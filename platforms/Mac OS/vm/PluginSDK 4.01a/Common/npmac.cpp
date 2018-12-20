//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//
// npmac.cpp
//
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#include <Processes.h>
#include <Gestalt.h>
#include <CodeFragments.h>
#include <Timer.h>
#include <Resources.h>
#include <ToolUtils.h>

#define XP_MAC 1

//
// A4Stuff.h contains the definition of EnterCodeResource and 
// EnterCodeResource, used for setting up the code resource�s
// globals for 68K (analagous to the function SetCurrentA5
// defined by the toolbox).
//
#if !defined ( __APPLE__ ) && !defined ( __MACH__ )
#include <A4Stuff.h>
#else
#define EnterCodeResource() 
#define ExitCodeResource() 
#define __destroy_global_chain()
#define __InitCode__()
#endif

#include "npapi.h"

//
// The Mixed Mode procInfos defined in npupp.h assume Think C-
// style calling conventions.  These conventions are used by
// Metrowerks with the exception of pointer return types, which
// in Metrowerks 68K are returned in A0, instead of the standard
// D0. Thus, since NPN_MemAlloc and NPN_UserAgent return pointers,
// Mixed Mode will return the values to a 68K plugin in D0, but 
// a 68K plugin compiled by Metrowerks will expect the result in
// A0.  The following pragma forces Metrowerks to use D0 instead.
//
#ifdef __MWERKS__
#ifndef powerc
#pragma pointers_in_D0
#endif
#endif

#include "npupp.h"

#ifdef __MWERKS__
#ifndef powerc
#pragma pointers_in_A0
#endif
#endif

// The following fix for static initializers (which fixes a preious
// incompatibility with some parts of PowerPlant, was submitted by 
// Jan Ulbrich.
#ifdef __MWERKS__
	#ifdef __cplusplus
	extern "C" {
	#endif
		#ifndef powerc
			extern void	__InitCode__(void);
		#else
			extern void __sinit(void);
			#define __InitCode__ __sinit
		#endif
		extern void	__destroy_global_chain(void);
	#ifdef __cplusplus
	}
	#endif // __cplusplus
#endif // __MWERKS__

//
// Define PLUGIN_TRACE to 1 to have the wrapper functions emit
// DebugStr messages whenever they are called.
//#define PLUGIN_TRACE 1

#if PLUGIN_TRACE
//extern "C"  int printOnOSXPascal(unsigned char * string);
//#define PLUGINDEBUGSTR(msg) printOnOSXPascal(msg)
#define PLUGINDEBUGSTR(msg)		::DebugStr(msg)
#else
#define PLUGINDEBUGSTR
#endif






//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//
// Globals
//
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

//JMM QDGlobals*		gQDPtr;				// Pointer to Netscape�s QuickDraw globals
short			gResFile;			// Refnum of the plugin�s resource file
NPNetscapeFuncs	gNetscapeFuncs;		// Function table for procs in Netscape called by plugin


//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//
// Wrapper functions for all calls from the plugin to Netscape.
// These functions let the plugin developer just call the APIs
// as documented and defined in npapi.h, without needing to know
// about the function table and call macros in npupp.h.
//
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


void NPN_Version(int* plugin_major, int* plugin_minor, int* netscape_major, int* netscape_minor)
{
	*plugin_major = NP_VERSION_MAJOR;
	*plugin_minor = NP_VERSION_MINOR;
	*netscape_major = gNetscapeFuncs.version >> 8;		// Major version is in high byte
	*netscape_minor = gNetscapeFuncs.version & 0xFF;	// Minor version is in low byte
}

NPError NPN_GetURLNotify(NPP instance, const char* url, const char* window, void* notifyData)
{
	int navMinorVers = gNetscapeFuncs.version & 0xFF;
	NPError err;
	
	if( navMinorVers >= NPVERS_HAS_NOTIFICATION )
	{
		err = CallNPN_GetURLNotifyProc(gNetscapeFuncs.geturlnotify, instance, url, window, notifyData);
	}
	else
	{
		err = NPERR_INCOMPATIBLE_VERSION_ERROR;
	}
	return err;
}

