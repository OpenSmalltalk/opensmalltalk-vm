/*------------------------------------------------------------
| TLFileExtra.c
|-------------------------------------------------------------
|
| PURPOSE: To provide less commonly used file functions.
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
|           00.27.00 Split off from 'TLFile.c'.
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.
    
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

#if macintosh

#include <Devices.h>
#include <Files.h>
#include <TextUtils.h>
#include <Errors.h> // For fnfErr.
#include <Resources.h>
#include <QuickDraw.h>
#include <TextEdit.h>
#include <Processes.h>

#endif // macintosh

#include "TLTypes.h"
#include "TLAscii.h"
#include "TLBytes.h"
#include "TLBytesExtra.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLDyString.h"
#include "TLBitIO.h"
#include "TLHuffman.h"
#include "TLStacks.h"
#include "TLParse.h"
#include "TLList.h"
#include "TLListIO.h"
#include "TLf64.h"
#include "TLByteBuffer.h"
#include "TLWin.h"
#include "TLMassMem.h"
#include "TLTable.h"
#include "TLNameAt.h"
#include "TLAk2Types.h"
#include "TLNumber.h"
#include "TLFile.h"
#include "TLMatrixAlloc.h"
#include "TLStringList.h"

#include "TLFileExtra.h"

#define USE_DISK_CACHE
        // Define the above symbol to enable the use of the 
        // MacOS disk cache for low-level file operations.
        //
        // See p. 2-95 of 'InsideMac Files' and also a public
        // domain patch written by Stuart Cheshire that alters 
        // the '_Write' trap to make disk writes go much faster: 
        // see the file 'write-through-init.c'.

#ifdef USE_DISK_CACHE

#define UseCacheOption  0x10
        // Logically OR the above value with 'ioPosMode' 
        // constants to ENABLE caching of low level file 
        // operations.  

#else

#define UseCacheOption  0x20 
        // Logically OR the above value with 'ioPosMode' 
        // constants to DISABLE caching of low level file 
        // operations.

#endif

/*------------------------------------------------------------
| CloseFileLowLevel
|-------------------------------------------------------------
|
| PURPOSE: To close a file that is open for low level file
|          access.
|
| DESCRIPTION: Also flushes the file and volume before 
| closing the file.  If the flush process fails then the 
| file will be left open.
|
| EXAMPLE:  
|
| NOTE: Returns 0 if sucessful, else returns an error code.
|
| WARNING: Attempting to close a file that has already been
|          closed will result in corruption of data.
|          See p. 2-124 of 'Inside Mac: Files'.
|
| ASSUMES: File is open.
|
|          No caching of low level files so no need to flush.
|
| HISTORY:  03.19.98 TL
|           03.22.98 TL Added volume number parameter.
|           03.23.98 TL Revised to remove caching and flush.
------------------------------------------------------------*/
#if macintosh

s16
CloseFileLowLevel( s32 FileRefNum, s32 VolRefNum )
{
    OSErr           err;
    ParamBlockRec   H;
    
    // Set up the parameter block.
    H.ioParam.ioRefNum  = (s16) FileRefNum;
    H.ioParam.ioVersNum = 0; // Always must be zero.
            
    // Close the file referred to by the 'ioRefNum' of the
    // parameter block.
    err = PBCloseSync( &H );
    
    // If there is an error.
    if( err )
    {
        // Trap it.
        Debugger();
    }
    else // If there is no error from closing the file.
    {
        // Set up the parameter block.
        H.ioParam.ioNamePtr = 0;
        H.ioParam.ioVRefNum = (s16) VolRefNum;
        H.ioParam.ioVersNum = 0; // Always must be zero.
        
        // Flush volume here because otherwise some data 
        // won't be updated.
        // See p. 2-124.
        err = PBFlushVolSync( &H );

        // If there is an error.
        if( err )
        {
            // Trap it.
            Debugger();
        }
    }
        
    // Return the error code.
    return( err );
}

#endif // macintosh
    
/*------------------------------------------------------------
| ConvertEndOfLinesInTextFiles
|-------------------------------------------------------------
|
| PURPOSE: To convert all of the text files in a directory to
|          a given end-of-line format with optional tab 
|          character translation.
|
| DESCRIPTION:  
|
| EXAMPLE: Convert all of the text files in the folder 'TEXT'
| on volume X to Unix end-of-line format and translate tabs
| to spaces with tab stops set every 4 characters.
|
| ConvertEndOfLinesInTextFiles( "X:TEXT:", UnixEOLString, 4 );
|
| ASSUMES: OK to overwrite text files.
|
|          Each file is small enough to fit in memory.
|
|          MacOS operating system.
|
| HISTORY: 04.29.01 TL
|          05.02.01 Generalized to take end-of-line parameter
|                   and applied WriteListOfTextLines.
------------------------------------------------------------*/
void
ConvertEndOfLinesInTextFiles( 
    s8* DirectoryPath,
            // Path to directory containing text files.
            //
    s8* EndOfLineString,
            // End-of-line string to be appended to each
            // line, a zero-terminated C string.
            //
            // Use one of these from TLAscii.c:
            //
            //  MacEOLString, WinEOLString, UnixEOLString
            //
    u32 TabStopInterval )
            // The number of characters between tab stops
            // assuming that tab stops are placed at
            // uniform intervals across the line.
            //
            // Use zero if tabs should not be translated
            // to spaces.
{
    List*   L;
    List*   T;
    s8*     FilePath;
    s8*     FileName;
    s8*     FileType;
    
    // Make a list of the files in the directory.
    L = MakeListOfPathsToFilesInDirectory( DirectoryPath );
    
    // Make the list of files the default list.
    ReferToList( L );
    
    // For each file.
    while( TheItem )
    {
        // Refer to the file path.
        FilePath = (s8*) TheDataAddress;
        
#if macintosh
        // Get the file type.
        FileType = GetFileTypeTL( FilePath );
#else
        FileType = "TEXT";
#endif

        // Refer to the file name in the path.
        FileName = LocateFileNameInPathName( (s8*) TheDataAddress );
        
        // If the filetype is text and is visible.
        if( strcmp( FileType, "TEXT" ) == 0 && FileName[0] != '.' )
        {
            // Load the text file as a list of strings, stripping
            // out whatever end-of-line character it has.
            T = ReadListOfTextLines( FilePath );
            
            // If tabs should be translated to spaces.
            if( TabStopInterval )
            {
                // Detab the text using the given tab stop interval.
                DetabStringList(
                    T,
                        // List of text lines, one line string per 
                        // item as a C string with no end-of-line 
                        // characters.
                        //
                    TabStopInterval );
                        // Number of characters between tab stops
                        // assuming that tab stops are placed at
                        // uniform intervals across the line.
            }
            
            // Rewrite the text file with the new end-of-line
            // sequence.
            WriteListOfTextLines(
                FilePath, 
                    // Path to the file to be (re)written.
                    //
                T,  // List of text lines, one line string per 
                    // item as a C string with no end-of-line 
                    // characters.
                    //
                EndOfLineString );
                    // End-of-line string to be appended to each
                    // line, a zero-terminated C string.
            
            // Delete the list of text lines.
            DeleteListOfDynamicData(T);
        }
        
        // Advance to the next file.
        ToNextItem();
    }
    
    RevertToList();
    
    // Delete the list of file paths.
    DeleteListOfDynamicData(L);
}

/*------------------------------------------------------------
| CopyFileTL
|-------------------------------------------------------------
|
| PURPOSE: To copy a file.
|
| DESCRIPTION: If the destination file exists, it is erased 
| and overwritten. Returns non-zero if file not copied.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Resource fork isn't to be copied. Add when needed.
|          Room in RAM for entire file.
|
| HISTORY: 04.04.91
|          02.02.97 added buffering, transfer of creator &
|                   file type.
|          01.07.99 Name changed from 'CopyFile()' to avoid
|                   name collision with NT procedure.
------------------------------------------------------------*/
s32
CopyFileTL( s8* From, s8* To )
{
    Item*   FromBuf;
#if macintosh
    s8*     Creator;
    s8*     Type;
#endif // macintosh

    // Try to load the file to a dynamic buffer referred to
    // by an 'Item' record.
    FromBuf = LoadFileToItem( From );
 
    // If all of the source file was read.
    if( FromBuf && 
        ( FromBuf->SizeOfData ==     // 'BytesRead'
          FromBuf->SizeOfBuffer ) )  // 'FileSize'
    {
#if macintosh
        // Get the file creator and type.
        Creator = GetFileCreator( From );
        Type    = GetFileTypeTL( From );
#endif // macintosh
        
        // Make the destination file.
        SaveBytesToFile( To, 
                         FromBuf->BufferAddress, 
                         FromBuf->SizeOfData );
#if macintosh       
        // Set the file types for the copy.
        SetFileType( To, Type );
        SetFileCreator( To, Creator );
#endif // macintosh
     
        // Discard the item and buffer.
        free( FromBuf->BufferAddress );
        DeleteItem( FromBuf );
        
        // Make sure the files match after the copy.
        if( IsMatchingFiles( From, To ) ) 
        {
            return(0);
        }
        else // An error during copy.
        {
            // Erase the any partial destination file.
            if( IsFileExisting( To ) )
            {
                DeleteFileTL( To );
            }
            
            return(-1);
        }
    }
    else // Complete file not read in.
    {
        // If a partial file was loaded, discard the buffer.
        if( FromBuf )
        {
            if( FromBuf->BufferAddress )
            {
                // Discard the item and buffer.
                free( FromBuf->BufferAddress );
            }
            
            DeleteItem( FromBuf );
        }
        
        return(-1);
    }
}

/*------------------------------------------------------------
| CountDirectoryEntries
|-------------------------------------------------------------
|
| PURPOSE: To count the entries in a given directory, both 
|          files and sub-directories.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 03.22.91
|          04.04.91 args changed per p. 443 of Mac Rom Encyc.
|          02.02.97 added explicit volume reference.
|          08.19.97 changed 'PBGetCatInfo' to 'PBGetCatInfoSync'
|                   which is the new convention.
|          08.25.97 Added 'MakeDirectoryPathEndInColon'.
------------------------------------------------------------*/
#if macintosh

s32
CountDirectoryEntries( s8* Directory )
{
    CInfoPBRec  Info;
    CInfoPBPtr  pb;
    OSErr       error;
    s16     VolRef;
    
    // Put the directory path in standard form.
    MakeDirectoryPathEndInColon( Directory );

    // Get the volume ref num of the path.
    VolRef = GetVolumeReferenceNumberOfPath( Directory );
    
    pb = &Info;
    
    c2pstr( (char*) Directory );  
    
    pb->dirInfo.ioFDirIndex = 0; // cause name to be used 
    pb->dirInfo.ioVRefNum   = VolRef; 
    pb->dirInfo.ioNamePtr   = (StringPtr) Directory;
    
    error = PBGetCatInfoSync( pb ); // synchronous
    p2cstr( (StringPtr) Directory); // back to c format 
    
    return( (s32) pb->dirInfo.ioDrNmFls );
}

#endif // macintosh

