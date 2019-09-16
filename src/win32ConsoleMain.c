#include <pharoClient.h>
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

int main(int argc, const char **argv)
{
    return pharovm_main(argc, argv, (const char**)_environ);
}
