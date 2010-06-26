/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

#ifndef MEMORY_H
#define MEMORY_H


/* Memory definitions */

struct _memory_core {
	unsigned int pc;
	unsigned int pc_instruction_begin;
	unsigned int sr;
	unsigned int mbar;
	unsigned int mbar_size;
	unsigned int mbar2;
	unsigned int mbar2_size;
	unsigned int rambar;
	unsigned int rambar1;
	unsigned int rombar;
	unsigned int vbr;
	unsigned int cacr;
	unsigned int d[8];
	unsigned int a[8];
	char (*mbar_write)(short size, int offset, unsigned int value);
	char (*mbar_read)(unsigned int * result, short size, int offset);
	char (*mbar2_write)(short size, int offset, unsigned int value);
	char (*mbar2_read)(unsigned int * result, short size, int offset);
};

/* Actually declared in memory.c */
extern struct _memory_core memory_core;

struct _SR {
#ifndef WORDS_BIGENDIAN
	unsigned C:1;
	unsigned V:1;
	unsigned Z:1;
	unsigned N:1;
	unsigned X:1;
	unsigned Unused:3;
	unsigned InterruptPriorityMask:3;
	unsigned Unused2:1;
	unsigned M:1;
	unsigned S:1;
	unsigned Unused3:1;
	unsigned T:1;
	unsigned pad:16;
#else
	unsigned pad:16;
	unsigned T:1;
	unsigned Unused3:1;
	unsigned S:1;
	unsigned M:1;
	unsigned Unused2:1;
	unsigned InterruptPriorityMask:3;
	unsigned Unused:3;
	unsigned X:1;
	unsigned N:1;
	unsigned Z:1;
	unsigned V:1;
	unsigned C:1;
#endif
};

extern struct _SR *SRBits; 

void memory_reset(void);
void Memory_Init(void);
void Memory_DeInit(void);

/* Memory seek */
char memory_seek(unsigned int offset);


/* Memory retrive */
#define Memory_RetrLongWord(V,Offset) 	Memory_Retr(V,32,Offset)
#define Memory_RetrWord(V,Offset) 	Memory_Retr(V,16,Offset)
#define Memory_RetrByte(V,Offset) 	Memory_Retr(V,8,Offset)
char Memory_Retr(unsigned int *Result, short Size, int Offset);

/* Memory Store */
#define Memory_StorLongWord(Offset,Value) 	Memory_Stor(32,Offset,Value)
#define Memory_StorWord(Offset,Value) 		Memory_Stor(16,Offset,Value)
#define Memory_StorByte(Offset,Value) 		Memory_Stor(8,Offset,Value)
char Memory_Stor(short Size, int Offset, unsigned int Value);

/* Memory retrive, and update the PC */
#define Memory_RetrByteFromPC(V)	Memory_RetrFromPC(V,8)
#define Memory_RetrWordFromPC(V) 	Memory_RetrFromPC(V,16)
#define Memory_RetrLongWordFromPC(V) 	Memory_RetrFromPC(V,32)
char Memory_RetrFromPC(unsigned int *Result, short Size);


void memory_update(void);


enum {
	SR_C = 0x0001,
	SR_V = 0x0002,
	SR_Z = 0x0004,
	SR_N = 0x0008,
	SR_X = 0x0010
};


/* Memory modules */
struct _memory_segment {
	char *name;
	unsigned int base;
	unsigned int *base_register;
	unsigned int mask;
	unsigned short interrupt_line;
	char *code;
	unsigned int code_len;
	void (*fini)(struct _memory_segment *s);
	char (*read)(struct _memory_segment *s, unsigned int *result, short size, unsigned int offset);
	char (*write)(struct _memory_segment *s, short size, unsigned int offset, unsigned int value);
	void (*reset)(struct _memory_segment *s);
	void (*update)(struct _memory_segment *s);
	void *data;
	
};

struct _memory_module {
	char *name;
	void (*setup)(struct _memory_segment *s);
};


void memory_module_register(char *name, 
		void (*setup)(struct _memory_segment *s));
//void memory_module_setup_segment(char *module_name, char *data);
void memory_module_setup_segment(char *module_name, int base_register, int base, int len);
struct _memory_segment *memory_find_segment_for(unsigned int offset);
void memory_core_set_reset_values(char *s);

void memory_dump_segments(void);
#endif
