/****************************************************************************
*   PROJECT: mac apple event handler
*   FILE:    sqMacUIAppleEvents.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacUIAppleEvents.c 1615 2007-03-11 00:07:44Z johnmci $
*
*   NOTES: 
*  3.7.3b2 Apr 10th, 2004 JMM Tetsuya HAYASHI <tetha@st.rim.or.jp>  encoding for image name at startup time.
*  3.8.9b1 Sept 13th, 2005 JMM add logic to open application to open image files
 3.8.11b1 Mar 4th, 2006 JMM refactor, cleanup and add headless support
 *	3.8.14b1 Oct	,2006 JMM browser rewrite

*/

#include "sq.h"
#include "sqMacUIAppleEvents.h"
#include "sqMacUIConstants.h"
#include "sqMacUIEvents.h"
#include "sqMacEncoding.h"
#include "sqMacUnixFileInterface.h"
#include "DropPlugin.h"

extern char gSqueakImageName;

struct HFSFlavorSqueak {
  OSType              fileType;               /* file type */
  OSType              fileCreator;            /* file creator */
  UInt16              fdFlags;                /* Finder flags */
  FSRef               theFSRef;               /* file system Ref */
  };
typedef struct HFSFlavorSqueak                HFSFlavorSqueak;

int getFirstImageNameIfPossible(AEDesc	*fileList);
void processDocumentsButExcludeOne(AEDesc	*fileList,long whichToExclude);
OSStatus SimpleRunAppleScript(const char* theScript);
void sqRevealWindowAndHandleQuit () ;

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
#pragma unused(aevt)
#pragma unused(refCon)
#pragma unused(reply)

	char string[PATH_MAX+1];
	getShortImageNameWithEncoding(string,gCurrentVMEncoding);
	/* use current image or, if unset, default image name */
	SetShortImageNameViaString(string[0] ? string : &gSqueakImageName,
								gCurrentVMEncoding);
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
	FSRef		theFSRef;
	char        shortImageName[SHORTIMAGE_NAME_SIZE+1];
	char		pathName[IMAGE_NAME_SIZE+1];				

#pragma unused(reply)
#pragma unused(refCon)  /* reference args to avoid compiler warnings */
	
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
		SetShortImageNameViaString(&gSqueakImageName,gCurrentVMEncoding);
		if (numFiles)
			goto processPendingDocs;
		else
			goto done;
    } else {
    	/* get image name */
    	err = AEGetNthPtr(&fileList, imageFileIsNumber, typeFSRef, &keyword, &type, (Ptr) &theFSRef, sizeof(theFSRef), &size);
    	if (err) 
    	    goto done;
    	        		
		PathToFileViaFSRef(pathName, IMAGE_NAME_SIZE, &theFSRef,gCurrentVMEncoding);
		getLastPathComponentInCurrentEncoding(pathName,shortImageName,gCurrentVMEncoding);
		SetShortImageNameViaString(shortImageName,gCurrentVMEncoding);
        SetImageNameViaString(pathName,gCurrentVMEncoding);
   }
    
    /* Do the rest of the documents */
