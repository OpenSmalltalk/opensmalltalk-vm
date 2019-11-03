/* 	

	File:		DNR.c 
	
	Contains:	DNR library for MPW

  	Copyright:	© 1989-1995 by Apple Computer, Inc., all rights reserved

	Version:	Technology:			Networking
				Package:			Use with MacTCP 2.0.6 and the Universal
									Interfaces 2.1b1	
		
	Change History (most recent first):
		<3>	 1/23/95	rrk  	implemented use of universal procptrs
		 						Changed selector name HINFO to HXINFO
		 						due to conflict of name in MacTCP header
		 						Removed use of TrapAvailable and exchanged
		 						for the TrapExists call.
								Changed symbol codeHandle to gDNRCodeHndl
								Changed symbol dnr to gDNRCodePtr
	Further modifications by Steve Falkenburg, Apple MacDTS 8/91
	Modifications by Jim Matthews, Dartmouth College, 5/91

	
*/
#include "sq.h"

#ifndef __OSUTILS__
#include <OSUtils.h>
#endif

#ifndef __ERRORS__
#include <Errors.h>
#endif

#ifndef __FILES__
#include <Files.h>
#endif

#ifndef __RESOURCES__
#include <Resources.h>
#endif

#ifndef __MEMORY__
#include <Memory.h>
#endif

#ifndef __TRAPS__
#include <Traps.h>
#endif

#ifndef __GESTALT__
#include <Gestalt.h>
#endif

#ifndef __FOLDERS__
#include <Folders.h>
#endif

#ifndef __TOOLUTILS__
#include <ToolUtils.h>
#endif


#ifndef __MACTCP__
#include "MacTCP.h"
#endif

#ifndef __ADDRESSXLATION__
#include "AddressXlation.h"
#endif

// think C compatibility stuff

#ifndef	_GestaltDispatch
#define	_GestaltDispatch	_Gestalt
#endif


/* RRK Modification 1/95 - commenting out the following defines as they are
	defined in the DNRCalls.h header file
*/

void GetSystemFolder(short *vRefNumP, long *dirIDP);
void GetCPanelFolder(short *vRefNumP, long *dirIDP);
short SearchFolderForDNRP(long targetType, long targetCreator, short vRefNum, long dirID);
short OpenOurRF(void);
short	NumToolboxTraps(void);
TrapType	GetTrapType(short theTrap);
Boolean TrapExists(short theTrap);

static Handle 			gDNRCodeHndl = nil;
static ProcPtr			gDNRCodePtr = nil;

/*	Check the bits of a trap number to determine its type. */

/* InitGraf is always implemented (trap $A86E).  If the trap table is big
** enough, trap $AA6E will always point to either Unimplemented or some other
** trap, but will never be the same as InitGraf.  Thus, you can check the size
** of the trap table by asking if the address of trap $A86E is the same as
** $AA6E. */

#pragma segment UtilMain
short	NumToolboxTraps(void)
{
	if (NGetTrapAddress(_InitGraf, ToolTrap) == NGetTrapAddress(0xAA6E, ToolTrap))
		return(0x200);
	else
		return(0x400);
}

#pragma segment UtilMain
TrapType	GetTrapType(short theTrap)
{
	/* OS traps start with A0, Tool with A8 or AA. */
	if ((theTrap & 0x0800) == 0)					/* per D.A. */
		return(OSTrap);
	else
		return(ToolTrap);
}

Boolean TrapExists(short theTrap)
{
	TrapType	theTrapType;

	theTrapType = GetTrapType(theTrap);
	if ((theTrapType == ToolTrap) && ((theTrap &= 0x07FF) >= NumToolboxTraps()))
		theTrap = _Unimplemented;

	return(NGetTrapAddress(_Unimplemented, ToolTrap) != NGetTrapAddress(theTrap, theTrapType));
}

void GetSystemFolder(short *vRefNumP, long *dirIDP)
{
	SysEnvRec info;
	long wdProcID;
	
	SysEnvirons(1, &info);
	if (GetWDInfo(info.sysVRefNum, vRefNumP, dirIDP, &wdProcID) != noErr) 
	{
		*vRefNumP = 0;
		*dirIDP = 0;
	}
}

