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
#include <stdio.h>

#ifdef HAVE_MMX

#ifdef HAVE_3Dnow
static inline void recva_mmx(unsigned char *s, unsigned char *d, int lx, int lx2, int h)
{
	__asm__(
		".align	8\n"
		"1:"
	   		"movq		(%1),	%%mm0\n"      /* 8 s */
	   		"movq		8(%1),	%%mm1\n"      /* 8 s */
	   		"movq		(%4),	%%mm2\n"      /* 8 s +lx */
	   		"movq		8(%4),	%%mm3\n"      /* 8 s +lx **/

			"pavgusb %%mm2, 	%%mm0\n"
			"addl		%3,		%1\n"
			"pavgusb %%mm3, 	%%mm1\n"

	   		"movq		(%2),	%%mm2\n"      /* 8 d */
	   		"movq		8(%2),	%%mm3\n"      /* 8 d */
			"pavgusb %%mm2, 	%%mm0\n"
			"addl		%3,		%4\n"
			"pavgusb %%mm3, 	%%mm1\n"

			"movq		%%mm0,	(%2)\n"
			"movq		%%mm1,	8(%2)\n"
			"addl		%3,		%2\n"
		"loop		1b\n"
      :
      : "c" (h), "r" (s), "r" (d), "r" (lx2), "r" (s +lx)
	);
}

static inline void recvac_mmx(unsigned char *s, unsigned char *d, int lx,int lx2, int h)
{
	__asm__(
		".align	8\n"
		"1:"
	   		"movq		(%1),	%%mm0\n"      /* 8 s */
	   		"movq		(%4),	%%mm2\n"      /* 8 s +lx */
			"addl		%3,		%1\n"
			"pavgusb %%mm2, 	%%mm0\n"
	   		"movq		(%2),	%%mm3\n"      /* 8 d */
			"addl		%3,		%4\n"
			"pavgusb %%mm3, 	%%mm0\n"
			"movq		%%mm0,	(%2)\n"
			"addl		%3,		%2\n"
		"loop		1b\n"
      :
      : "c" (h), "r" (s), "r" (d), "r" (lx2), "r" (s +lx)
	);
}

static inline void rech_mmx(unsigned char *s, unsigned char *d, int lx2, int h)
{
	__asm__ (
		".align	8\n"
		"1:"
	   		"movq		(%1),	%%mm0\n"      /* 8 s */
	   		"movq		8(%1),	%%mm1\n"      /* 8 s */
	   		"movq		1(%1),	%%mm2\n"      /* 8 s */
	   		"movq		9(%1),	%%mm3\n"      /* 8 s */

			"pavgusb 	%%mm2, 	%%mm0\n"
			"addl		%3,		%1\n"
			"pavgusb 	%%mm3, 	%%mm1\n"

			"movq		%%mm0,	(%2)\n"
			"movq		%%mm1,	8(%2)\n"
			"addl		%3,		%2\n"
		"loop		1b\n"
      :
      : "c" (h), "r" (s), "r" (d), "r" (lx2)
	);
}

static inline void rechc_mmx(unsigned char *s, unsigned char *d, int lx2, int h)
{
	__asm__ (
		".align	8\n"
		"1:"
	   		"movq		(%1),	%%mm0\n"      /* 8 s */
	   		"movq		1(%1),	%%mm2\n"      /* 8 s +1 */
			"addl		%3,		%1\n"
			"pavgusb 	%%mm2, 	%%mm0\n"
			"movq		%%mm0,	(%2)\n"
			"addl		%3,		%2\n"
		"loop		1b\n"
      :
      : "c" (h), "r" (s), "r" (d), "r" (lx2)
	);
}

static inline void recha_mmx(unsigned char *s, unsigned char *d,int lx2, int h)
{
	__asm__ (
		".align	8\n"
		"1:"
	   		"movq		(%1),	%%mm0\n"      /* 8 s */
	   		"movq		8(%1),	%%mm1\n"      /* 8 s */
	   		"movq		1(%1),	%%mm2\n"      /* 8 s */
	   		"movq		9(%1),	%%mm3\n"      /* 8 s */

			"pavgusb 	%%mm2, 	%%mm0\n"
			"addl		%3,		%1\n"
			"pavgusb 	%%mm3, 	%%mm1\n"

	   		"movq		(%2),	%%mm2\n"      /* 8 d */
	   		"movq		8(%2),	%%mm3\n"      /* 8 d */
			"pavgusb 	%%mm2, 	%%mm0\n"
			"pavgusb 	%%mm3, 	%%mm1\n"

			"movq		%%mm0,	(%2)\n"
			"movq		%%mm1,	8(%2)\n"
			"addl		%3,		%2\n"
		"loop		1b\n"
      :
      : "c" (h), "r" (s), "r" (d), "r" (lx2)
	);
}

static inline void rechac_mmx(unsigned char *s,unsigned char  *d, int lx2, int h)
{
	__asm__ (
		".align	8\n"
		"1:"
	   		"movq		(%1),	%%mm0\n"      /* 8 s */
	   		"movq		1(%1),	%%mm2\n"      /* 8 s */

			"addl		%3,		%1\n"
			"pavgusb 	%%mm2, 	%%mm0\n"

	   		"movq		(%2),	%%mm1\n"      /* 8 d */
			"pavgusb 	%%mm1, 	%%mm0\n"

			"movq		%%mm0,	(%2)\n"
			"addl		%3,		%2\n"
		"loop		1b\n"
      :
      : "c" (h), "r" (s), "r" (d), "r" (lx2)
	);
}

static inline void rec4_mmx(unsigned char *s, unsigned char *d, int lx, int lx2, int h)
{
	__asm__ __volatile__(
	   	"movq		(%1),	%%mm0\n"  /* 8 s */
	   	"movq		8(%1),	%%mm1\n"  /* 8 s */
	   	"movq		1(%1),	%%mm2\n"  /* 8 s +1*/
	   	"movq		9(%1),	%%mm3\n"  /* 8 s +1*/
		".align 8\n"
		"1:"
	   		"movq		(%4),	%%mm4\n"  /* 8 s+lx */
			"pavgusb 	%%mm2, 	%%mm0\n"
	   		"movq		8(%4),	%%mm5\n"  /* 8 s+lx */
			"pavgusb 	%%mm3, 	%%mm1\n"

	   		"movq		1(%4),	%%mm6\n"  /* 8 s+lx +1*/
			"pavgusb 	%%mm4, 	%%mm0\n"
	   		"movq		9(%4),	%%mm7\n"  /* 8 s+lx +1*/
			"pavgusb 	%%mm5, 	%%mm1\n"

			"pavgusb 	%%mm6, 	%%mm0\n"
			"addl		%3,		%4\n"
			"pavgusb 	%%mm7, 	%%mm1\n"
			"movq		%%mm0,	(%2)\n"
			"movq		%%mm6,	%%mm2\n"
			"movq		%%mm7,	%%mm3\n"
			"movq		%%mm1,	8(%2)\n"
			"movq		%%mm4,	%%mm0\n"
			"movq		%%mm5,	%%mm1\n"
			"addl		%3,		%2\n"
		"loop		1b\n"
      	:
		: "c" (h), "r" (s), "r" (d), "r" (lx2), "r" (s +lx)
	);
}

