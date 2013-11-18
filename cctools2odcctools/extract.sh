#!/bin/bash

# References. This work stands on the work done in these projects.
# Mainly odcctools work done by Shantonu Sen then updated by Peter O'Gorman
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

# Significantly different files on Darwin:
# libprunetrie/include/mach-o/compact_unwind_encoding.h  ->  More modern - Ivybridge added, APSL 2 licensed.
# include/architecture/alignment.h                       ->  Darwin version is missing #elif defined (__arm__) #include "architecture/arm/alignment.h"
# include/CommonCrypto/CommonDigest.h                    ->  Darwin changed to __OSX_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_5_0); from ... __IPHONE_NA);
# include/libkern/OSTypes.h                              ->  A load of stuff has been removed from newer Darwin version: #if defined(__LP64__) && defined(KERNEL)

# Analysis of odcctools patches
# *********** ar/ar.c
# XX  +#include "stuff/allocate.h"
# XX ..is not needed on either Linux or Windows
# +	    add_execute_list_with_prefix(RANLIBPROG);
# ..is still needed.
# *********** ar/archive.c
# XX  /*		case EBADRPC: */ ...is no longer needed, definition moved to configure.ac
# #if defined(__APPLE__)
# tv_sec = (long int)sb->st_mtimespec.tv_sec;
# +#else
# +			tv_sec = (long int)sb->st_mtime;
# +#endif
# ..is still needed                                                                                  (time_fixes.patch)
# +			    sb->st_mode, (int64_t)sb->st_size, ARFMAG);
# ..is still needed (warning fix)                                                                    (printf_format_bugs.patch)
# *********** ar/contents.c
# #include <time.h>
# ..is still needed                                                                                  (time_fixes.patch)
# (int64_t)chdr.size);
# ..is still needed (warning fix)                                                                    (printf_format_bugs.patch)
# Make an include file called:
# <servers/bootstrap.h>
# Make an include file called:
# <tzfile.h>
# *********** ar/misc.c
# + #define TMPDIR "TEMP" etc etc                                                                    (win_TMPDIR_as_TEMP.patch)
# XX -	errno = EFTYPE; -> added for configure.ac
# ************ as/arm.c
# ## All of this #define CPU_SUBTYPE_ , N_ARM_THUMB_DEF
# ************ as/bignum.c
# +#ifndef _BIGNUM_H_                                                                                (add_compile_guards.patch)
# ************ as/driver.c
# +	if(progname != NULL){                                                                        (as_driver_default_exename_to_argv0.patch)
# +	    strcpy(p, progname);
# +	}
# #ifndef __MINGW32__                          <- patch_misc_host...patch if(realpath == NULL)       <NOT SURE WHAT TO DO WITH THIS?>
#   if(realpath == NULL)
# #else
#   if(prefix == NULL)
# #endif
# ************ as/input-scrub.c
#+      fprintf (stderr, "%s.", strerror(errno));                                                    (use_strerror.patch) <- this won't work for some of the errors configure.ac defines.
# ************ /as/messages.c
# #include <servers/bootstrap.h>              <- make an empty include file.
# ************ as/relax.h
# #ifndef _RELAX_H_                                                                                  (add_compile_guards.patch - bignum.diff + relax.diff )
# ************ include/stuff/bytesex.h
# #ifdef _STRUCT_X86_FLOAT_STATE32           <- unneeded!
# ************ ld/ld.c
# #if defined(__OPENSTEP__) || defined(__GONZO_BUNSEN_BEAKER__) <- make an empty include file (bootstrap.h)
# ************ ld/uuid.c
# #if !(defined(KLD) && defined(__STATIC__)) <- can all vanish... ld_classic isn't even built + this isn't needed anyway.
# ************ ld64/src/ld/parsers/macho_relocatable_file.cpp
# #ifdef HAVE_BSD_QSORT_R                                                                            (allow_glibc_or_bsd_qsort_r.patch)
# // Work around for an old compiler bug.                                                            (add_typename_ld64.patch)
# _TYPENAME libunwind::CFI_Atom_Info<CFISection<x86_64>::OAS>::CFI_Atom_Info cfiArray[],             (add_typename_ld64.patch)
# ************ libstuff/execute.c
# #if defined(__MINGW32__)                                                                           (win__spawnvp_execute.patch)
# strcpy(resolved_name,p);                                                                           (realpath_execute.patch)
# ************ libstuff/get_arch_from_host.c                                                         (default_arch.patch            -   libstuff/default_arch.diff)
# ************ libstuff/macosx_deployment_target.c                                                   (macosx_deployment_target_default_10_5.patch - macosx_deployment_target_default_105.diff)
# ************ libstuff/ofile.c                                                                      (win_avoid_mmap_ofile.patch)
# ************ libstuff/ofile_error.c       <- unneeded!
# ************ libstuff/swap_headers.c      <- unneeded!
# ************ misc/libtool.c                    <- instead make an empty <server/bootstrap.h>
# -	/* see if this is being run as ranlib */                                                     (ranlibname.patch                - ranlibname.diff)
# +#ifdef CROSS_SYSROOT                    <-                                                        (cross_sysroot_option.patch)     - ld-sysroot.diff + Options-defcross.diff)
# add_execute_list(makestr(BINDIR, "/", LDPROG, NULL));
# add_execute_list(makestr(BINDIR, "/", LIPOPROG, NULL));                                            (libtool_prefix_relative_paths.patch  - libtool_lipo_transform.diff + libtool-ldpath.diff)

