"
This plugin provides access to foreign function interfaces on those platforms that provide such. For example Windows DLLs and unix .so's.  This version is designed to support reentrancy and threading, and so uses alloca to stack allocate all memory needed for a given callout.  Specific platforms are implemented by concrete subclasses.  Threaded calls can only be provided within the context of the threaded VM; othewise calls must be blocking.  So code specific to threading is guarded with a
	self cppIf: COGMTVM
		ifTrue: [...]
form to arrange that it is only compiled in the threaded VM context.

The callout primitives consume a type spec that defines the signature of the function to be called and a vector of arguments.  The type spec may be extracted from the method containing an FFI pragma or as an explicit parameter.  The arguments to be passed may either be arguments to the the method containing an FFI pragma or as an explicit Array of parameters.

Space is allocated to house the marshalled parameters and the type spec and arguments are then parsed to marshall the actual parameters into that space.  The space is some combination of alloca'ed (stack allocated) memory for parameters passed on the stack and a ""callout state"" struct (an instance of ThreadedFFICalloutState) to hold any parameters to be passed in registers.

By using C's facilities appropriately we can arrange that the C compiler generates code for passing all parameters, avoiding having to descend to the assembler or machine-code level (*). The basic scheme is to use alloca to stack allocate space for passing stacked parameters, since the memory allocated by alloca is at top-of-stack and in exactly the right place for parameter passing (*), and to invoke the function to be called with as many arguments as there are integer register parameters in the calling convention.  For example, on x86/IA32 there are no register parameters and all arguments are passed on the stack, while on ARMv4/5/6 there are four integer register parameters.  Since float results are typically answered through a floating-point register and integer/pointer results answered through one (or, on 32-bits for 64-bit results, two) register(s).  So on x86 the function to be called is invoked using

	floatRet := self dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'double (*)()')
or
	intRet := self dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'usqLong (*)()')

On ARMv4/5/6 it is invoked with

	floatRet := self 
			dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'float (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)') 
			with: (calloutState integerRegisters at: 0)
			with: (calloutState integerRegisters at: 1)
			with: (calloutState integerRegisters at: 2)
			with: (calloutState integerRegisters at: 3)
or
	floatRet := self 
				dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'double (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)') 
				with: (calloutState integerRegisters at: 0)
				with: (calloutState integerRegisters at: 1)
				with: (calloutState integerRegisters at: 2)
				with: (calloutState integerRegisters at: 3)
or
	intRet := self 
				dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'usqIntptr_t (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)') 
				with: (calloutState integerRegisters at: 0)
				with: (calloutState integerRegisters at: 1)
				with: (calloutState integerRegisters at: 2)
				with: (calloutState integerRegisters at: 3)

Hence the C compiler generates the code to pass register parameters appropriately.  All we have to do is provide sufficient register parameters and give the function (pointer) to be called a suitable type.

Likewise we also persuade the C compiler to generate code to load any floating-point register arguments by preceding any call of a function that takes floating-point arguments passed in registers with a call to loadFloatRegs with as many floating-point parameters as there are floating-point parameter registers.  loadFloatRegs is implemented in platforms//Cross/plugins/SqueakFFIPrims/sqFFIPlugin.c as an empty function.  So floating-point registers are passed via calls such as:

	calloutState floatRegisterIndex > 0 ifTrue:
		[self loadFloatRegs:
			   ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 0)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 2)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 4)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 6)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 8)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 10)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 12)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 14)) to: #'double *') at: 0)

(*) some implementations of alloca do not answer the actual top-of-stack, but may answer an address a word or two away.  On these implementations we merely derive the top-of-stack instead of using the result of alloca, or perhaps set the stack pointer to the result of alloca, as befits the platform.

Callbacks are not handled by this plugin.  Instead they are handled by image-level code to create Alien ""thunks"", small sequences of machine code, that invoke a function thunkEntry, implemented as required by each platform in one of the files in platforms/Cross/plugins/IA32ABI (a regrettable name; it should be something like platforms/Cross/plugins/AlienCallbacks).  Each platform's thunkEntry has a signature that takes all integer register parameters (if any), all floating-point register parameters (if any), a pointer to the thunk, and the stack pointer at the point the thunk was invoiked.  To pass a callback to foreign code, the marshaller in this plugin passes the address of the thunk.  When external code calls that address the think is invoked, and it invokes thunkEntry as required.  thunkEntry then saves its parameters locally in an instance of VMCallbackContext, which includes a jmpbuf.  thunkEntry then does a setjmp and enters the VM via sendInvokeCallbackContext[:], which creates an activation of invokeCallbackContext: to execute the callback.  This method then extracts the address of the thunk from the VMCallbackContext and invokes machinery in Callback to match the address with a Smalltalk block.  The block is then evaluated with the parameters extracted from the VMCallbackContext, marshalled by methods in Callback subclasses signatures protocol, which know whether a parameter would be passed in a register or on the stack.  The result of the block is then passed back to thunkEntry by storing it in a field in the VMCallbackContext and invoking primSignal:andReturnAs:fromContext:, which uses longjmp to jump back to thunkEntry which then extracts the result from its VMCallbackContext and returns.

For  example, the signature of thunkEntry on x86/IA32 (platforms/Cross/plugins/IA32ABI/ia32abicc.c) is
	long
	thunkEntry(void *thunkp, sqIntptr_t *stackp)
whereas on ARMv4/5/6 (platforms/Cross/plugins/IA32ABI/arm32abicc.c) it is
	long long
	thunkEntry(long r0, long r1, long r2, long r3,
		            double d0, double d1, double d2, double d3,
		            double d4, double d5, double d6, double d7,
		            void *thunkpPlus16, sqIntptr_t *stackp)
"
Class {
	#name : #ThreadedFFIPlugin,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'ffiLogEnabled',
		'externalFunctionInstSize',
		'ffiLastError',
		'allocationMap'
	],
	#classVars : [
		'DefaultMaxStackSize',
		'ExternalFunctionAddressIndex',
		'ExternalFunctionArgTypesIndex',
		'ExternalFunctionFlagsIndex',
		'ExternalFunctionStackSizeIndex',
		'MaxNumArgs'
	],
	#pools : [
		'FFIConstants'
	],
	#category : #'VMMaker-Plugins-FFI'
}

