/*------------------------------------------------------------
| TLUUID.c
|-------------------------------------------------------------
| 
| PURPOSE: To provide support for Universally Unique 
|          IDentifiers (UUID).
|
| DESCRIPTION: See 'UUID' header in 'TLUUID.h'.
|
|        This code creates only variant #1 UUIDs.
|
| NOTE: 
|
| HISTORY: 11.29.98 From 'uuid.c' of DCE released as 
|                   'PD-DCE-RPC.tar.Z'.
|
|( c) Copyright 1989 OPEN SOFTWARE FOUNDATION, INC.
|( c) Copyright 1989 HEWLETT-PACKARD COMPANY
|( c) Copyright 1989 DIGITAL EQUIPMENT CORPORATION
| To anyone who acknowledges that this file is provided 
| "AS IS" without any express or implied warranty:
| permission to use, copy, modify, and distribute this
| file for any purpose is hereby granted without fee, provided 
| that the above copyright notices and this notice appears in 
| all source code copies, and that none of the names of Open 
| Software Foundation, Inc., Hewlett-Packard Company, or 
| Digital Equipment Corporation be used in advertising or 
| publicity pertaining to distribution of the software without 
| specific, written prior permission.  Neither Open Software 
| Foundation, Inc., Hewlett-Packard Company, nor Digital 
| Equipment Corporation makes any representations about the 
| suitability of this software for any purpose.
------------------------------------------------------------*/

#include "TLTarget.h"  // Include this first.

#include <stdio.h>
#include <string.h>

#include "TLTypes.h"
#include "TLBytes.h"
#include "TLRandom.h"
#include "TLRandomExtra.h"

#ifdef macintosh

#include <Processes.h>
#include <OSUtils.h>
#include "TimePPC.h"

#endif // macintosh

#if defined( _WIN32_WINNT )

#include "TLTimeNT.h"

#endif // __INTEL__

#include "TLDate.h"
#include "TLUUID.h" 

 
// How many elements are returned by sscanf() when converting
// string formatted uuid's to binary.
#define UUID_ELEMENTS_NUM       11
#define UUID_ELEMENTS_NUM_OLD   10

// This is a globally available nil UUID constant that can be used 
// to initialize UUID fields, like this: MyUUID = NilUUID;
UUIDD 
NilUUID = 
{
    0,                   // TimeLo 
    0,                   // TimeMid 
    0,                   // TimeHiAndVersion
    0,                   // ClockSeqHiAndRes
    0,                   // ClockSeqLo
    { 0, 0, 0, 0, 0, 0 } // Node[6]
};
  
u32     IsUUIDSetUp = 0;
        // This flag indicates whether the UUID generator has
        // be set up for use.  It holds '1' when the 
        // generator is enabled, '0' when not available.

u64     TheCurrentUUIDTime; 
        // The UUID time most recently measured.
        
u64     TheLastUUIDTime;
        // The value of 'TheCurrentUUIDTime' the time before
        // the most recent measurement.

// The following globals can be read to determine the current
// UUID configuration.
//

u16     TheUUID_ClockSequence;    
        // A number used to compensate for backwards clocks
        // and loss of time state.

u16     TheUUID_ClockSequenceMask;    
        // A mask used to separate the 'ClockSequence' subfield
        // from the 'Res' sub field.  This mask is 0x1FFF for
        // GUID variants, 0x3FFF for DCE and NCS variants.

u32     TheUUID_Version;  
        // The version number, one of two possible: 
        // 1 == 'UUID_Version_1_DCE'
        // 2 == 'UUID_Version_2_Security'
                           
u32     TheUUID_Variant;  
        // The variant number, one of seven possible:
        //
        // 0 == 'UUID_Variant_NCS'
        // 4 == 'UUID_Variant_DCE'
        // 6 == 'UUID_Variant_GUID'
        // 7 == 'UUID_Variant_7'
                          
u8      TheUUID_NodeID[7] = { 0, 0, 0, 0, 0, 0, 0 };
        // The Node ID that should be used, or filled with 
        // zeros if none is specified.
        //
        // This can be a 7-byte HostID, a 6-byte IEEE 802 
        // address, or a 6-byte random number.

