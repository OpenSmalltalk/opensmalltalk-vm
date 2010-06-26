#include "skyeye_config.h"
#include "mipsdef.h"
#include "emul.h"

mips_mem_state_t mips_mem;
mips_mem_bank_t *mips_global_mbp;

//This is the memory banks congfigure variable
extern mips_mem_config_t mips_mem_config;
extern MIPS_State* mstate;

extern FILE * skyeye_logfd;

void mips_mem_reset ()
{
	int i, num, bank;
	FILE *f;
	unsigned char *p;
	long s;
	UInt32 swap;
	mips_mem_config_t *mc = &mips_mem_config;
	mips_mem_bank_t *mb = mc->mem_banks;

	num = mc->current_num;
	for (i = 0; i < num; i++) {
		bank = i;
		if (mips_mem.rom[bank])
			free (mips_mem.rom[bank]);
		//chy 2003-09-21: if mem type =MEMTYPE_IO, we need not malloc space for it.
		mips_mem.rom_size[bank] = mb[bank].len;
		if (mb[bank].type != MEMTYPE_IO) {
			mips_mem.rom[bank] = malloc (mb[bank].len);
			if (!mips_mem.rom[bank]) {
				fprintf (stderr,
					 "SKYEYE: mem_reset: Error allocating mem for bank number %d.\n",
					 bank);
				exit (-1);
			}
				
			if (mb[bank].filename
			    && (f = fopen (mb[bank].filename, "r"))) {
				if (fread
				    (mips_mem.rom[bank], 1, mb[bank].len,
				     f) <= 0) {
					perror ("fread");
					fprintf (stderr,
						 "Failed to load '%s'\n",
						 mb[bank].filename);
					skyeye_exit (-1);
				}
				fclose (f);

				p = (char *) mips_mem.rom[bank];
				s = 0;
				while (s < mips_mem.rom_size[bank]) {
					if (mstate->bigendSig == 1)	/*big enddian? */
						swap = ((UInt32) p[3]) |
							(((UInt32) p[2]) <<
							 8) | (((UInt32)
								p[1]) << 16) |
							(((UInt32) p[0]) <<
							 24);
					else
						swap = ((UInt32) p[0]) |
							(((UInt32) p[1]) <<
							 8) | (((UInt32)
								p[2]) << 16) |
							(((UInt32) p[3]) <<
							 24);
					*(UInt32 *) p = swap;
					p += 4;
					s += 4;
				}

				/*ywc 2004-03-30 */
				if (mb[bank].type == MEMTYPE_FLASH) {
					printf ("Loaded FLASH %s\n",
						mb[bank].filename);
				}
				else if (mb[bank].type == MEMTYPE_RAM) {
					printf ("Loaded RAM   %s\n",
						mb[bank].filename);
				}
				else if (mb[bank].type == MEMTYPE_ROM) {
					printf ("Loaded ROM   %s\n",
						mb[bank].filename);
				}

			}
			else if (mb[bank].filename[0] != '\0') {
				perror (mb[bank].filename);
				fprintf (stderr,
					 "bank %d, Couldn't open boot ROM %s - execution will "
					 "commence with the debuger.\n", bank,
					 mb[bank].filename);
				skyeye_exit (-1);
			}
		}
	}			/*end  for(i = 0;i < num; i++) */

}


// the address used here is the physical address  
UInt32 
mips_real_read_byte (UInt32 addr)
{
	UInt32 data;
	UInt32 offset;

	// the data is stored in the rom place in bunk(mips_global_mbp - mips_mem_config->mem_banks),
	data = mips_mem.rom[mips_global_mbp -
			      mips_mem_config.mem_banks][(addr -
			      mips_global_mbp->addr) >> 2];

	offset = (((UInt32) mstate->bigendSig * 3) ^ (addr & 3)) << 3; //Shi yang 2006-08-18

	return (data >> offset) & 0xffL;
}

