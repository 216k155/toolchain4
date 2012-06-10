#!/bin/bash

. ./bash-tools.sh

# Always use CLEAN=1 for release builds as otherwise Apple's proprietary software
# will be packaged.
CLEAN=1
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

UNAME=$(uname_bt)

BASE_TMP=/tmp2/tc4
# On MSYS, /tmp is in a deep folder (C:\Users\me\blah); deep folders and Windows
# don't get along, so /tmp2 is used instead.
if [[ "$(uname_bt)" == "Windows" ]] ; then
	BASE_TMP=/tmp2/tc4
fi

DST=${BASE_TMP}/final-install

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
#    rm -rf bld-$_PREFIX_SUFFIX src-$_PREFIX_SUFFIX $DST/$_PREFIX_SUFFIX
#    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh llvmgcc-core $_TARGET_ARCH
#    rm -rf bld-$1/cctools-809-${_TARGET_ARCH} src-$_PREFIX_SUFFIX/cctools-809
#    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh cctools $_TARGET_ARCH
#    rm -rf bld-$1/gcc-5666.3-${_TARGET_ARCH} src-$_PREFIX_SUFFIX/gcc-5666.3
#    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh gcc $_TARGET_ARCH
#    rm -rf bld-$_PREFIX_SUFFIX/llvmgcc42-2336.1-full-${_TARGET_ARCH} src-$_PREFIX_SUFFIX/llvmgcc42-2336.1
#    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh llvmgcc $_TARGET_ARCH
    PREFIX_SUFFIX=$_PREFIX_SUFFIX ./toolchain.sh gccdriver $_TARGET_ARCH
}

# Clean everything.
ARM_BUILD=0
if [ "$ARM_BUILD" = "1" ] ; then
    # Make arm build.
    full_build_for_arch $PREFIX arm
    if [[ $CLEAN = 1 ]] ; then
        rm -rf $DST/${PREFIX}-ios/usr/lib
        rm -rf $DST/${PREFIX}-ios/arm-apple-darwin11/lib
        rm $DST/${PREFIX}-ios/lib/libSystem.B.dylib
        rm -rf $DST/${PREFIX}-ios/usr/include
        rm -rf $DST/${PREFIX}-ios/arm-apple-darwin11/sys-include
    fi
    # Since libstdc++ doesn't build, we need to get the headers from an existing SDK.
    if [ ! -d $DST/${PREFIX}-ios/include/c++ ] ; then
        mkdir -p $DST/${PREFIX}-ios/include/c++
    fi
    TOPDIR=$PWD
    pushd $DST/${PREFIX}-ios/include/c++
    cp -rf $TOPDIR/sdks/iPhoneOS4.3.sdk/usr/include/c++/4.2.1 4.2.1
    mv 4.2.1/arm-apple-darwin10 4.2.1/arm-apple-darwin11
    cp -rf 4.2.1/arm-apple-darwin11/v7/bits 4.2.1/arm-apple-darwin11/
    mv 4.2.1/armv6-apple-darwin10 4.2.1/armv6-apple-darwin11
    mv 4.2.1/armv7-apple-darwin10 4.2.1/armv7-apple-darwin11
    popd
fi
# Copy needed dlls.
if [[ "$UNAME" = "Windows" ]] ; then
	for _DLL in libintl-8.dll libiconv-2.dll libgcc_s_dw2-1.dll libstdc++-6.dll pthreadGC2.dll
	do
		cp -rf /mingw/bin/$_DLL $DST/${PREFIX}-ios/bin
		cp -rf /mingw/bin/$_DLL $DST/${PREFIX}-ios/libexec/gcc/arm-apple-darwin11/4.2.1
		cp -rf /mingw/bin/$_DLL $DST/${PREFIX}-ios/libexec/llvmgcc/arm-apple-darwin11/4.2.1
	done
fi

INTEL_BUILD=1
if [ "$INTEL_BUILD" = "1" ] ; then
    # Make i686 build.
    full_build_for_arch $PREFIX intel
    if [[ $CLEAN = 1 ]] ; then
        rm -rf $DST/${PREFIX}-osx/usr/lib
        rm -rf $DST/${PREFIX}-osx/i686-apple-darwin11/lib
        rm $DST/${PREFIX}-osx/lib/libSystem.B.dylib
        rm -rf $DST/${PREFIX}-osx/usr/include
        rm -rf $DST/${PREFIX}-osx/i686-apple-darwin11/sys-include
    fi
    # Since libstdc++ doesn't build, we need to get the headers from an existing SDK.
    if [ ! -d $DST/${PREFIX}-osx/include/c++ ] ; then
        mkdir -p $DST/${PREFIX}-osx/include/c++
    fi
    TOPDIR=$PWD
    pushd $DST/${PREFIX}-osx/include/c++
    cp -rf $TOPDIR/sdks/MacOSX10.7.sdk/usr/include/c++/4.2.1 4.2.1
    popd
