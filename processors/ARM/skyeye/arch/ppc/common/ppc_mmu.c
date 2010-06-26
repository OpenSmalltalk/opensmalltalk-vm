/*
 *	PearPC
 *	ppc_mmu.cc
 *
 *	Copyright (C) 2003, 2004 Sebastian Biallas (sb@biallas.net)
 *	Portions Copyright (C) 2004 Daniel Foesch (dfoesch@cs.nmsu.edu)
 *	Portions Copyright (C) 2004 Apple Computer, Inc.
 *
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License version 2 as
 *	published by the Free Software Foundation.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program; if not, write to the Free Software
 *	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

/*	Pages marked: v.???
 *	From: IBM PowerPC MicroProcessor Family: Altivec(tm) Technology...
 *		Programming Environments Manual
 */

#include "debug.h"
#include "tracers.h"
#include "sysendian.h"
#include "io.h"
#include "ppc_cpu.h"
#include "ppc_fpu.h"
#include "ppc_vec.h"
#include "ppc_mmu.h"
#include "ppc_exc.h"
#include "ppc_tools.h"
#include "ppc_memory.h"
#include "ppc_e500_exc.h"

#define DEFAULT_CCSR_MEM 0xFF700000
#define CCSR_MEM_SIZE 0x100000
#define GET_CCSR_BASE(reg)(((reg >> 8)&0xFFF) << 20)

e500_mmu_t e500_mmu;
ppc_tlb_entry_t l1_i_vsp[4]; /* instruction, filled by TLB1 hit */
ppc_tlb_entry_t l1_i_tlb4k[64]; /* instruction, filled by TLB0 hit */
ppc_tlb_entry_t l1_d_vsp[4]; /* data, filled by TLB1 hit */
ppc_tlb_entry_t l1_d_tlb4k[64]; /* data, filled by TLB0 hit */

#define L2_TLB0_SIZE 256
#define L2_TLB1_SIZE 16
ppc_tlb_entry_t l2_tlb0_4k[L2_TLB0_SIZE]; /* unified, filled by tlbwe instruction */
ppc_tlb_entry_t l2_tlb1_vsp[L2_TLB1_SIZE]; /* filled by tlbwe insructions */
/*
ea = effective address
if translation is an instruction address then
	as = MSR[IS];
else // data address translation
	as = MSR[DS]
for all TLB entries
	if !TLB[entry].v then
		next // compare next TLB entry
	if as != TLB[entry].ts then
		next // compare next TLB entry
	if TLB[entry].tid == 0 then
		goto pid_match
	for all PID registers
		if this PID register == TLB[entry].tid then
			goto pid_match
	endfor
	next // no PIDs matched
 	pid_match://translation match
	mask = ~(1024 << (2 * TLB[entry].tsize)) - 01
	if (ea & mask) != TLB[entry].epn then
		next // no address match
	real address = TLB[entry].rpn | (ea & ~mask) // real address computed
	end translation --success
	endfor
	end translation tlb miss
*/
int ppc_effective_to_physical(uint32 addr, int flags, uint32 *result){
	int i,j;
	uint32 mask;
	ppc_tlb_entry_t *entry;
	int tlb1_index;
	int pid_match = 0;

	i = 0;
	/* walk over tlb0 and tlb1 to find the entry */
	while(i++ < (L2_TLB0_SIZE + L2_TLB1_SIZE)){
		if(i > (L2_TLB0_SIZE - 1)){
			tlb1_index = i - L2_TLB0_SIZE;
			entry = &l2_tlb1_vsp[tlb1_index];
		}
		else
			entry = &l2_tlb0_4k[i];
		if(!entry->v)
			continue;
		/* FIXME, not check ts bit now */
		if(entry->ts & 0x0)
			continue;
		if(entry->tid != 0){
			/*
			for(j = 0; j < 3; j++){
				if(e500_mmu.pid[j] == entry->tid)
					break;
			}*/
			//printf("entry->tid=0x%x\n", entry->tid);
			
			if(e500_mmu.pid[0] != entry->tid)
				continue;
			
		}
		if(i > (L2_TLB0_SIZE - 1)){
			int k,s = 1;
			for(k = 0; k < entry->size; k++)
				s = s * 4; 
			mask = ~((1024 * (s - 1) - 0x1) + 1024);
		}
		else
			mask = ~(1024 * 4 - 0x1);
		if(entry->size != 0xb){
			if((addr & mask) != ((entry->epn << 12) & mask))
				continue;
			/* check rwx bit */
			if(flags == PPC_MMU_WRITE){
				if(gCPU.msr & 0x4000){ /* Pr =1 , we are in user mode */
					if(!(entry->usxrw & 0x8)){
						//printf("In %s,usermode,offset=0x%x, entry->usxrw=0x%x,pc=0x%x\n", __FUNCTION__, i, entry->usxrw, gCPU.pc);
						ppc_exception(DATA_ST, flags, addr);
       			         		return PPC_MMU_EXC;
					}
				}
				else{/* Or PR is 0,we are in Supervisor mode */
					if(!(entry->usxrw & 0x4)){/* we judge SW bit */
						//printf("In %s,Super mode,entry->usxrw=0x%x,pc=0x%x\n", __FUNCTION__, entry->usxrw, gCPU.pc);
        	                                ppc_exception(DATA_ST, flags, addr);
                	                        return PPC_MMU_EXC;
                                	}
				}
			}

			*result = (entry->rpn << 12) | (addr & ~mask); // get real address
		}
		else {/*if 4G size is mapped, we will not do address check */
			//fprintf(stderr,"warning:4G address is used.\n");
			if(addr < (entry->epn << 12))
				continue;
			 *result = (entry->rpn << 12) | (addr - (entry->epn << 12)); // get real address

		}
		return PPC_MMU_OK;
	}
	//printf("In %s,DATA_TLB exp,addr=0x%x,pc=0x%x\n", __FUNCTION__, addr, gCPU.pc);
	if(flags == PPC_MMU_CODE){
		ppc_exception(INSN_TLB, flags, addr);
		return PPC_MMU_EXC;
	}
	else{
		if(ppc_exception(DATA_TLB, flags, addr))
			return PPC_MMU_EXC;
	}
	return PPC_MMU_FATAL;
	
}
int e500_mmu_init(){
	/* the initial tlb map of real hardware */
	ppc_tlb_entry_t * entry = &l2_tlb1_vsp[0];
	entry->v = 1; /* entry is valid */
	entry->ts = 0; /* address space 0 */
	entry->tid = 0; /* TID value for shared(global) page */
	entry->epn = 0xFFFFF; /* Address of last 4k byte in address space*/
	entry->rpn = 0xFFFFF; /* Address of last 4k byte in address space*/
	entry->size = 0x1; /* 4k byte page size */
	/* usxrw should be initialized to 010101 */
	entry->usxrw |= 0x15; /* Full supervisor mode access allowed */
	entry->usxrw &= 0x15; /* No user mode access allowed */
	entry->wimge = 0x8; /* Caching-inhibited, non-coherent,big-endian*/
	entry->x = 0; /* Reserved system attributes */
	entry->u = 0; /* User attribute bits */
	entry->iprot = 1; /* Page is protected from invalidation */
	gCPU.ccsr.ccsr = 0xFF700;
	e500_mmu.tlbcfg[0] = 0x4110200;
	e500_mmu.tlbcfg[1] = 0x101bc010;

	gCPU.lb_ctrl.lcrr = 0x80000008;
	gCPU.i2c_reg.i2csr = 0x81;
	gCPU.i2c_reg.i2cdfsrr = 0x10;
	gCPU.pic_ram.ctpr0 = 0x0000000F;
	gCPU.pic_global.svr = 0xFFFF;
}

