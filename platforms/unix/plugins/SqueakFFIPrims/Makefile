### This Makefile is NOT used to build Squeak.
### 
### See the file `00README' for instructions.
### 
### Last edited: 2003-01-30 00:02:00 by piumarta on emilia.inria.fr

CPU=	$(shell ./ffi-config -cpu)
ABI=	$(shell ./ffi-config -abi)
LIB=	$(shell ./ffi-config -lib)

INC=	-I../../../Cross/plugins/SqueakFFIPrims
DEF=	-DFFI_TEST

CFLAGS=	-g -Wall -Wno-unused -O2 $(DEF) $(INC)

OBJ=	ffi-test-main.o ffi-test.o $(CPU)-$(ABI).o $(CPU)-$(ABI)-asm.o

main : sq.h $(OBJ)
	gcc -g -o $@ $(OBJ) $(LIB)

libffi :
	$(MAKE) CPU=any ABI=libffi LIB=-lffi

sq.h :
	ln -s ffi-test-sq.h sq.h

%.o : Makefile

clean :
	/bin/rm -f *~ *.o main sq.h
