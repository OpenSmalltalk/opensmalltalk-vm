/* one part from clps7110 and another from at91.
 * should modify it only for at91.
 * walimis. 2003/7/18
 * */

/*
 * linux/include/asm-arm/arch-clps7110/clps7110.h
 *
 * Written 1998,1999 by Werner Almesberger
 *
 * This file contains the hardware definitions of the CL-PS7110 chip
 */

#ifndef _ASM_ARCH_CLPS7110_H
#define _ASM_ARCH_CLPS7110_H

/*
 * CL-PS7110 internal registers
 *
 * The names will almost certainly clash with something else ... so we'll
 * probably have to prefix them with CLPS7110_ or something equally ugly later.
 */

#define PADR	0x0000		/* Port A Data register ---------------------------- */
#define PBDR	0x0001		/* Port B Data register ---------------------------- */
#define PCDR	0x0002		/* Port C Data register ---------------------------- */
#define PDDR	0x0003		/* Port D Data register ---------------------------- */
#define PADDR	0x0040		/* Port A Data Direction register ------------------ */
#define PBDDR	0x0041		/* Port B Data Direction register ------------------ */
#define PCDDR	0x0042		/* Port C Data Direction register ------------------ */
#define PDDDR	0x0043		/* Port D Data Direction register ------------------ */
#define PEDR	0x0080		/* Port E Data register ---------------------------- */
#define PEDDR	0x00c0		/* Port E Data Direction register ------------------ */

#define	SYSCON	0x0100		/* System Control register ------------------------- */
#define KBDSCAN	0x0000000f	/* Keyboard scan */
#define KBSC_HI	    0x0		/*   All driven high */
#define KBSC_LO	    0x1		/*   All driven low */
#define KBSC_X	    0x2		/*   All high impedance */
#define KBSC_COL0   0x8		/*   Column 0 high, others high impedance */
#define KBSC_COL1   0x9		/*   Column 1 high, others high impedance */
#define KBSC_COL2   0xa		/*   Column 2 high, others high impedance */
#define KBSC_COL3   0xb		/*   Column 3 high, others high impedance */
#define KBSC_COL4   0xc		/*   Column 4 high, others high impedance */
#define KBSC_COL5   0xd		/*   Column 5 high, others high impedance */
#define KBSC_COL6   0xe		/*   Column 6 high, others high impedance */
#define KBSC_COL7   0xf		/*   Column 7 high, others high impedance */
#define TC1M	0x00000010	/* TC1 mode (0: free-running, 1: prescale) */
#define TC1S	0x00000020	/* TC1 clock source (0: 2 kHz, 1: 512 kHz) */
#define TC2M	0x00000040	/* TC2 mode (0: free-running, 1: prescale) */
#define TC2S	0x00000080	/* TC2 clock source (0: 2 kHz, 1: 512 kHz) */
#define UARTEN	0x00000100	/* Internal UART enable */
#define BZTOG	0x00000200	/* Drive buzzer directly */
#define BZMOD	0x00000400	/* Buzzer drive mode (0: BZTOG, 1: TC1 under-flow) */
#define DBGEN	0x00000800	/* Debug mode */
#define	LCDEN	0x00001000	/* LCD enable */
#define CDENTX	0x00002000	/* Codec interface enable Tx */
#define CDENRX	0x00004000	/* Codec interface enable Rx */
#define SIREN	0x00008000	/* HP SIR protocol encoding enable */
#define	ADCKSEL	0x00030000	/* Microwire/SPI peripheral clock speed select */
#define ADCKSEL_SHIFT	16
#define ADCS_8	    0x0		/*   Sample 8 kHz, interface 4 kHz */
#define ADCS_32	    0x1		/*   32/16 kHz */
#define ADCS_128    0x2		/*   128/64 kHz */
#define ADCS_256    0x3		/*   256/128 kHz */
#define EXCKEN	0x00040000	/* External expansion clock enable */
#define WAKEDIS	0x00080000	/* Disable switch-on through wake-up */
#define IRTXM	0x00100000	/* IrDA Tx mode (0: 3/16 of rate, 1: 1.63 us) */

