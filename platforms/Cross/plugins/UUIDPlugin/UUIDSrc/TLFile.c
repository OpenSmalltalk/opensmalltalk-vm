/*------------------------------------------------------------
| TLFile.c
|-------------------------------------------------------------
|
| PURPOSE: To provide commonly used file functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY:  02.01.89
|           03.22.89 added CreateFileTL
|           09.06.89 far buffer read/write potential added
|           12.09.90 Mac version.
|           02.03.93 from xfiles.c.
|           12.10.93 converted to ANSI C.
|           08.19.97 added C++ support.
|           12.30.98 Added Intel support.
|           01.27.00 Split off less commonly used functions to 
|                    a new file called 'TLFileExtra.c'.
------------------------------------------------------------*/

#include "TLTarget.h" 
    
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

#include "NumTypes.h"
#include "TLAscii.h"
#include "TLBytes.h"
#include "TLStrings.h"

#include "TLFile.h"

/*------------------------------------------------------------
| CloseFile
|-------------------------------------------------------------
|
| PURPOSE: To close a file.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: Returns 0 if sucessful, else returns an error code.
|
| ASSUMES: 
|
| HISTORY:  02.02.89
|           12.20.89 direct to DOS
|           12.09.90 mac version
------------------------------------------------------------*/
s16
CloseFile( FILE* F )
{
    return( (s16) fclose( F ) );     
}

/*------------------------------------------------------------
| ConvertFilePathToParentDirectory
|-------------------------------------------------------------
|
| PURPOSE: To convert a path to a file to the path of the
|          directory that contains the file.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
|  ConvertFilePathToParentDirectory( "My Disk:MyFile" );  
|  
|  result: "My Disk:"
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  08.30.97
------------------------------------------------------------*/
void
ConvertFilePathToParentDirectory( s8* PathToFile )
{
    s8* AtFile;
    
    AtFile = LocateFileNameInPathName( PathToFile );
    
    // Put a string terminator at the first character of the
    // file name.
    *AtFile = 0;
}
            
/*------------------------------------------------------------
| CreateFileTL
|-------------------------------------------------------------
|
| PURPOSE: To create and open a file for reading or writing.
|
| DESCRIPTION: Returns file handle of open file or 0 if error 
| occurred. If file already exists it is destroyed and 
| re-created with a zero file length.
|
| EXAMPLE:  
|
| NOTE: 
|
| WARNING: It's possible that attempting to OpenFileTL() that 
|          has just be CreateFileTL()d may result in allocation 
|          errors.
|
| ASSUMES: File should always be dealt with as binary.
|
| HISTORY:  03.22.89
|           12.20.89 direct to DOS
|           12.09.90 mac version.
|           12.12.93 changed "a+b" to "w+b".
|           06.07.96 added error trapping.
------------------------------------------------------------*/
FILE*
CreateFileTL( s8* FileName )
{
    FILE*   Result;
    
    // "w+b" means create a binary file for read/write.
    Result = fopen( (char*) FileName,"w+b" ); 
                            
    // Trap errors.
    if( Result == 0 )
    {
        Debugger();
    }

    return( Result );
}


/*------------------------------------------------------------
| DeleteFileTL
|-------------------------------------------------------------
|
| PURPOSE: To delete a file.
|
| DESCRIPTION: Returns error code:
|
|                               0 = no error
|                              -1 = error
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY:  11.22.89
|           12.21.89 direct to DOS
|           12.09.90 mac version
------------------------------------------------------------*/
s16
DeleteFileTL( s8* FileName )
{
   s16  Result;
   
   Result = (s16) remove( (char*) FileName );
   
   return( Result );
}

/*------------------------------------------------------------
| GetApplicationFilePath
|-------------------------------------------------------------
|
| PURPOSE: To get the path to the application file of the 
|          currently running process.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
|               p = GetApplicationFilePath();
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 08.30.97
|          08.28.98 Replaced call to 'FSpGetFullPath' with
|                   call to 'MakeFullPathGivenFSSpec'.
------------------------------------------------------------*/
#if macintosh
s8*
GetApplicationFilePath()
{
    static s8           Path[256];
    ProcessInfoRec      Info;
    ProcessSerialNumber PSN;
    FSSpec              spec;
    
    // Get the process serial number of the current process.
    GetCurrentProcess( &PSN );
    
    // Set up the Info structure before the call.
    Info.processAppSpec    = &spec;
    Info.processInfoLength = sizeof( ProcessInfoRec );
    Info.processName       = 0;
    
    // Get the information about the current process.
    GetProcessInformation( (const ProcessSerialNumber *) &PSN, &Info );
                           
    // Convert filespec to a full path. See 'FullPath.h' in
    // 'MoreFiles'.
    MakeFullPathGivenFSSpec( Info.processAppSpec, Path );
    
    // Return the path.
    return( Path );
}

#endif // macintosh

/*------------------------------------------------------------
| GetVolumeNameOfPath
|-------------------------------------------------------------
|
| PURPOSE: To return the volume name of a path.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
|       n = GetVolumeNameOfPath( "D:AFolder" );
|
| NOTE: 
|
| ASSUMES: Mac file path.
|           
| HISTORY:  12.29.96
------------------------------------------------------------*/
s8*
GetVolumeNameOfPath( s8* Path )
{
    static s8   VolumeName[40];
    s8* To;
    
    To = VolumeName;
    
    // Copy the path until a ':' or 0 is reached.
    while( *Path && *Path != ':' )
    {
        *To++ = *Path++;
    }
    
    // Add the string terminator.
    *To = 0;
    
    // Return the result.
    return( VolumeName );
}


/*------------------------------------------------------------
| GetFilePosition
|-------------------------------------------------------------
|
| PURPOSE: To return the current file position as an offset 
|          from the beginning of the file.
|
| DESCRIPTION: Returns -1L if an error occurred.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  11.8.89
|           12.20.89 converted to DOS
|           12.09.90 mac version
------------------------------------------------------------*/
u32
GetFilePosition( FILE* FileHandle )
{
    u32 CurrentPosition;

    CurrentPosition = (u32) ftell( FileHandle );

    return( CurrentPosition );
}

/*------------------------------------------------------------
| GetFileSize2
|-------------------------------------------------------------
|
| PURPOSE: To return the size of a given file in bytes.
|
| DESCRIPTION: Returns the number of bytes in the data fork.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.8.89
|          08.25.97 Name changed from 'GetFileSize' to
|                   avoid conflict with MoreFiles routine.
|          02.23.01 From TLFile.c. Revised to use stdio calls.
------------------------------------------------------------*/
u32
GetFileSize2( FILE* F )
{
    u32 EndPosition;
    u32 CurrentPosition;

    // Preserve the current file position.
    CurrentPosition = (u32) ftell( F );

    // Set the file position to the end of the file.
    fseek( F, 0L, 2);
    
    // Get the position of the file pointer at the end of
    // the file which is also the number of data bytes in
    // the file.
    EndPosition = (u32) ftell( F );

    // Restore original file position.
    fseek( F, (s32) CurrentPosition, 0 ); 
    
    // Return the number of bytes in the file.
    return( EndPosition );
}

