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
#ifndef __DEV_NANDFLASH_S3C2410_H_
#define __DEV_NANDFLASH_S3C2410_H_

#define S3C2410_NFCONF_EN          (1<<15)
#define S3C2410_NFCONF_512BYTE     (1<<14)
#define S3C2410_NFCONF_4STEP       (1<<13)
#define S3C2410_NFCONF_INITECC     (1<<12)
#define S3C2410_NFCONF_nFCE        (1<<11)
#define S3C2410_NFCONF_TACLS(x)    ((x)<<8)
#define S3C2410_NFCONF_TWRPH0(x)   ((x)<<4)
#define S3C2410_NFCONF_TWRPH1(x)   ((x)<<0)
#define NFCONF 0x4E000000	/* NAND flash configuration */
#define NFCMD 0x4E000004	/* NAND flash command set register */
#define NFADDR   0x4E000008  /*NAND flash address set register*/
#define NFDATA  0x4E00000C	/* NAND flash data register */
#define NFSTAT   0x4E000010    /*NAND flash operation status*/
#define NFECC1   0x4E000014 	/* NAND flash ECC (Error Correction Code) register */
#define NFECC2   0x4E000015
#define NFECC3   0x4E000016

typedef struct nandflash_s3c2410_io
{
	u32 nfconf;
	u32 nfcmd;
	u32 nfaddr;
	u32 nfdata;
	u32 nfstat;
	u32 nfecc;
} nandflash_s3c2410_io_t;


#endif //_DEV_NANDFLASH_S3C2410_H_

