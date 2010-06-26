/*
	usleep.c - portable usleep function for skyeye on Win32
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
#include "utils/portable/usleep.h"

int usleep(unsigned long usec)
{
	HANDLE timer = NULL;
	LARGE_INTEGER due;

	timer = CreateWaitableTimer(NULL, TRUE, NULL);
	if(timer == NULL) return -1;

	due.QuadPart = (-((__int64)usec)) * 10LL;
	if(!SetWaitableTimer(timer, &due, 0, NULL, NULL, 0))
	{
		CloseHandle(timer);
		return -1;
	}
	WaitForSingleObject(timer, INFINITE);
	CloseHandle(timer);

	return 0;
}

