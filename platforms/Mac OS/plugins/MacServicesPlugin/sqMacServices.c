/*
 *  sqMacServices.c
 *  SqueakServices
 *
 *  Created by John M McIntosh on 12/06/05.
 *
 */

#include "sqMacServices.h"
/*  The virtual machine proxy definition */
#include "sqVirtualMachine.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"

#include <pthread.h>


extern struct VirtualMachine *interpreterProxy;
static EventTargetRef myEventTarget=NULL;
static void *getSTWindow=NULL;
WindowPtr myDocumentWindow;

OSType	MyAppsDataTypes[64];
long	MyAppsDataTypesSize;
char *	myTextStringOut=NULL;
long	myTextStringOutLength=0;
char *	myTextStringIn=NULL;
long	myTextStringInLength=0;
ScrapRef        specificScrap=NULL; 
long	mySemaphore=0;
Boolean	gWaiting=false;

EventHandlerRef		myEventRef=NULL;

EventTypeSpec serviceEventList[] = {
        { kEventClassService, kEventServiceGetTypes },
        { kEventClassService, kEventServicePerform },
        { kEventClassService, kEventServiceCopy }, 
        { kEventClassService, kEventServicePaste } };

static pascal OSStatus MyServicesEventHandler (EventHandlerCallRef myHandlerChain,EventRef event, void* userData);
void makeItHideLogic();
void waitAFewMilliseconds();

int sqServicesInitialize() {
	if (myEventRef) 
		return 1;
	
	getSTWindow = interpreterProxy->ioLoadFunctionFrom("getSTWindow", "");
	if (getSTWindow == 0) {
		return 0;
	}
	myDocumentWindow = (WindowPtr) ((int (*) ()) getSTWindow)();
	myEventTarget = GetWindowEventTarget (myDocumentWindow);
	InstallApplicationEventHandler(NewEventHandlerUPP(MyServicesEventHandler), GetEventTypeCount(serviceEventList), serviceEventList, 0, &myEventRef);
	return 1;
}

int sqServicesShutdown() {
	if (myEventRef) 
		RemoveEventHandler(myEventRef);
	myEventRef = NULL;
	myTextStringInLength = 0;
	myTextStringOutLength = 0;
	if (myTextStringIn) {
		free(myTextStringIn);
		myTextStringIn = NULL;
	}
	if (myTextStringOut) {
		free(myTextStringOut);
		myTextStringOut = NULL;
	}

	return 1;
}

void sqServicesSetDataTypeslength(char *dataTypes, long dataTypesLength) {
	if (dataTypesLength > 256) 
		return;
	MyAppsDataTypesSize = dataTypesLength;
	memcpy(MyAppsDataTypes,dataTypes,MyAppsDataTypesSize);
}

void sqServicesSetSemaphore(int semi){
	mySemaphore = semi;
}

void sqServicesSetTextStringlength(char *aTextString, int stringLength){
	if (myTextStringOut != NULL) 
		free(myTextStringOut);
	myTextStringOutLength = stringLength;
	myTextStringOut = malloc(myTextStringOutLength+1);
	memcpy(myTextStringOut,aTextString,myTextStringOutLength);
	myTextStringOut[myTextStringOutLength] = 0x00;
}

void sqServicesSetReturnTextStringlength(char *aTextString, int stringLength){
	if(specificScrap == NULL) 
		return;
	ClearScrap (&specificScrap); 
	PutScrapFlavor (specificScrap, kScrapFlavorTypeText,kScrapFlavorMaskNone,stringLength,aTextString);
	gWaiting = false;
	specificScrap = NULL;
}


int sqServicesGetTextStringLength(void){
	return myTextStringInLength;
}

void sqServicesGetTextStringInto(char *buffer) {
	memcpy(buffer,myTextStringIn,myTextStringInLength);
}

