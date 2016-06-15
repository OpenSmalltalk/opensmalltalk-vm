/* 
 *
 *  This file is part of libmpeg3
 *	
 * LibMPEG3
 * Author: Adam Williams <broadcast@earthling.net>
 * Page: heroine.linuxbox.com
 * Page: http://www.smalltalkconsulting.com/html/mpeg3source.html (for Squeak)
 *
    LibMPEG3 was originally licenced under GPL. It was relicensed by
    the author under the LGPL and the Squeak license on Nov 1st, 2000
    
    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
    
    Also licensed under the Squeak license.
    http://www.squeak.org/license.html
 */
#include "mpeg3video.h"
#include "vlc.h"

/* variable length code tables                                    */

/* Table B-3, mb_type in P-pictures, codes 001..1xx */
mpeg3_VLCtab_t mpeg3_PMBtab0[8] = {
  {MPERROR,0},
  {MB_FORWARD,3},
  {MB_PATTERN,2}, {MB_PATTERN,2},
  {MB_FORWARD|MB_PATTERN,1}, {MB_FORWARD|MB_PATTERN,1},
  {MB_FORWARD|MB_PATTERN,1}, {MB_FORWARD|MB_PATTERN,1}
};

/* Table B-3, mb_type in P-pictures, codes 000001..00011x */
mpeg3_VLCtab_t mpeg3_PMBtab1[8] = {
  {MPERROR,0},
  {MB_QUANT|MB_INTRA,6},
  {MB_QUANT|MB_PATTERN,5}, {MB_QUANT|MB_PATTERN,5},
  {MB_QUANT|MB_FORWARD|MB_PATTERN,5}, {MB_QUANT|MB_FORWARD|MB_PATTERN,5},
  {MB_INTRA,5}, {MB_INTRA,5}
};

/* Table B-4, mb_type in B-pictures, codes 0010..11xx */
mpeg3_VLCtab_t mpeg3_BMBtab0[16] = {
  {MPERROR,0}, {MPERROR,0},
  {MB_FORWARD,4},
  {MB_FORWARD|MB_PATTERN,4},
  {MB_BACKWARD,3}, {MB_BACKWARD,3},
  {MB_BACKWARD|MB_PATTERN,3}, {MB_BACKWARD|MB_PATTERN,3},
  {MB_FORWARD|MB_BACKWARD,2}, {MB_FORWARD|MB_BACKWARD,2},
  {MB_FORWARD|MB_BACKWARD,2}, {MB_FORWARD|MB_BACKWARD,2},
  {MB_FORWARD|MB_BACKWARD|MB_PATTERN,2},
  {MB_FORWARD|MB_BACKWARD|MB_PATTERN,2},
  {MB_FORWARD|MB_BACKWARD|MB_PATTERN,2},
  {MB_FORWARD|MB_BACKWARD|MB_PATTERN,2}
};

/* Table B-4, mb_type in B-pictures, codes 000001..00011x */
mpeg3_VLCtab_t mpeg3_BMBtab1[8] = {
  {MPERROR,0},
  {MB_QUANT|MB_INTRA,6},
  {MB_QUANT|MB_BACKWARD|MB_PATTERN,6},
  {MB_QUANT|MB_FORWARD|MB_PATTERN,6},
  {MB_QUANT|MB_FORWARD|MB_BACKWARD|MB_PATTERN,5},
  {MB_QUANT|MB_FORWARD|MB_BACKWARD|MB_PATTERN,5},
  {MB_INTRA,5}, {MB_INTRA,5}
};