/*------------------------------------------------------------
| CountFiles
|-------------------------------------------------------------
|
| PURPOSE: To count the number of proper files in a given 
|          directory.
|
| DESCRIPTION: A proper file holds data: it is a directory 
|              entry that is not a sub-directory.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 06.10.96
------------------------------------------------------------*/
#if macintosh
s32
CountFiles(s8* Directory)
{
    s32 EntryCount;
    s32 SubDirCount;
    
    // Count both files and directories entries.
    EntryCount = CountDirectoryEntries(Directory);
    
    // Count the subdirectories.
    SubDirCount = CountSubDirectories(Directory);
    
    // Return the result.
    return( EntryCount - SubDirCount );
}
#endif // macintosh

/*------------------------------------------------------------
| CountSubDirectories
|-------------------------------------------------------------
|
| PURPOSE: To count the number of sub-directories in a given 
|          directory.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 06.10.96
|          08.25.97 factored out 
|                   'MakeDirectoryPathEndInColon'.
------------------------------------------------------------*/
s32
CountSubDirectories(s8* Directory)
{
    s32 SubDirCount;
    
#if macintosh
    s32 EntryCount;
    s8* EntryName;
    s8  EntryPath[128];
    s32 i;
    
    // Count both files and directories entries.
    EntryCount = CountDirectoryEntries(Directory);

    // For each entry, accumulate sub directory count.
    SubDirCount = 0;
    for( i = 0; i < EntryCount; i++ )
    {
        // Get the name of the entry.
        EntryName = NameOfNthDirectoryEntry(Directory, i);
        
        // Make a full path for the entry.
        CopyString( Directory, EntryPath );
        
        // If the directory name doesn't end in a ':',
        // add one.
        MakeDirectoryPathEndInColon( EntryPath );
        
        AppendStrings( EntryPath, EntryName, 0 );
        
        // Test for this being a directory.
        if( IsDirectory(EntryPath) )
        {
            SubDirCount++;
        }
    }
#else
        // FIX THIS LATER.
        Directory = Directory;
        SubDirCount = 0;
#endif // macintosh
    
    // Return the result.
    return( SubDirCount );
}   
        
/*------------------------------------------------------------
| CrcFile
|-------------------------------------------------------------
|
| PURPOSE: To compute a CRC checksum value of a range of bytes 
|          in a file.
|
| DESCRIPTION: Allocates a 64K working buffer to minimize the
| amount of time spent reading the disk.
|
| EXAMPLE:
|           C = CrcFile( F, StartOffset, ByteCount );
|
| NOTE: 
|
| ASSUMES: The file is open.
|
|          64K temporary buffer can be created.
|
| HISTORY: 11.16.98 TL From 'CrcLG()'.
|          12.02.98 Added trap for read failure.
------------------------------------------------------------*/
                     // Returns the CRC value of the bytes.
u32                     
CrcFile( 
    FILE* F,         // The file.
                     //
    u32 StartOffset, // The starting byte offset in the file.
                     //
    u32 ByteCount )  // How many bytes to include in CRC.
{ 
    u8* B;
    u32 CRC;
    u32 ByteCountThisPass, BytesRead;
    
    // Allocate the working buffer.
    B = malloc( 64 * 1024 );
    
    // Seek to the starting location.
    SetFilePosition( F, StartOffset );
    
    // Start the CRC value at zero.
    CRC = 0;
    
    // Until all the bytes have been processed.
    while( ByteCount )
    {
        // Set the default number of bytes to process 
        // on this pass to 64K.
        ByteCountThisPass = 64 * 1024;
        
        // If the amount remaining is less than 64K
        if( ByteCountThisPass > ByteCount )
        {
            // Use only the amount remaining.
            ByteCountThisPass = ByteCount;
        }
        
        // Read the bytes into the buffer.
        BytesRead = (u32) ReadBytes( F, B, ByteCountThisPass );
        
        // If the number of bytes actually read isn't
        // the amount requested.
        if( BytesRead != ByteCountThisPass )
        {
            // Trap the error.
            Debugger();
        }
        
        // Update the CRC value for the bytes read.
        CRC = CRC32Bytes( B, ByteCountThisPass, CRC );
        
        // Account for the number of bytes just processed.
        ByteCount -= ByteCountThisPass;
    }
    
    // Discard the temp buffer.
    free( B );

    // Return the checksum.
    return( CRC );
}   

/*------------------------------------------------------------
| CreateDirectoryTL
|-------------------------------------------------------------
|
| PURPOSE: To create a new directory.
|
| DESCRIPTION: Returns 0 if ok, else non-zero.
|
| EXAMPLE:  CreateDirectoryTL( "D:Data:Index" );
|
| NOTE: 
|
| ASSUMES: Superior directories exist.
|
| HISTORY: 04.04.91
|          02.02.97 added explicit volume reference; test for
|                   pre-existing directory.
|          08.19.97 changed 'PBDirCreate' to 'PBDirCreateSync'
|                   which is the new convention.
|          01.07.99 Name changed from 'CreateDirectory()' to 
|                   avoid name collision with NT procedure.
------------------------------------------------------------*/
#if macintosh

s16
CreateDirectoryTL( s8* Path )
{
    HParamBlockRec  H;
    OSErr           error;
    s32         VolRef;
    Str255          Path_PascalString;
    
    // Check to see if the directory already exists.
    if( IsFileExisting( Path ) )
    {
        return( 0 );
    }
    
    // Get the volume ref num of the path.
    VolRef = GetVolumeReferenceNumberOfPath( Path );
    
    // Convert the c string into a pascal string.
    CopyCToPascalString( Path, (s8*) Path_PascalString );
     
    H.fileParam.ioNamePtr   = Path_PascalString;
    H.fileParam.ioVRefNum   = VolRef; 
    H.fileParam.ioDirID     = 0; // in root
    H.fileParam.ioFVersNum  = 0; // Must always be zero.
    H.fileParam.ioFlVersNum = 0; // Must always be zero.
    
    error = PBDirCreateSync( &H );
    
    // If there is an error.
    if( error )
    {
        // Trap it.
        Debugger();
    }
    
    return( error );
}

#endif // macintosh

/*------------------------------------------------------------
| CreateNestedDirectory
|-------------------------------------------------------------
|
| PURPOSE: To create a new directory and any intermediate
|          directories.
|
| DESCRIPTION: Returns 0 if ok, else non-zero.
|
| If intermediate folders don't exist, then they are created
| too.
|
| EXAMPLE:  CreateNestedDirectory( "D:Data:Index" );
|
| NOTE: 
|
| ASSUMES: Superior folders may be non-existent.
|          The path includes a drive spec or no colons.
|
| HISTORY: 08.03.96
|          02.02.97 fixed trailing colon error.
------------------------------------------------------------*/
#if macintosh

s16
CreateNestedDirectory( s8* Dir )
{
    s32     ColonCount, MaskedColonCount;
    OSErr   error;
    s8*     AtColon;
    s8      Path[MaxPathLength];
    u32     n;
    
    // Copy the path to a local buffer.
    CopyString( Dir, Path );
    
    // If there is a trailing colon, drop it.
    AtColon = AddressOfLastCharacterInString(Path);
    if( *AtColon == ':' )
    {
        *AtColon = 0;
    }
    
    error = 0;
    
    // Count how many colon there are total
    ColonCount = CountBytesOfTypeInString( Path, (u16) ':' );

    // If none or one, then just use 'CreateDirectoryTL' 
    // directly.
    if( ColonCount < 2 )
    {
        return( CreateDirectoryTL( Path ) );
    }
    
    // Initially none of the colons are masked.
    MaskedColonCount = 0;
    
    // Work back to an existing folder or the drive ID and
    // a file.
    while( !IsFileExisting( Path ) &&
           (MaskedColonCount < ColonCount) )
    {
        // Put a zero string terminator in the last
        // ':' to mask it, thereby referring to the next 
        // folder up.
        n = (u32) (ColonCount - MaskedColonCount) - 1;
        
        AtColon = FindNthByteOfType( Path,
                                     n,
                                     (u16) ':');
        AtColon[0] = 0;
        
        MaskedColonCount++;
    }

    // Now work forward building folders as we go.
    while( MaskedColonCount )
    {
        // Restore the colon
        AtColon = AddressOfLastCharacterInString( Path );
        AtColon[1] = ':';
    
        // Now create the folder.
        error = CreateDirectoryTL( Path );
        
        if( error ) break;
        
        MaskedColonCount--;
    }
        
    return( error );
}

#endif // macintosh

/*------------------------------------------------------------
| CreateFileLowLevel
|-------------------------------------------------------------
|
| PURPOSE: To create a file using the low level calls.
|
| DESCRIPTION: Expects a path as a C string, a volume reference
| number and a directory ID.  In addition to creating the
| file, this function fills in the Finder information referred
| to below.
|
| From IM Files page 2-187:
|
| "The PBHCreate function creates a new file (both forks);
|  the new file is unlocked and empty.  The date and time
|  of its creation and last modification are set to the
|  current date and time.  If the file created isn't
|  temporary (that is, if it will exist after the user quits
|  the application), the application should call PBHSetFInfo
|  (after PBHCreate) to fill in the information needed by the
|  Finder.  
|
|  Files created using PBHCreate are not automatically opened.
|
|  If you want to write data to the new file, you must first
|  open the file using a file access routine (such as PBHOpenDF).
|
|  Note: The resource fork of the new file exists but is 
|  empty.  You'll need to call one of the Resource Manager
|  procedures CreateResFile, HCreateResFile or FSpCreateResFile
|  to create a resource map in the file before you can open it
|  (by calling one of the Resource Manager functions OpenResFile,
|  HOpenResFile, or FSpOpenResFile)."
|
| EXAMPLE:  
|   
|   CreateFileLowLevel( "DriveB:MyFile", AVolRefNum, ADirID );
|
| NOTE: 
|
| ASSUMES: System 7 and above.
|
|          File can be created.
|
|          Should default to text file type.
|
| HISTORY: 03.22.98 with some code pulled from 'open' in
|                   'fcntl.mac.c'.
------------------------------------------------------------*/
#if macintosh

void
CreateFileLowLevel( s8* Path, s32 VolRefNum, s32 DirID )
{
    HParamBlockRec  H;
    OSErr           err;
    Str255          Path_PascalString;
    u32             secs;

    // Convert the c string into a pascal string.
    CopyCToPascalString( Path, (s8*) Path_PascalString );

    // Set up the parameter block for file creation.
    H.fileParam.ioCompletion = 0;
    H.fileParam.ioNamePtr    = Path_PascalString;
    H.fileParam.ioVRefNum    = (s16) VolRefNum;
    H.fileParam.ioDirID      = DirID;
    H.fileParam.ioFVersNum   = 0; // Must always be zero.
    H.fileParam.ioFlVersNum  = 0; // Must always be zero.
    
    // Create the file.
    err = PBHCreateSync( &H );
    
    // If there was an error.
    if( err )
    {
        // Trap the error.
        Debugger();
    }
    else // File created OK.
    {
        GetDateTime( &secs );

        // Set the finder info.
        H.fileParam.ioFlCrDat = secs;
        H.fileParam.ioFlMdDat = secs;
        H.fileParam.ioFlFndrInfo.fdType    = 'TEXT';
        H.fileParam.ioFlFndrInfo.fdCreator = 'CWIE';
        H.fileParam.ioFlFndrInfo.fdFlags   = 0;
        H.fileParam.ioFVersNum   = 0; // Must always be zero.
        H.fileParam.ioFlVersNum  = 0; // Must always be zero.
        
        PBHSetFInfoSync( &H );
    }
}

