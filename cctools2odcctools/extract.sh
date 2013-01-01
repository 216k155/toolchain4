#!/bin/bash

# References. This work stands on the work done in these projects.
# Some people who provide ports of debian packages for MinGW!
# http://svn.clazzes.org/svn/mingw-pkg/trunk/macosx-deb/macosx-intel64-cctools/patches/cctools-806-nondarwin.patch  <--  with Windows fixes.
# Their home page:
# https://www.clazzes.org/projects/mingw-debian-packaging/
# Andrew's toolchain:
# https://github.com/tatsh/xchain
# Chromium uses this I think:
# http://code.google.com/p/toolwhip/
# Javacom:
# https://github.com/javacom/toolchain4
# One of the originals:
# http://code.google.com/p/iphonedevonlinux/

set -e

. ../bash-tools.sh

CCTOOLSNAME=cctools
CCTOOLSVERS=809
LD64NAME=ld64
LD64VERS=127.2
LD64DISTFILE=${LD64NAME}-${LD64VERS}.tar.gz
# For dyld.h.
DYLDNAME=dyld
DYLDVERS=195.5
DYLDDISTFILE=${DYLDNAME}-${DYLDVERS}.tar.gz
#TARBALLS_URL=http://www.opensource.apple.com/tarballs
TARBALLS_URL=$HOME/Dropbox/darwin-compilers-work/tarballs
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

LD64PATCHES="ld64/QSORT_macho_relocatable_file.diff ld64/_TYPENAME_compiler_bug.diff"

# Removed as/getc_unlocked.diff as all it did was re-include config.h
# Removed libstuff/cmd_with_prefix.diff as it's wrong.

if [[ "$USE_OSX_MACHINE_H" = "0" ]] ; then
PATCHFILES="ar/archive.diff ar/ar-printf.diff ar/ar-ranlibpath.diff \
ar/contents.diff ar/declare_localtime.diff ar/errno.diff ar/TMPDIR.diff \
as/arm.c.diff as/bignum.diff as/input-scrub.diff as/driver.c.diff \
as/messages.diff as/relax.diff as/use_PRI_macros.diff \
include/mach/machine.diff include/stuff/bytesex-floatstate.diff \
${LD64PATCHES} \
ld-sysroot.diff ld/uuid-nonsmodule.diff libstuff/default_arch.diff \
libstuff/macosx_deployment_target_default_105.diff \
libstuff/map_64bit_arches.diff libstuff/sys_types.diff \
libstuff/mingw_execute.diff libstuff/realpath_execute.diff libstuff/ofile_map_unmap_mingw.diff \
misc/libtool-ldpath.diff misc/libtool_lipo_transform.diff \
misc/ranlibname.diff misc/redo_prebinding.nogetattrlist.diff \
misc/redo_prebinding.nomalloc.diff \
otool/nolibmstub.diff otool/noobjc.diff otool/dontTypedefNXConstantString.diff \
include/mach/machine_armv7.diff \
ld/ld-nomach.diff ld/qsort_r.diff \
misc/bootstrap_h.diff"
else
# Removed as/driver.c.diff as we've got _NSGetExecutablePath.
PATCHFILES="ar/archive.diff ar/ar-printf.diff ar/ar-ranlibpath.diff \
ar/contents.diff ar/declare_localtime.diff ar/errno.diff ar/TMPDIR.diff \
as/arm.c.diff as/bignum.diff as/input-scrub.diff as/driver.c.diff \
as/messages.diff as/relax.diff \
include/stuff/bytesex-floatstate.diff \
${LD64PATCHES} \
ld-sysroot.diff ld/uuid-nonsmodule.diff libstuff/default_arch.diff \
libstuff/macosx_deployment_target_default_105.diff \
libstuff/map_64bit_arches.diff libstuff/sys_types.diff \
libstuff/mingw_execute.diff libstuff/realpath_execute.diff libstuff/ofile_map_unmap_mingw.diff \
misc/libtool-ldpath.diff misc/libtool_lipo_transform.diff \
misc/ranlibname.diff misc/redo_prebinding.nogetattrlist.diff \
misc/redo_prebinding.nomalloc.diff \
otool/nolibmstub.diff otool/noobjc.diff otool/dontTypedefNXConstantString.diff \
include/mach/machine_armv7.diff \
ld/ld-nomach.diff ld/qsort_r.diff \
misc/bootstrap_h.diff"
fi

