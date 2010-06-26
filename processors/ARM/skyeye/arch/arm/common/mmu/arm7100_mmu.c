/*
    armmmu.c - Memory Management Unit emulation.
    ARMulator extensions for the ARM7100 family.
    Copyright (C) 1999  Ben Williamson

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

#ifdef CACHE
#undef CACHE
#endif /*  */

#ifdef TLB
#undef TLB
#endif /*  */

#define	CACHE() (&state->mmu.u.arm7100_mmu.cache_t)
#define TLB() (&state->mmu.u.arm7100_mmu.tlb_t)
static fault_t a71_mmu_read (ARMul_State * state, ARMword virt_addr,
			     ARMword * data, ARMword datatype);
static fault_t a71_mmu_write (ARMul_State * state, ARMword virt_addr,
			      ARMword data, ARMword datatype);
static int
a71_mmu_init (ARMul_State * state)
{
	state->mmu.control = 0x70;
	state->mmu.translation_table_base = 0xDEADC0DE;
	state->mmu.domain_access_control = 0xDEADC0DE;
	state->mmu.fault_status = 0;
	state->mmu.fault_address = 0;
	if (mmu_cache_init (CACHE (), 16, 4, 128, CACHE_WRITE_THROUGH)) {
		err_msg ("cache init %d\n", -1);
		goto cache_error;
	}
	if (mmu_tlb_init (TLB (), 64)) {
		err_msg ("tlb init %d\n", -1);
		goto tlb_error;
	};
	return 0;
      tlb_error:mmu_cache_exit (CACHE ());
      cache_error:return -1;
}
static void
a71_mmu_exit (ARMul_State * state)
{
	mmu_cache_exit (CACHE ());
	mmu_tlb_exit (TLB ());
} static fault_t

a71_mmu_read_byte (ARMul_State * state, ARMword virt_addr, ARMword * data)
{

	//ARMword temp,offset;
	fault_t fault;
	fault = a71_mmu_read (state, virt_addr, data, ARM_BYTE_TYPE);
	return fault;
}

static fault_t
a71_mmu_read_halfword (ARMul_State * state, ARMword virt_addr, ARMword * data)
{

	//ARMword temp,offset;
	fault_t fault;
	fault = a71_mmu_read (state, virt_addr, data, ARM_HALFWORD_TYPE);
	return fault;
}

static fault_t
a71_mmu_read_word (ARMul_State * state, ARMword virt_addr, ARMword * data)
{
	return a71_mmu_read (state, virt_addr, data, ARM_WORD_TYPE);
}

