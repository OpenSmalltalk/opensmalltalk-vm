/*------------------------------------------------------------
| TLBitField.c
|-------------------------------------------------------------
|
| PURPOSE: To provide access to fields of bits.
|
| DESCRIPTION: The primary goal is to get the job done with
| the least number of errors, in the easiest to verify and
| understand way.  Speed is not a concern.
|
| DEFINITIONS:
|
| BIT RECORD - a series of binary digits segmented into  
|              groups called 'bit fields'.  
|
| BIT RECORD FORMAT - specification how the bits in a bit 
|                     record are partitioned into fields.
|
| BINARY ASCII STRING (BAS) - a string of ASCII '1's and 
|                             '0's. eg. "101010111".
|
| CONVENTIONS:
|
| 1. Bit records shall begin on byte boundaries. 
|
| 2. Bit record formats are ASCII strings such that each
|    character in the string is identified with each bit
|    in the bit record.  
|
|    Non-field literal zero bits are expressed using ASCII 
|    '0' and literal one bits use ASCII '1'.
|
|    Non-field positions of indefinite value are marked 
|    using periods, '.'.
|
|    Field bit values are marked using any printable
|    ASCII value except '0' and '1'.
|
|    If two source bits are in the same field then they 
|    are associated with the same ASCII format value.
|
|    ASCII 'space' (32) is ignored by the machinery but
|    is useful for marking byte boundaries for ease of 
|    reading.
|
|    The first byte in the string cooresponds to the lowest
|    order bit in the bit record.
|
|    Bit fields need not be contiguous.
|
|    Here's an example of a bit record format:
|
|    The machine instruction for 'ADDX' on a 68020 is a 
|    bit record with the following format:
|               
|                 Byte 0   Byte 1
|
|                01234567 01234567
|
|               "aaab00cc 1ddd1011" <--- FORMAT STRING
|
|            where: 'a' marks 'Register Ry' field
|                   'b' marks 'R/M' field
|                   'c' marks 'size' field
|                   'd' marks 'Register Rx' field
|
|    For ease of identification, fields can be named by
|    using a comma-delimited field name string like this:
|
|    "Register Ry,R/M,Size,Register Rx" <-- FIELD NAME STRING
|
| 2. By default, bit fields are represented as binary ASCII 
|    strings such that the first character cooresponds to the 
|    low order bit of the number.  This ordering is called
|    'Low-Order First', as opposed to 'High-Order First'.
|
|    Note that this is the reverse of the way a binary number 
|    would be printed but this is much easier to manipulate 
|    internally, especially if the high-order bits are 
|    indefinite.
|
|    For example the decimal number '8' is represented
|    as a binary ASCII string (BAS) as  "0001". To print this
|    string as a binary number, call 'ReverseString()' to
|    reverse the digits in place.
|    
| NOTE: 
|
| HISTORY: 02.17.97 
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdio.h>
#include <stdlib.h>

#include "TLTypes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStacks.h"
#include "TLStrings.h"
#include "TLDyString.h"
#include "TLParse.h"
#include "TLList.h"
#include "TLBitField.h"

/*------------------------------------------------------------
| ConvertBitsToString
|-------------------------------------------------------------
| 
| PURPOSE: To convert binary number to a Low-Order First 
|          binary ASCII string.
| 
| DESCRIPTION:  
| 
| EXAMPLE:   
|
|     u8    Bits;
|     s8    StringBuf[20];
|
|     Bits = 8;
|
|     ConvertBitsToString( &Bits, &StringBuf, 8 );
|
|     Results in "0001" in 'StringBuf'.
|            
| NOTE: 
| 
| ASSUMES:  
| 
| HISTORY: 02.17.97
------------------------------------------------------------*/
void
ConvertBitsToString( u8* B, s8* A, u32 BitCount )
{
    u8   BitBuffer;
    u32  BitsInBuffer;
    
    // Clear the bit buffer count.
    BitsInBuffer = 0;  
        
    // For each bit.
    while( BitCount-- )
    {
        // If bit buffer is empty.
        if( BitsInBuffer == 0 )
        {
            // Load the buffer
            BitBuffer = *B++;
            
            BitsInBuffer = 8;
        }
        
        // Test the lowest order bit remaining in the
        // buffer.
        if( BitBuffer & 1 )
        {
            // Output a '1' to the string.
            *A++ = '1';
        }
        else
        {
            // Output a '0' to the string.
            *A++ = '0';
        }
        
        // Consume the low-order bit.
        BitBuffer = (u8) ( BitBuffer >> 1 );
        BitsInBuffer--;
    }
    
    // Append a string terminator.
    *A = 0;
}
            
