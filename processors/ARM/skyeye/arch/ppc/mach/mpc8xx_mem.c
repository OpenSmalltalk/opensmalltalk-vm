/*
 * ----------------------------------------------------
 *
 * MPC8xx Memory Controller emulation
 * (C) 2004  Lightmaze Solutions AG
 *   Author: Jochen Karrer
 *
 * Status
 *    	not yet working 
 *
 * ----------------------------------------------------
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <bus.h>
#include <cpu_ppc.h>
#include <configfile.h>
#include "mpc8xx_immr.h"
#include "mpc8xx_mem.h"

struct MPC8xx_MemCo {
	BusDevice *bdev[8];
	int is_bootmap;
	uint32_t immr; /* Internal memory map register */

	uint32_t br[8];
	uint32_t or[8];
	uint32_t mar;
	uint32_t mcr;
	uint32_t mamr;
	uint32_t mbmr;
	uint16_t mstat;
	uint16_t mptpr;
};
/*
 * ----------------------------------------
 * Boot memory Map
 * Chapter 15.5.2 of MPC866 Manual
 * ----------------------------------------
 */
static void
MPC8xx_BootMap(MPC8xx_MemCo *memco)  
{
	uint32_t start,end;
	uint32_t mapsize;
	BusDevice *bdev = memco->bdev[0];
	start = 0;
	end = memco->immr & 0xffff0000; // 64k Window
	if(!bdev) {
		return;
	}
	mapsize=start-end;
	fprintf(stderr,"IMMR %08x\n",memco->immr);
	if(mapsize) {
		fprintf(stderr,"1: Mapping from %08x, size %08x\n",start,mapsize);
		Mem_AreaAddMapping(bdev,start,mapsize,MEM_FLAG_READABLE | MEM_FLAG_READABLE);
	}
	start = (memco->immr & 0xffff0000) + 0x10000;
	mapsize = ~start+1;
	if(mapsize) {
		fprintf(stderr,"2: Mapping from %08x, size %08x\n",start,mapsize);
		Mem_AreaAddMapping(bdev,start,mapsize,MEM_FLAG_READABLE | MEM_FLAG_READABLE);
	}
}
/*
 * ----------------------------------------------
 * Currently ignores readable/writable flags
 * ----------------------------------------------
 */
static void
MPC8xx_RebuildMmap(MPC8xx_MemCo *memco) {
        BusDevice *bdev;
	int i;
        for(i=0;i<8;i++) {
                bdev=memco->bdev[i];
                if(bdev) {
                        Mem_AreaDeleteMappings(bdev);
                }
        }
	if(memco->is_bootmap) {
		MPC8xx_BootMap(memco);
	} else {
		for(i=0;i<8;i++) {
        		uint32_t base;
        		uint32_t mapsize;
			uint32_t mask;
			uint32_t br;
			uint32_t or;
			br = memco->br[i];
			or = memco->or[i];
			base = br & 0xffff8000;
			mask = OR_AM(or);
			mapsize = ~mask+1;
			bdev=memco->bdev[i];
			if(!bdev)
				continue;
			if(!BR_V(br)) {
				continue;
			}
			Mem_AreaAddMapping(bdev,base,mapsize,MEM_FLAG_WRITABLE|MEM_FLAG_READABLE);
		}
	}
}

static uint32_t 
br_read(void *clientData,uint32_t address,int rqlen) {
	MPC8xx_MemCo *memco = (MPC8xx_MemCo *)clientData;
	int  offs = (address >> 3) & 7;
	return memco->br[offs];
}

static void 
br_write(void *clientData,uint32_t value,uint32_t address,int rqlen)  {
	MPC8xx_MemCo *memco = (MPC8xx_MemCo *)clientData;
	int  offs = (address >> 3) & 7;
	memco->br[offs]=value;
        fprintf(stderr,"PPC-Memco BR %d: %08x, value %08x\n",offs,address,value);
	MPC8xx_RebuildMmap(memco); 
        return;
}

static uint32_t 
or_read(void *clientData,uint32_t address,int rqlen) {
	MPC8xx_MemCo *memco = (MPC8xx_MemCo *)clientData;
	int  offs = (address >> 3) & 7;
        fprintf(stderr,"PPC-Memco read OR %d\n",offs);
	return memco->or[offs];
}

