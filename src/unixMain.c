#include "pharoClient.h"

extern char **environ;

int main(int argc, const char *argv[])
{
    return pharovm_main(argc, argv, (const char**)environ);
}
