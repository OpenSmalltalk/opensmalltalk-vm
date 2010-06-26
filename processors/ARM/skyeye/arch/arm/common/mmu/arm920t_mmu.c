/*
    arm920t_mmu.c - ARM920T Memory Management Unit emulation.
    Copyright (C) 2003 Skyeye Develop Group
    for help please send mail to <skyeye-developer@lists.gro.clinux.org>

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

#include <assert.h>
#include <string.h>

#include "armdefs.h"

#define ARM920T_I_TLB() (&state->mmu.u.arm920t_mmu.i_tlb)
#define ARM920T_I_CACHE() (&state->mmu.u.arm920t_mmu.i_cache)

#define ARM920T_D_TLB() (&state->mmu.u.arm920t_mmu.d_tlb)
#define ARM920T_D_CACHE() (&state->mmu.u.arm920t_mmu.d_cache)
#define ARM920T_WB() (&state->mmu.u.arm920t_mmu.wb_t)

typedef struct arm920t_mmu_desc_s
{
	int i_tlb;
	cache_desc_t i_cache;

	int d_tlb;
	cache_desc_t d_cache;
	wb_desc_t wb;
} arm920t_mmu_desc_t;

static arm920t_mmu_desc_t arm920t_mmu_desc = {
	64,
	/* 32 bytes per line
	 * 64 way
	 * 8 set
	 * */
	{32, 64, 8, CACHE_WRITE_BACK},

	64,
	{32, 64, 8, CACHE_WRITE_BACK},
	{8, 8}			//for byte size
};

static fault_t arm920t_mmu_write (ARMul_State * state, ARMword va,
				  ARMword data, ARMword datatype);
static fault_t arm920t_mmu_read (ARMul_State * state, ARMword va,
				 ARMword * data, ARMword datatype);
static fault_t update_cache (ARMul_State * state, ARMword va, ARMword data,
			     ARMword datatype, cache_line_t * cache,
			     cache_t * cache_t, ARMword real_va);

int
arm920t_mmu_init (ARMul_State * state)
{
	arm920t_mmu_desc_t *desc;
	cache_desc_t *c_desc;

	state->mmu.control = 0x70;
	state->mmu.translation_table_base = 0xDEADC0DE;
	state->mmu.domain_access_control = 0xDEADC0DE;
	state->mmu.fault_status = 0;
	state->mmu.fault_address = 0;
	state->mmu.process_id = 0;

	desc = &arm920t_mmu_desc;
	if (mmu_tlb_init (ARM920T_I_TLB (), desc->i_tlb)) {
		err_msg ("i_tlb init %d\n", -1);
		goto i_tlb_init_error;
	}

	c_desc = &desc->i_cache;
	if (mmu_cache_init (ARM920T_I_CACHE (), c_desc->width, c_desc->way,
			    c_desc->set, c_desc->w_mode)) {
		err_msg ("i_cache init %d\n", -1);
		goto i_cache_init_error;
	}

	if (mmu_tlb_init (ARM920T_D_TLB (), desc->d_tlb)) {
		err_msg ("d_tlb init %d\n", -1);
		goto d_tlb_init_error;
	}

	c_desc = &desc->d_cache;
	if (mmu_cache_init (ARM920T_D_CACHE (), c_desc->width, c_desc->way,
			    c_desc->set, c_desc->w_mode)) {
		err_msg ("d_cache init %d\n", -1);
		goto d_cache_init_error;
	}

	if (mmu_wb_init (ARM920T_WB (), desc->wb.num, desc->wb.nb)) {
		err_msg ("wb init %d\n", -1);
		goto wb_init_error;
	}
	return 0;

      wb_init_error:
	mmu_cache_exit (ARM920T_D_CACHE ());
      d_cache_init_error:
	mmu_tlb_exit (ARM920T_D_TLB ());
      d_tlb_init_error:
	mmu_cache_exit (ARM920T_I_CACHE ());
      i_cache_init_error:
	mmu_tlb_exit (ARM920T_I_TLB ());
      i_tlb_init_error:
	return -1;
}

