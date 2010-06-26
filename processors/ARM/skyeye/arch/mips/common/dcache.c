#include "emul.h"
#include "stdio.h"

// WARNING: currently, the memory access latencies are not simulated.
// WARNING: currently, the effect of write buffers isn't simulated.

// State information for the data cache.
#define W_FLAG			1
#define CS_First		1
#define	CS_Last			2

// Cache states -- unused on R4600/R4700, but needed for control_dcache().
#define	CS_Invalid 			(0 << CS_First)
#define	CS_Shared  	 		(1 << CS_Last)
#define	CS_CleanExclusive 		(2 << CS_Last)
#define	CS_DirtyExclusive 		(3 << CS_Last)

// Reset the L1 data cache.
void 
reset_dcache(MIPS_State* mstate)
{
	int i, j;
    	for (i = 0; i < Dcache_sets; ++i) {
		for (j = 0; j < Dcache_assoc; ++j) {
	    		mstate->dcache.set[i].line[j].tag = bad_tag;
	    		mstate->dcache.set[i].line[j].state = CS_Invalid;
	    		//dcache.set[i].lru_init();
	    		Dcache_lru_init(mstate->dcache.set[i].Dcache_lru);
		}
    	}
}


// Perform a cache operation (for use by decode_cache()).
void 
control_dcache(MIPS_State* mstate, VA va, PA pa, int op, int type)
{
    	if (type)
		return; // secondary cache not presents

    	switch (op) {
    		case 0:
    		{
			// Index Writeback Invalidate.
			MIPSDCacheSet* set=&mstate->dcache.set[Dcache_index(va)];
			MIPSDCacheLine*line=&set->line[Dcache_block(va)];
	
			if (line->state & W_FLAG) {
				PA pa = (Dcache_index(va) << Dcache_index_first) |
					(line->tag << (Dcache_index_last + 1));
				int j;
				for(j = 0; j < 4; j++)
		    			mips_mem_write(pa+8*j , line->data+j, 8);
	    			line->tag = bad_tag;
				line->state = CS_Invalid;
			}
			break;
    		}
    		case 1:
    		{
			/* Index Load Tag.  This cannot be implemented properly as I don't
			 * store the tag for invalidated entries.
			 */
			break;
    		}
    		case 2:
    		{
			/* Index Store Tag.  The comment from (1) applies. As ``Index Load
			 * Tag'' is not implemented, this may be left as a noop.
			 */
			break;
    		}
    		case 3:
    		{
			// Create Dirty Exclusive.
			UInt32 tag = Dcache_tag(pa);
			MIPSDCacheSet* set= &mstate->dcache.set[Dcache_index(va)];
			MIPSDCacheLine* line=&set->line[Dcache_block(va)];
			if (line->tag != tag && (line->state & W_FLAG)) {
	    			// Write back current data.
				PA pa = (Dcache_index(va) << Dcache_index_first) |(line->tag << (Dcache_index_last + 1));

				int j;
				for(j = 0; j < 4; j++)
				    	mips_mem_write(pa + 8 * j , line->data + j, 8);
			}
			line->tag = tag;
			line->state = CS_DirtyExclusive | (line->state & W_FLAG);
			break;
    		}
    		case 4:
    		{
			// Hit Invalidate.
			UInt32 tag = Dcache_tag(pa);
			MIPSDCacheSet* set = &mstate->dcache.set[Dcache_index(va)];
			MIPSDCacheLine* line=&set->line[Dcache_block(va)];
			if (line->tag != tag && (line->state & W_FLAG)) {
			    // Hit: invalidate the cache.
			    line->tag = bad_tag;
			    line->state = CS_Invalid;
			} else {
			    // Miss: clear the CH bit in status register.
			}
			break;
    		}
	    	case 5:
    		{
			// Hit Writeback Invalidate.
			UInt32 tag = Dcache_tag(pa);
			MIPSDCacheSet* set = &mstate->dcache.set[Dcache_index(va)];
			MIPSDCacheLine* line=&set->line[Dcache_block(va)];
			if (line->tag == tag && (line->state & W_FLAG)) {
				PA pa = (Dcache_index(va) << Dcache_index_first) |(line->tag << (Dcache_index_last + 1));
				int j;
				for (j = 0; j < 4; j++)
				    	mips_mem_write(pa + 8 * j , line->data + j, 8);
	 		}
			line->tag = bad_tag;
			line->state = CS_Invalid;
			break;
    		}
    		case 6:
    		{
			// Hit Writeback.
			UInt32 tag = Dcache_tag(pa);
			MIPSDCacheSet* set = &mstate->dcache.set[Dcache_index(va)];
			MIPSDCacheLine* line=&set->line[Dcache_block(va)];
			if (line->tag == tag && (line->state & W_FLAG)) {
			    	// Write back current data.
				PA pa = (Dcache_index(va) << Dcache_index_first) |
					(line->tag << (Dcache_index_last + 1));
				int j;
				for (j = 0; j < 4; j++)
				    	mips_mem_write(pa+8*j , line->data+j, 8);
	
			}
			line->tag = bad_tag;
			break;
    		} 
    		case 7:
			// Hit Set Virtual.
			break; // secondary cache not present
    	}
}


