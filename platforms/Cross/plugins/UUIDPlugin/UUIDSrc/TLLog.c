/*------------------------------------------------------------
| TLLog.c
|-------------------------------------------------------------
|
| PURPOSE: To provide application log functions.
|
| HISTORY: 12.09.96
------------------------------------------------------------*/

#include <stdarg.h>
#include <string.h>
#include <stdio.h>

#include "TLTypes.h"
#include "TLAscii.h"
#include "TLBytes.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLDyString.h"

#ifdef macintosh
#include "TimePPC.h"
#else
#include "TLTimeNT.h"
#endif
  
#include "TLLog.h"

u32     IsLogEnabled = 0;
                // 1 if the application log can accept 
                // new entries.

u32     IsLogWindowOutputEnabled = 0;
                // 1 if the application log can output
                // new entries in a text window.

u32     IsLogFileOutputEnabled = 0;
                // 1 if the application log can output
                // new entries in a text file.

s8      TheLogFilePath[256];
                // This refers the path of the text file to 
                // be used for the application log.

FILE*   TheLogFile2 = 0;
                // If non-zero, the file pointer for the log 
                // file.

s32     LogCharsInLine = 0; 
                // Number of characters in the current line.
                
s32     LogIndentOnWrap = 0;
                // Number of characters to indent when a line
                // wrap occurs.
                
s32     LineWrapLimit = 80;
                // The number of characters in a line, beyond 
                // which a line wrap occurs.
                 
/*------------------------------------------------------------
| CleanUpTheLog 
|-------------------------------------------------------------
|
| PURPOSE: To clean up the application log.
|
| DESCRIPTION: Closes the log file, if any, and sets the type 
| to be a text file with creator the same as CW.
| 
| Closes the log text window if any and discards it.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
|           
| HISTORY: 12.11.96
|          01.06.97 added flushing of pending notes.
------------------------------------------------------------*/
void
CleanUpTheLog()
{
    if( TheLogFile2 )
    {
        fclose( TheLogFile2 );
        
        TheLogFile2 = 0;
    }
    
    IsLogEnabled = 0;
}

/*------------------------------------------------------------
| DumpHex
|-------------------------------------------------------------
|
| PURPOSE: To dump bytes in ASCII hex form.
|
| DESCRIPTION: Outputs the hex codes, 64 per line.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 04.06.00 From DumpTsPacket,
------------------------------------------------------------*/
void
DumpHex( u8* AtBytes, u32 ByteCount )
{
    s8  Text[90];
    s8* A;
    u8  h;
    
    // Refer to the first output byte.
    A = Text;
    
    // For each source byte.
    while( ByteCount-- )
    {
        // Get the byte.
        h = *AtBytes++;
        
        // Ordering is [Hi-nibble][Lo-nibble] 
        *A++ = HexDigit[ (h >> 4) & 0x0f ]; 
         
        *A++ = HexDigit[ h & 0x0f ];
        
        // If a full line has been generated.
        if( ( A - Text ) == 64 )
        {
            // Append a zero byte.
            *A = 0;

            // Output the line.
            Note("%s\n", Text );
            
            // Refer to the first output byte.
            A = Text;
        }
    }
    
    // If there are any undumped bytes.
    if( A > Text )
    {
        // Append a zero byte.
        *A = 0;
        
        Note( "%s\n", Text );
    }
}

/*------------------------------------------------------------
| HexDump
|-------------------------------------------------------------
|
| PURPOSE: To dump a range of bytes as their ASCII hex 
|          equivalent with ASCII character interpretation.
|
| DESCRIPTION: Outputs the hex codes, 64 per line.
|
| INPUT:
| 
|    F - handle of output file, use 'stdout' for print
|        to standard output.
|
|    Address - source address of the bytes to be dumped.
|
|    ByteCount - number of source bytes to dump.
|
| HISTORY: 12.20.00 TL From HEXDUMP.C, originally written 
|                      by Paul Edwards, released to the 
|                      public domain. Modified for SNIPPETS 
|                      by Bob Stout.  Extended address to
|                      8 digits from 6.
------------------------------------------------------------*/
void
HexDump( FILE* F, u8* Address, u32 ByteCount )
{
    s32   c, pos1, pos2, posn;
    u32   x;
    s8    prtln[80];
    u8*   Addr;
 
    x = 0L;
    posn = (int)(((u32) Address) % 16L);
    
    // Refer to the first byte.
    Addr = Address;
    
    // Until all of the bytes have been dumped.
    while( x != ByteCount )
    {
        // Get a byte and put it into an 'int'
        // without sign extending it.
        c = (int) (u32) *Addr++;
        
        // If this is the first byte or on a
        // 16 byte boundary.
        if( 0 == (posn % 16) || 0 == x )
        {
            // Fill the output line with spaces.
            memset( prtln,' ', sizeof( prtln ) );
           
            // Insert the address at the beginning
            // of the line.
            sprintf( prtln, "%0.8X:", Address + x );
            
            // Replace the terminal zero with a space.
            prtln[9] = ' ';
            
            // Calculate the address of the hex characters
            // for the byte on the line.
            pos1 = 10 + (int)(3 * posn);
           
            // Adjust for the spacing between every four
            // bytes.
            if (posn > 3)  ++pos1;
            if (posn > 7)  ++pos1;
            if (posn > 11) ++pos1;
            
            // Calculate the address of the ASCII
            // equivalent for the character.
            pos2 = 62 + (int)(posn);
        }
        
        // Add the byte to the line.
        sprintf( prtln + pos1, "%0.2X ", c );
      
        // If the byte is a printable ASCII character.
        if( IsPrintableASCIICharacter(c) )
        {
            sprintf( prtln + pos2, "%c", c );
        }
        else  
        {
            sprintf( prtln + pos2, "." );
        }
        
        // Advance the character position.
        pos1 += 3;
        
        // Replace the terminal zero with a space.
        *(prtln+pos1) = ' ';
        
        // Advance the ascii character position.
        pos2++;
        
        // Put a space every four bytes.
        if( posn % 4 == 3 )
        {
            pos1++;
        }
        
        // If an entire line has been made.
        if( posn % 16 == 15 )
        {
            // Output the line.
            fprintf(F, "%s\n", prtln);
           
            posn = 0;
        }
        else  
        {
            ++posn;
        }
      
        // Account for the byte added.
        ++x;
    }
    
    // If a partial line remains.
    if( posn % 16 )
    {
        // Output the line to the file.
        fprintf( F, "%s\n", prtln );
    }
}

