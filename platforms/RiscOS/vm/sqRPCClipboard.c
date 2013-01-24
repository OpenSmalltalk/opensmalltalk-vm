//  A Squeak VM for RiscOS machines
//  Suited to RISC OS > 4, preferably > 5
// See www.squeak.org for much more information
//
// tim Rowledge tim@rowledge.org
//
// License: MIT License -
// Copyright (C) <2013> <tim rowledge>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// This is sqRPCClipboard.c
// It connects the Squeakclipboard to the RISC OS one

//#define DEBUG
#include "oslib/os.h"
#include "oslib/osbyte.h"
#include "oslib/osfscontrol.h"
#include "oslib/osfile.h"
#include "oslib/wimp.h"
#include "oslib/wimpspriteop.h"
#include "oslib/colourtrans.h"
#include "sq.h"
#include "sqArguments.h"
#include <kernel.h>

int		sqHasInputFocus = false;
int		sqHasClipboard = false;
char *		clipboardBuffer = NULL;
int		clipboardByteSize = 0;
int		clipboardMessageID = 0;

int allocClipboard(size_t size);

/* caret (input focus) and clipboard claiming functions */

void ClaimEntity( int flags) {
	wimp_message wmessage;
/* broadcast the Message_ClaimEntity using the flags value to decide whether
 * it is a claim of the caret or the clipboard (or both?)
 * When claiming the input focus or clipboard, a task should check to see if
 * it already owns that entity, and if so, there is no need to issue the
 * broadcast.
 * It should then take care of updating the caret / selection / clipboard
 * to the new value (updating the display in the case of the selection).
 */

	wmessage.size = 24;
	wmessage.sender = (wimp_t)NULL;
	wmessage.my_ref = 0;
	wmessage.your_ref = 0;
	wmessage.action = message_CLAIM_ENTITY;
	wmessage.data.claim_entity.flags = (wimp_claim_flags)flags;
	xwimp_send_message(wimp_USER_MESSAGE, &wmessage, wimp_BROADCAST);

}

void claimCaret(wimp_pointer * wblock) {
/* claim the input focus if I dont already have it */
	if (!sqHasInputFocus) {
		ClaimEntity( wimp_CLAIM_CARET_OR_SELECTION);
		sqHasInputFocus = true;
	}

}

void claimClipboard(void) {
/* claim the clipboard if I dont already have it */
	if (!sqHasClipboard ) {
		ClaimEntity( wimp_CLAIM_CLIPBOARD);
		sqHasClipboard = true;
	}
}

void receivedClaimEntity(wimp_message * wblock) {
/* When a task receives this message with bits 0 or 1 set, it should check
 *to see if any of its windows currently own the input focus. If so, it
 * should update its flag to indicate that it no longer has the focus, and
 * remove any representation of the caret which it has drawn (unless it uses
 * the Wimp caret, which will be undrawn automatically.) It may optionally
 * alter the appearance of its window to emphasize the fact that it does not
 * have the input focus, for example by shading the selection. A task that
 * receives Message_ClaimEntity with only one of bits 0 and 1 set should act
 * as if both bits were set.
 *
 * When a task receives this message with bit 2 set it should set a flag to
 * indicate that the clipboard is held by another application and deallocate
 * the memory being used to store the clipboard contents.
 */
	if ( (wblock->data.claim_entity.flags
		& wimp_CLAIM_CARET_OR_SELECTION) > 0 ) {
		sqHasInputFocus = false;
	}
	if ( wblock->data.claim_entity.flags == wimp_CLAIM_CLIPBOARD) {
		sqHasClipboard = false;
		allocClipboard(1);
	}
}

/* clipboard buffer management  */
int allocClipboard(size_t size) {
void * ptr;
	ptr = realloc(clipboardBuffer, size);
	if( ptr == NULL) {
		/* failed to reallocate but old buffer is stil in place
		 * so remember to clear it
		 */
		memset(clipboardBuffer,0, (size_t)clipboardByteSize);
		return false;
	}
	clipboardBuffer = ptr;
	clipboardByteSize = (int)size;
	memset(clipboardBuffer,0, (size_t)clipboardByteSize);
	return true;
}

void freeClipboard(void) {
	free(clipboardBuffer);
	clipboardBuffer = NULL;
	clipboardByteSize = 0;
}

/* clipboard fetching - we don't own the clipboard and do want the contents */

