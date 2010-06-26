/* 
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.  */

/*
 * author gbf0871 <gbf0871@126.com>
 */
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
//#include <sys/mman.h>
#include "portable/mman.h"
#include "skyeye_nandflash.h"
#include "nandflash_smallblock.h"
void nandflash_sb_reset(struct nandflash_device *dev);
static void nandflash_sb_doerase(struct nandflash_device *dev,struct nandflash_sb_status *nf)
{
	u32 blocks,len,base,i;
	if(nf->WP==NF_HIGH)
	{
		len=dev->erasesize;
		base=nf->address-nf->address%len;
#ifndef POSIX_SHARE_MEMORY_BROKEN
		for (i=0;i<len;i++)
			*(nf->addrspace+base+i)=0xFF;
#else
		lseek(nf->fdump,base,SEEK_SET);
		memset(nf->readbuffer,0xff,dev->pagedumpsize);
		nf->curblock=-1;
		for(i=0;i<dev->pagenum;i++)
		  write(nf->fdump,nf->readbuffer,dev->pagedumpsize);
#endif
		//msync(nf->addrspace+base,len,MS_ASYNC);
	}
}
static void nandflash_sb_dodatawrite(struct nandflash_device *dev,struct nandflash_sb_status *nf)
{
	u32 offset;
	if(nf->WP==NF_HIGH)
	{
		//offset=nf->address%528;
		if (nf->pageoffset>dev->pagedumpsize-1)
			NANDFLASH_DBG("nandflash write cycle out bound\n");
		nf->writebuffer[nf->pageoffset]=nf->IOPIN;
		nf->pageoffset++;		
	}
	
}
static void nandflash_sb_finishwrite(struct nandflash_device *dev,struct nandflash_sb_status *nf)
{
	u32 i,base;
	if(nf->WP==NF_HIGH)
	{
		base=nf->address-nf->address%dev->pagedumpsize;
#ifndef POSIX_SHARE_MEMORY_BROKEN
		for (i=0;i<dev->pagedumpsize;i++)
		{
			*(nf->addrspace+base+i)&=nf->writebuffer[i];
		}
#else
		//printf("DEBUG:nand flash write\n");
		lseek(nf->fdump,base,SEEK_SET);
		if(write(nf->fdump,nf->writebuffer,dev->pagedumpsize)!=dev->pagedumpsize)
			printf("nand flash write error\n");
		//fsync(nf->fdump);
#endif
		//msync(nf->addrspace+base,528,MS_ASYNC);
	}
}
static void nandflash_sb_doread(struct nandflash_device *dev,struct nandflash_sb_status *nf)
{
	if(nf->address<dev->devicesize)
	{
#ifndef POSIX_SHARE_MEMORY_BROKEN
		nf->IOPIN=*(nf->addrspace+nf->address);
#else
	    	int blockoff=nf->address%dev->pagedumpsize;
	    	nf->IOPIN=nf->readbuffer[blockoff];
#endif
		nf->address++;
#ifdef POSIX_SHARE_MEMORY_BROKEN
		if((nf->address%dev->pagedumpsize)==0)
		{
			nf->curblock=-1;
		}
#endif
		if((nf->address%dev->pagedumpsize==0)&&(nf->cmd==NAND_CMD_READOOB))
		{
			nf->address+=dev->pagesize;
		}
		//NANDFLASH_DBG("%s:mach:%x,data:%x\n", __FUNCTION__, nf->address,nf->IOPIN);
	}
	else
	{
		NANDFLASH_DBG("nandflash read outof bound!\n");
	}
}
static void nandflash_sb_doreadid(struct nandflash_device *dev,struct nandflash_sb_status *nf)
{
	switch(nf->cmdstatus){
	case NF_readID_1st:
		nf->IOPIN=dev->ID[0];
		nf->cmdstatus=NF_readID_2nd;
		break;
	case NF_readID_2nd:
		nf->IOPIN=dev->ID[1];
		nf->cmdstatus=NF_readID_3rd;
		break;
	case NF_readID_3rd:
		nf->IOPIN=dev->ID[2];
		nf->cmdstatus=NF_readID_4th;
		break;
	case NF_readID_4th:
		nf->IOPIN=dev->ID[3];
		nf->cmdstatus=NF_NOSTATUS;
		nf->iostatus=NF_NONE;
		break;
	default:
	 	NANDFLASH_DBG("Nandflash readID Error!");
		break;
	}
}
static void nandflash_sb_docmd(struct nandflash_device *dev,struct nandflash_sb_status *nf)
{
	//printf("commd:%x\n",nf->IOPIN);
	switch(nf->IOPIN) {
  	case NAND_CMD_READ0:
  		nf->cmd=NAND_CMD_READ0;
  		nf->cmdstatus=NF_addr_1st;
  		nf->address=0;
		nf->iostatus=NF_ADDR;
  		nf->pageoffset=0;
		break;
	case NAND_CMD_READ1:
		nf->cmd=NAND_CMD_READ1;
  		nf->cmdstatus=NF_addr_1st;
  		nf->pageoffset=256;
		nf->address=0;
		nf->iostatus=NF_ADDR;;
		break;
	case NAND_CMD_READOOB:
	  	nf->cmd=NAND_CMD_READOOB;
  		nf->cmdstatus=NF_addr_1st;
		nf->address=0;
  		nf->pageoffset=512;
		nf->iostatus=NF_ADDR;
		break;
	case NAND_CMD_RESET:
	   	nf->cmd=NAND_CMD_RESET;
		nandflash_sb_reset(dev);
		break;
	case NAND_CMD_SEQIN:
		nf->cmd=NAND_CMD_SEQIN;
  		nf->cmdstatus=NF_addr_1st;
		memset(nf->writebuffer,0xFF,dev->pagedumpsize);
  		nf->address=0;
		nf->iostatus=NF_ADDR;
		break;
	case NAND_CMD_ERASE1:
		nf->cmd=NAND_CMD_ERASE1;
  		nf->cmdstatus=NF_addr_2nd;
		nf->iostatus=NF_ADDR;
		nf->pageoffset=0;
  		nf->address=0;
		break;
	case NAND_CMD_ERASE2:
		if ((nf->cmd==NAND_CMD_ERASE1)&&(nf->cmdstatus==NF_addr_finish))
		{
			
			nandflash_sb_doerase(dev,nf);
		}
		else
		{
			NANDFLASH_DBG("invalid ERASE2 commond,command:%x,status:%x\n",nf->cmd,nf->cmdstatus);
		}
		nf->cmd=NAND_CMD_NONE;
		break;
	case NAND_CMD_STATUS:
		nf->cmd=NAND_CMD_STATUS;
  		nf->cmdstatus=NF_status;
		nf->iostatus=NF_STATUSREAD;
  		break;
  	case NAND_CMD_READID:
  		nf->cmd=NAND_CMD_READID;
  		nf->cmdstatus=NF_addr_4th;
		nf->pageoffset=0;
		nf->address=0;
		nf->iostatus=NF_ADDR;
  		break;
  	case NAND_CMD_PAGEPROG:
  		if ((nf->cmd==NAND_CMD_SEQIN)&&(nf->cmdstatus==NF_addr_finish))
  		{
			nf->cmd=NAND_CMD_PAGEPROG;
  			nandflash_sb_finishwrite(dev,nf);
  		}
  		else
  		{
  			NANDFLASH_DBG("invalid PAGEPROG commond,command:%x,status:%x\n",nf->cmd,nf->cmdstatus);
  		}
  		break;
	default:
	  	NANDFLASH_DBG("Unknow nandflash command:%x\n",nf->IOPIN);
		break;
	}
}
static void nandflash_sb_doaddr(struct nandflash_device *dev,struct nandflash_sb_status *nf)
{
	u32 offset,rows,tmp;
	tmp=nf->IOPIN;
	//printf("tmp:%02x\n",tmp);
	switch (nf->cmdstatus) {
	case NF_addr_1st:
		nf->address=0;
		nf->pageoffset=nf->IOPIN+nf->pageoffset;
		nf->cmdstatus=NF_addr_2nd;
		break;
	case NF_addr_2nd:
		nf->address=(nf->address |(tmp<<9));
		nf->cmdstatus=NF_addr_3rd;
		break;
	case NF_addr_3rd:
		nf->address=(nf->address |(tmp<<17));
		nf->cmdstatus=NF_addr_4th;
		break;
	case NF_addr_4th:
		nf->address=(nf->address |(tmp<<25));
		rows=nf->address>>9;
		nf->address=rows*528+nf->pageoffset;
		//NANDFLASH_DBG("set addr:%08x\n",nf->address);
		if ((nf->cmd==NAND_CMD_READ0)||(nf->cmd==NAND_CMD_READ1)||(nf->cmd==NAND_CMD_READOOB))
		{
			nf->iostatus=NF_DATAREAD;
			#ifdef POSIX_SHARE_MEMORY_BROKEN
				int block=nf->address/dev->pagedumpsize;
				int tmp;
				//if(block!=nf->curblock)
				//{
					//printf("nand read address:%08x\n",nf->address);
					if (nf->address<dev->devicesize)
					{
						memset(nf->readbuffer,0xff,dev->pagedumpsize);						
						if(lseek(nf->fdump,block*dev->pagedumpsize,SEEK_SET)==-1)
							printf("lseek error\n");
						//printf("offset:%d\n",block);
						tmp=read(nf->fdump,nf->readbuffer,dev->pagedumpsize);
						if  (tmp!=dev->pagedumpsize)
					  		printf("read error address:%08x,readsize:%d,block:%d\n",nf->address,tmp,block);
					  }
					  else
					  {
					  	printf("read outof bound\n");
					  }
				//}
			#endif
		}
		else if (nf->cmd==NAND_CMD_SEQIN)
		{
			nf->iostatus=NF_DATAWRITE;
			nf->cmdstatus=NF_addr_finish;
			//if (nf->pageoffset!=0) NANDFLASH_DBG("when page program offset is not 0 maybe this is error!\n");
		}
		else if (nf->cmd==NAND_CMD_READID)
		{
			nf->iostatus=NF_IDREAD;
			nf->cmdstatus=NF_readID_1st;
		}
		else if (nf->cmd==NAND_CMD_ERASE1)
		{
			nf->iostatus=NF_CMD;
			nf->cmdstatus=NF_addr_finish;
		}
		else
		{
			NANDFLASH_DBG("Error address input\n");
		}
		break;
	case NF_readID_addr:
		nf->cmdstatus=NF_readID_1st;
		nf->iostatus=NF_addr_finish;
		break;
	case NF_addr_finish:
	 	NANDFLASH_DBG("nandflash write address 4 cycle has already finish,but addr write however!\n");
		break;
	default:
	  	NANDFLASH_DBG("nandflash write address error!\n");
		break;
	}
}
u8   nandflash_sb_readio(struct nandflash_device *dev)
{
	struct nandflash_sb_status *nf=(struct nandflash_sb_status*)dev->priv;
	if (nf->CE==NF_LOW)
	{
		return nf->IOPIN;
	}
}
void nandflash_sb_writeio(struct nandflash_device *dev,u8 iodata)
{
	struct nandflash_sb_status *nf=(struct nandflash_sb_status*)dev->priv;
	if (nf->CE==NF_LOW)
	{
		nf->IOPIN=iodata;
	}
}
void nandflash_sb_setCE(struct nandflash_device *dev,NFCE_STATE state)
{
	struct nandflash_sb_status *nf=(struct nandflash_sb_status*)dev->priv;
	nf->CE=state;
	if ((state==NF_HIGH) &(nf->iostatus==NF_DATAREAD))
	{
		nf->iostatus=NF_NONE;
	}
}
void nandflash_sb_setCLE(struct nandflash_device *dev,NFCE_STATE state)
{
	struct nandflash_sb_status *nf=(struct nandflash_sb_status*)dev->priv;
       if (nf->ALE==NF_HIGH) 
       {
       	NANDFLASH_DBG("warning the ALE is high,but CLE also set high\n");//maybe this warning is wrong,i don't know
       }
	nf->CLE=state;
	if ((state==NF_HIGH)&&(nf->CE==NF_LOW))
	{
		nf->iostatus=NF_CMD;
	}
}
void nandflash_sb_setALE(struct nandflash_device *dev,NFCE_STATE state)
{
	struct nandflash_sb_status *nf=(struct nandflash_sb_status*)dev->priv;
	if (nf->CLE==NF_HIGH) 
       {
       	NANDFLASH_DBG("warning the CLE is high,but ALE also set high\n");  //maybe this warning is wrong,i don't know
       }
	nf->ALE=state;
	if ((state==NF_HIGH)&&(nf->CE==NF_LOW))
	{
		nf->iostatus=NF_ADDR;
	}
}
void nandflash_sb_setWE(struct nandflash_device *dev,NFCE_STATE state)
{
	struct nandflash_sb_status *nf=(struct nandflash_sb_status*)dev->priv;
	if ((nf->WE==NF_LOW)&&(state==NF_HIGH)&&(nf->CE==NF_LOW))            //latched on the rising edge
	{
		switch(nf->iostatus) {
		case NF_CMD:
		       nandflash_sb_docmd(dev,nf);
			break;
		case NF_ADDR:
			nandflash_sb_doaddr(dev,nf);
		   	break;
		case NF_DATAWRITE:
			nandflash_sb_dodatawrite(dev,nf);
			//nf->iostatus=NF_NONE;
			break;
		default:
			NANDFLASH_DBG("warning when WE raising,do nothing\n "); 
			break;
		}
	}
	nf->WE=state;
}
void nandflash_sb_setRE(struct nandflash_device *dev,NFCE_STATE state)
{
	struct nandflash_sb_status *nf=(struct nandflash_sb_status*)dev->priv;
	if ((nf->RE==NF_HIGH)&&(state==NF_LOW)&&(nf->CE==NF_LOW))
	{
		switch(nf->iostatus) {
		case NF_DATAREAD:
			nandflash_sb_doread(dev,nf);
			break;
		case NF_IDREAD:
			nandflash_sb_doreadid(dev,nf);
			break;
		case NF_STATUSREAD:
			//printf("read status:0x%x\n",nf->status);
			nf->IOPIN=nf->status;
			nf->iostatus=NF_NONE;
			break;
		default:
			NANDFLASH_DBG("warning when RE  falling,do nothing\n "); 
			break;
		}
	}
	nf->RE=state;
}
void nandflash_sb_setWP(struct nandflash_device *dev,NFCE_STATE state)
{
	struct nandflash_sb_status *nf=(struct nandflash_sb_status*)dev->priv;
	nf->WP=state;
	if (state==NF_LOW){
		nf->status=nf->status & 127;
		printf("WP set LOW\n");
	}
	else {
	 	nf->status=nf->status | 128;
		printf("WP set HIGH\n");
	}
}
u32 nandflash_sb_readRB(struct nandflash_device *dev)      //the rb
{
	return 1;
}
void nandflash_sb_sendcmd(struct nandflash_device *dev,u8 cmd)                                         //send a commond
{
	nandflash_sb_setCLE(dev,NF_HIGH);
	nandflash_sb_setWE(dev,NF_LOW);
	nandflash_sb_writeio(dev,cmd);
	nandflash_sb_setWE(dev,NF_HIGH);
	nandflash_sb_setCLE(dev,NF_LOW);
}