/*------------------------------------------------------------
| ConvertStringToBits 
|-------------------------------------------------------------
| PURPOSE: To convert a Low-Order First binary ASCII string 
|          to a binary number.
| 
| DESCRIPTION:  
| 
| EXAMPLE:   
|
|     u8    Bits;
|     s8    StringBuf[20];
|
|     ConvertStringToBits( "0001", &Bits );
|
|     Results in '8' (1000b) in 'Bits'.
|            
| NOTE: 
| 
| ASSUMES:  
| 
| HISTORY: 02.17.97
------------------------------------------------------------*/
void
ConvertStringToBits( s8* A, u8* B )
{
    u8   BitBuffer;
    u8   BitMask;
    u32  BitsInBuffer;
    s8   c;
    
    // Clear the bit buffer and count.
    BitBuffer    = 0;
    BitsInBuffer = 0;
    BitMask      = 1; 
        
    // For each binary digit.
    while( *A )
    {
        // Get the current character.
        c = *A++;
        
        // If the current character is '1'.
        if( c == '1' )
        {
            // Set the bit in the bit buffer.
            BitBuffer |= BitMask;
        }
        
        // Account for the new bit.
        BitsInBuffer++;
        
        // If the bit buffer is full.
        if( BitsInBuffer == 8 )
        {
            // Save the bits to result buffer.
            *B++ = BitBuffer;
            
            // Clear the bit buffer and count.
            BitBuffer    = 0;
            BitsInBuffer = 0;
            BitMask      = 1;
        }
        else
        {
            // Move the mask over 1 position.
            BitMask = (u8) ( BitMask << 1 );
        }
    }
    
    // If there are left over bits in the buffer.
    if( BitsInBuffer )
    {
        // Save the remainder.
        *B = BitBuffer;
    }
}

