/* drop support primitives */

/* module initialization/shutdown */
sqInt dropInit(void);
sqInt dropShutdown(void);

char* dropRequestFileName(sqInt dropIndex); /* return name of file or NULL if error */
/* note: dropRequestFileHandle needs to bypass plugin security checks when implemented */
sqInt dropRequestFileHandle(sqInt dropIndex); /* return READ-ONLY file handle OOP or nilObject if error */
sqInt sqSecFileAccessCallback(void *);
void sqSetNumberOfDropFiles(sqInt numberOfFiles);
void sqSetFileInformation(sqInt dropIndex, void *dropFile);
void sqDragTriggerData(char *aByteArray, sqInt dataLength, char *aFormat, sqInt formatLength);
