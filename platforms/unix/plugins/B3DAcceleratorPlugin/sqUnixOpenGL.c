/* sqUnixOpenGL.c -- support for accelerated 3D rendering
 * 
 * Author: Bert Freudenberg <bert@isg.cs.uni-magdeburg.de>
 *
 * Modified to work with both GLX and Quartz by: Ian.Piumarta@INRIA.Fr
 * 
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *      You are NOT ALLOWED to distribute modified versions of this file
 *      under its original name.  If you modify this file then you MUST
 *      rename it before making your modifications available publicly.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following additional restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. You must not distribute (or make publicly available by any
 *      means) a modified copy of this file unless you first rename it.
 * 
 *   3. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 * 
 * Last edited: 2003-02-03 18:52:50 by piumarta on emilia.local.
 * 
 * Note: the os-specific parts (ioGL* functions) are defined in
 *	 sqUnixX11.c (for X11/GLX on Unix) and
 *	 sqUnixQuartz.m (for Quartz/CoreGL on MacOSX).
 */

#include "sq.h"
#include "B3DAcceleratorPlugin.h"
#include "sqOpenGLRenderer.h"
#include "SqDisplay.h"

#include <stdio.h>
#include <sys/types.h>

extern struct VirtualMachine *interpreterProxy;
static struct SqDisplay	     *dpy= 0;

static glRenderer *current= 0;
static glRenderer  renderers[MAX_RENDERER];

static float blackLight[4]= { 0.0f, 0.0f, 0.0f, 0.0f };


int glInitialize(void)
{
  int i;
  for (i= 0;  i < MAX_RENDERER;  ++i)
    renderers[i].used= 0;
  if (!(dpy= ioGetDisplayModule()))
    return 0;
  dpy->ioGLinitialise();
  return 1;
}


int glShutdown(void)
{
  int i;
  for (i= 0;  i < MAX_RENDERER;  ++i)
    if (renderers[i].used)
      glDestroyRenderer(i);
  dpy= 0;
  return 1;
}


int glMakeCurrentRenderer(glRenderer *renderer)
{
  if (current == renderer)
    return 1;

  if (renderer)
    {
      if (!renderer->used)
	return 0;
      if (!dpy->ioGLmakeCurrentRenderer(renderer))
	{
	  DPRINTF(1, (fp, "glMakeCurrentRenderer failed\n"));
	  return 0;
	}
    }
  else
    dpy->ioGLmakeCurrentRenderer(0);

  current= renderer;
  return 1;
}


int glCreateRendererFlags(int x, int y, int w, int h, int flags)
{
  glRenderer *renderer= 0;
  int	      index;

  if (flags & ~(B3D_HARDWARE_RENDERER | B3D_SOFTWARE_RENDERER | B3D_STENCIL_BUFFER))
    {
      DPRINTF(1, (fp, "ERROR: Unsupported renderer flags (%d)\r", flags));
      return -1;
    }

  for (index= 0;  index < MAX_RENDERER;  ++index)
    if (!renderers[index].used)
      break;

  if (index == MAX_RENDERER)
    {
      DPRINTF(1, (fp, "ERROR: Maximum number of renderers (%d) exceeded\r", MAX_RENDERER));
      return -1;
    }

  renderer= renderers + index;
  renderer->drawable= 0;
  renderer->context=  0;
  
  DPRINTF(3, (fp, "---- Creating new renderer ----\r\r"));

  if ((w < 0) || (h < 0))
    {
      DPRINTF(1, (fp, "Negative extent (%i@%i)!\r", w, h));
      goto fail;
    }
  else
    if (dpy->ioGLcreateRenderer(renderer, x, y, w, h, flags))
      {
	renderer->used		= 1;
	renderer->bufferRect[0] = x;
	renderer->bufferRect[1] = y;
	renderer->bufferRect[2] = w;
	renderer->bufferRect[3] = h;
	if (!glMakeCurrentRenderer(renderer))
	  {
	    DPRINTF(1, (fp, "Failed to make context current\r"));
	    glDestroyRenderer(index);
	    return -1;
	  }
	DPRINTF(3, (fp, "\r### Renderer created! ###\r"));
	glDisable(GL_LIGHTING);
	glDisable(GL_COLOR_MATERIAL);
	glDisable(GL_BLEND);
	glDisable(GL_ALPHA_TEST);
	glEnable(GL_DITHER);
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_NORMALIZE);
	glDepthFunc(GL_LEQUAL);
	glClearDepth(1.0);
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
	glShadeModel(GL_SMOOTH);
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT, blackLight);
	glErrorCheck();

	return index;
      }

 fail:
  DPRINTF(1, (fp, "OpenGL initialization failed\r"));
  return -1;
}