# ************ misc/redo_prebinding.c
# -#include <malloc/malloc.h>               <- unneeded! make malloc/malloc.h file.                                                       - redo_prebinding.nomalloc.diff)
# +#if HAVE_GETATTRLIST                                                                              (redo_prebinding_nogetattrlist.patch - redo_prebinding.nogetattrlist.patch)
# ************ otool/main.c
# +#ifdef HAVE_OBJC_OBJC_RUNTIME_H         <- hopefully unneeded!                                    (                                    - noobjc.diff)

set -e

. ../bash-tools.sh

CCTOOLSNAME=cctools
CCTOOLSVERS=809
LD64NAME=ld64
LD64VERS=127.2
GCCLLVMVERS=2336.1
LD64DISTFILE=${LD64NAME}-${LD64VERS}.tar.gz
# For dyld.h.
DYLDNAME=dyld
#DYLDVERS=195.5
DYLDVERS=210.2.3

DYLDDISTFILE=${DYLDNAME}-${DYLDVERS}.tar.gz
#TARBALLS_URL=http://www.opensource.apple.com/tarballs
TARBALLS_URL=$HOME/Dropbox/darwin-compilers-work/tarballs
OSXVER=10.6

PATCHESMAKE=1
PATCHESUSE=0

TOPSRCDIR=`pwd`

MAKEDISTFILE=0
UPDATEPATCH=0
# To use MacOSX headers set USESDK to 999.
#USESDK=999
USESDK=1
FOREIGNHEADERS=

AUTOHEADER=autoheader
AUTOCONF=autoconf
AUTORECONF=autoreconf

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

