/*
 	File:		AddressXlation.h
 
 	Contains:	TCP Manager interfaces for dnr.c
 
 	Version:	Use with MacTCP 2.0.6 and Universal Interfaces 2.1b1
					in ³MPW Prerelease² on ETO #17

  	Copyright:	© 1984-1995 by Apple Computer, Inc.
 				All rights reserved.
 
 	Bugs?:		If you find a problem with this file, send the file and version
 				information (from above) and the problem description to:
 
 					Internet:	apple.bugs@applelink.apple.com
 					AppleLink:	APPLE.BUGS
 
*/

#ifndef __ADDRESSXLATION__
#define __ADDRESSXLATION__


#ifndef __TYPES__
#include <Types.h>
#endif
/*	#include <ConditionalMacros.h>								*/

#ifndef __MACTCP__
#include <MacTCP.h>
#endif
/*	#include <AppleTalk.h>										*/
/*		#include <OSUtils.h>									*/
/*			#include <MixedMode.h>								*/
/*			#include <Memory.h>									*/

#ifdef __cplusplus
extern "C" {
#endif

#if STRUCTALIGNMENTSUPPORTED
#pragma options align=mac68k
#endif

#if PRAGMA_IMPORT_SUPPORTED
#pragma import on
#endif

/*
	Developer Notes:

			When the various calls are made to the dnr code, you must set up 
			a NewRoutineDescriptor for every non-nil completion routine and/or 
			notifyProc parameter.  Otherwise, the 68K dnr code, will not 
			correctly call your routine.
		1. For the call to EnumCache, use NewEnumResultProc to set up a 
			universal procptr to pass as the enumResultProc parameter.
		2. For the calls to StrToAddr and AddrToName, use NewResultProc to 
			set up a ResultUPP universal procptr to pass as the ResultProc 
			parameter.
		3. For the calls to HInfo and MXInfo, use NewResultProc2Proc to
			set up a ResultProc2UPP universal procptr to pass as the ResultProc
			parameter.
		4. The DNR selector symbol HINFO has been changed to HXINFO due to
			conflict with the same symbol in the AddressXLation.h header
*/

enum {
	NUM_ALT_ADDRS				= 4
};

struct hostInfo {
	long							rtnCode;
	char							cname[255];
	SInt8							filler;						/* Filler for proper byte alignment	 */
	unsigned long					addr[NUM_ALT_ADDRS];
};
typedef struct hostInfo hostInfo;


enum {
	A							= 1,
	NS							= 2,
	CNAME						= 5,
	HINFO						= 13,
	MX							= 15,
	lastClass					= 32767
};

typedef unsigned short AddrClasses;

/* Domain Name Resolver code selectors */

enum {
	OPENRESOLVER				= 1,
	CLOSERESOLVER				= 2,
	STRTOADDR					= 3,
	ADDRTOSTR					= 4,
	ENUMCACHE					= 5,
	ADDRTONAME					= 6,
	HXINFO						= 7,							/* changed from HINFO due to symbol conflict*/
	MXINFO						= 8
};

struct HInfoRec {
	char							cpuType[30];
	char							osType[30];
};
typedef struct HInfoRec HInfoRec;

struct MXRec {
	unsigned short					preference;
	char							exchange[255];
};
typedef struct MXRec MXRec;

struct returnRec {
	long							rtnCode;
	char							cname[255];
	SInt8							filler;						/* Filler for proper byte alignment	 */
	union {
		unsigned long					addr[NUM_ALT_ADDRS];
		struct HInfoRec					hinfo;
		struct MXRec					mx;
	}								rdata;
};
typedef struct returnRec returnRec;

struct cacheEntryRecord {
	char							*cname;
	unsigned short					ctype;
	unsigned short					cacheClass;
	unsigned long					ttl;
	union {
		char							*name;
		ip_addr							addr;
	}								rdata;
};
typedef struct cacheEntryRecord cacheEntryRecord;

typedef pascal void (*EnumResultProcPtr)(struct cacheEntryRecord *cacheEntryRecordPtr, Ptr userDataPtr);
typedef pascal void (*ResultProcPtr)(struct hostInfo *hostInfoPtr, Ptr userDataPtr);
typedef pascal void (*ResultProc2ProcPtr)(struct returnRec *returnRecPtr, Ptr userDataPtr);

#if GENERATINGCFM
typedef UniversalProcPtr EnumResultUPP;
typedef UniversalProcPtr ResultUPP;
typedef UniversalProcPtr ResultProc2UPP;
#else
typedef EnumResultProcPtr EnumResultUPP;
typedef ResultProcPtr ResultUPP;
typedef ResultProc2ProcPtr ResultProc2UPP;
#endif

enum {
	uppEnumResultProcInfo = kPascalStackBased
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(struct cacheEntryRecord*)))
		 | STACK_ROUTINE_PARAMETER(2, SIZE_CODE(sizeof(Ptr))),
	uppResultProcInfo = kPascalStackBased
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(struct hostInfo*)))
		 | STACK_ROUTINE_PARAMETER(2, SIZE_CODE(sizeof(Ptr))),
	uppResultProc2ProcInfo = kPascalStackBased
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(struct returnRec*)))
		 | STACK_ROUTINE_PARAMETER(2, SIZE_CODE(sizeof(Ptr)))
};

