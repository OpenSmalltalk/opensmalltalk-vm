/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Window.c
*   CONTENT: Window management
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*
*   NOTES:
*    1) Currently supported Squeak color depths include 1,4,8,16,32 bits
*    2) To speed up drawing a slight update delay has been added (Toggle with F2)
*    3) The modifier keys are mapped as follows:
*
*        Mac    |  Win32
*       --------------------
*       Shift   -> Shift
*       Ctrl    -> Ctrl
*       Command -> Left ALT
*       Option  -> Right ALT
*
*****************************************************************************/
#include <windows.h>
#include <shellapi.h>
#include <commdlg.h>
#include <excpt.h>

#if defined(__MINGW32_VERSION) && (__MINGW32_MAJOR_VERSION < 3)
/** Kludge to get multimonitor API's to compile in the mingw/directx7 mix. **/
/** Not needed in cygwin **/
# define COMPILE_MULTIMON_STUBS
# undef SM_CMONITORS
# define HMONITOR_DECLARED
# include "multimon.h"
#endif /* defined(__MINGW32_VERSION) && (__MINGW32_MAJOR_VERSION < 3) */

#include "sq.h"
#include "sqWin32Prefs.h"
#include "sqSCCSVersion.h"

/****************************************************************************/
/* General Squeak declarations and definitions                              */
/****************************************************************************/

/* Import from DropPlugin/sqWin32Drop.c */
void SetupDragAndDrop(void);
int dropLaunchFile(char *fileName);

/* Import from VM */
void setInterruptPending(sqInt);
sqInt forceInterruptCheck(void);
sqInt getInterruptKeycode(void);
void setFullScreenFlag(sqInt);
sqInt getSavedWindowSize(void);
extern sqInt deferDisplayUpdates;


/*** Variables -- image and path names ***/
#define IMAGE_NAME_SIZE MAX_PATH

char imageName[MAX_PATH+1];		  /* full path and name to image */
TCHAR imagePath[MAX_PATH+1];	  /* full path to image */
TCHAR vmPath[MAX_PATH+1];		    /* full path to interpreter's directory */
TCHAR vmName[MAX_PATH+1];		    /* name of the interpreter's executable */
TCHAR windowTitle[MAX_PATH];        /* what should we display in the title? */
TCHAR squeakIniName[MAX_PATH+1];    /* full path and name to ini file */
TCHAR windowClassName[MAX_PATH+1];        /* Window class name */

const TCHAR U_ON[]  = TEXT("1");
const TCHAR U_OFF[] = TEXT("0");
const TCHAR U_GLOBAL[] = TEXT("Global");
const TCHAR U_SLASH[] = TEXT("/");
const TCHAR U_BACKSLASH[] = TEXT("\\");

/*** Variables -- Event Recording ***/
int inputSemaphoreIndex = 0;/* if non-zero the event semaphore index */
POINT mousePosition;		/* position at last PointerMotion event */
int   mouseWord;			/* Input word for Squeak */
int   buttonState = 0;		/* mouse button and modifier state when mouse
							   button went down or 0 if not pressed */
DWORD winButtonState = 0;

#define KEYBUF_SIZE 64
int keyBuf[KEYBUF_SIZE];	/* circular buffer */
int keyBufGet = 0;			/* index of next item of keyBuf to read */
int keyBufPut = 0;			/* index of next item of keyBuf to write */
int keyBufOverflows = 0;	/* number of characters dropped */

/*** Win32-related Variables (declared in sqWin32.h) ***/
HWND stWindow = NULL;      /*	the squeak window */
HWND browserWindow = NULL; /* The browser window */
HINSTANCE hInstance;	     /*	the instance of squeak running */
HCURSOR currentCursor=0;	 /*	current cursor displayed by squeak */
HPALETTE palette;	         /*	the palette (might be unused) */
LOGPALETTE *logPal;	       /*	the logical palette definition */
BITMAPINFO *bmi1;	         /*	1 bit depth bitmap info */
BITMAPINFO *bmi4;	         /*	4 bit depth bitmap info */
BITMAPINFO *bmi8;	         /*	8 bit depth bitmap info */
BITMAPINFO *bmi16;	       /*	16 bit depth bitmap info */
BITMAPINFO *bmi32;	       /*	32 bit depth bitmap info */
BOOL fWindows95;           /* Are we running on Win95 or NT? */
BOOL fHasFocus = 0;        /* if Squeak has the input focus */

/* Preference values */
BOOL fDeferredUpdate = 1; /* I prefer the deferred update*/
BOOL fShowConsole = 0;    /* do we show the console window?*/
BOOL fDynamicConsole = 1; /* Should we show the console if any errors occur? */
BOOL fShowAllocations = 0; /* Show allocation activity */
BOOL fReduceCPUUsage = 1; /* Should we reduce CPU usage? */
BOOL fReduceCPUInBackground = 0; /* Should we reduce CPU usage when not active? */
BOOL fUseDirectSound = 1; /* Do we use DirectSound?! */
BOOL fRunSingleApp = 0;   /* Do we allow only one instance of this VM? */

#ifdef CROQUET
BOOL fUseOpenGL = 1;      /* Do we use OpenGL vs. D3D?! */
#else /* Squeak */
BOOL fUseOpenGL = 0;      /* Do we use OpenGL vs. D3D?! */
#endif

BOOL fPriorityBoost = 1;

BOOL f1ButtonMouse = 0;   /* Should we use a 1 button mouse mapping? */
BOOL f3ButtonMouse = 0;   /* Should we use a real 3 button mouse mapping? */

/* Startup options */
BOOL  fHeadlessImage = 0;      /* Do we run headless? */
BOOL  fRunService = 0;         /* Do we run as NT service? */
DWORD dwMemorySize = 0;        /* How much memory do we use? */
BOOL  fBrowserMode = 0;        /* Are we running in a web browser? */

/* Misc preferences */
BOOL  fEnableAltF4Quit = 1; /* can we quit using Alt-F4? */
BOOL  fEnableF2Menu = 1;    /* can we get prefs menu via F2? */
BOOL  fEnablePrefsMenu = 1; /* can we get a prefs menu at all? */

HANDLE vmWakeUpEvent = 0;      /* wake up interpret() from sleep */

/* variables for cached display */
RECT updateRect;		     /*	the rectangle to update */
HRGN updateRgn;	     	     /*	the region to update (more accurate) */
BOOL updateRightNow;	     /*	update flag */
HWND  consoleWindow;       /* console */
int wasFullScreen = 0;       /* are in fullscreen mode? */
int shouldBeFullScreen = 0;  /* or should we be in fullscreen mode? */

/* variables for DirectX support */
RECT stWindowRect;			/* Client rectangle in screen coordinates */

#ifndef NO_PRINTER
/* printer settings */
PRINTDLG printValues;
static int printerSetup = FALSE;
#endif

#ifndef NO_WHEEL_MOUSE
UINT g_WM_MOUSEWHEEL = 0;	/* RvL: 1999-04-19 The message we receive from wheel mices */
#endif

/* misc declarations */
int recordMouseEvent(MSG *msg, UINT nrClicks);
int recordKeyboardEvent(MSG *msg);
int recordWindowEvent(int action, RECT *r);

extern sqInt byteSwapped(sqInt);
extern int convertToSqueakTime(SYSTEMTIME);
int recordMouseDown(WPARAM, LPARAM);
int recordModifierButtons();
int recordKeystroke(UINT,WPARAM,LPARAM);
int recordVirtualKey(UINT,WPARAM,LPARAM);
void recordMouse(void);
void SetSystemTrayIcon(BOOL on);
void HideSplashScreen(void);

sqInputEvent *sqNextEventPut(void);
int sqLaunchDrop(void);

#ifdef PharoVM
/**
 * HACK: Hook for SDL2.
 */
static void (*ioCheckForEventsHooks)(void);

EXPORT(void) setIoProcessEventsHandler(void * handler) {
    ioCheckForEventsHooks = (void (*)())handler;
}
#endif

/****************************************************************************/
/*                      Synchronization functions                           */
/****************************************************************************/

/* NOTE: Why do we need this? When running multi-threaded code such as in
         the networking code and in midi primitives
         we will signal the interpreter several semaphores. 
 	 (Predates the internal synchronization of signalSemaphoreWithIndex ()) */

int synchronizedSignalSemaphoreWithIndex(int semaIndex)
{ 
  int result;

  /* Do our job - this is now synchronized in signalSemaphoreWithIndex */
  result = signalSemaphoreWithIndex(semaIndex);
  /* wake up interpret() if sleeping */
  SetEvent(vmWakeUpEvent);
  return result;
}



/****************************************************************************/
/*                   Message Processing                                     */
/****************************************************************************/

/* The last dispatched event. It is used for the event processing mechanism. */
MSG *lastMessage = NULL;

/* The entry to the message hooks called from the window procedure.
   If another module requires to process messages by itself, it should
   put its message procedure in this place. */
messageHook firstMessageHook = 0;

/* The entry to a pre-message hook. Can be used to intercept any messages
   to the squeak main window. Useful for modules that wish to be notified
   about certain messages before they are processed. */
messageHook preMessageHook = 0;

/* main window procedure(s) */
LRESULT CALLBACK MainWndProcA(HWND hwnd,
                              UINT message,
                              WPARAM wParam,
                              LPARAM lParam) {
  return DefWindowProc(hwnd, message, wParam, lParam);
}

LRESULT CALLBACK MainWndProcW(HWND hwnd,
                              UINT message,
                              WPARAM wParam,
                              LPARAM lParam)
{ 
  PAINTSTRUCT ps;
  static UINT lastClickTime = 0;
  static UINT nrClicks = 0;
  UINT timeNow = 0;
  UINT timeDelta = 0;

  /* Intercept any messages if wanted */
  if(preMessageHook)
    if((*preMessageHook)(hwnd, message,wParam, lParam))
       return 1;

  if(message == SQ_LAUNCH_DROP) 
    return sqLaunchDrop();

#ifndef NO_WHEEL_MOUSE
  /* RvL 1999-04-19 00:23
     MOUSE WHEELING START */
  if( WM_MOUSEWHEEL == message || g_WM_MOUSEWHEEL == message ) {
    /* Record mouse wheel msgs as CTRL-Up/Down */
    short zDelta = (short) HIWORD(wParam);
    if(inputSemaphoreIndex) {
      sqKeyboardEvent *evt = (sqKeyboardEvent*) sqNextEventPut();
      evt->type = EventTypeKeyboard;
      evt->timeStamp = lastMessage->time;
      evt->charCode = (zDelta > 0) ? 30 : 31;
      evt->pressCode = EventKeyChar;
      evt->modifiers = CtrlKeyBit;
#ifdef PharoVM
     evt->utf32Code = evt->charCode;
#else
      evt->utf32Code = 0;
#endif
      evt->reserved1 = 0;
    } else {
      buttonState = 64;
      if (zDelta < 0) {
	recordVirtualKey(message,VK_DOWN,lParam);
      } else {
	recordVirtualKey(message,VK_UP,lParam);
      }
    }
    return 1;
  }
  /* MOUSE WHEELING END */
#endif

  switch(message) {
  case WM_SYSCOMMAND:
  case WM_COMMAND: {
    int cmd = wParam & 0xFFF0;
    if(cmd >= ID_PREF_FIRST && cmd <= ID_PREF_LAST) {
      HandlePrefsMenu(cmd);
      break;
    }
#if !defined(_WIN32_WCE)
    if(cmd == SC_MINIMIZE) {
      if(fHeadlessImage) ShowWindow(stWindow, SW_HIDE);
      else return DefWindowProcW(hwnd, message, wParam, lParam);
      break;
    }
#endif /* defined(_WIN32_WCE) */
    if(cmd == SC_CLOSE) {
#if NewspeakVM
		/* Newspeak doesn't easnt to quit if the main window is closed.  Only
		 * when the last native window is closed.
		 */
		if(fEnableAltF4Quit)
			ShowWindow(stWindow, SW_HIDE);
#else
		if(prefsEnableAltF4Quit() || GetKeyState(VK_SHIFT) < 0) {
			TCHAR msg[1001], label[1001];
			GetPrivateProfileString(U_GLOBAL, TEXT("QuitDialogMessage"), 
						TEXT("Quit ") TEXT(VM_NAME) TEXT(" without saving?"), 
						msg, 1000, squeakIniName);
			GetPrivateProfileString(U_GLOBAL, TEXT("QuitDialogLabel"), 
						TEXT(VM_NAME), 
						label, 1000, squeakIniName);
			if(MessageBox(stWindow, msg, label, MB_YESNO) != IDYES)
				return 0;
			DestroyWindow(stWindow);
			ioExit();
			/*NOTREACHED*/
		}
		recordWindowEvent(WindowEventClose, NULL);
#endif /* NewspeakVM */
      break;
    }
    return DefWindowProcW(hwnd,message,wParam,lParam);
    break;
  }
  /*  mousing */
  case WM_MOUSEMOVE:
    /* we have to be careful to not clear nrClicks if the mouse 
       happens to move in-between rapid clicks */
    timeNow = GetMessageTime();	/* Win32 - gets time of last GetMessage() */
    timeDelta = timeNow - lastClickTime;
    if (timeDelta > GetDoubleClickTime())
      nrClicks = 0;

    if(inputSemaphoreIndex) {
      recordMouseEvent(lastMessage, nrClicks);
      break;
    }
    /* state based stuff */
    mousePosition.x = LOWORD(lParam);
    mousePosition.y = HIWORD(lParam);
    break;
  case WM_LBUTTONDOWN:
  case WM_RBUTTONDOWN:
  case WM_MBUTTONDOWN:
    { /* update the button mask for this event */
      switch (message) {
      case WM_LBUTTONDOWN: winButtonState |= MK_LBUTTON; break;
      case WM_RBUTTONDOWN: winButtonState |= MK_RBUTTON; break;
      case WM_MBUTTONDOWN: winButtonState |= MK_MBUTTON; break;
      }
    }
    if(GetFocus() != stWindow) SetFocus(stWindow);
    SetCapture(stWindow); /* capture mouse input */

	/* count mouse clicks */
	timeNow = GetMessageTime();		/* Win32 - gets time of last GetMessage() */
	timeDelta = timeNow - lastClickTime;
	nrClicks = (timeDelta <= GetDoubleClickTime()) ? (nrClicks + 1) : 1;
	lastClickTime = timeNow;

    if(inputSemaphoreIndex) {
      recordMouseEvent(lastMessage, nrClicks);
      break;
    }
    /* state based stuff */
    mousePosition.x = LOWORD(lParam);
    mousePosition.y = HIWORD(lParam);
    /* check for console focus */
    recordMouseDown(wParam, lParam);
    recordModifierButtons();

	/* capture the mouse as long as the button is pressed so we can scroll outside */
    SetCapture(stWindow);
    break;

  case WM_LBUTTONUP:
  case WM_RBUTTONUP:
  case WM_MBUTTONUP:
    {  /* avoid posting mouse ups for which we haven't seen the
	  corresponding mouse down events (native dialogs etc) */
      DWORD upMask = 0;
      switch (message) {
      case WM_LBUTTONUP: upMask = MK_LBUTTON; break;
      case WM_RBUTTONUP: upMask = MK_RBUTTON; break;
      case WM_MBUTTONUP: upMask = MK_MBUTTON; break;
      }
      if((winButtonState & upMask) == 0) break;
      winButtonState &= ~upMask; /* clear current mask */
    }

    if(GetFocus() != stWindow) SetFocus(stWindow);
    ReleaseCapture(); /* release mouse capture */
    if(inputSemaphoreIndex) {
      recordMouseEvent(lastMessage, nrClicks);
      break;
    }
    /* state based stuff */
    mousePosition.x = LOWORD(lParam);
    mousePosition.y = HIWORD(lParam);
    /* check for console focus */
    if(GetFocus() != stWindow) SetFocus(stWindow);
    recordMouseDown(wParam,lParam);
    recordModifierButtons();

	/* release capture */
    ReleaseCapture();
    break;
    /* virtual key codes */
  case WM_KEYDOWN:
  case WM_SYSKEYDOWN:
    if(GetFocus() == consoleWindow)
      return DefWindowProcW(hwnd, message, wParam, lParam);
    if(inputSemaphoreIndex) {
      recordKeyboardEvent(lastMessage);
      if(wParam == VK_F2 && prefsEnableF2Menu()) {
	TrackPrefsMenu();
      }
      if(wParam == VK_F4) {
	/* We must let F4 through here if we want Alt-F4 to work */
	return DefWindowProcW(hwnd, message, wParam, lParam);
      }
      break;
    }
    /* state based stuff */
    recordModifierButtons();
    if(!recordVirtualKey(message,wParam,lParam))
      return DefWindowProcW(hwnd,message,wParam,lParam);
    break;
  case WM_KEYUP:
  case WM_SYSKEYUP:
    if(GetFocus() == consoleWindow)
      return DefWindowProcW(hwnd, message, wParam, lParam);
    if(inputSemaphoreIndex) {
      recordKeyboardEvent(lastMessage);
      break;
    }
    /* state based stuff */
    recordModifierButtons();
    break;
    /* character codes */
  case WM_CHAR:
  case WM_SYSCHAR:
    if(GetFocus() == consoleWindow)
      return DefWindowProcW(hwnd, message, wParam, lParam);
    if(inputSemaphoreIndex) {
      recordKeyboardEvent(lastMessage);
      break;
    }
    /* state based stuff */
    recordModifierButtons();
    recordKeystroke(message,wParam,lParam);
    break;
  case WM_DEADCHAR:
  case WM_SYSDEADCHAR:
    break;
    /* expose events */
  case WM_PAINT:
    /* retrieve update region _before_ calling BeginPaint() !!! */
    GetUpdateRgn(hwnd,updateRgn,FALSE);
    BeginPaint(hwnd,&ps);
    /* store the rectangle required for image bit reversal */
    updateRect = ps.rcPaint;
    EndPaint(hwnd,&ps);
    /* Avoid repaint unless absolutely necessary (null update rects are quite common) */
    if (!IsRectEmpty(&updateRect)) {
      /* force redraw the next time ioShowDisplay() is called */
      updateRightNow = TRUE;
      fullDisplayUpdate();  /* this makes VM call ioShowDisplay */
    }
    break;
  case WM_SIZE:
    if(hwnd == stWindow) {
      /* Adjust the console window */
      GetClientRect(stWindow,&stWindowRect);
      MoveWindow(consoleWindow, 0,
		 stWindowRect.bottom-100, stWindowRect.right, 100, 1);
      /* Record the global stWindowRect for DirectX */
      MapWindowPoints(stWindow, NULL, (LPPOINT)&stWindowRect, 2);
    }
    else return DefWindowProcW(hwnd,message,wParam,lParam);

  case WM_MOVE:
    if(hwnd == stWindow) {
      /* Record the global stWindowRect for DirectX */
      GetClientRect(stWindow,&stWindowRect);
      MapWindowPoints(stWindow, NULL, (LPPOINT) &stWindowRect, 2);
    }
    else return DefWindowProcW(hwnd,message,wParam,lParam);
    /* Erasing the background leads to flashing so avoid it */
  case WM_ERASEBKGND:
    return TRUE;
  case WM_ACTIVATE:
    if(wParam == WA_INACTIVE) {
      SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_NORMAL);
    } else if(fPriorityBoost) {
      SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_ABOVE_NORMAL);
    }
    break;

