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

#include "sqVirtualMachine.h"
#include "sqaio.h"
#include "CameraPlugin.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>

#include <getopt.h>

#include <fcntl.h>
#include <unistd.h>
#include <poll.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <dlfcn.h>

#include <asm/types.h>	  /* for videodev2.h */

/* See for example
 * https://www.kernel.org/doc/html/v5.4/media/uapi/v4l/video.html
 */
#include <linux/videodev2.h>


#define true 1
#define false 0

extern struct VirtualMachine *interpreterProxy;

/* >>>>> LIBV4L2 USAGE >>>>>
/
/ Attempting to get best-of-all-worlds so
/ explicitly loading libv4l2 if available
/ to avoid build-time dependency.
/
*/

static void *hLibv4l2 = NULL;

static int (*vd_open)(const char *, int, ...);
static int (*vd_close)(int);
static int (*vd_dup)(int);
static int (*vd_ioctl)(int, unsigned long int, ...);
static ssize_t (*vd_read)(int, void *, size_t);
static void * (*vd_mmap)(void *, size_t, int, int, int, int64_t);
static int (*vd_munmap)(void *, size_t);


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

#define CAMERA_COUNT 4

struct camInfo_t {
	int	fileDesc, pixelformat, semaphoreIndex;
	unsigned int isOpen, devNum, bmWidth, bmHeight, nBuffers;

	io_method ioMethod;
	struct buffer *buffers;

	struct v4l2_buffer vBuf;
	void *inBuffer;
	unsigned long inBufferSize;

	void *sqBuffer;
	unsigned long sqBufferBytes;
	unsigned long sqPixels;

	unsigned long frameCount;
	struct v4l2_capability cap;
	unsigned char mirrorImage;
} camInfo[CAMERA_COUNT];

typedef struct camInfo_t *camPtr;

static char *videoDevName0 = "/dev/video0";

struct v4l2_buffer tmpVBuf;


/* >>>>>>>> FUNCTION PROTOTYPES >>>>>>>> */

/* LIBRARY CONSTRUCTOR/DESCTRUCTOR */
void __attribute__ ((constructor)) libCon(void);
void __attribute__ ((destructor)) libDes(void);


/* ========================================================= */
/* ========================================================= */
/* ========================================================= */

/* >>>>>>>>>>> UTILITY */

static camPtr
camera(int camNum)
{
	return
		camNum >= 1 && camNum <= CAMERA_COUNT
		? camInfo + camNum - 1
		: 0;
}

static inline int   camIsOpen(camPtr cam) { return cam && cam->isOpen; }
static inline int camIsClosed(camPtr cam) { return !cam || !cam->isOpen; }


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

	for (devNum = 0; devNum < CAMERA_COUNT; ++devNum) {
	  cam = &camInfo[devNum];

	  CLEAR(*cam);

	  cam->isOpen = false;
	  cam->devNum = devNum;
	  cam->ioMethod = IO_METHOD_MMAP;
	  cam->nBuffers = 2;
	  cam->frameCount = 0;
	  cam->mirrorImage = 0;
	  cam->semaphoreIndex = -1;
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
*/
  }
}


void __attribute__ ((destructor))
libDes(void)
{
  sqInt camNum;
  for (camNum = 1; camNum < CAMERA_COUNT; ++camNum)
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

static inline uint8_t
clipPixel(const int pixel) {
    int result;
    result = ((pixel < 0) ? 0 : pixel);
    return (uint8_t) ((result > 255) ? 255: result);
}


static inline void
convertPixelYUV444toARGB32(
			   const uint8_t y,
               const uint8_t u,
               const uint8_t v,
               uint8_t* dest)
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


static inline void
convertImageYUYVToARGB32 (camPtr cam)
{
	size_t i;
	const uint8_t *src = cam->inBuffer;
	uint8_t *dst = cam->sqBuffer;
	uint32_t pixelCount = cam->sqPixels;

	for (i = 0; i < pixelCount; i += 2) {
		uint8_t y1 = src[0];
		uint8_t u  = src[1];
		uint8_t y2 = src[2];
		uint8_t v  = src[3];

		src += 4;

		convertPixelYUV444toARGB32(y1, u, v, dst);
		dst += 4;

		if (y2 == y1)
		  *dst = *(uint32_t *)(dst - 4);
		else
		  convertPixelYUV444toARGB32(y2, u, v, dst);

		dst += 4;
	}
}
/* <<<<<<<<< YUV CONVERSION <<<<<<<< */


static void
convertImageRGB24toARGB32 (camPtr cam)
{
	uint8_t  *src = cam->inBuffer;
	uint32_t *dst = cam->sqBuffer;
	uint32_t pixelCount = cam->sqPixels;

	if (!dst)
		return;

	while (--pixelCount >= 0) {
		*dst++ = 0xFF000000 | (src[0] << 16) | (src[1] << 8) | src[2];
		src += 3;
	}
}


static void
convertImageRGB444toARGB32 (camPtr cam)
{
	uint8_t  *src = cam->inBuffer;
	uint32_t *dst = cam->sqBuffer;
	uint32_t pixelCount = cam->sqPixels;
	uint32_t r,g,b;

	if (!dst)
		return;

	/* Byte0: (g)ggg(b)bbb, Byte1: xxxx(r)rrr */

	while (--pixelCount >= 0) {
	  r = *src << 4;
	  g = *src++ & 0xF0;
	  b = (*src++ & 0x0F) << 4;
	  *dst++ = 0xFF000000 | (r << 16) | (g <<  8) | b;
	}
}


static void
convertImageRGB565toARGB32 (camPtr cam)
{
	uint8_t  *src = cam->inBuffer;
	uint32_t *dst = cam->sqBuffer;
	uint32_t pixelCount = cam->sqPixels;
	uint32_t r,g,b,pixel;
	size_t i;

	if (!dst)
		return;

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


static inline void
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
	return 0 == r;
}


static inline int
queueBuffer(camPtr cam, struct v4l2_buffer *bufPtr)
{
	return xioctl (cam, VIDIOC_QBUF, bufPtr);
}


static inline int
dequeueBuffer(camPtr cam, struct v4l2_buffer *bufPtr)
{
	return xioctl (cam, VIDIOC_DQBUF, bufPtr);
}


/* See for example
 * https://www.kernel.org/doc/html/v5.4/media/uapi/v4l/io.html
 */
static inline int
read_frame (camPtr cam)
{
	struct v4l2_buffer *bufPtr = &(cam->vBuf);

	cam->frameCount += 1;

	vBufReset(bufPtr);

	FPRINTF((stderr, "read_frame %p\n", cam));
	if (!dequeueBuffer(cam, bufPtr)) {
		FPRINTF((stderr, "dequeueBuffer %p %p FAILED!!\n", cam, bufPtr));
		return false;
	}

	/* Quickly copy incoming frame and requeue immediately */
	memcpy(cam->inBuffer, cam->buffers[bufPtr->index].start, cam->inBufferSize);
	queueBuffer(cam, bufPtr);
	FPRINTF((stderr, "read_frame %p done!\n", cam));
	/* Conversion not triggered here, see comment on CameraGetFrame() */
	return true;
}


#define USE_POLL 1
static int
cameraReadable(camPtr cam)
{
#if USE_POLL
	struct pollfd fd;

	fd.fd = cam->fileDesc;
	fd.events = POLLIN;
	fd.revents = 0;

# ifdef AIO_DEBUG
	if (poll(&fd, 1, 0) < 0)
		perror("camera readable: poll(&fd, 1, 0)");
# else
	poll(&fd, 1, 0);
# endif
	return fd.revents & POLLIN;
#else
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
		if (-1 == (r = select(fd + 1, &fds, NULL, NULL, &tv))) {
			/* try again on EINTR */
			if ((EINTR == errno) | (EAGAIN == errno))
				continue;
			return false;
		}

		return r && FD_ISSET(fd, &fds);
	}
#endif
	return false;
}

static inline int
getFrame(camPtr cam)
{
	return cameraReadable(cam)
		? read_frame (cam)
		: false;
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
	size_t i;

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
		if (!queueBuffer(cam, bufPtr))
			return false;
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

	if (!xioctl(cam, VIDIOC_REQBUFS, &req))
		return false;
/* Left in for debugging >>>
	{
		if (EINVAL == errno) {
			return false;
		} else {
			return false;
		}
	}
<<< */
/* what? this is set above..
	if (req.count < cam->nBuffers)
		return false;
	if (cam->nBuffers < req.count)
		printf("Excess Buffers: %i\n", req.count);
*/
	if (!(cam->buffers = calloc (req.count, sizeof (struct buffer))))
		return false;

    /* we have at least as many buffers as requested; save that actual number for uninit_map later */
    cam->nBuffers = req.count;

	vBufReset(bufPtr);
	for (bufPtr->index = 0; bufPtr->index < /* req.count */ cam->nBuffers; bufPtr->index++) {

		if (!xioctl(cam, VIDIOC_QUERYBUF, bufPtr))
			return false;

		cam->buffers[bufPtr->index].length = bufPtr->length;
		cam->buffers[bufPtr->index].start  = vd_mmap (
						  NULL /* start anywhere */,
						  bufPtr->length,
						  PROT_READ | PROT_WRITE /* required */,
						  MAP_SHARED /* recommended */,
						  cam->fileDesc,
						  bufPtr->m.offset);

		if (MAP_FAILED == cam->buffers[bufPtr->index].start)
			return false;
	}

	return true;
}


