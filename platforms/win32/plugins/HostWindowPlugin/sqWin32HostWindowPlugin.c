/****************************************************************************
*   PROJECT: Squeak port for Win32
*   FILE:    sqWin32HostWindowPlugin.c
*   CONTENT: hostwindow support
*
*   AUTHORS:  Andreas Raab (ar) , Bernd Eckardt (be)
*   ADDRESS: Magdeburg, Germany
*   EMAIL:   andreas.raab@gmx.de, bernd.eckardt@impara.de
*****************************************************************************/

#include <Windows.h>

#if !defined(SQUEAK_BUILTIN_PLUGIN)
# error "HostWindowPlugin can only be compiled as an internal plugin"
#endif

#include "sqVirtualMachine.h"
#include "sq.h"
#include "HostWindowPlugin.h"

extern struct VirtualMachine *interpreterProxy;

/* Import from sqWin32Window.c */
extern int recordMouseEvent(MSG *msg, UINT nrClicks);
extern int recordKeyboardEvent(MSG *msg);
extern sqInputEvent *sqNextEventPut(void);

BITMAPINFO *BmiForDepth(int depth);
extern HINSTANCE hInstance;
extern MSG *lastMessage;

/* main window procedure(s) */
static LRESULT CALLBACK HostWndProcA(HWND hwnd,
                              UINT message,
                              WPARAM wParam,
                              LPARAM lParam)
{
  return DefWindowProc(hwnd, message, wParam, lParam);
}

static LRESULT CALLBACK HostWndProcW (HWND hwnd,
                              UINT message,
                              WPARAM wParam,
                              LPARAM lParam)
{
  RECT boundingRect;

 switch(message) {
  /*  mousing */

  case WM_MOUSEMOVE:
    recordMouseEvent(lastMessage,0);
    break;

  case WM_LBUTTONDOWN:
  case WM_RBUTTONDOWN:
  case WM_MBUTTONDOWN:
    if (GetFocus() != hwnd) SetFocus(hwnd);
    SetCapture(hwnd); /* capture mouse input */
    recordMouseEvent(lastMessage,1);
    break;

  case WM_LBUTTONUP:
  case WM_RBUTTONUP:
  case WM_MBUTTONUP:
    if (GetFocus() != hwnd) SetFocus(hwnd);
    ReleaseCapture(); /* release mouse capture */
    recordMouseEvent(lastMessage,1);
    break;


  /*keyboard events*/
  case WM_KEYDOWN:
  case WM_SYSKEYDOWN:
  case WM_KEYUP:
  case WM_SYSKEYUP:
  case WM_CHAR:
  case WM_SYSCHAR:
   recordKeyboardEvent(lastMessage);
   break;


  /*window events*/
  case WM_MOVE:
  case WM_SIZE:
    if ((GetWindowRect(hwnd, &boundingRect)) != 0){
      sqWindowEvent *windowevent = (sqWindowEvent*) sqNextEventPut();
      windowevent->type = EventTypeWindow;
      windowevent->timeStamp = lastMessage ? lastMessage->time : GetTickCount();
      windowevent->action = WindowEventMetricChange;
      windowevent->value1 = boundingRect.left ;
      windowevent->value2 = boundingRect.top;
      windowevent->value3 = boundingRect.right;
      windowevent->value4 = boundingRect.bottom;
      windowevent->windowIndex =(sqIntptr_t) hwnd;
    }
    break;

  case WM_PAINT:	
    if ((GetWindowRect(hwnd, &boundingRect)) != 0){
      sqWindowEvent *windowevent = (sqWindowEvent*) sqNextEventPut();
      windowevent->type = EventTypeWindow;
      windowevent->timeStamp = lastMessage ? lastMessage->time : GetTickCount();
      windowevent->action = WindowEventPaint;
      windowevent->value1 = boundingRect.left ;
      windowevent->value2 = boundingRect.top;
      windowevent->value3 = boundingRect.right;
      windowevent->value4 = boundingRect.bottom;
      windowevent->windowIndex =(sqIntptr_t) hwnd;
    }
    break;


  case WM_CLOSE:
    {
	sqWindowEvent *windowevent = (sqWindowEvent*) sqNextEventPut();
	windowevent->type = EventTypeWindow;
	windowevent->timeStamp = lastMessage ? lastMessage->time : GetTickCount();
	windowevent->action = WindowEventClose;
	windowevent->windowIndex =(sqIntptr_t) hwnd;
    }
    break;
	
  case WM_ACTIVATE:
    {
        sqWindowEvent *windowevent = (sqWindowEvent*) sqNextEventPut();
        windowevent->type = EventTypeWindow;
        windowevent->timeStamp = lastMessage ? lastMessage->time : GetTickCount();
        if (wParam == WA_INACTIVE) windowevent->action = WindowEventIconise;
        else windowevent->action = WindowEventActivated;
       	windowevent->windowIndex =(sqIntptr_t) hwnd;      
    }
    break; 
    	
  case WM_GETMINMAXINFO:
    {
        sqWindowEvent *windowevent = (sqWindowEvent*) sqNextEventPut();
        windowevent->type = EventTypeWindow;
        windowevent->timeStamp = lastMessage ? lastMessage->time : GetTickCount();
        if (IsIconic(hwnd) != 0)windowevent->action = WindowEventIconise;
        else windowevent->action = WindowEventActivated;
       	windowevent->windowIndex =(sqIntptr_t) hwnd;      
    }
    break;   
 }
 return DefWindowProcW(hwnd,message,wParam,lParam);
}