#define SYSFLG	0x0140		/* System Status Flags register -------------------- */
#define MCDR	0x00000001	/* Media changed direct read */
#define DCDET	0x00000002	/* Main adapter is powering the system */
#define WUDR	0x00000004	/* Wake-up direct read */
#define WUON	0x00000008	/* Left standby on wake-up */
#define DID	0x000000f0	/* Display ID nibble */
#define DID_SHIFT	4
#define CTS	0x00000100	/* UART CTS */
#define DSR	0x00000200	/* UART DSR */
#define DCD	0x00000400	/* UART DCD */
#define UBUSY	0x00000800	/* UART transmitter busy */
#define NBFLG	0x00001000	/* New battery flag */
#define RSTFLG	0x00002000	/* Reset flag */
#define PFFLG	0x00004000	/* Power fail flag */
#define CLDFLG	0x00008000	/* Cold start flag */
#define RTCDIV	0x003f0000	/* 64 Hz ticks since last RTC increment */
#define RTCDIV_SHIFT	16
#define URXFE	0x00400000	/* UART receiver FIFO empty */
#define UTXFF	0x00800000	/* UART transmit FIFO full */
#define CRXFE	0x01000000	/* Codec Rx FIFO empty */
#define CTXFF	0x02000000	/* Codec Tx FIFO full */
#define SSIBUSY 0x04000000	/* Synchronous serial interface busy */
#define BOOT8BIT 0x80000000	/* Initial bus width (0: 32 bit, 1: 8 bit) */
#define VERID	0xc0000000	/* Version ID */
#define VERID_SHIFT	30

#define MEMCFG1	0x0180		/* Memory Configuration register 1 ----------------- */
#define MEMCFG2	0x01c0		/* Memory Configuration register 2 ----------------- */
#define CS_BW	0x03		/* Bus width */
#define CS_BW_BUS32_E0	 0	/*   32 bit if E=0 */
#define CS_BW_BUS16_E0	 1	/*   16 bit if E=0 */
#define CS_BW_BUS8_E0	 2	/*    8 bit if E=0 */
#define CS_BW_PCMCIA_E0	 3	/*   PCMCIA if E=0 */
#define CS_BW_BUS8_E1	 0	/*    8 bit if E=1 */
#define CS_BW_PCMCIA_E1	 1	/*   PCMCIA if E=1 */
#define CS_BW_BUS32_E1	 2	/*   32 bit if E=1 */
#define CS_BW_BUS16_E1	 3	/*   16 bit if E=1 */
#define CS_RAWT	0x0c		/* Random Access Wait State */
#define CS_RAWT_SHIFT	2	/*   WS = 4-N; speed = 50+50*WS ns */
#define CS_SAWR	0x30		/* Sequential Access Wait State */
#define CS_SAWR_SHIFT	4	/*   WS = 3-N; speed[WS] = 40,80,120,150 ns */
#define CS_SQAEN 0x40		/* Sequential Access Enable */
#define CS_CLKEN 0x80		/* Expansion Clock Enable */
#define DRFPR	0x0200

#define INTSR	0x0240		/* Interrupt Status register ----------------------- */
#define EXTFIQ	0x00000001	/* External fast interrupt */
#define BLINT	0x00000002	/* Battery low interrupt */
#define WEINT	0x00000004	/* Watch dog expired interrupt */
#define MCINT	0x00000008	/* Media changed interrupt */
#define CSINT	0x00000010	/* Codec sound interrupt */
#define EINT1	0x00000020	/* External interrupt 1 */
#define EINT2	0x00000040	/* External interrupt 2 */
#define EINT3	0x00000080	/* External interrupt 3 */
#define TC1OI	0x00000100	/* TC1 under-flow interrupt */
#define TC2OI	0x00000200	/* TC2 under-flow interrupt */
#define RTCMI	0x00000400	/* RTC compare match interrupt */
#define TINT	0x00000800	/* 64-Hz tick interrupt */
#define UTXINT	0x00001000	/* Internal UART transmit FIFO half-empty intr. */
#define URXINT	0x00002000	/* Internal UART receive FIFO half-full interrupt */
#define UMSINT	0x00004000	/* Internal UART modem status changed interrupt */
#define SSEOTI	0x00008000	/* Synchronous serial interface end-of-transfer */

#define INTMR	0x0280		/* Interrupt Mask register ------------------------- */

