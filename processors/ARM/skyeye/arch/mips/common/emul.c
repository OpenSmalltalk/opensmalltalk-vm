#include "emul.h"
/*
        mips_regdefs.c - necessary mips definition for skyeye debugger
        Copyright (C) 2003 Skyeye Develop Group
        for help please send mail to <skyeye-developer@lists.sf.linuxforum.net>

        This program is free software; you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation; either version 2 of the License, or
        (at your option) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program; if not, write to the Free Software
        Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/
/*
 * 07/06/2007   Michael.Kang  <blackfin.kang@gmail.com>
 */
#include <stdio.h>
#include <stdlib.h>

extern MIPS_State* mstate;
/* Address decoder macros.
 * Bits 29, 30 and 31 of the virtual address select the user or kernel address spaces.
 */
int
vaddr_region(VA va)
{
	return bits(va, 31, 29); 
}

int 
vaddr_compat_region(UInt32 va)
{ 
	return bits(va, 31, 30); 
}

int 
get_random(MIPS_State* mstate) //Fix me: Shi yang 2006-08-10
{
	int wired = mstate->cp0[Wired];
	int free = tlb_size - wired;
	return (tlb_size - 1 - wired + (mstate->now - mstate->random_seed)) % free + wired;
}

void 
enter_kernel_mode(MIPS_State* mstate)
{	
	//copy_bits(mstate->cp0[SR], (bits(mstate->cp0[SR], 3, 0) << 2), 5, 2); //Shi yang 2006-08-10
	//clear_bits(mstate->cp0[SR], 1, 0); //Enter kernel mode
	mstate->mode = kmode;
}

void 
leave_kernel_mode(MIPS_State* mstate)
{
	copy_bits(mstate->cp0[SR], (bits(mstate->cp0[SR], 5, 2)), 3, 0);
	copy_bits(mstate->cp0[SR], (bits(mstate->cp0[SR], 3, 2) << 4), 5, 4); 
	if (bit(mstate->cp0[SR], 1) == 0)
		mstate->mode |= kmode; //From kernel mode to kernel mode
	else
		mstate->mode = umode; //From kernel mode to user mode
}

/* An ASID is represented by a 16 bit integer that is either a positive
 * (non-zero) ASID, complemented  if the G bit is also set. asid_match()
 * checks two ASIDs for equivalence. Yet another demonstration of the
 * versatility of exclusive-or. ;)
 */
int 
asid_match(Int16 asid1, Int16 asid2)
{ 
	return (asid1 ^ asid2) <= 0; 
}


/* Operations on the TLB lookup map. The map is a hash table indexed by a
 * hash value computed from the ASID and the bits of virtual page number
 * unaffected by any page mask. The result of the map lookup is a TLB
 * entry. The hash function doesn't provide an ideal distribution, but as
 * a minimum, it maintains a separate hash chain per ASID, and provides
 * good distribution at least for sparse address spaces.  The hash table
 * always has an extra entry pointing to an invalid page.
 */

int 
tlb_hash(VA va)
{ 
	return (bits(va, 31, 13) % tlb_map_size); 
}

int 
va_match(VA va1, VA va2)
{ 
	return !(va1 ^ va2); //Shi yang 2006-08-11 
}

// I-cache buffer operations.

int 
ibuf_match(PA pa, PA tag) //Shi yang 2006-08-10
{ 
	return ((pa >> log2_icache_line) ^ tag) == 0; 
}

// Some state information constants.

int 
allow_xinstr(MIPS_State* mstate) 
{ 
	return mstate->mode & (kmode|xmode); 
}

int 
branch_delay_slot(MIPS_State* mstate) //Shi yang 2006-08-10 
{ 
	return mstate->pipeline == branch_delay; 
}

void 
process_address_error(MIPS_State* mstate, int type, VA va)
{
	int exc = (type == data_store) ? EXC_AdES : EXC_AdEL;
	if(exc == EXC_AdEL)
		printf("In %s,va=0x%x,EXC_AdEL,pc=0x%x\n",__FUNCTION__, va, mstate->pc);
	else
		printf("In %s,va=0x%x,EXC_AdES, pc=0x%x\n", __FUNCTION__, va, mstate->pc);
		
	mstate->cp0[BadVAddr] = va;
	process_exception(mstate, exc, common_vector);
}

