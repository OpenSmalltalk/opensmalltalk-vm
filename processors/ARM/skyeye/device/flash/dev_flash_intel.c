/*
        dev_flash_intel.c - skyeye intel flash simulation
        Copyright (C) 2003 - 2005 Skyeye Develop Group
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

/*
 * 09/22/2005   rewrite for new framework
 * 		walimis	
 *
 *  ywc 2005-01-21 add for flash simulation
 *  core flash simulation source code from ipaqsim
 *  Thanks to ipaqsim's AUTHOR(s):     Ye Wen (wenye@cs.ucsb.edu) 
*/

#include <stdio.h>

#include "armdefs.h"
#include "armmem.h"

#include "dev_flash_intel.h"

//chy 2006-08-12 
//extern mem_bank_t *global_mbp;
//extern mem_bank_t * bank_ptr (ARMword addr);
/*ywc 2005-04-01*/
void init_querytable ();

static u32 query[INTEL_QUERYTABLE_SIZE];	/* query table */

/* return the lock bit */
#define ISLOCKED(x)                   (io->lock[(x)>>FLASH_SECTOR_SHIFT])


#define ADDR_SUSPENDED(x)       \
((io->program_suspended && ((x) == io->program_latch_addr)) || \
 (io->progbuf_suspended && (((x) >= io->pb_start) && ((x) < (io->pb_start+io->pb_count)))) || \
 (io->erase_suspended && (((x) & FLASH_SECTOR_MASK) == (io->erase_latch_addr & FLASH_SECTOR_MASK))) )

#define DEVICE_SUSPENDED        (io->program_suspended || io->progbuf_suspended || io->erase_suspended)

void
flash_intel_reset (struct device_desc *dev)
{
	struct flash_device *flash_dev = (struct flash_device *) dev->dev;
	struct flash_intel_io *io = (struct flash_intel_io *) dev->data;
	unsigned int i;

	io->size = INTEL28F128J3A_SIZE;

	io->lock = malloc (io->size / FLASH_SECTOR_SIZE);
	if (io->lock == NULL) {
		printf ("\nflash memory lock allocation failed");	/* exit */
	}
	for (i = 0; i < io->size / FLASH_SECTOR_SIZE; i++) {
		io->lock[i] = 0;
	}
	io->read_mode = WSM_READ_ARRAY;
	io->wsm_mode = WSM_READY;

	io->program_busy = io->progbuf_busy = io->erase_busy = io->lock_busy =
		0;
	io->program_suspended = io->progbuf_suspended = io->erase_suspended =
		0;
	io->protection_error = io->program_setlb_error =
		io->erase_clearlb_error = io->program_volt_error = 0;

	//io->vpen = 0;     /* disable program/erase */
	io->vpen = 1;		/* enable program/erase */

	io->pb_count = io->pb_loaded = 0;

	init_querytable ();
}

static void
flash_intel_fini (struct device_desc *dev)
{
	struct flash_intel_io *io = (struct flash_intel_io *) dev->data;
	if (!dev->dev)
		free (dev->dev);
	if (!io)
		free (io);
}

int
flash_intel_read_byte (struct device_desc *dev, u32 addr, u8 * data)
{
	struct machine_config *mc = (struct machine_config *) dev->mach;
	ARMul_State *state = (ARMul_State *) mc->state;
	u32 temp, offset;
	int ret = ADDR_HIT;
	flash_intel_read_word (dev, addr, &temp);
	offset = (((u32) state->bigendSig * 3) ^ (addr & 3)) << 3;
	*data = (temp >> offset & 0xffL);
	printf("In %s, mem_read addr=0x%x, data=0x%x, temp=0x%x\n", __FUNCTION__, addr, *data, temp);
	return ret;
}

