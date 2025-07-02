FROM --platform=linux/arm64 ubuntu:18.04
ARG DEBIAN_FRONTEND=noninteractive

ARG INDI_VERSION=master

RUN apt-get -y update && \
    apt-get -y install git \
        gcc-8 \
        g++-8 \
        build-essential \
        libssl-dev && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 10 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 10 && \
    git clone --branch v3.31.7 --depth 1 https://github.com/Kitware/CMake/ \
    && cd CMake && ./bootstrap && make && make install

RUN apt-get -y install dpkg-dev \
        cdbs \
        dkms \
        fxload \
        libgps-dev \
        libgsl-dev \
        libraw-dev \
        libusb-dev \
        zlib1g-dev \
        libftdi-dev \
        libjpeg-dev \
        libkrb5-dev \
        libnova-dev \
        libtiff-dev \
        libfftw3-dev \
        librtlsdr-dev \
        libcfitsio-dev \
        libgphoto2-dev \
        libusb-1.0-0-dev \
        libdc1394-22-dev \
        libboost-regex-dev \
        libcurl4-gnutls-dev \
        libtheora-dev \
        libwxgtk3.0-dev \
        wx3.0-i18n \
        libopencv-dev \
        libeigen3-dev \
        libgtest-dev \
        libx11-dev

ADD entrypoint.sh /usr/local/bin/entrypoint.sh

RUN --mount=source=libev,type=bind,target=/libev \
    dpkg -i /libev/*.deb

ENV INDI_VERSION=${INDI_VERSION}

CMD ["/bin/bash", "-x", "/usr/local/bin/entrypoint.sh" ]
