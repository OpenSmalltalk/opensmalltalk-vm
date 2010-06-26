/************************************************************************/
/*		S3C3410X Special Function Register Difinition		*/
/************************************************************************/
/*	Modified and programmed by Yong-Hyeon Kim			*/
/*	Description : 1999. 12. 20 first edited				*/
/************************************************************************/

#ifndef __40100_H__
#define __40100_H__

#define REGBASE         0x07ff0000
#define REGL(addr)      (REGBASE+addr)
#define REGW(addr)      (REGBASE+addr)
#define REGB(addr)      (REGBASE+addr)

/* System */
#define SYSCFG		REGL(0x1000)

#define EXTCON0		REGL(0x2030)
#define EXTCON1		REGL(0x2034)
#define EXTPOT		REGW(0x203e)
#define EXTDAT0		REGW(0x202c)
#define EXTDAT1		REGW(0x202e)

/* DMA0 Control */
#define DMASRC0		REGL(0x3000)
#define DMADST0		REGL(0x3004)
#define DMACNT0		REGL(0x3008)
#define DMACON0		REGL(0x300c)

/* DMA1 Control */
#define DMASRC1		REGL(0x4000)
#define DMADST1		REGL(0x4004)
#define DMACNT1		REGL(0x4008)
#define DMACON1		REGL(0x400c)

/* I/O Port */
#define PCON0		REGW(0xb010)
#define PDAT0		REGB(0xb000)
#define PUR0		REGB(0xb028)

#define PCON1		REGW(0xb012)
#define PDAT1		REGB(0xb001)
#define PDR1		REGB(0xb029)

#define PCON2		REGW(0xb014)
#define PDAT2		REGB(0xb002)
#define PUR2		REGB(0xb02a)

#define PCON3		REGW(0xb016)
#define PDAT3		REGB(0xb003)
#define PUR3		REGB(0xb02b)

#define PCON4		REGW(0xb018)
#define PDAT4		REGB(0xb004)
#define PDR4		REGB(0xb02c)

#define PCON5		REGL(0xb01c)
#define PDAT5		REGB(0xb005)
#define PUR5		REGB(0xb02d)

#define PCON6		REGL(0xb020)
#define PDAT6		REGB(0xb006)
#define PUR6		REGB(0xb02e)

#define PCON7		REGW(0xb024)
#define PDAT7		REGB(0xb007)
#define PUR7		REGB(0xb02f)

#define PCON8		REGB(0xb026)
#define PDAT8		REGB(0xb008)
#define PUR8		REGB(0xb03c)

#define PCON9		REGB(0xb027)
#define PDAT9		REGB(0xb009)

#define EINTPND		REGB(0xb031)
#define EINTCON		REGW(0xb032)
#define EINTMOD		REGL(0xb034)

/* Timer 0 */
#define TDAT0		REGW(0x9000)
#define TPRE0		REGB(0x9002)
#define TCON0		REGB(0x9003)
#define TCNT0		REGW(0x9006)

/* Timer 1 */
#define TDAT1		REGW(0x9010)
#define TPRE1		REGB(0x9012)
#define TCON1		REGB(0x9013)
#define TCNT1		REGW(0x9016)

/* Timer 2 */
#define TDAT2		REGW(0x9020)
#define TPRE2		REGB(0x9022)
#define TCON2		REGB(0x9023)
#define TCNT2		REGW(0x9026)

/* Timer 3 */
#define TDAT3		REGB(0x9031)
#define TPRE3		REGB(0x9032)
#define TCON3		REGB(0x9033)
#define TCNT3		REGB(0x9037)

/* Timer 4 */
#define TDAT4		REGB(0x9041)
#define TPRE4		REGB(0x9042)
#define TCON4		REGB(0x9043)
#define TCNT4		REGB(0x9047)

#define TFCON		REGB(0x904f)
#define TFSTAT		REGB(0x904e)
#define TFB4		REGB(0x904b)
#define TFHW4		REGW(0x904a)
#define TFW4		REGL(0x9048)