void GetCPanelFolder(short *vRefNumP, long *dirIDP)
{
	Boolean hasFolderMgr = false;
	long feature;
	
	if (TrapExists(_GestaltDispatch)) if (Gestalt(gestaltFindFolderAttr, &feature) == noErr) hasFolderMgr = true;
	if (!hasFolderMgr) 
	{
		GetSystemFolder(vRefNumP, dirIDP);
		return;
	}
	else 
	{
		if (FindFolder(kOnSystemDisk, kControlPanelFolderType, kDontCreateFolder, vRefNumP, dirIDP) != noErr) 
		{
			*vRefNumP = 0;
			*dirIDP = 0;
		}
	}
}
	
/* SearchFolderForDNRP is called to search a folder for files that might 
	contain the 'dnrp' resource */
short SearchFolderForDNRP(long targetType, long targetCreator, short vRefNum, long dirID)
{
	HParamBlockRec fi;
	Str255 filename;
	short refnum;
	
	fi.fileParam.ioCompletion = nil;
	fi.fileParam.ioNamePtr = filename;
	fi.fileParam.ioVRefNum = vRefNum;
	fi.fileParam.ioDirID = dirID;
	fi.fileParam.ioFDirIndex = 1;
	
	while (PBHGetFInfo(&fi, false) == noErr) 
	{
		/* scan system folder for driver resource files of specific type & creator */
		if (fi.fileParam.ioFlFndrInfo.fdType == targetType &&
			fi.fileParam.ioFlFndrInfo.fdCreator == targetCreator) 
		{
			/* found the MacTCP driver file? */
			refnum = HOpenResFile(vRefNum, dirID, filename, fsRdPerm);
			if (GetIndResource('dnrp', 1) == NULL)
				CloseResFile(refnum);
			else
				return refnum;
		}
		/* check next file in system folder */
		fi.fileParam.ioFDirIndex++;
		fi.fileParam.ioDirID = dirID;	/* PBHGetFInfo() clobbers ioDirID */
	}
	return(-1);
}	

/* OpenOurRF is called to open the MacTCP driver resources */

short OpenOurRF(void)
{
	short refnum;
	short vRefNum;
	long dirID;
	
	/* first search Control Panels for MacTCP 1.1 */
	GetCPanelFolder(&vRefNum, &dirID);
	refnum = SearchFolderForDNRP('cdev', 'ztcp', vRefNum, dirID);
	if (refnum != -1) return(refnum);
		
	/* next search System Folder for MacTCP 1.0.x */
	GetSystemFolder(&vRefNum, &dirID);
	refnum = SearchFolderForDNRP('cdev', 'mtcp', vRefNum, dirID);
	if (refnum != -1) return(refnum);
		
	/* finally, search Control Panels for MacTCP 1.0.x */
	GetCPanelFolder(&vRefNum, &dirID);
	refnum = SearchFolderForDNRP('cdev', 'mtcp', vRefNum, dirID);
	if (refnum != -1) return(refnum);
		
	return -1;
}	


OSErr OpenResolver(char *fileName)
{
	short 			refnum;
	OSErr 			rc;
	
	if (gDNRCodePtr != nil)
		/* resolver already loaded in */
		return(noErr);
		
	/* open the MacTCP driver to get DNR resources. Search for it based on
	   creator & type rather than simply file name */	
	refnum = OpenOurRF();

	/* ignore failures since the resource may have been installed in the 
	   System file if running on a Mac 512Ke */
	   
	/* load in the DNR resource package */
	gDNRCodeHndl = GetIndResource('dnrp', 1);
	if (gDNRCodeHndl == nil)
	{
		/* can't open DNR */
		return(ResError());
	}
	
	DetachResource(gDNRCodeHndl);
	if (refnum != -1) 
	{
		CloseResFile(refnum);
	}
		
	/* lock the DNR resource since it cannot be reloated while opened */
	MoveHHi(gDNRCodeHndl);
	HLock(gDNRCodeHndl);
	
	gDNRCodePtr = (ProcPtr)*gDNRCodeHndl;
	
	/* call open resolver */
	// RRK modification 1/95 use CallOpenResolverProc define to call UPP
	
	rc = CallOpenResolverProc(gDNRCodePtr, OPENRESOLVER, fileName);
	if (rc != noErr) 
	{
		/* problem with open resolver, flush it */
		HUnlock(gDNRCodeHndl);
		DisposeHandle(gDNRCodeHndl);
		gDNRCodePtr = nil;
	}
	return(rc);
}


