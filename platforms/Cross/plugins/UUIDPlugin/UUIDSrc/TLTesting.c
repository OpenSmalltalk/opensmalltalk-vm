/*------------------------------------------------------------
| TLTesting.c
|-------------------------------------------------------------
|
| PURPOSE: To test a sequence of procedures.
|
| DESCRIPTION: Every procedure in the given table is 
| validated using automated testing.  Known values are given 
| to each procedure and tests are made for expected results.  
| Test results are reported to the display and to the current
| TheLogFile. Some tests may require visual validation.
|
| NOTE: 
|
| HISTORY: 12.12.93 
|          06.12.01 Added comments and minor revisions.
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>  
#include <ctype.h>
#include <stdarg.h>

#include "NumTypes.h"
#include "TLTypes.h"
#include "TLRandom.h"

#include "TLTesting.h"

u8      IsStopOnDependent = 1;
            // Control flag set 1 if a unit test failure
            // terminates a test sequence or set to 0 if
            // the whole sequence will be run no matter what.
            
u32     RandomSeedForTest = 1298103;
            // The random number seed to use for the current
            // test run.  This number should be used within
            // unit tests to initialize the random number
            // generator for those tests.

FILE*   TheLogFile = 0;
            // Handle of the current test log file or zero if
            // there is no test log file open.

// Refer to test sequences defined in other files here so 
// they can be included in the procedure 'RunAllTests()' 
// below.   This is for example only.
// extern TestRecord ListTestSequence[];

/*------------------------------------------------------------
| printt
|-------------------------------------------------------------
|
| PURPOSE: To print a formatted string to both standard output
|          and to the test log file.
|
| DESCRIPTION: The input parameters are exactly the same as 
| for 'printf'.
|
| EXAMPLE:  printt( "My value: %d\n", x );
|           
| INPUT: 
|
|   Format      Standard 'printf' format string.
|
|   ...         Variable number of output parameters.
|
| OUTPUT:
|
|   Printed output to standard output if TheLogFile is 
|   non-zero.
|
| RETURN: Number of characters output.
|
| HISTORY: 01.02.01 TL From Note() in TLLog.c.
------------------------------------------------------------*/
int
printt( s8* Format, ... )
{
    s8  SprintfIn[4096];  
    s8  SprintfOut[4096]; 
    s8  FinalString[4096]; 
    s8  AByte;
    s8* In;
    va_list ap;
    
    // Clear the final format string.
    FinalString[0] = 0;
    
    // Initialize 'ptr' to point to the first argument after
    // the format string.
    va_start( ap, Format );
    
    // Construct the finished string by working through
    // the format string.
    // %...<someletter> is the pattern that is detected 
    // and handed to 'sprintf' for conversion.
    In = SprintfIn;
    
    while( *Format )
    {
        AByte = *Format++;
        
        // Feed byte to sprintf input buffer.
        *In++ = AByte;
        
        // If not the start of a formatting section.
        if( AByte != '%' ) 
        {       
            continue;
        }
        else // May be start of formatting section.
        {
            if( *Format == '%' ) // A literal '%'.
            {
                Format++; // Consume the extra '%'.
                continue;
            }
            
            // This is the start of a formatting section.
BuildFormattingSection:
                
            // Get next byte.
            AByte = *Format++;
            
            // Feed byte to sprintf input buffer.
            *In++ = AByte;
            
            // If the byte is not a letter of the alphabet. 
            if( ! isalpha( AByte ) )
            {
                goto BuildFormattingSection;
            }
            
            // If the letter is an optional size spec. 
            if( AByte == 'l' ||
                AByte == 'L' ||
                AByte == 'h' )
            {
                // Continue building the format.
                goto BuildFormattingSection;
            }
                
            // If byte is any other letter, then we have 
            // reached the end of a format spec.
            *In = 0; // Terminate string.
                    
            // Use the letter to get the type of the
            // argument.
            switch( AByte )
            {
                // Characters.
                case 'c':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) ); 
                             // chars take 4 bytes on the
                             // stack.
                    break;
                }
                
                // String
                case 's':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) );
                    break;
                }
                        
                // Signed integers.
                case 'd':
                case 'i':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,s32) );
                    break;
                }
                        
                // Unsigned integers.
                case 'o':
                case 'u':
                case 'x':
                case 'X':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,u32) );
                    break;
                }

                // Any floating point.
                case 'e':
                case 'E':
                case 'f':
                case 'g':
                case 'G':
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,double) );
                    break;
                }
                        
                // Address of something.
                case 'p':
                default:
                {
                    sprintf( (char*) SprintfOut, 
                             (char*) SprintfIn,
                             va_arg(ap,void*) );
                    break;
                }
            }
                    
            // Append the format output to the
            // final string.
            strcat( FinalString, SprintfOut );
                
            // Reset the pointer for the input string
            // accumulator.
            In = SprintfIn;
        }
    }
    
    // Terminate the sprintf input buffer.
    *In = 0;
    
    // If there are letters in the sprintf input buffer,
    // convert and append them to the final string.
    if( In > SprintfIn )
    {
        sprintf( (char*) SprintfOut, (char*) SprintfIn );
        
        // Append the output to the final string.
        strcat( FinalString, SprintfOut );
    }
    
    va_end( ap );
    
    // If the test log file is open.
    if( TheLogFile )
    {
        // Print the string to the file.
        fprintf( TheLogFile, "%s", FinalString );
        
        // Flush the file.
        fflush( TheLogFile );
    }
    
    // Print the string and return the number of characters
    // output.
    return( printf( "%s", FinalString ) );
}