ADDEDFILESDIR=${TOPSRCDIR}/files

# My BootstrapMinGW64.vbs doesn't install install.exe if the user selects msysgit...
# Urgh. Really, the vbs script should launch bash with a command line to finish the job.
if [ ! $(which install) ] ; then
    if [[ "$(uname_bt)" = "Windows" ]] ; then
        download http://garr.dl.sourceforge.net/project/mingw/MSYS/Base/coreutils/coreutils-5.97-3/coreutils-5.97-3-msys-1.0.13-bin.tar.lzma
        tar ${TARSTRIP}=0 -xJf coreutils-5.97-3-msys-1.0.13-bin.tar.lzma -C /tmp > /dev/null 2>&1
        cp /tmp/bin/install.exe /bin/
    fi
fi

if [[ ! "$(uname_bt)" = "Windows" ]] ; then
    PATCH_POSIX=--posix
fi

if [ -d "${DISTDIR}" ]; then
    echo "${DISTDIR} already exists. Please move aside before running" 1>&2
    exit 1
fi

rm -rf ${DISTDIR}
mkdir -p ${DISTDIR}
[[ ! -f "${CCTOOLSDISTFILE}" ]] && download $TARBALLS_URL/cctools/${CCTOOLSDISTFILE}
if [[ ! -f "${CCTOOLSDISTFILE}" ]] ; then
    error "Failed to download ${CCTOOLSDISTFILE}"
    exit 1
fi
tar ${TARSTRIP}=1 -xf ${CCTOOLSDISTFILE} -C ${DISTDIR} > /dev/null 2>&1
# Fix dodgy timestamps.
find ${DISTDIR} | xargs touch

[[ ! -f "${LD64DISTFILE}" ]] && download $TARBALLS_URL/ld64/${LD64DISTFILE}
if [[ ! -f "${LD64DISTFILE}" ]] ; then
    error "Failed to download ${LD64DISTFILE}"
    exit 1
fi
mkdir -p ${DISTDIR}/ld64
tar ${TARSTRIP}=1 -xf ${LD64DISTFILE} -C ${DISTDIR}/ld64 > /dev/null 2>&1
rm -rf ${DISTDIR}/ld64/FireOpal
find ${DISTDIR}/ld64 ! -perm +200 -exec chmod u+w {} \;
find ${DISTDIR}/ld64/doc/ -type f -exec cp "{}" ${DISTDIR}/man \;

[[ ! -f "${DYLDDISTFILE}" ]] && download $TARBALLS_URL/dyld/${DYLDDISTFILE}
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
    if [[ ! -d $SDKROOT ]] ; then
    # Sandboxing... OSX becomes more like iOS every day.
    SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX${OSXVER}.sdk
    fi
else
    SDKROOT=$(cd ${TOPSRCDIR}/../sdks/MacOSX${OSXVER}.sdk && pwd)
fi
cp -Rf ${SDKROOT}/usr/include/objc ${DISTDIR}/include

# llvm headers
# Originally, in toolchain4, gcc used was Saurik's, but that doesn't contain
# the llvm-c headers we need.
message_status "Merging include/llvm-c from Apple's llvmgcc42-2336.1"
GCC_DIR=${TOPSRCDIR}/../llvmgcc42-2336.1
if [ ! -d $GCC_DIR ]; then
    pushd $(dirname ${GCC_DIR})
    if [[ $(download $TARBALLS_URL/llvmgcc42/llvmgcc42-2336.1.tar.gz) ]] ; then
        error "Failed to download llvmgcc42-2336.1.tar.gz"
        exit 1
    fi
    tar -zxf llvmgcc42-2336.1.tar.gz
    popd
fi
cp -rf ${GCC_DIR}/llvmCore/include/llvm-c ${DISTDIR}/include/