void sendDataRequest(wimp_message* wmessage) {
/* We want to fetch the clipboard contents from some other application
 * Broadcast the message_DATA_REQUEST message
 */
	wmessage->size = 52;
	wmessage->sender = (wimp_t)NULL;
	wmessage->my_ref = 0;
	wmessage->your_ref = 0;
	wmessage->action = message_DATA_REQUEST;
	wmessage->data.data_request.w = 0 /* sqWindowHandle */;
	wmessage->data.data_request.i = wimp_ICON_WINDOW;
	wmessage->data.data_request.pos.x = 0;
	wmessage->data.data_request.pos.y = 0;
	wmessage->data.data_request.flags = wimp_DATA_REQUEST_CLIPBOARD;
	wmessage->data.data_request.file_types[0] = 0xFFF; //TEXT
	wmessage->data.data_request.file_types[1] = 0xFFD; // DATA
	wmessage->data.data_request.file_types[2] = -1;
	xwimp_send_message(wimp_USER_MESSAGE, wmessage, wimp_BROADCAST);
	clipboardMessageID = wmessage->my_ref;
}


int receivedClipboardDataSave(wimp_message * wmessage) {
/* When the application that initiated the Paste receives the
 * Message_DataSave, it should check the filetype to ensure that it
 * knows how to deal with it - it may be the clipboard owner's native
 * format. If it cannot, it may back out of the transaction by ignoring
 * the message. Otherwise, it should continue with the DataSave
 * protocol as detailed in the Programmer's Reference Manual.
 */
	if(wmessage->data.data_xfer.file_type != (bits)0xfff) {
		/* if not text type, empty clipboard buffer & return */
		memset(clipboardBuffer,0, (size_t)clipboardByteSize);
		return false;
	}
	/* We modify the received block and return to sender */
	wmessage->size = 60;
	wmessage->action = message_DATA_SAVE_ACK;
	wmessage->your_ref = wmessage->my_ref;
	wmessage->data.data_xfer.est_size = -1;
	wmessage->data.data_xfer.file_type = (bits)0xfff;
	strcpy(&(wmessage->data.data_xfer.file_name[0]), "<Wimp$Scrap>");
	xwimp_send_message(wimp_USER_MESSAGE, wmessage, wmessage->sender);
	return true;
}
void receivedClipboardDataLoad(wimp_message * wmessage) {
/* we got a dataload message, so grab the <Wimp$Scrap> file, then delete it
 * and return a dataloadack to the sender
 */
bits load_addr, exec_addr, file_type;
fileswitch_attr attr;
fileswitch_object_type obj_type;
int length;
	/* find the file size */
	xosfile_read_stamped_no_path(&(wmessage->data.data_xfer.file_name[0]),
		&obj_type, &load_addr, &exec_addr, &length, &attr, &file_type);
	/* if the obj_type is not-found, clear the buffer and return */
	if(obj_type == fileswitch_NOT_FOUND) {
		allocClipboard(1);
		return;
	}
	/* make sure we have enough buffer space for it
	 * fail if not */
	if(!allocClipboard(length+1))
		return;
	/* now load the file */
	xosfile_load_stamped_no_path(&(wmessage->data.data_xfer.file_name[0]),		(byte*)clipboardBuffer, &obj_type,
		&load_addr, &exec_addr, &length, &attr);
	/* delete the file */
	xosfscontrol_wipe(&(wmessage->data.data_xfer.file_name[0]), osfscontrol_WIPE_FORCE, 0,0,0,0);
	/* We modify the received block and return it to sender */
	wmessage->action = message_DATA_LOAD_ACK;
	wmessage->your_ref = wmessage->my_ref;
	xwimp_send_message(wimp_USER_MESSAGE, wmessage, wmessage->sender);
}

int pollForClipboardMessage(bits messageAction, wimp_block* wblock) {
/* poll for a message relating to the clipboard protocols (either datasave or
 * dataload usually) and return true if one is found or false if we either get
 * a null or go round more than a few times (avoid loop-of-death)
 */
wimp_event_no reason;
int pollword, i;
extern void WindowOpen(wimp_open* wblock);
extern void WindowClose(wimp_close* wblock);
extern void PointerLeaveWindow(wimp_block* wblock);
extern void PointerEnterWindow(wimp_block* wblock);
	for(i=0;i<100;i++) {
		xwimp_poll((wimp_MASK_POLLWORD| wimp_MASK_GAIN | wimp_MASK_LOSE
| wimp_SAVE_FP | wimp_QUEUE_REDRAW | wimp_QUEUE_MOUSE | wimp_QUEUE_KEY), wblock, &pollword, &reason);
		switch(reason) {
			case wimp_NULL_REASON_CODE:
				return false; break;
			case wimp_OPEN_WINDOW_REQUEST	:
				WindowOpen(&wblock->open); break;
			case wimp_CLOSE_WINDOW_REQUEST	:
				WindowClose(&wblock->close); break;
			case wimp_POINTER_LEAVING_WINDOW :
				PointerLeaveWindow(wblock); break;
			case wimp_POINTER_ENTERING_WINDOW:
				PointerEnterWindow(wblock); break;
			case wimp_USER_MESSAGE			:
			case wimp_USER_MESSAGE_RECORDED		:
				if( wblock->message.action == messageAction)
					return true; break;
		}
	}
	return false;
}