/*------------------------------------------------------------
| GetFileSize3
|-------------------------------------------------------------
|
| PURPOSE: To return the size of a given file in bytes.
|
| DESCRIPTION: Returns the number of bytes in the data fork.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 09.02.97 from 'GetFileSize2'.
------------------------------------------------------------*/
u32
GetFileSize3( s8* Path )
{
    u32 ByteCount;
    FILE*   F;
    
    F = OpenFileTL( Path, ReadAccess );

    ByteCount = GetFileSize2( F );
    
    CloseFile( F );

    return( ByteCount );
}

/*------------------------------------------------------------
| GetVolumeReferenceNumberOfPath
|-------------------------------------------------------------
|
| PURPOSE: To return the volume reference number of a path.
|
| DESCRIPTION: A volume reference number is a small negative
|              integer.  Returns zero if not found.
|
| EXAMPLE:  
|
|       n = GetVolumeReferenceNumberOfPath( &v, "D:AFolder" );
|
| NOTE: 
|
| ASSUMES: The user has only one volume with the desired name,
|          although the OS allows any number.
|           
| HISTORY:  12.29.96
|           12.30.96 fixed error where 'VolumeParam' was used
|                    instead of 'HParamBlockRec' -- wild memory
|                    writes outside of the 'VolumeParam'
|                    caused errors.
|           09.28.97 Changed size of return value to 's16'
|                    from 's32'.
|           03.23.98 Now uses 'CopyCToPascalString'.
------------------------------------------------------------*/
#if macintosh

s16
GetVolumeReferenceNumberOfPath( s8* Path )
{
    HParamBlockRec  H;
    OSErr           err;
    s32             VolIndex;
    Str255          VolName;
    Str255          VolToMatch;
    
    // Convert the c string into a pascal string.
    CopyCToPascalString( 
        GetVolumeNameOfPath( Path ), 
        (s8*) VolToMatch );
    
    // Step through each volume looking for the first name
    // that matches.
    VolIndex = 1;
    
TryVol:

    H.volumeParam.ioCompletion = 0;
    H.volumeParam.ioNamePtr    = VolName;
    H.volumeParam.ioVRefNum    = 0;
    H.volumeParam.ioVolIndex   = VolIndex;
    
    err = PBHGetVInfoSync( &H );

    // If the end of the chain is reached before the volume
    // is found, return the error and a zero volume reference.
    if( err == nsvErr )
    {
        return( 0 );
    }
    else // Compare the names.
    {
        if( VolName[0] ==
            VolToMatch[0] &&
            ! CompareBytes( (u8*) &VolName[1], 
                            (u32) VolName[0],
                            (u8*) &VolToMatch[1],
                            (u32) VolName[0] ) )
        {
            // Return the volume reference number.
            return( H.volumeParam.ioVRefNum );
        }
    }
    
    // Try another one.
    VolIndex++;
    
    goto TryVol;
}

#endif // macintosh
    
/*------------------------------------------------------------
| IsFileExisting
|-------------------------------------------------------------
|
| PURPOSE: To tell if a file/directory is existing.
|
| DESCRIPTION: 
|
| EXAMPLE: a = IsFileExisting("TEST.SCR"); 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 03.22.89
|          04.04.91 changed to test for directories as well.
|          12.25.96 needed to add 'dirNFErr' test. Why I 
|                    don't know.
|          02.02.97 added explicit volume reference.
|          08.19.97 changed 'PBGetCatInfo' to 'PBGetCatInfoSync'
|                   which is the new convention.
|          03.23.98 Revised to use 'CopyCToPascalString'.
|          12.30.98 Copied DOS code from 'MINFILE.C'; added
|                   generic version.
------------------------------------------------------------*/
#if macintosh

u32
IsFileExisting( s8* Path )
{
    CInfoPBRec  C;
    OSErr       error;
    s16         VolRef;
    Str255      Path_PascalFormat;
    
    // Get the volume ref num of the path.
    VolRef = GetVolumeReferenceNumberOfPath( Path );
    
    // Convert the c string into a pascal string.
    CopyCToPascalString( Path, (s8*) Path_PascalFormat );
    
    C.dirInfo.ioFDirIndex = 0; // cause name to be used 
    C.dirInfo.ioVRefNum   = VolRef;  
    C.dirInfo.ioNamePtr   = Path_PascalFormat;
    
    error = PBGetCatInfoSync( &C );  
    
    if( error != fnfErr && error != dirNFErr ) 
    {
        return( 1 );
    }
    else
    {
        return( 0 );
    }
}

#else // macintosh

#ifdef MSDOS

u32
IsFileExisting( s8* Path )
{
    s16    ErrorCode;

    ErrorCode = GetFileAttributesTL( Path ) >> 8; 
   
    // No error or access denied or invalid function.
    if( ErrorCode == 0 || 
        ErrorCode == 5 || 
        ErrorCode == 1 ) 
    {
        return( 1 );
    }

    return( 0 );
}

#else // MSDOS

// For all non-Mac, non-DOS.
u32
IsFileExisting( s8* Path )
{
    FILE* F;

    // Try to open the file to read binary data.
    F = fopen( (char*) Path, "rb" );  

    // If the file can be opened for reading.
    if( F )
    {
        // Close the file.
        fclose( F );
        
        // Signal that the file exists.
        return( 1 );
    }
    else // File can't be open for reading.
    {
        // Regard all unreadable files as nonexistent.
        return( 0 );
    }
}

#endif // MSDOS

#endif // macintosh

/*------------------------------------------------------------
| IsPossibleToOpenFile
|-------------------------------------------------------------
|
| PURPOSE: To test if a file can be opened.
|
| DESCRIPTION: 
|
| EXAMPLE: a = IsPossibleToOpenFile("TEST.SCR"); 
|
| NOTE: This can be fairly slow because fopen may read in
|       file directory blocks in anticipation of reads.
|
| ASSUMES: 
|
| HISTORY: 05.27.97
------------------------------------------------------------*/
u32
IsPossibleToOpenFile( s8* Path )
{
    FILE* F;
    
    // Open the file with read/write access.
    
    F = fopen( (char*) Path,"r+b"); 
    
    // Then close the file.
    CloseFile( F );
    
    // If 'F' is non-zero then it is possible to open the 
    // file.
    if( F )
    {
        return( 1 );
    }
    else
    {
        return( 0 );
    }
}
 