void
arm920t_mmu_exit (ARMul_State * state)
{
	mmu_wb_exit (ARM920T_WB ());
	mmu_cache_exit (ARM920T_D_CACHE ());
	mmu_tlb_exit (ARM920T_D_TLB ());
	mmu_cache_exit (ARM920T_I_CACHE ());
	mmu_tlb_exit (ARM920T_I_TLB ());
};


static fault_t
arm920t_mmu_load_instr (ARMul_State * state, ARMword va, ARMword * instr)
{
	fault_t fault;
	tlb_entry_t *tlb;
	cache_line_t *cache;
	int c;			//cache bit
	ARMword pa;		//physical addr

	static int debug_count = 0;	//used for debug

	d_msg ("va = %x\n", va);

	va = mmu_pid_va_map (va);
	if (MMU_Enabled) {
		/*align check */
		if ((va & (WORD_SIZE - 1)) && MMU_Aligned) {
			d_msg ("align\n");
			return ALIGNMENT_FAULT;
		}
		else
			va &= ~(WORD_SIZE - 1);

		/*translate tlb */
		fault = translate (state, va, ARM920T_I_TLB (), &tlb);
		if (fault) {
			d_msg ("translate\n");
			return fault;
		}

		/*check access */
		fault = check_access (state, va, tlb, 1);
		if (fault) {
			d_msg ("check_fault\n");
			return fault;
		}
	}

	/*search cache no matter MMU enabled/disabled */
	cache = mmu_cache_search (state, ARM920T_I_CACHE (), va);
	if (cache) {
		*instr = cache->data[va_cache_index (va, ARM920T_I_CACHE ())];
		return 0;
	}

	/*if MMU disabled or C flag is set alloc cache */
	if (MMU_Disabled) {
		c = 1;
		pa = va;
	}
	else {
		c = tlb_c_flag (tlb);
		pa = tlb_va_to_pa (tlb, va);
	}

	if (c) {
		int index;

		debug_count++;
		cache = mmu_cache_alloc (state, ARM920T_I_CACHE (), va, pa);
		index = va_cache_index (va, ARM920T_I_CACHE ());
		*instr = cache->data[va_cache_index (va, ARM920T_I_CACHE ())];
	}
	else
		//*instr = mem_read_word (state, pa);
		bus_read(32, pa, instr);

	return 0;
};



static fault_t
arm920t_mmu_read_byte (ARMul_State * state, ARMword virt_addr, ARMword * data)
{
	//ARMword temp,offset;
	fault_t fault;
	fault = arm920t_mmu_read (state, virt_addr, data, ARM_BYTE_TYPE);
	return fault;
}

static fault_t
arm920t_mmu_read_halfword (ARMul_State * state, ARMword virt_addr,
			   ARMword * data)
{
	//ARMword temp,offset;
	fault_t fault;
	fault = arm920t_mmu_read (state, virt_addr, data, ARM_HALFWORD_TYPE);
	return fault;
}

static fault_t
arm920t_mmu_read_word (ARMul_State * state, ARMword virt_addr, ARMword * data)
{
	return arm920t_mmu_read (state, virt_addr, data, ARM_WORD_TYPE);
}