#define LCDCON	0x02c0		/* LCD Control register ---------------------------- */
#define VBUFSIZ	0x00001fff	/* Video buffer size (bits/128-1) */
#define LINELEN	0x0007e000	/* Line length (pix/16-1) */
#define LINELEN_SHIFT	13
#define	PIXPSC	0x01f80000	/* Pixel prescale (526628/pixels-1) */
#define PIXPSC_SHIFT	19
#define ACPSC	0x3e000000	/* AC prescale */
#define ACPSC_SHIFT	25
#define GSEN	0x40000000	/* Grayscale enable (0: monochrome) */
#define	GSMD	0x80000000	/* Grayscale mode (0: 2 bit, 1: 4 bit) */

#define TC1D	0x0300		/* Timer Counter 1 Data register ------------------- */
#define TC_MASK	0x0000ffff
#define TC2D	0x0340		/* Timer Counter 2 Data register ------------------- */

#define RTCDR	0x0380		/* Realtime Clock Data register -------------------- */

#define RTCMR	0x03c0		/* Realtime Clock Match register ------------------- */

#define PMPCON	0x0400

#define CODR	0x0440		/* Codec Interface Data register ------------------- */

#define UARTDR	0x0480		/* UART FIFO Data register ------------------------- */
#define RX_DATA	0x000000ff	/* Rx data */
#define FRMERR	0x00000100	/* UART framing error */
#define PARERR	0x00000200	/* UART parity error */
#define OVERR	0x00000400	/* UART overrun error */

#define UBRLCR	0x04c0		/* UART Bit Rate and Line Control register --------- */
#define BRDIV	0x00000fff	/* Bit rate divisor */
#define BR_115200    1
#define BR_57600     3
#define BR_38400     5
#define BR_19200     11
#define BR_9600      23
#define BR_2400      95
#define BR_1200      191
#define BREAK	0x00001000	/* Set Tx high */
#define PRTEN	0x00002000	/* Parity enable */
#define EVENPRT 0x00004000	/* Even parity */
#define XSTOP	0x00008000	/* Extra stop bit */
#define FIFOEN  0x00010000	/* Enable FIFO */
#define WRDLEN	0x00030000	/* Word length */
#define WRDLEN_SHIFT	17
#define WL_5	    0x0		/*   5 bits */
#define WL_6	    0x1		/*   6 bits */
#define WL_7	    0x2		/*   7 bits */
#define WL_8	    0x3		/*   8 bits */

#define SYNCIO	0x0500
#define	TXFRMEN	0x00004000	/* Initiate data transfer */
#define	SMCKEN	0x00002000	/* Enable sample clock on SMPLCK */
#define FRLEN	0x00001f00	/* Frame length */
#define FRLEN_SHIFT	8
#define ADCCFB	0x000000ff	/* ADC Configuration byte */
#define ADCRSW	0x0000ffff	/* ADC result word */

#define PALLSW	0x0540		/* Least-significant 32-bit word of LCD Palette reg. */
#define PALMSW	0x0580		/* Most-significant 32-bit word of LCD Palette reg. */

#define STFCLR	0x05c0		/* Write to clear all start up reason flags -------- */
#define BLEOI	0x0600		/* Write to clear Battery Low interrupt ------------ */
#define MCEOI	0x0640		/* Write to clear Media Changed interrupt ---------- */
#define TEOI	0x0680		/* Write to clear Tick and Watchdog interrupt ------ */
#define TC1EOI	0x06c0		/* Write to clear TC1 interrupt -------------------- */
#define TC2EOI	0x0700		/* Write to clear TC2 interrupt -------------------- */
#define RTCEOI	0x0740		/* Write to clear RTC Match interrupt -------------- */
#define UMSEOI	0x0780		/* Write to clear UART Modem Status Changed interrupt */
#define COEOI	0x07c0		/* Write to clear Codec Sound interrupt ------------ */
#define HALT	0x0800		/* Write to enter idle state ----------------------- */
#define STDBY	0x0840		/* Write to standby state -------------------------- */

/*
 * CL-PS7110 PCMCIA memory constants
 *
 * Need to #define PCMCIA_BASE before using these macros.
 */

#define PCMCIA_ATTR8(a)	(PCMCIA_BASE+0x00000000+(a))
#define PCMCIA_MEM(a)	(PCMCIA_BASE+0x04000000+(a))
#define PCMCIA_IO8(a)	(PCMCIA_BASE+0x08000000+(a))
#define PCMCIA_IO16(a)	(PCMCIA_BASE+0x0c000000+((a) & ~3)+(((a) & 2) << 24))