#if !defined(_WIN32_WCE)
    /* Don't change the cursor or system tray on WinCE */
    /* cursor redraw */
  case WM_SETCURSOR:
    /* keep currentCursor */
    if((LOWORD(lParam) == HTCLIENT) && currentCursor) {
      SetCursor(currentCursor);
      break;
    }
    else return DefWindowProcW(hwnd,message,wParam,lParam);
  case WM_USER+42:
    /* system tray notification */
    if(wParam != (usqIntptr_t)hInstance) return 0;
    /* if right button, show system menu */
    /* if(lParam == WM_RBUTTONUP)
       TrackPrefsMenu(GetSystemMenu(stWindow,0)); */
    /* if double clicked, show main window */
    if(lParam == WM_LBUTTONDBLCLK) {
      if(!IsWindowVisible(stWindow))
	ShowWindow(stWindow, SW_SHOW);
      BringWindowToTop(stWindow);
    }
    return 0;
#endif /* !defined(_WIN32_WCE) */
    /* Focus handling */
  case WM_SETFOCUS:
    fHasFocus = 1;
    return DefWindowProcW(hwnd,message,wParam,lParam);
  case WM_KILLFOCUS:
    fHasFocus = 0;
    return DefWindowProcW(hwnd,message,wParam,lParam);
  default:
    /* Unprocessed messages may be processed outside the current
       module. If firstMessageHook is non-NULL and returns a non
       zero value, the message has been successfully processed */
    if(firstMessageHook)
      if((*firstMessageHook)(hwnd, message, wParam, lParam))
	return 1;
    return DefWindowProcW(hwnd,message,wParam,lParam);
  }
  return 1;
}

/****************************************************************************/
/*                     Printer Setup                                        */
/****************************************************************************/

// 18 June 2008 - jdm renamed from SetDefaultPrinter() which conflicts with Windows func
// No one seemed to be calling this func, anyway...
void SetTheDefaultPrinter()
{
#ifndef NO_PRINTER
  if(!printerSetup) SetupPrinter();
  printValues.Flags = PD_PRINTSETUP;
  PrintDlg(&printValues);
#endif /* NO_PRINTER */
}

void SetupPrinter()
{
#ifndef NO_PRINTER
  ZeroMemory(&printValues, sizeof(printValues));
  printValues.lStructSize = sizeof(PRINTDLG);
  printValues.hInstance = hInstance;
  printValues.nMinPage = 1;
  printValues.nMaxPage = 1;
  printValues.nFromPage = 1;
  printValues.nToPage = 1;
  printValues.hwndOwner = stWindow;

  /* fetch default DEVMODE/DEVNAMES */
  printValues.Flags = PD_RETURNDEFAULT;
  PrintDlg(&printValues);
  printerSetup = 1;
#endif
}


/****************************************************************************/
/*                   Color and Bitmap setup                                 */
/****************************************************************************/
#ifndef NO_STANDARD_COLORS
static void SetColorEntry(int index, int red, int green, int blue)
{
  logPal->palPalEntry[index].peRed = red / 256;
  logPal->palPalEntry[index].peGreen = green / 256;
  logPal->palPalEntry[index].peBlue = blue / 256;
  logPal->palPalEntry[index].peFlags = 0;
}

/* Generic color maps and bitmap info headers 1,4,8,16,32 bits per pixel */
void SetupPixmaps(void)
{ int i;

  logPal = malloc(sizeof(LOGPALETTE) + 255 * sizeof(PALETTEENTRY));
  if (!logPal) {
    printLastError(TEXT("malloc pallette"));
    return;
  }

  logPal->palVersion = 0x300;
  logPal->palNumEntries = 256;

  /* 1-bit colors (monochrome) */
  SetColorEntry(0, 65535, 65535, 65535);	/* white or transparent */
  SetColorEntry(1,     0,     0,     0);	/* black */

  /* additional colors for 2-bit color */
  SetColorEntry(2, 65535, 65535, 65535);	/* opaque white */
  SetColorEntry(3, 32768, 32768, 32768);	/* 1/2 gray */

  /* additional colors for 4-bit color */
  SetColorEntry( 4, 65535,     0,     0);	/* red */
  SetColorEntry( 5,     0, 65535,     0);	/* green */
  SetColorEntry( 6,     0,     0, 65535);	/* blue */
  SetColorEntry( 7,     0, 65535, 65535);	/* cyan */
  SetColorEntry( 8, 65535, 65535,     0);	/* yellow */
  SetColorEntry( 9, 65535,     0, 65535);	/* magenta */
  SetColorEntry(10,  8192,  8192,  8192);	/* 1/8 gray */
  SetColorEntry(11, 16384, 16384, 16384);	/* 2/8 gray */
  SetColorEntry(12, 24576, 24576, 24576);	/* 3/8 gray */
  SetColorEntry(13, 40959, 40959, 40959);	/* 5/8 gray */
  SetColorEntry(14, 49151, 49151, 49151);	/* 6/8 gray */
  SetColorEntry(15, 57343, 57343, 57343);	/* 7/8 gray */


  /* additional colors for 8-bit color */
  /* 24 more shades of gray (does not repeat 1/8th increments) */
  SetColorEntry(16,  2048,  2048,  2048);	/*  1/32 gray */
  SetColorEntry(17,  4096,  4096,  4096);	/*  2/32 gray */
  SetColorEntry(18,  6144,  6144,  6144);	/*  3/32 gray */
  SetColorEntry(19, 10240, 10240, 10240);	/*  5/32 gray */
  SetColorEntry(20, 12288, 12288, 12288);	/*  6/32 gray */
  SetColorEntry(21, 14336, 14336, 14336);	/*  7/32 gray */
  SetColorEntry(22, 18432, 18432, 18432);	/*  9/32 gray */
  SetColorEntry(23, 20480, 20480, 20480);	/* 10/32 gray */
  SetColorEntry(24, 22528, 22528, 22528);	/* 11/32 gray */
  SetColorEntry(25, 26624, 26624, 26624);	/* 13/32 gray */
  SetColorEntry(26, 28672, 28672, 28672);	/* 14/32 gray */
  SetColorEntry(27, 30720, 30720, 30720);	/* 15/32 gray */
  SetColorEntry(28, 34815, 34815, 34815);	/* 17/32 gray */
  SetColorEntry(29, 36863, 36863, 36863);	/* 18/32 gray */
  SetColorEntry(30, 38911, 38911, 38911);	/* 19/32 gray */
  SetColorEntry(31, 43007, 43007, 43007);	/* 21/32 gray */
  SetColorEntry(32, 45055, 45055, 45055);	/* 22/32 gray */
  SetColorEntry(33, 47103, 47103, 47103);	/* 23/32 gray */
  SetColorEntry(34, 51199, 51199, 51199);	/* 25/32 gray */
  SetColorEntry(35, 53247, 53247, 53247);	/* 26/32 gray */
  SetColorEntry(36, 55295, 55295, 55295);	/* 27/32 gray */
  SetColorEntry(37, 59391, 59391, 59391);	/* 29/32 gray */
  SetColorEntry(38, 61439, 61439, 61439);	/* 30/32 gray */
  SetColorEntry(39, 63487, 63487, 63487);	/* 31/32 gray */

  /* The remainder of color table defines a color cube with six steps
     for each primary color. Note that the corners of this cube repeat
     previous colors, but simplifies the mapping between RGB colors and
     color map indices. This color cube spans indices 40 through 255.
     */
  {
    int r, g, b;

    for (r= 0; r < 6; r++)
      for (g= 0; g < 6; g++)
	for (b= 0; b < 6; b++)
	  {
	    int i= 40 + ((36 * r) + (6 * b) + g);
	    if (i > 255) error("index out of range in color table compuation");
	    SetColorEntry(i, (r * 65535) / 5, (g * 65535) / 5, (b * 65535) / 5);
	  }
  }

  palette = CreatePalette(logPal);


  /* generate BITMAPINFOHEADERs */
  /* 1 bit color depth */
  bmi1 = (BITMAPINFO*) calloc(1,sizeof(BITMAPINFO) + 2 * sizeof(RGBQUAD));
  bmi1->bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi1->bmiHeader.biPlanes = 1;
  bmi1->bmiHeader.biBitCount = 1;
  bmi1->bmiHeader.biCompression = BI_RGB;
  for(i=0;i<2;i++)
    {
      bmi1->bmiColors[i].rgbRed = logPal->palPalEntry[i].peRed;
      bmi1->bmiColors[i].rgbGreen = logPal->palPalEntry[i].peGreen;
      bmi1->bmiColors[i].rgbBlue = logPal->palPalEntry[i].peBlue;
    }
  /* 4 bit color depth */
  bmi4 = (BITMAPINFO*) calloc(1,sizeof(BITMAPINFO) + 16 * sizeof(RGBQUAD));
  bmi4->bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi4->bmiHeader.biPlanes = 1;
  bmi4->bmiHeader.biBitCount = 4;
  bmi4->bmiHeader.biCompression = BI_RGB;
  for(i=0;i<16;i++)
    {
      bmi4->bmiColors[i].rgbRed = logPal->palPalEntry[i].peRed;
      bmi4->bmiColors[i].rgbGreen = logPal->palPalEntry[i].peGreen;
      bmi4->bmiColors[i].rgbBlue = logPal->palPalEntry[i].peBlue;
    }
  /* 8 bit color depth */
  bmi8 = (BITMAPINFO*) calloc(1,sizeof(BITMAPINFO) + 256 * sizeof(RGBQUAD));
  bmi8->bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi8->bmiHeader.biPlanes = 1;
  bmi8->bmiHeader.biBitCount = 8;
  bmi8->bmiHeader.biCompression = BI_RGB;
  for(i=0;i<256;i++)
    {
      bmi8->bmiColors[i].rgbRed = logPal->palPalEntry[i].peRed;
      bmi8->bmiColors[i].rgbGreen = logPal->palPalEntry[i].peGreen;
      bmi8->bmiColors[i].rgbBlue = logPal->palPalEntry[i].peBlue;
    }
  /* 16 bit color depth */
  bmi16 = (BITMAPINFO*) calloc(1,sizeof(BITMAPINFO) + 4 * sizeof(DWORD));
  bmi16->bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi16->bmiHeader.biPlanes = 1;
  bmi16->bmiHeader.biBitCount = 16;
  bmi16->bmiHeader.biCompression = BI_BITFIELDS;
  ((DWORD*) bmi16->bmiColors)[0] = (31 << 10); /* red mask */
  ((DWORD*) bmi16->bmiColors)[1] = (31 << 5); /* green mask */
  ((DWORD*) bmi16->bmiColors)[2] = (31 << 0); /* blue mask */

  /* 32 bit color depth */
  bmi32 = (BITMAPINFO*) calloc(1,sizeof(BITMAPINFO) + 4 * sizeof(DWORD));
  bmi32->bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi32->bmiHeader.biPlanes = 1;
  bmi32->bmiHeader.biBitCount = 32;
  bmi32->bmiHeader.biCompression = BI_BITFIELDS;
  ((DWORD*) bmi32->bmiColors)[0] = 0x00FF0000; /* red mask */
  ((DWORD*) bmi32->bmiColors)[1] = 0x0000FF00; /* green mask */
  ((DWORD*) bmi32->bmiColors)[2] = 0x000000FF; /* blue mask */

}

#endif /* NO_STANDARD_COLORS */

/****************************************************************************/
/*                     Window Setup                                         */
/****************************************************************************/

/* SetWindowTitle(): Set the main window title */
void SetWindowTitle() {
  char titleString[MAX_PATH+20];
  WCHAR wideTitle[MAX_PATH+20];

  if(!IsWindow(stWindow)) return;
  if(*windowTitle) sprintf(titleString, "%s", windowTitle);
  else sprintf(titleString,"%s! (%s)", VM_NAME, imageName);

  MultiByteToWideChar(CP_UTF8, 0, titleString, -1, wideTitle, MAX_PATH+20);
  SetWindowTextW(stWindow, wideTitle);
}

