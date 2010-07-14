# Makefile.in for FFIPlugin on Unix
# 
# Author: ian.piumarta@inria.fr
# 
# Last edited: 16 Jun 2010 by eliot miranda

[make_cfg]
[make_plg]

TARGET= SqueakFFIPrims$a

OBJS= SqueakFFIPrims$o sqFFIPlugin$o sqManualSurface$o sqFFITestFuncs$o

XINCLUDES= [includes]

$(TARGET) : $(OBJS) Makefile
	$(LINK) $(TARGET) $(OBJS)
	$(RANLIB) $(TARGET)

[make_targets]

.force :
