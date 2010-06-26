/*
	dev_net_s3c4510b.h - skyeye S3C4510B ethernet controllor simulation
	Copyright (C) 2003 - 2005 Skyeye Develop Group
	for help please send mail to <skyeye-developer@lists.gro.clinux.org>
	
	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
 
*/
/*
 * 06/04/2005 	modify to fit in dev_net_s3c4510b.c
 *			walimis <wlm@student.dlut.edu.cn>
 *
 * 09/05/2004   initial version
 *
 *              telpro2003@yahoo.com.cn, 
 *		walimis <wlm@student.dlut.edu.cn> 
 * */
#ifndef __DEV_NET_S3C4510B_H_
#define __DEV_NET_S3C4510B_H_

#define RX_FRAME_SIZE 64
#define TX_FRAME_SIZE 16

struct frame_desc_struct
{
	unsigned int frame_data_ptr;	// [31] Ownership 0=CPU, 1=BDMA
	unsigned int reserved;
	unsigned int status_and_frame_length;	// [31:16] Rx Status, [15:0] Frame Length
	unsigned int next_frame_desc;
};

/*
struct frame_buf_struct {
	unsigned char dst[ETH_ALEN];
	unsigned char src[ETH_ALEN];
	unsigned short proto;
	unsigned char data[ETH_DATA_LEN + 22];
};
*/



/* ----------------------------------------- *
 * Definitions of Samsung 4510 MAC registers *
 * ----------------------------------------- */

#define MaxRxFrameSize	(1520)

/* -------------------------------------- *
 * Buffered DMA Transmit Control Register *
 * -------------------------------------- */
#define BTxBRST		(0x0000F)	/* [4:0] */
#define BTxSTSKO	(0x00020)
#define BTxCCPIE	(0x00080)
#define BTxNLIE		(0x00100)
#define BTxNOIE		(0x00200)
#define BTxEmpty	(0x00400)
//#define BTxMSL                /* [13:11] */
#define BTxMSL000	(0x00000)
#define BTxMSL001	(0x00800)
#define BTxMSL010	(0x01000)
#define BTxMSL011	(0x01800)
#define BTxMSL100	(0x02000)
#define BTxMSL101	(0x02800)
#define BTxMSL110	(0x03000)
#define BTxMSL111	(0x03800)
#define BTxEn		(0x04000)
#define BTxRS		(0x08000)

/* ------------------------------------- *
 * Buffered DMA Receive Control Register *
 * ------------------------------------- */
#define BRxBRST		(0x0000F)	/* [4:0] */
#define BRxSTSKO	(0x00020)
#define BRxMAINC	(0x00040)
#define BRxDIE		(0x00080)
#define BRxNLIE		(0x00100)
#define BRxNOIE		(0x00200)
#define BRxMSOIE	(0x00400)
#define BRxLittle	(0x00800)
//#define BRxWA         /* [13:12] */
#define BRxWA01		(0x01000)
#define BRxWA10		(0x02000)
#define BRxWA11		(0x03000)
#define BRxEn		(0x04000)
#define BRxRS		(0x08000)
#define BRxEmpty	(0x10000)
#define BRxEarly	(0x20000)

/* -------------------- *
 * BDMA Status Register *
 * -------------------- */
#define S_BRxRDF	(0x00001)
#define S_BRxNL		(0x00002)
#define S_BRxNO		(0x00004)
#define S_BRxMSO	(0x00008)
#define S_BRxEmpty	(0x00010)
#define S_BRxSEarly	(0x00020)
#define S_BRxFRF	(0x00080)
#define S_BRxNFR	(0x00080)
#define S_BTxCCP	(0x10000)
#define S_BTxNL		(0x20000)
#define S_BTxNO		(0x40000)
#define S_BTxEmpty	(0x100000)

/* -------------------- *
 * MAC Control Register *
 * -------------------- */
#define HaltReq		(0x00001)
#define HaltImm		(0x00002)
#define Reset		(0x00004)
#define FullDup		(0x00008)
#define MACLoop		(0x00010)
#define MIIOFF		(0x00040)
#define Loop10		(0x00080)
#define MissRoll	(0x00400)
#define MDCOFF		(0x01000)
#define EnMissRoll	(0x02000)
#define Link10		(0x08000)

/* ----------------------------- *
 * MAC Transmit Control Register *
 * ----------------------------- */
#define TxEn		(0x0001)
#define TxHalt		(0x0002)
#define NoPad		(0x0004)
#define NoCRC		(0x0008)
#define FBack		(0x0010)
#define NoDef		(0x0020)
#define SdPause		(0x0040)
#define SQEn		(0x0080)
#define EnUnder		(0x0100)
#define EnDefer		(0x0200)
#define EnNCarr		(0x0400)
#define EnExColl	(0x0800)
#define EnLateColl	(0x1000)
#define EnTxPar		(0x2000)
#define EnComp		(0x4000)

/* ---------------------------- *
 * MAC Receive Control Register *
 * ---------------------------- */
#define RxEn		(0x0001)
#define RxHalt		(0x0002)
#define LongEn		(0x0004)
#define ShortEn		(0x0008)
#define StripCRC	(0x0010)
#define PassCtl		(0x0020)
#define IgnoreCRC	(0x0040)
//#define               (0x0080)
#define EnAlign		(0x0100)
#define EnCRCErr	(0x0200)
#define EnOver		(0x0400)
#define EnLongErr	(0x0800)
//#define               (0x1000)
#define EnRxPar		(0x2000)
#define EnGood		(0x4000)

