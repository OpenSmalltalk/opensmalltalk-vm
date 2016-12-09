#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdlib.h>
#include "SqueakVirtualMachine.h"

int CALLBACK WinMain(
  HINSTANCE hInstance,
  HINSTANCE hPrevInstance,
  LPSTR     lpCmdLine,
  int       nCmdShow
)
{
    return squeak_main(__argc, __argv);
}
