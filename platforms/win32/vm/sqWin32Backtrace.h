typedef struct { char *mname; void *fnameOrSelector; int offset; } symbolic_pc;

extern int backtrace(void *retpcs[], int nrpcs);
extern int backtrace_from_fp(void *fp,void *retpcs[], int nrpcs);
extern int symbolic_backtrace(int n, void *retpcs[], symbolic_pc *no);
extern void printModuleInfo(FILE *f);
