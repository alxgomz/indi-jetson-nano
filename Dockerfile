FROM --platform=linux/arm64 ubuntu:18.04
ARG DEBIAN_FRONTEND=noninteractive

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
        libboost-regex-dev \
        libcfitsio-dev \
        libcurl4-gnutls-dev \
        libdc1394-22-dev \
        libeigen3-dev \
        libfftw3-dev \
        libftdi-dev \
        libgphoto2-dev \
        libgps-dev \
        libgsl-dev \
        libjpeg-dev \
        libkrb5-dev \
        libnova-dev \
        libopencv-dev \
        libraw-dev \
        librtlsdr-dev \
        libtheora-dev \
        libtiff-dev \
        libusb-1.0-0-dev \
        libusb-dev \
        libwxgtk3.0-dev \
        libx11-dev \
        wx3.0-i18n \
        zlib1g-dev

ADD entrypoint.sh /usr/local/bin/entrypoint.sh
ADD http://launchpadlibrarian.net/477116565/libev-dev_4.33-1_arm64.deb http://launchpadlibrarian.net/477116569/libev4_4.33-1_arm64.deb /libev/

RUN dpkg -i /libev/*.deb

CMD ["/bin/bash", "-x", "/usr/local/bin/entrypoint.sh" ]
