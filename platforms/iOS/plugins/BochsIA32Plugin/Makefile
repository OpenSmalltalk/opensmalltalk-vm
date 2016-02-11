LINK_WITH_CPP:=1
INCDIRS:=../bochsx86 \
         ../../processors/IA32/bochs \
		 ../../processors/IA32/bochs/instrument/stubs
EXTRALIBS:=	-L../bochsx86/cpu -L../bochsx86/fpu -L../bochsx86/disasm \
			-lcpu -lfpu -ldisasm
CFLAGS:=-DUSE_BOCHS_CONFIG_H=1

include ../common/Makefile.plugin
