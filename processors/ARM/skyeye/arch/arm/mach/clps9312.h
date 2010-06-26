/*
 *  File:   linux/include/asm-arm/arch-ep93xx/regmap.h
 *
 *  Copyright (C) 2003 Cirrus Logic, Inc
 *  
 *  Copyright (C) 1999 ARM Limited.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef __ASM_ARCH_REGMAP_H
#define __ASM_ARCH_REGMAP_H

/*
 * Here's the rules:
 * - EP93xx register addresses in regmap.h are physical addresses.
 *
 * - IO_ADDRESS translates a physical address to a virtual one for the
 *   EP93xx's register space only.  Don't use it for actual memory.
 *
 * - The regs_*.h files in include/asm-arm/arch-ep93xx use IO_ADDRESS to
 *   translate physical register addresses to virtual addresses.
 *
 * - If you do i/o using any of the i/o macros in include/asm-arm/io.h
 *   then supply a physical address as these use __io which is the same
 *   as IO_ADDRESS
 *
 */

/*
 * Where in virtual memory the IO devices (timers, system controllers
 * and so on).  This gets used in arch/arm/mach-ep93xx/mm.c.
 *
 *  Note: IO is 1-1 mapping, but use IO_VIRT() on all IO addresses
 *  so that it can be moved in the future.
 */
#define IO_BASE_VIRT        0xE0000000	// Virtual address of IO
#define IO_BASE_PHYS        0x80000000	// Physical address of IO
#define IO_SIZE             0x0A000000	// How much?

#define PCMCIA_BASE_VIRT    0xD0000000	// Virtual address of PCMCIA
#define PCMCIA_BASE_PHYS    0xA0000000	// Physical address of PCMCIA
#define PCMCIA_SIZE         0x10000000	// How much?

/*
 * The HW_REG macro assumes that the param is a virtual address
 */
#define HW_REG(reg) ((unsigned int volatile *)reg)

/* 
 * Macro to get at IO space when running virtually.
 * (Translates a physical address to a virtual address)
 */
#define IO_ADDRESS(pa) (pa - IO_BASE_PHYS + IO_BASE_VIRT)

#define IO32(a)   (*(volatile unsigned int *)IO_ADDRESS(a))

/******************************************************************/
/*         EP93xx Memory Map and Register list                    */
/******************************************************************/
/*                                                                */
/* 0000_0000 - 0000_03ff: Internal ROM Memory  (Remap Low)        */
/* 0000_0400 - 1fff_ffff: External DRAM Memory (Remap Low)        */
/* 0000_0000 - 1fff_ffff: External DRAM Memory (Remap High)       */
/* 2000_0000 - 7fff_ffff: External SRAM Memory                    */
/* 8800_0000 - 8fff_ffff: Expansion Device Memory and Registers   */
/* 9000_0000 - 9fff_ffff: Expansion memory                        */
/* A000_0000 - Afff_ffff: PCMCIA Memory, I/O, and Attribute space */
/* B000_0000 - ffff_ffff: External SRAM memory                    */

/******************************************************************/
/*           EP93xx AHB Blocks Base Address                       */
/******************************************************************/
/*                                                                */
/* The AHB device address map is:                                 */
/* Start     End        Size Usage                                */
/* 8000_0000 8000_FFFF: 64 K DMA control registers                */
/* 8001_0000 8001_FFFF: 64 K Ethernet MAC control registers       */
/* 8002_0000 8002_FFFF: 64 K USB Host control registers           */
/* 8003_0000 8003_FFFF: 64 K Raster control registers             */
/* 8004_0000 8004_FFFF: 64 K Graphics control registers           */
/* 8005_0000 8005_FFFF: 64 K Reserved                             */
/* 8006_0000 8006_FFFF: 64 K SDRAM control registes               */
/* 8007_0000 8007_FFFF: 64 K ARM920T slave                        */
/* 8008_0000 8008_FFFF: 64 K SMC_PCMCIA control registers         */
/* 8009_0000 8009_FFFF: 64 K Boot ROM physical address            */
/* 800A_0000 800A_FFFF: 64 K IDE control registers                */
/* 800B_0000 800B_FFFF: 64 K VIC1 control registers               */
/* 800C_0000 800C_FFFF: 64 K VIC2 control registers               */
/* TAG: literal */
#define EP93XX_AHB_BASE (IO_BASE_PHYS)

/* ARM920T Address Description                             */
/*                                                         */
/* 0x8000.0000 -> 0x8000.003C M2P Channel 0 Registers (Tx) */
/* 0x8000.0040 -> 0x8000.007C M2P Channel 1 Registers (Rx) */
/* 0x8000.0080 -> 0x8000.00BC M2P Channel 2 Registers (Tx) */
/* 0x8000.00C0 -> 0x8000.00FC M2P Channel 3 Registers (Rx) */
/* 0x8000.0100 -> 0x8000.013C M2M Channel 0 Registers      */
/* 0x8000.0140 -> 0x8000.017C M2M Channel 1 Registers      */
/* 0x8000.0180 -> 0x8000.01BC Not Used                     */
/* 0x8000.01C0 -> 0x8000.01FC Not Used                     */
/* 0x8000.0200 -> 0x8000.023C M2P Channel 5 Registers (Rx) */
/* 0x8000.0240 -> 0x8000.027C M2P Channel 4 Registers (Tx) */
/* 0x8000.0280 -> 0x8000.02BC M2P Channel 7 Registers (Rx) */
/* 0x8000.02C0 -> 0x8000.02FC M2P Channel 6 Registers (Tx) */
/* 0x8000.0300 -> 0x8000.033C M2P Channel 9 Registers (Rx) */
/* 0x8000.0340 -> 0x8000.037C M2P Channel 8 Registers (Tx) */
/* 0x8000.0380 DMA Channel Arbitration register            */
/* 0x8000.03C0 DMA Global Interrupt register               */
/* 0x8000.03C4 -> 0x8000.03FC Not Used                     */

/* Internal M2P/P2M Channel Register Map                   */

/* Offset Name      Access  Bits Reset Value               */
/* 0x00   CONTROL   R/W     6    0                         */
/* 0x04   INTERRUPT R/W TC* 3    0                         */
/* 0x08   PPALLOC   R/W     4    channel dependant         */
/*                               (see reg description)     */
/* 0x0C   STATUS    RO      8    0                         */
/* 0x10   reserved                                         */
/* 0x14   REMAIN    RO      16   0                         */
/* 0X18   Reserved                                         */
/* 0X1C   Reserved                                         */
/* 0x20   MAXCNT0   R/W     16   0                         */
/* 0x24   BASE0     R/W     32   0                         */
/* 0x28   CURRENT0  RO      32   0                         */
/* 0x2C   Reserved                                         */
/* 0x30   MAXCNT1   R/W     16   0                         */
/* 0x34   BASE1     R/W     32   0                         */
/* 0X38   CURRENT1  RO      32   0                         */
/* 0X3C   Reserved                                         */
/*                                                         */
/* M2M Channel Register Map                                */
/* Offset Name         Access   Bits Reset Value           */
/*                                                         */
/* 0x00   CONTROL      R/W      22   0                     */
/* 0x04   INTERRUPT    R/W TC*  3    0                     */
/* 0x08   Reserved                                         */
/* 0x0C   STATUS       R/W TC*  14   0                     */
/* 0x10   BCR0         R/W      16   0                     */
/* 0x14   BCR1         R/W      16   0                     */
/* 0x18   SAR_BASE0    R/W      32   0                     */
/* 0x1C   SAR_BASE1    R/W      32   0                     */
/* 0x20   Reserved                                         */
/* 0x24   SAR_CURRENT0 RO       32   0                     */
/* 0x28   SAR_CURRENT1 RO       32   0                     */
/* 0x2C   DAR_BASE0    R/W      32   0                     */
/* 0x30   DAR_BASE1    R/W      32   0                     */
/* 0x34   DAR_CURRENT0 RO       32   0                     */
/* 0X38   Reserved                                         */
/* 0X3C   DAR_CURRENT1 RO       32   0                     */
/* * Write this location once to clear the bit (see        */
/* Interrupt/Status register description for which bits    */
/* this rule applies to).                                  */
/*---------------------------------------------------------*/
/* Changed to start at offset 0 from base of AHB Space     */
/*                                                     clc */

/* 8000_0000 - 8000_ffff: DMA  */
#define DMA_OFFSET              0x000000
#define DMA_BASE                (EP93XX_AHB_BASE|DMA_OFFSET)
#define DMAMP_TX_0_CONTROL      (DMA_BASE+0x0000)
#define DMAMP_TX_0_INTERRUPT    (DMA_BASE+0x0004)
#define DMAMP_TX_0_PPALLOC      (DMA_BASE+0x0008)
#define DMAMP_TX_0_STATUS       (DMA_BASE+0x000C)
#define DMAMP_TX_0_REMAIN       (DMA_BASE+0x0014)
#define DMAMP_TX_0_MAXCNT0      (DMA_BASE+0x0020)
#define DMAMP_TX_0_BASE0        (DMA_BASE+0x0024)
#define DMAMP_TX_0_CURRENT0     (DMA_BASE+0x0028)
#define DMAMP_TX_0_MAXCNT1      (DMA_BASE+0x0030)
#define DMAMP_TX_0_BASE1        (DMA_BASE+0x0034)
#define DMAMP_TX_0_CURRENT1     (DMA_BASE+0x0038)

#define DMAMP_RX_1_CONTROL      (DMA_BASE+0x0040)
#define DMAMP_RX_1_INTERRUPT    (DMA_BASE+0x0044)
#define DMAMP_RX_1_PPALLOC      (DMA_BASE+0x0048)
#define DMAMP_RX_1_STATUS       (DMA_BASE+0x004C)
#define DMAMP_RX_1_REMAIN       (DMA_BASE+0x0054)
#define DMAMP_RX_1_MAXCNT0      (DMA_BASE+0x0060)
#define DMAMP_RX_1_BASE0        (DMA_BASE+0x0064)
#define DMAMP_RX_1_CURRENT0     (DMA_BASE+0x0068)
#define DMAMP_RX_1_MAXCNT1      (DMA_BASE+0x0070)
#define DMAMP_RX_1_BASE1        (DMA_BASE+0x0074)
#define DMAMP_RX_1_CURRENT1     (DMA_BASE+0x0078)

#define DMAMP_TX_2_CONTROL      (DMA_BASE+0x0080)
#define DMAMP_TX_2_INTERRUPT    (DMA_BASE+0x0084)
#define DMAMP_TX_2_PPALLOC      (DMA_BASE+0x0088)
#define DMAMP_TX_2_STATUS       (DMA_BASE+0x008C)
#define DMAMP_TX_2_REMAIN       (DMA_BASE+0x0094)
#define DMAMP_TX_2_MAXCNT0      (DMA_BASE+0x00A0)
#define DMAMP_TX_2_BASE0        (DMA_BASE+0x00A4)
#define DMAMP_TX_2_CURRENT0     (DMA_BASE+0x00A8)
#define DMAMP_TX_2_MAXCNT1      (DMA_BASE+0x00B0)
#define DMAMP_TX_2_BASE1        (DMA_BASE+0x00B4)
#define DMAMP_TX_2_CURRENT1     (DMA_BASE+0x00B8)

#define DMAMP_RX_3_CONTROL      (DMA_BASE+0x00C0)
#define DMAMP_RX_3_INTERRUPT    (DMA_BASE+0x00C4)
#define DMAMP_RX_3_PPALLOC      (DMA_BASE+0x00C8)
#define DMAMP_RX_3_STATUS       (DMA_BASE+0x00CC)
#define DMAMP_RX_3_REMAIN       (DMA_BASE+0x00D4)
#define DMAMP_RX_3_MAXCNT0      (DMA_BASE+0x00E0)
#define DMAMP_RX_3_BASE0        (DMA_BASE+0x00E4)
#define DMAMP_RX_3_CURRENT0     (DMA_BASE+0x00E8)
#define DMAMP_RX_3_MAXCNT1      (DMA_BASE+0x00F0)
#define DMAMP_RX_3_BASE1        (DMA_BASE+0x00F4)
#define DMAMP_RX_3_CURRENT1     (DMA_BASE+0x00F8)

