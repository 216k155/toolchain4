#if (HAVE_DECL_MMAP==0) || (HAVE_DECL_FCHMOD==0) || (HAVE_DECL_FCHDIR==0) || (HAVE_DECL_UTIMES==0)

/*
 * WINVER of 0x0600 limits us to Windows Vista and above. There is FileExtd.lib for XP, but it appears
 * to be broken:
 * http://social.msdn.microsoft.com/Forums/en-US/windowssdk/thread/78de6b2f-d01f-4394-a5c5-a4253942ae9c
 * There's also:
 * http://tranxcoder.wordpress.com/2010/02/02/calling-getfileinformationbyhandleex-in-windows-xp/
 * ...but there's no license details given and the first comment needs paying attention to also.
 */

#ifdef WINVER
# undef WINVER
#endif
#define WINVER 0x0600

#ifdef _WIN32_WINNT
# undef _WIN32_WINNT
#endif
#define _WIN32_WINNT 0x0600

#ifndef WIN32_LEAN_AND_MEAN
# define WIN32_LEAN_AND_MEAN
#endif

#include <windows.h>

#ifndef ENOTSUP
# define ENOTSUP 95
#endif

#endif /* (HAVE_DECL_MMAP==0) || (HAVE_DECL_FCHMOD==0) || (HAVE_DECL_FCHDIR==0) || (HAVE_DECL_UTIMES==0) */

#include <mach/mach.h>
#include <mach/mach_error.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#if !defined(__MINGW32__)
 #include <sys/mman.h>
#else
 #include <stddef.h>
#endif
#include <errno.h>
#include <inttypes.h>
#include <mach/mach_time.h>
#include <mach/mach_host.h>
#include <mach/host_info.h>
#include <sys/time.h>

#if (HAVE_DECL_MMAP==0)
void *mmap(void *start, size_t length, int prot, int flags, int fd, off_t offset)
{
	HANDLE hmap;
	void *temp;
	off_t len;
	struct stat st;

    /* Fix up offset wrt dwAllocationGranularity
     * after http://msdn.microsoft.com/en-us/library/windows/desktop/aa366548(v=vs.85).aspx
     */
    SYSTEM_INFO SysInfo;
    GetSystemInfo(&SysInfo);

    /* How far into the page is the offset? */
    off_t PageDelta = offset%(off_t)SysInfo.dwAllocationGranularity;
	uint64_t o = offset-(uint64_t)PageDelta;

	DWORD Protect = PAGE_READONLY;
	DWORD DesiredAccess = FILE_MAP_COPY;
	if (prot != PROT_READ)
	{
        Protect = PAGE_READWRITE;
	    DesiredAccess = FILE_MAP_WRITE;
	}

	if (!fstat(fd, &st))
		len = st.st_size;
	else
	{
        fprintf(stderr,"mmap: fstat failed\n");
        exit(1);
	}

	if ((length + offset) > len)
		length = (size_t)len - (size_t)offset;

	hmap = CreateFileMapping((HANDLE)_get_osfhandle(fd), 0, Protect, 0, 0, 0);

	if (!hmap)
		return (void*)-1;

	temp = MapViewOfFile(hmap, DesiredAccess, (uint32_t)((o>>32)&0xffffffff), (uint32_t)(o&0xffffffff), length+PageDelta);

	if (!CloseHandle(hmap))
		fprintf(stderr,"mmap: CloseHandle failed\n");

	return temp ? temp+PageDelta : (void*)-1;
}

int munmap(void *start, size_t length)
{
    SYSTEM_INFO SysInfo;
    GetSystemInfo(&SysInfo);
    off_t PageDelta = (off_t)start%(off_t)SysInfo.dwAllocationGranularity;
	return !UnmapViewOfFile((void*)(start-PageDelta));
}
#endif /* HAVE_DECL_MMAP */

#if (HAVE_FLOCK==0)
int flock (int __fd, int __operation)
{
    return 0;
}
#endif /* HAVE_FLOCK */

#if (HAVE_DECL_GETUID==0)
uid_t getuid(void)
{
    return (uid_t)0;
}
#endif /* HAVE_DECL_GETUID */

#if (HAVE_DECL_GETUID==0)
gid_t getgid(void)
{
    return (gid_t)0;
}
#endif /* HAVE_DECL_GETGID */

