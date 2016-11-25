#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdlib.h>

extern int main(int argc, char *argv[], char *envp[]);

int CALLBACK WinMain(
  _In_ HINSTANCE hInstance,
  _In_ HINSTANCE hPrevInstance,
  _In_ LPSTR     lpCmdLine,
  _In_ int       nCmdShow
)
{
    return main(__argc, __argv, _environ);
}