/*------------------------------------------------------------
| Note
|-------------------------------------------------------------
|
| PURPOSE: To add a note to the application log.
|
| DESCRIPTION: The input parameters are exactly the same as 
| for 'printf'.
|
| The formatted result string is sent to standard output and
| also to the application log file if it is enabled.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
|           
| HISTORY: 12.09.96 from 'DrawStringAt'.
|          12.11.96 added string format.
|          12.23.99 From TLLog.c
|          04.17.99 Added support for optional size spec.
------------------------------------------------------------*/
void
Note( s8* Format, ... )
{
    s8      SprintfIn[4096];  
    s8      SprintfOut[4096]; 
    s8      FinalString[4096]; 
    s8      AByte;
    s8*     In;
    va_list ap;
    
    // If the log is not enabled.
    if( IsLogEnabled == 0 )
    {
        // Just return.
        return;
    }
    
    // Clear the final string.
    FinalString[0] = 0;
    
    // Initialize 'ptr' to point to the first argument after
    // the format string.
    va_start( ap, Format );
    
    // Construct the finished string by working through
    // the format string.
    // %...<someletter> is the pattern that is detected 
    // and handed to 'sprintf' for conversion.
    In = SprintfIn;
    
    while( *Format )
    {
        AByte = *Format++;
        
        // Feed byte to sprintf input buffer.
        *In++ = AByte;
        
        // If not the start of a formatting section.
        if( AByte != '%' ) 
        {       
            continue;
        }
        else // May be start of formatting section.
        {
            if( *Format == '%' ) // A literal '%'.
            {
                Format++; // Consume the extra '%'.
                continue;
            }
            
            // This is the start of a formatting section.
BuildFormattingSection:
                
            // Get next byte.
            AByte = *Format++;
            
            // Feed byte to sprintf input buffer.
            *In++ = AByte;
                
            if( ! IsLetter( AByte ) )
            {
                goto BuildFormattingSection;
            }
            
            // If the letter is an optional size spec. 
            if( AByte == 'l' ||
                AByte == 'L' ||
                AByte == 'h' )
            {
                // Continue building the format.
                goto BuildFormattingSection;
            }
                
            // If byte is any other letter, then we have 
            // reached the end of a format spec.
            *In = 0; // Terminate string.
                    
            // Use the letter to get the type of the
            // argument.
            switch( AByte )
            {
                // Characters.
                case 'c':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) ); // chars take 4 bytes on the
                                               // stack.
                    break;
                }
                
                // String
                case 's':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) );
                    break;
                }
                        
                // Signed integers.
                case 'd':
                case 'i':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,s32) );
                    break;
                }
                        
                // Unsigned integers.
                case 'o':
                case 'u':
                case 'x':
                case 'X':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) );
                    break;
                }

                // Any floating point.
                case 'e':
                case 'E':
                case 'f':
                case 'g':
                case 'G':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,f64) );
                    break;
                }
                        
                // Address of something.
                case 'p':
                default:
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,void*) );
                    break;
                }
            }
                    
            // Append the format output to the
            // final string.
            strcat( FinalString, SprintfOut );
                
            // Reset the pointer for the input string
            // accumulator.
            In = SprintfIn;
        }
    }
    
    // Terminate the sprintf input buffer.
    *In = 0;
    
    // If there are letters in the sprintf input buffer,
    // convert and append them to the final string.
    if( In > SprintfIn )
    {
        sprintf( (char*) SprintfOut, (char*) SprintfIn );
        
        // Append the output to the final string.
        strcat( FinalString, SprintfOut );
    }
    
    va_end( ap );
    
    // If logging to the standard output is enabled.
    if( IsLogWindowOutputEnabled )
    {
        // Output the string to the standard output.
        printf( "%s", FinalString );
    }
    
    // If the log file is open and enabled for output.
    if( IsLogFileOutputEnabled && TheLogFile2 )
    {
        // Append the string to the file.
        fprintf( TheLogFile2, "%s", FinalString );
        
        fflush( TheLogFile2 );
    }
}
 
/*------------------------------------------------------------
| SetUpTheLog 
|-------------------------------------------------------------
|
| PURPOSE: To set up the application log.
|
| DESCRIPTION: Enables the application log for use.
|
| The given control flags determine whether log messages are
| sent to a window and/or to a file called 'TheLogFile2'.
|
| Defers creation of the log window or file until a log
| message is output.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
|           
| HISTORY: 12.11.96
------------------------------------------------------------*/
void
SetUpTheLog( u32 LogToWindow, u32 LogToFile )
{
    u64 CurrentTick;
    s8  LogFileName[50];
    
    if( LogToWindow || IsLogFileOutputEnabled )
    {
        IsLogEnabled = 1;
        
        // If the log file is not open.
        if( TheLogFile2 == 0 )
        {
            // Get the current peformance counter.
            CurrentTick = ReadTimeStamp();

            // Make a unique name for the log file:
            //
            //  "AppLog_<low 16 bits of clock>.txt"
            //
            sprintf( LogFileName, 
                     "MxLog_%X.txt",
                     (u16) CurrentTick );
                     
            // Then open a special log file.
            TheLogFile2 = fopen( LogFileName, "w" );
        }
    }
    else
    {
        IsLogEnabled = 0;
    }
    
    IsLogWindowOutputEnabled = LogToWindow;
    
    IsLogFileOutputEnabled = LogToFile;
}

/*------------------------------------------------------------
| WrapLine
|-------------------------------------------------------------
|
| PURPOSE: To account for the characters appended to the
|          current log line and wrap the line if the limit
|          is reached.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
|           
| HISTORY: 06.05.97
------------------------------------------------------------*/
void
WrapLine( s32 CharCount )
{
    s32 i;
    
    // Accumulate the character count.
    LogCharsInLine += CharCount;
    
    // If the limit of chars per line has been reached.
    if( LogCharsInLine >= LineWrapLimit )
    {
        LogCharsInLine = 0;
        
        Note( (s8*) "\n" );
        
        // Indent the given number.
        for( i = 0; i < LogIndentOnWrap; i++ )
        {
            Note( (s8*) " ");
        }
    }
}