int FASTCALL ppc_read_effective_word(uint32 addr, uint32 *result)
{
	uint32 p;
	int r;
	if (!(r = ppc_effective_to_physical(addr, PPC_MMU_READ, &p))) {
		ppc_io_read_word(&gCPU, p);
		//printf("DBG:ccsr=0x%x,CCSR_BASE=0x%x\n",gCPU.ccsr.ccsr,GET_CCSR_BASE(gCPU.ccsr.ccsr));
		if((p >= GET_CCSR_BASE(gCPU.ccsr.ccsr)) && (p < (GET_CCSR_BASE(gCPU.ccsr.ccsr) + CCSR_MEM_SIZE))){
			int offset = p - GET_CCSR_BASE(gCPU.ccsr.ccsr);
			//printf("DBG:in %s,read CCSR,offset=0x%x,pc=0x%x\n", __FUNCTION__, offset, gCPU.pc);
			if(offset >= 0x919C0 && offset <= 0x919E0){
                                switch(offset){
                                        case 0x919C0:
                                                *result = gCPU.cpm_reg.cpcr;
                                                return r;
                                        default:
	                                        fprintf(stderr,"in %s, error when read CCSR.offset=0x%x,pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);
                                        	skyeye_exit(-1);
                                }
                        }
			 if(offset >= 0x2000 && offset <= 0x2E58){
                                switch(offset){
                                        case 0x2E44:
                                                *result = gCPU.ddr_ctrl.err_disable;
                                                return r;
                                        default:
                                                fprintf(stderr,"in %s, error when read CCSR.offset=0x%x,pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);
                                                skyeye_exit(-1);
                                }
                        }
			
                        /**
                         *  PIC Register Address Map
                         */
                        if(offset >= 0x50000 && offset <= 0x600B0){
				if(offset >= 0x50000 && offset <= 0x50170){
					int index = (offset - 0x50000) >> 4;
					if(index & 0x1)
						*result = gCPU.pic_ram.eidr[index >> 1];
					else
						*result = gCPU.pic_ram.eivpr[index >> 1];
					return r;
				}
				if(offset >= 0x50200 && offset <= 0x505F0){
					int index = (offset - 0x50200) >> 4;
					if(index & 0x1)
						*result = gCPU.pic_ram.iidr[index >> 1];
					else
						*result = gCPU.pic_ram.iivpr[index >> 1];
					return r;
				}
				
                                switch(offset){
					case 0x60080:
						*result = gCPU.pic_ram.ctpr0;
						return r;
					case 0x600a0:
						*result = gCPU.pic_percpu.iack0;
						return r;
                                        default:
                                                fprintf(stderr,"in %s, error when write pic ram,offset=0x%x,pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);

                                                break;
				}
                        }
		
			/**
                         * Interrupt Controller
                         */

                        if(offset >= 0x90C00 && offset <= 0x90C7F){
                                switch(offset){
                                        case 0x90C08:
                                                *result = gCPU.int_ctrl.sipnr_h;
                                                return r;
                                        case 0x90C0C:
                                                *result = gCPU.int_ctrl.sipnr_l;
                                                return r;
                                        case 0x90C14:
                                                *result = gCPU.int_ctrl.scprr_h;
                                                return r;
                                        case 0x90C18:
                                                *result = gCPU.int_ctrl.scprr_l;
                                                return r;
                                        case 0x90C1C:
                                                *result = gCPU.int_ctrl.simr_h;
                                                return r;
                                        case 0x90C20:
                                                *result = gCPU.int_ctrl.simr_l;
                                                return r;
                                        default:
                                                fprintf(stderr,"in %s, error when read interrupt controller,offset=0x%x,pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);
                                                return r;
                                }
                        }

			if(offset >= 0x91A00 && offset <= 0x91A3F){
                                int i = (0x20 & offset) >> 5;
                                offset = 0x1f & offset;
                                switch(offset){
                                        case 0x0:
                                                *result = gCPU.cpm_reg.scc[i].gsmrl;
                                                return r;
                                        default:
                                                fprintf(stderr,"in %s, error when read CCSR.offset=0x%x, \
                                pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);

                                                skyeye_exit(-1);

                                }
                        }

			/* CPM MUX I/O */
                        if(offset >= 0x91B00 && offset <= 0x91B1F){
                                switch(offset){
                                        case 0x91B08:
                                                *result = gCPU.cpm_reg.mux.cmxscr;
                                                return r;
					case 0x91B04:
						*result = gCPU.cpm_reg.mux.cmxfcr;
						return r;
                                        default:
                                                fprintf(stderr,"in %s, error when read CCSR.offset=0x%x, \
                                pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);

                                                skyeye_exit(-1);

                                }

                        }
			/* PIC Global register */
			if(offset >= 0x40000 && offset <= 0x4FFF0){
				 switch(offset){
					case 0x41000:
						*result = gCPU.pic_global.frr= 0x370002; /* according to 8560 manual */
						return r;
					case 0x400a0:
						*result = gCPU.pic_global.iack;
						return r;
					case 0x410f0:
						*result = gCPU.pic_global.tfrr;
						return r;
                                        case 0x41020:
                                                /* source attribute register for DMA0 */
                                                *result = gCPU.pic_global.gcr;
                                                return r;
					case 0x410e0:
                                                *result = gCPU.pic_global.svr;
                                                return r;

					case 0x41120:
						*result = gCPU.pic_global.gtvpr0; 
						return r;
					case 0x41160:
						*result = gCPU.pic_global.gtvpr1;			
						return r;
					case 0x41170:
                                                *result = gCPU.pic_global.gtdr1;
                                                return r;
                                        case 0x411a0:
                                                *result = gCPU.pic_global.gtvpr2;
                                                return r;
                                        case 0x411B0:
                                                *result = gCPU.pic_global.gtdr2;
                                                return
r;

					case 0x411E0:
						*result = gCPU.pic_global.gtvpr3;
                                                return
r;

                                        default:
                                                fprintf(stderr,"in %s, error when read global.offset=0x%x, \
                                pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);
                                                return r;
                                                //skyeye_exit(-1);

                                }
                        }

			/* DMA */
                        if(offset >= 0x21100 && offset <= 0x21300){
                                switch(offset){
                                        case 0x21110:
                                                /* source attribute register for DMA0 */
                                                *result = gCPU.dma.satr0;
                                                return r;
                                        case 0x21118:
                                                *result = gCPU.dma.satr0;
                                                return r;
                                        default:
                                                fprintf(stderr,"in %s, error when read dma.offset=0x%x, \
                                pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);
                                                return r;
                                                //skyeye_exit(-1);

                                }
                        }
			/* Input/Output port */
			if(offset >= 0x90D00 && offset <= 0x90D70){
                                switch(offset){
					case 0x90D00:
						*result = gCPU.cpm_reg.ioport.pdira;
						return r;
                                        case 0x90D04:
                                                *result = gCPU.cpm_reg.ioport.ppara;
                                                return r;
					case 0x90D08:
                                                *result = gCPU.cpm_reg.ioport.psora;
                                                return r;
					case 0x90D0C:
                                                *result = gCPU.cpm_reg.ioport.podra ;
                                                return r;
                                        case 0x90D10:
                                                *result = gCPU.cpm_reg.ioport.pdata;
                                                return r;
					case 0x90D20:
                                                *result = gCPU.cpm_reg.ioport.pdirb;
                                                return r;
                                        case 0x90D24:
                                                *result = gCPU.cpm_reg.ioport.pparb;
                                                return r;
                                        case 0x90D28:
                                                *result = gCPU.cpm_reg.ioport.psorb;
                                                return r;
                                        case 0x90D40:
                                                *result = gCPU.cpm_reg.ioport.pdirc;
                                                return r;
                                        case 0x90D44:
                                                *result = gCPU.cpm_reg.ioport.pparc;
                                                return r;
                                        case 0x90D48:
                                                *result = gCPU.cpm_reg.ioport.psorc;
                                                return r;
					case 0x90D60:
                                                *result = gCPU.cpm_reg.ioport.pdird;
                                                return r;
                                        case 0x90D64:
                                                *result = gCPU.cpm_reg.ioport.ppard;
                                                return r;
                                        case 0x90D68:
                                                *result = gCPU.cpm_reg.ioport.psord;
                                                return r;


                                        default:
                                                fprintf(stderr,"in %s, error when read IO port.offset=0x%x, \
                                pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);
						return r;
                                                //skyeye_exit(-1);

                                }

                        }

			if(offset >= 0x80000 && offset < 0x8C000){
                                *result = ppc_word_from_BE(*((sint32 *)&gCPU.cpm_reg.dpram[offset - 0x80000]));
				//printf("DBG_CPM:in %s,offset=0x%x,data=0x%x,pc=0x%x\n",__FUNCTION__, offset, *result,gCPU.pc);
                                return r;
                        }

			if(offset >= 0xE0000 && offset <= 0xE0020){
				switch(offset){
                                	case 0xE0000:
                                                *result = gCPU.por_conf.porpllsr;
                                                return r;
					case 0xE000C:
						*result = gCPU.por_conf.pordevsr;
						return r;

                                        default:
                                                fprintf(stderr,"in %s, error when read CCSR.addr=0x%x,pc=0x%x\n",__FUNCTION__, addr, gCPU.pc);
                                                skyeye_exit(-1);
                                }

			}
                        switch(offset){
                                case 0x0:
                                        *result = gCPU.ccsr.ccsr;
                                        break;
				case 0xC28:
					*result = gCPU.law.lawbar[1];
					break;
				case 0xC30:
					*result = gCPU.law.lawar[1];
				case 0x90C80:
					*result = gCPU.sccr;
					break;
				case 0xe0e10:
					*result = gCPU.debug_ctrl.ddrdllcr;
					return r;	
				case 0x50D4:
					*result = gCPU.lb_ctrl.lcrr;
					return r;
				case 0x20000:
					*result = gCPU.l2_reg.l2ctl;
					return r;
				case 0x8004:
                                        *result = gCPU.pci_cfg.cfg_data;
                                        return r;
				default:
                                        fprintf(stderr,"in %s, error when read CCSR.offset=0x%x,pc=0x%x\n", __FUNCTION__, offset, gCPU.pc);
                                        //skyeye_exit(-1);
                        }
		}
		else if((p >= boot_rom_start_addr) && (p < (boot_rom_start_addr - 1 + boot_romSize )))
			*result = ppc_word_from_BE(*((int *)&boot_rom[p - boot_rom_start_addr]));
		else if((p >= init_ram_start_addr) && (p < (init_ram_start_addr + init_ram_size)))
                        *result = ppc_word_from_BE(*((int *)&init_ram[p - init_ram_start_addr]));
		else if((p >= 0x0) && (p < (0x0 + DDR_RAM_SIZE))){
			                        *result = ppc_word_from_BE(*((int *)&ddr_ram[p]));
		}
		else{
			fprintf(stderr,"in %s, can not find address 0x%x,pc=0x%x\n", __FUNCTION__, p, gCPU.pc);
			//skyeye_exit(-1);
		}	
	}
	return r;
}

int FASTCALL ppc_read_effective_half(uint32 addr, uint16 *result)
{
	uint32 p;
	int r;
	if (!(r = ppc_effective_to_physical(addr, PPC_MMU_READ, &p))) {
		ppc_io_read_halfword(&gCPU, p);
		//printf("DBG:ccsr=0x%x,CCSR_BASE=0x%x\n",gCPU.ccsr.ccsr,GET_CCSR_BASE(gCPU.ccsr.ccsr));
		if((p >= GET_CCSR_BASE(gCPU.ccsr.ccsr)) && (p < (GET_CCSR_BASE(gCPU.ccsr.ccsr) + CCSR_MEM_SIZE))){
			int offset = p - GET_CCSR_BASE(gCPU.ccsr.ccsr);
			//printf("DBG:read CCSR,offset=0x%x,pc=0x%x\n", offset, gCPU.pc);
			if(offset >= 0x919C0 && offset <= 0x919E0){
                                switch(offset){
                                        case 0x919C0:
                                                *result = gCPU.cpm_reg.cpcr;
                                                return r;
                                        default:
	                                        fprintf(stderr,"in %s, error when read CCSR.offset=0x%x,pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);
                                        	skyeye_exit(-1);
                                }
                        }
			if((offset >= 0x80000) && (offset < 0x8C000)){
				*result = ppc_half_from_BE(*((sint16 *)&gCPU.cpm_reg.dpram[offset - 0x80000]));
				return r;
			}
			if(offset >= 0x91A00 && offset <= 0x91A3F){
                                int i = (0x20 & offset) >> 5;
                                offset = 0x1f & offset;
                                switch(offset){
                                        case 0x0:
                                                *result = gCPU.cpm_reg.scc[i].gsmrl;
                                                return r;
                                        case 0x4:
                                                *result = gCPU.cpm_reg.scc[i].gsmrh;
                                                return r;
                                        case 0x8:
                                                *result = gCPU.cpm_reg.scc[i].psmr;
                                                return r;
                                        case 0xE:
                                                *result = gCPU.cpm_reg.scc[i].dsr;
                                                return r;
                                        case 0x14:
                                                *result = gCPU.cpm_reg.scc[i].sccm;
                                                return r;

                                        case 0x10: /* W1C */
                                                *result = gCPU.cpm_reg.scc[i].scce;
                                                return r;
                                        default:
                                                fprintf(stderr,"in %s, error when read CCSR.offset=0x%x, \
                                pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);

                                                skyeye_exit(-1);

                                }
                        }
	
			if(offset >= 0xE0000 && offset <= 0xE0020){
				switch(offset){
                                	case 0xE0000:
                                                *result = gCPU.por_conf.porpllsr;
                                                return r;
                                        default:
                                                fprintf(stderr,"in %s, error when read CCSR.offset=0x%x,pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);
                                                skyeye_exit(-1);
                                }

			}
                        switch(offset){
                                case 0x0:
                                        *result = gCPU.ccsr.ccsr;
                                        break;
				case 0x90C80:
					*result = gCPU.sccr;
					break;
				case 0x8004:
					*result = gCPU.pci_cfg.cfg_data;
					break;	
				case 0x8006:
                                        *result = gCPU.pci_cfg.cfg_data;
                                        break;
                                default:
                                        fprintf(stderr,"in %s, error when read CCSR.offset=0x%x,pc=0x%x\n",__FUNCTION__,offset,gCPU.pc);
                                        //skyeye_exit(-1);
                        }
		}
		else if((p >= boot_rom_start_addr) && (p < (boot_rom_start_addr - 1 + boot_romSize )))
			*result = ppc_half_from_BE(*((sint16 *)&boot_rom[p - boot_rom_start_addr]));
			
		else if((p >= init_ram_start_addr) && (p < (init_ram_start_addr + init_ram_size)))
                        *result = ppc_half_from_BE(*((sint16 *)&init_ram[p - init_ram_start_addr]));
		else if((p >= 0x0) && (p < (0x0 + DDR_RAM_SIZE)))
{
                        *result = ppc_half_from_BE(*((sint16 *)&ddr_ram[p]));
                }
		else{
			fprintf(stderr,"in %s, can not find address 0x%x,pc=0x%x\n", __FUNCTION__, p, gCPU.pc);
			//skyeye_exit(-1);
		}	
	}
	return r;
}

int FASTCALL ppc_read_effective_byte(uint32 addr, uint8 *result)
{ 
	uint32 p;
	int r;
	if (!(r = ppc_effective_to_physical(addr, PPC_MMU_READ, &p))) {
		ppc_io_read_byte (&gCPU, p);
		//printf("\nDBG:in %s,addr=0x%x,p=0x%x\n", __FUNCTION__, addr,p);
		//printf("DBG:ccsr=0x%x,CCSR_BASE=0x%x\n",gCPU.ccsr.ccsr,GET_CCSR_BASE(gCPU.ccsr.ccsr));
		if((p >= GET_CCSR_BASE(gCPU.ccsr.ccsr)) && (p < (GET_CCSR_BASE(gCPU.ccsr.ccsr) + CCSR_MEM_SIZE))){
			int offset = p - GET_CCSR_BASE(gCPU.ccsr.ccsr);
			//printf("DBG:read CCSR,offset=0x%x,pc=0x%x\n", offset, gCPU.pc);
			if(offset >= 0x919C0 && offset <= 0x919E0){
                                switch(offset){
                                        case 0x919C0:
                                                *result = gCPU.cpm_reg.cpcr;
                                                return r;
                                        default:
	                                        fprintf(stderr,"in %s, error when read CCSR.addr=0x%x,pc=0x%x\n",__FUNCTION__, addr, gCPU.pc);
                                        	skyeye_exit(-1);
                                }
                        }
			if(offset >= 0x80000 && offset < 0x8C000){
				*result = *((sint16 *)&gCPU.cpm_reg.dpram[offset - 0x80000]);
				//printf("DBG_CPM:in %s,offset=0x%x,data=0x%x,pc=0x%x\n",__FUNCTION__, offset, *result,gCPU.pc);
				return r;
			}
	
			if(offset >= 0xE0000 && offset <= 0xE0020){
				switch(offset){
                                	case 0xE0000:
                                                *result = gCPU.por_conf.porpllsr;
                                                return r;
                                        default:
                                                fprintf(stderr,"in %s, error when read CCSR.addr=0x%x,pc=0x%x\n",__FUNCTION__, addr, gCPU.pc);
                                                skyeye_exit(-1);
                                }

			}
                        switch(offset){
                                case 0x0:
                                        *result = gCPU.ccsr.ccsr;
                                        break;
				case 0x90C80:
					*result = gCPU.sccr;
					break;
				case 0x300C:
					*result = gCPU.i2c_reg.i2csr;
					fprintf(prof_file,"KSDBG:read i2csr result=0x%x\n", *result);
					return r;
				case 0x8006:
					*result = gCPU.pci_cfg.cfg_data;
					return r;
                                default:
					return r;
                                        //fprintf(stderr,"in %s, error when read CCSR.addr=0x%x,pc=0x%x\n",__FUNCTION__,addr,gCPU.pc);
                                        //skyeye_exit(-1);
                        }
		}
		else if((p >= boot_rom_start_addr) && (p < (boot_rom_start_addr - 1 + boot_romSize )))
			*result = *((byte *)&boot_rom[p - boot_rom_start_addr]);
		else if((p >= init_ram_start_addr) && (p < (init_ram_start_addr + init_ram_size)))
                        *result = *((byte *)&init_ram[p - init_ram_start_addr]);
		else if((p >= 0x0) && (p < (0x0 + DDR_RAM_SIZE))){
                        *result = *((byte *)&ddr_ram[p]);
                }
		else{
			fprintf(stderr,"in %s, can not find address 0x%x,pc=0x%x\n", __FUNCTION__, p, gCPU.pc);
			skyeye_exit(-1);
		}	
	}
	return r;
}


int FASTCALL ppc_write_effective_word(uint32 addr, uint32 data)
{
	uint32 p;
	int r;
	if (!((r=ppc_effective_to_physical(addr, PPC_MMU_WRITE, &p)))) {
		if(p >= GET_CCSR_BASE(gCPU.ccsr.ccsr) && p <(GET_CCSR_BASE(gCPU.ccsr.ccsr) + CCSR_MEM_SIZE)){
			ppc_io_write_word (&gCPU, p, data);
			int offset = p - GET_CCSR_BASE(gCPU.ccsr.ccsr);
			//printf("DBG:write to CCSR,value=0x%x,offset=0x%x,pc=0x%x\n", data, offset,gCPU.pc);
			if(offset >= 0xC08 && offset <= 0xCF0){
				if(offset & 0x8){
					gCPU.law.lawbar[(offset - 0xC08)/0x20] = data;
				}else{
					gCPU.law.lawar[(offset - 0xC10)/0x20] = data;
				}
				return r;
			}

			if(offset >= 0x2000 && offset <= 0x2E58){
                                switch(offset){
                                        case 0x2E44:
                                                gCPU.ddr_ctrl.err_disable = data;
                                                return r;
                                        default:
                                                fprintf(stderr,"in %s, error when write ddr_ctrl,offset=0x%x,pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);
                                                skyeye_exit(-1);
                                }
                        }

			if(offset >= 0x5000 && offset <= 0x50D4){
				if(offset >= 0x5000 && offset <= 0x5038){
					gCPU.lb_ctrl.br[(offset - 0x5000)/0x8] = data;
					return r;
				}
#if 0
				switch(offset){
                                        case 0x50D0:
                                                gCPU.lb_ctrl.lbcr = data;
                                                return r;
                                        default:
                                                fprintf(stderr,"in %s, error when read CCSR.addr=0x%x, \
                                pc=0x%x\n",__FUNCTION__, addr, gCPU.pc);

                                                skyeye_exit(-1);

                                }
#endif
				
                               fprintf(stderr,"in %s, error when write lb_ctrl.addr=0x%x, \
                                pc=0x%x\n",__FUNCTION__, addr, gCPU.pc);

				return r;
			}
			
			/* DMA */
			if(offset >= 0x21100 && offset <= 0x21300){
				switch(offset){
					case 0x21110:
						/* source attribute register for DMA0 */
						gCPU.dma.satr0 = data;
						return r;
					case 0x21118:
						gCPU.dma.satr0 = data;
						return r;
					default:
                                                fprintf(stderr,"in %s, error when write dma.addr=0x%x, \
                                pc=0x%x\n",__FUNCTION__, addr, gCPU.pc);
						return r;
                                                //skyeye_exit(-1);

				}
			}

			/**
 			 *  PIC Register Address Map
			 */
			if(offset >= 0x50000 && offset <= 0x600B0){
				if(offset >= 0x50000 && offset <= 0x50170){
					int index = (offset - 0x50000) >> 4;
					if(index & 0x1)
						gCPU.pic_ram.eidr[index >> 1] = data;
					else
						gCPU.pic_ram.eivpr[index >> 1] = data;
					return r;
				}
				if(offset >= 0x50200 && offset <= 0x505F0){
                                        int index = (offset - 0x50200) >> 4;
					return r;
                                }

                                switch(offset){
					case 0x60080:
                                                gCPU.pic_ram.ctpr0 = data;
                                                return r;

                                        default:
                                                fprintf(stderr,"in %s, error when write pic ram,offset=0x%x,pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);
						return r;
				}
                        }

			/**
			 * Interrupt Controller
			 */

			if(offset >= 0x90C00 && offset <= 0x90C7F){
                                switch(offset){
                                        case 0x90C08: /* W1C */
						gCPU.int_ctrl.sipnr_h &= ~data;
                                                return r;
					case 0x90C0C: /* W1C */
						gCPU.int_ctrl.sipnr_l &= ~data;
						return r;
					case 0x90C14:
						gCPU.int_ctrl.scprr_h = data;
						return r;
					case 0x90C18:
						gCPU.int_ctrl.scprr_l = data;
						return r;
					case 0x90C1C:
						gCPU.int_ctrl.simr_h = data;
						return r;
					case 0x90C20:
						gCPU.int_ctrl.simr_l = data;
						return r;
                                        default:
                                                fprintf(stderr,"in %s, error when write interrupt controller,offset=0x%x,pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);
                         	                return r;
				}
			}

			if(offset >= 0x919C0 && offset <= 0x919E0){
				switch(offset){
					case 0x919C0:
						gCPU.cpm_reg.cpcr = data;
						/* set FLG bit to zero, that means we are ready for new command*/
						/* get sub block code */
						if((0x1f & (gCPU.cpm_reg.cpcr >> 21)) == 0x4){
							;/* we */	
							if((0xf & gCPU.cpm_reg.cpcr) == 0x0){
							/* INIT Rx and Tx Param in SCC1 */
							}
						}
						gCPU.cpm_reg.cpcr &= ~(1 << 16);
						return r;
					default:
						fprintf(stderr,"in %s, error when write cpm,offset=0x%x,pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);
						return r;
				}
			}
			if(offset >= 0x91A00 && offset <= 0x91A3F){
                                int i = (0x20 & offset) >> 5;
                                offset = 0x1f & offset;
                                switch(offset){
                                        case 0x0:
                                                gCPU.cpm_reg.scc[i].gsmrl = data;
						if(gCPU.cpm_reg.scc[i].gsmrl & 0x00000020)
                                                        ; /* Enable Receive */
                                                if(gCPU.cpm_reg.scc[i].gsmrl & 0x00000010)
                                                        ; /* Enable Transmit */

                                                return r;
                                        case 0x4:
                                                gCPU.cpm_reg.scc[i].gsmrh = data;
                                                return r;
                                        case 0x8:
                                                gCPU.cpm_reg.scc[i].psmr = data;
                                                return r;
                                        case 0xE:
                                                gCPU.cpm_reg.scc[i].dsr = data;
                                                return r;
                                        case 0x14:
                                                gCPU.cpm_reg.scc[i].sccm = data;
                                                return r;

                                        case 0x10: /* W1C */
                                                gCPU.cpm_reg.scc[i].scce &= ~data;
                                                return r;
                                        default:
                                                fprintf(stderr,"in %s, error when read CCSR.offset=0x%x, \
                                pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);

                                                skyeye_exit(-1);

                                }
                        }

			/* CPM MUX I/O */
			if(offset >= 0x91B00 && offset <= 0x91B1F){
				switch(offset){
					case 0x91B04:
                                                gCPU.cpm_reg.mux.cmxfcr = data;
                                                return r;
                                        case 0x91B08:
                                                gCPU.cpm_reg.mux.cmxscr = data;
                                                return r;
                                        default:
                                                fprintf(stderr,"in %s, error when read CCSR.offset=0x%x, \
                                pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);

                                                skyeye_exit(-1);

                                }

			}
			/* Input/Output port */
                        if(offset >= 0x90D00 && offset <= 0x90D70){
                                switch(offset){
					case 0x90D00:
                                                gCPU.cpm_reg.ioport.pdira = data;
                                                return r;

                                        case 0x90D04:
                                                gCPU.cpm_reg.ioport.ppara = data;
                                                return r;
					case 0x90D08:
                                                gCPU.cpm_reg.ioport.psora = data;
                                                return r;
					case 0x90D0C:
						gCPU.cpm_reg.ioport.podra = data;
						return r;
					case 0x90D10:
                                                gCPU.cpm_reg.ioport.pdata = data;
                                                return r;
					case 0x90D20:
						gCPU.cpm_reg.ioport.pdirb = data;
						return r;
					case 0x90D24:
						gCPU.cpm_reg.ioport.pparb = data;
						return r;
					case 0x90D28:
						gCPU.cpm_reg.ioport.psorb = data;
						return r;
					case 0x90D40:
						gCPU.cpm_reg.ioport.pdirc = data;
						return r;
					case 0x90D44:
						gCPU.cpm_reg.ioport.pparc = data;
						return r;
					case 0x90D48:
						gCPU.cpm_reg.ioport.psorc = data;
						return r;
					case 0x90D60:
                                                gCPU.cpm_reg.ioport.pdird = data;
                                                return r;
                                        case 0x90D64:
                                                gCPU.cpm_reg.ioport.ppard = data;
                                                return r;
                                        case 0x90D68:
                                                gCPU.cpm_reg.ioport.psord = data;
                                                return r;

                                        default:
                                                fprintf(stderr,"in %s, error when write io port.offset=0x%x, \
                                pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);
						return r;
                                                //skyeye_exit(-1);

                                }

                        }
						/* BRG */
			if(offset >= 0x919F0 && offset <= 0x919FC){
				gCPU.cpm_reg.brgc[(offset - 0x919F0)/4] = data;
                                return r;

			}
			if(offset >= 0x80000 && offset < 0x8C000){
				 //fprintf(prof_file,"DBG_CPM:in %s,offset=0x%x,data=0x%x,pc=0x%x\n",__FUNCTION__, offset, data, gCPU.pc);

                                *((sint32 *)&gCPU.cpm_reg.dpram[offset - 0x80000]) = ppc_word_to_BE(data);
                                return r;
                        }
			if(offset >= 0x8C00 && offset <= 0x8DFC)
			{
				switch(offset){
				case 0x8C20:
					gCPU.pci_atmu.potar1 = data;
					return r;
				case 0x8C24:
					gCPU.pci_atmu.potear1 = data;
					return r;
				case 0x8C28:
					gCPU.pci_atmu.powbar1 = data;
					return r;
				case 0x8C2C:
					gCPU.pci_atmu.reserv1 = data;
					return r;
				case 0x8C30:
					gCPU.pci_atmu.powar1 = data;
					return r;
				default:
					fprintf(stderr,"in %s, error when write to PCI_ATMU.offset=0x%x,pc=0x%x\n",__FUNCTION__,offset,gCPU.pc);
					//skyeye_exit(-1);
					return r;
				}
			}
			if(offset >= 0x40000 && offset <= 0x4FFF0){
				switch(offset){
                                        case 0x41020:
                                                /* source a
ttribute register for DMA0 */
                                                gCPU.pic_global.gcr = data;
                                                return r;
					case 0x410e0:
						gCPU.pic_global.svr = data;
						return r;
					case 0x41120:
                                                gCPU.pic_global.gtvpr0 = data;
                                                return r;
					case 0x41130:
						gCPU.pic_global.gtdr0 = data;
						return r;
					case 0x41160:
						gCPU.pic_global.gtvpr1 = data;
						return r;
					case 0x41170:
						gCPU.pic_global.gtdr1 = data;		
						return r;
					case 0x411a0:
						gCPU.pic_global.gtvpr2 = data;
						return r;
					case 0x411B0:
						gCPU.pic_global.gtdr2 = data;
						return r;
					case 0x411E0:
						gCPU.pic_global.gtvpr3 = data;
						return r;
					case 0x411F0:
						gCPU.pic_global.gtdr3 = data;
						return r;
                                        default:
                                                fprintf(stderr,"in %s, error when write global.offset=0x%x,pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);
                                                return r;
                                                //skyeye_ex
it(-1);

                                }

			}

			switch(offset){
				case 0x0:
					gCPU.ccsr.ccsr = data;
					break;
				 case 0x90C80:
                                        gCPU.sccr = data;
                                        break;
				case 0x50D4:
                                        gCPU.lb_ctrl.lcrr = data;
                                        return r;
				case 0x3008:
					gCPU.i2c_reg.i2ccr = data;
					return r;
				case 0xe0e10:
                                        gCPU.debug_ctrl.ddrdllcr = data;
                                        return r;
				case 0x8000:
					gCPU.pci_cfg.cfg_addr = data;
					return r;
				case 0x8004:
                                        gCPU.pci_cfg.cfg_data = data;
                                        return r;

				default:
					fprintf(stderr,"in %s, error when write to CCSR.offset=0x%x,pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);
					//skyeye_exit(-1);
			}
		}
		else if((p >= boot_rom_start_addr) && (p < (boot_rom_start_addr + boot_romSize )))

                        *((int *)&boot_rom[p - boot_rom_start_addr]) = ppc_word_to_BE(data);
		else if((p >= init_ram_start_addr) && (p < (init_ram_start_addr + init_ram_size)))
			*((int *)&init_ram[p - init_ram_start_addr]) = ppc_word_to_BE(data);
		else if((p >= 0x0) && (p < (0x0 + DDR_RAM_SIZE))){
			*((int *)&ddr_ram[p]) = ppc_word_to_BE(data);
			}
                else{
                        fprintf(stderr,"in %s, can not find address 0x%x,pc=0x%x\n", __FUNCTION__, p, gCPU.pc);
                        //skyeye_exit(-1);
                }
	}
	return r;
}

int FASTCALL ppc_write_effective_half(uint32 addr, uint16 data)
{	
	uint32 p;
	int r;
	if (!((r=ppc_effective_to_physical(addr, PPC_MMU_WRITE, &p)))) {
		ppc_io_write_halfword (&gCPU, p, data);
		//printf("DBG:in %s,addr=0x%x,p=0x%x, data=0x%x\n", __FUNCTION__, addr,p, data);
		//printf("DBG:ccsr=0x%x,CCSR_BASE=0x%x",gCPU.ccsr.ccsr,GET_CCSR_BASE(gCPU.ccsr.ccsr));
		if(p >= GET_CCSR_BASE(gCPU.ccsr.ccsr) && p <(GET_CCSR_BASE(gCPU.ccsr.ccsr) + CCSR_MEM_SIZE)){
			int offset = p - GET_CCSR_BASE(gCPU.ccsr.ccsr);
			//printf("DBG:write to CCSR,value=0x%x,offset=0x%x,pc=0x%x\n", data, offset,gCPU.pc);
			if(offset >= 0xC08 && offset <= 0xCF0){
				if(offset & 0x8){
					gCPU.law.lawbar[(offset - 0xC08)/0x20] = data;
				}else{
					gCPU.law.lawar[(offset - 0xC10)/0x20] = data;
				}
				return r;
			}
			if(offset >= 0x5000 && offset <= 0x5038){
				gCPU.lb_ctrl.br[(offset - 0x5000)/0x8] = data;
				return r;
			}
			if(offset >= 0x91A00 && offset <= 0x91A3F){
				int i = (0x20 & offset) >> 5;
				offset = 0x1f & offset;
                                switch(offset){
                                        case 0x0:
                                                gCPU.cpm_reg.scc[i].gsmrl = data;
                                                return r;
					case 0x4:
						gCPU.cpm_reg.scc[i].gsmrh = data;
						return r;
					case 0x8:
						gCPU.cpm_reg.scc[i].psmr = data;
                                                return r;
					case 0xE:
						gCPU.cpm_reg.scc[i].dsr = data;
						return r;
					case 0x14:
						gCPU.cpm_reg.scc[i].sccm = data;
						return r;
						
					case 0x10: /* W1C */
						gCPU.cpm_reg.scc[i].scce &= ~data;
						return r;
                                        default:
                                                fprintf(stderr,"in %s, error when read CCSR.offset=0x%x, \
                                pc=0x%x\n",__FUNCTION__, offset, gCPU.pc);

                                                skyeye_exit(-1);

                                }
                        }
			if(offset >= 0x919C0 && offset <= 0x919E0){
				switch(offset){
					case 0x919C0:
						gCPU.cpm_reg.cpcr = data;
						return r;
					default:
                                        	fprintf(stderr,"in %s, error when write to CCSR.offset=0x%x,pc=0x%x\n",__FUNCTION__,offset,gCPU.pc);
                                        	//skyeye_exit(-1);

				}
			}
			if(offset >= 0x80000 && offset < 0x8C000){
				//fprintf(prof_file,"DBG_CPM:in %s,offset=0x%x,data=0x%x,pc=0x%x\n",__FUNCTION__, offset, data, gCPU.pc);
                                *((sint16 *)&gCPU.cpm_reg.dpram[offset - 0x80000]) = ppc_half_to_BE(data);
                                return r;
                        }

			switch(offset){
				case 0x0:
					gCPU.ccsr.ccsr = data;
					break;
				case 0x90C00:
					gCPU.int_ctrl.sicr = data;
					break;
				case 0x90C80:
                                        gCPU.sccr = data;
                                        break;
				case 0x8004:
					gCPU.pci_cfg.cfg_data = data;
					break;
				case 0x8006:
					gCPU.pci_cfg.cfg_data = data;
					break;
				default:
					fprintf(stderr,"in %s, error when write to CCSR.offset=0x%x,pc=0x%x\n",__FUNCTION__,offset,gCPU.pc);
					//skyeye_exit(-1);
			}
		}
		else if((p >= boot_rom_start_addr) && (p < (boot_rom_start_addr + boot_romSize )))

                        *((sint16 *)&boot_rom[p - boot_rom_start_addr]) = ppc_half_to_BE(data);
		else if((p >= init_ram_start_addr) && (p < (init_ram_start_addr + init_ram_size)))
			*((sint16 *)&init_ram[p - init_ram_start_addr]) = ppc_half_to_BE(data);
		else if((p >= 0x0) && (p < (0x0 + DDR_RAM_SIZE))){
                        *((sint16 *)&ddr_ram[p]) = ppc_half_to_BE(data);
		}
                else{
                        fprintf(stderr,"in %s, can not find address 0x%x,pc=0x%x\n", __FUNCTION__, p, gCPU.pc);
                        //skyeye_exit(-1);
                }
	}
	return r;
}

int FASTCALL ppc_write_effective_byte(uint32 addr, uint8 data)
{
	uint32 p;
        int r;
        if (!((r=ppc_effective_to_physical(addr, PPC_MMU_WRITE, &p)))) {
		ppc_io_write_byte (&gCPU, p, data);

                //printf("DBG:in %s,addr=0x%x,p=0x%x, data=0x%x, pc=0x%x\n", __FUNCTION__, addr,p, data, gCPU.pc);
                //printf("DBG:ccsr=0x%x,CCSR_BASE=0x%x",gCPU.ccsr.ccsr,GET_CCSR_BASE(gCPU.ccsr.ccsr));
                if(p >= GET_CCSR_BASE(gCPU.ccsr.ccsr) && p <(GET_CCSR_BASE(gCPU.ccsr.ccsr) + CCSR_MEM_SIZE)){
                        int offset = p - GET_CCSR_BASE(gCPU.ccsr.ccsr);
                        //printf("DBG:write to CCSR,value=0x%x,offset=0x%x\n", data, offset);
                        if(offset >= 0xC08 && offset <= 0xCF0){
                                if(offset & 0x8){
                                        gCPU.law.lawbar[(offset - 0xC08)/0x20] = data;
                                }else{
                                        gCPU.law.lawar[(offset - 0xC10)/0x20] = data;
                                }
                                return r;
                        }
			if(offset >= 0x80000 && offset < 0x8C000){                                                            
				 //fprintf(prof_file,"DBG_CPM:in %s,offset=0x%x,data=0x%x,pc=0x%x\n",__FUNCTION__, offset, data, gCPU.pc);

				*((byte *)&gCPU.cpm_reg.dpram[offset - 0x80000]) = data;
                                            return r;
                        }  
                        switch(offset){
                                case 0x0:
                                        gCPU.ccsr.ccsr = data;
                                        break;
				case 0x3000:
					gCPU.i2c_reg.i2cadr = data;
					return r;
				case 0x3004:
					gCPU.i2c_reg.i2cfdr = data;
					return r;
				case 0x3008:
                                        gCPU.i2c_reg.i2ccr = data;
                                        return r;
				case 0x300C:
					gCPU.i2c_reg.i2csr = data;
					return r;
				case 0x3010:
                                        gCPU.i2c_reg.i2cdr = data;
					/* set bit of MIF */
					gCPU.i2c_reg.i2csr |= 0x02;
                                        return r;
				case 0x3014:
					gCPU.i2c_reg.i2cdfsrr = data;
					return r;
				case 0x8004:
                                        gCPU.pci_cfg.cfg_data = data;
                                        return r;
				case 0x8005:
                                        gCPU.pci_cfg.cfg_data = data;
                                        return r;

                                default:
                                        fprintf(stderr,"in %s, error when write to CCSR.addr=0x%x,pc=0x%x\n",
__FUNCTION__,addr,gCPU.pc);
                                        skyeye_exit(-1);
                        }
                }
                else if((p >= boot_rom_start_addr) && (p < (boot_rom_start_addr + boot_romSize )))

                        *((byte *)&boot_rom[p - boot_rom_start_addr]) = data;
                else if((p >= init_ram_start_addr) && (p < (init_ram_start_addr + init_ram_size)))
                        *((byte *)&init_ram[p - init_ram_start_addr]) = data;
		else if((p >= 0x0) && (p < (0x0 + DDR_RAM_SIZE))){                         
			*((byte *)&ddr_ram[p]) = data;    
		}
                else{
                        fprintf(stderr,"in %s, can not find address 0x%x,pc=0x%x\n", __FUNCTION__, p, gCPU.pc
);
                        skyeye_exit(-1);
                }
        }
        return r;

}

void ppc_mmu_tlb_invalidate()
{
	gCPU.effective_code_page = 0xffffffff;
}

/*
pagetable:
min. 2^10 (64k) PTEGs
PTEG = 64byte
The page table can be any size 2^n where 16 <= n <= 25.

A PTEG contains eight
PTEs of eight bytes each; therefore, each PTEG is 64 bytes long.
*/

bool FASTCALL ppc_mmu_set_sdr1(uint32 newval, bool quiesce)
{
	/* if (newval == gCPU.sdr1)*/ quiesce = false;
	PPC_MMU_TRACE("new pagetable: sdr1 = 0x%08x\n", newval);
	uint32 htabmask = SDR1_HTABMASK(newval);
	uint32 x = 1;
	uint32 xx = 0;
	int n = 0;
	while ((htabmask & x) && (n < 9)) {
		n++;
		xx|=x;
		x<<=1;
	}
	if (htabmask & ~xx) {
		PPC_MMU_TRACE("new pagetable: broken htabmask (%05x)\n", htabmask);
		return false;
	}
	uint32 htaborg = SDR1_HTABORG(newval);
	if (htaborg & xx) {
		PPC_MMU_TRACE("new pagetable: broken htaborg (%05x)\n", htaborg);
		return false;
	}
	gCPU.pagetable_base = htaborg<<16;
	gCPU.sdr1 = newval;
	gCPU.pagetable_hashmask = ((xx<<10)|0x3ff);
	PPC_MMU_TRACE("new pagetable: sdr1 accepted\n");
	PPC_MMU_TRACE("number of pages: 2^%d pagetable_start: 0x%08x size: 2^%d\n", n+13, gCPU.pagetable_base, n+16);
	if (quiesce) {
		//prom_quiesce();
	}
	return true;
}

bool FASTCALL ppc_mmu_page_create(uint32 ea, uint32 pa)
{
	uint32 sr = gCPU.sr[EA_SR(ea)];
	uint32 page_index = EA_PageIndex(ea);  // 16 bit
	uint32 VSID = SR_VSID(sr);             // 24 bit
	uint32 api = EA_API(ea);               //  6 bit (part of page_index)
	uint32 hash1 = (VSID ^ page_index);
	uint32 pte, pte2;
	uint32 h = 0;
	int j;
	for (j=0; j<2; j++) {
		uint32 pteg_addr = ((hash1 & gCPU.pagetable_hashmask)<<6) | gCPU.pagetable_base;
		int i;
		for (i=0; i<8; i++) {
			if (ppc_read_physical_word(pteg_addr, &pte)) {
				PPC_MMU_ERR("read physical in address translate failed\n");
				return false;
			}
			if (!(pte & PTE1_V)) {
				// free pagetable entry found
				pte = PTE1_V | (VSID << 7) | h | api;
				pte2 = (PA_RPN(pa) << 12) | 0;
				if (ppc_write_physical_word(pteg_addr, pte)
				 || ppc_write_physical_word(pteg_addr+4, pte2)) {
					return false;
				} else {
					// ok
					return true;
				}
			}
			pteg_addr+=8;
		}
		hash1 = ~hash1;
		h = PTE1_H;
	}
	return false;
}

inline bool FASTCALL ppc_mmu_page_free(uint32 ea)
{
	return true;
}

inline int FASTCALL ppc_direct_physical_memory_handle(uint32 addr, byte *ptr)
{
	if (addr < boot_romSize) {
		ptr = &boot_rom[addr];
		return PPC_MMU_OK;
	}
	return PPC_MMU_FATAL;
}

int FASTCALL ppc_direct_effective_memory_handle(uint32 addr, byte *ptr)
{
	uint32 ea;
	int r;
	if (!((r = ppc_effective_to_physical(addr, PPC_MMU_READ, &ea)))) {
		return ppc_direct_physical_memory_handle(ea, ptr);
	}
	return r;
}

int FASTCALL ppc_direct_effective_memory_handle_code(uint32 addr, byte *ptr)
{
	uint32 ea;
	int r;
	if (!((r = ppc_effective_to_physical(addr, PPC_MMU_READ | PPC_MMU_CODE, &ea)))) {
		return ppc_direct_physical_memory_handle(ea, ptr);
	}
	return r;
}

inline int FASTCALL ppc_read_physical_qword(uint32 addr, Vector_t *result)
{
	if (addr < boot_romSize) {
		// big endian
		VECT_D(*result,0) = ppc_dword_from_BE(*((uint64*)(boot_rom+addr)));
		VECT_D(*result,1) = ppc_dword_from_BE(*((uint64*)(boot_rom+addr+8)));
		return PPC_MMU_OK;
	}
	return io_mem_read128(addr, (uint128 *)result);
}

inline int FASTCALL ppc_read_physical_dword(uint32 addr, uint64 *result)
{
	if (addr < boot_romSize) {
		// big endian
		*result = ppc_dword_from_BE(*((uint64*)(boot_rom+addr)));
		return PPC_MMU_OK;
	}
	int ret = io_mem_read64(addr, result);
	*result = ppc_bswap_dword(result);
	return ret;
}

int FASTCALL ppc_read_physical_word(uint32 addr, uint32 *result)
{
	if (addr < boot_romSize) {
		// big endian
		*result = ppc_word_from_BE(*((uint32*)(boot_rom+addr)));
		return PPC_MMU_OK;
	}
	int ret = io_mem_read(addr, result, 4);
	*result = ppc_bswap_word(result);
	return ret;
}

inline int FASTCALL ppc_read_physical_half(uint32 addr, uint16 *result)
{
	if (addr < boot_romSize) {
		// big endian
		*result = ppc_half_from_BE(*((uint16*)(boot_rom+addr)));
		return PPC_MMU_OK;
	}
	uint32 r;
	int ret = io_mem_read(addr, r, 2);
	*result = ppc_bswap_half(r);
	return ret;
}

inline int FASTCALL ppc_read_physical_byte(uint32 addr, uint8 *result)
{
	if (addr < boot_romSize) {
		// big endian
		*result = boot_rom[addr];
		return PPC_MMU_OK;
	}
	uint32 r;
	int ret = io_mem_read(addr, r, 1);
	*result = r;
	return ret;
}

inline int FASTCALL ppc_read_effective_code(uint32 addr, uint32 *result)
{
	if (addr & 3) {
		// EXC..bla
		return PPC_MMU_FATAL;
	}
	uint32 p;
	int r;
	if (!((r=ppc_effective_to_physical(addr, PPC_MMU_READ | PPC_MMU_CODE, &p)))) {
		return ppc_read_physical_word(p, result);
	}
	return r;
}

inline int FASTCALL ppc_read_effective_qword(uint32 addr, Vector_t *result)
{
	uint32 p;
	int r;

	addr &= ~0x0f;

	if (!(r = ppc_effective_to_physical(addr, PPC_MMU_READ, &p))) {
		return ppc_read_physical_qword(p, result);
	}

	return r;
}

inline int FASTCALL ppc_read_effective_dword(uint32 addr, uint64 *result)
{
	uint32 p;
	int r;
	if (!(r = ppc_effective_to_physical(addr, PPC_MMU_READ, &p))) {
#if 0
		if (EA_Offset(addr) > 4088) {
			// read overlaps two pages.. tricky
			byte *r1, *r2;
			byte b[14];
			ppc_effective_to_physical((addr & ~0xfff)+4089, PPC_MMU_READ, &p);
			if ((r = ppc_direct_physical_memory_handle(p, r1))) return r;
			if ((r = ppc_effective_to_physical((addr & ~0xfff)+4096, PPC_MMU_READ, &p))) return r;
			if ((r = ppc_direct_physical_memory_handle(p, r2))) return r;
			memmove(&b[0], r1, 7);
			memmove(&b[7], r2, 7);
			memmove(&result, &b[EA_Offset(addr)-4089], 8);
			result = ppc_dword_from_BE(result);
			return PPC_MMU_OK;
		} else {
			return ppc_read_physical_dword(p, result);
		}
#endif
	}
	return r;

}
inline int FASTCALL ppc_write_physical_qword(uint32 addr, Vector_t *data)
{
	if (addr < boot_romSize) {
		// big endian
		*((uint64*)(boot_rom+addr)) = ppc_dword_to_BE(VECT_D(*data,0));
		*((uint64*)(boot_rom+addr+8)) = ppc_dword_to_BE(VECT_D(*data,1));
		return PPC_MMU_OK;
	}
	if (io_mem_write128(addr, (uint128 *)data) == IO_MEM_ACCESS_OK) {
		return PPC_MMU_OK;
	} else {
		return PPC_MMU_FATAL;
	}
}

inline int FASTCALL ppc_write_physical_dword(uint32 addr, uint64 data)
{
	if (addr < boot_romSize) {
		// big endian
		*((uint64*)(boot_rom+addr)) = ppc_dword_to_BE(data);
		return PPC_MMU_OK;
	}
	if (io_mem_write64(addr, ppc_bswap_dword(data)) == IO_MEM_ACCESS_OK) {
		return PPC_MMU_OK;
	} else {
		return PPC_MMU_FATAL;
	}
}

inline int FASTCALL ppc_write_physical_word(uint32 addr, uint32 data)
{
	if (addr < boot_romSize) {
		// big endian
		*((uint32*)(boot_rom+addr)) = ppc_word_to_BE(data);
		return PPC_MMU_OK;
	}
	return io_mem_write(addr, ppc_bswap_word(data), 4);
}
inline int FASTCALL ppc_write_effective_qword(uint32 addr, Vector_t data)
{
	uint32 p;
	int r;

	addr &= ~0x0f;

	if (!((r=ppc_effective_to_physical(addr, PPC_MMU_WRITE, &p)))) {
		return ppc_write_physical_qword(p, &data);
	}
	return r;
}

inline int FASTCALL ppc_write_effective_dword(uint32 addr, uint64 data)
{
	uint32 p;
	int r;
	if (!((r=ppc_effective_to_physical(addr, PPC_MMU_WRITE, &p)))) {
		if (EA_Offset(addr) > 4088) {
			// write overlaps two pages.. tricky
			byte *r1, *r2;
			byte b[14];
			ppc_effective_to_physical((addr & ~0xfff)+4089, PPC_MMU_WRITE, &p);
			if ((r = ppc_direct_physical_memory_handle(p, r1))) return r;
			if ((r = ppc_effective_to_physical((addr & ~0xfff)+4096, PPC_MMU_WRITE, &p))) return r;
			if ((r = ppc_direct_physical_memory_handle(p, r2))) return r;
			data = ppc_dword_to_BE(data);
			memmove(&b[0], r1, 7);
			memmove(&b[7], r2, 7);
			memmove(&b[EA_Offset(addr)-4089], &data, 8);
			memmove(r1, &b[0], 7);
			memmove(r2, &b[7], 7);
			return PPC_MMU_OK;
		} else {
			return ppc_write_physical_dword(p, data);
		}
	}
	return r;
}
/***************************************************************************
 *	DMA Interface
 */

bool	ppc_dma_write(uint32 dest, const void *src, uint32 size)
{
	if (dest > boot_romSize || (dest+size) > boot_romSize) return false;
	
	byte *ptr;
	ppc_direct_physical_memory_handle(dest, ptr);
	
	memcpy(ptr, src, size);
	return true;
}

bool	ppc_dma_read(void *dest, uint32 src, uint32 size)
{
	if (src > boot_romSize || (src+size) > boot_romSize) return false;
	
	byte *ptr;
	ppc_direct_physical_memory_handle(src, ptr);
	
	memcpy(dest, ptr, size);
	return true;
}

bool	ppc_dma_set(uint32 dest, int c, uint32 size)
{
	if (dest > boot_romSize || (dest+size) > boot_romSize) return false;
	
	byte *ptr;
	ppc_direct_physical_memory_handle(dest, ptr);
	
	memset(ptr, c, size);
	return true;
}


/***************************************************************************
 *	DEPRECATED prom interface
 */
bool ppc_prom_set_sdr1(uint32 newval, bool quiesce)
{
	return ppc_mmu_set_sdr1(newval, quiesce);
}

bool ppc_prom_effective_to_physical(uint32 *result, uint32 ea)
{
	return ppc_effective_to_physical(ea, PPC_MMU_READ|PPC_MMU_SV|PPC_MMU_NO_EXC, result) == PPC_MMU_OK;
}

bool ppc_prom_page_create(uint32 ea, uint32 pa)
{
	uint32 sr = gCPU.sr[EA_SR(ea)];
	uint32 page_index = EA_PageIndex(ea);  // 16 bit
	uint32 VSID = SR_VSID(sr);             // 24 bit
	uint32 api = EA_API(ea);               //  6 bit (part of page_index)
	uint32 hash1 = (VSID ^ page_index);
	uint32 pte, pte2;
	uint32 h = 0;
	int j;
	for (j=0; j<2; j++) {
		uint32 pteg_addr = ((hash1 & gCPU.pagetable_hashmask)<<6) | gCPU.pagetable_base;
		int i;
		for (i=0; i<8; i++) {
			if (ppc_read_physical_word(pteg_addr, &pte)) {
				PPC_MMU_ERR("read physical in address translate failed\n");
				return false;
			}
			if (!(pte & PTE1_V)) {
				// free pagetable entry found
				pte = PTE1_V | (VSID << 7) | h | api;
				pte2 = (PA_RPN(pa) << 12) | 0;
				if (ppc_write_physical_word(pteg_addr, pte)
				 || ppc_write_physical_word(pteg_addr+4, pte2)) {
					return false;
				} else {
					// ok
					return true;
				}
			}
			pteg_addr+=8;
		}
		hash1 = ~hash1;
		h = PTE1_H;
	}
	return false;
}

bool ppc_prom_page_free(uint32 ea)
{
	return true;
}


/***************************************************************************
 *	MMU Opcodes
 */

#include "ppc_dec.h"

/*
 *	dcbz		Data Cache Clear to Zero
 *	.464
 */
void ppc_opc_dcbz()
{
#ifdef E500
	//printf("DBG:In %s, for e500,cache is not implemented.\n",__FUNCTION__);
        //PPC_L1_CACHE_LINE_SIZE
        int rA, rD, rB;
        PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
        // assert rD=0
        uint32 a = (rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB];
        // bytes of per Cache line is 32 bytes 
        int i = 0;
        for(; i < 32; i += 4)
                ppc_write_effective_word(a + i, 0);


#else
	//PPC_L1_CACHE_LINE_SIZE
	int rA, rD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
	// assert rD=0
	uint32 a = (rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB];
	// BAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	ppc_write_effective_dword(a, 0)
	|| ppc_write_effective_dword(a+8, 0)
	|| ppc_write_effective_dword(a+16, 0)
	|| ppc_write_effective_dword(a+24, 0);
#endif
}
void ppc_opc_dcbtls(){
#ifdef E500
        //printf("DBG:In %s, for e500,cache is not implemented.\n",__FUNCTION__);
#else
	fprintf(stderr,"In %s, cache is not implemented.\n",__FUNCTION__);
#endif

}

/*
 *	lbz		Load Byte and Zero
 *	.521
 */
void ppc_opc_lbz()
{
	int rA, rD;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rD, rA, imm);
	uint8 r;
	int ret = ppc_read_effective_byte((rA?gCPU.gpr[rA]:0)+imm, &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rD] = r;
	}
}
/*
 *	lbzu		Load Byte and Zero with Update
 *	.522
 */
void ppc_opc_lbzu()
{
	int rA, rD;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rD, rA, imm);
	// FIXME: check rA!=0 && rA!=rD
	uint8 r;
	int ret = ppc_read_effective_byte(gCPU.gpr[rA]+imm, &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += imm;
		gCPU.gpr[rD] = r;
	}	
}
/*
 *	lbzux		Load Byte and Zero with Update Indexed
 *	.523
 */
void ppc_opc_lbzux()
{
	int rA, rD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
	// FIXME: check rA!=0 && rA!=rD
	uint8 r;
	int ret = ppc_read_effective_byte(gCPU.gpr[rA]+gCPU.gpr[rB], &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += gCPU.gpr[rB];
		gCPU.gpr[rD] = r;
	}
}
/*
 *	lbzx		Load Byte and Zero Indexed
 *	.524
 */
void ppc_opc_lbzx()
{
	int rA, rD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
	uint8 r;
	int ret = ppc_read_effective_byte((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rD] = r;
	}
}
/*
 *	lfd		Load Floating-Point Double
 *	.530
 */
void ppc_opc_lfd()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frD;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, frD, rA, imm);
	uint64 r;
	int ret = ppc_read_effective_dword((rA?gCPU.gpr[rA]:0)+imm, &r);
	if (ret == PPC_MMU_OK) {
		gCPU.fpr[frD] = r;
	}	
}
/*
 *	lfdu		Load Floating-Point Double with Update
 *	.531
 */
void ppc_opc_lfdu()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frD;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, frD, rA, imm);
	// FIXME: check rA!=0
	uint64 r;
	int ret = ppc_read_effective_dword(gCPU.gpr[rA]+imm, &r);
	if (ret == PPC_MMU_OK) {
		gCPU.fpr[frD] = r;
		gCPU.gpr[rA] += imm;
	}	
}
/*
 *	lfdux		Load Floating-Point Double with Update Indexed
 *	.532
 */
void ppc_opc_lfdux()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, frD, rA, rB);
	// FIXME: check rA!=0
	uint64 r;
	int ret = ppc_read_effective_dword(gCPU.gpr[rA]+gCPU.gpr[rB], &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += gCPU.gpr[rB];
		gCPU.fpr[frD] = r;
	}	
}
/*
 *	lfdx		Load Floating-Point Double Indexed
 *	.533
 */
void ppc_opc_lfdx()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, frD, rA, rB);
	uint64 r;
	int ret = ppc_read_effective_dword((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], &r);
	if (ret == PPC_MMU_OK) {
		gCPU.fpr[frD] = r;
	}	
}
/*
 *	lfs		Load Floating-Point Single
 *	.534
 */
void ppc_opc_lfs()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frD;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, frD, rA, imm);
	uint32 r;
	int ret = ppc_read_effective_word((rA?gCPU.gpr[rA]:0)+imm, &r);
	if (ret == PPC_MMU_OK) {
		ppc_single s;
		ppc_double d;
		ppc_fpu_unpack_single(&s, r);
		ppc_fpu_single_to_double(&s, &d);
		ppc_fpu_pack_double(&d, &(gCPU.fpr[frD]));
	}	
}
/*
 *	lfsu		Load Floating-Point Single with Update
 *	.535
 */
void ppc_opc_lfsu()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frD;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, frD, rA, imm);
	// FIXME: check rA!=0
	uint32 r;
	int ret = ppc_read_effective_word(gCPU.gpr[rA]+imm, &r);
	if (ret == PPC_MMU_OK) {
		ppc_single s;
		ppc_double d;
		ppc_fpu_unpack_single(&s, r);
		ppc_fpu_single_to_double(&s, &d);
		ppc_fpu_pack_double(&d, &(gCPU.fpr[frD]));
		gCPU.gpr[rA] += imm;
	}	
}
/*
 *	lfsux		Load Floating-Point Single with Update Indexed
 *	.536
 */
void ppc_opc_lfsux()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, frD, rA, rB);
	// FIXME: check rA!=0
	uint32 r;
	int ret = ppc_read_effective_word(gCPU.gpr[rA]+gCPU.gpr[rB], &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += gCPU.gpr[rB];
		ppc_single s;
		ppc_double d;
		ppc_fpu_unpack_single(&s, r);
		ppc_fpu_single_to_double(&s, &d);
		ppc_fpu_pack_double(&d, &(gCPU.fpr[frD]));
	}	
}
/*
 *	lfsx		Load Floating-Point Single Indexed
 *	.537
 */
void ppc_opc_lfsx()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, frD, rA, rB);
	uint32 r;
	int ret = ppc_read_effective_word((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], &r);
	if (ret == PPC_MMU_OK) {
		ppc_single s;
		ppc_double d;
		ppc_fpu_unpack_single(&s, r);
		ppc_fpu_single_to_double(&s, &d);
		ppc_fpu_pack_double(&d, &(gCPU.fpr[frD]));
	}	
}
/*
 *	lha		Load Half Word Algebraic
 *	.538
 */
void ppc_opc_lha()
{
	int rA, rD;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rD, rA, imm);
	uint16 r;
	int ret = ppc_read_effective_half((rA?gCPU.gpr[rA]:0)+imm, &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rD] = (r&0x8000)?(r|0xffff0000):r;
	}
}
/*
 *	lhau		Load Half Word Algebraic with Update
 *	.539
 */
