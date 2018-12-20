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
 * most other tables are calculated on program start (which is (of course)
 * not ISO-conform) .. 
 * Layer-3 huffman table is in huffman.h
 */

#include "mpeg3audio.h"
#include "tables.h"

struct al_table alloc_0[] = {
	{4,0},{5,3},{3,-3},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},{9,-255},{10,-511},
	{11,-1023},{12,-2047},{13,-4095},{14,-8191},{15,-16383},{16,-32767},
	{4,0},{5,3},{3,-3},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},{9,-255},{10,-511},
	{11,-1023},{12,-2047},{13,-4095},{14,-8191},{15,-16383},{16,-32767},
	{4,0},{5,3},{3,-3},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},{9,-255},{10,-511},
	{11,-1023},{12,-2047},{13,-4095},{14,-8191},{15,-16383},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{2,0},{5,3},{7,5},{16,-32767},
	{2,0},{5,3},{7,5},{16,-32767},
	{2,0},{5,3},{7,5},{16,-32767},
	{2,0},{5,3},{7,5},{16,-32767} };

struct al_table alloc_1[] = {
	{4,0},{5,3},{3,-3},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},{9,-255},{10,-511},
	{11,-1023},{12,-2047},{13,-4095},{14,-8191},{15,-16383},{16,-32767},
	{4,0},{5,3},{3,-3},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},{9,-255},{10,-511},
	{11,-1023},{12,-2047},{13,-4095},{14,-8191},{15,-16383},{16,-32767},
	{4,0},{5,3},{3,-3},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},{9,-255},{10,-511},
	{11,-1023},{12,-2047},{13,-4095},{14,-8191},{15,-16383},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
	{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{3,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{16,-32767},
	{2,0},{5,3},{7,5},{16,-32767},
	{2,0},{5,3},{7,5},{16,-32767},
	{2,0},{5,3},{7,5},{16,-32767},
	{2,0},{5,3},{7,5},{16,-32767},
	{2,0},{5,3},{7,5},{16,-32767},
	{2,0},{5,3},{7,5},{16,-32767},
	{2,0},{5,3},{7,5},{16,-32767} };

struct al_table alloc_2[] = {
	{4,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},{9,-255},
	{10,-511},{11,-1023},{12,-2047},{13,-4095},{14,-8191},{15,-16383},
	{4,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},{9,-255},
	{10,-511},{11,-1023},{12,-2047},{13,-4095},{14,-8191},{15,-16383},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63} };

struct al_table alloc_3[] = {
	{4,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},{9,-255},
	{10,-511},{11,-1023},{12,-2047},{13,-4095},{14,-8191},{15,-16383},
	{4,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},{9,-255},
	{10,-511},{11,-1023},{12,-2047},{13,-4095},{14,-8191},{15,-16383},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63} };

