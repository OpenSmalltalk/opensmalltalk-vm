/****************************************************************************
*   PROJECT: Mac external plugin, bundle, cfm mach-o whatever interface code.
*   FILE:    sqMacExternalPrims.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacExternalPrims.c,v 1.3 2003/02/08 18:31:33 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*****************************************************************************/

#include "sq.h"
#include "sqMacExternalPrims.h"
#include "sqMacFileLogic.h"

extern char vmPath[];
CFragConnectionID LoadLibViaPath(char *libName, char *pluginDirPath);

/*** Mac Specific External Primitive Support ***/

/* ioLoadModule:
	Load a module from disk.
	WARNING: this always loads a *new* module. Don't even attempt to find a loaded one.
	WARNING: never primitiveFail() within, just return 0
*/
int ioLoadModule(char *pluginName) {
	char pluginDirPath[1000];
	CFragConnectionID libHandle;
	Ptr mainAddr;
	Str255 errorMsg,tempPluginName;
	OSErr err;
    
    	/* first, look in the "<Squeak VM directory>Plugins" directory for the library */
	strcpy(pluginDirPath, vmPath);
	
#ifdef PLUGIN
	strcat(pluginDirPath, ":Plugins");
#else
	strcat(pluginDirPath, "Plugins");
#endif 	
    
    libHandle = LoadLibViaPath(pluginName, pluginDirPath);
	if (libHandle != nil) return (int) libHandle;

#ifndef PLUGIN
	/* second, look directly in Squeak VM directory for the library */
	libHandle = LoadLibViaPath(pluginName, vmPath);
	if (libHandle != nil) return (int) libHandle;
    
    #if !defined ( __APPLE__ ) && !defined ( __MACH__ )
        /* Lastly look for it as a shared import library */
        
        CopyCStringToPascal(pluginName,tempPluginName);
        err = GetSharedLibrary(tempPluginName, kAnyCFragArch, kLoadCFrag, &libHandle, &mainAddr, errorMsg);
            if (err == noErr) 
                err = GetSharedLibrary(tempPluginName, kAnyCFragArch, kFindCFrag, &libHandle, &mainAddr, errorMsg);
            if (libHandle != nil) return (int) libHandle;
    #endif
#endif
    
	return nil;
}

/* ioFindExternalFunctionIn:
	Find the function with the given name in the moduleHandle.
	WARNING: never primitiveFail() within, just return 0.
*/

#if defined ( __APPLE__ ) && defined ( __MACH__ ) && JMMFoo
/* This code is here because it was mentioned as a way to link to CFM 
libraries. However it seems to core dump the VM when we go to set the interpreter ptr
Getting the Module name seemed to work. 
This code comes from the Carbon samples.

 ?THought I wonder if the malloc is return non-aligned address (shouldnt)?
 ?However others can try to see if this works 
 ?The code would need to try as a bundle, if failure then try as a CFM
 ?Not quite sure how to carry forward info about bundle, or CFM
 ?Perhaps a structure is needed pass back that indicates what the handle is? 
 
      This of course goes in ioFindExternalFunctionIn, it's glue code that a CFM 
      application does for you, but we must manually do for mach-o applications
      
     functionPtr = MachOFunctionPointerForCFMFunctionPointer(functionPtr);
    
*/

//
//	This function allocates a block of CFM glue code which contains the instructions to call CFM routines
//
UInt32 CFMLinkageTemplate[6] = {0x3D800000, 0x618C0000, 0x800C0000, 0x804C0004, 0x7C0903A6, 0x4E800420};

void	*MachOFunctionPointerForCFMFunctionPointer( void *cfmfp );
void	*MachOFunctionPointerForCFMFunctionPointer( void *cfmfp )
{
    UInt32	*mfp;
    
    mfp = malloc(sizeof(CFMLinkageTemplate)); //No we don't need to free, this linkage might be needed later. Freed when we terminate!
    mfp[0] = CFMLinkageTemplate[0] | ((UInt32)cfmfp >> 16);
    mfp[1] = CFMLinkageTemplate[1] | ((UInt32)cfmfp & 0xFFFF);
    mfp[2] = CFMLinkageTemplate[2];
    mfp[3] = CFMLinkageTemplate[3];
    mfp[4] = CFMLinkageTemplate[4];
    mfp[5] = CFMLinkageTemplate[5];
 
    MakeDataExecutable( mfp, sizeof(CFMLinkageTemplate) );
    return( mfp );
}

#endif

#if defined ( __APPLE__ ) && defined ( __MACH__ )

OSStatus LoadFrameworkBundle(CFStringRef framework, CFBundleRef *bundlePtr)
{
	OSStatus 	err;
	FSRef 		frameworksFolderRef;
	CFURLRef	baseURL;
	CFURLRef	bundleURL;
	
	*bundlePtr = nil;
	
	baseURL = nil;
	bundleURL = nil;
	
	err = FSFindFolder(kOnAppropriateDisk, kFrameworksFolderType, true, &frameworksFolderRef);
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
	
	return err;
}

int 	ioFindExternalFunctionIn(char *lookupName, int moduleHandle) {
	void * 		functionPtr = 0;
	OSErr 		err;
        CFStringRef	theString;
        
	if (!moduleHandle) 
            return nil;
            
        theString = CFStringCreateWithCString(kCFAllocatorDefault,lookupName,kCFStringEncodingMacRoman);
        if (theString == nil) 
            return nil;
        functionPtr = (void*)CFBundleGetFunctionPointerForName((CFBundleRef) moduleHandle,theString);
        CFRelease(theString);
                
	return (int) functionPtr;
}

/* ioFreeModule:
	Free the module with the associated handle.
	WARNING: never primitiveFail() within, just return 0.
*/
int ioFreeModule(int moduleHandle) {
	if (!moduleHandle) 
            return 0;
	CFBundleUnloadExecutable((CFBundleRef) moduleHandle);
	CFRelease((CFBundleRef) moduleHandle);
        return 0;
}

CFragConnectionID LoadLibViaPath(char *libName, char *pluginDirPath) {
        char				tempDirPath[1024];
 	CFragConnectionID		libHandle = 0;
        CFURLRef 			theURLRef;
        CFBundleRef			theBundle;
        CFStringRef			filePath;
        OSStatus			err;
        
	strncpy(tempDirPath,pluginDirPath,1023);
        if (tempDirPath[strlen(tempDirPath)-1] != ':')
            strcat(tempDirPath,":");
            
        if ((strlen(tempDirPath) + strlen(libName) + 7) > 1023)
            return nil;
        
        strcat(tempDirPath,libName);
        strcat(tempDirPath,".bundle");  
        //Watch out for the bundle suffix, not a normal thing in squeak plugins
	// We could do this, but it's expensive err =makeFSSpec(tempDirPath,strlen(tempDirPath),&fileSpec);
        // So go back to a cheaper call
        filePath = CFStringCreateWithCString(kCFAllocatorDefault,
                    (UInt8 *) tempDirPath,kCFStringEncodingMacRoman);
        if (filePath == nil)
            return nil;
            
        theURLRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,filePath,kCFURLHFSPathStyle,false);
	CFRelease(filePath);
        if (theURLRef == nil)
            return nil;

        theBundle = CFBundleCreate(NULL,theURLRef);
        CFRelease(theURLRef);
        
        if (theBundle == nil) {
            CFStringRef libNameCFString;
           libNameCFString = CFStringCreateWithCString(kCFAllocatorDefault,libName,kCFStringEncodingMacRoman);
            err = LoadFrameworkBundle(libNameCFString, &theBundle);
            CFRelease(libNameCFString);
            if (err != noErr)
                return nil;
        }  
        
        if (theBundle == nil) 
            return nil;
            
        if (!CFBundleLoadExecutable(theBundle)) {
            CFRelease(theBundle);
            return nil;
        }
        libHandle = (CFragConnectionID) theBundle;

	return libHandle;
}

#else
int  ioFindExternalFunctionIn(char *lookupName, int moduleHandle) {
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
	return (int) functionPtr;
}

/* ioFreeModule:
	Free the module with the associated handle.
	WARNING: never primitiveFail() within, just return 0.
*/
int ioFreeModule(int moduleHandle) {
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
        char				tempDirPath[1024];
        Ptr				junk;
	CFragConnectionID		libHandle = 0;
	OSErr				err = noErr;

	strncpy(tempDirPath,pluginDirPath,1023);
        if (tempDirPath[strlen(tempDirPath)-1] != ':')
            strcat(tempDirPath,":");
            
        strcat(tempDirPath,libName);
	err =makeFSSpec(tempDirPath,strlen(tempDirPath),&fileSpec);
	if (err) return nil; /* bad plugin directory path */

        err = GetDiskFragment(
		&fileSpec, 0, kCFragGoesToEOF, nil, kLoadCFrag, &libHandle, &junk, problemLibName);
                
        if (err) 
	    return nil;

	return libHandle;
}
#endif