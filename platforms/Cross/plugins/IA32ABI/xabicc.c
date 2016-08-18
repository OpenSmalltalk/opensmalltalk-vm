/*
 *  xabicc.c - platform-agnostic root for Alien call-outs and callbacks.
 *
 * Support for Call-outs and Call-backs from the IA32ABI Plugin.
 * The plugin is misnamed.  It should be the AlienPlugin, but its history
 * dictates otherwise.
 */
#if i386|i486|i586|i686
# include "ia32abicc.c"
#elif powerpc|ppc
# include "ppcia32abicc.c"
#elif x86_64|x64|__x86_64|__x86_64__|_M_AMD64|_M_X64
# if WIN64
#	include "x64win64ia32abicc.c"
# else
#	include "x64ia32abicc.c"
# endif
#elif __ARM_ARCH__|__arm__|__arm32__|ARM32
# include "arm32ia32abicc.c"
#endif
	