// Stub to call mach-o plugin for better project builder debugging.
// By John M McIntosh Jan 2003. (johnmci@smalltalkconsulting.com)
// Released under the Squeak-L license 
//  http://www.squeak.org/download/license.html
// V1.0 January 2003.
// V 1.1 Sept 2003 Add looking in user/local/network/system domains

#include "npapi.h"
#include "npupp.h"

#define EnterCodeResource() 
#define ExitCodeResource() 
#define __destroy_global_chain()
#define __InitCode__()
int printOnOSXPascal(unsigned char * string);
int printOnOSX(char * string);
int printOnOSXNumber(int number);
int printOnOSXPascal(unsigned char * string);
int printOnOSXFormat(char * string,char *format);
OSStatus LoadFrameworkBundle(CFStringRef framework, CFBundleRef *bundlePtr);
CFragConnectionID LoadLibViaPath(char *libName);
CFragConnectionID LoadLibViaPathInDomain(char *libName, SInt16 domain);
int 	ioFindExternalFunctionIn(char *lookupName, int moduleHandle);
int ioFreeModule(int moduleHandle);
NPError 	Private_Initialize(void);
void 		Private_Shutdown(void);
NPError		Private_New(NPMIMEType pluginType, NPP instance, uint16 mode, int16 argc, char* argn[], char* argv[], NPSavedData* saved);
NPError 	Private_Destroy(NPP instance, NPSavedData** save);
NPError		Private_SetWindow(NPP instance, NPWindow* window);
NPError		Private_NewStream(NPP instance, NPMIMEType type, NPStream* stream, NPBool seekable, uint16* stype);
NPError		Private_DestroyStream(NPP instance, NPStream* stream, NPError reason);
int32		Private_WriteReady(NPP instance, NPStream* stream);
int32		Private_Write(NPP instance, NPStream* stream, int32 offset, int32 len, void* buffer);
void		Private_StreamAsFile(NPP instance, NPStream* stream, const char* fname);
void		Private_Print(NPP instance, NPPrint* platformPrint);
int16 		Private_HandleEvent(NPP instance, void* event);
void        Private_URLNotify(NPP instance, const char* url, NPReason reason, void* notifyData);
jref		Private_GetJavaClass(void);


typedef short (*GetMainPtr)(NPNetscapeFuncs* nsTable, NPPluginFuncs* pluginFuncs, NPP_ShutdownUPP* unloadUpp); // Mach-O function
GetMainPtr GetMain = NULL;

typedef NPError (*GetPrivate_InitializePtr)(); // Mach-O function
GetPrivate_InitializePtr GetPrivate_Initialize = NULL;

typedef void (*GetPrivate_ShutdownPtr)(); // Mach-O function
GetPrivate_ShutdownPtr GetPrivate_Shutdown = NULL;

typedef NPError (*GetPrivate_NewPtr)(NPMIMEType pluginType, NPP instance, uint16 mode, int16 argc, char* argn[], char* argv[], NPSavedData* saved); // Mach-O function
GetPrivate_NewPtr GetPrivate_New = NULL;

typedef NPError (*GetPrivate_DestroyPtr)(NPP instance, NPSavedData** save); // Mach-O function
GetPrivate_DestroyPtr GetPrivate_Destroy = NULL;

typedef NPError (*GetPrivate_SetWindowPtr)(NPP instance, NPWindow* window); // Mach-O function
GetPrivate_SetWindowPtr GetPrivate_SetWindow = NULL;

typedef NPError (*GetPrivate_NewStreamPtr)(NPP instance, NPMIMEType type, NPStream* stream, NPBool seekable, uint16* stype); // Mach-O function
GetPrivate_NewStreamPtr GetPrivate_NewStream = NULL;

typedef int32 (*GetPrivate_WriteReadyPtr)(NPP instance, NPStream* stream); // Mach-O function
GetPrivate_WriteReadyPtr GetPrivate_WriteReady = NULL;

typedef int32 (*GetPrivate_WritePtr)(NPP instance, NPStream* stream, int32 offset, int32 len, void* buffer); // Mach-O function
GetPrivate_WritePtr GetPrivate_Write = NULL;