#if GENERATINGCFM
#define NewEnumResultProc(userRoutine)		\
		(EnumResultUPP) NewRoutineDescriptor((ProcPtr)(userRoutine), uppEnumResultProcInfo, GetCurrentArchitecture())
#define NewResultProc(userRoutine)		\
		(ResultUPP) NewRoutineDescriptor((ProcPtr)(userRoutine), uppResultProcInfo, GetCurrentArchitecture())
#define NewResultProc2Proc(userRoutine)		\
		(ResultProc2UPP) NewRoutineDescriptor((ProcPtr)(userRoutine), uppResultProc2ProcInfo, GetCurrentArchitecture())
#else
#define NewEnumResultProc(userRoutine)		\
		((EnumResultUPP) (userRoutine))
#define NewResultProc(userRoutine)		\
		((ResultUPP) (userRoutine))
#define NewResultProc2Proc(userRoutine)		\
		((ResultProc2UPP) (userRoutine))
#endif

#if GENERATINGCFM
#define CallEnumResultProc(userRoutine, cacheEntryRecordPtr, userDataPtr)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppEnumResultProcInfo, (cacheEntryRecordPtr), (userDataPtr))
#define CallResultProc(userRoutine, hostInfoPtr, userDataPtr)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppResultProcInfo, (hostInfoPtr), (userDataPtr))
#define CallResultProc2Proc(userRoutine, returnRecPtr, userDataPtr)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppResultProc2ProcInfo, (returnRecPtr), (userDataPtr))
#else
#define CallEnumResultProc(userRoutine, cacheEntryRecordPtr, userDataPtr)		\
		(*(userRoutine))((cacheEntryRecordPtr), (userDataPtr))
#define CallResultProc(userRoutine, hostInfoPtr, userDataPtr)		\
		(*(userRoutine))((hostInfoPtr), (userDataPtr))
#define CallResultProc2Proc(userRoutine, returnRecPtr, userDataPtr)		\
		(*(userRoutine))((returnRecPtr), (userDataPtr))
#endif

extern OSErr OpenResolver(char *fileName);
extern OSErr StrToAddr(char *hostName, struct hostInfo *hostInfoPtr, ResultUPP ResultProc, char *userDataPtr);
extern OSErr AddrToStr(unsigned long addr, char *addrStr);
extern OSErr EnumCache(EnumResultUPP enumResultProc, Ptr userDataPtr);
extern OSErr AddrToName(ip_addr addr, struct hostInfo *hostInfoPtr, ResultUPP ResultProc, Ptr userDataPtr);
extern OSErr HInfo(char *hostName, struct returnRec *returnRecPtr, ResultProc2UPP resultProc, Ptr userDataPtr);
extern OSErr MXInfo(char *hostName, struct returnRec *returnRecPtr, ResultProc2UPP resultProc, Ptr userDataPtr);
extern OSErr CloseResolver(void);
/*
	Universal ProcPtrs declaration for each of the dnr selector code calls.
*/
typedef OSErr (*OpenResolverProcPtr)(UInt32 selector, char *filename);
typedef OSErr (*CloseResolverProcPtr)(UInt32 selector);
typedef OSErr (*StrToAddrProcPtr)(UInt32 selector, char *hostName, struct hostInfo *rtnStruct, ResultUPP resultproc, Ptr userDataPtr);
typedef OSErr (*AddrToStrProcPtr)(UInt32 selector, unsigned long addr, char *addrStr);
typedef OSErr (*EnumCacheProcPtr)(UInt32 selector, EnumResultUPP resultproc, Ptr userDataPtr);
typedef OSErr (*AddrToNameProcPtr)(UInt32 selector, UInt32 addr, struct hostInfo *rtnStruct, ResultUPP resultproc, Ptr userDataPtr);
typedef OSErr (*HInfoProcPtr)(UInt32 selector, char *hostName, struct returnRec *returnRecPtr, ResultProc2UPP resultProc, Ptr userDataPtr);
typedef OSErr (*MXInfoProcPtr)(UInt32 selector, char *hostName, struct returnRec *returnRecPtr, ResultProc2UPP resultProc, Ptr userDataPtr);

