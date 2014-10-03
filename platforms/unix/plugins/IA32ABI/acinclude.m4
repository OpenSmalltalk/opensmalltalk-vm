ia32abi_objs="IA32ABI.o AlienSUnitTestProcedures.o"

case $host_cpu in
ia32abi_objs="IA32ABI.o AlienSUnitTestProcedures.o ia32abicc.o"
;;
powerpc|ppc)
ia32abi_objs="IA32ABI.o AlienSUnitTestProcedures.o ppcia32abicc.o"
;;
esac

AC_SUBST(IA32ABI_OBJS, $ia32abi_objs)
