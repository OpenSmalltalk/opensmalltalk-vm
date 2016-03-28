/****************************************************************************
*   PROJECT: Squeak 3D accelerator
*   FILE:    sqOpenGLRenderer.c
*   CONTENT: Generic (cross-platform) bindings for OpenGL
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   Andreas.Raab@disney.com
*   RCSID:   $Id$
*
*   NOTES: 
*
*
*****************************************************************************/
#ifdef WIN32
# include <windows.h>
# include <winerror.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "sqVirtualMachine.h"
#include "sqConfig.h"
#include "sqPlatformSpecific.h"
#include "B3DAcceleratorPlugin.h"

#if defined (B3DX_GL)

#include "sqOpenGLRenderer.h"

#if !defined(GL_VERSION_1_1)
#warning "This system does not support OpenGL 1.1"
#endif

static float blackLight[4] = { 0.0f, 0.0f, 0.0f, 0.0f };

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/

int glGetRendererSurfaceHandle(int handle) {
  /* If we were to use p-buffers, this would be the place to 
     return a surface handle for the p-buffer so Squeak can
     blt directly to it. Note that this is a ZILLION times
     faster when it comes to compositing; so it is definitely
     a good idea when supported. However, I don't have the
     time to figure it out so I'll just leave this as an
     exercise for the interested reader :-)
   */
  return -1; /* e.g., fail */
}

int glGetRendererColorMasks(int handle, int *masks) {
  /* If a surface is provided, this is the place to fill
     in the color masks for the surface. Since we don't
     provide any, we just bail out.
   */
  return 0; /* e.g., fail */
}

int glGetRendererSurfaceWidth(int handle) {
  /* If a surface is provided return the width of it */
  return -1; /* e.g., fail */
}

int glGetRendererSurfaceHeight(int handle) {
  /* If a surface is provided return the height of it */
  return -1; /* e.g., fail */
}

int glGetRendererSurfaceDepth(int handle) {
  /* If a surface is provided return the depth of it */
  return -1; /* e.g., fail */
}

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/* texture support */
int glAllocateTexture(int handle, int w, int h, int d) /* return handle or -1 on error */
{   GLuint texture;
	char *errMsg = "";

	struct glRenderer *renderer = glRendererFromHandle(handle);

	if(!renderer || !glMakeCurrentRenderer(renderer)) {
		DPRINTF3D(4, (fp, "ERROR: Invalid renderer specified\n"));
		return 0;
	}

	if(w & (w-1)) return -1; /* not power of two */
	if(h & (h-1)) return -1; /* not power of two */

	DPRINTF3D(5, (fp, "### Allocating new texture (w = %d, h = %d, d = %d)\n", w, h, d));

	errMsg = "glGenTextures() failed";
	glGenTextures(1, &texture);
	if((glErr = glGetError()) != GL_NO_ERROR) goto FAILED;
	DPRINTF3D(5, (fp, "Allocated texture id = %d\n", texture));
	errMsg = "glBindTexture() failed";
	glBindTexture(GL_TEXTURE_2D, texture);
	if((glErr = glGetError()) != GL_NO_ERROR) goto FAILED;
	errMsg = "glTexParameter() failed";
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	if((glErr = glGetError()) != GL_NO_ERROR) goto FAILED;
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	if((glErr = glGetError()) != GL_NO_ERROR) goto FAILED;
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	if((glErr = glGetError()) != GL_NO_ERROR) goto FAILED;
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	if((glErr = glGetError()) != GL_NO_ERROR) goto FAILED;
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	if((glErr = glGetError()) != GL_NO_ERROR) goto FAILED;
	errMsg = "glTexImage2D() failed";
	glTexImage2D(GL_TEXTURE_2D, /* target */
				 0, /* mipmap level */
				 4, /* components */
				 w, /* width */
				 h, /* height */
				 0, /* border */
				 GL_RGBA, /* format */
				 GL_UNSIGNED_BYTE, /* type */
				 NULL /* image data - if NULL contents is unspecified */);
	if((glErr = glGetError()) != GL_NO_ERROR) goto FAILED;
	DPRINTF3D(5, (fp,"\tid = %d\n", texture));
	return texture;
FAILED:
	DPRINTF3D(1, (fp, "ERROR (glAllocateTexture): %s -- %s\n", errMsg, glErrString()));
	glDeleteTextures(1, &texture);
	return -1;
}

int glDestroyTexture(int rendererHandle, int handle) /* return true on success, false on error */
{
	struct glRenderer *renderer = glRendererFromHandle(rendererHandle);

	if(!renderer || !glMakeCurrentRenderer(renderer)) {
		DPRINTF3D(4, (fp, "ERROR: Invalid renderer specified\n"));
		return 0;
	}

	if(!glIsTexture(handle)) {
		return 0;
	}
	DPRINTF3D(5, (fp, "### Destroying texture (id = %d)\n", handle));
	glDeleteTextures(1, (GLuint*) &handle);
	ERROR_CHECK;
	return 1;
}

int glActualTextureDepth(int rendererHandle, int handle) /* return depth or <0 on error */
{
	struct glRenderer *renderer = glRendererFromHandle(rendererHandle);
	if(!renderer) return -1;
	return 32;
}

int glTextureColorMasks(int rendererHandle, int handle, int masks[4])  /* return true on success, false on error */
{
	struct glRenderer *renderer = glRendererFromHandle(rendererHandle);
	if(!renderer) return 0;
#ifdef LSB_FIRST
	masks[3] = 0xFF000000;
	masks[2] = 0x00FF0000;
	masks[1] = 0x0000FF00;
	masks[0] = 0x000000FF;
#else
	masks[0] = 0xFF000000;
	masks[1] = 0x00FF0000;
	masks[2] = 0x0000FF00;
	masks[3] = 0x000000FF;
#endif
	return 1;
}

