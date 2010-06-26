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
#ifndef __SKYEYE_NANDFLASH_H_
#define __SKYEYE_NANDFLASH_H_

#include "skyeye_device.h"
#define NANDFLASH_DEBUG 1
#if NANDFLASH_DEBUG
#define NANDFLASH_DBG(msg...) fprintf(stderr, ##msg)
#else
#define NANDFLASH_DBG(msg...)
#endif
/*
 * Standard NAND flash commands
 */
 #define NAND_CMD_NONE              -1
#define NAND_CMD_READ0		0
#define NAND_CMD_READ1		1
#define NAND_CMD_PAGEPROG	0x10
#define NAND_CMD_READOOB	0x50
#define NAND_CMD_ERASE1		0x60
#define NAND_CMD_STATUS		0x70
#define NAND_CMD_STATUS_MULTI	0x71
#define NAND_CMD_SEQIN		0x80
#define NAND_CMD_READID		0x90
#define NAND_CMD_ERASE2		0xd0
#define NAND_CMD_RESET		0xff

typedef enum {
	NF_LOW,
	NF_HIGH
} NFCE_STATE;

struct nandflash_device
{
	int mod;
	void *state;
	/* private data. */
	void *priv;
	char dump[MAX_STR_NAME];
	u32 pagesize,obbsize;
	u32 pagenum;           /* page numbers per block*/
	u32 blocknum;          /* block numbers per device*/
	u32 pagedumpsize,erasesize;
	u32 devicesize;
	u8 ID[5];
	u8   (*readio)(struct nandflash_device * flash_dev);
	void (*writeio) (struct nandflash_device * flash_dev,u8 iodata);
	void (*setCE) (struct nandflash_device * flash_dev,NFCE_STATE state);
	void (*setCLE) (struct nandflash_device * flash_dev,NFCE_STATE state);
	void (*setALE) (struct nandflash_device * flash_dev,NFCE_STATE state);
	void (*setRE) (struct nandflash_device * flash_dev,NFCE_STATE state);
	void (*setWE) (struct nandflash_device * flash_dev,NFCE_STATE state);
	void (*setWP) (struct nandflash_device * flash_dev,NFCE_STATE state);
	u32   (*readRB)(struct nandflash_device * flash_dev);
	void (*sendcmd)(struct nandflash_device * flash_dev,u8 cmd);
	void (*sendaddr)(struct nandflash_device * flash_dev,u8 addr);
	void (*senddata)(struct nandflash_device * flash_dev,u8 data);
	u8 (*readdata)(struct nandflash_device * flash_dev);
	void (*poweron)(struct nandflash_device * flash_dev);
	void (*reset)(struct nandflash_device * flash_dev);
	void (*install)(struct nandflash_device *flash_dev);
	void (*uinstall)(struct nandflash_device *flash_dev);
	
};

typedef struct nandflash_module_option
{
	char *name;
	u32 pagesize,obbsize;
	u32 pagenum;           /* page numbers per block*/
	u32 blocknum;          /* block numbers per device*/
	u8  ID[5];
	void (*install_dev) (struct nandflash_device *dev);
	void (*uinstall_dev)(struct nandflash_device *dev);
} nandflash_module_option;

int nandflash_module_setup(struct nandflash_device *dev,char *name);
void nandflash_sb_uninstall(struct nandflash_device* dev);
void  nandflash_sb_setup(struct nandflash_device* dev);
static nandflash_module_option nandflash_module_data[]={
	{"K9F1208U0B",512,16,32,4096,{0xEC,0x76,0xA5,0xC0,0x0},nandflash_sb_setup,nandflash_sb_uninstall},
};
#endif	/*__SKYEYE_NANDFLASH_H_*/

