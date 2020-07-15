#include "pharovm/pharo.h"
#include <stdarg.h>
#include <sys/time.h>

char * GetAttributeString(sqInt id);

#if defined(DEBUG) && DEBUG
static int max_error_level = 4;
#else
static int max_error_level = 1;
#endif
/*
 * This function set the logLevel to use in the VM
 *
 * LOG_NONE 		0
 * LOG_ERROR 		1
 * LOG_WARN 		2
 * LOG_INFO 		3
 * LOG_DEBUG		4
 * LOG_TRACE		5
 *
 */
EXPORT(void) logLevel(int value){
	max_error_level = value;
}

void error(char *errorMessage){
    logError(errorMessage);
    abort();
}

static char* severityName[5] = {"ERROR", "WARN", "INFO", "DEBUG", "TRACE"};

EXPORT(void) logAssert(const char* fileName, const char* functionName, int line, char* msg){
	logMessage(LOG_WARN, fileName, functionName, line, msg);
}

void logMessageFromErrno(int level, const char* msg, const char* fileName, const char* functionName, int line){
	char buffer[1024+1];
	int msgLength;

#ifdef WIN32
	strerror_s(buffer, 1024, errno);
#else
	strerror_r(errno, buffer, 1024);
#endif

	logMessage(level, fileName, functionName, line, "%s: %s", msg, buffer);
}

FILE* getStreamForLevel(int level){
	if(level <= LOG_ERROR){
		return stderr;
	}else{
		return stdout;
	}
}


EXPORT(void) logMessage(int level, const char* fileName, const char* functionName, int line, ...){
	char * format;
	char timestamp[20];

	FILE* outputStream;

	outputStream = getStreamForLevel(level);


	if(level > max_error_level){
		return;
	}

	time_t now = time(NULL);
	struct tm* ltime = localtime(&now);

	strftime(timestamp, 20, "%Y-%m-%d %H:%M:%S", ltime);

	//Printing the header.
	// Ex: [DEBUG] 2017-11-14 21:57:53,661 functionName (filename:line) - This is a debug log message.

	struct timeval utcNow;
	gettimeofday(&utcNow,0);

	fprintf(outputStream, "[%-5s] %s.%03d %s (%s:%d):", severityName[level - 1], timestamp, utcNow.tv_usec / 1000 , functionName, fileName, line);

	//Printint the message from the var_args.
	va_list list;
	va_start(list, line);

	format = va_arg(list, char*);
	vfprintf(outputStream, format, list);

	va_end(list);

	int formatLength = strlen(format);

	if(formatLength == 0 || format[formatLength - 1] != '\n'){
		fprintf(outputStream,"\n");
	}

	fflush(outputStream);
}

void getCrashDumpFilenameInto(char *buf)
{
	strcat(buf, "crash.dmp");
}

char *getVersionInfo(int verbose)
{
#if STACKVM
  extern char *__interpBuildInfo;
# define INTERP_BUILD __interpBuildInfo
# if COGVM
  extern char *__cogitBuildInfo;
# endif
#else
# define INTERP_BUILD interpreterVersion
#endif
  extern char *revisionAsString();

#define BUFFER_SIZE 4096

  char *info= (char *)malloc(BUFFER_SIZE);
  info[0]= '\0';

#if SPURVM
# if BytesPerOop == 8
#	define ObjectMemory " Spur 64-bit"
# else
#	define ObjectMemory " Spur"
# endif
#else
# define ObjectMemory
#endif
#if defined(NDEBUG)
# define BuildVariant "Production" ObjectMemory
#elif DEBUGVM
# define BuildVariant "Debug" ObjectMemory
# else
# define BuildVariant "Assert" ObjectMemory
#endif

#if USE_XSHM
#define USE_XSHM_STRING " XShm"
#else
#define USE_XSHM_STRING ""
#endif

#if ITIMER_HEARTBEAT
# define HBID " ITHB"
#else
# define HBID
#endif

  if(verbose){
	  snprintf(info, BUFFER_SIZE, IMAGE_DIALECT_NAME" VM version: "VM_VERSION"-"VM_BUILD_STRING USE_XSHM_STRING" "COMPILER_VERSION" [" BuildVariant HBID " VM]\nBuilt from: %s\n With:%s\n Revision: "VM_BUILD_SOURCE_STRING, INTERP_BUILD, GetAttributeString(1008));
  }else{
	  snprintf(info, BUFFER_SIZE, VM_VERSION"-"VM_BUILD_STRING USE_XSHM_STRING" "COMPILER_VERSION" [" BuildVariant HBID " VM]\n%s\n%s\n"VM_BUILD_SOURCE_STRING, INTERP_BUILD, GetAttributeString(1008));
  }

  return info;
}

/***
 *  This SHOULD be rewritten passing the FILE* as a parameter.
 */

static FILE* outputStream = NULL;

void
vm_setVMOutputStream(FILE * stream){
	fflush(outputStream);
	outputStream = stream;
}

int
vm_printf(const char * format, ... ){

	va_list list;
	va_start(list, format);

	if(outputStream == NULL){
		outputStream = stdout;
	}

	int returnValue = vfprintf(outputStream, format, list);

	va_end(list);

	return returnValue;
}
