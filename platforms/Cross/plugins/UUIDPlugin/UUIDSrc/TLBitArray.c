/*------------------------------------------------------------
| TLBitArray.c
|-------------------------------------------------------------
| 
| PURPOSE: To provide general two-dimensional bit 
|          array procedures.
|
| DESCRIPTION: Supports all possible binary packing orders. 
|
| NOTE: 
|
| HISTORY: 01.13.97
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include "TLTypes.h"
#include "TLBytes.h"
#include "TLBit.h"
#include "TLPacking.h"
#include "TLBitArray.h"

/*------------------------------------------------------------
| CopyPartOfBitArray
|-------------------------------------------------------------
|
| PURPOSE: To copy a rectangular section of a bit array
|          to the same or a different bit array.
|
| DESCRIPTION:  
|
| EXAMPLE:    
|
|           CopyPartOfBitArray( A, ARect, B, BRect );
|
| NOTE:  
|
| ASSUMES: 
|           
| HISTORY: 01.19.97 from 'MakeBitArray'.
------------------------------------------------------------*/


/*------------------------------------------------------------
| DeleteBitArray
|-------------------------------------------------------------
|
| PURPOSE: To delete a bit array.
|
| DESCRIPTION:  
|
| EXAMPLE:    DeleteBitArray( A );
|
| NOTE:  
|
| ASSUMES: 
|           
| HISTORY: 01.19.97 from 'MakeBitArray'.
------------------------------------------------------------*/
void
DeleteBitArray( BitArray* A )
{
    // Trap errors.
    if( A == 0 )
    {
        Debugger();
    }
    
    // If there is a row array, free it.
    if( A->Row )
    {
        free( A->Row );
    }
    
    // If there is dynamic data, free it.
    if( A->IsDataDynamic && A->Data )
    {
        free( A->Data );
    }
    
    // Free the array specification record itself.
    free( A );
}

/*------------------------------------------------------------
| ExpandBitArrayToByteArray
|-------------------------------------------------------------
|
| PURPOSE: To make a byte array that cooresponds to a bit 
|          array.
|
| DESCRIPTION: This procedure converts bits to bytes.
|
| The least significant bit of the unpacked access unit 
| converts to the first byte in the row, the next least 
| significant bit to the second byte and so on.
|
| EXAMPLE:    
|
|       B = ExpandBitArrayToByteArray( A, B, 0, 0xff );
|
| NOTE:  
|
| ASSUMES: Byte array rows are contiguous.
|          Packing of the byte array is same as CPU.
|          Access unit for the byte array is a byte.
|           
| HISTORY: 02.03.97 
------------------------------------------------------------*/
void
ExpandBitArrayToByteArray( BitArray*    A,
                           ByteArray*   B,
                           u32          ByteForZero,
                           u32          ByteForOne ) 
{
    
    u32       RowCount, ColCount;
    u32       RelPack;
    u64       Unit;
    u32       BitsPerUnit, BitsInUnit, BytesPerUnit;
    u32       i, j;
    u8*       AtByte;
    u16*      AtPair;
    u32*      AtQuad;
    u8*       AtUnit;
    u32Procedure      GetUnit;
    AccessUnit* Access;
    
    // Locate the access unit and packing.
    Access = A->Access;
    
    // Get the number of bits per access unit.
    BitsPerUnit  = Access->BitsPerAccessUnit;
    BytesPerUnit = Access->BytesPerAccessUnit;
    
    // Get the procedure for fetching an access unit.
    GetUnit = Access->PutUnit;
    
    // Calculate the relative packing order to be used for
    // packing.
    RelPack = ThePackingOrder ^ A->Packing;
    
    // Use the dimensions of the bit array.
    RowCount = A->RowCount;
    ColCount = B->ColCount;
    
    // Refer to the first byte in the byte array.
    AtByte = B->Data;
    
    // For each row.
    for( i = 0; i < RowCount; i++ )
    {
        // Clear the bit in unit counter.  
        BitsInUnit = 0; // Count of bits remaining in 
                        // access unit.
        
        // Find the start of the row in the bit array.
        AtUnit = *((u8**) (((u32) A->Row) + (i << 2))); 
        
        // For each column.
        for( j = 0; j < ColCount; j++ )
        {
            // If no bits are in the unit buffer.
            if( BitsInUnit == 0 )
            {
                // Fetch bits by the unit.
                if( Access == &AccessQuad )
                {
                    AtQuad = (u32*) AtUnit;
                    
                    Unit = *AtQuad;
                }
                else
                {
                    if( Access == &AccessPair )
                    {
                        AtPair = (u16*) AtUnit;
                    
                        Unit = *AtPair;
                    }
                    else
                    {
                        if( Access == &AccessByte )
                        {
                            Unit = *AtUnit;
                        }
                        else // Something special.
                        {
                            Unit = (*GetUnit)( AtUnit );
                        }
                    }
                }
         
                // Repack the unit if necessary.
                if( RelPack )
                {
                    Unit = Repack( RelPack, Unit );
                }
                
                // Reset the bit count.
                BitsInUnit = BitsPerUnit;
                
                // Advance the unit address.
                AtUnit += BytesPerUnit;
            }
            
            // Test the current bit.
            if( Unit & BitOfUnit[ BitsPerUnit - BitsInUnit ] )
            {
                // Output a 'OneByte'.
                *AtByte++ = (u8) ByteForOne;
            }
            else
            {
                // Output a 'ZeroByte'.
                *AtByte++ = (u8) ByteForZero;
            }
            
            // Decrement the number of bits in unit.
            BitsInUnit--;
        }
    }
}
         