static fault_t
a71_mmu_read (ARMul_State * state, ARMword virt_addr, ARMword * data,
	      ARMword datatype)
{
	tlb_entry_t *tlb;
	ARMword phys_addr;
	ARMword temp, offset;
	fault_t fault;
	if (!(state->mmu.control & CONTROL_MMU)) {

//              *data = mem_read_word(state, virt_addr);
//#if 0
		if (datatype == ARM_BYTE_TYPE)
			bus_read (8, virt_addr, data);

		else if (datatype == ARM_HALFWORD_TYPE)
			bus_read (16, virt_addr, data);

		else if (datatype == ARM_WORD_TYPE)
			bus_read (32, virt_addr, data);

		else {
			printf ("SKYEYE:1 a71_mmu_read error: unknown data type %d\n", datatype);
			skyeye_exit (-1);
		}

//#endif
		return NO_FAULT;
	}

#if 0
/* XXX */
	if (hack && (virt_addr >= 0xc0000000) && (virt_addr < 0xc0200000)) {
		printf ("0x%08x\n", virt_addr);
	}

#endif /*  */
	if ((virt_addr & 3) && (datatype == ARM_WORD_TYPE)
	    && (state->mmu.control & CONTROL_ALIGN_FAULT) || (virt_addr & 1)
	    && (datatype == ARM_HALFWORD_TYPE)
	    && (state->mmu.control & CONTROL_ALIGN_FAULT)) {
		fprintf (stderr, "SKYEYE, a71_mmu_read ALIGNMENT_FAULT\n");
		return ALIGNMENT_FAULT;
	}
	if (state->mmu.control & CONTROL_CACHE) {
		cache_line_t *cache;
		cache = mmu_cache_search (state, CACHE (), virt_addr);
		if (cache) {
			if (datatype == ARM_WORD_TYPE)
				*data = cache->data[(virt_addr >> 2) & 3];

			else if (datatype == ARM_HALFWORD_TYPE) {
				temp = cache->data[(virt_addr >> 2) & 3];
				offset = (((ARMword) state->bigendSig * 2) ^ (virt_addr & 2)) << 3;	/* bit offset into the word */
				*data = (temp >> offset) & 0xffff;
			}
			else if (datatype == ARM_BYTE_TYPE) {
				temp = cache->data[(virt_addr >> 2) & 3];
				offset = (((ARMword) state->bigendSig * 3) ^ (virt_addr & 3)) << 3;	/* bit offset into the word */
				*data = (temp >> offset & 0xffL);
			}
			return NO_FAULT;
		}
	}
	fault = translate (state, virt_addr, TLB (), &tlb);
	if (fault) {
		return fault;
	}
	fault = check_access (state, virt_addr, tlb, 1);
	if (fault) {
		return fault;
	}
	phys_addr = (tlb->phys_addr & tlb_masks[tlb->mapping]) |
		(virt_addr & ~tlb_masks[tlb->mapping]);

	/* allocate to the cache if cacheable */
	if ((tlb->perms & 0x08) && (state->mmu.control & CONTROL_CACHE)) {
		cache_line_t *cache;
		ARMword fetch;
		int i;
		cache = mmu_cache_alloc (state, CACHE (), virt_addr, 0);
		fetch = phys_addr & 0xFFFFFFF0;
		for (i = 0; i < 4; i++) {
			//cache->data[i] = mem_read_word (state, fetch);
			bus_read(32, fetch, &cache->data[i]);
			fetch += 4;
		}
		cache->tag =
			va_cache_align (virt_addr, CACHE ()) | TAG_VALID_FLAG;

		//*data = cache->data[(virt_addr >> 2) & 3];
		if (datatype == ARM_WORD_TYPE)
			*data = cache->data[(virt_addr >> 2) & 3];

		else if (datatype == ARM_HALFWORD_TYPE) {
			temp = cache->data[(virt_addr >> 2) & 3];
			offset = (((ARMword) state->bigendSig * 2) ^ (virt_addr & 2)) << 3;	/* bit offset into the word */
			*data = (temp >> offset) & 0xffff;
		}
		else if (datatype == ARM_BYTE_TYPE) {
			temp = cache->data[(virt_addr >> 2) & 3];
			offset = (((ARMword) state->bigendSig * 3) ^ (virt_addr & 3)) << 3;	/* bit offset into the word */
			*data = (temp >> offset & 0xffL);
		}
		return NO_FAULT;
	}
	else {
		if (datatype == ARM_BYTE_TYPE)
			//*data = mem_read_byte (state, phys_addr);
			bus_read(8, phys_addr, data);
		else if (datatype == ARM_HALFWORD_TYPE)
			//*data = mem_read_halfword (state, phys_addr);
			bus_read(16, phys_addr, data);
		else if (datatype == ARM_WORD_TYPE)
			//*data = mem_read_word (state, phys_addr);
			bus_read(32, phys_addr, data);
		else {
			printf ("SKYEYE:2 a71_mmu_read error: unknown data type %d\n", datatype);
			skyeye_exit (-1);
		}
		return NO_FAULT;
	}
}
static fault_t
a71_mmu_write_byte (ARMul_State * state, ARMword virt_addr, ARMword data)
{
	return a71_mmu_write (state, virt_addr, data, ARM_BYTE_TYPE);
}

static fault_t
a71_mmu_write_halfword (ARMul_State * state, ARMword virt_addr, ARMword data)
{
	return a71_mmu_write (state, virt_addr, data, ARM_HALFWORD_TYPE);
}

static fault_t
a71_mmu_write_word (ARMul_State * state, ARMword virt_addr, ARMword data)
{
	return a71_mmu_write (state, virt_addr, data, ARM_WORD_TYPE);
}

