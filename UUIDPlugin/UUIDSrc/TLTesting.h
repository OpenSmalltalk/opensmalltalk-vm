/*------------------------------------------------------------
| TLTesting.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to testing functions.
|
| DESCRIPTION:  
|
| NOTE: 
|
| HISTORY: 12.12.93 
------------------------------------------------------------*/
    
#ifndef _TLTESTING_H_
#define _TLTESTING_H_

extern u8       IsStopOnDependent;
            // Control flag set 1 if a unit test failure
            // terminates a test sequence or set to 0 if
            // the whole sequence will be run no matter what.
            
extern u32      RandomSeedForTest;
            // The random number seed to use for the current
            // test run.  This number should be used within
            // unit tests to initialize the random number
            // generator for those tests.

extern FILE*    TheLogFile;
            // Handle of the current test log file or zero if
            // there is no test log file open.

typedef struct 
{
    u32Procedure TestProcedure;
    s8*          NameOfProcedure;
} TestRecord;

int     printt( s8*, ... );
u32     RunTestSequence(TestRecord*, s8*);
u32     RunAllUnitTests();

#endif