NPError NPN_GetURL(NPP instance, const char* url, const char* window)
{
	return CallNPN_GetURLProc(gNetscapeFuncs.geturl, instance, url, window);
}

NPError NPN_PostURLNotify(NPP instance, const char* url, const char* window, uint32 len, const char* buf, NPBool file, void* notifyData)
{
	int navMinorVers = gNetscapeFuncs.version & 0xFF;
	NPError err;
	
	if( navMinorVers >= NPVERS_HAS_NOTIFICATION )
	{
		err = CallNPN_PostURLNotifyProc(gNetscapeFuncs.posturlnotify, instance, url, 
														window, len, buf, file, notifyData);
	}
	else
	{
		err = NPERR_INCOMPATIBLE_VERSION_ERROR;
	}
	return err;
}

NPError NPN_PostURL(NPP instance, const char* url, const char* window, uint32 len, const char* buf, NPBool file)
{
	return CallNPN_PostURLProc(gNetscapeFuncs.posturl, instance, url, window, len, buf, file);
}

NPError NPN_RequestRead(NPStream* stream, NPByteRange* rangeList)
{
	return CallNPN_RequestReadProc(gNetscapeFuncs.requestread, stream, rangeList);
}

NPError NPN_NewStream(NPP instance, NPMIMEType type, const char* window, NPStream** stream)
{
	int navMinorVers = gNetscapeFuncs.version & 0xFF;
	NPError err;
	
	if( navMinorVers >= NPVERS_HAS_STREAMOUTPUT )
	{
		err = CallNPN_NewStreamProc(gNetscapeFuncs.newstream, instance, type, window, stream);
	}
	else
	{
		err = NPERR_INCOMPATIBLE_VERSION_ERROR;
	}
	return err;
}

int32 NPN_Write(NPP instance, NPStream* stream, int32 len, void* buffer)
{
	int navMinorVers = gNetscapeFuncs.version & 0xFF;
	NPError err;
	
	if( navMinorVers >= NPVERS_HAS_STREAMOUTPUT )
	{
		err = CallNPN_WriteProc(gNetscapeFuncs.write, instance, stream, len, buffer);
	}
	else
	{
		err = NPERR_INCOMPATIBLE_VERSION_ERROR;
	}
	return err;
}

NPError	NPN_DestroyStream(NPP instance, NPStream* stream, NPError reason)
{
	int navMinorVers = gNetscapeFuncs.version & 0xFF;
	NPError err;
	
	if( navMinorVers >= NPVERS_HAS_STREAMOUTPUT )
	{
		err = CallNPN_DestroyStreamProc(gNetscapeFuncs.destroystream, instance, stream, reason);
	}
	else
	{
		err = NPERR_INCOMPATIBLE_VERSION_ERROR;
	}
	return err;
}

void NPN_Status(NPP instance, const char* message)
{
	CallNPN_StatusProc(gNetscapeFuncs.status, instance, message);
}

const char* NPN_UserAgent(NPP instance)
{
	return CallNPN_UserAgentProc(gNetscapeFuncs.uagent, instance);
}

void* NPN_MemAlloc(uint32 size)
{
	return CallNPN_MemAllocProc(gNetscapeFuncs.memalloc, size);
}

void NPN_MemFree(void* ptr)
{
	CallNPN_MemFreeProc(gNetscapeFuncs.memfree, ptr);
}

uint32 NPN_MemFlush(uint32 size)
{
	return CallNPN_MemFlushProc(gNetscapeFuncs.memflush, size);
}

void NPN_ReloadPlugins(NPBool reloadPages)
{
	CallNPN_ReloadPluginsProc(gNetscapeFuncs.reloadplugins, reloadPages);
}


JRIEnv* NPN_GetJavaEnv(void)
{
	return CallNPN_GetJavaEnvProc( gNetscapeFuncs.getJavaEnv );
}

