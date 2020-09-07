/* Two versioning facilities in one file.  If VERSION_PROGRAM is
 * defined as non-zero then this will run the main in
 * platforms/Cross/vm/sqSCCSVersion.h which will print various version
 * info.  Otherewise this defines vmBuildString with the current
 * compiler.
 */
#if VERSION_PROGRAM
# include "sqSCCSVersion.h"
#else
# if !defined __VERSION__
#	define __VERSION__ "Unknown"
# endif

# if !defined(TZ)
#	define TZ ""
#	define SPACER ""
# else
#	define SPACER " "
# endif

char vmBuildString[] = \
	"Mac OS X built on " \
	__DATE__" "__TIME__ SPACER TZ \
	" Compiler: " __VERSION__;
#endif /* VERSION_PROGRAM */
