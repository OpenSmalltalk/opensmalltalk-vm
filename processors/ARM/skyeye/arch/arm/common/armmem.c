/*
    armmem.c - Memory map decoding, ROM and RAM emulation.
    ARMulator extensions for the ARM7100 family.
    Copyright (C) 1999  Ben Williamson

	Changes to support running uClinux/Atmel AT91 targets
    Copyright (C) 2002  David McCullough <davidm@snapgear.com>

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

#include "armdefs.h"
#include "code_cov.h"

/*ywc 2005-03-30*/
#include "skyeye_flash.h"

//chy 2004-03-11
extern void lcd_write (ARMul_State * state, ARMword addr, ARMword data);
#if 0
void
mem_reset (ARMul_State * state)
{
	int i, num, bank;
	FILE *f;
	unsigned char *p;
	int s;
	ARMword swap;
	mem_config_t *mc = state->mem_bank;
	mem_bank_t *mb = mc->mem_banks;

	num = mc->current_num;
	for (i = 0; i < num; i++) {
		bank = i;
		if (state->mem.rom[bank])
			free (state->mem.rom[bank]);
		//chy 2003-09-21: if mem type =MEMTYPE_IO, we need not malloc space for it.
		state->mem.rom_size[bank] = mb[bank].len;
		if (mb[bank].type != MEMTYPE_IO) {
			state->mem.rom[bank] = malloc (mb[bank].len);
			if (!state->mem.rom[bank]) {
				fprintf (stderr,
					 "SKYEYE: mem_reset: Error allocating mem for bank number %d.\n",
					 bank);
				skyeye_exit (-1);
			}
			/*ywc 2005-04-01 */
#ifdef DBCT
			if (!skyeye_config.no_dbct) {
				//teawater add for arm2x86 2004.12.04-------------------------------------------
				if (mb[bank].len % TB_LEN) {
					fprintf (stderr,
						 "SKYEYE: mem_reset: Bank number %d length error.\n",
						 bank);
					skyeye_exit (-1);
				}

				state->mem.tbp[bank] = MAP_FAILED;
				state->mem.tbt[bank] = NULL;

				/*
				   state->mem.tbp[bank] = mmap(NULL, mb[bank].len / sizeof(ARMword) * TB_INSN_LEN_MAX + mb[bank].len / TB_LEN * op_return.len, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
				   if (state->mem.tbp[bank] == MAP_FAILED) {
				   fprintf(stderr, "SKYEYE: mem_reset: Error allocating mem for bank number %d.\n", bank);
				   exit(-1);
				   }
				   state->mem.tbt[bank] = malloc(mb[bank].len/TB_LEN*sizeof(tb_t));
				   if (!state->mem.tbt[bank]) {
				   fprintf(stderr, "SKYEYE: mem_reset: Error allocating mem for bank number %d.\n", bank);
				   exit(-1);
				   }
				   memset(state->mem.tbt[bank], 0, mb[bank].len/TB_LEN*sizeof(tb_t));
				 */
				//AJ2D--------------------------------------------------------------------------
			}
#endif
			if (mb[bank].filename
			    && (f = fopen (mb[bank].filename, "rb"))) {
				if (fread
				    (state->mem.rom[bank], 1, mb[bank].len,
				     f) <= 0) {
					perror ("fread");
					fprintf (stderr,
						 "Failed to load '%s'\n",
						 mb[bank].filename);
					skyeye_exit (-1);
				}
				fclose (f);

				p = (char *) state->mem.rom[bank];
				s = 0;
				while (s < state->mem.rom_size[bank]) {
					if (state->bigendSig == HIGH)	/*big enddian? */
						swap = ((ARMword) p[3]) |
							(((ARMword) p[2]) <<
							 8) | (((ARMword)
								p[1]) << 16) |
							(((ARMword) p[0]) <<
							 24);
					else
						swap = ((ARMword) p[0]) |
							(((ARMword) p[1]) <<
							 8) | (((ARMword)
								p[2]) << 16) |
							(((ARMword) p[3]) <<
							 24);
					*(ARMword *) p = swap;
					p += 4;
					s += 4;
				}

				/*ywc 2004-03-30 */
				//printf("Loaded ROM %s\n", mb[bank].filename);
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

extern ARMul_State *state;
// chy: can improve speed !!!! ????
// ywc 2005-04-22: Yes,teawater's code improve the speed, so I open it again.
mem_bank_t *
bank_ptr (ARMword addr)
{
	// chy 2005-01-06 add teawater's codes for speed,but I tested it, can not find the big improve
	// chy 2005-01-06 maybe some one  examines below. now I commit teatwater's codes
	//mem_bank_t *mbp;
	//---------teawater add for arm2ia32 2004.12.04-----------------
	//mem_bank_t *mbp;
	static mem_bank_t *mbp = NULL;
	if (mbp) {
		if (mbp->addr <= addr && (addr - mbp->addr) < mbp->len)
			return (mbp);
	}
	//AJ2D----------------------------------------------------------
	for (mbp = state->mem_bank->mem_banks; mbp->len; mbp++)
		if (mbp->addr <= addr && (addr - mbp->addr) < mbp->len)
			return (mbp);
	return (NULL);
}

/*ywc 2005-04-22 , called by dbct/tb.c tb_find FUNCTION */
mem_bank_t *
insn_bank_ptr (ARMword addr)
{
	static mem_bank_t *mbp = NULL;
	if (mbp) {
		if (mbp->addr <= addr && (addr - mbp->addr) < mbp->len)
			return (mbp);
	}
	for (mbp = state->mem_bank->mem_banks; mbp->len; mbp++)
		if (mbp->addr <= addr && (addr - mbp->addr) < mbp->len)
			return (mbp);
	return (NULL);
}

/* ywc 2005-04-22, in order to reduce the bank_ptr call times, use a global variable to 
 * store the bank_ptr result in mem_read/write_byte/halfword/word. The coresponding
 * real_read/write_byte/halfword/word just use the result directly, no need to call 
 * bank_ptr again.
 */
mem_bank_t *global_mbp;
ARMword
mem_read_byte (ARMul_State * state, ARMword addr)
{
	/* if addr is remaped to another place */
        if (state->vector_remap_flag && (addr <= 0x0 + state->vector_remap_size)) /* Fixme:we only think the start addr of interrupt vector is 0x0, not think 0xffff0000 */
        {
                addr += state->vector_remap_addr; /* support some remap function in LPC processor */
                printf("KSDBG: remap read addr=0x%x\n", addr);
        }

	global_mbp = bank_ptr (addr);
	if (global_mbp && global_mbp->read_byte)
		//return mbp->read_byte(state, addr);
		return global_mbp->read_byte (state, addr);
	else {
		//fprintf(stderr, "SKYEYE:NumInstrs %llu, mem_read_byte addr = %x no bank\n",state->NumInstrs, addr);
		//chy 2003-09-03
		//SKYEYE_OUTREGS(stderr);
		//exit(-1);
		return 0;
	}
}

ARMword
mem_read_halfword (ARMul_State * state, ARMword addr)
{
	 /* if addr is remaped to another place */
        if (state->vector_remap_flag && (addr <= 0x0 + state->vector_remap_size)) /* Fixme:we only think the start addr of interrupt vector is 0x0, not think 0xffff0000 */
        {
                addr += state->vector_remap_addr; /* support some remap function in LPC processor */
        //        printf("KSDBG: remap read addr=0x%x\n", addr);
        }

	global_mbp = bank_ptr (addr);
	if (global_mbp && global_mbp->read_halfword)
		//return mbp->read_halfword(state, addr);
		return global_mbp->read_halfword (state, addr);
	else {
		//fprintf(stderr, "SKYEYE:NumInstrs %llu, mem_read_halfword addr = %x no bank\n",state->NumInstrs, addr);
		//chy 2003-09-03
		//SKYEYE_OUTREGS(stderr);
		//exit(-1);
		return 0;
	}
}

ARMword
mem_read_word (ARMul_State * state, ARMword addr)
{
	if(skyeye_config.code_cov.prof_on)
		cov_prof(READ_FLAG, addr);

	/* if addr is remaped to another place */
	if (state->vector_remap_flag && (addr <= 0x0 + state->vector_remap_size)) /* Fixme:we only think the start addr of interrupt vector is 0x0, not think 0xffff0000 */
	{
        	addr += state->vector_remap_addr; /* support some remap function in LPC processor */
	}
	global_mbp = bank_ptr (addr);
	//if (mbp && mbp->read_word)
	if (global_mbp && global_mbp->read_word)
		//return mbp->read_word(state, addr);
		return global_mbp->read_word (state, addr);
	else {
		fprintf(stderr, "SKYEYE:Error in %s, no bank found, NumInstrs %llu, mem_read_word addr = %x no bank\n", __FUNCTION__, state->NumInstrs, addr);
		//SKYEYE_OUTREGS(stderr);
		//skyeye_exit(-1);
		return 0;
	}
}

void
mem_write_byte (ARMul_State * state, ARMword addr, ARMword data)
{
	//mem_bank_t *mbp = bank_ptr(addr);
	global_mbp = bank_ptr (addr);
	//if (mbp && mbp->write_byte){
	if (global_mbp && global_mbp->write_byte) {
		/*ywc 2005-03-31 */
		/*ywc 2005-04-22 move it to real_write_byte */
		/*
		   if(!skyeye_config.no_dbct){
		   //teawater add for arm2x86 2005.03.18----------------------------------
		   tb_setdirty(state, addr, mbp);
		   //AJ2D----------------------------------------------------------
		   }
		 */
		global_mbp->write_byte (state, addr, data);
		//mbp->write_byte(state, addr, data);
	}
	else {
		fprintf(stderr, "SKYEYE:NumInstrs %llu, mem_write_byte addr = %x no bank\n",state->NumInstrs, addr);
		//chy 2003-09-03
		//SKYEYE_OUTREGS(stderr);
		skyeye_exit(-1);
	}
}
void
mem_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
{
	//mem_bank_t *mbp = bank_ptr(addr);
	global_mbp = bank_ptr (addr);
	//if (mbp && mbp->write_halfword){
	if (global_mbp && global_mbp->write_halfword) {
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
		global_mbp->write_halfword (state, addr, data);
	}
	else {
		//fprintf(stderr, "SKYEYE:NumInstrs %llu, mem_write_halfword addr = %x no bank\n",state->NumInstrs, addr);
		//chy 2003-09-03
		//SKYEYE_OUTREGS(stderr);
		//exit(-1);
	}
}
void
mem_write_word (ARMul_State * state, ARMword addr, ARMword data)
{

//chy 2003-07-10 chy: lyh change 
//      bank_ptr(addr)->write_word(state, addr, data);
	//mem_bank_t *mbp = bank_ptr(addr);
	if(skyeye_config.code_cov.prof_on)
		cov_prof(WRITE_FLAG, addr);

	global_mbp = bank_ptr (addr);
	//if (mbp && mbp->write_word){
	if (global_mbp && global_mbp->write_word) {
		/*ywc 2005-03-31 */
		/*ywc 2005-04-22 move it to real_write_word */
		/*
		   if(!skyeye_config.no_dbct){
		   //teawater add for arm2x86 2005.03.18----------------------------------
		   tb_setdirty(state, addr, mbp);
		   //AJ2D----------------------------------------------------------
		   }
		 */
		//mbp->write_word(state, addr, data);
		global_mbp->write_word (state, addr, data);
	}
	else {
		//fprintf(stderr, "SKYEYE:NumInstrs %llu, mem_write_word addr = %x no bank\n",state->NumInstrs, addr);
		//chy 2003-09-03
		//SKYEYE_OUTREGS(stderr);
		//exit(-1);
	}
}

/* if you want a wanring about strange accesses put this on the region */

ARMword
warn_read_word (ARMul_State * state, ARMword addr)
{
	fprintf (stderr, "WARNING: illegal read from 0x%x @ 0x%x\n", addr,
		 state->pc);
	return (0xffffffff);
}

void
warn_write_byte (ARMul_State * state, ARMword addr, ARMword data)
{
	fprintf (stderr,
		 "SKYEYE: WARNING: illegal write byte to 0x%x of 0x%x @ 0x%x\n",
		 addr, data, state->pc);
}

void
warn_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
{
	fprintf (stderr,
		 "SKYEYE: WARNING: illegal write halfword to 0x%x of 0x%x @ 0x%x\n",
		 addr, data, state->pc);
}

void
warn_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	fprintf (stderr,
		 "SKYEYE: WARNING: illegal write word to 0x%x of 0x%x @ 0x%x\n",
		 addr, data, state->pc);
}


/* Accesses that map to gaps in the memory map go here: */

ARMword
fail_read_word (ARMul_State * state, ARMword addr)
{
	fprintf (stderr, "illegal read from 0x%x\n", addr);
	ARMul_Debug (state, 0, 0);
	return (0xffffffff);
}

void
fail_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	fprintf (stderr, "illegal write to 0x%x of 0x%x\n", addr, data);
	ARMul_Debug (state, 0, 0);
}



ARMword
_read_word (ARMul_State * state, ARMword addr)
{
	fprintf (stderr, "undefined read from 0x%x\n", addr);
	return (0xffffffff);
}

void
_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	fprintf (stderr, "undefined write to 0x%x of 0x%x\n", addr, data);
}

ARMword
real_read_byte (ARMul_State * state, ARMword addr)
{
	ARMword data, offset;
	/*
	   mem_bank_t *mbp = bank_ptr(addr);

	   if(!mbp)
	   {
	   fprintf(stderr, "real_read_byte. No bank at address 0x%x", addr);
	   return 0;
	   }
	 */
	//data = state->mem.rom[mbp - skyeye_config.mem.mem_banks][(addr - mbp->addr) >> 2];
	data = state->mem.rom[global_mbp -
			      state->mem_bank->mem_banks][(addr -
							   global_mbp->
							   addr) >> 2];

	offset = (((ARMword) state->bigendSig * 3) ^ (addr & 3)) << 3;	/* bit offset into the word */

	return (data >> offset & 0xffL);
}

ARMword
real_read_halfword (ARMul_State * state, ARMword addr)
{
	ARMword data, offset;
	/*
	   mem_bank_t *mbp = bank_ptr(addr);
	   if(!mbp)
	   {
	   fprintf(stderr, "real_read_halfword. No bank at address 0x%x", addr);
	   return 0;
	   }
	 */
	//data = state->mem.rom[mbp - skyeye_config.mem.mem_banks][(addr - mbp->addr) >> 2];
	data = state->mem.rom[global_mbp -
			      state->mem_bank->mem_banks][(addr -
							   global_mbp->
							   addr) >> 2];

	offset = (((ARMword) state->bigendSig * 2) ^ (addr & 2)) << 3;	/* bit offset into the word */

	return (data >> offset) & 0xffff;
}

ARMword
real_read_word (ARMul_State * state, ARMword addr)
{
	ARMword data;
	/*  
	   mem_bank_t *mbp = bank_ptr(addr);
	   if(!mbp)
	   {
	   fprintf(stderr, "real_read_word. No bank at address 0x%x", addr);
	   return 0;
	   }
	 */
	//data = state->mem.rom[mbp - skyeye_config.mem.mem_banks][(addr - mbp->addr) >> 2];
	data = state->mem.rom[global_mbp -
			      state->mem_bank->mem_banks][(addr -
							   global_mbp->
							   addr) >> 2];
	return data;
}

void
real_write_byte (ARMul_State * state, ARMword addr, ARMword data)
{
	ARMword *temp, offset;
	/*
	   mem_bank_t *mbp = bank_ptr(addr);
	   if(!mbp)
	   {
	   fprintf(stderr, "real_write_byte. No bank at address 0x%x", addr);
	   return;
	   }
	 */

	/*ywc 2005-04-22, I move it from mem_write_byte to here */
#ifdef DBCT
	if (!skyeye_config.no_dbct) {
		//teawater add for arm2x86 2005.03.18----------------------------------
		//tb_setdirty(state, addr, mbp);
		tb_setdirty (state, addr, global_mbp);
		//AJ2D----------------------------------------------------------
	}
#endif

	//temp = &state->mem.rom[mbp - skyeye_config.mem.mem_banks][(addr - mbp->addr) >> 2];
	temp = &state->mem.rom[global_mbp -
			       state->mem_bank->mem_banks][(addr -
							    global_mbp->
							    addr) >> 2];
	offset = (((ARMword) state->bigendSig * 3) ^ (addr & 3)) << 3;	/* bit offset into the word */
	//printf(stderr,"SKYEYE real_write_byte 1: temp %x,tempval %x,offset %x, addr %x, data %x\n",temp,*temp,offset,addr,data);

	*temp = (*temp & ~(0xffL << offset)) | ((data & 0xffL) << offset);
	//printf(stderr,"SKYEYE real_write_byte 2: temp %x,tempval %x,offset %x, addr %x, data %x\n",temp,*temp,offset,addr,data);
	//chy 2004-03-11: add lcd test
	//chy 2004-03-17 fix a bug: didn't test skyeye_config.no_lcd
	//chy 2004-09-29 disable blow lines
	/*
	   if((!skyeye_config.no_lcd) && *(state->mach_io.lcd_is_enable) && addr >= *(state->mach_io.lcd_addr_begin) && addr <= *(state->mach_io.lcd_addr_end)){
	   //fprintf(stderr, "SKYEYE,lcd enabled  write byte lcd memory addr %x, data %x\n",addr,*temp);
	   skyeye_config.mach->mach_lcd_write(state,addr,*temp);
	   }
	 */
}

void
real_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
{
	ARMword *temp, offset;
	/*
	   mem_bank_t *mbp = bank_ptr(addr);
	   if (!mbp)
	   {
	   fprintf(stderr, "real_write_halfword error. No bank at address 0x%x.\n", addr);
	   return;
	   }
	 */

	/*ywc 2005-04-22, I move it from mem_write_byte to here */
#ifdef DBCT
	if (!skyeye_config.no_dbct) {
		//teawater add for arm2x86 2005.03.18----------------------------------
		//tb_setdirty(state, addr, mbp);
		tb_setdirty (state, addr, global_mbp);
		//AJ2D----------------------------------------------------------
	}
#endif

	//temp = &state->mem.rom[mbp - skyeye_config.mem.mem_banks][(addr - mbp->addr) >> 2];
	temp = &state->mem.rom[global_mbp -
			       state->mem_bank->mem_banks][(addr -
							    global_mbp->
							    addr) >> 2];
	offset = (((ARMword) state->bigendSig * 2) ^ (addr & 2)) << 3;	/* bit offset into the word */

	*temp = (*temp & ~(0xffffL << offset)) | ((data & 0xffffL) << offset);
	//chy 2004-03-11: add lcd test
	//chy 2004-03-17 fix a bug: didn't test skyeye_config.no_lcd
	//chy 2004-09-29 disable blow lines
	/*
	   if((!skyeye_config.no_lcd) && *(state->mach_io.lcd_is_enable) && addr >= *(state->mach_io.lcd_addr_begin) && addr <= *(state->mach_io.lcd_addr_end)){
	   //fprintf(stderr, "SKYEYE,lcd enabled  write byte lcd memory addr %x, data %x\n",addr,*temp);
	   skyeye_config.mach->mach_lcd_write(state,addr,*temp);
	   }
	 */
}

void
real_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	/*
	   mem_bank_t *mbp = bank_ptr(addr);
	   if(!mbp)
	   {
	   fprintf(stderr, "real_write_word. No bank at address 0x%x", addr);
	   return ;
	   }
	 */

	/*ywc 2005-04-22, I move it from mem_write_byte to here */
#ifdef DBCT
	if (!skyeye_config.no_dbct) {
		//teawater add for arm2x86 2005.03.18----------------------------------
		//tb_setdirty(state, addr, mbp);
		tb_setdirty (state, addr, global_mbp);
		//AJ2D----------------------------------------------------------
	}
#endif

	//state->mem.rom[mbp - skyeye_config.mem.mem_banks][(addr - mbp->addr) >> 2] = data;
	state->mem.rom[global_mbp -
		       state->mem_bank->mem_banks][(addr -
						    global_mbp->addr) >> 2] =
		data;
	//chy 2004-03-11: add lcd test
	//chy 2004-03-17 fix a bug: didn't test skyeye_config.no_lcd
	//chy 2004-09-29 disable blow lines
	/*
	   if((!skyeye_config.no_lcd) && *(state->mach_io.lcd_is_enable) && addr >= *(state->mach_io.lcd_addr_begin) && addr <= *(state->mach_io.lcd_addr_end)){
	   //fprintf(stderr, "SKYEYE,lcd enabled  write byte lcd memory addr %x, data %x\n",addr,*temp);
	   skyeye_config.mach->mach_lcd_write(state,addr,data);
	   }
	 */
}
#endif