static void 
or_write(void *clientData,uint32_t value,uint32_t address,int rqlen)  {
	MPC8xx_MemCo *memco = (MPC8xx_MemCo *)clientData;
	int  cs = (address >> 3) & 7;
	int update=0;
	fprintf(stderr,"OR %d write value %08x\n",cs,value);
	if(cs==0) {
		if(memco->is_bootmap) {
			memco->is_bootmap=0; /* First write enables the memory Map */
			update = 1;
		}
	}
	memco->or[cs]=value;
	MPC8xx_RebuildMmap(memco); 
}

static uint32_t 
mar_read(void *clientData,uint32_t address,int rqlen) {
        fprintf(stderr,"MPC8xx-Memco read MAR register %08x not implemented\n",address);
        return 0;
}
static void 
mar_write(void *clientData,uint32_t value,uint32_t address,int rqlen)  {
        fprintf(stderr,"MPC8xx-Memco write MAR register %08x not implemented\n",address);
}

static uint32_t 
mcr_read(void *clientData,uint32_t address,int rqlen) {
        fprintf(stderr,"MPC8xx-Memco read MCR register %08x not implemented\n",address);
        return 0;
}
static void 
mcr_write(void *clientData,uint32_t value,uint32_t address,int rqlen)  {
        fprintf(stderr,"MPC8xx-Memco write MCR register %08x not implemented\n",address);
}
static uint32_t 
mamr_read(void *clientData,uint32_t address,int rqlen) {
        fprintf(stderr,"MPC8xx-Memco read MAMR register %08x not implemented\n",address);
        return 0;
}
static void 
mamr_write(void *clientData,uint32_t value,uint32_t address,int rqlen)  {
        fprintf(stderr,"MPC8xx MAMR write register %08x not implemented\n",address);
}
static uint32_t 
mbmr_read(void *clientData,uint32_t address,int rqlen) {
        fprintf(stderr,"MPC8xx MBMR read register %08x not implemented\n",address);
        return 0;
}
static void 
mbmr_write(void *clientData,uint32_t value,uint32_t address,int rqlen)  {
        fprintf(stderr,"MPC8xx MBMR write register %08x not implemented\n",address);
}
static uint32_t 
mstat_read(void *clientData,uint32_t address,int rqlen) {
        fprintf(stderr,"MPC8xx-Memco read MSTAT register %08x not implemented\n",address);
        return 0;
}
static void 
mstat_write(void *clientData,uint32_t value,uint32_t address,int rqlen)  {
        fprintf(stderr,"MPC8xx-Memco write MSTAT register %08x not implemented\n",address);
}
static uint32_t 
mptpr_read(void *clientData,uint32_t address,int rqlen) {
        fprintf(stderr,"MPC8xx-Memco read MPTPR register %08x not implemented\n",address);
        return 0;
}
static void 
mptpr_write(void *clientData,uint32_t value,uint32_t address,int rqlen)  {
        fprintf(stderr,"MPC8xx write MPTPR register %08x not implemented\n",address);
}


static void
MPC8xx_MemCoMap(MPC8xx_MemCo *memco) {
	int i;
	uint32_t addr;
	uint32_t base = IMMR_ISB(memco->immr);
	for(i=0;i<8;i++) {
		addr=MPC8xx_BR(i);
		IOH_New32(base+addr,br_read,br_write,memco);
		addr=MPC8xx_OR(i);
		IOH_New32(base+addr,or_read,or_write,memco);
	}
	IOH_New32(base + MPC8xx_MAR,mar_read,mar_write,memco);
	IOH_New32(base + MPC8xx_MCR,mcr_read,mcr_write,memco);
	IOH_New32(base + MPC8xx_MAMR,mamr_read,mamr_write,memco);
	IOH_New32(base + MPC8xx_MBMR,mbmr_read,mbmr_write,memco);
	IOH_New16(base + MPC8xx_MSTAT,mstat_read,mstat_write,memco);
	IOH_New16(base + MPC8xx_MPTPR,mptpr_read,mptpr_write,memco);
}

