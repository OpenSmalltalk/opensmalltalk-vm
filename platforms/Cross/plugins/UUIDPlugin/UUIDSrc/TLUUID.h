/*------------------------------------------------------------
| TLUUID.h
|-------------------------------------------------------------
| 
| PURPOSE: To provide interface for Universally Unique 
|          IDentifier (UUID) procedures and structures.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 11.29.98 From 'uuidp.h' of DCE released as 
|                   'PD-DCE-RPC.tar.Z'.
|          12.04.98 Additional information from "C. Appendix:
|                   GUIDs and UUIDs" at 
|                   http://www.microsoft.com/asf/spec2/c.htm .
|
| (c) Copyright 1989 OPEN SOFTWARE FOUNDATION, INC.
| (c) Copyright 1989 HEWLETT-PACKARD COMPANY
| (c) Copyright 1989 DIGITAL EQUIPMENT CORPORATION
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

#ifndef _TLUUID_H_
#define _TLUUID_H_

#ifdef __cplusplus
extern "C"
{
#endif

// These codes specify the Version of UUID, being a 4-bit
// code held in the most-significant bits of the 
// 'TimeHiAndVersion' field.
#define UUID_Version_1_DCE          1   // 0 0 0 1
#define UUID_Version_2_DCESecurity  2   // 0 0 1 0

// These codes specify the variant of UUID, being the 2 or
// 3-bit code held in the 'Res' subfield of the 8-bit 
// 'ClockSeqHiAndRes' field.   
#define UUID_Variant_NCS    0        // 0 0 x
#define UUID_Variant_DCE    4        // 1 0 x
#define UUID_Variant_GUID   6        // 1 1 0
#define UUID_Variant_7      7        // 1 1 1
 
// There are two types of GUID: one uses the NodeID from the
// network card, the other uses a randomly generated number.
// The two types are distinguished by the high-order bit of
// the NodeID field: 0 means network card ID, 1 means random
// number.  The high-order bit of IEEE 802 addresses is
// reserved for the unicast/multicast bit and is never used
// in network cards.
#define GUID_Variant_0_NodeID 0
#define GUID_Variant_1_Random 1

typedef struct OldUUID  OldUUID;

/*------------------------------------------------------------
| UUIDD
|-------------------------------------------------------------
|
| PURPOSE: To represent Universal Unique Identifiers (UUIDs).
|
| DESCRIPTION:  From 'uuid.c':
|
| Structure of universal unique IDs (UUIDs).
|  
| There are three "variants" of UUIDs that this code supports.  
| The variant #0 is defined in the 1989 HP/Apollo 
| Network Computing Architecture (NCA) specification and 
| implemented in NCS 1.x and DECrpc v1.  Variant #1 is defined 
| in the joint HP/DEC specification for the OSF (in DEC's "UID 
| Architecture Functional Specification Version X1.0.4") and 
| implemented in NCS 2.0, DECrpc v2, and OSF 1.0 DCE RPC.
| Variant #2 is defined by Microsoft.
|  
| The different UUID variants can exist on the same wire 
| because they have distinct values in the 3 MSB bits of octet 
| 8 (see table below).  Do NOT confuse the version number with 
| these 3 bits.  Note the distinct use of the terms "version" 
| and "variant". Variant #0 had no version field in it.  
| 
| The UUID record structure MUST NOT contain padding between 
| fields. The total size is 128 bits.
|  
| To minimize confusion about bit assignment within octets, 
| the UUID record definition is defined only in terms of fields 
| that are integral numbers of octets.
|  
| Depending on the network data representation, the multi-
| octet unsigned integer fields are subject to byte swapping 
| when communicated between dissimilar endian machines.  Note 
| that all three UUID variants have the same record structure; 
| this allows this byte swapping to occur. The ways in which 
| the contents of the fields are generated can and do vary.
|  
| Variant #1 UUID Structure:
|  
| +-----------------------------------+
| |     low 32 bits of time           |  0-3  .TimeLo
| +-------------------------------+----
| |     mid 16 bits of time       |  4-5      .TimeMid
| +-------+-----------------------+
| | vers. |   hi 12 bits of time  |  6-7      .TimeHiAndVersion
| +-------+-------+---------------+
| |Res|  clkSeqHi |  8                        .ClockSeqHiAndRes
| +---------------+
| |   clkSeqLow   |  9                        .ClockSeqLo
| +---------------+------------------+
| |            node ID               |  8-16  .Node
| +----------------------------------+
|
| The adjusted time stamp is split into three fields, and the 
| clockSeq is split into two fields.
|  
| The timestamp is a 60-bit value.  For UUID version 1, this
| is represented by Coordinated Universal Time (UTC/GMT) as
| a count of 100-nanosecond intervals since 00:00:00.00,
| 15 October 1582 (the date of Gregorian reform to the 
| Christian calendar.
|
| The version number is multiplexed in the 4 most significant
| bits of the 'TimeHiAndVersion' field. There are two defined
| versions:
|               MSB <---
| Version      4-Bit Code      Description
| ------------------------------------------------------------
| |  1           0 0 0 1     DCE version, as specified herein.
| |  2           0 0 1 0     DCE Security version, with 
| |                          embedded POSIX UIDs.
| ------------------------------------------------------------
|
| C.2.1 Clock Sequence
|
| The clock sequence value must be changed whenever:
|
| 1. The UUID generator detects that the local value of UTC
|    has gone backward; this may be due to normal functioning
|    of the DCE Time Service.
|
| 2. The UUID generator has lost its state of the last value
|    of UTC used, indicating that time may have gone 
|    backward: this is typically the case on reboot.
|
| While a node is operational, the UUID service always saves
| the last UTC used to create a UUID.  Each time a new UUID
| is created, the current UTC is compared to the saved value
| and if either the current value is less or the saved value
| was lost, then the clock sequence is incremented modulo
| 16,384, thus avoiding production of duplicted UUIDs.
|
| The clock sequence must be initialized to a random number
| to minimize the correlation across system.  This provides
| maximum protection against node identifiers that may move
| or switch from system to system rapidly.
|  
| C.2.3 Clock Adjustment
| 
| UUIDs may be created at a rate greater than the system clock
| resolution.  Therefore, the system must also maintain an 
| adjustment value to be added to the lower-order bits of the
| time.  Logically, each time the system clock ticks, the 
| adjustment value is cleared.  Every time a UUID is generated,
| the current adjustment value is read and incremented, and 
| then added to the UTC time field of the UUID.
|
| C.2.4 Clock Overrun
|
| The 100-nanosecond granularity of time should prove sufficient
| even for bursts of UUID production in the next generation of
| high-performance multiprocessors.  If a system overruns the
| clock adjustment by requesting too many UUIDs within a single
| system clock tick, the UUID service may raise an exception,
| handled in a system or process-dependent manner either by:
|
| 1. Terminating the requester.
| 2. Reissuing the request until it succeeds.
| 3. Stalling the UUID generator until the system clock catches
|    up.
|
| ----------------------------------------------------------- 
|  
| The structure layout of all three UUID variants is fixed 
| for all time. I.e., the layout consists of a 32 bit int, 
| 2 16 bit ints, and 8 8 bit ints.  The current form version 
| field does NOT determine/affect the layout.  This enables us 
| to do certain operations safely on the variants of UUIDs 
| without regard to variant; this increases the utility of 
| this code even as the version number changes, i.e. this code 
| does NOT need to check the version field.
|  
| The "Res" field in the octet #8 is the so-called "reserved" 
| bit-field and determines whether or not the uuid is a old, 
| current or other UUID as follows:
|  
|      MS-bit  2MS-bit  3MS-bit      Variant
|      ---------------------------------------------
|         0       x        x       0 (NCS 1.5)
|         1       0        x       1 (DCE 1.0 RPC)
|         1       1        0       2 (Microsoft)
|         1       1        1       unspecified
|                                  Reserved for future.
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 11.29.98 From 'nbase.idl'.
------------------------------------------------------------*/
struct UUIDD
{
    u32 TimeLo;
    u16 TimeMid;
    u16 TimeHiAndVersion;
    u8  ClockSeqHiAndRes;
    u8  ClockSeqLo;
    u8  Node[6];
};

