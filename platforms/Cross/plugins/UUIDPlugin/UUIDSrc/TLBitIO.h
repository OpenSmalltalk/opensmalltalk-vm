/*------------------------------------------------------------
| TLBitIO.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to bit file I/O functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 07.03.96 
|          08.19.97 added C++ support.
------------------------------------------------------------*/

#ifndef _BITIO_H
#define _BITIO_H

#ifdef __cplusplus
extern "C"
{
#endif

typedef struct bit_file 
{
    FILE*   file;
    u8      mask;
    s16     rack; // The input character from 'getc'.
} BIT_FILE;

BIT_FILE*   OpenInputBitFile( s8* );
BIT_FILE*   OpenOutputBitFile( s8* );
void        OutputBit( BIT_FILE *, s16 );
void        OutputBits( BIT_FILE *, u32, s16);
s16         InputBit( BIT_FILE *);
u32         InputBits( BIT_FILE *, s16 );
void        CloseInputBitFile( BIT_FILE * );
void        CloseOutputBitFile( BIT_FILE * );
void        FilePrintBinary( FILE *, u16, s16 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif  // _BITIO_H 