processPendingDocs:
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
	FSRef		theFSRef;
	FInfo		finderInformation;
    EventRecord theEvent;
    HFSFlavorSqueak   dropFile;
    Point       where;
	char        shortImageName[SHORTIMAGE_NAME_SIZE+1];
	char		pathName[IMAGE_NAME_SIZE+1];				

	/* count list elements */
	err = AECountItems( fileList, &numFiles);
	if (err)
	    return;
	
	theEvent.what = 0;
	theEvent.message = 0;
	theEvent.when = TickCount();
	where.v = 100;
	where.h = 100;
	theEvent.where = where;
	theEvent.modifiers = 0;
	
	for(i=1;i<=numFiles;i++) {
	    err = AEGetNthPtr(fileList, i, typeFSRef,  &keyword, &type, (Ptr) &theFSRef, sizeof(FSRef), &size);
	    if (err) 
	        goto done;
	
		err = getFInfoViaFSRef(&theFSRef,&finderInformation);
	    if (err) 
	        goto done;
		
	    if (i == whichToExclude || (finderInformation.fdCreator == 'MACS' && 
	        (finderInformation.fdType == 'fold' ||
    		finderInformation.fdType == 'disk'))) 
	        continue;
		PathToFileViaFSRef(pathName, IMAGE_NAME_SIZE, &theFSRef,gCurrentVMEncoding);
		getLastPathComponentInCurrentEncoding(pathName,shortImageName,gCurrentVMEncoding);

       if (IsImageName(shortImageName)  || finderInformation.fdType == 'STim') {
			char commandStuff[4096];
			extern char **argVec;
					
			PathToFileViaFSRef(pathName, 2048, &theFSRef,kCFStringEncodingMacRoman);
			commandStuff [0] = 0x00;
			strcat(commandStuff,"set pimage to  \"");
			strcat(commandStuff,pathName);
			strcat(commandStuff,"\" \n");
			strcat(commandStuff,"set qimage to quoted form of pimage\n");
			strcat(commandStuff,"set pVM to \"");
			strcat(commandStuff,argVec[0]);
			strcat(commandStuff,"\"\n");
			strcat(commandStuff,"set qVM to quoted form of pVM\n");
			strcat(commandStuff,"do shell script qVM");
			strcat(commandStuff," & \" \" &  qimage");
			strcat(commandStuff," & \" &> /dev/null &  echo $!\" \n");
			strcat(commandStuff,"set pid to the result as number\n");
			strcat(commandStuff,"on findProcessID(appID)\n");
			strcat(commandStuff,"  tell application \"Finder\"\n");
			strcat(commandStuff,"    repeat with ap in every application process\n");
			strcat(commandStuff,"      if «class idux» of ap is appID then return ap\n");
			strcat(commandStuff,"    end repeat\n");
			strcat(commandStuff,"  end tell\n");
			strcat(commandStuff,"end findProcessID\n");
			strcat(commandStuff,"delay 1\n");
			strcat(commandStuff,"set a to findProcessID(pid)\n");
			strcat(commandStuff,"set the frontmost of a to true\n");
			
			SimpleRunAppleScript(commandStuff);
			continue;
			}
	    actualFilteredNumber++;

    }

    if (actualFilteredNumber == 0) 
        goto done;
        
    sqSetNumberOfDropFiles(actualFilteredNumber);
    actualFilteredIndexNumber=1;
    
    recordDragDropEvent(&theEvent, actualFilteredNumber, SQDragEnter);
    for(i=1;i<=numFiles;i++) {
	    err = AEGetNthPtr(fileList, i, typeFSRef,  &keyword, &type, (Ptr) &theFSRef, sizeof(FSRef), &size);
	    if (err) 
	        goto done;
	
		err = getFInfoViaFSRef(&theFSRef,&finderInformation);
	    if (err) 
	        goto done;
		
	    if (i == whichToExclude || (finderInformation.fdCreator == 'MACS' && 
	        (finderInformation.fdType == 'fold' ||
    		finderInformation.fdType == 'disk'))) 
	        continue;

		
	    dropFile.fileType = finderInformation.fdType;
	    dropFile.fileCreator = finderInformation.fdCreator;
	    dropFile.fdFlags = finderInformation.fdFlags;
		dropFile.theFSRef = theFSRef;
	     
        sqSetFileInformation(actualFilteredIndexNumber, &dropFile);
        actualFilteredIndexNumber++;
    }
	theEvent.where = where;
    recordDragDropEvent(&theEvent, actualFilteredNumber, SQDragDrop);
	theEvent.where = where;
    recordDragDropEvent(&theEvent, actualFilteredNumber, SQDragLeave);
   
   done: 
   return;
    
}