/*------------------------------------------------------------
| ExtractBitFields
|-------------------------------------------------------------
| PURPOSE: To extract bit fields from a bit record.
| 
| DESCRIPTION: Returns a list of binary ASCII strings of the
| fields in the given bit record, parsed according to the
| given bit record format.
|
| The 'TypeOfData' field in each item in the list of fields
| holds the field marker character from the bit record format
| string.
| 
| EXAMPLE:   
|
|       L = ExtractBitFields( R, "aaab00cc 1ddd1011" );
|
| NOTE: The data field size of the returned items includes
|       the string terminator byte.
| 
| ASSUMES: 'BitRecord' refers to packed binary bits, not
|          a binary ASCII string.
| 
| HISTORY: 03.01.97 
------------------------------------------------------------*/
List*
ExtractBitFields( u8* BitRecord, s8* BitRecordFormat )
{
    s8    f, b;
    s8*   B;
    s8*   R;
    s8*   F;
    s8*   Format;
    u32   BitCount;
    u16   AType;
    List* L;
    Item* AnItem;
    
    // Duplicate the format string.
    Format = DuplicateString( BitRecordFormat );
    
    // Strip any spaces from the copy of the format string
    // to make processing easier later.
    StripByteFromString( Format, ' ' );

    
    // Allocate a list to hold the field strings.
    L = MakeList();
    
    // Count the number characters in the format 
    // string to determine the number of bits in the bit
    // record.
    BitCount = CountString( Format );
    
    // Allocate a buffer to hold the ASCII string equivalent
    // of the bit record.
    R = (s8*) malloc( BitCount + 1 ); 
    
    // Convert the bit record to ASCII string.
    ConvertBitsToString( BitRecord, R, BitCount );
    
    // For each figure in the format string...
    F = Format;
    
    // ... which cooresponds to each bit in the bit record.
    B = R;
    
    while( *F )
    {
        // Get the format character.
        f = *F++;
        
        // Get the source bit character.
        b = *B++;
        
        // Ignore source bits that coorespond to non-field
        // characters in the format string: literal
        // 1's and 0's or periods.
        if( f == '0' || f == '1' || f == '.' )
        {
            continue;
        }
         
        // Look for the item record in the field list that
        // has a type the same as the format character.
        AType  = (u16) f;
        AnItem = FindNextItemOfType( L, L->FirstItem, AType );

        // If there is no item for this field type, make one.
        if( AnItem == 0 )
        {
            // Allocate a 33 byte string to begin with.
            AnItem = InsertDataLastInList( L, malloc(33) );
            
            // Add an end-of-string marker.
            AnItem->DataAddress[0] = 0;
            
            // Set the buffer, data and type fields.
            AnItem->SizeOfData   = 1; // For string terminator.
            AnItem->SizeOfBuffer = 33;
            AnItem->TypeOfData   = AType;
        }
        
        // If there is no room for the bit character, make some.
        if( AnItem->SizeOfData == AnItem->SizeOfBuffer )
        {
            // New size.
            AnItem->SizeOfBuffer += 32;
            
            // Reallocate the buffer.
            AnItem->DataAddress = 
                realloc( AnItem->DataAddress, 
                          AnItem->SizeOfBuffer );
        }
    
        // Add the bit character to the buffer, overwriting the 
        // string terminator.
        AnItem->DataAddress[ AnItem->SizeOfData - 1 ] = (u8) b;
        
        // Append a new string terminator.
        AnItem->DataAddress[ AnItem->SizeOfData ] = 0;
        AnItem->SizeOfData++;
    }
    
    // Discard the format string.
    free( Format );
    
    // Discard the bit record string.
    free( R );
    
    // Return the list.
    return( L );
}   

/*------------------------------------------------------------
| ExtractNamedBitFields
|-------------------------------------------------------------
| PURPOSE: To extract named bit fields from a bit record.
| 
| DESCRIPTION: Returns a comma-delimited string with a list
| of field names equated with binary values held in the field,
| eg. "LT=101,GT=0,EQ=10,SO=111".
|
| The given bit field is parsed according to the given bit 
| record format, then the parsed values are identified with
| the given field names.
|
| EXAMPLE:   
|
|   R = "10100010 11111011";
|
|   n = ExtractNamedBitFields( R, 
|                              "aaab00cc 1ddd1011",
|                              "LT,GT,EQ,SO" );
|
| result 'n' is "LT=101,GT=0,EQ=10,SO=111"
|
| NOTE:
| 
| ASSUMES: The result string will be copied elsewhere if it
|          needs to be preserved.
|
|          The result string is less than 256 bytes.
|
|          Every field in the record format has a name
|          in the list of names.
| 
| HISTORY: 03.01.97
------------------------------------------------------------*/
s8*
ExtractNamedBitFields( u8* BitRecord,       // Where the bits are.
                       s8* BitRecordFormat, // Where the fields are.
                       s8* BitFieldNames )  // What the fields are
                                            // named.
{
    static s8 Result[256];
    List*     L;
    u32       FieldNumber;
    s8*       FieldName;

    // Parse the bit record into binary ASCII field values.
    L = ExtractBitFields( BitRecord, BitRecordFormat );
    
    // Mark the result buffer as empty.
    Result[0] = 0;
    
    // Refer to the first field name later.
    FieldNumber = 0;
    
    ReferToList( L );
    
    // For each field value.
    while( TheItem ) 
    {
        // If this is not the first field then append
        // a comma to the result string.
        if( FieldNumber )
        {
            AppendString2( Result, (s8*) "," );
        }
        
        // Get the field name.
        FieldName = 
            ValueOfNthItemInCommaDelimitedString( FieldNumber,
                                                  BitFieldNames );
        
        // Append the field name and value to the result.
        AppendStrings( Result,
                       FieldName,
                       "=",
                       (s8*) TheDataAddress );
    
        // Advance to the next field.
        FieldNumber++;
        
        ToNextItem();
    }
    
    RevertToList();
    
    // Discard the list of field values.
    DeleteListOfDynamicData( L );
    
    // Return a reference to the result.
    return( Result );
}                                  

