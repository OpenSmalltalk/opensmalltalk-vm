/*
 *  sqMacEncoding.h
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on Mon Dec 01 2003.
 *
 */

#include <Carbon/Carbon.h>

void getVMPathWithEncoding(char *target,UInt32 encoding);
void SetVMPath(FSSpec *workingDirectory);
Boolean VMPathIsEmpty();
void getImageNameWithEncoding(char *target,UInt32 encoding);
void SetImageNameViaCFString(CFStringRef string);
void SetImageNameViaString(char *string,UInt32 encoding);
void SetImageName(FSSpec *workingDirectory);
Boolean ImageNameIsEmpty();
char *getImageName();
void getShortImageNameWithEncoding(char *target,UInt32 encoding);
void SetShortImageNameViaString(char *string,UInt32 encoding);
Boolean ShortImageNameIsEmpty();
void getDocumentNameWithEncoding(char *target,UInt32 encoding);

int  IsImageName(char *name);
void setEncodingType (char *aType);
char* getEncodingType (UInt32 aType);
