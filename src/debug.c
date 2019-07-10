#include <pharo.h>
#include <stdarg.h>

#ifdef DEBUG
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
 *
 */
EXPORT(void) logLevel(int value){
	max_error_level = value;
}

void error(char *errorMessage){
    logError(errorMessage);
    abort();
}

static char* severityName[4] = {"ERROR", "WARN", "INFO", "DEBUG"};

EXPORT(void) logMessage(int level, const char* fileName, const char* functionName, int line, ...){
	char * format;
	char timestamp[20];

	if(level > max_error_level){
		return;
	}

	time_t now = time(NULL);
	strftime(timestamp, 20, "%Y-%m-%d %H:%M:%S", localtime(&now));

	//Printing the header.
	// Ex: [DEBUG] 2017-11-14 21:57:53,661 functionName (filename:line) - This is a debug log message.
	printf("[%-5s] %s %s (%s:%d):", severityName[level - 1], timestamp, functionName, fileName, line);

	//Printint the message from the var_args.
	va_list list;
	va_start(list, line);

	format = va_arg(list, char*);
	vprintf(format, list);

	va_end(list);

	int formatLength = strlen(format);

	if(formatLength == 0 || format[formatLength - 1] != '\n'){
		printf("\n");
	}
}