u32     TheUUID_IsRandomNodeID;
        // If the NodeID isn't specified then this flag 
        // controls whether a random number should be 
        // generated or whether the IEEE 802 address should 
        // be obtained from the network card to serve as NodeID. 
        // 
        // '1' means a random number should be used, '0' 
        // means get IEEE 802 node address.
        //
        // NOTE: Only 'UUID_Variant_GUID' supports the use of 
        // a random NodeID.
        
u64     UUIDTimeAtSetUpOrigin;
        // The UUID time at the point in time when the PowerPC
        // timebase functions were initialized,  expressed as 
        // the number of 100-nanosecond units since October 15, 
        // 1582 GMT.

u64     UUIDTimeOriginAdjustmentForNT;
        // The amount that needs to be added to a current time
        // value obtained via 'GetTimeNT()' to convert it to
        // the number 100-nanosecond units since October 15, 
        // 1582 GMT.

u64     TheMakeUUIDCounter = 0;
        // A count of how many times 'MakeUUID()' has been
        // called.
        
/*------------------------------------------------------------
| CompareUUIDs
|-------------------------------------------------------------
|
| PURPOSE: To compare the values of two UUIDs according to the
|          standard.
|
| DESCRIPTION:  Performs a field-by-field comparison of the 
| UUID's from the first field to the last: this is the most-
| specific to the most-general order.
|
| Each field is regarded as an unsigned integer.  Then, to
| compare a pair of UUIDs, arithmetically compare the 
| corresonding fields from each UUID in field order.
|  
| Two UUIDs are equal if all of the corresponding fields are
| equal.  The first of two UUIDs follows the second if the
| most significant field in which the UUID differ is greater
| for the first UUID.  The first of a pair of UUIDs precedes
| the second if the most most significant field in which the
| UUIDs differ is greater for the second UUID.
|
|
|       Comparison operation.
|
|              Returns: 0 if address A = address B.
|                       positive number if A > B.
|                       negative number if A < B.
|
| EXAMPLE:  Result = CompareUUID( A, B );
|
| NOTE: 
|
| ASSUMES: Both UUIDs are valid.
|       
|          The ordering must be the same on any machine that
|          this code runs on.
|
| HISTORY: 11.29.98 From 'uuid_compare()' and 
|                   'CompareBytes()'.
|          12.26.98 Finished.
------------------------------------------------------------*/
s32
CompareUUIDs( s8* A, s8* B )
{
    UUIDD   a;
    UUIDD   b;

    // Get the two UUID's to local variables.
    a = *( (UUIDD*) A );
    b = *( (UUIDD*) B );
    
    // If the 'TimeLo' fields are the same.
    if( a.TimeLo == b.TimeLo )
    {
        // If the 'TimeMid' fields are the same.
        if( a.TimeMid == b.TimeMid )
        {
            // If the 'TimeHiAndVersion' fields are the same.
            if( a.TimeHiAndVersion == b.TimeHiAndVersion )
            {
                // If the 'ClockSeqHiAndRes' fields are the same.
                if( a.ClockSeqHiAndRes == b.ClockSeqHiAndRes )
                {
                    // If the 'ClockSeqLo' fields are the same.
                    if( a.ClockSeqLo == b.ClockSeqLo )
                    {
                        // Compare the network node addresses.
                        return( CompareBytes( &a.Node[0], 6,
                                              &b.Node[0], 6 ) );
                    }
                    else // 'ClockSeqLo' fields are different.
                    {
                        // Return the result.
                        return( (s32) ( a.ClockSeqLo - 
                                               b.ClockSeqLo ) );
                    }
                }
                else // The 'ClockSeqHiAndRes' values differ.
                {
                    // Return the result.
                    return( (s32) ( a.ClockSeqHiAndRes - 
                                           b.ClockSeqHiAndRes ) );
                }
            }
            else // The 'TimeHiAndVersion' values differ.
            {
                // Return the result.
                return( (s32) ( a.TimeHiAndVersion - 
                                       b.TimeHiAndVersion ) );
            }
        }
        else // The 'TimeMid' values differ.
        {
            // Return the result.
            return( (s32) ( a.TimeMid - b.TimeMid ) );
        }
    }
    else // The 'TimeLo' values differ.
    {
        // Return the result.
        return( (s32) ( a.TimeLo - b.TimeLo ) );
    }
}
 
