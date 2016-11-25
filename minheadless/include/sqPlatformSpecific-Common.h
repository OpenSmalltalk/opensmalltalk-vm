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

/* Text encoding conversions. */
extern const char *sqUTF8ToUTF32Iterate(const char *string, int *dest);
extern unsigned short *sqUTF8ToUTF16Copy(unsigned short *dest, size_t destSize, const char *src);
extern unsigned short *sqUTF8toUTF16New(const char *string);