static inline void rec4c_mmx(unsigned char *s, unsigned char *d, int lx, int lx2, int h)
{
	__asm__ __volatile__(
	   	"movq		(%1),	%%mm0\n"  /* 8 s */
	   	"movq		1(%1),	%%mm2\n"  /* 8 s +1*/
		".align 8\n"
		"1:"
	   		"movq		(%4),	%%mm4\n"  /* 8 s+lx */
			"pavgusb 	%%mm2, 	%%mm0\n"

	   		"movq		1(%4),	%%mm6\n"  /* 8 s+lx +1*/
			"pavgusb 	%%mm4, 	%%mm0\n"

			"addl		%3,		%4\n"
			"pavgusb 	%%mm6, 	%%mm0\n"
			"movq		%%mm0,	(%2)\n"
			"movq		%%mm6,	%%mm2\n"
			"movq		%%mm4,	%%mm0\n"
			"addl		%3,		%2\n"
		"loop		1b\n"
      	:
		: "c" (h), "r" (s), "r" (d), "r" (lx2), "r" (s +lx)
	);
}

static inline void rec4a_mmx(unsigned char *s, unsigned char *d, int lx, int lx2, int h)
{
	__asm__ __volatile__(
	   	"movq		(%1),	%%mm0\n"  /* 8 s */
	   	"movq		8(%1),	%%mm1\n"  /* 8 s */
	   	"movq		1(%1),	%%mm2\n"  /* 8 s +1*/
	   	"movq		9(%1),	%%mm3\n"  /* 8 s +1*/
		".align 8\n"
		"1:"
	   		"movq		(%4),	%%mm4\n"  /* 8 s+lx */
			"pavgusb 	%%mm2, 	%%mm0\n"
	   		"movq		8(%4),	%%mm5\n"  /* 8 s+lx */
			"pavgusb 	%%mm3, 	%%mm1\n"

	   		"movq		1(%4),	%%mm6\n"  /* 8 s+lx +1*/
			"pavgusb 	%%mm4, 	%%mm0\n"
	   		"movq		9(%4),	%%mm7\n"  /* 8 s+lx +1*/
			"pavgusb 	%%mm5, 	%%mm1\n"
			"movq		(%2),	%%mm2\n"
			"pavgusb 	%%mm6, 	%%mm0\n"
			"movq		8(%2),	%%mm3\n"

			"pavgusb 	%%mm2, 	%%mm0\n"
			"addl		%3,		%4\n"
			"pavgusb 	%%mm3, 	%%mm1\n"
			"movq		%%mm0,	(%2)\n"

			"pavgusb 	%%mm7, 	%%mm1\n"
			"movq		%%mm6,	%%mm2\n"
			"movq		%%mm7,	%%mm3\n"
			"movq		%%mm1,	8(%2)\n"
			"movq		%%mm4,	%%mm0\n"
			"movq		%%mm5,	%%mm1\n"
			"addl		%3,		%2\n"
		"loop		1b\n"
      	:
		: "c" (h), "r" (s), "r" (d), "r" (lx2), "r" (s +lx)
	);
}

static inline void rec4ac_mmx(unsigned char *s, unsigned char  *d, int lx, int lx2, int h)
{
	__asm__ __volatile__(
	   	"movq		(%1),	%%mm0\n"  /* 8 s */
	   	"movq		1(%1),	%%mm2\n"  /* 8 s +1*/
		".align 8\n"
		"1:"
	   		"movq		(%4),	%%mm4\n"  /* 8 s+lx */
			"pavgusb 	%%mm2, 	%%mm0\n"

	   		"movq		1(%4),	%%mm6\n"  /* 8 s+lx +1*/
			"pavgusb 	%%mm4, 	%%mm0\n"
			"movq		(%2),	%%mm1\n"  /* 8 d */
			"pavgusb 	%%mm6, 	%%mm0\n"
			"addl		%3,		%4\n"
			"pavgusb 	%%mm1, 	%%mm0\n"
			"movq		%%mm6,	%%mm2\n"
			"movq		%%mm0,	(%2)\n"
			"movq		%%mm4,	%%mm0\n"
			"addl		%3,		%2\n"
		"loop		1b\n"
      	:
		: "c" (h), "r" (s), "r" (d), "r" (lx2), "r" (s +lx)
	);
}

#else  // HAVE_3DNOW
	static long long ADD_1	=	0x0101010101010101LL;
	static long long MASK_AND = 0x7f7f7f7f7f7f7f7fLL;
#endif

static inline void rec_mmx(unsigned char *s, unsigned char *d, int lx2, int h)
{
	__asm__ __volatile__(
		".align 8\n"
		"1:\t"
			"movq ( %1 ),     	%%mm0\n"			/* 8 s */
		    "movq 8( %1 ),    	%%mm2\n"			/* 16 s */
		    "movq %%mm0,  		( %2 )\n"   
			"addl %3,			%1\n"
		    "movq %%mm2,  		8( %2 )\n"   
			"decl %0\n"		
		    "leal (%2, %3), %2\n"
	 	"jnz    1b"            
		: 
		: "c" (h), "r" (s), "r" (d), "r" (lx2)
	);   
}


static inline void recc_mmx(unsigned char *s, unsigned char *d, int lx2, int h)
{
	__asm__ __volatile__(
		".align 8\n"
	    "1:\t"
	    	"movq ( %1 ),     %%mm0\n"
	      	"addl %3,   	  %1\n"
	      	"movq %%mm0,  	  ( %2 )\n"   
			"decl %0\n"
	      	"leal (%2, %3), %2\n"
	   	"jnz    1b"            
		: 
		: "c" (h), "r" (s), "r" (d), "r" (lx2)
	);   
}


static inline void reca_mmx(unsigned char *s, unsigned char  *d, int lx2, int h)
{
#ifdef HAVE_3Dnow
	__asm__ (
		".align	8\n"
		"1:"
		   	"movq		(%1),	%%mm0\n"      /* 8 s */
			"movq		(%2),	%%mm2\n"      /* 8 d */
		   	"movq		8(%1),	%%mm1\n"      /* 8 s */
		   	"movq		8(%2),	%%mm3\n"      /* 8 d */
			"pavgusb 	%%mm2, 	%%mm0\n"
			"addl		%3,		%1\n"
			"pavgusb 	%%mm3, 	%%mm1\n"

			"movq		%%mm0,	(%2)\n"
			"movq		%%mm1,	8(%2)\n"
			"addl		%3,		%2\n"
		"loop		1b\n"
		:
		: "c" (h), "r" (s), "r" (d), "r" (lx2)
	);
#else   /* No 3dnow */
	__asm__ (
  		"movq	     _MASK_AND, 	%%mm5\n"
  		"movq	     _ADD_1, 	%%mm6\n"
		"1:\t"
  			"movq        (%1),%%mm0\n"        /* Load 16 pixels from each row */
  			"movq        (%2),%%mm1\n"
  			"movq       8(%1),%%mm2\n"
  			"movq       8(%2),%%mm3\n"
  			"psrlw		$1,%%mm0\n"           /* Shift pixels down */
  			"psrlw	    $1,%%mm1\n"
  			"pand	    %%mm5,%%mm0\n"        /* Zero out significant bit */
  			"psrlw	    $1,%%mm2\n"
  			"pand	    %%mm5,%%mm1\n"
  			"psrlw	    $1,%%mm3\n"
  			"pand	    %%mm5,%%mm2\n"
  			"paddusb    %%mm1,%%mm0\n"        /* Add pixels */
  			"pand	    %%mm5,%%mm3\n"
  			"paddusb    %%mm3,%%mm2\n"
  			"paddusb    %%mm6,%%mm0\n"        /* Add 1 to results */
  			"paddusb    %%mm6,%%mm2\n"
  			"movq       %%mm0,(%2)\n"
  			"addl       %3,%1\n"
  			"movq	    %%mm2, 8(%2)\n"
  			"decl       %0\n"
  			"leal		(%2, %3), %2\n"
  		"jnz        1b\n"
		:
		: "c" (h), "r" (s), "r" (d), "r" (lx2)
	);
#endif
}