static fault_t
arm920t_mmu_read (ARMul_State * state, ARMword va, ARMword * data,
		  ARMword datatype)
{
	fault_t fault;
	tlb_entry_t *tlb;
	cache_line_t *cache;
	ARMword pa, real_va, temp, offset;

	d_msg ("va = %x\n", va);

	va = mmu_pid_va_map (va);
	real_va = va;
	/*if MMU disabled, memory_read */
	if (MMU_Disabled) {
		//*data = mem_read_word(state, va);
		if (datatype == ARM_BYTE_TYPE)
			//*data = mem_read_byte (state, va);
			bus_read(8, va, data);
		else if (datatype == ARM_HALFWORD_TYPE)
			//*data = mem_read_halfword (state, va);
			bus_read(16, va, data);
		else if (datatype == ARM_WORD_TYPE)
			//*data = mem_read_word (state, va);
			bus_read(32, va, data);
		else {
			printf ("SKYEYE:1 arm920t_mmu_read error: unknown data type %d\n", datatype);
			skyeye_exit (-1);
		}

		return 0;
	}

	/*align check */
	if (((va & 3) && (datatype == ARM_WORD_TYPE) && MMU_Aligned) ||
	    ((va & 1) && (datatype == ARM_HALFWORD_TYPE) && MMU_Aligned)) {
		d_msg ("align\n");
		return ALIGNMENT_FAULT;
	}			// else

	va &= ~(WORD_SIZE - 1);

	/*translate va to tlb */
	fault = translate (state, va, ARM920T_D_TLB (), &tlb);
	if (fault) {
		d_msg ("translate\n");
		return fault;
	}
	/*check access permission */
	fault = check_access (state, va, tlb, 1);
	if (fault)
		return fault;
	/*search main cache */
	cache = mmu_cache_search (state, ARM920T_D_CACHE (), va);
	if (cache) {
		*data = cache->data[va_cache_index (va, ARM920T_D_CACHE ())];
		goto datatrans;
		//return 0;
	}

	/*get phy_addr */
	pa = tlb_va_to_pa (tlb, va);
	if ((pa >= 0xe0000000) && (pa < 0xe8000000)) {
		if (tlb_c_flag (tlb)) {
			//if (tlb_b_flag(tlb)){
			//      mmu_cache_soft_flush(state, ARM920T_D_CACHE(), pa);
			//}
			mmu_cache_soft_flush (state, ARM920T_D_CACHE (), pa);
		}
		return 0;
	}

	/*if Buffer, drain Write Buffer first */
	if (tlb_b_flag (tlb))
		mmu_wb_drain_all (state, ARM920T_WB ());

	/*alloc cache or mem_read */
	if (tlb_c_flag (tlb) && MMU_DCacheEnabled) {
		cache_t *cache_t;

		//if (tlb_b_flag(tlb))
		cache_t = ARM920T_D_CACHE ();
		cache = mmu_cache_alloc (state, cache_t, va, pa);
		*data = cache->data[va_cache_index (va, cache_t)];
	}
	else {
		//*data = mem_read_word(state, pa);
		if (datatype == ARM_BYTE_TYPE)
			//*data = mem_read_byte (state, pa | (real_va & 3));
			bus_read(8, pa | (real_va & 3), data);
		else if (datatype == ARM_HALFWORD_TYPE)
			//*data = mem_read_halfword (state, pa | (real_va & 2));
			bus_read(16, pa | (real_va & 2), data);
		else if (datatype == ARM_WORD_TYPE)
			//*data = mem_read_word (state, pa);
			bus_read(32, pa, data);
		else {
			printf ("SKYEYE:2 arm920t_mmu_read error: unknown data type %d\n", datatype);
			skyeye_exit (-1);
		}
		return 0;
	}


      datatrans:
	if (datatype == ARM_HALFWORD_TYPE) {
		temp = *data;
		offset = (((ARMword) state->bigendSig * 2) ^ (real_va & 2)) << 3;	/* bit offset into the word */
		*data = (temp >> offset) & 0xffff;
	}
	else if (datatype == ARM_BYTE_TYPE) {
		temp = *data;
		offset = (((ARMword) state->bigendSig * 3) ^ (real_va & 3)) << 3;	/* bit offset into the word */
		*data = (temp >> offset & 0xffL);
	}
      end:
//      printf("va: %x, pa:%x data: %x\n", va, pa, *data);
	return 0;
}


static fault_t
arm920t_mmu_write_byte (ARMul_State * state, ARMword virt_addr, ARMword data)
{
	return arm920t_mmu_write (state, virt_addr, data, ARM_BYTE_TYPE);
}

