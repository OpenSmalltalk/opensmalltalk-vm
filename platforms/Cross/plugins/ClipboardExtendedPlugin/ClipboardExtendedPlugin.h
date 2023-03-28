#ifndef _SQ_CLIPBOARD_PLUGIN_H_
#define _SQ_CLIPBOARD_PLUGIN_H_

// Platform-specific interface for the ClipboardExtendedPlugin
// If a more specific type than void * is required, define CLIPBOARDTYPE to that
// type before including this file in your platform support code.

#if !defined(CLIPBOARDTYPE)
#	define CLIPBOARDTYPE void *
#endif

void sqPasteboardClear(CLIPBOARDTYPE inPasteboard);
sqInt sqPasteboardGetItemCount(CLIPBOARDTYPE inPasteboard);
sqInt sqPasteboardCopyItemFlavorsitemNumber(CLIPBOARDTYPE inPasteboard, sqInt formatNumber);
void *sqCreateClipboard(void);
void sqPasteboardPutItemFlavordatalengthformatTypeformatLength(CLIPBOARDTYPE inPasteboard, char *inData, sqInt dataLength, char *format, sqInt formatLength);
void sqPasteboardPutItemFlavordatalengthformatType(CLIPBOARDTYPE inPasteboard, char *inData, sqInt dataLength, sqInt format);
sqInt sqPasteboardCopyItemFlavorDataformatformatLength(CLIPBOARDTYPE inPasteboard, char *format, sqInt formatLength);
sqInt sqPasteboardCopyItemFlavorDataformat(CLIPBOARDTYPE inPasteboard, sqInt format);
sqInt sqPasteboardhasDataInFormatformatLength(CLIPBOARDTYPE inPasteboard, char *format, sqInt formatLength);
sqInt sqPasteboardhasDataInFormat(CLIPBOARDTYPE inPasteboard, sqInt format);

#endif // _SQ_CLIPBOARD_PLUGIN_H_
