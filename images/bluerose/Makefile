SHELL=/bin/bash
PROJECT := bluerose
REGISTRY := 001978429989.dkr.ecr.us-east-1.amazonaws.com
NVIDIA_NSIGHT_SYSTEMS_VERSION := 2021.4.1.73-08591f7
CONTAINER_BUILD_TARGET ?= runtime
COMMIT := $(shell git rev-parse --short HEAD)
# GIT_SNAPSHOT := $(shell git describe --tags --always --dirty)
BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
BRANCH_TAG := $(shell echo ${BRANCH} | sed 's/origin\///' | sed 's/[^-a-zA-Z0-9]/-/g')

# See the Dockerfile for an explanation of the need for these variables
# Defaults correspond to the package yielded by "apt-get install libssl" on Ubuntu 20.04
LIB_DIR=/usr/lib/x86_64-linux-gnu
LIB_SSL_SO=libssl.so.1.1
LIB_CRYPTO_SO=libcrypto.so.1.1

ifneq ("","$(wildcard ./.env)")
	include .env
	export
endif

# NOTE: The default build target is RelWithDebInfo, which goes into the 'build' folder.
CMAKE_BUILD_FOLDER ?= build
CMAKE_BUILD_TYPE ?= RelWithDebInfo

# default makefile target
.PHONY: default
default: relwithdebinfo

#### top level build commands

.PHONY: relwithdebinfo
relwithdebinfo: set-target-relwithdebinfo generate-normal compile

.PHONY: release
release: set-target-release generate-normal compile

.PHONY: debug
debug: set-target-host-debug generate-host-debug compile

.PHONY: device-debug
device-debug: set-target-device-debug generate-device-debug compile

#### setup build targets

.PHONY: set-target-relwithdebinfo
set-target-relwithdebinfo:
	$(eval CMAKE_BUILD_TYPE=RelWithDebInfo)
	$(eval CMAKE_BUILD_FOLDER=build)

.PHONY: set-target-host-debug
set-target-host-debug:
	$(eval CMAKE_BUILD_TYPE=Debug)
	$(eval CMAKE_BUILD_FOLDER=debug)

.PHONY: set-target-device-debug
set-target-device-debug:
	$(eval CMAKE_BUILD_TYPE=Debug)
	$(eval CMAKE_BUILD_FOLDER=device-debug)

.PHONY: set-target-release
set-target-release:
	$(eval CMAKE_BUILD_TYPE=Release)
	$(eval CMAKE_BUILD_FOLDER=release)

##### Cmake Generate commands

.PHONY: generate-normal
generate-normal:
	@echo Generating ${CMAKE_BUILD_TYPE} in ${CMAKE_BUILD_FOLDER}
	@cmake -B ${CMAKE_BUILD_FOLDER} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -G Ninja

.PHONY: generate-host-debug
generate-host-debug:
	@echo Generating ${CMAKE_BUILD_TYPE} in ${CMAKE_BUILD_FOLDER}
	@cmake -B ${CMAKE_BUILD_FOLDER} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DNO_DEVICE_DEBUG=YES -G Ninja

.PHONY: generate-device-debug
generate-device-debug:
	@echo Generating ${CMAKE_BUILD_TYPE} in ${CMAKE_BUILD_FOLDER}
	@cmake -B ${CMAKE_BUILD_FOLDER} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DNO_DEVICE_DEBUG=NO -G Ninja


##### Setup commands
.PHONY: bootstrap
bootstrap: clean-all

.PHONY: submodule
submodule: submodules

.PHONY: submodules
submodules:
	@git submodule update --init --recursive

##### Compilation
.PHONY: compile
compile:
	@echo Compiling ${CMAKE_BUILD_FOLDER}
	@cmake --build ${CMAKE_BUILD_FOLDER}

##### Doxygen

.PHONY: doxygen
doxygen:
	@doxygen Doxyfile

##### Cleaning

.PHONY: clean
clean: clean-relwithdebinfo

.PHONY: clean-relwithdebinfo
clean-relwithdebinfo:
	@echo Cleaning target ./build
	@rm -rf build

.PHONY: clean-debug
clean-debug:
	@echo Cleaning target ./debug
	@rm -rf debug

.PHONY: clean-device-debug
clean-device-debug:
	@echo Cleaning target ./device-debug
	@rm -rf device-debug

.PHONY: clean-release
clean-release:
	@echo Cleaning target ./release
	@rm -rf release

.PHONY: clean-all
clean-all: clean-relwithdebinfo clean-debug clean-device-debug clean-release

##### CI processes

