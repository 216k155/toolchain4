AC_INIT([ccctools], [809], [Ray Donnelly <mingw.android@gmail.com>])
AC_PREREQ([2.68])
AC_REVISION([m4_esyscmd_s([git describe --always])])

# Weird. Doesn't seem to do anything...
AC_CONFIG_MACRO_DIR([m4])

# ...as I still need these:
m4_include([m4/ax_append_flag.m4])
m4_include([m4/ax_check_compile_flag.m4])
m4_include([m4/ax_append_compile_flags.m4])

AC_CONFIG_SRCDIR([APPLE_LICENSE])

# Causes multiply defined warning unfortunately.
AC_GNU_SOURCE

AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_CC
AC_PROG_CXX

AC_PROG_CC_C99

AC_CANONICAL_BUILD
AC_CANONICAL_HOST
AC_CANONICAL_TARGET

AX_APPEND_COMPILE_FLAGS([-D__DARWIN_UNIX03],CFLAGS)
AX_APPEND_COMPILE_FLAGS([-D__DARWIN_UNIX03],CXXFLAGS)

# Handle host dependant matters.
# 1. Append to CFLAGS early so that configure checks use them.
# 2. __attribute__((visibility("hidden"))) doesn't work on MinGW.
case $host_os in
    mingw*)
      AX_APPEND_COMPILE_FLAGS([-D__USE_MINGW_ANSI_STDIO=1 -D_POSIX -D_POSIX_C_SOURCE],CFLAGS)
      PRIVEXT=
      PRIVEXT_DESC="private extern as nothing"
      ;;
    *)
      PRIVEXT="__attribute__((visibility(\"hidden\")))"
      PRIVEXT_DESC="private extern as hidden visibility"
      ;;
esac

AC_CONFIG_HEADERS([include/config.h])

# To minimise impact on the source code, we provide our own versions of
# missing system headers. This is almost entirely a check for Darwin,
# but it may also apply to *BSD.
AC_CHECK_HEADERS([libc.h])
AM_CONDITIONAL([HAVE_LIBC_H], [test "x$ac_cv_header_libc_h" = xyes])
AM_COND_IF([HAVE_LIBC_H],
 [AC_SUBST([HAVE_LIBC_CXX_H], [NO])],
 [AC_CONFIG_HEADERS([include/libc.h include/libc_cxx.h])
  AC_SUBST([HAVE_LIBC_CXX_H], [YES])]
  )

# Need this to happen even on Linux which has it's own dlfcn.h
AC_CHECK_HEADERS([dlfcn.h])
AM_CONDITIONAL([HAVE_DLFCN_H], [test "x$ac_cv_header_dlfcn_h" = xyes])
AM_COND_IF([HAVE_DLFCN_H], [],
 AC_CONFIG_HEADERS([include/dlfcn.h]))

AC_CHECK_HEADERS([err.h])
AM_CONDITIONAL([HAVE_ERR_H], [test "x$ac_cv_header_err_h" = xyes])
AM_COND_IF([HAVE_ERR_H], [],
 AC_CONFIG_HEADERS([include/err.h]))

AC_CHECK_HEADERS([execinfo.h])
AM_CONDITIONAL([HAVE_EXECINFO_H], [test "x$ac_cv_header_execinfo_h" = xyes])
AM_COND_IF([HAVE_EXECINFO_H], [],
 AC_CONFIG_HEADERS([include/execinfo.h]))

AC_CHECK_HEADERS([sys/cdefs.h])
AM_CONDITIONAL([HAVE_SYS_CDEFS_H], [test "x$ac_cv_header_sys_cdefs_h" = xyes])
AM_COND_IF([HAVE_SYS_CDEFS_H], [],
 AC_CONFIG_HEADERS([include/sys/cdefs.h]))

AC_CHECK_HEADERS([sys/_endian.h])
AM_CONDITIONAL([HAVE_SYS__ENDIAN_H], [test "x$ac_cv_header_sys__endian_h" = xyes])
AM_COND_IF([HAVE_SYS__ENDIAN_H], [],
 AC_CONFIG_HEADERS([include/sys/_endian.h]))

AC_CHECK_HEADERS([sys/mman.h])
AM_CONDITIONAL([HAVE_SYS_MMAN_H], [test "x$ac_cv_header_sys_mman_h" = xyes])
AM_COND_IF([HAVE_SYS_MMAN_H], [],
 AC_CONFIG_HEADERS([include/sys/mman.h]))

