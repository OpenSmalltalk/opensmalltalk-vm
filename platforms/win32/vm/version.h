#ifdef _MSC_VER
#if _MSC_VER >= 1600
define the type string here
#elif _MSC_VER >= 1500
#define VM_BUILD_STRING "Win32 built on " __DATE__ " "__TIME__ " Compiler: Microsoft Visual Studio 2008"
#elif _MSC_VER >= 1400
#define VM_BUILD_STRING "Win32 built on " __DATE__ " "__TIME__ " Compiler: Microsoft Visual Studio 2005"
#elif _MSC_VER >= 1300
#define VM_BUILD_STRING "Win32 built on " __DATE__ " "__TIME__ " Compiler: Microsoft Visual Studio 2003"
#elif _MSC_VER >= 1200
#define VM_BUILD_STRING "Win32 built on " __DATE__ " "__TIME__ " Compiler: Microsoft Visual Studio 6"
#else
define the type string here
#endif	//MSVC versions
#else
#define VM_BUILD_STRING "Win32 built on " __DATE__ " "__TIME__ " Compiler: "__VERSION__
#endif
