#include <langinfo.h>

int main(int argc, char **argv)
{
  char *cs= nl_langinfo(CODESET);
  return 0;
}