/*------------------------------------------------------------
| FindMarkerOfNamedField
|-------------------------------------------------------------
| PURPOSE: To find the field marker in a bit record format
|          that cooresponds to a field name.
| 
| DESCRIPTION:  
| 
| EXAMPLE:   
|
|     m = FindMarkerOfNamedField( "aaab00cc 1ddd1011",
|                                 "LT,GT,EQ,SO",
|                                 "GT" );
|  results in m = 'b'.
|
| NOTE: 
| 
| ASSUMES:  
| 
| HISTORY: 03.01.97
------------------------------------------------------------*/
u32 
FindMarkerOfNamedField( s8* BitRecordFormat,
                        s8* BitFieldNames,
                        s8* FieldName )
{
    u32 n, Marker;
    
    // Translate the field name to the field number.
    n = FindFieldHoldingValueInCommaDelimitedString( 
                BitFieldNames,
                FieldName );

    // Find the marker for the numbered field.
    Marker = FindNthFieldMarkerInBitRecordFormat( 
                BitRecordFormat,
                n );
    
    return( Marker );
}                                                

/*------------------------------------------------------------
| FindMatchingBinaryLiteral
|-------------------------------------------------------------
| PURPOSE: To find the first binary literal pattern in a list
|          that matches a test string.
| 
| DESCRIPTION: 
| 
| EXAMPLE:   
|
|       InsertDataLastInList( L, "101000aaa1010" );
|       InsertDataLastInList( L, "1ag010aaa1010" );
|
|       P = FindMatchingBinaryLiteral( L, "100111011011" );
|
| NOTE:  
| 
| ASSUMES:  
| 
| HISTORY: 03.01.97 
------------------------------------------------------------*/
Item*
FindMatchingBinaryLiteral( List* L, s8* Test )
{
    Item*   it;
    
    ReferToList( L );
    
    // Scan through a list of patterns.
    while( TheItem )
    {
        if( IsMatchingBinaryLiteral( (s8*) TheDataAddress,
                                     Test ) )
        {
            it = TheItem;
            
            RevertToList();
            
            return( it );
        }
        
        ToNextItem();
    }
    
    RevertToList();
    
    // No matching pattern found.
    return( 0 );
}

/*------------------------------------------------------------
| FindMatchingBinaryLiterals
|-------------------------------------------------------------
| PURPOSE: To find the all binary literal patterns in a list
|          that matches a test string.
| 
| DESCRIPTION: Returns a list that refers to the orginal
| pattern strings that match a given test string.
| 
| EXAMPLE:   
|
|       InsertDataLastInList( L, "101000aaa1010" );
|       InsertDataLastInList( L, "1ag010aaa1010" );
|
|       LL = FindMatchingBinaryLiterals( L, "100111011011" );
|
| NOTE:  
| 
| ASSUMES:  
| 
| HISTORY: 03.01.97 
------------------------------------------------------------*/
List*
FindMatchingBinaryLiterals( List* L, s8* Test )
{
    List*   LL;
    
    // Make a new list to hold the result.
    LL = MakeList();
    
    ReferToList( L );
    
    // Scan through a list of patterns.
    while( TheItem )
    {
        if( IsMatchingBinaryLiteral( (s8*) TheDataAddress,
                                     Test ) )
        {
            // Save a reference to the pattern.
            InsertDataLastInList( LL, TheDataAddress );
        }
        
        ToNextItem();
    }
    
    RevertToList();
    
    // Return the resulting patterns.
    return( LL );
}   
    
