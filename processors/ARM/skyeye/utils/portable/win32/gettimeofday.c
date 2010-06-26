/*
	gettimeofday.c - portable gettimeofday function for skyeye on Win32
	Copyright (C) 2007 Anthony Lee <don.anthony.lee+program@gmail.com>

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
 * 03/03/2007   written by Anthony Lee
 */

#include <windows.h>
#include "utils/portable/gettimeofday.h"

int gettimeofday(struct timeval *tv, struct timezone *tz)
{
	FILETIME CurrentTime;
	__int64 cur_time;

	if(tv == NULL || tz != NULL) return -1;

	GetSystemTimeAsFileTime(&CurrentTime);
	cur_time = ((__int64)CurrentTime.dwHighDateTime << 32) + (__int64)CurrentTime.dwLowDateTime;
	cur_time -= 116444736000000000LL;
	cur_time /= 10LL;

	tv->tv_sec = (cur_time / 1000000LL);
	tv->tv_usec = (cur_time % 1000000LL);

	return 0;
}

