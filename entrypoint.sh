#!/bin/bash -e

shopt -s nullglob

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

build_phd2() {
    pushd phd2
    # Build with non-free camera sdk
    sed -i \
      -e 's/ -DUSE_SYSTEM_GTEST=1/ -DUSE_SYSTEM_GTEST=0/' \
      -e 's/ -DOPENSOURCE_ONLY=1/ -DOPENSOURCE_ONLY=0 -DFETCHCONTENT_FULLY_DISCONNECTED=OFF/' \
      debian/rules
      curl -sLk https://github.com/indilib/indi-3rdparty/raw/refs/tags/v${INDI_VERSION}/libtoupcam/arm64/libtoupcam.bin > cameras/toupcam/linux/arm64/libtoupcam.so
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

# Build XISF
if [ -z libxisf{,-dev}_*_${PKG_ARCH}.deb ]; then echo "No XISF package found, building it"
    build_xisf
fi
dpkg -i libxisf{,-dev}_*_${PKG_ARCH}.deb

if [ ! -f libindi-dev_${INDI_VERSION#v*}_${PKG_ARCH}.deb ]; then echo "Missing indi development package, rebuilding"
    build_indi
fi
echo -e "\n########## Installing INDI packages" ##########"
dpkg -i libindi-dev_${INDI_VERSION#v*}_${PKG_ARCH}.deb \
    libindi1_${INDI_VERSION#v*}_${PKG_ARCH}.deb \
    libindi-data_${INDI_VERSION#v*}_all.deb \
    indi-bin_${INDI_VERSION#v*}_${PKG_ARCH}.deb

# Build INDI 3rd party drivers from INDI_3RD_PARTY_DRIVERS environment variable

pushd indi-3rdparty
chmod +x debian/*/rules
while read p; do echo -e "\n######### Compiling $p package #########\n"
    [ -d deb_$p ] || ./make_deb_pkgs $p
    if [[ "$p" =~ ^lib ]]; then echo "Installing compiled library $p as it may be required by subsequent packages"
        dpkg -i ${p}_*_${PKG_ARCH}.deb
    fi
done <<< "$INDI_3RD_PARTY_DRIVERS"

popd

# Build PHD2
if [ -z phd2_*_${PKG_ARCH}.deb ]; then echo "No PHD2 package found, building it"
    build_phd2
fi
dpkg -i phd2_*_${PKG_ARCH}.deb
