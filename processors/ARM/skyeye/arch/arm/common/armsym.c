/*  armsym.c -- Main instruction emulation:  SA11x Instruction Emulator.
    Copyright (C) 2001 Princeton University 

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

#include <assert.h>
#include "bfd.h"
#include <search.h>
#include "armsym.h"
#include "armdefs.h"


static char itoa_tab[16] =
	{ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c',
'd', 'e',
	'f'
};
static int storage_needed;
static asymbol **symbol_table;
static unsigned int number_of_symbols, kernel_number;

static SYM_FUNC trap_sym = { "Trap", 0, 0, 0 };
static SYM_FUNC init_sym = { "Init", 0, 0, 0 };	/* <tktan> BUG200103311736 */
static FUNC_NODE init_node = { &init_sym, 0, 0, 0 };
static ARMword debug;
#if 0
void
ARMul_InitSymTable ()
{
	int i, j, digit;
	ENTRY newentry, *oldentry;
	SYM_FUNC *symp;
	asymbol *symptr;
	int key;
	bfd *appl_bfd;
	bfd *abfd;
	int appl_storage_needed;

	abfd = bfd_openr ("./vmlinux", 0);
	/* <tktan> BUG200105221946 : get symbol from usrappl */
	appl_bfd = bfd_openr ("init/usrappl", 0);
	if (appl_bfd == NULL) {
		printf ("Can't open init/usrappl\n");
		exit (0);
	}

	if (!bfd_check_format (appl_bfd, bfd_object)) {
		printf ("Wrong format\n");
		exit (0);
	}

	appl_storage_needed = bfd_get_symtab_upper_bound (appl_bfd);
	if (appl_storage_needed < 0) {
		printf ("FAIL\n");
		exit (0);
	}
	/* <tktan> BUG200105221946 */

	if (!bfd_check_format (abfd, bfd_object)) {
		printf ("Wrong format\n");
		exit (0);
	}

	storage_needed = bfd_get_symtab_upper_bound (abfd);
	if (storage_needed < 0) {
		printf ("FAIL\n");
		exit (0);
	}

	// <tktan> BUG200105221946 :symbol_table = (asymbol **) malloc (storage_needed);
	symbol_table =
		(asymbol **) malloc (appl_storage_needed + storage_needed);

	number_of_symbols = bfd_canonicalize_symtab (abfd, symbol_table);
	kernel_number = number_of_symbols;	/* <tktan> BUG200106022219 */

	if (number_of_symbols < 0) {
		printf ("FAIL\n");
		exit (0);
	}

	/* <tktan> BUG200105221946 */
	number_of_symbols +=
		bfd_canonicalize_symtab (appl_bfd,
					 &(symbol_table[number_of_symbols]));

	// printf("Number of symbols = %d\n", number_of_symbols) ;

	if (!hcreate (number_of_symbols << 1)) {
		printf ("Not enough memory for hash table\n");
		exit (0);
	}
	for (i = 0; i < number_of_symbols; i++) {
		symptr = symbol_table[i];
		key = symptr->value + symptr->section->vma;	// adjust for section address

		if (((i < kernel_number) && (symbol_table[i]->flags == 0x01)) ||	// <tktan> BUG200105172154, BUG200106022219 
		    ((i < kernel_number) && (symbol_table[i]->flags == 0x02)) ||	// <tktan> BUG200204051654
		    (symbol_table[i]->flags & 0x10)) {	// Is a function symbol
			// printf("%x %8x %s\n", symbol_table[i]->flags, key, symbol_table[i]->name);

			// ***********************************************************
			// This is converting the function symbol value to char string
			// and use it as a key in the GNU hash table
			// ********************************************************
			newentry.key = (char *) malloc (9);
			for (j = 0; j < 8; j++) {
				newentry.key[j] =
					itoa_tab[((key) >> (j << 2)) & 0xf];
			}
			newentry.key[8] = 0;

			// *************************************************
			// This is allocating memory for a struct funcsym
			// *************************************************
			symp = (SYM_FUNC *) malloc (sizeof (SYM_FUNC));
			newentry.data = (char *) symp;
			symp->name = (char *) symbol_table[i]->name;
			symp->total_cycle = 0;
			symp->total_energy = 0;
			symp->instances = 0;

			// ***********************************************
			// Insert into hash table
			// *******************************************
			/* <tktan> BUG200106022219 */
			oldentry = hsearch (newentry, FIND);
			if (oldentry) {	// was entered
				// printf("Duplicate Symbol: %x %s\n", key, symp->name);
				oldentry->data = (char *) symp;
			}
			else if (!hsearch (newentry, ENTER)) {
				printf ("Insufficient memory\n");
				exit (0);
			}
		}
	}

	return;
}

