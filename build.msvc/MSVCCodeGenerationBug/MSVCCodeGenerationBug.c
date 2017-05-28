/*
* try and reproduce a codegeneration BUG
*/


#include <stdio.h>

typedef long long		sqInt;
typedef unsigned long long		usqInt;
#  define atPointerArg(oop)			oop
# define longAtPointer(ptr)			(*(sqInt *)(ptr))
# define longAt(oop)				longAtPointer(atPointerArg(oop))

# define GIV(interpreterInstVar) interpreterInstVar
#define BaseHeaderSize 8
#define shiftForWord() 3

#define ClassArray 7
#define ClassArrayCompactIndex 51

# define _iss static
_iss sqInt specialObjectsOop;
_iss sqInt classTableFirstPage;

int main()
{
	sqInt spoo[10];
	sqInt ctfp[60];
	int i;
	for(i=0;i<10;i++) spoo[i]=i;
	for(i=0;i<60;i++) ctfp[i]=i;
	spoo[1+ClassArray] = 0x1234567890ABCDEFLL;
	ctfp[1+ClassArrayCompactIndex] = 0x1234567890ABCDEFLL;
	specialObjectsOop = (sqInt) spoo;
	classTableFirstPage = (sqInt) ctfp;
	
	if ((longAt((GIV(specialObjectsOop) + BaseHeaderSize) + ((((usqInt)(ClassArray) << (shiftForWord())))))) != ((
	/* begin fetchPointer:ofObject: */
	longAt((GIV(classTableFirstPage) + BaseHeaderSize) + ((((usqInt)(ClassArrayCompactIndex) << (shiftForWord())))))))) {
		printf("Should not get here\n");
		return 1;
	}
	return 0;
}