jref  NPN_GetJavaPeer(NPP instance)
{
	return CallNPN_GetJavaPeerProc( gNetscapeFuncs.getJavaPeer, instance );
}

NPError NPN_GetValue(NPP instance, NPNVariable variable, void *value)
{
	return CallNPN_GetValueProc( gNetscapeFuncs.getvalue, instance, variable, value);
}

NPError NPN_SetValue(NPP instance, NPPVariable variable, void *value)
{
	return CallNPN_SetValueProc( gNetscapeFuncs.setvalue, instance, variable, value);
}

void NPN_InvalidateRect(NPP instance, NPRect *rect)
{
	CallNPN_InvalidateRectProc( gNetscapeFuncs.invalidaterect, instance, rect);
}

void NPN_InvalidateRegion(NPP instance, NPRegion region)
{
	CallNPN_InvalidateRegionProc( gNetscapeFuncs.invalidateregion, instance, region);
}

void NPN_ForceRedraw(NPP instance)
{
	CallNPN_ForceRedrawProc( gNetscapeFuncs.forceredraw, instance);
}

//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//
// Wrapper functions for all calls from Netscape to the plugin.
// These functions let the plugin developer just create the APIs
// as documented and defined in npapi.h, without needing to 
// install those functions in the function table or worry about
// setting up globals for 68K plugins.
//
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

extern "C" NPError 	Private_Initialize(void);
extern "C" void 		Private_Shutdown(void);
extern "C" NPError		Private_New(NPMIMEType pluginType, NPP instance, uint16 mode, int16 argc, char* argn[], char* argv[], NPSavedData* saved);
extern "C" NPError 	Private_Destroy(NPP instance, NPSavedData** save);
extern "C" NPError		Private_SetWindow(NPP instance, NPWindow* window);
extern "C" NPError		Private_NewStream(NPP instance, NPMIMEType type, NPStream* stream, NPBool seekable, uint16* stype);
extern "C" NPError		Private_DestroyStream(NPP instance, NPStream* stream, NPError reason);
extern "C" int32		Private_WriteReady(NPP instance, NPStream* stream);
extern "C" int32		Private_Write(NPP instance, NPStream* stream, int32 offset, int32 len, void* buffer);
extern "C" void		Private_StreamAsFile(NPP instance, NPStream* stream, const char* fname);
extern "C" void		Private_Print(NPP instance, NPPrint* platformPrint);
extern "C" int16 		Private_HandleEvent(NPP instance, void* event);
extern "C" void        Private_URLNotify(NPP instance, const char* url, NPReason reason, void* notifyData);
extern "C" jref		Private_GetJavaClass(void);

extern "C" NPError Private_Initialize(void)
{
	NPError err;
	EnterCodeResource();
	PLUGINDEBUGSTR("\pInitialize;g;");
	err = NPP_Initialize();
	ExitCodeResource();
	return err;
}

extern "C" void Private_Shutdown(void)
{
	EnterCodeResource();
	PLUGINDEBUGSTR("\pShutdown;g;");
	NPP_Shutdown();

	__destroy_global_chain();

	ExitCodeResource();
}


extern "C" NPError	Private_New(NPMIMEType pluginType, NPP instance, uint16 mode, int16 argc, char* argn[], char* argv[], NPSavedData* saved)
{
	EnterCodeResource();
	NPError ret = NPP_New(pluginType, instance, mode, argc, argn, argv, saved);
	PLUGINDEBUGSTR("\pNew;g;");
	ExitCodeResource();
	return ret;	
}

extern "C" NPError Private_Destroy(NPP instance, NPSavedData** save)
{
	NPError err;
	EnterCodeResource();
	PLUGINDEBUGSTR("\pDestroy;g;");
	err = NPP_Destroy(instance, save);
	ExitCodeResource();
	return err;
}

extern "C" NPError Private_SetWindow(NPP instance, NPWindow* window)
{
	NPError err;
	EnterCodeResource();
	PLUGINDEBUGSTR("\pSetWindow;g;");
	err = NPP_SetWindow(instance, window);
	ExitCodeResource();
	return err;
}

