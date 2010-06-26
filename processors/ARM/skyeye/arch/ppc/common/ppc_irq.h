#ifndef _ASM_POWERPC_IRQ_H
#define _ASM_POWERPC_IRQ_H

/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version
 * 2 of the License, or (at your option) any later version.
 */


/*
 * These constants are used for passing information about interrupt
 * signal polarity and level/edge sensing to the low-level PIC chip
 * drivers.
 */
#define IRQ_SENSE_MASK		0x1
#define IRQ_SENSE_LEVEL		0x1	/* interrupt on active level */
#define IRQ_SENSE_EDGE		0x0	/* interrupt triggered by edge */

#define IRQ_POLARITY_MASK	0x2
#define IRQ_POLARITY_POSITIVE	0x2	/* high level or low->high edge */
#define IRQ_POLARITY_NEGATIVE	0x0	/* low level or high->low edge */



/* These values must be zero-based and map 1:1 with the SIU configuration.
 * They are used throughout the 8xx I/O subsystem to generate
 * interrupt masks, flags, and other control patterns.  This is why the
 * current kernel assumption of the 8259 as the base controller is such
 * a pain in the butt.
 */
#define	SIU_IRQ0	(0)	/* Highest priority */
#define	SIU_LEVEL0	(1)
#define	SIU_IRQ1	(2)
#define	SIU_LEVEL1	(3)
#define	SIU_IRQ2	(4)
#define	SIU_LEVEL2	(5)
#define	SIU_IRQ3	(6)
#define	SIU_LEVEL3	(7)
#define	SIU_IRQ4	(8)
#define	SIU_LEVEL4	(9)
#define	SIU_IRQ5	(10)
#define	SIU_LEVEL5	(11)
#define	SIU_IRQ6	(12)
#define	SIU_LEVEL6	(13)
#define	SIU_IRQ7	(14)
#define	SIU_LEVEL7	(15)

#define MPC8xx_INT_FEC1		SIU_LEVEL1
#define MPC8xx_INT_FEC2		SIU_LEVEL3

#define MPC8xx_INT_SCC1		(CPM_IRQ_OFFSET + CPMVEC_SCC1)
#define MPC8xx_INT_SCC2		(CPM_IRQ_OFFSET + CPMVEC_SCC2)
#define MPC8xx_INT_SCC3		(CPM_IRQ_OFFSET + CPMVEC_SCC3)
#define MPC8xx_INT_SCC4		(CPM_IRQ_OFFSET + CPMVEC_SCC4)
#define MPC8xx_INT_SMC1		(CPM_IRQ_OFFSET + CPMVEC_SMC1)
#define MPC8xx_INT_SMC2		(CPM_IRQ_OFFSET + CPMVEC_SMC2)


/* Internal IRQs on MPC85xx OpenPIC */

#ifndef MPC85xx_OPENPIC_IRQ_OFFSET
#ifdef CONFIG_CPM2
#define MPC85xx_OPENPIC_IRQ_OFFSET	(CPM_IRQ_OFFSET + NR_CPM_INTS)
#else
#define MPC85xx_OPENPIC_IRQ_OFFSET	0
#endif
#endif

#define CPM_IRQ_OFFSET			0

/* Not all of these exist on all MPC85xx implementations */
#define MPC85xx_IRQ_L2CACHE	( 0 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_ECM		( 1 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_DDR		( 2 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_LBIU	( 3 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_DMA0	( 4 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_DMA1	( 5 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_DMA2	( 6 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_DMA3	( 7 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_PCI1	( 8 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_PCI2	( 9 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_RIO_ERROR	( 9 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_RIO_BELL	(10 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_RIO_TX	(11 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_RIO_RX	(12 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_TSEC1_TX	(13 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_TSEC1_RX	(14 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_TSEC3_TX	(15 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_TSEC3_RX	(16 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_TSEC3_ERROR	(17 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_TSEC1_ERROR	(18 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_TSEC2_TX	(19 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_TSEC2_RX	(20 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_TSEC4_TX	(21 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_TSEC4_RX	(22 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_TSEC4_ERROR	(23 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_TSEC2_ERROR	(24 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_FEC		(25 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_DUART	(26 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_IIC1	(27 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_PERFMON	(28 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_SEC2	(29 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_CPM		(30 + MPC85xx_OPENPIC_IRQ_OFFSET)

