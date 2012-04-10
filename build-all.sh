#!/bin/bash

. ./bash-tools.sh

PREFIX=$1
if [[ -z $PREFIX ]] ; then
    error "Please pass in a PREFIX as argument 1, e.g. apple"
    exit 1
fi

#if [[ -z $2 ]] ; then
#    error "Please pass in a TARGET_ARCH (either intel for MacOSX or arm for iOS) as argument 2"
#    exit 1
#fi
#TARGET_ARCH=$2

full_build_for_arch() {
    local _TARGET_ARCH=$2
    if [[ "$_TARGET_ARCH" = "arm" ]] ; then
        local _PREFIX_SUFFIX=$1-ios
    else
        local _PREFIX_SUFFIX=$1-osx
    fi
    rm -rf bld-$_PREFIX_SUFFIX src-$_PREFIX_SUFFIX /tmp2/$_PREFIX_SUFFIX
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh llvmgcc-core $_TARGET_ARCH
    rm -rf bld-$1/cctools-809-${_TARGET_ARCH} src-$_PREFIX_SUFFIX/cctools-809
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh cctools $_TARGET_ARCH
    rm -rf bld-$1/gcc-5666.3-${_TARGET_ARCH} src-$_PREFIX_SUFFIX/gcc-5666.3
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh gcc $_TARGET_ARCH
    rm -rf bld-$_PREFIX_SUFFIX/llvmgcc42-2336.1-full-${_TARGET_ARCH} src-$_PREFIX_SUFFIX/llvmgcc42-2336.1
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh llvmgcc $_TARGET_ARCH
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh gccdriver $_TARGET_ARCH
}

# Clean everything.

# Make arm build.
full_build_for_arch $PREFIX arm

# Remove Apple's proprietary stuff, backing up the list of what's needed.
find /tmp2/${PREFIX}-ios/usr/lib > /tmp2/${PREFIX}-ios/needed-libs.txt
find /tmp2/${PREFIX}-ios/arm-apple-darwin11/lib >> /tmp2/${PREFIX}-ios/needed-libs.txt
rm -rf /tmp2/${PREFIX}-ios/usr/lib
rm -rf /tmp2/${PREFIX}-ios/arm-apple-darwin11/lib
find /tmp2/${PREFIX}-ios/usr/include > /tmp2/${PREFIX}-ios/needed-headers.txt
find /tmp2/${PREFIX}-ios/arm-apple-darwin11/sys-include >> /tmp2/${PREFIX}-ios/needed-headers.txt
rm -rf /tmp2/${PREFIX}-ios/usr/include
rm -rf /tmp2/${PREFIX}-ios/arm-apple-darwin11/sys-include

# Make i686 build.
full_build_for_arch $PREFIX intel

# Remove Apple's proprietary stuff, backing up the list of what's needed.
find /tmp2/${PREFIX}-osx/usr/lib > /tmp2/${PREFIX}-osx/needed-libs.txt
find /tmp2/${PREFIX}-osx/i686-apple-darwin11/lib >> /tmp2/${PREFIX}-osx/needed-libs.txt
rm -rf /tmp2/${PREFIX}-osx/usr/lib
rm -rf /tmp2/${PREFIX}-osx/i686-apple-darwin11/lib
find /tmp2/${PREFIX}-osx/usr/include > /tmp2/${PREFIX}-osx/needed-headers.txt
find /tmp2/${PREFIX}-osx/i686-apple-darwin11/sys-include >> /tmp2/${PREFIX}-osx/needed-headers.txt
rm -rf /tmp2/${PREFIX}-osx/usr/include
rm -rf /tmp2/${PREFIX}-osx/i686-apple-darwin11/sys-include

# Strip executables.
find /tmp2/${PREFIX}-ios/bin -type f -and -not \( -path "*-config" \) | xargs strip
find /tmp2/${PREFIX}-ios/libexec -type f -and -not \( -path "*.sh" -or -path "*mkheaders" \) | xargs strip
find /tmp2/${PREFIX}-osx/bin -type f -and -not \( -path "*-config" \) | xargs strip
find /tmp2/${PREFIX}-osx/libexec -type f -and -not \( -path "*.sh" -or -path "*mkheaders" \) | xargs strip

pushd /tmp2
    UNAME=$(uname-bt)
    7za a -mx=9 multiarch-darwin11-cctools127.2-gcc42-5666.3-llvmgcc42-2336.1-$UNAME.7z ${PREFIX}-ios ${PREFIX}-osx
    cp multiarch-darwin11-cctools127.2-gcc42-5666.3-llvmgcc42-2336.1-$UNAME.7z ~/Dropbox/darwin-compilers-work
popd

#[[ -f tc4-bld-src-$(uname-bt).7z ]] && rm rc-bld-src-$(uname-bt).7z

#mv src src-$(uname-bt)
#mv bld bld-$(uname-bt)
# 7za a tc4-bld-src-$(uname-bt).7z bld-$(uname-bt) src-$(uname-bt)
#mv src-$(uname-bt) src
#mv bld-$(uname-bt) bld