/* Perform a load from the virtual address (va). The address translation has
 * already been performed and the physical address is (pa). The coherency
 * algorithm to use is encoded in high-order bits of (pa) using the same
 * encoding as that of the xkphys address space region. It is a template
 * explicitely specialized for doubleword, word, halfword and byte, to improve
 * performance of the endianess correction algorithm, as well as minor
 * improvements steming from the fact that bit field extraction on variable
 * boundaries is slow.
 */
#if 0
void 
load(MIPS_State* mstate, VA va, PA pa, UInt32* x, int size)
{

	// to generate the time out interrupt

	UInt32 addr = bits(pa, 31, 0);

	int i;

     	int ca = coherency_algorithm(pa);

    	if (ca == 0x5) { //Shi yang 2006-08-15
		// A direct memory access.
		mips_mem_read(pa, x, size);
		return;
			
    	}

    	// A cached memory access.
    	UInt32 index = Dcache_index(pa); //Shi yang 2006-08-15
    	UInt32 tag = Dcache_tag(pa);
    	MIPSDCacheSet* set = &(mstate->dcache.set[index]); 
    	MIPSDCacheLine* line = &(set->line[0]);
    	const PA line_mask = Dcache_line_size - 1;

    	int j;
    	for (j = 0; j < Dcache_assoc; ++j, ++line) {
		if (line->tag == tag) {
	    		Dcache_lru_touch(set->Dcache_lru,j);
	    		goto cache_hit;
		}
    	}
    
  	i = Dcache_lru_replace(mstate->dcache.set[index].Dcache_lru);
	line = &(mstate->dcache.set[index].line[i]);

	// Shi yang 2006-08-15 R3000's cache is write through cache.
    	for(j = 0; j < 4; j++)
    		mips_mem_read((pa & ~line_mask) + 8 * j , line->data + j, 8);

    	line->tag = tag;

	Dcache_lru_touch(set->Dcache_lru, i);
	
	int offset;
	UInt32 cachelinedata;
	cachelinedata = line->data[(pa & line_mask) / 8];
	
cache_hit:
    
    	/* Finally, fetch the data from the cache.
    	 * return swizzle<syscmd>(line->data[(pa & line_mask) / 8], va);
	 */
	
    	switch (size) {

		case 1:    
		{
			offset = (((UInt32) mstate->bigendSig * 3) ^ (va & 3)) << 3; //Shi yang 2006-08-18
	 		*x = (cachelinedata >> offset) & 0xffL;
			break;
		}
		case 2:    
		{
			offset = (((UInt32)mstate->bigendSig * 2) ^ (va & 2)) << 3; //Shi yang 2006-08-18
			*x = (cachelinedata >> offset) & 0xffffL;	
			break;
		}
		case 4:    
		{
			*x = cachelinedata;
			break;
		}
    	}
}
#endif
void
load(MIPS_State* mstate, VA va, PA pa, UInt32* x, int size)
{

        // to generate the time out interrupt

        UInt32 addr = bits(pa, 31, 0);

        int i;

        // A direct memory access.
        return mips_mem_read(pa, x, size);
}
/* Store data to the virtual address (va). The address translation has already
 * been performed and the physical address is (pa). The coherency algorithm to
 * use is encoded in high-order bits of (pa) using the same encoding as that
 * of the xkphys address space region. It is a template explicitely
 * specialized for doubleword, word, halfword and byte, to improve performance
 * of the endianess correction algorithm, as well as minor improvements
 * steming from the fact that bit field extraction on variable boundaries is
 * slow.
 */
