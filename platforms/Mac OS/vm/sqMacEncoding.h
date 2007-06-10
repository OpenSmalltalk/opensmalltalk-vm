/*
 *  sqMacEncoding.h
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on Mon Dec 01 2003.
 *
 */

#include <Carbon/Carbon.h>

void getVMPathWithEncoding(char *target,UInt32 encoding);
void SetVMPathFromCFString(CFMutableStringRef strRef);
Boolean VMPathIsEmpty(void);
void getImageNameWithEncoding(char *target,UInt32 encoding);
void SetImageNameViaCFString(CFStringRef string);
void SetImageNameViaString(char *string,UInt32 encoding);
Boolean ImageNameIsEmpty(void);
char *getImageName(void);
void getShortImageNameWithEncoding(char *target,UInt32 encoding);
void SetShortImageNameViaString(char *string,UInt32 encoding);
Boolean ShortImageNameIsEmpty(void);
void getDocumentNameWithEncoding(char *target,UInt32 encoding);
void SetDocumentNameViaString(char *string,UInt32 encoding);

void setEncodingType (char *aType);
char* getEncodingType (UInt32 aType);
int IsImageName(char *name);