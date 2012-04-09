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
    local _PREFIX_SUFFIX=$1
    local _TARGET_ARCH=$2
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh llvmgcc-core $_TARGET_ARCH
    rm -rf bld-$1/cctools-809-${_TARGET_ARCH} src-$1/cctools-809
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh cctools $_TARGET_ARCH
    rm -rf bld-$1/gcc-5666.3-${_TARGET_ARCH} src-$1/gcc-5666.3
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh gcc $_TARGET_ARCH
    rm -rf bld-$1/llvmgcc42-2336.1-full-${_TARGET_ARCH} src-$1/llvmgcc42-2336.1
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh llvmgcc $_TARGET_ARCH
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh gccdriver $_TARGET_ARCH
    rm -rf /tmp2/$1/$_TARGET_ARCH-apple-darwin11/sys-include
}

rm -rf bld-$PREFIX src-$PREFIX /tmp2/$PREFIX
full_build_for_arch $PREFIX arm
# Don't want arm binaries or headers in this folder, also these files are copyright to Apple.
find /tmp2/$PREFIX/usr/lib > /tmp2/$PREFIX/arm-needed-libs.txt
rm -rf /tmp2/$PREFIX/usr/lib/*
find /tmp2/$PREFIX/usr/include > /tmp2/$PREFIX/arm-needed-headers.txt
rm -rf /tmp2/$PREFIX/usr/include/*
full_build_for_arch $PREFIX intel
find /tmp2/$PREFIX/usr/lib > /tmp2/$PREFIX/intel-needed-libs.txt
rm -rf /tmp2/$PREFIX/usr/lib/*
find /tmp2/$PREFIX/usr/include > /tmp2/$PREFIX/intel-needed-headers.txt
rm -rf /tmp2/$PREFIX/usr/include/*

pushd /tmp2/$PREFIX/bin
    strip *
popd

pushd /tmp2/$PREFIX
    UNAME=$(uname-bt)
    7za a -mx=9 multiarch-darwin11-cctools127.2-gcc42-5666.3-llvmgcc42-2336.1-$UNAME.7z *
    cp multiarch-darwin11-cctools127.2-gcc42-5666.3-llvmgcc42-2336.1-$UNAME.7z ~/Dropbox/darwin-compilers-work
popd

#[[ -f tc4-bld-src-$(uname-bt).7z ]] && rm rc-bld-src-$(uname-bt).7z

#mv src src-$(uname-bt)
#mv bld bld-$(uname-bt)
# 7za a tc4-bld-src-$(uname-bt).7z bld-$(uname-bt) src-$(uname-bt)
#mv src-$(uname-bt) src
#mv bld-$(uname-bt) bld
