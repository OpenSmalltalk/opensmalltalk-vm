/****************************************************************************
 *   PROJECT: Mac clipboard interface.
 *   FILE:    sqMacUIClipBoard.c
 *   CONTENT: 
 *
 *   AUTHOR:  John Maloney, John McIntosh, and others.
 *   ADDRESS: 
 *   EMAIL:   johnmci@smalltalkconsulting.com
 *   RCSID:   $Id: sqMacUIClipBoard.c 1344 2006-03-05 21:07:15Z johnmci $
 *
 *   NOTES: 
 *  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
 3.8.11b1 Mar 4th, 2006 JMM refactor, cleanup and add headless support
 *
 *  Aug 2008 - BGF changed to Pasteboard API's for UTF-8 compatibility;
 *			  was using deprecated Scrap Manager.
 *****************************************************************************/
#include "sq.h"
#include "sqMacUIClipBoard.h"

/*** Clipboard Support (text only for now) ***/

void SetUpClipboard(void) { }

void FreeClipboard(void) { }

/**
 * Implementation straight out of Apple's pasteboard guide. 
 * Assumes the image treats Macintosh as having UTF-8 clipboard.
 * Puts both UTF-8 and UTF-16 flavors into the scrap,
 * to reach the widest variety of applications.
 */
sqInt clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex) {
	
	OSStatus err;
	PasteboardRef pb;
	CFDataRef data;
	CFStringRef str;
	CFRange range;
	CFIndex converted, needed;
	UInt8 * bytes;
	
	err = PasteboardCreate (kPasteboardClipboard, & pb);
	if (err) return 0;
	
	err = PasteboardClear(pb);
	if (err) return 0;
	
	PasteboardSynchronize (pb);
	data = CFDataCreate (kCFAllocatorDefault, (UInt8*) (byteArrayIndex+startIndex), count);
	if (! data) return 0;
 	
	err = PasteboardPutItemFlavor( pb, (PasteboardItemID)1, kUTTypeUTF8PlainText, data, 0);
	CFRelease(data);
	if (err) return 0;
	
	/** To get the UTF-16 form most apps (e.g. Word, Thunderbird) need, use an intermediate CFString **/
	str = CFStringCreateWithBytes(kCFAllocatorDefault, (UInt8*) (byteArrayIndex+startIndex), count, kCFStringEncodingUTF8, false);
	if (! str) { return 0; }
	
	range.length = CFStringGetLength( str );
	range.location = 0;
	/** First call just gives us the needed size **/
	converted = CFStringGetBytes( 
								 str,
								 range,
								 kCFStringEncodingUTF16,
								 '?',
								 false,
								 NULL,		/** Meaning, tell me how many bytes are needed **/
								 0,
								 & needed);
	if (converted > 0) {
		bytes = malloc(needed);
		converted = CFStringGetBytes( 
									 str,
									 range,
									 kCFStringEncodingUTF16,
									 '?',
									 false,
									 bytes,		/** This time, we're really encoding **/
									 needed,
									 NULL);
		if (converted > 0) {
			data = CFDataCreateWithBytesNoCopy (kCFAllocatorDefault, bytes, needed, kCFAllocatorMalloc);
			if(data) {
				err = PasteboardPutItemFlavor (pb, (PasteboardItemID)1, kUTTypeUTF16PlainText, data, 0);
				CFRelease(data);
			}	
		} else {
			free (bytes);
		}
	}
	CFRelease (str);
	return 0;
}

/**
 * Implementation straight out of Apple's pasteboard guide.
 * Just look for the first Pasteboard item whose data flavor conforms to utf-16,
 * and convert it into a UTF-8 string for the VM.
 * (UTF-16 seems the pasteboard lingua-franca.)
 */
