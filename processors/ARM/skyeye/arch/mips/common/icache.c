#include "emul.h"

// Reset the L1 instruction cache.
void
reset_icache(MIPS_State* mstate)
{
	int i, j;
    	for (i = 0; i < Icache_sets; ++i) {
		for (j = 0; j < Icache_assoc; ++j)
	    		mstate->icache.set[i].line[j].tag = bad_tag;
		Icache_lru_init(mstate->icache.set[i].Icache_lru);
    	}
    	mstate->ibuf[0].tag = bad_ibuf_tag;
    	mstate->ibuf[1].tag = bad_ibuf_tag;
}


// Perform a cache operation (for use by decode_cache()).
void
control_icache(MIPS_State* mstate, VA va, PA pa, int op, int type)
{
    	if (type)
		return; // secondary cache not presents

    	switch (op) {
    		case 0:
    		{
			mstate->icache.set[Icache_index(va)].line[Icache_block(va)].tag = bad_tag;
			break;
    		}
    		case 1:
    		{
			break;
    		}
    		case 2:
    		{
			break;
    		}
		case 4:
    		{
			UInt32 tag = mstate->icache.set[Icache_index(va)].line[Icache_block(va)].tag;
			if (tag == Icache_tag(pa))
		    		mstate->icache.set[Icache_index(va)].line[Icache_block(va)].tag = bad_tag;
			break;
    		}
		case 5:
    		{
			UInt32 tag = (UInt32) Icache_tag(pa);
			MIPSICacheSet* set=&mstate->icache.set[Icache_index(va)];
			MIPSICacheLine *line=&set->line[Icache_block(va)];
			const VA line_mask = Icache_line_size - 1;

			int j;
			for(j = 0; j < 4; j++)
			    	mips_mem_read((pa & ~line_mask)+8*j , line->data+j, 8);
	
			break;
    		}
		case 6:
			// Hit Writeback.
			break; // secondary cache not present
	    	case 7:
			// Hit Set Virtual.
			break; // secondary cache not present
	    	default:
			// Everything else is ignored.
			break;
    	}

    	// In all cases, invalidate the ibufs.
    	mstate->ibuf[0].tag  = bad_ibuf_tag;
    	mstate->ibuf[1].tag  = bad_ibuf_tag;
}


/* Fetch an instruction from the virtual address (va). The address translation
 * has already been performed and the physical address is (pa). The coherency
 * algorithm to use is encoded in high-order bits of (pa) using the same
 * encoding as that of the xkphys address space region.
 */

// WARNING: currently, the memory access latencies are not simulated.

Instr 
fetch(MIPS_State* mstate, VA va, PA pa)
{  
    	int i;

    	int ca = coherency_algorithm(pa);

    	if (ca == 0x5) { //Shi yang 2006-08-15
		// A direct memory access.
		UInt32 x;
		mips_mem_read(pa, &x, 4);
		return x;
    	}

    	// A cached memory access.
	UInt32 index = Icache_index(pa);
	UInt32 tag = Icache_tag(pa);
	MIPSICacheSet* set = &(mstate->icache.set[index]);
	MIPSICacheLine* line = &(set->line[0]);
	const PA line_mask = Icache_line_size - 1;

    	// Find the correct entry in the set (if any).
    	for (i = 0; i < Icache_assoc; ++i, ++line) {

		if (line->tag == tag) {
	 		Icache_lru_touch(set->Icache_lru,i);
	    		goto cache_hit;
		}
    	}
    
    	// Otherwise, we've got a cache miss.
    	i = Icache_lru_replace(mstate->icache.set[index].Icache_lru);
    	line = &(mstate->icache.set[index].line[i]);

    	// Fill the cache line from the main memory.
	int j;
	for (j = 0; j < 4; j++)
    		mips_mem_read((pa & ~line_mask) + 8 * j, line->data + j, 8);
    	line->tag = tag;
     	Icache_lru_touch(set->Icache_lru, i);

cache_hit:
    
    	// Finally, fetch the data from the cache.
    	mstate->ibuf[mstate->lru_ibuf].tag = pa >> log2_icache_line;
    	mstate->ibuf[mstate->lru_ibuf].line = line->data;
    	mstate->lru_ibuf = !mstate->lru_ibuf;
    	return swizzle_word(line->data[(pa & line_mask) / 8], va);
}
