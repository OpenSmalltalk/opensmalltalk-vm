/*
        ppc_tools.c - necessary ppc definition for skyeye debugger
        Copyright (C) 2003 Skyeye Develop Group
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
 * 12/21/2006   Michael.Kang  <blackfin.kang@gmail.com>
 */


#include "types.h"
#include "ppc_fpu.h"
#include "ppc_cpu.h"

extern PPC_CPU_State gCPU;

int ppc_count_leading_zeros(uint64 i)
{
	int ret;
	uint32 dd = i >> 32;
	if (dd) {
		ret = 31;
		if (dd > 0xffff) { ret -= 16; dd >>= 16; }
		if (dd > 0xff) { ret -= 8; dd >>= 8; }
		if (dd & 0xf0) { ret -= 4; dd >>= 4; }
		if (dd & 0xc) { ret -= 2; dd >>= 2; }
		if (dd & 0x2) ret--;
	} else {
		dd = (uint32)i;
		ret = 63;
		if (dd > 0xffff) { ret -= 16; dd >>= 16; }
		if (dd > 0xff) { ret -= 8; dd >>= 8; }
		if (dd & 0xf0) { ret -= 4; dd >>= 4; }
		if (dd & 0xc) { ret -= 2; dd >>= 2; }
		if (dd & 0x2) ret--;
	}
	return ret;
}

int ppc_fpu_normalize_quadro(ppc_quadro *d)
{
	int ret = d->m0 ? ppc_count_leading_zeros(d->m0) : 64 + ppc_count_leading_zeros(d->m1);
	return ret;
}

int ppc_fpu_normalize(ppc_double *d)
{
	return ppc_count_leading_zeros(d->m);
}

int ppc_fpu_normalize_single(ppc_single *s)
{
	int ret;
	uint32 dd = s->m;
	ret = 31;
	if (dd > 0xffff) { ret -= 16; dd >>= 16; }
	if (dd > 0xff) { ret -= 8; dd >>= 8; }
	if (dd & 0xf0) { ret -= 4; dd >>= 4; }
	if (dd & 0xc) { ret -= 2; dd >>= 2; }
	if (dd & 0x2) ret--;
	return ret;
}

//#include "tools/snprintf.h"
void ppc_fpu_unpack_double(ppc_double *res, uint64 d)
{
	FPD_UNPACK_VAR(d, res->s, res->e, res->m);
//	ht_printf("ud: %qx: s:%d e:%d m:%qx\n", d, res.s, res.e, res.m);
	// .124
	if (res->e == 2047) {
		if (res->m == 0) {
			res->type = ppc_fpr_Inf;
		} else {
			res->type = ppc_fpr_NaN;
		}
	} else if (res->e == 0) {
		if (res->m == 0) {
			res->type = ppc_fpr_zero;
		} else {
			// normalize denormalized exponent
			int diff = ppc_fpu_normalize(res) - 8;
			res->m <<= diff+3;
			res->e -= 1023 - 1 + diff;
			res->type = ppc_fpr_norm;
		}
	} else {
		res->e -= 1023; // unbias exponent
		res->type = ppc_fpr_norm;
		// add implied bit
		res->m |= 1ULL<<52;
		res->m <<= 3;
	}
//	ht_printf("ud: %qx: s:%d e:%d m:%qx\n", d, res.s, res.e, res.m);
}


void ppc_fpu_unpack_single(ppc_single *res, uint32 d)
{
	FPS_UNPACK_VAR(d, res->s, res->e, res->m);
	// .124
	if (res->e == 255) {
		if (res->m == 0) {
			res->type = ppc_fpr_Inf;
		} else {
			res->type = ppc_fpr_NaN;
		}
	} else if (res->e == 0) {
		if (res->m == 0) {
			res->type = ppc_fpr_zero;
		} else {
			// normalize denormalized exponent
			int diff = ppc_fpu_normalize_single(res) - 8;
			res->m <<= diff+3;
			res->e -= 127 - 1 + diff;
			res->type = ppc_fpr_norm;
		}
	} else {
		res->e -= 127; // unbias exponent
		res->type = ppc_fpr_norm;
		// add implied bit
		res->m |= 1<<23;
		res->m <<= 3;
	}
}

uint32 ppc_fpu_round(ppc_double *d) 
{
	// .132
	switch (FPSCR_RN(gCPU.fpscr)) {
	case FPSCR_RN_NEAR:
		if (d->m & 0x7) {
			if ((d->m & 0x7) != 4) {
				d->m += 4;
			} else if (d->m & 8) {
				d->m += 4;
			}
			return FPSCR_XX;
		}
		return 0;
	case FPSCR_RN_ZERO:
		if (d->m & 0x7) {
			return FPSCR_XX;
		}
		return 0;
	case FPSCR_RN_PINF:
		if (!d->s && (d->m & 0x7)) {
			d->m += 8;
			return FPSCR_XX;
		}
		return 0;
	case FPSCR_RN_MINF:
		if (d->s && (d->m & 0x7)) {
			d->m += 8;
			return FPSCR_XX;
		}
		return 0;
	}
	return 0;
}

