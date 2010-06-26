/*************************************/
/*                                   */
/*    Copyright 2000, David Grant    */
/*                                   */
/*  see ../LICENSE for more details  */
/*                                   */
/*************************************/

/* THANKS: to the WINE project.. www.winehq.com.. for many ideas on how
 * to make this :) */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include "tracer.h"

#define TRACER_DECLARE(ch) {#ch,0},

struct _TRACER_Info TRACER_Info[] = {
#include "generated.channels.h"
	{NULL,0}
};
#undef TRACER_DECLARE

int tracer_indent=0;
int tracer_printf(char *msg, ...) 
{
	va_list Args;
	int x;

/*f(*msg=='+')
		tracer_indent++;*/

/*f(*msg!=':') {
		printf("%02d:" tracer_indent);
		for(x=0;x<tracer_indent;x++)
        		printf("  ");
	}
*/
        va_start(Args,msg);
        x=vprintf(msg, Args);
        va_end(Args);

/*f(*msg=='-')
		tracer_indent--;*/
	return x;
}

int tracer_setuptrace(char *str)
{
	char *s, *original_s;
	char *ptr;
	int x;
	char enable;
	if(!str) return 0;

	s = malloc(strlen(str) + 1);
	strcpy(s, str);
	original_s = s;
	
	while(1) {
		enable=1;
		ptr=strchr(s,',');
		if(ptr) *ptr=0;
		
		if(s[0] == '-') { 
			enable=0;
			s++;
		}
		
		for(x=0;TRACER_Info[x].Name != NULL; x++) {
			if(strcmp(TRACER_Info[x].Name,s)==0 
					|| strcmp("all",s)==0) {
				TRACER_Info[x].Enabled=enable;
			}
		}
		
		/* End of string, break. */
		if(!ptr) break;
		s = ptr+1;
	}
	printf("Tracing [");
	for(x=0;TRACER_Info[x].Name != NULL; x++) {
		if(TRACER_Info[x].Enabled)  {
			printf(" %s ", TRACER_Info[x].Name);	
		}
	}
	printf("]\n");
	free(original_s);
	return 1;
}