/* Table B-5, mb_type in spat. scal. I-pictures, codes 0001..1xxx */
mpeg3_VLCtab_t mpeg3_spIMBtab[16] = {
  {MPERROR,0},
  {MB_CLASS4,4},
  {MB_QUANT|MB_INTRA,4},
  {MB_INTRA,4},
  {MB_CLASS4|MB_QUANT|MB_PATTERN,2}, {MB_CLASS4|MB_QUANT|MB_PATTERN,2},
  {MB_CLASS4|MB_QUANT|MB_PATTERN,2}, {MB_CLASS4|MB_QUANT|MB_PATTERN,2},
  {MB_CLASS4|MB_PATTERN,1}, {MB_CLASS4|MB_PATTERN,1},
  {MB_CLASS4|MB_PATTERN,1}, {MB_CLASS4|MB_PATTERN,1},
  {MB_CLASS4|MB_PATTERN,1}, {MB_CLASS4|MB_PATTERN,1},
  {MB_CLASS4|MB_PATTERN,1}, {MB_CLASS4|MB_PATTERN,1}
};

/* Table B-6, mb_type in spat. scal. P-pictures, codes 0010..11xx */
mpeg3_VLCtab_t mpeg3_spPMBtab0[16] =
{
  {MPERROR,0},{MPERROR,0},
  {MB_FORWARD,4},
  {MB_WEIGHT|MB_FORWARD,4},
  {MB_QUANT|MB_FORWARD|MB_PATTERN,3}, {MB_QUANT|MB_FORWARD|MB_PATTERN,3},
  {MB_WEIGHT|MB_FORWARD|MB_PATTERN,3}, {MB_WEIGHT|MB_FORWARD|MB_PATTERN,3},
  {MB_FORWARD|MB_PATTERN,2}, {MB_FORWARD|MB_PATTERN,2},
  {MB_FORWARD|MB_PATTERN,2}, {MB_FORWARD|MB_PATTERN,2},
  {MB_WEIGHT|MB_QUANT|MB_FORWARD|MB_PATTERN,2},
  {MB_WEIGHT|MB_QUANT|MB_FORWARD|MB_PATTERN,2},
  {MB_WEIGHT|MB_QUANT|MB_FORWARD|MB_PATTERN,2},
  {MB_WEIGHT|MB_QUANT|MB_FORWARD|MB_PATTERN,2}
};

/* Table B-6, mb_type in spat. scal. P-pictures, codes 0000010..000111x */
mpeg3_VLCtab_t mpeg3_spPMBtab1[16] = {
  {MPERROR,0},{MPERROR,0},
  {MB_CLASS4|MB_QUANT|MB_PATTERN,7},
  {MB_CLASS4,7},
  {MB_PATTERN,7},
  {MB_CLASS4|MB_PATTERN,7},
  {MB_QUANT|MB_INTRA,7},
  {MB_INTRA,7},
  {MB_QUANT|MB_PATTERN,6}, {MB_QUANT|MB_PATTERN,6},
  {MB_WEIGHT|MB_QUANT|MB_PATTERN,6}, {MB_WEIGHT|MB_QUANT|MB_PATTERN,6},
  {MB_WEIGHT,6}, {MB_WEIGHT,6},
  {MB_WEIGHT|MB_PATTERN,6}, {MB_WEIGHT|MB_PATTERN,6}
};

/* Table B-7, mb_type in spat. scal. B-pictures, codes 0010..11xx */
mpeg3_VLCtab_t mpeg3_spBMBtab0[14] = {
  {MB_FORWARD,4},
  {MB_FORWARD|MB_PATTERN,4},
  {MB_BACKWARD,3}, {MB_BACKWARD,3},
  {MB_BACKWARD|MB_PATTERN,3}, {MB_BACKWARD|MB_PATTERN,3},
  {MB_FORWARD|MB_BACKWARD,2}, {MB_FORWARD|MB_BACKWARD,2},
  {MB_FORWARD|MB_BACKWARD,2}, {MB_FORWARD|MB_BACKWARD,2},
  {MB_FORWARD|MB_BACKWARD|MB_PATTERN,2},
  {MB_FORWARD|MB_BACKWARD|MB_PATTERN,2},
  {MB_FORWARD|MB_BACKWARD|MB_PATTERN,2},
  {MB_FORWARD|MB_BACKWARD|MB_PATTERN,2}
};

