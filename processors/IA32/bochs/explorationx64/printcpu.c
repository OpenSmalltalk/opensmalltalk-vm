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
printf("!BochsX64Alien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s\r\t^self unsignedLongLongAt: %ld! !\r", m,d,y,h,i, lower(#r), \
	stoffsetof(BX_CPU_C,gen_reg[n].dword.erx));\
printf("!BochsX64Alien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s: anUnsignedInteger\r\t^self unsignedLongLongAt: %ld put: anUnsignedInteger! !\r", m,d,y,h,i, lower(#r), \
	stoffsetof(BX_CPU_C,gen_reg[n].dword.erx));\
printf("!BochsX64Alien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
	"%s\r\t^self unsignedByteAt: %ld! !\r", m,d,y,h,i, lower(#b), \
	stoffsetof(BX_CPU_C,gen_reg[n].dword.erx));\
printf("!BochsX64Alien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"\
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
	printf("!BochsX64Alien class methodsFor: 'instance creation' stamp: 'eem %d/%d/%d %d:%02d'!\r"
	"dataSize\r\t^%ld! !\r", m,d,y,h,i, sizeof(BX_CPU_C));

	printf("!BochsX64Alien methodsFor: 'accessing' stamp: 'eem %d/%d/%d %d:%02d'!\r"
			"rflags\r\t^self unsignedLongLongAt: %ld! !\r", m,d,y,h,i,
			stoffsetof(BX_CPU_C,eflags));

	print(RAX,BX_64BIT_REG_RAX,al);
	print(RBX,BX_64BIT_REG_RBX,bl);
	print(RCX,BX_64BIT_REG_RCX,cl);
	print(RDX,BX_64BIT_REG_RDX,dl);
	print(RSP,BX_64BIT_REG_RSP,spl);
	print(RBP,BX_64BIT_REG_RBP,bpl);
	print(RSI,BX_64BIT_REG_RSI,sil);
	print(RDI,BX_64BIT_REG_RDI,dil);
	print(R8,BX_64BIT_REG_R8,r8l);
	print(R9,BX_64BIT_REG_R9,r9l);
	print(R10,BX_64BIT_REG_R10,r10l);
	print(R11,BX_64BIT_REG_R11,r11l);
	print(R12,BX_64BIT_REG_R12,r12l);
	print(R13,BX_64BIT_REG_R13,r13l);
	print(R14,BX_64BIT_REG_R14,r14l);
	print(R15,BX_64BIT_REG_R15,r15l);
	print(RIP,BX_64BIT_REG_RIP,ipl); /* the ipl: method should be discarded */

	return 0;
}
