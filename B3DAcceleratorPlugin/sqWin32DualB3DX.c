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

#ifdef TEA
#warning "**************************************************************"
#warning "**************************************************************"
#warning "**************************************************************"
#warning
#warning "TEA: D3D disabled"
#warning
#warning "**************************************************************"
#warning "**************************************************************"
#warning "**************************************************************"
  glMode = 1;
#endif
  if(glMode)
    return glInitialize();
  else 
    return d3dInitialize();
}