/* Table B-7, mb_type in spat. scal. B-pictures, codes 0000100..000111x */
mpeg3_VLCtab_t mpeg3_spBMBtab1[12] = {
  {MB_QUANT|MB_FORWARD|MB_PATTERN,7},
  {MB_QUANT|MB_BACKWARD|MB_PATTERN,7},
  {MB_INTRA,7},
  {MB_QUANT|MB_FORWARD|MB_BACKWARD|MB_PATTERN,7},
  {MB_WEIGHT|MB_FORWARD,6}, {MB_WEIGHT|MB_FORWARD,6},
  {MB_WEIGHT|MB_FORWARD|MB_PATTERN,6}, {MB_WEIGHT|MB_FORWARD|MB_PATTERN,6},
  {MB_WEIGHT|MB_BACKWARD,6}, {MB_WEIGHT|MB_BACKWARD,6},
  {MB_WEIGHT|MB_BACKWARD|MB_PATTERN,6}, {MB_WEIGHT|MB_BACKWARD|MB_PATTERN,6}
};

/* Table B-7, mb_type in spat. scal. B-pictures, codes 00000100x..000001111 */
mpeg3_VLCtab_t mpeg3_spBMBtab2[8] = {
  {MB_QUANT|MB_INTRA,8}, {MB_QUANT|MB_INTRA,8},
  {MB_WEIGHT|MB_QUANT|MB_FORWARD|MB_PATTERN,8},
  {MB_WEIGHT|MB_QUANT|MB_FORWARD|MB_PATTERN,8},
  {MB_WEIGHT|MB_QUANT|MB_BACKWARD|MB_PATTERN,9},
  {MB_CLASS4|MB_QUANT|MB_PATTERN,9},
  {MB_CLASS4,9},
  {MB_CLASS4|MB_PATTERN,9}
};

/* Table B-8, mb_type in spat. scal. B-pictures, codes 001..1xx */
mpeg3_VLCtab_t mpeg3_SNRMBtab[8] = {
  {MPERROR,0},
  {0,3},
  {MB_QUANT|MB_PATTERN,2}, {MB_QUANT|MB_PATTERN,2},
  {MB_PATTERN,1}, {MB_PATTERN,1}, {MB_PATTERN,1}, {MB_PATTERN,1}
};

/* Table B-10, motion_code, codes 0001 ... 01xx */
mpeg3_VLCtab_t mpeg3_MVtab0[8] =
{ {MPERROR,0}, {3,3}, {2,2}, {2,2}, {1,1}, {1,1}, {1,1}, {1,1}
};

/* Table B-10, motion_code, codes 0000011 ... 000011x */
mpeg3_VLCtab_t mpeg3_MVtab1[8] =
{ {MPERROR,0}, {MPERROR,0}, {MPERROR,0}, {7,6}, {6,6}, {5,6}, {4,5}, {4,5}
};

/* Table B-10, motion_code, codes 0000001100 ... 000001011x */
mpeg3_VLCtab_t mpeg3_MVtab2[12] =
{ {16,9}, {15,9}, {14,9}, {13,9},
  {12,9}, {11,9}, {10,8}, {10,8},
  {9,8},  {9,8},  {8,8},  {8,8}
};

/* Table B-9, coded_block_pattern, codes 01000 ... 111xx */
mpeg3_VLCtab_t mpeg3_CBPtab0[32] =
{ {MPERROR,0}, {MPERROR,0}, {MPERROR,0}, {MPERROR,0},
  {MPERROR,0}, {MPERROR,0}, {MPERROR,0}, {MPERROR,0},
  {62,5}, {2,5},  {61,5}, {1,5},  {56,5}, {52,5}, {44,5}, {28,5},
  {40,5}, {20,5}, {48,5}, {12,5}, {32,4}, {32,4}, {16,4}, {16,4},
  {8,4},  {8,4},  {4,4},  {4,4},  {60,3}, {60,3}, {60,3}, {60,3}
};

