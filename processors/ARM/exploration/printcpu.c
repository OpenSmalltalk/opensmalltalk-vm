#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <time.h>

#define COG 1
#define FOR_COG_PLUGIN 1

#include <armdefs.h>

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

int
main()
{
#define offsetof(type,field) (long)(&(((type *)0)->field))
#define stoffsetof(type,field) (offsetof(type,field)+1)
#define print(n,r) \
printf("!GdbARMAlien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s\r\t^self unsignedLongAt: %ld! !\r", m,d,y,h,i, lower(#r), \
	stoffsetof(ARMul_State,Reg[n]));\
printf("!GdbARMAlien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s: anUnsignedInteger\r\t^self unsignedLongAt: %ld put: anUnsignedInteger! !\r", m,d,y,h,i, lower(#r), \
	stoffsetof(ARMul_State,Reg[n]))

	time_t nowsecs = time(0);
	struct tm now = *localtime(&nowsecs);
	int m = now.tm_mon + 1; /* strange but true */
	int d = now.tm_mday;
	int y = now.tm_year + 1900;
	int h = now.tm_hour;
	int i = now.tm_min;

	printf("\"Hello world!!\"!\r");
	printf("!GdbARMAlien class methodsFor: 'instance creation' stamp: 'eem %d/%d/%d %d:%02d'!\r"
	"dataSize\r\t^%ld! !\r", m,d,y,h,i, sizeof(ARMul_State));

	print(0,0);
	print(1,1);
	print(2,2);
	print(3,3);
	print(4,4);
	print(5,5);
	print(6,6);
	print(7,7);
	print(8,8);
	print(9,9);
	print(10,10);
	print(11,11);
	print(12,12);
	print(13,SP);
	print(14,LR);
	print(15,PC);

	return 0;
}