typedef struct UUIDD    UUIDD;

/*------------------------------------------------------------
| OldUUID
|-------------------------------------------------------------
|
| PURPOSE: To represent Variant 0, Universal Unique 
|          Identifiers (UUIDs).
|
| DESCRIPTION:  The Variant 0 is defined in the 1989 HP/
| Apollo Network Computing Architecture (NCA) specification 
| and implemented in NCS 1.x and DECrpc v1.
|  
| Variant #0 UUID Structure:
|  
| The first 6 octets are the number of 4 usec units of time 
| that have passed since 1/1/80 0000 GMT.  The next 2 octets 
| are reserved for future use.  The next octet is an address 
| family.  The next 7 octets are a host ID in the form 
| allowed by the specified address family.
|  
| Note that while the family field (octet 8) was originally 
| conceived of as being able to hold values in the range 
| [0..255], only [0..13] were ever used.  Thus, the 2 MSB of 
| this field are always 0 and are used to distinguish old 
| and current UUID forms.
|  
| +--------------------------------------+
| |           high 32 bits of time       | 0-3  .TimeHigh
| +-------------------------------+------- 
| |       low 16 bits of time     |  4-5        .TimeLo
| +-------+-----------------------+
| |         reserved              |  6-7        .reserved
| +---------------+---------------+
| |    family     |   8                         .family
| +---------------+------------------+
| |            node ID               |  9-16    .Node
| +----------------------------------+
|  
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 11.29.98 From 'nbase.idl'.
------------------------------------------------------------*/
struct OldUUID
{
    u32 TimeHigh;
    u16 TimeLo;
    u16 reserved;
    u8  family;
    u8  host[7];
};
 
