# To build the BochsIA32Plugin one must build the Bochs support libraries
if test -f ../../bochsx86/cpu/libcpu.a \
	-a  -f ../../bochsx86/disasm/libdisasm.a \
	-a  -f ../../bochsx86/fpu/libfpu.a; then
	echo "bochs support libraries have been built; building BochsIA32Plugin"
else
	echo "../../bochsx86 libraries have not been built; not building BochsIA32Plugin"
  AC_PLUGIN_DISABLE
fi
