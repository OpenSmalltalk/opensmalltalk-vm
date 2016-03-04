#if TARGET_API_MAC_CARBON
#include <Carbon/Carbon.h>
#else
	#include <OpenTransport.h>
	#include <OpenTptInternet.h>
	#include <OpenTptClient.h>
	#if defined(__MWERKS__) 
		#include <stropts.h>
	#else
		#include <OpenTransportProviders.h>
	#endif
	#include <Gestalt.h>
	#include <TextUtils.h>
	#include <files.h>
	#if !TARGET_API_MAC_CARBON
	    #ifndef NewOTNotifyUPP
	    	typedef struct OTConfiguration* OTConfigurationRef;
	    	#define OTNotifyUPP OTNotifyProcPtr 
	    	#define NewOTNotifyUPP(userRoutine) userRoutine
	    	#define DisposeOTNotifyUPP(userRoutine)
	    #endif
	#endif
#endif
#include "sq.h"
#include "SocketPlugin.h"
//#define OTSERVER

/*  May 1st 2000
	An Open Transport 2.0 version of source code for TCP/IP & UDP support
	Some of this the code was descended from Apple sample source written by: Eric Okholm
	However getting it to work was done by
	John M Mcintosh of Corporate Smalltalk Consulting Ltd
	johnmci@smalltalkconsulting.com 
	http://www.smalltalkconsulting.com 
	In May of 2000 under contract to Disney
	
	Some of the original source code was written by John Maloney of Disney thoughout the 1990's
	
	The basic intent was to make the code fully interrupt driven
	No limits.... Well maybe we throttle read buffers to some parcel of memory to prevent us
	from using all the memory on the box. Sends depend on lowerlayer buffering/flow control.
	Testing from a 500Mhz PowerBook showed we could saturate a 100MB ethernet when sending data oneway.
	
	UDP and TCP/IP are all supported.
	Note for TCP we turn on two options IP_REUSEADDR, and IP_KEEPALIVE.
	We do NOT handle T_EXDATA  data
	
	V1.0 May 18th 2000, JMM (TCP/IP and UDP)
	V1.1 May 19th 2000, JMM Cleanup
	V1.2 may 20th 2000, JMM UDP free buffer cleanup, relook at resolver terminate to fix crash
	V1.3 may 23rd 2000, JMM fix T_UDERR crash
	V1.3.1 may 24th 2000, JMM UDP work
	V1.3.2 may 25th 2000, JMM socket options work
	V1.3.3 may 27th 2000, JMM rewrote resolver
	V1.3.4 Jun 7th 2000, JMM some integration
	V1.3.5 Jun 9th 2000, JMM Dan Ingalls found some interesting bugs with a T_GODATA on T_CONNECT.
	V1.3.6 Jun 10th 2000, JMM fix a fatal but in close/close pattern I made on the 9th.
	V1.3.7 Aug 1st 2000, JMM Some carbon work, reviewed open non-existent port logic fix so unavailable port causes immediate failure
	V1.3.8 Aug 29th 2000, JMM Fix problem with recusion on make me an EP.
	v1.3.9 Sept 28th 2000, JMM Problem with accept somewhere (so harden code)
	v1.3.10 Oct 4th 2000, JMM Issue with destory and free buffers, and disconnect on read with buffer restriction
	v1.3.11 Nov 11th 2000, JMM extra buffer for server version
	v1.3.12 Jan 2001, Karl Goiser Carbon changes
        v1.3.13 Sept 2002, JMM fixes for wildcard  port binding, and IP_ADD_MEMBERSHIP logic
	v1.4.00 Feb 2003, JMM watch out for async port fetch info not working under os-x
	V1.5.00 Dec 2003, JMM add sqSocketListenOnPortBacklogSizeInterface logic
	
	Notes beware semaphore's lurk for socket support. Three semaphores lives in Smalltalk, waiting for
	connect/disconnect/listen, sending data, and receiving data. When to tap the semaphore is based on
	inferences driven from the smalltalk code. We really need a call to tell us intent.
	
	waitForDisconnectUntil:
	    via closeAndDestroy: after primSocketCloseConnection:
	    
	waitForDataUntil:
	    Usually before primitiveSocketReceiveDataBufCount: after checking SocketReceiveDataAvailable
	    
	waitForSendDoneUntil:
	    via sendData: or sendSomeData:startIndex;count: before calls to primitiveSocketSendDataBufCount
	    
	waitForConnectionUntil:
	    via waitForAcceptUntil and many places afer doing primitiveSocketConnectToPort
*/				
				
/*** Socket Type Constants ***/
#define TCPSocketType 0
#define UDPSocketType 1
#define TCPListenerSocketType 2   //These are special to enable the right options for listening. Not Exposed to Smalltalk
#define UDPListenerSocketType 3   //Very special not really linked to an EP structure.  Not Exposed to Smalltalk

/*** Resolver Status Constants ***/
#define RESOLVER_UNINITIALIZED	0
#define RESOLVER_SUCCESS		1
#define RESOLVER_BUSY			2
#define RESOLVER_ERROR			3
#define RESOLVER_NAMETOADDR     4
#define RESOLVER_ADDRTONAME     5


/*** TCP Socket Status Constants ***/
#define InvalidSocket           -1
#define Unconnected				0
#define WaitingForConnection	1
#define Connected				2
#define OtherEndClosed			3
#define ThisEndClosed			4


	// Overall program states
enum
{
	kProgramRunning		= 1,
	kProgramDone		= 2
};


	// Bit numbers in EPInfo stateFlags fields
enum
{
	kOpenInProgressBit				= 0,  
	kUnConnected    				= 1,
	kWaitingForConnection           = 2,
	kConnected                      = 3,
	kSendIsBlocked                  = 4,
    kOtherEndClosed                 = 5,
    kThisEndClosed                  = 6,
	kPassconBit                     = 7

};

	// Bit numbers in EPInfo stateFlags2 fields
enum
{
	kFlushDisconnectInProgressBit	= 0,
	kMakeEPIdle                     = 1,
	kEPIsBroken                     = 2,
	kReadFlowControl                = 3,
	kPassconNeeded                  = 4,
	kTapSemaphore                   = 5,
	kTapSemaphoreReadData           = 6,
	kTapSemaphoreWriteData          = 7
};

	// Bit numbers in EPInfo stateFlags3 fields
enum
{
    kKeepAliveOptionNeeded          = 0,
    kSleepKilledMe                  = 1,
    kWaitingForBind                 = 2
}; 

enum
{
	kOTVersion111				= 0x01110000,
	kOTVersion112				= 0x01120000,
	kOTVersion113				= 0x01130000,
	kOTVersion130				= 0x01300000
};

const kTCPKeepAliveInMinutes		= 10;		// 10 minutes  keep alive
#ifdef OTSERVER
const kReadBuffersToAllocate	    = 256;		// Memory Allocation issue how big, this means 256x mtu size * 4 But for 68K we do 1/2 size
#else
const kReadBuffersToAllocate	    = 50;		// Memory Allocation issue how big, this means 50x mtu size * 4 But for 68K we do 1/2 size
#endif

	// Endpoint Info Structure

struct EPInfo
{
	EndpointRef		erf;				//	actual endpoint
	OTLink			link;				//	link into an OT LIFO (atomic)
	OTLink          globalLink;         //  link that follows all allocated EPs
    SInt32          outstandingSends;   //  number of sends outstanding
    OTList          readBuffers;        //  Read buffers
    SInt32          bytesPendingToRead; //  bytes outstanding to read
	SInt32			semaIndex;			//	semaphore index
	SInt32          readSemaIndex;      //  read semaphore
	SInt32          writeSemaIndex;     //  write semaphore
	SInt32          UDPMaximumSize;     //  max size if a UDP endpoint
	SInt32			lastError;          //  last error code
	UInt8			stateFlags;			//	various status fields
	UInt8			stateFlags2;		//	various status fields
	UInt8			stateFlags3;		//	various status fields
	UInt8           socketType;         //  type of socket, tcp, udp, or tcp/udp listener
	InetAddress     localAddress;       //  local address at bind time (ignored used call to get current)
	InetAddress     remoteAddress;      //  remote address at connect (ignored used call to get current)
	Boolean         UDPMoreFlag;        //  UDP more of datagram flag set
    };
typedef struct EPInfo EPInfo;

struct ReadBuffer                       // Structure to contain read data.
{
	OTLink			fNext;				//	link into an OT FIFO 
	UInt32          readBufferSize;
	UInt32			readBufferOriginalSize;  
	char *          readBufferData;
	char *          readBufferPtr;      //Sliding pointer used to partial read buffer.
    InetAddress     UDPAddress;         //UDP address
	Boolean         UDPMoreFlag;        //UDP more of datagram flag set
};
typedef struct ReadBuffer ReadBuffer;


struct TKeepAliveOpt                    
{
	UInt32		len;
	OTXTILevel	level;
	OTXTIName	name;
	UInt32		status;
	UInt32		tcpKeepAliveOn;
	UInt32		tcpKeepAliveTimer;
};
typedef struct TKeepAliveOpt TKeepAliveOpt;

struct TLingerOpt                    
{
	UInt32		len;
	OTXTILevel	level;
	OTXTIName	name;
	UInt32		status;
	UInt32		tcpLingerOn;
	UInt32		tcpLingerTimer;
};
typedef struct TLingerOpt TLingerOpt;

/*** Variables ***/

extern struct VirtualMachine *interpreterProxy;

EPInfo*				gDNSResolver;               //Our resolver
SInt32				gDNSResolverStatus 			= RESOLVER_UNINITIALIZED;
SInt32				gDNSResolverError			= noErr;
SInt32			    gDNSResolverSemaIndex;      //This gets changed at startup time.
InetHostInfo		gDNSHostInfo;
InetDomainName 		gDNSAddrStr;                //Length of domain names? Old code was 512, but specs say 256.
InetHost			gDNSAddr;
SInt32              gDNSLookupType;

OTConfigurationRef	gCfgMastertcp				= NULL;
OTConfigurationRef	gCfgMasterudp				= NULL;
OTConfigurationRef	gCfgMasterListener			= NULL;

OTLIFO				gFreeReadBuffersLIFO;    	//  Buffers that are free to read into
OTLIFO*				gFreeReadBuffers			= &gFreeReadBuffersLIFO;
SInt32				gFreeReadBuffersCounter		= 0;
SInt32				gSocketsAllocated			= 0;
UInt32				gmtuSize 					= 1024; //This gets changed at startup time.
SInt32				gthisNetSession 			= 0;    //This gets changed at startup time.
SInt32				gMaxConnections				= 0;    //This gets changed at startup time.
UInt32				gOTVersion;                         //Gets set to OT version, to help us with special cases.
SInt32				gProgramState				= 0;    //This gets changed at startup time.
OTClientContextPtr     gClientContext;

OTLIFO				gIdleEPLIFO[3];
OTLIFO*				gIdleEPs[3];
SInt32              gIdleEPCounter[3];
OTLIFO				gBrokenEPLIFO;
OTLIFO*				gBrokenEPs					= &gBrokenEPLIFO;
OTLIFO				gAllEPLIFO;
OTLIFO*				gAllEPs					    = &gAllEPLIFO;

OTNotifyUPP DNSNotifierUPP,NotifierSocketUPP,NotifierSocketUDPUPP,NotifierSocketListenerUPP;


/*** Private TCP Socket Functions ***/

/*** Private Resolver Functions ***/
static void 		ResolverInitialize();
static void		    ResolverTerminate(void);
static void 		ResolverStart ();

/*** Other Private Functions ***/
void               CFMTerminate (void);
static Boolean	   DestroyAllOpenSockets(void);
static Boolean	   SocketValid(SocketPtr s);
static Boolean     PortNumberValid(InetPort port) ;
static SInt32      unmapStatus(EPInfo *);
static void        Recycle();
static void        makeEPIdle(EPInfo *epi);
static void        purgeReadBuffers(EPInfo *epi);
static void        makeEPBrokenThenIdle(EPInfo* epi,OTResult error);
static void        makeEPBroken(EPInfo* epi,OTResult error);
static EPInfo*     getOrMakeMeAnEP(UInt8 aSocketType,short counter);
static Boolean     makeMeAnEP(UInt8 aSocketType);
static void        attemptToCloseAndDeleteThisEP (EPInfo *epi);
static void		   makeEPUnconnected(EPInfo* epi);
static void        SetEPLastError(EPInfo* epi,OTResult error);
static void        TapAllInterestedSemaphores(EPInfo *epi);
int 				socketInit(void);
int 				socketShutdown(void);


static pascal void  DNSNotifier(void* context, OTEventCode event, OTResult result, void* cookie);
static pascal void  NotifierSocket(void* context, OTEventCode event, OTResult result, void* cookie);
static pascal void  NotifierSocketUDP(void* context, OTEventCode event, OTResult result, void* cookie);
static pascal void  NotifierSocketListener(void* context, OTEventCode event, OTResult result, void* cookie);
static SInt32       internalSocketCreate(SocketPtr s, SInt32 netType, SInt32  socketType, SInt32 recvBufSize, SInt32 sendBufSize, SInt32 semaIndex, SInt32 readSemaIndex, SInt32 writeSemaIndex, UInt8 aExtraSocketHint);
static Boolean		EPOpen(EPInfo* epi);
static Boolean 		EPClose(EPInfo*);
static void         DoListenAccept(EPInfo* acceptor,EPInfo* theServer);
static void         DoConnect(EPInfo* epi,InetHost addr, InetPort port);
static void         DoBind(EPInfo* epi,InetHost addr, InetPort port,UInt8 aExtraSocketHint, OTQLen queueDepth );
static UInt32       ReadData(EPInfo* epi, char* specialBuffer, UInt32 specialBufferSize);
static OTResult     SendData(EPInfo* epi, char* buffer, UInt32 size);
static OSStatus     doAbortConnection(EPInfo* epi);
static void         NoCopyReceiveWalkingBufferChain(EPInfo *epi,OTBufferInfo *bufferInfo);
static UInt32       readBytes(EPInfo* epi,char *buf,UInt32 adjustedBufSize);
static UInt32       readBytesUDP(EPInfo* epi,InetAddress *fromAddress, int *moreFlag, char *buf,UInt32 adjustedBufSize);
static SInt32	    lookupOptionName(EPInfo *epi, Boolean trueIfGet, char *aString, UInt32 value, SInt32 *result);
static OTResult     SetEightByteOption(EPInfo* epi, Boolean trueIfGet, OTXTILevel level,  OTXTIName  name, char * value, SInt32    *result);
static OTResult     SetFourByteOption(EPInfo* epi, Boolean trueIfGet, OTXTILevel level,  OTXTIName  name, UInt32 value, SInt32    *result);
static OTResult     SetOneByteOption(EPInfo* epi, Boolean trueIfGet, OTXTILevel level,  OTXTIName  name, UInt32 value, SInt32    *result);
static OTResult     SetKeepAliveOption(EPInfo* epi, Boolean trueIfGet, OTXTILevel level,  OTXTIName  name, UInt32 value, SInt32    *result);
static OTResult     SetLingerOption(EPInfo* epi, Boolean trueIfGet, OTXTILevel level,  OTXTIName  name, UInt32 value, SInt32    *result);

// Some diagnostic routines

void JMMLogMessage(Str255 input);
void JMMLogMessageAndNumber(Str255 msg,long number);
void JMMWriteLog();

/*** Network Functions ***/

int socketInit() {
	//
	//Don't actually do any network work until we are newworked initialized
	//This prevents kicking off internet dialup connections until needed
	//
	return true;
}

int socketShutdown() {
	CFMTerminate();
	return true;
}

