/*------------------------------------------------------------
| TLParseExtra.c
|-------------------------------------------------------------
|
| PURPOSE: To provide less commonly used data scanning and 
|          parsing procedures.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 11.08.93 pulled from 'Bytes.c' and 'StringSys.c'
|          12.31.93 added 'IsByteInString'
|          01.14.94 added 'FindNthByteOfType'.
|          01.27.00 Split this file off from 'TLParse.c'.
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <ctype.h>
#include <stdio.h>

#include "TLTypes.h"
#include "TLAscii.h"
#include "TLBytes.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStacks.h"
#include "TLList.h"
#include "TLMassMem.h"
#include "TLTable.h"
#include "TLNameAt.h"
#include "TLf64.h"
#include "TLAk2Types.h"
#include "TLNumber.h"

#include "TLParse.h"
#include "TLParseExtra.h"

/*------------------------------------------------------------
| ParseNumber
|-------------------------------------------------------------
|
| PURPOSE: To parse the next ASCII word as a 
|          64-bit binary floating point number.  
|
| DESCRIPTION:  
|
| Expects a number formatted like this:
|
|    [+|-] [digits][,][digits] [.digits] [e|E [-|+] digits]
|
| Anything in brackets is optional.  If items are separated
| by vertical bars, only one of those items may be in that
| position.   
|
| Returns 'NoNum' if an error occurred.
|
| Adjusts the given parsing cursor to the byte following the
| white-space delimited word.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY: 01.07.97
------------------------------------------------------------*/
f64
ParseNumber( s8** At )
{
    s8      Buf[64];
    f64 n;
    
    // Parse the next word to the buffer.
    *At = ParseWord( *At, Buf );

    // Convert the string to a f64.
    n = ConvertStringTof64( Buf );
    
    // Return the result.
    return( n );
}