static pascal OSStatus MyServicesEventHandler (EventHandlerCallRef myHandlerChain,
EventRef event, void* userData)
{
    UInt32 whatHappened;
	OSStatus result = eventNotHandledErr; /* report failure by default */

    whatHappened = GetEventKind(event);
    switch (whatHappened)
    {
        case kEventServiceGetTypes:
				{
				Boolean             textSelection = true; 
				CFMutableArrayRef   copyTypes, pasteTypes;
				short               index, count;
				if (textSelection)  {
					GetEventParameter (event, 
										kEventParamServiceCopyTypes, 
										typeCFMutableArrayRef, 
										NULL,
										sizeof (CFMutableArrayRef),
										NULL,
										&copyTypes);  
					}
				GetEventParameter (event, 
									kEventParamServicePasteTypes, 
									typeCFMutableArrayRef, 
									NULL,
									sizeof (CFMutableArrayRef), 
									NULL,
									&pasteTypes);  
				count = MyAppsDataTypesSize / sizeof (OSType); 
				for ( index = 0; index < count; index++ ) {
					CFStringRef type = 
								CreateTypeStringWithOSType (MyAppsDataTypes [index]); 
					if (type) {
						if (textSelection) 
								CFArrayAppendValue (copyTypes, type);  
						CFArrayAppendValue (pasteTypes, type); 
						CFRelease (type);  
						}
				}
				result = noErr; 
			}            
		break;
		case kEventServiceCopy:
				{
					OSStatus        status = noErr;
					ScrapRef        scrap;
												
					status = GetEventParameter (event,
												kEventParamScrapRef,
												typeScrapRef,
												NULL,
												sizeof (ScrapRef),
												NULL,
												&scrap ); 
					if (status != noErr) return result;
					status = ClearScrap (&scrap); 
					if (status != noErr) return result;
					status = PutScrapFlavor (scrap,
											kScrapFlavorTypeText,
											kScrapFlavorMaskNone,
											myTextStringOutLength,
											myTextStringOut); 
					if (status != noErr) return result;
					result = status; 
				}
		break;
		case kEventServicePaste:
			{
				OSStatus    status = noErr;
				ScrapRef    scrap;
											
				status = GetEventParameter (event,
										kEventParamScrapRef,
										typeScrapRef,
										NULL,
										sizeof (ScrapRef),
										NULL,
										&scrap); 
																							 
				if (status != noErr) return result;
				status = GetScrapFlavorSize (scrap, kScrapFlavorTypeText, &myTextStringInLength); 
				if (status != noErr) return result;
				if (myTextStringIn) 
					free(myTextStringIn);
				myTextStringIn = malloc (myTextStringInLength); 
				status = GetScrapFlavorData (scrap, kScrapFlavorTypeText, &myTextStringInLength, myTextStringIn ); 

				result = status; 
			}
		break;
		case kEventServicePerform:
			{
				OSStatus    status = noErr;
				CFStringRef     message; 
				
				status = GetEventParameter (event,          
								kEventParamServiceMessageName, 
								typeCFStringRef, 
								NULL,
								sizeof (CFStringRef),
								NULL,
								&message); 
				if (status != noErr) return result;
				status = GetEventParameter (event,         
								kEventParamScrapRef, 
								typeScrapRef, 
								NULL,
								sizeof (ScrapRef),
								NULL,
								&specificScrap); 
 				if (status != noErr) return result;
				status = GetScrapFlavorSize (specificScrap, kScrapFlavorTypeText, &myTextStringInLength); 
				if (status != noErr) return result;
				if (myTextStringIn) 
					free(myTextStringIn);
				myTextStringIn = malloc (myTextStringInLength); 
				status = GetScrapFlavorData (specificScrap, kScrapFlavorTypeText, &myTextStringInLength, myTextStringIn ); 
				if (status != noErr) return result;

				if (mySemaphore)
					interpreterProxy->signalSemaphoreWithIndex(mySemaphore);

				gWaiting = true;
				while(gWaiting)
					waitAFewMilliseconds();
				makeItHideLogic();
					
				result = status; 
		}
        break;
		default:
            break;
    }
	return result;
}

