#/bin/bash

# This script builds the very latest Apple toolchain natively on Darwin
# optionally saving temps for comparision purposes.
#
# Overall, Apple seems to be doing a bad job of maintaining cctools.
#
# Old ld doesn't seem to build cleanly at all, so it's probably worth
# disabling that and just using ld64 which builds fine.
# Error with ld is in ld.c:
# #error "unsupported architecture for static KLD"
# ..which happens as we're not defining ppc or i386 or anything else
#   for that matter.
#

# I think save-temps results in broken builds unfortunately...
SAVETEMPS=1
# -DARCH64 seems like something I don't want to be doing either...
ARCH64=0

TOPSRCDIR=$PWD
BUILD_DIR=bld-st-${SAVETEMPS}-a64-${ARCH64}
BUILD_PREFIX=${PWD}/${BUILD_DIR}
TARBALLS=$PWD/tarballs

[[ ! -d ${TARBALLS} ]] && mkdir ${TARBALLS}

GCC_VER=2336.1
#LD64_VER=95.2.12
LD64_VER=127.2
#CCTOOLS_VER=782
CCTOOLS_VER=809
DYLD_VER=195.5

GCC_STUBNAME=llvmgcc42-${GCC_VER}
LD64_STUBNAME=ld64-${LD64_VER}
CCTOOLS_STUBNAME=cctools-${CCTOOLS_VER}
DYLD_STUBNAME=dyld-${DYLD_VER}

# Unpatched original sources.
GCC_DIR=${TOPSRCDIR}/${GCC_STUBNAME}
LD64_DIR=${TOPSRCDIR}/${LD64_STUBNAME}
CCTOOLS_DIR=${TOPSRCDIR}/${CCTOOLS_STUBNAME}
DYLD_DIR=${TOPSRCDIR}/${DYLD_STUBNAME}

# Patched sources - need to be in the build folder.
GCC_DIR_BUILD=${TOPSRCDIR}/${BUILD_DIR}/${GCC_STUBNAME}-patched
LD64_DIR_BUILD=${TOPSRCDIR}/${BUILD_DIR}/${LD64_STUBNAME}-patched
CCTOOLS_DIR_BUILD=${TOPSRCDIR}/${BUILD_DIR}/${CCTOOLS_STUBNAME}-patched
DYLD_DIR_BUILD=${TOPSRCDIR}/${BUILD_DIR}/${DYLD_STUBNAME}-patched

if [[ "$1" == "archive-all" ]] ; then
	# Archives everything (except tarballs)
	[[ -f darwin-compilers-all.7z ]] && rm darwin-compilers-all.7z
	7za a -mx=9 darwin-compilers-all.7z bld-* build-all.sh darwin-compilers-gentoo patches *.log
	exit 0
elif [[ "$1" == "archive-src" ]] ; then
	# Archives source code (except tarballs and unpacked tarballs)
	[[ -f darwin-compilers-src.7z ]] && rm darwin-compilers-src.7z
	7za a -mx=9 darwin-compilers-src.7z build-all.sh darwin-compilers-gentoo patches
	exit 0
elif [[ "$1" == "clean" ]] ; then
	rm -rf bld-* $GCC_DIR $LD64_DIR $CCTOOLS_DIR $DYLD_DIR $GCC_DIR_BUILD $LD64_DIR_BUILD $CCTOOLS_DIR_BUILD $DYLD_DIR_BUILD *.log
	exit 0
fi

[[ -d ${BUILD_PREFIX} ]] && sudo rm -rf ${BUILD_PREFIX}

function doSed
{
#    if [ "$OSTYPE_MAJOR" = "darwin" ]
#    then
	sed -i '.bak' "$1" $2
	rm ${2}.bak
#    else
#	sed "$1" -i $2
#    fi
}

pushd ${TARBALLS}
if [[ ! -f ${GCC_STUBNAME}.tar.gz ]] ; then
	curl -S -L -O http://www.opensource.apple.com/tarballs/llvmgcc42/${GCC_STUBNAME}.tar.gz
fi
if [[ ! -f ${LD64_STUBNAME}.tar.gz ]] ; then
	curl -S -L -O http://www.opensource.apple.com/tarballs/ld64/${LD64_STUBNAME}.tar.gz
fi
if [[ ! -f ${CCTOOLS_STUBNAME}.tar.gz ]] ; then
	curl -S -L -O http://www.opensource.apple.com/tarballs/cctools/${CCTOOLS_STUBNAME}.tar.gz
fi
if [[ ! -f ${DYLD_STUBNAME}.tar.gz ]] ; then
	curl -S -L -O http://www.opensource.apple.com/tarballs/dyld/${DYLD_STUBNAME}.tar.gz
fi
if [[ ! -f streams.h ]] ; then
	curl -S -L -O http://opensource.apple.com/source/Libstreams/Libstreams-25/streams.h?txt -O streams.h
fi
popd

if [[ ! -d ${GCC_DIR} ]]; then
	tar -zxf ${TARBALLS}/${GCC_STUBNAME}.tar.gz
	pushd ${GCC_DIR}
		chmod -R +w .
		find . -exec touch {} \;
	popd
