/****************************************************************************
*   PROJECT: Mac window, memory, keyboard interface.
*   FILE:    sqMacDragDrop.c
*   CONTENT: 
*
*   AUTHOR:  John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacDragDrop.c 1708 2007-06-10 00:40:04Z johnmci $
*
*   NOTES: See change log below.
*	1/4/2002   JMM Carbon cleanup
*
*****************************************************************************/
/*	Drag and drop support for Squeak 
	John M McIntosh of Corporate Smalltalk Consulting Ltd
	johnmci@smalltalkconsulting.com 
	http://www.smalltalkconsulting.com 
	In Jan of 2001 under contract to Disney
	
	Dragging is only for objects into Squeak, not from Squeak outwards.
		
    V1.0 Jan 24th 2001, JMM
    V3.0.19 Aug 2001, JMM make a proper plugin

Some of this code comes from
	Author:		John Montbriand
				Some techniques borrowed from Pete Gontier's original FinderDragPro.


	Copyright: 	Copyright: � 1999 by Apple Computer, Inc.
				all rights reserved.
	
	Disclaimer:	You may incorporate this sample code into your applications without
				restriction, though the sample code has been provided "AS IS" and the
				responsibility for its operation is 100% yours.  However, what you are
				not permitted to do is to redistribute the source as "DSC Sample Code"
				after having made changes. If you're going to re-distribute the source,
				we require that you make it clear in the source that the code was
				descended from Apple Sample Code, but that you've made changes.
	
	Change History (most recent first):
	9/9/99 by John Montbriand
	
	May 8th,2002,JMM - Bert Freudenberg published some changes to make file opening easier without security
        July 28th, 2003, JMM - fix issue with race on open doc events and squeak VM Thread.
*  3.7.0bx Nov 24th, 2003 JMM gCurrentVMEncoding
	
*/
/*
    need get filetype/creator
    need DropPlugin_shutdownModule & dropShutdown
    
*/

#include "sq.h"

#if TARGET_API_MAC_CARBON
#include <Carbon/Carbon.h>
#else
#include <Drag.h>
#include <MacWindows.h>
#include <Gestalt.h>
#include <Quickdraw.h>
#endif

#include "sqVirtualMachine.h"
#include "sqMacUnixFileInterface.h"	
#include "sqMacUIConstants.h"
#include "DropPlugin.h"

	/* promise flavor types */
	
enum {
	kPromisedFlavor = 'fssP',		/* default promise */
	kPromisedFlavorFindFile = 'rWm1' /* Find File promise -- special case */
};

 struct HFSFlavorSqueak {
  OSType              fileType;               /* file type */
  OSType              fileCreator;            /* file creator */
  UInt16              fdFlags;                /* Finder flags */
  FSRef               theFSRef;               /* file system Ref */
  };
typedef struct HFSFlavorSqueak                HFSFlavorSqueak;

 volatile static Boolean gDragDropThrottleSpinLock = false;	     /* true if waiting for Squeak to process D&D */
 static DragReceiveHandlerUPP gMainReceiveHandler = NULL;   /* receive handler for the main dialog */
 static DragTrackingHandlerUPP gMainTrackingHandler = NULL; /* tracking handler for the main dialog */
 static WindowPtr   gWindowPtr;
 
volatile static UInt16 gNumDropFiles=0;

 static HFSFlavorSqueak *dropFiles;

 static char tempName[DOCUMENT_NAME_SIZE + 1];  

	/* these routines are used both in the receive handler and inside of the
		tracking handler.  The following variables are shared between MyDragTrackingHandler
		and MyDragReceiveHandler.  */
		
 static Boolean gApprovedDrag = false;   /* set to true if the drag is approved */
 static Boolean gInIconBox = false;      /* set true if the drag is inside our drop box */
 
extern struct VirtualMachine *interpreterProxy;
 pascal OSErr MyDragTrackingHandler(DragTrackingMessage message, WindowPtr theWindow, void *refCon, DragReference theDragRef);
 pascal OSErr MyDragReceiveHandler(WindowPtr theWindow, void *refcon, DragReference theDragRef);

// Startup logic

sqInt
dropInit(void)
{
 	void *fn;
    Boolean  installedReceiver=false, installedTracker=false;
    OSErr err;
  
    /* check for the drag manager & translucent feature??? */
    
	if (gMainReceiveHandler != NULL) return 1;
		
	fn = interpreterProxy->ioLoadFunctionFrom("getSTWindow", "");
	if (fn == 0) {
	    goto bail; 
	}
	gWindowPtr = (WindowPtr) ((int (*) ()) fn)();

	gMainTrackingHandler = NewDragTrackingHandlerUPP(MyDragTrackingHandler);
	if (gMainTrackingHandler == NULL) return 0;
	gMainReceiveHandler = NewDragReceiveHandlerUPP(MyDragReceiveHandler);
	if (gMainReceiveHandler == NULL) return 0;

		/* install the drag handlers, don't forget to dispose of them later */
		
	if (!gWindowPtr) 
		goto bail;
		
	err = InstallTrackingHandler(gMainTrackingHandler, gWindowPtr, NULL);
	if (err != noErr) { 
	    err = memFullErr; 
	    goto bail; 
    }
	installedTracker = true;
	err = InstallReceiveHandler(gMainReceiveHandler, gWindowPtr, NULL);
	
	if (err != noErr) { 
	    err = memFullErr; 
	    goto bail; 
	}
	installedReceiver = true;
	return 1;
	
bail: 
    if (installedReceiver)
		RemoveReceiveHandler(gMainReceiveHandler, gWindowPtr);
	if (installedTracker)
		RemoveTrackingHandler(gMainTrackingHandler, gWindowPtr);
	
	gMainTrackingHandler = NULL; 
    gMainReceiveHandler = NULL;
    
	return 0;
}	

// Shutdown logic

sqInt
dropShutdown() {
    if (gMainReceiveHandler != NULL)
		RemoveReceiveHandler(gMainReceiveHandler, gWindowPtr);
	if (gMainTrackingHandler != NULL)
		RemoveTrackingHandler(gMainTrackingHandler, gWindowPtr);
	if (gNumDropFiles != 0 ) {
	    DisposePtr((char *) dropFiles);
	    gNumDropFiles = 0;
	}
	
	gMainTrackingHandler = NULL; 
    gMainReceiveHandler = NULL;
    gDragDropThrottleSpinLock = false;
	return 1;
}

sqInt
sqSecFileAccessCallback(void *function) {
#pragma unused(function)
	return 0;
 }

//Primitive to get file name

char *
dropRequestFileName(sqInt dropIndex) {
    if(dropIndex < 1 || dropIndex > gNumDropFiles) 
        return NULL;
		
	PathToFileViaFSRef(tempName, DOCUMENT_NAME_SIZE, &dropFiles[dropIndex-1].theFSRef,gCurrentVMEncoding);
    if (dropIndex == gNumDropFiles) 
        gDragDropThrottleSpinLock = false;
  return tempName;
}

//Primitive to get file stream handle.

sqInt
dropRequestFileHandle(sqInt dropIndex) {
    sqInt  fileOop;
	void *fn;
    char *dropName = dropRequestFileName(dropIndex);

    if(!dropName)
        return interpreterProxy->nilObject();
 
	fn = interpreterProxy->ioLoadFunctionFrom("fileOpenNamesizewritesecure", "FilePlugin");
	if (fn == 0) {
		/* begin primitiveFail */
        interpreterProxy->success(false);
		return null;
	}
	fileOop = ((sqInt (*) (int, int, int, int)) fn)((int)dropName, strlen(dropName), 0,0);
    
  return fileOop;
}


/* RECEIVING DRAGS ------------------------------------------------ */