#if (HAVE_DECL_RINDEX==0)
char *rindex(const char *s, int c)
{
    return strrchr(s,c);
}
#endif /* HAVE_DECL_RINDEX */

#if (HAVE_DECL_INDEX==0)
char *index(const char *s, int c)
{
    return strchr(s,c);
}
#endif /* HAVE_DECL_INDEX */

#if (HAVE_DECL_STRMODE==0)
#include <sys/stat.h>
void strmode(int mode, char *p)
{
	 /* print type */
	switch (mode & S_IFMT) {
	case S_IFDIR:			/* directory */
		*p++ = 'd';
		break;
	case S_IFCHR:			/* character special */
		*p++ = 'c';
		break;
	case S_IFBLK:			/* block special */
		*p++ = 'b';
		break;
	case S_IFREG:			/* regular */
		*p++ = '-';
		break;
	case S_IFLNK:			/* symbolic link */
		*p++ = 'l';
		break;
#ifdef S_IFSOCK
	case S_IFSOCK:			/* socket */
		*p++ = 's';
		break;
#endif
#ifdef S_IFIFO
	case S_IFIFO:			/* fifo */
		*p++ = 'p';
		break;
#endif
#ifdef S_IFWHT
	case S_IFWHT:			/* whiteout */
		*p++ = 'w';
		break;
#endif
	default:			/* unknown */
		*p++ = '?';
		break;
	}
	/* usr */
	if (mode & S_IRUSR)
		*p++ = 'r';
	else
		*p++ = '-';
	if (mode & S_IWUSR)
		*p++ = 'w';
	else
		*p++ = '-';
	switch (mode & (S_IXUSR | S_ISUID)) {
	case 0:
		*p++ = '-';
		break;
	case S_IXUSR:
		*p++ = 'x';
		break;
	case S_ISUID:
		*p++ = 'S';
		break;
	case S_IXUSR | S_ISUID:
		*p++ = 's';
		break;
	}
	/* group */
	if (mode & S_IRGRP)
		*p++ = 'r';
	else
		*p++ = '-';
	if (mode & S_IWGRP)
		*p++ = 'w';
	else
		*p++ = '-';
	switch (mode & (S_IXGRP | S_ISGID)) {
	case 0:
		*p++ = '-';
		break;
	case S_IXGRP:
		*p++ = 'x';
		break;
	case S_ISGID:
		*p++ = 'S';
		break;
	case S_IXGRP | S_ISGID:
		*p++ = 's';
		break;
	}
	/* other */
	if (mode & S_IROTH)
		*p++ = 'r';
	else
		*p++ = '-';
	if (mode & S_IWOTH)
		*p++ = 'w';
	else
		*p++ = '-';
	switch (mode & (S_IXOTH | S_ISVTX)) {
	case 0:
		*p++ = '-';
		break;
	case S_IXOTH:
		*p++ = 'x';
		break;
	case S_ISVTX:
		*p++ = 'T';
		break;
	case S_IXOTH | S_ISVTX:
		*p++ = 't';
		break;
	}
	*p++ = ' ';		/* will be a '+' if ACL's implemented */
	*p = '\0';
}
#endif /* HAVE_DECL_STRMODE */

#if (HAVE_DECL_MKSTEMP==0)
#include <io.h>
#include <sys/stat.h>
#include <fcntl.h>
int mkstemp(char *tmplate)
{
    int ret;
    mktemp(tmplate);
    ret=_open(tmplate,O_RDWR|O_BINARY|O_CREAT|O_EXCL|_O_SHORT_LIVED, _S_IREAD|_S_IWRITE);
    return ret;
}
#endif /* HAVE_DECL_MKSTEMP */
#if (HAVE_DECL_SIGFILLSET==0)
int sigfillset (sigset_t *__set)
{
    return 0;
}
#endif /* HAVE_DECL_SIGFILLSET */
#if (HAVE_DECL_SIGPROCMASK==0)
int sigprocmask (int __how, __const sigset_t * __set, sigset_t * __oset)
{
    return 0;
}
#endif /* HAVE_DECL_SIGPROCMASK */

