#include <features.h>
#if defined(__GNUC__) && defined(__GLIBC_PREREQ)
# if __GLIBC_PREREQ(2,3)
    /* squash __ctype_to{upper,lower}_loc and avoid including the header */
#   define _CTYPE_H 1
#   undef isalnum
#   undef isalpha
#   undef isascii
#   undef isblank
#   undef iscntrl
#   undef isdigit
#   undef isgraph
#   undef islower
#   undef isprint
#   undef ispunct
#   undef isspace
#   undef isupper
#   undef isxdigit

    extern int isalnum(int c);
    extern int isalpha(int c);
    extern int isascii(int c);
    extern int isblank(int c);
    extern int iscntrl(int c);
    extern int isdigit(int c);
    extern int isgraph(int c);
    extern int islower(int c);
    extern int isprint(int c);
    extern int ispunct(int c);
    extern int isspace(int c);
    extern int isupper(int c);
    extern int isxdigit(int c);
    /* squash realpath@GLIBC_2.3 */
#   include <stdlib.h>
/*  asm (".symver realpath, realpath@GLIBC_2.0"); */
# endif
#endif