char *ioGetWindowLabel(void) {
  return windowTitle;
}

sqInt ioSetWindowLabelOfSize(void* lblIndex, sqInt sz) {
  if(sz > MAX_PATH) sz = MAX_PATH;
  memcpy(windowTitle, (void*)lblIndex, sz);
  windowTitle[sz] = 0;
  SetWindowTitle();
  return 1;
}

sqInt ioGetWindowWidth(void) {
  RECT r;
  if(!IsWindow(stWindow)) return -1;
  r.left = r.right = r.top = r.bottom = 0;
  GetWindowRect(stWindow, &r);
  return r.right - r.left;
}

sqInt ioGetWindowHeight(void) {
  RECT r;
  if(!IsWindow(stWindow)) return -1;
  r.left = r.right = r.top = r.bottom = 0;
  GetWindowRect(stWindow, &r);
  return r.bottom - r.top;
}

sqInt ioSetWindowWidthHeight(sqInt w, sqInt h) {
  RECT workArea, workArea2, old, shifted;
  HMONITOR hMonitor;
  MONITORINFO mi;
  int left, top, width, height, maxWidth, maxHeight;

  if(!IsWindow(stWindow)) return 0;
  width = w;
  height = h;

  /* minimum size is 64 x 64 */
  width  = ( width > 64) ?   width : 64;
  height = (height > 64) ?  height : 64;

  GetWindowRect(stWindow, &old);
  GetWindowRect(stWindow, &shifted);

  /* Work area of screen containing current window */
  hMonitor = MonitorFromWindow (stWindow, MONITOR_DEFAULTTONEAREST);
  mi.cbSize = (sizeof(mi));
  GetMonitorInfo(hMonitor, &mi);
  workArea = mi.rcWork;

  /* Work area of screen containing target rectangle. */
  shifted.bottom = (shifted.top + h);
  shifted.right = (shifted.left + w);
  hMonitor = MonitorFromRect (&shifted, MONITOR_DEFAULTTONEAREST);
  mi.cbSize = (sizeof(mi));
  GetMonitorInfo(hMonitor, &mi);
  workArea2 = mi.rcWork;

  /* If the second choice holds the target, use it, else use the more reliable window work area */
  if ((workArea2.top <= shifted.top) && (workArea2.bottom >= shifted.bottom) 
     && (workArea2.left <= shifted.left) && (workArea2.right >= shifted.right)) {
	workArea = workArea2;
  }
  /* maximum size is working area */
  maxWidth  = workArea.right - workArea.left;
  maxHeight = workArea.bottom - workArea.top;

  width  = (width <= maxWidth) ? width : maxWidth;
  height = (height <= maxHeight) ? height : maxHeight;

  /* We may have to center the window to fit on screen,
     although if there is room, we retain the window's previous position. */
  if (fBrowserMode) {
    left = 0;
    top = 0;
  } else if ((old.left >= workArea.left) && (old.top >= workArea.top) &&
		     (old.left + width < workArea.right) && (old.top + height < workArea.bottom)) {
	left = old.left; 
	top = old.top;
  } else {
    left = (workArea.left) + ((maxWidth-width) / 2);
    top = (workArea.top) + ((maxHeight-height) / 2);
  }
  if ((old.left != left) || (old.top != top) || 
	  (old.left - old.right != width) || (old.bottom - old.top != height)) {
	  SetWindowPos(stWindow, NULL, left, top, width, height, SWP_NOZORDER);
  }
  return 1;

}

void* ioGetWindowHandle(void)
{
	return stWindow;
}

sqInt ioIsWindowObscured(void) {
  HWND hwnd;
  RECT baseRect, hwndRect;

  if(!IsWindow(stWindow)) return 1; /* not even a window */
  if(IsIconic(stWindow)) return 1; /* minimized */

  /* Check whether the window extends beyond the screen */
  GetClientRect(stWindow, &baseRect);
  MapWindowPoints(stWindow, NULL, (LPPOINT)(&baseRect), 2);
  hwnd = GetDesktopWindow();
  GetWindowRect(hwnd, &hwndRect);
  if(baseRect.left   < hwndRect.left ||
     baseRect.right  > hwndRect.right ||
     baseRect.top    < hwndRect.top ||
     baseRect.bottom > hwndRect.bottom) return 1; /* too big */

  /* Check whether any windows in front of this window overlap */
  hwnd = stWindow;
  while(hwnd = GetNextWindow(hwnd, GW_HWNDPREV)) {

    if(!IsWindowVisible(hwnd)) continue; /* skip invisible windows */

    GetWindowRect(hwnd, &hwndRect);
    if(!(hwndRect.left >= baseRect.right ||
	 baseRect.left >= hwndRect.right ||
	 hwndRect.top >= baseRect.bottom ||
	 baseRect.top >= hwndRect.bottom)) return 1; /* obscured */
  }
  return false; /* not obscured */
}

void SetupWindows()
{ WNDCLASS wc;

  /* create our update region */
  updateRgn = CreateRectRgn(0,0,1,1);

  /* No windows at all when running as NT service */
  if(fRunService && !fWindows95) return;

  wc.style = CS_OWNDC; /* don't waste resources ;-) */
  wc.lpfnWndProc = (WNDPROC)MainWndProcA;
  wc.cbClsExtra = 0;
  wc.cbWndExtra = 0;
  wc.hInstance = hInstance;
  wc.hIcon = LoadIcon (hInstance, MAKEINTRESOURCE(2));
  wc.hCursor = NULL;
  wc.hbrBackground = GetStockObject (WHITE_BRUSH);
  wc.lpszMenuName = NULL;
  wc.lpszClassName = windowClassName;
  RegisterClass(&wc);

  if(!browserWindow)
    stWindow = CreateWindowEx(WS_EX_APPWINDOW /* | WS_EX_OVERLAPPEDWINDOW */,
			      windowClassName,
			      TEXT(VM_NAME) TEXT("!"),
			      WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
			      0,
			      0,
			      CW_USEDEFAULT,
			      CW_USEDEFAULT,
			      NULL,
			      NULL,
			      hInstance,
			      NULL);
  else {
    /* Setup a browser window. */
    fBrowserMode = 1;
    stWindow = CreateWindowEx(0,
			      windowClassName,
			      TEXT(VM_NAME) TEXT("!"),
			      WS_CHILD | WS_CLIPCHILDREN,
			      0,
			      0,
			      GetSystemMetrics(SM_CXSCREEN),
			      GetSystemMetrics(SM_CYSCREEN),
			      browserWindow,
			      NULL,
			      hInstance,
			      NULL);
  }
  /* Force Unicode WM_CHAR */
  SetWindowLongPtrW(stWindow,GWLP_WNDPROC,(LONG_PTR)MainWndProcW);

#ifndef NO_WHEEL_MOUSE
  g_WM_MOUSEWHEEL = RegisterWindowMessage( TEXT("MSWHEEL_ROLLMSG") ); /* RvL 1999-04-19 00:23 */
#endif

#if defined(_WIN32_WCE)
  /* WinCE does not support RegisterClassEx(), so we must set
     the small icon after creating the window. */
  SendMessage(stWindow,WM_SETICON, FALSE,
	      (LPARAM)LoadImage(hInstance, MAKEINTRESOURCE(1),
				IMAGE_ICON, 16, 16, 0));

  consoleWindow = NULL; /* We do not use console under WinCE */

#else /* defined(_WIN32_WCE) */

  consoleWindow = CreateWindowEx(0,
				 TEXT("EDIT"),
				 TEXT(""),
				 WS_CHILD | WS_BORDER |
				 WS_HSCROLL | WS_VSCROLL | ES_MULTILINE,
				 0,
				 0,
				 CW_USEDEFAULT,
				 CW_USEDEFAULT,
				 stWindow,
				 NULL,
				 hInstance,
				 NULL);
#endif /* defined(_WIN32_WCE) */

  /* Modify the system menu for any VM options */
  CreatePrefsMenu();
  SetWindowTitle();
  SetForegroundWindow(stWindow);

#ifndef NO_DROP
  /* drag and drop needs to be set up on per-window basis */
  SetupDragAndDrop();
#endif

#ifndef NO_DIRECTINPUT
  /* direct input needs to be set up on per-window basis */
  SetupDirectInput();
#endif
  ioScreenSize(); /* compute new rect initially */
}


#if !defined(_WIN32_WCE)  /* Unused under WinCE */

void SetWindowSize(void) {
  RECT r, workArea;
  int width, height, maxWidth, maxHeight, actualWidth, actualHeight;
  int deltaWidth, deltaHeight;

  if(!IsWindow(stWindow)) return; /* might happen if run as NT service */
  if(browserWindow) return; /* Ignored if in browser */

  if (getSavedWindowSize() != 0) {
    width  = (unsigned) getSavedWindowSize() >> 16;
    height = getSavedWindowSize() & 0xFFFF;
  } else {
    width  = 640;
    height = 480;
  }
  /* minimum size is 64 x 64 */
  width  = ( width > 64) ?   width : 64;
  height = (height > 64) ?  height : 64;

  /* maximum size is working area */
  SystemParametersInfo( SPI_GETWORKAREA, 0, &workArea, 0);
  maxWidth  = workArea.right - workArea.left;
  maxHeight = workArea.bottom - workArea.top;

  width  = ( width <= maxWidth)  ?  width : maxWidth;
  height = (height <= maxHeight) ? height : maxHeight;

  SetWindowPos(stWindow, NULL, (maxWidth-width) / 2,
  		(maxHeight-height) / 2, width, height,
  		SWP_NOZORDER | SWP_HIDEWINDOW);

  /* Get the client area to recompute the window size accordingly */
  GetClientRect(stWindow,&r);
  actualWidth = r.right - r.left;
  actualHeight = r.bottom - r.top;

  /* deltaWidth/height contains the 'decoration' of the window */
  deltaWidth = width - actualWidth;
  deltaHeight = height - actualHeight;
  width += deltaWidth;
  height += deltaHeight;
  width  = (width <= maxWidth ) ? width : maxWidth;
  height = (height <= maxHeight ) ? height : maxHeight;
  SetWindowPos(stWindow, NULL, (maxWidth-width) / 2,
  		(maxHeight-height) / 2, width, height,
  		SWP_NOZORDER | SWP_HIDEWINDOW);

}

#endif /* !defined(_WIN32_WCE) */

/****************************************************************************/
/*              Keyboard and Mouse                                          */
/****************************************************************************/

/* The following is a mapping to Mac Roman glyphs.
   It is not entirely correct since a number of glyphs are
   different but should be good enough for Squeak.
   More significantly, we can now map in both directions. */
static unsigned char keymap[256] =
{
  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63,
 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
 96, 97, 98, 99,100,101,102,103,104,105,106,107,108,109,110,111,
112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,
173,176,226,196,227,201,160,224,246,228,178,220,206,179,182,183,
184,212,213,210,211,165,208,209,247,170,185,221,207,186,189,217,
202,193,162,163,219,180,195,164,172,169,187,199,194,197,168,248,
161,177,198,215,171,181,166,225,252,218,188,200,222,223,240,192,
203,231,229,204,128,129,174,130,233,131,230,232,237,234,235,236,
245,132,241,238,239,205,133,249,175,244,242,243,134,250,251,167,
136,135,137,139,138,140,190,141,143,142,144,145,147,146,148,149,
253,150,152,151,153,155,154,214,191,157,156,158,159,254,255,216
};

/* The following is the inverse keymap */
static unsigned char iKeymap[256];

void SetupKeymap()
{ int i;
  for(i=0;i<256;i++)
    iKeymap[keymap[i]] = i;
}


/* Map a virtual key into something the Mac understands */
static int mapVirtualKey(int virtKey)
{
  switch (virtKey) {
    case VK_DELETE: return 127;
    case VK_INSERT: return 5;
    case VK_PRIOR:  return 11;
    case VK_NEXT :  return 12;
    case VK_END  :  return 4;
    case VK_HOME :  return 1;
    case VK_LEFT :  return 28;
    case VK_RIGHT:  return 29;
    case VK_UP   :  return 30;
    case VK_DOWN :  return 31;
    case VK_RETURN: return 13;
    /* remap appropriately so that we get _all_ key down events */
    case 127: return VK_DELETE;
    case 5: return VK_INSERT;
    case 11: return VK_PRIOR;
    case 12: return VK_NEXT;
    case 4: return VK_END;
    case 1: return VK_HOME;
    case 28: return VK_LEFT;
    case 29: return VK_RIGHT;
    case 30: return VK_UP;
    case 31: return VK_DOWN;
    /* case 13: return VK_RETURN; */
  }
  return 0;
}

/****************************************************************************/
/*              Event based primitive set                                   */
/****************************************************************************/
#define MAX_EVENT_BUFFER 1024
static sqInputEvent eventBuffer[MAX_EVENT_BUFFER];
static int eventBufferGet = 0;
static int eventBufferPut = 0;

sqInputEvent *sqNextEventPut(void) {
  sqInputEvent *evt;
  evt = eventBuffer + eventBufferPut;

  if(inputSemaphoreIndex)
  {
    eventBufferPut = (eventBufferPut + 1) % MAX_EVENT_BUFFER;
    if (eventBufferGet == eventBufferPut) {
      /* buffer overflow; drop the last event */
      printf("WARNING: event buffer overflow\n");
      eventBufferGet = (eventBufferGet + 1) % MAX_EVENT_BUFFER;
    }

    signalSemaphoreWithIndex(inputSemaphoreIndex);
  }
  return evt;
}


int recordMouseEvent(MSG *msg, UINT nrClicks) {
#ifndef NO_DIRECTINPUT
  static DWORD firstEventTime = 0;
#endif
  DWORD wParam;
  sqMouseEvent proto, *event;
  int alt, shift, ctrl, red, blue, yellow;
  if(!msg) return 0;

  /* clear out the button state for events we haven't seen */
  wParam = msg->wParam & 
    ~(MK_LBUTTON + MK_MBUTTON + MK_RBUTTON - winButtonState);

  /* printf("HWND: %x MSG: %x WPARAM: %x LPARAM: %x\n", msg->hwnd, msg->message, wParam, msg->lParam); */


  alt = GetKeyState(VK_MENU) & 0x8000;
  shift = wParam & MK_SHIFT;
  ctrl  = wParam & MK_CONTROL;
  red   = wParam & MK_LBUTTON;
  if(f1ButtonMouse) {
    /* there's just a single button y'know */
    red |= wParam & MK_MBUTTON;
    red |= wParam & MK_RBUTTON;
    blue = yellow = 0;
  } else if(!f3ButtonMouse) {
    blue   = wParam & MK_MBUTTON;
    yellow = wParam & MK_RBUTTON;
  } else {
    blue   = wParam & MK_RBUTTON;
    yellow = wParam & MK_MBUTTON;
  }
  /* first the basics */
  proto.type = EventTypeMouse;
  proto.timeStamp = msg->time;
  proto.x = (int)(short)LOWORD(msg->lParam);
  proto.y = (int)(short)HIWORD(msg->lParam);
  /* then the buttons */
  proto.buttons = 0;
  proto.buttons |= red ? RedButtonBit : 0;
  proto.buttons |= blue ? BlueButtonBit : 0;
  proto.buttons |= yellow ? YellowButtonBit : 0;
  /* then the modifiers */
  proto.modifiers = 0;
  proto.modifiers |= shift ? ShiftKeyBit : 0;
  proto.modifiers |= ctrl ? CtrlKeyBit : 0;
  proto.modifiers |= alt ? CommandKeyBit : 0;
  proto.nrClicks = nrClicks;
  proto.windowIndex = msg->hwnd == stWindow ? 0 : (sqIntptr_t) msg->hwnd;
#ifndef NO_DIRECTINPUT
  /* get buffered input */
  if(msg->message == WM_MOUSEMOVE) {
    GetBufferedMouseTrail(firstEventTime, msg->time, &proto);
  }
  firstEventTime = msg->time;
#endif
  /* and lastly, fill in the event itself */
  event = (sqMouseEvent*) sqNextEventPut();
  *event = proto;
  return 1;
}

