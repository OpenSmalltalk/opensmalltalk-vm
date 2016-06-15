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

/*
 * Discrete Cosine Tansform (DCT) for subband synthesis
 * optimized for machines with no auto-increment. 
 * The performance is highly compiler dependend. Maybe
 * the dct64.c version for 'normal' processor may be faster
 * even for Intel processors.
 */

#include "mpeg3audio.h"
#include "tables.h"

#include <math.h>

int mpeg3audio_dct64_1(float *out0, float *out1, float *b1, float *b2, float *samples)
{
	register float *costab = mpeg3_pnts[0];

	b1[0x00] = samples[0x00] + samples[0x1F];
	b1[0x01] = samples[0x01] + samples[0x1E];
	b1[0x1F] = (samples[0x00] - samples[0x1F]) * costab[0x0];
	b1[0x1E] = (samples[0x01] - samples[0x1E]) * costab[0x1];

	b1[0x02] = samples[0x02] + samples[0x1D];
	b1[0x03] = samples[0x03] + samples[0x1C];
	b1[0x1D] = (samples[0x02] - samples[0x1D]) * costab[0x2];
	b1[0x1C] = (samples[0x03] - samples[0x1C]) * costab[0x3];

	b1[0x04] = samples[0x04] + samples[0x1B];
	b1[0x05] = samples[0x05] + samples[0x1A];
	b1[0x1B] = (samples[0x04] - samples[0x1B]) * costab[0x4];
	b1[0x1A] = (samples[0x05] - samples[0x1A]) * costab[0x5];

	b1[0x06] = samples[0x06] + samples[0x19];
	b1[0x07] = samples[0x07] + samples[0x18];
	b1[0x19] = (samples[0x06] - samples[0x19]) * costab[0x6];
	b1[0x18] = (samples[0x07] - samples[0x18]) * costab[0x7];

	b1[0x08] = samples[0x08] + samples[0x17];
	b1[0x09] = samples[0x09] + samples[0x16];
	b1[0x17] = (samples[0x08] - samples[0x17]) * costab[0x8];
	b1[0x16] = (samples[0x09] - samples[0x16]) * costab[0x9];

	b1[0x0A] = samples[0x0A] + samples[0x15];
	b1[0x0B] = samples[0x0B] + samples[0x14];
	b1[0x15] = (samples[0x0A] - samples[0x15]) * costab[0xA];
	b1[0x14] = (samples[0x0B] - samples[0x14]) * costab[0xB];

	b1[0x0C] = samples[0x0C] + samples[0x13];
	b1[0x0D] = samples[0x0D] + samples[0x12];
	b1[0x13] = (samples[0x0C] - samples[0x13]) * costab[0xC];
	b1[0x12] = (samples[0x0D] - samples[0x12]) * costab[0xD];

	b1[0x0E] = samples[0x0E] + samples[0x11];
	b1[0x0F] = samples[0x0F] + samples[0x10];
	b1[0x11] = (samples[0x0E] - samples[0x11]) * costab[0xE];
	b1[0x10] = (samples[0x0F] - samples[0x10]) * costab[0xF];

	costab = mpeg3_pnts[1];

	b2[0x00] = b1[0x00] + b1[0x0F]; 
	b2[0x01] = b1[0x01] + b1[0x0E]; 
	b2[0x0F] = (b1[0x00] - b1[0x0F]) * costab[0];
	b2[0x0E] = (b1[0x01] - b1[0x0E]) * costab[1];

	b2[0x02] = b1[0x02] + b1[0x0D]; 
	b2[0x03] = b1[0x03] + b1[0x0C]; 
	b2[0x0D] = (b1[0x02] - b1[0x0D]) * costab[2];
	b2[0x0C] = (b1[0x03] - b1[0x0C]) * costab[3];

	b2[0x04] = b1[0x04] + b1[0x0B]; 
	b2[0x05] = b1[0x05] + b1[0x0A]; 
	b2[0x0B] = (b1[0x04] - b1[0x0B]) * costab[4];
	b2[0x0A] = (b1[0x05] - b1[0x0A]) * costab[5];

	b2[0x06] = b1[0x06] + b1[0x09]; 
	b2[0x07] = b1[0x07] + b1[0x08]; 
	b2[0x09] = (b1[0x06] - b1[0x09]) * costab[6];
	b2[0x08] = (b1[0x07] - b1[0x08]) * costab[7];

	/* */

	b2[0x10] = b1[0x10] + b1[0x1F];
	b2[0x11] = b1[0x11] + b1[0x1E];
	b2[0x1F] = (b1[0x1F] - b1[0x10]) * costab[0];
	b2[0x1E] = (b1[0x1E] - b1[0x11]) * costab[1];

	b2[0x12] = b1[0x12] + b1[0x1D];
	b2[0x13] = b1[0x13] + b1[0x1C];
	b2[0x1D] = (b1[0x1D] - b1[0x12]) * costab[2];
	b2[0x1C] = (b1[0x1C] - b1[0x13]) * costab[3];

	b2[0x14] = b1[0x14] + b1[0x1B];
	b2[0x15] = b1[0x15] + b1[0x1A];
	b2[0x1B] = (b1[0x1B] - b1[0x14]) * costab[4];
	b2[0x1A] = (b1[0x1A] - b1[0x15]) * costab[5];

	b2[0x16] = b1[0x16] + b1[0x19];
	b2[0x17] = b1[0x17] + b1[0x18];
	b2[0x19] = (b1[0x19] - b1[0x16]) * costab[6];
	b2[0x18] = (b1[0x18] - b1[0x17]) * costab[7];

 	costab = mpeg3_pnts[2];

	b1[0x00] = b2[0x00] + b2[0x07];
	b1[0x07] = (b2[0x00] - b2[0x07]) * costab[0];
	b1[0x01] = b2[0x01] + b2[0x06];
	b1[0x06] = (b2[0x01] - b2[0x06]) * costab[1];
	b1[0x02] = b2[0x02] + b2[0x05];
	b1[0x05] = (b2[0x02] - b2[0x05]) * costab[2];
	b1[0x03] = b2[0x03] + b2[0x04];
	b1[0x04] = (b2[0x03] - b2[0x04]) * costab[3];

	b1[0x08] = b2[0x08] + b2[0x0F];
	b1[0x0F] = (b2[0x0F] - b2[0x08]) * costab[0];
	b1[0x09] = b2[0x09] + b2[0x0E];
	b1[0x0E] = (b2[0x0E] - b2[0x09]) * costab[1];
	b1[0x0A] = b2[0x0A] + b2[0x0D];
	b1[0x0D] = (b2[0x0D] - b2[0x0A]) * costab[2];
	b1[0x0B] = b2[0x0B] + b2[0x0C];
	b1[0x0C] = (b2[0x0C] - b2[0x0B]) * costab[3];

	b1[0x10] = b2[0x10] + b2[0x17];
	b1[0x17] = (b2[0x10] - b2[0x17]) * costab[0];
	b1[0x11] = b2[0x11] + b2[0x16];
	b1[0x16] = (b2[0x11] - b2[0x16]) * costab[1];
	b1[0x12] = b2[0x12] + b2[0x15];
	b1[0x15] = (b2[0x12] - b2[0x15]) * costab[2];
	b1[0x13] = b2[0x13] + b2[0x14];
	b1[0x14] = (b2[0x13] - b2[0x14]) * costab[3];

	b1[0x18] = b2[0x18] + b2[0x1F];
	b1[0x1F] = (b2[0x1F] - b2[0x18]) * costab[0];
	b1[0x19] = b2[0x19] + b2[0x1E];
	b1[0x1E] = (b2[0x1E] - b2[0x19]) * costab[1];
	b1[0x1A] = b2[0x1A] + b2[0x1D];
	b1[0x1D] = (b2[0x1D] - b2[0x1A]) * costab[2];
	b1[0x1B] = b2[0x1B] + b2[0x1C];
	b1[0x1C] = (b2[0x1C] - b2[0x1B]) * costab[3];

	{
		register float const cos0 = mpeg3_pnts[3][0];
  		register float const cos1 = mpeg3_pnts[3][1];

		b2[0x00] = b1[0x00] + b1[0x03];
		b2[0x03] = (b1[0x00] - b1[0x03]) * cos0;
		b2[0x01] = b1[0x01] + b1[0x02];
		b2[0x02] = (b1[0x01] - b1[0x02]) * cos1;

		b2[0x04] = b1[0x04] + b1[0x07];
		b2[0x07] = (b1[0x07] - b1[0x04]) * cos0;
		b2[0x05] = b1[0x05] + b1[0x06];
		b2[0x06] = (b1[0x06] - b1[0x05]) * cos1;

		b2[0x08] = b1[0x08] + b1[0x0B];
		b2[0x0B] = (b1[0x08] - b1[0x0B]) * cos0;
		b2[0x09] = b1[0x09] + b1[0x0A];
		b2[0x0A] = (b1[0x09] - b1[0x0A]) * cos1;

		b2[0x0C] = b1[0x0C] + b1[0x0F];
		b2[0x0F] = (b1[0x0F] - b1[0x0C]) * cos0;
		b2[0x0D] = b1[0x0D] + b1[0x0E];
		b2[0x0E] = (b1[0x0E] - b1[0x0D]) * cos1;

		b2[0x10] = b1[0x10] + b1[0x13];
		b2[0x13] = (b1[0x10] - b1[0x13]) * cos0;
		b2[0x11] = b1[0x11] + b1[0x12];
		b2[0x12] = (b1[0x11] - b1[0x12]) * cos1;

		b2[0x14] = b1[0x14] + b1[0x17];
		b2[0x17] = (b1[0x17] - b1[0x14]) * cos0;
		b2[0x15] = b1[0x15] + b1[0x16];
		b2[0x16] = (b1[0x16] - b1[0x15]) * cos1;

		b2[0x18] = b1[0x18] + b1[0x1B];
		b2[0x1B] = (b1[0x18] - b1[0x1B]) * cos0;
		b2[0x19] = b1[0x19] + b1[0x1A];
		b2[0x1A] = (b1[0x19] - b1[0x1A]) * cos1;

		b2[0x1C] = b1[0x1C] + b1[0x1F];
		b2[0x1F] = (b1[0x1F] - b1[0x1C]) * cos0;
		b2[0x1D] = b1[0x1D] + b1[0x1E];
		b2[0x1E] = (b1[0x1E] - b1[0x1D]) * cos1;
 	}

 	{
		register float const cos0 = mpeg3_pnts[4][0];

		b1[0x00] = b2[0x00] + b2[0x01];
		b1[0x01] = (b2[0x00] - b2[0x01]) * cos0;
		b1[0x02] = b2[0x02] + b2[0x03];
		b1[0x03] = (b2[0x03] - b2[0x02]) * cos0;
		b1[0x02] += b1[0x03];

		b1[0x04] = b2[0x04] + b2[0x05];
		b1[0x05] = (b2[0x04] - b2[0x05]) * cos0;
		b1[0x06] = b2[0x06] + b2[0x07];
		b1[0x07] = (b2[0x07] - b2[0x06]) * cos0;
		b1[0x06] += b1[0x07];
		b1[0x04] += b1[0x06];
		b1[0x06] += b1[0x05];
		b1[0x05] += b1[0x07];

		b1[0x08] = b2[0x08] + b2[0x09];
		b1[0x09] = (b2[0x08] - b2[0x09]) * cos0;
		b1[0x0A] = b2[0x0A] + b2[0x0B];
		b1[0x0B] = (b2[0x0B] - b2[0x0A]) * cos0;
		b1[0x0A] += b1[0x0B];

		b1[0x0C] = b2[0x0C] + b2[0x0D];
		b1[0x0D] = (b2[0x0C] - b2[0x0D]) * cos0;
		b1[0x0E] = b2[0x0E] + b2[0x0F];
		b1[0x0F] = (b2[0x0F] - b2[0x0E]) * cos0;
		b1[0x0E] += b1[0x0F];
		b1[0x0C] += b1[0x0E];
		b1[0x0E] += b1[0x0D];
		b1[0x0D] += b1[0x0F];

		b1[0x10] = b2[0x10] + b2[0x11];
		b1[0x11] = (b2[0x10] - b2[0x11]) * cos0;
		b1[0x12] = b2[0x12] + b2[0x13];
		b1[0x13] = (b2[0x13] - b2[0x12]) * cos0;
		b1[0x12] += b1[0x13];

		b1[0x14] = b2[0x14] + b2[0x15];
		b1[0x15] = (b2[0x14] - b2[0x15]) * cos0;
		b1[0x16] = b2[0x16] + b2[0x17];
		b1[0x17] = (b2[0x17] - b2[0x16]) * cos0;
		b1[0x16] += b1[0x17];
		b1[0x14] += b1[0x16];
		b1[0x16] += b1[0x15];
		b1[0x15] += b1[0x17];

		b1[0x18] = b2[0x18] + b2[0x19];
		b1[0x19] = (b2[0x18] - b2[0x19]) * cos0;
		b1[0x1A] = b2[0x1A] + b2[0x1B];
		b1[0x1B] = (b2[0x1B] - b2[0x1A]) * cos0;
		b1[0x1A] += b1[0x1B];

		b1[0x1C] = b2[0x1C] + b2[0x1D];
		b1[0x1D] = (b2[0x1C] - b2[0x1D]) * cos0;
		b1[0x1E] = b2[0x1E] + b2[0x1F];
		b1[0x1F] = (b2[0x1F] - b2[0x1E]) * cos0;
		b1[0x1E] += b1[0x1F];
		b1[0x1C] += b1[0x1E];
		b1[0x1E] += b1[0x1D];
		b1[0x1D] += b1[0x1F];
 	}

	out0[0x10*16] = b1[0x00];
	out0[0x10*12] = b1[0x04];
	out0[0x10* 8] = b1[0x02];
	out0[0x10* 4] = b1[0x06];
	out0[0x10* 0] = b1[0x01];
	out1[0x10* 0] = b1[0x01];
	out1[0x10* 4] = b1[0x05];
	out1[0x10* 8] = b1[0x03];
	out1[0x10*12] = b1[0x07];

	out0[0x10*14] = b1[0x08] + b1[0x0C];
	out0[0x10*10] = b1[0x0C] + b1[0x0a];
	out0[0x10* 6] = b1[0x0A] + b1[0x0E];
	out0[0x10* 2] = b1[0x0E] + b1[0x09];
	out1[0x10* 2] = b1[0x09] + b1[0x0D];
	out1[0x10* 6] = b1[0x0D] + b1[0x0B];
	out1[0x10*10] = b1[0x0B] + b1[0x0F];
	out1[0x10*14] = b1[0x0F];

	{ 
		register float tmp;
		tmp = b1[0x18] + b1[0x1C];
		out0[0x10*15] = tmp + b1[0x10];
		out0[0x10*13] = tmp + b1[0x14];
		tmp = b1[0x1C] + b1[0x1A];
		out0[0x10*11] = tmp + b1[0x14];
		out0[0x10* 9] = tmp + b1[0x12];
		tmp = b1[0x1A] + b1[0x1E];
		out0[0x10* 7] = tmp + b1[0x12];
		out0[0x10* 5] = tmp + b1[0x16];
		tmp = b1[0x1E] + b1[0x19];
		out0[0x10* 3] = tmp + b1[0x16];
		out0[0x10* 1] = tmp + b1[0x11];
		tmp = b1[0x19] + b1[0x1D];
		out1[0x10* 1] = tmp + b1[0x11];
		out1[0x10* 3] = tmp + b1[0x15]; 
		tmp = b1[0x1D] + b1[0x1B];
		out1[0x10* 5] = tmp + b1[0x15];
		out1[0x10* 7] = tmp + b1[0x13];
		tmp = b1[0x1B] + b1[0x1F];
		out1[0x10* 9] = tmp + b1[0x13];
		out1[0x10*11] = tmp + b1[0x17];
		out1[0x10*13] = b1[0x17] + b1[0x1F];
		out1[0x10*15] = b1[0x1F];
	}
	return 0;
}

