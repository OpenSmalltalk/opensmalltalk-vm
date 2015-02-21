/* sqCamera-linux.c -- plugin for hardware camera on Linux
 *
 * Author: Derek O'Connell <doc@doconnel.f9.co.uk>
 * 
 *   Copyright (C) 2010 by Derek O'Connel
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
 * Last edited: 2012-07-30 14:59:01 by piumarta on emilia
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <getopt.h> 

#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <dlfcn.h>

#include <asm/types.h>	  /* for videodev2.h */

#include <linux/videodev2.h>


#define sqInt int
#define true 1
#define false 0


/* >>>>> USE_TEST_PATTERN >>>>
/  
/ Helps check Squeak is capturing and displaying the 
/ latest frame. See CameraGetFrame() which will
/ return single colour frames in the sequence RGB.
/ 
/ Remove the "x" to enable...
*/

#define USE_TEST_PATTERNx

#ifdef USE_TEST_PATTERN
  static int tstColourIdx = 0;
#endif


/* >>>>> LIBV4L2 USAGE >>>>> 
/ 
/ Attempting to get best-of-all-worlds so
/ explicitly loading libv4l2 if available
/ to avoid build-time dependency.
/ 
*/

void *hLibv4l2 = NULL;

int (*vd_open)(const char *, int, ...);
int (*vd_close)(int);
int (*vd_dup)(int);
int (*vd_ioctl)(int, unsigned long int, ...);
ssize_t (*vd_read)(int, void *, size_t);
void * (*vd_mmap)(void *, size_t, int, int, int, int64_t);
int (*vd_munmap)(void *, size_t);


/* >>>>>>> MULTI-CAMERA SUPPORT >>>>> */

#define CLEAR(x) memset (&(x), 0, sizeof (x))

typedef enum {
	IO_METHOD_READ,
	IO_METHOD_MMAP,
	IO_METHOD_USERPTR,
} io_method;

struct buffer {
	void *  start;
	size_t  length;
};

struct camInfo_t {
	unsigned int isOpen;
	unsigned int devNum;
	int	fileDesc;
	unsigned int bmWidth, bmHeight;
	
	io_method ioMethod;
	int pixelformat;
	struct buffer *buffers;
	unsigned int nBuffers;

	struct v4l2_buffer vBuf;
	void *inBuffer;
	unsigned long inBufferSize;
	
	void *sqBuffer;
	unsigned long sqBufferBytes;
	unsigned long sqPixels;

	unsigned long frameCount;
} camInfo[10];

typedef struct camInfo_t *camPtr;

static char * videoDevName0 = "/dev/video0";

struct v4l2_buffer tmpVBuf;


/* >>>>>>>> FUNCTION PROTOTYPES >>>>>>>> */

/* LIBRARY CONSTRUCTOR/DESCTRUCTOR */
void __attribute__ ((constructor)) libCon(void);
void __attribute__ ((destructor)) libDes(void);

/* SQUEAK INTERFACE */
sqInt CameraGetParam(int camNum, int paramNum);
sqInt CameraGetFrame(int camNum, unsigned char* buf, int pixelCount);
sqInt CameraExtent(int camNum);
char* CameraName(int camNum);
void CameraClose(int camNum);
sqInt CameraOpen(int camNum, int frameWidth, int frameHeight);


/* ========================================================= */
/* ========================================================= */
/* ========================================================= */

/* >>>>>>>>>>> UTILITY */

inline int   camIsOpen(camPtr cam) { return ( cam->isOpen); }
inline int camIsClosed(camPtr cam) { return (!cam->isOpen); }


static void 
vBufReset(struct v4l2_buffer *buf)
{
	CLEAR (*buf);
	buf->type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	buf->memory = V4L2_MEMORY_MMAP;
}


/* >>>>>>>>>>> LIB CONSTRUCTOR/DESTRUCTOR */