#if (HAVE_DECL_FCHMOD==0)
WINBASEAPI BOOL WINAPI SetFileInformationByHandle(HANDLE,FILE_INFO_BY_HANDLE_CLASS,LPVOID,DWORD);
int fchmod(int fildes, mode_t mode)
{
	FILE_BASIC_INFO basicInfo;
	HANDLE h = (HANDLE)_get_osfhandle(fildes);
	if(!GetFileInformationByHandleEx(h, FileBasicInfo, &basicInfo, sizeof(FILE_BASIC_INFO)))
		return -1;
	if( mode & S_IWUSR )
		basicInfo.FileAttributes &= ~FILE_ATTRIBUTE_READONLY;
	else
		basicInfo.FileAttributes |= FILE_ATTRIBUTE_READONLY;
	if(!SetFileInformationByHandle(h, FileBasicInfo, &basicInfo, sizeof(FILE_BASIC_INFO)))
		return -1;
	return 0;
}
#endif /* HAVE_DECL_FCHMOD */

#if (HAVE_DECL_FCHDIR==0)
WINBASEAPI BOOL WINAPI SetFileInformationByHandle(HANDLE,FILE_INFO_BY_HANDLE_CLASS,LPVOID,DWORD);
int fchdir(int fildes)
{
    char storage[sizeof(FILE_NAME_INFO)+1024*sizeof(WCHAR)];
	FILE_NAME_INFO* pNameInfo = (FILE_NAME_INFO*)&storage[0];
	pNameInfo->FileNameLength=1023;
	HANDLE h = (HANDLE)_get_osfhandle(fildes);
	if(!GetFileInformationByHandleEx(h, FileNameInfo, pNameInfo, sizeof(FILE_BASIC_INFO)))
		return -1;
	if(wcsrchr(pNameInfo->FileName,'\\'))
	{
        *wcsrchr(pNameInfo->FileName,'\\') = '\0';
	}
	SetCurrentDirectoryW(pNameInfo->FileName);
	return 0;
}
#endif /* HAVE_DECL_FCHDIR */