static inline void recac_mmx(unsigned char *s, unsigned char *d, int lx2, int h)
{
#ifdef HAVE_3Dnow
	__asm__ (
		".align	8\n"
		"1:"
		   	"movq		(%1),	%%mm0\n"      /* 8 s */
	   		"movq		(%2),	%%mm2\n"      /* 8 d */
			"pavgusb 	%%mm2, 	%%mm0\n"
			"addl		%3,		%1\n"
			"movq		%%mm0,	(%2)\n"
			"addl		%3,		%2\n"
		"loop		1b\n"
		:
		: "c" (h), "r" (s), "r" (d), "r" (lx2)
	);
#else /* No 3dnow */
	__asm__ (
  		"movq	     _MASK_AND, 	%%mm5\n"
  		"movq	     _ADD_1, 	%%mm6\n"
		"1:\t"
  			"movq       (%1),%%mm0\n"
  			"movq       (%2),%%mm1\n"
  			"psrlw		$1,%%mm0\n"
  			"psrlw	    $1,%%mm1\n"
  			"pand	    %%mm5,%%mm0\n"
  			"pand	    %%mm5,%%mm1\n"
  			"paddusb    %%mm1,%%mm0\n"
  			"paddusb    %%mm6,%%mm0\n"
  			"addl       %3,%1\n"
  			"movq       %%mm0,(%2)\n"
  			"decl       %0\n"
  			"leal		(%2, %3), %2\n"
  		"jnz        1b\n"
		:
		: "c" (h), "r" (s), "r" (d), "r" (lx2)
		);
#endif
}


static inline void recv_mmx(unsigned char *s, unsigned char *d, int lx, int lx2, int h)
{
#ifdef HAVE_3Dnow
	__asm__(
		".align	8\n"
		"1:"
	   		"movq		(%1),	%%mm0\n"      /* 8 s */
	   		"movq		(%4),	%%mm2\n"      /* 8 s +lx */
	   		"movq		8(%1),	%%mm1\n"      /* 8 s */
	   		"movq		8(%4),	%%mm3\n"      /* 8 s +lx **/

			"pavgusb %%mm2, 	%%mm0\n"
			"addl		%3,		%1\n"
			"pavgusb %%mm3, 	%%mm1\n"

			"movq		%%mm0,	(%2)\n"
			"addl		%3,		%4\n"
			"movq		%%mm1,	8(%2)\n"
			"addl		%3,		%2\n"
		"loop		1b\n"
      :
      : "c" (h), "r" (s), "r" (d), "r" (lx2), "r" (s +lx)
	);
#else
	__asm__ (
  		"movq	     _MASK_AND, 	%%mm5\n"
  		"movq	     _ADD_1, 	%%mm6\n"
		"1:\t"
	   		"movq		(%1),	%%mm0\n"      /* 8 s */
	   		"movq		(%4),	%%mm1\n"      /* 8 s +lx */
	   		"movq		8(%1),	%%mm2\n"      /* 8 s */
	   		"movq		8(%4),	%%mm3\n"      /* 8 s +lx **/
  			"psrlw      $1,%%mm0\n"
  			"psrlw      $1,%%mm1\n"
  			"pand       %%mm5,%%mm0\n"
  			"psrlw      $1,%%mm2\n"
  			"pand       %%mm5,%%mm1\n"
  			"psrlw      $1,%%mm3\n"
  			"pand       %%mm5,%%mm2\n"
  			"paddusb    %%mm1,%%mm0\n"
  			"pand       %%mm5,%%mm3\n"
  			"paddusb    %%mm3,%%mm2\n"
  			"paddusb    %%mm6,%%mm0\n"
  			"paddusb    %%mm6,%%mm2\n"
  			"movq       %%mm0,(%2)\n"
  			"addl       %3,%1\n"
  			"movq	    %%mm2, 8(%2)\n"
  			"addl       %3,%4\n"
  			"decl       %0\n"
  			"leal		(%2, %3), %2\n"
  		"jnz        1b\n"
      :
      : "c" (h), "r" (s), "r" (d), "r" (lx2), "r" (s +lx)
	);
#endif
}


static inline void recvc_mmx(unsigned char *s, unsigned char *d, int lx, int lx2, int h)
{
#ifdef HAVE_3Dnow
	__asm__(
		".align	8\n"
		"1:"
	   		"movq		(%1),	%%mm0\n"      /* 8 s */
	   		"movq		(%4),	%%mm2\n"      /* 8 s +lx */
			"addl		%3,		%1\n"
			"pavgusb %%mm2, 	%%mm0\n"
			"addl		%3,		%4\n"
			"movq		%%mm0,	(%2)\n"
			"addl		%3,		%2\n"
		"loop		1b\n"
      :
      : "c" (h), "r" (s), "r" (d), "r" (lx2), "r" (s +lx)
	);
#else
	__asm__ (
  		"movq	     _MASK_AND, 	%%mm5\n"
  		"movq	     _ADD_1, 	%%mm6\n"
		"1:\t"
	   		"movq		(%1),	%%mm0\n"      /* 8 s */
	   		"movq		(%4),	%%mm1\n"      /* 8 s +lx */
  			"psrlw      $1,%%mm0\n"
  			"psrlw      $1,%%mm1\n"
  			"pand       %%mm5,%%mm0\n"
  			"pand       %%mm5,%%mm1\n"
  			"paddusb    %%mm1,%%mm0\n"
  			"addl       %3,%1\n"
  			"paddusb    %%mm6,%%mm0\n"
  			"addl       %3,%4\n"
  			"movq       %%mm0,(%2)\n"
  			"decl       %0\n"
  			"leal		(%2, %3), %2\n"
  		"jnz        1b\n"
      :
      : "c" (h), "r" (s), "r" (d), "r" (lx2), "r" (s +lx)
	);
#endif
}

#endif  // HAVE_MMX

static inline void rec(unsigned char *s, unsigned char *d, int lx2, int h)
{
	int j;
# ifdef __POWERPC__
        unsigned long t1,t2,t3,t4;
#endif
	for(j = 0; j < h; j++, s += lx2, d += lx2)
	{
# ifdef __POWERPC__
        t1 = *(unsigned long *) s;
        t2 = *(((unsigned long *) s)+1);
        t3 = *(((unsigned long *) s)+2);
        t4 = *(((unsigned long *) s)+3);
        *(unsigned long *) d = t1;
        *(((unsigned long *) d)+1) = t2;
        *(((unsigned long *) d)+2) = t3;
        *(((unsigned long *) d)+3) = t4;
#else
    	d[0] = s[0]; d[1] = s[1]; d[2] = s[2]; d[3] = s[3];
    	d[4] = s[4]; d[5] = s[5]; d[6] = s[6]; d[7] = s[7];
    	d[8] = s[8]; d[9] = s[9]; d[10] = s[10]; d[11] = s[11];
    	d[12] = s[12]; d[13] = s[13]; d[14] = s[14]; d[15] = s[15];
#endif
	}
}



static inline void recc(unsigned char *s, unsigned char *d, int lx2, int h)
{
	int j;
# ifdef __POWERPC__
        long t1,t2;
#endif
	for(j = 0; j < h; j++, s += lx2, d += lx2)
	{
# ifdef __POWERPC__
        t1 = *(long *) s;
        t2 = *(((long *) s)+1);
        *(long *) d = t1;
        *(((long *) d)+1) = t2;
#else
    	d[0] = s[0]; d[1] = s[1]; d[2] = s[2]; d[3] = s[3];
    	d[4] = s[4]; d[5] = s[5]; d[6] = s[6]; d[7] = s[7];
#endif
	}
}