struct al_table alloc_4[] = {
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
		{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{14,-8191},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
		{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{14,-8191},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
		{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{14,-8191},
	{4,0},{5,3},{7,5},{3,-3},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},{8,-127},
		{9,-255},{10,-511},{11,-1023},{12,-2047},{13,-4095},{14,-8191},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{3,0},{5,3},{7,5},{10,9},{4,-7},{5,-15},{6,-31},{7,-63},
	{2,0},{5,3},{7,5},{10,9},
	{2,0},{5,3},{7,5},{10,9},
	{2,0},{5,3},{7,5},{10,9},
	{2,0},{5,3},{7,5},{10,9},
	{2,0},{5,3},{7,5},{10,9},
	{2,0},{5,3},{7,5},{10,9},
	{2,0},{5,3},{7,5},{10,9},
	{2,0},{5,3},{7,5},{10,9},
	{2,0},{5,3},{7,5},{10,9},
	{2,0},{5,3},{7,5},{10,9},
	{2,0},{5,3},{7,5},{10,9},
    {2,0},{5,3},{7,5},{10,9},
    {2,0},{5,3},{7,5},{10,9},
    {2,0},{5,3},{7,5},{10,9},
    {2,0},{5,3},{7,5},{10,9},
    {2,0},{5,3},{7,5},{10,9},
    {2,0},{5,3},{7,5},{10,9},
    {2,0},{5,3},{7,5},{10,9},
    {2,0},{5,3},{7,5},{10,9}  };


int mpeg3audio_II_select_table(mpeg3audio_t *audio)
{
  	static int translate[3][2][16] =
	   {{{ 0,2,2,2,2,2,2,0,0,0,1,1,1,1,1,0},
    	 { 0,2,2,0,0,0,1,1,1,1,1,1,1,1,1,0}},
    	{{ 0,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0},
    	 { 0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0}},
    	{{ 0,3,3,3,3,3,3,0,0,0,1,1,1,1,1,0},
    	 { 0,3,3,0,0,0,1,1,1,1,1,1,1,1,1,0}}};
  	int table, sblim;
  	static struct al_table *tables[5] =
       	{alloc_0, alloc_1, alloc_2, alloc_3, alloc_4};
  	static int sblims[5] = {27, 30, 8, 12, 30};

  	if(audio->lsf) 
		table = 4;
  	else
    	table = translate[audio->sampling_frequency_code][2 - audio->channels][audio->bitrate_index];
  	sblim = sblims[table];

	audio->alloc = tables[table];
	audio->II_sblimit = sblim;
	return 0;
}

int mpeg3audio_II_step_one(mpeg3audio_t *audio, unsigned int *bit_alloc, int *scale)
{
    int stereo = audio->channels - 1;
    int sblimit = audio->II_sblimit;
    int jsbound = audio->jsbound;
    int sblimit2 = audio->II_sblimit << stereo;
    struct al_table *alloc1 = audio->alloc;
    int i, result = 0;
    unsigned int *scfsi_buf = audio->layer2_scfsi_buf;
    unsigned int *scfsi, *bita;
    int sc, step;

    bita = bit_alloc;
    if(stereo)
    {
/* Stereo */
    	for(i = jsbound;i ; i--, alloc1 += (1 << step))
    	{
        	*bita++ = (char)mpeg3bits_getbits(audio->astream, step = alloc1->bits);
        	*bita++ = (char)mpeg3bits_getbits(audio->astream, step);
    	}
    	for(i = sblimit-jsbound; i; i--, alloc1 += (1 << step))
    	{
        	bita[0] = (char)mpeg3bits_getbits(audio->astream, step = alloc1->bits);
        	bita[1] = bita[0];
        	bita += 2;
    	}
    	bita = bit_alloc;
    	scfsi = scfsi_buf;
    	for(i = sblimit2; i; i--)
        	if(*bita++) *scfsi++ = (char)mpeg3bits_getbits(audio->astream, 2);
    }
    else 
    {
/* mono */
      	for(i = sblimit; i; i--, alloc1 += (1 << step))
        *bita++ = (char)mpeg3bits_getbits(audio->astream, step = alloc1->bits);
      	bita = bit_alloc;
      	scfsi = scfsi_buf;
      	for(i = sblimit; i; i--) if (*bita++) *scfsi++ = (char)mpeg3bits_getbits(audio->astream, 2);
    }

    bita = bit_alloc;
    scfsi = scfsi_buf;
    for(i = sblimit2; i; i--) 
	{
      	if(*bita++)
        	switch(*scfsi++) 
        	{
        	  case 0: 
                	*scale++ = mpeg3bits_getbits(audio->astream, 6);
                	*scale++ = mpeg3bits_getbits(audio->astream, 6);
                	*scale++ = mpeg3bits_getbits(audio->astream, 6);
                	break;
        	  case 1 : 
                	*scale++ = sc = mpeg3bits_getbits(audio->astream, 6);
                	*scale++ = sc;
                	*scale++ = mpeg3bits_getbits(audio->astream, 6);
                	break;
        	  case 2: 
                	*scale++ = sc = mpeg3bits_getbits(audio->astream, 6);
                	*scale++ = sc;
                	*scale++ = sc;
                	break;
        	  default:              /* case 3 */
                	*scale++ = mpeg3bits_getbits(audio->astream, 6);
                	*scale++ = sc = mpeg3bits_getbits(audio->astream, 6);
                	*scale++ = sc;
                	break;
        	}
	}
	return result | mpeg3bits_error(audio->astream);
}

int mpeg3audio_II_step_two(mpeg3audio_t *audio, unsigned int *bit_alloc, float fraction[2][4][SBLIMIT], int *scale, int x1)
{
    int i, j, k, ba, result = 0;
    int channels = audio->channels;
    int sblimit = audio->II_sblimit;
    int jsbound = audio->jsbound;
    struct al_table *alloc2, *alloc1 = audio->alloc;
    unsigned int *bita = bit_alloc;
    int d1, step, test;

    for(i = 0; i < jsbound; i++, alloc1 += (1 << step))
    {
    	step = alloc1->bits;
    	for(j = 0; j < channels; j++)
    	{
        	if(ba = *bita++)
        	{
        		k = (alloc2 = alloc1 + ba)->bits;
        		if((d1 = alloc2->d) < 0) 
        		{
            		float cm = mpeg3_muls[k][scale[x1]];

            		fraction[j][0][i] = ((float)((int)mpeg3bits_getbits(audio->astream, k) + d1)) * cm;
            		fraction[j][1][i] = ((float)((int)mpeg3bits_getbits(audio->astream, k) + d1)) * cm;
            		fraction[j][2][i] = ((float)((int)mpeg3bits_getbits(audio->astream, k) + d1)) * cm;
        		}
        		else 
        		{
            		static int *table[] = 
						{0, 0, 0, mpeg3_grp_3tab, 0, mpeg3_grp_5tab, 0, 0, 0, mpeg3_grp_9tab};
            		unsigned int idx, *tab, m = scale[x1];
					
            		idx = (unsigned int)mpeg3bits_getbits(audio->astream, k);
            		tab = (unsigned int*)(table[d1] + idx + idx + idx);
            		fraction[j][0][i] = mpeg3_muls[*tab++][m];
            		fraction[j][1][i] = mpeg3_muls[*tab++][m];
            		fraction[j][2][i] = mpeg3_muls[*tab][m];  
        		}
        		scale += 3;
        	}
          	else
        		fraction[j][0][i] = fraction[j][1][i] = fraction[j][2][i] = 0.0;
    	}
    }

    for(i = jsbound; i < sblimit; i++, alloc1 += (1 << step))
    {
    	step = alloc1->bits;
/* channel 1 and channel 2 bitalloc are the same */
    	bita++;		
    	if((ba = *bita++))
    	{
        	k=(alloc2 = alloc1+ba)->bits;
        	if((d1 = alloc2->d) < 0)
        	{
        		float cm;
				
        		cm = mpeg3_muls[k][scale[x1 + 3]];
        		fraction[1][0][i] = (fraction[0][0][i] = (float)((int)mpeg3bits_getbits(audio->astream, k) + d1)) * cm;
        		fraction[1][1][i] = (fraction[0][1][i] = (float)((int)mpeg3bits_getbits(audio->astream, k) + d1)) * cm;
        		fraction[1][2][i] = (fraction[0][2][i] = (float)((int)mpeg3bits_getbits(audio->astream, k) + d1)) * cm;
        		cm = mpeg3_muls[k][scale[x1]];
        		fraction[0][0][i] *= cm; 
				fraction[0][1][i] *= cm; 
				fraction[0][2][i] *= cm;
        	}
        	else
        	{
        	  static int *table[] = {0, 0, 0, mpeg3_grp_3tab, 0, mpeg3_grp_5tab, 0, 0, 0, mpeg3_grp_9tab};
        	  unsigned int idx, *tab, m1, m2;
			  
        	  m1 = scale[x1]; 
			  m2 = scale[x1+3];
        	  idx = (unsigned int)mpeg3bits_getbits(audio->astream, k);
        	  tab = (unsigned int*)(table[d1] + idx + idx + idx);
        	  fraction[0][0][i] = mpeg3_muls[*tab][m1]; 
			  fraction[1][0][i] = mpeg3_muls[*tab++][m2];
        	  fraction[0][1][i] = mpeg3_muls[*tab][m1]; 
			  fraction[1][1][i] = mpeg3_muls[*tab++][m2];
        	  fraction[0][2][i] = mpeg3_muls[*tab][m1]; 
			  fraction[1][2][i] = mpeg3_muls[*tab][m2];
        	}
        	scale += 6;
      	}
    	else 
		{
        	fraction[0][0][i] = fraction[0][1][i] = fraction[0][2][i] =
        	fraction[1][0][i] = fraction[1][1][i] = fraction[1][2][i] = 0.0;
    	}
/* 
   should we use individual scalefac for channel 2 or
   is the current way the right one , where we just copy channel 1 to
   channel 2 ?? 
   The current 'strange' thing is, that we throw away the scalefac
   values for the second channel ...!!
-> changed .. now we use the scalefac values of channel one !! 
*/
    }

    if(sblimit > SBLIMIT) sblimit = SBLIMIT;

    for(i = sblimit; i < SBLIMIT; i++)
      	for(j = 0; j < channels; j++)
        	fraction[j][0][i] = fraction[j][1][i] = fraction[j][2][i] = 0.0;

	return result | mpeg3bits_error(audio->astream);
}

int mpeg3audio_dolayer2(mpeg3audio_t *audio)
{
	int i, j, result = 0;
	int channels = audio->channels;
	float fraction[2][4][SBLIMIT]; /* pick_table clears unused subbands */
	unsigned int bit_alloc[64];
	int scale[192];
	int single = audio->single;

 	if(audio->error_protection)
		mpeg3bits_getbits(audio->astream, 16);

	mpeg3audio_II_select_table(audio);

  	audio->jsbound = (audio->mode == MPG_MD_JOINT_STEREO) ?
     	(audio->mode_ext << 2) + 4 : audio->II_sblimit;

  	if(channels == 1 || single == 3)
    	single = 0;

  	result |= mpeg3audio_II_step_one(audio, bit_alloc, scale);

	for(i = 0; i < SCALE_BLOCK && !result; i++)
	{
    	result |= mpeg3audio_II_step_two(audio, bit_alloc, fraction, scale, i >> 2);

    	for(j = 0; j < 3; j++) 
    	{
    		if(single >= 0)
    		{
/* Monaural */
        		mpeg3audio_synth_mono(audio, fraction[single][j], audio->pcm_sample, &(audio->pcm_point));
    		}
    		else 
			{
/* Stereo */
        		int p1 = audio->pcm_point;
        		mpeg3audio_synth_stereo(audio, fraction[0][j], 0, audio->pcm_sample, &p1);
        		mpeg3audio_synth_stereo(audio, fraction[1][j], 1, audio->pcm_sample, &(audio->pcm_point));
    		}

    		if(audio->pcm_point / audio->channels >= audio->pcm_allocated - MPEG3AUDIO_PADDING * audio->channels)
			{
/* Need more room */
				mpeg3audio_replace_buffer(audio, audio->pcm_allocated + MPEG3AUDIO_PADDING * audio->channels);
			}
    	}
	}


  	return result;
}
