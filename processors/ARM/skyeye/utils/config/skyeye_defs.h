/*
        skyeye_defs.h - some nessisary header files for skyeye
        Copyright (C) 2003 Skyeye Develop Group
        for help please send mail to <skyeye-developer@lists.sf.linuxforum.net>

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
 * 12/18/2006   Michael.Kang  <blackfin.kang@gmail.com>
 */


#ifndef __SKYEYE_DEFS_H__
#define __SKYEYE_DEFS_H__
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdint.h>

#ifndef FALSE

#define FALSE 0
#define TRUE 1
#endif
#define LOW 0
#define HIGH 1
#define LOWHIGH 1
#define HIGHLOW 2

#endif