int
flash_intel_read_halfword (struct device_desc *dev, u32 addr, u16 * data)
{
	struct machine_config *mc = (struct machine_config *) dev->mach;
	ARMul_State *state = (ARMul_State *) mc->state;
	u32 temp, offset;
	int ret = ADDR_HIT;
	flash_intel_read_word (dev, addr, &temp);
	offset = (((u32) state->bigendSig * 2) ^ (addr & 2)) << 3;
	*data = (temp >> offset & 0xffffL);
	printf("In %s, mem_read addr=0x%x, data=0x%x, temp=0x%x\n", __FUNCTION__, addr, *data, temp);
	return ret;
}

int
flash_intel_read_word (struct device_desc *dev, u32 addr, u32 * data)
{
	struct flash_device *flash_dev = (struct flash_device *) dev->dev;
	struct flash_intel_io *io = (struct flash_intel_io *) dev->data;
	struct machine_config *mc = (struct machine_config *) dev->mach;
	ARMul_State *state = (ARMul_State *) mc->state;
	int ret = ADDR_HIT;

	u32 temp;
	
	switch (io->read_mode) {
	case WSM_READ_ARRAY:	/* read flash */
		//data = mem[WORD_ADDR(addr)];
		//chy 2006-08-12 fig bug: not set global_mbp before real_read/write_byte/word.
		/*
		global_mbp = bank_ptr (addr);
		*data = real_read_word (state, addr);
		*/
		mem_read(32, addr, data);
		printf("In %s, mem_read addr=0x%x, data=0x%x\n", __FUNCTION__, addr, *data);
		break;
	case WSM_READ_ID:	//read IDs
		temp = WORD_ADDR (addr) & 0x00000001;
		if (temp == 0) {
			*data = BOTHCHIP (INTEL_MANUFACTURER_CODE);
		}		//manu. ID 
		else if (temp == 1) {
			*data = BOTHCHIP (INTEL_28F128J3A_DEVICE_CODE);
		}		// device ID
		else if (((addr & FLASH_SECTOR_OFF) >> WORD_SHIFT) == 2)	//read lock state 
			*data = BOTHCHIP (ISLOCKED (addr) & 0x1);
		else {
			*data = 0;
			printf ("\nFlash: read ID error: unknown address 0x%x\n", addr);
		}
		break;
	case WSM_READ_STATUS:	/* read status register */

		/* first get the WSM busy/ready state */
		temp = !io->program_busy && !io->progbuf_busy
			&& !io->lock_busy && !io->erase_busy;
		/* suppose no voltage error */
		*data = BOTHCHIP ((temp << 7) |
				  (io->erase_suspended << 6) |
				  (io->erase_clearlb_error << 5) |
				  (io->program_setlb_error << 4) |
				  (io->program_volt_error << 3) |
				  (io->program_suspended << 2) | (io->
								  protection_error)
				  << 1);

		break;
	case WSM_READ_QUERY:	// read query table 
		//temp = WORD_ADDR(addr);
		temp = WORD_ADDR (addr & 0x0000ffff);
		*data = (temp < INTEL_QUERYTABLE_SIZE) ? query[temp] : 0;
		break;
	default:
		printf ("\nFlash: invalid read mode: %d", io->read_mode);
		*data = 0;
		break;
	}
	return ret;
}

int
flash_intel_write_byte (struct device_desc *dev, u32 addr, u8 data)
{
	int ret = ADDR_HIT;
	printf ("\nFlash in current config does not support halfword write at 0x%x", addr);
	return ret;
}

int
flash_intel_write_halfword (struct device_desc *dev, u32 addr, u16 data)
{
	int ret = ADDR_HIT;
	printf ("\nFlash in current config does not support byte write at 0x%x", addr);
	return ret;
}

