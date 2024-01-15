FROM debian:12.4-slim

ARG TOOLCHAIN_VERSION=11.3.rel1
ARG HEX2DFU_VERSION=472b703
ARG TOOLCHAIN_PATH=/opt/gcc-arm-none-eabi

RUN apt update  \
    && apt install -y \
        curl \
	    build-essential \
	    cmake \
        ninja-build \
	    xz-utils \
        git-core \
    && rm -rf /var/lib/apt/lists/*

# get arm-none-eabi toolchain
RUN TARGET_ARCH="$(dpkg --print-architecture)"; \
    case "${TARGET_ARCH}" in \
        amd64) TOOLCHAIN_ARCH="x86_64";; \
        arm64) TOOLCHAIN_ARCH="aarch64";; \
        *) echo "'${TARGET_ARCH}' unsupported architecture" && exit 1;; \
    esac \
	&& mkdir ${TOOLCHAIN_PATH} \
	&& curl -Lo gcc-arm-none-eabi.tar.xz \
        "https://developer.arm.com/-/media/Files/downloads/gnu/${TOOLCHAIN_VERSION}/binrel/arm-gnu-toolchain-${TOOLCHAIN_VERSION}-${TOOLCHAIN_ARCH}-arm-none-eabi.tar.xz" \
	&& tar xf gcc-arm-none-eabi.tar.xz --strip-components=1 -C ${TOOLCHAIN_PATH} \
	&& rm gcc-arm-none-eabi.tar.xz \
	&& rm ${TOOLCHAIN_PATH}/*.txt \
	&& rm -rf ${TOOLCHAIN_PATH}/share/doc \
    && rm -rf ${TOOLCHAIN_PATH}/share/man

# add toolchain to PATH
ENV PATH="${TOOLCHAIN_PATH}/bin:${PATH}"

# get, build and install hex2dfu
RUN mkdir -p /opt/hex2dfu/bin \
    && curl \
        -Lo hex2dfu.tar.gz \
        https://github.com/encedo/hex2dfu/tarball/${HEX2DFU_VERSION} \
    && mkdir /opt/hex2dfu/src \
    && tar xf hex2dfu.tar.gz --strip-components=1 -C /opt/hex2dfu/src \
    && gcc -DED25519_SUPPORT=0 /opt/hex2dfu/src/hex2dfu.c -o /opt/hex2dfu/bin/hex2dfu \
    && rm hex2dfu.tar.gz \
    && rm -Rf /opt/hex2dfu/src

# add hex2dfu to PATH
ENV PATH="/opt/hex2dfu/bin:${PATH}"