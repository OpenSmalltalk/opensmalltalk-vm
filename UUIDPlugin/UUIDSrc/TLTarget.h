/*------------------------------------------------------------
| TLTarget.h
|-------------------------------------------------------------
|
| PURPOSE: To provide application target-dependent 
|          configuration options.
|
| DESCRIPTION: Compiler and target machine-dependent options 
| are defined in this file for each specific application.
|        
| NOTE: This file should be included first in all TLTools
|       files.
|
| HISTORY: 01.19.98
|          01.27.99 Added #undef HUGE_VAL correction to handle
|                   incompatibility between 'math.h' and 'fp.h'
|                   under Metrowerks.
|          05.26.01 Added FOR_DRIVER.
|          05.29.01 Added DebugPrint.
|          06.05.01 Added DEBUG_BUILD and operating system
|                   symbols.
|          06.19.01 Added FOR_UNIT_TESTING.
------------------------------------------------------------*/


#ifndef TLTARGET_H
#define TLTARGET_H

#ifdef __cplusplus
extern "C"
{
#endif

// Define standard numeric types.
#include "NumTypes.h"

// If using the Metrowerks compiler...
#ifdef __MWERKS__

    #define USING_CODEWARRIOR_COMPILER   1
    
#endif

// If using the Microsoft compiler...
#if defined( _MSC_VER ) && !defined( __MWERKS__ )

    #define USING_MICROSOFT_COMPILER      1 
    
#endif

// Define the target operating system to build for, one or 
// more of the following:
#define FOR_MACOS     1
//#define FOR_MACOSX  1
//#define FOR_WINNT   1
//#define FOR_WIN98   1
//#define FOR_WIN2000  1

// Define the following symbol to include the 'main()'
// routine for a unit test program.
// #define FOR_UNIT_TESTING 1


// Define the following symbol to build a device driver.
//#define FOR_DRIVER    1

// Define this symbol for making Plug-n-play drivers.
//#define FOR_PNP_DRIVER    1

// Define the following symbol to build a debug build.
//#define FOR_DEBUG   1


// If building for an Intel CPU target...
//
//   Metrowerks' symbol     Microsoft's symbol

#if defined( __INTEL__ ) || defined( _M_IX86 )

    #define FOR_INTEL   1

#endif


// If building for MacOS target...
#ifdef macintosh

    #define FOR_MACOS     1

#endif
 
#ifdef FOR_INTEL 

    #ifdef FOR_DRIVER 
    
        #ifdef FOR_PNP_DRIVER  

            #include <WDM.h>

        #else // Not FOR_PNP_DRIVER.

            #include <NTDDK.h>

        #endif // FOR_PNP_DRIVER

        #ifdef FOR_WIN98

            // Debugger()
            //-----------  
            // PURPOSE: To stop in the debugger in debug builds and do
            // nothing in release builds.
            #define Debugger()           
 
            // DebugPrint(x)
            //-------------- 
            // PURPOSE: To print a string to the debugger for debug builds
            // and do nothing for release builds.
            #define DebugPrint       
                    
        #endif // FOR_WIN98

        #ifdef FOR_WIN2000

            #ifdef FOR_DEBUG
            
                // Debugger()
                //-----------  
                // PURPOSE: To stop in the debugger in debug builds and do
                // nothing in release builds.
                #define Debugger            DbgBreakPoint 
                        // KdBreakPoint can only be used for Win2000 or later.
                        //
                        // KdBreakPoint is identical to DbgBreakPoint in debug
                        // builds and is a nop for release builds.

                // DebugPrint(x)
                //-------------- 
                // PURPOSE: To print a string to the debugger for debug builds
                // and do nothing for release builds.
                #define DebugPrint          DbgPrint 
                        // KdPrint can only be used for Win2000 or later.
                        //
                        // KdPrint is identical to DbgPrint in debug builds and
                        // is a nop for release builds.
                        
            #else // Not FOR_DEBUG

                static u32 noprintf( s8* n, ... ) { return( 0 ); }

                // Debugger()
                //-----------  
                // PURPOSE: To stop in the debugger in debug builds and do
                // nothing in release builds.
                #define Debugger     

                // DebugPrint(x)
                //-------------- 
                // PURPOSE: To print a string to the debugger for debug builds
                // and do nothing for release builds.
                #define DebugPrint          noprintf
                    
            #endif // FOR_DEBUG
            
        #endif // FOR_WIN2000
                
    #else // Not FOR_DRIVER.
    
        #ifndef _WIN32 
            #define _WIN32  1
        #endif
 
        // If building for Windows NT 4.0 or above.
        #if defined(FOR_WINNT) || defined(FOR_WIN2000)
            //
            // Define this symbol to enable new functions for NT 4.0:
            // From page 998 of "Advanced Windows", 3rd Ed. by Richter.
            #define _WIN32_WINNT    0x0400
        #endif
    
        // Master include file for Windows applications.
        #include <windows.h>
         
        // If using the Metrowerks compiler...
        #ifdef USING_CODEWARRIOR_COMPILER

            #include <ansi_fp.h>

            #define INLINE  inline
            #define ISNAN   isnan

        #endif
 
        // If using the Microsoft compiler...
        #ifdef USING_MICROSOFT_COMPILER

            #include <float.h>
            #include <math.h>

            #define INLINE  __inline
            #define ISNAN   _isnan

        #endif
 
        #ifndef pi

        #define pi  ( (double) 3.14159265358979323846 )

        #endif // pi

        #ifdef FOR_DEBUG

            #include <stdio.h>

            // Debugger()
            //-----------  
            // PURPOSE: To stop in the debugger in debug builds and do
            // nothing in release builds.
            #define Debugger()      __asm { int 3 } // DebugBreak()

            // DebugPrint(x)
            //-------------- 
            // PURPOSE: To print a string to the debugger for debug builds
            // and do nothing for release builds.
            #define DebugPrint      printf

        #else // Not FOR_DEBUG

            static u32 noprintf( s8* n, ... ) { return( 0 ); }

            // Debugger()
            //-----------  
            // PURPOSE: To stop in the debugger in debug builds and do
            // nothing in release builds.
            #define Debugger()       

            // DebugPrint(x)
            //-------------- 
            // PURPOSE: To print a string to the debugger for debug builds
            // and do nothing for release builds.
            #define DebugPrint      noprintf

        #endif // FOR_DEBUG
        
        #include "TLTimeNT.h"
            
    #endif // FOR_DRIVER

#endif // FOR_INTEL 




// If building for MacOS target...

#ifdef macintosh

    #ifdef FOR_DRIVER


    #else // Not FOR_DRIVER

        #ifdef __cmath__    // math.h and fp.h are not compatible, so we have to
            #undef HUGE_VAL     // undefine the symbols that are defined in both before
            #undef DECIMAL_DIG  // we #include <fp.h> below.
            #undef fpclassify
            #undef isnormal
            #undef isfinite
            #undef isnan
            #undef signbit
        #endif

        #ifndef __FP__      // NOTE: You need to add the appropriate version of
            #include <fp.h> // MathLib to use the routines that involve double_t
        #endif              // floating point numbers.

        #define INLINE  inline
        #define ISNAN   isnan

        #ifdef FOR_DEBUG
        
            #include <stdio.h>
            
            #define Debugger()      Debugger() 

            #define DebugPrint      printf 

        #else // Not FOR_DEBUG

            static u32 noprintf( s8* n, ... ) { return( 0 ); }

            #define Debugger()       

            #define DebugPrint      noprintf 

        #endif // FOR_DEBUG
        
        #include "TimePPC.h"
    
    #endif // FOR_DRIVER

#endif // macintosh



#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLTARGET_H