/* Table B-9, coded_block_pattern, codes 00000100 ... 001111xx */
mpeg3_VLCtab_t mpeg3_CBPtab1[64] =
{ {MPERROR,0}, {MPERROR,0}, {MPERROR,0}, {MPERROR,0},
  {58,8}, {54,8}, {46,8}, {30,8},
  {57,8}, {53,8}, {45,8}, {29,8}, {38,8}, {26,8}, {37,8}, {25,8},
  {43,8}, {23,8}, {51,8}, {15,8}, {42,8}, {22,8}, {50,8}, {14,8},
  {41,8}, {21,8}, {49,8}, {13,8}, {35,8}, {19,8}, {11,8}, {7,8},
  {34,7}, {34,7}, {18,7}, {18,7}, {10,7}, {10,7}, {6,7},  {6,7},
  {33,7}, {33,7}, {17,7}, {17,7}, {9,7},  {9,7},  {5,7},  {5,7},
  {63,6}, {63,6}, {63,6}, {63,6}, {3,6},  {3,6},  {3,6},  {3,6},
  {36,6}, {36,6}, {36,6}, {36,6}, {24,6}, {24,6}, {24,6}, {24,6}
};

/* Table B-9, coded_block_pattern, codes 000000001 ... 000000111 */
mpeg3_VLCtab_t mpeg3_CBPtab2[8] =
{ {MPERROR,0}, {0,9}, {39,9}, {27,9}, {59,9}, {55,9}, {47,9}, {31,9}
};

/* Table B-1, macroblock_address_increment, codes 00010 ... 011xx */
mpeg3_VLCtab_t mpeg3_MBAtab1[16] =
{ {MPERROR,0}, {MPERROR,0}, {7,5}, {6,5}, {5,4}, {5,4}, {4,4}, {4,4},
  {3,3}, {3,3}, {3,3}, {3,3}, {2,3}, {2,3}, {2,3}, {2,3}
};

/* Table B-1, macroblock_address_increment, codes 00000011000 ... 0000111xxxx */
mpeg3_VLCtab_t mpeg3_MBAtab2[104] =
{
  {33,11}, {32,11}, {31,11}, {30,11}, {29,11}, {28,11}, {27,11}, {26,11},
  {25,11}, {24,11}, {23,11}, {22,11}, {21,10}, {21,10}, {20,10}, {20,10},
  {19,10}, {19,10}, {18,10}, {18,10}, {17,10}, {17,10}, {16,10}, {16,10},
  {15,8},  {15,8},  {15,8},  {15,8},  {15,8},  {15,8},  {15,8},  {15,8},
  {14,8},  {14,8},  {14,8},  {14,8},  {14,8},  {14,8},  {14,8},  {14,8},
  {13,8},  {13,8},  {13,8},  {13,8},  {13,8},  {13,8},  {13,8},  {13,8},
  {12,8},  {12,8},  {12,8},  {12,8},  {12,8},  {12,8},  {12,8},  {12,8},
  {11,8},  {11,8},  {11,8},  {11,8},  {11,8},  {11,8},  {11,8},  {11,8},
  {10,8},  {10,8},  {10,8},  {10,8},  {10,8},  {10,8},  {10,8},  {10,8},
  {9,7},   {9,7},   {9,7},   {9,7},   {9,7},   {9,7},   {9,7},   {9,7},
  {9,7},   {9,7},   {9,7},   {9,7},   {9,7},   {9,7},   {9,7},   {9,7},
  {8,7},   {8,7},   {8,7},   {8,7},   {8,7},   {8,7},   {8,7},   {8,7},
  {8,7},   {8,7},   {8,7},   {8,7},   {8,7},   {8,7},   {8,7},   {8,7}
};

/* Table B-12, dct_dc_size_luminance, codes 00xxx ... 11110 */
mpeg3_VLCtab_t mpeg3_DClumtab0[32] =
{ {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2},
  {2, 2}, {2, 2}, {2, 2}, {2, 2}, {2, 2}, {2, 2}, {2, 2}, {2, 2},
  {0, 3}, {0, 3}, {0, 3}, {0, 3}, {3, 3}, {3, 3}, {3, 3}, {3, 3},
  {4, 3}, {4, 3}, {4, 3}, {4, 3}, {5, 4}, {5, 4}, {6, 5}, {MPERROR, 0}
};

