/*------------------------------------------------------------
| TLPacking.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to bit packing functions.
|
| DESCRIPTION:  
|
| NOTE: See header of 'TLPacking.c' for a specification of
| the standard followed below.  See also 'TLTwo.c' for working 
| with powers of 2.
|
| ASSUMES: Bytes are 8 bits.
|
| HISTORY: 02.10.97
|          09.03.98 Revised and extended to 64 bits.
------------------------------------------------------------*/
    
#ifndef TLPACKING_H
#define TLPACKING_H

#ifdef __cplusplus
extern "C"
{
#endif

// The two alternatives, same or different -- this coding must
// be the same as the result of the XOR operation.
#define Same 0
#define Diff 1

// Packing Order code masks:
#define BitEncoding 1
#define BitInByte   2
#define ByteInPair  4
#define PairInQuad  8
#define QuadInOct  16

// Names used to identify the 32 different possible packing orders:
//
//              QuadInOct   PairInQuad    ByteInPair    BitInByte   BitEncoding
#define SSSSS ((Same << 4) | (Same << 3) | (Same << 2) | (Same << 1) | Same)
#define SSSSD ((Same << 4) | (Same << 3) | (Same << 2) | (Same << 1) | Diff)
#define SSSDS ((Same << 4) | (Same << 3) | (Same << 2) | (Diff << 1) | Same)
#define SSSDD ((Same << 4) | (Same << 3) | (Same << 2) | (Diff << 1) | Diff)
#define SSDSS ((Same << 4) | (Same << 3) | (Diff << 2) | (Same << 1) | Same)
#define SSDSD ((Same << 4) | (Same << 3) | (Diff << 2) | (Same << 1) | Diff)
#define SSDDS ((Same << 4) | (Same << 3) | (Diff << 2) | (Diff << 1) | Same)
#define SSDDD ((Same << 4) | (Same << 3) | (Diff << 2) | (Diff << 1) | Diff)
#define SDSSS ((Same << 4) | (Diff << 3) | (Same << 2) | (Same << 1) | Same)
#define SDSSD ((Same << 4) | (Diff << 3) | (Same << 2) | (Same << 1) | Diff)
#define SDSDS ((Same << 4) | (Diff << 3) | (Same << 2) | (Diff << 1) | Same)
#define SDSDD ((Same << 4) | (Diff << 3) | (Same << 2) | (Diff << 1) | Diff)
#define SDDSS ((Same << 4) | (Diff << 3) | (Diff << 2) | (Same << 1) | Same)
#define SDDSD ((Same << 4) | (Diff << 3) | (Diff << 2) | (Same << 1) | Diff)
#define SDDDS ((Same << 4) | (Diff << 3) | (Diff << 2) | (Diff << 1) | Same)
#define SDDDD ((Same << 4) | (Diff << 3) | (Diff << 2) | (Diff << 1) | Diff)
#define DSSSS ((Diff << 4) | (Same << 3) | (Same << 2) | (Same << 1) | Same)
#define DSSSD ((Diff << 4) | (Same << 3) | (Same << 2) | (Same << 1) | Diff)
#define DSSDS ((Diff << 4) | (Same << 3) | (Same << 2) | (Diff << 1) | Same)
#define DSSDD ((Diff << 4) | (Same << 3) | (Same << 2) | (Diff << 1) | Diff)
#define DSDSS ((Diff << 4) | (Same << 3) | (Diff << 2) | (Same << 1) | Same)
#define DSDSD ((Diff << 4) | (Same << 3) | (Diff << 2) | (Same << 1) | Diff)
#define DSDDS ((Diff << 4) | (Same << 3) | (Diff << 2) | (Diff << 1) | Same)
#define DSDDD ((Diff << 4) | (Same << 3) | (Diff << 2) | (Diff << 1) | Diff)
#define DDSSS ((Diff << 4) | (Diff << 3) | (Same << 2) | (Same << 1) | Same)
#define DDSSD ((Diff << 4) | (Diff << 3) | (Same << 2) | (Same << 1) | Diff)
#define DDSDS ((Diff << 4) | (Diff << 3) | (Same << 2) | (Diff << 1) | Same)
#define DDSDD ((Diff << 4) | (Diff << 3) | (Same << 2) | (Diff << 1) | Diff)
#define DDDSS ((Diff << 4) | (Diff << 3) | (Diff << 2) | (Same << 1) | Same)
#define DDDSD ((Diff << 4) | (Diff << 3) | (Diff << 2) | (Same << 1) | Diff)
#define DDDDS ((Diff << 4) | (Diff << 3) | (Diff << 2) | (Diff << 1) | Same)
#define DDDDD ((Diff << 4) | (Diff << 3) | (Diff << 2) | (Diff << 1) | Diff)

// The packing order code for the packing standard.
#define TheStandardPackingOrder SSSSS

extern u64 ThePackingReference; // = 0x0807060504030201;
        // A known reference pattern used for run-time 
        // identification of the bit packing order of 
        // binary numbers.  The number must consist of 
        // eight bytes that are unique under bit reversal.

extern u32 ThePackingOrder;
        // The current binary packing order used by the CPU as
        // determined at run-time.
            
u32     HostToNetwork32Bit( u32 );
u32     IdentifyRelativePackingOrder( u64, u64 );
void    IdentifyThePackingOrder();
u64     Repack( u32, u64 );
void    RepackBytes( u32, u8*,  u8*,  u32 );
void    RepackOcts(  u32, u64*, u64*, u32 );
void    RepackPairs( u32, u16*, u16*, u32 );
void    RepackQuads( u32, u32*, u32*, u32 );
void    TestPacking();

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLPACKING_H