int sqNetworkInit(int resolverSemaIndex) {

	//
	//  Initialize the network and return 0 if successful
	//  Loads Open transport, allocates memory for read buffers and various other tasks
	//
	
	SInt32              i;
	OSStatus            err = noErr;
	InetInterfaceInfo   interfaceInformation;
	UInt8               aSocketType;
    ReadBuffer          *readBufferObject;
    long				check68KorPPC;
	    
	if (gthisNetSession != 0) return 0;  /* noop if network is already initialized */
	

#if TARGET_API_MAC_CARBON
	err = InitOpenTransportInContext (kInitOTForExtensionMask, &gClientContext);
#else
	err = InitOpenTransport(); 
#endif
	if (err) return -1;

		
	err = Gestalt(gestaltOpenTptVersions, (long*) &gOTVersion);
	
	if (err || (gOTVersion < kOTVersion112))
	{
		// Please install Open Transport 1.1.2 or later
		// This might change to 1.3 since tech notes talked about 
		// previous versions having problems with acksend logic.
		//
		return -111;
	}
	
	err = Gestalt(gestaltSysArchitecture, (long*) &check68KorPPC);
	gProgramState = kProgramRunning;

    // 
    //Setup the head of the idle queues
    //
    
	for (i=0;i<3;i++) {
	    gIdleEPs[i] = &gIdleEPLIFO[i];
	    gIdleEPs[i]->fHead	   = NULL;
	    gIdleEPCounter[i]      = 0;
	}
	gBrokenEPs->fHead 		= NULL;
	gFreeReadBuffers->fHead = NULL;
	gAllEPs->fHead          = NULL;
	
	
	gMaxConnections			= 24; // Build 8 of each of listeners, tcp, udp.
	
    DNSNotifierUPP = NewOTNotifyUPP(DNSNotifier);
    NotifierSocketUPP = NewOTNotifyUPP(NotifierSocket);
    NotifierSocketUDPUPP = NewOTNotifyUPP(NotifierSocketUDP);
    NotifierSocketListenerUPP = NewOTNotifyUPP(NotifierSocketListener);

	
#if TARGET_API_MAC_CARBON
	gDNSResolver = (EPInfo*) OTAllocMemInContext(sizeof(EPInfo), gClientContext);
#else
	gDNSResolver = (EPInfo*) OTAllocMem(sizeof(EPInfo));
#endif
	if (gDNSResolver == NULL) return -1;
		
	gDNSResolverSemaIndex = resolverSemaIndex;
	ResolverInitialize();
	
	/* Get MTU and default selected host address */
	
	OTInetGetInterfaceInfo (&interfaceInformation,kDefaultInetInterface);
    gmtuSize = interfaceInformation.fIfMTU;
    
	
	//
	//	Open endpoints 
	//
	gCfgMastertcp = OTCreateConfiguration(kTCPName);
	if (gCfgMastertcp == NULL) return -3;
	
	gCfgMasterudp = OTCreateConfiguration(kUDPName);
	if (gCfgMasterudp == NULL) return -4;
	
	gCfgMasterListener = OTCreateConfiguration("tilisten, tcp"); //Note use of special tilisten logic
	if (gCfgMasterListener == NULL) return -5;
	
	//
	//Build all our EPs, lots of work happens lower down asyncronously
	//
	aSocketType = TCPSocketType;
	for (i = 0; i < gMaxConnections; i++)	{
		makeMeAnEP(aSocketType);
		aSocketType = ++aSocketType > 2 ? TCPSocketType : aSocketType;
	} 
	
#ifdef OTSERVER
	for (i = 0; i < 256; i++)	{
		makeMeAnEP(TCPSocketType);
	} 
#endif

	//
	//Build storage objects for read buffers
	//How much memory to allocate still is a mystery
	//
    for (i=0;i<kReadBuffersToAllocate ;i++) { 
#if TARGET_API_MAC_CARBON
        readBufferObject = OTAllocMemInContext(sizeof(ReadBuffer), gClientContext);
#else
        readBufferObject = OTAllocMem(sizeof(ReadBuffer));
#endif
        if (readBufferObject == nil) {
       	    interpreterProxy->success(false);
            return -25;
        } 
        
        OTMemzero(readBufferObject,sizeof(ReadBuffer));
        if (gestalt68k == check68KorPPC) 
        	readBufferObject->readBufferOriginalSize = (gmtuSize > 0) ? gmtuSize*2 : 1024;
        else
        	readBufferObject->readBufferOriginalSize = (gmtuSize > 0) ? gmtuSize*4 : 1024;
        
#if TARGET_API_MAC_CARBON
       readBufferObject->readBufferData = readBufferObject->readBufferPtr = OTAllocMemInContext(readBufferObject->readBufferOriginalSize, gClientContext);
#else
       readBufferObject->readBufferData = readBufferObject->readBufferPtr = OTAllocMem(readBufferObject->readBufferOriginalSize);
#endif
        if ( readBufferObject->readBufferData == nil) {
       	    interpreterProxy->success(false);
            return -25;
        }

        OTLIFOEnqueue(gFreeReadBuffers, &readBufferObject->fNext);
		gFreeReadBuffersCounter++;
    }


	/* Success! Create a session ID that is unlikely to be
	   repeated. Zero is never used for a valid session number.
	*/
	gthisNetSession = interpreterProxy->getThisSessionID();

	return 0;
}


void CFMTerminate (void)    /* termination either via a CFM or Squeak call*/
{ 
    sqNetworkShutdown();
}


void sqNetworkShutdown(void) {
	/* shut down the network */
    
	if (gthisNetSession == 0) return;  /* noop if network is already shut down */
	gthisNetSession = 0;
	gProgramState = kProgramDone;
	DestroyAllOpenSockets();
#if TARGET_API_MAC_CARBON
	CloseOpenTransportInContext(gClientContext); 
#else
	CloseOpenTransport(); 
#endif
}


/*** Resolver Functions ***/


static void	ResolverInitialize() 
{
	OSStatus err;
	
	//
	//	Prepare to open internet services
	//  to invoke DNR services
	//
	
	OTMemzero(gDNSResolver, sizeof(EPInfo));	
#if TARGET_API_MAC_CARBON
    gDNSResolver->erf = OTOpenInternetServicesInContext(kDefaultInternetServicesPath, 0, &err, gClientContext);
#else
    gDNSResolver->erf = OTOpenInternetServices(kDefaultInternetServicesPath, 0, &err);
#endif
    gDNSResolver->semaIndex = gDNSResolverSemaIndex;
	
	if (err != kOTNoError) {
		gDNSResolverStatus = RESOLVER_ERROR;
		gDNSResolverError = err;
		return;
	}
	gDNSResolverStatus = RESOLVER_SUCCESS;
	gDNSResolverError = kOTNoError;

    err =  OTSetAsynchronous(gDNSResolver->erf);
    err =  OTSetNonBlocking(gDNSResolver->erf);
    err =  OTInstallNotifier(gDNSResolver->erf, DNSNotifierUPP, gDNSResolver);
}

static void ResolverStart () {
	OSStatus err;
	//
	// Invoke DNR service Async, this meants the DNSNotifier will handle the actual 
	// lookup and work, flags like the gDNSResolverStatus are used to indicate back
	// to Squeak when the work is done
	//
	if (gDNSResolver->erf == NULL) //Sleep fix, other endpoints are more explicit about this issue. 
	    ResolverInitialize();
	    
	gDNSResolverStatus  = RESOLVER_BUSY;
	switch (gDNSLookupType) {
		case RESOLVER_NAMETOADDR: {
		    err = OTInetStringToAddress((InetSvcRef)gDNSResolver->erf, gDNSAddrStr, &gDNSHostInfo);
			break;
		}
		case RESOLVER_ADDRTONAME: {
			err = OTInetAddressToName((InetSvcRef)gDNSResolver->erf, gDNSAddr, gDNSAddrStr);
			break;
		}
    }
	if (err != kOTNoError)  {
		gDNSResolverStatus = RESOLVER_ERROR;
		gDNSResolverError = err;
	}
}

void ResolverTerminate(void) {
    //JMM if the resolver is opening what happens?
 	gDNSResolverStatus = RESOLVER_UNINITIALIZED;
   
	if (gDNSResolver->erf == NULL) return;
	EPClose(gDNSResolver);
	OTMemzero(gDNSResolver, sizeof(EPInfo));
}

void sqResolverAbort(void) {
	//
	// Abort this running resolver request
	//

	if (gDNSResolverStatus == RESOLVER_BUSY) {
		ResolverTerminate();
		ResolverInitialize();
	}
}

void sqResolverAddrLookupResult(char *nameForAddress, int nameSize) {
	//
	// copy the name found by the last address lookup into the given string 
	//
	
	OTMemcpy(nameForAddress, gDNSAddrStr, (UInt32) nameSize);
	
}

int sqResolverAddrLookupResultSize(void) {
	//
	// return the length of the looked up name
	//
	return (long) strlen(gDNSAddrStr);
}

int sqResolverError(void) {
	//
	// Return OT error number
	//
	return gDNSResolverError; 
}

int sqResolverLocalAddress(void) {
    //
    // Watch out for dynamic changing of this information, so don't cache
    //
	InetInterfaceInfo interfaceInformation;

	OTInetGetInterfaceInfo (&interfaceInformation,kDefaultInetInterface);
	gDNSResolverStatus = RESOLVER_SUCCESS;
	gDNSResolverError  = noErr;
	return (long) interfaceInformation.fAddress;
}

int sqResolverNameLookupResult(void) {
	//
	// Return address from last lookup
	//
    
	return (int) gDNSAddr;
}

void sqResolverStartAddrLookup(int address) {
	//
	// start process to lookup name from address
	//
    
	if (gDNSResolverStatus == RESOLVER_BUSY) return;

	gDNSAddr            = (InetHost) address;
    gDNSLookupType      = RESOLVER_ADDRTONAME;
	ResolverStart();
}

void sqResolverStartNameLookup(char *hostName, int nameSize) {
	//
	// start process to lookup address from name
	//
    
	UInt32 len; 

	if (gDNSResolverStatus == RESOLVER_BUSY) return;

	len = (UInt32) ((nameSize <= kMaxHostNameLen) ? nameSize : kMaxHostNameLen);  //Old limit was 500  but that appeared to be wrong
	OTMemcpy(gDNSAddrStr, hostName, len);
	gDNSAddrStr[len]    = '\0';
    gDNSLookupType      = RESOLVER_NAMETOADDR;
	ResolverStart();
	
}

int sqResolverStatus(void) {
	//
	// return resolver status, this is different from resolver error code
	// status is the same among implementations, error is implementation dependent
	//
    
	return gDNSResolverStatus;
}

//================================

// Socket logic 
//

void	sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaID(
			SocketPtr s, int netType, int socketType,
			int recvBufSize, int sendBufSize, int semaIndex) {
			
	//
	//Old call from old image using new VM
	//Just make new call
	//
	sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(
  		 s,  netType,  socketType, recvBufSize,  sendBufSize,  semaIndex,  semaIndex,  semaIndex);
}

void sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(
  SocketPtr s, int netType, int socketType,
  int recvBufSize, int sendBufSize, int semaIndex, int readSemaIndex, int writeSemaIndex)	{
     OSErr error; 
     netType; recvBufSize; sendBufSize;
    
    
    //
    //Create a socket given the supplied information
    //We don't bind the socket to a local port  until 
    //we do the connection. This of course could change? 
    //
    
    error = internalSocketCreate( s, netType, socketType, recvBufSize,  sendBufSize, semaIndex, readSemaIndex, writeSemaIndex, (UInt8) socketType);
    if (error != noErr) {
		interpreterProxy->success(false); 
        return;   
    }

}

static SInt32 internalSocketCreate(
  SocketPtr s, SInt32 netType, SInt32 socketType,
  SInt32 recvBufSize, SInt32 sendBufSize, SInt32 semaIndex, SInt32 readSemaIndex, SInt32 writeSemaIndex, UInt8 aExtraSocketHint)	{
  //
  // Internal logic to open a socket for a connection or to listen
  // Note how we ignore buffer sizes!
  //
    EPInfo*     epi;
    socketType; netType; recvBufSize; sendBufSize;
    
    //
    //Make the socket invalid and then get an idle EP
    //Technically we only run out of EP when we run out of memory
    //
    
	s->sessionID = 0;
	if (gProgramState != kProgramRunning ) {		
	    interpreterProxy->success(false);
        return -1;
    }

	epi = getOrMakeMeAnEP(aExtraSocketHint,0);
	if (epi == NULL) {
		interpreterProxy->success(false);
		return -1;
	}

	epi->outstandingSends   = 0;
	epi->bytesPendingToRead = 0;
	epi->semaIndex          = semaIndex;
	epi->readSemaIndex      = readSemaIndex;
	epi->writeSemaIndex     = writeSemaIndex;
	epi->stateFlags         = 0;
	epi->stateFlags2        = 0;
	epi->stateFlags3        = 0;
	SetEPLastError(epi,noErr);
	epi->socketType        = aExtraSocketHint;
	OTInitInetAddress(&epi->remoteAddress, 0, 0);
    OTInitInetAddress(&epi->localAddress, 0, 0);
    
    if (aExtraSocketHint == UDPSocketType)
        OTAtomicSetBit(&epi->stateFlags, kConnected); //udp is always connected
     else
        OTAtomicSetBit(&epi->stateFlags, kUnConnected);
 
 	s->sessionID            = gthisNetSession;
	s->socketType           = (aExtraSocketHint == UDPSocketType) ? UDPSocketType : TCPSocketType;
	s->privateSocketPtr     = epi;
	gSocketsAllocated++;
	return 0;
}

void sqSocketListenOnPort(SocketPtr s, int port) {
    //
    //Listen on port for a connection, this is not the approved method
    //sqSocketListenOnPortBacklogSize is the best way if you are a server
    //However this works ok for UDP and kinda for onetime connections in TCP
    //
    EPInfo* epi;

	if (!SocketValid(s) || !PortNumberValid((InetPort) port)) return;
	epi = (EPInfo *) s->privateSocketPtr;
	if (s->socketType == TCPSocketType) {
		DoBind(epi,0,(InetPort) port,TCPListenerSocketType,1);
		if (port != 0 && epi->localAddress.fPort != port) {//We die if we don't get the port we want
            sqSocketDestroy(s);
    	    interpreterProxy->success(false);
		}
	} else {//udp
		DoBind(epi,0,(InetPort) port,UDPListenerSocketType,1);
	}

}
void	sqSocketListenOnPortBacklogSize(SocketPtr s, int port, int backlogSize) {
	sqSocketListenOnPortBacklogSizeInterface(s, port, backlogSize, 0);
}

void	sqSocketListenOnPortBacklogSizeInterface(SocketPtr s, int port, int backlogSize, int addr) {

    EPInfo* epi;
	SInt32 sema,readSema,writeSema;
	OSErr error;
    //
    //Listen on port for a connection, this is the best method if you are
    //a server. Works in conjunction with accept. Shouldn't drop connections
    //OT's special listener logic queues up the listen requestions
    //
	if (!SocketValid(s) || !PortNumberValid((InetPort) port)) return;
	if (s->socketType == TCPSocketType) {
		epi = (EPInfo *) s->privateSocketPtr;
		sema = epi->semaIndex; readSema = epi->readSemaIndex; writeSema = epi->writeSemaIndex;
	    makeEPIdle(epi); //Special case really need a listener EP, so put this EP back on the queue
	    				 //This may seem odd but the epi is allocated before we know what type it is.
	    				 //Would need to change Squeak to indicate type at creation!
		error = internalSocketCreate( s, 0, TCPSocketType, 0,  0, sema, readSema, writeSema, TCPListenerSocketType);
		if (error != noErr) {
            interpreterProxy->success(false); 
            return;   
		}
        epi = (EPInfo *) s->privateSocketPtr;
		DoBind(epi,addr,(InetPort) port,TCPListenerSocketType,(OTQLen) backlogSize);
		if (port != 0 && epi->localAddress.fPort != port) {//The port we wanted must match, otherwise we die
		    sqSocketDestroy(s);
    	    interpreterProxy->success(false);
		}
	} else {//udp not allowed
       	    interpreterProxy->success(false);
	}
}

void	sqSocketAcceptFromRecvBytesSendBytesSemaID(
			SocketPtr s, SocketPtr serverSocket,
			int recvBufSize, int sendBufSize, int semaIndex){
	//
	//Old call from old image using new VM
	//Just make new call
	//

	sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(
			 s,  serverSocket,  recvBufSize,  sendBufSize,  semaIndex,  semaIndex,  semaIndex);
		
}
void	sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(
			SocketPtr s, SocketPtr serverSocket,
			int recvBufSize, int sendBufSize, int semaIndex, int readSemaIndex, int writeSemaIndex) {
	//
	//Accept incoming request from a listener
	//We take information from the listener, create a new socket
	//and accept the incoming call
	//
	
    EPInfo* epiSocket;
    EPInfo* epiServerSocket;
    Boolean	doLeave;
    OSErr   error;
    long	count=0;
    
	if (!SocketValid(serverSocket)) return;
	if (serverSocket->socketType == TCPSocketType) {
            error = internalSocketCreate( s, 0, TCPSocketType, recvBufSize,  sendBufSize, semaIndex, readSemaIndex, writeSemaIndex, TCPSocketType);
		    if (error != noErr) {
        		interpreterProxy->success(false); 
		        return;   
		    }
		    epiSocket = (EPInfo *) s->privateSocketPtr;
    		DoBind(epiSocket,0,0,TCPSocketType,0); // interrupt driven to  T_TBINDCOMPLETE
    		while (count++ < 100 && (OTAtomicTestBit(&epiSocket->stateFlags3, kWaitingForBind) == true)) {
#ifndef TARGET_API_MAC_CARBON
			    SystemTask();
#endif
			    OTIdle();
            }
		    OTAtomicSetBit(&epiSocket->stateFlags2, kPassconNeeded);
		    epiServerSocket = (EPInfo *) serverSocket->privateSocketPtr;
			OTAtomicSetBit(&epiServerSocket->stateFlags, kWaitingForConnection);
			OTAtomicSetBit(&epiServerSocket->stateFlags, kUnConnected);
            OTAtomicClearBit(&epiServerSocket->stateFlags, kConnected);
    	    OTAtomicSetBit(&epiServerSocket->stateFlags2, kTapSemaphore);
        	
        	doLeave = OTEnterNotifier(epiServerSocket->erf);
        	DoListenAccept(epiSocket,epiServerSocket);
        	if (doLeave)
        		OTLeaveNotifier(epiServerSocket->erf);
	} else { //udp
		interpreterProxy->success(false); 
	}
}

void sqSocketConnectToPort(SocketPtr s, int addr, int port) {
    //
    //Connect this socket to the given host addr and port
    //
    EPInfo* epi;
	OTResult	epState;

	if (!SocketValid(s) || !PortNumberValid((InetPort) port)) return;
	epi = (EPInfo *) s->privateSocketPtr;
	if (s->socketType == TCPSocketType) {
    	DoBind(epi,(InetHost) addr,(InetPort) port,TCPSocketType,0); // interrupt driven to  T_TBINDCOMPLETE which drives T_CONNECT/DoConnect
	} else {//udp
		epState = OTGetEndpointState(epi->erf);
		if (epState == T_UNBND) {//Bind to remote, our side gets wildcarded
    	    DoBind(epi,(InetHost) addr,(InetPort) port,UDPSocketType,0); // interrupt driven to  T_TBINDCOMPLETE which drives T_CONNECT/DoConnect
    	} else {//Already bound to a port/interface on our side
    	    OTInitInetAddress(&epi->remoteAddress, (InetPort) port, (InetHost) addr);
    	}
	}
}