int recordDragDropEvent(HWND wnd, int dragType, int x, int y, int numFiles)
{
  sqDragDropFilesEvent *evt;
  int alt, shift, ctrl, modifiers;

  evt = (sqDragDropFilesEvent*) sqNextEventPut();

  alt = GetKeyState(VK_MENU) & 0x8000;
  shift = (GetKeyState(VK_SHIFT) & 0x8000);
  ctrl = GetKeyState(VK_CONTROL) & 0x8000;

  /* first the basics */
  evt->type = EventTypeDragDropFiles;
  evt->timeStamp = ioMicroMSecs();
  evt->dragType = dragType;
  evt->x = x;
  evt->y = y;
  /* then the modifiers */
  modifiers = 0;
  modifiers |= shift ? ShiftKeyBit : 0;
  modifiers |= ctrl ? CtrlKeyBit : 0;
  modifiers |= alt ? CommandKeyBit : 0;
  evt->modifiers = modifiers;
  evt->numFiles = numFiles;

  /* clean up reserved */
  evt->windowIndex = wnd == stWindow ? 0 : (sqIntptr_t) wnd;
  return 1;
}

int recordKeyboardEvent(MSG *msg) {
  sqKeyboardEvent *evt;
  int alt, shift, ctrl;
  int keyCode, virtCode, pressCode;

  if(!msg) return 0;

  alt = GetKeyState(VK_MENU) & 0x8000;
  shift = (GetKeyState(VK_SHIFT) & 0x8000);
  ctrl = GetKeyState(VK_CONTROL) & 0x8000;
  /* now the key code */
  virtCode = mapVirtualKey(msg->wParam);
  keyCode = msg->wParam;
  /* press code must differentiate */
  switch(msg->message) {
    case WM_KEYDOWN:
    case WM_SYSKEYDOWN:
      if(virtCode) keyCode = virtCode;
      pressCode = EventKeyDown;
      /* filter out repeated meta keys */
      if(msg->lParam & 0x40000000) {
	/* Bit 30 signifies the previous key state. */
	if(msg->wParam == VK_SHIFT ||
	   msg->wParam == VK_CONTROL ||
	   msg->wParam == VK_MENU) {
	  /* okay, it's a meta-key */
	  return 1;
	}
      }
      break;
    case WM_KEYUP:
    case WM_SYSKEYUP:
      if(virtCode) keyCode = virtCode;
      pressCode = EventKeyUp;
      break;
    case WM_CHAR:
    case WM_SYSCHAR:
      /* Note: VK_RETURN is recorded as virtual key ONLY */
      if(keyCode == 13) return 1;
      pressCode = EventKeyChar;
      break;
    default:
      pressCode = EventKeyChar;
  }
  /* remove Ctrl+Alt codes for international keyboards */
  if(ctrl && alt) {
    ctrl = 0;
    alt = 0;
  }
  /* first the basics */
  evt = (sqKeyboardEvent*) sqNextEventPut();
  evt->type = EventTypeKeyboard;
  evt->timeStamp = msg->time;
  evt->charCode = keymap[keyCode & 0xff];
  evt->pressCode = pressCode;
  evt->modifiers = 0;
  evt->modifiers |= alt ? CommandKeyBit : 0;
  evt->modifiers |= shift ? ShiftKeyBit : 0;
  evt->modifiers |= ctrl ? CtrlKeyBit : 0;
  evt->windowIndex = msg->hwnd == stWindow ? 0 : (sqIntptr_t) msg->hwnd;
  evt->utf32Code = keyCode;
  /* clean up reserved */
  evt->reserved1 = 0;

  /* so the image can distinguish between control sequence
     like SOH and characters with modifier like ctrl+a */
  if(pressCode == EventKeyChar && ctrl)
  {
    evt->utf32Code = MapVirtualKey(LOBYTE(HIWORD(msg->lParam)), 1);
    return 1;
  }

  /* note: several keys are not reported as character events;
     most noticably the mapped virtual keys. For those we
     generate extra character events here (not for CTRL+VK_RETURN*/
  if(pressCode == EventKeyDown && virtCode != 0 && (evt->charCode != VK_RETURN || !ctrl)) {
    /* generate extra character event */
    sqKeyboardEvent *extra = (sqKeyboardEvent*)sqNextEventPut();
    *extra = *evt;
    extra->pressCode = EventKeyChar;
  }
  
  /* some more keypress events for which windows only reports keydown and keyup
  */
  /* ctlr+m, but report as keyValue = VK_RETURN and charCode m/M */
  if(pressCode == EventKeyDown && ctrl && evt->charCode == 77)
  {
    evt->utf32Code = (shift) ? 77 : 109;
    evt->charCode = VK_RETURN;
    sqKeyboardEvent *extra = (sqKeyboardEvent*)sqNextEventPut();
    *extra = *evt;
    extra->pressCode = EventKeyChar;
  }
  /* ctlr+<number> */
  if(pressCode == EventKeyDown && ctrl && evt->charCode >= 48 && evt->charCode <= 57)
  {
    evt->utf32Code = evt->charCode;
    sqKeyboardEvent *extra = (sqKeyboardEvent*)sqNextEventPut();
    *extra = *evt;
    extra->pressCode = EventKeyChar;
  }
  /* ctlr+Tab */
  if(pressCode == EventKeyDown && ctrl && evt->charCode == 9)
  {
    evt->utf32Code = evt->charCode;
    sqKeyboardEvent *extra = (sqKeyboardEvent*)sqNextEventPut();
    *extra = *evt;
    extra->pressCode = EventKeyChar;
  }
  return 1;
}

int recordWindowEvent(int action, RECT *r) {
  sqWindowEvent *evt;
  evt = (sqWindowEvent*)sqNextEventPut();
  evt->type = EventTypeWindow;
  evt->timeStamp = GetTickCount();
  evt->action = action;
  if(r) {
    evt->value1 = r->left;
    evt->value2 = r->top;
    evt->value3 = r->right;
    evt->value4 = r->bottom;
  } else {
    evt->value1 = evt->value2 = evt->value3 = evt->value4 = 0;
  }
  evt->windowIndex = 1;
  return 1;
}

sqInt ioSetInputSemaphore(sqInt semaIndex) {
  inputSemaphoreIndex = semaIndex;
  return 1;
}

sqInt ioGetNextEvent(sqInputEvent *evt) {
  if (eventBufferGet == eventBufferPut) {
    ioProcessEvents();
  }
  if (eventBufferGet == eventBufferPut)
    return 1;

  *evt = eventBuffer[eventBufferGet];
  eventBufferGet = (eventBufferGet+1) % MAX_EVENT_BUFFER;
  return 1;
}

/****************************************************************************/
/*              State based primitive set                                   */
/****************************************************************************/

sqInt ioGetKeystroke(void)
{
  int keystate;
  ioProcessEvents();  /* process all pending events */
  if (keyBufGet == keyBufPut) return -1;  /* keystroke buffer is empty */
  keystate= keyBuf[keyBufGet];
  keyBufGet= (keyBufGet + 1) % KEYBUF_SIZE;
  /* set modifer bits in buttonState to reflect the last keystroke fetched */
  buttonState= ((keystate >> 5) & 0xF8) | (buttonState & 0x7);
  return keystate;
}

sqInt ioPeekKeystroke(void)
{
  int keystate;
  ioProcessEvents();  /* process all pending events */
  if (keyBufGet == keyBufPut) return -1;  /* keystroke buffer is empty */
  keystate= keyBuf[keyBufGet];
  /* set modifer bits in buttonState to reflect the last keystroke peeked at */
  buttonState= ((keystate >> 5) & 0xF8) | (buttonState & 0x7);
  return keystate;
}


void recordKey(int keystate)
{
  keyBuf[keyBufPut]= keystate;
  keyBufPut= (keyBufPut + 1) % KEYBUF_SIZE;
  if (keyBufGet == keyBufPut) {
    /* buffer overflow; drop the last character */
    keyBufGet= (keyBufGet + 1) % KEYBUF_SIZE;
    keyBufOverflows++;
  }
}

int recordVirtualKey(UINT message, WPARAM wParam, LPARAM lParam)
{
  int keystate = 0;

  if(wParam == VK_F2) {
    TrackPrefsMenu();
    return 1;
  }
  if(wParam == VK_CANCEL) {
    setInterruptPending(true);
    return 1;
  }
  keystate = mapVirtualKey(wParam);
  if(keystate == 0) return 0;
  keystate = keystate | ((buttonState >> 3) << 8);
  recordKey(keystate);
  return 1;
}

int recordKeystroke(UINT msg, WPARAM wParam, LPARAM lParam)
{
  int keystate=0;

  /* Special case: VK_RETURN is handled as virtual key *only* */
  if(wParam == 13) return 1;

  /* Map from Win32 to Mac */
  keystate = keymap[wParam];
  /* add the modifiers */
  keystate = keystate | ((buttonState >> 3) << 8);
  /* check for interrupt key */
  if(keystate == getInterruptKeycode())
    {
      /* NOTE: Interrupt key is meta, not recorded as key stroke */
      setInterruptPending(true);
	  return 1;
    }
  recordKey(keystate);
  return 1;
}

/* record mouse events */
int recordMouseDown(WPARAM wParam, LPARAM lParam)
{
  int stButtons= 0;

#if defined(_WIN32_WCE)

  if (wParam & MK_LBUTTON) stButtons |= 4;
  if (stButtons == 4)	/* red button honours the modifiers */
    {
      if (wParam & MK_CONTROL) stButtons = 1;	/* blue button if CTRL down */
      else if (GetKeyState(VK_LMENU) & 0x8000) stButtons = 2;	/* yellow button if META down */
    }

#else /* defined(_WIN32_WCE) */

  if(GetKeyState(VK_LBUTTON) & 0x8000) stButtons |= 4;
  if(GetKeyState(VK_MBUTTON) & 0x8000) {
    if(f1ButtonMouse) stButtons |= 4;
    else stButtons |= f3ButtonMouse ? 2 : 1;
  }
  if(GetKeyState(VK_RBUTTON) & 0x8000) {
    if(f1ButtonMouse) stButtons |= 4;
    else stButtons |= f3ButtonMouse ? 1 : 2;
  }

  if (stButtons == 4)	/* red button honours the modifiers */
    {
      if (GetKeyState(VK_CONTROL) & 0x8000)
        stButtons= 2;	/* blue button if CTRL down */
      else if (GetKeyState(VK_MENU) & 0x8000)
        stButtons= 1;	/* yellow button if META down */
    }

#endif /* defined(_WIN32_WCE) */

  buttonState = stButtons & 0x7;
  return 1;
}

/* record the modifier buttons */
int recordModifierButtons()
{ int modifiers=0;

  /* map both shift and caps lock to squeak shift bit */
  if(GetKeyState(VK_SHIFT) & 0x8000)
    modifiers |= 1 << 3;

  /* Map meta key to command.

     NOTE:
     Non US keyboards typically need the right menu key for special mappings.
     However, it seems that hitting this key is interpreted as Alt-Ctrl.
     We therefore ignore the control modifier if the right menu key
     is pressed (hoping that nobody will use the right-menu / control combination)

     NOTE^2:
     Due to another Win95 bug, we can not ask for the left
     or right alt key directly (Win95 returns always 0 if
     asked for VK_LMENU or VK_RMENU). Therefore we're using
     the Ctrl-Alt combination for detecting the right menu key */

  /* if CTRL and not ALT pressed use control modifier */
  if((GetKeyState(VK_CONTROL) & 0x8000) && (GetKeyState(VK_MENU) & 0x8000) == 0)
    modifiers |= 1 << 4;

  /* if ALT and not CTRL pressed use command modifier */
  if((GetKeyState(VK_MENU) & 0x8000) && (GetKeyState(VK_CONTROL) & 0x8000) == 0)
    modifiers |= 1 << 6;

  /* if ALT and CTRL pressed use option modifier */
  if((GetKeyState(VK_MENU) & 0x8000) && (GetKeyState(VK_CONTROL) & 0x8000))
    modifiers |= 1 << 5;

  /* button state: low three bits are mouse buttons; next 4 bits are modifier bits */
  buttonState= modifiers | (buttonState & 0x7);
  return 1;
}

sqInt ioGetButtonState(void)
{
  if(fReduceCPUUsage || (fReduceCPUInBackground && !fHasFocus)) {
    MSG msg;
    /* Delay execution of squeak if
       - there is currently no button pressed
       - there is currently no mouse event in the input queue
       by at most 5 msecs. This will reduce cpu load during idle times.
    */
    if((buttonState & 0x7) == 0 &&
       !PeekMessage(&msg, stWindow, WM_MOUSEFIRST, WM_MOUSELAST, PM_NOREMOVE))
      MsgWaitForMultipleObjects(0,NULL,0,5, QS_MOUSE);
  }
  ioProcessEvents();  /* process all pending events */
  return buttonState;
}

sqInt ioMousePoint(void)
{
  if(fReduceCPUUsage || (fReduceCPUInBackground && !fHasFocus)) {
    MSG msg;
    /* Delay execution of squeak if
       - there is currently no button pressed
       - there is currently no mouse event in the input queue
       by at most 5 msecs. This will reduce cpu load during idle times.
    */
    if((buttonState & 0x7) == 0 &&
       !PeekMessage(&msg, stWindow, WM_MOUSEFIRST, WM_MOUSELAST, PM_NOREMOVE))
      MsgWaitForMultipleObjects(0,NULL,0,5, QS_MOUSE);
  }
  ioProcessEvents();  /* process all pending events */
  /* x is high 16 bits; y is low 16 bits */
  return (mousePosition.x << 16) | (mousePosition.y);
}

/****************************************************************************/
/*              Misc support primitves                                      */
/****************************************************************************/
sqInt ioBeep(void)
{
  MessageBeep(0);
  return 1;
}

/*
 * In the Cog VMs time management is in platforms/win32/vm/sqin32Heartbeat.c.
 */
sqInt ioRelinquishProcessorForMicroseconds(sqInt microSeconds)
{
  /* wake us up if something happens */
  ResetEvent(vmWakeUpEvent);
  MsgWaitForMultipleObjects(1, &vmWakeUpEvent, FALSE,
			    microSeconds / 1000, QS_ALLINPUT);
  ioProcessEvents(); /* keep up with mouse moves etc. */
  return microSeconds;
}

