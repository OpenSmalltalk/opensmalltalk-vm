UNIT MoreDesktopMgr;

{	Apple Macintosh Developer Technical Support								}
{																			}
{	A collection of useful high-level Desktop Manager routines.				}
{	If the Desktop Manager isn't available, use the Desktop file			}
{	for 'read' operations.													}
{																			}
{	We do more because we can...											}
{																			}
{	by Jim Luther and Nitin Ganatra,										}
{		Apple Developer Technical Support Emeriti							}
{																			}
{	File:		MoreDesktopMgr.p											}
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


	FUNCTION DTOpen (volName: StringPtr;
									vRefNum: Integer;
									VAR dtRefNum: Integer;
									VAR newDTDatabase: Boolean): OSErr;

	FUNCTION DTXGetAPPL (volName: StringPtr;
									vRefNum: Integer;
									creator: OSType;
									searchCatalog: Boolean;
									VAR applVRefNum: Integer;
									VAR applParID: LongInt;
									VAR applName: Str255): OSErr;

	FUNCTION FSpDTXGetAPPL (volName: StringPtr;
									vRefNum: Integer;
									creator: OSType;
									searchCatalog: Boolean;
									VAR spec: FSSpec): OSErr;

	FUNCTION DTGetAPPL (volName: StringPtr;
									vRefNum: Integer;
									creator: OSType;
									VAR applVRefNum: Integer;
									VAR applParID: LongInt;
									VAR applName: Str255): OSErr;

	FUNCTION FSpDTGetAPPL (volName: StringPtr;
									vRefNum: Integer;
									creator: OSType;
									VAR spec: FSSpec): OSErr;

	FUNCTION DTGetIcon (volName: StringPtr;
									vRefNum: Integer;
									iconType: Integer;
									fileCreator: OSType;
									fileType: OSType;
									VAR iconHandle: Handle): OSErr;

	FUNCTION DTSetComment (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									comment: Str255): OSErr;

	FUNCTION FSpDTSetComment ({CONST}
									VAR spec: FSSpec;
									comment: Str255): OSErr;

	FUNCTION DTGetComment (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									VAR comment: Str255): OSErr;

	FUNCTION FSpDTGetComment ({CONST}
									VAR spec: FSSpec;
									VAR comment: Str255): OSErr;

	FUNCTION DTCopyComment (srcVRefNum: Integer;
									srcDirID: LongInt;
									srcName: StringPtr;
									dstVRefNum: Integer;
									dstDirID: LongInt;
									dstName: StringPtr): OSErr;

	FUNCTION FSpDTCopyComment ({CONST}
									VAR srcSpec: FSSpec;
									{CONST}
									VAR dstSpec: FSSpec): OSErr;


{***************************************************************************}


IMPLEMENTATION

END.