#ifndef _SHARP_H_
#define _SHARP_H_

enum
{
	RTC_ALARM_IRQ = (1 << 31),
	RTC_HZ_IRQ = (1 << 30),
	OS_IRQ_SHF = 26,
	FFUART_IRQ = (1 << 22),
};

typedef enum shp_ioregnum_t
{
	/* Interrupt controller */
	INTSR = 0x80000500,	/* Interrupt Status Register */
	INTRSR = 0x80000504,	/* Interrupt Raw Status Register */
	INTENS = 0x80000508,	/* Interrupt Enable Set Register */
	INTENC = 0x8000050C,	/* Interrupt Enable Clear Register */

	/* os timer 1 */
	TIMERLOAD1 = 0x80000C00,	/* Allows setting or reading the initial Timer2Value */
	TIMERVALUE1 = 0x80000C04,	/* Allows reading the current Timer2 value */
	TIMERCONTROL1 = 0x80000C08,	/* Allows setting or reading the Timer2 configuration */
	TIMERTCEOI1 = 0x80000c0C,	/* Clears the Timer2 interrupt */

	/* os timer 2 */
	TIMERLOAD2 = 0x80000C20,	/* Allows setting or reading the initial Timer2Value */
	TIMERVALUE2 = 0x80000C24,	/* Allows reading the current Timer2 value */
	TIMERCONTROL2 = 0x80000C28,	/* Allows setting or reading the Timer2 configuration */
	TIMERTCEOI2 = 0x80000c2C,	/* Clears the Timer2 interrupt */

	/*UART 2 */
	UART2DATA = 0x80000700,	/* Data Register */
	UART2FCON = 0x80000704,	/* FIFO Control Register */
	UART2BRCON = 0x80000708,	/* Baud Rate Control Register */
	UART2CON = 0x8000070C,	/* Control Register */
	UART2STATUS = 0x80000710,	/* Status Register */
	UART2RAWISR = 0x80000714,	/* Raw Interrupt Status Register */
	UART2INTEN = 0x80000718,	/* Interrupt Mask Register */
	UART2ISR = 0x8000071C,	/* Interrupt Status Register */

	CPLDKEYSTATE = 0x20000000,
	CPLDINTSTATE = 0x20000004,
	CPLDINTMASK = 0x20000008,
	CPLDPWRIO = 0x2000000c,
	CPLDEXTIO = 0x20000010,

} shp_ioregnum_t;

#define _BIT(n)         (1 << (n))

/*
 * Interrupt Controller Module Register Structure
 */

typedef struct
{
	volatile u32 status;
	volatile u32 rawstatus;
	volatile u32 enableset;
	volatile u32 enableclear;
} INTCREGS;

/**********************************************************************
 * Interrupt Controller Register Bit Fields
 *********************************************************************/

/* INTC Interrupt Sources */
#define INTC_GPIO0FIQ_BIT       0
#define INTC_BLINTR_BIT         1
#define INTC_WEINTR_BIT         2
#define INTC_MCINTR_BIT         3
#define INTC_CSINTR_BIT         4
#define INTC_GPIO1INTR_BIT      5
#define INTC_GPIO2INTR_BIT      6
#define INTC_GPIO3INTR_BIT      7
#define INTC_TC1OINTR_BIT       8
#define INTC_TC2OINTR_BIT       9
#define INTC_RTCMINTR_BIT       10
#define INTC_TICKINTR_BIT       11
#define INTC_UART1INTR_BIT      12
#define INTC_UART2INTR_BIT      13
#define INTC_LCDINTR_BIT        14
#define INTC_SSEOTINTR_BIT      15
#define INTC_UART3INTR_BIT      16
#define INTC_SCIINTR_BIT        17
#define INTC_AACINTR_BIT        18
#define INTC_MMCINTR_BIT        19
#define INTC_USBINTR_BIT        20
#define INTC_DMAINTR_BIT        21
#define INTC_TC3OINTR_BIT       22
#define INTC_GPIO4INTR_BIT      23
#define INTC_GPIO5INTR_BIT      24
#define INTC_GPIO6INTR_BIT      25
#define INTC_GPIO7INTR_BIT      26
#define INTC_BMIINTR_BIT        27

