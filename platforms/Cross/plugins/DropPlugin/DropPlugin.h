/* drop support primitives */

/* module initialization/shutdown */
int dropInit(void);
int dropShutdown(void);

char* dropRequestFileName(int dropIndex); /* return name of file or NULL if error */
/* note: dropRequestFileHandle needs to bypass plugin security checks when implemented */
int dropRequestFileHandle(int dropIndex); /* return READ-ONLY file handle OOP or nilObject if error */
int sqSecFileAccessCallback(void *);
void sqSetNumberOfDropFiles(int numberOfFiles);
void sqSetFileInformation(int dropIndex, void *dropFile);
void sqDragTriggerData(char *aByteArray, int dataLength, char *aFormat, int formatLength);
