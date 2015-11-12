# To build the BochsX64Plugin one must build the Bochs support libraries
if test -f ../../bochsx64/cpu/libcpu.a \
	-a  -f ../../bochsx64/disasm/libdisasm.a \
	-a  -f ../../bochsx64/fpu/libfpu.a; then
	echo "bochs support libraries have been built; building BochsX64Plugin"
else
	echo "../../bochsx64 libraries have not been built; not building BochsX64Plugin"
  AC_PLUGIN_DISABLE
fi
