  /*  Changed Sept 15th by John M McIntosh to support Macintosh & Squeak
 */
#ifndef VLC_H
#define VLC_H

/* variable length code tables                                    */

typedef struct {
  char val, len;
} mpeg3_VLCtab_t;

typedef struct {
  char run, level, len;
} mpeg3_DCTtab_t;

/* Added 03/38/96 by Alex de Jong : avoid IRIX GNU warning */
//#ifdef ERROR
//#undef ERROR
//#define ERROR 99
//#endif

/* Table B-3, mb_type in P-pictures, codes 001..1xx */
extern mpeg3_VLCtab_t mpeg3_PMBtab0[8];

/* Table B-3, mb_type in P-pictures, codes 000001..00011x */
extern mpeg3_VLCtab_t mpeg3_PMBtab1[8];

/* Table B-4, mb_type in B-pictures, codes 0010..11xx */
extern mpeg3_VLCtab_t mpeg3_BMBtab0[16];

/* Table B-4, mb_type in B-pictures, codes 000001..00011x */
extern mpeg3_VLCtab_t mpeg3_BMBtab1[8];

/* Table B-5, mb_type in spat. scal. I-pictures, codes 0001..1xxx */
extern mpeg3_VLCtab_t mpeg3_spIMBtab[16];

/* Table B-6, mb_type in spat. scal. P-pictures, codes 0010..11xx */
extern mpeg3_VLCtab_t mpeg3_spPMBtab0[16];

/* Table B-6, mb_type in spat. scal. P-pictures, codes 0000010..000111x */
extern mpeg3_VLCtab_t mpeg3_spPMBtab1[16];

/* Table B-7, mb_type in spat. scal. B-pictures, codes 0010..11xx */
extern mpeg3_VLCtab_t mpeg3_spBMBtab0[14];

/* Table B-7, mb_type in spat. scal. B-pictures, codes 0000100..000111x */
extern mpeg3_VLCtab_t mpeg3_spBMBtab1[12];

/* Table B-7, mb_type in spat. scal. B-pictures, codes 00000100x..000001111 */
extern mpeg3_VLCtab_t mpeg3_spBMBtab2[8];

/* Table B-8, mb_type in spat. scal. B-pictures, codes 001..1xx */
extern mpeg3_VLCtab_t mpeg3_SNRMBtab[8];

/* Table B-10, motion_code, codes 0001 ... 01xx */
extern mpeg3_VLCtab_t mpeg3_MVtab0[8];

/* Table B-10, motion_code, codes 0000011 ... 000011x */
extern mpeg3_VLCtab_t mpeg3_MVtab1[8];

/* Table B-10, motion_code, codes 0000001100 ... 000001011x */
extern mpeg3_VLCtab_t mpeg3_MVtab2[12];

/* Table B-9, coded_block_pattern, codes 01000 ... 111xx */
extern mpeg3_VLCtab_t mpeg3_CBPtab0[32];

/* Table B-9, coded_block_pattern, codes 00000100 ... 001111xx */
extern mpeg3_VLCtab_t mpeg3_CBPtab1[64];

/* Table B-9, coded_block_pattern, codes 000000001 ... 000000111 */
extern mpeg3_VLCtab_t mpeg3_CBPtab2[8];

/* Table B-1, macroblock_address_increment, codes 00010 ... 011xx */
extern mpeg3_VLCtab_t mpeg3_MBAtab1[16];

/* Table B-1, macroblock_address_increment, codes 00000011000 ... 0000111xxxx */
extern mpeg3_VLCtab_t mpeg3_MBAtab2[104];

/* Table B-12, dct_dc_size_luminance, codes 00xxx ... 11110 */
extern mpeg3_VLCtab_t mpeg3_DClumtab0[32];

/* Table B-12, dct_dc_size_luminance, codes 111110xxx ... 111111111 */
extern mpeg3_VLCtab_t mpeg3_DClumtab1[16];

/* Table B-13, dct_dc_size_chrominance, codes 00xxx ... 11110 */
extern mpeg3_VLCtab_t mpeg3_DCchromtab0[32];

/* Table B-13, dct_dc_size_chrominance, codes 111110xxxx ... 1111111111 */
extern mpeg3_VLCtab_t mpeg3_DCchromtab1[32];

/* Table B-14, DCT coefficients table zero,
 * codes 0100 ... 1xxx (used for first (DC) coefficient)
 */
extern mpeg3_DCTtab_t mpeg3_DCTtabfirst[12];

/* Table B-14, DCT coefficients table zero,
 * codes 0100 ... 1xxx (used for all other coefficients)
 */
extern mpeg3_DCTtab_t mpeg3_DCTtabnext[12];

/* Table B-14, DCT coefficients table zero,
 * codes 000001xx ... 00111xxx
 */
extern mpeg3_DCTtab_t mpeg3_DCTtab0[60];

/* Table B-15, DCT coefficients table one,
 * codes 000001xx ... 11111111
*/
extern mpeg3_DCTtab_t mpeg3_DCTtab0a[252];

/* Table B-14, DCT coefficients table zero,
 * codes 0000001000 ... 0000001111
 */
extern mpeg3_DCTtab_t mpeg3_DCTtab1[8];

/* Table B-15, DCT coefficients table one,
 * codes 000000100x ... 000000111x
 */
extern mpeg3_DCTtab_t mpeg3_DCTtab1a[8];

/* Table B-14/15, DCT coefficients table zero / one,
 * codes 000000010000 ... 000000011111
 */
extern mpeg3_DCTtab_t mpeg3_DCTtab2[16];

/* Table B-14/15, DCT coefficients table zero / one,
 * codes 0000000010000 ... 0000000011111
 */
extern mpeg3_DCTtab_t mpeg3_DCTtab3[16];

/* Table B-14/15, DCT coefficients table zero / one,
 * codes 00000000010000 ... 00000000011111
 */
extern mpeg3_DCTtab_t mpeg3_DCTtab4[16];

/* Table B-14/15, DCT coefficients table zero / one,
 * codes 000000000010000 ... 000000000011111
 */
extern mpeg3_DCTtab_t mpeg3_DCTtab5[16];

/* Table B-14/15, DCT coefficients table zero / one,
 * codes 0000000000010000 ... 0000000000011111
 */
extern mpeg3_DCTtab_t mpeg3_DCTtab6[16];


#endif