int sqSocketSendDataBufCount(SocketPtr s, char * buf, int bufSize) {
	//
	// Send data really fast
	// We create a copy of the data and give it to OT to play with
	// We can get flow controlled lower down, if no flow control then we
	// tap the semiphore since from squeaks viewpoint data is sent, otherwise when flow control is lifted the
	// semaphore is tapped in the notification routine
	//
	OTResult res ;
    EPInfo* epi;
    Boolean doLeave;
    char * buffer;
 	UInt32 adjustedBufSize = bufSize > 65536 ? 65536 : (UInt32) bufSize; //? Not sure if we really need to do this limiting.
   	
	if (!SocketValid(s)) return -1;
	
	epi = (EPInfo *) s->privateSocketPtr;
	
	// If send is blocked wait for unblocking
	if (OTAtomicTestBit(&epi->stateFlags, kSendIsBlocked)) {
	    return 0;
	}

    if (epi->socketType == UDPSocketType) {
        //UDP adjust the buffer size again
        adjustedBufSize = (adjustedBufSize > epi->UDPMaximumSize) ?   epi->UDPMaximumSize : adjustedBufSize;
     }

#if TARGET_API_MAC_CARBON
	buffer = OTAllocMemInContext(adjustedBufSize, gClientContext);
#else
	buffer = OTAllocMem(adjustedBufSize);
#endif
	if (buffer == nil) {
		//Well maybe we back off and wait awhile? 
		//If we run out of memory and stress the box, well death lurks.
		adjustedBufSize = 256;
#if TARGET_API_MAC_CARBON
		buffer = OTAllocMemInContext(adjustedBufSize, gClientContext);
#else
		buffer = OTAllocMem(adjustedBufSize);
#endif
		if (buffer == nil) {
		    interpreterProxy->success(false); //Death did lurk
	        SetEPLastError(epi, -1);
	        return -1;
	    } 
	}
		
	OTMemcpy(buffer,(void*) buf,adjustedBufSize);
    
	doLeave = OTEnterNotifier(epi->erf);  //Avoid race condition for T_GODATA
    res = SendData(epi,buffer,adjustedBufSize);  	
  	if (doLeave)
		OTLeaveNotifier(epi->erf);
		
  	if (res < 0 ){
	    SetEPLastError(epi, res);
		interpreterProxy->success(false); //JMM just for testing
	    return 0;
	}
	return res;
}

//
//New primitive for sending UDP data to a particular host/port
//Avoids race conditions between binding and send in Smalltalk
//

int sqSockettoHostportSendDataBufCount(SocketPtr s, int address, int port, char * buf, int bufSize) {
 sqSocketConnectToPort(s, address, port);
 return sqSocketSendDataBufCount(s, buf, bufSize);
}

//
//Abort the socket
//
void sqSocketAbortConnection(SocketPtr s) {
    EPInfo* epi;
   OSStatus err;
 
	if (!SocketValid(s)) return;
    if (s->socketType == UDPSocketType) {
		interpreterProxy->success(false); 
        return;
    }
	epi = (EPInfo *) s->privateSocketPtr;
	err = doAbortConnection(epi);
}

//
//Acutal abort logic
//We need to flush the queues
//Then do a disconnect
//
static OSStatus doAbortConnection(EPInfo* epi) {
   SInt32		count = 0;
   OSStatus     err = kOTNoError;
 
	if ( OTAtomicSetBit(&epi->stateFlags2, kFlushDisconnectInProgressBit) == 0 ) {
		//Do flush and wait for it to happen
		//Should make sync?
		//
		if (epi->outstandingSends != 0) {
		    err = OTIoctl(epi->erf, I_FLUSH, (void *)FLUSHRW);
		    while (count++ < 100 && (epi->outstandingSends != 0 || OTAtomicTestBit(&epi->stateFlags, kUnConnected) == false)) {
			    OTIdle();
            }
	    }
        makeEPBroken(epi,0);
	    err = OTSndDisconnect(epi->erf, NULL);
	}
	    
	if (err != kOTNoError) 
	    return err;
	else
        return epi->lastError;
}

//
//Socket close logic
//
void sqSocketCloseConnection(SocketPtr s) {
    EPInfo* epi;
    OSStatus err; 
	OTResult	epState;
	OTResult	lookResult;
    
	if (!SocketValid(s)) return;
	epi = (EPInfo *) s->privateSocketPtr;
    if (s->socketType == UDPSocketType) {//Handle udp and return
        OTAtomicClearBit(&epi->stateFlags, kThisEndClosed);
        OTAtomicClearBit(&epi->stateFlags, kConnected);
        OTAtomicClearBit(&epi->stateFlags, kOtherEndClosed);
        OTAtomicSetBit(&epi->stateFlags, kUnConnected);
        OTAtomicSetBit(&epi->stateFlags2, kTapSemaphore);
		err = OTUnbind(epi->erf);
		if (err != kOTNoError) { //kOTLookErr with T_DATA, book says response is to zap EP.
		    makeEPBroken(epi,err);
		}
	    TapAllInterestedSemaphores(epi);
	    return;
    }

    OTAtomicSetBit(&epi->stateFlags, kThisEndClosed);
    OTAtomicSetBit(&epi->stateFlags2, kTapSemaphore);
	// old code is sync and doesn't trigger semaphore 
	
	epState = OTGetEndpointState(epi->erf);
	if (epState == T_UNINIT || epState == T_UNBND ) {
        OTAtomicSetBit(&epi->stateFlags, kThisEndClosed);
        OTAtomicClearBit(&epi->stateFlags, kConnected);
        OTAtomicClearBit(&epi->stateFlags, kOtherEndClosed);
 	    TapAllInterestedSemaphores(epi);
	    return;
	}
	else
	    err = OTSndOrderlyDisconnect(epi->erf);
	    
	if (err == kOTNoError) {
        if (OTAtomicTestBit(&epi->stateFlags, kOtherEndClosed)) {
	        OTAtomicClearBit(&epi->stateFlags, kThisEndClosed);
	        OTAtomicClearBit(&epi->stateFlags, kConnected);
	        OTAtomicClearBit(&epi->stateFlags, kOtherEndClosed);
	        OTAtomicSetBit(&epi->stateFlags, kUnConnected);
	        if (epi->outstandingSends != 0)
	            doAbortConnection(epi);

			err = OTUnbind(epi->erf);
			if (err != kOTNoError) { //kOTLookErr with T_DATA, book says response is to zap EP.
			    makeEPBroken(epi,err);
			}
    	    TapAllInterestedSemaphores(epi);
        }
	} else {// Could get kOTLookErr with T_DISCONNECT pending 
		lookResult = OTLook(epi->erf); 
		if (err == kOTLookErr && lookResult == T_DISCONNECT) {
        	err = OTRcvDisconnect(epi->erf, NULL);
	        OTAtomicClearBit(&epi->stateFlags, kThisEndClosed);
	        OTAtomicClearBit(&epi->stateFlags, kConnected);
	        OTAtomicClearBit(&epi->stateFlags, kOtherEndClosed);
	        OTAtomicSetBit(&epi->stateFlags, kUnConnected);
	        if (epi->outstandingSends != 0)
	            doAbortConnection(epi);

			err = OTUnbind(epi->erf);
			if (err != kOTNoError) { //kOTLookErr with T_DATA, book says response is to zap EP.
			    makeEPBroken(epi,err);
			}
    	    TapAllInterestedSemaphores(epi);
        }
        else {
            SetEPLastError(epi,err);
    		makeEPBroken(epi,err);
            TapAllInterestedSemaphores(epi);
       }
	}
}

//
//Destroy the socket here we must ensure we cleanup and put the 
//socket back on the idle or broken EP queue
//
void sqSocketDestroy(SocketPtr s) {
    OTResult err;
    EPInfo* epi;
	OTResult	epState;

    JMMWriteLog(); //Diagnostics, turned off, must fiddle recompile to turn on.
    
  
    if (!SocketValid(s)) {
    	return; 
    }
	epi = (EPInfo *) s->privateSocketPtr;
   OTAtomicSetBit(&epi->stateFlags2, kMakeEPIdle); 
	epState = OTGetEndpointState(epi->erf);
	if (epState == T_UNINIT || epState == T_UNBND ) {
	    makeEPIdle(epi); //Unbound already so make him idle.
	} else {
	    if (s->socketType == UDPSocketType)
			err = OTUnbind(epi->erf);
	    else 
		    err = doAbortConnection(epi);
	
		if (err != kOTNoError) {//kOTLookErr with T_DATA, book says response is to zap EP.
		    makeEPBrokenThenIdle(epi,err);
		}
	}
	purgeReadBuffers(epi); //JMM Oct 4th 2000 (bug?)
	s->sessionID = 0;
	s->socketType = -1;
	s->privateSocketPtr = nil;
	gSocketsAllocated--;
 }

//
//Check to see if bytes are available
//
int sqSocketReceiveDataAvailable(SocketPtr s)							
{
    EPInfo* epi;
    static lastTickCount=0;

	if (!SocketValid(s)) return 0;
    epi = (EPInfo *) s->privateSocketPtr;
    if (epi->bytesPendingToRead > 0) 
        return 1;
   
    if (OTAtomicTestBit(&epi->stateFlags2, kReadFlowControl)) // New case if data pending but flow controlled then go get it
        return 1;
    
    OTAtomicSetBit(&epi->stateFlags2, kTapSemaphoreReadData); //Note how we imply there will be interest in semaphore
    return 0;
}


//
//Read data into the buffer supplied
//
int sqSocketReceiveDataBufCount(SocketPtr s, char * buf, int bufSize) {
    EPInfo* epi;
 	UInt32  bytesRead = 0;
    Boolean doLeave;
    
	if (!SocketValid(s)) return -1; 
	
	epi = (EPInfo *) s->privateSocketPtr;
        
 	doLeave = OTEnterNotifier(epi->erf);  //Avoid race condition for T_DATA
    bytesRead = readBytes(epi,(char *) buf,(UInt32) bufSize);
    if (OTAtomicTestBit(&epi->stateFlags2, kReadFlowControl)) {
        if (bytesRead > 0) 
            ReadData(epi,NULL,0); 
        else
            bytesRead = ReadData(epi,(char *) buf,(UInt32) bufSize); //special case attempt read into squeak buffer
    }
  	if (doLeave)
		OTLeaveNotifier(epi->erf);
   
	return (int) bytesRead;
}

//
//New primitive to read UDP data and get data, host/port, and more flag
//
int sqSocketReceiveUDPDataBufCountaddressportmoreFlag(SocketPtr s, char * buf, int bufSize,  int *address,  int *port, int *moreFlag) {
    EPInfo* epi;
 	UInt32 bytesRead = 0;
    Boolean doLeave;
    InetAddress fromAddress;
    
    OTMemzero(&fromAddress,sizeof(InetAddress));
    *address  = 0;
    *port = 0;
    *moreFlag = 0;
    
	if (!SocketValid(s)) return -1;
	
	epi = (EPInfo *) s->privateSocketPtr;
        
 	doLeave = OTEnterNotifier(epi->erf);  //Avoid race condition for T_DATA
    bytesRead   = readBytesUDP(epi,&fromAddress, moreFlag, (char *) buf,(UInt32) bufSize);
    *address    = fromAddress.fHost;
    *port       = fromAddress.fPort;
    if (OTAtomicTestBit(&epi->stateFlags2, kReadFlowControl)) {
         if (bytesRead > 0) 
            ReadData(epi,NULL,0); 
        else {
            bytesRead = ReadData(epi,(char *) buf,(UInt32) bufSize);//special case attempt read into squeak buffer
            *address    = epi->remoteAddress.fHost; //Also we happen to know the address just when into this area
            *port       = epi->remoteAddress.fPort; //JMM more flag?
            *moreFlag   = epi->UDPMoreFlag;
        }
    }
  	if (doLeave)
		OTLeaveNotifier(epi->erf);
   
	return (int) bytesRead;
}

int sqSocketLocalAddress(SocketPtr s) {
    EPInfo* epi;
    
	if (!SocketValid(s)) return -1;
	epi = (EPInfo *) s->privateSocketPtr;
    return (int) (epi->localAddress.fHost == 0) ? sqResolverLocalAddress() : epi->localAddress.fHost;
}

int sqSocketLocalPort(SocketPtr s) {
    EPInfo* epi;
    
	if (!SocketValid(s)) return -1;
	epi = (EPInfo *) s->privateSocketPtr;
	
	return epi->localAddress.fPort;
}

int sqSocketRemoteAddress(SocketPtr s) {
    EPInfo*     epi;
    TBind       remoteBind;
    InetAddress remoteAddr;
    OSStatus    err;
    Boolean	isAsync;

	if (!SocketValid(s)) return -1;
	epi = (EPInfo *) s->privateSocketPtr;
	if (OTAtomicTestBit(&epi->stateFlags, kUnConnected) && 
	    !OTAtomicTestBit(&epi->stateFlags, kWaitingForConnection)) 
            return 0;
	
    if (epi->socketType == UDPSocketType) {
        return (int) epi->remoteAddress.fHost;
    }
    
   if (OTIsSynchronous(epi->erf) == false)	{	// check whether ep sync or not
		isAsync = true;			       	// set flag if async
		OTSetSynchronous(epi->erf);		// set endpoint to sync	
    }
    //It seems the only reliable way to get the address
    //Is to make a call
    //
    OTMemzero(&remoteBind,sizeof(TBind));
    OTMemzero(&remoteAddr,sizeof(InetAddress));
    remoteBind.addr.buf = (UInt8 *) &remoteAddr;
    remoteBind.addr.maxlen = sizeof(InetAddress);
    err = OTGetProtAddress(epi->erf,0,&remoteBind);

    if (isAsync)				        // restore ep state 
        OTSetAsynchronous(epi->erf);
    
    if (err != kOTNoError) 
        return 0;
    else {
        if ((int) remoteAddr.fHost == 0)
                return (int) epi->remoteAddress.fHost;
        return (int) remoteAddr.fHost;
}
}

int sqSocketRemotePort(SocketPtr s) {
    EPInfo* epi;
    TBind       remoteBind;
    InetAddress remoteAddr;
    OSStatus    err;
    Boolean	isAsync;

	if (!SocketValid(s)) return -1;
	epi = (EPInfo *) s->privateSocketPtr;
	if (OTAtomicTestBit(&epi->stateFlags, kUnConnected) && 
	    !OTAtomicTestBit(&epi->stateFlags, kWaitingForConnection)) return 0;
	
    if (epi->socketType == UDPSocketType) {
        return epi->remoteAddress.fPort;
    }
    
   if (OTIsSynchronous(epi->erf) == false)	{	// check whether ep sync or not
		isAsync = true;			       	// set flag if async
		OTSetSynchronous(epi->erf);		// set endpoint to sync	
    }
    //It seems the only reliable way to get the port
    //Is to make a call
    //
    OTMemzero(&remoteBind,sizeof(TBind));
    OTMemzero(&remoteAddr,sizeof(InetAddress));
    remoteBind.addr.buf = (UInt8 *) &remoteAddr;
    remoteBind.addr.maxlen = sizeof(InetAddress);
    err = OTGetProtAddress(epi->erf,0,&remoteBind);
    if (isAsync)				        // restore ep state 
        OTSetAsynchronous(epi->erf);
    
    if (err != kOTNoError) 
        return 0;
    else {
        if ((int) remoteAddr.fPort == 0)
                return (int) epi->remoteAddress.fPort;
        return (int) remoteAddr.fPort;
    }
}


int sqSocketSendDone(SocketPtr s) {
    EPInfo* epi;

	if (!SocketValid(s)) return 1;
	epi = (EPInfo *) s->privateSocketPtr;
    if (OTAtomicTestBit(&epi->stateFlags, kSendIsBlocked)) {
	    OTAtomicSetBit(&epi->stateFlags2, kTapSemaphoreWriteData); //Note the implied intent to use the semaphore
        return 0;
    }
    else {
        return 1;
    }
}

int sqSocketError(SocketPtr s) {
    EPInfo* epi;
    
 	if (!SocketValid(s)) return -1;
	epi = (EPInfo *) s->privateSocketPtr;
    if (OTAtomicTestBit(&epi->stateFlags, kUnConnected)  && 
        !OTAtomicTestBit(&epi->stateFlags, kWaitingForConnection) 
        && epi->lastError == 0)
	    return kENOTCONNErr; // old code would return unconnectederror if unconnected
	else
	    return (epi->lastError);
}

int sqSocketConnectionStatus(SocketPtr s) {

	if (!SocketValid(s)) return InvalidSocket;
	return unmapStatus((EPInfo *) s->privateSocketPtr);
}

static SInt32 unmapStatus(EPInfo *s) {
    if (OTAtomicTestBit(&s->stateFlags3, kSleepKilledMe)) 
        {return  InvalidSocket;
        }
    if (OTAtomicTestBit(&s->stateFlags, kThisEndClosed)) 
        {return  ThisEndClosed;
        }
    if (OTAtomicTestBit(&s->stateFlags, kOtherEndClosed)) 
        {return  OtherEndClosed;
        }
    if (OTAtomicTestBit(&s->stateFlags, kConnected)) 
        { return  Connected;
        }
    if (OTAtomicTestBit(&s->stateFlags, kWaitingForConnection)) 
        {return  WaitingForConnection;
        }
    if (OTAtomicTestBit(&s->stateFlags, kUnConnected)) 
        {return  Unconnected;
        }
   return 0;
}

static Boolean SocketValid(SocketPtr s) {
	if ((s != NULL) &&
		(s->privateSocketPtr != NULL) &&
		(s->sessionID == gthisNetSession) && (gthisNetSession != 0) && 
		(s->socketType == TCPSocketType || s->socketType == UDPSocketType) &&
		(!OTAtomicTestBit(&(((EPInfo *)s->privateSocketPtr)->stateFlags3), kSleepKilledMe)) )
		    return true;
	interpreterProxy->success(false);
	return false;
}


static Boolean PortNumberValid(InetPort port) {
	if (port <= 65535) {
		return true;
	}
	interpreterProxy->success(false);
	return false;
}

//Used to signal all semaphores when we've closed the socket
//I guess the read/write/disconnect threads really want to know
//
static void TapAllInterestedSemaphores(EPInfo *epi) {
    if (OTAtomicClearBit(&epi->stateFlags2, kTapSemaphore)) 
	    interpreterProxy->signalSemaphoreWithIndex(epi->semaIndex); 
    if (OTAtomicClearBit(&epi->stateFlags2, kTapSemaphoreReadData)) 
	    interpreterProxy->signalSemaphoreWithIndex(epi->readSemaIndex); 
    if (OTAtomicClearBit(&epi->stateFlags2, kTapSemaphoreWriteData)) 
	    interpreterProxy->signalSemaphoreWithIndex(epi->writeSemaIndex); 				
}