void ppc_opc_lhau()
{
	int rA, rD;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rD, rA, imm);
	uint16 r;
	// FIXME: rA != 0
	int ret = ppc_read_effective_half(gCPU.gpr[rA]+imm, &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += imm;
		gCPU.gpr[rD] = (r&0x8000)?(r|0xffff0000):r;
	}
}
/*
 *	lhaux		Load Half Word Algebraic with Update Indexed
 *	.540
 */
void ppc_opc_lhaux()
{
	int rA, rD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
	uint16 r;
	// FIXME: rA != 0
	int ret = ppc_read_effective_half(gCPU.gpr[rA]+gCPU.gpr[rB], &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += gCPU.gpr[rB];
		gCPU.gpr[rD] = (r&0x8000)?(r|0xffff0000):r;
	}
}
/*
 *	lhax		Load Half Word Algebraic Indexed
 *	.541
 */
void ppc_opc_lhax()
{
	int rA, rD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
	uint16 r;
	// FIXME: rA != 0
	int ret = ppc_read_effective_half((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rD] = (r&0x8000) ? (r|0xffff0000):r;
	}
}
/*
 *	lhbrx		Load Half Word Byte-Reverse Indexed
 *	.542
 */
void ppc_opc_lhbrx()
{
	int rA, rD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
	uint16 r;
	int ret = ppc_read_effective_half((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rD] = ppc_bswap_half(r);
	}
}
/*
 *	lhz		Load Half Word and Zero
 *	.543
 */
