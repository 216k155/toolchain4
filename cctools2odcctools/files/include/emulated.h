#ifndef EMULATED_H_INCLUDED
#define EMULATED_H_INCLUDED

#ifdef __cplusplus
# include <cstddef>
#else
# include <stddef.h>
#endif /* __cplusplus */

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#if (HAVE_DECL_SLEEP==0)
unsigned int __cdecl sleep (unsigned int _Duration);
#endif /* HAVE_DECL_SLEEP */

/*
The following 2 includes *were* inside the
#if (HAVE_DECL_MMAP==0) block. This change
(and also libc.h not including  sys/stat.h)
are because '__unused' is a define used in
a single Apple header and Linux x86-64 uses
an array called '__unused' in stat.h. It will
be cleaner to instead remove __unused from
the Apple header and then never worry about it
again. Once done, we must also remove all the
autoconf logic responsible for checing and
defining __unused.
*/

#include <sys/stat.h>
#include <unistd.h>

#if (HAVE_DECL_MMAP==0)
#define PROT_READ 0
#define PROT_WRITE 0
#define MAP_FILE 0
#define MAP_PRIVATE 0
#define O_FSYNC 0
#define MAXNAMLEN 255
#define DEFFILEMODE (0666)
#define L_SET SEEK_SET
void *mmap(void *start, size_t length, int prot, int flags, int fd, off_t offset);
int munmap(void *start, size_t length);
#endif /* HAVE_DECL_MMAP */

#if (HAVE_FLOCK==0)
#define LOCK_EX 2
#define LOCK_NB 4
#define EOVERFLOW 75
#define ESTALE 116
#define ENOTSUP 95
#define EHOSTUNREACH 113
int flock (int __fd, int __operation);
#endif /* HAVE_FLOCK */

#if (HAVE_DECL_GETUID==0)
uid_t getuid(void);
#endif /* HAVE_DECL_GETUID */

#if (HAVE_DECL_GETUID==0)
gid_t getgid(void);
#endif /* HAVE_DECL_GETGID */

#if (HAVE_DECL_RINDEX==0)
char *rindex(const char *s, int c);
#endif /* HAVE_DECL_RINDEX */

#if (HAVE_DECL_INDEX==0)
char *index(const char *s, int c);
#endif /* HAVE_DECL_INDEX */

#if (HAVE_DECL_STRMODE==0)
void strmode(int mode, char *p);
#endif /* HAVE_DECL_STRMODE */

#if (HAVE_DECL_MKSTEMP==0)
int mkstemp(char *tmplate);
#endif /* HAVE_DECL_MKSTEMP */

#if (HAVE_DECL_SIGFILLSET==0)
#define SIG_BLOCK 0
#define SIG_SETMASK 0
int sigfillset (sigset_t *__set);
#endif /* HAVE_DECL_SIGFILLSET */

#if (HAVE_DECL_SIGPROCMASK==0)
int sigprocmask (int __how, __const sigset_t * __set, sigset_t * __oset);
#endif /* HAVE_DECL_SIGPROCMASK */

#if (HAVE_DECL_FCHMOD==0)
int fchmod(int fildes, mode_t mode);
#endif /* HAVE_DECL_FCHMOD */

#if (HAVE_DECL_FCHDIR==0)
int fchdir(int fildes);
#endif /* HAVE_DECL_FCHDIR */

#if (HAVE_DECL_UTIMES==0)
#include <sys/time.h>
int utimes(const char *filename, const struct timeval times[2]);
#endif /* HAVE_DECL_UTIMES */

#if (HAVE_DECL_DLOPEN==0)
void *dlopen(const char* file, int mode);
#endif /* HAVE_DECL_DLOPEN */

#if (HAVE_DECL_DLSYM==0)
void *dlsym(void* handle, const char* name);
#endif /* HAVE_DECL_DLSYM */

#if (HAVE_DECL_DLCLOSE==0)
#include <dlfcn.h>
int dlclose(void* handle);
int dladdr(void *addr, Dl_info *info);
#endif /* HAVE_DECL_DLCLOSE */

#if (HAVE_DECL_DLERROR==0)
const char *dlerror(void);
#endif /* HAVE_DECL_DLERROR */

#if (HAVE_DECL_ASPRINTF==0)
int asprintf( char **sptr, char *fmt, ... );
#endif /* HAVE_DECL_ASPRINTF */

#if (HAVE_DECL_BACKTRACE==0)
int backtrace(void **__array, int __size);
#endif /* HAVE_DECL_BACKTRACE */

#if (HAVE_DECL_PWRITE==0)
ssize_t pwrite(int fd, const void *buf, size_t count, off_t offset);
#endif /* HAVE_DECL_PWRITE */

#ifdef NEED_BSD_QSORT_R
void qsort_r(void *base, size_t nmemb, size_t size, void *thunk, int (*compar)(void *, const void *, const void *));
#define HAVE_BSD_QSORT_R
#endif /* NEED_BSD_QSORT_R */

/* if 0 because include/mach-o/dyld.h:240 also declares _NSGetExecutablePath */
#if 0 && !defined(HAVE__NSGETEXECUTABLEPATH)
#include <stdint.h>
int _NSGetExecutablePath(char* buf, unsigned long* bufsize);
#endif /* HAVE__NSGETEXECUTABLEPATH */

#if (HAVE_DECL_REALPATH==0)
char *realpath(const char *path, char *resolved);
#endif /* HAVE_DECL_REALPATH */

#ifndef HAVE_STRLCPY
size_t strlcpy(char *dst, const char *src, size_t siz);
#endif /* HAVE_STRLCPY */

#ifndef HAVE_STRLCAT
size_t strlcat(char *dst, const char *src, size_t siz);
#endif /* HAVE_STRLCAT */

#if (HAVE_GETATTRLIST==0)
int getattrlist(const char* a, void* b, void* c, size_t d, unsigned int e);
#endif /* HAVE_DECL_GETATTRLIST */

/*
kern_return_t mach_timebase_info( mach_timebase_info_t info);
char* mach_error_string(mach_error_t error_value);
mach_port_t mach_host_self(void);
kern_return_t host_info(host_t host, host_flavor_t flavor, host_info_t host_info_out, mach_msg_type_number_t *host_info_outCnt);
kern_return_t mach_port_deallocate(ipc_space_t task, mach_port_name_t name);
kern_return_t vm_allocate(vm_map_t target_task, vm_address_t *address, vm_size_t size, int flags);
kern_return_t vm_deallocate(vm_map_t target_task, vm_address_t address, vm_size_t size);
kern_return_t host_statistics(host_t host_priv, host_flavor_t flavor, host_info_t host_info_out, mach_msg_type_number_t *host_info_outCnt);
kern_return_t map_fd(int fd, vm_offset_t offset, vm_offset_t *va, boolean_t findspace, vm_size_t size);
uint64_t mach_absolute_time(void);
*/

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* EMULATED_H_INCLUDED */
