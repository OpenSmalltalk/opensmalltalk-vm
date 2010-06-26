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
#define EINT2	0x00000040  /* External interrupt 2 */	/*ywc 2004-04-02 used for touch screen interrupt */
#define EINT3	0x00000080	/* External interrupt 3 */
#define TC1OI	0x00000100	/* TC1 under-flow interrupt */
#define TC2OI	0x00000200	/* TC2 under-flow interrupt */
#define RTCMI	0x00000400	/* RTC compare match interrupt */
#define TINT	0x00000800	/* 64-Hz tick interrupt */
#define UTXINT	0x00001000	/* Internal UART transmit FIFO half-empty intr. */
#define URXINT	0x00002000	/* Internal UART receive FIFO half-full interrupt */
#define UMSINT	0x00004000	/* Internal UART modem status changed interrupt */
#define SSEOTI	0x00008000	/* Synchronous serial interface end-of-transfer */
//chy 2003-01-18  add the ext0 irq number offset  is at91 isr
//#define AT91_EXT0    0x00008000  /* Synchronous serial interface end-of-transfer */

#define INTMR	0x0280		/* Interrupt Mask register ------------------------- */
#define INTMR2  0x1280
#define INTMR3  0x2280

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

//ywc,2004-04-01
#define TSBUFFER	0xb000	/* this register contains the start address for touch screen data buffer,
				   this register is not exist in the real hardware------ */

#endif
