/*------------------------------------------------------------
| NAME: TLBitArray.h
|-------------------------------------------------------------
| 
| PURPOSE: To provide interface for two-dimensional bit 
|          array procedures.
|
| DESCRIPTION:  
|
| NOTE: See also 'Bit'h' and 'Two.c' for working with powers 
|       of 2.
|
| ASSUMES: Bytes are 8 bits.
|
| HISTORY: 01.20.99 Extended the size of 'PackingReference'
|                   field to 64-bits from 32.
------------------------------------------------------------*/
    
#ifndef _BITARRAY_H_
#define _BITARRAY_H_

#ifdef __cplusplus
extern "C"
{
#endif

/*************************************************************/
/*             B I T   A R R A Y   R E C O R D               */
/*************************************************************/
//
// Organizes all information about a two-dimensional array 
// of bits.
//
// RULES:
//
// 1. Data is in C-standard row-major order which means 
//    that all of the bits of a row are stored contiguously.
//
// 2. Bit rows begin on access unit boundaries so that the 
//    last bit of one row may or may not touch the first bit
//    of the next.
//               
typedef struct
{
    u64 PackingReference; 
            // The standard packing pattern, 0x0807060504030201, 
            // as stored by the CPU that produced the content 
            // of this record.  This field must be the first 
            // field of this structure.
                        //
    u32 Packing;        // How binary digits are stored
                        // in each access unit of the 
                        // 'Data' field, a 5-bit Packing Order
                        // Code: see 'TLPacking.h'.
                        //
    u32 RowCount;       // The number of rows of bits: row 0 
                        // is first.
                        //
    u32 ColCount;       // The number of columns of bits: 
                        // column 0 is first.
                        //
    u32 IsDataDynamic;  // 1 if the data buffer is 
                        // dynamically allocated and so should 
                        // be freed when the bit array is 
                        // deleted.
                        //
    u32 AccessUnitsPerRow; // The number of access units 
                        // in each row.
                        //
    u32 BytesPerRow;    // The number of bytes in each row.
                        //
    AccessUnit * Access; // How the 'Data' field is accessed.
                        //
    u8* Data;           // Where the bit data is stored. 
                        // May or may not be dynamic. Rows may 
                        // or may not be contiguous.
                        //
    u8**  Row;          // An array of addresses to the first 
                        // access unit in each row of the 
                        // 'Data' field. Addresses are
                        // unit addresses. Dynamic.
} BitArray;

// -------------------PROTOTYPES-----------------------------

void        DeleteBitArray( BitArray* );
void        ExpandBitArrayToByteArray( 
                BitArray*, ByteArray*, u32, u32 );
void        FillBitArray( BitArray*, u64 );
BitArray*   MakeBitArray( u32, u32, AccessUnit* );
void        OneFillBitArray( BitArray* );
void        ReduceByteArrayToBitArray( 
                ByteArray*, BitArray*, u32 );
void        ZeroBitArray( BitArray* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif
