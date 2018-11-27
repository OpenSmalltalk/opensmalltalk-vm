typedef struct { char *mname; void *fnameOrSelector; sqIntptr_t offset; } symbolic_pc;

extern int  backtrace(void *retpcs[], int nrpcs);
extern int  backtrace_from_fp(void *fp,void *retpcs[], int nrpcs);
extern int  symbolic_backtrace(int n, void *retpcs[], symbolic_pc *spcs);
extern void print_backtrace(FILE *f, int nframes, int maxframes,
							void *retpcs[], symbolic_pc *symbolic_pcs);
extern void printModuleInfo(FILE *f);
