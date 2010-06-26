/*
        dma.h - necessary arm definition for skyeye debugger
        Copyright (C) 2003-2007 Skyeye Develop Group
        for help please send mail to <skyeye-developer@lists.sf.linuxforum.net>

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
 * 12/16/2006   Michael.Kang  <blackfin.kang@gmail.com>
 */

#ifndef __DMA_H__
#define __DMA_H__

#define BF533_MDMA_D0 8
#define BF533_MDMA_S0 9
#define BF533_MDMA_D1 10
#define BF533_MDMA_S1 11

#define BF537_MDMA_D0 0xc
#define BF537_MDMA_S0 0xd
#define BF537_MDMA_D1 0xe
#define BF537_MDMA_S1 0xf

#define START_ADDR 0x1
#define DMA_CONFIG 0x2
#define X_COUNT 0x4
#define X_MODIFY 0x5
#define Y_COUNT 0x6
#define Y_MODIFY 0x7

#endif
