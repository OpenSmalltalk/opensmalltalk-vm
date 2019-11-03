/*
 	File:		MacTCP.h
 
 	Contains:	TCP Manager Interfaces.
 
 	Version:	Technology:	MacTCP 2.0.6
 				Package:	Universal Interfaces 2.1ß1 in ³MPW Prerelease² on ETO #17
 
 	Copyright:	© 1984-1995 by Apple Computer, Inc.
 				All rights reserved.
 
 	Bugs?:		If you find a problem with this file, use the Apple Bug Reporter
 				stack.  Include the file and version information (from above)
 				in the problem description and send to:
 					Internet:	apple.bugs@applelink.apple.com
 					AppleLink:	APPLE.BUGS
 
*/

#ifndef __MACTCP__
#define __MACTCP__


#ifndef __TYPES__
#include <Types.h>
#endif
/*	#include <ConditionalMacros.h>								*/

#ifndef __APPLETALK__
#include <AppleTalk.h>
#endif
/*	#include <OSUtils.h>										*/
/*		#include <MixedMode.h>									*/
/*		#include <Memory.h>										*/

#ifdef __cplusplus
extern "C" {
#endif

#if PRAGMA_ALIGN_SUPPORTED
#pragma options align=mac68k
#endif

#if PRAGMA_IMPORT_SUPPORTED
#pragma import on
#endif

/*
Developer Notes:
		0. This MacTCP header replaces what used to be defined in the following header files
			MacTCPCommonTypes.h
			GetMyIPAddr.h
			MiscIPPB.h
			TCPPB.h
			UDPPB.h 
			
			When the various control calls are made to the ip driver, you must set up a 
			NewRoutineDescriptor for every non-nil completion routine and/or notifyProc parameter.  
			Otherwise, the 68K driver code, will not correctly call your routine.
		1. For ipctlGetAddr Control calls, use NewGetIPIOCompletionProc
			to set up a GetIPIOCompletionUPP universal procptr to pass as
			the ioCompletion parameter.
		2. For the ipctlEchoICMP and ipctlLAPStats Control calls, use 
			NewIPIOCompletion to set up a IPIOCompletionUPP universal procptr
			to pass in the ioCompletion field of the parameter block.
		3. For TCPCreatePB Control calls, use NewTCPNotifyProc to set up a
			TCPNotifyUPP universal procptr to pass in the notifyProc field
			of the parameter block
		4. For all of the TCP Control calls using the TCPiopb parameter block,
			use NewTCPIOCompletionProc to set up a TCPIOCompletionUPP
			universal procptr to pass in the ioCompletion field of the paramter
			block.
		5. For UDBCreatePB Control calls, use NewUDPNotifyProc to set up a
			UDPNotifyUPP universal procptr to pass in the notifyProc field
			of the parameter block
		6. For all of the UDP Control calls using the UDPiopb parameter block,
			use NewUDPIOCompletionProc to set up a UDPIOCompletionUPP
			universal procptr to pass in the ioCompletion field of the paramter
			block.
		7. For all calls implementing a notifyProc or ioCompletion routine
			which was set up using a NewTCPRoutineProc call, do not call
			DisposeRoutineSDescriptor on the universal procptr until
			after the completion or notify proc has completed.
*/
/* MacTCP return Codes in the range -23000 through -23049 */

enum {
	inProgress					= 1,							/* I/O in progress */
	ipBadLapErr					= -23000,						/* bad network configuration */
	ipBadCnfgErr				= -23001,						/* bad IP configuration error */
	ipNoCnfgErr					= -23002,						/* missing IP or LAP configuration error */
	ipLoadErr					= -23003,						/* error in MacTCP load */
	ipBadAddr					= -23004,						/* error in getting address */
	connectionClosing			= -23005,						/* connection is closing */
	invalidLength				= -23006,
	connectionExists			= -23007,						/* request conflicts with existing connection */
	connectionDoesntExist		= -23008,						/* connection does not exist */
	insufficientResources		= -23009,						/* insufficient resources to perform request */
	invalidStreamPtr			= -23010,
	streamAlreadyOpen			= -23011,
	connectionTerminated		= -23012,
	invalidBufPtr				= -23013,
	invalidRDS					= -23014,
	invalidWDS					= -23014,
	openFailed					= -23015,
	commandTimeout				= -23016,
	duplicateSocket				= -23017
};

/* Error codes from internal IP functions */
enum {
	ipDontFragErr				= -23032,						/* Packet too large to send w/o fragmenting */
	ipDestDeadErr				= -23033,						/* destination not responding */
	icmpEchoTimeoutErr			= -23035,						/* ICMP echo timed-out */
	ipNoFragMemErr				= -23036,						/* no memory to send fragmented pkt */
	ipRouteErr					= -23037,						/* can't route packet off-net */
	nameSyntaxErr				= -23041,
	cacheFault					= -23042,
	noResultProc				= -23043,
	noNameServer				= -23044,
	authNameErr					= -23045,
	noAnsErr					= -23046,
	dnrErr						= -23047,
	outOfMemory					= -23048
};

enum {
	BYTES_16WORD				= 2,							/* bytes per = 16, bit ip word */
	BYTES_32WORD				= 4,							/* bytes per = 32, bit ip word */
	BYTES_64WORD				= 8								/* bytes per = 64, bit ip word */
};

/* 8-bit quantity */
typedef UInt8 b_8;

/* 16-bit quantity */
typedef UInt16 b_16;

/* 32-bit quantity */
typedef UInt32 b_32;

/* IP address is 32-bits */
typedef b_32 ip_addr;

struct ip_addrbytes {
	union {
		b_32							addr;
		UInt8							byte[4];
	}								a;
};
typedef struct ip_addrbytes ip_addrbytes;

struct wdsEntry {
	unsigned short					length;						/* length of buffer */
	Ptr								ptr;						/* pointer to buffer */
};
typedef struct wdsEntry wdsEntry;

struct rdsEntry {
	unsigned short					length;						/* length of buffer */
	Ptr								ptr;						/* pointer to buffer */
};
typedef struct rdsEntry rdsEntry;

typedef unsigned long BufferPtr;

typedef unsigned long StreamPtr;


enum {
	netUnreach					= 0,
	hostUnreach					= 1,
	protocolUnreach				= 2,
	portUnreach					= 3,
	fragReqd					= 4,
	sourceRouteFailed			= 5,
	timeExceeded				= 6,
	parmProblem					= 7,
	missingOption				= 8,
	lastICMPMsgType				= 32767
};

typedef unsigned short ICMPMsgType;

typedef b_16 ip_port;

struct ICMPReport {
	StreamPtr						streamPtr;
	ip_addr							localHost;
	ip_port							localPort;
	ip_addr							remoteHost;
	ip_port							remotePort;
	short							reportType;
	unsigned short					optionalAddlInfo;
	unsigned long					optionalAddlInfoPtr;
};
typedef struct ICMPReport ICMPReport;

/* csCode to get our IP address */

enum {
	ipctlGetAddr				= 15
};

typedef void (*GetIPIOCompletionProcPtr)(struct GetAddrParamBlock *iopb);

#if GENERATINGCFM
typedef UniversalProcPtr GetIPIOCompletionUPP;
#else
typedef GetIPIOCompletionProcPtr GetIPIOCompletionUPP;
#endif

#define GetIPParamBlockHeader 	\
	struct QElem*	qLink; 		\
	short	qType; 				\
	short	ioTrap; 				\
	Ptr	ioCmdAddr; 				\
	GetIPIOCompletionUPP	ioCompletion;  \
	OSErr	ioResult; 			\
	StringPtr	ioNamePtr; 		\
	short	ioVRefNum;				\
	short	ioCRefNum;				\
	short	csCode
struct GetAddrParamBlock {
	struct QElem					*qLink;
	short							qType;
	short							ioTrap;
	Ptr								ioCmdAddr;
	GetIPIOCompletionUPP			ioCompletion;
	OSErr							ioResult;
	StringPtr						ioNamePtr;
	short							ioVRefNum;
	short							ioCRefNum;
	short							csCode;						/* standard I/O header */
	ip_addr							ourAddress;					/* our IP address */
	long							ourNetMask;					/* our IP net mask */
};
typedef struct GetAddrParamBlock GetAddrParamBlock;

/* control codes */

enum {
	ipctlEchoICMP				= 17,							/* send icmp echo */
	ipctlLAPStats				= 19							/* get lap stats */
};

typedef void (*IPIOCompletionProcPtr)(struct ICMPParamBlock *iopb);

#if GENERATINGCFM
typedef UniversalProcPtr IPIOCompletionUPP;
#else
typedef IPIOCompletionProcPtr IPIOCompletionUPP;
#endif

#define IPParamBlockHeader 		\
	struct QElem*	qLink; 		\
	short	qType; 				\
	short	ioTrap; 				\
	Ptr	ioCmdAddr; 				\
	IPIOCompletionUPP	ioCompletion;  \
	OSErr	ioResult; 			\
	StringPtr	ioNamePtr; 		\
	short	ioVRefNum;				\
	short	ioCRefNum;				\
	short	csCode
struct ICMPParamBlock {
	struct QElem					*qLink;
	short							qType;
	short							ioTrap;
	Ptr								ioCmdAddr;
	IPIOCompletionUPP				ioCompletion;
	OSErr							ioResult;
	StringPtr						ioNamePtr;
	short							ioVRefNum;
	short							ioCRefNum;
	short							csCode;						/* standard I/O header */
	short							params[11];
	struct {
		unsigned long					echoRequestOut;			/* time in ticks of when the echo request went out */
		unsigned long					echoReplyIn;			/* time in ticks of when the reply was received */
		struct rdsEntry					echoedData;				/* data received in responce */
		Ptr								options;
		unsigned long					userDataPtr;
	}								icmpEchoInfo;
};
typedef pascal void (*ICMPEchoNotifyProcPtr)(struct ICMPParamBlock *iopb);

#if GENERATINGCFM
typedef UniversalProcPtr ICMPEchoNotifyUPP;
#else
typedef ICMPEchoNotifyProcPtr ICMPEchoNotifyUPP;
#endif

struct IPParamBlock {
	struct QElem					*qLink;
	short							qType;
	short							ioTrap;
	Ptr								ioCmdAddr;
	IPIOCompletionUPP				ioCompletion;
	OSErr							ioResult;
	StringPtr						ioNamePtr;
	short							ioVRefNum;
	short							ioCRefNum;
	short							csCode;						/* standard I/O header */
	union {
		struct {
			ip_addr							dest;				/* echo to IP address */
			wdsEntry						data;
			short							timeout;
			Ptr								options;
			unsigned short					optLength;
			ICMPEchoNotifyUPP				icmpCompletion;
			unsigned long					userDataPtr;
		}								IPEchoPB;
		struct {
			struct LAPStats					*lapStatsPtr;
		}								LAPStatsPB;
	}								csParam;
};
union LAPStatsAddrXlation {
	struct arp_entry				*arp_table;
	struct nbp_entry				*nbp_table;
};
struct LAPStats {
	short							ifType;
	char							*ifString;
	short							ifMaxMTU;
	long							ifSpeed;
	short							ifPhyAddrLength;
	char							*ifPhysicalAddress;
	union LAPStatsAddrXlation		AddrXlation;
	short							slotNumber;
};
typedef struct LAPStats LAPStats;

struct nbp_entry {
	ip_addr							ip_address;					/* IP address */
	AddrBlock						at_address;					/* matching AppleTalk address */
	Boolean							gateway;					/* TRUE if entry for a gateway */
	Boolean							valid;						/* TRUE if LAP address is valid */
	Boolean							probing;					/* TRUE if NBP lookup pending */
	SInt8							afiller;					/* Filler for proper byte alignment	 */
	long							age;						/* ticks since cache entry verified */
	long							access;						/* ticks since last access */
	SInt8							filler[116];				/* for internal use only !!! */
};
struct Enet_addr {
	b_16							en_hi;
	b_32							en_lo;
};
typedef struct Enet_addr Enet_addr;

struct arp_entry {
	short							age;						/* cache aging field */
	b_16							protocol;					/* Protocol type */
	ip_addr							ip_address;					/* IP address */
	Enet_addr						en_address;					/* matching Ethernet address */
};
typedef struct arp_entry arp_entry;

/* number of ARP table entries */

enum {
	ARP_TABLE_SIZE				= 20
};

enum {
	NBP_TABLE_SIZE				= 20,							/* number of NBP table entries */
	NBP_MAX_NAME_SIZE			= 16 + 10 + 2
};

/* Command codes */
enum {
	TCPCreate					= 30,
	TCPPassiveOpen				= 31,
	TCPActiveOpen				= 32,
	TCPSend						= 34,
	TCPNoCopyRcv				= 35,
	TCPRcvBfrReturn				= 36,
	TCPRcv						= 37,
	TCPClose					= 38,
	TCPAbort					= 39,
	TCPStatus					= 40,
	TCPExtendedStat				= 41,
	TCPRelease					= 42,
	TCPGlobalInfo				= 43,
	TCPCtlMax					= 49
};

enum {
	TCPClosing					= 1,
	TCPULPTimeout				= 2,
	TCPTerminate				= 3,
	TCPDataArrival				= 4,
	TCPUrgent					= 5,
	TCPICMPReceived				= 6,
	lastEvent					= 32767
};

typedef unsigned short TCPEventCode;


enum {
	TCPRemoteAbort				= 2,
	TCPNetworkFailure			= 3,
	TCPSecPrecMismatch			= 4,
	TCPULPTimeoutTerminate		= 5,
	TCPULPAbort					= 6,
	TCPULPClose					= 7,
	TCPServiceError				= 8,
	lastReason					= 32767
};

typedef unsigned short TCPTerminationReason;

typedef pascal void (*TCPNotifyProcPtr)(StreamPtr tcpStream, unsigned short eventCode, Ptr userDataPtr, unsigned short terminReason, struct ICMPReport *icmpMsg);

#if GENERATINGCFM
typedef UniversalProcPtr TCPNotifyUPP;
#else
typedef TCPNotifyProcPtr TCPNotifyUPP;
#endif

typedef unsigned short tcp_port;

/* ValidityFlags */

enum {
	timeoutValue				= 0x80,
	timeoutAction				= 0x40,
	typeOfService				= 0x20,
	precedence					= 0x10
};

/* TOSFlags */
enum {
	lowDelay					= 0x01,
	throughPut					= 0x02,
	reliability					= 0x04
};

struct TCPCreatePB {
	Ptr								rcvBuff;
	unsigned long					rcvBuffLen;
	TCPNotifyUPP					notifyProc;
	Ptr								userDataPtr;
};
typedef struct TCPCreatePB TCPCreatePB;

struct TCPOpenPB {
	SInt8							ulpTimeoutValue;
	SInt8							ulpTimeoutAction;
	SInt8							validityFlags;
	SInt8							commandTimeoutValue;
	ip_addr							remoteHost;
	tcp_port						remotePort;
	ip_addr							localHost;
	tcp_port						localPort;
	SInt8							tosFlags;
	SInt8							precedence;
	Boolean							dontFrag;
	SInt8							timeToLive;
	SInt8							security;
	SInt8							optionCnt;
	SInt8							options[40];
	Ptr								userDataPtr;
};
typedef struct TCPOpenPB TCPOpenPB;

struct TCPSendPB {
	SInt8							ulpTimeoutValue;
	SInt8							ulpTimeoutAction;
	SInt8							validityFlags;
	Boolean							pushFlag;
	Boolean							urgentFlag;
	SInt8							filler;						/* Filler for proper byte alignment	 */
	Ptr								wdsPtr;
	unsigned long					sendFree;
	unsigned short					sendLength;
	Ptr								userDataPtr;
};
typedef struct TCPSendPB TCPSendPB;

/* for receive and return rcv buff calls */
/*   Note: the filler in the following structure is in a different location than */
/*         that specified in the Programmer's Guide.  */
struct TCPReceivePB {
	SInt8							commandTimeoutValue;
	Boolean							markFlag;
	Boolean							urgentFlag;
	SInt8							filler;						/* Filler for proper byte alignment  */
	Ptr								rcvBuff;
	unsigned short					rcvBuffLen;
	Ptr								rdsPtr;
	unsigned short					rdsLength;
	unsigned short					secondTimeStamp;
	Ptr								userDataPtr;
};
typedef struct TCPReceivePB TCPReceivePB;

struct TCPClosePB {
	SInt8							ulpTimeoutValue;
	SInt8							ulpTimeoutAction;
	SInt8							validityFlags;
	SInt8							filler;						/* Filler for proper byte alignment	 */
	Ptr								userDataPtr;
};
typedef struct TCPClosePB TCPClosePB;

struct HistoBucket {
	unsigned short					value;
	unsigned long					counter;
};
typedef struct HistoBucket HistoBucket;


enum {
	NumOfHistoBuckets			= 7
};

struct TCPConnectionStats {
	unsigned long					dataPktsRcvd;
	unsigned long					dataPktsSent;
	unsigned long					dataPktsResent;
	unsigned long					bytesRcvd;
	unsigned long					bytesRcvdDup;
	unsigned long					bytesRcvdPastWindow;
	unsigned long					bytesSent;
	unsigned long					bytesResent;
	unsigned short					numHistoBuckets;
	struct HistoBucket				sentSizeHisto[NumOfHistoBuckets];
	unsigned short					lastRTT;
	unsigned short					tmrSRTT;
	unsigned short					rttVariance;
	unsigned short					tmrRTO;
	SInt8							sendTries;
	SInt8							sourchQuenchRcvd;
};
typedef struct TCPConnectionStats TCPConnectionStats;

struct TCPStatusPB {
	SInt8							ulpTimeoutValue;
	SInt8							ulpTimeoutAction;
	long							unused;
	ip_addr							remoteHost;
	tcp_port						remotePort;
	ip_addr							localHost;
	tcp_port						localPort;
	SInt8							tosFlags;
	SInt8							precedence;
	SInt8							connectionState;
	SInt8							filler;						/* Filler for proper byte alignment	 */
	unsigned short					sendWindow;
	unsigned short					rcvWindow;
	unsigned short					amtUnackedData;
	unsigned short					amtUnreadData;
	Ptr								securityLevelPtr;
	unsigned long					sendUnacked;
	unsigned long					sendNext;
	unsigned long					congestionWindow;
	unsigned long					rcvNext;
	unsigned long					srtt;
	unsigned long					lastRTT;
	unsigned long					sendMaxSegSize;
	struct TCPConnectionStats		*connStatPtr;
	Ptr								userDataPtr;
};
typedef struct TCPStatusPB TCPStatusPB;

struct TCPAbortPB {
	Ptr								userDataPtr;
};
typedef struct TCPAbortPB TCPAbortPB;

struct TCPParam {
	unsigned long					tcpRtoA;
	unsigned long					tcpRtoMin;
	unsigned long					tcpRtoMax;
	unsigned long					tcpMaxSegSize;
	unsigned long					tcpMaxConn;
	unsigned long					tcpMaxWindow;
};
typedef struct TCPParam TCPParam;

struct TCPStats {
	unsigned long					tcpConnAttempts;
	unsigned long					tcpConnOpened;
	unsigned long					tcpConnAccepted;
	unsigned long					tcpConnClosed;
	unsigned long					tcpConnAborted;
	unsigned long					tcpOctetsIn;
	unsigned long					tcpOctetsOut;
	unsigned long					tcpOctetsInDup;
	unsigned long					tcpOctetsRetrans;
	unsigned long					tcpInputPkts;
	unsigned long					tcpOutputPkts;
	unsigned long					tcpDupPkts;
	unsigned long					tcpRetransPkts;
};
typedef struct TCPStats TCPStats;

typedef StreamPtr *StreamPPtr;

struct TCPGlobalInfoPB {
	struct TCPParam					*tcpParamPtr;
	struct TCPStats					*tcpStatsPtr;
	StreamPPtr						tcpCDBTable[1];
	Ptr								userDataPtr;
	unsigned short					maxTCPConnections;
};
typedef struct TCPGlobalInfoPB TCPGlobalInfoPB;

typedef void (*TCPIOCompletionProcPtr)(struct TCPiopb *iopb);

#if GENERATINGCFM
typedef UniversalProcPtr TCPIOCompletionUPP;
#else
typedef TCPIOCompletionProcPtr TCPIOCompletionUPP;
#endif

struct TCPiopb {
	SInt8							fill12[12];
	TCPIOCompletionUPP				ioCompletion;
	short							ioResult;
	Ptr								ioNamePtr;
	short							ioVRefNum;
	short							ioCRefNum;
	short							csCode;
	StreamPtr						tcpStream;
	union {
		struct TCPCreatePB				create;
		struct TCPOpenPB				open;
		struct TCPSendPB				send;
		struct TCPReceivePB				receive;
		struct TCPClosePB				close;
		struct TCPAbortPB				abort;
		struct TCPStatusPB				status;
		struct TCPGlobalInfoPB			globalInfo;
	}								csParam;
};
typedef struct TCPiopb TCPiopb;


enum {
	UDPCreate					= 20,
	UDPRead						= 21,
	UDPBfrReturn				= 22,
	UDPWrite					= 23,
	UDPRelease					= 24,
	UDPMaxMTUSize				= 25,
	UDPStatus					= 26,
	UDPMultiCreate				= 27,
	UDPMultiSend				= 28,
	UDPMultiRead				= 29,
	UDPCtlMax					= 29
};

enum {
	UDPDataArrival				= 1,
	UDPICMPReceived				= 2,
	lastUDPEvent				= 32767
};

typedef unsigned short UDPEventCode;

typedef pascal void (*UDPNotifyProcPtr)(StreamPtr udpStream, unsigned short eventCode, Ptr userDataPtr, struct ICMPReport *icmpMsg);

#if GENERATINGCFM
typedef UniversalProcPtr UDPNotifyUPP;
#else
typedef UDPNotifyProcPtr UDPNotifyUPP;
#endif

typedef unsigned short udp_port;

/* for create and release calls */
struct UDPCreatePB {
	Ptr								rcvBuff;
	unsigned long					rcvBuffLen;
	UDPNotifyUPP					notifyProc;
	unsigned short					localPort;
	Ptr								userDataPtr;
	udp_port						endingPort;
};
typedef struct UDPCreatePB UDPCreatePB;

struct UDPSendPB {
	unsigned short					reserved;
	ip_addr							remoteHost;
	udp_port						remotePort;
	Ptr								wdsPtr;
	Boolean							checkSum;
	SInt8							filler;						/* Filler for proper byte alignment	 */
	unsigned short					sendLength;
	Ptr								userDataPtr;
	udp_port						localPort;
};
typedef struct UDPSendPB UDPSendPB;

/* for receive and buffer return calls */
struct UDPReceivePB {
	unsigned short					timeOut;
	ip_addr							remoteHost;
	udp_port						remotePort;
	Ptr								rcvBuff;
	unsigned short					rcvBuffLen;
	unsigned short					secondTimeStamp;
	Ptr								userDataPtr;
	ip_addr							destHost;					/* only for use with multi rcv */
	udp_port						destPort;					/* only for use with multi rcv */
};
typedef struct UDPReceivePB UDPReceivePB;

struct UDPMTUPB {
	unsigned short					mtuSize;
	ip_addr							remoteHost;
	Ptr								userDataPtr;
};
typedef struct UDPMTUPB UDPMTUPB;

typedef void (*UDPIOCompletionProcPtr)(struct UDPiopb *iopb);

#if GENERATINGCFM
typedef UniversalProcPtr UDPIOCompletionUPP;
#else
typedef UDPIOCompletionProcPtr UDPIOCompletionUPP;
#endif

struct UDPiopb {
	SInt8							fill12[12];
	UDPIOCompletionUPP				ioCompletion;
	short							ioResult;
	Ptr								ioNamePtr;
	short							ioVRefNum;
	short							ioCRefNum;
	short							csCode;
	StreamPtr						udpStream;
	union {
		struct UDPCreatePB				create;
		struct UDPSendPB				send;
		struct UDPReceivePB				receive;
		struct UDPMTUPB					mtu;
	}								csParam;
};
typedef struct UDPiopb UDPiopb;


#if GENERATINGCFM
#else
#endif

enum {
	uppGetIPIOCompletionProcInfo = kCStackBased
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(struct GetAddrParamBlock*))),
	uppIPIOCompletionProcInfo = kCStackBased
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(struct ICMPParamBlock*))),
	uppICMPEchoNotifyProcInfo = kPascalStackBased
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(struct ICMPParamBlock*))),
	uppTCPNotifyProcInfo = kPascalStackBased
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(StreamPtr)))
		 | STACK_ROUTINE_PARAMETER(2, SIZE_CODE(sizeof(unsigned short)))
		 | STACK_ROUTINE_PARAMETER(3, SIZE_CODE(sizeof(Ptr)))
		 | STACK_ROUTINE_PARAMETER(4, SIZE_CODE(sizeof(unsigned short)))
		 | STACK_ROUTINE_PARAMETER(5, SIZE_CODE(sizeof(struct ICMPReport*))),
	uppTCPIOCompletionProcInfo = kCStackBased
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(struct TCPiopb*))),
	uppUDPNotifyProcInfo = kPascalStackBased
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(StreamPtr)))
		 | STACK_ROUTINE_PARAMETER(2, SIZE_CODE(sizeof(unsigned short)))
		 | STACK_ROUTINE_PARAMETER(3, SIZE_CODE(sizeof(Ptr)))
		 | STACK_ROUTINE_PARAMETER(4, SIZE_CODE(sizeof(struct ICMPReport*))),
	uppUDPIOCompletionProcInfo = kCStackBased
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(struct UDPiopb*)))
};