void 
process_tlb_refill(MIPS_State* mstate, int type, VA va)
{
	int exc = (type == data_store) ? EXC_TLBS : EXC_TLBL;
	int vec = tlb_refill_vector;
	mstate->cp0[BadVAddr] = va;
	mstate->cp0[Context] = (va & 0xFFFFe000 >> 9) | (mstate->cp0[Context] & 0x7FFFF0);
	mstate->cp0[EntryHi] = (va & 0xFFFFE000) | (mstate->cp0[EntryHi] & 0x1FFF);
	process_exception(mstate, exc, vec);
}

void 
process_tlb_invalid(MIPS_State* mstate, int type, VA va)
{
	int exc = (type == data_store) ? EXC_TLBS : EXC_TLBL;
	mstate->cp0[BadVAddr] = va;
	mstate->cp0[Context] = (va & 0xFFFFe000 >> 9) | (mstate->cp0[Context] & 0x7FFFF0);

	mstate->cp0[EntryHi] = (va & 0xFFFFE000) | (mstate->cp0[EntryHi] & 0x1FFF);
	process_exception(mstate, exc, common_vector);
}

void 
process_tlb_modified(MIPS_State* mstate, VA va)
{
	//printf("In %s, va=0x%x\n", __FUNCTION__, va);
	mstate->cp0[BadVAddr] = va;
	mstate->cp0[Context] = (va & 0xFFFFe000 >> 9) | (mstate->cp0[Context] & 0x7FFFF0);
	mstate->cp0[EntryHi] = (va & 0xFFFFE000) | (mstate->cp0[EntryHi] & 0x1FFF);
	process_exception(mstate, EXC_Mod, common_vector);
}

void 
process_bus_error(MIPS_State* mstate, int type)
{
	int exc = (type == instr_fetch) ? EXC_IBE : EXC_DBE;
	process_exception(mstate, exc, common_vector);
}

void 
process_integer_overflow(MIPS_State* mstate)
{ 
	process_exception(mstate,EXC_Ov, common_vector); 
}

void 
process_trap(MIPS_State* mstate)
{
	printf("Begin process_trap.\n");
	process_exception(mstate, EXC_Tr, common_vector); 
}

void 
process_syscall(MIPS_State* mstate)
{ 
	//printf("syscall.\n");
	process_exception(mstate, EXC_Sys, common_vector); 
}

void 
process_breakpoint(MIPS_State* mstate)
{ 
	process_exception(mstate, EXC_Bp, common_vector); 
}

void 
process_reserved_instruction(MIPS_State* mstate)
{ 
	fprintf(stderr,"In %s,pc=0x%x", __FUNCTION__, mstate->pc);
	skyeye_exit(-1);
	process_exception(mstate, EXC_RI, common_vector); 
}

void 
process_coprocessor_unusable(MIPS_State* mstate, int c)
{ 
	process_exception(mstate, EXC_CpU | (c << (Cause_CE_First)), common_vector); 
}

void 
process_fp_exception(MIPS_State* mstate)
{ 
	process_exception(mstate,EXC_FPE, common_vector); 
}

void 
process_interrupt(MIPS_State* mstate)
{ 
	process_exception(mstate,EXC_Int, common_vector); 
}

/* Endianess parameters. The data received from the memory bus is always
 * in the host byte order, and uses host byte addressing.
 */
int 
big_endian_mem(MIPS_State* mstate)
{ 
	return bit(mstate->cp0[Config], Config_BE); 
}

int 
reverse_endian(MIPS_State* mstate) 
{ 
	return mstate->mode & rmode; 
}

int 
big_endian_cpu(MIPS_State* mstate) 
{ 
	return mstate->mode & bmode; 
}

UInt32 
swizzle_word(UInt32 x, UInt32 addr) //Fix me: Shi yang
{
	return x; //Shi yang 2006-08-18
    	
}

UInt8  
swizzle_byte(UInt32 x, UInt32 addr)
{
	int offset;
	offset = (((UInt32) mstate->bigendSig * 3) ^ (addr & 3)) << 3; //Shi yang 2006-08-18
	return (x >> offset) & 0xffL;
}

