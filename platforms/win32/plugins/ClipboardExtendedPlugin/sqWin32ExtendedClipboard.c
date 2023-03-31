/*
 *  sqWin32ExtendedClipboard.m
 *
 *  This file is part of Squeak
 *
 */

#include <Windows.h>
#include <urlmon.h>
#include "sqWin32.h"
#include "sqVirtualMachine.h"
#include "ClipboardExtendedPlugin.h"
#include "sqAssert.h"

extern struct VirtualMachine *interpreterProxy;

// As a convenience, because UTF16/CF_UNICODETEXT is so tricky, handle
// CF_PRIVATELAST as a special code implying put/get UTF-8 converted
// to/from UTF16
#define CF_UTF8TEXT CF_PRIVATELAST

// Manage registered clipboard types with dynamic format ids
#define SQCF_HTML 0x10001
#define SQCF_RTF  0x10002
#define SQCF_PNG  0x10003
#define SQCF_GIF  0x10004
#define SQCF_MIME_TEXT     0x20001
#define SQCF_MIME_TEXTUTF8 0x20002
#define SQCF_MIME_RICHTEXT 0x20003
#define SQCF_MIME_RTF      0x20004
#define SQCF_MIME_WAV      0x20005
#define SQCF_MIME_GIF      0x20006
#define SQCF_MIME_JPEG     0x20007
#define SQCF_MIME_TIFF     0x20008
#define SQCF_MIME_PNG      0x20009
#define SQCF_MIME_SVG      0x2000A
#define SQCF_MIME_BMP      0x2000B
#define SQCF_MIME_MPEG     0x2000C
#define SQCF_MIME_RAW      0x2000D
#define SQCF_MIME_PDF      0x2000E
#define SQCF_MIME_XHTML    0x2000F
#define SQCF_MIME_HTML     0x20010
#define SQCF_MIME_XML      0x20011

int cfHtml = 0, cfRtf = 0, cfPng = 0, cfGif = 0,
    cfMimeText = 0, cfMimeTextUtf8 = 0,
    cfMimeRichText = 0, cfMimeRtf = 0, cfMimeWav = 0, cfMimeGif = 0,
    cfMimeJpeg = 0, cfMimeTiff = 0, cfMimePng = 0, cfMimeSvg = 0,
    cfMimeBmp = 0, cfMimeMpeg = 0, cfMimeRaw = 0, cfMimePdf = 0,
    cfMimeXhtml = 0, cfMimeHtml = 0, cfMimeXml = 0;


#ifdef SQUEAK_BUILTIN_PLUGIN
extern void *ioGetWindowHandle(void);
# define myWindow() ioGetWindowHandle()
#else
__declspec(dllimport) void *getSTWindowHandle(void);
# define myWindow() getSTWindowHandle()
#endif

void
sqPasteboardClear(CLIPBOARDTYPE inPasteboard)
{
	if (!OpenClipboard(myWindow())) {
		interpreterProxy->primitiveFailFor(PrimErrOperationFailed);
		return;
	}
	if (!EmptyClipboard()) {
		CloseClipboard();
		interpreterProxy->primitiveFailFor(PrimErrOperationFailed);
		return;		
	}
	CloseClipboard();
}

sqInt
sqPasteboardGetItemCount(CLIPBOARDTYPE inPasteboard)
{
	UINT count = 0;

	if (!OpenClipboard(myWindow())) {
		interpreterProxy->primitiveFailFor(PrimErrOperationFailed);
		return 0;
	}
	count = CountClipboardFormats();
	CloseClipboard();
	return count;
}

sqInt
sqPasteboardCopyItemFlavorsitemNumber(CLIPBOARDTYPE inPasteboard, sqInt formatNumber)
{
	UINT count = 0, format = 0, lastFormat = 0;

	if (formatNumber < 0
	 || !OpenClipboard(myWindow())) {
		interpreterProxy->primitiveFailFor(PrimErrOperationFailed);
		return 0;
	}
	while ((format = EnumClipboardFormats(lastFormat))
		&& ++count < formatNumber)
		lastFormat = format;
	CloseClipboard();
	if (format == CF_UNICODETEXT) {
		format = CF_UTF8TEXT;
	}
	format = platformFormatToSqFormat(format);
	return format
				? interpreterProxy->integerObjectOf(format)
				: interpreterProxy->nilObject();
}