#endif // macintosh

/*------------------------------------------------------------
| DeleteDirectory2
|-------------------------------------------------------------
|
| PURPOSE: To delete a directory.
|
| DESCRIPTION: Returns 0 if ok, else non-zero.
|
| EXAMPLE:  
|
| NOTE: Can also be used to delete files on the Mac.
|
| ASSUMES: Directory exists.
|          Default volume.
|          Path given is root relative.
|
| HISTORY: 04.06.91
|          08.19.97 changed 'PBHDelete' to 'PBHDeleteSync'
|                   which is the new convention.
|          08.25.97 Name changed from 'DeleteDirectory' to
|                   avoid conflict with MoreFiles routine.
|          03.23.98 Cleaned up.
------------------------------------------------------------*/
#if macintosh

s16
DeleteDirectory2(s8* Dir)
{
    HParamBlockRec  H;
    OSErr           error;
    Str255          Path_PascalString;

    // Convert the c string into a pascal string.
    CopyCToPascalString( Dir, (s8*) Path_PascalString );
    
    H.fileParam.ioNamePtr   = Path_PascalString;
    H.fileParam.ioVRefNum   = 0; // default volume
    H.fileParam.ioDirID     = 0; // in root
    H.fileParam.ioFVersNum  = 0; // Must always be zero.
    H.fileParam.ioFlVersNum = 0; // Must always be zero.

    error = PBHDeleteSync( &H );

    return( error );
}

#endif // macintosh

/*------------------------------------------------------------
| GetCreationDateOfIndexedVolume
|-------------------------------------------------------------
|
| PURPOSE: To return the creation date of the indexed
|          volume.
|
| DESCRIPTION: Returns 0 if the indexed volume isn't mounted.
| The first mounted volume has an index number of 1.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY:  01.25.93
|           12.30.96 fixed error where 'VolumeParam' was used
|                    instead of 'HParamBlockRec' -- wild memory
|                    writes outside of the 'VolumeParam'
|                    could cause errors.
|           03.23.98 Changed use of 'HParamBlockRec' to 
|                    'ParamBlockRec'.
------------------------------------------------------------*/
#if macintosh

s32
GetCreationDateOfIndexedVolume( s16 VolumeIndex )
{
    OSErr           err;
    ParamBlockRec   P;
    
    P.volumeParam.ioCompletion = 0;
    P.volumeParam.ioNamePtr    = 0;
    P.volumeParam.ioVRefNum    = 0;
    P.volumeParam.ioVolIndex   = VolumeIndex;
    
    err = PBGetVInfoSync( &P );
   
    // If there was an error.
    if( err )
    {
        return( 0 );
    }
    else // No error.
    {
        // Return the creation date.
        return( P.volumeParam.ioVCrDate );
    }
}

#endif // macintosh

/*------------------------------------------------------------
| GetDirectoryIDOfParentDirectory
|-------------------------------------------------------------
|
| PURPOSE: To look up the directory ID number of the directory
|          that holds the file.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
|   d = GetDirectoryIDOfParentDirectory( "D:AFolder:MyFile" );
|
| where 'd' holds the directory ID of 'AFolder' on return.
|
| NOTE: 
|
| ASSUMES: The file exists. 
|           
| HISTORY: 08.19.97
------------------------------------------------------------*/
#if macintosh

s32
GetDirectoryIDOfParentDirectory( s8* Path )
{
    CInfoPBRec  Info;
    CInfoPBPtr  pb;
    OSErr       error;
    s16     VolRef;
    
    // Get the volume ref num of the path.
    VolRef = GetVolumeReferenceNumberOfPath( Path );
    
    pb = &Info;
    
    c2pstr( (char*) Path);  // convert to pascal format
    
    pb->dirInfo.ioFDirIndex = 0; // cause name to be used 
    pb->dirInfo.ioVRefNum   = VolRef; 
    pb->dirInfo.ioNamePtr   = (StringPtr) Path;
    
    error = PBGetCatInfoSync( pb ); 

    p2cstr( (StringPtr) Path );     // back to c format
    
    // Return the result.
    return( pb->hFileInfo.ioFlParID );
}

#endif // macintosh

/*------------------------------------------------------------
| GetDiskFreeSpaceTL
|-------------------------------------------------------------
|
| PURPOSE: To get the number of bytes available on the volume
|          with the given path.
|
| DESCRIPTION:  
|
| EXAMPLE:
|
|     n = GetDiskFreeSpaceTL( "MyDisk:MyFile" );
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 09.28.97 TL Tested.
|          03.19.98 TL Factored out 'GetVolumeFreeSpace()'.
|          01.07.99 Name changed from 'GetDiskFreeSpace()' to 
|                   avoid name collision with NT procedure.
------------------------------------------------------------*/
u32
GetDiskFreeSpaceTL( s8* Path )
{
#if macintosh   
    s16   RefNum;
    //
    // Find the volume reference number for the path.
    //
    RefNum = GetVolumeReferenceNumberOfPath( Path );
    
    // Get the free space on the volume.
    return( GetVolumeFreeSpace( RefNum ) );
#else // FIX THIS LATER.
    Path = Path;
#endif // macintosh
 
    return( 0 ); // not mac
}

/*------------------------------------------------------------
| GetFileAttributesTL
|-------------------------------------------------------------
|
| PURPOSE: To get the attribute byte for a given file.
|
| DESCRIPTION: Returns error code in high byte, attribute code 
|              in low byte.
|
| Error Codes: 0 = no error                                
|              1 = invalid function (file sharing)                          
|              2 = file not found                                             
|              3 = path not found                                             
|              5 = access denied                                              
|                                                                             
| Attribute Codes: 76543210
|                  .......1  Read Only
|                  ......1.  Hidden
|                  .....1..  System
|                  ....1...  Volume Label
|                  ...1....  Directory
|                  ..1.....  Archive
|                  xx......  Unused
|  
| EXAMPLE: Attr = GetFileAttribute("TEST.SCR"); 
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 12.21.89
|          12.09.90 disabled - write for mac as needed.
|          03.08.94 Small mem model rev for DOS.
|          12.30.98 Copied DOS code here from 'MINFILE.C'.
|          01.07.99 Name changed from 'GetFileAttributes()' to 
|                   avoid name collision with NT procedure.
------------------------------------------------------------*/

#if MSDOS

u16
GetFileAttributesTL( s8* AFileName )
{
   s16              Result;
   union    REGS    Registers;
   struct   SREGS   SegmentRegisters;
   
   segread( &SegmentRegisters );

   // DOS Function 43ch, Subfunction 0, Get File Attributes.
   Registers.h.ah = 0x43;  
   Registers.h.al = 0x00;           

   Registers.x.dx      = (s16) AFileName; 
   // SegmentRegisters.ds = TheDS;

   intdosx( &Registers, &Registers, &SegmentRegisters );
    
   if( Registers.x.cflag == 0 )
   {
      // no error, attibute byte.
      Result = Registers.x.cx & 0xff; 
   }
   else // error code.
   {
      Result = (Registers.x.ax & 0xff) << 8;    
   }

   return( Result );
}

#endif // MSDOS

#if macintosh

u16
GetFileAttributesTL( s8* /* AFileName */ )
{
   s16     Result;
   
   Debugger();
   
   Result = 0;
   
   return( Result );
}

#endif // macintosh

    
/*------------------------------------------------------------
| GetFileCreator
|-------------------------------------------------------------
|
| PURPOSE: To get the 4-byte file creator ID for an 
|          existing file.
|
| DESCRIPTION: 
|
| EXAMPLE:  c = GetFileCreator( MyFileName );
|
| NOTE: See p. 77 Mac Programming Secrets, p.IV-149,150  
|       InsideMac, p.456 Mac Rom.
|
| ASSUMES: File exists.
|
| HISTORY: 02.02.97 from 'SetFileCreator'.
|          03.23.98 Corrected use of partial param block.
------------------------------------------------------------*/
#if macintosh

s8*
GetFileCreator( s8* Path )
{
    static s8       ACreator[5];
    ParamBlockRec   P;
    OSErr           err;
    s16             VolRef;
    Str255          Path_PascalFormat;
    
    // Convert the c string into a pascal string.
    CopyCToPascalString( Path, (s8*) Path_PascalFormat );
    
    // Get the volume ref num of the path.
    VolRef = GetVolumeReferenceNumberOfPath( Path );
    
    P.fileParam.ioNamePtr   = Path_PascalFormat;
    P.fileParam.ioVRefNum   = VolRef; 
    P.fileParam.ioFDirIndex = 0; // cause name to be used 
    P.fileParam.ioFVersNum  = 0; // Must always be zero.
    P.fileParam.ioFlVersNum = 0; // Must always be zero.
    
    err = PBGetFInfoSync( &P );

    // If there was an error.
    if( err )
    {
        // Trap it.
        Debugger();
    }
    else // Got the file info.
    {
        CopyBytes((u8*) &P.fileParam.ioFlFndrInfo.fdCreator,
                  (u8*) &ACreator, 
                  (u32) 4 );
                  
        ACreator[4] = 0; // string terminator
    }
    
    // Return reference to the result.
    return( ACreator );
}

#endif // macintosh

/*------------------------------------------------------------
| GetFileSpecForPath
|-------------------------------------------------------------
|
| PURPOSE: To fill in a file spec struct for a path.
|
| DESCRIPTION: Returns 1 if file spec is constructed 
| properly else returns 0.
|
| EXAMPLE:  
|
|          t = GetFileSpecForPath( "D:AFolder", &F );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 08.19.97
|          09.02.97 Converted file name to Pascal format, 
|                   fixing bug.
------------------------------------------------------------*/
#if macintosh

u32
GetFileSpecForPath( s8* Path, FSSpec* F )
{
    // If the file exists.
    if( IsFileExisting( Path ) )
    {
        // Set the volume reference number of the path in
        // the file spec.
        F->vRefNum = GetVolumeReferenceNumberOfPath( Path );
        
        // Set the parent directory ID in the file spec.
        F->parID = GetDirectoryIDOfParentDirectory( Path );
        
        // Copy the file name to the filespec.
        CopyString( LocateFileNameInPathName( Path ),
                    (s8*) &F->name );
        
        // Convert the file name to Pascal format.
        c2pstr( (char*) &F->name );
                  
        return( 1 );
    }
    else // File doesn't exist.
    {
        return( 0 );
    }
}

#endif // macintosh

/*------------------------------------------------------------
| GetFileTypeTL
|-------------------------------------------------------------
|
| PURPOSE: To get the 4-byte file type for an existing file.
|
| DESCRIPTION: 
|
| EXAMPLE:  t = GetFileTypeTL( MyFileName )
|
| NOTE: See p. 77 Mac Programming Secrets, p.IV-149,150  
|       InsideMac, p.456 Mac Rom.
|
| ASSUMES: File exists.
|
| HISTORY: 02.02.97 from 'SetFileType'.
|          03.23.98 Corrected use of partial param block.
|          01.07.99 Name changed from 'GetFileType()' to 
|                   avoid name collision with NT procedure.
------------------------------------------------------------*/
#if macintosh