/*------------------------------------------------------------
| FillBitArray
|-------------------------------------------------------------
|
| PURPOSE: To fill a bit array with a value.
|
| DESCRIPTION:  
|
| EXAMPLE:  FillBitArray( A, n );
|
| NOTE: 
|
| ASSUMES: 
|          Fill value packing order is the CPU packing order.
|           
| HISTORY: 01.26.97
------------------------------------------------------------*/
void
FillBitArray( BitArray* A, u64 FillValue )
{
    u32             RowCount;
    u32             AccessUnitsPerRow;
    u32Procedure    FillUnits;
    u32Procedure    PutUnit;
    u32             i, j;
    u32             Reorder,    BytesPerUnit;
    u8*             UnitAddress;
    
    RowCount = A->RowCount;
    AccessUnitsPerRow = A->AccessUnitsPerRow;
    FillUnits = A->Access->Lop[LopFill];
    
    // If there is a bulk fill routine for the access unit.
    if( FillUnits )
    {
        // For each row.
        for( i = 0; i < RowCount; i++ )
        {
            (*FillUnits)( A->Row[i], 
                          AccessUnitsPerRow, 
                          FillValue );
        }
    }
    else // Fill each unit, one-by-one.
    {
        // Calculate the repacking required to pass from
        // the CPU packing order to the packing order of
        // the bit array data field.
        Reorder = ThePackingOrder ^ A->Packing;
    
        // Repack the fill value if necessary.
        if( Reorder )
        {
            FillValue = Repack( Reorder, FillValue );
        }
        
        PutUnit = A->Access->PutUnit;
        BytesPerUnit = A->Access->BytesPerAccessUnit;
        
        // For each row.
        for( i = 0; i < RowCount; i++ )
        {
            // For each unit in the row.
            UnitAddress = A->Row[i];
            for( j = 0; j < AccessUnitsPerRow; j++ )
            {
                (*PutUnit)( UnitAddress, FillValue );
                
                UnitAddress += BytesPerUnit;
            }
        }
    }
}    

