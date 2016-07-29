/****************************************************************************
*   PROJECT: Squeak Win32 port
*   FILE:    sqWin32DirectInput.c
*   CONTENT: Win32 specific support for DirectInput
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Impara GmbH, Magdeburg, Germany
*   EMAIL:   Andreas.Raab@impara.de
*
*   NOTES:
*     The function enclosed here provide direct support to the
*     mouse driver using DirectInput. This allows us to get accurate
*     mouse information even if Squeak is in a busy-loop or primitive.
*     Note that due to talking to the driver directly we need to take
*     different resolutions of the input devices into account
*     (e.g., Windows map the input from the driver through its internal
*     settings which means that the relative information we get is
*     extremely relative indeed). We deal with this problem by
*     remapping any mouse events into the input we have received
*     from Windows.
*
*****************************************************************************/
#ifndef NO_DIRECTINPUT

#ifndef DIRECTINPUT_VERSION
#define DIRECTINPUT_VERSION 0x700 /* restrict to DX7 */
#endif 

#include <windows.h>
#include <ole2.h>
#include "sq.h"
#ifdef __MINGW32__
#define HMONITOR_DECLARED
#undef WINNT
#endif

#include <dinput.h>
#include <stdio.h>
#include <math.h>

sqInputEvent *sqNextEventPut();

#define BUFFER_SIZE 100
static int xData[BUFFER_SIZE];
static int yData[BUFFER_SIZE];
static int stampData[BUFFER_SIZE];
static int printDebugMessages = 0;

IDirectInput            *lpDI = NULL;
IDirectInputDevice      *lpDev = NULL;

#define ERROR_CHECK(hResult, errMsg) \
if(FAILED(hResult)) { \
  if(printDebugMessages) printf("%s (%s, %d)\n", errMsg, __FILE__, __LINE__); \
  return hResult; \
}

HRESULT InitDirectInput( HANDLE hInstance, HWND hWnd )
{
  HRESULT hr;
  DIPROPDWORD propWord;

  /* connect to direct input */
#if DIRECTINPUT_VERSION >= 0x0800
  hr = DirectInput8Create( hInstance, DIRECTINPUT_VERSION,  &IID_IDirectInput8, &lpDI, NULL ); /* require dinput8.lib */
#else
  hr = DirectInputCreate( hInstance, DIRECTINPUT_VERSION, &lpDI, NULL ); /* require dinput.lib */
#endif
  ERROR_CHECK(hr, "Error creating DirectInput object");

  /* get the mouse */
  hr = lpDI->lpVtbl->CreateDevice(lpDI, &GUID_SysMouse, &lpDev, NULL );
  ERROR_CHECK(hr, "Error creating DirectDevice object (mouse)");

  /* tell it to get us mouse format data */
  hr = lpDev->lpVtbl->SetDataFormat(lpDev, &c_dfDIMouse );
  ERROR_CHECK(hr, "Error setting data format");

  /* be quite cooperative */
  hr = lpDev->lpVtbl->SetCooperativeLevel(lpDev, 
					  hWnd, 
					  DISCL_NONEXCLUSIVE | 
					  DISCL_BACKGROUND);
  ERROR_CHECK(hr, "Error setting cooperative level");

  /* setup buffer size */
  propWord.diph.dwSize = sizeof(DIPROPDWORD);
  propWord.diph.dwHeaderSize = sizeof(DIPROPHEADER);
  propWord.diph.dwObj = 0;
  propWord.diph.dwHow = DIPH_DEVICE;
  propWord.dwData = BUFFER_SIZE;

  hr = lpDev->lpVtbl->SetProperty(lpDev, DIPROP_BUFFERSIZE, &propWord.diph );
  ERROR_CHECK(hr, "Error setting input buffer size");

  /* try to aquire the device right away */
  lpDev->lpVtbl->Acquire(lpDev);

  return S_OK;
}

HRESULT FreeDirectInput()
{
  if(lpDev != NULL) {
    lpDev->lpVtbl->Unacquire(lpDev);
    lpDev->lpVtbl->Release(lpDev);
    lpDev = NULL;
  }
  if(lpDI != NULL) {
    lpDI->lpVtbl->Release(lpDI);
    lpDI = NULL;
  }
  return S_OK;
}