static fault_t
a71_mmu_write (ARMul_State * state, ARMword virt_addr, ARMword data,
	       ARMword datatype)
{
	tlb_entry_t *tlb;
	ARMword phys_addr;
	fault_t fault;
	ARMword temp, offset;
	if (!(state->mmu.control & CONTROL_MMU)) {
		if (datatype == ARM_BYTE_TYPE)
			bus_write (8, virt_addr, data);

		else if (datatype == ARM_HALFWORD_TYPE)
			bus_write (16, virt_addr, data);

		else if (datatype == ARM_WORD_TYPE)
			bus_write (32, virt_addr, data);

		else {
			printf ("SKYEYE:1 a71_mmu_write error: unknown data type %d\n", datatype);
			skyeye_exit (-1);
		}
		return NO_FAULT;
	}

//      if ((virt_addr & 3) && (state->mmu.control & CONTROL_ALIGN_FAULT)) {
	if ((virt_addr & 3) && (datatype == ARM_WORD_TYPE)
	    && (state->mmu.control & CONTROL_ALIGN_FAULT) || (virt_addr & 1)
	    && (datatype == ARM_HALFWORD_TYPE)
	    && (state->mmu.control & CONTROL_ALIGN_FAULT)) {
		fprintf (stderr, "SKYEYE, a71_mmu_write ALIGNMENT_FAULT\n");
		return ALIGNMENT_FAULT;
	}
	if (state->mmu.control & CONTROL_CACHE) {
		cache_line_t *cache;
		cache = mmu_cache_search (state, CACHE (), virt_addr);
		if (cache) {
			if (datatype == ARM_WORD_TYPE)
				cache->data[(virt_addr >> 2) & 3] = data;

			else if (datatype == ARM_HALFWORD_TYPE) {
				temp = cache->data[(virt_addr >> 2) & 3];
				offset = (((ARMword) state->bigendSig * 2) ^ (virt_addr & 2)) << 3;	/* bit offset into the word */
				cache->data[(virt_addr >> 2) & 3] =
					(temp & ~(0xffffL << offset)) |
					((data & 0xffffL) << offset);
			}
			else if (datatype == ARM_BYTE_TYPE) {
				temp = cache->data[(virt_addr >> 2) & 3];
				offset = (((ARMword) state->bigendSig * 3) ^ (virt_addr & 3)) << 3;	/* bit offset into the word */
				cache->data[(virt_addr >> 2) & 3] =
					(temp & ~(0xffL << offset)) |
					((data & 0xffL) << offset);
			}
		}
	}
	fault = translate (state, virt_addr, TLB (), &tlb);
	if (fault) {
		return fault;
	}
	fault = check_access (state, virt_addr, tlb, 0);
	if (fault) {
		return fault;
	}
	phys_addr = (tlb->phys_addr & tlb_masks[tlb->mapping]) |
		(virt_addr & ~tlb_masks[tlb->mapping]);
	if (datatype == ARM_BYTE_TYPE)
		bus_write (8, phys_addr, data);

	else if (datatype == ARM_HALFWORD_TYPE)
		bus_write (16, phys_addr, data);

	else if (datatype == ARM_WORD_TYPE)
		bus_write (32, phys_addr, data);

	else {
		printf ("SKYEYE:2  a71_mmu_write error: unknown data type %d \n", datatype);
		skyeye_exit (-1);
	}
	return NO_FAULT;
}