// Max size of a uuid string: tttttttt-tttt-cccc-cccc-nnnnnnnnnnnn
// Note: this includes the implied '\0'.
#define SizeOfUUIDStringIncludingZero          37

extern UUIDD    NilUUID;
                // This is a globally available nil UUID constant 
                // that can be used to initialize UUID fields,  
                // like this: MyUUID = NilUUID;
  
  
extern u32      IsUUIDSetUp;
                // This flag indicates whether the UUID generator 
                // has be set up for use.  It holds '1' when 
                // the generator is enabled, '0' when not 
                // available.

extern u64      TheCurrentUUIDTime; 
                // The UUID time most recently measured.
        
extern u64      TheLastUUIDTime;
                // The value of 'TheCurrentUUIDTime' the time 
                // before the most recent measurement.

// The following globals can be read to determine the current
// UUID configuration.
//

extern u16      TheUUID_ClockSequence;    
                // A number used to compensate for backwards clocks
                // and loss of time state.

extern u16      TheUUID_ClockSequenceMask;    
                // A mask used to separate the 'ClockSequence' subfield
                // from the 'Res' sub field.  This mask is 0x1FFF for
                // GUID variants, 0x3FFF for DCE and NCS variants.

extern u32     TheUUID_Version;  
                // The version number, one of two possible: 
                // 1 == 'UUID_Version_1_DCE'
                // 2 == 'UUID_Version_2_Security'
                           
extern u32      TheUUID_Variant;  
                // The variant number, one of seven possible:
                //
                // 0 == 'UUID_Variant_NCS'
                // 4 == 'UUID_Variant_DCE'
                // 6 == 'UUID_Variant_GUID'
                // 7 == 'UUID_Variant_7'
                          
extern u8       TheUUID_NodeID[7];
                // The Node ID that should be used, or filled with 
                // zeros if none is specified.
                //
                // This can be a 7-byte HostID, a 6-byte IEEE 802 
                // address, or a 6-byte random number.

extern u32      TheUUID_IsRandomNodeID;
                // If the NodeID isn't specified then this flag 
                // controls whether a random number should be 
                // generated or whether the IEEE 802 address should 
                // be obtained from the network card to serve as 
                // NodeID. 
                // 
                // '1' means a random number should be used, 
                // '0' means get IEEE 802 node address.
                //
                // NOTE: Only 'UUID_Variant_GUID' supports the use of 
                // a random NodeID.
        
extern u64      UUIDTimeAtSetUpOrigin;
                // The UUID time at the point in time when the 
                // PowerPC timebase functions were initialized,  
                // expressed as the number of 100-nanosecond units 
                // since October 15, 1582 GMT.

extern u64      TheMakeUUIDCounter;
                // A count of how many times 'MakeUUID()' has been
                // called.

s32     CompareUUIDs( s8*, s8* );
void    ConvertStringToUUID( s8*, UUIDD* );
void    ConvertUUIDToString( UUIDD*, s8* );
void    GetUUIDTime( u64* );
u16     HashUUID( UUIDD* );
u32     IsNilUUID( UUIDD* );
void    MakeUUID( UUIDD* );
void    MakeNilUUID( UUIDD* );
void    SetUpUUID( u32, u32, u8*, u32   );
void    SetUpUUIDTime();

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _UUIDP_H