UInt16 
swizzle_doublebyte(UInt32 x, UInt32 addr)
{
	int offset;
	offset = (((UInt32)mstate->bigendSig * 2) ^ (addr & 2)) << 3; //Shi yang 2006-08-18
	return (x >> offset) & 0xffffL;
	
}

inline Int32 
sign_extend_Int32(Int32 x, int n)
{
	if (((Int32)-1 >> 1) < 0) {
		// Host platform does arithmetic right shifts.
		Int32 y = x;
		return y << (8 * sizeof(Int32) - n) >> (8 * sizeof(Int32) - n);
    	} else if (n < 8 * sizeof(Int32)) {
		// We have to manually patch the high-order bits.
		if (bit(x, n - 1))
	    		return set_bits(x, 8 * sizeof(Int32) - 1, n);
		else
	    		return clear_bits(x, 8 * sizeof(Int32) - 1, n);
    	}
}

inline UInt32 
sign_extend_UInt32(UInt32 x, int n)
{
	if (((UInt32)-1 >> 1) < 0) {
		// Host platform does arithmetic right shifts.
		UInt32 y = x;
		return y << (8 * sizeof(UInt32) - n) >> (8 * sizeof(UInt32) - n);
    	} else if (n < 8 * sizeof(UInt32)) {
		// We have to manually patch the high-order bits.
		if (bit(x, n - 1))
	    		return set_bits(x, 8 * sizeof(UInt32) - 1, n);
		else
	    		return clear_bits(x, 8 * sizeof(UInt32) - 1, n);

    	}
}

inline Int64 
sign_extend_Int64(Int64 x, int n)
{
	if (((Int64)-1 >> 1) < 0) {
		// Host platform does arithmetic right shifts.
		Int64 y = x;
		return y << (8 * sizeof(Int64) - n) >> (8 * sizeof(Int64) - n);
    	} else if (n < 8 * sizeof(Int64)) {
		// We have to manually patch the high-order bits.
		if (bit(x, n - 1))
	    		return set_bits(x, 8 * sizeof(Int64) - 1, n);
		else
	    		return clear_bits(x, 8 * sizeof(Int64) - 1, n);
    	}
}

inline UInt64 
sign_extend_UInt64(UInt64 x, int n)
{
	if (((UInt64)-1 >> 1) < 0) {
		// Host platform does arithmetic right shifts.
		UInt64 y = x;
		return y << (8 * sizeof(UInt64) - n) >> (8 * sizeof(UInt64) - n);
    	} else if (n < 8 * sizeof(UInt64)) {
		// We have to manually patch the high-order bits.
		if (bit(x, n - 1))
	    		return set_bits(x, 8 * sizeof(UInt64) - 1, n);
		else
		    	return clear_bits(x, 8 * sizeof(UInt64) - 1, n);
    	}
}

// Specialisations for 32 and 64 bit types.

inline void 
divide_Int32(Int32 a, Int32 b)
{
    	if (32 <= sizeof(int)) {
		div_t r = div((int)(a), (int)(b));
		DivResult(r.quot, r.rem);
    	} else {
		ldiv_t r = ldiv((long)(a),(long)(b));
		DivResult(r.quot, r.rem);
    	}
}

inline void 
divide_UInt32(UInt32 a, UInt32 b)
{
    	if (32 < sizeof(long)) {
		ldiv_t r = ldiv((long)(a), (long)(b));
		DivResult(r.quot, r.rem);
    	} else {
		DivResult(a / b, a % b);
    	}
}

inline void 
divide_Int64(Int64 a, Int64 b)
{
    	if (64 <= sizeof(long)) {
		ldiv_t r = ldiv((long)(a), (long)(b));
		DivResult(r.quot, r.rem);
    	} else if ((Int64)(-2) % (Int64)(3) < 0) 
		// Hardware division rounds towards zero.
		DivResult(a / b, a % b)
    	else {
		// Hardware division rounds towards negative infinity, so fix it.
		if ((a ^ b) >= 0)
	    		DivResult(a / b, a % b)
		else if (a < 0)
	    		DivResult(-(-a / b), -(-a % b))
		else 
	    		DivResult(-(a / -b), -(a % -b))
	}
}
