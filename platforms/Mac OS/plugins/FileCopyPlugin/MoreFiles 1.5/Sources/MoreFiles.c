/*
**	Apple Macintosh Developer Technical Support
**
**	The long lost high-level and FSSpec File Manager functions.
**
**	by Jim Luther, Apple Developer Technical Support Emeritus
**
**	File:		MoreFiles.c
**
**	Copyright � 1992-1999 Apple Computer, Inc.
**	All rights reserved.
**
**	You may incorporate this sample code into your applications without
**	restriction, though the sample code has been provided "AS IS" and the
**	responsibility for its operation is 100% yours.  However, what you are
**	not permitted to do is to redistribute the source as "DSC Sample Code"
**	after having made changes. If you're going to re-distribute the source,
**	we require that you make it clear in the source that the code was
**	descended from Apple Sample Code, but that you've made changes.
*/

#include <Types.h>
#include <Errors.h>
#include <Files.h>

#define	__COMPILINGMOREFILES

#include "MoreFiles.h"
#include "MoreFilesExtras.h"

/*****************************************************************************/

pascal	OSErr	HGetVolParms(ConstStr255Param volName,
							 short vRefNum,
							 GetVolParmsInfoBuffer *volParmsInfo,
							 long *infoSize)
{
	HParamBlockRec pb;
	OSErr error;

	pb.ioParam.ioNamePtr = (StringPtr)volName;
	pb.ioParam.ioVRefNum = vRefNum;
	pb.ioParam.ioBuffer = (Ptr)volParmsInfo;
	pb.ioParam.ioReqCount = *infoSize;
	error = PBHGetVolParmsSync(&pb);
	if ( error == noErr )
	{
		*infoSize = pb.ioParam.ioActCount;
	}
	return ( error );
}

/*****************************************************************************/

pascal	OSErr	HCreateMinimum(short vRefNum,
							   long dirID,
							   ConstStr255Param fileName)
{
	HParamBlockRec pb;

	pb.fileParam.ioNamePtr = (StringPtr)fileName;
	pb.fileParam.ioVRefNum = vRefNum;
	pb.ioParam.ioVersNum = 0;
	pb.fileParam.ioDirID = dirID;
	return ( PBHCreateSync(&pb) );
}

/*****************************************************************************/

pascal	OSErr	FSpCreateMinimum(const FSSpec *spec)
{
	return ( HCreateMinimum(spec->vRefNum, spec->parID, spec->name) );
}

/*****************************************************************************/

pascal	OSErr	ExchangeFiles(short vRefNum,
							  long srcDirID,
							  ConstStr255Param srcName,
							  long dstDirID,
							  ConstStr255Param dstName)
{
	HParamBlockRec pb;

	pb.fidParam.ioVRefNum = vRefNum;
	pb.fidParam.ioSrcDirID = srcDirID;
	pb.fidParam.ioNamePtr = (StringPtr)srcName;
	pb.fidParam.ioDestDirID = dstDirID;
	pb.fidParam.ioDestNamePtr = (StringPtr)dstName;
	return ( PBExchangeFilesSync(&pb) );
}

/*****************************************************************************/

pascal	OSErr	ResolveFileIDRef(ConstStr255Param volName,
								 short vRefNum,
								 long fileID,
								 long *parID,
								 StringPtr fileName)
{
	HParamBlockRec pb;
	OSErr error;
	Str255 tempStr;
	
	tempStr[0] = 0;
	if ( volName != NULL )
	{
		BlockMoveData(volName, tempStr, volName[0] + 1);
	}
	pb.fidParam.ioNamePtr = (StringPtr)tempStr;
	pb.fidParam.ioVRefNum = vRefNum;
	pb.fidParam.ioFileID = fileID;
	error = PBResolveFileIDRefSync(&pb);
	if ( error == noErr )
	{
		*parID = pb.fidParam.ioSrcDirID;
		if ( fileName != NULL )
		{
			BlockMoveData(tempStr, fileName, tempStr[0] + 1);
		}
	}
	return ( error );
}

/*****************************************************************************/

