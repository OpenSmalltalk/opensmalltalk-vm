/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#ifndef __COLDFIRE_H__
#define __COLDFIRE_H__

#include <stdio.h>
#include <string.h>

#include "skyeye.h"

struct _Instruction {
	void (*FunctionPtr)(void);
	unsigned short Code;
	unsigned short Mask;
	int (*DIFunctionPtr)(char *Instruction, char *Arg1, char *Arg2);
};

/* This is ALWAYS cast into a longword, so we need to pad it to a longword */
struct _InstructionExtensionWord {
#ifndef WORDS_BIGENDIAN					
	signed Displacement:8;
	unsigned EV:1;
	unsigned Scale:2;
	unsigned WL:1;
	unsigned Register:3;
	unsigned AD:1;
	unsigned pad:16;
#else
	unsigned pad:16;
	unsigned AD:1;
	unsigned Register:3;
	unsigned WL:1;
	unsigned Scale:2;
	unsigned EV:1;
	signed Displacement:8;
#endif
};

enum {
	I_ADD, I_ADDA, I_ADDI, I_ADDQ, I_ADDX,
	I_AND, I_ANDI, I_ASL, I_ASR, I_BCC, I_BCHG, I_BCLR, I_BRA,
	I_BSET, I_BSR, I_BTST, I_CLR, I_CMP, I_CMPA, I_CMPI,
	I_DIVS, I_DIVL, I_DIVU, I_DIVUL, I_EOR, I_EORI, I_EXT, I_JMP, I_JSR,
	I_LEA, I_LINK, I_LSR, I_LSL, I_MOVE, I_MOVEC, I_MOVEA, I_MOVEM, I_MOVEQ,
	I_MOVETOSR, I_MULS, I_MULU, I_NEG, I_NEGX, I_NOP, I_NOT, I_OR,
	I_ORI, I_RTE, I_RTS, I_SCC, I_SUB, I_SUBA, I_SUBI, I_SUBQ, I_SUBX,
	I_SWAP, I_TRAP, I_TRAPF, I_TST, I_UNLK,

	I_LAST
};

enum _coldfire_cpu_id {
	CF_NULL, 
	CF_5206,
	CF_5206e,
	CF_5276, 
	CF_5307,
	CF_5407,
	CF_LAST
};

	
#define INSTRUCTION_(I,A) \
	typedef union _##I##_instr {			\
		struct _##I##_bits {			\
				A;			\
			} Bits;				\
			unsigned int Code;		\
		} I##_Instr


#ifndef WORDS_BIGENDIAN					
	#define INSTRUCTION_1ARG(I,A1,S1)			\
		INSTRUCTION_(I,	A1:S1)

	#define INSTRUCTION_2ARGS(I,A1,S1,A2,S2)			\
		INSTRUCTION_(I,	A2:S2; A1:S1)

	#define INSTRUCTION_3ARGS(I,A1,S1,A2,S2,A3,S3)			\
		INSTRUCTION_(I,	A3:S3; A2:S2; A1:S1)

	#define INSTRUCTION_4ARGS(I,A1,S1,A2,S2,A3,S3,A4,S4)		\
		INSTRUCTION_(I,	A4:S4; A3:S3; A2:S2; A1:S1)

	#define INSTRUCTION_5ARGS(I,A1,S1,A2,S2,A3,S3,A4,S4,A5,S5)	\
		INSTRUCTION_(I,	A5:S5; A4:S4; A3:S3; A2:S2; A1:S1)

	#define INSTRUCTION_6ARGS(I,A1,S1,A2,S2,A3,S3,A4,S4,A5,S5,A6,S6) \
		INSTRUCTION_(I, A6:S6; A5:S5; A4:S4; A3:S3; A2:S2; A1:S1)

	#define INSTRUCTION_7ARGS(I,A1,S1,A2,S2,A3,S3,A4,S4,A5,S5,A6,S6,A7,S7) \
		INSTRUCTION_(I,	A7:S7; A6:S6; A5:S5; A4:S4; A3:S3; A2:S2; A1:S1)