void ppc_opc_lhz()
{
	int rA, rD;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rD, rA, imm);
	uint16 r;
	int ret = ppc_read_effective_half((rA?gCPU.gpr[rA]:0)+imm, &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rD] = r;
	}
}
/*
 *	lhzu		Load Half Word and Zero with Update
 *	.544
 */
void ppc_opc_lhzu()
{
	int rA, rD;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rD, rA, imm);
	uint16 r;
	// FIXME: rA!=0
	int ret = ppc_read_effective_half(gCPU.gpr[rA]+imm, &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rD] = r;
		gCPU.gpr[rA] += imm;
	}
}
/*
 *	lhzux		Load Half Word and Zero with Update Indexed
 *	.545
 */
void ppc_opc_lhzux()
{
	int rA, rD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
	uint16 r;
	// FIXME: rA != 0
	int ret = ppc_read_effective_half(gCPU.gpr[rA]+gCPU.gpr[rB], &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += gCPU.gpr[rB];
		gCPU.gpr[rD] = r;
	}
}
/*
 *	lhzx		Load Half Word and Zero Indexed
 *	.546
 */
void ppc_opc_lhzx()
{
	int rA, rD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
	uint16 r;
	int ret = ppc_read_effective_half((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rD] = r;
	}
}
/*
 *	lmw		Load Multiple Word
 *	.547
 */
