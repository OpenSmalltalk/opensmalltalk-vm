/* makeprims.c - a tiny program to regenerate the sqNamedPrims.h file
   since we cannot rely on reasonable shell/script support on all
   Windows variants.

   Invoked from make with the list of internal plugins.
*/
#include <stdio.h>

int main(int argc, char** argv) {
  FILE *fp;
  int i;
  char *fName;

  if(argc < 2) {
    printf("usage: makeprims filename FooPlugin BarPlugin ...\n");
    return -1;
  }
  fName = argv[1];
  fp = fopen(fName, "wt");
  if(!fp) {
    printf("makeprims: Failed to open %s\n", fName);
    return -1;
  }
  fprintf(fp, "/* This is an automatically generated table of all builtin modules in the VM */\n\n");
  fprintf(fp, "extern sqExport vm_exports[];\n");
  fprintf(fp, "extern sqExport os_exports[];\n");
  for(i=2; i<argc;i++) {
    fprintf(fp,"extern sqExport %s_exports[];\n", argv[i]);
  }

  fprintf(fp,"\nsqExport *pluginExports[] = {\n");
  fprintf(fp,"\tvm_exports,\n");
  fprintf(fp,"\tos_exports,\n");
  for(i=2; i<argc;i++) {
    fprintf(fp,"\t%s_exports,\n", argv[i]);
  }
  fprintf(fp,"\tNULL\n");
  fprintf(fp,"};\n");
  return 0;
}