/*
 * the call via dct64 is a trick to force GCC to use
 * (new) registers for the b1,b2 pointer to the bufs[xx] field
 */
int mpeg3audio_dct64(float *a, float *b, float *c)
{
	float bufs[0x40];
	return mpeg3audio_dct64_1(a, b, bufs, bufs + 0x20, c);
}

/*//////////////////////////////////////////////////////////////// */
/* */
/* 9 Point Inverse Discrete Cosine Transform */
/* */
/* This piece of code is Copyright 1997 Mikko Tommila and is freely usable */
/* by anybody. The algorithm itself is of course in the public domain. */
/* */
/* Again derived heuristically from the 9-point WFTA. */
/* */
/* The algorithm is optimized (?) for speed, not for small rounding errors or */
/* good readability. */
/* */
/* 36 additions, 11 multiplications */
/* */
/* Again this is very likely sub-optimal. */
/* */
/* The code is optimized to use a minimum number of temporary variables, */
/* so it should compile quite well even on 8-register Intel x86 processors. */
/* This makes the code quite obfuscated and very difficult to understand. */
/* */
/* References: */
/* [1] S. Winograd: "On Computing the Discrete Fourier Transform", */
/*     Mathematics of Computation, Volume 32, Number 141, January 1978, */
/*     Pages 175-199 */