static Boolean DestroyAllOpenSockets(void) {
	EPInfo      *epi;
	OTLink*		link;
    ReadBuffer *aBuffer;

	//
	//	Start closing connector endpoints.
	//	While we could be rude and just close the endpoints, 
	//	we try to be polite and wait for all outstanding connections
	//	to finish before closing the endpoints.   The is a bit easier
	//	on the server which won't end up keeping around control blocks
	//	for dead connections which it doesn't know are dead.  Alternately,
	//	we could just send a disconnect, but this seems cleaner.
	//

	(void)OTLIFOStealList(gBrokenEPs);
	(void)OTLIFOStealList(gIdleEPs[0]);
	(void)OTLIFOStealList(gIdleEPs[1]);
	(void)OTLIFOStealList(gIdleEPs[2]);
	
    link = OTLIFODequeue(gAllEPs);
    while (link != NULL) {
        epi = OTGetLinkObject(link, EPInfo, globalLink);
     	attemptToCloseAndDeleteThisEP(epi);
        link = OTLIFODequeue(gAllEPs);
    }

	//
	//	If the lists are empty now, then all endpoints have been successfully closed,
	//	so the client is stopped now.  (Actually we hope that is the case)
	//
	
    //
    //Free up all the other resources
    //
    link = OTLIFODequeue(gFreeReadBuffers);
    while (link != NULL) {
    	aBuffer = OTGetLinkObject(link, ReadBuffer, fNext);
        OTFreeMem(aBuffer->readBufferData);
        OTFreeMem(aBuffer); 
        link = OTLIFODequeue(gFreeReadBuffers);
    }
    ResolverTerminate();
	OTFreeMem((char*)gDNSResolver);
	gIdleEPs[0]->fHead		= NULL;
	gIdleEPs[1]->fHead		= NULL;
	gIdleEPs[2]->fHead		= NULL;
	gBrokenEPs->fHead 		= NULL;
	OTDestroyConfiguration(gCfgMastertcp);
	OTDestroyConfiguration(gCfgMasterudp);
	OTDestroyConfiguration(gCfgMasterListener);
	DisposeOTNotifyUPP(DNSNotifierUPP);
	DisposeOTNotifyUPP(NotifierSocketUPP);
	DisposeOTNotifyUPP(NotifierSocketUDPUPP);
	DisposeOTNotifyUPP(NotifierSocketListenerUPP);
	return true;
}


//
//	DoBind
//
//	This routine either binds to a wild card address and specfic port if 
//  we are doing a listen, otherwise we bind to a wild card address and 
//  wild card port if we are starting a connection to a remote host.
//  J M M NOTE A more complex version could use port and addr
//  Note we don't bind to the local socket until here, we could when 
//  The socket is created, but that leads to odd issues.
//

static void DoBind(EPInfo* epi,InetHost addr, InetPort port,UInt8 aExtraSocketHint,OTQLen queueDepth )
{
	OSStatus 	err;
	TBind 		bindReq, bindResult;
	InetAddress	inAddr,bindAddr;
	
	switch (aExtraSocketHint) {
        case TCPSocketType: {
            // for a connection
        	//	Bind the endpoint to a wildcard address 
        	//	(assign us a port, we don't care which one).
        	//  NOTE A more complex version could use port and addr
            OTInitInetAddress(&epi->remoteAddress, port, addr);
            OTInitInetAddress(&epi->localAddress, 0, kOTAnyInetAddress);
        	OTInitInetAddress(&inAddr, 0, 0);
            break;
        }
        case UDPSocketType: { 
            // for a connection
        	//	Bind the endpoint to earlier supplied information
            OTInitInetAddress(&epi->remoteAddress, port, addr);
        	OTInitInetAddress(&inAddr, 0, 0);
            break;
        }
        case TCPListenerSocketType: {
            // For a listen, bind wild card address, but supplied port.
            // Note the passed in addr should be zero
            // Note a more complex version could supply the address
            OTInitInetAddress(&epi->remoteAddress, 0, kOTAnyInetAddress);
            OTInitInetAddress(&epi->localAddress, port, addr);
        	OTInitInetAddress(&inAddr,port, addr);
            break;
        }
        case UDPListenerSocketType: {
            // For a listen, bind wild card address, but supplied port.
            // Note the passed in addr should be zero
            // Note a more complex version could supply the address
            OTInitInetAddress(&epi->remoteAddress, 0, kOTAnyInetAddress);
            OTInitInetAddress(&epi->localAddress, port, addr);
        	OTInitInetAddress(&inAddr,port, addr);
            break;
        }
	}

 	bindReq.addr.len    	= sizeof(InetAddress);
	bindReq.addr.buf    	= (unsigned char*) &inAddr;
	bindReq.qlen        	= queueDepth; //Note queue depth for listening
 	bindResult.addr.maxlen	= sizeof(InetAddress);
 	bindResult.addr.len   	= sizeof(InetAddress);
	bindResult.addr.buf    	= (unsigned char*) &bindAddr;
	epi->stateFlags     	= 0;
	epi->stateFlags2   		= 0;
	epi->stateFlags3    	= 0;
	epi->bytesPendingToRead = 0;
	SetEPLastError(epi,noErr);
	if (aExtraSocketHint == TCPSocketType|| aExtraSocketHint == TCPListenerSocketType) {
        OTAtomicSetBit(&epi->stateFlags, kUnConnected);
        OTAtomicSetBit(&epi->stateFlags, kWaitingForConnection);
        OTAtomicSetBit(&epi->stateFlags2, kTapSemaphore);
    }
	
	OTAtomicSetBit(&epi->stateFlags3, kWaitingForBind);
	err = OTBind(epi->erf, &bindReq, &bindResult); // resume at T_BINDCOMPLETE
	
	// for bindReq on listen what is queueDepth now? 
	// bindReq.qlen could have changed
	// But... No why to feed this back to the client!
	
	if (err != kOTNoError) {
    	SetEPLastError(epi,err);
        makeEPUnconnected(epi);
    	return;
	}
	
	OTMemcpy(&epi->localAddress,bindResult.addr.buf,sizeof(InetAddress)); //Pickup local address
	return;
}

//
//	DoConnect
//
//	This routine attempts establish a new connection to the given
//	address and port.  
//  Called via the notifier at interrupt time.
//

static void DoConnect(EPInfo* epi,InetHost addr, InetPort port)
{
	OSStatus err;
	TCall sndCall;
	InetAddress inAddr;
	
	//	Don't want new connections if already shutting down.
	if (gProgramState != kProgramRunning ) return;
		
	OTInitInetAddress(&inAddr, port, addr);
	OTMemzero(&sndCall, sizeof(TCall));
	sndCall.addr.len 	= sizeof(InetAddress);				
	sndCall.addr.buf	= (unsigned char*) &inAddr;
	
	err = OTConnect(epi->erf, &sndCall, NULL); //resume at T_CONNECT
	if (err != kOTNoDataErr) {
    	SetEPLastError(epi,err);
        makeEPUnconnected(epi);
		return;
	}
}


//
//	DoListenAccept
//
//	The handling of a T_LISTEN is greatly simplified by use
//	of the tilisten module, which serializes inbound connections.
//	This means that when doing an OTAccept we won't get a kOTLookErr
//	because another inbound connection arrived and created a T_LISTEN.
//	Without the tilisten module, we have to use the "8 step 
//	listen/accept/disconnect method", which is documented elsewhere.
//

static void DoListenAccept(EPInfo* acceptor,EPInfo* theServer)
{
	TCall		call;
	InetAddress	caddr;
	OTResult	lookResult;
	OSStatus	err;
			
	OTMemzero(&call, sizeof(TCall));
	call.addr.maxlen = sizeof(InetAddress);
	call.addr.buf = (unsigned char*) &caddr;
		
	err = OTListen(theServer->erf, &call);
	if (err != kOTNoError) {
		//
		//	Only two errors are expected at this point.
		//	One would be a kOTNoDataErr, indicating the inbound connection
		//	was unavailable, temporarily hidden by a higher priority streams
		//	message, etc.   The more likely error is a kOTLookErr, 
		//	which indicates a T_DISCONNECT on the OTLook()
		//	happens when the call we were going to process disconnected.
		//	In that case, go away and wait for the next T_LISTEN event.
		//
		if (err == kOTNoDataErr) return;
			
		lookResult = OTLook(theServer->erf); 
		if (err == kOTLookErr && lookResult == T_DISCONNECT)
        	err = OTRcvDisconnect(theServer->erf, NULL);
		else 
		    SetEPLastError(theServer,lookResult);
		
		//JMM Sept28th,2000 ? ok accept it, if we don't does this cause blockage?
		acceptor->remoteAddress = caddr;
		err = OTAccept(theServer->erf, acceptor->erf, &call);
		return;	
	}
	
	acceptor->remoteAddress = caddr;
	
	err = OTAccept(theServer->erf, acceptor->erf, &call);
	//
	//	Note an kOTIndOutErr can occur if we are listening on the EP and handling 
	//  off to the same EP. Sorry use the listento:backlogqueue: logic instead
    //
	if (err != kOTNoError) {
		//
		//	Again, we have to be able to handle the connection being disconnected
		//	while we were trying to accept it.
		//
		lookResult = OTLook(theServer->erf);
		if (err == kOTLookErr && lookResult == T_DISCONNECT) 
        	err = OTRcvDisconnect(theServer->erf, NULL);
		else 
		    SetEPLastError(theServer,lookResult);
	}
}

//
//	EPOpen:
//
//	A front end to OTAsyncOpenEndpoint.
//	A status bit is set so we know there is an open in progress.
//	It is cleared when the notifier gets a T_OPENCOMPLETE where the context
//	pointer is this EPInfo.  Until that happens, this EPInfo can't be cleaned
//	up and released.
//
static Boolean EPOpen(EPInfo* epi)
{
	OSStatus err;
	
	OTAtomicSetBit(&epi->stateFlags, kOpenInProgressBit);
	SetEPLastError(epi,kOTNoError);
    epi->UDPMaximumSize = 0; //Remember to figure out the max UDP size.
    
	switch (epi->socketType) {
	    case TCPSocketType: {
#if TARGET_API_MAC_CARBON
		    err = OTAsyncOpenEndpointInContext(OTCloneConfiguration(gCfgMastertcp), 0, NULL, NotifierSocketUPP, epi, gClientContext); 
#else
		    err = OTAsyncOpenEndpoint(OTCloneConfiguration(gCfgMastertcp), 0, NULL, NotifierSocketUPP, epi); 
#endif
	        break;
	    }
	    case UDPSocketType: {
	        TEndpointInfo endPointInformation;
#if TARGET_API_MAC_CARBON
		    err = OTAsyncOpenEndpointInContext(OTCloneConfiguration(gCfgMasterudp), 0, &endPointInformation, NotifierSocketUDPUPP, epi, gClientContext); 
#else
		    err = OTAsyncOpenEndpoint(OTCloneConfiguration(gCfgMasterudp), 0, &endPointInformation, NotifierSocketUDPUPP, epi); 
#endif
		    epi->UDPMaximumSize = (endPointInformation.tsdu == T_INFINITE) ? 64*1024 : endPointInformation.tsdu;
	        break;
	    }
	    case TCPListenerSocketType: {
#if TARGET_API_MAC_CARBON
		    err = OTAsyncOpenEndpointInContext(OTCloneConfiguration(gCfgMasterListener), 0, NULL, NotifierSocketListenerUPP, epi, gClientContext); 
#else
		    err = OTAsyncOpenEndpoint(OTCloneConfiguration(gCfgMasterListener), 0, NULL, NotifierSocketListenerUPP, epi); 
#endif
	        break;
	    }
	}
	if (err != kOTNoError) {
		SetEPLastError(epi,err);
		OTAtomicClearBit(&epi->stateFlags, kOpenInProgressBit);
		return false;
	}
	return (epi->lastError == kOTNoError);
}


//
//	EPClose
//
//	This routine is a front end to OTCloseProvider.   
//	Centralizing closing of endpoints makes debugging and instrumentation easier.  
//
static Boolean EPClose(EPInfo* epi)
{
	OSStatus err;
	
	//
	//	If an endpoint is still being opened, we can't close it yet.
	//	There is no way to cancel an OTAsyncOpenEndpoint, so we just
	//	have to wait for the T_OPENCOMPLETE event at the notifier.
	//
	if ( OTAtomicTestBit(&epi->stateFlags, kOpenInProgressBit) )
		return false;
		
    
	//
	//	If the OTAsyncOpenEndpoint failed, the endpoint ref will be NULL,
	//	and we don't need to close it now. Also can be NULL or should be NULL if sleeping happened.
	//
	if (epi->erf == NULL || OTAtomicClearBit(&epi->stateFlags3, kSleepKilledMe)) {
	    epi->erf = NULL;
		return true;
	}
		
	if (epi->outstandingSends == 0) {
    	err = OTCloseProvider(epi->erf);
    	epi->erf = NULL;
    	return true;
    }
    	
    //
	//	If we get to this point, the endpoint did an OTSnd() with AckSends,
	//	and the T_MEMORYRELEASED event hasn't been returned yet.  In order
	//	to make sure we get the event, we flush the stream and then do an
	//	OTDisconnect().   This should get the memory freed so we can close
	//	the endpoint safely.   Note, we set a flag so we don't do this 
	//	more than once on an endpoint.
	//  J M M I'm not sure we'll ever get here since a flush should have been done higher up
	//
	if ( OTAtomicSetBit(&epi->stateFlags2, kFlushDisconnectInProgressBit) == 0 )
	{
		err = OTIoctl(epi->erf, I_FLUSH, (void *)FLUSHRW);
		if (err != kOTNoError)
			{} 
	}
	return false;

}

//
//	Recycle:
//
//	This routine shouldn't be necessary, but it is helpful to work around both
//	problems in OpenTransport and bugs in this program.   Basicly, whenever an
//	unexpected error occurs which shouldn't be fatal to the program, the EPInfo
//	is queued on the BrokenEP queue.  When recycle is called,
//  it will attempt to close the associated endpoint and open
//	a new one to replace it using the same EPInfo structure.   This process of
//	closing an errant endpoint and opening a replacement is probably the most
//	reliable way to make sure that this program and OpenTransport can recover
//	from unexpected happenings in a clean manner.
//
//  Mind you it can be invoked to cleanup UDP sockets that aren't closed 
//  properly due to pending traffice on a busy port.
//  Solution mentioned in books is to close the EP.
//
static void Recycle()
{
	OTLink* 	list = OTLIFOStealList(gBrokenEPs);
	OTLink*		link;
	EPInfo*		epi;

	while ( (link = list) != NULL ) {
		list = link->fNext;
		epi = OTGetLinkObject(link, EPInfo, link);
		if (!EPClose(epi)) {
			OTLIFOEnqueue(gBrokenEPs, &epi->link);
			continue;
		}
		if (gProgramState == kProgramRunning)
		    EPOpen(epi);
		 else
		    makeEPIdle(epi);
	}
}

//
// Make the EP idle, it either goes on an idle queue or gets broken.
//
static void    makeEPIdle(EPInfo *epi) {
    purgeReadBuffers(epi);
    
    if (OTAtomicClearBit(&epi->stateFlags2, kEPIsBroken)) {
        OTLIFOEnqueue(gBrokenEPs, &epi->link); 
    } else {
	    OTLIFOEnqueue(gIdleEPs[epi->socketType], &epi->link); 
   	    OTAtomicAdd32(1, &gIdleEPCounter[epi->socketType]); 
   }
}

static void attemptToCloseAndDeleteThisEP (EPInfo *epi) {
    purgeReadBuffers(epi); 
	if (!EPClose(epi)) {
		//	Can't close this endpoint yet, so skip it.
	} else 
	    OTFreeMem((char*)epi);
}
static EPInfo* getOrMakeMeAnEP(UInt8 aSocketType,short counter) {
	EPInfo      *epi;
    OTLink		*link;
    SInt32      i;
    
    Recycle();  //Ensure broken EP get fixed up
    
    if (counter > 25) 
        return nil;  // End recursion John 2000/8/29

    if (gIdleEPCounter[aSocketType] < 5)   //Magic Number ensure we have at least 5 EP available.
        makeMeAnEP(aSocketType);
        
    link = OTLIFODequeue(gIdleEPs[aSocketType]);
	if (link == NULL) {
		for(i=0;i<10;i++) {OTIdle();};
		return getOrMakeMeAnEP(aSocketType,counter+1); //Watch for recursive failure
	}
	
   	OTAtomicAdd32(-1, &gIdleEPCounter[aSocketType]);
	epi = OTGetLinkObject(link, EPInfo, link);
	
	if (OTAtomicTestBit(&epi->stateFlags3, kSleepKilledMe)) {
	//
	//A broken epi on the idle stack, now the only way we can 
	//get here (I think) is to have gone to sleep which breaks
	//all the end points. To clean up we must now fix them
	//So make it idle, of course it's broken
	//Then recursive call to get another one
	//This continues until we get a good one
	//
  	    makeEPIdle(epi);
	    return getOrMakeMeAnEP(aSocketType,counter);  //Not a recursion issue. 
	}
    return epi;
}

//
//This is where EP are actually made and opened
//EP opening is async
//

static Boolean makeMeAnEP (UInt8 aSocketType) {
	EPInfo      *epi;
	
#if TARGET_API_MAC_CARBON
	epi = (EPInfo*) OTAllocMemInContext(sizeof(EPInfo), gClientContext);
#else
	epi = (EPInfo*) OTAllocMem(sizeof(EPInfo));
#endif
	if (epi == NULL) return false;   //Death lurks
	OTMemzero(epi, sizeof(EPInfo));  //zero it out which makes all the pointers null
    epi->socketType = aSocketType;
    OTLIFOEnqueue(gAllEPs, &epi->globalLink);
	return EPOpen(epi);
}

static void makeEPUnconnected(EPInfo *epi) {
	OTAtomicClearBit(&epi->stateFlags, kWaitingForConnection);
	OTAtomicSetBit(&epi->stateFlags, kUnConnected);
    if (OTAtomicClearBit(&epi->stateFlags2, kTapSemaphore)) //tap to clear waitforconnection on error
        interpreterProxy->signalSemaphoreWithIndex(epi->semaIndex);
}

