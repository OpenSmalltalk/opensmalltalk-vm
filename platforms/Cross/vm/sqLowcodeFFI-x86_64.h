/* sqLowcodeFFI-i386 -- i386 Platform specific definitions for the FFI.
 *
 * Author: Ronie Salgado (roniesalg@gmail.com)
 */


#ifndef _SQ_LOWCODE_FFI_X86_64_H_
#define _SQ_LOWCODE_FFI_X86_64_H_

typedef union __attribute__((aligned(16))) _sqLowcodeVectorRegister
{
    float singleComponents[4];
    double doubleComponents[2];
} sqLowcodeVectorRegister;

typedef struct __attribute__((aligned(16))) _sqLowcodeCalloutState
{
    union
    {
        struct
        {
            uint64_t rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi;
            uint64_t r8, r9, r10, r11, r12, r13, r14, r15;
        };

        uint64_t intRegisters[16];
    };

    union
    {
        struct
        {
            sqLowcodeVectorRegister xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, xmm7;
            sqLowcodeVectorRegister xmm8, xmm9, xmm10, xmm11, xmm12, xmm13, xmm14, xmm15;
        };

        sqLowcodeVectorRegister vectorRegisters[16];
    };

} sqLowcodeCalloutState;

#define lowcodeCalloutStatepointerRegister(calloutState, registerId) ((char*)(calloutState)->intRegisters[registerId])
#define lowcodeCalloutStatepointerRegistervalue(calloutState, registerId, value) ((calloutState)->intRegisters[registerId] = (uint64_t) (value))

#define lowcodeCalloutStateint32Register(calloutState, registerId) ((calloutState)->intRegisters[registerId])
#define lowcodeCalloutStateint32Registervalue(calloutState, registerId, value) ((calloutState)->intRegisters[registerId] = (value))

#define lowcodeCalloutStateint64Register(calloutState, registerId) ((calloutState)->intRegisters[registerId])
#define lowcodeCalloutStateint64Registervalue(calloutState, registerId, value) ((calloutState)->intRegisters[registerId] = (value))

#define lowcodeCalloutStatefloat32Register(calloutState, registerId) ((calloutState)->vectorRegisters[registerId].singleComponents[0])
#define lowcodeCalloutStatefloat32Registervalue(calloutState, registerId, value) ((calloutState)->vectorRegisters[registerId].singleComponents[0] = (value))

#define lowcodeCalloutStatefloat64Register(calloutState, registerId) ((calloutState)->vectorRegisters[registerId].doubleComponents[0])
#define lowcodeCalloutStatefloat64Registervalue(calloutState, registerId, value) ((calloutState)->vectorRegisters[registerId].doubleComponents[0] = (value))

#define lowcodeCalloutStateFetchResultInt32(calloutState) ((calloutState)->rax)
#define lowcodeCalloutStateFetchResultInt64(calloutState) ((calloutState)->rax)
#define lowcodeCalloutStateFetchResultPointer(calloutState) ((char*)(calloutState)->rax)

#define lowcodeCalloutStateFetchResultFloat32(calloutState) ((calloutState)->xmm0.singleComponents[0])
#define lowcodeCalloutStateFetchResultFloat64(calloutState) ((calloutState)->xmm0.doubleComponents[0])
#define lowcodeCalloutStateFetchResultStructure(calloutState) ((char*)(calloutState)->rax)

#ifdef _WIN32
#define ARGUMENT_calloutState "104(%rbp)"        /* RCX */
#define ARGUMENT_stackPointer "96(%rbp)"         /* RDX*/
#define ARGUMENT_stackSize    "56(%rbp)"         /* R8 */
#define ARGUMENT_functionPointer "48%(rbp)"      /* R9 */
#else
#define ARGUMENT_calloutState "64(%rbp)"         /* RDI*/
#define ARGUMENT_stackPointer "72(%rbp)"         /* RSI */
#define ARGUMENT_stackSize    "96(%rbp)"         /* RDX*/
#define ARGUMENT_functionPointer  "104(%rbp)"    /* RCX */
#endif

