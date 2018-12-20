#if !defined(TZ)
# define TZ ""
# define SPACER ""
#else
# define SPACER " "
#endif

#ifdef _MSC_VER
# if _MSC_VER >= 2000
	define the version string here
# elif _MSC_VER >= 1900
#	define __VERSION__ "Microsoft Visual Studio 2015"
# elif _MSC_VER >= 1800
#	define __VERSION__ "Microsoft Visual Studio 2013"
# elif _MSC_VER >= 1700
#	define __VERSION__ "Microsoft Visual Studio 2012"
# elif _MSC_VER >= 1600
#	define __VERSION__ "Microsoft Visual Studio 2010"
# elif _MSC_VER >= 1500
#	define __VERSION__ "Microsoft Visual Studio 2008"
# elif _MSC_VER >= 1400
#	define __VERSION__ "Microsoft Visual Studio 2005"
# elif _MSC_VER >= 1300
#	define __VERSION__ "Microsoft Visual Studio 2003"
# elif _MSC_VER >= 1200
#	define __VERSION__ "Microsoft Visual Studio 6"
# elif _MSC_VER >= 1100
#	define __VERSION__ "Microsoft Visual Studio 5"
# else
	define the version string here
# endif	//MSVC versions
#endif	//MSVC versions

char vmBuildString[] = \
	"Win32 built on " \
	__DATE__" "__TIME__ SPACER TZ \
	" Compiler: " __VERSION__;
