/*
        arm_regdefs.c - necessary arm definition for skyeye debugger
        Copyright (C) 2003-2007 Skyeye Develop Group
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
 * 12/16/2006   Michael.Kang  <blackfin.kang@gmail.com>
 */

#include "skyeye_arch.h"
#include "skyeye_config.h"
#include "skyeye2gdb.h"
#include "skyeye_defs.h"

register_defs_t *register_types[MAX_SUPP_ARCH];
void register_reg_type(register_defs_t * reg_type){
	int i;
        for (i = 0; i < MAX_SUPP_ARCH; i++) {
                if (register_types[i] == NULL) {
                        register_types[i] = reg_type;
                        return;
                }
        }
}

extern void init_arm_register_defs();
extern void init_bfin_register_defs();
extern void init_mips_register_defs();

extern void init_cf_register_defs();
extern void init_ppc_register_defs();

extern skyeye_config_t skyeye_config;	

register_defs_t * current_reg_type;
/*
 * Initializing all register type for supported architechtures
 */
int init_register_type(){
	int i;
	if(!skyeye_config.arch){
		fprintf(stderr,"architecture is not initialized.\n");
		return -1;
	}
        for (i = 0; i < MAX_SUPP_ARCH; i++) {
                register_types[i] = NULL;
        }
        /* register arm_arch */
        init_arm_register_defs ();

        /*register bfin_arch */
        init_bfin_register_defs ();

        /* register mips_arch */
        init_mips_register_defs ();

        /* register coldfire_arch */
        init_cf_register_defs ();

        /* register ppc_arch */
	init_ppc_register_defs ();

	for (i = 0; i < MAX_SUPP_ARCH; i++){
		if(register_types[i] != NULL)
			if(!strcmp(skyeye_config.arch->arch_name, register_types[i]->name))
				current_reg_type = register_types[i];
	}
	if(!current_reg_type){
		fprintf(stderr, " Can not find register type for current arch!\n");
		return -1;
	}
	else
		return 0;
}
