/*------------------------------------------------------------
| TLAscii.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface for ASCII code procedures.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 08.28.93 from ascii.txt.
|          08.19.97 added C++ support.
------------------------------------------------------------*/

#ifndef TLASCII_H
#define TLASCII_H

#ifdef __cplusplus
extern "C"
{
#endif

// Ascii codes by name:
#define    CarriageReturn         13
#define    ControlC                3 
#define    EnterKey                3

#define    ControlZ               26 //  eof marker for DOS
#define    Tab                     9
#define    LineFeed               10
#define    FormFeed               12
#define    Space                  32
#define    Backspace               8
#define    Backslash              92
// from 'def.h' of 'NewsWatcher' source:

// Macros

#define isLWSP(a)      ((a) == ' ' || (a) == '\t')
#define isLWSPorCR(a)  (isLWSP(a) || (a) == CR)
#define isPrintable(a) ((a) >= ' ' && (a) != 0x7f)
#define isoctal(a)     ((a) >= '0' && (a) <= '7')
#define isCRorLF(a)    ((a) == CR || (a) == LF)

#define IsOctalDigit(a) ( (a) >= '0' && (a) <= '7' )

#define IsHexDigit(a)   ( ( (a) >= '0' && (a) <= '9' ) || \
                          ( (a) >= 'a' && (a) <= 'f' ) || \
                          ( (a) >= 'A' && (a) <= 'F' ) )

// The ordering of comparison tests here is based on 
// expected frequency.                         
#define IsWhiteSpace(a) \
            ( (a) == Space          || \
              (a) == Tab            || \
              (a) == CarriageReturn || \
              (a) == LineFeed       || \
              (a) == FormFeed )

                          
#define IsPrintableASCIICharacter(a) ( (a) >= 32 && (a) <= 126 )

#define CR          CarriageReturn
#define LF          LineFeed
#define BS          Backspace
#define FF          FormFeed
#define CRSTR       "\r"
#define LFSTR       "\n"
#define CRLF        "\r\n"
#define CRCR        "\r\r"
#define CRLFCRLF    "\r\n\r\n"

#define homeKey             0x01        // ascii code for home key
#define enterKey            0x03        // ascii code for enter key
#define endKey              0x04        // ascii code for end key
#define helpKey             0x05        // ascii code for help key
#define deleteKey           0x08        // ascii code for delete/backspace
#define tabKey              0x09        // ascii code for tab key
#define pageUpKey           0x0B        // ascii code for page up key
#define pageDownKey         0x0C        // ascii code for page down key
#define returnKey           0x0D        // ascii code for return key
#define leftArrow           0x1C        // ascii code for left arrow key
#define rightArrow          0x1D        // ascii code for right arrow key
#define upArrow             0x1E        // ascii code for up arrow key
#define downArrow           0x1F        // ascii code for down arrow key
#define forwardDelKey       0x7F        // ascii code for forward delete key

#define escapeKeyCode       0x35        // key code for escape key
#define clearKeyCode        0x47        // key code for clear key


extern u8   BinaryDigit[];
extern u8   OctalDigit[];
extern u8   DecimalDigit[];
extern u8   HexDigit[];
extern u8   HexDigitToBinary[];

// End-of-line strings.
extern s8   MacEOLString[];
extern s8   WinEOLString[];
extern s8   UnixEOLString[];
extern s8*  EOLString[];

// End-of-line types:
#define MacEOL  0
#define WinEOL  1
#define UnixEOL 2

void    ConvertDataToASCIIHex( u8*, u8*, u32, u32 );
void    ConvertDataToPrintableASCII( u8*, u8*, u32, u32 );
u32     ConvertDataToSourceCode( s8*, u8*, s8*, u32, u32, u8* );
u16     ConvertLetterToLowerCase( u16 );
u16     ConvertLetterToUpperCase( u16 );
u8*     GetCharMB( u8*, u32*, u32, u32, u32 );

//u32   IsPrintableASCIICharacter( u16 );
u32     IsDigit( u16 );
u32     Is1Thru9( u16 );
u32     IsHex( s8 );
u32     IsLetter( u16 );
u32     IsLowerCaseLetter( u16 );
u32     IsUpperCaseLetter( u16 );

u8*     PutCharMB( u8*, u32, u32, u32, u32 );

void    ReplaceControlCodesWithSpaces( s8*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif
