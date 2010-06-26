#include <fcntl.h>
#include <stdio.h>
#include <reg_map.h>
#include <host_reg.h>
int main(){
	char * filename = "reg_defs.h";
	FILE * fd = fopen(filename, "w+");
	int i = 0;
	for(; i < sizeof(host_regs)/sizeof(reg_t) ;i++){
		fprintf(fd, "register uint32_t %s asm (\"%s\")\n", host_regs[i].ir_regname, host_regs[i].host_regname);
	}
	close(fd);
}

