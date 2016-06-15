#ifndef AC3_H
#define AC3_H

#define MAX_AC3_FRAMESIZE 1920 * 2 + 512

//extern int mpeg3_ac3_samplerates[3];

/* Exponent strategy constants */
#define MPEG3_EXP_REUSE (0)
#define MPEG3_EXP_D15   (1)
#define MPEG3_EXP_D25   (2)
#define MPEG3_EXP_D45   (3)

/* Delta bit allocation constants */
#define DELTA_BIT_REUSE (0)
#define DELTA_BIT_NEW (1)
#define DELTA_BIT_NONE (2)
#define DELTA_BIT_RESERVED (3)


typedef float mpeg3ac3_stream_samples_t[6][256];

typedef struct
{
/* Bit stream identification == 0x8 */
	int bsid;	
/* Bit stream mode */
	int bsmod;
/* Audio coding mode */
	int acmod;
/* If we're using the centre channel then */
/* centre mix level */
		int cmixlev;
/* If we're using the surround channel then */
/* surround mix level */
		int surmixlev;
/* If we're in 2/0 mode then */
/* Dolby surround mix level - NOT USED - */
		int dsurmod;
/* Low frequency effects on */
	int lfeon;
/* Dialogue Normalization level */
	int dialnorm;
/* Compression exists */
	int compre;
/* Compression level */
		int compr;
/* Language code exists */
	int langcode;
/* Language code */
		int langcod;
/* Audio production info exists*/
	unsigned int audprodie;
		int mixlevel;
		int roomtyp;
/* If we're in dual mono mode (acmod == 0) then extra stuff */
		int dialnorm2;
		int compr2e;
			int compr2;
		int langcod2e;
			int langcod2;
		int audprodi2e;
			int mixlevel2;
			int roomtyp2;
/* Copyright bit */
	int copyrightb;
/* Original bit */
	int origbs;
/* Timecode 1 exists */
	int timecod1e;
/* Timecode 1 */
		unsigned int timecod1;
/* Timecode 2 exists */
	int timecod2e;
/* Timecode 2 */
		unsigned int timecod2;
/* Additional bit stream info exists */
	int addbsie;
/* Additional bit stream length - 1 (in bytes) */
		int addbsil;
/* Additional bit stream information (max 64 bytes) */
		unsigned char addbsi[64];

/* Information not in the AC-3 bitstream, but derived */
/* Number of channels (excluding LFE)
 * Derived from acmod */
	int nfchans;
} mpeg3_ac3bsi_t;