/*------------------------------------------------------------
| IsPathsToSameVolume
|-------------------------------------------------------------
|
| PURPOSE: To test if two paths refer to the same volume.
|
| DESCRIPTION: Returns 1 if the two paths refer to the
| same volume.
|
| EXAMPLE:  
|
|       t = IsPathsToSameVolume( "D:AFolder", "D:BFolder" );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.22.97
------------------------------------------------------------*/
u32
IsPathsToSameVolume( s8* A, s8* B )
{
    s8  VolumeNameA[40];
    s8  VolumeNameB[40];

    CopyString( GetVolumeNameOfPath( A ), VolumeNameA );
    CopyString( GetVolumeNameOfPath( B ), VolumeNameB );

    return( IsMatchingStrings( VolumeNameA, VolumeNameB ) );
}

/*------------------------------------------------------------
| LoadBytesFromFile
|-------------------------------------------------------------
|
| PURPOSE: To load the first 'n' bytes from a file into a 
|          given buffer.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Destination buffer big enough.
|          File exists.
|
| HISTORY: 07.04.96 from 'LoadFile'.
------------------------------------------------------------*/
void
LoadBytesFromFile( s8* Path, u8* Buffer, u32 Count )
{
    FILE*   F;
    u32     BytesRead;
    
    // Make sure the file exists.
    if( IsFileExisting( Path) == 0 ) 
    {
        // File doesn't exist.
        Debugger(); // Trap errors.
        return;
    }
    
    F = OpenFileTL( Path, ReadAccess );
    
    // Read the file to the buffer.
    BytesRead = (u32) ReadBytes( F, Buffer, Count );
    
    // Make sure the exact amount was read.
    if( BytesRead != Count )
    {
        Debugger();
    }
    
    // Close the file.
    CloseFile(F);
}

/*------------------------------------------------------------
| LoadFile
|-------------------------------------------------------------
|
| PURPOSE: To load a file into a dynamically allocated buffer.
|
| DESCRIPTION: Returns the address of the buffer holding
| the file data or 0 if the file doesn't exist.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 06.06.96
|          08.25.97 changed 'GetFileSize' to 'GetFileSize2'.
------------------------------------------------------------*/
u8*
LoadFile( s8* Path )
{
    FILE*   F;
    u32     FileSize;
    u8*     FileBuffer;
    u32     BytesRead;
    
    // Make sure the file exists.
    if( IsFileExisting( Path) == 0 ) 
    {
        // File doesn't exist.
        return( 0 );
    }
    
    F = OpenFileTL( Path, ReadAccess );
    
    FileSize = GetFileSize2( F );
 
    // Allocate the buffer for the file.
    FileBuffer = (u8*) malloc( FileSize );
    
    // Read the file to the buffer.
    BytesRead = (u32) 
        ReadBytes( F, FileBuffer, FileSize );
    
    // Make sure the exact file size was read.
    if( BytesRead != FileSize )
    {
        Debugger();
    }
    
    // Close the file.
    CloseFile(F);
    
    // Return the buffer.
    return( FileBuffer );
}

/*------------------------------------------------------------
| LoadFileToBuffer
|-------------------------------------------------------------
|
| PURPOSE: To load a file into a dynamically allocated buffer.
|
| DESCRIPTION: Makes a literal copy of the file data in a
| dynamically allocated buffer that is the same size as the
| data in the file.
|
| Returns the address of the buffer holding the file data or 
| 0 if the file contains no data or if the entire file could
| not be loaded. 
|
| The buffer is allocated using malloc() so it should be 
| freed using free().
|
| EXAMPLE:  
|
| ASSUMES: 
|
| HISTORY: 06.06.96
|          08.25.97 changed 'GetFileSize' to 'GetFileSize2'.
|          02.25.01 From TLFile.c; added DataSize parameter.
------------------------------------------------------------*/
            // OUT: Address of buffer holding the data or
u8*         //      zero if could not load data.
LoadFileToBuffer( 
    s8*  Path, 
            // IN: Path to the file to be loaded.
            //
    u32* DataSize )
            // OUT: Returns the size of the data loaded from
            //      the file.
{
    FILE*   F;
    u8*     DataBuffer;
    u32     BytesRead;
    u32     FileSize;
    
    // Start with no data buffer allocated.
    DataBuffer = 0;
    
    // Start with no bytes read.
    BytesRead = 0;
    
    // Open the input file to be read in as a literal binary 
    // image to avoid any interference from the i/o library
    // -- this is needed so that the file size corresponds 
    // with the number of bytes returned by fread.
    F = fopen( Path, "rb" );
    
    // If unable to open the file.
    if( F == 0 )
    {
        // Print a warning.
        printf( "Unable to open file \"%s\".\n", Path );
                
        // Return zero for the data buffer address and size.
        goto Finish;
    }
    
    // Get the size of the data in the file.
    FileSize = GetFileSize2( F );
    
    // If there is data in the file.
    if( FileSize )
    {
        // Allocate a buffer to hold the data.
        DataBuffer = malloc( FileSize );
    
        // If the data buffer was allocated.
        if( DataBuffer )
        {
            // Read the data into the buffer.
            BytesRead = fread( DataBuffer, 1, FileSize, F );
            
            // If the number of bytes read differs from
            // the file size.
            if( BytesRead != FileSize )
            {
                // Deallocate the buffer.
                free( DataBuffer );
                
                // Mark the buffer as missing.
                DataBuffer = 0;
                
                // Clear the bytes read.
                BytesRead = 0;
                
                // Report the error.
                printf( "Unable to read data from file \"%s\".\n", 
                        Path );
            }
        }
        else // Can't allocate a buffer.
        {
            // Print a warning.
            printf( "Unable to allocate buffer for"
                    " loading file \"%s\".\n", Path );
        }
    }
     
    // Close the input file.
    fclose( F );

/////////
Finish://
/////////

    // Return the size of the data in the buffer.
    *DataSize = BytesRead;

    // Return the address of the buffer.
    return( DataBuffer );
}

/*------------------------------------------------------------
| LocateFileNameInPathName
|-------------------------------------------------------------
|
| PURPOSE: To find the beginning of the file name in a path 
|          name.
|
| DESCRIPTION: Returns true if is a directory
|
| EXAMPLE: 
|
|  on IBM:   
|         FileName = 
|            LocateFileNameInPathName("C:\MYDIR\MYFILE.TXT");   
|                       returns address of "MYFILE.TXT"
|
|  on MAC:   
|         FileName = 
|            LocateFileNameInPathName("My Disk:MyFile");  
|                       returns "MyFile"
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  01.31.89
|           12.09.90 mac version
------------------------------------------------------------*/
s8*
LocateFileNameInPathName(s8* APathName)
{
    s8* CharPointer;

    CharPointer = APathName;

    while (*CharPointer != '\0')
    {
        ++CharPointer;
    }

    while (
            (CharPointer != APathName) &&
            (CharPointer[-1] != ':')
          )
    {
        --CharPointer;
    }
    return (CharPointer);
}

