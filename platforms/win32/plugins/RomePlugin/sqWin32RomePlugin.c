/****************************************************************************
*   PROJECT: Squeak port for Win32
*   FILE:    sqWin32RomePlugin.c
*   CONTENT: cairo support
*
*   AUTHORS:  Bernd Eckardt (be)
*   ADDRESS: Magdeburg, Germany
*   EMAIL:   bernd.eckardt@impara.de
*****************************************************************************/

#include <windows.h>
#include "sq.h"
#include <cairo.h>
#include "RomePlugin.h"



cairo_surface_t* createSurfaceFromWindowHandle(int windowIndex)
{
  HWND wnd = (HWND)windowIndex;
  HDC windowDC;
  cairo_surface_t* newSurface;
  cairo_t * cr;
  cairo_status_t err;

  windowDC = GetDC(wnd);  
  if(!windowDC){
    return 0;
  }

  newSurface = cairo_win32_surface_create (windowDC);
  err = cairo_surface_status (newSurface);
  if (err) return 0;
  return newSurface;
}


