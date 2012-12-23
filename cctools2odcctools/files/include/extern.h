#define __private_extern__ __attribute__((visibility("hidden")))

/*
   These includes are needed by all .cpp
   files as they don't include libc
*/

/*
   For *printf and strcmp
*/
#if defined(__linux__)
# include <stdio.h>
# include <string.h>
#elif defined(__MINGW32__)
# include <stdio.h>
# include <string.h>
#endif

/*
   For PATH_MAX, MAXPATHLEN, va_*
*/
#if !defined(__APPLE__)
# include <limits.h>
# include <sys/param.h>
# include <stdarg.h>
#endif

#include <sys/sysctl.h>
