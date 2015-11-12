XCFLAGS=-m32
XCPPFLAGS=	-m32 -DUSE_BOCHS_CONFIG_H=1 \
			-I../../../bochsx86 \
			-I$(topdir)/processors/IA32/bochs \
			-I$(topdir)/processors/IA32/bochs/instrument/stubs

XLDFLAGS=	-L../../../bochsx86/cpu \
			-L../../../bochsx86/fpu \
			-L../../../bochsx86/disasm \
			-lcpu -lfpu -ldisasm \
			-lstdc++