#if (HAVE_DECL_UTIMES==0)
#include <time.h>
#include <sys/time.h>
static void UnixTimeToFileTime(struct timeval t, LPFILETIME pft)
{
    /* Note that LONGLONG is a 64-bit value */
    LONGLONG ll;

    ll = Int32x32To64(t.tv_sec, 10000000LL) + t.tv_usec*10 + 116444736000000000;
    pft->dwLowDateTime = (DWORD)ll;
    pft->dwHighDateTime = ll >> 32;
}
int utimes(const char *filename, const struct timeval times[2])
{
    FILETIME LastAccessTime;
    FILETIME LastModificationTime;
    HANDLE hFile;

    UnixTimeToFileTime(times[0], &LastAccessTime);
    UnixTimeToFileTime(times[1], &LastModificationTime);
    hFile=CreateFileA(filename, FILE_WRITE_ATTRIBUTES, FILE_SHARE_DELETE | FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
    if(hFile==INVALID_HANDLE_VALUE)
    {
        return -1;
    }

    if(!SetFileTime(hFile, NULL, &LastAccessTime, &LastModificationTime))
    {
        return -1;
    }
    CloseHandle(hFile);
    return 0;
}
#endif /* HAVE_DECL_UTIMES */

#if (HAVE_DECL_DLOPEN==0)
void *dlopen(const char* file, int mode)
{
    return (void*)LoadLibrary(file);
}
#endif /* HAVE_DECL_DLOPEN */

#if (HAVE_DECL_DLSYM==0)
void *dlsym(void* handle, const char* name)
{
    return (void*)GetProcAddress((HMODULE)handle,(LPCSTR)name);
}
#endif /* HAVE_DECL_DLSYM */

#if (HAVE_DECL_DLCLOSE==0)
int dlclose(void* handle)
{
    if(FreeLibrary((HMODULE)handle))
        return 0;
    return 1;
}

int dladdr(void *addr, Dl_info *info)
{
    memset(info,0,sizeof(info));
    return 0;
}
#endif /* HAVE_DECL_DLCLOSE */

#if (HAVE_DECL_DLERROR==0)
const char *dlerror(void)
{
    return 0;
}
#endif/*HAVE_DECL_DLERROR*/

#if (HAVE_DECL_ASPRINTF==0)
/* From Keith Packard. */
#include <stdarg.h>
int vasprintf( char **sptr, const char *fmt, va_list argv )
{
    int wanted = vsnprintf( *sptr = NULL, 0, fmt, argv );
    if( (wanted < 0) || ((*sptr = malloc( 1 + wanted )) == NULL) )
    return -1;

    return vsprintf( *sptr, fmt, argv );
}
int asprintf( char **sptr, char *fmt, ... )
{
    int retval;
    va_list argv;
    va_start( argv, fmt );
    retval = vasprintf( sptr, fmt, argv );
    va_end( argv );
    return retval;
}
#endif /* HAVE_DECL_ASPRINTF */

#if (HAVE_DECL_BACKTRACE==0)
int backtrace(void **__array, int __size)
{
    return 0;
}
#endif /* HAVE_DECL_BACKTRACE */

#if (HAVE_DECL_PWRITE==0)
ssize_t pwrite(int fd, const void *buf, size_t count, off_t offset)
{
    ssize_t res;
    off_t old_pos;

    old_pos = lseek(fd, 0, SEEK_CUR);
    lseek (fd, offset, SEEK_SET);
    res = write(fd, buf, count);
    lseek(fd, old_pos, SEEK_SET);

    return res;
}
#endif /* HAVE_DECL_PWRITE */

#ifdef NEED_BSD_QSORT_R
__thread void *_qsort_thunk = NULL;
int (*_qsort_saved_func)(void *, const void *, const void *) = NULL;

static int _qsort_comparator(const void *a, const void *b);

static int _qsort_comparator(const void *a, const void *b)
{
  return _qsort_saved_func(_qsort_thunk, a, b);
}

void
qsort_r(void *base, size_t nmemb, size_t size, void *thunk,
    int (*compar)(void *, const void *, const void *))
{
  _qsort_thunk = thunk;
  _qsort_saved_func = compar;

  qsort(base, nmemb, size, _qsort_comparator);
}
#endif /* NEED_BSD_QSORT_R */

#ifndef HAVE__NSGETEXECUTABLEPATH
/**
 * Based on MonetDB's get_bin_path
 * http://dev.monetdb.org/hg/MonetDB/file/54ad354daff8/common/utils/mutils.c#l340
 * Really, bufsize should be set to the size required too.
 */
int _NSGetExecutablePath(char* buf, unsigned long* bufsize)
{
#if defined(_MSC_VER) || defined(__MINGW32__)
    if (GetModuleFileName(NULL, buf, (DWORD)(*bufsize)) != 0) {
        /* Early conversion to unix slashes instead of more changes
         * everywhere else... */
        char *winslash = strchr(buf,'\\');
        while (winslash) {
            *winslash = '/';
            winslash = strchr(winslash,'\\');
        }
		return strlen(buf);
	}
	return -1;
#elif (HAVE_DECL_READLINK) /* Linux */
    int ret = readlink("/proc/self/exe", buf, (size_t)(*bufsize));
    if(ret != -1) {
        buf[ret] = '\0';
    }
    return ret;
#else
	return -1; /* Fail on all other systems for now */
#endif /* _MSC_VER */
}
#endif/* HAVE__NSGETEXECUTABLEPATH */

#if (HAVE_DECL_REALPATH==0)
char *realpath(const char *path, char *resolved)
{
    char* winslash;
    _fullpath(resolved,path,255);
    winslash = strchr(resolved,'\\');
    while (winslash) {
        *winslash = '/';
        winslash = strchr(winslash,'\\');
    }
    return resolved;
}
#endif /* HAVE_DECL_REALPATH */

#ifndef HAVE_STRLCPY

/*      $OpenBSD: strlcpy.c,v 1.11 2006/05/05 15:27:38 millert Exp $        */

/*
 * Copyright (c) 1998 Todd C. Miller <Todd.Miller@courtesan.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sys/types.h>
#include <string.h>


/*
 * Copy src to string dst of size siz.  At most siz-1 characters
 * will be copied.  Always NUL terminates (unless siz == 0).
 * Returns strlen(src); if retval >= siz, truncation occurred.
 */
size_t strlcpy(char *dst, const char *src, size_t siz)
{
        char *d = dst;
        const char *s = src;
        size_t n = siz;

        /* Copy as many bytes as will fit */
        if (n != 0) {
                while (--n != 0) {
                        if ((*d++ = *s++) == '\0')
                                break;
                }
        }

        /* Not enough room in dst, add NUL and traverse rest of src */
        if (n == 0) {
                if (siz != 0)
                        *d = '\0';                /* NUL-terminate dst */
                while (*s++)
                        ;
        }

        return(s - src - 1);        /* count does not include NUL */
}

#endif /* HAVE_STRLCPY */

#ifndef HAVE_STRLCAT

/*	$OpenBSD: strlcat.c,v 1.13 2005/08/08 08:05:37 espie Exp $	*/

/*
 * Copyright (c) 1998 Todd C. Miller <Todd.Miller@courtesan.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sys/types.h>
#include <string.h>

/*
 * Appends src to string dst of size siz (unlike strncat, siz is the
 * full size of dst, not space left).  At most siz-1 characters
 * will be copied.  Always NUL terminates (unless siz <= strlen(dst)).
 * Returns strlen(src) + MIN(siz, strlen(initial dst)).
 * If retval >= siz, truncation occurred.
 */
size_t strlcat(char *dst, const char *src, size_t siz)
{
        char *d = dst;
        const char *s = src;
        size_t n = siz;
        size_t dlen;

        /* Find the end of dst and adjust bytes left but don't go past end */
        while (n-- != 0 && *d != '\0')
                d++;
        dlen = d - dst;
        n = siz - dlen;

        if (n == 0)
                return(dlen + strlen(s));
        while (*s != '\0') {
                if (n != 1) {
                        *d++ = *s;
                        n--;
                }
                s++;
        }
        *d = '\0';

        return(dlen + (s - src));	/* count does not include NUL */
}

#endif /* HAVE_STRLCAT */

#if (HAVE_GETATTRLIST==0)
int getattrlist(const char* a,void* b,void* c,size_t d,unsigned int e)
{
  errno = ENOTSUP;
  return -1;
}
#endif /* HAVE_DECL_GETATTRLIST */

kern_return_t mach_timebase_info( mach_timebase_info_t info)
{
   info->numer = 1;
   info->denom = 1;
   return 0;
}

char* mach_error_string(mach_error_t error_value)
{
  return "Unknown mach error";
}

mach_port_t mach_host_self(void)
{
  return 0;
}

kern_return_t host_info(host_t host, host_flavor_t flavor, host_info_t host_info_out, mach_msg_type_number_t *host_info_outCnt)
{
  if(flavor == HOST_BASIC_INFO)
  {
    host_basic_info_t      basic_info;

    basic_info = (host_basic_info_t) host_info_out;
    memset(basic_info, 0x00, sizeof(*basic_info));
    basic_info->cpu_type = EMULATED_HOST_CPU_TYPE;
    basic_info->cpu_subtype = EMULATED_HOST_CPU_SUBTYPE;
  }

  return 0;
}

mach_port_t mach_task_self_ = 0;

kern_return_t mach_port_deallocate(ipc_space_t task, mach_port_name_t name)
{
  return 0;
}

kern_return_t vm_allocate(vm_map_t target_task, vm_address_t *address, vm_size_t size, int flags)
{
  vm_address_t addr = 0;

  addr = (vm_address_t)calloc(size, sizeof(char));
  if(addr == 0)
    return 1;

  *address = addr;

  return 0;
}

kern_return_t vm_deallocate(vm_map_t target_task, vm_address_t address, vm_size_t size)
{
  /*  free((void *)address); leak it here */
  return 0;
}

kern_return_t host_statistics(host_t host_priv, host_flavor_t flavor,
    host_info_t host_info_out, mach_msg_type_number_t *host_info_outCnt)
{
  return ENOTSUP;
}

kern_return_t map_fd(int fd, vm_offset_t offset, vm_offset_t *va, boolean_t findspace,
    vm_size_t size)
{
  void *addr = NULL;

  addr = mmap(0, size, PROT_READ|PROT_WRITE,
          MAP_PRIVATE|MAP_FILE, fd, offset);

  if(addr == (void *)-1)
  {
    return 1;
  }

  *va = (vm_offset_t)addr;

  return 0;
}

uint64_t mach_absolute_time(void)
{
  uint64_t t = 0;
  struct timeval tv;
  if (gettimeofday(&tv,NULL)) return t;
  t = ((uint64_t)tv.tv_sec << 32)  | tv.tv_usec;
  return t;
}

vm_size_t vm_page_size = 4096; /* hardcoded to match expectations of darwin */