glRenderer *glRendererFromHandle(int handle)
{
  DPRINTF(7, (fp, "Looking for renderer id: %i\r", handle));
  if ((handle >= 0) && (handle < MAX_RENDERER) && renderers[handle].used)
    return renderers + handle;
  return 0;
}


int glDestroyRenderer(int handle)
{
  glRenderer *renderer= glRendererFromHandle(handle);
  DPRINTF(3, (fp, "\r--- Destroying renderer ---\r"));
  if (renderer)
    {
      if (!glMakeCurrentRenderer(0))
	return 0;
      dpy->ioGLdestroyRenderer(renderer);
      renderer->drawable = 0;
      renderer->context  = 0;
      renderer->used     = 0;
    }
  return 1;
}


int glIsOverlayRenderer(int handle)
{
  return 1;
}


int glSwapBuffers(glRenderer *renderer)
{
  if (renderer && renderer->used)
    dpy->ioGLswapBuffers(renderer);
  return 1;
}


int glSetBufferRect(int handle, int x, int y, int w, int h)
{
  glRenderer *renderer= glRendererFromHandle(handle);

  if (renderer && glMakeCurrentRenderer(renderer) && (w > 0) && (h > 0))
    {
      renderer->bufferRect[0]= x;
      renderer->bufferRect[1]= y;
      renderer->bufferRect[2]= w;
      renderer->bufferRect[3]= h;
      dpy->ioGLsetBufferRect(renderer, x, y, w, h);
      return 1;
    }
  return 0;
}


/* Verbose level for debugging purposes:
   0 - print NO information ever
   1 - print critical debug errors
   2 - print debug warnings
   3 - print extra information
   4 - print extra warnings
   5 - print information about primitive execution
   ...
   10 - print information about each vertex and face
*/
int glSetVerboseLevel(int level)
{
  verboseLevel= level;
  return 1;
}


int glGetIntPropertyOS(int handle, int prop)
{
  GLint v;
  glRenderer *renderer= glRendererFromHandle(handle);

  if (renderer && glMakeCurrentRenderer(renderer))
    switch (prop)
      {
      case 1: /* backface culling */
	if (!glIsEnabled(GL_CULL_FACE))
	  return 0;
	glGetIntegerv(GL_FRONT_FACE, &v);
	switch (v)
	  {
	  case GL_CW:	return  1;
	  case GL_CCW:	return -1;
	  }
	break;

      case 2: /* polygon mode */
	glGetIntegerv(GL_POLYGON_MODE, &v);
	glErrorCheck();
	return v;

      case 3: /* point size */
	glGetIntegerv(GL_POINT_SIZE, &v);
	glErrorCheck();
	return v;

      case 4: /* line width */
	glGetIntegerv(GL_LINE_WIDTH, &v);
	glErrorCheck();
	return v;
      }
  return 0;
}


int glSetIntPropertyOS(int handle, int prop, int value)
{
  glRenderer *renderer= glRendererFromHandle(handle);

  if (renderer && glMakeCurrentRenderer(renderer))
    switch (prop)
      {
      case 1: /* backface culling */
	if (!value)
	  glDisable(GL_CULL_FACE);
	else
	  {
	    glEnable(GL_CULL_FACE);
	    glFrontFace((value == 1) ? GL_CCW : GL_CW);
	  }
	glErrorCheck();
	return 1;

      case 2: /* polygon mode */
	switch (value)
	  {
	  case 0:  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);	break;
	  case 1:  glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);	break;
	  case 2:  glPolygonMode(GL_FRONT_AND_BACK, GL_POINT);	break;
	  default: return 0;
	  }
	glErrorCheck();
	return 1;

      case 3: /* point size */
	glPointSize(value);
	glErrorCheck();
	return 1;

      case 4: /* line width */
	glLineWidth(value);
	glErrorCheck();
	return 1;
      }
  return 0;
}
