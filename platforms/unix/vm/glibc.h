#include <features.h>
#if defined(__GNUC__) && __GLIBC_PREREQ(2,3)
  /* squash __ctype_to{upper,lower}_loc */
# if defined(__USE_EXTERN_INLINES)
#   undef __USE_EXTERN_INLINES
#   include <ctype.h>
#   undef toupper
#   undef tolower
#   define __USE_EXTERN_INLINES 1
# endif
  /* squash realpath@GLIBC_2.3 */
# include <stdlib.h>
  asm (".symver realpath, realpath@GLIBC_2.0");
#endif