EventLoopTimerRef  ghideStupidApplication;
Boolean			ghideStupidApplicationNow=false;
static pascal void hideStupidApplication (EventLoopTimerRef theTimer,void* userData);

static pascal void hideStupidApplication (EventLoopTimerRef theTimer,void* userData) {
    if (ghideStupidApplicationNow ) {
		ProcessSerialNumber psn = { 0, kCurrentProcess };
		if (IsProcessVisible(&psn))
			ShowHideProcess( &psn, false );
		ghideStupidApplicationNow = false;
		RemoveEventLoopTimer(ghideStupidApplication);
	}
}

void makeItHideLogic(int foo)
{
    InstallEventLoopTimer (GetMainEventLoop(),
                       250*kEventDurationMillisecond,
                       kEventDurationMillisecond,
                       NewEventLoopTimerUPP(hideStupidApplication),
                       NULL,&ghideStupidApplication);
	ghideStupidApplicationNow = true;
}


pthread_mutex_t sleepLock;
pthread_cond_t  sleepLockCondition;
void waitAFewMilliseconds()
{
    static Boolean doInitialization=true;
    const int	   realTimeToWait = 16;
    struct timespec tspec;
    int err;
    
    if (doInitialization) {
        doInitialization = false;
        pthread_mutex_init(&sleepLock, NULL);
        pthread_cond_init(&sleepLockCondition,NULL);
    }

    tspec.tv_sec=  realTimeToWait / 1000;
    tspec.tv_nsec= (realTimeToWait % 1000)*1000000;
    
    err = pthread_mutex_lock(&sleepLock);
    err = pthread_cond_timedwait_relative_np(&sleepLockCondition,&sleepLock,&tspec);	
    err = pthread_mutex_unlock(&sleepLock); 
}

/*				PasteboardRef   pasteboard;
				PasteboardItemID    item;
				CFDataRef           sourceData;
    CFIndex             sourceSize;
    CFMutableDataRef    returnData = NULL;
    const UInt8*        sourceBytes;
    UInt8*              returnBytes;
    CFIndex i;
					status = GetEventParameter( event, kEventParamPasteboardRef, typePasteboardRef, 
									NULL, sizeof( pasteboard ), NULL, &pasteboard );
					if (status != noErr) return result;
					PasteboardSynchronize(pasteboard);
					
					status = PasteboardGetItemIdentifier( pasteboard, 1, &item );
					status = PasteboardCopyItemFlavorData( pasteboard, item,  CFSTR("com.apple.traditional-mac-plain-text"), &sourceData );
				   sourceSize = CFDataGetLength( sourceData );
					
					// create the translation's return data storage
					returnData = CFDataCreateMutable( kCFAllocatorDefault, sourceSize );        
					sourceBytes = CFDataGetBytePtr( sourceData );
					returnBytes = CFDataGetMutableBytePtr( returnData );
					for(i = 0; i< sourceSize; i++ )
							returnBytes[i] = ( UInt8 )toupper( sourceBytes[ i ] );        
					status = PasteboardClear( pasteboard );
					status = PasteboardPutItemFlavor( pasteboard, item,  CFSTR("com.apple.traditional-mac-plain-text"), returnData, kPasteboardFlavorNoFlags );
					PasteboardSynchronize(pasteboard);				
*/


/*
				status = GetScrapFlavorSize (specificScrap, kScrapFlavorTypeText, &myTextStringInLength); 
				if (status != noErr) return result;
				if (myTextStringIn) 
					free(myTextStringIn);
				myTextStringIn = malloc (myTextStringInLength); 
				status = GetScrapFlavorData (specificScrap, kScrapFlavorTypeText, &myTextStringInLength, myTextStringIn ); 
				if (status != noErr) return result;
				ClearScrap (&specificScrap); 
				myTextStringIn[0] = '!'; 
				status = PutScrapFlavor (specificScrap,kScrapFlavorTypeText,kScrapFlavorMaskNone,myTextStringInLength,myTextStringIn);
*/

