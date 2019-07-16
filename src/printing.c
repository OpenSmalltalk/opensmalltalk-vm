#include <pharo.h>

void error(char *errorMessage){
    fprintf(stderr, "%s\n", errorMessage);
    abort();
}