if [ "$PATCHESMAKE" = "1" ] ; then
    rm -rf $PWD/*.patch
fi

PATCHNUM=100
patch_to_from() {
    local _FUNC=$1
    local _PATCH=$2
    local _DIR=$3
    local _PREFIX=$(printf "%03d" $PATCHNUM)
    local _FULLPATCH=$PWD/$_PREFIX-$_PATCH

    if [ "$PATCHESUSE" = "1" ] ; then
        message_status "Applying patch: $_FULLPATCH"
        pushd $_DIR
        patch -p1 < $_FULLPATCH
        popd
    else
        if [ "$PATCHESMAKE" = "1" ] ; then
            rm -rf a b
            cp -rf $_DIR a
        fi
        message_status "Applying bash function: $_FUNC..."
        "$_FUNC"
        if [ "$PATCHESMAKE" = "1" ] ; then
            cp -rf $_DIR b
        fi
    fi

    if [ "$PATCHESMAKE" = "1" ] ; then
        message_status "...and making a patch from result: $_FULLPATCH"
        diff -urN a b > $_PREFIX-$_PATCH
    fi
    PATCHNUM=$(expr $PATCHNUM + 10)
}

CCTOOLSDISTFILE=${CCTOOLSNAME}-${CCTOOLSVERS}.tar.gz
DISTDIR=odcctools-${CCTOOLSVERS}${FOREIGNHEADERS}

if [[ "$(uname -s)" = "Darwin" ]] ; then
    SDKROOT=/Developer/SDKs/MacOSX${OSXVER}.sdk
    if [[ ! -d $SDKROOT ]] ; then
        # Sandboxing... OSX becomes more like iOS every day.
        SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX${OSXVER}.sdk
    fi
else
    SDKROOT=$(cd ${HOME}/MacOSX${OSXVER}.sdk && pwd)
fi

USE_OSX_MACHINE_H=0
if [[ -z $FOREIGNHEADERS ]] ; then
    USE_OSX_MACHINE_H=1
fi
message_status "USE_OSX_MACHINE_H is $USE_OSX_MACHINE_H"

if [ "`tar --help | grep -- --strip-components 2> /dev/null`" ]; then
    TARSTRIP=--strip-components
elif [ "`tar --help | grep bsdtar 2> /dev/null`" ]; then
    TARSTRIP=--strip-components
else
    TARSTRIP=--strip-path
fi

PATCHFILESDIR=${TOPSRCDIR}/patches-${CCTOOLSVERS}

if [[ ! "$(uname -s)" = "Darwin" ]] ; then
    LD64_CREATE_READER_TYPENAME_DIFF=ld64/ld_createReader_typename.diff
fi

PATCHFILES_TIME="ar/archive.diff ar/declare_localtime.diff"
PATCHFILES_QSORT_R="ld/qsort_r.diff ld64/QSORT_macho_relocatable_file.diff"
PATCHFILES_ADD_COMPILEGUARDS="as/bignum.diff as/relax.diff"
PATCHFILES_PRINTF_FORMAT_BUG="ar/ar-printf.diff"    # The patch formed from this also includes some sedding for qd->lld.
PATCHFILES_CROSS_SYSROOT="ld-sysroot.diff ld64/Options-defcross.diff"
PATCHFILES_DEFAULT_ARCH="libstuff/default_arch.diff"
PATCHFILES_ADD_TYPENAME_LD64="ld64/_TYPENAME_compiler_bug.diff"
PATCHFILES_MACOSX_DEPLOYMENT_TARGET="libstuff/macosx_deployment_target_default_105.diff"
PATCHFILES_MAP_64BIT_ARCHES="libstuff/map_64bit_arches.diff"
PATCHFILES_DONT_TYPEDEF_NXCONSTANTSTRING="otool/dontTypedefNXConstantString.diff"
PATCHFILES_CROSS_PREFIXES="ar/ar-ranlibpath.diff misc/libtool_lipo_transform.diff misc/libtool-ldpath.diff"
PATCHFILES_PROGNAME_FIXES="as/driver.c.diff libstuff/realpath_execute.diff misc/libtool_progname_fixes.diff"
PATCHFILES_STRERROR="as/input-scrub.diff"
PATCHFILES_DONT_ASSUME_GETATTRLIST="misc/redo_prebinding.nogetattrlist.diff"
PATCHFILES_WIN_TMPDIR="ar/TMPDIR.diff"
PATCHFILES_WIN_EXECUTE="libstuff/mingw_execute.diff"
PATCHFILES_WIN_AVOID_MMAP_OFILE="libstuff/ofile_map_unmap_mingw.diff"

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

#
# cctools
#
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

#
# ld64
#
mkdir -p ${DISTDIR}/ld64
tar ${TARSTRIP}=1 -xf ${LD64DISTFILE} -C ${DISTDIR}/ld64 > /dev/null 2>&1

find ${DISTDIR}/ld64 ! -perm +200 -exec chmod u+w {} \;
find ${DISTDIR}/ld64/doc/ -type f -exec cp "{}" ${DISTDIR}/man \;

[[ ! -f "${DYLDDISTFILE}" ]] && download $TARBALLS_URL/dyld/${DYLDDISTFILE}
if [[ ! -f "${DYLDDISTFILE}" ]] ; then
    error "Failed to download ${DYLDDISTFILE}"
    exit 1
fi

#
# dyld
#
mkdir -p ${DISTDIR}/dyld
tar ${TARSTRIP}=1 -xf ${DYLDDISTFILE} -C ${DISTDIR}/dyld

#
# libprunetrie
#
mkdir ${DISTDIR}/libprunetrie
mkdir -p ${DISTDIR}/include/mach-o
#cp ${DISTDIR}/ld64/src/other/prune_trie.h  ${DISTDIR}/libprunetrie/
cp ${DISTDIR}/ld64/src/other/prune_trie.h  ${DISTDIR}/include/mach-o/
cp ${DISTDIR}/ld64/src/other/PruneTrie.cpp ${DISTDIR}/libprunetrie/

#
# llvm headers
#
message_status "Merging include/llvm-c from Apple's llvmgcc42-${GCCLLVMVERS}"
GCC_DIR=${TOPSRCDIR}/../llvmgcc42-${GCCLLVMVERS}
if [ ! -d $GCC_DIR ]; then
    pushd $(dirname ${GCC_DIR})
    if [[ $(download $TARBALLS_URL/llvmgcc42/llvmgcc42-${GCCLLVMVERS}.tar.gz) ]] ; then
        error "Failed to download llvmgcc42-${GCCLLVMVERS}.tar.gz"
        exit 1
    fi
    tar -zxf llvmgcc42-${GCCLLVMVERS}.tar.gz
    popd
fi
cp -rf ${GCC_DIR}/llvmCore/include/llvm-c ${DISTDIR}/include/

#
# EVERYTHING ABOVE THIS COMMENT IS NOT HANDLED VIA PATCHING.
# EVERYTHING BELOW THIS COMMENT IS HANDLED VIA PATCHING
#

patch_clean_sources() {
    message_status "Deleting cruft"
    find ${DISTDIR} -name \*.orig -exec rm -f "{}" \;
    rm -rf ${DISTDIR}/{cbtlibs,file,gprof,libdyld,mkshlib,profileServer,ld64/FireOpal}
    find ${DISTDIR} -name Makefile -exec rm -f "{}" \;
    find ${DISTDIR} -name \*~ -exec rm -f "{}" \;
    find ${DISTDIR} -name .\#\* -exec rm -f "{}" \;
}

set +e
#patch_to_from patch_clean_sources clean_sources.patch $DISTDIR

patch_add_sdkroot_headers1() {
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

        # For Linux x86_64 hosts. We get conflicting types otherwise.
        do_sed $"s/^typedef long long\t\t__int64_t;$/\/* __int64_t and __uint64_t unified with Linux x86-64 bits\/types.h for crosstool-ng *\/\n#if defined\(__LP64__\) \&\& defined\(__linux__\)\ntypedef signed long int\t\t__int64_t;\n#else\ntypedef long long\t\t__int64_t;\n#endif/" ${DISTDIR}/include/i386/_types.h
        do_sed $"s/^typedef unsigned long long\t__uint64_t;$/#if defined\(__LP64__\) \&\& defined\(__linux__\)\ntypedef unsigned long int\t__uint64_t;\n#else\ntypedef unsigned long long\t\t__uint64_t;\n#endif\n/" ${DISTDIR}/include/i386/_types.h

    fi
}

# patch_to_from patch_add_sdkroot_headers1 add_sdkroot_headers1.patch $DISTDIR

patch_add_sdkroot_headers2() {
    mkdir -p ${DISTDIR}/include/machine
    mkdir -p ${DISTDIR}/include/mach_debug
    cp -f ${SDKROOT}/usr/include/machine/types.h               ${DISTDIR}/include/machine/types.h
    cp -f ${SDKROOT}/usr/include/machine/_types.h              ${DISTDIR}/include/machine/_types.h
    cp -f ${SDKROOT}/usr/include/machine/endian.h              ${DISTDIR}/include/machine/endian.h
    cp -f ${SDKROOT}/usr/include/mach_debug/mach_debug_types.h ${DISTDIR}/include/mach_debug/mach_debug_types.h
    cp -f ${SDKROOT}/usr/include/mach_debug/ipc_info.h         ${DISTDIR}/include/mach_debug/ipc_info.h
    cp -f ${SDKROOT}/usr/include/mach_debug/vm_info.h          ${DISTDIR}/include/mach_debug/vm_info.h
    cp -f ${SDKROOT}/usr/include/mach_debug/zone_info.h        ${DISTDIR}/include/mach_debug/zone_info.h
    cp -f ${SDKROOT}/usr/include/mach_debug/page_info.h        ${DISTDIR}/include/mach_debug/page_info.h
    cp -f ${SDKROOT}/usr/include/mach_debug/hash_info.h        ${DISTDIR}/include/mach_debug/hash_info.h
    cp -f ${SDKROOT}/usr/include/mach_debug/lockgroup_info.h   ${DISTDIR}/include/mach_debug/lockgroup_info.h
    cp -f ${SDKROOT}/usr/include/Availability.h                ${DISTDIR}/include/Availability.h
    cp -f ${SDKROOT}/usr/include/AvailabilityMacros.h          ${DISTDIR}/include/AvailabilityMacros.h
    cp -f ${SDKROOT}/usr/include/AvailabilityInternal.h        ${DISTDIR}/include/AvailabilityInternal.h
    cp -f ${SDKROOT}/usr/include/libunwind.h                   ${DISTDIR}/include/libunwind.h
    cp -Rf ${SDKROOT}/usr/include/objc                         ${DISTDIR}/include/

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

    cp -f ${SDKROOT}/usr/include/mach-o/compact_unwind_encoding.h ${DISTDIR}/include/mach-o/
}

# patch_to_from patch_add_sdkroot_headers2 add_sdkroot_headers2.patch $DISTDIR

patch_add_sdkroot_headers() {
    patch_add_sdkroot_headers1
    patch_add_sdkroot_headers2
}

patch_to_from patch_add_sdkroot_headers add_sdkroot_headers.patch $DISTDIR

# process source for mechanical substitutions
patch_import_to_include() {
    message_status "Removing #import"
    FILES=$(find ${DISTDIR})
    for FILE in $FILES; do
        chmod +w $FILE
    done
    FILES=$(find ${DISTDIR} -type f -name \*.[ch])
    for FILE in $FILES; do
        chmod +w $FILE
        do_sed $"s/^#import/#include/" $FILE
    done
}

patch_to_from patch_import_to_include import_to_include.patch $DISTDIR

patch_apply_odcctools_patches() {
    local _PATCHFILES="$1"
    INTERACTIVE=0
    message_status "Applying patches"
    for p in ${_PATCHFILES}; do
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
        find . -type f -name \*.orig -exec mv "{}" "{}".$(basename $p) \;
        popd > /dev/null
    done
    find . -type f -name "*.orig\.*" -exec rm "{}" \;
}

patch_apply_odcctools_patches_unsorted() {
    patch_apply_odcctools_patches "$PATCHFILES"
}
patch_apply_odcctools_patches_time_fixes() {
    patch_apply_odcctools_patches "$PATCHFILES_TIME"
}
patch_apply_odcctools_patches_qsort_r() {
    patch_apply_odcctools_patches "$PATCHFILES_QSORT_R"
}
patch_apply_odcctools_patches_add_compileguards() {
    patch_apply_odcctools_patches "$PATCHFILES_ADD_COMPILEGUARDS"
}
patch_apply_odcctools_patches_CROSS_SYSROOT() {
    patch_apply_odcctools_patches "$PATCHFILES_CROSS_SYSROOT"
}
patch_apply_odcctools_patches_default_arch() {
    patch_apply_odcctools_patches "$PATCHFILES_DEFAULT_ARCH"
}
patch_apply_odcctools_patches_add_typename_ld64() {
    patch_apply_odcctools_patches "$PATCHFILES_ADD_TYPENAME_LD64"
}
patch_apply_odcctools_patches_remove_inc_arch_sparc_reg_h_PC_define() {
    do_sed $"s^#define\tPC\t(1)^/*#define\tPC\t(1) .. defining PC breaks llvm-3.4 */^" ${DISTDIR}/include/architecture/sparc/reg.h
}
patch_qd_to_lld() {
    # MinGW falls over because mingw_pformat.c doesn't handle qd, so instead, change it lld.
    do_sed $"s^10qd^10lld^"  ${DISTDIR}/ar/archive.h
    do_sed $"s^8qd^8lld^"    ${DISTDIR}/ar/contents.c
    do_sed $"s^qd^lld^"      ${DISTDIR}/as/messages.c
}
patch_apply_odcctools_patches_remove_sysctl_osversion_detection() {
    patch_apply_odcctools_patches "$PATCHFILES_MACOSX_DEPLOYMENT_TARGET"
    # libstuff
    # disable_sysctl_osversion_detection.patch
    do_sed $"s^if(sysctl(osversion_name, 2, osversion, &osversion_len, NULL, 0) == -1)^strcpy(osversion,\"12.0\");^" ${DISTDIR}/libstuff/macosx_deployment_target.c
    do_sed $"s^system_error(\"sysctl for kern.osversion failed\");^^" ${DISTDIR}/libstuff/macosx_deployment_target.c
}
patch_apply_odcctools_patches_map_64bit_arches() {
    patch_apply_odcctools_patches "$PATCHFILES_MAP_64BIT_ARCHES"
}
patch_apply_odcctools_patches_printf_format_bugs() {
    patch_apply_odcctools_patches "$PATCHFILES_PRINTF_FORMAT_BUG"
    patch_qd_to_lld
}
patch_apply_odcctools_patches_dont_typedef_NxConstantString() {
    patch_apply_odcctools_patches "$PATCHFILES_DONT_TYPEDEF_NXCONSTANTSTRING"
}
patch_apply_odcctools_patches_cross_prefixes_EXEEXT() {
    patch_apply_odcctools_patches "$PATCHFILES_CROSS_PREFIXES"
    do_sed $"s^    const char \*AS = \"/as\";^    const char \*AS = \"/as\" EXEEXT;\n^" ${DISTDIR}/as/driver.c
}
patch_apply_odcctools_patches_progname_fixes() {
    patch_apply_odcctools_patches "$PATCHFILES_PROGNAME_FIXES"
}
patch_apply_odcctools_patches_use_strerror() {
    patch_apply_odcctools_patches "$PATCHFILES_STRERROR"
}
patch_apply_odcctools_patches_dont_assume_getattrlist() {
    patch_apply_odcctools_patches "$PATCHFILES_DONT_ASSUME_GETATTRLIST"
}
patch_apply_odcctools_patches_win_TMPDIR_to_TEMP() {
    patch_apply_odcctools_patches "$PATCHFILES_WIN_TMPDIR"
}
patch_apply_odcctools_patches_win_execute() {
    patch_apply_odcctools_patches "$PATCHFILES_WIN_EXECUTE"
}
patch_apply_odcctools_patches_win_avoid_mmap_ofile() {
    patch_apply_odcctools_patches "$PATCHFILES_WIN_AVOID_MMAP_OFILE"
}
patch_apply_odcctools_patches_win_64bit_fix() {
    do_sed $"s^#if __LP64__^#if __LP64__ || defined(__x86_64__)^" ${DISTDIR}/ld64/src/ld/parsers/libunwind/AddressSpace.hpp
}

