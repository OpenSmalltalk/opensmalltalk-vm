/*------------------------------------------------------------
| FILE TLFile.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to file system.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 02.01.89 Created 
|          12.09.90 Mac version.
|          12.10.91 name changed from files.h to xfiles.h 
|                      due to collision.
|          02.03.93 from xfiles.h [217.1].
|          12.11.93 updated
|          08.02.98 Added conditional inclusion of 'Files.h'.
|          08.19.97 added C++ support.
|          12.29.98 Added Intel support.
|          01.27.00 Split off less commonly used functions
|                   to 'TLFileExtra.h'.
|          02.13.00 Inserted includes for Mac file types;
|                   added a couple of common functions for
|                   Mac.
------------------------------------------------------------*/
    
#ifndef TLFILE_H
#define TLFILE_H

#ifdef __cplusplus
extern "C"
{
#endif

#if macintosh

#include <Files.h>
#include <Errors.h> // For fnfErr.
#include <Processes.h>

#endif // macintosh


// File access codes 
#define ReadAccess      0
#define WriteAccess     1
#define ReadWriteAccess 2

#define    MaxPathLength   255   
           // longest path name that can be held at one time 
           // but possible to be longer than this in rare cases  
           // see Inside Mac IV p.99 

s16     CloseFile( FILE* );
void    ConvertFilePathToParentDirectory( s8* );
FILE*   CreateFileTL( s8* );
s16     DeleteFileTL( s8* );

#if macintosh
s8*     GetApplicationFilePath();
#endif

u32     GetFilePosition( FILE*);
u32     GetFileSize2( FILE*);
u32     GetFileSize3( s8* );
s8*     GetVolumeNameOfPath( s8* );
s16     GetVolumeReferenceNumberOfPath( s8* );
u32     IsFileExisting( s8* );
u32     IsPathsToSameVolume( s8*, s8* );
u32     IsPossibleToOpenFile( s8* );
void    LoadBytesFromFile( s8*, u8*, u32 );
u8*     LoadFile( s8* );
u8*     LoadFileToBuffer( s8*, u32* );
s8*     LocateFileNameInPathName( s8* );
s8*     LocateRootRelativePathNameInPathName( s8* );
void    MakeDirectoryPathEndInColon( s8* );

#if macintosh
OSErr   MakeFullPathGivenFSSpec( FSSpec*, s8* );
#endif

FILE*   OpenFileTL( s8*, u16);
s16     ReadByte( FILE* );
s32     ReadBytes( FILE*, u8*, u32 );
s16     ReadDOSTextLine( FILE*, s8* );
s16     ReadMacTextLine( FILE*, s8* ); 
u16     ReadString( FILE*, u8* ); 
u16     ReadStringAsText( FILE*, u8* ); 
s32     ReadTextLine( FILE*, s8* );
s32     ReadTextLineFromBuffer( s8**, s8*, s8* );
u32     ReadU32( FILE* );
s32     RenameFile( s8*, s8* );
FILE*   ReOpenFile( s8* );
void    SaveBytesToFile( s8*, u8*, u32 );
s32     SetFilePosition( FILE*, u32 );
void    ToBeginningOfFile( FILE*);
void    ToEndOfFile( FILE*);
u16     WriteByte( FILE*, u16);
u32     WriteBytes( FILE*, u8*, u32);
u32     WriteDOSTextLine( FILE*, s8* );
u32     WriteMacTextLine( FILE*, s8* );
u32     WriteString( FILE*, s8* );
u32     WriteStringAsText( FILE*, s8* );
u32     WriteTextLine( FILE*, s8*, s8* );
void    WriteU32( FILE*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLFILE_H