static fault_t
arm920t_mmu_write_halfword (ARMul_State * state, ARMword virt_addr,
			    ARMword data)
{
	return arm920t_mmu_write (state, virt_addr, data, ARM_HALFWORD_TYPE);
}

static fault_t
arm920t_mmu_write_word (ARMul_State * state, ARMword virt_addr, ARMword data)
{
	return arm920t_mmu_write (state, virt_addr, data, ARM_WORD_TYPE);
}



static fault_t
arm920t_mmu_write (ARMul_State * state, ARMword va, ARMword data,
		   ARMword datatype)
{
	tlb_entry_t *tlb;
	cache_line_t *cache;
	int b;
	ARMword pa, real_va;
	fault_t fault;

	d_msg ("va = %x, val = %x\n", va, data);
	va = mmu_pid_va_map (va);
	real_va = va;

	/*search instruction cache */
	cache = mmu_cache_search (state, ARM920T_I_CACHE (), va);
	if (cache) {
		update_cache (state, va, data, datatype, cache,
			      ARM920T_I_CACHE (), real_va);
	}

	if (MMU_Disabled) {
		//mem_write_word(state, va, data);
		if (datatype == ARM_BYTE_TYPE)
			//mem_write_byte (state, va, data);
			bus_write(8, va, data);	
		else if (datatype == ARM_HALFWORD_TYPE)
			//mem_write_halfword (state, va, data);
			bus_write(16,va, data);
		else if (datatype == ARM_WORD_TYPE)
			//mem_write_word (state, va, data);
			bus_write(32, va, data);
		else {
			printf ("SKYEYE:1 arm920t_mmu_write error: unknown data type %d\n", datatype);
			skyeye_exit (-1);
		}

		return 0;
	}
	/*align check */
	//if ((va & (WORD_SIZE - 1)) && MMU_Aligned){
	if (((va & 3) && (datatype == ARM_WORD_TYPE) && MMU_Aligned) ||
	    ((va & 1) && (datatype == ARM_HALFWORD_TYPE) && MMU_Aligned)) {
		d_msg ("align\n");
		return ALIGNMENT_FAULT;
	}			//else
	va &= ~(WORD_SIZE - 1);
	/*tlb translate */
	fault = translate (state, va, ARM920T_D_TLB (), &tlb);
	if (fault) {
		d_msg ("translate\n");
		return fault;
	}
	/*tlb check access */
	fault = check_access (state, va, tlb, 0);
	if (fault) {
		d_msg ("check_access\n");
		return fault;
	}
	/*search main cache */
	cache = mmu_cache_search (state, ARM920T_D_CACHE (), va);
	if (cache) {
		update_cache (state, va, data, datatype, cache,
			      ARM920T_D_CACHE (), real_va);
	}

	if (!cache) {
		b = tlb_b_flag (tlb);
		pa = tlb_va_to_pa (tlb, va);
		if (b) {
			if (MMU_WBEnabled) {
				if (datatype == ARM_WORD_TYPE)
					mmu_wb_write_bytes (state,
							    ARM920T_WB (), pa,
							    &data, 4);
				else if (datatype == ARM_HALFWORD_TYPE)
					mmu_wb_write_bytes (state,
							    ARM920T_WB (),
							    (pa |
							     (real_va & 2)),
							    &data, 2);
				else if (datatype == ARM_BYTE_TYPE)
					mmu_wb_write_bytes (state,
							    ARM920T_WB (),
							    (pa |
							     (real_va & 3)),
							    &data, 1);

			}
			else {
				if (datatype == ARM_WORD_TYPE)
					//mem_write_word (state, pa, data);
					bus_write(32, pa, data);
				else if (datatype == ARM_HALFWORD_TYPE)
					/* mem_write_halfword (state,
							    (pa |
							     (real_va & 2)),
							    data);
					*/
					bus_write(16, (pa |(real_va & 2)), data);
				else if (datatype == ARM_BYTE_TYPE)
					/* mem_write_byte (state,
							(pa | (real_va & 3)),
							data);
					*/
					bus_write(32, (pa | (real_va & 3)), data);
			}
		}
		else {
			mmu_wb_drain_all (state, ARM920T_WB ());

			if (datatype == ARM_WORD_TYPE)
				//mem_write_word (state, pa, data);
				bus_write(32, pa, data);
			else if (datatype == ARM_HALFWORD_TYPE)
				/*
				mem_write_halfword (state,
						    (pa | (real_va & 2)),
						    data);
				*/
				bus_write(16, pa, data);
			else if (datatype == ARM_BYTE_TYPE)
				/*mem_write_byte (state, (pa | (real_va & 3)),
						data);
				*/
				bus_write(8, pa, data);
		}
	}
	return 0;
}

