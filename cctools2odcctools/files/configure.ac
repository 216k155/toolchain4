AC_INIT([odcctools], [809.ma], [mingw.android@gmail.com])
AC_PREREQ([2.57])
AC_REVISION([m4_esyscmd_s([git describe --always])])

AC_CONFIG_SRCDIR([APPLE_LICENSE])

# Causes multiply defined warning unfortunately.
AC_DEFINE(_GNU_SOURCE, [], [To make the decl checks below work])

AC_CANONICAL_BUILD
AC_CANONICAL_HOST
AC_CANONICAL_TARGET

AC_CONFIG_HEADERS([include/config.h])

# To minimise impact on the source code, we provide our own versions of
# missing system headers.
AC_CHECK_HEADERS([libc.h])
AM_CONDITIONAL([HAVE_LIBC_H], [test "x$ac_cv_header_libc_h" = xyes])
AM_COND_IF([HAVE_LIBC_H], [],
 AC_CONFIG_HEADERS([include/libc.h]))

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

# For Windows:
AC_TYPE_UID_T
AC_CHECK_TYPE([caddr_t], [],
            [AC_DEFINE_UNQUOTED([caddr_t], [char *],
               [Define to `char *'
                if not defined.])])

AC_CHECK_TYPE([sigset_t], [],
            [AC_DEFINE_UNQUOTED([sigset_t], [int32_t],
               [Define to `int32_t'
                if not defined.])])

