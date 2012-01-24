#!/bin/bash

. ./bash-tools.sh

rm -rf bld src

CCTOOLSVER=782 FOREIGNHEADERS=0 ./toolchain.sh $1
CCTOOLSVER=782 FOREIGNHEADERS=1 ./toolchain.sh $1
CCTOOLSVER=809 FOREIGNHEADERS=0 ./toolchain.sh $1
CCTOOLSVER=809 FOREIGNHEADERS=1 ./toolchain.sh $1

[[ -f tc4-bld-src-$(uname-bt).7z ]] && rm rc-bld-src-$(uname-bt).7z

mv src src-$(uname-bt)
mv bld bld-$(uname-bt)
7za a tc4-bld-src-$(uname-bt).7z bld-$(uname-bt) src-$(uname-bt)
mv src-$(uname-bt) src
mv bld-$(uname-bt) bld
