#ifndef _EMUL_H_
#define _EMUL_H_

#include "cache.h"
#include "cpu.h"

/* 16 bit implementation and revision fields.  The upper 8 bits are 0x20
 * for R3000. The lower 8 bits should distinguish the
 * simulator.
 */


/* Some instruction latencies. These are for R4600. On R4700, both all
 * four multiplication latencies are decreased by four cycles.
 */
#define  mult_latency		10
#define  multu_latency	 	10
#define  div_latency		42
#define  divu_latency		42
#define  dmult_latency	 	12
#define  dmultu_latency	 	12
#define  ddiv_latency		74
#define  ddivu_latency	 	74

/* Asynchronous event constants. Each interrupt source corresponds to a
 * single bit of the (events) word. Bits 8 through 16 correspond to
 * interrupts 0 through 7. Other bits represent the three reset exceptions
 * as follows:
 */
#define cold_reset_event	 	(1 << 0)
#define soft_reset_event		(1 << 1)
#define nmi_event			(1 << 2)

/* Cache of some strategic CPU mode bits. This shortcut is used to avoid
 * parsing of the somewhat convoluted Status register during address
 * translation and instruction decoding.
 */
#define xmode 	(1 << 0) // 64 bit mode ([USK]X & [usk]mode)
#define cmode 	(1 << 1) // 32 bit (compatibility) mode (!xmode)
#define bmode 	(1 << 2) // big-endian-cpu (big_endian_mem() ^ reverse_endian())
#define rmode 	(1 << 3) // reverse-endian (RE && umode)
#define umode 	(1 << 4) // user mode
#define smode 	(1 << 5) // supervisor mode
#define kmode 	(1 << 6) // kernel mode

/* Pipeline information. This is fairly ad hoc, but it is still useful */
#define nothing_special		0	// nothing special
#define branch_delay		1	// current instruction in the branch-delay slot
#define instr_addr_error	2 	// instruction address error
#define branch_nodelay	3 	// syscall instruction or eret instruction

/* Coprocessor 1 (FPU) simulator */

//static const char* condname[16];
#define FCR0   			0
#define FP_Rev_Last  		7
#define FP_Rev_First  		0
#define FP_Imp_Last  		15
#define FP_Imp_First  		8
#define FCR31  			31
#define FP_RM_Last  		1
#define FP_RM_First  		0
#define FP_Flag_Last  		6
#define FP_Flag_First  		2
#define FP_Enable_Last  	11
#define FP_Enable_First  	7
#define FP_Cause_Last  		17
#define FP_Cause_First  	12
#define FP_C  			23
#define FP_FS  			24

/* Software IEC/IEEE floating-point rounding mode */
#define float_round_nearest_even	0
#define float_round_to_zero      	1
#define float_round_up           	2
#define float_round_down         	3

/* Software IEC/IEEE floating-point exception flags */
#define float_flag_inexact   		1
#define float_flag_underflow 		2
#define float_flag_overflow  		4
#define float_flag_divbyzero 		8
#define float_flag_invalid   		16
#define float_flag_unimplemented	32

/* An invalid ASID bit used to mark unused TLB entries */
#define invalid_asid	(1 << 6) //Shi yang 2006-08-08

/* An global ASID bit */
#define global_asid	(1 << 6) //Shi yang 2006-08-08

/* Geometry of the TLB lookup map (see below.) */
#define log2_tlb_map_size  		6 //Shi yang 2006-08-08
#define tlb_map_size			(1 << log2_tlb_map_size)

/* An invalid cache tag used to mark unused cache lines */
#define bad_tag	~(UInt32)0

/* An invalid ibuf tag used to marked unused icache buffers */
#define bad_ibuf_tag ~(VA)0

/* An invalid physical address returned by translate_vaddr() on cache
 * operations that specify an invalid address.
 */
#define bad_pa	~(PA)0

/* TLB access types, used to select the appropriate TLB miss handler */
#define instr_fetch			0 //instruction fetch
#define data_load			1 //data load
#define data_store			2 //data store
#define cache_op			3 //cache operations (ignore errors)

#define no_tracing			0
#define report_interrupts		1
#define report_exceptions		2
#define print_instructions		3
#define dump_gprs			4
/* The NOP guard */
#define catch_nops			128

/* if return 0, translate 
 * 0 means find the correct PA
 * 1 means some TLB exception happened
 */
#define TLB_FAIL -1
#define TLB_SUCC 0
#define TLB_EXP 1

/* A TLB Entry structure */
typedef struct TLBEntry_s {
	struct TLBEntry_s* next;	// the hash chain
	struct TLBEntry_s* prev;	// the hash chain
	UInt16 page_mask;
	UInt32 hi;	// VPN << 12
	UInt32 lo_reg[2];	// EntryLo0
	UInt16 index;	// TLB index
	UInt16 hash;	// TLB map index
}TLBEntry;

/* The two-entry ITLB. Each entry maps a 4KB page */
typedef struct ITLBEntry_s {
	VA vpn;		// virtual address page number (va / 4KB)
	PA pa;		// physical address and the caching algorithm
	Int16 asid;	// ASID and the global bit.
}ITLBEntry;