pascal	OSErr	FSpResolveFileIDRef(ConstStr255Param volName,
									short vRefNum,
									long fileID,
									FSSpec *spec)
{
	OSErr	error;
	
	error = DetermineVRefNum(volName, vRefNum, &(spec->vRefNum));
	if ( error == noErr )
	{
		error = ResolveFileIDRef(volName, vRefNum, fileID, &(spec->parID), spec->name);
	}
	return ( error );
}

/*****************************************************************************/

pascal	OSErr	CreateFileIDRef(short vRefNum,
								long parID,
								ConstStr255Param fileName,
								long *fileID)
{
	HParamBlockRec pb;
	OSErr error;

	pb.fidParam.ioNamePtr = (StringPtr)fileName;
	pb.fidParam.ioVRefNum = vRefNum;
	pb.fidParam.ioSrcDirID = parID;
	error = PBCreateFileIDRefSync(&pb);
	if ( (error == noErr) || (error == fidExists) || (error == afpIDExists) )
	{
		*fileID = pb.fidParam.ioFileID;
	}
	return ( error );
}

/*****************************************************************************/

pascal	OSErr	FSpCreateFileIDRef(const FSSpec *spec,
								   long *fileID)
{
	return ( CreateFileIDRef(spec->vRefNum, spec->parID, spec->name, fileID) );
}

/*****************************************************************************/

pascal	OSErr	DeleteFileIDRef(ConstStr255Param volName,
								short vRefNum,
								long fileID)
{
	HParamBlockRec pb;

	pb.fidParam.ioNamePtr = (StringPtr)volName;
	pb.fidParam.ioVRefNum = vRefNum;
	pb.fidParam.ioFileID = fileID;
	return ( PBDeleteFileIDRefSync(&pb) );
}

/*****************************************************************************/

pascal	OSErr	FlushFile(short refNum)
{
	ParamBlockRec pb;

	pb.ioParam.ioRefNum = refNum;
	return ( PBFlushFileSync(&pb) );
}

/*****************************************************************************/

pascal	OSErr	LockRange(short refNum,
						  long rangeLength,
						  long rangeStart)
{
	ParamBlockRec pb;

	pb.ioParam.ioRefNum = refNum;
	pb.ioParam.ioReqCount = rangeLength;
	pb.ioParam.ioPosMode = fsFromStart;
	pb.ioParam.ioPosOffset = rangeStart;
	return ( PBLockRangeSync(&pb) );
}

/*****************************************************************************/

pascal	OSErr	UnlockRange(short refNum,
							long rangeLength,
							long rangeStart)
{
	ParamBlockRec pb;

	pb.ioParam.ioRefNum = refNum;
	pb.ioParam.ioReqCount = rangeLength;
	pb.ioParam.ioPosMode = fsFromStart;
	pb.ioParam.ioPosOffset = rangeStart;
	return ( PBUnlockRangeSync(&pb) );
}

/*****************************************************************************/

pascal	OSErr	GetForeignPrivs(short vRefNum,
								long dirID,
								ConstStr255Param name,
								void *foreignPrivBuffer,
								long *foreignPrivSize,
								long *foreignPrivInfo1,
								long *foreignPrivInfo2,
								long *foreignPrivInfo3,
								long *foreignPrivInfo4)
{
	HParamBlockRec pb;
	OSErr error;

	pb.foreignPrivParam.ioNamePtr = (StringPtr)name;
	pb.foreignPrivParam.ioVRefNum = vRefNum;
	pb.foreignPrivParam.ioForeignPrivDirID = dirID;	
	pb.foreignPrivParam.ioForeignPrivBuffer = (Ptr)foreignPrivBuffer;
	pb.foreignPrivParam.ioForeignPrivReqCount = *foreignPrivSize;
	error = PBGetForeignPrivsSync(&pb);
	*foreignPrivSize = pb.foreignPrivParam.ioForeignPrivActCount;
	*foreignPrivInfo1 = pb.foreignPrivParam.ioForeignPrivInfo1;
	*foreignPrivInfo2 = pb.foreignPrivParam.ioForeignPrivInfo2;
	*foreignPrivInfo3 = pb.foreignPrivParam.ioForeignPrivInfo3;
	*foreignPrivInfo4 = pb.foreignPrivParam.ioForeignPrivInfo4;
	return ( error );
}