/* dump all buffered mouse input */
void DumpBufferedMouseTrail(void) {
  DIDEVICEOBJECTDATA  data;
  DWORD               count;
  HRESULT             hr;

  if(!lpDev) return;
  while(1) {
    count = 1;
    hr = lpDev->lpVtbl->GetDeviceData(lpDev,
				      sizeof(DIDEVICEOBJECTDATA), 
				      &data,
				      &count,
				      0);

    if (hr == DIERR_INPUTLOST) {
      /* re-aquire the device if possible */
      hr = lpDev->lpVtbl->Acquire(lpDev);
      if(FAILED(hr) || hr == S_FALSE) {
	/* sorry, can't do it */
	break;
      }
      continue; /* start over reading */
    }

    if(FAILED(hr) || count == 0) {
      /* no data or error */
      break;
    }
  }
}

/* get pending input from the device up to the baseEvt*/
void GetBufferedMouseTrail(DWORD firstTick, DWORD lastTick, 
			   sqMouseEvent *proto) 
{
  DIDEVICEOBJECTDATA  data;
  DWORD               count, seqNum, timeStamp;
  HRESULT             hr;

  sqMouseEvent *evt;
  static int lastX = 0;
  static int lastY = 0;
  static int nextX = 0;
  static int nextY = 0;
  int numExtra;

  /* printf("[%d@%d] -- %d\n", x, y, lastTick - firstTick);*/

  if(!lpDev) return;

  seqNum = 0;
  nextX = lastX;
  nextY = lastY;
  numExtra = 0;

  while(1) {
    count = 1;
    hr = lpDev->lpVtbl->GetDeviceData(lpDev,
				      sizeof(DIDEVICEOBJECTDATA), 
				      &data,
				      &count,
				      0);

    if (hr == DIERR_INPUTLOST) {
      /* re-aquire the device if possible */
      hr = lpDev->lpVtbl->Acquire(lpDev);
      if(FAILED(hr) || hr == S_FALSE) {
	/* sorry, can't do it */
	break;
      }
      continue; /* start over reading */
    }

    if(FAILED(hr) || count == 0) {
      /* no data or error */
      break;
    }

    /* if data arrived before first tick, ignore it */
    if(data.dwTimeStamp <= firstTick) continue;

    /* if data arrives at or after last tick, we're done */
    if(data.dwTimeStamp >= lastTick) break;

    /* otherwise process it */
    switch (data.dwOfs) {
      case DIMOFS_X:
      case DIMOFS_Y:
	if(seqNum != 0 && seqNum != data.dwSequence) {
	  /* flush last event */
	  if(numExtra < BUFFER_SIZE) {
	    xData[numExtra] = nextX;
	    yData[numExtra] = nextY;
	    stampData[numExtra] = timeStamp;
	    numExtra++;
	  }
	  /* printf("(%d)%d@%d\n", timeStamp - firstTick, x, y); */
	}
	timeStamp = data.dwTimeStamp;
	seqNum = data.dwSequence;
	if(data.dwOfs == DIMOFS_X) {
	  nextX += (int)data.dwData;
	} else {
	  nextY += (int)data.dwData;
	}
	break;
      /* ignore all buttons */
      case DIMOFS_BUTTON0:
      case DIMOFS_BUTTON1:
      case DIMOFS_BUTTON2:
      case DIMOFS_BUTTON3:
	break;
    }
  }

  if(seqNum != 0 && (numExtra < BUFFER_SIZE)) {
    xData[numExtra] = nextX;
    yData[numExtra] = nextY;
    stampData[numExtra] = timeStamp;
    numExtra++;
  }
  if(numExtra > 0) {
    int i;
    /* check if lastX and lastY match what we got from the proto event.
       we need this as windows settings can affect the mouse events,
       and we really want to fill the stuff obtained here so that it
       matches in/out as close as possible. */
    if(nextX != proto->x || nextY != proto->y) {
      /* rescale the trail to fit proto's expectations */
      int protoDx = proto->x - lastX;
      int protoDy = proto->y - lastY;
      int trailDx = nextX - lastX;
      int trailDy = nextY - lastY;

      for(i=0; i<numExtra;i++) {
	xData[i] = MulDiv(xData[i]-lastX, protoDx, trailDx) + lastX;
	yData[i] = MulDiv(yData[i]-lastY, protoDy, trailDy) + lastY;
      }
    }
    /* create the trail events */
    for(i=0; i<numExtra;i++) {
      evt = (sqMouseEvent*) sqNextEventPut();
      *evt = *proto;
      evt->x = xData[i];
      evt->y = yData[i];
      evt->timeStamp = stampData[i];
    }
  }
  /* remember x and y */
  lastX = proto->x;
  lastY = proto->y;
}

void SetupDirectInput(void) {
  HRESULT hr;
  FreeDirectInput();
  hr = InitDirectInput(hInstance, stWindow);
  if(FAILED(hr)) {
    FreeDirectInput();
  }
}

#endif /* NO_DIRECTINPUT */