patch_to_from patch_apply_odcctools_patches_time_fixes                            fix_time_bugs.patch                     $DISTDIR
patch_to_from patch_apply_odcctools_patches_add_compileguards                     add_compileguards.patch                 $DISTDIR
patch_to_from patch_apply_odcctools_patches_remove_sysctl_osversion_detection     remove_sysctl_osversion_detection.patch $DISTDIR
patch_to_from patch_apply_odcctools_patches_qsort_r                               allow_glibc_or_bsd_qsort_r.patch        $DISTDIR
patch_to_from patch_apply_odcctools_patches_map_64bit_arches                      map_64bit_arches.patch                  $DISTDIR
patch_to_from patch_apply_odcctools_patches_printf_format_bugs                    fix_printf_format_bugs.patch            $DISTDIR
patch_to_from patch_apply_odcctools_patches_CROSS_SYSROOT                         add_CROSS_SYSROOT.patch                 $DISTDIR
patch_to_from patch_apply_odcctools_patches_default_arch                          default_arch.patch                      $DISTDIR
patch_to_from patch_apply_odcctools_patches_add_typename_ld64                     add_typename_ld64.patch                 $DISTDIR
patch_to_from patch_apply_odcctools_patches_dont_typedef_NxConstantString         dont_typedef_NxConstantString.patch     $DISTDIR
patch_to_from patch_apply_odcctools_patches_cross_prefixes_EXEEXT                 cross_prefixes_and_EXEEXT.patch         $DISTDIR
patch_to_from patch_apply_odcctools_patches_progname_fixes                        progname_fixes.patch                    $DISTDIR
patch_to_from patch_apply_odcctools_patches_use_strerror                          use_strerror.patch                      $DISTDIR
patch_to_from patch_apply_odcctools_patches_dont_assume_getattrlist               dont_assume_getattrlist.patch           $DISTDIR