UInt32 
mips_real_read_halfword (UInt32 addr)
{
	UInt32 data;
	UInt32 offset;

	// the data is stored  in the rom place in bunk(mips_global_mbp - mips_mem_config->mem_banks),
	data = mips_mem.rom[mips_global_mbp -
			      mips_mem_config.mem_banks][(addr -
							   mips_global_mbp->
							   addr) >> 2];

	offset = (((UInt32) mstate->bigendSig * 2) ^ (addr & 2)) << 3; //Shi yang 2006-08-18
	
	return ((data >> offset) & 0xffff);
}

UInt32
mips_real_read_word (UInt32 addr)
{
	UInt32 data;
	UInt32 offset;
	data = mips_mem.rom[(mips_global_mbp -
			      mips_mem_config.mem_banks)][(addr -
							   mips_global_mbp->
							   addr) >> 2];
//    fprintf(skyeye_logfd,"after real_read_word addr=0x%x,pc=0x%x, data=0x%x\n", addr, mstate->pc, mips_mem.rom[0][(0x3c5ed8 >> 2)]);

	return data;
}


UInt64
mips_real_read_doubleword (UInt32 addr)
{
	UInt64 data;
	
	data = mips_mem.rom[mips_global_mbp -
			      mips_mem_config.mem_banks][(addr -
							   mips_global_mbp->
							   addr) >> 3];
	return data ;
}


void
mips_real_write_byte (UInt32 addr, UInt32 data)
{
	UInt32 *temp;
	UInt32 offset;
	temp = &(mips_mem.rom[mips_global_mbp -
			       mips_mem_config.mem_banks][(addr -
			    mips_global_mbp->addr) >> 2]);
	
	offset = (((UInt32) mstate->bigendSig * 3) ^ (addr & 3)) << 3; //Shi yang 2006-08-18
	
	*temp = (*temp & ~(0xffL << offset)) | ((data & 0xffL) << offset);

}

void
mips_real_write_halfword ( UInt32 addr, UInt32 data)
{
	UInt32 *temp;
	UInt32 offset;
	
	temp = &(mips_mem.rom[mips_global_mbp -
			       mips_mem_config.mem_banks][(addr -
							    mips_global_mbp->
							    addr) >> 2]);

	offset = (((UInt32) mstate->bigendSig * 2) ^ (addr & 2)) << 3; //Shi yang 2006-08-18

	*temp = (*temp & ~(0xffffL << offset)) | ((data & 0xffffL) << offset);
}


void
mips_real_write_word (UInt32 addr, UInt32 data)
{

	UInt32 *temp;
	//fprintf(skyeye_logfd,"before addr=0x%x,pc=0x%x,data=0x%x\n", addr, mstate->pc, mips_mem.rom[0][(0x3c5ed8 >> 2)]);	
	temp = &(mips_mem.rom[mips_global_mbp -
			       mips_mem_config.mem_banks]
				[(addr - mips_global_mbp->addr) >> 2]);
	*temp = data;
	//fprintf(skyeye_logfd,"after addr=0x%x,pc=0x%x, data=0x%x\n", addr, mstate->pc, mips_mem.rom[0][(0x3c5ed8 >> 2)]);

}

void
mips_real_write_doubleword ( UInt32 addr, UInt64 data)
{
	 mips_mem.rom[mips_global_mbp -
		       mips_mem_config.mem_banks][(addr -
						    mips_global_mbp->addr) >> 3] =data;
}

//Flash address space
UInt32
mips_flash_read_byte (UInt32 addr)
{
	return mips_real_read_byte(addr);
}

UInt32
mips_flash_read_halfword (UInt32 addr)
{
	return mips_real_read_halfword(addr);
}

UInt32
mips_flash_read_word (UInt32 addr)
{
	return mips_real_read_word(addr);
}

UInt64
mips_flash_read_doubleword (UInt32 addr)
{
	return mips_real_read_doubleword(addr);
}