#define INTC_GPIO0FIQ           _BIT(INTC_GPIO0FIQ_BIT)
#define INTC_BLINTR             _BIT(INTC_BLINTR_BIT)
#define INTC_WEINTR             _BIT(INTC_WEINTR_BIT)
#define INTC_MCINTR             _BIT(INTC_MCINTR_BIT)
#define INTC_CSINTR             _BIT(INTC_CSINTR_BIT)
#define INTC_GPIO1INTR          _BIT(INTC_GPIO1INTR_BIT)
#define INTC_GPIO2INTR          _BIT(INTC_GPIO2INTR_BIT)
#define INTC_GPIO3INTR          _BIT(INTC_GPIO3INTR_BIT)
#define INTC_TC1OINTR           _BIT(INTC_TC1OINTR_BIT)
#define INTC_TC2OINTR           _BIT(INTC_TC2OINTR_BIT)
#define INTC_RTCMINTR           _BIT(INTC_RTCMINTR_BIT)
#define INTC_TICKINTR           _BIT(INTC_TICKINTR_BIT)
#define INTC_UART1INTR          _BIT(INTC_UART1INTR_BIT)
#define INTC_UART2INTR          _BIT(INTC_UART2INTR_BIT)
#define INTC_LCDINTR            _BIT(INTC_LCDINTR_BIT)
#define INTC_SSEOTINTR          _BIT(INTC_SSEOTINTR_BIT)
#define INTC_UART3INTR          _BIT(INTC_UART3INTR_BIT)
#define INTC_SCIINTR            _BIT(INTC_SCIINTR_BIT)
#define INTC_AACINTR            _BIT(INTC_AACINTR_BIT)
#define INTC_MMCINTR            _BIT(INTC_MMCINTR_BIT)
#define INTC_USBINTR            _BIT(INTC_USBINTR_BIT)
#define INTC_DMAINTR            _BIT(INTC_DMAINTR_BIT)
#define INTC_TC3OINTR           _BIT(INTC_TC3OINTR_BIT)
#define INTC_GPIO4INTR          _BIT(INTC_GPIO4INTR_BIT)
#define INTC_GPIO5INTR          _BIT(INTC_GPIO5INTR_BIT)
#define INTC_GPIO6INTR          _BIT(INTC_GPIO6INTR_BIT)
#define INTC_GPIO7INTR          _BIT(INTC_GPIO7INTR_BIT)
#define INTC_BMIINTR            _BIT(INTC_BMIINTR_BIT)

/**********************************************************************
 * Defines for block access to interrupt sources
 *********************************************************************/

#define INTC_ALL_FIQS ( \
                        INTC_GPIO0FIQ | \
                        INTC_BLINTR | \
                        INTC_WEINTR | \
                        INTC_MCINTR)

#define INTC_ALL_IRQS ( \
                        INTC_CSINTR | \
                        INTC_GPIO1INTR | \
                        INTC_GPIO2INTR | \
                        INTC_GPIO3INTR | \
                        INTC_TC1OINTR | \
                        INTC_TC2OINTR | \
                        INTC_RTCMINTR | \
                        INTC_TICKINTR | \
                        INTC_UART1INTR | \
                        INTC_UART2INTR | \
                        INTC_LCDINTR | \
                        INTC_SSEOTINTR | \
                        INTC_UART3INTR | \
                        INTC_SCIINTR | \
                        INTC_AACINTR | \
                        INTC_MMCINTR | \
                        INTC_USBINTR | \
                        INTC_DMAINTR | \
                        INTC_TC3OINTR | \
                        INTC_GPIO4INTR | \
                        INTC_GPIO5INTR | \
                        INTC_GPIO6INTR | \
                        INTC_GPIO7INTR | \
                        INTC_BMIINTR)

#define INTC_ALL_INTS (INTC_ALL_FIQS | INTC_ALL_IRQS)

/**********************************************************************
 * Interrupt Enable Set, Interrupt Enable Clear Registers Bit Fields
 *********************************************************************/
#define INTC_INT_ENABLE(n)		_BIT(n)
#define INTC_INT_CLEAR(n)		_BIT(n)

/*
 * Timer Module Register Structure
 */
typedef struct
{
	volatile u32 load;	/* RW */
	volatile u32 value;	/* RO */
	volatile u32 control;	/* RW */
	volatile u32 clear;	/* WO */
} TIMERREGS;

/**********************************************************************
 * Timer Load Register Bit Fields
 *********************************************************************/
#define TIMER_MAXCOUNT  (0xFFFF)
#define	TIMER_LOAD(n)   ((n) & TIMER_MAXCOUNT)

/**********************************************************************
 * Timer Control Register Bit Fields
 *********************************************************************/
#define TIMER_CTRL_ENABLE       _BIT(7)
#define TIMER_CTRL_DISABLE      (0)
#define TIMER_CTRL_PERIODIC     _BIT(6)
#define TIMER_CTRL_FREERUN      (0)
#define TIMER_CTRL_508K         _BIT(3)
#define TIMER_CTRL_2K           (0)

/*
 * UART Module Register Structure
 */
typedef struct
{
	volatile u32 data;	// 0  Data
	volatile u32 lcr;	// 4  Line Control
	volatile u32 bcr;	// 8  Baud Rate Control
	volatile u32 control;	// c  Control
	volatile u32 status;	// 10 Status Flag
	volatile u32 intraw;	// 14 Raw Interrupt
	volatile u32 inte;	// 18 Interrupt Enable
	volatile u32 intr;	// 1c Resultant Interrupt
} UARTREGS;

