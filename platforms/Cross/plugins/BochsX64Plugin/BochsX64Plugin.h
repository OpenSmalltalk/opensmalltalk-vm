/* Include file for the Bochs x64/x86_64 processor simulator, BochsX64Plugin */
#define NumIntegerRegisterStateFields 18 /* the 16 registers plus pc & flags */
#define WordType unsigned long long

/* Must prepare setjmp/longjmp pair HERE so that linker finds references to */
/*_setjmp0 and longjmp functions. Only affects Windows builds. */
#include <setjmp.h>
#include "sqSetjmpShim.h"

#include <../ProcessorSimulatorPlugin.h>
