/*
 * "quick" hack backtrace specific to x86 and win32 compiled with mingw or MSVC.
 * Extracts symbols and addresses for the main .exe from a .map file.
 * Extracts symbols and addresses for loaded dlls from the dlls themselves.
 *
 * Exports two functions, backtrace which answers an array of return pcs on the
 * call stack of the caller, and symbolic_backtrace which answers an array of
 * function name, module name, offset tuples for the supplied pcs.  These are
 * modelled after the BSD backtrace & backtrace_symbols library functions.
 *
 * Why are we not using StackWalk64 you ask?  StackWalk64 does not work with
 * mingw binaries.  See e.g. the v8 (a.k.a. chromium) source code.
 *
 * Eliot Miranda, 7 january 2010.
 */

#include <windows.h>
#include <stdio.h>
#include <string.h>

//#undef NDEBUG  if you want asserts enabled in the production build
//#define DBGPRINT if you want debug printing turned on

#include "sq.h"
#include "sqAssert.h"
#include "sqWin32Backtrace.h"
#include "sqWin32.h"
#if COGVM
# include "cogmethod.h"
# if NewspeakVM
#	include "nssendcache.h"
# endif
# include "cogit.h"
#endif

#ifdef _MSC_VER
#include <intrin.h>
#endif

typedef struct frame {
	struct frame *savedfp;
	void *retpc;
} Frame;

/* This may be in winnt.h. We know it is not in MinGW 0.3 but is in MinGW v3.17.
 * In between we cannot say.
 */
#if defined(__MINGW32_MAJOR_VERSION) && __MINGW32_MAJOR_VERSION < 2
/* see http://en.wikipedia.org/wiki/Win32_Thread_Information_Block
 * & e.g. http://www.nirsoft.net/kernel_struct/vista/NT_TIB.html
 */
typedef struct _NT_TIB
{
     void *ExceptionList;
     Frame *StackBase;
     Frame *StackLimit;
} ThreadInformationBlock, NT_TIB;
#endif

#define ulong usqIntptr_t /* enough for holding a pointer - unsigned long does not fit in LLP64 */

int
backtrace(void **retpcs, int nrpcs)
{
	void **__fp;

# if defined(_M_IX86) || defined(_M_I386) || defined(_X86_) || defined(i386) || defined(__i386__)
  #if defined(_MSC_VER)
	__asm {
		mov EAX, EBP
		mov [__fp], EAX
	}
  #elif defined(__GNUC__)
	asm volatile ("movl %%ebp, %0" : "=r"(__fp) : );
  #else
  # error "don't know how to derive ebp"
  #endif
#elif defined(__amd64__) || defined(__amd64) || defined(x86_64) || defined(__x86_64__) || defined(__x86_64) || defined(x64) || defined(_M_AMD64) || defined(_M_X64) || defined(_M_IA64)
  #if defined(_MSC_VER)
	/* __asm {
		mov RAX, RBP
		mov [__fp], RAX
	}*/
	__fp = (void **) _AddressOfReturnAddress();
  #elif defined(__GNUC__)
	asm volatile ("movq %%rbp, %0" : "=r"(__fp) : );
  #else
  # error "don't know how to derive ebp"
  #endif
#else
#error "unknown architecture, cannot pick frame pointer"
#endif

	return backtrace_from_fp(*__fp, retpcs, nrpcs);
}

int
backtrace_from_fp(void *startfp, void **retpcs, int nrpcs)
{
	Frame *fp; 
	NT_TIB *tib;
	int i = 0;

# if defined(_M_IX86) || defined(_M_I386) || defined(_X86_) || defined(i386) || defined(__i386__)
  #if defined(_MSC_VER)
	__asm {
		mov EAX, FS:[18h]
		mov [tib], EAX
	}
  #elif defined(__GNUC__)
	asm volatile ("movl %%fs:0x18, %0" : "=r" (tib) : );
  #else
  # error "don't know how to derive tib"
  #endif
#elif defined(__amd64__) || defined(__amd64) || defined(x86_64) || defined(__x86_64__) || defined(__x86_64) || defined(x64) || defined(_M_AMD64) || defined(_M_X64) || defined(_M_IA64)
  #if defined(_MSC_VER)
	/* __asm {
		mov RAX, GS:[30h]
		mov [tib], RAX
	} */
	tib = (NT_TIB *) __readgsqword(0x30);
  #elif defined(__GNUC__)
	asm volatile ("movq %%gs:0x30, %0" : "=r" (tib) : );
  #else
  # error "don't know how to derive tib"
  #endif
#else
#error "unknown architecture, cannot pick frame pointer"
#endif

	fp = startfp;

	while (i < nrpcs) {
		Frame *savedfp;

		if (!fp->retpc)
			break;
		retpcs[i++] = fp->retpc;
		savedfp = fp->savedfp;

#define validfp(fp,sp) (((usqInt)(fp) & (sizeof(fp)-1)) == 0 && (char *)(fp) > (char *)(sp))

		if (savedfp >= (Frame *)tib->StackBase
		 || !validfp(savedfp,startfp)
		 || savedfp <= fp)
			break;

		fp = savedfp;
	}
	return i;
}

