ia32abi_objs="IA32ABI.o AlienSUnitTestProcedures.o"

case $host_cpu in
i386|i486|i586|i686)
ia32abi_objs="IA32ABI.o AlienSUnitTestProcedures.o ia32abicc.o"
;;
powerpc|ppc)
ia32abi_objs="IA32ABI.o AlienSUnitTestProcedures.o ppcia32abicc.o"
;;
x86_64|x64)
ia32abi_objs="IA32ABI.o AlienSUnitTestProcedures.o x64ia32abicc.o"
;;
esac

AC_SUBST(IA32ABI_OBJS, $ia32abi_objs)
