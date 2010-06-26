/*
 * An informative assert definition that prints expression and line number.
 *
 * assert's expression is evaluated only if NDEBUG is not defined and printed
 * along with its the line number if it is false.
 *
 * asserta's expression is always evaluated but only printed if it is false and
 * NDEBUG is not defined. (asserta => assert always)
 *
 * assertf's message is printed along with its line number if NDEBUG is not
 * defined. (assertfd => assert fail)
 */

extern void warning(char *);

#ifdef NDEBUG /* compatible with Mac OS X (FreeBSD) /usr/include/assert.h */
# undef assert
# define assert(expr) 0 /* hack disabling of asserts.  Better in makefile? */
# define asserta(expr) (expr)
# define assertf(msg) 0
# define PRODUCTION 1
#elif 1
# undef assert
# define __stringify(foo) #foo
# define __stringifyNum(n) __stringify(n)
# define assert(expr)  ((expr)||(warning(#expr " " __stringifyNum(__LINE__)),0))
# define asserta(expr) ((expr)||(warning(#expr " " __stringifyNum(__LINE__)),0))
# define assertf(msg)  (warning(#msg " " __stringifyNum(__LINE__)),0)
# define PRODUCTION 0
#endif

#define halt() warning("halt")
