/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@sumeru.stanford.edu & http://sumeru.stanford.edu/tim              */
/*  Known to work on RiscOS 3.7 for StrongARM RPCs, other machines        */
/*  not yet tested.                                                       */
/*                       sqRPCClipb.c                                     */
/* attempt to hook up to RiscOS clipboard stuff                           */
/**************************************************************************/

/* To recompile this reliably you will need    */           
/* Jonathon Coxhead's OSLib,                   */
/* AcornC_C++, the Acorn sockets libs          */
/* and a little luck                           */
#include "oslib/os.h"
#include "oslib/osbyte.h"
#include "oslib/osfscontrol.h"
#include "oslib/wimp.h"
#include "oslib/wimpspriteop.h"
#include "oslib/colourtrans.h"
#include "sq.h"
#include "sqArguments.h"
#include <kernel.h>

// CBDEBUG is for printfs related to the clipboard stuff
#define CBDEBUG 0
extern wimp_t			Task_Handle;
extern wimp_w	sqWindowHandle;
int						sqHasInputFocus = false;
int						sqHasClipboard = false;

void			claimCaret(wimp_pointer * wblock);

void ClaimEntity( int flags) {
	wimp_message wmessage;
// broadcast the Message_ClaimEntity using the flags value to decide whether it is a claim of the caret or the clipboard or both
//   Message_ClaimEntity (15)<BR>
//     0 message size (24)<BR>
//     4 task handle of task making the claim
//     8 message id<BR>
//    12 your_ref (0)<BR>
//    16 Message_ClaimEntity<BR>
//    20 flags:<BR>
// <PRE>
//         bits 0 and 1 set => caret or selection being claimed
//         bit 2 set => clipboard being claimed
//         all other bits reserved (must be 0)
// </PRE>
// 
// <p>
// This message should be broadcast to all tasks as the caret / selection or
// clipboard are claimed.
// When claiming the input focus or clipboard, a task should check to see if it
// already owns that entity, and if so, there is no need to issue the broadcast.
// It should then take care of updating the caret / selection / clipboard to the
// new value (updating the display in the case of the selection).

	wmessage.size = 24;
	wmessage.sender = Task_Handle;
	wmessage.my_ref = (int)Task_Handle; // some better message id ??
	wmessage.your_ref = 0;
	wmessage.action = message_CLAIM_ENTITY;
	wmessage.data.claim_entity.flags = (wimp_claim_flags)flags;
	xwimp_send_message(wimp_USER_MESSAGE, &wmessage, wimp_BROADCAST);
	if(CBDEBUG) {
		printf("ClaimEntity sent message with flags %x\n", flags);
		if (sqHasInputFocus) printf("has focus ");
		if (sqHasClipboard) printf("has clipboard\n");
	}
	
}

void claimCaret(wimp_pointer * wblock) {
#define flagsForClaimingInputFocus 0x03
// claim the input focus if I dont already have it
	if (!sqHasInputFocus) {
		ClaimEntity( flagsForClaimingInputFocus);
		sqHasInputFocus = true;
	}

// When the user positions the caret or makes a selection, the application
// should claim ownership of the input focus by broadcasting this message with
// bits 0 and 1 set. When positioning the caret, the application can choose
// whether to use the Wimp's caret or draw its own representation of the caret
// more appropriate to the type of data being edited. When making a selection,
// the application must hide the caret; it should do this by setting the Wimp's
// caret to the window containing the selection, but invisible. This is
// necessary to direct keystroke events to this window.
}

void claimClipboard(void) {
#define flagsForClaimingClipboard 0x04
// claim the clipboard if I dont already have it
	if (!sqHasClipboard ) {
		ClaimEntity( flagsForClaimingClipboard);
		sqHasClipboard = true;
	}
// When the user performs a Cut or Copy operation, the application should claim
// ownership of the clipboard by broadcasting this message with bit 2 set.

}

void receivedClaimEntity(wimp_message * wblock) {
// When a task receives this message with bits 0 or 1 set, it should check to
// see if any of its windows currently own the input focus. If so, it should
// update its flag to indicate that it no longer has the focus, and remove any
// representation of the caret which it has drawn (unless it uses the Wimp
// caret, which will be undrawn automatically.) It may optionally alter the
// appearance of its window to emphasize the fact that it does not have the
// input focus, for example by shading the selection. A task that receives
// Message_ClaimEntity with only one of bits 0 and 1 set should act as if both
// bits were set.

// When a task receives this message with bit 2 set it should set a flag to
// indicate that the clipboard is held by another application and deallocate the
// memory being used to store the clipboard contents.
	if(CBDEBUG) {
		printf("receivedClaimEntity with flags %x\n", wblock->data.claim_entity.flags);
		if (sqHasInputFocus) printf("has focus ");
		if (sqHasClipboard) printf("has clipboard\n");
	}

	if ( (wblock->data.claim_entity.flags & flagsForClaimingInputFocus)  > 0 ) {
		sqHasInputFocus = false;
	}
	if ( wblock->data.claim_entity.flags == flagsForClaimingClipboard) {
		sqHasClipboard = false;
	}
	if(CBDEBUG) {
		printf("post claim entity sq now ");
		if (sqHasInputFocus) printf("has focus ");
		if (sqHasClipboard) printf("has clipboard\n");
	}

}