if [[ $USESDK -eq 999 ]] || [[ ! "$FOREIGNHEADERS" = "-foreign-headers" ]]; then
    message_status "Merging content from ${SDKROOT} to ${DISTDIR}"
    if [ ! -d "$SDKROOT" ]; then
        error "$SDKROOT must be present"
        exit 1
    fi

    mv ${DISTDIR}/include/mach/machine.h ${DISTDIR}/include/mach/machine.h.new
    if [[ "$(uname_bt)" = "Darwin" ]] ; then
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

    do_sed $"s/} __mbstate_t/} NONCONFLICTING__mbstate_t/" ${DISTDIR}/include/i386/_types.h
    do_sed $"s/typedef __mbstate_t/typedef NONCONFLICTING__mbstate_t/" ${DISTDIR}/include/i386/_types.h
fi

# process source for mechanical substitutions
message_status "Removing #import"
find ${DISTDIR} -type f -name \*.[ch] | while read f; do
    sed -e 's/^#import/#include/' < $f > $f.tmp
    mv -f $f.tmp $f
done

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
    echo $PWD
    echo $p
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

message_status "Adding new files to $DISTDIR"

tar cf - --exclude=CVS --exclude=.svn -C ${ADDEDFILESDIR} . | tar xvf - -C ${DISTDIR}
mv ${DISTDIR}/ld64/Makefile.in.${LD64VERS} ${DISTDIR}/ld64/Makefile.in
if [[ "${LD64VERS}" == "127.2" ]] ; then
    echo -e "\n" > ${DISTDIR}/ld64/src/ld/configure.h
fi

if [[ $USESDK -eq 999 ]] || [[ ! "$FOREIGNHEADERS" = "-foreign-headers" ]] ; then
    if [[ $(uname_bt) = "Darwin" ]] ; then
        cp -f ${SDKROOT}/usr/include/sys/cdefs.h ${DISTDIR}/include/sys/cdefs.h
        cp -f ${SDKROOT}/usr/include/sys/types.h ${DISTDIR}/include/sys/types.h
        cp -f ${SDKROOT}/usr/include/sys/select.h ${DISTDIR}/include/sys/select.h
    fi
fi

mkdir -p ${DISTDIR}/ld64/include/mach-o/
mkdir -p ${DISTDIR}/ld64/include/mach/
mkdir -p ${DISTDIR}/include/mach-o/
cp -f ${DISTDIR}/dyld/include/mach-o/dyld* ${DISTDIR}/ld64/include/mach-o/
cp -f ${SDKROOT}/usr/include/mach/machine.h ${DISTDIR}/ld64/include/mach/machine.h
cp -f ${SDKROOT}/usr/include/TargetConditionals.h ${DISTDIR}/include/TargetConditionals.h
cp -f ${SDKROOT}/usr/include/ar.h ${DISTDIR}/include/ar.h

do_sed $"s^#if defined(__GNUC__) && ( defined(__APPLE_CPP__) || defined(__APPLE_CC__) || defined(__MACOS_CLASSIC__) )^#if defined(__GNUC__)^" ${DISTDIR}/include/TargetConditionals.h

mkdir -p ${DISTDIR}/libprunetrie/include/mach-o
cp -f ${SDKROOT}/usr/include/mach-o/compact_unwind_encoding.h ${DISTDIR}/libprunetrie/include/mach-o/
cp -f ${SDKROOT}/usr/include/mach-o/compact_unwind_encoding.h ${DISTDIR}/include/mach-o/

# I had been localising stuff into ld64 (above), but a lot of it is
# more generally needed?
mkdir -p ${DISTDIR}/include/machine
mkdir -p ${DISTDIR}/include/mach_debug
mkdir -p ${DISTDIR}/include/CommonCrypto
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
cp -f ${SDKROOT}/usr/include/Availability.h ${DISTDIR}/include/Availability.h
cp -f ${SDKROOT}/usr/include/AvailabilityInternal.h ${DISTDIR}/include/AvailabilityInternal.h
cp -f ${SDKROOT}/usr/include/CommonCrypto/CommonDigest.h ${DISTDIR}/include/CommonCrypto/CommonDigest.h
cp -f ${SDKROOT}/usr/include/libunwind.h ${DISTDIR}/include/libunwind.h
cp -f ${SDKROOT}/usr/include/AvailabilityMacros.h ${DISTDIR}/include/AvailabilityMacros.h

if [ -z $FOREIGNHEADERS ] ; then
    message_status "Removing include/foreign"
    rm -rf ${DISTDIR}/include/foreign
else
    message_status "Removing include/mach/ppc (so include/foreign/mach/ppc is used)"
    rm -rf ${DISTDIR}/include/mach/ppc
