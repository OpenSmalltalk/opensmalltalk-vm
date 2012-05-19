XCFLAGS=-m32
XCPPFLAGS=	-m32 -DUSE_BOCHS_CONFIG_H=1 \
			-I$(topdir)/processors/IA32/linuxbochs \
			-I$(topdir)/processors/IA32/bochs \
			-I$(topdir)/processors/IA32/bochs/instrument/stubs

XLDFLAGS=	-L$(topdir)/processors/IA32/linuxbochs/cpu \
			-L$(topdir)/processors/IA32/linuxbochs/fpu \
			-L$(topdir)/processors/IA32/linuxbochs/disasm \
			-lcpu -lfpu -ldisasm