#else
/**************************************************************************
  This function read the symbol list and store into a table
  It then generates a hash table based on the value of function symbol
  and the data is the pointer to struct funcsym defined in armsym.h

  The GNU hash table is used.
**************************************************************************/
/***************
 * added by ksh
 ***************/
void
ARMul_InitSymTable (char *filename)
{
	int i, j, digit;
	ENTRY newentry, *oldentry;
	SYM_FUNC *symp;
	asymbol *symptr;
	int key;
	bfd *abfd;
	printf ("call ARMul_InitSymTable,kernle filename is %s. \n",
		filename);

	if (!filename) {
		printf ("Can not get correct kernel filename!Maybe your skyeye.conf have something wrong!\n");
		skyeye_exit (-1);
	}
	/* <tktan> BUG200105221946 : get symbol from usrappl */
	abfd = bfd_openr (filename, 0);

	/* <tktan> BUG200105221946 : get symbol from usrappl */

	/* <tktan> BUG200105221946 */

	if (!bfd_check_format (abfd, bfd_object)) {
		printf ("Wrong format\n");
		skyeye_exit (0);
	}

	storage_needed = bfd_get_symtab_upper_bound (abfd);
	if (storage_needed < 0) {
		printf ("FAIL\n");
		skyeye_exit (0);
	}

	// <tktan> BUG200105221946 :symbol_table = (asymbol **) malloc (storage_needed);
	symbol_table = (asymbol **) malloc (storage_needed);

	number_of_symbols = bfd_canonicalize_symtab (abfd, symbol_table);
	kernel_number = number_of_symbols;	/* <tktan> BUG200106022219 */

	if (number_of_symbols < 0) {
		printf ("FAIL\n");
		skyeye_exit (0);
	}

	if (!hcreate (number_of_symbols << 1)) {
		printf ("Not enough memory for hash table\n");
		skyeye_exit (0);
	}
	for (i = 0; i < number_of_symbols; i++) {
		symptr = symbol_table[i];
		key = symptr->value + symptr->section->vma;	// adjust for section address

		if (((i < kernel_number) && (symbol_table[i]->flags == 0x01)) ||	// <tktan> BUG200105172154, BUG200106022219 
		    ((i < kernel_number) && (symbol_table[i]->flags == 0x02)) ||	// <tktan> BUG200204051654
		    (symbol_table[i]->flags & 0x10)) {	// Is a function symbol
			// printf("%x %8x %s\n", symbol_table[i]->flags, key, symbol_table[i]->name);

			// ***********************************************************
			// This is converting the function symbol value to char string
			// and use it as a key in the GNU hash table
			// ********************************************************
			newentry.key = (char *) malloc (9);
			for (j = 0; j < 8; j++) {
				newentry.key[j] =
					itoa_tab[((key) >> (j << 2)) & 0xf];
			}
			newentry.key[8] = 0;

			// *************************************************
			// This is allocating memory for a struct funcsym
			// *************************************************
			symp = (SYM_FUNC *) malloc (sizeof (SYM_FUNC));
			newentry.data = (char *) symp;
			symp->name = (char *) symbol_table[i]->name;
			symp->total_cycle = 0;
			symp->total_energy = 0;
			symp->instances = 0;

			// ***********************************************
			// Insert into hash table
			// *******************************************
			/* <tktan> BUG200106022219 */
			oldentry = hsearch (newentry, FIND);
			if (oldentry) {	// was entered
				// printf("Duplicate Symbol: %x %s\n", key, symp->name);
				oldentry->data = (char *) symp;
			}
			else if (!hsearch (newentry, ENTER)) {
				printf ("Insufficient memory\n");
				skyeye_exit (0);
			}
		}
	}

	return;
}
#endif
/***************************************************************
  This function get check the hash table for an entry
  If it exists, the corresponding pointer to the SYM_FUNC will
  be returned
*************************************************************/
SYM_FUNC *
ARMul_GetSym (ARMword address)
{
	int j;
	ENTRY entry, *ep;
	char text[9];
	SYM_FUNC *symp;

	//printf("GetSym %x\n", address);
	entry.key = text;
	for (j = 0; j < 8; j++) {
		entry.key[j] = itoa_tab[(address >> (j << 2)) & 0xf];
	}
	entry.key[8] = 0;
/*a bug need to fixed */
	ep = hsearch (entry, FIND);

	if (ep != 0) {
		symp = (SYM_FUNC *) ep->data;
		return (symp);
	}
	else

		return (0);
}