static void makeEPConnected(EPInfo *epi) {
	OTAtomicClearBit(&epi->stateFlags, kWaitingForConnection);
	OTAtomicClearBit(&epi->stateFlags, kUnConnected);
    OTAtomicSetBit(&epi->stateFlags, kConnected);
    if (OTAtomicClearBit(&epi->stateFlags2, kTapSemaphore)) //tap to clear waitforconnection
        interpreterProxy->signalSemaphoreWithIndex(epi->semaIndex);
}

static void makeEPBrokenThenIdle(EPInfo* epi,OTResult error) {
    makeEPBroken(epi,error);
    makeEPIdle(epi);
}

static void makeEPBroken(EPInfo* epi,OTResult error) {
    SetEPLastError(epi,error);
    OTAtomicSetBit(&epi->stateFlags2, kEPIsBroken);
}

static void SetEPLastError(EPInfo* epi,OTResult error) {
    if (error < 0) {
		JMMLogMessageAndNumber("\p NonZero Error For ",epi->semaIndex);
		JMMLogMessageAndNumber("\p NonZero Error Is  ",error);
    }
    epi->lastError = error;
}

//	ReadData:
//
//	This routine attempts to read all available data from an endpoint.
//	it is not necessary for the program to handle
//	getting back a T_DATA notification DURING an OTRcv() call, as would be
//	the case if we read from outside the notifier.   We must read until we
//	get a kOTNoDataErr in order to clear the T_DATA event so we will get
//	another notification of T_DATA in the future.
//  Note we use EnterNotifier to make this possible
//
//	Note for the curious we attempted to use no-copy receives to get data.  This obligates
//	the program to return the buffers to OT asap.  BUT we found we overran memory!
//  So we reverted to more expensive copies into buffers we have preallocated
//
//  Perhaps a seperate routine for UDP would make sense?
//  Note May 30/00 we added a special read when we exhaust the internal buffer pool
//  But data is still pending we allow you to read into the squeak buffer directly
//

static UInt32 ReadData(EPInfo* epi,char *specialReadBuffer,UInt32 specialReadSize) {
	OTResult  	res;
	OTFlags	  	flags;
	OTResult	epState,err;
	OTLink		*link;
    ReadBuffer 	*readBufferObject,simulatedReadBuffer;
    InetAddress UDPdataFromAddress;
	
    if (OTAtomicClearBit(&epi->stateFlags2, kTapSemaphoreReadData)) //tap to clear waitfordata Data Data Data
        interpreterProxy->signalSemaphoreWithIndex(epi->readSemaIndex);
        
    if (specialReadSize > 0) { //Special case drop into squeak buffer, make a simulated buffer object
        OTMemzero(&simulatedReadBuffer,sizeof(ReadBuffer));
        simulatedReadBuffer.readBufferData = specialReadBuffer;
        simulatedReadBuffer.readBufferSize = simulatedReadBuffer.readBufferOriginalSize = specialReadSize;
        readBufferObject = &simulatedReadBuffer;
    } else {
       link = OTLIFODequeue(gFreeReadBuffers);
            
    	if (link == NULL) {
           	OTAtomicSetBit(&epi->stateFlags2, kReadFlowControl);  //NO free buffers we are flow controled
        	return 0; 
    	}
		gFreeReadBuffersCounter--;
    	readBufferObject = OTGetLinkObject(link, ReadBuffer, fNext);
        OTAtomicClearBit(&epi->stateFlags2, kReadFlowControl);  
    }
    
    OTMemzero(&UDPdataFromAddress,sizeof(InetAddress));
    
	while (true) {
        
		readBufferObject->readBufferPtr = readBufferObject->readBufferData;
		
   	    if (epi->socketType == UDPSocketType) {
   	        TUnitData 	UDPDataInBound;
   	        OTFlags     flagMeaningMore;
            OSStatus    error;
            
    	    UDPDataInBound.addr.maxlen = sizeof(InetAddress);
    	    UDPDataInBound.addr.len    = sizeof(InetAddress);
    	    UDPDataInBound.addr.buf    = (UInt8*) &readBufferObject->UDPAddress;
    	    UDPDataInBound.opt.maxlen  = 0;
    	    UDPDataInBound.opt.len     = 0;
    	    UDPDataInBound.opt.buf     = NULL;
    	    UDPDataInBound.udata.maxlen = readBufferObject->readBufferOriginalSize;
    	    UDPDataInBound.udata.len    = readBufferObject->readBufferOriginalSize;
    	    UDPDataInBound.udata.buf    = (UInt8*)readBufferObject->readBufferData;
	    
	        error =  OTRcvUData(epi->erf, &UDPDataInBound, &flagMeaningMore);
	        
	        if (error != kOTNoError) {
	            res = error;
	        } else {
	            if (UDPDataInBound.addr.len == 0) //Remember UDP address
	                readBufferObject->UDPAddress = UDPdataFromAddress;
	            else
	                UDPdataFromAddress = readBufferObject->UDPAddress;
	                
	            epi->UDPMoreFlag = readBufferObject->UDPMoreFlag = (flagMeaningMore > 0) ? true: false;
	            res = (SInt32) UDPDataInBound.udata.len; 
	            OTMemcpy(&epi->remoteAddress,&readBufferObject->UDPAddress,sizeof(InetAddress));  
	        }
   	    } else {//A less complicated tcp read
   	        res = OTRcv(epi->erf, readBufferObject->readBufferData, readBufferObject->readBufferOriginalSize, &flags);
   	    }
   	    
		//
		//	Note, check for 0 because can get a real 0 length receive
		//	in some protocols (not in TCP), which is different from
		//	getting back a kOTNoDataErr.
		//
		if (res >= 0) {
            if (specialReadSize > 0) 
                return (UInt32) res; //Note special case
                
            readBufferObject->readBufferSize = (UInt32) res;
            
            OTAddLast(&epi->readBuffers,&readBufferObject->fNext); //Put the buffer on the read queue
        	OTAtomicAdd32(res, &epi->bytesPendingToRead);
            link = OTLIFODequeue(gFreeReadBuffers);
                    
        	if (link == NULL) {
               	OTAtomicSetBit(&epi->stateFlags2, kReadFlowControl); //Our read flow control, OT will block lower down
            	return 0; 
        	}
			gFreeReadBuffersCounter--;
        	readBufferObject = OTGetLinkObject(link, ReadBuffer, fNext);
   			continue; //Loop around and get more bytes if available
		}
		else {
            if (specialReadSize == 0) {
                OTLIFOEnqueue(gFreeReadBuffers, &readBufferObject->fNext); //Read above didn't work so put it back on free queue
				gFreeReadBuffersCounter++;
			}
		}
		
		if (res == kOTNoDataErr) {
			//
			//	Since ReadData is only called from inside the notifier
			//	we don't have to worry about having missed a T_DATA 
			//	during the OTRcv.
			//  Note use of EnterNotifier logic
			//
			if (specialReadSize > 0)
			    OTAtomicClearBit(&epi->stateFlags2, kReadFlowControl);
 			return 0;
		}
		if (res == kOTLookErr) {
			res = OTLook(epi->erf);
			if (res == T_ORDREL || res == T_DISCONNECT) {
				//	If we got the T_ORDREL, we won't get any more inbound data.
				//	We return and wait for the notifier to get the T_ORDREL notification.
				//	Upon getting it, we will notice we still need to send data and do so.
				//	The T_ORDREL has to be cleared before we can send. 
				//
				if (specialReadSize > 0 && res == T_DISCONNECT) {
					//Special case? need to get disconnect 
					err = OTRcvDisconnect(epi->erf, NULL);
					makeEPUnconnected(epi);
				}
				return 0 ;
			}
			if (res == T_GODATA) {
			    if (specialReadSize == 0) {
    			    link = OTLIFODequeue(gFreeReadBuffers);    
                	if (link == NULL) {
                       	OTAtomicSetBit(&epi->stateFlags2, kReadFlowControl);
                    	return 0 ; 
                	}
					gFreeReadBuffersCounter--;
                	readBufferObject = OTGetLinkObject(link, ReadBuffer, fNext);
            	} else {
            	    return 0;
            	}
			    continue; //OT Flow control lifted keep reading. JMM
			}
		} else {
			epState = OTGetEndpointState(epi->erf);
			if (res == kOTOutStateErr && epState == T_INREL) {
				//
				//	Occasionally this problem will happen due to what appears
				//	to be an OpenTransport notifier reentrancy problem.   
				//	What has occured is that a T_ORDREL event happened and 
				//	was processed during ReadData().   This is proven by being
				//	in the T_INREL state without having done a call to
				//	OTRcvOrderlyDisconnect() here.   It appears to be a benign 
				//	situation, so the way to handle it is to understand that no
				//	more data is going to arrive and go ahead and being our response
				//	to the client.
				//
				break;
			}
			if (res == kOTOutStateErr && (epState == T_UNBND || epState == T_IDLE ) && specialReadSize > 0) {
				  interpreterProxy->success(false); //JMM Oct 4th 2000 special case fail if read on unbound
				  return 0;
			}
		break; //Ok error so break out of loop
		}
	}
    return 0;	
}

//
// NOT USED HISTORICAL REASONS
// 
/*

static void NoCopyReceiveWalkingBufferChain(EPInfo *epi,OTBufferInfo *bufferInfo)
{
   OSStatus     err;
   OTBuffer     *thisBuffer;
   UInt32       count;
   ReadBuffer   *readBufferObject;
   
    
    thisBuffer = bufferInfo->fBuffer;
    err = noErr;
    while (err == noErr && thisBuffer != nil) {
        count = thisBuffer->fLen;
    	OTAtomicAdd32(count, &epi->bytesPendingToRead);
		readBufferObject = OTAllocMemInContext(sizeof(ReadBuffer), gClientContext);
        if (readBufferObject == nil) {
			SysBeep(5);
            err = -1;
            break;
        } 
        OTMemzero(readBufferObject,sizeof(ReadBuffer));
        readBufferObject->readBufferData = readBufferObject->readBufferPtr = OTAllocMemInContext(count, gClientContext);
        if ( readBufferObject->readBufferData == nil) {
			SysBeep(5);
             err = -1;
            break;
        } 
        readBufferObject->readBufferOriginalSize = readBufferObject->readBufferSize = count;
        OTMemcpy(readBufferObject->readBufferData,thisBuffer->fData,count);
        OTAddLast(&epi->readBuffers,&readBufferObject->fNext);
        thisBuffer = thisBuffer->fNext;
    }

   // Clean up.  We MUST release the OTBuffer chain to Open Transport 
   // so that it crelease the OTBuffer chain to Open Transport 
   // so that it can reuse it., OTReleaseBuffer does not tolerate
   // the parameter being nil, so we check for that case first. 

   if (bufferInfo->fBuffer != nil) {
      OTReleaseBuffer(bufferInfo->fBuffer);
   }

}
*/

//
// Read Bytes from the buffers
// Called by Squeak to get the data
//
static UInt32  readBytes(EPInfo* epi,char *buf,UInt32 adjustedBufSize)
{
    //
    // Read bytes from buffers
    // use recursion to fill buf to adjustedBufSize or 
    // til we have no buffers left
    // By using enterNotifier higher up we avoid race on the readBuffers list
    //
    
    UInt32 		increment,bytesRead = 0;
    ReadBuffer *aBuffer;
    
    aBuffer = (ReadBuffer *) OTRemoveFirst(&epi->readBuffers);
    if (aBuffer == nil) return 0;
    
    if (aBuffer->readBufferSize > adjustedBufSize) {
        bytesRead = adjustedBufSize;
    	OTAtomicAdd32(-bytesRead, &epi->bytesPendingToRead);
        OTMemcpy((char *) buf,aBuffer->readBufferPtr,bytesRead);
        aBuffer->readBufferPtr += bytesRead;
        aBuffer->readBufferSize -= bytesRead;
        OTAddFirst(&epi->readBuffers,&aBuffer->fNext);
        return bytesRead;
    }
    else {
        bytesRead = aBuffer->readBufferSize;
       	OTAtomicAdd32(-bytesRead, &epi->bytesPendingToRead);
        OTMemcpy(buf,aBuffer->readBufferPtr,bytesRead);
        OTLIFOEnqueue(gFreeReadBuffers, &aBuffer->fNext);
		gFreeReadBuffersCounter++;
        increment = readBytes(epi,buf+bytesRead,adjustedBufSize-bytesRead);
        bytesRead += increment;
        return bytesRead;
   }
}


static UInt32  readBytesUDP(EPInfo* epi,InetAddress *fromAddress, int * moreFlag, char *buf,UInt32 adjustedBufSize)
{
    //
    // Read bytes from buffers
    // For UDP we just drop in the read buffer and address
    // Don't fill the entire buffer no recursion.
    // By using enterNotifier higher up we avoid race on the readBuffers list
    //
    
    UInt32      bytesRead = 0;
    ReadBuffer  *aBuffer;
    
    aBuffer = (ReadBuffer *) OTRemoveFirst(&epi->readBuffers);
    if (aBuffer == nil) return 0;
    
    if (aBuffer->readBufferSize > adjustedBufSize) {
        bytesRead = adjustedBufSize;
    	OTAtomicAdd32(-bytesRead, &epi->bytesPendingToRead);
        OTMemcpy((char *) buf,aBuffer->readBufferPtr,bytesRead);
        aBuffer->readBufferPtr += bytesRead;
        aBuffer->readBufferSize -= bytesRead;
        OTMemcpy(fromAddress,&aBuffer->UDPAddress,sizeof(InetAddress));
        *moreFlag = aBuffer->UDPMoreFlag;
        OTAddFirst(&epi->readBuffers,&aBuffer->fNext);
        return bytesRead;
    }
    else {
        bytesRead = aBuffer->readBufferSize;
       	OTAtomicAdd32(-bytesRead, &epi->bytesPendingToRead);
        OTMemcpy(buf,aBuffer->readBufferPtr,bytesRead);
        OTMemcpy(fromAddress,&aBuffer->UDPAddress,sizeof(InetAddress));
        *moreFlag = aBuffer->UDPMoreFlag;
        OTLIFOEnqueue(gFreeReadBuffers, &aBuffer->fNext);
		gFreeReadBuffersCounter++;
        return bytesRead;
   }
}

//Cleanup logic
//

static void purgeReadBuffers(EPInfo *epi) {
    ReadBuffer *aBuffer;
        
    //
    //Put buffers for this epi back on the free queue
    //
    aBuffer = (ReadBuffer *) OTRemoveFirst(&epi->readBuffers);
    
    while (aBuffer != NULL) {
        OTLIFOEnqueue(gFreeReadBuffers, &aBuffer->fNext);
		gFreeReadBuffersCounter++;
        aBuffer = (ReadBuffer *) OTRemoveFirst(&epi->readBuffers);
    }
    epi->bytesPendingToRead = 0;
}



//
//	Send the Bytes (Really fast, we hope)
//
static SInt32 SendData(EPInfo* epi,char* buffer, UInt32 size)
{
	OTResult res;
	struct OTData *dataPtr; 

 	//
	//	Make sure we record that we are starting a send so we don't try to close
	//	the endpoint before a T_MEMORYRELEASED event is returned.
	//
	OTAtomicAdd32(1, &epi->outstandingSends);
	
	if (epi->socketType == UDPSocketType) {
		TUnitData UDPDataOutBound;

	    UDPDataOutBound.addr.maxlen  = sizeof(InetAddress);
	    UDPDataOutBound.addr.len     = sizeof(InetAddress);
	    UDPDataOutBound.addr.buf     = (UInt8*) &epi->remoteAddress;
	    UDPDataOutBound.opt.maxlen   = 0;
	    UDPDataOutBound.opt.len      = 0;
	    UDPDataOutBound.opt.buf      = NULL;
	    UDPDataOutBound.udata.maxlen = size;
	    UDPDataOutBound.udata.len    = size;
	    UDPDataOutBound.udata.buf    = (UInt8*)buffer;
	    
        res =  OTSndUData(epi->erf,&UDPDataOutBound); 
        if (res == kOTNoError ) return (SInt32) size;
        
        // Other Errors could be kOTFlowErr or kOTBadDataErr
	}
	else { //TCP Send
    	//
    	//	In OT 1.1.2 and previous versions, there is a bug with AckSends
    	//	which occurs when the same buffer is sent more than once.   In an attempt
    	//	to go fast and not allocate memory, TCP may write an IP and TCP header
    	//	into the data buffer which is sent.   If the buffer is sent more than once
    	//	without being refreshed, the data may be corrupted.   To work around this,
    	//	send the data via an OTData structure, using the gather-write mechanism.
    	//	The problem does not occur in this code path, and this will not hinder performance.
    	//	The problem will be fixed in the next Open Transport release following 1.1.2.
    	//
    	//  Note the MAC OS 8.1 docs alude to a bug before 1.3 where acksends
    	//  cause problems if a disconnect flows just right. Unsure if this
    	//  will be an issue
    	//
    	
    	if (gOTVersion < kOTVersion113) {
#if TARGET_API_MAC_CARBON
    		dataPtr = OTAllocMemInContext(sizeof(OTData), gClientContext);
#else
    		dataPtr = OTAllocMem(sizeof(OTData));
#endif
    		if (dataPtr == NULL) { //Death lurks I'm sure
    		    OTAtomicAdd32(-1, &epi->outstandingSends);
                OTFreeMem(buffer);
                return 0;
            }

    		dataPtr->fNext = NULL;
    		dataPtr->fData = buffer;
    		dataPtr->fLen  = size;
    		res = OTSnd(epi->erf, dataPtr, kNetbufDataIsOTData, 0);
    		
    		//Note in the notification routine we cleanup the allocated dataPtr AND buffer.
    	}
    	else
    	{
    		res = OTSnd(epi->erf, buffer, size, 0);
    		
    		//JMM how to handle kENOMEMErr no memory right now error
    		//Book says to back off and wait but must do a timer or something
    		//Right now we'll fail the primitive higher up since the error code is bad
    	}
    }

	if (res == size) return (SInt32) size;

	if (res >= 0) {
		//
		//	Implied kOTFlowErr since not all data was accepted.
		//  But maybe we aren't blocked yet so keep sending
		//
		return res;
	} else	{	// res < 0
	
 		OTAtomicAdd32(-1, &epi->outstandingSends);
        OTFreeMem(buffer);
        
	    if ((epi->socketType != UDPSocketType) && (gOTVersion < kOTVersion113) )
	       	OTFreeMem(dataPtr); 
	   
		if (res == kOTFlowErr) {
		    //
		    // Flow control back off and wait for T_GODATA
		    //
        	OTAtomicSetBit(&epi->stateFlags, kSendIsBlocked);
			return 0;
		}
		
		if (res == kOTLookErr) {
			res = OTLook(epi->erf);
			if (res == T_ORDREL || res == T_GODATA || res == T_DISCONNECT)
			{
				//	Wait to get the T_ORDREL at the notifier and handle it there.
				//	Then we will resume sending.
				//  Same applies for other events
				//
                //JMM test? 
               	OTAtomicSetBit(&epi->stateFlags, kSendIsBlocked);
				return 0;
			} else 	
		    	return res; 
		} else 
		    return res;
	
	}
}