static fault_t
update_cache (ARMul_State * state, ARMword va, ARMword data, ARMword datatype,
	      cache_line_t * cache, cache_t * cache_t, ARMword real_va)
{
	ARMword temp, offset;

	ARMword index = va_cache_index (va, cache_t);

	//cache->data[index] = data;

	if (datatype == ARM_WORD_TYPE)
		cache->data[index] = data;
	else if (datatype == ARM_HALFWORD_TYPE) {
		temp = cache->data[index];
		offset = (((ARMword) state->bigendSig * 2) ^ (real_va & 2)) << 3;	/* bit offset into the word */
		cache->data[index] =
			(temp & ~(0xffffL << offset)) | ((data & 0xffffL) <<
							 offset);
	}
	else if (datatype == ARM_BYTE_TYPE) {
		temp = cache->data[index];
		offset = (((ARMword) state->bigendSig * 3) ^ (real_va & 3)) << 3;	/* bit offset into the word */
		cache->data[index] =
			(temp & ~(0xffL << offset)) | ((data & 0xffL) <<
						       offset);
	}

	if (index < (cache_t->width >> (WORD_SHT + 1)))
		cache->tag |= TAG_FIRST_HALF_DIRTY;
	else
		cache->tag |= TAG_LAST_HALF_DIRTY;

	return 0;
}

ARMword
arm920t_mmu_mrc (ARMul_State * state, ARMword instr, ARMword * value)
{
	mmu_regnum_t creg = BITS (16, 19) & 0xf;
	int OPC_2 = BITS (5, 7) & 0x7;
	ARMword data;

	switch (creg) {
	case MMU_ID:
		if (OPC_2 == 0)
			data = state->cpu->cpu_val;
		else if (OPC_2 == 1)
			/* Cache type: 
			 * 000 0110 1 000 101 110 0 10 000 101 110 0 10
			 * */
			data = 0x0D172172;
		break;
	case MMU_CONTROL:
		/*
		 * 6:3          should be 1.
		 * 11:10        should be 0
		 * */
		data = (state->mmu.control | 0x78) & 0xFFFFF3FF;;
		break;
	case MMU_TRANSLATION_TABLE_BASE:
		data = state->mmu.translation_table_base;
		break;
	case MMU_DOMAIN_ACCESS_CONTROL:
		data = state->mmu.domain_access_control;
		break;
	case MMU_FAULT_STATUS:
		/* OPC_2 = 0: data FSR value
		 * */
		if (OPC_2 == 0)
			data = state->mmu.fault_status;
		break;
	case MMU_FAULT_ADDRESS:
		data = state->mmu.fault_address;
		break;
	case MMU_PID:
		data = state->mmu.process_id;
	default:
		printf ("mmu_mrc read UNKNOWN - reg %d\n", creg);
		data = 0;
		break;
	}
//      printf("\t\t\t\t\tpc = 0x%08x\n", state->Reg[15]);
	*value = data;
	return data;
}

/* ARM920T Cache Operation, P44
 * */
