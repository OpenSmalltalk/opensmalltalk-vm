/*
 *  sqMacEncoding.c
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on Mon Dec 01 2003.
 *	May 24th, 2005, JMM. bug in SetImageNameViaCFString
 *
 3.8.11b1 Mar 4th, 2006 JMM refactor, cleanup and add headless support
 */
#include "sq.h"

#include "sqMacEncoding.h"
#include "sqMacUIConstants.h"
#include "sqMacUnixFileInterface.h"


    CFStringEncoding gCurrentVMEncoding=kCFStringEncodingMacRoman;


/*** Variables -- image and path names ***/
char imageName[IMAGE_NAME_SIZE+1];

static CFStringRef vmPathString=NULL;
static CFStringRef imageNameString=NULL;
static CFStringRef shortImageNameString=NULL;

void getVMPathWithEncoding(char *target,UInt32 encoding) {
    CFStringGetCString (vmPathString, target, VMPATH_SIZE, encoding);
}

void SetVMPathFromCFString(CFMutableStringRef strRef) {
    if (vmPathString != NULL)
        CFRelease(vmPathString);
	vmPathString = strRef;
	CFRetain(vmPathString);
}

Boolean VMPathIsEmpty() {
    char path[VMPATH_SIZE + 1];
     if (vmPathString == NULL)
        return true;
    getVMPathWithEncoding(path,gCurrentVMEncoding);
    return (*path == 0x00);
}

void getImageNameWithEncoding(char *target,UInt32 encoding) {
    CFStringGetCString (imageNameString, target, IMAGE_NAME_SIZE, encoding);
}

char *getImageName(void) {
    getImageNameWithEncoding(imageName,gCurrentVMEncoding);
    return imageName;
}

void SetImageNameViaCFString(CFStringRef string) {
    char *ignore;
	// normalization because we get here from looking for file name in resource folder directly at startup time.
	// HFS+ imposes Unicode2.1 decomposed UTF-8 encoding on all path elements
	CFMutableStringRef mutableStr= CFStringCreateMutableCopy(NULL, 0, string);
	if (gCurrentVMEncoding == kCFStringEncodingUTF8)
		CFStringNormalize(mutableStr, kCFStringNormalizationFormKC); // pre-combined
    CFRetain(mutableStr);
	if (imageNameString != NULL)
        CFRelease(imageNameString);
    imageNameString = mutableStr;
    ignore = getImageName();
}

void SetImageNameViaString(char *string,UInt32 encoding) {
	CFStringRef path;

	if (imageNameString != NULL)
        CFRelease(imageNameString);
	path = CFStringCreateWithCString(NULL, string, encoding);
    SetImageNameViaCFString(path);
	CFRelease(path);
}


Boolean ImageNameIsEmpty() {
    if (imageNameString == NULL)
        return true;
    return getImageName() == 0x00;
}

void getShortImageNameWithEncoding(char *target,UInt32 encoding) {
    if (!shortImageNameString)
        *target = 0x00;
    else
		CFStringGetCString (shortImageNameString, target, SHORTIMAGE_NAME_SIZE, encoding);
}

void SetShortImageNameViaString(char *string,UInt32 encoding) {
    if (shortImageNameString)
        CFRelease(shortImageNameString);
    shortImageNameString = CFStringCreateWithCString(NULL, string, encoding);
}

Boolean ShortImageNameIsEmpty() {
    return shortImageNameString == NULL;
}

void setEncodingType (char * string) {
      gCurrentVMEncoding = kCFStringEncodingMacRoman;
      if (strcmp("UTF-8",string) == 0)
          gCurrentVMEncoding = kCFStringEncodingUTF8;
      if (strcmp("ShiftJIS",string) == 0)
          gCurrentVMEncoding = kCFStringEncodingShiftJIS;
      if (strcmp("Latin1",string) == 0)
          gCurrentVMEncoding = kCFStringEncodingISOLatin1;
      if (strcmp("iso-8859-1",string) == 0)
          gCurrentVMEncoding = kCFStringEncodingISOLatin1;
  }

  char  *getEncodingType(UInt32 aType) {
      if (aType == kCFStringEncodingMacRoman)
          return (char *)&"macintosh";
      if (aType == kCFStringEncodingUTF8)
          return (char *)&"UTF-8";
      if (aType == kCFStringEncodingShiftJIS)
          return (char *)&"ShiftJIS";
      if (aType == kCFStringEncodingISOLatin1)
          return (char *)&"Latin1";
      return (char *)&"macintosh";
  }