/*------------------------------------------------------------
| RunTestSequence
|-------------------------------------------------------------
|
| PURPOSE: To run tests in a sequence.
|
| DESCRIPTION: Every procedure in the given table is 
| validated using automated testing.  Known values are given 
| to each procedure and tests are made for expected results. 
| 
| Test results are reported to the display and to the current
| test log file if it is open. 
|
| Some tests may require visual validation.
|
| If any test fails then the remaining tests in the sequence
| are skipped and the number of the failing test is returned.
|
| Tests in a sequence should be organized so that the more
| primitive functions come before the more complex functions
| that depend on the more primitive ones.
|
| EXAMPLE:  
|
|    result = RunTestSequence( MyUnitTests, "MyUnitTests" );
|
| OUTPUT:
|
|   Printed output to standard output and to the current
|   test log file if it's open.
|
| RETURN:  
|
|   0    PASS, all tests passed -- no errors.
|
|  >0    FAIL, number of the first test that fails in the 
|        sequence, a one-based index, eg. the first test is 1.
|
|
| HISTORY: 11.06.93 TL
|          05.05.96 Removed test count and used zero end mark
|                   instead.
|          01.02.01 Added return value and comments.
|          01.03.01 TL Revised comments.
|          01.25.01 TL Added extra newline following the 
|                      title.
|          01.29.01 TL Added setting up the random number
|                      generator for the test sequence.
|          02.16.01 TL Disabled random number set up for the
|                      Mac temporarily.
|          06.12.01 Installed SetUpRandomNumberGenerator.
------------------------------------------------------------*/
u32
RunTestSequence( 
    TestRecord* Tests,
                    // Address of the table that defines the 
                    // test sequence.
                    //
    s8*         NameOfSequence )
                    // Printable name of the test sequence.
{
    u32 TestResult;
    u32 i;
    
    // Report the beginning of the test sequence.
    printt( "BEGIN TEST SEQUENCE: %s\n\n", NameOfSequence );
    
    // Start with the first test in the table.
    i = 0;

    // For every test in the given table -- the table is
    // terminated with a zero.
    while( Tests[i].TestProcedure )
    {
        // Report the test about to be performed.
        printt( "[%ld] Test: %s\n",
                i+1,
                Tests[i].NameOfProcedure );

        // Initialize the random number generator to the current
        // testing seed.
        SetUpRandomNumberGenerator( RandomSeedForTest );
                                    // A 32-bit value used to 
                                    // initialize the random 
                                    // number generator.
 
        // Run the test.
        TestResult = (*Tests[i].TestProcedure)();
        
        // If there was an error.
        if( TestResult ) 
        {
            printt( "************************************\n");
            printt( "...FAILED in section # %d.\n", TestResult );
            printt( "************************************\n");
    
            // If stopping sequence on unit error is enabled.
            if( IsStopOnDependent )
            {
                // Report the abnormal end of the test sequence.
                printt( "ABORT TEST SEQUENCE: %s,\n", NameOfSequence );
                printt( "  Skipping remaining tests in sequence to\n");
                printt( "  avoid cascading errors.\n");
                 
                // Abort the remainder of the tests in the sequence
                // to avoid cascading errors.
                //
                // Return the test number of the failing test, one-based
                // index.
                return( i+1 );
            }
        }
        else // No error.
        {
            printt( "...OK.\n\n" );
        }
        
        // Advance to next test.
        i++;
    }
    
    // Report the successful end of the test sequence.
    printt( "END TEST SEQUENCE: %s -- All tests OK.\n", 
            NameOfSequence );
     
    // Return zero if there were no errors in any of the
    // tests in the sequence.
    return( 0 );
}

/*------------------------------------------------------------
| RunAllUnitTests
|-------------------------------------------------------------
|
| PURPOSE: To show an example of how to run all desired unit 
|          test sequences.
|
| DESCRIPTION: Copy this procedure and insert your own test
| sequences.
|
| Each test sequence runs to completion or until one of it's 
| tests fails, at which point the next test sequence is 
| executed.
|
| After all test sequences complete a summary report is 
| printed.
|
| OUTPUT:
|
|    Prints test status to the display and to a log file
|    called "testlog.txt".
|
| RETURN:
|
| Status Code,
|
|   0   PASS, all tests passed.
|
|  >0   FAIL, one or more tests failed.
|
| HISTORY: 01.02.01 TL From ListTest_main.
|          01.03.01 TL Added comments.
------------------------------------------------------------*/
u32
RunAllUnitTests()
{
    u32 OverallResult;
    
    // Open the test log file.
    TheLogFile = fopen( "testlog.txt", "w" );
    
    // Report the beginning of all the API tests.
    printt( "===============\n" );
    printt( "BEGIN ALL TESTS\n" );
    printt( "===============\n" );
    
    // Start with the overall result code set to zero.
    OverallResult = 0;
 
    // Run a test sequence and accumulate the result.
// PUT YOUR TEST SEQUENCES HERE<<<<<<<<<<<<<<<<<<<<
//    OverallResult |= 
//      RunTestSequence( 
//          ListTestSequence,
//          "ListTestSequence" );

// Put other test sequences here.
//          
//    OverallResult |= 
//      RunTestSequence( 
//          "AnotherTestSequence", 
//          AnotherTestSequence );

    printt( "=======================================\n" );
    printt( "END ALL TESTS\n" );
    printt( "=======================================\n" );
    
    // If any of the test sequences resulted in an error.
    if( OverallResult )
    {
        printt( "SUMMARY: At least one test failed.\n" );
    }
    else
    {
        printt( "SUMMARY: All tests passed OK.\n" );
    }
    
    printt( "=======================================\n" );
    
    fclose( TheLogFile );
    
    // Return the overall result.
    return( OverallResult );
}