void ppc_opc_lmw()
{
	int rD, rA;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rD, rA, imm);
	uint32 ea = (rA ? gCPU.gpr[rA] : 0) + imm;
	while (rD <= 31) {
		if (ppc_read_effective_word(ea, &(gCPU.gpr[rD]))) {
			return;
		}
		rD++;
		ea += 4;
	}
}
/*
 *	lswi		Load String Word Immediate
 *	.548
 */
void ppc_opc_lswi()
{
	int rA, rD, NB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, NB);
	if (NB==0) NB=32;
	uint32 ea = rA ? gCPU.gpr[rA] : 0;
	uint32 r = 0;
	int i = 4;
	uint8 v;
	while (NB > 0) {
		if (!i) {
			i = 4;
			gCPU.gpr[rD] = r;
			rD++;
			rD%=32;
			r = 0;
		}
		if (ppc_read_effective_byte(ea, &v)) {
			return;
		}
		r<<=8;
		r|=v;
		ea++;
		i--;
		NB--;
	}
	while (i) { r<<=8; i--; }
	gCPU.gpr[rD] = r;
}
/*
 *	lswx		Load String Word Indexed
 *	.550
 */
void ppc_opc_lswx()
{
	int rA, rD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
	int NB = XER_n(gCPU.xer);
	uint32 ea = gCPU.gpr[rB] + (rA ? gCPU.gpr[rA] : 0);

	uint32 r = 0;
	int i = 4;
	uint8 v;
	while (NB > 0) {
		if (!i) {
			i = 4;
			gCPU.gpr[rD] = r;
			rD++;
			rD%=32;
			r = 0;
		}
		if (ppc_read_effective_byte(ea, &v)) {
			return;
		}
		r<<=8;
		r|=v;
		ea++;
		i--;
		NB--;
	}
	while (i) { r<<=8; i--; }
	gCPU.gpr[rD] = r;
}
/*
 *	lwarx		Load Word and Reserve Indexed
 *	.553
 */