/* initialize a new WSM command sequence */
void
init_wsm (struct device_desc *dev, u32 addr, u32 data)
{
	struct flash_intel_io *io = (struct flash_intel_io *) dev->data;
	/* maybe we don't need to care the data symmetry */
	//CHECK_DATA_VALID(data);

	/*
	 * No timing support now, so Suspend/Resume has no effect 
	 * July 1st, 2004 Ye Wen
	 */
	int i;
	u32 cmd = data & 0xff;
	switch (cmd) {
	case WSM_READ_ARRAY:
		io->read_mode = WSM_READ_ARRAY;
		break;
	case WSM_READ_ID:
		io->read_mode = WSM_READ_ID;
		break;
	case WSM_READ_STATUS:
		io->read_mode = WSM_READ_STATUS;
		break;
	case WSM_READ_QUERY:
		io->read_mode = WSM_READ_QUERY;
		break;
	case WSM_CLEAR_STATUS:
		io->protection_error = io->program_setlb_error =
			io->erase_clearlb_error = io->program_volt_error = 0;
		// is this right? I can't see it from spec.
		// but the bootldr code implies this. Check
		// program_flash_region in bootldr.c
		// -July 28, 2004 Ye Wen
		io->read_mode = WSM_READ_ARRAY;
		break;
	case WSM_PROGRAM:
	case WSM_PROGRAM2:
		io->wsm_mode = WSM_PROGRAM;
		break;
	case WSM_WRITE_BUFFER:
		io->wsm_mode = WSM_WRITE_BUFFER;
		io->read_mode = WSM_READ_STATUS;
		io->pb_count = io->pb_loaded = 0;
		for (i = 0; i < INTEL_WRITEBUFFER_SIZE; i++)
			io->pb_buf[i] = 0xffffffff;
		break;
	case WSM_BLOCK_ERASE:
		io->wsm_mode = WSM_BLOCK_ERASE;
		break;
	case WSM_SUSPEND:
		if (io->program_busy)
			io->program_suspended = 1;
		else if (io->progbuf_busy)
			io->progbuf_suspended = 1;
		else if (io->erase_busy)
			io->erase_suspended = 1;
		else {
			//ywc
			//printf("\nFlash: nothing busy for suspending");
		}
		break;
	case WSM_RESUME:
		if (io->program_suspended)
			io->program_suspended = 0;
		else if (io->progbuf_suspended)
			io->progbuf_suspended = 0;
		else if (io->erase_suspended)
			io->erase_suspended = 0;
		else {
			//ywc
			//printf("\nFlash: nothing to resume");
		}
		break;
	case WSM_LOCK_ACCESS:
		io->wsm_mode = WSM_LOCK_ACCESS;
		break;
	case WSM_CONFIG:
	case WSM_PROTECT:
		printf ("\nFlash: command 0x%x not supported yet", cmd);
		break;
	default:
		//ywc
		//printf("\nFlash: command 0x%x unrecognized", cmd);
		break;
	}
}
int
flash_intel_write_word (struct device_desc *dev, u32 addr, u32 data)
{
	struct machine_config *mc = (struct machine_config *) dev->mach;
	struct flash_intel_io *io = (struct flash_intel_io *) dev->data;
	ARMul_State *state = (ARMul_State *) mc->state;
	unsigned int i;
	int ret = ADDR_HIT;
	u32 j;

	
	//CHECK_ADDR_RANGE(addr);
         
        //fprintf(stderr,"SKYEYE flash write begin: addr %x  data %x\n", addr,data);
	switch (io->wsm_mode) {
	case WSM_READY:
		init_wsm (dev, addr, data);
		break;
	case WSM_WRITE_BUFFER:
		if (io->pb_count == 0) {	/* step 1: get count */
			io->pb_count = (data & 0xff) + 1;
			io->progbuf_latch_addr = addr;
			//fprintf(stderr,"SKYEYE flash write step 1: count %x  addr %x\n",io->pb_count, addr);
			if (io->pb_count > INTEL_WRITEBUFFER_SIZE) {
				io->program_setlb_error =
					io->erase_clearlb_error = 1;
				io->wsm_mode = WSM_READY;
				printf ("\nFlash: buffer program count too large: %d", io->pb_count);
				break;
			}
			if (SECTOR_ADDR (addr) !=
			    SECTOR_ADDR (addr + io->pb_count - 1)) {
				io->program_setlb_error =
					io->erase_clearlb_error = 1;
				io->wsm_mode = WSM_READY;
				printf ("\nFlash: buffer program address range across sectors: 0x%x-0x%x", addr, addr + io->pb_count - 1);
				break;
			}
			break;
		}
		if (io->pb_loaded < io->pb_count) {	/* step 2: load data */
			if (SECTOR_ADDR (addr) !=
			    SECTOR_ADDR (io->progbuf_latch_addr)) {
				io->program_setlb_error =
					io->erase_clearlb_error = 1;
				io->wsm_mode = WSM_READY;
				printf ("\nFlash: buffer program address across sectors: 0x%x", addr);
				break;
			}
			if (io->pb_loaded == 0)
				io->pb_start = addr;
			io->pb_buf[WORD_ADDR (addr) & INTEL_WRITEBUFFER_MASK]
				= data;
			io->pb_loaded++;
			break;
		}
		//fprintf(stderr,"SKYEYE flash write step 2: load data: start_addr %x, count %x\n",io->pb_start, io->pb_loaded);
		if ((data & 0xff) == WSM_CONFIRM) {	/* step 3: confirm the program */
			io->progbuf_busy = 1;
			io->read_mode = WSM_READ_STATUS;
			/* copy buffer to flash */
			if (ISLOCKED (io->progbuf_latch_addr)) {
				printf ("\nFlash: buffer program locked address [0x%x]", io->progbuf_latch_addr);
				io->program_setlb_error =
					io->protection_error = 1;
			}
			else if (DEVICE_SUSPENDED) {
				printf ("\nFlash: buffer program suspended device");
				io->program_setlb_error = 1;
			}
			else if (io->vpen != 1) {
				printf ("\nFlash: can't buffer program when VPEN low");
				io->program_setlb_error =
					io->program_volt_error = 1;
			}
			else {
		              //fprintf(stderr,"SKYEYE flash write step 3: confirm: \n");
				for (j = WORD_ADDR (io->pb_start);
				     j <
				     WORD_ADDR (io->pb_start) +
				     INTEL_WRITEBUFFER_SIZE; j++){
					//mem[j] &= io->pb_buf[j & INTEL_WRITEBUFFER_MASK];
					//chy 2006-08-12 fix bug: not set global_mbp before real_read/write_byte/word.
					//chy 2006-08-13 fix bug: j =real_addr >>2. should be j<<2
					/*
					global_mbp = bank_ptr (j<<WORD_SHIFT);
					real_write_word (state, j<<WORD_SHIFT,
							 real_read_word
							 (state,
							  j<<WORD_SHIFT) & io->pb_buf[j &
									  INTEL_WRITEBUFFER_MASK]);
					*/
					uint32_t tmp; 
					mem_read(32, j<<WORD_SHIFT, &tmp);
					mem_write(32, j<<WORD_SHIFT, tmp & io->pb_buf[j & INTEL_WRITEBUFFER_MASK]);
					printf("In %s, mem_read 0x%x, mem_write 0x%x\n", tmp, tmp & io->pb_buf[j & INTEL_WRITEBUFFER_MASK]);
				}
			}
			io->wsm_mode = WSM_READY;
			io->progbuf_busy = 0;
			break;
		}
		else {
			printf ("\nFlash: buffer program with wrong cmd sequence: 0x%x", data);
			io->program_setlb_error = io->erase_clearlb_error = 1;
			io->wsm_mode = WSM_READY;
			break;
		}
		break;
	case WSM_PROGRAM:
	case WSM_PROGRAM2:
		io->program_busy = 1;
		io->program_latch_addr = addr;
		io->program_latch_data = data;
		io->read_mode = WSM_READ_STATUS;
		if (ISLOCKED (io->program_latch_addr)) {
			printf ("\nFlash: program locked address [0x%x]=0x%x",
				addr, data);
			io->program_setlb_error = io->protection_error = 1;
		}
		else if (ADDR_SUSPENDED (io->program_latch_addr)) {
			printf ("\nFlash: program suspended address [0x%x]=0x%x", addr, data);
			io->program_setlb_error = 1;
		}
		else if (io->vpen != 1) {
			printf ("\nFlash: can't program when VPEN low");
			io->program_setlb_error = io->program_volt_error = 1;
		}
		else {
			//mem[WORD_ADDR(io->program_latch_addr)] &= data;
			//chy 2006-08-12 fig bug: not set global_mbp before real_read/write_byte/word.
			/*
			global_mbp = bank_ptr (io->program_latch_addr);
			real_write_word (state, io->program_latch_addr,
					 real_read_word (state,
							 io->
							 program_latch_addr) &
					 data);
			*/
			uint32_t tmp;
			mem_read(32, io->program_latch_addr, &tmp);
			mem_write(32, io->program_latch_addr, tmp & data);
			printf("In %s, mem_read 0x%x, mem_write 0x%x\n", tmp, tmp & data);
		}
		io->program_busy = 0;
		io->wsm_mode = WSM_READY;
		break;
	case WSM_BLOCK_ERASE:
		if ((data & 0xff) == WSM_CONFIRM) {
			io->erase_busy = 1;
			io->erase_latch_addr = addr & FLASH_SECTOR_MASK;
			io->read_mode = WSM_READ_STATUS;
			if (ISLOCKED (io->erase_latch_addr)) {
				printf ("\nFlash: erase locked address [0x%x]", io->erase_latch_addr);
				io->erase_clearlb_error =
					io->protection_error = 1;
			}
			else if (DEVICE_SUSPENDED) {
				printf ("\nFlash: erase suspended device");
				io->erase_clearlb_error = 1;
			}
			else if (io->vpen != 1) {
				printf ("\nFlash: can't erase when VPEN low\n");
				io->erase_clearlb_error =
					io->program_volt_error = 1;
			}
			else {
				for (i = 0; i < WORD_ADDR (FLASH_SECTOR_SIZE);
				     i++) {
					//mem[WORD_ADDR(io->erase_latch_addr)+i] = 0xffffffff;
					//chy 2006-08-12 fig bug: not set global_mbp before real_read/write_byte/word.
					/*
					global_mbp = bank_ptr (io->erase_latch_addr +(i<<WORD_SHIFT));
					real_write_word (state,io->erase_latch_addr +(i<<WORD_SHIFT), 0xffffffff);
					*/
					mem_write(32, io->erase_latch_addr +(i<<WORD_SHIFT), 0xffffffff);
					printf("In %s, mem_write addr=0x%x\n", __FUNCTION__, io->erase_latch_addr +(i<<WORD_SHIFT));
				}
			}
			io->erase_busy = 0;
			io->wsm_mode = WSM_READY;
			break;
		}
		else {
			printf ("\nFlash: erase with wrong cmd sequence: 0x%x", data);
			io->wsm_mode = WSM_READY;
			break;
		}
		break;
	case WSM_LOCK_ACCESS:
		if ((data & 0xff) == 0x01) {	/* set lock bit */
			io->lock_busy = 1;
			io->read_mode = WSM_READ_STATUS;
			if (DEVICE_SUSPENDED) {
				printf ("\nFlash: set lock on suspended device");
				io->program_setlb_error = 1;
			}
			else if (io->vpen != 1) {
				printf ("\nFlash: can't set lock when VPEN low");
				io->program_setlb_error =
					io->program_volt_error = 1;
			}
			else {
				io->lock[SECTOR_ADDR (addr)] = 1;
			}
			io->lock_busy = 0;
			io->wsm_mode = WSM_READY;
			break;
		}
		else if ((data & 0xff) == WSM_CONFIRM) {	/* clear all lock bits */
			io->lock_busy = 1;
			io->read_mode = WSM_READ_STATUS;
			if (DEVICE_SUSPENDED) {
				printf ("\nFlash: clear locks on suspended device");
				io->erase_clearlb_error = 1;
			}
			else if (io->vpen != 1) {
				printf ("\nFlash: can't clear locks when VPEN low");
				io->erase_clearlb_error =
					io->program_volt_error = 1;
			}
			else {
				for (i = 0; i < io->size / FLASH_SECTOR_SIZE;
				     i++)
					io->lock[i] = 0;
			}
			io->lock_busy = 0;
			io->wsm_mode = WSM_READY;
			break;
		}
		else {
			printf ("\nFlash: lock access with wrong cmd sequence: 0x%x", data);
			io->wsm_mode = WSM_READY;
			break;
		}
		break;
	default:
		printf ("\nFlash: Can't recognize WSM mode: 0x%x",
			io->wsm_mode);
		break;
	}

	return ret;
}

