/*
 * Copyright 1992 by Jutta Degener and Carsten Bormann, Technische
 * Universitaet Berlin.  See the accompanying file "COPYRIGHT" for
 * details.  THERE IS ABSOLUTELY NO WARRANTY FOR THIS SOFTWARE.
 */

/* This file was created by concatenating a number of separate header
   and source files from Jutta Degener and Carsten Bormann implementation,
   patch level 10. This was done to simplify Squeak source code maintenance.
 */

#include <assert.h>
#include <stdio.h>
#include <string.h>

#include "SoundCodecPrims.h"

/****** begin "gsm.h" *****/

#ifdef __cplusplus
#	define	NeedFunctionPrototypes	1
#endif

#if __STDC__
#	define	NeedFunctionPrototypes	1
#endif

#ifdef _NO_PROTO
#	undef	NeedFunctionPrototypes
#endif

#ifdef NeedFunctionPrototypes
#   include	<stdio.h>		/* for FILE * 	*/
#endif

#undef GSM_P
#if NeedFunctionPrototypes
#	define	GSM_P( protos )	protos
#else
#	define  GSM_P( protos )	( /* protos */ )
#endif

/*
 *	Interface
 */

typedef struct gsm_state * 	gsm;
typedef short		   	gsm_signal;		/* signed 16 bit */
typedef unsigned char		gsm_byte;
typedef gsm_byte 		gsm_frame[33];		/* 33 * 8 bits	 */

#define	GSM_MAGIC		0xD		  	/* 13 kbit/s RPE-LTP */

#define	GSM_PATCHLEVEL		10
#define	GSM_MINOR		0
#define	GSM_MAJOR		1

#define	GSM_OPT_VERBOSE		1
#define	GSM_OPT_FAST		2
#define	GSM_OPT_LTP_CUT		3
#define	GSM_OPT_WAV49		4
#define	GSM_OPT_FRAME_INDEX	5
#define	GSM_OPT_FRAME_CHAIN	6

extern gsm  gsm_create 	GSM_P((void));
extern void gsm_destroy GSM_P((gsm));	

extern int  gsm_print   GSM_P((FILE *, gsm, gsm_byte  *));
extern int  gsm_option  GSM_P((gsm, int, int *));

extern void gsm_encode  GSM_P((gsm, gsm_signal *, gsm_byte  *));
extern int  gsm_decode  GSM_P((gsm, gsm_byte   *, gsm_signal *));

extern int  gsm_explode GSM_P((gsm, gsm_byte   *, gsm_signal *));
extern void gsm_implode GSM_P((gsm, gsm_signal *, gsm_byte   *));

/****** begin "proto.h" *****/

#if __cplusplus
#	define	NeedFunctionPrototypes	1
#endif

#if __STDC__
#	define	NeedFunctionPrototypes	1
#endif

#ifdef	_NO_PROTO
#	undef	NeedFunctionPrototypes
#endif

#undef	P	/* gnu stdio.h actually defines this... 	*/
#undef	P0
#undef	P1
#undef	P2
#undef	P3
#undef	P4
#undef	P5
#undef	P6
#undef	P7
#undef	P8

#if NeedFunctionPrototypes

#	define	P( protos )	protos

#	define	P0()				(void)
#	define	P1(x, a)			(a)
#	define	P2(x, a, b)			(a, b)
#	define	P3(x, a, b, c)			(a, b, c)
#	define	P4(x, a, b, c, d)		(a, b, c, d)	
#	define	P5(x, a, b, c, d, e)		(a, b, c, d, e)
#	define	P6(x, a, b, c, d, e, f)		(a, b, c, d, e, f)
#	define	P7(x, a, b, c, d, e, f, g)	(a, b, c, d, e, f, g)
#	define	P8(x, a, b, c, d, e, f, g, h)	(a, b, c, d, e, f, g, h)

#else /* !NeedFunctionPrototypes */

#	define	P( protos )	( /* protos */ )

#	define	P0()				()
#	define	P1(x, a)			x a;
#	define	P2(x, a, b)			x a; b;
#	define	P3(x, a, b, c)			x a; b; c;
#	define	P4(x, a, b, c, d)		x a; b; c; d;
#	define	P5(x, a, b, c, d, e)		x a; b; c; d; e;
#	define	P6(x, a, b, c, d, e, f)		x a; b; c; d; e; f;
#	define	P7(x, a, b, c, d, e, f, g)	x a; b; c; d; e; f; g;
#	define	P8(x, a, b, c, d, e, f, g, h)	x a; b; c; d; e; f; g; h;

#endif  /* !NeedFunctionPrototypes */

/****** begin "private.h" *****/

typedef short			word;		/* 16 bit signed int	*/
typedef unsigned short		uword;		/* unsigned word	*/

#if _LP64
typedef int				longword;	/* 32 bit signed int	*/
typedef unsigned int	ulongword;	/* unsigned longword	*/
#else
typedef long			longword;	/* 32 bit signed int	*/
typedef unsigned long	ulongword;	/* unsigned longword	*/
#endif

struct gsm_state {

	word		dp0[ 280 ];

	word		z1;		/* preprocessing.c, Offset_com. */
	longword	L_z2;		/*                  Offset_com. */
	int		mp;		/*                  Preemphasis	*/

	word		u[8];		/* short_term_aly_filter.c	*/
	word		LARpp[2][8]; 	/*                              */
	word		j;		/*                              */

	word            ltp_cut;        /* long_term.c, LTP crosscorr.  */
	word		nrp; /* 40 */	/* long_term.c, synthesis	*/
	word		v[9];		/* short_term.c, synthesis	*/
	word		msr;		/* decoder.c,	Postprocessing	*/

	char		verbose;	/* only used if !NDEBUG		*/
	char		fast;		/* only used if FAST		*/

	char		wav_fmt;	/* only used if WAV49 defined	*/
	unsigned char	frame_index;	/*            odd/even chaining	*/
	unsigned char	frame_chain;	/*   half-byte to carry forward	*/
};


#define	MIN_WORD	(-32767 - 1)
#define	MAX_WORD	  32767

#define	MIN_LONGWORD	(-2147483647 - 1)
#define	MAX_LONGWORD	  2147483647

#ifdef	SASR		/* flag: >> is a signed arithmetic shift right */
#undef	SASR
#define	SASR(x, by)	((x) >> (by))
#else
#define	SASR(x, by)	((x) >= 0 ? (x) >> (by) : (~(-((x) + 1) >> (by))))
#endif	/* SASR */

//#include "proto.h"

/*
 *	Prototypes from add.c
 */
extern word	gsm_mult 	P((word a, word b));
extern longword gsm_L_mult 	P((word a, word b));
extern word	gsm_mult_r	P((word a, word b));

extern word	gsm_div  	P((word num, word denum));

extern word	gsm_add 	P(( word a, word b ));
extern longword gsm_L_add 	P(( longword a, longword b ));

extern word	gsm_sub 	P((word a, word b));
extern longword gsm_L_sub 	P((longword a, longword b));

extern word	gsm_abs 	P((word a));

extern word	gsm_norm 	P(( longword a ));

extern longword gsm_L_asl  	P((longword a, int n));
extern word	gsm_asl 	P((word a, int n));

extern longword gsm_L_asr  	P((longword a, int n));
extern word	gsm_asr  	P((word a, int n));

/*
 *  Inlined functions from add.h 
 */

/* 
 * #define GSM_MULT_R(a, b) (* word a, word b, !(a == b == MIN_WORD) *)	\
 *	(0x0FFFF & SASR(((longword)(a) * (longword)(b) + 16384), 15))
 */
#define GSM_MULT_R(a, b) /* word a, word b, !(a == b == MIN_WORD) */	\
	(SASR( ((longword)(a) * (longword)(b) + 16384), 15 ))

# define GSM_MULT(a,b)	 /* word a, word b, !(a == b == MIN_WORD) */	\
	(SASR( ((longword)(a) * (longword)(b)), 15 ))

# define GSM_L_MULT(a, b) /* word a, word b */	\
	(((longword)(a) * (longword)(b)) << 1)

# define GSM_L_ADD(a, b)	\
	( (a) <  0 ? ( (b) >= 0 ? (a) + (b)	\
		 : (utmp = (ulongword)-((a) + 1) + (ulongword)-((b) + 1)) \
		   >= MAX_LONGWORD ? MIN_LONGWORD : -(longword)utmp-2 )   \
	: ((b) <= 0 ? (a) + (b)   \
	          : (utmp = (ulongword)(a) + (ulongword)(b)) >= MAX_LONGWORD \
		    ? MAX_LONGWORD : utmp))

/*
 * # define GSM_ADD(a, b)	\
 * 	((ltmp = (longword)(a) + (longword)(b)) >= MAX_WORD \
 * 	? MAX_WORD : ltmp <= MIN_WORD ? MIN_WORD : ltmp)
 */
/* Nonportable, but faster: */

#define	GSM_ADD(a, b)	\
	((ulongword)((ltmp = (longword)(a) + (longword)(b)) - MIN_WORD) > \
		MAX_WORD - MIN_WORD ? (ltmp > 0 ? MAX_WORD : MIN_WORD) : ltmp)

# define GSM_SUB(a, b)	\
	((ltmp = (longword)(a) - (longword)(b)) >= MAX_WORD \
	? MAX_WORD : ltmp <= MIN_WORD ? MIN_WORD : ltmp)

# define GSM_ABS(a)	((a) < 0 ? ((a) == MIN_WORD ? MAX_WORD : -(a)) : (a))

/* Use these if necessary:

# define GSM_MULT_R(a, b)	gsm_mult_r(a, b)
# define GSM_MULT(a, b)		gsm_mult(a, b)
# define GSM_L_MULT(a, b)	gsm_L_mult(a, b)

# define GSM_L_ADD(a, b)	gsm_L_add(a, b)
# define GSM_ADD(a, b)		gsm_add(a, b)
# define GSM_SUB(a, b)		gsm_sub(a, b)

# define GSM_ABS(a)		gsm_abs(a)

*/

/*
 *  More prototypes from implementations..
 */
extern void Gsm_Coder P((
		struct gsm_state	* S,
		word	* s,	/* [0..159] samples		IN	*/
		word	* LARc,	/* [0..7] LAR coefficients	OUT	*/
		word	* Nc,	/* [0..3] LTP lag		OUT 	*/
		word	* bc,	/* [0..3] coded LTP gain	OUT 	*/
		word	* Mc,	/* [0..3] RPE grid selection	OUT     */
		word	* xmaxc,/* [0..3] Coded maximum amplitude OUT	*/
		word	* xMc	/* [13*4] normalized RPE samples OUT	*/));

extern void Gsm_Long_Term_Predictor P((		/* 4x for 160 samples */
		struct gsm_state * S,
		word	* d,	/* [0..39]   residual signal	IN	*/
		word	* dp,	/* [-120..-1] d'		IN	*/
		word	* e,	/* [0..40] 			OUT	*/
		word	* dpp,	/* [0..40] 			OUT	*/
		word	* Nc,	/* correlation lag		OUT	*/
		word	* bc	/* gain factor			OUT	*/));

extern void Gsm_LPC_Analysis P((
		struct gsm_state * S,
		word * s,	 /* 0..159 signals	IN/OUT	*/
	        word * LARc));   /* 0..7   LARc's	OUT	*/

extern void Gsm_Preprocess P((
		struct gsm_state * S,
		word * s, word * so));

extern void Gsm_Encoding P((
		struct gsm_state * S,
		word	* e,	
		word	* ep,	
		word	* xmaxc,
		word	* Mc,	
		word	* xMc));

extern void Gsm_Short_Term_Analysis_Filter P((
		struct gsm_state * S,
		word	* LARc,	/* coded log area ratio [0..7]  IN	*/
		word	* d	/* st res. signal [0..159]	IN/OUT	*/));

extern void Gsm_Decoder P((
		struct gsm_state * S,
		word	* LARcr,	/* [0..7]		IN	*/
		word	* Ncr,		/* [0..3] 		IN 	*/
		word	* bcr,		/* [0..3]		IN	*/
		word	* Mcr,		/* [0..3] 		IN 	*/
		word	* xmaxcr,	/* [0..3]		IN 	*/
		word	* xMcr,		/* [0..13*4]		IN	*/
		word	* s));		/* [0..159]		OUT 	*/

extern void Gsm_Decoding P((
		struct gsm_state * S,
		word 	xmaxcr,
		word	Mcr,
		word	* xMcr,  	/* [0..12]		IN	*/
		word	* erp)); 	/* [0..39]		OUT 	*/

extern void Gsm_Long_Term_Synthesis_Filtering P((
		struct gsm_state* S,
		word	Ncr,
		word	bcr,
		word	* erp,		/* [0..39]		  IN 	*/
		word	* drp)); 	/* [-120..-1] IN, [0..40] OUT 	*/

void Gsm_RPE_Decoding P((
	struct gsm_state *S,
		word xmaxcr,
		word Mcr,
		word * xMcr,  /* [0..12], 3 bits             IN      */
		word * erp)); /* [0..39]                     OUT     */

void Gsm_RPE_Encoding P((
		struct gsm_state * S,
		word    * e,            /* -5..-1][0..39][40..44     IN/OUT  */
		word    * xmaxc,        /*                              OUT */
		word    * Mc,           /*                              OUT */
		word    * xMc));        /* [0..12]                      OUT */

extern void Gsm_Short_Term_Synthesis_Filter P((
		struct gsm_state * S,
		word	* LARcr, 	/* log area ratios [0..7]  IN	*/
		word	* drp,		/* received d [0...39]	   IN	*/
		word	* s));		/* signal   s [0..159]	  OUT	*/

extern void Gsm_Update_of_reconstructed_short_time_residual_signal P((
		word	* dpp,		/* [0...39]	IN	*/
		word	* ep,		/* [0...39]	IN	*/
		word	* dp));		/* [-120...-1]  IN/OUT 	*/

/*
 *  Tables from table.c
 */
#ifndef	GSM_TABLE_C

extern word gsm_A[8], gsm_B[8], gsm_MIC[8], gsm_MAC[8];
extern word gsm_INVA[8];
extern word gsm_DLB[4], gsm_QLB[4];
extern word gsm_H[11];
extern word gsm_NRFAC[8];
extern word gsm_FAC[8];

#endif	/* GSM_TABLE_C */

/*
 *  Debugging
 */
#ifdef NDEBUG

#	define	gsm_debug_words(a, b, c, d)		/* nil */
#	define	gsm_debug_longwords(a, b, c, d)		/* nil */
#	define	gsm_debug_word(a, b)			/* nil */
#	define	gsm_debug_longword(a, b)		/* nil */

#else	/* !NDEBUG => DEBUG */

	extern void  gsm_debug_words     P((char * name, int, int, word *));
	extern void  gsm_debug_longwords P((char * name, int, int, longword *));
	extern void  gsm_debug_longword  P((char * name, longword));
	extern void  gsm_debug_word      P((char * name, word));

#endif /* !NDEBUG */


/****** begin "add.c" *****/


#define	saturate(x) 	\
	((x) < MIN_WORD ? MIN_WORD : (x) > MAX_WORD ? MAX_WORD: (x))

word gsm_add P2((a,b), word a, word b)
{
	longword sum = (longword)a + (longword)b;
	return saturate(sum);
}

word gsm_sub P2((a,b), word a, word b)
{
	longword diff = (longword)a - (longword)b;
	return saturate(diff);
}

word gsm_mult P2((a,b), word a, word b)
{
	if (a == MIN_WORD && b == MIN_WORD) return MAX_WORD;
	else return SASR( (longword)a * (longword)b, 15 );
}

word gsm_mult_r P2((a,b), word a, word b)
{
	if (b == MIN_WORD && a == MIN_WORD) return MAX_WORD;
	else {
		longword prod = (longword)a * (longword)b + 16384;
		prod >>= 15;
		return prod & 0xFFFF;
	}
}

word gsm_abs P1((a), word a)
{
	return a < 0 ? (a == MIN_WORD ? MAX_WORD : -a) : a;
}

longword gsm_L_mult P2((a,b),word a, word b)
{
	assert( a != MIN_WORD || b != MIN_WORD );
	return ((longword)a * (longword)b) << 1;
}

longword gsm_L_add P2((a,b), longword a, longword b)
{
	if (a < 0) {
		if (b >= 0) return a + b;
		else {
			ulongword A = (ulongword)-(a + 1) + (ulongword)-(b + 1);
			return A >= MAX_LONGWORD ? MIN_LONGWORD :-(longword)A-2;
		}
	}
	else if (b <= 0) return a + b;
	else {
		ulongword A = (ulongword)a + (ulongword)b;
		return A > MAX_LONGWORD ? MAX_LONGWORD : A;
	}
}

longword gsm_L_sub P2((a,b), longword a, longword b)
{
	if (a >= 0) {
		if (b >= 0) return a - b;
		else {
			/* a>=0, b<0 */

			ulongword A = (ulongword)a + -(b + 1);
			return A >= MAX_LONGWORD ? MAX_LONGWORD : (A + 1);
		}
	}
	else if (b <= 0) return a - b;
	else {
		/* a<0, b>0 */  

		ulongword A = (ulongword)-(a + 1) + b;
		return A >= MAX_LONGWORD ? MIN_LONGWORD : -(longword)A - 1;
	}
}

