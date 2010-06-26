/*
	skyeye_options.c - skyeye config file options' functions
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

/* 08/20/2003   add log option function
				chenyu
   4/02/2003	add net option function
 * 				walimis <walimi@peoplemail.com.cn>
 * 3/22/2003 	add cpu, mem_num, mem_bank, arch, dummy option function
 *				walimis <walimi@peoplemail.com.cn> 		
 * 10/24/2005	add dbct test speed function
 *				teawater <c7code-uc@yahoo.com.cn>
 * */
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "skyeye_options.h"
#include "skyeye_arch.h"
#include "skyeye_config.h"

#include "skyeye_arch.h"
#include "skyeye_config.h"

/* 2007-01-18 added by Anthony Lee: for new uart device frame */
#include "skyeye_uart.h"
#include "skyeye_net.h"
#include "skyeye_lcd.h"

extern FILE *skyeye_logfd;


int
split_param (const char *param, char *name, char *value)
{
	const char *src = param;
	char *dst = name;

	while (*src && (*src != '='))
		*dst++ = *src++;
	*dst = '\0';

	if (*src == '\0') {
		value = '\0';
		return -1;
	}

	strcpy (value, src + 1);
	return 0;
}


/* we need init some options before read the option file.
 * now put them here.
 * */

/* 2007-01-22 : SKYEYE4ECLIPSE moved to skyeye_config.c */

int
skyeye_option_init (skyeye_config_t * config)
{
	/* 2007-01-18 added by Anthony Lee: for new uart device frame */
	config->uart.count = 0;
	atexit(skyeye_uart_cleanup);

	/*ywc 2005-04-01 */
	config->no_dbct = 1;	/*default, dbct is off */
	//teawater add for new tb manage function 2005.07.10----------------------------
	config->tb_tbt_size = 0;
#if DBCT
	config->tb_tbp_size = TB_TBP_DEFAULT;
#else
	config->tb_tbp_size = 0;
#endif
}
int
do_dummy_option (skyeye_option_t * this_option, int num_params,
		 const char *params[])
{
	return 0;
};

/* parse "int" parameters. e.g. int=16:17*/
int
get_interrupts (char value[], u32 * interrupts)
{
	char *cur = value;
	char *next = value;
	int i = 0, end = 0;

	while ((*next != ':') && (*next != 0))
		next++;

	while (*cur != 0) {
		if (*next != 0) {
			*next = '\0';
		}
		else
			end = 1;
		interrupts[i] = strtoul (cur, NULL, 0);
		//printf("%s:%s\n", __FUNCTION__, cur);
		i++;
		if ((i > 4) || end == 1)
			return 0;
		cur = ++next;
		while ((*next != ':') && (*next != 0))
			next++;
	}
	return 0;
}

/** 
 * setup device option.
 * all device options may have common parameters. Here we handle these common parameters.
 * 
 */
int
setup_device_option (char *option_name, void *dev_option,
		     int num_params, const char *params[])
{
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];
	struct common_config conf;
	int i;

	memset (&conf, 0, sizeof (conf));
	conf.type = NULL;
	conf.name = NULL;

	for (i = 0; i < num_params; i++) {
		if (split_param (params[i], name, value) < 0)
			SKYEYE_ERR
				("Error: \"%s\" has wrong parameter \"%s\".\n",
				 option_name, name);
		if (!strncmp ("type", name, strlen (name))) {
			conf.type = strdup (value);
		}
		else if (!strncmp ("name", name, strlen (name))) {
			conf.name = strdup (value);
		}
		else if (!strncmp ("base", name, strlen (name))) {
			conf.base = strtoul (value, NULL, 0);
		}
		else if (!strncmp ("size", name, strlen (name))) {
			conf.size = strtoul (value, NULL, 0);
		}
		else if (!strncmp ("int", name, strlen (name))) {
			get_interrupts (value, conf.interrupts);
		}
	}
	setup_device (option_name, &conf, dev_option, skyeye_config.mach);
	if (conf.type)
		free (conf.type);
	if (conf.name)
		free (conf.name);
	return 0;

}

