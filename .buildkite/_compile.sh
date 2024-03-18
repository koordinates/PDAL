#!/bin/bash
set -eu

DEB_VER=$1
# pinned because there's also a 3.8.x in the repos and we still want to build against 3.6.x
MIN_GDAL_VER=3.6.4+kx-ci364-git20240110.6c7ffa44c2

source /etc/lsb-release

apt-get update -y
apt-get install -y --no-install-recommends \
    file \
    libcurl4-openssl-dev \
    libgeotiff-dev \
    "libgdal-dev=${MIN_GDAL_VER}" \
    "libgdal32=${MIN_GDAL_VER}" \
    "gdal-plugins=${MIN_GDAL_VER}" \
    "gdal-data=${MIN_GDAL_VER}"

# install modern cmake
CMAKE_VER=3.24.1
echo "Installing CMake v${CMAKE_VER}/$(uname -m) ..."
curl --silent --show-error --fail -L \
    "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/cmake-${CMAKE_VER}-linux-$(uname -m).sh" \
    >/tmp/cmake-install.sh
/bin/sh /tmp/cmake-install.sh --exclude-subdir --prefix=/usr --skip-license

cd /mnt/build

# configure
echo "+++ Configuring..."
cmake -S /src -B . \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_PLUGIN_PGPOINTCLOUD=OFF \
    -DWITH_TESTS=NO \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCPACK_DEBIAN_PACKAGE_MAINTAINER=robert.coup@koordinates.com \
    -DCPACK_DEBIAN_PACKAGE_SHLIBDEPS=ON \
    -DCPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS=ON \
    -DCPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS_POLICY=">=" \
    -DCPACK_DEBIAN_FILE_NAME=DEB-DEFAULT

# compile
echo "--- Compiling..."
cmake --build . --verbose

# compile
echo "--- Testing..."
ctest --output-on-failure

# build deb
echo "+++ Packaging..."
cpack -G DEB -R "${DEB_VER}"

cp -v pdal_*.deb /builds/
