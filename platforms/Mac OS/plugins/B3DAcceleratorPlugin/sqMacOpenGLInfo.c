/****************************************************************************
*   PROJECT: Squeak 3D accelerator
*   FILE:    sqMacOpenGLInfo.c
*   CONTENT: MacOS specific bindings for OpenGL
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   Andreas.Raab@disney.com
*   RCSID:   $Id: sqMacOpenGLInfo.c 1708 2007-06-10 00:40:04Z johnmci $
*
*   NOTES:
*
*****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
	#include <Carbon/Carbon.h>
	#include <AGL/gl.h>
	#include <AGL/agl.h>

#include "sq.h"
#include "sqVirtualMachine.h"
#include "sqMacUIConstants.h"
int printRendererInfo(void);
int printFormatInfo(AGLPixelFormat info);

/* Verbose level for debugging purposes:
	0 - print NO information ever
	1 - print critical debug errors
	2 - print debug warnings
	3 - print extra information
	4 - print extra warnings
	5 - print information about primitive execution

   10 - print information about each vertex and face
*/
int verboseLevel = 3;
/* define forceFlush if we should fflush() before closing file */
#define forceFlush 1

/* Note: Print this stuff into a file in case we lock up*/
/* Note: Print this stuff into a file in case we lock up*/
#undef DPRINTF3D
# define DPRINTF3D(vLevel, args) if(vLevel <= verboseLevel) {\
	char fileName[DOCUMENT_NAME_SIZE+1]; \
	sqFilenameFromStringOpen(fileName,(sqInt) &"Squeak3D.log", strlen("Squeak3D.log")); \
	FILE *fp = fopen(fileName, "at");\
	if(fp) { fprintf args; if(forceFlush) fflush(fp); fclose(fp); }}

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/

static void PrintBufferModes(GLint v)
{
	if(v & AGL_MONOSCOPIC_BIT)   DPRINTF3D(3,(fp,"            AGL_MONOSCOPIC_BIT\n"));
	if(v & AGL_STEREOSCOPIC_BIT) DPRINTF3D(3,(fp,"            AGL_STEREOSCOPIC_BIT\n"));
	if(v & AGL_SINGLEBUFFER_BIT) DPRINTF3D(3,(fp,"            AGL_SINGLEBUFFER_BIT\n"));
	if(v & AGL_DOUBLEBUFFER_BIT) DPRINTF3D(3,(fp,"            AGL_DOUBLEBUFFER_BIT\n"));
}