/* defined in skyeye_arch.c */
extern arch_config_t *skyeye_archs[];

int
do_arch_option (skyeye_option_t * this_option, int num_params,
		const char *params[])
{
	int i;
	arch_config_t *arch = skyeye_config.arch;
	char *default_arch = "arm";

	for (i = 0; i < MAX_SUPP_ARCH; i++) {
		if (skyeye_archs[i] == NULL)
			continue;
		if (!strncmp
		    (params[0], skyeye_archs[i]->arch_name, MAX_PARAM_NAME)) {
			skyeye_config.arch = skyeye_archs[i];
			SKYEYE_INFO ("arch: %s\n",
				     skyeye_archs[i]->arch_name);
			return 0;
		}
	}
	SKYEYE_ERR
		("Error: Unknowm architecture name \"%s\" or you use low version of skyeye?\n",
		 params[0]);
	return -1;
}

int
do_cpu_option (skyeye_option_t * this_option, int num_params,
	       const char *params[])
{
	int ret;

	if (skyeye_config.arch == NULL) {
		/* If we don't set arch, we use "arm" as default. */
		char *default_arch = "arm";
		int i;
		for (i = 0; i < MAX_SUPP_ARCH; i++) {
			if (skyeye_archs[i] == NULL)
				continue;
			if (!strncmp
			    (default_arch, skyeye_archs[i]->arch_name,
			     MAX_PARAM_NAME)) {
				skyeye_config.arch = skyeye_archs[i];
				SKYEYE_INFO ("arch: %s\n",
					     skyeye_archs[i]->arch_name);
			}
		}
		if (skyeye_config.arch == NULL) {
			SKYEYE_ERR
				("ERROR: No arch option found! Maybe you use low version of skyeye?\n");
			skyeye_exit (-1);
		}
	}
	ret = skyeye_config.arch->parse_cpu (params);
	if (ret < 0)
		SKYEYE_ERR ("Error: Unkonw cpu name \"%s\"\n", params[0]);
	return ret;
}

int
do_mach_option (skyeye_option_t * this_option, int num_params,
		const char *params[])
{
	int ret;
	machine_config_t *mach = skyeye_config.mach;
	ret = skyeye_config.arch->parse_mach (mach, params);
	if (ret < 0) {
		SKYEYE_ERR ("Error: Unkonw mach name \"%s\"\n", params[0]);
	}
	return ret;
}

int
do_mem_bank_option (skyeye_option_t * this_option, int num_params,
		    const char *params[])
{
	#if 0
	int ret;
	ret = skyeye_config.arch->parse_mem (num_params, params);
	if (ret < 0) {
		SKYEYE_ERR ("Error: Unkonw mem bank name \"%s\"\n",
			    params[0]);
	}
	return ret;
	#endif
	return parse_mem(num_params, params);
}