/*------------------------------------------------------------
| FindNthFieldMarkerInBitRecordFormat
|-------------------------------------------------------------
| PURPOSE: To find the field marker in a bit record format
|          that cooresponds to the nth field.
| 
| DESCRIPTION: The first field is numbered 0, the next is 1,
| and so on. 
| 
| EXAMPLE:   
|
|     m = FindNthFieldMarkerInBitRecordFormat( 
|                  "aaab00cc 1ddd1011",
|                   2 );
|
|  results in m = 'c'.
|
| NOTE: 
| 
| ASSUMES: Fields may be non-contiguous.
| 
| HISTORY: 03.01.97
------------------------------------------------------------*/
u32 
FindNthFieldMarkerInBitRecordFormat( s8* BitRecordFormat,
                                     u32 n )
{
    s8  FoundMarkers[100];
    u32 FoundMarkerCount;
    s8  b;
    
    // No markers found initially.
    FoundMarkers[0]  = 0;
    FoundMarkerCount = 0;

Another:
    
    // Get a byte from the field record.
    b = *BitRecordFormat++;
    
    // If 'b' is a field marker, save it as the marker.
    if( b != '0' && b != '1' && b != '.' && b != ' ' )
    {
        // If the marker isn't in the found marker list,
        // test for done or add it to found markers.
        if( ! IsByteInString( FoundMarkers, (u16) b ) )
        {
            // If the found marker count matches the 
            // sought after marker, return the marker.
            if( n == FoundMarkerCount )
            {
                return( (u32) b );
            }
            else // Remember this marker.
            {
                FoundMarkers[ FoundMarkerCount ] = b;
            
                FoundMarkerCount++;
            }
        }
    }
        
    goto Another;
}

/*------------------------------------------------------------
| InsertBitFields
|-------------------------------------------------------------
| PURPOSE: To insert bits into the bit fields of a bit record.
| 
| DESCRIPTION: Given a list of binary ASCII strings holding 
| field values which will be inserted into the bit record
| according to a given bit record format string.
|
| The 'TypeOfData' field in each item in the list of fields
| holds the field marker character from the bit record format
| string.
| 
| EXAMPLE:   
|
|     InsertBitFields( L, R, "aaab00cc 1ddd1011" );
|
| NOTE: The data field size of the items includes
|       the string terminator byte.
| 
| ASSUMES: Some, none or all input field values may be 
|          given.
|
|          Input values are complete for any given field.
|
|          Literal bit field values in the record format are
|          impressed on the bit record.
|
|          Input values are not to be altered.
| 
| HISTORY: 02.17.97 from 'ExtractBitFields'.
|          03.01.97 made literal values set even if no
|                   field values are supplied.
------------------------------------------------------------*/
void
InsertBitFields( u8* BitRecord, List* L, s8* BitRecordFormat )
{
    s8    m;
    s8*   R;
    s8*   Field;
    s8*   Format;
    u32   BitOfField;
    u32   BitCount, i;
    
    // Duplicate the format string.
    Format = DuplicateString( BitRecordFormat );
    
    // Strip any spaces from the copy of the format string
    // to make processing easier later.
    StripByteFromString( Format, ' ' );

    // Count the number of characters in the format 
    // string to determine the number of bits in the bit
    // record.
    BitCount = CountString( Format );
    
    // Allocate a buffer to hold the ASCII string equivalent
    // of the bit record.
    R = (s8*) malloc( BitCount + 1 ); 
    
    // Convert the existing bit record to ASCII string.
    ConvertBitsToString( BitRecord, R, BitCount );

    // For each field in the list.
    ReferToList( L );
    
    while( TheItem )
    {
        // Get the field marker character from the item.
        m = (s8) TheItem->TypeOfData;
        
        // Refer to the field string.
        Field = (s8*) TheDataAddress;
        
        // Set the bit position within the string.
        BitOfField = 0;
        
        // Scan through the format string to find matching
        // field markers.
        for( i = 0; i < BitCount; i++ )
        {
            // If a field marker byte is found.
            if( Format[i] == m )
            {
                // Move the bit character to the bit record
                // string.
                R[i] = Field[BitOfField];
                
                // Advance to the next bit of field.
                BitOfField++;
            }
        }
        
        // To next field.
        ToNextItem();
    }
    
    RevertToList();
    
    // Scan through the format string to find literal values.
    for( i = 0; i < BitCount; i++ )
    {
        if( Format[i] == '0' || Format[i] == '1' )
        {
            R[i] = Format[i];
        }
    }
    
    // Convert the bit record string to bits.
    ConvertStringToBits( R, BitRecord );
    
    // Discard the dynamic buffers.
    free( R );
    free( Format );
}

