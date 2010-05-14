/*
 *  V4L2 for Scratch (Derek O'Connell, 2009)
 *
 *  This code can be used and distributed without restrictions.
 *
 */

#include "sq.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <getopt.h>   /* getopt_long() */

#include <fcntl.h>    /* low-level i/o */
#include <unistd.h>
#include <errno.h>
#include <malloc.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <dlfcn.h>

#include <asm/types.h>	  /* for videodev2.h */

#include <linux/videodev2.h>

/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> */
/*
#define USE_LIBV4L2x
#ifdef USE_LIBV4L2
#include <libv4l2.h>
#endif
*/

void *hLibv4l2 = NULL;

int (*vd_open)(const char *, int, ...);
int (*vd_close)(int);
int (*vd_dup)(int);
int (*vd_ioctl)(int, unsigned long int, ...);
ssize_t (*vd_read)(int, void *, size_t);
void * (*vd_mmap)(void *, size_t, int, int, int, int64_t);
int (*vd_munmap)(void *, size_t);

/* <<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */


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
	int devNum;
	int	fileDesc;
	int bmWidth, bmHeight;
	
	io_method ioMethod;
	int pixelformat;
	struct buffer *	buffers;
	unsigned int nBuffers;

	struct v4l2_buffer read_buf;

	void *sqBuffer;
	long sqBufferBytes;
	long sqPixels;

	long frameCount;
} camInfo[10];

typedef struct camInfo_t *camPtr;

static char * videoDevName0 = "/dev/video0";

/* ================================== FUNCTION PROTOTYPES */

/* LIBRARY CONSTRUCTOR/DESCTRUCTOR */

void __attribute__ ((constructor)) libCon(void);
void __attribute__ ((destructor)) libDes(void);


/* UTILITY */

inline int camIsOpen(  camPtr cam) { return (-1 != cam->fileDesc); }
inline int camIsClosed(camPtr cam) { return (-1 == cam->fileDesc); }


/* V4L ACCESS */


/* SQUEAK INTERFACE */

sqInt CameraGetParam(int camNum, int paramNum);
sqInt CameraGetFrame(int camNum, unsigned char* buf, int pixelCount);
sqInt CameraExtent(int camNum);
char* CameraName(int camNum);
void CameraClose(int camNum);
sqInt CameraOpen(int camNum, int frameWidth, int frameHeight);


/* ================================== ??? */


/* LIBRARY CONSTRUCTOR/DESCTRUCTOR */

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

/*  printf("libv4l2: use if available...");
*/
hLibv4l2 = dlopen("libv4l2.so", RTLD_LAZY);
  if (hLibv4l2) 
  {
/*	  printf("yay!\n");
*/  
	  vd_open	= dlsym(hLibv4l2, "v4l2_open");
	  vd_close 	= dlsym(hLibv4l2, "v4l2_close");
	  vd_dup 	= dlsym(hLibv4l2, "v4l2_dup");
	  vd_ioctl 	= dlsym(hLibv4l2, "v4l2_ioctl");
	  vd_read 	= dlsym(hLibv4l2, "v4l2_read");
	  vd_mmap 	= dlsym(hLibv4l2, "v4l2_mmap");
	  vd_munmap = dlsym(hLibv4l2, "v4l2_munmap");
  } else {
/*	  printf("nay, %s\n", dlerror());
*/
  }

  for (devNum = 0; devNum < 10; ++devNum) {
	cam = &camInfo[devNum];

	CLEAR(*cam);

	cam->devNum				= devNum;
	cam->fileDesc			= -1;
	cam->ioMethod			= IO_METHOD_MMAP;
	cam->read_buf.type		= V4L2_BUF_TYPE_VIDEO_CAPTURE;
	cam->read_buf.memory	= V4L2_MEMORY_MMAP;
	cam->nBuffers 			= 1;

/*	Pixel format now auto selected according to ease/speed of conversion
	cam->pixelformat		= V4L2_PIX_FMT_YUYV;
	cam->pixelformat		= V4L2_PIX_FMT_RGB24;
*/

/*
	cam->fileDesc = 0;
	cam->bmWidth = 0;
	cam->bmHeight = 0;
	cam->buffers = NULL;
	cam->nBuffers = 0;
	cam->read_buf = NULL;
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
	  CameraClose(camNum);
/*  
  if (hLibv4l2)
	  dlclose(hLibv4l2);
*/
}


/* V4L ACCESS */

static int 
xioctl (camPtr cam, int request, void * arg) 
{
	int r;

	do r = vd_ioctl (cam->fileDesc, request, arg);
	  while (-1 == r && EINTR == errno);

	return r;
}


/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  from: palettes.c in VideoForLinuxPlugin
  from: http://en.wikipedia.org/wiki/YUV422

  Originally (here) a quick hack for XO-1 but libv4l
  version worked anyway.
  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> */