void
arm920t_mmu_cache_ops (ARMul_State * state, ARMword instr, ARMword value)
{
	int CRm, OPC_2;

	CRm = BITS (0, 3);
	OPC_2 = BITS (5, 7);

	if (OPC_2 == 0 && CRm == 7) {
		mmu_cache_invalidate_all (state, ARM920T_I_CACHE ());
		mmu_cache_invalidate_all (state, ARM920T_D_CACHE ());
		return;
	}

	if (OPC_2 == 0 && CRm == 5) {
		mmu_cache_invalidate_all (state, ARM920T_I_CACHE ());
		return;
	}
	/*Invalidate ICache single entry
	 **/
	if (OPC_2 == 1 && CRm == 5) {
		mmu_cache_invalidate (state, ARM920T_I_CACHE (), value);
		return;
	}
	/* FIXME: should complete
	 * Prefetch ICache line (using MVA)
	 * */
	if (OPC_2 == 1 && CRm == 13) {
		//mmu_cache_invalidate(state, ARM920T_I_CACHE(), value);
		return;
	}

	if (OPC_2 == 0 && CRm == 6) {
		mmu_cache_invalidate_all (state, ARM920T_D_CACHE ());
		return;
	}

	/* Invalidate DCache single entry (using MVA)
	 * */
	if (OPC_2 == 1 && CRm == 6) {
		mmu_cache_invalidate (state, ARM920T_D_CACHE (), value);
		return;
	}
	/* Clean DCache single entry (using MVA)
	 * */
	if (OPC_2 == 1 && CRm == 0xa) {
		mmu_cache_clean (state, ARM920T_D_CACHE (), value);
		return;
	}
	/* Clean and Invalidate DCache entry (using MVA)
	 * */
	if (OPC_2 == 1 && CRm == 14) {
		mmu_cache_clean (state, ARM920T_D_CACHE (), value);
		mmu_cache_invalidate (state, ARM920T_D_CACHE (), value);
		return;
	}
	/* Clean DCache single entry (using index)
	 * */
	if (OPC_2 == 2 && CRm == 0xa) {
		mmu_cache_clean_by_index (state, ARM920T_D_CACHE (), value);
		return;
	}
	/* Clean and Invalidate DCache entry (using index)
	 * */
	if (OPC_2 == 2 && CRm == 14) {
		mmu_cache_clean_by_index (state, ARM920T_D_CACHE (), value);
		mmu_cache_invalidate_by_index (state, ARM920T_D_CACHE (),
					       value);
		return;
	}

	/* Drain write buffer
	 * */
	if (OPC_2 == 4 && CRm == 0xa) {
		mmu_wb_drain_all (state, ARM920T_WB ());
		return;
	}
	/* FIXME: how to do a waiting operation?
	 * Wait for a interrupt
	 * */
	if (OPC_2 == 4 && CRm == 0) {
		return;
	}
	err_msg ("Unknow OPC_2 = %x CRm = %x\n", OPC_2, CRm);
}

static void
arm920t_mmu_tlb_ops (ARMul_State * state, ARMword instr, ARMword value)
{
	int CRm, OPC_2;

	CRm = BITS (0, 3);
	OPC_2 = BITS (5, 7);


	if (OPC_2 == 0 && CRm == 0x7) {
		mmu_tlb_invalidate_all (state, ARM920T_I_TLB ());
		mmu_tlb_invalidate_all (state, ARM920T_D_TLB ());
		return;
	}

	if (OPC_2 == 0 && CRm == 0x5) {
		mmu_tlb_invalidate_all (state, ARM920T_I_TLB ());
		return;
	}

	if (OPC_2 == 1 && CRm == 0x5) {
		mmu_tlb_invalidate_entry (state, ARM920T_I_TLB (), value);
		return;
	}

	if (OPC_2 == 0 && CRm == 0x6) {
		mmu_tlb_invalidate_all (state, ARM920T_D_TLB ());
		return;
	}

	if (OPC_2 == 1 && CRm == 0x6) {
		mmu_tlb_invalidate_entry (state, ARM920T_D_TLB (), value);
		return;
	}

	err_msg ("Unknow OPC_2 = %x CRm = %x\n", OPC_2, CRm);
}

