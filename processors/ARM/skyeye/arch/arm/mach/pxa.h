#ifndef _PXA_H_
#define _PXA_H_
//chy: refer to  linux/include/asm-arm/arch-pxa/irq.h
enum
{
	RTC_ALARM_IRQ = (1 << 31),
	RTC_HZ_IRQ = (1 << 30),
	OS_IRQ_SHF = 26,
	FFUART_IRQ = (1 << 22),
};
//chy: refer to linux/include/asm-arm/arch-pxa/pxa-regs.h
typedef enum pxa_ioregnum_t
{
	ICIP = 0x40D00000,	/* Interrupt Controller IRQ Pending Register */
	ICMR = 0x40D00004,	/* Interrupt Controller Mask Register */
	ICLR = 0x40D00008,	/* Interrupt Controller Level Register */
	ICFP = 0x40D0000C,	/* Interrupt Controller FIQ Pending Register */
	ICPR = 0x40D00010,	/* Interrupt Controller Pending Register */
	ICCR = 0x40D00014,	/* Interrupt Controller Control Register */

	RCNR = 0x40900000,	/* RTC Count Register */
	RTAR = 0x40900004,	/* RTC Alarm Register */
	RTSR = 0x40900008,	/* RTC Status Register */
	RTTR = 0x4090000C,	/* RTC Timer Trim Register */

	OSMR0 = 0x40A00000,
	OSMR1 = 0x40A00004,
	OSMR2 = 0x40A00008,
	OSMR3 = 0x40A0000C,
	OSCR = 0x40A00010,	/* OS Timer Counter Register */
	OSSR = 0x40A00014,	/* OS Timer Status Register */
	OWER = 0x40A00018,	/* OS Timer Watchdog Enable Register */
	OIER = 0x40A0001C,	/* OS Timer Interrupt Enable Register */


	/*Full Function UART */
	FFRBR = 0x40100000,	/* Receive Buffer Register (read only) */
	FFTHR = 0x40100000,	/* Transmit Holding Register (write only) */
	FFIER = 0x40100004,	/* Interrupt Enable Register (read/write) */
	FFIIR = 0x40100008,	/* Interrupt ID Register (read only) */
	FFFCR = 0x40100008,	/* FIFO Control Register (write only) */
	FFLCR = 0x4010000C,	/* Line Control Register (read/write) */
	FFMCR = 0x40100010,	/* Modem Control Register (read/write) */
	FFLSR = 0x40100014,	/* Line Status Register (read only) */
	FFMSR = 0x40100018,	/* Reserved */
	FFSPR = 0x4010001C,	/* Scratch Pad Register (read/write) */
	FFISR = 0x40100020,	/* Infrared Selection Register (read/write) */
	FFDLL = 0x40100000,	/* Divisor Latch Low Register (DLAB = 1) (read/write) */
	FFDLH = 0x40100004,	/* Divisor Latch High Register (DLAB = 1) (read/write) */
	/*Standard UART */
	BTRBR = 0x40200000,	/* Receive Buffer Register (read only) */
	BTTHR = 0x40200000,	/* Transmit Holding Register (write only) */
	BTIER = 0x40200004,	/* Interrupt Enable Register (read/write) */
	BTIIR = 0x40200008,	/* Interrupt ID Register (read only) */
	BTFCR = 0x40200008,	/* FIFO Control Register (write only) */
	BTLCR = 0x4020000C,	/* Line Control Register (read/write) */
	BTMCR = 0x40200010,	/* Modem Control Register (read/write) */
	BTLSR = 0x40200014,	/* Line Status Register (read only) */
	BTMSR = 0x40200018,	/* Reserved */
	BTSPR = 0x4020001C,	/* Scratch Pad Register (read/write) */
	BTISR = 0x40200020,	/* Infrared Selection Register (read/write) */
	BTDLL = 0x40200000,	/* Divisor Latch Low Register (DLAB = 1) (read/write) */
	BTDLH = 0x40200004,	/* Divisor Latch High Register (DLAB = 1) (read/write) */
	/*Standard UART */
	STRBR = 0x40700000,	/* Receive Buffer Register (read only) */
	STTHR = 0x40700000,	/* Transmit Holding Register (write only) */
	STIER = 0x40700004,	/* Interrupt Enable Register (read/write) */
	STIIR = 0x40700008,	/* Interrupt ID Register (read only) */
	STFCR = 0x40700008,	/* FIFO Control Register (write only) */
	STLCR = 0x4070000C,	/* Line Control Register (read/write) */
	STMCR = 0x40700010,	/* Modem Control Register (read/write) */
	STLSR = 0x40700014,	/* Line Status Register (read only) */
	STMSR = 0x40700018,	/* Reserved */
	STSPR = 0x4070001C,	/* Scratch Pad Register (read/write) */
	STISR = 0x40700020,	/* Infrared Selection Register (read/write) */
	STDLL = 0x40700000,	/* Divisor Latch Low Register (DLAB = 1) (read/write) */
	STDLH = 0x40700004,	/* Divisor Latch High Register (DLAB = 1) (read/write) */

	//core clock regs
	CCCR = 0x41300000,	/* Core Clock Configuration Register */
	CKEN = 0x41300004,	/* Clock Enable Register */
	OSCC = 0x41300008,	/* Oscillator Configuration Register */

	//ywc,2004-11-30, add LCD control register
	LCCR0 = 0x44000000,
	LCCR1 = 0x44000004,
	LCCR2 = 0x44000008,
	LCCR3 = 0x4400000C,

	FDADR0 = 0x44000200,
	FSADR0 = 0x44000204,
	FIDR0 = 0x44000208,
	LDCMD0 = 0x4400020C,

	FDADR1 = 0x44000210,
	FSADR1 = 0x44000214,
	FIDR1 = 0x44000218,
	LDCMD1 = 0x4400021C
		//ywc,2004-11-30, add LCD control register,end
} pxa_ioregnum_t;