static unsigned char const bitoff[ 256 ] = {
	 8, 7, 6, 6, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 4,
	 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
	 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

word gsm_norm P1((a), longword a )
/*
 * the number of left shifts needed to normalize the 32 bit
 * variable L_var1 for positive values on the interval
 *
 * with minimum of
 * minimum of 1073741824  (01000000000000000000000000000000) and 
 * maximum of 2147483647  (01111111111111111111111111111111)
 *
 *
 * and for negative values on the interval with
 * minimum of -2147483648 (-10000000000000000000000000000000) and
 * maximum of -1073741824 ( -1000000000000000000000000000000).
 *
 * in order to normalize the result, the following
 * operation must be done: L_norm_var1 = L_var1 << norm( L_var1 );
 *
 * (That's 'ffs', only from the left, not the right..)
 */
{
	assert(a != 0);

	if (a < 0) {
		if (a <= -1073741824) return 0;
		a = ~a;
	}

	return    a & 0xffff0000 
		? ( a & 0xff000000
		  ?  -1 + bitoff[ 0xFF & (a >> 24) ]
		  :   7 + bitoff[ 0xFF & (a >> 16) ] )
		: ( a & 0xff00
		  ?  15 + bitoff[ 0xFF & (a >> 8) ]
		  :  23 + bitoff[ 0xFF & a ] );
}

longword gsm_L_asl P2((a,n), longword a, int n)
{
	if (n >= 32) return 0;
	if (n <= -32) return -(a < 0);
	if (n < 0) return gsm_L_asr(a, -n);
	return a << n;
}

word gsm_asl P2((a,n), word a, int n)
{
	if (n >= 16) return 0;
	if (n <= -16) return -(a < 0);
	if (n < 0) return gsm_asr(a, -n);
	return a << n;
}

longword gsm_L_asr P2((a,n), longword a, int n)
{
	if (n >= 32) return -(a < 0);
	if (n <= -32) return 0;
	if (n < 0) return a << -n;

#	ifdef	SASR
		return a >> n;
#	else
		if (a >= 0) return a >> n;
		else return -(longword)( -(ulongword)a >> n );
#	endif
}

word gsm_asr P2((a,n), word a, int n)
{
	if (n >= 16) return -(a < 0);
	if (n <= -16) return 0;
	if (n < 0) return a << -n;

#	ifdef	SASR
		return a >> n;
#	else
		if (a >= 0) return a >> n;
		else return -(word)( -(uword)a >> n );
#	endif
}

/* 
 *  (From p. 46, end of section 4.2.5)
 *
 *  NOTE: The following lines gives [sic] one correct implementation
 *  	  of the div(num, denum) arithmetic operation.  Compute div
 *        which is the integer division of num by denum: with denum
 *	  >= num > 0
 */

word gsm_div P2((num,denum), word num, word denum)
{
	longword	L_num   = num;
	longword	L_denum = denum;
	word		div 	= 0;
	volatile  int		k 	= 15;

	/* The parameter num sometimes becomes zero.
	 * Although this is explicitly guarded against in 4.2.5,
	 * we assume that the result should then be zero as well.
	 */

	/* assert(num != 0); */

	assert(num >= 0 && denum >= num);
	if (num == 0)
	    return 0;

	while (k--) {
		div   <<= 1;
		L_num <<= 1;

		if (L_num >= L_denum) {
			L_num -= L_denum;
			div++;
		}
	}

	return div;
}

/****** begin "code.c" *****/

/* 
 *  4.2 FIXED POINT IMPLEMENTATION OF THE RPE-LTP CODER 
 */

void Gsm_Coder P8((S,s,LARc,Nc,bc,Mc,xmaxc,xMc),

	struct gsm_state	* S,

	word	* s,	/* [0..159] samples		  	IN	*/

/*
 * The RPE-LTD coder works on a frame by frame basis.  The length of
 * the frame is equal to 160 samples.  Some computations are done
 * once per frame to produce at the output of the coder the
 * LARc[1..8] parameters which are the coded LAR coefficients and 
 * also to realize the inverse filtering operation for the entire
 * frame (160 samples of signal d[0..159]).  These parts produce at
 * the output of the coder:
 */

	word	* LARc,	/* [0..7] LAR coefficients		OUT	*/

/*
 * Procedure 4.2.11 to 4.2.18 are to be executed four times per
 * frame.  That means once for each sub-segment RPE-LTP analysis of
 * 40 samples.  These parts produce at the output of the coder:
 */

	word	* Nc,	/* [0..3] LTP lag			OUT 	*/
	word	* bc,	/* [0..3] coded LTP gain		OUT 	*/
	word	* Mc,	/* [0..3] RPE grid selection		OUT     */
	word	* xmaxc,/* [0..3] Coded maximum amplitude	OUT	*/
	word	* xMc	/* [13*4] normalized RPE samples	OUT	*/
)
{
	int	k;
	word	* dp  = S->dp0 + 120;	/* [ -120...-1 ] */
	word	* dpp = dp;		/* [ 0...39 ]	 */

	static word e[50];

	word	so[160];

	Gsm_Preprocess			(S, s, so);
	Gsm_LPC_Analysis		(S, so, LARc);
	Gsm_Short_Term_Analysis_Filter	(S, LARc, so);

	for (k = 0; k <= 3; k++, xMc += 13) {

		Gsm_Long_Term_Predictor	( S,
					 so+k*40, /* d      [0..39] IN	*/
					 dp,	  /* dp  [-120..-1] IN	*/
					e + 5,	  /* e      [0..39] OUT	*/
					dpp,	  /* dpp    [0..39] OUT */
					 Nc++,
					 bc++);

		Gsm_RPE_Encoding	( S,
					e + 5,	/* e	  ][0..39][ IN/OUT */
					  xmaxc++, Mc++, xMc );
		/*
		 * Gsm_Update_of_reconstructed_short_time_residual_signal
		 *			( dpp, e + 5, dp );
		 */

		{ register int i;
		  register longword ltmp;
		  for (i = 0; i <= 39; i++)
			dp[ i ] = GSM_ADD( e[5 + i], dpp[i] );
		}
		dp  += 40;
		dpp += 40;

	}
	(void)memcpy( (char *)S->dp0, (char *)(S->dp0 + 160),
		120 * sizeof(*S->dp0) );
}

/****** begin "decode.c" *****/

/*
 *  4.3 FIXED POINT IMPLEMENTATION OF THE RPE-LTP DECODER
 */

static void Postprocessing P2((S,s),
	struct gsm_state	* S,
	register word 		* s)
{
	register int		k;
	register word		msr = S->msr;
	register longword	ltmp;	/* for GSM_ADD */
	register word		tmp;

	for (k = 160; k--; s++) {
		tmp = GSM_MULT_R( msr, 28180 );
		msr = GSM_ADD(*s, tmp);  	   /* Deemphasis 	     */
		*s  = GSM_ADD(msr, msr) & 0xFFF8;  /* Truncation & Upscaling */
	}
	S->msr = msr;
}

void Gsm_Decoder P8((S,LARcr, Ncr,bcr,Mcr,xmaxcr,xMcr,s),
	struct gsm_state	* S,

	word		* LARcr,	/* [0..7]		IN	*/

	word		* Ncr,		/* [0..3] 		IN 	*/
	word		* bcr,		/* [0..3]		IN	*/
	word		* Mcr,		/* [0..3] 		IN 	*/
	word		* xmaxcr,	/* [0..3]		IN 	*/
	word		* xMcr,		/* [0..13*4]		IN	*/

	word		* s)		/* [0..159]		OUT 	*/
{
	int		j, k;
	word		erp[40], wt[160];
	word		* drp = S->dp0 + 120;

	for (j=0; j <= 3; j++, xmaxcr++, bcr++, Ncr++, Mcr++, xMcr += 13) {

		Gsm_RPE_Decoding( S, *xmaxcr, *Mcr, xMcr, erp );
		Gsm_Long_Term_Synthesis_Filtering( S, *Ncr, *bcr, erp, drp );

		for (k = 0; k <= 39; k++) wt[ j * 40 + k ] =  drp[ k ];
	}

	Gsm_Short_Term_Synthesis_Filter( S, LARcr, wt, s );
	Postprocessing(S, s);
}

/****** begin "gsm_decode.c" *****/

int gsm_decode P3((s, c, target), gsm s, gsm_byte * c, gsm_signal * target)
{
	word  	LARc[8], Nc[4], Mc[4], bc[4], xmaxc[4], xmc[13*4];

#ifdef WAV49
	if (s->wav_fmt) {

		uword sr = 0;

		s->frame_index = !s->frame_index;
		if (s->frame_index) {

			sr = *c++;
			LARc[0] = sr & 0x3f;  sr >>= 6;
			sr |= (uword)*c++ << 2;
			LARc[1] = sr & 0x3f;  sr >>= 6;
			sr |= (uword)*c++ << 4;
			LARc[2] = sr & 0x1f;  sr >>= 5;
			LARc[3] = sr & 0x1f;  sr >>= 5;
			sr |= (uword)*c++ << 2;
			LARc[4] = sr & 0xf;  sr >>= 4;
			LARc[5] = sr & 0xf;  sr >>= 4;
			sr |= (uword)*c++ << 2;			/* 5 */
			LARc[6] = sr & 0x7;  sr >>= 3;
			LARc[7] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 4;
			Nc[0] = sr & 0x7f;  sr >>= 7;
			bc[0] = sr & 0x3;  sr >>= 2;
			Mc[0] = sr & 0x3;  sr >>= 2;
			sr |= (uword)*c++ << 1;
			xmaxc[0] = sr & 0x3f;  sr >>= 6;
			xmc[0] = sr & 0x7;  sr >>= 3;
			sr = *c++;
			xmc[1] = sr & 0x7;  sr >>= 3;
			xmc[2] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 2;
			xmc[3] = sr & 0x7;  sr >>= 3;
			xmc[4] = sr & 0x7;  sr >>= 3;
			xmc[5] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 1;			/* 10 */
			xmc[6] = sr & 0x7;  sr >>= 3;
			xmc[7] = sr & 0x7;  sr >>= 3;
			xmc[8] = sr & 0x7;  sr >>= 3;
			sr = *c++;
			xmc[9] = sr & 0x7;  sr >>= 3;
			xmc[10] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 2;
			xmc[11] = sr & 0x7;  sr >>= 3;
			xmc[12] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 4;
			Nc[1] = sr & 0x7f;  sr >>= 7;
			bc[1] = sr & 0x3;  sr >>= 2;
			Mc[1] = sr & 0x3;  sr >>= 2;
			sr |= (uword)*c++ << 1;
			xmaxc[1] = sr & 0x3f;  sr >>= 6;
			xmc[13] = sr & 0x7;  sr >>= 3;
			sr = *c++;				/* 15 */
			xmc[14] = sr & 0x7;  sr >>= 3;
			xmc[15] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 2;
			xmc[16] = sr & 0x7;  sr >>= 3;
			xmc[17] = sr & 0x7;  sr >>= 3;
			xmc[18] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 1;
			xmc[19] = sr & 0x7;  sr >>= 3;
			xmc[20] = sr & 0x7;  sr >>= 3;
			xmc[21] = sr & 0x7;  sr >>= 3;
			sr = *c++;
			xmc[22] = sr & 0x7;  sr >>= 3;
			xmc[23] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 2;
			xmc[24] = sr & 0x7;  sr >>= 3;
			xmc[25] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 4;			/* 20 */
			Nc[2] = sr & 0x7f;  sr >>= 7;
			bc[2] = sr & 0x3;  sr >>= 2;
			Mc[2] = sr & 0x3;  sr >>= 2;
			sr |= (uword)*c++ << 1;
			xmaxc[2] = sr & 0x3f;  sr >>= 6;
			xmc[26] = sr & 0x7;  sr >>= 3;
			sr = *c++;
			xmc[27] = sr & 0x7;  sr >>= 3;
			xmc[28] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 2;
			xmc[29] = sr & 0x7;  sr >>= 3;
			xmc[30] = sr & 0x7;  sr >>= 3;
			xmc[31] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 1;
			xmc[32] = sr & 0x7;  sr >>= 3;
			xmc[33] = sr & 0x7;  sr >>= 3;
			xmc[34] = sr & 0x7;  sr >>= 3;
			sr = *c++;				/* 25 */
			xmc[35] = sr & 0x7;  sr >>= 3;
			xmc[36] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 2;
			xmc[37] = sr & 0x7;  sr >>= 3;
			xmc[38] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 4;
			Nc[3] = sr & 0x7f;  sr >>= 7;
			bc[3] = sr & 0x3;  sr >>= 2;
			Mc[3] = sr & 0x3;  sr >>= 2;
			sr |= (uword)*c++ << 1;
			xmaxc[3] = sr & 0x3f;  sr >>= 6;
			xmc[39] = sr & 0x7;  sr >>= 3;
			sr = *c++;
			xmc[40] = sr & 0x7;  sr >>= 3;
			xmc[41] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 2;			/* 30 */
			xmc[42] = sr & 0x7;  sr >>= 3;
			xmc[43] = sr & 0x7;  sr >>= 3;
			xmc[44] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 1;
			xmc[45] = sr & 0x7;  sr >>= 3;
			xmc[46] = sr & 0x7;  sr >>= 3;
			xmc[47] = sr & 0x7;  sr >>= 3;
			sr = *c++;
			xmc[48] = sr & 0x7;  sr >>= 3;
			xmc[49] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 2;
			xmc[50] = sr & 0x7;  sr >>= 3;
			xmc[51] = sr & 0x7;  sr >>= 3;

			s->frame_chain = sr & 0xf;
		}
		else {
			sr = s->frame_chain;
			sr |= (uword)*c++ << 4;			/* 1 */
			LARc[0] = sr & 0x3f;  sr >>= 6;
			LARc[1] = sr & 0x3f;  sr >>= 6;
			sr = *c++;
			LARc[2] = sr & 0x1f;  sr >>= 5;
			sr |= (uword)*c++ << 3;
			LARc[3] = sr & 0x1f;  sr >>= 5;
			LARc[4] = sr & 0xf;  sr >>= 4;
			sr |= (uword)*c++ << 2;
			LARc[5] = sr & 0xf;  sr >>= 4;
			LARc[6] = sr & 0x7;  sr >>= 3;
			LARc[7] = sr & 0x7;  sr >>= 3;
			sr = *c++;				/* 5 */
			Nc[0] = sr & 0x7f;  sr >>= 7;
			sr |= (uword)*c++ << 1;
			bc[0] = sr & 0x3;  sr >>= 2;
			Mc[0] = sr & 0x3;  sr >>= 2;
			sr |= (uword)*c++ << 5;
			xmaxc[0] = sr & 0x3f;  sr >>= 6;
			xmc[0] = sr & 0x7;  sr >>= 3;
			xmc[1] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 1;
			xmc[2] = sr & 0x7;  sr >>= 3;
			xmc[3] = sr & 0x7;  sr >>= 3;
			xmc[4] = sr & 0x7;  sr >>= 3;
			sr = *c++;
			xmc[5] = sr & 0x7;  sr >>= 3;
			xmc[6] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 2;			/* 10 */
			xmc[7] = sr & 0x7;  sr >>= 3;
			xmc[8] = sr & 0x7;  sr >>= 3;
			xmc[9] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 1;
			xmc[10] = sr & 0x7;  sr >>= 3;
			xmc[11] = sr & 0x7;  sr >>= 3;
			xmc[12] = sr & 0x7;  sr >>= 3;
			sr = *c++;
			Nc[1] = sr & 0x7f;  sr >>= 7;
			sr |= (uword)*c++ << 1;
			bc[1] = sr & 0x3;  sr >>= 2;
			Mc[1] = sr & 0x3;  sr >>= 2;
			sr |= (uword)*c++ << 5;
			xmaxc[1] = sr & 0x3f;  sr >>= 6;
			xmc[13] = sr & 0x7;  sr >>= 3;
			xmc[14] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 1;			/* 15 */
			xmc[15] = sr & 0x7;  sr >>= 3;
			xmc[16] = sr & 0x7;  sr >>= 3;
			xmc[17] = sr & 0x7;  sr >>= 3;
			sr = *c++;
			xmc[18] = sr & 0x7;  sr >>= 3;
			xmc[19] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 2;
			xmc[20] = sr & 0x7;  sr >>= 3;
			xmc[21] = sr & 0x7;  sr >>= 3;
			xmc[22] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 1;
			xmc[23] = sr & 0x7;  sr >>= 3;
			xmc[24] = sr & 0x7;  sr >>= 3;
			xmc[25] = sr & 0x7;  sr >>= 3;
			sr = *c++;
			Nc[2] = sr & 0x7f;  sr >>= 7;
			sr |= (uword)*c++ << 1;			/* 20 */
			bc[2] = sr & 0x3;  sr >>= 2;
			Mc[2] = sr & 0x3;  sr >>= 2;
			sr |= (uword)*c++ << 5;
			xmaxc[2] = sr & 0x3f;  sr >>= 6;
			xmc[26] = sr & 0x7;  sr >>= 3;
			xmc[27] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 1;	
			xmc[28] = sr & 0x7;  sr >>= 3;
			xmc[29] = sr & 0x7;  sr >>= 3;
			xmc[30] = sr & 0x7;  sr >>= 3;
			sr = *c++;
			xmc[31] = sr & 0x7;  sr >>= 3;
			xmc[32] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 2;
			xmc[33] = sr & 0x7;  sr >>= 3;
			xmc[34] = sr & 0x7;  sr >>= 3;
			xmc[35] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 1;			/* 25 */
			xmc[36] = sr & 0x7;  sr >>= 3;
			xmc[37] = sr & 0x7;  sr >>= 3;
			xmc[38] = sr & 0x7;  sr >>= 3;
			sr = *c++;
			Nc[3] = sr & 0x7f;  sr >>= 7;
			sr |= (uword)*c++ << 1;		
			bc[3] = sr & 0x3;  sr >>= 2;
			Mc[3] = sr & 0x3;  sr >>= 2;
			sr |= (uword)*c++ << 5;
			xmaxc[3] = sr & 0x3f;  sr >>= 6;
			xmc[39] = sr & 0x7;  sr >>= 3;
			xmc[40] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 1;
			xmc[41] = sr & 0x7;  sr >>= 3;
			xmc[42] = sr & 0x7;  sr >>= 3;
			xmc[43] = sr & 0x7;  sr >>= 3;
			sr = *c++;				/* 30 */
			xmc[44] = sr & 0x7;  sr >>= 3;
			xmc[45] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 2;
			xmc[46] = sr & 0x7;  sr >>= 3;
			xmc[47] = sr & 0x7;  sr >>= 3;
			xmc[48] = sr & 0x7;  sr >>= 3;
			sr |= (uword)*c++ << 1;
			xmc[49] = sr & 0x7;  sr >>= 3;
			xmc[50] = sr & 0x7;  sr >>= 3;
			xmc[51] = sr & 0x7;  sr >>= 3;
		}
	}
	else
#endif
	{
		/* GSM_MAGIC  = (*c >> 4) & 0xF; */

		if (((*c >> 4) & 0x0F) != GSM_MAGIC) return -1;

		LARc[0]  = (*c++ & 0xF) << 2;		/* 1 */
		LARc[0] |= (*c >> 6) & 0x3;
		LARc[1]  = *c++ & 0x3F;
		LARc[2]  = (*c >> 3) & 0x1F;
		LARc[3]  = (*c++ & 0x7) << 2;
		LARc[3] |= (*c >> 6) & 0x3;
		LARc[4]  = (*c >> 2) & 0xF;
		LARc[5]  = (*c++ & 0x3) << 2;
		LARc[5] |= (*c >> 6) & 0x3;
		LARc[6]  = (*c >> 3) & 0x7;
		LARc[7]  = *c++ & 0x7;
		Nc[0]  = (*c >> 1) & 0x7F;
		bc[0]  = (*c++ & 0x1) << 1;
		bc[0] |= (*c >> 7) & 0x1;
		Mc[0]  = (*c >> 5) & 0x3;
		xmaxc[0]  = (*c++ & 0x1F) << 1;
		xmaxc[0] |= (*c >> 7) & 0x1;
		xmc[0]  = (*c >> 4) & 0x7;
		xmc[1]  = (*c >> 1) & 0x7;
		xmc[2]  = (*c++ & 0x1) << 2;
		xmc[2] |= (*c >> 6) & 0x3;
		xmc[3]  = (*c >> 3) & 0x7;
		xmc[4]  = *c++ & 0x7;
		xmc[5]  = (*c >> 5) & 0x7;
		xmc[6]  = (*c >> 2) & 0x7;
		xmc[7]  = (*c++ & 0x3) << 1;		/* 10 */
		xmc[7] |= (*c >> 7) & 0x1;
		xmc[8]  = (*c >> 4) & 0x7;
		xmc[9]  = (*c >> 1) & 0x7;
		xmc[10]  = (*c++ & 0x1) << 2;
		xmc[10] |= (*c >> 6) & 0x3;
		xmc[11]  = (*c >> 3) & 0x7;
		xmc[12]  = *c++ & 0x7;
		Nc[1]  = (*c >> 1) & 0x7F;
		bc[1]  = (*c++ & 0x1) << 1;
		bc[1] |= (*c >> 7) & 0x1;
		Mc[1]  = (*c >> 5) & 0x3;
		xmaxc[1]  = (*c++ & 0x1F) << 1;
		xmaxc[1] |= (*c >> 7) & 0x1;
		xmc[13]  = (*c >> 4) & 0x7;
		xmc[14]  = (*c >> 1) & 0x7;
		xmc[15]  = (*c++ & 0x1) << 2;
		xmc[15] |= (*c >> 6) & 0x3;
		xmc[16]  = (*c >> 3) & 0x7;
		xmc[17]  = *c++ & 0x7;
		xmc[18]  = (*c >> 5) & 0x7;
		xmc[19]  = (*c >> 2) & 0x7;
		xmc[20]  = (*c++ & 0x3) << 1;
		xmc[20] |= (*c >> 7) & 0x1;
		xmc[21]  = (*c >> 4) & 0x7;
		xmc[22]  = (*c >> 1) & 0x7;
		xmc[23]  = (*c++ & 0x1) << 2;
		xmc[23] |= (*c >> 6) & 0x3;
		xmc[24]  = (*c >> 3) & 0x7;
		xmc[25]  = *c++ & 0x7;
		Nc[2]  = (*c >> 1) & 0x7F;
		bc[2]  = (*c++ & 0x1) << 1;		/* 20 */
		bc[2] |= (*c >> 7) & 0x1;
		Mc[2]  = (*c >> 5) & 0x3;
		xmaxc[2]  = (*c++ & 0x1F) << 1;
		xmaxc[2] |= (*c >> 7) & 0x1;
		xmc[26]  = (*c >> 4) & 0x7;
		xmc[27]  = (*c >> 1) & 0x7;
		xmc[28]  = (*c++ & 0x1) << 2;
		xmc[28] |= (*c >> 6) & 0x3;
		xmc[29]  = (*c >> 3) & 0x7;
		xmc[30]  = *c++ & 0x7;
		xmc[31]  = (*c >> 5) & 0x7;
		xmc[32]  = (*c >> 2) & 0x7;
		xmc[33]  = (*c++ & 0x3) << 1;
		xmc[33] |= (*c >> 7) & 0x1;
		xmc[34]  = (*c >> 4) & 0x7;
		xmc[35]  = (*c >> 1) & 0x7;
		xmc[36]  = (*c++ & 0x1) << 2;
		xmc[36] |= (*c >> 6) & 0x3;
		xmc[37]  = (*c >> 3) & 0x7;
		xmc[38]  = *c++ & 0x7;
		Nc[3]  = (*c >> 1) & 0x7F;
		bc[3]  = (*c++ & 0x1) << 1;
		bc[3] |= (*c >> 7) & 0x1;
		Mc[3]  = (*c >> 5) & 0x3;
		xmaxc[3]  = (*c++ & 0x1F) << 1;
		xmaxc[3] |= (*c >> 7) & 0x1;
		xmc[39]  = (*c >> 4) & 0x7;
		xmc[40]  = (*c >> 1) & 0x7;
		xmc[41]  = (*c++ & 0x1) << 2;
		xmc[41] |= (*c >> 6) & 0x3;
		xmc[42]  = (*c >> 3) & 0x7;
		xmc[43]  = *c++ & 0x7;			/* 30  */
		xmc[44]  = (*c >> 5) & 0x7;
		xmc[45]  = (*c >> 2) & 0x7;
		xmc[46]  = (*c++ & 0x3) << 1;
		xmc[46] |= (*c >> 7) & 0x1;
		xmc[47]  = (*c >> 4) & 0x7;
		xmc[48]  = (*c >> 1) & 0x7;
		xmc[49]  = (*c++ & 0x1) << 2;
		xmc[49] |= (*c >> 6) & 0x3;
		xmc[50]  = (*c >> 3) & 0x7;
		xmc[51]  = *c & 0x7;			/* 33 */
	}

	Gsm_Decoder(s, LARc, Nc, bc, Mc, xmaxc, xmc, target);

	return 0;
}

/****** begin "gsm_encode.c" *****/

void gsm_encode P3((s, source, c), gsm s, gsm_signal * source, gsm_byte * c)
{
	word	 	LARc[8], Nc[4], Mc[4], bc[4], xmaxc[4], xmc[13*4];

	Gsm_Coder(s, source, LARc, Nc, bc, Mc, xmaxc, xmc);


	/*	variable	size

		GSM_MAGIC	4

		LARc[0]		6
		LARc[1]		6
		LARc[2]		5
		LARc[3]		5
		LARc[4]		4
		LARc[5]		4
		LARc[6]		3
		LARc[7]		3

		Nc[0]		7
		bc[0]		2
		Mc[0]		2
		xmaxc[0]	6
		xmc[0]		3
		xmc[1]		3
		xmc[2]		3
		xmc[3]		3
		xmc[4]		3
		xmc[5]		3
		xmc[6]		3
		xmc[7]		3
		xmc[8]		3
		xmc[9]		3
		xmc[10]		3
		xmc[11]		3
		xmc[12]		3

		Nc[1]		7
		bc[1]		2
		Mc[1]		2
		xmaxc[1]	6
		xmc[13]		3
		xmc[14]		3
		xmc[15]		3
		xmc[16]		3
		xmc[17]		3
		xmc[18]		3
		xmc[19]		3
		xmc[20]		3
		xmc[21]		3
		xmc[22]		3
		xmc[23]		3
		xmc[24]		3
		xmc[25]		3

		Nc[2]		7
		bc[2]		2
		Mc[2]		2
		xmaxc[2]	6
		xmc[26]		3
		xmc[27]		3
		xmc[28]		3
		xmc[29]		3
		xmc[30]		3
		xmc[31]		3
		xmc[32]		3
		xmc[33]		3
		xmc[34]		3
		xmc[35]		3
		xmc[36]		3
		xmc[37]		3
		xmc[38]		3

		Nc[3]		7
		bc[3]		2
		Mc[3]		2
		xmaxc[3]	6
		xmc[39]		3
		xmc[40]		3
		xmc[41]		3
		xmc[42]		3
		xmc[43]		3
		xmc[44]		3
		xmc[45]		3
		xmc[46]		3
		xmc[47]		3
		xmc[48]		3
		xmc[49]		3
		xmc[50]		3
		xmc[51]		3
	*/

#ifdef WAV49

	if (s->wav_fmt) {
		s->frame_index = !s->frame_index;
		if (s->frame_index) {

			uword sr;

			sr = 0;
			sr = sr >> 6 | LARc[0] << 10;
			sr = sr >> 6 | LARc[1] << 10;
			*c++ = sr >> 4;
			sr = sr >> 5 | LARc[2] << 11;
			*c++ = sr >> 7;
			sr = sr >> 5 | LARc[3] << 11;
			sr = sr >> 4 | LARc[4] << 12;
			*c++ = sr >> 6;
			sr = sr >> 4 | LARc[5] << 12;
			sr = sr >> 3 | LARc[6] << 13;
			*c++ = sr >> 7;
			sr = sr >> 3 | LARc[7] << 13;
			sr = sr >> 7 | Nc[0] << 9;
			*c++ = sr >> 5;
			sr = sr >> 2 | bc[0] << 14;
			sr = sr >> 2 | Mc[0] << 14;
			sr = sr >> 6 | xmaxc[0] << 10;
			*c++ = sr >> 3;
			sr = sr >> 3 | xmc[0] << 13;
			*c++ = sr >> 8;
			sr = sr >> 3 | xmc[1] << 13;
			sr = sr >> 3 | xmc[2] << 13;
			sr = sr >> 3 | xmc[3] << 13;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[4] << 13;
			sr = sr >> 3 | xmc[5] << 13;
			sr = sr >> 3 | xmc[6] << 13;
			*c++ = sr >> 6;
			sr = sr >> 3 | xmc[7] << 13;
			sr = sr >> 3 | xmc[8] << 13;
			*c++ = sr >> 8;
			sr = sr >> 3 | xmc[9] << 13;
			sr = sr >> 3 | xmc[10] << 13;
			sr = sr >> 3 | xmc[11] << 13;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[12] << 13;
			sr = sr >> 7 | Nc[1] << 9;
			*c++ = sr >> 5;
			sr = sr >> 2 | bc[1] << 14;
			sr = sr >> 2 | Mc[1] << 14;
			sr = sr >> 6 | xmaxc[1] << 10;
			*c++ = sr >> 3;
			sr = sr >> 3 | xmc[13] << 13;
			*c++ = sr >> 8;
			sr = sr >> 3 | xmc[14] << 13;
			sr = sr >> 3 | xmc[15] << 13;
			sr = sr >> 3 | xmc[16] << 13;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[17] << 13;
			sr = sr >> 3 | xmc[18] << 13;
			sr = sr >> 3 | xmc[19] << 13;
			*c++ = sr >> 6;
			sr = sr >> 3 | xmc[20] << 13;
			sr = sr >> 3 | xmc[21] << 13;
			*c++ = sr >> 8;
			sr = sr >> 3 | xmc[22] << 13;
			sr = sr >> 3 | xmc[23] << 13;
			sr = sr >> 3 | xmc[24] << 13;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[25] << 13;
			sr = sr >> 7 | Nc[2] << 9;
			*c++ = sr >> 5;
			sr = sr >> 2 | bc[2] << 14;
			sr = sr >> 2 | Mc[2] << 14;
			sr = sr >> 6 | xmaxc[2] << 10;
			*c++ = sr >> 3;
			sr = sr >> 3 | xmc[26] << 13;
			*c++ = sr >> 8;
			sr = sr >> 3 | xmc[27] << 13;
			sr = sr >> 3 | xmc[28] << 13;
			sr = sr >> 3 | xmc[29] << 13;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[30] << 13;
			sr = sr >> 3 | xmc[31] << 13;
			sr = sr >> 3 | xmc[32] << 13;
			*c++ = sr >> 6;
			sr = sr >> 3 | xmc[33] << 13;
			sr = sr >> 3 | xmc[34] << 13;
			*c++ = sr >> 8;
			sr = sr >> 3 | xmc[35] << 13;
			sr = sr >> 3 | xmc[36] << 13;
			sr = sr >> 3 | xmc[37] << 13;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[38] << 13;
			sr = sr >> 7 | Nc[3] << 9;
			*c++ = sr >> 5;
			sr = sr >> 2 | bc[3] << 14;
			sr = sr >> 2 | Mc[3] << 14;
			sr = sr >> 6 | xmaxc[3] << 10;
			*c++ = sr >> 3;
			sr = sr >> 3 | xmc[39] << 13;
			*c++ = sr >> 8;
			sr = sr >> 3 | xmc[40] << 13;
			sr = sr >> 3 | xmc[41] << 13;
			sr = sr >> 3 | xmc[42] << 13;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[43] << 13;
			sr = sr >> 3 | xmc[44] << 13;
			sr = sr >> 3 | xmc[45] << 13;
			*c++ = sr >> 6;
			sr = sr >> 3 | xmc[46] << 13;
			sr = sr >> 3 | xmc[47] << 13;
			*c++ = sr >> 8;
			sr = sr >> 3 | xmc[48] << 13;
			sr = sr >> 3 | xmc[49] << 13;
			sr = sr >> 3 | xmc[50] << 13;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[51] << 13;
			sr = sr >> 4;
			*c = sr >> 8;
			s->frame_chain = *c;
		}
		else {
			uword sr;

			sr = 0;
			sr = sr >> 4 | s->frame_chain << 12;
			sr = sr >> 6 | LARc[0] << 10;
			*c++ = sr >> 6;
			sr = sr >> 6 | LARc[1] << 10;
			*c++ = sr >> 8;
			sr = sr >> 5 | LARc[2] << 11;
			sr = sr >> 5 | LARc[3] << 11;
			*c++ = sr >> 6;
			sr = sr >> 4 | LARc[4] << 12;
			sr = sr >> 4 | LARc[5] << 12;
			*c++ = sr >> 6;
			sr = sr >> 3 | LARc[6] << 13;
			sr = sr >> 3 | LARc[7] << 13;
			*c++ = sr >> 8;
			sr = sr >> 7 | Nc[0] << 9;
			sr = sr >> 2 | bc[0] << 14;
			*c++ = sr >> 7;
			sr = sr >> 2 | Mc[0] << 14;
			sr = sr >> 6 | xmaxc[0] << 10;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[0] << 13;
			sr = sr >> 3 | xmc[1] << 13;
			sr = sr >> 3 | xmc[2] << 13;
			*c++ = sr >> 6;
			sr = sr >> 3 | xmc[3] << 13;
			sr = sr >> 3 | xmc[4] << 13;
			*c++ = sr >> 8;
			sr = sr >> 3 | xmc[5] << 13;
			sr = sr >> 3 | xmc[6] << 13;
			sr = sr >> 3 | xmc[7] << 13;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[8] << 13;
			sr = sr >> 3 | xmc[9] << 13;
			sr = sr >> 3 | xmc[10] << 13;
			*c++ = sr >> 6;
			sr = sr >> 3 | xmc[11] << 13;
			sr = sr >> 3 | xmc[12] << 13;
			*c++ = sr >> 8;
			sr = sr >> 7 | Nc[1] << 9;
			sr = sr >> 2 | bc[1] << 14;
			*c++ = sr >> 7;
			sr = sr >> 2 | Mc[1] << 14;
			sr = sr >> 6 | xmaxc[1] << 10;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[13] << 13;
			sr = sr >> 3 | xmc[14] << 13;
			sr = sr >> 3 | xmc[15] << 13;
			*c++ = sr >> 6;
			sr = sr >> 3 | xmc[16] << 13;
			sr = sr >> 3 | xmc[17] << 13;
			*c++ = sr >> 8;
			sr = sr >> 3 | xmc[18] << 13;
			sr = sr >> 3 | xmc[19] << 13;
			sr = sr >> 3 | xmc[20] << 13;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[21] << 13;
			sr = sr >> 3 | xmc[22] << 13;
			sr = sr >> 3 | xmc[23] << 13;
			*c++ = sr >> 6;
			sr = sr >> 3 | xmc[24] << 13;
			sr = sr >> 3 | xmc[25] << 13;
			*c++ = sr >> 8;
			sr = sr >> 7 | Nc[2] << 9;
			sr = sr >> 2 | bc[2] << 14;
			*c++ = sr >> 7;
			sr = sr >> 2 | Mc[2] << 14;
			sr = sr >> 6 | xmaxc[2] << 10;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[26] << 13;
			sr = sr >> 3 | xmc[27] << 13;
			sr = sr >> 3 | xmc[28] << 13;
			*c++ = sr >> 6;
			sr = sr >> 3 | xmc[29] << 13;
			sr = sr >> 3 | xmc[30] << 13;
			*c++ = sr >> 8;
			sr = sr >> 3 | xmc[31] << 13;
			sr = sr >> 3 | xmc[32] << 13;
			sr = sr >> 3 | xmc[33] << 13;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[34] << 13;
			sr = sr >> 3 | xmc[35] << 13;
			sr = sr >> 3 | xmc[36] << 13;
			*c++ = sr >> 6;
			sr = sr >> 3 | xmc[37] << 13;
			sr = sr >> 3 | xmc[38] << 13;
			*c++ = sr >> 8;
			sr = sr >> 7 | Nc[3] << 9;
			sr = sr >> 2 | bc[3] << 14;
			*c++ = sr >> 7;
			sr = sr >> 2 | Mc[3] << 14;
			sr = sr >> 6 | xmaxc[3] << 10;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[39] << 13;
			sr = sr >> 3 | xmc[40] << 13;
			sr = sr >> 3 | xmc[41] << 13;
			*c++ = sr >> 6;
			sr = sr >> 3 | xmc[42] << 13;
			sr = sr >> 3 | xmc[43] << 13;
			*c++ = sr >> 8;
			sr = sr >> 3 | xmc[44] << 13;
			sr = sr >> 3 | xmc[45] << 13;
			sr = sr >> 3 | xmc[46] << 13;
			*c++ = sr >> 7;
			sr = sr >> 3 | xmc[47] << 13;
			sr = sr >> 3 | xmc[48] << 13;
			sr = sr >> 3 | xmc[49] << 13;
			*c++ = sr >> 6;
			sr = sr >> 3 | xmc[50] << 13;
			sr = sr >> 3 | xmc[51] << 13;
			*c++ = sr >> 8;
		}
	}

	else

#endif	/* WAV49 */
	{

		*c++ =   ((GSM_MAGIC & 0xF) << 4)		/* 1 */
		       | ((LARc[0] >> 2) & 0xF);
		*c++ =   ((LARc[0] & 0x3) << 6)
		       | (LARc[1] & 0x3F);
		*c++ =   ((LARc[2] & 0x1F) << 3)
		       | ((LARc[3] >> 2) & 0x7);
		*c++ =   ((LARc[3] & 0x3) << 6)
		       | ((LARc[4] & 0xF) << 2)
		       | ((LARc[5] >> 2) & 0x3);
		*c++ =   ((LARc[5] & 0x3) << 6)
		       | ((LARc[6] & 0x7) << 3)
		       | (LARc[7] & 0x7);
		*c++ =   ((Nc[0] & 0x7F) << 1)
		       | ((bc[0] >> 1) & 0x1);
		*c++ =   ((bc[0] & 0x1) << 7)
		       | ((Mc[0] & 0x3) << 5)
		       | ((xmaxc[0] >> 1) & 0x1F);
		*c++ =   ((xmaxc[0] & 0x1) << 7)
		       | ((xmc[0] & 0x7) << 4)
		       | ((xmc[1] & 0x7) << 1)
		       | ((xmc[2] >> 2) & 0x1);
		*c++ =   ((xmc[2] & 0x3) << 6)
		       | ((xmc[3] & 0x7) << 3)
		       | (xmc[4] & 0x7);
		*c++ =   ((xmc[5] & 0x7) << 5)			/* 10 */
		       | ((xmc[6] & 0x7) << 2)
		       | ((xmc[7] >> 1) & 0x3);
		*c++ =   ((xmc[7] & 0x1) << 7)
		       | ((xmc[8] & 0x7) << 4)
		       | ((xmc[9] & 0x7) << 1)
		       | ((xmc[10] >> 2) & 0x1);
		*c++ =   ((xmc[10] & 0x3) << 6)
		       | ((xmc[11] & 0x7) << 3)
		       | (xmc[12] & 0x7);
		*c++ =   ((Nc[1] & 0x7F) << 1)
		       | ((bc[1] >> 1) & 0x1);
		*c++ =   ((bc[1] & 0x1) << 7)
		       | ((Mc[1] & 0x3) << 5)
		       | ((xmaxc[1] >> 1) & 0x1F);
		*c++ =   ((xmaxc[1] & 0x1) << 7)
		       | ((xmc[13] & 0x7) << 4)
		       | ((xmc[14] & 0x7) << 1)
		       | ((xmc[15] >> 2) & 0x1);
		*c++ =   ((xmc[15] & 0x3) << 6)
		       | ((xmc[16] & 0x7) << 3)
		       | (xmc[17] & 0x7);
		*c++ =   ((xmc[18] & 0x7) << 5)
		       | ((xmc[19] & 0x7) << 2)
		       | ((xmc[20] >> 1) & 0x3);
		*c++ =   ((xmc[20] & 0x1) << 7)
		       | ((xmc[21] & 0x7) << 4)
		       | ((xmc[22] & 0x7) << 1)
		       | ((xmc[23] >> 2) & 0x1);
		*c++ =   ((xmc[23] & 0x3) << 6)
		       | ((xmc[24] & 0x7) << 3)
		       | (xmc[25] & 0x7);
		*c++ =   ((Nc[2] & 0x7F) << 1)			/* 20 */
		       | ((bc[2] >> 1) & 0x1);
		*c++ =   ((bc[2] & 0x1) << 7)
		       | ((Mc[2] & 0x3) << 5)
		       | ((xmaxc[2] >> 1) & 0x1F);
		*c++ =   ((xmaxc[2] & 0x1) << 7)
		       | ((xmc[26] & 0x7) << 4)
		       | ((xmc[27] & 0x7) << 1)
		       | ((xmc[28] >> 2) & 0x1);
		*c++ =   ((xmc[28] & 0x3) << 6)
		       | ((xmc[29] & 0x7) << 3)
		       | (xmc[30] & 0x7);
		*c++ =   ((xmc[31] & 0x7) << 5)
		       | ((xmc[32] & 0x7) << 2)
		       | ((xmc[33] >> 1) & 0x3);
		*c++ =   ((xmc[33] & 0x1) << 7)
		       | ((xmc[34] & 0x7) << 4)
		       | ((xmc[35] & 0x7) << 1)
		       | ((xmc[36] >> 2) & 0x1);
		*c++ =   ((xmc[36] & 0x3) << 6)
		       | ((xmc[37] & 0x7) << 3)
		       | (xmc[38] & 0x7);
		*c++ =   ((Nc[3] & 0x7F) << 1)
		       | ((bc[3] >> 1) & 0x1);
		*c++ =   ((bc[3] & 0x1) << 7)
		       | ((Mc[3] & 0x3) << 5)
		       | ((xmaxc[3] >> 1) & 0x1F);
		*c++ =   ((xmaxc[3] & 0x1) << 7)
		       | ((xmc[39] & 0x7) << 4)
		       | ((xmc[40] & 0x7) << 1)
		       | ((xmc[41] >> 2) & 0x1);
		*c++ =   ((xmc[41] & 0x3) << 6)			/* 30 */
		       | ((xmc[42] & 0x7) << 3)
		       | (xmc[43] & 0x7);
		*c++ =   ((xmc[44] & 0x7) << 5)
		       | ((xmc[45] & 0x7) << 2)
		       | ((xmc[46] >> 1) & 0x3);
		*c++ =   ((xmc[46] & 0x1) << 7)
		       | ((xmc[47] & 0x7) << 4)
		       | ((xmc[48] & 0x7) << 1)
		       | ((xmc[49] >> 2) & 0x1);
		*c++ =   ((xmc[49] & 0x3) << 6)
		       | ((xmc[50] & 0x7) << 3)
		       | (xmc[51] & 0x7);

	}
}

/****** begin "long_term.c" *****/

/*
 *  4.2.11 .. 4.2.12 LONG TERM PREDICTOR (LTP) SECTION
 */


/*
 * This module computes the LTP gain (bc) and the LTP lag (Nc)
 * for the long term analysis filter.   This is done by calculating a
 * maximum of the cross-correlation function between the current
 * sub-segment short term residual signal d[0..39] (output of
 * the short term analysis filter; for simplification the index
 * of this array begins at 0 and ends at 39 for each sub-segment of the
 * RPE-LTP analysis) and the previous reconstructed short term
 * residual signal dp[ -120 .. -1 ].  A dynamic scaling must be
 * performed to avoid overflow.
 */

 /* The next procedure exists in six versions.  First two integer
  * version (if USE_FLOAT_MUL is not defined); then four floating
  * point versions, twice with proper scaling (USE_FLOAT_MUL defined),
  * once without (USE_FLOAT_MUL and FAST defined, and fast run-time
  * option used).  Every pair has first a Cut version (see the -C
  * option to toast or the LTP_CUT option to gsm_option()), then the
  * uncut one.  (For a detailed explanation of why this is altogether
  * a bad idea, see Henry Spencer and Geoff Collyer, ``#ifdef Considered
  * Harmful''.)
  */

#ifndef  USE_FLOAT_MUL

#ifdef	LTP_CUT

static void Cut_Calculation_of_the_LTP_parameters P5((st, d,dp,bc_out,Nc_out),

	struct gsm_state * st,

	register word	* d,		/* [0..39]	IN	*/
	register word	* dp,		/* [-120..-1]	IN	*/
	word		* bc_out,	/* 		OUT	*/
	word		* Nc_out	/* 		OUT	*/
)
{
	register int  	k, lambda;
	word		Nc, bc;
	word		wt[40];

	longword	L_result;
	longword	L_max, L_power;
	word		R, S, dmax, scal, best_k;
	word		ltp_cut;

	register word	temp, wt_k;

	/*  Search of the optimum scaling of d[0..39].
	 */
	dmax = 0;
	for (k = 0; k <= 39; k++) {
		temp = d[k];
		temp = GSM_ABS( temp );
		if (temp > dmax) {
			dmax = temp;
			best_k = k;
		}
	}
	temp = 0;
	if (dmax == 0) scal = 0;
	else {
		assert(dmax > 0);
		temp = gsm_norm( (longword)dmax << 16 );
	}
	if (temp > 6) scal = 0;
	else scal = 6 - temp;
	assert(scal >= 0);

	/* Search for the maximum cross-correlation and coding of the LTP lag
	 */
	L_max = 0;
	Nc    = 40;	/* index for the maximum cross-correlation */
	wt_k  = SASR(d[best_k], scal);

	for (lambda = 40; lambda <= 120; lambda++) {
		L_result = (longword)wt_k * dp[best_k - lambda];
		if (L_result > L_max) {
			Nc    = lambda;
			L_max = L_result;
		}
	}
	*Nc_out = Nc;
	L_max <<= 1;

	/*  Rescaling of L_max
	 */
	assert(scal <= 100 && scal >= -100);
	L_max = L_max >> (6 - scal);	/* sub(6, scal) */

	assert( Nc <= 120 && Nc >= 40);

	/*   Compute the power of the reconstructed short term residual
	 *   signal dp[..]
	 */
	L_power = 0;
	for (k = 0; k <= 39; k++) {

		register longword L_temp;

		L_temp   = SASR( dp[k - Nc], 3 );
		L_power += L_temp * L_temp;
	}
	L_power <<= 1;	/* from L_MULT */

	/*  Normalization of L_max and L_power
	 */

	if (L_max <= 0)  {
		*bc_out = 0;
		return;
	}
	if (L_max >= L_power) {
		*bc_out = 3;
		return;
	}

	temp = gsm_norm( L_power );

	R = SASR( L_max   << temp, 16 );
	S = SASR( L_power << temp, 16 );

	/*  Coding of the LTP gain
	 */

	/*  Table 4.3a must be used to obtain the level DLB[i] for the
	 *  quantization of the LTP gain b to get the coded version bc.
	 */
	for (bc = 0; bc <= 2; bc++) if (R <= gsm_mult(S, gsm_DLB[bc])) break;
	*bc_out = bc;
}

#endif 	/* LTP_CUT */

static void Calculation_of_the_LTP_parameters P4((d,dp,bc_out,Nc_out),
	register word	* d,		/* [0..39]	IN	*/
	register word	* dp,		/* [-120..-1]	IN	*/
	word		* bc_out,	/* 		OUT	*/
	word		* Nc_out	/* 		OUT	*/
)
{
	register int  	k, lambda;
	word		Nc, bc;
	word		wt[40];

	longword	L_max, L_power;
	word		R, S, dmax, scal;
	register word	temp;

	/*  Search of the optimum scaling of d[0..39].
	 */
	dmax = 0;

	for (k = 0; k <= 39; k++) {
		temp = d[k];
		temp = GSM_ABS( temp );
		if (temp > dmax) dmax = temp;
	}

	temp = 0;
	if (dmax == 0) scal = 0;
	else {
		assert(dmax > 0);
		temp = gsm_norm( (longword)dmax << 16 );
	}

	if (temp > 6) scal = 0;
	else scal = 6 - temp;

	assert(scal >= 0);

	/*  Initialization of a working array wt
	 */

	for (k = 0; k <= 39; k++) wt[k] = SASR( d[k], scal );

	/* Search for the maximum cross-correlation and coding of the LTP lag
	 */
	L_max = 0;
	Nc    = 40;	/* index for the maximum cross-correlation */

	for (lambda = 40; lambda <= 120; lambda++) {

# undef STEP
#		define STEP(k) 	(longword)wt[k] * dp[k - lambda]

		register longword L_result;

		L_result  = STEP(0)  ; L_result += STEP(1) ;
		L_result += STEP(2)  ; L_result += STEP(3) ;
		L_result += STEP(4)  ; L_result += STEP(5)  ;
		L_result += STEP(6)  ; L_result += STEP(7)  ;
		L_result += STEP(8)  ; L_result += STEP(9)  ;
		L_result += STEP(10) ; L_result += STEP(11) ;
		L_result += STEP(12) ; L_result += STEP(13) ;
		L_result += STEP(14) ; L_result += STEP(15) ;
		L_result += STEP(16) ; L_result += STEP(17) ;
		L_result += STEP(18) ; L_result += STEP(19) ;
		L_result += STEP(20) ; L_result += STEP(21) ;
		L_result += STEP(22) ; L_result += STEP(23) ;
		L_result += STEP(24) ; L_result += STEP(25) ;
		L_result += STEP(26) ; L_result += STEP(27) ;
		L_result += STEP(28) ; L_result += STEP(29) ;
		L_result += STEP(30) ; L_result += STEP(31) ;
		L_result += STEP(32) ; L_result += STEP(33) ;
		L_result += STEP(34) ; L_result += STEP(35) ;
		L_result += STEP(36) ; L_result += STEP(37) ;
		L_result += STEP(38) ; L_result += STEP(39) ;

		if (L_result > L_max) {

			Nc    = lambda;
			L_max = L_result;
		}
	}

	*Nc_out = Nc;

	L_max <<= 1;

	/*  Rescaling of L_max
	 */
	assert(scal <= 100 && scal >=  -100);
	L_max = L_max >> (6 - scal);	/* sub(6, scal) */

	assert( Nc <= 120 && Nc >= 40);

	/*   Compute the power of the reconstructed short term residual
	 *   signal dp[..]
	 */
	L_power = 0;
	for (k = 0; k <= 39; k++) {

		register longword L_temp;

		L_temp   = SASR( dp[k - Nc], 3 );
		L_power += L_temp * L_temp;
	}
	L_power <<= 1;	/* from L_MULT */

	/*  Normalization of L_max and L_power
	 */

	if (L_max <= 0)  {
		*bc_out = 0;
		return;
	}
	if (L_max >= L_power) {
		*bc_out = 3;
		return;
	}

	temp = gsm_norm( L_power );

	R = SASR( L_max   << temp, 16 );
	S = SASR( L_power << temp, 16 );

	/*  Coding of the LTP gain
	 */

	/*  Table 4.3a must be used to obtain the level DLB[i] for the
	 *  quantization of the LTP gain b to get the coded version bc.
	 */
	for (bc = 0; bc <= 2; bc++) if (R <= gsm_mult(S, gsm_DLB[bc])) break;
	*bc_out = bc;
}

#else	/* USE_FLOAT_MUL */

#ifdef	LTP_CUT

static void Cut_Calculation_of_the_LTP_parameters P5((st, d,dp,bc_out,Nc_out),
	struct gsm_state * st,		/*              IN 	*/
	register word	* d,		/* [0..39]	IN	*/
	register word	* dp,		/* [-120..-1]	IN	*/
	word		* bc_out,	/* 		OUT	*/
	word		* Nc_out	/* 		OUT	*/
)
{
	register int  	k, lambda;
	word		Nc, bc;
	word		ltp_cut;

	float		wt_float[40];
	float		dp_float_base[120], * dp_float = dp_float_base + 120;

	longword	L_max, L_power;
	word		R, S, dmax, scal;
	register word	temp;

	/*  Search of the optimum scaling of d[0..39].
	 */
	dmax = 0;

	for (k = 0; k <= 39; k++) {
		temp = d[k];
		temp = GSM_ABS( temp );
		if (temp > dmax) dmax = temp;
	}

	temp = 0;
	if (dmax == 0) scal = 0;
	else {
		assert(dmax > 0);
		temp = gsm_norm( (longword)dmax << 16 );
	}

	if (temp > 6) scal = 0;
	else scal = 6 - temp;

	assert(scal >= 0);
	ltp_cut = (longword)SASR(dmax, scal) * st->ltp_cut / 100; 


	/*  Initialization of a working array wt
	 */

	for (k = 0; k < 40; k++) {
		register word w = SASR( d[k], scal );
		if (w < 0 ? w > -ltp_cut : w < ltp_cut) {
			wt_float[k] = 0.0;
		}
		else {
			wt_float[k] =  w;
		}
	}
	for (k = -120; k <  0; k++) dp_float[k] =  dp[k];

	/* Search for the maximum cross-correlation and coding of the LTP lag
	 */
	L_max = 0;
	Nc    = 40;	/* index for the maximum cross-correlation */

	for (lambda = 40; lambda <= 120; lambda += 9) {

		/*  Calculate L_result for l = lambda .. lambda + 9.
		 */
		register float *lp = dp_float - lambda;

		register float	W;
		register float	a = lp[-8], b = lp[-7], c = lp[-6],
				d = lp[-5], e = lp[-4], f = lp[-3],
				g = lp[-2], h = lp[-1];
		register float  E; 
		register float  S0 = 0, S1 = 0, S2 = 0, S3 = 0, S4 = 0,
				S5 = 0, S6 = 0, S7 = 0, S8 = 0;

#		undef STEP
#		define	STEP(K, a, b, c, d, e, f, g, h) \
			if ((W = wt_float[K]) != 0.0) {	\
			E = W * a; S8 += E;		\
			E = W * b; S7 += E;		\
			E = W * c; S6 += E;		\
			E = W * d; S5 += E;		\
			E = W * e; S4 += E;		\
			E = W * f; S3 += E;		\
			E = W * g; S2 += E;		\
			E = W * h; S1 += E;		\
			a  = lp[K];			\
			E = W * a; S0 += E; } else (a = lp[K])

#		define	STEP_A(K)	STEP(K, a, b, c, d, e, f, g, h)
#		define	STEP_B(K)	STEP(K, b, c, d, e, f, g, h, a)
#		define	STEP_C(K)	STEP(K, c, d, e, f, g, h, a, b)
#		define	STEP_D(K)	STEP(K, d, e, f, g, h, a, b, c)
#		define	STEP_E(K)	STEP(K, e, f, g, h, a, b, c, d)
#		define	STEP_F(K)	STEP(K, f, g, h, a, b, c, d, e)
#		define	STEP_G(K)	STEP(K, g, h, a, b, c, d, e, f)
#		define	STEP_H(K)	STEP(K, h, a, b, c, d, e, f, g)

		STEP_A( 0); STEP_B( 1); STEP_C( 2); STEP_D( 3);
		STEP_E( 4); STEP_F( 5); STEP_G( 6); STEP_H( 7);

		STEP_A( 8); STEP_B( 9); STEP_C(10); STEP_D(11);
		STEP_E(12); STEP_F(13); STEP_G(14); STEP_H(15);

		STEP_A(16); STEP_B(17); STEP_C(18); STEP_D(19);
		STEP_E(20); STEP_F(21); STEP_G(22); STEP_H(23);

		STEP_A(24); STEP_B(25); STEP_C(26); STEP_D(27);
		STEP_E(28); STEP_F(29); STEP_G(30); STEP_H(31);

		STEP_A(32); STEP_B(33); STEP_C(34); STEP_D(35);
		STEP_E(36); STEP_F(37); STEP_G(38); STEP_H(39);

		if (S0 > L_max) { L_max = S0; Nc = lambda;     }
		if (S1 > L_max) { L_max = S1; Nc = lambda + 1; }
		if (S2 > L_max) { L_max = S2; Nc = lambda + 2; }
		if (S3 > L_max) { L_max = S3; Nc = lambda + 3; }
		if (S4 > L_max) { L_max = S4; Nc = lambda + 4; }
		if (S5 > L_max) { L_max = S5; Nc = lambda + 5; }
		if (S6 > L_max) { L_max = S6; Nc = lambda + 6; }
		if (S7 > L_max) { L_max = S7; Nc = lambda + 7; }
		if (S8 > L_max) { L_max = S8; Nc = lambda + 8; }

	}
	*Nc_out = Nc;

	L_max <<= 1;

	/*  Rescaling of L_max
	 */
	assert(scal <= 100 && scal >=  -100);
	L_max = L_max >> (6 - scal);	/* sub(6, scal) */

	assert( Nc <= 120 && Nc >= 40);

	/*   Compute the power of the reconstructed short term residual
	 *   signal dp[..]
	 */
	L_power = 0;
	for (k = 0; k <= 39; k++) {

		register longword L_temp;

		L_temp   = SASR( dp[k - Nc], 3 );
		L_power += L_temp * L_temp;
	}
	L_power <<= 1;	/* from L_MULT */

	/*  Normalization of L_max and L_power
	 */

	if (L_max <= 0)  {
		*bc_out = 0;
		return;
	}
	if (L_max >= L_power) {
		*bc_out = 3;
		return;
	}

	temp = gsm_norm( L_power );

	R = SASR( L_max   << temp, 16 );
	S = SASR( L_power << temp, 16 );

	/*  Coding of the LTP gain
	 */

	/*  Table 4.3a must be used to obtain the level DLB[i] for the
	 *  quantization of the LTP gain b to get the coded version bc.
	 */
	for (bc = 0; bc <= 2; bc++) if (R <= gsm_mult(S, gsm_DLB[bc])) break;
	*bc_out = bc;
}

#endif /* LTP_CUT */

static void Calculation_of_the_LTP_parameters P4((d,dp,bc_out,Nc_out),
	register word	* d,		/* [0..39]	IN	*/
	register word	* dp,		/* [-120..-1]	IN	*/
	word		* bc_out,	/* 		OUT	*/
	word		* Nc_out	/* 		OUT	*/
)
{
	register int  	k, lambda;
	word		Nc, bc;

	float		wt_float[40];
	float		dp_float_base[120], * dp_float = dp_float_base + 120;

	longword	L_max, L_power;
	word		R, S, dmax, scal;
	register word	temp;

	/*  Search of the optimum scaling of d[0..39].
	 */
	dmax = 0;

	for (k = 0; k <= 39; k++) {
		temp = d[k];
		temp = GSM_ABS( temp );
		if (temp > dmax) dmax = temp;
	}

	temp = 0;
	if (dmax == 0) scal = 0;
	else {
		assert(dmax > 0);
		temp = gsm_norm( (longword)dmax << 16 );
	}

	if (temp > 6) scal = 0;
	else scal = 6 - temp;

	assert(scal >= 0);

	/*  Initialization of a working array wt
	 */

	for (k =    0; k < 40; k++) wt_float[k] =  SASR( d[k], scal );
	for (k = -120; k <  0; k++) dp_float[k] =  dp[k];

	/* Search for the maximum cross-correlation and coding of the LTP lag
	 */
	L_max = 0;
	Nc    = 40;	/* index for the maximum cross-correlation */

	for (lambda = 40; lambda <= 120; lambda += 9) {

		/*  Calculate L_result for l = lambda .. lambda + 9.
		 */
		register float *lp = dp_float - lambda;

		register float	W;
		register float	a = lp[-8], b = lp[-7], c = lp[-6],
				d = lp[-5], e = lp[-4], f = lp[-3],
				g = lp[-2], h = lp[-1];
		register float  E; 
		register float  S0 = 0, S1 = 0, S2 = 0, S3 = 0, S4 = 0,
				S5 = 0, S6 = 0, S7 = 0, S8 = 0;

#		undef STEP
#		define	STEP(K, a, b, c, d, e, f, g, h) \
			W = wt_float[K];		\
			E = W * a; S8 += E;		\
			E = W * b; S7 += E;		\
			E = W * c; S6 += E;		\
			E = W * d; S5 += E;		\
			E = W * e; S4 += E;		\
			E = W * f; S3 += E;		\
			E = W * g; S2 += E;		\
			E = W * h; S1 += E;		\
			a  = lp[K];			\
			E = W * a; S0 += E

#		define	STEP_A(K)	STEP(K, a, b, c, d, e, f, g, h)
#		define	STEP_B(K)	STEP(K, b, c, d, e, f, g, h, a)
#		define	STEP_C(K)	STEP(K, c, d, e, f, g, h, a, b)
#		define	STEP_D(K)	STEP(K, d, e, f, g, h, a, b, c)
#		define	STEP_E(K)	STEP(K, e, f, g, h, a, b, c, d)
#		define	STEP_F(K)	STEP(K, f, g, h, a, b, c, d, e)
#		define	STEP_G(K)	STEP(K, g, h, a, b, c, d, e, f)
#		define	STEP_H(K)	STEP(K, h, a, b, c, d, e, f, g)

		STEP_A( 0); STEP_B( 1); STEP_C( 2); STEP_D( 3);
		STEP_E( 4); STEP_F( 5); STEP_G( 6); STEP_H( 7);

		STEP_A( 8); STEP_B( 9); STEP_C(10); STEP_D(11);
		STEP_E(12); STEP_F(13); STEP_G(14); STEP_H(15);

		STEP_A(16); STEP_B(17); STEP_C(18); STEP_D(19);
		STEP_E(20); STEP_F(21); STEP_G(22); STEP_H(23);

		STEP_A(24); STEP_B(25); STEP_C(26); STEP_D(27);
		STEP_E(28); STEP_F(29); STEP_G(30); STEP_H(31);

		STEP_A(32); STEP_B(33); STEP_C(34); STEP_D(35);
		STEP_E(36); STEP_F(37); STEP_G(38); STEP_H(39);

		if (S0 > L_max) { L_max = S0; Nc = lambda;     }
		if (S1 > L_max) { L_max = S1; Nc = lambda + 1; }
		if (S2 > L_max) { L_max = S2; Nc = lambda + 2; }
		if (S3 > L_max) { L_max = S3; Nc = lambda + 3; }
		if (S4 > L_max) { L_max = S4; Nc = lambda + 4; }
		if (S5 > L_max) { L_max = S5; Nc = lambda + 5; }
		if (S6 > L_max) { L_max = S6; Nc = lambda + 6; }
		if (S7 > L_max) { L_max = S7; Nc = lambda + 7; }
		if (S8 > L_max) { L_max = S8; Nc = lambda + 8; }
	}
	*Nc_out = Nc;

	L_max <<= 1;

	/*  Rescaling of L_max
	 */
	assert(scal <= 100 && scal >=  -100);
	L_max = L_max >> (6 - scal);	/* sub(6, scal) */

	assert( Nc <= 120 && Nc >= 40);

	/*   Compute the power of the reconstructed short term residual
	 *   signal dp[..]
	 */
	L_power = 0;
	for (k = 0; k <= 39; k++) {

		register longword L_temp;

		L_temp   = SASR( dp[k - Nc], 3 );
		L_power += L_temp * L_temp;
	}
	L_power <<= 1;	/* from L_MULT */

	/*  Normalization of L_max and L_power
	 */

	if (L_max <= 0)  {
		*bc_out = 0;
		return;
	}
	if (L_max >= L_power) {
		*bc_out = 3;
		return;
	}

	temp = gsm_norm( L_power );

	R = SASR( L_max   << temp, 16 );
	S = SASR( L_power << temp, 16 );

	/*  Coding of the LTP gain
	 */

	/*  Table 4.3a must be used to obtain the level DLB[i] for the
	 *  quantization of the LTP gain b to get the coded version bc.
	 */
	for (bc = 0; bc <= 2; bc++) if (R <= gsm_mult(S, gsm_DLB[bc])) break;
	*bc_out = bc;
}

#ifdef	FAST
#ifdef	LTP_CUT

static void Cut_Fast_Calculation_of_the_LTP_parameters P5((st,
							d,dp,bc_out,Nc_out),
	struct gsm_state * st,		/*              IN	*/
	register word	* d,		/* [0..39]	IN	*/
	register word	* dp,		/* [-120..-1]	IN	*/
	word		* bc_out,	/* 		OUT	*/
	word		* Nc_out	/* 		OUT	*/
)
{
	register int  	k, lambda;
	register float	wt_float;
	word		Nc, bc;
	word		wt_max, best_k, ltp_cut;

	float		dp_float_base[120], * dp_float = dp_float_base + 120;

	register float	L_result, L_max, L_power;

	wt_max = 0;

	for (k = 0; k < 40; ++k) {
		if      ( d[k] > wt_max) wt_max =  d[best_k = k];
		else if (-d[k] > wt_max) wt_max = -d[best_k = k];
	}

	assert(wt_max >= 0);
	wt_float = (float)wt_max;

	for (k = -120; k < 0; ++k) dp_float[k] = (float)dp[k];

	/* Search for the maximum cross-correlation and coding of the LTP lag
	 */
	L_max = 0;
	Nc    = 40;	/* index for the maximum cross-correlation */

	for (lambda = 40; lambda <= 120; lambda++) {
		L_result = wt_float * dp_float[best_k - lambda];
		if (L_result > L_max) {
			Nc    = lambda;
			L_max = L_result;
		}
	}

	*Nc_out = Nc;
	if (L_max <= 0.)  {
		*bc_out = 0;
		return;
	}

	/*  Compute the power of the reconstructed short term residual
	 *  signal dp[..]
	 */
	dp_float -= Nc;
	L_power = 0;
	for (k = 0; k < 40; ++k) {
		register float f = dp_float[k];
		L_power += f * f;
	}

	if (L_max >= L_power) {
		*bc_out = 3;
		return;
	}

	/*  Coding of the LTP gain
	 *  Table 4.3a must be used to obtain the level DLB[i] for the
	 *  quantization of the LTP gain b to get the coded version bc.
	 */
	lambda = L_max / L_power * 32768.;
	for (bc = 0; bc <= 2; ++bc) if (lambda <= gsm_DLB[bc]) break;
	*bc_out = bc;
}

#endif /* LTP_CUT */

static void Fast_Calculation_of_the_LTP_parameters P4((d,dp,bc_out,Nc_out),
	register word	* d,		/* [0..39]	IN	*/
	register word	* dp,		/* [-120..-1]	IN	*/
	word		* bc_out,	/* 		OUT	*/
	word		* Nc_out	/* 		OUT	*/
)
{
	register int  	k, lambda;
	word		Nc, bc;

	float		wt_float[40];
	float		dp_float_base[120], * dp_float = dp_float_base + 120;

	register float	L_max, L_power;

	for (k = 0; k < 40; ++k) wt_float[k] = (float)d[k];
	for (k = -120; k < 0; ++k) dp_float[k] = (float)dp[k];

	/* Search for the maximum cross-correlation and coding of the LTP lag
	 */
	L_max = 0;
	Nc    = 40;	/* index for the maximum cross-correlation */

	for (lambda = 40; lambda <= 120; lambda += 9) {

		/*  Calculate L_result for l = lambda .. lambda + 9.
		 */
		register float *lp = dp_float - lambda;

		register float	W;
		register float	a = lp[-8], b = lp[-7], c = lp[-6],
				d = lp[-5], e = lp[-4], f = lp[-3],
				g = lp[-2], h = lp[-1];
		register float  E; 
		register float  S0 = 0, S1 = 0, S2 = 0, S3 = 0, S4 = 0,
				S5 = 0, S6 = 0, S7 = 0, S8 = 0;

#		undef STEP
#		define	STEP(K, a, b, c, d, e, f, g, h) \
			W = wt_float[K];		\
			E = W * a; S8 += E;		\
			E = W * b; S7 += E;		\
			E = W * c; S6 += E;		\
			E = W * d; S5 += E;		\
			E = W * e; S4 += E;		\
			E = W * f; S3 += E;		\
			E = W * g; S2 += E;		\
			E = W * h; S1 += E;		\
			a  = lp[K];			\
			E = W * a; S0 += E

#		define	STEP_A(K)	STEP(K, a, b, c, d, e, f, g, h)
#		define	STEP_B(K)	STEP(K, b, c, d, e, f, g, h, a)
#		define	STEP_C(K)	STEP(K, c, d, e, f, g, h, a, b)
#		define	STEP_D(K)	STEP(K, d, e, f, g, h, a, b, c)
#		define	STEP_E(K)	STEP(K, e, f, g, h, a, b, c, d)
#		define	STEP_F(K)	STEP(K, f, g, h, a, b, c, d, e)
#		define	STEP_G(K)	STEP(K, g, h, a, b, c, d, e, f)
#		define	STEP_H(K)	STEP(K, h, a, b, c, d, e, f, g)

		STEP_A( 0); STEP_B( 1); STEP_C( 2); STEP_D( 3);
		STEP_E( 4); STEP_F( 5); STEP_G( 6); STEP_H( 7);

		STEP_A( 8); STEP_B( 9); STEP_C(10); STEP_D(11);
		STEP_E(12); STEP_F(13); STEP_G(14); STEP_H(15);

		STEP_A(16); STEP_B(17); STEP_C(18); STEP_D(19);
		STEP_E(20); STEP_F(21); STEP_G(22); STEP_H(23);

		STEP_A(24); STEP_B(25); STEP_C(26); STEP_D(27);
		STEP_E(28); STEP_F(29); STEP_G(30); STEP_H(31);

		STEP_A(32); STEP_B(33); STEP_C(34); STEP_D(35);
		STEP_E(36); STEP_F(37); STEP_G(38); STEP_H(39);

		if (S0 > L_max) { L_max = S0; Nc = lambda;     }
		if (S1 > L_max) { L_max = S1; Nc = lambda + 1; }
		if (S2 > L_max) { L_max = S2; Nc = lambda + 2; }
		if (S3 > L_max) { L_max = S3; Nc = lambda + 3; }
		if (S4 > L_max) { L_max = S4; Nc = lambda + 4; }
		if (S5 > L_max) { L_max = S5; Nc = lambda + 5; }
		if (S6 > L_max) { L_max = S6; Nc = lambda + 6; }
		if (S7 > L_max) { L_max = S7; Nc = lambda + 7; }
		if (S8 > L_max) { L_max = S8; Nc = lambda + 8; }
	}
	*Nc_out = Nc;

	if (L_max <= 0.)  {
		*bc_out = 0;
		return;
	}

	/*  Compute the power of the reconstructed short term residual
	 *  signal dp[..]
	 */
	dp_float -= Nc;
	L_power = 0;
	for (k = 0; k < 40; ++k) {
		register float f = dp_float[k];
		L_power += f * f;
	}

	if (L_max >= L_power) {
		*bc_out = 3;
		return;
	}

	/*  Coding of the LTP gain
	 *  Table 4.3a must be used to obtain the level DLB[i] for the
	 *  quantization of the LTP gain b to get the coded version bc.
	 */
	lambda = L_max / L_power * 32768.;
	for (bc = 0; bc <= 2; ++bc) if (lambda <= gsm_DLB[bc]) break;
	*bc_out = bc;
}

#endif	/* FAST 	 */
#endif	/* USE_FLOAT_MUL */


/* 4.2.12 */

static void Long_term_analysis_filtering P6((bc,Nc,dp,d,dpp,e),
	word		bc,	/* 					IN  */
	word		Nc,	/* 					IN  */
	register word	* dp,	/* previous d	[-120..-1]		IN  */
	register word	* d,	/* d		[0..39]			IN  */
	register word	* dpp,	/* estimate	[0..39]			OUT */
	register word	* e	/* long term res. signal [0..39]	OUT */
)
/*
 *  In this part, we have to decode the bc parameter to compute
 *  the samples of the estimate dpp[0..39].  The decoding of bc needs the
 *  use of table 4.3b.  The long term residual signal e[0..39]
 *  is then calculated to be fed to the RPE encoding section.
 */
{
	register int      k;
	register longword ltmp;

#	undef STEP
#	define STEP(BP)					\
	for (k = 0; k <= 39; k++) {			\
		dpp[k]  = GSM_MULT_R( BP, dp[k - Nc]);	\
		e[k]	= GSM_SUB( d[k], dpp[k] );	\
	}

	switch (bc) {
	case 0:	STEP(  3277 ); break;
	case 1:	STEP( 11469 ); break;
	case 2: STEP( 21299 ); break;
	case 3: STEP( 32767 ); break; 
	}
}

void Gsm_Long_Term_Predictor P7((S,d,dp,e,dpp,Nc,bc), 	/* 4x for 160 samples */

	struct gsm_state	* S,

	word	* d,	/* [0..39]   residual signal	IN	*/
	word	* dp,	/* [-120..-1] d'		IN	*/

	word	* e,	/* [0..39] 			OUT	*/
	word	* dpp,	/* [0..39] 			OUT	*/
	word	* Nc,	/* correlation lag		OUT	*/
	word	* bc	/* gain factor			OUT	*/
)
{
	assert( d  ); assert( dp ); assert( e  );
	assert( dpp); assert( Nc ); assert( bc );

#if defined(FAST) && defined(USE_FLOAT_MUL)
	if (S->fast) 
#if   defined (LTP_CUT)
		if (S->ltp_cut)
			Cut_Fast_Calculation_of_the_LTP_parameters(S,
				d, dp, bc, Nc);
		else
#endif /* LTP_CUT */
			Fast_Calculation_of_the_LTP_parameters(d, dp, bc, Nc );
	else 
#endif /* FAST & USE_FLOAT_MUL */
#ifdef LTP_CUT
		if (S->ltp_cut)
			Cut_Calculation_of_the_LTP_parameters(S, d, dp, bc, Nc);
		else
#endif
			Calculation_of_the_LTP_parameters(d, dp, bc, Nc);

	Long_term_analysis_filtering( *bc, *Nc, dp, d, dpp, e );
}

/* 4.3.2 */
void Gsm_Long_Term_Synthesis_Filtering P5((S,Ncr,bcr,erp,drp),
	struct gsm_state	* S,

	word			Ncr,
	word			bcr,
	register word		* erp,	   /* [0..39]		  	 IN */
	register word		* drp	   /* [-120..-1] IN, [-120..40] OUT */
)
/*
 *  This procedure uses the bcr and Ncr parameter to realize the
 *  long term synthesis filtering.  The decoding of bcr needs
 *  table 4.3b.
 */
{
	register longword	ltmp;	/* for ADD */
	register int 		k;
	word			brp, drpp, Nr;

	/*  Check the limits of Nr.
	 */
	Nr = Ncr < 40 || Ncr > 120 ? S->nrp : Ncr;
	S->nrp = Nr;
	assert(Nr >= 40 && Nr <= 120);

	/*  Decoding of the LTP gain bcr
	 */
	brp = gsm_QLB[ bcr ];

	/*  Computation of the reconstructed short term residual 
	 *  signal drp[0..39]
	 */
	assert(brp != MIN_WORD);

	for (k = 0; k <= 39; k++) {
		drpp   = GSM_MULT_R( brp, drp[ k - Nr ] );
		drp[k] = GSM_ADD( erp[k], drpp );
	}

	/*
	 *  Update of the reconstructed short term residual signal
	 *  drp[ -1..-120 ]
	 */

	for (k = 0; k <= 119; k++) drp[ -120 + k ] = drp[ -80 + k ];
}

/****** begin "lpc.c" *****/

#undef STEP
#undef	P

/*
 *  4.2.4 .. 4.2.7 LPC ANALYSIS SECTION
 */

/* 4.2.4 */


static void Autocorrelation P2((s, L_ACF),
	word     * s,		/* [0..159]	IN/OUT  */
 	longword * L_ACF)	/* [0..8]	OUT     */
/*
 *  The goal is to compute the array L_ACF[k].  The signal s[i] must
 *  be scaled in order to avoid an overflow situation.
 */
{
	register int	k, i;

	word		temp, smax, scalauto;

#ifdef	USE_FLOAT_MUL
	float		float_s[160];
#endif

	/*  Dynamic scaling of the array  s[0..159]
	 */

	/*  Search for the maximum.
	 */
	smax = 0;
	for (k = 0; k <= 159; k++) {
		temp = GSM_ABS( s[k] );
		if (temp > smax) smax = temp;
	}

	/*  Computation of the scaling factor.
	 */
	if (smax == 0) scalauto = 0;
	else {
		assert(smax > 0);
		scalauto = 4 - gsm_norm( (longword)smax << 16 );/* sub(4,..) */
	}

	/*  Scaling of the array s[0...159]
	 */

	if (scalauto > 0) {

# ifdef USE_FLOAT_MUL
#   define SCALE(n)	\
	case n: for (k = 0; k <= 159; k++) \
			float_s[k] = (float)	\
				(s[k] = GSM_MULT_R(s[k], 16384 >> (n-1)));\
		break;
# else 
#   define SCALE(n)	\
	case n: for (k = 0; k <= 159; k++) \
			s[k] = GSM_MULT_R( s[k], 16384 >> (n-1) );\
		break;
# endif /* USE_FLOAT_MUL */

		switch (scalauto) {
		SCALE(1)
		SCALE(2)
		SCALE(3)
		SCALE(4)
		}
# undef	SCALE
	}
# ifdef	USE_FLOAT_MUL
	else for (k = 0; k <= 159; k++) float_s[k] = (float) s[k];
# endif

	/*  Compute the L_ACF[..].
	 */
	{
# ifdef	USE_FLOAT_MUL
		register float * sp = float_s;
		register float   sl = *sp;

#		define STEP(k)	 L_ACF[k] += (longword)(sl * sp[ -(k) ]);
# else
		word  * sp = s;
		word    sl = *sp;

#		define STEP(k)	 L_ACF[k] += ((longword)sl * sp[ -(k) ]);
# endif

#	define NEXTI	 sl = *++sp


	for (k = 9; k--; L_ACF[k] = 0) ;

	STEP (0);
	NEXTI;
	STEP(0); STEP(1);
	NEXTI;
	STEP(0); STEP(1); STEP(2);
	NEXTI;
	STEP(0); STEP(1); STEP(2); STEP(3);
	NEXTI;
	STEP(0); STEP(1); STEP(2); STEP(3); STEP(4);
	NEXTI;
	STEP(0); STEP(1); STEP(2); STEP(3); STEP(4); STEP(5);
	NEXTI;
	STEP(0); STEP(1); STEP(2); STEP(3); STEP(4); STEP(5); STEP(6);
	NEXTI;
	STEP(0); STEP(1); STEP(2); STEP(3); STEP(4); STEP(5); STEP(6); STEP(7);

	for (i = 8; i <= 159; i++) {

		NEXTI;

		STEP(0);
		STEP(1); STEP(2); STEP(3); STEP(4);
		STEP(5); STEP(6); STEP(7); STEP(8);
	}

	for (k = 9; k--; L_ACF[k] <<= 1) ; 

	}
	/*   Rescaling of the array s[0..159]
	 */
	if (scalauto > 0) {
		assert(scalauto <= 4); 
		for (k = 160; k--; *s++ <<= scalauto) ;
	}
}

#if defined(USE_FLOAT_MUL) && defined(FAST)

static void Fast_Autocorrelation P2((s, L_ACF),
	word * s,		/* [0..159]	IN/OUT  */
 	longword * L_ACF)	/* [0..8]	OUT     */
{
	register int	k, i;
	float f_L_ACF[9];
	float scale;

	float          s_f[160];
	register float *sf = s_f;

	for (i = 0; i < 160; ++i) sf[i] = s[i];
	for (k = 0; k <= 8; k++) {
		register float L_temp2 = 0;
		register float *sfl = sf - k;
		for (i = k; i < 160; ++i) L_temp2 += sf[i] * sfl[i];
		f_L_ACF[k] = L_temp2;
	}
	scale = MAX_LONGWORD / f_L_ACF[0];

	for (k = 0; k <= 8; k++) {
		L_ACF[k] = f_L_ACF[k] * scale;
	}
}
#endif	/* defined (USE_FLOAT_MUL) && defined (FAST) */

/* 4.2.5 */

static void Reflection_coefficients P2( (L_ACF, r),
	longword	* L_ACF,		/* 0...8	IN	*/
	register word	* r			/* 0...7	OUT 	*/
)
{
	register int	i, m, n;
	register word	temp;
	register longword ltmp;
	word		ACF[9];	/* 0..8 */
	word		P[  9];	/* 0..8 */
	word		K[  9]; /* 2..8 */

	/*  Schur recursion with 16 bits arithmetic.
	 */

	if (L_ACF[0] == 0) {
		for (i = 8; i--; *r++ = 0) ;
		return;
	}

	assert( L_ACF[0] != 0 );
	temp = gsm_norm( L_ACF[0] );

	assert(temp >= 0 && temp < 32);

	/* ? overflow ? */
	for (i = 0; i <= 8; i++) ACF[i] = SASR( L_ACF[i] << temp, 16 );

	/*   Initialize array P[..] and K[..] for the recursion.
	 */

	for (i = 1; i <= 7; i++) K[ i ] = ACF[ i ];
	for (i = 0; i <= 8; i++) P[ i ] = ACF[ i ];

	/*   Compute reflection coefficients
	 */
	for (n = 1; n <= 8; n++, r++) {

		temp = P[1];
		temp = GSM_ABS(temp);
		if (P[0] < temp) {
			for (i = n; i <= 8; i++) *r++ = 0;
			return;
		}

		*r = gsm_div( temp, P[0] );

		assert(*r >= 0);
		if (P[1] > 0) *r = -*r;		/* r[n] = sub(0, r[n]) */
		assert (*r != MIN_WORD);
		if (n == 8) return; 

		/*  Schur recursion
		 */
		temp = GSM_MULT_R( P[1], *r );
		P[0] = GSM_ADD( P[0], temp );

		for (m = 1; m <= 8 - n; m++) {
			temp     = GSM_MULT_R( K[ m   ],    *r );
			P[m]     = GSM_ADD(    P[ m+1 ],  temp );

			temp     = GSM_MULT_R( P[ m+1 ],    *r );
			K[m]     = GSM_ADD(    K[ m   ],  temp );
		}
	}
}

/* 4.2.6 */

static void Transformation_to_Log_Area_Ratios P1((r),
	register word	* r 			/* 0..7	   IN/OUT */
)
/*
 *  The following scaling for r[..] and LAR[..] has been used:
 *
 *  r[..]   = integer( real_r[..]*32768. ); -1 <= real_r < 1.
 *  LAR[..] = integer( real_LAR[..] * 16384 );
 *  with -1.625 <= real_LAR <= 1.625
 */
{
	register word	temp;
	register int	i;


	/* Computation of the LAR[0..7] from the r[0..7]
	 */
	for (i = 1; i <= 8; i++, r++) {

		temp = *r;
		temp = GSM_ABS(temp);
		assert(temp >= 0);

		if (temp < 22118) {
			temp >>= 1;
		} else if (temp < 31130) {
			assert( temp >= 11059 );
			temp -= 11059;
		} else {
			assert( temp >= 26112 );
			temp -= 26112;
			temp <<= 2;
		}

		*r = *r < 0 ? -temp : temp;
		assert( *r != MIN_WORD );
	}
}

/* 4.2.7 */

static void Quantization_and_coding P1((LAR),
	register word * LAR    	/* [0..7]	IN/OUT	*/
)
{
	register word	temp;
	longword	ltmp;


	/*  This procedure needs four tables; the following equations
	 *  give the optimum scaling for the constants:
	 *  
	 *  A[0..7] = integer( real_A[0..7] * 1024 )
	 *  B[0..7] = integer( real_B[0..7] *  512 )
	 *  MAC[0..7] = maximum of the LARc[0..7]
	 *  MIC[0..7] = minimum of the LARc[0..7]
	 */

#	undef STEP
#	define	STEP( A, B, MAC, MIC )		\
		temp = GSM_MULT( A,   *LAR );	\
		temp = GSM_ADD(  temp,   B );	\
		temp = GSM_ADD(  temp, 256 );	\
		temp = SASR(     temp,   9 );	\
		*LAR  =  temp>MAC ? MAC - MIC : (temp<MIC ? 0 : temp - MIC); \
		LAR++;

	STEP(  20480,     0,  31, -32 );
	STEP(  20480,     0,  31, -32 );
	STEP(  20480,  2048,  15, -16 );
	STEP(  20480, -2560,  15, -16 );

	STEP(  13964,    94,   7,  -8 );
	STEP(  15360, -1792,   7,  -8 );
	STEP(   8534,  -341,   3,  -4 );
	STEP(   9036, -1144,   3,  -4 );

#	undef	STEP
}

void Gsm_LPC_Analysis P3((S, s,LARc),
	struct gsm_state *S,
	word 		 * s,		/* 0..159 signals	IN/OUT	*/
        word 		 * LARc)	/* 0..7   LARc's	OUT	*/
{
	longword	L_ACF[9];

#if defined(USE_FLOAT_MUL) && defined(FAST)
	if (S->fast) Fast_Autocorrelation (s,	  L_ACF );
	else
#endif
	Autocorrelation			  (s,	  L_ACF	);
	Reflection_coefficients		  (L_ACF, LARc	);
	Transformation_to_Log_Area_Ratios (LARc);
	Quantization_and_coding		  (LARc);
}

/****** begin "preprocess.c" *****/

/*	4.2.0 .. 4.2.3	PREPROCESSING SECTION
 *  
 *  	After A-law to linear conversion (or directly from the
 *   	Ato D converter) the following scaling is assumed for
 * 	input to the RPE-LTP algorithm:
 *
 *      in:  0.1.....................12
 *	     S.v.v.v.v.v.v.v.v.v.v.v.v.*.*.*
 *
 *	Where S is the sign bit, v a valid bit, and * a "don't care" bit.
 * 	The original signal is called sop[..]
 *
 *      out:   0.1................... 12 
 *	     S.S.v.v.v.v.v.v.v.v.v.v.v.v.0.0
 */


void Gsm_Preprocess P3((S, s, so),
	struct gsm_state * S,
	word		 * s,
	word 		 * so )		/* [0..159] 	IN/OUT	*/
{

	word       z1 = S->z1;
	longword L_z2 = S->L_z2;
	word 	   mp = S->mp;

	word 	   	s1;
	longword      L_s2;

	longword      L_temp;

	word		msp, lsp;
	word		SO;

	longword	ltmp;		/* for   ADD */
	ulongword	utmp;		/* for L_ADD */

	volatile int		k = 160;

	while (k--) {

	/*  4.2.1   Downscaling of the input signal
	 */
		SO = SASR( *s, 3 ) << 2;
		s++;

		assert (SO >= -0x4000);	/* downscaled by     */
		assert (SO <=  0x3FFC);	/* previous routine. */


	/*  4.2.2   Offset compensation
	 * 
	 *  This part implements a high-pass filter and requires extended
	 *  arithmetic precision for the recursive part of this filter.
	 *  The input of this procedure is the array so[0...159] and the
	 *  output the array sof[ 0...159 ].
	 */
		/*   Compute the non-recursive part
		 */

		s1 = SO - z1;			/* s1 = gsm_sub( *so, z1 ); */
		z1 = SO;

		assert(s1 != MIN_WORD);

		/*   Compute the recursive part
		 */
		L_s2 = s1;
		L_s2 <<= 15;

		/*   Execution of a 31 bv 16 bits multiplication
		 */

		msp = SASR( L_z2, 15 );
		lsp = L_z2-((longword)msp<<15); /* gsm_L_sub(L_z2,(msp<<15)); */

		L_s2  += GSM_MULT_R( lsp, 32735 );
		L_temp = (longword)msp * 32735; /* GSM_L_MULT(msp,32735) >> 1;*/
		L_z2   = GSM_L_ADD( L_temp, L_s2 );

		/*    Compute sof[k] with rounding
		 */
		L_temp = GSM_L_ADD( L_z2, 16384 );

	/*   4.2.3  Preemphasis
	 */

		msp   = GSM_MULT_R( mp, -28180 );
		mp    = SASR( L_temp, 15 );
		*so++ = GSM_ADD( mp, msp );
	}

	S->z1   = z1;
	S->L_z2 = L_z2;
	S->mp   = mp;
}

/****** begin "rpe.c" *****/

/*  4.2.13 .. 4.2.17  RPE ENCODING SECTION
 */

/* 4.2.13 */

static void Weighting_filter P2((e, x),
	register word	* e,		/* signal [-5..0.39.44]	IN  */
	word		* x		/* signal [0..39]	OUT */
)
/*
 *  The coefficients of the weighting filter are stored in a table
 *  (see table 4.4).  The following scaling is used:
 *
 *	H[0..10] = integer( real_H[ 0..10] * 8192 ); 
 */
{
	/* word			wt[ 50 ]; */

	register longword	L_result;
	register int		k /* , i */ ;

	/*  Initialization of a temporary working array wt[0...49]
	 */

	/* for (k =  0; k <=  4; k++) wt[k] = 0;
	 * for (k =  5; k <= 44; k++) wt[k] = *e++;
	 * for (k = 45; k <= 49; k++) wt[k] = 0;
	 *
	 *  (e[-5..-1] and e[40..44] are allocated by the caller,
	 *  are initially zero and are not written anywhere.)
	 */
	e -= 5;

	/*  Compute the signal x[0..39]
	 */ 
	for (k = 0; k <= 39; k++) {

		L_result = 8192 >> 1;

		/* for (i = 0; i <= 10; i++) {
		 *	L_temp   = GSM_L_MULT( wt[k+i], gsm_H[i] );
		 *	L_result = GSM_L_ADD( L_result, L_temp );
		 * }
		 */

#undef	STEP
#define	STEP( i, H )	(e[ k + i ] * (longword)H)

		/*  Every one of these multiplications is done twice --
		 *  but I don't see an elegant way to optimize this. 
		 *  Do you?
		 */

#ifdef	STUPID_COMPILER
		L_result += STEP(	0, 	-134 ) ;
		L_result += STEP(	1, 	-374 )  ;
	               /* + STEP(	2, 	0    )  */
		L_result += STEP(	3, 	2054 ) ;
		L_result += STEP(	4, 	5741 ) ;
		L_result += STEP(	5, 	8192 ) ;
		L_result += STEP(	6, 	5741 ) ;
		L_result += STEP(	7, 	2054 ) ;
	 	       /* + STEP(	8, 	0    )  */
		L_result += STEP(	9, 	-374 ) ;
		L_result += STEP(	10, 	-134 ) ;
#else
		L_result +=
		  STEP(	0, 	-134 ) 
		+ STEP(	1, 	-374 ) 
	     /* + STEP(	2, 	0    )  */
		+ STEP(	3, 	2054 ) 
		+ STEP(	4, 	5741 ) 
		+ STEP(	5, 	8192 ) 
		+ STEP(	6, 	5741 ) 
		+ STEP(	7, 	2054 ) 
	     /* + STEP(	8, 	0    )  */
		+ STEP(	9, 	-374 ) 
		+ STEP(10, 	-134 )
		;
#endif

		/* L_result = GSM_L_ADD( L_result, L_result ); (* scaling(x2) *)
		 * L_result = GSM_L_ADD( L_result, L_result ); (* scaling(x4) *)
		 *
		 * x[k] = SASR( L_result, 16 );
		 */

		/* 2 adds vs. >>16 => 14, minus one shift to compensate for
		 * those we lost when replacing L_MULT by '*'.
		 */

		L_result = SASR( L_result, 13 );
		x[k] =  (  L_result < MIN_WORD ? MIN_WORD
			: (L_result > MAX_WORD ? MAX_WORD : L_result ));
	}
}

/* 4.2.14 */

static void RPE_grid_selection P3((x,xM,Mc_out),
	word		* x,		/* [0..39]		IN  */ 
	word		* xM,		/* [0..12]		OUT */
	word		* Mc_out	/*			OUT */
)
/*
 *  The signal x[0..39] is used to select the RPE grid which is
 *  represented by Mc.
 */
{
	/* register word	temp1;	*/
	register int		/* m, */  i;
	register longword	L_result, L_temp;
	longword		EM;	/* xxx should be L_EM? */
	word			Mc;

	longword		L_common_0_3;

	EM = 0;
	Mc = 0;

	/* for (m = 0; m <= 3; m++) {
	 *	L_result = 0;
	 *
	 *
	 *	for (i = 0; i <= 12; i++) {
	 *
	 *		temp1    = SASR( x[m + 3*i], 2 );
	 *
	 *		assert(temp1 != MIN_WORD);
	 *
	 *		L_temp   = GSM_L_MULT( temp1, temp1 );
	 *		L_result = GSM_L_ADD( L_temp, L_result );
	 *	}
	 * 
	 *	if (L_result > EM) {
	 *		Mc = m;
	 *		EM = L_result;
	 *	}
	 * }
	 */

#undef	STEP
#define	STEP( m, i )		L_temp = SASR( x[m + 3 * i], 2 );	\
				L_result += L_temp * L_temp;

	/* common part of 0 and 3 */

	L_result = 0;
	STEP( 0, 1 ); STEP( 0, 2 ); STEP( 0, 3 ); STEP( 0, 4 );
	STEP( 0, 5 ); STEP( 0, 6 ); STEP( 0, 7 ); STEP( 0, 8 );
	STEP( 0, 9 ); STEP( 0, 10); STEP( 0, 11); STEP( 0, 12);
	L_common_0_3 = L_result;

	/* i = 0 */

	STEP( 0, 0 );
	L_result <<= 1;	/* implicit in L_MULT */
	EM = L_result;

	/* i = 1 */

	L_result = 0;
	STEP( 1, 0 );
	STEP( 1, 1 ); STEP( 1, 2 ); STEP( 1, 3 ); STEP( 1, 4 );
	STEP( 1, 5 ); STEP( 1, 6 ); STEP( 1, 7 ); STEP( 1, 8 );
	STEP( 1, 9 ); STEP( 1, 10); STEP( 1, 11); STEP( 1, 12);
	L_result <<= 1;
	if (L_result > EM) {
		Mc = 1;
	 	EM = L_result;
	}

	/* i = 2 */

	L_result = 0;
	STEP( 2, 0 );
	STEP( 2, 1 ); STEP( 2, 2 ); STEP( 2, 3 ); STEP( 2, 4 );
	STEP( 2, 5 ); STEP( 2, 6 ); STEP( 2, 7 ); STEP( 2, 8 );
	STEP( 2, 9 ); STEP( 2, 10); STEP( 2, 11); STEP( 2, 12);
	L_result <<= 1;
	if (L_result > EM) {
		Mc = 2;
	 	EM = L_result;
	}

	/* i = 3 */

	L_result = L_common_0_3;
	STEP( 3, 12 );
	L_result <<= 1;
	if (L_result > EM) {
		Mc = 3;
	 	EM = L_result;
	}

	/**/

	/*  Down-sampling by a factor 3 to get the selected xM[0..12]
	 *  RPE sequence.
	 */
	for (i = 0; i <= 12; i ++) xM[i] = x[Mc + 3*i];
	*Mc_out = Mc;
}

/* 4.12.15 */

static void APCM_quantization_xmaxc_to_exp_mant P3((xmaxc,exp_out,mant_out),
	word		xmaxc,		/* IN 	*/
	word		* exp_out,	/* OUT	*/
	word		* mant_out )	/* OUT  */
{
	word	exp, mant;

	/* Compute exponent and mantissa of the decoded version of xmaxc
	 */

	exp = 0;
	if (xmaxc > 15) exp = SASR(xmaxc, 3) - 1;
	mant = xmaxc - (exp << 3);

	if (mant == 0) {
		exp  = -4;
		mant = 7;
	}
	else {
		while (mant <= 7) {
			mant = mant << 1 | 1;
			exp--;
		}
		mant -= 8;
	}

	assert( exp  >= -4 && exp <= 6 );
	assert( mant >= 0 && mant <= 7 );

	*exp_out  = exp;
	*mant_out = mant;
}

static void APCM_quantization P5((xM,xMc,mant_out,exp_out,xmaxc_out),
	word		* xM,		/* [0..12]		IN	*/

	word		* xMc,		/* [0..12]		OUT	*/
	word		* mant_out,	/* 			OUT	*/
	word		* exp_out,	/*			OUT	*/
	word		* xmaxc_out	/*			OUT	*/
)
{
	int	i, itest;

	word	xmax, xmaxc, temp, temp1, temp2;
	word	exp, mant;


	/*  Find the maximum absolute value xmax of xM[0..12].
	 */

	xmax = 0;
	for (i = 0; i <= 12; i++) {
		temp = xM[i];
		temp = GSM_ABS(temp);
		if (temp > xmax) xmax = temp;
	}

	/*  Qantizing and coding of xmax to get xmaxc.
	 */

	exp   = 0;
	temp  = SASR( xmax, 9 );
	itest = 0;

	for (i = 0; i <= 5; i++) {

		itest |= (temp <= 0);
		temp = SASR( temp, 1 );

		assert(exp <= 5);
		if (itest == 0) exp++;		/* exp = add (exp, 1) */
	}

	assert(exp <= 6 && exp >= 0);
	temp = exp + 5;

	assert(temp <= 11 && temp >= 0);
	xmaxc = gsm_add( SASR(xmax, temp), exp << 3 );

	/*   Quantizing and coding of the xM[0..12] RPE sequence
	 *   to get the xMc[0..12]
	 */

	APCM_quantization_xmaxc_to_exp_mant( xmaxc, &exp, &mant );

	/*  This computation uses the fact that the decoded version of xmaxc
	 *  can be calculated by using the exponent and the mantissa part of
	 *  xmaxc (logarithmic table).
	 *  So, this method avoids any division and uses only a scaling
	 *  of the RPE samples by a function of the exponent.  A direct 
	 *  multiplication by the inverse of the mantissa (NRFAC[0..7]
	 *  found in table 4.5) gives the 3 bit coded version xMc[0..12]
	 *  of the RPE samples.
	 */


	/* Direct computation of xMc[0..12] using table 4.5
	 */

	assert( exp <= 4096 && exp >= -4096);
	assert( mant >= 0 && mant <= 7 ); 

	temp1 = 6 - exp;		/* normalization by the exponent */
	temp2 = gsm_NRFAC[ mant ];  	/* inverse mantissa 		 */

	for (i = 0; i <= 12; i++) {

		assert(temp1 >= 0 && temp1 < 16);

		temp = xM[i] << temp1;
		temp = GSM_MULT( temp, temp2 );
		temp = SASR(temp, 12);
		xMc[i] = temp + 4;		/* see note below */
	}

	/*  NOTE: This equation is used to make all the xMc[i] positive.
	 */

	*mant_out  = mant;
	*exp_out   = exp;
	*xmaxc_out = xmaxc;
}

/* 4.2.16 */

static void APCM_inverse_quantization P4((xMc,mant,exp,xMp),
	register word	* xMc,	/* [0..12]			IN 	*/
	word		mant,
	word		exp,
	register word	* xMp)	/* [0..12]			OUT 	*/
/* 
 *  This part is for decoding the RPE sequence of coded xMc[0..12]
 *  samples to obtain the xMp[0..12] array.  Table 4.6 is used to get
 *  the mantissa of xmaxc (FAC[0..7]).
 */
{
	int	i;
	word	temp, temp1, temp2, temp3;
	longword	ltmp;

	assert( mant >= 0 && mant <= 7 ); 

	temp1 = gsm_FAC[ mant ];	/* see 4.2-15 for mant */
	temp2 = gsm_sub( 6, exp );	/* see 4.2-15 for exp  */
	temp3 = gsm_asl( 1, gsm_sub( temp2, 1 ));

	for (i = 13; i--;) {

		assert( *xMc <= 7 && *xMc >= 0 ); 	/* 3 bit unsigned */

		/* temp = gsm_sub( *xMc++ << 1, 7 ); */
		temp = (*xMc++ << 1) - 7;	        /* restore sign   */
		assert( temp <= 7 && temp >= -7 ); 	/* 4 bit signed   */

		temp <<= 12;				/* 16 bit signed  */
		temp = GSM_MULT_R( temp1, temp );
		temp = GSM_ADD( temp, temp3 );
		*xMp++ = gsm_asr( temp, temp2 );
	}
}

/* 4.2.17 */

static void RPE_grid_positioning P3((Mc,xMp,ep),
	word		Mc,		/* grid position	IN	*/
	register word	* xMp,		/* [0..12]		IN	*/
	register word	* ep		/* [0..39]		OUT	*/
)
/*
 *  This procedure computes the reconstructed long term residual signal
 *  ep[0..39] for the LTP analysis filter.  The inputs are the Mc
 *  which is the grid position selection and the xMp[0..12] decoded
 *  RPE samples which are upsampled by a factor of 3 by inserting zero
 *  values.
 */
{
	volatile int	i = 13;

	assert(0 <= Mc && Mc <= 3);

        switch (Mc) {
                case 3: *ep++ = 0;
                case 2:  do {
                                *ep++ = 0;
                case 1:         *ep++ = 0;
                case 0:         *ep++ = *xMp++;
                         } while (--i);
        }
        while (++Mc < 4) *ep++ = 0;

	/*

	int i, k;
	for (k = 0; k <= 39; k++) ep[k] = 0;
	for (i = 0; i <= 12; i++) {
		ep[ Mc + (3*i) ] = xMp[i];
	}
	*/
}

/* 4.2.18 */

/*  This procedure adds the reconstructed long term residual signal
 *  ep[0..39] to the estimated signal dpp[0..39] from the long term
 *  analysis filter to compute the reconstructed short term residual
 *  signal dp[-40..-1]; also the reconstructed short term residual
 *  array dp[-120..-41] is updated.
 */

#if 0	/* Has been inlined in code.c */
void Gsm_Update_of_reconstructed_short_time_residual_signal P3((dpp, ep, dp),
	word	* dpp,		/* [0...39]	IN	*/
	word	* ep,		/* [0...39]	IN	*/
	word	* dp)		/* [-120...-1]  IN/OUT 	*/
{
	int 		k;

	for (k = 0; k <= 79; k++) 
		dp[ -120 + k ] = dp[ -80 + k ];

	for (k = 0; k <= 39; k++)
		dp[ -40 + k ] = gsm_add( ep[k], dpp[k] );
}
#endif	/* Has been inlined in code.c */

void Gsm_RPE_Encoding P5((S,e,xmaxc,Mc,xMc),

	struct gsm_state * S,

	word	* e,		/* -5..-1][0..39][40..44	IN/OUT  */
	word	* xmaxc,	/* 				OUT */
	word	* Mc,		/* 			  	OUT */
	word	* xMc)		/* [0..12]			OUT */
{
	word	x[40];
	word	xM[13], xMp[13];
	word	mant, exp;

	Weighting_filter(e, x);
	RPE_grid_selection(x, xM, Mc);

	APCM_quantization(	xM, xMc, &mant, &exp, xmaxc);
	APCM_inverse_quantization(  xMc,  mant,  exp, xMp);

	RPE_grid_positioning( *Mc, xMp, e );

}

void Gsm_RPE_Decoding P5((S, xmaxcr, Mcr, xMcr, erp),
	struct gsm_state	* S,

	word 		xmaxcr,
	word		Mcr,
	word		* xMcr,  /* [0..12], 3 bits 		IN	*/
	word		* erp	 /* [0..39]			OUT 	*/
)
{
	word	exp, mant;
	word	xMp[ 13 ];

	APCM_quantization_xmaxc_to_exp_mant( xmaxcr, &exp, &mant );
	APCM_inverse_quantization( xMcr, mant, exp, xMp );
	RPE_grid_positioning( Mcr, xMp, erp );

}

/****** begin "short_term.c" *****/

/*
 *  SHORT TERM ANALYSIS FILTERING SECTION
 */

/* 4.2.8 */

static void Decoding_of_the_coded_Log_Area_Ratios P2((LARc,LARpp),
	word 	* LARc,		/* coded log area ratio	[0..7] 	IN	*/
	word	* LARpp)	/* out: decoded ..			*/
{
	register word	temp1 /* , temp2 */;
	register long	ltmp;	/* for GSM_ADD */

	/*  This procedure requires for efficient implementation
	 *  two tables.
 	 *
	 *  INVA[1..8] = integer( (32768 * 8) / real_A[1..8])
	 *  MIC[1..8]  = minimum value of the LARc[1..8]
	 */

	/*  Compute the LARpp[1..8]
	 */

	/* 	for (i = 1; i <= 8; i++, B++, MIC++, INVA++, LARc++, LARpp++) {
	 *
	 *		temp1  = GSM_ADD( *LARc, *MIC ) << 10;
	 *		temp2  = *B << 1;
	 *		temp1  = GSM_SUB( temp1, temp2 );
	 *
	 *		assert(*INVA != MIN_WORD);
	 *
	 *		temp1  = GSM_MULT_R( *INVA, temp1 );
	 *		*LARpp = GSM_ADD( temp1, temp1 );
	 *	}
	 */

#undef	STEP
#define	STEP( B, MIC, INVA )	\
		temp1    = GSM_ADD( *LARc++, MIC ) << 10;	\
		temp1    = GSM_SUB( temp1, B << 1 );		\
		temp1    = GSM_MULT_R( INVA, temp1 );		\
		*LARpp++ = GSM_ADD( temp1, temp1 );

	STEP(      0,  -32,  13107 );
	STEP(      0,  -32,  13107 );
	STEP(   2048,  -16,  13107 );
	STEP(  -2560,  -16,  13107 );

	STEP(     94,   -8,  19223 );
	STEP(  -1792,   -8,  17476 );
	STEP(   -341,   -4,  31454 );
	STEP(  -1144,   -4,  29708 );

	/* NOTE: the addition of *MIC is used to restore
	 * 	 the sign of *LARc.
	 */
}

/* 4.2.9 */
/* Computation of the quantized reflection coefficients 
 */

/* 4.2.9.1  Interpolation of the LARpp[1..8] to get the LARp[1..8]
 */

/*
 *  Within each frame of 160 analyzed speech samples the short term
 *  analysis and synthesis filters operate with four different sets of
 *  coefficients, derived from the previous set of decoded LARs(LARpp(j-1))
 *  and the actual set of decoded LARs (LARpp(j))
 *
 * (Initial value: LARpp(j-1)[1..8] = 0.)
 */

static void Coefficients_0_12 P3((LARpp_j_1, LARpp_j, LARp),
	register word * LARpp_j_1,
	register word * LARpp_j,
	register word * LARp)
{
	register int 	i;
	register longword ltmp;

	for (i = 1; i <= 8; i++, LARp++, LARpp_j_1++, LARpp_j++) {
		*LARp = GSM_ADD( SASR( *LARpp_j_1, 2 ), SASR( *LARpp_j, 2 ));
		*LARp = GSM_ADD( *LARp,  SASR( *LARpp_j_1, 1));
	}
}

static void Coefficients_13_26 P3((LARpp_j_1, LARpp_j, LARp),
	register word * LARpp_j_1,
	register word * LARpp_j,
	register word * LARp)
{
	register int i;
	register longword ltmp;
	for (i = 1; i <= 8; i++, LARpp_j_1++, LARpp_j++, LARp++) {
		*LARp = GSM_ADD( SASR( *LARpp_j_1, 1), SASR( *LARpp_j, 1 ));
	}
}

static void Coefficients_27_39 P3((LARpp_j_1, LARpp_j, LARp),
	register word * LARpp_j_1,
	register word * LARpp_j,
	register word * LARp)
{
	register int i;
	register longword ltmp;

	for (i = 1; i <= 8; i++, LARpp_j_1++, LARpp_j++, LARp++) {
		*LARp = GSM_ADD( SASR( *LARpp_j_1, 2 ), SASR( *LARpp_j, 2 ));
		*LARp = GSM_ADD( *LARp, SASR( *LARpp_j, 1 ));
	}
}


static void Coefficients_40_159 P2((LARpp_j, LARp),
	register word * LARpp_j,
	register word * LARp)
{
	register int i;

	for (i = 1; i <= 8; i++, LARp++, LARpp_j++)
		*LARp = *LARpp_j;
}

/* 4.2.9.2 */

static void LARp_to_rp P1((LARp),
	register word * LARp)	/* [0..7] IN/OUT  */
/*
 *  The input of this procedure is the interpolated LARp[0..7] array.
 *  The reflection coefficients, rp[i], are used in the analysis
 *  filter and in the synthesis filter.
 */
{
	register int 		i;
	register word		temp;
	register longword	ltmp;

	for (i = 1; i <= 8; i++, LARp++) {

		/* temp = GSM_ABS( *LARp );
	         *
		 * if (temp < 11059) temp <<= 1;
		 * else if (temp < 20070) temp += 11059;
		 * else temp = GSM_ADD( temp >> 2, 26112 );
		 *
		 * *LARp = *LARp < 0 ? -temp : temp;
		 */

		if (*LARp < 0) {
			temp = *LARp == MIN_WORD ? MAX_WORD : -(*LARp);
			*LARp = - ((temp < 11059) ? temp << 1
				: ((temp < 20070) ? temp + 11059
				:  GSM_ADD( temp >> 2, 26112 )));
		} else {
			temp  = *LARp;
			*LARp =    (temp < 11059) ? temp << 1
				: ((temp < 20070) ? temp + 11059
				:  GSM_ADD( temp >> 2, 26112 ));
		}
	}
}


/* 4.2.10 */
static void Short_term_analysis_filtering P4((S,rp,k_n,s),
	struct gsm_state * S,
	register word	* rp,	/* [0..7]	IN	*/
	register int 	k_n, 	/*   k_end - k_start	*/
	register word	* s	/* [0..n-1]	IN/OUT	*/
)
/*
 *  This procedure computes the short term residual signal d[..] to be fed
 *  to the RPE-LTP loop from the s[..] signal and from the local rp[..]
 *  array (quantized reflection coefficients).  As the call of this
 *  procedure can be done in many ways (see the interpolation of the LAR
 *  coefficient), it is assumed that the computation begins with index
 *  k_start (for arrays d[..] and s[..]) and stops with index k_end
 *  (k_start and k_end are defined in 4.2.9.1).  This procedure also
 *  needs to keep the array u[0..7] in memory for each call.
 */
{
	register word		* u = S->u;
	register int		i;
	register word		di, zzz, ui, sav, rpi;
	register longword 	ltmp;

	for (; k_n--; s++) {

		di = sav = *s;

		for (i = 0; i < 8; i++) {		/* YYY */

			ui    = u[i];
			rpi   = rp[i];
			u[i]  = sav;

			zzz   = GSM_MULT_R(rpi, di);
			sav   = GSM_ADD(   ui,  zzz);

			zzz   = GSM_MULT_R(rpi, ui);
			di    = GSM_ADD(   di,  zzz );
		}

		*s = di;
	}
}

#if defined(USE_FLOAT_MUL) && defined(FAST)

static void Fast_Short_term_analysis_filtering P4((S,rp,k_n,s),
	struct gsm_state * S,
	register word	* rp,	/* [0..7]	IN	*/
	register int 	k_n, 	/*   k_end - k_start	*/
	register word	* s	/* [0..n-1]	IN/OUT	*/
)
{
	register word		* u = S->u;
	register int		i;

	float 	  uf[8],
		 rpf[8];

	register float scalef = 3.0517578125e-5;
	register float		sav, di, temp;

	for (i = 0; i < 8; ++i) {
		uf[i]  = u[i];
		rpf[i] = rp[i] * scalef;
	}
	for (; k_n--; s++) {
		sav = di = *s;
		for (i = 0; i < 8; ++i) {
			register float rpfi = rpf[i];
			register float ufi  = uf[i];

			uf[i] = sav;
			temp  = rpfi * di + ufi;
			di   += rpfi * ufi;
			sav   = temp;
		}
		*s = di;
	}
	for (i = 0; i < 8; ++i) u[i] = uf[i];
}
#endif /* ! (defined (USE_FLOAT_MUL) && defined (FAST)) */

static void Short_term_synthesis_filtering P5((S,rrp,k,wt,sr),
	struct gsm_state * S,
	register word	* rrp,	/* [0..7]	IN	*/
	register int	k,	/* k_end - k_start	*/
	register word	* wt,	/* [0..k-1]	IN	*/
	register word	* sr	/* [0..k-1]	OUT	*/
)
{
	register word		* v = S->v;
	register int		i;
	register word		sri, tmp1, tmp2;
	register longword	ltmp;	/* for GSM_ADD  & GSM_SUB */

	while (k--) {
		sri = *wt++;
		for (i = 8; i--;) {

			/* sri = GSM_SUB( sri, gsm_mult_r( rrp[i], v[i] ) );
			 */
			tmp1 = rrp[i];
			tmp2 = v[i];
			tmp2 =  ( tmp1 == MIN_WORD && tmp2 == MIN_WORD
				? MAX_WORD
				: 0x0FFFF & (( (longword)tmp1 * (longword)tmp2
					     + 16384) >> 15)) ;

			sri  = GSM_SUB( sri, tmp2 );

			/* v[i+1] = GSM_ADD( v[i], gsm_mult_r( rrp[i], sri ) );
			 */
			tmp1  = ( tmp1 == MIN_WORD && sri == MIN_WORD
				? MAX_WORD
				: 0x0FFFF & (( (longword)tmp1 * (longword)sri
					     + 16384) >> 15)) ;

			v[i+1] = GSM_ADD( v[i], tmp1);
		}
		*sr++ = v[0] = sri;
	}
}


#if defined(FAST) && defined(USE_FLOAT_MUL)

static void Fast_Short_term_synthesis_filtering P5((S,rrp,k,wt,sr),
	struct gsm_state * S,
	register word	* rrp,	/* [0..7]	IN	*/
	register int	k,	/* k_end - k_start	*/
	register word	* wt,	/* [0..k-1]	IN	*/
	register word	* sr	/* [0..k-1]	OUT	*/
)
{
	register word		* v = S->v;
	register int		i;

	float va[9], rrpa[8];
	register float scalef = 3.0517578125e-5, temp;

	for (i = 0; i < 8; ++i) {
		va[i]   = v[i];
		rrpa[i] = (float)rrp[i] * scalef;
	}
	while (k--) {
		register float sri = *wt++;
		for (i = 8; i--;) {
			sri -= rrpa[i] * va[i];
			if     (sri < -32768.) sri = -32768.;
			else if (sri > 32767.) sri =  32767.;

			temp = va[i] + rrpa[i] * sri;
			if     (temp < -32768.) temp = -32768.;
			else if (temp > 32767.) temp =  32767.;
			va[i+1] = temp;
		}
		*sr++ = va[0] = sri;
	}
	for (i = 0; i < 9; ++i) v[i] = va[i];
}

#endif /* defined(FAST) && defined(USE_FLOAT_MUL) */

void Gsm_Short_Term_Analysis_Filter P3((S,LARc,s),

	struct gsm_state * S,

	word	* LARc,		/* coded log area ratio [0..7]  IN	*/
	word	* s		/* signal [0..159]		IN/OUT	*/
)
{
	word		* LARpp_j	= S->LARpp[ S->j      ];
	word		* LARpp_j_1	= S->LARpp[ S->j ^= 1 ];

	word		LARp[8];

#undef	FILTER
#if 	defined(FAST) && defined(USE_FLOAT_MUL)
# 	define	FILTER 	(* (S->fast			\
			   ? Fast_Short_term_analysis_filtering	\
		    	   : Short_term_analysis_filtering	))

