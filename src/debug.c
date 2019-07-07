#include <pharo.h>
#include <stdarg.h>

static int max_error_level = 2;

/*
 * This function set the logLevel to use in the VM
 *
 * LOG_NONE 		0
 * LOG_ERROR 		1
 * LOG_WARN 		2
 * LOG_INFO 		3
 * LOG_DEBUG		4
 *
 */
void logLevel(int value){
	max_error_level = value;
}

void error(char *errorMessage){
    logError(errorMessage);
    abort();
}

void logMessage(int level, const char* fileName, const char* functionName, int line, ...){
	char * format;

	if(level < max_error_level){
		return;
	}

	va_list list;
	va_start(list, line);

	format = va_arg(list, char*);
	printf("%s (%s:%d):", functionName, fileName, line);
	vprintf(format, list);

	va_end(list);
}