int glTextureByteSex(int rendererHandle, int handle) /* return > 0 if MSB, = 0 if LSB, < 0 if error */
{
	struct glRenderer *renderer = glRendererFromHandle(rendererHandle);
	if(!renderer) return -1;
#ifdef LSB_FIRST
	return 0;
#else
	return 1;
#endif
}

int glTextureSurfaceHandle(int rendererHandle, int handle) {
  /* GL textures are not directly accessible */
  return -1;
}

int glUploadTexture(int rendererHandle, int handle, int w, int h, int d, void* bits)
{
	int y;

	struct glRenderer *renderer = glRendererFromHandle(rendererHandle);

	if(!renderer || !glMakeCurrentRenderer(renderer)) {
		DPRINTF3D(4, (fp, "ERROR: Invalid renderer specified\n"));
		return 0;
	}

	if(d != 32) return 0;

	if(!glIsTexture(handle)) {
		return 0;
	}
	DPRINTF3D(5, (fp, "### Uploading texture (w = %d, h = %d, d = %d, id = %d)\n", w, h, d, handle));
	glBindTexture(GL_TEXTURE_2D, handle);
	ERROR_CHECK;
	for(y = 0; y < h; y++) {
		glTexSubImage2D(GL_TEXTURE_2D, /* target */
						0, /* level */
						0, /* xoffset */
						y, /* yoffset */
						w, /* width */
						1, /* height */
						GL_RGBA, /* format */
						GL_UNSIGNED_BYTE, /* type */
						((char*)bits) + (y*w*4));
		ERROR_CHECK;
	}
	return 1;
}

int glCompositeTexture(int rendererHandle, int handle, int x, int y, int w, int h, int translucent)
{
	struct glRenderer *renderer = glRendererFromHandle(rendererHandle);

	if(!renderer || !glMakeCurrentRenderer(renderer)) {
		DPRINTF3D(4, (fp, "ERROR: Invalid renderer specified\n"));
		return 0;
	}
	if(!glIsTexture(handle)) {
		return 0;
	}
	ERROR_CHECK;
	DPRINTF3D(7, (fp, "glCompositeTexture(%d, %d, %d, %d)\n", x, y, w, h));
	{
		/* setup a transformation so that we're dealing with pixel x/y coordinate systems */
		glPushMatrix();
		glLoadIdentity();
		glMatrixMode(GL_PROJECTION);
		glPushMatrix();
		glLoadIdentity();
		ERROR_CHECK;
		/* matrix backup complete - now install new mapping */
		{
			int width = renderer->bufferRect[2];
			int height = renderer->bufferRect[3];
			glViewport(0, 0, width, height);
			/* now remap from lower left origin to upper left origin 
			   while scaling from (-width,+width) to (-1, +1) */
			glScaled(2.0/width, -2.0/height, 1.0);
			/* offset origin to start at 0,0 rather than -width/2,-height/2 */
			glTranslated(width*-0.5, height*-0.5, 0.0);
			ERROR_CHECK;
		}
		/* setup the right shading rules */
		glPushAttrib(GL_ALL_ATTRIB_BITS);
		{
			glShadeModel(GL_FLAT);
			glEnable(GL_TEXTURE_2D);
			glDisable(GL_COLOR_MATERIAL);
			glDisable(GL_DITHER);
			glDisable(GL_LIGHTING);
			glDisable(GL_DEPTH_TEST);
			glDisable(GL_BLEND);
			glDisable(GL_CULL_FACE);
			glDepthMask(GL_FALSE);
			glColor4d(1.0, 1.0, 1.0, 1.0);
			glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST);
		}
		ERROR_CHECK;

		/* prepare for translucency */
		if(translucent) {
			glEnable(GL_BLEND);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		}
		ERROR_CHECK;
	}
	{
		/* and *THAT* is the hard work ;-))) */
		glBindTexture(GL_TEXTURE_2D, handle);
		ERROR_CHECK;
		x -= renderer->bufferRect[0];
		y -= renderer->bufferRect[1];
		DPRINTF3D(7, (fp, "glRecti(%d, %d, %d, %d)\n", x, y, w, h));
		glBegin(GL_QUADS);
			glTexCoord2d(0.0, 0.0);
			glVertex2i(x, y);
			glTexCoord2d(1.0, 0.0);
			glVertex2i(x+w, y);
			glTexCoord2d(1.0, 1.0);
			glVertex2i(x+w, y+h);
			glTexCoord2d(0.0, 1.0);
			glVertex2i(x, y+h);
		glEnd();
		ERROR_CHECK;
	}
	/* and restore everything back to normal */
	{
		glPopAttrib();
		/* BUG BUG BUG - Mac OpenGL has a problem with glPushAttrib/glShadeModel/glPopAttrib - BUG BUG BUG */
		glShadeModel(GL_SMOOTH);
		glPopMatrix();
		glMatrixMode(GL_MODELVIEW);
		glPopMatrix();
	}
	ERROR_CHECK;
	/* done */
	return 1;
}

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/

int glSetViewport(int handle, int x, int y, int w, int h) /* return true on success, false on error */
{
	struct glRenderer *renderer = glRendererFromHandle(handle);
	if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;

	DPRINTF3D(5, (fp, "### New Viewport\n"));
	DPRINTF3D(5, (fp, "\tx: %d\n\ty: %d\n\tw: %d\n\th: %d\n", x, y, w, h));
	renderer->viewport[0] = x;
	renderer->viewport[1] = y;
	renderer->viewport[2] = w;
	renderer->viewport[3] = h;
	x -= renderer->bufferRect[0];
	y -= renderer->bufferRect[1];
	DPRINTF3D(5, (fp, "\tx: %d\n\ty: %d\n\tw: %d\n\th: %d\n", x, y, w, h));
	glViewport(x, renderer->bufferRect[3] - (y+h), w, h);
	ERROR_CHECK;

	return 1;
}