void __attribute__ ((constructor)) 
libCon(void)
{
	int devNum;
	camPtr cam;

	vd_open = open;
	vd_close = close;
	vd_dup = dup;
	vd_ioctl = ioctl;
	vd_read = read;
	vd_mmap = mmap;
	vd_munmap = munmap;

	/* Use libv4l2: use if available... */
	
	hLibv4l2 = dlopen("libv4l2.so.0", RTLD_LAZY);
	if (hLibv4l2) {
		vd_open = dlsym(hLibv4l2, "v4l2_open");
		vd_close = dlsym(hLibv4l2, "v4l2_close");
		vd_dup = dlsym(hLibv4l2, "v4l2_dup");
		vd_ioctl = dlsym(hLibv4l2, "v4l2_ioctl");
		vd_read = dlsym(hLibv4l2, "v4l2_read");
		vd_mmap = dlsym(hLibv4l2, "v4l2_mmap");
		vd_munmap = dlsym(hLibv4l2, "v4l2_munmap");
	} 

	/* Init camInfo array... */
	
	for (devNum = 0; devNum < 10; ++devNum) {
	  cam = &camInfo[devNum];

	  CLEAR(*cam);

	  cam->isOpen = false;
	  cam->devNum = devNum;
	  cam->ioMethod = IO_METHOD_MMAP;
	  cam->nBuffers = 2;
	  vBufReset(&(cam->vBuf));
	  /* Pixel format auto selected for ease/speed of conversion */

/*
	  cam->fileDesc = 0;
	  cam->bmWidth = 0;
	  cam->bmHeight = 0;
	  cam->buffers = NULL;
	  cam->nBuffers = 0;
	  cam->vBuf = NULL;
	  cam->pixelformat		= V4L2_PIX_FMT_YUYV;
	  cam->pixelformat		= V4L2_PIX_FMT_RGB24;
	  cam->sqBuffer = 0;
	  cam->sqBufferBytes = 0;
	  cam->sqPixels = 0;
	  cam->frameCount = 0;
*/
  }
}


void __attribute__ ((destructor)) 
libDes(void)
{
  int camNum;
  for (camNum = 1; camNum < 11; ++camNum)
	if (camIsOpen(&camInfo[camNum-1]))
	  CameraClose(camNum);
  
/* 
/ Closing libv4l2 causes a crash, so it must
/ already be closed by this point.
*/
/*  
  if (hLibv4l2) dlclose(hLibv4l2);
*/
}


/* >>>>>>>>>>> PIXEL FORMAT CONVERSION, SQ BUFFER TRANSFER */

/* YUV CONVERSION:
/
/  from: palettes.c in VideoForLinuxPlugin
/  from: http://en.wikipedia.org/wiki/YUV422
/
*/

inline unsigned char 
clipPixel(const int pixel) {
    int result;
    result = ((pixel < 0) ? 0 : pixel);
    return (unsigned char) ((result > 255) ? 255: result);
}


inline void 
convertPixelYUV444toARGB32(
			   const unsigned char y,
               const unsigned char u,
               const unsigned char v,
               unsigned char* dest)
{
    const int C = (y - 16) * 298 + 128;
    const int D = u - 128;
    const int E = v - 128;

    /* ARGB */
    dest[0] = clipPixel(( C + 516 * D          ) >> 8);
    dest[1] = clipPixel(( C - 100 * D - 208 * E) >> 8);
    dest[2] = clipPixel(( C           + 409 * E) >> 8);
    dest[3] = 255;
}


inline void 
convertImageYUYVToARGB32 (camPtr cam)
{
	int i;

	const unsigned char* src = cam->inBuffer;
	unsigned char* dst = cam->sqBuffer;
	unsigned long int *pdst;
	unsigned long int pixelCount = cam->sqPixels;

	unsigned char u, y1, v, y2;

	for (i = 0; i < pixelCount; i += 2) {
		y1 = *src++;
		u  = *src++;
		y2 = *src++;
		v  = *src++;

		convertPixelYUV444toARGB32(y1, u, v, dst);
		pdst = (unsigned long *)dst;
		dst += 4;

		if (y2 == y1)
		  *(unsigned long *)dst = *pdst;
		else
		  convertPixelYUV444toARGB32(y2, u, v, dst);
		
		dst += 4;
	}
}
/* <<<<<<<<< YUV CONVERSION <<<<<<<< */


