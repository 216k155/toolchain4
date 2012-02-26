#!/bin/bash

set -e

. ../bash-tools.sh

CCTOOLSNAME=cctools
CCTOOLSVERS=782
LD64NAME=ld64
#LD64VERS=85.2.1
LD64VERS=127.2
LD64DISTFILE=${LD64NAME}-${LD64VERS}.tar.gz
DYLDNAME=dyld
# For dyld.h.
DYLDVERS=195.5
DYLDDISTFILE=${DYLDNAME}-${DYLDVERS}.tar.gz
OSXVER=10.7

TOPSRCDIR=`pwd`

MAKEDISTFILE=0
UPDATEPATCH=0
# To use MacOSX headers set USESDK to 999.
#USESDK=999
USESDK=1
FOREIGNHEADERS=

while [ $# -gt 0 ]; do
    case $1 in
	--distfile)
	    shift
	    MAKEDISTFILE=1
	    ;;
	--updatepatch)
	    shift
	    UPDATEPATCH=1
	    ;;
	--nosdk)
	    shift
	    USESDK=0
	    ;;
	--help)
	    echo "Usage: $0 [--help] [--distfile] [--updatepatch] [--nosdk]" 1>&2
	    exit 0
	    ;;
	--vers)
	    shift
	    CCTOOLSVERS=$1
	    shift
	    ;;
	--foreignheaders)
	    shift
	    FOREIGNHEADERS=-foreign-headers
	    ;;
	--osxver)
	    shift
	    OSXVER=$1
	    shift
	    ;;
	*)
	    echo "Unknown option $1" 1>&2
	    exit 1
    esac
done

CCTOOLSDISTFILE=${CCTOOLSNAME}-${CCTOOLSVERS}.tar.gz
DISTDIR=odcctools-${CCTOOLSVERS}${FOREIGNHEADERS}

USE_OSX_MACHINE_H=0
if [[ -z $FOREIGNHEADERS ]] ; then
    USE_OSX_MACHINE_H=1
fi

if [ "`tar --help | grep -- --strip-components 2> /dev/null`" ]; then
    TARSTRIP=--strip-components
elif [ "`tar --help | grep bsdtar 2> /dev/null`" ]; then
    TARSTRIP=--strip-components
else
    TARSTRIP=--strip-path
fi

PATCHFILESDIR=${TOPSRCDIR}/patches-${CCTOOLSVERS}

#PATCHFILES=`cd "${PATCHFILESDIR}" && find * -type f \! -path \*/.svn\* | sort`

if [[ ! "$(uname -s)" = "Darwin" ]] ; then
    LD64_CREATE_READER_TYPENAME_DIFF=ld64/ld_createReader_typename.diff
fi

if [[ "$LD64VERS" == "85.2.1" ]] ; then
    LD64PATCHES="ld64/FileAbstraction-inline.diff ld64/ld_cpp_signal.diff \
ld64/Options-config_h.diff ld64/Options-ctype.diff \
ld64/Options-defcross.diff ld64/Options_h_includes.diff \
ld64/Options-stdarg.diff ld64/remove_tmp_math_hack.diff \
ld64/Thread64_MachOWriterExecutable.diff ${LD64_CREATE_READER_TYPENAME_DIFF} \
ld64/ld_BaseAtom_def_fix.diff ld64/LTOReader-setasmpath.diff \
ld64/cstdio.diff"
fi

if [[ "$USE_OSX_MACHINE_H" = "0" ]] ; then
PATCHFILES="ar/archive.diff ar/ar-printf.diff ar/ar-ranlibpath.diff \
ar/contents.diff ar/declare_localtime.diff ar/errno.diff as/arm.c.diff \
as/bignum.diff as/driver.c.diff as/getc_unlocked.diff as/input-scrub.diff \
as/messages.diff as/relax.diff as/use_PRI_macros.diff \
include/mach/machine.diff include/stuff/bytesex-floatstate.diff \
${LD64PATCHES} \
ld-sysroot.diff ld/uuid-nonsmodule.diff libstuff/default_arch.diff \
libstuff/macosx_deployment_target_default_105.diff \
libstuff/map_64bit_arches.diff libstuff/sys_types.diff \
misc/libtool-ldpath.diff misc/libtool-pb.diff misc/ranlibname.diff \
misc/redo_prebinding.nogetattrlist.diff \
misc/redo_prebinding.nomalloc.diff misc/libtool_lipo_transform.diff \
otool/nolibmstub.diff otool/noobjc.diff otool/dontTypedefNXConstantString.diff \
include/mach/machine_armv7.diff \
ld/ld-nomach.diff libstuff/cmd_with_prefix.diff \
misc/with_prefix.diff misc/bootstrap_h.diff"
else
PATCHFILES="ar/archive.diff ar/ar-printf.diff ar/ar-ranlibpath.diff \
ar/contents.diff ar/declare_localtime.diff ar/errno.diff as/arm.c.diff \
as/bignum.diff as/driver.c.diff as/getc_unlocked.diff as/input-scrub.diff \
as/messages.diff as/relax.diff \
include/stuff/bytesex-floatstate.diff \
${LD64PATCHES} \
ld-sysroot.diff ld/uuid-nonsmodule.diff libstuff/default_arch.diff \
libstuff/macosx_deployment_target_default_105.diff \
libstuff/map_64bit_arches.diff libstuff/sys_types.diff \
misc/libtool-ldpath.diff misc/libtool-pb.diff misc/ranlibname.diff \
misc/redo_prebinding.nogetattrlist.diff \
misc/redo_prebinding.nomalloc.diff misc/libtool_lipo_transform.diff \
otool/nolibmstub.diff otool/noobjc.diff otool/dontTypedefNXConstantString.diff \
 include/mach/machine_armv7.diff \
ld/ld-nomach.diff libstuff/cmd_with_prefix.diff \
misc/with_prefix.diff misc/bootstrap_h.diff"
fi