void *
sqCreateClipboard(void)
{
	if (!cfHtml) {
		// Compatibility with common Windows apps (MS Office, Chrome...)
		cfHtml = RegisterClipboardFormat(TEXT("HTML Format"));
		cfRtf = RegisterClipboardFormat(TEXT("Rich Text Format"));
		cfPng = RegisterClipboardFormat(TEXT("PNG")); 
		cfGif = RegisterClipboardFormat(TEXT("GIF")); 
		
		// Compatibility with generic MIME types
		cfMimeText = RegisterClipboardFormat(CFSTR_MIME_TEXT);
		cfMimeTextUtf8 = RegisterClipboardFormat(TEXT("text/plain;charset=utf-8"));
		cfMimeRichText = RegisterClipboardFormat(CFSTR_MIME_RICHTEXT);
		cfMimeRtf = RegisterClipboardFormat(TEXT("application/rtf"));
		cfMimeWav = RegisterClipboardFormat(CFSTR_MIME_WAV);
		cfMimeGif = RegisterClipboardFormat(CFSTR_MIME_GIF);
		cfMimeJpeg = RegisterClipboardFormat(CFSTR_MIME_JPEG);
		cfMimeTiff = RegisterClipboardFormat(CFSTR_MIME_TIFF);
		cfMimePng = RegisterClipboardFormat(CFSTR_MIME_PNG);
		cfMimeSvg = RegisterClipboardFormat(CFSTR_MIME_SVG_XML);
		cfMimeBmp = RegisterClipboardFormat(CFSTR_MIME_BMP);
		cfMimeMpeg = RegisterClipboardFormat(CFSTR_MIME_MPEG);
		cfMimeRaw = RegisterClipboardFormat(CFSTR_MIME_RAWDATA);
		cfMimePdf = RegisterClipboardFormat(CFSTR_MIME_PDF);
		cfMimeXhtml = RegisterClipboardFormat(CFSTR_MIME_XHTML);
		cfMimeHtml = RegisterClipboardFormat(CFSTR_MIME_HTML);
		cfMimeXml = RegisterClipboardFormat(CFSTR_MIME_XML);
	}
	return (void *)0xB0A4D;
}

void
sqPasteboardPutItemFlavordatalengthformatTypeformatLength(CLIPBOARDTYPE inPasteboard, char *inData, sqInt dataLength, char *format, sqInt formatLength)
{
	interpreterProxy->primitiveFailFor(PrimErrUnsupported);
}

