#include "sqMacFileLogic.h"	
#include <string.h>	

void StoreFullPathForLocalNameInto(char *shortName, char *fullName, int length, short volumeNumber,long directoryID) {
	int offset, sz, i;

	offset = PathToWorkingDir(fullName, length, volumeNumber, directoryID);

	/* copy the file name into a null-terminated C string */
	sz = strlen(shortName);
	for (i = 0; i <= sz; i++) {
		/* append shortName to fullName, including terminator */
		fullName[i + offset] = shortName[i];
	}
}

pascal	OSErr	GetFullPath(short vRefNum,
							long dirID,
							ConstStr255Param name,
							short *fullPathLength,
							Handle *fullPath)
{
	OSErr		result;
	FSSpec		spec;
	
	*fullPathLength = 0;
	*fullPath = NULL;
	
	result = FSMakeFSSpecCompat(vRefNum, dirID, name, &spec);
	if ( (result == noErr) || (result == fnfErr) )
	{
		result = FSpGetFullPath(&spec, fullPathLength, fullPath);
	}
	
	return ( result );
}

pascal	OSErr	FSpGetFullPath(const FSSpec *spec,
							   short *fullPathLength,
							   Handle *fullPath)
{
	OSErr		result;
	OSErr		realResult;
	FSSpec		tempSpec;
	CInfoPBRec	pb;
	
	*fullPathLength = 0;
	*fullPath = NULL;
	
	
	/* Default to noErr */
	realResult = result = noErr;
	
#if 0
//The following code doesn't seem to work in OS X, the BlockMoveData crashes the
// machine, the the FSMakeFSSpecCompat works, so go figure...  KG 4/1/01

	/* work around Nav Services "bug" (it returns invalid FSSpecs with empty names) */
	if ( spec->name[0] == 0 )
	{
		result = FSMakeFSSpecCompat(spec->vRefNum, spec->parID, spec->name, &tempSpec);
	}
	else
	{
		/* Make a copy of the input FSSpec that can be modified */
		BlockMoveData(spec, &tempSpec, sizeof(FSSpec));
	}
#endif 0

	result = FSMakeFSSpecCompat(spec->vRefNum, spec->parID, spec->name, &tempSpec);


	if ( result == noErr )
	{
		if ( tempSpec.parID == fsRtParID )
		{
			/* The object is a volume */
			
			/* Add a colon to make it a full pathname */
			++tempSpec.name[0];
			tempSpec.name[tempSpec.name[0]] = ':';
			
			/* We're done */
			result = PtrToHand(&tempSpec.name[1], fullPath, tempSpec.name[0]);
			*fullPathLength = tempSpec.name[0];
		}
		else
		{
			/* The object isn't a volume */
			
			/* Is the object a file or a directory? */
			pb.dirInfo.ioNamePtr = tempSpec.name;
			pb.dirInfo.ioVRefNum = tempSpec.vRefNum;
			pb.dirInfo.ioDrDirID = tempSpec.parID;
			pb.dirInfo.ioFDirIndex = 0;
			result = PBGetCatInfoSync(&pb);
			// Allow file/directory name at end of path to not exist.
			realResult = result;
			if ( (result == noErr) || (result == fnfErr) )
			{
				/* if the object is a directory, append a colon so full pathname ends with colon */
				if ( (result == noErr) && (pb.hFileInfo.ioFlAttrib & kioFlAttribDirMask) != 0 )
				{
					++tempSpec.name[0];
					tempSpec.name[tempSpec.name[0]] = ':';
				}
				
				/* Put the object name in first */
				result = PtrToHand(&tempSpec.name[1], fullPath, tempSpec.name[0]);
				*fullPathLength = tempSpec.name[0];
				if ( result == noErr )
				{
					/* Get the ancestor directory names */
					pb.dirInfo.ioNamePtr = tempSpec.name;
					pb.dirInfo.ioVRefNum = tempSpec.vRefNum;
					pb.dirInfo.ioDrParID = tempSpec.parID;
					do	/* loop until we have an error or find the root directory */
					{
						pb.dirInfo.ioFDirIndex = -1;
						pb.dirInfo.ioDrDirID = pb.dirInfo.ioDrParID;
						result = PBGetCatInfoSync(&pb);
						if ( result == noErr )
						{
							/* Append colon to directory name */
							++tempSpec.name[0];
							tempSpec.name[tempSpec.name[0]] = ':';
							
							/* Add directory name to beginning of fullPath */
							(void) Munger(*fullPath, 0, NULL, 0, &tempSpec.name[1], tempSpec.name[0]);
							*fullPathLength += tempSpec.name[0];
							result = MemError();
						}
					} while ( (result == noErr) && (pb.dirInfo.ioDrDirID != fsRtDirID) );
				}
			}
		}
	}
	
	if ( result == noErr )
	{
		/* Return the length */
///		*fullPathLength = GetHandleSize(*fullPath);
		result = realResult;	// return realResult in case it was fnfErr
	}
	else
	{
		/* Dispose of the handle and return NULL and zero length */
		if ( *fullPath != NULL )
		{
			DisposeHandle(*fullPath);
		}
		*fullPath = NULL;
		*fullPathLength = 0;
	}
	
	return ( result );
}