int glClearDepthBuffer(int handle) /* return true on success, false on error */
{
	struct glRenderer *renderer = glRendererFromHandle(handle);
	if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;
	DPRINTF3D(5, (fp, "### Clearing depth buffer\n"));
	glClear(GL_DEPTH_BUFFER_BIT);
	ERROR_CHECK;
	return 1;
}

int glClearViewport(int handle, unsigned int rgba, unsigned int pv) /* return true on success, false on error */
{
	struct glRenderer *renderer = glRendererFromHandle(handle);
	if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;
	DPRINTF3D(5, (fp, "### Clearing viewport buffer\n"));
	glClearColor(
				((rgba >> 16) & 255) / 255.0f, 
				((rgba >>  8) & 255) / 255.0f, 
				(rgba & 255) / 255.0f, 
				(rgba >> 24) / 255.0f);
	glClear(GL_COLOR_BUFFER_BIT);
	ERROR_CHECK;
	return 1;
}

int glFinishRenderer(int handle) /* return true on success, false on error */
{
	struct glRenderer *renderer = glRendererFromHandle(handle);
	if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;
	DPRINTF3D(5, (fp, "### Finishing renderer\n"));
	glFinish();
	ERROR_CHECK;
	return 1;
}

int glFlushRenderer(int handle) /* return true on success, false on error */
{
	struct glRenderer *renderer = glRendererFromHandle(handle);
	if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;
	DPRINTF3D(5, (fp, "### Flushing renderer\n"));
	glFlush();
	ERROR_CHECK;
	return 1;
}

int glSwapRendererBuffers(int handle) /* return true on success, false on error */
{
	struct glRenderer *renderer = glRendererFromHandle(handle);
	if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;
	DPRINTF3D(5, (fp, "### Swapping renderer buffers\n"));
	glSwapBuffers(renderer);
	ERROR_CHECK;
	return 1;
}


int glSetTransform(int handle, float *modelViewMatrix, float *projectionMatrix) {
	float matrix[16];
	int i, j;

	struct glRenderer *renderer = glRendererFromHandle(handle);
	if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;

	DPRINTF3D(5, (fp, "### Installing new transformations\n"));
	glMatrixMode(GL_PROJECTION);
	ERROR_CHECK;
	glLoadIdentity();
	ERROR_CHECK;
	if(projectionMatrix) {
		/* TODO: Check if matrix is simple and don't use glMultMatrixf if so */
		for(i=0; i<4; i++)
			for(j=0; j<4; j++)
				matrix[i*4+j] = projectionMatrix[j*4+i];
		glLoadMatrixf(matrix);
		ERROR_CHECK;
	}
	glMatrixMode(GL_MODELVIEW);
	ERROR_CHECK;
	glLoadIdentity();
	ERROR_CHECK;
	if(modelViewMatrix) {
		/* TODO: Check if matrix is simple and don't use glMultMatrixf if so */
		for(i=0; i<4; i++)
			for(j=0; j<4; j++)
				matrix[i*4+j] = modelViewMatrix[j*4+i];
		glLoadMatrixf(matrix);
		ERROR_CHECK;
	}
	return 1;
}

int glDisableLights(int handle) {
	int i;
	GLint max;
	struct glRenderer *renderer = glRendererFromHandle(handle);

	if(!renderer || !glMakeCurrentRenderer(renderer)) {
		DPRINTF3D(4, (fp, "ERROR: Invalid renderer specified\n"));
		return 0;
	}

	DPRINTF3D(5, (fp, "### Disabling all lights\n"));
	glGetIntegerv(GL_MAX_LIGHTS, &max);
	ERROR_CHECK;
	for(i = 0; i < max; i++) {
		glDisable(GL_LIGHT0+i);
		ERROR_CHECK;
		if( (glErr = glGetError()) != GL_NO_ERROR) 
			DPRINTF3D(1, (fp,"ERROR (glDisableLights): glDisable(GL_LIGHT%d) failed -- %s\n", i, glErrString()));
	}
	return 1;
}

int glLoadMaterial(int handle, B3DPrimitiveMaterial *mat)
{
	struct glRenderer *renderer = glRendererFromHandle(handle);

	if(!renderer || !glMakeCurrentRenderer(renderer)) {
		DPRINTF3D(4, (fp, "ERROR: Invalid renderer specified\n"));
		return 0;
	}

	DPRINTF3D(5, (fp, "### New Material\n"));
	if(!mat) {
		DPRINTF3D(5, (fp, "\tOFF (material == nil)\n"));
		glDisable(GL_LIGHTING);
		ERROR_CHECK;
		return 1;
	}
	DPRINTF3D(5, (fp, "\tambient  : %g, %g, %g, %g\n",mat->ambient[0], mat->ambient[1], mat->ambient[2], mat->ambient[3]));
	DPRINTF3D(5, (fp, "\tdiffuse  : %g, %g, %g, %g\n",mat->diffuse[0], mat->diffuse[1], mat->diffuse[2], mat->diffuse[3]));
	DPRINTF3D(5, (fp, "\tspecular : %g, %g, %g, %g\n",mat->specular[0], mat->specular[1], mat->specular[2], mat->specular[3]));
	DPRINTF3D(5, (fp, "\temission : %g, %g, %g, %g\n",mat->emission[0], mat->emission[1], mat->emission[2], mat->emission[3]));
	DPRINTF3D(5, (fp, "\tshininess: %g\n", mat->shininess));
	glEnable(GL_LIGHTING);
	ERROR_CHECK;
	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, mat->ambient);
	ERROR_CHECK;
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, mat->diffuse);
	ERROR_CHECK;
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, mat->specular);
	ERROR_CHECK;
	glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, mat->emission);
	ERROR_CHECK;
	glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, mat->shininess);
	ERROR_CHECK;
	return 1;
}

