#ifndef _CPU_H_
#define _CPU_H_

#include "types.h"

/* Cute macros for defining VA constants. Note that this doesn't conflict with
 * the VA type as the macro gets expanded only if followed by "(".
 */

#define TVA(a, b) C32(a, b) //Shi yang 2006-08-08

/* System Control Coprocessor (CP0) registers */
#define Index			0
#define Random			1
#define EntryLo0		2
#define EntryLo1		3
#define Context			4
#define PageMask		5
#define Wired			6
// reserved	=  7,
#define BadVAddr		8
#define Count			9
#define EntryHi			10
#define Compare			11
#define SR			12
#define Cause			13
#define EPC			14
#define PRId			15
#define Config			16
#define LLAddr			17
#define WatchLo			18
#define WatchHi			19
#define XContext		20
// reserved	= 21,
// reserved	= 22,
// reserved	= 23,
// reserved	= 24,
// reserved	= 25,
#define ECC			26
#define CacheErr		27
#define TagLo			28
#define TagHi			29
#define ErrorEPC		30
// reserved	= 31


/* CP0 register layout. For single-bit fields, only one constant is
 * defined. For multi-bit fields, two constants are defined: one for the
 * first (least-significant) bit of the field, and one for the
 * most-significant bit.
 */
/* Index Register (0) */
#define Index_First 			8
#define Index_Last 			13
#define CPO_Index_P 			31

/* Random Register (1) */
#define Random_First       		8
#define Random_Last 		 	13

/* EntryLo0 (2), and EntryLo1 (3) Registers */
#define EntryLo_G 			8
#define EntryLo_V 			9
#define EntryLo_D 			10
#define EntryLo_N			11
#define EntryLo_PFN_First 		12 
#define EntryLo_PFN_Last 		31

/* Context Register (4) */
#define Context_BadVPN_First 		2 
#define Context_BadVPN_Last 		20
#define Context_PTEBase_First 		21
#define Context_PTEBase_Last 		31

/* PageMask Register (5) */
#define PageMask_First 			13 
#define CPO_PageMask_Last 		24

/* Wired Register (6) */
#define Wired_First 			0
#define Wired_Last 			5

// Bad Virtual Address Register (BadVAddr) (8)
// Count Register (9)

/* EntryHi Register (CP0 Register 10) */
#define EntryHi_ASID_First 		8 
#define EntryHi_ASID_Last 		11
#define EntryHi_VPN2_First 		12
#define EntryHi_VPN2_Last 		31 

// Compare Register (11)

/* SR Register (12) */
#define SR_IEC  			0
#define SR_KUC 				1
#define SR_IEP 				2
#define SR_KUP	 			3 
#define SR_IEO	 			4
#define SR_KUO 				5
#define SR_IM0 				8
#define SR_IM1 				9
#define SR_IM2 				10
#define SR_IM3 				11
#define SR_IM4 				12
#define SR_IM5 				13
#define SR_IM6 				14
#define SR_IM7 				15
#define SR_IM_First 			8
#define SR_IM_Last 			15
#define SR_ISC 				16
#define SR_SWC				17
#define SR_PZ 				18
#define SR_CM				19
#define SR_PE 				20
#define SR_TS 				21
#define SR_BEV 				22
#define SR_DS_First 			16 
#define SR_DS_Last 			24
#define SR_CU0 				28
#define SR_CU1 				29
#define SR_CU2 				30
#define SR_CU3 				31
#define SR_CU_First 			28 
#define SR_CU_Last 			31

/* Cause Register (13) */
#define Cause_ExcCode_First 		2
#define Cause_ExcCode_Last 		6
#define Cause_IP0 			8
#define Cause_IP1 			9
#define Cause_IP2 			10
#define Cause_IP3 			11
#define Cause_IP4 			12
#define Cause_IP5 			13
#define Cause_IP6 			14
#define Cause_IP7 			15
#define Cause_IP_First 			8
#define Cause_IP_Last 			15
#define Cause_CE_First 			28 
#define Cause_CE_Last 			29
#define Cause_BD 			31

// Exception Program Counter (EPC) Register (14)

/* Processor Revision Identifier (PRId) Register (15) */
#define CPO_PRId_Rev_First 		0
#define CPO_PRId_Rev_Last 		7
#define CPO_PRId_Imp_First 		8 
#define CPO_Imp_Rev_Last 		15

/* Config Register (16) */
#define Config_K0_First 		0
#define Config_K0_Last 			2
#define Config_CU 			3
#define Config_DB 			4
#define Config_IB 			5
#define Config_DC_First 		6 
#define Config_DC_Last 			8
#define Config_IC_First 		9 
#define Config_IC_Last 			11
#define Config_EB 			13
#define Config_EM 			14
#define Config_BE 			15
#define Config_SM 			16
#define Config_SC 			17
#define Config_EW_First 		18 
#define Config_EW_Last 			19
#define Config_SW 			20
#define Config_SS 			21
#define Config_SB_First 		22 
#define Config_SB_Last 			23
#define Config_EP_First 		24 
#define Config_EP_Last 			27
#define Config_EC_First 		28 
#define Config_EC_Last 			30
#define Config_CM 			31

