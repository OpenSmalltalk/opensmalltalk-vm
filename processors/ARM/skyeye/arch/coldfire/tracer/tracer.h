/*************************************/
/*                                   */
/*    Copyright 2000, David Grant    */
/*                                   */
/*  see ../LICENSE for more details  */
/*                                   */
/*************************************/
#ifndef TRACER_H
#define TRACER_H
/* THANKS: to the WINE project.. www.winehq.com.. for many ideas on how
 * to make this :) */

/* If you define TRACER_OFF in your code, it will compile out all the tracer
 * stuff for that source file */
#ifdef TRACER_OFF
	#undef TRACER_ENABLE
#else
	#define TRACER_ENABLE
#endif

struct _TRACER_Info {
	char *Name;
	char Enabled;
};

extern struct _TRACER_Info TRACER_Info[];

int tracer_printf(char *msg, ...);
int tracer_setuptrace(char *str);

#define TRACER_DECLARE(ch) TRACER_##ch,
enum _TRACER_Channels {
	#include "generated.channels.h"
	TRACER_Last
};
#undef TRACER_DECLARE


#define __TPRINTF_DUMMY(x...)

#define __TPRINTF(chnumber) if(TRACER_Info[chnumber].Enabled) \
			tracer_printf("%s:%s(): ",TRACER_Info[chnumber].Name, \
						__FUNCTION__),\
			tracer_printf 
		
#ifdef TRACER_ENABLE
	#define TRACER_DEFAULT_CHANNEL(ch) static const enum _TRACER_Channels TRACER_default = TRACER_##ch
	#define TRACE      __TPRINTF(TRACER_default)
	#define TRACE_(ch) __TPRINTF(TRACER_##ch)
 
	/*
	#define ERR tracer_printf("%s:%s(): ",TRACER_Info[TRACER_default].Name,__FUNCTION__);\
   					 tracer_printf
	*/

	#define ERR tracer_printf("%s:%s(): ",__FILE__,__FUNCTION__);\
                                         tracer_printf

 
	#define ERR_(ch)   tracer_printf("%s:%s(): ",TRACER_Info[TRACER_##ch].Name,__FUNCTION__);\
   					 tracer_printf
	#define IFTRACE         (TRACER_Info[TRACER_default].Enabled)
	#define IFTRACE_(ch)    (TRACER_Info[ch].Enabled)
#else
	#define TRACER_DEFAULT_CHANNEL(ch) 
					 
	#define TRACE      __TPRINTF_DUMMY
	#define TRACE_(ch) __TPRINTF_DUMMY

	#define ERR        __TPRINTF_DUMMY
	#define ERR_(ch)   __TPRINTF_DUMMY

	#define IFTRACE         0
	#define IFTRACE_(ch)    0

#endif
#endif