//
//Set the options
//
int sqSocketSetOptionsoptionNameStartoptionNameSizeoptionValueStartoptionValueSizereturnedValue(SocketPtr s,char * optionNameT, int optionNameSize, char * optionValueT, int optionValueSize, int *result)	{
    EPInfo*     epi;
    OTResult    error;
    char        optionName[80],optionValue[80];
    SInt32      anInteger;
    
	*result = 0;
	if (!SocketValid(s)) return -1;
    epi = (EPInfo *) s->privateSocketPtr;

	OTMemcpy(optionName,(char *) optionNameT,optionNameSize);
	optionName[optionNameSize] = 0x00;
	
    OTMemcpy(optionValue,(char *) optionValueT,optionValueSize);
    optionValue[optionValueSize] = 0x00;
    if (optionValueSize == 8) {
        error = lookupOptionName(epi, false, (char *) &optionName, (long) &optionValue ,(long *) result);
    } else {
        CopyCStringToPascal(optionValue,(unsigned char *) optionValue);
        StringToNum((ConstStr255Param) optionValue,&anInteger);   
        error = lookupOptionName(epi, false, (char *) &optionName, anInteger,(long *) result);
    }
   return error;
}

//
//Get the options
//
int sqSocketGetOptionsoptionNameStartoptionNameSizereturnedValue(SocketPtr s,char * optionNameT, int optionNameSize, int *result)	{
    EPInfo*     epi;
    OTResult    error;
    char        optionNameTemp[80];
   
	*result = 0;
	if (!SocketValid(s)) return -1;
    epi = (EPInfo *) s->privateSocketPtr;

	OTMemcpy(optionNameTemp,(char *) optionNameT,optionNameSize);  //NEED to fiddle with error number JMM to say readonly notvalid etc.
	optionNameTemp[optionNameSize] = 0x00;
	
     	
   error = lookupOptionName(epi, true, (char *) &optionNameTemp, NULL,(long *)  result);
   return error;
}


// A Number of routines to set/get options, first figureout the flags, then call the routine
// To set or get the options. 

static SInt32	lookupOptionName(EPInfo *epi, Boolean trueIfGet, char *aString, UInt32 value, SInt32 *result) {
	if (strcmp("TCP_MAXSEG",aString)==0) 				{return SetFourByteOption(epi,trueIfGet,INET_TCP,TCP_MAXSEG,value,result);};
	if (strcmp("TCP_NODELAY",aString)==0) 				{return SetFourByteOption(epi,trueIfGet,INET_TCP,TCP_NODELAY,value,result);};
#ifdef TCP_NOPUSH
	if (strcmp("TCP_NOPUSH",aString)==0) 				{return SetFourByteOption(epi,trueIfGet,INET_TCP,TCP_NOPUSH,value,result);};
#endif
	if (strcmp("TCP_ABORT_THRESHOLD",aString)==0) 		{return SetFourByteOption(epi,trueIfGet,INET_TCP,TCP_ABORT_THRESHOLD,value,result);};
	if (strcmp("TCP_CONN_NOTIFY_THRESHOLD",aString)==0) {return SetFourByteOption(epi,trueIfGet,INET_TCP,TCP_CONN_NOTIFY_THRESHOLD,value,result);};
	if (strcmp("TCP_CONN_ABORT_THRESHOLD",aString)==0) 	{return SetFourByteOption(epi,trueIfGet,INET_TCP,TCP_CONN_ABORT_THRESHOLD,value,result);};
	if (strcmp("TCP_NOTIFY_THRESHOLD",aString)==0) 		{return SetFourByteOption(epi,trueIfGet,INET_TCP,TCP_NOTIFY_THRESHOLD,value,result);};
	if (strcmp("TCP_URGENT_PTR_TYPE",aString)==0) 		{return SetFourByteOption(epi,trueIfGet,INET_TCP,TCP_URGENT_PTR_TYPE,value,result);};

	if (strcmp("UDP_CHECKSUM",aString)==0) 				{return SetFourByteOption(epi,trueIfGet,INET_UDP,UDP_CHECKSUM,value,result);};

	if (strcmp("SO_DEBUG",aString)==0) 			    	{return SetFourByteOption(epi,trueIfGet,XTI_GENERIC,XTI_DEBUG,value,result);};
	if (strcmp("SO_REUSEADDR",aString)==0) 			    {return SetFourByteOption(epi,trueIfGet,INET_IP,kIP_REUSEADDR,value,result);;};
	if (strcmp("SO_REUSEPORT",aString)==0) 			    {return SetFourByteOption(epi,trueIfGet,INET_IP,kIP_REUSEPORT,value,result);};
	if (strcmp("SO_DONTROUTE",aString)==0) 			    {return SetFourByteOption(epi,trueIfGet,INET_IP,kIP_DONTROUTE,value,result);};
	if (strcmp("SO_BROADCAST",aString)==0) 			    {return SetFourByteOption(epi,trueIfGet,INET_IP,kIP_BROADCAST,value,result);};
	if (strcmp("SO_SNDBUF",aString)==0) 			    {return SetFourByteOption(epi,trueIfGet,XTI_GENERIC,XTI_SNDBUF,value,result);};
	if (strcmp("SO_RCVBUF",aString)==0) 			    {return SetFourByteOption(epi,trueIfGet,XTI_GENERIC,XTI_RCVBUF,value,result);};
	if (strcmp("SO_KEEPALIVE",aString)==0) 			   {return SetKeepAliveOption(epi,trueIfGet,INET_TCP,TCP_KEEPALIVE,value,result);};
	if (strcmp("SO_OOBINLINE",aString)==0) 			    {return SetFourByteOption(epi,trueIfGet,INET_TCP,TCP_OOBINLINE,value,result);};
	if (strcmp("SO_PRIORITY",aString)==0) 			     {return SetOneByteOption(epi,trueIfGet,INET_IP,kIP_TOS,value,result);};
	if (strcmp("SO_LINGER",aString)==0) 			      {return SetLingerOption(epi,trueIfGet,XTI_GENERIC,XTI_LINGER,value,result);};
	if (strcmp("SO_RCVLOWAT",aString)==0) 			    {return SetFourByteOption(epi,trueIfGet,XTI_GENERIC,XTI_RCVLOWAT,value,result);};
	if (strcmp("SO_SNDLOWAT",aString)==0) 			    {return SetFourByteOption(epi,trueIfGet,XTI_GENERIC,XTI_SNDLOWAT,value,result);};	
	
	if (strcmp("IP_OPTIONS",aString)==0) 			    { }; //JMM What to do here?	
	if (strcmp("IP_TTL",aString)==0) 			         {return SetOneByteOption(epi,trueIfGet,INET_IP,kIP_TTL,value,result);};	
	if (strcmp("IP_HDRINCL",aString)==0) 			    {return SetFourByteOption(epi,trueIfGet,INET_IP,kIP_HDRINCL,value,result);}; //NOT SUPPORT FOR IP	
	if (strcmp("IP_RCVOPTS",aString)==0) 			    {return SetFourByteOption(epi,trueIfGet,INET_IP,kIP_RCVOPTS,value,result);};	
	if (strcmp("IP_RCVDSTADDR",aString)==0) 			{return SetFourByteOption(epi,trueIfGet,INET_IP,kIP_RCVDSTADDR,value,result);};	
	if (strcmp("IP_MULTICAST_IF",aString)==0) 			{return SetFourByteOption(epi,trueIfGet,INET_IP,kIP_MULTICAST_IF,value,result);};	
	if (strcmp("IP_MULTICAST_TTL",aString)==0) 			 {return SetOneByteOption(epi,trueIfGet,INET_IP,kIP_MULTICAST_TTL,value,result);};	
	if (strcmp("IP_MULTICAST_LOOP",aString)==0) 	     {return SetOneByteOption(epi,trueIfGet,INET_IP,kIP_MULTICAST_LOOP,value,result);};	
	if (strcmp("IP_ADD_MEMBERSHIP",aString)==0) 	    { return SetEightByteOption(epi,trueIfGet,INET_IP,kIP_ADD_MEMBERSHIP,(char *) value,result);};	
	if (strcmp("IP_DROP_MEMBERSHIP",aString)==0) 	    { return SetEightByteOption(epi,trueIfGet,INET_IP,kIP_DROP_MEMBERSHIP,(char *) value,result);};	
	if (strcmp("IP_BROADCAST_IFNAME",aString)==0) 	        {return SetFourByteOption(epi,trueIfGet,INET_IP,kIP_BROADCAST_IFNAME,value,result);};	
	if (strcmp("IP_RCVIFADDR",aString)==0) 	            {return SetFourByteOption(epi,trueIfGet,INET_IP,kIP_RCVIFADDR,value,result);};	

    *result = 0;
    return -1;
}

static OTResult SetEightByteOption(EPInfo* epi,Boolean trueIfGet, OTXTILevel level, OTXTIName  name, char * value, SInt32    *returnValue) {
   OTResult err;
   UInt8    optBuffer[kOTFourByteOptionSize+4];
   TOption  *option = (TOption *) &optBuffer;
   TOptMgmt request;
   TOptMgmt result;
   Boolean isAsync=false;
   
   /* Set up the option buffer to specify the option and value to set. */
   option->len  = kOTFourByteOptionSize+4;
   option->level= level;
   option->name = name;
   option->status = 0;
   if (!trueIfGet) 
    OTMemcpy(option->value,value,8);
    
   /* Set up request parameter for OTOptionManagement */
   request.opt.buf= (UInt8 *) option;
   request.opt.len= sizeof(optBuffer);
   request.opt.maxlen=sizeof(optBuffer);
   request.flags  = trueIfGet ? T_CURRENT : T_NEGOTIATE;

   /* Set up reply parameter for OTOptionManagement. */
   result.opt.buf  = (UInt8 *) option;
   result.opt.maxlen  = sizeof(optBuffer);
  
    if (OTIsSynchronous(epi->erf) == false)	{	// check whether ep sync or not
		isAsync = true;			                // set flag if async
		OTSetSynchronous(epi->erf);			        // set endpoint to sync	
	}
				
				
    err = OTOptionManagement(epi->erf, &request, &result);
	
	if (isAsync)				        // restore ep state 
		OTSetAsynchronous(epi->erf);
    
	*returnValue = option->value[0];

   if (err == noErr) {
      if (option->status != T_SUCCESS) 
         err = option->status;
   } 
            
   return (err);
}

static OTResult SetFourByteOption(EPInfo* epi,Boolean trueIfGet, OTXTILevel level, OTXTIName  name, UInt32   value, SInt32    *returnValue) {
   OTResult err;
   UInt8    optBuffer[kOTFourByteOptionSize];
   TOption  *option = (TOption *) &optBuffer;
   TOptMgmt request;
   TOptMgmt result;
   Boolean isAsync=false;
   
   /* Set up the option buffer to specify the option and value to set. */
   option->len  = kOTFourByteOptionSize;
   option->level= level;
   option->name = name;
   option->status = 0;
   option->value[0] = value;

   /* Set up request parameter for OTOptionManagement */
   request.opt.buf= (UInt8 *) option;
   request.opt.len= sizeof(optBuffer);
   request.opt.maxlen=sizeof(optBuffer);
   request.flags  = trueIfGet ? T_CURRENT : T_NEGOTIATE;

   /* Set up reply parameter for OTOptionManagement. */
   result.opt.buf  = (UInt8 *) option;
   result.opt.maxlen  = sizeof(optBuffer);
  
    if (OTIsSynchronous(epi->erf) == false)	{	// check whether ep sync or not
		isAsync = true;			                // set flag if async
		OTSetSynchronous(epi->erf);			        // set endpoint to sync	
	}
				
				
    err = OTOptionManagement(epi->erf, &request, &result);
	
	if (isAsync)				        // restore ep state 
		OTSetAsynchronous(epi->erf);
    
	*returnValue = option->value[0];

   if (err == noErr) {
      if (option->status != T_SUCCESS) 
         err = option->status;
   } 
            
   return (err);
}

static OTResult SetOneByteOption(EPInfo* epi,Boolean trueIfGet, OTXTILevel level, OTXTIName  name, UInt32   value, SInt32    *returnValue) {
   OTResult err;
   UInt8    optBuffer[kOTFourByteOptionSize];
   TOption  *option = (TOption *) &optBuffer;
   TOptMgmt request;
   TOptMgmt result;
   Boolean isAsync=false;
   
   /* Set up the option buffer to specify the option and value to set. */
   option->len  = kOTOneByteOptionSize;
   option->level= level;
   option->name = name;
   option->status = 0;
   *(unsigned char *)option->value = value;

   /* Set up request parameter for OTOptionManagement */
   request.opt.buf= (UInt8 *) option;
   request.opt.len= kOTOneByteOptionSize;
   request.opt.maxlen=sizeof(optBuffer);
   request.flags  = trueIfGet ? T_CURRENT : T_NEGOTIATE;

   /* Set up reply parameter for OTOptionManagement. */
   result.opt.buf  = (UInt8 *) option;
   result.opt.maxlen  = sizeof(optBuffer);
   
    if (OTIsSynchronous(epi->erf) == false)	{	// check whether ep sync or not
		isAsync = true;			                // set flag if async
		OTSetSynchronous(epi->erf);			        // set endpoint to sync	
	}
				
    err = OTOptionManagement(epi->erf, &request, &result);
	
	if (isAsync)				        // restore ep state 
		OTSetAsynchronous(epi->erf);
    
	*returnValue = (UInt32) (*(unsigned char *)option->value);

   if (err == noErr) {
      if (option->status != T_SUCCESS) 
         err = option->status;
   }
            
   return (err);
}

static OTResult SetKeepAliveOption(EPInfo* epi,Boolean trueIfGet, OTXTILevel level, OTXTIName  name, UInt32   value, SInt32    *returnValue) {
   OTResult err;
   TKeepAliveOpt  optBuffer;
   TOption  *option = (TOption *) &optBuffer;
   TOptMgmt request;
   TOptMgmt result;
   Boolean isAsync=false;
   
   
   if (value == 0)
       optBuffer.tcpKeepAliveOn = T_NO;
   else
        optBuffer.tcpKeepAliveOn = T_YES;
        
   optBuffer.tcpKeepAliveTimer = value;
				
   /* Set up the option buffer to specify the option and value to set. */
   option->len  = sizeof(TKeepAliveOpt);
   option->level= level;
   option->name = name;
   option->status = 0;

   /* Set up request parameter for OTOptionManagement */
   request.opt.buf= (UInt8 *) option;
   request.opt.len= sizeof(TKeepAliveOpt);
   request.opt.maxlen=sizeof(TKeepAliveOpt);
   request.flags  = trueIfGet ? T_CURRENT : T_NEGOTIATE;

   /* Set up reply parameter for OTOptionManagement. */
   result.opt.buf  = (UInt8 *) option;
   result.opt.maxlen  = sizeof(TKeepAliveOpt);
   
    if (OTIsSynchronous(epi->erf) == false)	{	// check whether ep sync or not
		isAsync = true;			                // set flag if async
		OTSetSynchronous(epi->erf);			        // set endpoint to sync	
	}
				
    err = OTOptionManagement(epi->erf, &request, &result);
	
	if (isAsync)				        // restore ep state 
		OTSetAsynchronous(epi->erf);
    
	*returnValue = optBuffer.tcpKeepAliveTimer;

   if (err == noErr) {
      if (option->status != T_SUCCESS) 
         err = option->status;
   }
            
   return (err);
}
		    

static OTResult SetLingerOption(EPInfo* epi,Boolean trueIfGet, OTXTILevel level, OTXTIName  name, UInt32   value, SInt32    *returnValue) {
   OTResult err;
   TLingerOpt  optBuffer;
   TOption  *option = (TOption *) &optBuffer;
   TOptMgmt request;
   TOptMgmt result;
   Boolean isAsync=false;
   
   
   if (value == 0)
       optBuffer.tcpLingerOn = T_NO;
   else
        optBuffer.tcpLingerOn = T_YES;
        
   optBuffer.tcpLingerTimer = value;
				
   /* Set up the option buffer to specify the option and value to set. */
   option->len  = sizeof(TKeepAliveOpt);
   option->level= level;
   option->name = name;
   option->status = 0;

   /* Set up request parameter for OTOptionManagement */
   request.opt.buf= (UInt8 *) option;
   request.opt.len= sizeof(TKeepAliveOpt);
   request.opt.maxlen=sizeof(TKeepAliveOpt);
   request.flags  = trueIfGet ? T_CURRENT : T_NEGOTIATE;

   /* Set up reply parameter for OTOptionManagement. */
   result.opt.buf  = (UInt8 *) option;
   result.opt.maxlen  = sizeof(TKeepAliveOpt);
   
    if (OTIsSynchronous(epi->erf) == false)	{	// check whether ep sync or not
		isAsync = true;			                // set flag if async
		OTSetSynchronous(epi->erf);			        // set endpoint to sync	
	}
				
    err = OTOptionManagement(epi->erf, &request, &result);
	
	if (isAsync)				        // restore ep state 
		OTSetAsynchronous(epi->erf);
    
	*returnValue = optBuffer.tcpLingerTimer;

   if (err == noErr) {
      if (option->status != T_SUCCESS) 
         err = option->status;
   }
            
   return (err);
}