/*------------------------------------------------------------------*/
/*                                                                  */
/*    Function: Calculation of the inverse MDCT                     */
/*                                                                  */
/*------------------------------------------------------------------*/

int mpeg3audio_dct36(float *inbuf, float *o1, float *o2, float *wintab, float *tsbuf)
{
    float tmp[18];

	{
    	register float *in = inbuf;

    	in[17]+=in[16]; in[16]+=in[15]; in[15]+=in[14];
    	in[14]+=in[13]; in[13]+=in[12]; in[12]+=in[11];
    	in[11]+=in[10]; in[10]+=in[9];  in[9] +=in[8];
    	in[8] +=in[7];  in[7] +=in[6];  in[6] +=in[5];
    	in[5] +=in[4];  in[4] +=in[3];  in[3] +=in[2];
    	in[2] +=in[1];  in[1] +=in[0];

    	in[17]+=in[15]; in[15]+=in[13]; in[13]+=in[11]; in[11]+=in[9];
    	in[9] +=in[7];  in[7] +=in[5];  in[5] +=in[3];  in[3] +=in[1];


    	{
    		float t3;
    		{ 
    			float t0, t1, t2;

    			t0 = mpeg3_COS6_2 * (in[8] + in[16] - in[4]);
    			t1 = mpeg3_COS6_2 * in[12];

    			t3 = in[0];
    			t2 = t3 - t1 - t1;
    			tmp[1] = tmp[7] = t2 - t0;
    			tmp[4]          = t2 + t0 + t0;
    			t3 += t1;

    			t2 = mpeg3_COS6_1 * (in[10] + in[14] - in[2]);
    			tmp[1] -= t2;
    			tmp[7] += t2;
    		}
    		{
    			float t0, t1, t2;

    			t0 = mpeg3_cos9[0] * (in[4] + in[8] );
    			t1 = mpeg3_cos9[1] * (in[8] - in[16]);
    			t2 = mpeg3_cos9[2] * (in[4] + in[16]);

    			tmp[2] = tmp[6] = t3 - t0      - t2;
    			tmp[0] = tmp[8] = t3 + t0 + t1;
    			tmp[3] = tmp[5] = t3      - t1 + t2;
    		}
    	}
    	{
    		float t1, t2, t3;

    		t1 = mpeg3_cos18[0] * (in[2]  + in[10]);
    		t2 = mpeg3_cos18[1] * (in[10] - in[14]);
    		t3 = mpeg3_COS6_1   * in[6];

    		{
        		float t0 = t1 + t2 + t3;
        		tmp[0] += t0;
        		tmp[8] -= t0;
    		}

    		t2 -= t3;
    		t1 -= t3;

    		t3 = mpeg3_cos18[2] * (in[2] + in[14]);

    		t1 += t3;
    		tmp[3] += t1;
    		tmp[5] -= t1;

    		t2 -= t3;
    		tmp[2] += t2;
    		tmp[6] -= t2;
    	}


    	{
    		float t0, t1, t2, t3, t4, t5, t6, t7;

    		t1 = mpeg3_COS6_2 * in[13];
    		t2 = mpeg3_COS6_2 * (in[9] + in[17] - in[5]);

    		t3 = in[1] + t1;
    		t4 = in[1] - t1 - t1;
    		t5 = t4 - t2;

    		t0 = mpeg3_cos9[0] * (in[5] + in[9]);
    		t1 = mpeg3_cos9[1] * (in[9] - in[17]);

    		tmp[13] = (t4 + t2 + t2) * mpeg3_tfcos36[17-13];
    		t2 = mpeg3_cos9[2] * (in[5] + in[17]);

    		t6 = t3 - t0 - t2;
    		t0 += t3 + t1;
    		t3 += t2 - t1;

    		t2 = mpeg3_cos18[0] * (in[3]  + in[11]);
    		t4 = mpeg3_cos18[1] * (in[11] - in[15]);
    		t7 = mpeg3_COS6_1 * in[7];

    		t1 = t2 + t4 + t7;
    		tmp[17] = (t0 + t1) * mpeg3_tfcos36[17-17];
    		tmp[9]  = (t0 - t1) * mpeg3_tfcos36[17-9];
    		t1 = mpeg3_cos18[2] * (in[3] + in[15]);
    		t2 += t1 - t7;

    		tmp[14] = (t3 + t2) * mpeg3_tfcos36[17-14];
    		t0 = mpeg3_COS6_1 * (in[11] + in[15] - in[3]);
    		tmp[12] = (t3 - t2) * mpeg3_tfcos36[17-12];

    		t4 -= t1 + t7;

    		tmp[16] = (t5 - t0) * mpeg3_tfcos36[17-16];
    		tmp[10] = (t5 + t0) * mpeg3_tfcos36[17-10];
    		tmp[15] = (t6 + t4) * mpeg3_tfcos36[17-15];
    		tmp[11] = (t6 - t4) * mpeg3_tfcos36[17-11];
	    }

#define MACRO(v) \
	{ \
    	float tmpval; \
    	tmpval = tmp[(v)] + tmp[17-(v)]; \
    	out2[9+(v)] = tmpval * w[27+(v)]; \
    	out2[8-(v)] = tmpval * w[26-(v)]; \
    	tmpval = tmp[(v)] - tmp[17-(v)]; \
    	ts[SBLIMIT*(8-(v))] = out1[8-(v)] + tmpval * w[8-(v)]; \
    	ts[SBLIMIT*(9+(v))] = out1[9+(v)] + tmpval * w[9+(v)]; \
	}

		{
			register float *out2 = o2;
			register float *w = wintab;
			register float *out1 = o1;
			register float *ts = tsbuf;

			MACRO(0);
			MACRO(1);
			MACRO(2);
			MACRO(3);
			MACRO(4);
			MACRO(5);
			MACRO(6);
			MACRO(7);
			MACRO(8);
		}
	}
	return 0;
}