int
do_net_option (skyeye_option_t * this_option, int num_params,
	       const char *params[])
{
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];
	int i;
	struct net_option net_opt;
	unsigned char mac_addr[6];
	unsigned char hip[4];
	unsigned char *maddr, *ip;

	for (i = 0; i < num_params; i++) {
		if (split_param (params[i], name, value) < 0) {
			SKYEYE_ERR ("Error: %s has wrong parameter \"%s\".\n",
				    this_option->name, name);
			return -1;
		}
		if (!strncmp ("mac", name, strlen (name))) {
			sscanf (value, "%x:%x:%x:%x:%x:%x", &mac_addr[0],
				&mac_addr[1], &mac_addr[2], &mac_addr[3],
				&mac_addr[4], &mac_addr[5]);
			memcpy (net_opt.macaddr, mac_addr, 6);

		}
		else if (!strncmp ("hostip", name, strlen (name))) {
			/* FIXME: security problem, don't use sscanf later */
			sscanf (value, "%d.%d.%d.%d", &hip[0], &hip[1],
				&hip[2], &hip[3]);
			memcpy (net_opt.hostip, hip, 4);

		}
		else if (!strncmp ("ethmod", name, strlen (name))) {
			if (!strncmp ("linux", value, strlen (value))) {
				net_opt.ethmod = NET_MOD_LINUX;

			}
			else if (!strncmp ("tuntap", value, strlen (value))) {
				net_opt.ethmod = NET_MOD_TUNTAP;

			}
			else if (!strncmp ("vnet", value, strlen (value))) {
				net_opt.ethmod = NET_MOD_VNET;
			}
		}
	}
	maddr = net_opt.macaddr;
	ip = net_opt.hostip;
	printf ("ethmod num=%d, mac addr=%x:%x:%x:%x:%x:%x, hostip=%d.%d.%d.%d\n", net_opt.ethmod, maddr[0], maddr[1], maddr[2], maddr[3], maddr[4], maddr[5], ip[0], ip[1], ip[2], ip[3]);
	setup_device_option (this_option->name, (void *) &net_opt, num_params,
			     params);

	return 0;
}

/**
 * 
 * energy option
 */
int
do_energy_option (skyeye_option_t * this_option, int num_params,
		  const char *params[])
{
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];
	int i, fd;

	for (i = 0; i < num_params; i++) {
		if (split_param (params[i], name, value) < 0)
			SKYEYE_ERR
				("Error: energy has wrong parameter \"%s\".\n",
				 name);
		if (!strncmp ("state", name, strlen (name))) {
			if (!strncmp ("on", value, strlen (value))) {
				skyeye_config.energy.energy_prof = 1;
				SKYEYE_INFO
					("energy info: turn on energy!\n");
			}
			else {
				skyeye_config.energy.energy_prof = 0;
				SKYEYE_INFO
					("energy info: turn off energy!\n");
			}
		}
		else if (!strncmp ("filename", name, strlen (name))) {
			strcpy (skyeye_config.energy.filename, value);
			skyeye_config.energy.filename[strlen (value)] = '\0';
		}
		else if (!strncmp ("logfile", name, strlen (name))) {
			strcpy (skyeye_config.energy.logfile, value);
			skyeye_config.energy.logfile[strlen (value)] = '\0';
		}
	}
	return 0;

}



/*uart option*/
int
do_uart_option (skyeye_option_t * this_option, int num_params,
		const char *params[])
{
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];

	/* 2007-01-18 added by Anthony Lee: for new uart device frame */
	/* At default, if none options for uart were found,
	 * the function named "skyeye_read_config()" from "utils/config/skyeye_config.c" would insert
	 * a blank line in order to call this to make the uart simulation by standard input/output.
	 */
	struct uart_option uart_opt = {"", "", UART_SIM_STDIO, ""};
	int i, only_desc = 0;

	for (i = 0; i < num_params; i++)
	{
		if (split_param(params[i], name, value) < 0)
			SKYEYE_ERR("Error: uart has wrong parameter \"%s\".\n", name);

		if (!strncmp("converter", name, strlen(name))) {
			memcpy(&uart_opt.converter[0], value, strlen(value) + 1);
		}

		if (!strncmp("mod", name, strlen(name))) {
			if (!strncmp ("stdio", value, strlen (value)))
				uart_opt.mod = UART_SIM_STDIO;
			else if (!strncmp ("pipe", value, strlen (value)))
				uart_opt.mod = UART_SIM_PIPE;
			else if (!strncmp ("net", value, strlen (value)))
				uart_opt.mod = UART_SIM_NET;
		}

		/* for old style */
		if (!strncmp("fd_in", name, strlen(name))) {
			uart_opt.mod = UART_SIM_PIPE;
			memcpy(&uart_opt.desc_in[0], value, strlen(value) + 1);
		} else if (!strncmp("fd_out", name, strlen(name))) {
			uart_opt.mod = UART_SIM_PIPE;
			memcpy(&uart_opt.desc_out[0], value, strlen(value) + 1);
		}

		/* new style */
		if (!strncmp("desc", name, strlen(name))) {
			only_desc = 1;
			memcpy(&uart_opt.desc_in[0], value, strlen(value) + 1);
			uart_opt.desc_out[0] = '\0';
		} else if (only_desc == 0) {
			if (!strncmp("desc_in", name, strlen(name)))
				memcpy(&uart_opt.desc_in[0], value, strlen(value) + 1);
			else if (!strncmp("desc_out", name, strlen(name)))
				memcpy(&uart_opt.desc_out[0], value, strlen(value) + 1);
		}
	}

	skyeye_uart_setup(&uart_opt);

	return 0;
}


/* Anthony Lee 2006-09-07 */
static int lcd_mod_is_valid(int mod)
{
#ifdef GTK_LCD
	if(mod == LCD_MOD_GTK) return 1;
#endif
#ifdef WIN32_LCD
	if(mod == LCD_MOD_WIN32) return 1;
#endif
#ifdef BEOS_LCD
	if(mod == LCD_MOD_BEOS) return 1;
#endif
	return 0;
}


/* Anthony Lee 2006-09-07 */
static int lcd_valid_mod(void)
{
#ifdef GTK_LCD
	return LCD_MOD_GTK;
#else
#ifdef WIN32_LCD
	return LCD_MOD_WIN32;
#else
#ifdef BEOS_LCD
	return LCD_MOD_BEOS;
#else
	return LCD_MOD_NONE;
#endif
#endif
#endif
}


/*chy 2004-03-11 lcd option*/
int
do_lcd_option (skyeye_option_t * this_option, int num_params,
	       const char *params[])
{
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];
	struct lcd_option lcd_opt;
	int i, fd;

	for (i = 0; i < num_params; i++) {
		if (split_param (params[i], name, value) < 0)
			SKYEYE_ERR
				("Error: lcd has wrong parameter \"%s\".\n",
				 name);
		if (!strncmp ("mod", name, strlen (name))) {
			if (!strncmp ("gtk", value, strlen (value))) {
				lcd_opt.mod = LCD_MOD_GTK;
			}
			else if (!strncmp ("qt", value, strlen (value))) {
				lcd_opt.mod = LCD_MOD_QT;
			}
			else if (!strncmp ("x", value, strlen (value))) {
				lcd_opt.mod = LCD_MOD_X;
			}
			else if (!strncmp ("sdl", value, strlen (value))) {
				lcd_opt.mod = LCD_MOD_SDL;
			}
			else if (!strncmp ("win32", value, strlen (value))) {
				lcd_opt.mod = LCD_MOD_WIN32;
			}
			else if (!strncmp ("beos", value, strlen (value))) {
				lcd_opt.mod = LCD_MOD_BEOS;
			}
		}
	}

	if (lcd_mod_is_valid(lcd_opt.mod) == 0) lcd_opt.mod = lcd_valid_mod();
	if (lcd_opt.mod == LCD_MOD_NONE) return 0;

	setup_device_option (this_option->name, (void *) &lcd_opt, num_params,
			     params);

	return 0;
}

/*ywc 2005-04-01 dbct option*/
int
do_dbct_option (skyeye_option_t * this_option, int num_params,
		const char *params[])
{
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];
	int i, fd;

	for (i = 0; i < num_params; i++) {
		if (split_param (params[i], name, value) < 0)
			SKYEYE_ERR
				("Error: dbct has wrong parameter \"%s\".\n",
				 name);
		if (!strncmp ("state", name, strlen (name))) {
			if (!strncmp ("on", value, strlen (value))) {
				skyeye_config.no_dbct = 0;
#ifndef NO_DBCT
				SKYEYE_INFO ("dbct info: turn on dbct!\n");
#else
				SKYEYE_INFO
					("dbct info: Note: DBCT not compiled in. This option will be ignored\n");
#endif
			}
			else {
				skyeye_config.no_dbct = 1;
				SKYEYE_INFO ("dbct info: turn off dbct!\n");
			}
		}
		//teawater add for new tb manage function 2005.07.10----------------------------
		if (!strncmp ("tbt", name, strlen (name))) {
			skyeye_config.tb_tbt_size = strtoul (value, NULL, 0);
		}
		if (!strncmp ("tbp", name, strlen (name))) {
			skyeye_config.tb_tbp_size = strtoul (value, NULL, 0);
		}
	}
	return 0;
}