#else
# 	define	FILTER	Short_term_analysis_filtering
#endif

	Decoding_of_the_coded_Log_Area_Ratios( LARc, LARpp_j );

	Coefficients_0_12(  LARpp_j_1, LARpp_j, LARp );
	LARp_to_rp( LARp );
	FILTER( S, LARp, 13, s);

	Coefficients_13_26( LARpp_j_1, LARpp_j, LARp);
	LARp_to_rp( LARp );
	FILTER( S, LARp, 14, s + 13);

	Coefficients_27_39( LARpp_j_1, LARpp_j, LARp);
	LARp_to_rp( LARp );
	FILTER( S, LARp, 13, s + 27);

	Coefficients_40_159( LARpp_j, LARp);
	LARp_to_rp( LARp );
	FILTER( S, LARp, 120, s + 40);
}

void Gsm_Short_Term_Synthesis_Filter P4((S, LARcr, wt, s),
	struct gsm_state * S,

	word	* LARcr,	/* received log area ratios [0..7] IN  */
	word	* wt,		/* received d [0..159]		   IN  */

	word	* s		/* signal   s [0..159]		  OUT  */
)
{
	word		* LARpp_j	= S->LARpp[ S->j     ];
	word		* LARpp_j_1	= S->LARpp[ S->j ^=1 ];

	word		LARp[8];

#undef	FILTER
#if 	defined(FAST) && defined(USE_FLOAT_MUL)

# 	define	FILTER 	(* (S->fast			\
			   ? Fast_Short_term_synthesis_filtering	\
		    	   : Short_term_synthesis_filtering	))