fi
# Copy needed dlls
if [[ "$UNAME" = "Windows" ]] ; then
	for _DLL in libintl-8.dll libiconv-2.dll libgcc_s_dw2-1.dll libstdc++-6.dll pthreadGC2.dll
	do
		cp -rf /mingw/bin/$_DLL $DST/${PREFIX}-osx/bin
		cp -rf /mingw/bin/$_DLL $DST/${PREFIX}-osx/libexec/gcc/i686-apple-darwin11/4.2.1
		cp -rf /mingw/bin/$_DLL $DST/${PREFIX}-osx/libexec/llvmgcc/i686-apple-darwin11/4.2.1
	done
fi

# For some reason, make install on Windows isn't copying the x86_64 folders so work around that.
if [[ ! -d $DST/${PREFIX}-osx/lib/llvmgcc42/i686-apple-darwin11/4.2.1/x86_64 ]] ; then
    cp -rf ${BASE_TMP}/bld-${PREFIX}-osx/llvmgcc42-2336.1-full-i686/gcc/x86_64 $DST/${PREFIX}-osx/lib/llvmgcc/i686-apple-darwin11/4.2.1/
fi
if [[ ! -d $DST/${PREFIX}-osx/lib/gcc/i686-apple-darwin11/4.2.1/x86_64 ]] ; then
    cp -rf ${BASE_TMP}/bld-${PREFIX}-osx/gcc-5666.3-i686/gcc/x86_64 $DST/${PREFIX}-osx/lib/gcc/i686-apple-darwin11/4.2.1/
fi

if [ $MAKING_DEBUG = no ] ; then
    # Strip executables.
    # Maybe "strip -u -r -S" when on OS X?
    if [[ ! "$UNAME" = "Darwin" ]] ; then
        find $DST/${PREFIX}-ios/bin -type f -and -not \( -path "*-config" -or -path "*-gccbug" \) | xargs strip
        find $DST/${PREFIX}-ios/libexec -type f -and -not \( -path "*.sh" -or -path "*mkheaders" \) | xargs strip
        find $DST/${PREFIX}-osx/bin -type f -and -not \( -path "*-config" -or -path "*-gccbug"  \) | xargs strip
        find $DST/${PREFIX}-osx/libexec -type f -and -not \( -path "*.sh" -or -path "*mkheaders" \) | xargs strip
    fi
fi

find $DST -type d -empty -exec rmdir {} \;

cp ${BASE_TMP}/src-${PREFIX}-osx/cctools-809/APPLE_LICENSE $DST/${PREFIX}-osx
chmod 0777 $DST/${PREFIX}-osx/APPLE_LICENSE
cp ${BASE_TMP}/src-${PREFIX}-osx/llvmgcc42-2336.1/COPYING $DST/${PREFIX}-osx
cp ${BASE_TMP}/src-${PREFIX}-osx/llvmgcc42-2336.1/llvmCore/LICENSE.TXT $DST/${PREFIX}-osx

cp ${BASE_TMP}/src-${PREFIX}-osx/cctools-809/APPLE_LICENSE $DST/${PREFIX}-ios
chmod 0777 $DST/${PREFIX}-ios/APPLE_LICENSE
cp ${BASE_TMP}/src-${PREFIX}-osx/llvmgcc42-2336.1/COPYING $DST/${PREFIX}-ios
cp ${BASE_TMP}/src-${PREFIX}-osx/llvmgcc42-2336.1/llvmCore/LICENSE.TXT $DST/${PREFIX}-ios

DATESUFFIX=$(date +%y%m%d)
if [ $MAKING_DEBUG = yes ] ; then
    OUTFILEPREFIX=$PWD/multiarch-darwin11-cctools127.2-gcc42-5666.3-llvmgcc42-2336.1-$UNAME-dbg-$DATESUFFIX
else
    OUTFILEPREFIX=$PWD/multiarch-darwin11-cctools127.2-gcc42-5666.3-llvmgcc42-2336.1-$UNAME-$DATESUFFIX
fi
OUTFILE=$(compress_folders "$DST/." $OUTFILEPREFIX)
cp $OUTFILE ~/Dropbox/darwin-compilers-work
