/*
	skyeye_config.c - config file interface for skyeye
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
 * 3/21/2003 	Add config file interface to skyeye. 
 * 		Rename memmap.conf to skyeye.conf
 *		walimis <walimi@peoplemail.com.cn> 		
 * */

#include "skyeye_defs.h"
#include "skyeye_config.h"

//chy 2005-07-30
extern char *skyeye_config_filename;	//in skyeye.c
//int skyeye_instr_debug=0;
FILE *skyeye_logfd;

 /**/ int
parse_line_unformatted (char *line)
{
#define MAX_PARAMS_LEN 40
	char *ptr;
	unsigned i, string_i;
	char string[512];
	char *params[MAX_PARAMS_LEN];
	int num_params;
	int inquotes = 0;
	int comment = 0;
	int retval = 0;

	memset (params, 0, sizeof (params));
	if (line == NULL)
		return 0;
	/*if passed nothing but whitespace, just return */
	for (i = 0; i < strlen (line); i++) {
		if (!isspace (line[i]))
			break;
	}
	if (i >= strlen (line))
		return 0;

	num_params = 0;

	ptr = strtok (line, ":");
	while ((ptr) && (!comment)) {
		string_i = 0;
		for (i = 0; i < strlen (ptr); i++) {
			if (ptr[i] == '"')
				inquotes = !inquotes;
			else if ((ptr[i] == '#') && !inquotes) {
				comment = 1;
				break;
			}
			else {
				if (!isspace (ptr[i]) || inquotes)
					string[string_i++] = ptr[i];
			}
		}
		string[string_i] = '\0';
		if (string_i == 0)
			break;
		if (params[num_params] != NULL) {
			free (params[num_params]);
			params[num_params] = NULL;
		}
		if (num_params < MAX_PARAMS_LEN) {
			//chy 2003-08-21, only malloc string_i byte  is error!
			//params[num_params] = malloc(string_i);
			params[num_params] =
				malloc ((string_i + 16) & 0xfffffff0);
			if (!params[num_params]) {
				printf ("SKYEYE:parse_line_unformatted: malloc params[%d] error\n", num_params);
				skyeye_exit (-1);
			}
			strncpy (params[num_params], string, string_i);
			params[num_params][string_i] = '\0';
			num_params++;
			ptr = strtok (NULL, ",");
		}
		else {
			fprintf (stderr, "too many parameters, max is %d\n",
				 MAX_PARAMS_LEN);
		}
	}			/*end while */
	/*
	   for (i=0; i < MAX_PARAMS_LEN; i++)
	   {
	   if ( params[i] != NULL )
	   {
	   if (i == 0)

	   printf("****option: %s****\n", params[i]);
	   else
	   printf("params %d: %s\n", i, params[i]);
	   }
	   }
	 */
	retval = parse_line_formatted (num_params, &params[0]);
	for (i = 0; i < MAX_PARAMS_LEN; i++) {
		if (params[i] != NULL) {
			free (params[i]);
			params[i] = NULL;
		}
	}
	return retval;
}

/*parse every line that has been formatted
 * return -1: if a  option has exceeded it's max number or
 * 	option's do_option function has a error or
 * 	there is an unkonw option.
 * 	upper level function should print error and exit.
 * */
int
parse_line_formatted (int num_params, const char *params[])
{
	int i;
	skyeye_option_t *sop = skyeye_options;
	int len = sizeof (skyeye_options) / sizeof (skyeye_option_t);
	int retval = 0;

	if (num_params < 1)
		return 0;

	for (i = 0; i < len; i++, sop++) {
		if (!strncmp (sop->name, params[0], MAX_OPTION_NAME)) {
			sop->do_num++;
			if (sop->do_num > sop->max_do_num) {
				 /**/ fprintf (stderr,
					       "\"%s\" option has exceeded max number %d!\n",
					       params[0], sop->max_do_num);
				return -1;
			}
			else if (retval = sop->do_option (sop, num_params - 1,
							  &params[1]) < 0) {
				fprintf (stderr,
					 "\"%s\" option parameter error!\n",
					 params[0]);
				return retval;
			}
			else
				return retval;

		}
	}
	fprintf (stderr, "Unkonw option: %s\n", params[0]);
	return -1;		/* unknow option specified */
}

/* 2007-01-22 : SKYEYE4ECLIPSE from skyeye_options.c */
//chy 2004-12-05 for eclipse
//#define SKYEYE4ECLIPSE
#ifdef SKYEYE4ECLIPSE
extern char *inferior_io_terminal;
#endif
//------------------------------

extern void usage();
extern void display_all_support();
int
skyeye_read_config ()
{
	FILE *config_fd;
	char *ret;
	char line[MAX_STR];

	//chy 2005-07-30
	//char *config_file = DEFAULT_CONFIG_FILE;
	if (skyeye_config_filename == NULL)
		skyeye_config_filename = DEFAULT_CONFIG_FILE;
	strncpy (skyeye_config.config_file, skyeye_config_filename,
		 MAX_FILE_NAME);

	if (config_fd = fopen (skyeye_config.config_file, "r")) {
		int retval = 0;
		int len = 0;

		do {
			ret = fgets (line, sizeof (line) - 1, config_fd);
			line[sizeof (line) - 1] = '\0';
			len = strlen (line);
			if (len > 0)
				line[len - 1] = '\0';
			if ((ret != NULL) && strlen (line)) {
				if (parse_line_unformatted (line) < 0) {
					retval = -1;
					break;	// quit parsing after first error
				}
			}
		}
		while (!feof (config_fd));

		/* 2007-01-18 added by Anthony Lee: for new uart device frame */
		if(skyeye_config.uart.count == 0)
		{
#ifndef SKYEYE4ECLIPSE
			char tmp[] = "uart: mod=stdio";
#else
			char tmp[1024];
			snprintf(tmp, sizeof(tmp), "uart: mod=pipe, desc=%s",
				 inferior_io_terminal, inferior_io_terminal);
#endif
			if(parse_line_unformatted(tmp) < 0) retval = -1;
		}

		if (retval < 0) {
			fprintf (stderr,
				 "skyeye_read_config: config file %s have errors!\n",
				 skyeye_config.config_file);
			return -1;
		}
	}
	else {
		fprintf (stderr,
			 "Failed to open skyeye config file %s in the same directory\n",
			 skyeye_config.config_file);
		perror ("error");
		usage ();
		display_all_support();
		return -1;
	}
//chy 2003-08-20
#if 0
	//chy 2003-07-11: add log file
	skyeye_logfd = 0;
	skyeye_instr_debug = 1;
	if (skyeye_logfd = fopen ("/tmp/skyeyelog", "w+"))
		fprintf (stderr, "skyeye log file is /tmp/skyeyelog\n");
	else {
		fprintf (stderr,
			 "create skyeye log file failed, /tmp/skyeyelog\n");
		perror ("error");
		exit (0);
	}
#endif
	return 0;
}
