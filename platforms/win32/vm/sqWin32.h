/* Generic OS identifying and sub-system selecting include for _WIN32, _WIN64
 * and _WINCE
 */
#ifndef SQ_WIN_32_H
#define SQ_WIN_32_H


/*************************************************************/
/* NOTE: For a list of possible definitions see file README. */
/*************************************************************/

#ifdef _MSC_VER
/* disable "function XXXX: no return value" */
#pragma warning(disable:4035)
/* optional C SEH macros */
# define TRY __try
# define EXCEPT(filter) __except(filter)
# define FINALLY __finally
#else
/* optional C SEH macros */
# define TRY
# define EXCEPT(filter) if (0)
# define FINALLY
#endif

#define NO_TABLET

/* #define USE_DIRECT_X */
#define NO_DIRECTINPUT

/* Definition for Intel Processors */
#if defined(_M_IX86) || defined(i386)
# define WIN32_NAME "Win32"
# define WIN32_OS_NAME "NT"
# define WIN32_PROCESSOR_NAME "IX86"

# if defined(X86)
#  undef X86
#  define X86 i386
# endif

  /* Use console for warnings */
# define warnPrintf printf
# define warnPrintfW wprintf
#endif /* _M_IX86 */

/* We are stuck with Win32 as a misnomer for the Windows operating system for
 * historical reasons.  Images up to and including Squeak 5/Pharo 6 expect
 * getSystemAttribute: 1001 ("platform name") to answer 'Win32' on Windows.
 * Yes, this is regrettable.  No, it's not easy to fix without breaking existing
 * images :-(.  The NT vs CE distinction isn't particularly meaningful either.
 * Further (see sqWin32Window.c) parameter 1005 (the windoing system name) also
 * answers Win32.  Perhaps this could be changed to "Windows", because at least
 * in a base Squeak 5.1 image as of mid 2017 there is no use of windowSystemName
 * that depends on its result being 'Win32' (see e.g. HandMorph class>>
 * #compositionWindowManager).
 * eem 2017/05/16
 */
#if defined(__amd64__) || defined(__amd64) || defined(x86_64) || defined(__x86_64__) || defined(__x86_64) || defined(x64) || defined(_M_X64)
#	define WIN32_NAME "Win32"
#	define WIN32_OS_NAME "NT"
#	define WIN32_PROCESSOR_NAME "X64"

  /* Use console for warnings */
#	define warnPrintf printf
#	define warnPrintfW wprintf
#endif /* _M_X64 & al */

/* Experimental */
#ifdef MINIMAL
  /* The hardcoded defs:
   * No virtual memory support; no service support; no preferences; no printing
   */
#	define NO_VIRTUAL_MEMORY
#	define NO_SERVICE
#	define NO_PREFERENCES
#	define NO_PRINTER
  /* Use stub definitions from sqWin32Stubs.c */
#	define NO_SOUND
#	define NO_SERIAL_PORT
#	define NO_NETWORK
#	define NO_JOYSTICK
#	define NO_MIDI
#	define NO_ASYNC_FILES
  /* Do not rely on stdio functions but rather pure Win32 stuff */
#	define WIN32_FILE_SUPPORT
  /* Take out the static strings */
#	define NO_WARNINGS
#endif /* MINIMAL */

/********************************************************/
/* Message hooks for processing out of sqWin32Window.c  */
/********************************************************/
typedef int (*messageHook)(void *, unsigned int, unsigned int, long);

/********************************************************/
/* Several setup functions                              */
/********************************************************/
void SetupFilesAndPath(void);
void SetupWindows(void);
void SetupPixmaps(void);
void SetupPrinter(void);
void SetupMIDI(void);

/********************************************************/
/* Startup helper functions                             */
/********************************************************/
int findImageFile(void);
int openImageFile(void);

/********************************************************/
/* external SYNCHRONIZED signaling of semaphores        */
/********************************************************/
int synchronizedSignalSemaphoreWithIndex(int semaIndex);

/********************************************************/
/* Image options / VM options                           */
/********************************************************/
char *GetImageOption(int id);
char *GetVMOption(int id);

/********************************************************/
/* Misc functions                                       */
/********************************************************/
void SetWindowSize(void);
int printUsage(int level);

/********************************************************/
/* Service Stuff                                        */
/********************************************************/
#ifndef NO_SERVICE
/* The external startup point for installing squeak as NT service */
void sqServiceInstall(void);
/* The main() function used by NT services */
int sqServiceMain(void);
/* The generic main() function for starting squeak */
int sqMain(int argc, char *argv[]);
#endif

