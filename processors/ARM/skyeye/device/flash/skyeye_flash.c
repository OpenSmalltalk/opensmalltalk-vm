/*
	skyeye_flash.c - skyeye general flash device file support functions
	Copyright (C) 2003 - 2005 Skyeye Develop Group
        for help please send mail to <skyeye-developer@lists.gro.clinux.org>
	
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
 * 09/22/2005 	initial version
 *			walimis <wlm@student.dlut.edu.cn>
 */

#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "armdefs.h"
#include "skyeye_device.h"

#include "skyeye_options.h"
#include "skyeye.h"
#include "skyeye_flash.h"

extern void flash_intel_init(struct device_module_set *mod_set);
extern void flash_sst39lvf160_init(struct device_module_set *mod_set);
extern void flash_am29_init(struct device_module_set *mod_set);

/* initialize the flash module set.
 * If you want to add a new flash simulation, just add a "flash_*_init" function to it.
 * */
static void
flash_init (struct device_module_set *mod_set)
{
	flash_intel_init (mod_set);
	flash_sst39lvf160_init (mod_set);
	flash_am29_init (mod_set);
}
static int
flash_setup (struct device_desc *dev, void *option)
{
	struct flash_device *flash_dev;
	struct flash_option *flash_opt = (struct flash_option *) option;
	int ret = 0;

	flash_dev =
		(struct flash_device *) malloc (sizeof (struct flash_device));
	if (flash_dev == NULL)
		return 1;

	memset (flash_dev, 0, sizeof (struct flash_device));
	memcpy (&flash_dev->dump[0], &flash_opt->dump[0], MAX_STR_NAME);

	dev->dev = (void *) flash_dev;
	return ret;

}
static struct device_module_set flash_mod_set = {
	.name = "flash",
	.count = 0,
	.count_max = 0,
	.init = flash_init,
	.initialized = 0,
	.setup_module = flash_setup,
};

/* used by global device initialize function. 
 * */
void
flash_register ()
{
	if (register_device_module_set (&flash_mod_set))
		SKYEYE_ERR ("\"%s\" module set register error!\n",
			    flash_mod_set.name);
}

/* helper functions */
#ifdef __MINGW32__
	#include <io.h>
	#undef S_IREAD
	#undef S_IWRITE
	#undef O_CREAT
	#undef O_TRUNC
	#undef O_WRONLY
	#define S_IREAD				_S_IREAD
	#define S_IWRITE			_S_IWRITE
	#define O_CREAT				_O_CREAT
	#define O_TRUNC				_O_TRUNC
	#define O_WRONLY			(_O_WRONLY | _O_BINARY)
	#define open(file, flags, mode)		_open(file, flags, mode)
	#define close(fd)			_close(fd)
	#define write(fd, buf, count)		_write(fd, buf, count)
#else
	#include <sys/types.h>
	#include <sys/stat.h>
	#include <fcntl.h>
	#ifndef S_IREAD
		#define S_IREAD			S_IRUSR
	#endif
	#ifndef S_IWRITE
		#define S_IWRITE		S_IWUSR
	#endif
#endif


static int skyeye_flash_arm_read_word (uint32_t addr, uint32_t *data)
{
	/*
	extern mem_bank_t *global_mbp;
	extern mem_bank_t *bank_ptr(ARMword addr);
	*/
	ARMul_State *state = (ARMul_State*)skyeye_config.mach->state;
	/*
	if (data == NULL || state == NULL || (global_mbp = bank_ptr(addr)) == NULL ) return -1;
	*/
	//*data = real_read_word(state, addr);
	bus_read(state, addr, data);

#ifndef HOST_IS_BIG_ENDIAN
	if (state->bigendSig == HIGH)
#else
	if (state->bigendSig != HIGH)
#endif
		*data = ((*data & 0xff) << 24) | 
			 (((*data >> 8) & 0xff) << 16)  |
			 (((*data >> 16) & 0xff) << 8)  |
			 (((*data >> 24) & 0xff));

	return 0;
}

int skyeye_flash_dump (const char *filename, uint32_t base, uint32_t size)
{
	uint32_t addr, data;
	int fd;
	int (*read_word_func)(uint32_t, uint32_t*) = NULL;

	if (filename == NULL || *filename == 0 ||
	    skyeye_config.arch == NULL ||
	    skyeye_config.arch->arch_name == NULL) return -1;

	if (strcmp(skyeye_config.arch->arch_name, "arm") == 0) /* arm */
		read_word_func = skyeye_flash_arm_read_word;
	else /* TODO */
		return -1;

	fd = open(filename, O_CREAT | O_TRUNC | O_WRONLY, S_IREAD | S_IWRITE);
	if (fd == -1) return -1;

	for (addr = base; addr < base + size; addr += 4) {
		if ((*read_word_func)(addr, &data) != 0) {
			close(fd);
			return -1;
		}

		write(fd, &data, 4);
	}

	close(fd);

	return 0;
}