//ywc,2004-11-30, add macro definition for LCD
#define LCCR0_ENB       0x00000001
#define LCCR1_PPL       0x000003FF
#define LCCR2_LPP       0x000003FF
#define LCCR3_BPP       0x07000000
//ywc,2004-11-30, add macro definition for LCD,end

//chy 2009-09-19 from skyeye_mach_pxa250.c to here
typedef struct pxa250_io_t
{
	/*interrupt controller */
	u32 icpr;
	u32 icip;
	u32 icfp;
	u32 icmr;
	u32 iccr;
	u32 iclr;

	/*real time clock(RTC) */
	u32 rcnr;
	u32 rtar;
	u32 rtsr;
	u32 rttr;
	//chy: maybe not regs ????
	u32 rt_scale;		/*core frequence to 32.768K */
	u32 rt_count;

	/*os timer */
	u32 oscr;
	u32 osmr0, osmr1, osmr2, osmr3;
	u32 ower;
	u32 ossr;
	u32 oier;
	//chy: maybe not regs ????
	u32 os_scale;		//chy: I can not find it in pxa-regs.h????

	/*full function uart controller */
	u32 ffrbr;
	u32 ffthr;
	u32 ffier;
	u32 ffiir;
	u32 fffcr;
	u32 fflcr;
	u32 ffmcr;
	u32 fflsr;
	u32 ffmsr;
	u32 ffspr;
	u32 ffisr;
	u32 ffdll;
	u32 ffdlh;

	u32 ff_scale;
	/*bluetooth function uart controller */
	u32 btrbr;
	u32 btthr;
	u32 btier;
	u32 btiir;
	u32 btfcr;
	u32 btlcr;
	u32 btmcr;
	u32 btlsr;
	u32 btmsr;
	u32 btspr;
	u32 btisr;
	u32 btdll;
	u32 btdlh;
	/*standard uart controller */
	u32 strbr;
	u32 stthr;
	u32 stier;
	u32 stiir;
	u32 stfcr;
	u32 stlcr;
	u32 stmcr;
	u32 stlsr;
	u32 stmsr;
	u32 stspr;
	u32 stisr;
	u32 stdll;
	u32 stdlh;
	/*core clock */
	u32 cccr;
	u32 cken;
	u32 oscc;

	//ywc,2004-11-30,add io of LCD and Touchscreen
	  /*LCD*/
		/* remove them later. */
	  u32 lccr0;
	u32 lccr1;
	u32 lccr2;
	u32 lccr3;

	u32 fdadr0;
	u32 fdadr1;

	u32 fsadr0;
	u32 fsadr1;

	/*TouchScreen */
	u32 ts_int;
	u32 ts_buffer[8];
	u32 ts_addr_begin;
	u32 ts_addr_end;
	//ywc,2004-11-30,add io of LCD and Touchscreen,end

} pxa250_io_t;
//chy 2009-09-19 from skyeye_mach_pxa270.c to here
//chy:  lubbock, cerf, idp are different board
// I can add a union to cover the difference in the future
//chy:  refer to linux/include/asm-arm/arch-pxa/pxa-regs.h
typedef struct pxa270_io_t
{
	/*interrupt controller */
	u32 icpr;
	u32 icip;
	u32 icfp;
	u32 icmr;
	u32 iccr;
	u32 iclr;

	/*real time clock(RTC) */
	u32 rcnr;
	u32 rtar;
	u32 rtsr;
	u32 rttr;
	//chy: maybe not regs ????
	u32 rt_scale;		/*core frequence to 32.768K */
	u32 rt_count;

	/*os timer */
	u32 oscr;
	u32 osmr0, osmr1, osmr2, osmr3;
	u32 ower;
	u32 ossr;
	u32 oier;
	//chy: maybe not regs ????
	u32 os_scale;		//chy: I can not find it in pxa-regs.h????

	/*full function uart controller */
	u32 ffrbr;
	u32 ffthr;
	u32 ffier;
	u32 ffiir;
	u32 fffcr;
	u32 fflcr;
	u32 ffmcr;
	u32 fflsr;
	u32 ffmsr;
	u32 ffspr;
	u32 ffisr;
	u32 ffdll;
	u32 ffdlh;

	u32 ff_scale;
	/*bluetooth function uart controller */
	u32 btrbr;
	u32 btthr;
	u32 btier;
	u32 btiir;
	u32 btfcr;
	u32 btlcr;
	u32 btmcr;
	u32 btlsr;
	u32 btmsr;
	u32 btspr;
	u32 btisr;
	u32 btdll;
	u32 btdlh;
	/*standard uart controller */
	u32 strbr;
	u32 stthr;
	u32 stier;
	u32 stiir;
	u32 stfcr;
	u32 stlcr;
	u32 stmcr;
	u32 stlsr;
	u32 stmsr;
	u32 stspr;
	u32 stisr;
	u32 stdll;
	u32 stdlh;
	/*core clock */
	u32 cccr;
	u32 cken;
	u32 oscc;

	//ywc,2004-11-30,add io of LCD and Touchscreen
	  /*LCD*/
		/* remove them later. */
	  u32 lccr0;
	u32 lccr1;
	u32 lccr2;
	u32 lccr3;

	u32 fdadr0;
	u32 fdadr1;

	u32 fsadr0;
	u32 fsadr1;

	/*TouchScreen */
	u32 ts_int;
	u32 ts_buffer[8];
	u32 ts_addr_begin;
	u32 ts_addr_end;
	//ywc,2004-11-30,add io of LCD and Touchscreen,end

} pxa270_io_t;
//chy 2009-09-19 from skyeye_mach_pxa270.c to here-----end
#endif