s8*
GetFileTypeTL( s8* Path )
{
    ParamBlockRec   P;
    OSErr           err;
    s16         VolRef;
    static s8   FileType[5];
    Str255          Path_PascalFormat;
    
    // Convert the c string into a pascal string.
    CopyCToPascalString( Path, (s8*) Path_PascalFormat );
     
    // Get the volume ref num of the path.
    VolRef = GetVolumeReferenceNumberOfPath( Path );
    
    P.fileParam.ioNamePtr   = Path_PascalFormat;
    P.fileParam.ioVRefNum   = VolRef; 
    P.fileParam.ioFDirIndex = 0; // cause name to be used
    P.fileParam.ioFVersNum  = 0; // Must always be zero.
    P.fileParam.ioFlVersNum = 0; // Must always be zero.
    
    err = PBGetFInfoSync( &P );
 
    // If there was an error.
    if( err )
    {
        // Trap it.
        Debugger();
    }
    else // Got the file info.
    {
        CopyBytes( (u8*) &P.fileParam.ioFlFndrInfo.fdType,
                   (u8*) &FileType, 
                   (u32) 4 );
                   
        FileType[4] = 0; // String terminator
    }
    
    // Return the result.
    return( FileType );
}

#endif // macintosh
    
/*------------------------------------------------------------
| GetNameOfResource
|-------------------------------------------------------------
|
| PURPOSE: To get the name of a resource in a resource file.
|
| DESCRIPTION: Returns address of a static C-string buffer 
| that holds the name, if any.
|
| EXAMPLE:
|
|     n = GetNameOfResource( RefNum, 'PiMI', 16000 );
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 09.08.97 TL 
------------------------------------------------------------*/
#if macintosh

s8*
GetNameOfResource( 
    s16 RefNum, // Reference number of open resource file.
    ResType ResTyp, 
    s16   Index ) 
{
    static Str255   RsName;
    ResType RsTyp;
    s16   RsID;
    Handle  h;
    
    // Clear the name field.
    RsName[0] = 0;

    // Get the resource from any open resource file.
    h = GetResource( ResTyp, Index );
                
    // If the resource comes from the given file.
    if( HomeResFile( h ) == RefNum )
    {
        // Get info about the resource.
        GetResInfo( h, 
                    &RsID, 
                    &RsTyp, 
                    RsName );
                    
        // If info is no good.
        if( ResError() != noErr )
        {
            // Clear the name field.
            RsName[0] = 0;
        }
        
        // If a name exists.
        if( RsName[0] )
        {
            // Convert the name to C format in place.
            //
            p2cstr( RsName );
        }
    }
    
    // Get rid of the resource.
    ReleaseResource( h );
    
    // Return the result.
    return( (s8*) RsName );
}

#endif // macintosh
                
/*------------------------------------------------------------
| GetNthResourceOfTypeFromFile
|-------------------------------------------------------------
|
| PURPOSE: To load the nth resource of a certain type from
|          a specific resource file. 
|
| DESCRIPTION: Returns a handle to the resource or 0 if the
| resource isn't loadable from the given file.
|
| Expects the resource file reference number of a currently
| open resource file. 
|
| Index is 1-based.
|
| EXAMPLE:
|
|     h = GetNthResourceOfTypeFromFile( 'PiPL', 
|                                       i, 
|                                       ResourceFileRefNum );
|
| NOTE:  
|
| ASSUMES: OK to enable resource loading as a side-effect.
|
| HISTORY: 09.08.97 TL 
------------------------------------------------------------*/
#if macintosh

Handle
GetNthResourceOfTypeFromFile( 
    ResType RsType, 
    s16     RsID, 
    s16     ResourceFileRefNum ) 
{
    Handle  h;
    OSErr   o;
    
    // Can't turn off resource loading and still use
    // 'GetIndResource'... see p. 1-99 of 
    // "IM More Macintosh Toolbox".
    SetResLoad( 1 );
    
    // Get the resource from any open resource file.
    h = GetIndResource( RsType, RsID );
    
    // Check for an error.
    o = ResError();
            
    // If info is no good.
    if( o != noErr )
    {
        return( 0 );
    }
        
    // If the resource didn't come from the given file.
    if( HomeResFile( h ) != ResourceFileRefNum )
    {
        // Just get rid of the resource.
        ReleaseResource( h );
        
        // Set the handle to zero to signal that the resource
        // can't be loaded from the specified file.
        h = 0;
    }
    
    // Return the result.
    return( h );
}

#endif // macintosh
                    
/*------------------------------------------------------------
| GetVolumeFreeSpace
|-------------------------------------------------------------
|
| PURPOSE: To get the number of bytes available on the given
|          volume.
|
| DESCRIPTION:  
|
| EXAMPLE: If 2 is the number of the volume you're interested
| in then:
|
|       n = GetVolumeFreeSpace( 2 );
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 03.19.98 TL factored from 'GetDiskFreeSpaceTL'.
------------------------------------------------------------*/
#if macintosh

u32
GetVolumeFreeSpace( s16 RefNum )
{
    HParamBlockRec  H;
    
    // Set 'ioVolIndex' to 0 so that the volume information
    // will be retrieved by using just the volume reference
    // number. 
    H.volumeParam.ioVolIndex   = 0;
    H.volumeParam.ioVRefNum    = RefNum;
    H.volumeParam.ioCompletion = 0;
    H.volumeParam.ioNamePtr    = 0;
    
    // Get the volume info.
    PBHGetVInfoSync( &H );

    // Calculate the number of free bytes on the volume:
    // the number of free blocks times the size of a block.
    return( H.volumeParam.ioVFrBlk *
            H.volumeParam.ioVAlBlkSiz );
}

#endif // macintosh


/*------------------------------------------------------------
| GetFileInfo
|-------------------------------------------------------------
|
| PURPOSE: To get file info on Mac.
|
| DESCRIPTION: Returns error code.
|
|            Error Codes: noErr    = no error                              
|                         bdNamErr = Bad file name       
|                         extFSErr = External file system
|                         fnfErr   = File not found
|                         ioErr    = I/O error
|                         nsvErr   = No such volume
|                         paramErr = No default volume
|  
| EXAMPLE: Error = GetFileInfo("TEST.SCR"); 
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY:  12.09.90. finish when needed.
|
------------------------------------------------------------*/
/* 
u16
GetFileInfo(s8* FileName)
{
   u16     Result;
   ConvertStringToBStringInPlace(FileName);
   Result = (u16) GetFInfo(FileName,vRefNum,fndrInfo);
   return( Result );
}
*/

/*------------------------------------------------------------
| IsDirectory
|-------------------------------------------------------------
|
| PURPOSE: To determine whether a path is a directory or a 
|          file.
|
| DESCRIPTION: Returns true if is a directory
|
| EXAMPLE:  
|
| NOTE: See p. IV-122 Inside Mac, p. 442 Mac Rom Encyclopedia.
|
| ASSUMES: 
|
| HISTORY: 03.22.91
|          02.02.97 added explicit volume reference.
|          08.19.97 changed 'PBGetCatInfo' to 'PBGetCatInfoSync'
|                   which is the new convention.
|          03.23.98 Revised to use 'CopyCToPascalString'.
------------------------------------------------------------*/
#if macintosh

u32
IsDirectory( s8* Path )
{
    CInfoPBRec  C;
    OSErr       error;
    s16         VolRef;
    Str255      Path_PascalFormat;
    
    // Convert the c string into a pascal string.
    CopyCToPascalString( Path, (s8*) Path_PascalFormat );
    
    // Get the volume ref num of the path.
    VolRef = GetVolumeReferenceNumberOfPath( Path );
    
    C.dirInfo.ioFDirIndex = 0; // cause name to be used 
    C.dirInfo.ioVRefNum   = VolRef; 
    C.dirInfo.ioNamePtr   = Path_PascalFormat;
    
    error = PBGetCatInfoSync( &C ); 
    
    if( C.dirInfo.ioFlAttrib & 16 ) 
    {
        return( 1 );
    }
    else
    {
        return( 0 );
    }
}

#endif // macintosh

/*------------------------------------------------------------
| IsFileType
|-------------------------------------------------------------
|
| PURPOSE: To test if a file has a certain type.
|
| DESCRIPTION: Compares a 4-byte string to the file type of
| the file and returns '1' if they are identical, else
| returns '0'.
|
| EXAMPLE:  t = IsFileType(MyFileName, "TEXT")
|
| NOTE: See p. 77 Mac Programming Secrets, p.IV-149,150  
|       InsideMac, p.456 Mac Rom.
|
| ASSUMES: File exists.
|
| HISTORY: 06.07.96 from 'SetFileType'.
|          02.02.97 added explicit volume reference.
|          03.23.98 Fixed partial use of parameter block.
------------------------------------------------------------*/
#if macintosh

u32
IsFileType( s8* Path, s8* FileType )
{
    ParamBlockRec   P;
    OSErr           err;
    u32         IsSameType; 
    s16         VolRef;
    Str255          Path_PascalFormat;
    
    // Get the volume ref num of the path.
    VolRef = GetVolumeReferenceNumberOfPath( Path );
    
    // Convert the c string into a pascal string.
    CopyCToPascalString( Path, (s8*) Path_PascalFormat );
    
    P.fileParam.ioNamePtr   = Path_PascalFormat;
    P.fileParam.ioVRefNum   = VolRef; // use the default volume 
    P.fileParam.ioFDirIndex = 0; // cause name to be used 
    P.fileParam.ioFVersNum  = 0; // Must always be zero.
    P.fileParam.ioFlVersNum = 0; // Must always be zero.
    
    err = PBGetFInfoSync( &P );
 
    // If there is an error.
    if( err )
    {
        // Trap it.
        Debugger();
    }
    else // Got the file info.
    {
        IsSameType = 
            ! CompareBytes( (u8*) &P.fileParam.ioFlFndrInfo.fdType,
                            4, 
                            (u8*) FileType, 
                            4 );
    }

    return( IsSameType );
}

#endif // macintosh

/*------------------------------------------------------------
| IsMatchingFiles
|-------------------------------------------------------------
|
| PURPOSE: To test if two files have the exact same content
|          in their data forks.
|
| DESCRIPTION: Returns '1' if the contents match exactly.
|
| EXAMPLE:  
|
| NOTE: Simple and slow. Add buffering later perhaps.
|
| ASSUMES: 
|
| HISTORY: 01.31.97
|          08.25.97 changed 'GetFileSize' to 'GetFileSize2'.
------------------------------------------------------------*/
u32
IsMatchingFiles( s8* A, s8* B )
{
    FILE*   fA;
    FILE*   fB;
    u32     ASize, BSize, i, cA, cB;
    
    fA = OpenFileTL( A, ReadAccess );
    
    if( fA == 0 )
    {
        return( 0 );
    }
    
    fB = OpenFileTL( B, ReadAccess );
    
    if( fB == 0 )
    {
        return( 0 );
    }
    
    // Do the file sizes match?
    ASize = GetFileSize2( fA );
    BSize = GetFileSize2( fB );

    if( ASize != BSize )
    {
        CloseFile( fA );
        CloseFile( fB );
        
        return( 0 );
    }
    
    // Now check for matching bytes.
    for( i = 0; i < ASize; i++ )
    {
        cA = ReadByte(fA);
        cB = ReadByte(fB);
        
        if( cA != cB )
        {
            CloseFile( fA );
            CloseFile( fB );
        
            return( 0 );
        }
    }
    
    CloseFile( fA );
    CloseFile( fB );
        
    return( 1 );
}
 
