#include <stdio.h>
#include "target_reg.h"
#include "host_reg.h"

int main(){
	char * filename = "movl_oplet.c";
	FILE * fd = fopen(filename, "w+");
	int i = 0, j = 0;
	for(; i < sizeof(host_regs)/sizeof(reg_t);i++){
		j = 0;
		for(; j < sizeof(host_regs)/sizeof(reg_t);j++){
			fprintf(fd, "uint8_t * get_op_movl_%s_%s (int * len)\n", host_regs[i].ir_regname, host_regs[j].ir_regname);
			fprintf(fd, "{\n");
			fprintf(fd, "\tuint8_t * ret;\n");
			fprintf(fd, "\tOP_BEGIN (\"get_op_movl_%s_%s\");\n", host_regs[i].ir_regname, host_regs[j].ir_regname);
			fprintf(fd, "\t%s = %s;\n", host_regs[j].ir_regname, target_regs[i].regvalue);
			fprintf(fd, "\tOP_END (\"get_op_movl_%s_%s\");\n", target_regs[i].regname, host_regs[j].ir_regname);
			fprintf(fd, "\t*len = end - begin;\n");
			fprintf(fd, "\tret = (uint8_t *)begin;\n");
			fprintf(fd, "\treturn (ret);\n");
			fprintf(fd, "}\n");
		}
	}
	fclose(fd);
}
