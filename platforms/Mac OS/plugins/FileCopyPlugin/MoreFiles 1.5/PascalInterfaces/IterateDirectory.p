UNIT IterateDirectory;

{	IterateDirectory: File Manager directory iterator routines.				}
{																			}
{	by Jim Luther															}
{																			}
{	File:		IterateDirectory.p											}
{																			}
{	Copyright © 1996-1999 Jim Luther and Apple Computer, Inc.				}
{	All rights reserved.													}
{																			}
{	You may incorporate this sample code into your applications without		}
{	restriction, though the sample code has been provided "AS IS" and the	}
{	responsibility for its operation is 100% yours.							}
{																			}
{	IterateDirectory is designed to drop into the MoreFiles sample code		}
{	library I wrote while in Apple Developer Technical Support				}


INTERFACE

	USES
		Types, Files;

{***************************************************************************}


	TYPE
		IterateFilterProcPtr = ProcPtr;
{	A IterateDirectory IterateFilterProc procedure should have the			}
{	following form where the CInfoPBRec should be considered a CONST		}
{	(do not change it):														}
{																			}
{	PROCEDURE MyIterateFilterProcPtr (VAR cpbPtr: CInfoPBRec;				}
{									  VAR quitFlag: Boolean;				}
{									  yourDataPtr: Ptr);					}


{***************************************************************************}


	FUNCTION IterateDirectory (vRefNum: Integer;
									dirID: LongInt;
									name: StringPtr;
									maxLevels: Integer;
									iterateFilter: IterateFilterProcPtr;
									yourDataPtr: Ptr): OSErr;

	FUNCTION FSpIterateDirectory ({CONST}
									VAR spec: FSSpec;
									maxLevels: Integer;
									iterateFilter: IterateFilterProcPtr;
									yourDataPtr: Ptr): OSErr;


{***************************************************************************}


IMPLEMENTATION

END.