AC_CHECK_HEADERS([sys/sysctl.h])
AM_CONDITIONAL([HAVE_SYS_SYSCTL_H], [test "x$ac_cv_header_sys_sysctl_h" = xyes])
AM_COND_IF([HAVE_SYS_SYSCTL_H], [],
 AC_CONFIG_HEADERS([include/sys/sysctl.h]))

AC_CHECK_HEADERS([CommonCrypto/CommonDigest.h])
AM_CONDITIONAL([HAVE_COMMONCRYPTO_COMMONDIGEST_H], [test "x$ac_cv_header_commoncrypto_commondigest_h" = xyes])
AM_COND_IF([HAVE_COMMONCRYPTO_COMMONDIGEST_H], [],
 AC_CONFIG_HEADERS([include/CommonCrypto/CommonDigest.h]))

AC_CHECK_HEADERS([paths.h])
AM_CONDITIONAL([HAVE_PATHS_H], [test "x$ac_cv_header_paths_h" = xyes])
AM_COND_IF([HAVE_PATHS_H], [],
 AC_CONFIG_HEADERS([include/paths.h]))

# For Windows:
AC_TYPE_UID_T
AC_CHECK_TYPE([caddr_t], [],
            [AC_DEFINE([caddr_t], [char *],
               [Define to `char *'
                if not defined.])])

AC_CHECK_TYPE([sigset_t], [],
            [AC_DEFINE([sigset_t], [int32_t],
               [Define to `int32_t'
                if not defined.])])