static inline void reca(unsigned char *s, unsigned char  *d, int lx2, int h)
{
	int j;
	for(j = 0; j < h; j++, s +=lx2, d +=lx2)
	{
    	d[0] = (unsigned int)(d[0] + s[0] + 1) >> 1;
    	d[1] = (unsigned int)(d[1] + s[1] + 1) >> 1;
    	d[2] = (unsigned int)(d[2] + s[2] + 1) >> 1;
    	d[3] = (unsigned int)(d[3] + s[3] + 1) >> 1;
    	d[4] = (unsigned int)(d[4] + s[4] + 1) >> 1;
    	d[5] = (unsigned int)(d[5] + s[5] + 1) >> 1;
    	d[6] = (unsigned int)(d[6] + s[6] + 1) >> 1;
    	d[7] = (unsigned int)(d[7] + s[7] + 1) >> 1;
    	d[8] = (unsigned int)(d[8] + s[8] + 1) >> 1;
    	d[9] = (unsigned int)(d[9] + s[9] + 1) >> 1;
    	d[10] = (unsigned int)(d[10] + s[10] + 1) >> 1;
    	d[11] = (unsigned int)(d[11] + s[11] + 1) >> 1;
    	d[12] = (unsigned int)(d[12] + s[12] + 1) >> 1;
    	d[13] = (unsigned int)(d[13] + s[13] + 1) >> 1;
    	d[14] = (unsigned int)(d[14] + s[14] + 1) >> 1;
    	d[15] = (unsigned int)(d[15] + s[15] + 1) >> 1;
	}
}

static inline void recac(unsigned char *s, unsigned char *d, int lx2, int h)
{
	int j;
	for(j = 0; j < h; j++, s += lx2, d += lx2)
	{
    	d[0] = (unsigned int)(d[0] + s[0] + 1)>>1;
    	d[1] = (unsigned int)(d[1] + s[1] + 1)>>1;
    	d[2] = (unsigned int)(d[2] + s[2] + 1)>>1;
    	d[3] = (unsigned int)(d[3] + s[3] + 1)>>1;
    	d[4] = (unsigned int)(d[4] + s[4] + 1)>>1;
    	d[5] = (unsigned int)(d[5] + s[5] + 1)>>1;
    	d[6] = (unsigned int)(d[6] + s[6] + 1)>>1;
    	d[7] = (unsigned int)(d[7] + s[7] + 1)>>1;
	}
}

static inline void recv(unsigned char *s, unsigned char *d, int lx, int lx2, int h)
{
	unsigned char *dp,*sp,*sp2;
	int j;
	sp = s;
	sp2 = s + lx;
	dp = d;
	for(j = 0; j < h; j++)
	{
    	dp[0] = (unsigned int)(sp[0] + sp2[0] + 1) >> 1;
    	dp[1] = (unsigned int)(sp[1] + sp2[1] + 1) >> 1;
    	dp[2] = (unsigned int)(sp[2] + sp2[2] + 1) >> 1;
    	dp[3] = (unsigned int)(sp[3] + sp2[3] + 1) >> 1;
    	dp[4] = (unsigned int)(sp[4] + sp2[4] + 1) >> 1;
    	dp[5] = (unsigned int)(sp[5] + sp2[5] + 1) >> 1;
    	dp[6] = (unsigned int)(sp[6] + sp2[6] + 1) >> 1;
    	dp[7] = (unsigned int)(sp[7] + sp2[7] + 1) >> 1;
    	dp[8] = (unsigned int)(sp[8] + sp2[8] + 1) >> 1;
    	dp[9] = (unsigned int)(sp[9] + sp2[9] + 1) >> 1;
    	dp[10] = (unsigned int)(sp[10] + sp2[10] + 1) >> 1;
    	dp[11] = (unsigned int)(sp[11] + sp2[11] + 1) >> 1;
    	dp[12] = (unsigned int)(sp[12] + sp2[12] + 1) >> 1;
    	dp[13] = (unsigned int)(sp[13] + sp2[13] + 1) >> 1;
    	dp[14] = (unsigned int)(sp[14] + sp2[14] + 1) >> 1;
    	dp[15] = (unsigned int)(sp[15] + sp2[15] + 1) >> 1;
    	sp+= lx2;
    	sp2+= lx2;
    	dp+= lx2;
	}
}

static inline void recvc(unsigned char *s, unsigned char *d, int lx, int lx2, int h)
{
	unsigned char *dp,*sp,*sp2;
	int j;

	sp = s;
	sp2 = s+lx;
	dp = d;
	for(j = 0; j < h; j++)
	{
    	dp[0] = (unsigned int)(sp[0]+sp2[0]+1)>>1;
    	dp[1] = (unsigned int)(sp[1]+sp2[1]+1)>>1;
    	dp[2] = (unsigned int)(sp[2]+sp2[2]+1)>>1;
    	dp[3] = (unsigned int)(sp[3]+sp2[3]+1)>>1;
    	dp[4] = (unsigned int)(sp[4]+sp2[4]+1)>>1;
    	dp[5] = (unsigned int)(sp[5]+sp2[5]+1)>>1;
    	dp[6] = (unsigned int)(sp[6]+sp2[6]+1)>>1;
    	dp[7] = (unsigned int)(sp[7]+sp2[7]+1)>>1;
    	sp+= lx2;
    	sp2+= lx2;
    	dp+= lx2;
	}
}


static inline void recva(unsigned char *s, unsigned char *d, int lx, int lx2, int h)
{
	unsigned char *dp,*sp,*sp2;
	int j;

	sp = s;
	sp2 = s+lx;
	dp = d;
	for (j=0; j<h; j++){
    	dp[0] = (dp[0] + ((unsigned int)(sp[0]+sp2[0]+1)>>1) + 1)>>1;
    	dp[1] = (dp[1] + ((unsigned int)(sp[1]+sp2[1]+1)>>1) + 1)>>1;
    	dp[2] = (dp[2] + ((unsigned int)(sp[2]+sp2[2]+1)>>1) + 1)>>1;
    	dp[3] = (dp[3] + ((unsigned int)(sp[3]+sp2[3]+1)>>1) + 1)>>1;
    	dp[4] = (dp[4] + ((unsigned int)(sp[4]+sp2[4]+1)>>1) + 1)>>1;
    	dp[5] = (dp[5] + ((unsigned int)(sp[5]+sp2[5]+1)>>1) + 1)>>1;
    	dp[6] = (dp[6] + ((unsigned int)(sp[6]+sp2[6]+1)>>1) + 1)>>1;
    	dp[7] = (dp[7] + ((unsigned int)(sp[7]+sp2[7]+1)>>1) + 1)>>1;
    	dp[8] = (dp[8] + ((unsigned int)(sp[8]+sp2[8]+1)>>1) + 1)>>1;
    	dp[9] = (dp[9] + ((unsigned int)(sp[9]+sp2[9]+1)>>1) + 1)>>1;
    	dp[10] = (dp[10] + ((unsigned int)(sp[10]+sp2[10]+1)>>1) + 1)>>1;
    	dp[11] = (dp[11] + ((unsigned int)(sp[11]+sp2[11]+1)>>1) + 1)>>1;
    	dp[12] = (dp[12] + ((unsigned int)(sp[12]+sp2[12]+1)>>1) + 1)>>1;
    	dp[13] = (dp[13] + ((unsigned int)(sp[13]+sp2[13]+1)>>1) + 1)>>1;
    	dp[14] = (dp[14] + ((unsigned int)(sp[14]+sp2[14]+1)>>1) + 1)>>1;
    	dp[15] = (dp[15] + ((unsigned int)(sp[15]+sp2[15]+1)>>1) + 1)>>1;
    	sp+= lx2;
    	sp2+= lx2;
    	dp+= lx2;
	}
}


