/*
	gettimeofday.h - portable gettimeofday function for skyeye
	Copyright (C) 2007 Skyeye Develop Group
	for help please send mail to <skyeye-developer@lists.gro.clinux.org> 

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
*/

/*
 * 03/03/2007   initial version by Anthony Lee
 */

#ifndef __SKYEYE_GETTIMEOFDAY_H__
#define __SKYEYE_GETTIMEOFDAY_H__

#include <time.h> /* for gmtime */
#include <sys/time.h> /* for struct timeval */

#define HAVE_GETTIMEOFDAY

#if defined(__MINGW32__)
	#include <_mingw.h>
	#if (__MINGW32_MAJOR_VERSION < 3)
		#undef HAVE_GETTIMEOFDAY
	#elif (__MINGW32_MAJOR_VERSION == 3 && __MINGW32_MINOR_VERSION < 10)
		#undef HAVE_GETTIMEOFDAY
	#endif
#endif /* defined(__MINGW32__) */


#ifndef HAVE_GETTIMEOFDAY

#if defined(__MINGW32__)
/* we just use timeval, timezone is ignored. */
struct timezone {
};
#endif /* defined(__MINGW32__) */

int gettimeofday(struct timeval *tv, struct timezone *tz);

#endif /* HAVE_GETTIMEOFDAY */


#endif /* __SKYEYE_GETTIMEOFDAY_H__ */