void fetchClipboard(void) {
/*  fetch the clipboard from the current owner */
wimp_block wblock;
	/* ask for the clipboard contents */
	sendDataRequest(&wblock.message);
	if( !pollForClipboardMessage(message_DATA_SAVE, &wblock))
		/* didn't get any reply, so return empty */
		return ;
	if( !receivedClipboardDataSave(&wblock.message))
		return; /* no acceptable filetype, so give up */
	if( !pollForClipboardMessage(message_DATA_LOAD, &wblock))
		/* didn't get any reply, so return empty */
		return;
	receivedClipboardDataLoad(&wblock.message);
	return;
}

/* clipboard serving - what to do when we own the clipboard and somebody
 * else wants the contents
 */
void receivedDataRequest(wimp_message * wmessage) {
	if ( !sqHasClipboard ) return;

	/* somebody requested data & I have the clipboard
	* If an application receiving this message owns the clipboard,
	* it should choose the earliest filetype in the list that it
	* can provide, and if none are possible it should provide the
	* data its original (native) format. Note that the list can be
	* null, to indicate that the native data should be sent.
	*/
	/* reply using the normal Message_DataSave protocol.
	 * Bytes 20 through 35 of the DataSave block should be copied directly
	 * from the corresponding bytes of the Message_DataRequest block,
	 * whilst the estimated size field, filetype and filename must be
	 * filled in.
	 */

	/* We modify the received block and return to sender */
	wmessage->size = 52;
	wmessage->action = message_DATA_SAVE;
	wmessage->your_ref = wmessage->my_ref;
	wmessage->data.data_xfer.est_size = strlen(clipboardBuffer);
	wmessage->data.data_xfer.file_type = (bits) 0xfff;
	strcpy(&(wmessage->data.data_xfer.file_name[0]), "SqClip");
	xwimp_send_message(wimp_USER_MESSAGE, wmessage, wmessage->sender);
}


void receivedDataSaveAck(wimp_message * wmessage) {
/* we've been asked to save the clipboard contents to the wimpScrap */
	osfile_save_stamped(&(wmessage->data.data_xfer.file_name[0]),
		(bits)0xfff, (byte const *)clipboardBuffer,
		(byte const *)(clipboardBuffer +
			strlen(clipboardBuffer)));
	/* modify the block to be a data load message and return to sender */
	wmessage->action = message_DATA_LOAD;
	wmessage->your_ref = wmessage->my_ref;
	wmessage->data.data_xfer.est_size = strlen(clipboardBuffer);
	xwimp_send_message(wimp_USER_MESSAGE, wmessage, wmessage->sender);
}

/*** Clipboard Support interface to interp.c ***/

sqInt clipboardSize(void) {
extern int	forceInterruptCheck(void);

/* return the number of characters in the clipboard entry */
	if (!sqHasClipboard) {
		/* if squeak doesn't have the clipboard, we need to
		 * fetch the clipboard contents from the current holder
		 */
		fetchClipboard();
		forceInterruptCheck();
	}
	return strlen(clipboardBuffer);
}

sqInt clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex) {
// paste - clipboardSize() will actually do any fetching
int clipSize, charsToMove, i;
char *srcPtr, *dstPtr, cc;
	clipSize = strlen(clipboardBuffer);
	charsToMove = (count < clipSize) ? count : clipSize;

	srcPtr = (char *) clipboardBuffer;
	dstPtr = (char *) byteArrayIndex + startIndex;
	for (i = 0; i < charsToMove; i++, srcPtr++, dstPtr++) {
		*dstPtr = cc = *srcPtr;
		/* swap CR/LF */
		if( cc == (char)10) *dstPtr = (char)13;
		if( cc == (char)13) *dstPtr = (char)10;
	}

	return charsToMove;
}

sqInt clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex) {
/* copy count bytes, starting from startIndex, from byteArrayIndex to the
 * clipboard. return value not (yet) used but send the number of chars moved
 * the prim code has no way to handle any failure as yet, so do our best
 */
int  charsToMove, i;
char *srcPtr, *dstPtr, cc;

	/* buffer size must be at least 1 more than count to allow for
	 * terminating \0. Realloc if needed and then recheck size
	 */
	allocClipboard(count + 1);
	charsToMove = (count < clipboardByteSize) ? count : clipboardByteSize-1;

	srcPtr = (char *) byteArrayIndex + startIndex;
	dstPtr = (char *) clipboardBuffer;
	for (i = 0; i < charsToMove; i++, srcPtr++, dstPtr++) {
		*dstPtr = cc = *srcPtr;
		/* swap CR/LF */
		if( cc == (char)10) *dstPtr = (char)13;
		if( cc == (char)13) *dstPtr = (char)10;
	}
	*dstPtr = (char)NULL;

	claimClipboard();

	return charsToMove;
}