/*------------------------------------------------------------
| MakeBitArray
|-------------------------------------------------------------
|
| PURPOSE: To make a new bit array record and allocate the
|          bit data area.
|
| DESCRIPTION:  
|
| EXAMPLE:    A = MakeBitArray( Rows, Cols );
|
| NOTE: Doesn't initialize the cell data.
|
|       See 'MakeArray' for multi-dimensional bit arrays.
|
| ASSUMES: 'TheBinaryPackingOrder' is current. 
|          Rows begin on quad boundaries.
|          'malloc' returns quad-aligned addresses.
|           
| HISTORY: 01.19.97 from 'MakeArray'.
|          01.20.97 added 'BinaryPackingOrder'.
|          01.20.97 changed to quad alignment of rows.
------------------------------------------------------------*/
BitArray*
MakeBitArray( u32 RowCount, u32 ColCount, AccessUnit* Access )
{
    BitArray*   A;
    u32         i;
    
    // Allocate a bit array specification record.
    A = (BitArray*) malloc( sizeof( BitArray ) );
    
    // Save the dimension extents.
    A->RowCount = RowCount;
    A->ColCount = ColCount;
    
    // Save the access unit reference.
    A->Access = Access;
    
    // Save the packing order.
    A->PackingReference = ThePackingReference;
    A->Packing = ThePackingOrder;
    
    // Set the flag that says whether the data buffer is
    // dynamically allocated.  The display buffer isn't.
    A->IsDataDynamic = 1;
    
    // Calc number of access units per row: rows begin on
    // access unit boundaries.
    A->AccessUnitsPerRow = 
        ( ColCount + Access->BitsPerAccessUnit - 1 ) 
        / 
        Access->BitsPerAccessUnit ;
      
    // Compute the number of bytes per row.
    A->BytesPerRow = 
        A->AccessUnitsPerRow * Access->BytesPerAccessUnit;
    
    // Allocate the storage for the bit data.
    A->Data = malloc( A->BytesPerRow * RowCount );
    
    // Allocate the storage for the row address array.
    A->Row = (u8**) malloc( RowCount * sizeof( u8* ) );
    
    // For each row.
    for( i = 0; i < RowCount; i++ )
    {
        // Set the row address.
        A->Row[i] = A->Data + i * A->BytesPerRow;
    }
    
    // Return the result.
    return( A );
}

/*------------------------------------------------------------
| OneFillBitArray
|-------------------------------------------------------------
|
| PURPOSE: To fill a bit array with ones.
|
| DESCRIPTION:  
|
| EXAMPLE:  OneFillBitArray( A );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 01.19.97 from 'ZeroBitArray'.
------------------------------------------------------------*/
void
OneFillBitArray( BitArray* A )
{
    FillBitArray( A, 0xffffffff );
}
 