/*
 * new DCT12
 */
int mpeg3audio_dct12(float *in,float *rawout1,float *rawout2,register float *wi,register float *ts)
{
#define DCT12_PART1 \
            in5 = in[5*3]; \
    in5 += (in4 = in[4*3]); \
    in4 += (in3 = in[3*3]); \
    in3 += (in2 = in[2*3]); \
    in2 += (in1 = in[1*3]); \
    in1 += (in0 = in[0*3]); \
                            \
    in5 += in3; in3 += in1; \
                            \
    in2 *= mpeg3_COS6_1; \
    in3 *= mpeg3_COS6_1; \

#define DCT12_PART2 \
	in0 += in4 * mpeg3_COS6_2; \
                    	 \
	in4 = in0 + in2;     \
	in0 -= in2;          \
                    	 \
	in1 += in5 * mpeg3_COS6_2; \
                    	 \
	in5 = (in1 + in3) * mpeg3_tfcos12[0]; \
	in1 = (in1 - in3) * mpeg3_tfcos12[2]; \
                    	\
	in3 = in4 + in5;    \
	in4 -= in5;         \
                    	\
	in2 = in0 + in1;    \
	in0 -= in1;


	{
    	float in0,in1,in2,in3,in4,in5;
    	register float *out1 = rawout1;
    	ts[SBLIMIT*0] = out1[0]; ts[SBLIMIT*1] = out1[1]; ts[SBLIMIT*2] = out1[2];
    	ts[SBLIMIT*3] = out1[3]; ts[SBLIMIT*4] = out1[4]; ts[SBLIMIT*5] = out1[5];

    	DCT12_PART1

    	{
    		float tmp0,tmp1 = (in0 - in4);
    		{
        		float tmp2 = (in1 - in5) * mpeg3_tfcos12[1];
        		tmp0 = tmp1 + tmp2;
        		tmp1 -= tmp2;
    		}
    		ts[(17-1)*SBLIMIT] = out1[17-1] + tmp0 * wi[11-1];
    		ts[(12+1)*SBLIMIT] = out1[12+1] + tmp0 * wi[6+1];
    		ts[(6 +1)*SBLIMIT] = out1[6 +1] + tmp1 * wi[1];
    		ts[(11-1)*SBLIMIT] = out1[11-1] + tmp1 * wi[5-1];
    	}

    	DCT12_PART2

    	ts[(17-0)*SBLIMIT] = out1[17-0] + in2 * wi[11-0];
    	ts[(12+0)*SBLIMIT] = out1[12+0] + in2 * wi[6+0];
    	ts[(12+2)*SBLIMIT] = out1[12+2] + in3 * wi[6+2];
    	ts[(17-2)*SBLIMIT] = out1[17-2] + in3 * wi[11-2];

    	ts[(6+0)*SBLIMIT]  = out1[6+0] + in0 * wi[0];
    	ts[(11-0)*SBLIMIT] = out1[11-0] + in0 * wi[5-0];
    	ts[(6+2)*SBLIMIT]  = out1[6+2] + in4 * wi[2];
    	ts[(11-2)*SBLIMIT] = out1[11-2] + in4 * wi[5-2];
    }

	in++;

	{
    	 float in0,in1,in2,in3,in4,in5;
    	 register float *out2 = rawout2;

    	 DCT12_PART1

    	 {
    		 float tmp0,tmp1 = (in0 - in4);
    		 {
        		 float tmp2 = (in1 - in5) * mpeg3_tfcos12[1];
        		 tmp0 = tmp1 + tmp2;
        		 tmp1 -= tmp2;
    		 }
    		 out2[5-1] = tmp0 * wi[11-1];
    		 out2[0+1] = tmp0 * wi[6+1];
    		 ts[(12+1)*SBLIMIT] += tmp1 * wi[1];
    		 ts[(17-1)*SBLIMIT] += tmp1 * wi[5-1];
    	 }

    	 DCT12_PART2

    	 out2[5-0] = in2 * wi[11-0];
    	 out2[0+0] = in2 * wi[6+0];
    	 out2[0+2] = in3 * wi[6+2];
    	 out2[5-2] = in3 * wi[11-2];

    	 ts[(12+0)*SBLIMIT] += in0 * wi[0];
    	 ts[(17-0)*SBLIMIT] += in0 * wi[5-0];
    	 ts[(12+2)*SBLIMIT] += in4 * wi[2];
    	 ts[(17-2)*SBLIMIT] += in4 * wi[5-2];
	}

    in++; 

	{
    	float in0,in1,in2,in3,in4,in5;
    	register float *out2 = rawout2;
    	out2[12]=out2[13]=out2[14]=out2[15]=out2[16]=out2[17]=0.0;

    	DCT12_PART1

    	{
    		float tmp0,tmp1 = (in0 - in4);
    		{
        		float tmp2 = (in1 - in5) * mpeg3_tfcos12[1];
        		tmp0 = tmp1 + tmp2;
        		tmp1 -= tmp2;
    		}
    		out2[11-1] = tmp0 * wi[11-1];
    		out2[6 +1] = tmp0 * wi[6+1];
    		out2[0+1] += tmp1 * wi[1];
    		out2[5-1] += tmp1 * wi[5-1];
    	}

    	DCT12_PART2

    	out2[11-0] = in2 * wi[11-0];
    	out2[6 +0] = in2 * wi[6+0];
    	out2[6 +2] = in3 * wi[6+2];
    	out2[11-2] = in3 * wi[11-2];

    	out2[0+0] += in0 * wi[0];
    	out2[5-0] += in0 * wi[5-0];
    	out2[0+2] += in4 * wi[2];
    	out2[5-2] += in4 * wi[5-2];
	}
	return 0;
}