#else
#	define	FILTER	Short_term_synthesis_filtering
#endif

	Decoding_of_the_coded_Log_Area_Ratios( LARcr, LARpp_j );

	Coefficients_0_12( LARpp_j_1, LARpp_j, LARp );
	LARp_to_rp( LARp );
	FILTER( S, LARp, 13, wt, s );

	Coefficients_13_26( LARpp_j_1, LARpp_j, LARp);
	LARp_to_rp( LARp );
	FILTER( S, LARp, 14, wt + 13, s + 13 );

	Coefficients_27_39( LARpp_j_1, LARpp_j, LARp);
	LARp_to_rp( LARp );
	FILTER( S, LARp, 13, wt + 27, s + 27 );

	Coefficients_40_159( LARpp_j, LARp );
	LARp_to_rp( LARp );
	FILTER(S, LARp, 120, wt + 40, s + 40);
}

/****** begin "table.c" *****/

/*  Most of these tables are inlined at their point of use.
 */

/*  4.4 TABLES USED IN THE FIXED POINT IMPLEMENTATION OF THE RPE-LTP
 *      CODER AND DECODER
 *
 *	(Most of them inlined, so watch out.)
 */

/*  Table 4.1  Quantization of the Log.-Area Ratios
 */
/* i 		     1      2      3        4      5      6        7       8 */
word gsm_A[8]   = {20480, 20480, 20480,  20480,  13964,  15360,   8534,  9036};
word gsm_B[8]   = {    0,     0,  2048,  -2560,     94,  -1792,   -341, -1144};
word gsm_MIC[8] = { -32,   -32,   -16,    -16,     -8,     -8,     -4,    -4 };
word gsm_MAC[8] = {  31,    31,    15,     15,      7,      7,      3,     3 };


