/*
 *  sqMacEncoding.h
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on Mon Dec 01 2003.
 *
 */

#if TARGET_API_MAC_CARBON
#include <Carbon/Carbon.h>
#else
#define CFStringEncodings UInt32
#endif 

void getVMPathWithEncoding(char *target,UInt32 encoding);
#ifndef MACINTOSHUSEUNIXFILENAMES
void SetVMPath(FSSpec *workingDirectory);
#else
void SetVMPathFromCFString(CFMutableStringRef strRef);
#endif
Boolean VMPathIsEmpty();
void getImageNameWithEncoding(char *target,UInt32 encoding);
void SetImageNameViaCFString(CFStringRef string);
void SetImageNameViaString(char *string,UInt32 encoding);
void SetImageName(FSSpec *workingDirectory);
void SetImageNameWithEncoding(FSSpec *workingDirectory,
							  CFStringEncodings encoding);
Boolean ImageNameIsEmpty();
char *getImageName();
void getShortImageNameWithEncoding(char *target,UInt32 encoding);
void SetShortImageNameViaString(char *string,UInt32 encoding);
Boolean ShortImageNameIsEmpty();
void getDocumentNameWithEncoding(char *target,UInt32 encoding);
void SetDocumentNameViaString(char *string,UInt32 encoding);

void setEncodingType (char *aType);
char* getEncodingType (UInt32 aType);
int IsImageName(char *name);