//chy:2003-08-20 do_log option
int
do_log_option (skyeye_option_t * this_option, int num_params,
	       const char *params[])
{
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];
	int i, fd, logon, memlogon;
	unsigned long long start, end, length;
	/*2004-08-09 chy init skyeye_config.log */
	skyeye_config.log.log_fd = 0;
	skyeye_config.log.logon = 0;
	skyeye_config.log.memlogon = 0;
	skyeye_config.log.start = 0;
	skyeye_config.log.end = 0;
	skyeye_config.log.length = 0;

	for (i = 0; i < num_params; i++) {
		if (split_param (params[i], name, value) < 0)
			SKYEYE_ERR
				("log_info: Error: log has wrong parameter \"%s\".\n",
				 name);
		if (!strncmp ("logon", name, strlen (name))) {
			sscanf (value, "%d", &logon);
			if (logon != 0 && logon != 1)
				SKYEYE_ERR
					("log_info: Error logon value %d\n",
					 logon);
			if (logon == 1) {
				SKYEYE_INFO ("log_info: log is on.\n");
			}
			else {
				SKYEYE_INFO ("log_info: log is off.\n");
			}
			skyeye_config.log.logon = logon;
		}
		else if (!strncmp ("memlogon", name, strlen (name))) {
			sscanf (value, "%d", &memlogon);
			if (memlogon != 0 && memlogon != 1)
				SKYEYE_ERR
					("log_info: Error logon value %d\n",
					 memlogon);
			if (memlogon == 1) {
				SKYEYE_INFO ("log_info: memory klog is on.\n");
			}
			else {
				SKYEYE_INFO ("log_info: memory log is off.\n");
			}
			skyeye_config.log.memlogon = memlogon;
		}
		else if (!strncmp ("logfile", name, strlen (name))) {
			if ((skyeye_logfd = fopen (value, "w+")) == NULL) {
				//SKYEYE_DBG("SkyEye Error when open log file %s\n", value);
				perror ("SkyEye: Error when open log file:  ");
				skyeye_exit (-1);
			}
			skyeye_config.log.log_fd = skyeye_logfd;
			SKYEYE_INFO ("log_info:log file is %s, fd is 0x%x\n",
				     value, skyeye_logfd);
		}
		else if (!strncmp ("start", name, strlen (name))) {
			start = strtoul (value, NULL, 0);
			skyeye_config.log.start = start;
			SKYEYE_INFO ("log_info: log start clock %llu\n",
				     start);
		}
		else if (!strncmp ("end", name, strlen (name))) {
			end = strtoul (value, NULL, 0);
			skyeye_config.log.end = end;
			SKYEYE_INFO ("log_info: log end clock %llu\n", end);
		}
		else if (!strncmp ("length", name, strlen (name))) {
			sscanf (value, "%llu", &length);
			skyeye_config.log.length = length;
			SKYEYE_INFO ("log_info: log instr length %llu\n",
				     length);
		}
		else
			SKYEYE_ERR ("Error: Unkonw cpu name \"%s\"\n", params[0]);
	}

	return 0;
}


/*
 * we can add this option using:
 * step_disassemble:on[ON|1] for open this option
 * step_disassemble:off[OFF|0] for disable this option 
 * oyangjian add here
 */