uint32 ppc_fpu_round_single(ppc_single *s) 
{
	switch (FPSCR_RN(gCPU.fpscr)) {
	case FPSCR_RN_NEAR:
		if (s->m & 0x7) {
			if ((s->m & 0x7) != 4) {
				s->m += 4;
			} else if (s->m & 8) {
				s->m += 4;
			}
			return FPSCR_XX;
		}
		return 0;
	case FPSCR_RN_ZERO:
		if (s->m & 0x7) {
			return FPSCR_XX;
		}
		return 0;
	case FPSCR_RN_PINF:
		if (!s->s && (s->m & 0x7)) {
			s->m += 8;
			return FPSCR_XX;
		}
		return 0;
	case FPSCR_RN_MINF:
		if (s->s && (s->m & 0x7)) {
			s->m += 8;
			return FPSCR_XX;
		}
		return 0;
	}
	return 0;
}

uint32 ppc_fpu_round_double(ppc_double *s) 
{
	switch (FPSCR_RN(gCPU.fpscr)) {
	case FPSCR_RN_NEAR:
		if (s->m & 0x7) {
			if ((s->m & 0x7) != 4) {
				s->m += 4;
			} else if (s->m & 8) {
				s->m += 4;
			}
			return FPSCR_XX;
		}
		return 0;
	case FPSCR_RN_ZERO:
		if (s->m & 0x7) {
			return FPSCR_XX;
		}
		return 0;
	case FPSCR_RN_PINF:
		if (!s->s && (s->m & 0x7)) {
			s->m += 8;
			return FPSCR_XX;
		}
		return 0;
	case FPSCR_RN_MINF:
		if (s->s && (s->m & 0x7)) {
			s->m += 8;
			return FPSCR_XX;
		}
		return 0;
	}
	return 0;
}

uint32 ppc_fpu_pack_double(ppc_double *d, uint64 *res)
{
	// .124
	uint32 ret = 0;
//	ht_printf("pd_type: %d\n", d.type);
	switch (d->type) {
	case ppc_fpr_norm:
//		ht_printf("pd: %qx: s:%d e:%d m:%qx\n", d, d.s, d.e, d.m);
		d->e += 1023; // bias exponent
//		ht_printf("pd: %qx: s:%d e:%d m:%qx\n", d, d.s, d.e, d.m);
		if (d->e > 0) {
			ret |= ppc_fpu_round(d);
			if (d->m & (1ULL<<56)) {
				d->e++;
				d->m >>= 4;
			} else {
				d->m >>= 3;
			}
			if (d->e >= 2047) {
				d->e = 2047;
				d->m = 0;
				ret |= FPSCR_OX;
			}
		} else {
			// number is denormalized
			d->e = -d->e+1;
			if (d->e <= 56) {
				d->m >>= d->e;
				ret |= ppc_fpu_round(d);
				d->m <<= 1;
				if (d->m & (1ULL<<56)) {
					d->e = 1;
					d->m = 0;
				} else {
					d->e = 0;
					d->m >>= 4;
					ret |= FPSCR_UX;
				}
			} else {
				// underflow to zero
				d->e = 0;
				d->m = 0;
				ret |= FPSCR_UX;
			}
		}
		break;
	case ppc_fpr_zero:
		d->e = 0;
		d->m = 0;
		break;
	case ppc_fpr_NaN:
		d->e = 2047;
		d->m = 1;		
		break;
	case ppc_fpr_Inf:
		d->e = 2047;
		d->m = 0;
		break;
	}
//	ht_printf("pd: %qx: s:%d e:%d m:%qx\n", d, d.s, d.e, d.m);
	FPD_PACK_VAR(*res, d->s, d->e, d->m);
	return ret;
}

uint32 ppc_fpu_pack_single(ppc_double *d, uint32 *res)
{
	// .124
	uint32 ret = 0;
	switch (d->type) {
	case ppc_fpr_norm:
//		ht_printf("ps: %qx: s:%d e:%d m:%qx\n", d, d.s, d.e, d.m);
		d->e += 127; // bias exponent
		d->m >>= 29;
//		ht_printf("ps: %qx: s:%d e:%d m:%qx\n", d, d.s, d.e, d.m);
		if (d->e > 0) {
			ret |= ppc_fpu_round_double(d);
			if (d->m & (1ULL<<27)) {
				d->e++;
				d->m >>= 4;
			} else {
				d->m >>= 3;
			}
			if (d->e >= 255) {
				d->e = 255;
				d->m = 0;
				ret |= FPSCR_OX;
			}
		} else {
			// number is denormalized
			d->e = -d->e+1;
			if (d->e <= 27) {
				d->m >>= d->e;
				ret |= ppc_fpu_round_double(d);
				d->m <<= 1;
				if (d->m & (1ULL<<27)) {
					d->e = 1;
					d->m = 0;
				} else {
					d->e = 0;
					d->m >>= 4;
					ret |= FPSCR_UX;
				}
			} else {
				// underflow to zero
				d->e = 0;
				d->m = 0;
				ret |= FPSCR_UX;
			}
		}
		break;
	case ppc_fpr_zero:
		d->e = 0;
		d->m = 0;
		break;
	case ppc_fpr_NaN:
		d->e = 255;
		d->m = 1;
		break;
	case ppc_fpr_Inf:
		d->e = 255;
		d->m = 0;
		break;
	}
//	ht_printf("ps: %qx: s:%d e:%d m:%qx\n", d, d.s, d.e, d.m);
	FPS_PACK_VAR(*res, d->s, d->e, d->m);
	return ret;
}

