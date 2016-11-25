#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdlib.h>

extern int main(int argc, char *argv[], char *envp[]);

int CALLBACK WinMain(
  HINSTANCE hInstance,
  HINSTANCE hPrevInstance,
  LPSTR     lpCmdLine,
  int       nCmdShow
)
{
    return main(__argc, __argv, _environ);
}