int glLoadLight(int handle, int idx, B3DPrimitiveLight *light)
{
	float pos[4];
	int index = GL_LIGHT0 + idx;
	struct glRenderer *renderer = glRendererFromHandle(handle);

	if(!renderer || !glMakeCurrentRenderer(renderer)) {
		DPRINTF3D(4, (fp, "ERROR: Invalid renderer specified\n"));
		return 0;
	}

	DPRINTF3D(5, (fp, "### New Light (%d)\n", idx));

	if(!light) {
		DPRINTF3D(5, (fp, "\tDISABLED\n"));
		glDisable(index);
		ERROR_CHECK;
		return 1;
	}
	glEnable(index);
	ERROR_CHECK;
	DPRINTF3D(5, (fp, "\tambient       : %g, %g, %g, %g\n",light->ambient[0], light->ambient[1], light->ambient[2], light->ambient[3]));
	DPRINTF3D(5, (fp, "\tdiffuse       : %g, %g, %g, %g\n",light->diffuse[0], light->diffuse[1], light->diffuse[2], light->diffuse[3]));
	DPRINTF3D(5, (fp, "\tspecular      : %g, %g, %g, %g\n",light->specular[0], light->specular[1], light->specular[2], light->specular[3]));
	DPRINTF3D(5, (fp, "\tposition      : %g, %g, %g\n",light->position[0], light->position[1], light->position[2]));
	DPRINTF3D(5, (fp, "\tdirection     : %g, %g, %g\n",light->direction[0], light->direction[1], light->direction[2]));
	DPRINTF3D(5, (fp, "\tattenuation   : %g, %g, %g\n",light->attenuation[0], light->attenuation[1], light->attenuation[2]));
	DPRINTF3D(5, (fp, "\tflags [%d]:", light->flags));
	if(light->flags & B3D_LIGHT_AMBIENT) DPRINTF3D(5,(fp," B3D_LIGHT_AMBIENT"));
	if(light->flags & B3D_LIGHT_DIFFUSE) DPRINTF3D(5,(fp," B3D_LIGHT_DIFFUSE"));
	if(light->flags & B3D_LIGHT_SPECULAR) DPRINTF3D(5,(fp," B3D_LIGHT_SPECULAR"));
	if(light->flags & B3D_LIGHT_POSITIONAL) DPRINTF3D(5,(fp," B3D_LIGHT_POSITIONAL"));
	if(light->flags & B3D_LIGHT_DIRECTIONAL) DPRINTF3D(5,(fp," B3D_LIGHT_DIRECTIONAL"));
	if(light->flags & B3D_LIGHT_ATTENUATED) DPRINTF3D(5,(fp," B3D_LIGHT_ATTENUATED"));
	if(light->flags & B3D_LIGHT_HAS_SPOT) DPRINTF3D(5,(fp," B3D_LIGHT_HAS_SPOT"));
	DPRINTF3D(5, (fp, "\n"));
	DPRINTF3D(5, (fp, "\tspot exponent : %g\n", light->spotExponent));

	DPRINTF3D(5, (fp, "### Installing Light (%d)\n", idx));
	if(light->flags & B3D_LIGHT_AMBIENT) {
		DPRINTF3D(5, (fp, "\tambient  : %g, %g, %g, %g\n",light->ambient[0], light->ambient[1], light->ambient[2], light->ambient[3]));
		glLightfv(index, GL_AMBIENT, light->ambient);
	} else {
		DPRINTF3D(5, (fp, "\tambient  : OFF (0, 0, 0, 1)\n"));
		glLightfv(index, GL_AMBIENT, blackLight);
	}
	ERROR_CHECK;

	if(light->flags & B3D_LIGHT_DIFFUSE) {
		DPRINTF3D(5, (fp, "\tdiffuse  : %g, %g, %g, %g\n",light->diffuse[0], light->diffuse[1], light->diffuse[2], light->diffuse[3]));
		glLightfv(index, GL_DIFFUSE, light->diffuse);
	} else {
		DPRINTF3D(5, (fp, "\tdiffuse  : OFF (0, 0, 0, 1)\n"));
		glLightfv(index, GL_DIFFUSE, blackLight);
	}
	ERROR_CHECK;

	if(light->flags & B3D_LIGHT_SPECULAR) {
		DPRINTF3D(5, (fp, "\tspecular : %g, %g, %g, %g\n",light->specular[0], light->specular[1], light->specular[2], light->specular[3]));
		glLightfv(index, GL_SPECULAR, light->specular);
	} else {
		DPRINTF3D(5, (fp, "\tspecular : OFF (0, 0, 0, 1)\n"));
		glLightfv(index, GL_SPECULAR, blackLight);
	}
	ERROR_CHECK;

	if(light->flags & B3D_LIGHT_POSITIONAL) {
		DPRINTF3D(5, (fp, "\tposition : %g, %g, %g\n",light->position[0], light->position[1], light->position[2]));
		pos[0] = light->position[0];
		pos[1] = light->position[1];
		pos[2] = light->position[2];
		pos[3] = 1.0f;
		/* @@@ FIXME: Squeak pre-transforms the light @@@ */
		glPushMatrix();
		glLoadIdentity();
		glLightfv(index, GL_POSITION, pos);
		glPopMatrix();
	} else {
		if(light->flags & B3D_LIGHT_DIRECTIONAL) {
			DPRINTF3D(5, (fp, "\tdirection: %g, %g, %g\n",light->direction[0], light->direction[1], light->direction[2]));
			pos[0] = light->direction[0];
			pos[1] = light->direction[1];
			pos[2] = light->direction[2];
			pos[3] = 0.0f;
			/* @@@ FIXME: Squeak pre-transforms the light @@@ */
			glPushMatrix();
			glLoadIdentity();
			glLightfv(index, GL_POSITION, pos);
			glPopMatrix();
		}
	}
	ERROR_CHECK;

	if(light->flags & B3D_LIGHT_ATTENUATED) {
		DPRINTF3D(5, (fp, "\tattenuation: %g, %g, %g\n",light->attenuation[0], light->attenuation[1], light->attenuation[2]));
		glLightf(index, GL_CONSTANT_ATTENUATION,  light->attenuation[0]);
		ERROR_CHECK;
		glLightf(index, GL_LINEAR_ATTENUATION,    light->attenuation[1]);
		ERROR_CHECK;
		glLightf(index, GL_QUADRATIC_ATTENUATION, light->attenuation[2]);
		ERROR_CHECK;
	} else {
		DPRINTF3D(5, (fp, "\tattenuation: OFF (1, 0, 0)\n"));
		glLightf(index, GL_CONSTANT_ATTENUATION,  1.0f);
		ERROR_CHECK;
		glLightf(index, GL_LINEAR_ATTENUATION,    0.0f);
		ERROR_CHECK;
		glLightf(index, GL_QUADRATIC_ATTENUATION, 0.0f);
		ERROR_CHECK;
	}

	if(light->flags & B3D_LIGHT_HAS_SPOT) {
		DPRINTF3D(5, (fp, "\tspot exponent : %g\n", light->spotExponent));
		DPRINTF3D(5, (fp, "\tspot cutoff   : ???\n"));
		DPRINTF3D(5, (fp, "\tspot direction: %g, %g, %g\n",light->direction[0], light->direction[1], light->direction[2]));
		glLightf(index, GL_SPOT_EXPONENT, light->spotExponent);
		ERROR_CHECK;
		glLightf(index, GL_SPOT_CUTOFF, light->spotExponent);
		ERROR_CHECK;
		glLightfv(index, GL_SPOT_DIRECTION, light->direction);
		ERROR_CHECK;
	} else {
		glLightf(index, GL_SPOT_EXPONENT, 0.0f);
		ERROR_CHECK;
		glLightf(index, GL_SPOT_CUTOFF, 180.0f);
		ERROR_CHECK;
	}
	return 1;
}

