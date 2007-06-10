/****************************************************************************
*   PROJECT: Mac clipboard interface.
*   FILE:    sqMacUIClipBoard.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id$
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
 3.8.11b1 Mar 4th, 2006 JMM refactor, cleanup and add headless support
*****************************************************************************/
#include "sq.h"
#include "sqMacUIClipBoard.h"

int clipboardSize(void);

/*** Clipboard Support (text only for now) ***/

void SetUpClipboard(void) {
}

void FreeClipboard(void) {
}

sqInt clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex) {
	long clipSize, charsToMove;
	ScrapRef scrap;
	OSStatus err;

    err = GetCurrentScrap (&scrap);
    if (err != noErr) return 0;       
	clipSize = clipboardSize();
 	charsToMove = (count < clipSize) ? count : clipSize;
    err = GetScrapFlavorData(scrap,kScrapFlavorTypeText,(long *) &charsToMove,(char *) byteArrayIndex + startIndex);
    if (err != noErr) { 
        FreeClipboard();
        return 0;       
    }
	return charsToMove;
}

sqInt clipboardSize(void) {
	long count;
	ScrapRef scrap;
	OSStatus err;

    err = GetCurrentScrap (&scrap);
    if (err != noErr) return 0;       
    err = GetScrapFlavorSize (scrap, kScrapFlavorTypeText, &count); 
	if (err != noErr) {
		return 0;
	} else {
		return count;
	}
}

sqInt clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex) {
	ScrapRef scrap;
	OSErr err;
	err = ClearCurrentScrap();
    err = GetCurrentScrap (&scrap);
	err = PutScrapFlavor ( scrap, kScrapFlavorTypeText, kScrapFlavorMaskNone , count,  (const void *) (byteArrayIndex + startIndex));
	return 0;
}