//
//	Notifier:
//
//	Most of the interesting networking code in this program for the resolver resides inside 
//	this notifier.   In order to run asynchronously and as fast as possible,
//	things are done inside the notifier whenever possible.  Since almost
//	everything is done inside the notifier, there was little need for specical
//	synchronization code.
//
//	Note: The only events which are expected from the DNR are T_DNRSTRINGTOADDRCOMPLETE,
//	T_DNRADDRTONAMECOMPLETE, and of close sleep/reconfigure notifications.
//
//

static pascal void DNSNotifier(void* context, OTEventCode event, OTResult result, void* cookie)
{
#pragma unused(cookie)
	EPInfo* epi = (EPInfo*) context;

	JMMLogMessageAndNumber("\p DNS Event  ",event);
	JMMLogMessageAndNumber("\p DNS Result ",result);
	JMMLogMessageAndNumber("\p Id ",epi->semaIndex);
	
	//
	//	Once the program is shutting down, most events would be uninteresting.
	//
	if (gProgramState != kProgramRunning)
			return;
		
	//
	//	Within the notifier, all action is based on the event code.
	//	In this notifier, fatal errors all break out of the switch to the bottom.
	//	As long as everything goes as expected, the case returns rather than breaks.
	//
	switch (event)
	{
		//
		//	T_DNRSTRINGTOADDRCOMPLETE:
		//
		//	This event occurs when the DNR has finished an attempt to translate
		//	the server's name into an IP address we can use to connect to.
		//
		case T_DNRSTRINGTOADDRCOMPLETE:
		{
			gDNSResolverError = result;
			if (result != kOTNoError) {
				gDNSResolverStatus = RESOLVER_ERROR;
    			interpreterProxy->signalSemaphoreWithIndex(epi->semaIndex);
				return;
			}
			gDNSAddr = gDNSHostInfo.addrs[0];
			gDNSResolverStatus = RESOLVER_SUCCESS;
			interpreterProxy->signalSemaphoreWithIndex(epi->semaIndex);
			return;
		}
		
		//
		//	T_DNRADDRTONAMECOMPLETE:
		//
		//	This event occurs when the DNR has finished an attempt to translate
		//	the  an IP address into a server name.
		//
		case T_DNRADDRTONAMECOMPLETE:
		{
			gDNSResolverError = result;
			if (result != kOTNoError) {
				gDNSResolverStatus = RESOLVER_ERROR;
    			interpreterProxy->signalSemaphoreWithIndex(epi->semaIndex);
				return;
			}
			gDNSResolverStatus = RESOLVER_SUCCESS;
			interpreterProxy->signalSemaphoreWithIndex(epi->semaIndex);
			return;
		}
				
			
		//
		//	kOTProviderWillClose:
		//
		//	This event occurs when the user changes TCP/IP in the control panel
		//
		case kOTProviderWillClose:
		case kOTProviderIsClosed:
		{
			gDNSResolverError = kOTProviderWillClose;
			interpreterProxy->signalSemaphoreWithIndex(epi->semaIndex);
			ResolverTerminate(); 
			gDNSResolverStatus = RESOLVER_SUCCESS; //Cheat! Keep Squeak happy later we fix the resolver EP.
			return;
		}

		
		//
		//	default:
		//
		//	There are events which we don't handle, but we don't expect to see
		//	any of them.  In the production version of the program, we ignore the event and try to keep running.
		//
		default:
		{
			return;
		}
	}
}



//
//	Notifier for socket: Please note we have another notifier for sockets that do multiple listens
//  And a different notifier for UDP sockets, however the intesting thing is that we can call
/// This routine from othe other as a simple form of inheritence.
//
//	Most of the interesting networking code in this program for socket support resides inside 
//	this notifier.   In order to run asynchronously and as fast as possible,
//	things are done inside the notifier whenever possible.  Since almost
//	everything is done inside the notifier, there was little need for specical
//	synchronization code.
//
//	IMPORTANT NOTE:  Normal events defined by XTI (T_LISTEN, T_CONNECT, etc)
//	and OT completion events (T_OPENCOMPLETE, T_BINDCOMPLETE, etc.) are not
//	reentrant.  That is, whenever our notifier is invoked with such an event,
//	the notifier will not be called again by OT for another normal or completion
//	event until we have returned out of the notifier - even if we make OT calls
//	from inside the notifier.   This is a useful synchronization tool.
//	However, there are two kinds of events which will cause the notifier to 
//	be reentered.   One is T_MEMORYRELEASED, which always happens instantly.
//	The other are state change events like kOTProviderWillClose.
//

static pascal void NotifierSocket(void* context, OTEventCode event, OTResult result, void* cookie)
{
	OSStatus err;
	OTResult epState;
	EPInfo* epi = (EPInfo*) context;
	
	JMMLogMessageAndNumber("\p Event  ",event);
	JMMLogMessageAndNumber("\p Result ",result);
	JMMLogMessageAndNumber("\p Id ",epi->semaIndex);

	//
	//	Once the program is shutting down, most events would be uninteresting.
	//	However, we still need T_OPENCOMPLETE and T_MEMORYRELEASED events since
	//	we can't call CloseOpenTransport until all OTAsyncOpenEndpoints and
	//	OTSends with AckSends have completed.   So those specific events
	//	are still accepted.
	//
	if (gProgramState != kProgramRunning) {
		if ((event != T_OPENCOMPLETE) && (event != T_MEMORYRELEASED)) {
			return;
		}
	}
	
	
	//
	//	Within the notifier, all action is based on the event code.
	//	In this notifier, fatal errors all break out of the switch to the bottom.
	//	As long as everything goes as expected, the case returns rather than breaks.
	//
	switch (event)
	{
		//
		//	kStreamIoctlEvent:
		//
		//	This event is returned when an I_FLUSH ioctl has completed.
		//	The flush was done in an attempt to get back all T_MEMORYRELEASED events
		//	for outstanding OTSnd() calls with Ack Sends.   For good measure, we
		//	send a disconnect now.   Errors are ignored at this point since it is
		//	possible that the connection will already be gone, etc.
		//
		case kStreamIoctlEvent:
		{
			if (OTAtomicTestBit(&epi->stateFlags, kOpenInProgressBit) != 0) {
			    OTAtomicClearBit(&epi->stateFlags2, kFlushDisconnectInProgressBit);
				(void) OTSndDisconnect(epi->erf, NULL);
			}
			return;
		}
		//
		//	T_ACCEPTCOMPLETE:
		//
		//	This event is received by the listener endpoint only when we open a port with a listen.   
		//	The acceptor endpoint will get a T_PASSCON event instead.
		//
		case T_ACCEPTCOMPLETE:
		{
            SetEPLastError(epi,result);
			if (result != kOTNoError) {
				makeEPUnconnected(epi);
        		return;
            }
            makeEPConnected(epi);
			return;
		}
		//
		//	T_BINDCOMPLETE:
		//
		//	This event is returned when an endpoint has been bound to a wildcard addr.
		//  Bind happens when we open a connection to a remote location.
		//	No errors are expected.   
		//
		case T_BINDCOMPLETE:
		{
            SetEPLastError(epi,result);
			OTAtomicClearBit(&epi->stateFlags3, kWaitingForBind);
			if (result != kOTNoError) {
            	makeEPUnconnected(epi);
				return;
			}
			if (epi->remoteAddress.fHost != 0) 
			    DoConnect(epi,epi->remoteAddress.fHost, epi->remoteAddress.fPort);
			return;
		}
		
		//
		//	T_CONNECT:
		//
		//	This event is returned when a connection is established to the server.
		//	The program must call OTRcvConnect() to get the conenction information
		//	and clear the T_CONNECT event from the stream.  Since OTRcvConnect()
		//	returns immediately (rather than via a completion event to the notifier)
		//	we can use local stack structures for parameters.
		//
		case T_CONNECT:
		{
			TCall call;
						
            SetEPLastError(epi,result);
			if (result != kOTNoError) {
				makeEPUnconnected(epi);
  				return;
			}
			
			// Address of endpoint that has connection
			// This could be different from original request
			// Due to hand off to different EP say you connect to 
			// port 80, but you end up on 49160
			
			call.addr.maxlen = sizeof(InetAddress);
			call.addr.buf = (unsigned char*) &epi->remoteAddress;  
			call.opt.maxlen = 0;
			call.opt.buf = NULL;
			call.udata.maxlen = 0;
			call.udata.buf = NULL;
			
			err = OTRcvConnect(epi->erf, &call);
			SetEPLastError(epi,err);

			if (err != kOTNoError) {
			    if (err == kOTLookErr) {
			        OSStatus	lookStatus;
			        lookStatus = OTLook(epi->erf);
			        if (lookStatus == T_DISCONNECT) {
               			err = OTRcvDisconnect(epi->erf, NULL);
        	    		if (err != kOTNoError) {
        		    		if (err == kOTNoDisconnectErr) {
                    			err = OTRcvConnect(epi->erf, &call);
                    			SetEPLastError(epi,err);
                       			makeEPUnconnected(epi);
       		    		        return;
       		    		    }
			            } else {
                			err = OTRcvConnect(epi->erf, &call);
                			SetEPLastError(epi,err);
                   			makeEPUnconnected(epi);
   		    		        return;
			            }
			        }
			        if (lookStatus == T_GODATA) { // HUH
            			err = OTRcvConnect(epi->erf, &call);
            			SetEPLastError(epi,err);
               			makeEPConnected(epi);
	    		        return;
			        }
			    }
                //JMM book says may return kOTNoDataErr (no connecton yet) or a kOTLookErr with T_DISCONNECT
                // BUT we had got T_GODATA WHY? 
                
				makeEPUnconnected(epi);
				return;
			}
			
			makeEPConnected(epi);
			return;				// Wait for a T_DATA...
		}
		
		//
		//	T_LISTEN:
		//
		case T_LISTEN:
		{
			DoListenAccept(epi,epi);
			return;
		}

		//
		//	T_DATA:
		//
		//	The main rule for processing T_DATA's is to remember that once you have
		//	a T_DATA, you won't get another one until you have read to a kOTNoDataErr.
		//	The advanced rule is to remember that you could get another T_DATA
		//	during an OTRcv() which will eventually return kOTNoDataErr, presenting
		//	the application with a synchronization issue to be most careful about.
		//	
		//	In this application, since an OTRcv() calls are made from inside the notifier,
		//	this particular synchronization issue doesn't become a problem.
		//
		case T_DATA:
		{
			if (!OTAtomicTestBit(&epi->stateFlags2, kPassconNeeded)) {
			    ReadData(epi,NULL,0);
			    return;
			 }
			 else {
    			//
    			//	Here we work around a small OpenTransport bug.
    			//	It turns out, since this program does almost everything from inside the notifier,
    			//	that during a T_UNBINDCOMPLETE we can put an EPInfo back into the idle list.
    			//	If that notification is interrupted by a T_LISTEN at the notifier, we could
    			//	end up starting a new connection on the endpoint before OT unwinds the stack
    			//	out of the code which delivered the T_UNBINDCOMPLETE.   OT has some specific
    			//	code to protect against a T_DATA arriving before the T_PASSCON, but in this
    			//	case it gets confused and the events arrive out of order.   If we try to
    			//	do an OTRcv() at this point we will get a kOTStateChangeErr because the endpoint
    			//	is still locked by the earlier OTAccept call until the T_PASSCON is delivered
    			//	to us.   This is fairly benign and can be worked around easily.  What we do
    			//	is note that the T_PASSCON hasn't arrived yet and defer the call to ReadData()
    			//	until it does.
    			//
    			if ( OTAtomicSetBit(&epi->stateFlags, kPassconBit) != 0 )
    			{
    			    ReadData(epi,NULL,0);
    			    return;
    			}
    		}
		}					

		//
		//	T_PASSCON:
		//
		//	This event happens on the accepting endpoint, not the listening endpoint.
		//	At this point the connection is fully established and we can begin the
		//	process of downloading data.  Note that due to a problem in OT it is 
		//	possible for a T_DATA to beat a T_PASSCON to the notifier.  When this
		//	happens we note it in the T_DATA case and then start processing the 
		//	data here.  
		//
		case T_PASSCON:
		{
            SetEPLastError(epi,result);
			if (result != kOTNoError) {
               	OTAtomicSetBit(&epi->stateFlags, kPassconBit);
   				makeEPUnconnected(epi);
				return;
			}
			
   			makeEPConnected(epi);
                
		    if ( OTAtomicSetBit(&epi->stateFlags, kPassconBit) != 0 ){
				//
				//	A T_DATA previously beat the T_PASSCON to our notifier.
				//	Here we help OT out by having deferred data processing until now.
				//
			    ReadData(epi,NULL,0);
			}
			return;
		}
		//
		// T_MEMORYRELEASED
		// lower level has finished with buffer
				
		case T_MEMORYRELEASED:
		{
		    if (cookie == nil) return;
			OTAtomicAdd32(-1, &epi->outstandingSends);
			
	    	if (epi->socketType == UDPSocketType) {
		        OTFreeMem(cookie);
	    	} else {//tcp
		    	if (gOTVersion < kOTVersion113) {
		    		struct OTData *data=cookie;

		    		OTFreeMem(data->fData);
		    		OTFreeMem(data);
		    	} else {
		        	OTFreeMem(cookie);
		        }
	        }
	        	
		    return;
		}
			
		//
		//	T_DISCONNECT:
		//
		//	An inbound T_DISCONNECT event usually indicates that the other side of the
		//	connection did an abortive disconnect (as opposed to an orderly release).
		//	It also can be generated by the transport provider on the system (e.g. tcp)
		//	when it decides that a connection is no longer in existance.
		//
		//	We receive the disconnect, but this program ignores the associated reason (NULL param).
		//	It is possible to get back a kOTNoDisconnectErr from the OTRcvDisconnect call.
		//	This can happen when either (1) the disconnect on the stream is hidden by a 
		//	higher priority message, or (2) something has flushed or reset the disconnect
		//	event in the meantime.   This is not fatal, and the appropriate thing to do is
		//	to pretend the T_DISCONNECT event never happened.   Any other error is unexpected
		//	and needs to be reported so we can fix it.  Next, unbind the endpoint so we can
		//	reuse it for a new inbound connection.
		//	
		//	It is possible to get an error on the unbind due to a bug in OT 1.1.1 and earlier.
		//	The best thing to do for that is close the endpoint and open a new one to replace it.
		//	We do this back in the main thread so we don't have to deal with synchronization problems.
		//
		case T_DISCONNECT:
		{
			epState = OTGetEndpointState(epi->erf);
			err = OTRcvDisconnect(epi->erf, NULL);
			
			if (epState == T_OUTCON) { //01Aug2000 fix for bad port, will get disconnect on outgoing connection
                makeEPUnconnected(epi);
			}
			if (err != kOTNoError) {
				if (err == kOTNoDisconnectErr) return;
			    makeEPBroken(epi,err);
				return;
			}
			
                ///
                //Both sides now have closed 
                //
            
            OTAtomicSetBit(&epi->stateFlags, kUnConnected);			
	        OTAtomicClearBit(&epi->stateFlags, kConnected);
            OTAtomicClearBit(&epi->stateFlags, kThisEndClosed);			
            OTAtomicClearBit(&epi->stateFlags, kOtherEndClosed);			
			err = OTUnbind(epi->erf);
    	    TapAllInterestedSemaphores(epi);
			if (err != kOTNoError) {
			    makeEPBroken(epi,err);
			}
			return;
		}
		
		//
		//	T_GODATA:
		//
		//	This event is received when flow control is lifted.   We are under flow control
		//	whenever OTSnd() returns a kOTFlowErr or accepted less bytes than we attempted
		//	to send.  
		//
		//	Note, it is also possible to get a T_GODATA without having invoke flow control.
		//	Be safe and prepare for this. 
		//
		case T_GODATA:
		{
            if (OTAtomicClearBit(&epi->stateFlags, kSendIsBlocked)) {
 	           if (OTAtomicClearBit(&epi->stateFlags2, kTapSemaphoreWriteData))
  	              interpreterProxy->signalSemaphoreWithIndex(epi->writeSemaIndex);
            };
			return;
		}

		
		//
		//	T_OPENCOMPLETE:
		//
		//	This event occurs when an OTAsyncOpenEndpoint() completes.   Note that this event,
		//	just like any other async call made from outside the notifier, can occur during
		//	the call to OTAsyncOpenEndpoint().  That is, in the main thread the program did
		//	the OTAsyncOpenEndpoint(), and the notifier is invoked before control is returned
		//	to the line of code following the call to OTAsyncOpenEndpoint().   This is one
		//	event we need to keep track of even if we are shutting down the program since there
		//	is no way to cancel outstanding OTAsyncOpenEndpoint() calls.
		//
		case T_OPENCOMPLETE:
		{
			TOptMgmt 			optReq;
			TOption             opt;

			OTAtomicClearBit(&epi->stateFlags, kOpenInProgressBit);
			if (result == kOTNoError)
				epi->erf = (EndpointRef) cookie;
			else {
				makeEPBrokenThenIdle(epi,result);
				return;
			}

			if (gProgramState != kProgramRunning) return;
			
				
			//
			//	Set to blocking mode so we don't have to deal with kEAGAIN errors.
			//	Async/blocking is the best mode to write an OpenTransport application in.
			//
			err = OTSetBlocking(epi->erf);
			if (err != kOTNoError) {
			    makeEPBrokenThenIdle(epi,err);
				return;
			}
			
			//
			//	Set to AckSends so OT doesn't slow down to copy data sent out.
			//	However, this requires special care when closing endpoints, so don't use
			//	AckSends unless you are prepared for this.   Never, ever, close an endpoint
			//	when a send has been done but the T_MEMORYRELEASED event hasn't been returned yet.
			//
			err = OTAckSends(epi->erf);
			if (err != kOTNoError) {
			    makeEPBrokenThenIdle(epi,err);
				return;
			}
			
			//
			//	Option Management
			//
			//	Turn on ip_reuseaddr so we don't have port conflicts in general.
			//	We use local stack structures here since the memory for the 
			//	option request structure is free upon return.   If we were to request
			//	the option return value, we would have to use static memory for it.
			//
			optReq.flags			= T_NEGOTIATE;
			optReq.opt.len			= kOTFourByteOptionSize;
			optReq.opt.buf			= (unsigned char *) &opt;
			
			opt.len					= sizeof(TOption);
			opt.level				= INET_IP;
			opt.name				= kIP_REUSEADDR;
			opt.status				= 0;
			opt.value[0]			= 1;
			
            if (epi->socketType == TCPSocketType) 
                OTAtomicSetBit(&epi->stateFlags3, kKeepAliveOptionNeeded);
                
			err = OTOptionManagement(epi->erf, &optReq, NULL);
			if (err != kOTNoError) {
			    makeEPBrokenThenIdle(epi,err);
			}
			
			//
			//	Code path resumes at T_OPTMGMTCOMPLETE
			//
			
			return;
		}
		
		//
		//	T_OPTMGMTCOMPLETE:
		//
		//	An OTOptionManagement() call has completed.  These are used on all
		//	endpoints to set IP_REUSEADDR.   It is also used for all endpoints
		//	other than the listener to set TCP_KEEPALIVE which helps recover
		//	server resources if the other side crashes or is unreachable.
		//
		case T_OPTMGMTCOMPLETE:
		{
			TOptMgmt 			optReq;

			if (result != kOTNoError) {
			    makeEPBrokenThenIdle(epi,result);
				return;
			}
			
            if (OTAtomicClearBit(&epi->stateFlags3, kKeepAliveOptionNeeded)) {
                
                TKeepAliveOpt		opt;
				//
				//	Turn on TCP_KEEPALIVE so we can recover from connections which have
				//	gone away which we don't know about.  
				//
				optReq.flags			= T_NEGOTIATE;
				optReq.opt.len			= sizeof(TKeepAliveOpt);
				optReq.opt.buf			= (unsigned char *) &opt;
				
				opt.len					= sizeof(TKeepAliveOpt);
				opt.level				= INET_TCP;
				opt.name				= TCP_KEEPALIVE;
				opt.status				= 0;
				opt.tcpKeepAliveOn		= 1;
				opt.tcpKeepAliveTimer	= kTCPKeepAliveInMinutes;	
				
				err = OTOptionManagement(epi->erf, &optReq, NULL);
				if (err != kOTNoError) {
    			    makeEPBrokenThenIdle(epi,result);
                }
                return;
            }
						
            makeEPIdle(epi);  //This is where more EP enter the queue of available EPs.
            
			return;			// now wait 
		}
		//
		//	T_ORDREL:
		//
		//	This event occurs when an orderly release has been received on the stream.
		//
		case T_ORDREL:
		{
			err = OTRcvOrderlyDisconnect(epi->erf);
			
			if (err != kOTNoError) {
				//
				//	It is possible for several reasons for the T_ORDREL to have disappeared,
				//	or be temporarily hidden, when we attempt the OTRcvOrderlyDisconnect().
				//	The best thing to do when this happens is pretend that the event never
				//	occured.   We will get another notification of T_ORDREL if the event
				//	becomes unhidden later.  Any other form of error is unexpected and 
				//	is reported back so we can correct it.
				//
				if (err == kOTNoReleaseErr)
					return;
				//Can get OTLookErr with T_DISCONNECT
    		   makeEPBroken(epi,err);
			}	

			if (OTAtomicTestBit(&epi->stateFlags, kThisEndClosed)) {
                
                ///
                //Both sides now have closed
                //
                
                OTAtomicSetBit(&epi->stateFlags, kUnConnected);			
    	        OTAtomicClearBit(&epi->stateFlags, kConnected);
                OTAtomicClearBit(&epi->stateFlags, kThisEndClosed);			
                OTAtomicClearBit(&epi->stateFlags, kOtherEndClosed);			
				
				epState = OTGetEndpointState(epi->erf);
				if (epState != T_IDLE) {
            	    TapAllInterestedSemaphores(epi);
				    return;
				}

				err = OTUnbind(epi->erf);
        	    TapAllInterestedSemaphores(epi);
				if (err != kOTNoError) {
				    makeEPBroken(epi,err);
				}
				
    		    return;
            } else {
    			OTAtomicSetBit(&epi->stateFlags, kOtherEndClosed);
			}
			
			//
			//	Sometimes our data sends get stopped with a kOTLookErr
			//	because of a T_ORDREL from the other side (which doesn't close
			//	the connection, it just means they are done sending data).
			//	If so, we still end up in the notifier with the T_ORDREL event,
			//	but we won't resume sending data unless we explictly check
			//	here whether or not we need to do so.
			//
             //JMM Test this? 

            if (OTAtomicClearBit(&epi->stateFlags, kSendIsBlocked)) {
  		    	if (OTAtomicClearBit(&epi->stateFlags2, kTapSemaphoreWriteData))
                	interpreterProxy->signalSemaphoreWithIndex(epi->writeSemaIndex);
            };

			return;
		}
		
		//
		//	T_UNBINDCOMPLETE:
		//
		//	This event occurs on completion of an OTUnbind().
		//	The endpoint is ready for reuse on a new inbound connection.
		//	Note that the OTLIFO structure has atomic queue and dequeue,
		//	which can be helpful for synchronization protection.  
		//
		case T_UNBINDCOMPLETE:
		{
			if (result != kOTNoError) {
				//
				//	Unbind errors can occur as a result of a bug in OT 1.1.1 and earlier
				//	versions.   The best recovery is to put the endpoint in the broken
				//	list for recycling with a clean, new endpoint.
				//  Since we only support 1.1.2 we don't expect to run this code.
				//
			    makeEPBroken(epi,result);
				return;
			}
			return;
		}
		
		
		//
		//	T_DISCONNECTCOMPLETE:
		//
		//	This event occurs on completion of an OTSndDisconnect().
		//	Called when we abort a socket
		//
		case T_DISCONNECTCOMPLETE: {
			err = OTUnbind(epi->erf);
			if (err != kOTNoError) {
			    makeEPBroken(epi,err);
			}

			purgeReadBuffers(epi);		
            TapAllInterestedSemaphores(epi); 
			if (OTAtomicTestBit(&epi->stateFlags2, kMakeEPIdle)) { //Make EP idle if marked as such only happens via destroy. 
			    makeEPIdle(epi);
			}
			epi->stateFlags = 0;
			epi->stateFlags2 = 0;
			epi->stateFlags3 = 0;
            SetEPLastError(epi,result);
        	OTAtomicSetBit(&epi->stateFlags, kUnConnected);
			return;
		}
		
		//
		//Sleep sleep sleep all end points get trashed.
		//
		case kOTProviderWillClose: // reconfig stack disconnect and close
		{
		    makeEPBroken(epi,-12345678);
            if(OTAtomicTestBit(&epi->stateFlags, kOpenInProgressBit)) return;
            OTSetSynchronous(epi->erf);			        // set endpoint to sync	
        	if ( OTAtomicSetBit(&epi->stateFlags2, kFlushDisconnectInProgressBit) == 0 )
        		err = OTIoctl(epi->erf, I_FLUSH, (void *)FLUSHRW);
            OTSndDisconnect(epi->erf, NULL);
            OTUnbind(epi->erf);
            OTCloseProvider(epi->erf);
            OTAtomicSetBit(&epi->stateFlags, kUnConnected);			
	        OTAtomicClearBit(&epi->stateFlags, kConnected);
            OTAtomicClearBit(&epi->stateFlags, kThisEndClosed);			
            OTAtomicClearBit(&epi->stateFlags, kOtherEndClosed);			
            OTAtomicSetBit(&epi->stateFlags3, kSleepKilledMe);
            TapAllInterestedSemaphores(epi); 
		    return;
		}

		case kOTProviderIsClosed: //Sleep lurks
		{
		    makeEPBroken(epi,-12345678);
            OTSetSynchronous(epi->erf);			        // set endpoint to sync	
        	if ( OTAtomicSetBit(&epi->stateFlags2, kFlushDisconnectInProgressBit) == 0 )
        		err = OTIoctl(epi->erf, I_FLUSH, (void *)FLUSHRW);
            OTCloseProvider(epi->erf);
            OTAtomicSetBit(&epi->stateFlags, kUnConnected);			
	        OTAtomicClearBit(&epi->stateFlags, kConnected);
            OTAtomicClearBit(&epi->stateFlags, kThisEndClosed);			
            OTAtomicClearBit(&epi->stateFlags, kOtherEndClosed);			
            OTAtomicSetBit(&epi->stateFlags3, kSleepKilledMe);
            TapAllInterestedSemaphores(epi); 
			return;
		}

		//
		//	default:
		//
		//	There are events which we don't handle, but we don't expect to see
		//	any of them.   When running in debugging mode while developing a program,
		//	we exit with an informational alert.   Later, in the production version
		//	of the program, we ignore the event and try to keep running.
		//
		default:
		{
			return;
		}
	}
}