/* -------------------- *
 * CAM Control Register *
 * -------------------- */
#define StationAcc	(0x0001)
#define GroupAcc	(0x0002)
#define BroadAcc	(0x0004)
#define NegCAM		(0x0008)
#define CompEn		(0x0010)

/* Tx & Rx Frame Descriptor Ownership bit[31](O) */
#define BDMA_owner	0x80000000	/* BDMA */
#define CPU_owner	0x7fffffff	/* CPU  */

/* ------------------------------- *
 * Tx Frame Descriptor Description *
 * ------------------------------- */
#define Padding		(0x00)
#define NoPadding	(0x01)
#define CRCMode		(0x00)
#define NoCRCMode	(0x02)
#define MACTxIntEn	(0x04)
#define MACTxIntDis	(0x00)
#define LittleEndian	(0x08)
#define BigEndian	(0x00)
#define FrameDataPtrInc	(0x10)
#define FrameDataPtrDec	(0x00)
#define WA00		(0x00)
#define WA01		(0x20)
#define WA10		(0x40)
#define WA11		(0x60)

/* --------- *
 * Tx Status *
 * --------- */
#define TxCollCntMask	(0x000F)
#define ExColl		(0x0010)
#define TxDefer		(0x0020)
#define Paused		(0x0040)
#define IntTx		(0x0080)
#define Under		(0x0100)
#define Defer		(0x0200)
#define NCarr		(0x0400)
#define SQErr		(0x0800)
#define LateColl	(0x1000)
#define TxPar		(0x2000)
#define Comp		(0x4000)
#define TxHalted	(0x8000)

/* --------- *
 * Rx Status *
 * --------- */
#define OvMax		(0x0004)
#define CtlRcv		(0x0020)
#define IntRx		(0x0040)
#define Rx10stat	(0x0080)
#define AlignErr	(0x0100)
#define CRCErr		(0x0200)
#define Overflow	(0x0400)
#define LongErr		(0x0800)
#define RxPar		(0x2000)
#define Good		(0x4000)
#define RxHalted	(0x8000)

/* ------------- *
 * MII Registers *
 * ------------- */

#define PHYHWADDR       0x3E0
#define MiiBusy		(1<<11)
#define PHYREGWRITE	(1<<10)

enum
{
	gMACCON = FullDup,
	gMACTXCON = EnComp | TxEn,
	gMACRXCON = RxEn,
	gBDMATXCON = BTxBRST | BTxMSL110 | BTxSTSKO | BTxEn,
	gBDMARXCON =
		BRxDIE | BRxEn | BRxLittle | BRxMAINC | BRxBRST | BRxNLIE |
		BRxNOIE | BRxSTSKO | BRxWA10,
	gCAMCON = CompEn | BroadAcc
};


/* *********************** */
/* Ethernet BDMA Registers */
/* *********************** */
#define BDMATXCON       (0x9000)
#define BDMARXCON       (0x9004)
#define BDMATXPTR       (0x9008)
#define BDMARXPTR       (0x900C)
#define BDMARXLSZ       (0x9010)
#define BDMASTAT        (0x9014)
#define CAMBASE         (0x9100)
/*                      
 * CAM          0x9100 ~ 0x917C
 * BDMATXBUF    0x9200 ~ 0x92FC
 * BDMARXBUF    0x9800 ~ 0x99FC
 */

/* ********************** */
/* Ethernet MAC Registers */
/* ********************** */
#define MACON           (0xA000)
#define CAMCON          (0xA004)
#define MACTXCON        (0xA008)
#define MACTXSTAT       (0xA00C)
#define MACRXCON        (0xA010)
#define MACRXSTAT       (0xA014)
#define STADATA         (0xA018)
#define STACON          (0xA01C)
#define CAMEN           (0xA028)
#define EMISSCNT        (0xA03C)
#define EPZCNT          (0xA040)
#define ERMPZCNT        (0xA044)
#define EXTSTAT         (0x9040)


/* walimis */
#define INT_S3C4510B_BDMATX 0
#define INT_S3C4510B_BDMARX 1
#define INT_S3C4510B_MACTX 2
#define INT_S3C4510B_MACRX 3


typedef struct net_s3c4510b_io
{
	/*Ethernet BDMA Registers */
	u32 bdmatxcon;
	u32 bdmarxcon;
	u32 bdmatxptr;
	u32 bdmarxptr;
	u32 bdmarxlsz;
	u32 bdmastat;
	u32 cam[32];

	/*Ethernet MAC Registers */
	u32 macon;
	u32 camcon;
	u32 mactxcon;
	u32 mactxstat;
	u32 macrxcon;
	u32 macrxstat;
	u32 stadata;
	u32 stacon;
	u32 camen;
	u32 emisscnt;
	u32 epzcnt;
	u32 ermpzcnt;
	u32 extstat;

	u8 mac_buf[4096];

	int need_update;
} net_s3c4510b_io_t;


static u8 s3c4510b_output (struct device_desc *dev, u8 * buf, u16 packet_len);
static void s3c4510b_input (struct device_desc *dev);

#endif //_DEV_NET_S3C4510B_H_