void
sqPasteboardPutItemFlavordatalengthformatType(CLIPBOARDTYPE inPasteboard, char *inData, sqInt dataLength, sqInt format)
{
	HANDLE globalMem, okSet;
	int nullTerminationBytes = 0, okClose;

	if (dataLength <= 0) {
		interpreterProxy->primitiveFailFor(PrimErrBadArgument);
		return;
	}
	if (!OpenClipboard(myWindow())) {
		interpreterProxy->primitiveFailFor(PrimErrOperationFailed);
		return;
	}
	if (format == CF_BITMAP) {
		CloseClipboard();
		interpreterProxy->primitiveFailFor(PrimErrUnsupported);
		return;
	}
	format = sqFormatToPlatformFormat(format);
	// As a convenience, because UTF16/CF_UNICODETEXT is so tricky, handle
	// CF_UTF8TEXT as a special code implying put UTF-8 converted to UTF16
	if (format == CF_UTF8TEXT) {
		int numWchars = MultiByteToWideChar(CP_UTF8, 0, inData, dataLength, 0, 0);
		if (numWchars < 0) {
			CloseClipboard();
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
	okSet = SetClipboardData((UINT)format, globalMem);
	okClose = CloseClipboard();
	if (!okSet || !okClose) {
		GlobalFree(globalMem);
		interpreterProxy->primitiveFailFor(PrimErrOperationFailed);
	}
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
	format = sqFormatToPlatformFormat(format);
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
				long scanLineLength = ((pdib->biWidth * pdib->biBitCount + 31) / 32) * 4;
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
	if (format == CF_UTF8TEXT) {
		format = CF_UNICODETEXT;
	}
	format = sqFormatToPlatformFormat(format);
	return IsClipboardFormatAvailable(format);
}

int
sqFormatToPlatformFormat(int sqFormat)
{
	if (sqFormat == SQCF_HTML) return cfHtml;
	if (sqFormat == SQCF_RTF) return cfRtf;
	if (sqFormat == SQCF_PNG) return cfPng;
	if (sqFormat == SQCF_GIF) return cfGif;
	if (sqFormat == SQCF_MIME_TEXT) return cfMimeText;
	if (sqFormat == SQCF_MIME_TEXTUTF8) return cfMimeTextUtf8;
	if (sqFormat == SQCF_MIME_RICHTEXT) return cfMimeRichText;
	if (sqFormat == SQCF_MIME_RTF) return cfMimeRtf;
	if (sqFormat == SQCF_MIME_WAV) return cfMimeWav;
	if (sqFormat == SQCF_MIME_GIF) return cfMimeGif;
	if (sqFormat == SQCF_MIME_JPEG) return cfMimeJpeg;
	if (sqFormat == SQCF_MIME_TIFF) return cfMimeTiff;
	if (sqFormat == SQCF_MIME_PNG) return cfMimePng;
	if (sqFormat == SQCF_MIME_SVG) return cfMimeSvg;
	if (sqFormat == SQCF_MIME_BMP) return cfMimeBmp;
	if (sqFormat == SQCF_MIME_MPEG) return cfMimeMpeg;
	if (sqFormat == SQCF_MIME_RAW) return cfMimeRaw;
	if (sqFormat == SQCF_MIME_PDF) return cfMimePdf;
	if (sqFormat == SQCF_MIME_XHTML) return cfMimeXhtml;
	if (sqFormat == SQCF_MIME_HTML) return cfMimeHtml;
	if (sqFormat == SQCF_MIME_XML) return cfMimeXml;
	return sqFormat; // default is no mapping
}

int
platformFormatToSqFormat(int platformFormat)
{
	if (platformFormat == cfHtml) return SQCF_HTML;
	if (platformFormat == cfRtf) return SQCF_RTF;
	if (platformFormat == cfPng) return SQCF_PNG;
	if (platformFormat == cfGif) return SQCF_GIF;
	if (platformFormat == cfMimeText) return SQCF_MIME_TEXT;
	if (platformFormat == cfMimeTextUtf8) return SQCF_MIME_TEXTUTF8;
	if (platformFormat == cfMimeRichText) return SQCF_MIME_RICHTEXT;
	if (platformFormat == cfMimeRtf) return SQCF_MIME_RTF;
	if (platformFormat == cfMimeWav) return SQCF_MIME_WAV;
	if (platformFormat == cfMimeGif) return SQCF_MIME_GIF;
	if (platformFormat == cfMimeJpeg) return SQCF_MIME_JPEG;
	if (platformFormat == cfMimeTiff) return SQCF_MIME_TIFF;
	if (platformFormat == cfMimePng) return SQCF_MIME_PNG;
	if (platformFormat == cfMimeSvg) return SQCF_MIME_SVG;
	if (platformFormat == cfMimeBmp) return SQCF_MIME_BMP;
	if (platformFormat == cfMimeMpeg) return SQCF_MIME_MPEG;
	if (platformFormat == cfMimeRaw) return SQCF_MIME_RAW;
	if (platformFormat == cfMimePdf) return SQCF_MIME_PDF;
	if (platformFormat == cfMimeXhtml) return SQCF_MIME_XHTML;
	if (platformFormat == cfMimeHtml) return SQCF_MIME_HTML;
	if (platformFormat == cfMimeXml) return SQCF_MIME_XML;
	return platformFormat; // default is no mapping
}