/*------------------------------------------------------------
| LocateRootRelativePathNameInAPathName
|-------------------------------------------------------------
|
| PURPOSE: To find the beginning of the root-relative path 
|          name in a path name.
|
| DESCRIPTION: Returns true if is a directory
|
| EXAMPLE: use like this:  
|
|  on IBM:   PathName = 
|            LocateRootRelativePathNameInPathName("C:\MYDIR\MYFILE.TXT");   
|              returns address of "MYDIR\MYFILE.TXT"
|
|  on MAC:   
|         FileName = 
|            LocateFileNameInPathName("My Disk:MyFile");  
|                       returns "MyFile"
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  11.27.89
------------------------------------------------------------*/
s8*
LocateRootRelativePathNameInPathName(s8* APathName)
{
    s8* CharPointer;

    CharPointer = APathName;

    while(*CharPointer != '\0' && *CharPointer != ':')
    {
        ++CharPointer;
    }

    if( *CharPointer == '\0' )
    {
        CharPointer = APathName;
    }
    else
    {
        CharPointer++;   /* point one s8 past ':' */
    }

    if( *CharPointer == '\\' ) /* ??? */
    {
        CharPointer++;
    }

    return(CharPointer);
}

/*------------------------------------------------------------
| MakeDirectoryPathEndInColon
|-------------------------------------------------------------
|
| PURPOSE: To append a ':' character to a directory path if
|          the path doesn't end in a ':' already.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
|       MakeDirectoryPathEndInColon( DirPathBuffer );
|
| NOTE: 
|
| ASSUMES: Path buffer has room if the colon is missing.
|
|          Mac file path.
|
| HISTORY: 08.25.97 
------------------------------------------------------------*/
void
MakeDirectoryPathEndInColon( s8* Path )
{
    s8* A;
    
    A = Path;
    
    // Find the terminal.
    while( *A )
    {
        A++;
    }
    
    // Back up one byte.
    A--;
    
    // If the byte is ':'.
    if( *A == ':' )
    {
        return;
    }
    else // Missing ':'.
    {
        // Append a ':'.
        A++;
        
        *A++ = ':';
        
        *A = 0;
    }
}

/*------------------------------------------------------------
| MakeFullPathGivenFSSpec
|-------------------------------------------------------------
|
| PURPOSE: To make a path string that refers to a file,
|          directory or volume specified by an FSSpec.
|
| DESCRIPTION: Returns path in C-string format.
|
| EXAMPLE:  
|
|       p = MakeFullPathGivenFSSpec( F, APath );
|
| NOTE: 
|
| ASSUMES: Enough room for the result at 'FullPath'.
|           
| HISTORY: 08.28.98 From 'FSpGetFullPath()'.
------------------------------------------------------------*/
#if macintosh

OSErr   
MakeFullPathGivenFSSpec( FSSpec* F, s8* FullPath )
{
    OSErr       result;
    FSSpec      T;
    CInfoPBRec  pb;
    s32         i;
    
    s8          Names[1024];        // Buffer to hold object names.
    s32         N;                  // How many names are in 'Names'.
    s8*         NameAddress[100];   // Where each name begins in 'Names'.
    s32         NameLength[100];    // How many character bytes are in each name.
    
    // Default to no path.
    *FullPath = 0;
    
    // If the parent ID is root.
    if( F->parID == fsRtParID )
    {
        // The object is a volume.
        
        // Get the byte count of the name in the given file spec.
        i = (s32) F->name[0];
    
        // Copy the name to the result buffer.
        CopyBytes( (u8*) &F->name[1], (u8*) FullPath, i );
        
        // Add a colon to make it a full pathname.
        FullPath[ i ] = ':';
        
        // Add terminating zero.
        FullPath[ i + 1 ] = 0;
         
        // Return successfully.
        return( noErr );
    }
    
    // The object isn't a volume.

    // Make a copy of the input FSSpec that can be modified.
    CopyBytes( (u8*) F, (u8*) &T, sizeof(FSSpec) );
    
    // Get the object type information to determine whether the 
    // object is a file or a directory.
    pb.dirInfo.ioNamePtr = T.name;
    pb.dirInfo.ioVRefNum = T.vRefNum;
    pb.dirInfo.ioDrDirID = T.parID;
    pb.dirInfo.ioFDirIndex = 0;
    result = PBGetCatInfoSync(&pb);
    
    // If an error occurred when reading the disk catalog.
    if( result != noErr )
    {
        return( result );
    }

    // if the object is a directory.
    if( (pb.hFileInfo.ioFlAttrib & ioDirMask) != 0 )
    {
        // Append a colon so the full pathname ends with colon.
        ++T.name[0];
        T.name[T.name[0]] = ':';
    }
        
    // Put the object name in the name buffer.
    NameAddress[0] = Names;
    NameLength[0]  = T.name[0];
    CopyBytes( (u8*) &T.name[1], (u8*) Names, T.name[0] );
    N = 1;
    
    // Get the superior directory names.
    pb.dirInfo.ioNamePtr = T.name;
    pb.dirInfo.ioVRefNum = T.vRefNum;
    pb.dirInfo.ioDrParID = T.parID;
        
    // For each superior of the object.
GetSuperior:

    pb.dirInfo.ioFDirIndex = -1;
    pb.dirInfo.ioDrDirID = pb.dirInfo.ioDrParID;
    result = PBGetCatInfoSync(&pb);
        
    // If an error occurred when reading the disk catalog.
    if( result != noErr )
    {
        return( result );
    }

    // Append colon to directory name.
    ++T.name[0];
    T.name[T.name[0]] = ':';
    
    // Calculate a place for the directory name in the name buffer.
    NameAddress[N] = NameAddress[ N - 1 ] + NameLength[ N - 1 ];
                             
    // Save the length of the name.                         
    NameLength[N] = T.name[0];
    
    // Copy the directory name to the name buffer.
    CopyBytes( (u8*) &T.name[1], (u8*) NameAddress[N], T.name[0] );
    
    // Account for the new name.
    N++;
    
    // If there is a superior.
    if( pb.dirInfo.ioDrDirID != fsRtDirID )
    {
        // Get the next higher superior.
        goto GetSuperior;
    }
            
    // Construct the path name from the name buffer.
    for( i = N - 1; i >= 0; i-- )
    {
        // Copy the name to the result buffer.
        CopyBytes( (u8*) NameAddress[i], (u8*) FullPath, NameLength[i] );
        
        // Advance the target address.
        FullPath += NameLength[i];
    }
    
    // Append the string terminator.
    *FullPath = 0;  

    // Return successfully.
    return( noErr );
}

#endif // macintosh