int glSetFog(int handle, int fogType, double density, 
             double fogRangeStart, double fogRangeEnd, int rgba) {
  GLfloat fogColor[4];
  glRenderer *renderer = glRendererFromHandle(handle);

  if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;
  if(fogType == 0) {
    glDisable(GL_FOG);
    ERROR_CHECK;
    return 1;
  }

  glEnable(GL_FOG);
  if(fogType == 1) glFogi(GL_FOG_MODE, GL_LINEAR);
  if(fogType == 2) glFogi(GL_FOG_MODE, GL_EXP);
  if(fogType == 3) glFogi(GL_FOG_MODE, GL_EXP2);
  glFogf(GL_FOG_DENSITY, (GLfloat)density);
  glFogf(GL_FOG_START, (GLfloat)fogRangeStart);
  glFogf(GL_FOG_END, (GLfloat)fogRangeEnd);
  fogColor[0] = ((rgba >> 16) & 255) / 255.0f;
  fogColor[1] = ((rgba >>  8) & 255) / 255.0f;
  fogColor[2] = (rgba & 255) / 255.0f;
  fogColor[3] = (rgba >> 24) / 255.0f;
  glFogfv(GL_FOG_COLOR, fogColor);
  /* enable pixel fog */
  glHint(GL_FOG_HINT, GL_NICEST);
  ERROR_CHECK;
  return 1;
}

int glGetIntProperty(int handle, int prop)
{
  GLint v;

  glRenderer *renderer = glRendererFromHandle(handle);
  if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;

  if(prop < 0) return glGetIntPropertyOS(handle, prop);

  switch(prop) {
  case 1: /* backface culling */
    if(!glIsEnabled(GL_CULL_FACE)) return 0;
    glGetIntegerv(GL_FRONT_FACE, &v);
    if(v == GL_CW) return 1;
    if(v == GL_CCW) return -1;
    return 0;
  case 2: /* polygon mode */
    glGetIntegerv(GL_POLYGON_MODE, &v);
    ERROR_CHECK;
    return v;
  case 3: /* point size */
    glGetIntegerv(GL_POINT_SIZE, &v);
    ERROR_CHECK;
    return v;
  case 4: /* line width */
    glGetIntegerv(GL_LINE_WIDTH, &v);
    ERROR_CHECK;
    return v;
  case 5: /* blend enable */
    return glIsEnabled(GL_BLEND);
  case 6: /* blend source factor */
  case 7: /* blend dest factor */
    if(prop == 6)
      glGetIntegerv(GL_BLEND_SRC, &v);
    else
      glGetIntegerv(GL_BLEND_DST, &v);
    ERROR_CHECK;
    switch(v) {
        case GL_ZERO: return 0;
        case GL_ONE: return 1;
        case GL_SRC_COLOR: return 2;
        case GL_ONE_MINUS_SRC_COLOR: return 3;
        case GL_DST_COLOR: return 4;
        case GL_ONE_MINUS_DST_COLOR: return 5;
        case GL_SRC_ALPHA: return 6;
        case GL_ONE_MINUS_SRC_ALPHA: return 7;
        case GL_DST_ALPHA: return 8;
        case GL_ONE_MINUS_DST_ALPHA: return 9;
        case GL_SRC_ALPHA_SATURATE: return 10;
        default: return -1;
    }
  }
  return 0;
}

