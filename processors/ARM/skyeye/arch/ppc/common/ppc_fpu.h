/*
 *	PearPC
 *	ppc_fpu.h
 *
 *	Copyright (C) 2003, 2004 Sebastian Biallas (sb@biallas.net)
 *
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License version 2 as
 *	published by the Free Software Foundation.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program; if not, write to the Free Software
 *	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */
 
#ifndef __PPC_FPU_H__
#define __PPC_FPU_H__

#include "types.h"

#define FPU_SIGN_BIT (0x8000000000000000ULL)

#define FPD_SIGN(v) (((v)&FPU_SIGN_BIT)?1:0)
#define FPD_EXP(v) ((v)>>52)
#define FPD_FRAC(v) ((v)&0x000fffffffffffffULL)

#define FPS_SIGN(v) ((v)&0x80000000)
#define FPS_EXP(v) ((v)>>23)
#define FPS_FRAC(v) ((v)&0x007fffff)

// m must be uint64
#define FPD_PACK_VAR(f, s, e, m) (f) = ((s)?FPU_SIGN_BIT:0ULL)|((((uint64)(e))&0x7ff)<<52)|((m)&((1ULL<<52)-1))
#define FPD_UNPACK_VAR(f, s, e, m) {(s)=FPD_SIGN(f);(e)=FPD_EXP(f)&0x7ff;(m)=FPD_FRAC(f);}

#define FPS_PACK_VAR(f, s, e, m) (f) = ((s)?0x80000000:0)|((e)<<23)|((m)&0x7fffff)
#define FPS_UNPACK_VAR(f, s, e, m) {(s)=FPS_SIGN(f);(e)=FPS_EXP(f)&0xff;(m)=FPS_FRAC(f);}

#define FPD_UNPACK(freg, fvar) FPD_UNPACK(freg, fvar.s, fvar.e, fvar.m)


void ppc_fpu_test();

typedef enum {
	ppc_fpr_norm,
	ppc_fpr_zero,
	ppc_fpr_NaN,
	ppc_fpr_Inf,
}ppc_fpr_type;

typedef struct ppc_quadro_s {
	ppc_fpr_type type;
	int s;
	int e;
	uint64 m0;	// most  significant
	uint64 m1;	// least significant
}ppc_quadro;

typedef struct ppc_double_s {
	ppc_fpr_type type;
	int s;
	int e;
	uint64 m;
}ppc_double;

typedef struct ppc_single_s {
	ppc_fpr_type type;
	int s;
	int e;
	uint m;
}ppc_single;


double ppc_fpu_get_uint64(uint64 d);
double ppc_fpu_get_double(ppc_double *d);

void ppc_opc_fabsx();
void ppc_opc_faddx();
void ppc_opc_faddsx();
void ppc_opc_fcmpo();
void ppc_opc_fcmpu();
void ppc_opc_fctiwx();
void ppc_opc_fctiwzx();
void ppc_opc_fdivx();
void ppc_opc_fdivsx();
void ppc_opc_fmaddx();
void ppc_opc_fmaddsx();
void ppc_opc_fmrx();
void ppc_opc_fmsubx();
void ppc_opc_fmsubsx();
void ppc_opc_fmulx();
void ppc_opc_fmulsx();
void ppc_opc_fnabsx();
void ppc_opc_fnegx();
void ppc_opc_fnmaddx();
void ppc_opc_fnmaddsx();
void ppc_opc_fnmsubx();
void ppc_opc_fnmsubsx();
void ppc_opc_fresx();
void ppc_opc_frspx();
void ppc_opc_frsqrtex();
void ppc_opc_fselx();
void ppc_opc_fsqrtx();
void ppc_opc_fsqrtsx();
void ppc_opc_fsubx();
void ppc_opc_fsubsx();

#endif
