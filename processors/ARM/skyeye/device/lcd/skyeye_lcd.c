/*
	skyeye_lcd.c - skyeye general lcd device file support functions
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
 * 06/22/2005 	initial version
 *			walimis <wlm@student.dlut.edu.cn>
 */

#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "armdefs.h"
#include "arch/mips/common/mipsdef.h"
#include "skyeye_device.h"
#include "skyeye_options.h"
#include "skyeye.h"
#include "skyeye_lcd.h"

/* initialize the lcd module set.
 * If you want to add a new lcd simulation, just add a "lcd_*_init" function to it.
 * */
static void
lcd_init (struct device_module_set *mod_set)
{
	lcd_ep7312_init (mod_set);
	lcd_pxa_init (mod_set);
	lcd_s3c2410_init (mod_set);
	lcd_s3c44b0x_init (mod_set);
	lcd_au1100_init (mod_set);
}
static int
lcd_setup (struct device_desc *dev, void *option)
{
	struct lcd_device *lcd_dev;
	struct lcd_option *lcd_opt = (struct lcd_option *) option;
	int ret = 0;

	lcd_dev = (struct lcd_device *) malloc (sizeof (struct lcd_device));
	if (lcd_dev == NULL) return -1;

	memset (lcd_dev, 0, sizeof (struct lcd_device));

	lcd_dev->mod = lcd_opt->mod;
	printf ("lcd_mod:%d\n", lcd_dev->mod);
	switch (lcd_dev->mod) {
#ifdef GTK_LCD
		case LCD_MOD_GTK:
			ret = gtk_lcd_init(lcd_dev);
			break;
#endif
#ifdef WIN32_LCD
		case LCD_MOD_WIN32:
			ret = win32_lcd_init(lcd_dev);
			break;
#endif
#ifdef BEOS_LCD
		case LCD_MOD_BEOS:
			ret = beos_lcd_init(lcd_dev);
			break;
#endif
		default:
			ret = -1;
			break;
	}

	if (ret != 0) {
		free(lcd_dev);
		lcd_dev = NULL;
	}

	dev->dev = (void *) lcd_dev;
	return ret;
}

static struct device_module_set lcd_mod_set = {
	.name = "lcd",
	.count = 0,
	.count_max = 0,
	.init = lcd_init,
	.initialized = 0,
	.setup_module = lcd_setup,
};

/* used by global device initialize function. 
 * */
void
lcd_register ()
{
	if (register_device_module_set (&lcd_mod_set))
		SKYEYE_ERR ("\"%s\" module set register error!\n",
			    lcd_mod_set.name);
}

/* help functions. */
unsigned char* skyeye_find_lcd_dma (struct lcd_device *lcd_dev)
{
	unsigned char *dma = NULL;
	extern unsigned char * get_dma_addr(unsigned long guest_addr);

	if (lcd_dev == NULL ||
	    skyeye_config.arch == NULL ||
	    skyeye_config.arch->arch_name == NULL) return NULL;
	dma = get_dma_addr(lcd_dev->lcd_addr_begin);
#if 0
	if (strcmp(skyeye_config.arch->arch_name, "arm") == 0) { /* arm */
		extern mem_bank_t *bank_ptr(ARMword addr);
		mem_bank_t *mbp;
		ARMul_State *state = (ARMul_State*)lcd_dev->state;

		if(!(state == NULL || (mbp = bank_ptr(lcd_dev->lcd_addr_begin)) == NULL)) {
			dma = (unsigned char*)(&state->mem.rom[(mbp - state->mem_bank->mem_banks)]
							      [(lcd_dev->lcd_addr_begin - mbp->addr) >> 2]);
		}
	}

	if (strcmp(skyeye_config.arch->arch_name, "mips") == 0) { /* mips */
		extern mips_mem_state_t mips_mem;
		extern mips_mem_bank_t *mips_global_mbp;
		extern mips_mem_config_t mips_mem_config;
		int i;
		unsigned long addr, len;

		for (i = 0; i < mips_mem_config.bank_num; i++) {
			addr = mips_mem_config.mem_banks[i].addr;
			len = mips_mem_config.mem_banks[i].len;
			if (addr <= lcd_dev->lcd_addr_begin && addr + len > lcd_dev->lcd_addr_begin) break;
		}

		if (i != mips_mem_config.bank_num) {
			dma = (unsigned char*)&(mips_mem.rom[mips_global_mbp - mips_mem_config.mem_banks]
							    [(lcd_dev->lcd_addr_begin - mips_global_mbp->addr) >> 2]);
		}
	}
#endif
	/* TODO: blackfin, coldfire, etc. */

	return dma;
}

