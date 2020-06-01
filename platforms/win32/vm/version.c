#if !defined(TZ)
# define TZ ""
# define SPACER ""
#else
# define SPACER " "
#endif

#if defined(_MSC_VER) && !defined(__VERSION__)
# if _MSC_VER >= 2000
	define the version string here
# elif _MSC_VER >= 1920
#	define __VERSION__ "Microsoft Visual Studio 2019 version 16.x"
# elif _MSC_VER >= 1910
#	define __VERSION__ "Microsoft Visual Studio 2017 version 15.x"
# elif _MSC_VER >= 1900
#	define __VERSION__ "Microsoft Visual Studio 2015 version 14"
# elif _MSC_VER >= 1800 // That Mcrosoft appears to be superstitious inspires such confidence...
#	define __VERSION__ "Microsoft Visual Studio 2013 version 12.x"
# elif _MSC_VER >= 1700
#	define __VERSION__ "Microsoft Visual Studio 2012 version 11.x"
# elif _MSC_VER >= 1600
#	define __VERSION__ "Microsoft Visual Studio 2010 version 10.x"
# elif _MSC_VER >= 1500
#	define __VERSION__ "Microsoft Visual Studio 2008 version 9.x"
# elif _MSC_VER >= 1400
#	define __VERSION__ "Microsoft Visual Studio 2005 version 8.x"
# elif _MSC_VER >= 1300
#	define __VERSION__ "Microsoft Visual Studio 2003 version 7.x"
# elif _MSC_VER >= 1200
#	define __VERSION__ "Microsoft Visual Studio 6"
# elif _MSC_VER >= 1100
#	define __VERSION__ "Microsoft Visual Studio 5"
# else
	define the version string here
# endif	//_MSC_VER
#endif	//MSVC versions && !defined(__VERSION__)

char vmBuildString[] = \
	"Win32 built on " \
	__DATE__" "__TIME__ SPACER TZ \
	" Compiler: " __VERSION__ ;
