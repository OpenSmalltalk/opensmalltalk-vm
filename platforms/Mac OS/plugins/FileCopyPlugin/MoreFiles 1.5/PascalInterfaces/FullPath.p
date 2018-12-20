UNIT FullPath;

{	Apple Macintosh Developer Technical Support								}
{																			}
{	Routines for dealing with full pathnames... if you really must.			}
{																			}
{	by Jim Luther, Apple Developer Technical Support Emeritus				}
{																			}
{	File:		FullPath.p													}
{																			}
{	Copyright © 1995-1999 Apple Computer, Inc.								}
{	All rights reserved.													}
{																			}
{	You may incorporate this sample code into your applications without		}
{	restriction, though the sample code has been provided "AS IS" and the	}
{	responsibility for its operation is 100% yours.  However, what you are	}
{	not permitted to do is to redistribute the source as "DSC Sample Code"	}
{	after having made changes. If you're going to re-distribute the source,	}
{	we require that you make it clear in the source that the code was		}
{	descended from Apple Sample Code, but that you've made changes.			}


{	IMPORTANT NOTE:															}
{																			}
{	The use of full pathnames is strongly discouraged. Full pathnames are	}
{	particularly unreliable as a means of identifying files, directories	}
{	or volumes within your application, for two primary reasons:			}
{																			}
{	€ 	The user can change the name of any element in the path at			}
{		virtually any time.													}
{	€	Volume names on the Macintosh are *not* unique. Multiple			}
{		mounted volumes can have the same name. For this reason, the use of	}
{		a full pathname to identify a specific volume may not produce the	}
{		results you expect. If more than one volume has the same name and	}
{		a full pathname is used, the File Manager currently uses the first	}
{		mounted volume it finds with a matching name in the volume queue.	}
{																			}
{	In general, you should use a file¹s name, parent directory ID, and		}
{	volume reference number to identify a file you want to open, delete,	}
{	or otherwise manipulate.												}
{																			}
{	If you need to remember the location of a particular file across		}
{	subsequent system boots, use the Alias Manager to create an alias		}
{	record describing the file. If the Alias Manager is not available, you	}
{	can save the file¹s name, its parent directory ID, and the name of the	}
{	volume on which it¹s located. Although none of these methods is			}
{	foolproof, they are much more reliable than using full pathnames to		}
{	identify files.															}
{																			}
{	Nonetheless, it is sometimes useful to display a file¹s full pathname	}
{	to the user. For example, a backup utility might display a list of full	}
{	pathnames of files as it copies them onto the backup medium. Or, a		}
{	utility might want to display a dialog box showing the full pathname of	}
{	a file when it needs the user¹s confirmation to delete the file. No		}
{	matter how unreliable full pathnames may be from a file-specification	}
{	viewpoint, users understand them more readily than volume reference		}
{	numbers or directory IDs.												}
{																			}
{	The following technique for constructing the full pathname of a file is	}
{	intended for display purposes only. Applications that depend on any		}
{	particular structure of a full pathname are likely to fail on alternate	}
{	foreign file systems or under future system software versions.			}


INTERFACE

	USES
		Types, Files;

{***************************************************************************}


	FUNCTION GetFullPath (vRefNum: INTEGER;
									dirID: LONGINT;
									name: StringPtr;
									VAR fullPathLength: INTEGER;
									VAR fullPath: Handle): OSErr;

	FUNCTION FSpGetFullPath ({CONST}
									VAR spec: FSSpec;
									VAR fullPathLength: INTEGER;
									VAR fullPath: Handle): OSErr;

	FUNCTION FSpLocationFromFullPath (fullPathLength: INTEGER;
									fullPath: Ptr;
									VAR spec: FSSpec): OSErr;

	FUNCTION LocationFromFullPath (fullPathLength: INTEGER;
									fullPath: Ptr;
									VAR vRefNum: INTEGER;
									VAR parID: LONGINT;
									VAR name: Str31): OSErr;


{***************************************************************************}


IMPLEMENTATION

END.