#define DMAMM_0_CONTROL         (DMA_BASE+0x0100)
#define DMAMM_0_INTERRUPT       (DMA_BASE+0x0104)
#define DMAMM_0_STATUS          (DMA_BASE+0x010C)
#define DMAMM_0_BCR0            (DMA_BASE+0x0110)
#define DMAMM_0_BCR1            (DMA_BASE+0x0114)
#define DMAMM_0_SAR_BASE0       (DMA_BASE+0x0118)
#define DMAMM_0_SAR_BASE1       (DMA_BASE+0x011C)
#define DMAMM_0_SAR_CURRENT0    (DMA_BASE+0x0124)
#define DMAMM_0_SAR_CURRENT1    (DMA_BASE+0x0128)
#define DMAMM_0_DAR_BASE0       (DMA_BASE+0x012C)
#define DMAMM_0_DAR_BASE1       (DMA_BASE+0x0130)
#define DMAMM_0_DAR_CURRENT0    (DMA_BASE+0x0134)
#define DMAMM_0_DAR_CURRENT1    (DMA_BASE+0x013C)

#define DMAMM_1_CONTROL         (DMA_BASE+0x0140)
#define DMAMM_1_INTERRUPT       (DMA_BASE+0x0144)
#define DMAMM_1_STATUS          (DMA_BASE+0x014C)
#define DMAMM_1_BCR0            (DMA_BASE+0x0150)
#define DMAMM_1_BCR1            (DMA_BASE+0x0154)
#define DMAMM_1_SAR_BASE0       (DMA_BASE+0x0158)
#define DMAMM_1_SAR_BASE1       (DMA_BASE+0x015C)
#define DMAMM_1_SAR_CURRENT0    (DMA_BASE+0x0164)
#define DMAMM_1_SAR_CURRENT1    (DMA_BASE+0x0168)
#define DMAMM_1_DAR_BASE0       (DMA_BASE+0x016C)
#define DMAMM_1_DAR_BASE1       (DMA_BASE+0x0170)
#define DMAMM_1_DAR_CURRENT0    (DMA_BASE+0x0174)
#define DMAMM_1_DAR_CURRENT1    (DMA_BASE+0x017C)

#define DMAMP_RX_5_CONTROL      (DMA_BASE+0x0200)
#define DMAMP_RX_5_INTERRUPT    (DMA_BASE+0x0204)
#define DMAMP_RX_5_PPALLOC      (DMA_BASE+0x0208)
#define DMAMP_RX_5_STATUS       (DMA_BASE+0x020C)
#define DMAMP_RX_5_REMAIN       (DMA_BASE+0x0214)
#define DMAMP_RX_5_MAXCNT0      (DMA_BASE+0x0220)
#define DMAMP_RX_5_BASE0        (DMA_BASE+0x0224)
#define DMAMP_RX_5_CURRENT0     (DMA_BASE+0x0228)
#define DMAMP_RX_5_MAXCNT1      (DMA_BASE+0x0230)
#define DMAMP_RX_5_BASE1        (DMA_BASE+0x0234)
#define DMAMP_RX_5_CURRENT1     (DMA_BASE+0x0238)

#define DMAMP_TX_4_CONTROL      (DMA_BASE+0x0240)
#define DMAMP_TX_4_INTERRUPT    (DMA_BASE+0x0244)
#define DMAMP_TX_4_PPALLOC      (DMA_BASE+0x0248)
#define DMAMP_TX_4_STATUS       (DMA_BASE+0x024C)
#define DMAMP_TX_4_REMAIN       (DMA_BASE+0x0254)
#define DMAMP_TX_4_MAXCNT0      (DMA_BASE+0x0260)
#define DMAMP_TX_4_BASE0        (DMA_BASE+0x0264)
#define DMAMP_TX_4_CURRENT0     (DMA_BASE+0x0268)
#define DMAMP_TX_4_MAXCNT1      (DMA_BASE+0x0270)
#define DMAMP_TX_4_BASE1        (DMA_BASE+0x0274)
#define DMAMP_TX_4_CURRENT1     (DMA_BASE+0x0278)

#define DMAMP_RX_7_CONTROL      (DMA_BASE+0x0280)
#define DMAMP_RX_7_INTERRUPT    (DMA_BASE+0x0284)
#define DMAMP_RX_7_PPALLOC      (DMA_BASE+0x0288)
#define DMAMP_RX_7_STATUS       (DMA_BASE+0x028C)
#define DMAMP_RX_7_REMAIN       (DMA_BASE+0x0294)
#define DMAMP_RX_7_MAXCNT0      (DMA_BASE+0x02A0)
#define DMAMP_RX_7_BASE0        (DMA_BASE+0x02A4)
#define DMAMP_RX_7_CURRENT0     (DMA_BASE+0x02A8)
#define DMAMP_RX_7_MAXCNT1      (DMA_BASE+0x02B0)
#define DMAMP_RX_7_BASE1        (DMA_BASE+0x02B4)
#define DMAMP_RX_7_CURRENT1     (DMA_BASE+0x02B8)

#define DMAMP_TX_6_CONTROL      (DMA_BASE+0x02C0)
#define DMAMP_TX_6_INTERRUPT    (DMA_BASE+0x02C4)
#define DMAMP_TX_6_PPALLOC      (DMA_BASE+0x02C8)
#define DMAMP_TX_6_STATUS       (DMA_BASE+0x02CC)
#define DMAMP_TX_6_REMAIN       (DMA_BASE+0x02D4)
#define DMAMP_TX_6_MAXCNT0      (DMA_BASE+0x02E0)
#define DMAMP_TX_6_BASE0        (DMA_BASE+0x02E4)
#define DMAMP_TX_6_CURRENT0     (DMA_BASE+0x02E8)
#define DMAMP_TX_6_MAXCNT1      (DMA_BASE+0x02F0)
#define DMAMP_TX_6_BASE1        (DMA_BASE+0x02F4)
#define DMAMP_TX_6_CURRENT1     (DMA_BASE+0x02F8)

#define DMAMP_RX_9_CONTROL      (DMA_BASE+0x0300)
#define DMAMP_RX_9_INTERRUPT    (DMA_BASE+0x0304)
#define DMAMP_RX_9_PPALLOC      (DMA_BASE+0x0308)
#define DMAMP_RX_9_STATUS       (DMA_BASE+0x030C)
#define DMAMP_RX_9_REMAIN       (DMA_BASE+0x0314)
#define DMAMP_RX_9_MAXCNT0      (DMA_BASE+0x0320)
#define DMAMP_RX_9_BASE0        (DMA_BASE+0x0324)
#define DMAMP_RX_9_CURRENT0     (DMA_BASE+0x0328)
#define DMAMP_RX_9_MAXCNT1      (DMA_BASE+0x0330)
#define DMAMP_RX_9_BASE1        (DMA_BASE+0x0334)
#define DMAMP_RX_9_CURRENT1     (DMA_BASE+0x0338)

#define DMAMP_TX_8_CONTROL      (DMA_BASE+0x0340)
#define DMAMP_TX_8_INTERRUPT    (DMA_BASE+0x0344)
#define DMAMP_TX_8_PPALLOC      (DMA_BASE+0x0348)
#define DMAMP_TX_8_STATUS       (DMA_BASE+0x034C)
#define DMAMP_TX_8_REMAIN       (DMA_BASE+0x0354)
#define DMAMP_TX_8_MAXCNT0      (DMA_BASE+0x0360)
#define DMAMP_TX_8_BASE0        (DMA_BASE+0x0364)
#define DMAMP_TX_8_CURRENT0     (DMA_BASE+0x0368)
#define DMAMP_TX_8_MAXCNT1      (DMA_BASE+0x0370)
#define DMAMP_TX_8_BASE1        (DMA_BASE+0x0374)
#define DMAMP_TX_8_CURRENT1     (DMA_BASE+0x0378)

#define DMA_ARBITRATION         (DMA_BASE+0x0380)
#define DMA_INTERRUPT           (DMA_BASE+0x03C0)

/* 8001_0000 - 8001_ffff: Ether MAC */
#define MAC_OFFSET              0x010000
#define MAC_BASE                (EP93XX_AHB_BASE|MAC_OFFSET)
#define MAC_RXCTL               (MAC_BASE+0x00)	/* 2-RW Rx  Control */
#define MAC_TXCTL               (MAC_BASE+0x04)	/* 1-RW Tx Control */
#define MAC_TESTCTL             (MAC_BASE+0x08)	/* 1-RW Test Control */
#define MAC_MIICMD              (MAC_BASE+0x10)	/* 2-RW MII(Media Independent Intf) Command */
#define MAC_MIIDATA             (MAC_BASE+0x14)	/* 2-RW MII Data */
#define MAC_MIISTS              (MAC_BASE+0x18)	/* 1-RO MII Status */

#define MAC_SELFCTL             (MAC_BASE+0x20)	/* 1-RW Self Control for LED interface */
#define MAC_INTEN               (MAC_BASE+0x24)	/* 4-RW Intrrpt Enable */
#define MAC_INTSTSP             (MAC_BASE+0x28)	/* 4-RW Intrrpt Status Preserve */
#define MAC_INTSTSC             (MAC_BASE+0x2C)	/* 4-RO Intrrpt Status Clear */

#define MAC_DIAGAD              (MAC_BASE+0x38)	/* 4-RW Diag Addr (debug only) */
#define MAC_DIAGDATA            (MAC_BASE+0x3C)	/* 4-RW Diag Data (debug only) */

#define MAC_GT                  (MAC_BASE+0x40)	/* 4-RW General Timer */
#define MAC_FCT                 (MAC_BASE+0x44)	/* 4-RO Flow Control Timer */
#define MAC_FCF                 (MAC_BASE+0x48)	/* 4-RW Flow Control Format */
#define MAC_AFP                 (MAC_BASE+0x4C)	/* 1-RW Addr Filter Pointer */
#define MAC_HASHTB              (MAC_BASE+0x50)	/* 8-RW Logical Addr Filter (Hash Table) */
#define MAC_INDAD               (MAC_BASE+0x50)	/* 6-RW Individual Addr, IA */
#define MAC_INDAD_UPPER         (MAC_BASE+0x54)	/* 6-RW Individual Addr, IA */

#define MAC_FER                 (MAC_BASE+0x60)	/* 4-RW Cardbus Functn Event Reg */
#define MAC_FERMASK             (MAC_BASE+0x64)	/* 4-RW Cardbus Functn Event Mask Reg */
#define MAC_FPSR                (MAC_BASE+0x68)	/* 4-RO Cardbus Functn Present Status Reg */
#define MAC_FFER                (MAC_BASE+0x6C)	/* 4-RW Cardbus Functn Force Event Reg */
#define MAC_TXCOLLCNT           (MAC_BASE+0x70)	/* 2-RW Tx Collision Count */
#define MAC_RXMISSCNT           (MAC_BASE+0x74)	/* 2-RW Rx Miss Count */
#define MAC_RXRUNTCNT           (MAC_BASE+0x78)	/* 2-RW Rx Runt Count */