void nandflash_sb_senddata(struct nandflash_device *dev,u8 data)
{
	nandflash_sb_setWE(dev,NF_LOW);
	nandflash_sb_writeio(dev,data);
	nandflash_sb_setWE(dev,NF_HIGH);
}
void nandflash_sb_sendaddr(struct nandflash_device *dev,u8 data)
{
	nandflash_sb_setALE(dev,NF_HIGH);
	nandflash_sb_setWE(dev,NF_LOW);
	nandflash_sb_writeio(dev,data);
	nandflash_sb_setWE(dev,NF_HIGH);
	nandflash_sb_setALE(dev,NF_LOW);
}
u8 nandflash_sb_readdata(struct nandflash_device *dev)
{
	u8 data;
	nandflash_sb_setRE(dev,NF_LOW);
	data=nandflash_sb_readio(dev);
	nandflash_sb_setRE(dev,NF_HIGH);
	return data;
}
void nandflash_sb_poweron(struct nandflash_device *dev)
{	
   	struct nandflash_sb_status *nf=(struct nandflash_sb_status*)dev->priv;
	nf->ALE=NF_LOW;
	nf->CLE=NF_LOW;
	nf->CE=NF_HIGH;
	nf->iostatus=NF_NONE;
	nf->IOPIN=0;
	nf->RB=1;
	nf->RE=NF_HIGH;
	nf->WE=NF_HIGH;
	nf->WP=NF_HIGH;
	nf->status=192;
	nf->pageoffset=0;
	nf->cmd=NAND_CMD_READ0;
	nf->cmdstatus=NF_NOSTATUS;
	nf->iostatus=NF_NONE;
	memset(nf->writebuffer,0xFF,dev->pagedumpsize);         
}
void nandflash_sb_reset(struct nandflash_device *dev)
{
      struct nandflash_sb_status *nf=(struct nandflash_sb_status*)dev->priv;
	nf->ALE=NF_LOW;
	nf->CLE=NF_LOW;
	//nf->CE=NF_HIGH;
	nf->iostatus=NF_NONE;
	nf->IOPIN=0;
	nf->RB=1;
	nf->RE=NF_HIGH;
	nf->WE=NF_HIGH;
	nf->WP=NF_HIGH;
	nf->status=192;
	nf->pageoffset=0;
	nf->cmd=NF_NOSTATUS;
	nf->cmdstatus=NF_NOSTATUS;
	nf->iostatus=NF_NONE;
	memset(nf->writebuffer,0xFF,dev->pagedumpsize);
}