static void 
convertImageRGB24toARGB32 (camPtr cam)
{
	unsigned char 	  *src = cam->inBuffer;
	unsigned long int *dst = cam->sqBuffer;
	unsigned long int pixelCount = cam->sqPixels;
	unsigned long int pixel;
	int i;

	if (0 == dst) return;

	for ( i = 0; i < pixelCount; i++) {
		pixel = 0xFF000000 | (*src++ << 16);
		pixel = pixel | (*src++ << 8);
		*dst++  = pixel | *src++;
	}
}


static void 
convertImageRGB444toARGB32 (camPtr cam)
{
	unsigned char 	  *src = cam->inBuffer;
	unsigned long int *dst = cam->sqBuffer;
	unsigned long int pixelCount = cam->sqPixels;
	unsigned long int r,g,b,pixel;
	int i;

	if (0 == dst) return;

	/* Byte0: (g)ggg(b)bbb, Byte1: xxxx(r)rrr */

	for ( i = 0; i < pixelCount; i++) {
	  r = *src << 4;
	  g = *src++ & 0xF0;
	  b = (*src++ & 0x0F) << 4;
	  pixel = 0xFF000000;
	  pixel |= (r << 16);
	  pixel |= (g <<  8);
	  pixel |= b;
	  *dst++ = pixel;
	}
}


static void 
convertImageRGB565toARGB32 (camPtr cam)
{
	unsigned char 	  *src = cam->inBuffer;
	unsigned long int *dst = cam->sqBuffer;
	unsigned long int pixelCount = cam->sqPixels;
	unsigned long int r,g,b,pixel;
	int i;

	if (0 == dst) return;

	/* Byte0: ggg(r)rrrr, Byte1: (b)bbbb(g)gg */

	for ( i = 0; i < pixelCount; i++) {
	  r = (*src & 0x1F) << 3;
	  g = (*src++ & 0xE0) >> 5;
	  g |= (*src & 0x07) << 5;
	  b = *src++ & 0xF8;
	  pixel = 0xFF000000;
	  pixel |= (b << 16);
	  pixel |= (g <<  8);
	  pixel |= r;
	  *dst++ = pixel;
	}
}


void
convertImage (camPtr cam)
{
	/* func pts to be used at later date */
  
	if (cam->pixelformat == V4L2_PIX_FMT_YUYV) {
		convertImageYUYVToARGB32 (cam);
		return;
	}

	if (cam->pixelformat == V4L2_PIX_FMT_RGB565) {
		convertImageRGB565toARGB32 (cam);
		return;
	}
	
	if (cam->pixelformat == V4L2_PIX_FMT_RGB444) {
		convertImageRGB444toARGB32 (cam);
		return;
	}
	
	if (cam->pixelformat == V4L2_PIX_FMT_RGB24) {
		convertImageRGB24toARGB32 (cam);
		return;
	}
}


/* >>>>>>>>>>> V4L ACCESS */

static int 
xioctl (camPtr cam, int request, void * arg) 
{
	int r;
	do r = vd_ioctl (cam->fileDesc, request, arg);
	  while (-1 == r && EINTR == errno);
	return (0 == r);
}


inline static int
queueBuffer(camPtr cam, struct v4l2_buffer *bufPtr)
{
	return xioctl (cam, VIDIOC_QBUF, bufPtr);
}


inline static int
dequeueBuffer(camPtr cam, struct v4l2_buffer *bufPtr)
{
	return xioctl (cam, VIDIOC_DQBUF, bufPtr);
}


inline static int 
read_frame (camPtr cam) 
{
	struct v4l2_buffer *bufPtr = &(cam->vBuf);
	
	cam->frameCount += 1;
	
	vBufReset(bufPtr);
	
	if (!dequeueBuffer(cam, bufPtr)) {
		switch (errno) {
			case EAGAIN:
			case EIO:
				return false;
			default:
				return false;
		}
	}
/* Not convinced this check is needed...
	if (bufPtr->index < cam->nBuffers)
*/
	/* Quickly copy incoming frame and requeue immediately */
	memcpy(cam->inBuffer, cam->buffers[bufPtr->index].start, cam->inBufferSize);
	queueBuffer(cam, bufPtr);
	/* Conversion not triggered here, see comment on CameraGetFrame() */

	return true;
}