#define MAC_BMCTL               (MAC_BASE+0x80)	/* 1-RW Bus Master Control */
#define MAC_BMSTS               (MAC_BASE+0x84)	/* 1-RO Bus Master Status */
#define MAC_RXBCA               (MAC_BASE+0x88)	/* 4-RO Rx buffer current address */
#define MAC_TXBCA               (MAC_BASE+0x8C)	/* 4-RO Tx buffer current address */
#define MAC_RXDBA               (MAC_BASE+0x90)	/* 4-RW Rx Descrptr Queue Base Addr */
#define MAC_RXDBL               (UINT16*)(MAC_BASE+0x94)	/* 2-RW Rx Descrptr Queue Base Length */
#define MAC_RXDCA               (MAC_BASE+0x98)	/* 4-RW Rx Descrptr Current Addr */
#define MAC_RXDEQ               (MAC_BASE+0x9C)	/* 2-RW Rx Descrptr Enqueue */
#define MAC_RXSBA               (MAC_BASE+0xA0)	/* 4-RW Rx Status Queue Base Addr */
#define MAC_RXSBL               (UINT16*)(MAC_BASE+0xA4)	/* 2-RW Rx Status Queue Base Length */

#define MAC_RXSCA               (MAC_BASE+0xA8)	/* 4-RW Rx Status Current Addr */
#define MAC_RXSEQ               (MAC_BASE+0xAC)	/* 2-RW Rx Status Enqueue */
#define MAC_TXDBA               (MAC_BASE+0xB0)	/* 4-RW Tx Descrptr Queue Base Addr */
#define MAC_TXDBL               (MAC_BASE+0xB4)	/* 2-RW Tx Descrptr Queue Base Length */
#define MAC_TXDCL               (MAC_BASE+0xB6)	/* 2-RW Tx Descrptr Queue Current Length */
#define MAC_TXDCA               (MAC_BASE+0xB8)	/* 4-RW Tx Descrptr Current Addr */
#define MAC_TXDEQ               (MAC_BASE+0xBC)	/* 2-RW Tx Descrptr Enqueue */

#define MAC_TXSBA               (MAC_BASE+0xC0)	/* 4-RW Tx status Queue Base Addr */
#define MAC_TXSBL               (MAC_BASE+0xC4)	/* 2-RW Tx Status Queue Base Length */
#define MAC_TXSCL               (MAC_BASE+0xC6)	/* 2-RW Tx Status Queue Current Length */
#define MAC_TXSCA               (MAC_BASE+0xC8)	/* 4-RW Tx Status Current Addr */
#define MAC_TXSEQ               (MAC_BASE+0xCC)	/* 4-RW Tx Status Current Addr */
#define MAC_RXBTH               (MAC_BASE+0xD0)	/* 4-RW Rx Buffer Thrshold */
#define MAC_TXBTH               (MAC_BASE+0xD4)	/* 4-RW Tx Buffer Thrshold */
#define MAC_RXSTH               (MAC_BASE+0xD8)	/* 4-RW Rx Status Thrshold */
#define MAC_TXSTH               (MAC_BASE+0xDC)	/* 4-RW Tx Status Thrshold */

#define MAC_RXDTH               (MAC_BASE+0xE0)	/* 4-RW Rx Descrptr Thrshold */
#define MAC_TXDTH               (MAC_BASE+0xE4)	/* 4-RW Tx Descrptr Thrshold */
#define MAC_MAXFL               (MAC_BASE+0xE8)	/* 4-RW Maximum Frame Length */
#define MAC_RXHLEN              (MAC_BASE+0xEC)	/* 2-RW Rx Header Length */
#define MAC_CFG_REG0            (MAC_BASE+0x100)	/* config registers 0-2 */
#define MAC_CFG_REG1            (MAC_BASE+0x104)	/*   */
#define MAC_CFG_REG2            (MAC_BASE+0x108)	/*   */

/* 8002_0000 - 8002_ffff: USH */
#define USB_OFFSET              0x020000
#define USB_BASE                (EP93XX_AHB_BASE|USB_OFFSET)
#define HCREVISION              (USB_BASE+0x00)
#define HCCONTROL               (USB_BASE+0x04)
#define HCCOMMANDSTATUS         (USB_BASE+0x08)
#define HCINTERRUPTSTATUS       (USB_BASE+0x0C)
#define HCINTERRUPTENABLE       (USB_BASE+0x10)
#define HCINTERRUPTDISABLE      (USB_BASE+0x14)
#define HCHCCA                  (USB_BASE+0x18)
#define HCPERIODCURRENTED       (USB_BASE+0x1C)
#define HCCONTROLHEADED         (USB_BASE+0x20)
#define HCCONTROLCURRENTED      (USB_BASE+0x24)
#define HCBULKHEADED            (USB_BASE+0x28)
#define HCBULKCURRENTED         (USB_BASE+0x2C)
#define HCDONEHEAD              (USB_BASE+0x30)
#define HCFMINTERVAL            (USB_BASE+0x34)
#define HCFMREMAINING           (USB_BASE+0x38)
#define HCFMNUMBER              (USB_BASE+0x3C)
#define HCPERIODICSTART         (USB_BASE+0x40)
#define HCLSTHRESHOLD           (USB_BASE+0x44)
#define HCRHDESCRIPTORA         (USB_BASE+0x48)
#define HCRHDESCRIPTORB         (USB_BASE+0x4C)
#define HCRHSTATUS              (USB_BASE+0x50)
#define HCRHPORTSTATUS0         (USB_BASE+0x54)
#define HCRHPORTSTATUS1         (USB_BASE+0x58)
#define HCRHPORTSTATUS2         (USB_BASE+0x5C)
/* some tests used these registers names which are typos of original ones */
#define HCRHPROTSTATUS0         (USB_BASE+0x54)
#define HCRHPROTSTATUS1         (USB_BASE+0x58)
#define HCRHPROTSTATUS2         (USB_BASE+0x5C)
/* additional registers for controlling the AHB-HCI interface */
#define USBCTRL                 (USB_BASE+0x80)
#define USBHCI                  (USB_BASE+0x84)
#define USBTXTEST               (USB_BASE+0x88)
#define USBRXTEST               (USB_BASE+0x8C)

/* 8003_0000 - 8003_ffff: Raster */
#define RASTER_OFFSET           0x030000
#define RASTER_BASE             (EP93XX_AHB_BASE|RASTER_OFFSET)
///#define VLINESTOTAL             (RASTER_BASE+0x00)
///#define VSYNCSTRTSTOP           (RASTER_BASE+0x04)
///#define VACTIVESTRTSTOP         (RASTER_BASE+0x08)
///#define VCLKSTRTSTOP            (RASTER_BASE+0x0C)
///#define HCLKSTOTAL              (RASTER_BASE+0x10)
///#define HSYNCSTRTSTOP           (RASTER_BASE+0x14)
///#define HACTIVESTRTSTOP         (RASTER_BASE+0x18)
///#define HCLKSTRTSTOP            (RASTER_BASE+0x1C)
///#define BRIGHTNESS              (RASTER_BASE+0x20)
///#define VIDEOATTRIBS            (RASTER_BASE+0x24)
///#define VIDSCRNPAGE             (RASTER_BASE+0x28)
///#define VIDSCRNHPG              (RASTER_BASE+0x2C)
///#define SCRNLINES               (RASTER_BASE+0x30)
///#define LINELENGTH              (RASTER_BASE+0x34)
///#define VLINESTEP               (RASTER_BASE+0x38)
///#define LINECARRY               (RASTER_BASE+0x3C)
///#define BLINKRATE               (RASTER_BASE+0x40)
///#define BLINKMASK               (RASTER_BASE+0x44)
///#define BLINKPATTRN             (RASTER_BASE+0x48)
///#define PATTRNMASK              (RASTER_BASE+0x4C)
///#define BG_OFFSET               (RASTER_BASE+0x50)
///#define PIXELMODE               (RASTER_BASE+0x54)
///#define PARLLIFOUT              (RASTER_BASE+0x58)
///#define PARLLIFIN               (RASTER_BASE+0x5C)
///#define CURSOR_ADR_START        (RASTER_BASE+0x60)
///#define CURSOR_ADR_RESET        (RASTER_BASE+0x64)
///#define CURSORSIZE              (RASTER_BASE+0x68)
///#define CURSORCOLOR1            (RASTER_BASE+0x6C)
///#define CURSORCOLOR2            (RASTER_BASE+0x70)
///#define CURSORXYLOC             (RASTER_BASE+0x74)
///#define CURSOR_DHSCAN_LH_YLOC   (RASTER_BASE+0x78)
///#define REALITI_SWLOCK          (RASTER_BASE+0x7C)
///#define GS_LUT                  (RASTER_BASE+0x80)
///#define REALITI_TCR             (RASTER_BASE+0x100)
///#define REALITI_TISRA           (RASTER_BASE+0x104)
///#define REALITI_TISRB           (RASTER_BASE+0x108)
///#define CURSOR_TISR             (RASTER_BASE+0x10C)
///#define REALITI_TOCRA           (RASTER_BASE+0x110)
///#define REALITI_TOCRB           (RASTER_BASE+0x114)
///#define FIFO_TOCRA              (RASTER_BASE+0x118)
///#define FIFO_TOCRB              (RASTER_BASE+0x11C)
///#define BLINK_TISR              (RASTER_BASE+0x120)
///#define DAC_TISRA               (RASTER_BASE+0x124)
///#define DAC_TISRB               (RASTER_BASE+0x128)
///#define SHIFT_TISR              (RASTER_BASE+0x12C)
///#define DACMUX_TOCRA            (RASTER_BASE+0x130)
///#define DACMUX_TOCRB            (RASTER_BASE+0x134)
///#define PELMUX_TOCR             (RASTER_BASE+0x138)
///#define VIDEO_TOCRA             (RASTER_BASE+0x13C)
///#define VIDEO_TOCRB             (RASTER_BASE+0x140)
///#define YCRCB_TOCR              (RASTER_BASE+0x144)
///#define CURSOR_TOCR             (RASTER_BASE+0x148)
///#define VIDEO_TOCRC             (RASTER_BASE+0x14C)
///#define SHIFT_TOCR              (RASTER_BASE+0x150)
///#define BLINK_TOCR              (RASTER_BASE+0x154)
///#define REALITI_TCER            (RASTER_BASE+0x180)
///#define SIGVAL                  (RASTER_BASE+0x200)
///#define SIGCTL                  (RASTER_BASE+0x204)
///#define VSIGSTRTSTOP            (RASTER_BASE+0x208)
///#define HSIGSTRTSTOP            (RASTER_BASE+0x20C)
///#define SIGCLR                  (RASTER_BASE+0x210)
///#define ACRATE                  (RASTER_BASE+0x214)
///#define LUTCONT                 (RASTER_BASE+0x218)
///#define VBLANKSTRTSTOP          (RASTER_BASE+0x228)
///#define HBLANKSTRTSTOP          (RASTER_BASE+0x22C)
///#define LUT                     (RASTER_BASE+0x400)
///#define CURSORBLINK1            (RASTER_BASE+0x21C)
///#define CURSORBLINK2            (RASTER_BASE+0x220)
///#define CURSORBLINK             (RASTER_BASE+0x224)
///#define EOLOFFSET               (RASTER_BASE+0x230)
///#define FIFOLEVEL               (RASTER_BASE+0x234)
///#define GS_LUT2                 (RASTER_BASE+0x280)
///#define GS_LUT3                 (RASTER_BASE+0x300)

