UNIT MoreFilesExtras;

{	Apple Macintosh Developer Technical Support								}
{																			}
{	A collection of useful high-level File Manager routines.				}
{	by Jim Luther, Apple Developer Technical Support Emeritus				}
{																			}
{	File:		MoreFilesExtras.p											}
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
		Types, Files, Finder;

{***************************************************************************}

	CONST
		{	Deny mode permissions for use with the HOpenAware, HOpenRFAware,	}
		{	FSpOpenAware, and FSpOpenRFAware functions.							}
		{	Note: Common settings are the ones with comments.					}

		dmNone = $0000;
		dmNoneDenyRd = fsRdDenyPerm;
		dmNoneDenyWr = fsWrDenyPerm;
		dmNoneDenyRdWr = fsRdDenyPerm + fsWrDenyPerm;
		dmRd = fsRdPerm;							{ Single writer, multiple readers; the readers }
		dmRdDenyRd = fsRdPerm + fsRdDenyPerm;
		dmRdDenyWr = fsRdPerm + fsWrDenyPerm;		{ Browsing - equivalent to fsRdPerm }
		dmRdDenyRdWr = fsRdPerm + fsRdDenyPerm + fsWrDenyPerm;
		dmWr = fsWrPerm;
		dmWrDenyRd = fsWrPerm + fsRdDenyPerm;
		dmWrDenyWr = fsWrPerm + fsWrDenyPerm;
		dmWrDenyRdWr = fsWrPerm + fsRdDenyPerm + fsWrDenyPerm;
		dmRdWr = fsRdWrPerm;						{ Shared access - equivalent to fsRdWrShPerm }
		dmRdWrDenyRd = fsRdWrPerm + fsRdDenyPerm;
		dmRdWrDenyWr = fsRdWrPerm + fsWrDenyPerm;	{ Single writer, multiple readers; the writer }
		dmRdWrDenyRdWr = fsRdWrPerm + fsRdDenyPerm + fsWrDenyPerm;	{ Exclusive access - equivalent to fsRdWrPerm }

		{	Bit masks to get common information out of ioACUser returned by			}
		{	PBGetCatInfo (remember to clear ioACUser before calling PBGetCatInfo	}
		{	since some file systems don't bother to set this field).				}
		{																			}
		{	Use the GetDirAccessRestrictions or FSpGetDirAccessRestrictions			}
		{	functions to retrieve the ioACUser access restrictions byte for			}
		{	a folder.																}
		{																			}
		{	Note:	The access restriction byte returned by PBGetCatInfo is the		}
		{			2's complement of the user's privileges byte returned in		}
		{			ioACAccess by PBHGetDirAccess.									}

		{ mask for just the access restriction bits }
		acUserAccessMask = kioACUserNoSeeFolderMask + kioACUserNoSeeFilesMask + kioACUserNoMakeChangesMask;

		{ common access privilege settings }
		acUserFull = $00;						{ no access restiction bits on }
		acUserNone = acUserAccessMask;			{ all access restiction bits on }
		acUserDropBox = kioACUserNoSeeFolderMask + kioACUserNoSeeFilesMask; { make changes, but not see files or folders }
		acUserBulletinBoard = kioACUserNoMakeChangesMask;	{ see files and folders, but not make changes }


{	For those times where you need to use more than one kind of				}
{	File Manager parameter block but don't feel like wasting stack space,	}
{	here's a parameter block you can reuse.									}

{$PUSH}
{$ALIGN MAC68K}

	TYPE
		UniversalFMPBHandle = ^UniversalFMPBPtr;
		UniversalFMPBPtr = ^UniversalFMPB;
		UniversalFMPB = RECORD
				CASE Integer OF
					1: (
							PB: ParamBlockRec
					);
					2: (
							ciPB: CInfoPBRec
					);
					3: (
							dtPB: DTPBRec
					);
					4: (
							hPB: HParamBlockRec
					);
					5: (
							cmPB: CMovePBRec
					);
					6: (
							wdPB: WDPBRec
					);
					7: (
							fcbPB: FCBPBRec
					);
					8: (
							xPB: XVolumeParam
					);
			END;


{	Used by GetUGEntries to return user or group lists.						}

		UGEntryHandle = ^UGEntryPtr;
		UGEntryPtr = ^UGEntry;
		UGEntry = RECORD
				objType: Integer;
				objID: LongInt;
				name: Str31;
			END;


{	I use the following records instead of the AFPVolMountInfo and			}
{	AFPXVolMountInfo structures in Files.p									}

		Str8 = STRING[8];
		MyAFPVolMountInfoHandle = ^MyAFPVolMountInfoPtr;
		MyAFPVolMountInfoPtr = ^MyAFPVolMountInfo;
		MyAFPVolMountInfo = RECORD
				length: Integer;				{ length of this record }
				media: VolumeType;				{ type of media, always AppleShareMediaType }
				flags: Integer;					{ 0 = normal mount; set bit 0 to inhibit greeting messages }
				nbpInterval: SignedByte;		{ NBP interval parameter; 7 is a good choice }
				nbpCount: SignedByte;			{ NBP count parameter; 5 is a good choice }
				uamType: Integer;				{ User Authentication Method }
				zoneNameOffset: Integer;		{ offset from start of record to zoneName }
				serverNameOffset: Integer;		{ offset from start of record to serverName }
				volNameOffset: Integer;			{ offset from start of record to volName }
				userNameOffset: Integer;		{ offset from start of record to userName }
				userPasswordOffset: Integer;	{ offset from start of record to userPassword }
				volPasswordOffset: Integer;		{ offset from start of record to volPassword }
				zoneName: Str32;				{ server's AppleTalk zone name }
				serverName: Str32;				{ server name }
				volName: Str27;					{ volume name }
				userName: Str31;				{ user name (zero length Pascal string for guest) }
				userPassword: Str8;				{ user password (zero length Pascal string if no user password) }
				volPassword: Str8;				{ volume password (zero length Pascal string if no volume password) }
			END;
		MyAFPXVolMountInfo = RECORD
				length: Integer;				{ length of this record }
				media: VolumeType;				{ type of media, always AppleShareMediaType }
				flags: Integer;					{ 0 = normal mount; set bit 0 to inhibit greeting messages }
				nbpInterval: SignedByte;		{ NBP interval parameter; 7 is a good choice }
				nbpCount: SignedByte;			{ NBP count parameter; 5 is a good choice }
				uamType: Integer;				{ User Authentication Method }
				zoneNameOffset: Integer;		{ offset from start of record to zoneName }
				serverNameOffset: Integer;		{ offset from start of record to serverName }
				volNameOffset: Integer;			{ offset from start of record to volName }
				userNameOffset: Integer;		{ offset from start of record to userName }
				userPasswordOffset: Integer;	{ offset from start of record to userPassword }
				volPasswordOffset: Integer;		{ offset from start of record to volPassword }
				extendedFlags: Integer;			{ extended flags word }
				uamNameOffset: Integer;			{ offset to a pascal UAM name string }
				alternateAddressOffset: Integer; { offset to Alternate Addresses in tagged format }
				zoneName: Str32;				{ server's AppleTalk zone name }
				serverName: Str32;				{ server name }
				volName: Str27;					{ volume name }
				userName: Str31;				{ user name (zero length Pascal string for guest) }
				userPassword: Str8;				{ user password (zero length Pascal string if no user password) }
				volPassword: Str8;				{ volume password (zero length Pascal string if no volume password) }
				uamName: Str32;					{ UAM name }
				alternateAddress: Packed Array [0..0] OF Char; { variable length data }
			END;

{$ALIGN RESET}
{$POP}


{***************************************************************************}

	{	Functions to get information out of GetVolParmsInfoBuffer.	}
	{	(implemented in this Unit).									}
	
	{ version 1 field getters }
	FUNCTION GetVolParmsInfoVersion(VAR volParms: GetVolParmsInfoBuffer): INTEGER;
	FUNCTION GetVolParmsInfoAttrib(VAR volParms: GetVolParmsInfoBuffer): LONGINT;
	FUNCTION GetVolParmsInfoLocalHand(VAR volParms: GetVolParmsInfoBuffer): Handle;
	FUNCTION GetVolParmsInfoServerAdr(VAR volParms: GetVolParmsInfoBuffer): LONGINT;
	{ version 2 field getters (assume zero result if not version >= 2) }
	FUNCTION GetVolParmsInfoVolumeGrade(VAR volParms: GetVolParmsInfoBuffer): LONGINT;
	FUNCTION GetVolParmsInfoForeignPrivID(VAR volParms: GetVolParmsInfoBuffer): INTEGER;
	{ version 3 field getters (assume zero result if not version >= 3) }
	FUNCTION GetVolParmsInfoExtendedAttributes(VAR volParms: GetVolParmsInfoBuffer): LONGINT;
	
	{ attribute bits supported by all versions of GetVolParmsInfoBuffer }
	FUNCTION isNetworkVolume (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasLimitFCBs (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasLocalWList (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasNoMiniFndr (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasNoVNEdit (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasNoLclSync (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasTrshOffLine (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasNoSwitchTo (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasNoDeskItems (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasNoBootBlks (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasAccessCntl (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasNoSysDir (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasExtFSVol (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasOpenDeny (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasCopyFile (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasMoveRename (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasDesktopMgr (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasShortName (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasFolderLock (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasPersonalAccessPrivileges (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasUserGroupList (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasCatSearch (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasFileIDs (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasBTreeMgr (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION hasBlankAccessPrivileges (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION supportsAsyncRequests (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION supportsTrashVolumeCache (VAR volParms: GetVolParmsInfoBuffer): Boolean;

	{ attribute bits supported by version 3 and greater versions of GetVolParmsInfoBuffer }
	FUNCTION volIsEjectable (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION volSupportsHFSPlusAPIs (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION volSupportsFSCatalogSearch (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION volSupportsFSExchangeObjects (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION volSupports2TBFiles (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION volSupportsLongNames (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION volSupportsMultiScriptNames (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION volSupportsNamedForks (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION volSupportsSubtreeIterators (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	FUNCTION volL2PCanMapFileBlocks (VAR volParms: GetVolParmsInfoBuffer): Boolean;

	{	Functions to get common information out of ioACUser.	}
	{	(implemented in this Unit).								}
	FUNCTION userIsOwner (ioACUser: SInt8): Boolean;
	FUNCTION userHasFullAccess (ioACUser: SInt8): Boolean;
	FUNCTION userHasDropBoxAccess (ioACUser: SInt8): Boolean;
	FUNCTION userHasBulletinBoard (ioACUser: SInt8): Boolean;
	FUNCTION userHasNoAccess (ioACUser: SInt8): Boolean;


{***************************************************************************}


	PROCEDURE TruncPString (destination: StringPtr;
									source: StringPtr;
									maxLength: Integer);

	FUNCTION GetTempBuffer (buffReqSize: LONGINT;
									VAR buffActSize: LONGINT): Ptr;

	FUNCTION GetVolumeInfoNoName (pathname: StringPtr;
									vRefNum: Integer;
									VAR pb: HParamBlockRec): OSErr;

	FUNCTION XGetVolumeInfoNoName(pathname: StringPtr;
									vRefNum: Integer;
									VAR pb: XVolumeParam): OSErr;
	
	FUNCTION GetCatInfoNoName (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									VAR pb: CInfoPBRec): OSErr;

	FUNCTION DetermineVRefNum (pathname: StringPtr;
									vRefNum: Integer;
									VAR realVRefNum: Integer): OSErr;

	FUNCTION HGetVInfo (volReference: Integer;
									volName: StringPtr;
									VAR vRefNum: Integer;
									VAR freeBytes: LongInt;
									VAR totalBytes: LongInt): OSErr;

	FUNCTION XGetVInfo (volReference: Integer;
									volName: StringPtr;
									VAR vRefNum: Integer;
									VAR freeBytes: UnsignedWide;
									VAR totalBytes: UnsignedWide): OSErr;

	FUNCTION CheckVolLock (pathname: StringPtr;
									vRefNum: Integer): OSErr;

	FUNCTION GetDriverName (driverRefNum: Integer;
									VAR driverName: Str255): OSErr;

	FUNCTION FindDrive (pathname: StringPtr;
									vRefNum: Integer;
									VAR driveQElementPtr: DrvQElPtr): OSErr;

	FUNCTION GetVolFileSystemID (pathname: StringPtr;
									vRefNum: Integer;
									VAR fileSystemID: Integer): OSErr;
								   
	FUNCTION GetVolState (pathname: StringPtr;
									vRefNum: Integer;
									VAR volumeOnline: Boolean;
									VAR volumeEjected: Boolean;
									VAR driveEjectable: Boolean;
									VAR driverWantsEject: Boolean): OSErr;
								   
	FUNCTION UnmountAndEject (pathname: StringPtr;
									vRefNum: Integer): OSErr;

	FUNCTION OnLine (volumes: FSSpecPtr;
									reqVolCount: Integer;
									VAR actVolCount: Integer;
									VAR volIndex: Integer): OSErr;

	FUNCTION SetDefault (newVRefNum: Integer;
									newDirID: LongInt;
									VAR oldVRefNum: Integer;
									VAR oldDirID: LongInt): OSErr;

	FUNCTION RestoreDefault (oldVRefNum: Integer;
									oldDirID: LongInt): OSErr;

	FUNCTION GetDInfo (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									VAR fndrInfo: DInfo): OSErr;

	FUNCTION FSpGetDInfo ({CONST}
									VAR spec: FSSpec;
									VAR fndrInfo: DInfo): OSErr;

	FUNCTION SetDInfo (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									fndrInfo: DInfo): OSErr;

	FUNCTION FSpSetDInfo ({CONST}
									VAR spec: FSSpec;
									fndrInfo: DInfo): OSErr;

	FUNCTION GetDirectoryID (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									VAR theDirID: LongInt;
									VAR isDirectory: Boolean): OSErr;

	FUNCTION FSpGetDirectoryID ({CONST}
									VAR spec: FSSpec;
									VAR theDirID: LongInt;
									VAR isDirectory: Boolean): OSErr;

	FUNCTION GetDirName (vRefNum: Integer;
									dirID: LongInt;
									VAR name: Str31): OSErr;

	FUNCTION GetIOACUser (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									VAR ioACUser: SInt8): OSErr;

	FUNCTION FSpGetIOACUser (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									VAR ioACUser: SInt8): OSErr;

	FUNCTION GetParentID (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									VAR parID: LongInt): OSErr;

	FUNCTION GetFilenameFromPathname (pathname: Str255;
									VAR filename: Str255): OSErr;

	FUNCTION GetObjectLocation (vRefNum: Integer;
									dirID: LongInt;
									pathname: StringPtr;
									VAR realVRefNum: Integer;
									VAR realParID: LongInt;
									VAR realName: Str255;
									VAR isDirectory: Boolean): OSErr;

	FUNCTION GetDirItems (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									getFiles: Boolean;
									getDirectories: Boolean;
									items: FSSpecPtr;
									reqItemCount: Integer;
									VAR actItemCount: Integer;
									VAR itemIndex: Integer): OSErr;

	FUNCTION DeleteDirectoryContents (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr): OSErr;

	FUNCTION DeleteDirectory (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr): OSErr;

	FUNCTION CheckObjectLock (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr): OSErr;

	FUNCTION FSpCheckObjectLock ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION GetFileSize (vRefNum: Integer;
									dirID: LongInt;
									fileName: Str255;
									VAR dataSize: LONGINT;
									VAR rsrcSize: LONGINT): OSErr;

	FUNCTION FSpGetFileSize ({CONST}
									VAR spec: FSSpec;
									VAR dataSize: LONGINT;
									VAR rsrcSize: LONGINT): OSErr;

	FUNCTION BumpDate (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr): OSErr;

	FUNCTION FSpBumpDate ({CONST}
									VAR spec: FSSpec): OSErr;


	FUNCTION ChangeCreatorType (vRefNum: Integer;
									dirID: LongInt;
									name: Str255;
									creator: OSType;
									fileType: OSType): OSErr;

	FUNCTION FSpChangeCreatorType ({CONST}
									VAR spec: FSSpec;
									creator: OSType;
									fileType: OSType): OSErr;

	FUNCTION ChangeFDFlags (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									setBits: Boolean;
									flagBits: Integer): OSErr;

	FUNCTION FSpChangeFDFlags ({CONST}
									VAR spec: FSSpec;
									setBits: Boolean;
									flagBits: Integer): OSErr;

	FUNCTION SetIsInvisible (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr): OSErr;

	FUNCTION FSpSetIsInvisible ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION ClearIsInvisible (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr): OSErr;

	FUNCTION FSpClearIsInvisible ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION SetNameLocked (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr): OSErr;

	FUNCTION FSpSetNameLocked ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION ClearNameLocked (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr): OSErr;

	FUNCTION FSpClearNameLocked ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION SetIsStationery (vRefNum: Integer;
									dirID: LongInt;
									name: Str255): OSErr;

	FUNCTION FSpSetIsStationery ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION ClearIsStationery (vRefNum: Integer;
									dirID: LongInt;
									name: Str255): OSErr;

	FUNCTION FSpClearIsStationery ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION SetHasCustomIcon (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr): OSErr;

	FUNCTION FSpSetHasCustomIcon ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION ClearHasCustomIcon (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr): OSErr;

	FUNCTION FSpClearHasCustomIcon ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION ClearHasBeenInited (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr): OSErr;

	FUNCTION FSpClearHasBeenInited ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION CopyFileMgrAttributes (srcVRefNum: Integer;
									srcDirID: LongInt;
									srcName: StringPtr;
									dstVRefNum: Integer;
									dstDirID: LongInt;
									dstName: StringPtr;
									copyLockBit: Boolean): OSErr;

	FUNCTION FSpCopyFileMgrAttributes ({CONST}
									VAR srcSpec: FSSpec;
									{CONST}
									VAR dstSpec: FSSpec;
									copyLockBit: Boolean): OSErr;

	FUNCTION HOpenAware (vRefNum: Integer;
									dirID: LongInt;
									fileName: Str255;
									denyModes: Integer;
									VAR refNum: Integer): OSErr;

	FUNCTION FSpOpenAware ({CONST}
									VAR spec: FSSpec;
									denyModes: Integer;
									VAR refNum: Integer): OSErr;

	FUNCTION HOpenRFAware (vRefNum: Integer;
									dirID: LongInt;
									fileName: Str255;
									denyModes: Integer;
									VAR refNum: Integer): OSErr;

	FUNCTION FSpOpenRFAware ({CONST}
									VAR spec: FSSpec;
									denyModes: Integer;
									VAR refNum: Integer): OSErr;

	FUNCTION FSReadNoCache (refNum: Integer;
									VAR count: LongInt;
									buffPtr: Ptr): OSErr;

	FUNCTION FSWriteNoCache (refNum: Integer;
									VAR count: LongInt;
									buffPtr: Ptr): OSErr;

	FUNCTION FSWriteVerify (refNum: Integer;
									VAR count: LongInt;
									buffPtr: Ptr): OSErr;

	FUNCTION CopyFork (srcRefNum: Integer;
									dstRefNum: Integer;
									copyBufferPtr: Ptr;
									copyBufferSize: LongInt): OSErr;

	FUNCTION GetFileLocation (refNum: Integer;
									VAR vRefNum: Integer;
									VAR dirID: LongInt;
									fileName: StringPtr): OSErr;

	FUNCTION FSpGetFileLocation (refNum: Integer;
									VAR spec: FSSpec): OSErr;

	FUNCTION CopyDirectoryAccess (srcVRefNum: Integer;
									srcDirID: LongInt;
									srcName: StringPtr;
									dstVRefNum: Integer;
									dstDirID: LongInt;
									dstName: StringPtr): OSErr;

	FUNCTION FSpCopyDirectoryAccess ({CONST}
									VAR srcSpec: FSSpec;
									{CONST}
									VAR dstSpec: FSSpec): OSErr;

	FUNCTION HMoveRenameCompat (vRefNum: Integer;
									srcDirID: LongInt;
									srcName: Str255;
									dstDirID: LongInt;
									dstpathName: StringPtr;
									copyName: StringPtr): OSErr;

	FUNCTION FSpMoveRenameCompat ({CONST}
									VAR srcSpec: FSSpec;
									{CONST}
									VAR dstSpec: FSSpec;
									copyName: StringPtr): OSErr;

	FUNCTION BuildAFPVolMountInfo (flags: Integer;
									nbpInterval: SignedByte;
									nbpCount: SignedByte;
									uamType: Integer;
									zoneName: Str32;
									serverName: Str32;
									volName: Str27;
									userName: Str31;
									userPassword: Str8;
									volPassword: Str8;
									VAR afpInfoPtr: MyAFPVolMountInfoPtr): OSErr;

	FUNCTION RetrieveAFPVolMountInfo (afpInfoPtr: AFPVolMountInfoPtr;
									VAR flags: Integer;
									VAR uamType: Integer;
									zoneName: StringPtr;
									serverName: StringPtr;
									volName: StringPtr;
									userName: StringPtr): OSErr;

	FUNCTION BuildAFPXVolMountInfo (flags: Integer;
									nbpInterval: SignedByte;
									nbpCount: SignedByte;
									uamType: Integer;
									zoneName: Str32;
									serverName: Str32;
									volName: Str27;
									userName: Str31;
									userPassword: Str8;
									volPassword: Str8;
									uamName: Str32;
									alternateAddressLength: LongInt;
									alternateAddress: Ptr;
									VAR afpXInfoPtr: AFPXVolMountInfoPtr): OSErr;

	FUNCTION RetrieveAFPXVolMountInfo(afpXInfoPtr: AFPXVolMountInfoPtr;
									VAR flags: Integer;
									VAR uamType: Integer;
									zoneName: StringPtr;
									serverName: StringPtr;
									volName: StringPtr;
									userName: StringPtr;
									uamName: StringPtr;
									VAR alternateAddressLength: LongInt;
									VAR	alternateAddress: AFPAlternateAddressPtr): OSErr;

	FUNCTION GetUGEntries (objType: Integer;
									entries: UGEntryPtr;
									reqEntryCount: LongInt;
									VAR actEntryCount: LongInt;
									VAR objID: LongInt): OSErr;


{***************************************************************************}


IMPLEMENTATION

	{	Functions to get information out of GetVolParmsInfoBuffer.	}
	
	FUNCTION GetVolParmsInfoVersion(VAR volParms: GetVolParmsInfoBuffer): INTEGER;
	BEGIN
		GetVolParmsInfoVersion := volParms.vMVersion;
	END;
	
	FUNCTION GetVolParmsInfoAttrib(VAR volParms: GetVolParmsInfoBuffer): LONGINT;
	BEGIN
		GetVolParmsInfoAttrib := volParms.vMAttrib;
	END;
	
	FUNCTION GetVolParmsInfoLocalHand(VAR volParms: GetVolParmsInfoBuffer): Handle;
	BEGIN
		GetVolParmsInfoLocalHand := volParms.vMLocalHand;
	END;
	
	FUNCTION GetVolParmsInfoServerAdr(VAR volParms: GetVolParmsInfoBuffer): LONGINT;
	BEGIN
		GetVolParmsInfoServerAdr := volParms.vMServerAdr;
	END;

	FUNCTION GetVolParmsInfoVolumeGrade(VAR volParms: GetVolParmsInfoBuffer): LONGINT;
	BEGIN
		IF volParms.vMVersion >= 2
			THEN
				GetVolParmsInfoVolumeGrade := volParms.vMVolumeGrade
			ELSE
				GetVolParmsInfoVolumeGrade := 0;
	END;
	
	FUNCTION GetVolParmsInfoForeignPrivID(VAR volParms: GetVolParmsInfoBuffer): INTEGER;
	BEGIN
		IF volParms.vMVersion >= 2
			THEN
				GetVolParmsInfoForeignPrivID := volParms.vMForeignPrivID
			ELSE
				GetVolParmsInfoForeignPrivID := 0;
	END;
	
	FUNCTION GetVolParmsInfoExtendedAttributes(VAR volParms: GetVolParmsInfoBuffer): LONGINT;
	BEGIN
		IF volParms.vMVersion >= 3
			THEN
				GetVolParmsInfoExtendedAttributes := volParms.vMExtendedAttributes
			ELSE
				GetVolParmsInfoExtendedAttributes := 0;
	END;
	
	FUNCTION isNetworkVolume (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		isNetworkVolume := (volParms.vMServerAdr <> 0);
	END;

	FUNCTION hasLimitFCBs (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasLimitFCBs := BTST(volParms.vMAttrib, bLimitFCBs);
	END;

	FUNCTION hasLocalWList (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasLocalWList := BTST(volParms.vMAttrib, bLocalWList);
	END;

	FUNCTION hasNoMiniFndr (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasNoMiniFndr := BTST(volParms.vMAttrib, bNoMiniFndr);
	END;

	FUNCTION hasNoVNEdit (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasNoVNEdit := BTST(volParms.vMAttrib, bNoVNEdit);
	END;

	FUNCTION hasNoLclSync (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasNoLclSync := BTST(volParms.vMAttrib, bNoLclSync);
	END;

	FUNCTION hasTrshOffLine (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasTrshOffLine := BTST(volParms.vMAttrib, bTrshOffLine);
	END;

	FUNCTION hasNoSwitchTo (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasNoSwitchTo := BTST(volParms.vMAttrib, bNoSwitchTo);
	END;

	FUNCTION hasNoDeskItems (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasNoDeskItems := BTST(volParms.vMAttrib, bNoDeskItems);
	END;

	FUNCTION hasNoBootBlks (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasNoBootBlks := BTST(volParms.vMAttrib, bNoBootBlks);
	END;

	FUNCTION hasAccessCntl (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasAccessCntl := BTST(volParms.vMAttrib, bAccessCntl);
	END;

	FUNCTION hasNoSysDir (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasNoSysDir := BTST(volParms.vMAttrib, bNoSysDir);
	END;

	FUNCTION hasExtFSVol (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasExtFSVol := BTST(volParms.vMAttrib, bHasExtFSVol);
	END;

	FUNCTION hasOpenDeny (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasOpenDeny := BTST(volParms.vMAttrib, bHasOpenDeny);
	END;

	FUNCTION hasCopyFile (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasCopyFile := BTST(volParms.vMAttrib, bHasCopyFile);
	END;

	FUNCTION hasMoveRename (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasMoveRename := BTST(volParms.vMAttrib, bHasMoveRename);
	END;

	FUNCTION hasDesktopMgr (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasDesktopMgr := BTST(volParms.vMAttrib, bHasDesktopMgr);
	END;

	FUNCTION hasShortName (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasShortName := BTST(volParms.vMAttrib, bHasShortName);
	END;

	FUNCTION hasFolderLock (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasFolderLock := BTST(volParms.vMAttrib, bHasFolderLock);
	END;

	FUNCTION hasPersonalAccessPrivileges (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasPersonalAccessPrivileges := BTST(volParms.vMAttrib, bHasPersonalAccessPrivileges);
	END;

	FUNCTION hasUserGroupList (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasUserGroupList := BTST(volParms.vMAttrib, bHasUserGroupList);
	END;

	FUNCTION hasCatSearch (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasCatSearch := BTST(volParms.vMAttrib, bHasCatSearch);
	END;

	FUNCTION hasFileIDs (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasFileIDs := BTST(volParms.vMAttrib, bHasFileIDs);
	END;

	FUNCTION hasBTreeMgr (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasBTreeMgr := BTST(volParms.vMAttrib, bHasBTreeMgr);
	END;

	FUNCTION hasBlankAccessPrivileges (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		hasBlankAccessPrivileges := BTST(volParms.vMAttrib, bHasBlankAccessPrivileges);
	END;

	FUNCTION supportsAsyncRequests (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		supportsAsyncRequests := BTST(volParms.vMAttrib, bSupportsAsyncRequests);
	END;

	FUNCTION supportsTrashVolumeCache (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		supportsTrashVolumeCache := BTST(volParms.vMAttrib, bSupportsTrashVolumeCache);
	END;

	FUNCTION volIsEjectable (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		volIsEjectable := BTST(GetVolParmsInfoExtendedAttributes(volParms), bIsEjectable);
	END;
	
	FUNCTION volSupportsHFSPlusAPIs (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		volSupportsHFSPlusAPIs := BTST(GetVolParmsInfoExtendedAttributes(volParms), bSupportsHFSPlusAPIs);
	END;
	
	FUNCTION volSupportsFSCatalogSearch (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		volSupportsFSCatalogSearch := BTST(GetVolParmsInfoExtendedAttributes(volParms), bSupportsFSCatalogSearch);
	END;
	
	FUNCTION volSupportsFSExchangeObjects (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		volSupportsFSExchangeObjects := BTST(GetVolParmsInfoExtendedAttributes(volParms), bSupportsFSExchangeObjects);
	END;
	
	FUNCTION volSupports2TBFiles (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		volSupports2TBFiles := BTST(GetVolParmsInfoExtendedAttributes(volParms), bSupports2TBFiles);
	END;
	
	FUNCTION volSupportsLongNames (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		volSupportsLongNames := BTST(GetVolParmsInfoExtendedAttributes(volParms), bSupportsLongNames);
	END;
	
	FUNCTION volSupportsMultiScriptNames (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		volSupportsMultiScriptNames := BTST(GetVolParmsInfoExtendedAttributes(volParms), bSupportsMultiScriptNames);
	END;
	
	FUNCTION volSupportsNamedForks (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		volSupportsNamedForks := BTST(GetVolParmsInfoExtendedAttributes(volParms), bSupportsNamedForks);
	END;
	
	FUNCTION volSupportsSubtreeIterators (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		volSupportsSubtreeIterators := BTST(GetVolParmsInfoExtendedAttributes(volParms), bSupportsSubtreeIterators);
	END;
	
	FUNCTION volL2PCanMapFileBlocks (VAR volParms: GetVolParmsInfoBuffer): Boolean;
	BEGIN
		volL2PCanMapFileBlocks := BTST(GetVolParmsInfoExtendedAttributes(volParms), bL2PCanMapFileBlocks);
	END;
	
	{	Functions for testing ioACUser bits.	}

	FUNCTION userIsOwner (ioACUser: SInt8): Boolean;
	BEGIN
		userIsOwner := NOT (BTST(ioACUser, kioACUserNotOwnerMask));
	END;

	FUNCTION userHasFullAccess (ioACUser: SInt8): Boolean;
	BEGIN
		userHasFullAccess := BAND(ioACUser, acUserAccessMask) = acUserFull;
	END;

	FUNCTION userHasDropBoxAccess (ioACUser: SInt8): Boolean;
	BEGIN
		userHasDropBoxAccess := BAND(ioACUser, acUserAccessMask) = acUserDropBox;
	END;

	FUNCTION userHasBulletinBoard (ioACUser: SInt8): Boolean;
	BEGIN
		userHasBulletinBoard := BAND(ioACUser, acUserAccessMask) = acUserBulletinBoard;
	END;

	FUNCTION userHasNoAccess (ioACUser: SInt8): Boolean;
	BEGIN
		userHasNoAccess := BAND(ioACUser, acUserAccessMask) = acUserNone;
	END;


END.