/****************************************************************************
*   PROJECT: Mac external plugin, bundle, cfm mach-o whatever interface code.
*   FILE:    sqMacExternalPrims.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacExternalPrims.c 1311 2006-02-07 07:24:56Z johnmci $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Oct 2nd, 2003, JMM bug in browser file name creation in os-x, rework how path is resolved
 3.7.0bx Nov 24th, 2003 JMM gCurrentVMEncoding
 3.7.5b1 Aug 24th, 2004 JMM Joliet support for loading bundles?
 3.8.9b2 Sep 22nd, 2005 JMM look in os-x resource folders for bundles too
*****************************************************************************/

#include "sq.h"
#include "sqMacExternalPrims.h"
#include "sqMacUnixFileInterface.h"
#include "sqMacEncoding.h"
#include "sqMacUIConstants.h"

//#define JMMDEBUG
CFragConnectionID LoadLibViaPath(char *libName, char *pluginDirPath);
void createBrowserPluginPath(char *pluginDirPath);

/*** Mac Specific External Primitive Support ***/

/* ioLoadModule:
	Load a module from disk.
	WARNING: this always loads a *new* module. Don't even attempt to find a loaded one.
	WARNING: never primitiveFail() within, just return 0
*/
void* ioLoadModule(char *pluginName) {
	char pluginDirPath[DOCUMENT_NAME_SIZE+1];
	CFragConnectionID libHandle;
#ifndef BROWSERPLUGIN
    #if !defined ( __APPLE__ ) && !defined ( __MACH__ )
	Ptr mainAddr;
	Str255 errorMsg,tempPluginName;
	OSErr err;
#endif
#endif    
    	/* first, look in the "<Squeak VM directory>Plugins" directory for the library */
        getVMPathWithEncoding(pluginDirPath,gCurrentVMEncoding);
	
#ifdef BROWSERPLUGIN
        createBrowserPluginPath(pluginDirPath);
#else
	strcat(pluginDirPath, "Plugins");
#endif 	
    
    libHandle = LoadLibViaPath(pluginName, pluginDirPath);
	if (libHandle != nil) return (void *) libHandle;

#ifndef BROWSERPLUGIN
	/* second, look directly in Squeak VM directory for the library */
	getVMPathWithEncoding(pluginDirPath,gCurrentVMEncoding);
	libHandle = LoadLibViaPath(pluginName, pluginDirPath);
	if (libHandle != nil) return (void*) libHandle;
    
    #if !defined ( __APPLE__ ) && !defined ( __MACH__ )
        /* Lastly look for it as a shared import library */
        
        CopyCStringToPascal(pluginName,tempPluginName);
        err = GetSharedLibrary(tempPluginName, kAnyCFragArch, kLoadCFrag, &libHandle, &mainAddr, errorMsg);
            if (err == noErr) 
                err = GetSharedLibrary(tempPluginName, kAnyCFragArch, kFindCFrag, &libHandle, &mainAddr, errorMsg);
            if (libHandle != nil) return (void*) libHandle;
    #else
		{
            CFBundleRef mainBundle;
            CFURLRef	bundleURL,bundleURL2,resourceURL;
			CFStringRef filePath,resourcePathString;
			
            mainBundle = CFBundleGetMainBundle();   
			bundleURL = CFBundleCopyBundleURL(mainBundle);
			resourceURL = CFBundleCopyResourcesDirectoryURL(mainBundle);
			resourcePathString = CFURLCopyPath(resourceURL);
			CFRelease(resourceURL);

			bundleURL2 = CFURLCreateCopyAppendingPathComponent( kCFAllocatorSystemDefault, bundleURL, resourcePathString, false );
			CFRelease(bundleURL);
	#ifdef MACINTOSHUSEUNIXFILENAMES
			filePath = CFURLCopyFileSystemPath (bundleURL2, kCFURLPOSIXPathStyle);
	#else
			filePath = CFURLCopyFileSystemPath (bundleURL2, kCFURLHFSPathStyle);
	#endif
			CFRelease(bundleURL2);
			
			CFStringGetCString (filePath,pluginDirPath,DOCUMENT_NAME_SIZE, gCurrentVMEncoding);
			CFRelease(filePath);
			
			libHandle = LoadLibViaPath(pluginName, pluginDirPath);
			if (libHandle != nil) return (void *) libHandle;
 		}
	#endif
    #endif 
	
	return nil;
}