/*  Table 4.2  Tabulation  of 1/A[1..8]
 */
word gsm_INVA[8]={ 13107, 13107,  13107, 13107,  19223, 17476,  31454, 29708 };


/*   Table 4.3a  Decision level of the LTP gain quantizer
 */
/*  bc		      0	        1	  2	     3			*/
word gsm_DLB[4] = {  6554,    16384,	26214,	   32767	};


/*   Table 4.3b   Quantization levels of the LTP gain quantizer
 */
/* bc		      0          1        2          3			*/
word gsm_QLB[4] = {  3277,    11469,	21299,	   32767	};


/*   Table 4.4	 Coefficients of the weighting filter
 */
/* i		    0      1   2    3   4      5      6     7   8   9    10  */
word gsm_H[11] = {-134, -374, 0, 2054, 5741, 8192, 5741, 2054, 0, -374, -134 };


/*   Table 4.5 	 Normalized inverse mantissa used to compute xM/xmax 
 */
/* i		 	0        1    2      3      4      5     6      7   */
word gsm_NRFAC[8] = { 29128, 26215, 23832, 21846, 20165, 18725, 17476, 16384 };


/*   Table 4.6	 Normalized direct mantissa used to compute xM/xmax
 */
/* i                  0      1       2      3      4      5      6      7   */
word gsm_FAC[8]	= { 18431, 20479, 22527, 24575, 26623, 28671, 30719, 32767 };