/*****************************************************************************/

pascal	OSErr	FSpGetForeignPrivs(const FSSpec *spec,
								   void *foreignPrivBuffer,
								   long *foreignPrivSize,
								   long *foreignPrivInfo1,
								   long *foreignPrivInfo2,
								   long *foreignPrivInfo3,
								   long *foreignPrivInfo4)
{
	return ( GetForeignPrivs(spec->vRefNum, spec->parID, spec->name,
							 foreignPrivBuffer, foreignPrivSize,
							 foreignPrivInfo1, foreignPrivInfo2,
							 foreignPrivInfo3, foreignPrivInfo4) );
}

/*****************************************************************************/

pascal	OSErr	SetForeignPrivs(short vRefNum,
								long dirID,
								ConstStr255Param name,
								const void *foreignPrivBuffer,
								long *foreignPrivSize,
								long foreignPrivInfo1,
								long foreignPrivInfo2,
								long foreignPrivInfo3,
								long foreignPrivInfo4)
{
	HParamBlockRec pb;
	OSErr error;

	pb.foreignPrivParam.ioNamePtr = (StringPtr)name;
	pb.foreignPrivParam.ioVRefNum = vRefNum;
	pb.foreignPrivParam.ioForeignPrivDirID = dirID;	
	pb.foreignPrivParam.ioForeignPrivBuffer = (Ptr)foreignPrivBuffer;
	pb.foreignPrivParam.ioForeignPrivReqCount = *foreignPrivSize;
	pb.foreignPrivParam.ioForeignPrivInfo1 = foreignPrivInfo1;
	pb.foreignPrivParam.ioForeignPrivInfo2 = foreignPrivInfo2;
	pb.foreignPrivParam.ioForeignPrivInfo3 = foreignPrivInfo3;
	pb.foreignPrivParam.ioForeignPrivInfo4 = foreignPrivInfo4;
	error = PBSetForeignPrivsSync(&pb);
	if ( error == noErr )
	{
		*foreignPrivSize = pb.foreignPrivParam.ioForeignPrivActCount;
	}
	return ( error );
}

/*****************************************************************************/

pascal	OSErr	FSpSetForeignPrivs(const FSSpec *spec,
								   const void *foreignPrivBuffer,
								   long *foreignPrivSize,
								   long foreignPrivInfo1,
								   long foreignPrivInfo2,
								   long foreignPrivInfo3,
								   long foreignPrivInfo4)
{
	return ( SetForeignPrivs(spec->vRefNum, spec->parID, spec->name,
							 foreignPrivBuffer, foreignPrivSize,
							 foreignPrivInfo1, foreignPrivInfo2,
							 foreignPrivInfo3, foreignPrivInfo4) );
}

/*****************************************************************************/

pascal	OSErr	HGetLogInInfo(ConstStr255Param volName,
							  short vRefNum,
							  short *loginMethod,
							  StringPtr userName)
{
	HParamBlockRec pb;
	OSErr error;

	pb.objParam.ioNamePtr = (StringPtr)volName;
	pb.objParam.ioVRefNum = vRefNum;
	pb.objParam.ioObjNamePtr = userName;
	error = PBHGetLogInInfoSync(&pb);
	if ( error == noErr )
	{
		*loginMethod = pb.objParam.ioObjType;
	}
	return ( error );
}

/*****************************************************************************/

pascal	OSErr	HGetDirAccess(short vRefNum,
							  long dirID,
							  ConstStr255Param name,
							  long *ownerID,
							  long *groupID,
							  long *accessRights)
{
	HParamBlockRec pb;
	OSErr error;

	pb.accessParam.ioNamePtr = (StringPtr)name;
	pb.accessParam.ioVRefNum = vRefNum;
	pb.fileParam.ioDirID = dirID;
	error = PBHGetDirAccessSync(&pb);
	if ( error == noErr )
	{
		*ownerID = pb.accessParam.ioACOwnerID;
		*groupID = pb.accessParam.ioACGroupID;
		*accessRights = pb.accessParam.ioACAccess;
	}
	return ( error );
}