void
mips_flash_write_byte (UInt32 addr, UInt32 data)
{
	mips_real_write_byte(addr, data);
}

void
mips_flash_write_halfword (UInt32 addr, UInt32 data)
{
	mips_real_write_halfword(addr, data);
}

void
mips_flash_write_word (UInt32 addr, UInt32 data)
{
	mips_real_write_word(addr, data);
}

void
mips_flash_write_doubleword (UInt32 addr, UInt64 data)
{
	mips_real_write_doubleword(addr, data);
}



//these fuctions are used for warning
void
mips_warn_write_byte (UInt32 addr, UInt32 data)
{
	fprintf (stderr,
		 "SKYEYE: WARNING: illegal write byte to 0x%x of 0x%x @ 0x%x\n",
		 addr, data, mstate->pc);
}

void
mips_warn_write_halfword (UInt32 addr, UInt32 data)
{
	fprintf (stderr,
		 "SKYEYE: WARNING: illegal write halfword to 0x%x of 0x%x @ 0x%x\n",
		 addr, data, mstate->pc);
}

void
mips_warn_write_word (UInt32 addr, UInt32 data)
{
	fprintf (stderr,
		 "SKYEYE: WARNING: illegal write word to 0x%x of 0x%x @ 0x%x\n",
		 addr, data, mstate->pc);
}


mips_mem_bank_t*
mips_bank_ptr (UInt32 addr)
{
	// chy 2005-01-06 add teawater's codes for speed,but I tested it, can not find the big improve
	// chy 2005-01-06 maybe some one  examines below. now I commit teatwater's codes
	//mem_bank_t *mbp;
	//---------teawater add for arm2ia32 2004.12.04-----------------
	//mem_bank_t *mbp;

	static mips_mem_bank_t *mbp = NULL;
	if (mbp) {
		if ((mbp->addr <= addr) && ((addr - mbp->addr) < mbp->len))
			return (mbp);
	}
	//printf("mem_bank: 0x%08x\n",mips_mem_config.mem_banks);
	//AJ2D----------------------------------------------------------
	//search for the proper memory bank
	for (mbp = mips_mem_config.mem_banks; mbp->len; mbp++)
		if ((mbp->addr <= addr) && ((addr - mbp->addr) < mbp->len))
			{
			//printf("mbp addr: 0x%08x, mbp len: 0x%08x, addr: 0x%08x\n",mbp->addr, mbp->len, addr);
			return (mbp);
			}
	return (NULL);
}

void 
mips_mem_write_byte (UInt32 phys_addr, UInt32 v)
{	
	//translate the  physical address to the 32 bits 
	UInt32 addr = bits(phys_addr, 31, 0);

	//get the memory bank of the address
	mips_global_mbp = mips_bank_ptr (addr);
	
	if (mips_global_mbp && mips_global_mbp->write_byte) {
		mips_global_mbp->write_byte (addr, v);
	} else {
		fprintf(stderr,"mips memory write error in %s, addr=0x%x,pc=0x%x..\n",__FUNCTION__,addr, mstate->pc);
		skyeye_exit(-1);
	}
}


void 
mips_mem_write_halfword (UInt32 phys_addr, UInt32 v)
{
	UInt32 addr = bits(phys_addr, 31, 0);
	
	mips_global_mbp = mips_bank_ptr (addr);
	if (mips_global_mbp && mips_global_mbp->write_halfword) {
		/*ywc 2005-03-31 */
		/*ywc 2005-04-22 move it to real_write_halfword */
		/*
		   if(!skyeye_config.no_dbct){
		   //teawater add for arm2x86 2005.03.18----------------------------------
		   tb_setdirty(state, addr, mbp);
		   //AJ2D----------------------------------------------------------
		   }
		 */
		//mbp->write_halfword(state, addr, data);
		mips_global_mbp->write_halfword (addr, v);
	} else {
		fprintf(stderr,"mips memory write error in %s..\n",__FUNCTION__);
		skyeye_exit(-1);
	}
}