/********************************************************/
/********************************************************/
/* Stuff requiring to include windows.h                 */
/********************************************************/
/********************************************************/

#if defined(_WINDOWS_) || defined(__WINDOWS__) || defined(_WINDOWS_H)

#ifdef _MSC_VER
#define COMPILER "Microsoft Visual C++ "
#define VERSION ""
#endif
#ifdef __GNUC__
#define COMPILER "gcc "
#define VERSION __VERSION__
#endif
#ifndef COMPILER
#define COMPILER "(unknown) "
#endif
#ifndef VERSION
#define VERSION ""
#endif

/********************************************************/
/* image reversal functions                             */
/********************************************************/
int reverse_image_bytes(unsigned int* dst, unsigned int *src,int depth, int width, RECT *rect);
int reverse_image_words(unsigned int *dst, unsigned int *src,int depth, int width, RECT *rect);

/********************************************************/
/* Declarations we may need by other modules            */
/********************************************************/

/* Note: a character can require up to 4 bytes in UTF8 encoding
   But the expansion from UTF16 -> UTF8 is never more than 3 bytes for 1 short
   U+ 0000-U+  007F - 1byte in utf8, 1 short in utf16.
   U+ 0080-U+  07FF - 2byte in utf8, 1 short in utf16.
   U+ 0800-U+  FFFF - 3byte in utf8, 1 short in utf16.
   U+10000-U+10FFFF - 4byte in utf8, 2 short in utf16.
*/
#define MAX_PATH_UTF8 (MAX_PATH*3)

extern char  imageName [];       /* full path and name to image - UTF8 */
extern WCHAR imageNameW[];       /* full path and name to image - UTF16 */
extern char  imagePathA[];       /* full path to image - UTF8 */
extern WCHAR imagePathW[];       /* full path to image - UTF16 */
extern char  vmPathA[];          /* full path to interpreter's directory - UTF8 */
extern WCHAR vmPathW[];          /* full path to interpreter's directory - UTF16 */
extern char  vmNameA[];          /* name of the interpreter's executable - UTF8 */
extern WCHAR vmNameW[];          /* name of the interpreter's executable - UTF16 */
extern char windowTitle[];       /* window title string - UTF8 */
extern char vmBuildString[];     /* the vm build string */
extern TCHAR windowClassName[];  /* class name for the window */
extern char  squeakIniNameA[];   /* full path to ini file - UTF8 */
extern WCHAR squeakIniNameW[];   /* full path to ini file - UTF16 */

#ifdef UNICODE
# define imageNameT imageNameW /* define the generic TCHAR* version */
# define imagePath  imagePathW
# define vmName vmNameW
# define vmPath vmPathW
# define squeakIniName squeakIniNameW
#else
# define imageNameT imageName
# define imagePath  imagePathA
# define vmName vmNameA
# define vmPath vmPathA
# define squeakIniName squeakIniNameA
#endif

#define __UNICODE_TEXT(x) L##x
#define _UNICODE_TEXT(x) __UNICODE_TEXT(x)

extern UINT SQ_LAUNCH_DROP;

extern const TCHAR U_ON[];
extern const TCHAR U_OFF[];
extern const TCHAR U_GLOBAL[];
extern const WCHAR W_BACKSLASH[];

#ifndef NO_PREFERENCES
extern HMENU vmPrefsMenu;         /* preferences menu */
#endif

extern HWND  consoleWindow;       /* console */


extern HWND stWindow;	     	         /*	the squeak window */
extern HWND browserWindow;	     	     /*	the browser window */
extern HINSTANCE hInstance;	     /*	the instance of squeak running */
extern HCURSOR currentCursor;	     /*	current cursor displayed by squeak */
extern HPALETTE palette;	     /*	the palette (might be unused) */
extern LOGPALETTE *logPal;	     /*	the logical palette definition */
extern BITMAPINFO *bmi1;	     /*	1 bit depth bitmap info */
extern BITMAPINFO *bmi4;	     /*	4 bit depth bitmap info */
extern BITMAPINFO *bmi8;	     /*	8 bit depth bitmap info */
extern BITMAPINFO *bmi16;	     /*	16 bit depth bitmap info */
extern BITMAPINFO *bmi32;	     /*	32 bit depth bitmap info */
extern BOOL fIsConsole;          /* Are we running as a console app? */

