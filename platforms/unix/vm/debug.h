#ifndef __sq_debug_h
#define __sq_debug_h


#ifndef  DEBUG
# define DEBUG	0
#endif


#if (DEBUG)
  /* the thing to use here is a variadic macro, but Apple's gcc barfs on
  ** them when running in precomp mode.  did they _really_ have to break
  ** the preprocessor just to implement precomp?  good _grief_.
  */
  extern void __sq_DPRINTF(const char *fmt, ...);
# define DPRINTF(ARGS) __sq_DPRINTF ARGS
#else
# define DPRINTF(ARGS)	((void)0)
#endif


#undef assert

#if (DEBUG)
  extern void __sq_assert(char *file, int line, char *func, char *expr);
# define assert(E) \
    ((void)((E) ? 0 : __sq_assert(__FILE__, __LINE__, __FUNCTION__, #E)))
#else
# define assert(E)	((void)0)
#endif


extern char *__sq_errfile;
extern int   __sq_errline;
extern char *__sq_errfunc;

extern void __sq_eprintf(const char *fmt, ...);

# define EPRINTF				\
  ( __sq_errfile= __FILE__,			\
    __sq_errline= __LINE__,			\
    __sq_errfunc= __FUNCTION__,			\
    __sq_eprintf )

extern void sqDebugAnchor(void);

#endif /* __sq_debug_h */