/* 8004_0000 - 8004_ffff: Graphics */
#define GRAPHICS_OFFSET         0x040000
#define GRAPHICS_BASE           (EP93XX_AHB_BASE|GRAPHICS_OFFSET)
///#define SRCPIXELSTRT            (GRAPHICS_BASE+0x00)
///#define DESTPIXELSTRT           (GRAPHICS_BASE+0x04)
///#define BLKSRCSTRT              (GRAPHICS_BASE+0x08)
///#define BLKDSTSTRT              (GRAPHICS_BASE+0x0C)
///#define BLKSRCWIDTH             (GRAPHICS_BASE+0x10)
///#define SRCLINELENGTH           (GRAPHICS_BASE+0x14)
///#define BLKDESTWIDTH            (GRAPHICS_BASE+0x18)
///#define BLKDESTHEIGHT           (GRAPHICS_BASE+0x1C)
///#define DESTLINELENGTH          (GRAPHICS_BASE+0x20)
///#define BLOCKCTRL               (GRAPHICS_BASE+0x24)
///#define TRANSPATTRN             (GRAPHICS_BASE+0x28)
///#define BLOCKMASK               (GRAPHICS_BASE+0x2C)
///#define BACKGROUND              (GRAPHICS_BASE+0x30)
///#define LINEINC                 (GRAPHICS_BASE+0x34)
///#define LINEINIT                (GRAPHICS_BASE+0x38)
///#define LINEPATTRN              (GRAPHICS_BASE+0x3C)
///#define GOATTCR                 (GRAPHICS_BASE+0x40)
///#define GOATTISRA               (GRAPHICS_BASE+0x44)
///#define GOATTISRB               (GRAPHICS_BASE+0x48)
///#define GOATTOCRA               (GRAPHICS_BASE+0x4C)
///#define GOATTOCRB               (GRAPHICS_BASE+0x50)
///#define GOATTOCRC               (GRAPHICS_BASE+0x54) 
///#define GOATTCER                (GRAPHICS_BASE+0x80)

/* 8005_0000 - 8005_ffff: Reserved  */

/*8006_0000 - 8006_ffff: SDRAM  */
#define SDRAM_OFFSET            0x060000
#define SDRAM_BASE              (EP93XX_AHB_BASE|SDRAM_OFFSET)
//#define SDRAMRESERVED         (SDRAM_BASE+0x00) /* Reserved */
#define SDRAMGLOBALCFG          (SDRAM_BASE+0x04)
#define SDRAMREFRESHTIME        (SDRAM_BASE+0x08)	/* Refresh Timer */
#define SDRAMBOOTSTATUS         (SDRAM_BASE+0x0C)
#define SDRAMCFG0               (SDRAM_BASE+0x10)	/* Configuration Register 0 (nSDCS0) */
#define SDRAMCFG1               (SDRAM_BASE+0x14)	/* Configuration Register 1 (nSDCS1) */
#define SDRAMCFG2               (SDRAM_BASE+0x18)	/* Configuration Register 2 (nSDCS2) */
#define SDRAMCFG3               (SDRAM_BASE+0x1C)	/* Configuration Register 3 (nSDCS3) */

/* 8007_0000 - 8007_ffff: ARM920T Slave  */

/* 8008_0000 - 8008_ffff: SRAM CS */

/* SMC register map                                                            */
/* Address     Read Location                   Write Location                  */
/* 0x8000.2000 SMCBCR0(Bank config register 0) SMCBCR0(Bank config register 0) */
/* 0x8000.2004 SMCBCR1(Bank config register 1) SMCBCR1(Bank config register 1) */
/* 0x8000.2008 SMCBCR2(Bank config register 2) SMCBCR2(Bank config register 2) */
/* 0x8000.200C SMCBCR3(Bank config register 3) SMCBCR3(Bank config register 3) */
/* 0x8000.2010 Reserved, RAZ Reserved, RAZ                                     */
/* 0x8000.2014 Reserved, RAZ Reserved, RAZ                                     */
/* 0x8000.2018 SMCBCR6(Bank config register 6) SMCBCR6(Bank config register 6) */
/* 0x8000.201C SMCBCR7(Bank config register 7) SMCBCR7(Bank config register 7) */
/* 0x8000.2020 PC1Attribute Register PC1Attribute                              */
/* 0x8000.2024 PC1Common Register PC1Common                                    */
/* 0x8000.2028 PC1IO Register PC1IO                                            */
/* 0x8000.202C Reserved, RAZ Reserved, RAZ                                     */
/* 0x8000.2030 PC2Attribute Register PC2Attribute                              */
/* 0x8000.2034 PC2Common Register PC2Common                                    */
/* 0x8000.2038 PC2IO Register PC2IO                                            */
/* 0x8000.203C Reserved, RAZ Reserved, RAZ                                     */
/* 0x8000.2040 PCMCIA control register PCMCIA control register                 */

#define SRAM_OFFSET             0x080000
#define SRAM_BASE               (EP93XX_AHB_BASE|SRAM_OFFSET)
#define SMCBCR0                 (SRAM_BASE+0x00)	/* 0x8000.2000  Bank config register 0 */
#define SMCBCR1                 (SRAM_BASE+0x04)	/* 0x8000.2004  Bank config register 1 */
#define SMCBCR2                 (SRAM_BASE+0x08)	/* 0x8000.2008  Bank config register 2 */
#define SMCBCR3                 (SRAM_BASE+0x0C)	/* 0x8000.200C  Bank config register 3 */
  /* 0x8000.2010  Reserved, RAZ          */
  /* 0x8000.2014  Reserved, RAZ          */
#define SMCBCR6                 (SRAM_BASE+0x18)	/* 0x8000.2018  Bank config register 6 */
#define SMCBCR7                 (SRAM_BASE+0x1C)	/* 0x8000.201C  Bank config register 7 */
#define PC1ATTRIB               (SRAM_BASE+0x20)	/* 0x8000.2020  PC1 Attribute Register */
#define PC1COMMON               (SRAM_BASE+0x24)	/* 0x8000.2024  PC1 Common Register    */
#define PC1IO                   (SRAM_BASE+0x28)	/* 0x8000.2028  PC1 IO Register        */
  /* 0x8000.202C Reserved, RAZ           */
#define PC2ATTRIB               (SRAM_BASE+0x30)	/* 0x8000.2030 PC2 Attribute Register   */
#define PC2COMMON               (SRAM_BASE+0x34)	/* 0x8000.2034 PC2 Common Register     */
#define PC2IO                   (SRAM_BASE+0x38)	/* 0x8000.2038 PC2 IO Register         */
  /* 0x8000.203C Reserved, RAZ           */
#define PCMCIACNT               (SRAM_BASE+0x40)	/* 0x8000.2040 PCMCIA control register */

/* 8009_0000 - 8009_ffff: Boot ROM (Remap low or high) */
/*   0000 - 8009_0FFF - Boot ROM code                  */
/*   0FFF - 8009_FFFF - Reserved                       */
#define BOOT_OFFSET             0x090000
#define BOOT_BASE               (EP93XX_AHB_BASE|BOOT_OFFSET)
#define BOOT                    (BOOT_BASE+0x00)

/* 800A_0000 - 800A_ffff: IDE Interface  */
#define IDE_OFFSET              0x0a0000
#define IDE_BASE                (EP93XX_AHB_BASE|IDE_OFFSET)
///#define IDECR                   (IDE_BASE+0x00)
///#define IDECFG                  (IDE_BASE+0x04)
///#define IDEMDMAOP               (IDE_BASE+0x08)
///#define IDEUDMAOP               (IDE_BASE+0x0C)
///#define IDEDATAOUT              (IDE_BASE+0x10)
///#define IDEDATAIN               (IDE_BASE+0x14)
///#define IDEMDMADATAOUT          (IDE_BASE+0x18)
///#define IDEMDMADATAIN           (IDE_BASE+0x1C)
///#define IDEUDMADATAOUT          (IDE_BASE+0x20)
///#define IDEUDMADATAIN           (IDE_BASE+0x24)
///#define IDEUDMASTATUS           (IDE_BASE+0x28)
///#define IDEUDMADEBUG            (IDE_BASE+0x2C)
///#define IDEUDMAWFST             (IDE_BASE+0x30)
///#define IDEUDMARFST             (IDE_BASE+0x34)

/* 800B_0000 - 800B_FFFF: VIC 0 */
#define VIC0_OFFSET              0x0B0000
#define VIC0_BASE                (EP93XX_AHB_BASE|VIC0_OFFSET)
#define VIC0                     (VIC0_BASE+0x000)
#define VIC0IRQSTATUS            (VIC0_BASE+0x000)	/* R   IRQ status register               */
#define VIC0FIQSTATUS            (VIC0_BASE+0x004)	/* R   FIQ status register               */
#define VIC0RAWINTR              (VIC0_BASE+0x008)	/* R   Raw interrupt status register     */
#define VIC0INTSELECT            (VIC0_BASE+0x00C)	/* R/W Interrupt select register         */
#define VIC0INTENABLE            (VIC0_BASE+0x010)	/* R/W Interrupt enable register         */
#define VIC0INTENCLEAR           (VIC0_BASE+0x014)	/* W   Interrupt enable clear register   */
#define VIC0SOFTINT              (VIC0_BASE+0x018)	/* R/W Software interrupt register       */
#define VIC0SOFTINTCLEAR         (VIC0_BASE+0x01C)	/* R/W Software interrupt clear register */
#define VIC0PROTECTION           (VIC0_BASE+0x020)	/* R/W Protection enable register        */
#define VIC0VECTADDR             (VIC0_BASE+0x030)	/* R/W Vector address register           */
#define VIC0DEFVECTADDR          (VIC0_BASE+0x034)	/* R/W Default vector address register   */
#define VIC0VECTADDR00           (VIC0_BASE+0x100)	/* R/W Vector address 00 register        */
#define VIC0VECTADDR01           (VIC0_BASE+0x104)	/* R/W Vector address 01 register        */
#define VIC0VECTADDR02           (VIC0_BASE+0x108)	/* R/W Vector address 02 register        */
#define VIC0VECTADDR03           (VIC0_BASE+0x10C)	/* R/W Vector address 03 register        */
#define VIC0VECTADDR04           (VIC0_BASE+0x110)	/* R/W Vector address 04 register        */
#define VIC0VECTADDR05           (VIC0_BASE+0x114)	/* R/W Vector address 05 register        */
#define VIC0VECTADDR06           (VIC0_BASE+0x118)	/* R/W Vector address 06 register        */
#define VIC0VECTADDR07           (VIC0_BASE+0x11C)	/* R/W Vector address 07 register        */
#define VIC0VECTADDR08           (VIC0_BASE+0x120)	/* R/W Vector address 08 register        */
#define VIC0VECTADDR09           (VIC0_BASE+0x124)	/* R/W Vector address 09 register        */
#define VIC0VECTADDR10           (VIC0_BASE+0x128)	/* R/W Vector address 10 register        */
#define VIC0VECTADDR11           (VIC0_BASE+0x12C)	/* R/W Vector address 11 register        */
#define VIC0VECTADDR12           (VIC0_BASE+0x130)	/* R/W Vector address 12 register        */
#define VIC0VECTADDR13           (VIC0_BASE+0x134)	/* R/W Vector address 13 register        */
#define VIC0VECTADDR14           (VIC0_BASE+0x138)	/* R/W Vector address 14 register        */
#define VIC0VECTADDR15           (VIC0_BASE+0x13C)	/* R/W Vector address 15 register        */
#define VIC0VECTCNTL00           (VIC0_BASE+0x200)	/* R/W Vector control 00 register        */
#define VIC0VECTCNTL01           (VIC0_BASE+0x204)	/* R/W Vector control 01 register        */
#define VIC0VECTCNTL02           (VIC0_BASE+0x208)	/* R/W Vector control 02 register        */
#define VIC0VECTCNTL03           (VIC0_BASE+0x20C)	/* R/W Vector control 03 register        */
#define VIC0VECTCNTL04           (VIC0_BASE+0x210)	/* R/W Vector control 04 register        */
#define VIC0VECTCNTL05           (VIC0_BASE+0x214)	/* R/W Vector control 05 register        */
#define VIC0VECTCNTL06           (VIC0_BASE+0x218)	/* R/W Vector control 06 register        */
#define VIC0VECTCNTL07           (VIC0_BASE+0x21C)	/* R/W Vector control 07 register        */
#define VIC0VECTCNTL08           (VIC0_BASE+0x220)	/* R/W Vector control 08 register        */
#define VIC0VECTCNTL09           (VIC0_BASE+0x224)	/* R/W Vector control 09 register        */
#define VIC0VECTCNTL10           (VIC0_BASE+0x228)	/* R/W Vector control 10 register        */
#define VIC0VECTCNTL11           (VIC0_BASE+0x22C)	/* R/W Vector control 11 register        */
#define VIC0VECTCNTL12           (VIC0_BASE+0x230)	/* R/W Vector control 12 register        */
#define VIC0VECTCNTL13           (VIC0_BASE+0x234)	/* R/W Vector control 13 register        */
#define VIC0VECTCNTL14           (VIC0_BASE+0x238)	/* R/W Vector control 14 register        */
#define VIC0VECTCNTL15           (VIC0_BASE+0x23C)	/* R/W Vector control 15 register        */
#define VIC0ITCR                 (VIC0_BASE+0x300)	/* R/W Test control register             */
#define VIC0ITIP1                (VIC0_BASE+0x304)	/* R   Test input register (nVICIRQIN/nVICFIQIN) */
#define VIC0ITIP2                (VIC0_BASE+0x308)	/* R   Test input register (VICVECTADDRIN)      */
#define VIC0ITOP1                (VIC0_BASE+0x30C)	/* R   Test output register (nVICIRQ/nVICFIQ)   */
#define VIC0ITOP2                (VIC0_BASE+0x310)	/* R   Test output register (VICVECTADDROUT)    */
#define VIC0PERIPHID0            (VIC0_BASE+0xFE0)	/* R   Peripheral ID register bits 7:0   */
#define VIC0PERIPHID1            (VIC0_BASE+0xFE4)	/* R   Peripheral ID register bits 15:8  */
#define VIC0PERIPHID2            (VIC0_BASE+0xFE8)	/* R   Peripheral ID register bits 23:16 */
#define VIC0PERIPHID3            (VIC0_BASE+0xFEC)	/* R   Peripheral ID register bits 31:24 */