static 
int 
getFrame(camPtr cam) 
{
	int fd = cam->fileDesc;
	unsigned int retry;
	fd_set fds;
	struct timeval tv;
	int r;

	retry = 1;
	while (retry-- > 0) {
		FD_ZERO (&fds);
		FD_SET (fd, &fds);

		/* Timeout. */
		tv.tv_sec = 0;
		tv.tv_usec = 20000;

		errno = 0;
		if (-1 == (r = select (fd + 1, &fds, NULL, NULL, &tv))) {
			/* try again on EINTR */
			if ((EINTR == errno) | (EAGAIN == errno))
				continue;
			return false;
		}

		if (0 == r)
		  return false;
		
		if (FD_ISSET(fd, &fds))
		  return read_frame (cam);

		return false;
	}
	
	return false;
}


static int 
stream_off (camPtr cam) 
{
	enum v4l2_buf_type streamType = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	return xioctl (cam, VIDIOC_STREAMOFF, &streamType);
}


static int 
stream_on (camPtr cam) 
{
	enum v4l2_buf_type streamType = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	return xioctl (cam, VIDIOC_STREAMON, &streamType);
}


static int 
uninit_device (camPtr cam) 
{
	unsigned int i;

	if (cam->buffers)
	  for (i = 0; i < cam->nBuffers; ++i)
		  if (vd_munmap (cam->buffers[i].start, cam->buffers[i].length))
			  return false;

	free (cam->buffers);
	free (cam->inBuffer);
	
	return true;
}


static int 
queueAllBuffers (camPtr cam) 
{
	struct v4l2_buffer *bufPtr = &(cam->vBuf);
	
	vBufReset(bufPtr);
	for (bufPtr->index = 0; bufPtr->index < cam->nBuffers; (bufPtr->index)++)
		if (!queueBuffer(cam, bufPtr)) return false;
	return true;
}


static int 
init_mmap (camPtr cam) 
{
	struct v4l2_buffer *bufPtr = &tmpVBuf;
	struct v4l2_requestbuffers req;
	
	CLEAR (req);
	req.count	= cam->nBuffers;
	req.type	= V4L2_BUF_TYPE_VIDEO_CAPTURE;
	req.memory	= V4L2_MEMORY_MMAP;

	if (!xioctl(cam, VIDIOC_REQBUFS, &req)) return false;
/* Left in for debugging >>>
	{
		if (EINVAL == errno) {
			return false;
		} else {
			return false;
		}
	}
<<< */

	if (req.count < cam->nBuffers) return false;
	if (cam->nBuffers < req.count) 
		printf("Excess Buffers: %i\n", req.count);

	if (!(cam->buffers = calloc (req.count, sizeof (struct buffer))))
		return false;

    /* we have at least as many buffers as requested; save that actual number for uninit_map later */
    cam->nBuffers = req.count;
    
	vBufReset(bufPtr);
	for (bufPtr->index = 0; bufPtr->index < /* req.count */ cam->nBuffers; bufPtr->index++) {

		if (!xioctl(cam, VIDIOC_QUERYBUF, bufPtr)) return false;
		
		cam->buffers[bufPtr->index].length = bufPtr->length;
		cam->buffers[bufPtr->index].start  = vd_mmap (
						  NULL /* start anywhere */,
						  bufPtr->length,
						  PROT_READ | PROT_WRITE /* required */,
						  MAP_SHARED /* recommended */,
						  cam->fileDesc,
						  bufPtr->m.offset);

		if (MAP_FAILED == cam->buffers[bufPtr->index].start) return false;
	}

	return true;
}


static int
set_format (camPtr cam, struct v4l2_format *fmt, int pixelformat, int w, int h)
{
	fmt->type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	fmt->fmt.pix.width	= w;
	fmt->fmt.pix.height	= h;
	fmt->fmt.pix.pixelformat = pixelformat;
	fmt->fmt.pix.field	= V4L2_FIELD_NONE;
	if (!xioctl (cam, VIDIOC_S_FMT, fmt)) return false;

	/* Note VIDIOC_S_FMT may change width and height. */
	if ((w != fmt->fmt.pix.width) | (h != fmt->fmt.pix.height)
			| (fmt->fmt.pix.pixelformat != pixelformat))
		return false;

	cam->pixelformat = pixelformat;
	
	return true;
}


