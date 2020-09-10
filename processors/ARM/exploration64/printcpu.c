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
#define print(n,r) \
printf(CLASS " methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s\r\t^self unsignedLongLongAt: %ld! !\r", m,d,y,h,i, lower(#r), \
	stoffsetof(struct _sim_cpu,gr[n]));\
printf(CLASS " methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s: anUnsignedInteger\r\t^self unsignedLongLongAt: %ld put: anUnsignedInteger! !\r", m,d,y,h,i, lower(#r), \
	stoffsetof(struct _sim_cpu,gr[n]))

#define printpc(r) \
printf(CLASS " methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s\r\t^self unsignedLongLongAt: %ld! !\r", m,d,y,h,i, lower(#r), \
	stoffsetof(struct _sim_cpu,pc));\
printf(CLASS " methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s: anUnsignedInteger\r\t^self unsignedLongLongAt: %ld put: anUnsignedInteger! !\r", m,d,y,h,i, lower(#r), \
	stoffsetof(struct _sim_cpu,pc))

	time_t nowsecs = time(0);
	struct tm now = *localtime(&nowsecs);
	int m = now.tm_mon + 1; /* strange but true */
	int d = now.tm_mday;
	int y = now.tm_year + 1900;
	int h = now.tm_hour;
	int i = now.tm_min;

	printf("\"Hello world!!\"!\r");
	printf(CLASS " class methodsFor: 'instance creation' stamp: 'eem %d/%d/%d %d:%02d'!\r"
	"dataSize\r\t^%ld! !\r", m,d,y,h,i, sizeof(struct sim_state));

	print(0,r0);
	print(1,r1);
	print(2,r2);
	print(3,r3);
	print(4,r4);
	print(5,r5);
	print(6,r6);
	print(7,r7);
	print(8,r8);
	print(9,r9);
	print(10,r10);
	print(11,r11);
	print(12,r12);
	print(13,r13);
	print(14,r14);
	print(15,r15);
	print(16,r16);
	print(17,r17);
	print(18,r18);
	print(19,r19);
	print(20,r20);
	print(21,r21);
	print(22,r22);
	print(23,r23);
	print(24,r24);
	print(25,r25);
	print(26,r26);
	print(27,r27);
	print(28,r28);
	print(29,FP);
	print(30,LR);
	print(31,SP);
	printpc(pc);

	return 0;
}