static inline void recvac(unsigned char *s, unsigned char *d, int lx,int lx2, int h){
  unsigned char *dp,*sp,*sp2;
	int j;

  sp = s;
  sp2 = s+lx;
  dp = d;
  for (j=0; j<h; j++){
    dp[0] = (dp[0] + ((unsigned int)(sp[0]+sp2[0]+1)>>1) + 1)>>1;
    dp[1] = (dp[1] + ((unsigned int)(sp[1]+sp2[1]+1)>>1) + 1)>>1;
    dp[2] = (dp[2] + ((unsigned int)(sp[2]+sp2[2]+1)>>1) + 1)>>1;
    dp[3] = (dp[3] + ((unsigned int)(sp[3]+sp2[3]+1)>>1) + 1)>>1;
    dp[4] = (dp[4] + ((unsigned int)(sp[4]+sp2[4]+1)>>1) + 1)>>1;
    dp[5] = (dp[5] + ((unsigned int)(sp[5]+sp2[5]+1)>>1) + 1)>>1;
    dp[6] = (dp[6] + ((unsigned int)(sp[6]+sp2[6]+1)>>1) + 1)>>1;
    dp[7] = (dp[7] + ((unsigned int)(sp[7]+sp2[7]+1)>>1) + 1)>>1;
    sp+= lx2;
    sp2+= lx2;
    dp+= lx2;
  }
}


static inline void rech(unsigned char *s, unsigned char *d, int lx2, int h){
  unsigned char *dp,*sp;
  unsigned int s1,s2;
	int j;

  sp = s;
  dp = d;
  for (j=0; j<h; j++){
    s1=sp[0];
    dp[0] = (unsigned int)(s1+(s2=sp[1])+1)>>1;
    dp[1] = (unsigned int)(s2+(s1=sp[2])+1)>>1;
    dp[2] = (unsigned int)(s1+(s2=sp[3])+1)>>1;
    dp[3] = (unsigned int)(s2+(s1=sp[4])+1)>>1;
    dp[4] = (unsigned int)(s1+(s2=sp[5])+1)>>1;
    dp[5] = (unsigned int)(s2+(s1=sp[6])+1)>>1;
    dp[6] = (unsigned int)(s1+(s2=sp[7])+1)>>1;
    dp[7] = (unsigned int)(s2+(s1=sp[8])+1)>>1;
    dp[8] = (unsigned int)(s1+(s2=sp[9])+1)>>1;
    dp[9] = (unsigned int)(s2+(s1=sp[10])+1)>>1;
    dp[10] = (unsigned int)(s1+(s2=sp[11])+1)>>1;
    dp[11] = (unsigned int)(s2+(s1=sp[12])+1)>>1;
    dp[12] = (unsigned int)(s1+(s2=sp[13])+1)>>1;
    dp[13] = (unsigned int)(s2+(s1=sp[14])+1)>>1;
    dp[14] = (unsigned int)(s1+(s2=sp[15])+1)>>1;
    dp[15] = (unsigned int)(s2+sp[16]+1)>>1;
    sp+= lx2;
    dp+= lx2;
  }
}


static inline void rechc(unsigned char *s,unsigned char *d, int lx2, int h){
  unsigned char *dp,*sp;
  unsigned int s1,s2;
	int j;

  sp = s;
  dp = d;
  for (j=0; j<h; j++){
    s1=sp[0];
    dp[0] = (unsigned int)(s1+(s2=sp[1])+1)>>1;
    dp[1] = (unsigned int)(s2+(s1=sp[2])+1)>>1;
    dp[2] = (unsigned int)(s1+(s2=sp[3])+1)>>1;
    dp[3] = (unsigned int)(s2+(s1=sp[4])+1)>>1;
    dp[4] = (unsigned int)(s1+(s2=sp[5])+1)>>1;
    dp[5] = (unsigned int)(s2+(s1=sp[6])+1)>>1;
    dp[6] = (unsigned int)(s1+(s2=sp[7])+1)>>1;
    dp[7] = (unsigned int)(s2+sp[8]+1)>>1;
    sp+= lx2;
    dp+= lx2;
  }
}

static inline void recha(unsigned char *s, unsigned char *d,int lx2, int h)
{
	unsigned char *dp,*sp;
	unsigned int s1,s2;
	int j;

	sp = s;
	dp = d;
	for (j = 0; j < h; j++)
	{
    	s1 = sp[0];
    	dp[0] = (dp[0] + ((unsigned int)(s1 + (s2 = sp[1]) + 1) >> 1) + 1) >> 1;
    	dp[1] = (dp[1] + ((unsigned int)(s2 + (s1 = sp[2]) + 1) >> 1) + 1) >> 1;
    	dp[2] = (dp[2] + ((unsigned int)(s1 + (s2 = sp[3]) + 1) >> 1) + 1) >> 1;
    	dp[3] = (dp[3] + ((unsigned int)(s2 + (s1 = sp[4]) + 1) >> 1) + 1) >> 1;
    	dp[4] = (dp[4] + ((unsigned int)(s1 + (s2 = sp[5]) + 1) >> 1) + 1) >> 1;
    	dp[5] = (dp[5] + ((unsigned int)(s2 + (s1 = sp[6]) + 1) >> 1) + 1) >> 1;
    	dp[6] = (dp[6] + ((unsigned int)(s1 + (s2 = sp[7]) + 1) >> 1) + 1) >> 1;
    	dp[7] = (dp[7] + ((unsigned int)(s2 + (s1 = sp[8]) + 1) >> 1) + 1) >> 1;
    	dp[8] = (dp[8] + ((unsigned int)(s1 + (s2 = sp[9]) + 1) >> 1) + 1) >> 1;
    	dp[9] = (dp[9] + ((unsigned int)(s2 + (s1 = sp[10]) + 1) >> 1) + 1) >> 1;
    	dp[10] = (dp[10] + ((unsigned int)(s1 + (s2 = sp[11]) + 1) >> 1) + 1) >> 1;
    	dp[11] = (dp[11] + ((unsigned int)(s2 + (s1 = sp[12]) + 1) >> 1) + 1) >> 1;
    	dp[12] = (dp[12] + ((unsigned int)(s1 + (s2 = sp[13]) + 1) >> 1) + 1) >> 1;
    	dp[13] = (dp[13] + ((unsigned int)(s2 + (s1 = sp[14]) + 1) >> 1) + 1) >> 1;
    	dp[14] = (dp[14] + ((unsigned int)(s1 + (s2 = sp[15]) + 1) >> 1) + 1) >> 1;
    	dp[15] = (dp[15] + ((unsigned int)(s2 + sp[16] + 1) >> 1) + 1) >> 1;
    	sp += lx2;
    	dp += lx2;
	}
}


static inline void rechac(unsigned char *s,unsigned char  *d, int lx2, int h)
{
	unsigned char *dp,*sp;
	unsigned int s1,s2;
	int j;

	sp = s;
	dp = d;
	for(j = 0; j < h; j++)
	{
    	s1 = sp[0];
    	dp[0] = (dp[0] + ((unsigned int)(s1 + (s2 = sp[1]) + 1) >> 1) + 1) >> 1;
    	dp[1] = (dp[1] + ((unsigned int)(s2 + (s1 = sp[2]) + 1) >> 1) + 1) >> 1;
    	dp[2] = (dp[2] + ((unsigned int)(s1 + (s2 = sp[3]) + 1) >> 1) + 1) >> 1;
    	dp[3] = (dp[3] + ((unsigned int)(s2 + (s1 = sp[4]) + 1) >> 1) + 1) >> 1;
    	dp[4] = (dp[4] + ((unsigned int)(s1 + (s2 = sp[5]) + 1) >> 1) + 1) >> 1;
    	dp[5] = (dp[5] + ((unsigned int)(s2 + (s1 = sp[6]) + 1) >> 1) + 1) >> 1;
    	dp[6] = (dp[6] + ((unsigned int)(s1 + (s2 = sp[7]) + 1) >> 1) + 1) >> 1;
    	dp[7] = (dp[7] + ((unsigned int)(s2 + sp[8] + 1) >> 1) + 1) >> 1;
    	sp += lx2;
    	dp += lx2;
	}
}