/* N.B.  This is from psapi.h but we do not link against psapi.dll, so define
 * this ourselves.
 */
typedef struct _MODULEINFO {
	LPVOID lpBaseOfDll;
	DWORD  SizeOfImage;
	LPVOID EntryPoint;
} MODULEINFO, *LPMODULEINFO;
typedef struct _dll_exports {
	HMODULE module;
	char name[MAX_PATH];
	MODULEINFO info;
	void (*find_symbol)(struct _dll_exports *, void *, symbolic_pc *);
	int    n;
	char   initialized;
	ulong *functions;
	union { char **funcNames; ulong *funcNameOffsets; sqInt *methods; } u;
	int   *sorted_ordinals;
} dll_exports;

static dll_exports *dll_exports_for_pc(void *retpc);

/*
 * Answer pairs of function name, offset in symbolic_pc for the n retpcs.
 */
int
symbolic_backtrace(int n, void **retpcs, symbolic_pc *spc)
{
	int i;

	for (i = 0; i < n; i++) {
		dll_exports *exports = dll_exports_for_pc(retpcs[i]);

		if (exports)
			exports->find_symbol(exports, retpcs[i], spc + i);
		else
			spc[i].fnameOrSelector = spc[i].mname = 0, spc[i].offset = 0;
	}
	return n;
}

#if COGVM
	sqInt addressCouldBeObj(sqInt address);
	sqInt byteSizeOf(sqInt oop);
	void *firstFixedField(sqInt);
#endif

void
print_backtrace(FILE *f, int nframes, int maxframes,
				void **retpcs, symbolic_pc *symbolic_pcs)
{
	int i;

	fprintf(f, "\nStack backtrace:\n");
#if COGVM
	for (i = 0; i < nframes; ++i) {
		char *name; int namelen;
		if (addressCouldBeObj((sqInt)symbolic_pcs[i].fnameOrSelector)) {
			name = firstFixedField((sqInt)symbolic_pcs[i].fnameOrSelector);
			namelen = byteSizeOf((sqInt)symbolic_pcs[i].fnameOrSelector);
		}
		else {
			if (!(name = symbolic_pcs[i].fnameOrSelector))
				name = "???";
			namelen = strlen(name);
		}
		fprintf(f,
				"\t[%p] %.*s + 0x%" PRIxSQPTR " in %s\n",
				retpcs[i],
				namelen, name,
				symbolic_pcs[i].offset,
				symbolic_pcs[i].mname);
	}
#else
	for (i = 0; i < nframes; ++i)
		fprintf(f,
				"\t[%p] %s + 0x%" PRIxSQPTR " in %s\n",
				retpcs[i],
				symbolic_pcs[i].fnameOrSelector
					? symbolic_pcs[i].fnameOrSelector
					: "???",
				symbolic_pcs[i].offset,
				symbolic_pcs[i].mname);
#endif
	if (nframes == maxframes)
		fprintf(f, "\t...\n");
}

BOOL (WINAPI *EnumProcessModules)(HANDLE,HMODULE*,DWORD,LPDWORD) = NULL;
BOOL (WINAPI *GetModuleInformation)(HANDLE, HMODULE, LPMODULEINFO, DWORD)=NULL;

static DWORD moduleCount = 0;
static dll_exports *all_exports = 0;

static int
expcmp(const void *a, const void *b)
{ return (sqIntptr_t)((dll_exports *)a)->info.lpBaseOfDll - (sqIntptr_t)((dll_exports *)b)->info.lpBaseOfDll; }

static  void find_in_dll(dll_exports *exports, void *pc, symbolic_pc *spc);
static  void find_in_exe(dll_exports *exports, void *pc, symbolic_pc *spc);
#if COGVM
static  void find_in_cog(dll_exports *exports, void *pc, symbolic_pc *spc);
extern sqInt nilObject(void);
extern usqInt stackLimitAddress(void);
#endif