/* AC3 IMDCT tables */

/* Twiddle factors for IMDCT */
static float mpeg3_xcos1[AC3_N / 4];
static float mpeg3_xsin1[AC3_N / 4];
static float mpeg3_xcos2[AC3_N / 8];
static float mpeg3_xsin2[AC3_N / 8];


/* 128 point bit-reverse LUT */
static unsigned char mpeg3_bit_reverse_512[] = 
{
	0x00, 0x40, 0x20, 0x60, 0x10, 0x50, 0x30, 0x70, 
	0x08, 0x48, 0x28, 0x68, 0x18, 0x58, 0x38, 0x78, 
	0x04, 0x44, 0x24, 0x64, 0x14, 0x54, 0x34, 0x74, 
	0x0c, 0x4c, 0x2c, 0x6c, 0x1c, 0x5c, 0x3c, 0x7c, 
	0x02, 0x42, 0x22, 0x62, 0x12, 0x52, 0x32, 0x72, 
	0x0a, 0x4a, 0x2a, 0x6a, 0x1a, 0x5a, 0x3a, 0x7a, 
	0x06, 0x46, 0x26, 0x66, 0x16, 0x56, 0x36, 0x76, 
	0x0e, 0x4e, 0x2e, 0x6e, 0x1e, 0x5e, 0x3e, 0x7e, 
	0x01, 0x41, 0x21, 0x61, 0x11, 0x51, 0x31, 0x71, 
	0x09, 0x49, 0x29, 0x69, 0x19, 0x59, 0x39, 0x79, 
	0x05, 0x45, 0x25, 0x65, 0x15, 0x55, 0x35, 0x75, 
	0x0d, 0x4d, 0x2d, 0x6d, 0x1d, 0x5d, 0x3d, 0x7d, 
	0x03, 0x43, 0x23, 0x63, 0x13, 0x53, 0x33, 0x73, 
	0x0b, 0x4b, 0x2b, 0x6b, 0x1b, 0x5b, 0x3b, 0x7b, 
	0x07, 0x47, 0x27, 0x67, 0x17, 0x57, 0x37, 0x77, 
	0x0f, 0x4f, 0x2f, 0x6f, 0x1f, 0x5f, 0x3f, 0x7f
};