/*****************************************************************************/

pascal	OSErr	FSpGetDirAccess(const FSSpec *spec,
								long *ownerID,
								long *groupID,
								long *accessRights)
{
	return ( HGetDirAccess(spec->vRefNum, spec->parID, spec->name,
						   ownerID, groupID, accessRights) );
}

/*****************************************************************************/

pascal	OSErr	HSetDirAccess(short vRefNum,
							  long dirID,
							  ConstStr255Param name,
							  long ownerID,
							  long groupID,
							  long accessRights)
{
	HParamBlockRec pb;

	pb.accessParam.ioNamePtr = (StringPtr)name;
	pb.accessParam.ioVRefNum = vRefNum;
	pb.fileParam.ioDirID = dirID;
	pb.accessParam.ioACOwnerID = ownerID;
	pb.accessParam.ioACGroupID = groupID;
	pb.accessParam.ioACAccess = accessRights;
	return ( PBHSetDirAccessSync(&pb) );
}

/*****************************************************************************/

pascal	OSErr	FSpSetDirAccess(const FSSpec *spec,
								long ownerID,
								long groupID,
								long accessRights)
{
	return ( HSetDirAccess(spec->vRefNum, spec->parID, spec->name,
						   ownerID, groupID, accessRights) );
}

/*****************************************************************************/

pascal	OSErr	HMapID(ConstStr255Param volName,
					   short vRefNum,
					   long ugID,
					   short objType,
					   StringPtr name)
{
	HParamBlockRec pb;

	pb.objParam.ioNamePtr = (StringPtr)volName;
	pb.objParam.ioVRefNum = vRefNum;
	pb.objParam.ioObjType = objType;
	pb.objParam.ioObjNamePtr = name;
	pb.objParam.ioObjID = ugID;
	return ( PBHMapIDSync(&pb) );
}

/*****************************************************************************/

pascal	OSErr	HMapName(ConstStr255Param volName,
						 short vRefNum,
						 ConstStr255Param name,
						 short objType,
						 long *ugID)
{
	HParamBlockRec pb;
	OSErr error;

	pb.objParam.ioNamePtr = (StringPtr)volName;
	pb.objParam.ioVRefNum = vRefNum;
	pb.objParam.ioObjType = objType;
	pb.objParam.ioObjNamePtr = (StringPtr)name;
	error = PBHMapNameSync(&pb);
	if ( error == noErr )
	{
		*ugID = pb.objParam.ioObjID;
	}
	return ( error );
}

/*****************************************************************************/

pascal	OSErr	HCopyFile(short srcVRefNum,
						  long srcDirID,
						  ConstStr255Param srcName,
						  short dstVRefNum,
						  long dstDirID,
						  ConstStr255Param dstPathname,
						  ConstStr255Param copyName)
{
	HParamBlockRec pb;

	pb.copyParam.ioVRefNum = srcVRefNum;
	pb.copyParam.ioDirID = srcDirID;
	pb.copyParam.ioNamePtr = (StringPtr)srcName;
	pb.copyParam.ioDstVRefNum = dstVRefNum;
	pb.copyParam.ioNewDirID = dstDirID;
	pb.copyParam.ioNewName = (StringPtr)dstPathname;
	pb.copyParam.ioCopyName = (StringPtr)copyName;
	return ( PBHCopyFileSync(&pb) );
}

/*****************************************************************************/

pascal	OSErr	FSpCopyFile(const FSSpec *srcSpec,
							const FSSpec *dstSpec,
							ConstStr255Param copyName)
{
	return ( HCopyFile(srcSpec->vRefNum, srcSpec->parID, srcSpec->name,
					   dstSpec->vRefNum, dstSpec->parID,
					   dstSpec->name, copyName) );
}

/*****************************************************************************/