/* 800C_0000 - 800C_FFFF: VIC 0 */
#define VIC1_OFFSET              0x0C0000
#define VIC1_BASE                (EP93XX_AHB_BASE|VIC1_OFFSET)
#define VIC1                     (VIC1_BASE+0x000)
#define VIC1IRQSTATUS            (VIC1_BASE+0x000)	/* R   IRQ status register               */
#define VIC1FIQSTATUS            (VIC1_BASE+0x004)	/* R   FIQ status register               */
#define VIC1RAWINTR              (VIC1_BASE+0x008)	/* R   Raw interrupt status register     */
#define VIC1INTSELECT            (VIC1_BASE+0x00C)	/* R/W Interrupt select register         */
#define VIC1INTENABLE            (VIC1_BASE+0x010)	/* R/W Interrupt enable register         */
#define VIC1INTENCLEAR           (VIC1_BASE+0x014)	/* W   Interrupt enable clear register   */
#define VIC1SOFTINT              (VIC1_BASE+0x018)	/* R/W Software interrupt register       */
#define VIC1SOFTINTCLEAR         (VIC1_BASE+0x01C)	/* R/W Software interrupt clear register */
#define VIC1PROTECTION           (VIC1_BASE+0x020)	/* R/W Protection enable register        */
#define VIC1VECTADDR             (VIC1_BASE+0x030)	/* R/W Vector address register           */
#define VIC1DEFVECTADDR          (VIC1_BASE+0x034)	/* R/W Default vector address register   */
#define VIC1VECTADDR00           (VIC1_BASE+0x100)	/* R/W Vector address 00 register        */
#define VIC1VECTADDR01           (VIC1_BASE+0x104)	/* R/W Vector address 01 register        */
#define VIC1VECTADDR02           (VIC1_BASE+0x108)	/* R/W Vector address 02 register        */
#define VIC1VECTADDR03           (VIC1_BASE+0x10C)	/* R/W Vector address 03 register        */
#define VIC1VECTADDR04           (VIC1_BASE+0x110)	/* R/W Vector address 04 register        */
#define VIC1VECTADDR05           (VIC1_BASE+0x114)	/* R/W Vector address 05 register        */
#define VIC1VECTADDR06           (VIC1_BASE+0x118)	/* R/W Vector address 06 register        */
#define VIC1VECTADDR07           (VIC1_BASE+0x11C)	/* R/W Vector address 07 register        */
#define VIC1VECTADDR08           (VIC1_BASE+0x120)	/* R/W Vector address 08 register        */
#define VIC1VECTADDR09           (VIC1_BASE+0x124)	/* R/W Vector address 09 register        */
#define VIC1VECTADDR10           (VIC1_BASE+0x128)	/* R/W Vector address 10 register        */
#define VIC1VECTADDR11           (VIC1_BASE+0x12C)	/* R/W Vector address 11 register        */
#define VIC1VECTADDR12           (VIC1_BASE+0x130)	/* R/W Vector address 12 register        */
#define VIC1VECTADDR13           (VIC1_BASE+0x134)	/* R/W Vector address 13 register        */
#define VIC1VECTADDR14           (VIC1_BASE+0x138)	/* R/W Vector address 14 register        */
#define VIC1VECTADDR15           (VIC1_BASE+0x13C)	/* R/W Vector address 15 register        */
#define VIC1VECTCNTL00           (VIC1_BASE+0x200)	/* R/W Vector control 00 register        */
#define VIC1VECTCNTL01           (VIC1_BASE+0x204)	/* R/W Vector control 01 register        */
#define VIC1VECTCNTL02           (VIC1_BASE+0x208)	/* R/W Vector control 02 register        */
#define VIC1VECTCNTL03           (VIC1_BASE+0x20C)	/* R/W Vector control 03 register        */
#define VIC1VECTCNTL04           (VIC1_BASE+0x210)	/* R/W Vector control 04 register        */
#define VIC1VECTCNTL05           (VIC1_BASE+0x214)	/* R/W Vector control 05 register        */
#define VIC1VECTCNTL06           (VIC1_BASE+0x218)	/* R/W Vector control 06 register        */
#define VIC1VECTCNTL07           (VIC1_BASE+0x21C)	/* R/W Vector control 07 register        */
#define VIC1VECTCNTL08           (VIC1_BASE+0x220)	/* R/W Vector control 08 register        */
#define VIC1VECTCNTL09           (VIC1_BASE+0x224)	/* R/W Vector control 09 register        */
#define VIC1VECTCNTL10           (VIC1_BASE+0x228)	/* R/W Vector control 10 register        */
#define VIC1VECTCNTL11           (VIC1_BASE+0x22C)	/* R/W Vector control 11 register        */
#define VIC1VECTCNTL12           (VIC1_BASE+0x230)	/* R/W Vector control 12 register        */
#define VIC1VECTCNTL13           (VIC1_BASE+0x234)	/* R/W Vector control 13 register        */
#define VIC1VECTCNTL14           (VIC1_BASE+0x238)	/* R/W Vector control 14 register        */
#define VIC1VECTCNTL15           (VIC1_BASE+0x23C)	/* R/W Vector control 15 register        */
#define VIC1ITCR                 (VIC1_BASE+0x300)	/* R/W Test control register             */
#define VIC1ITIP1                (VIC1_BASE+0x304)	/* R   Test input register (nVICIRQIN/nVICFIQIN) */
#define VIC1ITIP2                (VIC1_BASE+0x308)	/* R   Test input register (VICVECTADDRIN)      */
#define VIC1ITOP1                (VIC1_BASE+0x30C)	/* R   Test output register (nVICIRQ/nVICFIQ)   */
#define VIC1ITOP2                (VIC1_BASE+0x310)	/* R   Test output register (VICVECTADDROUT)    */
#define VIC1PERIPHID0            (VIC1_BASE+0xFE0)	/* R   Peripheral ID register bits 7:0   */
#define VIC1PERIPHID1            (VIC1_BASE+0xFE4)	/* R   Peripheral ID register bits 15:8  */
#define VIC1PERIPHID2            (VIC1_BASE+0xFE8)	/* R   Peripheral ID register bits 23:16 */
#define VIC1PERIPHID3            (VIC1_BASE+0xFEC)	/* R   Peripheral ID register bits 31:24 */

/*800D_0000 - 807F_FFFF: Reserved AHB space  */

/******************************************************************/
/******************************************************************/
/* EP93xx APB Blocks Base Addrs                                   */
/* The APB address map is:                                        */
/* Start     End        Size Usage                                */
/* 8080_0000 8080_FFFF: 64 K Reserved                             */
/* 8081_0000 8081_FFFF: 64 K Timer control registers              */
/* 8082_0000 8082_FFFF: 64 K I2S control registers                */
/* 8083_0000 8083_FFFF: 64 K Reserved                             */
/* 8084_0000 8084_FFFF: 64 K GPIO control registers               */
/* 8085_0000 8085_FFFF: 64 K Reserved                             */
/* 8086_0000 8086_FFFF: 64 K Reserved                             */
/* 8087_0000 8087_FFFF: 64 K Reserved                             */
/* 8088_0000 8088_FFFF: 64 K AAC control registers                */
/* 8089_0000 8089_FFFF: 64 K Reserved                             */
/* 808A_0000 808A_FFFF: 64 K SPI1 control registers               */
/* 808B_0000 808B_FFFF: 64 K IrDA control registers               */
/* 808C_0000 808C_FFFF: 64 K UART1 control registers              */
/* 808D_0000 808D_FFFF: 64 K UART2 control registers              */
/* 808E_0000 808E_FFFF: 64 K UART3 control registers              */
/* 808F_0000 808F_FFFF: 64 K Key Matrix control registers         */
/* 8090_0000 8090_FFFF: 64 K Touch Screen control registers       */
/* 8091_0000 8091_FFFF: 64 K PWM control registers                */
/* 8092_0000 8092_FFFF: 64 K Real Time Clock control registers    */
/* 8093_0000 8093_1FFF: 64 K Syscon control registers             */
/* 8093_2000 8093_FFFF: 64 K Security control registers           */
/* 8094_0000 8094_FFFF: 64 K Watchdog control registers           */
/* 8095_0000 8FFF_FFFF: 128M Reserved                             */

#define EP93XX_APB_BASE (IO_BASE_PHYS | 0x00800000)

/* 8080_0000 - 8080_ffff: Reserved  */

/* 8081_0000 - 8081_ffff: Timers */
#define TIMERS_OFFSET           0x010000
#define TIMERS_BASE             (EP93XX_APB_BASE|TIMERS_OFFSET)

#define TIMER1LOAD              (TIMERS_BASE+0x00)
#define TIMER1VALUE             (TIMERS_BASE+0x04)
#define TIMER1CONTROL           (TIMERS_BASE+0x08)
#define TIMER1CLEAR             (TIMERS_BASE+0x0C)
#define TIMER1TEST              (TIMERS_BASE+0x10)

#define TIMER2LOAD              (TIMERS_BASE+0x20)
#define TIMER2VALUE             (TIMERS_BASE+0x24)
#define TIMER2CONTROL           (TIMERS_BASE+0x28)
#define TIMER2CLEAR             (TIMERS_BASE+0x2C)
#define TIMER2TEST              (TIMERS_BASE+0x30)

#define TIMER3LOAD              (TIMERS_BASE+0x80)
#define TIMER3VALUE             (TIMERS_BASE+0x84)
#define TIMER3CONTROL           (TIMERS_BASE+0x88)
#define TIMER3CLEAR             (TIMERS_BASE+0x8C)
#define TIMER3TEST              (TIMERS_BASE+0x90)

#define TTIMERBZCONT            (TIMERS_BASE+0x40)

#define TIMER4VALUELOW          (TIMERS_BASE+0x60)
#define TIMER4VALUEHIGH         (TIMERS_BASE+0x64)

