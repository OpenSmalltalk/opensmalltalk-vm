/*------------------------------------------------------------
| TLLog.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to application log functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 12.09.96
|          08.19.97 added C++ support.
|          08.02.98 Added conditional inclusion of 
|                   'MacWindows.h'.
|          12.30.98 Added Win32 support.
------------------------------------------------------------*/
#ifndef TLLOG_H
#define TLLOG_H

#ifdef __cplusplus
extern "C"
{
#endif
 
extern u32      IsLogEnabled;
                // 1 if the application log can accept 
                // new entries.

extern u32      IsLogWindowOutputEnabled;
                // 1 if the application log can output
                // new entries in a text window.

extern u32      IsLogFileOutputEnabled;
                // 1 if the application log can output
                // new entries in a text file.

extern s8       TheLogFilePath[];
                // This refers the path of
                // the text file to be used for the application
                // log. 

extern FILE*    TheLogFile2;
                // If non-zero, the file pointer for the log file.
                
extern s32      LogCharsInLine; 
                // Number of characters in the current line.
                
extern s32      LogIndentOnWrap;
                // Number of characters to indent when a line wrap 
                // occurs.
                
extern s32      LineWrapLimit;
                // The number of characters in a line, beyond which 
                // a line wrap occurs.
                
void    CleanUpTheLog();
void    DumpHex( u8*, u32 );
void    HexDump( FILE*, u8*, u32 );
void    Note( s8*, ... );
void    SetUpTheLog( u32, u32 );
void    WrapLine( s32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLLOG_H
