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
munge(char *s)
{
	int i, d;
	for (i = 0, d = 0; i + d < strlen(s); i++)
		buf[i] = (s[i+d] == '_' && s[i+d+1])
					? toupper(s[++d+i])
					: tolower(s[i+d]);
	buf[i] = 0;
	return buf;
}

int
main()
{
#define stoffsetof(type,field) (offsetof(type,field)+1)
#define print(r,ra,len) \
printf("!BochsX64Alien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s\r\t^self unsigned" #len "At: %ld! !\r", m,d,y,h,i, munge(#r), \
	stoffsetof(BX_CPU_C,ra));\
printf("!BochsX64Alien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s: anUnsignedInteger\r\t^self unsigned" #len "At: %ld put: anUnsignedInteger! !\r", m,d,y,h,i, munge(#r), \
	stoffsetof(BX_CPU_C,ra));

	time_t nowsecs = time(0);
	struct tm now = *localtime(&nowsecs);
	int m = now.tm_mon + 1; /* strange but true */
	int d = now.tm_mday;
	int y = now.tm_year + 1900;
	int h = now.tm_hour;
	int i = now.tm_min;

	printf("\"Hello world!!\"!\r");

	print(cr0,cr0.val32,LongLong);
	print(cr1,cr1,LongLong);
	print(cr2,cr2,LongLong);
	print(cr3,cr3,LongLong);
	print(cr4,cr4.val32,LongLong);

	print(stop_reason,stop_reason,Byte);
	print(save_eip,save_eip,Long);
	print(save_esp,save_esp,Long);

	return 0;
}
