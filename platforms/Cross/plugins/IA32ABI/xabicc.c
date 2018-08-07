/*
 *  xabicc.c - platform-agnostic root for Alien call-outs and callbacks.
 *
 * Support for Call-outs and Call-backs from the IA32ABI Plugin.
 * The plugin is misnamed.  It should be the AlienPlugin, but its history
 * dictates otherwise.
 */
#if i386|i486|i586|i686|_M_IX86
# include "ia32abicc.c"
#elif powerpc|ppc
# include "ppc32abicc.c"
#elif x86_64|x64|__x86_64|__x86_64__|_M_AMD64|_M_X64
# if _WIN64
#	include "x64win64abicc.c"
# else
#	include "x64sysvabicc.c"
# endif
#elif __ARM_ARCH__|__arm__|__arm32__|ARM32
# include "arm32abicc.c"
#endif
	