#if GENERATINGCFM
typedef UniversalProcPtr OpenResolverUPP;
typedef UniversalProcPtr CloseResolverUPP;
typedef UniversalProcPtr StrToAddrUPP;
typedef UniversalProcPtr AddrToStrUPP;
typedef UniversalProcPtr EnumCacheUPP;
typedef UniversalProcPtr AddrToNameUPP;
typedef UniversalProcPtr HInfoUPP;
typedef UniversalProcPtr MXInfoUPP;
#else
typedef OpenResolverProcPtr OpenResolverUPP;
typedef CloseResolverProcPtr CloseResolverUPP;
typedef StrToAddrProcPtr StrToAddrUPP;
typedef AddrToStrProcPtr AddrToStrUPP;
typedef EnumCacheProcPtr EnumCacheUPP;
typedef AddrToNameProcPtr AddrToNameUPP;
typedef HInfoProcPtr HInfoUPP;
typedef MXInfoProcPtr MXInfoUPP;
#endif

enum {
	uppOpenResolverProcInfo = kCStackBased
		 | RESULT_SIZE(SIZE_CODE(sizeof(OSErr)))
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(UInt32)))
		 | STACK_ROUTINE_PARAMETER(2, SIZE_CODE(sizeof(char*))),
	uppCloseResolverProcInfo = kCStackBased
		 | RESULT_SIZE(SIZE_CODE(sizeof(OSErr)))
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(UInt32))),
	uppStrToAddrProcInfo = kCStackBased
		 | RESULT_SIZE(SIZE_CODE(sizeof(OSErr)))
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(UInt32)))
		 | STACK_ROUTINE_PARAMETER(2, SIZE_CODE(sizeof(char*)))
		 | STACK_ROUTINE_PARAMETER(3, SIZE_CODE(sizeof(struct hostInfo*)))
		 | STACK_ROUTINE_PARAMETER(4, SIZE_CODE(sizeof(ResultUPP)))
		 | STACK_ROUTINE_PARAMETER(5, SIZE_CODE(sizeof(Ptr))),
	uppAddrToStrProcInfo = kCStackBased
		 | RESULT_SIZE(SIZE_CODE(sizeof(OSErr)))
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(UInt32)))
		 | STACK_ROUTINE_PARAMETER(2, SIZE_CODE(sizeof(unsigned long)))
		 | STACK_ROUTINE_PARAMETER(3, SIZE_CODE(sizeof(char*))),
	uppEnumCacheProcInfo = kCStackBased
		 | RESULT_SIZE(SIZE_CODE(sizeof(OSErr)))
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(UInt32)))
		 | STACK_ROUTINE_PARAMETER(2, SIZE_CODE(sizeof(EnumResultUPP)))
		 | STACK_ROUTINE_PARAMETER(3, SIZE_CODE(sizeof(Ptr))),
	uppAddrToNameProcInfo = kCStackBased
		 | RESULT_SIZE(SIZE_CODE(sizeof(OSErr)))
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(UInt32)))
		 | STACK_ROUTINE_PARAMETER(2, SIZE_CODE(sizeof(UInt32)))
		 | STACK_ROUTINE_PARAMETER(3, SIZE_CODE(sizeof(struct hostInfo*)))
		 | STACK_ROUTINE_PARAMETER(4, SIZE_CODE(sizeof(ResultUPP)))
		 | STACK_ROUTINE_PARAMETER(5, SIZE_CODE(sizeof(Ptr))),
	uppHInfoProcInfo = kCStackBased
		 | RESULT_SIZE(SIZE_CODE(sizeof(OSErr)))
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(UInt32)))
		 | STACK_ROUTINE_PARAMETER(2, SIZE_CODE(sizeof(char*)))
		 | STACK_ROUTINE_PARAMETER(3, SIZE_CODE(sizeof(struct returnRec*)))
		 | STACK_ROUTINE_PARAMETER(4, SIZE_CODE(sizeof(ResultProc2UPP)))
		 | STACK_ROUTINE_PARAMETER(5, SIZE_CODE(sizeof(Ptr))),
	uppMXInfoProcInfo = kCStackBased
		 | RESULT_SIZE(SIZE_CODE(sizeof(OSErr)))
		 | STACK_ROUTINE_PARAMETER(1, SIZE_CODE(sizeof(UInt32)))
		 | STACK_ROUTINE_PARAMETER(2, SIZE_CODE(sizeof(char*)))
		 | STACK_ROUTINE_PARAMETER(3, SIZE_CODE(sizeof(struct returnRec*)))
		 | STACK_ROUTINE_PARAMETER(4, SIZE_CODE(sizeof(ResultProc2UPP)))
		 | STACK_ROUTINE_PARAMETER(5, SIZE_CODE(sizeof(Ptr)))
};

