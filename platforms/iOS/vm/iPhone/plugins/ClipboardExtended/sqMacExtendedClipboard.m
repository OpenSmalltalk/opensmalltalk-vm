/*
 *  sqMacExtendedClipboard.m
 *  SqueakClipboardExtendedxcodeproj
 *
 *  Created by John Sterling Mcintosh on 4/21/06.
 *  Copyright 2006-2010 Corporate Smalltalk Consulting ltd. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 *  obtaining a copy of this software and associated documentation
 *  files (the "Software"), to deal in the Software without
 *  restriction, including without limitation the rights to use,
 *  copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following
 *  conditions:
 *  
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 *  
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *  OTHER DEALINGS IN THE SOFTWARE.
 *
 */

#include "sqMacExtendedClipboard.h"


extern struct VirtualMachine* interpreterProxy;

void sqPasteboardClear(CLIPBOARDTYPE inPasteboard )
{
	NSArray *arrayOfTypes = [NSArray array];
	
	inPasteboard.items =  arrayOfTypes;
}

sqInt sqPasteboardGetItemCount (CLIPBOARDTYPE inPasteboard )
{
	return [inPasteboard.items count];
}

sqInt sqPasteboardCopyItemFlavorsitemNumber (CLIPBOARDTYPE inPasteboard, sqInt formatNumber )
{

	sqInt formatTypeLength;
	sqInt flavorCount;
	
	flavorCount =  [[inPasteboard pasteboardTypes] count];
	if (formatNumber > flavorCount) {
		return interpreterProxy->nilObject();
	}
	
	NSString *formatType = [inPasteboard pasteboardTypes][formatNumber-1];
	
	const char *utf8data = [formatType UTF8String];
	formatTypeLength = strlen(utf8data);
	sqInt outData = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), formatTypeLength);
	unsigned char* formatConverted = interpreterProxy->firstIndexableField(outData);
	memcpy(formatConverted,utf8data,formatTypeLength);
	
	return outData;
}

#warning this is wrong as it makes a 64 bit pointer for 32bit usage later
void * sqCreateClipboard( void )
{
	return (__bridge void*) [UIPasteboard generalPasteboard];
}

void sqPasteboardPutItemFlavordatalengthformatTypeformatLength ( CLIPBOARDTYPE inPasteboard, char* inData, sqInt dataLength, char* format, sqInt formatLength)
{	
	NSString *formatType = [[NSString alloc] initWithBytes: format length: formatLength encoding:  NSUTF8StringEncoding];
	NSData* data = [[NSData alloc ] initWithBytes: inData length: dataLength];

	[inPasteboard setData: data forPasteboardType: formatType];

}
	
sqInt sqPasteboardCopyItemFlavorDataformatformatLength (  CLIPBOARDTYPE inPasteboard, char* format, sqInt formatLength)
{
	NSString *formatType = [[NSString alloc] initWithBytes: format length: formatLength encoding:  NSUTF8StringEncoding];
	NSData *dataBuffer = [inPasteboard dataForPasteboardType: formatType];

	if (dataBuffer == NULL) {
		return interpreterProxy->nilObject();
	}		
	sqInt dataLength = [dataBuffer length];
	sqInt outData = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), dataLength );
	char *outDataPtr = (char *) interpreterProxy->firstIndexableField(outData);
	[dataBuffer getBytes: outDataPtr];

	return outData;
}