AC_CHECK_TYPE([u_int32_t], [],
            [AC_DEFINE([u_int32_t], [uint32_t],
               [Define to `uint32_t'])],
            [#include <sys/types.h>])

AC_CHECK_TYPE([u_char], [],
            [AC_DEFINE([u_char], [uint8_t],
               [Define to `uint32_t'])],
            [#include <sys/types.h>])

AC_CHECK_TYPE([u_short], [],
            [AC_DEFINE([u_short], [unsigned short],
               [Define to `unsigned short'])],
            [#include <sys/types.h>])

AC_CHECK_TYPE([u_int], [],
            [AC_DEFINE([u_int], [unsigned int],
               [Define to `unsigned int'])],
            [#include <sys/types.h>])

AC_CHECK_DECL([MIN], [],
            [AC_DEFINE([MIN(_a,_b)], [(((_a)<(_b))?(_a):(_b))],
               [Define MIN(_a,_b) to `(((_a)<(_b))?(_a):(_b))'])],
            [#include <sys/param.h>])

# MinGW-w64 has sleep() but mingw doesn't.
AC_CHECK_FUNC([sleep], [],
            [AC_DEFINE([sleep], [_sleep], [_sleep will suffice])])

# MinGW-w64 has SIGHUP and SIGPIPE so long as _POSIX is defined,
# otherwise define them to the values 1 and 13 respectively.
AC_CHECK_DECL([SIGHUP], [],
            [AC_DEFINE([SIGHUP], [1],
               [SIGHUP])],
            [#include <signal.h>])

AC_CHECK_DECL([SIGPIPE], [],
            [AC_DEFINE([SIGPIPE], [13],
               [SIGPIPE])],
            [#include <signal.h>])

# Linux's dlfcn.h has the exact same structure layout for
# Dl_info as Mac OS X, it's just missing the dl_info alias.
AC_CHECK_TYPE([dl_info], [],
            [AC_DEFINE([dl_info], [Dl_info],
               [Define to `Dl_info'])],
            [#include <dlfcn.h>])

# For everything but Windows:
AC_CHECK_DECL([O_BINARY], [],
            [AC_DEFINE([O_BINARY], [0],
               [Windows-specific open() flag
                to disable text mode])],
            [[#include <io.h>
              #include <fcntl.h>]])

# For everything but Darwin/BSD:
AC_CHECK_FUNC([bcmp], [],
            [AC_DEFINE([bcmp], [memcmp], [memcmp will suffice])])

AC_CHECK_FUNC([bcopy], [],
            [AC_DEFINE([bcopy(_s,_d,_n)], [memmove(_d,_s,_n)], [memmove will suffice])])

AC_CHECK_FUNC([bzero], [],
            [AC_DEFINE([bzero(_p,_n)], [memset(_p,0,_n)], [memset will suffice])])

AC_CHECK_FUNC([setbuffer], [],
            [AC_DEFINE([setbuffer(_f,_b,_n)], [do {} while(0)], [not needed])])

AC_CHECK_FUNC([getwd], [],
            [AC_DEFINE([getwd(_p)], [getcwd(_p,MAXPATHLEN-1)], [getcwd will suffice])])

AC_CHECK_FUNC([ffs], [],
            [AC_DEFINE([ffs(_x)], [__builtin_ffs(_x)], [__builtin_ffs will suffice])])

AC_CHECK_FUNC([getc_unlocked], [],
            [AC_DEFINE([getc_unlocked(_f)], [getc(_f)], [getc will suffice])])

#AC_CHECK_DECL([AR_EFMT1], [],
#            [AC_DEFINE([AR_EFMT1], ["#1"],
#               [AR_EFMT1])],
#            [#include <ar.h>])

AC_CHECK_DECL([ULLONG_MAX], [],
            [AC_DEFINE([ULLONG_MAX], [0xffffffffffffffffULL],
               [ULLONG_MAX])],
            [#include <limits.h>])

CHECK_ENUM(CTL_KERN, [sys/sysctl.h],
            [], [AC_DEFINE([CTL_KERN], [1],
               [CTL_KERN])])

CHECK_ENUM(KERN_OSRELEASE, [sys/sysctl.h],
            [], [AC_DEFINE([KERN_OSRELEASE], [2],
               [KERN_OSRELEASE])])

# This must be checked for after CTL_KERN amd KERN_OSRELEASE because
# on Linux, sysctl.h contains "unsigned long __unused[4];"
AC_CHECK_DECL([__unused], [],
            [AC_DEFINE([__unused], [__attribute__((__unused__))],
               [__unused macro to save some typing])],
            [#include <sys/cdefs.h>])

AC_CHECK_DECL([FP_PREC_24B], [],
            [AC_DEFINE([FP_PREC_24B], [0],
               [FP_PREC_24B])],
            [#include <_structs.h>])

AC_CHECK_DECL([FP_PREC_53B], [],
            [AC_DEFINE([FP_PREC_53B], [2],
               [FP_PREC_53B])],
            [#include <_structs.h>])

AC_CHECK_DECL([FP_PREC_64B], [],
            [AC_DEFINE([FP_PREC_64B], [3],
               [FP_PREC_64B])],
            [#include <_structs.h>])

AC_CHECK_DECL([FP_RND_NEAR], [],
            [AC_DEFINE([FP_RND_NEAR], [0],
               [FP_RND_NEAR])],
            [#include <_structs.h>])

AC_CHECK_DECL([FP_RND_DOWN], [],
            [AC_DEFINE([FP_RND_DOWN], [1],
               [FP_RND_DOWN])],
            [#include <_structs.h>])

AC_CHECK_DECL([FP_RND_UP], [],
            [AC_DEFINE([FP_RND_UP], [2],
               [FP_RND_UP])],
            [#include <_structs.h>])

AC_CHECK_DECL([FP_CHOP], [],
            [AC_DEFINE([FP_CHOP], [3],
               [FP_CHOP])],
            [#include <_structs.h>])

AC_CHECK_DECL([S_IFSOCK], [],
            [AC_DEFINE([S_IFSOCK], [0140000], [0140000])])

AC_CHECK_DECL([S_ISUID], [],
            [AC_DEFINE([S_ISUID], [0004000], [0004000])])

AC_CHECK_DECL([S_IFLNK], [],
            [AC_DEFINE([S_IFLNK], [0120000], [0120000])])

AC_CHECK_DECL([S_IRGRP], [],
            [AC_DEFINE([S_IRGRP], [00040], [00040])])

AC_CHECK_DECL([S_IWGRP], [],
            [AC_DEFINE([S_IWGRP], [00020], [00020])])

AC_CHECK_DECL([S_IXGRP], [],
            [AC_DEFINE([S_IXGRP], [00010], [00010])])

AC_CHECK_DECL([S_ISGID], [],
            [AC_DEFINE([S_ISGID], [0002000], [0002000])])

AC_CHECK_DECL([S_ISGID], [],
            [AC_DEFINE([S_ISGID], [0002000], [0002000])])

AC_CHECK_DECL([S_IROTH], [],
            [AC_DEFINE([S_IROTH], [00004], [00004])])

AC_CHECK_DECL([S_IWOTH], [],
            [AC_DEFINE([S_IWOTH], [00002], [00002])])

AC_CHECK_DECL([S_IXOTH], [],
            [AC_DEFINE([S_IXOTH], [00001], [00001])])

AC_CHECK_DECL([S_ISVTX], [],
            [AC_DEFINE([S_ISVTX], [0001000], [0001000])])

AC_ARG_PROGRAM

case $target_os in
darwin*)
    :
    ;;
*)
    AC_MSG_ERROR([$PACKAGE_NAME only supports targeting Darwin])
    ;;
esac

case $target_cpu in
     powerpc)
        AC_DEFINE(EMULATED_HOST_CPU_TYPE, 18, [Emulated CPU type])
        AC_DEFINE(EMULATED_HOST_CPU_SUBTYPE, 100, [Emulated CPU subtype])
    ;;
     powerpc64)
        AC_DEFINE(EMULATED_HOST_CPU_TYPE, 16777234, [Emulated CPU type])
        AC_DEFINE(EMULATED_HOST_CPU_SUBTYPE, 0, [Emulated CPU subtype])
       ;;
     i?86)
        AC_DEFINE(EMULATED_HOST_CPU_TYPE, 7, [Emulated CPU type])
        AC_DEFINE(EMULATED_HOST_CPU_SUBTYPE, 10, [Emulated CPU subtype])
    ;;
     x86_64)
        AC_DEFINE(EMULATED_HOST_CPU_TYPE, 16777223, [Emulated CPU type])
        AC_DEFINE(EMULATED_HOST_CPU_SUBTYPE, 3, [Emulated CPU subtype])
    ;;
     arm)
        AC_DEFINE(EMULATED_HOST_CPU_TYPE, 12, [Emulated CPU type])
        AC_DEFINE(EMULATED_HOST_CPU_SUBTYPE, 0, [Emulated CPU subtype])
    ;;
     *)
    AC_MSG_ERROR([Unsupported target $target_cpu])
    ;;
esac

AC_CHECK_TOOL([HOST_RANLIB], [ranlib], :)
AC_CHECK_TOOL([HOST_AR], [ar], :)

ASTARGETS=""
conftargets=""
AC_MSG_CHECKING([for configured assembler targets])
AC_ARG_ENABLE([as-targets],
        AC_HELP_STRING([--enable-as-targets],
                [space-separated list ("ppc", "ppc64", "i386", "x86_64", "arm", "all")]),
        [conftargets="$enableval"],
        [conftargets="default"])

case "$conftargets" in
    all)
        ASTARGETS="ppc ppc64 i386 x86_64 arm"
    ;;
    default)
        ASTARGETS="ppc ppc64 i386 x86_64 arm"
    ;;
    yes)
        AC_MSG_ERROR([no assembler targets configured])
    ;;
    no)
        AC_MSG_ERROR([no assembler targets configured])
    ;;
    *)
        if [[ -z "$conftargets" ]]; then
            AC_MSG_ERROR([no assembler targets configured])
        fi
        ASTARGETS="$conftargets"
    ;;
esac

AC_MSG_RESULT([$ASTARGETS])
AC_SUBST([ASTARGETS], [$ASTARGETS])

# On openSUSE, libexec ends up as lib instead. In:
# /usr/share/site/x86_64-unknown-linux-gnu
# there's:
# "If user did not specify libexecdir, guess the correct target:
# Nor FHS nor openSUSE allow prefix/libexec. Let's default to prefix/lib."
# libexecdir='${exec_prefix}/lib'
# ..however, even when I did specify it to configure, it didn't work.
# Fact is, we always want ${prefix}/libexec for Darwin cross compilers.
# AC_SUBST([ASLIBEXECDIR], ['${libexecdir}/as'])

AC_SUBST([ASLIBEXECDIR], ['${prefix}/libexec/as'])

AC_ARG_WITH([sysroot],
        AC_HELP_STRING([--with-sysroot],
                [filesystem root of cross build environment]),
        [AC_DEFINE_UNQUOTED([CROSS_SYSROOT],["$withval"],[filesystem root of cross build environment])])


# Not sure why MDYNAMICNOPIC is used instead of just WARNINGS
MDYNAMICNOPIC=""
AX_APPEND_COMPILE_FLAGS([-mdynamic-no-pic], [MDYNAMICNOPIC])
AC_SUBST([MDYNAMICNOPIC])

AX_APPEND_COMPILE_FLAGS([-fno-builtin-round -fno-builtin-trunc],[CFLAGS])

ORIGCFLAGS=$CFLAGS
CFLAGS="$CFLAGS -no-cpp-precomp"
supported=0
AC_MSG_CHECKING([if -no-cpp-precomp is supported])
AC_LANG_CONFTEST(
    [AC_LANG_SOURCE([const char hw[] = "Hello, World\n";])])
rm -f conftest.$ac_objext conftest$ac_exeext
out=`$CC -c $CFLAGS $CPPFLAGS conftest.$ac_ext 2>&1`
if [[ $? -ne 0 ]]; then
   supported=0;
else
   unrecog=`echo $out | grep unrecog | wc -l`
   if [[ $unrecog -gt 0 ]]; then
      supported=0;
   else
      supported=1;
   fi
fi
if [[ $supported -eq 1 ]]; then
   AC_MSG_RESULT([yes])
else
   CFLAGS="$ORIGCFLAGS"
   AC_MSG_RESULT([no])
fi
rm -f conftest.$ac_objext conftest$ac_exeext conftest.$ac_ext

#ORIGCFLAGS=$CFLAGS
#CFLAGS="$CFLAGS -mdynamic-no-pic"
#AC_MSG_CHECKING([if -mdynamic-no-pic is supported])
#AC_COMPILE_IFELSE(
#   [AC_LANG_SOURCE([[const char hw[] = "Hello, World\n";]])],
#   [AC_SUBST([MDYNAMICNOPIC],[-mdynamic-no-pic])
#    AC_MSG_RESULT([yes])],
#   [AC_SUBST([MDYNAMICNOPIC],[])
#    AC_MSG_RESULT([no])]
#)
#CFLAGS=$ORIGCFLAGS

#ORIGCFLAGS=$CFLAGS
#CFLAGS="$CFLAGS -fno-builtin-round"
#AC_MSG_CHECKING([if -fno-builtin-round is supported])
#AC_COMPILE_IFELSE(
#   [AC_LANG_SOURCE([[const char hw[] = "Hello, World\n";]])],
#   [AC_MSG_RESULT([yes])],
#   [CFLAGS=$ORIGCFLAGS
#    AC_MSG_RESULT([no])]
#)

#ORIGCFLAGS=$CFLAGS
#CFLAGS="$CFLAGS -fno-builtin-trunc"
#AC_MSG_CHECKING([if -fno-builtin-trunc is supported])
#AC_COMPILE_IFELSE(
#   [AC_LANG_SOURCE([[const char hw[] = "Hello, World\n";]])],
#   [AC_MSG_RESULT([yes])],
#   [CFLAGS=$ORIGCFLAGS
#    AC_MSG_RESULT([no])]
#)

# There's a bug in Google's 4.4.3 GCC where it never reports -Wno-* as missing, unless there are other warnings present as well.
# i.e. the following command returns an exit code of 0 and reports no error:
#  /home/nonesuch/i686-linux-glibc2.7-4.4.3/bin/i686-linux-gcc -Wall -Wno-way-this-warning-exists conftest.c
# whereas this command fails, reporting an error:
#  /home/nonesuch/i686-linux-glibc2.7-4.4.3/bin/i686-linux-gcc -Wall -Wthis-warning-doesnt-exist conftest.c
# for this reason, form INVERSE_WARNINGS (containing -Wimport instead of -Wno-import) then transform them afterwards.
# A cleaner approach might be to create and use AX_ENABLE_WARNING and AX_DISABLE_WARNING where e.g. 'import', 'unused-variable' etc are the names specified.
# -Wattributes (hence -Wno-attributes) used to be in this list, but I'd rather not disable warnings un-necessarily, in fact, enabling all
# warnings (or at least not disabling any) and compiling everything with -Werror should be an explicit goal.
AX_APPEND_COMPILE_FLAGS([-Wimport -Wunused-variable -Wunused-but-set-variable -Wdeprecated-declarations], [INVERSE_WARNINGS], [-Wall -Werror])
WARNINGS=""
for WARNING in $INVERSE_WARNINGS; do
    WARNINGS=$WARNINGS" ${WARNING//-W/-Wno-}"
done
AC_SUBST([WARNINGS], [$WARNINGS])

ORIGCFLAGS=$CFLAGS
CFLAGS="$CFLAGS -x objective-c"
OBJC="-x objective-c"
AC_MSG_CHECKING([if -x objective-c is supported])
AC_COMPILE_IFELSE(
   [AC_LANG_SOURCE([[@class foo;
void bar(void) {
     [foo alloc];
}
]])],
   [AC_DEFINE(HAVE_OBJC, 1, [Have Objective-C support])
    AC_MSG_RESULT([yes])],
   [OBJC=""
    AC_MSG_RESULT([no])]
)
AC_SUBST([OBJC], [$OBJC])
CFLAGS=$ORIGCFLAGS

AC_MSG_CHECKING([if __private_extern__ is supported])
AC_COMPILE_IFELSE(
   [AC_LANG_SOURCE([[__private_extern__ int foo;]])],
   [AC_MSG_RESULT([yes])],
   [AC_DEFINE_UNQUOTED([__private_extern__], [$PRIVEXT], [$PRIVEXT_DESC])
    AC_MSG_RESULT([no])]
)

ORIGLDFLAGS=$LDFLAGS
LDFLAGS="$LDFLAGS -multiply_defined suppress"
AC_MSG_CHECKING([if -multiply_defined suppress is supported])
AC_LINK_IFELSE([AC_LANG_PROGRAM()],
    [AC_MSG_RESULT([yes])],
    [LDFLAGS="$ORIGLDFLAGS"
     AC_MSG_RESULT([no])]
)

# Again, work around the -Wno-* bug.
AC_LANG_PUSH([C++])
AX_APPEND_COMPILE_FLAGS([-Wtrigraphs -Wdeprecated -Wstrict-aliasing -Wenum-compare -Winvalid-offsetof], [INVERSE_CXXWARNINGS], [-Wall -Werror])
CXXWARNINGS=""
for WARNING in $INVERSE_CXXWARNINGS; do
    CXXWARNINGS=$CXXWARNINGS" ${WARNING//-W/-Wno-}"
done
CXXFLAGS=$CXXFLAGS" $CXXWARNINGS"
AC_LANG_POP

AC_HEADER_STDC
AC_CHECK_HEADERS([stdio.h errno.h limits.h])
if [[ "x$OBJC" != "x" ]]; then
   ORIGCFLAGS=$CFLAGS
   CFLAGS="$CFLAGS $OBJC"
   AC_CHECK_HEADERS([objc/objc-runtime.h])
   CFLAGS="$ORIGCFLAGS"
fi

AC_MSG_CHECKING([for max unsigned long long])
AC_COMPILE_IFELSE(
   [AC_LANG_SOURCE([[#if HAVE_LIMITS_H
             #include <limits.h>
             #endif
             unsigned long long a = ULLONG_MAX;]])],
   [AC_MSG_RESULT([ULLONG_MAX])],
   [AC_COMPILE_IFELSE(
    [AC_LANG_SOURCE([[#if HAVE_LIMITS_H
                  #include <limits.h>
             #endif
             unsigned long long a = 18446744073709551615ULL;]])],
    [AC_DEFINE(ULLONG_MAX, [18446744073709551615ULL], [max unsigned long long])
     AC_MSG_RESULT([18446744073709551615ULL])],
    [AC_MSG_RESULT([none]) ]
    )
    ]
)

AC_CHECK_FUNCS([qsort_r qsort getattrlist NSIsSymbolNameDefined strlcpy strlcat _NSGetExecutablePath])
AC_CHECK_DECLS([vm_msync], [], [], [[#include <mach/vm_map.h>]])

# Not right for Darwin?
AC_CHECK_HEADERS([CommonCrypto/CommonDigest.h],[],[SSL_LIBS="-lssl -lcrypto"])
AC_SUBST(SSL_LIBS)

AC_CHECK_DECLS([backtrace], [], [], [[#include <execinfo.h>]])
AC_CHECK_DECLS([dlopen, dlsym, dlclose, dlerror, dladdr], [], [], [[#include <dlfcn.h>]])
AC_CHECK_DECLS([mmap], [], [], [[#include <sys/mman.h>]])
AC_CHECK_DECLS([flock], [], [], [[#include <sys/file.h>]])
AC_CHECK_DECLS([sigfillset, sigprocmask], [], [], [[#include <signal.h>]])
AC_CHECK_DECLS([utimes], [], [], [[#include <sys/time.h>]])
AC_CHECK_DECLS([asprintf], [], [], [[#include <stdio.h>]])
AC_CHECK_DECLS([strlcpy, strlcat, getuid, getgid, rindex, index, strmode, mkstemp, fchmod, fchdir, pwrite, realpath])
AC_CHECK_DECLS([readlink], [], [], [[#include <unistd.h>]])

case $host_os in
    mingw*)
        AC_DEFINE([FIO_READ_WRITE],[_S_IREAD|_S_IWRITE],[0666])
        AC_DEFINE([FIO_READ_WRITE_ME],[_S_IREAD|_S_IWRITE],[0600])
        AC_DEFINE([FIO_READ_WRITE_EXEC],[_S_IREAD|_S_IWRITE|_S_IEXEC],[0777])
        AC_DEFINE([FIO_MASK_ALL_4],[_S_IREAD|_S_IWRITE|_S_IEXEC],[07777])
        ;;
    *)
        AC_DEFINE([FIO_READ_WRITE],[0666],[_S_IREAD|_S_IWRITE])
        AC_DEFINE([FIO_READ_WRITE_ME],[0600],[_S_IREAD|_S_IWRITE])
        AC_DEFINE([FIO_READ_WRITE_EXEC],[0777],[_S_IREAD|_S_IWRITE|_S_IEXEC])
        AC_DEFINE([FIO_MASK_ALL_4],[07777],[_S_IREAD|_S_IWRITE|_S_IEXEC])
        ;;
esac

case $host_os in
     darwin*)
    AC_SUBST([HAVE_FOREIGN_HEADERS],[NO])
    ;;
     *)
    AC_SUBST([HAVE_FOREIGN_HEADERS],[YES])
    AC_SUBST([EMULATED_OBJ], [emulated.c])
    AC_C_BIGENDIAN([AC_SUBST([ENDIAN_FLAG],[-D__BIG_ENDIAN__=1])],
            [AC_SUBST([ENDIAN_FLAG],[-D__LITTLE_ENDIAN__=1])])
    ;;
esac

# There's no fts.h (included from dylib_roots.c) with MinGW. There is however,
# http://cygwin.com/cgi-bin/cvsweb.cgi/src/winsup/cygwin/libc/fts.c?cvsroot=src
# http://cygwin.com/cgi-bin/cvsweb.cgi/~checkout~/src/winsup/cygwin/libc/fts.c?rev=1.4&content-type=text/plain&cvsroot=src
# from cygwin which is under the BSD license, so I could maybe use that if seg_addr_table is needed.
case $host_os in
     mingw*)
       AC_DEFINE_UNQUOTED([EXEEXT],[".exe"], ["Define executable extension"])
     ;;
     *)
       AC_DEFINE_UNQUOTED([EXEEXT],[""], ["Define executable extension"])
       AC_SUBST([NOT_FOR_WINDOWS_C],["dylib_roots.c seg_addr_table.c dylib_table.c SymLoc.c"])
       AC_SUBST([NOT_FOR_WINDOWS_MISC_C],["checksyms.c redo_prebinding.c"])
       AC_SUBST([NOT_FOR_WINDOWS_PROG],["seg_addr_table checksyms redo_prebinding"])
     ;;
esac

AC_CHECK_SIZEOF([long])
if test $ac_cv_sizeof_long >=8; then
    LD_CLASSIC=
else
    LD_CLASSIC=ld
fi
COMPONENTS="libstuff ar as include libprunetrie libmacho ${LD_CLASSIC} misc otool man ld64"
AC_SUBST([COMPONENTS], [$COMPONENTS])

AC_CHECK_FUNC([uuid_generate_random],[],
          [AC_CHECK_LIB([uuid],[uuid_generate_random],
                [UUID_LIBS="-luuid"],
                [AC_MSG_ERROR(
                 [No uuid_generate_random function found])])])
AC_SUBST([UUID_LIBS])

AC_CHECK_FUNC([dlopen],[],
          [AC_CHECK_LIB([dl],[dlopen],
                [DL_LIBS="-ldl"],
                [AC_MSG_WARN(
                 [No dlopen function found in dl])])])
AC_SUBST([DL_LIBS])

case $host_os in
     darwin*)
# Dynamically linked LTO
AC_LANG_PUSH([C++])
AC_CHECK_LIB([LTO],[lto_get_version],[
         LTO_LIBS=-lLTO
         LTO_DEFS="-DLTO_SUPPORT=1"
         ])
AC_LANG_POP([C++])
AC_SUBST(LTO_LIBS)
AC_SUBST(LTO_DEFS)
;;
     mingw*)
# -lEnhancedDisassembly.dll needed, there is a .a but various syms are missing
# (_imp__SymSetOptions@4,_imp__SymInitialize@12,_imp__SymGetModuleBase@8,_imp__SymFunctionTableAccess@8,_imp__StackWalk@36,_imp__SymGetModuleBase@8,_imp__SymGetSymFromAddr@16,_imp__SymGetLineFromAddr@16,GetProcessMemoryInfo@12)
# even after there, there's
# (_imp__SymSetOptions@4,_imp__SymInitialize@12,_imp__SymGetModuleBase@8,_imp__SymFunctionTableAccess@8,_imp__StackWalk@36,_imp__SymGetModuleBase@8,_imp__SymGetSymFromAddr@16,_imp__SymGetLineFromAddr@16,GetProcessMemoryInfo@12)
LTO_LIBS="-Wl,-Bstatic -Wl,--start-group -lpthread -lssl -lcrypto -Wl,--end-group -Wl,-Bdynamic -llibLTO"
LTO_DEFS="-DLTO_SUPPORT=1"
AC_SUBST(LTO_LIBS)
AC_SUBST(LTO_DEFS)
;;
     *)
# Statically linked LTO (though static llvmgcc itself isn't yet done)
# ...requires a large list of libraries. Using gnumake's $(wildcard) might be a better plan.
AC_LANG_PUSH([C++])
AC_CHECK_LIB([LTO],[lto_get_version],[
         LTO_LIBS="-lpthread -Wl,-Bstatic -Wl,--start-group -lCompilerDriver -lEnhancedDisassembly -lLLVMAlphaAsmPrinter -lLLVMAlphaCodeGen -lLLVMAlphaInfo -lLLVMAnalysis -lLLVMArchive -lLLVMARMAsmParser -lLLVMARMAsmPrinter -lLLVMARMCodeGen -lLLVMARMInfo -lLLVMAsmParser -lLLVMAsmPrinter -lLLVMBitReader -lLLVMBitWriter -lLLVMBlackfinAsmPrinter -lLLVMBlackfinCodeGen -lLLVMBlackfinInfo -lLLVMCBackend -lLLVMCBackendInfo -lLLVMCellSPUAsmPrinter -lLLVMCellSPUCodeGen -lLLVMCellSPUInfo -lLLVMCodeGen -lLLVMCore -lLLVMCppBackend -lLLVMCppBackendInfo -lLLVMExecutionEngine -lLLVMInstCombine -lLLVMInstrumentation -lLLVMInterpreter -lLLVMipa -lLLVMipo -lLLVMJIT -lLLVMLinker -lLLVMMBlazeAsmPrinter -lLLVMMBlazeCodeGen -lLLVMMBlazeInfo -lLLVMMC -lLLVMMCParser -lLLVMMipsAsmPrinter -lLLVMMipsCodeGen -lLLVMMipsInfo -lLLVMMSIL -lLLVMMSILInfo -lLLVMMSP430AsmPrinter -lLLVMMSP430CodeGen -lLLVMMSP430Info -lLLVMPIC16AsmPrinter -lLLVMPIC16CodeGen -lLLVMPIC16Info -lLLVMpic16passes -lLLVMPowerPCAsmPrinter -lLLVMPowerPCCodeGen -lLLVMPowerPCInfo -lLLVMScalarOpts -lLLVMSelectionDAG -lLLVMSparcAsmPrinter -lLLVMSparcCodeGen -lLLVMSparcInfo -lLLVMSupport -lLLVMSystem -lLLVMSystemZAsmPrinter -lLLVMSystemZCodeGen -lLLVMSystemZInfo -lLLVMTarget -lLLVMTransformUtils -lLLVMX86AsmParser -lLLVMX86AsmPrinter -lLLVMX86CodeGen -lLLVMX86Disassembler -lLLVMX86Info -lLLVMXCoreAsmPrinter -lLLVMXCoreCodeGen -lLLVMXCoreInfo -lLTO -lplugin_llvmc_Base -lplugin_llvmc_Clang -lUnitTestMain -Wl,--end-group -Wl,-Bdynamic"
         LTO_DEFS="-DLTO_SUPPORT=1"
         ])
AC_LANG_POP([C++])
AC_SUBST(LTO_LIBS)
AC_SUBST(LTO_DEFS)
;;
esac

# So tagged (zzz_and_finally) to ensure that this gets sorted last in config.h
AH_VERBATIM([zzz_and_finally],[
#include "emulated.h"
])

AC_CONFIG_FILES([Makefile include/Makefile libprunetrie/Makefile libstuff/Makefile libmacho/Makefile])
AC_CONFIG_FILES([ar/Makefile])
AC_CONFIG_FILES([as/Makefile])
for ast in $ASTARGETS; do
    case $ast in
    ppc)
    AC_CONFIG_FILES([as/ppc/Makefile:as/ppc/Makefile.in:as/Makefile.arch.in])
    ;;
    ppc64)
    AC_CONFIG_FILES([as/ppc64/Makefile:as/ppc64/Makefile.in:as/Makefile.arch.in])
    ;;
    i386)
    AC_CONFIG_FILES([as/i386/Makefile:as/i386/Makefile.in:as/Makefile.arch.in])
    ;;
    x86_64)
    AC_CONFIG_FILES([as/x86_64/Makefile:as/x86_64/Makefile.in:as/Makefile.arch.in])
    ;;
    arm)
    AC_CONFIG_FILES([as/arm/Makefile:as/arm/Makefile.in:as/Makefile.arch.in])
    ;;
    *)
    AC_MSG_ERROR([Unrecognized assembler target $ast])
    ;;
    esac
done

AC_CONFIG_FILES([ld/Makefile])
AC_CONFIG_FILES([ld64/Makefile])
AC_CONFIG_FILES([man/Makefile])
AC_CONFIG_FILES([misc/Makefile])
AC_CONFIG_FILES([otool/Makefile])
AC_OUTPUT