patch_autoconfiscate() {

    message_status "Adding new files to $DISTDIR"

    tar cf - --exclude=CVS --exclude=.svn -C ${ADDEDFILESDIR} . | tar xvf - -C ${DISTDIR}
    mv ${DISTDIR}/ld64/Makefile.in.${LD64VERS} ${DISTDIR}/ld64/Makefile.in
    if [[ "${LD64VERS}" == "127.2" ]] ; then
        echo -e "\n" > ${DISTDIR}/ld64/src/ld/configure.h
    fi

    if [[ -z $FOREIGNHEADERS ]] ; then
        message_status "Removing include/foreign"
        if [[ -d ${DISTDIR}/include/foreign ]] ; then
            rm -rf ${DISTDIR}/include/foreign
        fi
    else
        message_status "Removing include/mach/ppc (so include/foreign/mach/ppc is used)"
        if [[ -f ${DISTDIR}/include/foreign ]] ; then
            rm -rf ${DISTDIR}/include/mach/ppc
        fi
    fi
    pushd $DISTDIR
    $AUTOHEADER
    rm -rf autom4te.cache
    rm include/config.h.in~
    popd
}

patch_ppc64_reenable() {
    # ppc64 is disabled on non-darwin native builds, so let's re-enable it -> shouldn't break darwin native.
    # enable_ppc64_when_cross_compiling.patch
    do_sed $"s^#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)^//#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)^" ${DISTDIR}/include/mach/ppc/thread_status.h
    do_sed $"s%#endif /\* (_POSIX_C_SOURCE && !_DARWIN_C_SOURCE)%//#endif /\* _POSIX_C_SOURCE && !_DARWIN_C_SOURCE%" ${DISTDIR}/include/mach/ppc/thread_status.h
    do_sed $"s^#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)^//#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)^" ${DISTDIR}/include/mach/ppc/_structs.h
    do_sed $"s%#endif /\* (_POSIX_C_SOURCE && !_DARWIN_C_SOURCE)%//#endif /\* _POSIX_C_SOURCE && !_DARWIN_C_SOURCE%" ${DISTDIR}/include/mach/ppc/_structs.h
}