#define handleForIndex(winIndex) ((winIndex) == 1 ? stWindow : (HWND)(winIndex))

/* closeWindow: arg is int windowIndex. Fail (return 0) if anything goes wrong
 * - typically the windowIndex invalid or similar */
sqInt
closeWindow(sqIntptr_t windowIndex)
{
  HWND hwnd = handleForIndex(windowIndex);
  if (!IsWindow(hwnd))
	return 0;
  DestroyWindow(hwnd);
  return 1;
}

/* createWindow: takes int width, height and origin x/y plus a char* list of
 * as yet undefined attributes. Returns an int window index or 0 for failure
 * Failure may occur because of an inability to add the window, too many
 * windows already extant (platform dependant), the specified size being
 * unreasonable etc. */
sqInt
createWindowWidthheightoriginXyattrlength(sqInt w, sqInt h, sqInt x, sqInt y, char * list, sqInt attributeListLength)
{
  HWND hwnd;

  WNDCLASS wc;

  wc.style = CS_OWNDC; /* don't waste resources ;-) */
  wc.lpfnWndProc = (WNDPROC)HostWndProcA;
  wc.cbClsExtra = 0;
  wc.cbWndExtra = 0;
  wc.hInstance = hInstance;
  wc.hIcon = LoadIcon (hInstance, MAKEINTRESOURCE(2));
  wc.hCursor = NULL;
  wc.hbrBackground = GetStockObject (WHITE_BRUSH);
  wc.lpszMenuName = NULL;
  wc.lpszClassName = TEXT("SqueakHostWindowClass");

  /* Due to Win95 bug we have to ignore the return value
     of RegisterClass(). Win95 returns several strange
     error messages (such as ERR_FUNCTION_NOT_SUPPORTED)
     when the class is already registered (which should
     result in an ERR_CLASS_ALREADY_EXISTS) */
  RegisterClass(&wc);

  hwnd = CreateWindowEx(WS_EX_APPWINDOW /* | WS_EX_OVERLAPPEDWINDOW */,
			TEXT("SqueakHostWindowClass"),
			TEXT("Squeak!"),
			WS_VISIBLE | WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
			x,
			y,
			w,
			h,
			NULL,
			NULL,
			hInstance,
			NULL);

  /* Force Unicode WM_CHAR */
  SetWindowLongPtrW(hwnd,GWLP_WNDPROC,(usqIntptr_t)HostWndProcW);

  return (sqInt)hwnd;
}