sqInt ioProcessEvents(void)
{	static MSG msg;
	int result;
	extern sqInt inIOProcessEvents;

	if (fRunService && !fWindows95) return 1;

#if NewspeakVM
	/* inIOProcessEvents controls ioProcessEvents.  If negative then
	 * ioProcessEvents is disabled.  If >= 0 inIOProcessEvents is incremented
	 * to avoid reentrancy (i.e. for native GUIs).
	 */
	if (inIOProcessEvents) return -1;
	inIOProcessEvents += 1;

	result = ioDrainEventQueue();

	if (inIOProcessEvents > 0)
		inIOProcessEvents -= 1;

	return result;
#else /* NewspeakVM */
	/* inIOProcessEvents controls ioProcessEvents.  If negative then
	 * ioProcessEvents is disabled.  If >= 0 inIOProcessEvents is incremented
	 * to avoid reentrancy (i.e. for native GUIs).
	 */
	if (inIOProcessEvents) return -1;
	inIOProcessEvents += 1;

  /* WinCE doesn't retrieve WM_PAINTs from the queue with PeekMessage,
     so we won't get anything painted unless we use GetMessage() if there
     is a dirty rect. */
	lastMessage = &msg;

#ifdef PharoVM
	if(ioCheckForEventsHooks) {
		/* HACK for SDL 2 */
     		ioCheckForEventsHooks();
	}
	else {
	
		while(PeekMessage(&msg,NULL,0,0,PM_NOREMOVE)) {
			GetMessage(&msg,NULL,0,0);
# ifndef NO_PLUGIN_SUPPORT
			if (msg.hwnd == NULL)
				pluginHandleEvent(&msg);
# endif
			TranslateMessage(&msg);
			DispatchMessage(&msg);

		}
	}
#else
	while(PeekMessage(&msg,NULL,0,0,PM_NOREMOVE)) {
		GetMessage(&msg,NULL,0,0);
# ifndef NO_PLUGIN_SUPPORT
		if (msg.hwnd == NULL)
			pluginHandleEvent(&msg);
# endif
		TranslateMessage(&msg);
		DispatchMessage(&msg);
    	}
#endif

# ifndef NO_DIRECTINPUT
	/* any buffered mouse input which hasn't been processed is obsolete */
	DumpBufferedMouseTrail();
# endif

	/* If we're running in a browser check if the browser's still there */
	if (fBrowserMode
	 && browserWindow
	 && !IsWindow(browserWindow))
		ioExit();

	lastMessage = NULL;

	if (inIOProcessEvents > 0)
		inIOProcessEvents -= 1;

	return 1;
#endif /* NewspeakVM */
}

#if NewspeakVM
sqInt
ioDrainEventQueue(void)
{ static MSG msg;
  POINT mousePt;

  if(fRunService && !fWindows95) return 1;

  /* WinCE doesn't retrieve WM_PAINTs from the queue with PeekMessage,
     so we won't get anything painted unless we use GetMessage() if there
     is a dirty rect. */
  lastMessage = &msg;
  while(PeekMessage(&msg,NULL,0,0,PM_NOREMOVE))
    {
      GetMessage(&msg,NULL,0,0);
#ifndef NO_PLUGIN_SUPPORT
      if(msg.hwnd == NULL) {
	pluginHandleEvent(&msg);
      } else
#endif
	if(msg.hwnd != stWindow) {
	  /* Messages not sent to Squeak window */
	  if(msg.hwnd != consoleWindow && GetParent(msg.hwnd) == stWindow) {
	    /* This message has been sent to a plugin window */
	    /* Selectively pass up certain events to the parent's level */
	    switch (msg.message) {
	      case WM_LBUTTONDOWN:
	      case WM_LBUTTONUP:
	      case WM_MBUTTONDOWN:
	      case WM_MBUTTONUP:
	      case WM_RBUTTONDOWN:
	      case WM_RBUTTONUP:
	      case WM_MOUSEMOVE:
		mousePt.x = LOWORD(msg.lParam);
		mousePt.y = HIWORD(msg.lParam);
		MapWindowPoints(msg.hwnd, stWindow, &mousePt, 1);
		PostMessage(stWindow, msg.message, msg.wParam, MAKELONG(mousePt.x,mousePt.y));
	    }
	  }
	}
      TranslateMessage(&msg);
      DispatchMessage(&msg);
    }

#ifndef NO_DIRECTINPUT
  /* any buffered mouse input which hasn't been processed is obsolete */
  DumpBufferedMouseTrail();
#endif

  /* If we're running in a browser check if the browser's still there */
  if(fBrowserMode && browserWindow) {
    if(!IsWindow(browserWindow)) ioExit();
  }
  lastMessage = NULL;
  return 1;
}
#endif /* NewspeakVM */

double ioScreenScaleFactor(void)
{
    return 1.0;
}

/* returns the size of the Squeak window */
sqInt ioScreenSize(void)
{
  static RECT r;

  if(!IsWindow(stWindow)) return getSavedWindowSize();
  if(browserWindow && GetParent(stWindow) == browserWindow) {
    GetClientRect(browserWindow,&r);
  } else {
    if(!IsIconic(stWindow))
      GetClientRect(stWindow,&r);
  }
  /* width is high 16 bits; height is low 16 bits */
  return MAKELONG(r.bottom,r.right);
}

/* returns the depth of the OS display */
sqInt ioScreenDepth(void) {
  int depth;
  HDC dc = GetDC(stWindow);
  if(!dc) return 0; /* fail */
  depth = GetDeviceCaps(dc, BITSPIXEL);
  ReleaseDC(stWindow, dc);
  return depth;
}


sqInt ioSetCursorWithMask(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY)
{
#if !defined(_WIN32_WCE)
	/****************************************************/
	/* Only one cursor is defined under CE...           */
	/* (the wait cursor)                         :-(    */
	/****************************************************/
  static unsigned char *andMask=0,*xorMask=0;
  static int cx=0,cy=0,cursorSize=0;
  int i;

  if(!IsWindow(stWindow)) return 1;
  if(!andMask || !xorMask)
	{ /* Determine the cursor size.
		 NOTE: On NT this is actually not necessary, as NT _can_
		 create cursors of different sizes. However, on Win95 the
		 cursor will be created, BUT WILL NOT BE SHOWN! */
      cx = GetSystemMetrics(SM_CXCURSOR);
      cy = GetSystemMetrics(SM_CYCURSOR);
      cursorSize = cx*cy / 8;
      andMask = malloc(cursorSize);
      xorMask = malloc(cursorSize);
  }

  /* free last used cursor */
  if(currentCursor) DestroyCursor(currentCursor);

  memset(andMask,0xff,cursorSize);
  memset(xorMask,0x00,cursorSize);
  if(cursorMaskIndex)
    { /* New Cursors specify mask and bits:
         Mask    Bit    Result
         0       0      Transparent
         0       1      Invert
         1       0      White
         1       1      Black
      */
      for (i=0; i<16; i++)
        {
          andMask[i*cx/8+0] = ~(checkedLongAt(cursorMaskIndex + (4 * i)) >> 24) & 0xFF;
          andMask[i*cx/8+1] = ~(checkedLongAt(cursorMaskIndex + (4 * i)) >> 16) & 0xFF;
        }
      for (i=0; i<16; i++)
        {
          xorMask[i*cx/8+0] = (~(checkedLongAt(cursorBitsIndex + (4 * i)) >> 24) & 0xFF) ^ (andMask[i*cx/8+0]);
          xorMask[i*cx/8+1] = (~(checkedLongAt(cursorBitsIndex + (4 * i)) >> 16) & 0xFF) ^ (andMask[i*cx/8+1]);
        }
    }
  else /* Old Cursor: Just make all 1-bits black */
    for (i=0; i<16; i++)
      {
        andMask[i*cx/8+0] = ~(checkedLongAt(cursorBitsIndex + (4 * i)) >> 24) & 0xFF;
        andMask[i*cx/8+1] = ~(checkedLongAt(cursorBitsIndex + (4 * i)) >> 16) & 0xFF;
      }

  currentCursor = CreateCursor(hInstance,-offsetX,-offsetY,cx,cy,andMask,xorMask);
  if(currentCursor)
    {
      SetCursor(0);
      SetCursor(currentCursor);
    }
  else
    {
      printLastError(TEXT("CreateCursor failed"));
    }
#endif /* !defined(_WIN32_WCE) */
  return 1;
}

sqInt ioSetCursor(sqInt cursorBitsIndex, sqInt offsetX, sqInt offsetY) {
  return ioSetCursorWithMask(cursorBitsIndex, 0, offsetX, offsetY);
}

int ioSetCursorARGB(sqInt bitsIndex, sqInt w, sqInt h, sqInt x, sqInt y) {
  ICONINFO info;
  HBITMAP hbmMask = NULL;
  HBITMAP hbmColor = NULL;
  HDC mDC;
  unsigned int *srcBits = (unsigned int*)bitsIndex;
  unsigned int *dibBits=NULL, *maskBits=NULL;

  mDC = CreateCompatibleDC(NULL);

  /* We can leave the mask bits empty since we have an alpha channel below */
  bmi1->bmiHeader.biWidth = w;
  bmi1->bmiHeader.biHeight = -h;
  hbmMask = CreateDIBSection(mDC,bmi1,DIB_RGB_COLORS,(void **)&maskBits,0,0);

  bmi32->bmiHeader.biWidth = w;
  bmi32->bmiHeader.biHeight = -h;
  hbmColor = CreateDIBSection(mDC,bmi32,DIB_RGB_COLORS,(void **)&dibBits,0,0);
  memcpy(dibBits, srcBits, w*h*4);

  info.fIcon = 0;
  info.xHotspot = -x;
  info.yHotspot = -y;
  info.hbmMask = hbmMask;
  info.hbmColor = hbmColor;

  DestroyCursor(currentCursor);
  currentCursor = CreateIconIndirect(&info);
  if(hbmColor) DeleteObject(hbmColor);
  if(hbmMask) DeleteObject(hbmMask);
  if(mDC) DeleteDC(mDC);

  SetCursor(currentCursor);

  return 1;
}

sqInt ioSetFullScreen(sqInt fullScreen) {
  if(!IsWindow(stWindow)) return 1;
  if(wasFullScreen == fullScreen) return 1;
  /* NOTE: No modifications if the window is not currently
           visible, else we'll have a number of strange effects ... */
  if(!IsWindowVisible(stWindow)) {
    shouldBeFullScreen = fullScreen;
    return 1;
  }
  if(fullScreen)
    {
#if !defined(_WIN32_WCE)
      if(browserWindow) {
	/* Jump out of the browser */
	HWND oldBrowserWindow = browserWindow;
	browserWindow = NULL;
	DestroyWindow(stWindow);
	SetupWindows();
	/* I'm not exactly sure which one of the following three
	   does the trick for IE - but using all three works,
	   so hey, who cares ;-) */
	SetForegroundWindow(stWindow);
	SetActiveWindow(stWindow);
	BringWindowToTop(stWindow);
	/* SetWindowPos(stWindow, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW); */
	browserWindow = oldBrowserWindow;
      }
      SetWindowLongPtr(stWindow,GWL_STYLE, WS_POPUP | WS_CLIPCHILDREN);
      SetWindowLongPtr(stWindow,GWL_EXSTYLE, WS_EX_APPWINDOW);
      ShowWindow(stWindow, SW_SHOWMAXIMIZED);
#else /* !defined(_WIN32_WCE) */
      ShowWindow(stWindow,SW_SHOWNORMAL);
#endif /* !defined(_WIN32_WCE) */
      setFullScreenFlag(1);
    }
  else
    {
#if !defined(_WIN32_WCE)
      ShowWindow(stWindow, SW_RESTORE);
      ShowWindow(stWindow, SW_HIDE);
      SetWindowLongPtr(stWindow,GWL_STYLE, WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN);
      SetWindowLongPtr(stWindow,GWL_EXSTYLE, WS_EX_APPWINDOW /* | WS_EX_OVERLAPPEDWINDOW */ );
      SetWindowPos(stWindow,0,0,0,0,0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED | SWP_NOREDRAW);
      if(browserWindow) {
	/* Jump back into the browser */
	DestroyWindow(stWindow);
	SetupWindows();
      }
#endif /* !defined(_WIN32_WCE) */
      ShowWindow(stWindow,SW_SHOWNORMAL);
      setFullScreenFlag(0);
    }
  /* get us back in the foreground */
  SetForegroundWindow(stWindow);
  wasFullScreen = shouldBeFullScreen = fullScreen;
  return 1;
}

/****************************************************************************/
/*                           Image byte reversal                            */
/****************************************************************************/
#ifdef MSB_FIRST
# define BYTE_SWAP(w) w
# define WORD_SWAP(w) w
#else /* LSB_FIRST */
# if defined(__GNUC__) && (defined(_X86_) || defined(i386) || defined(__i386) || defined(__i386__))
   /* GCC generates *optimal* code with a little help */
#  define BYTE_SWAP(w) __asm__("bswap %0" : "+r" (w))
#  define WORD_SWAP(w) __asm__("roll $16, %0" : "+r" (w))
#  define SRC_PIX_REG asm("%esi")
#  define DST_PIX_REG asm("%edi")
# else /* Not GCC?! Well, it's your own fault ;-) */
#  define BYTE_SWAP(w) w = (w<<24) | ((w&0xFF00)<<8) | ((w>>8)&0xFF00) | (w>>24)
#  define WORD_SWAP(w) w = (( (unsigned)(w) << 16) | ((unsigned) (w) >> 16))
# endif /* __GNUC__ */
#endif /* MSB_FIRST */

#ifndef SRC_PIX_REG
# define SRC_PIX_REG
# define DST_PIX_REG
#endif

int reverse_image_bytes(unsigned int* dst, unsigned int *src,
			int depth, int width, RECT *rect)
{
  int pitch, first, last, nWords, delta, yy;

  /* --- SPECIAL HACK FOR WINDOWS CE --- */
#ifdef _WIN32_WCE
  int reverseBits = 0;
  if(depth == 1)
    reverseBits = 1;
#else
  /* compiler will optimize it away */
  static const int reverseBits = 0;
#endif

  /* note: all  of the below are in DWORDs not BYTEs */
  pitch = ((width * depth) + 31) / 32;
  first = (rect->left * depth) / 32;
  last  = ((rect->right * depth) + 31) / 32;
  nWords = last - first;
  delta = pitch - nWords;
  if(nWords <= 0) return 1;

  { /* the inner loop */
    register DWORD* srcPixPtr SRC_PIX_REG;
    register DWORD* dstPixPtr DST_PIX_REG;
    srcPixPtr = ((DWORD*)src) + (rect->top * pitch) + first;
    dstPixPtr = ((DWORD*)dst) + (rect->top * pitch) + first;
    if(reverseBits) {
      for(yy = rect->top; yy < rect->bottom;
	  yy++, srcPixPtr += delta, dstPixPtr += delta) {
	int i = nWords;
	do {
	  unsigned int value = *srcPixPtr++;
	  BYTE_SWAP(value);
	  *dstPixPtr++ = ~value;
	} while(--i);
      }
    } else { /* !reverseBits */
      for(yy = rect->top; yy < rect->bottom;
	  yy++, srcPixPtr += delta, dstPixPtr += delta) {
	int i = nWords;
	do {
	  unsigned int value = *srcPixPtr++;
	  BYTE_SWAP(value);
	  *dstPixPtr++ = value;
	} while(--i);
      }
    }
  }
  return 1;
}

int reverse_image_words(unsigned int *dst, unsigned int *src,
			int depth, int width, RECT *rect)
{
  int pitch, first, last, nWords, delta, yy;

  /* note: all  of the below are in DWORDs not BYTEs */
  pitch = ((width * depth) + 31) / 32;
  first = (rect->left * depth) / 32;
  last  = ((rect->right * depth) + 31) / 32;
  nWords = last - first;
  delta = pitch - nWords;
  if(nWords <= 0) return 1;

  { /* the inner loop */
    register DWORD* srcPixPtr SRC_PIX_REG;
    register DWORD* dstPixPtr DST_PIX_REG;
    srcPixPtr = ((DWORD*)src) + (rect->top * pitch) + first;
    dstPixPtr = ((DWORD*)dst) + (rect->top * pitch) + first;
    for(yy = rect->top; yy < rect->bottom;
	yy++, srcPixPtr += delta, dstPixPtr += delta) {
      int i = nWords;
      do {
	unsigned int value = *srcPixPtr++;
	WORD_SWAP(value);
	*dstPixPtr++ = value;
      } while(--i);
    }
  }
  return 1;
}