/*------------------------------------------------------------
| OpenFileTL
|-------------------------------------------------------------
|
| PURPOSE: To open a file for reading or writing.
|
| DESCRIPTION:  
|
|        AccessMode byte encoding:   
|
|          76543210
|          .....000    Read  access
|          .....001    Write access
|          .....010    Read/Write access
|          ....x...    Reserved
|          .000....    Sharing mode - compatibility mode
|          .001....    Sharing mode - read/write access denied
|          .010....    Sharing mode - write access denied
|          .011....    Sharing mode - read access denied
|          .100....    Sharing mode - full access permitted
|          0.......    Inherited by child processes
|          1.......    Private to current process
|
| EXAMPLE: 
|
| NOTE: See page 592 of "DOS Programmers Reference, 2nd Ed".
|
| ASSUMES: The existence of the file.
|
| HISTORY: 02.02.89
|          03.22.89 added error check
|          09.15.89 added far file name capability
|          12.20.89 added access mode, direct to DOS call
|          12.09.90 mac version ignores bits 3-7 for now
|          06.07.96 added error trapping.
|          01.07.99 Name changed from 'OpenFile()' to 
|                   avoid name collision with NT procedure.
------------------------------------------------------------*/
FILE*
OpenFileTL( s8* FileName, u16 AccessMode )
{
    FILE*   FilePointer;

    // Strip off DOS specific attributes: add sharing mode
    // support for Mac and DOS later as needed.
    AccessMode &= 7; 
    
    if( AccessMode == ReadWriteAccess )
    {
        // Read or write binary data.
        FilePointer = fopen( (char*) FileName,"r+b" ); 
    }
    else if( AccessMode == ReadAccess )
    {
        // read binary data.
        FilePointer = fopen( (char*) FileName,"rb");  
    }
    else if(AccessMode == WriteAccess)
    {
        // Write binary data.
        FilePointer = fopen( (char*) FileName,"wb"); 
    }
    
    // Trap errors.
    if( FilePointer == 0 )
    {
        Debugger();
    }

    return( FilePointer );
}

/*------------------------------------------------------------
| ReadByte
|-------------------------------------------------------------
|
| PURPOSE: To a read byte from a file and advance the file 
|          pointer.
|
| DESCRIPTION: Returns a signed word with the byte read as the 
|              low byte. If read error or EOF, -1 is returned.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY:  02.02.89
|           12.21.89 revised to pass error code
------------------------------------------------------------*/
s16
ReadByte(FILE* FileHandle)
{
   u8    ByteBuffer;
   s16   Result;

   Result = (s16)
        ReadBytes(FileHandle, (u8*) &ByteBuffer, 1 );

   if( Result == 1 )
   {
       Result = ByteBuffer;
   }
   else
   {
       Result = -1;
   }

    return( Result );
}

/*------------------------------------------------------------
| ReadBytes
|-------------------------------------------------------------
|
| PURPOSE: To read bytes from a file to a buffer.
|
| DESCRIPTION: Returns number of bytes read or -1 if error or 
|              EOF.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.12.89
|          09.06.89 enable buffer to be in far segment
|          09.18.89 added number of Bytes read
|          12.20.89 direct to DOS call
|          12.21.89 made EOF conditions less ambiguous
|          12.09.90 mac version
|                   ByteCount type changed to s16 to 
|                   match result value type.
|          06.06.96 ByteCount type changed to s32 to support
|                   larger files loaded as a unit.
------------------------------------------------------------*/
s32
ReadBytes( FILE*  FileHandle,
           u8*    BufferPointer,
           u32    ByteCount )
{
    s32 Result;
    
    Result = (s32) 
             fread( BufferPointer,                                  
                    1,
                    (u32) ByteCount,
                    FileHandle );
            
   if( Result == 0 )
   {
       // Bytes were requested to be read, 
       // but none were... EOF assumed.
       Result = -1;
   }

   return( (s32) Result );
}

/*------------------------------------------------------------
| ReadDOSTextLine
|-------------------------------------------------------------
|
| PURPOSE: To read a line of text from a DOS text file.
|
| DESCRIPTION: 1. Reads bytes up to and including the next 
|                 LineFeed (0x0a) byte into the buffer.
|              2. The CarriageReturn:LineFeed characters, if 
|                 present, are dropped.
|              3. Returns the length of the string without 
|                 the delimiting 0 or -1 if EOF & nothing 
|                 read. Empty lines return 0.
|              4. Treats ControlZ as an end-of-file marker.
|
| ASSUMES: Line fits within the given buffer and is
|          less than 32K bytes long.
|
| HISTORY: 05.17.91 TL
|          12.12.93 simplified logic
|          03.06.94 IBM version
|          12.30.98 From 'MINFILE.C'.
------------------------------------------------------------*/
s16
ReadDOSTextLine( FILE* AFile, s8* ABuffer )
{
    s16 ByteBuffer;
    s16 ByteCount;
    
    ByteCount = 0;
    
Loop:
    
    ByteBuffer = ReadByte(AFile);
    
    // End-of-file.
    if( ByteBuffer == -1 || 
        ByteBuffer == ControlZ ) goto AfterLoop;
    
    // Ignore CarriageReturns.
    if( ByteBuffer == CarriageReturn ) goto Loop;

    // End-of-line.
    if( ByteBuffer == LineFeed ) goto AfterLoop;

    *ABuffer++ = (s8) ByteBuffer;

    ByteCount++;
 
    goto Loop;
    
AfterLoop:
    
    // Mark end of string.
    *ABuffer = 0; 

    // If no bytes read at all before end-of-file.
    if( ByteBuffer == -1 && ByteCount == 0 ) ByteCount = -1;
    
    return( ByteCount );
}

/*------------------------------------------------------------
| ReadMacTextLine
|-------------------------------------------------------------
|
| PURPOSE: To read a line of text from a Macintosh file.
|
| DESCRIPTION: 1. Reads bytes up to and including the next 
|                 CarriageReturn (0x0d) byte into the buffer.
|              2. The CarriageReturn (0x0d) character, if 
|                 present, is dropped.
|              3. Returns the length of the string without 
|                 the delimiting 0 or -1 if EOF & nothing 
|                 read. Empty lines return 0.
|
| EXAMPLE: 
|
| NOTE: no special treatment of end of file marker, 0x1a.
|
| ASSUMES: Line fits within the given buffer and is
|          less than 32K bytes long.
|
| HISTORY: 05.17.91
|          12.12.93 simplified logic
|          07.31.95 added LineFeed.
------------------------------------------------------------*/
s16
ReadMacTextLine( FILE*   AFile, s8* ABuffer )
{
    s16 ByteBuffer;
    s16 ByteCount;
    
    ByteCount = 0;
    
Loop:
    
    ByteBuffer = ReadByte(AFile);
    
    // End-of-file.
    if( ByteBuffer == -1 ) goto AfterLoop ;
    
    // End-of-line.
    if( ByteBuffer == CarriageReturn ||
        ByteBuffer == LineFeed ) 
    {
        goto AfterLoop ;
    }

    *ABuffer++ = (s8) ByteBuffer;

    ByteCount++;
 
    goto Loop;
    
AfterLoop:
    
    *ABuffer = 0; // Mark end of string.

    // If no bytes read at all before end-of-file.
    if( ByteBuffer == -1 && ByteCount == 0 ) ByteCount = -1;
    
    return( ByteCount );
}