static void
get_modules(void)
{
	DWORD moduleCount2, i;
	HANDLE me = GetCurrentProcess();
	HANDLE hPsApi = LoadLibrary("psapi.dll");
	HMODULE *modules;

	EnumProcessModules = (void*)GetProcAddress(hPsApi, "EnumProcessModules");
	GetModuleInformation=(void*)GetProcAddress(hPsApi, "GetModuleInformation");

	if (!EnumProcessModules(me, (HMODULE *)&modules, sizeof(modules), &moduleCount)) {
		printLastError("EnumProcessModules 1");
		return;
	}
	modules = malloc(moduleCount);
#if COGVM
# define EXTRAMODULES 1
#else
# define EXTRAMODULES 0
#endif
	all_exports = calloc(moduleCount / sizeof(HMODULE) + EXTRAMODULES,
						 sizeof(dll_exports));
	if (!modules || !all_exports) {
		printLastError("get_modules out of memory");
		if (modules)
			free(modules);
		return;
	}

	if (!EnumProcessModules(me, modules, moduleCount, &moduleCount2)) {
		printLastError("EnumProcessModules 2");
		free(modules);
		return;
	}
	moduleCount /= sizeof(HMODULE);

	for (i = 0; i < moduleCount; i++) {
		all_exports[i].module = modules[i];
		if (!GetModuleFileName(modules[i], all_exports[i].name, MAX_PATH))
			printLastError("GetModuleFileName");
		if (!GetModuleInformation(me, modules[i], &all_exports[i].info, sizeof(MODULEINFO)))
			printLastError("GetModuleInformation");
		all_exports[i].find_symbol = find_in_dll;
	}
	free(modules);
	assert(GetModuleHandle(0) == all_exports[0].module);
	all_exports[0].find_symbol = find_in_exe;
#if COGVM
	/* Do not attempt to find addresses in Cog code until VM is initialized!! */
	if (*(char **)stackLimitAddress()) {
		strcpy(all_exports[moduleCount].name,"CogCode");
		all_exports[moduleCount].module = (void *)cogCodeBase();
		all_exports[moduleCount].info.lpBaseOfDll = (void *)cogCodeBase();
		/* startOfMemory() => nilObject() is temporary; FIX ME */
		all_exports[moduleCount].info.SizeOfImage = nilObject() - cogCodeBase();
		all_exports[moduleCount].find_symbol = find_in_cog;
		++moduleCount;
	}
#endif
	qsort(all_exports, moduleCount, sizeof(dll_exports), expcmp);
}

static dll_exports *
dll_exports_for_pc(void *retpc)
{
	unsigned int i;

	if (!all_exports)
		get_modules();

	if (!all_exports)
		return 0;

	for (i = 0; i < moduleCount; i++)
		if (all_exports[i].info.lpBaseOfDll <= retpc
		 && (void *)((ulong)all_exports[i].info.lpBaseOfDll
						  + all_exports[i].info.SizeOfImage) >= retpc)
			return all_exports + i;

	return 0;
}

static void compute_dll_symbols(dll_exports *exports);

static void
find_in_dll(dll_exports *exports, void *pcval, symbolic_pc *spc)
{
	int i;
	ulong pc = (ulong)pcval - (ulong)exports->info.lpBaseOfDll;

	spc->mname = strrchr(exports->name,'\\')
					? strrchr(exports->name,'\\') + 1
					: (char *)&exports->name;

	if (!exports->initialized)
		compute_dll_symbols(exports);

	for (i = 0; i < exports->n; i++) {
		ulong addr = exports->functions[exports->sorted_ordinals[i]];
		if (pc >= addr
		 && (  i + 1 >= exports->n
			|| pc < exports->functions[exports->sorted_ordinals[i + 1]])) {
			spc->fnameOrSelector = (char *)
					(exports->u.funcNameOffsets[exports->sorted_ordinals[i]]
					+ (ulong)exports->module);
			spc->offset = pc - addr;
			return;
		}
	}
	spc->fnameOrSelector = 0;
	spc->offset = pc;
}

static void compute_exe_symbols(dll_exports *exports);

