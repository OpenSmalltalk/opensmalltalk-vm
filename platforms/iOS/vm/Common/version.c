#if !defined __VERSION__
#	define __VERSION__ "Unknown"
#endif

#if !defined(TZ)
# define TZ ""
# define SPACER ""
#else
# define SPACER " "
#endif

char vmBuildString[] = \
	"Mac OS X built on " \
	__DATE__" "__TIME__ SPACER TZ \
	" Compiler: " __VERSION__;