/* ioShowDisplayOnWindow: similar to ioShowDisplay but adds the int windowIndex
 * Return true if ok, false if not, but not currently checked */
sqInt
ioShowDisplayOnWindow(unsigned char* dispBits, sqInt width, 
			    sqInt height, sqInt depth, sqInt affectedL, 
			    sqInt affectedR, sqInt affectedT, sqInt affectedB, 
			    sqIntptr_t windowIndex)
{
  HWND hwnd = handleForIndex(windowIndex);
  HDC dc;
  BITMAPINFO *bmi;
  int lines;
  int lsbDisplay;

  if (!IsWindow(hwnd))
    return 0;

  if (affectedR < affectedL || affectedT > affectedB)
    return 1;

  /* Careful here:
     After resizing the main window the affected area can
     be larger than the area covered by the display bits ... */
  if (affectedR > width) affectedR= width-1;
  if (affectedB > height) affectedB= height-1;
  /* ... and don't forget left and top - else reverse_image_* will crash */
  if (affectedL > width) affectedL= width-1;
  if (affectedT > height) affectedT= height-1;

  /* Don't draw empty areas */
  if (affectedL == affectedR || affectedT == affectedB)
	return 1;
  /* reload the update rectangle */
  updateRect.left = affectedL;
  updateRect.top = affectedT;
  updateRect.right = affectedR;
  updateRect.bottom = affectedB;
  /* ----- EXPERIMENTAL ----- */
  lsbDisplay = depth < 0;
  if (lsbDisplay) depth = -depth;

  bmi = BmiForDepth(depth);
  if (!bmi)
  	return 0;

  /* reverse the image bits if necessary */

  if ( !lsbDisplay && depth < 32 ) {
    if (depth == 16)
      reverse_image_words((unsigned int*) dispBits, (unsigned int*) dispBits,
			  depth, width, &updateRect);
    else
      reverse_image_bytes((unsigned int*) dispBits, (unsigned int*) dispBits,
			  depth, width, &updateRect);
  }
  bmi->bmiHeader.biWidth = width;
  bmi->bmiHeader.biHeight = -height;
  bmi->bmiHeader.biSizeImage = 0;

  dc = GetDC(hwnd);
  if (!dc) {
    printLastError(TEXT("ioShowDisplayBits: GetDC() failed"));
    return 0;
  }


  lines = SetDIBitsToDevice(dc,
  	    0, /* dst_x */
  	    0, /* dst_y */
  	    width,  /* dst_w */
  	    height, /* dst_h */
  	    0, /* src_x */
  	    0, /* src_y */
  	    0, /* start scan line in DIB */
  	    height, /* num scan lines in DIB */
	    (void*) dispBits,  /* bits */
	    bmi,
	    DIB_RGB_COLORS);

  if (lines == 0) {
    /* Note: the above is at least five times faster than what follows.
       Unfortunately, it also requires quite a bit of resources to
       be available. These are almost always available except in a
       few extreme conditions - but to compensate for those the
       following is provided. */
    int pitch, start, end, nPix, line, left;
    sqIntptr_t bitsPtr;

    /* compute pitch of form */
    pitch = (((width * depth) + 31) & ~31) / 8;
    /* compute first word of update region */
    start = ((updateRect.left * depth) & ~31) / 8;
    /* compute last word of update region */
    end   = (((updateRect.right * depth) + 31) & ~31) / 8;
    /* compute #of bits covered in update region */
    nPix = ((end - start) * 8) / depth;
    left = (start * 8) / depth;
    bmi->bmiHeader.biWidth = nPix;
    bmi->bmiHeader.biHeight = 1;
    bmi->bmiHeader.biSizeImage = 0;
    bitsPtr = (sqIntptr_t) dispBits + start + (updateRect.top * pitch);
    for(line = updateRect.top; line < updateRect.bottom; line++) {
      lines = SetDIBitsToDevice(dc, left, line, nPix, 1, 0, 0, 0, 1,
				(void*) bitsPtr, bmi, DIB_RGB_COLORS);
      bitsPtr += pitch;
    }
  }

  ReleaseDC(hwnd,dc);

  if (lines == 0) {
    printLastError(TEXT("SetDIBitsToDevice failed"));
#if _UNICODE
    warnPrintfW(TEXT("width=%" PRIdSQINT ",height=%" PRIdSQINT ",bits=%" PRIXSQPTR ",dc=%" PRIXSQPTR "\n"),
#else
    warnPrintf(TEXT("width=%" PRIdSQINT ",height=%" PRIdSQINT ",bits=%" PRIXSQPTR ",dc=%" PRIXSQPTR "\n"),
#endif
	       width, height, (usqIntptr_t)dispBits, (usqIntptr_t)dc);
  }
  /* reverse the image bits if necessary */

  if ( !lsbDisplay && depth < 32 ) {
    if (depth == 16)
      reverse_image_words((unsigned int*) dispBits, (unsigned int*) dispBits,
			  depth, width, &updateRect);
    else
      reverse_image_bytes((unsigned int*) dispBits, (unsigned int*) dispBits,
			  depth, width, &updateRect);
  }
  return 1;
}


/* ioSizeOfWindow: arg is int windowIndex. Return the size of the specified
 * window in (width<<16 | height) format like ioScreenSize.
 * Return -1 for failure - typically invalid windowIndex
 * -1 is chosen since itwould correspond to a window size of 64k@64k which
 * I hope is unlikely for some time to come */
sqInt
ioSizeOfWindow(sqIntptr_t windowIndex)
{
  HWND hwnd = handleForIndex(windowIndex);
  RECT boundingRect;
  int wsize;

  if ((GetWindowRect(hwnd, &boundingRect)) != 0){

    wsize = ((boundingRect.right - boundingRect.left) << 16)| (boundingRect.bottom - boundingRect.top);
    return wsize;
  }
  return -1;
}

#if TerfVM
/* ioSizeOfNativeWindow: arg is void* windowHandle, defined as usqIntptr_t
 * for convenience. Return the size of the specified native window in
 * (width<<16 | height) format like ioScreenSize.
 * Return -1 for failure - typically invalid windowHandle
 * -1 is chosen since it would correspond to a window size of +/-32k@+/-32k
 * which it is hoped is unlikely for some time to come */
sqInt
ioSizeOfNativeWindow(usqIntptr_t windowHandle)
{
	RECT boundingRect;

	return GetWindowRect((HWND)windowHandle, &boundingRect)
		? ((boundingRect.right - boundingRect.left) << 16)
			| ((boundingRect.bottom - boundingRect.top) & 0xFFFF)
		: -1;
}

sqInt
ioSizeOfNativeDisplay(usqIntptr_t windowHandle)
{
	RECT boundingRect;

	return GetClientRect((HWND)windowHandle, &boundingRect)
		? ((boundingRect.right - boundingRect.left) << 16)
			| ((boundingRect.bottom - boundingRect.top) & 0xFFFF)
		: -1;
}
#endif /* TerfVM */

/* ioSizeOfWindowSetxy: args are int windowIndex, int w & h for the
 * width / height to make the window. Return the actual size the OS
 * produced in (width<<16 | height) format or -1 for failure as above. */
sqInt
ioSizeOfWindowSetxy(sqIntptr_t windowIndex, sqInt w, sqInt h)
{
  HWND hwnd = handleForIndex(windowIndex);
  RECT boundingRect;
 
  if (!GetWindowRect(hwnd, &boundingRect)
   || !MoveWindow(hwnd,
		 boundingRect.left, boundingRect.top,
		 w, h,
		 TRUE))
	return -1;
  return ioSizeOfWindow(windowIndex);
}

/* ioPositionOfWindow: arg is int windowIndex. Return the pos of the specified
 * window in (left<<16 | top) format like ioScreenSize.
 * Return -1 (as above) for failure - tpyically invalid windowIndex */
sqInt
ioPositionOfWindow(sqIntptr_t windowIndex)
{
  HWND hwnd = handleForIndex(windowIndex);
  RECT boundingRect;

	return GetWindowRect(hwnd, &boundingRect)
		? (boundingRect.left << 16) | boundingRect.top
		: -1;
}

#if TerfVM
/* ioPositionOfNativeWindow: arg is void* windowHandle, defined as usqIntptr_t
 * for convenience. Return the pos of the specified native window in
 * (left<<16 | top) format like ioScreenSize (& ioPositionOfWindow).
 * Return -1 (as above) for failure - typically invalid windowHandle */
sqInt
ioPositionOfNativeWindow(usqIntptr_t windowHandle)
{
	RECT boundingRect;

	return GetWindowRect((HWND)windowHandle, &boundingRect)
		? (boundingRect.left << 16) | boundingRect.top
		: -1;
}

sqInt
ioPositionOfNativeDisplay(usqIntptr_t windowHandle)
{
	RECT boundingRect;
	WINDOWINFO wi;
	int insideHeight, windowHeight, titleHeight, x, y;

	wi.cbSize = sizeof(wi);
	GetWindowInfo((HWND)windowHandle, &wi);
	DPRINTF("rcWindow %d@%d corner: %d@%d\n",
			wi.rcWindow.left, wi.rcWindow.top,
			wi.rcWindow.right, wi.rcWindow.bottom);
	DPRINTF("rcClient %d@%d corner: %d@%d\n",
			wi.rcClient.left, wi.rcClient.top,
			wi.rcClient.right, wi.rcClient.bottom);
	DPRINTF("cxWindowBorders %d cyWindowBorders %d\n",
			wi.cxWindowBorders, wi.cyWindowBorders);

	if (!GetWindowRect((HWND)windowHandle, &boundingRect))
		return -1;
	windowHeight = wi.rcWindow.bottom - wi.rcWindow.top;
	insideHeight = wi.rcClient.bottom - wi.rcClient.top;
	titleHeight = windowHeight - insideHeight - wi.cyWindowBorders;
	x = boundingRect.left + wi.cxWindowBorders;
	y = boundingRect.top + titleHeight;
	return (x << 16) | (short)y;
}
#endif /* TerfVM */

/* ioPositionOfWindowSetxy: args are int windowIndex, int x & y for the
 * origin x/y for the window. Return the actual origin the OS
 * produced in (left<<16 | top) format or -1 for failure, as above */
sqInt
ioPositionOfWindowSetxy(sqIntptr_t windowIndex, sqInt x, sqInt y)
{
  HWND hwnd = handleForIndex(windowIndex);
  RECT boundingRect;

  if (!GetWindowRect(hwnd, &boundingRect)
   || !MoveWindow(hwnd, x, y,
		 boundingRect.right - boundingRect.left,
		 boundingRect.bottom - boundingRect.top,
		 TRUE))
	return -1;
  return ioPositionOfWindow(windowIndex);
}

/* ioSetTitleOfWindow: args are int windowIndex, char* newTitle and
 * int size of new title. Fail with -1 if windowIndex is invalid, string is too long for platform etc. Leave previous title in place on failure */
sqInt
ioSetTitleOfWindow(sqIntptr_t windowIndex, char * newTitle, sqInt sizeOfTitle)
{
  HWND hwnd = handleForIndex(windowIndex);
  char titleString[1024];
  WCHAR wideTitle[1024];

  if (!IsWindow(hwnd)) return 0;
  if (sizeOfTitle > 1023) sizeOfTitle = 1023;
  strncpy(titleString, newTitle, sizeOfTitle);
  titleString[sizeOfTitle] = 0;
  MultiByteToWideChar(CP_UTF8, 0, titleString, -1, wideTitle, 1024);
  if (SetWindowTextW(hwnd, wideTitle) == 0) return -1;
  return sizeOfTitle;
}

/* ioSetIconOfWindow: args are int windowIndex, char* iconPath and
 * int size of new logo path. If one of the function is failing, the logo is not set.
 */
sqInt
ioSetIconOfWindow(sqIntptr_t windowIndex, char * iconPath, sqInt sizeOfPath)
{
	WCHAR iconPathW[MAX_PATH + 1];
	HWND hwnd = handleForIndex(windowIndex);
	int len;
	if (!IsWindow(hwnd)) return 0;
	len = MultiByteToWideChar(CP_UTF8, 0, iconPath, sizeOfPath, iconPathW, MAX_PATH);
	if (len <= 0) return -1; /* invalid UTF8 ? */
	iconPathW[len] = 0;
	//Check if file exists and have read rights
	if (_waccess(iconPathW, 4) == -1)
		return -1;
	//Load the image into an icon
	HICON hIcon = (HICON)LoadImageW(NULL, iconPathW, IMAGE_ICON, 0, 0, LR_LOADFROMFILE);
	if (hIcon == 0)
		return -2;
	SendMessage(hwnd, WM_SETICON, ICON_BIG, (LONG_PTR)hIcon); 
	return 0;
}


/* ioCloseAllWindows: intended for VM shutdown.
 * Close all the windows that appear to be open.
 * No useful return value since we're getting out of Dodge anyway.
 */
sqInt
ioCloseAllWindows(void){ return 0; }

sqInt
ioSetCursorPositionXY(long x, long y)
{
	return SetCursorPos(x,y)
		? 0
		: -1;
}

#if TerfVM
/* Return the pixel origin (topleft) of the platform-defined working area
   for the screen containing the given window. */
sqInt
ioPositionOfScreenWorkArea (sqIntptr_t windowIndex)
{
	HMONITOR hMonitor;
	MONITORINFO mi;
	RECT workArea;
  	hMonitor = MonitorFromWindow ((HWND) windowIndex, MONITOR_DEFAULTTONEAREST);
	mi.cbSize = (sizeof(mi));
	GetMonitorInfo(hMonitor, &mi);
	workArea = mi.rcWork;
	return (workArea.left << 16) | (workArea.top & 0xFFFF);
}

/* Return the pixel extent of the platform-defined working area
   for the screen containing the given window. */
sqInt
ioSizeOfScreenWorkArea (sqIntptr_t windowIndex)
{
	HMONITOR hMonitor;
	MONITORINFO mi;
	RECT workArea;
  	hMonitor = MonitorFromWindow ((HWND) windowIndex, MONITOR_DEFAULTTONEAREST);
	mi.cbSize = (sizeof(mi));
	GetMonitorInfo(hMonitor, &mi);
	workArea = mi.rcWork;
	return ((workArea.right - workArea.left) << 16) | ((workArea.bottom - workArea.top) & 0xFFFF);
}

static sqInt result, monitorIdx;
static BOOL
enumMonitor(HMONITOR monitor, HDC dc, LPRECT rect, LPARAM store)
{
	if (store) {
		storeIntegerofObjectwithValue
			(monitorIdx, result, packedXY(rect->left,rect->top));
		storeIntegerofObjectwithValue
			(monitorIdx+1, result, packedXY(rect->right - rect->left,rect->bottom - rect->top));
	}
	monitorIdx = monitorIdx + 2;
	return 1;
}

/* Answer an Array of screen coordinates as pairs of packed points, origin,
 * extent for each screen. So if there is one monitor the array has two entries.
 */
sqInt
ioScreenRectangles(void)
{
	monitorIdx = 0;
	EnumDisplayMonitors(0,0,enumMonitor,0);
	if ((result = instantiateClassindexableSize(classArray(),monitorIdx))) {
		monitorIdx = 0;
		EnumDisplayMonitors(0,0,enumMonitor,1);
	}
	return result;
}
#endif /* TerfVM */