/***** Squeak Interface Code Starts Here *****/

/* glue functions */

void gsmEncode(
  usqIntptr_t state, sqInt frameCount,
  usqIntptr_t src, sqInt srcIndex, sqInt srcSize,
  usqIntptr_t dst, sqInt dstIndex, sqInt dstSize,
  sqInt *srcDelta, sqInt *dstDelta) {
  	sqInt maxSrcFrames, maxDstFrames, i;
	usqIntptr_t srcPtr, dstPtr;

	maxSrcFrames = (srcSize + 1 - srcIndex) / 160;
	maxDstFrames = (dstSize + 1 - dstIndex) / 33;
	if (frameCount > maxSrcFrames) frameCount = maxSrcFrames;
	if (frameCount > maxDstFrames) frameCount = maxDstFrames;

	srcPtr = src + 4 + ((srcIndex - 1) * 2);
	dstPtr = dst + 4 + (dstIndex - 1);
	for (i = 1; i <= frameCount; i++) {
		gsm_encode((gsm) state, (short *) srcPtr, (unsigned char *) dstPtr);
		srcPtr += 160 * 2;
		dstPtr += 33;
	}
	*srcDelta = frameCount * 160;
	*dstDelta = frameCount * 33;
}

void gsmDecode(
  usqIntptr_t state, sqInt frameCount,
  usqIntptr_t src, sqInt srcIndex, sqInt srcSize,
  usqIntptr_t dst, sqInt dstIndex, sqInt dstSize,
  sqInt *srcDelta, sqInt *dstDelta) {
  	sqInt maxSrcFrames, maxDstFrames, i;
	usqIntptr_t srcPtr, dstPtr;

	maxSrcFrames = (srcSize + 1 - srcIndex) / 33;
	maxDstFrames = (dstSize + 1 - dstIndex) / 160;
	if (frameCount > maxSrcFrames) frameCount = maxSrcFrames;
	if (frameCount > maxDstFrames) frameCount = maxDstFrames;

	srcPtr = src + 4 + (srcIndex - 1);
	dstPtr = dst + 4 + ((dstIndex - 1) * 2);
	for (i = 1; i <= frameCount; i++) {
		gsm_decode((gsm) state, (unsigned char *) srcPtr, (short *) dstPtr);
		srcPtr += 33;
		dstPtr += 160 * 2;
	}
	*srcDelta = frameCount * 33;
	*dstDelta = frameCount * 160;
}

void gsmInitState(usqIntptr_t state) {
	/* Initialize the given GSM state record. */
	memset((char *) state, 0, sizeof(struct gsm_state));
	((gsm) state)->nrp = 40;
}

	/* Return the size of a GSM state record in bytes. */
sqInt gsmStateBytes(void) { return sizeof(struct gsm_state); }