/* ApproveDragReference is called by the drag tracking handler to determine
	if the contents of the drag can be handled by our receive handler.

	Note that if a flavor can't be found, it's not really an
	error; it only means the flavor wasn't there and we should
	not accept the drag. Therefore, we translate 'badDragFlavorErr'
	into a 'false' value for '*approved'. */

static pascal OSErr
ApproveDragReference(DragReference theDragRef, Boolean *approved) {

	OSErr err;
	DragAttributes dragAttrs;
	FlavorFlags flavorFlags;
	ItemReference theItem;
		
		/* we cannot drag to our own window */
	if ((err = GetDragAttributes(theDragRef, &dragAttrs)) != noErr) 
	    goto bail;
	    
	if ((dragAttrs & kDragInsideSenderWindow) != 0) { 
	    err = userCanceledErr; 
	    goto bail; 
    }
	
		/* gather information about the drag & a reference to item one. */
	if ((err = GetDragItemReferenceNumber(theDragRef, 1, &theItem)) != noErr) 
	    goto bail;
		
		/* check for flavorTypeHFS */
	err = GetFlavorFlags(theDragRef, theItem, flavorTypeHFS, &flavorFlags);
	if (err == noErr) {
		*approved = true;
		return noErr;
	} else if (err != badDragFlavorErr)
		goto bail;
		
		/* check for flavorTypePromiseHFS */
	err = GetFlavorFlags(theDragRef, theItem, flavorTypePromiseHFS, &flavorFlags);
	if (err == noErr) {
		*approved = true;
		return noErr;
	} else if (err != badDragFlavorErr)
		goto bail;
		
		/* none of our flavors were found */
	*approved = false;
	return noErr;
	
bail:
		/* an error occured, clean up.  set result to false. */
	*approved = false;
	return err;
}



/* MyDragTrackingHandler is called for tracking the mouse while a drag is passing over our
	window.  if the drag is approved, then the drop box will be hilitied appropriately
	as the mouse passes over it.  */

pascal OSErr
MyDragTrackingHandler(DragTrackingMessage message, WindowPtr theWindow, void *refCon, DragReference theDragRef) {
#pragma unused(refCon)
		/* we're drawing into the image well if we hilite... */
	EventRecord		theEvent;
    void *     fn;
	Point mouse;

	switch (message) {
	
		case kDragTrackingEnterWindow:
			{	
				DragAttributes currDragFlags;
				
				gApprovedDrag = false;
				if (theWindow == gWindowPtr) {
					if (ApproveDragReference(theDragRef, &gApprovedDrag) != noErr) break;
					if ( ! gApprovedDrag ) break;
					GetDragAttributes(theDragRef,&currDragFlags);

					if (currDragFlags) {  // if we're in the box, hilite... 
						gInIconBox = true;					
                    	    /* queue up an event */
						GetDragMouse (theDragRef,&mouse,NULL);
						theEvent.what = 0;
						theEvent.message = 0;
						theEvent.modifiers = 0;
						theEvent.when = 0;
						theEvent.where = mouse;
                    	fn = interpreterProxy->ioLoadFunctionFrom("recordDragDropEvent", "");
                    	if (fn != 0) {
                    	    ((int (*) (EventRecord *theEvent, int numberOfItems, int dragType)) fn)(&theEvent, gNumDropFiles,SQDragEnter);
                    	}
					} 
				}
			}
			break;

		case kDragTrackingInWindow:
			if (gApprovedDrag) {
				GetDragMouse (theDragRef,&mouse,NULL);
				theEvent.what = 0;
				theEvent.message = 0;
				theEvent.modifiers = 0;
				theEvent.when = 0;
				theEvent.where = mouse;
             	fn = interpreterProxy->ioLoadFunctionFrom("recordDragDropEvent", "");
            	if (fn != 0) {
            	    ((int (*) (EventRecord *theEvent,  int numberOfItems, int dragType)) fn)(&theEvent,gNumDropFiles,SQDragMove);
            	    
            	}
			}
			break;

		case kDragTrackingLeaveWindow:
			if (gApprovedDrag && gInIconBox) {
            	    /* queue up an event */
				GetDragMouse (theDragRef,&mouse,NULL);
				theEvent.what = 0;
				theEvent.message = 0;
				theEvent.modifiers = 0;
				theEvent.when = 0;
				theEvent.where = mouse;
            	fn = interpreterProxy->ioLoadFunctionFrom("recordDragDropEvent", "");
            	if (fn != 0) {
            	    ((int (*) (EventRecord *theEvent, int numberOfItems, int dragType)) fn)(&theEvent, gNumDropFiles,SQDragLeave);
            	    
            	}
			}
			gApprovedDrag = gInIconBox = false;
			break;
	}
	return noErr; // there's no point in confusing Drag Manager or its caller
}