/* UART */
#define ULCON		REGB(0x5003)
#define UCON		REGB(0x5007)
#define USTAT		REGB(0x500b)
#define UFCON		REGB(0x500f)
#define UFSTAT		REGB(0x5012)
#define UTXH		REGB(0x5017)
#define UTXH_HW		REGW(0x5016)
#define UTXH_W		REGL(0x5014)
#define URXH		REGB(0x501b)
#define URXH_HW		REGW(0x501a)
#define URXH_W		REGL(0x5018)
#define UBRDIV		REGW(0x501e)

/* SIO 0 */
#define ITVCNT0		REGB(0x6000)
#define SBRDR0		REGB(0x6001)
#define SIODAT0		REGB(0x6002)
#define SIOCON0		REGB(0x6003)

/* SIO 1 */
#define ITVCNT1		REGB(0x7000)
#define SBRDR1		REGB(0x7001)
#define SIODAT1		REGB(0x7002)
#define SIOCON1		REGB(0x7003)

/* Interrupt Control */
#define INTMOD		REGL(0xc000)
#define INTPND		REGL(0xc004)
#define INTMSK		REGL(0xc008)
#define INTPRI0		REGL(0xc00c)
#define INTPRI1		REGL(0xc010)
#define INTPRI2		REGL(0xc014)
#define INTPRI3		REGL(0xc018)
#define INTPRI4		REGL(0xc01c)
#define INTPRI5		REGL(0xc020)
#define INTPRI6		REGL(0xc024)
#define INTPRI7		REGL(0xc028)

/* ADC */
#define ADCCON		REGW(0x8002)
#define ADCDAT		REGW(0x8006)

/* Basic Timer */
#define BTCON		REGW(0xa002)
#define BTCNT		REGB(0xa007)

/* IIC */
#define IICCON		REGB(0xe000)
#define IICSTAT		REGB(0xe001)
#define IICADD		REGB(0xe003)
#define IICDS		REGB(0xe002)
#define IICPS		REGB(0xe004)
#define IICPCNT		REGB(0xe005)

/* Power Manager */
#define SYSCON		REGB(0xd003)

/* RTC */
#define RTCCON		REGB(0xa013)
#define RTCALM		REGB(0xa012)
#define RINTCON		REGB(0xa011)
#define RINTPND		REGB(0xa010)
#define ALMSEC		REGB(0xa033)
#define ALMMIN		REGB(0xa032)
#define ALMHOUR		REGB(0xa031)
#define ALMDAY		REGB(0xa037)
#define ALMMON		REGB(0xa036)
#define ALMYEAR		REGB(0xa035)
#define BCDSEC		REGB(0xa023)
#define BCDMIN		REGB(0xa022)
#define BCDHOUR		REGB(0xa021)
#define BCDDAY		REGB(0xa027)
#define BCDDATE		REGB(0xa020)
#define BCDMON		REGB(0xa026)
#define BCDYEAR		REGB(0xa025)

#define INT_EINT0	(0)
#define INT_EINT1	(1)
#define INT_URX		(2)
#define INT_UTX		(3)
#define INT_UERR	(4)
#define INT_DMA0	(5)
#define INT_DMA1	(6)
#define INT_TOF0	(7)
#define INT_TMC0	(8)
#define INT_TOF1	(9)
#define INT_TMC1	(10)
#define INT_TOF2	(11)
#define INT_TMC2	(12)
#define INT_TOF3	(13)
#define INT_TMC3	(14)
#define INT_TOF4	(15)
#define INT_TMC4	(16)
#define INT_BT		(17)
#define INT_SIO0	(18)
#define INT_SIO1	(19)
#define INT_IIC		(20)
#define INT_RTCA	(21)
#define INT_RTCT	(22)
#define INT_TF		(23)
#define INT_EINT2	(24)
#define INT_EINT3	(25)
#define INT_EINT4	(26)
#define INT_ADC		(27)
#define INT_EINT8	(28)
#define INT_EINT9	(29)
#define INT_EINT10	(30)
#define INT_EINT11	(31)

#endif /*__41000_H___*/