/* See for example
 * https://www.kernel.org/doc/html/v5.4/media/uapi/v4l/format.html
 */
static int
set_format (camPtr cam, struct v4l2_format *fmt, int pixelformat, int w, int h)
{
	fmt->type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	fmt->fmt.pix.width	= w;
	fmt->fmt.pix.height	= h;
	fmt->fmt.pix.pixelformat = pixelformat;
	fmt->fmt.pix.field	= V4L2_FIELD_NONE;
	if (!xioctl (cam, VIDIOC_S_FMT, fmt))
		return false;

	/* Note VIDIOC_S_FMT may change width and height. */
	if (w != fmt->fmt.pix.width
	 || h != fmt->fmt.pix.height
	 || fmt->fmt.pix.pixelformat != pixelformat)
		return false;

	cam->pixelformat = pixelformat;

	return true;
}


static int
init_device (camPtr cam, int w, int h)
{
	struct v4l2_cropcap cropcap;
	struct v4l2_format fmt;
	int bpp;
	unsigned int min;

	if (!xioctl (cam, VIDIOC_QUERYCAP, &cam->cap))
		return false;

	if (!(cam->cap.capabilities & V4L2_CAP_VIDEO_CAPTURE)
	 || !(cam->cap.capabilities & V4L2_CAP_STREAMING))
		return false;

	/* Select video input, video standard and tune here. */

	CLEAR (cropcap);
	cropcap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

	if (xioctl (cam, VIDIOC_CROPCAP, &cropcap)) {
		struct v4l2_crop crop;
		crop.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		crop.c = cropcap.defrect; /* reset to default */
		/* If cropping is not supported , the lack is ignored. */
		(void)xioctl (cam, VIDIOC_S_CROP, &crop);
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

	if (!(cam->inBuffer = calloc (min, 1)))
		return false;
	cam->inBufferSize = min;

	if (!init_mmap(cam))
		return false;

	if (!queueAllBuffers(cam))
		return false;

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

	if (stat (deviceName, &st))
		return false;
	if (!S_ISCHR (st.st_mode))
		return false;

	return (-1 != (cam->fileDesc = vd_open (deviceName, O_RDWR /* required */ | O_NONBLOCK, 0)));
}


int
initCamera(camPtr cam, int w, int h)
{
    if (!open_device(cam))
		return false;

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


sqInt
CameraGetParam(sqInt cameraNum, sqInt paramNum)
{
	camPtr cam = camera(camNum);

	if (!cam)
		return -PrimErrNotFound;
	switch (paramNum) {
	case FrameCount:	return cam->frameCount;
	case FrameByteSize:	return cam->width * cam->height * 4;
	case MirrorImage:	return cam->mirrorImage;
	}
	return -PrimErrBadArgument;
}

sqInt
CameraSetParam(sqInt cameraNum, sqInt paramNum, sqInt paramValue)
{
	camPtr cam = camera(camNum);

	if (!cam)
		return -PrimErrNotFound;
	if (paramNum == MirrorImage) {
		sqInt oldValue = cam->mirrorImage;
		if (1) // For now
			return PrimErrUnsupported;
		cam->mirrorImage = paramValue;
		return oldValue;
	}
	return -PrimErrBadArgument;
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
CameraGetFrame(sqInt camNum, unsigned char* buf, sqInt pixelCount)
{
	int ourCount;
	camPtr cam = camera(camNum);

	FPRINTF((stderr, "CameraGetFrame %ld %s %ld=%ld (%d,%ld)\n",
			camNum, camIsClosed(cam) ? "closed" : "open",
			pixelCount, cam->sqPixels, cam->semaphoreIndex, cam->frameCount));
	if (camIsClosed(cam))
		return -1;
	if (pixelCount != cam->sqPixels)
		return -1;

	cam->sqBuffer = (void *)buf;

	if (cam->semaphoreIndex > 0) {
		ourCount = cam->frameCount;
		cam->frameCount = 0;
		convertImage (cam);
		FPRINTF((stderr, "CameraGetFrame v0 done %d\n", ourCount));
		return ourCount;
	}
#if 0 /* OPTION 1: ALL FRAMES, SKIP IMAGE-SIDE, INCUR CONVERSION COST... */
	if (getFrame(cam)) {
		ourCount = cam->frameCount;
		cam->frameCount = 0;
		convertImage (cam);
		FPRINTF((stderr, "CameraGetFrame v1 done %d\n", ourCount));
		return ourCount;
	}
	return 0;
#else /* OPTION 2: ONLY LATEST FRAME, AVOIDS CONVERSION OF SKIPPED FRAMES... */
	while (getFrame(cam));
	ourCount = cam->frameCount;
	cam->frameCount = 0;
	convertImage (cam);
	FPRINTF((stderr, "CameraGetFrame v2 done %d\n", ourCount));
	return ourCount;
#endif
}


sqInt
CameraExtent(sqInt camNum)
{
	camPtr cam = camera(camNum);

	return camIsOpen(cam)
		? (cam->bmWidth << 16) + cam->bmHeight
		: 0;
}


char*
CameraName(sqInt camNum)
{
	camPtr cam = camera(camNum);
	return camIsOpen(cam)
		? (char *)&cam->cap.card[0]
		: 0;
}

char *
CameraUID(sqInt camNum)
{
	camPtr cam = camera(camNum);
	return camIsOpen(cam)
		? (char *)&cam->cap.bus_info[0]
		: 0;
}


void
CameraClose(sqInt camNum)
{
	camPtr cam = camera(camNum);
	if (camIsClosed(cam))
		return;
	aioDisable(cam->fileDesc);
	stream_off(cam);
	uninit_device(cam);
	close_device(cam);
	cam->isOpen = false;
}


sqInt
CameraOpen(sqInt camNum, sqInt frameWidth, sqInt frameHeight)
{
	camPtr cam = camera(camNum);

	CameraClose(camNum);
	if (!initCamera(cam, frameWidth, frameHeight))
		return false;
	cam->isOpen = true;

	return true;
}

static void
cameraHandler(int fd, camPtr cam, int flags)
{
	FPRINTF((stderr, "cameraHandler %d %p %x (%d)\n",
			fd, cam, flags, cam->semaphoreIndex));
	if ((flags & AIO_R)
	 && cam->semaphoreIndex > 0) {
		read_frame(cam);
		interpreterProxy->signalSemaphoreWithIndex(cam->semaphoreIndex);
	}
}


sqInt
CameraGetSemaphore(sqInt camNum)
{
	camPtr cam = camera(camNum);

	return cam && cam->semaphoreIndex > 0
		? cam->semaphoreIndex
		: 0;
}

// primSetCameraBuffers ensures buffers are pinned non-pointer objs if non-null
sqInt
CameraSetFrameBuffers(sqInt cameraNum, sqInt bufferA, sqInt bufferB)
{
	// For now
	return PrimErrUnsupported;
}

// If double-buffering is in effect (set via CameraSetFrameBuffers) answer which
// buffer contains the freshest data, either A (1) or B (2). If no buffer has
// been filled yet, answer nil.  Otherwise fail with an appropriate error code.
sqInt
CameraGetLatestBufferIndex(sqInt camNum)
{
	// For now
	return PrimErrUnsupported;
}


/* Alas, see for example
 * https://www.kernel.org/doc/html/v5.4/media/uapi/v4l/async.html
 * "3.5. Asynchronous I/O	This method is not defined yet."
 * So to support CameraSetSemaphore without V4L2_CAP_ASYNCIO
 * we would have to spawn a thread to do blocking reads.
 *
 * But change is on its way.  This is from the 5.9 documentation:
 * https://www.kernel.org/doc/html/v5.9/driver-api/media/v4l2-async.html
 * 1.22. V4L2 async kAPI
 */
sqInt
CameraSetSemaphore(sqInt camNum, sqInt semaphoreIndex)
{
	camPtr cam = camera(camNum);

	if (!camIsOpen(cam))
		return PrimErrBadIndex;
	if (!(cam->cap.capabilities & V4L2_CAP_ASYNCIO))
		return PrimErrUnsupported;
	aioEnable(cam->fileDesc, cam, 0);
	aioHandle(cam->fileDesc, (void (*)(int,void *,int))cameraHandler, AIO_RX);
	cam->semaphoreIndex = semaphoreIndex;
	return 0;
}

#ifdef AIO_DEBUG
static char *(*oldHandlerChain)(aioHandler h);
static char *
cameraHandleName(aioHandler h)
{
	if (h == (void (*)(int,void *,int))cameraHandler)
		return "cameraHandler";
	if (oldHandlerChain)
		return oldHandlerChain(h);
	return 0;
}
#endif


/*** module initialisation/shutdown ***/


sqInt
cameraInit(void)
{
#ifdef AIO_DEBUG
	oldHandlerChain = handlerNameChain;
	handlerNameChain = cameraHandleName;
#endif
  return 1;
}

sqInt
cameraShutdown(void)
{
#ifdef AIO_DEBUG
	if (handlerNameChain == cameraHandleName)
		handlerNameChain = oldHandlerChain;
#endif
	libDes();
	return 1;
}
