/*
	skyeye.h - necessary definition for skyeye
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
 * 3/21/2003 	init this file.
 * 		add debug macros.
 *		walimis <walimi@peoplemail.com.cn> 		
 * */
#ifndef __SKYEYE_H_
#define __SKYEYE_H_
#include <string.h>
#include <stdio.h>

#ifdef __APPLE__
#include <libkern/OSByteOrder.h>
#endif

#define SKYEYE_DEBUG 0
#if SKYEYE_DEBUG
#define SKYEYE_DBG(msg...) fprintf(stderr, ##msg)
#else
#define SKYEYE_DBG(msg...)
#endif

#define SKYEYE_INFO(msg...)		fprintf(stderr, ##msg);
#define SKYEYE_ERR(msg...)		fprintf(stderr, ##msg);
#define SKYEYE_WARNING(msg...)	fprintf(stderr, ##msg);

#ifndef i8
#define i8	char
#define i16	short
#define i32	int
#define i64	long long
#endif /*i8 */

#ifndef u8
#define u8	unsigned char
#define u16	unsigned short
#define u32	unsigned int
#define u64	unsigned long long
#endif /*u8 */

#ifndef min
#define		min(x,y) (((x) < (y)) ? (x) : (y))
#endif

#ifndef max
#define		max(x,y) (((x) > (y)) ? (x) : (y))
#endif

#ifndef NULL
#define		NULL	((void *)0)
#endif


#ifdef DEBUG
#define d_msg log_msg
#else
#define d_msg(args...)
#endif
//chy 2006-04-24
extern void skyeye_exit(int ret);

#define err_msg(fmt, args...)	fprintf(stderr, "%s %d: %s %s " fmt, __FILE__, __LINE__, __FUNCTION__, \
						strerror(errno), ## args)
					       
#endif /* __SKYEYE_H_ */