static unsigned char mpeg3_bit_reverse_256[] = 
{
	0x00, 0x20, 0x10, 0x30, 0x08, 0x28, 0x18, 0x38, 
	0x04, 0x24, 0x14, 0x34, 0x0c, 0x2c, 0x1c, 0x3c, 
	0x02, 0x22, 0x12, 0x32, 0x0a, 0x2a, 0x1a, 0x3a, 
	0x06, 0x26, 0x16, 0x36, 0x0e, 0x2e, 0x1e, 0x3e, 
	0x01, 0x21, 0x11, 0x31, 0x09, 0x29, 0x19, 0x39, 
	0x05, 0x25, 0x15, 0x35, 0x0d, 0x2d, 0x1d, 0x3d, 
	0x03, 0x23, 0x13, 0x33, 0x0b, 0x2b, 0x1b, 0x3b, 
	0x07, 0x27, 0x17, 0x37, 0x0f, 0x2f, 0x1f, 0x3f
};

/* Windowing function for Modified DCT - Thank you acroread */
static float mpeg3_window[] = 
{
	0.00014, 0.00024, 0.00037, 0.00051, 0.00067, 0.00086, 0.00107, 0.00130,
	0.00157, 0.00187, 0.00220, 0.00256, 0.00297, 0.00341, 0.00390, 0.00443,
	0.00501, 0.00564, 0.00632, 0.00706, 0.00785, 0.00871, 0.00962, 0.01061,
	0.01166, 0.01279, 0.01399, 0.01526, 0.01662, 0.01806, 0.01959, 0.02121,
	0.02292, 0.02472, 0.02662, 0.02863, 0.03073, 0.03294, 0.03527, 0.03770,
	0.04025, 0.04292, 0.04571, 0.04862, 0.05165, 0.05481, 0.05810, 0.06153,
	0.06508, 0.06878, 0.07261, 0.07658, 0.08069, 0.08495, 0.08935, 0.09389,
	0.09859, 0.10343, 0.10842, 0.11356, 0.11885, 0.12429, 0.12988, 0.13563,
	0.14152, 0.14757, 0.15376, 0.16011, 0.16661, 0.17325, 0.18005, 0.18699,
	0.19407, 0.20130, 0.20867, 0.21618, 0.22382, 0.23161, 0.23952, 0.24757,
	0.25574, 0.26404, 0.27246, 0.28100, 0.28965, 0.29841, 0.30729, 0.31626,
	0.32533, 0.33450, 0.34376, 0.35311, 0.36253, 0.37204, 0.38161, 0.39126,
	0.40096, 0.41072, 0.42054, 0.43040, 0.44030, 0.45023, 0.46020, 0.47019,
	0.48020, 0.49022, 0.50025, 0.51028, 0.52031, 0.53033, 0.54033, 0.55031,
	0.56026, 0.57019, 0.58007, 0.58991, 0.59970, 0.60944, 0.61912, 0.62873,
	0.63827, 0.64774, 0.65713, 0.66643, 0.67564, 0.68476, 0.69377, 0.70269,
	0.71150, 0.72019, 0.72877, 0.73723, 0.74557, 0.75378, 0.76186, 0.76981,
	0.77762, 0.78530, 0.79283, 0.80022, 0.80747, 0.81457, 0.82151, 0.82831,
	0.83496, 0.84145, 0.84779, 0.85398, 0.86001, 0.86588, 0.87160, 0.87716,
	0.88257, 0.88782, 0.89291, 0.89785, 0.90264, 0.90728, 0.91176, 0.91610,
	0.92028, 0.92432, 0.92822, 0.93197, 0.93558, 0.93906, 0.94240, 0.94560,
	0.94867, 0.95162, 0.95444, 0.95713, 0.95971, 0.96217, 0.96451, 0.96674,
	0.96887, 0.97089, 0.97281, 0.97463, 0.97635, 0.97799, 0.97953, 0.98099,
	0.98236, 0.98366, 0.98488, 0.98602, 0.98710, 0.98811, 0.98905, 0.98994,
	0.99076, 0.99153, 0.99225, 0.99291, 0.99353, 0.99411, 0.99464, 0.99513,
	0.99558, 0.99600, 0.99639, 0.99674, 0.99706, 0.99736, 0.99763, 0.99788,
	0.99811, 0.99831, 0.99850, 0.99867, 0.99882, 0.99895, 0.99908, 0.99919,
	0.99929, 0.99938, 0.99946, 0.99953, 0.99959, 0.99965, 0.99969, 0.99974,
	0.99978, 0.99981, 0.99984, 0.99986, 0.99988, 0.99990, 0.99992, 0.99993,
	0.99994, 0.99995, 0.99996, 0.99997, 0.99998, 0.99998, 0.99998, 0.99999,
	0.99999, 0.99999, 0.99999, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000,
	1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000 
};

mpeg3_complex_t cmplx_mult(mpeg3_complex_t a, mpeg3_complex_t b)
{
	mpeg3_complex_t ret;

	ret.real = a.real * b.real - a.imag * b.imag;
	ret.imag = a.real * b.imag + a.imag * b.real;

	return ret;
}