/* 8082_0000 - 8082_ffff: SAI (I2S) */
#define SAI_OFFSET            0x020000
#define SAI_BASE              (EP93XX_APB_BASE|SAI_OFFSET)
#define SAI                   (SAI_BASE+0x00)
#define SAI_TX_CLK_CFG        (SAI_BASE+0x00)	/* 8082.0000 R/W Transmitter clock config register  */
#define SAI_RX_CLK_CFG        (SAI_BASE+0x04)	/* 8082.0004 R/W Receiver clock config register     */
#define SAI_CSR               (SAI_BASE+0x08)	/* 8082.0008 R/W SAI Global Status register. This   */
  /*               reflects the status of the 3 RX    */
  /*               FIFOs and the 3 TX FIFOs           */
#define SAI_GCR               (SAI_BASE+0x0C)	/* 8082.000C R/W SAI Global Control register        */
#define SAI_TX0_LEFT          (SAI_BASE+0x10)	/* 8082.0010 R/W Left  TX data reg for channel 0    */
#define SAI_TX0_RIGHT         (SAI_BASE+0x14)	/* 8082.0014 R/W Right TX data reg for channel 0    */
#define SAI_TX1_LEFT          (SAI_BASE+0x18)	/* 8082.0018 R/W Left  TX data reg for channel 1    */
#define SAI_TX1_RIGHT         (SAI_BASE+0x1C)	/* 8082.001C R/W Right TX data reg for channel 1    */
#define SAI_TX2_LEFT          (SAI_BASE+0x20)	/* 8082.0020 R/W Left  TX data reg for channel 2    */
#define SAI_TX2_RIGHT         (SAI_BASE+0x24)	/* 8082.0024 R/W Right TX data reg for channel 2    */
#define SAI_TX_LCR            (SAI_BASE+0x28)	/* 8082.0028 R/W TX Line Control data register      */
#define SAI_TX_CR             (SAI_BASE+0x2C)	/* 8082.002C R/W TX Control register                */
#define SAI_TX_WL             (SAI_BASE+0x30)	/* 8082.0030 R/W TX Word Length                     */
#define SAI_TX_EN0            (SAI_BASE+0x34)	/* 8082.0034 R/W TX0 Channel Enable                 */
#define SAI_TX_EN1            (SAI_BASE+0x38)	/* 8082.0038 R/W TX1 Channel Enable                 */
#define SAI_TX_EN2            (SAI_BASE+0x3C)	/* 8082.003C R/W TX2 Channel Enable                 */
#define SAI_RX0_LEFT          (SAI_BASE+0x40)	/* 8082.0040 R   Left  RX data reg for channel 0    */
#define SAI_RX0_RIGHT         (SAI_BASE+0x44)	/* 8082.0044 R   Right RX data reg for channel 0    */
#define SAI_RX1_LEFT          (SAI_BASE+0x48)	/* 8082.0048 R   Left  RX data reg for channel 1    */
#define SAI_RX1_RIGHT         (SAI_BASE+0x4C)	/* 8082.004c R   Right RX data reg for channel 1    */
#define SAI_RX2_LEFT          (SAI_BASE+0x50)	/* 8082.0050 R   Left  RX data reg for channel 2    */
#define SAI_RX2_RIGHT         (SAI_BASE+0x54)	/* 8082.0054 R   Right RX data reg for channel 2    */
#define SAI_RX_LCR            (SAI_BASE+0x58)	/* 8082.0058 R/W RX Line Control data register      */
#define SAI_RX_CR             (SAI_BASE+0x5C)	/* 8082.005C R/W RX Control register                */
#define SAI_RX_WL             (SAI_BASE+0x60)	/* 8082.0060 R/W RX Word Length                     */
#define SAI_RX_EN0            (SAI_BASE+0x64)	/* 8082.0064 R/W RX0 Channel Enable                 */
#define SAI_RX_EN1            (SAI_BASE+0x68)	/* 8082.0068 R/W RX1 Channel Enable                 */
#define SAI_RX_EN2            (SAI_BASE+0x6C)	/* 8082.006C R/W RX2 Channel Enable                 */

/* 8083_0000 - 8083_ffff: Security Block */
#define SECURITY_OFFSET         0x030000
#define SECURITY_BASE           (EP93XX_APB_BASE|SECURITY_OFFSET)
#define SECFLG                  (SECURITY_BASE+0x2400)
#define SECEN                   (SECURITY_BASE+0x2410)
#define UNIQID                  (SECURITY_BASE+0x2440)
#define UNIQCHK                 (SECURITY_BASE+0x2450)
#define UNIQVAL                 (SECURITY_BASE+0x2460)
#define CLINBOOT                (SECURITY_BASE+0x2480)
#define CLINVADDR               (SECURITY_BASE+0x2484)
#define CLSETSKRNL              (SECURITY_BASE+0x2488)
#define CLSKRNL                 (SECURITY_BASE+0x248C)
#define ITTMP                   (SECURITY_BASE+0x2490)
#define ETBL1                   (SECURITY_BASE+0x24A0)
#define ETCL1                   (SECURITY_BASE+0x24A4)
#define ETAPL1                  (SECURITY_BASE+0x24A8)
#define ETSPTREG1               (SECURITY_BASE+0x24B0)
#define ETSPTREG2               (SECURITY_BASE+0x24B4)
#define ETSPTREG3               (SECURITY_BASE+0x24B8)

#define SECID1                  (SECURITY_BASE+0x2500)
#define SECID2                  (SECURITY_BASE+0x2504)
#define SECCHK1                 (SECURITY_BASE+0x2520)
#define SECCHK2                 (SECURITY_BASE+0x2524)
#define SECVAL1                 (SECURITY_BASE+0x2540)
#define SECVAL2                 (SECURITY_BASE+0x2544)

#define UNIQID2                 (SECURITY_BASE+0x2700)
#define UNIQID3                 (SECURITY_BASE+0x2704)
#define UNIQID4                 (SECURITY_BASE+0x2708)
#define UNIQID5                 (SECURITY_BASE+0x270C)
#define UNIQCHK2                (SECURITY_BASE+0x2710)
#define USRFLG                  (SECURITY_BASE+0x2714)
#define UNIQVAL2                (SECURITY_BASE+0x2720)
#define UNIQVAL3                (SECURITY_BASE+0x2724)
#define UNIQVAL4                (SECURITY_BASE+0x2728)
#define TESTVAL                 (SECURITY_BASE+0x2744)
#define TESTCHK                 (SECURITY_BASE+0x2754)
#define ACHK1                   (SECURITY_BASE+0x27A0)
#define ACHK2                   (SECURITY_BASE+0x27A4)
#define PROCRESET               (SECURITY_BASE+0x27A8)
#define TESTIDR                 (SECURITY_BASE+0x27AC)
#define AVAL1                   (SECURITY_BASE+0x27B0)
#define AVAL2                   (SECURITY_BASE+0x27B4)
#define AID1                    (SECURITY_BASE+0x27C4)
#define AID2                    (SECURITY_BASE+0x27C8)
#define ADYNREMAP               (SECURITY_BASE+0x27D0)
#define ALTTMP                  (SECURITY_BASE+0x27D4)
#define PROCSIGN                (SECURITY_BASE+0x27F0)

#define ECLIDX                  (SECURITY_BASE+0x2800)
#define ECLINE0                 (SECURITY_BASE+0x2810)
#define ECLINE1                 (SECURITY_BASE+0x2814)
#define ECLINE2                 (SECURITY_BASE+0x2818)
#define ECLINE3                 (SECURITY_BASE+0x281C)
#define ECLINE4                 (SECURITY_BASE+0x2820)
#define ECLINE5                 (SECURITY_BASE+0x2824)
#define ECLINE6                 (SECURITY_BASE+0x2828)
#define ECLINE7                 (SECURITY_BASE+0x282C)
#define ETWIDX1                 (SECURITY_BASE+0x2840)
#define ETWL1                   (SECURITY_BASE+0x2844)
#define ETWIDX2                 (SECURITY_BASE+0x2848)
#define ETWL2                   (SECURITY_BASE+0x284C)

#define ETSPT10                 (SECURITY_BASE+0x4000)
#define ETSPT11                 (SECURITY_BASE+0x4004)
#define ETSPT12                 (SECURITY_BASE+0x4008)
#define ETSPT13                 (SECURITY_BASE+0x400C)

#define ETSPT2000               (SECURITY_BASE+0x6000)
#define ETSPT2020               (SECURITY_BASE+0x6020)
#define ETSPT2024               (SECURITY_BASE+0x6024)

/* 8084_0000 - 8084_ffff: GPIO */
#define GPIO_OFFSET              0x040000
#define GPIO_BASE                (EP93XX_APB_BASE|GPIO_OFFSET)
#define GPIO_PADR                HW_REG(GPIO_BASE+0x00)
#define GPIO_PBDR                HW_REG(GPIO_BASE+0x04)
#define GPIO_PCDR                HW_REG(GPIO_BASE+0x08)
#define GPIO_PDDR                HW_REG(GPIO_BASE+0x0C)
#define GPIO_PADDR               HW_REG(GPIO_BASE+0x10)
#define GPIO_PBDDR               HW_REG(GPIO_BASE+0x14)
#define GPIO_PCDDR               HW_REG(GPIO_BASE+0x18)
#define GPIO_PDDDR               HW_REG(GPIO_BASE+0x1C)
#define GPIO_PEDR                HW_REG(GPIO_BASE+0x20)
#define GPIO_PEDDR               HW_REG(GPIO_BASE+0x24)
// #define 0x8084.0028 Reserved
// #define 0x8084.002C Reserved
#define GPIO_PFDR                HW_REG(GPIO_BASE+0x30)
#define GPIO_PFDDR               HW_REG(GPIO_BASE+0x34)
#define GPIO_PGDR                HW_REG(GPIO_BASE+0x38)
#define GPIO_PGDDR               HW_REG(GPIO_BASE+0x3C)
#define GPIO_PHDR                HW_REG(GPIO_BASE+0x40)
#define GPIO_PHDDR               HW_REG(GPIO_BASE+0x44)
// #define 0x8084.0048 RAZ RAZ                                  
#define GPIO_INTTYPE1            HW_REG(GPIO_BASE+0x4C)
#define GPIO_INTTYPE2            HW_REG(GPIO_BASE+0x50)
#define GPIO_FEOI                HW_REG(GPIO_BASE+0x54)	/* WRITE ONLY - READ UNDEFINED */
#define GPIO_INTEN               HW_REG(GPIO_BASE+0x58)
#define GPIO_INTSTATUS           HW_REG(GPIO_BASE+0x5C)
#define GPIO_RAWINTSTASUS        HW_REG(GPIO_BASE+0x60)
#define GPIO_FDB                 HW_REG(GPIO_BASE+0x64)
#define GPIO_PAPINDR             HW_REG(GPIO_BASE+0x68)
#define GPIO_PBPINDR             HW_REG(GPIO_BASE+0x6C)
#define GPIO_PCPINDR             HW_REG(GPIO_BASE+0x70)
#define GPIO_PDPINDR             HW_REG(GPIO_BASE+0x74)
#define GPIO_PEPINDR             HW_REG(GPIO_BASE+0x78)
#define GPIO_PFPINDR             HW_REG(GPIO_BASE+0x7C)
#define GPIO_PGPINDR             HW_REG(GPIO_BASE+0x80)
#define GPIO_PHPINDR             HW_REG(GPIO_BASE+0x84)
#define GPIO_AINTTYPE1           HW_REG(GPIO_BASE+0x90)	/*                           */
#define GPIO_AINTTYPE2           HW_REG(GPIO_BASE+0x94)	/*                            */
#define GPIO_AEOI                HW_REG(GPIO_BASE+0x98)	/* WRITE ONLY - READ UNDEFINED */
#define GPIO_AINTEN              HW_REG(GPIO_BASE+0x9C)	/*                         */
#define GPIO_INTSTATUSA          HW_REG(GPIO_BASE+0xA0)	/* */
#define GPIO_RAWINTSTSTISA       HW_REG(GPIO_BASE+0xA4)	/* */
#define GPIO_ADB                 HW_REG(GPIO_BASE+0xA8)	/*              */
#define GPIO_BINTTYPE1           HW_REG(GPIO_BASE+0xAC)	/*                      */
#define GPIO_BINTTYPE2           HW_REG(GPIO_BASE+0xB0)	/*                         */
#define GPIO_BEOI                HW_REG(GPIO_BASE+0xB4)	/* WRITE ONLY - READ UNDEFINED */
#define GPIO_BINTEN              HW_REG(GPIO_BASE+0xB8)	/*                         */
#define GPIO_INTSTATUSB          HW_REG(GPIO_BASE+0xBC)	/* */
#define GPIO_RAWINTSTSTISB       HW_REG(GPIO_BASE+0xC0)	/* */
#define GPIO_BDB                 HW_REG(GPIO_BASE+0xC4)	/*              */
#define GPIO_EEDRIVE             HW_REG(GPIO_BASE+0xC8)	/* */
//#define Reserved               (GPIO_BASE+0xCC)
#define GPIO_TCR                 HW_REG(GPIO_BASE+0xD0)	/* Test Registers */
#define GPIO_TISRA               HW_REG(GPIO_BASE+0xD4)	/* Test Registers */
#define GPIO_TISRB               HW_REG(GPIO_BASE+0xD8)	/* Test Registers */
#define GPIO_TISRC               HW_REG(GPIO_BASE+0xDC)	/* Test Registers */
#define GPIO_TISRD               HW_REG(GPIO_BASE+0xE0)	/* Test Registers */
#define GPIO_TISRE               HW_REG(GPIO_BASE+0xE4)	/* Test Registers */
#define GPIO_TISRF               HW_REG(GPIO_BASE+0xE8)	/* Test Registers */
#define GPIO_TISRG               HW_REG(GPIO_BASE+0xEC)	/* Test Registers */
#define GPIO_TISRH               HW_REG(GPIO_BASE+0xF0)	/* Test Registers */
#define GPIO_TCER                HW_REG(GPIO_BASE+0xF4)	/* Test Registers */