int copy_image_words(unsigned int *dst, unsigned int *src,
		     int depth, int width, RECT *rect)
{
  int pitch, first, last, nWords, delta, yy;

  /* note: all  of the below are in DWORDs not BYTEs */
  pitch = ((width * depth) + 31) / 32;
  first = (rect->left * depth) / 32;
  last  = ((rect->right * depth) + 31) / 32;
  nWords = last - first;
  delta = pitch - nWords;
  if(nWords <= 0) return 1;

  {/* the inner loop */
    DWORD* srcPixPtr;
    DWORD* dstPixPtr;
    srcPixPtr = ((DWORD*)src) + (rect->top * pitch) + first;
    dstPixPtr = ((DWORD*)dst) + (rect->top * pitch) + first;
    for(yy = rect->top; yy < rect->bottom;
	yy++, srcPixPtr += pitch, dstPixPtr += pitch) {
      memcpy(dstPixPtr, srcPixPtr, nWords*4);
    }
  }
  return 1;
}

#undef BYTE_SWAP
#undef WORD_SWAP
#undef SRC_PIX_REG
#undef DST_PIX_REG

/****************************************************************************/
/*              Display and printing                                        */
/****************************************************************************/

BITMAPINFO *BmiForDepth(int depth)
{ BITMAPINFO *bmi = NULL;
  switch(depth) {
    case 1: bmi = bmi1; break;
    case 4: bmi = bmi4; break;
    case 8: bmi = bmi8; break;
    case 16: bmi = bmi16; break;
    case 32: bmi = bmi32; break;
  }
  return bmi;
}

sqInt ioHasDisplayDepth(sqInt depth) {
  /* MSB variants */
  if(depth == 1 || depth == 4 || depth == 8 || depth == 16 || depth == 32)
    return 1;
  /* LSB variants */
  if(depth == -8 || depth == -16 || depth == -32)
    return 1;
  return 0;
}


sqInt ioSetDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag)
{
#ifdef _WIN32_WCE
  return 0; /* Not implemented on CE */
#else
  RECT r;
#ifdef USE_DIRECT_X
  static int wasFullscreen = 0;
  static HWND oldBrowserWindow = NULL;
#endif

  if(!IsWindow(stWindow)) return 0;
  if(!IsWindowVisible(stWindow)) return 0;

#ifdef USE_DIRECT_X
  if(wasFullscreen && !fullscreenFlag) {
    /* Some weird DirectX bug - if exclusive mode has been set for
       the main window you'll never get out of it. That's why we
       destroy and recreate the window here.
    */
    ioSetFullScreen(0); /* Turn off fullscreen */
    DirectXSetDisplayMode(stWindow, width, height, depth, 0);
    DestroyWindow(stWindow);
    browserWindow = oldBrowserWindow;
    SetupWindows();
    ShowWindow(stWindow, SW_SHOWNORMAL);
  }
  wasFullscreen = fullscreenFlag;
  if(fullscreenFlag && browserWindow) {
    /* Must get out of browser window */
    oldBrowserWindow = browserWindow;
    browserWindow = NULL;
    DestroyWindow(stWindow);
    SetupWindows();
    ShowWindow(stWindow, SW_SHOWNORMAL);
  }
  if(!DirectXSetDisplayMode(stWindow, width, height, depth, fullscreenFlag)) {
    /* We must carefully restore the old window here */
    if(oldBrowserWindow) {
      DestroyWindow(stWindow);
      browserWindow = oldBrowserWindow;
      SetupWindows();
      ShowWindow(stWindow, SW_SHOWNORMAL);
    }
    return 0;
  }
  /* Note: Only go to full screen if DirectX is used */
  ioSetFullScreen(fullscreenFlag);
#endif

  r.left = 0;
  r.top = 0;
  r.right = width;
  r.bottom = height;
  if(browserWindow) {
    r.right = GetSystemMetrics(SM_CXSCREEN);
    r.bottom = GetSystemMetrics(SM_CYSCREEN);
  } else {
    AdjustWindowRect(&r, GetWindowLongPtr(stWindow, GWL_STYLE), 0);
  }
  SetWindowPos(stWindow, NULL, 0, 0, r.right-r.left, r.bottom-r.top,
	       SWP_NOMOVE | SWP_NOZORDER);
  SetFocus(stWindow);
  return 1;
#endif /* _WIN32_WCE */
}

/* force an update of the squeak window if using deferred updates */
sqInt ioForceDisplayUpdate(void) {
	/* With Newspeak and the native GUI we do not want the main window to appear
	 * unless explicitly asked for.
	 */
#if !NewspeakVM
  /* Show the main window if it's been hidden so far */
  if(IsWindow(stWindow) && !IsWindowVisible(stWindow)) {
    HideSplashScreen();
    ShowWindow(stWindow, SW_SHOW);
    if(wasFullScreen != shouldBeFullScreen) 
      ioSetFullScreen(shouldBeFullScreen);
    UpdateWindow(stWindow);
  }
#endif
  /* Check if
     a) We should do deferred updates at all
     b) The window is valid
     c) The Interpreter does not defer updates by itself
  */
  if(fDeferredUpdate && IsWindow(stWindow) && !deferDisplayUpdates)
      UpdateWindow(stWindow);
  return 1;
}

sqInt ioFormPrint(sqInt bitsAddr, sqInt width, sqInt height, sqInt depth, double hDPI, double vDPI, sqInt landscapeFlag)
	/* print a form with the given bitmap, width, height, and depth at
	   the given horizontal and vertical scales in the given orientation */
{
#ifdef NO_PRINTER
  warnPrintf(TEXT("This VM does not support printing.\n"));
  return success(false);
#else /* !defined(NO_PRINTER) */
  DEVMODE *dmPtr;
  BITMAPINFO *bmi;
  DOCINFO di;
  HDC dc;
  DEVNAMES *devNames;
  TCHAR *namePtr;
  RECT targetRect;
  int scWidth;
  int scHeight;

  if(!printerSetup) SetupPrinter();
  devNames = GlobalLock(printValues.hDevNames);
  if(!devNames)
    {
      warnPrintf(TEXT("No printer configured\n"));
      return false;
    }
  dmPtr = GlobalLock(printValues.hDevMode);
  if(dmPtr)
    {
      dmPtr->dmOrientation = landscapeFlag ? DMORIENT_LANDSCAPE : DMORIENT_PORTRAIT;
      dmPtr->dmFields |= DM_ORIENTATION;
    }
  namePtr = (TCHAR*) devNames;
  dc = CreateDC(namePtr+devNames->wDriverOffset,
                namePtr+devNames->wDeviceOffset,
                namePtr+devNames->wOutputOffset,
                dmPtr);
  GlobalUnlock(printValues.hDevMode);
  GlobalUnlock(printValues.hDevNames);

  if(!dc)
    {
      warnPrintf(TEXT("Unable to open printer.\n"));
      return false;
    }

  bmi = BmiForDepth(depth);
  if(!bmi)
    {
      warnPrintf(TEXT("Color depth %") TEXT(PRIdSQINT) TEXT(" not supported"), depth);
      return false;
    }

  di.cbSize      = sizeof(DOCINFO);
  di.lpszDocName = TEXT(VM_NAME) TEXT(" Print Job");
  di.lpszOutput  = NULL;

  StartDoc  (dc, &di);
  StartPage (dc);

  bmi->bmiHeader.biWidth = width;
  bmi->bmiHeader.biHeight = height;
  bmi->bmiHeader.biSizeImage = 0;

  /* set device coords to 0.001 inch per unit */

  SetMapMode(dc, MM_HIENGLISH);
  scWidth = (int)(width * 1000.0 / hDPI);
  scHeight = (int)(height * 1000.0 / vDPI );

  /* reverse the image bits if necessary */
  targetRect.left = targetRect.top = 0;
  targetRect.right = width;
  targetRect.bottom = height;
#ifndef NO_BYTE_REVERSAL
  if( depth < 32 ) {
    if(depth == 16)
      reverse_image_words((unsigned int*) bitsAddr, (unsigned int*) bitsAddr,
			  depth, width, &targetRect);
    else
      reverse_image_bytes((unsigned int*) bitsAddr, (unsigned int*) bitsAddr,
			  depth, width, &targetRect);
  }
#endif /* NO_BYTE_REVERSAL */

  if(GDI_ERROR == StretchDIBits(dc,
                0,         /* dst_x */
                -scHeight, /* dst_y --- mapping mode changes positive y-axis */
                scWidth,   /* dst_w */
                scHeight,  /* dst_h */
                0,         /* src_x */
                0,         /* src_y */
                width,     /* src_w */
                height,    /* src_h */
                (void*) bitsAddr, /* bits */
                bmi,
                DIB_RGB_COLORS,
                SRCCOPY)) printLastError(TEXT("StretchDIBits failed"));

  /* reverse the image bits if necessary */
#ifndef NO_BYTE_REVERSAL
  if( depth < 32 ) {
    if(depth == 16)
      reverse_image_words((unsigned int*) bitsAddr, (unsigned int*) bitsAddr,
			  depth, width, &targetRect);
    else
      reverse_image_bytes((unsigned int*) bitsAddr, (unsigned int*) bitsAddr,
			  depth, width, &targetRect);
  }
#endif /* NO_BYTE_REVERSAL */

  EndPage   (dc);
  EndDoc    (dc);
  DeleteDC  (dc);

	return true;
#endif /* NO_PRINTER */
}


#ifdef USE_DIB_SECTIONS

/* CreateBitmapDC():
   Create a device context for a DIB of the selected size.
*/
HDC CreateBitmapDC(HDC dc, int depth, int width, int height, void** pBitsOut)
{
  /* Cached DIBSection */
  static HBITMAP hbm = NULL;
  static int lastDepth = 0;
  static int lastWidth = 0;
  static int lastHeight = 0;
  static void* pBits;
  static HDC memDC;
  BITMAPINFO *bmi;

  bmi = BmiForDepth(depth);
  if(!bmi)
    abortMessage(TEXT("Fatal error: Color depth %d not supported"),depth);

  if (depth != lastDepth || width != lastWidth || height != lastHeight)
    {
      lastDepth = depth;
      lastHeight = height;
      lastWidth = width;
      bmi->bmiHeader.biWidth = width;
      bmi->bmiHeader.biHeight = -height;
      if (hbm)
	DeleteObject(hbm);
      hbm = CreateDIBSection(dc, bmi, DIB_RGB_COLORS, &pBits, NULL, 0);
      if (!hbm)
	abortMessage(TEXT("Fatal error: Cannot create device bitmap!"));
    }

  *pBitsOut = pBits;
  memDC = CreateCompatibleDC(dc);
  SelectObject(memDC, hbm);
  return memDC;
}

/* ReleaseBitmapDC():
   Clean up the given DC.
*/
void ReleaseBitmapDC(HDC memDC)
{
  DeleteDC(memDC);
}

#endif /* USE_DIB_SECTIONS */

sqInt ioShowDisplay(sqInt dispBits, sqInt width, sqInt height, sqInt depth,
		  sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB)
{ HDC dc;
  BITMAPINFO *bmi;
  int lines;
  int lsbDisplay;

  if(!IsWindow(stWindow))
    return 0;

  if(affectedR < affectedL || affectedT > affectedB)
    return 1;
#if 0
  if(ioDirectXShowDisplayBits(dispBits, width, height, depth,
			      affectedL, affectedR, affectedT, affectedB))
    return 1;
#endif
  /* Try to accumulate the changes */
  if(!updateRightNow)
    {
      updateRect.left = affectedL;
      updateRect.top = affectedT;
      updateRect.right = affectedR;
      updateRect.bottom = affectedB;
      /* Acknowledge the request for deferred updates only
         if the interpreter is not deferring these by itself */
      if(fDeferredUpdate && !deferDisplayUpdates)
        {
          /* Wait until the next WM_PAINT gets processed */
          InvalidateRect(stWindow,&updateRect,FALSE);
          return 1;
        }
      else
        /* Set the update region manually */
        SetRectRgn(updateRgn, updateRect.left, updateRect.top,
		   updateRect.right,updateRect.bottom);
    }
  else
    {
      /* After a paint, so get affected area from update rect */
      updateRightNow = FALSE;
    }
  if (IsRectEmpty(&updateRect)) return 1; /* Nothing to do */

  affectedL = updateRect.left;
  affectedT = updateRect.top;
  affectedR = updateRect.right;
  affectedB = updateRect.bottom;

  /* Careful here:
     After resizing the main window the affected area can
     be larger than the area covered by the display bits ... */
  if (affectedR > width) affectedR= width-1;
  if (affectedB > height) affectedB= height-1;
  /* ... and don't forget left and top - else reverse_image_* will crash */
  if (affectedL > width) affectedL= width-1;
  if (affectedT > height) affectedT= height-1;

  /* Don't draw empty areas */
  if(affectedL == affectedR || affectedT == affectedB) return 1;
  /* reload the update rectangle */
  updateRect.left = affectedL;
  updateRect.top = affectedT;
  updateRect.right = affectedR;
  updateRect.bottom = affectedB;
  /* ----- EXPERIMENTAL ----- */
  lsbDisplay = depth < 0;
  if(lsbDisplay) depth = -depth;

#if defined(USE_DIB_SECTIONS)
	/******************************************************/
	/* Windows CE version, using DIBSection               */
	/* (does not support palettes or SetDIBitsToDevice()) */
	/******************************************************/
  {
    void* pBits;
    HDC memDC;

    dc = GetDC(stWindow);
    if (!dc)
      error("GetDC() failed");

    memDC = CreateBitmapDC(dc, depth, width, height, &pBits);
    /* Reverse the affected area out of the squeak bitmap, into the DIBSection */

    PROFILE_BEGIN(PROFILE_DISPLAY)
      if( !lsbDisplay && depth < 32 ) {
	if(depth == 16)
	  reverse_image_words((unsigned int*) pBits, (unsigned int*) dispBits,
			      depth, width, &updateRect);
	else
	  reverse_image_bytes((unsigned int*) pBits, (unsigned int*) dispBits,
			      depth, width, &updateRect);
      } else {
	copy_image_words((int*)pBits, (int*) dispBits,
			 depth, width, &updateRect);
      }
    PROFILE_END(ticksForReversal)

      PROFILE_BEGIN(PROFILE_DISPLAY);
    BitBlt(dc,
	   updateRect.left,/* dst_x */
	   updateRect.top, /* dst_y */
	   (updateRect.right - updateRect.left),/* dst_w */
	   (updateRect.bottom - updateRect.top),/* dst_h */
	   memDC,
	   updateRect.left, /* src_x */
	   updateRect.top,  /* src_y */
	   SRCCOPY);

    ReleaseBitmapDC(memDC);
    ReleaseDC(stWindow,dc);
    PROFILE_END(ticksForBlitting);
  }
#else /* !defined(USE_DIB_SECTIONS) */

  bmi = BmiForDepth(depth);
  if(!bmi)
    {
      abortMessage(TEXT("Aborting!!!!\nColor depth %d not supported"),depth);
    }

  /* reverse the image bits if necessary */
#ifndef NO_BYTE_REVERSAL
  PROFILE_BEGIN(PROFILE_DISPLAY)
  if( !lsbDisplay && depth < 32 ) {
    if(depth == 16)
      reverse_image_words((unsigned int*) dispBits, (unsigned int*) dispBits,
			  depth, width, &updateRect);
    else
      reverse_image_bytes((unsigned int*) dispBits, (unsigned int*) dispBits,
			  depth, width, &updateRect);
  }
  PROFILE_END(ticksForReversal)
#endif /* NO_BYTE_REVERSAL */

  bmi->bmiHeader.biWidth = width;
  bmi->bmiHeader.biHeight = -height;
  bmi->bmiHeader.biSizeImage = 0;

  dc = GetDC(stWindow);
  if(!dc) {
    printLastError(TEXT("ioShowDisplayBits: GetDC() failed"));
    return 0;
  }

  SelectPalette(dc,palette,0);
  RealizePalette(dc);


  PROFILE_BEGIN(PROFILE_DISPLAY)
  /* use the actual affected region rather than
     the complete recangle for clipping */
  SelectClipRgn(dc,updateRgn);

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

  if(lines == 0) {
    /* Note: the above is at least five times faster than what follows.
       Unfortunately, it also requires quite a bit of resources to
       be available. These are almost always available except in a
       few extreme conditions - but to compensate for those the
       following is provided. */
    int pitch, start, end, nPix, line, left;
    sqIntptr_t bitsPtr;

    /* compute pitch of form */
    pitch = ((width * depth) + 31 & ~31) / 8;
    /* compute first word of update region */
    start = ((updateRect.left * depth) & ~31) / 8;
    /* compute last word of update region */
    end   = ((updateRect.right * depth) + 31 & ~31) / 8;
    /* compute #of bits covered in update region */
    nPix = ((end - start) * 8) / depth;
    left = (start * 8) / depth;
    bmi->bmiHeader.biWidth = nPix;
    bmi->bmiHeader.biHeight = 1;
    bmi->bmiHeader.biSizeImage = 0;
    bitsPtr = dispBits + start + (updateRect.top * pitch);
    for(line = updateRect.top; line < updateRect.bottom; line++) {
      lines = SetDIBitsToDevice(dc, left, line, nPix, 1, 0, 0, 0, 1,
				(void*) bitsPtr, bmi, DIB_RGB_COLORS);
      bitsPtr += pitch;
    }
  }

  SelectClipRgn(dc,NULL);
  PROFILE_END(ticksForBlitting)

  ReleaseDC(stWindow,dc);

  if(lines == 0) {
    printLastError(TEXT("SetDIBitsToDevice failed"));
    warnPrintf(TEXT("width=%") TEXT(PRIdSQINT) TEXT(",height=%") TEXT(PRIdSQINT) TEXT(",bits=%") TEXT(PRIXSQINT) TEXT(",dc=%") TEXT(PRIXSQINT) TEXT("\n"),
	       width, height, dispBits,(usqIntptr_t)dc);
  }
  /* reverse the image bits if necessary */
#ifndef NO_BYTE_REVERSAL
  PROFILE_BEGIN(PROFILE_DISPLAY)
  if( !lsbDisplay && depth < 32 ) {
    if(depth == 16)
      reverse_image_words((unsigned int*) dispBits, (unsigned int*) dispBits,
			  depth, width, &updateRect);
    else
      reverse_image_bytes((unsigned int*) dispBits, (unsigned int*) dispBits,
			  depth, width, &updateRect);
  }
  PROFILE_END(ticksForReversal)
#endif /* NO_BYTE_REVERSAL */
#endif /* defined(_WIN32_WCE) */
  return 1;
}