/* Table B-12, dct_dc_size_luminance, codes 111110xxx ... 111111111 */
mpeg3_VLCtab_t mpeg3_DClumtab1[16] =
{ {7, 6}, {7, 6}, {7, 6}, {7, 6}, {7, 6}, {7, 6}, {7, 6}, {7, 6},
  {8, 7}, {8, 7}, {8, 7}, {8, 7}, {9, 8}, {9, 8}, {10,9}, {11,9}
};

/* Table B-13, dct_dc_size_chrominance, codes 00xxx ... 11110 */
mpeg3_VLCtab_t mpeg3_DCchromtab0[32] =
{ {0, 2}, {0, 2}, {0, 2}, {0, 2}, {0, 2}, {0, 2}, {0, 2}, {0, 2},
  {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2}, {1, 2},
  {2, 2}, {2, 2}, {2, 2}, {2, 2}, {2, 2}, {2, 2}, {2, 2}, {2, 2},
  {3, 3}, {3, 3}, {3, 3}, {3, 3}, {4, 4}, {4, 4}, {5, 5}, {MPERROR, 0}
};

/* Table B-13, dct_dc_size_chrominance, codes 111110xxxx ... 1111111111 */
mpeg3_VLCtab_t mpeg3_DCchromtab1[32] =
{ {6, 6}, {6, 6}, {6, 6}, {6, 6}, {6, 6}, {6, 6}, {6, 6}, {6, 6},
  {6, 6}, {6, 6}, {6, 6}, {6, 6}, {6, 6}, {6, 6}, {6, 6}, {6, 6},
  {7, 7}, {7, 7}, {7, 7}, {7, 7}, {7, 7}, {7, 7}, {7, 7}, {7, 7},
  {8, 8}, {8, 8}, {8, 8}, {8, 8}, {9, 9}, {9, 9}, {10,10}, {11,10}
};

/* Table B-14, DCT coefficients table zero,
 * codes 0100 ... 1xxx (used for first (DC) coefficient)
 */
mpeg3_DCTtab_t mpeg3_DCTtabfirst[12] =
{
  {0,2,4}, {2,1,4}, {1,1,3}, {1,1,3},
  {0,1,1}, {0,1,1}, {0,1,1}, {0,1,1},
  {0,1,1}, {0,1,1}, {0,1,1}, {0,1,1}
};

/* Table B-14, DCT coefficients table zero,
 * codes 0100 ... 1xxx (used for all other coefficients)
 */
mpeg3_DCTtab_t mpeg3_DCTtabnext[12] =
{
  {0,2,4},  {2,1,4},  {1,1,3},  {1,1,3},
  {64,0,2}, {64,0,2}, {64,0,2}, {64,0,2}, /* EOB */
  {0,1,2},  {0,1,2},  {0,1,2},  {0,1,2}
};

/* Table B-14, DCT coefficients table zero,
 * codes 000001xx ... 00111xxx
 */
mpeg3_DCTtab_t mpeg3_DCTtab0[60] =
{
  {65,0,6}, {65,0,6}, {65,0,6}, {65,0,6}, /* Escape */
  {2,2,7}, {2,2,7}, {9,1,7}, {9,1,7},
  {0,4,7}, {0,4,7}, {8,1,7}, {8,1,7},
  {7,1,6}, {7,1,6}, {7,1,6}, {7,1,6},
  {6,1,6}, {6,1,6}, {6,1,6}, {6,1,6},
  {1,2,6}, {1,2,6}, {1,2,6}, {1,2,6},
  {5,1,6}, {5,1,6}, {5,1,6}, {5,1,6},
  {13,1,8}, {0,6,8}, {12,1,8}, {11,1,8},
  {3,2,8}, {1,3,8}, {0,5,8}, {10,1,8},
  {0,3,5}, {0,3,5}, {0,3,5}, {0,3,5},
  {0,3,5}, {0,3,5}, {0,3,5}, {0,3,5},
  {4,1,5}, {4,1,5}, {4,1,5}, {4,1,5},
  {4,1,5}, {4,1,5}, {4,1,5}, {4,1,5},
  {3,1,5}, {3,1,5}, {3,1,5}, {3,1,5},
  {3,1,5}, {3,1,5}, {3,1,5}, {3,1,5}
};