void 
mips_mem_write_word (UInt32 phys_addr, UInt32 v)
{
	UInt32 addr = bits(phys_addr, 31, 0);
	
	mips_global_mbp = mips_bank_ptr (addr);
	//if (mbp && mbp->write_halfword){
	if (mips_global_mbp && mips_global_mbp->write_word) {
		/*ywc 2005-03-31 */
		/*ywc 2005-04-22 move it to real_write_halfword */
		/*
		   if(!skyeye_config.no_dbct){
		   //teawater add for arm2x86 2005.03.18----------------------------------
		   tb_setdirty(state, addr, mbp);
		   //AJ2D----------------------------------------------------------
		   }
		 */
		//mbp->write_halfword(state, addr, data);
		mips_global_mbp->write_word (addr, v);
	} else {
		fprintf(stderr,"mips memory write error in %s,addr=0x%x, pc=0x%x..\n", __FUNCTION__, addr, mstate->pc);
		exit(-1);
	}
}

void 
mips_mem_write_doubleword (UInt64 phys_addr, UInt64 v)
{
	UInt32 addr = bits(phys_addr, 31, 0);
	
	mips_global_mbp = mips_bank_ptr (addr);
	if (mips_global_mbp && mips_global_mbp->write_doubleword) {
		/*ywc 2005-03-31 */
		/*ywc 2005-04-22 move it to real_write_halfword */
		/*
		   if(!skyeye_config.no_dbct){
		   //teawater add for arm2x86 2005.03.18----------------------------------
		   tb_setdirty(state, addr, mbp);
		   //AJ2D----------------------------------------------------------
		   }
		 */
		//mbp->write_halfword(state, addr, data);
		mips_global_mbp->write_doubleword (addr, v);
	} else {
		fprintf(stderr,"mips memory write error in %s..\n",__FUNCTION__);
		skyeye_exit(-1);
	}
}

UInt32
mips_mem_read_byte (UInt32 phys_addr)
{

	UInt32 addr = bits(phys_addr, 31, 0);
	mips_global_mbp = mips_bank_ptr (addr);
	if (mips_global_mbp && mips_global_mbp->read_byte)
		return mips_global_mbp->read_byte (addr);
	else {
		return 0;
	}
}

UInt32
mips_mem_read_halfword (UInt32 phys_addr)
{

	UInt32 addr = bits(phys_addr,31,0);
	mips_global_mbp = mips_bank_ptr (addr);
	if (mips_global_mbp && mips_global_mbp->read_halfword)
		return mips_global_mbp->read_halfword (addr);
	else {
		return 0;
	}
}

UInt32
mips_mem_read_word (UInt32 phys_addr)
{

	UInt32 addr = bits(phys_addr, 31, 0);
	mips_global_mbp = mips_bank_ptr (addr);
	if (mips_global_mbp && mips_global_mbp->read_word)
		return mips_global_mbp->read_word (addr);
	else {
		return 0;
	}
}

UInt64
mips_mem_read_doubleword (UInt64 phys_addr)
{

	UInt32 addr = bits(phys_addr, 31, 0);
	mips_global_mbp = mips_bank_ptr (addr);
	if (mips_global_mbp && mips_global_mbp->read_doubleword)
		return mips_global_mbp->read_doubleword (addr);
	else {
		return 0;
	}
}

void 
mips_mmu_write_byte (MIPS_State* mstate, UInt32 vir_addr, UInt32 v)
{
	//translate the virtual address  to phsical address
	PA phys_addr ;
	if( translate_vaddr(mstate, (VA)vir_addr, data_store, &phys_addr) == TLB_SUCC)
		mips_mem_write_byte ((UInt32)phys_addr, v);
}

void 
mipsMul_WriteByte (MIPS_State* mstate, UInt32 vir_addr, UInt32 v)
{
	mips_mmu_write_byte (mstate, vir_addr, v);
}

