#ifndef __REG_MAP_H__
#define __REG_MAP_H__

struct _reg_s {
	char * ir_regname;
	char * host_regname;
};
typedef struct _reg_s reg_t;

struct _target_reg_s {
	char * regname;
	char * regvalue; 
};
typedef struct _target_reg_s target_reg_t;

#endif