/*------------------------------------------------------------
| IsResourceFileExisting
|-------------------------------------------------------------
|
| PURPOSE: To test if the resource fork of a file exists.
|
| DESCRIPTION: 
|
| EXAMPLE: a = IsResourceFileExisting( "D:MyResFile" ); 
|
| NOTE: This loads the resource map which may slow things down.  
|       
|       There must be a faster way to do this.
|
| ASSUMES: 
|
| HISTORY: 08.21.97
------------------------------------------------------------*/
#if macintosh

u32
IsResourceFileExisting( s8* Path )
{
    s16 RefNum;
    
    // Turn off the pre-loading of resource data for now.
    SetResLoad( 0 );
    
    // Try to open the resource fork.
    RefNum = OpenResFile( (const u8*) Path );
    
    // Turn on the loading of resource data.
    SetResLoad( 1 );
    
    // If the open failed.
    if( RefNum == -1 )
    {
        return( 0 );
    }
    else // Opened OK.
    {
        // Close the resource file.
        CloseResFile( RefNum );
        
        return( 1 );
    }
}

#endif // macintosh

/*------------------------------------------------------------
| IsResourceInFile
|-------------------------------------------------------------
|
| PURPOSE: To test if a resource is in an open resource file.
|
| DESCRIPTION: Returns '1' if it is, else '0'.
|
| EXAMPLE:
|
|       t = IsResourceInFile( RefNum, 'PiMI', 16000 );
|
| NOTE: There's probably a faster way to do this than 
| actually loading the resource: optimize later. TLMARK.
|
| ASSUMES: 
|
| HISTORY: 09.10.97 TL 
------------------------------------------------------------*/
#if macintosh

u32
IsResourceInFile( 
    s16     RefNum, // Reference number of open resource file.
    ResType ResTyp, 
    s16     Index ) 
{
    Handle  h;
    
    // Get the resource from any open resource file.
    h = GetResource( ResTyp, Index );

    // If resource not found.
    if( h == 0 )
    {
        return( 0 );
    }
            
    // If the resource comes from the given file.
    if( HomeResFile( h ) == RefNum )
    {
        // Get rid of the resource.
        ReleaseResource( h );
        
        return( 1 );
    }
    else
    {
        // Get rid of the resource.
        ReleaseResource( h );
        
        return( 0 );
    }
}

#endif // macintosh

/*------------------------------------------------------------
| LoadFileToItem
|-------------------------------------------------------------
|
| PURPOSE: To load a file into dynamicly allocated list
|          item.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 12.15.96 from 'LoadFileToByteBuffer'.
|          08.25.97 changed 'GetFileSize' to 'GetFileSize2'.
------------------------------------------------------------*/
Item*
LoadFileToItem( s8* Path )
{
    FILE*   F;
    Item*   AnItem;
    u32     FileSize;
    u32     BytesRead;
    u8*     ABuffer;
    
    // Make sure the file exists.
    if( IsFileExisting( Path ) == 0 ) 
    {
        // File doesn't exist.
        return(0);
    }
    
    F = OpenFileTL( Path, ReadAccess );
    
    FileSize = GetFileSize2( F );
 
    if( FileSize == 0 ) 
    {
        CloseFile( F );
        
        return( 0 );
    }
    
    // Allocate space in the buffer for the file.
    ABuffer = (u8*) malloc( FileSize );
    
    // Read the file to the buffer.
    BytesRead = (u32)
        ReadBytes( F, ABuffer, FileSize );
    
    // Make sure the exact file size was read.
    if( BytesRead != FileSize )
    {
//      Note( "Error: FileSize: %d, BytesRead: %d\n",
//              FileSize, BytesRead );
    }
    
    // Make an Item for the buffer.
    AnItem = MakeItemForData( ABuffer );
    
    // Set the data and buffer byte counts.
    AnItem->SizeOfData   = BytesRead;
    AnItem->SizeOfBuffer = FileSize;
    
    // Close the file.
    CloseFile( F );
    
    return( AnItem );
}

/*------------------------------------------------------------
| MakeDirectoryEntryList
|-------------------------------------------------------------
|
| PURPOSE: To make a list of the names of files and 
|          sub-directories of a directory.
|
| DESCRIPTION: Returns a list of names of directory contents
| relative to the directory.
|
| EXAMPLE:  
|
|       err = MakeDirectoryEntryList( "D:A:" );
|
| returns: ( "FirstFile", "SecondFile", "ThirdFile" ... )
|
| NOTE:  
|
| ASSUMES: Enough memory to hold the list.
|
| HISTORY: 02.02.97 
------------------------------------------------------------*/
List*
MakeDirectoryEntryList( s8* Directory )
{
    List*   L;
#if macintosh
    s8*     Name;
    s32     Count,i;
    
    
    // Append a colon to the directory path if it needs one.
    MakeDirectoryPathEndInColon( Directory );
    
    // Make a list for the names.
    L = MakeList();
    
    // Count how many entries there are.
    Count = CountDirectoryEntries( Directory );
    
    // For each entry.
    for( i = 0; i < Count; i++ )
    {
        // Refer to the name.
        Name = NameOfNthDirectoryEntry( Directory, i );

        // Duplicate the name and save it in the list.
        InsertDataLastInList( L, (u8*) DuplicateString( Name ) );
    }
#else // FIX THIS LATER.
    L = 0;
    Directory = Directory;
#endif

    // Return the list of names.
    return( L );
}

/*------------------------------------------------------------
| MakeDirectoryEntryPathList
|-------------------------------------------------------------
|
| PURPOSE: To make a list of the full paths to the files and
|          sub-directories of a directory.
|
| DESCRIPTION: Returns a list of full paths to items in the
| given directory. 
|
| EXAMPLE:  
|
|       err = MakeDirectoryEntryPathList( "D:A:" );
|
| returns: ( "D:A:FirstFile", "D:A:SecondFile", ... )
|
| NOTE:  
|
| ASSUMES: Enough memory to hold the list.
|
| HISTORY: 02.02.97 from 'MakeDirectoryEntryList'.
------------------------------------------------------------*/
List*
MakeDirectoryEntryPathList( s8* Directory )
{
    List*   L;
#if macintosh
    s8*     Name;
    s32     Count, i;
    s8      Path[MaxPathLength];
    
    // Make a list for the names.
    L = MakeList();
    
    // Count how many entries there are.
    Count = CountDirectoryEntries( Directory );
    
    // For each entry.
    for( i = 0; i < Count; i++ )
    {
        // Copy the directory to the path buffer.
        CopyString( Directory, Path );
        
        // Append a colon to the directory path if it 
        // needs one.
        MakeDirectoryPathEndInColon( Path );

        // Refer to the name.
        Name = NameOfNthDirectoryEntry( Directory, i );

        // Append the name to the directory in the path.
        AppendString2( Path, Name );
        
        // Duplicate the name and save it in the list.
        InsertDataLastInList( L, (u8*) DuplicateString( Path ) );
    }
#else // FIX THIS LATER.
    Directory = Directory;
    L = 0;
#endif
    
    // Return the list of names.
    return( L );
}

/*------------------------------------------------------------
| MakeFileListDocument
|-------------------------------------------------------------
|
| PURPOSE: To make a text file that contains a list of the
|          files contained in a folder.
|
| DESCRIPTION:  
|
| EXAMPLE: Make a text file called "FileList.txt" holding the 
| full path names of all of the files in the "C:SourceFiles" 
| folder:
|            
|   MakeFileListDocument(
|       "C:SourceFiles:",
|               // Path to the folder containing the files to
|               // list in the output document.
|               //
|       "FileList.txt",
|               // Path to the output file.
|               //
|       1,      // Output the full path.
|               //
|       MacEOLString );
|               // End-of-line string to be appended to each
|               // line, a zero-terminated C string.
|
| ASSUMES: SetUpTheListSystem() has been called to set up the
|          list manager.
|
| HISTORY: 08.26.01 
------------------------------------------------------------*/
void
MakeFileListDocument(
    s8* FolderPath,
            // Path to the folder containing the files to
            // list in the output document.
            //
    s8* OutputFile,
            // Path to the output file.
            //
    u32 UseFullPath,
            // Control flag set to 1 if the full path of the
            // file should be included in the output or 0
            // if only the folder-relative file name should
            // be output.
            //
    s8* EndOfLineString )
            // End-of-line string to be appended to each
            // line, a zero-terminated C string.
            //
            // Use one of these from TLAscii.c:
            //
            //  MacEOLString, WinEOLString, UnixEOLString
{
    List* L;
    FILE* F;
    s8*   FilePath;
 
    // Make a list of the files in the folder.
    L = MakeListOfPathsToFilesInDirectory( FolderPath );

    // Open the output file for writing.
    F = OpenFileTL( OutputFile, WriteAccess );
 
    // Refer to 'L' as the current list and preserve the
    // current list context.
    ReferToList( L );
    
    // For each file found in the folder.
    while( TheItem )
    {
        // If the full path should be output.
        if( UseFullPath )
        {
            // Then the full path is the output string.
            FilePath = (s8*) TheDataAddress;
        }
        else // Use the folder-relative file name.
        {
            // Refer to the file name in the path.
            FilePath = 
                LocateFileNameInPathName( 
                    (s8*) TheDataAddress );
        }
        
        // Write the file path to the file.
        WriteTextLine( 
            F, 
                // Handle of file open for writting.
                //
            FilePath,
                // A single line of text as a zero-terminated
                // C string.
                //
            EndOfLineString );
                // End-of-line string to be appended to each
                // line, a zero-terminated C string.
                //
                // Use one of these from TLAscii.c:
                //
                //  MacEOLString, WinEOLString, UnixEOLString

        
        // Advance to the next path.
        ToNextItem();
    }
    
    // Revert to the preserved list context.
    RevertToList();
    
    // Close the file.
    CloseFile(F);
    
    // Delete the list of path name strings.
    DeleteListOfDynamicData( L );

    // If running on a Mac.
#if FOR_MACOS

    // Set the file creator to CodeWarrior IDE.
    SetFileCreator( OutputFile, "CWIE" );
    
    // Set the file type to 'TEXT'.
    SetFileType( OutputFile, "TEXT" );
    
#endif // FOR_MACOS
}   
    
/*------------------------------------------------------------
| MakeListOfPathsToFilesInDirectory
|-------------------------------------------------------------
|
| PURPOSE: To make a list of the full paths to the files of 
|          a directory, excluding any sub-directories.
|
| DESCRIPTION: Returns a list of full paths to files in the
| given directory. 
|
| EXAMPLE:  
|
|       err = MakeListOfPathsToFilesInDirectory( "D:A:" );
|
| returns: ( "D:A:FirstFile", "D:A:SecondFile", ... )
|
| NOTE:  
|
| ASSUMES: Enough memory to hold the list.
|
| HISTORY: 02.04.97 from 'MoveFilesFromFolderToFolder'.
------------------------------------------------------------*/
List*
MakeListOfPathsToFilesInDirectory( s8* DirectoryPath )
{
    List*   L;
#if macintosh
    s8*     EntryPath;
    
    // Make a list of paths to the contents of the 
    // directory.
    L = MakeDirectoryEntryPathList( DirectoryPath );
    
    ReferToList( L );
    
    // For each directory entry.
    while( TheItem )
    {
        // Refer to the entry path.
        EntryPath = (s8*) TheDataAddress;
        
        // If this is a sub-directory.
        if( IsDirectory( EntryPath ) )
        {
            // Mark the item.
            MarkItem( TheItem );
            
            // Free the path.
            free( TheDataAddress );
        }
        
        ToNextItem();
    }
    
    RevertToList();
    
    // Discard the items that referred to 
    // sub-directories.
    DeleteMarkedItems( L );
#else // FIX THIS LATER.
    DirectoryPath = DirectoryPath;
    L = 0;
#endif // macintosh

    // Return the remaining list.
    return( L );
}

