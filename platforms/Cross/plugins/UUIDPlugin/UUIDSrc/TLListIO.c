/*------------------------------------------------------------
| TLListIO.c
|-------------------------------------------------------------
|
| PURPOSE: To support the reading and writing of lists of 
|          data.
|
| HISTORY: 12.10.93 
|
-------------------------------------------------------------*/

#include <stdlib.h>
#include <stdio.h>

#include "TLTypes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLAscii.h"
#include "TLList.h"
#include "TLByteBuffer.h"
#include "TLFile.h"
#include "TLFileExtra.h"
#include "TLDyString.h"
#include "TLListIO.h"


/*------------------------------------------------------------
| ReadListOfTextLines
|-------------------------------------------------------------
|
| PURPOSE: To read a file as a list of text lines.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|           AList = ReadListOfTextLines("MyData");
| NOTE:  
|
| ASSUMES: List system setup.
|
|          The given file exists.
|
|          Sufficient item records available to hold the 
|             each line in the text file.
|
|          Sufficient memory to hold line data.
|
|          List will be deleted using 
|             'DeleteListOfDynamicData'.
|
| HISTORY: 12.11.93 
|          03.08.94 open file error check added.
|          07.09.97 changed to 'ReadTextLine' from 
|                   'ReadMacTextLine'.
------------------------------------------------------------*/
List*
ReadListOfTextLines(s8* AFileName)
{
    List*   AList;
    FILE*   AFile;
    s8      ABuffer[MaxLineBuffer];
    s16     ByteCount;
    s8      *AString;
    
    AFile = OpenFileTL(AFileName, ReadAccess);

    if(AFile == 0)
    {
        return(0);
    }

    AList = MakeList();
    
ReadLine:
    
    ByteCount = ReadTextLine( AFile, ABuffer );
        
    if(ByteCount == -1) goto Done;
        
    AString = DuplicateString(ABuffer);
        
    InsertDataLastInList( AList, (u8*) AString );
        
    goto ReadLine;
    
Done:
    CloseFile(AFile);
    
    return(AList);
}

/*------------------------------------------------------------
| WriteListOfTextLines
|-------------------------------------------------------------
|
| PURPOSE: To write a list of text lines to a file.
|
| DESCRIPTION: If the file exists it is recreated.
|
| EXAMPLE:  
|           WriteListOfTextLines("MyData", MyList);
| NOTE:  
|
| ASSUMES: List system setup.
|
|          Enough room exists on disk for the file.
|
| HISTORY: 12.12.93 
|          05.02.01 Added end-of-line parameter.
------------------------------------------------------------*/
void
WriteListOfTextLines(
    s8*     FilePath, 
                // Path to the file to be (re)written.
                //
    List*   AList,
                // List of text lines, one line string per 
                // item as a C string with no end-of-line 
                // characters.
                //
    s8*     EndOfLineString )
                // End-of-line string to be appended to each
                // line, a zero-terminated C string.
                //
                // Use one of these from TLAscii.c:
                //
                //  MacEOLString, WinEOLString, UnixEOLString
{
    FILE*   AFile;
    
    ReferToList( AList ); 
    
    AFile = ReOpenFile(FilePath);

    while(TheItem)
    {
        // Write the current text line to the file.
        WriteTextLine( 
            AFile, 
                // Handle of file open for writting.
                //
            (s8*) TheDataAddress,
                // A single line of text as a zero-
                // terminated C string.
                //
            EndOfLineString );
                // End-of-line string to be appended 
                // to each line, a zero-terminated C 
                // string.
                
        ToNextItem();
    }
        
    CloseFile(AFile);
    
#if macintosh
    // Set the file to an CW document for now. 
    SetFileType(FilePath,(s8*) "TEXT");
    SetFileCreator(FilePath,(s8*) "CWIE");
#endif
    
    RevertToList();
}