/* Table B-15, DCT coefficients table one,
 * codes 000001xx ... 11111111
*/
mpeg3_DCTtab_t mpeg3_DCTtab0a[252] =
{
  {65,0,6}, {65,0,6}, {65,0,6}, {65,0,6}, /* Escape */
  {7,1,7}, {7,1,7}, {8,1,7}, {8,1,7},
  {6,1,7}, {6,1,7}, {2,2,7}, {2,2,7},
  {0,7,6}, {0,7,6}, {0,7,6}, {0,7,6},
  {0,6,6}, {0,6,6}, {0,6,6}, {0,6,6},
  {4,1,6}, {4,1,6}, {4,1,6}, {4,1,6},
  {5,1,6}, {5,1,6}, {5,1,6}, {5,1,6},
  {1,5,8}, {11,1,8}, {0,11,8}, {0,10,8},
  {13,1,8}, {12,1,8}, {3,2,8}, {1,4,8},
  {2,1,5}, {2,1,5}, {2,1,5}, {2,1,5},
  {2,1,5}, {2,1,5}, {2,1,5}, {2,1,5},
  {1,2,5}, {1,2,5}, {1,2,5}, {1,2,5},
  {1,2,5}, {1,2,5}, {1,2,5}, {1,2,5},
  {3,1,5}, {3,1,5}, {3,1,5}, {3,1,5},
  {3,1,5}, {3,1,5}, {3,1,5}, {3,1,5},
  {1,1,3}, {1,1,3}, {1,1,3}, {1,1,3},
  {1,1,3}, {1,1,3}, {1,1,3}, {1,1,3},
  {1,1,3}, {1,1,3}, {1,1,3}, {1,1,3},
  {1,1,3}, {1,1,3}, {1,1,3}, {1,1,3},
  {1,1,3}, {1,1,3}, {1,1,3}, {1,1,3},
  {1,1,3}, {1,1,3}, {1,1,3}, {1,1,3},
  {1,1,3}, {1,1,3}, {1,1,3}, {1,1,3},
  {1,1,3}, {1,1,3}, {1,1,3}, {1,1,3},
  {64,0,4}, {64,0,4}, {64,0,4}, {64,0,4}, /* EOB */
  {64,0,4}, {64,0,4}, {64,0,4}, {64,0,4},
  {64,0,4}, {64,0,4}, {64,0,4}, {64,0,4},
  {64,0,4}, {64,0,4}, {64,0,4}, {64,0,4},
  {0,3,4}, {0,3,4}, {0,3,4}, {0,3,4},
  {0,3,4}, {0,3,4}, {0,3,4}, {0,3,4},
  {0,3,4}, {0,3,4}, {0,3,4}, {0,3,4},
  {0,3,4}, {0,3,4}, {0,3,4}, {0,3,4},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,1,2}, {0,1,2}, {0,1,2}, {0,1,2},
  {0,2,3}, {0,2,3}, {0,2,3}, {0,2,3},
  {0,2,3}, {0,2,3}, {0,2,3}, {0,2,3},
  {0,2,3}, {0,2,3}, {0,2,3}, {0,2,3},
  {0,2,3}, {0,2,3}, {0,2,3}, {0,2,3},
  {0,2,3}, {0,2,3}, {0,2,3}, {0,2,3},
  {0,2,3}, {0,2,3}, {0,2,3}, {0,2,3},
  {0,2,3}, {0,2,3}, {0,2,3}, {0,2,3},
  {0,2,3}, {0,2,3}, {0,2,3}, {0,2,3},
  {0,4,5}, {0,4,5}, {0,4,5}, {0,4,5},
  {0,4,5}, {0,4,5}, {0,4,5}, {0,4,5},
  {0,5,5}, {0,5,5}, {0,5,5}, {0,5,5},
  {0,5,5}, {0,5,5}, {0,5,5}, {0,5,5},
  {9,1,7}, {9,1,7}, {1,3,7}, {1,3,7},
  {10,1,7}, {10,1,7}, {0,8,7}, {0,8,7},
  {0,9,7}, {0,9,7}, {0,12,8}, {0,13,8},
  {2,3,8}, {4,2,8}, {0,14,8}, {0,15,8}
};