void  nandflash_sb_setup(struct nandflash_device* dev)
{
	u8 flag=0xFF;
	int len,start,needinit=0;
	struct stat statbuf;
	struct nandflash_sb_status *nf;
	int i;
	nf=(struct nandflash_sb_status *)malloc(sizeof(struct nandflash_sb_status));
	if (nf==NULL) 
	{
		printf("error malloc nandflash_sb_status!\n");
       	skyeye_exit(-1);
	}
	dev->poweron=nandflash_sb_poweron;
	dev->readdata=nandflash_sb_readdata;
	dev->readio=nandflash_sb_readio;
	dev->readRB=nandflash_sb_readRB;
	dev->reset=nandflash_sb_reset;
	dev->sendaddr=nandflash_sb_sendaddr;
	dev->sendcmd=nandflash_sb_sendcmd;
	dev->senddata=nandflash_sb_senddata;
	dev->setALE=nandflash_sb_setALE;
	dev->setCE=nandflash_sb_setCE;
	dev->setCLE=nandflash_sb_setCLE;
	dev->setRE=nandflash_sb_setRE;
	dev->setWE=nandflash_sb_setWE;
	dev->setWP=nandflash_sb_setWP;
	memset(nf,0,sizeof(struct nandflash_sb_status));
#ifdef POSIX_SHARE_MEMORY_BROKEN
	nf->readbuffer=(u8*)malloc(dev->pagedumpsize);
#endif
	nf->writebuffer=(u8*)malloc(dev->pagedumpsize);
	//nf->memsize=528*32*4096;
       if ((nf->fdump= open(dev->dump, FILE_FLAG)) < 0)
       {
       	free(nf);
       	printf("error open nandflash dump!\n");
       	skyeye_exit(-1);
       }
	
       if (fstat(nf->fdump, &statbuf) < 0)   /* need size of input file */
       {
       	free(nf);
       	printf("error fstat function\n");
		skyeye_exit(-1);
       }
       if (statbuf.st_size<dev->devicesize)
       {
		printf("\nInit nandflash dump file.\n");
		needinit=1;
		start=statbuf.st_size;
		len=dev->devicesize-start;
		lseek(nf->fdump,dev->devicesize-1,SEEK_SET);
		write(nf->fdump,&flag,1);
#ifndef __MINGW32__
		fsync(nf->fdump);
#else
		_flushall();
#endif
       }
#ifndef POSIX_SHARE_MEMORY_BROKEN
       
	if (fstat(nf->fdump, &statbuf) < 0)   /* need size of input file */
       	{
       		free(nf);
       		printf("error fstat function\n");
				skyeye_exit(-1);
       	}

			printf("file size:%d\n",statbuf.st_size);
         if ((nf->addrspace= mmap(0, statbuf.st_size, PROT_READ | PROT_WRITE,
      		MAP_SHARED, nf->fdump, 0)) == MAP_FAILED)
      	{
      		free(nf);
      		printf("error mmap nandflash file\n");
		      skyeye_exit(-1);
      	}
      	if (needinit)
      	{
      		for(i=start;i<dev->devicesize;i++)
      		{
      			*(nf->addrspace+i)=flag;
      		}
      		if (!msync(nf->addrspace,dev->devicesize,MS_SYNC))
			printf("finish init nandflash dump\n");
		
      	}
		
 #else
   	nf->curblock=-1;
 	if (needinit)
 	{
 		memset(nf->readbuffer,0xff,dev->pagedumpsize);
 		lseek(nf->fdump,start,SEEK_SET);
 		while((dev->devicesize-start)>=dev->pagesize)
 		{
 		  write(nf->fdump,nf->readbuffer,dev->pagesize);
 		  start=start+dev->pagesize;
 		 }
 		 for (i=start;i<dev->devicesize;i++)
 		   write(nf->fdump,&flag,1);
 	}
 #endif
      	dev->priv=nf;
      	nandflash_sb_poweron(dev);
}
void nandflash_sb_uninstall(struct nandflash_device* dev)
{
	struct nandflash_sb_status *nf;
	if(!dev->priv)
	{
		nf=(struct nandflash_sb_status*)dev->priv;
		if (!nf->fdump)
		{
			//msync(nf->addrspace,nf->memsize,MS_SYNC);
#ifndef POSIX_SHARE_MEMORY_BROKEN
			munmap(nf->addrspace,dev->devicesize);
#endif
			close(nf->fdump);
			NANDFLASH_DBG("Unistall nandflash\n");
		}
#ifdef POSIX_SHARE_MEMORY_BROKEN
		if(!nf->readbuffer)
		  free(nf->readbuffer);
#endif
		if(!nf->writebuffer)
		  free(nf->writebuffer);
		free(nf);
	}
}
