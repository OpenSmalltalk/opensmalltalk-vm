#define INITGUID

#include <Windows.h>

#ifdef __MINGW32__
# ifndef HMONITOR_DECLARED
#	define HMONITOR_DECLARED
# endif
# undef WINNT
#endif

#include <ddraw.h>
#include <dsound.h>
#include <dsconf.h>
#include <d3d.h>
#include <dinput.h>
#include <unknwn.h>