/*------------------------------------------------------------
| ReduceByteArrayToBitArray
|-------------------------------------------------------------
|
| PURPOSE: To make a bit array that cooresponds to a byte
|          array.
|
| DESCRIPTION: Given a byte array and a byte value that is
| to be taken as binary zero, this procedure maps bytes to 
| bits.
|
| The first byte in the row maps to the least significant
| bit of the unpacked access unit, the second byte to the
| next least significant bit and so on.
|
| EXAMPLE:    
|
|   B = ReduceByteArrayToBitArray( A, B, '.' );
|
| NOTE:  
|
| ASSUMES: Byte array rows are contiguous.
|          Packing of the byte array is same as CPU.
|          Access unit for the byte array is a byte.
|          Dimensions of the two arrays are the same.
|           
| HISTORY: 02.03.97 
|          02.14.97 
------------------------------------------------------------*/
void
ReduceByteArrayToBitArray( ByteArray*   A,
                           BitArray*    B, 
                           u32          ZeroByte )
{
    u32       RowCount, ColCount;
    u32       RelPack;
    u64       Unit;
    u32       BitsPerUnit, BitsInUnit, BytesPerUnit;
    u32       i, j;
    u8        AByte;
    u8*       AtByte;
    u16*      AtPair;
    u32*      AtQuad;
    u8*       AtUnit;
    u32Procedure      PutUnit;
    AccessUnit* Access;
    
    // Locate the access unit and packing.
    Access = B->Access;
    
    // Get the number of bits per access unit.
    BitsPerUnit  = Access->BitsPerAccessUnit;
    BytesPerUnit = Access->BytesPerAccessUnit;
    
    // Get the procedure for storing an access unit.
    PutUnit = Access->PutUnit;
    
    // Calculate the relative packing order to be used for
    // packing.
    RelPack = ThePackingOrder ^ B->Packing;
    
    // Use the dimensions of the byte array.
    RowCount = A->RowCount;
    ColCount = A->ColCount;
    
    // Refer to the first byte in the byte array.
    AtByte = A->Data;
    
    // For each row.
    for( i = 0; i < RowCount; i++ )
    {
        // Clear the bit accumulator.
        Unit = 0;       // The bit pattern.
        BitsInUnit = 0; // Count of bits accumulated.
        
        // Find the start of the row in the bit array.
        AtUnit = *((u8**) (((u32) B->Row) + (i << 2))); 
        
        // For each column.
        for( j = 0; j < ColCount; j++ )
        {
            // Get the byte from the array.
            AByte = *AtByte++;
            
            // Set the cooresponding bit in the access unit
            // if the byte was not the zero byte.
            if( AByte != ZeroByte )
            {
                Unit |= BitOfUnit[ BitsInUnit ];
            }
            
            // Account for the new bit in the unit.
            BitsInUnit++;
            
            // If a complete access unit has been made.
            if( BitsInUnit == BitsPerUnit )
            {
                // Repack the unit if necessary.
                if( RelPack )
                {
                    Unit = Repack( RelPack, Unit );
                }
                
                // Save the unit in the bit array.
                if( Access == &AccessQuad )
                {
                    AtQuad = (u32*) AtUnit;
                    
                    *AtQuad = (u32) Unit;
                }
                else
                {
                    if( Access == &AccessPair )
                    {
                        AtPair = (u16*) AtUnit;
                    
                        *AtPair = (u16) Unit;
                    }
                    else
                    {
                        if( Access == &AccessByte )
                        {
                            *AtUnit = (u8) Unit;
                        }
                        else // Something special.
                        {
                            (*PutUnit)( AtUnit, Unit );
                        }
                    }
                }
                
                // Clear the unit accumulator and bit count.
                Unit = 0;       // The bit pattern.
                BitsInUnit = 0; // Count of bits accumulated.
                
                // Advance the unit address.
                AtUnit += BytesPerUnit;
            }
        }
                    
        // If a partial access unit remains.
        if( BitsInUnit )
        {
            // Repack the unit if necessary.
            if( RelPack )
            {
                Unit = Repack( RelPack, Unit );
            }
                
            // Save the unit in the bit array.
            if( Access == &AccessQuad )
            {
                AtQuad = (u32*) AtUnit;
                    
                *AtQuad = (u32) Unit;
            }
            else
            {
                if( Access == &AccessPair )
                {
                    AtPair = (u16*) AtUnit;
                    
                    *AtPair = (u16) Unit;
                }
                else
                {
                    if( Access == &AccessByte )
                    {
                        *AtUnit = (u8) Unit;
                    }
                    else // Something special.
                    {
                        (*PutUnit)( AtUnit, Unit );
                    }
                }
            }
        }
    }
}

/*------------------------------------------------------------
| ZeroBitArray
|-------------------------------------------------------------
|
| PURPOSE: To fill a bit array with zeros.
|
| DESCRIPTION:  
|
| EXAMPLE:  ZeroBitArray( A );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 01.26.97 
------------------------------------------------------------*/
void
ZeroBitArray( BitArray* A )
{
    FillBitArray( A, 0 );
}