int mpeg3audio_imdct_init(mpeg3audio_t *audio)
{
	int i, k;
	mpeg3_complex_t angle_step;
	mpeg3_complex_t current_angle;

/* Twiddle factors to turn IFFT into IMDCT */
	for(i = 0; i < AC3_N / 4; i++)
	{
		mpeg3_xcos1[i] = -cos(2.0f * M_PI * (8 * i + 1 ) / ( 8 * AC3_N)); 
		mpeg3_xsin1[i] = -sin(2.0f * M_PI * (8 * i + 1 ) / ( 8 * AC3_N));
	}
	
/* More twiddle factors to turn IFFT into IMDCT */
	for(i = 0; i < AC3_N / 8; i++)
	{
		mpeg3_xcos2[i] = -cos(2.0f * M_PI * (8 * i + 1 ) / ( 4 * AC3_N)); 
		mpeg3_xsin2[i] = -sin(2.0f * M_PI * (8 * i + 1 ) / ( 4 * AC3_N));
	}

/* Canonical twiddle factors for FFT */
	audio->ac3_w[0] = audio->ac3_w_1;
	audio->ac3_w[1] = audio->ac3_w_2;
	audio->ac3_w[2] = audio->ac3_w_4;
	audio->ac3_w[3] = audio->ac3_w_8;
	audio->ac3_w[4] = audio->ac3_w_16;
	audio->ac3_w[5] = audio->ac3_w_32;
	audio->ac3_w[6] = audio->ac3_w_64;

	for(i = 0; i < 7; i++)
	{
		angle_step.real = cos(-2.0f * M_PI / (1 << (i + 1)));
		angle_step.imag = sin(-2.0f * M_PI / (1 << (i + 1)));

		current_angle.real = 1.0f;
		current_angle.imag = 0.0f;

		for (k = 0; k < 1 << i; k++)
		{
			audio->ac3_w[i][k] = current_angle;
			current_angle = cmplx_mult(current_angle, angle_step);
		}
	}
	return 0;
}


void swap_cmplx(mpeg3_complex_t *a, mpeg3_complex_t *b)
{
	mpeg3_complex_t tmp;

	tmp = *a;
	*a = *b;
	*b = tmp;
}
 
void mpeg3audio_ac3_imdct_do_512(mpeg3audio_t *audio, 
		float data[], 
		float *y, 
		int step, 
		float *delay)
{
	int i, k;
	int p, q;
	int m;
	int two_m;
	int two_m_plus_one;

	float tmp_a_i;
	float tmp_a_r;
	float tmp_b_i;
	float tmp_b_r;

	float *y_ptr;
	float *delay_ptr;
	float *window_ptr;
	mpeg3_complex_t *buf = audio->ac3_imdct_buf;

/* Pre IFFT complex multiply plus IFFT cmplx conjugate  */
	for(i = 0; i < AC3_N / 4; i++)
	{
		buf[i].real =   (data[AC3_N / 2 - 2 * i - 1] * mpeg3_xcos1[i]) - (data[2 * i] * mpeg3_xsin1[i]);
	    buf[i].imag = -((data[2 * i] * mpeg3_xcos1[i]) + (data[AC3_N / 2 - 2 * i - 1] * mpeg3_xsin1[i]));
	}

/* Bit reversed shuffling */
	for(i = 0; i < AC3_N / 4; i++)
	{ 
		k = mpeg3_bit_reverse_512[i];
		if(k < i)
			swap_cmplx(&buf[i], &buf[k]);
	}

/* FFT Merge */
	for(m = 0; m < 7; m++)
	{
		if(m)
			two_m = (1 << m);
		else
			two_m = 1;

		two_m_plus_one = (1 << (m + 1));

		for(k = 0; k < two_m; k++)
		{
			for(i = 0; i < AC3_N / 4; i += two_m_plus_one)
			{
				p = k + i;
				q = p + two_m;
				tmp_a_r = buf[p].real;
				tmp_a_i = buf[p].imag;
				tmp_b_r = buf[q].real * audio->ac3_w[m][k].real - buf[q].imag * audio->ac3_w[m][k].imag;
				tmp_b_i = buf[q].imag * audio->ac3_w[m][k].real + buf[q].real * audio->ac3_w[m][k].imag;
				buf[p].real = tmp_a_r + tmp_b_r;
				buf[p].imag = tmp_a_i + tmp_b_i;
				buf[q].real = tmp_a_r - tmp_b_r;
				buf[q].imag = tmp_a_i - tmp_b_i;
			}
		}
	}

/* Post IFFT complex multiply  plus IFFT complex conjugate*/
	for(i = 0; i < AC3_N / 4; i++)
	{
		tmp_a_r =  buf[i].real;
		tmp_a_i = -buf[i].imag;
		buf[i].real = (tmp_a_r * mpeg3_xcos1[i])  -  (tmp_a_i  * mpeg3_xsin1[i]);
		buf[i].imag = (tmp_a_r * mpeg3_xsin1[i])  +  (tmp_a_i  * mpeg3_xcos1[i]);
	}

	y_ptr = y;
	delay_ptr = delay;
	window_ptr = mpeg3_window;

/* Window and convert to real valued signal */
	for(i = 0; i < AC3_N / 8; i++) 
	{ 
		*y_ptr = -buf[AC3_N / 8 + i].imag     * *window_ptr++ + *delay_ptr++;
		y_ptr += step;
		*y_ptr =  buf[AC3_N / 8 - i - 1].real * *window_ptr++ + *delay_ptr++;
		y_ptr += step;
	}

	for(i = 0; i < AC3_N / 8; i++) 
	{ 
		*y_ptr = -buf[i].real                * *window_ptr++ + *delay_ptr++;
		y_ptr += step;
		*y_ptr = buf[AC3_N / 4 - i - 1].imag * *window_ptr++ + *delay_ptr++;
		y_ptr += step;
	}

/* The trailing edge of the window goes into the delay line */
	delay_ptr = delay;

	for(i = 0; i < AC3_N / 8; i++)
	{
		*delay_ptr++  = -buf[AC3_N / 8 + i].real     * *--window_ptr; 
		*delay_ptr++  =  buf[AC3_N / 8 - i - 1].imag * *--window_ptr; 
	}

	for(i = 0; i < AC3_N / 8; i++) 
	{
		*delay_ptr++  =  buf[i].imag                 * *--window_ptr; 
		*delay_ptr++  = -buf[AC3_N / 4 - i - 1].real * *--window_ptr; 
	}
}