static int 
init_device (camPtr cam, int w, int h) 
{
	struct v4l2_capability cap;
	struct v4l2_cropcap cropcap;
	struct v4l2_crop crop;
	struct v4l2_format fmt;
	int bpp;
	unsigned int min;

	if (!xioctl (cam, VIDIOC_QUERYCAP, &cap)) return false;
/* left in for debugging >>>
	{
		if (EINVAL == errno) {
			return -1;
		} else {
			return -1;
		}
	}
<<< */

	if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE)) return false;
	if (!(cap.capabilities & V4L2_CAP_STREAMING)) return false;

	/* Select video input, video standard and tune here. */

	CLEAR (cropcap);
	cropcap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

	if (xioctl (cam, VIDIOC_CROPCAP, &cropcap)) {
		crop.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		crop.c = cropcap.defrect; /* reset to default */
		if (!xioctl (cam, VIDIOC_S_CROP, &crop)) {
			if (EINVAL == errno) {
				/* Cropping not supported (ignored) */
			} else {
				/* Errors ignored. */
			}
		}
	} else {
		/* Errors ignored. */
	}

	CLEAR (fmt);
	/* The order of preference of formats... */
	if (!set_format(cam, &fmt, V4L2_PIX_FMT_RGB24, w, h))
	  if (!set_format(cam, &fmt, V4L2_PIX_FMT_YUYV, w, h))
		if (!set_format(cam, &fmt, V4L2_PIX_FMT_RGB565, w, h))
		  if (!set_format(cam, &fmt, V4L2_PIX_FMT_RGB444, w, h))
			return false;
		
	/* For reference:
		V4L2_PIX_FMT_RGB24 : 3 bytes == 1 dst pixel
		V4L2_PIX_FMT_RGB565: 2 bytes == 1 dst pixel
		V4L2_PIX_FMT_RGB444: 2 bytes == 1 dst pixel
		V4L2_PIX_FMT_YUYV  : 4 bytes == 2 dst pixels
	*/
	
	switch (fmt.fmt.pix.pixelformat) {
	  case V4L2_PIX_FMT_RGB24: /* printf("V4L2_PIX_FMT_RGB24\n"); */
		bpp = 3; 
		break;
	  case V4L2_PIX_FMT_RGB565: /* printf("V4L2_PIX_FMT_RGB565\n"); */
		bpp = 2; 
		break;
	  case V4L2_PIX_FMT_RGB444: /* printf("V4L2_PIX_FMT_RGB444\n"); */
		bpp = 2;
		break;
	  case V4L2_PIX_FMT_YUYV: /* printf("V4L2_PIX_FMT_YUYV\n"); */
		bpp = 4; 
		break;
	}
	
	/* Buggy driver paranoia >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> */	
	min = fmt.fmt.pix.width * bpp;
	if (fmt.fmt.pix.bytesperline < min) fmt.fmt.pix.bytesperline = min;
	min = fmt.fmt.pix.bytesperline * fmt.fmt.pix.height;
	if (fmt.fmt.pix.sizeimage < min) fmt.fmt.pix.sizeimage = min;
	/* <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */
	
	if (!(cam->inBuffer = calloc (min, 1))) return false;
	cam->inBufferSize = min;
	
	if (!init_mmap(cam)) return false;

	if (!queueAllBuffers(cam)) return false;

	/* cache returned dims */
	cam->bmWidth = fmt.fmt.pix.width;
	cam->bmHeight = fmt.fmt.pix.height;
	cam->sqPixels = cam->bmWidth * cam->bmHeight;
	cam->sqBufferBytes = cam->sqPixels * 4; /* Bytes to tx to Squeak (always RGB32) */

	return true;
}


static int 
close_device (camPtr cam) 
{
	vd_close (cam->fileDesc);
	cam->fileDesc = 0;
	return true;
}