#if GENERATINGCFM
#define NewGetIPIOCompletionProc(userRoutine)		\
		(GetIPIOCompletionUPP) NewRoutineDescriptor((ProcPtr)(userRoutine), uppGetIPIOCompletionProcInfo, GetCurrentArchitecture())
#define NewIPIOCompletionProc(userRoutine)		\
		(IPIOCompletionUPP) NewRoutineDescriptor((ProcPtr)(userRoutine), uppIPIOCompletionProcInfo, GetCurrentArchitecture())
#define NewICMPEchoNotifyProc(userRoutine)		\
		(ICMPEchoNotifyUPP) NewRoutineDescriptor((ProcPtr)(userRoutine), uppICMPEchoNotifyProcInfo, GetCurrentArchitecture())
#define NewTCPNotifyProc(userRoutine)		\
		(TCPNotifyUPP) NewRoutineDescriptor((ProcPtr)(userRoutine), uppTCPNotifyProcInfo, GetCurrentArchitecture())
#define NewTCPIOCompletionProc(userRoutine)		\
		(TCPIOCompletionUPP) NewRoutineDescriptor((ProcPtr)(userRoutine), uppTCPIOCompletionProcInfo, GetCurrentArchitecture())
#define NewUDPNotifyProc(userRoutine)		\
		(UDPNotifyUPP) NewRoutineDescriptor((ProcPtr)(userRoutine), uppUDPNotifyProcInfo, GetCurrentArchitecture())
