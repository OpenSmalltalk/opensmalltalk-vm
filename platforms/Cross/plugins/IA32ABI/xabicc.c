/*
 *  xabicc.c - platform-agnostic root for Alien call-outs and callbacks.
 *
 * Support for Call-outs and Call-backs from the IA32ABI Plugin.
 * The plugin is misnamed.  It should be the AlienPlugin, but its history
 * dictates otherwise.
 */
#if defined(_M_I386) || defined(_M_IX86) || defined(_X86_) || defined(i386) || defined(i486) || defined(i586) || defined(i686) || defined(__i386__) || defined(__386__) || defined(X86) || defined(I386)
# include "ia32abicc.c"
#elif powerpc|ppc
# include "ppc32abicc.c"
#elif defined(x86_64) || defined(__amd64) || defined(__x86_64) || defined(__amd64__) || defined(__x86_64__) || defined(_M_AMD64) || defined(_M_X64)
# if _WIN64
#	include "x64win64abicc.c"
# else
#	include "x64sysvabicc.c"
# endif
#elif defined(__ARM_ARCH_ISA_A64) || defined(__aarch64__) || defined(__arm64__) || defined(ARM64)
# include "arm64abicc.c"
#elif defined(__ARM_ARCH__) || defined(__arm__) || defined(__arm32__) || defined(ARM32) || defined(_M_ARM)
# include "arm32abicc.c"
#else
#error "Unsupported architecture"
#endif