/*------------------------------------------------------------
| ConvertUUIDToString
|-------------------------------------------------------------
|
| PURPOSE: To decode a UUID from a printable string.
|
| DESCRIPTION: 
|
| EXAMPLE:   
|
| NOTE: 
|
| ASSUMES: 'UUIDString' has space for a 37 byte string,
|          including the zero terminator byte.
|
|          The given UUID string is valid.
|
| HISTORY: 11.29.98 From 'uuid.c'.
------------------------------------------------------------*/
void 
ConvertStringToUUID 
(
    s8*     UUIDString, // IN: The string representation of 
                        //     a UUID.
                        //
    UUIDD*  U           // OUT: The binary UUID.
)
{
    UUIDD   UUID_New;   // used for sscanf for new uuid's.
    OldUUID UUID_Old;   // used for sscanf for old uuid's.
    UUIDD*  UUID_Ptr;   // pointer to correct uuid( old/new).
 
    // If a NULL pointer or empty string, give the nil UUID.
    if( UUIDString == NULL || *UUIDString == 0 )
    {
        memcpy( U, &NilUUID, sizeof( UUIDD ) );
        
        return;
    }

    // If this is a new format UUID.
    if( UUIDString[8] == '-' )
    {
        long    TimeLo;
        int     TimeMid;
        int     TimeHiAndVersion;
        int     ClockSeqHiAndRes;
        int     ClockSeqLo;
        int     Node[6];
 
        // Format is tttttttt-tttt-cccc-cccc-nnnnnnnnnnnn.
        sscanf(
            UUIDString, 
            "%8lx-%4x-%4x-%2x%2x-%2x%2x%2x%2x%2x%2x",
            &TimeLo,
            &TimeMid,
            &TimeHiAndVersion,
            &ClockSeqHiAndRes,
            &ClockSeqLo,
            &Node[0], &Node[1], &Node[2], &Node[3], &Node[4], &Node[5]);
 
        // Note that we're going through this agony because scanf is 
        // defined to know only to scan into "int"s or "long"s.
        UUID_New.TimeLo            = (u32) TimeLo;
        UUID_New.TimeMid           = (u16) TimeMid;
        UUID_New.TimeHiAndVersion  = (u16) TimeHiAndVersion;
        UUID_New.ClockSeqHiAndRes  = (u8)  ClockSeqHiAndRes;
        UUID_New.ClockSeqLo        = (u8)  ClockSeqLo;
        UUID_New.Node[0]           = (u8)  Node[0];
        UUID_New.Node[1]           = (u8)  Node[1];
        UUID_New.Node[2]           = (u8)  Node[2];
        UUID_New.Node[3]           = (u8)  Node[3];
        UUID_New.Node[4]           = (u8)  Node[4];
        UUID_New.Node[5]           = (u8)  Node[5];

        // point to the correct uuid
        UUID_Ptr = &UUID_New;
    }
    else // Old-format UUID.
    {
        long    TimeHigh;
        int     TimeLo;
        int     family;
        int     host[7];

        // Format is tttttttttttt.ff.h1.h2.h3.h4.h5.h6.h7
        sscanf(
            UUIDString, "%8lx%4x.%2x.%2x.%2x.%2x.%2x.%2x.%2x.%2x",
            &TimeHigh, &TimeLo, &family,
            &host[0], &host[1], &host[2], &host[3],
            &host[4], &host[5], &host[6]);
  
        // Note that we're going through this agony because scanf 
        // is defined to know only to scan into "int"s or "long"s.
        UUID_Old.TimeHigh   = (u32) TimeHigh;
        UUID_Old.TimeLo     = (u16) TimeLo;
        UUID_Old.family     = (u8)  family;
        UUID_Old.host[0]    = (u8)  host[0];
        UUID_Old.host[1]    = (u8)  host[1];
        UUID_Old.host[2]    = (u8)  host[2];
        UUID_Old.host[3]    = (u8)  host[3];
        UUID_Old.host[4]    = (u8)  host[4];
        UUID_Old.host[5]    = (u8)  host[5];
        UUID_Old.host[6]    = (u8)  host[6];

        // Fix up non-string field, and point to the correct uuid
        UUID_Old.reserved = 0;
        UUID_Ptr = ( UUIDD*) ( &UUID_Old );
    }
 
    // copy the uuid to user.
    memcpy( U, UUID_Ptr, sizeof( UUIDD ) );
}
 