static pascal OSErr SetDropFolder
    (DragReference dragRef, FSRef *folder)
{
    OSErr err = noErr;

    AliasHandle aliasH;

    if (!(err = FSNewAliasMinimal (folder,&aliasH)))
    {
        HLockHi ((Handle) aliasH);
        if (!(err = MemError ( )))
        {
            Size size = GetHandleSize ((Handle) aliasH);
            if (!(err = MemError ( )))
            {
                AEDesc dropLoc;

                if (!(err = AECreateDesc
                    (typeAlias,*aliasH,size,&dropLoc)))
                {
                    OSErr err2;

                    err = SetDropLocation (dragRef,&dropLoc);

                    err2 = AEDisposeDesc (&dropLoc);
                    if (!err) err = err2;
                }
            }
        }

        DisposeHandle ((Handle) aliasH);
        if (!err) err = MemError ( );
    }

    return err;
}

/* MyDragReceiveHandler is the receive handler for the main window.  It is called
	when a file or folder (or a promised file or folder) is dropped into the drop
	box in the main window.  Here, if the drag reference has been approved in the
	track drag call, we handle three different cases:
	
	1. standard hfs flavors,
	
	2. promised flavors provided by find file, mmmm This may be a pre sherlock issue
	
	3. promised flavors provided by other applications.
	
     */
     