ADDEDFILESDIR=${TOPSRCDIR}/files

if [[ ! "$(uname-bt)" == "Windows" ]] ; then
	PATCH_POSIX=--posix
fi

if [ -d "${DISTDIR}" ]; then
    echo "${DISTDIR} already exists. Please move aside before running" 1>&2
    exit 1
fi

rm -rf ${DISTDIR}
mkdir -p ${DISTDIR}
[[ ! -f "${CCTOOLSDISTFILE}" ]] && download http://www.opensource.apple.com/tarballs/cctools/${CCTOOLSDISTFILE}
if [[ ! -f "${CCTOOLSDISTFILE}" ]] ; then
	error "Failed to download ${CCTOOLSDISTFILE}"
	exit 1
fi

tar ${TARSTRIP}=1 -xf ${CCTOOLSDISTFILE} -C ${DISTDIR} > /dev/null 2>&1
# Fix dodgy timestamps.
find ${DISTDIR} | xargs touch

[[ ! -f "${LD64DISTFILE}" ]] && download http://www.opensource.apple.com/tarballs/ld64/${LD64DISTFILE}
if [[ ! -f "${LD64DISTFILE}" ]] ; then
	error "Failed to download ${LD64DISTFILE}"
	exit 1
fi
mkdir -p ${DISTDIR}/ld64
tar ${TARSTRIP}=1 -xf ${LD64DISTFILE} -C ${DISTDIR}/ld64
rm -rf ${DISTDIR}/ld64/FireOpal
find ${DISTDIR}/ld64 ! -perm +200 -exec chmod u+w {} \;
find ${DISTDIR}/ld64/doc/ -type f -exec cp "{}" ${DISTDIR}/man \;

[[ ! -f "${DYLDDISTFILE}" ]] && download http://www.opensource.apple.com/tarballs/dyld/${DYLDDISTFILE}
if [[ ! -f "${DYLDDISTFILE}" ]] ; then
	error "Failed to download ${DYLDDISTFILE}"
	exit 1
fi
mkdir -p ${DISTDIR}/dyld
tar ${TARSTRIP}=1 -xf ${DYLDDISTFILE} -C ${DISTDIR}/dyld

mkdir ${DISTDIR}/libprunetrie
mkdir ${DISTDIR}/libprunetrie/mach-o
cp ${DISTDIR}/ld64/src/other/prune_trie.h ${DISTDIR}/libprunetrie/
cp ${DISTDIR}/ld64/src/other/prune_trie.h ${DISTDIR}/libprunetrie/mach-o/
cp ${DISTDIR}/ld64/src/other/PruneTrie.cpp ${DISTDIR}/libprunetrie/

# Clean the source a bit
find ${DISTDIR} -name \*.orig -exec rm -f "{}" \;
rm -rf ${DISTDIR}/{cbtlibs,file,gprof,libdyld,mkshlib,profileServer}

if [[ "$(uname -s)" = "Darwin" ]] ; then
    SDKROOT=/Developer/SDKs/MacOSX${OSXVER}.sdk
else
    SDKROOT=${TOPSRCDIR}/../sdks/MacOSX${OSXVER}.sdk
fi
cp -Rf ${SDKROOT}/usr/include/objc ${DISTDIR}/include