int
do_step_disassemble_option (skyeye_option_t * this_option, int num_params,
			    const char *params[])
{
	int i;

	for (i = 0; i < num_params; i++) {
		printf ("step_disassemble state:%s\n", params[0]);
		if (!params[0]) {
			SKYEYE_ERR ("Error :usage: step_disassemble:on[off]");
			return -1;
		}
		if (!strncmp (params[0], "on", 2)
		    || !strncmp (params[0], "ON", 2)) {
			skyeye_config.can_step_disassemble = 1;
			return 0;
		}
		else if (!strncmp (params[0], "off", 3)
			 || !strncmp (params[0], "OFF", 3)) {

			skyeye_config.can_step_disassemble = 0;
			return 0;
		}

	}
	SKYEYE_ERR ("Error: Unkonw cpu name \"%s\"\n", params[0]);
	return -1;
}

int
do_flash_option (skyeye_option_t * this_option, int num_params,
		 const char *params[])
{
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];
	struct flash_option flash_opt;
	int i, fd;

	memset(&flash_opt, 0, sizeof(struct flash_option));

	for (i = 0; i < num_params; i++) {
		if (split_param (params[i], name, value) < 0)
			SKYEYE_ERR
				("Error: flash has wrong parameter \"%s\".\n",
				 name);

		if (!strncmp("dump", name, strlen(name))) {
			memcpy(&flash_opt.dump[0], value, strlen(value) + 1);
		}
	}

	SKYEYE_INFO ("flash: dump %s\n",
		     flash_opt.dump[0] == 0 ? "none" : flash_opt.dump);

	setup_device_option (this_option->name, (void *) &flash_opt,
			     num_params, params);

	return 0;
}

int
do_nandflash_option (skyeye_option_t * this_option, int num_params,
		 const char *params[])
{
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];
	struct flash_option flash_opt;
	int i, fd;

	memset(&flash_opt, 0, sizeof(struct flash_option));

	for (i = 0; i < num_params; i++) {
		if (split_param (params[i], name, value) < 0)
			SKYEYE_ERR
				("Error: flash has wrong parameter \"%s\".\n",
				 name);

		if (!strncmp("dump", name, strlen(name))) {
			memcpy(&flash_opt.dump[0], value, strlen(value) + 1);
		}
	}

	SKYEYE_INFO ("nandflash: dump %s\n",
		     flash_opt.dump[0] == 0 ? "none" : flash_opt.dump);

	setup_device_option (this_option->name, (void *) &flash_opt,
			     num_params, params);

	return 0;
}


int
do_touchscreen_option (skyeye_option_t * this_option, int num_params,
		       const char *params[])
{
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];
	struct touchscreen_option ts_opt;
	int i;

	for (i = 0; i < num_params; i++) {
		if (split_param (params[i], name, value) < 0)
			SKYEYE_ERR
				("Error: touchscreen has wrong parameter \"%s\".\n",
				 name);

		/* TODO */
	}

	setup_device_option (this_option->name, (void*)&ts_opt,
			     num_params, params);

	return 0;
}

int
do_sound_option (skyeye_option_t * this_option, int num_params,
		 const char *params[])
{
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];
	struct sound_option snd_opt;
	int i;

	memset (&snd_opt, 0, sizeof(snd_opt));

	for (i = 0; i < num_params; i++) {
		if (split_param (params[i], name, value) < 0)
			SKYEYE_ERR
				("Error: sound has wrong parameter \"%s\".\n",
				 name);
		if (!strncmp ("mod", name, strlen (name))) {
			if (!strncmp ("pcm", value, strlen (value))) {
				snd_opt.mod = 1; /* SOUND_SIM_PCM */
			}
		}
		if (!strncmp ("channels", name, strlen (name))) {
			sscanf (value, "%d", &snd_opt.channels);
		}
		if (!strncmp ("bits_per_sample", name, strlen (name))) {
			sscanf (value, "%d", &snd_opt.bits_per_sample);
		}
		if (!strncmp ("samples_per_sec", name, strlen (name))) {
			sscanf (value, "%d", &snd_opt.samples_per_sec);
		}
	}

	if (snd_opt.mod == 0) return 0;

	SKYEYE_INFO ("sound: channels:%d, bits_per_sample:%d, samples_per_sec:%d.\n",
		     snd_opt.channels, snd_opt.bits_per_sample, snd_opt.samples_per_sec);

	setup_device_option (this_option->name, (void*)&snd_opt,
			     num_params, params);

	return 0;
}