fi
if [[ ! -d ${LD64_DIR} ]]; then
	tar -zxf ${TARBALLS}/${LD64_STUBNAME}.tar.gz
	pushd ${LD64_DIR}
		chmod -R +w .
		find . -exec touch {} \;
	popd
fi
if [[ ! -d ${CCTOOLS_DIR} ]]; then
	tar -zxf ${TARBALLS}/${CCTOOLS_STUBNAME}.tar.gz
	pushd ${CCTOOLS_DIR}
		chmod -R +w .
		find . -exec touch {} \;
	popd
fi
if [[ ! -d ${DYLD_DIR} ]]; then
	tar -zxf ${TARBALLS}/${DYLD_STUBNAME}.tar.gz
	pushd ${DYLD_DIR}
		chmod -R +w .
		find . -exec touch {} \;
	popd
fi

# Clean.
rm -rf ${GCC_DIR_BUILD} ${LD64_DIR_BUILD} ${CCTOOLS_DIR_BUILD} ${DYLD_DIR_BUILD}

mkdir -p ${BUILD_PREFIX}

cp -rf ${GCC_DIR} ${GCC_DIR_BUILD}
cp -rf ${LD64_DIR} ${LD64_DIR_BUILD}
cp -rf ${CCTOOLS_DIR} ${CCTOOLS_DIR_BUILD}
cp -rf ${DYLD_DIR} ${DYLD_DIR_BUILD}

mkdir -p ${BUILD_PREFIX}/include
mkdir -p ${BUILD_PREFIX}/lib
mkdir -p ${BUILD_PREFIX}/bin
mkdir -p ${BUILD_PREFIX}/include/streams
mkdir -p ${BUILD_PREFIX}/include/mach

cp -rf ${GCC_DIR_BUILD}/llvmCore/include/llvm-c ${BUILD_PREFIX}/include/
cp tarballs/streams.h ${BUILD_PREFIX}/include/streams/
cp /usr/include/mach/mach.h ${BUILD_PREFIX}/include/mach/
cp /usr/include/mach/mach_init.h ${BUILD_PREFIX}/include/mach/
cp /usr/include/mach/mach_traps.h ${BUILD_PREFIX}/include/mach/
cp /usr/include/mach/mach_error.h ${BUILD_PREFIX}/include/mach/
cp /usr/include/mach/thread_switch.h ${BUILD_PREFIX}/include/mach/
# Only needed for pagestuff (some for ld too?)
cp /usr/include/stdlib.h ${BUILD_PREFIX}/include/
cp /usr/include/alloca.h ${BUILD_PREFIX}/include/
mkdir -p ${BUILD_PREFIX}/include/i386
mkdir -p ${BUILD_PREFIX}/include/machine
mkdir -p ${BUILD_PREFIX}/include/ppc
mkdir -p ${BUILD_PREFIX}/include/sys
mkdir -p ${BUILD_PREFIX}/include/mach-o
cp /usr/include/_types.h ${BUILD_PREFIX}/include/
cp /usr/include/i386/_types.h ${BUILD_PREFIX}/include/i386/
cp /usr/include/machine/_types.h ${BUILD_PREFIX}/include/machine/
cp /usr/include/ppc/_types.h ${BUILD_PREFIX}/include/ppc/
cp /usr/include/sys/_types.h ${BUILD_PREFIX}/include/sys/

sudo cp -rf ${CCTOOLS_DIR}/include/mach-o ${BUILD_PREFIX}/include/
sudo cp -rf ${DYLD_DIR}/include/mach-o/dyld* ${BUILD_PREFIX}/include/mach-o