patch_to_from patch_ppc64_reenable ppc64_reenable.patch $DISTDIR

patch_dont_assume_vm_sync() {
    do_sed $"s^#ifdef VM_SYNC_DEACTIVATE^#if defined(VM_SYNC_DEACTIVATE) \&\& (HAVE_DECL_VM_MSYNC)^"  ${DISTDIR}/ld/pass1.c
    do_sed $"s^#ifdef VM_SYNC_DEACTIVATE^#if defined(VM_SYNC_DEACTIVATE) \&\& (HAVE_DECL_VM_MSYNC)^"  ${DISTDIR}/ld/pass2.c
    do_sed $"s^#ifdef VM_SYNC_DEACTIVATE^#if defined(VM_SYNC_DEACTIVATE) \&\& (HAVE_DECL_VM_MSYNC)^"  ${DISTDIR}/misc/libtool.c
}

patch_to_from patch_dont_assume_vm_sync dont_assume_vm_sync.patch $DISTDIR

patch_missing_includes() {
    # as_misc_fixes.patch
    do_sed $"s^#include <sys/stat.h>^#include <sys/stat.h>\n#include <unistd.h>^" ${DISTDIR}/ar/archive.c
    do_sed $"s^#include <stdlib.h>^#include <stdlib.h>\n#include <stdint.h>\n^" ${DISTDIR}/as/obstack.c
    do_sed $"s^#include <unistd.h>^#include <unistd.h>\n#include <stdint.h>\n^" ${DISTDIR}/ar/contents.c
    do_sed $"s^#include <strings.h>^#include <strings.h>\n#include <string.h>\n^" ${DISTDIR}/as/sections.c
    do_sed $"s^#include <unistd.h>^#include <unistd.h>\n#ifndef __APPLE__\n#include <uuid/uuid.h>\n#endif^" ${DISTDIR}/ld64/include/mach-o/dyld_images.h
}

