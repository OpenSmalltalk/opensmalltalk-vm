/* Include file for the Bochs IA32/x86 processor simulator, BochsIA32Plugin */
#define NumIntegerRegisterStateFields 10 /* the 8 registers plus pc & flags */
#define WordType unsigned int

/* Must prepare setjmp/longjmp pair HERE so that linker finds references to */
/*_setjmp0 and longjmp functions. Only affects Windows builds. */
#include <setjmp.h>
#include "sqSetjmpShim.h"

#include <../ProcessorSimulatorPlugin.h>