// Load Linked Address (LLAddr) Register (17)

/* WatchLo (18) and WatchHi (19) Registers */
#define WatchLo_W 			0
#define WatchLo_R 			1
#define WatchLo_PAddr0_First 		3		 
#define WatchLo_PAddr0_Last 		31
#define WatchHi_PAddr1_First 		0
#define WatchHi_PAddr1_Last 		3

/* XContext Register (20) */
#define XContext_BadVPN2_First 		4 
#define XContext_BadVPN2_Last 		30 
#define XContext_R_First 		31
#define XContext_R_Last 		32
#define XContext_PTEBase_First 		33
#define XContext_PTEBase_Last 		63

/* Error Checking and Correcting (ECC) Register (26) */
#define ECC_First 			0
#define ECC_Last 			7

/* Cache Error (CacheErr) Register (27) */
#define CacheErr_PIdx_First		0 
#define CacheErr_PIdx_Last 		2
#define CacheErr_SIdx_First 		3 
#define CacheErr_SIdx_Last 		21
#define CacheErr_EW 			23
#define CacheErr_EI 			24
#define CacheErr_EB 			25
#define CacheErr_EE 			26
#define CacheErr_ES 			27
#define CacheErr_ET 			28
#define CacheErr_ED 			29
#define CacheErr_EC 			30
#define CacheErr_ER 			31

/* Cache Tag Registers [TagLo (28) and TagHi (29)] */
#define CacheTag_ECC_First 		0
#define CacheTag_ECC_Last 		6
#define CacheTag_VIndex_First 		7 
#define CacheTag_VIndex_Last 		9
#define CacheTag_SState_First 		10 
#define CacheTag_SState_Last 		12
#define CacheTag_STagLo_First 		13 
#define CacheTag_STagLo_Last 		31
#define CacheTag_P 			0
#define CacheTag_PState_First 		6 
#define CacheTag_PState_Last 		7
#define CacheTag_PTagLo_First 		8 
#define CacheTag_PTagLo_Last 		31

/* Error Exception Program Counter (Error EPC) Register (30)
 * Exception numbers.
 */
#define EXC_Int	    (0 << 2)	// interrupt
#define EXC_Mod     (1 << 2)	// TLB modified exception
#define EXC_TLBL    (2 << 2)	// TLB exception (load or instruction fetch)
#define EXC_TLBS    (3 << 2)	// TLB exception (store)
#define EXC_AdEL    (4 << 2)	// Address error exception (load or fetch)
#define EXC_AdES    (5 << 2)	// Address error exception (store)
#define EXC_IBE	    (6 << 2)	// Bus error exception (instruction fetch)
#define EXC_DBE     (7 << 2)	// Bus error exception (load or store)
#define EXC_Sys	    (8 << 2)	// Syscall exception
#define EXC_Bp	    (9 << 2)	// Breakpoint exception
#define EXC_RI	    (10 << 2)	// Reserved instruction exception
#define EXC_CpU     (11 << 2)	// Coprocessor Unusable exception
#define EXC_Ov	    (12 << 2)	// Arithmetic overflow exception
#define EXC_Tr	    (13 << 2)	// Trap exception
#define EXC_VCEI    (14 << 2)	// Virtual Coherency Exception (I-cache)
#define EXC_FPE     (15 << 2)	// Floating-Point exception
// 16-22		// Reserved
#define EXC_WATCH   (23 << 2)	// Reference to WatchHi/WatchLo address
// 24-30		// Reserved
#define EXC_VCED    (31 << 2)	// Virtual Coherency Exception (D-cache)

/* Address space layout */
#define kseg2			0xC0000000 //TVA(0xC000,0x0000) //Shi yang 2006-08-09
#define kseg1			0xA0000000 //TVA(0xA000,0x0000)
#define kseg0			0x80000000 //TVA(0x8000,0x0000)
#define kuseg			0x00000000 //TVA(0x0000,0x0000)

#define KUSEG			0
#define KSEG0			1
#define KSEG1			2
#define KSEG2			3

/* Exception vectors */
#define reset_vector_base			0xBFC00000 //TVA(0xBFC0,0x0000)
#define general_vector_base			0x80000000 //TVA(0x8000,0x0000)
#define boot_vector_base			0x80000000 //TVA(0x8000,0x0000)
#define cache_error_vector_base			0xA0000000 //TVA(0xA000,0x0000)

#define reset_vector				0x000
#define tlb_refill_vector			0x000
#define xtlb_refill_vector			0x080
#define cache_error_vector			0x100
#define common_vector				0x180

#endif //end of _CPU_H_
