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

// As a convenience, because UTF16/CF_UNICODETEXT is so tricky, handle
// CF_PRIVATELAST as a special code implying put/get UTF-8 converted
// to/from UTF16

#define CF_UTF8TEXT CF_PRIVATELAST

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
	int nullTerminationBytes = 0;

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
	// As a convenience, because UTF16/CF_UNICODETEXT is so tricky, handle
	// CF_UTF8TEXT as a special code implying put UTF-8 converted to UTF16
	if (format == CF_UTF8TEXT) {
		int numWchars = MultiByteToWideChar(CP_UTF8, 0, inData, dataLength, 0, 0);
		if (numWchars < 0) {
			interpreterProxy->primitiveFailForOSError(GetLastError());
			return;
		}
		globalMem = GlobalAlloc(GMEM_MOVEABLE,(numWchars + 1) * sizeof(wchar_t));
		if (!globalMem) {
			CloseClipboard();
			interpreterProxy->primitiveFailFor(PrimErrNoCMemory);
			return;
		}
		wchar_t *globalWchars = GlobalLock(globalMem);
		(void)MultiByteToWideChar(CP_UTF8, 0, inData, dataLength, globalWchars, (numWchars + 1) * sizeof(wchar_t));
		globalWchars[numWchars] = 0;
		format = CF_UNICODETEXT;
	}
	else {
		// Text formats must put null-terminated strings, which isn't convenient
		// for Squeak, so add them if missing.
		if (format == CF_TEXT
		 || format == CF_OEMTEXT) {
			if (inData[dataLength - 1] != 0)
				nullTerminationBytes = 1;
		}
		else if (format == CF_UNICODETEXT) {
			if (inData[dataLength - 1] != 0
			 || inData[dataLength - 2] != 0)
				nullTerminationBytes = 2;
		}
		globalMem = GlobalAlloc(GMEM_MOVEABLE, dataLength + nullTerminationBytes);
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
		PBITMAPINFOHEADER pdib = (BITMAPINFOHEADER *)inData; // Paul Atreides??

		// If the data is either CF_DIB or CF_DIBV5 and it is a top-down bitmap
		// (biHeight negative) then turn it into a bottom-up bitmap to suit Windows
		if ((format == CF_DIB || format == CF_DIBV5)
		 && pdib->biHeight < 0) {
			unsigned char *dest = globalBytes;
			long scanLineLength = pdib->biWidth * pdib->biBitCount / 8;
			char *source, *start;
			assert(pdib->biSizeImage + sizeof(*pdib) < dataLength);
			pdib->biHeight = - pdib->biHeight; // temporary!!
			memcpy(dest, inData, dataLength - pdib->biSizeImage);
			pdib->biHeight = - pdib->biHeight; // undo the damage
			dest += dataLength - pdib->biSizeImage;
			start = inData + dataLength - pdib->biSizeImage;
			source = inData + dataLength - scanLineLength;
			while (source > start) {
				memcpy(dest, source, scanLineLength);
				dest += scanLineLength;
				source -= scanLineLength;
			}
		}
		else {
			memcpy(globalBytes, inData, dataLength);
			if (nullTerminationBytes) {
				((char *)globalBytes)[dataLength] = 0;
				if (nullTerminationBytes > 1)
					((char *)globalBytes)[dataLength + 1] = 0;
			}
		}
	}
	GlobalUnlock(globalMem);
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

sqInt
sqPasteboardCopyItemFlavorDataformat(CLIPBOARDTYPE inPasteboard, sqInt format)
{
	sqInt outData = 0;
	if (!OpenClipboard(myWindow())) {
		interpreterProxy->primitiveFailFor(PrimErrOperationFailed);
		return 0;
	}
	HANDLE data = GetClipboardData((UINT)(format == CF_UTF8TEXT
											? CF_UNICODETEXT
											: format));
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
		int numWchars;
		if (!data
		 || !(dataBytes = GlobalLock(data))) {
			CloseClipboard();
			interpreterProxy->primitiveFailFor(PrimErrNotFound);
			return 0;
		}
		SIZE_T dataSize = GlobalSize(data);
		// Text formats are null-terminated, which isn't useful for Smalltalk
		if (format == CF_TEXT
		 || format == CF_OEMTEXT) {
			if (dataSize > 0
			 && *((char *)dataBytes + dataSize - 1) == 0)
				dataSize -= 1;
		}
		else if (format == CF_UNICODETEXT
			  || format == CF_UTF8TEXT) {
			if (dataSize > 1
			 && *((unsigned short *)dataBytes + (dataSize/2) - 1) == 0)
				dataSize -= 2;
		}
		if (format == CF_UTF8TEXT) {
			dataSize = WideCharToMultiByte(CP_UTF8,
											0,
											(LPCWCH)dataBytes,
											numWchars = dataSize / 2,
											0,
											0,
											0,
											0);
			if (dataSize < 0) {
				GlobalUnlock(data);
				CloseClipboard();
				interpreterProxy->primitiveFailForwithSecondary
									(PrimErrOSError,GetLastError());
				return 0;
			}
		}
		outData = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), dataSize);
		if (outData) {
			PBITMAPINFOHEADER pdib = (BITMAPINFOHEADER *)dataBytes; // Paul Atreides??

			// If the data is either CF_DIB or CF_DIBV5 and it is a bottom-up bitmap
			// (biHeight not negative) then turn it into a top-down bitmap to suit Squeak
			if ((format == CF_DIB || format == CF_DIBV5)
			 && pdib->biHeight > 0) {
				unsigned char *dest = interpreterProxy->firstIndexableField(outData);
				long scanLineLength = pdib->biWidth * pdib->biBitCount / 8;
				unsigned char *source, *start;
				assert(pdib->biSizeImage + sizeof(*pdib) < dataSize);
				pdib->biHeight = - pdib->biHeight;
				memcpy(dest, dataBytes, dataSize - pdib->biSizeImage);
				dest += dataSize - pdib->biSizeImage;
				start = dataBytes + dataSize - pdib->biSizeImage;
				source = dataBytes + dataSize - scanLineLength;
				while (source > start) {
					memcpy(dest, source, scanLineLength);
					dest += scanLineLength;
					source -= scanLineLength;
				}
			}
			else if (format == CF_UTF8TEXT) {
				(void)WideCharToMultiByte(CP_UTF8,
											0,
											(LPCWCH)dataBytes,
											numWchars,
											interpreterProxy->firstIndexableField(outData),
											dataSize,
											0,
											0);
			}
			else
				memcpy(interpreterProxy->firstIndexableField(outData),
					   dataBytes,
					   dataSize);
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

sqInt
sqPasteboardhasDataInFormatformatLength(CLIPBOARDTYPE inPasteboard, char *format, sqInt formatLength)
{
	interpreterProxy->primitiveFailFor(PrimErrUnsupported);
	return interpreterProxy->nilObject();
}

sqInt
sqPasteboardhasDataInFormat(CLIPBOARDTYPE inPasteboard, sqInt format)
{
	return IsClipboardFormatAvailable(format);
}