/*------------------------------------------------------------
| ConvertUUIDToString
|-------------------------------------------------------------
|
| PURPOSE: To encode a UUID into a printable string.
|
| DESCRIPTION: 
|
| EXAMPLE:   
|
| NOTE: 
|
| ASSUMES: 'UUIDString' has space for a 37 byte string,
|          including the zero terminator byte.
|
|          The given UUID is valid.
|
| HISTORY: 11.29.98 From 'uuid.c'.
------------------------------------------------------------*/
void 
ConvertUUIDToString 
(
    UUIDD*  U,          // IN: The binary UUID to be converted 
                        //     to a string UUID.
                        //
    s8*     UUIDString  // OUT: The string representation of 
                        //      the given UUID.
)
{
    sprintf(
        UUIDString,
        "%08x-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        U->TimeLo, 
        U->TimeMid, 
        U->TimeHiAndVersion,
        U->ClockSeqHiAndRes, 
        U->ClockSeqLo,
        (u8) U->Node[0],(u8) U->Node[1],
        (u8) U->Node[2],(u8) U->Node[3],
        (u8) U->Node[4],(u8) U->Node[5]);
}

/*------------------------------------------------------------
| GetUUIDTime
|-------------------------------------------------------------
|
| PURPOSE: To get the current time in the format used by
|          the UUID generator.
|
| DESCRIPTION: Returns a 60-bit time value in a 64-bit data 
| type.
|
| The time value is Coordinated Universal Time (UTC) a.k.a. 
| Greenwich Mean Time (GMT), expressed as the number of 
| 100-nanosecond intervals since 00:00:00.00, October 15 1582,
| the date of Gregorian reform of the calendar.
|
| EXAMPLE:   
|
| NOTE:  
|
| ASSUMES: 'SetUpUUIDTime()' has been called at least once.
|
| HISTORY: 12.20.98 TL
|          12.26.98 Revised.
|          12.30.98 Made Mac-specific.
------------------------------------------------------------*/
void
GetUUIDTime( u64* t )
{

#if macintosh
    
    u64 a, da, ds;

    // If TheMakeUUIDCounter is evenly divisible by 16.
    if( (TheMakeUUIDCounter & 15) == 0 )
    {
        // Measure the timebase clock speed.
        MeasureTimeBaseTicksPerSecond();
    }
 
    // Get the current value of the timebase.
    GetTimeCPU( &a );
    
    // Calculate the elapsed timebase time since the 
    // timebase function set up origin.
    da = a - SetUpOriginOfTimebase;
    
    // Convert the elapsed time to 100-nanosecond units.
    ds = ( da * 10000000 ) / TimeBaseTicksPerSecond;
    
    // Add the time at the UUID set up origin and return 
    // the result.
    *t = UUIDTimeAtSetUpOrigin + ds;
    
#else // Not MacOS.

#if defined( __INTEL__ ) || defined( _M_IX86 )

    u64 a;
    
    // Get the current time in 100-nanosecond units.
    GetTimeNT( &a );
    
    // Add the origin adjustment for NT and return 
    // the result.
    *t = a + UUIDTimeOriginAdjustmentForNT;

#else // Not Mac or NT.

    // Default to a constant value.
    *t = 0;
    
    // Add support for other operating systems as needed.
    Debugger();
    
#endif // __INTEL__
    
#endif // macintosh
}

/*------------------------------------------------------------
| HashUUID
|-------------------------------------------------------------
|
| PURPOSE: To compute a 16-bit hash value for a UUID.
|
| DESCRIPTION: 
| 
|
| EXAMPLE:   h = HashUUID( &MyUUID );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 12.26.98 From 'uuid.c', 'HashUUID()'.
------------------------------------------------------------*/
u16 
HashUUID( UUIDD* U )
{
    u16 c0, c1;
    s16 x, y;
    u8* c;

    // Refer to the UUID as a string of bytes.
    c = (u8*) U;
    
    // Initialize counters
    c0 = 0;
    c1 = 0;

    // For speed,  unroll the following loop:
    //
    //   for( i = 0; i < 16; i++ )
    //   {
    //       c0 = c0 + *c++;
    //       c1 = c1 + c0;
    //   }
    c0 += *c++; c1 += c0;
    c0 += *c++; c1 += c0;
    c0 += *c++; c1 += c0;
    c0 += *c++; c1 += c0;

    c0 += *c++; c1 += c0;
    c0 += *c++; c1 += c0;
    c0 += *c++; c1 += c0;
    c0 += *c++; c1 += c0;
    
    c0 += *c++; c1 += c0;
    c0 += *c++; c1 += c0;
    c0 += *c++; c1 += c0;
    c0 += *c++; c1 += c0;

    c0 += *c++; c1 += c0;
    c0 += *c++; c1 += c0;
    c0 += *c++; c1 += c0;
    c0 += *c++; c1 += c0;

    // Calculate the value for first octet of the hash.
    x = (s16) ( -c1 % 255 );
    
    if( x < 0 )
    {
        x = (s16) ( x + 255 );
    }

    // Calculate the value for second octet of the hash.
    y = (s16) ( ( c1 - c0 ) % 255 );
    
    if( y < 0 )
    {
        y = (s16) ( y + 255 );
    }

    // Return the pieces put together.
    return( (u16) ( (y << 8) + x ) );
}
 
