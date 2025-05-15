#!/bin/bash -e

shopt -s nullglob

VERSION=${INDI_VERSION:=master}

ARCH=$(uname -m)
case $ARCH in
    x86_64)
        PKG_ARCH='amd64'
    ;;
    aarch64)
        PKG_ARCH='arm64'
    ;;
    *)
        echo "Unknown architecture $ARCH. Aborting compilation."
        ecit 1
    ;;
esac

cd /usr/src

build_xisf() {
    pushd libXISF
    # Build with bundled libs (as ours are too old anyway)
    sed -ie 's/ -DUSE_BUNDLED_LIBS=Off//' debian/rules
    dpkg-buildpackage -d -b -uc
    popd
}

build_indi() {
    pushd indi
    for i in ../patches/*.diff; do echo "Applying $i"
        patch -p 1 < $i
        git diff
    done
    dpkg-buildpackage -d -b -uc
    popd
}

if [ ! -f libxisf_*_${PKG_ARCH}.deb -o ! libxisf-dev_*_${PKG_ARCH}.deb ]; then echo "No XISF package found, building it"
    build_xisf
fi
dpkg -i libxisf{,-dev}_*_${PKG_ARCH}.deb

if [ ! -f indi-bin_${INDI_VERSION#v*}_${PKG_ARCH}.deb ]; then echo "No indi package found, building it"
    build_indi
fi
echo -e "\n########## Installing INDI dev package" #########\#"
dpkg -i libindi-dev_${INDI_VERSION#v*}_${PKG_ARCH}.deb \
    libindi1_${INDI_VERSION#v*}_${PKG_ARCH}.deb \
    libindi-data_${INDI_VERSION#v*}_all.deb \
    indi-bin_${INDI_VERSION#v*}_${PKG_ARCH}.deb

INDI_3RD_PARTY_DRIVERS="libplayerone libpktriggercord indi-playerone indi-pentax libqhy indi-qhy"

pushd indi-3rdparty
for p in $(echo $INDI_3RD_PARTY_DRIVERS); do echo -e "\n######### Compiling $p package #########\n"
    [ -d deb_$p ] || ./make_deb_pkgs $p
    if [[ "$p" =~ ^lib ]]; then echo "Installing compiled library $p as it may be required by subsequent packages"
        dpkg -i ${p}_*_${PKG_ARCH}.deb
    fi
done
