# eem 2016/5/4 The existing code is in terms of oplder pre-carbon APIs and the
# Component Manager, which was deprecated in 10.8 and no longer seems available.
# To get the code to link we therefore have to use -undefined dynamic_lookup

EXTRALIBS:=-undefined dynamic_lookup -framework AudioToolbox -framework CoreAudio -framework QuickTime

include ../common/Makefile.plugin