void skyeye_convert_color_from_lcd_dma (struct lcd_device *lcd,
					int x, int y, int w, int h,
					void (*func)(u32, void*, void*),
					void *user_data1, void *user_data2)
{
	const u8 *dma = skyeye_find_lcd_dma(lcd);
	const u32 *buf;
	const u16 *buf16;
	const u8 *buf8;
	u32 block, color, c;
	int dx, dy, exw, exb, line_width;
	int i, k;

	if (dma == NULL || lcd->lcd_lookup_color == NULL || func == NULL) return;
	if (!(lcd->depth == 1 || lcd->depth == 2 || lcd->depth == 4 ||
	      lcd->depth == 8 || lcd->depth == 16 || lcd->depth == 32)) return;
	if (lcd->width <= 0 || x < 0 || w <= 0 || x + w > lcd->width) return;
	if (lcd->height <= 0 || y < 0 || h <= 0 || y + h > lcd->height) return;

	line_width = (lcd->width + (int)lcd->lcd_line_offset);

	for (dy = y; dy < y + h; dy++) {

		exw = (((line_width * dy + x) * lcd->depth) % 32) / 8;
		exb = ((line_width * dy + x) * lcd->depth) % 8;
		buf = (const u32*)(dma + 4 * (((line_width * dy + x) * lcd->depth) / 32));

		for (dx = x; dx < x + w; buf++) {

			block = *buf;
#ifndef HOST_IS_BIG_ENDIAN
			if (lcd->lcd_dma_swap_word == 1) {
#else
			if (lcd->lcd_dma_swap_word == 0) {
#endif
				block = (((block & 0xff) << 24) |
					 ((block & 0xff00) << 8) |
					 ((block & 0xff0000) >> 8) |
					 (block >> 24));
			}
			buf8 = (u8*)&block;
			buf16 = (u16*)&block;

			for (i = exw; i < 4 && dx < x + w; exw = 0) {
				if (lcd->depth < 16) { /* lcd->depth: 1, 2, 4, 8 */
					color = (u32)(*(buf8 + (lcd->lcd_color_right_to_left == 0 ? i : 3 - i)));
					for (k = exb; k < 8 && dx < x + w; k += lcd->depth, exb = 0) {
						if (lcd->lcd_color_right_to_left == 0)
							c = ((color >> (8 - (k + lcd->depth))) & ((1 << lcd->depth) - 1));
						else
							c = ((color >> k) & ((1 << lcd->depth) - 1));
						(*func)(lcd->lcd_lookup_color(lcd, c), user_data1, user_data2);
						dx++;
					}
					i += 1;
				}
				else if (lcd->depth == 16) {
					if (lcd->lcd_color_right_to_left == 0)
						color = (u32)(*(buf16 + (i == 0 ? 0 : 1)));
					else
						color = (u32)(*(buf16 + (i == 0 ? 1 : 0)));
					(*func)(lcd->lcd_lookup_color(lcd, color), user_data1, user_data2);
					dx++;
					i += 2;
				} else { /* lcd->depth: 32 */
					color = block;
					(*func)(lcd->lcd_lookup_color(lcd, color), user_data1, user_data2);
					dx++;
					break;
				}
			}
		}
	}
}

