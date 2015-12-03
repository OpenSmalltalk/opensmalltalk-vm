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
#define print(r,n,b) \
printf("!BochsIA32Alien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s\r\t^self unsignedLongAt: %ld! !\r", m,d,y,h,i, lower(#r), \
	stoffsetof(BX_CPU_C,gen_reg[n].dword.erx));\
printf("!BochsIA32Alien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s: anUnsignedInteger\r\t^self unsignedLongAt: %ld put: anUnsignedInteger! !\r", m,d,y,h,i, lower(#r), \
	stoffsetof(BX_CPU_C,gen_reg[n].dword.erx));\
printf("!BochsIA32Alien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s\r\t^self unsignedByteAt: %ld! !\r", m,d,y,h,i, lower(#b), \
	stoffsetof(BX_CPU_C,gen_reg[n].dword.erx));\
printf("!BochsIA32Alien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s: anUnsignedInteger\r\t^self unsignedByteAt: %ld put: anUnsignedInteger! !\r", m,d,y,h,i, lower(#b), \
	stoffsetof(BX_CPU_C,gen_reg[n].dword.erx))

	time_t nowsecs = time(0);
	struct tm now = *localtime(&nowsecs);
	int m = now.tm_mon + 1; /* strange but true */
	int d = now.tm_mday;
	int y = now.tm_year + 1900;
	int h = now.tm_hour;
	int i = now.tm_min;

	printf("\"Hello world!!\"!\r");
	printf("!BochsIA32Alien class methodsFor: 'instance creation' stamp: 'eem %d/%d/%d %d:%02d'!\r"
	"dataSize\r\t^%ld! !\r", m,d,y,h,i, sizeof(BX_CPU_C));

	printf("!BochsIA32Alien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"
			"eflags\r\t^self unsignedLongAt: %ld! !\r", m,d,y,h,i,
			stoffsetof(BX_CPU_C,eflags));

	print(EAX,BX_32BIT_REG_EAX,al);
	print(EBX,BX_32BIT_REG_EBX,bl);
	print(ECX,BX_32BIT_REG_ECX,cl);
	print(EDX,BX_32BIT_REG_EDX,dl);
	print(ESP,BX_32BIT_REG_ESP,spl);
	print(EBP,BX_32BIT_REG_EBP,bpl);
	print(ESI,BX_32BIT_REG_ESI,sil);
	print(EDI,BX_32BIT_REG_EDI,dil);
	print(EIP,BX_32BIT_REG_EIP,ipl); /* the ipl: method should be discarded */

	return 0;
}