extern "C" NPError Private_NewStream(NPP instance, NPMIMEType type, NPStream* stream, NPBool seekable, uint16* stype)
{
	NPError err;
	EnterCodeResource();
	PLUGINDEBUGSTR("\pNewStream;g;");
	err = NPP_NewStream(instance, type, stream, seekable, stype);
	ExitCodeResource();
	return err;
}

extern "C" int32 Private_WriteReady(NPP instance, NPStream* stream)
{
	int32 result;
	EnterCodeResource();
	PLUGINDEBUGSTR("\pWriteReady;g;");
	result = NPP_WriteReady(instance, stream);
	ExitCodeResource();
	return result;
}

extern "C" int32 Private_Write(NPP instance, NPStream* stream, int32 offset, int32 len, void* buffer)
{
	int32 result;
	EnterCodeResource();
	PLUGINDEBUGSTR("\pWrite;g;");
	result = NPP_Write(instance, stream, offset, len, buffer);
	ExitCodeResource();
	return result;
}

extern "C" void Private_StreamAsFile(NPP instance, NPStream* stream, const char* fname)
{
	EnterCodeResource();
	PLUGINDEBUGSTR("\pStreamAsFile;g;");
	NPP_StreamAsFile(instance, stream, fname);
	ExitCodeResource();
}


extern "C" NPError Private_DestroyStream(NPP instance, NPStream* stream, NPError reason)
{
	NPError err;
	EnterCodeResource();
	PLUGINDEBUGSTR("\pDestroyStream;g;");
	err = NPP_DestroyStream(instance, stream, reason);
	ExitCodeResource();
	return err;
}

extern "C" int16 Private_HandleEvent(NPP instance, void* event)
{
	int16 result;
	EnterCodeResource();
//	PLUGINDEBUGSTR("\pHandleEvent;g;");
	result = NPP_HandleEvent(instance, event);
	ExitCodeResource();
	return result;
}

extern "C" void Private_Print(NPP instance, NPPrint* platformPrint)
{
	EnterCodeResource();
	PLUGINDEBUGSTR("\pPrint;g;");
	NPP_Print(instance, platformPrint);
	ExitCodeResource();
}

extern "C" void Private_URLNotify(NPP instance, const char* url, NPReason reason, void* notifyData)
{
	EnterCodeResource();
	PLUGINDEBUGSTR("\pURLNotify;g;");
	NPP_URLNotify(instance, url, reason, notifyData);
	ExitCodeResource();
}

extern "C" jref Private_GetJavaClass(void)
{
	EnterCodeResource();
	PLUGINDEBUGSTR("\pGetJavaClass;g;");

    jref clazz = NPP_GetJavaClass();
    ExitCodeResource();
    if (clazz)
    {
		JRIEnv* env = NPN_GetJavaEnv();
		return (jref)JRI_NewGlobalRef(env, clazz);
    }
    return NULL;
}