/*------------------------------------------------------------
| ReadString
|-------------------------------------------------------------
|
| PURPOSE: To read a string from a file to a buffer.
|
| DESCRIPTION: 1. Reads Bytes up to and including the next 
|                 LineFeed (0A) u8 into the buffer.
|              2. A 0 u8 is appended after the linefeed byte 
|                 in the buffer.
|              3. Returns the length of the string without the 
|                 delimiting 0.
|              4. Returns 0 for EOF or if an error occured.
|
| EXAMPLE: 
|
| NOTE: no special treatment of end of file marker, 0x1a.
|
| ASSUMES: 
|
| HISTORY:  09.18.89
------------------------------------------------------------*/
u16
ReadString( FILE* FileHandle, u8* ABuffer )
{
    s16 ByteBuffer;
    u16 ByteCount;
    
    ByteCount = 0;
    
    while( (ByteBuffer = ReadByte(FileHandle)) != -1 ) 
    {
        ByteCount++;

        *ABuffer++ = (u8) ByteBuffer;

        if( ByteBuffer == LineFeed ) 
        {
            break; 
        }
    }

    *ABuffer = 0;

    return( ByteCount );
}

/*------------------------------------------------------------
| ReadStringAsText
|-------------------------------------------------------------
|
| PURPOSE: To read a string from a file replacing 
|          CarriageReturn:LineFeed pairs (0x0d,0x0a) with 
|          LineFeeds(0x0a).
|
| DESCRIPTION: 
|
| 1. Reads Bytes up to and including the next LineFeed (0A) 
|    byte into the buffer.
| 2. If a CarriageReturn preceeds the LineFeed it is removed.
| 3. A 0 u8 is appended after the linefeed byte in the 
|    buffer.
| 4. Returns the length of the string without the delimiting 
|    0.
| 5. If a Control Z is encountered, end-of-file is assumed.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  09.18.89
|           12.22.89 added check for bytes read before EOS 
|                    appended.
------------------------------------------------------------*/
u16
ReadStringAsText( FILE* FileHandle, 
                  u8* ABuffer )
{
    s16 ByteBuffer;
    u16 ByteCount;

    ByteCount = 0;
    
    while( (ByteBuffer = ReadByte(FileHandle)) != -1 ) 
    {
        if( ByteBuffer == ControlZ ) break;

        ByteCount++;

        *ABuffer++ = (u8) ByteBuffer;

        if( ByteBuffer == LineFeed ) break; 
    }

    if( (ByteCount) && 
        (*(ABuffer - 2) == CarriageReturn) && 
        (*(ABuffer - 1) == LineFeed) )
    {
        *(ABuffer - 2) = LineFeed;
        ABuffer--;
        ByteCount--;
    }

    if( ByteCount ) /* only append EOS marker 
                     * if a string was read 
                     */
    {
       *ABuffer = 0;    
    }

    return( ByteCount );
}

/*------------------------------------------------------------
| ReadTextLine
|-------------------------------------------------------------
|
| PURPOSE: To read a line of text from a DOS, Mac or Unix  
|          file.
|
| DESCRIPTION: Reads the next line as a string without the 
| end of line sequence.
|
| Returns the number of bytes in the line read, not counting
| the zero-terminator.
|
| If the line is empty then 0 is returned.
|
| If end-of-file is reached then -1 is returned.
|
| If a Control Z character is encountered it is treated as
| an end-of-file marker.
|
| EXAMPLE:    Count = ReadTextLine( F, MyBuffer );
|
| ASSUMES: Line fits within the given buffer.
|
| HISTORY: 07.09.97 from 'ReadMacTextLine'.
|          07.15.97 added ability to terminate lines with
|                   LineFeed.
|          02.08.01 Added Unix text line and converted
|                   ReadByte to fgetc.
------------------------------------------------------------*/
s32
ReadTextLine( FILE* AFile, s8* ABuffer )
{
    s32 ByteBuffer;
    s32 ByteCount;
    
    ByteCount = 0;

///////////////
ReadNextByte://
///////////////
    
    // Read the next byte from the file.
    ByteBuffer = fgetc( AFile );
    
    // If an end-of-file has been encountered...
    if( ByteBuffer == EOF || ByteBuffer == ControlZ )
    {
        // ...then finish up.
        goto Finish;
    }

    // If this is a CarriageReturn...
    if( ByteBuffer == CarriageReturn )
    {
        // ...then look for a following LineFeed.
    
        // Read the next byte.
        ByteBuffer = fgetc( AFile );
        
        // If the next byte isn't a line feed... 
        if( ByteBuffer != LineFeed )
        {
            // ...put it back.
            ungetc( ByteBuffer, AFile );
            
            // Revert to the carriage return just read.
            ByteBuffer = CarriageReturn;
        }
    }
        
    // If an end-of-line sequence has been found...
    if( ByteBuffer == CarriageReturn ||
        ByteBuffer == LineFeed )
    {
        // ...then finish up.
        goto Finish;
    }

    // Accumulate the byte to the line buffer.
    *ABuffer++ = (s8) ByteBuffer;

    // Count the byte.
    ByteCount++;
    
    // Go read the next byte.
    goto ReadNextByte;

/////////   
Finish://
/////////   
    
    // Mark end of string.
    *ABuffer = 0; 

    // If no bytes read at all before end-of-file.
    if( ByteBuffer == EOF && ByteCount == 0 ) 
    {
        // Set byte count to -1 to signal end-of-file.
        ByteCount = -1;
    }
    
    // Return the number of bytes returned.
    return( ByteCount );
}

/*------------------------------------------------------------
| ReadTextLineFromBuffer
|-------------------------------------------------------------
|
| PURPOSE: To read a line of text from a buffer holding the
|          contents of a DOS, Mac or Unix file.
|
| DESCRIPTION: Reads the next line as a string without the 
| end-of-line sequence.
|
| Returns the number of bytes in the line read, not counting
| the string's zero-terminator.
|
| If the line is empty then 0 is returned.
|
| If end-of-data is reached and no data is read then -1 is 
| returned.
|
| If a Control-Z character is encountered it is treated as
| an end-of-data marker.
|
| EXAMPLE:    
|
|    Count = ReadTextLineFromBuffer( AtLine, AtEnd, MyBuffer );
|
| ASSUMES: Line fits with in the destination buffer.
|
|          The buffer was filled by reading a file opened
|          as "rb" for read binary as opposed to "r" read
|          text -- the read-text mode may strip out characters.
|
| HISTORY: 07.09.97 from 'ReadMacTextLine'.
|          07.15.97 added ability to terminate lines with
|                   LineFeed.
|          02.08.01 Added Unix text line and converted
|                   ReadByte to fgetc.
|          02.23.01 Revised to read a text line from a buffer
|                   rather than directly from a file.
------------------------------------------------------------*/
        // OUT: Number of bytes read, without end-of-line
        //      or terminal zero.
        //
        //      This value is -1 if there is no data left