void ppc_opc_lwarx()
{
	int rA, rD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
	uint32 r;
	int ret = ppc_read_effective_word((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rD] = r;
		gCPU.reserve = r;
		gCPU.have_reservation = 1;
	}
}
/*
 *	lwbrx		Load Word Byte-Reverse Indexed
 *	.556
 */
void ppc_opc_lwbrx()
{
	int rA, rD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
	uint32 r;
	int ret = ppc_read_effective_word((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rD] = ppc_bswap_word(r);
	}
}
/*
 *	lwz		Load Word and Zero
 *	.557
 */
void ppc_opc_lwz()
{
	int rA, rD;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rD, rA, imm);
	uint32 r;

	int ret = ppc_read_effective_word((rA?gCPU.gpr[rA]:0)+imm, &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rD] = r;
	}	

}
/*
 *	lbzu		Load Word and Zero with Update
 *	.558
 */
void ppc_opc_lwzu()
{
	int rA, rD;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rD, rA, imm);
	// FIXME: check rA!=0 && rA!=rD
	uint32 r;
	int ret = ppc_read_effective_word(gCPU.gpr[rA]+imm, &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += imm;
		gCPU.gpr[rD] = r;
	}	
}
/*
 *	lwzux		Load Word and Zero with Update Indexed
 *	.559
 */
void ppc_opc_lwzux()
{
	int rA, rD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
	// FIXME: check rA!=0 && rA!=rD
	uint32 r;
	int ret = ppc_read_effective_word(gCPU.gpr[rA]+gCPU.gpr[rB], &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += gCPU.gpr[rB];
		gCPU.gpr[rD] = r;
	}
}
/*
 *	lwzx		Load Word and Zero Indexed
 *	.560
 */
void ppc_opc_lwzx()
{
	int rA, rD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
	uint32 r;
	int ret = ppc_read_effective_word((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], &r);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rD] = r;
	}
}

/*      lvx	     Load Vector Indexed
 *      v.127
 */
void ppc_opc_lvx()
{
#ifndef __VEC_EXC_OFF__
	if ((gCPU.msr & MSR_VEC) == 0) {
		ppc_exception(PPC_EXC_NO_VEC, 0, 0);
		return;
	}
#endif
	VECTOR_DEBUG;
	int rA, vrD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, vrD, rA, rB);
	Vector_t r;

	int ea = ((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB]);

	int ret = ppc_read_effective_qword(ea, &r);
	if (ret == PPC_MMU_OK) {
		gCPU.vr[vrD] = r;
	}
}

/*      lvxl	    Load Vector Index LRU
 *      v.128
 */
void ppc_opc_lvxl()
{
	ppc_opc_lvx();
	/* This instruction should hint to the cache that the value won't be
	 *   needed again in memory anytime soon.  We don't emulate the cache,
	 *   so this is effectively exactly the same as lvx.
	 */
}

/*      lvebx	   Load Vector Element Byte Indexed
 *      v.119
 */
void ppc_opc_lvebx()
{
#ifndef __VEC_EXC_OFF__
	if ((gCPU.msr & MSR_VEC) == 0) {
		ppc_exception(PPC_EXC_NO_VEC, 0, 0);
		return;
	}
#endif
	VECTOR_DEBUG;
	int rA, vrD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, vrD, rA, rB);
	uint32 ea;
	uint8 r;
	ea = (rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB];
	int ret = ppc_read_effective_byte(ea, &r);
	if (ret == PPC_MMU_OK) {
		VECT_B(gCPU.vr[vrD], ea & 0xf) = r;
	}
}

/*      lvehx	   Load Vector Element Half Word Indexed
 *      v.121
 */
void ppc_opc_lvehx()
{
#ifndef __VEC_EXC_OFF__
	if ((gCPU.msr & MSR_VEC) == 0) {
		ppc_exception(PPC_EXC_NO_VEC, 0, 0);
		return;
	}
#endif
	VECTOR_DEBUG;
	int rA, vrD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, vrD, rA, rB);
	uint32 ea;
	uint16 r;
	ea = ((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB]) & ~1;
	int ret = ppc_read_effective_half(ea, &r);
	if (ret == PPC_MMU_OK) {
		VECT_H(gCPU.vr[vrD], (ea & 0xf) >> 1) = r;
	}
}

/*      lvewx	   Load Vector Element Word Indexed
 *      v.122
 */
void ppc_opc_lvewx()
{
#ifndef __VEC_EXC_OFF__
	if ((gCPU.msr & MSR_VEC) == 0) {
		ppc_exception(PPC_EXC_NO_VEC, 0, 0);
		return;
	}
#endif
	VECTOR_DEBUG;
	int rA, vrD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, vrD, rA, rB);
	uint32 ea;
	uint32 r;
	ea = ((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB]) & ~3;
	int ret = ppc_read_effective_word(ea, &r);
	if (ret == PPC_MMU_OK) {
		VECT_W(gCPU.vr[vrD], (ea & 0xf) >> 2) = r;
	}
}

#if HOST_ENDIANESS == HOST_ENDIANESS_LE
static byte lvsl_helper[] = {
	0x1F, 0x1E, 0x1D, 0x1C, 0x1B, 0x1A, 0x19, 0x18,
	0x17, 0x16, 0x15, 0x14, 0x13, 0x12, 0x11, 0x10,
	0x0F, 0x0E, 0x0D, 0x0C, 0x0B, 0x0A, 0x09, 0x08,
	0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0x00
};
#elif HOST_ENDIANESS == HOST_ENDIANESS_BE
static byte lvsl_helper[] = {
	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
	0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
	0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
	0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F
};
#else
#error Endianess not supported!
#endif

/*
 *      lvsl	    Load Vector for Shift Left
 *      v.123
 */
void ppc_opc_lvsl()
{
#ifndef __VEC_EXC_OFF__
	if ((gCPU.msr & MSR_VEC) == 0) {
		ppc_exception(PPC_EXC_NO_VEC, 0, 0);
		return;
	}
#endif
	VECTOR_DEBUG;
	int rA, vrD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, vrD, rA, rB);
	uint32 ea;
	ea = ((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB]);
#if HOST_ENDIANESS == HOST_ENDIANESS_LE
	memmove(&gCPU.vr[vrD], lvsl_helper+0x10-(ea & 0xf), 16);
#elif HOST_ENDIANESS == HOST_ENDIANESS_BE
	memmove(&gCPU.vr[vrD], lvsl_helper+(ea & 0xf), 16);
#else
#error Endianess not supported!
#endif
}

/*
 *      lvsr	    Load Vector for Shift Right
 *      v.125
 */
void ppc_opc_lvsr()
{
#ifndef __VEC_EXC_OFF__
	if ((gCPU.msr & MSR_VEC) == 0) {
		ppc_exception(PPC_EXC_NO_VEC, 0, 0);
		return;
	}
#endif
	VECTOR_DEBUG;
	int rA, vrD, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, vrD, rA, rB);
	uint32 ea;
	ea = ((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB]);
#if HOST_ENDIANESS == HOST_ENDIANESS_LE
	memmove(&gCPU.vr[vrD], lvsl_helper+(ea & 0xf), 16);
#elif HOST_ENDIANESS == HOST_ENDIANESS_BE
	memmove(&gCPU.vr[vrD], lvsl_helper+0x10-(ea & 0xf), 16);
#else
#error Endianess not supported!
#endif
}