/***************************************
*  Function to initialize the energy profiling tree root
***************************************************/
void
ARMul_ProfInit (ARMul_State * state)
{				/* <tktan> BUG200103311736 */
	TASK_STACK *tsp;
	printf ("call ARMul_ProfInit \n");
	tsp = malloc (sizeof (TASK_STACK));
	if (tsp <= 0) {
		printf ("Memory allocation error in ARMul_ProfInit \n");
		skyeye_exit (-1);
	}

	state->energy.cur_task = (void *) tsp;
	tsp->task_id = 0xc00f0000;	// where the INIT_TASK reside 
	memcpy (&(tsp->func_stack[0]), &init_node, sizeof (FUNC_NODE));
	tsp->level = 0;
	tsp->total_energy = 0;
	tsp->total_cycle = 0;
	tsp->next = tsp;

	return;
}

/****************************************
* Function to create child function node
****************************************/
FUNC_NODE *
ARMul_CreateChild (ARMul_State * state)
{
	TASK_STACK *tsp;
	int level;
	FUNC_NODE *fnp;

	tsp = (TASK_STACK *) state->energy.cur_task;
	(tsp->level)++;
	level = tsp->level;
	/* <tktan> BUG200105311233 */
	if (level >= MAX_LEVEL) {
		printf ("ARMul_CreateChild failed\n");
		assert (0);
	}

	fnp = &(tsp->func_stack[level]);
//  printf("Create Child!\n ");
	fnp->tenergy = tsp->total_energy;
	fnp->tcycle = tsp->total_cycle;
	return (fnp);
}

/******************************************
* Function to destroy child nodes
*****************************************/
void
ARMul_DestroyChild (ARMul_State * state)
{
	TASK_STACK *tsp;
	int level;
	long long fenergy;
	long long fcycle;
	FUNC_NODE *fnp;

	tsp = (TASK_STACK *) state->energy.cur_task;
	level = tsp->level;
	fnp = &(tsp->func_stack[level]);
	// <tktan> BUG200105222137 fenergy = state->t_energy - fnp->tenergy;
	fenergy = tsp->total_energy - fnp->tenergy;
	fcycle = tsp->total_cycle - fnp->tcycle;

	/* <tktan> BUG200105181702 */
	if ((state->energy.enable_func_energy)
	    && !(strcmp (state->energy.func_energy, fnp->func_symbol->name))) {
		printf ("energy_report %s %f\n", fnp->func_symbol->name,
			fenergy);
	}

	/* <tktan> BUG200104101936 */
	if (state->energy.energy_prof) {
		fnp->func_symbol->total_energy += fenergy;
		fnp->func_symbol->total_cycle += fcycle;
		(fnp->func_symbol->instances)++;
	}
	//printf("Destroy child,name %s \n",fnp->func_symbol->name);
	tsp->level = level - 1;
	return;
}


