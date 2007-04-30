/*
 *  sqMacExtendedClipboard.c
 *  SqueakClipboardExtendedxcodeproj
 *
 *  Created by John Sterling Mcintosh on 4/21/06.
 *  Copyright 2006 Corporate Smalltalk Consulting ltd. All rights reserved.
 *  Licenced under the squeak-l NSImage
 *
 */
#include <Carbon/Carbon.h>

#include "sqMacExtendedClipboard.h"
/* The virtual machine proxy definition */
#include "sqVirtualMachine.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"


extern struct VirtualMachine* interpreterProxy;

void sqPasteboardClear( PasteboardRef inPasteboard )
{
	PasteboardClear( inPasteboard );
}

int sqPasteboardGetItemCount (	PasteboardRef inPasteboard )
{
	ItemCount itemCount;
	
	PasteboardSynchronize ( inPasteboard );
	PasteboardGetItemCount ( inPasteboard, &itemCount);
	return itemCount;
}

int sqPasteboardCopyItemFlavorsitemNumber ( PasteboardRef inPasteboard, int formatNumber )
{
	CFArrayRef flavorTypeArray;	
	CFStringRef formatType;
	int formatTypeLength;
	PasteboardItemID itemID;
	OSStatus err;
	int flavorCount;
	
	PasteboardSynchronize ( inPasteboard );
	err = PasteboardGetItemIdentifier (inPasteboard,1,&itemID);

	if (err) {
		return interpreterProxy->nilObject();
	}		

	err = PasteboardCopyItemFlavors( inPasteboard, itemID, &flavorTypeArray );
	
	if (err) {
		return interpreterProxy->nilObject();
	}		
	
	flavorCount = CFArrayGetCount( flavorTypeArray );
	if (formatNumber > flavorCount) {
		CFRelease(flavorTypeArray);
		return interpreterProxy->nilObject();
	}
	
	formatType = (CFStringRef) CFArrayGetValueAtIndex ( flavorTypeArray, formatNumber-1);
	
	formatTypeLength = CFStringGetLength (formatType);
	
	int outData = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), formatTypeLength);
	unsigned char* formatConverted = interpreterProxy->firstIndexableField(outData);
		
	CFStringGetBytes ( formatType, CFRangeMake(0,formatTypeLength), kCFStringEncodingMacRoman, 0, 
							   false, formatConverted,formatTypeLength, NULL);
	CFRelease (flavorTypeArray);
	
	return outData;
}

PasteboardRef sqCreateClipboard( void )
{
    static PasteboardRef sPasteboard = NULL;

    if ( sPasteboard == NULL )
    {
        PasteboardCreate( kPasteboardClipboard, &sPasteboard );
    }

    return sPasteboard;
}

void sqPasteboardPutItemFlavordatalengthformatTypeformatLength ( PasteboardRef inPasteboard, char* inData, int dataLength, char* format, int formatLength)
{	
	OSStatus err;

	CFStringRef formatType = CFStringCreateWithBytes ( kCFAllocatorDefault, format, formatLength, 
														kCFStringEncodingMacRoman, false);
	CFDataRef convertedData = CFDataCreate(NULL, inData, dataLength);
	
	err = PasteboardPutItemFlavor ( inPasteboard, 1, formatType, convertedData, kPasteboardFlavorNoFlags);

	CFRelease (convertedData);
	CFRelease (formatType);

	if (err) {
		interpreterProxy->success(0);
	}
}
	
int sqPasteboardCopyItemFlavorDataformatformatLength ( PasteboardRef inPasteboard, char* format, int formatLength)
{
	CFDataRef dataBuffer;
	PasteboardItemID itemID;
	OSStatus err;
	
	CFStringRef formatType = CFStringCreateWithBytes ( kCFAllocatorDefault, format, formatLength,
														kCFStringEncodingMacRoman, false);
														
	PasteboardSynchronize ( inPasteboard );
	err = PasteboardGetItemIdentifier (inPasteboard,1,&itemID);

	if (err) {
		return interpreterProxy->nilObject();
	}		

	err = PasteboardCopyItemFlavorData ( inPasteboard, itemID, formatType, &dataBuffer);
	
	if (err) {
		CFRelease(formatType);
		return interpreterProxy->nilObject();
	}
	
	int dataLength = CFDataGetLength(dataBuffer);
	int outData = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), dataLength );
	unsigned char* flavorData = interpreterProxy->firstIndexableField(outData);
	CFDataGetBytes (dataBuffer, CFRangeMake(0,dataLength), flavorData);
	
	CFRelease(formatType);
	CFRelease(dataBuffer);
		
	return outData;
}