{ #category : #translation }
ThreadedFFIPlugin class >> ancilliaryClasses [
	^{ self calloutStateClass }
]

{ #category : #translation }
ThreadedFFIPlugin class >> calloutStateClass [
	^ThreadedFFICalloutState
]

{ #category : #translation }
ThreadedFFIPlugin class >> declareCVarsIn: cg [
	super declareCVarsIn: cg.
	cg removeConstant: #COGMTVM. "this should be defined at compile time"
	cg removeVariable: #allocationMap "this is simulation only"
]

{ #category : #translation }
ThreadedFFIPlugin class >> excludingPredefinedMacros [
	"Answer the predefined macros that disqualify the platforms a subclass handles, if any.
	 These are anded together and with includingPredefinedMacros, whereas
	 identifyingPredefinedMacros are ored together.
	 This can be used to differentiate e.g. x64 Sys V from x64 Win64."
	^nil
]

{ #category : #translation }
ThreadedFFIPlugin class >> generateCodeStringForPrimitives [
	"Output a skeletal SqueakFFIPrims.c that includes the relevant FooFFIPlugin.c for
	 each subclass based on the identifyingPredefinedMacros the subclass defines."
	 
	^String streamContents:
		[:s|
		 s nextPutAll: '/* Automatically generated by\	' withCRs.
		 s nextPutAll: (CCodeGenerator monticelloDescriptionFor: self).
		 s cr; nextPutAll: ' */'.
		 s cr; cr; nextPut: $#.
		 (self allSubclasses sort: [:a :b| a name < b name]) do:
			[:class |
			class identifyingPredefinedMacros ifNotNil:
				[:predefinedMacros|
				 s nextPutAll: 'if '.
				class includingPredefinedMacros ifNotNil:
					[:includingMacros|
					 includingMacros do:
						[:predefinedMacro| s nextPutAll: 'defined('; nextPutAll: predefinedMacro; nextPutAll: ') && '].
					 s nextPut: $(].
				class excludingPredefinedMacros ifNotNil:
					[:excludingMacros|
					 excludingMacros do:
						[:predefinedMacro| s nextPutAll: '!defined('; nextPutAll: predefinedMacro; nextPutAll: ') && '].
					 s nextPut: $(].
				 predefinedMacros
					do: [:predefinedMacro| s nextPutAll: 'defined('; nextPutAll: predefinedMacro; nextPut: $)]
					separatedBy: [s nextPutAll: ' || '].
				class excludingPredefinedMacros ifNotNil:
					[s nextPut: $)].
				class includingPredefinedMacros ifNotNil:
					[s nextPut: $)].
				 s cr; cr; nextPutAll: '# define '; nextPutAll: class moduleName; nextPutAll: '_exports ';
												nextPutAll: self moduleName; nextPutAll: '_exports'.
				 s cr; nextPutAll: '# include "'; nextPutAll: class moduleName; nextPutAll: '.c"'.
				 s cr; cr; nextPutAll: '#el']].
		 s nextPutAll: 'se'.
		 #(	'As yet no FFI implementation appears to exist for your platform.'
			'Consider implementing it, starting by adding a subclass of ThreadedFFIPlugin.') do:
			[:msg| s cr; nextPutAll: '# error '; nextPutAll: msg].
		 s cr; nextPutAll: '#endif'; cr]
]

{ #category : #translation }
ThreadedFFIPlugin class >> identifyingPredefinedMacros [
	"Answer the predefined macros that identify the platforms a subclass handles, if any.
	 These are ored together.
	 If the subclass isn't yet ready for production (a work in progress) simply answer nil."
	^nil
]

{ #category : #translation }
ThreadedFFIPlugin class >> includingPredefinedMacros [
	"Answer the predefined macros that qualify the platforms a subclass handles, if any.
	 These are anded together and with excludingPredefinedMacros, whereas
	 identifyingPredefinedMacros are ored together.
	 This can be used to differentiate e.g. x64 Sys V from x64 Win64."
	^nil
]

{ #category : #'class initialization' }
ThreadedFFIPlugin class >> initialize [
	"c.f. ExternalFunction allInstVarNames
		old: #('handle' 'flags' 'argTypes')
		new: #('handle' 'flags' 'argTypes' 'stackSize')"
	ExternalFunctionAddressIndex := 0.
	ExternalFunctionFlagsIndex := 1.
	ExternalFunctionArgTypesIndex := 2.
	ExternalFunctionStackSizeIndex := 3.

	"c.f. e.g. CoInterpreter class initializeMiscConstants"
	MaxNumArgs := 15.

	DefaultMaxStackSize := 1024 * 16
]

{ #category : #accessing }
ThreadedFFIPlugin class >> maxNumArgs [
	^MaxNumArgs
]

{ #category : #translation }
ThreadedFFIPlugin class >> moduleExportsName [
	"To make the inclusion of the platform-specific plugin to work it can't use
	 its moduleName in the exports but must use the proper moduleName."

	^ThreadedFFIPlugin moduleName
]

{ #category : #translation }
ThreadedFFIPlugin class >> moduleName [
	"IMPORTANT: IF YOU CHANGE THE NAME OF THIS PLUGIN YOU MUST CHANGE
		Interpreter>>primitiveCalloutToFFI *and* ThreadedFFIPlugin>>getModuleName
	TO REFLECT THE CHANGE."
	^#('SqueakFFIPrims' 'FFIPlugin') first
]

{ #category : #translation }
ThreadedFFIPlugin class >> preambleCCode [
	"For a source of builtin defines grep for builtin_define in a gcc release config directory.
	 See See platforms/Cross/vm/sqCogStackAlignment.h for per-platform definitions for
	 STACK_ALIGN_BYTES MUST_ALIGN_STACK et al."
	^'
#include "sqAssert.h" /* for assert */
#define ThreadedFFIPlugin 1 /* to filter-out unwanted declarations from sqFFI.h */
#include "sqFFI.h" /* for logging and surface functions */
#include "sqCogStackAlignment.h" /* for STACK_ALIGN_BYTES and getsp() */

#ifdef _MSC_VER
# define alloca _alloca
#endif
#if defined(__GNUC__) && (defined(_X86_) || defined(i386) || defined(__i386) || defined(__i386__))
# define setsp(sp) asm volatile ("movl %0,%%esp" : : "m"(sp))
# elif defined(__GNUC__) && (defined(__amd64__) || defined(__x86_64__) ||  defined(__amd64) || defined(__x86_64))
# define setsp(sp) asm volatile ("movq %0,%%rsp" : : "m"(sp))
# elif defined(__arm64__) || defined(__aarch64__) || defined(ARM64)
        /* https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html#Extended-Asm
         * http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.den0024a/index.html
         */
#  if __GNUC__
#   define getfp() ({ usqIntptr_t fp;                                                           \
                                          asm volatile ("mov x0, x29" : "=r"(x29) : );  \
                                          fp; })
#   define getsp() ({ usqIntptr_t sp;                                                           \
                                          asm volatile ("mov x0, sp" : "=r"(sp) : );    \
                                          sp; })
# define setsp(sp) asm volatile ("ldr x16, %0 \n\t" "mov sp, x16"  : : "m"(sp) )
#  endif
# elif defined(__GNUC__) && (defined(__arm__))
# define setsp(sp) asm volatile ("ldr %%sp, %0" : : "m"(sp))
#endif
#if !defined(getsp)
# define getsp() 0
#endif 
#if !defined(setsp)
# define setsp(ignored) 0
#endif 

#if !defined(STACK_ALIGN_BYTES)
#  define STACK_ALIGN_BYTES 0
#endif /* !defined(STACK_ALIGN_BYTES) */

/* For ABI that require stack alignment greater than natural word size */
#define MUST_ALIGN_STACK (STACK_ALIGN_BYTES > sizeof(void*))

#if defined(_X86_) || defined(i386) || defined(__i386) || defined(__i386__)
/* Both Mac OS X x86 and Win32 x86 return structs of a power of two in size
 * less than or equal to eight bytes in length in registers. Linux never does so.
 */
# if __linux__
#	define WIN32_X86_STRUCT_RETURN 0
# else
#	define WIN32_X86_STRUCT_RETURN 1
# endif
# if _WIN32
#	define PLATFORM_API_USES_CALLEE_POPS_CONVENTION 1
# endif
# elif defined(__amd64__) || defined(__x86_64__) ||  defined(__amd64) || defined(__x86_64)
# if _WIN32 | _WIN64
#	define PLATFORM_API_USES_CALLEE_POPS_CONVENTION 1
# endif
#endif /* defined(_X86_) || defined(i386) || defined(__i386) || defined(__i386__) */

#if !defined(ALLOCA_LIES_SO_SETSP_BEFORE_CALL)
# if defined(__MINGW32__) && !defined(__clang__) && (__GNUC__ >= 3) && (defined(_X86_) || defined(i386) || defined(__i386) || defined(__i386__))
    /*
     * cygwin -mno-cygwin (MinGW) gcc 3.4.x''s alloca is a library routine that answers
     * %esp + xx, so the outgoing stack is offset by one or more word if uncorrected.
     * Grab the actual stack pointer to correct.
     */
#	define ALLOCA_LIES_SO_SETSP_BEFORE_CALL 1
# else
#	define ALLOCA_LIES_SO_SETSP_BEFORE_CALL 0
# endif
#endif /* !defined(ALLOCA_LIES_SO_SETSP_BEFORE_CALL) */

#if !defined(PLATFORM_API_USES_CALLEE_POPS_CONVENTION)
# define PLATFORM_API_USES_CALLEE_POPS_CONVENTION 0
#endif

/* This alignment stuff is a hack for integerAt:put:size:signed:/primitiveFFIIntegerAt[Put].
 * The assumption right now is that all processors support unaligned access.  That only
 * holds true for x86, x86-64 & ARMv6 & later.  But this keeps us going until we can address
 * it properly.
 */
#define unalignedShortAt(a) shortAt(a)
#define unalignedShortAtput(a,v) shortAtput(a,v)
#define unalignedLong32At(a) long32At(a)
#define unalignedLong32Atput(a,v) long32Atput(a,v)
#define unalignedLong64At(a) long64At(a)
#define unalignedLong64Atput(a,v) long64Atput(a,v)

/* The dispatchOn:in:with:with: generates an unwanted call on error.  Just squash it. */
#define error(foo) 0
#ifndef SQUEAK_BUILTIN_PLUGIN
/* but print assert failures. */
void
warning(char *s) { /* Print an error message but don''t exit. */
	printf("\n%s\n", s);
}
#endif

/* sanitize */
#ifdef SQUEAK_BUILTIN_PLUGIN
# define EXTERN 
#else
# define EXTERN extern
#endif
'
]

{ #category : #translation }
ThreadedFFIPlugin class >> translateInDirectory: directory doInlining: inlineFlag [
	"As a hack to allow ThreadedFFIPlugin to generate a skeletal SqueakFFIPrims.c that
	 simply includes the fleshed-out SqueakIA32FFIPrims.c, SqueakARMFFIPrims.c et al,
	 intercept for ThreadedFFIPlugin and output generateCodeStringForPrimitives."
	| ffiPluginRootClass |
	ffiPluginRootClass := thisContext method methodClass soleInstance.
	^self == ffiPluginRootClass
		ifTrue:
			[self
				storeString: self generateCodeStringForPrimitives
				onFileNamed: (directory fullNameFor: self moduleName, '.c').
			#()]
		ifFalse:
			[super
				translateInDirectory: (directory containingDirectory directoryNamed: ffiPluginRootClass moduleName) assureExistence
				doInlining: inlineFlag]
]

{ #category : #marshalling }
ThreadedFFIPlugin >> allocaLiesSoSetSpBeforeCall [
	"At least one alloca implementation does not answer the actual top of stack.
	 If so we need to reset the actual stack pointer just before the call.
	Answer whether this is necessary."
	<cmacro: '() ALLOCA_LIES_SO_SETSP_BEFORE_CALL'>
	^false
]

{ #category : #'primitive support' }
ThreadedFFIPlugin >> atomicTypeOf: typeSpec [
	^(typeSpec bitAnd: FFIAtomicTypeMask) >> FFIAtomicTypeShift
]

{ #category : #marshalling }
ThreadedFFIPlugin >> cStackAlignment [
	"Many ABIs mandate a particular stack alignment greater than the natural word
	 size. If so, this macro will answer that alignment.  If not, this macro will answer 0.
	 See platforms/Cross/vm/sqCogStackAlignment.h and class-side preambleCCode."
	<cmacro: '() STACK_ALIGN_BYTES'>
	^0
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> cleanupCalloutState: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<returnTypeC: #void>
	"Free any temporary arg strings."
	<inline: true>
	[calloutState stringArgIndex > 0] whileTrue:
		[self free: (calloutState stringArgs at: (calloutState stringArgIndex: calloutState stringArgIndex - 1))]
]

{ #category : #simulation }
ThreadedFFIPlugin >> destroyManualSurface: surfaceID [
	<doNotGenerate>
	"Temporarily hack the simulation.  Soon enough we could defer top the actual SurfacePlugin to simulate surfaces properly."
	^1
]

{ #category : #'primitive support' }
ThreadedFFIPlugin >> disownFlagsFor: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: #always>
	^self cppIf: COGMTVM
		ifTrue: [(calloutState callFlags anyMask: FFICallFlagThreaded)
					ifTrue: [DisownVMForFFICall+DisownVMForThreading]
					ifFalse: [DisownVMForFFICall]]
		ifFalse: [DisownVMForFFICall]
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> dispatchFunctionPointer: aFunctionPointer [
	"In C aFunctionPointer is void (*aFunctionPointer)()"
	<cmacro: '(aFunctionPointer) (aFunctionPointer)()'>
	"To write the FFI call failure code we simulate invoking the production VM's
	 fatal exception handlers (sigsegv on Unix, squeakExceptionHandler on WIN32, et al)."
	^[self perform: aFunctionPointer]
		on: Error
		do: [:ex|
			interpreterProxy
				primitiveFailForFFIException: PrimErrFFIException
				at: aFunctionPointer asInteger.
			ex pass "NOTREACHED if VM is handling FFI exceptions"]
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> dispatchFunctionPointer: aFunctionPointer with: int1 with: int2 with: int3 with: int4 [
	"In C aFunctionPointer is void (*aFunctionPointer)(int, int, int, int)"
	<cmacro: '(aFunctionPointer, int1, int2, int3, int4) (aFunctionPointer)(int1, int2, int3, int4)'>
	"To write the FFI call failure code we simulate invoking the production VM's
	 fatal exception handlers (sigsegv on Unix, squeakExceptionHandler on WIN32, et al)."
	^[self perform: aFunctionPointer
			with: int1
			with: int2
			with: int3
			with: int4]
		on: Error
		do: [:ex|
			interpreterProxy
				primitiveFailForFFIException: PrimErrFFIException
				at: aFunctionPointer asInteger.
			ex pass "NOTREACHED if VM is handling FFI exceptions"]
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> dispatchFunctionPointer: aFunctionPointer with: int1 with: int2 with: int3 with: int4 with: int5 with: int6 [
	"In C aFunctionPointer is void (*aFunctionPointer)(int, int, int, int, int, int)"
	<cmacro: '(aFunctionPointer, int1, int2, int3, int4, int5, int6) (aFunctionPointer)(int1, int2, int3, int4, int5, int6)'>
	"To write the FFI call failure code we simulate invoking the production VM's
	 fatal exception handlers (sigsegv on Unix, squeakExceptionHandler on WIN32, et al)."
	^[self perform: aFunctionPointer
			with: int1
			with: int2
			with: int3
			with: int4
			with: int5
			with: int6]
		on: Error
		do: [:ex|
			interpreterProxy
				primitiveFailForFFIException: PrimErrFFIException
				at: aFunctionPointer asInteger.
			ex pass "NOTREACHED if VM is handling FFI exceptions"]
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> dispatchFunctionPointer: aFunctionPointer with: int1 with: int2 with: int3 with: int4 with: int5 with: int6 with: int7 with: int8 [
	"In C aFunctionPointer is void (*aFunctionPointer)(int, int, int, int, int, int)"
	<cmacro: '(aFunctionPointer, int1, int2, int3, int4, int5, int6, int7, int8) (aFunctionPointer)(int1, int2, int3, int4, int5, int6, int7, int8)'>
	"To write the FFI call failure code we simulate invoking the production VM's
	 fatal exception handlers (sigsegv on Unix, squeakExceptionHandler on WIN32, et al)."
	^[self perform: aFunctionPointer
			with: int1
			with: int2
			with: int3
			with: int4
			with: int5
			with: int6
			with: int7
			with: int8]
		on: Error
		do: [:ex|
			interpreterProxy
				primitiveFailForFFIException: PrimErrFFIException
				at: aFunctionPointer asInteger.
			ex pass "NOTREACHED if VM is handling FFI exceptions"]
]

{ #category : #'symbol loading' }
ThreadedFFIPlugin >> externalFunctionHasStackSizeSlot [
	<inline: true>
	^externalFunctionInstSize > ExternalFunctionStackSizeIndex
]

{ #category : #'primitive support' }
ThreadedFFIPlugin >> ffiAddressOf: rcvr startingAt: byteOffset size: byteSize [
	"Answer a long of the address of the byteSize slot (byte, short, int, whatever) at byteOffset in rcvr.
	 Nominally intended for use with ExternalAddress objects, this code will work (for obscure historical
	 reasons) with plain Byte or Word Arrays as well. Answer 0 on error."
	| rcvrClass rcvrSize addr |
	(interpreterProxy isBytes: rcvr) ifFalse:[^0].
	byteOffset > 0 ifFalse:[^0].
	rcvrClass := interpreterProxy fetchClassOf: rcvr.
	rcvrSize := interpreterProxy byteSizeOf: rcvr.
	rcvrClass = interpreterProxy classExternalAddress
		ifTrue:
			[rcvrSize = BytesPerWord ifFalse:[^0].
			addr := interpreterProxy fetchPointer: 0 ofObject: rcvr. "Hack!!"
			"don't you dare to read from object memory (unless is pinned)!"
			(addr = 0 "or: [(interpreterProxy isInMemory: addr) or: [(interpreterProxy isPinned: rcvr) not]]") ifTrue:
				[^0]]
		ifFalse:
			[byteOffset+byteSize-1 <= rcvrSize ifFalse:
				[^0].
			addr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: #'sqIntptr_t'].
	addr := addr + byteOffset - 1.
	^addr asVoidPointer
]

{ #category : #'primitive support' }
ThreadedFFIPlugin >> ffiAlloc: bytes [
	"Default to malloc/free.  If a platform needs a different allocator define
	 something in the preamble and redefine this to take account of that."
	<cmacro: '(bytes) (usqInt)malloc(bytes)'>
	"Simulate external allocation.  This would be straight-forward were it not for simulating a
	 32-bit system above a 64-bit system, where the result of an allocation won't fit in a 32-bit
	 pointer.  So in this case maintain a map from external allocations to fake addresses."
	| externalAllocation key |
	(self evaluateIfFailed: [externalAllocation := ExternalAddress allocate: bytes]) ifTrue: [^0].
	(self sizeof: #sqIntptr_t) >= Smalltalk wordSize ifTrue:
		[^externalAllocation asInteger].
	allocationMap ifNil:
		[allocationMap := Dictionary new].
	allocationMap at: (key := allocationMap size * (4 * 1024 * 1024) + 16r8E000000) put: externalAllocation asInteger.
	^key
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiArgByValue: oop in: calloutState [
	"Support for generic callout. Prepare an argument by value for a callout."
	<var: #calloutState type: #'CalloutState *'>
	| atomicType intValue floatValue |
	<inline: true>
	<var: #floatValue type: #double>
	atomicType := self atomicTypeOf: calloutState ffiArgHeader.
	"check if the range is valid"
	(atomicType < 0 or:[atomicType > FFITypeDoubleFloat])
		ifTrue:[^FFIErrorBadAtomicType].
	atomicType < FFITypeSingleFloat ifTrue:["integer types"
		(atomicType >> 1) = (FFITypeSignedLongLong >> 1)
			ifTrue:[intValue := oop] "ffi support code must coerce longlong"
			ifFalse:[intValue := self ffiIntegerValueOf: oop]. "does all the coercions"
		interpreterProxy failed ifTrue:[^FFIErrorCoercionFailed].
		^self dispatchOn: atomicType
			in: #(
				ffiPushVoid:in:
				ffiPushUnsignedInt:in:
				ffiPushUnsignedByte:in:
				ffiPushSignedByte:in:
				ffiPushUnsignedShort:in:
				ffiPushSignedShort:in:
				ffiPushUnsignedInt:in:
				ffiPushSignedInt:in:
				ffiPushUnsignedLongLongOop:in:
				ffiPushSignedLongLongOop:in:
				ffiPushUnsignedChar:in:
				ffiPushSignedChar:in:)
			with: intValue
			with: calloutState].
	"either float or double"
	floatValue := self ffiFloatValueOf: oop.
	interpreterProxy failed ifTrue:
		[^FFIErrorCoercionFailed].
	atomicType = FFITypeSingleFloat
		ifTrue: [^self ffiPushSingleFloat: floatValue in: calloutState]
		ifFalse:[^self ffiPushDoubleFloat: floatValue in: calloutState]
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiArgument: oop Spec: argSpec Class: argClass in: calloutState [
	"Callout support. Prepare the given oop as argument.
	argSpec defines the compiled spec for the argument.
	argClass (if non-nil) defines the required (super)class for the argument."
	<var: #calloutState type: #'CalloutState *'>
	| valueOop oopClass isStruct nilOop |
	<inline: false>
	oopClass := interpreterProxy fetchClassOf: oop. "Prefetch class (we'll need it)"
	nilOop :=  interpreterProxy nilObject.
	"Do the necessary type checks"
	argClass = nilOop ifFalse:[
		"Type check 1: 
		Is the required class of the argument a subclass of ExternalStructure?"
		(interpreterProxy includesBehavior: argClass 
						ThatOf: interpreterProxy classExternalStructure)
			ifFalse:[^FFIErrorWrongType]. "Nope. Fail."
		"Type check 2:
		Is the class of the argument a subclass of required class?"
		((nilOop = oop) or:[interpreterProxy includesBehavior: oopClass ThatOf: argClass])
				ifFalse:[^FFIErrorCoercionFailed]. "Nope. Fail."
		"Okay, we've passed the type check (so far)"
	].

	"Check if oopClass is a subclass of ExternalStructure.
	If this is the case we'll work on it's handle and not the actual oop."
	isStruct := false.
	(oop ~= nilOop
	 and: [interpreterProxy isPointers: oop]) ifTrue: "#isPointers: will fail if oop is immediate so don't even attempt to use it"
		[isStruct := interpreterProxy
						includesBehavior: oopClass 
						ThatOf: interpreterProxy classExternalStructure.
		 (argClass = nilOop or: [isStruct]) ifFalse:
			[^FFIErrorCoercionFailed]].
	"note: the test for #isPointers: above should speed up execution since no pointer type
	 ST objects are allowed in external calls and thus if #isPointers: is true then the arg must
	 be ExternalStructure to work. If it isn't then the code fails anyways so speed isn't an issue."

	"Determine valueOop (e.g., the actual oop to pass as argument)"
	isStruct
		ifTrue:[valueOop := interpreterProxy fetchPointer: 0 ofObject: oop]
		ifFalse:[valueOop := oop].

	"Fetch and check the contents of the compiled spec"
	(interpreterProxy isWords: argSpec)
		ifFalse:[^FFIErrorWrongType].
	calloutState ffiArgSpecSize: (interpreterProxy slotSizeOf: argSpec).
	calloutState ffiArgSpecSize = 0 ifTrue:[^FFIErrorWrongType].
	calloutState ffiArgSpec: (interpreterProxy firstIndexableField: argSpec).
	calloutState ffiArgHeader: (interpreterProxy longAt: calloutState ffiArgSpec).

	"Do the actual preparation of the argument"
	"Note: Order is important since FFIFlagStructure + FFIFlagPointer is used to represent 'typedef void* VoidPointer' and VoidPointer really is *struct* not pointer."

	(calloutState ffiArgHeader anyMask: FFIFlagStructure) ifTrue:[
		"argument must be ExternalStructure"
		isStruct ifFalse:[^FFIErrorCoercionFailed].
		(calloutState ffiArgHeader anyMask: FFIFlagAtomic) 
			ifTrue:[^FFIErrorWrongType]. "bad combination"
		^self ffiPushStructureContentsOf: valueOop in: calloutState].

	(calloutState ffiArgHeader anyMask: FFIFlagPointer) ifTrue:[
		"no integers (or characters) for pointers please"
		(interpreterProxy isImmediate: oop) 
			ifTrue:[^FFIErrorIntAsPointer].

		"but allow passing nil pointer for any pointer type"
		oop = nilOop ifTrue:[^self ffiPushPointer: nil in: calloutState].

		"argument is reference to either atomic or structure type"
		(calloutState ffiArgHeader anyMask: FFIFlagAtomic) ifTrue:[
			isStruct "e.g., ExternalData"
				ifTrue:[^self ffiAtomicStructByReference: oop Class: oopClass in: calloutState]
				ifFalse:[^self ffiAtomicArgByReference: oop Class: oopClass in: calloutState].
			"********* NOTE: The above uses 'oop' not 'valueOop' (for ExternalData) ******"
		].

		"Needs to be external structure here"
		isStruct ifFalse:[^FFIErrorCoercionFailed].
		^self ffiPushPointerContentsOf: valueOop in: calloutState].

	(calloutState ffiArgHeader anyMask: FFIFlagAtomic) ifTrue:[
		"argument is atomic value"
		^self ffiArgByValue: valueOop in: calloutState].
	"None of the above - bad spec"
	^FFIErrorWrongType
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiAtomicArgByReference: oop Class: oopClass in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	"Support for generic callout. Prepare a pointer reference to an atomic type for callout.
	 Note: 
		for type 'void*' we allow ByteArray/String/Symbol, wordVariableSubclass, Alien or ExternalAddress.
		for other types we allow ByteArray, wordVariableSubclass, Alien or ExternalAddress."
	| atomicType isString isAlien |
	<inline: true>
	atomicType := self atomicTypeOf: calloutState ffiArgHeader.
	(atomicType = FFITypeBool) ifTrue: "No bools on input"
		[^FFIErrorCoercionFailed].
	isAlien := (isString := interpreterProxy 
					includesBehavior: oopClass 
					ThatOf: interpreterProxy classString)
				ifTrue: [false]
				ifFalse:
					[interpreterProxy 
						includesBehavior: oopClass 
						ThatOf: interpreterProxy classAlien].
	((atomicType >> 1) = (FFITypeSignedChar >> 1)) ifTrue:"string value (char*)"
		"note: the only types allowed for passing into char* types are
		ByteArray, String, Symbol, Alien and *no* other byte indexed objects
		(e.g., CompiledMethod, LargeInteger). We only check for strings
		here and fall through to the byte* check otherwise."
		[isString ifTrue:"String/Symbol"
			"Strings must be allocated by the ffi support code"
			[^self ffiPushString: (interpreterProxy firstIndexableField: oop)
				OfLength: (interpreterProxy byteSizeOf: oop)
				in: calloutState].
		"Fall through to byte* test"
		atomicType := FFITypeUnsignedByte].

	self cppIf: COGMTVM ifTrue:
	["Since all the following pass the address of the first indexable field we need to fail
	 the call if it is threaded and the object is young, since it may move during the call."
	((calloutState callFlags anyMask: FFICallFlagThreaded)
	and: [(isAlien not or: [self isDirectAlien: oop])
	and: [interpreterProxy isYoung: oop]]) ifTrue:
		[^PrimErrObjectMayMove negated]].

	(atomicType = FFITypeVoid or:[(atomicType >> 1) = (FFITypeSignedByte >> 1)]) ifTrue:
		"byte* -- see comment on string above"
		[(isString or: [oopClass = interpreterProxy classByteArray]) ifTrue: "String/Symbol/ByteArray"
			[^self ffiPushPointer: (interpreterProxy firstIndexableField: oop) in: calloutState].
		(oopClass = interpreterProxy classExternalAddress) ifTrue: 
			[^self ffiPushPointer: (self longAt: oop + interpreterProxy baseHeaderSize) in: calloutState].
		isAlien ifTrue:
			[^self ffiPushPointer: (self pointerForOop: (self startOfData: oop)) in: calloutState].
		atomicType = FFITypeVoid ifFalse:
			[^FFIErrorCoercionFailed]].
		"note: type void falls through"

	"I can push pointers to any type (take for instance calls who receive int* output arguments, etc.)
	 but I need to store them into a ByteArray, ExternalAddress or Alien"
	(atomicType <= FFITypeDoubleFloat) ifTrue:
		[((interpreterProxy isWords: oop) or: [oopClass = interpreterProxy classByteArray]) ifTrue:
			[^self ffiPushPointer: (interpreterProxy firstIndexableField: oop) in: calloutState].
		(oopClass = interpreterProxy classExternalAddress) ifTrue: 
			[^self ffiPushPointer: (self longAt: oop + interpreterProxy baseHeaderSize) in: calloutState].
		isAlien ifTrue:
			[^self ffiPushPointer: (self pointerForOop: (self startOfData: oop)) in: calloutState]].

	^FFIErrorCoercionFailed
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiAtomicStructByReference: oop Class: oopClass in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	"Support for generic callout. Prepare an external pointer reference to an atomic type for callout."
	| atomicType err valueOop |
	<inline: true>
	"must be external data to pass pointers to atomic type"
	oopClass = interpreterProxy classExternalData 
		ifFalse:[^FFIErrorCoercionFailed].
	atomicType := self atomicTypeOf: calloutState ffiArgHeader.
	"no type checks for void pointers"
	atomicType ~= FFITypeVoid ifTrue:[
		err := self ffiValidateExternalData: oop AtomicType: atomicType.
		err ~= 0 ifTrue:[^err].
	].
	"and push pointer contents"
	valueOop := interpreterProxy fetchPointer: 0 ofObject: oop.
	^self ffiPushPointerContentsOf: valueOop in: calloutState
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiCall: externalFunction ArgArrayOrNil: argArrayOrNil NumArgs: nArgs [
	"Generic callout. Does the actual work.  If argArrayOrNil is nil it takes args from the stack
	 and the spec from the method.  If argArrayOrNil is not nil takes args from argArrayOrNil
	 and the spec from the receiver."
	| flags argTypeArray address argType oop argSpec argClass err theCalloutState calloutState requiredStackSize stackSize allocation result primNumArgs |
	<inline: true>
	<var: #theCalloutState type: #'CalloutState'>
	<var: #calloutState type: #'CalloutState *'>
	<var: #allocation type: #'char *'>

	primNumArgs := interpreterProxy methodArgumentCount.
	(interpreterProxy is: externalFunction KindOfClass: interpreterProxy classExternalFunction) ifFalse:
		[^self ffiFail: FFIErrorNotFunction].
	"Load and check the values in the externalFunction before we call out"
	flags := interpreterProxy fetchInteger: ExternalFunctionFlagsIndex ofObject: externalFunction.
	interpreterProxy failed ifTrue:
		[^self ffiFail: FFIErrorBadArgs].

	"This must come early for compatibility with the old FFIPlugin.  Image-level code
	 may assume the function pointer is loaded eagerly.  Thanks to Nicolas Cellier."
	address := self ffiLoadCalloutAddress: externalFunction.
	interpreterProxy failed ifTrue:
		[^0 "error code already set by ffiLoadCalloutAddress:"].
	
	argTypeArray := interpreterProxy fetchPointer: ExternalFunctionArgTypesIndex ofObject: externalFunction.
	"must be array of arg types"
	((interpreterProxy isArray: argTypeArray)
	and: [(interpreterProxy slotSizeOf: argTypeArray) = (nArgs + 1)]) ifFalse:
		[^self ffiFail: FFIErrorBadArgs].
	"check if the calling convention is supported"
	self cppIf: COGMTVM
		ifTrue:
			[(self ffiSupportsCallingConvention: (flags bitAnd: FFICallTypesMask)) ifFalse:
				[^self ffiFail: FFIErrorCallType]]
		ifFalse: "not masking causes threaded calls to fail, which is as they should if the plugin is not threaded."
			[(self ffiSupportsCallingConvention: flags) ifFalse:
				[^self ffiFail: FFIErrorCallType]].
		
	requiredStackSize := self externalFunctionHasStackSizeSlot
							ifTrue: [interpreterProxy
										fetchInteger: ExternalFunctionStackSizeIndex
										ofObject: externalFunction]
							ifFalse: [-1].
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: (argArrayOrNil isNil
												ifTrue: [PrimErrBadMethod]
												ifFalse: [PrimErrBadReceiver])].
	stackSize := requiredStackSize < 0 ifTrue: [DefaultMaxStackSize] ifFalse: [requiredStackSize].
	self cCode: [] inSmalltalk: [theCalloutState := self class calloutStateClass new].
	calloutState := self addressOf: theCalloutState.
	self cCode: [self me: calloutState ms: 0 et: (self sizeof: #CalloutState)].
	calloutState callFlags: flags.
	"Fetch return type and args"
	argType := interpreterProxy fetchPointer: 0 ofObject: argTypeArray.
	argSpec := interpreterProxy fetchPointer: 0 ofObject: argType.
	argClass := interpreterProxy fetchPointer: 1 ofObject: argType.
	(err := self ffiCheckReturn: argSpec With: argClass in: calloutState) ~= 0 ifTrue:
		[^self ffiFail: err]. "cannot return"
	"alloca the outgoing stack frame, leaving room for marshalling args, and including space for the return struct, if any.
	Additional space reserved for saving register args like mandated by Win64 X64 or PPC ABI, will be managed by the call itself"
	allocation := self alloca: stackSize + calloutState structReturnSize + self cStackAlignment.
	self mustAlignStack ifTrue:
		[allocation := self cCoerce: (allocation asUnsignedIntegerPtr bitClear: self cStackAlignment - 1) to: #'char *'].
	calloutState
		argVector: allocation;
		currentArg: allocation;
		limit: allocation + stackSize.
	(calloutState structReturnSize > 0
	 and: [self nonRegisterStructReturnIsViaImplicitFirstArgument
	 and: [(self returnStructInRegisters: calloutState structReturnSize) not]]) ifTrue:
		[err := self ffiPushPointer: calloutState limit in: calloutState.
		 err ~= 0 ifTrue:
			[self cleanupCalloutState: calloutState.
			 self cppIf: COGMTVM ifTrue:
			 [err = PrimErrObjectMayMove negated ifTrue:
				[^PrimErrObjectMayMove]]. "N.B. Do not fail if object may move because caller will GC and retry."
			 ^self ffiFail: err]].
	1 to: nArgs do:
		[:i|
		argType := interpreterProxy fetchPointer: i ofObject: argTypeArray.
		argSpec := interpreterProxy fetchPointer: 0 ofObject: argType.
		argClass := interpreterProxy fetchPointer: 1 ofObject: argType.
		oop := argArrayOrNil isNil
				ifTrue: [interpreterProxy stackValue: nArgs - i]
				ifFalse: [interpreterProxy fetchPointer: i - 1 ofObject: argArrayOrNil].
		err := self ffiArgument: oop Spec: argSpec Class: argClass in: calloutState.
		err ~= 0 ifTrue:
			[self cleanupCalloutState: calloutState.
			 self cppIf: COGMTVM ifTrue:
			 [err = PrimErrObjectMayMove negated ifTrue:
				[^PrimErrObjectMayMove]]. "N.B. Do not fail if object may move because caller will GC and retry."
			 ^self ffiFail: err]]. "coercion failed or out of stack space"
	"Failures must be reported back from ffiArgument:Spec:Class:in:.
	 Should not fail from here on in."
	self assert: interpreterProxy failed not.
	self ffiLogCallout: externalFunction.
	(requiredStackSize < 0
	 and: [self externalFunctionHasStackSizeSlot]) ifTrue:
		[stackSize := calloutState currentArg - calloutState argVector.
		 interpreterProxy storeInteger: ExternalFunctionStackSizeIndex ofObject: externalFunction withValue: stackSize].
	"Go out and call this guy"
	result := self ffiCalloutTo: address SpecOnStack: argArrayOrNil notNil in: calloutState.
	self cleanupCalloutState: calloutState.
	"Can not safely use argumentCount (via e.g. methodReturnValue:) since it may have been changed by a callback."
	interpreterProxy pop: primNumArgs + 1 thenPush: result. 
	^result
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiCalloutTo: procAddr SpecOnStack: specOnStack in: calloutState [
	<var: #procAddr type: #'void *'>
	<arg: #calloutState type: #'CalloutState *'>
	"Perform the callout, collect the result and and create the return value.
	 If a threaded call, disown and own VM around the call.  If there are floating-point
	 arguments that are passed in registers then call a dummy function to load them.
	 This *must* be inlined because of the alloca of the outgoing stack frame in
	 ffiCall:SpecOnStack:Flags:NumArgs:Args:AndTypes:"
	<inline: true>
	self subclassResponsibility
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiCheckReturn: retSpec With: retClass in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	"Make sure we can return an object of the given type"
	<inline: true>
	retClass = interpreterProxy nilObject ifFalse:
		[(interpreterProxy
				includesBehavior: retClass 
				ThatOf: interpreterProxy classExternalStructure) ifFalse:
			[^FFIErrorBadReturn]].

	((interpreterProxy isWords: retSpec)
	 and: [(interpreterProxy slotSizeOf: retSpec) > 0]) ifFalse:
		[^FFIErrorWrongType].

	calloutState ffiRetHeader: (interpreterProxy fetchLong32: 0 ofObject: retSpec).
	(self isAtomicType: calloutState ffiRetHeader) ifFalse:
		[retClass = interpreterProxy nilObject ifTrue:
			[^FFIErrorBadReturn]].
	(calloutState ffiRetHeader bitAnd: (FFIFlagPointer bitOr: FFIFlagStructure)) = FFIFlagStructure ifTrue:
		[calloutState structReturnSize: (calloutState ffiRetHeader bitAnd: FFIStructSizeMask)].
	^0
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiContentsOfHandle: oop errCode: errCode [
	"Make sure that the given oop is a valid external handle"
	<inline: true>
	((interpreterProxy isBytes: oop)
	 and: [(interpreterProxy byteSizeOf: oop) = (self sizeof: #sqInt)]) ifFalse:
		[^self ffiFail: errCode].
	^interpreterProxy fetchPointer: 0 ofObject: oop
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiCreateIntegralResultOop: retVal ofAtomicType: atomicType in: calloutState [
	<inline: true>
	<var: #calloutState type: #'CalloutState *'>
	<var: #retVal type: #usqLong>
	"Callout support. Return the appropriate oop for the given atomic type"
	| shift value mask byteSize |
	<var: 'value' type: #usqLong>
	<var: 'mask' type: #usqLong>
	self assert: atomicType < FFITypeSingleFloat.

	atomicType = FFITypeBool ifTrue:
		["Make sure bool honors the byte size requested"
		 byteSize := calloutState ffiRetHeader bitAnd: FFIStructSizeMask.
		 value := byteSize = (self sizeof: retVal)
					ifTrue:[retVal]
					ifFalse:[retVal bitAnd: 1 asUnsignedLongLong << (byteSize * 8) - 1].
		 ^value = 0
			ifTrue:[interpreterProxy falseObject]
			ifFalse:[interpreterProxy trueObject]].
	atomicType <= FFITypeSignedInt ifTrue:
		["these are all generall integer returns"
		atomicType <= (BytesPerWord = 8 ifTrue: [FFITypeSignedInt] ifFalse: [FFITypeSignedShort]) ifTrue:
			["byte/short. first extract partial word, then sign extend"
			shift := (BytesPerWord = 8 and: [atomicType >= FFITypeUnsignedInt])
						ifTrue: [32]
						ifFalse: [(atomicType >> 1) * 8]. "# of significant bits"
			value := retVal bitAnd: (1 asUnsignedLongLong << shift - 1). 
			(atomicType anyMask: 1) ifTrue:
				["make the guy signed"
				mask := 1 asUnsignedLongLong << (shift-1).
				value := (value bitAnd: mask-1) - (value bitAnd: mask)].
			^interpreterProxy integerObjectOf: value].
		"Word sized integer return"
		^(atomicType anyMask: 1)
			ifTrue:[interpreterProxy signedMachineIntegerFor: retVal] "signed return"
			ifFalse:[interpreterProxy positiveMachineIntegerFor: retVal]]. "unsigned return"

	"longlong, char"
	^(atomicType >> 1) = (FFITypeSignedLongLong >> 1) 
		ifTrue:
			[(atomicType anyMask: 1)
				ifTrue:[interpreterProxy signed64BitIntegerFor: retVal] "signed return"
				ifFalse:[interpreterProxy positive64BitIntegerFor: retVal]]
		ifFalse:
			[interpreterProxy characterObjectOf: (retVal bitAnd: 16rFF)]
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiFail: reason [
	<inline: false>
	"Map the FFI error code into a primitive error code.  If reason is negative it encodes one of the
	 standard PrimErr... codes, negated to distinguish it from the FFIError codes.  If it is an FFIError...
	 code then add the size of the primitive error table + 2 to disambiguate it from the PrimErr... codes.
	 For historic reasons the FFIError codes range from -1 on up hence adding size + 2 maps them to
	 size of table + 1 on up.  This OFFSET IS undone by ExternalFunction class>>externalCallFailedWith:.
	 Thus we can communicate back both PrimErr.. and FFIError codes.  Complex but necessary."
	ffiLastError := reason.
	^interpreterProxy primitiveFailFor:
		(reason >= FFINoCalloutAvailable
			ifTrue: [reason + 2 + (interpreterProxy slotSizeOf: interpreterProxy primitiveErrorTable)]
			ifFalse: [reason negated])
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiFloatValueOf: oop [
	"Support for generic callout. Return a float value that is coerced as C would do."
	<returnTypeC: #double>
	(interpreterProxy isFloatObject: oop) ifTrue:
		[^interpreterProxy floatValueOf: oop].
	"otherwise try the integer coercions and return its float value"
	^(self ffiIntegerValueOf: oop) asFloat
]

{ #category : #'primitive support' }
ThreadedFFIPlugin >> ffiFree: pointer [
	"Default to malloc/free.  If a platform needs a different allocator define
	 something in the preamble and redefine this to take account of that."
	<cmacro: '(pointer) free((void *)(pointer))'>
	^self
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiIntegerValueOf: oop [
	"Support for generic callout. Answer an integer value that is coerced as C would do."
	<inline: true>
	"Cheat with a tag test"
	(oop anyMask: BytesPerWord - 1)
		ifTrue:
			[(interpreterProxy isIntegerObject: oop) ifTrue:
				[^interpreterProxy integerValueOf: oop].
			self cppIf: SPURVM
				ifTrue:
					[(interpreterProxy isCharacterObject: oop) ifTrue: "Immediate in Spur"
						[^interpreterProxy characterValueOf: oop].
					 (interpreterProxy isFloatObject: oop) ifTrue: "Immediate in 64-bit Spur"
						[^interpreterProxy floatValueOf: oop]]]
		ifFalse:
			[self cppIf: SPURVM
				ifTrue: "No non-immediate characters in Spur"
					[]
				ifFalse:
					[(interpreterProxy isCharacterObject: oop) ifTrue:
						[^interpreterProxy characterValueOf: oop]].
			 (interpreterProxy isFloatObject: oop) ifTrue:
				[^interpreterProxy floatValueOf: oop].
			 oop = interpreterProxy nilObject ifTrue: [^0]. "@@: should we really allow this????"
			 oop = interpreterProxy falseObject ifTrue: [^0].
			 oop = interpreterProxy trueObject ifTrue: [^1].
			 (interpreterProxy isLargePositiveIntegerObject: oop) ifTrue:
				[self cppIf: BytesPerWord = 8 "Use cppIf: to get the return type of the function right.  Should be sqInt on 32-bits."
					ifTrue: [^interpreterProxy positive64BitValueOf: oop]
					ifFalse: [^interpreterProxy positive32BitValueOf: oop]]].
	^interpreterProxy signedMachineIntegerValueOf: oop "<- will fail if not integer"
]

{ #category : #'symbol loading' }
ThreadedFFIPlugin >> ffiLoadCalloutAddress: lit [
	"Load the address of the foreign function from the given object"
	| addressPtr address ptr |
	<var: #ptr type: #'sqIntptr_t *'>
	"Lookup the address"
	addressPtr := interpreterProxy fetchPointer: 0 ofObject: lit.
	"Make sure it's an external handle"
	address := self ffiContentsOfHandle: addressPtr errCode: FFIErrorBadAddress.
	interpreterProxy failed ifTrue:
		[^0].
	address = 0 ifTrue:"Go look it up in the module"
		[self externalFunctionHasStackSizeSlot ifTrue:
			[interpreterProxy
				storePointer: ExternalFunctionStackSizeIndex
				ofObject: lit
				withValue: (interpreterProxy integerObjectOf: -1)].
		(interpreterProxy slotSizeOf: lit) < 5 ifTrue:
			[^self ffiFail: FFIErrorNoModule].
		address := self ffiLoadCalloutAddressFrom: lit.
		interpreterProxy failed ifTrue:
			[^0].
		"Store back the address"
		ptr := interpreterProxy firstIndexableField: addressPtr.
		ptr at: 0 put: address].
	^address
]

{ #category : #'symbol loading' }
ThreadedFFIPlugin >> ffiLoadCalloutAddressFrom: oop [
	"Load the function address for a call out to an external function"
	| module moduleHandle functionName address |
	<inline: false>
	"First find and load the module"
	module := interpreterProxy fetchPointer: externalFunctionInstSize + 1 ofObject: oop.
	moduleHandle := self ffiLoadCalloutModule: module.
	interpreterProxy failed ifTrue:
		[^0]. "failed"
	"fetch the function name"
	functionName := interpreterProxy fetchPointer: externalFunctionInstSize ofObject: oop.
	(interpreterProxy isBytes: functionName) ifFalse:
		[^self ffiFail: FFIErrorBadExternalFunction].
	address := (interpreterProxy
					ioLoadSymbol: (interpreterProxy firstIndexableField: functionName) asInteger
					OfLength: (interpreterProxy byteSizeOf: functionName) 
					FromModule: moduleHandle) asInteger.
	(interpreterProxy failed or: [address = 0]) ifTrue:
		[^self ffiFail: FFIErrorAddressNotFound].
	^address
]

{ #category : #'symbol loading' }
ThreadedFFIPlugin >> ffiLoadCalloutModule: module [
	"Load the given module and return its handle"
	| moduleHandlePtr moduleHandle ffiModuleName moduleLength rcvr ptr |
	<var: #ptr type:'sqInt *'>
	(interpreterProxy isBytes: module) ifTrue:[
		"plain module name"
		ffiModuleName := module.
		moduleLength := interpreterProxy byteSizeOf: ffiModuleName.
		moduleHandle := (interpreterProxy
							ioLoadModule: (interpreterProxy firstIndexableField: ffiModuleName) asInteger
							OfLength: moduleLength) asInteger.
		(interpreterProxy failed
		 or: [moduleHandle = 0]) ifTrue:
			[^self ffiFail: FFIErrorModuleNotFound]. "failed"
		^moduleHandle].
	"Check if the external method is defined in an external library"
	rcvr := interpreterProxy stackValue: interpreterProxy methodArgumentCount.
	(interpreterProxy is: rcvr KindOfClass: interpreterProxy classExternalLibrary) ifFalse:
		[^self ffiFail: FFIErrorNoModule].
	"external library"
	moduleHandlePtr := interpreterProxy fetchPointer: 0 ofObject: rcvr.
	moduleHandle := self ffiContentsOfHandle: moduleHandlePtr errCode: FFIErrorBadExternalLibrary.
	interpreterProxy failed ifTrue:[^0].
	moduleHandle = 0 ifTrue:["need to reload module"
		ffiModuleName := interpreterProxy fetchPointer: 1 ofObject: rcvr.
		(interpreterProxy isBytes: ffiModuleName) ifFalse:[^self ffiFail: FFIErrorBadExternalLibrary].
		moduleLength := interpreterProxy byteSizeOf: ffiModuleName.
		moduleHandle := (interpreterProxy
								ioLoadModule: (interpreterProxy firstIndexableField: ffiModuleName) asInteger
								OfLength: moduleLength) asInteger.
		(interpreterProxy failed
		 or: [moduleHandle = 0]) ifTrue:
			[^self ffiFail: FFIErrorModuleNotFound]. "failed"
		"and store back"
		ptr := interpreterProxy firstIndexableField: moduleHandlePtr.
		ptr at: 0 put: moduleHandle].
	^moduleHandle
]

{ #category : #'symbol loading' }
ThreadedFFIPlugin >> ffiLogCallout: lit [
	<returnTypeC: #void>
	"fetch the function name"
	| functionName |
	ffiLogEnabled ifTrue:[
		functionName := interpreterProxy fetchPointer: externalFunctionInstSize ofObject: lit.
		(interpreterProxy isBytes: functionName) ifFalse:[^nil].
		self ffiLogCall: (interpreterProxy firstIndexableField: functionName)
			OfLength: (interpreterProxy byteSizeOf: functionName).
	].
]

{ #category : #initialize }
ThreadedFFIPlugin >> ffiLogCallsTo: fileName [
	"This is a special entry point exposed such that client code can 
	enable and disable logging of FFI calls."
	| ok |
	<export: true>
	<var: #fileName type: 'char*'>
	fileName == nil ifTrue:[ "disable logging"
		ok := self ffiLogFileName: nil OfLength: 0.
		ok ifFalse:[^false].
		ffiLogEnabled := false.
	] ifFalse:[ "enable logging"
		ok := self ffiLogFileName: fileName OfLength: (self strlen: fileName).
		ok ifFalse:[^false].
		ffiLogEnabled := true.
	].
	^true
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushDoubleFloat: value in: calloutState [
	<var: #calloutState type: #double>
	<var: #calloutState type: #'CalloutState *'>
	^self subclassResponsibility
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushPointer: pointer in: calloutState [
	<var: #pointer type: #'void *'>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self subclassResponsibility
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushPointerContentsOf: oop in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	"Push the contents of the given external structure"
	| ptrClass ptrAddress |
	<inline: false>
	ptrClass := interpreterProxy fetchClassOf: oop.
	ptrClass = interpreterProxy classExternalAddress ifTrue:
		[ptrAddress := (interpreterProxy fetchPointer: 0 ofObject: oop) asVoidPointer.
		"Don't you dare to pass pointers into object memory"
		(interpreterProxy isInMemory: ptrAddress) ifTrue:
			[^FFIErrorInvalidPointer].
		^self ffiPushPointer: ptrAddress in: calloutState].

	ptrClass = interpreterProxy classByteArray ifTrue:
		["Since this involves passing the address of the first indexable field we need to fail
		  the call if it is threaded and the object is young, since it may move during the call."
		 self cppIf: COGMTVM ifTrue:
		 [((calloutState callFlags anyMask: FFICallFlagThreaded)
		   and: [interpreterProxy isYoung: oop]) ifTrue:
			[^PrimErrObjectMayMove negated]].

		ptrAddress := interpreterProxy firstIndexableField: oop.
		^self ffiPushPointer: ptrAddress in: calloutState].

	(interpreterProxy includesBehavior: ptrClass ThatOf: interpreterProxy classAlien) ifTrue:
		[self cppIf: COGMTVM ifTrue:
		 [((calloutState callFlags anyMask: FFICallFlagThreaded)
		   and: [(self isDirectAlien: oop)
		   and: [interpreterProxy isYoung: oop]]) ifTrue:
			[^PrimErrObjectMayMove negated]].

		ptrAddress := self startOfData: oop.
		^self ffiPushPointer: ptrAddress in: calloutState].

	^FFIErrorBadArg
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushSignedByte: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self subclassResponsibility
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushSignedChar: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self subclassResponsibility
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushSignedInt: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self subclassResponsibility
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushSignedLongLong: value in: calloutState [
	<var: #value type: #sqLong>
	<var: #calloutState type: #'CalloutState *'>
	^self subclassResponsibility
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiPushSignedLongLongOop: oop in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	"Push a longlong type (e.g., a 64bit integer).
	Note: Coercions from float are *not* supported."
	| value |
	<var: #value type: #sqLong>
	(oop = interpreterProxy nilObject
	 or: [oop = interpreterProxy falseObject])
		ifTrue:[value := 0] ifFalse:
	[oop = interpreterProxy trueObject
		ifTrue:[value := 1] ifFalse:
	[value := interpreterProxy signed64BitValueOf: oop.
	 interpreterProxy failed ifTrue:
		[^FFIErrorCoercionFailed]]].
	^self ffiPushSignedLongLong: value in: calloutState
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushSignedShort: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self subclassResponsibility
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushSingleFloat: value in: calloutState [
	<var: #value type: #float>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self subclassResponsibility
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushString: pointer OfLength: length in: calloutState [
	<var: #pointer type: #'char *'>
	<var: #calloutState type: #'CalloutState *'>
	| copy |
	<var: #copy type: #'char *'>
	<inline: true>
	calloutState stringArgIndex >= MaxNumArgs ifTrue:
		[^PrimErrBadNumArgs negated].
	copy := self malloc: length + 1.
	copy isNil ifTrue:
		[^PrimErrNoCMemory negated].
	self memcpy: copy _: pointer _: length.
	copy at: length put: 0.
	calloutState stringArgs at: calloutState stringArgIndex put: copy.
	calloutState stringArgIndex: calloutState stringArgIndex + 1.
	^self ffiPushPointer: copy in: calloutState
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushStructure: pointer ofSize: structSize typeSpec: argSpec ofLength: argSpecSize in: calloutState [
	<var: #pointer type: #'void *'>
	<var: #argSpec type: #'sqInt *'>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self subclassResponsibility
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiPushStructureContentsOf: oop in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	"Push the contents of the given external structure"
	| ptrClass ptrAddress |
	<inline: true>
	ptrClass := interpreterProxy fetchClassOf: oop.
	ptrClass = interpreterProxy classExternalAddress ifTrue: "ExternalAddress is bytes"
		[ptrAddress := (interpreterProxy fetchPointer: 0 ofObject: oop) asVoidPointer.
		"There is no way we can make sure the structure is valid.
		But we can at least check for attempts to pass pointers to ST memory."
		(interpreterProxy isInMemory: ptrAddress) ifTrue:
			[^FFIErrorInvalidPointer].
		^self ffiPushStructure: ptrAddress
			ofSize: (calloutState ffiArgHeader bitAnd: FFIStructSizeMask)
			typeSpec: calloutState ffiArgSpec
			ofLength: calloutState ffiArgSpecSize
			in: calloutState].
	ptrClass = interpreterProxy classByteArray ifTrue:
		["The following is a somewhat pessimistic test but I like being sure..."
		(interpreterProxy byteSizeOf: oop) = (calloutState ffiArgHeader bitAnd: FFIStructSizeMask)
			ifFalse:[^FFIErrorStructSize].
		ptrAddress := interpreterProxy firstIndexableField: oop.
		(calloutState ffiArgHeader anyMask: FFIFlagPointer) ifFalse:
			"Since this involves passing the address of the first indexable field we need to fail
			  the call if it is threaded and the object is young, since it may move during the call."
			[self cppIf: COGMTVM ifTrue:
			 [((calloutState callFlags anyMask: FFICallFlagThreaded)
			 and: [interpreterProxy isYoung: oop]) ifTrue:
				[^PrimErrObjectMayMove negated]].
			^self ffiPushStructure: ptrAddress
				ofSize: (calloutState ffiArgHeader bitAnd: FFIStructSizeMask)
				typeSpec: calloutState ffiArgSpec
				ofLength: calloutState ffiArgSpecSize
				in: calloutState].
		"If FFIFlagPointer + FFIFlagStructure is set use ffiPushPointer on the contents"
		(calloutState ffiArgHeader bitAnd: FFIStructSizeMask) = BytesPerWord ifFalse:
			[^FFIErrorStructSize].
		ptrAddress := (interpreterProxy fetchPointer: 0 ofObject: oop) asVoidPointer.
		(interpreterProxy isInMemory: ptrAddress) ifTrue:
			[^FFIErrorInvalidPointer].
		^self ffiPushPointer: ptrAddress in: calloutState].
	^FFIErrorBadArg
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushUnsignedByte: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self subclassResponsibility
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushUnsignedChar: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self subclassResponsibility
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushUnsignedInt: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self subclassResponsibility
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushUnsignedLongLong: value in: calloutState [
	<var: #value type: #usqLong>
	^self subclassResponsibility
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiPushUnsignedLongLongOop: oop in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	"Push an unsigned longlong type (e.g., a 64bit integer).
	Note: Coercions from float are *not* supported."
	| value |
	<var: #value type: #usqLong>
	(oop = interpreterProxy nilObject
	 or: [oop = interpreterProxy falseObject])
		ifTrue:[value := 0] ifFalse:
	[oop = interpreterProxy trueObject
		ifTrue:[value := 1] ifFalse:
	[value := interpreterProxy positive64BitValueOf: oop.
	 interpreterProxy failed ifTrue:
		[^FFIErrorCoercionFailed]]].
	^self ffiPushUnsignedLongLong: value in: calloutState
]

{ #category : #marshalling }
ThreadedFFIPlugin >> ffiPushUnsignedShort: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self subclassResponsibility
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiPushVoid: ignored in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	"This is a fallback in case somebody tries to pass a 'void' value.
	We could simply ignore the argument but I think it's better to let
	the caller know what he did"
	^FFIErrorAttemptToPassVoid
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiReturnCStringFrom: cPointer [
	"Create a Smalltalk string from a zero terminated C string"
	| strLen strOop cString strPtr |
	<var: #cString type: #'char *'>
	<var: #strPtr type: #'char *'>
	cPointer ifNil: [^interpreterProxy nilObject]. "nil always returns as nil"
	cString := self cCoerce: cPointer to: #'char *'.
	strLen := 0.
	[(cString at: strLen) = 0] whileFalse:[strLen := strLen+1].
	strOop := interpreterProxy 
				instantiateClass: interpreterProxy classString 
				indexableSize: strLen.
	strPtr := interpreterProxy firstIndexableField: strOop.
	0 to: strLen-1 do: [:i| strPtr at: i put: (cString at: i)].
	^strOop
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiReturnPointer: retVal ofType: retType in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<var: #retVal type: #usqLong>
	"Generic callout support. Create a pointer return value from an external function call"
	| retClass atomicType retOop oop ptr classOop |
	<var: #ptr type: #'sqInt *'>
	retClass := interpreterProxy fetchPointer: 1 ofObject: retType.
	retClass = interpreterProxy nilObject ifTrue:
		["Create ExternalData upon return"
		atomicType := self atomicTypeOf: calloutState ffiRetHeader.
		(atomicType >> 1) = (FFITypeSignedChar >> 1) ifTrue: "String return"
			[retOop := self ffiReturnCStringFrom: (self cCoerceSimple: retVal to: #usqInt).
			 ^retOop].
		"generate external data"
		self remapOop: retType in:
			[oop := interpreterProxy
						instantiateClass: interpreterProxy classExternalAddress 
						indexableSize: BytesPerWord.
			ptr := interpreterProxy firstIndexableField: oop.
			ptr at: 0 put: (self cCoerceSimple: retVal to: #sqInt).
			self remapOop: oop in:
				[retOop := interpreterProxy 
								instantiateClass: interpreterProxy classExternalData 
								indexableSize: 0].
			interpreterProxy storePointer: 0 ofObject: retOop withValue: oop].
		interpreterProxy storePointer: 1 ofObject: retOop withValue: retType.
		^retOop].
	"non-atomic pointer return"
	classOop := (calloutState ffiRetHeader anyMask: FFIFlagStructure)
					ifTrue:[interpreterProxy classByteArray]
					ifFalse:[interpreterProxy classExternalAddress].
	self remapOop: retClass in:
		[oop := interpreterProxy 
					instantiateClass: classOop
					indexableSize: BytesPerWord].
	ptr := interpreterProxy firstIndexableField: oop.
	ptr at: 0 put: (self cCoerceSimple: retVal to: #sqInt).
	self remapOop: oop in:
		[retOop := interpreterProxy instantiateClass: retClass indexableSize: 0].
	interpreterProxy storePointer: 0 ofObject: retOop withValue: oop.
	^retOop
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiReturnStruct: longLongRet ofType: ffiRetClass in: calloutState [
	<var: #longLongRet type: #usqLong>
	<var: #calloutState type: #'CalloutState *'>
	"Create a structure return value from an external function call.  The value as been stored in
	 alloca'ed space pointed to by the calloutState."
	<inline: true>
	self subclassResponsibility
]

{ #category : #'symbol loading' }
ThreadedFFIPlugin >> ffiReturnType: specOnStack [
	"Answer the return type object for the current invocation"
	| specLiteral argTypes |
	specLiteral := specOnStack
					ifTrue: [interpreterProxy stackValue: 1]
					ifFalse: [interpreterProxy literal: 0 ofMethod: interpreterProxy primitiveMethod].
	argTypes := interpreterProxy fetchPointer: ExternalFunctionArgTypesIndex ofObject: specLiteral.
	^interpreterProxy fetchPointer: 0 ofObject: argTypes
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiSupportsCallingConvention: aCallingConvention [
	"Check that the calling convention is valid.  This test also filters out attempts
	 to do a threaded call in the non-threaded VM/plugin combinatioin."

	<inline: true>
	^aCallingConvention = FFICallTypeCDecl or: [aCallingConvention = FFICallTypeApi]
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> ffiValidateExternalData: oop AtomicType: atomicType [
	"Validate if the given oop (an instance of ExternalData) can be passed as a pointer to the given atomic type."
	| ptrType specOop spec specType |
	<inline: true>
	ptrType := interpreterProxy fetchPointer: 1 ofObject: oop.
	((interpreterProxy isPointers: ptrType)
	and: [(interpreterProxy slotSizeOf: ptrType) >= 2]) ifFalse:
		[^FFIErrorWrongType].
	specOop := interpreterProxy fetchPointer: 0 ofObject: ptrType.
	((interpreterProxy isWords: specOop)
	and: [(interpreterProxy slotSizeOf: specOop) > 0]) ifFalse:
		[^FFIErrorWrongType].
	spec := interpreterProxy fetchPointer: 0 ofObject: specOop.
	(self isAtomicType: spec) ifFalse:
		[^FFIErrorWrongType].
	specType := self atomicTypeOf: spec.
	specType ~= atomicType ifTrue:
		"Allow for signed/unsigned conversion but nothing else.
		 See FFIConstants class>>#initializeTypeConstants"
		[(atomicType >= FFITypeUnsignedByte
		  and: [atomicType <= FFITypeSignedChar
		  and: [(atomicType >> 1) = (specType >> 1)]]) ifFalse:
			[^FFIErrorCoercionFailed]].
	^0
]

{ #category : #initialize }
ThreadedFFIPlugin >> getModuleName [
	"Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important!"
	<returnTypeC: 'const char *'>
	<export: true>
	^'SqueakFFIPrims'
]

{ #category : #simulation }
ThreadedFFIPlugin >> initSurfacePluginFunctionPointers [
	"This is a simulation-only stub.  The real code is in
		platforms/Cross/plugins/SqueakFFIPrims/sqManualSurface.c"
	<doNotGenerate>
]

{ #category : #initialize }
ThreadedFFIPlugin >> initialiseModule [
	<export: true>
	ffiLastError := 0.
	"By default, disable logging"
	ffiLogEnabled := false.
	"Get the instSize of ExternalFunction to know whether it contains a cache of the stackSize,
	 and what the offset of ExternalLibraryFunction's functionName and moduleName slots are."
	externalFunctionInstSize := interpreterProxy instanceSizeOf: interpreterProxy classExternalFunction.
	self initSurfacePluginFunctionPointers.
	^true
]

{ #category : #'primitive support' }
ThreadedFFIPlugin >> isAlien: anOop [
	^interpreterProxy
		includesBehavior: (interpreterProxy fetchClassOf: anOop)
		ThatOf: interpreterProxy classAlien
]

{ #category : #'primitive support' }
ThreadedFFIPlugin >> isAtomicType: typeSpec [
	^typeSpec anyMask: FFIFlagAtomic
]

{ #category : #'callout support' }
ThreadedFFIPlugin >> isCalleePopsConvention: callType [
	<cmacro: '(callType) (PLATFORM_API_USES_CALLEE_POPS_CONVENTION && (callType) == FFICallTypeApi)'>
	^callType == FFICallTypeApi
]

{ #category : #'primitive support' }
ThreadedFFIPlugin >> isDirectAlien: oop [
	self assert: (self isAlien: oop).
	^(self sizeField: oop) > 0
]

{ #category : #simulation }
ThreadedFFIPlugin >> morphIntoConcreteSubclass: aCoInterpreter [
	<doNotGenerate>
	| concreteClass |
	concreteClass :=
		aCoInterpreter ISA caseOf: {
			[ #X64 ]		->	[(Smalltalk platformName beginsWith: 'Win')
								ifTrue: [ThreadedX64Win64FFIPlugin]
								ifFalse: [ThreadedX64SysVFFIPlugin]].
			[ #IA32 ]		->	[ThreadedIA32FFIPlugin].
			[ #ARMv5 ]	->	[ThreadedARM32FFIPlugin].
			[ #aarch64 ] -> [ ThreadedARM64FFIPlugin ]
	} otherwise: [self error: 'simulation not set up for this ISA'].
	"If the concreteClass has an initialize method, other than ThreadedFFIPlugin class>>initialize
	 then it needs to be run."
	((concreteClass class whichClassIncludesSelector: #initialize) inheritsFrom: self class class) ifTrue:
		[concreteClass initialize].
	concreteClass adoptInstance: self
]

{ #category : #debugging }
ThreadedFFIPlugin >> msg: s [
	<var: #s type: 'char *'>
	self cCode: 'fprintf(stderr, "\n%s: %s", getModuleName(), s)'
		inSmalltalk: [super msg: s].
	^0
]

{ #category : #marshalling }
ThreadedFFIPlugin >> mustAlignStack [
	"Many ABIs mandate a particular stack alignment greater than the natural word size.
	 If so, this macro will answer true.  See platforms/Cross/vm/sqCogStackAlignment.h
	 and class-side preambleCCode."
	<cmacro: '() MUST_ALIGN_STACK'>
	^false
]

{ #category : #marshalling }
ThreadedFFIPlugin >> nonRegisterStructReturnIsViaImplicitFirstArgument [
	"Answer if a struct returned in memory is returned to the
	 referent of a pointer passed as an implciit first argument.
	 It almost always is.  Subclasses can override if not."
	^true
]

{ #category : #primitives }
ThreadedFFIPlugin >> primitiveCallout [
	"IMPORTANT: IF YOU CHANGE THE NAME OF THIS METHOD YOU MUST CHANGE
		Interpreter>>primitiveCalloutToFFI
	TO REFLECT THE CHANGE."

	"Perform a function call to a foreign function.
	Only invoked from method containing explicit external call spec."
 
	<returnTypeC: #void>
	<export: true>
	| meth externalFunction |
	meth := interpreterProxy primitiveMethod.
	(interpreterProxy literalCountOf: meth) > 0 ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadMethod].
	externalFunction := interpreterProxy literal: 0 ofMethod: meth.
	self cppIf: COGMTVM
		ifTrue:
			[ | nArgs retryCount result |
			nArgs := interpreterProxy methodArgumentCount.
			retryCount := 0.
			[result := self ffiCall: externalFunction ArgArrayOrNil: nil NumArgs: nArgs.
			 result = PrimErrObjectMayMove
			 and: [(retryCount := retryCount + 1) <= (nArgs + 1)]] whileTrue:
				[interpreterProxy tenuringIncrementalGC]]
		ifFalse:
			[self ffiCall: externalFunction ArgArrayOrNil: nil NumArgs: interpreterProxy methodArgumentCount].
	^0
]

{ #category : #primitives }
ThreadedFFIPlugin >> primitiveCalloutWithArgs [
	"Perform a function call to a foreign function.
	 Only invoked from ExternalFunction>>invokeWithArguments:"

	<returnTypeC: #void>
	<export: true>
	| externalFunction argArray nArgs |
	interpreterProxy methodArgumentCount = 1 ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	self cppIf: COGMTVM
		ifTrue:
			[| retryCount result |
			retryCount := 0.
			[externalFunction := interpreterProxy stackValue: 1.
			 argArray := interpreterProxy stackValue: 0.
			 (interpreterProxy isArray: argArray) ifFalse:
				[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
			 nArgs := interpreterProxy slotSizeOf: argArray.
			 result := self ffiCall: externalFunction ArgArrayOrNil: argArray NumArgs: nArgs.
			 result = PrimErrObjectMayMove
			  and: [(retryCount := retryCount + 1) <= (nArgs + 1)]] whileTrue:
				[interpreterProxy tenuringIncrementalGC]]
		ifFalse:
			[externalFunction := interpreterProxy stackValue: 1.
			argArray := interpreterProxy stackValue: 0.
			(interpreterProxy isArray: argArray) ifFalse:
				[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
			nArgs := interpreterProxy slotSizeOf: argArray.
			self ffiCall: externalFunction ArgArrayOrNil: argArray NumArgs: nArgs].
	^0
]

{ #category : #'primitives - surfaces' }
ThreadedFFIPlugin >> primitiveCreateManualSurface [
	"arguments: name(type, stack offset)
		width(Integer, 4)
		height(Integer, 3)
		rowPitch(Integer, 2)
		depth(Integer, 1)
		isMSB(Boolean, 0)"
	| width height rowPitch depth isMSB result |
	<export: true>
	
	interpreterProxy methodArgumentCount = 5 ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	width := interpreterProxy stackIntegerValue: 4.
	height := interpreterProxy stackIntegerValue: 3.
	rowPitch := interpreterProxy stackIntegerValue: 2.
	depth := interpreterProxy stackIntegerValue: 1.
	isMSB := interpreterProxy stackObjectValue: 0.
	isMSB := interpreterProxy booleanValueOf: isMSB. 
	interpreterProxy failed ifTrue: [^nil].
	
	result := self cCode: 'createManualSurface(width, height, rowPitch, depth, isMSB)'
				inSmalltalk: [self create: width Man: height ual: rowPitch Surf: depth ace: isMSB].
	result < 0 ifTrue:
		[^interpreterProxy primitiveFail].
	result := interpreterProxy signed32BitIntegerFor: result.
	^interpreterProxy pop: 6 thenPush: result
	
]

{ #category : #'primitives - surfaces' }
ThreadedFFIPlugin >> primitiveDestroyManualSurface [
	| surfaceID |
	<export: true>
	interpreterProxy methodArgumentCount = 1 ifFalse:
		[^interpreterProxy primitiveFail].
	surfaceID := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifFalse:
		[(self destroyManualSurface: surfaceID) = 0
			ifTrue: [interpreterProxy primitiveFail]
			ifFalse: [interpreterProxy pop: 1]]
]

{ #category : #primitives }
ThreadedFFIPlugin >> primitiveFFIAllocate [
	"Primitive. Allocate an object on the external heap."
	| byteSize addr oop ptr |
	<export: true>
	<inline: false>
	<var: #ptr type: #'sqIntptr_t *'>
	byteSize := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:
		[^nil].
	addr := self ffiAlloc: byteSize.
	addr = 0 ifTrue:
		[^interpreterProxy primitiveFail].
	oop := interpreterProxy 
			instantiateClass: interpreterProxy classExternalAddress 
			indexableSize: (self sizeof: #'sqIntptr_t').
	ptr := interpreterProxy firstIndexableField: oop.
	ptr at: 0 put: addr.
	^interpreterProxy pop: 2 thenPush: oop
]

{ #category : #primitives }
ThreadedFFIPlugin >> primitiveFFIDoubleAt [
	"Return a (signed or unsigned) n byte integer from the given byte offset."
	| byteOffset rcvr addr floatValue |
	<export: true>
	<inline: false>
	<var: #floatValue type: #double>
	byteOffset := interpreterProxy stackIntegerValue: 0.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^0].
	addr := self ffiAddressOf: rcvr startingAt: byteOffset size: 8.
	addr = 0 ifTrue: [^interpreterProxy primitiveFail].
	self memcpy: (self addressOf: floatValue) _: addr _: (self sizeof: floatValue).
	interpreterProxy pop: 2.
	^interpreterProxy pushFloat: floatValue

]

{ #category : #primitives }
ThreadedFFIPlugin >> primitiveFFIDoubleAtPut [
	"Return a (signed or unsigned) n byte integer from the given byte offset."
	| byteOffset rcvr addr floatValue floatOop |
	<export: true>
	<inline: false>
	<var: #floatValue type: #double>
	floatOop := interpreterProxy stackValue: 0.
	(interpreterProxy isIntegerObject: floatOop)
		ifTrue:[floatValue := self cCoerce: (interpreterProxy integerValueOf: floatOop) to:'double']
		ifFalse:[floatValue := self cCoerce: (interpreterProxy floatValueOf: floatOop) to:'double'].
	byteOffset := interpreterProxy stackIntegerValue: 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:[^0].
	addr := self ffiAddressOf: rcvr startingAt: byteOffset size: 8.
	addr = 0 ifTrue: [^interpreterProxy primitiveFail].
	self memcpy: addr _: (self addressOf: floatValue) _: (self sizeof: floatValue).
	^interpreterProxy pop: 3 thenPush: floatOop
]

{ #category : #primitives }
ThreadedFFIPlugin >> primitiveFFIFloatAt [
	"Return a (signed or unsigned) n byte integer from the given byte offset."
	| byteOffset rcvr addr floatValue |
	<export: true>
	<inline: false>
	<var: #floatValue type: #float>
	byteOffset := interpreterProxy stackIntegerValue: 0.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^0].
	addr := self ffiAddressOf: rcvr startingAt: byteOffset size: 4.
	addr = 0 ifTrue: [^interpreterProxy primitiveFail].
	self memcpy: (self addressOf: floatValue) _: addr _: (self sizeof: floatValue).
	interpreterProxy pop: 2.
	^interpreterProxy pushFloat: floatValue
]

{ #category : #primitives }
ThreadedFFIPlugin >> primitiveFFIFloatAtPut [
	"Return a (signed or unsigned) n byte integer from the given byte offset."
	| byteOffset rcvr addr floatValue floatOop |
	<export: true>
	<inline: false>
	<var: #floatValue type: #float>
	floatOop := interpreterProxy stackValue: 0.
	(interpreterProxy isIntegerObject: floatOop)
		ifTrue:[floatValue := self cCoerce: (interpreterProxy integerValueOf: floatOop) to:'float']
		ifFalse:[floatValue := self cCoerce: (interpreterProxy floatValueOf: floatOop) to:'float'].
	byteOffset := interpreterProxy stackIntegerValue: 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:[^0].
	addr := self ffiAddressOf: rcvr startingAt: byteOffset size: 4.
	addr = 0 ifTrue: [^interpreterProxy primitiveFail].
	self memcpy: addr _: (self addressOf: floatValue) _: (self sizeof: floatValue).
	^interpreterProxy pop: 3 thenPush: floatOop
]

{ #category : #primitives }
ThreadedFFIPlugin >> primitiveFFIFree [
	"Primitive. Free the object pointed to on the external heap."
	| addr oop ptr |
	<export: true>
	<inline: false>
	<var: #ptr type: #'sqIntptr_t *'>
	oop := interpreterProxy stackObjectValue: 0.
	((interpreterProxy fetchClassOf: oop) = interpreterProxy classExternalAddress
	 and: [(interpreterProxy byteSizeOf: oop) = (self sizeof: #'sqIntptr_t')]) ifFalse:
		[^interpreterProxy primitiveFail].
	ptr := interpreterProxy firstIndexableField: oop.
	addr := ptr at: 0.
	"Don't you dare to free Squeak's memory!"
	(addr = 0
	 or: [(addr asUnsignedIntegerPtr bitAnd: (self sizeof: #'sqIntptr_t') - 1) ~= 0
	 or: [interpreterProxy isInMemory: addr]]) ifTrue:
		[^interpreterProxy primitiveFail].
	self ffiFree: addr.
	^ptr at: 0 put: 0 "cleanup"
]

{ #category : #primitives }
ThreadedFFIPlugin >> primitiveFFIGetLastError [
	"Primitive. Return the error code from a failed call to the foreign function interface.
	 This is for backwards-compatibility.  Thread-safe access to the error code is via the
	 primitive error code."
	<export: true>
	<inline: false>
	interpreterProxy methodReturnInteger: ffiLastError
]

{ #category : #primitives }
ThreadedFFIPlugin >> primitiveFFIIntegerAt [
	"Answer a (signed or unsigned) n byte integer from the given byte offset
	 in the receiver, using the platform's endianness."
	| isSigned byteSize byteOffset rcvr addr value mask valueOop |
	<var: 'value' type: #usqLong>
	<var: 'mask' type: #usqLong>
	<export: true>
	<inline: false>
	isSigned := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 0).
	byteSize := interpreterProxy stackIntegerValue: 1.
	byteOffset := interpreterProxy stackIntegerValue: 2.
	rcvr := interpreterProxy stackObjectValue: 3.
	interpreterProxy failed ifTrue:[^0].
	(byteOffset > 0
	 and: [(byteSize between: 1 and: 8)
	 and: [(byteSize bitAnd: byteSize - 1) = 0 "a.k.a. isPowerOfTwo"]]) ifFalse:
		[^interpreterProxy primitiveFail].
	addr := self ffiAddressOf: rcvr startingAt: byteOffset size: byteSize.
	addr = 0 ifTrue: [^interpreterProxy primitiveFail].
	byteSize <= 2
		ifTrue:
			[byteSize = 1
				ifTrue: [value := self cCoerceSimple: (interpreterProxy byteAt: addr) to: #'unsigned char']
				ifFalse: [value := self cCoerceSimple: (interpreterProxy unalignedShortAt: addr) to: #'unsigned short']]
		ifFalse:
			[byteSize = 4
				ifTrue: [value := self cCoerceSimple: (interpreterProxy unalignedLong32At: addr) to: #'unsigned int']
				ifFalse: [value := interpreterProxy unalignedLong64At: addr]].
	byteSize < BytesPerWord
		ifTrue:
			[isSigned ifTrue: "sign extend value"
				[mask := 1 asUnsignedLongLong << (byteSize * 8 - 1).
				value := (value bitAnd: mask-1) - (value bitAnd: mask)].
			 "note: byte/short (&long if BytesPerWord=8) never exceed SmallInteger range"
			 valueOop := interpreterProxy integerObjectOf: value]
		ifFalse: "general 64 bit integer; note these never fail"
			[isSigned
				ifTrue:
					[byteSize < 8 ifTrue: "sign extend value"
						[mask := 1 asUnsignedLongLong << (byteSize * 8 - 1).
						value := (value bitAnd: mask-1) - (value bitAnd: mask)].
					 self cCode: [] inSmalltalk:
						[(byteSize = 8 and: [(value bitShift: -56) >= 128]) ifTrue:
							[value := value - (1 bitShift: 64)]].
					 valueOop := interpreterProxy signed64BitIntegerFor: value]
				ifFalse:[valueOop := interpreterProxy positive64BitIntegerFor: value]].
	^interpreterProxy pop: 4 thenPush: valueOop
]

{ #category : #primitives }
ThreadedFFIPlugin >> primitiveFFIIntegerAtPut [
	"Store a (signed or unsigned) n byte integer at the given byte offset
	 in the receiver, using the platform's endianness."
	| isSigned byteSize byteOffset rcvr addr value max valueOop |
	<var: 'value' type: #sqLong>
	<var: 'max' type: #sqLong>
	<export: true>
	<inline: false>
	isSigned := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 0).
	byteSize := interpreterProxy stackIntegerValue: 1.
	valueOop := interpreterProxy stackValue: 2.
	byteOffset := interpreterProxy stackIntegerValue: 3.
	rcvr := interpreterProxy stackObjectValue: 4.
	interpreterProxy failed ifTrue:[^0].
	(byteOffset > 0
	 and: [(byteSize between: 1 and: 8)
	 and: [(byteSize bitAnd: byteSize - 1) = 0 "a.k.a. isPowerOfTwo"]]) ifFalse:
		[^interpreterProxy primitiveFail].
	addr := self ffiAddressOf: rcvr startingAt: byteOffset size: byteSize.
	addr = 0 ifTrue: [^interpreterProxy primitiveFail].
	isSigned 
		ifTrue:[value := interpreterProxy signed64BitValueOf: valueOop]
		ifFalse:[value := interpreterProxy positive64BitValueOf: valueOop].
	interpreterProxy failed ifTrue:[^0].
	byteSize < 8 ifTrue:
		[isSigned
			ifTrue:
				[max := 1 asUnsignedLongLong << (8 * byteSize - 1).
				(value >= (0 - max) and: [value < max]) ifFalse: [^interpreterProxy primitiveFail]]
			ifFalse:
				[value asUnsignedLongLong < (1 asUnsignedLongLong << (8 * byteSize)) ifFalse: [^interpreterProxy primitiveFail]]].
	byteSize <= 2
		ifTrue:
			[byteSize = 1
				ifTrue: [interpreterProxy byteAt: addr put: value]
				ifFalse: [interpreterProxy unalignedShortAt: addr put: value]]
		ifFalse:
			[byteSize = 4
				ifTrue: [interpreterProxy unalignedLong32At: addr put: value]
				ifFalse: [interpreterProxy unalignedLong64At: addr put: value]].
	^interpreterProxy pop: 5 thenPush: valueOop
]

{ #category : #primitives }
ThreadedFFIPlugin >> primitiveForceLoad [
	"Primitive. Force loading the receiver (an instance of ExternalLibrary)."
	| rcvr moduleHandlePtr moduleHandle ffiModuleName ptr |
	<export: true>
	<inline: false>
	<var: #ptr type: #'sqInt *'>
	interpreterProxy methodArgumentCount = 0 ifFalse:
		[^interpreterProxy primitiveFail].
	rcvr := interpreterProxy stackValue: 0.
	(interpreterProxy is: rcvr KindOfClass: interpreterProxy classExternalLibrary) ifFalse:
		[^self ffiFail: FFIErrorBadExternalLibrary].
	moduleHandlePtr := interpreterProxy fetchPointer: 0 ofObject: rcvr.
	moduleHandle := self ffiContentsOfHandle: moduleHandlePtr errCode: FFIErrorBadExternalLibrary.
	interpreterProxy failed ifTrue:
		[^0].
	ffiModuleName := interpreterProxy fetchPointer: 1 ofObject: rcvr.
	(interpreterProxy isBytes: ffiModuleName) ifFalse:
		[^self ffiFail: FFIErrorBadExternalLibrary].
	moduleHandle := (interpreterProxy
						ioLoadModule: (interpreterProxy firstIndexableField: ffiModuleName) asInteger
						OfLength: (interpreterProxy byteSizeOf: ffiModuleName)) asInteger.
	interpreterProxy failed ifTrue:
		[^self ffiFail: FFIErrorModuleNotFound]. "failed"
	"and store back"
	ptr := interpreterProxy firstIndexableField: moduleHandlePtr.
	ptr at: 0 put: moduleHandle.
	^0 "done"
]

{ #category : #primitives }
ThreadedFFIPlugin >> primitiveLoadSymbolFromModule [
	"Attempt to find the address of a symbol in a loaded library.
	loadSymbol: aSymbol fromModule: moduleName
		<primitive: 'primitiveLoadSymbolFromModule' error: errorCode module: 'SqueakFFIPrims'>
	"
	<export: true>

	| symbol module moduleHandle address oop ptr |

	<var: #address type: #'void *'>
	<var: #ptr type: #'void **'>
	
	interpreterProxy methodArgumentCount = 2 ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].	

	module := interpreterProxy stackValue: 0.
	symbol := interpreterProxy stackValue: 1.

	moduleHandle := module ~= interpreterProxy nilObject ifTrue:
						[self ffiLoadCalloutModule: module].
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNotFound].
	address := interpreterProxy
					ioLoadSymbol: (self cCoerce: (interpreterProxy firstIndexableField: symbol) to: #sqInt)
					OfLength: (interpreterProxy byteSizeOf: symbol)
					FromModule: moduleHandle.
	(interpreterProxy failed
	 or: [address = 0]) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNotFound].
	
	oop := interpreterProxy 
			instantiateClass: interpreterProxy classExternalAddress 
			indexableSize: (self sizeof: #'void *').
	ptr := interpreterProxy firstIndexableField: oop.
	ptr at: 0 put: address.
	
	^interpreterProxy methodReturnValue: oop
]

{ #category : #primitives }
ThreadedFFIPlugin >> primitiveLogCallsTo [
	"Enable logging of FFI calls by providing it with a log file name."
	| logFile ok |
	<export: true>
	interpreterProxy methodArgumentCount = 1 
		ifFalse:[^interpreterProxy primitiveFail].
	logFile := interpreterProxy stackValue: 0.
	logFile = interpreterProxy nilObject ifTrue:[ "disable logging"
		ok := self ffiLogFileName: nil OfLength: 0.
		ok ifFalse:[^interpreterProxy primitiveFail].
		ffiLogEnabled := false.
	] ifFalse:[ "enable logging"
		(interpreterProxy isBytes: logFile) ifFalse:[^interpreterProxy primitiveFail].
		ok := self ffiLogFileName: (interpreterProxy firstIndexableField: logFile)
					OfLength: (interpreterProxy byteSizeOf: logFile).
		ok ifFalse:[^interpreterProxy primitiveFail].
		ffiLogEnabled := true.
	].
	^interpreterProxy pop: 1. "pop arg; return rcvr"

]

{ #category : #'primitives - surfaces' }
ThreadedFFIPlugin >> primitiveSetManualSurfacePointer [
	"Create a 'manual surface' data-structure.  See the ExternalForm class in the FFI package for example usage."
	"arguments: name(type, stack offset)
		surfaceID(Integer, 1)
		ptr(uint32/uint64, 0)"
	| surfaceID ptr result |
	<export: true>
	<var: #ptr type: #'usqIntptr_t'>
	
	interpreterProxy methodArgumentCount = 2 ifFalse: [^interpreterProxy primitiveFail].
	surfaceID := interpreterProxy stackIntegerValue: 1.
	ptr := interpreterProxy positiveMachineIntegerValueOf: (interpreterProxy stackValue: 0).
	interpreterProxy failed ifTrue: [^nil].

	self touch: surfaceID; touch: ptr.
	
	result := self setManualSurface: surfaceID Pointer: ptr asVoidPointer.
	result = 0 ifTrue: [^interpreterProxy primitiveFail].
	^interpreterProxy pop: 2
	
]

{ #category : #marshalling }
ThreadedFFIPlugin >> returnStructInRegisters: returnStructSize [
	"Answer if a struct result of a given size is returned in memory or not."
	^self subclassResponsibility
]

{ #category : #simulation }
ThreadedFFIPlugin >> setInterpreter: anInterpreter [
	"Initialization of the plugin in the simulator.
	 The real routine is in the superclass."
	self cCode: []
		inSmalltalk: [self class == thisContext method methodClass ifTrue:
						[self morphIntoConcreteSubclass: anInterpreter]].
	^super setInterpreter: anInterpreter
]

{ #category : #'primitive support' }
ThreadedFFIPlugin >> sizeField: oop [
	"Answer the first field of oop which is assumed to be an Alien of at least 8 bytes"
	<inline: true>
	^self longAt: oop + interpreterProxy baseHeaderSize
]

{ #category : #'primitive support' }
ThreadedFFIPlugin >> startOfData: oop [ "<Alien oop> ^<Integer>"
	"Answer the start of oop's data.  For direct aliens this is the address of
	 the second field.  For indirect and pointer aliens it is what the second field points to."
	<inline: true>
	^(self sizeField: oop) > 0
	 	ifTrue: [oop + interpreterProxy baseHeaderSize + interpreterProxy bytesPerOop]
		ifFalse: [self longAt: oop + interpreterProxy baseHeaderSize + interpreterProxy bytesPerOop]
]
