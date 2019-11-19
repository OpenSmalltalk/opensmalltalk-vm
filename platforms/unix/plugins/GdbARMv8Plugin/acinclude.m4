# To build the GdbARMPlugin one must build libsim.a from gdb
if test -f ../../gdbarm64/sim/aarch64/libsim.a; then
	echo "libsim.a has been built; building GdbARMPlugin"
else
	echo "../../gdbarm64/sim/aarch64/libsim.a has not been built; not building GdbARMPlugin"
  AC_PLUGIN_DISABLE
fi
