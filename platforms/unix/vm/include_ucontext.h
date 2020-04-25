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

#if __DARWIN_UNIX03 && __APPLE__ && __MACH__ && __i386__
# define _PC_IN_UCONTEXT uc_mcontext->__ss.__eip
#elif __APPLE__ && __MACH__ && __i386__
# define _PC_IN_UCONTEXT uc_mcontext->ss.eip
#elif __APPLE__ && __MACH__ && __ppc__
# define _PC_IN_UCONTEXT uc_mcontext->ss.srr0
#elif __DARWIN_UNIX03 && __APPLE__ && __MACH__ && __x86_64__
# define _PC_IN_UCONTEXT uc_mcontext->__ss.__rip
#elif __APPLE__ && __MACH__ && __x86_64__
# define _PC_IN_UCONTEXT uc_mcontext->ss.rip
#elif __sun && __amd64
# define _PC_IN_UCONTEXT uc_mcontext.gregs[REG_RIP]
#elif __sun && __i386__
# define _PC_IN_UCONTEXT uc_mcontext.gregs[EIP]
#elif __linux__ && __i386__
# define _PC_IN_UCONTEXT uc_mcontext.gregs[REG_EIP]
#elif __linux__ && __x86_64__
# define _PC_IN_UCONTEXT uc_mcontext.gregs[REG_RIP]
#elif __linux__ && __aarch64__
# define _PC_IN_UCONTEXT uc_mcontext.pc
#elif __linux__ && __arm64__
# define _PC_IN_UCONTEXT uc_mcontext.pc
#elif __linux__ && __arm__
# define _PC_IN_UCONTEXT uc_mcontext.arm_pc
#elif __FreeBSD__ && __i386__
# define _PC_IN_UCONTEXT uc_mcontext.mc_eip
#elif __FreeBSD__ && __amd64__
# define _PC_IN_UCONTEXT uc_mcontext.mc_rip
#elif __OpenBSD__ && __i386__
# define _PC_IN_UCONTEXT sc_eip
#elif __OpenBSD__ && __amd64__
# define _PC_IN_UCONTEXT sc_rip
#else
# error need to implement extracting pc from a ucontext_t on this system
#endif
