#!/bin/bash

. ./bash-tools.sh

if [[ -z $1 ]] ; then
    error "Please pass in a prefix suffix as argument"
    exit 1
fi

rm -rf bld-$1/llvmgcc42-2336.1-full-11 src-$1/llvmgcc42-2336.1
mkdir -p src-$1 bld-$1 /tmp2/$1
PREFIX_SUFFIX=$1 ./toolchain.sh llvmgcc

#[[ -f tc4-bld-src-$(uname-bt).7z ]] && rm rc-bld-src-$(uname-bt).7z

#mv src src-$(uname-bt)
#mv bld bld-$(uname-bt)
# 7za a tc4-bld-src-$(uname-bt).7z bld-$(uname-bt) src-$(uname-bt)
#mv src-$(uname-bt) src
#mv bld-$(uname-bt) bld