void fetchClipboard(void) {
	// fetch the clipboard from the current owner
	// send a data request, put the returned clipboard text into the buffer etc.
	if(CBDEBUG) {
		printf("fetchClipboard ");
		if (sqHasInputFocus) printf("has focus ");
		if (sqHasClipboard) printf("has clipboard\n");
	}
	// we can't fetch the outside clipboard yet, so fake it
	sqHasClipboard = true;
	clipboardSize();
}
 
void sendDataRequest(void) {
//   Paste related fetching of clipboard text
// 
// <p>
// The application should first check to see if it owns the clipboard, and use
// the data directly if so. If is does not own it, it should broadcast the
// following message:
// 
// <p>
//   Message_DataRequest (16)<BR>
//     0 message size<BR>
//     4 task handle of task requesting data
//     8 message id<BR>
//    12 your_ref (0)<BR>
//    16 Message_DataRequest<BR>
//    20 window handle<BR>
//    24 internal handle to indicate destination of data
//    28 x<BR>
//    32 y<BR>
//    36 flags:<BR>
// <PRE>
//         bit 2 set => send data from clipboard (must be 1)
//         all other bits reserved (must be 0)
// </PRE>
//    40 list of filetypes in order of preference,
// <PRE>
//       terminated by -1
// </PRE>
// 
// <p>
// The sender must set flags bit 2, and the receiver must check this bit, and
// ignore the message if it is not set. All other flags bits must be cleared by
// the sender and ignored by the receiver.

	wimp_message wmessage;
	if(CBDEBUG) {
		printf("sendDataRequest  ");
		if (sqHasInputFocus) printf("has focus ");
		if (sqHasClipboard) printf("has clipboard\n");
	}

	wmessage.size = 0;
	wmessage.sender = Task_Handle;
	wmessage.my_ref = (int)Task_Handle; // some better message id ??
	wmessage.your_ref = 0;
	wmessage.action = message_DATA_REQUEST;
	wmessage.data.data_request.w = sqWindowHandle;
	wmessage.data.data_request.i = wimp_ICON_WINDOW;
	wmessage.data.data_request.pos.x = 0;
	wmessage.data.data_request.pos.y = 0;
	wmessage.data.data_request.flags = 0x04;
	// fill in filetypes somehow
	wmessage.data.data_request.file_types[0] = 0xFFF;  //TEXT
	wmessage.data.data_request.file_types[1] = 0xFFD;   // DATA
	wmessage.data.data_request.file_types[2] = -1;
	xwimp_send_message(wimp_USER_MESSAGE, &wmessage, wimp_BROADCAST);

}

void receivedDataRequest(wimp_message * wmessage) {
	if ( sqHasClipboard ) {
		// somebody requested data & I have the clipboard
// If an application receiving this message owns the clipboard, it should choose
// the earliest filetype in the list that it can provide, and if none are
// possible it should provide the data its original (native) format. Note that
// the list can be null, to indicate that the native data should be sent.
//		check the filetype list. My native format is text for this purpose
	if(CBDEBUG) {
		printf("receivedDataRequest ");
		if (sqHasInputFocus) printf("has focus ");
		if (sqHasClipboard) printf("has clipboard\n");
	}

		// loop until filetype is -1 or we find TEXT
		// (- types are 'bits' which is unsigned int) in a list up to 54 words long.
		// since I will only handle text, and I am using it as native format, I can skip
		// this test. It would always suceed!


// It
// should reply using the normal Message_DataSave protocol. Bytes 20 through 35
// of the DataSave block should be copied directly from the corresponding bytes
// of the Message_DataRequest block, whilst the estimated size field, filetype
// and filename must be filled in.
		//make up a datasave block
		//send the data save message
		//sendDataSave(dsblock);
// <p>
// If your application needs to find out whether there is data available to
// paste, but does not actually want to receive the data, you should broadcast
// a Message_DataRequest as described above. If no task replies (i.e. you get
// the message back) then there is no clipboard data available. If a
// Message_DataSave is received, then you should ignore it (fail to reply),
// which will cause the operation to be silently aborted by the other task. You
// can then use the filetype field of the Message_DataSave to determine whether
// the data being offered by the other task is in a suitable format for you to
// receive.
	}
	// what to do if I don't have the clipboard? No reply?
}

void receivedDataSave(wimp_message * wblock) {
// 
// <p>
// When the application that initiated the Paste receives the Message_DataSave,
// it should check the filetype to ensure that it knows how to deal with it - it
// may be the clipboard owner's native format. If it cannot, it may back out of
// the transaction by ignoring the message. Otherwise, it should continue with
// the DataSave protocol as detailed in the Programmer's Reference Manual.
		// check the filetype - only deal with text for now. What others might be useful ?
		// Do the data save protocols to get the clipboard text
//
	if(CBDEBUG) {
		printf("receivedDataSave ");
		if (sqHasInputFocus) printf("has focus ");
		if (sqHasClipboard) printf("has clipboard\n");
	}
 
}