#if 0
void 
store(MIPS_State* mstate, UInt32 data, VA va, PA pa, int size)
{
	UInt32 addr=bits(pa, 31, 0);
   
    	UInt32 x = data;
	
  	int ca = coherency_algorithm(pa);
	
	// Anthony Lee 2007-01-30 : no {} ???
	if (ca == 0x5) //Shi yang uncached area 
		mips_mem_write(pa, &data, size);
		return; //Shi yang 2006-08-28
	

    	// A cached memory access.
    	UInt32 index = Dcache_index(pa); //Shi yang 2006-08-15
    	UInt32 tag = Dcache_tag(pa);
    	MIPSDCacheSet* set = &(mstate->dcache.set[index]); 
    	MIPSDCacheLine* line = &(set->line[0]);
    	const PA line_mask = Dcache_line_size - 1;

    	int j;
    	for (j = 0; j < Dcache_assoc; ++j, ++line) {
		if (line->tag == tag) {
	    		Dcache_lru_touch(set->Dcache_lru, j);
	    		goto cache_hit;
		}
    	}

   	int i; 
  	i = Dcache_lru_replace(mstate->dcache.set[index].Dcache_lru); //Replace cache line
	line = &(mstate->dcache.set[index].line[i]);
	
    	line->tag = tag;

	Dcache_lru_touch(set->Dcache_lru, i);
	
	int offset;
	UInt32* cachelinedata; //Shi yang 2006-08-15
	cachelinedata = &(line->data[(pa & line_mask) / 8]);

cache_hit:
    
    	/* Finally, fetch the data from the cache.
    	 * return swizzle<syscmd>(line->data[(pa & line_mask) / 8], va);
	 */
	
    	switch (size) {

		case 1:    
		{
			offset = (((UInt32) mstate->bigendSig * 3) ^ (va & 3)) << 3; //Shi yang 2006-08-18
			*cachelinedata = clear_bits(*cachelinedata, offset, 0) | (x & 0xffL); //Shi yang 2006-08-15 Write cache line 
			mips_mem_write(pa, &data, size); //Write memory
			break;
		}
		case 2:    
		{
			offset = (((UInt32)mstate->bigendSig * 2) ^ (va & 2)) << 3; //Shi yang 2006-08-18
			*cachelinedata = clear_bits(*cachelinedata, offset, 0) | (x & 0xffffL); 
			mips_mem_write(pa, &data, size);
			break;
		}
		case 4:    
		{
			*x = cachelinedata;
			mips_mem_write(pa, &data, size);
			break;
		}
    	}
}
#endif

/*
 * simple implementation for store function written by michael.kang 
 */

void
store(MIPS_State* mstate, UInt32 data, VA va, PA pa, int size)          {
        UInt32 addr=bits(pa, 31, 0);                                    
        UInt32 x = data;                                                
        return mips_mem_write(pa, &data, size);
}