#else							
	#define INSTRUCTION_1ARG(I,A1,S1)			\
		INSTRUCTION_(I,	unsigned pad:(32-S1);		\
				A1:S1)

	#define INSTRUCTION_2ARGS(I,A1,S1,A2,S2)			\
		INSTRUCTION_(I,	unsigned pad:(32-S1-S2);		\
				A1:S1; A2:S2)

	#define INSTRUCTION_3ARGS(I,A1,S1,A2,S2,A3,S3)			\
		INSTRUCTION_(I,	unsigned pad:(32-S1-S2-S3); 		\
				A1:S1; A2:S2; A3:S3)

	#define INSTRUCTION_4ARGS(I,A1,S1,A2,S2,A3,S3,A4,S4)		\
		INSTRUCTION_(I,	unsigned pad:(32-S1-S2-S3-S4); 		\
				A1:S1; A2:S2; A3:S3; A4:S4)

	#define INSTRUCTION_5ARGS(I,A1,S1,A2,S2,A3,S3,A4,S4,A5,S5);	\
		INSTRUCTION_(I,	unsigned pad:(32-S1-S2-S3-S4-S5); 	\
				A1:S1; A2:S2; A3:S3; A4:S4; A5:S5)

	#define INSTRUCTION_6ARGS(I,A1,S1,A2,S2,A3,S3,A4,S4,A5,S5,A6,S6)\
		INSTRUCTION_(I,	unsigned pad:(32-S1-S2-S3-S4-S5-S6); 	\
				A1:S1; A2:S2; A3:S3; A4:S4; A5:S5; A6:S6)

	#define INSTRUCTION_7ARGS(I,A1,S1,A2,S2,A3,S3,A4,S4,A5,S5,A6,S6,A7,S7)	\
		INSTRUCTION_(I,	unsigned pad:(32-S1-S2-S3-S4-S5-S6-S7); 	\
				A1:S1; A2:S2; A3:S3; A4:S4; A5:S5; A6:S6; A7:S7)
#endif	


#include "memory.h"
#include "addressing.h"
//#include "monitor/monitor.h"
	
//#include "i_5206/i_5206.h"
//#include "i_5206e/i_5206e.h"
//#include "i_5307/i_5307.h"
//#include "peripherals/peripherals.h"		

/* board.c -- definitions of various eval board layouts */
struct _board_data {
	char *cpu_id;
	unsigned int clock_speed;
	unsigned int cycle_count;
	unsigned int total_cycle_count;
	char use_timer_hack;
	char trace_run;
	enum _coldfire_cpu_id cpu;
};

void board_init(void);
void board_reset(void);
void board_fini(void);
void board_setup(char *file);
struct _board_data *board_get_data(void);

/* cycle.c */
void cycle(unsigned int number);
int cycle_EA(short reg, short mode);

/* exception.c -- exception generators */
int exception_do_raw_exception(short vector);
int exception_do_exception(short vector);
void exception_restore_from_stack_frame(void);
void exception_push_stack_frame(short vector);
void exception_post(unsigned int interrupt_level, 
		unsigned int (*func)(unsigned int interrupt_level) );
void exception_withdraw(unsigned int interrupt_level);
void exception_check_and_handle(void);

/* handlers.c -- misc functions */
void SR_Set(short Instr, int Source, int Destination, int Result);

/* i.c -- instructions */
void Instruction_Init(void);
void instruction_register(unsigned short code, unsigned short mask, 
		void (*execute)(void),
		int (*disassemble)(char *, char *, char *));
void Instruction_DeInit(void);
struct _Instruction *Instruction_FindInstruction(unsigned short Instr);
void instruction_register_instructions(void);

/* misc.c -- Misc functions */
int arg_split(char **argv, char *buffer, int max_args);
int arg_split_chars(char **argv, char *buffer, int max_args, char *split);

/* network.c -- Network functions */
int network_setup_on_port(int *fd, unsigned short port);
int network_check_accept(int *fd);

/* run.c -- Running the core */
extern char Run_Exit;
void Run(void);

/* sim.c -- System Integration Module */
struct _sim_register {
	char *name;
	int offset;
	char width;
	char read;
	char write;
	int resetvalue;
	char *description;
};

struct _sim {
	/* These are for peripherals to talk to the sim */
	void (*interrupt_assert)(short number, short vector);
	void (*interrupt_withdraw)(short number);
	/* These are for the monitor to query SIM registers */
	struct _sim_register *(*register_lookup_by_offset)(int offset);
	struct _sim_register *(*register_lookup_by_name)(char *name);
};
void sim_register(struct _sim *sim_data);
extern struct _sim *sim;

/*
#define TRACE(x,y,z)
#define TRACE(x,y) 
#define TRACE(x)
*/

/* INSTRUCTION TIMING is firewalled inside profile.h */
//#include "profile.h"
/* MEMORY_STATS is firewalled inside stats.h */
//#include "stats.h"
#endif
