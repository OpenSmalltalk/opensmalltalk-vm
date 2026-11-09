# To build the GdbARMPlugin one must build libsim.a from gdb
if test -f ../../gdb-18.1/sim/riscv/libsim.a; then
	echo "libsim.a has been built; building GdbRiscV64Plugin"
else
	echo "../../gdb-18.1/sim/riscv/libsim.a has not been built; not building GdbRiscV64Plugin"
  AC_PLUGIN_DISABLE
fi