int glSetIntProperty(int handle, int prop, int value)
{
  glRenderer *renderer = glRendererFromHandle(handle);
  if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;

  if(prop < 0) return glSetIntPropertyOS(handle, prop, value);

  switch(prop) {
  case 1: /* backface culling */
    if(!value) {
      glDisable(GL_CULL_FACE);
      ERROR_CHECK;
      return 1;
    }
    glEnable(GL_CULL_FACE);
    glFrontFace(value == 1 ? GL_CCW : GL_CW);
    ERROR_CHECK;
    return 1;
  case 2: /* polygon mode */
    if(value == 0) glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    else if(value == 1) glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
    else if(value == 2) glPolygonMode(GL_FRONT_AND_BACK, GL_POINT);
    else return 0;
    ERROR_CHECK;
    return 1;
  case 3: /* point size */
    glPointSize(value);
    ERROR_CHECK;
    return 1;
  case 4: /* line width */
    glLineWidth(value);
    ERROR_CHECK;
    return 1;
  case 5: /* blend enable */
    if(value)
      glEnable(GL_BLEND);
    else
      glDisable(GL_BLEND);
    ERROR_CHECK;
    return 1;
  case 6: /* blend source factor */
  case 7: /* blend dest factor */
    {
      int factor;
      GLint src, dst;
      switch(value) {
        case 0: factor = GL_ZERO; break;
        case 1: factor = GL_ONE; break;
        case 2: factor = GL_SRC_COLOR; break;
        case 3: factor = GL_ONE_MINUS_SRC_COLOR; break;
        case 4: factor = GL_DST_COLOR; break;
        case 5: factor = GL_ONE_MINUS_DST_COLOR; break;
        case 6: factor = GL_SRC_ALPHA; break;
        case 7: factor = GL_ONE_MINUS_SRC_ALPHA; break;
        case 8: factor = GL_DST_ALPHA; break;
        case 9: factor = GL_ONE_MINUS_DST_ALPHA; break;
        case 10: factor = GL_SRC_ALPHA_SATURATE; break;
        default: return 0;
      }
      glGetIntegerv(GL_BLEND_SRC, &src);
      glGetIntegerv(GL_BLEND_DST, &dst);
      if(prop == 6) src = factor;
      else dst = factor;
      glBlendFunc(src,dst);
      ERROR_CHECK;
      return 1;
    }
  }
  return 0;
}

#ifndef GL_VERSION_1_1

static void glRenderVertex(B3DPrimitiveVertex *vtx, int flags)
{
	DPRINTF3D(10, (fp, "["));
	if(flags & 1) {
		unsigned int vv = vtx->pixelValue32;
		DPRINTF3D(10, (fp, "C(%d, %d, %d, %d)",(vv >> 16) & 255, (vv >> 8) & 255, vv & 255, vv >> 24));
		glColor4ub( (vv >> 16) & 255, (vv >> 8) & 255, vv & 255, vv >> 24 );
	}
	if(flags & 2) {
		DPRINTF3D(10, (fp, "N(%g, %g, %g)", vtx->normal[0], vtx->normal[1], vtx->normal[2]));
		glNormal3fv(vtx->normal);
	}
	if(flags & 4) {
		DPRINTF3D(10, (fp, "T(%g, %g)", vtx->texCoord[0], vtx->texCoord[1]));
		glTexCoord2fv(vtx->texCoord);
	}
	DPRINTF3D(10, (fp, "V(%g, %g, %g)]\n", vtx->position[0], vtx->position[1], vtx->position[2]));
	glVertex3fv(vtx->position);
}
#endif

/* General dummy for Squeak's primitive faces */
typedef int B3DInputFace;

