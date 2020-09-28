/*
 * Informative assert definitions that print expression and line number.
 *
 * assert's expression is evaluated only if NDEBUG is not defined and printed
 * along with its the line number if it is false.
 *
 * asserta's expression is always evaluated but only printed if it is false and
 * NDEBUG is not defined. (asserta => assert always)
 *
 * assertf's message is printed along with its line number if NDEBUG is not
 * defined. (assertf => assert fail)
 *
 * assertl, assertal & assertfl take a line number as an argument.
 */

#include "sqPlatformSpecific.h" // for EXPORT()

#pragma auto_inline(off)
#if defined(IMPORT) && defined(SQUEAK_EXTERNAL_PLUGIN)
IMPORT(void) error(const char *);
IMPORT(void) warning(const char *);
IMPORT(void) warningat(const char *,int);
#elif defined(EXPORT) && !defined(SQUEAK_BUILTIN_PLUGIN)
EXPORT(void) error(const char *);
EXPORT(void) warning(const char *);
EXPORT(void) warningat(const char *,int);
#else
void error(const char *);
void warning(const char *);
void warningat(const char *,int);
#endif
#pragma auto_inline(on)

#undef assert
# define __stringify(foo) #foo
# define __stringifyNum(n) __stringify(n)
#ifdef NDEBUG /* compatible with Mac OS X (FreeBSD) /usr/include/assert.h */
# define assert(expr) 0 /* hack disabling of asserts.  Better in makefile? */
# define asserta(expr) (expr)
# define assertf(msg) 0
# define assertl(expr,line) 0
# define assertal(expr,line) (expr)
# define assertfl(msg,line) 0
# define eassert(expr) 0 /* hack disabling of asserts.  Better in makefile? */
# define PRODUCTION 1
#elif defined(_MSC_VER) && !defined(__clang__)
// MSVC generates incorrect code for assertions using the macro forms. To help
// it hang with the grown-up compilers we use these inline functions. But WIN64
// doesn't make it easy to choose a natural machine word type; sigh...
# if _WIN64
#	define  __word __int64
# else
#	define  __word __int32
# endif
static inline __word
warningIfNot(__word condition, const char *msg)
{
    if (!condition)
		warning(msg);
	return condition;
}

static inline __word
warningIfNotAt(__word condition, const char *msg, int line)
{
    if (!condition)
		warningat(msg, line);
	return condition;
}
# undef __word

# define assert(expr)  warningIfNot(expr, #expr " " __stringifyNum(__LINE__))
# define asserta(expr) warningIfNot(expr, #expr " " __stringifyNum(__LINE__))
# define assertf(msg)  (warning(#msg " " __stringifyNum(__LINE__)),0)
# define assertl(expr,line)  warningIfNotAt(expr, #expr, line)
# define assertal(expr,line) warningIfNotAt(expr, #expr, line)
# define assertfl(msg,line)  (warningat(#msg,line),0)
extern char expensiveAsserts;
# define eassert(expr)  warningIfNot(!expensiveAsserts || !(expr), #expr " " __stringifyNum(__LINE__))
# define PRODUCTION 0
#else
# define assert(expr)  ((expr)||(warning(#expr " " __stringifyNum(__LINE__)),0))
# define asserta(expr) ((expr)||(warning(#expr " " __stringifyNum(__LINE__)),0))
# define assertf(msg)  (warning(#msg " " __stringifyNum(__LINE__)),0)
# define assertl(expr,line)  ((expr)||(warningat(#expr,line),0))
# define assertal(expr,line) ((expr)||(warningat(#expr,line),0))
# define assertfl(msg,line)  (warningat(#msg,line),0)
extern char expensiveAsserts;
# define eassert(expr)  (!expensiveAsserts||(expr) \
						 ||(warning(#expr " " __stringifyNum(__LINE__)),0))
# define PRODUCTION 0
#endif
