/*
 *  macFileNameBits.c
 *  FT2Plugin support
 *
 *  Created by John M McIntosh on 21/11/05.
 * Feb 15th, 2006, use sqFilenameFromString
 *
 */
#include "sqVirtualMachine.h" 

extern struct VirtualMachine * interpreterProxy;

void		sqFilenameFromString(char *buffer,long fileIndex, long fileLength) {
	interpreterProxy->ioFilenamefromStringofLengthresolveAliases(buffer,fileIndex, fileLength, 1);
}

void fetchPreferences() {}

/* int IsImageName(char *name) {
	return 1;
};

int isSystem9_0_or_better(void)
{
	return 1;
}

CFStringEncoding gCurrentVMEncoding=kCFStringEncodingMacRoman;

void fetchPreferences() {
	CFBundleRef  myBundle;
	CFDictionaryRef myDictionary;
	CFStringRef    SqueakVMEncodingType;
	char        encoding[256];

	myBundle = CFBundleGetMainBundle();
	myDictionary = CFBundleGetInfoDictionary(myBundle);
	SqueakVMEncodingType = CFDictionaryGetValue(myDictionary, CFSTR("SqueakEncodingType"));
	if (SqueakVMEncodingType) 
		CFStringGetCString (SqueakVMEncodingType, encoding, 256, kCFStringEncodingMacRoman);
	else
		*encoding = 0x00;

	gCurrentVMEncoding = kCFStringEncodingMacRoman;
	if (strcmp("UTF-8",encoding) == 0)
	  gCurrentVMEncoding = kCFStringEncodingUTF8;
	if (strcmp("ShiftJIS",encoding) == 0)
	  gCurrentVMEncoding = kCFStringEncodingShiftJIS;
}
*/