/****************************************************************************
*   PROJECT: Unix platform support for Cog VM
*   FILE:    include_ucontext.h
*   CONTENT: Unix include machinery for accessing the ucontext_t * parameter
*			 in a signal handler, which gives access to register state.
*			 statistical profiling of the VM
*
*   AUTHOR:  Eliot Miranda
*   ADDRESS: 
*   EMAIL:   eliot.miranda@gmail.com
*
*****************************************************************************/
 
#if __linux__
# if !defined(__USE_GNU)
#	define UNDEF__USE_GNU 1
#	define __USE_GNU /* to get register defines in sys/ucontext.h */
# endif
#endif
#ifdef __OpenBSD__
# include <sys/signal.h>
#elif __sun
/* Single UNIX Specification (SUS), Version 2 specifies <ucontext.h> */
# include <ucontext.h>
#else
# include <sys/ucontext.h>
#endif
#if __linux__ && UNDEF__USE_GNU
# undef __USE_GNU
#endif

#if __APPLE__ && __MACH__ && __DARWIN_UNIX03
# if __i386__
#	define _PC_IN_UCONTEXT uc_mcontext->__ss.__eip
#	define _FP_IN_UCONTEXT uc_mcontext->__ss.__ebp
#	define _SP_IN_UCONTEXT uc_mcontext->__ss.__esp
# elif __x86_64__
#	define _PC_IN_UCONTEXT uc_mcontext->__ss.__rip
#	define _FP_IN_UCONTEXT uc_mcontext->__ss.__rbp
#	define _SP_IN_UCONTEXT uc_mcontext->__ss.__rsp
# elif __arm64__
#	define _PC_IN_UCONTEXT uc_mcontext->__ss.__pc
#	define _FP_IN_UCONTEXT uc_mcontext->__ss.__fp
#	define _SP_IN_UCONTEXT uc_mcontext->__ss.__sp
#	define _JIT_SP_IN_UCONTEXT uc_mcontext->__ss.__x[16]
# endif
#elif __APPLE__ && __MACH__
# if __ppc__
#	define _PC_IN_UCONTEXT uc_mcontext->ss.srr0
# elif __i386__
#	define _PC_IN_UCONTEXT uc_mcontext->ss.eip
#	define _FP_IN_UCONTEXT uc_mcontext->ss.ebp
#	define _SP_IN_UCONTEXT uc_mcontext->ss.esp
# elif __x86_64__
#	define _PC_IN_UCONTEXT uc_mcontext->ss.rip
#	define _FP_IN_UCONTEXT uc_mcontext->ss.rbp
#	define _SP_IN_UCONTEXT uc_mcontext->ss.rsp
# elif __arm64__
#	define _PC_IN_UCONTEXT uc_mcontext->ss.pc
#	define _FP_IN_UCONTEXT uc_mcontext->ss.fp
#	define _SP_IN_UCONTEXT uc_mcontext->ss.sp
#	define _JIT_SP_IN_UCONTEXT uc_mcontext->ss.x[16]
# endif
#elif __sun__ && __amd64
# define _PC_IN_UCONTEXT uc_mcontext.gregs[REG_RIP]
# define _FP_IN_UCONTEXT uc_mcontext.gregs[REG_FP]
# define _SP_IN_UCONTEXT uc_mcontext.gregs[REG_SP]
#elif __sun__ && __i386__
# define _PC_IN_UCONTEXT uc_mcontext.gregs[EIP]
# define _FP_IN_UCONTEXT uc_mcontext.gregs[REG_FP]
# define _SP_IN_UCONTEXT uc_mcontext.gregs[REG_SP]
#elif __linux__ && __i386__
# define _PC_IN_UCONTEXT uc_mcontext.gregs[REG_EIP]
# define _FP_IN_UCONTEXT uc_mcontext.gregs[REG_EBP]
# define _SP_IN_UCONTEXT uc_mcontext.gregs[REG_ESP]
#elif __linux__ && __x86_64__
# define _PC_IN_UCONTEXT uc_mcontext.gregs[REG_RIP]
# define _FP_IN_UCONTEXT uc_mcontext.gregs[REG_RBP]
# define _SP_IN_UCONTEXT uc_mcontext.gregs[REG_RSP]
#elif __linux__ && __aarch64__
# define _PC_IN_UCONTEXT uc_mcontext.pc
# define _FP_IN_UCONTEXT uc_mcontext.sp
# define _SP_IN_UCONTEXT uc_mcontext.regs[29]
# define _JIT_SP_IN_UCONTEXT uc_mcontext.regs[16]
#elif __linux__ && (__arm64__ || __aarch64__ || ARM64)
# define _PC_IN_UCONTEXT uc_mcontext.pc
# define _FP_IN_UCONTEXT uc_mcontext.sp
# define _SP_IN_UCONTEXT uc_mcontext.regs[29]
# define _JIT_SP_IN_UCONTEXT uc_mcontext.regs[16]
#elif __linux__ && (__arm__ || __arm32__)
# define _PC_IN_UCONTEXT uc_mcontext.arm_pc
# define _FP_IN_UCONTEXT uc_mcontext.arm_fp
# define _SP_IN_UCONTEXT uc_mcontext.arm_sp
#elif __FreeBSD__ && __i386__
# define _PC_IN_UCONTEXT uc_mcontext.mc_eip
# define _FP_IN_UCONTEXT uc_mcontext.mc_ebp
# define _SP_IN_UCONTEXT uc_mcontext.mc_esp
#elif __FreeBSD__ && __amd64__
# define _PC_IN_UCONTEXT uc_mcontext.mc_rip
# define _FP_IN_UCONTEXT uc_mcontext.mc_rbp
# define _SP_IN_UCONTEXT uc_mcontext.mc_rsp
#elif __OpenBSD__ && __i386__
# define _PC_IN_UCONTEXT sc_eip
# define _FP_IN_UCONTEXT sc_ebp
# define _SP_IN_UCONTEXT sc_esp
#elif __OpenBSD__ && __amd64__
# define _PC_IN_UCONTEXT sc_rip
# define _FP_IN_UCONTEXT sc_rbp
# define _SP_IN_UCONTEXT sc_rsp
#endif
#if !defined(_PC_IN_UCONTEXT)
# error need to implement extracting pc from a ucontext_t on this system
#endif
#if !defined(_FP_IN_UCONTEXT)
# error need to implement extracting fp from a ucontext_t on this system
#endif
#if !defined(_SP_IN_UCONTEXT)
# error need to implement extracting sp from a ucontext_t on this system
#endif
