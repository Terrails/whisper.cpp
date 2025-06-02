ARG UBUNTU_VERSION=22.04
# This needs to generally match the container host's environment.
ARG CUDA_VERSION=12.8.0
#ARG CUDA_MAIN_VERSION=12.8
# Target the CUDA build image
ARG BASE_CUDA_DEV_CONTAINER=nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}
# Target the CUDA runtime image
ARG BASE_CUDA_RUN_CONTAINER=nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION}
# The path to CUDA shared libraries
ARG CUDA_LIB_PATH=/usr/local/cuda-${CUDA_MAIN_VERSION}/compat

FROM ${BASE_CUDA_DEV_CONTAINER} AS build
WORKDIR /app

# Unless otherwise specified, we make a fat build.
ARG CUDA_DOCKER_ARCH=default
# Set nvcc architecture
ENV CUDA_DOCKER_ARCH=${CUDA_DOCKER_ARCH}

RUN apt-get update && apt-get install software-properties-common
RUN add-apt-repository --remove ppa:vikoadi/ppa
RUN apt-get update && \
    apt-get install -y build-essential libsdl2-dev wget cmake git \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Ref: https://stackoverflow.com/a/53464012
#ENV LD_LIBRARY_PATH ${CUDA_LIB_PATH}:$LD_LIBRARY_PATH

COPY .. .
# Enable cuBLAS
RUN make base.en CMAKE_ARGS="-DGGML_CUDA=1"

FROM ${BASE_CUDA_RUN_CONTAINER} AS runtime
# LD_LIBRARY_PATH breaks CUDA in the container, have to do more testing to see what else is unnecessary
#ENV LD_LIBRARY_PATH /usr/local/cuda-${CUDA_MAIN_VERSION}/compat:$LD_LIBRARY_PATH
ENV CUDA_ARCH_FLAG=all
WORKDIR /app

RUN apt-get update && \
  apt-get install -y curl ffmpeg wget cmake git \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY --from=build /app /app
ENV PATH=/app/build/bin:$PATH
ENTRYPOINT [ "bash", "-c" ]