void mpeg3audio_ac3_imdct_do_256(mpeg3audio_t *audio, 
	float data[], 
	float *y, 
	int step, 
	float *delay)
{
	int i, k;
	int p, q;
	int m;
	int two_m;
	int two_m_plus_one;
	mpeg3_complex_t *buf = audio->ac3_imdct_buf;
	float *y_ptr;
	float *delay_ptr;
	float *window_ptr;

	float tmp_a_i;
	float tmp_a_r;
	float tmp_b_i;
	float tmp_b_r;

	mpeg3_complex_t *buf_1, *buf_2;

	buf_1 = &buf[0];
	buf_2 = &buf[64];

/* Pre IFFT complex multiply plus IFFT cmplx conjugate */
	for(k = 0; k < AC3_N / 8; k++)
	{
		p = 2 * (AC3_N / 4 - 2 * k - 1);
		q = 2 * (2 * k);

		buf_1[k].real =    data[p] * mpeg3_xcos2[k] - data[q] * mpeg3_xsin2[k];
	    buf_1[k].imag = - (data[q] * mpeg3_xcos2[k] + data[p] * mpeg3_xsin2[k]); 
		buf_2[k].real =    data[p + 1] * mpeg3_xcos2[k] - data[q + 1] * mpeg3_xsin2[k];
	    buf_2[k].imag = - (data[q + 1] * mpeg3_xcos2[k] + data[p + 1] * mpeg3_xsin2[k]); 
	}

/* IFFT Bit reversed shuffling */
	for(i = 0; i < AC3_N / 8; i++)
	{
		k = mpeg3_bit_reverse_256[i];
		if(k < i)
		{
			swap_cmplx(&buf_1[i], &buf_1[k]);
			swap_cmplx(&buf_2[i], &buf_2[k]);
		}
	}

/* FFT Merge */
	for(m = 0; m < 6; m++)
	{
		if(m)
			two_m = (1 << m);
		else
			two_m = 1;

		two_m_plus_one = (1 << (m + 1));

		for(k = 0; k < two_m; k++)
		{
			for(i = 0; i < AC3_N / 8; i += two_m_plus_one)
			{
				p = k + i;
				q = p + two_m;
/* Do block 1 */
				tmp_a_r = buf_1[p].real;
				tmp_a_i = buf_1[p].imag;
				tmp_b_r = buf_1[q].real * audio->ac3_w[m][k].real - buf_1[q].imag * audio->ac3_w[m][k].imag;
				tmp_b_i = buf_1[q].imag * audio->ac3_w[m][k].real + buf_1[q].real * audio->ac3_w[m][k].imag;
				buf_1[p].real = tmp_a_r + tmp_b_r;
				buf_1[p].imag = tmp_a_i + tmp_b_i;
				buf_1[q].real = tmp_a_r - tmp_b_r;
				buf_1[q].imag = tmp_a_i - tmp_b_i;

/* Do block 2 */
				tmp_a_r = buf_2[p].real;
				tmp_a_i = buf_2[p].imag;
				tmp_b_r = buf_2[q].real * audio->ac3_w[m][k].real - buf_2[q].imag * audio->ac3_w[m][k].imag;
				tmp_b_i = buf_2[q].imag * audio->ac3_w[m][k].real + buf_2[q].real * audio->ac3_w[m][k].imag;
				buf_2[p].real = tmp_a_r + tmp_b_r;
				buf_2[p].imag = tmp_a_i + tmp_b_i;
				buf_2[q].real = tmp_a_r - tmp_b_r;
				buf_2[q].imag = tmp_a_i - tmp_b_i;
			}
		}
	}

/* Post IFFT complex multiply */
	for(i = 0; i < AC3_N / 8; i++)
	{
		tmp_a_r =  buf_1[i].real;
		tmp_a_i = -buf_1[i].imag;
		buf_1[i].real = (tmp_a_r * mpeg3_xcos2[i])  -  (tmp_a_i  * mpeg3_xsin2[i]);
		buf_1[i].imag = (tmp_a_r * mpeg3_xsin2[i])  +  (tmp_a_i  * mpeg3_xcos2[i]);
		tmp_a_r =  buf_2[i].real;
		tmp_a_i = -buf_2[i].imag;
		buf_2[i].real = (tmp_a_r * mpeg3_xcos2[i])  -  (tmp_a_i  * mpeg3_xsin2[i]);
	    buf_2[i].imag = (tmp_a_r * mpeg3_xsin2[i])  +  (tmp_a_i  * mpeg3_xcos2[i]);
	}

/* Window and convert to real valued signal */
	y_ptr = y;
	delay_ptr = delay;
	window_ptr = mpeg3_window;

	for(i = 0; i < AC3_N / 8; i++) 
	{ 
		*y_ptr = -buf[AC3_N / 8 + i].imag     * *window_ptr++ + *delay_ptr++;
		y_ptr += step;
		*y_ptr =  buf[AC3_N / 8 - i - 1].real * *window_ptr++ + *delay_ptr++;
		y_ptr += step;
	}

	for(i = 0; i < AC3_N / 8; i++) 
	{ 
		*y_ptr = -buf[i].real                * *window_ptr++ + *delay_ptr++;
		y_ptr += step;
		*y_ptr = buf[AC3_N / 4 - i - 1].imag * *window_ptr++ + *delay_ptr++;
		y_ptr += step;
	}

/* The trailing edge of the window goes into the delay line */
	delay_ptr = delay;

	for(i = 0; i < AC3_N / 8; i++)
	{
		*delay_ptr++  = -buf[AC3_N / 8 + i].real     * *--window_ptr; 
		*delay_ptr++  =  buf[AC3_N / 8 - i - 1].imag * *--window_ptr; 
	}

	for(i = 0; i < AC3_N / 8; i++) 
	{
		*delay_ptr++  =  buf[i].imag                 * *--window_ptr; 
		*delay_ptr++  = -buf[AC3_N / 4 - i - 1].real * *--window_ptr; 
	}
}

int mpeg3audio_ac3_imdct(mpeg3audio_t *audio, 
		mpeg3_ac3bsi_t *bsi,
		mpeg3_ac3audblk_t *audblk, 
		mpeg3ac3_stream_samples_t samples)
{
	int i;

	for(i = 0; i < bsi->nfchans; i++)
	{
		if(audblk->blksw[i])
			mpeg3audio_ac3_imdct_do_256(audio, 
				samples[i], 
				audio->pcm_sample + audio->pcm_point + i, 
				bsi->nfchans, 
				audio->ac3_delay[i]);
		else
			mpeg3audio_ac3_imdct_do_512(audio, 
				samples[i], 
				audio->pcm_sample + audio->pcm_point + i, 
				bsi->nfchans, 
				audio->ac3_delay[i]);
	}
	audio->pcm_point += AC3_N / 2 * bsi->nfchans;
	return 0;
}
