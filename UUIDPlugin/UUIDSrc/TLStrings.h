/*------------------------------------------------------------
| TLStrings.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface for zero-terminated string 
|          functions.
|
| DESCRIPTION:   
|
| NOTE: See 'TLBString.c' for strings prefixed with a count byte.
|       See 'TLParse.h' for string parsing functions.
|
| HISTORY: 02.01.89 
|          02.15.93 from xstring.h.
|          01.12.94 added #include <Ascii.h> replacing ctype.h
|          01.13.94 added ConvertIntegerToString, ReverseString
|          01.14.94 added FindLastByteInLine
|          01.27.94 added ConvertStringToInteger, ConvertStringTo32BitInteger
|          08.19.97 added C++ support.
|          01.08.99 Added 'NamedStringTable'.
------------------------------------------------------------*/
    
#ifndef  TLSTRINGS_H
#define  TLSTRINGS_H

#ifdef __cplusplus
extern "C"
{
#endif

// Type definitions and forward references to the structures 
// defined below.
typedef struct StringTable  StringTable;

#ifndef CStr255
typedef s8 CStr255[256];    
                // like Str255, except for C-format strings. 
                // from 'NewsWatcher'.
#endif

/*------------------------------------------------------------
| StringTable
|-------------------------------------------------------------
|
| PURPOSE: To organize strings into a table that can be 
|          referenced by name.
|
| DESCRIPTION: Using this record, tables of strings can be
| referenced by name and tables can be connected into lists
| of related tables.
|
| EXAMPLE:
|   
|   // The first string table in the list of predefined PDF
|   // font encodings.
|   StringTable 
|   PDFDocEncodingStringTable =
|   {
|       "PDFDocEncoding",               // Name
|       PDF_PDFDocEncoding,             // Strings
|       257,                            // StringCount
|       257,                            // MaxStringCount
|       &MacExpertEncodingStringTable   // Next
|   };
|
| NOTE: 
|
| ASSUMES: Strings are one byte per character ASCII strings.
|
| HISTORY: 01.08.99
------------------------------------------------------------*/
struct StringTable
{
    s8*             Name;   // The string that names the 
                            // table.
                            // Zero-terminated C string.
                            //
    s8**            Strings;// An array of C string 
                            // addresses terminated by an 
                            // entry holding zero.
                            //
    u32             StringCount;
                            // How many strings are 
                            // currently held in the table.
                            //
    u32             MaxCount;   
                            // How many strings can be held 
                            // in the string array without 
                            // having to reallocate it.
                            //
    StringTable*    Next;   // The next string table in a
                            // list of tables.  Holds zero
                            // if this is the last record
                            // in the list.
                            //
};

s8*             AddressOfLastCharacterInString(s8*);
void            AppendString2(s8*, s8*);
void            AppendStrings(s8*, s8*, ...);
void            AppendUnicodeString( u16*, u16* );
s32             CompareStrings(s8*, s8*);
s32             CompareStringsCaseSensitive(s8*, s8*);
void            ConvertStringToLowerCase(s8*);
void            ConvertStringToUpperCase(s8*);
u32             Convertu64ToString( u64, s8* );
void            CopyCToPascalString( s8*, s8* );
void            CopyPascalToCString( s8*, s8* );
void            CopyString(s8*, s8*);
void            CopyStringToUnicodeString( s8*, u16* );
void            CopyUnicodeString( u16*, u16* );
u32             CountString(s8*);
u32             CountStringMB( u8*, u32 );
u32             CountUnicodeString( u16* );
void            FillString( s8*, u32 );
s8*             FindLastByteInLine(s8*);
s32             IndexOfStringInArray( s8**, s8* );
void            InsertString(s8*, s8*, u32);
u32             IsMatchingStrings( s8*, s8* );
u32             IsStringInArray( s8*, s8**);
s8*             LookUpString( s8**, s8*, s32 );
void            MoveString( s8*, s8* );
StringTable*    NthStringTable( StringTable*, u32 );
void            ReplaceBytesInString(s8*, u16, u16);
void            ReverseString(s8*);
void            RightJustifyInteger( s8*, s32, s64 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLSTRINGS_H