typedef void (*GetPrivate_StreamAsFilePtr)(NPP instance, NPStream* stream, const char* fname); // Mach-O function
GetPrivate_StreamAsFilePtr GetPrivate_StreamAsFile = NULL;

typedef NPError (*GetPrivate_DestroyStreamPtr)(NPP instance, NPStream* stream, NPError reason); // Mach-O function
GetPrivate_DestroyStreamPtr GetPrivate_DestroyStream = NULL;

typedef int16 (*GetPrivate_HandleEventPtr)(NPP instance, void* event); // Mach-O function
GetPrivate_HandleEventPtr GetPrivate_HandleEvent = NULL;

typedef void (*GetPrivate_PrintPtr)(NPP instance, NPPrint* platformPrint); // Mach-O function
GetPrivate_PrintPtr GetPrivate_Print = NULL;

typedef void (*GetPrivate_URLNotifyPtr)(NPP instance, const char* url, NPReason reason, void* notifyData); // Mach-O function
GetPrivate_URLNotifyPtr GetPrivate_URLNotify = NULL;

typedef jref (*GetPrivate_GetJavaClassPtr)(void); // Mach-O function
GetPrivate_GetJavaClassPtr GetPrivate_GetJavaClass = NULL;

static CFragConnectionID gWhere;

NPNetscapeFuncs gRememberOldgNetscapeFuncsForSafariIssue;
NPPluginFuncs gDummyPluginFuncsForSafariIssue;
NPP_ShutdownUPP gDummyUnloadUppForSafariIssue;

int main(NPNetscapeFuncs* nsTable, NPPluginFuncs* pluginFuncs, NPP_ShutdownUPP* unloadUpp)
{
	int err=noErr;
	int navMinorVers = nsTable->version & 0xFF;
	
	gRememberOldgNetscapeFuncsForSafariIssue = *nsTable;
	
	gWhere = LoadLibViaPath("NPSqueak.bundle");
	if (gWhere == nil)
		return -1;
		
	GetMain = (void *) ioFindExternalFunctionIn("npmain",(int) gWhere);
	if (GetMain == NULL) 
		GetMain = (void *) ioFindExternalFunctionIn("main",(int) gWhere);
	err = GetMain(nsTable, pluginFuncs, unloadUpp);
	
	//
	// Set up the plugin function table that Netscape will use to
	// call us.  Netscape needs to know about our version and size
	// and have a UniversalProcPointer for every function we implement.
	//

	pluginFuncs->version = (NP_VERSION_MAJOR << 8) + NP_VERSION_MINOR;
	pluginFuncs->size = sizeof(NPPluginFuncs);
	pluginFuncs->newp = NewNPP_NewProc(Private_New);
	pluginFuncs->destroy = NewNPP_DestroyProc(Private_Destroy);
	pluginFuncs->setwindow = NewNPP_SetWindowProc(Private_SetWindow);
	pluginFuncs->newstream = NewNPP_NewStreamProc(Private_NewStream);
	pluginFuncs->destroystream = NewNPP_DestroyStreamProc(Private_DestroyStream);
	pluginFuncs->asfile = NewNPP_StreamAsFileProc(Private_StreamAsFile);
	pluginFuncs->writeready = NewNPP_WriteReadyProc(Private_WriteReady);
	pluginFuncs->write = NewNPP_WriteProc(Private_Write);
	pluginFuncs->print = NewNPP_PrintProc(Private_Print);
	pluginFuncs->event = NewNPP_HandleEventProc(Private_HandleEvent);	
	if( navMinorVers >= NPVERS_HAS_NOTIFICATION )
	{	
		pluginFuncs->urlnotify = NewNPP_URLNotifyProc(Private_URLNotify);			
	}
	if( navMinorVers >= NPVERS_HAS_LIVECONNECT )
	{
		pluginFuncs->javaClass	= (JRIGlobalRef) Private_GetJavaClass();
	}
	*unloadUpp = NewNPP_ShutdownProc(Private_Shutdown);

	return err;
}

NPError Private_Initialize(void)
{
	NPError err;
	if (GetPrivate_Initialize == NULL) 
		GetPrivate_Initialize = (void *) ioFindExternalFunctionIn("Private_Initialize",(int) gWhere);
	err = GetPrivate_Initialize();
	return err;
}

