/*------------------------------------------------------------
| TLDyString.c
|-------------------------------------------------------------
|
| PURPOSE: To provide dynamically-allocated string functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 09.22.93 from StringSys.c
------------------------------------------------------------*/

#include "TLTarget.h" 

#include "NumTypes.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLDyString.h"

#include "TLStrings.h"

Lot*    TheStringPool = 0;
                // The allocation pool from which all data
                // in dynamic string functions is allocated.

/*------------------------------------------------------------
| AllocateString
|-------------------------------------------------------------
|
| PURPOSE: To allocate memory for a string of a given length.
|
| DESCRIPTION: Sets aside enough memory for the string and
| a '0' terminator byte.
|
| EXAMPLE:  
|
| NOTES: Use FreeMemoryHM() to deallocate strings created using
|        this procedure.
|
| ASSUMES: Enough memory space exists.
|
| HISTORY:  02.15.93 
|           03.06.96 Makes first byte 0 so that string is
|                    seen as empty when appending.
------------------------------------------------------------*/
s8*
AllocateString( u32 Count )
{
    s8* NewString;
    
    NewString = (s8*) 
        AllocateMemoryAnyPoolHM( 
            TheStringPool, 
            Count+1 );

    NewString[0]     = 0; /* terminator byte */
    NewString[Count] = 0; /* terminator byte */

    return( NewString );
}

/*------------------------------------------------------------
| DuplicateString
|-------------------------------------------------------------
|
| PURPOSE: To allocate a copy of a string.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTES:  
|
| ASSUMES: 
|
| HISTORY: 01.30.89 
|          02.15.93 changed to use AllocateString.
------------------------------------------------------------*/
s8*
DuplicateString(s8* AString)
{
    s8* NewString;
    u32 LengthOfString;
    
    LengthOfString = CountString(AString); 
    
    NewString = AllocateString(LengthOfString);

    CopyBytes( (u8*) AString, 
               (u8*) NewString, 
               LengthOfString );
    
    return(NewString);
}

/*------------------------------------------------------------
| LeftString
|-------------------------------------------------------------
|
| PURPOSE: To return a new string consisting of the left n 
|          characters of a string.
|
| DESCRIPTION: Returns a dynamic string which must be freed 
|              later using 'FreeMemoryHM()'.
|
| EXAMPLE:  AStr = LeftString("abcdefg",(u32) 4);
|
|           AStr == "abcd"
|
| NOTES:  
|
| ASSUMES: 
|
| HISTORY: 12.06.89  from source by 
|                   Jack A. Zucker
|          02.15.93 changed count to quad. Allocates space.
------------------------------------------------------------*/
s8*
LeftString(s8* AString, u32 ByteCount)
{
    s8* ResultString;

    ResultString = AllocateString(ByteCount);
    
    CopyBytes( (u8*) AString, 
               (u8*) ResultString, 
               ByteCount );

    return(ResultString);
}

/*------------------------------------------------------------
| MidString
|-------------------------------------------------------------
|
| PURPOSE: To return a new string copied from the middle of 
|          another string.
|
| DESCRIPTION: Returns a dynamic string which must be freed 
|              later using 'FreeMemoryHM()'.
|
| EXAMPLE:  AStr = MidString("abcdefg",(u32) 2, (u32) 3);
|
|           AStr == "cde"
|
| NOTES: 
|
| ASSUMES: Assumes substring is within string.
|
| HISTORY: 12.06.89  from source by 
|                   Jack A. Zucker
|          02.15.93 changed count to quad. Allocates space.
------------------------------------------------------------*/
s8*
MidString( s8* AString, 
           u32 ByteOffset, 
           u32 ByteCount )
{
    s8* ResultString;

    ResultString = AllocateString(ByteCount);
    
    CopyBytes( (u8*)(AString + ByteOffset), 
               (u8*) ResultString, 
               ByteCount); 

    return( ResultString );
}

/*------------------------------------------------------------
| RightString
|-------------------------------------------------------------
|
| PURPOSE: To return a new string copied from the right n 
|          characters of a string.
|
| DESCRIPTION: Returns a dynamic string which must be freed 
|              later using 'FreeMemoryHM()'.
|
| EXAMPLE:  AStr = RightString("abcdefg",(u32) 4);
|
|           AStr == "defg"
|
| NOTES:  
|
| ASSUMES: Result string will be freed using FreeString.
|
| HISTORY: 12/06/89 from source by Jack A. Zucker
|          02.15.93 changed count to quad and made to 
|                   allocate dynamic string.
------------------------------------------------------------*/
s8*
RightString( s8* AString, u32 ByteCount )
{
    u32 StringCount;
    u32 ByteOffset;
    
    StringCount = CountString(AString);

    ByteOffset = StringCount - ByteCount;

    return( MidString( AString, ByteOffset, ByteCount ) );
}