sqInt clipboardSize(void) {
	ItemCount itemCount;
	OSStatus err;
	CFRange range;
	CFIndex itemIndex;
	CFIndex flavorIndex;
	CFIndex converted, needed;
	CFStringRef str;
	PasteboardRef pb;
	
	err = PasteboardCreate (kPasteboardClipboard, & pb);
	if (err) return 0;
	PasteboardSynchronize (pb);
	err = PasteboardGetItemCount (pb, &itemCount);	
	if (err) return 0;
	
	for (itemIndex = 1; itemIndex <= itemCount; itemIndex++) {
		
        PasteboardItemID    itemID;
        CFArrayRef          flavorTypeArray;
        CFIndex             flavorCount;
		
        err = PasteboardGetItemIdentifier( pb, itemIndex, &itemID );
		if (err) continue;
		err = PasteboardCopyItemFlavors( pb, itemID, &flavorTypeArray );
		
		if (err) continue;
        flavorCount = CFArrayGetCount( flavorTypeArray );
        for( flavorIndex = 0; flavorIndex < flavorCount; flavorIndex++ )
        {
			
			CFStringRef             flavorType;
			CFDataRef               flavorData;
			
			flavorType = (CFStringRef) CFArrayGetValueAtIndex (flavorTypeArray, flavorIndex);
			if (err) continue;
			
			/** We have to search for UTF-16 as that seems to be the lingua franca;
			 if this is done looking for UTF-8, various paste-sources (Thunderbird, Microsoft Office)
			 seem not to yield conforming scraps.
			 **/
			
			if (UTTypeConformsTo(flavorType, kUTTypeUTF16PlainText))
            {
                err = PasteboardCopyItemFlavorData(pb, itemID, flavorType, &flavorData );
				if (! err) {
					
					/** Convert the UTF-16 to UTF-8 by making an intermediate CFString **/
					str = CFStringCreateWithBytes(kCFAllocatorDefault, CFDataGetBytePtr(flavorData), CFDataGetLength(flavorData), kCFStringEncodingUTF16, false);
					if (! str) {
						CFRelease (flavorData);
						CFRelease (flavorTypeArray);
						return 0;
					}
					range.length = CFStringGetLength(str);
					range.location = 0;
					
					converted = CFStringGetBytes( 
												 str,
												 range,
												 kCFStringEncodingUTF8,
												 '?',
												 false,
												 NULL,		/** Meaning, tell me how many bytes are needed **/
												 0,
												 & needed);
					CFRelease (str);
					CFRelease (flavorData);
					CFRelease (flavorTypeArray);
					if (converted > 0) {	/* Meaning, conversion is possible */
						return needed;
					}
					return 0;
				}
			}
		}
		CFRelease (flavorTypeArray);
	}
	return 0;
}

/*
 * Implementation straight out of Apple's pasteboard guide.
 * Just look for the first Pasteboard item whose data flavor is conforms to utf-8.
 */
sqInt clipboardReadIntoAt(sqInt count, sqInt byteArrayPtr, sqInt startIndex) {
	
	ItemCount itemCount;
	CFIndex itemIndex;
	CFIndex flavorIndex;
	OSStatus err;
	
	PasteboardRef pb;
	err = PasteboardCreate (kPasteboardClipboard, & pb);
	if (err) return 0;
	
	PasteboardSynchronize (pb);
	err = PasteboardGetItemCount (pb, &itemCount);	
	if (err) return 0;
	
	for (itemIndex = 1; itemIndex <= itemCount; itemIndex++) 	{
		
        PasteboardItemID    itemID;
        CFArrayRef          flavorTypeArray;
        CFIndex             flavorCount;
		
        err = PasteboardGetItemIdentifier( pb, itemIndex, &itemID );
		if (err) continue;
        err = PasteboardCopyItemFlavors( pb, itemID, &flavorTypeArray );
		if (err) continue;
		
        flavorCount = CFArrayGetCount( flavorTypeArray );
        for( flavorIndex = 0; flavorIndex < flavorCount; flavorIndex++ )
        {
			CFStringRef flavorType;
			CFDataRef   flavorData;
			
			flavorType = (CFStringRef) CFArrayGetValueAtIndex(flavorTypeArray, flavorIndex);
			
			/** We have to search for UTF-16 as that seems to be the lingua franca;
			 if this is done looking for UTF-8, various paste-sources (Thunderbird, Microsoft Office)
			 seem not to yield conforming scraps.
			 **/
			if (UTTypeConformsTo(flavorType, kUTTypeUTF16PlainText))
       		{
				CFRange range;
				CFIndex converted, bytesUsed;
				CFStringRef str;
				err = PasteboardCopyItemFlavorData (pb, itemID,  flavorType, &flavorData);
				if (!err) {
					
					/** Convert the UTF-16 to UTF-8 by making an intermediate CFString **/
					str = CFStringCreateWithBytes (kCFAllocatorDefault, CFDataGetBytePtr(flavorData), CFDataGetLength(flavorData), kCFStringEncodingUTF16, false);
					if (! str) {
						CFRelease (flavorData);
						CFRelease (flavorTypeArray);
						return 0;
					}
					range.length = CFStringGetLength (str);
					range.location = 0;
					
					converted = CFStringGetBytes( 
												 str,
												 range,
												 kCFStringEncodingUTF8,
												 '?',
												 false,
												 (UInt8*) (byteArrayPtr+startIndex),
												 count,
												 & bytesUsed);
					CFRelease (str);
					CFRelease (flavorData);
					CFRelease (flavorTypeArray);
					return (converted > 0) ? bytesUsed : 0;
				}
			}
		}
		CFRelease (flavorTypeArray);
	}
	return 0;
}

