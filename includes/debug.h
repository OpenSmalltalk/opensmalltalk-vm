#ifndef __sq_debug_h
#define __sq_debug_h


#ifndef  DEBUG
# define DEBUG	0
#endif

#define LOG_NONE 		0
#define LOG_ERROR 		1
#define LOG_WARN 		2
#define LOG_INFO 		3
#define LOG_DEBUG		4

//This variable is set externally by CMAKE
#ifndef SOURCE_PATH_SIZE
# define SOURCE_PATH_SIZE 0
#endif

//FILENAME gives only the filename, as __FILE__ gives all the path
#define __FILENAME__ (__FILE__ + SOURCE_PATH_SIZE)

void logLevel(int level);

EXPORT(void) logMessage(int level, const char* fileName, const char* functionName, int line, ...);

#define logDebug(...)	logMessage(LOG_DEBUG, __FILENAME__, __FUNCTION__, __LINE__, __VA_ARGS__)
#define logInfo(...)	logMessage(LOG_INFO, __FILENAME__, __FUNCTION__, __LINE__, __VA_ARGS__)
#define logWarn(...)	logMessage(LOG_WARN, __FILENAME__, __FUNCTION__, __LINE__, __VA_ARGS__)
#define logError(...)	logMessage(LOG_ERROR, __FILENAME__, __FUNCTION__, __LINE__, __VA_ARGS__)


#if (DEBUG)
# define assert(E) \
    ((void)((E) ? 0 : logMessage(LOG_WARN, __FILENAME__, __FUNCTION__, __LINE__, #E)))
#else
# define assert(E)	((void)0)
#endif


//# define EPRINTF				\
//  ( __sq_errfile= __FILE__,			\
//    __sq_errline= __LINE__,			\
//    __sq_errfunc= __FUNCTION__,			\
//    __sq_eprintf )
//
//extern void sqDebugAnchor(void);

#endif /* __sq_debug_h */