s32     //      to be read.
ReadTextLineFromBuffer( 
    s8** InputBuffer,
        // IN/OUT: Address of the next byte to be read as 
        //         input data.  This value is updated.
        //
    s8* AtEndOfData,
        // IN: Address of the first byte after the last data
        //     byte in the buffer.
        //
    s8* OutputBuffer )
        // OUT: The line of text read from the input buffer
        //      will be written to this output buffer as a
        //      string without end-of-line sequence but with
        //      a zero-terminator.
{
    s8  ByteBuffer;
    s32 ByteCount;
    s8* In;
    u8  IsEndOfData;
    
    // Start with no bytes read.
    ByteCount = 0;
    
    // Start with end-of-data flag defaulting to false.
    IsEndOfData = 0;
    
    // Get a local copy of the input buffer pointer.
    In = *InputBuffer;

    // While the line remains to be read.
    while(1)
    {
        // If the end-of-data has been reached.
        if( In >= AtEndOfData )
        {
            // Signal end-of-data condition.
            IsEndOfData = 1;
            
            // Then finish up.
            goto Finish;
        }
      
        // Read the next byte from the input buffer.
        ByteBuffer = *In++;
        
        // If an end-of-data marker byte has been encountered.
        if( ByteBuffer == ControlZ )
        {
            // Signal end-of-data condition.
            IsEndOfData = 1;
            
            // Then finish up.
            goto Finish;
        }

        // If this is a CarriageReturn.
        if( ByteBuffer == CarriageReturn )
        {
            // If the end-of-data has been reached.
            if( In >= AtEndOfData )
            {
                // Signal end-of-data condition.
                IsEndOfData = 1;
                
                // Then finish up.
                goto Finish;
            }
      
            // Look for a following LineFeed.
        
            // Read the next byte.
            ByteBuffer = *In++;
            
            // If the next byte isn't a line feed... 
            if( ByteBuffer != LineFeed )
            {
                // ...put it back.
                In--;
                
                // Revert to the carriage return just read.
                ByteBuffer = CarriageReturn;
            }
        }
            
        // If an end-of-line sequence has been found.
        if( ByteBuffer == CarriageReturn ||
            ByteBuffer == LineFeed )
        {
            // Then finish up.
            goto Finish;
        }
        else // The byte read is not an end-of-line delimiter.
        {
            // Accumulate the byte to the output buffer.
            *OutputBuffer++ = (s8) ByteBuffer;

            // Count the byte as added to the output buffer.
            ByteCount++;
        }
    }

/////////   
Finish://
/////////   
    
    // Mark end of the line string.
    *OutputBuffer = 0; 

    // Update the input buffer pointer.
    *InputBuffer = In;
    
    // If there are no byte in the output buffer and an
    // end-of-data condition exists.
    if( ByteCount == 0 && IsEndOfData ) 
    {
        // Set byte count to -1 to signal end-of-data and
        // no output bytes.
        ByteCount = -1;
    }
    
    // Return the number of bytes in the output buffer.
    return( ByteCount );
}

/*------------------------------------------------------------
| ReadU32
|-------------------------------------------------------------
|
| PURPOSE: To read a u32 from a file in LSB-first order.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: The u32 can be read.
|
| HISTORY: 01.22.99 From 'WriteU32()'.
------------------------------------------------------------*/
u32 
ReadU32( FILE* F )
{
    u8  b[4];
    u32 x;
    
    // Read the bytes from the file.
    ReadBytes( F, b, 4 );
    
    // Assemble the result.
    x =  b[3]; x <<= 8;
    x |= b[2]; x <<= 8;
    x |= b[1]; x <<= 8;
    x |= b[0];
    
    // Return the result.
    return( x );
}

/*------------------------------------------------------------
| RenameFile
|-------------------------------------------------------------
|
| PURPOSE: To rename a file.
|
| DESCRIPTION: Returns non-zero if file not renamed.
|
| EXAMPLE:  e = RenameFile( "D:A", "D:B" )
|
| NOTE: 
|
| ASSUMES: Paths refer to the same volume.
|          Files are in the same directory. Relax this.
|
| HISTORY: 04.22.97 from 'CopyFileTL'.
------------------------------------------------------------*/
s32
RenameFile( s8* From, s8* To )
{
    s32 e;
    
    e = rename(  (char*) From, (char*) To );
    
    if( e )
    {
        Debugger();
    }
    
    return( e );
}

/*------------------------------------------------------------
|  ReOpenFile
|-------------------------------------------------------------
| 
|  PURPOSE: To open a file that may already exist, and if it
|  does, empty it before opening it. Create the file if it
|  doesn't exist.
|
|  DESCRIPTION: 
| 
|  EXAMPLE:  MyFileName ReOpenFile ( -- Handle OR -1 )
| 
|  NOTE:  
|         
|  ASSUMES: 
| 
|  HISTORY: 07.25.91
|           12.12.93 from Focus
------------------------------------------------------------*/
FILE*
ReOpenFile(s8* FileName)
{
    if( IsFileExisting( FileName ) )
    {
        DeleteFileTL( FileName );
    }
    
    return( CreateFileTL( FileName ) );
}

/*------------------------------------------------------------
| SaveBytesToFile
|-------------------------------------------------------------
|
| PURPOSE: To save some bytes to a file from a given buffer. 
|           
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY: 07.04.96 from 'LoadFile'.
------------------------------------------------------------*/
void
SaveBytesToFile( s8* Path, u8* Buffer, u32 Count )
{
    FILE*   F;
    
    F = ReOpenFile(Path);

    WriteBytes( F, Buffer, Count );
    
    CloseFile(F);
}



/*------------------------------------------------------------
| SetFilePosition
|-------------------------------------------------------------
|
| PURPOSE: To set file position given an offset from the 
|          beginning of the file.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  11.8.89
|           12.09.90 mac version
|           10.27.98 Revised to return the result code.
------------------------------------------------------------*/
s32
SetFilePosition( FILE* FileHandle, u32 Offset )
{
    s32  Result;
    
    // Seek relative to the beginning of the file.
    Result = fseek( FileHandle, (s32) Offset, 0 ); 
    
    // Return the result.
    return( Result );
}

/*------------------------------------------------------------
| ToBeginningOfFile
|-------------------------------------------------------------
|
| PURPOSE: To set file position to the beginning of a file.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  11.8.89
------------------------------------------------------------*/
void
ToBeginningOfFile( FILE* FileHandle )
{
   SetFilePosition( FileHandle, 0 );
}

/*------------------------------------------------------------
| ToEndOfFile
|-------------------------------------------------------------
|
| PURPOSE: To set file position to the end of a file.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  11.08.89
|           12.09.90 mac version
------------------------------------------------------------*/
void
ToEndOfFile( FILE* FileHandle )
{
    s16 Result;
    
    Result = (s16) fseek( FileHandle, 0L, 2);
}