static void PrintColorModes(GLint v)
{
	if(v & AGL_RGB8_BIT)         DPRINTF3D(3,(fp,"            AGL_RGB8_BIT\n"));
	if(v & AGL_RGB8_A8_BIT)      DPRINTF3D(3,(fp,"            AGL_RGB8_A8_BIT\n"));
	if(v & AGL_BGR233_BIT)       DPRINTF3D(3,(fp,"            AGL_BGR233_BIT\n"));
	if(v & AGL_BGR233_A8_BIT)    DPRINTF3D(3,(fp,"            AGL_BGR233_A8_BIT\n"));
	if(v & AGL_RGB332_BIT)       DPRINTF3D(3,(fp,"            AGL_RGB332_BIT\n"));
	if(v & AGL_RGB332_A8_BIT)    DPRINTF3D(3,(fp,"            AGL_RGB332_A8_BIT\n"));
	if(v & AGL_RGB444_BIT)       DPRINTF3D(3,(fp,"            AGL_RGB444_BIT\n"));
	if(v & AGL_ARGB4444_BIT)     DPRINTF3D(3,(fp,"            AGL_ARGB4444_BIT\n"));
	if(v & AGL_RGB444_A8_BIT)    DPRINTF3D(3,(fp,"            AGL_RGB444_A8_BIT\n"));
	if(v & AGL_RGB555_BIT)       DPRINTF3D(3,(fp,"            AGL_RGB555_BIT\n"));
	if(v & AGL_ARGB1555_BIT)     DPRINTF3D(3,(fp,"            AGL_ARGB1555_BIT\n"));
	if(v & AGL_RGB555_A8_BIT)    DPRINTF3D(3,(fp,"            AGL_RGB555_A8_BIT\n"));
	if(v & AGL_RGB565_BIT)       DPRINTF3D(3,(fp,"            AGL_RGB565_BIT\n"));
	if(v & AGL_RGB565_A8_BIT)    DPRINTF3D(3,(fp,"            AGL_RGB565_A8_BIT\n"));
	if(v & AGL_RGB888_BIT)       DPRINTF3D(3,(fp,"            AGL_RGB888_BIT\n"));
	if(v & AGL_ARGB8888_BIT)     DPRINTF3D(3,(fp,"            AGL_ARGB8888_BIT\n"));
	if(v & AGL_RGB888_A8_BIT)    DPRINTF3D(3,(fp,"            AGL_RGB888_A8_BIT\n"));
	if(v & AGL_RGB101010_BIT)    DPRINTF3D(3,(fp,"            AGL_RGB101010_BIT\n"));
	if(v & AGL_ARGB2101010_BIT)  DPRINTF3D(3,(fp,"            AGL_ARGB2101010_BIT\n"));
	if(v & AGL_RGB101010_A8_BIT) DPRINTF3D(3,(fp,"            AGL_RGB101010_A8_BIT\n"));
	if(v & AGL_RGB121212_BIT)    DPRINTF3D(3,(fp,"            AGL_RGB121212_BIT\n"));
	if(v & AGL_ARGB12121212_BIT) DPRINTF3D(3,(fp,"            AGL_ARGB12121212_BIT\n"));
	if(v & AGL_RGB161616_BIT)    DPRINTF3D(3,(fp,"            AGL_RGB161616_BIT\n"));
	if(v & AGL_ARGB16161616_BIT) DPRINTF3D(3,(fp,"            AGL_ARGB16161616_BIT\n"));
	if(v & AGL_INDEX8_BIT)       DPRINTF3D(3,(fp,"            AGL_INDEX8_BIT\n"));
	if(v & AGL_INDEX16_BIT)      DPRINTF3D(3,(fp,"            AGL_INDEX16_BIT\n"));
}

static void PrintBitModes(GLint v)
{
	if(v & AGL_0_BIT)            DPRINTF3D(3,(fp,"            AGL_0_BIT\n"));
	if(v & AGL_1_BIT)            DPRINTF3D(3,(fp,"            AGL_1_BIT\n"));
	if(v & AGL_2_BIT)            DPRINTF3D(3,(fp,"            AGL_2_BIT\n"));
	if(v & AGL_3_BIT)            DPRINTF3D(3,(fp,"            AGL_3_BIT\n"));
	if(v & AGL_4_BIT)            DPRINTF3D(3,(fp,"            AGL_4_BIT\n"));
	if(v & AGL_5_BIT)            DPRINTF3D(3,(fp,"            AGL_5_BIT\n"));
	if(v & AGL_6_BIT)            DPRINTF3D(3,(fp,"            AGL_6_BIT\n"));
	if(v & AGL_8_BIT)            DPRINTF3D(3,(fp,"            AGL_8_BIT\n"));
	if(v & AGL_10_BIT)           DPRINTF3D(3,(fp,"            AGL_10_BIT\n"));
	if(v & AGL_12_BIT)           DPRINTF3D(3,(fp,"            AGL_12_BIT\n"));
	if(v & AGL_16_BIT)           DPRINTF3D(3,(fp,"            AGL_16_BIT\n"));
	if(v & AGL_24_BIT)           DPRINTF3D(3,(fp,"            AGL_24_BIT\n"));
	if(v & AGL_32_BIT)           DPRINTF3D(3,(fp,"            AGL_32_BIT\n"));
	if(v & AGL_48_BIT)           DPRINTF3D(3,(fp,"            AGL_48_BIT\n"));
	if(v & AGL_64_BIT)           DPRINTF3D(3,(fp,"            AGL_64_BIT\n"));
	if(v & AGL_96_BIT)           DPRINTF3D(3,(fp,"            AGL_96_BIT\n"));
	if(v & AGL_128_BIT)          DPRINTF3D(3,(fp,"            AGL_128_BIT\n"));
}

