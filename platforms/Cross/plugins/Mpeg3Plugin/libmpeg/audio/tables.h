#ifndef TABLES_H
#define TABLES_H

extern int mpeg3_tabsel_123[2][3][16];

extern long mpeg3_freqs[9];

struct mpeg3_bandInfoStruct 
{
	int longIdx[23];
	int longDiff[22];
	int shortIdx[14];
	int shortDiff[13];
};


extern float mpeg3_decwin[512 + 32];
extern float mpeg3_cos64[16], mpeg3_cos32[8], mpeg3_cos16[4], mpeg3_cos8[2], mpeg3_cos4[1];

extern float *mpeg3_pnts[5];

extern int mpeg3_grp_3tab[32 * 3];   /* used: 27 */
extern int mpeg3_grp_5tab[128 * 3];  /* used: 125 */
extern int mpeg3_grp_9tab[1024 * 3]; /* used: 729 */
extern float mpeg3_muls[27][64];	/* also used by layer 1 */
extern float mpeg3_gainpow2[256 + 118 + 4];
extern long mpeg3_intwinbase[257];
extern float mpeg3_ispow[8207];
extern float mpeg3_aa_ca[8], mpeg3_aa_cs[8];
extern float mpeg3_win[4][36];
extern float mpeg3_win1[4][36];
extern float mpeg3_COS1[12][6];
extern float mpeg3_COS9[9];
extern float mpeg3_COS6_1, mpeg3_COS6_2;
extern float mpeg3_tfcos36[9];
extern float mpeg3_tfcos12[3];
extern float mpeg3_cos9[3], mpeg3_cos18[3];
extern float mpeg3_tan1_1[16], mpeg3_tan2_1[16], mpeg3_tan1_2[16], mpeg3_tan2_2[16];
extern float mpeg3_pow1_1[2][16], mpeg3_pow2_1[2][16], mpeg3_pow1_2[2][16], mpeg3_pow2_2[2][16];

extern int mpeg3_longLimit[9][23];
extern int mpeg3_shortLimit[9][14];

extern struct mpeg3_bandInfoStruct mpeg3_bandInfo[9];

extern int mpeg3_mapbuf0[9][152];
extern int mpeg3_mapbuf1[9][156];
extern int mpeg3_mapbuf2[9][44];
extern int *mpeg3_map[9][3];
extern int *mpeg3_mapend[9][3];

extern unsigned int mpeg3_n_slen2[512]; /* MPEG 2.0 slen for 'normal' mode */
extern unsigned int mpeg3_i_slen2[256]; /* MPEG 2.0 slen for intensity stereo */

#endif
