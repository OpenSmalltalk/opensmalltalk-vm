#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <time.h>

#define COG 1
#define FOR_COG_PLUGIN 1

#include <config.h>
#include <sim-main.h>

static char buf[10];

char *
lower(char *s)
{
	int i;
	for (i = 0; i < strlen(s); i++)
		buf[i] = tolower(s[i]);
	buf[i] = 0;
	return buf;
}

#if FOR64BITS
# define CLASS "!GdbARMv8Alien64"
#else
# define CLASS "!GdbARMv8Alien"
#endif

int
main()
{
//#define offsetof(type,field) (long)(&(((type *)0)->field))
#define stoffsetof(type,field) (offsetof(type,field)+1)
#define print(f,s) \
printf(CLASS " methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s\r\t^self unsignedLongLongAt: %ld! !\r", m,d,y,h,i, #s, \
	stoffsetof(struct _sim_cpu,f));\
printf(CLASS " methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s: anUnsignedInteger\r\t^self unsignedLongLongAt: %ld put: anUnsignedInteger! !\r", m,d,y,h,i, #s, \
	stoffsetof(struct _sim_cpu,f))

#define print32(f,s) \
printf(CLASS " methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s\r\t^self unsignedLongAt: %ld! !\r", m,d,y,h,i, #s, \
	stoffsetof(struct _sim_cpu,f));\
printf(CLASS " methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s: anUnsignedInteger\r\t^self unsignedLongAt: %ld put: anUnsignedInteger! !\r", m,d,y,h,i, #s, \
	stoffsetof(struct _sim_cpu,f))

	time_t nowsecs = time(0);
	struct tm now = *localtime(&nowsecs);
	int m = now.tm_mon + 1; /* strange but true */
	int d = now.tm_mday;
	int y = now.tm_year + 1900;
	int h = now.tm_hour;
	int i = now.tm_min;

	printf("\"Hello world!!\"!\r");
	printf(CLASS " class methodsFor: 'instance creation' stamp: 'eem %d/%d/%d %d:%02d'!\r"
	"dataSize\r\t^%ld! !\r", m,d,y,h,i, sizeof(struct _sim_cpu));

	print(CPSR,rawCPSR);
	print(FPSR,fpCPSR);
	print(FPCR,fpCPCR);
	print(nextpc,nextpc);
	print32(instr,instr);

	return 0;
}