/* below from linux/include/asm-arm/arch-atmel/hardware.h
 * skyeye_mach_at91.c should use it.
 * walimis. 2003/7/18
 * */

/*
 * linux/include/asm-arm/arch-atmel/hardware.h
 * for Atmel AT91 series
 * 2001 Erwin Authried
 */


/* 0=TC0, 1=TC1, 2=TC2 */
#define KERNEL_TIMER 1

#ifdef CONFIG_CPU_AT91X40
/*
 ******************* AT91x40xxx ********************
 */

#define ARM_CLK		(32768000)

#define AT91_USART_CNT 2
#define AT91_USART0_BASE	(0xfffd0000)
#define AT91_USART1_BASE	(0xfffcc000)
#define AT91_TC_BASE		(0xfffe0000)
#define AIC_BASE		(0xfffff000)
#define AT91_PIOA_BASE		(0xffff0000)
#define AT91_SF_CIDR		(0xfff00000)

#define HARD_RESET_NOW()

#define HW_AT91_TIMER_INIT(timer)	/* no PMC */

/* use TC0 as hardware timer to create high resolution timestamps for debugging.
 *  Timer 0 must be set up as a free running counter, e.g. in the bootloader
 */
#define HW_COUNTER  (((struct at91_timers *)AT91_TC_BASE)->chans[0].ch.cv)

/* enable US0,US1 */
#define HW_AT91_USART_INIT ((volatile struct pio_regs *)AT91_PIOA_BASE)->pdr = \
				PIOA_RXD0|PIOA_TXD0|PIOA_RXD1|PIOA_TXD1;
/* PIOA bit allocation */
#define PIOA_TCLK0	(1<<0)
#define PIOA_TI0A0	(1<<1)
#define PIOA_TI0B0	(1<<2)
#define PIOA_TCLK1	(1<<3)
#define PIOA_TIOA1	(1<<4)
#define PIOA_TIOB1	(1<<5)
#define PIOA_TCLK2	(1<<6)
#define PIOA_TIOA2	(1<<7)
#define PIOA_TIOB2	(1<<8)
#define PIOA_IRQ0	(1<<9)
#define PIOA_IRQ1	(1<<10)
#define PIOA_IRQ2	(1<<11)
#define PIOA_FIQ	(1<<12)
#define PIOA_SCK0	(1<<13)
#define PIOA_TXD0	(1<<14)
#define PIOA_RXD0	(1<<15)

#define PIOA_SCK1	(1<<20)
#define PIOA_TXD1	(1<<21)
#define PIOA_RXD1	(1<<22)

#define PIOA_MCK0	(1<<25)
#define PIOA_NCS2	(1<<26)
#define PIOA_NCS3	(1<<27)

#define PIOA_A20_CS7	(1<<28)
#define PIOA_A21_CS6	(1<<29)
#define PIOA_A22_CS5	(1<<30)
#define PIOA_A23_CS4	(1<<31)

#elif CONFIG_CPU_AT91X63
/*
 ******************* AT91x63xxx ********************
 */

#define ARM_CLK		(25000000)

#define AT91_USART_CNT 2
#define AT91_USART0_BASE	(0xfffc0000)
#define AT91_USART1_BASE	(0xfffc4000)
#define AT91_TC_BASE		(0xfffd0000)
#define AIC_BASE		(0xfffff000)
#define AT91_PIOA_BASE 		(0xfffec000)
#define AT91_PIOB_BASE 		(0xffff0000)
#define AT91_PMC_BASE		(0xffff4000)

#define HARD_RESET_NOW()

/* enable US0,US1 */
#define HW_AT91_USART_INIT ((volatile struct pmc_regs *)AT91_PMC_BASE)->pcer = \
				(1<<2) | (1<<3) | (1<<13); \
			   ((volatile struct pio_regs *)AT91_PIOA_BASE)->pdr = \
				PIOA_RXD0|PIOA_TXD0|PIOA_RXD1|PIOA_TXD1;

#define HW_AT91_TIMER_INIT(timer) ((volatile struct pmc_regs *)AT91_PMC_BASE)->pcer = \
				1<<(timer+6);

/* PIOA bit allocation */
#define PIOA_TCLK3	(1<<0)
#define PIOA_TI0A3	(1<<1)
#define PIOA_TI0B3	(1<<2)
#define PIOA_TCLK4	(1<<3)
#define PIOA_TI0A4	(1<<4)
#define PIOA_TI0B4	(1<<5)
#define PIOA_TCLK5	(1<<6)
#define PIOA_TI0A5	(1<<7)
#define PIOA_TI0B5	(1<<8)
#define PIOA_IRQ0	(1<<9)
#define PIOA_IRQ1	(1<<10)
#define PIOA_IRQ2	(1<<11)
#define PIOA_IRQ3	(1<<12)
#define PIOA_FIQ	(1<<13)
#define PIOA_SCK0	(1<<14)
#define PIOA_TXD0	(1<<15)
#define PIOA_RXD0	(1<<16)
#define PIOA_SCK1	(1<<17)
#define PIOA_TXD1	(1<<18)
#define PIOA_RXD1	(1<<19)
#define PIOA_SCK2	(1<<20)
#define PIOA_TXD2	(1<<21)
#define PIOA_RXD2	(1<<22)
#define PIOA_SPCK	(1<<23)
#define PIOA_MISO	(1<<24)
#define PIOA_MOSI	(1<<25)
#define PIOA_NPCS0	(1<<26)
#define PIOA_NPCS1	(1<<27)
#define PIOA_NPCS2	(1<<28)
#define PIOA_NPCS3	(1<<29)

/* PIOB bit allocation */
#define PIOB_MPI_NOE	(1<<0)
#define PIOB_MPI_NLB	(1<<1)
#define PIOB_MPI_NUB	(1<<2)

#define PIOB_MCK0	(1<<17)
#define PIOB_BMS	(1<<18)
#define PIOB_TCLK0	(1<<19)
#define PIOB_TIOA0	(1<<20)
#define PIOB_TIOB0	(1<<21)
#define PIOB_TCLK1	(1<<22)
#define PIOB_TIOA1	(1<<23)
#define PIOB_TIOB1	(1<<24)
#define PIOB_TCLK2	(1<<25)
#define PIOB_TIOA2	(1<<26)
#define PIOB_TIOB2	(1<<27)
#else
 // #error "Configuration error: No CPU defined"
#endif

/*
 ******************* COMMON PART ********************
 */
#define AIC_SMR(i)  (AIC_BASE+i*4)
#define AIC_IVR	    (AIC_BASE+0x100)
#define AIC_FVR	    (AIC_BASE+0x104)
#define AIC_ISR	    (AIC_BASE+0x108)
#define AIC_IPR	    (AIC_BASE+0x10C)
#define AIC_IMR	    (AIC_BASE+0x110)
#define AIC_CISR	(AIC_BASE+0x114)
#define AIC_IECR	(AIC_BASE+0x120)
#define AIC_IDCR	(AIC_BASE+0x124)
#define AIC_ICCR	(AIC_BASE+0x128)
#define AIC_ISCR	(AIC_BASE+0x12C)
#define AIC_EOICR   (AIC_BASE+0x130)


#ifndef __ASSEMBLER__
struct at91_timer_channel
{
	unsigned int ccr;	// channel control register             (WO)
	unsigned int cmr;	// channel mode register                (RW)
	unsigned int reserved[2];
	unsigned int cv;	// counter value                                (RW)
	unsigned int ra;	// register A                                   (RW)
	unsigned int rb;	// register B                                   (RW)
	unsigned int rc;	// register C                                   (RW)
	unsigned int sr;	// status register                              (RO)
	unsigned int ier;	// interrupt enable register    (WO)
	unsigned int idr;	// interrupt disable register   (WO)
	unsigned int imr;	// interrupt mask register              (RO)
};

struct at91_timers
{
	struct
	{
		struct at91_timer_channel ch;
		unsigned char padding[0x40 -
				      sizeof (struct at91_timer_channel)];
	} chans[3];
	unsigned int bcr;	// block control register               (WO)
	unsigned int bmr;	// block mode    register               (RW)
};
#endif

#define IRQ_FIQ         0
#define IRQ_SWI         1
#define IRQ_USART0      2
#define IRQ_USART1      3
#define IRQ_TC0         4
#define IRQ_TC1         5
#define IRQ_TC2         6
#define IRQ_WD          7
#define IRQ_PIOA        8

#define IRQ_EXT0        16
#define IRQ_EXT1        17
#define IRQ_EXT2        18


/*  TC control register */
#define TC_SYNC	(1)

/*  TC mode register */
#define TC2XC2S(x)	(x & 0x3)
#define TC1XC1S(x)	(x<<2 & 0xc)
#define TC0XC0S(x)	(x<<4 & 0x30)
#define TCNXCNS(timer,v) ((v) << (timer<<1))

/* TC channel control */
#define TC_CLKEN	(1)
#define TC_CLKDIS	(1<<1)
#define TC_SWTRG	(1<<2)

/* TC interrupts enable/disable/mask and status registers */
#define TC_MTIOB	(1<<18)
#define TC_MTIOA	(1<<17)
#define TC_CLKSTA	(1<<16)

#define TC_ETRGS	(1<<7)
#define TC_LDRBS	(1<<6)
#define TC_LDRAS	(1<<5)
#define TC_CPCS		(1<<4)
#define TC_CPBS		(1<<3)
#define TC_CPAS		(1<<2)
#define TC_LOVRS	(1<<1)
#define TC_COVFS	(1)

/*
 *	USART registers
 */


/*  US control register */
#define US_SENDA	(1<<12)
#define US_STTO		(1<<11)
#define US_STPBRK	(1<<10)
#define US_STTBRK	(1<<9)
#define US_RSTSTA	(1<<8)
#define US_TXDIS	(1<<7)
#define US_TXEN		(1<<6)
#define US_RXDIS	(1<<5)
#define US_RXEN		(1<<4)
#define US_RSTTX	(1<<3)
#define US_RSTRX	(1<<2)

/* US mode register */
#define US_CLK0		(1<<18)
#define US_MODE9	(1<<17)
#define US_CHMODE(x)(x<<14 & 0xc000)
#define US_NBSTOP(x)(x<<12 & 0x3000)
#define US_PAR(x)	(x<<9 & 0xe00)
#define US_SYNC		(1<<8)
#define US_CHRL(x)	(x<<6 & 0xc0)
#define US_USCLKS(x)(x<<4 & 0x30)

/* US interrupts enable/disable/mask and status register */
#define US_DMSI		(1<<10)
#define US_TXEMPTY	(1<<9)
#define US_TIMEOUT	(1<<8)
#define US_PARE		(1<<7)
#define US_FRAME	(1<<6)
#define US_OVRE		(1<<5)
#define US_ENDTX	(1<<4)
#define US_ENDRX	(1<<3)
#define US_RXBRK	(1<<2)
#define US_TXRDY	(1<<1)
#define US_RXRDY	(1)

#define US_ALL_INTS (US_DMSI|US_TXEMPTY|US_TIMEOUT|US_PARE|US_FRAME|US_OVRE|US_ENDTX|US_ENDRX|US_RXBRK|US_TXRDY|US_RXRDY)

#ifndef __ASSEMBLER__
struct atmel_usart_regs
{
	unsigned int cr;	// control 
	unsigned int mr;	// mode
	unsigned int ier;	// interrupt enable
	unsigned int idr;	// interrupt disable
	unsigned int imr;	// interrupt mask
	unsigned int csr;	// channel status
	unsigned int rhr;	// receive holding 
	unsigned int thr;	// tramsmit holding             
	unsigned int brgr;	// baud rate generator          
	unsigned int rtor;	// rx time-out
	unsigned int ttgr;	// tx time-guard
	unsigned int res1;
	unsigned int rpr;	// rx pointer
	unsigned int rcr;	// rx counter
	unsigned int tpr;	// tx pointer
	unsigned int tcr;	// tx counter
};
#endif

#define PIO(i)		(1<<i)

#ifndef __ASSEMBLER__
struct pio_regs
{
	unsigned int per;
	unsigned int pdr;
	unsigned int psr;
	unsigned int res1;
	unsigned int oer;
	unsigned int odr;
	unsigned int osr;
	unsigned int res2;
	unsigned int ifer;
	unsigned int ifdr;
	unsigned int ifsr;
	unsigned int res3;
	unsigned int sodr;
	unsigned int codr;
	unsigned int odsr;
	unsigned int pdsr;
	unsigned int ier;
	unsigned int idr;
	unsigned int imr;
	unsigned int isr;
};
#endif

#ifndef __ASSEMBLER__
struct pmc_regs
{
	unsigned int scer;
	unsigned int scdr;
	unsigned int scsr;
	unsigned int reserved;
	unsigned int pcer;
	unsigned int pcdr;
	unsigned int pcsr;
};
#endif



#endif
