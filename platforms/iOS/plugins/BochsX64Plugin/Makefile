LINK_WITH_CPP:=1
INCDIRS:=../bochsx64 \
         ../../processors/IA32/bochs \
         ../../processors/IA32/bochs/instrument/stubs
EXTRALIBS:=	-L../bochsx64/cpu -L../bochsx64/fpu -L../bochsx64/disasm \
			-lcpu -lfpu -ldisasm
CFLAGS:=-DUSE_BOCHS_CONFIG_H=1

include ../common/Makefile.plugin
