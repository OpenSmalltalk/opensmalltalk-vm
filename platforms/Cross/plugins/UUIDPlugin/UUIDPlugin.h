#if TARGET_API_MAC_CARBON || (defined ( __APPLE__ ) && defined ( __MACH__ ))
#include <CFUUID.h>
#endif
#include <MacTypes.h>
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
    UInt32 TimeLo;
    UInt16 TimeMid;
    UInt16 TimeHiAndVersion;
    UInt8  ClockSeqHiAndRes;
    UInt8  ClockSeqLo;
    UInt8  Node[6];
};

typedef struct UUIDD    UUIDD;
int MakeUUID(UUIDD * location);
int sqUUIDInit();
