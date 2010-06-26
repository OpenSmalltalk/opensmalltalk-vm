/* 
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.  */

/*
 * 30/10/2007   Michael.Kang  <blackfin.kang@gmail.com>
 */

#ifndef __PPC_BOOT_H__
#define __PPC_BOOT_H__

#define TARGET_85xx
#define TARGET_CPM2

typedef struct bd_info {
	unsigned int	bi_memstart;	/* start of DRAM memory */
	unsigned int	bi_memsize;	/* size	 of DRAM memory in bytes */
	unsigned int	bi_flashstart;	/* start of FLASH memory */
	unsigned int	bi_flashsize;	/* size	 of FLASH memory */
	unsigned int	bi_flashoffset; /* reserved area for startup monitor */
	unsigned int	bi_sramstart;	/* start of SRAM memory */
	unsigned int	bi_sramsize;	/* size	 of SRAM memory */
#if defined(TARGET_8xx) || defined(TARGET_CPM2) || defined(TARGET_85xx) ||\
	defined(TARGET_83xx)
	unsigned int	bi_immr_base;	/* base of IMMR register */
#endif
#if defined(TARGET_PPC_MPC52xx)
	unsigned int   bi_mbar_base;   /* base of internal registers */
#endif
	unsigned int	bi_bootflags;	/* boot / reboot flag (for LynxOS) */
	unsigned int	bi_ip_addr;	/* IP Address */
	unsigned char	bi_enetaddr[6];	/* Ethernet address */
	unsigned short	bi_ethspeed;	/* Ethernet speed in Mbps */
	unsigned int	bi_intfreq;	/* Internal Freq, in MHz */
	unsigned int	bi_busfreq;	/* Bus Freq, in MHz */
#if defined(TARGET_CPM2)
	unsigned int	bi_cpmfreq;	/* CPM_CLK Freq, in MHz */
	unsigned int	bi_brgfreq;	/* BRG_CLK Freq, in MHz */
	unsigned int	bi_sccfreq;	/* SCC_CLK Freq, in MHz */
	unsigned int	bi_vco;		/* VCO Out from PLL, in MHz */
#endif
#if defined(TARGET_PPC_MPC52xx)
	unsigned int   bi_ipbfreq;     /* IPB Bus Freq, in MHz */
	unsigned int   bi_pcifreq;     /* PCI Bus Freq, in MHz */
#endif
	unsigned int	bi_baudrate;	/* Console Baudrate */
#if defined(TARGET_4xx)
	unsigned char	bi_s_version[4];	/* Version of this structure */
	unsigned char	bi_r_version[32];	/* Version of the ROM (IBM) */
	unsigned int	bi_procfreq;	/* CPU (Internal) Freq, in Hz */
	unsigned int	bi_plb_busfreq;	/* PLB Bus speed, in Hz */
	unsigned int	bi_pci_busfreq;	/* PCI Bus speed, in Hz */
	unsigned char	bi_pci_enetaddr[6];	/* PCI Ethernet MAC address */
#endif
#if defined(TARGET_HYMOD)
	hymod_conf_t	bi_hymod_conf;	/* hymod configuration information */
#endif
#if defined(TARGET_EVB64260) || defined(TARGET_405EP) || defined(TARGET_44x) || \
	defined(TARGET_85xx) ||	defined(TARGET_83xx)
	/* second onboard ethernet port */
	unsigned char	bi_enet1addr[6];
#define HAVE_ENET1ADDR
#endif
#if defined(TARGET_EVB64260) || defined(TARGET_440GX) || defined(TARGET_85xx)
	/* third onboard ethernet ports */
	unsigned char	bi_enet2addr[6];
#define HAVE_ENET2ADDR
#endif
#if defined(TARGET_440GX)
	/* fourth onboard ethernet ports */
	unsigned char	bi_enet3addr[6];
#define HAVE_ENET3ADDR
#endif
#if defined(TARGET_4xx)
	unsigned int	bi_opbfreq;		/* OB clock in Hz */
	int		bi_iic_fast[2];		/* Use fast i2c mode */
#endif
#if defined(TARGET_440GX)
	int		bi_phynum[4];		/* phy mapping */
	int		bi_phymode[4];		/* phy mode */
#endif
} bd_t;

#endif /* #ifndef __PPC_BOOT_H__ */