/*------------------------------------------------------------
| IsNilUUID
|-------------------------------------------------------------
|
| PURPOSE: To test if a UUID is a 'nil' UUID.
|
| DESCRIPTION: The nil UUID is a special form that is 
| specified to have all 128 bits set to zero.
|
| Returns '1' if the UUID is composed of all zero bits, 
| else returns '0'.
|
| EXAMPLE:   
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 11.29.98 From 'uuid_is_nil()'.
------------------------------------------------------------*/
u32   
IsNilUUID( UUIDD* U )
{
    u64*    a;
    
    // Refer to the UUID as an array of two u64's.
    a = (u64*) U;
    
    // If the first 8 bytes are non-zero.
    if( *a ) 
    {
        // Signal that this isn't a nil UUID.
        return( 0 );
    }
    
    // Refer to the second 8 bytes.
    a++;
    
    // If the second 8 bytes are non-zero.
    if( *a ) 
    {
        // Signal that this isn't a nil UUID.
        return( 0 );
    }
    
    // Signal that the UUID is of the nil type.
    return( 1 );
}

/*------------------------------------------------------------
| MakeUUID
|-------------------------------------------------------------
|
| PURPOSE: To make a new UUID of the currently configured 
|          type.
|
| DESCRIPTION: 
| 
|
| EXAMPLE:   
|           UUIDD   MyUUID;
|
|           MakeUUID( &MyUUID );
|
| NOTE: Support for old-style, Variant# 0 UUIDs is missing:
|       add as needed. 
|
| ASSUMES: 'SetUpUUID()' has been called before calling this
|          procedure.
|
| HISTORY: 11.29.98 From 'uuid.c'.
|          01.13.99 Revised for NT.
------------------------------------------------------------*/
void 
MakeUUID( UUIDD* U )
{
    u32     IsTimeFactorsValid;
    u32     HiTime;
    
    // Start without valid time factors.
    IsTimeFactorsValid = 0;
     
    // Until time factors are valid.
    while( IsTimeFactorsValid == 0 )
    {
        // Get the current time in 100 nanosecond ticks since 
        // 00:00:00.00 October 15, 1582, the date of Gregorian 
        // reform of the calendar.
        GetUUIDTime( &TheCurrentUUIDTime );
        
        // If the current time is less than the last measured 
        // time.
        if( TheCurrentUUIDTime < TheLastUUIDTime )
        {
            // Increment the clock sequence modulo 16,384 or 
            // 8,192 depending on the type of UUID.
            TheUUID_ClockSequence = (u16)
                ( ( TheUUID_ClockSequence + 1 ) & 
                  TheUUID_ClockSequenceMask );
                
            // Signal that valid time factors have been 
            // produced.
            IsTimeFactorsValid = 1;
        }
        else // Current time is not less than the last time.
        {
            // If the current time is greater than the last 
            // time.
            if( TheCurrentUUIDTime > TheLastUUIDTime )
            {
                // Signal that valid time factors have been 
                // produced.
                IsTimeFactorsValid = 1;
            }
            else // The current time is equal to the last time.
            {
                // Just wait for the clock to tick.
                ; 
            }
        }
    }

    // Regard the current time as the last time.
    TheLastUUIDTime = TheCurrentUUIDTime;
 
    // Set the low 32-bits of the time field.
    U->TimeLo = (u32) TheCurrentUUIDTime;
    
    // Get the high 32-bits of the time field.
    HiTime = (u32) ( TheCurrentUUIDTime >> 32 );
    
    // Set the middle 16-bits of the time field.
    U->TimeMid = (u16) ( HiTime & 0xffff );

    // Mask off the low 12 bits of the highest 16 bits 
    // of the time and put it into the high time field.
    U->TimeHiAndVersion = (u16) ( ( HiTime >> 16 ) & 0x0fff );
    
    // Merge the version subfield into the field shared
    // with the high time value.
    U->TimeHiAndVersion |= (u16) ( TheUUID_Version << 12 );

    // Set the low field of the clock sequence, a byte.
    U->ClockSeqLo = (u8) TheUUID_ClockSequence;
    
    // Set the high field of the clock sequence, clearing the
    // high 3 bits of the byte.
    U->ClockSeqHiAndRes = (u8)
         ( (u8) ( TheUUID_ClockSequence >> 8 ) & 0x1f );

    // Merge the variant subfield into the field shared
    // with the high byte of the clock sequence.
    U->ClockSeqHiAndRes |= (u8) ( TheUUID_Variant << 5 );

    // Copy the NodeID to the node field.
    CopyBytes( TheUUID_NodeID, U->Node, 6 );
        
    // Increment the counter that tells how often this routine
    // has been called.
    TheMakeUUIDCounter++;
}
 
