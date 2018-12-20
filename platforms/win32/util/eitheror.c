/* eitheror.c - treat each argument as a filename.  Test each for existence,
				answering the first one that exists or the last one if none.
   since there is no substitute in the Windows/MinGW32 pantheon.

   Invoked from make with a potential plugin-specific makefile or the generic.
*/
#include <io.h>
#include <stdio.h>

#ifdef _MSC_VER
# define F_OK 00
# define access _access
#else
# include <unistd.h>
#endif

int
main(int argc, char *argv[])
{
	int i;
	if (argc < 3) {
		fprintf(stderr,"usage: eitheror thingOne thingTwo [things...]\n");
		return 1;
	}
#if 0 /* for debugging the makefile. % in $(wildcard does not work... */
	fprintf(stderr,"%s\n",argv[0]);
	fprintf(stderr,"%s\n",argv[1]);
	fprintf(stderr,"%s\n",argv[2]);
#endif
	for (i = 1; i < (argc - 1); i++)
		if (!access(argv[i],F_OK)) { /* 0 == success */
			printf("%s\n", argv[i]);
			return 0;
		}
	printf("%s\n", argv[argc - 1]);
	return 0;
}