/* Table B-14, DCT coefficients table zero,
 * codes 0000001000 ... 0000001111
 */
mpeg3_DCTtab_t mpeg3_DCTtab1[8] =
{
  {16,1,10}, {5,2,10}, {0,7,10}, {2,3,10},
  {1,4,10}, {15,1,10}, {14,1,10}, {4,2,10}
};

/* Table B-15, DCT coefficients table one,
 * codes 000000100x ... 000000111x
 */
mpeg3_DCTtab_t mpeg3_DCTtab1a[8] =
{
  {5,2,9}, {5,2,9}, {14,1,9}, {14,1,9},
  {2,4,10}, {16,1,10}, {15,1,9}, {15,1,9}
};

/* Table B-14/15, DCT coefficients table zero / one,
 * codes 000000010000 ... 000000011111
 */
mpeg3_DCTtab_t mpeg3_DCTtab2[16] =
{
  {0,11,12}, {8,2,12}, {4,3,12}, {0,10,12},
  {2,4,12}, {7,2,12}, {21,1,12}, {20,1,12},
  {0,9,12}, {19,1,12}, {18,1,12}, {1,5,12},
  {3,3,12}, {0,8,12}, {6,2,12}, {17,1,12}
};

/* Table B-14/15, DCT coefficients table zero / one,
 * codes 0000000010000 ... 0000000011111
 */
mpeg3_DCTtab_t mpeg3_DCTtab3[16] =
{
  {10,2,13}, {9,2,13}, {5,3,13}, {3,4,13},
  {2,5,13}, {1,7,13}, {1,6,13}, {0,15,13},
  {0,14,13}, {0,13,13}, {0,12,13}, {26,1,13},
  {25,1,13}, {24,1,13}, {23,1,13}, {22,1,13}
};

/* Table B-14/15, DCT coefficients table zero / one,
 * codes 00000000010000 ... 00000000011111
 */
mpeg3_DCTtab_t mpeg3_DCTtab4[16] =
{
  {0,31,14}, {0,30,14}, {0,29,14}, {0,28,14},
  {0,27,14}, {0,26,14}, {0,25,14}, {0,24,14},
  {0,23,14}, {0,22,14}, {0,21,14}, {0,20,14},
  {0,19,14}, {0,18,14}, {0,17,14}, {0,16,14}
};

/* Table B-14/15, DCT coefficients table zero / one,
 * codes 000000000010000 ... 000000000011111
 */
mpeg3_DCTtab_t mpeg3_DCTtab5[16] =
{
  {0,40,15}, {0,39,15}, {0,38,15}, {0,37,15},
  {0,36,15}, {0,35,15}, {0,34,15}, {0,33,15},
  {0,32,15}, {1,14,15}, {1,13,15}, {1,12,15},
  {1,11,15}, {1,10,15}, {1,9,15}, {1,8,15}
};

/* Table B-14/15, DCT coefficients table zero / one,
 * codes 0000000000010000 ... 0000000000011111
 */
mpeg3_DCTtab_t mpeg3_DCTtab6[16] =
{
  {1,18,16}, {1,17,16}, {1,16,16}, {1,15,16},
  {6,3,16}, {16,2,16}, {15,2,16}, {14,2,16},
  {13,2,16}, {12,2,16}, {11,2,16}, {31,1,16},
  {30,1,16}, {29,1,16}, {28,1,16}, {27,1,16}
};