/*------------------------------------------------------------
| MakeNilUUID
|-------------------------------------------------------------
|
| PURPOSE: To create a 'nil' UUID.
|
| DESCRIPTION: The nil UUID is a special form that is 
| specified to have all 128 bits set to zero.
|
| EXAMPLE:   
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 11.29.98 From 'uuid.c'.
------------------------------------------------------------*/
void 
MakeNilUUID( UUIDD* U )
{
    memset( U, 0, sizeof( UUIDD ) );
}
 
/*------------------------------------------------------------
| SetUpUUID
|-------------------------------------------------------------
|
| PURPOSE: To prepare the UUID generator for use.
|
| DESCRIPTION: This must be called prior to generating any
| UUID's or when changing the type of UUID to be generated.
| 
| To use this procedure, supply desired UUID configuration
| parameters and then, after the procedure returns, check 
| the global configuration variables to determine the actual 
| configuration that resulted -- some configurations
| are not available on on some machines.
|
| These are the global configuration variables, defined
| above:
|
| 'TheUUID_Version'
| 'TheUUID_Variant'
| 'TheUUID_NodeID'
| 'TheUUID_IsRandomNodeID'
|
| Also on return 'IsUUIDSetUp' is set to '1' to indicate 
| that the UUID generator is ready to generate ID numbers.
|
| EXAMPLE: Set up UUID generation so that GUID types will
| be produced, using a network card node ID if available
| or defaulting to a randomly generated node ID:
|
|   SetUpUUID(
|       UUID_Version_1_DCE, 
|       UUID_Variant_GUID, 
|       0,                   // Query network card if available.
|       0 );                 // Don't use random node unless 
|                            // network card ID is unavailable.
|
| NOTE: Support for old-style, Variant #0 UUIDs is not 
|       implemented: add as needed.
|
| ASSUMES: If the NodeID is to be read from the network card,
|          OpenTransport has been initialized: see 
|          'GetAnyEthernetAddress()'.
|
| HISTORY: 11.29.98 From 'uuid.c'.
|          12.06.98 Revised to add configuration parameters.
|          12.30.98 Added Intel support.
------------------------------------------------------------*/
void 
SetUpUUID(
    u32     UUID_Version,    // The version number, one of two 
                             // possible: 
                             // 1 == 'UUID_Version_1_DCE'
                             // 2 == 'UUID_Version_2_Security'
                             //
    u32     UUID_Variant,    // The variant number, one of 
                             // four possible:
                             //
                             // 0 == 'UUID_Variant_NCS'
                             // 4 == 'UUID_Variant_DCE'
                             // 6 == 'UUID_Variant_GUID'
                             // 7 == 'UUID_Variant_7'
                             //
    u8*     UUID_NodeID,     // The address of the 6-byte
                             // Node ID that should be used,
                             // or zero if none is specified.
                             // 
                             // This can be a 7-byte HostID,
                             // a 6-byte IEEE 802 address, or
                             // a 6-byte random number.
                             //
    u32     UUID_IsRandomNodeID )
                             // If the NodeID isn't specified,
                             // then this flag controls whether 
                             // a random number should be 
                             // generated or whether the IEEE
                             // 802 address should be obtained
                             // from the network card to serve
                             // as NodeID. 
                             // 
                             // '1' means a random number
                             // should be used, '0' means 
                             // use IEEE 802 node address.
                             //
                             // NOTE: Only 'UUID_Variant_6_GUID'
                             // supports the use of a random
                             // NodeID.
{
    u64     r;
    u16     r16;
    u32     IsFound;

    // If an old-style UUID is requested.
    if( UUID_Variant == UUID_Variant_NCS )
    {
        // Default to the most universal version.
        UUID_Variant = UUID_Variant_GUID;
    }
    
    // Set up the time reference for UUID-format timestamp
    // generation.
    SetUpUUIDTime();
    
    // If the NodeID is given.
    if( UUID_NodeID )
    {
        // If the NodeID has 7 bytes.
        if( UUID_Variant == UUID_Variant_NCS )
        {
            // Copy the given NodeID to the current NodeID.
            CopyBytes( UUID_NodeID, TheUUID_NodeID, 7 );
        }
        else // The NodeID is 6 bytes long.
        {
            // Copy the given NodeID to the current NodeID.
            CopyBytes( UUID_NodeID, TheUUID_NodeID, 6 );
        }
    } 
    else // The NodeID must be generated or fetched from network
         // card.
    {
        // If this type of UUID should use the network card ID
        // if availalble.
        if( UUID_IsRandomNodeID == 0 )
        {
#if macintosh
            // Try to get the Ethernet address using OpenTransport.
//TBD           IsFound = GetAnyEthernetAddress( TheUUID_NodeID );
            IsFound = 0;
#else
            // Default to use random for INTEL machines.
            IsFound = 0;
#endif // macintosh

            // If the Ethernet address was not found.
            if( IsFound == 0 )
            {
                // Default to random node ID type.
                UUID_Variant        = UUID_Variant_GUID;
                UUID_IsRandomNodeID = 1;
            }
        }
        
        // If this is a UUID that can be and should be randomly 
        // generated.
        if( UUID_Variant == UUID_Variant_GUID &&
            UUID_IsRandomNodeID )
        {
            // Make a random NodeID using a true random source.
            
            // Get a truly random 64-bit number.
            TrueRandomNumber( &r );
        
            // Copy the first 6 bytes to the node ID field.
            CopyBytes( (u8*) &r, TheUUID_NodeID, 6 );
            
            // Set the bit that identifies this as a random
            // NodeID: the LSB of the first byte is the 
            // multicast bit.  No network card address sets
            // this bit so this is how random NodeID's are
            // distinguished.
            TheUUID_NodeID[0] |= 1;
        }
    }
    
    // Set the effective node ID type.
    TheUUID_IsRandomNodeID = UUID_IsRandomNodeID;
    
    // Set the current version.
    TheUUID_Version = UUID_Version;
    
    // Set the current variant.
    TheUUID_Variant = UUID_Variant;
    
    // Set the clock sequence mask based on the variant.
    switch( UUID_Variant )
    {
        case UUID_Variant_NCS:
        case UUID_Variant_DCE:
        {
            // The Res field is 2 bits wide.
            TheUUID_ClockSequenceMask = 0x3FFF; 
            break;
        }
        
        case UUID_Variant_GUID:
        case UUID_Variant_7:
        {
            // The Res field is 3 bits wide.
            TheUUID_ClockSequenceMask = 0x1FFF; 
            break;
        }
    }
        
    // Get a truly random 64-bit number.
    TrueRandomNumber( &r );
    
    // Take the low 16 bits of the random number.
    r16 = (u16) r;
    
    // Start the clock sequence at a truly random value.
    TheUUID_ClockSequence = (u16)
        ( TheUUID_ClockSequenceMask & r16 );

    // Set the reference time stamp used by the generator.
    GetUUIDTime( &TheLastUUIDTime );
    
    // Signal that the UUID generator is available for use.
    IsUUIDSetUp = 1;

}
 
