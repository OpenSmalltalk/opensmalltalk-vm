/*
 * winARM64Thunk.c  —  Windows/ARM64 only.
 *
 * On aarch64 the ThreadedFFIPlugin's generated ARM64FFIPlugin.c calls the tiny
 * assembler thunk callAndReturnWithStructAddr(), which lives in the IA32ABI
 * plugin's arm64abicc.c. On x64 the corresponding X64Win64FFIPlugin.c inlines
 * its call sequence and needs no external thunk, so the win32 FFI Makefile does
 * not compile any abicc file into SqueakFFIPrims. That leaves the symbol
 * undefined when linking the aarch64 SqueakFFIPrims.dll.
 *
 * Pull the thunk into the plugin here so the DLL is self-contained. Defining
 * SQUEAK_BUILTIN_PLUGIN before the include keeps arm64abicc.c's interpreterProxy
 * declaration `extern` (the plugin already defines interpreterProxy), which
 * avoids a duplicate-symbol clash. On every non-aarch64 target this file
 * compiles to an empty object and changes nothing.
 */
#if defined(__aarch64__) || defined(__arm64__) || defined(_M_ARM64)
# define SQUEAK_BUILTIN_PLUGIN
# include "../IA32ABI/arm64abicc.c"
#endif
