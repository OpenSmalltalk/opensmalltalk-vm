#include "sqVirtualMachine.h"
#include "B3DAcceleratorPlugin.h"

extern struct VirtualMachine *interpreterProxy;

int glMode = 1; /* default to OpenGL */

int b3dxInitialize(void) {
  int *ptr;
  ptr =  (int*)interpreterProxy->ioLoadFunctionFrom("fUseOpenGL","");
  if(ptr) {
    glMode = *ptr;
  }
  if(glMode)
    return glInitialize();
  else 
    return d3dInitialize();
}

