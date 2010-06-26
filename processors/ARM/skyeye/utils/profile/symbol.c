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

#include <config.h>
#ifdef HAVE_LIBBFD /* we do a workaround for those platform without bfd library */
#include <assert.h>
#include "bfd.h"
#include <search.h>
#include "symbol.h"

/*
 * FIXME: GNU hash table isn't exist everywhere!!!
 */

static char itoa_tab[16] = {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'} ;
static long storage_needed;
static asymbol **symbol_table;
static unsigned long number_of_symbols, kernel_number;

/**************************************************************************
  This function read the symbol list and store into a table
  It then generates a hash table based on the value of function symbol
  and the data is the pointer to struct funcsym defined in armsym.h

  The GNU hash table is used.
**************************************************************************/
/***************
 * added by ksh
 ***************/ 
void init_symbol_table(char* filename)
{
  long i,j, digit;
  ENTRY newentry, *oldentry;
  SYM_FUNC *symp;
  asymbol *symptr;
  int key;
  bfd *abfd;
  printf("call ARMul_InitSymTable,kernel filename is %s. \n",filename);

	if(!filename){
					fprintf(stderr, "Can not get correct kernel filename!Maybe your skyeye.conf have something wrong!\n");
					skyeye_exit(-1);
	}
  abfd = bfd_openr (filename, 0);


  if (!bfd_check_format(abfd, bfd_object)) {
    printf("Wrong format\n") ;
    exit(0);
  }

  storage_needed = bfd_get_symtab_upper_bound(abfd);
  if (storage_needed < 0){
    printf("FAIL\n");
    exit(0);
  }

  // <tktan> BUG200105221946 :symbol_table = (asymbol **) malloc (storage_needed);
  symbol_table = (asymbol **) malloc (storage_needed);

  number_of_symbols =
     bfd_canonicalize_symtab (abfd, symbol_table);
  kernel_number = number_of_symbols; /* <tktan> BUG200106022219 */

  if (number_of_symbols < 0){
    printf("FAIL\n");
    exit(0);
  }

  if (!hcreate(number_of_symbols << 1)) {
    printf("Not enough memory for hash table\n");
    exit(0);
  }
  for (i = 0; i < number_of_symbols; i++) {
    symptr = symbol_table[i] ;
    key = symptr->value + symptr->section->vma; // adjust for section address

    if (((i<kernel_number) && (symbol_table[i]->flags == 0x01)) || // <tktan> BUG200105172154, BUG200106022219 
	((i<kernel_number) && (symbol_table[i]->flags == 0x02)) || // <tktan> BUG200204051654
	(symbol_table[i]->flags & 0x10)) { // Is a function symbol
      // printf("%x %8x %s\n", symbol_table[i]->flags, key, symbol_table[i]->name);

      // ***********************************************************
      // This is converting the function symbol value to char string
      // and use it as a key in the GNU hash table
      // ********************************************************
      newentry.key = (char *) malloc(9);
      for (j=0;j<8;j++) {
        newentry.key[j] = itoa_tab[((key) >> (j << 2)) & 0xf] ;
      }
      newentry.key[8] = 0 ;

      // *************************************************
      // This is allocating memory for a struct funcsym
      // *************************************************
      symp = (SYM_FUNC *) malloc(sizeof(SYM_FUNC));
      newentry.data = (char *) symp; 
      symp->name = (char *) symbol_table[i]->name ;
      symp->total_cycle = 0;
      symp->total_energy = 0;
      symp->instances = 0;

      // ***********************************************
      // Insert into hash table
      // *******************************************
      /* <tktan> BUG200106022219 */
      oldentry = hsearch(newentry, FIND) ;
      if (oldentry) { // was entered
        // printf("Duplicate Symbol: %x %s\n", key, symp->name);
        oldentry->data = (char *) symp ;	
      } else if (!hsearch(newentry, ENTER)) { 
        printf("Insufficient memory\n");
        exit(0) ;
      }
    }
  }

  return;
}
/***************************************************************
  This function get check the hash table for an entry
  If it exists, the corresponding pointer to the SYM_FUNC will
  be returned
*************************************************************/
char *get_sym(ARMword address)
{
  int j ;
  ENTRY entry, *ep;
  char text[9] ;
  SYM_FUNC *symp;

  //printf("GetSym %x\n", address);
  entry.key = text ;
  for (j=0;j<8;j++) {
    entry.key[j] = itoa_tab[(address >> (j << 2)) & 0xf] ;
  }
  entry.key[8] = 0 ;
/*a bug need to fixed */
  ep = hsearch(entry, FIND) ;

  if (ep != 0) {
    symp = (SYM_FUNC *) ep->data;
    return(symp->name);
  } else
    return(NULL);
}
#endif