#if defined(_WIN32)
#define LOWCODE_FFI_PROGRAM_SECTION ".section .text"
#define LOWCODE_FFI_SYMBOL_PREFIX ""
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
    push %rax                                                                \n\
    push %rcx                                                                \n\
    push %rdx                                                                \n\
    push %rbx                                                                \n\
    push %rbp                                                                \n\
    push %rsi                                                                \n\
    push %rdi                                                                \n\
    push %r8                                                                 \n\
    push %r9                                                                 \n\
    push %r10                                                                \n\
    push %r11                                                                \n\
    push %r12                                                                \n\
    push %r13                                                                \n\
    push %r14                                                                \n\
    push %r15                                                                \n\
    movq %rsp, %rbp                                                          \n\
    /* Align the stack */                                                    \n\
    andq $-16, %rsp                                                          \n\
    /* Copy the stack arguments */                                           \n\
    movq " ARGUMENT_stackPointer ", %rsi                                     \n\
    movq " ARGUMENT_stackSize ", %rcx                                        \n\
    subq %rcx, %rsp                                                          \n\
    shrq $3, %rcx                                                            \n\
    movq %rsp, %rdi                                                          \n\
    cld                                                                      \n\
    rep movsq                                                                \n\
    /* Fetch the function pointer */                                         \n\
    movq " ARGUMENT_functionPointer ", %rax                                  \n\
    movq %rax, -16(%rsp)                                                     \n\
    /* Fetch the registers */                                                \n\
    movq " ARGUMENT_calloutState ", %rax                                     \n\
    movaps 128(%rax), %xmm0                                                  \n\
    movaps 144(%rax), %xmm1                                                  \n\
    movaps 160(%rax), %xmm2                                                  \n\
    movaps 176(%rax), %xmm3                                                  \n\
    movaps 192(%rax), %xmm4                                                  \n\
    movaps 208(%rax), %xmm5                                                  \n\
    movaps 224(%rax), %xmm6                                                  \n\
    movaps 240(%rax), %xmm7                                                  \n\
    movaps 256(%rax), %xmm8                                                  \n\
    movaps 272(%rax), %xmm9                                                  \n\
    movaps 288(%rax), %xmm10                                                 \n\
    movaps 304(%rax), %xmm11                                                 \n\
    movaps 320(%rax), %xmm12                                                 \n\
    movaps 336(%rax), %xmm13                                                 \n\
    movaps 352(%rax), %xmm14                                                 \n\
    movaps 368(%rax), %xmm15                                                 \n\
    movq 8(%rax), %rcx                                                       \n\
    movq 16(%rax), %rdx                                                      \n\
    movq 24(%rax), %rbx                                                      \n\
    movq 48(%rax), %rsi                                                      \n\
    movq 56(%rax), %rdi                                                      \n\
    movq 64(%rax), %r8                                                       \n\
    movq 72(%rax), %r9                                                       \n\
    movq 80(%rax), %r10                                                      \n\
    movq 88(%rax), %r11                                                      \n\
    movq 96(%rax), %r12                                                      \n\
    movq 104(%rax), %r13                                                     \n\
    movq 112(%rax), %r14                                                     \n\
    movq 120(%rax), %r15                                                     \n\
    movq 0(%rax), %rax                                                       \n\
    /* Perform the callout */                                                \n\
    call .LcallTrap                                                          \n\
    /* Store the registers in the stack */                                   \n\
    push %r15                                                                \n\
    push %r14                                                                \n\
    push %r13                                                                \n\
    push %r12                                                                \n\
    push %r11                                                                \n\
    push %r10                                                                \n\
    push %r9                                                                 \n\
    push %r8                                                                 \n\
    push %rdi                                                                \n\
    push %rsi                                                                \n\
    push %rsp                                                                \n\
    push %rbp                                                                \n\
    push %rbx                                                                \n\
    push %rdx                                                                \n\
    push %rcx                                                                \n\
    push %rax                                                                \n\
    /* Copy the registers back to the callout state */                       \n\
    movq $16, %rcx                                                           \n\
    movq %rsp, %rsi                                                          \n\
    movq " ARGUMENT_calloutState ", %rax                                     \n\
    movq %rax, %rdi                                                          \n\
    cld                                                                      \n\
    rep movsq                                                                \n\
    /* Copy the vector registers back to the callout state */                \n\
    movaps %xmm0, 128(%rax)                                                  \n\
    movaps %xmm1, 144(%rax)                                                  \n\
    movaps %xmm2, 160(%rax)                                                  \n\
    movaps %xmm3, 176(%rax)                                                  \n\
    movaps %xmm4, 192(%rax)                                                  \n\
    movaps %xmm5, 208(%rax)                                                  \n\
    movaps %xmm6, 224(%rax)                                                  \n\
    movaps %xmm7, 240(%rax)                                                  \n\
    movaps %xmm8, 256(%rax)                                                  \n\
    movaps %xmm9, 272(%rax)                                                  \n\
    movaps %xmm10, 288(%rax)                                                 \n\
    movaps %xmm11, 304(%rax)                                                 \n\
    movaps %xmm12, 320(%rax)                                                 \n\
    movaps %xmm13, 336(%rax)                                                 \n\
    movaps %xmm14, 352(%rax)                                                 \n\
    movaps %xmm15, 368(%rax)                                                 \n\
    /* Return */                                                             \n\
    movq %rbp, %rsp                                                          \n\
    pop %r15                                                                 \n\
    pop %r14                                                                 \n\
    pop %r13                                                                 \n\
    pop %r12                                                                 \n\
    pop %r11                                                                 \n\
    pop %r10                                                                 \n\
    pop %r9                                                                  \n\
    pop %r8                                                                  \n\
    pop %rdi                                                                 \n\
    pop %rsi                                                                 \n\
    pop %rbp                                                                 \n\
    pop %rbx                                                                 \n\
    pop %rdx                                                                 \n\
    pop %rcx                                                                 \n\
    pop %rax                                                                 \n\
    ret                                                                      \n\
.LcallTrap:                                                                  \n\
    subq $8, %rsp                                                            \n\
    ret                                                                      \n\
");

static void lowcodeCalloutStatestackPointerstackSizecallFunction(sqLowcodeCalloutState *calloutState, char *stackPointer, size_t stackSize, char* functionPointer);

#undef ARGUMENT_calloutState
#undef ARGUMENT_stackPointer
#undef ARGUMENT_stackSize
#undef ARGUMENT_functionPointer

#endif /*_SQ_LOWCODE_FFI_X86_64_H_*/