/* 8085_0000 - 8085_ffff: Reserved  */

/* 8086_0000 - 8086_ffff: Reserved  */

/* 8087_0000 - 8087_ffff: Reserved  */

/* 8088_0000 - 8088_ffff: Ac97 Controller (AAC) */
#define AAC_OFFSET             0x080000
#define AAC_BASE               (EP93XX_APB_BASE|AAC_OFFSET)
#define AACDR1                 (AAC_BASE+0x00)	/* 8088.0000 R/W Data read or written from/to FIFO1  */
#define AACRXCR1               (AAC_BASE+0x04)	/* 8088.0004 R/W Control register for receive        */
#define AACTXCR1               (AAC_BASE+0x08)	/* 8088.0008 R/W Control register for transmit       */
#define AACSR1                 (AAC_BASE+0x0C)	/* 8088.000C R   Status register                     */
#define AACRISR1               (AAC_BASE+0x10)	/* 8088.0010 R   Raw interrupt status register       */
#define AACISR1                (AAC_BASE+0x14)	/* 8088.0014 R   Interrupt Status                    */
#define AACIE1                 (AAC_BASE+0x18)	/* 8088.0018 R/W Interrupt Enable                    */
  /* 8088.001C Reserved - RAZ                          */
#define AACDR2                 (AAC_BASE+0x20)	/* 8088.0020 R/W Data read or written from/to FIFO2  */
#define AACRXCR2               (AAC_BASE+0x24)	/* 8088.0024 R/W Control register for receive        */
#define AACTXCR2               (AAC_BASE+0x28)	/* 8088.0028 R/W Control register for transmit       */
#define AACSR2                 (AAC_BASE+0x2C)	/* 8088.002C R   Status register                     */
#define AACRISR2               (AAC_BASE+0x30)	/* 8088.0030 R   Raw interrupt status register       */
#define AACISR2                (AAC_BASE+0x34)	/* 8088.0034 R   Interrupt Status                    */
#define AACIE2                 (AAC_BASE+0x38)	/* 8088.0038 R/W Interrupt Enable                    */
  /* 8088.003C Reserved - RAZ                          */
#define AACDR3                 (AAC_BASE+0x40)	/* 8088.0040 R/W Data read or written from/to FIFO3. */
#define AACRXCR3               (AAC_BASE+0x44)	/* 8088.0044 R/W Control register for receive        */
#define AACTXCR3               (AAC_BASE+0x48)	/* 8088.0048 R/W Control register for transmit       */
#define AACSR3                 (AAC_BASE+0x4C)	/* 8088.004C R   Status register                     */
#define AACRISR3               (AAC_BASE+0x50)	/* 8088.0050 R   Raw interrupt status register       */
#define AACISR3                (AAC_BASE+0x54)	/* 8088.0054 R   Interrupt Status                    */
#define AACIE3                 (AAC_BASE+0x58)	/* 8088.0058 R/W Interrupt Enable                    */
  /* 8088.005C Reserved - RAZ                          */
#define AACDR4                 (AAC_BASE+0x60)	/* 8088.0060 R/W Data read or written from/to FIFO4. */
#define AACRXCR4               (AAC_BASE+0x64)	/* 8088.0064 R/W Control register for receive        */
#define AACTXCR4               (AAC_BASE+0x68)	/* 8088.0068 R/W Control register for transmit       */
#define AACSR4                 (AAC_BASE+0x6C)	/* 8088.006C R   Status register                     */
#define AACRISR4               (AAC_BASE+0x70)	/* 8088.0070 R   Raw interrupt status register       */
#define AACISR4                (AAC_BASE+0x74)	/* 8088.0074 R   Interrupt Status                    */
#define AACIE4                 (AAC_BASE+0x78)	/* 8088.0078 R/W Interrupt Enable                    */
  /* 8088.007C Reserved - RAZ                          */
#define AACS1DATA              (AAC_BASE+0x80)	/* 8088.0080 R/W Data received/transmitted on SLOT1  */
#define AACS2DATA              (AAC_BASE+0x84)	/* 8088.0084 R/W Data received/transmitted on SLOT2  */
#define AACS12DATA             (AAC_BASE+0x88)	/* 8088.0088 R/W Data received/transmitted on SLOT12 */
#define AACRGIS                (AAC_BASE+0x8C)	/* 8088.008C R/W Raw Global interrupt status register */
#define AACGIS                 (AAC_BASE+0x90)	/* 8088.0090 R   Global interrupt status register    */
#define AACIM                  (AAC_BASE+0x94)	/* 8088.0094 R/W Interrupt mask register             */
#define AACEOI                 (AAC_BASE+0x98)	/* 8088.0098 W   Interrupt clear register            */
#define AACGCR                 (AAC_BASE+0x9C)	/* 8088.009C R/W Main Control register               */
#define AACRESET               (AAC_BASE+0xA0)	/* 8088.00A0 R/W RESET control register.             */
#define AACSYNC                (AAC_BASE+0xA4)	/* 8088.00A4 R/W SYNC control register.              */
#define AACGCIS                (AAC_BASE+0xA8)	/* 8088.00A8 R  Global chan FIFO int status register */

/* 8089_0000 - 8089_ffff: Reserved */

/* 808A_0000 - 808A_ffff: SSP - (SPI) */
#define SSP_OFFSET             0x0A0000
#define SSP_BASE               (EP93XX_APB_BASE|SSP_OFFSET)
///#define SSPCR0                 HW_REG(SSP_BASE+0x00) /* 0x808A.0000 R/W Control register 0                */
///#define SSPCR1                 HW_REG(SSP_BASE+0x04) /* 0x808A.0004 R/W Control register 1.               */
///#define SSPIIR                 HW_REG(SSP_BASE+0x08) /* 0x808A.0008 R   Interrupt ID register             */
///#define SSPICR                 HW_REG(SSP_BASE+0x08) /* 0x808A.0008 W   Interrupt clear register          */
///#define SSPDR                  HW_REG(SSP_BASE+0x0C) /* 0x808A.000C R/W  Receive FIFO (Read)              */
///                                                     /*                  Transmit FIFO  (Write)           */
///#define SSPCPSR                HW_REG(SSP_BASE+0x10) /* 0x808A.0010 R/W Clock prescale register           */
///#define SSPSR                  HW_REG(SSP_BASE+0x14) /* 0x808A.0014 R   Status register                   */

/*808B_0000 - 808B_ffff: IrDA */
#define IRDA_OFFSET             0x0B0000
#define IRDA_BASE               (EP93XX_APB_BASE|IRDA_OFFSET)
//#define IRENABLE                (IRDA_BASE+0x00)
//#define IRCON                   (IRDA_BASE+0x04)
//#define IRAMV                   (IRDA_BASE+0x08)
//#define IRFLAG                  (IRDA_BASE+0x0C)
//#define IRDATA                  (IRDA_BASE+0x10)
//#define IRDATATAIL1             (IRDA_BASE+0x14)
//#define IRDATATAIL2             (IRDA_BASE+0x18)
//#define IRDATATAIL3             (IRDA_BASE+0x1c)
//#define IRRIB                   (IRDA_BASE+0x20)
//#define IRTR0                   (IRDA_BASE+0x24)
//#define IRDMACR                 (IRDA_BASE+0x28)
//#define SIRTR0                  (IRDA_BASE+0x30)
//#define MISR                    (IRDA_BASE+0x80)
//#define MIMR                    (IRDA_BASE+0x84)
//#define MIIR                    (IRDA_BASE+0x88)
//#define MITR0                   (IRDA_BASE+0x90)
//#define MITR1                   (IRDA_BASE+0x94)
//#define MITR2                   (IRDA_BASE+0x98)
//#define MITR3                   (IRDA_BASE+0x9c)
//#define MITR4                   (IRDA_BASE+0xa0)
//#define FISR                    (IRDA_BASE+0x180)
//#define FIMR                    (IRDA_BASE+0x184)
//#define FIIR                    (IRDA_BASE+0x188)
//#define FITR0                   (IRDA_BASE+0x190)
//#define FITR1                   (IRDA_BASE+0x194)
//#define FITR2                   (IRDA_BASE+0x198)
//#define FITR3                   (IRDA_BASE+0x19c)
//#define FITR4                   (IRDA_BASE+0x1a0)

/* 808C_0000 - 808C_ffff: UART1 */
#define UART1_OFFSET            0x0C0000
#define UART1_BASE              (EP93XX_APB_BASE|UART1_OFFSET)
#define UART1DR                 (UART1_BASE+0x000)
#define UART1RSR                (UART1_BASE+0x004)	/* Read */
#define UART1ECR                (UART1_BASE+0x004)	/* Write */
#define UART1CR_H               (UART1_BASE+0x008)
#define UART1CR_M               (UART1_BASE+0x00C)
#define UART1CR_L               (UART1_BASE+0x010)
#define UART1CR                 (UART1_BASE+0x014)
#define UART1FR                 (UART1_BASE+0x018)
#define UART1IIR                (UART1_BASE+0x01C)	/* Read */
#define UART1ICR                (UART1_BASE+0x01C)	/* Write */
#define UART1ILPR               (UART1_BASE+0x020)
#define UART1DMACR              (UART1_BASE+0x028)
#define UART1TMR                (UART1_BASE+0x084)
#define UART1MCR                (UART1_BASE+0x100)	/* Modem Control Reg */
#define UART1MSR                (UART1_BASE+0x104)	/* Modem Status Reg */
#define UART1TCR                (UART1_BASE+0x108)
#define UART1TISR               (UART1_BASE+0x10C)
#define UART1TOCR               (UART1_BASE+0x110)
#define HDLC1CR                 (UART1_BASE+0x20c)
#define HDLC1AMV                (UART1_BASE+0x210)
#define HDLC1AMSK               (UART1_BASE+0x214)
#define HDLC1RIB                (UART1_BASE+0x218)
#define HDLC1SR                 (UART1_BASE+0x21c)