void
init_querytable ()
{
	int i;
	for (i = 0; i < INTEL_QUERYTABLE_SIZE; i++) {
		query[i] = 0;
	}

	/*
	 * This is a dump of a real 28F128J3A flash query table 
	 * Lines with a "*": different from Verilog model (Ref.2)
	 * Lines with a "+": different from the spec (Ref.1)
	 */
	query[0x00] = 0x00890089;	//manu. ID
	//query[0x01] = 0x00170017;             //device ID     
	query[0x01] = 0x00180018;	//device ID     
	query[0x02] = 0x00010001;	//?

	query[0x10] = 0x00510051;	//"Q"
	query[0x11] = 0x00520052;	//"R"
	query[0x12] = 0x00590059;	//"Y"

	query[0x13] = 0x00010001;

	query[0x15] = 0x00310031;

	query[0x1b] = 0x00270027;
	query[0x1c] = 0x00360036;
	query[0x1f] = 0x00070007;
	query[0x20] = 0x00070007;
	query[0x21] = 0x000A000A;
	query[0x23] = 0x00040004;
	query[0x24] = 0x00040004;
	query[0x25] = 0x00040004;

	query[0x27] = 0x00180018;	//2^(0x18) = 2^24 = 16MByte 28F128 flash chip size
	//query[0x27] = 0x00170017;

	query[0x28] = 0x00020002;
	query[0x2a] = 0x00050005;	//2^5 = 32 write buffer size
	query[0x2c] = 0x00010001;	//symmetrically-blocked

	query[0x2d] = 0x007F007F;	//[31,16]=?(128KByte) ;[15,0]=block number

	query[0x30] = 0x00020002;

	query[0x31] = 0x00500050;	//"P"
	query[0x32] = 0x00520052;	//"R"
	query[0x33] = 0x00490049;	//"I"

	query[0x34] = 0x00310031;
	query[0x35] = 0x00320032;	// *

	query[0x36] = 0x00CE00CE;	// *

	query[0x3a] = 0x00010001;

	query[0x3b] = 0x00010001;
	query[0x3c] = 0x00010001;

	query[0x3d] = 0x00330033;
	query[0x3f] = 0x00010001;

	query[0x40] = 0x00000000;	// +
	query[0x41] = 0x00010001;	// +
	query[0x42] = 0x00030003;
	query[0x43] = 0x00030003;
	query[0x44] = 0x00030003;
}
static int
flash_intel_setup (struct device_desc *dev)
{
	int i;
	struct flash_intel_io *io;
	struct device_interrupt *intr = &dev->intr;

	dev->fini = flash_intel_fini;
	dev->reset = flash_intel_reset;
	//dev->update = flash_intel_update;
	dev->read_byte = flash_intel_read_byte;
	dev->write_byte = flash_intel_write_byte;
	dev->read_halfword = flash_intel_read_halfword;
	dev->write_halfword = flash_intel_write_halfword;
	dev->read_word = flash_intel_read_word;
	dev->write_word = flash_intel_write_word;

	io = (struct flash_intel_io *)
		malloc (sizeof (struct flash_intel_io));
	memset (io, 0, sizeof (struct flash_intel_io));
	if (io == NULL)
		return 1;
	dev->data = (void *) io;

	flash_intel_reset (dev);


	/* see if we need to set default values.
	 * */
	//set_device_default (dev, intel_flash_def);


	return 0;
}

void
flash_intel_init (struct device_module_set *mod_set)
{
	int i;
	register_device_module ("28F128J3A", mod_set, &flash_intel_setup);

}