pascal	OSErr	HMoveRename(short vRefNum,
							long srcDirID,
							ConstStr255Param srcName,
							long dstDirID,
							ConstStr255Param dstpathName,
							ConstStr255Param copyName)
{
	HParamBlockRec pb;

	pb.copyParam.ioVRefNum = vRefNum;
	pb.copyParam.ioDirID = srcDirID;
	pb.copyParam.ioNamePtr = (StringPtr)srcName;
	pb.copyParam.ioNewDirID = dstDirID;
	pb.copyParam.ioNewName = (StringPtr)dstpathName;
	pb.copyParam.ioCopyName = (StringPtr)copyName;
	return ( PBHMoveRenameSync(&pb) );
}

/*****************************************************************************/

pascal	OSErr	FSpMoveRename(const FSSpec *srcSpec,
							  const FSSpec *dstSpec,
							  ConstStr255Param copyName)
{
	OSErr	error;
	
	/* make sure the FSSpecs refer to the same volume */
	if ( srcSpec->vRefNum != dstSpec->vRefNum )
	{
		error = diffVolErr;
	}
	else
	{
		error = HMoveRename(srcSpec->vRefNum, srcSpec->parID, srcSpec->name, 
							dstSpec->parID, dstSpec->name, copyName);
	}
	return ( error );
}

/*****************************************************************************/

pascal	OSErr	GetVolMountInfoSize(ConstStr255Param volName,
									short vRefNum,
									short *size)
{
	ParamBlockRec pb;

	pb.ioParam.ioNamePtr = (StringPtr)volName;
	pb.ioParam.ioVRefNum = vRefNum;
	pb.ioParam.ioBuffer = (Ptr)size;
	return ( PBGetVolMountInfoSize(&pb) );
}

/*****************************************************************************/

pascal	OSErr	GetVolMountInfo(ConstStr255Param volName,
								short vRefNum,
								void *volMountInfo)
{
	ParamBlockRec pb;

	pb.ioParam.ioNamePtr = (StringPtr)volName;
	pb.ioParam.ioVRefNum = vRefNum;
	pb.ioParam.ioBuffer = (Ptr)volMountInfo;
	return ( PBGetVolMountInfo(&pb) );
}

/*****************************************************************************/

pascal	OSErr	VolumeMount(const void *volMountInfo,
							short *vRefNum)
{
	ParamBlockRec pb;
	OSErr error;

	pb.ioParam.ioBuffer = (Ptr)volMountInfo;
	error = PBVolumeMount(&pb);
	if ( error == noErr )
	{
		*vRefNum = pb.ioParam.ioVRefNum;
	}
	return ( error );
}

/*****************************************************************************/

pascal	OSErr	Share(short vRefNum,
					  long dirID,
					  ConstStr255Param name)
{
	HParamBlockRec pb;

	pb.fileParam.ioNamePtr = (StringPtr)name;
	pb.fileParam.ioVRefNum = vRefNum;
	pb.fileParam.ioDirID = dirID;
	return ( PBShareSync(&pb) );
}

/*****************************************************************************/

pascal	OSErr	FSpShare(const FSSpec *spec)
{
	return ( Share(spec->vRefNum, spec->parID, spec->name) );
}

/*****************************************************************************/

pascal	OSErr	Unshare(short vRefNum,
						long dirID,
						ConstStr255Param name)
{
	HParamBlockRec pb;

	pb.fileParam.ioNamePtr = (StringPtr)name;
	pb.fileParam.ioVRefNum = vRefNum;
	pb.fileParam.ioDirID = dirID;
	return ( PBUnshareSync(&pb) );
}

/*****************************************************************************/

pascal	OSErr	FSpUnshare(const FSSpec *spec)
{
	return ( Unshare(spec->vRefNum, spec->parID, spec->name) );
}

/*****************************************************************************/

pascal	OSErr	GetUGEntry(short objType,
						   StringPtr objName,
						   long *objID)
{
	HParamBlockRec pb;
	OSErr error;

	pb.objParam.ioObjType = objType;
	pb.objParam.ioObjNamePtr = objName;
	pb.objParam.ioObjID = *objID;
	error = PBGetUGEntrySync(&pb);
	if ( error == noErr )
	{
		*objID = pb.objParam.ioObjID;
	}
	return ( error );
}

/*****************************************************************************/
