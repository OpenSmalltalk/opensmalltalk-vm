/* sqLowcodeFFI-i386 -- i386 Platform specific definitions for the FFI.
 *
 * Author: Ronie Salgado (roniesalg@gmail.com)
 */


#ifndef _SQ_LOWCODE_FFI_I386_H_
#define _SQ_LOWCODE_FFI_I386_H_

typedef struct _sqLowcodeCalloutState
{
    union
    {
        struct
        {
            uint32_t eax, ecx, edx, ebx, esp, ebp, esi, edi;
        };

        uint32_t intRegisters[8];
    };

    double floatResult;
} sqLowcodeCalloutState;

#define lowcodeCalloutStatepointerRegister(calloutState, registerId) ((char*)(calloutState)->intRegisters[registerId])
#define lowcodeCalloutStatepointerRegistervalue(calloutState, registerId, value) ((calloutState)->intRegisters[registerId] = (uint32_t) (value))

#define lowcodeCalloutStateint32Register(calloutState, registerId) ((calloutState)->intRegisters[registerId])
#define lowcodeCalloutStateint32Registervalue(calloutState, registerId, value) ((calloutState)->intRegisters[registerId] = (value))

#define lowcodeCalloutStateint64Register(calloutState, registerId) 0
#define lowcodeCalloutStateint64Registervalue(calloutState, registerId, value) 0

#define lowcodeCalloutStatefloat32Register(calloutState, registerId) 0
#define lowcodeCalloutStatefloat32Registervalue(calloutState, registerId, value) 0

#define lowcodeCalloutStatefloat64Register(calloutState, registerId) 0
#define lowcodeCalloutStatefloat64Registervalue(calloutState, registerId, value) 0

#define lowcodeCalloutStateFetchResultInt32(calloutState) (calloutState)->eax
#define lowcodeCalloutStateFetchResultInt64(calloutState) 0
#define lowcodeCalloutStateFetchResultPointer(calloutState) ((char*)(calloutState)->eax)

#define lowcodeCalloutStateFetchResultFloat32(calloutState) (calloutState)->floatResult
#define lowcodeCalloutStateFetchResultFloat64(calloutState) (calloutState)->floatResult
#define lowcodeCalloutStateFetchResultStructure(calloutState) ((char*)(calloutState)->eax)

#if defined(_WIN32)
#define LOWCODE_FFI_PROGRAM_SECTION ".section .text"
#define LOWCODE_FFI_SYMBOL_PREFIX "_"
#elif defined(__APPLE__)
#define LOWCODE_FFI_PROGRAM_SECTION ".section __TEXT,__text"
#define LOWCODE_FFI_SYMBOL_PREFIX "_"
#else /* Linux */
#define LOWCODE_FFI_PROGRAM_SECTION ".section .text"
#define LOWCODE_FFI_SYMBOL_PREFIX
#endif

__asm__ ( "\n\
" LOWCODE_FFI_PROGRAM_SECTION " \n\
" LOWCODE_FFI_SYMBOL_PREFIX "lowcodeCalloutStatestackPointerstackSizecallFunction: \n\
    pusha                                                                    \n\
    movl %esp, %ebp                                                          \n\
    /* Align the stack */                                                    \n\
    andl $-16, %esp                                                          \n\
    /* Copy the stack arguments */                                           \n\
    movl 40(%ebp), %esi                                                      \n\
    movl 44(%ebp), %ecx                                                      \n\
    subl %ecx, %esp                                                          \n\
    shr $2, %ecx                                                             \n\
    movl %esp, %edi                                                          \n\
    cld                                                                      \n\
    rep movsd                                                                \n\
    /* Fetch the function pointer */                                         \n\
    movl 48(%ebp), %eax                                                      \n\
    movl %eax, -8(%esp)                                                      \n\
    /* Fetch the registers */                                                \n\
    movl 36(%ebp), %eax                                                      \n\
    movl 4(%eax), %ecx                                                       \n\
    movl 8(%eax), %edx                                                       \n\
    movl 12(%eax), %ebx                                                      \n\
    movl 24(%eax), %esi                                                      \n\
    movl 28(%eax), %edi                                                      \n\
    movl 0(%eax), %eax                                                       \n\
    /* Perform the callout */                                                \n\
    call .LcallTrap                                                          \n\
    /* Store the registers in the stack */                                   \n\
    subl $8, %esp                                                            \n\
    fstpl (%esp)                                                             \n\
    pushl %edi                                                               \n\
    pushl %esi                                                               \n\
    pushl %esp                                                               \n\
    pushl %ebp                                                               \n\
    pushl %ebx                                                               \n\
    pushl %edx                                                               \n\
    pushl %ecx                                                               \n\
    pushl %eax                                                               \n\
    /* Copy the registers back to the callout state */                       \n\
    movl $10, %ecx                                                           \n\
    movl %esp, %esi                                                          \n\
    movl 36(%ebp), %edi                                                      \n\
    cld                                                                      \n\
    rep movsd                                                                \n\
    /* Return */                                                             \n\
    movl %ebp, %esp                                                          \n\
    popa                                                                     \n\
    ret                                                                      \n\
.LcallTrap:                                                                  \n\
    subl $4, %esp                                                            \n\
    ret                                                                      \n\
");

static void lowcodeCalloutStatestackPointerstackSizecallFunction(sqLowcodeCalloutState *calloutState, char *stackPointer, size_t stackSize, char* functionPointer);

#endif /*_SQ_LOWCODE_FFI_I386_H_*/