static void PrintInfoStats(AGLRendererInfo info)
{
	GLint rv;
	
	aglDescribeRenderer(info, AGL_RENDERER_ID, &rv);
	DPRINTF3D(3,(fp,"        AGL_RENDERER_ID     : 0x%X\n", rv));
	
	aglDescribeRenderer(info, AGL_OFFSCREEN, &rv);
	DPRINTF3D(3,(fp,"        AGL_OFFSCREEN       : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribeRenderer(info, AGL_FULLSCREEN, &rv);
	DPRINTF3D(3,(fp,"        AGL_FULLSCREEN      : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribeRenderer(info, AGL_WINDOW, &rv);
	DPRINTF3D(3,(fp,"        AGL_WINDOW          : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribeRenderer(info, AGL_ACCELERATED, &rv);
	DPRINTF3D(3,(fp,"        AGL_ACCELERATED     : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribeRenderer(info, AGL_ROBUST, &rv);
	DPRINTF3D(3,(fp,"        AGL_ROBUST          : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribeRenderer(info, AGL_BACKING_STORE, &rv);
	DPRINTF3D(3,(fp,"        AGL_BACKING_STORE   : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribeRenderer(info, AGL_MP_SAFE, &rv);
	DPRINTF3D(3,(fp,"        AGL_MP_SAFE         : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribeRenderer(info, AGL_COMPLIANT, &rv);
	DPRINTF3D(3,(fp,"        AGL_COMPLIANT       : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribeRenderer(info, AGL_MULTISCREEN, &rv);
	DPRINTF3D(3,(fp,"        AGL_MULTISCREEN     : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribeRenderer(info, AGL_BUFFER_MODES, &rv);
	DPRINTF3D(3,(fp,"        AGL_BUFFER_MODES    : 0x%X\n", rv));
	PrintBufferModes(rv);
	
	aglDescribeRenderer(info, AGL_MIN_LEVEL, &rv);
	DPRINTF3D(3,(fp,"        AGL_MIN_LEVEL       : %d\n", rv));
	
	aglDescribeRenderer(info, AGL_MAX_LEVEL, &rv);
	DPRINTF3D(3,(fp,"        AGL_MAX_LEVEL       : %d\n", rv));
	
	aglDescribeRenderer(info, AGL_COLOR_MODES, &rv);
	DPRINTF3D(3,(fp,"        AGL_COLOR_MODES     : 0x%X\n", rv));
	PrintColorModes(rv);
	
	aglDescribeRenderer(info, AGL_ACCUM_MODES, &rv);
	DPRINTF3D(3,(fp,"        AGL_ACCUM_MODES     : 0x%X\n", rv));
	PrintColorModes(rv);
	
	aglDescribeRenderer(info, AGL_DEPTH_MODES, &rv);
	DPRINTF3D(3,(fp,"        AGL_DEPTH_MODES     : 0x%X\n", rv));
	PrintBitModes(rv);
	
	aglDescribeRenderer(info, AGL_STENCIL_MODES, &rv);
	DPRINTF3D(3,(fp,"        AGL_STENCIL_MODES   : 0x%X\n", rv));
	PrintBitModes(rv);
	
	aglDescribeRenderer(info, AGL_MAX_AUX_BUFFERS, &rv);
	DPRINTF3D(3,(fp,"        AGL_MAX_AUX_BUFFERS : %d\n", rv));
	
	aglDescribeRenderer(info, AGL_VIDEO_MEMORY, &rv);
	DPRINTF3D(3,(fp,"        AGL_VIDEO_MEMORY    : %d\n", rv));
	
	aglDescribeRenderer(info, AGL_TEXTURE_MEMORY, &rv);
	DPRINTF3D(3,(fp,"        AGL_TEXTURE_MEMORY  : %d\n", rv));
}

static void CheckGetRendererInfo(GDHandle device)
{
	AGLRendererInfo info, head_info;
	GLint inum;

	head_info =  aglQueryRendererInfo(&device, 1);
	if(!head_info)
	{
		DPRINTF3D(3,(fp,"aglQueryRendererInfo : Info Error\n"));
		return;
	}
	
	info = head_info;
	inum = 0;
	while(info)
	{
		DPRINTF3D(3,(fp,"\n    Renderer : %d\n", inum));
		PrintInfoStats(info);
		info = aglNextRendererInfo(info);
		inum++;
	}
	
	aglDestroyRendererInfo(head_info);
}

int printRendererInfo(void)
{
	GLenum   err;
	GDHandle device;
	GLuint   dnum = 0;
	
	device = GetDeviceList();
	while(device)
	{
		DPRINTF3D(3,(fp,"\nDevice : %d\n", dnum));
		CheckGetRendererInfo(device);
		device = GetNextDevice(device);
		dnum++;
	}
		
	err = aglGetError();
	if(err != AGL_NO_ERROR) DPRINTF3D(3,(fp,"aglGetError - %s\n", aglErrorString(err)));

   return 1;
}

int printFormatInfo(AGLPixelFormat info)
{
	GLint rv;

	DPRINTF3D(3, (fp, "\n\nSelected pixel format:\n"));

	aglDescribePixelFormat(info, AGL_RENDERER_ID, &rv);
	DPRINTF3D(3,(fp,"        AGL_RENDERER_ID     : 0x%X\n", rv));
	
	aglDescribePixelFormat(info, AGL_OFFSCREEN, &rv);
	DPRINTF3D(3,(fp,"        AGL_OFFSCREEN       : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribePixelFormat(info, AGL_FULLSCREEN, &rv);
	DPRINTF3D(3,(fp,"        AGL_FULLSCREEN      : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribePixelFormat(info, AGL_WINDOW, &rv);
	DPRINTF3D(3,(fp,"        AGL_WINDOW          : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribePixelFormat(info, AGL_ACCELERATED, &rv);
	DPRINTF3D(3,(fp,"        AGL_ACCELERATED     : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribePixelFormat(info, AGL_ROBUST, &rv);
	DPRINTF3D(3,(fp,"        AGL_ROBUST          : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribePixelFormat(info, AGL_BACKING_STORE, &rv);
	DPRINTF3D(3,(fp,"        AGL_BACKING_STORE   : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribePixelFormat(info, AGL_MP_SAFE, &rv);
	DPRINTF3D(3,(fp,"        AGL_MP_SAFE         : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribePixelFormat(info, AGL_COMPLIANT, &rv);
	DPRINTF3D(3,(fp,"        AGL_COMPLIANT       : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribePixelFormat(info, AGL_MULTISCREEN, &rv);
	DPRINTF3D(3,(fp,"        AGL_MULTISCREEN     : %s\n", (rv ? "GL_TRUE" : "GL_FALSE")));
	
	aglDescribePixelFormat(info, AGL_BUFFER_SIZE, &rv);
	DPRINTF3D(3,(fp,"        AGL_BUFFER_SIZE     : %d\n", rv));
	
	aglDescribePixelFormat(info, AGL_LEVEL, &rv);
	DPRINTF3D(3,(fp,"        AGL_LEVEL           : %d\n", rv));

	aglDescribePixelFormat(info, AGL_PIXEL_SIZE, &rv);
	DPRINTF3D(3,(fp,"        AGL_PIXEL_SIZE      : %d\n", rv));

#if 0
	aglDescribePixelFormat(info, AGL_ACCUM_MODES, &rv);
	DPRINTF3D(3,(fp,"        AGL_ACCUM_MODES     : 0x%X\n", rv));
	PrintColorModes(rv);
#endif	
	aglDescribePixelFormat(info, AGL_DEPTH_SIZE, &rv);
	DPRINTF3D(3,(fp,"        AGL_DEPTH_SIZE      : %d\n", rv));
	
	aglDescribePixelFormat(info, AGL_STENCIL_SIZE, &rv);
	DPRINTF3D(3,(fp,"        AGL_STENCIL_SIZE    : %d\n", rv));
	PrintBitModes(rv);
	
	aglDescribePixelFormat(info, AGL_AUX_BUFFERS, &rv);
	DPRINTF3D(3,(fp,"        AGL_AUX_BUFFERS     : %d\n", rv));
#if 0
	aglDescribePixelFormat(info, AGL_VIDEO_MEMORY, &rv);
	DPRINTF3D(3,(fp,"        AGL_VIDEO_MEMORY    : %d\n", rv));
	
	aglDescribePixelFormat(info, AGL_TEXTURE_MEMORY, &rv);
	DPRINTF3D(3,(fp,"        AGL_TEXTURE_MEMORY  : %d\n", rv));
#endif

#if 0
	aglDescribePixelFormat(pix, AGL_BUFFER_SIZE, &rv);
	DPRINTF3D(3, (fp, "\tAGL_BUFFER_SIZE: %d\n", rv));
	aglDescribePixelFormat(pix, AGL_LEVEL, &rv);
	DPRINTF3D(3, (fp, "\tAGL_LEVEL: %d\n", rv));
	aglDescribePixelFormat(pix, AGL_RGBA, &rv);
	DPRINTF3D(3, (fp, "\tAGL_RGBA: %s\n", (rv == GL_TRUE ? "GL_TRUE" : "GL_FALSE")));
	aglDescribePixelFormat(pix, AGL_DOUBLEBUFFER, &rv);
	DPRINTF3D(3, (fp, "\tAGL_DOUBLEBUFFER: %s\n", (rv == GL_TRUE ? "GL_TRUE" : "GL_FALSE")));
	aglDescribePixelFormat(pix, AGL_STEREO, &rv);
	DPRINTF3D(3, (fp, "\tAGL_STEREO: %s\n", (rv == GL_TRUE ? "GL_TRUE" : "GL_FALSE")));
	aglDescribePixelFormat(pix, AGL_AUX_BUFFERS, &rv);
	DPRINTF3D(3, (fp, "\tAGL_AUX_BUFFERS: %d\n", rv));
	aglDescribePixelFormat(pix, AGL_PIXEL_SIZE, &rv);
	DPRINTF3D(3, (fp, "\tAGL_PIXEL_SIZE: %d\n", rv));

	aglDescribePixelFormat(pix, AGL_RED_SIZE, &rv);
	DPRINTF3D(3, (fp, "\n\tAGL_RED_SIZE: %d\n", rv));
	aglDescribePixelFormat(pix, AGL_GREEN_SIZE, &rv);
	DPRINTF3D(3, (fp, "\tAGL_GREEN_SIZE: %d\n", rv));
	aglDescribePixelFormat(pix, AGL_BLUE_SIZE, &rv);
	DPRINTF3D(3, (fp, "\tAGL_BLUE_SIZE: %d\n", rv));
	aglDescribePixelFormat(pix, AGL_ALPHA_SIZE, &rv);
	DPRINTF3D(3, (fp, "\tAGL_ALPHA_SIZE: %d\n", rv));

	aglDescribePixelFormat(pix, AGL_DEPTH_SIZE, &rv);
	DPRINTF3D(3, (fp, "\n\tAGL_DEPTH_SIZE: %d\n", rv));
	aglDescribePixelFormat(pix, AGL_STENCIL_SIZE, &rv);
	DPRINTF3D(3, (fp, "\tAGL_STENCIL_SIZE: %d\n", rv));
	
	aglDescribePixelFormat(pix, AGL_ACCUM_RED_SIZE, &rv);
	DPRINTF3D(3, (fp, "\tAGL_ACCUM_RED_SIZE: %d\n", rv));
	aglDescribePixelFormat(pix, AGL_ACCUM_GREEN_SIZE, &rv);
	DPRINTF3D(3, (fp, "\tAGL_ACCUM_GREEN_SIZE: %d\n", rv));
	aglDescribePixelFormat(pix, AGL_ACCUM_BLUE_SIZE, &rv);
	DPRINTF3D(3, (fp, "\tAGL_ACCUM_BLUE_SIZE: %d\n", rv));
	aglDescribePixelFormat(pix, AGL_ACCUM_ALPHA_SIZE, &rv);
	DPRINTF3D(3, (fp, "\tAGL_ACCUM_ALPHA_SIZE: %d\n", rv));
#endif
	return 1;
}