/************************************************
  Function to check the different kind of branch 
************************************************/
void
ARMul_CallCheck (ARMul_State * state, ARMword cur_pc, ARMword to_pc,
		 ARMword instr)
{
	FUNC_NODE *child_node;
	TASK_STACK *tsp;
	SYM_FUNC *symp;
	int i, bt, level;
	ARMword new_task_id, fp_value;

	tsp = (TASK_STACK *) state->energy.cur_task;
	level = tsp->level;
	fp_value = state->Reg[11];	// BUG200311301153
#if 0
	if (debug != tsp->task_id || !debug) {
		printf ("cur_task is changed! %x \n", tsp->task_id);
		debug = tsp->task_id;
	}
#endif

	/* <tktan> BUG200105311233 */
	if (level >= MAX_LEVEL) {
		printf ("ARMul_CallCheck failed\n");
		printf ("level %d \n", level);
		//exit(-1);
	}
	// First check if it is normal return
	if (to_pc == (tsp->func_stack[level].ret_addr + 4)) {
		if (state->energy.func_display & state->energy.func_disp_start) {	/* <tktan> BUG200104191428 */
			//if(1){
			printf ("[%x:%d:%x] Function return %s (%x)--> %s (%x)\n", tsp->task_id, level, fp_value, tsp->func_stack[level].func_symbol->name, cur_pc, tsp->func_stack[level - 1].func_symbol->name, to_pc);
		}

		/* <tktan> BUG200104101736 */
		ARMul_DestroyChild (state);

		return;
	}
	// Check if it is a trap return
	// a trap return is one that jump to a saved interrupted address, saved
	// in .ret_addr
	bt = 0;
	while ((level - bt >= 0) && (bt <= 3)) {
		if (to_pc == tsp->func_stack[level - bt].ret_addr) {
			if (state->energy.func_display & state->energy.func_disp_start) {	/* <tktan> BUG200104191428 */
				printf ("[%x:%d:%x] Trap Return -> %s\n",
					tsp->task_id, level, fp_value,
					tsp->func_stack[level - bt -
							1].func_symbol->name);
			}

			/* <tktan> BUG200104101736 */
			for (i = 0; i <= bt; i++) {
				ARMul_DestroyChild (state);
			}

			return;
		}
		bt++;
	}

	// BUG200311212039
	// check if it is a recursive call, or I was missing some returns through
	// abnormal jumps
	bt = 0;
	while ((level - bt >= 0) && (bt <= 2)) {
		if (to_pc == tsp->func_stack[level - bt].func_start_addr) {
			if (state->energy.func_display & state->energy.func_disp_start) {	/* <tktan> BUG200104191428 */
				printf ("[%x:%d:%x] Function %s ended\n",
					tsp->task_id, level, fp_value,
					tsp->func_stack[level -
							bt].func_symbol->
					name);
			}

			/* <tktan> BUG200104101736 */
			for (i = 0; i <= bt; i++) {
				ARMul_DestroyChild (state);
			}

		}
		bt++;
	}
	tsp = (TASK_STACK *) state->energy.cur_task;
	level = tsp->level;

	// check if it is a trap
	//if (!(to_pc & 0xffffffe0) && (state->Reg[14] == (cur_pc+4))) { // check for pc from 0x0 - 0x1f
	// BUG200311302126: Reg[14]_abt is cur_pc+8 for DataAbort,
	// but cur_pc+4 for other exception. So, better not check it 
	if (!(to_pc & 0xffffffe0)) {	// check for pc from 0x0 - 0x1f
		child_node = ARMul_CreateChild (state);	/* <tktan> BUG200104101736 */
		child_node->ret_addr = cur_pc;
		child_node->func_start_addr = to_pc;
		child_node->func_symbol = &trap_sym;

		if (state->energy.func_display & state->energy.func_disp_start) {	/* <tktan> BUG200104191428 */
			printf ("[%x:%d:%x] Function %s(%x) --> Trap %x\n",
				tsp->task_id, level, fp_value,
				tsp->func_stack[level].func_symbol->name,
				cur_pc, to_pc);
		}
		return;
	}

	// Check if it is a function call

	if ((state->Reg[14] == (cur_pc + 4)) ||	/* <tktan> BUG200105172030 */
	    (BITS (20, 27) & 0xf0) == 0xb0) {	/* <tktan> BUG200104012116 */

		symp = ARMul_GetSym (to_pc);
		if (symp) {
			// it is an entry into a function
			child_node = ARMul_CreateChild (state);	/* <tktan> BUG2001040101736 */
			child_node->ret_addr = cur_pc;
			child_node->func_start_addr = to_pc;
			child_node->func_symbol = symp;


			/* <tktan> BUG200105211055 : perform task switch */
			if (!strcmp (symp->name, "__switch_to")) {	// BUG200204021340
				ARMul_TaskSwitch (state);
			}
			if (!strcmp (symp->name, "copy_thread")) {
				new_task_id = ARMul_TaskCreate (state);
			}
		}

	}			/* <tktan> BUG200104012116 */
	// Just a normal branch, maybe
	return;
}

/* <tktan> BUG200105211055 : perform task switch */
void
ARMul_TaskSwitch (ARMul_State * state)
{
	TASK_STACK *ctsp, *oldtsp, *newtsp;
	//ARMword to_thread_id;
	ARMword to_task_id;
	int done = 0;

	//to_thread_id = state->Reg[2] ; // r1, the to_task task structure
	to_task_id = state->Reg[7];
	oldtsp = (TASK_STACK *) state->energy.cur_task;
	//printf("cur_task id %x \n",state->Reg[0]);
	oldtsp->task_id = state->Reg[0];	/* <tktan> BUG200106051701 */
	//printf("Task ThreadInfo Switch from %x to %x\n", oldtsp->thread_id, to_thread_id);
	//printf("task switch from %x to %x \n",oldtsp->task_id,to_task_id);
	ctsp = oldtsp->next;
	while (!done && (ctsp != oldtsp)) {
		if (ctsp->task_id == to_task_id) {
			done = 1;
			newtsp = ctsp;
		}
//      printf("ctsp taskid=%x,next task_id=%x \n",ctsp->task_id,ctsp->next->task_id);
		ctsp = ctsp->next;
	}

	if (done)
		state->energy.cur_task = (void *) newtsp;
	else {
		printf ("Error : Can not find task stack\n");
		//print_allTask(state);
		skyeye_exit (-1);
	}
}
void
print_allTask (ARMul_State * state)
{
	TASK_STACK *ctsp, *oldtsp, *newtsp;
	ARMword to_task_id;

	oldtsp = (TASK_STACK *) state->energy.cur_task;
	ctsp = oldtsp;
#if 0
	printf ("Begin to print all task...\n");
	do {
		printf ("ctsp taskid=%x,next task_id=%x \n", ctsp->task_id,
			ctsp->next->task_id);
		ctsp = ctsp->next;
	}
	while (ctsp != oldtsp);
	printf ("End to print....\n");
#endif
}

/* <tktan> BUG200105211055 : create new task stack */
ARMword
ARMul_TaskCreate (ARMul_State * state)
{
	TASK_STACK *oldtsp, *newtsp, *oldnext;
	ARMword to_task_id;
	int i;

	to_task_id = state->Reg[3];	// r3, the to_task task structure
	if (to_task_id == 0x00000000) {	// BUG200204081717
		to_task_id = state->Reg[5];	// r5 store the to_task task structure
	}

	oldtsp = (TASK_STACK *) state->energy.cur_task;

	newtsp = malloc (sizeof (TASK_STACK));
	memcpy (newtsp, oldtsp, sizeof (TASK_STACK));
	newtsp->task_id = to_task_id;
	newtsp->level -= 2;	// point to the SWI level

	/* <tktan> BUG200105222137 */
	newtsp->total_cycle = 0;
	// newtsp->total_energy = 0.0; BUG200106142205, possible problem
	newtsp->total_energy = 0;
	for (i = 0; i <= newtsp->level; i++) {
		newtsp->func_stack[i].tcycle = 0;
		newtsp->func_stack[i].tenergy = 0;
	}

	/* put newtsp after oldtsp */
	oldnext = oldtsp->next;
	oldtsp->next = newtsp;
	newtsp->next = oldnext;
	//printf("Create a new task,task_id=%x \n",to_task_id);
//print_allTask(state);
	return (to_task_id);
}

