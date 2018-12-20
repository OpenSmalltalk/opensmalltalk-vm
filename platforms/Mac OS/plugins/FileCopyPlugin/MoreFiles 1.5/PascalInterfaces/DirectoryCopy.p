UNIT DirectoryCopy;

{	Apple Macintosh Developer Technical Support								}
{																			}
{	DirectoryCopy: A robust, general purpose directory copy routine.		}
{	by Jim Luther, Apple Developer Technical Support Emeritus				}
{																			}
{	File:		DirectoryCopy.p												}
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

	{ DirectoryCopy failedOperation codes. }
	CONST
		getNextItemOp = 1;			{ couldn't access items in this }
									{ directory - no access privileges }
		copyDirCommentOp = 2;		{ couldn't copy directory's Finder }
									{ comment }
		copyDirAccessPrivsOp = 3;	{ couldn't copy directory's AFP access }
									{ privileges }
		copyDirFMAttributesOp = 4;	{ couldn't copy directory's File }
									{ Manager attributes }
		dirCreateOp = 5;			{ couldn't create destination directory }
		fileCopyOp = 6;				{ couldn't copy file }


{***************************************************************************}

	TYPE
		CopyErrProcPtr = ProcPtr;
{	A DirectoryCopy CopyErrProc function should have the following form:	}
{																			}
{	FUNCTION MyCopyErrProc (error: OSErr; 									}
{							failedOperation: Integer;						}
{							srcVRefNum: Integer;							}
{							srcDirID: LongInt;								}
{							srcName: StringPtr;								}
{							dstVRefNum: Integer;							}
{							dstDirID: LongInt;								}
{							dstName: StringPtr): Boolean;					}

		CopyFilterProcPtr = ProcPtr;
{	A DirectoryCopy CopyFilterProc function should have the following form:	}
{																			}
{	FUNCTION MyCopyFilterProc (cpbPtr: CInfoPBPtr): Boolean;				}

{***************************************************************************}


	FUNCTION FilteredDirectoryCopy (srcVRefNum: Integer;
									srcDirID: LongInt;
									srcName: StringPtr;
									dstVRefNum: Integer;
									dstDirID: LongInt;
									dstName: StringPtr;
									copyName: StringPtr;
									copyBufferPtr: Ptr;
									copyBufferSize: LongInt;
									preflight: Boolean;
									copyErrHandler: CopyErrProcPtr;
									copyFilterProc: CopyFilterProcPtr): OSErr;

	FUNCTION FSpFilteredDirectoryCopy ({CONST}
									VAR srcSpec: FSSpec;
									{CONST}
									VAR dstSpec: FSSpec;
									copyName: StringPtr;
									copyBufferPtr: Ptr;
									copyBufferSize: LongInt;
									preflight: Boolean;
									copyErrHandler: CopyErrProcPtr;
									copyFilterProc: CopyFilterProcPtr): OSErr;

	FUNCTION DirectoryCopy (srcVRefNum: Integer;
									srcDirID: LongInt;
									srcName: StringPtr;
									dstVRefNum: Integer;
									dstDirID: LongInt;
									dstName: StringPtr;
									copyName: StringPtr;
									copyBufferPtr: Ptr;
									copyBufferSize: LongInt;
									preflight: Boolean;
									copyErrHandler: CopyErrProcPtr): OSErr;

	FUNCTION FSpDirectoryCopy ({CONST}
									VAR srcSpec: FSSpec;
									{CONST}
									VAR dstSpec: FSSpec;
									copyName: StringPtr;
									copyBufferPtr: Ptr;
									copyBufferSize: LongInt;
									preflight: Boolean;
									copyErrHandler: CopyErrProcPtr): OSErr;


{***************************************************************************}


IMPLEMENTATION

END.