/* ioFindExternalFunctionIn:
	Find the function with the given name in the moduleHandle.
	WARNING: never primitiveFail() within, just return 0.
*/


OSStatus LoadFrameworkBundle(SInt16 folderLocation,CFStringRef framework, CFBundleRef *bundlePtr)
{
	OSStatus 	err;
	FSRef 		frameworksFolderRef;
	CFURLRef	baseURL;
	CFURLRef	bundleURL;
	
	*bundlePtr = nil;
	
	baseURL = nil;
	bundleURL = nil;
	
	err = FSFindFolder(folderLocation, kFrameworksFolderType, true, &frameworksFolderRef);
	if (err == noErr) {
		baseURL = CFURLCreateFromFSRef(kCFAllocatorSystemDefault, &frameworksFolderRef);
		if (baseURL == nil) {
			err = coreFoundationUnknownErr;
		}
	}
	if (err == noErr) {
		bundleURL = CFURLCreateCopyAppendingPathComponent(kCFAllocatorSystemDefault, baseURL, framework, false);
		if (bundleURL == nil) {
			err = coreFoundationUnknownErr;
		}
	}
	if (err == noErr) {
		*bundlePtr = CFBundleCreate(kCFAllocatorSystemDefault, bundleURL);
		if (*bundlePtr == nil) {
			err = coreFoundationUnknownErr;
		}
	}
	if (err == noErr) {
	    if ( ! CFBundleLoadExecutable( *bundlePtr ) ) {
			err = coreFoundationUnknownErr;
	    }
	}

	// Clean up.
	
	if (err != noErr && *bundlePtr != nil) {
		CFRelease(*bundlePtr);
		*bundlePtr = nil;
	}
	if (bundleURL != nil) {
		CFRelease(bundleURL);
	}	
	if (baseURL != nil) {
		CFRelease(baseURL);
	}	

	#ifdef JMMDEBUG
	fprintf(stderr,"\nsystem location %i error %i",folderLocation,err);
	#endif
	
	return err;
}
#if defined(__APPLE__) && defined(__MACH__)

void* 	ioFindExternalFunctionIn(char *lookupName, void * moduleHandle) {
	void * 		functionPtr = 0;
        CFStringRef	theString;
        
	if (!moduleHandle) 
            return nil;
            
        theString = CFStringCreateWithCString(kCFAllocatorDefault,lookupName,gCurrentVMEncoding);
        if (theString == nil) 
            return nil;
        functionPtr = (void*)CFBundleGetFunctionPointerForName((CFBundleRef) moduleHandle,theString);
        CFRelease(theString);
                
	return (void*) functionPtr;
}

/* ioFreeModule:
	Free the module with the associated handle.
	WARNING: never primitiveFail() within, just return 0.
*/
sqInt ioFreeModule(void * moduleHandle) {
	if (!moduleHandle) 
            return 0;
	CFBundleUnloadExecutable((CFBundleRef) moduleHandle);
	CFRelease((CFBundleRef) moduleHandle);
        return 0;
}

