/* sqAndroidCompat.h -- POSIX functions that Android's Bionic libc does not provide.
 *
 * Force-included (-include) when cross-compiling the Unix VM for Android.
 * Bionic implements most of POSIX, but a few functions the Unix VM and the
 * OSProcess plugin rely on are absent at *every* API level:
 *
 *   getdtablesize()  -- legacy BSD; the POSIX spelling is sysconf(_SC_OPEN_MAX)
 *   confstr()        -- never implemented by Bionic
 *
 * Other gaps are handled by choosing a high enough minimum API level instead
 * of shimming them (nl_langinfo needs API 26, glob/globfree need API 28), and
 * by upstream's own NOEXECINFO switch (backtrace() needs API 33).
 */

#ifndef SQ_ANDROID_COMPAT_H
#define SQ_ANDROID_COMPAT_H

#ifdef __ANDROID__

#include <unistd.h>
#include <string.h>

/* Bionic declares login_tty() in <utmp.h>, not in <pty.h>/<termios.h> where
 * the Unix sources expect to find it via openpty.h. */
#include <utmp.h>

/* Number of file descriptors the process may have open. */
static inline int
getdtablesize(void)
{
	long n = sysconf(_SC_OPEN_MAX);
	return n > 0 ? (int)n : 1024;
}

/* confstr(3). Bionic has none, so answer only the one variable that is both
 * well defined on Android and actually asked for (_CS_PATH); anything else
 * answers 0, which callers already treat as "not supported". */
#ifndef _CS_PATH
# define _CS_PATH 1
#endif

static inline size_t
confstr(int name, char *buf, size_t len)
{
	const char *value;

	switch (name) {
	case _CS_PATH: value = "/system/bin:/system/xbin"; break;
	default:       return 0;
	}
	if (buf && len) {
		strncpy(buf, value, len - 1);
		buf[len - 1] = '\0';
	}
	return strlen(value) + 1;
}

#endif /* __ANDROID__ */
#endif /* SQ_ANDROID_COMPAT_H */