/* Startup options */
extern BOOL  fHeadlessImage; /* Do we run headless? */
extern BOOL  fRunService;    /* Do we run as NT service? */
extern BOOL  fBrowserMode;   /* Do we run in a web browser? */
extern DWORD dwMemorySize;   /* How much memory do we use? */
extern BOOL  fUseDirectSound;/* Do we use DirectSound?! */
extern BOOL  fUseOpenGL;     /* Do we use OpenGL?! */
extern BOOL fReduceCPUUsage; /* Should we reduce CPU usage? */
extern BOOL fReduceCPUInBackground; /* reduce CPU usage when not active? */
extern BOOL  f1ButtonMouse;  /* Should we use a 1 button mouse mapping? */
extern BOOL  f3ButtonMouse;  /* Should we use a 3 button mouse mapping? */
extern BOOL  fShowAllocations; /* Show memory allocations */
extern BOOL  fPriorityBoost; /* thread priority boost */
extern BOOL  fEnableAltF4Quit; /* can we quit using Alt-F4? */
extern BOOL  fEnableF2Menu;    /* can we get prefs menu via F2? */
extern BOOL  fEnablePrefsMenu;    /* can we get prefs menu at all? */
extern BOOL  fRunSingleApp;   /* do we only allow one instance? */

extern HANDLE vmWakeUpEvent;      /* wakeup event for interpret() */

/* variables for cached display */
extern RECT updateRect;		     /*	the rectangle to update */
extern HRGN updateRgn;	     	     /*	the region to update (more accurate) */
extern BOOL updateRightNow;	     /*	update flag */

/********************************************************/
/* Preference values                                    */
/********************************************************/
extern BOOL fDeferredUpdate; /* I prefer the deferred update*/
extern BOOL fShowConsole;    /* do we show the console window?*/
extern BOOL fDynamicConsole; /* Should we show the console if any errors occur? */
extern BOOL fReduceCPUUsage; /* Should we reduce CPU usage? */
extern BOOL f3ButtonMouse;   /* Should we use a real 3 button mouse mapping? */
extern BOOL fBufferMouse;    /* Should we buffer mouse input? */


/******************************************************/
/* Output stuff                                       */
/******************************************************/
#ifndef sqMessageBox
int __cdecl sqMessageBox(DWORD dwFlags, const TCHAR *titleString, const TCHAR* fmt, ...);
#endif

#ifndef warnPrintf
int __cdecl warnPrintf(char *fmt, ...);
#endif

#ifndef warnPrintfW
int __cdecl warnPrintfW(WCHAR *fmt, ...);
#endif

#ifdef UNICODE
#define warnPrintfT warnPrintfW
#else
#define warnPrintfT warnPrintf
#endif

#ifndef abortMessage
int __cdecl abortMessage(TCHAR *fmt, ...);
#endif

/* neat little helpers - print prefix and the GetLastError() meaning */
#ifndef printLastError
void printLastError(TCHAR *prefix);
#endif

#ifndef vprintLastError
void vprintLastError(TCHAR *fmt, ...);
#endif

/******************************************************/
/* Misc functions                                     */
/******************************************************/
DWORD SqueakImageLength(WCHAR *fileName);
int isLocalFileName(TCHAR *fileName);

#ifndef NO_PLUGIN_SUPPORT
void pluginInit(void);
void pluginExit(void);
void pluginHandleEvent(MSG* msg);
#endif /* NO_PLUGIN_SUPPORT */

#ifndef NO_DROP
int recordDragDropEvent(HWND wnd, int dragType, int x, int y, int numFiles);
#endif

/******************************************************/
/* Profiling support                                  */
/******************************************************/
#if 0
#define PROFILE           /* if you want some information about times */
#define PROFILE_DISPLAY 1 /* measure times in ioShowDisplay() */
#endif

#if defined(PROFILE) && 0
#define PROFILE_BEGIN(condition) if(condition) { DWORD __profileTicks = GetTickCount();
#define PROFILE_END(variable) variable += GetTickCount() - __profileTicks; }
#define PROFILE_SHOW(variable) if(variable) {char s[20]; MessageBox(0,itoa(variable, s, 10), "Milliseconds for " #variable, MB_OK); }
#else
#define PROFILE_BEGIN(condition)
#define PROFILE_END(variable)
#define PROFILE_SHOW(variable)
#endif

#if defined(PROFILE) && 0
extern DWORD ticksForReversal; /* time needed for byte/word reversal */
extern DWORD ticksForBlitting; /* time needed for actual blts */
#endif

#endif /* _WINDOWS_ */

#ifndef STACK_SIZE_PARAM_IS_A_RESERVATION
#  define STACK_SIZE_PARAM_IS_A_RESERVATION 0x00010000
#endif

#endif /* SQ_WIN_32_H */