/*------------------------------------------------------------
| WriteByte
|-------------------------------------------------------------
|
| PURPOSE: To write a byte to a file.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  09.18.89
|           12.26.89 added return value
|           12.10.93 arg size changed from u8 to u16
------------------------------------------------------------*/
u16
WriteByte( FILE* FileHandle, u16 AByte )
{
    u16     Result;
    u8      BByte;
    
    BByte = (u8) AByte;
    
    Result = (u16) WriteBytes( FileHandle, (u8*) &BByte, 1 );

    return( Result );
}

/*------------------------------------------------------------
| WriteBytes
|-------------------------------------------------------------
|
| PURPOSE: To write bytes from a buffer to a file.
|
| DESCRIPTION: returns bytes written or 0 if error occurred.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: File is open and current file pointer is positioned.
|
| HISTORY: 01.12.89
|          09.06.89 far buffer potential added
|          12.20.89 added return value, revised to call direct 
|                   to DOS
|          12.09.90 mac version.
|          06.07.96 extended byte count parameter to 4 bytes;
|                   added trap for errors.
------------------------------------------------------------*/
u32
WriteBytes( FILE*   FileHandle,
            u8*     BufferPointer,
            u32     ByteCount )
{

    u32    Result;
    
    Result = (u32) fwrite( BufferPointer,
                           1,
                           ByteCount,
                           FileHandle );
    
    if( Result != ByteCount )
    {
        Debugger();
    }
                           
    return( Result );
}

/*------------------------------------------------------------
| WriteDOSTextLine
|-------------------------------------------------------------
|
| PURPOSE: To write a string to a file replacing the string
|          terminator with a CarriageReturn:LineFeed.
|
| DESCRIPTION: Returns total number of bytes written 
| including the end-of-line CarriageReturn:LineFeed.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Room for data on disk.
|
| HISTORY: 12.12.93 TL
|          03.08.94 IBM version.
|          12.30.98 Copied from 'MINFILE.C'.
------------------------------------------------------------*/
u32
WriteDOSTextLine( FILE* AFile, s8* AString )
{
    u32   BytesWritten;
    u32   StringCount;
    
    StringCount = CountString( AString );
    
    BytesWritten = WriteBytes( AFile, 
                               (u8*) AString, 
                               StringCount );

    WriteByte( AFile, CarriageReturn );
    WriteByte( AFile, LineFeed );

    return( BytesWritten+2 );
}

/*------------------------------------------------------------
| WriteMacTextLine
|-------------------------------------------------------------
|
| PURPOSE: To write a string to a file replacing the string
|          terminator with a CarriageReturn.
|
| DESCRIPTION: Returns total number of bytes written 
| including the end-of-line CarriageReturn.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Room for data on disk.
|
| HISTORY: 12.12.93
|          06.07.96 now has 32 bit result instead of 16.
------------------------------------------------------------*/
u32
WriteMacTextLine( FILE* AFile, s8* AString )
{
    u32   BytesWritten;
    u32   StringCount;
    
    StringCount = CountString( AString );
    
    BytesWritten = WriteBytes( AFile, 
                               (u8*) AString, 
                               StringCount);

    WriteByte( AFile, CarriageReturn );

    return( BytesWritten+1 );
}

/*------------------------------------------------------------
| WriteString
|-------------------------------------------------------------
|
| PURPOSE: To write a string to a file.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  09.18.89
|           06.07.96 now has 32 bit result instead of 16.
------------------------------------------------------------*/
u32
WriteString( FILE*   FileHandle, 
             s8*     AString )
{
    u32   Result;

    Result = WriteBytes( FileHandle, 
                         (u8*) AString, 
                         (u16) CountString( AString ) );

    return( Result );
}

/*------------------------------------------------------------
| WriteStringAsText
|-------------------------------------------------------------
|
| PURPOSE: To write a string to a file replacing 
|          LineFeeds(0x0a) with CarriageReturn:LineFeed 
|          pairs (0x0d,0x0a).
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 09.18.89
|          12.26.89 added return value
|          06.07.96 now has 32 bit result instead of 16.
------------------------------------------------------------*/
u32
WriteStringAsText( FILE*  FileHandle, 
                   s8*    AString )
{
    u8      AByte;
    u32     BytesWritten;

    BytesWritten = 0;

    while( (AByte = (u8) *AString++) != 0 )
    {
        if( AByte == LineFeed )
        {
            BytesWritten += WriteByte( FileHandle, 
                                       CarriageReturn );
        }
        
        BytesWritten += WriteByte( FileHandle, AByte );
    }

    return( BytesWritten );
}

/*------------------------------------------------------------
| WriteTextLine
|-------------------------------------------------------------
|
| PURPOSE: To write a line of text to a file replacing the 
|          string terminator with a given end-of-line string.
|
| DESCRIPTION: Returns total number of bytes written 
| including the end-of-line string.
|
| EXAMPLE:  
|
|   n = WriteTextLine( F, "This is a test.", MacEOLString );
|
| ASSUMES: Room for data on disk.
|
|          No embedded end-of-line characters in the input
|          string.
|
| HISTORY: 05.02.01 TL From WriteMacTextLine.
------------------------------------------------------------*/
u32
WriteTextLine( 
    FILE*   AFile, 
                // Handle of file open for writting.
                //
    s8*     AString,
                // A single line of text as a zero-terminated
                // C string.
                //
    s8*     EndOfLineString )
                // End-of-line string to be appended to each
                // line, a zero-terminated C string.
                //
                // Use one of these from TLAscii.c:
                //
                //  MacEOLString, WinEOLString, UnixEOLString
{
    u32 BytesWritten;
    u32 StringCount;
    u32 EOLCount;
    
    // Measure size of the string being written.
    StringCount = CountString( AString );
    
    // Write the line to the file.
    BytesWritten = WriteBytes( AFile, 
                               (u8*) AString, 
                               StringCount );

    // Measure size of the end-of-line string.
    StringCount = CountString( EndOfLineString );
    
    // Write the end-of-line to the file.
    BytesWritten += WriteBytes( AFile, 
                                (u8*) EndOfLineString, 
                                StringCount);
                                
    // Return the number of bytes written.
    return( BytesWritten );
}

/*------------------------------------------------------------
| WriteU32
|-------------------------------------------------------------
|
| PURPOSE: To write a u32 to a file in LSB-first order.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.22.99
------------------------------------------------------------*/
void 
WriteU32( FILE* F, u32 x )
{
    u8  b[4];
    
    // Put the bytes in LSB-first order.
    b[0] = (u8) ( x & 0xff ); x >>= 8;
    b[1] = (u8) ( x & 0xff ); x >>= 8;
    b[2] = (u8) ( x & 0xff ); x >>= 8;
    b[3] = (u8) ( x & 0xff );
    
    // Write the bytes to the file.
    WriteBytes( F, b, 4 );
}