void Private_Shutdown(void)
{
	if (gWhere == NULL) 
		return;
	if (GetPrivate_Shutdown == NULL) 
		GetPrivate_Shutdown = (void *) ioFindExternalFunctionIn("Private_Shutdown",(int) gWhere);
	if (GetPrivate_Shutdown == NULL) 
		return;
	GetPrivate_Shutdown();
	ioFreeModule((int) gWhere);
	gWhere = 0;
	GetPrivate_Initialize = 0;
	GetPrivate_Shutdown = 0;
	GetPrivate_New = 0;
	GetPrivate_Destroy= 0;
	GetPrivate_SetWindow= 0;
	GetPrivate_NewStream= 0;
	GetPrivate_WriteReady= 0;
	GetPrivate_Write = 0;
 	GetPrivate_StreamAsFile = 0;
	GetPrivate_DestroyStream = 0;
	GetPrivate_HandleEvent = 0;
 	GetPrivate_Print = 0;
 	GetPrivate_URLNotify = 0;
	GetPrivate_GetJavaClass = 0;
}


NPError	Private_New(NPMIMEType pluginType, NPP instance, uint16 mode, int16 argc, char* argn[], char* argv[], NPSavedData* saved)
{
	NPError err;

	if (gWhere == nil) {
		
		gWhere = LoadLibViaPath("NPSqueak.bundle");
		if (gWhere == nil) 
			return -1;
		GetMain = (void *) ioFindExternalFunctionIn("npmain",(int) gWhere);
		if (GetMain == NULL) 
			GetMain = (void *) ioFindExternalFunctionIn("main",(int) gWhere);
		err = GetMain(&gRememberOldgNetscapeFuncsForSafariIssue, &gDummyPluginFuncsForSafariIssue, &gDummyUnloadUppForSafariIssue);
	}

	if (GetPrivate_New == NULL) 
		GetPrivate_New = (void *) ioFindExternalFunctionIn("Private_New",(int) gWhere);
	if (GetPrivate_New != NULL) 
		err = GetPrivate_New( pluginType,  instance,  mode,  argc, argn,  argv,  saved);
	return err;
}

NPError Private_Destroy(NPP instance, NPSavedData** save)
{
	NPError err;
	if (GetPrivate_Destroy == NULL) 
		GetPrivate_Destroy = (void *) ioFindExternalFunctionIn("Private_Destroy",(int) gWhere);
	if (GetPrivate_Destroy != NULL) 
		err = GetPrivate_Destroy( instance, save);
	Private_Shutdown();
	return NPERR_NO_ERROR;
}
NPError Private_SetWindow(NPP instance, NPWindow* window)
{
	NPError err;
	if (GetPrivate_SetWindow == NULL) 
		GetPrivate_SetWindow = (void *) ioFindExternalFunctionIn("Private_SetWindow",(int) gWhere);
	if (GetPrivate_SetWindow != NULL) 
		err = GetPrivate_SetWindow( instance,  window);
	return err;
}

NPError Private_NewStream(NPP instance, NPMIMEType type, NPStream* stream, NPBool seekable, uint16* stype)
{
	NPError err;
	if (GetPrivate_NewStream == NULL) 
		GetPrivate_NewStream = (void *) ioFindExternalFunctionIn("Private_NewStream",(int) gWhere);
	if (GetPrivate_NewStream != NULL) 
		err = GetPrivate_NewStream( instance,  type,  stream,  seekable,  stype);
	return err;
}

int32 Private_WriteReady(NPP instance, NPStream* stream)
{
	int32 length;
	if (GetPrivate_WriteReady == NULL) 
		GetPrivate_WriteReady = (void *) ioFindExternalFunctionIn("Private_WriteReady",(int) gWhere);
	if (GetPrivate_WriteReady != NULL) 
		length = GetPrivate_WriteReady( instance, stream);
	return length;
}

int32 Private_Write(NPP instance, NPStream* stream, int32 offset, int32 len, void* buffer)
{
	int32 length;
	if (GetPrivate_Write == NULL) 
		GetPrivate_Write = (void *) ioFindExternalFunctionIn("Private_Write",(int) gWhere);
	if (GetPrivate_Write != NULL) 
		length = GetPrivate_Write( instance,  stream,  offset,  len,  buffer);
	return length;
}

void Private_StreamAsFile(NPP instance, NPStream* stream, const char* fname)
{
	if (GetPrivate_StreamAsFile == NULL) 
		GetPrivate_StreamAsFile = (void *) ioFindExternalFunctionIn("Private_StreamAsFile",(int) gWhere);
	if (GetPrivate_StreamAsFile != NULL) 
		GetPrivate_StreamAsFile( instance,  stream, fname);
}


NPError Private_DestroyStream(NPP instance, NPStream* stream, NPError reason)
{
	NPError err;
	if (GetPrivate_DestroyStream == NULL) 
		GetPrivate_DestroyStream = (void *) ioFindExternalFunctionIn("Private_DestroyStream",(int) gWhere);
	if (GetPrivate_DestroyStream != NULL) 
		err = GetPrivate_DestroyStream( instance,  stream,  reason);
	return err;
}

int16 Private_HandleEvent(NPP instance, void* event)
{
	int16 err;
	if (GetPrivate_HandleEvent == NULL) 
		GetPrivate_HandleEvent = (void *) ioFindExternalFunctionIn("Private_HandleEvent",(int) gWhere);
	if (GetPrivate_HandleEvent != NULL) 
		err = GetPrivate_HandleEvent( instance,  event);
	return err;
}

void Private_Print(NPP instance, NPPrint* platformPrint)
{
	if (GetPrivate_Print == NULL) 
		GetPrivate_Print = (void *) ioFindExternalFunctionIn("Private_Print",(int) gWhere);
	if (GetPrivate_Print != NULL) 
		GetPrivate_Print( instance,  platformPrint);
}

void Private_URLNotify(NPP instance, const char* url, NPReason reason, void* notifyData)
{
	if (GetPrivate_URLNotify == NULL) 
		GetPrivate_URLNotify = (void *) ioFindExternalFunctionIn("Private_URLNotify",(int) gWhere);
	if (GetPrivate_URLNotify != NULL) 
		GetPrivate_URLNotify( instance, url,  reason,  notifyData);
}

jref Private_GetJavaClass(void)
{
	if (GetPrivate_GetJavaClass == NULL) 
		GetPrivate_GetJavaClass = (void *) ioFindExternalFunctionIn("Private_GetJavaClass",(int) gWhere);
	if (GetPrivate_GetJavaClass != NULL) 
		return GetPrivate_GetJavaClass();
}

static void* FP2TV (void * fp ) {
	void **newGlue = NULL ;
	if ( fp != NULL ) {
		newGlue = (void**) malloc (2 * sizeof(void *));
		if (newGlue != NULL ) {
			newGlue[0] = fp ;
			newGlue[1] = NULL ;
		}
	}
	return newGlue;
}