int getFirstImageNameIfPossible(AEDesc	*fileList) {
	OSErr		err;
	long		numFiles, size, i;
	DescType	type;
	AEKeyword	keyword;
	FSRef		theFSRef;
	FInfo		finderInformation;
	char        shortImageName[SHORTIMAGE_NAME_SIZE+1];

	/* count list elements */
	err = AECountItems( fileList, &numFiles);
	if (err) 
	    goto done;
	
	/* get image name */
	for(i=1;i<=numFiles;i++) {
	    err = AEGetNthPtr(fileList, i, typeFSRef,
					  &keyword, &type, (Ptr) &theFSRef, sizeof(FSRef), &size);
	    if (err) 
	        goto done;
		err = getFInfoViaFSRef(&theFSRef,&finderInformation);
	    if (err) 
	        goto done;
                
		{
			char pathName[DOCUMENT_NAME_SIZE+1];
				
			PathToFileViaFSRef(pathName, DOCUMENT_NAME_SIZE, &theFSRef,gCurrentVMEncoding);
			getLastPathComponentInCurrentEncoding(pathName,shortImageName,gCurrentVMEncoding);
		}
		SetShortImageNameViaString(shortImageName,gCurrentVMEncoding);

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
	extern Boolean gSqueakQuitOnQuitAppleEvent;
	
	if (gSqueakQuitOnQuitAppleEvent) {
		sqRevealWindowAndHandleQuit ();
	}
	return noErr;  
}


/* LowRunAppleScript compiles and runs an AppleScript
    provided as text in the buffer pointed to by text.  textLength
    bytes will be compiled from this buffer and run as an AppleScript
    using all of the default environment and execution settings.  If
    resultData is not NULL, then the result returned by the execution
    command will be returned as typeChar in this descriptor record
    (or typeNull if there is no result information).  If the function
    returns errOSAScriptError, then resultData will be set to a
    descriptive error message describing the error (if one is
    available).  */
static OSStatus LowRunAppleScript(const void* text, long textLength,
                                    AEDesc *resultData) {
    ComponentInstance theComponent;
    AEDesc scriptTextDesc;
    OSStatus err;
    OSAID scriptID, resultID;

        /* set up locals to a known state */
    theComponent = NULL;
    AECreateDesc(typeNull, NULL, 0, &scriptTextDesc);
    scriptID = kOSANullScript;
    resultID = kOSANullScript;

        /* open the scripting component */
    theComponent = OpenDefaultComponent(kOSAComponentType,
                    typeAppleScript);
    if (theComponent == NULL) { err = paramErr; goto bail; }

        /* put the script text into an aedesc */
    err = AECreateDesc(typeChar, text, textLength, &scriptTextDesc);
    if (err != noErr) goto bail;

        /* compile the script */
    err = OSACompile(theComponent, &scriptTextDesc,
                    kOSAModeNull, &scriptID);
    if (err != noErr) goto bail;

        /* run the script */
    err = OSAExecute(theComponent, scriptID, kOSANullScript,
                    kOSAModeNull, &resultID);

        /* collect the results - if any */
    if (resultData != NULL) {
        AECreateDesc(typeNull, NULL, 0, resultData);
        if (err == errOSAScriptError) {
            OSAScriptError(theComponent, kOSAErrorMessage,
                        typeChar, resultData);
        } else if (err == noErr && resultID != kOSANullScript) {
            OSADisplay(theComponent, resultID, typeChar,
                        kOSAModeNull, resultData);
        }
    }
bail:
    AEDisposeDesc(&scriptTextDesc);
    if (scriptID != kOSANullScript) OSADispose(theComponent, scriptID);
    if (resultID != kOSANullScript) OSADispose(theComponent, resultID);
    if (theComponent != NULL) CloseComponent(theComponent);
    return err;
}


    /* SimpleRunAppleScript compiles and runs the AppleScript in
    the c-style string provided as a parameter.  The result returned
    indicates the success of the operation. */

OSStatus SimpleRunAppleScript(const char* theScript) {
    return LowRunAppleScript(theScript, strlen(theScript), NULL);
}
