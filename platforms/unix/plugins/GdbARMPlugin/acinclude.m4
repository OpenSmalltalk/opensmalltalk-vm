# To build the GdbARMPlugin one must build libsim.a from gdb
if test -f ../../../processors/ARM/gdb-7.6/sim/arm/libsim.a; then
	echo "libsim.a has been built\; building GdbARMPlugin"
else
	echo "/processors/ARM/gdb-7.6/sim/arm/libsim.a has not been built\; not building GdbARMPlugin"
  AC_PLUGIN_DISABLE
fi