int 	ioFindExternalFunctionIn(char *lookupName, int moduleHandle) {
	void * 		functionPtr = 0;
    CFStringRef	theString;
        	
	if (!moduleHandle) 
            return nil;
    //printOnOSX(lookupName);
    
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

CFragConnectionID LoadLibViaPathInDomain(char *libName,SInt16 domain) {
 	CFragConnectionID	libHandle = 0;
    CFURLRef 			theURLRef;
    CFBundleRef			theBundle;
    OSStatus			err;
    CFStringRef 		libNameCFString;
	FSRef 				frameworksFolderRef;
	CFURLRef	baseURL;

 
    err = FSFindFolder(domain, kInternetPlugInFolderType, false,&frameworksFolderRef);
    
    if (err != noErr) {
		return nil;
    }
    
    baseURL = CFURLCreateFromFSRef(kCFAllocatorSystemDefault,&frameworksFolderRef);
    if (baseURL == nil) {
        return nil;
    }
    
	libNameCFString = CFStringCreateWithCString(kCFAllocatorDefault,libName,kCFStringEncodingMacRoman);
    if (libNameCFString == nil) {
		CFRelease(baseURL);
    	return nil;
    }
    theURLRef = CFURLCreateCopyAppendingPathComponent(kCFAllocatorSystemDefault, baseURL,libNameCFString, false);
	CFRelease(libNameCFString);
	CFRelease(baseURL);
    if (theURLRef == nil) {
        return nil;
    }
         
    theBundle = CFBundleCreate(kCFAllocatorSystemDefault,theURLRef);
    CFRelease(theURLRef);
    
    if (theBundle == nil) {
        return nil;
    }
    
    if (!CFBundleLoadExecutable(theBundle)) {
        CFRelease(theBundle);
        return nil;
    }
    
    libHandle = (CFragConnectionID) theBundle;

	return libHandle;
}

CFragConnectionID LoadLibViaPath(char *libName) {
	static const SInt16 domain[] = {kUserDomain, kLocalDomain, kNetworkDomain, kSystemDomain, 0}; 
	CFragConnectionID connectionID;
	SInt32 domainIndex=0;
	
	do {
		connectionID = LoadLibViaPathInDomain(libName,domain[domainIndex]);
		if (connectionID != nil) 
			return connectionID;
		domainIndex++;
	} while (domain[domainIndex] != 0); 
	return nil;
}

OSStatus LoadFrameworkBundle(CFStringRef framework, CFBundleRef
*bundlePtr)
{
    OSStatus    err;
    FSRef       frameworksFolderRef;
    CFURLRef    baseURL;
    CFURLRef    bundleURL;

    if ( bundlePtr == nil ) return( -1 );

    *bundlePtr = nil;
 
    baseURL = nil;
    bundleURL = nil;
 
    err = FSFindFolder(kOnAppropriateDisk, kFrameworksFolderType, true,
&frameworksFolderRef);
    if (err == noErr) {
        baseURL = CFURLCreateFromFSRef(kCFAllocatorSystemDefault,
&frameworksFolderRef);
        if (baseURL == nil) {
            err = coreFoundationUnknownErr;
        }
    }
    if (err == noErr) {
        bundleURL =
CFURLCreateCopyAppendingPathComponent(kCFAllocatorSystemDefault, baseURL,
framework, false);
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



int printOnOSXFormat(char * string,char *format) {
	CFBundleRef bundle;
	int(*fprintf_ptr)(FILE *stream, const char *format, ...) = NULL;
	int(*fcnFlush_ptr)(FILE *stream) = NULL;
	void* fcn_ptr = NULL;
	void* fcnFlushx_ptr = NULL;
	OSErr	err;
	FILE* stderr_ptr = NULL;
	void* __sf_ptr = NULL;
	
	err = LoadFrameworkBundle( CFSTR("System.framework"), &bundle );

	fcn_ptr = CFBundleGetFunctionPointerForName(bundle, CFSTR("fprintf"));
	fcnFlushx_ptr = CFBundleGetFunctionPointerForName(bundle, CFSTR("fflush"));
	__sf_ptr = CFBundleGetDataPointerForName(bundle, CFSTR("__sF"));
	
	if(fcn_ptr) {
	   /* cast it */
	   fprintf_ptr = ( int(*)(FILE *stream, const char *format, ...) ) fcn_ptr;
	} else {
	   /* it failed, handle that somehow */
	   return;
	}

	if(fcnFlushx_ptr) {
	   /* cast it */
	   fcnFlush_ptr = ( int(*)(FILE *stream) ) fcnFlushx_ptr;
	} else {
	   /* it failed, handle that somehow */
	   return;
	}

	if(__sf_ptr) {
	   stderr_ptr = (FILE*) ( ((char*)__sf_ptr) + 176);
	   /* 176 = 88*2, where 88=sizeof(FILE) under BSD */
	} else {
	   /* it failed */
	   return;
	}

	fprintf_ptr(stderr_ptr, format,string);
	fcnFlush_ptr(stderr_ptr);
}

int printOnOSX(char * string) {
	return printOnOSXFormat(string,"\n+-+%s");
}

int printOnOSXNumber(int number) {
	return printOnOSXFormat((char *) number,"\n+-+%d");
}

int printOnOSXPascal(unsigned char *string) {
	CopyPascalStringToC((ConstStr255Param) string,(char*) string);
	printOnOSX((char*) string);
	CopyCStringToPascal((char*)string,(void *) string);
}
