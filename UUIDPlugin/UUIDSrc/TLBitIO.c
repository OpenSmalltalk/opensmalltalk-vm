/*------------------------------------------------------------
| TLBitIO.c
|-------------------------------------------------------------
|
| PURPOSE: To provide bit file input/output functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 07.03.96 from the disk in the book "The Data
|                   Compression Book, 2nd Ed." by Nelson & 
|                   Gailly.
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdio.h>
#include <stdlib.h>

#include "TLTypes.h"
#include "TLBitIO.h"

/*------------------------------------------------------------
| OpenOutputBitFile
|
| PURPOSE:  
|
| DESCRIPTION:  
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
BIT_FILE *
OpenOutputBitFile(s8 * name )
{
    BIT_FILE *bit_file;

    bit_file = (BIT_FILE *) calloc( 1, sizeof( BIT_FILE ) );
     
    bit_file->file = fopen( (char*) name, "wb" );
    bit_file->rack = 0;
    bit_file->mask = 0x80;
    
    return( bit_file );
}

/*------------------------------------------------------------
| OpenInputBitFile
|
| PURPOSE:  
|
| DESCRIPTION:  
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
BIT_FILE*
OpenInputBitFile( s8 *name )
{
    BIT_FILE* bit_file;

    bit_file = (BIT_FILE *) calloc( 1, sizeof( BIT_FILE ) );
     
    bit_file->file = fopen( (char*) name, "rb" );
    bit_file->rack = 0;
    bit_file->mask = 0x80;
    
    return( bit_file );
}

/*------------------------------------------------------------
| CloseOutputBitFile
|
| PURPOSE:  
|
| DESCRIPTION:  
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
void 
CloseOutputBitFile( BIT_FILE *bit_file )
{
    if( bit_file->mask != 0x80 )
    {
        putc( (u8) bit_file->rack, bit_file->file );
    }
    
    fclose( bit_file->file );
    
    free( (s8*) bit_file );
}

/*------------------------------------------------------------
| CloseInputBitFile
|
| PURPOSE:  
|
| DESCRIPTION:  
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
void 
CloseInputBitFile( BIT_FILE *bit_file )
{
    fclose( bit_file->file );
    
    free( (s8*) bit_file );
}

/*------------------------------------------------------------
| OutputBit
|
| PURPOSE:  
|
| DESCRIPTION:  
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
void 
OutputBit( BIT_FILE *bit_file, s16 bit )
{
    if( bit )
    {
        bit_file->rack |= bit_file->mask;
    }
        
    bit_file->mask >>= 1;
    
    if( bit_file->mask == 0 ) 
    {
        putc( (u8) bit_file->rack, bit_file->file );
     
        bit_file->rack = 0;
        bit_file->mask = 0x80;
    }
}

/*------------------------------------------------------------
| OutputBits
|
| PURPOSE:  
|
| DESCRIPTION:  
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
void 
OutputBits( BIT_FILE *bit_file, u32 code, s16 count )
{
    u32 mask;

    mask = (u32) ( 1U << ( count - 1 ) );
    
    while( mask != 0) 
    {
        if( mask & code )
        {
            bit_file->rack |= bit_file->mask;
        }
            
        bit_file->mask >>= 1;
        
        if( bit_file->mask == 0 ) 
        {
            putc( (u8) bit_file->rack, bit_file->file );
            
            bit_file->rack = 0;
            bit_file->mask = 0x80;
        }
        
        mask >>= 1;
    }
}

/*------------------------------------------------------------
| InputBit
|
| PURPOSE:  
|
| DESCRIPTION:  
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
s16 
InputBit( BIT_FILE *bit_file )
{
    s16 value;

    if( bit_file->mask == 0x80 ) 
    {
        bit_file->rack = (s16) getc( bit_file->file );
        
        if( bit_file->rack == EOF )
        {
            Debugger();
            // "Fatal error in InputBit!"
        }   
    }
    
    value = (s16) ( bit_file->rack & bit_file->mask );
    
    bit_file->mask >>= 1;
    
    if( bit_file->mask == 0 )
    {
        bit_file->mask = 0x80;
    }
        
    return( (s16) ( value ? 1 : 0 ) );
}

/*------------------------------------------------------------
| InputBits
|
| PURPOSE:  
|
| DESCRIPTION:  
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
u32 
InputBits( BIT_FILE *bit_file, s16 bit_count )
{
    u32 mask;
    u32 return_value;

    mask = (u32) ( 1L << ( bit_count - 1 ) );
    
    return_value = 0;
    
    while( mask != 0) 
    {
        if( bit_file->mask == 0x80 ) 
        {
            bit_file->rack = (s16) getc( bit_file->file );
            
            if( bit_file->rack == EOF )
            {
                Debugger();
                // "Fatal error in InputBit! 
            }
        }
    
        if( bit_file->rack & bit_file->mask )
        {
            return_value |= mask;
        }
    
        mask >>= 1;
    
        bit_file->mask >>= 1;
        
        if( bit_file->mask == 0 )
        {
            bit_file->mask = 0x80;
        }
    }
    
    return( return_value );
}

/*------------------------------------------------------------
| FilePrintBinary
|
| PURPOSE:  
|
| DESCRIPTION:  
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
void 
FilePrintBinary( FILE *file, u16 code, s16 bits )
{
    u16 mask;

    mask = (u16) ( 1 << ( bits - 1 ) );
    
    while( mask != 0 ) 
    {
        if( code & mask )
        {
            fputc( '1', file );
        }
        else
        {
            fputc( '0', file );
        }
            
        mask >>= 1;
    }
}