pascal	OSErr	FSMakeFSSpecCompat(short vRefNum,
								   long dirID,
								   ConstStr255Param fileName,
								   FSSpec *spec)
{
	OSErr	result;
	
	/* Let the file system create the FSSpec if it can since it does the job */
	/* much more efficiently than I can. */
	result = FSMakeFSSpec(vRefNum, dirID, fileName, spec);

	/* Fix a bug in Macintosh PC Exchange's MakeFSSpec code where 0 is */
	/* returned in the parID field when making an FSSpec to the volume's */
	/* root directory by passing a full pathname in MakeFSSpec's */
	/* fileName parameter. Fixed in Mac OS 8.1 */
	if ( (result == noErr) && (spec->parID == 0) )
		spec->parID = fsRtParID;
	return ( result );
}

OSErr FSpLocationFromFullPath(short fullPathLength,
									 const void *fullPath,
									 FSSpec *spec)
{
	AliasHandle	alias;
	OSErr		result;
	Boolean		wasChanged;
	Str32		nullString;
	
	/* Create a minimal alias from the full pathname */
	nullString[0] = 0;	/* null string to indicate no zone or server name */
	result = NewAliasMinimalFromFullPath(fullPathLength, fullPath, nullString, nullString, &alias);
	if ( result == noErr )
	{
		/* Let the Alias Manager resolve the alias. */
		result = ResolveAlias(NULL, alias, spec, &wasChanged);
		
		/* work around Alias Mgr sloppy volume matching bug */
		if ( spec->vRefNum == 0 )
		{
			/* invalidate wrong FSSpec */
			spec->parID = 0;
			spec->name[0] =  0;
			result = nsvErr;
		}
		DisposeHandle((Handle)alias);	/* Free up memory used */
	}
	return ( result );
}

#if !defined (__APPLE__) && !defined(__MACH__)
typedef struct {
	StandardFileReply *theSFR;
	FSSpec *itemSpec;
} HookRecord, *HookRecordPtr;
#endif

OSErr squeakFindImage(const FSSpecPtr defaultLocationfssPtr,FSSpecPtr documentFSSpec)
{
    NavDialogOptions    dialogOptions;
    AEDesc              defaultLocation;
    NavEventUPP         eventProc = NewNavEventUPP(findImageEventProc);
    NavObjectFilterUPP  filterProc =  NewNavObjectFilterUPP(findImageFilterProc);
    OSErr               anErr = noErr;
    
#if !TARGET_API_MAC_CARBON 
#if   MINIMALVM
  if (true) {
#else
  if ((Ptr) NavGetDefaultDialogOptions==(Ptr)kUnresolvedCFragSymbolAddress ) {
#endif
      	//System pre 8.5 or system 7.x
    	// point my hook data record at the reply record and at
		// the file spec for the system file
		
     	StandardFileReply mySFR;
#if !defined (__APPLE__) && !defined(__MACH__)
    	HookRecord hookRec;
#endif

        DlgHookYDUPP	myDlgHookUPP;
    	SFTypeList mySFTypeList;
	    Point dialogPt;
	    
		hookRec.itemSpec = defaultLocationfssPtr;
		hookRec.theSFR = &mySFR;
		SetPt(&dialogPt, -1, -1);

		// Set up the universal proc pointer to your hook routine with this 
		// macro defined in StandardFile.h.  **NOTE** This is different
		// from the macro used for System 6 dialog hooks, and you should get
		// a compiler error if you try to use the wrong UPP with the wrong call.
		myDlgHookUPP = NewDlgHookYDProc(DialogHook);
		
		// call Std File
		CustomGetFile(nil, -1, mySFTypeList, &mySFR, 0, dialogPt, myDlgHookUPP,
			nil, nil, nil, &hookRec);
			
		// Dispose of the routine descriptor, since they do allocate memory..
		DisposeRoutineDescriptor(myDlgHookUPP);
		*documentFSSpec = mySFR.sfFile; 
		return !mySFR.sfGood;
	}
#endif
#if !MINIMALVM
    //  Specify default options for dialog box
    anErr = NavGetDefaultDialogOptions(&dialogOptions);
    if (anErr == noErr)
    {
        //  Adjust the options to fit our needs
        //  Set default location option
        dialogOptions.dialogOptionFlags |= kNavSelectDefaultLocation;
        dialogOptions.dialogOptionFlags |= kNavNoTypePopup;
        //  Clear preview option
        dialogOptions.dialogOptionFlags ^= kNavAllowPreviews;
        
        // make descriptor for default location
        anErr = AECreateDesc(typeFSS, defaultLocationfssPtr,
                             sizeof(*defaultLocationfssPtr),
                             &defaultLocation );
        if (anErr == noErr)
        {
            // Get 'open' resource. A nil handle being returned is OK,
            // this simply means no automatic file filtering.
            NavTypeListHandle typeList = (NavTypeListHandle)GetResource(
                                        'open', 128);
            NavReplyRecord reply;
            
            // Call NavGetFile() with specified options and
            // declare our app-defined functions and type list
            anErr = NavGetFile (&defaultLocation, &reply, &dialogOptions,
                                eventProc, nil, filterProc,
                                typeList, nil);
            if (anErr == noErr && reply.validRecord)
            {
                //  Deal with multiple file selection
                long    count;
                
                anErr = AECountItems(&(reply.selection), &count);
                // Set up index for file list
                if (anErr == noErr)
                {
                    long index;
                    
                    for (index = 1; index <= 1; index++)
                    {
                        AEKeyword   theKeyword;
                        DescType    actualType;
                        Size        actualSize;
                        
                        // Get a pointer to selected file
                        anErr = AEGetNthPtr(&(reply.selection), index,
                                            typeFSS, &theKeyword,
                                            &actualType,documentFSSpec,
                                            sizeof(FSSpec),
                                            &actualSize);
                     }
                }
                //  Dispose of NavReplyRecord, resources, descriptors
                anErr = NavDisposeReply(&reply);
            }
            if (typeList != NULL)
            {
                ReleaseResource( (Handle)typeList);
            }
            (void) AEDisposeDesc(&defaultLocation);
        }
    }
    DisposeNavEventUPP(eventProc);
    DisposeNavObjectFilterUPP(filterProc);
    return anErr;
#endif
}

pascal void findImageEventProc(NavEventCallbackMessage callBackSelector, 
                        NavCBRecPtr callBackParms, 
                        NavCallBackUserData callBackUD)
{
   // WindowPtr window = 
   //                 (WindowPtr)callBackParms->eventData.event->message;
    switch (callBackSelector)
    {
        case kNavCBEvent:
            switch (((callBackParms->eventData)
                    .eventDataParms).event->what)
            {
                case updateEvt:
                   // MyHandleUpdateEvent(window, 
                    //    (EventRecord*)callBackParms->eventData.event);
                    break;
            }
            break;
    }
}

pascal Boolean findImageFilterProc(AEDesc* theItem, void* info, 
                            NavCallBackUserData callBackUD,
                            NavFilterModes filterMode)
{
    OSErr theErr = noErr;
    Boolean display = true;
    NavFileOrFolderInfo* theInfo = (NavFileOrFolderInfo*)info;
    
    if (theItem->descriptorType == typeFSS)
        if (!theInfo->isFolder)
            if (theInfo->fileAndFolder.fileInfo.finderInfo.fdType 
                != 'STim')
                display = false;
    return display;
}

#if !TARGET_API_MAC_CARBON

// this dialog hook for System 7 std file selects
// the file specified by the hookRecord supplied as userData

pascal short DialogHook(short item, DialogPtr theDialog, 
	void *userData)
{
	HookRecordPtr hookRecPtr;
	
	hookRecPtr = (HookRecordPtr) userData;
	
	// hookRecPtr->itemSpec points to the FSSpec of the item to be selected
	// hookRecPtr->theSFR points to the standard file reply record

	// make sure we're dealing with the proper dialog
	if (GetWRefCon(theDialog) == sfMainDialogRefCon) {
	
		// just when opening the dialog...
		if (item == sfHookFirstCall) {
	
			// make the reply record hold the spec of the specified item
			hookRecPtr->theSFR->sfFile = *hookRecPtr->itemSpec;
			
			// There¹s a gotcha in Standard File when using sfHookChangeSelection. 
			// Even though New Inside Macintosh: Files has a sample that doesn't set
			// the sfScript field, it should be set, or the last object in the
			// selected directory  will always be selected.
			hookRecPtr->theSFR->sfScript = smSystemScript;

			// tell std file to change the selection to that item
			item = sfHookChangeSelection;
		}
	}			
		
	return item;
}
#endif
/*****************************************************************************************
GetApplicationDirectory

Get the volume reference number and directory id of this application.
Code taken from Apple:
	Technical Q&As: FL 14 - Finding your application's directory (19-June-2000)

Karl Goiser 14/01/01
*****************************************************************************************/

        /* GetApplicationDirectory returns the volume reference number
        and directory ID for the current application's directory. */

    OSStatus GetApplicationDirectory(short *vRefNum, long *dirID) {
        ProcessSerialNumber PSN;
        ProcessInfoRec pinfo;
        FSSpec pspec;
        OSStatus err;
            /* valid parameters */
        if (vRefNum == NULL || dirID == NULL) return paramErr;
            /* set up process serial number */
        PSN.highLongOfPSN = 0;
        PSN.lowLongOfPSN = kCurrentProcess;
            /* set up info block */
        pinfo.processInfoLength = sizeof(pinfo);
        pinfo.processName = NULL;
        pinfo.processAppSpec = &pspec;
            /* grab the vrefnum and directory */
        err = GetProcessInformation(&PSN, &pinfo);
        if (err == noErr) {
            *vRefNum = pspec.vRefNum;
            *dirID = pspec.parID;
        }
        return err;
    }


/*** Initializing the path to Working Dir ***/

int PathToWorkingDir(char *pathName, int pathNameMax, short volumeNumber,long directoryID) {
	/* Fill in the given string with the full path from a root volume to
	   to current working directory. (At startup time, the working directory
	   is set to the application's directory. Fails if the given string is not
	   long enough to hold the entire path. (Use at least 1000 characters to
	   be safe.)
	*/

	short	fullPathLength;
	Handle	fullPathHandle;

	if (GetFullPath(volumeNumber, directoryID, nil, &fullPathLength, &fullPathHandle) != noErr) {
		//Some sort of random guff for failure:
		pathName[0] = 1;
		pathName[1] = (char)":";
		return 1;
	}

	strncpy((char *) pathName, (char *) *fullPathHandle, fullPathLength);
	DisposeHandle(fullPathHandle);
	return fullPathLength;
}



/*****************************************************************************/


int PrefixPathWith(char *pathName, int pathNameSize, int pathNameMax, char *prefix) {
	/* Insert the given prefix C string plus a delimitor character at the
	   beginning of the given C string. Return the new pathName size. Fails
	   if pathName is does not have sufficient space for the result.
	   Assume: pathName is null terminated.
	*/

	int offset, i;

	offset = strlen(prefix) + 1;
	if ((pathNameSize + offset) > pathNameMax) {
		return pathNameSize;
	}

	for (i = pathNameSize; i >= 0; i--) {
		/* make room in pathName for prefix (moving string terminator, too) */
		pathName[i + offset] = pathName[i];
	}
	for (i = 0; i < offset; i++) {
		/* make room in pathName for prefix */
		pathName[i] = prefix[i];
	}
	pathName[offset - 1] = ':';  /* insert delimitor */
	return pathNameSize + offset;
}

OSErr makeFSSpec(char *pathString, int pathStringLength,FSSpec *spec)
{	
	char name[256];
	
	if (pathStringLength > 255 ) 
	    return -1;
   
    strncpy((char *) name,pathString,pathStringLength);
    name[pathStringLength] = 0x00;
    return __path2fss((char *) name, spec);
}

OSErr __path2fss(const char * pathName, FSSpecPtr spec)
{
    return lookupPath((char *) pathName, strlen(pathName),spec,true);
}
									 								 
/*
JMM 2001/02/02 rewrote 
*/

int lookupPath(char *pathString, int pathStringLength, FSSpec *spec,Boolean noDrillDown) {
	/* Resolve the given path and return the resulting folder or volume
	   reference number in *refNumPtr. Return error if the path is bad. */

	CInfoPBRec      pb;
	Str255          tempName;
 	OSErr		    err;
    Boolean         ignore;
 	int				i;
 	
    /* First locate by farily normal methods, with perhaps an alias lookup */
    makePascalStringFromSqName(pathString,pathStringLength,tempName);

    err = FSMakeFSSpecCompat(0,0,tempName,spec);

    if (err == noErr) {
        if (noDrillDown == false) {
            fetchFileInfo(&pb,0,spec,spec->name,true,&ignore);
        }
        return noErr;
    }         
         
    /* Than failed, we might have an alias chain, or other issue so 
    first setup for directory or file then do it the hard way */
    
    strncpy((char *)tempName,pathString,pathStringLength);
    if (noDrillDown) {
        tempName[pathStringLength] = 0x00;
    }
    else {
        tempName[pathStringLength] = ':';
        tempName[pathStringLength+1] = 0x00;
    }

  	i = 0;
  	while(tempName[i]) {
   		if(tempName[i] == ':') {
      		if(tempName[i+1] == ':')
				return fnfErr; /* fix for :: doItTheHardWay can't deal with this */
   		 }
   		i++;
    }

    err = doItTheHardWay(tempName,spec,&pb,noDrillDown);
    return err;
}

/* This method is used to lookup paths, chunk by chunk. It builds specs for each chuck and fetchs the file 
information, Note the special case when noDrilldown */

int doItTheHardWay(unsigned char *pathString,FSSpec *spec,CInfoPBRec *pb,Boolean noDrillDown) {
    char *token;
    Str255 lookup;
    Boolean ignore,firstTime=true;
    OSErr   err;
    
    token = strtok((char*) pathString,":");
    if (token == 0) return -1;
    while (token) 
    {
        if (firstTime) {
            strncpy((char*) lookup+1,(char*) token,63);
            lookup[0] = strlen(token)+1;
            lookup[lookup[0]] = ':';
            firstTime = false;
        } else {
            strncpy((char*) lookup+2,(char*) token,63);
            lookup[0] = strlen(token)+1;
            lookup[1] = ':';
        }
        if ((err = FSMakeFSSpecCompat(spec->vRefNum,spec->parID, lookup, spec)) != noErr) 
            return err;
        
        fetchFileInfo(pb,0,spec,spec->name,true,&ignore);
        token = strtok(NULL,":"); 
    }
   if (noDrillDown) 
       spec->parID = pb->dirInfo.ioDrParID;
     return noErr;
}

/*Get the file ID that unique IDs this file or directory, also resolve any alias if required */

int fetchFileInfo(CInfoPBRec *pb,int dirIndex,FSSpec *spec,unsigned char *name,Boolean doAlias,Boolean *isFolder) {
    long    aliasGestaltInfo;
     
    *isFolder = false;
    pb->hFileInfo.ioNamePtr = name;
	pb->hFileInfo.ioFVersNum = 0;
	pb->hFileInfo.ioFDirIndex = dirIndex;
	pb->hFileInfo.ioVRefNum = spec->vRefNum;
	pb->hFileInfo.ioDirID = spec->parID;

	if (PBGetCatInfoSync(pb) == noErr) {
		if ((pb->hFileInfo.ioFlFndrInfo.fdFlags & kIsAlias) && doAlias) {
		    FSSpec spec2;
		    Boolean isAlias;
		    OSErr   err;
		    
		   
		   err = FSMakeFSSpecCompat(spec->vRefNum, spec->parID, name,&spec2);
#if TARGET_CPU_PPC
           if ((Gestalt(gestaltAliasMgrAttr, &aliasGestaltInfo) == noErr) &&
                aliasGestaltInfo & (1<<gestaltAliasMgrResolveAliasFileWithMountOptions)  &&
                ((Ptr) ResolveAliasFileWithMountFlags != (Ptr)kUnresolvedCFragSymbolAddress)) {
                err = ResolveAliasFileWithMountFlags(&spec2,false,isFolder,&isAlias,kResolveAliasFileNoUI);
            } 
            else 
#endif
    			err = ResolveAliasFile(&spec2,false,isFolder,&isAlias);
    		
    			
            if (err == noErr) {
            	if (dirIndex == 0) {
            	    fetchFileInfo(pb,dirIndex,&spec2,spec2.name,false,isFolder);
            	    *spec = spec2;
            	}
        		return true;
			}
		}
        spec->parID = pb->hFileInfo.ioDirID;
		return true;
	}
	return false;

}

void makePascalStringFromSqName(char *pathString, int pathStringLength,unsigned char *name)
{
	/* copy file name into a Pascal string */
	
	name[0] = pathStringLength;
	strncpy((char *)name+1,pathString,pathStringLength);

} 

