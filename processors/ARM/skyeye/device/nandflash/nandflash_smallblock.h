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
#ifndef _NANDFLASH_SMALLBLOCK_H_
#define _NANDFLASH_SMALLBLOCK_H_
#include <stdio.h>
#include "skyeye_nandflash.h"

#ifdef __MINGW32__
	#define FILE_FLAG   (O_RDWR | O_CREAT | O_BINARY)
#else
	#define FILE_FLAG   (O_RDWR | O_CREAT)
#endif

#if (defined(__MINGW32__) || defined(__BEOS__))
	#define POSIX_SHARE_MEMORY_BROKEN
#endif

//nandflash cmd status

typedef enum {
		NF_NOSTATUS,
		NF_addr_1st,
		NF_addr_2nd,
		NF_addr_3rd,
		NF_addr_4th,
		NF_addr_finish,
		NF_status,
		NF_readID_1st,
		NF_readID_2nd,
		NF_readID_3rd,
		NF_readID_4th,
		NF_readID_addr
} cmdstatustype;

typedef enum {
		NF_CMD,
		NF_ADDR,
		NF_DATAREAD,
		NF_DATAWRITE,
		NF_STATUSREAD,
		NF_IDREAD,
		NF_NONE
} iostatustype;
struct nandflash_sb_status
{
	u8 IOPIN;
	u8 status;
	NFCE_STATE CLE;
	NFCE_STATE ALE;
	NFCE_STATE CE;
	NFCE_STATE WE;
	NFCE_STATE RE;
      NFCE_STATE WP;
      NFCE_STATE RB;
      u8 cmd;
      cmdstatustype cmdstatus;
      iostatustype iostatus;
      u32 address;
      //u32 memsize;
      int fdump;
      u8  *writebuffer;
      u16  pageoffset;
      #ifdef POSIX_SHARE_MEMORY_BROKEN
      u8 *readbuffer;
      u32 curblock;
      FILE *fd;
      #else
      u8* addrspace;
      #endif
};

#endif //_NANDFLASH_SMALLBLOCK_H_
