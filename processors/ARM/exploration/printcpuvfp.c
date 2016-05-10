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
	"%s\r\t^self unsignedLongLongAt: %ld! !\r", m,d,y,h,i, lower(#r), \
	stoffsetof(ARMul_State,VFP_Reg[n].dword));\
printf("!GdbARMAlien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s: anUnsignedInteger\r\t^self unsignedLongLongAt: %ld put: anUnsignedInteger! !\r", m,d,y,h,i, lower(#r), \
	stoffsetof(ARMul_State,VFP_Reg[n].dword))

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

	print(0,d0);
	print(1,d1);
	print(2,d2);
	print(3,d3);
	print(4,d4);
	print(5,d5);
	print(6,d6);
	print(7,d7);
	print(8,d8);
	print(9,d9);
	print(10,d10);
	print(11,d11);
	print(12,d12);
	print(13,d13);
	print(14,d14);
	print(15,d15);
	print(16,d16);
	print(17,d17);
	print(18,d18);
	print(19,d19);
	print(20,d20);
	print(21,d21);
	print(22,d22);
	print(23,d23);
	print(24,d24);
	print(25,d25);
	print(26,d26);
	print(27,d27);
	print(28,d28);
	print(29,d29);
	print(30,d30);
	print(31,d31);

	return 0;
}