static inline void rec4(unsigned char *s, unsigned char *d, int lx, int lx2, int h)
{
  unsigned char *dp,*sp,*sp2;
  unsigned int s1,s2,s3,s4;
	int j;

  sp = s;
  sp2 = s+lx;
  dp = d;
  for (j=0; j<h; j++){
    s1=sp[0]; s3=sp2[0];
    dp[0] = (unsigned int)(s1+(s2=sp[1])+s3+(s4=sp2[1])+2)>>2;
    dp[1] = (unsigned int)(s2+(s1=sp[2])+s4+(s3=sp2[2])+2)>>2;
    dp[2] = (unsigned int)(s1+(s2=sp[3])+s3+(s4=sp2[3])+2)>>2;
    dp[3] = (unsigned int)(s2+(s1=sp[4])+s4+(s3=sp2[4])+2)>>2;
    dp[4] = (unsigned int)(s1+(s2=sp[5])+s3+(s4=sp2[5])+2)>>2;
    dp[5] = (unsigned int)(s2+(s1=sp[6])+s4+(s3=sp2[6])+2)>>2;
    dp[6] = (unsigned int)(s1+(s2=sp[7])+s3+(s4=sp2[7])+2)>>2;
    dp[7] = (unsigned int)(s2+(s1=sp[8])+s4+(s3=sp2[8])+2)>>2;
    dp[8] = (unsigned int)(s1+(s2=sp[9])+s3+(s4=sp2[9])+2)>>2;
    dp[9] = (unsigned int)(s2+(s1=sp[10])+s4+(s3=sp2[10])+2)>>2;
    dp[10] = (unsigned int)(s1+(s2=sp[11])+s3+(s4=sp2[11])+2)>>2;
    dp[11] = (unsigned int)(s2+(s1=sp[12])+s4+(s3=sp2[12])+2)>>2;
    dp[12] = (unsigned int)(s1+(s2=sp[13])+s3+(s4=sp2[13])+2)>>2;
    dp[13] = (unsigned int)(s2+(s1=sp[14])+s4+(s3=sp2[14])+2)>>2;
    dp[14] = (unsigned int)(s1+(s2=sp[15])+s3+(s4=sp2[15])+2)>>2;
    dp[15] = (unsigned int)(s2+sp[16]+s4+sp2[16]+2)>>2;
    sp+= lx2;
    sp2+= lx2;
    dp+= lx2;
  }
}


static inline void rec4c(unsigned char *s,unsigned char *d, int lx, int lx2, int h)
{
  unsigned char *dp,*sp,*sp2;
  unsigned int s1,s2,s3,s4;
	int j;

  sp = s;
  sp2 = s+lx;
  dp = d;
  for (j=0; j<h; j++){
    s1=sp[0]; s3=sp2[0];
    dp[0] = (unsigned int)(s1+(s2=sp[1])+s3+(s4=sp2[1])+2)>>2;
    dp[1] = (unsigned int)(s2+(s1=sp[2])+s4+(s3=sp2[2])+2)>>2;
    dp[2] = (unsigned int)(s1+(s2=sp[3])+s3+(s4=sp2[3])+2)>>2;
    dp[3] = (unsigned int)(s2+(s1=sp[4])+s4+(s3=sp2[4])+2)>>2;
    dp[4] = (unsigned int)(s1+(s2=sp[5])+s3+(s4=sp2[5])+2)>>2;
    dp[5] = (unsigned int)(s2+(s1=sp[6])+s4+(s3=sp2[6])+2)>>2;
    dp[6] = (unsigned int)(s1+(s2=sp[7])+s3+(s4=sp2[7])+2)>>2;
    dp[7] = (unsigned int)(s2+sp[8]+s4+sp2[8]+2)>>2;
    sp+= lx2;
    sp2+= lx2;
    dp+= lx2;
  }
}


static inline void rec4a(unsigned char *s,unsigned char *d, int lx, int lx2, int h)
{
  unsigned char *dp=d, *sp=s, *sp2=s+lx;
  unsigned int s1, s2, s3, s4;
	int j;

/*
  sp = s;
  sp2 = s+lx;
  dp = d;
*/
  for (j=0; j<h; j++){
    s1=sp[0]; s3=sp2[0];
    dp[0] = (dp[0] + ((unsigned int)(s1+(s2=sp[1])+s3+(s4=sp2[1])+2)>>2) + 1)>>1;
    dp[1] = (dp[1] + ((unsigned int)(s2+(s1=sp[2])+s4+(s3=sp2[2])+2)>>2) + 1)>>1;
    dp[2] = (dp[2] + ((unsigned int)(s1+(s2=sp[3])+s3+(s4=sp2[3])+2)>>2) + 1)>>1;
    dp[3] = (dp[3] + ((unsigned int)(s2+(s1=sp[4])+s4+(s3=sp2[4])+2)>>2) + 1)>>1;
    dp[4] = (dp[4] + ((unsigned int)(s1+(s2=sp[5])+s3+(s4=sp2[5])+2)>>2) + 1)>>1;
    dp[5] = (dp[5] + ((unsigned int)(s2+(s1=sp[6])+s4+(s3=sp2[6])+2)>>2) + 1)>>1;
    dp[6] = (dp[6] + ((unsigned int)(s1+(s2=sp[7])+s3+(s4=sp2[7])+2)>>2) + 1)>>1;
    dp[7] = (dp[7] + ((unsigned int)(s2+(s1=sp[8])+s4+(s3=sp2[8])+2)>>2) + 1)>>1;
    dp[8] = (dp[8] + ((unsigned int)(s1+(s2=sp[9])+s3+(s4=sp2[9])+2)>>2) + 1)>>1;
    dp[9] = (dp[9] + ((unsigned int)(s2+(s1=sp[10])+s4+(s3=sp2[10])+2)>>2) + 1)>>1;
    dp[10] = (dp[10] + ((unsigned int)(s1+(s2=sp[11])+s3+(s4=sp2[11])+2)>>2) + 1)>>1;
    dp[11] = (dp[11] + ((unsigned int)(s2+(s1=sp[12])+s4+(s3=sp2[12])+2)>>2) + 1)>>1;
    dp[12] = (dp[12] + ((unsigned int)(s1+(s2=sp[13])+s3+(s4=sp2[13])+2)>>2) + 1)>>1;
    dp[13] = (dp[13] + ((unsigned int)(s2+(s1=sp[14])+s4+(s3=sp2[14])+2)>>2) + 1)>>1;
    dp[14] = (dp[14] + ((unsigned int)(s1+(s2=sp[15])+s3+(s4=sp2[15])+2)>>2) + 1)>>1;
    dp[15] = (dp[15] + ((unsigned int)(s2+sp[16]+s4+sp2[16]+2)>>2) + 1)>>1;
    sp+= lx2;
    sp2+= lx2;
    dp+= lx2;
  }
}