patch_to_from patch_missing_includes missing_includes.patch $DISTDIR

patch_error_as_weak_symbol() {
    do_sed $":a;N;\$!ba;s^__private_extern__\nvoid\nerror^__private_extern__\n#ifndef __MINGW32__\n__attribute__\(\(weak\)\)\n#endif\nvoid\nerror^" ${DISTDIR}/libstuff/errors.c
}

patch_to_from patch_error_as_weak_symbol error_as_weak_symbol.patch $DISTDIR

patch_undef___unused_for_sysctl() {
    do_sed $"s^#include <sys/sysctl.h>^#if defined(__unused) \&\& defined(__linux__)\n#undef __unused\n#endif\n#include <sys/sysctl.h>^" ${DISTDIR}/libstuff/macosx_deployment_target.c
}

patch_to_from patch_undef___unused_for_sysctl undef___unused_for_sysctl.patch $DISTDIR

patch_fix_realpath_result_check() {
    do_sed $"s^\tif(realpath == NULL)^if(prefix == NULL)^" ${DISTDIR}/as/driver.c
}

patch_to_from patch_fix_realpath_result_check fix_realpath_result_check.patch $DISTDIR

patch_extern_C_log2_only_if___APPLE__() {
    do_sed $"s^extern \"C\" double log2 ( double );^#ifdef __APPLE__\nextern \"C\" double log2 ( double );\n#endif\n#include <libc.h>^" ${DISTDIR}/ld64/src/ld/ld.cpp
}