#if GENERATINGCFM
#define CallOpenResolverProc(userRoutine, selector, filename)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppOpenResolverProcInfo, (selector), (filename))
#define CallCloseResolverProc(userRoutine, selector)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppCloseResolverProcInfo, (selector))
#define CallStrToAddrProc(userRoutine, selector, hostName, rtnStruct, resultproc, userDataPtr)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppStrToAddrProcInfo, (selector), (hostName), (rtnStruct), (resultproc), (userDataPtr))
#define CallAddrToStrProc(userRoutine, selector, addr, addrStr)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppAddrToStrProcInfo, (selector), (addr), (addrStr))
#define CallEnumCacheProc(userRoutine, selector, resultproc, userDataPtr)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppEnumCacheProcInfo, (selector), (resultproc), (userDataPtr))
#define CallAddrToNameProc(userRoutine, selector, addr, rtnStruct, resultproc, userDataPtr)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppAddrToNameProcInfo, (selector), (addr), (rtnStruct), (resultproc), (userDataPtr))
#define CallHInfoProc(userRoutine, selector, hostName, returnRecPtr, resultProc, userDataPtr)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppHInfoProcInfo, (selector), (hostName), (returnRecPtr), (resultProc), (userDataPtr))
#define CallMXInfoProc(userRoutine, selector, hostName, returnRecPtr, resultProc, userDataPtr)		\
		CallUniversalProc((UniversalProcPtr)(userRoutine), uppMXInfoProcInfo, (selector), (hostName), (returnRecPtr), (resultProc), (userDataPtr))
#else
#define CallOpenResolverProc(userRoutine, selector, filename)		\
		(*(userRoutine))((selector), (filename))
#define CallCloseResolverProc(userRoutine, selector)		\
		(*(userRoutine))((selector))
#define CallStrToAddrProc(userRoutine, selector, hostName, rtnStruct, resultproc, userDataPtr)		\
		(*(userRoutine))((selector), (hostName), (rtnStruct), (resultproc), (userDataPtr))
#define CallAddrToStrProc(userRoutine, selector, addr, addrStr)		\
		(*(userRoutine))((selector), (addr), (addrStr))
#define CallEnumCacheProc(userRoutine, selector, resultproc, userDataPtr)		\
		(*(userRoutine))((selector), (resultproc), (userDataPtr))
#define CallAddrToNameProc(userRoutine, selector, addr, rtnStruct, resultproc, userDataPtr)		\
		(*(userRoutine))((selector), (addr), (rtnStruct), (resultproc), (userDataPtr))
#define CallHInfoProc(userRoutine, selector, hostName, returnRecPtr, resultProc, userDataPtr)		\
		(*(userRoutine))((selector), (hostName), (returnRecPtr), (resultProc), (userDataPtr))
#define CallMXInfoProc(userRoutine, selector, hostName, returnRecPtr, resultProc, userDataPtr)		\
		(*(userRoutine))((selector), (hostName), (returnRecPtr), (resultProc), (userDataPtr))
#endif


#if PRAGMA_IMPORT_SUPPORTED
#pragma import off
#endif

#if STRUCTALIGNMENTSUPPORTED
#pragma options align=reset
#endif

#ifdef __cplusplus
}
#endif

#endif /* __ADDRESSXLATION__ */
