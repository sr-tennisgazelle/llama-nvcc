FROM ghcr.io/nelhage/llama as llama
FROM ubuntu:22.04 AS runtime-environment
LABEL maintainer "SimpleRose Engineering <eng@simplerose.com>"
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Supply build argument and/or override at container start
ARG NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES}

ARG CUDA_MAJOR_VERSION=11
ARG CUDA_MINOR_VERSION=7
ENV CUDA_PACKAGE_VERSION=${CUDA_MAJOR_VERSION}-${CUDA_MINOR_VERSION}
ENV CUDA_VERSION=${CUDA_MAJOR_VERSION}.${CUDA_MINOR_VERSION}
ENV NVIDIA_REQUIRE_CUDA="cuda>=${CUDA_VERSION} driver>=470"

# install cuda repository
RUN apt-get update \
    && apt-get install -y curl unzip gnupg2 \
    && curl -sL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin --output /etc/apt/preferences.d/cuda-repository-pin-600 \
    && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub \
    && echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /" > /etc/apt/sources.list.d/cuda.list \
    && rm -rf /var/lib/apt/lists/*

# install NvidiaSystems (nsys) profiler
COPY build/container/nsys.deb .
RUN apt-get update \
    && apt-get install -y ./nsys.deb \
    && rm -f nsys.deb \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y zlib1g libssl3 \
    && apt-get install -y cuda-compat-${CUDA_PACKAGE_VERSION} \
    && apt-get install -y libcusolver-${CUDA_PACKAGE_VERSION} libcusparse-${CUDA_PACKAGE_VERSION} libcublas-${CUDA_PACKAGE_VERSION} \
    && rm -rf /var/lib/apt/lists/*
ENV LD_LIBRARY_PATH /usr/local/cuda/compat:/usr/local/cuda/lib64

FROM runtime-environment as runtime

# The build of the current working tree is produced externally
COPY build/bluerose /usr/local/bin/bluerose
COPY build/tests/run /usr/local/bin/bluerose.test

# If needed, add .so libraries from the build
#ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
#COPY libawesome.so /usr/local/lib/

# ENTRYPOINT [ "/usr/local/bin/bluerose" ]

FROM runtime-environment AS builder

# Misc build utilities and cuda toolkit
RUN apt-get update
RUN apt-get install -y build-essential zlib1g-dev libssl-dev cuda-toolkit-${CUDA_PACKAGE_VERSION}
ENV PATH /usr/local/cuda/bin:${PATH}

# # install gcc-11
# RUN apt-get update \
#     && apt-get install -y gnupg2 \
#     && echo 'deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu focal main' > /etc/apt/sources.list.d/toolchain.list \
#     && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 60C317803A41BA51845E371A1E9377A2BA9EF27F \
#     && apt-get update \
#     && apt-get install -y -q gcc-11 g++-11 \
#     && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 111 \
#     --slave /usr/bin/g++ g++ /usr/bin/g++-11 \
#     --slave /usr/bin/gcov gcov /usr/bin/gcov-11 \
#     --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-11 \
#     --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-11 \
#     --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-11 \
#     && update-alternatives --install /usr/bin/cpp cpp /usr/bin/cpp-11 111 \
#     && rm -rf /var/lib/apt/lists/*

# install ninja
ARG NINJA_VERSION=1.10.2
ADD https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux.zip /tmp/
RUN unzip /tmp/ninja-linux.zip -d /usr/local/bin && rm -f /tmp/ninja-linux.zip

# install cmake
ARG CMAKE_VERSION=3.21.6
RUN curl -sL https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz | tar xz --strip-components=1 -C /usr/local

FROM builder as devel

# allow manual pages
RUN rm -f /etc/dpkg/dpkg.cfg.d/excludes \
    && dpkg-divert --remove /usr/bin/man \
    && apt-get update \
    && apt-get install -y man-db manpages

RUN apt-get install -y locales && locale-gen en_US.UTF-8

# install network utils
# install general utils
# install debug utils
RUN apt-get install -y curl wget net-tools telnet iputils-ping tcpdump \
        git vim jq tmux less zip unzip ack awscli zsh nano clang-format git-lfs procps rsync \
        valgrind gdb gdbserver

# install zsh theme
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k
RUN echo 'source ~/.powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
RUN echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc
RUN curl -sL https://gist.githubusercontent.com/simplerose-ci/843c1d8189f638cc39996d92b7202e6b/raw/7f91569db2cfe6a78e5aa14aeaf19d1d14132cd9/.p10k.zsh --output ~/.p10k.zsh

# install docker client
ARG DOCKER_CLI_VERSION=20.10.14
RUN curl -sL https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce-cli_${DOCKER_CLI_VERSION}~3-0~ubuntu-focal_amd64.deb --output docker-ce-cli.deb \
    && apt-get install ./docker-ce-cli.deb \
    && rm -f docker-ce-cli.deb 

# install github client
ARG GITHUB_CLI_VERSION=2.7.0
RUN curl -sL https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_amd64.deb --output ./gh_cli_linux_amd64.deb \
    && apt-get install ./gh_cli_linux_amd64.deb \
    && rm -f ./gh_cli_linux_amd64.deb

# The latest bench is downloaded by an external script
# COPY build/bluerose /usr/local/bin/bluerose
# COPY build/container/bench_linux-amd64 /usr/local/bin/bench
# RUN chmod +x /usr/local/bin/bench

COPY --from=llama /llama_runtime /llama_runtime
COPY /build ./build
COPY Makefile ./Makefile
ARG build_folder build/

WORKDIR /
# ENTRYPOINT['/']
ENTRYPOINT ["/bin/bash"]