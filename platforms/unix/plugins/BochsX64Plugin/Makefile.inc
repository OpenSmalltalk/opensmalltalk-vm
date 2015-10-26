XCFLAGS=-m32
XCPPFLAGS=	-m32 -DUSE_BOCHS_CONFIG_H=1 \
			-I../../../bochsx64 \
			-I$(topdir)/processors/IA32/bochs \
			-I$(topdir)/processors/IA32/bochs/instrument/stubs

XLDFLAGS=	-L../../../bochsx64/cpu \
			-L../../../bochsx64/fpu \
			-L../../../bochsx64/disasm \
			-lcpu -lfpu -ldisasm \
			-lstdc++