static void
find_in_exe(dll_exports *exports, void *pc, symbolic_pc *spc)
{
	int i;

	spc->mname = strrchr(exports->name,'\\')
					? strrchr(exports->name,'\\') + 1
					: (char *)&exports->name;

	if (!exports->initialized)
		compute_exe_symbols(exports);

	for (i = 0; i < exports->n; i++) {
		ulong addr = exports->functions[i];
		if ((ulong)pc >= addr
		 && (  i + 1 >= exports->n
			|| (ulong)pc < exports->functions[i + 1])) {
			spc->fnameOrSelector = exports->u.funcNames[i];
			spc->offset = (ulong)pc - addr;
			return;
		}
	}
	spc->fnameOrSelector = 0;
	spc->offset = (ulong)pc - (ulong)exports->module;
}

static void
compute_exe_symbols(dll_exports *exports)
{
#if defined(_MSV_VER)
# error parse of MSVC .map file as yet unimplemented
/* Create the file using "cl .... /link /map"
 * Parse it by looking for lines beginning with " 0001:" where 0001 is the
 * segment number of the .text segment.  Representative lines look like

 0000:00000000       __except_list              00000000     <absolute>
 0001:00000000       _printLastError            00401000 f   main.obj
 0001:0000005c       _crashreport               0040105c f   main.obj
 0001:000000ed       _main                      004010ed f   main.obj

 * Be sure to look for global and static symbols.  The character "f" tells you
 * that this is a line for a function.
 */
#else  /* assume a BSD-style nm output as in
		* nm --numeric-sort --defined-only -f bsd $(VMEXE) >$(VMMAP)
		* where typical lines look like
00400000 A __image_base__
00401000 t .text
00401000 t __gnu_exception_handler@4
00401150 t ___mingw_CRTStartup
00401280 T _mainCRTStartup
004012a0 T _WinMainCRTStartup
004012c0 T _atexit
004012d0 T __onexit
004012e0 t .text
004012e0 T _btext
004012f0 t .text
004012f0 t _genoperandoperand
		* The characters t & T indicate this is a text symbol.  Note duplicates.
		*/

/* Read the entire file into memory.  We can use the string as the string table.
 * Once we've counted the lines we can parse and read the start addresses.
 */
	char filename[MAX_PATH];
	char *contents;
	FILE *f;
	int pos, len, nlines, n;

	strcpy(filename, exports->name);
	strcpy(strrchr(filename,'.')+1,"map");

	if (!(f = fopen(filename,"r"))) {
		printLastError("fopen");
		return;
	}
	fseek(f,0,SEEK_END);
	len = ftell(f);
	fseek(f,0,SEEK_SET);
	if (!(contents = malloc(len))) {
		printLastError("malloc");
		fclose(f);
		return;
	}
	if (fread(contents, sizeof(char), len, f) != len) {
		printLastError("fread");
		fclose(f);
		return;
	}
	fclose(f);

	pos = nlines = 0;
	while (pos < len) {
		if (contents[pos] == '\n') {
			nlines++;
			contents[pos] = 0;
		}
		pos++;
	}

	if (!(exports->functions	= calloc(nlines,sizeof(ulong)))
	 || !(exports->u.funcNames	= calloc(nlines,sizeof(char *)))) {
		printLastError("malloc");
		fclose(f);
		return;
	}
	pos = n = 0;
	while (pos < len) {
		ulong addr;
		char  type, *symname;

		/* Note: Scan format should better be SCNuSQPTR according to C99, if ever different from print format - but we did not define that macro */
		asserta(sscanf(contents + pos, "%" PRIxSQPTR " %c", &addr, &type) == 2);
		symname = strrchr(contents + pos, ' ') + 1;
		if ((type == 't' || type == 'T')
		 && strcmp(symname,".text")) {
			exports->functions[n] = addr;
			exports->u.funcNames[n] = symname;
			++n;
		}
		pos += strlen(contents + pos) + 1;
	}
	exports->n = n;
#endif
#if DBGPRINT
	for (n = 0; n < exports->n; n++)
		printf("exe [%p] %s\n",
				exports->functions[exports->sorted_ordinals[n]],
				exports->u.funcNames[exports->sorted_ordinals[n]]);
#endif
	exports->initialized = 1;
}

/* See e.g. PEDump
	http://msdn.microsoft.com/en-us/library/ms809762.aspx
	http://msdn.microsoft.com/en-us/library/bb985994.aspx
 */

static ulong *funcs_for_ordcmp;
static int
ordcmp(const void *a, const void *b)
{ return funcs_for_ordcmp[*(int *)a] - funcs_for_ordcmp[*(int *)b]; }

