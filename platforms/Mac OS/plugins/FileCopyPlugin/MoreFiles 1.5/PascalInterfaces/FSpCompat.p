UNIT FSpCompat;

{	Apple Macintosh Developer Technical Support								}
{																			}
{	FSSpec compatibility functions											}
{																			}
{	by Jim Luther, Apple Developer Technical Support Emeritus				}
{																			}
{	File:		FSpCompat.p													}
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


	FUNCTION FSMakeFSSpecCompat (vRefNum: INTEGER;
									dirID: LONGINT;
									fileName: Str255;
									VAR spec: FSSpec): OSErr;

	FUNCTION FSpOpenDFCompat ({CONST}
									VAR spec: FSSpec;
									permission: SignedByte;
									VAR refNum: INTEGER): OSErr;

	FUNCTION FSpOpenRFCompat ({CONST}
									VAR spec: FSSpec;
									permission: SignedByte;
									VAR refNum: INTEGER): OSErr;

	FUNCTION FSpCreateCompat ({CONST}
									VAR spec: FSSpec;
									creator: OSType;
									fileType: OSType;
									scriptTag: ScriptCode): OSErr;

	FUNCTION FSpDirCreateCompat ({CONST}
									VAR spec: FSSpec;
									scriptTag: ScriptCode;
									VAR createdDirID: LONGINT): OSErr;

	FUNCTION FSpDeleteCompat ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION FSpGetFInfoCompat ({CONST}
									VAR spec: FSSpec;
									VAR fndrInfo: FInfo): OSErr;

	FUNCTION FSpSetFInfoCompat ({CONST}
									VAR spec: FSSpec;
									fndrInfo: FInfo): OSErr;

	FUNCTION FSpSetFLockCompat ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION FSpRstFLockCompat ({CONST}
									VAR spec: FSSpec): OSErr;

	FUNCTION FSpRenameCompat ({CONST}
									VAR spec: FSSpec;
									newName: Str255): OSErr;

	FUNCTION FSpCatMoveCompat ({CONST}
									VAR source: FSSpec;
									{CONST}
									VAR dest: FSSpec): OSErr;

	FUNCTION FSpExchangeFilesCompat ({CONST}
									VAR source: FSSpec;
									{CONST}
									VAR dest: FSSpec): OSErr;

	FUNCTION FSpOpenResFileCompat ({CONST}
									VAR spec: FSSpec;
									permission: SignedByte): INTEGER;

	PROCEDURE FSpCreateResFileCompat ({CONST}
									VAR spec: FSSpec;
									creator: OSType;
									fileType: OSType;
									scriptTag: ScriptCode);


{***************************************************************************}


IMPLEMENTATION

END.