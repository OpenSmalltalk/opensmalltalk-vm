UNIT MoreFiles;

{	Apple Macintosh Developer Technical Support								}
{																			}
{	The long lost high-level and FSSpec File Manager functions.				}
{	by Jim Luther, Apple Developer Technical Support Emeritus				}
{																			}
{	File:		MoreFiles.p													}
{																			}
{	Copyright © 1992-1999 Apple Computer, Inc.								}
{	All rights reserved.													}
{																			}
{	You may incorporate this sample code into your applications without		}
{	restriction, though the sample code has been provided "AS IS" and the	}
{	responsibility for its operation is 100% yours.  However, what you are	}
{	not permitted to do is to redistribute the source as "DSC Sample Code"	}
{	after having made changes. If you're going to re-distribute the source,	}
{	we require that you make it clear in the source that the code was		}
{	descended from Apple Sample Code, but that you've made changes.			}


INTERFACE

	USES
		Types, Files;

{***************************************************************************}


	FUNCTION HGetVolParms (volName: StringPtr;
									vRefNum: Integer;
									VAR volParmsInfo: GetVolParmsInfoBuffer;
									VAR infoSize: LongInt): OSErr;

	FUNCTION HCreateMinimum (vRefNum: Integer;
									dirID: LongInt;
									fileName: Str255): OSErr;

	FUNCTION FSpCreateMinimum ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION ExchangeFiles (vRefNum: Integer;
									srcDirID: LongInt;
									srcName: Str255;
									dstDirID: LongInt;
									dstName: Str255): OSErr;

	FUNCTION ResolveFileIDRef (volName: StringPtr;
									vRefNum: Integer;
									fileID: LongInt;
									VAR parID: LongInt;
									fileName: StringPtr): OSErr;

	FUNCTION FSpResolveFileIDRef (volName: StringPtr;
									vRefNum: Integer;
									fileID: LongInt;
									VAR spec: FSSpec): OSErr;

	FUNCTION CreateFileIDRef (vRefNum: Integer;
									parID: LongInt;
									fileName: Str255;
									VAR fileID: LongInt): OSErr;

	FUNCTION FSpCreateFileIDRef ({CONST}
									VAR spec: FSSpec;
									VAR fileID: LongInt): OSErr;

	FUNCTION DeleteFileIDRef (volName: StringPtr;
									vRefNum: Integer;
									fileID: LongInt): OSErr;

	FUNCTION FlushFile (refNum: Integer): OSErr;

	FUNCTION LockRange (refNum: Integer;
									rangeLength: LongInt;
									rangeStart: LongInt): OSErr;

	FUNCTION UnlockRange (refNum: Integer;
									rangeLength: LongInt;
									rangeStart: LongInt): OSErr;

	FUNCTION GetForeignPrivs (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									foreignPrivBuffer: Ptr;
									VAR foreignPrivSize: LongInt;
									VAR foreignPrivInfo1: LongInt;
									VAR foreignPrivInfo2: LongInt;
									VAR foreignPrivInfo3: LongInt;
									VAR foreignPrivInfo4: LongInt): OSErr;

	FUNCTION FSpGetForeignPrivs ({CONST}
									VAR spec: FSSpec;
									foreignPrivBuffer: Ptr;
									VAR foreignPrivSize: LongInt;
									VAR foreignPrivInfo1: LongInt;
									VAR foreignPrivInfo2: LongInt;
									VAR foreignPrivInfo3: LongInt;
									VAR foreignPrivInfo4: LongInt): OSErr;

	FUNCTION SetForeignPrivs (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									foreignPrivBuffer: Ptr;
									VAR foreignPrivSize: LongInt;
									foreignPrivInfo1: LongInt;
									foreignPrivInfo2: LongInt;
									foreignPrivInfo3: LongInt;
									foreignPrivInfo4: LongInt): OSErr;

	FUNCTION FSpSetForeignPrivs ({CONST}
									VAR spec: FSSpec;
									foreignPrivBuffer: Ptr;
									VAR foreignPrivSize: LongInt;
									foreignPrivInfo1: LongInt;
									foreignPrivInfo2: LongInt;
									foreignPrivInfo3: LongInt;
									foreignPrivInfo4: LongInt): OSErr;

	FUNCTION HGetLogInInfo (volName: StringPtr;
									vRefNum: Integer;
									VAR loginMethod: Integer;
									userName: StringPtr): OSErr;

	FUNCTION HGetDirAccess (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									VAR ownerID: LongInt;
									VAR groupID: LongInt;
									VAR accessRights: LongInt): OSErr;

	FUNCTION FSpGetDirAccess ({CONST}
									VAR spec: FSSpec;
									VAR ownerID: LongInt;
									VAR groupID: LongInt;
									VAR accessRights: LongInt): OSErr;

	FUNCTION HSetDirAccess (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									ownerID: LongInt;
									groupID: LongInt;
									accessRights: LongInt): OSErr;

	FUNCTION FSpSetDirAccess ({CONST}
									VAR spec: FSSpec;
									ownerID: LongInt;
									groupID: LongInt;
									accessRights: LongInt): OSErr;

	FUNCTION HMapID (volName: StringPtr;
									vRefNum: Integer;
									ugID: LongInt;
									objType: Integer;
									name: StringPtr): OSErr;

	FUNCTION HMapName (volName: StringPtr;
									vRefNum: Integer;
									name: Str255;
									objType: Integer;
									VAR ugID: LongInt): OSErr;

	FUNCTION HCopyFile (srcVRefNum: Integer;
									srcDirID: LongInt;
									srcName: Str255;
									dstVRefNum: Integer;
									dstDirID: LongInt;
									dstPathname: StringPtr;
									copyName: StringPtr): OSErr;

	FUNCTION FSpCopyFile ({CONST}
									VAR srcSpec: FSSpec;
									{CONST}
									VAR dstSpec: FSSpec;
									copyName: StringPtr): OSErr;

	FUNCTION HMoveRename (vRefNum: Integer;
									srcDirID: LongInt;
									srcName: Str255;
									dstDirID: LongInt;
									dstpathName: StringPtr;
									copyName: StringPtr): OSErr;

	FUNCTION FSpMoveRename ({CONST}
									VAR srcSpec: FSSpec;
									{CONST}
									VAR dstSpec: FSSpec;
									copyName: StringPtr): OSErr;

	FUNCTION GetVolMountInfoSize (volName: StringPtr;
									vRefNum: Integer;
									VAR size: Integer): OSErr;

	FUNCTION GetVolMountInfo (volName: StringPtr;
									vRefNum: Integer;
									volMountInfo: Ptr): OSErr;

	FUNCTION VolumeMount (volMountInfo: Ptr;
									VAR vRefNum: Integer): OSErr;

	FUNCTION Share (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr): OSErr;

	FUNCTION FSpShare ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION Unshare (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr): OSErr;

	FUNCTION FSpUnshare ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION GetUGEntry (objType: Integer;
									objName: StringPtr;
									VAR objID: LongInt): OSErr;


{***************************************************************************}

IMPLEMENTATION

END.