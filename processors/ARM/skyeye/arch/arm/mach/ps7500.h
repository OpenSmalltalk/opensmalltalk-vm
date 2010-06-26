
#define IOMD_CONTROL	(0x000)
#define IOMD_KARTTX	(0x004)
#define IOMD_KARTRX	(0x004)
#define IOMD_KCTRL	(0x008)

#define IOMD_IOLINES	(0x00C)

#define IOMD_IRQSTATA	(0x010)
#define IOMD_IRQREQA	(0x014)
#define IOMD_IRQCLRA	(0x014)
#define IOMD_IRQMASKA	(0x018)

#define IOMD_SUSMODE	(0x01C)

#define IOMD_IRQSTATB	(0x020)
#define IOMD_IRQREQB	(0x024)
#define IOMD_IRQMASKB	(0x028)

#define IOMD_FIQSTAT	(0x030)
#define IOMD_FIQREQ	(0x034)
#define IOMD_FIQMASK	(0x038)

#define IOMD_CLKCTL	(0x03C)

#define IOMD_T0CNTL	(0x040)
#define IOMD_T0LTCHL	(0x040)
#define IOMD_T0CNTH	(0x044)
#define IOMD_T0LTCHH	(0x044)
#define IOMD_T0GO	(0x048)
#define IOMD_T0LATCH	(0x04c)

#define IOMD_T1CNTL	(0x050)
#define IOMD_T1LTCHL	(0x050)
#define IOMD_T1CNTH	(0x054)
#define IOMD_T1LTCHH	(0x054)
#define IOMD_T1GO	(0x058)
#define IOMD_T1LATCH	(0x05c)

#define IOMD_IRQSTATC	(0x060)
#define IOMD_IRQREQC	(0x064)
#define IOMD_IRQMASKC	(0x068)

#define IOMD_VIDMUX	(0x06c)

#define IOMD_IRQSTATD	(0x070)
#define IOMD_IRQREQD	(0x074)
#define IOMD_IRQMASKD	(0x078)

#define IOMD_ROMCR0	(0x080)
#define IOMD_ROMCR1	(0x084)
#define IOMD_REFCR	(0x08C)

#define IOMD_FSIZE	(0x090)
#define IOMD_ID0	(0x094)
#define IOMD_ID1	(0x098)
#define IOMD_VERSION	(0x09C)

#define IOMD_MOUSEX	(0x0A0)
#define IOMD_MOUSEY	(0x0A4)

#define IOMD_MSEDAT	(0x0A8)
#define IOMD_MSECTL	(0x0Ac)

#define IOMD_DMATCR	(0x0C0)
#define IOMD_IOTCR	(0x0C4)
#define IOMD_ECTCR	(0x0C8)
#define IOMD_DMAEXT	(0x0CC)
#define IOMD_ASTCR	(0x0CC)
#define IOMD_DRAMCR	(0x0D0)
#define IOMD_SELFREF	(0x0D4)
#define IOMD_ATODICR	(0x0E0)
#define IOMD_ATODSR	(0x0E4)
#define IOMD_ATODCC	(0x0E8)
#define IOMD_ATODCNT1	(0x0EC)
#define IOMD_ATODCNT2	(0x0F0)
#define IOMD_ATODCNT3	(0x0F4)
#define IOMD_ATODCNT4	(0x0F8)

#define DMA_EXT_IO0	1
#define DMA_EXT_IO1	2
#define DMA_EXT_IO2	4
#define DMA_EXT_IO3	8

#define IOMD_IO0CURA	(0x100)
#define IOMD_IO0ENDA	(0x104)
#define IOMD_IO0CURB	(0x108)
#define IOMD_IO0ENDB	(0x10C)
#define IOMD_IO0CR	(0x110)
#define IOMD_IO0ST	(0x114)

#define IOMD_IO1CURA	(0x120)
#define IOMD_IO1ENDA	(0x124)
#define IOMD_IO1CURB	(0x128)
#define IOMD_IO1ENDB	(0x12C)
#define IOMD_IO1CR	(0x130)
#define IOMD_IO1ST	(0x134)

#define IOMD_IO2CURA	(0x140)
#define IOMD_IO2ENDA	(0x144)
#define IOMD_IO2CURB	(0x148)
#define IOMD_IO2ENDB	(0x14C)
#define IOMD_IO2CR	(0x150)
#define IOMD_IO2ST	(0x154)

#define IOMD_IO3CURA	(0x160)
#define IOMD_IO3ENDA	(0x164)
#define IOMD_IO3CURB	(0x168)
#define IOMD_IO3ENDB	(0x16C)
#define IOMD_IO3CR	(0x170)
#define IOMD_IO3ST	(0x174)

#define IOMD_SD0CURA	(0x180)
#define IOMD_SD0ENDA	(0x184)
#define IOMD_SD0CURB	(0x188)
#define IOMD_SD0ENDB	(0x18C)
#define IOMD_SD0CR	(0x190)
#define IOMD_SD0ST	(0x194)

#define IOMD_SD1CURA	(0x1A0)
#define IOMD_SD1ENDA	(0x1A4)
#define IOMD_SD1CURB	(0x1A8)
#define IOMD_SD1ENDB	(0x1AC)
#define IOMD_SD1CR	(0x1B0)
#define IOMD_SD1ST	(0x1B4)

#define IOMD_CURSCUR	(0x1C0)
#define IOMD_CURSINIT	(0x1C4)

#define IOMD_VIDCUR	(0x1D0)
#define IOMD_VIDEND	(0x1D4)
#define IOMD_VIDSTART	(0x1D8)
#define IOMD_VIDINIT	(0x1DC)
#define IOMD_VIDCR	(0x1E0)

#define IOMD_DMASTAT	(0x1F0)
#define IOMD_DMAREQ	(0x1F4)
#define IOMD_DMAMASK	(0x1F8)

#define IRQ_INT2                0		//IRQA
#define IRQ_INT1                2
#define IRQ_VSYNCPULSE          3
#define IRQ_POWERON             4
#define IRQ_TIMER0              5
#define IRQ_TIMER1              6
#define IRQ_FORCE               7

#define IRQ_INT8                8		//IRQB
#define IRQ_ISA                 9
#define IRQ_INT6                10
#define IRQ_INT5                11
#define IRQ_INT4                12
#define IRQ_INT3                13
#define IRQ_KEYBOARDTX          14
#define IRQ_KEYBOARDRX          15

#define IRQ_DMA0                16		//DMA
#define IRQ_DMA1                17
#define IRQ_DMA2                18
#define IRQ_DMA3                19
#define IRQ_DMAS0               20
#define IRQ_DMAS1               21

#define IRQ_IOP0                24		//IRQC
#define IRQ_IOP1                25
#define IRQ_IOP2                26
#define IRQ_IOP3                27
#define IRQ_IOP4                28
#define IRQ_IOP5                29
#define IRQ_IOP6                30
#define IRQ_IOP7                31

#define IRQ_MOUSERX             40		//IRQD
#define IRQ_MOUSETX             41
#define IRQ_ADC                 42
#define IRQ_EVENT1              43
#define IRQ_EVENT2              44

#define FIQ_INT9                0		// FIQ
#define FIQ_INT5                1
#define FIQ_INT6                4
#define FIQ_INT8                6
#define FIQ_FORCE               7

// KCTRL bits
#define KB_SKC		0x01
#define KB_SKD		0x02
#define KB_RXP		0x04
#define KB_ENA		0x08
#define KB_RXB		0x10
#define KB_RXF		0x20
#define KB_TXB		0x40
#define KB_TXE		0x80