# For everything but Windows:
AC_CHECK_DECL([O_BINARY], [],
            [AC_DEFINE_UNQUOTED([O_BINARY], [0],
               [Windows-specific open() flag
                to disable text mode])],
            [[#include <io.h>
              #include <fcntl.h>]])

# For everything but Darwin:
AC_CHECK_DECL([__unused], [],
            [AC_DEFINE_UNQUOTED([__unused], [__attribute__((__unused__))],
               [__unused macro to save some typing])],
            [#include <sys/cdefs.h>])

AC_CHECK_DECL([AR_EFMT1], [],
            [AC_DEFINE_UNQUOTED([AR_EFMT1], ["#1"],
               [AR_EFMT1])],
            [#include <ar.h>])

AC_CHECK_DECL([ULLONG_MAX], [],
            [AC_DEFINE_UNQUOTED([ULLONG_MAX], [0xffffffffffffffffULL],
               [ULLONG_MAX])],
            [#include <i386/limits.h>])

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


AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_CC
AC_PROG_CXX

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

ORIGCFLAGS=$CFLAGS
CFLAGS="$CFLAGS -mdynamic-no-pic"
AC_MSG_CHECKING([if -mdynamic-no-pic is supported])
AC_COMPILE_IFELSE(
   [AC_LANG_SOURCE([[const char hw[] = "Hello, World\n";]])],
   [AC_SUBST([MDYNAMICNOPIC],[-mdynamic-no-pic])
    AC_MSG_RESULT([yes])],
   [AC_SUBST([MDYNAMICNOPIC],[])
    AC_MSG_RESULT([no])]
)
CFLAGS=$ORIGCFLAGS

ORIGCFLAGS=$CFLAGS
CFLAGS="$CFLAGS -fno-builtin-round"
AC_MSG_CHECKING([if -fno-builtin-round is supported])
AC_COMPILE_IFELSE(
   [AC_LANG_SOURCE([[const char hw[] = "Hello, World\n";]])],
   [AC_MSG_RESULT([yes])],
   [CFLAGS=$ORIGCFLAGS
    AC_MSG_RESULT([no])]
)

ORIGCFLAGS=$CFLAGS
CFLAGS="$CFLAGS -fno-builtin-trunc"
AC_MSG_CHECKING([if -fno-builtin-trunc is supported])
AC_COMPILE_IFELSE(
   [AC_LANG_SOURCE([[const char hw[] = "Hello, World\n";]])],
   [AC_MSG_RESULT([yes])],
   [CFLAGS=$ORIGCFLAGS
    AC_MSG_RESULT([no])]
)

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

WARNINGS=""

ORIGCFLAGS=$CFLAGS
CFLAGS="$CFLAGS -Werror -Wall"
AC_MSG_CHECKING([if -Wall is supported])
AC_COMPILE_IFELSE(
   [AC_LANG_SOURCE([[const char hw[] = "Hello, World\n";]])],
   [WARNINGS="$WARNINGS -Wall"
    AC_MSG_RESULT([yes])],
   [AC_MSG_RESULT([no])]
)
CFLAGS=$ORIGCFLAGS

ORIGCFLAGS=$CFLAGS
CFLAGS="$CFLAGS -Werror -Wno-import"
AC_MSG_CHECKING([if -Wno-import is supported])
AC_COMPILE_IFELSE(
   [AC_LANG_SOURCE([[const char hw[] = "Hello, World\n";]])],
   [WARNINGS="$WARNINGS -Wno-import"
    AC_MSG_RESULT([yes])],
   [AC_MSG_RESULT([no])]
)
CFLAGS=$ORIGCFLAGS

ORIGCFLAGS=$CFLAGS
CFLAGS="$CFLAGS -Werror -Wno-unused-variable"
AC_MSG_CHECKING([if -Wno-unused-variable is supported])
AC_COMPILE_IFELSE(
   [AC_LANG_SOURCE([[const char hw[] = "Hello, World\n";]])],
   [WARNINGS="$WARNINGS -Wno-unused-variable"
    AC_MSG_RESULT([yes])],
   [AC_MSG_RESULT([no])]
)
CFLAGS=$ORIGCFLAGS

ORIGCFLAGS=$CFLAGS
CFLAGS="$CFLAGS -Werror -Wno-unused-but-set-variable"
AC_MSG_CHECKING([if -Wno-unused-but-set-variable is supported])
AC_COMPILE_IFELSE(
   [AC_LANG_SOURCE([[const char hw[] = "Hello, World\n";]])],
   [WARNINGS="$WARNINGS -Wno-unused-but-set-variable"
    AC_MSG_RESULT([yes])],
   [AC_MSG_RESULT([no])]
)
CFLAGS=$ORIGCFLAGS

ORIGCFLAGS=$CFLAGS
CFLAGS="$CFLAGS -Werror -Wno-deprecated-declarations"
AC_MSG_CHECKING([if -Wno-deprecated-declarations is supported])
AC_COMPILE_IFELSE(
   [AC_LANG_SOURCE([[const char hw[] = "Hello, World\n";]])],
   [WARNINGS="$WARNINGS -Wno-deprecated-declarations"
    AC_MSG_RESULT([yes])],
   [AC_MSG_RESULT([no])]
)
CFLAGS=$ORIGCFLAGS

ORIGCFLAGS=$CFLAGS
CFLAGS="$CFLAGS -Werror -Wno-attributes"
AC_MSG_CHECKING([if -Wno-attributes is supported])
AC_COMPILE_IFELSE(
   [AC_LANG_SOURCE([[const char hw[] = "Hello, World\n";]])],
   [WARNINGS="$WARNINGS -Wno-attributes"
    AC_MSG_RESULT([yes])],
   [AC_MSG_RESULT([no])]
)
CFLAGS=$ORIGCFLAGS

ORIGCFLAGS=$CFLAGS
CFLAGS="$CFLAGS -Werror -Wno-enum-compare"
AC_MSG_CHECKING([if -Wno-enum-compare is supported])
AC_COMPILE_IFELSE(
   [AC_LANG_SOURCE([[const char hw[] = "Hello, World\n";]])],
   [WARNINGS="$WARNINGS -Wno-enum-compare"
    AC_MSG_RESULT([yes])],
   [AC_MSG_RESULT([no])]
)
CFLAGS=$ORIGCFLAGS

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
   [AC_SUBST([HAVE_PRIVEXT], [YES])
    AC_MSG_RESULT([yes])],
   [AC_SUBST([HAVE_PRIVEXT], [NO])
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

AC_LANG_PUSH([C++])
ORIGCXXFLAGS=$CXXFLAGS
CXXFLAGS="$CXXFLAGS -Wno-trigraphs"
AC_MSG_CHECKING([if -Wno-trigraphs is supported])
AC_LINK_IFELSE([AC_LANG_PROGRAM()],
    [AC_MSG_RESULT([yes])],
    [CXXFLAGS="$ORIGCXXFLAGS"
     AC_MSG_RESULT([no])]
)

ORIGCXXFLAGS=$CXXFLAGS
CXXFLAGS="$CXXFLAGS -Wno-deprecated"
AC_MSG_CHECKING([if -Wno-deprecated is supported])
AC_LINK_IFELSE([AC_LANG_PROGRAM()],
        [AC_MSG_RESULT([yes])],
            [CXXFLAGS="$ORIGCXXFLAGS"
         AC_MSG_RESULT([no])]
)

ORIGCXXFLAGS=$CXXFLAGS
CXXFLAGS="$CXXFLAGS -Wno-strict-aliasing"
AC_MSG_CHECKING([if -Wno-strict-aliasing is supported])
AC_LINK_IFELSE([AC_LANG_PROGRAM()],
        [AC_MSG_RESULT([yes])],
            [CXXFLAGS="$ORIGCXXFLAGS"
         AC_MSG_RESULT([no])]
)

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
AC_CHECK_HEADERS([CommonCrypto/CommonDigest.h],[],[SSL_LIBS="-lssl -lcrypto"])
AC_SUBST(SSL_LIBS)

AC_CHECK_DECLS([backtrace], [], [], [[#include <execinfo.h>]])
AC_CHECK_DECLS([dlopen, dlsym, dlclose, dlerror, dladdr], [], [], [[#include <dlfcn.h>]])
AC_CHECK_DECLS([mmap], [], [], [[#include <sys/mman.h>]])
AC_CHECK_DECLS([flock], [], [], [[#include <sys/file.h>]])
AC_CHECK_DECLS([sigfillset, sigprocmask], [], [], [[#include <signal.h>]])
AC_CHECK_DECLS([utimes], [], [], [[#include <sys/time.h>]])
AC_CHECK_DECLS([asprintf], [], [], [[#include <stdio.h>]])
AC_CHECK_DECLS([getc_unlocked, strlcpy, strlcat, getuid, getgid, rindex, index, strmode, mkstemp, fchmod, fchdir, pwrite])
AC_CHECK_DECLS([readlink], [], [], [[#include <unistd.h>]])

AC_CHECK_DECL([uid_t getuid(void)])
AC_CHECK_DECL([gid_t getgid(void)])

AH_VERBATIM([HAVE_DECL_GETC_UNLOCKED_REPLACEMENT],
[/* For systems that don't have getc_unlocked, use getc  */
#if !HAVE_DECL_GETC_UNLOCKED
# define getc_unlocked(a) getc(a)
#endif])

AH_VERBATIM([X_DECLS],
[/* Declare functions that are missing declarations */
#if !HAVE_DECL_STRLCPY || ! HAVE_DECL_STRLCAT
#include <sys/types.h>
#endif
#if !HAVE_DECL_STRLCPY
#ifdef __cplusplus
extern "C"
#endif
size_t strlcpy(char *dst, const char *src, size_t size);
#endif
#if !HAVE_DECL_STRLCAT
#ifdef __cplusplus
extern "C"
#endif
size_t strlcat(char *dst, const char *src, size_t size);
#endif
#if !HAVE_DECL_MMAP
#ifdef __cplusplus
extern "C"
{
#endif
#include <sys/stat.h>
#include <unistd.h>
#define PROT_READ 0
#define PROT_WRITE 0
#define MAP_FILE 0
#define MAP_PRIVATE 0
#define O_FSYNC 0
#define MAXNAMLEN 255
#define DEFFILEMODE (0666)
#define L_SET SEEK_SET
typedef unsigned int u_int;
typedef unsigned short u_short;
void *mmap(void *start, size_t length, int prot, int flags, int fd, off_t offset);
int munmap(void *start, size_t length);
#ifdef __cplusplus
}
#endif
#endif
#if !HAVE_DECL_FLOCK
int flock (int __fd, int __operation);
#define LOCK_EX 2
#define LOCK_NB 4
#define EOVERFLOW 75
#define ESTALE 116
#define ENOTSUP 95
#define EHOSTUNREACH 113
#define MIN(_a,_b) (_a)<(_b)?(_a):(_b)
#endif
#if defined(__MINGW32__)
#ifdef __cplusplus
extern "C"
#endif
char *realpath(const char *path, char *resolved);
#define sleep(_x) _sleep(_x)
#define bcmp(_a,_b,_n) memcmp(_a,_b,_n)
#define bcopy(_s,_d,_n) memmove(_d,_s,_n)
#define bzero(_p,_n) memset(_p,0,_n)
#define setbuffer(_f,_b,_n) do {} while(0)
#define getwd(_p) getcwd(_p,MAXPATHLEN-1)
#define ffs(_x) __builtin_ffs(_x)
#endif
#if !HAVE_DECL_RINDEX
char *rindex(const char *s, int c);
#endif
#if !HAVE_DECL_INDEX
char *index(const char *s, int c);
#endif
#if !HAVE_DECL_STRMODE
void strmode(int mode, char *p);
#endif
#if !HAVE_DECL_MKSTEMP
int mkstemp(char *__template);
#endif
#if !HAVE_DECL_SIGFILLSET
#define SIG_BLOCK 0
#define SIG_SETMASK 0
int sigfillset(sigset_t *__set);
#endif
#if !HAVE_DECL_SIGPROCMASK
int sigprocmask(int __how, __const sigset_t * __set, sigset_t * __oset);
#endif
#if !HAVE_DECL_FCHMOD
int fchmod(int fildes, mode_t mode);
#endif
#if !HAVE_DECL_FCHDIR
int fchdir(int fildes);
#endif
#if !HAVE_DECL_UTIMES
#include <time.h>
#include <sys/time.h>
int utimes(const char *filename, const struct timeval times[2]);
#endif
/* I took these defines from Linux, Darwin may have
 * different values! */
#if !defined(__APPLE__)
#ifndef S_IFSOCK
 #define S_IFSOCK 0140000
#endif
#ifndef S_ISUID
 #define S_ISUID  0004000
#endif
#ifndef S_IFLNK
 #define S_IFLNK  0120000
#endif
#ifndef S_IRGRP
 #define S_IRGRP 00040
#endif
#ifndef S_IWGRP
 #define S_IWGRP 00020
#endif
#ifndef S_IXGRP
 #define S_IXGRP 00010
#endif
#ifndef S_ISGID
 #define S_ISGID  0002000
#endif
#ifndef S_ISGID
 #define S_ISGID  0002000
#endif
#ifndef S_IROTH
 #define S_IROTH 00004
#endif
#ifndef S_IWOTH
 #define S_IWOTH 00002
#endif
#ifndef S_IXOTH
 #define S_IXOTH 00001
#endif
#ifndef S_ISVTX
 #define S_ISVTX  0001000
#endif
#endif
#if !HAVE_DECL_DLOPEN
#ifdef __cplusplus
extern "C"
#endif
void* dlopen(const char* file, int mode);
#endif
#if !HAVE_DECL_DLERROR
#ifdef __cplusplus
extern "C"
#endif
const char *dlerror(void);
#endif
#if !HAVE_DECL_DLSYM
#ifdef __cplusplus
extern "C"
#endif
void* dlsym(void* handle, const char* name);
#endif
#if !HAVE_DECL_DLCLOSE
#include <dlfcn.h>
#ifdef __cplusplus
extern "C"
#endif
int dlclose(void* handle);
#endif
#if !HAVE_DECL_DLADDR
#include <dlfcn.h>
#ifdef __cplusplus
extern "C"
#endif
int dladdr(void *addr, Dl_info *info);
#endif
#if !HAVE_DECL_ASPRINTF
#include <stdarg.h>
#ifdef __cplusplus
extern "C"
#endif
int vasprintf( char **sptr, const char *fmt, va_list argv );
#ifdef __cplusplus
extern "C"
#endif
int asprintf( char **sptr, char *fmt, ... );
#endif
#if !HAVE_DECL_BACKTRACE
#ifdef __cplusplus
extern "C"
#endif
int backtrace(void **__array, int __size);
#endif
#if !HAVE_DECL_PWRITE
#ifdef __cplusplus
extern "C"
#endif
ssize_t pwrite(int fd, const void *buf, size_t count, off_t offset);
#endif
#if !HAVE_QSORT_R
#ifdef __cplusplus
extern "C"
#endif
void qsort_r(void *base, size_t nmemb, size_t size, void *thunk, int (*compar)(void *, const void *, const void *));
#endif

#ifdef __MINGW32__
 #define FIO_READ_WRITE      _S_IREAD|_S_IWRITE
 #define FIO_READ_WRITE_ME   _S_IREAD|_S_IWRITE
 #define FIO_READ_WRITE_EXEC _S_IREAD|_S_IWRITE|_S_IEXEC
 #define FIO_MASK_ALL_4      _S_IREAD|_S_IWRITE|_S_IEXEC
#else
 #define FIO_READ_WRITE      0666
 #define FIO_READ_WRITE_ME   0600
 #define FIO_READ_WRITE_EXEC 0777
 #define FIO_MASK_ALL_4      07777
#endif
])

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
     CFLAGS="$CFLAGS -D__USE_MINGW_ANSI_STDIO"
     ;;
     *)
     CFLAGS="$CFLAGS -O0 -g"
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

AH_VERBATIM([_LIBC_REPLACEMENTS_LINUX],
[/* Linux libc.h replacements. */
#ifdef HAVE_LIBC_REPLACEMENTS_LINUX
 #include <stdio.h>
 #include <stdlib.h>
 #include <fcntl.h>
 #include <sys/param.h>
 #include <sys/stat.h>
 #include <time.h>
 #include <unistd.h>
#endif
])

AH_VERBATIM([_LIBC_REPLACEMENTS_WINDOWS],
[/* Windows libc.h replacements. */
#ifdef HAVE_LIBC_REPLACEMENTS_WINDOWS
 #include <stdio.h>
 #include <stdlib.h>
 #include <fcntl.h>
 #include <sys/param.h>
 #include <io.h>
#endif
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
