UNIT FileCopy;

{	Apple Macintosh Developer Technical Support								}
{																			}
{	FileCopy: A robust, general purpose file copy routine.					}
{	by Jim Luther, Apple Developer Technical Support Emeritus				}
{																			}
{	File:		FileCopy.p													}
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


	FUNCTION FileCopy (srcVRefNum: Integer;
									srcDirID: LongInt;
									srcName: Str255;
									dstVRefNum: Integer;
									dstDirID: LongInt;
									dstPathname: StringPtr;
									copyName: StringPtr;
									copyBufferPtr: Ptr;
									copyBufferSize: LongInt;
									preflight: Boolean): OSErr;

	FUNCTION FSpFileCopy ({CONST}
									VAR srcSpec: FSSpec;
									{CONST}
									VAR dstSpec: FSSpec;
									copyName: StringPtr;
									copyBufferPtr: Ptr;
									copyBufferSize: LongInt;
									preflight: Boolean): OSErr;


{***************************************************************************}

IMPLEMENTATION

END.