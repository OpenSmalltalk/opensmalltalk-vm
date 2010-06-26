//ywc 2005-1-21 for flash simulation
//core flash simulation source code from ipaqsim
//Thanks to ipaqsim's AUTHOR(s):     Ye Wen (wenye@cs.ucsb.edu) 

#include <stdio.h>

//#include "sadefs.h"
//#include "memory.h"

//#define INTEL28F640J3A_SIZE   (0x800000 * 2)          /* 28F640J3A: 8M * 2 */
#define INTEL28F128J3A_SIZE	(0x1000000 * 2)	/* 28F128J3A: 16M * 2 */

#define INTEL_MANUFACTURER_CODE		(0x0089)	/* Intel flash */
//#define INTEL_28F640J3A_DEVICE_CODE   (0x0017)        /* for 28F640J3A */
#define INTEL_28F128J3A_DEVICE_CODE	(0x0018)	/* for 28F128J3A */

#define INTEL_WRITEBUFFER_SIZE		(0x10)	/* 16 words */
#define INTEL_WRITEBUFFER_MASK		(0xf)	/* apply to word address */
/* 
 * It is not clear how large the query table is.
 * I choose the largest value from the spec (Ref.1).
 */
#define INTEL_QUERYTABLE_SIZE		(0x47)	/* query table size: word size */

/* 128KB x 2 */
#define FLASH_SECTOR_SIZE	(0x40000)
//#define FLASH_SECTOR_NUM      (INTEL28F640J3A_SIZE/FLASH_SECTOR_SIZE)
#define FLASH_SECTOR_NUM	(INTEL28F128J3A_SIZE/FLASH_SECTOR_SIZE)
#define FLASH_SECTOR_MASK	(0xfffc0000)
#define FLASH_SECTOR_OFF	(0x3ffff)
#define FLASH_SECTOR_SHIFT	(18)
#define SECTOR_ADDR(x)		((x) >> FLASH_SECTOR_SHIFT)	/* get sector number */

/* command code is also used as the WSM state value */
#define WSM_READ_ARRAY		(0xff)	/* default mode: read array */
#define WSM_READ_ID		(0x90)	/* read ID codes */
#define WSM_READ_STATUS		(0x70)	/* read status register */
#define WSM_CLEAR_STATUS	(0x50)	/* clear status register */
#define WSM_READ_QUERY		(0x98)	/* read query */
#define WSM_WRITE_BUFFER		(0xe8)	/* write to buffer */
#define WSM_PROGRAM			(0x40)	/* word program */
#define WSM_PROGRAM2			(0x10)	/* alternative of word program */
#define WSM_BLOCK_ERASE			(0x20)	/* block erase (0xd0) */
#define WSM_SUSPEND			(0xB0)	/* blcok erase/program suspend */
#define WSM_RESUME			(0xD0)	/* blcok erase/program resume */
#define WSM_CONFIG			(0xB8)	/* configuration */
#define WSM_LOCK_ACCESS			(0x60)	/* set(0x01)/clear(0xD0) block lock-bit */
#define WSM_PROTECT			(0xC0)	/* protection program */
#define WSM_CONFIRM			(0xD0)	/* buffer program/erase confirm */

#define WSM_READY			(0x00)	/* default state of WSM, ready for new command */

/* status bits */
#define FLASH_STATUS_WSMS	(1 << 7)	/* WSM ready */
#define FLASH_STATUS_ESS	(1 << 6)	/* erase suspended */
#define FLASH_STATUS_ECLBS	(1 << 5)	/* erase/clear lock-bit error */
#define FLASH_STATUS_PSLBS	(1 << 4)	/* program/set lock-bit error */
#define FLASH_STATUS_VPENS	(1 << 3)	/* programming voltage low */
#define FLASH_STATUS_PSS	(1 << 2)	/* program suspended */
#define FLASH_STATUS_DPS	(1 << 1)	/* block locked, operation aborted */

/* XSR bits */
#define FLASH_XSR_WBS		(1 << 7)	/* write buffer available */

/* 
 * Since there are 2 chips of 16-bit flash, the data
 * sent to bus should be sth. like 0x00uv00uv. This
 * macro is used to check the validity of the data
 * to ensure same command is sent to the two chips.
 */
#define CHIP_DATA_VALID(x)	( ((x) & 0xffff) == (((x) >> 16) & 0xffff) )

/*
#define CHECK_DATA_VALID(x)	\
do {						\
	if (!CHIP_DATA_VALID(x)) {	\
		printf("\ndata commands sent to two chips are different: 0x%x", x);	\
		return SUCCESS;		\
	}						\
}while (0)
*/

/* make 32-bit data output for both chips when ID or Query is read */
#define BOTHCHIP(x)			((((x)&0xffff)<<16)|((x)&0xffff))

/* return the lock bit */
//#define ISLOCKED(x)                   (this->lock[(x)>>FLASH_SECTOR_SHIFT])

/*
#define ADDR_SUSPENDED(x)	\
((program_suspended && ((x) == program_latch_addr)) || \
 (progbuf_suspended && (((x) >= pb_start) && ((x) < (pb_start+pb_count)))) || \
 (erase_suspended && (((x) & FLASH_SECTOR_MASK) == (erase_latch_addr & FLASH_SECTOR_MASK))) )

#define DEVICE_SUSPENDED	(program_suspended || progbuf_suspended || erase_suspended)
*/

#define SUCCESS		( 0)	/* integer return values */
#define FAILURE		(-1)

#ifndef WORD_SIZE
#define WORD_SIZE	4
#endif
#define WORD_SHIFT	2
#define WORD_ADDR(x)	((x) >> WORD_SHIFT)

#ifndef ARMWord
typedef unsigned int ARMWord;
#endif

#ifndef ARMByte
typedef unsigned char ARMByte;
#endif

#ifndef ARMAddr
typedef ARMWord ARMAddr;
#endif

typedef struct flash_intel_io
{
	u8 *lock;		/* sector lock */
	u32 size;		/* byte size */
	u32 read_mode;		/* mode for read operation */
	u32 wsm_mode;		/* write state machine */

	/* VPEN pin: should controlled by EGPIO ??? */
	u8 vpen;

	/* latch address&data for each handlers */
	u32 program_latch_addr;
	u32 program_latch_data;
	u32 progbuf_latch_addr;
	u32 erase_latch_addr;


	/* 
	 * stateful information for buffer program handler 
	 */
	/* total count and number to be loaded/programmed */
	u32 pb_count, pb_loaded;
	u32 pb_start;		/* start address */
	u32 pb_buf[INTEL_WRITEBUFFER_SIZE];	/* write buffer */

	/*
	 * state bits for handlers: program, buffer program, erase, lock 
	 * xxxx_busy: whether WSM is busy on the handler
	 * xxxx_suspended: whether the handler is suspended
	 * xxxx_error: operation errors
	 */
	u8 program_busy, progbuf_busy, erase_busy, lock_busy;
	u8 program_suspended, progbuf_suspended, erase_suspended;
	u8 protection_error, program_setlb_error, erase_clearlb_error,
		program_volt_error;
} flash_intel_io_t;
