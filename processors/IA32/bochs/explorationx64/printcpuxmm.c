/*
% g++ -I.. -I../cpu -I../instrument/stubs -Wno-invalid-offsetof @ -o #
 */

#include <stddef.h>

#define COG 1

#include <bochs.h>

#define NEED_CPU_REG_SHORTCUTS

#include <cpu.h>

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
#define stoffsetof(type,field) (offsetof(type,field)+1)
#define print(r,n,lh) \
printf("!BochsX64Alien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s\r\t^self unsignedLongLongAt: %ld! !\r", m,d,y,h,i, lower(#r), \
	stoffsetof(BX_CPU_C,xmm[n]._u64[lh]));\
printf("!BochsX64Alien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s: anUnsignedInteger\r\t^self unsignedLongLongAt: %ld put: anUnsignedInteger! !\r", m,d,y,h,i, lower(#r), \
	stoffsetof(BX_CPU_C,xmm[n]._u64[lh]));\

	time_t nowsecs = time(0);
	struct tm now = *localtime(&nowsecs);
	int m = now.tm_mon + 1; /* strange but true */
	int d = now.tm_mday;
	int y = now.tm_year + 1900;
	int h = now.tm_hour;
	int i = now.tm_min;

	printf("\"Hello world!!\"!\r");

	print(XMM0Low,0,0);
	print(XMM1Low,1,0);
	print(XMM2Low,2,0);
	print(XMM3Low,3,0);
	print(XMM4Low,4,0);
	print(XMM5Low,5,0);
	print(XMM6Low,6,0);
	print(XMM7Low,7,0);
	print(XMM8Low,8,0);
	print(XMM9Low,9,0);
	print(XMM10Low,10,0);
	print(XMM11Low,11,0);
	print(XMM12Low,12,0);
	print(XMM13Low,13,0);
	print(XMM14Low,14,0);
	print(XMM15Low,15,0);

	print(XMM0High,0,1);
	print(XMM1High,1,1);
	print(XMM2High,2,1);
	print(XMM3High,3,1);
	print(XMM4High,4,1);
	print(XMM5High,5,1);
	print(XMM6High,6,1);
	print(XMM7High,7,1);
	print(XMM8High,8,1);
	print(XMM9High,9,1);
	print(XMM10High,10,1);
	print(XMM11High,11,1);
	print(XMM12High,12,1);
	print(XMM13High,13,1);
	print(XMM14High,14,1);
	print(XMM15High,15,1);

	return 0;
}