//
//	Notifier for listen socket:
//


static pascal void NotifierSocketListener(void* context, OTEventCode event, OTResult result, void* cookie)
{
	EPInfo* epi = (EPInfo*) context;

	if (gProgramState != kProgramRunning)
	{
		if ((event != T_OPENCOMPLETE) && (event != T_MEMORYRELEASED))
		{
			return;
		}
	}
	JMMLogMessageAndNumber("\p Listener Event  ",event);
	JMMLogMessageAndNumber("\p Listener Result ",result);
	JMMLogMessageAndNumber("\p Listener Id ",epi->semaIndex);
	
	switch (event)
	{
		//
		//	T_BINDCOMPLETE:
		//
		//	We only bind the listener endpoint, and bind failure is a fatal error.  
		//	Acceptor endpoints are bound within the OTAccept() call when they get a connection.
		//
		case T_BINDCOMPLETE:
		{
            SetEPLastError(epi,result);
			OTAtomicClearBit(&epi->stateFlags3, kWaitingForBind);
			if (result != kOTNoError)
   				makeEPUnconnected(epi);
      
			return;
		}
				
		//
		//	T_LISTEN:
		//
		case T_LISTEN:
		{
            SetEPLastError(epi,result);
   			makeEPConnected(epi);
			return;
		}
		//
		//	T_ACCEPTCOMPLETE:
		//
		//	This event is received by the listener endpoint only.   
		//	The acceptor endpoint will get a T_PASSCON event instead.
		//
		case T_ACCEPTCOMPLETE:
		{
            SetEPLastError(epi,result);
			return;
		}

		
		//
		//	default:
		//
		//	There are events which we don't handle, pass them onwards
		//
		default:
		{
            NotifierSocket(context,  event,  result, cookie);
			return;
		}
	}
}


//
//	Notifier for UDP listen socket:
//


static pascal void NotifierSocketUDP(void* context, OTEventCode event, OTResult result, void* cookie)
{
	EPInfo* epi = (EPInfo*) context;
	OSStatus err;

	JMMLogMessageAndNumber("\p DNS Event  ",event);
	JMMLogMessageAndNumber("\p DNS Result ",result);
	JMMLogMessageAndNumber("\p Id ",epi->semaIndex);

	if (gProgramState != kProgramRunning) {
		if ((event != T_OPENCOMPLETE) && (event != T_MEMORYRELEASED)) {
			return;
		}
	}
		
	switch (event)
	{
		//Some sort of UDP send error, too late to tell anyone?
		//
		case T_UDERR: {  
    		TUDErr 		uderr;
		    InetAddress errorAddress;
            
            uderr.addr.maxlen   = sizeof(InetAddress);
            uderr.addr.len      = sizeof(InetAddress);
            uderr.addr.buf      = (UInt8 *) &errorAddress;
            uderr.opt.maxlen    = 0;
            uderr.opt.len       = 0;
            uderr.opt.buf       = NULL;
   
		    err =  OTRcvUDErr(epi->erf, &uderr);
            if (err != kOTNoError)   
				makeEPBroken(epi,err);
			
            SetEPLastError(epi,uderr.error);
		    return;
		}
		
		//
		//	T_DATA:
		//
		//  Got milk?
		//
		
		case T_DATA: {
			ReadData(epi,NULL,0);
		    return;
		}
		
		//
		//	T_BINDCOMPLETE:
		//
		//	This event is returned when an endpoint has been bound.
		//	No errors are expected.   
		//
		
		case T_BINDCOMPLETE:
		{
            SetEPLastError(epi,result);
			OTAtomicClearBit(&epi->stateFlags3, kWaitingForBind);
			if (result != kOTNoError) {
   				makeEPUnconnected(epi);
				return;
			}
   			makeEPConnected(epi);
			return;
		}

		//
		//	default:
		//
		//	There are events which we don't handle, pass them onwards to the regular notifier
		//
		
		default:
		{
            NotifierSocket(context,  event,  result, cookie);
			return;
		}
    }
}


short	        gJMMFile=0;
OTTimeStamp 	JMMStartTimeStamp;
OTLIFO			JMMLogBufferLIFO;    	//  Buffers that are free to read into
OTLIFO*			JMMLogBufferBuffers			= &JMMLogBufferLIFO;

 
void JMMWriteLog() {
	OSErr			error;
	OTLink* 	    list = OTReverseList(OTLIFOStealList(JMMLogBufferBuffers));
	OTLink*		    link;
	ReadBuffer      *aBuffer;
	long           dummySize;
	char			CH=0x0D;

	if (true) return;
	
	error = HCreate(0,0,"\pJMMFOOBAR.txt",'TEXT','TEXT');
	error = HOpenDF(0,0,"\pJMMFOOBAR.txt",fsRdWrPerm,&gJMMFile);
	error = SetFPos(gJMMFile,fsFromLEOF,0);

	while ( (link = list) != NULL ) {
		list = link->fNext;
    	aBuffer = OTGetLinkObject(link, ReadBuffer, fNext);
    	error = FSWrite(gJMMFile,(long *)&aBuffer->readBufferSize,aBuffer->readBufferData);
    	dummySize = 1;
    	error = FSWrite(gJMMFile,&dummySize,&CH);
	}
	error = FSClose(gJMMFile);
	
	while ( (link = list) != NULL ) {
		list = link->fNext;
    	aBuffer = OTGetLinkObject(link, ReadBuffer, fNext);
        OTFreeMem(aBuffer->readBufferData);
        OTFreeMem(aBuffer); 
	}
	
}

void JMMLogMessage(Str255 input) {
	Str255 			timeString;
	long 			timeStringLength,inputLength;
	UInt32			duration;
	ReadBuffer      *readBufferObject;
	
	if (true) return;
	
	if (gJMMFile == 0) {
		gJMMFile = 1;
		OTGetTimeStamp(&JMMStartTimeStamp);
		JMMLogBufferBuffers->fHead 		= NULL;

	}
	
	duration = OTElapsedMilliseconds(&JMMStartTimeStamp);
	NumToString(duration,timeString);
	timeStringLength = (unsigned char) timeString[0];
	inputLength = (unsigned char) input[0];
	
#if TARGET_API_MAC_CARBON
	readBufferObject = OTAllocMemInContext(sizeof(ReadBuffer), gClientContext);
#else
	readBufferObject = OTAllocMem(sizeof(ReadBuffer));
#endif
	if (readBufferObject == NULL) return;
	OTMemzero(readBufferObject,sizeof(ReadBuffer));
	
#if TARGET_API_MAC_CARBON
	readBufferObject->readBufferData = OTAllocMemInContext(60, gClientContext);
#else
	readBufferObject->readBufferData = OTAllocMem(60);
#endif
	if (readBufferObject->readBufferData == NULL) {
	    OTFreeMem(readBufferObject);
	    return;
	}
	
	OTMemcpy(readBufferObject->readBufferData,timeString+1,timeStringLength);
	OTMemcpy(readBufferObject->readBufferData+timeStringLength,input+1,inputLength);
	readBufferObject->readBufferSize= timeStringLength+inputLength;
    OTLIFOEnqueue(JMMLogBufferBuffers, &readBufferObject->fNext);
	
}

void JMMLogMessageAndNumber(Str255 msg,long number) {
	Str255 buffer,numberString;
	long msgLength,numberLength;
	
	if (true) return;
	
	NumToString(number,numberString);
	numberLength = (unsigned char) numberString[0];
	msgLength = (unsigned char) msg[0];
	
	OTMemcpy(buffer+1,msg+1,msgLength);
	OTMemcpy(buffer+1+msgLength,numberString+1,numberLength);
	buffer[0] = (unsigned char) msgLength+numberLength;
	JMMLogMessage(buffer);

}


/*
The Open Transport TCP/IP software modules provide a RawIP interface to the IP protocol

hostname of '' lookup fails This is OK? Same on linux and old mac version

JMM look at tlook page, not sure if we have completely understood it

JMM is it legal to send a zero byte buffer need case for this?

/* According to the XTI spec ("Section 4.6 Events and TLOOK Error indication"), 
the SndOrderlyDisconnect and RcvOrderlyDisconnect calls can fail because of a pending T_DISCONNECT event. 
This is XTI trying to tell you that the a connection on that endpoint broke. This can happen in this asynchronous 
wacky world of networks and your program will have to call a RcvDisconnect to acknowledge that your endpoint dropped.

You might want to check out the OTI spec, which, although it is not always written in the most lucid fashion, 
does contain valuable information for those involved in OpenTransport programming.

Further Information:
Title: X/OPEN TRANSPORT INTERFACE (XTI) VER 2 [ 1.0 ed]
Author: X/OPEN 
ISBN #: 0133534596

A Prior to Open Transport 1.3, there was no supported way of calling Open Transport from CFM-68K code. 
With the introduction of Open Transport 1.3, it is now possible to call the Open Transport client 
interface from CFM-68K code. The Open Transport 1.3 SDK includes stub libraries and a document, 
"Open Tpt CFM68K Dev. Note", which explains Open Transport's support for CFM-68K. which is supporte for 
syste 7.x but you can't install! No standalone installer exists. Coping the OT files kinda works
*/
