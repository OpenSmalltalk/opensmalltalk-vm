/*------------------------------------------------------------
| TLBitField.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to bit field functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 02.17.97
------------------------------------------------------------*/

#ifndef BITFIELD_H
#define BITFIELD_H

#ifdef __cplusplus
extern "C"
{
#endif

void    ConvertBitsToString( u8*, s8*, u32 );
void    ConvertStringToBits( s8*, u8* );
List*   ExtractBitFields( u8*, s8* );
s8*     ExtractNamedBitFields( u8*, s8*, s8* );
u32     FindMarkerOfNamedField( s8*, s8*, s8* );
Item*   FindMatchingBinaryLiteral( List*, s8* );
List*   FindMatchingBinaryLiterals( List*, s8* );
u32     FindNthFieldMarkerInBitRecordFormat( s8*, u32 );
void    InsertBitFields(  u8*, List*, s8* );
void    InsertNamedBitFields( u8*, s8*, s8*, s8* );
u32     IsMatchingBinaryLiteral( s8*, s8* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif
