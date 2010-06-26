/*
        skyeye_arch.c -  all architecture definition for skyeye
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
 * 12/16/2006   Michael.Kang  <blackfin.kang@gmail.com>
 */

#include "skyeye_arch.h"
#include "skyeye_config.h"
#include <stdlib.h>

arch_config_t *skyeye_archs[MAX_SUPP_ARCH];
/*
 * register a supported arch to skyeye_archs
 */
void
register_arch (arch_config_t * arch)
{
	int i;
	for (i = 0; i < MAX_SUPP_ARCH; i++) {
		if (skyeye_archs[i] == NULL) {
			skyeye_archs[i] = arch;
			return;
		}
	}
}

extern void init_arm_arch ();
extern void init_bfin_arch ();
extern void init_coldfire_arch ();
extern void init_mips_arch();

extern void init_ppc_arch();

void
initialize_all_arch ()
{
	int i;
	for (i = 0; i < MAX_SUPP_ARCH; i++) {
		skyeye_archs[i] = NULL;
	}
	/* register arm_arch */
	init_arm_arch ();

	/* register bfin_arch */
	init_bfin_arch ();

	/* register mips_arch */
	init_mips_arch ();

	/* register coldfire_arch */
	init_coldfire_arch ();

	/* register ppc_arch */
	init_ppc_arch();
}