/*
 *      dst	     Data Stream Touch
 *      v.115
 */
void ppc_opc_dst()
{
	VECTOR_DEBUG;
	/* Since we are not emulating the cache, this is a nop */
}

/*
 *	stb		Store Byte
 *	.632
 */
void ppc_opc_stb()
{
	int rA, rS;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rS, rA, imm);
	ppc_write_effective_byte((rA?gCPU.gpr[rA]:0)+imm, (uint8)gCPU.gpr[rS]) != PPC_MMU_FATAL;
}
/*
 *	stbu		Store Byte with Update
 *	.633
 */
void ppc_opc_stbu()
{
	int rA, rS;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rS, rA, imm);
	// FIXME: check rA!=0
	int ret = ppc_write_effective_byte(gCPU.gpr[rA]+imm, (uint8)gCPU.gpr[rS]);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += imm;
	}
}
/*
 *	stbux		Store Byte with Update Indexed
 *	.634
 */
void ppc_opc_stbux()
{
	int rA, rS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rS, rA, rB);
	// FIXME: check rA!=0
	int ret = ppc_write_effective_byte(gCPU.gpr[rA]+gCPU.gpr[rB], (uint8)gCPU.gpr[rS]);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += gCPU.gpr[rB];
	}
}
/*
 *	stbx		Store Byte Indexed
 *	.635
 */
void ppc_opc_stbx()
{
	int rA, rS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rS, rA, rB);
	ppc_write_effective_byte((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], (uint8)gCPU.gpr[rS]) != PPC_MMU_FATAL;
}
/*
 *	stfd		Store Floating-Point Double
 *	.642
 */
void ppc_opc_stfd()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frS;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, frS, rA, imm);
	ppc_write_effective_dword((rA?gCPU.gpr[rA]:0)+imm, gCPU.fpr[frS]) != PPC_MMU_FATAL;
}
/*
 *	stfdu		Store Floating-Point Double with Update
 *	.643
 */
void ppc_opc_stfdu()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU ,0 ,0);
		return;
	}
	int rA, frS;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, frS, rA, imm);
	// FIXME: check rA!=0
	int ret = ppc_write_effective_dword(gCPU.gpr[rA]+imm, gCPU.fpr[frS]);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += imm;
	}
}
/*
 *	stfd		Store Floating-Point Double with Update Indexed
 *	.644
 */
void ppc_opc_stfdux()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, frS, rA, rB);
	// FIXME: check rA!=0
	int ret = ppc_write_effective_dword(gCPU.gpr[rA]+gCPU.gpr[rB], gCPU.fpr[frS]);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += gCPU.gpr[rB];
	}
}
/*
 * tlbivax	TLB invalidated virtual address indexed
 * .786
 */
void ppc_opc_tlbivax()
{
	int rA, rD, rB;
        PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
	int i = 0,j = 0;
	uint32 mask;
	ppc_tlb_entry_t *entry;
	int tlb1_index;
	uint32 addr;
	if(rA) 
		addr = gCPU.gpr[rA]+gCPU.gpr[rB];
	else
		addr = gCPU.gpr[rB];
	//printf("In %s,addr=0x%x,pc=0x%x\n", __FUNCTION__,  addr, gCPU.pc);
	/* check if IA bit is set */
	if(addr & 0x4){
		int i,j;
		/* Now we only have TLB0 and TLB1 */
		if((addr >> 3) & 0x3 > 1)
			return;
		if((addr >> 3) & 0x3){
			for(j = 0; j < L2_TLB1_SIZE; j++)
		                if(!l2_tlb1_vsp[j].iprot)
                		        l2_tlb1_vsp[j].v = 0;

		}
		else{
			for(i = 0; i < L2_TLB0_SIZE; i++)
		                if(!l2_tlb0_4k[i].iprot)
                		        l2_tlb0_4k[i].v = 0;
		}
		return;
	}
	/* walk over tlb0 and tlb1 to find the entry */
	while(i++ < (L2_TLB0_SIZE + L2_TLB1_SIZE)){
		if(i > (L2_TLB0_SIZE - 1)){
			tlb1_index = i - L2_TLB0_SIZE;
			entry = &l2_tlb1_vsp[tlb1_index];
		}
		else
			entry = &l2_tlb0_4k[i];
		/* check if entry is protected. */
		if(entry->iprot)
			continue;
		/* FIXME, not check ts bit now */
		if(entry->ts & 0x0)
			continue;
		if(entry->tid != 0){
			if(e500_mmu.pid[0] != entry->tid)
				continue;
		}
		if(i > (L2_TLB0_SIZE - 1)){
			int k,s = 1;
			for(k = 0; k < entry->size; k++)
				s = s * 4; 
			mask = ~((1024 * (s - 1) - 0x1) + 1024);
		}
		else
			mask = ~(1024 * 4 - 0x1);
		if(entry->size != 0xb){
			if((addr & mask) != ((entry->epn << 12) & mask))
				continue;
		}
		else {/*if 4G size is mapped, we will not do address check */
			//fprintf(stderr,"warning:4G address is used.\n");
			if(addr < (entry->epn << 12))
				continue;

		}
		//printf("In %s,found ,offset = 0x%x,addr=0x%x,pc=0x%x\n", __FUNCTION__, i, addr, gCPU.pc);
		entry->v = 0;
	}
}
/*
 * tlbwe TLB write entry
 * .978
 */
/*
 * Fixme, now only support e500
 */
void ppc_opc_tlbwe()
{
	ppc_tlb_entry_t * entry;	
	int offset;
	if(TLBSEL(e500_mmu.mas[0]) == 0x0){
		offset = ((ESEL(e500_mmu.mas[0]) & 0xC) << 4) | (EPN(e500_mmu.mas[2]) & 0x3f);
		/* Fixme: we just implement a simple round-robin replace for TLB0. that is not as described in manual of e500 */
		#if 0
		static int tlb0_nv = 0;
		//offset = ((tlb0_nv & 0x1) << 7) | (EPN(e500_mmu.mas[2]) & 0x7f);
		offset = tlb0_nv++;
		if(tlb0_nv == 0xff)
			tlb0_nv = 0;
		#endif
		if(offset >= L2_TLB0_SIZE){
			fprintf(stderr, "Out of TLB size..\n");
			skyeye_exit(-1);
		}
		else{
			entry = &l2_tlb0_4k[0 + offset];
			/* update TLB0[NV] with MAS0[NV] */
			e500_mmu.tlb0_nv = e500_mmu.mas[0] & 0x1; 
		}
	}
	else{
		offset = ESEL(e500_mmu.mas[0]);
		if(offset >= L2_TLB1_SIZE){
                        fprintf(stderr, "Out of TLB size..\n");
			skyeye_exit(-1);
                }
                else
			entry = &l2_tlb1_vsp[0 + offset];
	}
	entry->v = e500_mmu.mas[1] >> 31;
	entry->iprot = (e500_mmu.mas[1] >> 30) & 0x1;
	entry->ts = (e500_mmu.mas[1] >> 12) & 0x1;
	entry->tid = (e500_mmu.mas[1] >> 16) & 0xFF;
	entry->size = (e500_mmu.mas[1] >> 8) & 0xF;
	entry->wimge = (e500_mmu.mas[2] & 0x1F);
	entry->x = (e500_mmu.mas[2] >> 5) & 0x3;
	entry->epn = (e500_mmu.mas[2] >> 12) & 0xFFFFF;
	entry->usxrw = e500_mmu.mas[3] & 0x3F;
	entry->u = (e500_mmu.mas[3]) >> 6 & 0xF;
	entry->rpn = (e500_mmu.mas[3] >> 12) & 0xFFFFF;
	e500_mmu.tlb0_nv = e500_mmu.mas[0] & 0x3;
	//printf("In %s, rpn=0x%x, epn=0x%x, offset=0x%x, tid=0x%x, mas2=0x%x\n", __FUNCTION__, entry->rpn, entry->epn, offset, entry->tid, e500_mmu.mas[2]);
	//printf("In %s, e500_mmu.tlb0_nv=0x%x\n", __FUNCTION__, e500_mmu.tlb0_nv);
	//printf("In %s, rpn=0x%x, epn=0x%x, offset=0x%x,usxrw=0x%x,tid=0x%x,pc=0x%x\n", __FUNCTION__, entry->rpn, entry->epn, offset, entry->usxrw, entry->tid ,gCPU.pc);
}

void ppc_opc_tlbsx(){
	ppc_tlb_entry_t *entry;
        int tlb1_index;
	int va,ea;
	int mask;
        int i = 0;
	int rA, rD, rB;
        PPC_OPC_TEMPL_X(gCPU.current_opc, rD, rA, rB);
	ea = gCPU.gpr[rB];
        /* walk over tlb0 and tlb1 to find the entry */

	//printf("In %s, ea=0x%x\n", __FUNCTION__, ea);
	while(i++ < (L2_TLB0_SIZE + L2_TLB1_SIZE)){
        	if(i > (L2_TLB0_SIZE - 1)){
                	tlb1_index = i - L2_TLB0_SIZE;
                	entry = &l2_tlb1_vsp[tlb1_index];
                }
                else
                        entry = &l2_tlb0_4k[i];
                if(!entry->v)
                        continue;
                /* FIXME, not check ts bit now */
                if(entry->ts & 0x0)
                        continue;
		if(entry->tid != 0 && entry->tid != ((e500_mmu.mas[6] & 0xFF0000) >> 16)){
                                continue;
                }
		//printf("In %s,entry->tid=0x%x,mas[6]=0x%x\n", __FUNCTION__, entry->tid, e500_mmu.mas[6]);
		if(i > (L2_TLB0_SIZE - 1)){
                        int k,s = 1;
                        for(k = 0; k < entry->size; k++)
                                s = s * 4;
                        mask = ~(1024 * s - 0x1);
                }
                else
                        mask = ~(1024 * 4 - 0x1);
		/* we found the entry */
		if((ea & mask) == (entry->epn << 12)){
			//printf("In %s, found entry,i=0x%x entry->usxrw=0x%x,entry->rpn=0x%x, pc=0x%x\n", __FUNCTION__, i, entry->usxrw, entry->rpn, gCPU.pc);
			if(i > (L2_TLB0_SIZE - 1)){
				e500_mmu.mas[0] |= (0x1 << 28);
				e500_mmu.mas[0] |= (e500_mmu.mas[0] & 0xFFF0FFFF) | ((tlb1_index & 0xC) << 16) ;
				e500_mmu.mas[2] = (e500_mmu.mas[2] & 0xFFFFF000) | (entry->epn << 12);
                                /* set v bit to one */
                                //e500_mmu.mas[1] &= 0x80000000;

                                e500_mmu.mas[3] = (e500_mmu.mas[3] & 0xFFFFFFC0) | entry->usxrw;
                                e500_mmu.mas[3] = (e500_mmu.mas[3] & 0xFFF) | (entry->rpn << 12);

			}
        	        else{
				e500_mmu.mas[0] &= ~(0x1 << 28);
				e500_mmu.mas[0] = (e500_mmu.mas[0] & 0xFFFFFFFC) | (e500_mmu.tlb0_nv & 0x3);
				/* fill ESEL */
				e500_mmu.mas[0] = (e500_mmu.mas[0] & 0xFFF0FFFF) | (((i & 0xC0) >> 4)  << 16);
				e500_mmu.mas[2] = (e500_mmu.mas[2] & 0xFFFFF000) | (entry->epn << 12);
				/* set v bit to one */
				//e500_mmu.mas[1] &= 0x80000000;
				
				e500_mmu.mas[3] = (e500_mmu.mas[3] & 0xFFFFFFC0) | entry->usxrw;
				e500_mmu.mas[3] = (e500_mmu.mas[3] & 0xFFF) | (entry->rpn << 12);
			}
			e500_mmu.mas[1] = (e500_mmu.mas[1] & 0xFF0000) | (entry->tid << 16);
			e500_mmu.mas[1] |= 0x80000000;
			//printf("In %s,mas3=0x%x\n", __FUNCTION__, e500_mmu.mas[3]);
			break;
		}
	}
	//printf("In %s, missing\n", __FUNCTION__);
}

void ppc_opc_tlbrehi(){
	ppc_tlb_entry_t * entry;
        int offset;
        if(TLBSEL(e500_mmu.mas[0]) == 0x0){
                offset = ((ESEL(e500_mmu.mas[0]) & 0xC) << 4) | (EPN(e500_mmu.mas[2]) & 0x3f);
                if(offset > L2_TLB0_SIZE){
                        fprintf(stderr, "Out of TLB size..\n");
                        skyeye_exit(-1);
                }
                else
                        entry = &l2_tlb0_4k[0 + offset];
		e500_mmu.mas[0] = (e500_mmu.mas[0] & 0xFFFFFFFC) | (e500_mmu.tlb0_nv & 0x3);
        }
        else{
                offset = ESEL(e500_mmu.mas[0]);
                if(offset > L2_TLB1_SIZE){
                        fprintf(stderr, "Out of TLB size..\n");
                        skyeye_exit(-1);
                }
                else
                        entry = &l2_tlb1_vsp[0 + offset];
        }
	e500_mmu.mas[1] = (e500_mmu.mas[1] & 0x7FFFFFFF) | (entry->v << 31);
	e500_mmu.mas[1] = (e500_mmu.mas[1] & 0xbFFFFFFF) | (entry->iprot << 30);
	e500_mmu.mas[1] = (e500_mmu.mas[1] & 0xFFFFEFFF) | (entry->ts << 12);
	e500_mmu.mas[1] = (e500_mmu.mas[1] & 0xFF00FFFF) | (entry->tid << 16);
	e500_mmu.mas[1] = (e500_mmu.mas[1] & 0xFFFFF0FF) | (entry->size << 8);
	e500_mmu.mas[2] = (e500_mmu.mas[2] & 0xFFFFFFE0) | (entry->wimge);
	e500_mmu.mas[2] = (e500_mmu.mas[2] & 0xFFFFFF9F) | (entry->x << 5);

	e500_mmu.mas[2] = (e500_mmu.mas[2] & 0xFFF) | (entry->epn << 12);

	e500_mmu.mas[3] = (e500_mmu.mas[3] & 0xFFFFFFC0) | (entry->usxrw);

	e500_mmu.mas[3] = (e500_mmu.mas[3] & 0xFFFFFFC3F) | (entry->u << 6);
	e500_mmu.mas[3] = (e500_mmu.mas[3] & 0xFFF) | (entry->rpn << 12);

}
/*
 *	stfdx		Store Floating-Point Double Indexed
 *	.645
 */
