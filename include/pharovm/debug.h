#pragma once

#ifndef EXPORT
#define EXPORT(x)  x
#endif

#ifndef  DEBUG
# define DEBUG	0
#endif

#define LOG_NONE 		0
#define LOG_ERROR 		1
#define LOG_WARN 		2
#define LOG_INFO 		3
#define LOG_DEBUG		4
#define LOG_TRACE		5

EXPORT(void) logLevel(int level);
EXPORT(void) logMessage(int level, const char* fileName, const char* functionName, int line, ...);
EXPORT(void) logAssert(const char* fileName, const char* functionName, int line, char* msg);

EXPORT(void) installErrorHandlers();

//This variable is set externally by CMAKE
#ifndef SOURCE_PATH_SIZE
# define SOURCE_PATH_SIZE 0
#endif

//FILENAME gives only the filename, as __FILE__ gives all the path
#define __FILENAME__ ((char*)__FILE__ + SOURCE_PATH_SIZE)

#define logTrace(...)	logMessage(LOG_TRACE, __FILENAME__, __FUNCTION__, __LINE__, __VA_ARGS__)
#define logDebug(...)	logMessage(LOG_DEBUG, __FILENAME__, __FUNCTION__, __LINE__, __VA_ARGS__)
#define logInfo(...)	logMessage(LOG_INFO, __FILENAME__, __FUNCTION__, __LINE__, __VA_ARGS__)
#define logWarn(...)	logMessage(LOG_WARN, __FILENAME__, __FUNCTION__, __LINE__, __VA_ARGS__)
#define logError(...)	logMessage(LOG_ERROR, __FILENAME__, __FUNCTION__, __LINE__, __VA_ARGS__)

#define LOG_SIZEOF(expr) logDebug("sizeof("#expr"): %ld", sizeof(expr))

#define logErrorFromErrno(msg) 	logMessageFromErrno(LOG_ERROR, msg, __FILENAME__, __FUNCTION__, __LINE__);
#define logWarnFromErrno(msg) 	logMessageFromErrno(LOG_WARN, msg, __FILENAME__, __FUNCTION__, __LINE__);
#define logDebugFromErrno(msg) 	logMessageFromErrno(LOG_DEBUG, msg, __FILENAME__, __FUNCTION__, __LINE__);

EXPORT(void) logMessageFromErrno(int level, const char* msg, const char* fileName, const char* functionName, int line);

#include <stdio.h>

int vm_printf( const char * format, ... );
void vm_setVMOutputStream(FILE * stream);