/* Although not in real hardware, we also cache the two most recent
 * I-cache accesses, as simulating cache lookups is slow, and as many as 8
 * instructions can be fetched from one cache line.
 */
typedef struct ICacheBuffer_s {
	VA tag;		// address of the cache shifted by log2_icache_line
	UInt32* line;	// pointer to the ICache line.
}ICacheBuffer;

typedef struct MIPS_State_s{
	// The register set.
	VA pc;			// Program Counter
	UInt32 gpr[32];		// General Purpose Registers
	UInt32 fpr[32];		// Floating-Point General Purpose Registers
	UInt32 fir,fcsr;  	// Floating-point implementation register and control-status register
	UInt32 cp0[32];		// CP0 Registers
	UInt32 cp0_config1;
	UInt32 cp1[32];		// CP1 Registers
	UInt32 hi, lo;		// Multiply and Divide Registers
	int ll_bit;		// The Load-Linked Bit

	ClockValue now;	
	int warm;		//flag:warm_reset or cold_reset
	int nop_count;		//nop instruction count

	// CPU state.
	UInt16 events;		// external events: this also replaces Cause[15:8].
	UInt8 pipeline;		// current instruction in the branch-delay slot
	UInt8 mode;		// CPU mode
	int sync_bit;		// true after executing the SYNC instruction.
	VA branch_target;	// next PC when in the branch delay slot	

	/* cp0[Random] is not updated on each clock cycle. Instead, its value is
	 * updated when either cp0[Random] or cp0[Wired] is set, and the current
	 * value is computed using the time elapsed since then.
         */
	ClockValue random_seed;
	// Similary, we lazily compute the value of the Count register.
	ClockValue count_seed;

	// ITLB data. (lru_itlb) stores the index of the least-recently used entry.
	ITLBEntry itlb[2];
	int lru_itlb;
	/* I-cache buffer data (lru_ibuf) stores the index of the least-recently
	 * used entry (0 or 1).
	 */
	ICacheBuffer ibuf[2];
	int lru_ibuf;

	int env; 		//The longjmp buffer used for handling exceptions.

	/* The TLB and L1 caches */
	TLBEntry tlb[tlb_size];
	ICache icache;
	DCache dcache;
	/* The TLB map used to simulate the direct-mapped TLB lookup.  There's an
	 * extra entry at the end that contains the hash chain of all unused TLB
	 * entries (that way, there is always exactly (tlb_size) mappings in the
	 * hash table).
	 */
	TLBEntry* tlb_map[tlb_map_size + 1];

	int trace_level;	
	// Finally, some configuration data.
	struct  conf_t{
		char* bus;
		int ec;
		char* ep;
		int be;
		int trace;
	} conf;

	unsigned bigendSig;
	int irq_pending;
}MIPS_State;

void reset(int warm);

/* Interrupt delivery functions */
void deliver_cold_reset(MIPS_State* mstate);
void deliver_soft_reset(MIPS_State* mstate);

/* TLB operations */
void reset_tlb(MIPS_State* mstate);
void dump_tlb();
TLBEntry* probe_tlb(MIPS_State* mstate, VA va);
void set_tlb_entry(MIPS_State* mstate, int index);

int translate_vaddr(MIPS_State* mstate, VA va, int type, PA *pa);

/* Instruction cache operations */
void reset_icache(MIPS_State* mstate);
void control_icache(MIPS_State* mstate, VA va, PA pa, int op, int type);
Instr fetch(MIPS_State* mstate, VA va, PA pa);

/* Data cache operations*/
void reset_dcache(MIPS_State* mstate);
void control_dcache(MIPS_State* mstate, VA va, PA pa, int op, int type);
UInt32 load_left(UInt32 x, VA va, int syscmd);		// LDL, LWL
UInt32 load_right(UInt32 x, VA va, int syscmd);		// LDR, LWR
void store_left(UInt32 x, VA va, int syscmd);		// SDL, SWL
void store_right(UInt32 x, VA va, int syscmd);		// SDR, SWR

/* Complete any pending memory operations */
//void sync();
void process_reset(MIPS_State* mstate);
void process_exception(MIPS_State* mstate, UInt32 cause, int vec);

/* Set the Coprocessor 0 timer interrupt */
void set_timer();
/* Coprocessor 0 register access. This is necessary as some registers
 * are computed on demand, and most registers have some read-only fields.
 */
UInt32 read_cp0(MIPS_State* mstate, int n, int sel) ;
void write_cp0(MIPS_State* mstate, int n, UInt32 x);

/* The main instruction decoder with satelite functions for some of the
 * more elaborate instructions.
 */
int decode(MIPS_State* mstate, Instr instr);
int decode_cop0(MIPS_State* mstate, Instr instr);
int decode_cop1(MIPS_State* mstate, Instr instr);
int decode_cache(MIPS_State* mstate, Instr instr);
int decode_ldc1(MIPS_State* mstate, Instr instr);
int decode_lwc1(MIPS_State* mstate, Instr instr);
int decode_sdc1(MIPS_State* mstate, Instr instr);
int decode_swc1(MIPS_State* mstate, Instr instr);

/* Some debugging help */
void dump_gpr_registers() ;
void dump_fpr_registers() ;

#endif //end of _EMUL_H__