int glRenderVertexBuffer(int handle, int primType, int flags, int texHandle, float *vtxArray, int vtxSize, int *idxArray, int idxSize)
{
	B3DPrimitiveVertex *vtxPointer = (B3DPrimitiveVertex*) vtxArray;
	B3DInputFace *facePtr = (B3DInputFace*) idxArray;
	GLuint tracking;
	int nVertices = vtxSize;
#ifndef GL_VERSION_1_1
	int nFaces = 0;
#endif
	int i, vtxFlags;

	struct glRenderer *renderer = glRendererFromHandle(handle);

	if(!renderer || !glMakeCurrentRenderer(renderer)) {
		DPRINTF3D(4, (fp, "ERROR: Invalid renderer specified\n"));
		return 0;
	}

	DPRINTF3D(5, (fp,"### Primitive : %d\n", primType));
	DPRINTF3D(5, (fp,"\ttexHandle   : %d\n", texHandle));
	DPRINTF3D(5, (fp,"\tcolor flags :"));
	if(flags & B3D_VB_TRACK_AMBIENT) DPRINTF3D(5,(fp," B3D_VB_TRACK_AMBIENT"));
	if(flags & B3D_VB_TRACK_DIFFUSE) DPRINTF3D(5,(fp," B3D_VB_TRACK_DIFFUSE"));
	if(flags & B3D_VB_TRACK_SPECULAR) DPRINTF3D(5,(fp," B3D_VB_TRACK_SPECULAR"));
	if(flags & B3D_VB_TRACK_EMISSION) DPRINTF3D(5,(fp," B3D_VB_TRACK_EMISSION"));
	DPRINTF3D(5, (fp,"\n\tlight flags :"));
	if(flags & B3D_VB_LOCAL_VIEWER) DPRINTF3D(5,(fp," B3D_VB_LOCAL_VIEWER"));
	if(flags & B3D_VB_TWO_SIDED) DPRINTF3D(5,(fp," B3D_VB_TWO_SIDED"));
	DPRINTF3D(5, (fp,"\n\tvertex flags:"));
	if(flags & B3D_VB_HAS_NORMALS) DPRINTF3D(5,(fp," B3D_VB_HAS_NORMALS"));
	if(flags & B3D_VB_HAS_TEXTURES) DPRINTF3D(5,(fp," B3D_VB_HAS_TEXTURES"));
	DPRINTF3D(5, (fp, "\n"));

	/* process VB flags */
	tracking = 0;
	if(flags & B3D_VB_TRACK_AMBIENT) tracking |= GL_AMBIENT;
	if(flags & B3D_VB_TRACK_DIFFUSE) tracking |= GL_DIFFUSE;
	if(flags & B3D_VB_TRACK_SPECULAR) tracking |= GL_SPECULAR;
	if(flags & B3D_VB_TRACK_EMISSION) tracking |= GL_EMISSION;

	if(tracking) {
		/* in accordance with glColorMaterial man page noting:
		   Call glColorMaterial before enabling GL_COLOR_MATERIAL. */
		glColorMaterial(GL_FRONT_AND_BACK, tracking);
		ERROR_CHECK;
		glEnable(GL_COLOR_MATERIAL);
		ERROR_CHECK;
	}

	glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER, (flags & B3D_VB_LOCAL_VIEWER) ? 1 : 0);
	ERROR_CHECK;
	glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, (flags & B3D_VB_TWO_SIDED) ? 1 : 0);
	ERROR_CHECK;

	if(texHandle > 0) {
		glEnable(GL_TEXTURE_2D);
		ERROR_CHECK;
		glBindTexture(GL_TEXTURE_2D, texHandle);
		ERROR_CHECK;
	} else {
		glDisable(GL_TEXTURE_2D);
		ERROR_CHECK;
	}
	vtxFlags = 0;
	if(tracking)
		vtxFlags |= 1;
	if(flags & B3D_VB_HAS_NORMALS)
		vtxFlags |= 2;
	if(flags & B3D_VB_HAS_TEXTURES)
		vtxFlags |= 4;
#ifdef GL_VERSION_1_1
	/* use glDrawElements() etc */
	/* @@@ HACK!!! */
	vtxPointer -= 1; /* that way we can submit all vertices at once */
	if(vtxFlags & 1) {
	  /* harumph... we need to rotate all the colors as we're getting ARGB here but GL expects RGBA... */
	  for(i=1;i<=nVertices;i++) {
	    unsigned int argb = vtxPointer[i].pixelValue32;
	    unsigned int rgba = (argb << 8) | (argb >> 24);
	    vtxPointer[i].pixelValue32 = rgba;
	  }
	  glColorPointer(4, GL_UNSIGNED_BYTE, sizeof(B3DPrimitiveVertex), &(vtxPointer->pixelValue32));
	  glEnableClientState(GL_COLOR_ARRAY);
	}
	if(vtxFlags & 2) {
	  glNormalPointer(GL_FLOAT, sizeof(B3DPrimitiveVertex), vtxPointer->normal);
	  glEnableClientState(GL_NORMAL_ARRAY);
	}
	if(vtxFlags & 4) {
	  glTexCoordPointer(2, GL_FLOAT, sizeof(B3DPrimitiveVertex), vtxPointer->texCoord);
	  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	}

	glVertexPointer(3, GL_FLOAT, sizeof(B3DPrimitiveVertex), vtxPointer->position);
	glEnableClientState(GL_VERTEX_ARRAY);
	ERROR_CHECK;
	/* @@@ HACK!!! */
	vtxPointer += 1; /* that way we can submit all vertices at once */
