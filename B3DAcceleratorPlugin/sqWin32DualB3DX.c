#include "sqVirtualMachine.h"
#include "B3DAcceleratorPlugin.h"

extern struct VirtualMachine *interpreterProxy;

int glMode = 0; /* default to D3D */

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