/* 808d_0000 - 808d_ffff: UART2 */
#define UART2_OFFSET            0x0D0000
#define UART2_BASE              (EP93XX_APB_BASE|UART2_OFFSET)
#define UART2DR                 (UART2_BASE+0x00)
#define UART2RSR                (UART2_BASE+0x04)	/* Read */
#define UART2ECR                (UART2_BASE+0x04)	/* Write */
#define UART2CR_H               (UART2_BASE+0x08)
#define UART2CR_M               (UART2_BASE+0x0C)
#define UART2CR_L               (UART2_BASE+0x10)
#define UART2CR                 (UART2_BASE+0x14)
#define UART2FR                 (UART2_BASE+0x18)
#define UART2IIR                (UART2_BASE+0x1C)	/* Read */
#define UART2ICR                (UART2_BASE+0x1C)	/* Write */
#define UART2ILPR               (UART2_BASE+0x20)
#define UART2DMACR              (UART2_BASE+0x28)
#define UART2TMR                (UART2_BASE+0x84)

/* 808e_0000 - 808e_ffff: UART3 */
#define UART3_OFFSET            0x0E0000
#define UART3_BASE              (EP93XX_APB_BASE|UART3_OFFSET)
#define UART3DR                 (UART3_BASE+0x00)
#define UART3RSR                (UART3_BASE+0x04)	/* Read */
#define UART3ECR                (UART3_BASE+0x04)	/* Write */
#define UART3CR_H               (UART3_BASE+0x08)
#define UART3CR_M               (UART3_BASE+0x0C)
#define UART3CR_L               (UART3_BASE+0x10)
#define UART3CR                 (UART3_BASE+0x14)
#define UART3FR                 (UART3_BASE+0x18)
#define UART3IIR                (UART3_BASE+0x1C)	/* Read */
#define UART3ICR                (UART3_BASE+0x1C)	/* Write */
#define UART3ILPR               (UART3_BASE+0x20)
#define UART3DMACR              (UART3_BASE+0x28)
#define UART3TCR                (UART3_BASE+0x80)
#define UART3TISR               (UART3_BASE+0x88)
#define UART3TOCR               (UART3_BASE+0x8C)
#define UART3TMR                (UART3_BASE+0x84)
#define UART3MCR                (UART3_BASE+0x100)	/* Modem Control Reg */
#define UART3MSR                (UART3_BASE+0x104)	/* Modem Status Reg */

#define UART3HDLCCR             (UART3_BASE+0x20C)	/* HDLC Registers */
#define UART3HDLCAMV            (UART3_BASE+0x210)	/* HDLC Registers */
#define UART3HDLCAMSK           (UART3_BASE+0x214)	/* HDLC Registers */
#define UART3HDLCCRIB           (UART3_BASE+0x218)	/* HDLC Registers */
#define UART3HDLCSR             (UART3_BASE+0x21C)	/* HDLC Registers */

/* 808f_0000 - 808f_ffff: KEY Matrix */
#define KEY_OFFSET              0x0F0000
#define KEY_BASE                (EP93XX_APB_BASE|KEY_OFFSET)
//#define SCANINIT                (KEY_BASE+0x00)
//#define DIAG                    (KEY_BASE+0x04)
//#define KEYS_REG                (KEY_BASE+0x08)
//#define KEY_TCR                 (KEY_BASE+0x10)
//#define KEY_TISR                (KEY_BASE+0x14)
//#define KEY_TOCR                (KEY_BASE+0x18)
//#define KEY_TCER00              (KEY_BASE+0x40)
//#define KEY_TCER01              (KEY_BASE+0x44)
//#define KEY_TCER02              (KEY_BASE+0x48)
//#define KEY_TCER03              (KEY_BASE+0x4C)
//#define KEY_TCER04              (KEY_BASE+0x50)
//#define KEY_TCER05              (KEY_BASE+0x54)
//#define KEY_TCER06              (KEY_BASE+0x58)
//#define KEY_TCER07              (KEY_BASE+0x5C)
//#define KEY_TCER08              (KEY_BASE+0x60)
//#define KEY_TCER09              (KEY_BASE+0x64)
//#define KEY_TCER10              (KEY_BASE+0x68)
//#define KEY_TCER11              (KEY_BASE+0x6C)
//#define KEY_TCER12              (KEY_BASE+0x70)
//#define KEY_TCER13              (KEY_BASE+0x74)
//#define KEY_TCER14              (KEY_BASE+0x78)
//#define KEY_TCER15              (KEY_BASE+0x7C)

/* 8090_0000 - 8090_ffff: Analog Resistive Touchscreen  */
#define TOUCH_OFFSET            0x100000
#define TOUCH_BASE              (EP93XX_APB_BASE|TOUCH_OFFSET)
//#define TSSETUP                 (TOUCH_BASE+0x00) /* R/W touchscreen controller setup control register.     */
//#define TSXYMAXMIN              (TOUCH_BASE+0x04) /* R/W touchscreen controller max/min register.           */
//#define TSXYRESULT              (TOUCH_BASE+0x08) /* R   touchscreen controller result register.            */
//#define TSDISCHARGE             (TOUCH_BASE+0x0C) /* LOCKED R/W touchscreen Switch Matrix control register. */
//#define TSXSAMPLE               (TOUCH_BASE+0x10) /* LOCKED R/W touchscreen Switch Matrix control register. */
//#define TSYSAMPLE               (TOUCH_BASE+0x14) /* LOCKED R/W touchscreen Switch Matrix control register. */
//#define TSDIRECT                (TOUCH_BASE+0x18) /* LOCKED R/W touchscreen Switch Matrix control register. */
//#define TSDETECT                (TOUCH_BASE+0x1C) /* LOCKED R/W touchscreen Switch Matrix control register. */
//#define TSSWLOCK                (TOUCH_BASE+0x20) /*  NA    R/W touchscreen software lock register.         */
//#define TSSETUP2                (TOUCH_BASE+0x24) /* R/W touchscreen setup control register #2.             */

/* 8091_0000 - 8091_ffff: PWM */
#define PWM_OFFSET              0x110000
#define PWM_BASE                (EP93XX_APB_BASE|PWM_OFFSET)
#define PWM0_TC                 (PWM_BASE+0x00)	/* 80910000 R/W PWM_0 Terminal Count */
#define PWM0_DC                 (PWM_BASE+0x04)	/* 80910004 R/W PWM_0 Duty Cycle     */
#define PWM0_EN                 (PWM_BASE+0x08)	/* 80910008 R/W PWM_0 Enable         */
#define PWM0_INV                (PWM_BASE+0x0C)	/* 8091000C R/W PWM_0 Invert         */
#define PWM0_SYNC               (PWM_BASE+0x10)	/* 80910010 R/W PWM_0 Synchronous    */
#define PWM1_TC                 (PWM_BASE+0x20)	/* 80910020 R/W PWM_1 Terminal Count */
#define PWM1_DC                 (PWM_BASE+0x24)	/* 80910024 R/W PWM_1 Duty Cycle     */
#define PWM1_EN                 (PWM_BASE+0x28)	/* 80910028 R/W PWM_1 Enable         */
#define PWM1_INV                (PWM_BASE+0x2C)	/* 8091002C R/W PWM_1 Invert         */
#define PWM1_SYNC               (PWM_BASE+0x30)	/* 80910030 R/W PWM_1 Synchronous    */

/* 8092_0000 - 8092_ffff: RTC */
#define RTC_OFFSET              0x120000
#define RTC_BASE                (EP93XX_APB_BASE|RTC_OFFSET)
#define RTCDR                   (RTC_BASE+0x00)
#define RTCMR                   (RTC_BASE+0x04)
#define RTCSTAT                 (RTC_BASE+0x08)	/* Read */
#define RTCEOI                  (RTC_BASE+0x08)	/* Write */
#define RTCLR                   (RTC_BASE+0x0C)
#define RTCCR                   (RTC_BASE+0x10)
#define RTCSCOMP                (RTC_BASE+0x108)

/* 8093_0000 - 8093_ffff: CSC/Syscon  PLL, clock control, & misc. stuff */
#define SYSCON_OFFSET           0x130000
#define SYSCON_BASE             (EP93XX_APB_BASE|SYSCON_OFFSET)
#define SYSCON_PWRSR            (SYSCON_BASE+0x0000)
#define SYSCON_PWRCNT           (SYSCON_BASE+0x0004)
#define SYSCON_HALT             (SYSCON_BASE+0x0008)
#define SYSCON_STBY             (SYSCON_BASE+0x000c)
#define SYSCON_BLEOI            (SYSCON_BASE+0x0010)
#define SYSCON_MCEOI            (SYSCON_BASE+0x0014)
#define SYSCON_TEOI             (SYSCON_BASE+0x0018)
#define SYSCON_STFCLR           (SYSCON_BASE+0x001c)
#define SYSCON_CLKSET1          (SYSCON_BASE+0x0020)
#define SYSCON_CLKSET2          (SYSCON_BASE+0x0024)
#define SYSCON_RESV00           (SYSCON_BASE+0x0028)
#define SYSCON_RESV01           (SYSCON_BASE+0x002c)
#define SYSCON_RESV02           (SYSCON_BASE+0x0030)
#define SYSCON_RESV03           (SYSCON_BASE+0x0034)
#define SYSCON_RESV04           (SYSCON_BASE+0x0038)
#define SYSCON_RESV05           (SYSCON_BASE+0x003c)
#define SYSCON_SCRREG0          (SYSCON_BASE+0x0040)
#define SYSCON_SCRREG1          (SYSCON_BASE+0x0044)
#define SYSCON_CLKTEST          (SYSCON_BASE+0x0048)
#define SYSCON_USBRESET         (SYSCON_BASE+0x004c)
#define SYSCON_APBWAIT          (SYSCON_BASE+0x0050)
#define SYSCON_BMAR             (SYSCON_BASE+0x0054)
#define SYSCON_BOOTCLR          (SYSCON_BASE+0x0058)
#define SYSCON_DEVCFG           (SYSCON_BASE+0x0080)
#define SYSCON_VIDDIV           (SYSCON_BASE+0x0084)
#define SYSCON_MIRDIV           (SYSCON_BASE+0x0088)
#define SYSCON_I2SDIV           (SYSCON_BASE+0x008C)
#define SYSCON_KTDIV            (SYSCON_BASE+0x0090)
#define SYSCON_CHIPID           (SYSCON_BASE+0x0094)
#define SYSCON_TSTCR            (SYSCON_BASE+0x0098)
#define SYSCON_SYSCFG           (SYSCON_BASE+0x009C)
#define CSC_SYSCON_SWLOCK       (SYSCON_BASE+0x00C0)

#define SYSCON_DEVCFG_KEYS      0x00000002
#define SYSCON_DEVCFG_RasOnP3   0x00000010
#define SYSCON_DEVCFG_GONK      0x08000000

#define SYSCON_KTDIV_KEN        0x00008000

/* 8094_0000 - 8094_ffff: Watchdog */
#define WATCHDOG_OFFSET         0x140000
#define WATCHDOG_BASE           (EP93XX_APB_BASE|WATCHDOG_OFFSET)
#define WATCHDOG                (WATCHDOG_BASE+0x00)
#define WDSTATUS                (WATCHDOG_BASE+0x04)
#define WD_TCR                  (WATCHDOG_BASE+0x08)
#define WD_TISR                 (WATCHDOG_BASE+0x0C)
#define WDTOCR                  (WATCHDOG_BASE+0x10)

/* 8095_0000 - 87ff_ffff: Reserved APB space */

#endif /* __ASM_ARCH_HARDWARE_H */
