/* mkNamedPrims.c:
	Generates an sqNamedPrims.c from list of plugins passed in as command line.
*/

#include <stdio.h>

int main(int argc, char **argv) {
	int i;

	printf("/* Automatically generated on %s, %s */\n\n", __DATE__, __TIME__);

	printf("extern sqExport vm_exports[];\n");
	printf("extern sqExport os_exports[];\n");
	for(i = 1; i<argc;i++) {
		printf("extern sqExport %s_exports[];\n", argv[i]);
	}
	printf("\nsqExport *pluginExports[] = {\n");
	printf("\tvm_exports,\n");
	printf("\tos_exports,\n");
	for(i = 1; i<argc;i++) {
		printf("\t%s_exports,\n", argv[i]);
	}
	printf("\tNULL\n");
	printf("};\n");
	return 0;
}