static void
MPC8xx_MemCoUnMap(MPC8xx_MemCo *memco) {
	int i;
	uint32_t addr;
	uint32_t base = IMMR_ISB(memco->immr);
	for(i=0;i<8;i++) {
		addr=MPC8xx_BR(i);
		IOH_Delete32(base + addr);
		addr=MPC8xx_OR(i);
		IOH_Delete32(base+addr);
	}
	IOH_Delete32(base + MPC8xx_MAR);
	IOH_Delete32(base + MPC8xx_MCR);
	IOH_Delete32(base + MPC8xx_MAMR);
	IOH_Delete32(base + MPC8xx_MBMR);
	IOH_Delete16(base + MPC8xx_MSTAT);
	IOH_Delete16(base + MPC8xx_MPTPR);
}

void
MPC8xx_RegisterDevice(MPC8xx_MemCo *memco,BusDevice *bdev,uint32_t cs) {
        if(cs>7) {
                fprintf(stderr,"Bug, only 8 Chipselects available but trying to set Nr. %d\n",cs);
                exit(4324);
        }
        if(memco->bdev[cs]) {
                fprintf(stderr,"NS9750_RegisterDevice warning: There is already a device for CS%d\n",cs);
        }
        memco->bdev[cs]=bdev;
        MPC8xx_RebuildMmap(memco);
}

static uint32_t
MemCo_ImmrRead(int spr,void *cd) {
	MPC8xx_MemCo *memco=(MPC8xx_MemCo*)cd;
	return memco->immr;
}

/*
 * -----------------------------------------------------------
 * SPR638 (IMMR) is a traced Processor processor register
 * When it changes the Internal registers of
 * the MPC8xx have to be moved
 * -----------------------------------------------------------
 */
void
MemCo_ImmrWrite(uint32_t value,int spr,void *cd) {
	MPC8xx_MemCo *memco=(MPC8xx_MemCo*)cd;
	if(value!=memco->immr) {
		MPC8xx_MemCoUnMap(memco); 
		memco->immr = value;
		MPC8xx_MemCoMap(memco); 
		if(memco->is_bootmap) {
			MPC8xx_RebuildMmap(memco);
		}
	}
}

MPC8xx_MemCo *
MPC8xx_MemController_New(PpcCpu *cpu) 
{
	MPC8xx_MemCo *memco = (MPC8xx_MemCo*)malloc(sizeof(MPC8xx_MemCo));
	uint32_t configWord;
	uint32_t rstconf;
	uint32_t isb;
	uint32_t bdis;
	if(!memco) {
		fprintf(stderr,"Out of memory\n");
		exit(6495);
	}
	memset(memco,0,sizeof(MPC8xx_MemCo));
	/* from hardreset configuration word */
	if(Config_ReadUInt32(&rstconf,"MPC8xx","rstconf")<0) {
		fprintf(stderr,"Can not read MPC8xx rstconf pin\n");
		exit(1468);
	}
	if(rstconf) {
		configWord = 0;
		fprintf(stderr,"RSTCONFIG is high: configword is 0\n");
	} else {
		if(Config_ReadUInt32(&configWord,"MPC8xx","configWord")<0) {
			fprintf(stderr,"Can not read MPC8xx configuration word\n");
			exit(1468);
		}
	}
	isb = (configWord >> 23)&3;
	bdis = (configWord >> 28)&1;
	switch(isb) {
		case 0:
			memco->immr=0;
			break;
		case 1:
			memco->immr=0x00f00000;
			break;
		case 2:
			memco->immr=0xff000000;
			break;
		case 3:
		default:
			memco->immr=0xfff00000;
			break;
	}
	fprintf(stderr,"isb %d immr %08x\n",isb,memco->immr);
//	fprintf(stderr,"bdis %08x word %08x\n",bdis,configWord);
	memco->br[0] = 0;
	memco->or[0] = 0xfff4;
	memco->mamr = 0x00001000;
	memco->mbmr = 0x00001000;
	memco->mstat = 0;
	memco->mcr = 0;
	memco->is_bootmap=1;
	Ppc_RegisterSprHandler(cpu,SPR_IMMR,MemCo_ImmrRead,MemCo_ImmrWrite, memco);	
	MPC8xx_MemCoMap(memco); 
	fprintf(stderr,"MPC8xx Memory Controller created: IMMR 0x%08x\n",memco->immr);
	return memco;
}