static int 
open_device (camPtr cam) 
{
	char deviceName[12];
	struct stat st;

	strcpy(deviceName, videoDevName0);
	deviceName[10] = cam->devNum + '0';

	if (stat (deviceName, &st)) return false;
	if (!S_ISCHR (st.st_mode)) return false;

	return (-1 != (cam->fileDesc = vd_open (deviceName, O_RDWR /* required */ | O_NONBLOCK, 0)));
}


int 
initCamera(camPtr cam, int w, int h) 
{
    if (!open_device(cam)) return false;

	if (!init_device(cam, w, h)) {
        close_device(cam);
        return false;
    }

    if (!stream_on(cam)) {
        uninit_device(cam);
        close_device(cam);
        return false;
    }

    return true;
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> */
/* >>>>>>>>>>>>>>>>> SCRATCH I/F >>>>>>>>>>>>>>>>> */
/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> */

sqInt 
CameraGetParam(int camNum, int paramNum) 
{
	camPtr cam = &camInfo[camNum-1];
	return false;
}


/*
/ Spec from Scratch protocol...
/
/	  "Copy a camera frame into the given Bitmap. The Bitmap should be for a Form 
/	  of depth 32 that is the same width and height as the current camera frame. 
/	  Fail if the camera is not open or if the bitmap is not the right size. If 
/	  successful, answer the number of frames received from the camera since the 
/	  last call. If this is zero, then there has been no change."
/	
/  This version: 
/	- designed to fail silently
/	- coded so that a future version can skip frames and do so *without* incurring
/	  delays due to conversion.
*/
sqInt 
CameraGetFrame(int camNum, unsigned char* buf, int pixelCount) 
{
#ifdef USE_TEST_PATTERN
	unsigned long f,i;
	unsigned long *d;
#endif

	camPtr cam = &camInfo[camNum-1];
	
	if (camIsClosed(cam)) return 0;
	if (pixelCount != cam->sqPixels) return 0;
	
	cam->sqBuffer = (void *)buf;

#ifdef USE_TEST_PATTERN
printf("%i\n", tstColourIdx);
	switch (tstColourIdx) {
	  case 0:
		f = 0xFFFF0000;
		break;
	  case 1:
		f = 0xFF00FF00;
		break;
	  case 2:
		f = 0xFF0000FF;
		break;
	}
	d = (unsigned long *)buf;
	for (i = 0; i < pixelCount; i++)
	  *d++ = f;
	tstColourIdx = (tstColourIdx == 2 ? 0: tstColourIdx + 1);
	return 1;
#endif

/* OPTION 1: ALL FRAMES, SKIP IMAGE-SIDE, INCUR CONVERSION COST... */

	if (getFrame(cam)) {
	  convertImage (cam);
	  return 1;
	}
	return 0;

	
/* OPTION 2: ONLY LATEST FRAME, AVOIDS CONVERSION OF SKIPPED FRAMES... */

	/* getFrame() buffers & eventually fails leaving the latest/last frame */
/*
	while (getFrame(cam));
	convertImage (cam);
	return 1;
*/

}


sqInt 
CameraExtent(int camNum) 
{
	camPtr cam = &camInfo[camNum-1];
	if (camIsClosed(cam)) return false;
	return (cam->bmWidth << 16) + cam->bmHeight;
}


char* 
CameraName(int camNum) 
{
	camPtr cam = &camInfo[camNum-1];
	if (camIsClosed(cam)) return "camera not open";
	return "default camera";
}


void 
CameraClose(int camNum) 
{
	camPtr cam = &camInfo[camNum-1];
	if (camIsClosed(cam)) return;
	stream_off(cam);
	uninit_device(cam);
	close_device(cam);
	cam->isOpen = false;
}


sqInt 
CameraOpen(int camNum, int frameWidth, int frameHeight) 
{
	camPtr cam = &camInfo[camNum-1];

	if (camIsOpen(cam)) return false;
	if (!initCamera(cam, frameWidth, frameHeight)) return false;
	cam->isOpen = true;
	
	while (!getFrame(cam));

#ifdef USE_TEST_PATTERN
	tstColourIdx = 0;
#endif
	return true;
}

