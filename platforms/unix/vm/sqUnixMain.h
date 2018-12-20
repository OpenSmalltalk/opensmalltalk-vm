#ifndef __sqUnixMain_h
#define __sqUnixMain_h

extern char   imageName[];
extern char   shortImageName[];
extern sqInt  inputEventSemaIndex;
extern char   vmPath[];
extern char  *exeName;
extern char **argVec;

extern int    fullScreenFlag;
extern int    textEncodingUTF8;

extern void   imgInit(void);

#define	EventTypeUpdate	100

#endif /* __sqUnixMain_h */