void ppc_opc_stfdx()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, frS, rA, rB);
	ppc_write_effective_dword((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], gCPU.fpr[frS]) != PPC_MMU_FATAL;
}
/*
 *	stfiwx		Store Floating-Point as Integer Word Indexed
 *	.646
 */
void ppc_opc_stfiwx()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, frS, rA, rB);
	ppc_write_effective_word((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], (uint32)gCPU.fpr[frS]) != PPC_MMU_FATAL;
}
/*
 *	stfs		Store Floating-Point Single
 *	.647
 */
void ppc_opc_stfs()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frS;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, frS, rA, imm);
	uint32 s;
	ppc_double d;
	ppc_fpu_unpack_double(&d, gCPU.fpr[frS]);
	ppc_fpu_pack_single(&d, &s);
	ppc_write_effective_word((rA?gCPU.gpr[rA]:0)+imm, s) != PPC_MMU_FATAL;
}
/*
 *	stfsu		Store Floating-Point Single with Update
 *	.648
 */
void ppc_opc_stfsu()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frS;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, frS, rA, imm);
	// FIXME: check rA!=0
	uint32 s;
	ppc_double d;
	ppc_fpu_unpack_double(&d, gCPU.fpr[frS]);
	ppc_fpu_pack_single(&d, &s);
	int ret = ppc_write_effective_word(gCPU.gpr[rA]+imm, s);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += imm;
	}
}
/*
 *	stfsux		Store Floating-Point Single with Update Indexed
 *	.649
 */
void ppc_opc_stfsux()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, frS, rA, rB);
	// FIXME: check rA!=0
	uint32 s;
	ppc_double d;
	ppc_fpu_unpack_double(&d, gCPU.fpr[frS]);
	ppc_fpu_pack_single(&d, &s);
	int ret = ppc_write_effective_word(gCPU.gpr[rA]+gCPU.gpr[rB], s);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += gCPU.gpr[rB];
	}
}
/*
 *	stfsx		Store Floating-Point Single Indexed
 *	.650
 */
void ppc_opc_stfsx()
{
	if ((gCPU.msr & MSR_FP) == 0) {
		ppc_exception(PPC_EXC_NO_FPU, 0, 0);
		return;
	}
	int rA, frS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, frS, rA, rB);
	uint32 s;
	ppc_double d;
	ppc_fpu_unpack_double(&d, gCPU.fpr[frS]);
	ppc_fpu_pack_single(&d, &s);
	ppc_write_effective_word((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], s) != PPC_MMU_FATAL;
}
/*
 *	sth		Store Half Word
 *	.651
 */
void ppc_opc_sth()
{
	int rA, rS;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rS, rA, imm);
	ppc_write_effective_half((rA?gCPU.gpr[rA]:0)+imm, (uint16)gCPU.gpr[rS]) != PPC_MMU_FATAL;
	/*if(gCPU.pc >= 0xfff830e4 && gCPU.pc <= 0xfff83254)
		fprintf(prof_file, "DBG:in %s,pc=0x%x\n", __FUNCTION__, gCPU.pc);
	*/
}
/*
 *	sthbrx		Store Half Word Byte-Reverse Indexed
 *	.652
 */
void ppc_opc_sthbrx()
{
	int rA, rS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rS, rA, rB);
	ppc_write_effective_half((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], ppc_bswap_half(gCPU.gpr[rS])) != PPC_MMU_FATAL;
}
/*
 *	sthu		Store Half Word with Update
 *	.653
 */
void ppc_opc_sthu()
{
	int rA, rS;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rS, rA, imm);
	// FIXME: check rA!=0
	int ret = ppc_write_effective_half(gCPU.gpr[rA]+imm, (uint16)gCPU.gpr[rS]);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += imm;
	}
}
/*
 *	sthux		Store Half Word with Update Indexed
 *	.654
 */
void ppc_opc_sthux()
{
	int rA, rS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rS, rA, rB);
	// FIXME: check rA!=0
	int ret = ppc_write_effective_half(gCPU.gpr[rA]+gCPU.gpr[rB], (uint16)gCPU.gpr[rS]);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += gCPU.gpr[rB];
	}
}
/*
 *	sthx		Store Half Word Indexed
 *	.655
 */
void ppc_opc_sthx()
{
	int rA, rS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rS, rA, rB);
	ppc_write_effective_half((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], (uint16)gCPU.gpr[rS]) != PPC_MMU_FATAL;
}
/*
 *	stmw		Store Multiple Word
 *	.656
 */
void ppc_opc_stmw()
{
	int rS, rA;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rS, rA, imm);
	uint32 ea = (rA ? gCPU.gpr[rA] : 0) + imm;
	while (rS <= 31) {
		if (ppc_write_effective_word(ea, gCPU.gpr[rS])) {
			return;
		}
		rS++;
		ea += 4;
	}
}
/*
 *	stswi		Store String Word Immediate
 *	.657
 */
void ppc_opc_stswi()
{
	int rA, rS, NB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rS, rA, NB);
	if (NB==0) NB=32;
	uint32 ea = rA ? gCPU.gpr[rA] : 0;
	uint32 r = 0;
	int i = 0;
	
	while (NB > 0) {
		if (!i) {
			r = gCPU.gpr[rS];
			rS++;
			rS%=32;
			i = 4;
		}
		if (ppc_write_effective_byte(ea, (r>>24))) {
			return;
		}
		r<<=8;
		ea++;
		i--;
		NB--;
	}
}
/*
 *	stswx		Store String Word Indexed
 *	.658
 */
void ppc_opc_stswx()
{
	int rA, rS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rS, rA, rB);
	int NB = XER_n(gCPU.xer);
	uint32 ea = gCPU.gpr[rB] + (rA ? gCPU.gpr[rA] : 0);
	uint32 r = 0;
	int i = 0;
	
	while (NB > 0) {
		if (!i) {
			r = gCPU.gpr[rS];
			rS++;
			rS%=32;
			i = 4;
		}
		if (ppc_write_effective_byte(ea, (r>>24))) {
			return;
		}
		r<<=8;
		ea++;
		i--;
		NB--;
	}
}
/*
 *	stw		Store Word
 *	.659
 */
void ppc_opc_stw()
{
	int rA, rS;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rS, rA, imm);
	ppc_write_effective_word((rA?gCPU.gpr[rA]:0)+imm, gCPU.gpr[rS]) != PPC_MMU_FATAL;
}
/*
 *	stwbrx		Store Word Byte-Reverse Indexed
 *	.660
 */
void ppc_opc_stwbrx()
{
	int rA, rS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rS, rA, rB);
	// FIXME: doppelt gemoppelt
	ppc_write_effective_word((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], ppc_bswap_word(gCPU.gpr[rS])) != PPC_MMU_FATAL;
}
/*
 *	stwcx.		Store Word Conditional Indexed
 *	.661
 */
void ppc_opc_stwcx_()
{
	int rA, rS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rS, rA, rB);
	gCPU.cr &= 0x0fffffff;
	if (gCPU.have_reservation) {
		gCPU.have_reservation = false;
		uint32 v;
		if (ppc_read_effective_word((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], &v)) {
			return;
		}
		if (v==gCPU.reserve) {
			if (ppc_write_effective_word((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], gCPU.gpr[rS])) {
				return;
			}
			gCPU.cr |= CR_CR0_EQ;
		}
		if (gCPU.xer & XER_SO) {
			gCPU.cr |= CR_CR0_SO;
		}
	}
}
/*
 *	stwu		Store Word with Update
 *	.663
 */
void ppc_opc_stwu()
{
	int rA, rS;
	uint32 imm;
	PPC_OPC_TEMPL_D_SImm(gCPU.current_opc, rS, rA, imm);
	// FIXME: check rA!=0
	int ret = ppc_write_effective_word(gCPU.gpr[rA]+imm, gCPU.gpr[rS]);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += imm;
	}
}
/*
 *	stwux		Store Word with Update Indexed
 *	.664
 */
void ppc_opc_stwux()
{
	int rA, rS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rS, rA, rB);
	// FIXME: check rA!=0
	int ret = ppc_write_effective_word(gCPU.gpr[rA]+gCPU.gpr[rB], gCPU.gpr[rS]);
	if (ret == PPC_MMU_OK) {
		gCPU.gpr[rA] += gCPU.gpr[rB];
	}
}
/*
 *	stwx		Store Word Indexed
 *	.665
 */
void ppc_opc_stwx()
{
	int rA, rS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, rS, rA, rB);
	ppc_write_effective_word((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB], gCPU.gpr[rS]) != PPC_MMU_FATAL;
}

/*      stvx	    Store Vector Indexed
 *      v.134
 */
void ppc_opc_stvx()
{
#ifndef __VEC_EXC_OFF__
	if ((gCPU.msr & MSR_VEC) == 0) {
		ppc_exception(PPC_EXC_NO_VEC, 0, 0);
		return;
	}
#endif
	VECTOR_DEBUG;
	int rA, vrS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, vrS, rA, rB);

	int ea = ((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB]);

	ppc_write_effective_qword(ea, gCPU.vr[vrS]) != PPC_MMU_FATAL;
}

/*      stvxl	   Store Vector Indexed LRU
 *      v.135
 */
void ppc_opc_stvxl()
{
	ppc_opc_stvx();
	/* This instruction should hint to the cache that the value won't be
	 *   needed again in memory anytime soon.  We don't emulate the cache,
	 *   so this is effectively exactly the same as lvx.
	 */
}

/*      stvebx	  Store Vector Element Byte Indexed
 *      v.131
 */
void ppc_opc_stvebx()
{
#ifndef __VEC_EXC_OFF__
	if ((gCPU.msr & MSR_VEC) == 0) {
		ppc_exception(PPC_EXC_NO_VEC, 0, 0);
		return;
	}
#endif
	VECTOR_DEBUG;
	int rA, vrS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, vrS, rA, rB);
	uint32 ea;
	ea = (rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB];
	ppc_write_effective_byte(ea, VECT_B(gCPU.vr[vrS], ea & 0xf));
}

/*      stvehx	  Store Vector Element Half Word Indexed
 *      v.132
 */
void ppc_opc_stvehx()
{
#ifndef __VEC_EXC_OFF__
	if ((gCPU.msr & MSR_VEC) == 0) {
		ppc_exception(PPC_EXC_NO_VEC, 0, 0);
		return;
	}
#endif
	VECTOR_DEBUG;
	int rA, vrS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, vrS, rA, rB);
	uint32 ea;
	ea = ((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB]) & ~1;
	ppc_write_effective_half(ea, VECT_H(gCPU.vr[vrS], (ea & 0xf) >> 1));
}

/*      stvewx	  Store Vector Element Word Indexed
 *      v.133
 */
void ppc_opc_stvewx()
{
#ifndef __VEC_EXC_OFF__
	if ((gCPU.msr & MSR_VEC) == 0) {
		ppc_exception(PPC_EXC_NO_VEC, 0, 0);
		return;
	}
#endif
	VECTOR_DEBUG;
	int rA, vrS, rB;
	PPC_OPC_TEMPL_X(gCPU.current_opc, vrS, rA, rB);
	uint32 ea;
	ea = ((rA?gCPU.gpr[rA]:0)+gCPU.gpr[rB]) & ~3;
	ppc_write_effective_word(ea, VECT_W(gCPU.vr[vrS], (ea & 0xf) >> 2));
}

/*      dstst	   Data Stream Touch for Store
 *      v.117
 */
void ppc_opc_dstst()
{
	VECTOR_DEBUG;
	/* Since we are not emulating the cache, this is a nop */
}

/*      dss	     Data Stream Stop
 *      v.114
 */
void ppc_opc_dss()
{
	VECTOR_DEBUG;
	/* Since we are not emulating the cache, this is a nop */
}
void ppc_opc_wrteei(){
	if ((gCPU.current_opc >> 15) & 0x1)
		gCPU.msr |= 0x00008000;
	else
		gCPU.msr &= ~0x00008000;
}
void ppc_opc_wrtee(){
	int rA, rS, rB;
        PPC_OPC_TEMPL_X(gCPU.current_opc, rS, rA, rB);
        if ((gCPU.gpr[rS] >> 15) & 0x1)
                gCPU.msr |= 0x00008000;
        else
                gCPU.msr &= ~0x00008000;

}