.PHONY: format
format:
	@clang-format -i rose/**/*.cu rose/**/*.cuh rose/**/*.h tests/**/*.cu tests/**/*.cuh tests/**/*.h tests/*.cu tests/*.cuh tests/*.h

.PHONY: test
test: default
	@build/tests/run

.PHONY: build-info
build-info:
	@printf '\n'
	@echo '============================|Build Info|============================'
	@echo "COMMIT="$(COMMIT)
	@echo "BRANCH="$(BRANCH)
	@echo "BRANCH_TAG="$(BRANCH_TAG)
	@echo "CONTAINER_BUILD_TARGET="$(CONTAINER_BUILD_TARGET)
	@printf '\n'
	cmake --version
	@printf '\n'
	gcc -v
	@printf '\n'
	nvcc --version
	@printf '\n'
	git submodule status
	@echo '============================|Build Info|============================'
	@printf '\n'

.PHONY: ci
ci: clean submodules build-info container-test container-push


.PHONY: registry-login
registry-login:
	@if ! jq -e '.auths."$(REGISTRY)"?' < ~/.docker/config.json > /dev/null ; then \
		aws --region us-east-1 ecr get-login-password | docker login --username AWS --password-stdin $(REGISTRY) ; \
	elif ! docker manifest inspect $(REGISTRY)/${PROJECT}:devel > /dev/null ; then \
		aws --region us-east-1 ecr get-login-password | docker login --username AWS --password-stdin $(REGISTRY) ; \
	fi

##### containers

build/container/nsys.deb:
	@aws s3 cp \
		s3://solver-infrastructure-tools/nvidia/NsightSystems-linux-cli-public-${NVIDIA_NSIGHT_SYSTEMS_VERSION}.deb \
		build/container/nsys.deb

build/container/bench_linux-amd64:
	@GH_REPO=simpleroseinc/bench gh release download --pattern bench_linux-amd64 --dir build/container

.PHONY: container
ifeq ($(CONTAINER_BUILD_TARGET), runtime)
container: default # "runtime" target requires BlueRose to be built externally then copied in
endif
ifeq ($(CONTAINER_BUILD_TARGET), devel)
container: build/container/bench_linux-amd64
endif
container: build/container/nsys.deb
	@cp $(LIB_DIR)/$(LIB_SSL_SO) build
	@cp $(LIB_DIR)/$(LIB_CRYPTO_SO) build
	@docker buildx build \
		--build-arg LIB_SSL_SO=$(LIB_SSL_SO) \
		--build-arg LIB_CRYPTO_SO=$(LIB_CRYPTO_SO) \
		--tag $(PROJECT):$(CONTAINER_BUILD_TARGET) \
		--tag ${PROJECT}:$(CONTAINER_BUILD_TARGET)_$(COMMIT) \
		--tag ${PROJECT}:$(CONTAINER_BUILD_TARGET)_$(BRANCH_TAG) \
		--target $(CONTAINER_BUILD_TARGET) \
		.

.PHONY: container-test
container-test: container
	@e=0 ; \
	if [ "$(CONTAINER_BUILD_TARGET)" = "runtime" ] ; then \
			printf '\n' ; \
			echo '============================|Container Tests|============================' ; \
			nvidia-smi; \
			docker run --entrypoint /usr/local/bin/bluerose.test --gpus all $(PROJECT):$(CONTAINER_BUILD_TARGET)_$(COMMIT) ; \
			e=$$? ; \
			echo '============================|Container Tests|============================' ; \
			printf '\n' ; \
	fi ; \
	exit $$e


.PHONY: container-push
container-push: registry-login
	@if [ "$(CONTAINER_BUILD_TARGET)" = "runtime" ] ; then \
		docker tag $(PROJECT):$(CONTAINER_BUILD_TARGET) $(REGISTRY)/$(PROJECT):$(COMMIT) ; \
		docker tag $(PROJECT):$(CONTAINER_BUILD_TARGET) $(REGISTRY)/$(PROJECT):$(BRANCH_TAG) ; \
		docker push $(REGISTRY)/$(PROJECT):$(COMMIT) ; \
		docker push $(REGISTRY)/$(PROJECT):$(BRANCH_TAG) ; \
	else \
		docker tag $(PROJECT):$(CONTAINER_BUILD_TARGET) $(REGISTRY)/$(PROJECT):$(CONTAINER_BUILD_TARGET) ; \
		docker push $(REGISTRY)/$(PROJECT):$(CONTAINER_BUILD_TARGET) ; \
	fi
	@docker tag $(PROJECT):$(CONTAINER_BUILD_TARGET) $(REGISTRY)/$(PROJECT):$(CONTAINER_BUILD_TARGET)_$(COMMIT) ; 
	@docker tag $(PROJECT):$(CONTAINER_BUILD_TARGET) $(REGISTRY)/$(PROJECT):$(CONTAINER_BUILD_TARGET)_$(BRANCH_TAG) ; 
	@docker push $(REGISTRY)/$(PROJECT):$(CONTAINER_BUILD_TARGET)_$(COMMIT) ; 
	@docker push $(REGISTRY)/$(PROJECT):$(CONTAINER_BUILD_TARGET)_$(BRANCH_TAG) ; 

# .PHONY: bench
# bench: container registry-login
# 	@bench run create \
# 		--problem netlib/afiro \
# 		--module ${PROJECT} \
# 		--module.tag ${GIT_SNAPSHOT} \
# 		--tag USER=${USER} \
# 		--tag GIT_SNAPSHOT=${GIT_SNAPSHOT}
# 	@echo ${GIT_SNAPSHOT}

.PHONY: llama-setup
llama-setup:
	@echo "===> installing llama locally"