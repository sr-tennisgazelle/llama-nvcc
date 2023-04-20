FROM ghcr.io/nelhage/llama as llama
FROM ubuntu:focal
RUN apt-get update && apt-get -y install gcc g++ gcc-9 g++-9 ca-certificates && apt-get clean

# ARG CUDA_MAJOR_VERSION=11
# ARG CUDA_MINOR_VERSION=7
# ENV CUDA_PACKAGE_VERSION=${CUDA_MAJOR_VERSION}-${CUDA_MINOR_VERSION}
# ENV CUDA_VERSION=${CUDA_MAJOR_VERSION}.${CUDA_MINOR_VERSION}
# ENV NVIDIA_REQUIRE_CUDA="cuda>=${CUDA_VERSION} driver>=470"
# # install cuda repository
# RUN apt-get update \
#     && apt-get install -y curl unzip gnupg2 \
#     && curl -sL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin --output /etc/apt/preferences.d/cuda-repository-pin-600 \
#     && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub \
#     && echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /" > /etc/apt/sources.list.d/cuda.list \
#     && rm -rf /var/lib/apt/lists/*

# RUN apt-get update \
#     && apt-get install -y zlib1g libssl3 \
#     && apt-get install -y cuda-compat-${CUDA_PACKAGE_VERSION} \
#     && apt-get install -y libcusolver-${CUDA_PACKAGE_VERSION} libcusparse-${CUDA_PACKAGE_VERSION} libcublas-${CUDA_PACKAGE_VERSION} \
#     && rm -rf /var/lib/apt/lists/*
# ENV LD_LIBRARY_PATH /usr/local/cuda/compat:/usr/local/cuda/lib64

COPY --from=llama /llama_runtime /llama_runtime
WORKDIR /
ENTRYPOINT ["/llama_runtime"]