/*------------------------------------------------------------
| SetUpUUIDTime
|-------------------------------------------------------------
|
| PURPOSE: To set up the time reference for UUID-format 
|          timestamp generation.
|
| DESCRIPTION: UUID time values are 60-bit numbers held in a 
| 64-bit integer fields.
|
| The time value is Coordinated Universal Time (UTC) a.k.a. 
| Greenwich Mean Time (GMT), expressed as the number of 
| 100-nanosecond intervals since 00:00:00.00, October 15 1582,
| the date of Gregorian reform of the calendar.
|
| EXAMPLE:   
|
| NOTE:  
|
| ASSUMES: In order for the time value to be accurate the 
|          location of the machine and the current local time 
|          must be set properly.
|
| HISTORY: 12.20.98 TL
|          12.30.98 Made Mac-specific.
|          01.14.98 Added NT support.
------------------------------------------------------------*/
void
SetUpUUIDTime()
{
#if macintosh

    MachineLocation Here;
    u32             TheGMTDelta, TheDLSDelta;
    u64             t;
    
    // If the timebase functions haven't been set up.
    if( IsTimePPCSetUp == 0 )
    {
        // Set up the timebase functions.
        SetUpTimePPC();
    }
    
    // Read the machine location from the parameter RAM.
    //
    // If the geographic location record has never been set, 
    // all fields contain 0.
    ReadLocation( &Here );
    
    // If the location has never been set.
    if( Here.latitude   == 0 && 
        Here.longitude  == 0 && 
        Here.u.gmtDelta == 0 )
    {
        // Default to GMT.
        
        // Set the Greenwich mean time delta to zero.
        TheGMTDelta = 0;
        
        // Set the daylight savings time delta to zero.
        TheDLSDelta = 0;
    }
    else // The location has been set.
    {
        // The Greenwich mean time value of the location
        // record is in seconds east of GMT. For example, 
        // San Francisco is at ­28,800 seconds 
        // (8 hours * 3,600 seconds per hour) east of GMT.
        //
        // The 'gmtDelta' field of the geographic location 
        // record is a 3-byte value contained in a 32-bit field
        // so it must be extracted and sign-extended.
        TheGMTDelta = Here.u.gmtDelta & 0x00FFFFFF;
    
        // Sign-extend the GMT correction.
        if( TheGMTDelta & 0x00800000 )
        {
            TheGMTDelta |= 0xFF000000;
        }
        
        // The daylight savings time value is a signed byte 
        // value that specifies the offset for the hour field --
        // whether to add 1 hour, subtract 1 hour, or make no 
        // change at all.
        TheDLSDelta = (s32) Here.u.dlsDelta;
    }
    
    //
    // Calculate the UUID time at the PPC timebase set up origin...
    //
    
    // ...Start with the number of seconds since 00:00 
    // January 1 1904 in local time.  
    t = SetUpOriginOfDateTime;
    
    // ...Apply the GMT adjustment.
    t += TheGMTDelta;
    
    // ...Add the DLS adjustment, converting hours to seconds.
    t += TheDLSDelta * 60 * 60;
    
    // ...'t' is now seconds since 00:00 January 1 1904 GMT.
    
    // ...Calculate the number of days between 00:00 October 15 1582 
    //    and 00:00 January 1 1904.
    UUIDTimeAtSetUpOrigin = JulianDay( 1, 1, 1904 ) -
                            JulianDay( 10, 15, 1582 );
    
    // ...Convert the days to seconds.
    UUIDTimeAtSetUpOrigin *= SecondsPerDay;
    
    // ...Add the seconds since 00:00 January 1 1904 GMT.
    UUIDTimeAtSetUpOrigin += (u64) t;
    
    // ...Convert the seconds to 100-nanosecond units by multiplying
    // by ten million.
    UUIDTimeAtSetUpOrigin *= (u64) 10000000;
    
#else // Not MacOS.

#if defined( __INTEL__ ) || defined( _M_IX86 )
        
    // Calculate the number of days between 00:00 October 15 1582 
    //    and 00:00 January 1 1601.
    UUIDTimeOriginAdjustmentForNT = 
        JulianDay( 1, 1, 1601 ) - JulianDay( 10, 15, 1582 );
    
    // ...Convert the days to seconds.
    UUIDTimeOriginAdjustmentForNT *= SecondsPerDay;
    
    // ...Convert the seconds to 100-nanosecond units by 
    // multiplying by ten million.
    UUIDTimeOriginAdjustmentForNT *= (u64) 10000000;
    
#else // Not Mac or NT.

        // Add support as needed.
        Debugger();
        
#endif // __INTEL__

#endif // macintosh
}