static inline void rec4ac(unsigned char *s,unsigned char  *d, int lx, int lx2, int h)
{
  unsigned char *dp=d, *sp=s, *sp2=s+lx;
  unsigned int s1,s2,s3,s4;
	int j;

/*
  sp = s;
  sp2 = s+lx;
  dp = d;
*/
	for (j=0; j<h; j++)
	{
    	s1=sp[0]; s3=sp2[0];
    	dp[0] = (dp[0] + ((unsigned int)(s1+(s2=sp[1])+s3+(s4=sp2[1])+2)>>2) + 1)>>1;
    	dp[1] = (dp[1] + ((unsigned int)(s2+(s1=sp[2])+s4+(s3=sp2[2])+2)>>2) + 1)>>1;
    	dp[2] = (dp[2] + ((unsigned int)(s1+(s2=sp[3])+s3+(s4=sp2[3])+2)>>2) + 1)>>1;
    	dp[3] = (dp[3] + ((unsigned int)(s2+(s1=sp[4])+s4+(s3=sp2[4])+2)>>2) + 1)>>1;
    	dp[4] = (dp[4] + ((unsigned int)(s1+(s2=sp[5])+s3+(s4=sp2[5])+2)>>2) + 1)>>1;
    	dp[5] = (dp[5] + ((unsigned int)(s2+(s1=sp[6])+s4+(s3=sp2[6])+2)>>2) + 1)>>1;
    	dp[6] = (dp[6] + ((unsigned int)(s1+(s2=sp[7])+s3+(s4=sp2[7])+2)>>2) + 1)>>1;
    	dp[7] = (dp[7] + ((unsigned int)(s2+sp[8]+s4+sp2[8]+2)>>2) + 1)>>1;
    	sp+= lx2;
    	sp2+= lx2;
    	dp+= lx2;
	}
}

static inline
void recon_comp(mpeg3video_t *video, 
		unsigned char *src, 
		unsigned char *dst, 
		int lx, 
		int lx2,
		int w, 
		int h, 
		int x, 
		int y, 
		int dx, 
		int dy, 
		int addflag)
{
	int switcher;
	unsigned char *s, *d;

/* half pel scaling */
	switcher = (dx & 1) << 3 | (dy & 1) << 2 | w;
	if(addflag) switcher |= 2; 
/* origins */
	s = src + lx * (y + (dy >> 1)) + x + (dx >> 1);
	d = dst + lx * y + x;

// Accelerated functions
#ifdef HAVE_MMX
	if(video->have_mmx)
	{
		switch(switcher)
		{
			case 0x3: 	reca_mmx(s, d, lx2, h);       break;
			case 0x2:	recac_mmx(s, d, lx2, h);      break;
			case 0x1:	rec_mmx(s, d, lx2, h);        break;
			case 0x0:	recc_mmx(s, d, lx2, h);       break;
			case 0x7:   recva(s, d, lx, lx2, h);  break;
			case 0x6:   recvac(s, d, lx, lx2, h); break;
			case 0x5:	recv_mmx(s, d, lx, lx2, h);   break;
			case 0x4:	recvc_mmx(s, d, lx, lx2, h);  break;
			case 0x9:	rech(s, d, lx2, h);       break;
			case 0x8:   rechc(s, d, lx2, h);      break;
		}
	}
	else
#endif
	{
		switch(switcher)
		{
			case 0x3: 	reca(s, d, lx2, h);       break;
			case 0x2:	recac(s, d, lx2, h);      break;
			case 0x1:	rec(s, d, lx2, h);        break;
			case 0x0:	recc(s, d, lx2, h);       break;
			case 0x7:   recva(s, d, lx, lx2, h);  break;
			case 0x6:   recvac(s, d, lx, lx2, h); break;
			case 0x5:	recv(s, d, lx, lx2, h);   break;
			case 0x4:	recvc(s, d, lx, lx2, h);  break;
			case 0x9:	rech(s, d, lx2, h);       break;
			case 0x8:   rechc(s, d, lx2, h);      break;
		}
	}

// Unaccelerated functions
	switch(switcher) 
	{
		case 0xb: 	recha(s, d, lx2, h);      break;
		case 0xa:	rechac(s, d, lx2, h);     break;
		case 0xf: 	rec4a(s, d, lx, lx2, h);  break;
		case 0xe:	rec4ac(s, d, lx, lx2, h); break;
		case 0xd:	rec4(s, d, lx, lx2, h);   break;
		case 0xc:	rec4c(s, d, lx, lx2, h);  break;
	 }
}

/*
	unsigned char *src[]; * prediction source buffer *
	int sfield;           * prediction source field number (0 or 1) *
	unsigned char *dst[]; * prediction destination buffer *
	int dfield;           * prediction destination field number (0 or 1)*
	int lx,lx2;           * horizontal offsets *
	int w,h;              * prediction block/sub-block width, height *
	int x,y;              * pixel co-ordinates of top-left sample in current MB *
	int dx,dy;            * horizontal, vertical motion vector *
	int addflag;          * add prediction error to prediction ? *
*/
static void recon(mpeg3video_t *video, 
		unsigned char *src[], 
		int sfield, 
	    unsigned char *dst[], 
		int dfield, 
		int lx,
		int lx2,
	    int w, 
		int h, 
		int x, 
		int y, 
		int dx, 
		int dy, 
		int addflag)
{

/* Y */
	recon_comp(video, (src[0] + (sfield ? (lx2 >> 1) : 0)), 
	       dst[0] + (dfield ? (lx2 >> 1) : 0),
           lx, lx2, w, h, x, y, dx, dy, addflag);

	if(video->chroma_format != CHROMA444)
	{
      	lx >>= 1; 
		dx /= 2; 
		lx2 >>= 1; 
		w = 0; 
		x >>= 1; 
	}

	if(video->chroma_format == CHROMA420)
	{
      	h >>= 1; 
		dy /= 2; 
		y >>= 1; 
	}

/* Cb */
	recon_comp(video, (src[1] + (sfield ? (lx2 >> 1) : 0)), 
	       dst[1] + (dfield ? (lx2 >> 1) : 0),
	       lx, lx2, w, h, x, y, dx, dy, addflag);

/* Cr */
	recon_comp(video, (src[2] + (sfield ? (lx2 >> 1) : 0)),
	       dst[2] + (dfield ? (lx2 >> 1) : 0),
           lx, lx2, w, h, x, y, dx, dy, addflag);
}

#define WIDTH 1

