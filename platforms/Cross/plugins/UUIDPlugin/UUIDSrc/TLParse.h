/*------------------------------------------------------------
| TLParse.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface for parsing procedures.
|
| DESCRIPTION:  
|
| NOTE: 
|
| HISTORY: 02.15.93 
|          12.31.93 added 'IsByteInString'
|          08.19.97 added C++ support.
|          01.27.00 Split out less commonly used functions
|                   to a new file called 'TLParseExtra.h'.
------------------------------------------------------------*/
    
#ifndef TLPARSE_H
#define TLPARSE_H

#ifdef __cplusplus
extern "C"
{
#endif

extern  u32 CountOfBytesParsed;

// Globals used to refer to the current word in the 
// current string.
extern s8* AtTheString;     // Address of first byte of current 
                            // string.
                            //
extern s8* AtTheStringEnd;  // Address of terminal zero of  
                            // current string.
                            //
extern s8* TheWord;         // Address of first byte of the 
                            // current word in the current 
                            // string or zero if no word is 
                            // current.
                            //
extern s8* AtTheWordEnd;    // Address of first byte after the
                            // current word or the address of 
                            // the string terminator if there 
                            // is no current word.
                            //
extern s8  TheWordDelimiter;// The byte following the current 
                            // word which has temporarily been
                            // replaced with a zero to make the
                            // word a string.

extern Stack* StringStack;  // Stack used to preserve/restore
                            // the current string context.

s8*     AddressOfNthWordInLine( s8*, s32 );
s32     CopyBytesUntilDelimiter( u8*, u8*, u32);
u32     CountBytesOfTypeInString( s8*, u16 );
u32     CountDataInString( s8* );
u32     CountFiguresInString( s8* );
u32     CountItemsInCommaDelimitedString( s8* );
u32     DeTabLine( s8*, s8*, u32, u32 );
s8*     FindByteInString( s32, s8* );
u8*     FindByteInBytes( s32, u8*, s32 );
u8*     FindBytesInBytes( u8*, s32, u8*, s32 );
s8*     FindNthByteOfType( s8*, u32, u32 );
s8*     FindStringInBytes( s8*, u8*,  s32 );
s8*     FindStringInString(s8*, s8*);
u32     FindFieldHoldingValueInCommaDelimitedString( s8*, s8* );
f64     GetFirstDatumInString( s8* );
s32     IndexOfWordInLine( s8* );
u32     InsertDelimiters( u8*, u32, u32, u8*, u32 );
void    IntersectString( s8*, s8*, s8* );
u32     IsAnySubStringInString( s8**, s8* );
u32     IsByteInString(s8*, u16);
u32     IsParensBalancedInString( u8*, u32, u32, u32 );
u32     IsPrefixForString( s8*, s8* );
u32     IsSuffixForString(s8*, s8*);
void    JoinNameAndValue( s8*, s8*, u32, s8* );
s8*     LocationOfNthItemInCommaDelimitedString( u32, s8* );
u8*     ParseBytes( u8*,u8*, u8*, u16 ); 
s8*     ParseDatum( s8*, s8* );
s8*     ParseString( s8*, s8*, u32 );
u32     ParseUnsignedInteger( s8** );
f64     ParseUnsignedIntegerTof64( s8** );
s8*     ParseWord( s8*, s8* );
void    ReferToString( s8* );
void    ReplaceRangeInBuffer( u8*, u32, u8*, u32, u8*, u32);
void    ReplaceRangeInBufferAndPadSlack( u8*, u32, u8*, u32, u8*, u32, u32 );
void    RevertToString();
u8*     ScanBytesEQ( u8*, u8*, u16 );
u8*     ScanBytesEQBackward( u8*, u8*, u16 );
u8*     ScanBytesNE(u8*, u8*, u16);
u8*     ScanToDigit( u8*, u8* );
u8*     ScanToDigitBackward( u8*, u8* );
u8*     ScanForNonDigitOrPeriodBackward( u8*, u8* );
void    SkipWhiteSpace( s8** );
void    SkipWhiteSpaceBackward( s8** );
void    SkipWord( s8** );
void    SplitNameAndValue( s8*, s8*, u32, s8* );
void    StripByteFromString( s8*, u32 );
void    StripLeadingWhiteSpace( s8* );
void    StripTrailingWhiteSpace( s8* );
void    ToFirstWord();
void    ToLastWord();
void    ToNextLine( s8** );
void    ToNextWord();
void    ToNoWord();
void    ToPriorWord();
void    ToStartOfLine( s8** );
void    ToStringTerminator( s8** );
void    ToWhiteSpace( s8** );
s8*     ValueOfNthItemInCommaDelimitedString( u32, s8* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLPARSE_H
