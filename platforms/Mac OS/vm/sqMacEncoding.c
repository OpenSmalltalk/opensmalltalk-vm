/*
 *  sqMacEncoding.c
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on Mon Dec 01 2003.
 *
 */

#include "sqMacEncoding.h"
#include "sqMacUIConstants.h" 

#if TARGET_API_MAC_CARBON
    CFStringEncoding gCurrentVMEncoding=kCFStringEncodingMacRoman;
#else
    UInt32 gCurrentVMEncoding=0;
#endif


/*** Variables -- image and path names ***/
char imageName[IMAGE_NAME_SIZE+1];

#if TARGET_API_MAC_CARBON
static CFStringRef vmPathString=NULL;
static CFStringRef imageNameString=NULL;
static CFStringRef documentNameString=NULL;
static CFStringRef shortImageNameString=NULL;

void getVMPathWithEncoding(char *target,UInt32 encoding) {
    CFStringGetCString (vmPathString, target, VMPATH_SIZE, encoding);
}

void SetVMPath(FSSpec *workingDirectory) {
    char path[VMPATH_SIZE + 1];
    
    if (vmPathString != NULL)  
        CFRelease(vmPathString);
    PathToDir(path,VMPATH_SIZE, workingDirectory,kCFStringEncodingUTF8);
    vmPathString = CFStringCreateWithCString(NULL, path, kCFStringEncodingUTF8);
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
    CFRetain(string);
    imageNameString = string;
    ignore = getImageName();
}

void SetImageNameViaString(char *string,UInt32 encoding) {
    char *ignore;
    if (imageNameString != NULL)
        CFRelease(imageNameString);
    imageNameString = CFStringCreateWithCString(NULL, string, encoding);
    ignore = getImageName();
}

void SetImageName(FSSpec *workingDirectory) {
    char path[IMAGE_NAME_SIZE + 1];
    
    PathToFile(path,IMAGE_NAME_SIZE, workingDirectory,kCFStringEncodingUTF8);
    SetImageNameViaString(path,kCFStringEncodingUTF8);
}

Boolean ImageNameIsEmpty() {
    if (imageNameString == NULL) 
        return true;
    return getImageName() == 0x00;
}

void getDocumentNameWithEncoding(char *target,UInt32 encoding) {
    if (documentNameString == NULL) {
        *target = 0x00;
        return;
    }
    CFStringGetCString (documentNameString, target, DOCUMENT_NAME_SIZE, encoding);
}

void SetDocumentNameViaString(char *string,UInt32 encoding) {
    if (documentNameString != NULL)
        CFRelease(documentNameString);
    documentNameString = CFStringCreateWithCString(NULL, string, encoding);
}

void getShortImageNameWithEncoding(char *target,UInt32 encoding) {
    if (shortImageNameString == NULL) {
        *target = 0x00;
        return;
    }
    CFStringGetCString (shortImageNameString, target, SHORTIMAGE_NAME_SIZE, encoding);
}

void SetShortImageNameViaString(char *string,UInt32 encoding) {
    if (shortImageNameString != NULL)
        CFRelease(shortImageNameString);
    shortImageNameString = CFStringCreateWithCString(NULL, string, encoding);
}

Boolean ShortImageNameIsEmpty() {
    return shortImageNameString == NULL;
}
#else
static char vmPathString[VMPATH_SIZE+1];
static char documentNameString[DOCUMENT_NAME_SIZE+1];
static char shortImageNameString[SHORTIMAGE_NAME_SIZE+1];

void getVMPathWithEncoding(char *target,UInt32 encoding) {
    strcpy(target,vmPathString);
}

void SetVMPath(FSSpec *workingDirectory) {
    PathToDir(vmPathString,VMPATH_SIZE, workingDirectory,kCFStringEncodingUTF8);
}

Boolean VMPathIsEmpty() {
    return vmPathString[0] == 0x00;
}

void getImageNameWithEncoding(char *target,UInt32 encoding) {
    strcpy(target,imageName);
}

char *getImageName(void) {
    return imageName;
}
    
void SetImageNameViaString(char *string,UInt32 encoding) {
    strcpy(imageName,string);
}

void SetImageName(FSSpec *workingDirectory) {
    PathToFile(imageName,IMAGE_NAME_SIZE, workingDirectory,kCFStringEncodingUTF8);
}

Boolean ImageNameIsEmpty() {
    return imageName[0] == 0x00;
}

void getDocumentNameWithEncoding(char *target,UInt32 encoding) {
    strcpy(target,documentNameString);
}

void SetDocumentNameViaString(char *string,UInt32 encoding) {
    strcpy(documentNameString,string);
}

void getShortImageNameWithEncoding(char *target,UInt32 encoding) {
    strcpy(target,shortImageNameString);
}

void SetShortImageNameViaString(char *string,UInt32 encoding) {
    strcpy(shortImageNameString,string);
}

Boolean ShortImageNameIsEmpty() {
    return shortImageNameString[0] == 0x00;
}
#endif


void setEncodingType (char * string) {
    gCurrentVMEncoding = kCFStringEncodingMacRoman;
    if (strcmp("UTF-8",string) == 0)
        gCurrentVMEncoding = kCFStringEncodingUTF8;
}

char  *getEncodingType(UInt32 aType) {
    if (aType == kCFStringEncodingMacRoman) 
        return &"macintosh";
    if (aType == kCFStringEncodingUTF8) 
        return &"UTF-8";
    return &"macintosh";
}