static ARMword
a71_mmu_mrc (ARMul_State * state, ARMword instr, ARMword * value)
{
	mmu_regnum_t creg = BITS (16, 19) & 15;
	ARMword data;
	switch (creg) {
	case MMU_ID:

//              printf("mmu_mrc read ID     ");
#if 0
#ifdef MMU_V4
		data = 0x41018100;	/* v4 */

#else /*  */
		data = 0x41007100;	/* v3 */

#endif /*  */
#endif /*  */
		//data = 0x41007100; 
		data = state->cpu->cpu_val;
		break;
	case MMU_CONTROL:

//              printf("mmu_mrc read CONTROL");
		data = state->mmu.control;
		break;
	case MMU_TRANSLATION_TABLE_BASE:

//              printf("mmu_mrc read TTB    ");
		data = state->mmu.translation_table_base;
		break;
	case MMU_DOMAIN_ACCESS_CONTROL:

//              printf("mmu_mrc read DACR   ");
		data = state->mmu.domain_access_control;
		break;
	case MMU_FAULT_STATUS:

//              printf("mmu_mrc read FSR    ");
		data = state->mmu.fault_status;
		break;
	case MMU_FAULT_ADDRESS:

//              printf("mmu_mrc read FAR    ");
		data = state->mmu.fault_address;
		break;
	default:
		printf ("mmu_mrc read UNKNOWN - reg %d\n", creg);
		data = 0;
		break;
	}

//      printf("\t\t\t\t\tpc = 0x%08x\n", state->Reg[15]);
	*value = data;
	return data;
}
static void
a71_mmu_mcr (ARMul_State * state, ARMword instr, ARMword value)
{
	mmu_regnum_t creg = BITS (16, 19) & 15;
	if (!strncmp (state->cpu->cpu_arch_name, "armv4", 5))
	{
		switch (creg) {
		case MMU_CONTROL:

//              printf("mmu_mcr wrote CONTROL      ");
			state->mmu.control = (value | 0x70) & 0xFFFF;
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

//#ifdef MMU_V4
		case MMU_FAULT_STATUS:
			state->mmu.fault_status = value & 0xFF;
			break;
		case MMU_FAULT_ADDRESS:
			state->mmu.fault_address = value;
			break;
		case MMU_V4_CACHE_OPS:	/* incomplete */
			if ((BITS (5, 7) & 7) == 0) {
				mmu_cache_invalidate_all (state, CACHE ());
			}
			break;
		case MMU_V4_TLB_OPS:	/* incomplete */
			switch (BITS (5, 7) & 7) {
			case 0:
				mmu_tlb_invalidate_all (state, TLB ());
				break;
			case 1:
				mmu_tlb_invalidate_entry (state, TLB (),
							  value);
				break;
			}
			break;
		default:
			printf ("mmu_mcr wrote UNKNOWN - reg %d\n", creg);
			break;
		}

//#else
	}
	else {
		switch (creg) {
		case MMU_CONTROL:
			state->mmu.control = (value | 0x70) & 0xFFFF;
			break;
		case MMU_TRANSLATION_TABLE_BASE:
			state->mmu.translation_table_base =
				value & 0xFFFFC000;
			break;
		case MMU_DOMAIN_ACCESS_CONTROL:
			state->mmu.domain_access_control = value;
			break;
		case MMU_V3_FLUSH_TLB:

//              printf("mmu_mcr wrote FLUSH_TLB    ");
			mmu_tlb_invalidate_all (state, TLB ());
			break;
		case MMU_V3_FLUSH_TLB_ENTRY:

//              printf("mmu_mcr wrote FLUSH_TLB_ENTRY");
			mmu_tlb_invalidate_entry (state, TLB (), value);
			break;
		case MMU_V3_FLUSH_CACHE:

//              printf("mmu_mcr wrote FLUSH_CACHE    ");
			mmu_cache_invalidate_all (state, CACHE ());
			break;
		default:
			printf ("mmu_mcr wrote UNKNOWN - reg %d\n", creg);
			break;

//#endif
		}
	}

//      printf("\t\t\t\tpc = 0x%08x\n", state->Reg[15]);
}
static int
a71_mmu_v2p_dbct (ARMul_State * state, ARMword virt_addr, ARMword * phys_addr)
{
	tlb_entry_t *tlb;
	ARMword temp, offset;
	fault_t fault;
	ARMword datatype = ARM_WORD_TYPE;
	int ret = -1;
	if ((virt_addr & 3) && (datatype == ARM_WORD_TYPE)
	    && (state->mmu.control & CONTROL_ALIGN_FAULT) || (virt_addr & 1)
	    && (datatype == ARM_HALFWORD_TYPE)
	    && (state->mmu.control & CONTROL_ALIGN_FAULT)) {
		fprintf (stderr, "SKYEYE, a71_mmu_read ALIGNMENT_FAULT\n");
		goto out;
	}
	if (!(state->mmu.control & CONTROL_MMU)) {
		*phys_addr = virt_addr;
	}
	else {
		fault = translate (state, virt_addr, TLB (), &tlb);
		if (fault) {
			goto out;
		}
		fault = check_access (state, virt_addr, tlb, 1);
		if (fault) {
			goto out;
		}
		*phys_addr = (tlb->phys_addr & tlb_masks[tlb->mapping]) |
			(virt_addr & ~tlb_masks[tlb->mapping]);
	}
	ret = 0;
      out:return (ret);
}


#undef CACHE
#undef TLB
mmu_ops_t arm7100_mmu_ops = {
	a71_mmu_init, a71_mmu_exit, a71_mmu_read_byte, a71_mmu_write_byte, a71_mmu_read_halfword, a71_mmu_write_halfword, a71_mmu_read_word, a71_mmu_write_word, a71_mmu_read_word,	// load instr
	a71_mmu_mcr, a71_mmu_mrc, a71_mmu_v2p_dbct	// ywc 2005-04-16 test
};
