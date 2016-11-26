#include "sqPath.h"
#include "sqTextEncoding.h"

/**
 * Printing and reporting functions.
 * In some platforms, such as Windows, stdout, stderr and stdin are not always usable
 */
extern void sqMessagePrintf(const char *format, ...);
extern void sqWarnPrintf(const char *format, ...);
extern void sqErrorPrintf(const char *format, ...);

/*
#define messagePrintf sqMessagePrintf
#define warnPrintf sqWarnPrintf
#define errorPrintf sqErrorPrintf
*/

#define messagePrintf printf
#define warnPrintf printf
#define errorPrintf printf

#define error sqError

/* Function used by the Squeak security plugin. In a headless VM, do not create a message box. */
extern int sqAskSecurityYesNoQuestion(const char *question);

extern const char *sqGetCurrentImagePath(void);