/********************************************
 *  Function to report energy tree
 *******************************************/
void
ARMul_ReportEnergy (ARMul_State * state, FILE * pf)
{
	int i, j;
	ENTRY entry, *ep;
	char text[9];
	SYM_FUNC *symp;
	asymbol *symptr;
	ARMword address;
	TASK_STACK *ctsp, *oldtsp;
	float energy;

	ARMul_Consolidate (state);	// <tktan> BUG200105222137 

	for (i = 0; i < number_of_symbols; i++) {
		symptr = symbol_table[i];
		address = symptr->value + symptr->section->vma;	// adjust for section address

		if (((i < kernel_number) && (symbol_table[i]->flags == 0x01)) ||	// <tktan> BUG200105172154, BUG200106022219
		    ((i < kernel_number) && (symbol_table[i]->flags == 0x02)) ||	// <tktan> BUG200204051654, BUG200311211406
		    (symbol_table[i]->flags & 0x10)) {	// Is a function symbol

			// ***********************************************************
			// This is converting the function symbol value to char string
			// and use it as a key in the GNU hash table
			// ********************************************************
			entry.key = text;
			for (j = 0; j < 8; j++) {
				entry.key[j] =
					itoa_tab[(address >> (j << 2)) & 0xf];
			}
			entry.key[8] = 0;

			ep = hsearch (entry, FIND);
			if (ep != 0) {
				symp = (SYM_FUNC *) ep->data;
				/*modified by ksh for evaluate the usrappl program only */
				/*
				   if(strncmp(symp->name,"usrappl",7) != 0){
				   continue;
				   }
				 */
				if (symp->instances > 0) {	// only show if executed
					energy = symp->total_energy;
					fprintf (pf, "%s %d %lld %f\n",
						 symp->name, symp->instances,
						 symp->total_cycle, energy);
				}
			}
		}
	}

	/* <tktan> BUG200105222137 : print out task energy */
	oldtsp = (TASK_STACK *) state->energy.cur_task;
	ctsp = oldtsp;
	do {
		energy = ctsp->total_energy;
		fprintf (pf, "Task[%x] %lld %f\n", ctsp->task_id,
			 ctsp->total_cycle, energy);
		ctsp = ctsp->next;
	}
	while (ctsp != oldtsp);
}

/* <tktan> BUG200105222137 : consolidate unfinished function energy */
void
ARMul_Consolidate (ARMul_State * state)
{
	long long fenergy;	// <tktan> BUG200106142205
	long long fcycle;	// <tktan> BUG200106142205
	FUNC_NODE *fnp;
	TASK_STACK *ctsp, *oldtsp;
	int i;
	double energy;

	/* <tktan> BUG200105222137 : report energy for tasks */
	/* <tktan> BUG200106041235 : use do instead of while */
	oldtsp = (TASK_STACK *) state->energy.cur_task;
	ctsp = oldtsp;
	do {
		for (i = ctsp->level; i >= 0; i--) {
			fnp = &(ctsp->func_stack[i]);
			fenergy = ctsp->total_energy - fnp->tenergy;
			fcycle = ctsp->total_cycle - fnp->tcycle;

			/* copied from <tktan> BUG200105181702 */
			if ((state->energy.enable_func_energy)
			    &&
			    !(strcmp
			      (state->energy.func_energy,
			       fnp->func_symbol->name))) {
				//energy = I2ENERGY(fenergy);
				//fprintf(pf,"energy_report %s %f\n", fnp->func_symbol->name, energy);
			}

			/* copied from <tktan> BUG200104101936 */
			fnp->func_symbol->total_energy += fenergy;
			fnp->func_symbol->total_cycle += fcycle;
			(fnp->func_symbol->instances)++;
		}
		ctsp = ctsp->next;
	}
	while (ctsp != oldtsp);
}
