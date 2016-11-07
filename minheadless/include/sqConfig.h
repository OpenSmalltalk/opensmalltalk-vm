#ifndef SQ_COMFIG_H_
#define SQ_COMFIG_H_

#define VMBIGENDIAN 0

#if defined(__GNUC__)
/* Define the "don't generate functions with register parameters" attribute
 * for x86 and similar.  Do so for debugging; gdb typically can't call static
 * functions that have been optimized to use register arguments.
 */
# if defined(_M_I386) || defined(_X86_) || defined(i386) || defined(i486) || defined(i586) || defined(i686) || defined(__i386__) || defined(__386__) || defined(X86) || defined(I386)
#	define PlatformNoDbgRegParms __attribute__ ((regparm (0)))
# endif
# define NeverInline __attribute__ ((noinline))
#endif

#if defined( __clang__)
# define NeverInline __attribute__ ((noinline))
#endif

#endif /* SQ_COMFIG_H_ */
