#!/bin/bash

. ./bash-tools.sh

if [[ -z $1 ]] ; then
    error "Please pass in a prefix suffix as argument"
    exit 1
fi

rm -rf bld$1/gcc-5665.3-11 src$1/gcc-5666.3
mkdir -p src$1 bld$1 /tmp2/$1
PREFIX_SUFFIX=$1 ./toolchain.sh gcc

#[[ -f tc4-bld-src-$(uname_bt).7z ]] && rm rc-bld-src-$(uname_bt).7z

#mv src src-$(uname_bt)
#mv bld bld-$(uname_bt)
# 7za a tc4-bld-src-$(uname_bt).7z bld-$(uname_bt) src-$(uname_bt)
#mv src-$(uname_bt) src
#mv bld-$(uname_bt) bld
