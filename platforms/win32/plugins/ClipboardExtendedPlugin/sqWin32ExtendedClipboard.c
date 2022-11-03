/*
 *  sqWin32ExtendedClipboard.m
 *
 *  This file is part of Squeak
 *
 */

#include <Windows.h>
#include "sqWin32.h"
#include "sqVirtualMachine.h"
#include "sqAssert.h"

#ifdef SQUEAK_BUILTIN_PLUGIN
extern void *ioGetWindowHandle(void);
# define myWindow() ioGetWindowHandle()
#else
__declspec(dllimport) void *getSTWindowHandle(void);
# define myWindow() getSTWindowHandle()
#endif

extern struct VirtualMachine* interpreterProxy;
typedef void *CLIPBOARDTYPE;

void
sqPasteboardClear(CLIPBOARDTYPE inPasteboard)
{
	(void)OpenClipboard(NULL);
	(void)EmptyClipboard();
}

sqInt
sqPasteboardGetItemCount(CLIPBOARDTYPE inPasteboard)
{
#if 0
	UINT count = 0, format = 0, lastFormat = 0;

	if (!OpenClipboard(myWindow())) {
		interpreterProxy->primitiveFailFor(PrimErrOperationFailed);
		return 0;
	}
	while ((format = EnumClipboardFormats(lastFormat))) {
		lastFormat = format;
		++count;
	}
	CloseClipboard(NULL);
    return count;
#else
	return CountClipboardFormats();
#endif
}

sqInt
sqPasteboardCopyItemFlavorsitemNumber(CLIPBOARDTYPE inPasteboard, sqInt formatNumber)
{
	UINT count = 0, format = 0, lastFormat = 0;

	if (formatNumber < 1
	 || !OpenClipboard(myWindow())) {
		interpreterProxy->primitiveFailFor(PrimErrOperationFailed);
		return 0;
	}
	while ((format = EnumClipboardFormats(lastFormat))
		&& ++count < formatNumber)
		lastFormat = format;
	CloseClipboard();
	return format
				? interpreterProxy->integerObjectOf(format)
				: interpreterProxy->nilObject();
}

void *
sqCreateClipboard(void) { return (void *)0xB0A4D; }

void
sqPasteboardPutItemFlavordatalengthformatTypeformatLength(CLIPBOARDTYPE inPasteboard, char *inData, sqInt dataLength, char *format, sqInt formatLength)
{
	interpreterProxy->primitiveFailFor(PrimErrUnsupported);
}

void
sqPasteboardPutItemFlavordatalengthformatType(CLIPBOARDTYPE inPasteboard, char *inData, sqInt dataLength, sqInt format)
{
	HANDLE globalMem;

	if (dataLength <= 0) {
		interpreterProxy->primitiveFailFor(PrimErrBadArgument);
		return;
	}
	if (!OpenClipboard(myWindow())) {
		interpreterProxy->primitiveFailFor(PrimErrOperationFailed);
		return;
	}
	if (format == CF_BITMAP) {
		interpreterProxy->primitiveFailFor(PrimErrUnsupported);
		return;
	}
	else {
		globalMem = GlobalAlloc(GMEM_MOVEABLE, dataLength);
		if (!globalMem) {
			CloseClipboard();
			interpreterProxy->primitiveFailFor(PrimErrNoCMemory);
			return;
		}
		void *globalBytes = GlobalLock(globalMem);
		if (!globalBytes) {
			CloseClipboard();
			GlobalFree(globalMem);
			interpreterProxy->primitiveFailFor(PrimErrOperationFailed);
			return;
		}
		memcpy(globalBytes, inData, dataLength);
		GlobalUnlock(globalMem);
	}
	(void)EmptyClipboard();
	if (!SetClipboardData((UINT)format, globalMem)) {
		CloseClipboard();
		GlobalFree(globalMem);
		interpreterProxy->primitiveFailFor(PrimErrOperationFailed);
		return;
	}
	CloseClipboard();
}

sqInt
sqPasteboardCopyItemFlavorDataformatformatLength(CLIPBOARDTYPE inPasteboard, char *format, sqInt formatLength)
{
	interpreterProxy->primitiveFailFor(PrimErrUnsupported);
	return interpreterProxy->nilObject();
}

// copied from sqWin32Window.c
extern int
reverse_image_words(unsigned int *dst, unsigned int *src,
					int depth, int width, RECT *rect);

