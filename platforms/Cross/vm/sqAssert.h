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
extern void warning(char *);
extern void warningat(char *,int);
void error(char *s);
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
# ifdef SQUEAK_EXTERNAL_PLUGIN
static void (*warnfp)(char *) = 0;
static void (*warnatfp)(char *,int) = 0;
# endif
static inline int warningIf(int condition, char *message)
{
    if (!condition)
        return 1;
#	ifdef SQUEAK_EXTERNAL_PLUGIN
	if (!warnfp)
		warnfp = (void (*)(char *))GetProcAddress(GetModuleHandle(0),"warning");
	warnfp(message);
#	else
	warning(message);
#	endif
	return 0;
}

static inline int warningIfAt(int condition, char *message, int line)
{
    if (!condition)
        return 1;
#	ifdef SQUEAK_EXTERNAL_PLUGIN
	if (!warnatfp)
		warnatfp = (void (*)(char *,int))GetProcAddress(GetModuleHandle(0),"warningat");
	warnatfp(message, line);
#	else
	warningat(message, line);
#	endif
	return 0;
}

# define assert(expr)  warningIf(!(expr), #expr " " __stringifyNum(__LINE__))
# define asserta(expr) warningIf(!(expr), #expr " " __stringifyNum(__LINE__))
# define assertf(msg)  (warning(#msg " " __stringifyNum(__LINE__)),0)
# define assertl(expr,line)  warningIfAt(!(expr), #expr, line)
# define assertal(expr,line) warningIfAt(!(expr), #expr, line)
# define assertfl(msg,line)  (warningat(#msg,line),0)
extern char expensiveAsserts;
# define eassert(expr)  warningIf(!expensiveAsserts && !(expr), #expr " " __stringifyNum(__LINE__))
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