inline unsigned char clipPixel(const int pixel) {
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
convertImageYUYVToARGB32 (camPtr cam, int bufIdx)
{
	int i;

	const unsigned char* src = cam->buffers[bufIdx].start;
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

/* <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */

static void 
convertImageRGB24toARGB32 (camPtr cam, int bufIdx) /* const void *src, const void *dst) */
{
	unsigned char 	  *src = cam->buffers[bufIdx].start;
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
convertImageRGB444toARGB32 (camPtr cam, int bufIdx) /* const void *src, const void *dst) */
{
	unsigned char 	  *src = cam->buffers[bufIdx].start;
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
convertImageRGB565toARGB32 (camPtr cam, int bufIdx) /* const void *src, const void *dst) */
{
	unsigned char 	  *src = cam->buffers[bufIdx].start;
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
convertImage (camPtr cam, int bufIdx)
{
	/* func pts to be used at later date */
  
	if (cam->pixelformat == V4L2_PIX_FMT_YUYV) {
		convertImageYUYVToARGB32 (cam, bufIdx);
		return;
	}

	if (cam->pixelformat == V4L2_PIX_FMT_RGB565) {
		convertImageRGB565toARGB32 (cam, bufIdx);
		return;
	}
	
	if (cam->pixelformat == V4L2_PIX_FMT_RGB444) {
		convertImageRGB444toARGB32 (cam, bufIdx);
		return;
	}
	
	if (cam->pixelformat == V4L2_PIX_FMT_RGB24) {
		convertImageRGB24toARGB32 (cam, bufIdx);
		return;
	}
}


static int 
read_frame (camPtr cam) 
{
	struct v4l2_buffer buf;

	cam->frameCount += 1;

	CLEAR (buf);
	buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	buf.memory = V4L2_MEMORY_MMAP;

	if (-1 == xioctl (cam, VIDIOC_DQBUF, &buf)) {
		switch (errno) {
			case EAGAIN:
			case EIO:
				return 0;
			default:
				return -1;
		}
	}

	if (buf.index < cam->nBuffers)
		convertImage (cam, buf.index);

	if (-1 == xioctl (cam, VIDIOC_QBUF, &buf)) return -1;

	return 0;
}


static int 
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
		tv.tv_sec = 1;
		tv.tv_usec = 0;

		r = select (fd + 1, &fds, NULL, NULL, &tv);

		if (-1 == r) {
			if (EINTR == errno)
				continue;

			return -1;
		}

		if (0 == r) return -1;
		if (0 == read_frame (cam)) return 0;

		/* EAGAIN - retry */
	}
}


static int 
stream_off (camPtr cam) 
{
	enum v4l2_buf_type type;
	type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	xioctl (cam, VIDIOC_STREAMOFF, &type);
	return 0;
}


static int 
stream_on (camPtr cam) 
{
	enum v4l2_buf_type type;
	type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	if (-1 == xioctl (cam, VIDIOC_STREAMON, &type)) return -1;
	return 0;
}


static int 
uninit_device (camPtr cam) 
{
	unsigned int i;

	for (i = 0; i < cam->nBuffers; ++i)
		if (-1 == vd_munmap (cam->buffers[i].start, cam->buffers[i].length))
			return -1;

	free (cam->buffers);
	return 0;
}


static int 
queue_buffers (camPtr cam) 
{
	unsigned int i;

	for (i = 0; i < cam->nBuffers; ++i) {
		struct v4l2_buffer buf;

		CLEAR (buf);
		buf.type	= V4L2_BUF_TYPE_VIDEO_CAPTURE;
		buf.memory	= V4L2_MEMORY_MMAP;
		buf.index	= i;

		if (-1 == xioctl (cam, VIDIOC_QBUF, &buf)) return -1;
	}

	return 0;
}


static int 
init_mmap (camPtr cam) 
{
	struct v4l2_requestbuffers req;
	int bufIdx;
	
	CLEAR (req);
	req.count	= cam->nBuffers;
	req.type	= V4L2_BUF_TYPE_VIDEO_CAPTURE;
	req.memory	= V4L2_MEMORY_MMAP;

	if (-1 == xioctl (cam, VIDIOC_REQBUFS, &req)) {
		if (EINVAL == errno) {
			return -1;
		} else {
			return -1;
		}
	}

	if (req.count < 1) return -1;

	cam->buffers = calloc (req.count, sizeof (*(cam->buffers)));
	if (!cam->buffers) return -1;

	for (bufIdx = 0; bufIdx < req.count; ++bufIdx) {
		struct v4l2_buffer buf;

		CLEAR (buf);
		buf.type	= V4L2_BUF_TYPE_VIDEO_CAPTURE;
		buf.memory	= V4L2_MEMORY_MMAP;
		buf.index	= bufIdx;

		if (-1 == xioctl (cam, VIDIOC_QUERYBUF, &buf)) return -1;

		cam->buffers[bufIdx].length = buf.length;
		cam->buffers[bufIdx].start  = vd_mmap (NULL /* start anywhere */,
						  buf.length,
						  PROT_READ | PROT_WRITE /* required */,
						  MAP_SHARED /* recommended */,
						  cam->fileDesc,
						  buf.m.offset);

		if (MAP_FAILED == cam->buffers[bufIdx].start) return -1;
	}

	return 0;
}

static int
set_format (camPtr cam, struct v4l2_format *fmt, int pixelformat, int w, int h)
{
/*
	fmt->fmt.pix.field	= V4L2_FIELD_INTERLACED;
	fmt->fmt.pix.field	= V4L2_FIELD_TOP;
*/

	fmt->type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	fmt->fmt.pix.width	= w;
	fmt->fmt.pix.height	= h;
	fmt->fmt.pix.pixelformat = pixelformat;
	fmt->fmt.pix.field	= V4L2_FIELD_NONE; /* V4L2_FIELD_INTERLACED; */
	if (-1 == xioctl (cam, VIDIOC_S_FMT, fmt)) return -1;

	/* Note VIDIOC_S_FMT may change width and height. */

	if ((w != fmt->fmt.pix.width)  | 
	    (h != fmt->fmt.pix.height) | 
	    (fmt->fmt.pix.pixelformat != pixelformat))
	{
		return -1;
	}

	cam->pixelformat = pixelformat;
	
	return 0;
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

	if (-1 == xioctl (cam, VIDIOC_QUERYCAP, &cap)) {
		if (EINVAL == errno) {
			return -1;
		} else {
			return -1;
		}
	}

	if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE)) return -1;
	if (!(cap.capabilities & V4L2_CAP_STREAMING)) return -1;

	/* Select video input, video standard and tune here. */

	CLEAR (cropcap);
	cropcap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

	if (0 == xioctl (cam, VIDIOC_CROPCAP, &cropcap)) {
		crop.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		crop.c = cropcap.defrect; /* reset to default */

		if (-1 == xioctl (cam, VIDIOC_S_CROP, &crop)) {
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
	if (-1 == set_format(cam, &fmt, V4L2_PIX_FMT_RGB24, w, h))
	  if (-1 == set_format(cam, &fmt, V4L2_PIX_FMT_YUYV, w, h))
		if (-1 == set_format(cam, &fmt, V4L2_PIX_FMT_RGB565, w, h))
		  if (-1 == set_format(cam, &fmt, V4L2_PIX_FMT_RGB444, w, h))
			return -1;
		
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
	
	if (0 > init_mmap(cam)) return -1;
	if (0 > queue_buffers(cam)) return -1;

	/* cache returned dims (make fmt a global?) */
	cam->bmWidth = fmt.fmt.pix.width;
	cam->bmHeight = fmt.fmt.pix.height;
	cam->sqPixels = cam->bmWidth * cam->bmHeight;
	cam->sqBufferBytes = cam->sqPixels * 4; /* Bytes to tx to Squeak (always RGB32) */

	return 0;
}


static int 
close_device (camPtr cam) 
{
	if (-1 == vd_close (cam->fileDesc)) return -1;
	cam->fileDesc = -1;
	return 0;
}


static int 
open_device (camPtr cam) 
{
	char deviceName[12];
	struct stat st;

	strcpy(deviceName, videoDevName0);
	deviceName[10] = cam->devNum + '0';

	if (-1 == stat (deviceName, &st)) return -1;
	if (!S_ISCHR (st.st_mode)) return -1;

	cam->fileDesc = vd_open (deviceName, O_RDWR /* required */ | O_NONBLOCK, 0);

	if (camIsClosed(cam)) return -1;

	return 0;
}


int 
InitCamera(camPtr cam, int w, int h) 
{
    cam->read_buf.type 	= V4L2_BUF_TYPE_VIDEO_CAPTURE;
    cam->read_buf.memory = V4L2_MEMORY_MMAP;
	cam->ioMethod		= IO_METHOD_MMAP;

    if (0 > open_device(cam)) return -1;

    if (0 > init_device(cam, w, h)) {
        close_device(cam);
        return -1;
    }

    if (0 > stream_on(cam)) {
        uninit_device(cam);
        close_device(cam);
        return -1;
    }

    return 0;
}



/* ============================================= SCRATCH I/F ==================================================== */


sqInt 
CameraGetParam(int camNum, int paramNum) 
{
	camPtr cam = &camInfo[camNum-1];
	
	return 0;
}

/*
	"Copy a camera frame into the given Bitmap. The Bitmap should be for a Form 
	of depth 32 that is the same width and height as the current camera frame. 
	Fail if the camera is not open or if the bitmap is not the right size. If 
	successful, answer the number of frames received from the camera since the 
	last call. If this is zero, then there has been no change."
	
	???
*/
sqInt 
CameraGetFrame(int camNum, unsigned char* buf, int pixelCount) 
{
	camPtr cam = &camInfo[camNum-1];
	
	if (camIsClosed(cam)) return false;
	if (pixelCount != cam->sqPixels) return false;
	cam->sqBuffer = (void *)buf;
	if (0 != getFrame(cam)) return 0;
	return 1;
}


sqInt 
CameraExtent(int camNum) 
{
	camPtr cam = &camInfo[camNum-1];
	
	if (camIsClosed(cam)) return 0;
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
}


sqInt 
CameraOpen(int camNum, int frameWidth, int frameHeight) 
{
	camPtr cam = &camInfo[camNum-1];
	
	if (camIsOpen(cam)) return false;
	if (0 != InitCamera(cam, frameWidth, frameHeight)) return false;
	return true;
}