fi

# ppc64 is disabled on non-darwin native builds, so let's re-enable it -> shouldn't break darwin native.
do_sed $"s^#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)^//#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)^" ${DISTDIR}/include/mach/ppc/thread_status.h
do_sed $"s%#endif /\* (_POSIX_C_SOURCE && !_DARWIN_C_SOURCE)%//#endif /\* _POSIX_C_SOURCE && !_DARWIN_C_SOURCE%" ${DISTDIR}/include/mach/ppc/thread_status.h

do_sed $"s^#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)^//#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)^" ${DISTDIR}/include/mach/ppc/_structs.h
do_sed $"s%#endif /\* (_POSIX_C_SOURCE && !_DARWIN_C_SOURCE)%//#endif /\* _POSIX_C_SOURCE && !_DARWIN_C_SOURCE%" ${DISTDIR}/include/mach/ppc/_structs.h

# libstuff
do_sed $"s^if(sysctl(osversion_name, 2, osversion, &osversion_len, NULL, 0) == -1)^strcpy(osversion,\"12.0\");^" ${DISTDIR}/libstuff/macosx_deployment_target.c
do_sed $"s^system_error(\"sysctl for kern.osversion failed\");^^" ${DISTDIR}/libstuff/macosx_deployment_target.c

do_sed $":a;N;\$!ba;s^__private_extern__\nvoid\nerror^__private_extern__\n#ifndef __MINGW32__\n__attribute__\(\(weak\)\)\n#endif\nvoid\nerror^" ${DISTDIR}/libstuff/errors.c

do_sed $"s^#include <sys/sysctl.h>^#if defined(__unused) \&\& defined(__linux__)\n#undef __unused\n#endif\n#include <sys/sysctl.h>^" ${DISTDIR}/libstuff/macosx_deployment_target.c

do_sed $"s^#include <unistd.h>^#include <unistd.h>\n#include <stdint.h>\n^" ${DISTDIR}/ar/contents.c

do_sed $"s^if(realpath == NULL)^#ifndef __MINGW32__\nif(realpath == NULL)\n#else\nif(prefix == NULL)\n#endif^" ${DISTDIR}/as/driver.c
do_sed $"s^    const char \*AS = \"/as\";^    const char \*AS = \"/as\" EXEEXT;\n^" ${DISTDIR}/as/driver.c

do_sed $"s^#include <stdlib.h>^#include <stdlib.h>\n#include <stdint.h>\n^" ${DISTDIR}/as/obstack.c

do_sed $"s^#include <strings.h>^#include <strings.h>\n#include <string.h>\n^" ${DISTDIR}/as/sections.c

do_sed $"s^extern \"C\" double log2 ( double );^#ifdef __APPLE__\nextern \"C\" double log2 ( double );\n#endif\n#include <libc.h>^" ${DISTDIR}/ld64/src/ld/ld.cpp

do_sed $"s^void __assert_rtn(const char\* func, const char\* file, int line, const char\* failedexpr)^extern \"C\" void __assert_rtn(const char\* func, const char\* file, int line, const char\* failedexpr);\nvoid __assert_rtn(const char\* func, const char\* file, int line, const char\* failedexpr)^" ${DISTDIR}/ld64/src/ld/ld.cpp

do_sed $"s^#include <unistd.h>^#include <unistd.h>\n#ifndef __APPLE__\n#include <uuid/uuid.h>\n#endif^" ${DISTDIR}/ld64/include/mach-o/dyld_images.h

do_sed $"s^#ifdef VM_SYNC_DEACTIVATE^#if defined(VM_SYNC_DEACTIVATE) \&\& (HAVE_DECL_VM_MSYNC)^"  ${DISTDIR}/ld/pass1.c
do_sed $"s^#ifdef VM_SYNC_DEACTIVATE^#if defined(VM_SYNC_DEACTIVATE) \&\& (HAVE_DECL_VM_MSYNC)^"  ${DISTDIR}/ld/pass2.c
do_sed $"s^#ifdef VM_SYNC_DEACTIVATE^#if defined(VM_SYNC_DEACTIVATE) \&\& (HAVE_DECL_VM_MSYNC)^"  ${DISTDIR}/misc/libtool.c

