/*
        mipsio.c - necessary arm definition for skyeye debugger
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
 * 06/07/2006   Michael.Kang  <blackfin.kang@gmail.com>
 */
#include "types.h"
#include "emul.h"

#include "skyeye_config.h"

extern MIPS_State *mstate;

UInt32
mips_io_read_byte(UInt32 addr)
{
	if (skyeye_config.mach->mach_io_read_byte)
		return skyeye_config.mach->mach_io_read_byte(mstate, addr);
 	else{
                fprintf(stderr, "io_read_byte is not initialized,in %s \n", __FUNCTION__);

                skyeye_exit(-1);
                return 0; /* never executed */
        }
}

UInt32
mips_io_read_halfword(UInt32 addr)
{	
	if (skyeye_config.mach->mach_io_read_halfword)
		return skyeye_config.mach->mach_io_read_halfword(mstate, addr);
	else{
                fprintf(stderr, "io_read_halfword is not initialized, in %s\n", __FUNCTION__);

                skyeye_exit(-1);
                return 0; /* never executed */
        }
}

UInt32
mips_io_read_word(UInt32 addr)
{
	
	if (skyeye_config.mach->mach_io_read_word)
		return skyeye_config.mach->mach_io_read_word(mstate, addr);
	else{
                fprintf(stderr, "io_read_word is not initializedin %s\n", __FUNCTION__);
                skyeye_exit(-1);
		return 0; /* never executed */
        }
}

UInt64
mips_io_read_doubleword(UInt32 addr)
{
	fprintf(stderr, "io_read_doubleword is not initializedin %s\n", __FUNCTION__);
	skyeye_exit(-1);
}

void
mips_io_write_byte(UInt32 addr, UInt32 data)
{
	
	if (skyeye_config.mach->mach_io_write_byte)
		skyeye_config.mach->mach_io_write_byte(mstate, addr, data);
	else{
                fprintf(stderr, "io_write_byte is not initializedin %s\n", __FUNCTION__);
                skyeye_exit(-1);
        }
}

void
mips_io_write_halfword(UInt32 addr, UInt32 data)
{
	
	if (skyeye_config.mach->mach_io_write_halfword)
		skyeye_config.mach->mach_io_write_halfword(mstate, addr, data);
	else{
                fprintf(stderr, "io_write_halfword is not initializedin %s\n", __FUNCTION__);
                skyeye_exit(-1);
        }
}

void
mips_io_write_word(UInt32 addr, UInt32 data)
{
	
	if (skyeye_config.mach->mach_io_write_word)
		skyeye_config.mach->mach_io_write_word(mstate, addr, data);
	else{
		fprintf(stderr, "io_write_word is not initializedin %s\n", __FUNCTION__);
		skyeye_exit(-1);
	}
}

void
mips_io_write_doubleword(UInt32 addr, UInt32 data)
{
	fprintf(stderr, "io_write_doubleword is not initializedin %s\n", __FUNCTION__);
        skyeye_exit(-1);

}
