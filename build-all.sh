#!/bin/bash

. ./bash-tools.sh

PREFIX=$1
if [[ -z $PREFIX ]] ; then
    error "Please pass in a PREFIX as argument 1, e.g. apple"
    error "If it contains debug or dbg, debugabble toolchains"
    error "are made."
    exit 1
fi

MAKING_DEBUG=no
case $PREFIX in
  *debug*)
    MAKING_DEBUG=yes
    ;;
  *dbg*)
    MAKING_DEBUG=yes
    ;;
  *)
    ;;
esac

UNAME=$(uname-bt)

if [ $MAKING_DEBUG = yes ] ; then
   echo "*************************"
   echo "*** Making Debuggable ***"
   echo "*************************"
   export HOST_DEBUG_CFLAGS="-O0 -g"
fi

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
ARM_BUILD=1
if [ "$ARM_BUILD" = "1" ] ; then
    # Make arm build.
    full_build_for_arch $PREFIX arm
    rm -rf /tmp2/${PREFIX}-ios/usr/lib
    rm -rf /tmp2/${PREFIX}-ios/arm-apple-darwin11/lib
    rm /tmp2/${PREFIX}-ios/lib/libSystem.B.dylib
    rm -rf /tmp2/${PREFIX}-ios/usr/include
    rm -rf /tmp2/${PREFIX}-ios/arm-apple-darwin11/sys-include
    # Since libstdc++ doesn't build, we need to get the headers from an existing SDK.
    if [ ! -d /tmp2/${PREFIX}-ios/include/c++ ] ; then
        mkdir -p /tmp2/${PREFIX}-ios/include/c++
    fi
    pushd /tmp2/${PREFIX}-ios/include/c++
    cp -rf ~/iPhoneOS4.3.sdk/usr/include/c++/4.2.1 4.2.1
    mv 4.2.1/arm-apple-darwin10 4.2.1/arm-apple-darwin11
    cp -rf 4.2.1/arm-apple-darwin11/v7/bits 4.2.1/arm-apple-darwin11/
    mv 4.2.1/armv6-apple-darwin10 4.2.1/armv6-apple-darwin11
    mv 4.2.1/armv7-apple-darwin10 4.2.1/armv7-apple-darwin11
    popd
    # Copy needed dlls
    if [[ "$UNAME" = "Windows" ]] ; then
        for _DLL in libintl-8.dll libiconv-2.dll libgcc_s_dw2-1.dll libstdc++-6.dll
        do
            cp -rf /mingw/bin/$_DLL /tmp2/${PREFIX}-ios/bin
        done
    fi
fi

INTEL_BUILD=1
if [ "$INTEL_BUILD" = "1" ] ; then
    # Make i686 build.
    full_build_for_arch $PREFIX intel
    rm -rf /tmp2/${PREFIX}-osx/usr/lib
    rm -rf /tmp2/${PREFIX}-osx/i686-apple-darwin11/lib
    rm /tmp2/${PREFIX}-osx/lib/libSystem.B.dylib
    rm -rf /tmp2/${PREFIX}-osx/usr/include
    rm -rf /tmp2/${PREFIX}-osx/i686-apple-darwin11/sys-include
    # Since libstdc++ doesn't build, we need to get the headers from an existing SDK.
    if [ ! -d /tmp2/${PREFIX}-osx/include/c++ ] ; then
        mkdir -p /tmp2/${PREFIX}-osx/include/c++
    fi
    pushd /tmp2/${PREFIX}-osx/include/c++
    cp -rf ~/MacOSX10.7.sdk/usr/include/c++/4.2.1 4.2.1
    popd
    # Copy needed dlls
    if [[ "$UNAME" = "Windows" ]] ; then
        for _DLL in libintl-8.dll libiconv-2.dll libgcc_s_dw2-1.dll libstdc++-6.dll
        do
            cp -rf /mingw/bin/$_DLL /tmp2/${PREFIX}-osx/bin
        done
    fi
fi

if [ $MAKING_DEBUG = no ] ; then
    # Strip executables.
    # Maybe "strip -u -r -S" when on OS X?
    if [[ ! "$UNAME" = "Darwin" ]] ; then
        find /tmp2/${PREFIX}-ios/bin -type f -and -not \( -path "*-config" \) | xargs strip
        find /tmp2/${PREFIX}-ios/libexec -type f -and -not \( -path "*.sh" -or -path "*mkheaders" \) | xargs strip
        find /tmp2/${PREFIX}-osx/bin -type f -and -not \( -path "*-config" \) | xargs strip
        find /tmp2/${PREFIX}-osx/libexec -type f -and -not \( -path "*.sh" -or -path "*mkheaders" \) | xargs strip
    fi
fi

cp src-${PREFIX}-osx/cctools-809/APPLE_LICENSE /tmp2/${PREFIX}-osx
cp src-${PREFIX}-osx/llvmgcc42-2336.1/COPYING /tmp2/${PREFIX}-osx
cp src-${PREFIX}-osx/llvmgcc42-2336.1/llvmCore/LICENSE.TXT /tmp2/${PREFIX}-osx

cp src-${PREFIX}-osx/cctools-809/APPLE_LICENSE /tmp2/${PREFIX}-ios
cp src-${PREFIX}-osx/llvmgcc42-2336.1/COPYING /tmp2/${PREFIX}-ios
cp src-${PREFIX}-osx/llvmgcc42-2336.1/llvmCore/LICENSE.TXT /tmp2/${PREFIX}-ios

pushd /tmp2
    7za a -mx=9 multiarch-darwin11-cctools127.2-gcc42-5666.3-llvmgcc42-2336.1-$UNAME.7z ${PREFIX}-ios ${PREFIX}-osx
    cp multiarch-darwin11-cctools127.2-gcc42-5666.3-llvmgcc42-2336.1-$UNAME.7z ~/Dropbox/darwin-compilers-work
popd

#[[ -f tc4-bld-src-$(uname-bt).7z ]] && rm rc-bld-src-$(uname-bt).7z

#mv src src-$(uname-bt)
#mv bld bld-$(uname-bt)
# 7za a tc4-bld-src-$(uname-bt).7z bld-$(uname-bt) src-$(uname-bt)
#mv src-$(uname-bt) src
#mv bld-$(uname-bt) bld