# Fix binary files being written out (and read in) as ascii on Windows. It'd be better if could just turn off ascii reads and writes.
do_sed $"s^O_WRONLY | O_CREAT | O_TRUNC^O_WRONLY | O_CREAT | O_TRUNC | O_BINARY^"   ${DISTDIR}/ld/rld.c
do_sed $"s^O_WRONLY | O_CREAT | O_TRUNC^O_WRONLY | O_CREAT | O_TRUNC | O_BINARY^"   ${DISTDIR}/as/write_object.c
do_sed $"s^O_WRONLY^O_WRONLY | O_BINARY^"                                           ${DISTDIR}/misc/libtool.c
do_sed $"s^O_WRONLY | O_CREAT | O_TRUNC^O_WRONLY | O_CREAT | O_TRUNC | O_BINARY^"   ${DISTDIR}/misc/lipo.c
do_sed $"s^O_CREAT|O_RDWR^O_CREAT|O_RDWR|O_BINARY^"                                 ${DISTDIR}/ar/append.c
do_sed $"s^O_CREAT|O_RDWR^O_CREAT|O_RDWR|O_BINARY^"                                 ${DISTDIR}/ar/replace.c
do_sed $"s^O_RDONLY)^O_RDONLY|O_BINARY)^"                                           ${DISTDIR}/ar/replace.c
do_sed $"s^O_CREAT | O_EXLOCK | O_RDWR^O_CREAT | O_EXLOCK | O_RDWR | O_BINARY^"     ${DISTDIR}/dyld/launch-cache/dsc_extractor.cpp
do_sed $"s^O_CREAT | O_RDWR | O_TRUNC^O_CREAT | O_RDWR | O_TRUNC | O_BINARY^"       ${DISTDIR}/dyld/launch-cache/update_dyld_shared_cache.cpp
do_sed $"s^O_CREAT | O_RDWR | O_TRUNC^O_CREAT | O_RDWR | O_TRUNC | O_BINARY^"       ${DISTDIR}/dyld/launch-cache/update_dyld_shared_cache.cpp
do_sed $"s^O_WRONLY|O_CREAT|O_TRUNC^O_WRONLY|O_CREAT|O_TRUNC|O_BINARY^"             ${DISTDIR}/efitools/makerelocs.c
do_sed $"s^O_WRONLY|O_CREAT|O_TRUNC^O_WRONLY|O_CREAT|O_TRUNC|O_BINARY^"             ${DISTDIR}/efitools/mtoc.c
do_sed $"s^archive, mode^archive, mode|O_BINARY^"                                   ${DISTDIR}/ar/archive.c
do_sed $"s^O_WRONLY|O_CREAT|O_TRUNC^O_WRONLY|O_CREAT|O_TRUNC|O_BINARY^"             ${DISTDIR}/ar/extract.c
do_sed $"s^O_TRUNC, 0666^O_TRUNC | O_BINARY, 0666^"                                 ${DISTDIR}/misc/segedit.c
do_sed $"s^O_WRONLY|O_CREAT|O_TRUNC|fsync^O_WRONLY|O_CREAT|O_TRUNC|O_BINARY|fsync^" ${DISTDIR}/libstuff/writeout.c
do_sed $"s^O_RDONLY^O_RDONLY|O_BINARY^"                                             ${DISTDIR}/libstuff/ofile.c
do_sed $"s^O_CREAT | O_WRONLY | O_TRUNC^O_CREAT | O_WRONLY | O_TRUNC | O_BINARY^"   ${DISTDIR}/ld64/src/ld/OutputFile.cpp
do_sed $"s^O_CREAT | O_WRONLY | O_TRUNC^O_CREAT | O_WRONLY | O_TRUNC | O_BINARY^"   ${DISTDIR}/ld64/src/ld/lto_file.hpp
do_sed $"s^O_CREAT | O_WRONLY | O_TRUNC^O_CREAT | O_WRONLY | O_TRUNC | O_BINARY^"   ${DISTDIR}/ld64/src/ld/parsers/lto_file.cpp
do_sed $"s^O_CREAT | O_RDWR | O_TRUNC^O_CREAT | O_RDWR | O_TRUNC | O_BINARY^"       ${DISTDIR}/ld64/src/other/rebase.cpp
do_sed $"s^O_RDWR : O_RDONLY^O_RDWR|O_BINARY : O_RDONLY|O_BINARY^"                  ${DISTDIR}/ld64/src/other/rebase.cpp
do_sed $"s^O_RDONLY, 0)^O_RDONLY|O_BINARY, 0)^"                                     ${DISTDIR}/ld64/src/ld/Options.cpp
do_sed $"s^O_CREAT | O_WRONLY | O_TRUNC ^O_CREAT | O_WRONLY | O_TRUNC | O_BINARY^"  ${DISTDIR}/misc/segedit.c
do_sed $"s^O_RDONLY^O_RDONLY|O_BINARY^"                                             ${DISTDIR}/misc/segedit.c
do_sed $"s^O_WRONLY|O_CREAT^O_WRONLY|O_CREAT|O_BINARY^"                             ${DISTDIR}/misc/strip.c
do_sed $"s^O_RDONLY^O_RDONLY|O_BINARY^"                                             ${DISTDIR}/misc/strip.c
#do_sed $"s^#include <libc.h>^#ifdef __APPLE__\n#include <libc.h>\n#else\n#include <stdio.h>\n#include <stdlib.h>\n#include <fcntl.h>\n#include <sys/param.h>\n#include <io.h>\n#endif^" ${DISTDIR}/ld64/src/ld/Options.cpp