OSErr CloseResolver(void)
{
	
	if (gDNRCodePtr == nil)
		/* resolver not loaded error */
		return(notOpenErr);
		
	/* call close resolver */
	// RRK modification 1/95 use CallCloseResolverProc define to call UPP
	// (void) (*dnr)(CLOSERESOLVER);

	CallCloseResolverProc(gDNRCodePtr, CLOSERESOLVER);
	
	/* release the DNR resource package */
	HUnlock(gDNRCodeHndl);
	DisposeHandle(gDNRCodeHndl);
	gDNRCodePtr = nil;
	return(noErr);
}

	// RRK modification 1/95 declare parameter resultProc to be of type 
	// ResultProcUPP instead of a long
	
OSErr StrToAddr(char *hostName, struct hostInfo *rtnStruct, 
			ResultUPP resultproc, Ptr userDataPtr)
{
	if (gDNRCodePtr == nil)
		/* resolver not loaded error */
		return(notOpenErr);
		
	// RRK modification 1/95 use CallStrToAddrProc define to call UPP
	// return((*dnr)(STRTOADDR, hostName, rtnStruct, resultproc, userDataPtr));
			
	return (CallStrToAddrProc(gDNRCodePtr, STRTOADDR, hostName, rtnStruct, resultproc, userDataPtr));
}
	
OSErr AddrToStr(unsigned long addr, char *addrStr)
{
	OSErr	err;
	if (gDNRCodePtr == nil)
		/* resolver not loaded error */
		return(notOpenErr);
		
	// RRK modification 1/95 use CallAddrToStrProc define to call UPP
	// (*dnr)(ADDRTOSTR, addr, addrStr);
	
	err = CallAddrToStrProc(gDNRCodePtr, ADDRTOSTR, addr, addrStr);
	return(noErr);
}
	
OSErr EnumCache(EnumResultUPP resultproc, Ptr userDataPtr)
{

	if (gDNRCodePtr == nil)
		/* resolver not loaded error */
		return(notOpenErr);
		
	// RRK modification 1/95 use CallEnumCacheProc define to call UPP
	// return((*dnr)(ENUMCACHE, resultproc, userDataPtr));

	return (CallEnumCacheProc(gDNRCodePtr, ENUMCACHE, resultproc, userDataPtr));
}
	
	
OSErr AddrToName(unsigned long addr, struct hostInfo *rtnStruct, 
			ResultUPP resultproc, Ptr userDataPtr)
{
	if (gDNRCodePtr == nil)
		/* resolver not loaded error */
		return(notOpenErr);
		
	// RRK modification 1/95 use CallAddrToNameProc define to call UPP
	// return((*dnr)(ADDRTONAME, addr, rtnStruct, resultproc, userDataPtr));

	return(CallAddrToNameProc(gDNRCodePtr, ADDRTONAME, addr, rtnStruct, resultproc, userDataPtr));
}


extern OSErr HInfo(char *hostName, struct returnRec *returnRecPtr, 
			ResultProc2UPP resultProc, Ptr userDataPtr)
{
	if (gDNRCodePtr == nil)
		/* resolver not loaded error */
		return(notOpenErr);
		
	// RRK modification 1/95 use CallHInfoProc define to call UPP
	// return((*dnr)(HINFO, hostName, returnRecPtr, resultProc, userDataPtr));

	return(CallHInfoProc(gDNRCodePtr, HXINFO, hostName, returnRecPtr, resultProc, userDataPtr));

}
	
extern OSErr MXInfo(char *hostName, struct returnRec *returnRecPtr, 
			ResultProc2UPP resultProc, Ptr userDataPtr)
{
	if (gDNRCodePtr == nil)
		/* resolver not loaded error */
		return(notOpenErr);
		
	// RRK modification 1/95 use CallHInfoProc define to call UPP
	// return((*dnr)(MXINFO, hostName, returnRecPtr, resultProc, userDataPtr));

	return(CallMXInfoProc(gDNRCodePtr, MXINFO, hostName, returnRecPtr, resultProc, userDataPtr));

}	/* removed ; (causes syntax err in Think C 5.0 */
	