static void
compute_dll_symbols(dll_exports *exports)
{
	char *dllbase = (char *)exports->module;
    PIMAGE_EXPORT_DIRECTORY pExportDir;
    unsigned int i, j, n;
    PWORD ordinals;
    ulong *functions;
    ulong exportsStartRVA, exportsEndRVA;

    PIMAGE_NT_HEADERS dllhdr;

    dllhdr = (PIMAGE_NT_HEADERS)(dllbase
							  + ((PIMAGE_DOS_HEADER)exports->module)->e_lfanew);

	if (IsBadReadPtr(dllhdr, sizeof(dllhdr->Signature))
	 || dllhdr->Signature != IMAGE_NT_SIGNATURE) {
		fprintf(stderr,"Not a Portable Executable (PE) EXE\n");
		return;
	}

    exportsStartRVA = dllhdr->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;

    exportsEndRVA = exportsStartRVA + dllhdr->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].Size;

    pExportDir = (PIMAGE_EXPORT_DIRECTORY) (dllbase + exportsStartRVA);

#if 0
	time_t timeStamp = pExportDir->TimeDateStamp;
    printf("  TimeDateStamp:   %08X -> %s",
    			pExportDir->TimeDateStamp, ctime(&timeStamp) );
    printf("  Version:         %u.%02u\n", pExportDir->MajorVersion,
            pExportDir->MinorVersion);
    printf("  Ordinal base:    %08X\n", pExportDir->Base);
    printf("  # of functions:  %08X\n", pExportDir->NumberOfFunctions);
    printf("  # of Names:      %08X\n", pExportDir->NumberOfNames);
#endif

    ordinals =	(PWORD)	(dllbase + (DWORD)pExportDir->AddressOfNameOrdinals);
    functions =	(PDWORD)(dllbase + (DWORD)pExportDir->AddressOfFunctions);

    if (!(exports->sorted_ordinals = calloc(pExportDir->NumberOfNames, sizeof(int)))) {
		printLastError("compute_dll_symbols calloc");
		return;
	}
	exports->functions = functions;
	exports->u.funcNameOffsets = (ulong*)(dllbase + (DWORD)pExportDir->AddressOfNames);

    for (i = n = 0; i < pExportDir->NumberOfFunctions; i++)
        if (functions[i]) // Skip over gaps in exported function ordinals
			// Only record if the function has a name.
			for (j=0; j < pExportDir->NumberOfNames; j++)
				if (ordinals[j] == i) {
					exports->sorted_ordinals[n++] = i;
					break;
				}

	exports->n = n;
	exports->initialized = 1;
	funcs_for_ordcmp = exports->functions;
	qsort(exports->sorted_ordinals, n, sizeof(int), ordcmp);

#if DBGPRINT // this to dump the symbols once sorted for checking
	for (i = 0; i < n; i++)
		printf("%3d %lx %s\n",
				exports->sorted_ordinals[i],
				exports->functions[exports->sorted_ordinals[i]]
				+ (ulong)exports->module,
				exports->u.funcNameOffsets[exports->sorted_ordinals[i]]
				+ (ulong)exports->module);
#endif
}

#if COGVM
static void
find_in_cog(dll_exports *exports, void *pc, symbolic_pc *spc)
{
	CogMethod *cogMethod;

	spc->mname = (char *)&exports->name;

	if ((spc->fnameOrSelector = codeEntryNameFor(pc)))
		spc->offset = (ulong)pc - (ulong)codeEntryFor(pc);
	else if ((cogMethod = methodFor(pc))) {
		spc->fnameOrSelector = cogMethod->selector == nilObject()
								? "Cog method with nil selector"
								: (char *)(cogMethod->selector);
		spc->offset = (ulong)pc - (ulong)cogMethod;
	}
	else
		spc->offset = (ulong)pc - (ulong)exports->info.lpBaseOfDll;
}
#endif

void
printModuleInfo(FILE *f)
{
	unsigned int i;

	if (!all_exports)
		get_modules();

	fprintf(f, "\nModule information:\n");
	for (i = 0; i < moduleCount; i++) {
		fprintf(f,
				"\t%0*" PRIxSQPTR " - %0*" PRIxSQPTR ": %s\n", 
				(int) sizeof(all_exports[i].info.lpBaseOfDll)*2,
				(ulong)all_exports[i].info.lpBaseOfDll,
				(int) sizeof(all_exports[i].info.lpBaseOfDll)*2,
				((ulong)all_exports[i].info.lpBaseOfDll) + all_exports[i].info.SizeOfImage,
				all_exports[i].name);
		fflush(f);
	}
}