typedef struct 
{
/* block switch bit indexed by channel num */
	unsigned short blksw[5];
/* dither enable bit indexed by channel num */
	unsigned short dithflag[5];
/* dynamic range gain exists */
	int dynrnge;
/* dynamic range gain */
		int dynrng;
/* if acmod==0 then */
/* dynamic range 2 gain exists */
	int dynrng2e;
/* dynamic range 2 gain */
		int dynrng2;
/* coupling strategy exists */
	int cplstre;
/* coupling in use */
		int cplinu;
/* channel coupled */
			unsigned short chincpl[5];
/* if acmod==2 then */
/* Phase flags in use */
				int phsflginu;
/* coupling begin frequency code */
			int cplbegf;
/* coupling end frequency code */
			int cplendf;
/* coupling band structure bits */
			unsigned short cplbndstrc[18];
/* Do coupling co-ords exist for this channel? */
			unsigned short cplcoe[5];
/* Master coupling co-ordinate */
			unsigned short mstrcplco[5];
/* Per coupling band coupling co-ordinates */
			unsigned short cplcoexp[5][18];
			unsigned short cplcomant[5][18];
/* Phase flags for dual mono */
			unsigned short phsflg[18];
/* Is there a rematrixing strategy */
	unsigned int rematstr;
/* Rematrixing bits */
		unsigned short rematflg[4];
/* Coupling exponent strategy */
	int cplexpstr;
/* Exponent strategy for full bandwidth channels */
	unsigned short chexpstr[5];
/* Exponent strategy for lfe channel */
	int lfeexpstr;
/* Channel bandwidth for independent channels */
	unsigned short chbwcod[5];
/* The absolute coupling exponent */
		int cplabsexp;
/* Coupling channel exponents (D15 mode gives 18 * 12 /3  encoded exponents */
		unsigned short cplexps[18 * 12 / 3];
/* fbw channel exponents */
	unsigned short exps[5][252 / 3];
/* channel gain range */
	unsigned short gainrng[5];
/* low frequency exponents */
	unsigned short lfeexps[3];

/* Bit allocation info */
	int baie;
/* Slow decay code */
		int sdcycod;
/* Fast decay code */
		int fdcycod;
/* Slow gain code */
		int sgaincod;
/* dB per bit code */
		int dbpbcod;
/* masking floor code */
		int floorcod;

/* SNR offset info */
	int snroffste;
/* coarse SNR offset */
		int csnroffst;
/* coupling fine SNR offset */
		int cplfsnroffst;
/* coupling fast gain code */
		int cplfgaincod;
/* fbw fine SNR offset */
		unsigned short fsnroffst[5];
/* fbw fast gain code */
		unsigned short fgaincod[5];
/* lfe fine SNR offset */
		int lfefsnroffst;
/* lfe fast gain code */
		int lfefgaincod;
	
/* Coupling leak info */
	int cplleake;
/* coupling fast leak initialization */
		int cplfleak;
/* coupling slow leak initialization */
		int cplsleak;
	
/* delta bit allocation info */
	int deltbaie;
/* coupling delta bit allocation exists */
		int cpldeltbae;
/* fbw delta bit allocation exists */
		unsigned short deltbae[5];
/* number of cpl delta bit segments */
		int cpldeltnseg;
/* coupling delta bit allocation offset */
			unsigned short cpldeltoffst[8];
/* coupling delta bit allocation length */
			unsigned short cpldeltlen[8];
/* coupling delta bit allocation length */
			unsigned short cpldeltba[8];
/* number of delta bit segments */
		unsigned short deltnseg[5];
/* fbw delta bit allocation offset */
			unsigned short deltoffst[5][8];
/* fbw delta bit allocation length */
			unsigned short deltlen[5][8];
/* fbw delta bit allocation length */
			unsigned short deltba[5][8];

/* skip length exists */
	int skiple;
/* skip length */
	int skipl;

/* channel mantissas */
	short chmant[5][256];

/* coupling mantissas */
	unsigned short cplmant[256];

/* coupling mantissas */
	unsigned short lfemant[7];

/*  -- Information not in the bitstream, but derived thereof  -- */

/* Number of coupling sub-bands */
	int ncplsubnd;

/* Number of combined coupling sub-bands
 * Derived from ncplsubnd and cplbndstrc */
	int ncplbnd;

/* Number of exponent groups by channel
 * Derived from strmant, endmant */
	int nchgrps[5];

/* Number of coupling exponent groups
 * Derived from cplbegf, cplendf, cplexpstr */
	int ncplgrps;
			
/* End mantissa numbers of fbw channels */
	unsigned short endmant[5];

/* Start and end mantissa numbers for the coupling channel */
	int cplstrtmant;
	int cplendmant;

/* Decoded exponent info */
	unsigned short fbw_exp[5][256];
	unsigned short cpl_exp[256];
	unsigned short lfe_exp[7];

/* Bit allocation pointer results */
	unsigned short fbw_bap[5][256];
/*FIXME figure out exactly how many entries there should be (253-37?)  */
	unsigned short cpl_bap[256];
	unsigned short lfe_bap[7];
} mpeg3_ac3audblk_t;

/* Bit allocation data */
typedef struct
{
	int sdecay;
	int fdecay;
	int sgain;
	int dbknee;
	int floor;
	short psd[256];
	short bndpsd[256];
	short excite[256];
	short mask[256];
} mpeg3_ac3_bitallocation_t;

/* Mantissa data */
typedef struct
{
	unsigned short m_1[3];
	unsigned short m_2[3];
	unsigned short m_4[2];
	unsigned short m_1_pointer;
	unsigned short m_2_pointer;
	unsigned short m_4_pointer;
} mpeg3_ac3_mantissa_t;

#endif
