#!/bin/bash

. ./bash-tools.sh

if [[ -z $1 ]] ; then
    error "Please pass in a PREFIX as argument 1, e.g. apple"
    exit 1
fi

if [[ -z $2 ]] ; then
    error "Please pass in a TARGET_ARCH (either intel for MacOSX or arm for iOS) as argument 2"
    exit 1
fi

TARGET_ARCH=$2

rm -rf bld-$1 src-$1 /tmp2/$1
PREFIX_SUFFIX=$1 ./toolchain.sh llvmgcc-core $TARGET_ARCH
rm -rf bld-$1/cctools-809-iphone src-$1/cctools-809
PREFIX_SUFFIX=$1 ./toolchain.sh cctools $TARGET_ARCH
rm -rf bld-$1/gcc-5666.3-11 src-$1/gcc-5666.3
PREFIX_SUFFIX=$1 ./toolchain.sh gcc $TARGET_ARCH
rm -rf bld-$1/llvmgcc42-2336.1-full-11 src-$1/llvmgcc42-2336.1
PREFIX_SUFFIX=$1 ./toolchain.sh llvmgcc $TARGET_ARCH
PREFIX_SUFFIX=$1 ./toolchain.sh gccdriver $TARGET_ARCH

rm -rf /tmp2/$1/$BUILD_ARCH-apple-darwin11/sys-include
pushd /tmp2/$1/bin
#strip *
popd

pushd /tmp2/$1
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