/*------------------------------------------------------------
| MeasureTextFileExtent
|-------------------------------------------------------------
|
| PURPOSE: To scan a text file just to measure the length of 
|          the longest line and number of lines.
|
| DESCRIPTION: This function measures the basic textual extent
| of the file, the number of rows and columns needed to hold
| the file if it is copied into a matrix of characters.
|
| EXAMPLE:    
|
|       MeasureTextFileExtent( F, &ColCount, &RowCount );
|
| ASSUMES: A character is one byte.
|
|          No special handling is applied to tab characters
|          which can be interpreted as more than one space
|          depending on the tab stop interval.
|
| HISTORY: 08.05.01 from 'ReadTextLine'.
------------------------------------------------------------*/
void
MeasureTextFileExtent( 
    FILE* F,// Handle of an open text file.
            //
    u32*  MaxCharsPerLine, 
            // OUT: Number of characters in the longest line
            //      in the file.
            //
    u32*  RowCount )
            // OUT: Number of lines in the file.
{
    s32 CharCount, MaxCharCount;
    u32 Rows;
    
    // Start at the beginning of the file.
    ToBeginningOfFile( F );
    
    // Initialize the extent variables.
    MaxCharCount = 0;
    Rows = 0;
    
    // For every line in the file.
    while(1)
    {    
        // Read the number of characters in the current line.
        //
        // OUT: Character count or -1 at end of file.
        CharCount = MeasureTextLineSize( F );
        
        // If the end-of-file has been reached.
        if( CharCount < 0 )
        {
            // Return the size of the longest line found.
            *MaxCharsPerLine = MaxCharCount;
            
            // Return the number of rows in the file.
            *RowCount = Rows;
            
            // Exit this function.
            return;
        }
        else // A line has been measured.
        {
            // Account for the line just measured.
            Rows++;
            
            // If this line is longer than the longest one 
            // measured so far.
            if( CharCount > MaxCharCount )
            {
                // Then update the longest line.
                MaxCharCount = CharCount;
            }
        }
    }
}

/*------------------------------------------------------------
| MeasureTextLineSize
|-------------------------------------------------------------
|
| PURPOSE: To read a line of text from a DOS, Mac or Unix  
|          file just to measure the number of characters in
|          the line.
|
| DESCRIPTION: Reads the next line up to and including the
| next end-of-line sequence.
|
| Returns the number of bytes in the line read, not counting
| the end-of-line sequence.
|
| If the line is empty then 0 is returned.
|
| If end-of-file is reached then -1 is returned.
|
| If a Control Z character is encountered it is treated as
| an end-of-file marker.
|
| EXAMPLE:    
|              Size = MeasureTextLineSize( F );
|
| ASSUMES: A character is one byte.
|
| HISTORY: 08.04.01 from 'ReadTextLine'.
------------------------------------------------------------*/
s32
MeasureTextLineSize( FILE* AFile )
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

    // Count the byte.
    ByteCount++;
    
    // Go read the next byte.
    goto ReadNextByte;

/////////   
Finish://
/////////   
    
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
| MoveFileTL
|-------------------------------------------------------------
|
| PURPOSE: To move a file.
|
| DESCRIPTION: If the destination file exists, it is erased 
| and overwritten.  Then the original and the copy are 
| compared.  If they match the original is erased.  If they
| don't match the process is repeated  up to 3 times.
|
| Returns non-zero if file not moved.
|
| EXAMPLE:  
|
|       err = MoveFileTL( "D:A", "C:A" );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.31.97 from 'CopyFileTL'.
|          01.07.99 Name changed from 'MoveFile()' to 
|                   avoid name collision with NT procedure.
------------------------------------------------------------*/
s32
MoveFileTL( s8* From, s8* To )
{
    s32     CopyError;
//  s32     RenameError;
    s32     RetryCount;
    
    
    // If the paths are to the same volume then just
    // rename the file.
#if 0 // Fix this.
    if( IsPathsToSameVolume( From, To ) )
    {
        RenameError = RenameFile( From, To );
        
        return( RenameError );
    }
#endif 
    // If get here then need to copy the file.  
    
    RetryCount = 0;
    
Retry:
    
    // Copy the file.
    CopyError = CopyFileTL( From, To );
    
    // If there was an error during copy.
    if( CopyError )
    {
        RetryCount++;
        
        // If already tried three times.
        if( RetryCount > 3 )
        {
            // Return with an error.
            return( 1 );
        }
        
        // Try again.
        goto Retry;
    }
    
    // Erase the original file.
    DeleteFileTL( From );
 
    // Return NoErr.
    return( 0 );
}

/*------------------------------------------------------------
| MoveFilesFromFolderToFolder
|-------------------------------------------------------------
|
| PURPOSE: To move all of the files in a folder to another 
|          folder.
|
| DESCRIPTION: If the destination folder doesn't exist, it
| is created, then all files in the source file are moved
| to the new folder, one-by-one.
|
| Returns non-zero if not able to create a new folder
| or move files. 
|
| EXAMPLE:  
|
|       err = MoveFilesFromFolderToFolder( 
|               "D:Data:Update:Incoming:",
|               "D:Data:Update:ToParse:" );
|
| NOTE:  
|
| ASSUMES: The contents of the source folder are all files.
|
| HISTORY: 02.02.97 
|          02.04.97 installed 
|                   'MakeListOfPathsToFilesInDirectory',
|                   factored out 'MoveFilesToFolder'.
------------------------------------------------------------*/
s32
MoveFilesFromFolderToFolder( s8* SrcFolder, s8* DstFolder )
{
    List*   L;
    s32     err;
    
    // Make a list of paths to the files of the source
    // folder.
    L = MakeListOfPathsToFilesInDirectory( SrcFolder );
    
    // Move the files.
    err = MoveFilesToFolder( L, DstFolder );

    // Delete the list of file paths.
    DeleteListOfDynamicData( L );
    
    return( err );
}

/*------------------------------------------------------------
| MoveFilesToFolder
|-------------------------------------------------------------
|
| PURPOSE: To move a list of files to a folder.
|
| DESCRIPTION: If the destination folder doesn't exist, it
| is created, then all files are moved to the new folder, 
| one-by-one.
|
| Returns non-zero if not able to create a new folder
| or move files. 
|
| EXAMPLE:  
|
|       err = MoveFilesToFolder( 
|               AListOfFilePaths,
|               "D:Data:Update:ToParse:" );
|
| NOTE:  
|
| ASSUMES: The contents of the source folder are all files.
|
| HISTORY: 02.04.97 from 'MoveFilesFromFolderToFolder'.
------------------------------------------------------------*/
s32
MoveFilesToFolder( List* L, s8* DstFolder )
{
    s32     err;
#if macintosh
    s8      Path[MaxPathLength];
    s8*     SrcPath;
    s8*     FileInFolder;
    
    // If there are no files, just return.
    if( L->ItemCount == 0 )
    {
        return(0);
    }
    
    // Make the destination folder if it doesn't exist.
    err = CreateNestedDirectory( DstFolder );
    
    if( err ) 
    {
        return( -1 );
    }
    
    ReferToList( L );
    
    // For each file in the folder.
    while( TheItem )
    {
        // Refer to the source path.
        SrcPath = (s8*) TheDataAddress;
        
        // Refer to the folder relative file name.
        FileInFolder = 
                LocateFileNameInPathName( SrcPath );
            
        // Make a path name to the new folder.
        CopyString( DstFolder, Path );
        
        MakeDirectoryPathEndInColon( Path );
            
        AppendString2( Path, FileInFolder );
            
        // Move the file.
        err = MoveFileTL( SrcPath, Path );
            
        if( err )
        {
            goto Done;
        }
        
        ToNextItem();
    }

Done:
    
    RevertToList();
#else // FIX THIS LATER.
    L = L;
    DstFolder = DstFolder;
    err = 0;
#endif // macintosh

    return( err );
}
/*------------------------------------------------------------
| NameOfNthDirectoryEntry
|-------------------------------------------------------------
|
| PURPOSE: To get the name of the nth file/subdirectory in a 
|          directory.
|
| DESCRIPTION: Returns the folder-relative name of the
|              nth directory entry, eg. "AFile", not
|              the full path like "D:AFolder:AFile".
|
| EXAMPLE:  
|
| NOTE: See p. 77 Mac Programming Secrets, p.IV-149 InsideMac, 
|       p.456 Mac Rom.
|
| ASSUMES: FileIndex is valid, and 0-based.
|          Directory exists.
|
| HISTORY: 04.01.91
|          06.10.96 validated.
|          12.29.96 added explicit setting of volume ref num
|                   to allow access to other than the default
|                   volume.
------------------------------------------------------------*/
#if macintosh

s8*
NameOfNthDirectoryEntry( s8* Directory,  // Path of directory.
                         s32 FileIndex )
{
    CInfoPBRec      Info;
    CInfoPBRec      FInfo;
    OSErr           err;
    s16         VolRef;
    static Str255   FileNameBuffer;
    Str255          Path_PascalFormat;
    
    // Get the volume ref num of the path.
    VolRef = GetVolumeReferenceNumberOfPath( Directory );
    
    // Convert the c string into a pascal string.
    CopyCToPascalString( Directory, (s8*) Path_PascalFormat );
    
    // first get directory identifiers given name
    Info.dirInfo.ioFDirIndex = 0; // cause name to be used.
    Info.dirInfo.ioVRefNum   = VolRef; 
    Info.dirInfo.ioNamePtr   = Path_PascalFormat;
    
    err = PBGetCatInfoSync( &Info );  

    // now get file name of nth file in directory
    FInfo.hFileInfo.ioDirID   = Info.dirInfo.ioDrDirID; 
    FInfo.hFileInfo.ioVRefNum = Info.dirInfo.ioVRefNum;
     
    // 1-based index needed here.
    FInfo.hFileInfo.ioFDirIndex = (s16) FileIndex + 1; 
    FInfo.hFileInfo.ioNamePtr   = FileNameBuffer; 
    FileNameBuffer[0] = 0; 
    
    err = PBGetCatInfoSync( &FInfo );  

    if( err != fnfErr && err != dirNFErr )
    {
        // convert pascal to c string in place see pascal.h 
        p2cstr( (StringPtr) FileNameBuffer);  
    }
    else // An error so no name.
    {
        FileNameBuffer[0] = 0;
    }
    
    return( (s8*) FileNameBuffer );
}

#endif // macintosh