void SetUpQD(void);
void SetUpQD(void)
{
	ProcessSerialNumber PSN;
	FSSpec				myFSSpec;
	Str63				name;
	ProcessInfoRec		infoRec;
	OSErr				result = noErr;
	CFragConnectionID 	connID;
	Str255 				errName;
	
	//
	// Memorize the plugin�s resource file 
	// refnum for later use.
	//
	gResFile = CurResFile();
	
	//
	// Ask the system if CFM is available.
	//
	long response;
	OSErr err = Gestalt(gestaltCFMAttr, &response);
	Boolean hasCFM = BitTst(&response, 31-gestaltCFMPresent);
			
	if (hasCFM)
	{
		//
		// GetProcessInformation takes a process serial number and 
		// will give us back the name and FSSpec of the application.
		// See the Process Manager in IM.
		//
		infoRec.processInfoLength = sizeof(ProcessInfoRec);
		infoRec.processName = name;
		infoRec.processAppSpec = &myFSSpec;
		
		PSN.highLongOfPSN = 0;
		PSN.lowLongOfPSN = kCurrentProcess;
		
		result = GetProcessInformation(&PSN, &infoRec);
		if (result != noErr)
			PLUGINDEBUGSTR("\pFailed in GetProcessInformation");
		}
	else
		//
		// If no CFM installed, assume it must be a 68K app.
		//
		result = -1;		
		
	if (result == noErr)
	{
		//
		// Now that we know the app name and FSSpec, we can call GetDiskFragment
		// to get a connID to use in a subsequent call to FindSymbol (it will also
		// return the address of �main� in app, which we ignore).  If GetDiskFragment 
		// returns an error, we assume the app must be 68K.
		//
		Ptr mainAddr; 	
		result =  GetDiskFragment(infoRec.processAppSpec, 0L, 0L, infoRec.processName,
								  kLoadCFrag, &connID, (Ptr*)&mainAddr, errName);
	}

	if (result == noErr) 
	{
		//
		// The app is a PPC code fragment, so call FindSymbol
		// to get the exported �qd� symbol so we can access its
		// QuickDraw globals.
		//
		CFragSymbolClass symClass;
		//JMM result = FindSymbol(connID, "\pqd", (Ptr*)&gQDPtr, &symClass);
		if (result != noErr)
			PLUGINDEBUGSTR("\pFailed in FindSymbol qd");
	}
	else
	{
		//
		// The app is 68K, so use its A5 to compute the address
		// of its QuickDraw globals.
		//
		//JMM gQDPtr = (QDGlobals*)(*((long*)SetCurrentA5()) - (sizeof(QDGlobals) - sizeof(GrafPtr)));
	}

}
#if defined ( __APPLE__ ) && defined ( __MACH__ )
static void* TV2FP (void *tvp) {
	static uint32 glue[6] = { 0x3D800000, 0x618C0000, 0x800C0000, 0x804C0004, 0x7C0903A6, 0x4E800420 };
	uint32 * newGlue = NULL ;

	if (tvp != NULL ) {
		newGlue = ( uint32 *) malloc (sizeof(glue));
		if (newGlue != NULL ) {
			memcpy(newGlue, glue, sizeof(glue));
			newGlue[0] |= ((UInt32)tvp >> 16);
			newGlue[1] |= ((UInt32)tvp & 0xFFFF);
			MakeDataExecutable(newGlue, sizeof(glue));
		}
	}
	return newGlue;
}
#else
#define TV2FP(foo) foo
#endif 

int main(NPNetscapeFuncs* nsTable, NPPluginFuncs* pluginFuncs, NPP_ShutdownUPP* unloadUpp);

#if TARGET_RT_MAC_CFM
#if !TARGET_API_MAC_CARBON
RoutineDescriptor mainRD = BUILD_ROUTINE_DESCRIPTOR(uppNPP_MainEntryProcInfo, main);
#else
#endif
#endif
 

