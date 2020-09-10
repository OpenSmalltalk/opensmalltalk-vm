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

#pragma auto_inline(off)
#if defined(EXPORT) && !defined(SQUEAK_BUILTIN_PLUGIN)
EXPORT(void) error(const char *);
EXPORT(void) warning(const char *);
EXPORT(void) warningat(const char *,int);
#else
extern void error(const char *);
extern void warning(const char *);
extern void warningat(const char *,int);
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
#elif defined(_MSC_VER)
static inline sqInt warningIfNot(sqInt condition, const char *msg)
{
    if (!condition)
		warning(msg);
	return condition;
}

static inline sqInt warningIfNotAt(sqInt condition, const char *msg, int line)
{
    if (!condition)
		warningat(msg, line);
	return condition;
}

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