pascal OSErr
MyDragReceiveHandler(WindowPtr theWindow, void *refcon, DragReference theDragRef) {

#pragma unused(refcon)
#pragma unused(theWindow)
	ItemReference   theItem;
	PromiseHFSFlavor targetPromise;
	Size            theSize;
	OSErr           err;
	EventRecord		theEvent;
	long            i,countActualItems;
	void *			fn;
	FInfo 			finderInfo;
	HFSFlavor		targetHFSFlavor;
	
		/* validate the drag.  Recall the receive handler will only be called after
		the tracking handler has received a kDragTrackingInWindow event.  As a result,
		the gApprovedDrag and gInIconBox will be defined when we arrive here.  Hence,
		there is no need to spend extra time validating the drag at this point. */
		
	if ( ! (gApprovedDrag && gInIconBox) )  
	    return userCanceledErr; 

	if (gNumDropFiles !=0 ) 
	    DisposePtr((char *) dropFiles);
	    
	if ((err = CountDragItems(theDragRef, (UInt16 *) &gNumDropFiles)) != noErr) 
	    return paramErr;
	
	dropFiles = (HFSFlavorSqueak *) NewPtr(sizeof(HFSFlavorSqueak)*gNumDropFiles);
	
	if (dropFiles == null) {
	    gNumDropFiles = 0;
	    return userCanceledErr;
	}
	
    countActualItems = 0;
    		
    for(i=1;i<=gNumDropFiles;i++) {
		/* get the first item reference */
    	if ((err = GetDragItemReferenceNumber(theDragRef, i, &theItem)) != noErr) 
    	    continue;

    		/* try to get a  HFSFlavor*/
    	theSize = sizeof(HFSFlavor);
    	err = GetFlavorData(theDragRef, theItem, flavorTypeHFS, &targetHFSFlavor, &theSize, 0);
 
     	if (err == noErr) {
    		dropFiles[countActualItems].fileType = targetHFSFlavor.fileType;
    		dropFiles[countActualItems].fileCreator = targetHFSFlavor.fileCreator;
    		dropFiles[countActualItems].fdFlags = targetHFSFlavor.fdFlags;
			FSpMakeFSRef(&targetHFSFlavor.fileSpec, &dropFiles[countActualItems].theFSRef);
    		countActualItems++;
    		continue;
    	} else 
			if (err != badDragFlavorErr) 
    	        continue; 
    	
    		/* try to get a  promised HFSFlavor*/
    	theSize = sizeof(PromiseHFSFlavor);
    	err = GetFlavorData(theDragRef, theItem, flavorTypePromiseHFS, &targetPromise, &theSize, 0);
    	if (err != noErr) 
    		continue;
    	
    		/* check for a drop from find file */
    	if (targetPromise.promisedFlavor == kPromisedFlavorFindFile) {
    			/* from find file, no need to set the file location... */
    		if (err != noErr) 
    			continue;
    	} else {
			FSRef	targetFolder;
			
			err = FSFindFolder(kLocalDomain, kTemporaryFolderType, kDontCreateFolder, &targetFolder);
    		if (err != noErr) 
    			continue;
			err = SetDropFolder(theDragRef, &targetFolder);
    		if (err != noErr) 
    			continue;
    	}
		FSSpec	aFSSpec;
		
		theSize = sizeof(FSSpec);
		err = GetFlavorData(theDragRef, theItem, targetPromise.promisedFlavor, &aFSSpec, &theSize, 0);
		if (err != noErr) 
			continue;
		FSpMakeFSRef(&aFSSpec, &dropFiles[countActualItems].theFSRef);
		err = getFInfoViaFSRef(&dropFiles[countActualItems].theFSRef,&finderInfo);
		if (err != noErr) 
			continue;
			
		dropFiles[countActualItems].fileType = finderInfo.fdType;
		dropFiles[countActualItems].fileCreator = finderInfo.fdCreator;
		dropFiles[countActualItems].fdFlags =  finderInfo.fdFlags;
 		countActualItems++;
    }
    
	gNumDropFiles = countActualItems;
    if (gNumDropFiles == 0) {
    	DisposePtr((char *) dropFiles);
    	return noErr;
    }
	
	    /* queue up an event */
	Point mouse;
	
	GetDragMouse (theDragRef,&mouse,NULL);
	theEvent.what = 0;
	theEvent.message = 0;
	theEvent.modifiers = 0;
	theEvent.when = 0;
	theEvent.where = mouse;

	fn = interpreterProxy->ioLoadFunctionFrom("recordDragDropEvent", "");
	if (fn != 0) {
	    ((int (*) (EventRecord *theEvent, int numberOfItems, int dragType)) fn)(&theEvent, gNumDropFiles,SQDragDrop);
	}
	return noErr;
}

void
sqSetNumberOfDropFiles(sqInt numberOfFiles) {
        while (gDragDropThrottleSpinLock);
        gDragDropThrottleSpinLock = true;
	if (gNumDropFiles != 0 ) {
	    DisposePtr((char *) dropFiles);
	    gNumDropFiles = 0;
	}
	gNumDropFiles = numberOfFiles;
	dropFiles = (HFSFlavorSqueak *) NewPtr(sizeof(HFSFlavorSqueak)*gNumDropFiles);
	if (dropFiles == null) {
	    gNumDropFiles = 0;
	}
    return;
}

void
sqSetFileInformation(sqInt dropIndex, void *dropFile) { 
    if(dropIndex < 1 || dropIndex > gNumDropFiles) 
        return;
    memcpy(&dropFiles[dropIndex-1],(char *) dropFile,sizeof(HFSFlavorSqueak));
}
