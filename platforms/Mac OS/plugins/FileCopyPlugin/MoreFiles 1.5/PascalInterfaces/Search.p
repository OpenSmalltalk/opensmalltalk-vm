UNIT Search;

{	Apple Macintosh Developer Technical Support								}
{																			}
{	IndexedSearch and the PBCatSearch compatibility function.				}
{	by Jim Luther, Apple Developer Technical Support Emeritus				}
{																			}
{	File:		Search.p													}
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


	FUNCTION IndexedSearch (pb: HParmBlkPtr;
									dirID: LongInt): OSErr;

	FUNCTION PBCatSearchSyncCompat (paramBlock: HParmBlkPtr): OSErr;

	FUNCTION NameFileSearch (volName: StringPtr;
									vRefNum: Integer;
									fileName: Str255;
									matches: FSSpecPtr;
									reqMatchCount: LongInt;
									VAR actMatchCount: LongInt;
									newSearch: Boolean;
									partial: Boolean): OSErr;

	FUNCTION CreatorTypeFileSearch (volName: StringPtr;
									vRefNum: Integer;
									creator: OSType;
									fileType: OSType;
									matches: FSSpecPtr;
									reqMatchCount: LongInt;
									VAR actMatchCount: LongInt;
									newSearch: Boolean): OSErr;


{***************************************************************************}


IMPLEMENTATION

END.