static void
arm920t_mmu_cache_lockdown (ARMul_State * state, ARMword instr, ARMword value)
{
	int OPC_2 = BITS (5, 7) & 0x7;
}
static void
arm920t_mmu_tlb_lockdown (ARMul_State * state, ARMword instr, ARMword value)
{
}


static ARMword
arm920t_mmu_mcr (ARMul_State * state, ARMword instr, ARMword value)
{
	mmu_regnum_t creg = BITS (16, 19) & 15;
	int OPC_2 = BITS (5, 7) & 0x7;
	if (!strncmp (state->cpu->cpu_arch_name, "armv4", 5)) {
		switch (creg) {
		case MMU_CONTROL:
//              printf("mmu_mcr wrote CONTROL      ");
			state->mmu.control = (value | 0x78) & 0xFFFFF3FF;
			break;
		case MMU_TRANSLATION_TABLE_BASE:
//              printf("mmu_mcr wrote TTB          ");
			state->mmu.translation_table_base =
				value & 0xFFFFC000;
			break;
		case MMU_DOMAIN_ACCESS_CONTROL:
//              printf("mmu_mcr wrote DACR         ");
			state->mmu.domain_access_control = value;
			break;

		case MMU_FAULT_STATUS:
			if (OPC_2 == 0)
				state->mmu.fault_status = value & 0xFF;
			break;
		case MMU_FAULT_ADDRESS:
			state->mmu.fault_address = value;
			break;

		case MMU_CACHE_OPS:
			arm920t_mmu_cache_ops (state, instr, value);
			break;
		case MMU_TLB_OPS:
			arm920t_mmu_tlb_ops (state, instr, value);
			break;
		case MMU_CACHE_LOCKDOWN:
			/* 
			 * FIXME: cache lock down*/
			break;
		case MMU_TLB_LOCKDOWN:
			/* FIXME:tlb lock down */
			break;
		case MMU_PID:
			/*0:24 should be zero. */
			state->mmu.process_id = value & 0xfe000000;
			break;

		default:
			printf ("mmu_mcr wrote UNKNOWN - reg %d\n", creg);
			break;
		}
	}
}

//teawater add for arm2x86 2005.06.19-------------------------------------------
static int
arm920t_mmu_v2p_dbct (ARMul_State * state, ARMword virt_addr,
		      ARMword * phys_addr)
{
	fault_t fault;
	tlb_entry_t *tlb;

	virt_addr = mmu_pid_va_map (virt_addr);
	if (MMU_Enabled) {

		/*align check */
		if ((virt_addr & (WORD_SIZE - 1)) && MMU_Aligned) {
			d_msg ("align\n");
			return ALIGNMENT_FAULT;
		}
		else
			virt_addr &= ~(WORD_SIZE - 1);

		/*translate tlb */
		fault = translate (state, virt_addr, ARM920T_I_TLB (), &tlb);
		if (fault) {
			d_msg ("translate\n");
			return fault;
		}

		/*check access */
		fault = check_access (state, virt_addr, tlb, 1);
		if (fault) {
			d_msg ("check_fault\n");
			return fault;
		}
	}

	if (MMU_Disabled) {
		*phys_addr = virt_addr;
	}
	else {
		*phys_addr = tlb_va_to_pa (tlb, virt_addr);
	}

	return (0);
}

//AJ2D--------------------------------------------------------------------------

/*arm920t mmu_ops_t*/
mmu_ops_t arm920t_mmu_ops = {
	arm920t_mmu_init,
	arm920t_mmu_exit,
	arm920t_mmu_read_byte,
	arm920t_mmu_write_byte,
	arm920t_mmu_read_halfword,
	arm920t_mmu_write_halfword,
	arm920t_mmu_read_word,
	arm920t_mmu_write_word,
	arm920t_mmu_load_instr,
	arm920t_mmu_mcr,
	arm920t_mmu_mrc,
//teawater add for arm2x86 2005.06.19-------------------------------------------
	arm920t_mmu_v2p_dbct,
//AJ2D--------------------------------------------------------------------------
};