# Need unistd.h for sleep() on MinGW-w64.
do_sed $"s^#include <sys/stat.h>^#include <sys/stat.h>\n#include <unistd.h>^" ${DISTDIR}/ar/archive.c

# I don't think these any point to these changes anymore!
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/ld/rld.c
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/ld/ld.c
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/ld/pass2.c
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/as/write_object.c
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/dyld/src/dyld.cpp
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/dyld/src/dyld.cpp
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/misc/libtool.c
do_sed $"s^07777^FIO_MASK_ALL_4^"     ${DISTDIR}/misc/lipo.c
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/misc/codesign_allocate.c
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/misc/ctf_insert.c
do_sed $"s^0644^FIO_READ_WRITE^"      ${DISTDIR}/dyld/launch-cache/dsc_extractor.cpp
do_sed $"s^0644^FIO_READ_WRITE^"      ${DISTDIR}/dyld/launch-cache/update_dyld_shared_cache.cpp
do_sed $"s^0644^FIO_READ_WRITE^"      ${DISTDIR}/efitools/makerelocs.c
do_sed $"s^0644^FIO_READ_WRITE^"      ${DISTDIR}/efitools/mtoc.c
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/ld64/src/ld/InputFiles.cpp
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/misc/segedit.c
do_sed $"s^07777^FIO_MASK_ALL_4^"     ${DISTDIR}/misc/redo_prebinding.c
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/misc/inout.c
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/misc/install_name_tool.c
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/ld64/src/ld/OutputFile.cpp
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/ld64/src/ld/OutputFile.cpp
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/ld64/src/ld/lto_file.hpp
do_sed $"s^0666^FIO_READ_WRITE^"      ${DISTDIR}/ld64/src/ld/parsers/lto_file.cpp
do_sed $"s^0600^FIO_READ_WRITE_ME^"   ${DISTDIR}/misc/strip.c
do_sed $"s^0777^FIO_READ_WRITE_EXEC^" ${DISTDIR}/misc/strip.c

AUTOHEADER=autoheader
AUTOCONF=autoconf
AUTORECONF=autoreconf

# MinGW falls over, because pformat.c doesn't handle qd, so instead, change it lld.
do_sed $"s^10qd^10lld^"    ${DISTDIR}/ar/archive.h

message_status "Deleting cruft"
find ${DISTDIR} -name Makefile -exec rm -f "{}" \;
find ${DISTDIR} -name \*~ -exec rm -f "{}" \;
find ${DISTDIR} -name .\#\* -exec rm -f "{}" \;

pushd ${DISTDIR} > /dev/null
message_status $PWD
$AUTORECONF -vi
popd > /dev/null

if [ $MAKEDISTFILE -eq 1 ]; then
    DATE=$(date +%Y%m%d)
    mv ${DISTDIR} ${DISTDIR}-$DATE
    tar jcf ${DISTDIR}-$DATE.tar.bz2 ${DISTDIR}-$DATE
fi