pushd ${LD64_DIR_BUILD}
#	LD64_PREFIX=${BUILD_PREFIX}
#	LD64_PREFIX=
	# Must set this to nothing otherwise end up with $LD64_DESTROOT/Users/nonesuch/src.
	LD64_DESTROOT=/
	# The PREFIX doesn't seem to make any odds.
	LD64_PREFIX=${BUILD_PREFIX}
	mkdir -p obj sym dst
	# OCF is an abbreviation for OTHER_CFLAGS. Work out what we need.
	OCF_INC_DIR=-I${BUILD_PREFIX}/include
	# I'm pretty sure we don't want arm here, but it's safely ignored.
	BUILD_ARCHS="i386 x86_64 arm"
	if [[ $SAVETEMPS == 1 ]] ; then
		patch -p0 < ../../patches/ld64.project.pbxproj.use-clang.patch
		OCF_SAVE_TEMPS=-save-temps
		OCF_SAVE_TEMPS_CLANG=-save-temps
		BUILD_ARCHS="i386"
	fi
	if [[ $ARCH64 == 1 ]] ; then
		OCF_ARCH64=-DARCH64
	fi
	# I might want to only doSed for dstPath = "/usr/local/ and INSTALL_PATH = /usr/local/ and INSTALL_PATH = "$(HOME)/bin";
	doSed $"s#\$(DEVELOPER_DIR)/usr/local/#/usr/local/#" ld64.xcodeproj/project.pbxproj
	doSed $"s#/usr/local/#${BUILD_PREFIX}/#" ld64.xcodeproj/project.pbxproj
	doSed $"s#\$(HOME)/bin#${BUILD_PREFIX}/bin#" ld64.xcodeproj/project.pbxproj
	doSed $"s#INSTALL_PATH = /usr/bin#INSTALL_PATH = ${BUILD_PREFIX}/bin#" ld64.xcodeproj/project.pbxproj
	xcodebuild install -target libprunetrie ARCHS="$BUILD_ARCHS" SRCROOT=$PWD OBJROOT=$PWD/obj SYMROOT=$PWD/sym DSTROOT=${LD64_DESTROOT} PREFIX=${LD64_PREFIX} OTHER_CFLAGS="$OCF_INC_DIR $OCF_SAVE_TEMPS $OCF_ARCH64"
	xcodebuild install -target unwinddump ARCHS="$BUILD_ARCHS" SRCROOT=$PWD OBJROOT=$PWD/obj SYMROOT=$PWD/sym DSTROOT=${LD64_DESTROOT} PREFIX=${LD64_PREFIX} OTHER_CFLAGS="$OCF_INC_DIR $OCF_SAVE_TEMPS $OCF_ARCH64"
	xcodebuild install -target ld ARCHS="$BUILD_ARCHS" SRCROOT=$PWD OBJROOT=$PWD/obj SYMROOT=$PWD/sym DSTROOT=${LD64_DESTROOT} PREFIX=${LD64_PREFIX} OTHER_CFLAGS="$OCF_INC_DIR $OCF_SAVE_TEMPS_CLANG $OCF_ARCH64"
	xcodebuild install -target ObjectDump ARCHS="$BUILD_ARCHS" SRCROOT=$PWD OBJROOT=$PWD/obj SYMROOT=$PWD/sym DSTROOT=${LD64_DESTROOT} PREFIX=${LD64_PREFIX} OTHER_CFLAGS="$OCF_INC_DIR $OCF_SAVE_TEMPS $OCF_ARCH64"
	xcodebuild install -target dyldinfo ARCHS="$BUILD_ARCHS" SRCROOT=$PWD OBJROOT=$PWD/obj SYMROOT=$PWD/sym DSTROOT=${LD64_DESTROOT} PREFIX=${LD64_PREFIX} OTHER_CFLAGS="$OCF_INC_DIR $OCF_SAVE_TEMPS $OCF_ARCH64"
	xcodebuild install -target machocheck ARCHS="$BUILD_ARCHS" SRCROOT=$PWD OBJROOT=$PWD/obj SYMROOT=$PWD/sym DSTROOT=${LD64_DESTROOT} PREFIX=${LD64_PREFIX} OTHER_CFLAGS="$OCF_INC_DIR $OCF_SAVE_TEMPS $OCF_ARCH64"
	xcodebuild install -target rebase ARCHS="$BUILD_ARCHS" SRCROOT=$PWD OBJROOT=$PWD/obj SYMROOT=$PWD/sym DSTROOT=${LD64_DESTROOT} PREFIX=${LD64_PREFIX} OTHER_CFLAGS="$OCF_INC_DIR $OCF_SAVE_TEMPS $OCF_ARCH64"
#	if [[ ! "$LD64_PREFIX" = "$BUILD_PREFIX" ]] ; then
#		sudo cp -v ${LD64_PREFIX}/lib/libprunetrie.a ${BUILD_PREFIX}/lib/
#		sudo cp -rf ${LD64_PREFIX}/include/mach-o ${BUILD_PREFIX}/include/
#	fi
popd

if [[ ! -f ${BUILD_PREFIX}/include/mach-o/prune_trie.h ]] ; then
    echo "prune_trie.h didn't get installed."
    exit 1
fi

pushd ${CCTOOLS_DIR_BUILD}
	patch -p0 < ../../patches/cctools.Makefile.keep-passed-RC_CFLAGS.patch || exit 1
	patch -p0 < ../../patches/cctools-809.stuff.SWAP_LONG.patch || exit 1
	patch -p0 < ../../patches/cctools-809.include.mach-o.nlist.__LP64__.patch || exit 1
#	patch -p0 < ../../patches/cctools-809.streams.h.patch || exit 1
	patch -p0 < ../../patches/cctools-809.ld.map_fd-to-mmap.patch || exit 1
	patch -p0 < ../../patches/cctools-809.pagestuff.vm_page_size.patch || exit 1
	patch -p0 < ../../patches/cctools-809.no.kld.patch || exit 1
	patch -p0 < ../../patches/cctools-809.no.sarld.patch || exit 1

	if [[ $SAVETEMPS == 1 ]] ; then
		make RC_CFLAGS="-save-temps -I${BUILD_PREFIX}/include -L${BUILD_PREFIX}/lib" # -DARCH64"
	else
		make RC_CFLAGS="-I${BUILD_PREFIX}/include -L${BUILD_PREFIX}/lib" # -DARCH64"
	fi
popd

#mkdir -p misc/mach-o
#cp ld64-${LD64_VER}/src/other/prune_trie.h misc/mach-o/
#make RC_CFLAGS="-save-temps"
