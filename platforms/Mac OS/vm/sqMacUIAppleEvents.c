/****************************************************************************
*   PROJECT: mac apple event handler
*   FILE:    sqMacUIAppleEvents.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacUIAppleEvents.c,v 1.4 2004/08/03 02:42:00 johnmci Exp $
*
*   NOTES: 
*  3.7.3b2 Apr 10th, 2004 JMM Tetsuya HAYASHI <tetha@st.rim.or.jp>  encoding for image name at startup time.
*/

#include "sq.h"
#include "sqMacUIAppleEvents.h"
#include "sqMacUIConstants.h"
#include "sqMacUIEvents.h"
#include "sqMacEncoding.h"
#include "sqMacFileLogic.h"
#include "DropPlugin.h"

extern squeakFileOffsetType calculateStartLocationForImage();

int getFirstImageNameIfPossible(AEDesc	*fileList);
void processDocumentsButExcludeOne(AEDesc	*fileList,long whichToExclude);
UInt32 getEncoding();

/*** Apple Event Handlers ***/
static pascal OSErr HandleOpenAppEvent(const AEDescList *aevt,  AEDescList *reply, long refCon);
static pascal OSErr HandleOpenDocEvent(const AEDescList *aevt,  AEDescList *reply, long refCon);
static pascal OSErr HandlePrintDocEvent(const AEDescList *aevt, AEDescList *reply, long refCon);
static pascal OSErr HandleQuitAppEvent(const AEDescList *aevt,  AEDescList *reply, long refCon);

/*** Apple Event Handling ***/

void InstallAppleEventHandlers() {
	OSErr	err;
	long	result;

	err = Gestalt(gestaltAppleEventsAttr, &result);
	if (err == noErr) {
		AEInstallEventHandler(kCoreEventClass, kAEOpenApplication, NewAEEventHandlerUPP(HandleOpenAppEvent),  0, false);
		AEInstallEventHandler(kCoreEventClass, kAEOpenDocuments,   NewAEEventHandlerUPP(HandleOpenDocEvent),  0, false);
		AEInstallEventHandler(kCoreEventClass, kAEPrintDocuments,  NewAEEventHandlerUPP(HandlePrintDocEvent), 0, false);
		AEInstallEventHandler(kCoreEventClass, kAEQuitApplication, NewAEEventHandlerUPP(HandleQuitAppEvent),  0, false);
	}
}

pascal OSErr HandleOpenAppEvent(const AEDescList *aevt,  AEDescList *reply, long refCon) {
	/* User double-clicked application; look for "Squeak.image" in same directory */
    squeakFileOffsetType                 checkValueForEmbeddedImage;
    OSErr               err;
	ProcessSerialNumber processID;
	ProcessInfoRec      processInformation;
	Str255              name; 
        char                cname[256];
	FSSpec 		    workingDirectory;
#pragma unused(aevt)
#pragma unused(refCon)
#pragma unused(reply)

	// Get spec to the working directory
    err = GetApplicationDirectory(&workingDirectory);
    if (err != noErr) 
        return err;

	// Convert that to a full path string.
    SetVMPath(&workingDirectory);

	checkValueForEmbeddedImage = calculateStartLocationForImage();
	if (checkValueForEmbeddedImage == 0) {
	    /* use default image name in same directory as the VM */
        SetShortImageNameViaString("Squeak.image",gCurrentVMEncoding);
	    return noErr;
	}

    GetCurrentProcess(&processID); 
    processInformation.processInfoLength = sizeof(ProcessInfoRec);
    processInformation.processAppSpec = &workingDirectory;
    processInformation.processName = (StringPtr) &name;
	err = GetProcessInformation(&processID,&processInformation);

	if (err != noErr) {
        SetShortImageNameViaString("Squeak.image",gCurrentVMEncoding);
        return noErr;
    }
    
    CopyPascalStringToC(name,cname);
      SetShortImageNameViaString(cname,getEncoding());
    SetImageName( &workingDirectory);

    return noErr;
}

pascal OSErr HandleOpenDocEvent(const AEDescList *aevt, AEDescList *reply, long refCon) {
	/* User double-clicked an image file. Record the path to the VM's directory,
	   then set the default directory to the folder containing the image and
	   record the image name. */

	OSErr		err;
	AEDesc		fileList = {'NULL', NULL};
	long		numFiles, size, imageFileIsNumber;
	DescType	type;
	AEKeyword	keyword;
	FSSpec		fileSpec,workingDirectory;
	WDPBRec		pb;
	FInfo		finderInformation;
	char            shortImageName[256];
	
#pragma unused(reply)
#pragma unused(refCon)  /* reference args to avoid compiler warnings */

	/* record path to VM's home folder */
	
    if (VMPathIsEmpty()) {
        err = GetApplicationDirectory(&workingDirectory);
        if (err != noErr) 
            return err;    
        SetVMPath(&workingDirectory);
	}
	
	/* copy document list */
	err = AEGetKeyDesc(aevt, keyDirectObject, typeAEList, &fileList);
	if (err) 
	    return errAEEventNotHandled;;

	/* count list elements */
	err = AECountItems( &fileList, &numFiles);
	if (err) 
	    goto done;
	
	if (!ShortImageNameIsEmpty()) {
        /* Do the rest of the documents */
        processDocumentsButExcludeOne(&fileList,-1);
		goto done;
	}

    imageFileIsNumber = getFirstImageNameIfPossible(&fileList);
    
    if (imageFileIsNumber == 0) { 
        // Test is open change set 
        strcpy(shortImageName, "Squeak.image");
        CopyCStringToPascal(shortImageName,workingDirectory.name);
          SetShortImageNameViaString(shortImageName,getEncoding());
        SetImageName(&workingDirectory);
        fileSpec = workingDirectory;
    } else {
    	/* get image name */
    	err = AEGetNthPtr(&fileList, imageFileIsNumber, typeFSS, &keyword, &type, (Ptr) &fileSpec, sizeof(fileSpec), &size);
    	if (err) 
    	    goto done;
    	    
    	err = FSpGetFInfo(&fileSpec,&finderInformation);
    	if (err) 
    	    goto done;
    		
    	CopyPascalStringToC(fileSpec.name,shortImageName);
          SetShortImageNameViaString(shortImageName,getEncoding());
        SetImageName(&fileSpec);
   }
    
	/* make the image or document directory the working directory */
	pb.ioNamePtr = NULL;
	pb.ioVRefNum = fileSpec.vRefNum;
	pb.ioWDDirID = fileSpec.parID;
	PBHSetVolSync(&pb);

    /* Do the rest of the documents */
    processDocumentsButExcludeOne(&fileList,imageFileIsNumber);
done:
	AEDisposeDesc(&fileList);
	return err;
}