sqInt
sqPasteboardCopyItemFlavorDataformat(CLIPBOARDTYPE inPasteboard, sqInt format)
{
	sqInt outData = 0;
	if (!OpenClipboard(myWindow())) {
		interpreterProxy->primitiveFailFor(PrimErrOperationFailed);
		return 0;
	}
	HANDLE data = GetClipboardData((UINT)format);
	// *%^$!# Microsoft do it again; CF_BITMAP is an exception; the memory
	// must not be locked.  WTF?!?!
	if (format == CF_BITMAP) {
		BITMAP bm;
		HGDIOBJ ogo = 0;
		HDC dc = 0;
		sqInt outBits;

		if (!data) {
			CloseClipboard();
			interpreterProxy->primitiveFailFor(PrimErrNotFound);
			return 0;
		}

		bzero(&bm,sizeof(bm));
		if (!GetObject(data, sizeof(BITMAP), &bm)
		 || !(dc = CreateCompatibleDC(NULL))
		 || !(ogo = SelectObject(dc,data))) {
			CloseClipboard();
			if (ogo) SelectObject(dc,ogo);
			if (dc) DeleteDC(dc);
			interpreterProxy->primitiveFailForwithSecondary
								(PrimErrOSError,GetLastError());
			return 0;
		}
#define FormBitsIndex 0
#define FormWidthIndex 1
#define FormHeightIndex 2
#define FormDepthIndex 3

#define BitsIndex 0
#define WidthIndex 1
#define HeightIndex 2
#define DepthIndex 3
#define ColourTableIndex 4
#define ArraySize (ColourTableIndex + 1)
		outData = interpreterProxy->instantiateClassindexableSize
									(interpreterProxy->classArray(), ArraySize);
		outBits = interpreterProxy->instantiateClassindexableSize
									(interpreterProxy->classBitmap(),
									bm.bmWidthBytes * bm.bmHeight / sizeof(int));
		if (!outBits)
			outData = 0;
		if (outData) {
			interpreterProxy->storePointerofObjectwithValue
								(BitsIndex,
								 outData,
								 outBits);
			interpreterProxy->storePointerofObjectwithValue
								(WidthIndex,
								 outData,
								 interpreterProxy->integerObjectOf(bm.bmWidth));
			interpreterProxy->storePointerofObjectwithValue
								(HeightIndex,
								 outData,
								 interpreterProxy->integerObjectOf(bm.bmHeight));
			interpreterProxy->storePointerofObjectwithValue
								(DepthIndex,
								 outData,
								 interpreterProxy->integerObjectOf(bm.bmBitsPixel));
			if (bm.bmBits)
				memcpy(interpreterProxy->firstIndexableField(outBits),
						bm.bmBits,
						bm.bmWidthBytes * bm.bmHeight);
			else {
				LONG nbytes = GetBitmapBits(data,
											bm.bmWidthBytes * bm.bmHeight,
											interpreterProxy->firstIndexableField(outBits));
				assert(nbytes == bm.bmWidthBytes * bm.bmHeight);
			}
		}
		SelectObject(dc,ogo);
		DeleteDC(dc);
	}
	else {
		void *dataBytes;
		if (!data
		 || !(dataBytes = GlobalLock(data))) {
			CloseClipboard();
			interpreterProxy->primitiveFailFor(PrimErrNotFound);
			return 0;
		}
		outData = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), GlobalSize(data));
		if (outData) {
			PBITMAPINFOHEADER pdib = (BITMAPINFOHEADER *)dataBytes; // Paul Atreides??

			// If the data is either CF_DIB or CF_DIBV5 and it is a bottom-up bitmap
			// (biHeight not negative) then turn it into a top-down bitmap to suit Squeak
			if ((format == CF_DIB || format == CF_DIBV5)
			 && pdib->biHeight > 0) {
				unsigned char *dest = interpreterProxy->firstIndexableField(outData);
				long size = GlobalSize(data);
				long scanLineLength = pdib->biWidth * pdib->biBitCount / 8;
				unsigned char *source, *start;
				assert(pdib->biSizeImage + sizeof(*pdib) < size);
				pdib->biHeight = - pdib->biHeight;
				memcpy(dest, dataBytes, size - pdib->biSizeImage);
				dest += size - pdib->biSizeImage;
				start = dataBytes + size - pdib->biSizeImage;
				source = dataBytes + size - scanLineLength;
				while (source > start) {
					memcpy(dest, source, scanLineLength);
					dest += scanLineLength;
					source -= scanLineLength;
				}
			}
			else
				memcpy(interpreterProxy->firstIndexableField(outData),
					   dataBytes,
					   GlobalSize(data));
		}
	}
	if (format != CF_BITMAP)
		GlobalUnlock(data);
	CloseClipboard();

	if (!outData) {
		interpreterProxy->primitiveFailFor(PrimErrNoMemory);
		return interpreterProxy->nilObject();
	}
    return outData;
}