# llvm headers
# Originally, in toolchain4, gcc used was Saurik's, but that doesn't contain
# the llvm-c headers we need.
message_status "Merging include/llvm-c from Apple's llvmgcc42-2336.1"
GCC_DIR=${TOPSRCDIR}/../llvmgcc42-2336.1
if [ ! -d $GCC_DIR ]; then
    pushd $(dirname ${GCC_DIR})
    if [[ $(download http://www.opensource.apple.com/tarballs/llvmgcc42/llvmgcc42-2336.1.tar.gz) ]] ; then
	error "Failed to download llvmgcc42-2336.1.tar.gz"
	exit 1
    fi
    tar -zxf llvmgcc42-2336.1.tar.gz
    popd
fi
cp -rf ${GCC_DIR}/llvmCore/include/llvm-c ${DISTDIR}/include/

if [[ $USESDK -eq 999 ]] || [[ ! "$FOREIGNHEADERS" = "-foreign-headers" ]]; then
    message_status "Merging content from $SDKROOT"
    if [ ! -d "$SDKROOT" ]; then
	error "$SDKROOT must be present"
	exit 1
    fi

    mv ${DISTDIR}/include/mach/machine.h ${DISTDIR}/include/mach/machine.h.new
    if [[ "$(uname-bt)" = "Darwin" ]] ; then
        SYSFLDR=sys
    else
        # Want to use the system's sys folder as much as possible.
        SYSFLDR=sys/_types.h
    fi
    for i in mach architecture i386 libkern $SYSFLDR; do
	tar cf - -C "$SDKROOT/usr/include" $i | tar xf - -C ${DISTDIR}/include
    done

    if [[ "$USE_OSX_MACHINE_H" = "1" ]] ; then
	mv ${DISTDIR}/include/mach/machine.h.new ${DISTDIR}/include/mach/machine.h
    fi

# Although this does what it's supposed to, it's not quite what's needed, as the linux version isn't
# known about at this time...
#    comment-out-rev ${DISTDIR}/include/i386/_types.h "typedef union {" "} __mbstate_t;"
    do-sed $"s/} __mbstate_t/} NONCONFLICTING__mbstate_t/" ${DISTDIR}/include/i386/_types.h
    do-sed $"s/typedef __mbstate_t/typedef NONCONFLICTING__mbstate_t/" ${DISTDIR}/include/i386/_types.h

#    rm ${DISTDIR}/include/sys/cdefs.h
#    rm ${DISTDIR}/include/sys/types.h
#    rm ${DISTDIR}/include/sys/select.h

# If this is enabled, libkern/machine/OSByteOrder.h is used instead of
# libkern/i386/OSByteOrder.h and this causes failure on Darwin, it may
# be needed on other OSes though?
#    for f in ${DISTDIR}/include/libkern/OSByteOrder.h; do
#	sed -e 's/__GNUC__/__GNUC_UNUSED__/g' < $f > $f.tmp
#	mv -f $f.tmp $f
#    done
fi

# process source for mechanical substitutions
message_status "Removing #import"
find ${DISTDIR} -type f -name \*.[ch] | while read f; do
    sed -e 's/^#import/#include/' < $f > $f.tmp
    mv -f $f.tmp $f
done

message_status "Removing __private_extern__"
find ${DISTDIR} -type f -name \*.h | while read f; do
    sed -e 's/^__private_extern__/extern/' < $f > $f.tmp
    mv -f $f.tmp $f
done

#echo "Removing static enum bool"
#find ${DISTDIR} -type f -name \*.[ch] | while read f; do
#    sed -e 's/static enum bool/static bool/' < $f > $f.tmp
#    mv -f $f.tmp $f
#done

set +e

INTERACTIVE=0
message_status "Applying patches"
for p in ${PATCHFILES}; do
    dir=`dirname $p`
    if [ $INTERACTIVE -eq 1 ]; then
	read -p "Apply patch $p? " REPLY
    else
	message_status "Applying patch $p"
    fi
    pushd ${DISTDIR}/$dir > /dev/null
    patch $PATCH_POSIX -p0 < ${PATCHFILESDIR}/$p
    if [ $? -ne 0 ]; then
	error "There was a patch failure. Please manually merge and exit the sub-shell when done"
	$SHELL
	if [ $UPDATEPATCH -eq 1 ]; then
	    find . -type f | while read f; do
		if [ -f "$f.orig" ]; then
		    diff -u -N "$f.orig" "$f"
		fi
	    done > ${PATCHFILESDIR}/$p
	fi
    fi
    # For subsequent patches to work, move orig files out of the way
    # to a filename that includes the patch name, e.g. archive.c.orig.archive.diff
    find . -type f -name \*.orig -exec mv "{}" "{}"$(basename $p) \;
    popd > /dev/null
done

set -e

message_status "Adding new files"
tar cf - --exclude=CVS --exclude=.svn -C ${ADDEDFILESDIR} . | tar xvf - -C ${DISTDIR}
mv ${DISTDIR}/ld64/Makefile.in.${LD64VERS} ${DISTDIR}/ld64/Makefile.in
if [[ "${LD64VERS}" == "127.2" ]] ; then
    echo -e "\n" > ${DISTDIR}/ld64/src/ld/configure.h
fi

if [[ $USESDK -eq 999 ]] || [[ ! "$FOREIGNHEADERS" = "-foreign-headers" ]] ; then
    if [[ $(uname-bt) = "Darwin" ]] ; then
        cp -f ${SDKROOT}/usr/include/sys/cdefs.h ${DISTDIR}/include/sys/cdefs.h
        cp -f ${SDKROOT}/usr/include/sys/types.h ${DISTDIR}/include/sys/types.h
        cp -f ${SDKROOT}/usr/include/sys/select.h ${DISTDIR}/include/sys/select.h
        # causes arch.c failures (error: ?CPU_TYPE_VEO? undeclared here (not in a function)
        # cp -f ${SDKROOT}/usr/include/mach/machine.h ${DISTDIR}/include/mach/machine.h
    fi
fi

# This works for ld64, but breaks cctools-809 itself.
# cp -f ${DISTDIR}/dyld/src/dyld.h ${DISTDIR}/include/mach-o/dyld.h
mkdir -p ${DISTDIR}/ld64/include/mach-o/
mkdir -p ${DISTDIR}/ld64/include/mach/
#cp -f ${DISTDIR}/dyld/src/dyld.h ${DISTDIR}/ld64/include/mach-o/dyld.h
#cp -f ${SDKROOT}/usr/include/mach-o/dyld.h ${DISTDIR}/ld64/include/mach-o/dyld.h
cp -f ${DISTDIR}/dyld/include/mach-o/dyld* ${DISTDIR}/ld64/include/mach-o/
#cp -f ${DISTDIR}/dyld/src/dyld_priv.h ${DISTDIR}/ld64/include/mach-o/dyld_priv.h
cp -f ${SDKROOT}/usr/include/mach/machine.h ${DISTDIR}/ld64/include/mach/machine.h

# I had been localising stuff into ld64 (above), but a lot of it is
# more generally needed?
mkdir -p ${DISTDIR}/include/machine
mkdir -p ${DISTDIR}/include/mach_debug
cp -f ${SDKROOT}/usr/include/machine/types.h ${DISTDIR}/include/machine/types.h
cp -f ${SDKROOT}/usr/include/machine/_types.h ${DISTDIR}/include/machine/_types.h
cp -f ${SDKROOT}/usr/include/machine/endian.h ${DISTDIR}/include/machine/endian.h
cp -f ${SDKROOT}/usr/include/mach_debug/mach_debug_types.h ${DISTDIR}/include/mach_debug/mach_debug_types.h
cp -f ${SDKROOT}/usr/include/mach_debug/ipc_info.h ${DISTDIR}/include/mach_debug/ipc_info.h
cp -f ${SDKROOT}/usr/include/mach_debug/vm_info.h ${DISTDIR}/include/mach_debug/vm_info.h
cp -f ${SDKROOT}/usr/include/mach_debug/zone_info.h ${DISTDIR}/include/mach_debug/zone_info.h
cp -f ${SDKROOT}/usr/include/mach_debug/page_info.h ${DISTDIR}/include/mach_debug/page_info.h
cp -f ${SDKROOT}/usr/include/mach_debug/hash_info.h ${DISTDIR}/include/mach_debug/hash_info.h
cp -f ${SDKROOT}/usr/include/mach_debug/lockgroup_info.h ${DISTDIR}/include/mach_debug/lockgroup_info.h

#cp -f ${DISTDIR}/dyld/src/ImageLoader.h ${DISTDIR}/ld64/include/ImageLoader.h
#cp -f ${DISTDIR}/dyld/src/CrashReporterClient.h ${DISTDIR}/ld64/include/CrashReporterClient.h

if [ -z $FOREIGNHEADERS ] ; then
    message_status "Removing include/foreign"
    rm -rf ${DISTDIR}/include/foreign
else
    message_status "Removing include/mach/ppc (so include/foreign/mach/ppc is used)"
    rm -rf ${DISTDIR}/include/mach/ppc
fi

message_status "Deleting cruft"
find ${DISTDIR} -name Makefile -exec rm -f "{}" \;
find ${DISTDIR} -name \*~ -exec rm -f "{}" \;
find ${DISTDIR} -name .\#\* -exec rm -f "{}" \;

pushd ${DISTDIR} > /dev/null
autoheader
autoconf
rm -rf autom4te.cache
popd > /dev/null

if [ $MAKEDISTFILE -eq 1 ]; then
    DATE=$(date +%Y%m%d)
    mv ${DISTDIR} ${DISTDIR}-$DATE
    tar jcf ${DISTDIR}-$DATE.tar.bz2 ${DISTDIR}-$DATE
fi
#patch odcctools-${CCTOOLSVERS}${FOREIGNHEADERS}/misc/Makefile.in < $PATCHFILESDIR/misc/Makefile.in.diff
