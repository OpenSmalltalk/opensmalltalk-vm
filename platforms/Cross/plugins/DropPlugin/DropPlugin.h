/* drop support primitives */

/* module initialization/shutdown */
sqInt dropInit(void);
sqInt dropShutdown(void);

char *dropRequestFileName(sqInt dropIndex); /* return name of file or NULL if error */
char *dropRequestURI(sqInt dropIndex); /* return uri (if supported) or NULL if error */
/* note: dropRequestFileHandle needs to bypass plugin security checks when implemented */
sqInt dropRequestFileHandle(sqInt dropIndex); /* return READ-ONLY file handle OOP or nilObject if error */