void processDocumentsButExcludeOne(AEDesc	*fileList,long whichToExclude) {
	OSErr		err;
	long		numFiles, size, i, actualFilteredNumber=0,actualFilteredIndexNumber;
	DescType	type;
	AEKeyword	keyword;
	FSSpec		fileSpec;
	FInfo		finderInformation;
    EventRecord theEvent;
    HFSFlavor   dropFile;
    Point       where;
    
	/* count list elements */
	err = AECountItems( fileList, &numFiles);
	if (err)
	    return;
	
	theEvent.what = 0;
	theEvent.message = 0;
	theEvent.when = TickCount();
	where.v = 1;
	where.h = 1;
	LocalToGlobal(&where);
	theEvent.where = where;
	theEvent.modifiers = 0;
	
	for(i=1;i<=numFiles;i++) {
	    err = AEGetNthPtr(fileList, i, typeFSS,  &keyword, &type, (Ptr) &fileSpec, sizeof(fileSpec), &size);
	    if (err) 
	        goto done;
	
	    err = FSpGetFInfo(&fileSpec,&finderInformation);
	    if (err) 
	        goto done;
		
	    if (i == whichToExclude || (finderInformation.fdCreator == 'MACS' && 
	        (finderInformation.fdType == 'fold' ||
    		finderInformation.fdType == 'disk'))) 
	        continue;
	     
	    actualFilteredNumber++;

    }
    if (actualFilteredNumber == 0) 
        goto done;
        
    sqSetNumberOfDropFiles(actualFilteredNumber);
    actualFilteredIndexNumber=1;
    
    recordDragDropEvent(&theEvent, actualFilteredNumber, DragEnter);
    for(i=1;i<=numFiles;i++) {
	    err = AEGetNthPtr(fileList, i, typeFSS,  &keyword, &type, (Ptr) &fileSpec, sizeof(fileSpec), &size);
	    if (err) 
	        goto done;
	
	    err = FSpGetFInfo(&fileSpec,&finderInformation);
	    if (err) 
	        goto done;
		
	    if (i == whichToExclude || (finderInformation.fdCreator == 'MACS' && 
	        (finderInformation.fdType == 'fold' ||
    		finderInformation.fdType == 'disk'))) 
	        continue;
	        
	    dropFile.fileType = finderInformation.fdType;
	    dropFile.fileCreator = finderInformation.fdCreator;
	    dropFile.fdFlags = finderInformation.fdFlags;
	    memcpy(&dropFile.fileSpec,&fileSpec,sizeof(FSSpec));
	     
        sqSetFileInformation(actualFilteredIndexNumber, &dropFile);
        actualFilteredIndexNumber++;
    }
	theEvent.where = where;
    recordDragDropEvent(&theEvent, actualFilteredNumber, DragDrop);
	theEvent.where = where;
    recordDragDropEvent(&theEvent, actualFilteredNumber, DragLeave);
   
   done: 
   return;
    
}


int getFirstImageNameIfPossible(AEDesc	*fileList) {
	OSErr		err;
	long		numFiles, size, i;
	DescType	type;
	AEKeyword	keyword;
	FSSpec		fileSpec;
	FInfo		finderInformation;
        char            shortImageName[256];

	/* count list elements */
	err = AECountItems( fileList, &numFiles);
	if (err) 
	    goto done;
	
	/* get image name */
	for(i=1;i<=numFiles;i++) {
	    err = AEGetNthPtr(fileList, i, typeFSS,
					  &keyword, &type, (Ptr) &fileSpec, sizeof(fileSpec), &size);
	    if (err) 
	        goto done;
	
	    err = FSpGetFInfo(&fileSpec,&finderInformation);
	    if (err) 
	        goto done;
                
            CopyPascalStringToC(fileSpec.name,shortImageName);
            SetShortImageNameViaString(shortImageName,getEncoding());

        if (IsImageName(shortImageName)  || finderInformation.fdType == 'STim')
            return i;
    }
    done: 
        return 0;
}       


pascal OSErr HandlePrintDocEvent(const AEDescList *aevt,  AEDescList *reply, long refCon) {
#pragma unused(aevt)
#pragma unused(reply)
#pragma unused(refCon)  /* reference args to avoid compiler warnings */
	return errAEEventNotHandled;
}

pascal OSErr HandleQuitAppEvent(const AEDescList *aevt,  AEDescList *reply, long refCon) {
#pragma unused(aevt)
#pragma unused(reply)
#pragma unused(refCon)  /* reference args to avoid compiler warnings */
	return noErr;  //Note under Carbon it sends us a Quit event, but we don't process because image might not get saved?
}

UInt32 getEncoding() {
#if TARGET_API_MAC_CARBON
	return CFStringGetSystemEncoding();
#else
	return 0;
#endif
}