int mpeg3video_reconstruct(mpeg3video_t *video, 
	int bx, 
	int by, 
	int mb_type, 
	int motion_type,
	int PMV[2][2][2], 
	int mv_field_sel[2][2], 
	int dmvector[2], 
	int stwtype)
{
	int currentfield;
	unsigned char **predframe;
	int DMV[2][2];
	int stwtop, stwbot;

	stwtop = stwtype % 3; /* 0:temporal, 1 : (spat+temp) / 2, 2 : spatial */
	stwbot = stwtype / 3;

	if((mb_type & MB_FORWARD) || (video->pict_type == P_TYPE))
	{
    	if(video->pict_struct == FRAME_PICTURE)
		{
    		if((motion_type == MC_FRAME) || !(mb_type & MB_FORWARD))
			{
/* frame-based prediction */
				{
        			if(stwtop < 2)
        				recon(video, video->oldrefframe, 0, video->newframe, 0,
        	    			video->coded_picture_width, video->coded_picture_width << 1, WIDTH, 8, bx, by,
            			  	PMV[0][0][0], PMV[0][0][1], stwtop);

        			if(stwbot < 2)
        				recon(video, video->oldrefframe, 1, video->newframe, 1,
       	    				video->coded_picture_width, video->coded_picture_width << 1, WIDTH, 8, bx, by,
            				PMV[0][0][0], PMV[0][0][1], stwbot);
    		  	}
    		}
    		else if(motion_type == MC_FIELD) /* field-based prediction */
    		{
/* top field prediction */
        		if(stwtop < 2)
        			recon(video, video->oldrefframe, mv_field_sel[0][0], video->newframe, 0,
            			video->coded_picture_width << 1, video->coded_picture_width << 1, WIDTH, 8, bx, by >> 1,
            			PMV[0][0][0], PMV[0][0][1] >> 1, stwtop);

/* bottom field prediction */
        		if(stwbot < 2)
        			recon(video, video->oldrefframe, mv_field_sel[1][0], video->newframe, 1,
            			video->coded_picture_width << 1, video->coded_picture_width << 1, WIDTH, 8, bx, by >> 1, 
            			PMV[1][0][0], PMV[1][0][1] >> 1, stwbot);
    		}
    		else if(motion_type == MC_DMV)
			{ 
/* dual prime prediction */
/* calculate derived motion vectors */
        		mpeg3video_calc_dmv(video, 
					DMV,
					dmvector,
					PMV[0][0][0],
					PMV[0][0][1] >> 1);

        		if(stwtop < 2)
				{
/* predict top field from top field */
        			recon(video, video->oldrefframe, 0, video->newframe, 0, 
            			video->coded_picture_width << 1, video->coded_picture_width << 1, WIDTH, 8, bx, by>>1, 
            			PMV[0][0][0], PMV[0][0][1] >> 1, 0);

/* predict and add to top field from bottom field */
        			recon(video, video->oldrefframe, 1, video->newframe, 0, 
            			video->coded_picture_width << 1, video->coded_picture_width << 1, WIDTH, 8, bx, by>>1, 
            			DMV[0][0], DMV[0][1], 1);
        		}

        		if(stwbot < 2)
        		{
/* predict bottom field from bottom field */
        			recon(video, video->oldrefframe, 1, video->newframe, 1, 
            			video->coded_picture_width << 1, video->coded_picture_width << 1, WIDTH, 8, bx, by>>1, 
            			PMV[0][0][0], PMV[0][0][1]>>1, 0);

/* predict and add to bottom field from top field */
        			recon(video, video->oldrefframe, 0, video->newframe, 1, 
            			video->coded_picture_width << 1, video->coded_picture_width<<1, WIDTH, 8, bx, by>>1, 
            			DMV[1][0], DMV[1][1], 1);
        		}
    		}
    	  	else
/* invalid motion_type */
/*        		fprintf(stderr, "reconstruct: invalid motion_type\n"); */
				;
    	}
      	else 
      	{
/* TOP_FIELD or BOTTOM_FIELD */
/* field picture */
    		currentfield = (video->pict_struct == BOTTOM_FIELD);

/* determine which frame to use for prediction */
    		if((video->pict_type == P_TYPE) && video->secondfield
        	   && (currentfield != mv_field_sel[0][0]))
        		predframe = video->refframe; /* same frame */
    		else
        	 	predframe = video->oldrefframe; /* previous frame */

    		if((motion_type == MC_FIELD) || !(mb_type & MB_FORWARD))
    		{
/* field-based prediction */
        		if(stwtop < 2)
        			recon(video, predframe,mv_field_sel[0][0],video->newframe,0,
            			video->coded_picture_width << 1,video->coded_picture_width << 1,WIDTH,16,bx,by,
            			PMV[0][0][0],PMV[0][0][1],stwtop);
    		}
    		else 
			if(motion_type == MC_16X8)
    		{
        		if(stwtop < 2)
        		{
        			recon(video, predframe, mv_field_sel[0][0], video->newframe, 0, 
            			video->coded_picture_width << 1, video->coded_picture_width << 1, WIDTH, 8, bx, by, 
            			PMV[0][0][0], PMV[0][0][1], stwtop);

        			/* determine which frame to use for lower half prediction */
        			if((video->pict_type==P_TYPE) && video->secondfield
            		   && (currentfield!=mv_field_sel[1][0]))
            		  predframe = video->refframe; /* same frame */
        			else
            		  predframe = video->oldrefframe; /* previous frame */

        			recon(video, predframe, mv_field_sel[1][0], video->newframe, 0, 
            			video->coded_picture_width << 1, video->coded_picture_width << 1, WIDTH, 8, bx, by+8, 
            			PMV[1][0][0], PMV[1][0][1], stwtop);
        		}
    		}
    		else 
			if(motion_type == MC_DMV) /* dual prime prediction */
    		{
        		if(video->secondfield)
        		  	predframe = video->refframe; /* same frame */
        		else
        		  	predframe = video->oldrefframe; /* previous frame */

/* calculate derived motion vectors */
        		mpeg3video_calc_dmv(video, 
					DMV,
					dmvector,
					PMV[0][0][0],
					PMV[0][0][1]);

/* predict from field of same parity */
        		recon(video, video->oldrefframe, currentfield, video->newframe, 0, 
        			video->coded_picture_width << 1, video->coded_picture_width << 1, WIDTH, 16, bx, by, 
        			PMV[0][0][0], PMV[0][0][1], 0);

/* predict from field of opposite parity */
        		recon(video, predframe, !currentfield, video->newframe, 0, 
        			video->coded_picture_width << 1, video->coded_picture_width << 1, WIDTH, 16, bx, by, 
        			DMV[0][0], DMV[0][1], 1);
    		}
    		else
/* invalid motion_type */
/*        	  fprintf(stderr, "reconstruct: invalid motion_type\n"); */
			;
		}
      	stwtop = stwbot = 1;
	}

	if(mb_type & MB_BACKWARD)
	{
    	if(video->pict_struct == FRAME_PICTURE)
    	{
    		if(motion_type == MC_FRAME)
    		{
/* frame-based prediction */
        		if(stwtop < 2)
        			recon(video, video->refframe, 0, video->newframe, 0, 
            			video->coded_picture_width, video->coded_picture_width << 1, WIDTH, 8, bx, by, 
            			PMV[0][1][0], PMV[0][1][1], stwtop);

        		if(stwbot < 2)
        			recon(video, video->refframe, 1, video->newframe, 1, 
						video->coded_picture_width, video->coded_picture_width << 1, WIDTH, 8, bx, by, 
						PMV[0][1][0], PMV[0][1][1], stwbot);
    		}
    		else 
			{           
/* field-based prediction */
/* top field prediction */
				if(stwtop < 2)
				{
					recon(video, video->refframe, mv_field_sel[0][1], video->newframe, 0,
						(video->coded_picture_width << 1), (video->coded_picture_width<<1), WIDTH, 8, bx, (by >> 1),
						PMV[0][1][0], (PMV[0][1][1] >> 1), stwtop);
				}

/* bottom field prediction */
        		if(stwbot < 2)
				{
        			recon(video, video->refframe, mv_field_sel[1][1], video->newframe, 1, (video->coded_picture_width << 1),
						(video->coded_picture_width << 1), WIDTH, 8, bx, (by>>1),
						PMV[1][1][0], (PMV[1][1][1]>>1), stwbot);
				}
    		}
    	}
    	else 
		{
/* TOP_FIELD or BOTTOM_FIELD */
/* field picture */
    		if(motion_type == MC_FIELD)
			{
/* field-based prediction */
        		recon(video, video->refframe, mv_field_sel[0][1], video->newframe, 0, 
	    			video->coded_picture_width << 1, video->coded_picture_width << 1, WIDTH, 16, bx, by, 
	    			PMV[0][1][0], PMV[0][1][1], stwtop);
    		}
    		else if(motion_type==MC_16X8)
    		{
        		recon(video, video->refframe, mv_field_sel[0][1], video->newframe, 0, 
        			video->coded_picture_width << 1, video->coded_picture_width << 1, WIDTH, 8, bx, by, 
        			PMV[0][1][0], PMV[0][1][1], stwtop);

        		recon(video, video->refframe, mv_field_sel[1][1], video->newframe, 0, 
        			video->coded_picture_width << 1, video->coded_picture_width << 1, WIDTH, 8, bx, by+8, 
        			PMV[1][1][0], PMV[1][1][1], stwtop);
    		}
    		else
/* invalid motion_type */
/*        	  fprintf(stderr, "reconstruct: invalid motion_type\n"); */
			;
    	}
	} /* mb_type & MB_BACKWARD */
	return 0;
}


