#include "pharoClient.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

int CALLBACK
WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    return vm_main(__argc, (const char **)__argv, (const char**)environ);
}