patch_to_from patch_extern_C_log2_only_if___APPLE__ extern_C_log2_only_if___APPLE__.patch $DISTDIR

patch_extern_C___assert_rtn() {
    do_sed $"s^void __assert_rtn(const char\* func, const char\* file, int line, const char\* failedexpr)^extern \"C\" void __assert_rtn(const char\* func, const char\* file, int line, const char\* failedexpr);\nvoid __assert_rtn(const char\* func, const char\* file, int line, const char\* failedexpr)^" ${DISTDIR}/ld64/src/ld/ld.cpp
}

patch_to_from patch_extern_C___assert_rtn extern_C___assert_rtn.patch $DISTDIR

patch_O_BINARY() {
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
}

patch_to_from patch_O_BINARY win_O_BINARY.patch $DISTDIR

patch_fileio_mode() {
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
}

patch_to_from patch_fileio_mode win_fileio_mode.patch $DISTDIR

patch_configure_regen() {
    pushd ${DISTDIR} > /dev/null
    message_status $PWD
    if [ ! $($AUTORECONF -vi) ] ; then
        $AUTORECONF -vi
    fi
    popd > /dev/null
}

patch_to_from patch_apply_odcctools_patches_win_TMPDIR_to_TEMP                    win_TMPDIR_to_TEMP.patch                $DISTDIR
patch_to_from patch_apply_odcctools_patches_win_execute                           win_execute.patch                       $DISTDIR
patch_to_from patch_apply_odcctools_patches_win_avoid_mmap_ofile                  win_avoid_mmap_ofile.patch              $DISTDIR
patch_to_from patch_apply_odcctools_patches_win_64bit_fix                         win_64bit_fix.patch                     $DISTDIR

patch_to_from patch_apply_odcctools_patches_remove_inc_arch_sparc_reg_h_PC_define remove_inc_arch_sparc_reg_h_PC.patch    $DISTDIR

patch_to_from patch_autoconfiscate autoconfiscate.patch $DISTDIR

patch_to_from patch_configure_regen configure_regen.patch $DISTDIR

if [ $MAKEDISTFILE -eq 1 ]; then
    DATE=$(date +%Y%m%d)
    mv ${DISTDIR} ${DISTDIR}-$DATE
    message_status "Making DISTFILE $PWD/${DISTDIR}-${DATE}.tar.bz2"
    tar jcf ${DISTDIR}-$DATE.tar.bz2 ${DISTDIR}-$DATE
fi
