#define INITGUID

#include <windows.h>

#ifdef __MINGW32__
#define HMONITOR_DECLARED
#undef WINNT
#endif

#include <ddraw.h>
#include <dsound.h>
#include <dsconf.h>
#include <d3d.h>
#include <dinput.h>
#include <unknwn.h>