/*------------------------------------------------------------
| InsertNamedBitFields
|-------------------------------------------------------------
| PURPOSE: To insert named bits into the bit fields of a bit 
|          record.
| 
| DESCRIPTION: Given a list of binary ASCII strings holding 
| field values which will be inserted into the bit record
| according to a given bit record format string.
|
| The 'TypeOfData' field in each item in the list of fields
| holds the field marker character from the bit record format
| string.
| 
| EXAMPLE:   
|
|     InsertNamedBitFields( R, 
|                           "aaab00cc 1ddd1011",
|                           "LT,GT,EQ,SO",
|                           "LT=101,GT=0,EQ=10,SO=111" );
|
| NOTE: The data field size of the items includes
|       the string terminator byte.
| 
| ASSUMES: Some, none or all field values may be present as
|          input.
|
|          The order of the field names in 'BitFieldNames'
|          cooresponds to the ordering of the field markers.
|
|          Bit fields in the bit record may be non-contiguous.
|
|          Named values are in binary ASCII string form.
| 
| HISTORY: 02.17.97 from 'ExtractBitFields'.
------------------------------------------------------------*/
void
InsertNamedBitFields( u8* BitRecord, 
                      s8* BitRecordFormat,
                      s8* BitFieldNames,
                      s8* NamedValues )
{
    u32   ValueCount, n;
    s8*   V;
    s8    FieldName[30];
    s8    FieldValue[256];
    u32   Marker;
    List* L;
    Item* It;
    s8*   S;

    // Make a list to hold the input bit field strings.
    L = MakeList();
    
    // Count up how many input values there are.
    ValueCount = 
         CountItemsInCommaDelimitedString( NamedValues );
        
    // For each input value.
    for( n = 0; n < ValueCount; n++ )
    {
        // Get the input value.
        V = ValueOfNthItemInCommaDelimitedString( 
                n, NamedValues );
                
        // Split the field name and value into parts.
        SplitNameAndValue( V, FieldName, '=', FieldValue );
        
        // Find the field marker that cooresponds to the
        // the field name.
        Marker = FindMarkerOfNamedField( BitRecordFormat,
                                         BitFieldNames,
                                         FieldName );
        
        // Duplicate the field value string.
        S = DuplicateString( FieldValue );
        
        // Insert the field value into the list.
        It = InsertDataLastInList( L, (u8*) S );
        
        // Set the item type to the field marker value.
        It->TypeOfData = Marker;
    }
    
    // Insert the field values into the bit record.
    InsertBitFields( BitRecord, L, BitRecordFormat );
    
    // Discard the field value list.
    DeleteListOfDynamicData( L );
}

/*------------------------------------------------------------
| IsMatchingBinaryLiteral
|-------------------------------------------------------------
| PURPOSE: To test if a binary string matches a pattern.
| 
| DESCRIPTION: Given two binary ASCII strings, the first one
| serving as the pattern, return '1' if every binary digit
| in the pattern matches the cooresponding binary digit in
| the test string.
| 
| EXAMPLE:   
|
|   t = IsMatchingBinaryLiteral( "ab1cc00111", 
|                                "1111100111" );
|
| NOTE:  
| 
| ASSUMES: The pattern string is less than or equal to the
|          length of the test string.
| 
| HISTORY: 03.01.97 
------------------------------------------------------------*/
u32  
IsMatchingBinaryLiteral( s8* Pattern, s8* Test )
{
    s8  p, t;
    
    while( *Pattern )
    {
        p = *Pattern++;
        t = *Test++;
        
        if( p == '0' || p == '1' )
        {
            if( p != t )
            {
                return( 0 );
            }
        }
    }
    
    return( 1 );
}
