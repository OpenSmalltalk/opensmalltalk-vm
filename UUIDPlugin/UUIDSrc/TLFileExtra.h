/*------------------------------------------------------------
| TLFileExtra.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to less commonly used file 
|          functions.
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
|          00.27.00 Split off from 'TLFile.h'.
------------------------------------------------------------*/
    
#ifndef _TLFILEEXTRA_H_
#define _TLFILEEXTRA_H_

#ifdef __cplusplus
extern "C"
{
#endif

#if macintosh

#ifndef FSSpec
#include <Files.h>
#endif

#endif // macintosh

#define MAX_DELIMITER_SIZE  80

s16     CloseFileLowLevel( s32, s32 );
void    ConvertEndOfLinesInTextFiles( s8*, s8*, u32 );
s32     CopyFileTL( s8*,s8* );
s32     CountDirectoryEntries( s8* );
s32     CountFiles( s8* );
s32     CountSubDirectories( s8* );
u32     CrcFile( FILE*, u32, u32 );
s16     CreateDirectoryTL( s8* );
void    CreateFileLowLevel( s8*, s32, s32 );
s16     CreateNestedDirectory( s8* );
s16     DeleteDirectory2( s8* );
s32     GetCreationDateOfIndexedVolume( s16 );
s32     GetDirectoryIDOfParentDirectory( s8* );
u32     GetDiskFreeSpaceTL( s8* );
u16     GetFileAttributesTL( s8* );
s8*     GetFileCreator( s8* );
//   u16       GetFileInfo( s8* );
#if macintosh
u32     GetFileSpecForPath( s8*, FSSpec* );
#endif
 
s8*     GetFileTypeTL( s8* );

#if macintosh
s8*     GetNameOfResource( s16, ResType, s16 );
Handle  GetNthResourceOfTypeFromFile( ResType, s16, s16 );
#endif

u32     GetVolumeFreeSpace( s16 );
u32     IsDirectory( s8* );
u32     IsFileType( s8*, s8* );
u32     IsMatchingFiles( s8*, s8* );
u32     IsResourceFileExisting( s8* );

#if macintosh
u32     IsResourceInFile( s16, ResType, s16 ); 
#endif
Item*   LoadFileToItem( s8* );
List*   MakeDirectoryEntryList( s8* );
List*   MakeDirectoryEntryPathList( s8* );
void    MakeFileListDocument( s8*, s8*, u32, s8* );
void    MeasureTextFileExtent( FILE*, u32*, u32* );
s32     MeasureTextLineSize( FILE* );
s32     MoveFileTL( s8*, s8* );
s32     MoveFilesFromFolderToFolder( s8*, s8* );
s32     MoveFilesToFolder( List*, s8* );
List*   MakeListOfPathsToFilesInDirectory( s8* );
s8*     NameOfNthDirectoryEntry( s8*, s32 );
s8*     NameOfNthFile( s8*, s32 );
s8*     NameOfNthSubDirectory( s8*, s32 );
s16     OpenFileLowLevel( s8*, s32, s32, s32 );
s32     ReadBytesLowLevel( s32, u8*, s32 );
f64     ReadNumber( FILE* );
void    SaveBytesToFileCompressed( s8*, u8*, u32 );
u32     SeekToDelimiter( FILE*, FILE*, u8*, u16 ); 
       
#if macintosh
void    SetFileCreator( s8*, s8* );
OSErr   SetFilePositionLowLevel( s32, u32 );
void    SetFileType( s8*, s8* );
#endif

#if macintosh
u16     WriteByteLowLevel( s32, u16 );
u32     WriteBytesLowLevel( s32, u8*, u32 );
#endif
u32     WriteNumber( FILE*, f64 );
u32     WriteNumberWithComment( FILE*, f64, s8* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _TLFILEEXTRA_H_