int main(NPNetscapeFuncs* nsTable, NPPluginFuncs* pluginFuncs, NPP_ShutdownUPP* unloadUpp)
{
	EnterCodeResource();
	PLUGINDEBUGSTR("\pmain");

	__InitCode__();

	NPError err = NPERR_NO_ERROR;
	
	//
	// Ensure that everything Netscape passed us is valid!
	//
	if ((nsTable == NULL) || (pluginFuncs == NULL) || (unloadUpp == NULL))
		err = NPERR_INVALID_FUNCTABLE_ERROR;
	
	//
	// Check the �major� version passed in Netscape�s function table.
	// We won�t load if the major version is newer than what we expect.
	// Also check that the function tables passed in are big enough for
	// all the functions we need (they could be bigger, if Netscape added
	// new APIs, but that�s OK with us -- we�ll just ignore them).
	//
	if (err == NPERR_NO_ERROR)
	{
		if ((nsTable->version >> 8) > NP_VERSION_MAJOR)		// Major version is in high byte
			err = NPERR_INCOMPATIBLE_VERSION_ERROR;
//		if (nsTable->size < sizeof(NPNetscapeFuncs))
//			err = NPERR_INVALID_FUNCTABLE_ERROR;
//		if (pluginFuncs->size < sizeof(NPPluginFuncs))		
//			err = NPERR_INVALID_FUNCTABLE_ERROR;
	}
		
	
	if (err == NPERR_NO_ERROR)
	{
		//
		// Copy all the fields of Netscape�s function table into our
		// copy so we can call back into Netscape later.  Note that
		// we need to copy the fields one by one, rather than assigning
		// the whole structure, because the Netscape function table
		// could actually be bigger than what we expect.
		//
		
		int navMinorVers = nsTable->version & 0xFF;

		gNetscapeFuncs.version = nsTable->version;
		gNetscapeFuncs.size = nsTable->size;
                gNetscapeFuncs.version          = nsTable->version;
                gNetscapeFuncs.size             = nsTable->size;
                gNetscapeFuncs.posturl          = (NPN_PostURLUPP)TV2FP( nsTable->posturl);
                gNetscapeFuncs.geturl           = (NPN_GetURLUPP)TV2FP( nsTable->geturl);
                gNetscapeFuncs.requestread      = (NPN_RequestReadUPP)TV2FP( nsTable->requestread);
                gNetscapeFuncs.newstream        = (NPN_NewStreamUPP)TV2FP(nsTable->newstream);
                gNetscapeFuncs.write            = (NPN_WriteUPP)TV2FP(nsTable->write);
                gNetscapeFuncs.destroystream    = (NPN_DestroyStreamUPP)TV2FP( nsTable->destroystream);
                gNetscapeFuncs.status           = (NPN_StatusUPP)TV2FP(nsTable->status);
                gNetscapeFuncs.uagent           = (NPN_UserAgentUPP)TV2FP(nsTable->uagent);
                gNetscapeFuncs.memalloc         = (NPN_MemAllocUPP)TV2FP(nsTable->memalloc);
                gNetscapeFuncs.memfree          = (NPN_MemFreeUPP)TV2FP(nsTable->memfree);
                gNetscapeFuncs.memflush         = (NPN_MemFlushUPP)TV2FP(nsTable->memflush);
                gNetscapeFuncs.reloadplugins    = (NPN_ReloadPluginsUPP)TV2FP( nsTable->reloadplugins);
                if( navMinorVers >= NPVERS_HAS_LIVECONNECT ){ 
                        gNetscapeFuncs.getJavaEnv   = (NPN_GetJavaEnvUPP)TV2FP(nsTable->getJavaEnv);
                    gNetscapeFuncs.getJavaPeer  = (NPN_GetJavaPeerUPP)TV2FP( nsTable->getJavaPeer);
                
                
                }                                     
                if( navMinorVers >= NPVERS_HAS_NOTIFICATION ){ 
                        gNetscapeFuncs.geturlnotify     = (NPN_GetURLNotifyUPP)TV2FP( nsTable->geturlnotify);
                    gNetscapeFuncs.posturlnotify    = (NPN_PostURLNotifyUPP)TV2FP( nsTable->posturlnotify);
                
                }
                
                gNetscapeFuncs.getvalue         = (NPN_GetValueUPP)TV2FP( nsTable->getvalue);
                gNetscapeFuncs.setvalue         = (NPN_SetValueUPP)TV2FP( nsTable->setvalue);
                gNetscapeFuncs.invalidaterect   = (NPN_InvalidateRectUPP)TV2FP( nsTable->invalidaterect);
                gNetscapeFuncs.invalidateregion = (NPN_InvalidateRegionUPP)TV2FP( nsTable->invalidateregion);
                gNetscapeFuncs.forceredraw      = (NPN_ForceRedrawUPP)TV2FP( nsTable->forceredraw);
		
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
		SetUpQD();
		err = Private_Initialize();
	}
	
	ExitCodeResource();
	return err;
}