/****************************************************************************/
/*                      Clipboard                                           */
/****************************************************************************/

sqInt clipboardSize(void) { 
  HANDLE h;
  WCHAR *src;
  int i, count, bytesNeeded;

  /* Do we have text in the clipboard? */
  if(!IsClipboardFormatAvailable(CF_UNICODETEXT))
    return 0;

  if(!OpenClipboard(stWindow))
    return 0;

  /* Get it in unicode format. */
  h = GetClipboardData(CF_UNICODETEXT);
  src = GlobalLock(h);

  /* How many bytes do we need to store those unicode chars in UTF8 format? */
  bytesNeeded = WideCharToMultiByte(CP_UTF8, 0, src, -1,
				    NULL, 0, NULL, NULL );
  if (bytesNeeded > 0) {
    unsigned char *tmp = malloc(bytesNeeded+1);

    /* Convert Unicode text to UTF8. */
    WideCharToMultiByte(CP_UTF8, 0, src, -1, tmp, bytesNeeded , NULL, NULL);

    /* Count CrLfs for which we remove the extra Lf */
    count = bytesNeeded; /* ex. terminating zero */
    for(i=0; i<count; i++) {
      if((tmp[i] == 13) && (tmp[i+1] == 10)) bytesNeeded--;
    }
    bytesNeeded--; /* discount terminating zero */
    free(tmp); /* no longer needed */
  }

  GlobalUnlock(h);
  CloseClipboard();

  return bytesNeeded;
}

/* send the given string to the clipboard */
sqInt clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex) {
  HANDLE h;
  unsigned char *src, *tmp, *cvt;
  int i, wcharsNeeded, utf8Count;
  WCHAR *out;

  if(!OpenClipboard(stWindow))
    return 0;

  /* Get the pointer to the byte array. */
  src = (unsigned char *)byteArrayIndex + startIndex;

  /* Count lone CRs for which we want to add an extra Lf */
  for(i=0, utf8Count=count; i<count; i++) {
    if((src[i] == 13) && (src[i+1] != 10)) utf8Count++;
  }

  /* allocate temporary storage and copy string (inserting Lfs) */
  cvt = tmp = malloc(utf8Count+1);
  for(i=0;i<count;i++,tmp++,src++) {
    *tmp = *src;
    if(src[0] == 13 && src[1] != 10) {
      tmp++;
      *tmp = 10;
    }
  }
  *tmp = 0; /* terminating zero */

  /* Note: At this point we have a valid UTF-8, CrLf-containing,
     zero-terminated C-string. Phew. Now just make it UTF-16 and be done */

  /* How many WCHARs do we need to store the UTF8 bytes from Squeak? */
  wcharsNeeded = MultiByteToWideChar(CP_UTF8, 0, cvt, -1, NULL, 0);

  /* Allocate needed memory for wcharsNeeded WCHARs. */
  h = GlobalAlloc(GMEM_MOVEABLE | GMEM_DDESHARE, wcharsNeeded * sizeof(WCHAR));
  out = GlobalLock(h);

  /* Convert data to Unicode UTF16. */
  MultiByteToWideChar( CP_UTF8, 0, cvt, -1, out, wcharsNeeded );

  /* Send the Unicode text to the clipboard. */
  EmptyClipboard();
  SetClipboardData(CF_UNICODETEXT, h);

  /* Note: After setting clipboard data,
     the memory block previously allocated belongs to
     the clipboard - not to the app. */
  CloseClipboard();
  free(cvt);
  return 1;
}


/* transfer the clipboard data into the given byte array */
sqInt clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex) {
  HANDLE h;
  unsigned char *dst, *cvt, *tmp;
  WCHAR *src;
  int i, bytesNeeded;


  /* Check if we have Unicode text available */
  if(!IsClipboardFormatAvailable(CF_UNICODETEXT))
    return 0;

  if(!OpenClipboard(stWindow))
    return 0;

  /* Get clipboard data in Unicode format */
  h = GetClipboardData(CF_UNICODETEXT);
  src = GlobalLock(h);

  /* How many bytes do we need to store the UTF8 representation? */
  bytesNeeded = WideCharToMultiByte(CP_UTF8, 0, src, -1,
				    NULL, 0, NULL, NULL );

  /* Convert Unicode text to UTF8. */
  cvt = tmp = malloc(bytesNeeded);
  WideCharToMultiByte(CP_UTF8, 0, src, -1, tmp, bytesNeeded, NULL, NULL);

  /* Copy data, skipping Lfs as needed */
  dst = (unsigned char *)byteArrayIndex + startIndex;
  for(i=0;i<count;i++,dst++,tmp++) {
    *dst = *tmp;
    if(((tmp[0] == 13) && (tmp[1] == 10))) tmp++;
  }  
  free(cvt);

  GlobalUnlock(h);
  CloseClipboard();
  return count;
}


/****************************************************************************/
/*                    Image / VM File Naming                                */
/****************************************************************************/

sqInt vmPathSize(void)
{
  return lstrlen(vmPath);
}

sqInt vmPathGetLength(sqInt sqVMPathIndex, sqInt length)
{
  char *stVMPath= (char *)sqVMPathIndex;
  int count, i;

  count= lstrlen(vmPath);
  count= (length < count) ? length : count;

  /* copy the file name into the Squeak string */
  for (i= 0; i < count; i++)
    stVMPath[i]= (char) vmPath[i]; /* will remove leading zeros from unicode */

  return count;
}

sqInt imageNameSize(void)
{
  return strlen(imageName);
}

sqInt imageNameGetLength(sqInt sqImageNameIndex, sqInt length)
{
  char *sqImageName= (char *)sqImageNameIndex;
  int count, i;

  count= strlen(imageName);
  count= (length < count) ? length : count;

  /* copy the file name into the Squeak string */
  for (i= 0; i < count; i++)
    sqImageName[i]= imageName[i];

  return count;
}

sqInt imageNamePutLength(sqInt sqImageNameIndex, sqInt length)
{
  char *sqImageName= (char *)sqImageNameIndex;
  char tmpImageName[MAX_PATH+1];
  char *tmp;
  int count, i;

  count= (IMAGE_NAME_SIZE < length) ? IMAGE_NAME_SIZE : length;

  /* copy the file name into a null-terminated C string */
  for (i= 0; i < count; i++)
    tmpImageName[i]= sqImageName[i];

  tmpImageName[count]= 0;

  /* Note: We have to preserve the fully qualified image path */
  tmp = strrchr(tmpImageName,'\\');
  if(tmp)
    { /* fully qualified */
      strcpy(imageName,tmpImageName);
    }
  else
    { /* not qualified */
      tmp = strrchr(imageName,'\\');
      if(!tmp)
        strcpy(imageName,tmpImageName);
      else
        {
          tmp++; *tmp = 0;
          count = IMAGE_NAME_SIZE - (tmp-imageName);
          if(count < length)
            tmpImageName[count] = 0;
          strcat(imageName,tmpImageName);
        }
    }
  SetWindowTitle();
  return 1;
}

sqInt sqGetFilenameFromString(char *buf, char *fileName, sqInt length, sqInt alias) {
  memcpy(buf, fileName, length);
  buf[length] = 0;
  return 1;
}

/****************************************************************************/
/*                      System Attributes                                   */
/****************************************************************************/
extern char *hwInfoString;
extern char *osInfoString;
extern char *gdInfoString;
extern char *win32VersionName;

char * GetAttributeString(sqInt id) {
	/* This is a hook for getting various status strings back from
	   the OS. In particular, it allows Squeak to be passed arguments
	   such as the name of a file to be processed. Command line options
	   could be reported this way as well.
	*/
  /* id == 0 : return the full name of the VM */
  if(id == 0) return fromUnicode(vmName);
  /* 0 < id <= 1000 : return options of the image (e.g. given *after* the image name) */
  if(id > 0 && id <= 1000)
    return GetImageOption(id-1);
  /* id < 0 : return options of the VM (e.g. given *before* the image name) */
  if(id < 0)
    return GetVMOption(-id);
  /* special attributes */
  switch(id) {
    case 1001: /* Primary OS type */
      return WIN32_NAME;
    case 1002: /* Secondary OS type */
      return win32VersionName;
    case 1003:/* Processor type */
      return WIN32_PROCESSOR_NAME;
    case 1004:
      return (char*) interpreterVersion;
    case 1005: /* window system name */
      return "Win32";
    case 1006: /* VM build ID */
      return vmBuildString;
#if STACKVM
	case 1007: { /* interpreter build info */
		extern char *__interpBuildInfo;
		return __interpBuildInfo;
	}
# if COGVM
	case 1008: { /* cogit build info */
		extern char *__cogitBuildInfo;
		return __cogitBuildInfo;
	}
# endif
#endif

	  case 1009: /* source tree version info */
		return sourceVersionString(' ');

    /* Windows internals */
    case 10001: /* addl. hardware info */
      return hwInfoString;
    case 10002: /* addl. hardware info */
      return osInfoString;
    case 10003: /* addl. hardware info */
      return gdInfoString;
  }
  return NULL;
}

sqInt attributeSize(sqInt id) {
  char *attrValue;
  attrValue = GetAttributeString(id);
  if(!attrValue) return primitiveFail();
  return strlen(attrValue);
}

sqInt getAttributeIntoLength(sqInt id, sqInt byteArrayIndex, sqInt length) {
  char *srcPtr, *dstPtr, *end;
  int charsToMove;

  srcPtr = GetAttributeString(id);
  if(!srcPtr) return 0;
  charsToMove = strlen(srcPtr);
  if (charsToMove > length) {
    charsToMove = length;
  }

  dstPtr = (char *) byteArrayIndex;
  end = srcPtr + charsToMove;
  while (srcPtr < end) {
    *dstPtr++ = *srcPtr++;
  }
  return charsToMove;
}


/****************************************************************************/
/*                      File Startup                                        */
/****************************************************************************/

int sqLaunchDrop(void) {
  HANDLE h;
  WCHAR *src, **argv=NULL;
  char tmp[MAX_PATH];
  int argc=0;

#ifdef __MINGW32__
  /* For some weird reason I cannot link CommandLineToArgvW correctly.
     Work around it for now. */
  static LPWSTR* (WINAPI *sqCommandLineToArgvW)(LPCWSTR,int*) = NULL;
  if(!sqCommandLineToArgvW) {
    HANDLE hShell32 = LoadLibrary("shell32.dll");
    sqCommandLineToArgvW=(void*)GetProcAddress(hShell32, "CommandLineToArgvW");
    if(!sqCommandLineToArgvW) return 0;
  }
#else
#define sqCommandLineToArgvW CommandLineToArgvW
#endif

  /* Do we have text in the clipboard? */
  if(!IsClipboardFormatAvailable(CF_UNICODETEXT)) return 0;
  if(!OpenClipboard(stWindow)) return 0;

  /* Get clipboard data in unicode format. */
  h = GetClipboardData(CF_UNICODETEXT);
  src = GlobalLock(h);
  argv = sqCommandLineToArgvW(src, &argc);
  GlobalUnlock(h);
  CloseClipboard();
  if(argc < 2) return 0;

  /* Convert Unicode text to UTF8. */
  WideCharToMultiByte(CP_UTF8, 0, argv[argc-1], -1, tmp, MAX_PATH, 
		      NULL, NULL);
  dropLaunchFile(tmp);
  LocalFree(argv);
  return 1;
}

/* Check if the path/file name is subdirectory of the image path */
int isLocalFileName(TCHAR *fileName)
{
  int i;
  for(i=0; i<lstrlen(imagePath); i++)
    if(imagePath[i] != fileName[i]) return 0;
  return 1;
}

#if defined(_WIN32_WCE)
	/* WinCE does not support short file names, and has
	   no concept of a current directory. Space is at a
	   premium, the file system is small, and we are unlikely
	   to have a full sources file anyway (too big). All these
	   factors means that we stick with a simpler scheme, of
	   either requiring the image name to be fully pathed, or
	   if not, popping up a file open dialog */