/*------------------------------------------------------------
| NameOfNthFile
|-------------------------------------------------------------
|
| PURPOSE: To get the name of the nth file in a directory.
|
| DESCRIPTION: Ignores subdirectories if any.
|
|             n is zero-based.
| EXAMPLE:  
|
| NOTE: See p. 77 Mac Programming Secrets, p.IV-149 InsideMac, 
|       p.456 Mac Rom.
|
| ASSUMES: FileIndex is valid.
|          Directory exists.
|
| HISTORY: 06.10.96 
|          08.25.97 factored out 
|                   'MakeDirectoryPathEndInColon'.
------------------------------------------------------------*/
s8*
NameOfNthFile(s8* Directory, s32 FileIndex)
{
    static s8 NameBuffer[256];
#if macintosh
    s32     FirstFileIndex;
    s32     i;
    s8*     EntryName;
    s8  EntryPath[256];
    
    // Find the index of the first file in the directory.
    FirstFileIndex = 0;
    
Another:    
    // Get the name of the directory entry.
    EntryName = 
            NameOfNthDirectoryEntry( Directory, FirstFileIndex );
            
    // Make a full path for the entry.
    CopyString( Directory, EntryPath );
 
    // If the directory name doesn't end in a ':',
    // add one.
    MakeDirectoryPathEndInColon( EntryPath );
        
    AppendStrings( EntryPath, EntryName, 0 );

    if( IsDirectory( EntryPath ) )
    {
        FirstFileIndex++;
        goto Another;
    }
    
    // The entry index of the first file is known here.
    
    // Advance to the nth file.
    for( i = 0; i < FileIndex; i++ )
    {
        // Advance to the next file.
Another2:
        FirstFileIndex++;
        
        EntryName = 
            NameOfNthDirectoryEntry( Directory, FirstFileIndex );
            
        // Make a full path for the entry.
        CopyString( Directory, EntryPath );
        
        // If the directory name doesn't end in a ':',
        // add one.
        MakeDirectoryPathEndInColon( EntryPath );
        
        AppendStrings( EntryPath, EntryName, 0 );

        if( IsDirectory( EntryPath ) )
        {
            goto Another2;
        }
    }
    
    // Make a permanent copy of the file name.
    CopyString( EntryName, NameBuffer );
#else // FIX THIS LATER.
    Directory = Directory;
    FileIndex = FileIndex;
    NameBuffer[0] = 0;
#endif // macintosh
    
    // Return the entry name.
    return( NameBuffer );
}

/*------------------------------------------------------------
| NameOfNthSubDirectory
|-------------------------------------------------------------
|
| PURPOSE: To get the name of the nth sub-directory in a 
|          directory.
|
| DESCRIPTION: Ignores files if any.
|
| EXAMPLE:  
|
| NOTE: See p. 77 Mac Programming Secrets, p.IV-149 InsideMac, 
|       p.456 Mac Rom.
|
| ASSUMES: FileIndex is valid.
|          Directory exists.
|
| HISTORY: 06.10.96 from 'NameOfNthFile'.
|          08.25.97 factored out 'MakeDirectoryPathEndInColon'.
------------------------------------------------------------*/
s8*
NameOfNthSubDirectory(s8* Directory, s32 FileIndex)
{
    static s8 NameBuffer[128];
#if macintosh
    s32     FirstDirIndex;
    s32     i;
    s8*     EntryName;
    s8  EntryPath[128];
    
    // Find the index of the first subdirectory in the directory.
    FirstDirIndex = 0;
    
Another:    
    // Get the name of the directory entry.
    EntryName = 
            NameOfNthDirectoryEntry( Directory, FirstDirIndex );
            
    // Make a full path for the entry.
    CopyString( Directory, EntryPath );
    
    // If the directory name doesn't end in a ':',
    // add one.
    MakeDirectoryPathEndInColon( EntryPath );

        
    AppendStrings( EntryPath, EntryName, 0 );
            
    if( ! IsDirectory( EntryPath ) )
    {
        FirstDirIndex++;
        goto Another;
    }
    
    // The entry index of the first file is known here.
    
    // Advance to the nth file.
    for( i = 0; i < FileIndex; i++ )
    {
        // Advance to the next file.
Another2:
        FirstDirIndex++;

        EntryName = 
            NameOfNthDirectoryEntry( Directory, FirstDirIndex );
        
        // Make a full path for the entry.
        CopyString( Directory, EntryPath );

        // If the directory name doesn't end in a ':',
        // add one.
        MakeDirectoryPathEndInColon( EntryPath );
        
        AppendStrings( EntryPath, EntryName, 0 );
            
        if( ! IsDirectory( EntryPath ) )
        {
            goto Another2;
        }
    }
    
    // Make a permanent copy of the file name.
    CopyString( EntryName, NameBuffer );
    
#else // FIX THIS LATER.

    Directory = Directory;
    FileIndex = FileIndex;
    NameBuffer[0] = 0;
        
#endif // macintosh
    
    // Return the entry name.
    return( NameBuffer );
}


/*------------------------------------------------------------
| OpenFileLowLevel
|-------------------------------------------------------------
|
| PURPOSE: To open a file for reading or writing using the
|          low level file access routines.
|
| DESCRIPTION: Returns a positive number which is the file 
| reference number or halts in the debugger if there is an
| error, then returns the error code.
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
|       n = OpenFileLowLevel( "MyDrive:MyFile",
|                             AVolRefNum,
|                             TheParentDirID,
|                             ReadWriteAccess );
|
| NOTE: See page 592 of "DOS Programmers Reference, 2nd Ed".
|       See page 2-183 of IM Files.
|
| ASSUMES: The existence of the file.
|
|          System 7 and above.
|
| HISTORY:  03.19.98 from 'OpenFileTL'.
|           03.23.98 added setting of 'ioFVersNum' and
|                    'ioFlVersNum'; added error return value.
------------------------------------------------------------*/
#if macintosh

s16
OpenFileLowLevel( s8*   Path,
                  s32   VolRefNum, 
                  s32   ParentDirID, 
                  s32   AccessMode )
{
    HParamBlockRec  H;
    OSErr           err;
    Str255          Path_PascalString;
    
    // Convert the c string into a pascal string.
    CopyCToPascalString( Path, (s8*) Path_PascalString );
    
    // Set up the parameter block.
    H.fileParam.ioNamePtr    = Path_PascalString;
    H.fileParam.ioVRefNum    = (s16) VolRefNum;
    H.fileParam.ioDirID      = ParentDirID;
    H.fileParam.ioFVersNum   = 0; // Must always be zero.
    H.fileParam.ioFlVersNum  = 0; // Must always be zero.
    
    // Strip off any DOS-specific attributes.
    AccessMode &= 7; 
    
    // Convert access mode code to what low level calls
    // expect.
    switch( AccessMode )
    {
        case ReadWriteAccess:
        {
            H.ioParam.ioPermssn = fsRdWrPerm;
            break;
        }
        case ReadAccess:
        {
            H.ioParam.ioPermssn = fsRdPerm;
            break;
        }
        case WriteAccess:
        {
            H.ioParam.ioPermssn = fsWrPerm;
            break;
        }
    }
    
    // Open the file.
    err = PBHOpenDFSync( &H );
    
    // If there was an error.
    if( err )
    {
        // Trap the error.
        Debugger();
        
        // Return the error.
        return( err );
    }
    else // No error.
    {
        // Return the file reference number.
        return( H.ioParam.ioRefNum );
    }
}

#endif // macintosh
    
/*------------------------------------------------------------
| ReadBytesLowLevel
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
| ASSUMES: File is open and current file pointer is positioned.
|
| HISTORY: 03.22.98 from 'ReadBytes'.
------------------------------------------------------------*/
#if macintosh

s32
ReadBytesLowLevel( 
    s32 FileRefNum,
    u8* BufferPointer,
    s32 ByteCount )
{
    ParamBlockRec   H;
    OSErr           err;
    
    // Set up the parameter block.
    H.ioParam.ioRefNum     = (s16) FileRefNum;
    H.ioParam.ioBuffer     = (char*) BufferPointer;
    H.ioParam.ioReqCount   = ByteCount;
    H.ioParam.ioVersNum    = 0; // Must always be zero.
    
    // Read relative to the current file position.
    H.ioParam.ioPosMode    = fsAtMark | UseCacheOption;
    H.ioParam.ioPosOffset  = 0;

    // Read the bytes from the file.
    err = PBReadSync( &H );
    
    // If there is an error.
    if( err != noErr ||
        H.ioParam.ioActCount != ByteCount )
    {
        return(-1);
    }
    
    // Return the number of bytes actually read.                   
    return( H.ioParam.ioActCount );
}

#endif // macintosh


/*------------------------------------------------------------
| ReadNumber
|-------------------------------------------------------------
|
| PURPOSE: To read a whitespace delimited ASCII number from 
|          the current file and position.
|
| DESCRIPTION: Returns the number and leaves the file 
| positioned after the first whitespace character or EOF.
|
| Returns NoNum if EOF.
|
| If a ':' character is encountered, the remainder of the
| line is ignored as a comment.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 05.19.97
|          08.19.97 fixed buffer not being cleared.
------------------------------------------------------------*/
f64
ReadNumber( FILE* F )
{
    s32  c;
    s8   buf[60];
    s32  i;
    
    // Clear the buffer.
    buf[0] = 0;
    i = 0;
    
    // Advance to the number string skipping non-number bytes.
A:
    c = fgetc( F );
    
    // If this is end of file.
    if( c == EOF )
    {
        // Just return 0.
        return( NoNum );
    }
    
    // If this is a back slash character.
    if( c == ':' )
    {
        // Consume characters until the next new line.
AA:     c = fgetc( F );
        
        if( c != '\n' ) 
        {
            goto AA;
        }
    }
        
    // If this is a whitespace character, skip it.
    if( c == ' ' || 
        c == '\t' || 
        c == '\n' ||
        c == '\r' )
    {
        goto A;
    }
    
    // Read bytes to the buffer until the next whitespace character.
    buf[i++] = (s8) c;
    
B:
    c = fgetc( F );
    
    // If this is end of file.
    if( c == EOF )
    {
        // Just return 0.
        return( NoNum );
    }
    
    // If this is a whitespace character then convert the number string.
    if( c == ' '  || 
        c == '\t' || 
        c == '\n' ||
        c == '\r' )
    {
        // Append string terminator.
        buf[i] = 0;
        
        // Convert the string to a number if possible.
        return( ConvertStringTof64( buf ) );
    }
    else // Add the byte to the string.
    {
        buf[i++] = (s8) c;
        
        // And get the next byte.
        goto B;
    }
}

/*------------------------------------------------------------
| SaveBytesToFileCompressed
|-------------------------------------------------------------
|
| PURPOSE: To save some bytes to a file from a given buffer,
|          in compressed form. 
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
| HISTORY: 07.06.96 from 'SaveBytesToFile'.
------------------------------------------------------------*/
void
SaveBytesToFileCompressed( s8* Path, u8* Buf, u32 Count )
{
    BIT_FILE*   F;

    F = OpenOutputBitFile( Path );
    
    CompressBytesToFile( F, Buf, Count );

    CloseOutputBitFile( F );
}

#if 0
/*------------------------------------------------------------
| SaveBytesToFileSafely
|-------------------------------------------------------------
|
| PURPOSE: To save some bytes to a file from a given buffer
|          using a method that reduces possibility of
|          file corruption. 
|
| DESCRIPTION: Writes data to a temp file then exchanges the
| directory entries for the temp file and the desired file,
| and then deletes the temp file and flushes the volume 
| information.  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES:  
|
| HISTORY: 07.04.96 from 'SaveBytesToFile'.
------------------------------------------------------------*/
s32
SaveBytesToFileSafely( s8* Path, u8* Buffer, s32 Count )
{
    FILE*   F;
    
    F = ReOpenFile(Path);

    WriteBytes( F, Buffer, Count );
    
    CloseFile(F);
}
#endif 

