/* WeDoLinux.c -- Linux plugin for Lego WeDo
 *
 * Author: Derek O'Connell <doc@doconnel.f9.co.uk>
 * 
 *   Copyright (C) 2010 by MIT
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 *   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 *
 * Last edited: 2010-06-20 16:23:00 by Derek O'Connell
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <linux/hiddev.h>


#define true 1
#define false 0

#define NTEMPLATES  2
#define MAXSTRLEN  64

static char hiddevFileTemplates[NTEMPLATES][MAXSTRLEN] = {
	"/dev/usb/hiddev0",
	"/dev/hiddev0"
};

static char hiddevFileName[MAXSTRLEN];

static int fdWeDo = 0;


/* ================================================= */
/* ============== FUNCTION PROTOTYPES ============== */
/* ================================================= */


/* LIBRARY CONSTRUCTOR/DESCTRUCTOR */
void __attribute__ ((constructor)) libConWeDo(void);
void __attribute__ ((destructor)) libDesWeDo(void);

/* SQUEAK INTERFACE */
int WeDoOpenPort(void);
int WeDoClosePort(void);
int WeDoRead(char *bufPtr, int bufSize);
int WeDoWrite(char *bufPtr, int bufSize);


/* ================================================= */
/* ========== LIB CONSTRUCTOR/DESTRUCTOR =========== */
/* ================================================= */


void __attribute__ ((constructor)) 
libConWeDo(void) {
	/* NOTHING TO DO (YET) */
}


void __attribute__ ((destructor)) 
libDesWeDo(void) {
	WeDoClosePort();
}


/* ================================================= */
/* =================== UTILITY ===================== */
/* ================================================= */


void 
delay(int mS) {
	int microsecs;
	struct timeval tv;

	microsecs=mS * 1000;
	tv.tv_sec  = microsecs/1000000;
	tv.tv_usec = microsecs%1000000;

	select(0, NULL, NULL, NULL, &tv);
}


/* ================================================= */
/* ================== WEDO UTILS =================== */
/* ================================================= */


int
scanForWeDo(char *fileTemplate) { /* eg, "/dev/usb/hiddev0" */
	int f, i;
	struct hiddev_devinfo dinfo;
	
	f = 0;
	for (i=0; i<10; i++) {
		strcpy(hiddevFileName, fileTemplate); 
		hiddevFileName[strlen(hiddevFileName)-1] = '0' + i;
		if (-1 != (f = open(hiddevFileName, O_RDWR)))
			if (-1 != ioctl(f, HIDIOCGDEVINFO, &dinfo))
				if ((dinfo.vendor == 0x0694) & (dinfo.product == 0x0003))
					return f;
	}
	return 0;
}


int
isWeDoAvailable() {
	struct stat st;

	if (!fdWeDo) return false;

	/* Required, catches device being unplugged... */
	if (-1 == stat(hiddevFileName, &st)) {
		WeDoClosePort();
		return false;
	}
	
	return true;
}


/* ================================================= */
/* ================= SCRATCH I/F =================== */
/* ================================================= */


int 
WeDoOpenPort(void) {
	int i;

	if (fdWeDo) return true;

	fdWeDo = 0;
	for (i=0; i<NTEMPLATES; i++)
		if (fdWeDo = scanForWeDo(hiddevFileTemplates[i]))
			break;
	
	if (!fdWeDo) return false;
		
	delay(100);
	return true;
}


int 
WeDoClosePort(void) {
	if (!fdWeDo) return true;
	close(fdWeDo);
	fdWeDo = 0;
	return true;
}


int 
WeDoRead(char *bufPtr, int bufSize) {
	int i;
	struct hiddev_usage_ref uref;

	if (!isWeDoAvailable()) return 8;
	
	for (i = 0; i < 8; i++)	{
		uref.report_type = HID_REPORT_TYPE_INPUT;
		uref.report_id = HID_REPORT_ID_FIRST;
		uref.field_index = 0;
		uref.usage_index = i;
		uref.value = 0;
		if (isWeDoAvailable())
			if (ioctl(fdWeDo, HIDIOCGUCODE, &uref) < 0) continue;
		if (isWeDoAvailable())
			if (ioctl(fdWeDo, HIDIOCGUSAGE, &uref) < 0) continue;
		*(bufPtr + i) = uref.value;
	}
	return 8;
}


int 
WeDoWrite(char *bufPtr, int bufSize) {
	int i;

	if (!isWeDoAvailable()) return 8;
	
	for (i = 0; i < 8; i++)
		if (isWeDoAvailable())
			ioctl(fdWeDo, HIDIOCSUSAGE, (int []){HID_REPORT_TYPE_OUTPUT, 0, 0, i, 0, *(bufPtr + i)});
	if (isWeDoAvailable())
		ioctl(fdWeDo, HIDIOCSREPORT,(int []){HID_REPORT_TYPE_OUTPUT, 0, 1});
	if (isWeDoAvailable())
		ioctl(fdWeDo, HIDIOCSREPORT,(int []){HID_REPORT_TYPE_OUTPUT, 0, 1});

	return 8;
}

