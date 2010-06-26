/*  armsym.h -- ARMulator emulation macros:  SA11x Instruction Emulator.
    Copyright (C) 2001 Princeton University.

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
    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. */

#ifndef ARMSYM_H
#define ARMSYM_H

#include "armdefs.h"
#include <config.h>
#ifdef HAVE_LIBBFD
struct sym_func {
  char *name;
  long long total_energy; // for all instances
  long long total_cycle; // for all instances
  int instances; // number of instances
};

typedef struct sym_func SYM_FUNC;

struct sym_funcinst {
  /* Function Info */
  SYM_FUNC *func_symbol;
  ARMword func_start_addr; // the address at which this function starts
  ARMword ret_addr; // the  PC at which we make sub-routine call 

  /* Profiling Data */
  float tenergy;
  long long tcycle;
};

#define MAX_LEVEL 1024

struct sym_taskinst {
  ARMword task_id; // Actually is the pointer to Linux struct task_struct 
  /* Task call stack */
  struct sym_funcinst func_stack[MAX_LEVEL];
  int level;

  /* Profiling Data */
  float total_energy;
  long long total_cycle;

  /* link data */
  struct sym_taskinst *next;
};

typedef struct sym_funcinst FUNC_NODE;
typedef struct sym_taskinst TASK_STACK;

/*****************************************************
  Function declaration
******************************************************/
//void ARMul_InitSymTable(bfd *abfd);
SYM_FUNC *ARMul_GetSym(ARMword address);
void ARMul_ProfInit(ARMul_State *state);
FUNC_NODE *ARMul_CreateChild(ARMul_State *state);
void ARMul_DestroyChild(ARMul_State *state);
void ARMul_CallCheck(ARMul_State *state, ARMword cur_pc, ARMword to_pc, ARMword instr);
void ARMul_TaskSwitch(ARMul_State *state);
ARMword ARMul_TaskCreate(ARMul_State *state);
void ARMul_ReportEnergy(ARMul_State *state, FILE* pf);
void ARMul_Consolidate(ARMul_State *state);

#endif
#endif