#endif /* GL_VERSION_1_1 */

	switch(primType) {
		case 1: /* points */
#ifdef GL_VERSION_1_1
		        glDrawArrays(GL_POINTS, 1, nVertices);
#else /* !GL_VERSION_1_1 */
			glBegin(GL_POINTS);
			for(i=0; i < nVertices; i++)
				glRenderVertex(vtxPointer + i, vtxFlags);
			glEnd();
#endif /* GL_VERSION_1_1 */
			break;
		case 2: /* lines */
#ifdef GL_VERSION_1_1
		        glDrawArrays(GL_LINES, 1, nVertices);
#else /* !GL_VERSION_1_1 */
			glBegin(GL_LINES);
			for(i=0; i < nVertices; i++)
				glRenderVertex(vtxPointer + i, vtxFlags);
			glEnd();
#endif /* GL_VERSION_1_1 */
			break;
		case 3: /* polygon */
#ifdef GL_VERSION_1_1
		        glDrawArrays(GL_POLYGON, 1, nVertices);
#else /* !GL_VERSION_1_1 */
			glBegin(GL_POLYGON);
			for(i=0; i < nVertices; i++)
				glRenderVertex(vtxPointer + i, vtxFlags);
			glEnd();
#endif /* GL_VERSION_1_1 */
			break;
		case 4: /* indexed lines */
#ifdef GL_VERSION_1_1
		        glDrawElements(GL_LINES, idxSize, GL_UNSIGNED_INT, facePtr);
#else /* !GL_VERSION_1_1 */
			nFaces = idxSize / 2;
			glBegin(GL_LINES);
			for(i = 0; i < nFaces; i++) {
				B3DInputFace *face = facePtr + (2*i);
				if(face[0] && face[1]) {
					DPRINTF3D(10, (fp,"\n"));
					glRenderVertex(vtxPointer + face[0] - 1, vtxFlags);
					glRenderVertex(vtxPointer + face[1] - 1, vtxFlags);
				}
			}
			glEnd();
#endif /* GL_VERSION_1_1 */
			break;
		case 5: /* indexed triangles */
#ifdef GL_VERSION_1_1
		        glDrawElements(GL_TRIANGLES, idxSize, GL_UNSIGNED_INT, facePtr);
#else /* !GL_VERSION_1_1 */
			nFaces = idxSize / 3;
			glBegin(GL_TRIANGLES);
			for(i = 0; i < nFaces; i++) {
				B3DInputFace *face = facePtr + (3*i);
				if(face[0] && face[1] && face[2]) {
					DPRINTF3D(10, (fp,"\n"));
					glRenderVertex(vtxPointer + face[0] - 1, vtxFlags);
					glRenderVertex(vtxPointer + face[1] - 1, vtxFlags);
					glRenderVertex(vtxPointer + face[2] - 1, vtxFlags);
				}
			}
			glEnd();
#endif /* GL_VERSION_1_1 */
			break;
		case 6: /* indexed quads */
#ifdef GL_VERSION_1_1
		        glDrawElements(GL_QUADS, idxSize, GL_UNSIGNED_INT, facePtr);
#else /* !GL_VERSION_1_1 */
			nFaces = idxSize / 4;
			glBegin(GL_QUADS);
			for(i = 0; i < nFaces; i++) {
				B3DInputFace *face = facePtr + (4*i);
				if(face[0] && face[1] && face[2] && face[3]) {
					DPRINTF3D(10, (fp,"\n"));
					glRenderVertex(vtxPointer + face[0] - 1, vtxFlags);
					glRenderVertex(vtxPointer + face[1] - 1, vtxFlags);
					glRenderVertex(vtxPointer + face[2] - 1, vtxFlags);
					glRenderVertex(vtxPointer + face[3] - 1, vtxFlags);
				}
			}
			glEnd();
#endif /* GL_VERSION_1_1 */
			break;
	}
	ERROR_CHECK;
	DPRINTF3D(5, (fp,"\n"));
	glDisable(GL_COLOR_MATERIAL);
	ERROR_CHECK;
#ifdef GL_VERSION_1_1
	if(vtxFlags & 1)
	  glDisableClientState(GL_COLOR_ARRAY);
	if(vtxFlags & 2)
	  glDisableClientState(GL_NORMAL_ARRAY);
	if(vtxFlags & 4)
	  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
	ERROR_CHECK;
#endif /* GL_VERSION_1_1 */
	return 1;
}


/*****************************************************************************/
/*****************************************************************************/
int b3dLoadClientState(int handle, float *vtxData, int vtxSize, float *colorData, int colorSize, float *normalData, int normalSize, float *txData, int txSize) {
  glRenderer *renderer = glRendererFromHandle(handle);
  if(!renderer || !glMakeCurrentRenderer(renderer)) {
    DPRINTF3D(0, (fp, "ERROR: Invalid renderer specified: %d\n", handle));
    return 0;
  }

  if(colorData) glColorPointer(colorSize, GL_FLOAT, colorSize*4, colorData);
  else glDisableClientState(GL_COLOR_ARRAY);
  if(normalData) glNormalPointer(GL_FLOAT, normalSize*4, normalData);
  else glDisableClientState(GL_NORMAL_ARRAY);
  if(txData) glTexCoordPointer(txSize, GL_FLOAT, txSize*4, txData);
  else glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glVertexPointer(vtxSize, GL_FLOAT, vtxSize*4, vtxData);
  return 1;
}

int b3dDrawRangeElements(int handle, int mode, int minIdx, int maxIdx, int nFaces, unsigned int *facePtr) {
  glRenderer *renderer = glRendererFromHandle(handle);
  if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;

#ifdef WIN32
  if(!renderer->glDrawRangeElements) {
    void *fn;
    fn = wglGetProcAddress("glDrawRangeElements");
    if(!fn) {
      DPRINTF3D(1, (fp, "ERROR: Cannot find glDrawRangeElements\n"));
      fn = wglGetProcAddress("glDrawRangeElementsEXT");
      if(!fn) {
	DPRINTF3D(1, (fp, "ERROR: Cannot find glDrawRangeElementsEXT\n"));
	return 0;
      }
    }
    renderer->glDrawRangeElements = fn;
  }
  (*(renderer->glDrawRangeElements))
    (mode, minIdx, maxIdx, nFaces, GL_UNSIGNED_INT, facePtr);
#else
  glDrawRangeElements(mode, minIdx, maxIdx, nFaces, GL_UNSIGNED_INT, facePtr);
#endif
  return 1;
}

int b3dDrawElements(int handle, int mode, int nFaces, unsigned int *facePtr) {
  glRenderer *renderer = glRendererFromHandle(handle);
  if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;
  glDrawElements(mode, nFaces, GL_UNSIGNED_INT, facePtr);
  return 1;
}

int b3dDrawArrays(int handle, int mode, int minIdx, int maxIdx) {
  glRenderer *renderer = glRendererFromHandle(handle);
  if(!renderer || !glMakeCurrentRenderer(renderer)) return 0;
  glDrawArrays(mode, minIdx, maxIdx);
  return 1;
}


#endif /* defined B3DX_GL */