/*------------------------------------------------------------
| SeekToDelimiter
|-------------------------------------------------------------
|
| PURPOSE: To seek to the first byte following the given 
|          delimiter in the input file, optionally outputting 
|          non-delimiter bytes to an output file.
|
| DESCRIPTION: Returns relative offset of the beginning of 
|              the delimiter or 0 if not found.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  09.22.89    
------------------------------------------------------------*/
u32
SeekToDelimiter( FILE* InputFile, 
                 FILE* OutputFile, 
                 u8* DelimiterAddress, 
                 u16          DelimiterCount )
{
    u32 RelativeOffset;
    u8  SuspensionBuffer[MAX_DELIMITER_SIZE];
    u32 Found, PrefixValid;
    u16 Index;
    u16 OutIndex;
    s16 AWord;

    Found = 0;
    RelativeOffset = 0;
    Index = 0;

    while( (AWord = ReadByte(InputFile)) != EOF )   
    {   
        SuspensionBuffer[Index] = (u8) AWord;
        RelativeOffset++;

        if(SuspensionBuffer[Index] == DelimiterAddress[Index]) 
        {
            if( Index == DelimiterCount-1 )
            {
                Found = 1;
                break;
            }
            else
            {
                Index++;
            }
        }
        else
        {
            if( OutputFile ) WriteBytes( OutputFile, 
                       (u8*) SuspensionBuffer, 1 );

            if( Index )
            {
                CopyBytes( (u8*) SuspensionBuffer+1, 
                           (u8*) SuspensionBuffer, 
                           (u32) Index );

                PrefixValid = 0;

                while(!PrefixValid && Index)
                {
                    OutIndex = 0;
                    PrefixValid = 1;
                    while(OutIndex++ < Index)
                    {
                        PrefixValid = PrefixValid && 
                                      (SuspensionBuffer[OutIndex] == 
                                      DelimiterAddress[OutIndex-1]);
                    }
                    if(!PrefixValid) 
                    {
                        if(OutputFile) 
                        {
                          WriteBytes( OutputFile, 
                                      (u8*) SuspensionBuffer, 
                                      1 );
                        }
                        CopyBytes( (u8*) SuspensionBuffer+1, 
                                   (u8*) SuspensionBuffer, 
                                   (u32) Index );
                        Index--;
                    }
                }
            }
        }
    }

    if( !Found ) RelativeOffset = 0;

    return( RelativeOffset );
}

/*------------------------------------------------------------
| SetFileCreator
|-------------------------------------------------------------
|
| PURPOSE: To set the 4-byte file creator ID for an 
|          existing file.
|
| DESCRIPTION: 
|
| EXAMPLE:  SetFileCreator(MyFileName, "CWIE")
|
| NOTE: See p. 77 Mac Programming Secrets, p.IV-149,150  
|       InsideMac, p.456 Mac Rom.
|
| ASSUMES: File exists.
|
| HISTORY: 12.15.93
|          12.17.93 revised to use 'PBGetFInfoSync' --
|                   copied from 'fopen.c'.
|          02.02.97 added explicit volume.
|          03.23.98 Fixed use of partial parameter block.
------------------------------------------------------------*/
#if macintosh

void
SetFileCreator( s8* Path, s8* ACreator )
{
    OSErr           err;
    s16         VolRef;
    ParamBlockRec   P;
    Str255          Path_PascalFormat;
    
    // Convert the c string into a pascal string.
    CopyCToPascalString( Path, (s8*) Path_PascalFormat );
    
    // Get the volume ref num of the path.
    VolRef = GetVolumeReferenceNumberOfPath( Path );
    
    P.fileParam.ioNamePtr   = Path_PascalFormat;
    P.fileParam.ioVRefNum   = VolRef; 
    P.fileParam.ioFVersNum  = 0; // Must always be zero.
    P.fileParam.ioFlVersNum = 0; // Must always be zero.
    P.fileParam.ioFDirIndex = 0; // cause name to be used 
    
    err = PBGetFInfoSync( &P );

    if( err == noErr )
    {
        CopyBytes((u8*) ACreator, 
                  (u8*) &P.fileParam.ioFlFndrInfo.fdCreator,
                  (u32) 4);
    
        err = PBSetFInfoSync( &P );
    }
}

#endif // macintosh

/*------------------------------------------------------------
| SetFilePositionLowLevel
|-------------------------------------------------------------
|
| PURPOSE: To set file position given an offset from the 
|          beginning of the file.
|
| DESCRIPTION: First flushes the file so that any previously
| written data in the access buffer will be updated to disk
| before the file position is changed.
|
| Returns one of the following result codes:
|
|   noErr       0   No error
|   ioErr     -36   I/O error
|   fnOpnerr  -38   File not open
|   eofErr    -39   Logical end-of-file reached
|   posErr    -40   Attempt to position mark before start
|                   of file.
|   rfNumErr  -51   Bad reference number.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: File is less than 2 gig.
|
|          No caching of data.
|
| HISTORY:  03.22.98
|           10.27.98 Added passing of result code.
|           11.04.98 Added resizing of file on EOF error so 
|                    the function works more like 'fseek()'.
------------------------------------------------------------*/
#if macintosh

OSErr
SetFilePositionLowLevel( s32 FileRefNum, u32 ByteOffset )
{
    OSErr   err;
    
    // Change the file position.
    err = SetFPos( (s16) FileRefNum, 
                   (s16) fsFromStart | UseCacheOption, 
                   (s32) ByteOffset );
                   
    // If an end-of-file error occurred.
    if( err == eofErr )
    {
        // Call the low-level routine to set the logical 
        // end-of-file.
        SetEOF( FileRefNum, ByteOffset + 1 );
        
        // Try to set the file position again.
        err = SetFPos( (s16) FileRefNum, 
                       (s16) fsFromStart | UseCacheOption, 
                       (s32) ByteOffset );
    }
                   
    // Return the seek result code.
    return( err );
}

#endif // macintosh

/*------------------------------------------------------------
| SetFileType
|-------------------------------------------------------------
|
| PURPOSE: To set the 4-byte file type for an existing file.
|
| DESCRIPTION: 
|
| EXAMPLE:  SetFileType( MyFileName, "TEXT" );
|
| NOTE: See p. 77 Mac Programming Secrets, p.IV-149,150  
|       InsideMac, p.456 Mac Rom.
|
| ASSUMES: File exists.
|
| HISTORY: 05.25.91
|          12.17.93 revised to use 'PBGetFInfoSync' --
|                   copied from 'fopen.c'. 
|          02.02.97 added explicit volume ref.
|          03.23.98 Fixed use of partial parameter block.
------------------------------------------------------------*/
#if macintosh

void
SetFileType( s8* Path, s8* FileType )
{
    OSErr           err;
    s16         VolRef;
    ParamBlockRec   P;
    Str255          Path_PascalFormat;
    
    // Convert the c string into a pascal string.
    CopyCToPascalString( Path, (s8*) Path_PascalFormat );

    // Get the volume ref num of the path.
    VolRef = GetVolumeReferenceNumberOfPath( Path );
    
    P.fileParam.ioNamePtr   = (StringPtr) Path;
    P.fileParam.ioVRefNum   = VolRef; 
    P.fileParam.ioFVersNum  = 0; // Must always be zero.
    P.fileParam.ioFlVersNum = 0; // Must always be zero.
    P.fileParam.ioFDirIndex = 0; // cause name to be used
    
    err = PBGetFInfoSync( &P );
 
    if( err == noErr )
    {
        CopyBytes((u8*) FileType, 
                  (u8*) &P.fileParam.ioFlFndrInfo.fdType,
                  (u32) 4);
    
        err = PBSetFInfoSync( &P );
    }
}

#endif // macintosh

/*------------------------------------------------------------
| WriteByteLowLevel
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
| HISTORY:  03.22.98 from 'WriteByte'.
------------------------------------------------------------*/
#if macintosh
u16
WriteByteLowLevel( s32 FileRefNum, u16 AByte )
{
    u16     Result;
    u8      BByte;
    
    BByte = (u8) AByte;
    
    Result = (u16) 
             WriteBytesLowLevel( FileRefNum, 
                                 (u8*) &BByte, 
                                 1 );
    return( Result );
}
#endif // macintosh

/*------------------------------------------------------------
| WriteBytesLowLevel
|-------------------------------------------------------------
|
| PURPOSE: To write bytes from a buffer to a file.
|
| DESCRIPTION: returns bytes written and traps errors.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: File is open and current file pointer is positioned.
|
| HISTORY: 03.22.98 from 'WriteBytes'.
------------------------------------------------------------*/
#if macintosh

u32
WriteBytesLowLevel( 
    s32 FileRefNum,
    u8* BufferPointer,
    u32 ByteCount )
{
    ParamBlockRec   H;
    OSErr           err;
    
    // Set up the parameter block.
    H.ioParam.ioCompletion = 0;
    H.ioParam.ioRefNum     = (s16) FileRefNum;
    H.ioParam.ioBuffer     = (char*) BufferPointer;
    H.ioParam.ioReqCount   = ByteCount;
    H.ioParam.ioVersNum    = 0; // Must always be zero.
    
    // Write relative to the current file position.
    H.ioParam.ioPosMode    = fsAtMark | UseCacheOption;
    H.ioParam.ioPosOffset  = 0;

    // Write the bytes to the file.
    err = PBWriteSync( &H );
    
    // If there is an error.
    if( err != noErr ||
        H.ioParam.ioActCount != ByteCount )
    {
        Debugger();
    }
    
    // Return the number of bytes actually written.                
    return( H.ioParam.ioActCount );
}

#endif // macintosh

/*------------------------------------------------------------
| WriteNumber
|-------------------------------------------------------------
|
| PURPOSE: To write a whitespace delimited ASCII number at 
|          the current file and position.
|
| DESCRIPTION: Writes the number string followed by '\n'.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: MaxCountOfNumberStringDigits > 30.
|
| HISTORY: 05.19.97
|          07.31.97 limited number of digits to 30.
------------------------------------------------------------*/
u32
WriteNumber( FILE* F, f64 n )
{
    u32  Result;
    s8*  S;
        
    // Convert the number to a string.
    UseScientificFormat = 0;
    S = ConvertNumberToString( (Number) n );

    // Put a string terminator at 30.
    S[30] = 0;
    
    Result = (u32) fprintf( F, "%s\n", S );
    
    return( Result );
}

/*------------------------------------------------------------
| WriteNumberWithComment
|-------------------------------------------------------------
|
| PURPOSE: To write a whitespace delimited ASCII number at 
|          the current file and position followed by " : "
|          and a comment terminated by the end of the line.
|
| DESCRIPTION: Writes the number string followed by a 
| comment and a new line character:
|
|        2342.2323 : This is the item count.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 06.06.97 from 'WriteNumber'.
------------------------------------------------------------*/
u32
WriteNumberWithComment( FILE* F, f64 n, s8* Comment )
{
    u32  Result;
    s8*  S;
        
    // Convert the number to a string.
    UseScientificFormat = 0;
    S = ConvertNumberToString( (Number) n );

    Result = (u32) fprintf( F, "%s : %s \n", S, Comment );
    
    return( Result );
}