#define UART_NUM_MAX    3	// maximum number of UART's

/***********************************************************************
 * UART Data Register Bit Fields
 **********************************************************************/
#define UART_DATA_BE         _BIT(11)	// Break Error
#define UART_DATA_OE         _BIT(10)	// Overrun Error
#define UART_DATA_PE         _BIT(9)	// Parity Error
#define UART_DATA_FE         _BIT(8)	// Framing Error
#define UART_DATA_MASK       (0xFF)	// Data (8 bits)

/***********************************************************************
 * UART Line Control Register Bit Fields
 **********************************************************************/
#define UART_LCR_WLEN(n)    ((_SBF(5,((n) - 5))) & 0x60)
#define UART_LCR_WLEN5     _SBF(5,0)	// 5 bits
#define UART_LCR_WLEN6     _SBF(5,1)	// 6 bits
#define UART_LCR_WLEN7     _SBF(5,2)	// 7 bits
#define UART_LCR_WLEN8     _SBF(5,3)	// 8 bits
#define UART_LCR_FEN       _SBF(4,1)	// FIFO Enable
#define UART_LCR_STP1      _SBF(3,0)	// One Stop Bits Select
#define UART_LCR_STP2      _SBF(3,1)	// Two Stop Bits Select
#define UART_LCR_EPS       _SBF(2,1)	// Even Parity Select
#define UART_LCR_PEVEN     _SBF(2,1)	// Even Parity Select
#define UART_LCR_PODD      _SBF(2,0)	// Odd Parity Select
#define UART_LCR_PEN       _SBF(1,1)	// Parity Enable
#define UART_LCR_PNONE     _SBF(1,0)	// Parity None
#define UART_LCR_SENDBRK   _SBF(0,1)	// Assert Break

/***********************************************************************
 * UART Baud Rate Control Register Bit Field
 **********************************************************************/
#define UART_BCR(n)        ((7372800 / (16 * (n))) - 1)
// The following values assume a UART clock frequency of 7.3728 MHz
#define UART_BCR_2400      0xBF
#define UART_BCR_4800      0x5F
#define UART_BCR_9600      0x2F
#define UART_BCR_19200     0x17
#define UART_BCR_28800     0xF
#define UART_BCR_38400     0xB
#define UART_BCR_57600     0x7
#define UART_BCR_115200    0x3
#define UART_BCR_153600    0x2
#define UART_BCR_230400    0x1
#define UART_BCR_460800    0x0

/***********************************************************************
 * UART Control Register Bit Fields
 **********************************************************************/
#define UART_CONTROL_SIRBD       _BIT(7)	// SIR Blanking Disable
#define UART_CONTROL_LBE         _BIT(6)	// Loop Back Enable
#define UART_CONTROL_MXP         _BIT(5)	// Modem Polarity Select
#define UART_CONTROL_TXP         _BIT(4)	// Xmit Pin Polarity Select
#define UART_CONTROL_RXP         _BIT(3)	// Receive Pin Polarity Select
#define UART_CONTROL_SIRLP       _BIT(2)	// IrDA SIR Low Power Mode
#define UART_CONTROL_SIR_ENABLE        0	// SIR Enable
#define UART_CONTROL_SIR_DISABLE _BIT(1)	// SIR Disable
#define UART_CONTROL_SIREN       _BIT(1)	// SIR !DISABLE! bit
#define UART_CONTROL_EN          _BIT(0)	// UART Enable
#define UART_CONTROL_UART_ENABLE _BIT(0)	// UART Enable

/***********************************************************************
 * UART Status Register Bit Fields
 **********************************************************************/
#define UART_STATUS_TXFE   _BIT(7)	// Transmit FIFO Empty
#define UART_STATUS_RXFF   _BIT(6)	// Receive FIFO Full
#define UART_STATUS_TXFF   _BIT(5)	// Transmit FIFO Full
#define UART_STATUS_RXFE   _BIT(4)	// Receive FIFO Empty
#define UART_STATUS_BUSY   _BIT(3)	// Transmitter Busy
#define UART_STATUS_DCD    _BIT(2)	// Data Carrier Detect
#define UART_STATUS_DSR    _BIT(1)	// Data Set Ready
#define UART_STATUS_CTS    _BIT(0)	// Clear To Send

/***********************************************************************
 * UART Interrupt Registers Bit Fields
 * intraw, inte, intr
 **********************************************************************/
#define UART_INTR_RTI    _BIT(3)	// Receive Timeout Interrupt
#define UART_INTR_MI     _BIT(2)	// Modem Interrupt
#define UART_INTR_TI     _BIT(1)	// Transmit Interrupt
#define UART_INTR_RI     _BIT(0)	// Receive Interrupt

#endif