#define NewUDPIOCompletionProc(userRoutine)		\
		(UDPIOCompletionUPP) NewRoutineDescriptor((ProcPtr)(userRoutine), uppUDPIOCompletionProcInfo, GetCurrentArchitecture())
#else
#define NewGetIPIOCompletionProc(userRoutine)		\
		((GetIPIOCompletionUPP) (userRoutine))
#define NewIPIOCompletionProc(userRoutine)		\
		((IPIOCompletionUPP) (userRoutine))
#define NewICMPEchoNotifyProc(userRoutine)		\
		((ICMPEchoNotifyUPP) (userRoutine))
#define NewTCPNotifyProc(userRoutine)		\
		((TCPNotifyUPP) (userRoutine))
#define NewTCPIOCompletionProc(userRoutine)		\
		((TCPIOCompletionUPP) (userRoutine))
#define NewUDPNotifyProc(userRoutine)		\
		((UDPNotifyUPP) (userRoutine))
#define NewUDPIOCompletionProc(userRoutine)		\
		((UDPIOCompletionUPP) (userRoutine))
#endif

#if GENERATINGCFM
#define CallGetIPIOCompletionProc(userRoutine, iopb)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppGetIPIOCompletionProcInfo, (iopb))
#define CallIPIOCompletionProc(userRoutine, iopb)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppIPIOCompletionProcInfo, (iopb))
#define CallICMPEchoNotifyProc(userRoutine, iopb)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppICMPEchoNotifyProcInfo, (iopb))
#define CallTCPNotifyProc(userRoutine, tcpStream, eventCode, userDataPtr, terminReason, icmpMsg)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppTCPNotifyProcInfo, (tcpStream), (eventCode), (userDataPtr), (terminReason), (icmpMsg))
#define CallTCPIOCompletionProc(userRoutine, iopb)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppTCPIOCompletionProcInfo, (iopb))
#define CallUDPNotifyProc(userRoutine, udpStream, eventCode, userDataPtr, icmpMsg)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppUDPNotifyProcInfo, (udpStream), (eventCode), (userDataPtr), (icmpMsg))
#define CallUDPIOCompletionProc(userRoutine, iopb)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppUDPIOCompletionProcInfo, (iopb))
#else
#define CallGetIPIOCompletionProc(userRoutine, iopb)		\
		(*(userRoutine))((iopb))
#define CallIPIOCompletionProc(userRoutine, iopb)		\
		(*(userRoutine))((iopb))
#define CallICMPEchoNotifyProc(userRoutine, iopb)		\
		(*(userRoutine))((iopb))
#define CallTCPNotifyProc(userRoutine, tcpStream, eventCode, userDataPtr, terminReason, icmpMsg)		\
		(*(userRoutine))((tcpStream), (eventCode), (userDataPtr), (terminReason), (icmpMsg))
#define CallTCPIOCompletionProc(userRoutine, iopb)		\
		(*(userRoutine))((iopb))
#define CallUDPNotifyProc(userRoutine, udpStream, eventCode, userDataPtr, icmpMsg)		\
		(*(userRoutine))((udpStream), (eventCode), (userDataPtr), (icmpMsg))
#define CallUDPIOCompletionProc(userRoutine, iopb)		\
		(*(userRoutine))((iopb))
#endif


#if PRAGMA_IMPORT_SUPPORTED
#pragma import off
#endif

#if PRAGMA_ALIGN_SUPPORTED
#pragma options align=reset
#endif

#ifdef __cplusplus
}
#endif

#endif /* __MACTCP__ */