//teawater add DBCT_TEST_SPEED 2005.10.04---------------------------------------
#ifdef DBCT_TEST_SPEED
int
do_dbct_test_speed_sec(struct skyeye_option_t *this_opion, int num_params, const char *params[])
{
	if (num_params != 1) {
		goto error_out;
	}
	errno = 0;
	skyeye_config.dbct_test_speed_sec = strtol(params[0], NULL, 10);
	if (errno == ERANGE) {
		goto error_out;
	}
	printf("dbct_test_speed_sec %ld\n", skyeye_config.dbct_test_speed_sec);

error_out:
	SKYEYE_ERR("Error :usage: step_disassemble: dbct_test_speed_sec\n");
	return(-1);
}
#endif	//DBCT_TEST_SPEED
//AJ2D--------------------------------------------------------------------------

/* set values for some register */
int
do_regfile_option (skyeye_option_t * this_option, int num_params,
		 const char *params[])
{

	if(skyeye_config.arch && skyeye_config.arch->parse_regfile)
		skyeye_config.arch->parse_regfile(num_params, params);
	else
		SKYEYE_WARNING("regfile option is not implemented by current arch\n");
	return 0;
}

/* set load address for elf image */
int
do_load_addr_option (skyeye_option_t * this_option, int num_params,

		 const char *params[])
{
	int i;
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];
	extern unsigned long load_base;
	extern unsigned long load_mask;
	for (i = 0; i < num_params; i++) {
		if (split_param (params[i], name, value) < 0)
			SKYEYE_ERR
				("Error: sound has wrong parameter \"%s\".\n",
				 name);
		if (!strncmp ("base", name, strlen (name))) {
			sscanf (value, "%x", &load_base);
		}
		else if (!strncmp ("mask", name, strlen (name))) {
			sscanf (value, "%x", &load_mask);
		}
		else
                        SKYEYE_ERR ("Error: Unkonw load_addr option  \"%s\"\n", params[i]);
	}
	printf("Your elf file will be load to: base address=0x%x,mask=0x%x\n", load_base, load_mask);
	return 0;
}

/**
 * code coverage option
 */
int
do_code_cov_option (skyeye_option_t * this_option, int num_params,
		  const char *params[])
{
	char name[MAX_PARAM_NAME], value[MAX_PARAM_NAME];
	int i, start, end;

	for (i = 0; i < num_params; i++) {
		if (split_param (params[i], name, value) < 0)
			SKYEYE_ERR
				("Error: code coverage has wrong parameter \"%s\".\n",
				 name);
		if (!strncmp ("state", name, strlen (name))) {
			if (!strncmp ("on", value, strlen (value))) {
				skyeye_config.code_cov.prof_on = 1;
				SKYEYE_INFO
					("code coverage info: turn on profiling!\n");
			}
			else {
				skyeye_config.code_cov.prof_on = 0;
				SKYEYE_INFO
					("code coverage info: turn off profiling!\n");
			}
		}
		else if (!strncmp ("filename", name, strlen (name))) {
			strcpy (skyeye_config.code_cov.prof_filename, value);
			skyeye_config.code_cov.prof_filename[strlen (value)] = '\0';
		}
		else if (!strncmp ("start", name, strlen (name))) {
			start = strtoul (value, NULL, 0);
			skyeye_config.code_cov.start = start;
			SKYEYE_INFO ("log_info: log start clock %llu\n",
				     start);
		}
		else if (!strncmp ("end", name, strlen (name))) {
			end = strtoul (value, NULL, 0);
			skyeye_config.code_cov.end = end;
			SKYEYE_INFO ("log_info: log end clock %llu\n", end);
		}
	}
	return 0;
}