void ppc_fpu_single_to_double(ppc_single *s, ppc_double *d) 
{
	d->s = s->s;
	d->e = s->e;
	d->m = ((uint64)s->m)<<29;
	d->type = s->type;
}

uint32 ppc_fpu_pack_double_as_single(ppc_double *d, uint64 *res)
{
	ppc_single s;
	s.m = d->m >> 29;
	s.e = d->e;
	s.s = d->s;
	s.type = d->type;
	uint32 ret = 0;
	
	switch (s.type) {
	case ppc_fpr_norm: 
		s.e = d->e+127;
		if (s.e > 0) {
			ret |= ppc_fpu_round_single(&s);
			if (s.m & (1<<27)) {
				s.e++;
				s.m >>= 4;
			} else {
				s.m >>= 3;
			}
			if (s.e >= 255) {
				s.type = ppc_fpr_Inf;
				s.e = 255;
				s.m = 0;
				ret |= FPSCR_OX;
			}
			d->e = s.e-127;
		} else {
			// number is denormalized
			s.e = -s.e+1;
			if (s.e <= 27) {
				s.m >>= s.e;
				ret |= ppc_fpu_round_single(&s);
				s.m <<= 1;
				if (s.m & (1<<27)) {
					s.e = 1;
					s.m = 0;
				} else {
					s.e = 0;
					s.m >>= 4;
					ret |= FPSCR_UX;
				}
			} else {
				// underflow to zero
				s.type = ppc_fpr_zero;
				s.e = 0;
				s.m = 0;
				ret |= FPSCR_UX;
			}
		}
		break;
	case ppc_fpr_zero:
		s.e = 0;
		s.m = 0;
		break;
	case ppc_fpr_NaN:
		s.e = 2047;
		s.m = 1;		
		break;
	case ppc_fpr_Inf:
		s.e = 2047;
		s.m = 0;
		break;
	}	
	if (s.type == ppc_fpr_norm) {
		d->m = ((uint64)(s.m))<<32;
	} else {
		d->m = s.m;
	}
//	ht_printf("dm: %qx\n", d.m);
	ret |= ppc_fpu_pack_double(d, res);
	return ret;
}

uint32 ppc_fpu_double_to_int(ppc_double *d)
{
	switch (d->type) {
	case ppc_fpr_norm: {
		if (d->e < 0) {
			switch (FPSCR_RN(gCPU.fpscr)) {
			case FPSCR_RN_NEAR:
				if (d->e < -1) {
					return 0;
				} else {
					return d->s ? (uint32)-1 : 1;
				}
			case FPSCR_RN_ZERO:
				return 0;
			case FPSCR_RN_PINF:
				if (d->s) {
					return 0;
				} else {
					return 1;
				}
			case FPSCR_RN_MINF:
				if (d->s) {
					return (uint32)-1;
				} else {
					return 0;
				}
			}
		}
		if (d->e >= 31) {
			if (d->s) {
				return 0x80000000;
			} else {
				return 0x7fffffff;
			}
		}		
		int i=0;
		uint64 mask = (1ULL<<(56 - d->e - 1))-1;
		// we have to round
		switch (FPSCR_RN(gCPU.fpscr)) {
		case FPSCR_RN_NEAR:
			if (d->m & mask) {
				if (d->m & (1ULL<<(56 - d->e - 2))) {
					i = 1;
				}
			}
			break;
		case FPSCR_RN_ZERO:
			break;
		case FPSCR_RN_PINF:
			if (!d->s && (d->m & mask)) {
				i = 1;
			}
			break;
		case FPSCR_RN_MINF:
			if (d->s && (d->m & mask)) {
				i = 1;
			}
			break;
		}
		d->m >>= 56 - d->e - 1;
		d->m += i;
		return d->s ? -d->m : d->m;
	}
	case ppc_fpr_zero:
		return 0;
	case ppc_fpr_Inf:
	case ppc_fpr_NaN:
		if (d->s) {
			return 0x80000000;
		} else {
			return 0x7fffffff;
		}
	}
	return 0;
}