void SetupFilesAndPath(){ 
  char *tmp;
  lstrcpy(imagePath, imageName);
  tmp = lstrrchr(imagePath,'\\');
  if(tmp) tmp[1] = 0;
}

#else /* defined(_WIN32_WCE) */

void
LongFileNameFromPossiblyShortName(TCHAR *nameBuffer)
{ TCHAR oldDir[MAX_PATH+1];
  TCHAR testName[13];
  TCHAR nameBuf[MAX_PATH+1];
  TCHAR *shortName;
  WIN32_FIND_DATA findData;
  HANDLE findHandle;

  GetCurrentDirectory(MAX_PATH,oldDir);
  shortName = lstrrchr(nameBuffer,U_BACKSLASH[0]);
  if(!shortName) shortName = lstrrchr(nameBuffer,U_SLASH[0]);
  if(!shortName) return;
  /* if the file name is longer than 8.3
     this can't be a short name */
  *(shortName++) = 0;
  if(lstrlen(shortName) > 12)
    goto notFound;

  /* back up the old and change to the given directory,
     this makes searching easier */
  lstrcpy(nameBuf, nameBuffer);
  lstrcat(nameBuf,TEXT("\\"));
  SetCurrentDirectory(nameBuf);

  /* now search the directory */
  findHandle = FindFirstFile(TEXT("*.*"),&findData);
  if(findHandle == INVALID_HANDLE_VALUE) goto notFound; /* nothing found */
  do {
    if(lstrcmp(findData.cFileName,TEXT("..")) && lstrcmp(findData.cFileName,TEXT(".")))
      lstrcpy(testName,findData.cAlternateFileName);
    else
      *testName = 0;
    if(lstrcmp(testName,shortName) == 0) /* gotcha! */
      {
        FindClose(findHandle);
        /* recurse down */
        lstrcpy(nameBuf, findData.cFileName);
        goto recurseDown;
      }
  } while(FindNextFile(findHandle,&findData) != 0);
  /* nothing appropriate found */
  FindClose(findHandle);
notFound:
  lstrcpy(nameBuf, shortName);
recurseDown:
  /* recurse down */
  LongFileNameFromPossiblyShortName(nameBuffer);
  lstrcat(nameBuffer,TEXT("\\"));
  lstrcat(nameBuffer,nameBuf);
  SetCurrentDirectory(oldDir);
}

void SetupFilesAndPath() {
  char *tmp;
  WCHAR tmpName[MAX_PATH];
  WCHAR imageNameW[MAX_PATH];

  /* get the full path for the image */
  MultiByteToWideChar(CP_UTF8, 0, imageName, -1, tmpName, MAX_PATH);
  GetFullPathNameW(tmpName, MAX_PATH, imageNameW, NULL);

  /* and copy back to a UTF-8 string */
  WideCharToMultiByte(CP_UTF8, 0, imageNameW,-1,imageName,MAX_PATH,NULL,NULL);

  /* get the VM directory */
  lstrcpy(vmPath, vmName);
  tmp = lstrrchr(vmPath,U_BACKSLASH[0]);
  if(tmp) *tmp = 0;
  lstrcat(vmPath,U_BACKSLASH);

  lstrcpy(imagePath, imageName);
  tmp = lstrrchr(imagePath,U_BACKSLASH[0]);
  if(tmp) tmp[1] = 0;
}

#endif /* !defined(_WIN32_WCE) */

/* SqueakImageLength():
   Return the length of the image if it is a valid Squeak image file.
   Otherwise return 0. */
DWORD SqueakImageLengthFromHandle(HANDLE hFile) {
  DWORD dwRead, dwSize, magic = 0;
  /* get the file size */
  dwSize = GetFileSize(hFile, NULL);
  /* seek to start */
  if(SetFilePointer(hFile, 0, NULL, FILE_BEGIN) != 0) return 0;
  /* read magic number */
  if(!ReadFile(hFile, &magic, 4, &dwRead, NULL)) return 0;
  /* see if it matches */
  if(readableFormat(magic) || readableFormat(byteSwapped(magic))) return dwSize;
  /* skip possible 512 byte header */
  dwSize -= 512;
  if(SetFilePointer(hFile, 512, NULL, FILE_BEGIN) != 512) return 0;
  /* read magic number */
  if(!ReadFile(hFile, &magic, 4, &dwRead, NULL)) return 0;
  /* see if it matches */
  if(readableFormat(magic) || readableFormat(byteSwapped(magic))) return dwSize;
  return 0;
}

DWORD SqueakImageLength(char *fileName) {
  DWORD dwSize;
  WCHAR wideName[MAX_PATH];
  HANDLE hFile;

  /* open image file */
  MultiByteToWideChar(CP_UTF8, 0, fileName, -1, wideName, MAX_PATH);
  hFile = CreateFileW(wideName, GENERIC_READ, FILE_SHARE_READ,
		      NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
  if(hFile == INVALID_HANDLE_VALUE) return 0;
  dwSize = SqueakImageLengthFromHandle(hFile);
  CloseHandle(hFile);
  return dwSize;
}

/****************************************************************************/
/*                      Startup helper functions                            */
/****************************************************************************/

/* findImageFile():
   Search the current directory for exactly one image file.
   If it is found, copy the name into imageName and return true.
*/
int findImageFile(void) {
  WIN32_FIND_DATAW findData;
  HANDLE findHandle;
  int nextFound;

  findHandle = FindFirstFileW(L"*.image",&findData);
  if(findHandle == INVALID_HANDLE_VALUE) return 0; /* Not found */
  nextFound = FindNextFileW(findHandle,&findData);
  FindClose(findHandle);
  if(nextFound) return 0; /* more than one entry */
  WideCharToMultiByte(CP_UTF8, 0, findData.cFileName, -1, 
		      imageName, MAX_PATH, NULL, NULL);
  return 1;
}

/* openImageFile():
   Pop up a file open dialog for image files.
   Copy the selection into imageName and return true.
*/
int openImageFile(void) {
  OPENFILENAMEW ofn;
  WCHAR path[MAX_PATH];

  memset(&ofn, 0, sizeof(ofn));
  path[0] = 0;
  ofn.lStructSize = sizeof(ofn);
  ofn.lpstrFilter = L"Image Files (*.image)\0*.image\0All Files (*.*)\0*.*\0";
  ofn.lpstrFile = path;
  ofn.nMaxFile = MAX_PATH;
#ifdef __GNUC__
  ofn.lpstrTitle = L""VM_NAME": Please select an image file...";
#else
  ofn.lpstrTitle = L"Please select an image file...";
#endif
  ofn.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;
  ofn.lpstrDefExt = L"image";
  if (!GetOpenFileNameW(&ofn)) return 0;
  WideCharToMultiByte(CP_UTF8, 0, path, -1, 
		      imageName, MAX_PATH, NULL, NULL);
  return 1;
}

/****************************************************************************/
/*                       Splash screen functions                            */
/****************************************************************************/

static HBITMAP hSplashDIB = NULL;
static HWND hSplashWnd = NULL;
static DWORD startTime;
static DWORD splashTime;

/* splash window procedure */
static LRESULT CALLBACK SplashWndProcA(HWND hwnd,
				UINT message,
				WPARAM wParam,
				LPARAM lParam) {
  PAINTSTRUCT ps;
  HDC mdc;
  HANDLE hOld;

  switch(message) {
  case WM_PAINT:
    BeginPaint(hwnd,&ps);
    mdc = CreateCompatibleDC(ps.hdc);
    hOld = SelectObject(mdc, hSplashDIB);
    BitBlt(ps.hdc, ps.rcPaint.left, ps.rcPaint.top,
	   ps.rcPaint.right-ps.rcPaint.left,
	   ps.rcPaint.bottom-ps.rcPaint.top,
	   mdc,
	   ps.rcPaint.left,
	   ps.rcPaint.top,
	   SRCCOPY);
    SelectObject(mdc, hOld);
    DeleteDC(mdc);
    EndPaint(hwnd,&ps);
    break;
  default:
    return DefWindowProc(hwnd, message, wParam, lParam);
  }
  return 1;
}

void ShowSplashScreen(void) {
  WNDCLASS wc;
  char splashFile[1024];
  char splashTitle[1024];
  BITMAP bm;
  RECT wa, rSplash;

  /* Look if we have a splash file somewhere */
  GetPrivateProfileString("Global", "SplashScreen", "Splash.bmp", 
			  splashFile, 1024, squeakIniName);

  /* Also get the title for the splash window */
  GetPrivateProfileString("Global", "SplashTitle", VM_NAME"!",
			  splashTitle, 1024, squeakIniName);

  /* Look for the mimimum splash time to use */
  splashTime = GetPrivateProfileInt("Global", "SplashTime", 
				    1000, squeakIniName);

  if(!splashFile[0]) return; /* no splash file */

  /* Load the splash screen picture */
  hSplashDIB = LoadImage(NULL, splashFile, IMAGE_BITMAP,0,0,
			 LR_CREATEDIBSECTION | LR_LOADFROMFILE);
  if(!hSplashDIB) {
    /* ignore the common case but print failures for the others */
    if(GetLastError() != ERROR_FILE_NOT_FOUND)
      printLastError("LoadImage failed");
    return;
  }
  GetObject(hSplashDIB, sizeof(bm), &bm);

  /* position the splash screen rectangle */
  SystemParametersInfo( SPI_GETWORKAREA, 0, &wa, 0);
  rSplash.left = (wa.right - bm.bmWidth) / 2;
  rSplash.top = (wa.bottom - bm.bmHeight) / 2;
  rSplash.right = rSplash.left + bm.bmWidth;
  rSplash.bottom = rSplash.top + bm.bmHeight;

  /* create the splash window */
  wc.style = 0;
  wc.lpfnWndProc = (WNDPROC)SplashWndProcA;
  wc.cbClsExtra = 0;
  wc.cbWndExtra = 0;
  wc.hInstance = hInstance;
  wc.hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(2));
  wc.hCursor = NULL;
  wc.hbrBackground = GetStockObject (WHITE_BRUSH);
  wc.lpszMenuName = NULL;
  wc.lpszClassName = TEXT("SqueakSplashWindow");
  RegisterClass(&wc);
  
  hSplashWnd = CreateWindowEx(0,
			      TEXT("SqueakSplashWindow"),
			      splashTitle,
			      WS_POPUP,
			      rSplash.left,rSplash.top,
			      rSplash.right-rSplash.left,
			      rSplash.bottom-rSplash.top,
			      NULL, NULL, hInstance, NULL);

  /* put it up */
  ShowWindow(hSplashWnd, SW_SHOW);
  UpdateWindow(hSplashWnd);
  startTime = GetTickCount();
}

void HideSplashScreen(void) {
  if(hSplashWnd) {
    /* hide splash window after minimal time */
    while(GetTickCount() - startTime < splashTime) {
      Sleep(100);
    }
    ShowWindow(hSplashWnd, SW_HIDE);
    DestroyWindow(hSplashWnd);
    hSplashWnd = NULL;
  }
  /* destroy splash bitmap */
  if(hSplashDIB) {
    DeleteObject(hSplashDIB);
    hSplashDIB = NULL;
  }
}

/****************************************************************************/
/*                      Usage of Squeak                                     */
/****************************************************************************/

#ifdef PharoVM
# define VMOPTION(arg) "--"arg
#else
# define VMOPTION(arg) "-"arg
#endif

/* print usage with different output levels */
int printUsage(int level)
{
  switch(level) {
    case 0: /* No command line given */
      abortMessage(TEXT("Usage: ") TEXT(VM_NAME) TEXT(" [options] <imageFile>"));
      break;
    case 1: /* full usage */
      abortMessage(TEXT("%s"),
                   TEXT("Usage: ") TEXT(VM_NAME) TEXT(" [vmOptions] imageFile [imageOptions]\n\n")
                   TEXT("vmOptions:")
		   /* TEXT("\n\t-service: ServiceName \t(install Squeak as NT service)") */
                   TEXT("\n\t") TEXT(VMOPTION("headless")) TEXT(" \t\t(force Squeak to run headless)")
                   TEXT("\n\t") TEXT(VMOPTION("timephases")) TEXT(" (print start load and run times)")
                   TEXT("\n\t") TEXT(VMOPTION("log:")) TEXT(" LogFile \t\t(use LogFile for VM messages)")
                   TEXT("\n\t") TEXT(VMOPTION("memory:")) TEXT(" megaByte \t(set memory to megaByte MB)")
#if STACKVM || NewspeakVM
                   TEXT("\n\t") TEXT(VMOPTION("breaksel:")) TEXT(" string \t(call warning on send of sel for debug)")
#endif /* STACKVM || NewspeakVM */
#if STACKVM
                   TEXT("\n\t") TEXT(VMOPTION("breakmnu:")) TEXT(" string \t(call warning on MNU of sel for debug)")
                   TEXT("\n\t") TEXT(VMOPTION("leakcheck:")) TEXT(" n \t(leak check on GC (1=full,2=incr,3=both))")
                   TEXT("\n\t") TEXT(VMOPTION("eden:")) TEXT(" bytes \t(set eden memory size to bytes)")
				   TEXT("\n\t") TEXT(VMOPTION("stackpages:")) TEXT(" n \t(use n stack pages)")
                   TEXT("\n\t") TEXT(VMOPTION("numextsems:")) TEXT(" n \t(allow up to n external semaphores)")
                   TEXT("\n\t") TEXT(VMOPTION("checkpluginwrites")) TEXT(" \t(check for writes past end of object in plugins")
                   TEXT("\n\t") TEXT(VMOPTION("noheartbeat")) TEXT(" \t(no heartbeat for debug)")
#endif /* STACKVM */
#if STACKVM || NewspeakVM
# if COGVM
					TEXT("\n\t") TEXT(VMOPTION("trace")) TEXT("[=num]\tenable tracing (optionally to a specific value)\n")
# else
                   TEXT("\n\t") TEXT(VMOPTION("sendtrace")) TEXT(" \t(trace sends to stdout for debug)")
# endif
                   TEXT("\n\t") TEXT(VMOPTION("warnpid")) TEXT("   \t(print pid in warnings)")
#endif
#if COGVM
                   TEXT("\n\t") TEXT(VMOPTION("codesize:")) TEXT(" bytes \t(set machine-code memory size to bytes)")
                   TEXT("\n\t") TEXT(VMOPTION("cogmaxlits:")) TEXT(" n \t(set max number of literals for methods to be compiled to machine code)")
                   TEXT("\n\t") TEXT(VMOPTION("cogminjumps:")) TEXT(" n \t(set min number of backward jumps for interpreted methods to be considered for compilation to machine code)")
                   TEXT("\n\t") TEXT(VMOPTION("tracestores")) TEXT(" \t(assert-check stores for debug)")
                   TEXT("\n\t") TEXT(VMOPTION("reportheadroom")) TEXT("\t(report unused stack headroom on exit)")
                   TEXT("\n\t") TEXT(VMOPTION("dpcso:")) TEXT(" bytes \t(stack offset for prim calls for debug)")
#endif /* COGVM */
#if SPURVM
                   TEXT("\n\t") TEXT(VMOPTION("maxoldspace:")) TEXT(" bytes \t(set max size of old space memory to bytes)")
#endif
                   );
      break;
    case 2: /* No image found */
    default:
      abortMessage(
        TEXT("Could not open the ") TEXT(VM_NAME) TEXT(" image file '%s'\n\n")
        TEXT("There are several ways to open an image file. You can:\n")
        TEXT("  1. Double-click on the desired image file.\n")
        TEXT("  2. Drop the image file onto the application.\n")
        TEXT("Aborting...\n"), toUnicode(imageName));
  }
  return -1;
}