CFragConnectionID LoadLibViaPath(char *libName, char *pluginDirPath) {
        char				tempDirPath[DOCUMENT_NAME_SIZE+1];
		char				cFileName[DOCUMENT_NAME_SIZE+1];
		CFragConnectionID   libHandle = 0;
		CFStringRef			filePath;
        CFURLRef 			theURLRef;
        CFBundleRef			theBundle;
        OSStatus			err;
        
		strncpy(tempDirPath,pluginDirPath,DOCUMENT_NAME_SIZE);
        if (tempDirPath[strlen(tempDirPath)-1] != DELIMITERInt)
            strcat(tempDirPath,DELIMITER);
            
        if ((strlen(tempDirPath) + strlen(libName) + 7) > DOCUMENT_NAME_SIZE)
            return nil;
        
        strcat(tempDirPath,libName);
        strcat(tempDirPath,".bundle");  
        //Watch out for the bundle suffix, not a normal thing in squeak plugins

		/* copy the file name into a null-terminated C string */
		sqFilenameFromStringOpen(cFileName, (int) &tempDirPath, strlen(tempDirPath));
		#ifdef JMMDEBUG
		fprintf(stderr,"\nLoadLibViaPath file %s",cFileName);
		#endif
        filePath   = CFStringCreateWithBytes(kCFAllocatorDefault,(UInt8 *)cFileName,strlen(cFileName),kCFStringEncodingUTF8,false);
    
        theURLRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,filePath,kCFURLPOSIXPathStyle,false);
		CFRelease(filePath);
        if (theURLRef == nil) {
			#ifdef JMMDEBUG
			fprintf(stderr,"\ntheURLRef was nil so bail");
			#endif
            return nil;
		}

        theBundle = CFBundleCreate(NULL,theURLRef);
        CFRelease(theURLRef);
        
        if (theBundle == nil) {
            CFStringRef libNameCFString;
			#ifdef JMMDEBUG
			fprintf(stderr,"\nbundle was nil, trying to load from other system locations");
			#endif

           libNameCFString = CFStringCreateWithCString(kCFAllocatorDefault,libName,gCurrentVMEncoding);
            err = LoadFrameworkBundle(kUserDomain,libNameCFString, &theBundle);
			if (err != noErr)
				err = LoadFrameworkBundle(kNetworkDomain,libNameCFString, &theBundle);
			if (err != noErr)
				err = LoadFrameworkBundle(kLocalDomain,libNameCFString, &theBundle);
			if (err != noErr)
				err = LoadFrameworkBundle(kSystemDomain,libNameCFString, &theBundle);
				
            CFRelease(libNameCFString);
            if (err != noErr) {
				#ifdef JMMDEBUG
				fprintf(stderr,"\nno bundle so bail, last error %i",err);
				#endif
                return nil;
			}
        }  
        
        if (theBundle == nil) {
			#ifdef JMMDEBUG
			fprintf(stderr,"\nno bundle so bail");
			#endif
            return nil;
		}
            
        if (!CFBundleLoadExecutable(theBundle)) {
			#ifdef JMMDEBUG
			fprintf(stderr,"\nBundle found but failed CFBundleLoadExecutable");
			#endif
            CFRelease(theBundle);
            return nil;
        }
        libHandle = (CFragConnectionID) theBundle;

	#ifdef JMMDEBUG
		fprintf(stderr,"\nFound Bundle %i",libHandle);
	#endif
	return libHandle;
}

#else
void *  ioFindExternalFunctionIn(char *lookupName, void * moduleHandle) {
	CFragSymbolClass ignored;
	Ptr functionPtr = 0;
	OSErr err;
        Str255 tempLookupName;
    
	if (!moduleHandle) return 0;

	/* get the address of the desired primitive function */
	CopyCStringToPascal(lookupName,tempLookupName);
	err = FindSymbol(
		(CFragConnectionID) moduleHandle, (unsigned char *) tempLookupName,
		&functionPtr, &ignored);
	if (err) 
	    return 0;
	return (void *) functionPtr;
}

/* ioFreeModule:
	Free the module with the associated handle.
	WARNING: never primitiveFail() within, just return 0.
*/
sqInt ioFreeModule( void  *moduleHandle) {
	CFragConnectionID libHandle;
	OSErr err;

	if (!moduleHandle) return 0;
	libHandle = (CFragConnectionID) moduleHandle;
	err = CloseConnection(&libHandle);
	return 0;
}

CFragConnectionID LoadLibViaPath(char *libName, char *pluginDirPath) {
	FSSpec				fileSpec;
	Str255				problemLibName;
        char				tempDirPath[DOCUMENT_NAME_SIZE+1];
        Ptr				junk;
	CFragConnectionID		libHandle = 0;
	OSErr				err = noErr;

	strncpy(tempDirPath,pluginDirPath,DOCUMENT_NAME_SIZE);
        if (tempDirPath[strlen(tempDirPath)-1] != DELIMITER)
            strcat(tempDirPath,DELIMITER);
            
        strcat(tempDirPath,libName);
	err =makeFSSpec(tempDirPath,&fileSpec);
	if (err) return nil; /* bad plugin directory path */

        err = GetDiskFragment(
		&fileSpec, 0, kCFragGoesToEOF, nil, kLoadCFrag, &libHandle, &junk, problemLibName);
                
        if (err) 
	    return nil;

	return libHandle;
}
#endif

void createBrowserPluginPath(char *pluginDirPath) {
    int lengthOfPath = strlen(pluginDirPath);
    int i;
    
    lengthOfPath--;
    pluginDirPath[lengthOfPath] = 0x00;
#warning broken    
    for (i=lengthOfPath;i>=0;i--) {
        if (pluginDirPath[i] == ':') {
            pluginDirPath[i] = 0x00;
            strcat(pluginDirPath, ":Plugins");
            return;
        }
    }
    /* shouldn't ever get here, path will always contain one : */
}

