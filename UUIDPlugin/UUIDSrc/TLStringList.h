/*------------------------------------------------------------
| TLStringList.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to string list functions.
|
| DESCRIPTION:
| 
| CONVENTION: The 'SizeOfData' field of each list item holds
|             the character count of each string.
|        
| HISTORY: 08.11.01 
------------------------------------------------------------*/

#ifndef TLSTRINGLIST_H
#define TLSTRINGLIST_H

#ifdef __cplusplus
extern "C"
{
#endif

// Strings in the list may be classified by setting bits in
// TypeOfData field of the Item record that refers to the
// string.
//
// This is how bits in the TypeOfData field are interpreted.
#define ZERO_ENDED_STRING       1
            // Configuration flag set to 1 if the string has
            // a zero terminator byte, or 0 if not.
            
#define COUNTED_STRING          2
            // Configuration flag set to 1 if the Item record
            // refers to a sequence of characters that have
            // been counted or, 0 if not.
            //
            // The character count if any is held in the 
            // SizeOfData field of the Item record that refers
            // to the string.
            //
            // A counted character sequence may or may not 
            // have a zero terminator byte.
            
// Type definitions and forward references to the structures 
// defined below.
typedef struct ThatChar     ThatChar;
 
/*------------------------------------------------------------
| ThatChar
|-------------------------------------------------------------
|
| PURPOSE: To provide a way to refer to a single character in
|          the context of a string list.
|
| DESCRIPTION: This is a character cursor.
|
| Think of this record as a finger pointing at a character in 
| a list to select it for special  processing. 
|
| This record organizes everything needed to refer to a 
| character in a way that supports easy traversal through the 
| string list.
|
| See TLList.h for more about lists.
|
| ASSUMES: Strings are 8-bit characters.
|
| HISTORY: 08.19.01 From ThatRecord.
------------------------------------------------------------*/
struct ThatChar
{
    //////////////////////////////////////////////////////////
    //                                                      //
    //           C U R R E N T   C H A R A C T E R          //
    //                                                      //
    //////////////////////////////////////////////////////////
    s8*     TheCharAddress; 
                // Address of the current character or zero 
                // if there is no character at the current 
                // position in the string list.
                //
    u32     TheCharOffset;
                // The offset of the character from the start
                // of the list, a zero-based index.
                //
                // This is only valid if TheCharAddress is
                // non-zero.
                //
    u32     TheCharInStringOffset;
                // The offset of the current character in the 
                // current string, a zero-based index.
                //                                                       
                // This is only valid if TheCharAddress is
                // non-zero.
                //
    //////////////////////////////////////////////////////////
    //                                                      //
    //              C U R R E N T   S T R I N G             //
    //                                                      //
    //////////////////////////////////////////////////////////
    Item*   TheStringItem;  
                // Address of the Item that refers to the
                // current string that holds the character.
                //
                // The DataAddress of this record refers to
                // the first byte of the current string.
                //
                // The TypeOfData field identifies the
                // string type, COUNTED_STRING and/or 
                // ZERO_ENDED_STRING.
                //
                // If the string is counted then the 
                // SizeOfData field holds the number of 
                // characters in the string, not counting 
                // any zero terminator byte.
                //
    u32     TheStringOffset;
                // The offset of the string from the start
                // of the list, a zero-based index.
                //
                // If strings represent lines of text then
                // this can be interpreted as the line number.
                // 
    //////////////////////////////////////////////////////////
    //                                                      //
    //               C U R R E N T   L I S T                //
    //                                                      //
    //////////////////////////////////////////////////////////
    List*   TheStringList;   
                // Address of the list of strings that holds 
                // the current string and character.
};


void    CopyStringListToMatrix( Matrix*, s32, s32, List* );
void    DetabStringList( List*, u32 );
void    ExtentOfStringList( List*, u32*, u32* );
List*   MatrixToStringList( Matrix* );
void    MeasureStringList( List* );
Matrix* ReadTextFileIntoMatrix( s8*, u32 );
void    ReplaceStringInStringList( List*, s8*, s8* );
void    SaveTextMatrixToFile( Matrix*, s8*, s8* );
u32     SizeOfString( Item* );
u32     SizeOfStringList( List* );
Matrix* StringListToMatrix( List* );
void    StripLeadingWhiteSpaceInStringList( List* );
void    StripTrailingWhiteSpaceInStringList( List* );
void    ToChar( ThatChar*, s8 );
void    ToCharNotOfClass( ThatChar*, s8*, u32 );
void    ToCharOfClass( ThatChar*, s8*, u32 );
void    ToChars( ThatChar*, s8*, u32 );
void    ToFirstCharInString( ThatChar* );
void    ToFirstString( List*, ThatChar* );
void    ToLastCharInString( ThatChar* );
void    ToLastString( List*, ThatChar* );
void    ToNextChar( ThatChar* );
void    ToNextCharInString( ThatChar* );
void    ToNextChars( ThatChar*, u32 );
void    ToNextString( ThatChar* );
void    ToNextStringWithChars( ThatChar* );
void    ToNonWhiteSpaceSL( ThatChar* );
void    ToPriorChar( ThatChar* );
void    ToPriorCharInString( ThatChar* );
void    ToPriorString( ThatChar* );
void    ToPriorStringWithChars( ThatChar* );
void    ToWhiteSpaceSL( ThatChar* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLSTRINGLIST_H