/* The 12 external interrupt lines */
#define MPC85xx_IRQ_EXT0        (48 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_EXT1        (49 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_EXT2        (50 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_EXT3        (51 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_EXT4        (52 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_EXT5        (53 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_EXT6        (54 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_EXT7        (55 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_EXT8        (56 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_EXT9        (57 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_EXT10       (58 + MPC85xx_OPENPIC_IRQ_OFFSET)
#define MPC85xx_IRQ_EXT11       (59 + MPC85xx_OPENPIC_IRQ_OFFSET)

/* CPM related interrupts */
#define	SIU_INT_ERROR		((uint)0x00+CPM_IRQ_OFFSET)
#define	SIU_INT_I2C		((uint)0x01+CPM_IRQ_OFFSET)
#define	SIU_INT_SPI		((uint)0x02+CPM_IRQ_OFFSET)
#define	SIU_INT_RISC		((uint)0x03+CPM_IRQ_OFFSET)
#define	SIU_INT_SMC1		((uint)0x04+CPM_IRQ_OFFSET)
#define	SIU_INT_SMC2		((uint)0x05+CPM_IRQ_OFFSET)
#define	SIU_INT_USB		((uint)0x0b+CPM_IRQ_OFFSET)
#define	SIU_INT_TIMER1		((uint)0x0c+CPM_IRQ_OFFSET)
#define	SIU_INT_TIMER2		((uint)0x0d+CPM_IRQ_OFFSET)
#define	SIU_INT_TIMER3		((uint)0x0e+CPM_IRQ_OFFSET)
#define	SIU_INT_TIMER4		((uint)0x0f+CPM_IRQ_OFFSET)
#define	SIU_INT_FCC1		((uint)0x20+CPM_IRQ_OFFSET)
#define	SIU_INT_FCC2		((uint)0x21+CPM_IRQ_OFFSET)
#define	SIU_INT_FCC3		((uint)0x22+CPM_IRQ_OFFSET)
#define	SIU_INT_MCC1		((uint)0x24+CPM_IRQ_OFFSET)
#define	SIU_INT_MCC2		((uint)0x25+CPM_IRQ_OFFSET)
#define	SIU_INT_SCC1		((uint)0x28+CPM_IRQ_OFFSET)
#define	SIU_INT_SCC2		((uint)0x29+CPM_IRQ_OFFSET)
#define	SIU_INT_SCC3		((uint)0x2a+CPM_IRQ_OFFSET)
#define	SIU_INT_SCC4		((uint)0x2b+CPM_IRQ_OFFSET)
#define	SIU_INT_PC15		((uint)0x30+CPM_IRQ_OFFSET)
#define	SIU_INT_PC14		((uint)0x31+CPM_IRQ_OFFSET)
#define	SIU_INT_PC13		((uint)0x32+CPM_IRQ_OFFSET)
#define	SIU_INT_PC12		((uint)0x33+CPM_IRQ_OFFSET)
#define	SIU_INT_PC11		((uint)0x34+CPM_IRQ_OFFSET)
#define	SIU_INT_PC10		((uint)0x35+CPM_IRQ_OFFSET)
#define	SIU_INT_PC9		((uint)0x36+CPM_IRQ_OFFSET)
#define	SIU_INT_PC8		((uint)0x37+CPM_IRQ_OFFSET)
#define	SIU_INT_PC7		((uint)0x38+CPM_IRQ_OFFSET)
#define	SIU_INT_PC6		((uint)0x39+CPM_IRQ_OFFSET)
#define	SIU_INT_PC5		((uint)0x3a+CPM_IRQ_OFFSET)
#define	SIU_INT_PC4		((uint)0x3b+CPM_IRQ_OFFSET)
#define	SIU_INT_PC3		((uint)0x3c+CPM_IRQ_OFFSET)
#define	SIU_INT_PC2		((uint)0x3d+CPM_IRQ_OFFSET)
#define	SIU_INT_PC1		((uint)0x3e+CPM_IRQ_OFFSET)
#define	SIU_INT_PC0		((uint)0x3f+CPM_IRQ_OFFSET)

#endif /* _ASM_IRQ_H */
