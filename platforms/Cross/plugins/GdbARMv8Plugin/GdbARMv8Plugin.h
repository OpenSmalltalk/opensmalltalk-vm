/* Include file for the ARMv8/ARM64 processor simulator plugin, GdbARMv8Plugin */
#define NumIntegerRegisterStateFields 34 /* the 32 registers plus pc & flags */
#define WordType unsigned long long

/* Must prepare setjmp/longjmp pair HERE so that linker finds references to */
/*_setjmp0 and longjmp functions. Only affects Windows builds. */
#include <setjmp.h>
#include "sqSetjmpShim.h"

#include <../ProcessorSimulatorPlugin.h>
