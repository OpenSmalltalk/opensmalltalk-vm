BOX:=../bochsx86
PREREQUISITES:=$(BOX)/cpu/libcpu.a $(BOX)/disasm/libdisasm.a $(BOX)/fpu/libfpu.a

LINK_WITH_CPP:=1
INCDIRS:=$(BOX) \
         ../../processors/IA32/bochs \
		 ../../processors/IA32/bochs/instrument/stubs
EXTRALIBS:=	-L$(BOX)/cpu -L$(BOX)/fpu -L$(BOX)/disasm -lcpu -lfpu -ldisasm
CFLAGS:=-DUSE_BOCHS_CONFIG_H=1

include ../common/Makefile.plugin
