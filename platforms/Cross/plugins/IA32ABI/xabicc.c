/*
 *  xabicc.c - platform-agnostic root for ALien call-outs and callbacks.
 *
 * Support for Call-outs and Call-backs from the IA32ABI Plugin.
 * The plugin is misnamed.  It should be the AlienPlugin, but its history
 * dictates otherwise.
 */
#if i386|i486|i586|i686
# include "ia32abicc.c"
#elif powerpc|ppc
# include "ppcia32abicc.c"
#elif x86_64|x64|__x86_64|__x86_64__
# include "x64ia32abicc.c"
#elif defined(__ARM_ARCH__) || defined(__arm__) || defined(__arm32__) || defined(ARM32)
# include "arm32ia32abicc.c"
#endif
