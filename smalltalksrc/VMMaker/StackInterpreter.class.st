"
This class is a complete implementation of the Smalltalk-80 virtual machine, derived originally from the Blue Book specification but quite different in some areas.  This VM supports Closures but *not* old-style BlockContexts.

It has been modernized with 32-bit (and indeed 64-bit) pointers, better management of Contexts (see next item), and attention to variable use that allows the CCodeGenerator (qv) to keep, eg, the instruction pointer and stack pointer in registers as well as keeping most simple variables in a global array that seems to improve performance for most platforms.

The VM does not use Contexts directly.  Instead Contexts serve as proxies for a more conventional stack format that is invisible to the image.  There is considerable explanation at http://www.mirandabanda.org/cogblog/2009/01/14/under-cover-contexts-and-the-big-frame-up.  The VM maintains a fixed-size stack zone divided into pages, each page being capable of holding several method/block activations.  A send establishes a new frame in the current stack page, a return returns to the previous frame.  This eliminates allocation/deallocation of contexts and the moving of receiver and arguments from caller to callee on each send/return.  Contexts are created lazily when an activation needs a context (creating a block, explicit use of thisContext, access to sender when sender is a frame, or linking of stack pages together).  Contexts are either conventional and heap-resident (""single"") or ""married"" and serve as proxies for their corresponding frame or ""widowed"", meaning that their spouse frame has been returned from (died).  A married context is specially marked (more details in the code) and refers to its frame.  Likewise a married frame is specially marked and refers to its context.

In addition to SmallInteger arithmetic and Floats, the VM supports logic on 32-bit (and 64-bit) PositiveLargeIntegers, thus allowing it to simulate itself much more efficiently than would otherwise be the case.

StackInterpreter and subclasses support multiple memory managers.  Currently there are two.  NewMemoryManager is a slightly refined version of ObjectMemory, and is the memory manager and garbage collector for the original Squeak object representation as described in ""Back to the Future The Story of Squeak, A Practical Smalltalk Written in Itself"", see http://ftp.squeak.org/docs/OOPSLA.Squeak.html.  Spur is a faster, more regular object representation that is designed for more performance and functionality, and to have a common header format for both 32-bit and 64-bit versions.  You can read about it in SpurMemoryManager's class comment.  There is also a video of a presentation at ESUG 2014 (https://www.youtube.com/watch?v=k0nBNS1aHZ4), along with slides (http://www.slideshare.net/esug/spur-a-new-object-representation-for-cog?related=1).

StackInterpreter is designed toi be subclassed by CoInterpreter et al.  CoInterpreter cooperates with a bytecode to machine-code JIT compiler, for much higher performance

Instance Variables

atCache
	- a small array holding tuples of oop => format,fixedFields,size to speed up at:[put:].  Unused in CoInterpreter

breakLookupClassTag
	- if non-nil, the class tag to break on sends, breaking (calling warning) if there's a match

breakSelector
	- if breakSelectorLength ~= 0, a pointer to a string to compare messageSelector against on send, breaking (calling warning) if there's a match

breakSelectorLength
	- if > 0, breakSelector is checked on each send.  If < 0, breakSelector is checked on each MNU

bytecodeSetSelector
	- if multiple bytecode sets are in use this is the offset (0 or 256) for the current bytecode set

checkAllocFiller
	- a variable used to fill eden to allow checking for overwriting the end of an object

checkedPluginName
	- the oop of a symbol which, when gcmode is GCCheckPrimCall, can check for heap memory leaks after a specific primitive has been called

classByteArrayCompactIndex
	- the compact class index of the class ByteArray, if appropriate

classNameIndex
	- the slot index of name in a class object, used or debug printing, derived from class Array at start-up

currentBytecode
	- the value of the currentBytecode

debugCallbackInvokes
	- a counter used to debug the old (Python) callback support

debugCallbackPath
	- a variable used to hold the path through the new callback support

debugCallbackReturns
	- a counter used to debug the old (Python) callback support; it should match debugCallbackInvokes

deferDisplayUpdates
	- the variable that implements primitive 126, primitiveDeferDisplayUpdates

desiredEdenBytes
	- the desired size of eden, used at image load and snapshot time

desiredNumStackPages
	- the desired number of stack pages, used at image load and snapshot time

displayBits
	- either the first indexable field of the current display object, or the handle of the current display surface

displayDepth
	- pixel depth of the current display object or surface

displayHeight
	- height in pixels of the current display object or surface

displayWidth
	- width in pixels of the current display object or surface

extA
	- if a prefix btecode set, such as SstaV1, is in use, the accumulator for extension A

extB
	- if a prefix btecode set, such as SstaV1, is in use, the accumulator for extension B

externalPrimitiveTable
	- xxxxx

externalPrimitiveTableFirstFreeIndex
	- a small array cacheing the target function pointer for external calls (primitiveExternalCall)

extraFramesToMoveOnOverflow
	- a variable used to prevent thrashing on sends and returns at the end of a page (see overflowedPage)

extraVMMemory
	- in Spur, free heap to be allocated at startup.  In V3, C memory to reserve for malloc at startup (i.e. malloc extraVMMemory, alloc heap, free extraVMMemory)

framePointer
	- the pointer to the current frame when primitives (or in the CoInterpreter, when machine-code <-> interpreter transitions) are invoked (c.f. localFP)

fullScreenFlag
	- true if the system is in full-screen mode

gcSemaphoreIndex
	- if non-zero, the index in the semaphore table of a semaphore to signal after any GC

globalSessionID
	- a non-zero number (derived from the time) identifying the current session

highestRunnableProcessPriority
	- a tide mark in the runnableProcesses array, used to reduce the time spent scanning the array looking for the highest priority runnable process.  This variable is set high when the priority of the highest process is unknown, and set to the highest found when the array is scanned.  Hence most of the time the nused entries in the array are not scanned.

imageFloatsBigEndian
	- true if the order of data in floats is big-endian

imageHeaderFlags
	- the flags stored in the image at load time or to be stored in the image at snapshto time.  These flags identify various options, sich as whether floats are in platfrm order.

inIOProcessEvents
	- true if the system is receiving events in ioProcessEvents, used to avoid recursion when receiuving events via callbacks

instructionPointer
	- the pointer to the current bytecode when primitives (or in the CoInterpreter, when machine-code <-> interpreter transitions) are invoked (c.f. localIP)

interpreterProxy
	- the table of functions used to export interpreter and memory manager functions to plugin primitives

interruptCheckChain
	- if non nil a funciton pointer to be called when a user interrupt event is received, used by plugin primitives to abort long-running calls on interrupt

interruptKeycode
	- the keycode of the event signifying a user interrupt

interruptPending
	- a variable set by ioProcessEvents if a user interrupt is pending

jmpBuf
	- a small array of jmpbufs (for setjmp/longjmp) used to manage returning in the iold (Python) callback support (see suspendedCallbacks et al)

jmpDepth
	- the index of the next free entry in jmpBuf

lastMethodCacheProbeWrite
	- the index of the last write into the method lookup cache, used by primitiveExternalCall to rewrite the method cache entry to call the target function, avoiding going through primitiveExternalCall on every plugin primitive dispatch

lkupClass
	- the implicit class argument to the class hierarchy looup routines such as lookupOrdinarySend

lkupClassTag
	- the implicit class tag argument to message send lookup

localAbsentReceiver
	- Newspeak, the absent receiver in any Newspeak absent receiver send

localAbsentReceiverOrZero
	- Newspeak, if non-zero, the absent receiver in any Newspeak outer absent receiver send

localFP
	- the frame pointer in the fully-inlined interpret routine, hopfully allowing a C compiler to assign localFP to a register variable (c.f. framePointer)

localIP
	- the instruction pointer in the fully-inlined interpret routine, hopfully allowing a C compiler to assign localFP to a register variable (c.f. instructionPointer)

localReturnValue
	- the value being returned in return bytecodes

localSP
	- the stack pointer in the fully-inlined interpret routine, hopfully allowing a C compiler to assign localFP to a register variable (c.f. framePointer)

longRunningPrimitiveCheckMethod
	- a variable used to monitor long-running primtiives via primitiveLongRunningPrimitive

longRunningPrimitiveCheckSemaphore
	- a variable used to monitor long-running primtiives via primitiveLongRunningPrimitive

longRunningPrimitiveCheckSequenceNumber
	- a variable used to monitor long-running primtiives via primitiveLongRunningPrimitive

longRunningPrimitiveGCUsecs
	- a variable used to monitor long-running primtiives via primitiveLongRunningPrimitive

longRunningPrimitiveSignalUndelivered
	- a variable used to monitor long-running primtiives via primitiveLongRunningPrimitive

longRunningPrimitiveStartUsecs
	- a variable used to monitor long-running primtiives via primitiveLongRunningPrimitive

longRunningPrimitiveStopUsecs
	- a variable used to monitor long-running primtiives via primitiveLongRunningPrimitive

lowcodeCalloutState
	- Lowcode, the state used to marshall an outgoing Lowcode call

maxExtSemTabSizeSet
	- a flag stating whether the maximum size of the external semaphore table has been set or not

metaAccessorDepth
	- Spur, the accessor depth of a primitive being invoked by one of the meta primitive primitives, primitiveDoPrimitiveWithArgs and primitiveDoNamedPrimitiveWithArgs

metaclassNumSlots
	- teh size of a Metaclass instanc, set at startup, used for debug printing

method
	- the oop of the current method

methodCache
	- a small array holding tuples of selector x class => method,functionPointer to speed up message send (avoid class hierarchy search on send)

methodDictLinearSearchLimit
	- a variable used to control searching of method dictionaries.  Dictionaries of size within the limit are searched linearly instead of hashed.  This can be used either to speed up search in small dictionaries or to turn off hashed lookup wen hashing needs to be changed

nativeSP
	- Lowcode, the native (C) stack pointer (?; then why nativeStackPointer?)

nativeStackPointer
	- Lowcode, the native (C) stack pointer (?; then why nativeSP?)

nextPollUsecs
	- if non-zero, the micosecond clock value at which to next poll for events, used to control event polling rate

nextWakeupUsecs
	- if non-zero, the micosecond clock value at which the next delay expires

nsMethodCache
	- Newspeak, a small array hilding tuples of selector x class tag x calling method x privacy code => target method,primitive function,actual receiver, used to speed up Newspeak absent receiver sends

numExtB
	- the number of bytes in extB, used to correctly maintain extB, given that it is unsigned

numStackPages
	- the number of stack pages being used

overflowedPage
	- the stack page that a send last overflowed, used to avoid thrashing on send and return at the end of a stack page (see extraFramesToMoveOnOverflow)

pendingFinalizationSignals
	- a variable used to control signalling the finalizationSemahpore

primitiveAccessorDepthTable
	- Spur, the accessor depths for the iundexed primitives, used to determine how much state to scan loking for forwarders on primitive failure

primitiveFunctionPointer
	- the function pointer (in simulation, the selector symbol) of the current primitive, nil for newMethod if there is no primitive

primitiveTable
	- the table holding the functions (in simulation the selector symbols) for the indexed primitives

savedWindowSize
	- the display size to write into a snapshot.  Avoids writing a zero window size into a snapshot when an image is loaded headless.  

shadowCallStackPointer
	- Lowcode, the shadow stack pointer, used when marshalling Lowcode external calls

showSurfaceFn
	- if non-zero, the function to call to update the display when the current display is a surface

stackLimit
	- the variable marking the end of the current stack page, also used to break out of interpretation to check for events.  When marking the end of a page, it enables a send to create an activation on a new page,  When set so that any send would fail the stack limit check, causes a check for events on stack page overflow

stackPage
	- the current stack page

stackPages
	- the set of stack pages

stackPointer
	- the pointer to the top of stack in the current frame when primitives (or in the CoInterpreter, when machine-code <-> interpreter transitions) are invoked (c.f. localSP)

statCheckForEvents
	- the count of checkForEventsMaybeContextSwitch: calls

statForceInterruptCheck
	- the count of forceInterruptCheck calls

statIOProcessEvents
	- the count of ioProcessEvents calls

statIdleUsecs
	- the count of microseconds at which the system is at idle (a bad idea; this should be replaced by its inverse; asking the OS how long the VM process has been active)

statPendingFinalizationSignals
	- the count of pendingFinalizationSignals

statProcessSwitch
	- the count of process switches

statStackOverflow
	- the count of stack overflows

statStackPageDivorce
	- the cound of stack page divorces (a stack page divorce occurs when a stack page must be freed for use)

suppressHeartbeatFlag
	- a flag controlling whether the heatbeat is in effect; the heartbeat is used to set stackLimit periodically to cause break out to chedck for events (see stackLimit)

suspendedCallbacks
	- a small array holding the processes suspended when the old callback machinery is in use (see jmpBuf et al)

suspendedMethods
	- a small array holding the methods of the processes suspended when the old callback machinery is in use

tempOop
	- if non-zero, an oop that may move during primitive execution

tempOop2
	- if non-zero, an oop that may move during primitive execution

the2ndUnknownShort
	- the value of a field in the image header that is unused in the StackInterpreter but used in the CoInterpreter (and hence to be preserved in snapshots)

theUnknownShort
	- the value of a field in the image header that is unused in the StackInterpreter but used in the CoInterpreter (and hence to be preserved in snapshots)

thisClassIndex
	- the index in a Metaclass of thisClass (the instance of the metaclass) used in debug printing
"
Class {
	#name : #StackInterpreter,
	#superclass : #InterpreterPrimitives,
	#instVars : [
		'currentBytecode',
		'bytecodeSetSelector',
		'localFP',
		'localIP',
		'localSP',
		'stackLimit',
		'stackPage',
		'stackPages',
		'method',
		'instructionPointer',
		'stackPointer',
		'framePointer',
		'localReturnValue',
		'localAbsentReceiver',
		'localAbsentReceiverOrZero',
		'extA',
		'extB',
		'numExtB',
		'primitiveFunctionPointer',
		'methodCache',
		'nsMethodCache',
		'atCache',
		'lkupClassTag',
		'lkupClass',
		'methodDictLinearSearchLimit',
		'highestRunnableProcessPriority',
		'reenterInterpreter',
		'nextWakeupUsecs',
		'nextPollUsecs',
		'inIOProcessEvents',
		'interruptKeycode',
		'interruptPending',
		'savedWindowSize',
		'imageHeaderFlags',
		'fullScreenFlag',
		'sendWheelEvents',
		'deferDisplayUpdates',
		'pendingFinalizationSignals',
		'extraVMMemory',
		'interpreterProxy',
		'showSurfaceFn',
		'primitiveTable',
		'primitiveAccessorDepthTable',
		'externalPrimitiveTable',
		'externalPrimitiveTableFirstFreeIndex',
		'overflowedPage',
		'extraFramesToMoveOnOverflow',
		'globalSessionID',
		'jmpBuf',
		'jmpDepth',
		'suspendedCallbacks',
		'suspendedMethods',
		'numStackPages',
		'desiredNumStackPages',
		'desiredEdenBytes',
		'classNameIndex',
		'thisClassIndex',
		'metaclassNumSlots',
		'interruptCheckChain',
		'suppressHeartbeatFlag',
		'breakSelector',
		'breakSelectorLength',
		'breakLookupClassTag',
		'longRunningPrimitiveCheckMethod',
		'longRunningPrimitiveCheckSemaphore',
		'longRunningPrimitiveStartUsecs',
		'longRunningPrimitiveStopUsecs',
		'longRunningPrimitiveGCUsecs',
		'longRunningPrimitiveCheckSequenceNumber',
		'longRunningPrimitiveSignalUndelivered',
		'checkAllocFiller',
		'tempOop',
		'tempOop2',
		'metaAccessorDepth',
		'theUnknownShort',
		'the2ndUnknownShort',
		'imageFloatsBigEndian',
		'maxExtSemTabSizeSet',
		'lastMethodCacheProbeWrite',
		'gcSemaphoreIndex',
		'classByteArrayCompactIndex',
		'checkedPluginName',
		'nativeSP',
		'nativeStackPointer',
		'lowcodeCalloutState',
		'shadowCallStackPointer',
		'displayBits',
		'displayWidth',
		'displayHeight',
		'displayDepth',
		'statForceInterruptCheck',
		'statStackOverflow',
		'statStackPageDivorce',
		'statCheckForEvents',
		'statProcessSwitch',
		'statIOProcessEvents',
		'statPendingFinalizationSignals',
		'statIdleUsecs',
		'debugCallbackPath',
		'debugCallbackReturns',
		'debugCallbackInvokes',
		'printedStackFrames',
		'maxStacksToPrint',
		'maxStackMessagePrinted',
		'libFFI',
		'codeGeneratorToComputeAccessorDepth'
	],
	#classVars : [
		'AccessModifierPrivate',
		'AccessModifierProtected',
		'AccessModifierPublic',
		'AltBytecodeEncoderClassName',
		'AltLongStoreBytecode',
		'AlternateHeaderHasPrimFlag',
		'AlternateHeaderIsOptimizedFlag',
		'AlternateHeaderNumLiteralsMask',
		'AtCacheFixedFields',
		'AtCacheFmt',
		'AtCacheMask',
		'AtCacheOop',
		'AtCacheSize',
		'AtCacheTotalSize',
		'AtPutBase',
		'BytecodeEncoderClassName',
		'BytecodeTable',
		'CacheProbeMax',
		'DirBadPath',
		'DirEntryFound',
		'DirNoMoreEntries',
		'DumpStackOnLowSpace',
		'EnclosingMixinIndex',
		'EnclosingObjectIndex',
		'EnforceAccessControl',
		'FailImbalancedPrimitives',
		'LongStoreBytecode',
		'MaxExternalPrimitiveTableSize',
		'MaxJumpBuf',
		'MaxPrimitiveIndex',
		'MaxQuickPrimitiveIndex',
		'MethodHeaderArgCountShift',
		'MethodHeaderFlagBitPosition',
		'MethodHeaderTempCountShift',
		'MixinIndex',
		'PrimNumberDoExternalCall',
		'PrimNumberDoPrimitive',
		'PrimNumberExternalCall',
		'PrimNumberFFICall',
		'PrimitiveTable',
		'ReturnToInterpreter',
		'StackPageReachedButUntraced',
		'StackPageTraceInvalid',
		'StackPageTraced',
		'StackPageUnreached',
		'V3PrimitiveBitsMask'
	],
	#pools : [
		'VMBasicConstants',
		'VMBytecodeConstants',
		'VMMethodCacheConstants',
		'VMObjectIndices',
		'VMSpurObjectRepresentationConstants',
		'VMSqueakClassIndices',
		'VMStackFrameOffsets'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #translation }
StackInterpreter class >> additionalHeadersDo: aBinaryBlock [
	"Evaluate aBinaryBlock with the names and contents of
	 any additional header files that need to be generated."
	aBinaryBlock
		value: 'vmCallback.h'
		value: self vmCallbackHeader
]

{ #category : #translation }
StackInterpreter class >> additionalSelectorTables [
	^{ self primitiveTable }
]

{ #category : #translation }
StackInterpreter class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	^{	self objectMemoryClass.
		VMCallbackContext.
		CogStackPages.
		InterpreterStackPages.
		LibFFI.
		CogStackPage }
]

{ #category : #constants }
StackInterpreter class >> bytecodeTable [

	^ BytecodeTable
]

{ #category : #translation }
StackInterpreter class >> declareCVarsIn: aCCodeGenerator [
	| vmClass |
	self class == thisContext methodClass ifFalse: [^self]. "Don't duplicate decls in subclasses"
	vmClass := aCCodeGenerator vmClass. "Generate primitiveTable etc based on vmClass, not just StackInterpreter"
	aCCodeGenerator
		addHeaderFile:'<stddef.h> /* for e.g. alloca */';
		addHeaderFile:'<stdint.h> /* for e.g. alloca */';
		addHeaderFile:'<setjmp.h>';
		addHeaderFile:'<wchar.h> /* for wint_t */';
		addHeaderFile:'"vmCallback.h"';
		addHeaderFile:'"sqMemoryFence.h"';
		addHeaderFile:'"dispdbg.h"';

"This cannot be properly expressed in slang.
If ffi is put as a separate header, slang will sort the header and put it outside the #ifdef"
		addHeaderFile:'#if FEATURE_FFI
#include <ffi.h>
#endif //FEATURE_FFI
#if FEATURE_THREADED_FFI
#include "pharovm/pThreadedFFI/worker.h"
#endif //FEATURE_THREADED_FFI'.

	LowcodeVM ifTrue: [ aCCodeGenerator addHeaderFile:'"sqLowcodeFFI.h"'].

	vmClass declareInterpreterVersionIn: aCCodeGenerator defaultName: 'Stack'.
	aCCodeGenerator
		var: #interpreterProxy  type: #'struct VirtualMachine*'.
	aCCodeGenerator
		declareVar: #sendTrace type: 'volatile int';
		declareVar: #byteCount type: #usqInt.
	"These need to be pointers or unsigned."
	self declareC: #(instructionPointer method newMethod)
		as: #usqInt
		in: aCCodeGenerator.
	"These are all pointers; char * because Slang has no support for C pointer arithmetic."
	self declareC: #(localIP localSP localFP stackPointer framePointer stackLimit breakSelector)
		as: #'char *'
		in: aCCodeGenerator.
	aCCodeGenerator
		var: #breakSelectorLength
		declareC: 'sqInt breakSelectorLength = MinSmallInteger'.
	self declareC: #(stackPage overflowedPage)
		as: #'StackPage *'
		in: aCCodeGenerator.
	aCCodeGenerator removeVariable: 'stackPages'.  "this is an implicit receiver in the translated code."
	"This defines bytecodeSetSelector as 0 if MULTIPLEBYTECODESETS
	 is not defined, for the benefit of the interpreter on slow machines."
	aCCodeGenerator addConstantForBinding: (self bindingOf: #MULTIPLEBYTECODESETS).
	MULTIPLEBYTECODESETS == false ifTrue:
		[aCCodeGenerator
			removeVariable: 'bytecodeSetSelector'].
	BytecodeSetHasExtensions == false ifTrue:
		[aCCodeGenerator
			removeVariable: 'extA';
			removeVariable: 'extB'].
	aCCodeGenerator
		var: #methodCache
		declareC: 'sqIntptr_t methodCache[MethodCacheSize + 1 /* ', (MethodCacheSize + 1) printString, ' */]'.
	aCCodeGenerator
		removeVariable: #nsMethodCache;
		removeVariable: 'localAbsentReceiver';
		removeVariable: 'localAbsentReceiverOrZero'.
	AtCacheTotalSize isInteger ifTrue:
		[aCCodeGenerator
			var: #atCache
			declareC: 'sqInt atCache[AtCacheTotalSize + 1 /* ', (AtCacheTotalSize + 1) printString, ' */]'].
	aCCodeGenerator
		var: #primitiveTable
		declareC: 'void (*primitiveTable[MaxPrimitiveIndex + 2 /* ', (MaxPrimitiveIndex + 2) printString, ' */])(void) = ', vmClass primitiveTableString.
	vmClass primitiveTable do:
		[:symbolOrNot|
		(symbolOrNot isSymbol
		 and: [symbolOrNot ~~ #primitiveFail]) ifTrue:
			[(aCCodeGenerator methodNamed: symbolOrNot) ifNotNil:
				[:tMethod| tMethod returnType: #void]]].
	vmClass objectMemoryClass hasSpurMemoryManagerAPI
		ifTrue:
			[aCCodeGenerator
				var: #primitiveAccessorDepthTable
				type: 'signed char'
				sizeString: 'MaxPrimitiveIndex + 2 /* ', (MaxPrimitiveIndex + 2) printString, ' */'
				array: vmClass primitiveAccessorDepthTable]
		ifFalse:
			[aCCodeGenerator removeVariable: #primitiveAccessorDepthTable].
	aCCodeGenerator
		var: #displayBits type: #'void *'.
	self declareC: #(displayWidth displayHeight displayDepth) as: #int in: aCCodeGenerator.
	aCCodeGenerator
		var: #primitiveFunctionPointer
			declareC: 'void (*primitiveFunctionPointer)()';
		var: #externalPrimitiveTable
			declareC: 'void (*externalPrimitiveTable[MaxExternalPrimitiveTableSize + 1 /* ', (MaxExternalPrimitiveTableSize + 1) printString, ' */])(void)';
		var: #interruptCheckChain
			declareC: 'void (*interruptCheckChain)(void) = 0';
		var: #showSurfaceFn
			declareC: 'int (*showSurfaceFn)(sqIntptr_t, int, int, int, int)';
		var: #jmpBuf
			declareC: 'jmp_buf jmpBuf[MaxJumpBuf + 1 /* ', (MaxJumpBuf + 1) printString, ' */]';
		var: #suspendedCallbacks
			declareC: 'usqInt suspendedCallbacks[MaxJumpBuf + 1 /* ', (MaxJumpBuf + 1) printString, ' */]';
		var: #suspendedMethods
			declareC: 'usqInt suspendedMethods[MaxJumpBuf + 1 /* ', (MaxJumpBuf + 1) printString, ' */]'.

	self declareCAsUSqLong: #(nextPollUsecs nextWakeupUsecs longRunningPrimitiveGCUsecs
								longRunningPrimitiveStartUsecs longRunningPrimitiveStopUsecs
								"these are high-frequency enough that they're overflowing quite quickly on modern hardware"
								statProcessSwitch statIOProcessEvents statForceInterruptCheck
								statCheckForEvents statStackOverflow statStackPageDivorce
								statIdleUsecs)
		in: aCCodeGenerator.
	aCCodeGenerator var: #nextProfileTick type: #sqLong.
	aCCodeGenerator
		var: #reenterInterpreter
		declareC: 'jmp_buf reenterInterpreter; /* private export */'.
		
	aCCodeGenerator removeVariable: #'libFFI'.
	LibFFIConstants classVariables do: [ :e | aCCodeGenerator removeConstant: e name ].
		
	LowcodeVM
		ifTrue:
			[aCCodeGenerator
				var: #lowcodeCalloutState type: #'sqLowcodeCalloutState*'.
			 self declareC: #(nativeSP nativeStackPointer shadowCallStackPointer)
				as: #'char *'
				in: aCCodeGenerator]
		ifFalse:
			[#(lowcodeCalloutState nativeSP nativeStackPointer shadowCallStackPointer) do:
				[:var| aCCodeGenerator removeVariable: var]]
]

{ #category : #translation }
StackInterpreter class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #initialization }
StackInterpreter class >> initializeAssociationIndex [
	KeyIndex := 0.
	ValueIndex := 1
]

{ #category : #initialization }
StackInterpreter class >> initializeBytecodeTable [
	"StackInterpreter initializeBytecodeTable"

	VMBytecodeConstants falsifyBytecodeSetFlags: InitializationOptions.
	BytecodeSetHasDirectedSuperSend := false.

	(InitializationOptions at: #bytecodeTableInitializer ifAbsent: nil) ifNotNil:
		[:initalizer| ^self perform: initalizer].

	^MULTIPLEBYTECODESETS
		ifTrue: [self initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid]
		ifFalse: [self initializeBytecodeTableForSqueakV3PlusClosures]
]

{ #category : #initialization }
StackInterpreter class >> initializeBytecodeTableForSistaV1 [
	"See e.g. the cass comment for EncoderForSistaV1"
	"StackInterpreter initializeBytecodeTableForSistaV1"
	"Note: This table will be used to generate a C switch statement."

	InitializationOptions at: #SistaV1BytecodeSet put: (SistaV1BytecodeSet := true).

	BytecodeTable := Array new: 256.
	BytecodeEncoderClassName := #EncoderForSistaV1.
	BytecodeSetHasDirectedSuperSend := true.
	BytecodeSetHasExtensions := true.
	LongStoreBytecode := 245.
	self table: BytecodeTable from:
	#(	"1 byte bytecodes"
		(   0  15 pushReceiverVariableBytecode)
		( 16  31 pushLiteralVariable16CasesBytecode)
		( 32  63 pushLiteralConstantBytecode)
		( 64  75 pushTemporaryVariableBytecode)
		( 76	 pushReceiverBytecode)
		( 77	 pushConstantTrueBytecode)
		( 78	 pushConstantFalseBytecode)
		( 79	 pushConstantNilBytecode)
		( 80	 pushConstantZeroBytecode)
		( 81	 pushConstantOneBytecode)
		( 82	 extPushPseudoVariable)
		( 83	 duplicateTopBytecode)
	
		( 84 87	unknownBytecode)
		( 88	returnReceiver)
		( 89	returnTrue)
		( 90	returnFalse)
		( 91	returnNil)
		( 92	returnTopFromMethod)
		( 93	returnNilFromBlock)
		( 94	returnTopFromBlock)
		( 95	extNopBytecode)

		( 96	 bytecodePrimAdd)
		( 97	 bytecodePrimSubtract)
		( 98	 bytecodePrimLessThanSistaV1) 		"for booleanCheatSistaV1:"
		( 99	 bytecodePrimGreaterThanSistaV1) 	"for booleanCheatSistaV1:"
		(100	 bytecodePrimLessOrEqualSistaV1) 	"for booleanCheatSistaV1:"
		(101	 bytecodePrimGreaterOrEqualSistaV1) 	"for booleanCheatSistaV1:"
		(102	 bytecodePrimEqualSistaV1) 			"for booleanCheatSistaV1:"
		(103	 bytecodePrimNotEqualSistaV1) 		"for booleanCheatSistaV1:"
		(104	 bytecodePrimMultiply)
		(105	 bytecodePrimDivide)
		(106	 bytecodePrimMod)
		(107	 bytecodePrimMakePoint)
		(108	 bytecodePrimBitShift)
		(109	 bytecodePrimDiv)
		(110	 bytecodePrimBitAnd)
		(111	 bytecodePrimBitOr)

		(112	 bytecodePrimAt)
		(113	 bytecodePrimAtPut)
		(114	 bytecodePrimSize)
		(115	 bytecodePrimNext)		 "i.e. a 0 arg special selector"
		(116	 bytecodePrimNextPut)		 "i.e. a 1 arg special selector"
		(117	 bytecodePrimAtEnd)
		(118	 bytecodePrimIdenticalSistaV1) "for booleanCheatSistaV1:"
		(119	 bytecodePrimClass)
		(120	 bytecodePrimNotIdenticalSistaV1) "was blockCopy:"
		(121	 bytecodePrimValue)
		(122	 bytecodePrimValueWithArg)
		(123	 bytecodePrimDo)			"i.e. a 1 arg special selector"
		(124	 bytecodePrimNew)			"i.e. a 0 arg special selector"
		(125	 bytecodePrimNewWithArg)	"i.e. a 1 arg special selector"
		(126	 bytecodePrimPointX)		"i.e. a 0 arg special selector"
		(127	 bytecodePrimPointY)		"i.e. a 0 arg special selector"

		(128 143	sendLiteralSelector0ArgsBytecode)
		(144 159	sendLiteralSelector1ArgBytecode)
		(160 175	sendLiteralSelector2ArgsBytecode)

		(176 183	shortUnconditionalJump)
		(184 191	shortConditionalJumpTrue)
		(192 199	shortConditionalJumpFalse)
	
		(200 207	storeAndPopReceiverVariableBytecode)
		(208 215	storeAndPopTemporaryVariableBytecode)
		(216		popStackBytecode)
		(217		unconditionnalTrapBytecode)

		(218 223	unknownBytecode)

		"2 byte bytecodes"
		(224		extABytecode)
		(225		extBBytecode)

		(226		extPushReceiverVariableBytecode)
		(227		extPushLiteralVariableBytecode)
		(228		extPushLiteralBytecode)
		(229		longPushTemporaryVariableBytecode)
		(230		unknownBytecode)
		(231		pushNewArrayBytecode)
		(232		extPushIntegerBytecode)
		(233		extPushCharacterBytecode)

		(234		extSendBytecode)
		(235		extSendSuperBytecode)

		(236		callMappedInlinedPrimitive)

		(237		extUnconditionalJump)
		(238		extJumpIfTrue)
		(239		extJumpIfFalse)

		(240		extStoreAndPopReceiverVariableBytecode)
		(241		extStoreAndPopLiteralVariableBytecode)
		(242		longStoreAndPopTemporaryVariableBytecode)

		(243		extStoreReceiverVariableBytecode)
		(244		extStoreLiteralVariableBytecode)
		(245		longStoreTemporaryVariableBytecode)

		(246 247	unknownBytecode)

		"3 byte bytecodes"
		(248		callPrimitiveBytecode)
		(249		extPushFullClosureBytecode)

		(250		extPushClosureBytecode)
		(251		pushRemoteTempLongBytecode)
		(252		storeRemoteTempLongBytecode)
		(253		storeAndPopRemoteTempLongBytecode)
				
		(254 255	unknownBytecode)
	)
]

{ #category : #initialization }
StackInterpreter class >> initializeBytecodeTableForSqueakV3PlusClosures [
	"StackInterpreter initializeBytecodeTableForSqueakV3PlusClosures"
	"Note: This table will be used to generate a C switch statement."

	InitializationOptions at: #SqueakV3PlusClosuresBytecodeSet put: (SqueakV3PlusClosuresBytecodeSet := true).

	BytecodeTable := Array new: 256.
	BytecodeEncoderClassName := #EncoderForV3PlusClosures.
	LongStoreBytecode := 129.
	BytecodeSetHasExtensions := false.
	self table: BytecodeTable from:
	#(
		(  0  15 pushReceiverVariableBytecode)
		( 16  31 pushTemporaryVariableBytecode)
		( 32  63 pushLiteralConstantBytecode)
		( 64  95 pushLiteralVariableBytecode)
		( 96 103 storeAndPopReceiverVariableBytecode)
		(104 111 storeAndPopTemporaryVariableBytecode)
		(112 pushReceiverBytecode)
		(113 pushConstantTrueBytecode)
		(114 pushConstantFalseBytecode)
		(115 pushConstantNilBytecode)
		(116 pushConstantMinusOneBytecode)
		(117 pushConstantZeroBytecode)
		(118 pushConstantOneBytecode)
		(119 pushConstantTwoBytecode)
		(120 returnReceiver)
		(121 returnTrue)
		(122 returnFalse)
		(123 returnNil)
		(124 returnTopFromMethod)
		(125 returnTopFromBlock)

		(126 127 unknownBytecode)

		(128 extendedPushBytecode)
		(129 extendedStoreBytecode)
		(130 extendedStoreAndPopBytecode)
		(131 singleExtendedSendBytecode)
		(132 doubleExtendedDoAnythingBytecode)
		(133 singleExtendedSuperBytecode)
		(134 secondExtendedSendBytecode)
		(135 popStackBytecode)
		(136 duplicateTopBytecode)

		(137 pushActiveContextBytecode)
		(138 pushNewArrayBytecode)),

	((InitializationOptions at: #SpurObjectMemory ifAbsent: [false])
		ifTrue: [#((139 callPrimitiveBytecode))]	"V3PlusClosures on Spur"
		ifFalse: [#((139 unknownBytecode))]),	"V3PlusClosures on V3"

	  #(
		(140 pushRemoteTempLongBytecode)
		(141 storeRemoteTempLongBytecode)
		(142 storeAndPopRemoteTempLongBytecode)
		(143 pushClosureCopyCopiedValuesBytecode)

		(144 151 shortUnconditionalJump)
		(152 159 shortConditionalJumpFalse)
		(160 167 longUnconditionalJump)
		(168 171 longJumpIfTrue)
		(172 175 longJumpIfFalse)

		"176-191 were sendArithmeticSelectorBytecode"
		(176 bytecodePrimAdd)
		(177 bytecodePrimSubtract)
		(178 bytecodePrimLessThan)
		(179 bytecodePrimGreaterThan)
		(180 bytecodePrimLessOrEqual)
		(181 bytecodePrimGreaterOrEqual)
		(182 bytecodePrimEqual)
		(183 bytecodePrimNotEqual)
		(184 bytecodePrimMultiply)
		(185 bytecodePrimDivide)
		(186 bytecodePrimMod)
		(187 bytecodePrimMakePoint)
		(188 bytecodePrimBitShift)
		(189 bytecodePrimDiv)
		(190 bytecodePrimBitAnd)
		(191 bytecodePrimBitOr)

		"192-207 were sendCommonSelectorBytecode"
		(192 bytecodePrimAt)
		(193 bytecodePrimAtPut)
		(194 bytecodePrimSize)
		(195 bytecodePrimNext)
		(196 bytecodePrimNextPut)
		(197 bytecodePrimAtEnd)
		(198 bytecodePrimIdentical)
		(199 bytecodePrimClass)
		(200 bytecodePrimNotIdentical) "was bytecodePrimSpecialSelector24 / blockCopy"
		(201 bytecodePrimValue)
		(202 bytecodePrimValueWithArg)
		(203 bytecodePrimDo)
		(204 bytecodePrimNew)
		(205 bytecodePrimNewWithArg)
		(206 bytecodePrimPointX)
		(207 bytecodePrimPointY)

		(208 223 sendLiteralSelector0ArgsBytecode)
		(224 239 sendLiteralSelector1ArgBytecode)
		(240 255 sendLiteralSelector2ArgsBytecode)
	)
]

{ #category : #initialization }
StackInterpreter class >> initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid [
	"StackInterpreter initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid"

	| v3Table v1Table |
	self initializeBytecodeTableForSistaV1.
	v1Table := BytecodeTable.
	AltBytecodeEncoderClassName := BytecodeEncoderClassName.
	AltLongStoreBytecode := LongStoreBytecode.
	self initializeBytecodeTableForSqueakV3PlusClosures.
	BytecodeSetHasExtensions := true.
	v3Table := BytecodeTable.
	BytecodeTable := v3Table, v1Table
]

{ #category : #initialization }
StackInterpreter class >> initializeCaches [

	| atCacheEntries atCacheEntrySize |
	MethodCacheEntries := 1024.
	MethodCacheSelector := 1.
	MethodCacheClass := 2.
	MethodCacheMethod := 3.
	MethodCachePrimFunction := 4.
	MethodCacheEntrySize := 4.  "Must be power of two for masking scheme."
	MethodCacheMask := (MethodCacheEntries - 1) * MethodCacheEntrySize.
	MethodCacheSize := MethodCacheEntries * MethodCacheEntrySize.
	CacheProbeMax := 3.

	NSMethodCacheEntries := 512.
	NSMethodCacheSelector := 1.
	NSMethodCacheClassTag := 2.
	NSMethodCacheCallingMethod := 3.
	NSMethodCacheDepthOrLookupRule := 4.
	NSMethodCacheTargetMethod := 5.
	NSMethodCachePrimFunction := 6.
	NSMethodCacheActualReceiver := 7.
	NSMethodCacheEntrySize := 8.	"Must be power of two for masking scheme."
	NSMethodCacheMask := NSMethodCacheEntries - 1 * NSMethodCacheEntrySize.
	NSMethodCacheSize := NSMethodCacheEntries * NSMethodCacheEntrySize.

	AtCacheOop := 1.
	AtCacheSize := 2.
	AtCacheFmt := 3.
	AtCacheFixedFields := 4.
	atCacheEntries := 8.
	atCacheEntrySize := 4.  "Must be power of two for masking scheme."
	AtCacheMask := (atCacheEntries-1) * atCacheEntrySize.
	AtPutBase := atCacheEntries * atCacheEntrySize.
	AtCacheTotalSize := atCacheEntries * atCacheEntrySize * 2.

	"LookupRuleOuter is [0, 255], with the value being the lexical depth. Note that an
	 outer send to lexical depth 0 is equivalent to a self send. Implicit receiver and
	 outer sends are encoded as adjacent values to allow a quick range check to
	 determine whether the absent receiver might differ from the method receiver.
	 Note also Smalltalk super sends use ordinary send lookup rules."
	LookupRuleSelf := 0.
	LookupRuleImplicit := 256.
	LookupRuleDynamicSuper := 257.
	LookupRuleOrdinary := 258.
	LookupRuleMNU := 259.

]

{ #category : #initialization }
StackInterpreter class >> initializeCharacterIndex [
	CharacterValueIndex := 0
]

{ #category : #initialization }
StackInterpreter class >> initializeCharacterScannerIndices [
	CrossedX := 258.
	EndOfRun := 257

]

{ #category : #initialization }
StackInterpreter class >> initializeClassIndices [
	"Class Class"
	SuperclassIndex := 0.
	MethodDictionaryIndex := 1.
	InstanceSpecificationIndex := 2.
	"Fields of a message dictionary"
	MethodArrayIndex := 1. 
	SelectorStart := 2.

]

{ #category : #initialization }
StackInterpreter class >> initializeContextIndices [
	"Class MethodContext"
	SenderIndex := 0.
	InstructionPointerIndex := 1.
	StackPointerIndex := 2.
	MethodIndex := 3.
	ClosureIndex := 4. "N.B. Called receiverMap in old images, closureOrNil in newer images."
	ReceiverIndex := 5.
	CtxtTempFrameStart := 6.

	SmallContextSlots := CtxtTempFrameStart + 16.  "16 indexable fields"
	"Large contexts have 56 indexable fields.  Max with single header word of ObjectMemory [but not SpurMemoryManager ;-)]."
	LargeContextSlots := CtxtTempFrameStart + 56.
	
	"Including the header size in these sizes is problematic for multiple memory managers,
	 so we don't use them.  Set to #bogus for error checking."
	SmallContextSize := #bogus.
	LargeContextSize := #bogus.

	"Class BlockClosure"
	ClosureOuterContextIndex := 0.
	ClosureStartPCIndex := 1.
	ClosureNumArgsIndex := 2.
	ClosureFirstCopiedValueIndex := 3.
	
	"Class FullBlockClosure, outercontext and numArgs index are shared with the BlockClosure class."	
	FullClosureCompiledBlockIndex := 1.
	FullClosureReceiverIndex := 3.
	FullClosureFirstCopiedValueIndex := 4.
]

{ #category : #initialization }
StackInterpreter class >> initializeDirectoryLookupResultCodes [

	DirEntryFound := 0.
	DirNoMoreEntries := 1.
	DirBadPath := 2.
]

{ #category : #initialization }
StackInterpreter class >> initializeFrameIndices [
	"Format of a stack frame.  Word-sized indices relative to the frame pointer.
	 Terminology
		Frames are either single (have no context) or married (have a context).
		Contexts are either single (exist on the heap), married (have a context) or widowed (had a frame that has exited).
	 Stacks grow down:

			receiver for method activations/closure for block activations
			arg0
			...
			argN
			caller's method ip/base frame's sender context
	fp->	saved fp
			method
			frame flags
			context (uninitialized)
			receiver
			first temp
			...
	sp->	Nth temp

	frame flags holds the number of arguments (since argument temporaries are above the frame)
	the flag for a block activation
	and the flag indicating if the context field is valid (whether the frame is married).

	The first frame in a stack page is the baseFrame and is marked as such by a null saved fp,
	in which case the saved method ip is actually the context (possibly hybrid) beneath the base frame"

	| fxCallerSavedIP fxSavedFP fxMethod fxFrameFlags fxThisContext fxReceiver |
	fxCallerSavedIP := 1.
	fxSavedFP := 0.
	fxMethod := -1.
	fxFrameFlags := -2.	"Can find numArgs, needed for fast temp access. args are above fxCallerSavedIP.
						 Can find ``is block'' bit
						 Can find ``has context'' bit"
	fxThisContext := -3.
	fxReceiver := -4.

	FrameSlots := fxCallerSavedIP - fxReceiver + 1.

	FoxCallerSavedIP := fxCallerSavedIP * BytesPerWord.
	"In base frames the caller saved ip field holds the caller context."
	FoxCallerContext := FoxCallerSavedIP.
	FoxSavedFP := fxSavedFP * BytesPerWord.
	FoxMethod := fxMethod * BytesPerWord.
	FoxFrameFlags := fxFrameFlags * BytesPerWord.
	FoxThisContext := fxThisContext * BytesPerWord.
	FoxReceiver := fxReceiver * BytesPerWord.

	"Mark the CoInterpreter-specific offsets as #undefined to
	 avoid including them accidentally in StackInterpreter code."
	IFrameSlots := #undefined.
	MFrameSlots := #undefined.
	FoxIFrameFlags := #undefined.
	FoxIFSavedIP := #undefined.
	FoxIFReceiver := #undefined.
	FoxMFReceiver := #undefined
]

{ #category : #initialization }
StackInterpreter class >> initializeMessageIndices [
	MessageSelectorIndex := 0.
	MessageArgumentsIndex := 1.
	MessageLookupClassIndex := 2.
]

{ #category : #initialization }
StackInterpreter class >> initializeMethodIndices [
	| tagBits |
	"Class CompiledMethod"
	HeaderIndex := 0.
	LiteralStart := 1.

	tagBits := self objectMemoryClass numSmallIntegerTagBits.
	LargeContextBit := 16r20000 << tagBits.  "This bit set in method headers if large context is needed."
	MethodHeaderTempCountShift := 18 + tagBits.
	MethodHeaderArgCountShift := 24 + tagBits.
	V3PrimitiveBitsMask := 16r100001FF << tagBits.
	AlternateHeaderHasPrimFlag := 16r10000 << tagBits.
	AlternateHeaderIsOptimizedFlag := 16r8000 << tagBits.
	AlternateHeaderNumLiteralsMask := 16r7FFF. "N.B.  *not* shifted"
	"The position of the unused flag bit in the method header, not including tag bit(s).
	 Bits 28 & 29 are free for use as flag bits."
	MethodHeaderFlagBitPosition := 28 + tagBits.
	AccessModifierPublic := 2r00.
	AccessModifierPrivate := 2r01.
	AccessModifierProtected := 2r10.
]

{ #category : #initialization }
StackInterpreter class >> initializeMiscConstants [

	super initializeMiscConstants.
	STACKVM := true.

	"These flags function to identify a GC operation, or
	 to specify what operations the leak checker should be run for."
	GCModeFull := 1.				"stop-the-world global GC"
	GCModeNewSpace := 2.		"Spur's scavenge, or V3's incremental"
	GCModeIncremental := 4.		"incremental global gc (Dijkstra tri-colour marking); as yet unimplemented"
	GCModeBecome := 8.			"v3 post-become sweeping/Spur forwarding"
	GCModeImageSegment := 16.	"just a flag for leak checking image segments"
	GCModeFreeSpace := 32.		"just a flag for leak checking free space; Spur only"
	GCCheckPrimCall := 64.		"just a flag for leak checking external primitive calls"

	StackPageTraceInvalid := -1.
	StackPageUnreached := 0.
	StackPageReachedButUntraced := 1.
	StackPageTraced := 2.

	DumpStackOnLowSpace := 0.
	MillisecondClockMask := 16r1FFFFFFF.
	"Note: The external primitive table should actually be dynamically sized but for the sake of inferior platforms (e.g., Mac :-) who cannot allocate memory in any reasonable way, we keep it static (and cross our fingers...)"
	MaxExternalPrimitiveTableSize := 4096. "entries"

	MaxJumpBuf := 32. "max. callback depth"
	FailImbalancedPrimitives := InitializationOptions at: #FailImbalancedPrimitives ifAbsentPut: [true].
	EnforceAccessControl := InitializationOptions at: #EnforceAccessControl ifAbsent: [true].

	ReturnToInterpreter := 1. "setjmp/longjmp code."

	"N.B. some of these DisownFlags are replicated in platforms/Cross/vm/sqVirtualMachine.h.
	 Hence they should always be initialized.  Because of a hack with callbacks in the non-threaded
	 VM they must not conflct with the VM's tag bits."
	DisownVMLockOutFullGC := 8.
	DisownVMForFFICall := 16.
	DisownVMForThreading := 32

]

{ #category : #initialization }
StackInterpreter class >> initializePointIndices [
	XIndex := 0.
	YIndex := 1
]

{ #category : #initialization }
StackInterpreter class >> initializePrimitiveTable [
	"This table generates a C function address table used in slowPrimitiveResponse along with dispatchFunctionPointerOn:in:"
	"self initializePrimitiveTable"

	"NOTE: The real limit here is 2047 because of the old method header layout but there is no point in going over the needed size"
	MaxPrimitiveIndex := 660.	
	MaxQuickPrimitiveIndex := 519.
	PrimNumberExternalCall := 117.
	PrimNumberDoPrimitive := 118.
	PrimNumberFFICall := 120.
	PrimNumberDoExternalCall := 218.
	PrimitiveTable := Array new: MaxPrimitiveIndex + 1.
	self primitivesClass table: PrimitiveTable from: 
	#(	"Integer Primitives (0-19)"
		(0 0 "a.k.a. primitiveFail but faster because primitiveFail won't even be called")
		(1 primitiveAdd)
		(2 primitiveSubtract)
		(3 primitiveLessThan)
		(4 primitiveGreaterThan)
		(5 primitiveLessOrEqual)
		(6 primitiveGreaterOrEqual)
		(7 primitiveEqual)
		(8 primitiveNotEqual)
		(9 primitiveMultiply)
		(10 primitiveDivide)
		(11 primitiveMod)
		(12 primitiveDiv)
		(13 primitiveQuo)
		(14 primitiveBitAnd)
		(15 primitiveBitOr)
		(16 primitiveBitXor)
		(17 primitiveBitShift)
		(18 primitiveMakePoint)
		(19 primitiveFail)					"Guard primitive for simulation -- *must* fail"

		"LargeInteger Primitives (20-37)"
		(20 primitiveRemLargeIntegers)
		(21 primitiveAddLargeIntegers)
		(22 primitiveSubtractLargeIntegers)
		(23 primitiveLessThanLargeIntegers)
		(24 primitiveGreaterThanLargeIntegers)
		(25 primitiveLessOrEqualLargeIntegers)
		(26 primitiveGreaterOrEqualLargeIntegers)
		(27 primitiveEqualLargeIntegers)
		(28 primitiveNotEqualLargeIntegers)
		(29 primitiveMultiplyLargeIntegers)
		(30 primitiveDivideLargeIntegers)
		(31 primitiveModLargeIntegers)
		(32 primitiveDivLargeIntegers)
		(33 primitiveQuoLargeIntegers)
		(34 primitiveBitAndLargeIntegers)
		(35 primitiveBitOrLargeIntegers)
		(36 primitiveBitXorLargeIntegers)
		(37 primitiveBitShiftLargeIntegers)

		"Float Primitives (38-59)"
		(38 primitiveFloatAt)
		(39 primitiveFloatAtPut)
		(40 primitiveAsFloat)
		(41 primitiveFloatAdd)
		(42 primitiveFloatSubtract)
		(43 primitiveFloatLessThan)
		(44 primitiveFloatGreaterThan)
		(45 primitiveFloatLessOrEqual)
		(46 primitiveFloatGreaterOrEqual)
		(47 primitiveFloatEqual)
		(48 primitiveFloatNotEqual)
		(49 primitiveFloatMultiply)
		(50 primitiveFloatDivide)
		(51 primitiveTruncated)
		(52 primitiveFractionalPart)
		(53 primitiveExponent)
		(54 primitiveTimesTwoPower)
		(55 primitiveSquareRoot)
		(56 primitiveSine)
		(57 primitiveArctan)
		(58 primitiveLogN)
		(59 primitiveExp)

		"Subscript and Stream Primitives (60-67)"
		(60 primitiveAt)
		(61 primitiveAtPut)
		(62 primitiveSize)
		(63 primitiveStringAt)
		(64 primitiveStringAtPut)
		"The stream primitives no longer pay their way; normal Smalltalk code is faster."
		(65 0 "a.k.a. primitiveFail but faster because primitiveFail won't even be called")"was primitiveNext"
		(66 0 "a.k.a. primitiveFail but faster because primitiveFail won't even be called") "was primitiveNextPut"
		(67 0 "a.k.a. primitiveFail but faster because primitiveFail won't even be called") "was primitiveAtEnd"

		"StorageManagement Primitives (68-79)"
		(68 primitiveObjectAt)
		(69 primitiveObjectAtPut)
		(70 primitiveNew)
		(71 primitiveNewWithArg)
		(72 primitiveArrayBecomeOneWay)	"Blue Book: primitiveBecome"
		(73 primitiveInstVarAt)
		(74 primitiveInstVarAtPut)
		(75 primitiveIdentityHash)
		(76 primitiveStoreStackp)			"Blue Book: primitiveAsObject"
		(77 primitiveSomeInstance)
		(78 primitiveNextInstance)
		(79 primitiveNewMethod)

		"Control Primitives (80-89)"
		(80 primitiveFail)					"Blue Book: primitiveBlockCopy"
		(81 primitiveFail)					"Blue Book: primitiveValue"
		(82 primitiveFail)					"Blue Book: primitiveValueWithArgs"
		(83 primitivePerform)
		(84 primitivePerformWithArgs)
		(85 primitiveSignal)
		(86 primitiveWait)
		(87 primitiveResume)
		(88 primitiveSuspend)
		(89 primitiveFlushCache)

		"Input/Output Primitives (90-109)"
		(90 primitiveMousePoint)
		(91 primitiveTestDisplayDepth)			"Blue Book: primitiveCursorLocPut"
		(92 primitiveSetDisplayMode)				"Blue Book: primitiveCursorLink"
		(93 primitiveInputSemaphore)
		(94 primitiveGetNextEvent)				"Blue Book: primitiveSampleInterval"
		(95 primitiveInputWord)
		(96 primitiveFail)	"primitiveCopyBits"
		(97 primitiveSnapshot)
		(98 primitiveStoreImageSegment)
		(99 primitiveLoadImageSegment)
		(100 primitivePerformInSuperclass)		"Blue Book: primitiveSignalAtTick"
		(101 primitiveBeCursor)
		(102 primitiveBeDisplay)
		(103 primitiveFail)	"primitiveScanCharacters"
		(104 primitiveFail)	"primitiveDrawLoop"
		(105 primitiveStringReplace)
		(106 primitiveScreenSize)
		(107 primitiveMouseButtons)
		(108 primitiveKbdNext)
		(109 primitiveKbdPeek)

		"System Primitives (110-119)"
		(110 primitiveIdentical)
		(111 primitiveClass)
		(112 primitiveBytesLeft)
		(113 primitiveQuit)
		(114 primitiveExitToDebugger)
		(115 primitiveChangeClass)					"Blue Book: primitiveOopsLeft"
		(116 primitiveFlushCacheByMethod)
		(117 primitiveExternalCall)
		(118 primitiveDoPrimitiveWithArgs)
		(119 primitiveFlushCacheBySelector)
			"Squeak 2.2 and earlier use 119.  Squeak 2.3 and later use 116.
			Both are supported for backward compatibility."

		"Miscellaneous Primitives (120-127)"
		(120 primitiveCalloutToFFI)
		(121 primitiveImageName)
		(122 primitiveNoop)					"Blue Book: primitiveImageVolume"
		(123 primitiveFail)	"was primitiveValueUninterruptably"
		(124 primitiveLowSpaceSemaphore)
		(125 primitiveSignalAtBytesLeft)

		"Squeak Primitives Start Here"

		"Squeak Miscellaneous Primitives (128-149)"
		(126 primitiveDeferDisplayUpdates)
		(127 primitiveShowDisplayRect)
		(128 primitiveArrayBecome)
		(129 primitiveSpecialObjectsOop)
		(130 primitiveFullGC)
		(131 primitiveIncrementalGC)
		(132 primitiveObjectPointsTo)
		(133 primitiveSetInterruptKey)
		(134 primitiveInterruptSemaphore)
		(135 primitiveMillisecondClock)
		(136 primitiveSignalAtMilliseconds)
		(137 primitiveSecondsClock)
		(138 primitiveSomeObject)
		(139 primitiveNextObject)
		(140 primitiveBeep)
		(141 primitiveClipboardText)
		(142 primitiveVMPath)
		(143 primitiveShortAt)
		(144 primitiveShortAtPut)
		(145 primitiveConstantFill)
		"NOTE: When removing the obsolete indexed primitives,
		the following two should go become #primitiveIntegerAt / atPut"
		(146 primitiveFail)	"primitiveReadJoystick"
		(147 primitiveFail)	"primitiveWarpBits"
		(148 primitiveClone)
		(149 primitiveGetAttribute)

		"Were File Primitives (150-169) - NO LONGER INDEXED"
		(150 157 primitiveFail)
		(158 primitiveCompareWith)
		(159 primitiveHashMultiply)
		(160 primitiveAdoptInstance)
		(161 primitiveSetOrHasIdentityHash)
		(162 primitiveFail)			"reserved for immutablity primitives"
		(163 primitiveGetImmutability)
		(164 primitiveSetImmutability)	
		(165 primitiveIntegerAt)		"hacked in here for now"
		(166 primitiveIntegerAtPut)
		(167 primitiveYield)
		(168 primitiveCopyObject)
		(169 primitiveNotIdentical)

		"SpurMemoryManager primitives"
		(170 primitiveAsCharacter)
		(171 primitiveImmediateAsInteger)
		(172 primitiveFetchNextMourner)
		(173 primitiveSlotAt)		"c.f. (73 primitiveInstVarAt)"
		(174 primitiveSlotAtPut)	"c.f. (74 primitiveInstVarAtPut)"
		(175 primitiveBehaviorHash)
		(176 primitiveMaxIdentityHash)
		(177 primitiveAllInstances)
		(178 primitiveAllObjects)
		(179 primitiveFail) "reserved for primitiveAllInstancesOfAny"
		(180 primitiveGrowMemoryByAtLeast)
		(181 primitiveSizeInBytesOfInstance)
		(182 primitiveSizeInBytes)
		(183 primitiveIsPinned)
		(184 primitivePin)

		"CriticalSection primitives"
		(185 primitiveExitCriticalSection) "similar to signal hence index = signal + 100"
		(186 primitiveEnterCriticalSection) "similar to wait hence index = wait + 100. was primitiveClosureValue"
		(187 primitiveTestAndSetOwnershipOfCriticalSection) "was primitiveClosureValueWithArgs"

		"Perform method directly"
		(188 primitiveExecuteMethodArgsArray)
		(189 primitiveExecuteMethod)

		"Sound Primitives (continued) - NO LONGER INDEXED"
		(190 194 primitiveFail)

		"Unwind primitives"
		(195 primitiveFindNextUnwindContext)
		(196 primitiveTerminateTo)
		(197 primitiveFindHandlerContext)
		(198 0 "a.k.a. primitiveMarkUnwindMethod")
		(199 0 "a.k.a. primitiveMarkHandlerMethod")

		"new closure primitives (were Networking primitives)"
		(200 primitiveClosureCopyWithCopiedValues)
		(201 primitiveClosureValue) "value"
		(202 primitiveClosureValue) "value:"
		(203 primitiveClosureValue) "value:value:"
		(204 primitiveClosureValue) "value:value:value:"
		(205 primitiveClosureValue) "value:value:value:value:"
		(206 primitiveClosureValueWithArgs) "valueWithArguments:"

		(207 primitiveFullClosureValue) "value[:value:value:value:] et al"
		(208 primitiveFullClosureValueWithArgs) "valueWithArguments:"
		(209 primitiveFullClosureValueNoContextSwitch) "valueNoContextSwitch[:value:] et al"

		(210 primitiveContextAt)
		(211 primitiveContextAtPut)
		(212 primitiveContextSize)
		(213 primitiveContextXray)
		(214 primitiveVoidVMState)
		(215 primitiveFlushCacheByMethod) "primitiveVoidVMStateForMethod in the CoInterpreter"
		(216 217 primitiveFail)	"reserved for Cog primitives"
		(218 primitiveDoNamedPrimitiveWithArgs)
		(219 primitiveFail)		"reserved for Cog primitives"

		(220 primitiveFail)		"reserved for Cog primitives"

		(221 primitiveClosureValueNoContextSwitch) "valueNoContextSwitch"
		(222 primitiveClosureValueNoContextSwitch) "valueNoContextSwitch:"

		(223 229 primitiveFail)	"reserved for Cog primitives (see 228 & 229 in CoInterpreterMT"

		(230 primitiveRelinquishProcessor)
		(231 primitiveForceDisplayUpdate)
		(232 primitiveFormPrint)
		(233 primitiveSetFullScreen)
		(234 primitiveFail) "primBitmapdecompressfromByteArrayat"
		(235 primitiveFail) "primStringcomparewithcollated"
		(236 primitiveFail) "primSampledSoundconvert8bitSignedFromto16Bit"
		(237 primitiveFail) "primBitmapcompresstoByteArray"
		(238 239 primitiveFail) "serial port primitives"
		(240 primitiveUTCMicrosecondClock)		"was serial port primitive"
		(241 primitiveLocalMicrosecondClock)		"was serial port primitive"
		(242 primitiveSignalAtUTCMicroseconds)
		(243 primitiveUpdateTimezone) "primStringtranslatefromtotable"
		(244 primitiveUtcAndTimezoneOffset)
		(245 primitiveCoarseUTCMicrosecondClock) "primStringindexOfAsciiinStringstartingAt"
		(246 primitiveCoarseLocalMicrosecondClock) "primStringfindSubstringinstartingAtmatchTable"
		(247 primitiveSnapshotEmbedded)
		(248 primitiveArrayBecomeOneWayNoCopyHash) "was primitiveInvokeObjectAsMethod"
		(249 primitiveArrayBecomeOneWayCopyHash)

		"VM Implementor Primitives (250-255)"
		(250 primitiveClearVMProfile)
		(251 primitiveControlVMProfiling "primitiveStartVMProfiling")
		(252 primitiveVMProfileSamplesInto "primitiveStopVMProfiling")
		(253 primitiveFail "N.B. primitiveCollectCogCodeConstituents in CoInterpreter below")
		(254 primitiveVMParameter)
		(255 primitiveFail) "RESERVED FOR THE R/Squeak VM. Was primitiveInstVarsPutFromStack. Never used except in Disney tests."

		"Quick Push Const Methods"
		(256 nil) "primitivePushSelf"
		(257 nil) "primitivePushTrue"
		(258 nil) "primitivePushFalse"
		(259 nil) "primitivePushNil"
		(260 nil) "primitivePushMinusOne"
		(261 nil) "primitivePushZero"
		(262 nil) "primitivePushOne"
		(263 nil) "primitivePushTwo"

		"Quick Push Inst Var Methods"
		(264 519 nil) "primitiveLoadInstVar"

		(520 primitiveFail)
		(521 529 primitiveFail) "Reserved for Spur primitives"
		(530 539 primitiveFail)

		(540 primitiveFail)
		(541 primitiveSmallFloatAdd)
		(542 primitiveSmallFloatSubtract)
		(543 primitiveSmallFloatLessThan)
		(544 primitiveSmallFloatGreaterThan)
		(545 primitiveSmallFloatLessOrEqual)
		(546 primitiveSmallFloatGreaterOrEqual)
		(547 primitiveSmallFloatEqual)
		(548 primitiveSmallFloatNotEqual)
		(549 primitiveSmallFloatMultiply)
		(550 primitiveSmallFloatDivide)
		(551 primitiveSmallFloatTruncated)
		(552 primitiveSmallFloatFractionalPart)
		(553 primitiveSmallFloatExponent)
		(554 primitiveSmallFloatTimesTwoPower)
		(555 primitiveSmallFloatSquareRoot)
		(556 primitiveSmallFloatSine)
		(557 primitiveSmallFloatArctan)
		(558 primitiveSmallFloatLogN)
		(559 primitiveSmallFloatExp)

		(560 569 primitiveFail)

		"External primitive support primitives"
		(570 primitiveFlushExternalPrimitives)
		(571 primitiveUnloadModule)
		(572 primitiveListBuiltinModule)
		(573 primitiveListExternalModule)
		(574 primitiveFail) "reserved for addl. external support prims"

		"Unassigned Primitives"
		(575 597 primitiveFail)

		"Pinned object creation primitives"
		(598 primitiveNewPinned)
		(599 primitiveNewWithArgPinned)
		
		"Memory accessor primitives"
		(600 primitiveLoadBoolean8FromBytes)
		(601 primitiveLoadUInt8FromBytes)
		(602 primitiveLoadInt8FromBytes)
		(603 primitiveLoadUInt16FromBytes)
		(604 primitiveLoadInt16FromBytes)
		(605 primitiveLoadUInt32FromBytes)
		(606 primitiveLoadInt32FromBytes)
		(607 primitiveLoadUInt64FromBytes)
		(608 primitiveLoadInt64FromBytes)
		(609 primitiveLoadPointerFromBytes)
		(610 primitiveLoadChar8FromBytes)
		(611 primitiveLoadChar16FromBytes)
		(612 primitiveLoadChar32FromBytes)
		(613 primitiveLoadFloat32FromBytes)
		(614 primitiveLoadFloat64FromBytes)
		(615 primitiveStoreBoolean8IntoBytes)
		(616 primitiveStoreUInt8IntoBytes)
		(617 primitiveStoreInt8IntoBytes)
		(618 primitiveStoreUInt16IntoBytes)
		(619 primitiveStoreInt16IntoBytes)
		(620 primitiveStoreUInt32IntoBytes)
		(621 primitiveStoreInt32IntoBytes)
		(622 primitiveStoreUInt64IntoBytes)
		(623 primitiveStoreInt64IntoBytes)
		(624 primitiveStorePointerIntoBytes)
		(625 primitiveStoreChar8IntoBytes)
		(626 primitiveStoreChar16IntoBytes)
		(627 primitiveStoreChar32IntoBytes)
		(628 primitiveStoreFloat32IntoBytes)
		(629 primitiveStoreFloat64IntoBytes)
		(630 primitiveLoadBoolean8FromExternalAddress)
		(631 primitiveLoadUInt8FromExternalAddress)
		(632 primitiveLoadInt8FromExternalAddress)
		(633 primitiveLoadUInt16FromExternalAddress)
		(634 primitiveLoadInt16FromExternalAddress)
		(635 primitiveLoadUInt32FromExternalAddress)
		(636 primitiveLoadInt32FromExternalAddress)
		(637 primitiveLoadUInt64FromExternalAddress)
		(638 primitiveLoadInt64FromExternalAddress)
		(639 primitiveLoadPointerFromExternalAddress)
		(640 primitiveLoadChar8FromExternalAddress)
		(641 primitiveLoadChar16FromExternalAddress)
		(642 primitiveLoadChar32FromExternalAddress)
		(643 primitiveLoadFloat32FromExternalAddress)
		(644 primitiveLoadFloat64FromExternalAddress)
		(645 primitiveStoreBoolean8IntoExternalAddress)
		(646 primitiveStoreUInt8IntoExternalAddress)
		(647 primitiveStoreInt8IntoExternalAddress)
		(648 primitiveStoreUInt16IntoExternalAddress)
		(649 primitiveStoreInt16IntoExternalAddress)
		(650 primitiveStoreUInt32IntoExternalAddress)
		(651 primitiveStoreInt32IntoExternalAddress)
		(652 primitiveStoreUInt64IntoExternalAddress)
		(653 primitiveStoreInt64IntoExternalAddress)
		(654 primitiveStorePointerIntoExternalAddress)
		(655 primitiveStoreChar8IntoExternalAddress)
		(656 primitiveStoreChar16IntoExternalAddress)
		(657 primitiveStoreChar32IntoExternalAddress)
		(658 primitiveStoreFloat32IntoExternalAddress)
		(659 primitiveStoreFloat64IntoExternalAddress)
		
		(660 primitiveFail)
		)
]

{ #category : #initialization }
StackInterpreter class >> initializeSchedulerIndices [
	"Class ProcessorScheduler"
	ProcessListsIndex := 0.
	ActiveProcessIndex := 1.
	"Class LinkedList"
	FirstLinkIndex := 0.
	LastLinkIndex := 1.
	"Class Semaphore"
	ExcessSignalsIndex := 2.
	"Class Link"
	NextLinkIndex := 0.
	"Class Process"
	SuspendedContextIndex := 1.
	PriorityIndex := 2.
	MyListIndex := 3
]

{ #category : #initialization }
StackInterpreter class >> initializeSmallIntegers [
	"SmallIntegers"
	ConstMinusOne := self objectMemoryClass basicNew integerObjectOf: -1.
	ConstZero := self objectMemoryClass basicNew integerObjectOf: 0.
	ConstOne := self objectMemoryClass basicNew integerObjectOf: 1.
	ConstTwo := self objectMemoryClass basicNew integerObjectOf: 2
]

{ #category : #initialization }
StackInterpreter class >> initializeStreamIndices [
	StreamArrayIndex := 0.
	StreamIndexIndex := 1.
	StreamReadLimitIndex := 2.
	StreamWriteLimitIndex := 3.
]

{ #category : #initialization }
StackInterpreter class >> initializeWithOptions: optionsDictionary [
	"StackInterpreter initializeWithOptions: Dictionary new"

	super initializeWithOptions: optionsDictionary.
	self initializeMiscConstants. "must precede other initialization."
	self initializeAssociationIndex.
	self initializeBytecodeTable.
	self initializeCaches.
	self initializeCharacterIndex.
	self initializeCharacterScannerIndices.
	self initializeClassIndices.
	self initializeContextIndices.
	self initializeDirectoryLookupResultCodes.
	self initializeFrameIndices.
	self initializeMessageIndices.
	self initializeMethodIndices.
	self initializePointIndices.
	self initializePrimitiveTable.
	self initializeSchedulerIndices.
	self initializeSmallIntegers.
	self initializeStreamIndices
]

{ #category : #accessing }
StackInterpreter class >> interpreterVersion [ 
	^ 'Stack'
]

{ #category : #translation }
StackInterpreter class >> isInterpreterClass [
	^true
]

{ #category : #translation }
StackInterpreter class >> isNonArgumentImplicitReceiverVariableName: aString [
	^(#('self' 'stackPages' 'interpreter' 'coInterpreter' 'objectMemory') includes: aString)
	  or: [self objectMemoryClass isNonArgumentImplicitReceiverVariableName: aString]
]

{ #category : #'spur compilation support' }
StackInterpreter class >> isObjectAccessor: selector [
	"Answer if selector is one of fetchPointer:ofObject: storePointer:ofObject:withValue:
	 et al."
	^(InterpreterProxy whichCategoryIncludesSelector: selector) = #'object access'
	 or: [(SpurMemoryManager whichCategoryIncludesSelector: selector) = #'object access']

	"This for checking.  The above two protocols are somewhat disjoint."
	"(InterpreterProxy allMethodsInCategory: #'object access') copyWithoutAll: (SpurMemoryManager allMethodsInCategory: #'object access')"
	"(SpurMemoryManager allMethodsInCategory: #'object access') copyWithoutAll: (InterpreterProxy allMethodsInCategory: #'object access')"
]

{ #category : #'spur compilation support' }
StackInterpreter class >> isStackAccessor: selector [
	^(StackInterpreter whichCategoryIncludesSelector: selector) = #'stack access'
]

{ #category : #translation }
StackInterpreter class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^(super mustBeGlobal: var)
	   or: [(self objectMemoryClass mustBeGlobal: var)
	   or: [(#('interpreterProxy' 'interpreterVersion' 'inIOProcessEvents' 'sendWheelEvents'
			'deferDisplayUpdates' 'extraVMMemory'
			'showSurfaceFn' 'displayBits' 'displayWidth' 'displayHeight' 'displayDepth'
			'desiredNumStackPages' 'desiredEdenBytes'
			'breakLookupClassTag' 'breakSelector' 'breakSelectorLength' 'sendTrace' 'checkAllocFiller' 'checkedPluginName'
			'reenterInterpreter' 'suppressHeartbeatFlag' 'ffiExceptionResponse'
			'debugCallbackInvokes' 'debugCallbackPath' 'debugCallbackReturns') includes: var)
	   or: [ "This allows slow machines to define bytecodeSetSelector as 0
			to avoid the interpretation overhead."
			MULTIPLEBYTECODESETS not and: [var = 'bytecodeSetSelector']]]]
]

{ #category : #translation }
StackInterpreter class >> namesOfVariablesToLocalize [
	^#(currentBytecode localFP localIP localSP localReturnValue)
]

{ #category : #translation }
StackInterpreter class >> needsCogit [
	^false
]

{ #category : #translation }
StackInterpreter class >> patchInterpGCCPPC: fileName [
	"Interpreter patchInterpGCCPPC: 'Squeak copy 1'"
	"This will patch out the unneccesary range check (a compare
	 and branch) in the inner interpreter dispatch loop. for the PPC version of the GCC compiled
	version of Squeak under MPW"
	"NOTE: You must edit in the Interpeter file name"

	| delta f code len remnant i |
	delta := 7.
	f := FileStream fileNamed: fileName.
	f binary.
	code := Bitmap new: (len := f size) // 4.
	f nextInto: code.
	remnant := f next: len - (code size * 4).
	i := 0.
	["Look for a BCTR instruction"
	(i := code indexOf: 16r4E800420 startingAt: i + 1 ifAbsent: [0]) > 0] whileTrue:
		["Look for a CMPLWI cr1,rxx,FF, 7 instrs back"
	       ((code at: i - delta) bitAnd: 16rFFE0FFFF) = 16r288000FF ifTrue:
	       	["Copy dispatch instrs back over the compare"
			self inform: 'Patching at ', i hex.
			0 to: delta - 2 do: [ :j |
				code at: (i - delta) + j put: (code at: (i - delta) + j + 2)]]].
	f position: 0; nextPutAll: code; nextPutAll: remnant.
	f close
]

{ #category : #translation }
StackInterpreter class >> preGenerationHook: aCCodeGen [
	"Perform any last-minute changes to the code generator immediately
	 before it performs code analysis and generation.  In this case, make
	 all non-exported methods private."
	| publicMethodNames |
	self primitiveTable do:
		[:s|
		(s isSymbol and: [s ~~ #primitiveFail]) ifTrue:
			[(aCCodeGen methodNamed: s) returnType: #void]].
	publicMethodNames := (self requiredMethodNames: aCCodeGen options)
								copyWithoutAll: (self primitiveTable
														copyWithout: #primitiveFail).
	aCCodeGen selectorsAndMethodsDo:
		[:s :m|
		(m export or: [m isAPIMethod or: [publicMethodNames includes: s]]) ifTrue:
			[m static: false]]
]

{ #category : #translation }
StackInterpreter class >> preambleCCode [
	^	
'/* Disable Intel compiler inlining of warning which is used for breakpoints */
#pragma auto_inline(off)
sqInt warnpid, erroronwarn;
void
warning(char *s) { /* Print an error message but don''t necessarily exit. */
	if (erroronwarn) error(s);
	if (warnpid)
		vm_printf("\n%s pid %ld\n", s, (long)warnpid);
	else
		vm_printf("\n%s\n", s);
}
void
warningat(char *s, int l) { /* ditto with line number. */
	/* use alloca to call warning so one does not have to remember to set two breakpoints... */
	char *sl = alloca(strlen(s) + 16);
	sprintf(sl, "%s %d", s, l);
	warning(sl);
}
#pragma auto_inline(on)

void
invalidCompactClassError(char *s) { /* Print a (compact) class index error message and exit. */
#if SPURVM
	vm_printf("\nClass %s does not have the required class index\n", s);
#else
	vm_printf("\nClass %s does not have the required compact class index\n", s);
#endif
	exit(-1);
}

/*
 * Define sigsetjmp and siglongjmp to be the most minimal setjmp/longjmp available on the platform.
 * Note: on windows 64 via mingw-w64, the 2nd argument NULL to _setjmp prevents stack unwinding
 */
#undef sigsetjmp
#undef siglongjmp
#if _MSC_VER
# define sigsetjmp(jb,ssmf) _setjmp(jb)
# define siglongjmp(jb,v) longjmp(jb,v)
#elif _WIN64 && __GNUC__
# define sigsetjmp(jb,ssmf) _setjmp(jb,NULL)
# define siglongjmp(jb,v) longjmp(jb,v)
#elif _WIN32
# define sigsetjmp(jb,ssmf) setjmp(jb)
# define siglongjmp(jb,v) longjmp(jb,v)
#else
# define sigsetjmp(jb,ssmf) _setjmp(jb)
# define siglongjmp(jb,v) _longjmp(jb,v)
#endif

#define odd(v) ((int)(v)&1)
#define even(v) (!odd(v))
'
]

{ #category : #translation }
StackInterpreter class >> prepareToBeAddedToCodeGenerator: aCodeGen [
	"It is either this or scan cmacro methods for selectors."
	aCodeGen retainMethods: #(enterSmalltalkExecutiveImplementation)
]

{ #category : #constants }
StackInterpreter class >> primitiveAccessorDepthTable [
	| cg |
	cg := MLVMCCodeGenerator new.
	cg vmClass: StackInterpreter.
	cg vmMaker: VMMaker new.
	cg vmMaker vmmakerConfiguration: VMMakerConfiguration.
	^self primitiveTable collect:
		[:thing| | implementingClass method |
		(thing isInteger "quick prims, 0 for fast primitve fail"
		 or: [thing == #primitiveFail
		 or: [(implementingClass := self primitivesClass whichClassIncludesSelector: thing) isNil]])
			ifTrue: [-1]
			ifFalse:
				[method := cg compileToTMethodSelector: thing in: implementingClass.
				 cg accessorDepthCalculator accessorDepthForMethod: method]]
]

{ #category : #constants }
StackInterpreter class >> primitiveTable [
	| cg |
	cg := MLVMCCodeGenerator new.
	cg vmClass: self.
	^PrimitiveTable collect:
		[:thing|
		(thing isInteger "quick prims, 0 for fast primitve fail"
		 or: [thing == #primitiveFail])
			ifTrue: [thing]
			ifFalse:
				[(self primitivesClass whichClassIncludesSelector: thing)
					ifNil: [#primitiveFail]
					ifNotNil:
						[:class|
						 (cg shouldIncludeMethodFor: class selector: thing)
							ifTrue: [thing]
							ifFalse: [#primitiveFail]]]]
]

{ #category : #initialization }
StackInterpreter class >> primitiveTableString [
	"StackInterpreter initializePrimitiveTable primitiveTableString"
	^self primitiveTableStringFor: self primitiveTable
]

{ #category : #initialization }
StackInterpreter class >> primitiveTableStringFor: table [
	"StackInterpreter initializePrimitiveTable primitiveTableString"
	^String streamContents:
		[:s | 
		s nextPut: ${.
		table withIndexDo:
			[:primSpec :index |
			s
				crtab;
				nextPutAll: '/* ';
				print: index - 1;
				nextPutAll: ' */ ';
				nextPutAll: (primSpec isString
								ifTrue: [primSpec == #primitiveFail
											ifTrue: ['(void (*)(void))0']
											ifFalse: [primSpec]]
								ifFalse: ['(void (*)(void))', primSpec printString]);
				nextPut: $,].
			s cr; nextPutAll: ' 0 }']
]

{ #category : #'accessing class hierarchy' }
StackInterpreter class >> primitivesClass [
	^StackInterpreterPrimitives
]

{ #category : #miscellaneous }
StackInterpreter class >> reorganizeAsISeeFit [
	"StackInterpreter reorganizeAsISeeFit"
	"CoInterpreter reorganizeAsISeeFit"
	| initializations bytecodes privates remainder |
	initializations := OrderedCollection new.
	bytecodes := OrderedCollection new.
	privates := OrderedCollection new.
	remainder := OrderedCollection new.
	self organization categories do:
		[:cat|
		((cat includesSubstring: 'initializ')
			ifTrue: [initializations]
			ifFalse:
				[((cat endsWith: 'bytecodes') or: [cat includesSubstring: 'selector sends'])
					ifTrue: [bytecodes]
					ifFalse:
						[(cat includesSubstring: 'private')
							ifTrue: [privates]
							ifFalse: [remainder]]])
			add: cat].
	self organization categories: initializations sort, bytecodes sort, remainder sort, privates sort
]

{ #category : #translation }
StackInterpreter class >> requiredMethodNames: options [
	"Answer the list of method names that should be retained for export or other support reasons"
	| requiredList |
	"A number of methods required by VM support code, specific platforms, etc"
	requiredList := #(
		assertValidExecutionPointe:r:s:
		characterForAscii:
		findClassOfMethod:forReceiver: findSelectorOfMethod:
			forceInterruptCheck forceInterruptCheckFromHeartbeat fullDisplayUpdate
		getCurrentBytecode getFullScreenFlag getInterruptKeycode getInterruptPending
			getSavedWindowSize getThisSessionID
		interpret
		loadInitialContext
		primitiveFail primitiveFailFor: primitiveFlushExternalPrimitives printAllStacks printCallStack printContext:
			printExternalHeadFrame printFramesInPage: printFrame: printHeadFrame printMemory printOop:
				printStackPages printStackPageList printStackPagesInUse printStackPageListInUse
		readableFormat: readImageFromFile:HeapSize:StartingAt:
		setFullScreenFlag: setInterruptKeycode: setInterruptPending: setInterruptCheckChain:
			setSavedWindowSize: success:
		validInstructionPointer:inMethod:framePointer:) asSet.

	"Nice to actually have all the primitives available"
	requiredList addAll: (self primitiveTable select: [:each| each isSymbol]).

	"InterpreterProxy is the internal analogue of sqVirtualMachine.c, so make sure to keep all those"
	InterpreterProxy organization categories do:
		[:cat |
		((cat ~= 'initialize') and: [cat ~= 'private']) ifTrue:
			[requiredList addAll: (InterpreterProxy organization listAtCategoryNamed: cat)]].

	^requiredList
]

{ #category : #translation }
StackInterpreter class >> sourceFileName [
	^'interp.c'
]

{ #category : #initialization }
StackInterpreter class >> table: anArray from: specArray [ 
	"SpecArray is an array of one of (index selector) or (index1 
	 index2 selector) or (index nil) or (index1 index2 nil).  If selector
	 then the entry is the selector, but if nil the entry is the index."
	| contiguous |
	contiguous := 0.
	specArray do:
		[:spec | 
		(spec at: 1) = contiguous ifFalse:
			[self error: 'Non-contiguous table entry'].
		spec size = 2
			ifTrue:
				[anArray
					at: (spec at: 1) + 1
					put: ((spec at: 2) ifNil: [spec at: 1] ifNotNil: [:sym| sym]).
				 contiguous := contiguous + 1]
			ifFalse:
				[(spec at: 1) to: (spec at: 2) do:
					[:i | anArray at: i + 1 put: ((spec at: 3) ifNil: [i] ifNotNil: [:sym| sym])].
				 contiguous := contiguous + ((spec at: 2) - (spec at: 1)) + 1]].
	anArray doWithIndex:
		[:entry :index|
		entry isSymbol ifTrue:
			[(self shouldIncludeMethodForSelector: entry) ifFalse:
				[anArray at: index put: 0]]]
]

{ #category : #translation }
StackInterpreter class >> translationClass [
	"Return te class to use as the interpreterCLass when translating.  For the all-in-one
	 VMs that inherit from ObjectMemory this is the receiver.  But for the separate VMs
	 where most primitives are in a subclass it will be the subclass with the primitives."
	^self subclasses detect: [:s| s name = (self name, 'Primitives')] ifNone: [self]
]

{ #category : #translation }
StackInterpreter class >> vmCallbackHeader [
	^String streamContents:
		[:s|
		s nextPutAll: '#define VM_CALLBACK_INC 1'; cr; cr.
		VMCallbackContext printTypedefOn: s.
		s cr]
]

{ #category : #'api version' }
StackInterpreter class >> vmProxyMajorVersion [
	"Define the  VM_PROXY_MAJOR version for this VM as used to
	 define the api in platforms/Cross/vm/sqVirtualMachine.[ch]"
	^1
]

{ #category : #'api version' }
StackInterpreter class >> vmProxyMinorVersion [
	"Define the  VM_PROXY_MINOR version for this VM as used to
	 define the api in platforms/Cross/vm/sqVirtualMachine.[ch]"
	"14 primitiveFailForOSError: methodReturnReceiver: primitiveFailForFFIException:at: added"
	^15 "isBooleanObject isPositiveMachineIntegerObject added"
]

{ #category : #translation }
StackInterpreter class >> wantsLabels [
	"Only label the VM, not plugins (internal or external).  This to cut down the scope
	 of problems with labels being duplicated by C compiler optimizer inlining and
	 loop unrolling.  We use the asmLabel: directive to control labelling in the
	 interpreter proper. But it is too much work doing that for plugins too."
	^true
]

{ #category : #translation }
StackInterpreter class >> writeVMHeaderTo: aStream bytesPerWord: bytesPerWord generator: aCCodeGenerator [
	super writeVMHeaderTo: aStream bytesPerWord: bytesPerWord generator: aCCodeGenerator.
	SistaVM ifTrue:
		[aCCodeGenerator putDefineOf: #SistaVM as: 1 on: aStream].
	MULTIPLEBYTECODESETS ifTrue:
		[aCCodeGenerator putDefineOf: #MULTIPLEBYTECODESETS as: 1 on: aStream].
	IMMUTABILITY ifTrue:
		[aCCodeGenerator
			putConditionalDefineOf: #IMMUTABILITY
			as: 1
			comment: 'Allow this to be overridden on the compiler command line'
			on: aStream].
	SistaVM | MULTIPLEBYTECODESETS | IMMUTABILITY ifTrue:
		[aStream cr].
	aCCodeGenerator putDefineOf: #STACKVM as: 1 on: aStream.
	(InitializationOptions at: #SpurObjectMemory ifAbsent: false) ifTrue:
		[aCCodeGenerator putDefineOf: #SPURVM as: 1 on: aStream].

	aCCodeGenerator
		putDefineOf: #DisownVMLockOutFullGC as: DisownVMLockOutFullGC on: aStream;
		putDefineOf: #DisownVMForFFICall as: DisownVMForFFICall on: aStream;
		putDefineOf: #DisownVMForThreading as: DisownVMForThreading on: aStream
]

{ #category : #simulation }
StackInterpreter >> ISA [
	<doNotGenerate>
	^self class initializationOptions
		at: #ISA
		ifAbsent: [Smalltalk wordSize = 8
					ifTrue: [#X64]
					ifFalse: [#IA32]]
]

{ #category : #'debug support' }
StackInterpreter >> abstractDetailedSymbolicMethod: aMethod [
	<doNotGenerate>
	| ts prim |
	(ts := self transcript) ensureCr.
	(prim := self primitiveIndexOf: aMethod) > 0 ifTrue:
		[ts nextPutAll: '<primitive: '; print: prim; nextPut: $>.
		(self isQuickPrimitiveIndex: prim) ifTrue:
			[ts nextPutAll: ' quick method'; cr; flush.
			 ^self].
		ts cr].
	(RelativeDetailedInstructionPrinter
			on: (VMCompiledMethodProxy new
					for: aMethod
					coInterpreter: self
					objectMemory: objectMemory))
		indent: 0;
		printInstructionsOn: ts.
	ts flush
]

{ #category : #'primitive support' }
StackInterpreter >> activateFailingPrimitiveMethod [
	"Assuming the primFailCode (and any other relevant failure state) has been set,
	 switch the VM to the interpreter if necessary (if in the CoInterpreter executing machine code),
	 and activate the newMethod (which is expected to have a primitive)."
	self assert: primFailCode ~= 0.
	self assert: (objectMemory addressCouldBeObj: newMethod).
	self assert: (objectMemory isCompiledMethod: newMethod).
	self assert: (self primitiveIndexOf: newMethod) ~= 0.
	self justActivateNewMethod: true. "Frame must be interpreted"
	self siglong: reenterInterpreter jmp: ReturnToInterpreter.
	"NOTREACHED"
	^nil
]

{ #category : #'control primitives' }
StackInterpreter >> activateNewClosure: blockClosure outer: outerContext method: theMethod  numArgs: numArgs mayContextSwitch: mayContextSwitch [
	"Similar to activateNewMethod but for Closure and newMethod."
	| numCopied closureIP |
	<inline: true>
	self assert: (objectMemory isContext: outerContext).
	numCopied := self copiedValueCountOfClosure: blockClosure.
	self assert: theMethod = (objectMemory fetchPointer: MethodIndex ofObject: outerContext).
	self assert: (objectMemory isOopCompiledMethod: theMethod).

	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: theMethod.
	self push: (self encodeFrameFieldHasContext: false isBlock: true numArgs: numArgs).
	self push: objectMemory nilObject. "FxThisContext field"
	"Because inst var access is not checked, we must follow the receiver in Spur to ensure it is valid."
	self push: (objectMemory followField: ReceiverIndex ofObject: outerContext).

	"Copy the copied values..."
	0 to: numCopied - 1 do:
		[:i|
		self push: (objectMemory
					fetchPointer: i + ClosureFirstCopiedValueIndex
					ofObject: blockClosure)].

	self assert: (self frameIsBlockActivation: framePointer).
	self assert: (self frameHasContext: framePointer) not.

	"The initial instructions in the block nil-out remaining temps."

	"the instruction pointer is a pointer variable equal to 
	method oop + ip + BaseHeaderSize 
	-1 for 0-based addressing of fetchByte 
	-1 because it gets incremented BEFORE fetching currentByte"
	closureIP := self quickFetchInteger: ClosureStartPCIndex ofObject: blockClosure.
	instructionPointer := theMethod + closureIP + objectMemory baseHeaderSize - 2.
	self setMethod: theMethod.

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)"
	stackPointer < stackLimit ifTrue:
		[self handleStackOverflowOrEventAllowContextSwitch: mayContextSwitch]
]

{ #category : #'control primitives' }
StackInterpreter >> activateNewFullClosure: blockClosure method: theMethod numArgs: numArgs mayContextSwitch: mayContextSwitch [
	"Similar to activateNewMethod but for Closure and newMethod."
	| numCopied methodHeader numTemps |
	<inline: true>
	self assert: theMethod = (objectMemory fetchPointer: FullClosureCompiledBlockIndex ofObject: blockClosure).
	numCopied := self copiedValueCountOfFullClosure: blockClosure.
	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: theMethod.
	self push: (self encodeFrameFieldHasContext: false isBlock: true numArgs: numArgs).
	self push: objectMemory nilObject. "FxThisContext field"
	"Because inst var access is not checked, we must follow the receiver in Spur to ensure it is valid."
	self push: (objectMemory followField: FullClosureReceiverIndex ofObject: blockClosure).

	"Copy the copied values..."
	0 to: numCopied - 1 do:
		[:i|
		self push: (objectMemory
					fetchPointer: i + FullClosureFirstCopiedValueIndex
					ofObject: blockClosure)].

	self assert: (self frameIsBlockActivation: framePointer).
	self assert: (self frameHasContext: framePointer) not.

	methodHeader := objectMemory methodHeaderOf: theMethod.
	numTemps := self temporaryCountOfMethodHeader: methodHeader.

	numArgs + numCopied + 1 to: numTemps do: [ :i | self push: objectMemory nilObject].

	instructionPointer := (self initialIPForHeader: methodHeader method: theMethod) - 1.
	
	self setMethod: theMethod.

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)"
	stackPointer < stackLimit ifTrue:
		[self handleStackOverflowOrEventAllowContextSwitch: mayContextSwitch]
]

{ #category : #'message sending' }
StackInterpreter >> activateNewMethod [
	| methodHeader |
	methodHeader := self justActivateNewMethod: false. "either interpreted or machine code"

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)."
	stackPointer < stackLimit ifTrue:
		[self handleStackOverflowOrEventAllowContextSwitch: (self canContextSwitchIfActivating: newMethod header: methodHeader)]
]

{ #category : #'process primitive support' }
StackInterpreter >> activeProcess [
	"Answer the current activeProcess."
	<api> "useful for VM debugging"
	^objectMemory memoryActiveProcess
]

{ #category : #'process primitive support' }
StackInterpreter >> addFirstLink: proc toList: aList [ 
	"Add the given process to the front of the given linked list
	 and set the backpointer of process to its new list."
	| firstLink |
	self assert: (objectMemory isForwarded: aList) not.
	self assert: (objectMemory fetchPointer: NextLinkIndex ofObject: proc) = objectMemory nilObject.
	firstLink := objectMemory fetchPointer: FirstLinkIndex ofObject: aList.
	self assert: firstLink ~= proc.
	objectMemory storePointer: FirstLinkIndex ofObject: aList withValue: proc.
	firstLink = objectMemory nilObject "a.k.a. (self isEmptyList: aList)"
		ifTrue: [objectMemory storePointer: LastLinkIndex ofObject: aList withValue: proc]
		ifFalse: [objectMemory storePointer: NextLinkIndex ofObject: proc withValue: firstLink].
	objectMemory storePointer: MyListIndex ofObject: proc withValue: aList
]

{ #category : #'primitive support' }
StackInterpreter >> addIdleUsecs: idleUsecs [
	"The various poll/select calls in the VM should attempt to tally the ammount
	 of time spent at idle here, so as to render the uptime value meaningful."
	<api>
	statIdleUsecs := statIdleUsecs + idleUsecs
]

{ #category : #'process primitive support' }
StackInterpreter >> addLastLink: proc toList: aList [ 
	"Add the given process to the end of the given linked list
	 and set the backpointer of process to its new list."
	| lastLink |
	self deny: (objectMemory isForwarded: proc).
	self deny: (objectMemory isForwarded: aList).
	self assert: (objectMemory fetchPointer: NextLinkIndex ofObject: proc) = objectMemory nilObject.
	(self isEmptyList: aList)
		ifTrue: [objectMemory storePointer: FirstLinkIndex ofObject: aList withValue: proc]
		ifFalse:
			[lastLink := objectMemory fetchPointer: LastLinkIndex ofObject: aList.
			 self assert: lastLink ~= proc.
			 objectMemory storePointer: NextLinkIndex ofObject: lastLink withValue: proc].
	objectMemory storePointer: LastLinkIndex ofObject: aList withValue: proc.
	objectMemory storePointer: MyListIndex ofObject: proc withValue: aList
]

{ #category : #'method lookup cache' }
StackInterpreter >> addNewMethodToCache: classObj [
	"Add the given entry to the method cache.
	The policy is as follows:
		Look for an empty entry anywhere in the reprobe chain.
		If found, install the new entry there.
		If not found, then install the new entry at the first probe position
			and delete the entries in the rest of the reprobe chain.
		This has two useful purposes:
			If there is active contention over the first slot, the second
				or third will likely be free for reentry after ejection.
			Also, flushing is good when reprobe chains are getting full."
	| probe hash primitiveIndex |
	<inline: false>
	hash := objectMemory methodCacheHashOf: messageSelector with: (objectMemory classTagForClass: classObj).  "shift drops low-order zeros from addresses"
	(objectMemory isOopCompiledMethod: newMethod)
		ifTrue:
			[primitiveIndex := self primitiveIndexOf: newMethod.
			 primitiveFunctionPointer := self functionPointerFor: primitiveIndex inClass: classObj]
		ifFalse:
			[self assert: ((objectMemory isNonImmediate: newMethod)
						  and: [objectMemory isForwarded: newMethod]) not.
			 primitiveFunctionPointer := #primitiveInvokeObjectAsMethod].

	0 to: CacheProbeMax-1 do:
		[:p | probe := (hash >> p) bitAnd: MethodCacheMask.
		(methodCache at: probe + MethodCacheSelector) = 0 ifTrue:
			["Found an empty entry -- use it"
			methodCache at: probe + MethodCacheSelector put: messageSelector.
			methodCache at: probe + MethodCacheClass put: (objectMemory classTagForClass: classObj).
			methodCache at: probe + MethodCacheMethod put: newMethod.
			methodCache at: probe + MethodCachePrimFunction put: (self cCoerce: primitiveFunctionPointer to: #'sqIntptr_t').
			lastMethodCacheProbeWrite := probe. "this for primitiveExternalMethod"
			^self]].

	"OK, we failed to find an entry -- install at the first slot..."
	probe := hash bitAnd: MethodCacheMask.  "first probe"
	methodCache at: probe + MethodCacheSelector put: messageSelector.
	methodCache at: probe + MethodCacheClass put: (objectMemory classTagForClass: classObj).
	methodCache at: probe + MethodCacheMethod put: newMethod.
	methodCache at: probe + MethodCachePrimFunction put: (self cCoerce: primitiveFunctionPointer to: #'sqIntptr_t').
	lastMethodCacheProbeWrite := probe. "this for primitiveExternalMethod"

	"...and zap the following entries"
	1 to: CacheProbeMax-1 do:
		[:p | probe := (hash >> p) bitAnd: MethodCacheMask.
		methodCache at: probe + MethodCacheSelector put: 0]
]

{ #category : #'plugin support' }
StackInterpreter >> addToExternalPrimitiveTable: functionAddress [
	"Add the given function address to the external primitive table and return the index where it's stored. This function doesn't need to be fast since it is only called when an external primitive has been looked up (which takes quite a bit of time itself). So there's nothing specifically complicated here.
	Note: Return index will be one-based (ST convention)"

	<var: #functionAddress declareC: 'void *functionAddress'>

	externalPrimitiveTableFirstFreeIndex to: MaxExternalPrimitiveTableSize-1 do:
		[ :i |
		(externalPrimitiveTable at: i) = 0 ifTrue:
			[externalPrimitiveTable at: i put: functionAddress.
			^externalPrimitiveTableFirstFreeIndex := i+1]].
	"if no space left, return zero so it'll looked up again"
	^0
]

{ #category : #'debug support' }
StackInterpreter >> addressCouldBeClassObj: maybeClassObj [
	"Answer if maybeClassObj looks like a class object"
	<inline: false>
	^(objectMemory addressCouldBeObj: maybeClassObj)
	  and: [self objCouldBeClassObj: maybeClassObj]
]

{ #category : #'debug support' }
StackInterpreter >> allAccessibleObjectsOkay [
	"Ensure that all accessible objects in the heap are okay."
	| ok |
	ok := true.
	objectMemory allObjectsDoSafely:
		[:oop|
		ok := ok & (self okayFields: oop)].
	^ok
]

{ #category : #'stack pages' }
StackInterpreter >> allOnesAsCharStar [
	<inline: true>
	^(self
		cCoerceSimple: (objectMemory wordSize = 8
								ifTrue: [-1 signedIntToLong64]
								ifFalse: [-1 signedIntToLong])
		to: #'char *')
]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> allocateLowcodeCalloutState [
	<option: #LowcodeVM>
	| calloutStateSize |
	calloutStateSize := self sizeof: #'sqLowcodeCalloutState'.
	shadowCallStackPointer := self cCoerce: ((self cCoerce: shadowCallStackPointer - calloutStateSize to: 'size_t') bitAnd: -16) to: 'char*'.
	lowcodeCalloutState := self cCoerce: shadowCallStackPointer to: #'sqLowcodeCalloutState*'.
	
]

{ #category : #'image save/restore' }
StackInterpreter >> allocateMemory: heapSize minimum: minimumMemory imageFile: fileStream headerSize: headerSize [
	"Translate to C function call with (case sensitive) camelCase. The purpose of this
	 method is to document the translation.
	 The default implementation is sqAllocateMemory(minimumMemory, heapSize). This may
	 be redefined to make use of the image file and header size parameters for efficient
	 implementation with mmap().
	 See CCodeGenerator>>writeDefaultMacrosOn: which specifies a default implementation."

	<inline: true>
	<returnTypeC: #'char *'>
	<var: #fileStream type: #sqImageFile>
	^self pointerForOop: (self
							allocateMemory: heapSize
							Minimum: minimumMemory
							ImageFile: fileStream
							HeaderSize: headerSize)
]

{ #category : #'image save/restore' }
StackInterpreter >> allocateMemory: heapSize minimum: minimumMemory imageFile: fileStream headerSize: headerSize desiredPosition: desiredBaseAddress [
	"Translate to C function call with (case sensitive) camelCase. The purpose of this
	 method is to document the translation.
	 The default implementation is sqAllocateMemory(minimumMemory, heapSize). This may
	 be redefined to make use of the image file and header size parameters for efficient
	 implementation with mmap().
	 See CCodeGenerator>>writeDefaultMacrosOn: which specifies a default implementation."

	<inline: true>
	<returnTypeC: #'char *'>
	<var: #fileStream type: #sqImageFile>
	^self pointerForOop: (self
							allocateMemory: heapSize
							Minimum: minimumMemory
							ImageFile: fileStream
							HeaderSize: headerSize
							BaseAddress: desiredBaseAddress)
]

{ #category : #'compiled methods' }
StackInterpreter >> alternateHeaderHasPrimitiveFlag: methodHeader [
	<inline: true>
	^methodHeader anyMask: AlternateHeaderHasPrimFlag
]

{ #category : #'compiled methods' }
StackInterpreter >> alternateHeaderNumLiteralsMask [
	<api>
	<cmacro>
	^AlternateHeaderNumLiteralsMask
]

{ #category : #'compiled methods' }
StackInterpreter >> argumentCountOf: methodPointer [
	<api>
	^self argumentCountOfMethodHeader: (objectMemory methodHeaderOf: methodPointer)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> argumentCountOfClosure: closurePointer [
	<api> "for Cogit"
	<inline: true>
	^self quickFetchInteger: ClosureNumArgsIndex ofObject: closurePointer
]

{ #category : #'compiled methods' }
StackInterpreter >> argumentCountOfMethodHeader: header [
	<api>
	^header >> MethodHeaderArgCountShift bitAnd: 16rF
]

{ #category : #utilities }
StackInterpreter >> arrayValueOf: arrayOop [
	"Return the address of first indexable field of resulting array object, or fail if
	 the instance variable does not contain an indexable bytes or words object."
	"Note: May be called by translated primitive code."

	<returnTypeC: #'void *'>
	(objectMemory isWordsOrBytes: arrayOop) ifTrue:
		[^self cCoerceSimple: (self pointerForOop: arrayOop + objectMemory baseHeaderSize) to: #'void *'].
	self primitiveFail
]

{ #category : #'indexing primitive support' }
StackInterpreter >> asciiOfCharacter: characterObj [  "Returns an integer object"

	<inline: false>
	(objectMemory isCharacterObject: characterObj) ifTrue:
		[^CharacterTable
			ifNil: [objectMemory integerObjectOfCharacterObject: characterObj]
			ifNotNil: [objectMemory fetchPointer: CharacterValueIndex ofObject: characterObj]].
	self primitiveFailFor: PrimErrBadArgument.
	^ConstZero  "in case some code needs an int"
]

{ #category : #utilities }
StackInterpreter >> assertClassOf: oop is: classOop [
	"Succeed if oop is an instance of the given class. Fail if the object is an integer."
	| ok |
	<inline: true>
	ok := objectMemory isNonImmediate: oop.
	ok ifTrue:
		[ok := objectMemory isClassOfNonImm: oop equalTo: classOop].
	self success: ok
]

{ #category : #'debug support' }
StackInterpreter >> assertValidExecutionPointe: lip r: lifp s: lisp [
	<inline: true>
	<var: #lip type: #'usqInt'>
	<var: #lifp type: #'char *'>
	<var: #lisp type: #'char *'>
	self assertValidExecutionPointe: lip r: lifp s: lisp imbar: (self isMachineCodeFrame: lifp) not line: #'__LINE__'
]

{ #category : #'debug support' }
StackInterpreter >> assertValidExecutionPointe: lip r: lfp s: lsp imbar: inInterpreter line: ln [
	<var: #lip type: #usqInt>
	<var: #lfp type: #'char *'>
	<var: #lsp type: #'char *'>
	self assert: inInterpreter l: ln.
	self assert: stackPage = stackPages mostRecentlyUsedPage l: ln.
	self assertValidStackLimits: ln.
	self assert: (stackPage addressIsInPage: lfp) l: ln.
	self assert: lsp < lfp l: ln.
	self assert: lfp > lsp l: ln.
	self assert: lsp >= (stackPage realStackLimit - self stackLimitOffset) l: ln.
	self assert: (lfp - lsp) / objectMemory bytesPerOop < LargeContextSlots l: ln.
	self assert: (self validInstructionPointer: lip inFrame: lfp) l: ln.
	self assert: ((self frameIsBlockActivation: lfp)
				or: [(self pushedReceiverOrClosureOfFrame: lfp) = (self frameReceiver: lfp)])
		l: ln.
	self assert: method = (self frameMethod: lfp) l: ln.
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [self assert: (self methodUsesAlternateBytecodeSet: method) = (bytecodeSetSelector = 256)  l: ln].
]

{ #category : #'debug support' }
StackInterpreter >> assertValidExecutionPointers [
	<doNotGenerate> "simulator only"
	self assertValidExecutionPointe: localIP r: localFP s: localSP
]

{ #category : #'process primitive support' }
StackInterpreter >> assertValidStackLimits: ln [
	<returnTypeC: #void>
	"Order in the stackLimit checks is important because stackLimit is smashed by
	 interrupts. So always check for unsmashed value first to avoid race condition."
	self assert: (stackLimit = stackPage realStackLimit
				or: [stackLimit = self allOnesAsCharStar])
		l: ln.
	self assert: (stackPage stackLimit = stackPage realStackLimit
				or: [stackPage stackLimit = self allOnesAsCharStar])
		l: ln
]

{ #category : #'return bytecodes' }
StackInterpreter >> baseFrameReturn [
	"Return from a baseFrame (the bottom frame in a stackPage).  The context to
	 return to (which may be married) is stored in the saved instruction pointer slot."
	<inline: true>
	| contextToReturnTo isAContext theFP theSP thePage frameAbove |
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #frameAbove type: #'char *'>
	contextToReturnTo := self frameCallerContext: localFP.
	isAContext := objectMemory isContext: contextToReturnTo.
	(isAContext
	 and: [self isStillMarriedContext: contextToReturnTo])
		ifTrue:
			[theFP := self frameOfMarriedContext: contextToReturnTo.
			 thePage := stackPages stackPageFor: theFP.
			 theFP = thePage headFP
				ifTrue:
					[theSP := thePage headSP.
					 stackPages freeStackPageNoAssert: stackPage "for a short time invariant is violated; assert follows"]
				ifFalse:
					["Returning to some interior frame, presumably because of a sender assignment.
					  Move the frames above to another page (they may be in use, e.g. via coroutining).
					  Make the interior frame the top frame."
					 frameAbove := self findFrameAbove: theFP inPage: thePage.
					 "Reuse the page we're exiting, which avoids allocating a new page and
					  manipulating the page list to mark the page we're entering as least recently
					  used (to avoid it being deallocated when allocating a new page)."
					 self moveFramesIn: thePage through: frameAbove toPage: stackPage.
					 theFP := thePage headFP.
					 theSP := thePage headSP]]
		ifFalse:
			[(isAContext
			  and: [objectMemory isIntegerObject: (objectMemory fetchPointer: InstructionPointerIndex ofObject: contextToReturnTo)]) ifFalse:
				[^self internalCannotReturn: localReturnValue].
			 thePage := self makeBaseFrameFor: contextToReturnTo.
			 theFP := thePage headFP.
			 theSP := thePage headSP.
			 stackPages freeStackPageNoAssert: stackPage "for a short time invariant is violated; assert follows"].
	self setStackPageAndLimit: thePage.
	self assert: (stackPages stackPageFor: theFP) = stackPage.
	localSP := theSP.
	localFP := theFP.
	self setMethod: (self frameMethod: localFP).
	localIP := self pointerForOop: self internalStackTop.
	self internalStackTopPut: localReturnValue.
	self assert: (self checkIsStillMarriedContext: contextToReturnTo currentFP: localFP).
	^self fetchNextBytecode
]

{ #category : #'frame access' }
StackInterpreter >> bereaveAllMarriedContextsForSnapshotFlushingExternalPrimitivesIf: flushExtPrims [
	"Enumerate all contexts and convert married contexts to widowed contexts so
	 that the snapshot contains only single contexts.  This allows the test for being
	 married to avoid checking for a context's frame pointer being in bounds.  If
	 flushExtPrims is true, flush references to external primitives in methods."
	objectMemory allObjectsDo:
		[:obj| | fmt |
		fmt := objectMemory formatOf: obj.
		(fmt = objectMemory indexablePointersFormat
		  and: [objectMemory isContextNonImm: obj]) ifTrue:
			[self makeContextSnapshotSafe: obj].
		 "Clean out external functions from compiled methods"
		 (flushExtPrims
		  and: [objectMemory isCompiledMethodFormat: fmt]) ifTrue:
			[self flushExternalPrimitiveOf: obj]]
]

{ #category : #'sista inline primitives - binary' }
StackInterpreter >> binaryAtInlinePrimitive: primIndex [
	<option: #SistaVM>
	| result rec argIntAdjusted top |
	rec := self internalStackValue: 1.
	top := self internalStackTop.
	self deny: ((objectMemory isOopForwarded: rec) or: [(objectMemory isImmediate: rec)]).
	self assert: (objectMemory isIntegerObject: top).
	argIntAdjusted := (objectMemory integerValueOf: top) - 1.
	self assert: argIntAdjusted >= 0.
	primIndex caseOf: {
		"2064	pointerAt:
		Pointer object (Fixed sized or not) and not a context, Smi =>  (1-based, optimised if arg1 is a constant)"
		[64]	->	[self assert: (objectMemory isPointers: rec).
					 self assert: argIntAdjusted < (objectMemory numSlotsOfAny: rec).
					 result := objectMemory fetchPointer: argIntAdjusted ofObject: rec.].
		"2065	maybeContextPointerAt:
		 Pointer object (Fixed sized or not), Smi =>  (1-based, optimised if arg1 is a constant)"
		[65]	->	[ ((objectMemory isContextNonImm: rec) 
						 and: [self isMarriedOrWidowedContext: rec])
							ifTrue:
								[self externalizeIPandSP.
								 result := self externalInstVar: argIntAdjusted ofContext: rec.
								 self internalizeIPandSP]
					ifFalse: [result := objectMemory fetchPointer: argIntAdjusted ofObject: rec]
			].
		"2066	byteAt:
		 byte object, Smi => 8 bits unsigned Smi (1-based, optimised if arg1 is a constant)"
		[66]	->	[self assert: (objectMemory isBytes: rec).
					 self assert: argIntAdjusted < (objectMemory numBytesOf: rec).
					 result := objectMemory integerObjectOf: (objectMemory fetchByte: argIntAdjusted ofObject: rec)].
		"2067	shortAt:
		short object, Smi => 16 bits unsigned Smi (1-based, optimised if arg1 is a constant)"
		[67]	->	[self assert: (objectMemory isShorts: rec).
					 self assert: argIntAdjusted < (objectMemory num16BitUnitsOf: rec).
					 result := objectMemory integerObjectOf: (objectMemory fetchShort16: argIntAdjusted ofObject: rec)].
		"2068	wordAt:
		 word object, Smi => 32 bits unsigned Smi (1-based, optimised if arg1 is a constant)."
		[68]	->	[self assert: (objectMemory isWords: rec).
					 self assert: argIntAdjusted < (objectMemory num32BitUnitsOf: rec).
					 result := self positive32BitIntegerFor: (objectMemory fetchLong32: argIntAdjusted ofObject: rec)].
		"2069	doubleWordAt:
		 double word object, Smi => 64 bits unsigned Smi or LargePositiveInteger (1-based, optimised if arg1 is a constant)"
		[69]	->	[self assert: (objectMemory isLong64s: rec).
					 self assert: argIntAdjusted < (objectMemory num64BitUnitsOf: rec).
					 result := self positive64BitIntegerFor: (objectMemory fetchLong64: argIntAdjusted ofObject: rec)].}.
		self internalPop: 1; internalStackTopPut: result
]

{ #category : #'sista inline primitives - binary' }
StackInterpreter >> binaryCompInlinePrimitive: primIndex [
	<option: #SistaVM>
	| result |
	self assert: (primIndex between: 38 and: 39).
	primIndex caseOf: {
		"2038	rawEqualsEquals:
		 not a forwarder, not a forwarder => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)"
		[38]	->	[result := ((self internalStackValue: 1) = self internalStackTop).].
		"2039	rawNotEqualsEquals:
		 not a forwarder, not a forwarder => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)"
		[39]	->	[result := ((self internalStackValue: 1) ~= self internalStackTop)].
	}.
	self internalPop: 1; internalStackTopPut: (objectMemory booleanObjectOf: result)
]

{ #category : #'sista inline primitives - binary' }
StackInterpreter >> binaryInlinePrimitive: primIndex [
	<option: #SistaVM>
	"Bulk comments: each sub-method has its own comment with the specific case.
	2000	+
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant)
	2001	-
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant)
	2002	*
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant)
	2003	/
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant)
	2004	//
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant)
	2005	\
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant)
	2006	quo:
	Smi, Smi => Smi (no overflow, optimised if one operand is a constant)
	2016	bitAnd:
	Smi, Smi => Smi (optimised if one operand is a constant)
	2017	bitOr:
	Smi, Smi => Smi (optimised if one operand is a constant)
	2018	bitXor:
	Smi, Smi => Smi (optimised if one operand is a constant)
	2019	bitShiftLeft:
	Smi greater or equal to 0, Smi greater or equal to 0 => Smi (no overflow, optimised if arg1 is a constant)
	2020	bitShiftRight:
	Smi, Smi greater or equal to 0 => Smi (optimised if arg1 is a constant)
	2032	>
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2033	<
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2034	>=
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2035	<=
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2036	=
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2037	~=
	Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2038	rawEqualsEquals:
	not a forwarder, not a forwarder => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2039	rawNotEqualsEquals:
	not a forwarder, not a forwarder => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)
	2048	rawNew:
	literal which is a fixed-sized behavior, Smi => instance of receiver, fields nilled out (optimised if arg1 is a constant)
	2049	rawNewNoInit:
	literal which is a fixed-sized behavior, Smi => instance of receiver (Fields of returned value contain undefined data, optimised if arg1 is a constant)
	2064	pointerAt:
	Pointer object (Fixed sized or not) and not a context, Smi =>  (1-based, optimised if arg1 is a constant)
	2065	maybeContextPointerAt:
	Pointer object (Fixed sized or not), Smi =>  (1-based, optimised if arg1 is a constant)
	2066	byteAt:
	byte object, Smi => 8 bits unsigned Smi (1-based, optimised if arg1 is a constant)
	2067	shortAt:
	short object, Smi => 16 bits unsigned Smi (1-based, optimised if arg1 is a constant)
	2068	wordAt:
	word object, Smi => 32 bits unsigned Smi (1-based, optimised if arg1 is a constant)
	2069	doubleWordAt:
	double word object, Smi => 64 bits unsigned Smi or LargePositiveInteger (1-based, optimised if arg1 is a constant)"
	primIndex <= 6 ifTrue: [^self binarySmiArithmeticInlinePrimitive: primIndex].
	primIndex < 16 ifTrue: [^self unknownInlinePrimitive].
	primIndex <= 20 ifTrue: [^self binarySmiBitInlinePrimitive: primIndex].
	primIndex < 32 ifTrue: [^self unknownInlinePrimitive].
	primIndex <= 37 ifTrue: [^self binarySmiCompInlinePrimitive: primIndex].
	primIndex <= 39 ifTrue: [^self binaryCompInlinePrimitive: primIndex].
	primIndex < 48 ifTrue: [^self unknownInlinePrimitive].
	primIndex <= 49 ifTrue: [^self binaryNewInlinePrimitive: primIndex].
	primIndex < 64 ifTrue: [^self unknownInlinePrimitive].
	primIndex <= 69 ifTrue: [^self binaryAtInlinePrimitive: primIndex].
	self unknownInlinePrimitive
]

{ #category : #'sista inline primitives - binary' }
StackInterpreter >> binaryNewInlinePrimitive: primIndex [
	"2048	rawNew:
	literal which is a variable-sized behavior, Smi => instance of receiver, fields nilled/zeroed out (optimised if arg1 is a constant)
	2049	rawNewNoInit:
	literal which is a variable-sized behavior, Smi => instance of receiver (Fields of returned value contain undefined data, optimised if arg1 is a constant)
	
	WARNING: In the interpreter version, fields are always initialized."
	| classObj result size top |
	self assert: (primIndex between: 48 and: 49).
	top := self internalStackTop.
	classObj := self internalStackValue: 1.
	self assert: ((objectMemory isNonImmediate: classObj) and: [self objCouldBeClassObj: classObj]).
	self assert: (objectMemory isIntegerObject: top).
	size := self positiveMachineIntegerValueOf: top.
	result := objectMemory instantiateClass: classObj indexableSize: size.
	self internalPop: 1; internalStackTopPut: result
]

{ #category : #'sista inline primitives - binary' }
StackInterpreter >> binarySmiArithmeticInlinePrimitive: primIndex [
	<option: #SistaVM>
	| result recInt argInt rcvr top |
	rcvr := self internalStackValue: 1.
	top := self internalStackTop.
	self assert: primIndex <= 6.
	self assert: (objectMemory isIntegerObject: rcvr).
	self assert: (objectMemory isIntegerObject: top).
	recInt := objectMemory integerValueOf: rcvr.
	argInt := objectMemory integerValueOf: top.
	primIndex caseOf: {
		"2000	+
		 Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[0]	->	[result := recInt + argInt].
		"2001	-
		 Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[1]	->	[result := recInt - argInt].
		"2002	*
		 Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[2]	->	[result := recInt * argInt].
		"2003	/
		 Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[3]	->	[result := recInt / argInt].
		"2004	//
		 Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[4]	->	[result := recInt // argInt].
		"2005	\
		 Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[5]	->	[result := recInt \\ argInt].
		"2006	quo:
		 Smi, Smi => Smi (no overflow, optimised if one operand is a constant)"
		[6]	->	[result := self quot: recInt ient: argInt].
	}.
	self internalPop: 1; internalStackTopPutIntegerObjectOf: result
]

{ #category : #'sista inline primitives - binary' }
StackInterpreter >> binarySmiBitInlinePrimitive: primIndex [
	<option: #SistaVM>
	| result recInt argInt rcvr top |
	rcvr := self internalStackValue: 1.
	top := self internalStackTop.
	self assert: (primIndex between: 16 and: 20).
	self assert: (objectMemory isIntegerObject: rcvr).
	self assert: (objectMemory isIntegerObject: top).
	recInt := objectMemory integerValueOf: rcvr.
	argInt := objectMemory integerValueOf: top.
	primIndex caseOf: {
		"2016	bitAnd:
		 Smi, Smi => Smi (optimised if one operand is a constant)"
		[16]	->	[result := recInt bitAnd: argInt].
		"2017	bitOr:
		 Smi, Smi => Smi (optimised if one operand is a constant)"
		[17]	->	[result := recInt bitOr: argInt].
		"2018	bitXor:
		 Smi, Smi => Smi (optimised if one operand is a constant)"
		[18]	->	[result := recInt bitXor: argInt].
		"2019	bitShiftLeft:
		 Smi greater or equal to 0, Smi greater or equal to 0 => Smi (no overflow, optimised if arg1 is a constant)"
		[19]	->	[self assert: recInt >= 0.
					 self assert: argInt >= 0.
					 result := recInt << argInt].
		"2020	bitShiftRight:
		 Smi, Smi greater or equal to 0 => Smi (optimised if arg1 is a constant)"
		[20]	->	[self assert: argInt >= 0.
					 result := recInt >> argInt].
	}.
	self internalPop: 1; internalStackTopPutIntegerObjectOf: result
]

{ #category : #'sista inline primitives - binary' }
StackInterpreter >> binarySmiCompInlinePrimitive: primIndex [
	<option: #SistaVM>
	| result top rcvr |
	self assert: (primIndex between: 32 and: 37).
	rcvr := self internalStackValue: 1.
	top := self internalStackTop.
	self assert: (objectMemory isIntegerObject: rcvr).
	self assert: (objectMemory isIntegerObject: top).
	primIndex caseOf: {
		"2032	>
		Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)"
		[32]	->	[result := rcvr > top].
		"2033	<
		Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)"
		[33]	->	[result := rcvr < top].
		"2034	>=
		Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)"
		[34]	->	[result := rcvr >= top].
		"2035	<=
		Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)"
		[35]	->	[result :=rcvr <= top].
		"2036	=
		Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)"
		[36]	->	[result := (rcvr = top).].
		"2037	~=
		Smi, Smi => Boolean (optimised if one operand is a constant, Pipelined with ifTrue:ifFalse:)"
		[37]	->	[result := (rcvr ~= top)].
	}.
	self internalPop: 1; internalStackTopPut: (objectMemory booleanObjectOf: result)
]

{ #category : #utilities }
StackInterpreter >> booleanCheat: cond [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<inline: true>

	cond
		ifTrue: [self booleanCheatTrue]
		ifFalse: [self booleanCheatFalse]
]

{ #category : #utilities }
StackInterpreter >> booleanCheatFalse [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<sharedCodeInCase: #bytecodePrimGreaterThan>
	| bytecode offset |

	bytecode := self fetchByte.  "assume next bytecode is jumpIfFalse (99%)"
	self internalPop: 2.
	(bytecode < 160 and: [bytecode > 151]) ifTrue:  "short jumpIfFalse"
		[^self jump: bytecode - 151].

	bytecode = 172 ifTrue:  "long jumpIfFalse"
		[offset := self fetchByte.
		^self jump: offset].

	"not followed by a jumpIfFalse; (un)do instruction fetch and push boolean result"
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [currentBytecode := bytecode + bytecodeSetSelector]
		ifFalse: [currentBytecode := bytecode].
	self internalPush: objectMemory falseObject
]

{ #category : #utilities }
StackInterpreter >> booleanCheatFalseSistaV1 [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<sharedCodeInCase: #bytecodePrimGreaterThanSistaV1>
	| bytecode offset |

	bytecode := self fetchByte.  "assume next bytecode is jumpIfFalse (99%)"
	self internalPop: 2.
	(bytecode < 199 and: [bytecode > 191]) ifTrue:  "short jumpIfFalse"
		[^self jump: bytecode - 191].

	bytecode = 239 ifTrue:  "long jumpIfFalse"
		[offset := self fetchByte.
		^self jump: offset].

	"not followed by a jumpIfFalse; (un)do instruction fetch and push boolean result"
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [currentBytecode := bytecode + bytecodeSetSelector]
		ifFalse: [currentBytecode := bytecode].
	self internalPush: objectMemory falseObject
]

{ #category : #utilities }
StackInterpreter >> booleanCheatFalseV4 [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<sharedCodeInCase: #bytecodePrimGreaterThanV4>
	| bytecode offset |

	bytecode := self fetchByte.  "assume next bytecode is jumpIfFalse (99%)"
	self internalPop: 2.
	(bytecode < 216 and: [bytecode > 207]) ifTrue:  "short jumpIfFalse"
		[^self jump: bytecode - 207].

	bytecode = 244 ifTrue:  "long jumpIfFalse"
		[offset := self fetchByte.
		^self jump: offset].

	"not followed by a jumpIfFalse; (un)do instruction fetch and push boolean result"
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [currentBytecode := bytecode + bytecodeSetSelector]
		ifFalse: [currentBytecode := bytecode].
	self internalPush: objectMemory falseObject
]

{ #category : #utilities }
StackInterpreter >> booleanCheatSistaV1: cond [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<inline: true>

	cond
		ifTrue: [self booleanCheatTrueSistaV1]
		ifFalse: [self booleanCheatFalseSistaV1]
]

{ #category : #utilities }
StackInterpreter >> booleanCheatTrue [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<sharedCodeInCase: #bytecodePrimLessThan>
	| bytecode offset |

	bytecode := self fetchByte.  "assume next bytecode is jumpIfFalse (99%)"
	self internalPop: 2.
	(bytecode < 173 and: [bytecode > 151]) ifTrue:
		[bytecode < 160 ifTrue: "short jumpIfFalse 152 - 159"
			[^self fetchNextBytecode].
		bytecode = 172 ifTrue: "long jumpIfFalse"
			[self fetchByte.
			^self fetchNextBytecode].
		bytecode > 167 ifTrue: "long jumpIfTrue 168 - 171"
			[offset := bytecode - 168 << 8 + self fetchByte.
			^self jump: offset]].

	"not followed by a jumpIfFalse; (un)do instruction fetch and push boolean result"
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [currentBytecode := bytecode + bytecodeSetSelector]
		ifFalse: [currentBytecode := bytecode].
	self internalPush: objectMemory trueObject
]

{ #category : #utilities }
StackInterpreter >> booleanCheatTrueSistaV1 [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<sharedCodeInCase: #bytecodePrimLessThanSistaV1>
	| bytecode offset |

	bytecode := self fetchByte.  "assume next bytecode is jumpIfFalse (99%)"
	self internalPop: 2.
	bytecode >= 192 ifTrue:
		[bytecode <= 199 ifTrue: "short jumpIfFalse 192 - 199"
			[^self fetchNextBytecode].
		bytecode = 239 ifTrue: "long jumpIfFalse"
			[self fetchByte.
			^self fetchNextBytecode].
		bytecode = 238 ifTrue: "long jumpIfTrue 238"
			[offset := self fetchByte.
			^self jump: offset]].

	"not followed by a jumpIfFalse; (un)do instruction fetch and push boolean result"
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [currentBytecode := bytecode + bytecodeSetSelector]
		ifFalse: [currentBytecode := bytecode].
	self internalPush: objectMemory trueObject
]

{ #category : #utilities }
StackInterpreter >> booleanCheatTrueV4 [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<sharedCodeInCase: #bytecodePrimLessThanV4>
	| bytecode offset |

	bytecode := self fetchByte.  "assume next bytecode is jumpIfFalse (99%)"
	self internalPop: 2.
	bytecode >= 208 ifTrue:
		[bytecode <= 215 ifTrue: "short jumpIfFalse 208 - 215"
			[^self fetchNextBytecode].
		bytecode = 244 ifTrue: "long jumpIfFalse"
			[self fetchByte.
			^self fetchNextBytecode].
		bytecode = 243 ifTrue: "long jumpIfTrue 243"
			[offset := self fetchByte.
			^self jump: offset]].

	"not followed by a jumpIfFalse; (un)do instruction fetch and push boolean result"
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [currentBytecode := bytecode + bytecodeSetSelector]
		ifFalse: [currentBytecode := bytecode].
	self internalPush: objectMemory trueObject
]

{ #category : #utilities }
StackInterpreter >> booleanCheatV4: cond [
	"cheat the interpreter out of the pleasure of handling the next bytecode IFF it is a jump-on-boolean. Which it is, often enough when the current bytecode is something like bytecodePrimEqual"
	<inline: true>

	cond
		ifTrue: [self booleanCheatTrueV4]
		ifFalse: [self booleanCheatFalseV4]
]

{ #category : #utilities }
StackInterpreter >> booleanValueOf: obj [
"convert true and false (Smalltalk) to true or false(C)"
	obj = objectMemory trueObject ifTrue: [ ^ true ].
	obj = objectMemory falseObject ifTrue: [ ^ false ].
	self success: false.
	^ nil
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimAdd [
	| rcvr arg result |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg)
		ifTrue: [result := (objectMemory integerValueOf: rcvr) + (objectMemory integerValueOf: arg).
				(objectMemory isIntegerValue: result) ifTrue:
					[self internalPop: 2 thenPush: (objectMemory integerObjectOf: result).
					^ self fetchNextBytecode "success"]]
		ifFalse: [self initPrimCall.
				self externalizeIPandSP.
				self primitiveFloatAdd: rcvr toArg: arg.
				self internalizeIPandSP.
				self successful ifTrue: [^ self fetchNextBytecode "success"]].

	messageSelector := self specialSelector: 0.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimAt [
	"BytecodePrimAt will only succeed if the receiver is in the atCache.
	 Otherwise it will fail so that the more general primitiveAt will put it in the
	 cache after validating that message lookup results in a primitive response.
	 Override to insert in the at: cache here.  This is necessary since once there
	 is a compiled at: primitive method (which doesn't use the at: cache) the only
	 way something can get installed in the atCache is here."
	| index rcvr result atIx |
	index := self internalStackTop.
	rcvr := self internalStackValue: 1.
	((objectMemory isNonImmediate: rcvr)
	 and: [objectMemory isIntegerObject: index]) ifTrue:
		[atIx := rcvr bitAnd: AtCacheMask.  "Index into atCache = 4N, for N = 0 ... 7"
		(atCache at: atIx+AtCacheOop) ~= rcvr ifTrue:
			[lkupClassTag := objectMemory fetchClassTagOfNonImm: rcvr.
			 messageSelector := self specialSelector: 16.
			 (self lookupInMethodCacheSel: messageSelector classTag: lkupClassTag) ifFalse:
				[argumentCount := 1.
				 ^self commonSendOrdinary].
			 primitiveFunctionPointer == #primitiveAt
				ifTrue: [self install: rcvr inAtCache: atCache at: atIx string: false]
				ifFalse:
					[primitiveFunctionPointer == #primitiveStringAt
						ifTrue: [self install: rcvr inAtCache: atCache at: atIx string: true]
						ifFalse:
							[argumentCount := 1.
							 ^self commonSendOrdinary]]].
		 self successful ifTrue:
			[result := self commonVariable: rcvr at: (objectMemory integerValueOf: index) cacheIndex: atIx].
		 self successful ifTrue:
			[self fetchNextBytecode.
			 ^self internalPop: 2 thenPush: result].
		 self initPrimCall].

	messageSelector := self specialSelector: 16.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimAtEnd [
	messageSelector := self specialSelector: 21.
	argumentCount := self specialSelectorNumArgs: 21.
	self normalSend.
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimAtPut [
	"BytecodePrimAtPut will only succeed if the receiver is in the atCache.
	Otherwise it will fail so that the more general primitiveAtPut will put it in the
	cache after validating that message lookup results in a primitive response.
	 Override to insert in the atCache here.  This is necessary since once there
	 is a compiled at:[put:] primitive method (which doesn't use the at: cache) the
	 only way something can get installed in the atCache is here."
	| index rcvr atIx value correctRcvr |
	value := self internalStackTop.
	index := self internalStackValue: 1.
	rcvr := self internalStackValue: 2.
	self cppIf: IMMUTABILITY 
		ifTrue: [ correctRcvr := objectMemory isOopMutable: rcvr ]
		ifFalse: [ correctRcvr := objectMemory isNonImmediate: rcvr ].
	(correctRcvr
	 and: [objectMemory isIntegerObject: index]) ifTrue:
		[atIx := (rcvr bitAnd: AtCacheMask) + AtPutBase.  "Index into atPutCache"
		 (atCache at: atIx+AtCacheOop) ~= rcvr ifTrue:
			[lkupClassTag := objectMemory fetchClassTagOfNonImm: rcvr.
			 messageSelector := self specialSelector: 17.
			 (self lookupInMethodCacheSel: messageSelector classTag: lkupClassTag) ifFalse:
				[argumentCount := 2.
				 ^self commonSendOrdinary].
			 primitiveFunctionPointer == #primitiveAtPut
				ifTrue: [self install: rcvr inAtCache: atCache at: atIx string: false]
				ifFalse:
					[primitiveFunctionPointer == #primitiveStringAtPut
						ifTrue: [self install: rcvr inAtCache: atCache at: atIx string: true]
						ifFalse:
							[argumentCount := 2.
							 ^self commonSendOrdinary]]].
		 self successful ifTrue:
			[self commonVariable: rcvr at: (objectMemory integerValueOf: index) put: value cacheIndex: atIx].
		 self successful ifTrue:
			[self fetchNextBytecode.
			 ^self internalPop: 3 thenPush: value].
		 self initPrimCall].

	messageSelector := self specialSelector: 17.
	argumentCount := 2.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimBitAnd [
	| rcvr arg |
	arg := self internalStackTop.
	rcvr := self internalStackValue: 1.
	((objectMemory isIntegerObject: arg)
	 and: [objectMemory isIntegerObject: rcvr]) ifTrue:
		[self internalPop: 2 thenPush: (arg bitAnd: rcvr).
		 ^self fetchNextBytecode "success"].

	self initPrimCall.
	self externalizeIPandSP.
	self primitiveBitAnd.
	self internalizeIPandSP.
	self successful ifTrue:
		[^self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 14.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimBitOr [
	| rcvr arg |
	arg := self internalStackTop.
	rcvr := self internalStackValue: 1.
	((objectMemory isIntegerObject: arg)
	 and: [objectMemory isIntegerObject: rcvr]) ifTrue:
		[self internalPop: 2 thenPush: (arg bitOr: rcvr).
		 ^self fetchNextBytecode "success"].

	self initPrimCall.
	self externalizeIPandSP.
	self primitiveBitOr.
	self internalizeIPandSP.
	self successful ifTrue:
		[^self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 15.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimBitShift [

	self initPrimCall.
	self externalizeIPandSP.
	self primitiveBitShift.
	self internalizeIPandSP.
	self successful ifTrue: [^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 12.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimClass [
	| rcvr |
	rcvr := self internalStackTop.
	(objectMemory isOopForwarded: rcvr) ifTrue:
		[rcvr := self handleSpecialSelectorSendFaultFor: rcvr].
	self internalStackTopPut: (objectMemory fetchClassOf: rcvr).
	self fetchNextBytecode
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimDiv [
	| quotient |
	self initPrimCall.
	quotient := self doPrimitiveDiv: (self internalStackValue: 1) by: (self internalStackValue: 0).
	self successful ifTrue: [self internalPop: 2 thenPush: (objectMemory integerObjectOf: quotient).
		^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 13.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimDivide [
	| rcvr arg result |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg)
		ifTrue: [rcvr := objectMemory integerValueOf: rcvr.
			arg := objectMemory integerValueOf: arg.
			(arg ~= 0 and: [rcvr \\ arg = 0])
				ifTrue: [result := rcvr // arg.
					"generates C / operation"
					(objectMemory isIntegerValue: result)
						ifTrue: [self internalPop: 2 thenPush: (objectMemory integerObjectOf: result).
							^ self fetchNextBytecode"success"]]]
		ifFalse: [self initPrimCall.
			self externalizeIPandSP.
			self primitiveFloatDivide: rcvr byArg: arg.
			self internalizeIPandSP.
			self successful ifTrue: [^ self fetchNextBytecode"success"]].

	messageSelector := self specialSelector: 9.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimDo [

	messageSelector := self specialSelector: 27.
	argumentCount := self specialSelectorNumArgs: 27.
	self normalSend.

]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimEqual [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue: [^self booleanCheat: rcvr = arg].

	self initPrimCall.
	aBool := self primitiveFloatEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 6.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimEqualSistaV1 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue: [^self booleanCheatSistaV1: rcvr = arg].

	self initPrimCall.
	aBool := self primitiveFloatEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheatSistaV1: aBool].

	messageSelector := self specialSelector: 6.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimEqualV4 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue: [^self booleanCheatV4: rcvr = arg].

	self initPrimCall.
	aBool := self primitiveFloatEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheatV4: aBool].

	messageSelector := self specialSelector: 6.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimGreaterOrEqual [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheat: rcvr >= arg]
			inSmalltalk: [self booleanCheat: (objectMemory integerValueOf: rcvr) >= (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatGreaterOrEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 5.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimGreaterOrEqualSistaV1 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheatSistaV1: rcvr >= arg]
			inSmalltalk: [self booleanCheatSistaV1: (objectMemory integerValueOf: rcvr) >= (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatGreaterOrEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheatSistaV1: aBool].

	messageSelector := self specialSelector: 5.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimGreaterOrEqualV4 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheatV4: rcvr >= arg]
			inSmalltalk: [self booleanCheatV4: (objectMemory integerValueOf: rcvr) >= (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatGreaterOrEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheatV4: aBool].

	messageSelector := self specialSelector: 5.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimGreaterThan [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheat: rcvr > arg]
			inSmalltalk: [self booleanCheat: (objectMemory integerValueOf: rcvr) > (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatGreater: rcvr thanArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 3.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimGreaterThanSistaV1 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheatSistaV1: rcvr > arg]
			inSmalltalk: [self booleanCheatSistaV1: (objectMemory integerValueOf: rcvr) > (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatGreater: rcvr thanArg: arg.
	self successful ifTrue: [^self booleanCheatSistaV1: aBool].

	messageSelector := self specialSelector: 3.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimGreaterThanV4 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheatV4: rcvr > arg]
			inSmalltalk: [self booleanCheatV4: (objectMemory integerValueOf: rcvr) > (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatGreater: rcvr thanArg: arg.
	self successful ifTrue: [^self booleanCheatV4: aBool].

	messageSelector := self specialSelector: 3.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimIdentical [
	| rcvr arg |
	rcvr := self internalStackValue: 1.
	(objectMemory isOopForwarded: rcvr) ifTrue:
		[rcvr := self handleSpecialSelectorSendFaultFor: rcvr].
	arg := self internalStackValue: 0.
	(objectMemory isOopForwarded: arg) ifTrue:
		[arg := self handleSpecialSelectorSendFaultFor: arg].
	self booleanCheat: rcvr = arg
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimIdenticalSistaV1 [
	| rcvr arg |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory isOopForwarded: rcvr) ifTrue:
		[rcvr := self handleSpecialSelectorSendFaultFor: rcvr].
	(objectMemory isOopForwarded: arg) ifTrue:
		[arg := self handleSpecialSelectorSendFaultFor: arg].
	self booleanCheatSistaV1: rcvr = arg
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimIdenticalV4 [
	| rcvr arg |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory isOopForwarded: rcvr) ifTrue:
		[rcvr := self handleSpecialSelectorSendFaultFor: rcvr].
	(objectMemory isOopForwarded: arg) ifTrue:
		[arg := self handleSpecialSelectorSendFaultFor: arg].
	self booleanCheatV4: rcvr = arg
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimLessOrEqual [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheat: rcvr <= arg]
			inSmalltalk: [self booleanCheat: (objectMemory integerValueOf: rcvr) <= (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatLessOrEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool].

	messageSelector := self specialSelector: 4.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimLessOrEqualSistaV1 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheatSistaV1: rcvr <= arg]
			inSmalltalk: [self booleanCheatSistaV1: (objectMemory integerValueOf: rcvr) <= (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatLessOrEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheatSistaV1: aBool].

	messageSelector := self specialSelector: 4.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimLessOrEqualV4 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheatV4: rcvr <= arg]
			inSmalltalk: [self booleanCheatV4: (objectMemory integerValueOf: rcvr) <= (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatLessOrEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheatV4: aBool].

	messageSelector := self specialSelector: 4.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimLessThan [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheat: rcvr < arg]
			inSmalltalk: [self booleanCheat: (objectMemory integerValueOf: rcvr) < (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatLess: rcvr thanArg: arg.
	self successful ifTrue: [^ self booleanCheat: aBool].

	messageSelector := self specialSelector: 2.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimLessThanSistaV1 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheatSistaV1: rcvr < arg]
			inSmalltalk: [self booleanCheatSistaV1: (objectMemory integerValueOf: rcvr) < (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatLess: rcvr thanArg: arg.
	self successful ifTrue: [^ self booleanCheatSistaV1: aBool].

	messageSelector := self specialSelector: 2.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimLessThanV4 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue:
		["The C code can avoid detagging since tagged integers are still signed.
		 But this means the simulator must override to do detagging."
		^self cCode: [self booleanCheatV4: rcvr < arg]
			inSmalltalk: [self booleanCheatV4: (objectMemory integerValueOf: rcvr) < (objectMemory integerValueOf: arg)]].

	self initPrimCall.
	aBool := self primitiveFloatLess: rcvr thanArg: arg.
	self successful ifTrue: [^ self booleanCheatV4: aBool].

	messageSelector := self specialSelector: 2.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimMakePoint [
	"Inline primitiveMakePoint for the benefit of the interpreter. Externalizing the
	 sp & fp, then internalizing and testign for primitive failure add much overhead.
	 So simply inline the relatively small ammount of code directly."
	| rcvr arg pt |
	rcvr := self internalStackValue: 1.
	arg := self internalStackTop.
	((objectMemory isFloatOrInt: rcvr)
	 and: [objectMemory isFloatOrInt: arg]) ifTrue:
		[pt := objectMemory eeInstantiateSmallClass: (objectMemory splObj: ClassPoint) numSlots: YIndex + 1.
		 objectMemory "No need to check since new object is always new."
			storePointerUnchecked: XIndex ofObject: pt withValue: rcvr;
			storePointerUnchecked: YIndex ofObject: pt withValue: arg.
		 self internalPop: 2 thenPush: pt.
		 ^self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 11.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimMod [
	| mod |
	self initPrimCall.
	mod := self doPrimitiveMod: (self internalStackValue: 1) by: (self internalStackValue: 0).
	self successful ifTrue:
		[self internalPop: 2 thenPush: (objectMemory integerObjectOf: mod).
		^ self fetchNextBytecode "success"].

	messageSelector := self specialSelector: 10.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimMultiply [
	| rcvr arg result overflow oop |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg)
		ifTrue: [rcvr := objectMemory integerValueOf: rcvr.
				arg := objectMemory integerValueOf: arg.
				overflow := rcvr > 0
							ifTrue:  [arg > 0
								ifTrue: [rcvr > (objectMemory maxSmallInteger / arg)]
								ifFalse: [arg < (objectMemory minSmallInteger / rcvr)]]
							ifFalse: [arg > 0
								ifTrue: [rcvr < (objectMemory minSmallInteger / arg)]
								ifFalse: [(rcvr < 0) and: [arg < (objectMemory maxSmallInteger / rcvr)]]].
				overflow
					ifFalse:
						[result := rcvr * arg.
						oop := objectMemory integerObjectOf: result.
      					self internalPop: 2 thenPush: oop.
						^self fetchNextBytecode "success"]]
		ifFalse: [self initPrimCall.
				self externalizeIPandSP.
				self primitiveFloatMultiply: rcvr byArg: arg.
				self internalizeIPandSP.
				self successful ifTrue: [^ self fetchNextBytecode "success"]].

	messageSelector := self specialSelector: 8.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNew [

	messageSelector := self specialSelector: 28.
	argumentCount := 0.
	self normalSend.

]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNewWithArg [

	messageSelector := self specialSelector: 29.
	argumentCount := 1.
	self normalSend.

]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNext [
	messageSelector := self specialSelector: 19.
	argumentCount := self specialSelectorNumArgs: 19.
	self normalSend.
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNextPut [
	messageSelector := self specialSelector: 20.
	argumentCount := self specialSelectorNumArgs: 20.
	self normalSend.
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNotEqual [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue: [^self booleanCheat: rcvr ~= arg].

	self initPrimCall.
	aBool := self primitiveFloatEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheat: aBool not].

	messageSelector := self specialSelector: 7.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNotEqualSistaV1 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue: [^self booleanCheatSistaV1: rcvr ~= arg].

	self initPrimCall.
	aBool := self primitiveFloatEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheatSistaV1: aBool not].

	messageSelector := self specialSelector: 7.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNotEqualV4 [
	| rcvr arg aBool |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg) ifTrue: [^self booleanCheatV4: rcvr ~= arg].

	self initPrimCall.
	aBool := self primitiveFloatEqual: rcvr toArg: arg.
	self successful ifTrue: [^self booleanCheatV4: aBool not].

	messageSelector := self specialSelector: 7.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNotIdentical [
	| rcvr arg |
	rcvr := self internalStackValue: 1.
	(objectMemory isOopForwarded: rcvr) ifTrue:
		[rcvr := self handleSpecialSelectorSendFaultFor: rcvr].
	arg := self internalStackValue: 0.
	(objectMemory isOopForwarded: arg) ifTrue:
		[arg := self handleSpecialSelectorSendFaultFor: arg].
	self booleanCheat: rcvr ~= arg
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNotIdenticalSistaV1 [
	| rcvr arg |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory isOopForwarded: rcvr) ifTrue:
		[rcvr := self handleSpecialSelectorSendFaultFor: rcvr].
	(objectMemory isOopForwarded: arg) ifTrue:
		[arg := self handleSpecialSelectorSendFaultFor: arg].
	self booleanCheatSistaV1: rcvr ~= arg
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimNotIdenticalV4 [
	| rcvr arg |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory isOopForwarded: rcvr) ifTrue:
		[rcvr := self handleSpecialSelectorSendFaultFor: rcvr].
	(objectMemory isOopForwarded: arg) ifTrue:
		[arg := self handleSpecialSelectorSendFaultFor: arg].
	self booleanCheatV4: rcvr ~= arg
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimPointX [

	| rcvr |
	self initPrimCall.
	rcvr := self internalStackTop.
	self assertClassOf: rcvr is: (objectMemory splObj: ClassPoint).
	self successful ifTrue:
		[self internalStackTopPut: (objectMemory fetchPointer: XIndex ofObject: rcvr).
		^self fetchNextBytecode "success"].
	primFailCode := 0.

	messageSelector := self specialSelector: 30.
	argumentCount := 0.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimPointY [

	| rcvr |
	self initPrimCall.
	rcvr := self internalStackTop.
	self assertClassOf: rcvr is: (objectMemory splObj: ClassPoint).
	self successful ifTrue:
		[self internalStackTopPut: (objectMemory fetchPointer: YIndex ofObject: rcvr).
		^self fetchNextBytecode "success"].
	primFailCode := 0.

	messageSelector := self specialSelector: 31.
	argumentCount := 0.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimSize [
	| rcvr sz isString isArray |
	self initPrimCall.
	rcvr := self internalStackTop.

	"Shortcut the mega-lookup for ByteString and Array, the two big consumers of cycles
	 here. Both of these have compact class indices and neither has any added fields."
      isString := self isInstanceOfClassByteString: rcvr.
	isString ifTrue:
		[sz := objectMemory lengthOf: rcvr.
		 self internalStackTopPut: (objectMemory integerObjectOf: sz).
		^self fetchNextBytecode].

      isArray := self isInstanceOfClassArray: rcvr.
	isArray ifTrue:
		[sz := objectMemory lengthOf: rcvr.
		 self internalStackTopPut: (objectMemory integerObjectOf: sz).
		^self fetchNextBytecode].

	messageSelector := self specialSelector: 18.
	argumentCount := 0.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimSpecialSelector24 [

	messageSelector := self specialSelector: 24.
	argumentCount := self specialSelectorNumArgs: 24.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimSubtract [
	| rcvr arg result |
	rcvr := self internalStackValue: 1.
	arg := self internalStackValue: 0.
	(objectMemory areIntegers: rcvr and: arg)
		ifTrue: [result := (objectMemory integerValueOf: rcvr) - (objectMemory integerValueOf: arg).
				(objectMemory isIntegerValue: result) ifTrue:
					[self internalPop: 2 thenPush: (objectMemory integerObjectOf: result).
					^self fetchNextBytecode "success"]]
		ifFalse: [self initPrimCall.
				self externalizeIPandSP.
				self primitiveFloatSubtract: rcvr fromArg: arg.
				self internalizeIPandSP.
				self successful ifTrue: [^self fetchNextBytecode "success"]].

	messageSelector := self specialSelector: 1.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimValue [
	| rcvr isBlock |
	rcvr := self internalStackTop.
	argumentCount := 0.
	isBlock := self isInstanceOfClassBlockClosure: rcvr.
	isBlock ifTrue:
		[self externalizeIPandSP.
		self initPrimCall.
		self primitiveClosureValue.
		self internalizeIPandSP.
		self successful ifTrue:
			[^self fetchNextBytecode].
		primFailCode := 0].
	messageSelector := self specialSelector: 25.
	self normalSend
]

{ #category : #'common selector sends' }
StackInterpreter >> bytecodePrimValueWithArg [
	| rcvr isBlock |
	rcvr := self internalStackValue: 1.
	argumentCount := 1.
	isBlock := self isInstanceOfClassBlockClosure: rcvr.
	isBlock ifTrue:
		[self externalizeIPandSP.
		self initPrimCall.
		self primitiveClosureValue.
		self internalizeIPandSP.
		self successful ifTrue:
			[^self fetchNextBytecode].
		primFailCode := 0].
	messageSelector := self specialSelector: 26.
	self normalSend
]

{ #category : #'plugin primitive support' }
StackInterpreter >> callExternalPrimitive: functionID [
	"Call the external plugin function identified. In the VM this is an address;
	 see StackInterpreterSimulator for its version."

	<var: #functionID declareC: 'void (*functionID)()'>
	"Spur needs the primitiveFunctionPointer to be set correctly
	 for accurate following of forwarders on primitive failure."
	objectMemory hasSpurMemoryManagerAPI ifTrue:
		[primitiveFunctionPointer := functionID].
	self dispatchFunctionPointer: functionID.
	self maybeFailForLastObjectOverwrite.
]

{ #category : #'sista bytecodes' }
StackInterpreter >> callMappedInlinedPrimitive [
	"SistaV1:	236		11101100	iiiiiiii		callMappedInlinedPrimitive"
	| primIndex |
	SistaVM
		ifTrue:
			[primIndex := self fetchByte.
			self fetchNextBytecode.
			self sistaMappedInlinePrimitive: primIndex]
		ifFalse: 
			[localIP := localIP - 2.
			self respondToUnknownBytecode].
]

{ #category : #'miscellaneous bytecodes' }
StackInterpreter >> callPrimitiveBytecode [
	"V4:			249		11111001	i i i i i i i i	jjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjjj * 256)
	 SistaV1:	248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution.
	 V3/Spur:	139		10001011	i i i i i i i i	jjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjjj * 256)"
	"Note that we simply skip a callPrimitiveBytecode at the start of a method
	 that contains a primitive.  This because methods like Context(Part)>>reset
	 have to be updated to skip the callPrimtiive bytecode otherwise."
	SistaVM
		ifTrue:
			[| byte1 byte2 prim primSet header |
			 byte1 := self fetchByte.
			 byte2 := self fetchByte.
			 self fetchNextBytecode.
			 byte2 < 128 ifTrue:
				[header := objectMemory methodHeaderOf: method.
				 ((self methodHeaderHasPrimitive: header)
				  and: [localIP asUnsignedInteger
						= (self initialIPForHeader: header method: method) + (self sizeOfCallPrimitiveBytecode: header)]) ifTrue:
					[^self].
				 localIP := localIP - 3.
				 ^self respondToUnknownBytecode].
			 prim := byte2 - 128 << 8 + byte1.
			 primSet := prim >> 13 bitAnd: 3.
			 prim := prim bitAnd: 8191.
			 primSet = 0 ifTrue: [^self sistaInlinePrimitive: prim].
		
			LowcodeVM ifTrue: [
				primSet = 1 ifTrue: [
					prim < 1000 ifTrue:
						[^self lowcodeNullaryInlinePrimitive: prim].

					prim < 2000 ifTrue:
						[^self lowcodeUnaryInlinePrimitive: prim - 1000].
				
					prim < 3000 ifTrue:
						[^self lowcodeBinaryInlinePrimitive: prim - 2000].

					prim < 4000 ifTrue:
						[^self lowcodeTrinaryInlinePrimitive: prim - 3000].
				].
			].
		
			localIP := localIP - 3.
			^self respondToUnknownBytecode]
		ifFalse:
			[| header |
			 header := objectMemory methodHeaderOf: method.
			 ((self methodHeaderHasPrimitive: header)
			  and: [localIP asInteger = (self initialIPForHeader: header method: method)])
				ifTrue:
					[localIP := localIP + (self sizeOfCallPrimitiveBytecode: header) - 1.
					 ^self fetchNextBytecode]
				ifFalse:
					[^self respondToUnknownBytecode]]
]

{ #category : #'callback support' }
StackInterpreter >> callbackEnter: callbackID [
	"Re-enter the interpreter to execute a (non-ALien,non-FFI) callback (as used by the Python bridge)."
	<volatile>
	<export: true>
	<var: #callbackID type: #'sqInt *'>
	| savedReenterInterpreter |
	<var: #savedReenterInterpreter type: #'jmp_buf'>

	"For now, do not allow a callback unless we're in a primitiveResponse"
	(self asserta: primitiveFunctionPointer ~= 0) ifFalse:
		[^false].

	self assert: primFailCode = 0.

	"Check if we've exceeded the callback depth"
	(self asserta: jmpDepth < MaxJumpBuf) ifFalse:
		[^false].
	jmpDepth := jmpDepth + 1.

	"Suspend the currently active process"
	suspendedCallbacks at: jmpDepth put: self activeProcess.
	"We need to preserve newMethod explicitly since it is not activated yet
	and therefore no context has been created for it. If the caller primitive
	for any reason decides to fail we need to make sure we execute the correct
	method and not the one 'last used' in the call back"
	suspendedMethods at: jmpDepth put: newMethod.
	"Signal external semaphores since a signalSemaphoreWithIndex: request may
	 have been issued immediately prior to this callback before the VM has any
	 chance to do a signalExternalSemaphores in checkForEventsMayContextSwitch:"
	self signalExternalSemaphores.
	"If no process is awakened by signalExternalSemaphores then transfer
	 to the highest priority runnable one."
	(suspendedCallbacks at: jmpDepth) = self activeProcess ifTrue:
		[self transferTo: self wakeHighestPriority].

	"Typically, invoking the callback means that some semaphore has been 
	signaled to indicate the callback. Force an interrupt check as soon as possible."
	self forceInterruptCheck.

	"Save the previous interpreter entry jmp_buf."
	self memcpy: savedReenterInterpreter asVoidPointer
		_: reenterInterpreter
		_: (self sizeof: #'jmp_buf').
	(self setjmp: (jmpBuf at: jmpDepth)) = 0 ifTrue: "Fill in callbackID"
		[callbackID at: 0 put: jmpDepth.
		 self enterSmalltalkExecutive.
		 self assert: false "NOTREACHED"].

	"Restore the previous interpreter entry jmp_buf."
	self memcpy: reenterInterpreter
		_: (self cCoerceSimple: savedReenterInterpreter to: #'void *')
		_: (self sizeof: #'jmp_buf').

	"Transfer back to the previous process so that caller can push result"
	self putToSleep: self activeProcess yieldingIf: preemptionYields.
	self transferTo: (suspendedCallbacks at: jmpDepth).
	newMethod := suspendedMethods at: jmpDepth.	"see comment above"
	argumentCount := self argumentCountOf: newMethod.
	self assert: primFailCode = 0.
	jmpDepth := jmpDepth - 1.
	^true
]

{ #category : #'callback support' }
StackInterpreter >> callbackLeave: cbID [
	"Leave from a previous callback"
	<export: true>

	"For now, do not allow a callback return unless we're in a primitiveResponse"
	(self asserta: primitiveFunctionPointer ~= 0) ifFalse:
		[^false].

	"Check if this is the top-level callback"
	cbID = jmpDepth ifFalse:[^false].
	cbID < 1 ifTrue:[^false].
	"This is ugly but necessary, or otherwise the Mac will not build"
	self long: (jmpBuf at: jmpDepth) jmp: 1.
	"NOTREACHED"
	^nil
]

{ #category : #'message sending' }
StackInterpreter >> canContextSwitchIfActivating: theMethod header: methodHeader [
	"Context switch should not be allowed on every method activation.  In particular
	 the implementation of ensure: and ifCurtailed: depends on there being no
	 suspension point on failing primitive 198 (primitiveMarkUnwindMethod).
	 slowPrimitiveResponse states
		``N.B.  This means there is no suspension point on primitive failure
		    which methods such as ensure: and ifCurtailed: rely on.''
	 Rather than prevent context switch on all primitives but the ones we really need
	 to be suspension points (primitiveSignal et al) we choose to allow context switch
	 for all but primitiveMarkUnwindMethod."
	| primitiveIndex |
	<api>
	<inline: true>
	primitiveIndex := self primitiveIndexOfMethod: theMethod header: methodHeader.
	^self cppIf: true
		ifTrue:
			[primitiveIndex ~= 198] "primitiveMarkUnwindMethod"
		ifFalse:
			[primitiveIndex = 0
			  or: [(primitiveIndex between: 85 and: 88) "primitiveSignal primitiveWait primitiveResume primitiveSuspend"
			  or: [primitiveIndex = 167]]] "primitiveYield"
]

{ #category : #'stack bytecodes' }
StackInterpreter >> cannotAssign: resultObj to: targetObj withIndex: index [
	<option: #IMMUTABILITY>
	<inline: true> "because of use of normalSend..."
	self internalPush: targetObj.
	self internalPush: resultObj.
	self internalPush: (objectMemory integerObjectOf: index + 1).
	messageSelector := self splObj: SelectorAttemptToAssign.
	argumentCount := 2.
	^ self normalSend
]

{ #category : #'debug support' }
StackInterpreter >> capturePendingFinalizationSignals [
	statPendingFinalizationSignals := pendingFinalizationSignals.

]

{ #category : #'indexing primitive support' }
StackInterpreter >> characterForAscii: ascii [  "Above ObjectMemory, arg must lie in range 0-255!"
	<inline: true>
	^CharacterTable
		ifNil: [objectMemory characterObjectOf: ascii]
		ifNotNil: [objectMemory fetchPointer: ascii ofObject: objectMemory characterTable]
]

{ #category : #'debug support' }
StackInterpreter >> charsOfLong: long [
	"N.B. This will need to be overridden in big-endian simulator subclasses."
	<doNotGenerate>

	| byteArray |

	byteArray := ByteArray new: objectMemory wordSize.
	byteArray integerAt: 1 put: long size: objectMemory wordSize signed: false.

	^ byteArray collect: [:aByte | 
		aByte >= 14
			ifTrue: [aByte asCharacter]
			ifFalse: [$?]] as: Array
]

{ #category : #'debug support' }
StackInterpreter >> checkAllAccessibleObjectsOkay [
	"Ensure that all accessible objects in the heap are okay."
	<api>
	| ok |
	ok := true.
	objectMemory allObjectsDoSafely:
		[:oop| ok := ok & (self checkOkayFields: oop)].
	^ok
]

{ #category : #'primitive support' }
StackInterpreter >> checkAllocFiller [
	"If allocCheckFiller is true, words in newSpace from freeStart to scavengeThreshold
	 are filled with their address, and after each call of a plugin primitive, the VM checks
	 that freeStart points to a word containing the value of freeStart.  This is a simple
	 check for primitives overwriting the ends of an object."
	<cmacro: '() GIV(checkAllocFiller)'>
	^checkAllocFiller
]

{ #category : #initialization }
StackInterpreter >> checkAssumedCompactClasses [
	"Check that the classes the VM assumes are compact have the right indices."
	objectMemory checkCompactIndex: ClassArrayCompactIndex isClass: ClassArray named: 'Array'.
	objectMemory checkCompactIndex: ClassLargeNegativeIntegerCompactIndex isClass: ClassLargeNegativeInteger named: 'LargeNegativeInteger'.
	objectMemory checkCompactIndex: ClassLargePositiveIntegerCompactIndex isClass: ClassLargePositiveInteger named: 'LargePositiveInteger'.
	objectMemory checkCompactIndex: ClassFloatCompactIndex isClass: ClassFloat named: 'Float'.
	objectMemory checkCompactIndex: ClassBlockClosureCompactIndex isClass: ClassBlockClosure named: 'BlockClosure'.
	objectMemory checkCompactIndex: ClassMethodContextCompactIndex isClass: ClassMethodContext named: 'MethodContext'.
	classByteArrayCompactIndex := objectMemory compactIndexOfClass: (objectMemory splObj: ClassByteArray)
]

{ #category : #'object memory support' }
StackInterpreter >> checkCodeIntegrity: fullGCFlag [
	"This is a no-op in the StackVM"
	^true
]

{ #category : #'process primitive support' }
StackInterpreter >> checkCogCompiledCodeCompactionCalledFor [
	"This is a no-op in the StackVM"
]

{ #category : #'primitive support' }
StackInterpreter >> checkDeliveryOfLongRunningPrimitiveSignal [
	"Check for a hit of the longRunningPrimitive probe and if so attempt to signal the
	 longRunningPrimitiveCheckSemaphore.  Answer if a process switch occurred as a result."
	<inline: true>
	(longRunningPrimitiveStopUsecs > longRunningPrimitiveStartUsecs "a hit"
	 and: [longRunningPrimitiveCheckSemaphore notNil "deliverable"
	 and: [longRunningPrimitiveSignalUndelivered]]) ifTrue: "but not yet delivered"
		[longRunningPrimitiveSignalUndelivered := false.
		 longRunningPrimitiveGCUsecs := (objectMemory gcStartUsecs < longRunningPrimitiveStopUsecs
										   and: [objectMemory statGCEndUsecs > longRunningPrimitiveStartUsecs])
											ifTrue: [objectMemory statGCEndUsecs - objectMemory gcStartUsecs]
											ifFalse: [0].
		"Signal the LRP check semaphore if it is present"
		^self synchronousSignal: longRunningPrimitiveCheckSemaphore].
	^false
]

{ #category : #'primitive support' }
StackInterpreter >> checkForAndFollowForwardedPrimitiveState [
	"In Spur a primitive may fail due to encountering a forwarder. On failure,
	 check the accessorDepth for the primitive and if non-negative scan the
	 args to the depth, following any forwarders.  Answer if any are found so
	 the prim can be retried.  The primitive index is derived from newMethod."
	<option: #SpurObjectMemory>
	| primIndex accessorDepth found scannedStackFrame |
	self assert: self failed.
	found := scannedStackFrame := false.
	primIndex := self primitiveIndexOf: newMethod.
	self assert: (argumentCount = (self argumentCountOf: newMethod) or: [self isMetaPrimitiveIndex: primIndex]).
	"If the primitive is one of the meta primitives PrimNumberDoPrimitive or
	 PrimNumberDoExternalCall, then metaAccessorDepth will have been set
	 to nil at the start of the primitive, and to the accessor depth of the called
	 primitive (or external call) immediately before dispatch.  Hence if primIndex
	 is that of a meta primiitve then if metaAccessorDepth is -2, the accessor
	 depth is that of the meta primitive, and if > -2, then metaAccessorDepth is
	 the accessor depth of the primitive (or external call).  SImilarly, if the
	 primitive is primitiveExternalCall then the accessor depth is that of
	 primitiveExternalCall until primitiveFunctionPointer is assigned, at which
	 point the accessor depth is taken from the slot in newMethod's first literal."
	accessorDepth := ((self isMetaPrimitiveIndex: primIndex)
						 and: [metaAccessorDepth > -2])
							ifTrue: [metaAccessorDepth]
							ifFalse:
								[(primIndex = PrimNumberExternalCall
								  and: [primitiveFunctionPointer ~~ #primitiveExternalCall])
									ifTrue: [self primitiveAccessorDepthForExternalPrimitiveMethod: newMethod]
									ifFalse: [primitiveAccessorDepthTable at: primIndex]].
	self assert: (self saneFunctionPointerForFailureOfPrimIndex: primIndex).
	self assert: (accessorDepth between: -1 and: 5).
	accessorDepth >= 0 ifTrue:
		[0 to: argumentCount do:
			[:index| | oop |
			oop := self stackValue: index.
			(objectMemory isNonImmediate: oop) ifTrue:
				[(objectMemory isForwarded: oop) ifTrue:
					[self assert: index < argumentCount. "receiver should have been caught at send time."
					 found := true.
					 oop := objectMemory followForwarded: oop.
					 self stackValue: index put: oop.
					 scannedStackFrame ifFalse:
						[scannedStackFrame := true.
						 self
							followForwardedFrameContents: framePointer
							stackPointer: stackPointer + (argumentCount + 1 * objectMemory wordSize) "don't repeat effort"]].
				(accessorDepth > 0
			 	 and: [(objectMemory hasPointerFields: oop)
				 and: [objectMemory followForwardedObjectFields: oop toDepth: accessorDepth]]) ifTrue:
					[found := true]]]].
	^found
]

{ #category : #'process primitive support' }
StackInterpreter >> checkForEventsMayContextSwitch: mayContextSwitch [
	"Check for possible interrupts and handle one if necessary.
	 Answer if a context switch has occurred."
	| switched sema now |
	<inline: false>
	<var: #now type: #usqLong>
	statCheckForEvents := statCheckForEvents + 1.

	"restore the stackLimit if it has been smashed."
	self restoreStackLimit.
	self externalWriteBackHeadFramePointers.
	self assert: stackPage = stackPages mostRecentlyUsedPage.

	"Allow the platform to do anything it needs to do synchronously."
	self ioSynchronousCheckForEvents.

	self checkCogCompiledCodeCompactionCalledFor.

	objectMemory needGCFlag ifTrue:
		["sufficientSpaceAfterGC: runs the incremental GC and
		 then, if not enough space is available, the fullGC."
		 (objectMemory sufficientSpaceAfterGC: 0) ifFalse:
			[self setSignalLowSpaceFlagAndSaveProcess]].

	mayContextSwitch ifFalse: [^false].

	switched := false.

	(profileProcess ~= objectMemory nilObject
	 or: [nextProfileTick > 0 and:[self ioHighResClock >= nextProfileTick]]) ifTrue:
		[nextProfileTick := 0.
		 "Take a sample (if not already done so) for the profiler if it is active.  This
		  must be done before any of the synchronousSignals below or else we will
		  attribute a pause in ioRelinquishProcessor to the newly activated process."
		 profileProcess = objectMemory nilObject ifTrue:
			[profileProcess := self activeProcess.
			 profileMethod := objectMemory nilObject].
		 "and signal the profiler semaphore if it is present"
		 (profileSemaphore ~= objectMemory nilObject
		  and: [self synchronousSignal: profileSemaphore]) ifTrue:
			[switched := true]].

	self checkDeliveryOfLongRunningPrimitiveSignal ifTrue:
		[switched := true].

	objectMemory signalLowSpace ifTrue:
		[objectMemory signalLowSpace: false. "reset flag"
		 sema := objectMemory splObj: TheLowSpaceSemaphore.
		 (sema ~= objectMemory nilObject
		  and: [self synchronousSignal: sema]) ifTrue:
			[switched := true]].

	"inIOProcessEvents prevents reentrancy into ioProcessEvents and allows disabling
	 ioProcessEvents e.g. for native GUIs.  We would like to manage that here but can't
	 since the platform code may choose to call ioProcessEvents itself in various places."
	false
		ifTrue:
			[((now := self ioUTCMicroseconds) >= nextPollUsecs
			 and: [inIOProcessEvents = 0]) ifTrue:
				[statIOProcessEvents := statIOProcessEvents + 1.
				 inIOProcessEvents := inIOProcessEvents + 1.
				 self ioProcessEvents. "sets interruptPending if interrupt key pressed; may callback"
				 inIOProcessEvents > 0 ifTrue:
					[inIOProcessEvents := inIOProcessEvents - 1].
				 nextPollUsecs := now + 20000
				 "msecs to wait before next call to ioProcessEvents.  Note that strictly
				  speaking we might need to update 'now' at this point since
				  ioProcessEvents could take a very long time on some platforms"]]
		ifFalse:
			[(now := self ioUTCMicroseconds) >= nextPollUsecs ifTrue:
				[statIOProcessEvents := statIOProcessEvents + 1.
				 self ioProcessEvents. "sets interruptPending if interrupt key pressed; may callback"
				 nextPollUsecs := now + 20000
				 "msecs to wait before next call to ioProcessEvents.  Note that strictly
				  speaking we might need to update 'now' at this point since
				  ioProcessEvents could take a very long time on some platforms"]].

	interruptPending ifTrue:
		[interruptPending := false.
		 "reset interrupt flag"
		 sema := objectMemory splObj: TheInterruptSemaphore.
		 (sema ~= objectMemory nilObject
		  and: [self synchronousSignal: sema]) ifTrue:
			[switched := true]].

	nextWakeupUsecs ~= 0 ifTrue:
		[now >= nextWakeupUsecs ifTrue:
			[nextWakeupUsecs := 0.
			 "set timer interrupt to 0 for 'no timer'"
			 sema := objectMemory splObj: TheTimerSemaphore.
			 (sema ~= objectMemory nilObject
			  and: [self synchronousSignal: sema]) ifTrue:
				[switched := true]]].

	"signal any pending finalizations"
	pendingFinalizationSignals > 0 ifTrue:
		[pendingFinalizationSignals := 0.
		 sema := objectMemory splObj: TheFinalizationSemaphore.
		 (sema ~= objectMemory nilObject
		  and: [self synchronousSignal: sema]) ifTrue:
			[switched := true]].

	"signal all semaphores in semaphoresToSignal"
	self signalExternalSemaphores ifTrue:
		[switched := true].

	^switched
]

{ #category : #simulation }
StackInterpreter >> checkForLastObjectOverwrite [
	<doNotGenerate>
	| freeStart |
	checkAllocFiller ifTrue: 
		[self assert: ((freeStart := objectMemory freeStart) >= objectMemory scavengeThreshold
					  or: [(objectMemory longAt: freeStart) = freeStart])]
]

{ #category : #'primitive support' }
StackInterpreter >> checkForLongRunningPrimitive [
	"Called from forceInterruptCheckFromHeartbeat.  If the system has been running
	 the same primitive on two successive heartbeats then signal profileMethod."
	<inline: true>
	longRunningPrimitiveCheckSemaphore isNil ifTrue:
		[^nil].
	(longRunningPrimitiveStartUsecs > 0
	 and: [longRunningPrimitiveCheckMethod = newMethod
	 and: [longRunningPrimitiveCheckSequenceNumber = statCheckForEvents]]) ifTrue:
		[longRunningPrimitiveStopUsecs := self ioUTCMicroseconds.
		self assert: longRunningPrimitiveStopUsecs > longRunningPrimitiveStartUsecs.
		^nil].
	"See traceProfileState & mapProfileState."
	longRunningPrimitiveStopUsecs = 0 ifTrue:
		[longRunningPrimitiveCheckSequenceNumber := statCheckForEvents.
		 longRunningPrimitiveCheckMethod := newMethod.
		 longRunningPrimitiveStartUsecs := self ioUTCMicroseconds.
		 self sqLowLevelMFence]
]

{ #category : #'message sending' }
StackInterpreter >> checkForStackOverflow [
	"Check for stack overflow, moving frames to another stack if so.  Since event checking
	 piggy-backs off the stackLimit by setting it to all ones, the check for overflow must be
	 against the real stack limit to find out if overflow has actually occurred."
	<inline: true>
	self externalWriteBackHeadFramePointers.
	stackPointer < stackPage realStackLimit ifTrue:
		[self handleStackOverflow]
]

{ #category : #'image save/restore' }
StackInterpreter >> checkImageVersionFrom: f startingAt: imageOffset [
	"Read and verify the image file version number and return true if the the given image file needs to be byte-swapped. As a side effect, position the file stream just after the version number of the image header. This code prints a warning and does a hard-exit if it cannot find a valid version number."
	"This code is based on C code by Ian Piumarta."

	<inline: false>
	| version firstVersion |
	<var: #f type: #sqImageFile>
	<var: #imageOffset type: #squeakFileOffsetType>

	"check the version number"
	self sqImageFile: f Seek: imageOffset.
	version := firstVersion := self getWord32FromFile: f swap: false.
	(self readableFormat: version) ifTrue: [^ false].

	"try with bytes reversed"
	self sqImageFile: f Seek: imageOffset.
	version := self getWord32FromFile: f swap: true.
	(self readableFormat: version) ifTrue: [^ true].

	"Note: The following is only meaningful if not reading an embedded image"
	imageOffset = 0 ifTrue:[
		"try skipping the first 512 bytes (prepended by certain Mac file transfer utilities)"
		self sqImageFile: f Seek: 512.
		version := self getWord32FromFile: f swap: false.
		(self readableFormat: version) ifTrue: [^ false].

		"try skipping the first 512 bytes with bytes reversed"
		self sqImageFile: f Seek: 512.
		version := self getWord32FromFile: f swap: true.
		(self readableFormat: version) ifTrue: [^ true]].

	"hard failure; abort"
	self print: 'This interpreter (vers. '.
	self printNum: self imageFormatVersion.
	self print: ') cannot read image file (vers. '.
	self printNum: firstVersion.
	self print: ').'.
	self cr.
	self print: 'Press CR to quit...'.
	self getchar.
	self ioExitWithErrorCode: 1.
	^false
]

{ #category : #'object memory support' }
StackInterpreter >> checkInterpreterIntegrity [
	"Perform an integrity/leak check using the heapMap.  Assume
	 clearLeakMapAndMapAccessibleObjects has set a bit at each
	 object's header.  Check that all oops in the interpreter's state
	 points to a header.  Answer 0 if all checks pass."
	| flags |
	flags := 0.
	(objectMemory checkOopIntegrity: objectMemory specialObjectsOop named: 'specialObjectsOop') ifFalse:
		[flags := 1].
	"No longer check messageSelector; it is ephemeral, not living beyond message lookup.
	(objectMemory isNonImmediate: messageSelector) ifTrue:
		[(objectMemory checkOopIntegrity: messageSelector named: 'messageSelector') ifFalse:
			[flags := flags + N]]."
	(objectMemory checkOopIntegrity: newMethod named: 'newMethod') ifFalse:
		[flags := flags + 2].
	"No longer check lkupClass; it is ephemeral, not living beyond message lookup.
	(objectMemory checkOopIntegrity: lkupClass named: 'lkupClass') ifFalse:
		[flags := flags + N]."
	(objectMemory checkOopIntegrity: profileProcess named: 'profileProcess') ifFalse:
		[flags := flags + 4].
	(objectMemory checkOopIntegrity: profileMethod named: 'profileMethod') ifFalse:
		[flags := flags + 8].
	(objectMemory checkOopIntegrity: profileSemaphore named: 'profileSemaphore') ifFalse:
		[flags := flags + 16].
	tempOop = 0 ifFalse:
		[(objectMemory checkOopIntegrity: tempOop named: 'tempOop') ifFalse:
			[flags := flags + 32]].
	tempOop2 = 0 ifFalse:
		[(objectMemory checkOopIntegrity: tempOop2 named: 'tempOop2') ifFalse:
			[flags := flags + 64]].

	"Callback support - check suspended callback list"
	1 to: jmpDepth do:
		[:i|
		(objectMemory checkOopIntegrity: (suspendedCallbacks at: i) named: 'suspendedCallbacks' index: i) ifFalse:
			[flags := flags + 128].
		(objectMemory checkOopIntegrity: (suspendedMethods at: i) named: 'suspendedMethods' index: i) ifFalse:
			[flags := flags + 256]].

	self checkLogIntegrity ifFalse:
		[flags := flags + 512].

	^flags
]

{ #category : #'frame access' }
StackInterpreter >> checkIsStillMarriedContext: aContext currentFP: currentFP [
	"Another version of isWidowedContext: for debugging.
	 This will not bereave a widowed context."
	| thePage maybeFP limitFP maybeFrameCtxt |
	<inline: false>
	<var: #currentFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #maybeFP type: #'char *'>
	<var: #limitFP type: #'char *'>
	((objectMemory isContext: aContext)
	 and: [self isMarriedOrWidowedContext: aContext]) ifFalse:
		[^false].
	maybeFP := self frameOfMarriedContext: aContext.
	thePage := stackPages stackPageFor: maybeFP.
	limitFP := (thePage = stackPage and: [currentFP notNil])
				ifTrue: [currentFP]
				ifFalse: [thePage headFP].
	(maybeFP >= limitFP
	 and: [(objectMemory isNonImmediate: (self frameCallerFP: maybeFP) asInteger)
	 and: [(self withSmallIntegerTags: (self frameCallerFP: maybeFP))
			= (objectMemory fetchPointer: InstructionPointerIndex ofObject: aContext)
	 and: [self frameHasContext: maybeFP]]]) ifFalse:
		[^false].
	maybeFrameCtxt := self frameContext: maybeFP.
	"On Spur we need to follow the context to check for a match, but since the VM is
	 only speculating about maybeFrame being a frame, and only speculating about
	 maybeContext being a context, we need to be sure before we can safely follow."
	(objectMemory hasSpurMemoryManagerAPI
	 and: [(stackPages isFree: thePage) not
	 and: [(self isFrame: maybeFP onPage: thePage)
	 and: [objectMemory isForwarded: maybeFrameCtxt]]]) ifTrue:
		[maybeFrameCtxt := objectMemory followForwarded: maybeFrameCtxt].
	^maybeFrameCtxt = aContext
]

{ #category : #'object memory support' }
StackInterpreter >> checkLogIntegrity [
	"This is a no-op in the StackInterpreter"
	^true
]

{ #category : #'debug support' }
StackInterpreter >> checkOkayFields: oop [
	"Check if the argument is an ok object.
	 If this is a pointers object, check that its fields are all okay oops."

	| hasYoung i fieldOop |
	(oop = nil or: [oop = 0]) ifTrue: [ ^true ]. "?? eem 1/16/2013"
	(objectMemory isIntegerObject: oop) ifTrue: [ ^true ].
	(objectMemory checkOkayOop: oop) ifFalse: [ ^false ].
	(objectMemory checkOopHasOkayClass: oop) ifFalse: [ ^false ].
	((objectMemory isPointersNonImm: oop) or: [objectMemory isCompiledMethod: oop]) ifFalse: [ ^true ].
	hasYoung := objectMemory hasSpurMemoryManagerAPI not
				  and: [objectMemory isYoung: (objectMemory fetchClassOfNonImm: oop)].
	(objectMemory isCompiledMethod: oop)
		ifTrue:
			[i := (objectMemory literalCountOf: oop) + LiteralStart - 1]
		ifFalse:
			[(objectMemory isContext: oop)
				ifTrue: [i := CtxtTempFrameStart + (self fetchStackPointerOf: oop) - 1]
				ifFalse: [i := (objectMemory lengthOf: oop) - 1]].
	[i >= 0] whileTrue:
		[fieldOop := objectMemory fetchPointer: i ofObject: oop.
		(objectMemory isIntegerObject: fieldOop) ifFalse:
			[hasYoung := hasYoung or: [objectMemory isYoung: fieldOop].
			(objectMemory checkOkayOop: fieldOop) ifFalse: [ ^false ].
			(self checkOopHasOkayClass: fieldOop) ifFalse: [ ^false ]].
		i := i - 1].
	hasYoung ifTrue:
		[^objectMemory checkOkayYoungReferrer: oop].
	^true
]

{ #category : #'debug support' }
StackInterpreter >> checkOkayInterpreterObjects: writeBack [
	<api>
	| ok oopOrZero oop |
	ok := true.
	ok := ok & (self checkOkayFields: objectMemory nilObject).
	ok := ok & (self checkOkayFields: objectMemory falseObject).
	ok := ok & (self checkOkayFields: objectMemory trueObject).
	ok := ok & (self checkOkayFields: objectMemory specialObjectsOop).
	ok := ok & (self checkOkayFields: messageSelector).
	ok := ok & (self checkOkayFields: newMethod).
	ok := ok & (self checkOkayFields: lkupClass).
	0 to: MethodCacheEntries - 1 by: MethodCacheEntrySize do:
		[ :i |
		oopOrZero := methodCache at: i + MethodCacheSelector.
		oopOrZero = 0 ifFalse:
			[ok := ok & (self checkOkayFields: (methodCache at: i + MethodCacheSelector)).
			objectMemory hasSpurMemoryManagerAPI ifFalse:
				[ok := ok & (self checkOkayFields: (methodCache at: i + MethodCacheClass))].
			ok := ok & (self checkOkayFields: (methodCache at: i + MethodCacheMethod))]].
	1 to: objectMemory remapBufferCount do:
		[ :i |
		oop := objectMemory remapBuffer at: i.
		(objectMemory isImmediate: oop) ifFalse:
			[ok := ok & (self checkOkayFields: oop)]].
	ok := ok & (self checkOkayStackZone: writeBack).
	^ok
]

{ #category : #'debug support' }
StackInterpreter >> checkOkayStackPage: thePage [
	| theSP theFP ok frameRcvrOffset callerFP oop |
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #frameRcvrOffset type: #'char *'>
	<var: #callerFP type: #'char *'>
	<inline: false>
	theSP := thePage headSP.
	theFP := thePage  headFP.
	ok := true.
	"Skip the instruction pointer on top of stack of inactive pages."
	thePage = stackPage ifFalse:
		[theSP := theSP + objectMemory wordSize].
	[frameRcvrOffset := self frameReceiverLocation: theFP.
	 [theSP <= frameRcvrOffset] whileTrue:
		[oop := stackPages longAt: theSP.
		 (objectMemory isIntegerObject: oop) ifFalse:
			[ok := ok & (self checkOkayFields: oop)].
		 theSP := theSP + objectMemory wordSize].
	(self frameHasContext: theFP) ifTrue:
		[self assert: (objectMemory isContext: (self frameContext: theFP)).
		 ok := ok & (self checkOkayFields: (self frameContext: theFP))].
	ok := ok & (self checkOkayFields: (self frameMethodObject: theFP)).
	(callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
		[theSP := theFP + FoxCallerSavedIP + objectMemory wordSize.
		 theFP := callerFP].
	theSP := self isCog
				ifTrue: [theFP + FoxCallerSavedIP + objectMemory wordSize] "caller ip is ceBaseReturnPC"
				ifFalse: [theFP + FoxCallerSavedIP]. "caller ip is frameCallerContext in a base frame"
	[theSP <= thePage baseAddress] whileTrue:
		[oop := stackPages longAt: theSP.
		 (objectMemory isIntegerObject: oop) ifFalse:
			[ok := ok & (self checkOkayFields: oop)].
		 theSP := theSP + objectMemory wordSize].
	^ok
]

{ #category : #'debug support' }
StackInterpreter >> checkOkayStackZone: writeBack [
	"Check that all objects in the stack zone are okay"
	| ok thePage |
	<var: #thePage type: #'StackPage *'>
	<inline: false>
	writeBack ifTrue:
		[self externalWriteBackHeadFramePointers].
	ok := true.

	0 to: numStackPages - 1 do:
		[:i|
		thePage := stackPages stackPageAt: i.
		(stackPages isFree: thePage) ifFalse:
			[ok := ok & (self checkOkayStackPage: thePage)]].

	^ok
]

{ #category : #'process primitive support' }
StackInterpreter >> checkProfileTick: aPrimitiveMethod [
	"Check if the profile timer has expired and if so take a sample.
	 If the primitive has failed sample the profileMethod as nil."
	<inline: false>

	self assert: nextProfileTick ~= 0.
	self ioHighResClock >= nextProfileTick ifTrue:
		[profileProcess := self activeProcess.
		 profileMethod := self successful ifTrue: [aPrimitiveMethod] ifFalse: [objectMemory nilObject].
		 self forceInterruptCheck.
		 nextProfileTick := 0]
]

{ #category : #'object memory support' }
StackInterpreter >> checkStackIntegrity [
	"Perform an integrity/leak check using the heapMap.  Assume
	 clearLeakMapAndMapAccesibleObjects has set a bit at each
	 object's header.  Scan all objects accessible from the stack
	 checking that every pointer points to a header.  Answer if no
	 dangling pointers were detected."
	| ok |
	<inline: false>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	ok := true.
	0 to: numStackPages - 1 do:
		[:i| | thePage theSP theFP callerFP oop |
		thePage := stackPages stackPageAt: i.
		(stackPages isFree: thePage) ifFalse:
			[thePage = stackPage
				ifTrue:
					[theSP := stackPointer.
					 theFP := framePointer]
				ifFalse:
					[theSP := thePage headSP.
					 theFP := thePage  headFP].
			 "Skip the instruction pointer on top of stack of inactive pages."
			 thePage = stackPage ifFalse:
				[theSP := theSP + objectMemory wordSize].
			 [[theSP <= (theFP + FoxReceiver)] whileTrue:
				[oop := stackPages longAt: theSP.
				 ((objectMemory isNonImmediate: oop) 
				   and: [(objectMemory heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
					[self printFrameThing: 'object leak in frame temp' andFrame: theFP at: theSP.
					 ok := false].
				 theSP := theSP + objectMemory wordSize].
			 (self frameHasContext: theFP) ifTrue:
				[oop := self frameContext: theFP.
				 ((objectMemory isImmediate: oop) 
				   or: [(objectMemory heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
					[self printFrameThing: 'object leak in frame ctxt' andFrame: theFP at: theFP + FoxThisContext.
					 ok := false].
				 (objectMemory isContext: oop) ifFalse:
					[self printFrameThing: 'frame ctxt should be context' andFrame: theFP at: theFP + FoxThisContext.
					 ok := false].
				 ((objectMemory isContext: oop) and: [self isMarriedOrWidowedContext: oop]) ifFalse:
					[self printFrameThing: 'frame ctxt should be married' andFrame: theFP at: theFP + FoxThisContext.
					 ok := false].
				 ((objectMemory isContext: oop)
				  and: [(self isMarriedOrWidowedContext: oop)
				  and: [(self frameOfMarriedContext: oop) = theFP]]) ifFalse:
					[self printFrameThing: 'frame ctxt should be married to this frame ' andFrame: theFP at: theFP + FoxThisContext.
					 ok := false]].
			 oop := self frameMethod: theFP.
			 ((objectMemory isImmediate: oop) 
			   or: [(objectMemory heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
				[self printFrameThing: 'object leak in frame mthd' andFrame: theFP at: theFP + FoxMethod.
				 ok := false].
			 (callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
				[theSP := theFP + FoxCallerSavedIP + objectMemory wordSize.
				 theFP := callerFP].
			 theSP := theFP + FoxCallerSavedIP + objectMemory wordSize.
			 [theSP <= thePage baseAddress] whileTrue:
				[oop := stackPages longAt: theSP.
				 ((objectMemory isNonImmediate: oop) 
				   and: [(objectMemory heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
					[self printFrameThing: 'object leak in frame arg' andFrame: theFP at: theSP.
					 ok := false].
				 theSP := theSP + objectMemory wordSize]]].
	^ok
]

{ #category : #'internal interpreter access' }
StackInterpreter >> checkStackPointerForMaybeMarriedContext: aContext [
	"Version of stackPointerForMaybeMarriedContext: with no side-effects (does not widow).
	 Used for assertion checking. Safe only in external primitives (framePointer valid).
	 Answer the stackPointer of a Context."
	| sp |
	<inline: true>
	(self checkIsStillMarriedContext: aContext currentFP: framePointer) ifTrue:
		[sp := self checkStackPointerIndexForFrame: (self frameOfMarriedContext: aContext).
		 self assert: ReceiverIndex + (objectMemory integerValueOf: sp) < (objectMemory lengthOf: aContext).
		 ^sp].
	(self isMarriedOrWidowedContext: aContext) ifTrue:
		[^self argumentCountOf: (objectMemory fetchPointer: MethodIndex ofObject: aContext)].
	^self fetchStackPointerOf: aContext
]

{ #category : #'frame access' }
StackInterpreter >> checkStackPointerIndexForFrame: theFP [
	"Version of stackPointerIndexForFrame: that does not depend on writing back head frame pointers.
	 Used for assertion checking. Safe only in external primitives (framePointer valid).
	 Answer the 0-based index rel to the given frame.
	 (This is what stackPointer used to be before conversion to pointer)"
	"In the StackInterpreter stacks grow down."
	| thePage theSP |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	theFP = framePointer ifTrue:
		[^self stackPointerIndexForFrame: theFP WithSP: stackPointer].
	thePage := stackPages stackPageFor: theFP.
	theSP := self findSPOrNilOf: theFP
				on: thePage
				startingFrom: (thePage = stackPage ifTrue: [framePointer] ifFalse: [thePage headFP]).
	theSP ifNil: [^-1].
	^self stackPointerIndexForFrame: theFP WithSP: theSP
]

{ #category : #utilities }
StackInterpreter >> checkedIntegerValueOf: intOop [
	"Note: May be called by translated primitive code."

	(objectMemory isIntegerObject: intOop)
		ifTrue: [ ^ objectMemory integerValueOf: intOop ]
		ifFalse: [ self primitiveFail. ^ 0 ]
]

{ #category : #simulation }
StackInterpreter >> classNameIndex [
	<doNotGenerate>
	^classNameIndex
]

{ #category : #'plugin primitive support' }
StackInterpreter >> classNameOf: aClass Is: className [ 
	"Check if aClass's name is className"
	| srcName name length |
	<var: #className type: #'char *'>
	<var: #srcName type: #'char *'>
	(objectMemory lengthOf: aClass) <= classNameIndex ifTrue:
		[^ false]. "Not a class but might be behavior"
	name := objectMemory fetchPointer: classNameIndex ofObject: aClass.
	(objectMemory isBytes: name) ifFalse:
		[^false].
	length := self stSizeOf: name.
	srcName := self cCoerce: (self arrayValueOf: name) to: 'char *'.
	0 to: length - 1 do: [:i | (srcName at: i) = (className at: i) ifFalse: [^false]].
	"Check if className really ends at this point"
	^(className at: length) = 0
]

{ #category : #'message sending' }
StackInterpreter >> cloneOSErrorObj: errObj numSlots: numSlots [
	"If errObj is a pointer object with at least two slots, then answer a clone
	  of the error object with the second slot set to the value of osErrorCode,
	  and if an PrimErrFFIException, then the third slow with the exceptionPC."
	| clone |
	<inline: true>
	clone := objectMemory hasSpurMemoryManagerAPI
				ifTrue: [objectMemory
							eeInstantiateSmallClassIndex: (objectMemory classIndexOf: errObj)
							format: objectMemory nonIndexablePointerFormat
							numSlots: numSlots]
				ifFalse: [objectMemory
							eeInstantiateSmallClass: (objectMemory fetchClassOfNonImm: errObj)
							numSlots: numSlots].
	0 to: numSlots - 1 do:
		[:i| objectMemory
				storePointerUnchecked: i
				ofObject: clone
				withValue: (objectMemory fetchPointer: i ofObject: errObj)].
	(numSlots > 2
	 and: [primFailCode = PrimErrFFIException])
		ifTrue:
			[objectMemory
				storePointerUnchecked: 1
					ofObject: clone
						withValue: (self positive64BitIntegerFor: (self cCoerceSimple: osErrorCode to: #usqLong));
				storePointerUnchecked: 2
					ofObject: clone
						withValue: (self positiveMachineIntegerFor: exceptionPC)]
		ifFalse:
			[objectMemory
				storePointerUnchecked: 1
				ofObject: clone
				withValue: (self signed64BitIntegerFor: osErrorCode)].
	^clone
]

{ #category : #'control primitives' }
StackInterpreter >> closureIn: context numArgs: numArgs instructionPointer: initialIP copiedValues: copiedValues [
	| newClosure numCopied |
	<inline: true>
	"numCopied should be zero for nil"
	numCopied := objectMemory numSlotsOf: copiedValues.
	ClassBlockClosureCompactIndex ~= 0
		ifTrue:
			[newClosure := objectMemory
								eeInstantiateSmallClassIndex: ClassBlockClosureCompactIndex
								format: objectMemory indexablePointersFormat
								numSlots: ClosureFirstCopiedValueIndex + numCopied]
		ifFalse:
			[newClosure := objectMemory
								eeInstantiateSmallClass: (objectMemory splObj: ClassBlockClosure)
								numSlots: ClosureFirstCopiedValueIndex + numCopied].
	"Assume: have just allocated a new closure; it must be young. Thus, can use unchecked stores."
	objectMemory
		storePointerUnchecked: ClosureOuterContextIndex ofObject: newClosure withValue: context;
		storePointerUnchecked: ClosureStartPCIndex ofObject: newClosure withValue: (objectMemory integerObjectOf: initialIP);
		storePointerUnchecked: ClosureNumArgsIndex ofObject: newClosure withValue: (objectMemory integerObjectOf: numArgs).
	0 to: numCopied - 1 do:
		[:i|
		objectMemory storePointerUnchecked: i + ClosureFirstCopiedValueIndex
			ofObject: newClosure
			withValue: (objectMemory fetchPointer: i ofObject: copiedValues)].
	^newClosure
]

{ #category : #'control primitives' }
StackInterpreter >> closureIn: context numArgs: numArgs instructionPointer: initialIP numCopiedValues: numCopied [
	| newClosure |
	<inline: true>
	ClassBlockClosureCompactIndex ~= 0
		ifTrue:
			[newClosure := objectMemory
								eeInstantiateSmallClassIndex: ClassBlockClosureCompactIndex
								format: objectMemory indexablePointersFormat
								numSlots: ClosureFirstCopiedValueIndex + numCopied]
							
		"This path is for preSpur images"					
		ifFalse:
			[newClosure := objectMemory
								eeInstantiateSmallClass: (objectMemory splObj: ClassBlockClosure)
								numSlots: ClosureFirstCopiedValueIndex + numCopied].
	"Assume: have just allocated a new closure; it must be young. Thus, can use unchecked stores."
	objectMemory storePointerUnchecked: ClosureOuterContextIndex ofObject: newClosure withValue: context.
	objectMemory storePointerUnchecked: ClosureStartPCIndex ofObject: newClosure withValue: (objectMemory integerObjectOf: initialIP).
	objectMemory storePointerUnchecked: ClosureNumArgsIndex ofObject: newClosure withValue: (objectMemory integerObjectOf: numArgs).
	^newClosure
]

{ #category : #'primitive support' }
StackInterpreter >> codeGeneratorToComputeAccessorDepth [

	^ codeGeneratorToComputeAccessorDepth ifNil: [
		^(VMMaker new
			buildCodeGeneratorForInterpreter: self class primitivesClass
			includeAPIMethods: false
			initializeClasses: false)
				logger: self transcript;
				yourself ]
]

{ #category : #'as yet unclassified' }
StackInterpreter >> codeGeneratorToComputeAccessorDepth: aCCodeGenerator [ 
	<doNotGenerate>
	codeGeneratorToComputeAccessorDepth := aCCodeGenerator
]

{ #category : #'indexing primitive support' }
StackInterpreter >> commonAt: stringy [
	"This code is called if the receiver responds primitively to at:.
	 N.B. this does *not* use the at cache, instead inlining stObject:at:.
	 Using the at cache here would require that callers set messageSelector
	 and lkupClass and that is onerous and error-prone, and in any case,
	 inlining produces much better performance than using the at cache here."
	| index rcvr result |
	<inline: true> "to get it inlined in primitiveAt and primitiveStringAt"
	self initPrimCall.
	rcvr := self stackValue: 1.
	index := self stackTop.
	(objectMemory isImmediate: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	"No need to test for large positive integers here.  No object has 1g elements"
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 1 "e.g. object:basicAt:"
		 and: [objectMemory isForwarded: rcvr]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	result := self stObject: rcvr at: index.
	self successful ifTrue:
		[stringy ifTrue:
			[(objectMemory isInRangeCharacterCode: result) ifFalse:
				[^self primitiveFailFor: PrimErrBadReceiver].
			 result := self characterForAscii: (objectMemory integerValueOf: result)].
		 self pop: argumentCount+1 thenPush: result]
]

{ #category : #'indexing primitive support' }
StackInterpreter >> commonAtPut: stringy [
	"This code is called if the receiver responds primitively to at:Put:.
	 N.B. this does *not* use the at cache, instead inlining stObject:at:put:.
	 Using the at cache here would require that callers set messageSelector
	 and lkupClass and that is onerous and error-prone, and in any case,
	 inlining produces much better performance than using the at cache here."
	| value index rcvr |
	<inline: true> "to get it inlined in primitiveAtPut and primitiveStringAtPut"
	self initPrimCall.
	rcvr := self stackValue: 2.
	index := self stackValue: 1.
	value := self stackTop.
	(objectMemory isImmediate: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrInappropriate].
	"No need to test for large positive integers here.  No object has 1g elements"
	((objectMemory isNonIntegerObject: index)
	 or: [argumentCount > 2 "e.g. object:basicAt:put:"
		 and: [objectMemory isForwarded: rcvr]]) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	(objectMemory isObjImmutable: rcvr) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	index := objectMemory integerValueOf: index.
	stringy
		ifTrue: [self stObject: rcvr at: index put: (self asciiOfCharacter: value)]
		ifFalse: [self stObject: rcvr at: index put: value].
	self successful ifTrue:
		[self pop: argumentCount+1 thenPush: value]
]

{ #category : #'return bytecodes' }
StackInterpreter >> commonCallerReturn [
	"Return to the previous context/frame (sender for method activations, caller for block activations)."
	<sharedCodeInCase: #returnTopFromBlock>
	| callersFPOrNull doWeHaveANativeFrame |
	<var: #callersFPOrNull type: #'char *'>

	"TODO: Store/restore the nativeSP more properly, when it exists"
	LowcodeVM ifTrue: [ 
		doWeHaveANativeFrame := self frameHasNativeFrame: localFP.
		doWeHaveANativeFrame ifTrue: [
			nativeStackPointer := (self nativePreviousStackPointerIn: localFP) - 1.
			nativeSP := 0.
			self setFrameHasNotNativeFrame: localFP.
		].
	].

	callersFPOrNull := self frameCallerFP: localFP.
	callersFPOrNull = 0 "baseFrame" ifTrue:
		[self assert: localFP = stackPage baseFP.
		 ^self baseFrameReturn].

	localIP := self frameCallerSavedIP: localFP.
	localSP := localFP + (self frameStackedReceiverOffset: localFP).
	localFP := callersFPOrNull.
	self setMethod: (self frameMethod: localFP).
	self fetchNextBytecode.
	self internalStackTopPut: localReturnValue
]

{ #category : #'return bytecodes' }
StackInterpreter >> commonReturn [
	"Do an ^-return (return from method), checking for unwinds if this is a block activation.
	 Note: Assumed to be inlined into the dispatch loop."

	<sharedCodeInCase: #returnReceiver>
	| closure home unwindContextOrNilOrZero frameToReturnTo contextToReturnTo theFP callerFP newPage |
	<var: #frameToReturnTo type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #newPage type: #'StackPage *'>
	<var: #thePage type: #'StackPage *'>

	"If this is a method simply return to the  sender/caller."
	(self iframeIsBlockActivation: localFP) ifFalse:
		[^self commonCallerReturn].

	"Update the current page's headFrame pointers to enable the search for unwind protects below
	 to identify widowed contexts correctly."
	self writeBackHeadFramePointers.
	self externalizeIPandSP.

	"Since this is a block activation the closure is on the stack above any args and the frame."
	closure := self pushedReceiverOrClosureOfFrame: localFP.
	home := nil. "avoid compiler warning"
	"Walk the closure's lexical chain to find the context or frame to return from (home).
	 If home is missing (Sista closures) then throw cannotReturn rather than crash."
	[closure ~= objectMemory nilObject] whileTrue:
		[home := objectMemory followField: ClosureOuterContextIndex ofObject: closure.
		 (objectMemory isContext: home) ifFalse:
			[^self internalCannotReturn: localReturnValue].
		 closure := objectMemory followField: ClosureIndex ofObject: home].
	"home is to be returned from provided there is no unwind-protect activation between
	 this frame and home's sender.  Search for an unwind.  findUnwindThroughContext:
	 will answer either the context for an unwind-protect activation or nilObj if the sender
	 cannot be found or 0 if no unwind is found but the sender is."
	unwindContextOrNilOrZero := self findUnwindThroughContext: home.
	unwindContextOrNilOrZero = objectMemory nilObject ifTrue:
		["error: can't find home on chain; cannot return"
		 ^self internalCannotReturn: localReturnValue].
	unwindContextOrNilOrZero ~= 0 ifTrue:
		[^self internalAboutToReturn: localReturnValue through: unwindContextOrNilOrZero].

	"Now we know home is on the sender chain.
	 We could be returning to either a context or a frame.  Find out which."
	contextToReturnTo := nil.
	(self isMarriedOrWidowedContext: home)
		ifTrue:
			[self assert: (self checkIsStillMarriedContext: home currentFP: localFP).
			 theFP := self frameOfMarriedContext: home.
			 (self isBaseFrame: theFP)
				ifTrue:
					[contextToReturnTo := self frameCallerContext: theFP]
				ifFalse:
					[frameToReturnTo := self frameCallerFP: theFP]]
		ifFalse:
			[contextToReturnTo := objectMemory fetchPointer: SenderIndex ofObject: home.
			 ((objectMemory isContext: contextToReturnTo)
			  and: [self isMarriedOrWidowedContext: contextToReturnTo]) ifTrue:
				[self assert: (self checkIsStillMarriedContext: contextToReturnTo currentFP: localFP).
			 	 frameToReturnTo := self frameOfMarriedContext: contextToReturnTo.
				 contextToReturnTo := nil]].

	"If returning to a context we must make a frame for it unless it is dead."
	contextToReturnTo ~= nil ifTrue:
		[frameToReturnTo := self establishFrameForContextToReturnTo: contextToReturnTo.
		 frameToReturnTo = 0 ifTrue: "error: home's sender is dead; cannot return"
			[^self internalCannotReturn: localReturnValue]].

	"Now we have a frame to return to.  If it is on a different page we must free intervening pages and
	 nil out intervening contexts.  We must free intervening stack pages because if we leave the pages
	 to be divorced then their contexts will be divorced with intact senders and instruction pointers.  This
	 code is similar to primitiveTerminateTo.  We must move any frames on intervening pages above the
	 frame linked to because these may be in use, e.g. via co-routining (see baseFrameReturn)."
	self assert: stackPages pageListIsWellFormed.
	newPage := stackPages stackPageFor: frameToReturnTo.
	newPage ~~ stackPage ifTrue:
		[| currentCtx thePage nextCntx |
		 currentCtx := self frameCallerContext: stackPage baseFP.
		 stackPages freeStackPage: stackPage.
		 [self assert: (objectMemory isContext: currentCtx).
		  (self isMarriedOrWidowedContext: currentCtx)
		   and: [(stackPages stackPageFor: (theFP := self frameOfMarriedContext: currentCtx)) = newPage]] whileFalse:
			[(self isMarriedOrWidowedContext: currentCtx)
				ifTrue:
					[thePage := stackPages stackPageFor: theFP.
					 theFP ~= thePage headFP ifTrue:
						["Since we've just deallocated a page we know that newStackPage won't deallocate an existing one."
						 self moveFramesIn: thePage through: (self findFrameAbove: theFP inPage: thePage) toPage: stackPages newStackPage].
					 currentCtx := self frameCallerContext: thePage baseFP.
					 stackPages freeStackPage: thePage]
				ifFalse:
					[nextCntx := objectMemory fetchPointer: SenderIndex ofObject: currentCtx.
					 self markContextAsDead: currentCtx.
					 currentCtx := nextCntx]].
		 self setStackPageAndLimit: newPage.
		 localSP := stackPage headSP.
		 localFP := stackPage headFP].

	"Two cases.  Returning to the top frame on a new page or an interior frame on the current page.
	 The top frame has its instruction pointer on top of stack. An interior frame has its instruction pointer
	 in the caller frame. We need to peel back any frames on the page until we get to the correct frame."

	localFP = frameToReturnTo
		ifTrue: "pop the saved IP, push the return value and continue."
			[localIP := self pointerForOop: self internalStackTop]
		ifFalse:
			[[callerFP := localFP.
			  localFP := self frameCallerFP: localFP.
			  localFP ~~ frameToReturnTo] whileTrue.
			localIP := self frameCallerSavedIP: callerFP.
			localSP := (self frameCallerSP: callerFP) - objectMemory wordSize].
	self maybeReturnToMachineCodeFrame.
	self setMethod: (self frameMethod: localFP).
	self fetchNextBytecode.
	self internalStackTopPut: localReturnValue
]

{ #category : #'send bytecodes' }
StackInterpreter >> commonSendOrdinary [
	"Send a message, starting lookup with the receiver's class."
	"Assume: messageSelector and argumentCount have been set, and that 
	the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	<sharedCodeInCase: #singleExtendedSendBytecode>
	self sendBreakpoint: messageSelector receiver: (self internalStackValue: argumentCount).
	self printSends ifTrue:
		[self printActivationNameForSelector: messageSelector startClass: (objectMemory classForClassTag: lkupClassTag); cr].
	self internalFindNewMethodOrdinary.
	self internalExecuteNewMethod.
	self fetchNextBytecode
]

{ #category : #'indexing primitive support' }
StackInterpreter >> commonVariable: rcvr at: index cacheIndex: atIx [ 
	"This code assumes the receiver has been identified at location atIx in the atCache."
	| stSize fmt fixedFields result |
	<inline: true>
	stSize := atCache at: atIx+AtCacheSize.
	((self oop: index isGreaterThanOrEqualTo: 1)
	 and: [self oop: index isLessThanOrEqualTo: stSize]) ifTrue:
		[fmt := atCache at: atIx+AtCacheFmt.
		 fmt <= objectMemory weakArrayFormat ifTrue:
			[self assert: (objectMemory isContextNonImm: rcvr) not.
			 fixedFields := atCache at: atIx+AtCacheFixedFields.
			 ^objectMemory fetchPointer: index + fixedFields - 1 ofObject: rcvr].
		 fmt < objectMemory firstByteFormat ifTrue: "64, 32, & 16 bits"
			[objectMemory hasSpurMemoryManagerAPI ifTrue:
				[fmt >= objectMemory firstShortFormat ifTrue:
					[^objectMemory integerObjectOf:
						(objectMemory fetchUnsignedShort16: index - 1 ofObject: rcvr)].
				 fmt = objectMemory sixtyFourBitIndexableFormat ifTrue:
					[^self positive64BitIntegerFor:
						(objectMemory fetchLong64: index - 1 ofObject: rcvr)]].
			 result := objectMemory fetchLong32: index - 1 ofObject: rcvr.
			 ^self positive32BitIntegerFor: result].
		 fmt >= objectMemory firstStringyFakeFormat  "Note fmt >= firstStringyFormat is an artificial flag for strings"
			ifTrue: "String"
				["Spur supports the String at:[put:] primitives on WideString and DoubleByteString"
				 result := (objectMemory hasSpurMemoryManagerAPI
							and: [fmt < (objectMemory firstByteFormat + objectMemory firstStringyFakeFormat)])
								ifTrue:
									[fmt < (objectMemory firstShortFormat + objectMemory firstStringyFakeFormat)
										ifTrue: [objectMemory fetchLong32: index - 1 ofObject: rcvr]
										ifFalse: [objectMemory fetchUnsignedShort16: index - 1 ofObject: rcvr]]
								ifFalse: [objectMemory fetchByte: index - 1 ofObject: rcvr].
				^self characterForAscii: result]
			ifFalse:
				[(fmt < objectMemory firstCompiledMethodFormat "ByteArray"
				  or: [index >= (self firstByteIndexOfMethod: rcvr) "CompiledMethod"]) ifTrue:
					[^objectMemory integerObjectOf: (objectMemory fetchByte: index - 1 ofObject: rcvr)]]].

	^self primitiveFailFor: ((objectMemory isIndexable: rcvr)
								ifFalse: [PrimErrBadReceiver]
								ifTrue: [PrimErrBadIndex])
]

{ #category : #'indexing primitive support' }
StackInterpreter >> commonVariable: rcvr at: index put: value cacheIndex: atIx [
	"This code assumes the receiver has been identified at location atIx in the atCache."
	<returnTypeC: #void>
	| stSize fmt fixedFields valToPut isCharacter |
	<inline: true>
	stSize := atCache at: atIx+AtCacheSize.
	((self oop: index isGreaterThanOrEqualTo: 1)
	  and: [self oop: index isLessThanOrEqualTo: stSize]) ifTrue:
		[fmt := atCache at: atIx+AtCacheFmt.
		fmt <= objectMemory weakArrayFormat ifTrue:
			[self assert: (objectMemory isContextNonImm: rcvr) not.
			 fixedFields := atCache at: atIx+AtCacheFixedFields.
			 ^objectMemory storePointer: index + fixedFields - 1 ofObject: rcvr withValue: value].
		fmt < objectMemory firstByteFormat ifTrue:  "64, 32, & 16 bits"
			[objectMemory hasSpurMemoryManagerAPI ifTrue:
				[fmt >= objectMemory firstShortFormat ifTrue:
					[valToPut := (objectMemory isIntegerObject: value)
									ifTrue: [objectMemory integerValueOf: value]
									ifFalse: [-1].
					(valToPut >= 0 and: [valToPut <= 65535]) ifFalse: [^self primitiveFailFor: PrimErrBadArgument].
					^objectMemory storeShort16: index - 1 ofObject: rcvr withValue: valToPut].
				 fmt = objectMemory sixtyFourBitIndexableFormat ifTrue:
					[| val64ToPut |
					 val64ToPut := self positive64BitValueOf: value.
					 self successful ifTrue:
						[^objectMemory storeLong64: index - 1 ofObject: rcvr withValue: val64ToPut].
					 ^self primitiveFailFor: PrimErrBadArgument]].
			 valToPut := self positive32BitValueOf: value.
			 self successful ifTrue:
				[^objectMemory storeLong32: index - 1 ofObject: rcvr withValue: valToPut].
			 ^self primitiveFailFor: PrimErrBadArgument].
		fmt >= objectMemory firstStringyFakeFormat  "Note fmt >= firstStringyFormat is an artificial flag for strings"
			ifTrue:
				[isCharacter := objectMemory isCharacterObject: value.
				 isCharacter ifFalse:
					[^self primitiveFailFor: PrimErrBadArgument].
				 objectMemory hasSpurMemoryManagerAPI
					ifTrue: [valToPut := objectMemory characterValueOf: value]
					ifFalse:
						[valToPut := objectMemory fetchPointer: CharacterValueIndex ofObject: value.
						 valToPut := (objectMemory isIntegerObject: valToPut)
										ifTrue: [objectMemory integerValueOf: valToPut]
										ifFalse: [-1]].
				 objectMemory hasSpurMemoryManagerAPI ifTrue:
				 	[fmt < (objectMemory firstByteFormat + objectMemory firstStringyFakeFormat) ifTrue:
						[fmt < (objectMemory firstShortFormat + objectMemory firstStringyFakeFormat)
							ifTrue:
								[self assert: fmt ~= (objectMemory sixtyFourBitIndexableFormat + objectMemory firstStringyFakeFormat).
								 ^objectMemory storeLong32: index - 1 ofObject: rcvr withValue: valToPut]
							ifFalse:
								[(valToPut >= 0 and: [valToPut <= 65535]) ifFalse: [^self primitiveFailFor: PrimErrBadArgument].
								 ^objectMemory storeShort16: index - 1 ofObject: rcvr withValue: valToPut]]]]
			ifFalse:
				[(fmt >= objectMemory firstCompiledMethodFormat
				  and: [index < (self firstByteIndexOfMethod: rcvr)]) ifTrue:
					[^self primitiveFailFor: PrimErrBadIndex].
				valToPut := (objectMemory isIntegerObject: value)
								ifTrue: [objectMemory integerValueOf: value]
								ifFalse: [-1]].
		(valToPut >= 0 and: [valToPut <= 255]) ifFalse: [^self primitiveFailFor: PrimErrBadArgument].
		^objectMemory storeByte: index - 1 ofObject: rcvr withValue: valToPut].

	^self primitiveFailFor: ((objectMemory isIndexable: rcvr)
								ifFalse: [PrimErrBadReceiver]
								ifTrue: [PrimErrBadIndex])
]

{ #category : #initialization }
StackInterpreter >> computeStackZoneSize [
	self cCode: [] inSmalltalk:
		[stackPages ifNil:
			[stackPages := self stackPagesClass new setInterpreter: self]].
	^numStackPages * ((self sizeof: CogStackPage) + self stackPageByteSize)
	 + stackPages extraStackBytes
]

{ #category : #'internal interpreter access' }
StackInterpreter >> context: thisCntx hasSender: aContext [ 
	"Does thisCntx have aContext in its sender chain?
	 Cheapo implementation above extant machinery."
	| handlerOrNilOrZero |
	<inline: true>
	handlerOrNilOrZero := self
							findMethodWithPrimitive: -1
							FromContext: thisCntx
							UpToContext: aContext.
	^handlerOrNilOrZero = 0
]

{ #category : #'debug support' }
StackInterpreter >> context: aContext hasValidInversePCMappingOf: theIP in: theFP [
	"For asserts.  Check that theIP maps back correctly to the context's pc.
	 The CallPrimitive bytecode presents a complication."
	| pc encodedip |
	<var: #theFP type: #'char *'>
	pc := objectMemory fetchPointer: InstructionPointerIndex ofObject: aContext.
	encodedip := self contextInstructionPointer: theIP frame: theFP.
	^(objectMemory hasSpurMemoryManagerAPI or: [MULTIPLEBYTECODESETS])
		ifTrue:
			[pc = encodedip
			or: [| methodHeader |
				methodHeader := objectMemory methodHeaderOf: (objectMemory fetchPointer: MethodIndex ofObject: aContext).
				(self methodHeaderHasPrimitive: methodHeader)
				and: [(objectMemory integerValueOf: encodedip) - (objectMemory integerValueOf: pc)
					= (self sizeOfCallPrimitiveBytecode: methodHeader)]]]
		ifFalse: [pc = encodedip]
]

{ #category : #'frame access' }
StackInterpreter >> contextInstructionPointer: theIP frame: theFP [
	<var: #theFP type: #'char *'>
	self assert: (self validInstructionPointer: theIP + 1 inFrame: theFP).
	^objectMemory integerObjectOf: theIP - (self iframeMethod: theFP) - objectMemory baseHeaderSize + 2
]

{ #category : #'image save/restore' }
StackInterpreter >> convertFloatsToPlatformOrder [
	"Byte-swap the words of all bytes objects in a range of the 
	 image, including Strings, ByteArrays, and CompiledMethods.
	 This returns these objects to their original byte ordering 
	 after blindly byte-swapping the entire image. For compiled 
	 methods, byte-swap only their bytecodes part.
	 Ensure floats are in platform-order."
	objectMemory vmEndianness = imageFloatsBigEndian ifTrue:
		[^nil].
	self assert: ClassFloatCompactIndex ~= 0.
	objectMemory allObjectsDo:
		[:obj| | temp |
		(objectMemory compactClassIndexOf: obj) = ClassFloatCompactIndex ifTrue:
			[temp := objectMemory long32At: obj + objectMemory baseHeaderSize.
			 objectMemory long32At: obj + objectMemory baseHeaderSize put: (objectMemory long32At: obj + objectMemory baseHeaderSize + 4).
			 objectMemory long32At: obj + objectMemory baseHeaderSize + 4 put: temp]]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> copiedValueCountOfClosure: closurePointer [
	<api> "for Cogit"
	^(objectMemory numSlotsOf: closurePointer) - ClosureFirstCopiedValueIndex
]

{ #category : #'internal interpreter access' }
StackInterpreter >> copiedValueCountOfFullClosure: closurePointer [
	<api> "for Cogit"
	^(objectMemory numSlotsOf: closurePointer) - FullClosureFirstCopiedValueIndex
]

{ #category : #'bitblt support' }
StackInterpreter >> copyBits [
	"This entry point needs to be implemented for the interpreter proxy.
	Since BitBlt is now a plugin we need to look up BitBltPlugin:=copyBits
	and call it. This entire mechanism should eventually go away and be
	replaced with a dynamic lookup from BitBltPlugin itself but for backward
	compatibility this stub is provided"

	| fn |
	<var: #fn type: 'void *'>
	fn := self ioLoadFunction: 'copyBits' From: 'BitBltPlugin'.
	fn = 0 ifTrue: [^self primitiveFail].
	^self cCode: '((sqInt (*)(void))fn)()'
]

{ #category : #'bitblt support' }
StackInterpreter >> copyBitsFrom: x0 to: x1 at: y [
	"This entry point needs to be implemented for the interpreter proxy.
	Since BitBlt is now a plugin we need to look up BitBltPlugin:=copyBitsFrom:to:at:
	and call it. This entire mechanism should eventually go away and be
	replaced with a dynamic lookup from BitBltPlugin itself but for backward
	compatibility this stub is provided"

	| fn |
	<var: #fn type: 'void *'>
	fn := self ioLoadFunction: 'copyBitsFromtoat' From: 'BitBltPlugin'.
	fn = 0 ifTrue: [^self primitiveFail].
	^self cCode: '((sqInt (*)(sqInt, sqInt, sqInt))fn)(x0, x1, y)'
]

{ #category : #'debug support' }
StackInterpreter >> couldBeProcess: oop [
	<inline: #never>
	^(objectMemory addressCouldBeObj: oop)
	  and: [(objectMemory isPointersNonImm: oop)
	  and: [(objectMemory isContext: oop) not
	  and: [(objectMemory lengthOf: oop) > MyListIndex
	  and: [objectMemory isContext: (objectMemory
										fetchPointer: SuspendedContextIndex
										ofObject: oop)]]]]
]

{ #category : #'debug printing' }
StackInterpreter >> cr [
	"For testing in Smalltalk, this method should be overridden in a subclass."
	<inline: true>
	self print: '\n'.
	^ 1.
]

{ #category : #'message sending' }
StackInterpreter >> createActualMessageTo: lookupClass [ 
	"Bundle up the selector, arguments and lookupClass into a Message object. 
	 In the process it pops the arguments off the stack, and pushes the message object. 
	 This can then be presented as the argument of e.g. #doesNotUnderstand:"
	| argumentArray message |
	<inline: false> "This is a useful break-point"
	self assert: ((objectMemory isImmediate: messageSelector) or: [objectMemory addressCouldBeObj: messageSelector]).
	self mnuBreakpoint: messageSelector receiver: nil.
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[argumentArray := objectMemory
								eeInstantiateSmallClassIndex: ClassArrayCompactIndex
								format: objectMemory arrayFormat
								numSlots: argumentCount.
			 message := objectMemory
								eeInstantiateSmallClassIndex: ClassMessageCompactIndex
								format: objectMemory nonIndexablePointerFormat
								numSlots: MessageLookupClassIndex + 1]
		ifFalse:
			[argumentArray := objectMemory
								eeInstantiateSmallClass: (objectMemory splObj: ClassArray)
								numSlots: argumentCount.
			 message := objectMemory
								eeInstantiateSmallClass: (objectMemory splObj: ClassMessage)
								numSlots: MessageLookupClassIndex + 1].

	"Since the array is new can use unchecked stores."
	(argumentCount - 1) * objectMemory bytesPerOop to: 0 by: objectMemory bytesPerOop negated do:
		[:i|
		objectMemory longAt:  argumentArray + objectMemory baseHeaderSize + i put: self popStack].
	"Since message is new can use unchecked stores."
	objectMemory
		storePointerUnchecked: MessageSelectorIndex ofObject: message withValue: messageSelector;
		storePointerUnchecked: MessageArgumentsIndex ofObject: message withValue: argumentArray;
		storePointerUnchecked: MessageLookupClassIndex ofObject: message withValue: lookupClass.

	self push: message.

	argumentCount := 1
]

{ #category : #'stack pages' }
StackInterpreter >> defaultNativeStackFrameSize [
	"default native stack frame size"
	^ 256
]

{ #category : #initialization }
StackInterpreter >> defaultNumStackPages [
	"Return the default number of stack pages allocate at startup.
	 This V3 default suits Qwaq Forums (specifically general rendering).
	 The Spur default reflects tuning for GC performance ast Cadence.
	 It is probably a bit high for normal use but QF is profligate with processes.
	 The actual value can be set via vmParameterAt: and/or a preference in the ini file."
	<inline: false>
	^objectMemory hasSpurMemoryManagerAPI
		ifTrue: [50]
		ifFalse: [160]
]

{ #category : #'debug support' }
StackInterpreter >> detailedSymbolicMethod: aMethod [
	<doNotGenerate>
	 self transcript
		ensureCr;
		nextPutAll:
			((String streamContents:
				[:ts| | prim proxy |
				(prim := self primitiveIndexOf: aMethod) > 0 ifTrue:
					[ts nextPutAll: '<primitive: '; print: prim; nextPut: $>.
					(self isQuickPrimitiveIndex: prim) ifTrue:
						[ts nextPutAll: ' quick method'; cr; flush.
						 ^self].
					ts cr].
				proxy := VMCompiledMethodProxy new
								for: aMethod
								coInterpreter: self
								objectMemory: objectMemory.
				(DetailedInstructionPrinter on: proxy)
					stackHeightComputer: (StackDepthFinder on: proxy);
					indent: 0;
					printInstructionsOn: ts]) copyReplaceAll: 'a VMObjectProxy for ' with: '');
		flush
]

{ #category : #'send bytecodes' }
StackInterpreter >> directedSuperclassSend [
	"Send a message to self, starting lookup with the superclass of the class on top of stack."
	"Assume: messageSelector and argumentCount have been set, and that
	 the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	<sharedCodeInCase: #extSendSuperBytecode>
	<option: #BytecodeSetHasDirectedSuperSend>
	| class superclass |
	class := self internalPopStack.
	(objectMemory isForwarded: class) ifTrue:
		[class := objectMemory followForwarded: class].
	superclass := self superclassOf: class.
	"classTagForClass: uses ensureBehaviorHash:"
	lkupClassTag := objectMemory classTagForClass: superclass.
	"To maintain the invariant that all receivers are unforwarded we need an explicit
	 read barrier in the super send cases.  Even though we always follow receivers
	 on become  e.g. super doSomethingWith: (self become: other) forwards the receiver
	 self pushed on the stack."
	self ensureReceiverUnforwarded.
	self assert: lkupClassTag ~= objectMemory nilObject.
	self commonSendOrdinary
]

{ #category : #'vm scheduling' }
StackInterpreter >> disownVM: flags [
	<api>
	<inline: false>
	"Release the VM to other threads and answer the current thread's index.
	 Currently valid flags for the non-threaded VM are:
		DisownVMLockOutFullGC	- prevent fullGCs while this thread disowns the VM
		DisownVMForFFICall			- informs the VM that it is entering an FFI call

	 This is the entry-point for plugins and primitives that wish to release the VM while
	 performing some operation that may potentially block, and for callbacks returning
	 back to some blocking operation.  While this exists for the threaded FFI VM we use
	 it to reset newMethod and the argumentCount after a callback."
	self assert: primFailCode = 0.

	"Hack encodings of client state.  We use non-immediates (bottom three bits clear)
	 for FFI/Plugin doing
		save := self disownVM: FLAGS. ... callout ... self ownVM: save.
	 We use immediate integer (bottom bit 1) for callbacks doing
		save := self ownVM: 0. ... callback ... self disownVM: save. return to C"
	self assert: ((objectMemory isImmediate: flags)
				ifFalse:
					[flags = (flags bitAnd: DisownVMLockOutFullGC+DisownVMForFFICall+DisownVMForThreading)
					 and: [flags anyMask: DisownVMForFFICall]]
				ifTrue:
					[(objectMemory isIntegerObject: flags)
					 and: [(objectMemory integerValueOf: flags)
							between: 0
							and: (self argumentCountOfMethodHeader: -1)]]).

	"If DisownVMForFFICall this is from the FFI plugin and we're making a callout; remember the fact."
	(((objectMemory isImmediate: flags)) not
	 and: [flags anyMask: DisownVMForFFICall]) ifTrue:
		[self assert: ((objectMemory isOopCompiledMethod: newMethod)
				and: [(self argumentCountOf: newMethod) = argumentCount]).
		 inFFIFlags := DisownVMForFFICall.
		 ^flags].

	self assert: ((objectMemory isIntegerObject: flags)
				and: [(objectMemory integerValueOf: flags)
						between: 0
						and: (self argumentCountOfMethodHeader: -1)]).

	"Otherwise this is a callback return; restore argumentCount and newMethod as per the ownVM: on callback."
	argumentCount := objectMemory integerValueOf: flags.
	newMethod := self popStack.
	self assert: ((objectMemory isOopCompiledMethod: newMethod)
				and: [(self argumentCountOf: newMethod) = argumentCount]).
	^0
]

{ #category : #'message sending' }
StackInterpreter >> dispatchFunctionPointer: aFunctionPointer [
	"In C aFunctionPointer is void (*aFunctionPointer)()"
	<cmacro: '(aFunctionPointer) (aFunctionPointer)()'>
	"In Smalltalk aFunctionPointer is a message selector symbol, except for
	 external primitives which are funkily encoded as integers >= 1000."
	(aFunctionPointer isInteger
	 and: [aFunctionPointer >= 1000])
		ifTrue: [self callExternalPrimitive: aFunctionPointer]
		ifFalse: [self perform: aFunctionPointer]
]

{ #category : #simulation }
StackInterpreter >> displayBits [
	<doNotGenerate>
	^displayBits
]

{ #category : #'frame access' }
StackInterpreter >> divorceAllFrames [
	| activeContext |
	<inline: false>
	<var: #aPage type: #'StackPage *'>
	stackPage ~= 0 ifTrue:
		[self externalWriteBackHeadFramePointers].
	activeContext := self
						ensureFrameIsMarried: framePointer
						SP: stackPointer + objectMemory wordSize.
	0 to: numStackPages - 1 do:
		[:i| | aPage |
		aPage := stackPages stackPageAt: i.
		(stackPages isFree: aPage) ifFalse:
			[self divorceFramesIn: aPage]].
	self zeroStackPage.
	^activeContext
]

{ #category : #'frame access' }
StackInterpreter >> divorceFramesIn: aStackPage [
	| theFP calleeFP theSP theIP calleeContext theContext |
	<inline: false>
	<var: #aStackPage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<var: #calleeFP type: #'char *'>
	<var: #theSP type: #'char *'>

	statStackPageDivorce := statStackPageDivorce + 1.

	theFP := aStackPage headFP.
	theSP := aStackPage headSP.
	theIP := stackPages longAt: theSP.
	theSP := theSP + objectMemory wordSize. "theSP points at hottest item on frame's stack"
	calleeContext := nil.

	[theContext := self ensureFrameIsMarried: theFP SP: theSP.
	 self updateStateOfSpouseContextForFrame: theFP WithSP: theSP.
	 objectMemory storePointerUnchecked: InstructionPointerIndex
		ofObject: theContext
		withValue: (self contextInstructionPointer: theIP frame: theFP).
	 self assert: (self frameReceiver: theFP)
				= (objectMemory fetchPointer: ReceiverIndex ofObject: theContext).
	 calleeContext ~~ nil ifTrue:
		[objectMemory storePointer: SenderIndex
			ofObject: calleeContext
			withValue: theContext].
	 calleeContext := theContext.
	 calleeFP := theFP.
	 theIP := (self frameCallerSavedIP: theFP) asInteger.
	 theFP := self frameCallerFP: theFP.
	 theFP ~= 0] whileTrue:
		["theSP points at stacked hottest item on frame's stack"
		 theSP := self frameCallerSP: calleeFP].

	objectMemory storePointer: SenderIndex
		ofObject: theContext
		withValue: (self frameCallerContext: calleeFP).

	"The page is now free; mark it so."
	aStackPage baseFP: 0
]

{ #category : #simulation }
StackInterpreter >> doItContext [
	"This is for the bottom-right-hand pane in the simulator window."
	<doNotGenerate>
	^nil
]

{ #category : #simulation }
StackInterpreter >> doItReceiver [
	"This is for the bottom-right-hand pane in the simulator window."
	<doNotGenerate>
	^self
]

{ #category : #'arithmetic primitive support' }
StackInterpreter >> doPrimitiveDiv: rcvr by: arg [
	"Rounds negative results towards negative infinity, rather than zero."
	| result posArg posRcvr integerRcvr integerArg |
	(objectMemory areIntegers: rcvr and: arg)
		ifTrue: [integerRcvr := objectMemory integerValueOf: rcvr.
				integerArg := objectMemory integerValueOf: arg.
				self success: integerArg ~= 0]
		ifFalse: [self primitiveFail].
	self successful ifFalse: [^ 1 "fail"].

	integerRcvr > 0
		ifTrue: [integerArg > 0
					ifTrue: [result := integerRcvr // integerArg]
					ifFalse: ["round negative result toward negative infinity"
							posArg := 0 - integerArg.
							result := 0 - ((integerRcvr + (posArg - 1)) // posArg)]]
		ifFalse: [posRcvr := 0 - integerRcvr.
				integerArg > 0
					ifTrue: ["round negative result toward negative infinity"
							result := 0 - ((posRcvr + (integerArg - 1)) // integerArg)]
					ifFalse: [posArg := 0 - integerArg.
							result := posRcvr // posArg]].
	self success: (objectMemory isIntegerValue: result).
	^ result
]

{ #category : #'arithmetic primitive support' }
StackInterpreter >> doPrimitiveMod: rcvr by: arg [
	| integerResult integerRcvr integerArg |
	(objectMemory areIntegers: rcvr and: arg)
		ifTrue: [integerRcvr := objectMemory integerValueOf: rcvr.
				integerArg := objectMemory integerValueOf: arg.
				self success: integerArg ~= 0]
		ifFalse: [self primitiveFail].
	self successful ifFalse: [^ 1 "fail"].

	integerResult := integerRcvr \\ integerArg.

	"ensure that the result has the same sign as the integerArg"
	integerArg < 0
		ifTrue: [integerResult > 0
			ifTrue: [integerResult := integerResult + integerArg]]
		ifFalse: [integerResult < 0
			ifTrue: [integerResult := integerResult + integerArg]].
	self success: (objectMemory isIntegerValue: integerResult).
	^ integerResult
]

{ #category : #'process primitive support' }
StackInterpreter >> doSignalSemaphoreWithIndex: index [
	"Signal the external semaphore with the given index.  Answer if a context switch
	 occurs as a result.  Do not bounds check.  This has been done in the caller."
	<api>
	| sema |
	
	sema := self getExternalSemaphoreWithIndex: index.
	
	^(objectMemory isSemaphoreOop: sema)
	  and: [self synchronousSignal: sema]
]

{ #category : #'send bytecodes' }
StackInterpreter >> doubleExtendedDoAnythingBytecode [
	"Replaces the Blue Book double-extended send [132], in which the first byte was wasted on 8 bits of argument count. 
	Here we use 3 bits for the operation sub-type (opType),  and the remaining 5 bits for argument count where needed. 
	The last byte give access to 256 instVars or literals. 
	See also secondExtendedSendBytecode"
	| byte2 byte3 opType top |
	byte2 := self fetchByte.
	byte3 := self fetchByte.
	opType := byte2 >> 5.
	opType = 0 ifTrue:
		[messageSelector := self literal: byte3.
		 argumentCount := byte2 bitAnd: 31.
		 ^self normalSend].
	opType = 1 ifTrue:
		[messageSelector := self literal: byte3.
		 argumentCount := byte2 bitAnd: 31.
		 ^self superclassSend].
	opType = 2 ifTrue: [self fetchNextBytecode. ^self pushMaybeContextReceiverVariable: byte3].
	opType = 3 ifTrue: [self fetchNextBytecode. ^self pushLiteralConstant: byte3].
	opType = 4 ifTrue: [self fetchNextBytecode. ^self pushLiteralVariable: byte3].
	top := self internalStackTop.
	opType = 7 ifTrue:
		[self storeLiteralVariable: byte3 withValue: top.
		 ^self fetchNextBytecode].
	"opType = 5 is store; opType = 6 is storePop"
	opType = 6 ifTrue:
		[self internalPop: 1].
	self storeMaybeContextReceiverVariable: byte3 withValue: top.
	self fetchNextBytecode
]

{ #category : #initialization }
StackInterpreter >> dummyReferToProxy [
	<inline: false>
	interpreterProxy := interpreterProxy
]

{ #category : #'image save/restore' }
StackInterpreter >> dumpImage: fileName [
	"Dump the entire image out to the given file. Intended for debugging only.  Doesn't work for Spur."
	| f dataSize result |
	<notOption: #SpurObjectMemory>
	<export: true>
	<var: #f type: #sqImageFile>

	f := self sqImageFile: (self pointerForOop: fileName) Open: 'wb'.
	f = nil ifTrue: [^-1].
	dataSize := objectMemory endOfMemory - objectMemory startOfMemory.
	result := self sq: (self pointerForOop: self memory) Image: (self sizeof: #'unsigned char') File: dataSize Write: f.
	self sqImageFileClose: f.
	^result
]

{ #category : #'debug support' }
StackInterpreter >> dumpPrimTraceLog [
	"Dummy definition to allow the StackInterpreter to link against the Cog run-time."

	<api>
]

{ #category : #'stack bytecodes' }
StackInterpreter >> duplicateTopBytecode [

	self fetchNextBytecode.
	self internalPush: self internalStackTop.

]

{ #category : #'debug printing' }
StackInterpreter >> elementsPerPrintOopLine [
	^5
]

{ #category : #'frame access' }
StackInterpreter >> encodeFrameFieldHasContext: hasContext "<Boolean>" isBlock: isBlock "<Boolean>" numArgs: numArgs [
	"For ``fast'' temporary access (ok, to mitigate slower temp access) we need
	 fast access to a method's numArgs.  Could have a variable set on save and return.
	 We'll investigate this.  For the moment we just use a byte in the frameFlags
	 field.  This is endian dependent.  Store numArgs in byte at FoxFrameFields + 1.
	 Store hasContext flag in top bit (allows for 64-bit tags) of byte at FoxFrameFields.
	 Make frameFields look like a SmallInteger for the benefit of gc (dubious)."
	"bitsPerWord := BytesPerWord * 8"
	<inline: true>
	^VMBIGENDIAN
		ifTrue: [1
				+ (numArgs << ((objectMemory wordSize * 8) - 8))
				+ (hasContext ifTrue: [1 << ((objectMemory wordSize * 8) - 16)] ifFalse: [0])
				+  (isBlock ifTrue: [1 << ((objectMemory wordSize * 8) - 24)] ifFalse: [0])]
		ifFalse: [1
				+ (numArgs << 8)
				+  (hasContext ifTrue: [1 << 16] ifFalse: [0])
				+  (isBlock ifTrue: [1 << 24] ifFalse: [0])]
]

{ #category : #simulation }
StackInterpreter >> encoderClassForHeader: headerInteger [
	<doNotGenerate>
	^Smalltalk classNamed: ((headerInteger < 0 or: [objectMemory headerIndicatesAlternateBytecodeSet: headerInteger])
								ifTrue: [AltBytecodeEncoderClassName]
								ifFalse: [BytecodeEncoderClassName])
]

{ #category : #'frame access' }
StackInterpreter >> ensureCallerContext: theFP [
	"Answerr the caller context for a frame.  If the frame has a caller
	 frame that doesn't have a context, then marry the caller frame."
	| callerFP |
	<inline: true>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	callerFP := self frameCallerFP: theFP.
	callerFP = 0 ifTrue: "base frame, context in saved ip slot (or base of stack in Cog)"
		[^self frameCallerContext: theFP].
	^self ensureFrameIsMarried: callerFP SP: (self frameCallerStackPointer: theFP)
]

{ #category : #'frame access' }
StackInterpreter >> ensureContextHasBytecodePC: aContext [
	"Make sure the context has a byetcode pc.  Can only be used on single contexts.
	 This is a nop in the StackInterpreter."
]

{ #category : #'frame access' }
StackInterpreter >> ensureContextIsExecutionSafeAfterAssignToStackPointer: aContext [
	"Safety to give the JIT lattitude in calling convention.  A noop in the interpreter.
	 See subclass implementation(s) for explanation."
]

{ #category : #'frame access' }
StackInterpreter >> ensureFrameIsMarried: theFP SP: theSP [
	<inline: true>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	(self frameHasContext: theFP) ifTrue:
		[self assert: (objectMemory isContext: (self frameContext: theFP)).
		^self frameContext: theFP].

	^self marryFrame: theFP SP: theSP
]

{ #category : #'image save/restore' }
StackInterpreter >> ensureImageFormatIsUpToDate: swapBytes [
	"Ensure the image data has been updated to suit the current VM."
	<inline: false>
	swapBytes
		ifTrue: [self reverseBytesInImage]
		ifFalse: [self convertFloatsToPlatformOrder]
]

{ #category : #'send bytecodes' }
StackInterpreter >> ensureReceiverUnforwarded [
	"To maintain the invariant that all receivers are unforwarded we need an explicit
	 read barrier in the super send cases."
	(objectMemory isOopForwarded: (self internalStackValue: argumentCount)) ifTrue:
		[self internalStackValue: argumentCount
			put: (objectMemory followForwarded: (self internalStackValue: argumentCount))]
]

{ #category : #initialization }
StackInterpreter >> enterSmalltalkExecutive [
	"Main entry-point into the interpreter at each execution level, where an
	 execution level is either the start of execution or reentry for a callback."
	<cmacro: '() enterSmalltalkExecutiveImplementation()'>
	"Simulation of the setjmp in enterSmalltalkExecutiveImplementation for reentry into interpreter."
	[([self enterSmalltalkExecutiveImplementation]
		on: ReenterInterpreter
		do: [:ex| ex return: ex returnValue]) = ReturnToInterpreter] whileTrue
]

{ #category : #'callback support' }
StackInterpreter >> enterSmalltalkExecutiveFromCallback [
	<inline: true>
	self enterSmalltalkExecutive
]

{ #category : #initialization }
StackInterpreter >> enterSmalltalkExecutiveImplementation [
	"Main entry-point into the interpreter at each execution level, where an execution
	 level is either the start of execution or reentry for a callback.
	 This is the actual implementation, separated from enterSmalltalkExecutive so the
	 simulator can wrap it in an exception handler and hence simulate the setjmp/longjmp."
	<inline: false>
	"Setjmp for reentry into interpreter from elsewhere, e.g. FFI exception primitive failure."
	self sigset: reenterInterpreter jmp: 0.
	self setMethod: (self frameMethod: framePointer).
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: true line: #'__LINE__'.
	self interpret.
	^0
]

{ #category : #'frame access' }
StackInterpreter >> establishFrameForContextToReturnTo: contextToReturnTo [
	| thePage |
	<var: #thePage type: #'StackPage *'>
	<returnTypeC: 'char *'>
	(objectMemory isContext: contextToReturnTo) ifFalse:
		[^0].
	(self isMarriedOrWidowedContext: contextToReturnTo) ifTrue:
		[(self isWidowedContext: contextToReturnTo) ifTrue:
			["error: home's sender is dead; cannot return"
			 ^0].
		 ^self frameOfMarriedContext: contextToReturnTo].
	(objectMemory isIntegerObject: (objectMemory fetchPointer: InstructionPointerIndex ofObject: contextToReturnTo)) ifFalse:
		[^0].
	thePage := self makeBaseFrameFor: contextToReturnTo.
	stackPages markStackPageMostRecentlyUsed: thePage.
	^thePage baseFP
]

{ #category : #'message sending' }
StackInterpreter >> executeNewMethod [
	"Execute newMethod - either primitiveFunctionPointer must be set directly
	 (i.e. from primitiveExecuteMethod et al), or it would have been set probing
	 the method cache (i.e. primitivePerform et al)."
	primitiveFunctionPointer ~= 0 ifTrue:
		[self isPrimitiveFunctionPointerAnIndex ifTrue:
			[self externalQuickPrimitiveResponse.
			 ^nil].
		 self slowPrimitiveResponse.
		 self successful ifTrue: [^nil]].
	"if not primitive, or primitive failed, activate the method"
	self activateNewMethod
]

{ #category : #'translation support' }
StackInterpreter >> expandCases [
	"For translation only; noop when running in Smalltalk.
	 Must not be inlined otherwise the directive will disappear!"
	<inline: false>
]

{ #category : #'miscellaneous bytecodes' }
StackInterpreter >> extABytecode [
	"224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)"
	extA := (extA bitShift: 8) + self fetchByte.
	self fetchNextBytecode
]

{ #category : #'miscellaneous bytecodes' }
StackInterpreter >> extBBytecode [
	"225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)"
	| byte |
	byte := self fetchByte.
	self fetchNextBytecode.
	extB := (numExtB = 0 and: [byte > 127])
				ifTrue: [byte - 256]
				ifFalse: [(extB bitShift: 8) + byte].
	numExtB := numExtB + 1
]

{ #category : #'jump bytecodes' }
StackInterpreter >> extJumpIfFalse [
	"244		11110100	i i i i i i i i	Pop and Jump 0n False i i i i i i i i (+ Extend B * 256, where Extend B >= 0)"
	| byte offset |
	byte := self fetchByte.
	offset := byte + (extB << 8).
	numExtB := extB := extA := 0.
	self jumplfFalseBy: offset
]

{ #category : #'jump bytecodes' }
StackInterpreter >> extJumpIfTrue [
	"243		11110011	i i i i i i i i	Pop and Jump 0n True i i i i i i i i (+ Extend B * 256, where Extend B >= 0)"
	| byte offset |
	byte := self fetchByte.
	offset := byte + (extB << 8).
	numExtB := extB := extA := 0.
	self jumplfTrueBy: offset
]

{ #category : #'miscellaneous bytecodes' }
StackInterpreter >> extNopBytecode [
	"SistaV1		94		01011111		Nop"
	self fetchNextBytecode.
	numExtB := extA := extB := 0
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extPushCharacterBytecode [
	"SistaV1:	*	233		11101001	iiiiiiii		Push Character #iiiiiiii (+ Extend B * 256)"
	| value |
	value := self fetchByte + (extB << 8).
	self fetchNextBytecode.
	self internalPush: (objectMemory characterObjectOf: value).
	numExtB := extB := 0
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extPushClosureBytecode [
	"253		11111101 eei i i kkk	jjjjjjjj		Push Closure Num Copied iii (+ Ext A // 16 * 8) Num Args kkk (+ Ext A \\ 16 * 8) BlockSize jjjjjjjj (+ Ext B * 256). ee = num extensions.
	 The compiler has pushed the values to be copied, if any.  Find numArgs and numCopied in the byte following.
	 Create a Closure with space for the copiedValues and pop numCopied values off the stack into the closure.
	 Set numArgs as specified, and set startpc to the pc following the block size and jump over that code."
	| byte numArgs numCopied blockSize |
	byte := self fetchByte.
	numArgs := (byte bitAnd: 7) + (extA \\ 16 * 8).
	numCopied := ((byte >> 3) bitAnd: 7) + (extA // 16 * 8).
	extA := 0.
	blockSize := self fetchByte + (extB << 8).
	numExtB := extB := 0.
	self pushClosureNumArgs: numArgs copiedValues: numCopied blockSize: blockSize
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extPushFullClosureBytecode [
	"255		11111111	xxxxxxxx	siyyyyyy	
		push Closure Compiled block literal index xxxxxxxx (+ Extend A * 256) 
		numCopied yyyyyy 
		receiverOnStack: s = 1 
		ignoreOuterContext: i = 1
	 The compiler has pushed the values to be copied, if any. The receiver has been pushed on stack before if specified. 
	 Create a Closure with space for the copiedValues and pop numCopied values off the stack into the closure.
	 Sets outerContext, compiledBlock, numArgs and receiver as specified.."
	| compiledBlockLiteralIndex compiledBlock byte numArgs numCopied receiverIsOnStack ignoreContext |
	compiledBlockLiteralIndex := self fetchByte + (extA << 8).
	extA := 0.
	compiledBlock := self literal: compiledBlockLiteralIndex.
	self assert: (objectMemory isOopCompiledMethod: compiledBlock).
	numArgs := self argumentCountOf: compiledBlock.
	byte := self fetchByte.
	numCopied := byte bitAnd: 1<< 6 - 1.
	receiverIsOnStack := byte anyMask: 1 << 7.
	ignoreContext := byte anyMask: 1 << 6.
	self pushFullClosureNumArgs: numArgs copiedValues: numCopied compiledBlock: compiledBlock receiverIsOnStack: receiverIsOnStack ignoreContext: ignoreContext
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extPushIntegerBytecode [
	"229		11100101	i i i i i i i i	Push Integer #iiiiiiii (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	| value |
	value := self fetchByte + (extB << 8).
	self fetchNextBytecode.
	extB := 0.
	numExtB := 0.
	self internalPush: (objectMemory integerObjectOf: value)
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extPushLiteralBytecode [
	"228		11100100	i i i i i i i i	Push Literal #iiiiiiii (+ Extend A * 256)"
	| index |
	index := self fetchByte + (extA << 8).
	self fetchNextBytecode.
	extA := 0.
	self pushLiteralConstant: index
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extPushLiteralVariableBytecode [
	"227		11100011	i i i i i i i i	Push Literal Variable #iiiiiiii (+ Extend A * 256)"
	| index |
	index := self fetchByte + (extA << 8).
	self fetchNextBytecode.
	extA := 0.
	self pushLiteralVariable: index
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extPushPseudoVariable [
	"SistaV1:	*	82			01010010			Push thisContext, (then e.g. Extend B 1 = push thisProcess)"
	| theThingToPush |
	extB
		caseOf: {
			[0]	->	[theThingToPush := self ensureFrameIsMarried: localFP SP: localSP].
			[1]	->	[theThingToPush := self activeProcess] }
		otherwise:
			[self respondToUnknownBytecode].
	self fetchNextBytecode.
	self internalPush: theThingToPush.
	extB := 0.
	numExtB := 0.
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extPushReceiverVariableBytecode [
	"226		11100010	i i i i i i i i	Push Receiver Variable #iiiiiiii (+ Extend A * 256)"
	| index |
	index := self fetchByte + (extA << 8).
	self fetchNextBytecode.
	extA := 0.
	self pushMaybeContextReceiverVariable: index
]

{ #category : #'return bytecodes' }
StackInterpreter >> extReturnTopFromBlock [
	"218		11011010		Return Stack Top From Block [* return from enclosing block N, N = Extend A]
	 If extA is zero, return to the caller of the current block activation.
	 If extA is non-zero return to the caller of the Nth enclosing block activation."
	extA = 0 ifTrue:
		[localReturnValue := self internalStackTop.
		 ^self commonCallerReturn].
	self shouldBeImplemented.
	extA := 0
]

{ #category : #'send bytecodes' }
StackInterpreter >> extSendBytecode [
	"238		11101110	i i i i i j j j	Send Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments"
	| byte rcvr |
	byte := self fetchByte.
	messageSelector := self literal: (byte >> 3) + (extA << 5).
	extA := 0.
	argumentCount := (byte bitAnd: 7) + (extB << 3).
	extB := 0.
	numExtB := 0.
	rcvr := self internalStackValue: argumentCount.
	lkupClassTag := objectMemory fetchClassTagOf: rcvr.
	self commonSendOrdinary
]

{ #category : #'send bytecodes' }
StackInterpreter >> extSendSuperBytecode [
	"239		11101111	i i i i i j j j
		ExtendB < 64
			ifTrue: [Send To Superclass Literal Selector #iiiii (+ Extend A * 32) with jjj (+ Extend B * 8) Arguments]
			ifFalse: [Send To Superclass of Stacked Class Literal Selector #iiiii (+ Extend A * 32) with jjj (+ (Extend B bitAnd: 63) * 8) Arguments]"
	| byte |
	byte := self fetchByte.
	messageSelector := self literal: (byte >> 3) + (extA << 5).
	extA := 0.
	BytecodeSetHasDirectedSuperSend ifTrue:
		[extB >= 64 ifTrue:
			[argumentCount := (byte bitAnd: 7) + (extB - 64 << 3).
			 extB := 0.
			 numExtB := 0.
			 ^self directedSuperclassSend]].
	argumentCount := (byte bitAnd: 7) + (extB << 3).
	extB := 0.
	numExtB := 0.
	self superclassSend
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extStoreAndPopLiteralVariableBytecode [
	"236		11101100	i i i i i i i i	Pop and Store Literal Variable #iiiiiiii (+ Extend A * 256)"
	| variableIndex value |
	variableIndex := self fetchByte + (extA << 8).
	value := self internalStackTop.
	self internalPop: 1.
	extA := 0.
	self storeLiteralVariable: variableIndex withValue: value.
	self fetchNextBytecode.
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extStoreAndPopReceiverVariableBytecode [
	"235		11101011	i i i i i i i i	Pop and Store Receiver Variable #iiiiiii (+ Extend A * 256)"
	| variableIndex value |
	variableIndex := self fetchByte + (extA << 8).
	extA := 0.
	value := self internalStackTop.
	self internalPop: 1.
	self storeMaybeContextReceiverVariable: variableIndex withValue: value.
	self fetchNextBytecode.
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extStoreLiteralVariableBytecode [
	"233		11101001	i i i i i i i i	Store Literal Variable #iiiiiiii (+ Extend A * 256)"
	| variableIndex |
	variableIndex := self fetchByte + (extA << 8).
	extA := 0.
	self storeLiteralVariable: variableIndex withValue: self internalStackTop.
	self fetchNextBytecode.
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extStoreReceiverVariableBytecode [
	"232		11101000	i i i i i i i i	Store Receiver Variable #iiiiiii (+ Extend A * 256)"
	| variableIndex |
	variableIndex := self fetchByte + (extA << 8).
	extA := 0.
	self storeMaybeContextReceiverVariable: variableIndex withValue: self internalStackTop.
	self fetchNextBytecode.
]

{ #category : #'jump bytecodes' }
StackInterpreter >> extUnconditionalJump [
	"242		11110010	i i i i i i i i	Jump i i i i i i i i (+ Extend B * 256, where bbbbbbbb = sddddddd, e.g. -32768 = i=0, a=0, s=1)"
	| byte offset bcpcDelta |
	byte := self fetchByte.
	offset := byte + (extB << 8).
	bcpcDelta := offset < 0 ifTrue: [numExtB * 2] ifFalse: [0].
	extB := 0.
	numExtB := 0.
	localIP := localIP + offset.
	self ifBackwardsCheckForEvents: offset + bcpcDelta.
	self fetchNextBytecode
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extendedPushBytecode [

	| descriptor variableType variableIndex |
	descriptor := self fetchByte.
	self fetchNextBytecode.
	variableType := (descriptor >> 6) bitAnd: 16r3.
	variableIndex := descriptor bitAnd: 16r3F.
	variableType=0 ifTrue: [^self pushReceiverVariable: variableIndex].
	variableType=1 ifTrue: [^self pushTemporaryVariable: variableIndex].
	variableType=2 ifTrue: [^self pushLiteralConstant: variableIndex].
	variableType=3 ifTrue: [^self pushLiteralVariable: variableIndex].

]

{ #category : #'stack bytecodes' }
StackInterpreter >> extendedStoreAndPopBytecode [
	<inline: true>
	self extendedStoreBytecodePop: true
	"may not be reached (immutable receiver)"
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extendedStoreBytecode [
	<inline: true>
	self extendedStoreBytecodePop: false
	"may not be reached (immutable receiver)"
]

{ #category : #'stack bytecodes' }
StackInterpreter >> extendedStoreBytecodePop: popBoolean [
	| descriptor variableType variableIndex value |
	<inline: true>
	descriptor := self fetchByte.
	variableType := descriptor >> 6 bitAnd: 3.
	variableIndex := descriptor bitAnd: 63.
	value := self internalStackTop.
	popBoolean ifTrue: [ self internalPop: 1 ].
	variableType = 0 ifTrue:
		[objectMemory storePointerImmutabilityCheck: variableIndex ofObject: self receiver withValue: value.
		^ self fetchNextBytecode].
	variableType = 1 ifTrue:
		[ self fetchNextBytecode.
		self temporary: variableIndex in: localFP put: value.
		^ self "keep slang happy"].
	variableType = 3 ifTrue:
		[self storeLiteralVariable: variableIndex withValue: value.
		^ self fetchNextBytecode].
	self error: 'illegal store'

]

{ #category : #'frame access' }
StackInterpreter >> externalDivorceFrame: theFP andContext: ctxt [
	"Divorce a single frame and its context.  If it is not the top frame of a stack this means splitting its stack."
	| thePage onCurrent theSP callerCtx newPage frameAbove callerFP callerSP callerIP theIP |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	<var: #newPage type: #'StackPage *'>
	<var: #frameAbove type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #callerSP type: #'char *'>
	"stackPage needs to have current head pointers to avoid confusion."
	self assert: (stackPage = 0 or: [stackPage = stackPages mostRecentlyUsedPage]).
	thePage := stackPages stackPageFor: theFP.
	(onCurrent := thePage = stackPage) ifFalse:
		[stackPages markStackPageNextMostRecentlyUsed: thePage].
	theSP := self findSPOf: theFP on: thePage.
	self updateStateOfSpouseContextForFrame: theFP WithSP: theSP.
	callerCtx := self ensureCallerContext: theFP.
	(frameAbove := self findFrameAbove: theFP inPage: thePage) = 0
		ifTrue: "If we're divorcing the top frame we can simply peel it off."
			[theIP := stackPages longAt: thePage headSP]
		ifFalse: "othewise move all frames above to a new stack and then peel the frame off."
			[newPage := stackPages newStackPage.
			 theIP := self oopForPointer: (self frameCallerSavedIP: frameAbove).
			 frameAbove := self moveFramesIn: thePage through: frameAbove toPage: newPage.
			 onCurrent
				ifTrue:
					[self setStackPageAndLimit: newPage.
					 self setStackPointersFromPage: newPage]
				ifFalse:
					[stackPages markStackPageMostRecentlyUsed: newPage].
			 self assert: (self frameCallerContext: frameAbove) = ctxt].
	objectMemory storePointerUnchecked: InstructionPointerIndex
		ofObject: ctxt
		withValue: (self contextInstructionPointer: theIP frame: theFP).
	objectMemory storePointer: SenderIndex
		ofObject: ctxt
		withValue: callerCtx.
	callerFP := self frameCallerFP: theFP.
	callerFP = 0 "theFP is a base frame; it is now alone; free the entire page"
		ifTrue: [stackPages freeStackPage: thePage]
		ifFalse:
			[callerIP := self oopForPointer: (self frameCallerSavedIP: theFP).
			 callerSP := (self frameCallerSP: theFP) - objectMemory wordSize.
			 stackPages longAt: callerSP put: callerIP.
			 self setHeadFP: callerFP andSP: callerSP inPage: thePage]
	
]

{ #category : #'frame access' }
StackInterpreter >> externalEnsureIsBaseFrame: aFramePtr [
	"Ensure aFramePtr is a base frame.  Then we can assign its sender.
	 Answer the possibly moved location of the frame."
	| theFP thePage onCurrent |
	<var: #aFramePtr type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<returnTypeC: 'char *'>
	(self isBaseFrame: aFramePtr) ifTrue:
		[^aFramePtr].
	theFP := aFramePtr.
	thePage := stackPages stackPageFor: theFP.
	onCurrent := thePage = stackPage.
	"Storing the frame's sender with its caller's context
	 has the side effect of making theFP a base frame."
	theFP := self
				storeSenderOfFrame: theFP
				withValue: (self ensureCallerContext: theFP).
	onCurrent
		ifTrue:
			[self assert: stackPage ~~ thePage. "stackPage has moved to a new page"
			 self setStackPointersFromPage: stackPage]
		ifFalse:
			[stackPages markStackPageMostRecentlyUsed: stackPage].
	self assert: stackPages pageListIsWellFormed.
	self assert: stackPage = stackPages mostRecentlyUsedPage.
	^theFP
]

{ #category : #'frame access' }
StackInterpreter >> externalInstVar: offset ofContext: aContext [
	"Fetch an instance variable from a maybe married context.
	 If the context is still married compute the value of the
	 relevant inst var from the spouse frame's state."
	<inline: false>

	self assert: (objectMemory isContext: aContext).
	self assert: offset <= (ReceiverIndex + (self checkStackPointerForMaybeMarriedContext: aContext)).
	"method, closureOrNil & receiver need no special handling; only
	 sender, pc & stackp have to be computed for married contexts."
	(self isReadMediatedContextInstVarIndex: offset) ifTrue:
		[self externalWriteBackHeadFramePointers.
		 (self isStillMarriedContext: aContext) ifTrue:
			[^self fetchPointer: offset ofMarriedContext: aContext]].
	
	^objectMemory fetchPointer: offset ofObject: aContext
]

{ #category : #'frame access' }
StackInterpreter >> externalInstVar: index ofContext: maybeMarriedContext put: anOop [
	| theFP thePage onCurrentPage |
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	self assert: (objectMemory isContext: maybeMarriedContext).
	self externalWriteBackHeadFramePointers.
	"Assign the field of a married context."
	self deny: (objectMemory isObjImmutable: maybeMarriedContext).
	(self isStillMarriedContext: maybeMarriedContext) ifFalse:
		[objectMemory storePointer: index ofObject: maybeMarriedContext withValue: anOop.
		 index = StackPointerIndex ifTrue:
			[self ensureContextIsExecutionSafeAfterAssignToStackPointer: maybeMarriedContext].
		 ^nil].
	theFP := self frameOfMarriedContext: maybeMarriedContext.
	thePage := stackPages stackPageFor: theFP.
	self assert: stackPage = stackPages mostRecentlyUsedPage.
	onCurrentPage := thePage = stackPage.
	index = SenderIndex
		ifTrue:
			[self storeSenderOfFrame: theFP withValue: anOop]
		ifFalse:
			[self externalDivorceFrame: theFP andContext: maybeMarriedContext.
			 (self is: index methodAssignmentToContextWithMachineCodePC: maybeMarriedContext) ifTrue:
				[self ensureContextHasBytecodePC: maybeMarriedContext].
			 objectMemory storePointer: index ofObject: maybeMarriedContext withValue: anOop.
			 index = StackPointerIndex ifTrue:
				[self ensureContextIsExecutionSafeAfterAssignToStackPointer: maybeMarriedContext]].
	onCurrentPage
		ifTrue:
			[self setStackPointersFromPage: stackPage]
		ifFalse:
			[stackPages markStackPageMostRecentlyUsed: stackPage].
	stackPages assert: stackPage = stackPages mostRecentlyUsedPage.
	stackPages assert: stackPages pageListIsWellFormed.
	stackPages assert: self validStackPageBaseFrames
]

{ #category : #'primitive support' }
StackInterpreter >> externalQuickPrimitiveResponse [
	"Invoke a quick primitive.
	 Called under the assumption that primFunctionPtr has been preloaded"
	
	| localPrimIndex |
	self assert: self isPrimitiveFunctionPointerAnIndex.
	localPrimIndex := self cCoerceSimple: primitiveFunctionPointer to: #sqInt.
	self assert: (localPrimIndex > 255 and: [localPrimIndex < 520]).
	"Quick return inst vars"
	localPrimIndex >= 264 ifTrue:
		[self pop: 1 thenPush: (objectMemory fetchPointer: localPrimIndex - 264 ofObject: self stackTop).
		 ^true].
	"Quick return constants"
	localPrimIndex = 256 ifTrue: [^true "return self"].
	localPrimIndex = 257 ifTrue: [self pop: 1 thenPush: objectMemory trueObject. ^true].
	localPrimIndex = 258 ifTrue: [self pop: 1 thenPush: objectMemory falseObject. ^true].
	localPrimIndex = 259 ifTrue: [self pop: 1 thenPush: objectMemory nilObject. ^true].
	self pop: 1 thenPush: (objectMemory integerObjectOf: localPrimIndex - 261).
	^true
]

{ #category : #'frame access' }
StackInterpreter >> externalSetStackPageAndPointersForSuspendedContextOfProcess: aProcess [
	"Set stackPage, instructionPointer, framePointer and stackPointer for the suspendedContext of
	 aProcess, marrying the context if necessary, and niling the suspendedContext slot.  This is used
	 on process switch to ensure a context has a stack frame and so can continue execution."
	| newContext theFrame thePage newPage |
	<inline: true>
	<var: #theFrame type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #newPage type: #'StackPage *'>
	
	newContext := objectMemory fetchPointer: SuspendedContextIndex ofObject: aProcess.
	self assert: (objectMemory isContext: newContext).
	(self isMarriedOrWidowedContext: newContext) ifTrue:
		[self assert: (self checkIsStillMarriedContext: newContext currentFP: framePointer)].
	objectMemory
		storePointerUnchecked: SuspendedContextIndex
		ofObject: aProcess
		withValue: objectMemory nilObject.
	(self isStillMarriedContext: newContext)
		ifTrue:
			[theFrame := self frameOfMarriedContext: newContext.
			 thePage := stackPages stackPageFor: theFrame.
			 theFrame ~= thePage headFP ifTrue:
				["explicit assignment of suspendedContext can cause switch to interior frame."
				 newPage := stackPages newStackPage.
				 self moveFramesIn: thePage
					through: (self findFrameAbove: theFrame inPage: thePage)
					toPage: newPage.
				  stackPages markStackPageLeastMostRecentlyUsed: newPage].
			 self assert: thePage headFP = theFrame]
		ifFalse:
			[thePage := self makeBaseFrameFor: newContext.
			 theFrame := thePage baseFP].
	self setStackPageAndLimit: thePage.
	self setStackPointersFromPage: thePage.
	(self isMachineCodeFrame: framePointer) ifFalse:
		[self setMethod: (self iframeMethod: framePointer)].
	instructionPointer := self popStack.
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer
]

{ #category : #'stack pages' }
StackInterpreter >> externalWriteBackHeadFramePointers [
	self assert:  (framePointer - stackPointer) < (LargeContextSlots * objectMemory bytesPerOop).
	self assert: stackPage = stackPages mostRecentlyUsedPage.
	self deny: stackPage isFree.
	self setHeadFP: framePointer andSP: stackPointer inPage: stackPage.
	self assert: stackPages pageListIsWellFormed
]

{ #category : #utilities }
StackInterpreter >> externalizeFPandSP [
	"Copy the frame and stack pointers to global variables for use in primitives and other functions outside the interpret loop."
	self assert: (localSP < stackPage baseAddress
				and: [localSP > (stackPage realStackLimit - (LargeContextSlots * objectMemory bytesPerOop))]).
	stackPointer := localSP.
	framePointer := localFP
]

{ #category : #utilities }
StackInterpreter >> externalizeIPandSP [
	"Copy the local instruction, stack and frame pointers to global variables for use in primitives and other functions outside the interpret loop."

	instructionPointer := self oopForPointer: localIP.
	stackPointer := localSP.
	framePointer := localFP
]

{ #category : #'primitive support' }
StackInterpreter >> failUnbalancedPrimitive [
	"not inlined for breakpoint value..."
	<inline: false>
	self primitiveFailFor: PrimErrBadNumArgs
]

{ #category : #utilities }
StackInterpreter >> fetchArray: fieldIndex ofObject: objectPointer [
	"Fetch the instance variable at the given index of the given object. Return the address of first indexable field of resulting array object, or fail if the instance variable does not contain an indexable bytes or words object."
	"Note: May be called by translated primitive code."

	| arrayOop |
	<returnTypeC: 'void *'>
	arrayOop := objectMemory fetchPointer: fieldIndex ofObject: objectPointer.
	^ self arrayValueOf: arrayOop

]

{ #category : #'interpreter shell' }
StackInterpreter >> fetchByte [
	"This method uses the preIncrement builtin function which has no Smalltalk equivalent. Thus, it must be overridden in the simulator."

	^objectMemory byteAtPointer: localIP preIncrement
]

{ #category : #utilities }
StackInterpreter >> fetchFloat: fieldIndex ofObject: objectPointer [
	"Fetch the instance variable at the given index of the given object. Return the C double precision floating point value of that instance variable, or fail if it is not a Float."
	"Note: May be called by translated primitive code."

	| floatOop |
	<returnTypeC: #double>
	floatOop := objectMemory fetchPointer: fieldIndex ofObject: objectPointer.
	^objectMemory floatValueOf: floatOop
]

{ #category : #utilities }
StackInterpreter >> fetchInteger: fieldIndex ofObject: objectPointer [
	"Note: May be called by translated primitive code."

	| intOop |
	<inline: false>
	intOop := objectMemory fetchPointer: fieldIndex ofObject: objectPointer.
	^self checkedIntegerValueOf: intOop
]

{ #category : #'interpreter shell' }
StackInterpreter >> fetchNextBytecode [
	"This method fetches the next instruction (bytecode). Each bytecode method is responsible for fetching the next bytecode, preferably as early as possible to allow the memory system time to process the request before the next dispatch."

	MULTIPLEBYTECODESETS
		ifTrue: [currentBytecode := self fetchByte + bytecodeSetSelector]
		ifFalse: [currentBytecode := self fetchByte]
]

{ #category : #'frame access' }
StackInterpreter >> fetchPointer: offset ofMarriedContext: aContext [
	"Fetch a slot from a married context.  Compute the value
	 of the relevant inst var from the spouse frame's state.

	 This method assumes frame pointers have been written back."
	| spouseFP |
	<inline: false>
	<var: #spouseFP type: #'char *'>

	self assert: (objectMemory isContext: aContext).
	self assert: (stackPage headFP = framePointer and: [stackPage headSP = stackPointer]).
	self assert: (self checkIsStillMarriedContext: aContext currentFP: framePointer).

	"method, closureOrNil & receiver need no special handling; only
	 sender, pc & stackp have to be computed for married contexts."
	offset <= ReceiverIndex ifTrue:
		[(self isReadMediatedContextInstVarIndex: offset) ifFalse:
			[^objectMemory fetchPointer: offset ofObject: aContext].

		 spouseFP := self frameOfMarriedContext: aContext.
		 offset = SenderIndex ifTrue:
			[^self ensureCallerContext: spouseFP].
		 offset = StackPointerIndex ifTrue:
			[^objectMemory integerObjectOf: (self stackPointerIndexForFrame: spouseFP)].
		 offset = InstructionPointerIndex ifTrue:
			[^self instructionPointerForFrame: spouseFP currentFP: framePointer currentIP: instructionPointer]].
	
	spouseFP := self frameOfMarriedContext: aContext.
	^(offset - ReceiverIndex between: 1 and: (self stackPointerIndexForFrame: spouseFP))
		ifTrue: [self temporary: offset - (ReceiverIndex + 1) in: spouseFP]
		ifFalse: [objectMemory nilObject]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> fetchStackPointerOf: aContext [
	"Return the stackPointer of a Context or BlockContext.
	 Does not deal with married contexts.  Use only for debug
	 printing or object tracing functions.  To obtain an accurate
	 stack pointer use stackPointerForMaybeMarriedContext:"
	| sp |
	<inline: true>
	sp := objectMemory fetchPointer: StackPointerIndex ofObject: aContext.
	(objectMemory isIntegerObject: sp) ifFalse: [^0].
	self assert: ReceiverIndex + (objectMemory integerValueOf: sp) < (objectMemory lengthOf: aContext).
	^objectMemory integerValueOf: sp
]

{ #category : #'debug support' }
StackInterpreter >> findClassContainingMethod: meth startingAt: classObj [
	| currClass classDict classDictSize methodArray i |
	(objectMemory isOopForwarded: classObj)
		ifTrue: [currClass := objectMemory followForwarded: classObj]
		ifFalse: [currClass := classObj].
	[self assert: (objectMemory isForwarded: currClass) not.
	 (self addressCouldBeClassObj: currClass) ifFalse:
		[^objectMemory nilObject].
	 classDict := objectMemory noFixupFollowField: MethodDictionaryIndex ofObject: currClass.
	 self assert: (objectMemory isForwarded: classDict) not.
	 classDictSize := objectMemory numSlotsOf: classDict.
	 classDictSize > MethodArrayIndex ifTrue:
		[methodArray := objectMemory noFixupFollowField: MethodArrayIndex ofObject: classDict.
		 self assert: (objectMemory isForwarded: methodArray) not.
		 i := 0.
		 [i < (classDictSize - SelectorStart)] whileTrue:
			[meth = (objectMemory noFixupFollowField: i ofObject: methodArray) ifTrue:
				[^currClass].
			 i := i + 1]].
	 currClass := self noFixupSuperclassOf: currClass.
	 currClass = objectMemory nilObject] whileFalse.
	^currClass		"method not found in superclass chain"
]

{ #category : #'debug support' }
StackInterpreter >> findClassForSelector: aSelector lookupClass: startClass do: unaryBlock [
	"Search startClass' class hierarchy looking for aSelector and if found, evaluate unaryBlock
	 with the class where the selector is found.  Otherwise evaluate unaryBlock with nil."
	| currClass classDict classDictSize i |
	currClass := startClass.
	[classDict := objectMemory fetchPointer: MethodDictionaryIndex ofObject: currClass.
	 classDictSize := objectMemory numSlotsOf: classDict.
	 i := SelectorStart.
	 [i < classDictSize] whileTrue:
		[aSelector = (objectMemory fetchPointer: i ofObject: classDict) ifTrue:
			[^unaryBlock value: currClass].
			i := i + 1].
	 currClass := self superclassOf: currClass.
	 currClass = objectMemory nilObject] whileFalse.
	^unaryBlock value: nil    "selector not found in superclass chain"
		
]

{ #category : #'debug support' }
StackInterpreter >> findClassOfMethod: meth forReceiver: rcvr [
	((objectMemory addressCouldBeOop: rcvr)
	and: [(objectMemory isOopForwarded: rcvr) not]) ifTrue:
		[| rclass |
		 rclass := self
					findClassContainingMethod: meth
					startingAt: (objectMemory fetchClassOf: rcvr).
		 rclass ~= objectMemory nilObject ifTrue:
			[^rclass]].
	((objectMemory addressCouldBeObj: meth)
	 and: [objectMemory isCompiledMethod: meth]) ifFalse:
		[^objectMemory nilObject].
	^self
		findClassContainingMethod: meth
		startingAt: (self safeMethodClassOf: meth)
]

{ #category : #'frame access' }
StackInterpreter >> findFrameAbove: theFP inPage: thePage [
	"Answer the frame above theFP (adjacent frame nearest head end).
	 If theFP is the head frame answer 0."
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	| fp callerFP |
	<var: #fp type: #'char *'>
	<var: #callerFP type: #'char *'>
	<returnTypeC: #'char *'>
	fp := thePage headFP.
	fp = theFP ifTrue:
		[^0].
	[(callerFP := self frameCallerFP: fp) ~= 0] whileTrue:
		[callerFP = theFP ifTrue:
			[^fp].
		 fp := callerFP].
	self error: 'did not find theFP in stack page'.
	^0
]

{ #category : #'debug printing' }
StackInterpreter >> findHomeForContext: aContext [
	| closureOrNil |
	<inline: false>
	(objectMemory isContext: aContext) ifFalse:
		[^nil].
	closureOrNil := objectMemory fetchPointer: ClosureIndex ofObject: aContext.
	closureOrNil = objectMemory nilObject ifTrue:
		[^aContext].
	ClassBlockClosureCompactIndex ~= 0
		ifTrue:
			[((objectMemory compactClassIndexOf: closureOrNil) ~= ClassBlockClosureCompactIndex
			  and: [(objectMemory compactClassIndexOf: closureOrNil) ~= ClassFullBlockClosureCompactIndex]) ifTrue:
				[^nil]]
		ifFalse:
			[(objectMemory fetchClassOf: closureOrNil) ~= (objectMemory splObj: ClassBlockClosure) ifTrue:
				[(ClassFullBlockClosureCompactIndex ~= 0
				  and: [(objectMemory fetchClassOf: closureOrNil) = (objectMemory splObj: ClassFullBlockClosure)]) ifFalse:
					[^nil]]].
	^self findHomeForContext: (objectMemory fetchPointer: ClosureOuterContextIndex ofObject: closureOrNil)
]

{ #category : #'handler search' }
StackInterpreter >> findMethodWithPrimitive: primitive FromContext: senderContext UpToContext: homeContext [
	"See findUnwindThroughContext:.  Alas this is mutually recursive with
	 findMethodWithPrimitive:FromFP:SP:ThroughContext: instead of iterative.
	 We're doing the simplest thing that could possibly work.  Niceties can wait."
	<inline: false>
	<returnTypeC: #sqInt> "Being mutually-recursive with findMethodWithPrimitive:FromFP:UpToContext: gives the author's type inference algorithm headaches.  Wimp out by declaring the return type."
	| theContext theMethod |
	self assert: (senderContext = objectMemory nilObject or: [objectMemory isContext: senderContext]).
	self assert: (homeContext = objectMemory nilObject or: [objectMemory isContext: homeContext]).
	theContext := senderContext.
	[theContext = objectMemory nilObject ifTrue:
		[^theContext].
	 self isMarriedOrWidowedContext: theContext] whileFalse:
		[theContext = homeContext ifTrue: [^0].
		 (primitive = 0
		  or: [(objectMemory fetchPointer: ClosureIndex ofObject: theContext) ~= objectMemory nilObject]) ifFalse:
		 	[theMethod := objectMemory fetchPointer: MethodIndex ofObject: theContext.
			 (self primitiveIndexOf: theMethod) = primitive ifTrue:
				[^theContext]].
		 theContext := objectMemory fetchPointer: SenderIndex ofObject: theContext].
	(self isWidowedContext: theContext) ifTrue:
		[^objectMemory nilObject].
	^self
		findMethodWithPrimitive: primitive
		FromFP: (self frameOfMarriedContext: theContext)
		UpToContext: homeContext
]

{ #category : #'handler search' }
StackInterpreter >> findMethodWithPrimitive: primitive FromFP: startFP UpToContext: homeContext [
	"See findUnwindThroughContext:.  Alas this is mutually recursive with
	 findMethodWithPrimitive:FromContext:ThroughContext: instead of iterative.
	 We're doing the simplest thing that could possibly work.  Niceties can wait."
	<inline: true>
	| theFP theFPAbove theSP theMethod senderContext |
	<var: #startFP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #theFPAbove type: #'char *'>
	<var: #theSP type: #'char *'>
	theFP := startFP.
	theFPAbove := startFP.
	[((self frameHasContext: theFP)
	  and: [homeContext = (self frameContext: theFP)]) ifTrue:
		[^0].
	 (primitive = 0
	  or: [self frameIsBlockActivation: theFP]) ifFalse:
	 	[theMethod := self frameMethodObject: theFP.
		 (self primitiveIndexOf: theMethod) = primitive ifTrue:
			[theFP = theFPAbove
						ifTrue: [theSP := self findSPOf: theFP on: (stackPages stackPageFor: theFP)]
						ifFalse: [theSP := self frameCallerStackPointer: theFPAbove].
			 ^self ensureFrameIsMarried: theFP SP: theSP]].
	 theFPAbove := theFP.
	 theFP := self frameCallerFP: theFP.
	 theFP ~= 0] whileTrue.
	senderContext := self frameCallerContext: theFPAbove.
	(objectMemory isContext: senderContext) ifFalse:
		[^objectMemory nilObject].
	^self
		findMethodWithPrimitive: primitive
		FromContext: senderContext
		UpToContext: homeContext
]

{ #category : #'message sending' }
StackInterpreter >> findNewMethodInClassTag: classTagArg [
	"Find the compiled method to be run when the current 
	messageSelector is sent to the given class, setting the values 
	of 'newMethod' and 'primitiveIndex'."
	| ok classTag |
	<inline: false>
	ok := self lookupInMethodCacheSel: messageSelector classTag: classTagArg.
	ok ifFalse: "entry was not found in the cache; look it up the hard way "
		[classTag := classTagArg.
		 ((objectMemory isOopForwarded: messageSelector)
		  or: [objectMemory isForwardedClassTag: classTag]) ifTrue:
			[(objectMemory isOopForwarded: messageSelector) ifTrue:
				[messageSelector := self handleForwardedSelectorFaultFor: messageSelector].
			 (objectMemory isForwardedClassTag: classTag) ifTrue:
				[classTag := self handleForwardedSendFaultForTag: classTag].
			ok := self lookupInMethodCacheSel: messageSelector classTag: classTag.
			ok ifTrue:
				[^nil]].
 		 lkupClass := objectMemory classForClassTag: classTag.
		 self lookupMethodInClass: lkupClass.
		 self addNewMethodToCache: lkupClass]
]

{ #category : #'frame access' }
StackInterpreter >> findSPOf: theFP on: thePage [
	"Search for the stack pointer for theFP.  This points to the hottest item on the frame's stack.
	 DO NOT CALL THIS WITH theFP == localFP OR theFP == framePointer!"
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<returnTypeC: #'char *'>
	| theSP |
	<inline: false>
	<var: #theSP type: #'char *'>
	self deny: (stackPages isFree: thePage).
	theSP := self findSPOrNilOf: theFP on: thePage startingFrom: thePage headFP.
	theSP ifNotNil:
		[^theSP].
	self error: 'did not find theFP in stack page'.
	^0
]

{ #category : #'frame access' }
StackInterpreter >> findSPOrNilOf: theFP on: thePage startingFrom: startFrame [
	"Search for the stack pointer for theFP.  This points to the hottest item on the frame's stack.
	 DO NOT CALL THIS WITH theFP == localFP OR theFP == framePointer!"
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #startFrame type: #'char *'>
	<returnTypeC: #'char *'>
	| aFrame prevFrame |
	<inline: true>
	<var: #aFrame type: #'char *'>
	<var: #prevFrame type: #'char *'>
	startFrame = theFP ifTrue:
		[thePage headSP >= startFrame ifTrue:
			["If the SP is invalid return the pointer to the receiver field."
			 ^self frameReceiverLocation: theFP].
		 "Skip the instruction pointer on top of stack of inactive pages."
		^thePage = stackPage
			ifTrue: [thePage headSP]
			ifFalse: [thePage headSP + objectMemory wordSize]].
	aFrame := startFrame.
	[prevFrame := aFrame.
	 aFrame := self frameCallerFP: aFrame.
	 aFrame ~= 0] whileTrue:
		[theFP = aFrame ifTrue:
			[^self frameCallerSP: prevFrame]].
	^nil
]

{ #category : #'debug support' }
StackInterpreter >> findSelectorAndClassForMethod: meth lookupClass: startClass do: binaryBlock [
	"Search startClass' class hierarchy searching for method and if found, evaluate aBinaryBlock
	 with the selector and class where the method is found.  Otherwise evaluate aBinaryBlock
	 with doesNotUnderstand: and nil."
	| currClass classDict classDictSize methodArray i |
	currClass := startClass.
	[classDict := objectMemory fetchPointer: MethodDictionaryIndex ofObject: currClass.
	 classDictSize := objectMemory numSlotsOf: classDict.
	 classDictSize > MethodArrayIndex ifTrue:
		[methodArray := objectMemory fetchPointer: MethodArrayIndex ofObject: classDict.
		 i := 0.
		 [i <= (classDictSize - SelectorStart)] whileTrue:
			[meth = (objectMemory fetchPointer: i ofObject: methodArray) ifTrue:
				[^binaryBlock
					value: (objectMemory fetchPointer: i + SelectorStart ofObject: classDict)
					value: currClass].
				i := i + 1]].
	 currClass := self superclassOf: currClass.
	 currClass = objectMemory nilObject] whileFalse.
	^binaryBlock    "method not found in superclass chain"
		value: (objectMemory splObj: SelectorDoesNotUnderstand)
		value: nil
]

{ #category : #'debug support' }
StackInterpreter >> findSelectorOfMethod: meth [
	| classObj classDict classDictSize methodArray i |
	(objectMemory addressCouldBeObj: meth) ifFalse:
		[^objectMemory nilObject].
	(objectMemory isForwarded: meth) ifTrue:
		[^self findSelectorOfMethod: (objectMemory followForwarded: meth)].
	 (objectMemory isOopCompiledMethod: meth) ifFalse:
		[^objectMemory nilObject].
	(self maybeSelectorOfMethod: meth) ifNotNil:
		[:selector| ^selector].
	classObj := self safeMethodClassOf: meth.
	(self addressCouldBeClassObj: classObj) ifTrue:
		[classDict := objectMemory fetchPointer: MethodDictionaryIndex ofObject: classObj.
		 classDictSize := objectMemory numSlotsOf: classDict.
		 classDictSize > MethodArrayIndex ifTrue:
			[methodArray := objectMemory fetchPointer: MethodArrayIndex ofObject: classDict.
			 i := 0.
			 [i < (classDictSize - SelectorStart)] whileTrue:
				[meth = (objectMemory fetchPointer: i ofObject: methodArray) ifTrue:
					[^(objectMemory fetchPointer: i + SelectorStart ofObject: classDict)].
					 i := i + 1]]].
	^objectMemory nilObject
]

{ #category : #'return bytecodes' }
StackInterpreter >> findUnwindThroughContext: homeContext [
	"Search for either an unwind-protect (activation of method with primitive 198)
	 or homeContext along the sender chain, which ever is found first.  Return values:
		0			home context was found on sender chain with no intervening unwind-protects
		nilObj		home context could not be found => cannotReturn
		context		the context of an intervening unwind-protect implies home context was found"
	| onSamePage ctxtOrNilOrZero theMethod |
	"Almost always (98%) the home is on the same page, in which case we know it will be found."
	onSamePage := (self isStillMarriedContext: homeContext)
					and: [(stackPages pageIndexFor: framePointer) = (stackPages pageIndexFor: (self frameOfMarriedContext: homeContext))].

	"Since nothing changes we don't need to internalize."
	ctxtOrNilOrZero := self findMethodWithPrimitive: 198 FromFP: framePointer UpToContext: homeContext.
	self deny: (onSamePage and: [ctxtOrNilOrZero = objectMemory nilObject]).

	ctxtOrNilOrZero = 0 ifTrue:
		[theMethod := objectMemory fetchPointer: MethodIndex ofObject: homeContext.
		 (self primitiveIndexOf: theMethod) = 198 ifTrue:
			[^homeContext].
		 ^0].

	"If an unwind was found, can the home context be found also?  No need to look if on the same page.
	 No need to look if cannot return (ctxtOrNilOrZero = objectMemory nilObject)"
	(onSamePage
	 or: [ctxtOrNilOrZero = objectMemory nilObject]) ifFalse:
		[(self findMethodWithPrimitive: 0 FromContext: ctxtOrNilOrZero UpToContext: homeContext)
		  = objectMemory nilObject ifTrue:
			[^objectMemory nilObject]].
	^ctxtOrNilOrZero
]

{ #category : #finalization }
StackInterpreter >> fireEphemeron: ephemeron [
	<option: #SpurObjectMemory>
	objectMemory
		queueMourner: ephemeron;
		setFormatOf: ephemeron to: objectMemory nonIndexablePointerFormat.
	self signalFinalization: ephemeron
]

{ #category : #finalization }
StackInterpreter >> fireFinalization: weakling [
	<option: #SpurObjectMemory>
	newFinalization ifTrue:
		[objectMemory queueMourner: weakling].
	self signalFinalization: weakling
]

{ #category : #'compiled methods' }
StackInterpreter >> firstByteIndexOfMethod: methodObj [
	"Answer the one-relative index of the first bytecode in methodObj.
	 Used for safer bounds-checking on methods."
	^(objectMemory literalCountOf: methodObj) + LiteralStart * objectMemory bytesPerOop + 1
]

{ #category : #'compiled methods' }
StackInterpreter >> firstBytecodeOfAlternateHeader: methodHeader method: theMethod [
	^theMethod
	 + ((LiteralStart + (self literalCountOfAlternateHeader: methodHeader)) * objectMemory bytesPerOop)
	 + objectMemory baseHeaderSize
]

{ #category : #'plugin primitive support' }
StackInterpreter >> floatArg: index [
	"Like #stackFloatValue: but access method arguments left-to-right"
	<returnTypeC: #double>
	<doNotGenerate> "Obsolete; was never used; replaced with methodReturnString: in the VirtualMachine struct."
	| oop |
	self deprecated.
	oop := self methodArg: index.
	oop = 0 ifTrue:[^0.0]. "methodArg: failed"
	^objectMemory floatValueOf: oop
]

{ #category : #'debug printing' }
StackInterpreter >> flush [
	<api>
	<cmacro: '() fflush(stdout)'>
]

{ #category : #'method lookup cache' }
StackInterpreter >> flushAtCache [
	"Flush the at cache. The method cache is flushed on every programming change and garbage collect."

	1 to: AtCacheTotalSize do: [ :i | atCache at: i put: 0 ]
]

{ #category : #'object memory support' }
StackInterpreter >> flushBecommedClassesInMethodCache [
	"Flush any entries in the cache which refer to a forwarded (becommed) class."
	0 to: MethodCacheSize - 1 by: MethodCacheEntrySize do:
		[:i | | c s |
		c := methodCache at: i + MethodCacheClass.
		s := methodCache at: i + MethodCacheSelector.
		(c ~= 0 and: [s ~= 0
		 and: [objectMemory isForwarded: (objectMemory classOrNilAtIndex: c)]]) ifTrue:
			[methodCache
				at: i + MethodCacheClass put: 0;
				at: i + MethodCacheSelector put: 0]].
	self flushAtCache
]

{ #category : #'object memory support' }
StackInterpreter >> flushBecommedClassesInMethodZone [
	"This is just a stub for the CoInterpreter"
]

{ #category : #'plugin primitive support' }
StackInterpreter >> flushExternalPrimitiveOf: methodObj [
	"methodObj is a CompiledMethod. If it contains an external primitive,
	 flush the function address and session ID of the CM.  Answer the prim
	 index for the benefit of subclass overrides."
	<inline: false>
	| header primIdx lit |
	header := objectMemory methodHeaderOf: methodObj.
	primIdx := self primitiveIndexOfMethod: methodObj header: header.
	(primIdx = PrimNumberExternalCall
	 and: [(objectMemory literalCountOfMethodHeader: header) > 0]) ifTrue: "If not, something's broken"
		[lit := self literal: 0 ofMethod: methodObj.
		((objectMemory isArray: lit) and: [(objectMemory numSlotsOf: lit) = 4]) ifTrue: "If not, something's broken"
			[objectMemory
				storePointerUnchecked: 2 ofObject: lit withValue: ConstZero;
				storePointerUnchecked: 3 ofObject: lit withValue: ConstZero]].
	^primIdx
]

{ #category : #'plugin primitive support' }
StackInterpreter >> flushExternalPrimitiveTable [
	"Flush the external primitive table"
	0 to: MaxExternalPrimitiveTableSize-1 do:[:i|
		externalPrimitiveTable at: i put: 0].
	externalPrimitiveTableFirstFreeIndex := 0
]

{ #category : #'plugin primitive support' }
StackInterpreter >> flushExternalPrimitives [
	"Flush the references to external functions from plugin primitives.
	 This will force a reload of those primitives when accessed next. 
	 Note: We must flush the method cache here also, so that any failed
	 primitives are looked up again."
	objectMemory allObjectsDo:
		[:oop|
		(objectMemory isCompiledMethod: oop) ifTrue: "This is a compiled method"
			[self flushExternalPrimitiveOf: oop]].
	self flushMethodCache.
	self flushExternalPrimitiveTable
]

{ #category : #'method lookup cache' }
StackInterpreter >> flushMethodCache [
	"Flush the method cache. The method cache is flushed on every programming change and garbage collect."

	1 to: MethodCacheSize do: [ :i | methodCache at: i put: 0 ].
	lastMethodCacheProbeWrite := 0. "this for primitiveExternalMethod"
	self flushAtCache
]

{ #category : #'method lookup cache' }
StackInterpreter >> flushMethodCacheForMethod: oldMethod [
	"Flush the method caches of references to oldMethod."
	| probe |
	probe := 0.
	1 to: MethodCacheEntries do:
		[:i |
		(methodCache at: probe + MethodCacheMethod) = oldMethod ifTrue:
			[methodCache at: probe + MethodCacheSelector put: 0].
		probe := probe + MethodCacheEntrySize].
	self flushExternalPrimitiveOf: oldMethod.
	self flushAtCache
]

{ #category : #'method lookup cache' }
StackInterpreter >> flushMethodCacheFrom: memStart to: memEnd [ 
	"Flush entries in the method cache only if the oop address is within the given memory range. 
	This reduces over-aggressive cache clearing. Note the AtCache is fully flushed, 70% of the time 
	cache entries live in newspace, new objects die young"
	| probe |
	probe := 0.
	1 to: MethodCacheEntries do:
		[:i | 
		(methodCache at: probe + MethodCacheSelector) = 0 ifFalse:
			[((((self oop: (methodCache at: probe + MethodCacheSelector) isGreaterThanOrEqualTo: memStart)
				 and: [self oop: (methodCache at: probe + MethodCacheSelector) isLessThan: memEnd])
			 or: [(self oop: (methodCache at: probe + MethodCacheClass) isGreaterThanOrEqualTo: memStart)
				 and: [self oop: (methodCache at: probe + MethodCacheClass) isLessThan: memEnd]])
			 or: [(self oop: (methodCache at: probe + MethodCacheMethod) isGreaterThanOrEqualTo: memStart)
				 and: [self oop: (methodCache at: probe + MethodCacheMethod) isLessThan: memEnd]]) ifTrue:
				[methodCache at: probe + MethodCacheSelector put: 0]].
			probe := probe + MethodCacheEntrySize].
	self flushAtCache
]

{ #category : #'message sending' }
StackInterpreter >> followForwardedFieldsInCurrentMethod [
	<inline: true>
	objectMemory
		followForwardedObjectFields: method
		toDepth: 0
]

{ #category : #'lazy become' }
StackInterpreter >> followForwardedFrameContents: theFP stackPointer: theSP [
	"follow pointers in the current stack frame up to theSP."
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<inline: false>
	 | oop |
	<var: #ptr type: #'char *'>
	theSP
		to: (self frameReceiverLocation: theFP)
		by: objectMemory wordSize
		do: [:ptr|
			oop := stackPages longAt: ptr.
			((objectMemory isNonImmediate: oop)
			 and: [objectMemory isForwarded: oop]) ifTrue:
				[stackPages longAt: ptr put: (objectMemory followForwarded: oop)]].
	theFP + FoxCallerSavedIP + objectMemory wordSize
		to: theFP + (self frameStackedReceiverOffset: theFP)
		by: objectMemory wordSize
		do: [:ptr|
			oop := stackPages longAt: ptr.
			((objectMemory isNonImmediate: oop)
			 and: [objectMemory isForwarded: oop]) ifTrue:
				[oop := objectMemory followForwarded: oop.
				 stackPages longAt: ptr put: oop]].
	"If we're in a block then also follow fields in the stacked closure as it may be activated again."
	(self frameIsBlockActivation: theFP) ifTrue:
		[self assert: oop = (stackPages longAt: theFP + (self frameStackedReceiverOffset: theFP)).
		 objectMemory followForwardedObjectFields: oop toDepth: 0].
	self assert: (objectMemory isForwarded: (self frameMethodObject: theFP)) not.
	(self frameHasContext: theFP) ifTrue:
		[self assert: (objectMemory isForwarded: (self frameContext: theFP)) not]
]

{ #category : #'object memory support' }
StackInterpreter >> followForwardedMethodsInMethodCache [
	0 to: MethodCacheSize - 1 by: MethodCacheEntrySize do:
		[:i | | c s m |
		c := methodCache at: i + MethodCacheClass.
		s := methodCache at: i + MethodCacheSelector.
		m := methodCache at: i + MethodCacheMethod.
		(c ~= 0 and: [s ~= 0 and: [m ~= 0
		 and: [objectMemory isOopForwarded: m]]]) ifTrue:
			[m := objectMemory followForwarded: m.
			 methodCache at: i + MethodCacheMethod put: m]]
]

{ #category : #'object memory support' }
StackInterpreter >> followForwardedMethodsInMethodZone [
	"This is just a stub for the CoInterpreter"
]

{ #category : #'object memory support' }
StackInterpreter >> followForwardingPointersInProfileState [
	(objectMemory isForwarded: profileProcess) ifTrue:
		[profileProcess := objectMemory followForwarded: profileProcess].
	(objectMemory isForwarded: profileMethod) ifTrue:
		[profileMethod := objectMemory followForwarded: profileMethod].
	(objectMemory isForwarded: profileProcess) ifTrue:
		[profileSemaphore := objectMemory followForwarded: profileSemaphore].
]

{ #category : #'object memory support' }
StackInterpreter >> followForwardingPointersInScheduler [
	| schedAssoc sched procLists |
	schedAssoc := objectMemory splObj: SchedulerAssociation.
	"the GC follows pointers in the special objects array for us."
	self assert: (objectMemory isForwarded: schedAssoc) not.

	"Make sure the active process has been followed."
	objectMemory followForwardedObjectFields: schedAssoc toDepth: 1.

	sched := objectMemory fetchPointer: ValueIndex ofObject: schedAssoc.

	procLists := objectMemory followObjField: ProcessListsIndex ofObject: sched.

	"Follow all links in the process list to ensure the lists are valid."
	0 to: (objectMemory numSlotsOf: procLists) - 1 do:
		[:i| | list first last next |
		list := objectMemory followObjField: i ofObject: procLists.
		first := objectMemory followObjField: FirstLinkIndex ofObject: list.
		last := objectMemory followObjField: LastLinkIndex ofObject: list.
		[first ~= last] whileTrue:
			[next := objectMemory followObjField: NextLinkIndex ofObject: first.
			 first := next]]

]

{ #category : #'object memory support' }
StackInterpreter >> followForwardingPointersInSpecialObjectsArray [
	"Various semaphores in the specialObjectsArray are signalled in checkForEventsMayContextSwitch:.
	 These must be followed post become to avoid a read barrier in checkForEventsMayContextSwitch:,
	 or worse still in synchronousSignal."
	| xArray |
	self followSemaphoreIn: objectMemory specialObjectsOop
		at: TheLowSpaceSemaphore.
	self followSemaphoreIn: objectMemory specialObjectsOop
		at: TheInterruptSemaphore.
	self followSemaphoreIn: objectMemory specialObjectsOop
		at: TheTimerSemaphore.
	self followSemaphoreIn: objectMemory specialObjectsOop
		at: TheFinalizationSemaphore.
	xArray := objectMemory splObj: ExternalObjectsArray.
	(objectMemory isForwarded: xArray) ifTrue:
		[xArray := objectMemory followForwarded: xArray.
		 objectMemory splObj: ExternalObjectsArray put: xArray].
	0 to: (objectMemory numSlotsOf: xArray) - 1 do:
		[:i|
		self followSemaphoreIn: xArray at: i]
]

{ #category : #'object memory support' }
StackInterpreter >> followForwardingPointersInStackZone: theBecomeEffectsFlags [
	"Spur's become: is lazy, turning the becommed object into a forwarding object to the other.
	 The read-barrier is minimised by arranging that forwarding pointers will fail a method cache
	 probe, since notionally objects' internals are accessed only via sending messages to them,
	 the exception is primitives that access the internals of the non-receiver argument(s).

	 To avoid a read barrier on bytecode, literal and inst var fetch and non-local return, we scan
	 the receivers (including the stacked receiver for non-local return) and method references
	 in the stack zone and follow any forwarded ones.  This is of course way cheaper than
	 scanning all of memory as in the old become."
	| theIPPtr |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theIPPtr type: #usqInt>
	<var: #callerFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>

	stackPage = 0 ifTrue: "the system must be snapshotting; nothing to do..."
		[self assert: stackPages mostRecentlyUsedPage isFree.
		 self cCode: [] inSmalltalk: [stackPages allPagesFree].
		 ^self].

	self externalWriteBackHeadFramePointers.

	(theBecomeEffectsFlags anyMask: BecameCompiledMethodFlag) ifTrue:
		[(objectMemory isForwarded: method) ifTrue:
			[theIPPtr := instructionPointer - method.
			 method := objectMemory followForwarded: method.
			 instructionPointer := method + theIPPtr].
		(objectMemory isOopForwarded: newMethod) ifTrue:
			[newMethod := objectMemory followForwarded: newMethod]].

	self assert: stackPage ~= 0.
	0 to: numStackPages - 1 do:
		[:i| | thePage theFP callerFP offset oop |
		thePage := stackPages stackPageAt: i.
		thePage isFree ifFalse:
			[self assert: (self ifCurrentStackPageHasValidHeadPointers: thePage).
			 theFP := thePage  headFP.
			 "Skip the instruction pointer on top of stack of inactive pages."
			 theIPPtr := thePage = stackPage ifTrue: [0] ifFalse: [thePage headSP asUnsignedInteger].
			 [self assert: (thePage addressIsInPage: theFP).
			  self assert: (theIPPtr = 0 or: [thePage addressIsInPage: theIPPtr asVoidPointer]).
			  oop := stackPages longAt: theFP + FoxReceiver.
			  (objectMemory isOopForwarded: oop) ifTrue:
				[stackPages
					longAt: theFP + FoxReceiver
					put: (objectMemory followForwarded: oop)].
			  ((self frameHasContext: theFP)
			   and: [(objectMemory isForwarded: (self frameContext: theFP))]) ifTrue:
				[stackPages
					longAt: theFP + FoxThisContext
					put: (objectMemory followForwarded: (self frameContext: theFP))].
			  oop := self frameMethod: theFP.
			  (objectMemory isForwarded: oop) ifTrue:
				[| newOop delta |
				 newOop := objectMemory followForwarded: oop.
				 theIPPtr ~= 0 ifTrue:
					[self assert: (stackPages longAt: theIPPtr) > (self frameMethod: theFP).
					 delta := newOop - oop.
					 stackPages
						longAt: theIPPtr
						put: (stackPages longAt: theIPPtr) + delta].
				stackPages
					longAt: theFP + FoxMethod
					put: (oop := newOop)].
			  offset := self frameStackedReceiverOffset: theFP.
			  oop := stackPages longAt: theFP + offset.
			  (objectMemory isOopForwarded: oop) ifTrue:
				[stackPages
					longAt: theFP + offset
					put: (objectMemory followForwarded: oop)].
			  (callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
				[theIPPtr := (theFP + FoxCallerSavedIP) asUnsignedInteger.
				 theFP := callerFP].
			 "And finally follow the caller context."
			 self assert: theFP = thePage baseFP.
			 oop := self frameCallerContext: theFP.
			 (objectMemory isForwarded: oop) ifTrue:
				[self frameCallerContext: theFP put: (objectMemory followForwarded: oop)]]]
]

{ #category : #'compiled methods' }
StackInterpreter >> followLiteral: offset ofMethod: methodPointer [
	^objectMemory followField: offset + LiteralStart ofObject: methodPointer

]

{ #category : #'object memory support' }
StackInterpreter >> followSemaphoreIn: anArray at: index [
	"Only follow the reference to the semaphore.  synchronousSignal
	 checks the chain to the suspendedContext."
	 
	| obj |
	obj := objectMemory fetchPointer: index ofObject: anArray.
	(objectMemory isForwarded: obj) ifTrue:
		[obj := objectMemory followForwarded: obj.
		 objectMemory storePointer: index ofObject: anArray withValue: obj]
]

{ #category : #'process primitive support' }
StackInterpreter >> forceInterruptCheck [
	"Force an interrupt check ASAP.
	 Must set the stack page's limit before stackLimit to avoid
	 a race condition if this is called from an interrupt handler."
	| thePage iccFunc |
	<inline: false>
	<var: #thePage type: #'StackPage *'>
	<var: #iccFunc declareC: 'void (*iccFunc)()'>
	"Do _not_ set stackLimit until the stack system has been initialized.
	 stackLimit is the initialization flag for the stack system."
	stackLimit = 0 ifTrue:
		[^nil].
	thePage := stackPage.
	(thePage notNil and: [thePage ~= 0]) ifTrue:
		[thePage stackLimit: self allOnesAsCharStar].
	stackLimit := self allOnesAsCharStar.
	self sqLowLevelMFence.
	"There is a race condition if we test the function and then dereference
	 it a second time to call it.  This is called from interrupt code but at the
	 same time other code could be clearing the interruptCheckChain via
	 setInterruptCheckChain:."
	(iccFunc := interruptCheckChain) notNil ifTrue:
		[self perform: iccFunc].
	statForceInterruptCheck := statForceInterruptCheck + 1
]

{ #category : #'process primitive support' }
StackInterpreter >> forceInterruptCheckFromHeartbeat [
	"Force an interrupt check ASAP. This version is the
	 entry-point to forceInterruptCheck for the heartbeat
	 timer to allow for repeatable debugging."
	suppressHeartbeatFlag ifFalse:
		[self checkForLongRunningPrimitive.
		 self forceInterruptCheck]
]

{ #category : #'frame access' }
StackInterpreter >> frameCallerContext: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxCallerContext "a.k.a. FoxCallerSavedIP"
]

{ #category : #'frame access' }
StackInterpreter >> frameCallerContext: theFP put: aValue [
	<var: #theFP type: #'char *'>
	<inline: true>
	self assert: (aValue = objectMemory nilObject or: [objectMemory isContext: aValue]).
	^stackPages
		longAt: theFP + FoxCallerContext "a.k.a. FoxCallerSavedIP"
		put: aValue
]

{ #category : #'frame access' }
StackInterpreter >> frameCallerFP: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	<returnTypeC: 'char *'>
	^self pointerForOop: (stackPages longAt: theFP + FoxSavedFP)
]

{ #category : #'frame access' }
StackInterpreter >> frameCallerSP: theFP [
	"Answer the SP of the caller provided theFP is not a base frame.
	 This points to the hottest item on the caller frame's stack."
	<var: #theFP type: #'char *'>
	<returnTypeC: 'char *'>
	self assert: (self isBaseFrame: theFP) not.
	^theFP + (self frameStackedReceiverOffset: theFP) + objectMemory wordSize
]

{ #category : #'frame access' }
StackInterpreter >> frameCallerSavedIP: theFP [
	<inline: true>
	<returnTypeC: #'char *'>
	<var: #theFP type: #'char *'>
	^self pointerForOop: (stackPages longAt: theFP + FoxCallerSavedIP) "a.k.a. FoxCallerSavedIP"
]

{ #category : #'frame access' }
StackInterpreter >> frameCallerStackPointer: theFP [
	"Answer the stack pointer of the caller frame."
	<var: #theFP type: #'char *'>
	<returnTypeC: #'char *'>
	<inline: true>
	self assert: (self isBaseFrame: theFP) not.
	^theFP + (self frameStackedReceiverOffset: theFP) + objectMemory wordSize
]

{ #category : #'frame access' }
StackInterpreter >> frameContext: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxThisContext
]

{ #category : #'frame access' }
StackInterpreter >> frameHasContext: theFP [
	"See encodeFrameFieldHasContext:numArgs:"
	<inline: true>
	<var: #theFP type: #'char *'>
	^(stackPages byteAt: theFP + FoxFrameFlags + 2) ~= 0
]

{ #category : #'frame access' }
StackInterpreter >> frameHasNativeFrame: theFP [
	"See encodeFrameFieldHasContext:numArgs:"
	<inline: true>
	<option: #LowcodeVM>
	<var: #theFP type: #'char *'>
	| markObject |
	markObject := self temporary: (self frameNumArgs: theFP) in: theFP.
	
	^ markObject ~= objectMemory nilObject and: [ markObject = (objectMemory splObj: LowcodeContextMark)]
]

{ #category : #'frame access' }
StackInterpreter >> frameIsBlockActivation: theFP [ "<Integer>"
	<inline: true>
	<var: #theFP type: #'char *'>
	^(stackPages byteAt: theFP + FoxFrameFlags + 3) ~= 0
]

{ #category : #'frame access' }
StackInterpreter >> frameLastArgumentOffset [
	"Answer the offset in bytes from the frame pointer to the last argument,
	 which is simply the address of the word above the saved ip.  See the
	 diagram in StackInterpreter class>>initializeFrameIndices."
	<inline: true>
	^FoxCallerSavedIP + objectMemory wordSize
]

{ #category : #'frame access' }
StackInterpreter >> frameMethod: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxMethod
]

{ #category : #'frame access' }
StackInterpreter >> frameMethodObject: theFP [
	"Homonym of frameMethod: for compatibility with CoInterpreter"
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxMethod
]

{ #category : #'frame access' }
StackInterpreter >> frameNumArgs: theFP [
	"See encodeFrameFieldHasContext:numArgs:"
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages byteAt: theFP + FoxFrameFlags + 1
]

{ #category : #'frame access' }
StackInterpreter >> frameOfMarriedContext: aContext [ 
	| senderOop |
	<inline: true>
	<returnTypeC: 'char *'>
	senderOop := objectMemory fetchPointer: SenderIndex ofObject: aContext.
	^self withoutSmallIntegerTags: senderOop
]

{ #category : #'cog jit support' }
StackInterpreter >> framePointer: theFP [
	"Simulation only"
	<doNotGenerate>
	framePointer := theFP
]

{ #category : #'internal interpreter access' }
StackInterpreter >> framePointerOfNativeArgument: offset in: theFP [
	<inline: false>
	<option: #LowcodeVM>
	<returnTypeC: 'char*'>
	<var: #theFP type: #'char*'>
	^ (self nativePreviousStackPointerIn: theFP) + offset - 1
]

{ #category : #'internal interpreter access' }
StackInterpreter >> framePointerOfNativeLocal: offset in: theFP [
	<inline: false>
	<option: #LowcodeVM>
	<returnTypeC: 'char*'>
	<var: #theFP type: #'char*'>
	^ (self nativeFramePointerIn: theFP) + offset - 1
]

{ #category : #'frame access' }
StackInterpreter >> frameReceiver: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxReceiver
]

{ #category : #'frame access' }
StackInterpreter >> frameReceiverLocation: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^theFP + FoxReceiver
]

{ #category : #'frame access' }
StackInterpreter >> frameStackedReceiver: theFP numArgs: numArgs [
	"Answer the stacked receiver given the frame's argument count.
	 The receiver of a message send or the closure of a block activation is
	 always on the stack above any arguments and the frame itself.  See the
	 diagram in StackInterpreter class>>initializeFrameIndices."
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + (self frameStackedReceiverOffsetNumArgs: numArgs)
]

{ #category : #'frame access' }
StackInterpreter >> frameStackedReceiverOffset: theFP [
	"Answer the offset in bytes from the the frame pointer to its stacked receiver.
	 The receiver of a message send or the closure of a block activation is
	 always on the stack above any arguments and the frame itself.  See the
	 diagram in StackInterpreter class>>initializeFrameIndices."
	<inline: true>
	<var: #theFP type: #'char *'>
	^self frameStackedReceiverOffsetNumArgs: (self frameNumArgs: theFP)
]

{ #category : #'frame access' }
StackInterpreter >> frameStackedReceiverOffsetNumArgs: numArgs [
	"Answer the offset in bytes from the a frame pointer to its stacked receiver,
	 given the argument count.  The receiver of a message send or the closure of
	 a block activation is always on the stack above any arguments and the frame
	 itself.  See the diagram in StackInterpreter class>>initializeFrameIndices."
	<inline: true>
	^FoxCallerSavedIP + objectMemory wordSize + (numArgs << objectMemory shiftForWord)
]

{ #category : #'object memory support' }
StackInterpreter >> freeUnmarkedMachineCode [
	"This is a no-op in the StackInterpreter"
]

{ #category : #'object memory support' }
StackInterpreter >> freeUntracedStackPages [
	"Free any untraced stack pages."
	<var: #thePage type: #'StackPage *'>
	<inline: false>

	0 to: numStackPages - 1 do:
		[:i| | thePage |
		thePage := stackPages stackPageAt: i.
		((stackPages isFree: thePage) not
		 and: [thePage trace = StackPageUnreached]) ifTrue:
			[self assert: (self noMarkedContextsOnPage: thePage).
			 stackPages freeStackPage: thePage].
		self assert: (thePage trace: StackPageTraceInvalid) ~= 0] "Invalidate the trace state for assertion checks"
]

{ #category : #'control primitives' }
StackInterpreter >> fullClosureIn: context numArgs: numArgs numCopiedValues: numCopied compiledBlock: compiledBlock [ 
	| newClosure |
	<inline: true>
	ClassFullBlockClosureCompactIndex ~= 0
		ifTrue:
			[newClosure := objectMemory
								eeInstantiateSmallClassIndex: ClassFullBlockClosureCompactIndex
								format: objectMemory indexablePointersFormat
								numSlots: FullClosureFirstCopiedValueIndex + numCopied]
		ifFalse:
			[newClosure := objectMemory
								eeInstantiateSmallClass: (objectMemory splObj: ClassFullBlockClosure)
								numSlots: FullClosureFirstCopiedValueIndex + numCopied].
	"Assume: have just allocated a new closure; it must be young. Thus, can use unchecked stores."
	objectMemory
		storePointerUnchecked: ClosureOuterContextIndex ofObject: newClosure withValue: context;
		storePointerUnchecked: FullClosureCompiledBlockIndex ofObject: newClosure withValue: compiledBlock;
		storePointerUnchecked: ClosureNumArgsIndex ofObject: newClosure withValue: (objectMemory integerObjectOf: numArgs).
	^newClosure
]

{ #category : #'I/O primitive support' }
StackInterpreter >> fullDisplayUpdate [
	"Repaint the entire smalltalk screen, ignoring the affected rectangle. Used in some platform's code when the Smalltalk window is brought to the front or uncovered."
	<returnTypeC: #sqInt>
	self updateDisplayLeft: 0 Top: 0 Right: displayWidth Bottom: displayHeight.
	self ioForceDisplayUpdate
]

{ #category : #'plugin primitive support' }
StackInterpreter >> functionForPrimitiveCallout [
	"Answer the function primitiveCallout from the FFI plugin or nil if it can't
	 be found.  Cache it for performance.  We use this circumlocution so that
	 Squeak can be deployed without the FFI plugin for security reasons."

	<returnTypeC: 'void (*functionForPrimitiveCallout())(void)'>
	| function |
	<var: #function declareC: 'static void *function = (void *)-1'>
	self cCode: '' inSmalltalk: [function := -1].
	function asInteger = -1 ifTrue:
		[function := self ioLoadFunction: 'primitiveCallout' From: 'SqueakFFIPrims'].
	^self cCoerceSimple: function to: #'void (*)(void)'
]

{ #category : #'method lookup cache' }
StackInterpreter >> functionPointerFor: primIdx inClass: theClass [
	"Find an actual function pointer for this primitiveIndex.  This is an
	opportunity to specialise the prim for the relevant class (format for
	example).  Default for now is simply the entry in the base primitiveTable."
	<api>
	<returnTypeC: 'void (*functionPointerForinClass(sqInt primIdx,sqInt theClass))(void)'>
	^primIdx > MaxPrimitiveIndex ifTrue: [0] ifFalse: [primitiveTable at: primIdx]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getCodeCompactionCount [
	"This is nil in the StackVM"
	^objectMemory nilObject
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getCodeCompactionMSecs [
	"This is nil in the StackVM"
	^objectMemory nilObject
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getCogCodeSize [
	"This is nil in the StackVM"
	^objectMemory nilObject
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getCogMethodCount [
	"This is 0 in the StackVM"
	^ConstZero
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getCogVMFeatureFlags [
	"Answer an array of flags indicating various optional features of the Cog VM.
	 Bit 0: supports two bytecode sets (MULTIPLEBYTECODESETS)
	 Bit 1: supports immutablity (IMMUTABILITY)
	 Bit 2: suffers from a UNIX setitimer signal-based heartbeat"
	^objectMemory integerObjectOf: (MULTIPLEBYTECODESETS ifTrue: [1] ifFalse: [0])
									+ (IMMUTABILITY ifTrue: [2] ifFalse: [0])
									+ (self cppIf: #'ITIMER_HEARTBEAT' ifTrue: [4] ifFalse: [0])
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getCogVMFlags [
	"Answer an array of flags indicating various properties of the Cog VM.
	 These are the same as the image header flags shifted right two bits (excluding float order and full screen flags).
	 Bit 0: specific to CoInterpreterMT
	 Bit 1: specific to CoInterpreter
	 Bit 2: if set, implies preempting a process does not put it to the back of its run queue
	 Bit 3: specific to CoInterpreterMT
	 Bit 4: if set, implies the new finalization scheme where WeakArrays are queued
	 Bit 5: if set, implies wheel events will be delivered as such and not mapped to arrow key events"
	^objectMemory integerObjectOf: (preemptionYields ifTrue: [0] ifFalse: [4])
									+ (newFinalization ifTrue: [16] ifFalse: [0])
									+ (sendWheelEvents ifTrue: [32] ifFalse: [0])
									+ (imageHeaderFlags >> 2 bitClear: 4 + 16 + 32)
]

{ #category : #'interpreter shell' }
StackInterpreter >> getCurrentBytecode [
	"currentBytecode will be private to the main dispatch loop in the generated code. This method allows the currentBytecode to be retrieved from global variables."

	^objectMemory byteAt: instructionPointer
]

{ #category : #'simulation support' }
StackInterpreter >> getDeferDisplayUpdates [
	<doNotGenerate>
	^deferDisplayUpdates
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getDesiredCogCodeSize [
	"This is nil in the StackVM"
	^objectMemory nilObject
]

{ #category : #'message sending' }
StackInterpreter >> getErrorObjectFromPrimFailCode [
	"Answer the errorCode object to supply to a failing primitive method that accepts one.
	 If there is a primitive error table and the primFailCode is a valid index there-in answer
	 the corresponding entry in the table, otherwise simply answer the code as an integer."
	| table errObj numSlots |
	primFailCode > 0 ifTrue:
		[table := objectMemory splObj: PrimErrTableIndex.
		 primFailCode <= (objectMemory numSlotsOf: table) ifTrue:
			[errObj := objectMemory followField: primFailCode - 1 ofObject: table.
			 "If this is a PrimErrOSError/PrimErrFFIException and there's a clonable object in the table at that index,
			 answer a clone of the error object with the second slot set to the value of osErrorCode."
			 ((primFailCode = PrimErrOSError or: [primFailCode = PrimErrFFIException])
			  and: [(objectMemory formatOf: errObj) = objectMemory nonIndexablePointerFormat
			  and: [(numSlots := objectMemory numSlotsOf: errObj) >= 2]]) ifTrue:
				[errObj := self cloneOSErrorObj: errObj numSlots: numSlots].
			 ^errObj]].
	^objectMemory integerObjectOf: primFailCode
]

{ #category : #'process primitive support' }
StackInterpreter >> getExternalSemaphoreWithIndex: index [
	<api>
	| xArray sema |
	xArray := objectMemory splObj: ExternalObjectsArray.
	self assert: (objectMemory isArray: xArray).
	sema := objectMemory fetchPointer: index - 1 ofObject: xArray. "Note: semaphore indices are 1-based"
	self assert: (objectMemory isOopForwarded: sema) not.
	self assert: (objectMemory isSemaphoreOop: sema).
	
	^ sema
]

{ #category : #'plugin primitive support' }
StackInterpreter >> getFullScreenFlag [
	^fullScreenFlag
]

{ #category : #'object memory support' }
StackInterpreter >> getGCMode [
	"This is a no-op in the StackVM"
	^0
]

{ #category : #'image save/restore' }
StackInterpreter >> getImageHeaderFlags [
	"Answer the flags that are contained in the 7th long of the image header."
	^fullScreenFlag "0 or 1"
	+ (VMBIGENDIAN ifTrue: [0] ifFalse: [2]) "this is the imageFloatsLittleEndian flag"
	+ (preemptionYields ifTrue: [0] ifFalse: [16r10])
	+ (newFinalization ifTrue: [16r40] ifFalse: [0])
	+ (sendWheelEvents ifTrue: [16r80] ifFalse: [0])
	+ (imageHeaderFlags bitClear: 16rD3) "these are any flags we do not recognize"
]

{ #category : #'plugin primitive support' }
StackInterpreter >> getInterruptKeycode [
	^interruptKeycode
]

{ #category : #'plugin primitive support' }
StackInterpreter >> getInterruptPending [
	^interruptPending
]

{ #category : #'image save/restore' }
StackInterpreter >> getLongFromFile: aFile swap: swapFlag [
	"Answer the next 32 or 64 bit word read from aFile, byte-swapped according to the swapFlag."
	<var: #aFile type: #sqImageFile>
	| w |
	w := 0.
	self cCode: [self
					sq: (self addressOf: w)
					Image: (self sizeof: w)
					File: 1
					Read: aFile]
		inSmalltalk: [w := objectMemory nextLongFrom: aFile].
	^swapFlag
		ifTrue: [objectMemory byteSwapped: w]
		ifFalse: [w]
]

{ #category : #'plugin primitive support' }
StackInterpreter >> getNextWakeupUsecs [
	<api>
	<returnTypeC: #usqLong>
	^nextWakeupUsecs
]

{ #category : #'plugin primitive support' }
StackInterpreter >> getSavedWindowSize [
	^savedWindowSize
]

{ #category : #'image save/restore' }
StackInterpreter >> getShortFromFile: aFile swap: swapFlag [
	"Answer the next 16 bit word read from aFile, byte-swapped according to the swapFlag."

	<var: #aFile type: #sqImageFile>
	| w |
	<var: #w type: #'unsigned short'>
	w := 0.
	self cCode: [self
					sq: (self addressOf: w)
					Image: (self sizeof: #'unsigned short')
					File: 1
					Read: aFile]
		inSmalltalk: [w := objectMemory nextShortFrom: aFile].
	^swapFlag
		ifTrue: [((w >> 8) bitAnd: 16rFF) bitOr: ((w bitAnd: 16rFF) << 8)]
		ifFalse: [w]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> getSnapshotScreenSize [
	"Answer the screen size to write to the snapshot.
	 If the actual screen size is zero then write the savedWindowSize instead."
	| screenSize |
	screenSize := self ioScreenSize.
	((screenSize bitAnd: 16rFFFF) = 0
	 or: [screenSize >> 16 = 0]) ifTrue:
		[screenSize := savedWindowSize].
	^screenSize
]

{ #category : #'primitive support' }
StackInterpreter >> getStackPointer [
	"For Alien FFI"
	<api>
	<returnTypeC: #'sqInt *'>
	^self cCoerceSimple: stackPointer to: #'sqInt *'
]

{ #category : #'plugin support' }
StackInterpreter >> getThisSessionID [
	"return the global session ID value"
	<inline: false>
	^globalSessionID
]

{ #category : #'image save/restore' }
StackInterpreter >> getWord32FromFile: aFile swap: swapFlag [
	"Answer the next 32 bit word read from aFile, byte-swapped according to the swapFlag."

	<var: #aFile type: #sqImageFile>
	| w |
	<var: #w type: #int>
	w := 0.
	self cCode: [self
					sq: (self addressOf: w)
					Image: (self sizeof: #int)
					File: 1
					Read: aFile]
		inSmalltalk: [w := objectMemory nextWord32From: aFile].
	^swapFlag
		ifTrue: [w byteSwap32]
		ifFalse: [w]
]

{ #category : #'message sending' }
StackInterpreter >> handleForwardedSelectorFaultFor: selectorOop [
	"Handle a send fault that is due to a send using a forwarded selector.
	 Unforward the selector and follow the current method and special
	 selectors array to unforward the source of the forwarded selector."
	<option: #SpurObjectMemory>
	<inline: false>
	self assert: (objectMemory isOopForwarded: selectorOop).
	self followForwardedFieldsInCurrentMethod.
	objectMemory
		followForwardedObjectFields: (objectMemory splObj: SpecialSelectors)
		toDepth: 0.
	^objectMemory followForwarded: selectorOop
]

{ #category : #'message sending' }
StackInterpreter >> handleForwardedSendFaultForTag: classTag [
	"Handle a send fault that may be due to a send to a forwarded object.
	 Unforward the receiver on the stack and answer its actual class."
	<option: #SpurObjectMemory>
	| rcvr |
	<inline: false>
	self assert: (objectMemory isForwardedClassTag: classTag).

	rcvr := self stackValue: argumentCount.
	"should *not* be a super send, so the receiver should be forwarded."
	self assert: (objectMemory isOopForwarded: rcvr).
	rcvr := objectMemory followForwarded: rcvr.
	self stackValue: argumentCount put: rcvr.
	self followForwardedFrameContents: framePointer
		stackPointer: stackPointer + (argumentCount + 1 * objectMemory wordSize). "don't repeat effort"
	(objectMemory isPointers: (self frameReceiver: framePointer)) ifTrue:
		[objectMemory
			followForwardedObjectFields: (self frameReceiver: framePointer)
			toDepth: 0].
	^objectMemory fetchClassTagOf: rcvr
]

{ #category : #'message sending' }
StackInterpreter >> handleSpecialSelectorSendFaultFor: obj [
	<inline: true>
	<option: #SpurObjectMemory>
	^self handleSpecialSelectorSendFaultFor: obj fp: localFP sp: localSP
]

{ #category : #'message sending' }
StackInterpreter >> handleSpecialSelectorSendFaultFor: obj fp: theFP sp: theSP [
	"Handle a special send fault that may be due to a special selector
	 send accessing a forwarded object.  obj is forwarded.
	 Unforward stack contents and and inst vars and answer obj's target."
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	| rcvr |
	self assert: (objectMemory isOopForwarded: obj).
	self followForwardedFrameContents: theFP stackPointer: theSP.
	rcvr := self frameReceiver: theFP.
	(objectMemory isPointers: rcvr) ifTrue:
		[objectMemory
			followForwardedObjectFields: rcvr
			toDepth: 0].
	^objectMemory followForwarded: obj
]

{ #category : #'message sending' }
StackInterpreter >> handleStackOverflow [
	"Check for stack overflow, moving frames to another stack if so.
	 This should *only* be sent from checkForStackOverflow."
	<inline: #never>
	| newPage theFP callerFP overflowLimitAddress overflowCount |
	<var: #newPage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #overflowLimitAddress type: #'char *'>

	self assert: stackPointer < stackPage realStackLimit.

	self maybeTraceStackOverflow.
	statStackOverflow := statStackOverflow + 1.

	"The stack has overflowed this page.  If the system is executing some recursive algorithm,
	 e.g. fibonacci, then the system could thrash overflowing the stack if the call soon returns
	 back to the current page.  To avoid thrashing, since overflow is quite slow, we can move
	 more than one frame.  The idea is to record which page has overflowed, and the first
	 time it overflows move one frame, the second time two frames, and so on.  We move no
	 more frames than would leave the page half occupied."
	theFP := framePointer.
	stackPage = overflowedPage
		ifTrue:
			[overflowLimitAddress := stackPage baseAddress - stackPages overflowLimit.
			 overflowCount := extraFramesToMoveOnOverflow := extraFramesToMoveOnOverflow + 1.
			 [(overflowCount := overflowCount - 1) >= 0
			   and: [(callerFP := self frameCallerFP: theFP) < overflowLimitAddress
			   and: [(self isBaseFrame: callerFP) not]]] whileTrue:
				[theFP := callerFP]]
		ifFalse:
			[overflowedPage := stackPage.
			 extraFramesToMoveOnOverflow := 0].

	self ensureCallerContext: theFP.
	newPage := stackPages newStackPage.
	self moveFramesIn: stackPage through: theFP toPage: newPage.
	self setStackPageAndLimit: newPage.
	self setStackPointersFromPage: newPage.
	self isCog
		ifFalse: "To overflow the stack this must be a new frame, but in Cog base frames are married."
			[self assert: (self frameHasContext: framePointer) not.
			 self assert: (self validInstructionPointer: instructionPointer + 1
							inMethod: method
							framePointer: framePointer)]
		ifTrue:
			[self assert: (self validInstructionPointer: instructionPointer + 1
							inFrame: framePointer).
			 self assert: ((self frameHasContext: framePointer) not
						or: [objectMemory isContext: (self frameContext: framePointer)])]
]

{ #category : #'message sending' }
StackInterpreter >> handleStackOverflowOrEventAllowContextSwitch: mayContextSwitch [
	"The stackPointer is below the stackLimit.  This is either because of a
	 stack overflow or the setting of stackLimit to indicate a possible interrupt.
	 Check for stackOverflow and  interrupts anddeal with each appropriately.
	 Answer if a context switch occurred."
	<inline: false>
	self checkForStackOverflow.
	"If the stackLimit differs from the realStackLimit then the stackLimit
	 has been set to indicate an event or interrupt that needs servicing."
	stackLimit = stackPage realStackLimit ifTrue:
		[^false].
	^self checkForEventsMayContextSwitch: mayContextSwitch
]

{ #category : #'stack pages' }
StackInterpreter >> highBit: anUnsignedValue [ 
	"This is a C implementation needed by ioSetMaxExtSemTableSize
	 and e.g. stackPageByteSize."
	| shifted bitNo |
	<api>
	<highBit> "so it shows up in senders..."
	<var: #anUnsignedValue type: #usqInt>
	<var: #shifted type: #usqInt>
	shifted := anUnsignedValue.
	bitNo := 0.
	self cppIf: objectMemory wordSize > 4
		ifTrue:
			[shifted < (1 << 32) ifFalse:
				[shifted := shifted >> 32.
				 bitNo := bitNo + 32]].
	shifted < (1 << 16) ifFalse:
		[shifted := shifted >> 16.
		 bitNo := bitNo + 16].
	shifted < (1 << 8) ifFalse:
		[shifted := shifted >> 8.
		 bitNo := bitNo + 8].
	shifted < (1 << 4) ifFalse:
		[shifted := shifted >> 4.
		 bitNo := bitNo + 4].
	shifted < (1 << 2) ifFalse:
		[shifted := shifted >> 2.
		 bitNo := bitNo + 2].
	shifted < (1 << 1) ifFalse:
		[shifted := shifted >> 1.
		 bitNo := bitNo + 1].
	"shifted 0 or 1 now"
	^bitNo + shifted
]

{ #category : #'process primitive support' }
StackInterpreter >> highestPriorityProcess [
	"Answer the highest priority process that is ready to run, but
	 unlike wakeHighestPriority do not remove it from the list.
	 To save time looking at many empty lists before finding a
	 runnable process the VM maintains a variable holding the
	 highest priority runnable process.  If this variable is 0 then the
	 VM does not know the highest priority and must search all lists.
	 Note: It is a fatal VM error if there is no runnable process."
	| schedLists p processList processOrNil |
	<inline: false>
	schedLists := objectMemory fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	p := highestRunnableProcessPriority = 0
			ifTrue: [objectMemory numSlotsOf: schedLists]
			ifFalse: [highestRunnableProcessPriority].
	p := p - 1.
	"index of last indexable field"
	[processList := objectMemory fetchPointer: p ofObject: schedLists.
	 processOrNil := objectMemory fetchPointer: FirstLinkIndex ofObject: processList.
	 processOrNil = objectMemory nilObject] whileTrue:
		[(p := p - 1) < 0 ifTrue:
			[^nil]].
	highestRunnableProcessPriority := p + 1.
	^processOrNil
]

{ #category : #'message sending' }
StackInterpreter >> ifAppropriateCompileToNativeCode: aMethodObj selector: selector [
	"Convenient  noop in the StackInterpreter e.g. for sendInvokeCallbackContext:"
]

{ #category : #'jump bytecodes' }
StackInterpreter >> ifBackwardsCheckForEvents: offset [
	"Backward jump means we're in a loop; check for possible interrupts."
	<inline: true>
	(offset < 0
	 and: [localSP < stackLimit]) ifTrue:
		[self externalizeIPandSP.
		 self checkForEventsMayContextSwitch: true.
		 self browserPluginReturnIfNeeded.
		 self internalizeIPandSP]
]

{ #category : #'stack pages' }
StackInterpreter >> ifCurrentStackPageHasValidHeadPointers: thePage [
	"If thePage is the stackPage and the stackPointer and/or the framePointer are pointing within it,
	 answer if thePage's heapSP and headFP are equal to the stackPointer and framePointer respectively."
	<var: #thePage type: #'StackPage *'>
	thePage = stackPage ifTrue:
		[(thePage addressIsInPage: framePointer) ifTrue:
			[thePage headFP ~= framePointer ifTrue:
				[^false]].
		(thePage addressIsInPage: stackPointer) ifTrue:
			[thePage headSP ~= stackPointer ifTrue:
				[^false]]].
	^true
]

{ #category : #'frame access' }
StackInterpreter >> ifSoAssertValidIPAssign: index ofContext: maybeMarriedContext with: anOop [
	self assert: (index ~= InstructionPointerIndex
				or: [(objectMemory isContextNonImm: maybeMarriedContext) not
				or: [| mo |
					mo := self fetchPointer: MethodIndex ofObject: maybeMarriedContext.
					(anOop = objectMemory nilObject
					 or: [(objectMemory isIntegerObject: anOop)
						  and: [(objectMemory integerValueOf: anOop)
								between: (LiteralStart + (objectMemory literalCountOf: mo)) * objectMemory bytesPerOop
								and: (objectMemory numBytesOf: mo)]])]])
]

{ #category : #'debug support' }
StackInterpreter >> ifValidWriteBackStack: theCFP Pointers: theCSP Save: savedFPP To: savedSPP [
	"This is for low-level error reporting.  If either of the C stack pointers are
	 pointing into the stack zone then write them back to framePointer and/or
	 stackPointer so that the stack backtrace will be up to date.  Write their
	 original values through savedFPP & savedSPP if non-null.
	 This is a noop in the stack VM since the C stack pointers are always
	 elsewhere (e.g., in some C function running the interpreter)."
	<api>
	<var: #theCFP type: #'void *'>
	<var: #theCSP type: #'void *'>
	<var: #savedFPP type: #'char **'>
	<var: #savedSPP type: #'char **'>
	<returnTypeC: #void>
]

{ #category : #'frame access' }
StackInterpreter >> iframeInstructionPointerForIndex: ip method: aMethod [
	"Answer the instruction pointer for use in an interpreter frame (a pointer to a bytecode)."
	self assert: (ip between: (((LiteralStart + (objectMemory literalCountOf: aMethod)) * objectMemory bytesPerOop)) + 1
					and: (objectMemory lengthOf: aMethod)).
	^aMethod + ip + objectMemory baseHeaderSize - 2
]

{ #category : #'frame access' }
StackInterpreter >> iframeIsBlockActivation: theFP [ "<Integer>"
	^self frameIsBlockActivation: theFP
]

{ #category : #'frame access' }
StackInterpreter >> iframeMethod: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	<returnTypeC: #usqInt>
	^stackPages longAt: theFP + FoxMethod
]

{ #category : #'image save/restore' }
StackInterpreter >> imageFormatCompatibilityVersion [
	"This VM is backward-compatible with the immediately preceding version."

	^objectMemory wordSize = 4 ifTrue: [6504] ifFalse: [68002]
]

{ #category : #'image save/restore' }
StackInterpreter >> imageFormatVersion [
	"Return a magic constant that changes when the image format changes.
	 Since the image reading code uses this to detect byte ordering, one
	 must avoid version numbers that are invariant under byte reversal."
	<doNotGenerate>
	self assert: (objectMemory imageFormatVersion anyMask: 16) = objectMemory hasSpurMemoryManagerAPI.
	^objectMemory imageFormatVersion
]

{ #category : #'plugin primitive support' }
StackInterpreter >> includesBehavior: aClass ThatOf: aSuperclass [
	"Return the equivalent of 
		aClass includesBehavior: aSuperclass.
	Note: written for efficiency and better inlining (only 1 temp)"
	| theClass |
	<inline: true>
	aSuperclass = objectMemory nilObject ifTrue:
		[^false].
	theClass := aClass.
	[theClass = aSuperclass ifTrue:
		[^true].
	 theClass ~= objectMemory nilObject] whileTrue:
		[theClass := self superclassOf: theClass].
	^false
]

{ #category : #'simulation support' }
StackInterpreter >> initExtensions [
	<inline: true>
	BytecodeSetHasExtensions ifTrue: [extA := numExtB := extB := 0]
]

{ #category : #'object memory support' }
StackInterpreter >> initStackPageGC [
	"GC of pages.  Throwing away all stack pages on full GC is simple but dangerous
	 because it causes us to allocate lots of contexts immediately before a GC.
	 Reclaiming pages whose top context is not referenced is poor because it would
	 take N incrementalGCs to reclaim N unused pages.  Only the page whose top
	 context is not referred to by the bottom context of any other page would be
	 reclaimed.  Not until the next GC would the page whose top contect is the
	 previously reclaimed page's base frame's bottom context be reclaimed.

	 Better is to not mark stack pages until their contexts are encountered.  We can
	 eagerly trace the active page and the page reachable from its bottom context
	 if any, and so on.  Other pages can be marked when we encounter a married
	 context."
	<var: #thePage type: #'StackPage *'>
	<inline: true>
	"Need to write back the frame pointers unless all pages are free (as in snapshot)"
	stackPage ~= 0 ifTrue:
		[self externalWriteBackHeadFramePointers].

	0 to: numStackPages - 1 do:
		[:i| | thePage |
		thePage := stackPages stackPageAt: i.
		thePage trace: StackPageUnreached]
]

{ #category : #initialization }
StackInterpreter >> initStackPages [
	"Initialize the stackPages.  This version is only for simulation
	 because Slang refuses to inline it, which makes the alloca invalid."
	| stackPageBytes stackPagesBytes theStackMemory |
	stackPageBytes := self stackPageByteSize.
	stackPagesBytes := self computeStackZoneSize.
	theStackMemory := self
							cCode: [self alloca: stackPagesBytes]
							inSmalltalk: [stackPages initializeWithByteSize: stackPagesBytes for: self].
	self cCode: [self me: theStackMemory ms: 0 et: stackPagesBytes].
	stackPages
		initializeStack: theStackMemory
		numSlots: stackPagesBytes / objectMemory wordSize
		pageSize: stackPageBytes / objectMemory wordSize
]

{ #category : #initialization }
StackInterpreter >> initStackPagesAndInterpret [
	"Initialize the stack pages and enter interpret. Use alloca'ed memory so that when
	 we have a JIT its stack pointer will be on the native stack since alloca allocates
	 memory on the stack. Certain thread systems use the native stack pointer as the
	 frame ID so putting the stack anywhere else can confuse the thread system."

	"This should be in its own initStackPages method but Slang can't inline
	 C code strings."
	| stackPageBytes stackPagesBytes theStackMemory |
	<var: #theStackMemory type: #'void *'>
	stackPageBytes := self stackPageByteSize.
	stackPagesBytes := self computeStackZoneSize.
	theStackMemory := self
							cCode: [self alloca: stackPagesBytes]
							inSmalltalk: [stackPages initializeWithByteSize: stackPagesBytes for: self].
	self cCode: [self me: theStackMemory ms: 0 et: stackPagesBytes].
	stackPages
		initializeStack: theStackMemory
		numSlots: stackPagesBytes / objectMemory wordSize
		pageSize: stackPageBytes / objectMemory wordSize.

	"Once the stack pages are initialized we can continue to bootstrap the system."
	self loadInitialContext.
	"We're ready for the heartbeat (poll interrupt)"
	self ioInitHeartbeat.
	self initialEnterSmalltalkExecutive.
	^nil
]

{ #category : #initialization }
StackInterpreter >> initialCleanup [
	"This used to cope with issues with images written by VMs earlier than 3.6/3.7.
	 Since we won't be loading such images (being a closure only VM) we only have to
	 deal with external primitives.  Since references to external plugins in methods are
	 cleaned up in snapshotCleanUp only initialize the tables, not visit each method."
	<inline: true>
	self flushMethodCache.
	self flushExternalPrimitiveTable
]

{ #category : #initialization }
StackInterpreter >> initialEnterSmalltalkExecutive [
	"Main entry-point into the interpreter at system start-up.
	 In the non-threaded VM this is identical to enterSmalltalkExecutive"
	<cmacro: '() enterSmalltalkExecutiveImplementation()'>
	"Simulation of the setjmp in enterSmalltalkExecutiveImplementation for reentry into interpreter."
	[([self enterSmalltalkExecutiveImplementation]
		on: ReenterInterpreter
		do: [:ex| ex return: ex returnValue]) = ReturnToInterpreter] whileTrue
]

{ #category : #'compiled methods' }
StackInterpreter >> initialIPForHeader: methodHeader method: theMethod [
	"Answer a pointer to the initial byte for a method; used only in methods that build a frame."
	<inline: true>
	^theMethod
	+ ((LiteralStart + (objectMemory literalCountOfMethodHeader: methodHeader)) * objectMemory bytesPerOop)
	+ objectMemory baseHeaderSize
]

{ #category : #initialization }
StackInterpreter >> initialize [
	"Here we can initialize the variables C initializes to zero.  #initialize methods do /not/ get translated."
	super initialize.
	checkAllocFiller := false. "must precede initializeObjectMemory:"
	stackLimit := 0. "This is also the initialization flag for the stack system."
	stackPage := overflowedPage := 0.
	extraFramesToMoveOnOverflow := 0.
	bytecodeSetSelector := 0.
	highestRunnableProcessPriority := 0.
	nextPollUsecs := 0.
	nextWakeupUsecs := 0.
	tempOop := tempOop2 := theUnknownShort := 0.
	interruptPending := false.
	maxStacksToPrint := 0.
	inIOProcessEvents := 0.
	fullScreenFlag := 0.
	sendWheelEvents := deferDisplayUpdates := false.
	displayBits := displayWidth := displayHeight := displayDepth := 0.
	pendingFinalizationSignals := statPendingFinalizationSignals := 0.
	globalSessionID := 0.
	jmpDepth := 0.
	longRunningPrimitiveStartUsecs := longRunningPrimitiveStopUsecs := 0.
	maxExtSemTabSizeSet := false.
	debugCallbackInvokes := debugCallbackPath := debugCallbackReturns := 0.
	statForceInterruptCheck := statStackOverflow := statCheckForEvents :=
	statProcessSwitch := statIOProcessEvents := statStackPageDivorce :=
	statIdleUsecs := 0
]

{ #category : #initialization }
StackInterpreter >> initializeExtraClassInstVarIndices [
	"Initialize metaclassNumSlots and thisClassIndex which are used in debug printing, and
	 classNameIndex which is used not only for debug printing but for is:KindOf: & is:MemberOf:
	 via classNameOf:is: (evil but a reality we have to accept)."
	| classArrayObj classArrayClass |
	classArrayObj := objectMemory splObj: ClassArray.
	classArrayClass := objectMemory fetchClassOfNonImm: classArrayObj.
	metaclassNumSlots := objectMemory numSlotsOf: classArrayClass.	"determine actual Metaclass instSize"
	thisClassIndex := 5. "default"
	InstanceSpecificationIndex + 1 to: (objectMemory lengthOf: classArrayClass) do:
		[:i|
		(objectMemory fetchPointer: i - 1 ofObject: classArrayClass) = classArrayObj ifTrue:
			[thisClassIndex := i - 1]].
	classNameIndex := 6. "default"
	InstanceSpecificationIndex + 1 to: (objectMemory lengthOf: classArrayObj) do:
		[:i| | oop |
		oop := objectMemory fetchPointer: i - 1 ofObject: classArrayObj.
		((objectMemory isBytes: oop)
		and: [(objectMemory lengthOf: oop) = 5
		and: [(objectMemory strncmp: 'Array' _: (objectMemory firstFixedField: oop) _: 5) = 0]]) ifTrue:
			[classNameIndex := i - 1]]
]

{ #category : #initialization }
StackInterpreter >> initializeInterpreter: bytesToShift [
	"Initialize Interpreter state before starting execution of a new image."
	interpreterProxy := self sqGetInterpreterProxy.
	self dummyReferToProxy.
	objectMemory initializeObjectMemory: bytesToShift.
	self checkAssumedCompactClasses.
	self initializeExtraClassInstVarIndices.
	method := newMethod := objectMemory nilObject.
	self cCode: '' inSmalltalk:
		[breakSelectorLength ifNil:
			[breakSelectorLength := objectMemory minSmallInteger]].
	methodDictLinearSearchLimit := 8.
	self initialCleanup.
	LowcodeVM ifTrue: [ self setupNativeStack ].
	profileSemaphore := profileProcess := profileMethod := objectMemory nilObject.
	interruptKeycode := 2094. "cmd-. as used for Mac but no other OS"
	[globalSessionID = 0] whileTrue:
		[globalSessionID := self
								cCode: [(self time: #NULL) + self ioMSecs]
								inSmalltalk: [(Random new next * (SmallInteger maxVal min: 16rFFFFFFFF)) asInteger]].
	metaAccessorDepth := -2.
	super initializeInterpreter: bytesToShift
]

{ #category : #'stack pages' }
StackInterpreter >> initializePageTraceToInvalid: aPage [
	<var: #aPage type: #'StackPage *'>
	aPage trace: StackPageTraceInvalid "for assert checking of the page tracing flags"
]

{ #category : #'method lookup cache' }
StackInterpreter >> inlineLookupInMethodCacheSel: selector classTag: classTag [
	"This method implements a simple method lookup cache.  If an entry for the given selector and classTag is
	 found in the cache, set the values of 'newMethod' and 'primitiveFunctionPointer' and answer true. Otherwise,
	 answer false."
	"About the re-probe scheme: The hash is the low bits of the XOR of two large addresses, minus their useless
	 lowest two bits. If a probe doesn't get a hit, the hash is shifted right one bit to compute the next probe,
	 introducing a new randomish bit. The cache is probed CacheProbeMax times before giving up."
	"WARNING: Since the hash computation is based on the object addresses of the class and selector, we must
	 rehash or flush when compacting storage. We've chosen to flush, since that also saves the trouble of updating
	 the addresses of the objects in the cache."
	"classTag is either a class object, if using NewObjectMemory, or a classIndex, if using SpurMemoryManager."

	| hash probe |
	<inline: true>
	hash := objectMemory methodCacheHashOf: selector with: classTag.  "shift drops two low-order zeros from addresses"

	probe := hash bitAnd: MethodCacheMask.  "first probe"
	(((methodCache at: probe + MethodCacheSelector) = selector) and:
		 [(methodCache at: probe + MethodCacheClass) = classTag]) ifTrue:
			[newMethod := methodCache at: probe + MethodCacheMethod.
			primitiveFunctionPointer := self cCoerceSimple: (methodCache at: probe + MethodCachePrimFunction)
											to: #'void (*)()'.
			^true	"found entry in cache; done"].

	probe := (hash >> 1) bitAnd: MethodCacheMask.  "second probe"
	(((methodCache at: probe + MethodCacheSelector) = selector) and:
		 [(methodCache at: probe + MethodCacheClass) = classTag]) ifTrue:
			[newMethod := methodCache at: probe + MethodCacheMethod.
			primitiveFunctionPointer := self cCoerceSimple: (methodCache at: probe + MethodCachePrimFunction)
											to: #'void (*)()'.
			^true	"found entry in cache; done"].

	probe := (hash >> 2) bitAnd: MethodCacheMask.
	(((methodCache at: probe + MethodCacheSelector) = selector) and:
		 [(methodCache at: probe + MethodCacheClass) = classTag]) ifTrue:
			[newMethod := methodCache at: probe + MethodCacheMethod.
			primitiveFunctionPointer := self cCoerceSimple: (methodCache at: probe + MethodCachePrimFunction)
											to: #'void (*)()'.
			^true	"found entry in cache; done"].

	^false
]

{ #category : #'method lookup cache' }
StackInterpreter >> inlineLookupInNSMethodCacheSel: selector classTag: classTag method: callingMethod lookupRule: lookupRule [
	"Like inlineLookupInMethodCacheSel:classTag:, but the cache is additionally key'd by the calling method and lookupRule/depth and additionally answers localAbsentReceiverOrZero."

	| hash probe |
	<inline: true>
	hash := (objectMemory methodCacheHashOf: selector with: classTag) bitXor: (callingMethod bitXor: lookupRule).

	probe := hash bitAnd: NSMethodCacheMask.  "first probe"
	(((((nsMethodCache at: probe + NSMethodCacheSelector) = selector) and:
		[(nsMethodCache at: probe + NSMethodCacheClassTag) = classTag]) and:
		[(nsMethodCache at: probe + NSMethodCacheCallingMethod) = callingMethod]) and:
		[(nsMethodCache at: probe + NSMethodCacheDepthOrLookupRule) = lookupRule]) ifTrue:
			[newMethod := nsMethodCache at: probe + NSMethodCacheTargetMethod.
			primitiveFunctionPointer := self cCoerceSimple: (nsMethodCache at: probe + NSMethodCachePrimFunction)
											to: #'void (*)()'.
			localAbsentReceiverOrZero := nsMethodCache at: probe + NSMethodCacheActualReceiver.
			^true	"found entry in cache; done"].

	probe := (hash >> 1) bitAnd: NSMethodCacheMask.  "second probe"
	(((((nsMethodCache at: probe + NSMethodCacheSelector) = selector) and:
		[(nsMethodCache at: probe + NSMethodCacheClassTag) = classTag]) and:
		[(nsMethodCache at: probe + NSMethodCacheCallingMethod) = callingMethod]) and:
		[(nsMethodCache at: probe + NSMethodCacheDepthOrLookupRule) = lookupRule]) ifTrue:
			[newMethod := nsMethodCache at: probe + NSMethodCacheTargetMethod.
			primitiveFunctionPointer := self cCoerceSimple: (nsMethodCache at: probe + NSMethodCachePrimFunction)
											to: #'void (*)()'.
			localAbsentReceiverOrZero := nsMethodCache at: probe + NSMethodCacheActualReceiver.
			^true	"found entry in cache; done"].

	probe := (hash >> 2) bitAnd: NSMethodCacheMask.
	(((((nsMethodCache at: probe + NSMethodCacheSelector) = selector) and:
		[(nsMethodCache at: probe + NSMethodCacheClassTag) = classTag]) and:
		[(nsMethodCache at: probe + NSMethodCacheCallingMethod) = callingMethod]) and:
		[(nsMethodCache at: probe + NSMethodCacheDepthOrLookupRule) = lookupRule]) ifTrue:
			[newMethod := nsMethodCache at: probe + NSMethodCacheTargetMethod.
			primitiveFunctionPointer := self cCoerceSimple: (nsMethodCache at: probe + NSMethodCachePrimFunction)
											to: #'void (*)()'.
			localAbsentReceiverOrZero := nsMethodCache at: probe + NSMethodCacheActualReceiver.
			^true	"found entry in cache; done"].

	^false
]

{ #category : #'frame access' }
StackInterpreter >> instVar: offset ofContext: aContext [
	"Fetch an instance variable from a maybe married context.
	 If the context is still married compute the value of the
	 relevant inst var from the spouse frame's state."
	| spouseFP |
	<var: #spouseFP type: #'char *'>
	<inline: true>
	self assert: offset < MethodIndex.
	self assert: (objectMemory isContext: aContext).
	(self isMarriedOrWidowedContext: aContext) ifFalse:
		[^objectMemory fetchPointer: offset ofObject: aContext].

	self writeBackHeadFramePointers.
	(self isWidowedContext: aContext) ifTrue:
		[^objectMemory fetchPointer: offset ofObject: aContext].

	spouseFP := self frameOfMarriedContext: aContext.
	offset = SenderIndex ifTrue:
		[^self ensureCallerContext: spouseFP].
	offset = StackPointerIndex ifTrue:
		[self assert: ReceiverIndex + (self stackPointerIndexForFrame: spouseFP) < (objectMemory lengthOf: aContext).
		^objectMemory integerObjectOf: (self stackPointerIndexForFrame: spouseFP)].
	offset = InstructionPointerIndex ifTrue:
		[^self instructionPointerForFrame: spouseFP currentFP: localFP currentIP: (self oopForPointer: localIP)].
	self error: 'bad index'.
	^0
]

{ #category : #'frame access' }
StackInterpreter >> instVar: index ofContext: aMarriedContext put: anOop [
	| theFP |
	"Assign the field of a married context.  The important case to optimize is
	 assigning the sender.  We could also consider optimizing assigning the IP but
	 typically that is followed by an assignment to the stack pointer and we can't
	 efficiently assign the stack pointer because it involves moving frames around."
	<inline: true>
	self assert: (self isMarriedOrWidowedContext: aMarriedContext).
	self deny: (objectMemory isObjImmutable: aMarriedContext).
	self writeBackHeadFramePointers.
	(self isStillMarriedContext: aMarriedContext) ifFalse:
		[objectMemory storePointer: index ofObject: aMarriedContext withValue: anOop.
		 index = StackPointerIndex ifTrue:
			[self ensureContextIsExecutionSafeAfterAssignToStackPointer: aMarriedContext].
		 ^nil].
	theFP := self frameOfMarriedContext: aMarriedContext.
	index = SenderIndex ifTrue:
		[| thePage onCurrentPage |
		 thePage := stackPages stackPageFor: theFP.
		 self assert: stackPage = stackPages mostRecentlyUsedPage.
		 onCurrentPage := thePage = stackPage.
		 self storeSenderOfFrame: theFP withValue: anOop.
		 onCurrentPage
			ifTrue:
				[localFP := stackPage headFP.
				 localSP := stackPage headSP]
			ifFalse:
				[stackPages markStackPageMostRecentlyUsed: stackPage].
		 ^nil].
	self externalizeIPandSP.
	self externalDivorceFrame: theFP andContext: aMarriedContext.
	(self is: index methodAssignmentToContextWithMachineCodePC: aMarriedContext) ifTrue:
		[self ensureContextHasBytecodePC: aMarriedContext].
	objectMemory storePointer: index ofObject: aMarriedContext withValue: anOop.
	index = StackPointerIndex ifTrue:
		[self ensureContextIsExecutionSafeAfterAssignToStackPointer: aMarriedContext].
	self internalizeIPandSP.
	"Assigning various fields can force a divorce which can change the stackPage."
	stackPages markStackPageMostRecentlyUsed: stackPage.
	self assertValidExecutionPointe: localIP asUnsignedInteger r: localFP s: localSP imbar: true line: #'__LINE__'
]

{ #category : #'indexing primitive support' }
StackInterpreter >> install: rcvr inAtCache: cache at: atIx string: stringy [
	"Attempt to install the oop of this object in the given cache (at or atPut),
	 along with its size, format and fixedSize. Answer if this was successful."
	| hdr fmt totalLength fixedFields |
	<inline: true>
	<var: #cache type: 'sqInt *'>
	self assert: (objectMemory isContext: rcvr) not.
	hdr := objectMemory baseHeader: rcvr.
	fmt := objectMemory formatOfHeader: hdr.
	"For now the AtCache code doesn't support 16-bit indexability."
	(objectMemory hasSpurMemoryManagerAPI
	and: [fmt between: objectMemory firstShortFormat and: objectMemory firstByteFormat - 1]) ifTrue:
		[^self primitiveFail].
	stringy
		ifTrue:
			[totalLength := objectMemory lengthOf: rcvr baseHeader: hdr format: fmt.
			 fixedFields := 0.
			 fmt := fmt + objectMemory firstStringyFakeFormat]  "special flag for strings"
		ifFalse:
			[(fmt = objectMemory indexablePointersFormat and: [objectMemory isContextHeader: hdr]) ifTrue:
				["Contexts must not be put in the atCache, since their size is not constant"
				self primitiveFailFor: PrimErrBadReceiver.
				^false].
			 totalLength := objectMemory lengthOf: rcvr baseHeader: hdr format: fmt.
			 fixedFields := objectMemory fixedFieldsOf: rcvr format: fmt length: totalLength].

	cache at: atIx+AtCacheOop put: rcvr.
	cache at: atIx+AtCacheFmt put: fmt.
	cache at: atIx+AtCacheFixedFields put: fixedFields.
	cache at: atIx+AtCacheSize put: totalLength - fixedFields.
	^true
]

{ #category : #accessing }
StackInterpreter >> instructionPointer [
	<doNotGenerate>
	^ instructionPointer
]

{ #category : #accessing }
StackInterpreter >> instructionPointer: anInteger [
	<doNotGenerate>
	instructionPointer := anInteger
]

{ #category : #'frame access' }
StackInterpreter >> instructionPointerForFrame: spouseFP currentFP: currentFP currentIP: instrPtr [
	"Answer the bytecode pc object (i.e. SmallInteger) for an active frame.  The bytecode
	 pc is derived from the frame's pc.  If the frame is the top frame on the current stack
	 the frame pc is whatever the current instruction pointer is.  If the frame is the top
	 frame on some other stack the frame pc is the value on top of stack.  Otherwise the
	 frame pc is the saved pc of the frame above.  Once the frame pc is found it must be
	 mapped to a bytecode pc."
	<var: #spouseFP type: #'char *'>
	<var: #currentFP type: #'char *'>
	| theIP thePage theFPAbove |
	<var: #thePage type: #'StackPage *'>
	<var: #theFPAbove type: #'char *'>
	spouseFP = currentFP
		ifTrue: [theIP := self oopForPointer: instrPtr]
		ifFalse:
			[thePage := stackPages stackPageFor: spouseFP.
			 theFPAbove := self findFrameAbove: spouseFP inPage: thePage.
			 theIP := theFPAbove = 0
						ifTrue: [stackPages longAt: thePage headSP]
						ifFalse:[self oopForPointer: (self frameCallerSavedIP: theFPAbove)]].
	^self contextInstructionPointer: theIP frame: spouseFP
]

{ #category : #'plugin primitive support' }
StackInterpreter >> integerArg: index [
	"Like #stackIntegerValue: but access method arguments left-to-right"
	<doNotGenerate> "Obsolete; was never used; replaced with methodReturnInteger: in the VirtualMachine struct."
	| oop |
	self deprecated.
	oop := self methodArg: index.
	oop = 0 ifTrue:[^0]. "methodArg: failed"
	^self checkedIntegerValueOf: oop
]

{ #category : #'return bytecodes' }
StackInterpreter >> internalAboutToReturn: resultOop through: aContext [
	| ourContext |
	<inline: true>
	ourContext := self ensureFrameIsMarried: localFP SP: localSP.
	self internalPush: ourContext.
	self internalPush: resultOop.
	self internalPush: aContext.
	messageSelector := objectMemory splObj: SelectorAboutToReturn.
	argumentCount := 2.
	^self normalSend
]

{ #category : #'message sending' }
StackInterpreter >> internalActivateNewMethod [
	| methodHeader numTemps rcvr |
	<inline: true>

	methodHeader := objectMemory methodHeaderOf: newMethod.
	numTemps := self temporaryCountOfMethodHeader: methodHeader.
	self assert: argumentCount = (self argumentCountOfMethodHeader: methodHeader).
	rcvr := self internalStackValue: argumentCount. "could new rcvr be set at point of send?"
	self assert: (objectMemory isOopForwarded: rcvr) not.

	self internalPush: localIP.
	self internalPush: localFP.
	localFP := localSP.
	self internalPush: newMethod.
	self setMethod: newMethod methodHeader: methodHeader.
	self internalPush: (self
						encodeFrameFieldHasContext: false
						isBlock: false
						numArgs: (self argumentCountOfMethodHeader: methodHeader)).
	self internalPush: objectMemory nilObject. "FxThisContext field"
	self internalPush: rcvr.

	"Initialize temps..."
	argumentCount + 1 to: numTemps do:
		[:i | self internalPush: objectMemory nilObject].

	"-1 to account for pre-increment in fetchNextBytecode"
	localIP := self pointerForOop: (self initialIPForHeader: methodHeader method: newMethod) - 1.

	(self methodHeaderHasPrimitive: methodHeader) ifTrue:
		["Skip the CallPrimitive bytecode, if it's there, and store the error code if the method starts
		  with a long store temp.  Strictly no need to skip the store because it's effectively a noop."
		 localIP := localIP + (self sizeOfCallPrimitiveBytecode: methodHeader).
		 primFailCode ~= 0 ifTrue:
			[self reapAndResetErrorCodeTo: localSP header: methodHeader]].

	self assert: (self frameNumArgs: localFP) = argumentCount.
	self assert: (self frameIsBlockActivation: localFP) not.
	self assert: (self frameHasContext: localFP) not.

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)."
	localSP < stackLimit ifTrue:
		[self externalizeIPandSP.
		 self handleStackOverflowOrEventAllowContextSwitch: (self canContextSwitchIfActivating: newMethod header: methodHeader).
		 self internalizeIPandSP]
]

{ #category : #'return bytecodes' }
StackInterpreter >> internalCannotReturn: resultOop [
	| ourContext |
	<inline: true>
	ourContext := self ensureFrameIsMarried: localFP SP: localSP.
	self internalPush: ourContext.
	self internalPush: resultOop.
	messageSelector := objectMemory splObj: SelectorCannotReturn.
	argumentCount := 1.
	^self normalSend
]

{ #category : #'message sending' }
StackInterpreter >> internalExecuteNewMethod [
	| succeeded |
	<inline: true>
	primitiveFunctionPointer ~= 0 ifTrue:
		[self isPrimitiveFunctionPointerAnIndex ifTrue:
			[self internalQuickPrimitiveResponse.
			^ self "keep slang happy"].
		 self externalizeIPandSP.
		 succeeded := self slowPrimitiveResponse.
		 self internalizeIPandSP.
		 succeeded ifTrue:
			[self browserPluginReturnIfNeeded.
			^ self]].
	"if not primitive, or primitive failed, activate the method"
	^self internalActivateNewMethod
]

{ #category : #'message sending' }
StackInterpreter >> internalFindNewMethodOrdinary [
	"Find the compiled method to be run when the current messageSelector is sent to the class 'lkupClass', setting the values of 'newMethod' and 'primitiveIndex'."
	<inline: true>
	(self inlineLookupInMethodCacheSel: messageSelector classTag: lkupClassTag) ifFalse:
		["entry was not found in the cache; look it up the hard way"
		 self externalizeIPandSP.
		 ((objectMemory isOopForwarded: messageSelector)
		  or: [objectMemory isForwardedClassTag: lkupClassTag]) ifTrue:
			[(objectMemory isOopForwarded: messageSelector) ifTrue:
				[messageSelector := self handleForwardedSelectorFaultFor: messageSelector].
			 (objectMemory isForwardedClassTag: lkupClassTag) ifTrue:
				[lkupClassTag := self handleForwardedSendFaultForTag: lkupClassTag].
			(self lookupInMethodCacheSel: messageSelector classTag: lkupClassTag) ifTrue:
				[^nil]].
		 lkupClass := objectMemory classForClassTag: lkupClassTag.
		 self lookupMethodInClass: lkupClass.
		 self internalizeIPandSP.
		 self addNewMethodToCache: lkupClass].

]

{ #category : #'return bytecodes' }
StackInterpreter >> internalMustBeBoolean [
	<inline: true>
	messageSelector := objectMemory splObj: SelectorMustBeBoolean.
	argumentCount := 0.
	self normalSend
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPop: nItems [
	"In the StackInterpreter stacks grow down."
	localSP := localSP + (nItems * objectMemory bytesPerOop)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPop: nItems thenPush: oop [
	"In the StackInterpreter stacks grow down."
	stackPages longAtPointer: (localSP := localSP + ((nItems - 1) * objectMemory bytesPerOop)) put: oop
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPopStack [
	"In the StackInterpreter stacks grow down."
	| top |
	top := stackPages longAt: localSP.
	localSP := localSP + objectMemory bytesPerOop.
	^top
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPopStackFloat32 [
	<option: #LowcodeVM>
	<returnTypeC: #float>
	<var: #topSingle type: #float>
	"In the StackInterpreter stacks grow down."
	| topSingle  |
	nativeSP := self nativeStackPointerIn: localFP.
	topSingle := stackPages singleFloatAtPointer: nativeSP - 1.
	nativeSP := self nativeStackPointerIn: localFP put: nativeSP + objectMemory bytesPerOop.
	^topSingle
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPopStackFloat64 [
	<option: #LowcodeVM>
	<returnTypeC: #double>
	<var: #topDouble type: #double>
	"In the StackInterpreter stacks grow down."
	| topDouble |
	nativeSP := self nativeStackPointerIn: localFP.
	topDouble := stackPages floatAtPointer: nativeSP - 1.
	nativeSP := self nativeStackPointerIn: localFP put: nativeSP + 8.
	^topDouble
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPopStackInt32 [
	<option: #LowcodeVM>
	"In the StackInterpreter stacks grow down."
	| topInt32 |
	nativeSP := self nativeStackPointerIn: localFP.
	topInt32 := stackPages int32AtPointer: nativeSP - 1.
	nativeSP := self nativeStackPointerIn: localFP put: nativeSP + objectMemory bytesPerOop.
	^topInt32
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPopStackInt64 [
	<option: #LowcodeVM>
	<returnTypeC: #sqLong>
	<var: #topInt64 type: #sqLong>
	"In the StackInterpreter stacks grow down."
	| topInt64 |
	nativeSP := self nativeStackPointerIn: localFP.
	topInt64 := stackPages long64AtPointer: nativeSP - 1.
	nativeSP := self nativeStackPointerIn: localFP put: nativeSP + 8.
	^topInt64
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPopStackNativeSize: popSize [
	<option: #LowcodeVM>
	"In the StackInterpreter stacks grow down."
	nativeSP := self nativeStackPointerIn: localFP.
	nativeSP := self nativeStackPointerIn: localFP put: nativeSP + popSize.
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPopStackPointer [
	<option: #LowcodeVM>
	<returnTypeC: #'char*'>
	<var: #topPointer type: #'char*'>
	"In the StackInterpreter stacks grow down."
	| topPointer |
	nativeSP := self nativeStackPointerIn: localFP.
	topPointer := stackPages pointerAtPointer: nativeSP - 1.
	nativeSP := self nativeStackPointerIn: localFP put: nativeSP + objectMemory bytesPerOop.
	^topPointer
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPush: object [
	"In the StackInterpreter stacks grow down."
	stackPages longAtPointer: (localSP := localSP - objectMemory bytesPerOop) put: object
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPushFloat32: singleFloatValue [
	<option: #LowcodeVM>
	<var: #singleFloatValue type: #float >
	"In the StackInterpreter stacks grow down."
	nativeSP := (self nativeStackPointerIn: localFP) - objectMemory bytesPerOop.
	self nativeStackPointerIn: localFP put: nativeSP.

	"In the StackInterpreter stacks grow down."
	stackPages singleFloatAtPointer: (nativeSP - 1) put: singleFloatValue
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPushFloat64: floatValue [
	<option: #LowcodeVM>
	<arg: #floatValue type: #double >
	"In the StackInterpreter stacks grow down."
	nativeSP := (self nativeStackPointerIn: localFP) - 8.
	self nativeStackPointerIn: localFP put: nativeSP.

	"In the StackInterpreter stacks grow down."
	stackPages floatAtPointer: (nativeSP - 1) put: floatValue

]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPushInt32: int32Value [
	<option: #LowcodeVM>
	"In the StackInterpreter stacks grow down."
	nativeSP := (self nativeStackPointerIn: localFP) - objectMemory bytesPerOop.
	self nativeStackPointerIn: localFP put: nativeSP.

	"In the StackInterpreter stacks grow down."
	stackPages int32AtPointer: (nativeSP - 1) put: int32Value

]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPushInt64: int64Value [
	<option: #LowcodeVM>
	<arg: #int64Value type: #sqLong >
	"In the StackInterpreter stacks grow down."
	nativeSP := (self nativeStackPointerIn: localFP) - 8.
	self nativeStackPointerIn: localFP put: nativeSP.

	"In the StackInterpreter stacks grow down."
	stackPages long64AtPointer: (nativeSP - 1) put: int64Value

]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPushPointer: pointerValue [
	<option: #LowcodeVM>
	<var: #pointerValue type: #'char*' >
	"In the StackInterpreter stacks grow down."
	nativeSP := (self nativeStackPointerIn: localFP) - objectMemory bytesPerOop.
	self nativeStackPointerIn: localFP put: nativeSP.

	"In the StackInterpreter stacks grow down."
	stackPages pointerAtPointer: (nativeSP - 1) put: pointerValue

]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPushShadowCallStackFloat32: singleFloatValue [
	<option: #LowcodeVM>
	<var: #singleFloatValue type: #float >
	"In the StackInterpreter stacks grow down."
	shadowCallStackPointer := shadowCallStackPointer - objectMemory bytesPerOop.

	"In the StackInterpreter stacks grow down."
	stackPages singleFloatAtPointer: shadowCallStackPointer put: singleFloatValue
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPushShadowCallStackFloat64: floatValue [
	<option: #LowcodeVM>
	<var: #floatValue type: #double >
	"In the StackInterpreter stacks grow down."
	shadowCallStackPointer := shadowCallStackPointer - 8.

	"In the StackInterpreter stacks grow down."
	stackPages singleFloatAtPointer: shadowCallStackPointer put: floatValue
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPushShadowCallStackInt32: int32Value [
	<option: #LowcodeVM>
	"In the StackInterpreter stacks grow down."
	shadowCallStackPointer := shadowCallStackPointer - objectMemory bytesPerOop.

	"In the StackInterpreter stacks grow down."
	stackPages int32AtPointer: shadowCallStackPointer put: int32Value
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPushShadowCallStackInt64: int64Value [
	<option: #LowcodeVM>
	<arg: #int64Value type: #sqLong >
	
	"In the StackInterpreter stacks grow down."
	shadowCallStackPointer := shadowCallStackPointer - 8.

	"In the StackInterpreter stacks grow down."
	stackPages int64AtPointer: shadowCallStackPointer put: int64Value
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPushShadowCallStackPointer: pointerValue [
	<option: #LowcodeVM>
	<var: #pointerValue type: #'char*' >
	"In the StackInterpreter stacks grow down."
	shadowCallStackPointer := shadowCallStackPointer - BytesPerOop.

	"In the StackInterpreter stacks grow down."
	stackPages pointerAtPointer: shadowCallStackPointer put: pointerValue
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPushShadowCallStackSpace: spaceSize [
	<option: #LowcodeVM>
	"In the StackInterpreter stacks grow down."
	shadowCallStackPointer := shadowCallStackPointer - spaceSize.
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalPushShadowCallStackStructure: structurePointer size: size [
	<option: #LowcodeVM>
	shadowCallStackPointer := shadowCallStackPointer - size.
	self lowcode_mem: shadowCallStackPointer cp: structurePointer y: size
]

{ #category : #'primitive support' }
StackInterpreter >> internalQuickPrimitiveResponse [
	"Invoke a quick primitive.
	 Called under the assumption that primFunctionPtr has been preloaded"
	
	| localPrimIndex |
	self assert: self isPrimitiveFunctionPointerAnIndex.
	localPrimIndex := self cCoerceSimple: primitiveFunctionPointer to: #sqInt.
	self assert: (localPrimIndex > 255 and: [localPrimIndex < 520]).
	"Quick return inst vars"
	localPrimIndex >= 264 ifTrue:
		[self internalStackTopPut: (objectMemory fetchPointer: localPrimIndex - 264 ofObject: self internalStackTop).
		 ^true].
	"Quick return constants"
	localPrimIndex = 256 ifTrue: [^true "return self"].
	localPrimIndex = 257 ifTrue: [self internalStackTopPut: objectMemory trueObject. ^true].
	localPrimIndex = 258 ifTrue: [self internalStackTopPut: objectMemory falseObject. ^true].
	localPrimIndex = 259 ifTrue: [self internalStackTopPut: objectMemory nilObject. ^true].
	self internalStackTopPut: (objectMemory integerObjectOf: localPrimIndex - 261).
	^true
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalStackTop [

	^stackPages longAtPointer: localSP
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalStackTopPut: aValue [

	^stackPages longAtPointer: localSP put: aValue
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalStackTopPutIntegerObjectOf: aValue [
	
	^self internalStackTopPut: (objectMemory integerObjectOf: aValue)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalStackValue: offset [
	"In the StackInterpreter stacks grow down."
	^stackPages longAtPointer: localSP + (offset * objectMemory bytesPerOop)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> internalStackValue: offset put: aValue [
	"In the StackInterpreter stacks grow down."
	^stackPages longAtPointer: localSP + (offset * objectMemory bytesPerOop) put: aValue
]

{ #category : #utilities }
StackInterpreter >> internalizeIPandSP [
	"Copy the instruction, stack and frame pointers to local variables for rapid access within the interpret loop."
	localIP := self pointerForOop: instructionPointer.
	localSP := self pointerForOop: stackPointer.
	localFP := self pointerForOop: framePointer.
	LowcodeVM ifTrue: [ nativeSP := 0. ]
]

{ #category : #'interpreter shell' }
StackInterpreter >> interpret [
	"This is the main interpreter loop. It normally loops forever, fetching and executing bytecodes. When running in the context of a browser plugin VM, however, it must return control to the browser periodically. This should done only when the state of the currently running Squeak thread is safely stored in the object heap. Since this is the case at the moment that a check for interrupts is performed, that is when we return to the browser if it is time to do so. Interrupt checks happen quite frequently."

	<inline: false>
	"If stacklimit is zero then the stack pages have not been initialized."
	stackLimit = 0 ifTrue:
		[^self initStackPagesAndInterpret].
	"record entry time when running as a browser plug-in"
	self browserPluginInitialiseIfNeeded.
	self internalizeIPandSP.
	self initExtensions.
	self fetchNextBytecode.
	[true] whileTrue: [self dispatchOn: currentBytecode in: BytecodeTable].
	localIP := localIP - 1.  "undo the pre-increment of IP before returning"
	self externalizeIPandSP.
	^nil

]

{ #category : #'stack pages' }
StackInterpreter >> interpreterAllocationReserveBytes [
	"At a rough approximation we may need to allocate up to a couple
	 of page's worth of contexts when switching stack pages, assigning
	 to senders, etc.  But the snapshot primitive voids all stack pages.
	 So a safe margin is the size of a large context times the maximum
	 number of frames per page times the number of pages."
	<inline: #never>
	| maxUsedBytesPerPage maxFramesPerPage |
	maxUsedBytesPerPage := self stackPageFrameBytes + self stackLimitOffset.
	maxFramesPerPage := maxUsedBytesPerPage / objectMemory wordSize // FrameSlots.
	^maxFramesPerPage * LargeContextSlots * objectMemory bytesPerOop * numStackPages
]

{ #category : #'I/O primitive support' }
StackInterpreter >> ioBeDisplay: bitsOrHandle width: width height: height depth: depth [
	"Record the position and dimensions of the display bitmap, and inform
	 the display subsystem of the installation of a new display bitmap."
	<var: #bitsOrHandle type: #'void *'>
	| changed |
	changed := displayBits ~= bitsOrHandle.
	displayBits := bitsOrHandle.
	displayWidth := width.
	displayHeight := height.
	displayDepth := depth.
	self ioNoteDisplayChanged: bitsOrHandle width: width height: height depth: depth
]

{ #category : #'plugin support' }
StackInterpreter >> ioFilename: aCharBuffer fromString: aFilenameString ofLength: filenameLength resolveAliases: aBoolean [
"the vm has to convert aFilenameString via any canonicalization and char-mapping and put the result in aCharBuffer.
Note the resolveAliases flag - this is an awful artefact of OSX and Apples demented alias handling. When opening a file, the flag must be  true, when closing or renaming it must be false. Sigh."
	<var: #aCharBuffer type: #'char *'>
	<var: #aFilenameString type: #'char *'>
	self cCode:'sqGetFilenameFromString(aCharBuffer, aFilenameString, filenameLength, aBoolean)'
		inSmalltalk:["this doesn't translate well in Smalltalk since we know how long strings are rather than considering them terminated by a 0 char. Do the best we can"
			aCharBuffer replaceFrom:1 to: filenameLength with: aFilenameString]
]

{ #category : #simulation }
StackInterpreter >> ioForceDisplayUpdate [
	"Make sure the display is updated.  Simulation only"
	<doNotGenerate>
	UIManager default restoreDisplay
]

{ #category : #'primitive support' }
StackInterpreter >> ioLoadExternalFunction: functionName OfLength: functionLength FromModule: moduleName OfLength: moduleLength [
	"Load and return the requested function from a module.
	 N.B. The actual code lives in platforms/Cross/vm/sqNamedPrims.h"
	<doNotGenerate>
	| pluginString functionString |
	pluginString := String new: moduleLength.
	1 to: moduleLength do:[:i| pluginString byteAt: i put: (objectMemory byteAt: moduleName+i-1)].
	functionString := String new: functionLength.
	1 to: functionLength do:[:i| functionString byteAt: i put: (objectMemory byteAt: functionName+i-1)].
	^self ioLoadFunction: functionString From: pluginString
]

{ #category : #'primitive support' }
StackInterpreter >> ioLoadExternalFunction: functionName OfLength: functionLength FromModule: moduleName OfLength: moduleLength AccessorDepthInto: accessorDepthPtr [
	"Load and return the requested function from a module.  Assign the accessor depth through accessorDepthPtr.
	 N.B. The actual code lives in platforms/Cross/vm/sqNamedPrims.h"
	<doNotGenerate>
	| pluginString functionString |
	pluginString := String new: moduleLength.
	(1 to: moduleLength) do:[:i| pluginString byteAt: i put: (objectMemory byteAt: moduleName+i-1)].
	functionString := String new: functionLength.
	(1 to: functionLength) do:[:i| functionString byteAt: i put: (objectMemory byteAt: functionName+i-1)].
	"We used to ignore loads of the SqueakFFIPrims plugin, but that means doing without integerAt:[put:]size:signed:
	 which is too much of a limitation (not that these simulate unaligned accesses yet)."
	
	^self ioLoadFunction: functionString From: pluginString AccessorDepthInto: accessorDepthPtr
]

{ #category : #'primitive support' }
StackInterpreter >> ioLocalMicroseconds [
	<doNotGenerate>
	^self ioUTCMicroseconds + (1000000 * DateAndTime localOffset asSeconds)
]

{ #category : #'primitive support' }
StackInterpreter >> ioLocalMicrosecondsNow [
	<doNotGenerate>
	^self ioUTCMicrosecondsNow + (1000000 * DateAndTime localOffset asSeconds)
]

{ #category : #'primitive support' }
StackInterpreter >> ioLocalSecondsOffset [
	"simulation-only implementation"
	<doNotGenerate>
	^DateAndTime localOffset asSeconds
]

{ #category : #'I/O primitive support' }
StackInterpreter >> ioNoteDisplayChanged: bitsOrHandle width: width height: height depth: depth [
	"The real platform may want to note the location of the display and respond to the fact of
	 its installation."
	<doNotGenerate>
]

{ #category : #'primitive support' }
StackInterpreter >> ioSeconds [
	"simulation-only implementation"
	<doNotGenerate>
	^self ioLocalMicroseconds // 1000000
]

{ #category : #'primitive support' }
StackInterpreter >> ioSecondsNow [
	"simulation-only implementation"
	<doNotGenerate>
	^self ioLocalMicrosecondsNow // 1000000
]

{ #category : #'primitive support' }
StackInterpreter >> ioSetHeartbeatMilliseconds: ignored [
	"simulation-only implementation"
	<doNotGenerate>
]

{ #category : #'primitive support' }
StackInterpreter >> ioUTCMicrosecondsNow [
	"simulation-only implementation"
	<doNotGenerate>
	^self ioUTCMicroseconds
]

{ #category : #'debug support' }
StackInterpreter >> ioUnloadModule: moduleName OfLength: moduleNameLength [
	"Fake forgiving stub.  The actual code is in platforms/Cross/vm/sqNamedPrims.c"
	<doNotGenerate>
	^true
]

{ #category : #'system control primitives' }
StackInterpreter >> ioUpdateVMTimezone [
	"A noop in the simulator"
	<doNotGenerate>
]

{ #category : #'plugin primitive support' }
StackInterpreter >> is: oop KindOf: className [
	"Support for external primitives."
	| oopClass |
	<var: #className type:#'char *'>
	oopClass := objectMemory fetchClassOf: oop.
	[oopClass = objectMemory nilObject] whileFalse:[
		(self classNameOf: oopClass Is: className) ifTrue:[^true].
		oopClass := self superclassOf: oopClass].
	^false
]

{ #category : #'plugin primitive support' }
StackInterpreter >> is: oop KindOfClass: aClass [
	"Support for external primitives."
	<api>
	| oopClass |
	oopClass := objectMemory fetchClassOf: oop.
	[oopClass = objectMemory nilObject] whileFalse:
		[oopClass = aClass ifTrue: [^true].
		 oopClass := self superclassOf: oopClass].
	^false
]

{ #category : #'plugin primitive support' }
StackInterpreter >> is: oop MemberOf: className [
	"Support for external primitives"
	| oopClass |
	<var: #className type:#'char *'>
	oopClass := objectMemory fetchClassOf: oop.
	^(self classNameOf: oopClass Is: className)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> is: fieldIndex methodAssignmentToContextWithMachineCodePC: anOop [
	"This is a hook for the CoInterpreter.  It is a noop in the StackInterpreter."
	<inline: true>
	^false
]

{ #category : #'frame access' }
StackInterpreter >> isBaseFrame: theFP [
	"A base frame (first frame in a stack page) is so marked by having a null saved fp."
	<inline: true>
	<var: #theFP type: #'char *'>
	^(stackPages longAt: theFP + FoxSavedFP) = 0
]

{ #category : #'plugin primitive support' }
StackInterpreter >> isBooleanObject: oop [
	^oop = objectMemory trueObject or: [oop = objectMemory falseObject]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> isCog [
	^false
]

{ #category : #'process primitive support' }
StackInterpreter >> isEmptyList: aLinkedList [
	self assert: (objectMemory isForwarded: aLinkedList) not.
	^ (objectMemory fetchPointer: FirstLinkIndex ofObject: aLinkedList) = objectMemory nilObject
]

{ #category : #'compiled methods' }
StackInterpreter >> isExternalPrimitiveCall: aMethodObj [
	"Answer if the method is an external primtiive call (prim 117)."
	<inline: true>
	^(self primitiveIndexOf: aMethodObj) = PrimNumberExternalCall
]

{ #category : #'internal interpreter access' }
StackInterpreter >> isFloatObject: oop [
	<api>
	<inline: true>
	^objectMemory isFloatInstance: oop
]

{ #category : #'frame access' }
StackInterpreter >> isFrame: aFrame onPage: aPage [
	<var: #aFrame type: #'char *'>
	<var: #aPage type: #'StackPage *'>
	| theFP prevFP |
	<var: #theFP type: #'char *'>
	<var: #prevFP type: #'char *'>
	self deny: (stackPages isFree: aPage).
	"Walk the static chain making sure progress is being made,
	 and in the right direction, looking for a match with aFrame."
	theFP := aPage headFP.
	prevFP := theFP - objectMemory wordSize.
	[theFP = aFrame ifTrue: [^true].
	 theFP > prevFP
	 and: [theFP < aPage baseFP]] whileTrue:
		[prevFP := theFP.
		 theFP := self frameCallerFP: theFP].
	^false
]

{ #category : #'internal interpreter access' }
StackInterpreter >> isKindOfInteger: oop [
	"Answer true if the oop is kind of Integer (Small or Large)."
	<api>
	<inline: true>
	^(objectMemory isIntegerObject: oop)
		or: [objectMemory isLargeIntegerInstance: oop]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> isLargeIntegerObject: oop [
	<api>
	<inline: true>
	^objectMemory isLargeIntegerInstance: oop
]

{ #category : #'internal interpreter access' }
StackInterpreter >> isLargeNegativeIntegerObject: oop [
	<api>
	<inline: true>
	^objectMemory isInstanceOfClassLargeNegativeInteger: oop
]

{ #category : #'internal interpreter access' }
StackInterpreter >> isLargePositiveIntegerObject: oop [
	<api>
	<inline: true>
	^objectMemory isInstanceOfClassLargePositiveInteger: oop
]

{ #category : #'frame access' }
StackInterpreter >> isLiveContext: oop [
	"Answer if the argument, which can be any object, is a live context."
	self deny: (objectMemory isOopForwarded: oop).
	(objectMemory isContext: oop) ifFalse:
		[^false].
	(self isSingleContext: oop) ifTrue:
		[^objectMemory isIntegerObject: (objectMemory fetchPointer: InstructionPointerIndex ofObject: oop)].
	^(self isWidowedContext: oop) not
]

{ #category : #'frame access' }
StackInterpreter >> isMachineCodeFrame: theFP [
	"For compatibility with CoInterpreter.  Needed to avoid slowPrimitiveResponse
	 failing within ceSend:to:numArgs: et al with an unbalanced stack."
	<var: #theFP type: #'char *'>
	<inline: true>
	^false
]

{ #category : #'frame access' }
StackInterpreter >> isMarriedOrWidowedContext: aContext [
	^objectMemory isIntegerObject: (objectMemory fetchPointer: SenderIndex ofObject: aContext)
]

{ #category : #'primitive support' }
StackInterpreter >> isMetaPrimitiveIndex: primIndex [
	"This virtual machine provides two primitives that executes arbitrary primitives, one
	 for indexed primitivces and one for named primitives.  These meta primitives are used
	 in the debugger to execute primitives while simulating execution.  Spur needs to know
	 the accessor depth for a primitive so that failures due to forwarders can be fixed up
	 and retried.  This method identifies such meta primitives so that metaAccessorDepth
	 can be substituted when appropriate."
	<inline: true>
	^primIndex = PrimNumberDoPrimitive
	  or: [primIndex = PrimNumberDoExternalCall]
]

{ #category : #'compiled methods' }
StackInterpreter >> isNullExternalPrimitiveCall: aMethodObj [
	"Answer if the method is an external primtiive call (prim 117) with a null external primtiive.
	 This is just for an assert in the CoInterpreter."
	| lit |
	((self isExternalPrimitiveCall: aMethodObj)
	and: [(objectMemory literalCountOf: aMethodObj) > 0]) ifFalse:
		[^false].

	lit := self literal: 0 ofMethod: aMethodObj.
	^(objectMemory isArray: lit)
	  and: [(objectMemory numSlotsOf: lit) = 4
	  and: [(objectMemory fetchPointer: 3 ofObject: lit) = ConstZero
			or: [(objectMemory fetchPointer: 3 ofObject: lit) = ConstMinusOne]]]
]

{ #category : #'compiled methods' }
StackInterpreter >> isOptimizedMethod: methodObj [
	<api>
	<option: #SistaVM>
	^self isOptimizedMethodHeader: (objectMemory methodHeaderOf: methodObj)
]

{ #category : #'compiled methods' }
StackInterpreter >> isOptimizedMethodHeader: header [
	<option: #SistaVM>
	^header anyMask: AlternateHeaderIsOptimizedFlag
]

{ #category : #'primitive support' }
StackInterpreter >> isPrimitiveFunctionPointerAnIndex [
	"We save slots in the method cache by using the primitiveFunctionPointer
	 to hold either a function pointer or the index of a quick primitive. Since
	 quick primitive indices are small they can't be confused with function
	 addresses. "
	^(self cCoerce: primitiveFunctionPointer to: #'usqIntptr_t') <= MaxQuickPrimitiveIndex
]

{ #category : #'compiled methods' }
StackInterpreter >> isQuickPrimitiveIndex: anInteger [
	<api>
	^anInteger between: 256 and: 519
]

{ #category : #'frame access' }
StackInterpreter >> isReadMediatedContextInstVarIndex: index [
	"Reading the sender, instructionPointer and stackPointer inst vars of a context must take
	 account of potentially married contexts and fetch the state from the frame. method,
	 closureOrNil and receiver can safely be fetched from the context without checking."
	<api>
	<inline: true>
	^index <= StackPointerIndex
]

{ #category : #'frame access' }
StackInterpreter >> isSingleContext: aContext [
	^objectMemory isNonImmediate: (objectMemory fetchPointer: SenderIndex ofObject: aContext)
]

{ #category : #'frame access' }
StackInterpreter >> isStillMarriedContext: aContext [
	"Answer if aContext is married or widowed and still married.
	 If a context is widowed then turn it into a single dead context."
	^(self isMarriedOrWidowedContext: aContext)
	    and: [(self isWidowedContext: aContext) not]
]

{ #category : #'frame access' }
StackInterpreter >> isStillMarriedContextDuringGC: aContext [
	"Answer if aContext is married or widowed and still married.
	 If a context is widowed then turn it into a single dead context.
	This version is for use during scavenging when stack references may be forwarded.
	 Following what appear to be references to forwarded objects on the stack is dangerous;
	 an instruction ponter may be correctly aligned and may point to bytes that just happen
	 to look like a forwarder. So it is only safe to follow fields that we know are frameContext
	 fields; hence the stack page is walked to check that aOnceMarriedContext is pointing to
	 a live frame.  This only has to happen during scavenging because after a become: all
	 frameContext fields have been followed and so there is no need to follow forwarders."
	^(self isMarriedOrWidowedContext: aContext)
	    and: [(self isWidowedContextDuringGC: aContext) not]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> isVanillaBlockClosure: aClosure [
	"Answer if aClosure is a vanilla BlockClosure as in the first Cog release, BlockClosure laid out as 
	 'outerContext, startpc, numArgs.  FullBlockClosure is laid out as  outerContext, method, numArgs, receiver.
	 So either answer true if we're not supporting FullBlockClosure, or test the startpc/method field."
	<inline: true>
	^SistaV1BytecodeSet
		ifTrue: [objectMemory isIntegerObject: (objectMemory fetchPointer: ClosureStartPCIndex ofObject: aClosure)]
		ifFalse: [true]
]

{ #category : #'frame access' }
StackInterpreter >> isWidowedContext: aOnceMarriedContext [
	"See if the argument is married to a live frame or not.
	 If it is not, turn it into a bereaved single context. This version is safe for use
	 only when no frameContext fields may be forwarded (as maybe the case
	 when scavenging).  Post become: all frameContext fields are followed, and
	 hence nrmally no following of frameCOtext fields is necessary.  But during
	 a scavenge one must use isWidowedContextDuringGC:."
	| theFrame thePage shouldBeFrameCallerField |
	<var: #theFrame type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #shouldBeFrameCallerField type: #'char *'>
	self assert: ((objectMemory isContext: aOnceMarriedContext)
				  and: [self isMarriedOrWidowedContext: aOnceMarriedContext]).
	theFrame := self frameOfMarriedContext: aOnceMarriedContext.
	thePage := stackPages stackPageFor: theFrame.
	((stackPages isFree: thePage)
	 or: [theFrame < thePage headFP]) ifFalse:
		["The frame pointer is within the bounds of a live page.
		   Now check if it matches a frame."
		 shouldBeFrameCallerField := self withoutSmallIntegerTags:
											(objectMemory
												fetchPointer: InstructionPointerIndex
												ofObject: aOnceMarriedContext).
		 ((self frameCallerFP: theFrame) = shouldBeFrameCallerField
		  and: [self frameHasContext: theFrame]) ifTrue:
			[self deny: (((self isFrame: theFrame onPage: thePage))
						and: [objectMemory isForwarded: (self frameContext: theFrame)]).
			 (self frameContext: theFrame) = aOnceMarriedContext ifTrue: "It is still married!"
				[^false]]].
	"It is out of range or doesn't match the frame's context.
	 It is widowed. Time to wear black."
	self markContextAsDead: aOnceMarriedContext.
	^true
]

{ #category : #'frame access' }
StackInterpreter >> isWidowedContextDuringGC: aOnceMarriedContext [
	"See if the argument is married to a live frame or not.  i.e. see if there is a matching
	 frame whose frameContext field is aOnceMarriedContext, or a forwarder to it.
	 If aOnceMarriedContext is not married to a live frame, turn it into a bereaved single context.
	 This version is for use during scavenging when stack references may be forwarded.
	 Following what appear to be references to forwarded objects on the stack is dangerous;
	 an instruction ponter may be correctly aligned and may point to bytes that just happen
	 to look like a forwarder. So it is only safe to follow fields that we know are frameContext
	 fields; hence the stack page is walked to check that aOnceMarriedContext is pointing to
	 a live frame.  This only has to happen during scavenging because after a become: all
	 frameContext fields have been followed and so there is no need to follow forwarders."
	| maybeFrame thePage shouldBeFrameCallerField maybeFrameCtxt |
	<var: #maybeFrame type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #shouldBeFrameCallerField type: #'char *'>
	self assert: ((objectMemory isContext: aOnceMarriedContext)
				  and: [self isMarriedOrWidowedContext: aOnceMarriedContext]).
	maybeFrame := self frameOfMarriedContext: aOnceMarriedContext.
	thePage := stackPages stackPageFor: maybeFrame.
	((stackPages isFree: thePage)
	 or: [maybeFrame < thePage headFP]) ifFalse:
		["The frame pointer is within the bounds of a live page.
		   Now check if it matches a frame."
		 shouldBeFrameCallerField := self withoutSmallIntegerTags:
											(objectMemory
												fetchPointer: InstructionPointerIndex
												ofObject: aOnceMarriedContext).
		 ((self frameCallerFP: maybeFrame) = shouldBeFrameCallerField
		  and: [self frameHasContext: maybeFrame]) ifTrue:
			[maybeFrameCtxt := self frameContext: maybeFrame.
			 "On Spur we need to follow the context to check for a match, but since the VM is
			  only speculating about maybeFrame being a frame, and only speculating about
			  maybeContext being a context, we need to be sure before we can safely follow."
			 (objectMemory hasSpurMemoryManagerAPI
			  and: [(self isFrame: maybeFrame onPage: thePage)
			  and: [objectMemory isForwarded: maybeFrameCtxt]]) ifTrue:
				[maybeFrameCtxt := objectMemory followForwarded: maybeFrameCtxt.
				 self setFrameContext: maybeFrame to: maybeFrameCtxt].
			 maybeFrameCtxt = aOnceMarriedContext ifTrue: "It is still married!"
				[^false]]].
	"It is out of range or doesn't match the frame's context.
	 It is widowed. Time to wear black."
	self markContextAsDead: aOnceMarriedContext.
	^true
]

{ #category : #'frame access' }
StackInterpreter >> isWriteMediatedContextInstVarIndex: index [
	"Wrining any inst vars of a context must take account of potentially married contexts
	 and set the state in the frame. Inst vars in subclasses don't need mediation; subclasses
	 can't marry."
	<api>
	<inline: true>
	^index <= ReceiverIndex
]

{ #category : #'jump bytecodes' }
StackInterpreter >> jump: offset [
	localIP := localIP + offset + 1.
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [currentBytecode := (objectMemory byteAtPointer: localIP) + bytecodeSetSelector]
		ifFalse: [currentBytecode := objectMemory byteAtPointer: localIP]
]

{ #category : #'sista bytecodes' }
StackInterpreter >> jumpBinaryInlinePrimitive: primIndex [
	<option: #SistaVM>
	| test offset top |
	top := self internalStackTop.
	self assert: (objectMemory isIntegerObject: top).
	offset := objectMemory integerValueOf: top.
	test := self internalStackValue: 1.
	self assert: offset >= 0.
	primIndex caseOf: {
		"7016	jumpIfWritable:
		 Not a forwarder, literal which is a Smi"
		[16]	->	[self deny: (objectMemory isOopForwarded: test).
					 self deny: (objectMemory isImmediate: test).
					 (objectMemory isImmutable: test) ifFalse: [localIP := localIP + offset]].
		"7017	jumpIfReadOnly:
		 Not a forwarder, literal which is a Smi"
		[17]	->	[self deny: (objectMemory isOopForwarded: test).
					 self deny: (objectMemory isImmediate: test).
					 (objectMemory isImmutable: test) ifTrue: [localIP := localIP + offset]].
		"7018	jumpIfYoung:
		 Not a forwarder, literal which is a Smi"
		[18]	->	[self deny: (objectMemory isOopForwarded: test).
					 self deny: (objectMemory isImmediate: test).
					 (objectMemory isYoungObject: test) ifTrue: [localIP := localIP + offset]].
		"7019	jumpIfOld:
		 Not a forwarder, literal which is a Smi"
		[19]	->	[self deny: (objectMemory isOopForwarded: test).
					 self deny: (objectMemory isImmediate: test).
					 (objectMemory isYoungObject: test) ifFalse: [localIP := localIP + offset]].
	}.
	localIP := localIP - 1. "we've already fetched, but we may have incorrectly fetched if jump"
	self fetchNextBytecode.
	self internalPop: 2.
	
]

{ #category : #'sista bytecodes' }
StackInterpreter >> jumpTrinaryInlinePrimitive: primIndex [
	<option: #SistaVM>
	"Note: those tests work with forwarders (wrong class index)"
	| test classObj offset classTag top |
	top := self internalStackTop.
	self assert: (objectMemory isIntegerObject: top).
	offset := objectMemory integerValueOf: top.
	self assert: offset >= 0.
	test := self internalStackValue: 2.
	classObj := self internalStackValue: 1.
	self assert: (objectMemory isNonImmediate: classObj).
	primIndex caseOf: {
	[0] -> 	["8000	jumpIfInstanceOf:distance:
			 Anything, literal which is a Behavior, literal which is a Smi"
			 self assert: (self objCouldBeClassObj: classObj).
			 classTag := objectMemory fetchClassTagOf: test.
			 classTag = (objectMemory rawClassTagForClass: classObj) ifTrue: 
				[localIP := localIP + offset]].
	[1] -> 	["8001	jumpIfNotInstanceOf:distance:
			 Anything, literal which is a Behavior, literal which is a Smi"
			 self assert: (self objCouldBeClassObj: classObj).
			 classTag := objectMemory fetchClassTagOf: test.
			 classTag = (objectMemory rawClassTagForClass: classObj) ifFalse: 
				[localIP := localIP + offset]].
	[2] -> 	["8002	jumpIfInstanceOfOneOf:distance:
			 Anything, Array of behaviors, literal which is a Smi"
			 self assert: (objectMemory isArrayNonImm: classObj).
			 classTag := objectMemory fetchClassTagOf: test.
			0 to: (objectMemory numSlotsOf: classObj) asInteger - 1 do:
			[:i |
			 classTag = (objectMemory rawClassTagForClass: (objectMemory fetchPointer: i ofObject: classObj)) ifTrue:
				[localIP := localIP + offset]]].
	[3] -> 	["8003	jumpIfNotInstanceOfOneOf:distance:
			  Anything, Array of behaviors, literal which is a Smi"
			 self assert: (objectMemory isArrayNonImm: classObj).
			 classTag := objectMemory fetchClassTagOf: test.
			0 to: (objectMemory numSlotsOf: classObj) asInteger - 1 do:
			[:i |
			 classTag = (objectMemory rawClassTagForClass: (objectMemory fetchPointer: i ofObject: classObj)) ifTrue:
				[localIP := localIP - 1.
				 self fetchNextBytecode.
				 ^self internalPop: 3]].
			localIP := localIP + offset].
	}.
	localIP := localIP - 1. "we've already fetched, but we may have incorrectly fetched if jump"
	self fetchNextBytecode.
	self internalPop: 3
	
]

{ #category : #'sista bytecodes' }
StackInterpreter >> jumpUnaryInlinePrimitive: primIndex [
	<option: #SistaVM>
	"6000	backjumpNoInterrupt
	 literal which is a Smi"
	| top |
	top := self internalStackTop.
	primIndex = 0 ifTrue: 
		[self assert: (objectMemory isIntegerObject: top). 
		 self assert: (objectMemory integerValueOf: top) < 0.
		"We've already fetched next bytecode, so we add -1"
		 localIP := localIP + (objectMemory integerValueOf: top) - 1. 
		 self fetchNextBytecode.
		 ^self internalPop: 1].
	^ self unknownInlinePrimitive	
]

{ #category : #'jump bytecodes' }
StackInterpreter >> jumplfFalseBy: offset [ 
	| boolean |
	boolean := self internalStackTop.
	boolean = objectMemory falseObject
		ifTrue: [self jump: offset]
		ifFalse:
			[boolean = objectMemory trueObject ifFalse:
				[^self internalMustBeBoolean].
			self fetchNextBytecode].
	self internalPop: 1
]

{ #category : #'jump bytecodes' }
StackInterpreter >> jumplfTrueBy: offset [ 
	| boolean |
	boolean := self internalStackTop.
	boolean = objectMemory trueObject
		ifTrue: [self jump: offset]
		ifFalse:
			[boolean = objectMemory falseObject ifFalse:
				[^self internalMustBeBoolean].
			self fetchNextBytecode].
	self internalPop: 1
]

{ #category : #'message sending' }
StackInterpreter >> justActivateNewMethod: mustBeInterpreterFrame [
	| methodHeader numArgs numTemps rcvr |
	<inline: true>
	"Create the frame for the method activation"
	methodHeader := objectMemory methodHeaderOf: newMethod.
	numTemps := self temporaryCountOfMethodHeader: methodHeader.
	numArgs := self argumentCountOfMethodHeader: methodHeader.

	rcvr := self stackValue: numArgs. "could new rcvr be set at point of send?"
	self assert: (objectMemory isOopForwarded: rcvr) not.

	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: newMethod.
	self setMethod: newMethod methodHeader: methodHeader.
	self push: (self encodeFrameFieldHasContext: false isBlock: false numArgs: numArgs).
	self push: objectMemory nilObject. "FxThisContext field"
	self push: rcvr.

	"clear remaining temps to nil"
	numArgs+1 to: numTemps do:
		[:i | self push: objectMemory nilObject].

	instructionPointer := (self initialIPForHeader: methodHeader method: newMethod) - 1.

	(self methodHeaderHasPrimitive: methodHeader) ifTrue:
		["Skip the CallPrimitive bytecode, if it's there, and store the error code if the method starts
		  with a long store temp.  Strictly no need to skip the store because it's effectively a noop."
		 instructionPointer := instructionPointer + (self sizeOfCallPrimitiveBytecode: methodHeader).
		 primFailCode ~= 0 ifTrue:
			[self reapAndResetErrorCodeTo: stackPointer header: methodHeader]].

	^methodHeader
]

{ #category : #'debug printing' }
StackInterpreter >> lengthOfNameOfClass: classOop [
	<inline: false>
	| numSlots |
	numSlots := objectMemory numSlotsOf: classOop.
	numSlots = metaclassNumSlots ifTrue:
		[^self lengthOfNameOfClass: (objectMemory fetchPointer: thisClassIndex ofObject: classOop)].
	numSlots <= classNameIndex ifTrue:
		[^0].
	^objectMemory lengthOf: (objectMemory fetchPointer: classNameIndex ofObject: classOop)
]

{ #category : #accessing }
StackInterpreter >> libFFI [
	<doNotGenerate>
	^ libFFI
]

{ #category : #accessing }
StackInterpreter >> libFFI: aLibFFI [ 
	<doNotGenerate>
	libFFI := aLibFFI
]

{ #category : #'compiled methods' }
StackInterpreter >> literal: offset [
	self assert: method = (self iframeMethod: localFP).
	^self literal: offset ofMethod: method
]

{ #category : #'compiled methods' }
StackInterpreter >> literal: offset ofMethod: methodPointer [
	<api>
	^objectMemory fetchPointer: offset + LiteralStart ofObject: methodPointer

]

{ #category : #'compiled methods' }
StackInterpreter >> literal: offset ofMethod: methodPointer put: oop [
	<option: #SpurMemoryManager>
	<inline: true>
	objectMemory storePointer: offset + LiteralStart ofObject: methodPointer withValue: oop

]

{ #category : #'compiled methods' }
StackInterpreter >> literalCountOfAlternateHeader: headerPointer [
	<inline: true>
	^(objectMemory integerValueOf: headerPointer) bitAnd: AlternateHeaderNumLiteralsMask
]

{ #category : #'compiled methods' }
StackInterpreter >> literalCountOfOriginalHeader: headerPointer [
	<inline: true>
	^(headerPointer >> 10) bitAnd: 16rFF
]

{ #category : #'bitblt support' }
StackInterpreter >> loadBitBltFrom: bb [
	"This entry point needs to be implemented for the interpreter proxy.
	Since BitBlt is now a plugin we need to look up BitBltPlugin:=loadBitBltFrom
	and call it. This entire mechanism should eventually go away and be
	replaced with a dynamic lookup from BitBltPlugin itself but for backward
	compatibility this stub is provided"
	| fn |
	<var: #fn type: 'void *'>
	fn := self ioLoadFunction: 'loadBitBltFrom' From: 'BitBltPlugin'.
	fn = 0 ifTrue: [^self primitiveFail].
	^self cCode: '((sqInt (*)(sqInt))fn)(bb)'
]

{ #category : #initialization }
StackInterpreter >> loadInitialContext [
	<inline: false>
	| activeProc activeContext |
	self cCode: [] inSmalltalk: [self initExtensions].
	objectMemory runLeakCheckerFor: GCModeFull.
	activeProc := self activeProcess.
	activeContext := objectMemory fetchPointer: SuspendedContextIndex ofObject: activeProc.
	self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext
]

{ #category : #'debug printing' }
StackInterpreter >> log10: n [
	"compat with C library."
	<doNotGenerate>
	^n log: 10
]

{ #category : #simulation }
StackInterpreter >> long: aJumpBuf jmp: returnValue [
	"Hack simulation of setjmp/longjmp.
	 Signal the exception that simulates a longjmp back to the interpreter." 
	<doNotGenerate>
	aJumpBuf == reenterInterpreter ifTrue:
		[self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: true line: nil].
	aJumpBuf returnValue: returnValue; signal
]

{ #category : #'jump bytecodes' }
StackInterpreter >> longJumpIfFalse [

	self jumplfFalseBy: ((currentBytecode bitAnd: 3) * 256) + self fetchByte.
]

{ #category : #'jump bytecodes' }
StackInterpreter >> longJumpIfTrue [

	self jumplfTrueBy: ((currentBytecode bitAnd: 3) * 256) + self fetchByte.
]

{ #category : #'debug printing' }
StackInterpreter >> longPrintOop: oop [
	<api>
	| fmt lastIndex startIP bytecodesPerLine column |
	<var: 'field16' type: #'unsigned short'>
	<var: 'field32' type: #'unsigned int'>
	<var: 'field64' type: #usqLong>
	((objectMemory isImmediate: oop)
	 or: [(objectMemory addressCouldBeObj: oop) not
	 or: [(oop bitAnd: objectMemory allocationUnit - 1) ~= 0
	 or: [(objectMemory isFreeObject: oop)
	 or: [objectMemory isForwarded: oop]]]]) ifTrue:
		[self printOop: oop.
		 ^self].
	self printHex: oop.
	(objectMemory fetchClassOfNonImm: oop)
		ifNil: [self print: ' has a nil class!!']
		ifNotNil: [:class|
			self print: ': a(n) '; printNameOfClass: class count: 5;
				print: ' ('.
			objectMemory hasSpurMemoryManagerAPI ifTrue:
				[self printHexnp: (objectMemory compactClassIndexOf: oop); print: '=>'].
			self printHexnp: class; print: ')'].
	fmt := objectMemory formatOf: oop.
	self print: ' format '; printHexnp: fmt.
	fmt > objectMemory lastPointerFormat
		ifTrue: [self print: ' nbytes '; printNum: (objectMemory numBytesOf: oop)]
		ifFalse: [(objectMemory isIndexableFormat: fmt) ifTrue:
					[| len |
					len := objectMemory lengthOf: oop.
					self print: ' size '; printNum: len - (objectMemory fixedFieldsOf: oop format: fmt length: len)]].
	objectMemory printHeaderTypeOf: oop.
	self print: ' hash '; printHexnp: (objectMemory rawHashBitsOf: oop).
	self cr.
	(fmt between: objectMemory firstByteFormat and: objectMemory firstCompiledMethodFormat - 1) ifTrue:
		[self printStringOf: oop; cr. 
		^ self "keep slang happy !"
		].
	(fmt between: objectMemory firstLongFormat and: objectMemory firstByteFormat - 1) ifTrue:
		[0 to: ((objectMemory num32BitUnitsOf: oop) min: 256) - 1 do:
			[:i| | field32 |
			field32 := objectMemory fetchLong32: i ofObject: oop.
			self space; printNum: i; space; printHex: field32; space; cr].
		 ^self].
	objectMemory hasSpurMemoryManagerAPI ifTrue:
		[fmt = objectMemory sixtyFourBitIndexableFormat ifTrue:
			[0 to: ((objectMemory num64BitUnitsOf: oop) min: 256) - 1 do:
				[:i| | field64 |
				field64 := objectMemory fetchLong64: i ofObject: oop.
				self space; printNum: i; space; printHex: field64; space; cr].
			 ^self].
		 (fmt between: objectMemory firstShortFormat and: objectMemory firstShortFormat + 1) ifTrue:
			[0 to: ((objectMemory num16BitUnitsOf: oop) min: 256) - 1 do:
				[:i| | field16 |
				field16 := objectMemory fetchShort16: i ofObject: oop.
				self space; printNum: i; space; printHex: field16; space; cr].
			 ^self]].
	"this is nonsense.  apologies."
	startIP := (objectMemory lastPointerOf: oop) + objectMemory bytesPerOop - objectMemory baseHeaderSize / objectMemory bytesPerOop.
	lastIndex := 256 min: startIP.
	lastIndex > 0 ifTrue:
		[1 to: lastIndex do:
			[:i| | fieldOop |
			fieldOop := objectMemory fetchPointer: i - 1 ofObject: oop.
			self space; printNum: i - 1; space; printHex: fieldOop; space.
			(i = 1 and: [objectMemory isCompiledMethod: oop])
				ifTrue: [self printMethodHeaderOop: fieldOop]
				ifFalse: [self cCode: [self printOopShort: fieldOop]
							inSmalltalk: [self print: (self shortPrint: fieldOop)]].
			self cr]].
	(objectMemory isCompiledMethod: oop)
		ifFalse:
			[startIP > lastIndex ifTrue: [self print: '...'; cr]]
		ifTrue:
			[startIP := startIP * objectMemory wordSize + 1.
			 lastIndex := objectMemory lengthOf: oop.
			 lastIndex - startIP > 100 ifTrue:
				[lastIndex := startIP + 100].
			 bytecodesPerLine := 8.
			 column := 1.
			 startIP to: lastIndex do:
				[:index| | byte |
				column = 1 ifTrue:
					[self cCode: 'vm_printf("0x%08" PRIxSQPTR ": ", (usqIntptr_t)(oop+BaseHeaderSize+index-1))'
						inSmalltalk: [self print: (oop+objectMemory baseHeaderSize+index-1) hex; print: ': ']].
				byte := objectMemory fetchByte: index - 1 ofObject: oop.
				self cCode: 'vm_printf(" %02x/%-3d", (int)byte,(int)byte)'
					inSmalltalk: [self space; print: (byte radix: 16); printChar: $/; printNum: byte].
				column := column + 1.
				column > bytecodesPerLine ifTrue:
					[column := 1. self cr]].
			column = 1 ifFalse:
				[self cr]].
]

{ #category : #'stack bytecodes' }
StackInterpreter >> longPushTemporaryVariableBytecode [
	"230		11100110	i i i i i i i i	Push Temporary Variable #iiiiiiii"
	| index |
	index := self fetchByte.
	self fetchNextBytecode.
	self internalPush: (self temporary: index in: localFP)
]

{ #category : #'stack bytecodes' }
StackInterpreter >> longStoreAndPopTemporaryVariableBytecode [
	"237		11101101	i i i i i i i i	Pop and Store Temporary Variable #iiiiiiii"
	self longStoreTemporaryVariableBytecode.
	self internalPop: 1
]

{ #category : #'compiled methods' }
StackInterpreter >> longStoreBytecodeForHeader: methodHeader [
	"Answer the relevant long store temp bytecode, which indicates it has a primitive error code."
	"234		11101010	i i i i i i i i	Store Temporary Variable #iiiiiiii"
	"129 		10000001 jjkkkkkk 	Store (Receiver Variable, Temporary Location, Illegal, Literal Variable) [jj] #kkkkkk"
	<api>
	<inline: true>
	^self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [(objectMemory headerIndicatesAlternateBytecodeSet: methodHeader)
					ifTrue: [AltLongStoreBytecode]
					ifFalse: [LongStoreBytecode]]
		ifFalse: [LongStoreBytecode]
]

{ #category : #'stack bytecodes' }
StackInterpreter >> longStoreTemporaryVariableBytecode [
	"234		11101010	i i i i i i i i	Store Temporary Variable #iiiiiiii"
	| index |
	index := self fetchByte.
	self fetchNextBytecode.
	self temporary: index in: localFP put: self internalStackTop
]

{ #category : #'jump bytecodes' }
StackInterpreter >> longUnconditionalJump [
	| offset |
	offset := (((currentBytecode bitAnd: 7) - 4) * 256) + self fetchByte.
	localIP := localIP + offset.
	self ifBackwardsCheckForEvents: offset.
	self fetchNextBytecode
]

{ #category : #'debug support' }
StackInterpreter >> lookupBreakFor: lookupClass [
	<inline: true>
	(objectMemory shouldBreakForLookupIn: lookupClass given: breakLookupClassTag) ifTrue:
		[self
			cCode: [self warning: 'lookup class send break (heartbeat suppressed)']
			inSmalltalk: [self halt: 'Lookup in class ', lookupClass hex]]
]

{ #category : #'method lookup cache' }
StackInterpreter >> lookupInMethodCacheSel: selector classTag: classTag [
	"This method implements a simple method lookup cache.  If an entry for the given
	 selector and classTag is found in the cache, set the values of 'newMethod' and
	 'primitiveFunctionPointer' and answer true. Otherwise, answer false."
	<inline: false>
	^self inlineLookupInMethodCacheSel: selector classTag: classTag
]

{ #category : #'message sending' }
StackInterpreter >> lookupMNU [
	"A send lookup failed. Replace the arguments on the stack with a Message and lookup
	 #doesNotUndestand: starting at lkupClass. Note that MNU lookup ignores access modifiers.
	 This makes it different from an ordinary send of #doesNotUnderstand:, which must only
	 find public methods.
	IN: lkupClass
	IN: messageSelector
	IN: argumentCount
	OUT: newMethod
	OUT: primitiveIndex
	RESULT: LookupRuleMNU"

	| currentClass dictionary found |
	self lookupBreakFor: lkupClass.
	self createActualMessageTo: lkupClass.
	messageSelector := objectMemory splObj: SelectorDoesNotUnderstand.
	currentClass := lkupClass.
	[currentClass ~= objectMemory nilObject] whileTrue:
		[dictionary := objectMemory followObjField: MethodDictionaryIndex ofObject: currentClass.
		found := self lookupMethodInDictionary: dictionary.
		found ifTrue: [^LookupRuleMNU].
		currentClass := self superclassOf: currentClass].

	self error: 'Recursive not understood error encountered'

]

{ #category : #'message sending' }
StackInterpreter >> lookupMNUInClass: class [
	"Lookup messageSelector in class.  Answer 0 on success. Answer the splObj: index
	 for the error selector to use on failure rather than performing MNU processing etc."
	| currentClass dictionary found |
	<inline: false>
	self lookupBreakFor: class.
	currentClass := class.
	[currentClass ~= objectMemory nilObject] whileTrue:
		[dictionary := objectMemory followObjField: MethodDictionaryIndex ofObject: currentClass.
		 dictionary = objectMemory nilObject ifTrue:
			[lkupClass := self superclassOf: currentClass.
			 ^SelectorCannotInterpret].
		found := self lookupMethodInDictionary: dictionary.
		found ifTrue: [self addNewMethodToCache: class. ^0].
		currentClass := self superclassOf: currentClass].
	lkupClass := class.
	^SelectorDoesNotUnderstand
]

{ #category : #'message sending' }
StackInterpreter >> lookupMethodFor: selector InDictionary: dictionary [
	"Lookup the argument selector in aDictionary and answer either the
	 method or nil, if not found.
	This method lookup tolerates integers as Dictionary keys to support
	 execution of images in which Symbols have been compacted out."
	| length index mask wrapAround nextSelector methodArray |
	<inline: true>
	length := objectMemory numSlotsOf: dictionary.
	mask := length - SelectorStart - 1.
	index := SelectorStart + (objectMemory methodDictionaryHash: selector mask: mask).

	"It is assumed that there are some nils in this dictionary, and search will 
	 stop when one is encountered. However, if there are no nils, then wrapAround 
	 will be detected the second time the loop gets to the end of the table."
	wrapAround := false.
	[true] whileTrue:
		[nextSelector := objectMemory fetchPointer: index ofObject: dictionary.
		 nextSelector = objectMemory nilObject ifTrue:
			[^nil].
		 (objectMemory isOopForwarded: nextSelector) ifTrue:
			[nextSelector := objectMemory
								fixFollowedField: index + SelectorStart
								ofObject: dictionary
								withInitialValue: nextSelector].
		 nextSelector = selector ifTrue:
			[methodArray := objectMemory followObjField: MethodArrayIndex ofObject: dictionary.
			 ^objectMemory followField: index - SelectorStart ofObject: methodArray].
		 index := index + 1.
		 index = length ifTrue:
			[wrapAround ifTrue: [^nil].
			 wrapAround := true.
			 index := SelectorStart]].
	^nil "for Slang"
]

{ #category : #'message sending' }
StackInterpreter >> lookupMethodInClass: class [
	| currentClass dictionary found |
	<inline: false>
	self assert: (self addressCouldBeClassObj: class).
	self lookupBreakFor: class.
	currentClass := class.
	[currentClass ~= objectMemory nilObject] whileTrue:
		[dictionary := objectMemory followObjField: MethodDictionaryIndex ofObject: currentClass.
		dictionary = objectMemory nilObject ifTrue:
			["MethodDict pointer is nil (hopefully due a swapped out stub)
				-- raise exception #cannotInterpret:."
			self createActualMessageTo: class.
			messageSelector := objectMemory splObj: SelectorCannotInterpret.
			self sendBreakpoint: messageSelector receiver: nil.
			^self lookupMethodInClass: (self superclassOf: currentClass)].
		found := self lookupMethodInDictionary: dictionary.
		found ifTrue: [^currentClass].
		currentClass := self superclassOf: currentClass].

	"Could not find #doesNotUnderstand: -- unrecoverable error."
	messageSelector = (objectMemory splObj: SelectorDoesNotUnderstand) ifTrue:
		[self error: 'Recursive not understood error encountered'].

	"Cound not find a normal message -- raise exception #doesNotUnderstand:"
	self createActualMessageTo: class.
	messageSelector := objectMemory splObj: SelectorDoesNotUnderstand.
	self sendBreak: messageSelector + objectMemory baseHeaderSize
		point: (objectMemory lengthOf: messageSelector)
		receiver: nil.
	^self lookupMethodInClass: class
]

{ #category : #'message sending' }
StackInterpreter >> lookupMethodInDictionary: dictionary [ 
	"This method lookup tolerates integers as Dictionary keys to support
	 execution of images in which Symbols have been compacted out."
	| length index mask wrapAround nextSelector methodArray |
	<inline: true>
	length := objectMemory numSlotsOf: dictionary.
	mask := length - SelectorStart - 1.
	"Use linear search on small dictionaries; its cheaper.
	 Also the limit can be set to force linear search of all dictionaries, which supports the
	 booting of images that need rehashing (e.g. because a tracer has generated an image
	 with different hashes but hasn't rehashed it yet.)"
	mask <= methodDictLinearSearchLimit ifTrue:
		[index := 0.
		 [index <= mask] whileTrue:
			[nextSelector := objectMemory fetchPointer: index + SelectorStart ofObject: dictionary.
			 (objectMemory isOopForwarded: nextSelector) ifTrue:
				[nextSelector := objectMemory
									fixFollowedField: index + SelectorStart
									ofObject: dictionary
									withInitialValue: nextSelector].
			 nextSelector = messageSelector ifTrue:
				[methodArray := objectMemory followObjField: MethodArrayIndex ofObject: dictionary.
				 newMethod := objectMemory followField: index ofObject: methodArray.
				^true].
		 index := index + 1].
		 ^false].
	index := SelectorStart + (objectMemory methodDictionaryHash: messageSelector mask: mask).

	"It is assumed that there are some nils in this dictionary, and search will 
	 stop when one is encountered. However, if there are no nils, then wrapAround 
	 will be detected the second time the loop gets to the end of the table."
	wrapAround := false.
	[true] whileTrue:
		[nextSelector := objectMemory fetchPointer: index ofObject: dictionary.
		 nextSelector = objectMemory nilObject ifTrue: [^false].
		 (objectMemory isOopForwarded: nextSelector) ifTrue:
			[nextSelector := objectMemory
								fixFollowedField: index + SelectorStart
								ofObject: dictionary
								withInitialValue: nextSelector].
		 nextSelector = messageSelector ifTrue:
			[methodArray := objectMemory followObjField: MethodArrayIndex ofObject: dictionary.
			 newMethod := objectMemory followField: index - SelectorStart ofObject: methodArray.
			^true].
		 index := index + 1.
		 index = length ifTrue:
			[wrapAround ifTrue: [^false].
			 wrapAround := true.
			 index := SelectorStart]].
	
	^false "for Slang"
]

{ #category : #'message sending' }
StackInterpreter >> lookupOrdinaryNoMNUEtcInClass: class [
	"Lookup messageSelector in class.  Answer 0 on success. Answer the splObj: index
	 for the error selector to use on failure rather than performing MNU processing etc."
	| currentClass dictionary found |
	<inline: false>
	self lookupBreakFor: class.
	currentClass := class.
	[currentClass ~= objectMemory nilObject] whileTrue:
		[dictionary := objectMemory followObjField: MethodDictionaryIndex ofObject: currentClass.
		 dictionary = objectMemory nilObject ifTrue:
			[lkupClass := self superclassOf: currentClass.
			 ^SelectorCannotInterpret].
		found := self lookupMethodInDictionary: dictionary.
		found ifTrue: [self addNewMethodToCache: class. ^0].
		currentClass := self superclassOf: currentClass].
	lkupClass := class.
	^SelectorDoesNotUnderstand
]

{ #category : #'debug support' }
StackInterpreter >> lookupSelector: selector inClass: class [
	"Lookup selector in class.  Answer the method or nil.  This is a debugging routine.
	 It does /not/ side-effect lookupClass or newMethod."
	| currentClass dictionary |
	<api>

	currentClass := class.
	[currentClass ~= objectMemory nilObject] whileTrue:
		[dictionary := objectMemory followObjField: MethodDictionaryIndex ofObject: currentClass.
		 dictionary = objectMemory nilObject ifTrue:
			[^nil].
		 (self lookupMethodFor: selector InDictionary: dictionary) ifNotNil:
			[:meth| ^meth].
		currentClass := self superclassOf: currentClass].
	^nil
]

{ #category : #'inline primitive dispatch generated code' }
StackInterpreter >> lowcodeBinaryInlinePrimitive: prim [
	<option: #LowcodeVM>	"Lowcode instruction interpreter dispatch"
	prim
		caseOf: {
			[0]	-> [ ^ self lowcodePrimitiveByteSizeOf ].
			[1]	-> [ ^ self lowcodePrimitiveFirstFieldPointer ].
			[2]	-> [ ^ self lowcodePrimitiveFirstIndexableFieldPointer ].
			[3]	-> [ ^ self lowcodePrimitiveIsBytes ].
			[4]	-> [ ^ self lowcodePrimitiveIsFloatObject ].
			[5]	-> [ ^ self lowcodePrimitiveIsIndexable ].
			[6]	-> [ ^ self lowcodePrimitiveIsIntegerObject ].
			[7]	-> [ ^ self lowcodePrimitiveIsPointers ].
			[8]	-> [ ^ self lowcodePrimitiveIsWords ].
			[9]	-> [ ^ self lowcodePrimitiveIsWordsOrBytes ].
			[10]	-> [ ^ self lowcodePrimitiveOopSmallIntegerToInt32 ].
			[11]	-> [ ^ self lowcodePrimitiveOopSmallIntegerToInt64 ].
			[12]	-> [ ^ self lowcodePrimitiveOopToBoolean32 ].
			[13]	-> [ ^ self lowcodePrimitiveOopToBoolean64 ].
			[14]	-> [ ^ self lowcodePrimitiveOopToFloat32 ].
			[15]	-> [ ^ self lowcodePrimitiveOopToFloat64 ].
			[16]	-> [ ^ self lowcodePrimitiveOopToInt32 ].
			[17]	-> [ ^ self lowcodePrimitiveOopToInt64 ].
			[18]	-> [ ^ self lowcodePrimitiveOopToPointer ].
			[19]	-> [ ^ self lowcodePrimitiveOopToPointerReinterpret ].
			[20]	-> [ ^ self lowcodePrimitiveOopToUInt32 ].
			[21]	-> [ ^ self lowcodePrimitiveOopToUInt64 ].
			[22]	-> [ ^ self lowcodePrimitivePin ].
			[23]	-> [ ^ self lowcodePrimitiveUnpin ].
		}
		otherwise: [
			localIP := localIP - 3.
			^self respondToUnknownBytecode
		].
	


]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutState: calloutState callFunction: functionPointer [
	<option: #LowcodeVM>
	self lowcodeCalloutState: calloutState stackPointer: shadowCallStackPointer stackSize: (self cCoerce: lowcodeCalloutState to: #'char*') - shadowCallStackPointer callFunction: functionPointer

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutState: calloutState float32Register: registerId [
	"This is implemented as C macros in platform specific headers"
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutState: calloutState float32Register: registerId value: value [
	"This is implemented as C macros in platform specific headers"
	<var: #value type: #'float' >
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutState: calloutState float64Register: registerId [
	"This is implemented as C macros in platform specific headers"
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutState: calloutState float64Register: registerId value: value [
	"This is implemented as C macros in platform specific headers"
	<var: #value type: #'double' >
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutState: calloutState int32Register: registerId [
	"This is implemented as C macros in platform specific headers"
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutState: calloutState int32Register: registerId value: value [
	"This is implemented as C macros in platform specific headers"
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutState: calloutState int64Register: registerId [
	"This is implemented as C macros in platform specific headers"
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutState: calloutState int64Register: registerId value: value [
	"This is implemented as C macros in platform specific headers"
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutState: calloutState pointerRegister: registerId [
	"This is implemented as C macros in platform specific headers"
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutState: calloutState pointerRegister: registerId value: value [
	"This is implemented as C macros in platform specific headers"
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutState: calloutState stackPointer: calloutStackPointer stackSize: calloutStackSize callFunction: functionPointer [
	"This is implemented as C macros in platform specific headers"
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutStateFetchResultFloat32: calloutState [
	"This is implemented as C macros in platform specific headers"
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutStateFetchResultFloat64: calloutState [
	"This is implemented as C macros in platform specific headers"
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutStateFetchResultInt32: calloutState [
	"This is implemented as C macros in platform specific headers"
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutStateFetchResultInt64: calloutState [
	"This is implemented as C macros in platform specific headers"
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutStateFetchResultPointer: calloutState [
	"This is implemented as C macros in platform specific headers"
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeCalloutStateFetchResultStructure: calloutState [
	"This is implemented as C macros in platform specific headers"
	<doNotGenerate>

]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> lowcodeDoCallout: functionPointer [
	<option: #LowcodeVM>
	<var: #functionPointer type: #'char*' >
	self undoFetchNextBytecode.
	self externalizeIPandSP.
	self lowcodeCalloutState: lowcodeCalloutState callFunction: functionPointer.
	self internalizeIPandSP.
	self reloadLowcodeStateAfterCallout.
	self fetchNextBytecode.
	^ self lowcodeCalloutStateFetchResultFloat32: lowcodeCalloutState
]

{ #category : #'inline primitive dispatch generated code' }
StackInterpreter >> lowcodeNullaryInlinePrimitive: prim [
	<option: #LowcodeVM>	"Lowcode instruction interpreter dispatch"
	prim
		caseOf: {
			[0]	-> [ ^ self lowcodePrimitiveBoolean32ToOop ].
			[1]	-> [ ^ self lowcodePrimitiveBoolean64ToOop ].
			[2]	-> [ ^ self lowcodePrimitiveFloat32ToOop ].
			[3]	-> [ ^ self lowcodePrimitiveFloat64ToOop ].
			[4]	-> [ ^ self lowcodePrimitiveInt32ToOop ].
			[5]	-> [ ^ self lowcodePrimitiveInt64ToOop ].
			[6]	-> [ ^ self lowcodePrimitivePointerToOop ].
			[7]	-> [ ^ self lowcodePrimitivePointerToOopReinterprer ].
			[8]	-> [ ^ self lowcodePrimitiveSmallInt32ToOop ].
			[9]	-> [ ^ self lowcodePrimitiveUint32ToOop ].
			[10]	-> [ ^ self lowcodePrimitiveUint64ToOop ].
		}
		otherwise: [
			localIP := localIP - 3.
			^self respondToUnknownBytecode
		].
	


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveAdd32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqInt' >
	<var: #result type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	result := first + second.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveAdd64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqLong' >
	<var: #result type: #'sqLong' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	result := first + second.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveAlloca32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer size |
	<var: #pointer type: #'char*' >
	<var: #size type: #'sqInt' >
	size := self internalPopStackInt32.

	nativeStackPointer := self cCoerce:
	((self cCoerce: nativeStackPointer - size to: 'size_t') bitAnd: -16)
	to: 'char*'.
	pointer := nativeStackPointer.

	self internalPushPointer: pointer.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveAlloca64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer size |
	<var: #pointer type: #'char*' >
	<var: #size type: #'sqLong' >
	size := self internalPopStackInt64.

	nativeStackPointer := nativeStackPointer - size.
	pointer := nativeStackPointer.

	self internalPushPointer: pointer.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveAnd32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqInt' >
	<var: #result type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	result := first bitAnd: second.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveAnd64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqLong' >
	<var: #result type: #'sqLong' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	result := first bitAnd: second.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveArithmeticRightShift32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value shiftAmount result |
	<var: #value type: #'sqInt' >
	<var: #shiftAmount type: #'sqInt' >
	<var: #result type: #'sqInt' >
	shiftAmount := self internalPopStackInt32.
	value := self internalPopStackInt32.

	result := value >> shiftAmount.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveArithmeticRightShift64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value shiftAmount result |
	<var: #value type: #'sqLong' >
	<var: #shiftAmount type: #'sqLong' >
	<var: #result type: #'sqLong' >
	shiftAmount := self internalPopStackInt64.
	value := self internalPopStackInt64.

	result := value >> shiftAmount.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveBeginCall [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| alignment |
	alignment := extA.

	"Store the shadow stack pointer"
	self shadowCallStackPointerIn: localFP put: shadowCallStackPointer + 1.
	"Allocate the callout state"
	self allocateLowcodeCalloutState.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveBoolean32ToOop [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	value := self internalPopStackInt32.

	object := value ~= 0 ifTrue: [ objectMemory trueObject ] ifFalse: [objectMemory falseObject].

	self internalPush: object.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveBoolean64ToOop [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqLong' >
	value := self internalPopStackInt64.

	object := value ~= 0 ifTrue: [ objectMemory trueObject ] ifFalse: [objectMemory falseObject].

	self internalPush: object.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveByteSizeOf [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	object := self internalPopStack.

	value := self byteSizeOf: object.

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveCallArgumentFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| argumentValue |
	<var: #argumentValue type: #'float' >
	argumentValue := self internalPopStackFloat32.

	self internalPushShadowCallStackFloat32: argumentValue.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveCallArgumentFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| argumentValue |
	<var: #argumentValue type: #'double' >
	argumentValue := self internalPopStackFloat64.

	self internalPushShadowCallStackFloat64: argumentValue.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveCallArgumentInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value |
	<var: #value type: #'sqInt' >
	value := self internalPopStackInt32.

	self internalPushShadowCallStackInt32: value.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveCallArgumentInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value |
	<var: #value type: #'sqLong' >
	value := self internalPopStackInt64.

	self internalPushShadowCallStackInt64: value.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveCallArgumentPointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointerValue |
	<var: #pointerValue type: #'char*' >
	pointerValue := self internalPopStackPointer.

	self internalPushShadowCallStackPointer: pointerValue.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveCallArgumentSpace [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| spaceSize |
	spaceSize := extA.

	self internalPushShadowCallStackSpace: spaceSize.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveCallArgumentStructure [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| structurePointer structureSize |
	<var: #structurePointer type: #'char*' >
	structureSize := extA.
	structurePointer := self internalPopStackPointer.

	self internalPushShadowCallStackStructure: structurePointer size: structureSize.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveCallInstruction [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| function |
	function := extA.

	self abort.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveCallPhysical [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| registerID |
	registerID := extA.

	self abort.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveCheckSessionIdentifier [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| expectedSession value |
	<var: #value type: #'sqInt' >
	expectedSession := extA.

	value := (expectedSession = self getThisSessionID) ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveCompareAndSwap32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| newValue check oldValue value |
	<var: #newValue type: #'sqInt' >
	<var: #check type: #'char*' >
	<var: #oldValue type: #'sqInt' >
	<var: #value type: #'sqInt' >
	newValue := self internalPopStackInt32.
	oldValue := self internalPopStackInt32.
	check := self internalPopStackPointer.

	self abort.

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveDiv32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqInt' >
	<var: #result type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	result := first // second.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveDiv64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqLong' >
	<var: #result type: #'sqLong' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	result := first // second.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveDuplicateFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value dup1 dup2 |
	<var: #value type: #'float' >
	<var: #dup1 type: #'float' >
	<var: #dup2 type: #'float' >
	value := self internalPopStackFloat32.

	dup1 := value.
	dup2 := value.

	self internalPushFloat32: dup1.
	self internalPushFloat32: dup2.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveDuplicateFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value dup1 dup2 |
	<var: #value type: #'double' >
	<var: #dup1 type: #'double' >
	<var: #dup2 type: #'double' >
	value := self internalPopStackFloat64.

	dup1 := value.
	dup2 := value.

	self internalPushFloat64: dup1.
	self internalPushFloat64: dup2.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveDuplicateInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value dup1 dup2 |
	<var: #value type: #'sqInt' >
	<var: #dup1 type: #'sqInt' >
	<var: #dup2 type: #'sqInt' >
	value := self internalPopStackInt32.

	dup1 := value.
	dup2 := value.

	self internalPushInt32: dup1.
	self internalPushInt32: dup2.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveDuplicateInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value dup1 dup2 |
	<var: #value type: #'sqLong' >
	<var: #dup1 type: #'sqLong' >
	<var: #dup2 type: #'sqLong' >
	value := self internalPopStackInt64.

	dup1 := value.
	dup2 := value.

	self internalPushInt64: dup1.
	self internalPushInt64: dup2.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveDuplicatePointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| dup2 dup1 pointerValue |
	<var: #dup2 type: #'char*' >
	<var: #dup1 type: #'char*' >
	<var: #pointerValue type: #'char*' >
	pointerValue := self internalPopStackPointer.

	dup1 := pointerValue.
	dup2 := pointerValue.

	self internalPushPointer: dup1.
	self internalPushPointer: dup2.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveEffectiveAddress32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result offset base scale index |
	<var: #result type: #'char*' >
	<var: #offset type: #'sqInt' >
	<var: #base type: #'char*' >
	<var: #scale type: #'sqInt' >
	<var: #index type: #'sqInt' >
	offset := self internalPopStackInt32.
	scale := self internalPopStackInt32.
	index := self internalPopStackInt32.
	base := self internalPopStackPointer.

	result := base + (index*scale) + offset.

	self internalPushPointer: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveEffectiveAddress64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result offset base scale index |
	<var: #result type: #'char*' >
	<var: #offset type: #'sqLong' >
	<var: #base type: #'char*' >
	<var: #scale type: #'sqLong' >
	<var: #index type: #'sqLong' >
	offset := self internalPopStackInt64.
	scale := self internalPopStackInt64.
	index := self internalPopStackInt64.
	base := self internalPopStackPointer.

	result := base + (index*scale) + offset.

	self internalPushPointer: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveEndCall [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	"Restore the shadow stack pointer"
	shadowCallStackPointer := (self shadowCallStackPointerIn: localFP) - 1.
	self shadowCallStackPointerIn: localFP put: (self cCoerce: 1 to: #'char*').



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveEndCallNoCleanup [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	"Restore the shadow stack pointer"
	shadowCallStackPointer := (self shadowCallStackPointerIn: localFP) - 1.
	self shadowCallStackPointerIn: localFP put: (self cCoerce: 1 to: #'char*').



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFirstFieldPointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object pointer |
	<var: #object type: #'sqInt' >
	<var: #pointer type: #'char*' >
	object := self internalPopStack.

	pointer := objectMemory firstFixedField: object.

	self internalPushPointer: pointer.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFirstIndexableFieldPointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object pointer |
	<var: #object type: #'sqInt' >
	<var: #pointer type: #'char*' >
	object := self internalPopStack.

	pointer := objectMemory firstIndexableField: object.

	self internalPushPointer: pointer.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32Add [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'float' >
	<var: #result type: #'float' >
	<var: #first type: #'float' >
	second := self internalPopStackFloat32.
	first := self internalPopStackFloat32.

	result := first + second.

	self internalPushFloat32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32Div [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'float' >
	<var: #result type: #'float' >
	<var: #first type: #'float' >
	second := self internalPopStackFloat32.
	first := self internalPopStackFloat32.

	result := first / second.

	self internalPushFloat32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32Equal [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'float' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'float' >
	second := self internalPopStackFloat32.
	first := self internalPopStackFloat32.

	value := first = second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32Great [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'float' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'float' >
	second := self internalPopStackFloat32.
	first := self internalPopStackFloat32.

	value := first > second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32GreatEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'float' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'float' >
	second := self internalPopStackFloat32.
	first := self internalPopStackFloat32.

	value := first >= second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32Less [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'float' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'float' >
	second := self internalPopStackFloat32.
	first := self internalPopStackFloat32.

	value := first < second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32LessEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'float' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'float' >
	second := self internalPopStackFloat32.
	first := self internalPopStackFloat32.

	value := first <= second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32Mul [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'float' >
	<var: #result type: #'float' >
	<var: #first type: #'float' >
	second := self internalPopStackFloat32.
	first := self internalPopStackFloat32.

	result := first * second.

	self internalPushFloat32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32Neg [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'float' >
	<var: #result type: #'float' >
	value := self internalPopStackFloat32.

	result := value negated.

	self internalPushFloat32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32NotEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'float' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'float' >
	second := self internalPopStackFloat32.
	first := self internalPopStackFloat32.

	value := first ~= second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32Sqrt [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'float' >
	<var: #result type: #'float' >
	value := self internalPopStackFloat32.

	result := self sqrt: value.

	self internalPushFloat32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32Sub [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'float' >
	<var: #result type: #'float' >
	<var: #first type: #'float' >
	second := self internalPopStackFloat32.
	first := self internalPopStackFloat32.

	result := first - second.

	self internalPushFloat32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32ToFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| singleFloatValue doubleResult |
	<var: #singleFloatValue type: #'float' >
	<var: #doubleResult type: #'double' >
	singleFloatValue := self internalPopStackFloat32.

	doubleResult := self cCoerce: singleFloatValue to: 'double'.

	self internalPushFloat64: doubleResult.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32ToInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'float' >
	<var: #result type: #'sqInt' >
	value := self internalPopStackFloat32.

	result := self cCoerce: value to: 'sqInt'.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32ToInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'float' >
	<var: #result type: #'sqLong' >
	value := self internalPopStackFloat32.

	result := self cCoerce: value to: 'sqLong'.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32ToOop [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| singleFloatValue object |
	<var: #singleFloatValue type: #'float' >
	<var: #object type: #'sqInt' >
	singleFloatValue := self internalPopStackFloat32.

	object := objectMemory floatObjectOf: singleFloatValue.

	self internalPush: object.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32ToUInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'float' >
	<var: #result type: #'sqInt' >
	value := self internalPopStackFloat32.

	result := self cCoerce: value to: 'uint32_t'.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat32ToUInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'float' >
	<var: #result type: #'sqLong' >
	value := self internalPopStackFloat32.

	result := self cCoerce: value to: 'uint64_t'.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64Add [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'double' >
	<var: #result type: #'double' >
	<var: #first type: #'double' >
	second := self internalPopStackFloat64.
	first := self internalPopStackFloat64.

	result := first + second.

	self internalPushFloat64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64Div [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'double' >
	<var: #result type: #'double' >
	<var: #first type: #'double' >
	second := self internalPopStackFloat64.
	first := self internalPopStackFloat64.

	result := first / second.

	self internalPushFloat64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64Equal [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'double' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'double' >
	second := self internalPopStackFloat64.
	first := self internalPopStackFloat64.

	value := first = second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64Great [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'double' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'double' >
	second := self internalPopStackFloat64.
	first := self internalPopStackFloat64.

	value := first > second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64GreatEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'double' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'double' >
	second := self internalPopStackFloat64.
	first := self internalPopStackFloat64.

	value := first >= second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64Less [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'double' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'double' >
	second := self internalPopStackFloat64.
	first := self internalPopStackFloat64.

	value := first < second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64LessEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'double' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'double' >
	second := self internalPopStackFloat64.
	first := self internalPopStackFloat64.

	value := first <= second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64Mul [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'double' >
	<var: #result type: #'double' >
	<var: #first type: #'double' >
	second := self internalPopStackFloat64.
	first := self internalPopStackFloat64.

	result := first * second.

	self internalPushFloat64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64Neg [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'double' >
	<var: #result type: #'double' >
	value := self internalPopStackFloat64.

	result := value negated.

	self internalPushFloat64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64NotEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'double' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'double' >
	second := self internalPopStackFloat64.
	first := self internalPopStackFloat64.

	value := first ~= second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64Sqrt [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'double' >
	<var: #result type: #'double' >
	value := self internalPopStackFloat64.

	result := self sqrt: value.

	self internalPushFloat64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64Sub [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'double' >
	<var: #result type: #'double' >
	<var: #first type: #'double' >
	second := self internalPopStackFloat64.
	first := self internalPopStackFloat64.

	result := first - second.

	self internalPushFloat64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64ToFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| floatValue singleFloatResult |
	<var: #floatValue type: #'double' >
	<var: #singleFloatResult type: #'float' >
	floatValue := self internalPopStackFloat64.

	singleFloatResult := self cCoerce: floatValue to: 'float'.

	self internalPushFloat32: singleFloatResult.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64ToInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| floatValue int32Result |
	<var: #floatValue type: #'double' >
	<var: #int32Result type: #'sqInt' >
	floatValue := self internalPopStackFloat64.

	int32Result := self cCoerce: floatValue to: 'sqInt'.

	self internalPushInt32: int32Result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64ToInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| floatValue int64Result |
	<var: #floatValue type: #'double' >
	<var: #int64Result type: #'sqLong' >
	floatValue := self internalPopStackFloat64.

	int64Result := self cCoerce: floatValue to: 'sqLong'.

	self internalPushInt64: int64Result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64ToOop [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| floatValue object |
	<var: #floatValue type: #'double' >
	<var: #object type: #'sqInt' >
	floatValue := self internalPopStackFloat64.

	object := objectMemory floatObjectOf: floatValue.

	self internalPush: object.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64ToUInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| floatValue int64Result |
	<var: #floatValue type: #'double' >
	<var: #int64Result type: #'sqInt' >
	floatValue := self internalPopStackFloat64.

	int64Result := self cCoerce: floatValue to: 'uint32_t'.

	self internalPushInt32: int64Result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFloat64ToUInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| floatValue int64Result |
	<var: #floatValue type: #'double' >
	<var: #int64Result type: #'sqLong' >
	floatValue := self internalPopStackFloat64.

	int64Result := self cCoerce: floatValue to: 'uint64_t'.

	self internalPushInt64: int64Result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveFree [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer |
	<var: #pointer type: #'char*' >
	pointer := self internalPopStackPointer.

	self free: pointer.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInstantiateIndexable32Oop [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| indexableSize object classOop |
	<var: #indexableSize type: #'sqInt' >
	<var: #object type: #'sqInt' >
	<var: #classOop type: #'sqInt' >
	indexableSize := self internalPopStackInt32.
	classOop := self internalPopStack.

	object := objectMemory instantiateClass: classOop indexableSize: indexableSize.

	self internalPush: object.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInstantiateIndexableOop [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| indexableSize object classOop |
	<var: #object type: #'sqInt' >
	<var: #classOop type: #'sqInt' >
	indexableSize := extA.
	classOop := self internalPopStack.

	object := objectMemory instantiateClass: classOop indexableSize: indexableSize.

	self internalPush: object.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInstantiateOop [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object classOop |
	<var: #object type: #'sqInt' >
	<var: #classOop type: #'sqInt' >
	classOop := self internalPopStack.

	object := objectMemory instantiateClass: classOop indexableSize: 0.

	self internalPush: object.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt32Equal [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqInt' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	value := first = second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt32Great [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqInt' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	value := first > second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt32GreatEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqInt' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	value := first >= second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt32Less [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqInt' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	value := first < second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt32LessEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqInt' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	value := first <= second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt32NotEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqInt' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	value := first ~= second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt32ToFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqInt' >
	<var: #result type: #'float' >
	value := self internalPopStackInt32.

	result := self cCoerce: value to: 'float'.

	self internalPushFloat32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt32ToFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqInt' >
	<var: #result type: #'double' >
	value := self internalPopStackInt32.

	result := self cCoerce: value to: 'double'.

	self internalPushFloat64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt32ToOop [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	value := self internalPopStackInt32.

	object := objectMemory signed32BitIntegerFor: value.

	self internalPush: object.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt32ToPointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqInt' >
	<var: #result type: #'char*' >
	value := self internalPopStackInt32.

	result := self cCoerce: (self cCoerce: value to: 'uintptr_t') to: 'char*'.

	self internalPushPointer: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt64Equal [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqLong' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	value := first = second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt64Great [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqLong' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	value := first > second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt64GreatEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqLong' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	value := first >= second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt64Less [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqLong' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	value := first < second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt64LessEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqLong' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	value := first <= second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt64NotEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqLong' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	value := first ~= second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt64ToFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqLong' >
	<var: #result type: #'double' >
	value := self internalPopStackInt64.

	result := self cCoerce: value to: 'float'.

	self internalPushFloat64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt64ToFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqLong' >
	<var: #result type: #'double' >
	value := self internalPopStackInt64.

	result := self cCoerce: value to: 'double'.

	self internalPushFloat64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt64ToOop [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqLong' >
	value := self internalPopStackInt64.

	object := objectMemory signed64BitIntegerFor: value.

	self internalPush: object.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveInt64ToPointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqLong' >
	<var: #result type: #'char*' >
	value := self internalPopStackInt64.

	result := self cCoerce:
	(self cCoerce: value to: 'intptr_t')
	to: 'char*'.

	self internalPushPointer: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveIsBytes [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	object := self internalPopStack.

	value := (objectMemory isBytes: object) ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveIsFloatObject [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	object := self internalPopStack.

	value := (objectMemory isFloatObject: object) ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveIsIndexable [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	object := self internalPopStack.

	value := (objectMemory isIndexable: object) ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveIsIntegerObject [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	object := self internalPopStack.

	value := (objectMemory isIntegerObject: object) ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveIsPointers [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	object := self internalPopStack.

	value := (objectMemory isPointers: object) ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveIsWords [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	object := self internalPopStack.

	value := (objectMemory isWords: object) ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveIsWordsOrBytes [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	object := self internalPopStack.

	value := (objectMemory isWordsOrBytes: object) ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLeftShift32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value shiftAmount result |
	<var: #value type: #'sqInt' >
	<var: #shiftAmount type: #'sqInt' >
	<var: #result type: #'sqInt' >
	shiftAmount := self internalPopStackInt32.
	value := self internalPopStackInt32.

	result := value << shiftAmount.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLeftShift64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value shiftAmount result |
	<var: #value type: #'sqLong' >
	<var: #shiftAmount type: #'sqLong' >
	<var: #result type: #'sqLong' >
	shiftAmount := self internalPopStackInt64.
	value := self internalPopStackInt64.

	result := value << shiftAmount.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadArgumentAddress [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer baseOffset |
	<var: #pointer type: #'char*' >
	baseOffset := extA.

	pointer := self framePointerOfNativeArgument: baseOffset in: localFP.

	self internalPushPointer: pointer.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadArgumentFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| floatValue baseOffset |
	<var: #floatValue type: #'float' >
	baseOffset := extA.

	floatValue := stackPages singleFloatAtPointer: (self framePointerOfNativeArgument: baseOffset in: localFP).

	self internalPushFloat32: floatValue.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadArgumentFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| doubleValue baseOffset |
	<var: #doubleValue type: #'double' >
	baseOffset := extA.

	doubleValue := stackPages floatAtPointer: (self framePointerOfNativeArgument: baseOffset in: localFP).

	self internalPushFloat64: doubleValue.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadArgumentInt16 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqInt' >
	baseOffset := extA.

	value := stackPages int16AtPointer: (self framePointerOfNativeArgument: baseOffset in: localFP).

	self internalPushInt32: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadArgumentInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqInt' >
	baseOffset := extA.

	value := stackPages int32AtPointer: (self framePointerOfNativeArgument: baseOffset in: localFP).

	self internalPushInt32: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadArgumentInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqLong' >
	baseOffset := extA.

	value := stackPages int64AtPointer: (self framePointerOfNativeArgument: baseOffset in: localFP).

	self internalPushInt64: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadArgumentInt8 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqInt' >
	baseOffset := extA.

	value := stackPages int8AtPointer: (self framePointerOfNativeArgument: baseOffset in: localFP).

	self internalPushInt32: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadArgumentPointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointerResult baseOffset |
	<var: #pointerResult type: #'char*' >
	baseOffset := extA.

	pointerResult := stackPages pointerAtPointer: (self framePointerOfNativeArgument: baseOffset in: localFP).

	self internalPushPointer: pointerResult.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadArgumentUInt16 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqInt' >
	baseOffset := extA.

	value := stackPages uint16AtPointer: (self framePointerOfNativeArgument: baseOffset in: localFP).

	self internalPushInt32: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadArgumentUInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqInt' >
	baseOffset := extA.

	value := stackPages uint32AtPointer: (self framePointerOfNativeArgument: baseOffset in: localFP).

	self internalPushInt32: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadArgumentUInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqLong' >
	baseOffset := extA.

	value := stackPages uint64AtPointer: (self framePointerOfNativeArgument: baseOffset in: localFP).

	self internalPushInt64: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadArgumentUInt8 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqInt' >
	baseOffset := extA.

	value := stackPages uint8AtPointer: (self framePointerOfNativeArgument: baseOffset in: localFP).

	self internalPushInt32: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadFloat32FromMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer value |
	<var: #pointer type: #'char*' >
	<var: #value type: #'float' >
	pointer := self internalPopStackPointer.

	value := self singleFloatAtPointer: pointer.

	self internalPushFloat32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadFloat64FromMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer value |
	<var: #pointer type: #'char*' >
	<var: #value type: #'double' >
	pointer := self internalPopStackPointer.

	value := self floatAtPointer: pointer.

	self internalPushFloat64: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadInt16FromMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer value |
	<var: #pointer type: #'char*' >
	<var: #value type: #'sqInt' >
	pointer := self internalPopStackPointer.

	value := self int16AtPointer: pointer.

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadInt32FromMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer value |
	<var: #pointer type: #'char*' >
	<var: #value type: #'sqInt' >
	pointer := self internalPopStackPointer.

	value := self int32AtPointer: pointer.

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadInt64FromMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer value |
	<var: #pointer type: #'char*' >
	<var: #value type: #'sqLong' >
	pointer := self internalPopStackPointer.

	value := self int64AtPointer: pointer.

	self internalPushInt64: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadInt8FromMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer value |
	<var: #pointer type: #'char*' >
	<var: #value type: #'sqInt' >
	pointer := self internalPopStackPointer.

	value := self int8AtPointer: pointer.

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadLocalAddress [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer baseOffset |
	<var: #pointer type: #'char*' >
	baseOffset := extA.

	pointer := self framePointerOfNativeLocal: baseOffset in: localFP.

	self internalPushPointer: pointer.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadLocalFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| floatValue baseOffset |
	<var: #floatValue type: #'float' >
	baseOffset := extA.

	floatValue := stackPages singleFloatAtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP).

	self internalPushFloat32: floatValue.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadLocalFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| doubleValue baseOffset |
	<var: #doubleValue type: #'double' >
	baseOffset := extA.

	doubleValue := stackPages floatAtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP).

	self internalPushFloat64: doubleValue.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadLocalInt16 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqInt' >
	baseOffset := extA.

	value := stackPages int16AtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP).

	self internalPushInt32: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadLocalInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqInt' >
	baseOffset := extA.

	value := stackPages int32AtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP).

	self internalPushInt32: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadLocalInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqLong' >
	baseOffset := extA.

	value := stackPages int64AtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP).

	self internalPushInt64: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadLocalInt8 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqInt' >
	baseOffset := extA.

	value := stackPages int8AtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP).

	self internalPushInt32: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadLocalPointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointerResult baseOffset |
	<var: #pointerResult type: #'char*' >
	baseOffset := extA.

	pointerResult := stackPages pointerAtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP).

	self internalPushPointer: pointerResult.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadLocalUInt16 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqInt' >
	baseOffset := extA.

	value := stackPages uint16AtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP).

	self internalPushInt32: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadLocalUInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqInt' >
	baseOffset := extA.

	value := stackPages uint32AtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP).

	self internalPushInt32: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadLocalUInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqLong' >
	baseOffset := extA.

	value := stackPages uint64AtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP).

	self internalPushInt64: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadLocalUInt8 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqInt' >
	baseOffset := extA.

	value := stackPages uint8AtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP).

	self internalPushInt32: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadObjectAt [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| fieldIndex object fieldValue |
	<var: #fieldIndex type: #'sqInt' >
	<var: #object type: #'sqInt' >
	<var: #fieldValue type: #'sqInt' >
	fieldIndex := self internalPopStackInt32.
	object := self internalPopStack.

	fieldValue := objectMemory fetchPointer: fieldIndex ofObject: object.

	self internalPush: fieldValue.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadObjectField [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| fieldIndex object fieldValue |
	<var: #object type: #'sqInt' >
	<var: #fieldValue type: #'sqInt' >
	fieldIndex := extA.
	object := self internalPopStack.

	fieldValue := self fetchPointer: fieldIndex ofObject: object.

	self internalPush: fieldValue.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadPointerFromMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointerResult pointer |
	<var: #pointerResult type: #'char*' >
	<var: #pointer type: #'char*' >
	pointer := self internalPopStackPointer.

	pointerResult := self pointerAtPointer: pointer.

	self internalPushPointer: pointerResult.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadUInt16FromMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer value |
	<var: #pointer type: #'char*' >
	<var: #value type: #'sqInt' >
	pointer := self internalPopStackPointer.

	value := self uint16AtPointer: pointer.

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadUInt32FromMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer value |
	<var: #pointer type: #'char*' >
	<var: #value type: #'sqInt' >
	pointer := self internalPopStackPointer.

	value := self uint32AtPointer: pointer.

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadUInt64FromMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer value |
	<var: #pointer type: #'char*' >
	<var: #value type: #'sqLong' >
	pointer := self internalPopStackPointer.

	value := self uint64AtPointer: pointer.

	self internalPushInt64: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLoadUInt8FromMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer value |
	<var: #pointer type: #'char*' >
	<var: #value type: #'sqInt' >
	pointer := self internalPopStackPointer.

	value := self uint8AtPointer: pointer.

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLocalFrameSize [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| alignedSize size |
	size := extA.

	"Align the size to 16 bytes."
	alignedSize := size + 15 bitAnd: -16.
	"Mark the frame"
	self setFrameHasNativeFrame: localFP.
	"Store the previous stack pointer"
	self nativePreviousStackPointerIn: localFP put: nativeStackPointer + 1.
	"Make the frame pointer"
	nativeStackPointer := nativeStackPointer - alignedSize.
	self nativeFramePointerIn: localFP put: nativeStackPointer + 1.
	"Set the stack pointer"
	nativeSP := nativeStackPointer + 1.
	self nativeStackPointerIn: localFP put: nativeStackPointer + 1.
	"Reserve space for the native stack"
	nativeStackPointer := nativeStackPointer - self defaultNativeStackFrameSize.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLockRegisters [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	"Nop in the interpreter"



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveLockVM [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	self abort.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveMalloc32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer size |
	<var: #pointer type: #'char*' >
	<var: #size type: #'sqInt' >
	size := self internalPopStackInt32.

	pointer := self malloc: size.

	self internalPushPointer: pointer.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveMalloc64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer size |
	<var: #pointer type: #'char*' >
	<var: #size type: #'sqLong' >
	size := self internalPopStackInt64.

	pointer := self malloc: size.

	self internalPushPointer: pointer.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveMemcpy32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| source dest size |
	<var: #source type: #'char*' >
	<var: #dest type: #'char*' >
	<var: #size type: #'sqInt' >
	size := self internalPopStackInt32.
	source := self internalPopStackPointer.
	dest := self internalPopStackPointer.

	self lowcode_mem: dest cp: source y: size.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveMemcpy64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| source dest size |
	<var: #source type: #'char*' >
	<var: #dest type: #'char*' >
	<var: #size type: #'sqLong' >
	size := self internalPopStackInt64.
	source := self internalPopStackPointer.
	dest := self internalPopStackPointer.

	self lowcode_mem: dest cp: source y: size.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveMemcpyFixed [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| source size dest |
	<var: #source type: #'char*' >
	<var: #dest type: #'char*' >
	size := extA.
	source := self internalPopStackPointer.
	dest := self internalPopStackPointer.

	self lowcode_mem: dest cp: source y: size.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveMoveFloat32ToPhysical [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| registerID value |
	<var: #value type: #'float' >
	registerID := extA.
	value := self internalPopStackFloat32.

	self lowcodeCalloutState: lowcodeCalloutState float32Register: registerID value: value.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveMoveFloat64ToPhysical [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| registerID value |
	<var: #value type: #'double' >
	registerID := extA.
	value := self internalPopStackFloat64.

	self lowcodeCalloutState: lowcodeCalloutState float64Register: registerID value: value.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveMoveInt32ToPhysical [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| registerID value |
	<var: #value type: #'sqInt' >
	registerID := extA.
	value := self internalPopStackInt32.

	self lowcodeCalloutState: lowcodeCalloutState int32Register: registerID value: value.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveMoveInt64ToPhysical [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| registerID value |
	<var: #value type: #'sqLong' >
	registerID := extA.
	value := self internalPopStackInt64.

	self lowcodeCalloutState: lowcodeCalloutState int64Register: registerID value: value.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveMovePointerToPhysical [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| registerID pointerValue |
	<var: #pointerValue type: #'char*' >
	registerID := extA.
	pointerValue := self internalPopStackPointer.

	self lowcodeCalloutState: lowcodeCalloutState pointerRegister: registerID value: pointerValue.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveMul32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqInt' >
	<var: #result type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	result := first * second.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveMul64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqLong' >
	<var: #result type: #'sqLong' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	result := first * second.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveNeg32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqInt' >
	<var: #result type: #'sqInt' >
	value := self internalPopStackInt32.

	result := value negated.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveNeg64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqLong' >
	<var: #result type: #'sqLong' >
	value := self internalPopStackInt64.

	result := value negated.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveNot32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqInt' >
	<var: #result type: #'sqInt' >
	value := self internalPopStackInt32.

	result := value bitXor: -1.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveNot64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqLong' >
	<var: #result type: #'sqLong' >
	value := self internalPopStackInt64.

	result := value bitXor: -1.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOopEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqInt' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStack.
	first := self internalPopStack.

	value := first = second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOopNotEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqInt' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStack.
	first := self internalPopStack.

	value := first ~= second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOopSmallIntegerToInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	object := self internalPopStack.

	value := objectMemory integerValueOf: object.

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOopSmallIntegerToInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqLong' >
	object := self internalPopStack.

	value := objectMemory integerValueOf: object.

	self internalPushInt64: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOopToBoolean32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	object := self internalPopStack.

	value := self booleanValueOf: object.

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOopToBoolean64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqLong' >
	object := self internalPopStack.

	value := self booleanValueOf: object.

	self internalPushInt64: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOopToFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'float' >
	object := self internalPopStack.

	value := objectMemory floatValueOf: object.

	self internalPushFloat32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOopToFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'double' >
	object := self internalPopStack.

	value := objectMemory floatValueOf: object.

	self internalPushFloat64: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOopToInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	object := self internalPopStack.

	value := self signed32BitValueOf: object.

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOopToInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqLong' >
	object := self internalPopStack.

	value := self signed64BitValueOf: object.

	self internalPushInt64: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOopToPointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object pointer |
	<var: #object type: #'sqInt' >
	<var: #pointer type: #'char*' >
	object := self internalPopStack.

	pointer := self pointerAtPointer: (objectMemory firstIndexableField: object).

	self internalPushPointer: pointer.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOopToPointerReinterpret [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object pointer |
	<var: #object type: #'sqInt' >
	<var: #pointer type: #'char*' >
	object := self internalPopStack.

	pointer := self cCoerce: object to: 'char*'.

	self internalPushPointer: pointer.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOopToUInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	object := self internalPopStack.

	value := self positive32BitValueOf: object.

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOopToUInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqLong' >
	object := self internalPopStack.

	value := self positive64BitValueOf: object.

	self internalPushInt64: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOr32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqInt' >
	<var: #result type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	result := first bitOr: second.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveOr64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqLong' >
	<var: #result type: #'sqLong' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	result := first bitOr: second.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePerformCallout [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| function |
	function := extA.

	self lowcodeDoCallout: (self cCoerce: function to: #'char*').

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePerformCalloutIndirect [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| function |
	<var: #function type: #'char*' >
	function := self internalPopStackPointer.

	self lowcodeDoCallout: function.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePin [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object |
	<var: #object type: #'sqInt' >
	object := self internalPopStack.

	objectMemory pinObject: object.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePlaftormCode [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| code |
	<var: #code type: #'sqInt' >

	self abort.

	self internalPushInt32: code.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePointerAddConstantOffset [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| base offset result |
	<var: #base type: #'char*' >
	<var: #result type: #'char*' >
	offset := extB.
	base := self internalPopStackPointer.

	result := base + offset.

	self internalPushPointer: result.
	extB := 0.
	numExtB := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePointerAddOffset32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| base offset result |
	<var: #base type: #'char*' >
	<var: #offset type: #'sqInt' >
	<var: #result type: #'char*' >
	offset := self internalPopStackInt32.
	base := self internalPopStackPointer.

	result := base + offset.

	self internalPushPointer: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePointerAddOffset64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| base offset result |
	<var: #base type: #'char*' >
	<var: #offset type: #'sqLong' >
	<var: #result type: #'char*' >
	offset := self internalPopStackInt64.
	base := self internalPopStackPointer.

	result := base + offset.

	self internalPushPointer: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePointerEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'char*' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'char*' >
	second := self internalPopStackPointer.
	first := self internalPopStackPointer.

	value := first = second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePointerNotEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'char*' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'char*' >
	second := self internalPopStackPointer.
	first := self internalPopStackPointer.

	value := first ~= second ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePointerToInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer result |
	<var: #pointer type: #'char*' >
	<var: #result type: #'sqInt' >
	pointer := self internalPopStackPointer.

	result := self cCoerce: pointer to: 'uintptr_t'.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePointerToInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer result |
	<var: #pointer type: #'char*' >
	<var: #result type: #'sqLong' >
	pointer := self internalPopStackPointer.

	result := self cCoerce: pointer to: 'uintptr_t'.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePointerToOop [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer object pointerClassLiteral |
	<var: #pointer type: #'char*' >
	<var: #object type: #'sqInt' >
	pointerClassLiteral := self literal: extA.
	pointer := self internalPopStackPointer.

	object := objectMemory instantiateClass: pointerClassLiteral indexableSize: BytesPerWord.
	self pointerAtPointer: (objectMemory firstIndexableField: object) put: pointer.

	self internalPush: object.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePointerToOopReinterprer [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer object |
	<var: #pointer type: #'char*' >
	<var: #object type: #'sqInt' >
	pointer := self internalPopStackPointer.

	object := self cCoerce: pointer to: 'sqInt'.

	self internalPush: object.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePopFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value |
	<var: #value type: #'float' >
	value := self internalPopStackFloat32.




]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePopFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value |
	<var: #value type: #'double' >
	value := self internalPopStackFloat64.




]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePopInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value |
	<var: #value type: #'sqInt' >
	value := self internalPopStackInt32.




]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePopInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value |
	<var: #value type: #'sqLong' >
	value := self internalPopStackInt64.




]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePopMultipleNative [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| popSize |
	popSize := extA.

	self internalPopStackNativeSize: popSize.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePopPointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointerValue |
	<var: #pointerValue type: #'char*' >
	pointerValue := self internalPopStackPointer.




]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushCalloutResultFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result |
	<var: #result type: #'float' >

	result := self lowcodeCalloutStateFetchResultFloat32: lowcodeCalloutState.

	self internalPushFloat32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushCalloutResultFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result |
	<var: #result type: #'double' >

	result := self lowcodeCalloutStateFetchResultFloat64: lowcodeCalloutState.

	self internalPushFloat64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushCalloutResultInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result |
	<var: #result type: #'sqInt' >

	result := self lowcodeCalloutStateFetchResultInt32: lowcodeCalloutState.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushCalloutResultInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result |
	<var: #result type: #'sqLong' >

	result := self lowcodeCalloutStateFetchResultInt64: lowcodeCalloutState.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushCalloutResultPointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result |
	<var: #result type: #'char*' >

	result := self lowcodeCalloutStateFetchResultPointer: lowcodeCalloutState.

	self internalPushPointer: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushConstantUInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result constant |
	<var: #result type: #'sqInt' >
	constant := extA.

	result := constant.

	self internalPushInt32: result.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushConstantUInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result constant |
	<var: #result type: #'sqLong' >
	constant := extA.

	result := constant.

	self internalPushInt64: result.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushNullPointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result |
	<var: #result type: #'char*' >

	result := 0.

	self internalPushPointer: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushOne32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result |
	<var: #result type: #'sqInt' >

	result := 1.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushOne64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result |
	<var: #result type: #'sqLong' >

	result := 1.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushOneFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result |
	<var: #result type: #'float' >

	result := 1.0.

	self internalPushFloat32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushOneFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result |
	<var: #result type: #'double' >

	result := 1.0.

	self internalPushFloat64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushPhysicalFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| registerID value |
	<var: #value type: #'float' >
	registerID := extA.

	value := self lowcodeCalloutState: lowcodeCalloutState float32Register: registerID.

	self internalPushFloat32: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushPhysicalFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| registerID value |
	<var: #value type: #'double' >
	registerID := extA.

	value := self lowcodeCalloutState: lowcodeCalloutState float64Register: registerID.

	self internalPushFloat64: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushPhysicalInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| registerID value |
	<var: #value type: #'sqInt' >
	registerID := extA.

	value := self lowcodeCalloutState: lowcodeCalloutState int32Register: registerID.

	self internalPushInt32: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushPhysicalInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| registerID value |
	<var: #value type: #'sqLong' >
	registerID := extA.

	value := self lowcodeCalloutState: lowcodeCalloutState int64Register: registerID.

	self internalPushInt64: value.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushPhysicalPointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| registerID pointerValue |
	<var: #pointerValue type: #'char*' >
	registerID := extA.

	pointerValue := self lowcodeCalloutState: lowcodeCalloutState pointerRegister: registerID.

	self internalPushPointer: pointerValue.
	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushSessionIdentifier [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value |
	<var: #value type: #'sqInt' >

	value := self getThisSessionID.

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushZero32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result |
	<var: #result type: #'sqInt' >

	result := 0.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushZero64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result |
	<var: #result type: #'sqLong' >

	result := 0.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushZeroFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result |
	<var: #result type: #'float' >

	result := 0.0.

	self internalPushFloat32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitivePushZeroFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| result |
	<var: #result type: #'double' >

	result := 0.0.

	self internalPushFloat64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveRem32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqInt' >
	<var: #result type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	result := first \\ second.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveRem64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqLong' >
	<var: #result type: #'sqLong' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	result := first \\ second.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveRightShift32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value shiftAmount result |
	<var: #value type: #'sqInt' >
	<var: #shiftAmount type: #'sqInt' >
	<var: #result type: #'sqInt' >
	shiftAmount := self internalPopStackInt32.
	value := self internalPopStackInt32.

	result := value >> shiftAmount.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveRightShift64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value shiftAmount result |
	<var: #value type: #'sqLong' >
	<var: #shiftAmount type: #'sqLong' >
	<var: #result type: #'sqLong' >
	shiftAmount := self internalPopStackInt64.
	value := self internalPopStackInt64.

	result := value >> shiftAmount.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveSignExtend32From16 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqInt' >
	<var: #result type: #'sqInt' >
	value := self internalPopStackInt32.

	result := self cCoerce: value to: 'signed short'.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveSignExtend32From8 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqInt' >
	<var: #result type: #'sqInt' >
	value := self internalPopStackInt32.

	result := self cCoerce: value to: 'signed char'.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveSignExtend64From16 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqLong' >
	<var: #result type: #'sqLong' >
	value := self internalPopStackInt64.

	result := self cCoerce: value to: 'int16_t'.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveSignExtend64From32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqInt' >
	<var: #result type: #'sqLong' >
	value := self internalPopStackInt32.

	result := self cCoerce: value to: 'int32_t'.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveSignExtend64From8 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqLong' >
	<var: #result type: #'sqLong' >
	value := self internalPopStackInt64.

	result := self cCoerce: value to: 'signed char'.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveSmallInt32ToOop [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	value := self internalPopStackInt32.

	object := objectMemory integerObjectOf: value.

	self internalPush: object.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStoreFloat32ToMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| floatValue pointer |
	<var: #floatValue type: #'float' >
	<var: #pointer type: #'char*' >
	pointer := self internalPopStackPointer.
	floatValue := self internalPopStackFloat32.

	self singleFloatAtPointer: pointer put: floatValue.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStoreFloat64ToMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| doubleValue pointer |
	<var: #doubleValue type: #'double' >
	<var: #pointer type: #'char*' >
	pointer := self internalPopStackPointer.
	doubleValue := self internalPopStackFloat64.

	self floatAtPointer: pointer put: doubleValue.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStoreInt16ToMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer value |
	<var: #pointer type: #'char*' >
	<var: #value type: #'sqInt' >
	pointer := self internalPopStackPointer.
	value := self internalPopStackInt32.

	self int16AtPointer: pointer put: value.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStoreInt32ToMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer value |
	<var: #pointer type: #'char*' >
	<var: #value type: #'sqInt' >
	pointer := self internalPopStackPointer.
	value := self internalPopStackInt32.

	self int32AtPointer: pointer put: value.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStoreInt64ToMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer value |
	<var: #pointer type: #'char*' >
	<var: #value type: #'sqLong' >
	pointer := self internalPopStackPointer.
	value := self internalPopStackInt64.

	self int64AtPointer: pointer put: value.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStoreInt8ToMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointer value |
	<var: #pointer type: #'char*' >
	<var: #value type: #'sqInt' >
	pointer := self internalPopStackPointer.
	value := self internalPopStackInt32.

	self int8AtPointer: pointer put: value.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStoreLocalFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'float' >
	baseOffset := extA.
	value := self internalPopStackFloat32.

	stackPages singleFloatAtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP) put: value.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStoreLocalFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'double' >
	baseOffset := extA.
	value := self internalPopStackFloat64.

	stackPages floatAtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP) put: value.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStoreLocalInt16 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqInt' >
	baseOffset := extA.
	value := self internalPopStackInt32.

	stackPages int16AtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP) put: value.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStoreLocalInt32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqInt' >
	baseOffset := extA.
	value := self internalPopStackInt32.

	stackPages int32AtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP) put: value.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStoreLocalInt64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	<var: #valueInt64 type: #'sqLong'>
	|valueInt64|
	BytesPerWord = 4 ifTrue: [
	self lowcodeStoreLocalInt64Workaround: extA in: localFP sp: localSP.
	] ifFalse: [
	valueInt64 := self internalPopStackInt64.
	stackPages int64AtPointer: (self framePointerOfNativeLocal: extA in: localFP) put: valueInt64.
	].
	extA := 0.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStoreLocalInt8 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value baseOffset |
	<var: #value type: #'sqInt' >
	baseOffset := extA.
	value := self internalPopStackInt32.

	stackPages int8AtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP) put: value.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStoreLocalPointer [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| pointerValue baseOffset |
	<var: #pointerValue type: #'char*' >
	baseOffset := extA.
	pointerValue := self internalPopStackPointer.

	stackPages pointerAtPointer: (self framePointerOfNativeLocal: baseOffset in: localFP) put: pointerValue.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStoreObjectField [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| fieldIndex object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	fieldIndex := extA.
	value := self internalPopStack.
	object := self internalPopStack.

	objectMemory storePointer: fieldIndex ofObject: object withValue: value.

	extA := 0.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStoreObjectFieldAt [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| fieldIndex object value |
	<var: #fieldIndex type: #'sqInt' >
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	value := self internalPopStack.
	fieldIndex := self internalPopStackInt32.
	object := self internalPopStack.

	objectMemory storePointer: fieldIndex ofObject: object withValue: value.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveStorePointerToMemory [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| memoryPointer pointerValue |
	<var: #memoryPointer type: #'char*' >
	<var: #pointerValue type: #'char*' >
	memoryPointer := self internalPopStackPointer.
	pointerValue := self internalPopStackPointer.

	self pointerAtPointer: memoryPointer put: pointerValue.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveSub32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqInt' >
	<var: #result type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	result := first - second.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveSub64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqLong' >
	<var: #result type: #'sqLong' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	result := first - second.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveTruncate32To16 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqInt' >
	<var: #result type: #'sqInt' >
	value := self internalPopStackInt32.

	result := value bitAnd: 16rFFFF.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveTruncate32To8 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqInt' >
	<var: #result type: #'sqInt' >
	value := self internalPopStackInt32.

	result := value bitAnd: 16rFF.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveTruncate64To16 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqLong' >
	<var: #result type: #'sqInt' >
	value := self internalPopStackInt64.

	result := value bitAnd: 16rFFFF.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveTruncate64To32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqLong' >
	<var: #result type: #'sqInt' >
	value := self internalPopStackInt64.

	result := value bitAnd: 16rFFFFFFFF.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveTruncate64To8 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqLong' >
	<var: #result type: #'sqInt' >
	value := self internalPopStackInt64.

	result := value bitAnd: 16rFF.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUdiv32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqInt' >
	<var: #result type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	result := (self cCoerce: first to: 'unsigned int') //
	(self cCoerce: second to: 'unsigned int').

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUdiv64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqLong' >
	<var: #result type: #'sqLong' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	result := (self cCoerce: first to: 'uint64_t') //
	(self cCoerce: second to: 'uint64_t').

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUint32Great [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqInt' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	value := (self cCoerce: first to: 'unsigned int') >
	(self cCoerce: second to: 'unsigned int') ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUint32GreatEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqInt' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	value := (self cCoerce: first to: 'unsigned int') >=
	(self cCoerce: second to: 'unsigned int') ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUint32Less [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqInt' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	value := (self cCoerce: first to: 'unsigned int') <
	(self cCoerce: second to: 'unsigned int') ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUint32LessEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqInt' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	value := (self cCoerce: first to: 'unsigned int') <=
	(self cCoerce: second to: 'unsigned int') ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUint32ToFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqInt' >
	<var: #result type: #'float' >
	value := self internalPopStackInt32.

	result := self cCoerce: (self cCoerce: value to: 'unsigned int') to: 'float'.

	self internalPushFloat32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUint32ToFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqInt' >
	<var: #result type: #'double' >
	value := self internalPopStackInt32.

	result := self cCoerce: (self cCoerce: value to: 'unsigned int') to: 'double'.

	self internalPushFloat64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUint32ToOop [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqInt' >
	value := self internalPopStackInt32.

	object := objectMemory positive32BitIntegerFor: value.

	self internalPush: object.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUint64Great [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqLong' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	value := (self cCoerce: first to: 'uint64_t') >
	(self cCoerce: second to: 'uint64_t') ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUint64GreatEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqLong' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	value := (self cCoerce: first to: 'uint64_t') >=
	(self cCoerce: second to: 'uint64_t') ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUint64Less [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqLong' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	value := (self cCoerce: first to: 'uint64_t') <
	(self cCoerce: second to: 'uint64_t') ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUint64LessEqual [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second value first |
	<var: #second type: #'sqLong' >
	<var: #value type: #'sqInt' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	value := (self cCoerce: first to: 'uint64_t') <=
	(self cCoerce: second to: 'uint64_t') ifTrue: [1] ifFalse: [0].

	self internalPushInt32: value.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUint64ToFloat32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqLong' >
	<var: #result type: #'float' >
	value := self internalPopStackInt64.

	result := self cCoerce: (self cCoerce: value to: 'uint64_t') to: 'float'.

	self internalPushFloat32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUint64ToFloat64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqLong' >
	<var: #result type: #'double' >
	value := self internalPopStackInt64.

	result := self cCoerce: (self cCoerce: value to: 'uint64_t') to: 'double'.

	self internalPushFloat64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUint64ToOop [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object value |
	<var: #object type: #'sqInt' >
	<var: #value type: #'sqLong' >
	value := self internalPopStackInt64.

	object := self positive64BitIntegerFor: value.

	self internalPush: object.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUmul32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqInt' >
	<var: #result type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	result := (self cCoerce: first to: 'unsigned int') *
	(self cCoerce: second to: 'unsigned int').

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUmul64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqLong' >
	<var: #result type: #'sqLong' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	result := (self cCoerce: first to: 'uint64_t') *
	(self cCoerce: second to: 'uint64_t').

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUnlockRegisters [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	"Nop in the interpreter"



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUnlockVM [
	<option: #LowcodeVM>	"Lowcode instruction generator"

	self abort.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUnpin [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| object |
	<var: #object type: #'sqInt' >
	object := self internalPopStack.

	objectMemory unpinObject: object.



]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUrem32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqInt' >
	<var: #result type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	result := (self cCoerce: first to: 'unsigned int') \\
	(self cCoerce: second to: 'unsigned int').

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveUrem64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqLong' >
	<var: #result type: #'sqLong' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	result := (self cCoerce: first to: 'unsigned int') \\
	(self cCoerce: second to: 'unsigned int').

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveXor32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqInt' >
	<var: #result type: #'sqInt' >
	<var: #first type: #'sqInt' >
	second := self internalPopStackInt32.
	first := self internalPopStackInt32.

	result := first bitXor: second.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveXor64 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| second result first |
	<var: #second type: #'sqLong' >
	<var: #result type: #'sqLong' >
	<var: #first type: #'sqLong' >
	second := self internalPopStackInt64.
	first := self internalPopStackInt64.

	result := first bitXor: second.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveZeroExtend32From16 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqInt' >
	<var: #result type: #'sqInt' >
	value := self internalPopStackInt32.

	result := self cCoerce: value to: 'uint16_t'.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveZeroExtend32From8 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqInt' >
	<var: #result type: #'sqInt' >
	value := self internalPopStackInt32.

	result := self cCoerce: value to: 'uint8_t'.

	self internalPushInt32: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveZeroExtend64From16 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqLong' >
	<var: #result type: #'sqLong' >
	value := self internalPopStackInt64.

	result := self cCoerce: value to: 'uint16_t'.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveZeroExtend64From32 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqInt' >
	<var: #result type: #'sqLong' >
	value := self internalPopStackInt32.

	result := self cCoerce: value to: 'uint32_t'.

	self internalPushInt64: result.


]

{ #category : #'inline primitive generated code' }
StackInterpreter >> lowcodePrimitiveZeroExtend64From8 [
	<option: #LowcodeVM>	"Lowcode instruction generator"
	| value result |
	<var: #value type: #'sqLong' >
	<var: #result type: #'sqLong' >
	value := self internalPopStackInt64.

	result := self cCoerce: value to: 'uint8_t'.

	self internalPushInt64: result.


]

{ #category : #'inline primitive support' }
StackInterpreter >> lowcodeStoreLocalInt64Workaround: baseOffset in: theFP sp: theSP [
	"This method is a workaround a GCC bug"
	<inline: #never>
	<option: #LowcodeVM>
	<var: #theFP type: #'char*'>
	<var: #theSP type: #'char*'>
	<var: #value type: #'sqLong'>
	| value workNativeSP|

	"Fetch the value from the native tack"
	workNativeSP := (self nativeStackPointerIn: theFP).
	value := stackPages long64AtPointer: (workNativeSP - 1).
	self nativeStackPointerIn: theFP put: workNativeSP + 8.

	"Store the local"
 	self int64AtPointer: (self framePointerOfNativeLocal: baseOffset in: theFP) put: value.
]

{ #category : #'inline primitive dispatch generated code' }
StackInterpreter >> lowcodeTrinaryInlinePrimitive: prim [
	<option: #LowcodeVM>	"Lowcode instruction interpreter dispatch"
	prim
		caseOf: {
			[0]	-> [ ^ self lowcodePrimitiveOopEqual ].
			[1]	-> [ ^ self lowcodePrimitiveOopNotEqual ].
			[2]	-> [ ^ self lowcodePrimitiveStoreObjectField ].
			[3]	-> [ ^ self lowcodePrimitiveStoreObjectFieldAt ].
		}
		otherwise: [
			localIP := localIP - 3.
			^self respondToUnknownBytecode
		].
	


]

{ #category : #'inline primitive dispatch generated code' }
StackInterpreter >> lowcodeUnaryInlinePrimitive2: prim [
	<option: #LowcodeVM>	"Lowcode instruction interpreter dispatch"
	prim
		caseOf: {
			[60]	-> [ ^ self lowcodePrimitiveFloat64ToFloat32 ].
			[61]	-> [ ^ self lowcodePrimitiveFloat64ToInt32 ].
			[62]	-> [ ^ self lowcodePrimitiveFloat64ToInt64 ].
			[63]	-> [ ^ self lowcodePrimitiveFloat64ToUInt32 ].
			[64]	-> [ ^ self lowcodePrimitiveFloat64ToUInt64 ].
			[65]	-> [ ^ self lowcodePrimitiveFree ].
			[66]	-> [ ^ self lowcodePrimitiveInstantiateIndexable32Oop ].
			[67]	-> [ ^ self lowcodePrimitiveInstantiateIndexableOop ].
			[68]	-> [ ^ self lowcodePrimitiveInstantiateOop ].
			[69]	-> [ ^ self lowcodePrimitiveInt32Equal ].
			[70]	-> [ ^ self lowcodePrimitiveInt32Great ].
			[71]	-> [ ^ self lowcodePrimitiveInt32GreatEqual ].
			[72]	-> [ ^ self lowcodePrimitiveInt32Less ].
			[73]	-> [ ^ self lowcodePrimitiveInt32LessEqual ].
			[74]	-> [ ^ self lowcodePrimitiveInt32NotEqual ].
			[75]	-> [ ^ self lowcodePrimitiveInt32ToFloat32 ].
			[76]	-> [ ^ self lowcodePrimitiveInt32ToFloat64 ].
			[77]	-> [ ^ self lowcodePrimitiveInt32ToPointer ].
			[78]	-> [ ^ self lowcodePrimitiveInt64Equal ].
			[79]	-> [ ^ self lowcodePrimitiveInt64Great ].
			[80]	-> [ ^ self lowcodePrimitiveInt64GreatEqual ].
			[81]	-> [ ^ self lowcodePrimitiveInt64Less ].
			[82]	-> [ ^ self lowcodePrimitiveInt64LessEqual ].
			[83]	-> [ ^ self lowcodePrimitiveInt64NotEqual ].
			[84]	-> [ ^ self lowcodePrimitiveInt64ToFloat32 ].
			[85]	-> [ ^ self lowcodePrimitiveInt64ToFloat64 ].
			[86]	-> [ ^ self lowcodePrimitiveInt64ToPointer ].
			[87]	-> [ ^ self lowcodePrimitiveLeftShift32 ].
			[88]	-> [ ^ self lowcodePrimitiveLeftShift64 ].
			[89]	-> [ ^ self lowcodePrimitiveLoadArgumentAddress ].
			[90]	-> [ ^ self lowcodePrimitiveLoadArgumentFloat32 ].
			[91]	-> [ ^ self lowcodePrimitiveLoadArgumentFloat64 ].
			[92]	-> [ ^ self lowcodePrimitiveLoadArgumentInt16 ].
			[93]	-> [ ^ self lowcodePrimitiveLoadArgumentInt32 ].
			[94]	-> [ ^ self lowcodePrimitiveLoadArgumentInt64 ].
			[95]	-> [ ^ self lowcodePrimitiveLoadArgumentInt8 ].
			[96]	-> [ ^ self lowcodePrimitiveLoadArgumentPointer ].
			[97]	-> [ ^ self lowcodePrimitiveLoadArgumentUInt16 ].
			[98]	-> [ ^ self lowcodePrimitiveLoadArgumentUInt32 ].
			[99]	-> [ ^ self lowcodePrimitiveLoadArgumentUInt64 ].
			[100]	-> [ ^ self lowcodePrimitiveLoadArgumentUInt8 ].
			[101]	-> [ ^ self lowcodePrimitiveLoadFloat32FromMemory ].
			[102]	-> [ ^ self lowcodePrimitiveLoadFloat64FromMemory ].
			[103]	-> [ ^ self lowcodePrimitiveLoadInt16FromMemory ].
			[104]	-> [ ^ self lowcodePrimitiveLoadInt32FromMemory ].
			[105]	-> [ ^ self lowcodePrimitiveLoadInt64FromMemory ].
			[106]	-> [ ^ self lowcodePrimitiveLoadInt8FromMemory ].
			[107]	-> [ ^ self lowcodePrimitiveLoadLocalAddress ].
			[108]	-> [ ^ self lowcodePrimitiveLoadLocalFloat32 ].
			[109]	-> [ ^ self lowcodePrimitiveLoadLocalFloat64 ].
			[110]	-> [ ^ self lowcodePrimitiveLoadLocalInt16 ].
			[111]	-> [ ^ self lowcodePrimitiveLoadLocalInt32 ].
			[112]	-> [ ^ self lowcodePrimitiveLoadLocalInt64 ].
			[113]	-> [ ^ self lowcodePrimitiveLoadLocalInt8 ].
			[114]	-> [ ^ self lowcodePrimitiveLoadLocalPointer ].
			[115]	-> [ ^ self lowcodePrimitiveLoadLocalUInt16 ].
			[116]	-> [ ^ self lowcodePrimitiveLoadLocalUInt32 ].
			[117]	-> [ ^ self lowcodePrimitiveLoadLocalUInt64 ].
			[118]	-> [ ^ self lowcodePrimitiveLoadLocalUInt8 ].
			[119]	-> [ ^ self lowcodePrimitiveLoadObjectAt ].
		}
		otherwise: [ ^ self lowcodeUnaryInlinePrimitive3: prim ].
	


]

{ #category : #'inline primitive dispatch generated code' }
StackInterpreter >> lowcodeUnaryInlinePrimitive3: prim [
	<option: #LowcodeVM>	"Lowcode instruction interpreter dispatch"
	prim
		caseOf: {
			[120]	-> [ ^ self lowcodePrimitiveLoadObjectField ].
			[121]	-> [ ^ self lowcodePrimitiveLoadPointerFromMemory ].
			[122]	-> [ ^ self lowcodePrimitiveLoadUInt16FromMemory ].
			[123]	-> [ ^ self lowcodePrimitiveLoadUInt32FromMemory ].
			[124]	-> [ ^ self lowcodePrimitiveLoadUInt64FromMemory ].
			[125]	-> [ ^ self lowcodePrimitiveLoadUInt8FromMemory ].
			[126]	-> [ ^ self lowcodePrimitiveLocalFrameSize ].
			[127]	-> [ ^ self lowcodePrimitiveLockRegisters ].
			[128]	-> [ ^ self lowcodePrimitiveLockVM ].
			[129]	-> [ ^ self lowcodePrimitiveMalloc32 ].
			[130]	-> [ ^ self lowcodePrimitiveMalloc64 ].
			[131]	-> [ ^ self lowcodePrimitiveMemcpy32 ].
			[132]	-> [ ^ self lowcodePrimitiveMemcpy64 ].
			[133]	-> [ ^ self lowcodePrimitiveMemcpyFixed ].
			[134]	-> [ ^ self lowcodePrimitiveMoveFloat32ToPhysical ].
			[135]	-> [ ^ self lowcodePrimitiveMoveFloat64ToPhysical ].
			[136]	-> [ ^ self lowcodePrimitiveMoveInt32ToPhysical ].
			[137]	-> [ ^ self lowcodePrimitiveMoveInt64ToPhysical ].
			[138]	-> [ ^ self lowcodePrimitiveMovePointerToPhysical ].
			[139]	-> [ ^ self lowcodePrimitiveMul32 ].
			[140]	-> [ ^ self lowcodePrimitiveMul64 ].
			[141]	-> [ ^ self lowcodePrimitiveNeg32 ].
			[142]	-> [ ^ self lowcodePrimitiveNeg64 ].
			[143]	-> [ ^ self lowcodePrimitiveNot32 ].
			[144]	-> [ ^ self lowcodePrimitiveNot64 ].
			[145]	-> [ ^ self lowcodePrimitiveOr32 ].
			[146]	-> [ ^ self lowcodePrimitiveOr64 ].
			[147]	-> [ ^ self lowcodePrimitivePerformCallout ].
			[148]	-> [ ^ self lowcodePrimitivePerformCalloutIndirect ].
			[149]	-> [ ^ self lowcodePrimitivePushCalloutResultFloat32 ].
			[150]	-> [ ^ self lowcodePrimitivePushCalloutResultFloat64 ].
			[151]	-> [ ^ self lowcodePrimitivePushCalloutResultInt32 ].
			[152]	-> [ ^ self lowcodePrimitivePushCalloutResultInt64 ].
			[153]	-> [ ^ self lowcodePrimitivePushCalloutResultPointer ].
			[161]	-> [ ^ self lowcodePrimitivePlaftormCode ].
			[162]	-> [ ^ self lowcodePrimitivePointerAddConstantOffset ].
			[163]	-> [ ^ self lowcodePrimitivePointerAddOffset32 ].
			[164]	-> [ ^ self lowcodePrimitivePointerAddOffset64 ].
			[165]	-> [ ^ self lowcodePrimitivePointerEqual ].
			[166]	-> [ ^ self lowcodePrimitivePointerNotEqual ].
			[167]	-> [ ^ self lowcodePrimitivePointerToInt32 ].
			[168]	-> [ ^ self lowcodePrimitivePointerToInt64 ].
			[169]	-> [ ^ self lowcodePrimitivePopFloat32 ].
			[170]	-> [ ^ self lowcodePrimitivePopFloat64 ].
			[171]	-> [ ^ self lowcodePrimitivePopInt32 ].
			[172]	-> [ ^ self lowcodePrimitivePopInt64 ].
			[173]	-> [ ^ self lowcodePrimitivePopMultipleNative ].
			[174]	-> [ ^ self lowcodePrimitivePopPointer ].
			[175]	-> [ ^ self lowcodePrimitivePushConstantUInt32 ].
			[176]	-> [ ^ self lowcodePrimitivePushConstantUInt64 ].
			[177]	-> [ ^ self lowcodePrimitivePushNullPointer ].
			[178]	-> [ ^ self lowcodePrimitivePushOne32 ].
			[179]	-> [ ^ self lowcodePrimitivePushOne64 ].
			[180]	-> [ ^ self lowcodePrimitivePushOneFloat32 ].
			[181]	-> [ ^ self lowcodePrimitivePushOneFloat64 ].
			[182]	-> [ ^ self lowcodePrimitivePushPhysicalFloat32 ].
			[183]	-> [ ^ self lowcodePrimitivePushPhysicalFloat64 ].
			[184]	-> [ ^ self lowcodePrimitivePushPhysicalInt32 ].
			[185]	-> [ ^ self lowcodePrimitivePushPhysicalInt64 ].
			[186]	-> [ ^ self lowcodePrimitivePushPhysicalPointer ].
		}
		otherwise: [ ^ self lowcodeUnaryInlinePrimitive4: prim ].
	


]

{ #category : #'inline primitive dispatch generated code' }
StackInterpreter >> lowcodeUnaryInlinePrimitive4: prim [
	<option: #LowcodeVM>	"Lowcode instruction interpreter dispatch"
	prim
		caseOf: {
			[187]	-> [ ^ self lowcodePrimitivePushSessionIdentifier ].
			[188]	-> [ ^ self lowcodePrimitivePushZero32 ].
			[189]	-> [ ^ self lowcodePrimitivePushZero64 ].
			[190]	-> [ ^ self lowcodePrimitivePushZeroFloat32 ].
			[191]	-> [ ^ self lowcodePrimitivePushZeroFloat64 ].
			[192]	-> [ ^ self lowcodePrimitiveRem32 ].
			[193]	-> [ ^ self lowcodePrimitiveRem64 ].
			[194]	-> [ ^ self lowcodePrimitiveRightShift32 ].
			[195]	-> [ ^ self lowcodePrimitiveRightShift64 ].
			[196]	-> [ ^ self lowcodePrimitiveSignExtend32From16 ].
			[197]	-> [ ^ self lowcodePrimitiveSignExtend32From8 ].
			[198]	-> [ ^ self lowcodePrimitiveSignExtend64From16 ].
			[199]	-> [ ^ self lowcodePrimitiveSignExtend64From32 ].
			[200]	-> [ ^ self lowcodePrimitiveSignExtend64From8 ].
			[201]	-> [ ^ self lowcodePrimitiveStoreFloat32ToMemory ].
			[202]	-> [ ^ self lowcodePrimitiveStoreFloat64ToMemory ].
			[203]	-> [ ^ self lowcodePrimitiveStoreInt16ToMemory ].
			[204]	-> [ ^ self lowcodePrimitiveStoreInt32ToMemory ].
			[205]	-> [ ^ self lowcodePrimitiveStoreInt64ToMemory ].
			[206]	-> [ ^ self lowcodePrimitiveStoreInt8ToMemory ].
			[207]	-> [ ^ self lowcodePrimitiveStoreLocalFloat32 ].
			[208]	-> [ ^ self lowcodePrimitiveStoreLocalFloat64 ].
			[209]	-> [ ^ self lowcodePrimitiveStoreLocalInt16 ].
			[210]	-> [ ^ self lowcodePrimitiveStoreLocalInt32 ].
			[211]	-> [ ^ self lowcodePrimitiveStoreLocalInt64 ].
			[212]	-> [ ^ self lowcodePrimitiveStoreLocalInt8 ].
			[213]	-> [ ^ self lowcodePrimitiveStoreLocalPointer ].
			[214]	-> [ ^ self lowcodePrimitiveStorePointerToMemory ].
			[215]	-> [ ^ self lowcodePrimitiveSub32 ].
			[216]	-> [ ^ self lowcodePrimitiveSub64 ].
			[217]	-> [ ^ self lowcodePrimitiveTruncate32To16 ].
			[218]	-> [ ^ self lowcodePrimitiveTruncate32To8 ].
			[219]	-> [ ^ self lowcodePrimitiveTruncate64To16 ].
			[220]	-> [ ^ self lowcodePrimitiveTruncate64To32 ].
			[221]	-> [ ^ self lowcodePrimitiveTruncate64To8 ].
			[222]	-> [ ^ self lowcodePrimitiveUdiv32 ].
			[223]	-> [ ^ self lowcodePrimitiveUdiv64 ].
			[224]	-> [ ^ self lowcodePrimitiveUint32Great ].
			[225]	-> [ ^ self lowcodePrimitiveUint32GreatEqual ].
			[226]	-> [ ^ self lowcodePrimitiveUint32Less ].
			[227]	-> [ ^ self lowcodePrimitiveUint32LessEqual ].
			[228]	-> [ ^ self lowcodePrimitiveUint32ToFloat32 ].
			[229]	-> [ ^ self lowcodePrimitiveUint32ToFloat64 ].
			[230]	-> [ ^ self lowcodePrimitiveUint64Great ].
			[231]	-> [ ^ self lowcodePrimitiveUint64GreatEqual ].
			[232]	-> [ ^ self lowcodePrimitiveUint64Less ].
			[233]	-> [ ^ self lowcodePrimitiveUint64LessEqual ].
			[234]	-> [ ^ self lowcodePrimitiveUint64ToFloat32 ].
			[235]	-> [ ^ self lowcodePrimitiveUint64ToFloat64 ].
			[236]	-> [ ^ self lowcodePrimitiveUmul32 ].
			[237]	-> [ ^ self lowcodePrimitiveUmul64 ].
			[238]	-> [ ^ self lowcodePrimitiveUnlockRegisters ].
			[239]	-> [ ^ self lowcodePrimitiveUnlockVM ].
			[240]	-> [ ^ self lowcodePrimitiveUrem32 ].
			[241]	-> [ ^ self lowcodePrimitiveUrem64 ].
			[242]	-> [ ^ self lowcodePrimitiveXor32 ].
			[243]	-> [ ^ self lowcodePrimitiveXor64 ].
			[244]	-> [ ^ self lowcodePrimitiveZeroExtend32From16 ].
			[245]	-> [ ^ self lowcodePrimitiveZeroExtend32From8 ].
			[246]	-> [ ^ self lowcodePrimitiveZeroExtend64From16 ].
		}
		otherwise: [ ^ self lowcodeUnaryInlinePrimitive5: prim ].
	


]

{ #category : #'inline primitive dispatch generated code' }
StackInterpreter >> lowcodeUnaryInlinePrimitive5: prim [
	<option: #LowcodeVM>	"Lowcode instruction interpreter dispatch"
	prim
		caseOf: {
			[247]	-> [ ^ self lowcodePrimitiveZeroExtend64From32 ].
			[248]	-> [ ^ self lowcodePrimitiveZeroExtend64From8 ].
		}
		otherwise: [
			localIP := localIP - 3.
			^self respondToUnknownBytecode
		].
	


]

{ #category : #'inline primitive dispatch generated code' }
StackInterpreter >> lowcodeUnaryInlinePrimitive: prim [
	<option: #LowcodeVM>	"Lowcode instruction interpreter dispatch"
	prim
		caseOf: {
			[0]	-> [ ^ self lowcodePrimitiveAdd32 ].
			[1]	-> [ ^ self lowcodePrimitiveAdd64 ].
			[2]	-> [ ^ self lowcodePrimitiveAlloca32 ].
			[3]	-> [ ^ self lowcodePrimitiveAlloca64 ].
			[4]	-> [ ^ self lowcodePrimitiveAnd32 ].
			[5]	-> [ ^ self lowcodePrimitiveAnd64 ].
			[6]	-> [ ^ self lowcodePrimitiveArithmeticRightShift32 ].
			[7]	-> [ ^ self lowcodePrimitiveArithmeticRightShift64 ].
			[8]	-> [ ^ self lowcodePrimitiveBeginCall ].
			[9]	-> [ ^ self lowcodePrimitiveCallArgumentFloat32 ].
			[10]	-> [ ^ self lowcodePrimitiveCallArgumentFloat64 ].
			[11]	-> [ ^ self lowcodePrimitiveCallArgumentInt32 ].
			[12]	-> [ ^ self lowcodePrimitiveCallArgumentInt64 ].
			[13]	-> [ ^ self lowcodePrimitiveCallArgumentPointer ].
			[14]	-> [ ^ self lowcodePrimitiveCallArgumentSpace ].
			[15]	-> [ ^ self lowcodePrimitiveCallArgumentStructure ].
			[16]	-> [ ^ self lowcodePrimitiveCallInstruction ].
			[17]	-> [ ^ self lowcodePrimitiveCallPhysical ].
			[18]	-> [ ^ self lowcodePrimitiveCheckSessionIdentifier ].
			[19]	-> [ ^ self lowcodePrimitiveCompareAndSwap32 ].
			[20]	-> [ ^ self lowcodePrimitiveDiv32 ].
			[21]	-> [ ^ self lowcodePrimitiveDiv64 ].
			[22]	-> [ ^ self lowcodePrimitiveDuplicateFloat32 ].
			[23]	-> [ ^ self lowcodePrimitiveDuplicateFloat64 ].
			[24]	-> [ ^ self lowcodePrimitiveDuplicateInt32 ].
			[25]	-> [ ^ self lowcodePrimitiveDuplicateInt64 ].
			[26]	-> [ ^ self lowcodePrimitiveDuplicatePointer ].
			[27]	-> [ ^ self lowcodePrimitiveEffectiveAddress32 ].
			[28]	-> [ ^ self lowcodePrimitiveEffectiveAddress64 ].
			[29]	-> [ ^ self lowcodePrimitiveEndCall ].
			[30]	-> [ ^ self lowcodePrimitiveEndCallNoCleanup ].
			[31]	-> [ ^ self lowcodePrimitiveFloat32Add ].
			[32]	-> [ ^ self lowcodePrimitiveFloat32Div ].
			[33]	-> [ ^ self lowcodePrimitiveFloat32Equal ].
			[34]	-> [ ^ self lowcodePrimitiveFloat32Great ].
			[35]	-> [ ^ self lowcodePrimitiveFloat32GreatEqual ].
			[36]	-> [ ^ self lowcodePrimitiveFloat32Less ].
			[37]	-> [ ^ self lowcodePrimitiveFloat32LessEqual ].
			[38]	-> [ ^ self lowcodePrimitiveFloat32Mul ].
			[39]	-> [ ^ self lowcodePrimitiveFloat32Neg ].
			[40]	-> [ ^ self lowcodePrimitiveFloat32NotEqual ].
			[41]	-> [ ^ self lowcodePrimitiveFloat32Sqrt ].
			[42]	-> [ ^ self lowcodePrimitiveFloat32Sub ].
			[43]	-> [ ^ self lowcodePrimitiveFloat32ToFloat64 ].
			[44]	-> [ ^ self lowcodePrimitiveFloat32ToInt32 ].
			[45]	-> [ ^ self lowcodePrimitiveFloat32ToInt64 ].
			[46]	-> [ ^ self lowcodePrimitiveFloat32ToUInt32 ].
			[47]	-> [ ^ self lowcodePrimitiveFloat32ToUInt64 ].
			[48]	-> [ ^ self lowcodePrimitiveFloat64Add ].
			[49]	-> [ ^ self lowcodePrimitiveFloat64Div ].
			[50]	-> [ ^ self lowcodePrimitiveFloat64Equal ].
			[51]	-> [ ^ self lowcodePrimitiveFloat64Great ].
			[52]	-> [ ^ self lowcodePrimitiveFloat64GreatEqual ].
			[53]	-> [ ^ self lowcodePrimitiveFloat64Less ].
			[54]	-> [ ^ self lowcodePrimitiveFloat64LessEqual ].
			[55]	-> [ ^ self lowcodePrimitiveFloat64Mul ].
			[56]	-> [ ^ self lowcodePrimitiveFloat64Neg ].
			[57]	-> [ ^ self lowcodePrimitiveFloat64NotEqual ].
			[58]	-> [ ^ self lowcodePrimitiveFloat64Sqrt ].
			[59]	-> [ ^ self lowcodePrimitiveFloat64Sub ].
		}
		otherwise: [ ^ self lowcodeUnaryInlinePrimitive2: prim ].
	


]

{ #category : #'inline primitive support' }
StackInterpreter >> lowcode_mem: destAddress cp: sourceAddress y: bytes [
	"This method is a workaround a GCC bug.
	In Windows memcpy is putting too much register pressure on GCC when used by Lowcode instructions"
	<inline: #never>
	<option: #LowcodeVM>
	<var: #destAddress type: #'void*'>
	<var: #sourceAddress type: #'void*'>
	<var: #bytes type: #'sqInt'>
	
	"Using memmove instead of memcpy to avoid crashing GCC in Windows."
	self memmove: destAddress _: sourceAddress _: bytes
]

{ #category : #'frame access' }
StackInterpreter >> makeBaseFrameFor: aContext [ "<Integer>"
	"Marry aContext with the base frame of a new stack page.  Build the base
	 frame to reflect the context's state.  Answer the new page."
	<returnTypeC: #'StackPage *'>
	| page pointer theMethod theIP numArgs stackPtrIndex maybeClosure rcvr |
	<inline: false>
	<var: #page type: #'StackPage *'>
	<var: #pointer type: #'char *'>
	self assert: (objectMemory isContext: aContext).
	self assert: (self isSingleContext: aContext).
	self assert: (objectMemory goodContextSize: aContext).
	page := stackPages newStackPage.
	pointer := page baseAddress.
	theIP := objectMemory fetchPointer: InstructionPointerIndex ofObject: aContext.
	theMethod := objectMemory followObjField: MethodIndex ofObject: aContext.
	(objectMemory isIntegerObject: theIP) ifFalse:
		[self error: 'context is not resumable'].
	theIP := objectMemory integerValueOf: theIP.
	rcvr := objectMemory followField: ReceiverIndex ofObject: aContext.
	"If the frame is a closure activation then the closure should be on the stack in
	 the pushed receiver position (closures receive the value[:value:] messages).
	 Otherwise it should be the receiver proper."
	maybeClosure := objectMemory fetchPointer: ClosureIndex ofObject: aContext.
	maybeClosure ~= objectMemory nilObject
		ifTrue:
			[(objectMemory isForwarded: maybeClosure) ifTrue:
				[maybeClosure := objectMemory fixFollowedField: ClosureIndex ofObject: aContext withInitialValue: maybeClosure].
			 numArgs := self argumentCountOfClosure: maybeClosure.
			 stackPages longAt: pointer put: maybeClosure]
		ifFalse:
			[| header |
			 header := objectMemory methodHeaderOf: theMethod.
			 numArgs := self argumentCountOfMethodHeader: header.
			 "If this is a synthetic context its IP could be pointing at the CallPrimitive opcode.  If so, skip it."
			 ((self methodHeaderHasPrimitive: header)
			  and: [theIP = (1 + (self startPCOfMethodHeader: header))]) ifTrue:
				[theIP := theIP + (self sizeOfCallPrimitiveBytecode: header)].
			 stackPages longAt: pointer put: rcvr].
	"Put the arguments on the stack"
	1 to: numArgs do:
		[:i|
		stackPages
			longAt: (pointer := pointer - objectMemory wordSize)
			put: (objectMemory fetchPointer: ReceiverIndex + i ofObject: aContext).
		"nil the slot in the context so that it doesn't inadvertently hang onto some collectable object.
		 Thanks to Ryan Macnak for identifying this bug"
		objectMemory storePointerUnchecked: ReceiverIndex + i ofObject: aContext withValue: objectMemory nilObject].
	"saved caller ip is sender context in base frame"
	stackPages
		longAt: (pointer := pointer - objectMemory wordSize)
		put: (objectMemory followObjField: SenderIndex ofObject: aContext).
	"base frame's saved fp is null"
	stackPages
		longAt: (pointer := pointer - objectMemory wordSize)
		put: 0.
	page baseFP: pointer; headFP: pointer.
	stackPages
		longAt: (pointer := pointer - objectMemory wordSize)
		put: theMethod.
	stackPages
		longAt: (pointer := pointer - objectMemory wordSize)
		put: (self encodeFrameFieldHasContext: true isBlock: maybeClosure ~= objectMemory nilObject numArgs: numArgs).
	self assert: (self frameHasContext: page baseFP).
	self assert: (self frameNumArgs: page baseFP) == numArgs.
	stackPages
		longAt: (pointer := pointer - objectMemory wordSize)
		put: aContext.
	stackPages
		longAt: (pointer := pointer - objectMemory wordSize)
		put: rcvr.
	stackPtrIndex := self quickFetchInteger: StackPointerIndex ofObject: aContext.
	self assert: ReceiverIndex + stackPtrIndex < (objectMemory lengthOf: aContext).
	numArgs + 1 to: stackPtrIndex do:
		[:i|
		stackPages
			longAt: (pointer := pointer - objectMemory wordSize)
			put: (objectMemory fetchPointer: ReceiverIndex + i ofObject: aContext)].
	"top of stack is the instruction pointer"
	theIP := self iframeInstructionPointerForIndex: theIP method: theMethod.
	stackPages longAt: (pointer := pointer - objectMemory wordSize) put: theIP.
	page headSP: pointer.
	self assert: (self context: aContext hasValidInversePCMappingOf: theIP in: page baseFP).

	"Mark context as married by setting its sender to the frame pointer plus SmallInteger
	 tags and the InstructionPointer to the saved fp (which ensures correct alignment
	 w.r.t. the frame when we check for validity) plus SmallInteger tags."
	objectMemory storePointerUnchecked: SenderIndex
		ofObject: aContext
		withValue: (self withSmallIntegerTags: page baseFP).
	objectMemory storePointerUnchecked: InstructionPointerIndex
		ofObject: aContext
		withValue: (self withSmallIntegerTags: 0).
	self assert: (objectMemory isIntegerObject: (objectMemory fetchPointer: SenderIndex ofObject: aContext)).
	self assert: (self frameOfMarriedContext: aContext) = page baseFP.
	self assert: (self validStackPageBaseFrame: page).
	^page
]

{ #category : #'frame access' }
StackInterpreter >> makeContextSnapshotSafe: ctxt [
	"Convert married contexts to widowed contexts, and in the CoInterpreter,
	 map any machine code pcs to bytecode pcs, and then nil all slots beyond
	 top of stack, so that the context can be resumed on any VM."
	<inline: false>
	self assert: (objectMemory isContext: ctxt).
	"The stack pages have already been discarded.  Any remaining married contexts are actually widows."
	(self isMarriedOrWidowedContext: ctxt)
		ifTrue: [self markContextAsDead: ctxt]
		ifFalse: [self ensureContextHasBytecodePC: ctxt].
	 "Fill slots beyond top of stack with nil"
	 (self fetchStackPointerOf: ctxt) + CtxtTempFrameStart
		to: (objectMemory numSlotsOf: ctxt) - 1
		do: [:i |
			 objectMemory
				storePointerUnchecked: i
				ofObject: ctxt
				withValue: objectMemory nilObject]
]

{ #category : #utilities }
StackInterpreter >> makePointwithxValue: xValue yValue: yValue [
	"make a Point xValue@yValue.
	 We know both will be integers so no value nor root checking is needed"
	| pointResult |
	pointResult := objectMemory eeInstantiateSmallClass: (objectMemory splObj: ClassPoint) numSlots: YIndex + 1.
	objectMemory storePointerUnchecked: XIndex ofObject: pointResult withValue: (objectMemory integerObjectOf: xValue).
	objectMemory storePointerUnchecked: YIndex ofObject: pointResult withValue: (objectMemory integerObjectOf: yValue).
	^pointResult
]

{ #category : #'object memory support' }
StackInterpreter >> mapInterpreterOops [
	"Map all oops in the interpreter's state to their new values 
	 during garbage collection or a become: operation."
	"Assume: All traced variables contain valid oops."
	<inline: false>
	self mapStackPages.
	self mapMachineCode: self getGCMode.
	self mapTraceLogs.
	self mapVMRegisters.
	self mapProfileState.
	self remapCallbackState.
	(tempOop ~= 0
	 and: [objectMemory shouldRemapOop: tempOop]) ifTrue:
		[tempOop := objectMemory remapObj: tempOop].
	(tempOop2 ~= 0
	 and: [objectMemory shouldRemapOop: tempOop2]) ifTrue:
		[tempOop2 := objectMemory remapObj: tempOop2]
]

{ #category : #'object memory support' }
StackInterpreter >> mapMachineCode: theGCMode [
	<inline: true>
	"This is a no-op in the StackVM"
]

{ #category : #'object memory support' }
StackInterpreter >> mapProfileState [
	(objectMemory shouldRemapObj: profileProcess) ifTrue:
		[profileProcess := objectMemory remapObj: profileProcess].
	(objectMemory shouldRemapObj: profileMethod) ifTrue:
		[profileMethod := objectMemory remapObj: profileMethod].
	(objectMemory shouldRemapObj: profileSemaphore) ifTrue:
		[profileSemaphore := objectMemory remapObj: profileSemaphore].
	"The longRunningPrimitiveCheckMethod (LRPCM) is sampled in an interrupt.  Be very careful with it.
	  If longRunningPrimitiveCheckSequenceNumber (LRPCSN) = statCheckForEvents then LRPCM has
	  been recenty sampled and could be mapped or not, but it must be newMethod and we can simply
	  copy newMethod.  If LRPCSN ~= statCheckForEvents then LRPCM must be some extant object and
	  needs to be remapped."
	self sqLowLevelMFence.
	longRunningPrimitiveCheckMethod ifNotNil:
		[longRunningPrimitiveCheckSequenceNumber = statCheckForEvents
			ifTrue: [longRunningPrimitiveCheckMethod := newMethod]
			ifFalse:
				[(objectMemory shouldRemapObj: longRunningPrimitiveCheckMethod) ifTrue:
					[longRunningPrimitiveCheckMethod := self remapObj: longRunningPrimitiveCheckMethod]].
		 self sqLowLevelMFence].
	longRunningPrimitiveCheckSemaphore ifNotNil:
		[(objectMemory shouldRemapObj: longRunningPrimitiveCheckSemaphore) ifTrue:
			[longRunningPrimitiveCheckSemaphore := objectMemory remapObj: longRunningPrimitiveCheckSemaphore]]
]

{ #category : #'object memory support' }
StackInterpreter >> mapStackPages [
	<inline: #never>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #theIPPtr type: #'char *'>
	| numLivePages |
	numLivePages := 0.
	0 to: numStackPages - 1 do:
		[:i| | thePage theSP theFP callerFP theIPPtr theIP oop |
		thePage := stackPages stackPageAt: i.
		thePage isFree ifFalse:
			[self assert: (self ifCurrentStackPageHasValidHeadPointers: thePage).
			 numLivePages := numLivePages + 1.
			 theSP := thePage headSP.
			 theFP := thePage  headFP.
			 "Skip the instruction pointer on top of stack of inactive pages."
			 thePage = stackPage
				ifTrue: [theIPPtr := 0]
				ifFalse:
					[theIPPtr := theSP.
					 theSP := theSP + objectMemory wordSize].
			[self assert: (thePage addressIsInPage: theFP).
			 self assert: (thePage addressIsInPage: theSP).
			 self assert: (theIPPtr = 0 or: [thePage addressIsInPage: theIPPtr]).
			 [theSP <= (theFP + FoxReceiver)] whileTrue:
				[oop := stackPages longAt: theSP.
				 (objectMemory shouldRemapOop: oop) ifTrue:
					[stackPages longAt: theSP put: (objectMemory remapObj: oop)].
				 theSP := theSP + objectMemory wordSize].
			 (self frameHasContext: theFP) ifTrue:
				[(objectMemory shouldRemapObj: (self frameContext: theFP)) ifTrue:
					[stackPages
						longAt: theFP + FoxThisContext
						put: (objectMemory remapObj: (self frameContext: theFP))].
				 "With SqueakV3 objectMemory or SpurPlanningCompactor can't assert since object body is yet to move."
				 (objectMemory hasSpurMemoryManagerAPI
				  and: [objectMemory slidingCompactionInProgress not]) ifTrue:
					[self assert: ((self isMarriedOrWidowedContext: (self frameContext: theFP))
								  and: [(self frameOfMarriedContext: (self frameContext: theFP)) = theFP])]].
			 (objectMemory shouldRemapObj: (self frameMethod: theFP)) ifTrue:
				[theIPPtr ~= 0 ifTrue:
					[self assert: (stackPages longAt: theIPPtr) > (self frameMethod: theFP).
					 theIP := (stackPages longAt: theIPPtr) - (self frameMethod: theFP)].
				 stackPages
					longAt: theFP + FoxMethod
					put: (objectMemory remapObj: (self frameMethod: theFP)).
				 theIPPtr ~= 0 ifTrue:
					[stackPages longAt: theIPPtr put: theIP + (self frameMethod: theFP)]].
			 (callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
				[theSP := (theIPPtr := theFP + FoxCallerSavedIP) + objectMemory wordSize.
				 theFP := callerFP].
			 theSP := theFP + FoxCallerContext. "a.k.a. FoxCallerSavedIP"
			 [theSP <= thePage baseAddress] whileTrue:
				[oop := stackPages longAt: theSP.
				 (objectMemory shouldRemapOop: oop) ifTrue:
					[stackPages longAt: theSP put: (objectMemory remapObj: oop)].
				 theSP := theSP + objectMemory wordSize]]].
	stackPages recordLivePagesOnMapping: numLivePages
]

{ #category : #'object memory support' }
StackInterpreter >> mapTraceLogs [
	"This is a no-op in the StackVM"
]

{ #category : #'object memory support' }
StackInterpreter >> mapVMRegisters [
	"Map the oops in the interpreter's vm ``registers'' to their new values 
	during garbage collection or a become: operation."
	"Assume: All traced variables contain valid oops.
	 N.B. Don't trace messageSelector and lkupClass; these are ephemeral, live
	 only during message lookup and because createActualMessageTo will not
	 cause a GC these cannot change during message lookup."
	(objectMemory shouldRemapObj: method) ifTrue:
		[instructionPointer := instructionPointer - method. "*rel to method"
		 method := objectMemory remapObj: method.
		 instructionPointer := instructionPointer + method]. "*rel to method"
	(objectMemory shouldRemapOop: newMethod) ifTrue: "maybe oop due to object-as-method"
		[newMethod := objectMemory remapObj: newMethod]
]

{ #category : #'sista bytecodes' }
StackInterpreter >> mappedBackjumpAlwaysInterrupt [
	| top offset |
	top := self internalStackTop.
	self assert: (objectMemory isIntegerObject: top).
	offset := objectMemory integerObjectOf: top.
	localIP := localIP - offset.
	self internalPop: 1.
	"+1 since this instr is 3 bytes not 2"
	self ifBackwardsCheckForEvents: 0 - offset + 1. 
	localIP := localIP - 1.
	self fetchNextBytecode
]

{ #category : #'sista bytecodes' }
StackInterpreter >> mappedDirectCall [
	"250	directCall
	literal index of the method to call on top of stack =>  (variable number of parameters)"
	|methodHeader localPrimIndex methodIndex|
	methodIndex := self internalPopStack. "Can't write this inside next line for Slang inliner"
	newMethod := self literal: (objectMemory integerValueOf: methodIndex).
	self assert: (objectMemory isCompiledMethod: newMethod).
	methodHeader := objectMemory methodHeaderOf: newMethod.
	localPrimIndex := self primitiveIndexOfMethod: newMethod header: methodHeader.
	argumentCount := self argumentCountOfMethodHeader: methodHeader.
	"The primitive function pointer is not cached in the interpreter, but it's called quickly in the JIT"
	primitiveFunctionPointer := self functionPointerFor: localPrimIndex inClass: objectMemory nilObject..
	self internalActivateNewMethod
]

{ #category : #'sista bytecodes' }
StackInterpreter >> mappedEnsureEnoughWords [
	"50	EnsureEnoughWords
	 literal which is a Smi => ret value is receiver"
	 | slots ok top |
	 top := self internalStackTop.
	 self assert: (objectMemory isIntegerObject: top).
	 slots := objectMemory integerValueOf: top.
	 self assert: slots >= 0.
	 ok := objectMemory checkForAvailableSlots: slots.
	 ok ifFalse:
		[self externalizeIPandSP.
		 self checkForEventsMayContextSwitch: true.
		 self browserPluginReturnIfNeeded.
		 self internalizeIPandSP]
]

{ #category : #'sista bytecodes' }
StackInterpreter >> mappedImmcheckDataAtPut: primIndex [
	<option: #SistaVM>
	| argIntAdjusted rec result arg1 |
	self assert: (primIndex between: 154 and: 157).
	arg1 := self internalStackValue: 1.
	rec := self internalStackValue: 2.
	self deny: ((objectMemory isOopForwarded: rec) or: [(objectMemory isImmediate: rec)]).
	self assert: (objectMemory isIntegerObject: arg1).
	argIntAdjusted := (objectMemory integerValueOf: arg1) - 1.
	self assert: argIntAdjusted >= 0.
	result := self internalStackTop.
	self internalPop: 2; internalStackTopPut: result.
	(objectMemory isImmutable: rec) ifTrue: [^self cannotAssign: result to: rec withIndex: argIntAdjusted].
	
	primIndex caseOf: {
		"154	immCheckByteAt:put:
		byte object, Smi, 8 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)"
		[154]	->	[self assert: (objectMemory isBytes: rec).
				 self assert: argIntAdjusted < (objectMemory numBytesOf: rec).
				 self assert: (objectMemory isIntegerObject: result).
				 objectMemory
					storeByte: argIntAdjusted
					ofObject: rec
					withValue: (objectMemory integerValueOf: result)].
		"155	immCheckShortAt:put:
		short object, Smi, 16 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)"
		[155]	->	[self assert: (objectMemory isShorts: rec).
				 self assert: argIntAdjusted < (objectMemory num16BitUnitsOf: rec).
				 self assert: (objectMemory isIntegerObject: result).
				 objectMemory
					storeShort16: argIntAdjusted
					ofObject: rec
					withValue: (objectMemory integerValueOf: result)].
		"156	immCheckWordAt:put:
		word object, Smi, 32 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)"
		[156]	->	[self assert: (objectMemory isWords: rec).
				 self assert: argIntAdjusted < (objectMemory num32BitUnitsOf: rec).
				 objectMemory
					storeLong32: argIntAdjusted
					ofObject: rec
					withValue: (objectMemory positive32BitValueOf: result)].
		"157	immCheckDoubleWordAt:put:
		double word object, Smi, 64 bits unsigned Smi or LargePositiveInteger => arg2 (1-based, optimised if arg1 is a constant)"
		[157]	->	[self assert: (objectMemory isLong64s: rec).
				 self assert: argIntAdjusted < (objectMemory num64BitUnitsOf: rec).
				 objectMemory
					storeLong64: argIntAdjusted
					ofObject: rec
					withValue: (objectMemory positive64BitValueOf: result)]}.
		
]

{ #category : #'sista bytecodes' }
StackInterpreter >> mappedImmcheckMaybeContextStoreCheckPointerAtPut [
	"153	immCheckMaybeContextStoreCheckPointerAt:put:
	 pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)"
	|rec argIntAdjusted result arg1|
	rec := self internalStackValue: 2.
	arg1 := self internalStackValue: 1.
	self assert: (objectMemory isIntegerObject: arg1).
	argIntAdjusted := (objectMemory integerValueOf: arg1) - 1.
	result := self internalStackTop.
	self internalPop: 3.
	self internalPush: result.
	(self isWriteMediatedContextInstVarIndex: argIntAdjusted) 
						ifFalse: [objectMemory storePointerImmutabilityCheck: argIntAdjusted ofObject: rec withValue: result]
						ifTrue: [self externalizeIPandSP.
								self externalInstVar: argIntAdjusted ofContext: rec  put: result.
								self internalizeIPandSP]
]

{ #category : #'sista bytecodes' }
StackInterpreter >> mappedImmcheckStoreCheckPointerAtPut [
	"151	immCheckStoreCheckPointerAt:put:
	 pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)"
	|rec argIntAdjusted result arg1|
	rec := self internalStackValue: 2.
	arg1 := self internalStackValue: 1.
	self assert: (objectMemory isPointers: rec).
	self assert: (objectMemory isIntegerObject: arg1).
	argIntAdjusted := (objectMemory integerValueOf: arg1) - 1.
	self assert: argIntAdjusted >= 0.
	self assert: argIntAdjusted < (objectMemory numSlotsOfAny: rec).
	result := self internalStackTop.
	self internalPop: 3.
	self internalPush: result.
	objectMemory
		storePointerImmutabilityCheck: argIntAdjusted
		ofObject: rec
		withValue: result
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTraceAndMaybeFreeStackPages: fullGCFlag [
	"Read markAndTraceStackPages:'s comment.  Finish tracing to-be-traced pages.
	 Then free any untraced pages."
	<var: #thePage type: #'StackPage *'>
	<inline: false>
	fullGCFlag ifFalse:
		[0 to: numStackPages - 1 do:
			[:i| | thePage |
			thePage := stackPages stackPageAt: i.
			self assert: (thePage trace: -1) ~= 0]. "Invalidate the trace state for assertion checks"
		^nil].

	self markAndTraceUntracedReachableStackPages.
	self freeUntracedStackPages
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTraceInterpreterOops: fullGCFlag [
	"Mark and trace all oops in the interpreter's state."
	"Assume: All traced variables contain valid oops.
	 N.B. Don't trace messageSelector and lkupClass; these are ephemeral, live
	 only during message lookup and because createActualMessageTo will not
	 cause a GC these cannot change during message lookup."
	| oop |
	"Must mark stack pages first to initialize the per-page trace
	 flags for full garbage collect before any subsequent tracing."
	self markAndTraceStackPages: fullGCFlag.
	self markAndTraceTraceLog.
	self markAndTracePrimTraceLog.
	objectMemory markAndTrace: objectMemory specialObjectsOop. "also covers nilObj, trueObj, falseObj, and compact classes"
	(objectMemory isImmediate: newMethod) ifFalse:
		[objectMemory markAndTrace: newMethod].
	self traceProfileState.
	tempOop = 0 ifFalse: [objectMemory markAndTrace: tempOop].
	tempOop2 = 0 ifFalse: [objectMemory markAndTrace: tempOop2].

	"V3 memory manager support"
	1 to: objectMemory remapBufferCount do:
		[:i | 
		oop := objectMemory remapBuffer at: i.
		(objectMemory isImmediate: oop) ifFalse: [objectMemory markAndTrace: oop]].

	"Old callback support - trace suspended callback list"
	1 to: jmpDepth do:
		[:i|
		oop := suspendedCallbacks at: i.
		(objectMemory isImmediate: oop) ifFalse:[objectMemory markAndTrace: oop].
		oop := suspendedMethods at: i.
		(objectMemory isImmediate: oop) ifFalse:[objectMemory markAndTrace: oop]]
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTraceMachineCodeOfMarkedMethods [
	"This is a no-op in the StackVM"
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTraceOrFreeMachineCode: fullGCFlag [
	"This is a no-op in the StackVM"
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTracePrimTraceLog [
	"This is a no-op in the StackVM"
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTraceStackPage: thePage [
	| theSP theFP frameRcvrOffset callerFP oop |
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #frameRcvrOffset type: #'char *'>
	<var: #callerFP type: #'char *'>
	<inline: false>

	self assert: (stackPages isFree: thePage) not.
	self assert: (self ifCurrentStackPageHasValidHeadPointers: thePage).
	self assert: thePage trace ~= StackPageTraced.
	thePage trace: StackPageTraced.

	theSP := thePage headSP.
	theFP := thePage  headFP.
	"Skip the instruction pointer on top of stack of inactive pages."
	thePage = stackPage ifFalse:
		[theSP := theSP + objectMemory wordSize].
	[frameRcvrOffset := self frameReceiverLocation: theFP.
	 [theSP <= frameRcvrOffset] whileTrue:
		[oop := stackPages longAt: theSP.
		 (objectMemory isOopForwarded: oop) ifTrue:
			[oop := objectMemory followForwarded: oop.
			 stackPages longAt: theSP put: oop].
		 (objectMemory isImmediate: oop) ifFalse:
			[objectMemory markAndTrace: oop].
		 theSP := theSP + objectMemory wordSize].
	(self frameHasContext: theFP) ifTrue:
		[self assert: (objectMemory isContext: (self frameContext: theFP)).
		 objectMemory markAndTrace: (self frameContext: theFP)].
	objectMemory markAndTrace: (self iframeMethod: theFP).
	(callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
		[theSP := theFP + FoxCallerSavedIP + objectMemory wordSize.
		 theFP := callerFP].
	theSP := theFP + FoxCallerSavedIP. "caller ip is frameCallerContext in a base frame"
	[theSP <= thePage baseAddress] whileTrue:
		[oop := stackPages longAt: theSP.
		 (objectMemory isOopForwarded: oop) ifTrue:
			[oop := objectMemory followForwarded: oop.
			 stackPages longAt: theSP put: oop].
		 (objectMemory isImmediate: oop) ifFalse:
			[objectMemory markAndTrace: oop].
		 theSP := theSP + objectMemory wordSize]
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTraceStackPages: fullGCFlag [
	"GC of pages.  Throwing away all stack pages on full GC is simple but dangerous
	 because it causes us to allocate lots of contexts immediately before a GC.
	 Reclaiming pages whose top context is not referenced is poor because it would
	 take N incrementalGCs to reclaim N unused pages.  Only the page whose top
	 context is not referred to by the bottom context of any other page would be
	 reclaimed.  Not until the next GC would the page whose top contect is the
	 previously reclaimed page's base frame's bottom context be reclaimed.

	 Better is to not mark stack pages until their contexts are encountered.  We can
	 eagerly trace the active page and the page reachable from its bottom context
	 if any, and so on.  Other pages can be marked when we encounter a married
	 context."
	| thePage context |
	<var: #thePage type: #'StackPage *'>
	<inline: false>
	objectMemory hasSpurMemoryManagerAPI ifFalse:
		[self initStackPageGC].

	"On an incremental GC simply consider all non-free stack pages to be roots."
	fullGCFlag ifFalse:
		[0 to: numStackPages - 1 do:
			[:i|
			thePage := stackPages stackPageAt: i.
			(stackPages isFree: thePage) ifFalse:
				[self markAndTraceStackPage: thePage]].
		^nil].

	"On a full GC only eagerly trace pages referenced from
	 the base of the active page, i.e. on the active stack."
	stackPage = 0 ifTrue: [^nil].
	thePage := stackPage.
	[self markAndTraceStackPage: thePage.
	 context := self frameCallerContext: thePage baseFP.
	 ((objectMemory isContext: context)
	  and: [(self isMarriedOrWidowedContext: context)
	  and: [self isStillMarriedContext: context]]) ifTrue:
		[thePage := stackPages stackPageFor:  (self frameOfMarriedContext: context).
		 self assert: (stackPages isFree: thePage) not].
	 thePage trace < StackPageTraced] whileTrue
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTraceTraceLog [
	"This is a no-op in the StackVM"
]

{ #category : #'object memory support' }
StackInterpreter >> markAndTraceUntracedReachableStackPages [
	"Trace any untraced pages"
	| thePage foundToBeTracedPage |
	<var: #thePage type: #'StackPage *'>
	<inline: false>

	[foundToBeTracedPage := false.
	0 to: numStackPages - 1 do:
		[:i|
		thePage := stackPages stackPageAt: i.
		((stackPages isFree: thePage) not
		 and: [thePage trace = StackPageReachedButUntraced]) ifTrue:
			[foundToBeTracedPage := true.
			 self markAndTraceStackPage: thePage]].
	foundToBeTracedPage] whileTrue
]

{ #category : #'frame access' }
StackInterpreter >> markContextAsDead: oop [
	"Mark the argument, which must be a context, married, widowed or single, as dead.
	 For married or widowed contexts this breaks any link to the spouse and makes the context single.
	 For all contexts, marks the context as inactive/having been returned from."
	<inline: true>
	self assert: (objectMemory isContext: oop).
	objectMemory
		storePointerUnchecked: SenderIndex ofObject: oop withValue: objectMemory nilObject;
		storePointerUnchecked: InstructionPointerIndex ofObject: oop withValue: objectMemory nilObject
]

{ #category : #'frame access' }
StackInterpreter >> marriedContext: spouseContext pointsTo: anOop stackDeltaForCurrentFrame: stackDeltaForCurrentFrame [
	"This is a helper for primitiveObjectPointsTo so it *does not* check the frameContext field because that is an implicit self-reference not present in the state ."
	| theFP thePage theSP rcvrOffset |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	<var: #rcvrOffset type: #'char *'>
	theFP := self frameOfMarriedContext: spouseContext.
	theFP = framePointer
		ifTrue: [theSP := stackPointer + (stackDeltaForCurrentFrame * objectMemory wordSize)]
		ifFalse:
			[thePage := stackPages stackPageFor: theFP.
			theSP := self findSPOf: theFP on: thePage].
	(objectMemory isIntegerObject: anOop)
		ifTrue: "Check stack and instruction pointer fields."
			[(anOop = (objectMemory integerObjectOf: (self stackPointerIndexForFrame: theFP WithSP: theSP))
			or: [anOop = (self externalInstVar: InstructionPointerIndex ofContext: spouseContext)]) ifTrue:
				[^true]]
		ifFalse: "Check method and sender fields, avoiding unnecessarily reifying sender context."
			[anOop = (self frameMethodObject: theFP) ifTrue:
				[^true].
			 (self isBaseFrame: theFP)
				ifTrue: [anOop = (self frameCallerContext: theFP) ifTrue:
							[^true]]
				ifFalse: [((self frameHasContext: (self frameCallerFP: theFP))
						and: [anOop = (self frameContext: (self frameCallerFP: theFP))]) ifTrue:
							[^true]]].
	"Now check receiver, temps and stack contents"
	rcvrOffset := self frameReceiverLocation: theFP.
	 [theSP <= rcvrOffset] whileTrue:
		[anOop = (stackPages longAt: theSP) ifTrue:
			[^true].
		 theSP := theSP + objectMemory wordSize].
	"Finally check stacked receiver (closure field or duplicate of receiver) and arguments"
	theSP := theFP + FoxCallerSavedIP + objectMemory wordSize.
	rcvrOffset := theFP + (self frameStackedReceiverOffset: theFP).
	 [theSP <= rcvrOffset] whileTrue:
		[anOop = (stackPages longAt: theSP) ifTrue:
			[^true].
		 theSP := theSP + objectMemory wordSize].
	^false
]

{ #category : #'frame access' }
StackInterpreter >> marryContextInNewStackPageAndInitializeInterpreterRegisters: aContext [
	"Establish aContext at the base of a new stackPage, make the stackPage the
	 active one and set-up the interreter registers.  This is used to boot the system
	 and bring it back after a snapshot."
	<inline: false>
	| newPage |
	<var: #newPage type: #'StackPage *'>
	self assert: stackPage = 0.
	newPage := self makeBaseFrameFor: aContext.
	self setStackPageAndLimit: newPage.
	self setStackPointersFromPage: newPage.
	self setMethod: (self iframeMethod: stackPage headFP).
	instructionPointer := self popStack
]

{ #category : #'frame access' }
StackInterpreter >> marryFrame: theFP SP: theSP [
	"Marry an unmarried frame.  This means creating a spouse context
	 initialized with a subset of the frame's state (state through the last argument)
	 that references the frame."
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<inline: false>
	^self marryFrame: theFP SP: theSP copyTemps: false
]

{ #category : #'frame access' }
StackInterpreter >> marryFrame: theFP SP: theSP copyTemps: copyTemps [
	"Marry an unmarried frame.  This means creating a spouse context
	 initialized with a subset of the frame's state that references the frame.
	 For the default closure implementation we do not need to copy temps.
	 Different closure implementations may require temps to be copied."
	| theContext methodHeader numSlots numArgs numStack closureOrNil numTemps |
	<inline: true>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	self assert: (self frameHasContext: theFP) not.

	"The SP is expected to be pointing at the last oop on the stack, not at the pc"
	self assert: (objectMemory addressCouldBeOop: (stackPages longAt: theSP)).

	methodHeader := objectMemory methodHeaderOf: (self frameMethod: theFP).
	"Decide how much of the stack to preserve in widowed contexts.  Preserving too much
	 state will potentially hold onto garbage.  Holding onto too little may mean that a dead
	 context isn't informative enough in a debugging situation.  If copyTemps is false (as it
	 is in the default closure implementation) compromise, retaining only the arguments with
	 no temporaries.  Note that we still set the stack pointer to its current value, but stack
	 contents other than the arguments are nil."
	numArgs := self frameNumArgs: theFP.
	numStack := self stackPointerIndexForFrame: theFP WithSP: theSP.

	closureOrNil := (self frameIsBlockActivation: theFP)
						ifTrue: [self pushedReceiverOrClosureOfFrame: theFP]
						ifFalse: [objectMemory nilObject].

	numSlots := (self methodHeaderIndicatesLargeFrame: methodHeader)
					ifTrue: [LargeContextSlots]
					ifFalse: [SmallContextSlots].
	theContext := objectMemory eeInstantiateMethodContextSlots: numSlots.
	self assert: numStack + ReceiverIndex <= numSlots. 
	"Mark context as married by setting its sender to the frame pointer plus SmallInteger
	 tags and the InstructionPointer to the saved fp (which ensures correct alignment
	 w.r.t. the frame when we check for validity)"
	objectMemory storePointerUnchecked: SenderIndex
		ofObject: theContext
		withValue: (self withSmallIntegerTags: theFP).
	objectMemory storePointerUnchecked: InstructionPointerIndex
		ofObject: theContext
		withValue: (self withSmallIntegerTags: (self frameCallerFP: theFP)).
	objectMemory storePointerUnchecked: StackPointerIndex
		ofObject: theContext
		withValue: (objectMemory integerObjectOf: numStack).
	objectMemory storePointerUnchecked: MethodIndex
		ofObject: theContext
		withValue: (self frameMethod: theFP).
	objectMemory storePointerUnchecked: ClosureIndex ofObject: theContext withValue: closureOrNil.
	objectMemory storePointerUnchecked: ReceiverIndex
		ofObject: theContext
		withValue: (self frameReceiver: theFP).
	"If copyTemps is false, store just the arguments.  If the frame is divorced the context
	 will have valid arguments but all temporaries will be nil."
	1 to: numArgs do:
		[:i|
		objectMemory storePointerUnchecked: ReceiverIndex + i
			ofObject: theContext "inline self temporary: i - 1 in:theFP" 
			withValue: (stackPages longAt: theFP
										+ FoxCallerSavedIP
										+ ((numArgs - i + 1) * objectMemory wordSize))].
	copyTemps ifTrue:
		[numTemps := self frameNumTemps: theFP.
		 1 to: numTemps do:
			[:i|
			objectMemory storePointerUnchecked: ReceiverIndex + i + numArgs
				ofObject: theContext
				withValue: (self temporary: i - 1 in: theFP)].
		 numArgs := numArgs + numTemps].

	numArgs + 1 to: numStack do:
		[:i|
		objectMemory storePointerUnchecked: ReceiverIndex + i
			ofObject: theContext
			withValue: objectMemory nilObject].

	self setFrameContext: theFP to: theContext.
	self setFrameHasContext: theFP.

	self assert: (self frameHasContext: theFP).
	self assert: (self frameOfMarriedContext: theContext) = theFP.
	self assert: numStack + ReceiverIndex < (objectMemory lengthOf: theContext).

	^theContext

]

{ #category : #'primitive support' }
StackInterpreter >> maybeFailForLastObjectOverwrite [
	<inline: true>
	checkAllocFiller ifTrue: 
		[(objectMemory freeStart < objectMemory scavengeThreshold
		  and: [(objectMemory longAt: objectMemory freeStart) ~= objectMemory freeStart]) ifTrue:
			[self primitiveFailFor: PrimErrWritePastObject]]
]

{ #category : #'cog jit support' }
StackInterpreter >> maybeFixClonedCompiledMethod: objOop [
	"This is a noop in the Stack VM"
	<inline: true>
]

{ #category : #'compiled methods' }
StackInterpreter >> maybeFlagMethodAsInterpreted: aMethod [
	"Convenient  noop in the StackInterpreter e.g. for sendInvokeCallbackContext:"
]

{ #category : #'primitive support' }
StackInterpreter >> maybeInlinePositive32BitIntegerFor: integerValue [
	"N.B. will *not* cause a GC.
	 integerValue is interpreted as POSITIVE, e.g. as the result of Bitmap>at:."
	<notOption: #Spur64BitMemoryManager>
	<var: 'integerValue' type: #'unsigned int'>
	| newLargeInteger |
	self deny: objectMemory hasSixtyFourBitImmediates.
       "force coercion because slang inliner sometimes incorrectly pass a signed int without converting to unsigned"
       (self cCode: [self cCoerceSimple: integerValue to: #'unsigned int']
			inSmalltalk: [integerValue bitAnd: 1 << 32 - 1]) <= objectMemory maxSmallInteger ifTrue:
		[^objectMemory integerObjectOf: integerValue].
	newLargeInteger := objectMemory
							eeInstantiateSmallClassIndex: ClassLargePositiveIntegerCompactIndex
							format: (objectMemory byteFormatForNumBytes: 4)
							numSlots: 1.
	SPURVM
		ifTrue:
			["Memory is 8 byte aligned in Spur, make sure that oversized bytes are set to zero" "eem 4/28/2016 questionable; they should never be read"
			objectMemory storeLong32: 0 ofObject: newLargeInteger withValue: (objectMemory byteSwapped32IfBigEndian: integerValue).
			objectMemory storeLong32: 1 ofObject: newLargeInteger withValue: 0]
		ifFalse: 
			[objectMemory storeLong32: 0 ofObject: newLargeInteger withValue: (objectMemory byteSwapped32IfBigEndian: integerValue)].
	^newLargeInteger
]

{ #category : #'debug support' }
StackInterpreter >> maybeLeakCheckExternalPrimCall: aMethodObj [
	"Assert-only check for leaks after external prim calls if checkForLeaks includes the GCCheckPrimCall flag.
	 This is ionly really useful from a low-level C debugger, hence no accessors for checkedPluginName."
	((objectMemory checkForLeaks anyMask: GCCheckPrimCall)
	 and: [(self isExternalPrimitiveCall: aMethodObj)
	 and: [checkedPluginName = (objectMemory fetchPointer: 0 ofObject: (self literal: 0 ofMethod: aMethodObj))]]) ifTrue:
		[objectMemory runLeakCheckerFor: GCCheckPrimCall].
	^true
]

{ #category : #'primitive support' }
StackInterpreter >> maybeMapPrimitiveFunctionPointerBackToSomethingEvaluable [
	"In the real VM primitiveFunctionPointer is either an index (for quick primitives)
	 or a proper function pointer to a primitive.  In the simulator it may be a small
	 index (corresponding to a quick primitive index), a symbol (corresponding to
	 a function pointer) or an index into the externalPrimitiveTable, or an invalid
	 address that references an evaluable in the simulatedTrampolines dictionary
	 of the Cogit.  The simulator expects dispatchFunctionPointer to be called with
	 primitiveFunctionPointer being a symbol only for internal primitives.  External
	 primitives must have their funciton pointer mapped back to an index.  This
	 method does the reverse mapping."
	<doNotGenerate>
	(self isExternalPrimitiveCall: newMethod) ifTrue: "External prims must be evaluated by the right plugin..."
		[| pfp index externalIndex |
		 pfp := primitiveFunctionPointer.
		 index := self mappedPluginEntries findFirst: [:entry| entry second == primitiveFunctionPointer].
		 self assert: index ~= 0.
		 externalIndex := 1000 + (externalPrimitiveTable object
												indexOf: index
												ifAbsent: [self error: 'entry not found']).
		 self assert: ((self pluginEntryFor: externalIndex) notNil
					   and: [(self pluginEntryFor: externalIndex) second == primitiveFunctionPointer]).
		 primitiveFunctionPointer := externalIndex ]
]

{ #category : #'primitive support' }
StackInterpreter >> maybeRetryPrimitiveOnFailure [
	"In Spur two cases of pirmitive failure are handled specially.  A primitive may fail due to validation
	 encountering a forwarder. On failure, check the accessorDepth for the primitive and if non-negative
	 scan the args to the depth, following any forwarders.  Retry the primitive if any are found.  Hence
	 lazily and transparently following forwarders on primtiive failue.  Additionally a prmitive might fail
	 due to an allocation failing.  Retry if primitives have failed with PrimErrNoMemory after running
	 first the scavenger and then on a subsequent failure, the global mark-sweep collector.  Hence lazily
	 and transparently GC on memory exhaustion."
	<inline: true>
	(objectMemory hasSpurMemoryManagerAPI and: [self failed]) ifTrue:
		[self retryPrimitiveOnFailure]
]

{ #category : #'return bytecodes' }
StackInterpreter >> maybeReturnToMachineCodeFrame [
	"Hook for the CoInterpreter to return to machine-code or
	 load the saved IP.  This is a nop in the StackInterpreter."
]

{ #category : #'debug support' }
StackInterpreter >> maybeSelectorOfMethod: methodObj [
	"Answer the selector of a method, assuming its penultimate literal is either
	 a symbol or a pointer object whose first slot references the method and
	 whose second slot is a symbol (i.e. an AdditionalMethodState).  If a Symbol
	 can't be found answer nil.  This isn't satisfactory, as it puts a lot of information
	 into the VM, but it is needed for adequate crash debugging at Cadence.
	 With full blocks as of 9/2016 the last literal of a CompiledBlock is a back pointer
	 to the enclosing block or compiled method."
	<api>
	| ultimateLiteral penultimateLiteral maybeSelector |
	self assert: (objectMemory isOopCompiledMethod: methodObj).
	ultimateLiteral := self ultimateLiteralOf: methodObj.
	(objectMemory isOopCompiledMethod: ultimateLiteral) ifTrue:
		[^self maybeSelectorOfMethod: ultimateLiteral].
	penultimateLiteral := self penultimateLiteralOf: methodObj.
	(objectMemory isWordsOrBytes: penultimateLiteral) ifTrue:
		[^(objectMemory fetchClassTagOfNonImm: penultimateLiteral)
			= (objectMemory fetchClassTagOfNonImm: (objectMemory splObj: SelectorDoesNotUnderstand)) ifTrue:
			[penultimateLiteral]].
	^((objectMemory isPointers: penultimateLiteral)
	 and: [(objectMemory numSlotsOf: penultimateLiteral) >= 2
	 and: [(objectMemory fetchPointer: 0 ofObject: penultimateLiteral) = methodObj
	 and: [maybeSelector := objectMemory fetchPointer: 1 ofObject: penultimateLiteral.
		(objectMemory isWordsOrBytes: maybeSelector)
	 and: [(objectMemory fetchClassTagOfNonImm: maybeSelector)
			= (objectMemory fetchClassTagOfNonImm: (objectMemory splObj: SelectorDoesNotUnderstand))]]]]) ifTrue:
		[maybeSelector]
]

{ #category : #'debug support' }
StackInterpreter >> maybeTraceStackOverflow [
	"nop in the stack interpreter"
]

{ #category : #accessing }
StackInterpreter >> messageSelector [
	<doNotGenerate>
	^ messageSelector
]

{ #category : #simulation }
StackInterpreter >> metaclassNumSlots [
	<doNotGenerate>
	^metaclassNumSlots
]

{ #category : #'as yet unclassified' }
StackInterpreter >> method [

	<doNotGenerate>
	^ method
]

{ #category : #accessing }
StackInterpreter >> method: oop [
	<doNotGenerate>
	method := oop
]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodArg: index [
	"Like #stackValue: but access method arguments left-to-right"
	<doNotGenerate> "Obsolete; was never used; replaced with methodReturnBool: in the VirtualMachine struct."
	self deprecated.
	index > argumentCount + 1 ifTrue:
		[self cCode: 'vm_printf("[VM]: Attempt to access method args beyond range\n")'.
		self printCallStack.
		self primitiveFail.
		^0].
	^self stackValue: argumentCount - index
]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodArgumentCount [
	^argumentCount
]

{ #category : #'compiled methods' }
StackInterpreter >> methodClassAssociationOf: methodPointer [
	<api>
	^self literal: (objectMemory literalCountOf: methodPointer) - 1 ofMethod: methodPointer
]

{ #category : #'compiled methods' }
StackInterpreter >> methodClassOf: methodPointer [
	<api>
	"Answer the method class of a method which is the value of an Association in the last literal,
	 or answer nil if there isn't one.
	 Using a read barrier here simplifies the become implementation and costs very little
	 because the class index and ValueIndex of the association almost certainly share a cache line."
	| literal |
	literal := self followLiteral: (objectMemory literalCountOf: methodPointer) - 1 ofMethod: methodPointer.
	^ (literal ~= objectMemory nilObject 
		and: [objectMemory isPointers: literal]) "filters out fullBlock last literal"
			ifTrue: 
				[self assert: (objectMemory numSlotsOf: literal) > ValueIndex.
			 	objectMemory followField: ValueIndex ofObject: literal]
			ifFalse: [objectMemory nilObject]
]

{ #category : #accessing }
StackInterpreter >> methodDictLinearSearchLimit: anInteger [ 
<doNotGenerate>
	methodDictLinearSearchLimit := anInteger
]

{ #category : #'compiled methods' }
StackInterpreter >> methodHeaderHasPrimitive: methodHeader [
	"Note: We now have 10 bits of primitive index, but they are in two places
	 for temporary backward compatibility.  The time to unpack is negligible,
	 since the derived primitive function pointer is stored in the method cache."
	^objectMemory hasSpurMemoryManagerAPI
		ifTrue: [self alternateHeaderHasPrimitiveFlag: methodHeader]
		ifFalse:
			[MULTIPLEBYTECODESETS
				ifTrue:
					[(objectMemory headerIndicatesAlternateBytecodeSet: methodHeader)
						ifTrue: [self alternateHeaderHasPrimitiveFlag: methodHeader]
						ifFalse: [methodHeader anyMask: V3PrimitiveBitsMask]]
				ifFalse:
					[methodHeader anyMask: V3PrimitiveBitsMask]]
]

{ #category : #'frame access' }
StackInterpreter >> methodHeaderIndicatesLargeFrame: methodHeader [
	<inline: true>
	^(methodHeader bitAnd: LargeContextBit) ~= 0
]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodPrimitiveIndex [
	<api>
	((objectMemory addressCouldBeObj: newMethod)
	 and: [objectMemory isCompiledMethod: newMethod]) ifFalse:
		[^-1].
	^self primitiveIndexOf: newMethod
]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodReturnBool: boolean [
	"Sets the return value for a method.  In the CoInterpreter we replace the cumbersome
	 primResult machinery."
	self pop: argumentCount+1 thenPushBool: boolean.
	^0
]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodReturnFloat: aFloat [
	"Sets the return value for a method."
	<var: 'aFloat' type: #double>
	self pop: argumentCount+1 thenPushFloat: aFloat.
	^0
]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodReturnInteger: integer [
	"Sets the return value for a method.  In the CoInterpreter we replace the cumbersome
	 primResult machinery."
	self pop: argumentCount+1 thenPushInteger: integer.
	^0
]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodReturnReceiver [
	"Sets the return value for a method"
	self pop: argumentCount.
	^0
]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodReturnString: aCString [
	"Sets the return value for a method."
	<var: 'aCString' type: #'char *'>
	self pop: argumentCount+1 thenPush: (objectMemory stringForCString: aCString).
	^0
]

{ #category : #'plugin primitive support' }
StackInterpreter >> methodReturnValue: oop [
	"Sets the return value for a method.  In the CoInterpreter we replace the cumbersome
	 primResult machinery."
	self pop: argumentCount+1 thenPush: oop.
	^0
]

{ #category : #'internal interpreter access' }
StackInterpreter >> methodUsesAlternateBytecodeSet: aMethodObj [
	<api>
	<inline: true>
	"A negative header selects the alternate bytecode set."
	^objectMemory headerIndicatesAlternateBytecodeSet: (objectMemory methodHeaderOf: aMethodObj)
]

{ #category : #'primitive support' }
StackInterpreter >> methodUsesPrimitiveErrorCode: aMethodObj [
	"Answer if aMethodObj contains a primitive and uses the primitive error code."
	<inline: true>
	| methodHeader |
	methodHeader := objectMemory methodHeaderOf: aMethodObj.
	^(self primitiveIndexOfMethod: aMethodObj header: methodHeader) > 0
	  and: [(self longStoreBytecodeForHeader: methodHeader)
			= (objectMemory
				fetchByte: (self startPCOfMethod: aMethodObj) + (self sizeOfCallPrimitiveBytecode: methodHeader)
				ofObject: aMethodObj)]
]

{ #category : #'frame access' }
StackInterpreter >> mframeCogMethod: theFP [
	self shouldNotImplement
]

{ #category : #'primitive support' }
StackInterpreter >> microsecondsToMilliseconds: microseconds [
	<var: #microseconds type: #usqLong>
	^microseconds // 1000 bitAnd: MillisecondClockMask
]

{ #category : #'debug support' }
StackInterpreter >> mnuBreak: selectorString point: selectorLength receiver: receiverOrNil [
	<doNotGenerate> "C version is in platforms/Cross/vm/dispdbg.h"
	"self shortPrintFrameAndCallers: localFP"
	| i |
	breakSelectorLength negated = selectorLength ifTrue:
		[i := breakSelectorLength negated.
		 [i > 0] whileTrue:
			[(objectMemory byteAt: selectorString + i - 1) = (breakSelector at: i) asInteger
				ifTrue: [(i := i - 1) = 0 ifTrue:
							[self changed: #byteCountText.
							 self halt: 'MNU of '
									, breakSelector,
									(receiverOrNil
										ifNotNil: [' to ', (self shortPrint: receiverOrNil)]
										ifNil: [''])]]
				ifFalse: [i := 0]]]
]

{ #category : #'debug support' }
StackInterpreter >> mnuBreakpoint: selector receiver: rcvr [
	<inline: true>
	self mnuBreak: (objectMemory firstFixedFieldOfMaybeImmediate: selector)
		point: (objectMemory lengthOfMaybeImmediate: selector)
		receiver: rcvr
]

{ #category : #initialization }
StackInterpreter >> moduleUnloaded: aModuleName [ 
	"The module with the given name was just unloaded. 
	Make sure we have no dangling references."
	<export: true>
	<var: #aModuleName type: 'char *'>
	(aModuleName strcmp: 'SurfacePlugin') = 0
		ifTrue: ["Surface plugin went away. Should never happen. But  then, who knows"
			showSurfaceFn := 0]
]

{ #category : #'frame access' }
StackInterpreter >> moveFramesIn: oldPage through: theFP toPage: newPage [
	"Move frames from the hot end of oldPage through to theFP to newPage.
	 This has the effect of making theFP a base frame which can be stored into.
	 Answer theFP's new location."
	| newSP newFP stackedReceiverOffset delta callerFP callerIP fpInNewPage offsetCallerFP theContext |
	<inline: false>
	<var: #oldPage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<var: #newPage type: #'StackPage *'>
	<var: #newSP type: #'char *'>
	<var: #newFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #fpInNewPage type: #'char *'>
	<var: #offsetCallerFP type: #'char *'>
	<var: #source type: #'char *'>
	<returnTypeC: 'char *'>
	newSP := newPage baseAddress + objectMemory wordSize.
	stackedReceiverOffset := self frameStackedReceiverOffset: theFP.
	"First move the data.  We will fix up frame pointers later."
	theFP + stackedReceiverOffset
		to: oldPage headSP
		by: objectMemory wordSize negated
		do: [:source|
			newSP := newSP - objectMemory wordSize.
			stackPages longAt: newSP put: (stackPages longAt: source)].
	"newSP = oldSP + delta => delta = newSP - oldSP"
	delta := newSP - oldPage headSP.
	newFP := newPage baseAddress - stackedReceiverOffset.
	self setHeadFP: oldPage headFP + delta andSP: newSP inPage: newPage.
	newPage baseFP: newFP.
	callerFP := self frameCallerFP: theFP.
	self assert: (self isBaseFrame: theFP) not.
	self assert: (self frameHasContext: callerFP).
	callerIP := self oopForPointer: (self frameCallerSavedIP: theFP).
	stackPages longAt: theFP + stackedReceiverOffset put: callerIP.
	self assert: (callerFP < oldPage baseAddress
				and: [callerFP > (oldPage realStackLimit - (LargeContextSlots * objectMemory bytesPerOop / 2))]).
	oldPage
		headFP: callerFP;
		headSP: theFP + stackedReceiverOffset.
	"Mark the new base frame in the new page (FoxCallerContext a.k.a. FoxCallerSavedIP)"
	stackPages longAt: newFP + FoxCallerContext put:  (self frameContext: callerFP).
	stackPages longAt: newFP + FoxSavedFP put: 0.
	"Now relocate frame pointers, updating married contexts to refer to their moved spouse frames."
	fpInNewPage := newPage headFP.
	[offsetCallerFP := self frameCallerFP: fpInNewPage.
	 offsetCallerFP ~= 0 ifTrue:
		[offsetCallerFP := offsetCallerFP + delta].
	 stackPages longAt: fpInNewPage + FoxSavedFP put: (self oopForPointer: offsetCallerFP).
	 (self frameHasContext: fpInNewPage) ifTrue:
		[theContext := self frameContext: fpInNewPage.
		 objectMemory storePointerUnchecked: SenderIndex
			ofObject: theContext
			withValue: (self withSmallIntegerTags: fpInNewPage).
		 objectMemory storePointerUnchecked: InstructionPointerIndex
			ofObject: theContext
			withValue: (self withSmallIntegerTags: offsetCallerFP)].
	 fpInNewPage := offsetCallerFP.
	 fpInNewPage ~= 0] whileTrue.
	^newFP
]

{ #category : #'internal interpreter access' }
StackInterpreter >> nacFetchStackPointerOf: aContext [
	"A version of fetchStackPointerOf: for use when objects may be forwarded.
	 Does not do an assert-check of the stack pointer being in bounds."
	| sp |
	<inline: true>
	sp := objectMemory fetchPointer: StackPointerIndex ofObject: aContext.
	(objectMemory isIntegerObject: sp) ifFalse: [^0].
	^objectMemory integerValueOf: sp
]

{ #category : #'debug printing' }
StackInterpreter >> nameOfClass: classOop [
	"Brain-damaged nameOfClass: for C VM.  Does *not* answer Foo class for metaclasses.
	 Use e.g. classIsMeta: to avoid being fooled."
	<inline: false>
	<returnTypeC: #'char *'>
	| numSlots maybeNameOop maybeThisClassOop |
	numSlots := objectMemory numSlotsOf: classOop.
	numSlots = metaclassNumSlots ifTrue:
		[maybeThisClassOop := objectMemory fetchPointer: thisClassIndex ofObject: classOop.
		(self addressCouldBeClassObj: maybeThisClassOop) ifTrue:
			[^self nameOfClass: (objectMemory fetchPointer: thisClassIndex ofObject: classOop)].
		 ^'bad class'].
	(numSlots > classNameIndex
	 and: [maybeNameOop := objectMemory fetchPointer: classNameIndex ofObject: classOop.
		objectMemory isBytes: maybeNameOop]) ifFalse:
		[^'bad class'].
	^objectMemory firstIndexableField: maybeNameOop
]

{ #category : #'internal interpreter access' }
StackInterpreter >> nativeFramePointerIn: theFP [
	"See StackInterpreter class>>initializeFrameIndices"
	<inline: false>
	<option: #LowcodeVM>
	<returnTypeC: #'char*'>
	<var: #theFP type: #'char *'>
	^ stackPages pointerAtPointer: theFP + FoxReceiver - (BytesPerWord*3)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> nativeFramePointerIn: theFP put: valueOopPointer [
	"See StackInterpreter class>>initializeFrameIndices"
	<inline: false>
	<option: #LowcodeVM>
	<returnTypeC: #'char*'>
	<var: #theFP type: #'char *'>
	<var: #valueOopPointer type: #'char*'>
	^ stackPages pointerAtPointer: theFP + FoxReceiver - (BytesPerWord*3) put: valueOopPointer
]

{ #category : #'internal interpreter access' }
StackInterpreter >> nativeFrameSignalObjectIn: theFP [
	"See StackInterpreter class>>initializeFrameIndices"
	<inline: false>
	<option: #LowcodeVM>
	<var: #theFP type: #'char *'>
	^ stackPages longAt: theFP + FoxReceiver - (BytesPerWord*3)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> nativeFrameSignalObjectIn: theFP put: oop [
	"See StackInterpreter class>>initializeFrameIndices"
	<inline: false>
	<option: #LowcodeVM>
	<var: #theFP type: #'char *'>
	^ stackPages longAt: theFP + FoxReceiver - BytesPerWord put: oop
]

{ #category : #'internal interpreter access' }
StackInterpreter >> nativePreviousStackPointerIn: theFP [
	"See StackInterpreter class>>initializeFrameIndices"
	<inline: false>
	<option: #LowcodeVM>
	<returnTypeC: #'char*'>
	<var: #theFP type: #'char *'>
	^ stackPages pointerAtPointer: theFP + FoxReceiver - (BytesPerWord*2)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> nativePreviousStackPointerIn: theFP put: valueOopPointer [
	"See StackInterpreter class>>initializeFrameIndices"
	<inline: false>
	<option: #LowcodeVM>
	<returnTypeC: #'char*'>
	<var: #theFP type: #'char *'>
	<var: #valueOopPointer type: #'char*'>
	^ stackPages pointerAtPointer: theFP + FoxReceiver - (BytesPerWord*2) put: valueOopPointer
]

{ #category : #'internal interpreter access' }
StackInterpreter >> nativeStackPointerIn: theFP [
	"See StackInterpreter class>>initializeFrameIndices"
	<inline: false>
	<option: #LowcodeVM>
	<returnTypeC: #'char*'>
	<var: #theFP type: #'char *'>
	^ stackPages pointerAtPointer: theFP + FoxReceiver - (BytesPerWord*4)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> nativeStackPointerIn: theFP put: valueOopPointer [
	"See StackInterpreter class>>initializeFrameIndices"
	<inline: false>
	<option: #LowcodeVM>
	<returnTypeC: #'char*'>
	<var: #theFP type: #'char *'>
	<var: #valueOopPointer type: #'char *'>
	^ stackPages pointerAtPointer: theFP + FoxReceiver - (BytesPerWord*4) put: valueOopPointer
]

{ #category : #'stack pages' }
StackInterpreter >> nativeStackSize [
	"4 MB native stack size"
	^ 4 *1024 * 1024
]

{ #category : #accessing }
StackInterpreter >> newMethod [
	<doNotGenerate>

	^ newMethod
]

{ #category : #accessing }
StackInterpreter >> nextProfileTick: anInteger [ 
	
	<doNotGenerate>
	nextProfileTick := anInteger

]

{ #category : #'compiled methods' }
StackInterpreter >> noAssertHeaderOf: methodPointer [
	^objectMemory fetchPointer: HeaderIndex ofObject: methodPointer
]

{ #category : #'message sending' }
StackInterpreter >> noFixupSuperclassOf: classPointer [
	"No fixup version of superclassOf: that should not create heisenbugs"
	<inline: true>
	^objectMemory noFixupFollowField: SuperclassIndex ofObject: classPointer
]

{ #category : #'primitive support' }
StackInterpreter >> noInlineSigned32BitIntegerGutsFor: integerValue [
	"Answer a full 32 bit integer object for the given integer value which
	 is known not to be a SmallInteger value.  This serves to share the
	 code for creating a four byte LargeInteger in one place."
	<notOption: #Spur64BitMemoryManager>
	| newLargeInteger magnitude largeClass |
	<inline: #never>
	<var: #magnitude type: #'unsigned int'>
	self deny: objectMemory hasSixtyFourBitImmediates.
	self deny: (objectMemory isIntegerValue: integerValue).
	 integerValue < 0
		ifTrue: [largeClass := ClassLargeNegativeIntegerCompactIndex.
				magnitude := 0 asUnsignedInteger - integerValue]
		ifFalse: [largeClass := ClassLargePositiveIntegerCompactIndex.
				magnitude := integerValue].
	newLargeInteger := objectMemory
							eeInstantiateSmallClassIndex: largeClass
							format: (objectMemory byteFormatForNumBytes: 4)
							numSlots: 1.
	objectMemory storeLong32: 0 ofObject: newLargeInteger withValue: (objectMemory byteSwapped32IfBigEndian: magnitude).
	SPURVM ifTrue: "Memory is 8 byte aligned in Spur, make sure that oversized bytes are set to zero" "eem 4/28/2016 questionable; they should never be read"
		[objectMemory storeLong32: 1 ofObject: newLargeInteger withValue: 0].
	^newLargeInteger
]

{ #category : #'internal interpreter access' }
StackInterpreter >> noInlineTemporary: offset in: theFP [
	<var: #theFP type: #'char *'>
	<inline: false>
	^self temporary: offset in: theFP
]

{ #category : #'internal interpreter access' }
StackInterpreter >> noInlineTemporary: offset in: theFP put: valueOop [
	<var: #theFP type: #'char *'>
	<inline: false>
	^self temporary: offset in: theFP put: valueOop
]

{ #category : #'object memory support' }
StackInterpreter >> noMarkedContextsOnPage: thePage [
	"Answer true if there are no marked contexts on thePage."
	| theFP |
	<var: #thePage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<inline: false>
	self assert: (stackPages isFree: thePage) not.
	theFP := thePage  headFP.
	[(self frameHasContext: theFP) ifTrue:
		[self assert: (objectMemory isContext: (self frameContext: theFP)).
		 (objectMemory isMarked: (self frameContext:  theFP)) ifTrue:
			[^false]].
	(theFP := self frameCallerFP: theFP) ~= 0] whileTrue.
	^true
]

{ #category : #'send bytecodes' }
StackInterpreter >> normalSend [
	"Send a message, starting lookup with the receiver's class."
	"Assume: messageSelector and argumentCount have been set, and that 
	the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	<sharedCodeInCase: #singleExtendedSendBytecode>
	| rcvr |
	rcvr := self internalStackValue: argumentCount.
	lkupClassTag := objectMemory fetchClassTagOf: rcvr.
	self assert: lkupClassTag ~= objectMemory nilObject.
	self commonSendOrdinary
]

{ #category : #'sista bytecodes' }
StackInterpreter >> nullaryInlinePrimitive: primIndex [
	<option: #SistaVM>
	self unknownInlinePrimitive
]

{ #category : #'internal interpreter access' }
StackInterpreter >> numSlotsOfMarriedContext: aContext [
	"Answer the number of effective pointer fields in the given context."
	<inline: true>
	| contextSize |
	contextSize := self stackPointerIndexForFrame: (self frameOfMarriedContext: aContext).
	^CtxtTempFrameStart + contextSize
]

{ #category : #accessing }
StackInterpreter >> numStackPages: anInteger [ 
	<doNotGenerate>
	numStackPages := anInteger
]

{ #category : #'stack pages' }
StackInterpreter >> numStkPages [
	<inline: true>
	^numStackPages
]

{ #category : #'debug support' }
StackInterpreter >> objCouldBeClassObj: objOop [
	"Answer if objOop looks like a class object.  WIth Spur be lenient if the object doesn't
	 yet have a hash (i.e. is not yet in the classTable), and accept forwarding pointers."
	<api>
	<inline: false>
	| fieldOop |
	^(objectMemory isPointersNonImm: objOop)
	  and: [(objectMemory numSlotsOfAny: objOop) > InstanceSpecificationIndex
	  and: [fieldOop := objectMemory fetchPointer: SuperclassIndex ofObject: objOop.
			((objectMemory addressCouldBeObj: fieldOop)
			and:[ (objectMemory isPointersNonImm: fieldOop)
				or: [(objectMemory isOopForwarded: fieldOop)
					and: [objectMemory isPointers: (objectMemory followForwarded: fieldOop)]]])
	  and: [fieldOop := objectMemory fetchPointer: MethodDictionaryIndex ofObject: objOop.
			((objectMemory addressCouldBeObj: fieldOop)
			and:[ (objectMemory isPointersNonImm: fieldOop)
				or: [(objectMemory isOopForwarded: fieldOop)
					and: [objectMemory isPointers: (objectMemory followForwarded: fieldOop)]]])
	  and: [(objectMemory isIntegerObject: (objectMemory fetchPointer: InstanceSpecificationIndex ofObject: objOop))]]]]
]

{ #category : #'plugin primitive support' }
StackInterpreter >> objectArg: index [
	"Like #stackObjectValue: but access method arguments left-to-right"
	<doNotGenerate> "Obsolete; was never used; replaced with methodReturnFloat: in the VirtualMachine struct."
	| oop |
	self deprecated.
	oop := self methodArg: index.
	oop = 0 ifTrue:[^0]. "methodArg: failed"
	(objectMemory isImmediate: oop) ifTrue: [self primitiveFail. ^ nil].
	^oop
]

{ #category : #'simulation support' }
StackInterpreter >> objectMemory [
	<doNotGenerate>
	^objectMemory
]

{ #category : #initialization }
StackInterpreter >> objectMemory: anObjectMemory [
	<doNotGenerate>
	objectMemory := anObjectMemory
]

{ #category : #'debug support' }
StackInterpreter >> okayFields: oop [
	"Check if the argument is an ok object.
	 If this is a pointers object, check that its fields are all okay oops."

	| i fieldOop |
	(oop = nil or: [oop = 0]) ifTrue: [ ^true ].
	(objectMemory isIntegerObject: oop) ifTrue: [ ^true ].
	(objectMemory okayOop: oop) ifFalse: [ ^false ].
	(objectMemory oopHasOkayClass: oop) ifFalse: [ ^false ].
	((objectMemory isPointersNonImm: oop) or: [objectMemory isCompiledMethod: oop]) ifFalse: [ ^true ].
	(objectMemory isCompiledMethod: oop)
		ifTrue:
			[i := (objectMemory literalCountOf: oop) + LiteralStart - 1]
		ifFalse:
			[(objectMemory isContext: oop)
				ifTrue: [i := CtxtTempFrameStart + (self fetchStackPointerOf: oop) - 1]
				ifFalse: [i := (objectMemory lengthOf: oop) - 1]].
	[i >= 0] whileTrue: [
		fieldOop := objectMemory fetchPointer: i ofObject: oop.
		(objectMemory isIntegerObject: fieldOop) ifFalse: [
			(objectMemory okayOop: fieldOop) ifFalse: [ ^false ].
			(self oopHasOkayClass: fieldOop) ifFalse: [ ^false ].
		].
		i := i - 1.
	].
	^true
]

{ #category : #'debug support' }
StackInterpreter >> okayInterpreterObjects [

	| oopOrZero oop |
	self okayFields: objectMemory nilObject.
	self okayFields: objectMemory falseObject.
	self okayFields: objectMemory trueObject.
	self okayFields: objectMemory specialObjectsOop.
	self okayFields: messageSelector.
	self okayFields: newMethod.
	self okayFields: lkupClass.
	0 to: MethodCacheEntries - 1 by: MethodCacheEntrySize do: [ :i |
		oopOrZero := methodCache at: i + MethodCacheSelector.
		oopOrZero = 0 ifFalse: [
			self okayFields: (methodCache at: i + MethodCacheSelector).
			self okayFields: (methodCache at: i + MethodCacheClass).
			self okayFields: (methodCache at: i + MethodCacheMethod).
		].
	].
	1 to: objectMemory remapBufferCount do: [ :i |
		oop := objectMemory remapBuffer at: i.
		(objectMemory isImmediate: oop) ifFalse: [
			self okayFields: oop.
		].
	].
	self okayStackZone.
]

{ #category : #'simulation support' }
StackInterpreter >> openImageFileNamed: fileName [
	"Attempt to open fileName or fileName, '.image'"
	<doNotGenerate>
	| f |
	f := [FileStream readOnlyFileNamed: fileName]
			on: FileDoesNotExistException
			do: [:ex|
				 ((fileName endsWith: '.image') not
				  and: [(fileName, '.image') asFileReference exists]) ifFalse:
					[ex pass].
				 FileStream readOnlyFileNamed: fileName, '.image'].
	^f ifNil: [self error: 'no image found'. nil].
]

{ #category : #simulation }
StackInterpreter >> openOn: fileName [
	"(StackInterpreterSimulator new openOn: 'clonex.image') openAsMorph; run"
	<doNotGenerate>
	self openOn: fileName extraMemory: 2500000
]

{ #category : #'vm scheduling' }
StackInterpreter >> ownVM: threadIndexAndFlags [
	<api>
	<inline: false>
	"This is the entry-point for plugins and primitives that wish to reacquire the VM after having
	 released it via disownVM or callbacks that want to acquire it without knowing their ownership
	 status.  While this exists for the threaded FFI VM we use it to reset newMethod and the
	 argumentCount after a callback.

	 Answer -1 if the current thread is unknown to the VM and fails to take ownership."
	<var: 'amInVMThread' declareC: 'extern sqInt amInVMThread(void)'>
	self cppIf: COGMTVM
		ifTrue:
			[self amInVMThread ifFalse:
				[^-1]].

	self assert: ((objectMemory isOopCompiledMethod: newMethod)
				and: [(self argumentCountOf: newMethod) = argumentCount]).

	"Hack encodings of client state.  We use non-immediates (bottom three bits clear)
	 for FFI/Plugin doing
		save := self disownVM: FLAGS. ... callout ... self ownVM: save.
	 We use immediate integer (bottom bit 1) for callbacks doing
		save := self ownVM: 0. ... callback ... self disownVM: save. return to C"

	"If DisownVMForFFICall this is from the FFI plugin and we're returning from a callout."
	(threadIndexAndFlags anyMask: DisownVMForFFICall) ifTrue:
		[inFFIFlags := 0.
		 ^threadIndexAndFlags].

	"Otherwise this is a callback; stash newMethod on the stack and encode
	 argumentCount in the flags retrieved when the calback calls disownVM:."
	self assert: primFailCode = 0.
	self push: newMethod.
	^objectMemory integerObjectOf: argumentCount
]

{ #category : #'as yet unclassified' }
StackInterpreter >> page: aCogStackPage [ 
	self shouldBeImplemented.
]

{ #category : #accessing }
StackInterpreter >> pendingFinalizationSignals [
	<doNotGenerate>
	^ pendingFinalizationSignals
]

{ #category : #'debug printing' }
StackInterpreter >> penultimateLiteralOf: aMethodOop [
	<api>
	self assert: (objectMemory isOopCompiledMethod: aMethodOop).
	^self literal: (objectMemory literalCountOf: aMethodOop) - 2 ofMethod: aMethodOop
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pop2AndPushIntegerIfOK: integerResult [

	self successful ifTrue:
		[(objectMemory isIntegerValue: integerResult)
			ifTrue: [self pop: 2 thenPush: (objectMemory integerObjectOf: integerResult)]
			ifFalse: [self success: false]]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pop: nItems [
	<inline: true>
	"In the StackInterpreter stacks grow down."
	stackPointer := stackPointer + (nItems*objectMemory wordSize).
	^nil
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pop: nItems thenPush: oop [
	"In the StackInterpreter stacks grow down."
	| sp |
	<inline: true>
	<var: #sp type: #'char *'>
	stackPages longAt: (sp := stackPointer + ((nItems - 1) * objectMemory wordSize)) put: oop.
	stackPointer := sp
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pop: nItems thenPushBool: trueOrFalse [
	"In the StackInterpreter stacks grow down."
	| sp |
	<inline: true>
	<var: #sp type: #'char *'>
	stackPages
		longAt: (sp := stackPointer + ((nItems - 1) * objectMemory wordSize))
		put: (objectMemory booleanObjectOf: trueOrFalse).
	stackPointer := sp
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pop: nItems thenPushFloat: f [
	"In the StackInterpreter stacks grow down."
	| sp |
	<inline: true>
	<var: #f type: #double>
	<var: #sp type: #'char *'>
	stackPages
		longAt: (sp := stackPointer + ((nItems - 1) * objectMemory wordSize))
		put: (objectMemory floatObjectOf: f).
	stackPointer := sp
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pop: nItems thenPushInteger: integerVal [
	"lots of places pop a few items off the stack and then push an integer. Make it convenient.
	 In the StackInterpreter stacks grow down."
	| sp |
	<var: #sp type: #'char *'>
	stackPages
		longAt: (sp := stackPointer + ((nItems - 1) * objectMemory wordSize))
		put: (objectMemory integerObjectOf: integerVal).
	stackPointer := sp
]

{ #category : #'primitive support' }
StackInterpreter >> popFloat [
	<returnTypeC: #double>
	^objectMemory floatValueOf: self popStack
]

{ #category : #'internal interpreter access' }
StackInterpreter >> popPos32BitInteger [
	"May set successFlag, and return false if not valid"

	| top |
	top := self popStack.
	^ self positive32BitValueOf: top
]

{ #category : #'internal interpreter access' }
StackInterpreter >> popStack [
	"In the StackInterpreter stacks grow down."
	<api>
	| top |
	<inline: true>
	top := stackPages longAt: stackPointer.
	stackPointer := stackPointer + objectMemory wordSize.
	^top
]

{ #category : #'stack bytecodes' }
StackInterpreter >> popStackBytecode [

	self fetchNextBytecode.
	self internalPop: 1.

]

{ #category : #'primitive support' }
StackInterpreter >> positive32BitIntegerFor: integerValue [
	"integerValue is interpreted as POSITIVE, e.g. as the result of Bitmap>at:.
	 N.B.  Returning in each arm separately enables Slang inlining.
	 /Don't/ return the ifTrue:ifFalse: unless Slang inlining of conditionals is fixed."
	<inline: true>
	<var: 'integerValue' type: #'unsigned int'>
	objectMemory hasSixtyFourBitImmediates
		ifTrue:
			[^objectMemory integerObjectOf: (integerValue asUnsignedInteger bitAnd: 16rFFFFFFFF)]
		ifFalse:
			[^self maybeInlinePositive32BitIntegerFor: integerValue]
]

{ #category : #'primitive support' }
StackInterpreter >> positive64BitIntegerFor: integerValue [
	<api>
	<var: 'integerValue' type: #usqLong>
	<var: 'highWord' type: #'unsigned int'>
	"Answer a Large Positive Integer object for the given integer value.  N.B. will *not* cause a GC."
	| newLargeInteger highWord sz |
	objectMemory hasSixtyFourBitImmediates
		ifTrue:
			[(self cCode: [integerValue] inSmalltalk: [integerValue bitAnd: 1 << 64 - 1]) <= objectMemory maxSmallInteger ifTrue:
				[^objectMemory integerObjectOf: integerValue].
			 sz := 8]
		ifFalse:
			[(highWord := integerValue >> 32) = 0 ifTrue:
				[^self positive32BitIntegerFor: integerValue].
			 sz := 5.
			 (highWord := highWord >> 8) = 0 ifFalse:
				[sz := sz + 1.
				 (highWord := highWord >> 8) = 0 ifFalse:
					[sz := sz + 1.
					 (highWord := highWord >> 8) = 0 ifFalse:[sz := sz + 1]]]].
	newLargeInteger := objectMemory
							eeInstantiateSmallClassIndex: ClassLargePositiveIntegerCompactIndex
							format: (objectMemory byteFormatForNumBytes: sz)
							numSlots: 8 / objectMemory bytesPerOop.
	objectMemory storeLong64: 0 ofObject: newLargeInteger withValue: (objectMemory byteSwapped64IfBigEndian: integerValue).
	^newLargeInteger

]

{ #category : #'callback support' }
StackInterpreter >> positiveMachineIntegerFor: value [
	<var: #value type: #'usqIntptr_t'>
	<inline: false>
	| resultObj |
	objectMemory wordSize = 8
		ifTrue: [resultObj := self positive64BitIntegerFor: value]
		ifFalse: [resultObj := self positive32BitIntegerFor: value].
	^resultObj
]

{ #category : #'object memory support' }
StackInterpreter >> postBecomeAction: theBecomeEffectsFlags [
	objectMemory hasSpurMemoryManagerAPI ifTrue:
		[self spurPostBecomeAction: theBecomeEffectsFlags]
]

{ #category : #'object memory support' }
StackInterpreter >> postGCAction: gcModeArg [
	"Signal the gc semaphore, and inform the display subsystem if the display bitmap has moved."

	self signalSemaphoreWithIndex: gcSemaphoreIndex.
	self postGCUpdateDisplayBits
]

{ #category : #'object memory support' }
StackInterpreter >> postGCUpdateDisplayBits [
	"Update the displayBits after a GC may have moved it.
	 Answer if the displayBits appear valid"
	<inline: false>
	| displayObj bitsOop bitsNow |
	displayObj := objectMemory splObj: TheDisplay.
	((objectMemory isPointers: displayObj)
	 and: [(objectMemory lengthOf: displayObj) >= 4
	 and: [objectMemory isWordsOrBytes: (bitsOop := objectMemory fetchPointer: 0 ofObject: displayObj)]]) ifFalse:
		[^false].

	(objectMemory hasSpurMemoryManagerAPI
	 and: [objectMemory isPinned: bitsOop]) ifFalse:
		[bitsNow := self cCode: [objectMemory firstIndexableField: bitsOop]
					inSmalltalk: [(objectMemory firstIndexableField: bitsOop) asInteger].
		 displayBits ~= bitsNow ifTrue:
			[displayBits := bitsNow.
			 self ioNoteDisplayChanged: displayBits width: displayWidth height: displayHeight depth: displayDepth]].
	^true
]

{ #category : #'object memory support' }
StackInterpreter >> preBecomeAction [
	"Need to write back the frame pointers unless all pages are free (as in snapshot)"
	stackPage ~= 0 ifTrue:
		[self externalWriteBackHeadFramePointers]
]

{ #category : #'object memory support' }
StackInterpreter >> preGCAction: gcModeArg [
	"Need to write back the frame pointers unless all pages are free (as in snapshot)"
	stackPage ~= 0 ifTrue:
		[self externalWriteBackHeadFramePointers].
	(gcModeArg = GCModeFull
	 and: [objectMemory hasSpurMemoryManagerAPI]) ifTrue:
		[self flushMethodCache]
]

{ #category : #accessing }
StackInterpreter >> preemptionYields [
	
	^ preemptionYields
]

{ #category : #accessing }
StackInterpreter >> preemptionYields: aValue [ 
	preemptionYields := aValue
]

{ #category : #accessing }
StackInterpreter >> primFailCode [
	<doNotGenerate>
	^ primFailCode 
]

{ #category : #'primitive support' }
StackInterpreter >> primitiveAccessorDepthForExternalPrimitiveMethod: methodObj [
	^objectMemory integerValueOf:
		(objectMemory
			fetchPointer: 2
			ofObject: (self literal: 0 ofMethod: methodObj))
]

{ #category : #'I/O primitives' }
StackInterpreter >> primitiveEventProcessingControl [
	"With 0 args answers whether ioProcessEvents is enabled and being called.
	 With 1 arg expects a boolean which will enable ioProcessEvents if true and
	 disable it if false, answering its previous state."
	<export: true>
	| enabled |
	enabled := inIOProcessEvents >= 0.
	argumentCount = 0 ifTrue:
		[^self pop: 1 thenPushBool: enabled].
	argumentCount = 1 ifTrue:
		[self stackTop = objectMemory trueObject
			ifTrue: [inIOProcessEvents < 0 ifTrue:
					[inIOProcessEvents := 0]]
			ifFalse:
				[self stackTop = objectMemory falseObject
					ifTrue: [inIOProcessEvents := -1]
					ifFalse: [self primitiveFailFor: PrimErrBadArgument.
							^self]].
		 ^self pop: 2 thenPushBool: enabled].
	self primitiveFailFor: PrimErrBadNumArgs
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatAdd: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory loadFloatOrIntFrom: rcvrOop.
	arg := objectMemory loadFloatOrIntFrom: argOop.
	self successful ifTrue:
		[self pop: 2 thenPushFloat: rcvr + arg]
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatDivide: rcvrOop byArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory loadFloatOrIntFrom: rcvrOop.
	arg := objectMemory loadFloatOrIntFrom: argOop.
	self success: arg ~= 0.0.
	self successful ifTrue:
		[self pop: 2 thenPushFloat: rcvr / arg]
]

{ #category : #'comparison float primitives' }
StackInterpreter >> primitiveFloatEqual: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory loadFloatOrIntFrom: rcvrOop.
	arg := objectMemory loadFloatOrIntFrom: argOop.
	^rcvr = arg
]

{ #category : #'comparison float primitives' }
StackInterpreter >> primitiveFloatGreater: rcvrOop thanArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory loadFloatOrIntFrom: rcvrOop.
	arg := objectMemory loadFloatOrIntFrom: argOop.
	^rcvr > arg
]

{ #category : #'comparison float primitives' }
StackInterpreter >> primitiveFloatGreaterOrEqual: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory loadFloatOrIntFrom: rcvrOop.
	arg := objectMemory loadFloatOrIntFrom: argOop.
	^rcvr >= arg
]

{ #category : #'comparison float primitives' }
StackInterpreter >> primitiveFloatLess: rcvrOop thanArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory loadFloatOrIntFrom: rcvrOop.
	arg := objectMemory loadFloatOrIntFrom: argOop.
	^rcvr < arg
]

{ #category : #'comparison float primitives' }
StackInterpreter >> primitiveFloatLessOrEqual: rcvrOop toArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory loadFloatOrIntFrom: rcvrOop.
	arg := objectMemory loadFloatOrIntFrom: argOop.
	^rcvr <= arg
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatMultiply: rcvrOop byArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory loadFloatOrIntFrom: rcvrOop.
	arg := objectMemory loadFloatOrIntFrom: argOop.
	self successful ifTrue:
		[self pop: 2 thenPushFloat: rcvr * arg]
]

{ #category : #'arithmetic float primitives' }
StackInterpreter >> primitiveFloatSubtract: rcvrOop fromArg: argOop [
	| rcvr arg |
	<var: #rcvr type: #double>
	<var: #arg type: #double>

	rcvr := objectMemory loadFloatOrIntFrom: rcvrOop.
	arg := objectMemory loadFloatOrIntFrom: argOop.
	self successful ifTrue:
		[self pop: 2 thenPushFloat: rcvr - arg]
]

{ #category : #accessing }
StackInterpreter >> primitiveFunctionPointer [
	^ primitiveFunctionPointer
]

{ #category : #'compiled methods' }
StackInterpreter >> primitiveIndexOf: methodPointer [
	<api>
	^self primitiveIndexOfMethod: methodPointer header: (objectMemory methodHeaderOf: methodPointer)
]

{ #category : #'compiled methods' }
StackInterpreter >> primitiveIndexOfMethod: theMethod header: methodHeader [
	"Note: With the Squeak V3 format we now have 10 bits of primitive index, but they are
	 in two places for temporary backward compatibility.  The time to unpack is negligible,
	 since the derived primitive function pointer is stored in the method cache.  With the
	 Spur format we assume a 3-byte CallPrimitive with a little-endian 16-bit primitive index."
	<api>
	<inline: true>
	| firstBytecode |
	^objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[(self alternateHeaderHasPrimitiveFlag: methodHeader)
				ifTrue:
					[firstBytecode := self firstBytecodeOfAlternateHeader: methodHeader method: theMethod.
					 (objectMemory byteAt: firstBytecode + 1) + ((objectMemory byteAt: firstBytecode + 2) << 8)]
				ifFalse:
					[0]]
		ifFalse:
			[MULTIPLEBYTECODESETS
				ifTrue:
					[(objectMemory headerIndicatesAlternateBytecodeSet: methodHeader)
						ifTrue:
							[(self alternateHeaderHasPrimitiveFlag: methodHeader)
								ifTrue:
									[firstBytecode := self firstBytecodeOfAlternateHeader: methodHeader method: theMethod.
									 (objectMemory byteAt: firstBytecode + 1) + ((objectMemory byteAt: firstBytecode + 2) << 8)]
								ifFalse:
									[0]]
						ifFalse:
							[| primBits |
							 primBits := objectMemory integerValueOf: methodHeader.
							 (primBits bitAnd: 16r1FF) + (primBits >> 19 bitAnd: 16r200)]]
				ifFalse:
					[| primBits |
					 primBits := objectMemory integerValueOf: methodHeader.
					 (primBits bitAnd: 16r1FF) + (primBits >> 19 bitAnd: 16r200)]]
]

{ #category : #'control primitives' }
StackInterpreter >> primitiveObject: actualReceiver perform: selector withArguments: argumentArray lookedUpIn: lookupClassOrNil [
	"Common routine used by perform:withArgs:, perform:withArgs:inSuperclass:,
	 object:perform:withArgs:inClass: et al.  Answer nil on success.

	 NOTE:  The case of doesNotUnderstand: is not a failure to perform.
	 The only failures are arg types and consistency of argumentCount.

	 Since we're in the stack VM we can assume there is space to push the arguments
	 provided they are within limits (max argument count is 15).  We can therefore deal
	 with the arbitrary amount of state to remove from the stack (lookup class, selector,
	 mirror receiver) and arbitrary argument orders by deferring popping anything until
	 we know whether the send has succeeded.  So on failure we merely have to remove
	 the actual receiver and arguments pushed, and on success we have to slide the actual
	 receiver and arguments down to replace the original ones."
	<inline: true>
	| arraySize performArgCount delta |
	(objectMemory isArray: argumentArray) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].

	"Check if number of arguments is reasonable; MaxNumArgs isn't available
	 so just use LargeContextSize"
	arraySize := objectMemory numSlotsOf: argumentArray.
	arraySize > (LargeContextSlots - CtxtTempFrameStart) ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].

	performArgCount := argumentCount.
	"Push newMethod to save it in case of failure,
	 then push the actual receiver and the args in the array."
	self push: newMethod.
	self push: actualReceiver.
	"Copy the arguments to the stack, in case of MNU, and lookup"
	1 to: arraySize do:
		[:index| self push: (objectMemory fetchPointer: index - 1 ofObject: argumentArray)].
	argumentCount := arraySize.
	messageSelector := selector.
	self sendBreakpoint: messageSelector receiver: actualReceiver.
	self printSends ifTrue:
		[self printActivationNameForSelector: messageSelector
				startClass: (lookupClassOrNil isNil
								ifTrue: [objectMemory fetchClassOf: actualReceiver]
								ifFalse: [lookupClassOrNil]);
			cr].
	self findNewMethodInClassTag: (lookupClassOrNil isNil
										ifTrue: [objectMemory fetchClassTagOf: actualReceiver]
										ifFalse: [objectMemory classTagForClass: lookupClassOrNil]).

	"Only test CompiledMethods for argument count - any other objects playacting as CMs will have to take their chances"
	((objectMemory isOopCompiledMethod: newMethod)
	  and: [(self argumentCountOf: newMethod) ~= argumentCount]) ifTrue:
		["Restore the state by popping the array entries, the actual receiver and the saved
		  newMethod, leaving the selector and array, and fail.  N.B.  If an MNU has happened
		  then argumentCount will match newMethod, so this code will not be reached."
		 "These asserts check that an MNU has not occurred if the argumentCount doesn't match the newMethod."
		 self assert: (self stackTop = (arraySize = 0
											ifTrue: [actualReceiver]
											ifFalse: [(objectMemory fetchPointer: arraySize - 1 ofObject: argumentArray)])).
		 self assert:  argumentCount = arraySize.
		 self pop: arraySize + 1.
		 newMethod := self popStack.
		 "Must reset primitiveFunctionPointer for checkForAndFollowForwardedPrimitiveState"
		 objectMemory hasSpurMemoryManagerAPI ifTrue:
			[argumentCount := performArgCount.
			 primitiveFunctionPointer := lookupClassOrNil
												ifNil: [#primitivePerformWithArgs]
												ifNotNil: [#primitivePerformInSuperclass]].
		 ^self primitiveFailFor: PrimErrBadNumArgs].

	"Cannot fail this primitive from here-on.  Slide the actual receiver and arguments down
	 to replace the perform arguments and saved newMethod and then execute the new
	 method. Use argumentCount not arraySize because an MNU may have changed it."
	delta := objectMemory wordSize * (performArgCount + 2). "+2 = receiver + saved newMethod"
	argumentCount * objectMemory wordSize to: 0 by: objectMemory wordSize negated do:
		[:offset|
		stackPages
			longAt: stackPointer + offset + delta
			put: (stackPages longAt: stackPointer + offset)].
	self pop: performArgCount + 2.
	self executeNewMethod.
	self initPrimCall.  "Recursive xeq affects primErrorCode"
	^nil
]

{ #category : #'as yet unclassified' }
StackInterpreter >> primitiveTable [
	<doNotGenerate>
	^ primitiveTable
]

{ #category : #'debug printing' }
StackInterpreter >> print: s [
	"For testing in Smalltalk, this method should be overridden in a subclass."

	<api>
	<var: #s type: #'char *'>
	self
		cCode: 'vm_printf(s)'
		inSmalltalk: [ self subclassResponsibility ]
]

{ #category : #'debug printing' }
StackInterpreter >> printActivationNameFor: aMethod receiver: anObject isBlock: isBlock firstTemporary: maybeMessage [
	| methClass methodSel classObj |
	<inline: false>
	isBlock ifTrue:
		[self print: '[] in '].
	methClass := self findClassOfMethod: aMethod forReceiver: anObject.
	methodSel := self findSelectorOfMethod: aMethod.
	((objectMemory addressCouldBeOop: anObject)
	 and: [(objectMemory isOopForwarded: anObject) not
	 and: [self addressCouldBeClassObj: (classObj := objectMemory fetchClassOf: anObject)]])
		ifTrue:
			[(classObj = methClass or: [methClass isNil or: [methClass = objectMemory nilObject] "i.e. doits"])
				ifTrue: [self printNameOfClass: classObj count: 5]
				ifFalse:
					[self printNameOfClass: classObj count: 5.
					 self print: '('.
					 self printNameOfClass: methClass count: 5.
					 self print: ')']]
		ifFalse:
			[self cCode: '' inSmalltalk: [self halt].
			 self print: 'INVALID RECEIVER'].
	self print: '>'.
	(objectMemory addressCouldBeOop: methodSel)
		ifTrue:
			[methodSel = objectMemory nilObject
				ifTrue: [self print: '(nil)']
				ifFalse: [self printStringOf: methodSel]]
		ifFalse: [self print: 'INVALID SELECTOR'].
	(methodSel = (objectMemory splObj: SelectorDoesNotUnderstand)
	and: [(objectMemory addressCouldBeObj: maybeMessage)
	and: [(objectMemory fetchClassOfNonImm: maybeMessage) = (objectMemory splObj: ClassMessage)]]) ifTrue:
		["print arg message selector"
		methodSel := objectMemory fetchPointer: MessageSelectorIndex ofObject: maybeMessage.
		self print: ' '.
		self printStringOf: methodSel]
]

{ #category : #'debug printing' }
StackInterpreter >> printActivationNameForSelector: aSelector startClass: startClass [
	| methClass |
	<inline: false>
	(objectMemory addressCouldBeObj: startClass)
		ifTrue:
			[self findClassForSelector: aSelector
				lookupClass: startClass
				do: [:class| methClass := class].
			(methClass isNil or: [startClass = methClass])
				ifTrue:
					[self printNameOfClass: methClass count: 5.
					 self printChar: $>.
					 methClass ifNil:
						[self printStringOf: (objectMemory splObj: SelectorDoesNotUnderstand).
						 self print: ' ']]
				ifFalse:
					[self printNameOfClass: startClass count: 5.
					 self printChar: $(.
					 self printNameOfClass: methClass count: 5.
					 self printChar: $).
					 self printChar: $>]]
		ifFalse: [self print: 'INVALID CLASS'].
	(objectMemory addressCouldBeOop: aSelector)
		ifTrue:
			[(objectMemory isBytes: aSelector)
				ifTrue: [self printStringOf: aSelector]
				ifFalse: [self printOopShort: aSelector]]
		ifFalse: [self print: 'INVALID SELECTOR']
]

{ #category : #'debug printing' }
StackInterpreter >> printAllStacks [
	"Print all the stacks of all running processes, including those that are currently suspended."
	<api>
	| proc semaphoreClass mutexClass schedLists p processList |
	<inline: false>
	proc := self activeProcess.
	self printNameOfClass: (objectMemory fetchClassOf: proc) count: 5; space; printHex: proc.
	self print: ' priority '; printNum: (self quickFetchInteger: PriorityIndex ofObject: proc); cr.
	self printCallStackFP: framePointer. "first the current activation"
	schedLists := objectMemory fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	"then the runnable processes"
	p := highestRunnableProcessPriority = 0
			ifTrue: [objectMemory numSlotsOf: schedLists]
			ifFalse: [highestRunnableProcessPriority].
	p - 1 to: 0 by: -1 do:
		[:pri|
		processList := objectMemory fetchPointer: pri ofObject: schedLists.
		(self isEmptyList: processList) ifFalse:
			[self cr; print: 'processes at priority '; printNum: pri + 1.
			 self printProcsOnList: processList]].
	self cr; print: 'suspended processes'.
	semaphoreClass := objectMemory classSemaphore.
	mutexClass := objectMemory classMutex.
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[semaphoreClass := objectMemory compactIndexOfClass: semaphoreClass.
			 mutexClass := objectMemory compactIndexOfClass: mutexClass.
			 objectMemory allHeapEntitiesDo:
				[:obj| | classIdx |
				 classIdx := objectMemory classIndexOf: obj.
				 (classIdx = semaphoreClass
				  or: [classIdx = mutexClass]) ifTrue:
					[self printProcsOnList: obj]]]
		ifFalse:
			[objectMemory allObjectsDoSafely:
				[:obj| | classObj |
				 classObj := objectMemory fetchClassOfNonImm: obj.
				 (classObj = semaphoreClass
				  or: [classObj = mutexClass]) ifTrue:
					[self printProcsOnList: obj]]]
]

{ #category : #'debug printing' }
StackInterpreter >> printAtCache [
	0 to: AtCacheTotalSize - 1 by: 4 do:
		[:i | | obj sz fmt fixed |
		obj := atCache at: i + AtCacheOop.
		sz := atCache at: i + AtCacheSize.
		fmt := atCache at: i + AtCacheFmt.
		fixed := atCache at: i + AtCacheFixedFields.
		(objectMemory addressCouldBeObj: obj) ifTrue:
			[self transcript ensureCr.
			 self print: i; tab; print: (i < AtPutBase ifTrue: ['at   '] ifFalse: ['put ']);
				tab; printNum: sz; tab; printNum: fmt; tab; printNum: fixed; tab;
				shortPrintOop: obj]]
]

{ #category : #'debug printing' }
StackInterpreter >> printCallStack [
	<inline: false>
	
	self resetStackPrintedCount.
	framePointer = nil
		ifTrue: [self printCallStackOf: (objectMemory fetchPointer: SuspendedContextIndex ofObject: self activeProcess)]
		ifFalse: [self printCallStackFP: framePointer]
]

{ #category : #'debug printing' }
StackInterpreter >> printCallStackFP: theFP [
	| context |
	<inline: false>
	<var: #theFP type: #'char *'>

	self resetStackPrintedCount.
	context := self shortReversePrintFrameAndCallers: theFP.
	[context = objectMemory nilObject] whileFalse:
		[(self isMarriedOrWidowedContext: context)
			ifTrue:
				[(self checkIsStillMarriedContext: context currentFP: framePointer) ifFalse:
					[self shortPrintContext: context.
					 ^nil].
				 context := self shortReversePrintFrameAndCallers: (self frameOfMarriedContext: context)]
			ifFalse:
				[context := self printContextCallStackOf: context]]
]

{ #category : #'debug printing' }
StackInterpreter >> printCallStackOf: aContextOrProcessOrFrame [
	<api>
	| context |
	<inline: false>
	
	self resetStackPrintedCount.
	
	(stackPages couldBeFramePointer: aContextOrProcessOrFrame) ifTrue:
		[^self printCallStackFP: (self cCoerceSimple: aContextOrProcessOrFrame to: #'char *')].
	(self couldBeProcess: aContextOrProcessOrFrame) ifTrue:
		[^self printCallStackOf: (objectMemory
									fetchPointer: SuspendedContextIndex
									ofObject: aContextOrProcessOrFrame)].
	context := aContextOrProcessOrFrame.
	[context = objectMemory nilObject] whileFalse:
		[(self isMarriedOrWidowedContext: context)
			ifTrue:
				[(self checkIsStillMarriedContext: context currentFP: framePointer) ifFalse:
					[self shortPrintContext: context.
					 ^nil].
				 context := self shortReversePrintFrameAndCallers: (self frameOfMarriedContext: context)]
			ifFalse:
				[context := self printContextCallStackOf: context]]
]

{ #category : #'debug printing' }
StackInterpreter >> printCallStackOf: aContext currentFP: currFP [
	| ctxt theFP thePage |
	<inline: false>
	<var: #currFP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>

	self resetStackPrintedCount.
	ctxt := aContext.
	[ctxt = objectMemory nilObject] whileFalse:
		[(self isMarriedOrWidowedContext: ctxt)
			ifFalse:
				[self shortPrintContext: ctxt.
				 ctxt := objectMemory fetchPointer: SenderIndex ofObject: ctxt]
			ifTrue:
				[theFP := self frameOfMarriedContext: ctxt.
				 (self checkIsStillMarriedContext: ctxt currentFP: currFP)
					ifTrue:
						[thePage := stackPages stackPageFor: theFP.
						 (stackPages isFree: thePage) ifTrue:
							[self printHexPtr: theFP; print: ' is on a free page?!'; cr.
							 ^nil].
						 self shortPrintFrameAndCallers: theFP.
						 theFP := thePage baseFP.
						 ctxt := self frameCallerContext: theFP.
						 (objectMemory isForwarded: ctxt) ifTrue:
							[ctxt := objectMemory followForwarded: ctxt]]
					ifFalse: [self print: 'widowed caller frame '; printHexPtr: theFP; cr.
							^nil]]]
]

{ #category : #'debug printing' }
StackInterpreter >> printChar: aByte [
	<api>
	"For testing in Smalltalk, this method should be overridden in a subclass."
	self cCode: 'vm_printf("%c", aByte)' inSmalltalk: [self putchar: aByte].
]

{ #category : #'debug printing' }
StackInterpreter >> printContext: aContext [
	| sender ip sp |
	<inline: false>
	self shortPrintContext: aContext.
	sender := objectMemory fetchPointer: SenderIndex ofObject: aContext.
	ip := objectMemory fetchPointer: InstructionPointerIndex ofObject: aContext.
	(objectMemory isIntegerObject: sender)
		ifTrue:
			[(self checkIsStillMarriedContext: aContext currentFP: framePointer)
				ifTrue: [self print: 'married (assuming framePointer valid)'; cr]
				ifFalse: [self print: 'widowed (assuming framePointer valid)'; cr].
			self print: 'sender   '; printNum: sender; print: ' (';
				printHexPtr: (self withoutSmallIntegerTags: sender); printChar: $); cr.
			 self print: 'ip       '; printNum: ip; print: ' (';
				printHexPtr: (self withoutSmallIntegerTags: ip); printChar: $); cr]
		ifFalse:
			[self print: 'sender   '; shortPrintOop: sender.
			 self print: 'ip       '.
			 ip = objectMemory nilObject
				ifTrue: [self shortPrintOop: ip]
				ifFalse: [self printNum: ip; print: ' ('; printNum: (objectMemory integerValueOf: ip); space; printHex: (objectMemory integerValueOf: ip); printChar: $); cr]].
	sp := objectMemory fetchPointer: StackPointerIndex ofObject: aContext.
	sp := sp min: (objectMemory lengthOf: aContext) - ReceiverIndex.
	self print: 'sp       '; printNum: sp; print: ' ('; printNum: (objectMemory integerValueOf: sp); printChar: $); cr.
	self print: 'method   '; printMethodFieldForPrintContext: aContext.
	self print: 'closure  '; shortPrintOop: (objectMemory fetchPointer: ClosureIndex ofObject: aContext).
	self print: 'receiver '; shortPrintOop: (objectMemory fetchPointer: ReceiverIndex ofObject: aContext).
	sp := objectMemory integerValueOf: sp.
	1 to: sp do:
		[:i|
		self print: '       '; printNum: i; space; shortPrintOop: (objectMemory fetchPointer: ReceiverIndex + i ofObject: aContext)]
]

{ #category : #'debug printing' }
StackInterpreter >> printContextCallStackOf: aContext [
	"Print the call stack of aContext until it links to a frame."
	| ctxt |
	<inline: false>
	ctxt := aContext.
	[ctxt = objectMemory nilObject or: [self isMarriedOrWidowedContext: ctxt]] whileFalse:
		[self shortPrintContext: ctxt.
		 ctxt := objectMemory fetchPointer: SenderIndex ofObject: ctxt].
	^ctxt
]

{ #category : #printing }
StackInterpreter >> printDecodeMethodHeaderOop: methodHeaderOop [
	self printOopShort: methodHeaderOop.
	(self methodHeaderHasPrimitive: methodHeaderOop) ifTrue:
		[self print: ' hasPrim'].
	(self methodHeaderIndicatesLargeFrame: methodHeaderOop) ifTrue:
		[self print: ' largeFrame'].
	(SistaVM and: [self isOptimizedMethodHeader: methodHeaderOop]) ifTrue:
		[self print: ' optimized'].
	(MULTIPLEBYTECODESETS and: [(objectMemory integerValueOf: methodHeaderOop) < 0]) ifTrue:
		[self print: ' altSet'].

	self print: ' nLits '; printNum: (objectMemory literalCountOfMethodHeader: methodHeaderOop);
		print: ' nArgs '; printNum: (self argumentCountOfMethodHeader: methodHeaderOop);
		print: ' nTemps '; printNum: (self temporaryCountOfMethodHeader: methodHeaderOop)
]

{ #category : #'debug printing' }
StackInterpreter >> printExternalHeadFrame [
	<inline: false>
	self printFrame: framePointer WithSP: stackPointer
]

{ #category : #'debug printing' }
StackInterpreter >> printFloat: f [
	"For testing in Smalltalk, this method should be overridden in a subclass."
	<cmacro: '(f) vm_printf("%g", f)'>
	self print: f
]

{ #category : #'debug printing' }
StackInterpreter >> printFrame: theFP [
	| thePage frameAbove theSP |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #frameAbove type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	(stackPages couldBeFramePointer: theFP) ifFalse:
		[((objectMemory addressCouldBeObj: theFP asInteger)
		  and: [(objectMemory isInMemory: theFP asInteger)
		  and: [(objectMemory isContextNonImm: theFP asInteger)
		  and: [(self checkIsStillMarriedContext: theFP asInteger currentFP: framePointer)]]]) ifTrue:
			[^self printFrame: (self frameOfMarriedContext: theFP asInteger)].
		self printHexPtr: theFP; print: ' is not in the stack zone?!'; cr.
		 ^nil].
	frameAbove := nil.
	theFP = framePointer
		ifTrue: [theSP := stackPointer]
		ifFalse:
			[thePage := stackPages stackPageFor: theFP.
			 (stackPages isFree: thePage) ifTrue:
				[self printHexPtr: theFP; print: ' is on a free page?!'; cr.
				 ^nil].
			 (thePage ~= stackPage
			  and: [theFP = thePage headFP])
				ifTrue: [theSP := thePage headSP]
				ifFalse:
					[frameAbove := self safeFindFrameAbove: theFP
										on: thePage
										startingFrom: ((thePage = stackPage
														and: [framePointer
																between: thePage realStackLimit
																and: thePage baseAddress])
														ifTrue: [framePointer]
														ifFalse: [thePage headFP]).
					 theSP := frameAbove ifNotNil:
								[self frameCallerSP: frameAbove]]].
	theSP ifNil:
		[self print: 'could not find sp; using bogus value'; cr.
		 theSP := self frameReceiverLocation: theFP].
	self printFrame: theFP WithSP: theSP.
	frameAbove ifNotNil:
		[self printFrameThing: 'frame pc' at: frameAbove + FoxCallerSavedIP]
]

{ #category : #'debug printing' }
StackInterpreter >> printFrame: theFP WithSP: theSP [
	<api>
	| theMethod numArgs topThing |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #addr type: #'char *'>
	self cCode: '' inSmalltalk: [self transcript ensureCr].
	(stackPages couldBeFramePointer: theFP) ifFalse:
		[self printHexPtr: theFP; print: ' is not in the stack zone?!'; cr.
		 ^nil].
	theMethod := self frameMethod: theFP.
	numArgs := self frameNumArgs: theFP.
	self shortPrintFrame: theFP.
	self printFrameOop: 'rcvr/clsr'
		at: theFP + FoxCallerSavedIP + ((numArgs + 1) * objectMemory wordSize).
	numArgs to: 1 by: -1 do:
		[:i| self printFrameOop: 'arg' at: theFP + FoxCallerSavedIP + (i * objectMemory wordSize)].
	self printFrameThing: 'cllr ip/ctxt' at: theFP + FoxCallerSavedIP.
	self printFrameThing: 'saved fp' at: theFP + FoxSavedFP.
	self printFrameOop: 'method' at: theFP + FoxMethod.
	self printFrameFlagsForFP: theFP.
	self printFrameThing: 'context' at: theFP + FoxThisContext.
	self printFrameOop: 'receiver' at: theFP + FoxReceiver.
	topThing := stackPages longAt: theSP.
	(topThing >= theMethod
	 and: [topThing <= (theMethod + (objectMemory sizeBitsOfSafe: theMethod))])
		ifTrue:
			[theFP + FoxReceiver - objectMemory wordSize to: theSP + objectMemory wordSize by: objectMemory wordSize negated do:
				[:addr|
				self printFrameOop: 'temp/stck' at: addr].
			self printFrameThing: 'frame ip' at: theSP]
		ifFalse:
			[theFP + FoxReceiver - objectMemory wordSize to: theSP by: objectMemory wordSize negated do:
				[:addr|
				self printFrameOop: 'temp/stck' at: addr]]
]

{ #category : #'debug printing' }
StackInterpreter >> printFrameAndCallers: theFP SP: theSP [
	self printFrameAndCallers: theFP SP: theSP short: false
]

{ #category : #'debug printing' }
StackInterpreter >> printFrameAndCallers: theFP SP: theSP short: printShort [
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	(stackPages couldBeFramePointer: theFP) ifFalse: [^nil].
	(self isBaseFrame: theFP) ifFalse:
		[self printFrameAndCallers: (self frameCallerFP: theFP)
			SP: (self frameCallerSP: theFP)
			short: printShort].
	printShort ifTrue:
		[self shortPrintFrame: theFP.
		 ^nil].
	self cr.
	self printFrame: theFP WithSP: theSP
]

{ #category : #'debug printing' }
StackInterpreter >> printFrameFlagsForFP: theFP [
	| address it |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #address type: #'char *'>
	address := theFP + FoxFrameFlags.
	it := stackPages longAt: address.
	self printHexPtr: address;
		print: ':       flags: ';
		printHex: it.
	it ~= 0 ifTrue:
		[self printChar: $=; printNum: it].
	self print: '  numArgs: '; printNum: (self frameNumArgs: theFP);
		print: ((self frameHasContext: theFP) ifTrue: [' hasContext'] ifFalse: [' noContext']);
		print: ((self frameIsBlockActivation: theFP) ifTrue: [' isBlock'] ifFalse: [' notBlock']);
		cr
]

{ #category : #'debug printing' }
StackInterpreter >> printFrameOop: name at: address [
	| it |
	<inline: false>
	<var: #name type: #'char *'>
	<var: #address type: #'char *'>
	it := stackPages longAt: address.
	self printHexPtr: address;
		printChar: $:.
	1 to: 12 - (self strlen: name) do: [:i| self printChar: $ ].
	self print: name;
		print: ': ';
		printHex: it;
		tab;
		printChar: $=;
		printOopShort: it;
		cr
]

{ #category : #'debug printing' }
StackInterpreter >> printFrameOop: name index: idx at: address [
	| it |
	<inline: false>
	<var: #name type: #'char *'>
	<var: #address type: #'char *'>
	it := stackPages longAt: address.
	self printHexPtr: address;
		printChar: $:.
	1	to: 11 - (self strlen: name) - (self log10: (idx max: 1)) floor
		do: [:i| self printChar: $ ].
	self print: name;
		printNum: idx;
		print: ': ';
		printHex: it;
		tab;
		printChar: $=;
		printOopShort: it;
		cr
]

{ #category : #'debug printing' }
StackInterpreter >> printFrameThing: name andFrame: theFP at: address [
	<var: #theFP type: #'char *'>
	| it len |
	<inline: false>
	<var: #name type: #'char *'>
	<var: #address type: #'char *'>
	it := stackPages longAt: address.
	self printHexPtr: address;
		printChar: $:.
	len := self strlen: name.
	1 to: 12 - len do: [:i| self space].
	self print: name;
		print: ': ';
		printHex: it.
	it ~= 0 ifTrue:
		[self printChar: $=.
		 it = objectMemory nilObject
			ifTrue: [self print: 'nil']
			ifFalse:
				[self printNum: it]].
	self print: ' frame: '; printHexPtr: theFP; cr
]

{ #category : #'debug printing' }
StackInterpreter >> printFrameThing: name at: address [
	| it len |
	<inline: false>
	<var: #name type: #'char *'>
	<var: #address type: #'char *'>
	it := stackPages longAt: address.
	self printHexPtr: address;
		printChar: $:.
	len := self strlen: name.
	1 to: 12 - len do: [:i| self space].
	self print: name;
		print: ': ';
		printHex: it.
	it ~= 0 ifTrue:
		[self printChar: $=.
		 it = objectMemory nilObject
			ifTrue: [self print: 'nil']
			ifFalse:
				[self printNum: it]].
	self cr
]

{ #category : #'debug printing' }
StackInterpreter >> printFramesInPage: thePage [
	<export: true> "use export: not api, so it won't be written to cointerp.h. cogit.c is unaware of StackPage"
	<inline: false>
	<var: #thePage type: #'StackPage *'>
	self printFrameAndCallers: thePage headFP SP: thePage headSP short: false
]

{ #category : #'debug printing' }
StackInterpreter >> printFramesOnStackPageListInUse [
	<export: true>
	| page |
	<inline: false>
	<var: #page type: #'StackPage *'>
	page := stackPages mostRecentlyUsedPage.
	[(stackPages isFree: page) ifFalse:
		[self print: 'page '; printHexPtrnp: (self cCode: [page] inSmalltalk: [page baseAddress]); cr.
		 self printFramesInPage: page.
		 self cr].
	 (page := page prevPage) ~= stackPages mostRecentlyUsedPage] whileTrue
]

{ #category : #'debug printing' }
StackInterpreter >> printHeadFrame [
	<inline: false>
	self printFrame: localFP WithSP: localSP
]

{ #category : #'debug printing' }
StackInterpreter >> printHex: n [
	"Print n in hex,  in the form '    0x1234', padded to a width of 10 characters
	 in 32-bits ('0x' + 8 nibbles) or 18 characters in 64-bits ('0x' + 16 nibbles)"
	<api>
	<var: #n type: #usqInt>
	| len buf |
	<var: #buf declareC: 'char buf[37]'> "large enough for a 64-bit value in hex plus the null plus 16 spaces"
	self cCode: 'memset(buf,'' '',36)' inSmalltalk: [buf := 'doh!'].
	len := self cCode: 'sprintf(buf + 2 + 2 * BytesPerWord, "0x%" PRIxSQPTR, (usqIntptr_t)(n))'.
	self cCode: 'vm_printf("%s", buf + len)'.
	len touch: buf
]

{ #category : #'debug printing' }
StackInterpreter >> printHexPtr: p [
	"Print p in hex, padded to 10 characters in the form '    0x1234'"
	<inline: true>
	<var: #p type: #'void *'>
	self printHex: (self oopForPointer: p)
]

{ #category : #'debug printing' }
StackInterpreter >> printHexPtrnp: p [
	"Print p in hex, unpadded, in the form '0x1234'"
	<inline: true>
	<var: #p type: #'void *'>
	self printHexnp: (self oopForPointer: p)
]

{ #category : #'debug printing' }
StackInterpreter >> printHexnp: n [
	<api>
	<var: #n type: #usqInt>
	"Print n in hex,  in the form '0x1234', unpadded"
	^ self cCode: 'vm_printf("0x%lx", n)'inSmalltalk: ['0x%lx' printf: n]
]

{ #category : #'debug printing' }
StackInterpreter >> printHexnpnp: n [
	<var: #n type: #usqInt>
	"Print n in hex, in the form '1234', unpadded"
	^ self cCode: 'vm_printf("%lx", n)'inSmalltalk: ['%lx' printf: n]
	
]

{ #category : #'debug printing' }
StackInterpreter >> printLikelyImplementorsOfSelector: selector [
	"Print all methods whose penultimate literal is either selector,
	 or an object whose first inst var is the method and whose
	 second is selector (e.g. an AdditionalMethodState)."
	<api>
	objectMemory allObjectsDo:
		[:obj| | methodClassAssociation |
		((objectMemory isCompiledMethod: obj)
		 and: [(self maybeSelectorOfMethod: obj) = selector]) ifTrue:
			["try and print the key of the method class association (the name of the implementing class)"
			 methodClassAssociation := self methodClassAssociationOf: obj.
			 self printHexnp: obj;
				space;
				printOopShortInner: (((objectMemory isPointers: methodClassAssociation)
									  and: [(objectMemory numSlotsOf: methodClassAssociation) >= 2])
										ifTrue: [objectMemory fetchPointer: 0 ofObject: methodClassAssociation]
										ifFalse: [methodClassAssociation]);
				cr]]
]

{ #category : #'debug printing' }
StackInterpreter >> printMethodCache [
	<api>
	self printMethodCacheFor: -1
]

{ #category : #'debug printing' }
StackInterpreter >> printMethodCacheFor: thing [
	<api>
	| n |
	n := 0.
	0 to: MethodCacheSize - 1 by: MethodCacheEntrySize do:
		[:i | | s c m p |
		s := methodCache at: i + MethodCacheSelector.
		c := methodCache at: i + MethodCacheClass.
		m := methodCache at: i + MethodCacheMethod.
		p := methodCache at: i + MethodCachePrimFunction.
		((thing = -1 or: [s = thing or: [c = thing or: [p = thing or: [m = thing]]]])
		 and: [(objectMemory addressCouldBeOop: s)
		 and: [c ~= 0
		 and: [(self addressCouldBeClassObj: c)
			or: [self addressCouldBeClassObj: (objectMemory classForClassTag: c)]]]]) ifTrue:
			[self cCode: [] inSmalltalk: [self transcript ensureCr].
			 self printNum: i; space; printHexnp: i; cr; tab.
			 (objectMemory isBytesNonImm: s)
				ifTrue: [self cCode: 'vm_printf("%" PRIxSQPTR " %.*s\n", s, (int)(numBytesOf(s)), (char *)firstIndexableField(s))'
						inSmalltalk: [self printHex: s; space; print: (self stringOf: s); cr]]
				ifFalse: [self shortPrintOop: s].
			 self tab.
			 (self addressCouldBeClassObj: c)
				ifTrue: [self shortPrintOop: c]
				ifFalse: [self printNum: c; space; shortPrintOop: (objectMemory classForClassTag: c)].
			self tab; shortPrintOop: m; tab.
			self cCode:
					[p > 1024
						ifTrue: [self printHexnp: p]
						ifFalse: [self printNum: p]]
				inSmalltalk:
					[p isSymbol ifTrue: [self print: p] ifFalse: [self printNum: p]].
			self cr]].
	n > 1 ifTrue:
		[self printNum: n; cr]
]

{ #category : #'debug printing' }
StackInterpreter >> printMethodDictionary: dictionary [
	<api>
	| methodArray |
	methodArray := objectMemory fetchPointer: MethodArrayIndex ofObject: dictionary.
	SelectorStart to: (objectMemory numSlotsOf: dictionary) - 1 do:
		[:index | | selector meth |
		 selector := objectMemory fetchPointer: index ofObject: dictionary.
		 selector ~= objectMemory nilObject ifTrue:
			[meth := objectMemory fetchPointer: index - SelectorStart ofObject: methodArray.
			 self
				printOopShort: selector;
				print: ' => ';
				printOopShort: meth;
				print: ' (';
				printHex: selector;
				print: ' => ';
				printHex: meth;
				putchar: $);
				cr]]
]

{ #category : #'debug printing' }
StackInterpreter >> printMethodDictionaryOf: behavior [
	<api>
	self printMethodDictionary: (objectMemory fetchPointer: MethodDictionaryIndex ofObject: behavior)
]

{ #category : #'debug printing' }
StackInterpreter >> printMethodFieldForPrintContext: aContext [
	<inline: true>
	self shortPrintOop: (objectMemory fetchPointer: MethodIndex ofObject: aContext)
]

{ #category : #'debug printing' }
StackInterpreter >> printMethodHeaderOop: anOop [
	"Override hook for CoInterpreter"
	<inline: true>
	^self printDecodeMethodHeaderOop: anOop
]

{ #category : #'debug printing' }
StackInterpreter >> printNameOfClass: classOop count: cnt [
	"Details: The count argument is used to avoid a possible infinite recursion if classOop is a corrupted object."
	<inline: false>
	| numSlots |
	classNameIndex ifNil:
		[self print: '??nil cnidx??'.
		 ^self].
	(classOop isNil or: [classOop = 0 or: [cnt <= 0]]) ifTrue:
		[self print: 'bad class'.
		 ^self].
	numSlots := objectMemory numSlotsOf: classOop.
	(numSlots = metaclassNumSlots
	 and: [metaclassNumSlots > thisClassIndex])
		ifTrue: [self printNameOfClass: (objectMemory fetchPointer: thisClassIndex ofObject: classOop) count: cnt - 1.
				self print: ' class']
		ifFalse:
			[numSlots <= classNameIndex
				ifTrue: [self print: 'bad class']
				ifFalse:
					[self printStringOf: (objectMemory fetchPointer: classNameIndex ofObject: classOop)]]
]

{ #category : #'debug printing' }
StackInterpreter >> printNum: n [
	"For testing in Smalltalk, this method should be overridden in a subclass."

	self cCode: 'vm_printf("%ld", (long) n)'.
]

{ #category : #'debug printing' }
StackInterpreter >> printOop: oop [
	| cls fmt lastIndex startIP bytecodesPerLine column |
	<inline: false>
	(objectMemory isImmediate: oop) ifTrue:
		[^ self shortPrintOop: oop].
	self printHex: oop.
	(objectMemory addressCouldBeObj: oop) ifFalse:
		[self print: ((oop bitAnd: objectMemory allocationUnit - 1) ~= 0
						ifTrue: [' is misaligned']
						ifFalse: [self whereIs: oop]); cr. ^self].
					
	(objectMemory isFreeObject: oop) ifTrue:
		[self print: ' is a free chunk of size '; printNum: (objectMemory sizeOfFree: oop).
		 objectMemory hasSpurMemoryManagerAPI ifTrue:
			[self print: ' 0th: '; printHex: (objectMemory fetchPointer: 0 ofFreeChunk: oop).
			 objectMemory printHeaderTypeOf: oop].
		 self cr. 
		^ self].
	(objectMemory isForwarded: oop) ifTrue:
		[self
			print: ' is a forwarded object to '; printHex: (objectMemory followForwarded: oop);
			print: ' of slot size '; printNum: (objectMemory numSlotsOfAny: oop).
		 objectMemory printHeaderTypeOf: oop.
		 self cr. ^ self].
	self print: ': a(n) '.
	self printNameOfClass: (cls := objectMemory fetchClassOfNonImm: oop) count: 5.
	cls = (objectMemory splObj: ClassFloat) ifTrue:
		[self cr; printFloat: (objectMemory dbgFloatValueOf: oop); cr. ^ self].
	fmt := objectMemory formatOf: oop.
	fmt > objectMemory lastPointerFormat ifTrue:
		[self print: ' nbytes '; printNum: (objectMemory numBytesOf: oop)].
	self cr.
	(fmt between: objectMemory firstLongFormat and: objectMemory firstCompiledMethodFormat - 1) ifTrue:
		["This will answer false if splObj: ClassAlien is nilObject"
		 (self is: oop KindOfClass: (objectMemory splObj: ClassAlien)) ifTrue:
			[self print: ' datasize '; printNum: (self sizeOfAlienData: oop).
			self print: ((self isIndirectAlien: oop)
							ifTrue: [' indirect @ ']
							ifFalse:
								[(self isPointerAlien: oop)
									ifTrue: [' pointer @ ']
									ifFalse: [' direct @ ']]).
			 ^self printHex: (self startOfAlienData: oop) asUnsignedInteger; cr].
		 (objectMemory isWordsNonImm: oop) ifTrue:
			[lastIndex := 64 min: ((objectMemory numBytesOf: oop) / objectMemory wordSize).
			 lastIndex > 0 ifTrue:
				[1 to: lastIndex do:
					[:index|
					self space; printHex: (self cCoerceSimple: (objectMemory fetchLong32: index - 1 ofObject: oop)
											to: #'unsigned int').
					(index \\ self elementsPerPrintOopLine) = 0 ifTrue:
						[self cr]].
				(lastIndex \\ self elementsPerPrintOopLine) = 0 ifFalse:
					[self cr]].
			^self].
		^self printStringOf: oop; cr].
	"this is nonsense.  apologies."
	startIP := (objectMemory lastPointerOf: oop) + objectMemory bytesPerOop - objectMemory baseHeaderSize / objectMemory bytesPerOop.
	lastIndex := 256 min: startIP.
	lastIndex > 0 ifTrue:
		[1 to: lastIndex do:
			[:index|
			self cCode: [self printHex: (objectMemory fetchPointer: index - 1 ofObject: oop); space]
				inSmalltalk: [self space; printHex: (objectMemory fetchPointer: index - 1 ofObject: oop); space.
							 self print: (self shortPrint: (objectMemory fetchPointer: index - 1 ofObject: oop))].
			(index \\ self elementsPerPrintOopLine) = 0 ifTrue:
				[self cr]].
		(lastIndex \\ self elementsPerPrintOopLine) = 0 ifFalse:
			[self cr]].
	(objectMemory isCompiledMethod: oop)
		ifFalse:
			[startIP > 64 ifTrue: [self print: '...'; cr]]
		ifTrue:
			[startIP := startIP * objectMemory wordSize + 1.
			 lastIndex := objectMemory lengthOf: oop.
			 lastIndex - startIP > 100 ifTrue:
				[lastIndex := startIP + 100].
			 bytecodesPerLine := 8.
			 column := 1.
			 startIP to: lastIndex do:
				[:index| | byte |
				column = 1 ifTrue:
					[self cCode: 'vm_printf("0x%08" PRIxSQPTR ": ", (usqIntptr_t)(oop+BaseHeaderSize+index-1))'
						inSmalltalk: [self print: (oop+objectMemory baseHeaderSize+index-1) hex; print: ': ']].
				byte := objectMemory fetchByte: index - 1 ofObject: oop.
				self cCode: 'vm_printf(" %02x/%-3d", (int)byte,(int)byte)'
					inSmalltalk: [self space; print: (byte radix: 16); printChar: $/; printNum: byte].
				column := column + 1.
				column > bytecodesPerLine ifTrue:
					[column := 1. self cr]].
			column = 1 ifFalse:
				[self cr]]
]

{ #category : #'debug printing' }
StackInterpreter >> printOopShort: oop [
	<inline: false>
	self printOopShortInner: oop.
	self flush
]

{ #category : #'debug printing' }
StackInterpreter >> printOopShortInner: oop [
	| classOop name nameLen |
	<var: #name type: #'char *'>
	<inline: true>
	(objectMemory isImmediate: oop) ifTrue:
		[(objectMemory isImmediateCharacter: oop) ifTrue:
			[^self
				printChar: $$;
				printChar: (objectMemory characterValueOf: oop);
				printChar: $(;
				printHexnp: (objectMemory characterValueOf: oop);
				printChar: $)].
		 (objectMemory isIntegerObject: oop) ifTrue:
			[^self
				printNum: (objectMemory integerValueOf: oop);
				printChar: $(;
				printHexnp: (objectMemory integerValueOf: oop);
				printChar: $)].
		 (objectMemory isImmediateFloat: oop) ifTrue:
			[^self
				printFloat: (objectMemory dbgFloatValueOf: oop);
				printChar: $(;
				printHexnp: oop;
				printChar: $)].
		 ^self print: 'unknown immediate '; printHexnp: oop].
	(objectMemory addressCouldBeObj: oop) ifFalse:
		[^self print: ((oop bitAnd: objectMemory allocationUnit - 1) ~= 0
						ifTrue: [' is misaligned']
						ifFalse: [self whereIs: oop])].
	(objectMemory isFreeObject: oop) ifTrue:
		[^self print: ' is a free chunk'].
	(objectMemory isForwarded: oop) ifTrue:
		[^self print: ' is a forwarder to '; printHexnp: (objectMemory followForwarded: oop)].
	(self isFloatObject: oop) ifTrue:
		[^self printFloat: (objectMemory dbgFloatValueOf: oop)].
	classOop := objectMemory fetchClassOfNonImm: oop.
	(objectMemory addressCouldBeObj: classOop) ifFalse:
		[^self print: 'a ??'].
	(objectMemory numSlotsOf: classOop) = metaclassNumSlots ifTrue:
		[^self printNameOfClass: oop count: 5].
	oop = objectMemory nilObject ifTrue: [^self print: 'nil'].
	oop = objectMemory trueObject ifTrue: [^self print: 'true'].
	oop = objectMemory falseObject ifTrue: [^self print: 'false'].
	nameLen := self lengthOfNameOfClass: classOop.
	nameLen = 0 ifTrue: [^self print: 'a ??'].
	name := self nameOfClass: classOop.
	nameLen = 10 ifTrue:
		[(self strncmp: name _: 'ByteString' _: 10) = 0 "strncmp is weird" ifTrue:
			[^self printChar: $'; printStringOf: oop; printChar: $'].
		 (self strncmp: name _: 'ByteSymbol' _: 10) = 0 "strncmp is weird" ifTrue:
			[self printChar: $#; printStringOf: oop. ^self]].
	(nameLen = 9 and: [(self strncmp: name _: 'Character' _: 9) = 0]) ifTrue:
		[^self printChar: $$; printChar: (objectMemory integerValueOf: (objectMemory fetchPointer: 0 ofObject: oop))].
	self print: 'a(n) '.
	self
		cCode: [0 to: nameLen - 1 do: [:i| self printChar: (name at: i)]]
		inSmalltalk:
			[name isString
				ifTrue: [self print: name]
				ifFalse: [0 to: nameLen - 1 do: [:i| self printChar: (name at: i)]]].
	"Try to spot association-like things; they're all subclasses of LookupKey"
	((objectMemory isPointersNonImm: oop)
	 and: [(objectMemory instanceSizeOf: classOop) = (ValueIndex + 1)
	 and: [(objectMemory isBytes: (objectMemory fetchPointer: KeyIndex ofObject: oop))]]) ifTrue:
		[| classLookupKey |
		 classLookupKey := objectMemory fetchClassOfNonImm: (objectMemory splObj: SchedulerAssociation).
		 [classLookupKey = objectMemory nilObject ifTrue:
			[^self].
		  (objectMemory instanceSizeOf: classLookupKey) = (KeyIndex + 1)] whileFalse:
			[classLookupKey := self superclassOf: classLookupKey].
		 (self includesBehavior: classOop ThatOf: classLookupKey) ifTrue:
			[self space;
				printOopShort: (objectMemory fetchPointer: KeyIndex ofObject: oop);
				print: ' -> ';
				printHexnp: (objectMemory fetchPointer: ValueIndex ofObject: oop)]]
]

{ #category : #'debug printing' }
StackInterpreter >> printPageHeadFrame [
	<inline: false>
	self printFrame: stackPage headFP WithSP: stackPage headSP
]

{ #category : #'debug printing' }
StackInterpreter >> printProcessStack: aProcess [
	<api>
	<inline: false>
	| ctx |
	self cr; printNameOfClass: (objectMemory fetchClassOf: aProcess) count: 5; space; printHex: aProcess.
	self print: ' priority '; printNum: (self quickFetchInteger: PriorityIndex ofObject: aProcess); cr.
	ctx := objectMemory followField: SuspendedContextIndex ofObject: aProcess.
	ctx = objectMemory nilObject ifFalse:
		[self printCallStackOf: ctx currentFP: framePointer]
]

{ #category : #'debug printing' }
StackInterpreter >> printProcsOnList: procList [
	<api>
	<inline: false>
	| proc firstProc |
	proc := firstProc := objectMemory followField: FirstLinkIndex ofObject: procList.
	[proc = objectMemory nilObject] whileFalse:
		[self printProcessStack: proc.
		 proc := objectMemory followField: NextLinkIndex ofObject: proc.
		 proc = firstProc ifTrue:
			[self warning: 'circular process list!!'.
			 ^nil]]
]

{ #category : #'debug printing' }
StackInterpreter >> printSends [
	^false
]

{ #category : #'debug printing' }
StackInterpreter >> printStackCallStack [
	<doNotGenerate>
	self printStackCallStackOf: (localFP ifNil: [framePointer])
]

{ #category : #'debug printing' }
StackInterpreter >> printStackCallStackOf: aContextOrProcessOrFrame [
	<api>
	| theFP context |
	<var: #theFP type: #'char *'>
	(self cCode: [false] "In the stack simulator, frame pointers are negative which upsets addressCouldBeObj:"
		inSmalltalk: [stackPages couldBeFramePointer: aContextOrProcessOrFrame]) ifFalse:
		[(objectMemory addressCouldBeObj: aContextOrProcessOrFrame) ifTrue:
			[((objectMemory isContext: aContextOrProcessOrFrame)
			  and: [self checkIsStillMarriedContext: aContextOrProcessOrFrame currentFP: nil]) ifTrue:
				[^self printStackCallStackOf: (self frameOfMarriedContext: aContextOrProcessOrFrame) asInteger].
			 (self couldBeProcess: aContextOrProcessOrFrame) ifTrue:
				[^self printCallStackOf: (objectMemory
											fetchPointer: SuspendedContextIndex
											ofObject: aContextOrProcessOrFrame)].
			 ^nil]].

	theFP := aContextOrProcessOrFrame asVoidPointer.
	[context := self shortReversePrintFrameAndCallers: theFP.
	 ((self isMarriedOrWidowedContext: context)
	  and:
		[theFP := self frameOfMarriedContext: context.
		 self checkIsStillMarriedContext: context currentFP: theFP]) ifFalse:
			[^nil]] repeat
]

{ #category : #'debug printing' }
StackInterpreter >> printStackPage: page [
	<inline: true>
	<var: #page type: #'StackPage *'>
	self printStackPage: page useCount: -1
]

{ #category : #'debug printing' }
StackInterpreter >> printStackPage: page useCount: n [
	<inline: false>
	<var: #page type: #'StackPage *'>
	self print: 'page '; printHexPtr: (self cCode: [page] inSmalltalk: [page baseAddress]);
		print: ' ('; printNum: (stackPages pageIndexFor: page realStackLimit).
	n >= 0 ifTrue:
		[self print: ','; printNum: n].
	self print: ')  (trace: '; printNum: page trace; printChar: $).
	(stackPages isFree: page) ifTrue:
		[self print: ' (free)'].
	page = stackPages mostRecentlyUsedPage ifTrue:
		[self print: ' (MRU)'].
	page prevPage = stackPages mostRecentlyUsedPage ifTrue:
		[self print: ' (LRU)'].
	self cr; tab; print: 'ba: ';
		printHexPtr: page baseAddress; print: ' - sl: ';
		printHexPtr: page realStackLimit; print: ' - sl-so: ';
		printHexPtr: page realStackLimit - self stackLimitOffset; print: ' - la:';
		printHexPtr: page lastAddress.
	(stackPages isFree: page) ifFalse:
		[self cr; tab; print: 'baseFP '; printHexPtr: page baseFP.
		 self "cr;" tab; print: 'headFP '; printHexPtr: page headFP.
		 self "cr;" tab; print: 'headSP '; printHexPtr: page headSP].
	self cr; tab; print: 'prev '; printHexPtr: (self cCode: 'page->prevPage' inSmalltalk: [page prevPage baseAddress]);
		print: ' ('; printNum: (stackPages pageIndexFor: page prevPage realStackLimit); printChar: $).
	self tab; print: 'next '; printHexPtr: (self cCode: 'page->nextPage' inSmalltalk: [page nextPage baseAddress]);
		print: ' ('; printNum: (stackPages pageIndexFor: page nextPage realStackLimit); printChar: $).
	self cr
]

{ #category : #'debug printing' }
StackInterpreter >> printStackPageList [
	| page |
	<inline: false>
	<var: #page type: #'StackPage *'>
	page := stackPages mostRecentlyUsedPage.
	[self printStackPage: page.
	 self cr.
	 (page := page prevPage) ~= stackPages mostRecentlyUsedPage] whileTrue
]

{ #category : #'debug printing' }
StackInterpreter >> printStackPageListInUse [
	| page n |
	<inline: false>
	<var: #page type: #'StackPage *'>
	page := stackPages mostRecentlyUsedPage.
	n := 0.
	[(stackPages isFree: page) ifFalse:
		[self printStackPage: page useCount: (n := n + 1); cr].
	 (page := page prevPage) ~= stackPages mostRecentlyUsedPage] whileTrue
]

{ #category : #'debug printing' }
StackInterpreter >> printStackPages [
	0 to: numStackPages - 1 do:
		[:i|
		self printStackPage: (stackPages stackPageAt: i).
		self cr]
]

{ #category : #'debug printing' }
StackInterpreter >> printStackPagesInUse [
	| n |
	n := 0.
	0 to: numStackPages - 1 do:
		[:i|
		(stackPages isFree: (stackPages stackPageAt: i)) ifFalse:
			[self printStackPage: (stackPages stackPageAt: i) useCount: (n := n + 1); cr]]
]

{ #category : #'object memory support' }
StackInterpreter >> printStackReferencesTo: oop [
	<api>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	0 to: numStackPages - 1 do:
		[:i| | thePage theSP theFP callerFP |
		thePage := stackPages stackPageAt: i.
		thePage isFree ifFalse:
			[theSP := thePage headSP.
			 theFP := thePage headFP.
			 "Skip the instruction pointer on top of stack of inactive pages."
			 thePage = stackPage ifFalse:
				[theSP := theSP + objectMemory wordSize].
			 [[theSP <= (self frameReceiverLocation: theFP)] whileTrue:
				[oop = (stackPages longAt: theSP) ifTrue:
					[self print: 'FP: '; printHexnp: theFP; print: ' @ '; printHexnp: theSP; cr].
				 theSP := theSP + objectMemory wordSize].
			  (self frameHasContext: theFP) ifTrue:
				[oop = (self frameContext: theFP) ifTrue:
					[self print: 'FP: '; printHexnp: theFP; print: ' CTXT'; cr]].
			  oop = (self frameMethod: theFP) ifTrue:
				[self print: 'FP: '; printHexnp: theFP; print: ' MTHD'; cr].
			  (callerFP := self frameCallerFP: theFP) ~= 0]
				whileTrue:
					[theSP := (theFP + FoxCallerSavedIP) + objectMemory wordSize.
					 theFP := callerFP].
			 theSP := theFP + FoxCallerSavedIP. "a.k.a. FoxCallerContext"
			 [theSP <= thePage baseAddress] whileTrue:
				[oop = (stackPages longAt: theSP) ifTrue:
					[self print: 'FP: '; printHexnp: theFP; print: ' @ '; printHexnp: theSP; cr].
				 theSP := theSP + objectMemory wordSize]]]
]

{ #category : #'debug printing' }
StackInterpreter >> printStringOf: oop [
	| fmt len cnt max i |
	<inline: false>
	(objectMemory isImmediate: oop) ifTrue:
		[^self].
	(objectMemory addressCouldBeObj: oop) ifFalse:
		[^self].
	fmt := objectMemory formatOf: oop.
	fmt < objectMemory firstByteFormat ifTrue: [^self].

	cnt := (max := 128) min: (len := objectMemory lengthOf: oop).
	i := 0.

	((objectMemory is: oop
		  instanceOf: (objectMemory splObj: ClassByteArray)
		  compactClassIndex: classByteArrayCompactIndex)
	or: [(objectMemory isLargeIntegerInstance: oop)])
		ifTrue:
			[[i < cnt] whileTrue:
				[self printHex: (objectMemory fetchByte: i ofObject: oop).
				 i := i + 1]]
		ifFalse:
			[[i < cnt] whileTrue:
				[self cCode:
						[(objectMemory fetchByte: i ofObject: oop) = 13 "Character cr asInteger" ifTrue:
							[self print: '<CR>'.
							 i + 1 < len ifTrue:
								[self print: '...'].
							 ^self]].
				 self printChar: (objectMemory fetchByte: i ofObject: oop).
				 i := i + 1]].
	len > max ifTrue:
		[self print: '...'].
	self flush
]

{ #category : #'debug printing' }
StackInterpreter >> printUnbalancedStack: primIdx [
	<inline: false>
	self print: 'Stack unbalanced after '.
	self successful 
		ifTrue:[self print:'successful primitive '] 
		ifFalse:[self print: 'failed primitive '].
	self printNum: primIdx.
	self cr.
		
]

{ #category : #'process primitive support' }
StackInterpreter >> processesInProcessListDo: aBlock [
	"Return the highest priority process that is ready to run.
	 To save time looking at many empty lists before finding a
	 runnable process the VM maintains a variable holding the
	 highest priority runnable process.  If this variable is 0 then the
	 VM does not know the highest priority and must search all lists.
	 Note: It is a fatal VM error if there is no runnable process."
	| schedLists p processList proc ctxt |
	self externalWriteBackHeadFramePointers.
	schedLists := objectMemory fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	p := highestRunnableProcessPriority = 0
			ifTrue: [objectMemory numSlotsOf: schedLists]
			ifFalse: [highestRunnableProcessPriority].
	[(p := p - 1) >= 0] whileTrue:
		[processList := objectMemory fetchPointer: p ofObject: schedLists.
	 	 proc := objectMemory fetchPointer: FirstLinkIndex ofObject: processList. 
		 [proc = objectMemory nilObject] 
			whileFalse: ["Only answer processes with a runnable suspendedContext.
			  Discard those that aren't; the VM would crash otherwise."
			 ctxt := objectMemory fetchPointer: SuspendedContextIndex ofObject: proc.
			  self cppIf: SPURVM ifTrue: 
				["This is uncommon, so we can deal with forwarders here instead of assuming there isn't."
				 (objectMemory isOopForwarded: ctxt) ifTrue:
					[ctxt := self fixFollowedField: SuspendedContextIndex 
									ofObject: proc withInitialValue: ctxt].
				  (self isLiveContext: ctxt) ifTrue:
					[ aBlock value: proc ] ].
			 proc := objectMemory fetchPointer: NextLinkIndex ofObject: proc ]].
]

{ #category : #'as yet unclassified' }
StackInterpreter >> profileMethod [
	<doNotGenerate>
	^ profileMethod
]

{ #category : #'as yet unclassified' }
StackInterpreter >> profileSemaphore [
	<doNotGenerate>
	^ profileSemaphore
]

{ #category : #'internal interpreter access' }
StackInterpreter >> push: object [
	"In the StackInterpreter stacks grow down."
	| sp |
	<inline: true>
	<var: #sp type: #'char *'>
	stackPages longAt: (sp := stackPointer - objectMemory wordSize) put: object.
	stackPointer := sp
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushActiveContextBytecode [
	| ourContext |
	ourContext := self ensureFrameIsMarried: localFP SP: localSP.
	self fetchNextBytecode.
	self internalPush: ourContext
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pushBool: trueOrFalse [
	<inline: true>
	self push: (objectMemory booleanObjectOf: trueOrFalse)
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushClosureCopyCopiedValuesBytecode [
	"The compiler has pushed the values to be copied, if any.  Find numArgs and numCopied in the byte following.
	 Create a Closure with space for the copiedValues and pop numCopied values off the stack into the closure.
	 Set numArgs as specified, and set startpc to the pc following the block size and jump over that code."
	| numArgsNumCopied numArgs numCopied blockSize |
	numArgsNumCopied := self fetchByte.
	numArgs := numArgsNumCopied bitAnd: 16rF.
	numCopied := numArgsNumCopied bitShift: -4.
	"Split blockSize := (self fetchByte * 256) + self fetchByte. into two because evaluation order in C is undefined."
	blockSize := self fetchByte << 8.
	blockSize := blockSize + self fetchByte.
	self pushClosureNumArgs: numArgs copiedValues: numCopied blockSize: blockSize
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushClosureNumArgs: numArgs copiedValues: numCopied blockSize: blockSize [
	"The compiler has pushed the values to be copied, if any.
	 Create a Closure with space for the copiedValues and pop numCopied values off the stack into the closure.
	 Set numArgs as specified, and set startpc to the pc following the block size and jump over that code."
	<inline: true>
	| newClosure context |
	"No need to record the pushed copied values in the outerContext."
	context := self ensureFrameIsMarried: localFP SP: localSP + (numCopied * objectMemory bytesPerOop).
	newClosure := self
					closureIn: context
					numArgs: numArgs
					instructionPointer: (self oopForPointer: localIP) + 2 - (method+objectMemory baseHeaderSize)
					numCopiedValues: numCopied.
	numCopied > 0 ifTrue:
		[0 to: numCopied - 1 do:
			[:i|
			"Assume: have just allocated a new BlockClosure; it must be young.
			 Thus, can use unchecked stores."
			 objectMemory storePointerUnchecked: i + ClosureFirstCopiedValueIndex
				ofObject: newClosure
				withValue: (self internalStackValue: numCopied - i - 1)].
		 self internalPop: numCopied].
	localIP := localIP + blockSize.
	self fetchNextBytecode.
	self internalPush: newClosure
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantFalseBytecode [

	self fetchNextBytecode.
	self internalPush: objectMemory falseObject.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantMinusOneBytecode [

	self fetchNextBytecode.
	self internalPush: ConstMinusOne.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantNilBytecode [

	self fetchNextBytecode.
	self internalPush: objectMemory nilObject.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantOneBytecode [

	self fetchNextBytecode.
	self internalPush: ConstOne.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantTrueBytecode [

	self fetchNextBytecode.
	self internalPush: objectMemory trueObject.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantTwoBytecode [

	self fetchNextBytecode.
	self internalPush: ConstTwo.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushConstantZeroBytecode [

	self fetchNextBytecode.
	self internalPush: ConstZero.

]

{ #category : #'primitive support' }
StackInterpreter >> pushFloat: f [

	<var: #f type: #double>
	self push: (objectMemory floatObjectOf: f).
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushFullClosureNumArgs: numArgs copiedValues: numCopiedArg compiledBlock: compiledBlock receiverIsOnStack: receiverIsOnStack ignoreContext: ignoreContext [
	"The compiler has pushed the values to be copied, if any. The receiver has been pushed on stack before if specified. 
	 Create a Closure with space for the copiedValues and pop numCopied values off the stack into the closure.
	 Sets outerContext, compiledBlock, numArgs and receiver as specified.."
	<inline: true>
	| numCopied newClosure context startIndex |
	"No need to record the pushed copied values in the outerContext."
	context := ignoreContext
		ifTrue: [objectMemory nilObject ]
		ifFalse: [self ensureFrameIsMarried: localFP SP: localSP + (numCopiedArg * objectMemory bytesPerOop)].
	newClosure := self
					fullClosureIn: context 
					numArgs: numArgs 
					numCopiedValues: numCopiedArg 
					compiledBlock: compiledBlock.
	receiverIsOnStack
		ifFalse: 
			[ startIndex := FullClosureFirstCopiedValueIndex.
			   objectMemory storePointerUnchecked: FullClosureReceiverIndex
				ofObject: newClosure
				withValue: self receiver.
			numCopied := numCopiedArg ]
		ifTrue:
			[ startIndex := FullClosureReceiverIndex.
			numCopied := numCopiedArg + 1 ].
	numCopied > 0 ifTrue:
		[0 to: numCopied - 1 do:
			[ :i |
			"Assume: have just allocated a new BlockClosure; it must be young.
			 Thus, can use unchecked stores."
			 objectMemory storePointerUnchecked: i + startIndex
				ofObject: newClosure
				withValue: (self internalStackValue: numCopied - i - 1)].
		 self internalPop: numCopied].
	self fetchNextBytecode.
	self internalPush: newClosure
]

{ #category : #'internal interpreter access' }
StackInterpreter >> pushInteger: integerValue [
	self push: (objectMemory integerObjectOf: integerValue).
	^nil
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushLiteralConstant: literalIndex [

	self internalPush: (self literal: literalIndex).
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushLiteralConstantBytecode [
	<expandCases>
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[self fetchNextBytecode.
			 self pushLiteralConstant: (currentBytecode bitAnd: 16r1F)]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[self pushLiteralConstant: (currentBytecode bitAnd: 16r1F).
			 self fetchNextBytecode]
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushLiteralVariable16CasesBytecode [
	<expandCases>
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[self fetchNextBytecode.
			 self pushLiteralVariable: (currentBytecode bitAnd: 16rF)]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[self pushLiteralVariable: (currentBytecode bitAnd: 16rF).
			 self fetchNextBytecode]
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushLiteralVariable: literalIndex [
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[| litVar |
			 "push/store/popLiteralVariable all fetch a literal, and either read or write the literal's value field.
			  The fetch of the literal needs an explicit check (otherwise we would have to scan all literals in
			  all methods in the stack zone, and the entire method on return, and global variables are relatively
			  rare; in my work image 8.7% of literals are globals)."
			 litVar := self literal: literalIndex.
			 (objectMemory isForwarded: litVar) ifTrue:
				[litVar := self unfollow: litVar atIndex: literalIndex].
			 self internalPush:
				(objectMemory fetchPointer: ValueIndex ofObject: litVar)]
		ifFalse:
			[self internalPush:
				(objectMemory fetchPointer: ValueIndex ofObject: (self literal: literalIndex))]
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushLiteralVariableBytecode [
	<expandCases>
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[self fetchNextBytecode.
			 self pushLiteralVariable: (currentBytecode bitAnd: 16r1F)]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[self pushLiteralVariable: (currentBytecode bitAnd: 16r1F).
			 self fetchNextBytecode]
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushMaybeContext: obj receiverVariable: fieldIndex [
	"Must trap accesses to married and widowed contexts.
	 But don't want to check on all inst var accesses.  This
	 method is only used by the long-form bytecodes, evading
	 the cost. Note that the method, closure and receiver fields
	 of married contexts are correctly initialized so they don't
	 need special treatment on read.  Only sender, instruction
	 pointer and stack pointer need to be intercepted on reads."
	<inline: true>
	((self isReadMediatedContextInstVarIndex: fieldIndex)
	and: [objectMemory isContextNonImm: obj])
		ifTrue:
			[self internalPush: (self instVar: fieldIndex ofContext: obj)]
		ifFalse:
			[self internalPush: (objectMemory fetchPointer: fieldIndex ofObject: obj)]
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushMaybeContextReceiverVariable: fieldIndex [
	"Must trap accesses to married and widowed contexts.
	 But don't want to check on all inst var accesses.  This
	 method is only used by the long-form bytecodes, evading
	 the cost. Note that the method, closure and receiver fields
	 of married contexts are correctly initialized so they don't
	 need special treatment on read.  Only sender, instruction
	 pointer and stack pointer need to be intercepted on reads."
	<inline: true>
	self pushMaybeContext: self receiver receiverVariable: fieldIndex
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushNewArrayBytecode [
	| size popValues array |
	size := self fetchByte.
	popValues := size > 127.
	size := size bitAnd: 127.
	self fetchNextBytecode.
	self externalizeIPandSP. "in case of abort"
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[array := objectMemory
						eeInstantiateSmallClassIndex: ClassArrayCompactIndex
						format: objectMemory arrayFormat
						numSlots: size]
		ifFalse:
			[array := objectMemory
						eeInstantiateClassIndex: ClassArrayCompactIndex
						format: objectMemory arrayFormat
						numSlots: size].
	popValues
		ifTrue:
			[0 to: size - 1 do:
				[:i|
				"Assume: have just allocated a new Array; it must be young. Thus, can use unchecked stores."
				objectMemory storePointerUnchecked: i ofObject: array withValue: (self internalStackValue: size - i - 1)].
			 self internalPop: size]
		ifFalse:
			[0 to: size - 1 do:
				[:i|
				objectMemory storePointerUnchecked: i ofObject: array withValue: objectMemory nilObject]].
	self internalPush: array
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushReceiverBytecode [

	self fetchNextBytecode.
	self internalPush: self receiver.

]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushReceiverVariable: fieldIndex [

	self internalPush: (objectMemory fetchPointer: fieldIndex ofObject: self receiver).
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushReceiverVariableBytecode [
	<expandCases>
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[self fetchNextBytecode.
			 self pushReceiverVariable: (currentBytecode bitAnd: 16rF)]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[self pushReceiverVariable: (currentBytecode bitAnd: 16rF).
			 self fetchNextBytecode]
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushRemoteTemp: index inVectorAt: tempVectorIndex [
	| tempVector |
	tempVector := self temporary: tempVectorIndex in: localFP.
	TempVectReadBarrier
		ifTrue: 
			[(objectMemory isForwarded: tempVector) ifTrue:
				[tempVector := self unfollowTempVector: tempVector atIndex: tempVectorIndex in: localFP]].
	self internalPush: (objectMemory fetchPointer: index ofObject: tempVector)
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushRemoteTempLongBytecode [
	| remoteTempIndex tempVectorIndex |
	remoteTempIndex := self fetchByte.
	tempVectorIndex := self fetchByte.
	self fetchNextBytecode.
	self pushRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushTemporaryVariable: temporaryIndex [

	self internalPush: (self temporary: temporaryIndex in: localFP).
]

{ #category : #'stack bytecodes' }
StackInterpreter >> pushTemporaryVariableBytecode [
	<expandCases>
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[self fetchNextBytecode.
			 self pushTemporaryVariable: (currentBytecode bitAnd: 16rF)]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[self pushTemporaryVariable: (currentBytecode bitAnd: 16rF).
			 self fetchNextBytecode]
]

{ #category : #'frame access' }
StackInterpreter >> pushedReceiverOrClosureOfFrame: theFP [
	"The receiver of a message send or the closure of a block activation is
	 always on the stack above any arguments and the frame itself.  See the
	 diagram in StackInterpreter class>>initializeFrameIndices."
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + (self frameStackedReceiverOffset: theFP)
]

{ #category : #'image save/restore' }
StackInterpreter >> putLong: aLong toFile: aFile [
	"Append aLong to aFile in this platform's 'natural' byte order.  aLong is either 32 or 64 bits,
	 depending on ObjectMemory.  (Bytes will be swapped, if necessary, when the image is read
	 on a different platform.) Set successFlag to false if the write fails."

	<var: #aLong type: #sqInt>
	<var: #aFile type: #sqImageFile>
	<inline: false>
	| objectsWritten |
	objectsWritten := self
						cCode: [self sq: (self addressOf: aLong) Image: (self sizeof: #sqInt) File: 1 Write: aFile]
						inSmalltalk:
							[| value |
							 value := aLong.
							 objectMemory wordSize timesRepeat:
								[aFile nextPut: (value bitAnd: 16rFF).
								 value := value >> 8].
							 1].
	self success: objectsWritten = 1
]

{ #category : #'image save/restore' }
StackInterpreter >> putShort: aShort toFile: aFile [
	"Append the 16-bit aShort to aFile in this platform's 'natural' byte order.
	 (Bytes will be swapped, if necessary, when the image is read on a
	 different platform.) Set successFlag to false if the write fails."

	<var: #aShort type: #short>
	<var: #aFile type: #sqImageFile>
	<inline: false>
	| objectsWritten |
	objectsWritten := self
						cCode: [self sq: (self addressOf: aShort) Image: (self sizeof: #short) File: 1 Write: aFile]
						inSmalltalk:
							[aFile
								nextPut: (aShort bitAnd: 16rFF);
								nextPut: (aShort >> 8 bitAnd: 16rFF).
							 1].
	self success: objectsWritten = 1
]

{ #category : #'process primitive support' }
StackInterpreter >> putToSleep: aProcess yieldingIf: yieldImplicitly [
	"Save the given process on the scheduler process list for its priority,
	 adding to the back if yieldImplicitly or to the front if not yieldImplicitly."

	| priority processLists processList |
	self assert: (framePointer - stackPointer) < (LargeContextSlots * objectMemory bytesPerOop).
	priority := self quickFetchInteger: PriorityIndex ofObject: aProcess.
	(highestRunnableProcessPriority ~= 0
	 and: [priority > highestRunnableProcessPriority]) ifTrue:
		[highestRunnableProcessPriority := priority].
	processLists := objectMemory fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	processList := objectMemory fetchPointer: priority - 1 ofObject: processLists.
	yieldImplicitly
		ifTrue: [self addLastLink: aProcess toList: processList]
		ifFalse: [self addFirstLink: aProcess toList: processList]
]

{ #category : #'image save/restore' }
StackInterpreter >> putWord32: aWord32 toFile: aFile [
	"Append aWord32 to aFile in this platform's 'natural' byte order.  aWord32 is 32 bits,
	 depending on ObjectMemory.  (Bytes will be swapped, if necessary, when the image is read
	 on a different platform.) Set successFlag to false if the write fails."

	<var: #aWord32 type: #int>
	<var: #aFile type: #sqImageFile>
	<inline: false>
	| objectsWritten |
	objectsWritten := self
						cCode: [self sq: (self addressOf: aWord32) Image: 4 File: 1 Write: aFile]
						inSmalltalk:
							[| value |
							 value := aWord32.
							 4 timesRepeat:
								[aFile nextPut: (value bitAnd: 16rFF).
								 value := value >> 8].
							 1].
	self success: objectsWritten = 1
]

{ #category : #'sista bytecodes' }
StackInterpreter >> quaternaryInlinePrimitive: primIndex [
	<option: #SistaVM>
	self unknownInlinePrimitive
]

{ #category : #utilities }
StackInterpreter >> quickFetchInteger: fieldIndex ofObject: objectPointer [
	"Return the integer value of the field without verifying that it is an integer value! For use in time-critical places where the integer-ness of the field can be guaranteed."

	| oop |
	oop := objectMemory fetchPointer: fieldIndex ofObject: objectPointer.
	self assert: (objectMemory isIntegerObject: oop).
	^objectMemory integerValueOf: oop
]

{ #category : #'sista bytecodes' }
StackInterpreter >> quinaryInlinePrimitive: primIndex [
	| src srcIndex dest destIndex destLimit oop |
	<option: #SistaVM>
	"0 is deprecated, now this can be handled at Scorch level"
	primIndex = 0 ifTrue: "Array copy, pointer variable object with no inst vars"
		[dest := self internalStackValue: 4.
		destIndex := (objectMemory integerValueOf: (self internalStackValue: 3)) - 1.
		destLimit := (objectMemory integerValueOf: (self internalStackValue: 2)) - 1.
		src := self internalStackValue: 1.
		srcIndex := (objectMemory integerValueOf: (self internalStackValue: 0)) - 1.
		self internalPop: 4.
		destLimit < destIndex ifTrue: [^self].
		(objectMemory isYoung: dest) ifFalse: [objectMemory possibleRootStoreInto: dest].
		0 to: destLimit - destIndex do: 
			[:i| oop := objectMemory fetchPointer: srcIndex + i ofObject: src.
			    objectMemory storePointerUnchecked: destIndex + i ofObject: dest withValue: oop].
		^ self].
	self unknownInlinePrimitive
]

{ #category : #'image save/restore' }
StackInterpreter >> readImageFromFile: f HeapSize: desiredHeapSize StartingAt: imageOffset [
	"Read an image from the given file stream, allocating an amount of memory to its object heap.
	
	 V3: desiredHeapSize is the total size of the heap.  Fail if the image has an unknown format or
	 requires more than the specified amount of memory.

	 Spur: desiredHeapSize is ignored; this routine will attempt to provide at least extraVMMemory's
	 ammount of free space after the image is loaded, taking any free space in teh image into account.
	 extraVMMemory is stored in the image header and is accessible as vmParameterAt: 23.  If
	 extraVMMemory is 0, the value defaults to the default grow headroom.  Fail if the image has an
	 unknown format or if sufficient memory cannot be allocated.

	 Details: This method detects when the image was stored on a machine with the opposite byte
	 ordering from this machine and swaps the bytes automatically. Furthermore, it allows the header
	 information to start 512 bytes into the file, since some file transfer programs for the Macintosh
	 apparently prepend a Mac-specific header of this size. Note that this same 512 bytes of prefix
	 area could also be used to store an exec command on Unix systems, allowing one to launch
	 Smalltalk by invoking the image name as a command."

	| headerStart headerSize headerFlags dataSize oldBaseAddr swapBytes
	  minimumMemory bytesRead bytesToShift heapSize firstSegSize
	  hdrEdenBytes hdrMaxExtSemTabSize hdrNumStackPages allocationReserve |
	<var: #f type: #sqImageFile>
	<var: #heapSize type: #usqInt>
	<var: #dataSize type: #'size_t'>
	<var: #minimumMemory type: #usqInt>
	<var: #desiredHeapSize type: #usqInt>
	<var: #allocationReserve type: #usqInt>
	<var: #headerStart type: #squeakFileOffsetType>
	<var: #imageOffset type: #squeakFileOffsetType>

	metaclassNumSlots := 6.	"guess Metaclass instSize"
	classNameIndex := 6.		"guess (Class instVarIndexFor: 'name' ifAbsent: []) - 1"
	swapBytes := self checkImageVersionFrom: f startingAt: imageOffset.
	headerStart := (self sqImageFilePosition: f) - 4.  "record header start position"

	headerSize			:= self getWord32FromFile: f swap: swapBytes.
	dataSize			:= self getLongFromFile: f swap: swapBytes.
	oldBaseAddr		:= self getLongFromFile: f swap: swapBytes.
	objectMemory specialObjectsOop: (self getLongFromFile: f swap: swapBytes).
	objectMemory lastHash: (self getLongFromFile: f swap: swapBytes). "N.B.  not used."
	savedWindowSize	:= self getLongFromFile: f swap: swapBytes.
	headerFlags		:= self getLongFromFile: f swap: swapBytes.
	self setImageHeaderFlagsFrom: headerFlags.
	extraVMMemory	:= self getWord32FromFile: f swap: swapBytes.
	hdrNumStackPages	:= self getShortFromFile: f swap: swapBytes.
	"4 stack pages is small.  Should be able to run with as few as
	 three. 4 should be comfortable but slow.  8 is a reasonable
	 default.  Can be changed via vmParameterAt: 43 put: n.
	 Can be set as a preference (Info.plist, VM.ini, command line etc).
	 If desiredNumStackPages is already non-zero then it has been
	 set as a preference.  Ignore (but preserve) the header's default."
	numStackPages := desiredNumStackPages ~= 0
						ifTrue: [desiredNumStackPages]
						ifFalse: [hdrNumStackPages = 0
									ifTrue: [self defaultNumStackPages]
									ifFalse: [hdrNumStackPages]].
	desiredNumStackPages := hdrNumStackPages.
	"pad to word boundary.  This slot can be used for anything else that will fit in 16 bits.
	 It is used for the cog code size in Cog.  Preserve it to be polite to other VMs."
	theUnknownShort	:= self getShortFromFile: f swap: swapBytes.
	hdrEdenBytes		:= self getWord32FromFile: f swap: swapBytes.
	objectMemory edenBytes: (desiredEdenBytes ~= 0
						ifTrue: [desiredEdenBytes]
						ifFalse:
							[hdrEdenBytes = 0
									ifTrue: [objectMemory defaultEdenBytes]
									ifFalse: [hdrEdenBytes]]).
	desiredEdenBytes := hdrEdenBytes.
	hdrMaxExtSemTabSize := self getShortFromFile: f swap: swapBytes.
	hdrMaxExtSemTabSize ~= 0 ifTrue:
		[self setMaxExtSemSizeTo: hdrMaxExtSemTabSize].
	"pad to word boundary.  This slot can be used for anything else that will fit in 16 bits.
	 Preserve it to be polite to other VMs."
	the2ndUnknownShort	:= self getShortFromFile: f swap: swapBytes.
	firstSegSize := self getLongFromFile: f swap: swapBytes.
	objectMemory firstSegmentSize: firstSegSize.
	"compare memory requirements with availability"
	allocationReserve := self interpreterAllocationReserveBytes.
	minimumMemory := dataSize
						+ objectMemory newSpaceBytes
						+ allocationReserve.
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[| freeOldSpaceInImage headroom |
			 freeOldSpaceInImage := self getLongFromFile: f swap: swapBytes.
			 headroom := objectMemory
							initialHeadroom: extraVMMemory
							givenFreeOldSpaceInImage: freeOldSpaceInImage.
			 heapSize := objectMemory roundUpHeapSize:
						   dataSize
						+ headroom
						+ objectMemory newSpaceBytes
						+ (headroom > allocationReserve
							ifTrue: [0]
							ifFalse: [allocationReserve])]
		ifFalse:
			[heapSize :=  desiredHeapSize
						+ objectMemory newSpaceBytes
						+ (desiredHeapSize - dataSize > allocationReserve
							ifTrue: [0]
							ifFalse: [allocationReserve]).
			 heapSize < minimumMemory ifTrue:
				[self insufficientMemorySpecifiedError]].

	"allocate a contiguous block of memory for the Squeak heap"
	objectMemory memory: (self
								allocateMemory: heapSize
								minimum: minimumMemory
								imageFile: f
								headerSize: headerSize
								desiredPosition: oldBaseAddr) asUnsignedInteger.
	objectMemory memory ifNil: [self insufficientMemoryAvailableError].

	objectMemory
		setHeapBase: objectMemory memory
		memoryLimit: objectMemory memory + heapSize
		endOfMemory: objectMemory memory + dataSize.

	"position file after the header"
	self sqImageFile: f Seek: headerStart + headerSize.

	"read in the image in bulk, then swap the bytes if necessary"
	bytesRead := objectMemory readHeapFromImageFile: f dataBytes: dataSize.
	bytesRead ~= dataSize ifTrue: [self unableToReadImageError].

	self ensureImageFormatIsUpToDate: swapBytes.

	"compute difference between old and new memory base addresses"
	bytesToShift := objectMemory memoryBaseForImageRead - oldBaseAddr.
	self initializeInterpreter: bytesToShift.  "adjusts all oops to new location"
	^dataSize
]

{ #category : #'image save/restore' }
StackInterpreter >> readableFormat: imageVersion [
	"Anwer true if images of the given format are readable by this interpreter.
	 Allows a virtual machine to accept selected older image formats."

	^imageVersion = self imageFormatVersion "Float words in platform-order"
	   or: [objectMemory hasSpurMemoryManagerAPI not "No compatibility version for Spur as yet"
			and: [imageVersion = self imageFormatCompatibilityVersion]] "Float words in BigEndian order"
]

{ #category : #'primitive support' }
StackInterpreter >> reapAndResetErrorCodeTo: theSP header: methodHeader [
	"Assuming the primFailCode is non-zero, check if the method consumes the error code
	 and if so, assign it through theSP.  Then zero the primFailCode.  This is infrequent code,
	 so keep it out of the common path."
	<var: 'theSP' type: #'char *'>
	<inline: #never>
	| initialPC |
	self assert: primFailCode ~= 0.
	initialPC := (self initialIPForHeader: methodHeader method: newMethod) + (self sizeOfCallPrimitiveBytecode: methodHeader).
	(objectMemory byteAt: initialPC) = (self longStoreBytecodeForHeader: methodHeader) ifTrue:
		[stackPages longAtPointer: theSP put: self getErrorObjectFromPrimFailCode].
	 primFailCode := 0
]

{ #category : #'internal interpreter access' }
StackInterpreter >> receiver [
	<inline: true>
	^stackPages longAt: localFP + FoxReceiver
]

{ #category : #'callback support' }
StackInterpreter >> reestablishContextPriorToCallback: callbackContext [
	"callbackContext is an activation of invokeCallback:[stack:registers:jmpbuf:].
	 Its sender is the VM's state prior to the callback.  Reestablish that state,
	 and mark calloutContext as dead."
	| calloutContext theFP thePage |
	<export: true>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	self flag: #obsolete.
	(self isLiveContext: callbackContext) ifFalse:
		[^false].
	calloutContext := self externalInstVar: SenderIndex ofContext: callbackContext.
	(self isLiveContext: calloutContext) ifFalse:
		[^false].
	"We're about to leave this stack page; must save the current frame's instructionPointer."
	self push: instructionPointer.
	self externalWriteBackHeadFramePointers.
	"Mark callbackContext as dead; the common case is that it is the current frame.
	 We go the extra mile for the debugger."
	(self isSingleContext: callbackContext)
		ifTrue: [self markContextAsDead: callbackContext]
		ifFalse:
			[theFP := self frameOfMarriedContext: callbackContext.
			 framePointer = theFP "common case"
				ifTrue:
					[(self isBaseFrame: theFP)
						ifTrue: [stackPages freeStackPage: stackPage]
						ifFalse: "calloutContext is immediately below on the same page.  Make it current."
							[instructionPointer := (self frameCallerSavedIP: framePointer) asUnsignedInteger.
							 stackPointer := framePointer + (self frameStackedReceiverOffset: framePointer) + objectMemory wordSize.
							 framePointer := self frameCallerFP: framePointer.
							 ^true]]
				ifFalse:
					[self externalDivorceFrame: theFP andContext: callbackContext.
					 self markContextAsDead: callbackContext]].
	"Make the calloutContext the active frame.  The case where calloutContext
	 is immediately below callbackContext on the same page is handled above."
	(self isStillMarriedContext: calloutContext)
		ifTrue:
			[theFP := self frameOfMarriedContext: calloutContext.
			 thePage := stackPages stackPageFor: theFP.
			 "findSPOf:on: points to the word beneath the instructionPointer, but
			  there is no instructionPointer on the top frame of the current page."
			 self assert: thePage ~= stackPage.
			 stackPointer := (self findSPOf: theFP on: thePage) - objectMemory wordSize.
			 framePointer := theFP.
			 self assert: stackPointer < framePointer]
		ifFalse:
			[thePage := self makeBaseFrameFor: calloutContext.
			 self setStackPointersFromPage: thePage].
	instructionPointer := self popStack.
	self setStackPageAndLimit: thePage.
	^true
]

{ #category : #'inline primitive ffi abi' }
StackInterpreter >> reloadLowcodeStateAfterCallout [
	<option: #LowcodeVM>
	<var: #initialShadowCallStackPointer type: #'char*' >
	
	| calloutStateSize initialShadowCallStackPointer |
	calloutStateSize := self sizeof: #'sqLowcodeCalloutState'.
	initialShadowCallStackPointer := (self shadowCallStackPointerIn: localFP) - 1.
	
	initialShadowCallStackPointer := self cCoerce: ((self cCoerce: initialShadowCallStackPointer - calloutStateSize to: 'size_t') bitAnd: -16) to: 'char*'.
	lowcodeCalloutState := self cCoerce: initialShadowCallStackPointer to: #'sqLowcodeCalloutState*'.
]

{ #category : #'object memory support' }
StackInterpreter >> remapCallbackState [
	"Callback support - trace suspended callback list"
	1 to: jmpDepth do:
		[:i| | oop |
		oop := suspendedCallbacks at: i.
		(objectMemory shouldRemapOop: oop) ifTrue:
			[suspendedCallbacks at: i put: (objectMemory remapObj: oop)].
		oop := suspendedMethods at: i.
		(objectMemory shouldRemapObj: oop) ifTrue:
			[suspendedMethods at: i put: (objectMemory remapObj: oop)]]
]

{ #category : #'stack bytecodes' }
StackInterpreter >> remoteIsInstVarAccess [
	"If this byte is set in the second byte (zero-based) of the instruction, 
	the remote temp instruction is in fact a remote inst var access"
	<api>
	<cmacro>
	^ 128 "1 << 7"
]

{ #category : #'process primitive support' }
StackInterpreter >> removeFirstLinkOfList: aList [ 
	"Remove the first process from the given linked list."
	| first last next |
	self deny: (objectMemory isForwarded: aList).
	first := objectMemory fetchPointer: FirstLinkIndex ofObject: aList.
	last := objectMemory fetchPointer: LastLinkIndex ofObject: aList.
	self deny: (objectMemory isForwarded: first).
	self deny: (objectMemory isForwarded: last).
	first = last
		ifTrue:
			[objectMemory
				storePointerUnchecked: FirstLinkIndex ofObject: aList withValue: objectMemory nilObject;
				storePointerUnchecked: LastLinkIndex ofObject: aList withValue: objectMemory nilObject]
		ifFalse:
			[next := objectMemory fetchPointer: NextLinkIndex ofObject: first.
			 objectMemory storePointer: FirstLinkIndex ofObject: aList withValue: next].
	objectMemory storePointerUnchecked: NextLinkIndex ofObject: first withValue: objectMemory nilObject.
	^first
]

{ #category : #'process primitive support' }
StackInterpreter >> removeProcess: aProcess fromList: aList [ 
	"Remove a given process from a linked list. May fail if aProcess is not on the list."
	| firstLink lastLink nextLink tempLink |
	self deny: (objectMemory isForwarded: aProcess).
	self deny: (objectMemory isForwarded: aList).
	firstLink := objectMemory fetchPointer: FirstLinkIndex ofObject: aList.
	lastLink := objectMemory fetchPointer: LastLinkIndex ofObject: aList.
	self deny: (objectMemory isForwarded: firstLink).
	self deny: (objectMemory isForwarded: lastLink).
	aProcess  = firstLink
		ifTrue:
			[nextLink := objectMemory fetchPointer: NextLinkIndex ofObject: aProcess.
			 self deny: (objectMemory isForwarded: nextLink).
			 objectMemory storePointer: FirstLinkIndex ofObject: aList withValue: nextLink.
			 aProcess  = lastLink ifTrue:
				[objectMemory storePointerUnchecked: LastLinkIndex ofObject: aList withValue: objectMemory nilObject]]
		ifFalse:
			[tempLink := firstLink.
			 [self deny: (objectMemory isForwarded: tempLink).
			  tempLink = objectMemory nilObject ifTrue:
				[self primitiveFail. ^self].
			  nextLink := objectMemory fetchPointer: NextLinkIndex ofObject: tempLink.
			  nextLink = aProcess] whileFalse:
				[tempLink := objectMemory fetchPointer: NextLinkIndex ofObject: tempLink].
			 nextLink := objectMemory fetchPointer: NextLinkIndex ofObject: aProcess.
			 objectMemory storePointer: NextLinkIndex ofObject: tempLink withValue: nextLink.
			 aProcess  = lastLink ifTrue:
				[objectMemory storePointer: LastLinkIndex ofObject: aList withValue: tempLink]].
	objectMemory storePointer: NextLinkIndex ofObject: aProcess withValue: objectMemory nilObject
]

{ #category : #'debug printing' }
StackInterpreter >> resetStackPrintedCount [

	printedStackFrames := maxStackMessagePrinted := 0
]

{ #category : #'sista bytecodes' }
StackInterpreter >> respondToSistaTrap [
	| ourContext |
	<sharedCodeInCase: #unconditionnalTrapBytecode>
	messageSelector := objectMemory splObj: SelectorSistaTrap.
	ourContext := self ensureFrameIsMarried: localFP SP: localSP.
	self internalPush: ourContext.
	argumentCount := 0.
	self normalSend
]

{ #category : #'miscellaneous bytecodes' }
StackInterpreter >> respondToUnknownBytecode [
	"If an error selector is available then send it to the activeContext, otherwise abort."
	<sharedCodeInCase: #unknownBytecode>
	| ourContext |
	messageSelector := objectMemory maybeSplObj: SelectorUnknownBytecode.
	(messageSelector isNil
	or: [messageSelector = objectMemory nilObject]) ifTrue:
		[self error: 'Unknown bytecode'].
	ourContext := self ensureFrameIsMarried: localFP SP: localSP.
	"undo fetch of bytecode so that context's pc is pointing to the unknown bytecode."
	localIP := localIP - 1.
	self internalPush: ourContext.
	argumentCount := 0.
	self normalSend
]

{ #category : #'callback support' }
StackInterpreter >> restoreCStackStateForCallbackContext: vmCallbackContext [
	<var: #vmCallbackContext type: #'VMCallbackContext *'>
		
	self cCode:
			[self memcpy: reenterInterpreter
				_: vmCallbackContext savedReenterInterpreter asVoidPointer
				_: (self sizeof: #'jmp_buf')]
		inSmalltalk:
			[ reenterInterpreter := vmCallbackContext savedReenterInterpreter ].
	
]

{ #category : #'stack pages' }
StackInterpreter >> restoreStackLimit [
	"restore the stackLimit if it has been smashed."
	<inline: true>
	stackPage stackLimit: stackPage realStackLimit.
	stackLimit := stackPage stackLimit
]

{ #category : #'process primitive support' }
StackInterpreter >> resume: aProcess [
	"Replaced by resume:preemptedYieldingIf:"
	"Make aProcess runnable and if its priority is higher than
	 that of the current process, preempt the current process.
	 Answer if the current process was preempted.  Override
	 to add tracing info (see resume:from:)."
	<doNotGenerate>
	self shouldNotImplement
]

{ #category : #'process primitive support' }
StackInterpreter >> resume: aProcess preemptedYieldingIf: yieldImplicitly [
	"Make aProcess runnable and if its priority is higher than  that of the
	 current process, preempt the current process.   Answer if the current
	 process was preempted.  If the current process was preempted then if
	 yieldImplicitly add the current process to the back of its run queue,
	 causing an implicit yiled to other processes on the run queue,  otherwise
	 add the current process to the front of its run queue, hence not yielding.
	 Blue book behaviour is to yield implicitly but is arguably incorrect."
	| activeProc activePriority newPriority |
	<inline: false>
	activeProc := self activeProcess.
	activePriority := self quickFetchInteger: PriorityIndex ofObject: activeProc.
	newPriority := self quickFetchInteger: PriorityIndex ofObject: aProcess.
	newPriority <= activePriority ifTrue:
		[self putToSleep: aProcess yieldingIf: true.
		 ^false].
	self putToSleep: activeProc yieldingIf: yieldImplicitly.
	self transferTo: aProcess.
	^true
]

{ #category : #'primitive support' }
StackInterpreter >> retryPrimitiveOnFailure [
	"In Spur two cases of primitive failure are handled specially.  A primitive may fail due to validation
	 encountering a forwarder. On failure, check the accessorDepth for the primitive and if non-negative
	 scan the args to the depth, following any forwarders.  Retry the primitive if any are found.  Hence
	 lazily and transparently following forwarders on primtiive failure.  Additionally a prmitive might fail
	 due to an allocation failing.  Retry if external primitives have failed with PrimErrNoMemory after running
	 first the scavenger and then on a subsequent failure, the global mark-sweep collector.  Hence lazily
	 and transparently GC on memory exhaustion."
	<option: #SpurObjectMemory>
	<inline: false>
	| gcDone followDone canRetry retry retried |
	gcDone := 0.
	followDone := canRetry := retried := false.
	[retry := false.
	 primFailCode = PrimErrNoMemory
		ifTrue:
			[(gcDone := gcDone + 1) = 1 ifTrue:
				[canRetry := self isExternalPrimitiveCall: newMethod].
			 canRetry ifTrue:
				 [gcDone = 1 ifTrue:
					[objectMemory scavengingGC].
				 gcDone = 2 ifTrue:
					[objectMemory fullGC].
				 retry := gcDone <= 2]]
		 ifFalse:
			[followDone ifFalse:
				[followDone := true.
				 retry := self checkForAndFollowForwardedPrimitiveState]].
	 retry] whileTrue:
		[self assert: primFailCode ~= 0.
		 retried := true.
		 self initPrimCall.
		 self cCode: [] inSmalltalk:
			[self maybeMapPrimitiveFunctionPointerBackToSomethingEvaluable].
		 self dispatchFunctionPointer: primitiveFunctionPointer].
	^retried
]

{ #category : #'callback support' }
StackInterpreter >> returnAs: returnTypeOop ThroughCallback: vmCallbackContext Context: callbackMethodContext [
	"callbackMethodContext is an activation of invokeCallback:[stack:registers:jmpbuf:].
	 Its sender is the VM's state prior to the callback.  Reestablish that state (via longjmp),
	 and mark callbackMethodContext as dead."
	<export: true>
	<var: #vmCallbackContext type: #'VMCallbackContext *'>
	| calloutMethodContext theFP thePage |
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	self assert: primFailCode = 0.
	self assert: (objectMemory isIntegerObject: returnTypeOop).
	self assert: (objectMemory isImmediate: vmCallbackContext asInteger) not.
	self assert: ((objectMemory addressCouldBeObj: callbackMethodContext)
				and: [objectMemory isContext: callbackMethodContext]).
	self assert: (debugCallbackPath := 0) = 0.
	((objectMemory isIntegerObject: returnTypeOop)
	 and: [self isLiveContext: callbackMethodContext]) ifFalse:
		[self assert: (debugCallbackPath := 1) = 1.
		 ^false].
	calloutMethodContext := self externalInstVar: SenderIndex ofContext: callbackMethodContext.
	(self isLiveContext: calloutMethodContext) ifFalse:
		[self assert: (debugCallbackPath := 2) = 2.
		 ^false].
	self assert: (debugCallbackReturns := debugCallbackReturns + 1) > 0.
	"self assert: debugCallbackReturns < 3802."
	"We're about to leave this stack page; must save the current frame's instructionPointer."
	self push: instructionPointer.
	self externalWriteBackHeadFramePointers.
	"Mark callbackMethodContext as dead; the common case is that it is the current frame.
	 We go the extra mile for the debugger."
	(self isSingleContext: callbackMethodContext)
		ifTrue:
			[self assert: (debugCallbackPath := debugCallbackPath bitOr: 4) > 0.
		 	 self markContextAsDead: callbackMethodContext]
		ifFalse:
			[self assert: (debugCallbackPath := debugCallbackPath bitOr: 8) > 0.
		 	 theFP := self frameOfMarriedContext: callbackMethodContext.
			 self assert: (self frameReceiver: theFP) = (objectMemory splObj: ClassAlien).
			 framePointer = theFP "common case"
				ifTrue:
					[self assert: (debugCallbackPath := debugCallbackPath bitOr: 16) > 0.
		 			 (self isBaseFrame: theFP) ifFalse: "calloutMethodContext is immediately below on the same page.  Make it current."
						[self assert: (debugCallbackPath := debugCallbackPath bitOr: 32) > 0.
		 				 instructionPointer := (self frameCallerSavedIP: theFP) asUnsignedInteger.
						 stackPointer := theFP + (self frameStackedReceiverOffset: theFP) + objectMemory wordSize.
						 framePointer := self frameCallerFP: theFP.
						 self setMethod: (self frameMethodObject: framePointer).
						 self restoreCStackStateForCallbackContext: vmCallbackContext.
						 self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer.
						 "N.B. siglongjmp is defines as _longjmp on non-win32 platforms.
						  This matches the use of _setjmp in ia32abicc.c."
						 self siglong: vmCallbackContext trampoline jmp: (self integerValueOf: returnTypeOop).
						 ^true].
					 stackPages freeStackPage: stackPage]
				ifFalse:
					[self assert: (debugCallbackPath := debugCallbackPath bitOr: 64) > 0.
		 			 self externalDivorceFrame: theFP andContext: callbackMethodContext.
					 self markContextAsDead: callbackMethodContext]].
	"Make the calloutMethodContext the active frame.  The case where calloutMethodContext
	 is immediately below callbackMethodContext on the same page is handled above."
	(self isStillMarriedContext: calloutMethodContext)
		ifTrue:
			[self assert: (debugCallbackPath := debugCallbackPath bitOr: 128) > 0.
		 	 theFP := self frameOfMarriedContext: calloutMethodContext.
			 thePage := stackPages stackPageFor: theFP.
			 "findSPOf:on: points to the word beneath the instructionPointer, but
			  there is no instructionPointer on the top frame of the current page."
			 self assert: thePage ~= stackPage.
			 stackPointer := thePage headFP = theFP
								ifTrue: [thePage headSP]
								ifFalse: [(self findSPOf: theFP on: thePage) - objectMemory wordSize].
			 framePointer := theFP.
			 self assert: stackPointer < framePointer]
		ifFalse:
			[self assert: (debugCallbackPath := debugCallbackPath bitOr: 256) > 0.
		 	 thePage := self makeBaseFrameFor: calloutMethodContext.
			 self setStackPointersFromPage: thePage].
	instructionPointer := self popStack.
	self setMethod: (objectMemory fetchPointer: MethodIndex ofObject: calloutMethodContext).
	self setStackPageAndLimit: thePage.
	self restoreCStackStateForCallbackContext: vmCallbackContext.
	primitiveFunctionPointer := vmCallbackContext savedPrimFunctionPointer.
	"N.B. siglongjmp is defined as _longjmp on non-win32 platforms.
	  This matches the use of _setjmp in ia32abicc.c."
	self siglong: vmCallbackContext trampoline jmp: (self integerValueOf: returnTypeOop).
	"NOTREACHED"
	^true
]

{ #category : #'return bytecodes' }
StackInterpreter >> returnFalse [
	localReturnValue := objectMemory falseObject.
	self commonReturn
]

{ #category : #'return bytecodes' }
StackInterpreter >> returnNil [
	localReturnValue := objectMemory nilObject.
	self commonReturn
]

{ #category : #'return bytecodes' }
StackInterpreter >> returnNilFromBlock [
	"Return nil to the caller of the current block activation."
	localReturnValue := objectMemory nilObject.
	self commonCallerReturn
]

{ #category : #'return bytecodes' }
StackInterpreter >> returnReceiver [
	localReturnValue := self receiver.
	self commonReturn
]

{ #category : #'return bytecodes' }
StackInterpreter >> returnTopFromBlock [
	"Return top-of-stack to the caller of the current block activation."
	localReturnValue := self internalStackTop.
	self commonCallerReturn
]

{ #category : #'return bytecodes' }
StackInterpreter >> returnTopFromMethod [
	localReturnValue := self internalStackTop.
	self commonReturn
]

{ #category : #'return bytecodes' }
StackInterpreter >> returnTrue [
	localReturnValue := objectMemory trueObject.
	self commonReturn
]

{ #category : #'image save/restore' }
StackInterpreter >> reverseBytesInImage [
	"Byte-swap all words in memory after reading in the entire image file with bulk read. Contributed by Tim Rowledge."

	"First, byte-swap every word in the image. This fixes objects headers."
	objectMemory reverseBytesInMemory.

	"Second, return the bytes of bytes-type objects to their
	 orginal order, and perform any other format conversions."
	self updateObjectsPostByteSwap
]

{ #category : #'I/O primitive support' }
StackInterpreter >> reverseDisplayFrom: startIndex to: endIndex [ 
	"Reverse the given range of Display pixels, rounded to whole word boundary.
	Used to give feedback during VM activities such as garbage collection when debugging.
	 It is assumed that the given word range falls entirely within the first line of the Display."
	
	| wordStartIndex wordEndIndex primFailCodeValue |
	self postGCUpdateDisplayBits ifFalse:
		[^self].
	(displayBits = 0 or: [(objectMemory isImmediate: displayBits asInteger) or: [displayDepth <= 0]]) ifTrue: [^self].
	wordStartIndex := (startIndex max: 0) * displayDepth // 32.
	wordEndIndex := (endIndex min: displayWidth) * displayDepth // 32.
	displayBits asInteger + (wordStartIndex * 4) to: displayBits asInteger + (wordEndIndex * 4) by: 4 do:
		[:ptr | | reversed |
		reversed := (objectMemory long32At: ptr) bitXor: 16rFFFFFFFF.
		objectMemory long32At: ptr put: reversed].
	primFailCodeValue := primFailCode.
	self initPrimCall.
	self updateDisplayLeft: 0 Top: 0 Right: displayWidth Bottom: 1.
	self ioForceDisplayUpdate.
	primFailCode := primFailCodeValue
]

{ #category : #'method lookup cache' }
StackInterpreter >> rewriteMethodCacheEntryForExternalPrimitiveToFunction: localPrimAddress [
	"Rewrite an existing entry in the method cache with a new primitive function address.
	 Used by primitiveExternalCall to make direct calls to found external prims, or quickly
	 fail not found external prims."
	<inline: false>
	<var: #localPrimAddress declareC: 'void (*localPrimAddress)(void)'>
	(methodCache at: lastMethodCacheProbeWrite + MethodCacheMethod) = newMethod ifTrue:
		[methodCache
			at: lastMethodCacheProbeWrite + MethodCachePrimFunction
			put: (self cCoerce: localPrimAddress to: #'sqIntptr_t')]
]

{ #category : #'primitive support' }
StackInterpreter >> roomToPushNArgs: n [
	"Answer if there is room to push n arguments onto the current stack.  We assume
	 this is called by primitives that check there is enough room in any new context, and
	 won't actually push the arguments in the current context if the primitive fails.  With
	 this assumption it is safe to answer based on the maximum argument count, /not/
	 the ammount of space in the current frame were it converted to a context.."
	false
		ifTrue: "old code that checked size of context..."
			[| cntxSize |
			 self assert: method = (stackPages longAt: framePointer + FoxMethod).
			 cntxSize := (self methodHeaderIndicatesLargeFrame: (objectMemory methodHeaderOf: method))
							ifTrue: [LargeContextSlots - CtxtTempFrameStart]
							ifFalse: [SmallContextSlots - CtxtTempFrameStart].
			 ^self stackPointerIndex + n <= cntxSize]
		ifFalse: "simpler code that simply insists args are <= max arg count"
			[^n <= (LargeContextSlots - CtxtTempFrameStart)]
]

{ #category : #simulation }
StackInterpreter >> runLeakChecker [
	<doNotGenerate>
	| oldCheckForLeaks |
	oldCheckForLeaks := objectMemory checkForLeaks.
	objectMemory setCheckForLeaks: -1.
	[objectMemory runLeakCheckerFor: GCModeIncremental]
		ensure:
			[objectMemory setCheckForLeaks: oldCheckForLeaks]
]

{ #category : #'frame access' }
StackInterpreter >> safeFindFrameAbove: theFP on: thePage startingFrom: startFrame [
	"Search for the previous frame to theFP (the frame that theFP calls).
	 DO NOT CALL THIS WITH theFP == localFP OR theFP == framePointer!"
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #startFrame type: #'char *'>
	<returnTypeC: #'char *'>
	| aFrame prevFrame |
	<inline: true>
	<var: #aFrame type: #'char *'>
	<var: #prevFrame type: #'char *'>
	self assert: (stackPages isFree: thePage) not.
	startFrame = theFP ifTrue:
		[^nil].
	aFrame := startFrame.
	[prevFrame := aFrame.
	 aFrame := self frameCallerFP: aFrame.
	 aFrame ~= 0] whileTrue:
		[theFP = aFrame ifTrue:
			[^prevFrame]].
	^nil
]

{ #category : #'compiled methods' }
StackInterpreter >> safeMethodClassOf: methodPointer [
	"Safe version of methodClassOf: that deals with malformed compiled methods,
	 etc, and does not fixup forwarding pointers.."
	| literal maybeClass |
	literal := self literal: (objectMemory literalCountOf: methodPointer) - 1 ofMethod: methodPointer.
	(objectMemory isOopForwarded: literal) ifTrue:
		[literal := objectMemory followForwarded: literal].
	((objectMemory isPointers: literal) and: [(objectMemory numSlotsOf: literal) > ValueIndex]) ifFalse:
		[^objectMemory nilObject].
	maybeClass := objectMemory fetchPointer: ValueIndex ofObject: literal.
	(objectMemory isOopForwarded: maybeClass) ifTrue:
		[maybeClass := objectMemory followForwarded: maybeClass].
	^maybeClass
]

{ #category : #'primitive support' }
StackInterpreter >> saneFunctionPointerForFailureOfPrimIndex: primIndex [
	| basePrimitive |
	<var: 'basePrimitive' declareC: 'void (*basePrimitive)(void)'>
	basePrimitive := self functionPointerFor: primIndex inClass: objectMemory nilObject.
	^primitiveFunctionPointer = basePrimitive
	  or: [(basePrimitive = #primitiveExternalCall and: [self isPrimitiveFunctionPointerAnIndex not]) 
	  or: [(self isMetaPrimitiveIndex: primIndex) and: [metaAccessorDepth > -2]]]
]

{ #category : #'compiled methods' }
StackInterpreter >> saneMethodClassAssociationIn: methodObj numLiterals: numLiterals [
	| shouldBeAssoc |
	shouldBeAssoc := self literal: numLiterals - 1 ofMethod: methodObj.
	(objectMemory isForwarded: shouldBeAssoc) ifTrue:
		[shouldBeAssoc := objectMemory followForwarded: shouldBeAssoc].
	^(objectMemory isPointers: shouldBeAssoc)
	 and: [(objectMemory numSlotsOf: shouldBeAssoc) > ValueIndex
	 and: [self addressCouldBeClassObj: (objectMemory noFixupFollowField: ValueIndex ofObject: shouldBeAssoc)]]
]

{ #category : #'callback support' }
StackInterpreter >> saveCStackStateForCallbackContext: vmCallbackContext [
	<var: #vmCallbackContext type: #'VMCallbackContext *'>
		
	self cCode:
			[self memcpy: vmCallbackContext savedReenterInterpreter asVoidPointer
				_: reenterInterpreter
				_: (self sizeof: #'jmp_buf')]
		inSmalltalk:
			[ vmCallbackContext savedReenterInterpreter: reenterInterpreter].
	
]

{ #category : #'process primitive support' }
StackInterpreter >> schedulerPointer [

	^ objectMemory fetchPointer: ValueIndex ofObject: (objectMemory splObj: SchedulerAssociation)
]

{ #category : #'send bytecodes' }
StackInterpreter >> secondExtendedSendBytecode [
	"This replaces the Blue Book double-extended super-send [134],
	which is subsumed by the new double-extended do-anything [132].
	It offers a 2-byte send of 0-3 args for up to 63 literals, for which 
	the Blue Book opcode set requires a 3-byte instruction."

	| descriptor |
	descriptor := self fetchByte.
	messageSelector := self literal: (descriptor bitAnd: 16r3F).
	argumentCount := descriptor >> 6.
	self normalSend.

]

{ #category : #'debug printing' }
StackInterpreter >> selectorOfContext: aContext [
	(objectMemory isContext: aContext) ifFalse:
		[^nil].
	^self findSelectorOfMethod: (objectMemory fetchPointer: MethodIndex ofObject: aContext)
]

{ #category : #'debug support' }
StackInterpreter >> sendBreak: selectorString point: selectorLength receiver: receiverOrNil [
	<doNotGenerate> "C version is in platforms/Cross/vm/dispdbg.h"
	"self shortPrintFrameAndCallers: localFP"
	| i |
	breakSelectorLength = selectorLength ifTrue:
		[i := breakSelectorLength.
		 [i > 0] whileTrue:
			[(objectMemory byteAt: selectorString + i - 1) = (breakSelector at: i) asInteger
				ifTrue: [(i := i - 1) = 0 ifTrue:
							[self changed: #byteCountText.
							 self halt: 'Send of '
									, breakSelector,
									(receiverOrNil
										ifNotNil: [' to ', (self shortPrint: receiverOrNil)]
										ifNil: [''])]]
				ifFalse: [i := 0]]]
]

{ #category : #'debug support' }
StackInterpreter >> sendBreakpoint: selector receiver: rcvr [
	<inline: true>
	self sendBreak: (objectMemory firstFixedFieldOfMaybeImmediate: selector)
		point: (objectMemory lengthOfMaybeImmediate: selector)
		receiver: rcvr
]

{ #category : #'callback support' }
StackInterpreter >> sendInvokeCallback: thunkPtr Stack: stackPtr Registers: regsPtr Jmpbuf: jmpBufPtr [
	"Send the 4 argument callback message invokeCallback:stack:registers:jmpbuf:
	 to Alien class with the supplied args.  The arguments are raw C addresses
	 and are converted to integer objects on the way."
	<export: true>
	| classTag |
	classTag := self fetchClassTagOfNonImm: (self splObj: ClassAlien).
	messageSelector := self splObj: SelectorInvokeCallback.
	argumentCount := 4.
	(self lookupInMethodCacheSel: messageSelector classTag: classTag) ifFalse:
	 	[(self lookupOrdinaryNoMNUEtcInClass: (objectMemory classForClassTag: classTag)) ~= 0 ifTrue:
			[^false]].
	((self argumentCountOf: newMethod) = 4
	and: [primitiveFunctionPointer = 0]) ifFalse:
		[^false].
	self push: (self splObj: ClassAlien). "receiver"
	self push: (self positiveMachineIntegerFor: thunkPtr).
	self push: (self positiveMachineIntegerFor: stackPtr).
	self push: (self positiveMachineIntegerFor: regsPtr).
	self push: (self positiveMachineIntegerFor: jmpBufPtr).
	self ifAppropriateCompileToNativeCode: newMethod selector: messageSelector.
	self justActivateNewMethod: false. "either interpreted or machine code"
	(self isMachineCodeFrame: framePointer) ifFalse:
		[self maybeFlagMethodAsInterpreted: newMethod].
	self checkForStackOverflow.
	self enterSmalltalkExecutiveFromCallback.
	"not reached"
	^true
]

{ #category : #'callback support' }
StackInterpreter >> sendInvokeCallbackContext: vmCallbackContext [
	"Send the calllback message to Alien class with the supplied arg(s).  Use either the 1 arg
	 invokeCallbackContext: or the 4 arg invokeCallback:stack:registers:jmpbuf: message,
	 depending on what selector is installed in the specialObjectsArray. Note that if invoking the
	 legacy invokeCallback:stack:registers:jmpbuf: we pass the vmCallbackContext as the jmpbuf
	 argument (see reestablishContextPriorToCallback:). The arguments are raw C addresses and
	 are converted to integer objects on the way. sendInvokeCallbackContext: &
	 returnAs:ThroughCallback:Context: along with ownVM: and disownVM: conspire to save and
	 restore newMethod, argumentCount and primitiveFunctionPointer around a callback.
	 The VM depends on argumentCount being correct to cut-back the correct number of
	 arguments on primitive return.  If a primitive that invokes a callback fails after invoking a
	 callback (a bad idea, but s**t happens during development) then newMethod is required to
	 activate the right faling method, and Spur expects primitiveFunctionPointer to be valid, so
	 asserts will fail misleadingly if not."
	<export: true>
	<var: #vmCallbackContext type: #'VMCallbackContext *'>
	| classTag |
	vmCallbackContext savedPrimFunctionPointer: primitiveFunctionPointer.
	classTag := self fetchClassTagOfNonImm: (objectMemory splObj: ClassAlien).
	messageSelector := self splObj: SelectorInvokeCallback.
	(self lookupInMethodCacheSel: messageSelector classTag: classTag) ifFalse:
	 	[(self lookupOrdinaryNoMNUEtcInClass: (objectMemory classForClassTag: classTag)) ~= 0 ifTrue:
			[^false]].
	primitiveFunctionPointer ~= 0 ifTrue:
		[primitiveFunctionPointer := vmCallbackContext savedPrimFunctionPointer.
		 ^false].
	self assert: (debugCallbackInvokes := debugCallbackInvokes + 1) > 0.
	"self assert: debugCallbackInvokes < 3802."
	self saveCStackStateForCallbackContext: vmCallbackContext.
	self push: (objectMemory splObj: ClassAlien). "receiver"
	(self argumentCountOf: newMethod) = 4 ifTrue:
		[self push: (self positiveMachineIntegerFor: vmCallbackContext thunkp asUnsignedInteger).
		 self push: (self positiveMachineIntegerFor: vmCallbackContext stackp asUnsignedInteger).
		 self push: (self positiveMachineIntegerFor: vmCallbackContext intregargsp asUnsignedInteger)].
	self push: (self positiveMachineIntegerFor: vmCallbackContext asUnsignedInteger).
	self ifAppropriateCompileToNativeCode: newMethod selector: messageSelector.
	self justActivateNewMethod: false. "either interpreted or machine code"
	(self isMachineCodeFrame: framePointer) ifFalse:
		[self maybeFlagMethodAsInterpreted: newMethod].
	self checkForStackOverflow.
	self assert: (self frameReceiver: framePointer) = (objectMemory splObj: ClassAlien).
	self enterSmalltalkExecutiveFromCallback.
	"not reached"
	^true
]

{ #category : #'send bytecodes' }
StackInterpreter >> sendLiteralSelector0ArgsBytecode [
	"Can use any of the first 16 literals for the selector."
	| rcvr |
	messageSelector := self literal: (currentBytecode bitAnd: 16rF).
	argumentCount := 0.
	rcvr := self internalStackValue: 0.
	lkupClassTag := objectMemory fetchClassTagOf: rcvr.
	self assert: lkupClassTag ~= objectMemory nilObject.
	self commonSendOrdinary
]

{ #category : #'send bytecodes' }
StackInterpreter >> sendLiteralSelector1ArgBytecode [
	"Can use any of the first 16 literals for the selector."
	| rcvr |
	messageSelector := self literal: (currentBytecode bitAnd: 16rF).
	argumentCount := 1.
	rcvr := self internalStackValue: 1.
	lkupClassTag := objectMemory fetchClassTagOf: rcvr.
	self assert: lkupClassTag ~= objectMemory nilObject.
	self commonSendOrdinary
]

{ #category : #'send bytecodes' }
StackInterpreter >> sendLiteralSelector2ArgsBytecode [
	"Can use any of the first 16 literals for the selector."
	| rcvr |
	messageSelector := self literal: (currentBytecode bitAnd: 16rF).
	argumentCount := 2.
	rcvr := self internalStackValue: 2.
	lkupClassTag := objectMemory fetchClassTagOf: rcvr.
	self assert: lkupClassTag ~= objectMemory nilObject.
	self commonSendOrdinary
]

{ #category : #'debug support' }
StackInterpreter >> setBreakMNUSelector: aString [
	<api>
	<var: #aString type: #'char *'>
	(breakSelector := aString)
		ifNil: [breakSelectorLength := objectMemory minSmallInteger "nil's effective length is zero"]
		ifNotNil: [breakSelectorLength := (self strlen: aString) negated]
]

{ #category : #'debug support' }
StackInterpreter >> setBreakSelector: aString [
	<api>
	<var: #aString type: #'char *'>
	(breakSelector := aString)
		ifNil: [breakSelectorLength := objectMemory minSmallInteger "nil's effective length is zero"]
		ifNotNil: [breakSelectorLength := self strlen: aString]
]

{ #category : #'primitive support' }
StackInterpreter >> setCheckAllocFiller: aBool [
	"If allocCheckFiller is true, words in newSpace from freeStart to scavengeThreshold
	 are filled with their address, and after each call of a plugin primitive, the VM checks
	 that freeStart points to a word containing the value of freeStart.  This is a simple
	 check for primitives overwriting the ends of an object."
	checkAllocFiller := aBool
]

{ #category : #'internal interpreter access' }
StackInterpreter >> setCogVMFlags: flags [
	"Set an array of flags indicating various properties of the Cog VM.
	 Bit 2: if set, implies preempting a process does not put it to the back of its run queue
	 Bit 4: if set, implies the new finalization scheme where WeakArrays are queued
	 Bit 5: if set, implies wheel events will be delivered as such and not mapped to arrow key events"
	flags asUnsignedInteger > 63 ifTrue:
		[^self primitiveFailFor: PrimErrUnsupported].
	"processHasThreadId := flags anyMask: 1. specific to CoInterpreterMT"
	"flagInterpretedMethods := flags anyMask: 2. specific to CoInterpreter"
	preemptionYields := flags noMask: 4.
	"noThreadingOfGUIThread := flags anyMask: 8.. specific to CoInterpreterMT"
	newFinalization := flags anyMask: 16.
	sendWheelEvents := flags anyMask: 32
]

{ #category : #'internal interpreter access' }
StackInterpreter >> setDesiredCogCodeSize: dccs [
	<inline: true>
	"This should perhaps be a no-op in the StackVM, but we implement it for the convenience of bootstrap scripts etc."
	theUnknownShort := dccs
]

{ #category : #'frame access' }
StackInterpreter >> setFrameContext: theFP to: aContext [
	<inline: true>
	<var: #theFP type: #'char *'>
	stackPages longAt: theFP + FoxThisContext put: aContext
]

{ #category : #'frame access' }
StackInterpreter >> setFrameHasContext: theFP [
	"See encodeFrameFieldHasContext:numArgs:"
	<inline: true>
	<var: #theFP type: #'char *'>
	stackPages byteAt: theFP + FoxFrameFlags + 2 put: 1
]

{ #category : #'frame access' }
StackInterpreter >> setFrameHasNativeFrame: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	self temporary: (self frameNumArgs: theFP) in: theFP put: (objectMemory splObj: LowcodeContextMark)
]

{ #category : #'frame access' }
StackInterpreter >> setFrameHasNotNativeFrame: theFP [
	<inline: true>
	<option: #LowcodeVM>
	<var: #theFP type: #'char *'>
	self temporary: (self frameNumArgs: theFP) in: theFP put: (objectMemory nilObject)
]

{ #category : #'plugin primitive support' }
StackInterpreter >> setFullScreenFlag: value [
	fullScreenFlag := value
]

{ #category : #'object memory support' }
StackInterpreter >> setGCMode: mode [
	"This is a no-op in the StackVM"
	^0
]

{ #category : #'stack pages' }
StackInterpreter >> setHeadFP: theFP andSP: theSP inPage: thePage [
	<inline: true>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	self assert: theSP < theFP.
	self assert: (theSP < thePage baseAddress
				and: [theSP > (thePage realStackLimit - (LargeContextSlots * objectMemory bytesPerOop))]).
	self assert: (theFP < thePage baseAddress
				and: [theFP > (thePage realStackLimit - (LargeContextSlots * objectMemory bytesPerOop / 2))]).
	thePage headFP: theFP; headSP: theSP
]

{ #category : #'image save/restore' }
StackInterpreter >> setImageHeaderFlagsFrom: headerFlags [
	"Set the flags that are contained in the 7th long of the image header."
	imageHeaderFlags := headerFlags. "so as to preserve unrecognised flags."
	fullScreenFlag := headerFlags bitAnd: 1.
	imageFloatsBigEndian := (headerFlags noMask: 2) ifTrue: [1] ifFalse: [0].
	"processHasThreadId := headerFlags anyMask: 4. specific to CoInterpreterMT"
	"flagInterpretedMethods := headerFlags anyMask: 8. specific to CoInterpreter"
	preemptionYields := headerFlags noMask: 16.
	"noThreadingOfGUIThread := headerFlags anyMask: 32. specific to CoInterpreterMT"
	newFinalization := headerFlags anyMask: 64.
	sendWheelEvents := headerFlags anyMask: 128
]

{ #category : #'primitive support' }
StackInterpreter >> setInterruptCheckChain: aFunction [
	<var: #aFunction declareC: 'void (*aFunction)()'>
	<var: #prevFunction declareC: 'void (*prevFunction)()'>
	<returnTypeC: 'void (*setInterruptCheckChain(void (*aFunction)(void)))()'>
	<export: true>
	| prevFunction |
	prevFunction := interruptCheckChain.
	interruptCheckChain := aFunction.
	^prevFunction
]

{ #category : #'plugin primitive support' }
StackInterpreter >> setInterruptKeycode: value [
	interruptKeycode := value
]

{ #category : #'plugin primitive support' }
StackInterpreter >> setInterruptPending: value [
	self forceInterruptCheck.
	interruptPending := value
]

{ #category : #'process primitive support' }
StackInterpreter >> setMaxExtSemSizeTo: maxExtSemTabSize [
	maxExtSemTabSizeSet := true.
	self ioSetMaxExtSemTableSize: maxExtSemTabSize
]

{ #category : #'debug printing' }
StackInterpreter >> setMaxStacksToPrint: anInteger [
	<api>
	maxStacksToPrint := anInteger
]

{ #category : #'internal interpreter access' }
StackInterpreter >> setMethod: aMethodObj [
	"Set the method and determine the bytecode set based on the method header's sign.
	 If MULTIPLEBYTECODESETS then a negative header selects the alternate bytecode set.
	 Conditionalizing the code on MULTIPLEBYTECODESETS allows the header sign bit to be
	 used for other experiments."
	<inline: true>
	method := aMethodObj.
	self assert: (objectMemory isOopCompiledMethod: method).
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [bytecodeSetSelector := (self methodUsesAlternateBytecodeSet: method)
											ifTrue: [256]
											ifFalse: [0]]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> setMethod: aMethodObj methodHeader: methodHeader [
	"Set the method and determine the bytecode set based on the method header's sign.
	 If MULTIPLEBYTECODESETS then a negative header selects the alternate bytecode set.
	 Conditionalizing the code on MULTIPLEBYTECODESETS allows the header sign bit to be
	 used for other experiments."
	<inline: true>
	method := aMethodObj.
	self assert: (objectMemory isOopCompiledMethod: method).
	self assert: (objectMemory methodHeaderOf: method) = methodHeader.
	self cppIf: MULTIPLEBYTECODESETS
		ifTrue: [bytecodeSetSelector := (objectMemory headerIndicatesAlternateBytecodeSet: methodHeader)
											ifTrue: [256]
											ifFalse: [0]]
]

{ #category : #'compiled methods' }
StackInterpreter >> setMethodClassAssociationOf: methodPointer to: anObject [
	objectMemory
		storePointer: (objectMemory literalCountOf: methodPointer) + LiteralStart - 1
		ofObject: methodPointer
		withValue: anObject
]

{ #category : #'plugin primitive support' }
StackInterpreter >> setNextWakeupUsecs: value [
	<api>
	<var: #value type: #usqLong>
	nextWakeupUsecs := value
]

{ #category : #'plugin primitive support' }
StackInterpreter >> setSavedWindowSize: value [
	savedWindowSize := value
]

{ #category : #'process primitive support' }
StackInterpreter >> setSignalLowSpaceFlagAndSaveProcess [
	"The low space semaphore is about to be signaled. Set the signalLowSpace flag,
	 and force an interrupt check.  Save the currently active process in the special
	 objects array so that the low space handler will be able to determine the process
	 that first triggered a low space condition. The image's low space handler is expected
	 to nil out the special objects array slot when it handles the low space condition."

	| lastSavedProcess activeProc |
	<inline: false>
	DumpStackOnLowSpace ~= 0 ifTrue:
		[self printCallStack.
		 self printAllStacks].
	objectMemory signalLowSpace: true.
	objectMemory lowSpaceThreshold: 0. "disable additional interrupts until lowSpaceThreshold is reset by image"
	lastSavedProcess := objectMemory splObj: ProcessSignalingLowSpace.
	lastSavedProcess = objectMemory nilObject ifTrue:
		[activeProc := self activeProcess.
		objectMemory splObj: ProcessSignalingLowSpace put: activeProc].
	self forceInterruptCheck
]

{ #category : #'stack pages' }
StackInterpreter >> setStackPageAndLimit: thePage [
	"Set stackPage to a different page.  Set stackLimit unless it has
	 been smashed.  Make the stackPage the most recently used"
	<inline: true>
	<var: #thePage type: #'StackPage *'>
	self assert: thePage ~= 0.
	stackPage := thePage.
	stackLimit ~= self allOnesAsCharStar ifTrue:
		[stackLimit := stackPage stackLimit].
	stackPages markStackPageMostRecentlyUsed: thePage
]

{ #category : #'stack pages' }
StackInterpreter >> setStackPointersFromPage: thePage [
	<var: #thePage type: #'StackPage *'>
	<inline: true>
	stackPointer := thePage headSP.
	framePointer := thePage headFP
]

{ #category : #'object memory support' }
StackInterpreter >> setTraceFlagOnContextsFramesPageIfNeeded: aContext [
	| thePage |
	<inline: false>
	<var: #thePage type: #'StackPage *'>
	(self isStillMarriedContextDuringGC: aContext) ifTrue:
		[thePage := stackPages stackPageFor: (self frameOfMarriedContext: aContext).
		 self assert: (thePage trace between: StackPageUnreached and: StackPageTraced).
		 thePage trace = StackPageUnreached ifTrue:
			[thePage trace: StackPageReachedButUntraced]]
]

{ #category : #initialization }
StackInterpreter >> setupNativeStack [
	<option: #LowcodeVM>
	<var: #theNativeStackMemory type: #'char*'>
	<var: #theShadowCallStackMemory type: #'char*'>
	<inline: false>
	"This initializes an alternate stack that is used by the Lowcode instructions"
	| nativeStackMemorySize theNativeStackMemory shadowCallStackMemorySize theShadowCallStackMemory|
	nativeStackMemorySize := self nativeStackSize.
	theNativeStackMemory := self malloc: nativeStackMemorySize.
	nativeStackPointer := theNativeStackMemory + nativeStackMemorySize.
	
	shadowCallStackMemorySize := self shadowCallStackSize.
	theShadowCallStackMemory := self malloc: shadowCallStackMemorySize.
	shadowCallStackPointer := theShadowCallStackMemory + shadowCallStackMemorySize
]

{ #category : #'internal interpreter access' }
StackInterpreter >> shadowCallStackPointerIn: theFP [
	"See StackInterpreter class>>initializeFrameIndices"
	<option: #LowcodeVM>
	<inline: false>
	<returnTypeC: #'char*'>
	<var: #theFP type: #'char *'>
	^ stackPages pointerAtPointer: theFP + FoxReceiver - (BytesPerWord*5)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> shadowCallStackPointerIn: theFP put: valueOopPointer [
	"See StackInterpreter class>>initializeFrameIndices"
	<option: #LowcodeVM>
	<inline: false>
	<returnTypeC: #'char*'>
	<var: #theFP type: #'char *'>
	<var: #valueOopPointer type: #'char*'>
	^ stackPages pointerAtPointer: theFP + FoxReceiver - (BytesPerWord*5) put: valueOopPointer
]

{ #category : #'stack pages' }
StackInterpreter >> shadowCallStackSize [
	"1 MB shadow call stack size"
	^ 1 *1024 * 1024
]

{ #category : #'jump bytecodes' }
StackInterpreter >> shortConditionalJumpFalse [

	self jumplfFalseBy: (currentBytecode bitAnd: 7) + 1
]

{ #category : #'jump bytecodes' }
StackInterpreter >> shortConditionalJumpTrue [

	self jumplfTrueBy: (currentBytecode bitAnd: 7) + 1
]

{ #category : #simulation }
StackInterpreter >> shortPrint: oop [
	<doNotGenerate>
	| name classOop key |
	(objectMemory isImmediate: oop) ifTrue:
		[(objectMemory isImmediateCharacter: oop) ifTrue:
			[^(objectMemory characterValueOf: oop) < 256
				ifTrue:
					['=$', (objectMemory characterValueOf: oop) printString,
					' ($', (String with: (Character value: (objectMemory characterValueOf: oop))), ')']
				ifFalse:
					['=$', (objectMemory characterValueOf: oop) printString, '($???)']].
		(objectMemory isIntegerObject: oop) ifTrue:
			[^'=', (objectMemory integerValueOf: oop) printString,
			' (', (objectMemory integerValueOf: oop) hex, ')'].
		(objectMemory isImmediateFloat: oop) ifTrue:
			[^ '=', (objectMemory floatValueOf: oop) printString, ' (', oop hex, ')'].
		^'= UNKNOWN IMMEDIATE', ' (', (objectMemory integerValueOf: oop) hex, ')'].
	(objectMemory addressCouldBeObj: oop) ifFalse:
		[^(oop bitAnd: objectMemory allocationUnit - 1) ~= 0
			ifTrue: [' is misaligned']
			ifFalse: [self whereIs: oop]].
	(objectMemory isFreeObject: oop) ifTrue:
		[^' is a free chunk of size ', (objectMemory sizeOfFree: oop) printString,
			(objectMemory hasSpurMemoryManagerAPI
				ifTrue: [' 0th: ', (objectMemory fetchPointer: 0 ofFreeChunk: oop) hex]
				ifFalse: [''])].
	(objectMemory isForwarded: oop) ifTrue:
		[^' is a forwarded object to ', (objectMemory followForwarded: oop) hex,
			' of slot size ', (objectMemory numSlotsOfAny: oop) printString].
	(objectMemory isFloatInstance: oop) ifTrue:
		[^'=', (objectMemory dbgFloatValueOf: oop) printString].
	oop = objectMemory nilObject ifTrue:
		[^'nil'].
	oop = objectMemory falseObject ifTrue:
		[^'false'].
	oop = objectMemory trueObject ifTrue:
		[^'true'].

	classOop := objectMemory fetchClassOfNonImm: oop.
	((self objCouldBeClassObj: oop)
	 and: [(objectMemory numSlotsOf: classOop) = metaclassNumSlots]) ifTrue:
		[^'class ', (self nameOfClass: oop)].
	name := self nameOfClass: classOop.
	name size = 0 ifTrue: [name := '??'].
	(#('String'  'ByteString') includes: name) ifTrue:
		[^(self stringOf: oop) printString].
	(#('Symbol'  'ByteSymbol') includes: name) ifTrue:
		[^'#', (self stringOf: oop)].
	name = 'Character' ifTrue: "SpurMemoryManager has immediate Characters (see above); ObjectMemory does not"
		[^'=', (Character value: (objectMemory integerValueOf: 
				(objectMemory fetchPointer: 0 ofObject: oop))) printString].

	"Try to spot association-like things; they're all subclasses of LookupKey"
	((objectMemory isPointersNonImm: oop)
	 and: [classOop ~= objectMemory nilObject
	 and: [((objectMemory instanceSizeOf: classOop) between: ValueIndex + 1 and: ValueIndex + 2)
	 and: [(objectMemory addressCouldBeObj: (key := objectMemory fetchPointer: KeyIndex ofObject: oop))
	 and: [(key = objectMemory nilObject and: [self addressCouldBeClassObj: (objectMemory fetchPointer: ValueIndex ofObject: oop)])
		or: [objectMemory isBytesNonImm: key]]]]]) ifTrue:
		[| classLookupKey |
		 classLookupKey := objectMemory fetchClassOfNonImm: (objectMemory splObj: SchedulerAssociation).
		 [classLookupKey = objectMemory nilObject ifTrue:
			[^(('AEIOU' includes: name first) ifTrue: ['an '] ifFalse: ['a ']), name].
		  (objectMemory instanceSizeOf: classLookupKey) = (KeyIndex + 1)] whileFalse:
			[classLookupKey := self superclassOf: classLookupKey].
		[(objectMemory instanceSizeOf: (self superclassOf: classLookupKey)) = (KeyIndex + 1)] whileTrue:
			[classLookupKey := self superclassOf: classLookupKey].
		 (self includesBehavior: classOop ThatOf: classLookupKey) ifTrue:
			[^(('AEIOU' includes: name first) ifTrue: ['an '] ifFalse: ['a ']), name,
				' ', (self shortPrint: (objectMemory fetchPointer: KeyIndex ofObject: oop)),
				' -> ',
				(objectMemory fetchPointer: ValueIndex ofObject: oop) hex8]].

	^(('AEIOU' includes: name first) ifTrue: ['an '] ifFalse: ['a ']), name
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintContext: aContext [
	| theFP |
	<inline: false>
	<var: #theFP type: #'char *'>
	(objectMemory isContext: aContext) ifFalse:
		[self printHex: aContext; print: ' is not a context'; cr.
		^nil].
	
	printedStackFrames := printedStackFrames + 1.
	(maxStacksToPrint ~= 0 and:[ printedStackFrames > maxStacksToPrint])
		ifTrue: [ 
			maxStackMessagePrinted = 1 ifFalse: [  
				self print: '    ... more contexts ...'; cr.
				maxStackMessagePrinted := 1 ].
			^ nil ].		
	
	self printHex: aContext.
	(self isMarriedOrWidowedContext: aContext)
		ifTrue: [(self checkIsStillMarriedContext: aContext currentFP: framePointer)
					ifTrue:
						[theFP := self frameOfMarriedContext: aContext.
						(self isMachineCodeFrame: theFP)
							ifTrue: [self print: ' M (']
							ifFalse: [self print: ' I ('].
						 self printHex: theFP asUnsignedIntegerPtr; print: ') ']
					ifFalse:
						[self print: ' w ']]
		ifFalse: [self print: ' s '].
	(self findHomeForContext: aContext)
		ifNil: [self print: ' BOGUS CONTEXT (can''t determine home)']
		ifNotNil:
			[:home|
			 self printActivationNameFor: (objectMemory
											fetchPointer: MethodIndex
											ofObject: (home ifNil: [aContext]))
				receiver: (home
							ifNil: [objectMemory nilObject]
							ifNotNil: [objectMemory fetchPointer: ReceiverIndex ofObject: home])
				isBlock: home ~= aContext
				firstTemporary: (objectMemory fetchPointer: 0 + CtxtTempFrameStart ofObject: home)].
	self cr
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintFrame: theFP [
	<inline: false>
	<var: #theFP type: #'char *'>
	| rcvr |
	
	printedStackFrames := printedStackFrames + 1.
	(maxStacksToPrint ~= 0 and:[ printedStackFrames > maxStacksToPrint])
		ifTrue: [ 
			maxStackMessagePrinted = 1 ifFalse: [  
				self print: '    ... more contexts ...'; cr.
				maxStackMessagePrinted := 1 ].
			^ nil ].	
	
	(stackPages couldBeFramePointer: theFP) ifFalse:
		[self print: 'invalid frame pointer'; cr.
		 ^nil].
	rcvr := self frameReceiver: theFP.
	self printHexPtr: theFP.
	self space.
	self printActivationNameFor: (self frameMethod: theFP)
		receiver: rcvr
		isBlock: (self frameIsBlockActivation: theFP)
		firstTemporary: (self temporary: 0 in: theFP).
	self space.
	self shortPrintOop: rcvr "shortPrintOop: adds a cr"
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintFrame: theFP AndNCallers: n [
	<api>
	<inline: false>
	<var: #theFP type: #'char *'>
	self resetStackPrintedCount.
	(n ~= 0 and: [stackPages couldBeFramePointer: theFP]) ifTrue:
		[self shortPrintFrame: theFP.
		 self shortPrintFrame: (self frameCallerFP: theFP) AndNCallers: n - 1]
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintFrameAndCallers: theFP [
	<inline: false>
	<var: #theFP type: #'char *'>
	(stackPages couldBeFramePointer: theFP) ifFalse: [^nil].
	self shortPrintFrame: theFP.
	(self isBaseFrame: theFP) ifFalse:
		[self shortPrintFrameAndCallers: (self frameCallerFP: theFP)]
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintFramesInCurrentPage [
	<inline: false>
	self resetStackPrintedCount.
	self shortPrintFrameAndCallers: localFP
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintFramesInPage: thePage [
	<export: true> "use export: not api, so it won't be written to cointerp.h. cogit.c is unaware of StackPage"
	<inline: false>
	<var: #thePage type: #'StackPage *'>
	self printFrameAndCallers: thePage headFP SP: thePage headSP short: true
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintFramesOnStackPageListInUse [
	<export: true>
	| page |
	<inline: false>
	<var: #page type: #'StackPage *'>
	page := stackPages mostRecentlyUsedPage.
	[(stackPages isFree: page) ifFalse:
		[self print: 'page '; printHexPtrnp: (self cCode: [page] inSmalltalk: [page baseAddress]); cr.
		 self shortPrintFramesInPage: page.
		 self cr].
	 (page := page prevPage) ~= stackPages mostRecentlyUsedPage] whileTrue
]

{ #category : #'debug printing' }
StackInterpreter >> shortPrintOop: oop [
	<inline: false>
	self printHexnp: oop.
	(objectMemory isImmediate: oop) ifTrue:
		[(objectMemory isIntegerObject: oop) ifTrue:
			[self
				cCode: 'vm_printf("=%ld\n", (long)integerValueOf(oop))'
				inSmalltalk: [self print: (self shortPrint: oop); cr]].
		 (objectMemory isImmediateCharacter: oop) ifTrue:
			[self
				cCode: 'vm_printf("=$%ld ($%lc)\n", (long)characterValueOf(oop), (wint_t)characterValueOf(oop))'
				inSmalltalk: [self print: (self shortPrint: oop); cr]].
		 (objectMemory isImmediateFloat: oop) ifTrue:
			[self
				cCode: 'vm_printf("=%g\n", floatValueOf(oop))'
				inSmalltalk: [self print: '='; printFloat: (objectMemory floatValueOf: oop); cr]].
		 ^self].
	(objectMemory addressCouldBeObj: oop) ifFalse:
		[^self print: ((oop bitAnd: objectMemory allocationUnit - 1) ~= 0
						ifTrue: [' is misaligned']
						ifFalse: [self whereIs: oop]); cr].
	((objectMemory isFreeObject: oop)
	 or: [objectMemory isForwarded: oop]) ifTrue:
		[^self printOop: oop].
	self print: ': a(n) '.
	self printNameOfClass: (objectMemory fetchClassOfNonImm: oop) count: 5.
	self cr
]

{ #category : #'debug printing' }
StackInterpreter >> shortReversePrintFrameAndCallers: aFramePointer [
	| theFP callerFP caller |
	<inline: false>
	<var: #aFramePointer type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	aFramePointer = 0 ifTrue:
		[^objectMemory nilObject].
	theFP := aFramePointer.
	[self shortPrintFrame: theFP.
	 callerFP := self frameCallerFP: theFP.
	 callerFP ~= 0] whileTrue:
		[theFP := callerFP].
	caller := self frameCallerContext: theFP.
	(objectMemory isForwarded: caller) ifTrue:
		[caller := objectMemory followForwarded: caller].
	^caller
]

{ #category : #'jump bytecodes' }
StackInterpreter >> shortUnconditionalJump [
	<expandCases>
	self jump: (currentBytecode bitAnd: 7) + 1.
]

{ #category : #'I/O primitive support' }
StackInterpreter >> show: surfaceHandle Sur: left fa: top ce: width Fn: height [
	"Simulate the showSurfaceFn function call as a failure to load the surface."
	<doNotGenerate>
	^0
]

{ #category : #'I/O primitive support' }
StackInterpreter >> showDisplayBits: aForm Left: l Top: t Right: r Bottom: b [
	"Repaint the portion of the Smalltalk screen bounded by the affected rectangle. Used to synchronize the screen after a Bitblt to the Smalltalk Display object."
	(deferDisplayUpdates
	 or: [aForm ~= (objectMemory splObj: TheDisplay)]) ifTrue: [^nil].
	self updateDisplayLeft: l Top: t Right: r Bottom: b
]

{ #category : #'send bytecodes' }
StackInterpreter >> shuffleArgumentsAndStoreAbsentReceiver: theReceiver [
	"For the absent receiver sends move the arguments up the stack and store the supplied receiver."
	<inline: true>
	localSP := localSP - objectMemory bytesPerOop. "a.k.a. self internalPush: anything"
	1 to: argumentCount do:
		[:i| | oop |
		oop := self internalStackValue: i.
		self internalStackValue: i - 1 put: oop].
	self internalStackValue: argumentCount put: theReceiver
]

{ #category : #'primitive support' }
StackInterpreter >> siglong: aJumpBuf jmp: returnValue [
	^self long: aJumpBuf jmp: returnValue
]

{ #category : #utilities }
StackInterpreter >> signExtend16: int16 [
	"Convert a signed 16-bit integer into a signed 32-bit integer value. The integer bit is not added here."

	(int16 bitAnd: 16r8000) = 0
		ifTrue: [ ^ int16 ]
		ifFalse: [ ^ int16 - 16r10000 ].
]

{ #category : #'process primitive support' }
StackInterpreter >> signalExternalSemaphores [
	"Signal all requested semaphores.  Answer if a context switch has occurred."
	| xArray |
	xArray := objectMemory splObj: ExternalObjectsArray.
	^self doSignalExternalSemaphores: (objectMemory numSlotsOf: xArray)
]

{ #category : #'process primitive support' }
StackInterpreter >> signalFinalization: weakReferenceOop [
	"Record the fact that there is at least one object to finalize
	 and cause the VM to check for interrupts at the earliest
	 opportunity. The finalization semaphore will actually be
	 signalled once in checkForEventsMayContextSwitch:"

	self forceInterruptCheck.
	pendingFinalizationSignals := pendingFinalizationSignals + 1
]

{ #category : #'primitive support' }
StackInterpreter >> signed32BitIntegerFor: integerValue [
	"Answer a full 32 bit integer object for the given integer value.
	 N.B.  Returning in each arm separately enables Slang inlining.
	 /Don't/ return the ifTrue:ifFalse: unless Slang inlining of conditionals is fixed."
	<inline: true>
	objectMemory hasSixtyFourBitImmediates
		ifTrue:
			[^objectMemory integerObjectOf: 
				(self cCode: [self cCoerceSimple: integerValue to: #int]
					inSmalltalk: [(integerValue bitAnd: 16r7FFFFFFF)
								- ((integerValue >> 31 anyMask: 1)
									ifTrue: [-16r100000000]
									ifFalse: [0])])]
		ifFalse:
			[(objectMemory isIntegerValue: integerValue) ifTrue:
				[^objectMemory integerObjectOf: integerValue].
			 ^self noInlineSigned32BitIntegerGutsFor: integerValue]
]

{ #category : #'primitive support' }
StackInterpreter >> signed64BitIntegerFor: integerValue [
	<var: 'integerValue' type: #sqLong>
	"Answer a Large Integer object for the given integer value.  N.B. will *not* cause a GC."
	| newLargeInteger magnitude largeClass highWord sz |
	<inline: false>
	<var: 'magnitude' type: #usqLong>
	<var: 'highWord' type: #usqInt>

	integerValue < 0
		ifTrue:[	integerValue >= objectMemory minSmallInteger ifTrue: [^objectMemory integerObjectOf: integerValue asInteger].
				largeClass := ClassLargeNegativeIntegerCompactIndex.
				magnitude := 0 - (self cCoerceSimple: integerValue to: #usqLong)]
		ifFalse:[	integerValue <= objectMemory maxSmallInteger ifTrue: [^objectMemory integerObjectOf: integerValue asInteger].
				largeClass := ClassLargePositiveIntegerCompactIndex.
				magnitude := integerValue].

	objectMemory wordSize = 8
		ifTrue: [sz := 8]
		ifFalse: [
		 (highWord := magnitude >> 32) = 0 
			ifTrue: [sz := 4] 
			ifFalse:
				[sz := 5.
				 (highWord := highWord >> 8) = 0 ifFalse:
					[sz := sz + 1.
					 (highWord := highWord >> 8) = 0 ifFalse:
						[sz := sz + 1.
						 (highWord := highWord >> 8) = 0 ifFalse:
							[sz := sz + 1]]]]].

	newLargeInteger := objectMemory
							eeInstantiateSmallClassIndex: largeClass
							format: (objectMemory byteFormatForNumBytes: sz)
							numSlots: sz + 3 // objectMemory bytesPerOop.
	SPURVM
		ifTrue:
			["Memory is eight byte aligned in SPUR, so we are sure to have room for 64bits word whatever allocated sz"
			objectMemory storeLong64: 0 ofObject: newLargeInteger withValue: (objectMemory byteSwapped64IfBigEndian: magnitude)]
		ifFalse:
			[sz > 4
				ifTrue: [objectMemory storeLong64: 0 ofObject: newLargeInteger withValue: (objectMemory byteSwapped64IfBigEndian: magnitude)]
				ifFalse: [objectMemory storeLong32: 0 ofObject: newLargeInteger withValue: (objectMemory byteSwapped32IfBigEndian: magnitude)]].
	^newLargeInteger
]

{ #category : #'runtime support' }
StackInterpreter >> sigset: aJumpBuf jmp: sigSaveMask [
	"Hack simulation of sigsetjmp/siglongjmp.
	 Assign to reenterInterpreter the exception that when
	 raised simulates a longjmp back to the interpreter." 
	<doNotGenerate>
	reenterInterpreter := ReenterInterpreter new returnValue: 0; yourself.
	^0
]

{ #category : #'send bytecodes' }
StackInterpreter >> singleExtendedSendBytecode [
	"Can use any of the first 32 literals for the selector and pass up to 7 arguments."

	| descriptor |
	descriptor := self fetchByte.
	messageSelector := self literal: (descriptor bitAnd: 16r1F).
	argumentCount := descriptor >> 5.
	self normalSend.
]

{ #category : #'send bytecodes' }
StackInterpreter >> singleExtendedSuperBytecode [
	"Can use any of the first 32 literals for the selector and pass up to 7 arguments."

	| descriptor |
	descriptor := self fetchByte.
	messageSelector := self literal: (descriptor bitAnd: 16r1F).
	argumentCount := descriptor >> 5.
	self superclassSend.

]

{ #category : #'sista bytecodes' }
StackInterpreter >> sistaInlinePrimitive: prim [
	"SistaV1:	248		11111000 	iiiiiiii		mjjjjjjj		Call Primitive #iiiiiiii + (jjjjjjj * 256) m=1 means inlined primitive, no hard return after execution. This is the dispatch for unmapped sista inlined primitives."
	<option: #SistaVM>
	
	 prim < 1000 ifTrue:
		[^self nullaryInlinePrimitive: prim].

	 prim < 2000 ifTrue:
		[^self unaryInlinePrimitive: prim - 1000].

	 prim < 3000 ifTrue:
		[^self binaryInlinePrimitive: prim - 2000].

	 prim < 4000 ifTrue:
		[^self trinaryInlinePrimitive: prim - 3000].

	 prim < 5000 ifTrue:
		[^self quaternaryInlinePrimitive: prim - 4000].

	 prim < 6000 ifTrue:
		[^self quinaryInlinePrimitive: prim - 5000].
	
	 prim < 7000 ifTrue:
		[^self jumpUnaryInlinePrimitive: prim - 6000].
	
 	prim < 8000 ifTrue:
		[^self jumpBinaryInlinePrimitive: prim - 7000].
	
	^ self jumpTrinaryInlinePrimitive: prim - 8000.
]

{ #category : #'sista bytecodes' }
StackInterpreter >> sistaMappedInlinePrimitive: primIndex [
	"SistaV1:	236		11101100	iiiiiiii		callMappedInlinedPrimitive"
	"Number of arguments:
	 0-49 nullary
	 50-99 unary
	 100-149  binary
	 150-199 trinary
	 200-249 variable
	 250-255 mapped jumps"
	"Specification:
	50	EnsureEnoughWords
	literal which is a Smi => ret value is receiver
	150	immCheckPointerAt:put:
	pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	151	immCheckStoreCheckPointerAt:put:
	pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	152	immCheckMaybeContextPointerAt:put:
	pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	153	immCheckMaybeContextStoreCheckPointerAt:put:
	pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	154	immcheckByteAt:put:
	byte object, Smi, 8 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)
	155	immCheckShortAt:put:
	short object, Smi, 16 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)
	156	immCheckWordAt:put:
	word object, Smi, 32 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)
	157	immCheckDoubleWordAt:put:
	double word object, Smi, 64 bits unsigned Smi or LargePositiveInteger => arg2 (1-based, optimised if arg1 is a constant)
	200	directCall
	method to call on top of stack =>  (variable number of parameters)
	250 	backjumpAlwaysInterrupt
	literal which is a Smi"
	<option: #SistaVM>
	(primIndex between: 154 and: 157) ifTrue: [^self mappedImmcheckDataAtPut: primIndex].
	primIndex caseOf: {
		[50]	->	[self mappedEnsureEnoughWords].
		[150]	->	["150	immCheckPointerAt:put:
		 			 pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)"
					"We could ignore the store check but we don't care in the interpreter"
					self mappedImmcheckStoreCheckPointerAtPut].
		[151]	->	[self mappedImmcheckStoreCheckPointerAtPut].
		[152]	->	["152	immCheckMaybeContextPointerAt:put:
					 pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)"
					 "We could ignore the store check but we don't care in the interpreter"
					 self mappedImmcheckMaybeContextStoreCheckPointerAtPut].
		[153]	->	[self mappedImmcheckMaybeContextStoreCheckPointerAtPut].
		[200] 	->	[self mappedDirectCall].
		[250] 	->	[self mappedBackjumpAlwaysInterrupt].
	} otherwise: [self unknownInlinePrimitive]
	

]

{ #category : #'compiled methods' }
StackInterpreter >> sizeOfCallPrimitiveBytecode: methodHeader [
	"Answer the size of the CallPrimitive bytecode that may be used to store a method's primitive."
	"NewsqueakV4:	249	11111001	iiiiiiii	jjjjjjjj	Call Primitive #iiiiiiii + (jjjjjjjj * 256)"
	"SistaV1:		248	11111000 	iiiiiiii	mssjjjjj	Call Primitive #iiiiiiii + (  jjjjj * 256)"
	"V3+Closures:	139	11101111	iiiiiiii	jjjjjjjj	Call Primitive #iiiiiiii + (jjjjjjjj * 256)"
	<api>
	<inline: true>
	^objectMemory hasSpurMemoryManagerAPI
		ifTrue: [3]
		ifFalse:
			[MULTIPLEBYTECODESETS
				ifTrue: [(objectMemory headerIndicatesAlternateBytecodeSet: methodHeader)
							ifTrue: [3]
							ifFalse: [0]]
				ifFalse: [0]]
]

{ #category : #'compiled methods' }
StackInterpreter >> sizeOfLongStoreTempBytecode: methodHeader [
	"234		11101010	i i i i i i i i	Store Temporary Variable #iiiiiiii"
	"129 		10000001 jjkkkkkk 	Store (Receiver Variable, Temporary Location, Illegal, Literal Variable) [jj] #kkkkkk"
	<api>
	^2
]

{ #category : #utilities }
StackInterpreter >> sizeOfSTArrayFromCPrimitive: cPtr [
	"Return the number of indexable fields of the given object. This method is to be called from an automatically generated C primitive. The argument is assumed to be a pointer to the first indexable field of a words or bytes object; the object header starts 4 bytes before that."
	"Note: Only called by translated primitive code."

	| oop |
	<var: #cPtr type: 'void *'>
	oop := (self oopForPointer: cPtr) - objectMemory baseHeaderSize.
	(objectMemory isWordsOrBytes: oop) ifFalse: [
		self primitiveFail.
		^0].
	^objectMemory lengthOf: oop

]

{ #category : #'primitive support' }
StackInterpreter >> slowPrimitiveResponse [
	"Invoke a normal (non-quick) primitive.
	 Called under the assumption that primFunctionPointer has been preloaded."
	| nArgs savedFramePointer savedStackPointer |
	<inline: true>
	<var: #savedFramePointer type: #'char *'>
	<var: #savedStackPointer type: #'char *'>
	self assert: (objectMemory isOopForwarded: (self stackValue: argumentCount)) not.
	self assert: objectMemory remapBufferCount = 0.
	FailImbalancedPrimitives ifTrue:
		[nArgs := argumentCount.
		 savedStackPointer := stackPointer.
		 savedFramePointer := framePointer].
	self initPrimCall.
	self dispatchFunctionPointer: primitiveFunctionPointer.
	self assert: (self maybeLeakCheckExternalPrimCall: newMethod).
	self maybeRetryPrimitiveOnFailure.
	self maybeFailForLastObjectOverwrite.
	(FailImbalancedPrimitives
	and: [self successful
	and: [framePointer = savedFramePointer
	and: [(self isMachineCodeFrame: framePointer) not]]]) ifTrue:"Don't fail if primitive has done something radical, e.g. perform:"
		[stackPointer ~= (savedStackPointer + (nArgs * objectMemory wordSize)) ifTrue:
			[self flag: 'Would be nice to make this a message send of e.g. unbalancedPrimitive to the current process or context'.
			 "This is necessary but insufficient; the result may still have been written to the stack.
			   At least we'll know something is wrong."
			 self failUnbalancedPrimitive.
			 stackPointer := savedStackPointer]].
	"If we are profiling, take accurate primitive measures"
	nextProfileTick > 0 ifTrue:
		[self checkProfileTick: newMethod].
	^self successful
]

{ #category : #'image save/restore' }
StackInterpreter >> snapshot: embedded [ 
	"update state of active context"
	| activeContext activeProc rcvr setMacType stackIndex |
	<var: #setMacType type: #'void *'>

	"For now the stack munging below doesn't deal with more than one argument.
	 It can, and should."
	argumentCount ~= 0 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].

	"Need to convert all frames into contexts since the snapshot file only holds objects."
	self push: instructionPointer.
	activeContext := self voidVMStateForSnapshotFlushingExternalPrimitivesIf: true.

	"update state of active process"
	activeProc := self activeProcess.
	objectMemory
		storePointer: SuspendedContextIndex
		ofObject: activeProc
		withValue: activeContext.

	tempOop := activeContext.
	objectMemory garbageCollectForSnapshot.
	"Nothing moves from here on so it is safe to grab the activeContext again."
	activeContext := tempOop.
	tempOop := 0.

	self successful ifTrue:
		["Without contexts or stacks simulate
			rcvr := self popStack. ''pop rcvr''
			self push: trueObj.
		  to arrange that the snapshot resumes with true.  N.B. stackIndex is one-relative."
		stackIndex := self quickFetchInteger: StackPointerIndex ofObject: activeContext.
		rcvr := objectMemory fetchPointer: stackIndex + CtxtTempFrameStart - 1 ofObject: activeContext.
		objectMemory
			storePointerUnchecked: stackIndex + CtxtTempFrameStart - 1
			ofObject: activeContext
			withValue: objectMemory trueObject.
		"now attempt to write the snapshot file"
		self writeImageFileIO.
		(self successful and: [embedded not]) ifTrue:
			["set Mac file type and creator; this is a noop on other platforms"
			setMacType := self ioLoadFunction: 'setMacFileTypeAndCreator' From: 'FilePlugin'.
			setMacType = 0 ifFalse:
				[self cCode: '((sqInt (*)(char *, char *, char *))setMacType)(imageName, "STim", "FAST")']].
		"Without contexts or stacks simulate
			self pop: 1"
		objectMemory
			storePointerUnchecked: StackPointerIndex
			ofObject: activeContext
			withValue: (objectMemory integerObjectOf: stackIndex - 1)].

	objectMemory postSnapshot.
	self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext.
	self successful
		ifTrue: [self push: objectMemory falseObject]
		ifFalse:
			[self push: rcvr.
			 self justActivateNewMethod: true] "no point checking for machine code; there isn't any at this point"
]

{ #category : #'debug printing' }
StackInterpreter >> space [
	<inline: true>
	self printChar: $ 
]

{ #category : #'message sending' }
StackInterpreter >> specialSelector: index [
	<api>
	^objectMemory fetchPointer: (index * 2) ofObject: (objectMemory splObj: SpecialSelectors)
]

{ #category : #'message sending' }
StackInterpreter >> specialSelector: index put: aValue [
	<doNotGenerate>
	^objectMemory
		storePointer: (index * 2)
		ofObject: (objectMemory splObj: SpecialSelectors)
		withValue: aValue
]

{ #category : #'message sending' }
StackInterpreter >> specialSelectorArray: anOop [
	<doNotGenerate>
	objectMemory splObj: SpecialSelectors put: anOop
]

{ #category : #'message sending' }
StackInterpreter >> specialSelectorNumArgs: index [
	^objectMemory integerValueOf: (objectMemory fetchPointer: (index * 2) + 1 ofObject: (objectMemory splObj: SpecialSelectors))
]

{ #category : #'object memory support' }
StackInterpreter >> spurPostBecomeAction: theBecomeEffectsFlags [
	"Insulate the stack zone from the effects of a become.
	 All receivers must be unfollowed for two reasons:
		1. inst var access is direct with no read barrier
		2. super sends (always to the receiver) have no class check and so don't trap
		   for forwarded receivers.  This is an issue for primitives that assume their receiver
		   is valid and don't validate.
	 Super sends require an explicit check to ensure receivers in super sends are unforwarded.
	 e.g. super doSomethingWith: (self become: other) forwards the receiver self pushed on the
	 stack.  So we could avoid following non-pointer receivers.  But this is too tricky,  Instead, we
	 always follow receivers.
	 Methods must be unfollowed since bytecode access is direct with no read barrier.
	 But this only needs to be done if the becomeEffectsFlags indicate that a
	 CompiledMethod was becommed.
	 The scheduler state must be followed, but only if the becomeEffectsFlags indicate
	 that a pointer object was becommed."
	<option: #SpurObjectMemory>
	<inline: false> "For VM profiling"
	self flushAtCache.
	theBecomeEffectsFlags ~= 0 ifTrue:
		[(theBecomeEffectsFlags anyMask: BecameCompiledMethodFlag) ifTrue:
			[self followForwardedMethodsInMethodCache.
			 self followForwardedMethodsInMethodZone]. "for CoInterpreter; must precede followForwardingPointersInStackZone:"
		 (theBecomeEffectsFlags anyMask: BecameActiveClassFlag) ifTrue:
			[self flushBecommedClassesInMethodCache.
			 self flushBecommedClassesInMethodZone]. "for CoInterpreter"
		 (theBecomeEffectsFlags anyMask: BecamePointerObjectFlag) ifTrue:
			[self followForwardingPointersInScheduler.
			 self followForwardingPointersInSpecialObjectsArray].
		 (theBecomeEffectsFlags anyMask: BecamePointerObjectFlag + BecameCompiledMethodFlag) ifTrue:
			[self followForwardingPointersInProfileState]].
	self followForwardingPointersInStackZone: theBecomeEffectsFlags
]

{ #category : #'indexing primitive support' }
StackInterpreter >> stObject: array at: index [
	"Return what ST would return for <obj> at: index."

	| hdr fmt totalLength fixedFields stSize |
	<inline: true>
	hdr := objectMemory baseHeader: array.
	fmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: array baseHeader: hdr format: fmt.
	fixedFields := objectMemory fixedFieldsOf: array format: fmt length: totalLength.
	(fmt = objectMemory indexablePointersFormat
	 and: [objectMemory isContextHeader: hdr])
		ifTrue:
			[stSize := self stackPointerForMaybeMarriedContext: array.
			((self oop: index isGreaterThanOrEqualTo: 1)
			 and: [(self oop: index isLessThanOrEqualTo: stSize)
			 and: [self isStillMarriedContext: array]]) ifTrue:
				[^self noInlineTemporary: index - 1 in: (self frameOfMarriedContext: array)]]
		ifFalse: [stSize := totalLength - fixedFields].
	((self oop: index isGreaterThanOrEqualTo: (objectMemory firstValidIndexOfIndexableObject: array withFormat: fmt))
	 and: [self oop: index isLessThanOrEqualTo: stSize]) ifTrue:
		[^self subscript: array with: (index + fixedFields) format: fmt].
	self primitiveFailFor: (fmt <= 1 ifTrue: [PrimErrBadReceiver] ifFalse: [PrimErrBadIndex]).
	^0
]

{ #category : #'indexing primitive support' }
StackInterpreter >> stObject: array at: index put: value [
	"Do what ST would return for <obj> at: index put: value."
	| hdr fmt totalLength fixedFields stSize |
	<inline: true>
	hdr := objectMemory baseHeader: array.
	fmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: array baseHeader: hdr format: fmt.
	fixedFields := objectMemory fixedFieldsOf: array format: fmt length: totalLength.
	(fmt = objectMemory indexablePointersFormat
	 and: [objectMemory isContextHeader: hdr])
		ifTrue:
			[stSize := self stackPointerForMaybeMarriedContext: array.
			((self oop: index isGreaterThanOrEqualTo: 1)
			 and: [(self oop: index isLessThanOrEqualTo: stSize)
			 and: [self isStillMarriedContext: array]]) ifTrue:
				[^self noInlineTemporary: index - 1 in: (self frameOfMarriedContext: array) put: value]]
		ifFalse: [stSize := totalLength - fixedFields].
	((self oop: index isGreaterThanOrEqualTo: (objectMemory firstValidIndexOfIndexableObject: array withFormat: fmt))
	 and: [self oop: index isLessThanOrEqualTo: stSize])
		ifTrue: [self subscript: array with: (index + fixedFields) storing: value format: fmt]
		ifFalse: [self primitiveFailFor: (fmt <= 1 ifTrue: [PrimErrBadReceiver] ifFalse: [PrimErrBadIndex])].
	^value
]

{ #category : #'indexing primitive support' }
StackInterpreter >> stSizeOf: oop [
	"Return the number of indexable fields in the given object. (i.e., what Smalltalk would return for <obj> size)."
	"Note: Assume oop is not a SmallInteger!"

	| hdr fmt totalLength fixedFields |
	<inline: false>
	hdr := objectMemory baseHeader: oop.
	fmt := objectMemory formatOfHeader: hdr.
	totalLength := objectMemory lengthOf: oop baseHeader: hdr format: fmt.
	fixedFields := objectMemory fixedFieldsOf: oop format: fmt length: totalLength.
	fmt = objectMemory indexablePointersFormat ifTrue:
		[self assert: (objectMemory isContextHeader: hdr) not].
	^totalLength - fixedFields
]

{ #category : #'stack access' }
StackInterpreter >> stackFloatValue: offset [
	"In the StackInterpreter stacks grow down."
	<returnTypeC: #double>
	^objectMemory floatValueOf: (stackPages longAt: stackPointer + (offset*objectMemory wordSize))
]

{ #category : #'stack access' }
StackInterpreter >> stackIntegerValue: offset [
	"In the StackInterpreter stacks grow down."
	| integerPointer |
	integerPointer := stackPages longAt: stackPointer + (offset*objectMemory wordSize).
	^self checkedIntegerValueOf: integerPointer
]

{ #category : #'stack pages' }
StackInterpreter >> stackLimitBytes [
	"Answer the actual stackLimit offset in a page.  Since stackPageByteSize may have chosen to shrink a page
	 this may be less than stackPageFrameBytes, but it should be no more than stackPageFrameBytes."
	^self stackPageFrameBytes min: self stackPageByteSize - self stackLimitOffset - self stackPageHeadroom.
]

{ #category : #'stack pages' }
StackInterpreter >> stackLimitOffset [
	"Answer the amount of slots needed to fit a new frame at the point the stack
	 limit is checked.  A frame looks like this at the point the stack limit is checked:
			stacked receiver/closure
			arg0
			...
			argN
			caller's method ip/base frame's sender context
	fp->	saved fp
			method
			method header fields
			context (uninitialized)
			receiver
			first temp
			...
	sp->	Nth temp
	So the amount of headroom is
		the maximum number of arguments + 1 (for stacked receiver and arguments)
		+ the frame size
		+ the max number of temps.
	 Since a method's number of temps includes its arguments the actual offset is:"
	^(FrameSlots + 64) * objectMemory wordSize
]

{ #category : #'stack access' }
StackInterpreter >> stackObjectValue: offset [
	"Ensures that the given object is a real object, not a SmallInteger."
	"In the StackInterpreter stacks grow down."
	| oop |
	oop := stackPages longAt: stackPointer + (offset * objectMemory wordSize).
	(objectMemory isImmediate: oop) ifTrue:
		[self primitiveFail. ^ nil].
	^oop
]

{ #category : #'as yet unclassified' }
StackInterpreter >> stackPage: aCogStackPage [ 
	stackPage := aCogStackPage
]

{ #category : #'stack pages' }
StackInterpreter >> stackPageByteSize [
	"Answer a page size that is a power-of-two and contains a useful number of frames.
	 Room for 256 slots for frames gives around 40 frames a page which is a
	 good compromise between overflow rate and latency in divorcing a page."
	<inline: false>
	| pageBytes largeSize smallSize |
	pageBytes := self stackPageFrameBytes + self stackLimitOffset + self stackPageHeadroom.
	(pageBytes bitAnd: pageBytes - 1) = 0 ifTrue: "= 0 => a power of two"
		[^pageBytes].
	"round up or round down; that is the question.  If rounding down reduces
	 the size by no more than 1/8th round down, otherwise roundup."
	largeSize := 1 << pageBytes highBit.
	smallSize := 1 << (pageBytes highBit - 1).
	self assert: (largeSize > pageBytes and: [pageBytes > smallSize]).
	^(pageBytes - smallSize) <= (smallSize / 8)
		ifTrue: [smallSize]
		ifFalse: [largeSize]
]

{ #category : #'stack pages' }
StackInterpreter >> stackPageFrameBytes [
	"Answer a byte size that accomodates a useful number of frames.  The minimum frame size is
	 7 slots in the StackInterpreter, and 6 slots in the CoInterpreter, and the maximum size is 56 + 7
	 slots in the StackInterpreter and 56 + 8 slots in the CoInterpreter. 256 slots gives from 4 to 36
	 frames in the StackInterpreter and from 4 to 42 in the CoInterpreter. Hence 2048 bytes in 32-bits
	 and 4096 bytes in 64-bits; a compromise between overflow rate and latency in divorcing a page."
	"Defining as a macro simplifies hand editing the C for experiments..."
	<cmacro: '() (256 * BytesPerWord)'>
	^256 * objectMemory wordSize
]

{ #category : #'stack pages' }
StackInterpreter >> stackPageHeadroom [
	"Return a minimum amount of headroom for each stack page (in bytes).
	 In a JIT the stack has to have room for interrupt handlers which will run on the
	 stack.  In the interpreter we don't actually need any headroom."
	^0
]

{ #category : #accessing }
StackInterpreter >> stackPages: anInterpreterStackPages [
	<doNotGenerate>
	1halt.
	stackPages := anInterpreterStackPages
]

{ #category : #initialization }
StackInterpreter >> stackPagesClass [
	<doNotGenerate>
	^VMBIGENDIAN
		ifTrue: [InterpreterStackPagesMSB]
		ifFalse: [InterpreterStackPagesLSB]
]

{ #category : #accessing }
StackInterpreter >> stackPointer [
	<doNotGenerate>
	^stackPointer
]

{ #category : #'cog jit support' }
StackInterpreter >> stackPointer: theSP [
	"Simulation only"
	<doNotGenerate>
	stackPointer := theSP
]

{ #category : #'internal interpreter access' }
StackInterpreter >> stackPointerForMaybeMarriedContext: aContext [
	"Return the stackPointer of a Context or BlockContext."
	| sp |
	<inline: true>
	(self isStillMarriedContext: aContext) ifTrue:
		[sp := self stackPointerIndexForFrame: (self frameOfMarriedContext: aContext).
		 self assert: ReceiverIndex + (objectMemory integerValueOf: sp) < (objectMemory lengthOf: aContext).
		 ^sp].
	^self fetchStackPointerOf: aContext
]

{ #category : #'internal interpreter access' }
StackInterpreter >> stackPointerIndex [
	"Return the 1-based value of the stack pointer for the current frame.
	 This is what the value of the stackp slot would be in a context object."
	^self stackPointerIndexForFrame: framePointer WithSP: stackPointer
]

{ #category : #'frame access' }
StackInterpreter >> stackPointerIndexForFrame: theFP [
	"Return the 0-based index rel to the given frame.
	 (This is what stackPointer used to be before conversion to pointer)"
	"In the StackInterpreter stacks grow down."
	| thePage theSP |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	thePage := stackPages stackPageFor: theFP.
	theSP := self findSPOf: theFP on: thePage.
	^self stackPointerIndexForFrame: theFP WithSP: theSP
]

{ #category : #'frame access' }
StackInterpreter >> stackPointerIndexForFrame: theFP WithSP: theSP [
	"Return the 1-based index rel to the given frame"
	"In the StackInterpreter stacks grow down."
	^(((theFP + FoxReceiver) - theSP) >> objectMemory shiftForWord) + (self frameNumArgs: theFP)
]

{ #category : #'stack access' }
StackInterpreter >> stackPositiveMachineIntegerValue: offset [
	<api>
	<returnTypeC: #'usqIntptr_t'>
	"In the StackInterpreter stacks grow down."
	| integerPointer |
	integerPointer := stackPages longAt: stackPointer + (offset*objectMemory wordSize).
	^self positiveMachineIntegerValueOf: integerPointer
]

{ #category : #'stack access' }
StackInterpreter >> stackSignedMachineIntegerValue: offset [
	<api>
	<returnTypeC: #'sqIntptr_t'>
	"In the StackInterpreter stacks grow down."
	| integerPointer |
	integerPointer := stackPages longAt: stackPointer + (offset*objectMemory wordSize).
	^self signedMachineIntegerValueOf: integerPointer
]

{ #category : #'stack access' }
StackInterpreter >> stackTop [
	<api>
	^stackPages longAt: stackPointer
]

{ #category : #'stack access' }
StackInterpreter >> stackTopPut: aValue [

	^stackPages longAtPointer: stackPointer put: aValue
]

{ #category : #'stack access' }
StackInterpreter >> stackValue: offset [
	<api>
	"In the StackInterpreter stacks grow down."
	^stackPages longAt: stackPointer + (offset*objectMemory wordSize)
]

{ #category : #'stack access' }
StackInterpreter >> stackValue: offset put: oop [
	"In the StackInterpreter stacks grow down."
	^stackPages
		longAt: stackPointer + (offset*objectMemory wordSize)
		put: oop
]

{ #category : #'compiled methods' }
StackInterpreter >> startPCOfMethod: aCompiledMethod [
	<api>
	"Zero-relative version of CompiledMethod>>startpc."
	^(objectMemory literalCountOf: aCompiledMethod) + LiteralStart * objectMemory bytesPerOop
]

{ #category : #'compiled methods' }
StackInterpreter >> startPCOfMethodHeader: methodHeader [
	"Answer the zero-relative index to the initial byte for a method.
	 Zero-relative version of CompiledMethod>>startpc."
	^(objectMemory literalCountOfMethodHeader: methodHeader) + LiteralStart * objectMemory bytesPerOop
]

{ #category : #'stack bytecodes' }
StackInterpreter >> storeAndPopReceiverVariableBytecode [
	| rcvr top instVarIndex |
	rcvr := self receiver.
	top := self internalStackTop.
	instVarIndex := currentBytecode bitAnd: 7.
	self internalPop: 1.
	objectMemory
		storePointerImmutabilityCheck: instVarIndex
		ofObject: rcvr
		withValue: top.
	self fetchNextBytecode.
]

{ #category : #'stack bytecodes' }
StackInterpreter >> storeAndPopRemoteTempLongBytecode [
	self storeRemoteTempLongBytecode.
	self internalPop: 1
]

{ #category : #'stack bytecodes' }
StackInterpreter >> storeAndPopTemporaryVariableBytecode [
	<expandCases>
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[self fetchNextBytecode.
			 self temporary: (currentBytecode bitAnd: 7) in: localFP put: self internalStackTop.
			 self internalPop: 1]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[self temporary: (currentBytecode bitAnd: 7) in: localFP put: self internalStackTop.
			 self fetchNextBytecode.
			 self internalPop: 1]
]

{ #category : #utilities }
StackInterpreter >> storeInteger: fieldIndex ofObject: objectPointer withValue: integerValue [ 
	"Note: May be called by translated primitive code."
	(objectMemory isIntegerValue: integerValue)
		ifTrue: [objectMemory storePointerUnchecked: fieldIndex ofObject: objectPointer
					withValue: (objectMemory integerObjectOf: integerValue)]
		ifFalse: [self primitiveFail].
	^nil
]

{ #category : #'stack bytecodes' }
StackInterpreter >> storeLiteralVariable: literalIndex withValue: anObject [
	| litVar |
	litVar := self literal: literalIndex.
	"push/store/popLiteralVariable all fetch a literal, and either read or write the literal's value field.
	 The fetch of the literal needs an explicit check (otherwise we would have to scan all literals in
	 all methods in the stack zone, and the entire method on return, and global variables are relatively
	 rare; in my work image 8.7% of literals are globals)."

	(objectMemory isForwarded: litVar) ifTrue:
		[litVar := self unfollow: litVar atIndex: literalIndex].
	objectMemory storePointerImmutabilityCheck: ValueIndex ofObject: litVar withValue: anObject
]

{ #category : #'stack bytecodes' }
StackInterpreter >> storeMaybeContext: obj receiverVariable: fieldIndex withValue: anOop [
	"Must trap accesses to married and widowed contexts.
	 But don't want to check on all inst var accesses.  This
	 method is only used by the long-form bytecodes, evading the cost."
	<inline: true>
	((self isWriteMediatedContextInstVarIndex: fieldIndex)
	and: [(objectMemory isContextNonImm: obj)
	and: [(self isMarriedOrWidowedContext: obj)
		or: [self is: fieldIndex methodAssignmentToContextWithMachineCodePC: anOop]]])
		ifTrue:
			[self instVar: fieldIndex ofContext: obj put: anOop]
		ifFalse:
			[objectMemory storePointerImmutabilityCheck: fieldIndex ofObject: obj withValue: anOop]
]

{ #category : #'stack bytecodes' }
StackInterpreter >> storeMaybeContextReceiverVariable: fieldIndex withValue: anObject [
	"Must trap accesses to married and widowed contexts.
	 But don't want to check on all inst var accesses.  This
	 method is only used by the long-form bytecodes, evading the cost."
	self storeMaybeContext: self receiver receiverVariable: fieldIndex withValue: anObject

]

{ #category : #'stack bytecodes' }
StackInterpreter >> storeRemoteTemp: index inVectorAt: tempVectorIndex [
	| tempVector |
	tempVector := self temporary: tempVectorIndex in: localFP.
	TempVectReadBarrier
		ifTrue: 
			[(objectMemory isForwarded: tempVector) ifTrue:
				[tempVector := self unfollowTempVector: tempVector atIndex: tempVectorIndex in: localFP]].
	objectMemory storePointer: index ofObject: tempVector withValue: self internalStackTop.
]

{ #category : #'stack bytecodes' }
StackInterpreter >> storeRemoteTempLongBytecode [
	| remoteTempIndex tempVectorIndex |
	remoteTempIndex := self fetchByte.
	tempVectorIndex := self fetchByte.
	self fetchNextBytecode.
	self storeRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex
]

{ #category : #'frame access' }
StackInterpreter >> storeSenderOfFrame: theFP withValue: anOop [
	"Set the sender of a frame.  If the frame is a base frame then this is trivial;
	 merely store into the FoxCallerSavedIP/FoxCallerContext field.  If not, then
	 split the stack at the frame, moving the frame and those hotter than it to a
	 new stack page.  In the new stack page the frame will be the base frame
	 and storing trivial.  Answer the possibly changed location of theFP."
	| thePage onCurrentPage newPage theMovedFP |
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #newPage type: #'StackPage *'>
	<var: #theMovedFP type: #'char *'>
	<returnTypeC: #'char *'>
	(self isBaseFrame: theFP) ifTrue:
		[self frameCallerContext: theFP put: anOop.
		 ^theFP].
	self ensureCallerContext: theFP.
	thePage := stackPages stackPageFor: theFP.
	self assert: stackPage = stackPages mostRecentlyUsedPage.
	onCurrentPage := thePage = stackPage.
	onCurrentPage ifFalse:
		["Make sure the frame's page isn't divorced when a new page is allocated."
		 stackPages markStackPageNextMostRecentlyUsed: thePage].
	newPage := stackPages newStackPage.
	theMovedFP := self moveFramesIn: thePage through: theFP toPage: newPage.
	onCurrentPage
		ifTrue: [self setStackPageAndLimit: newPage]
		ifFalse: [stackPages markStackPageMostRecentlyUsed: newPage].
	self assert: (self isBaseFrame: theMovedFP).
	self frameCallerContext: theMovedFP put: anOop.
	^theMovedFP
]

{ #category : #'internal interpreter access' }
StackInterpreter >> storeStackPointerValue: value inContext: aContext [
	"Assume: value is an integerValue"
	self assert: ReceiverIndex + value < (objectMemory lengthOf: aContext).
	objectMemory storePointerUnchecked: StackPointerIndex
		ofObject: aContext
		withValue: (objectMemory integerObjectOf: value)
]

{ #category : #'debug support' }
StackInterpreter >> stringOf: oop [
	<doNotGenerate>
	| size long nLongs chars |
	^ String streamContents:
		[:strm |
		size := 128 min: (self stSizeOf: oop).
		nLongs := size-1//objectMemory wordSize+1.
		1 to: nLongs do:
			[:i | long := objectMemory longAt: oop + objectMemory baseHeaderSize + (i-1*objectMemory wordSize).
			chars := self charsOfLong: long.
			strm nextPutAll: (i=nLongs
							ifTrue: [chars copyFrom: 1 to: size-1\\objectMemory wordSize+1]
							ifFalse: [chars])]]
]

{ #category : #'indexing primitive support' }
StackInterpreter >> subscript: array with: index format: fmt [
	"Note: This method assumes that the index is within bounds!"

	<inline: true>
	fmt <= objectMemory lastPointerFormat ifTrue:
		[^objectMemory fetchPointer: index - 1 ofObject: array].
	fmt >= objectMemory firstByteFormat ifTrue:
		[^objectMemory integerObjectOf:
			(objectMemory fetchByte: index - 1 ofObject: array)].
	objectMemory hasSpurMemoryManagerAPI ifTrue:
		[fmt >= objectMemory firstShortFormat ifTrue:
			[^objectMemory integerObjectOf:
				(objectMemory fetchUnsignedShort16: index - 1 ofObject: array)].
		 fmt = objectMemory sixtyFourBitIndexableFormat ifTrue:
			[^self positive64BitIntegerFor:
				(objectMemory fetchLong64: index - 1 ofObject: array)]].
	"32bit-word type objects; for now assume no 64-bit indexable objects"
	^self positive32BitIntegerFor:
			(objectMemory fetchLong32: index - 1 ofObject: array)
]

{ #category : #'indexing primitive support' }
StackInterpreter >> subscript: array with: index storing: oopToStore format: fmt [ 
	"Note: This method assumes that the index is within bounds!"
	| signedValueToStore unsignedValueToStore |
	<inline: true>
	fmt <= objectMemory lastPointerFormat ifTrue:
		[objectMemory storePointer: index - 1 ofObject: array withValue: oopToStore.
		 ^self].
	fmt >= objectMemory firstByteFormat ifTrue:
		[(objectMemory isIntegerObject: oopToStore) ifFalse:
			[primFailCode := PrimErrBadArgument.
			 ^self].
		 signedValueToStore := objectMemory integerValueOf: oopToStore.
		 (signedValueToStore >= 0 and: [signedValueToStore <= 255]) ifFalse:
			[primFailCode := PrimErrBadArgument.
			 ^self].
		 objectMemory storeByte: index - 1 ofObject: array withValue: signedValueToStore.
		 ^self].
	objectMemory hasSpurMemoryManagerAPI ifTrue:
		[fmt >= objectMemory firstShortFormat ifTrue:
			[(objectMemory isIntegerObject: oopToStore) ifFalse:
				[primFailCode := PrimErrBadArgument.
				 ^self].
			 signedValueToStore := objectMemory integerValueOf: oopToStore.
			 (signedValueToStore >= 0 and: [signedValueToStore <= 65535]) ifFalse:
				[primFailCode := PrimErrBadArgument.
				 ^self].
			 objectMemory storeShort16: index - 1 ofObject: array withValue: signedValueToStore.
			 ^self].
		 fmt = objectMemory sixtyFourBitIndexableFormat ifTrue:
			[| unsigned64BitValueToStore |
			 unsigned64BitValueToStore := self positive64BitValueOf: oopToStore.
			 self successful ifTrue:
				[objectMemory storeLong64: index - 1 ofObject: array withValue: unsigned64BitValueToStore].
			 ^self]].
	"32bit-word type objects"
	unsignedValueToStore := self positive32BitValueOf: oopToStore.
	self successful ifTrue:
		[objectMemory storeLong32: index - 1 ofObject: array withValue: unsignedValueToStore]
]

{ #category : #'process primitive support' }
StackInterpreter >> supendActiveProcess [
	<api>
	
	| activeProc |
	activeProc := self activeProcess.
	self transferTo: self wakeHighestPriority.
	^ activeProc
]

{ #category : #'message sending' }
StackInterpreter >> superclassOf: classPointer [
	"Using a read barrier here simplifies the become implementation and costs very
	 little because the class index and superclass almost certainly share a cache line."
	<inline: true>
	^objectMemory followField: SuperclassIndex ofObject: classPointer
]

{ #category : #'send bytecodes' }
StackInterpreter >> superclassSend [
	"Send a message to self, starting lookup with the superclass of the class
	 containing the currently executing method."
	"Assume: messageSelector and argumentCount have been set, and that
	 the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	<sharedCodeInCase: #singleExtendedSuperBytecode>
	| superclass |
	superclass := self superclassOf: (self methodClassOf: method).
	"classTagForClass: uses ensureBehaviorHash:"
	lkupClassTag := objectMemory classTagForClass: superclass.
	"To maintain the invariant that all receivers are unforwarded we need an explicit
	 read barrier in the super send cases.  Even though we always follow receivers
	 on become  e.g. super doSomethingWith: (self become: other) forwards the receiver
	 self pushed on the stack."
	self ensureReceiverUnforwarded.
	self assert: lkupClassTag ~= objectMemory nilObject.
	self commonSendOrdinary
]

{ #category : #'debug support' }
StackInterpreter >> symbolicMethod: aMethod [
	<doNotGenerate>
	 self transcript
		ensureCr;
		nextPutAll:
			((String streamContents:
				[:ts| | prim |
				(prim := self primitiveIndexOf: aMethod) > 0 ifTrue:
					[ts nextPutAll: '<primitive: '; print: prim; nextPut: $>.
					(self isQuickPrimitiveIndex: prim) ifTrue:
						[ts nextPutAll: ' quick method'; cr; flush.
						 ^self].
					ts cr].
				(InstructionPrinter
						on: (VMCompiledMethodProxy new
								for: aMethod
								coInterpreter: self
								objectMemory: objectMemory))
					indent: 0;
					printInstructionsOn: ts]) copyReplaceAll: 'a VMObjectProxy for ' with: '');
		flush
]

{ #category : #'process primitive support' }
StackInterpreter >> synchronousSignal: aSemaphore [ 
	"Signal the given semaphore from within the interpreter.
	 Answer if the current process was preempted."
	| excessSignals |
	<inline: false>
	(self isEmptyList: aSemaphore) ifTrue:
		["no process is waiting on this semaphore"
		 excessSignals := self fetchInteger: ExcessSignalsIndex ofObject: aSemaphore.
		 self storeInteger: ExcessSignalsIndex
			ofObject: aSemaphore
			withValue: excessSignals + 1.
		 ^false].

	objectMemory ensureSemaphoreUnforwardedThroughContext: aSemaphore.

	^self resume: (self removeFirstLinkOfList: aSemaphore)
		preemptedYieldingIf: preemptionYields
]

{ #category : #'debug printing' }
StackInterpreter >> tab [
	<inline: true>
	self printChar: $	"<-Character tab"
]

{ #category : #'compiled methods' }
StackInterpreter >> tempCountOf: methodPointer [
	<api>
	^self temporaryCountOfMethodHeader: (objectMemory methodHeaderOf: methodPointer)
]

{ #category : #'internal interpreter access' }
StackInterpreter >> temporary: offset in: theFP [
	"See StackInterpreter class>>initializeFrameIndices"
	| frameNumArgs |
	<inline: true>
	<var: #theFP type: #'char *'>
	^offset < (frameNumArgs := self frameNumArgs: theFP)
		ifTrue: [stackPages longAt: theFP + FoxCallerSavedIP + ((frameNumArgs - offset) * objectMemory wordSize)]
		ifFalse: [stackPages longAt: theFP + FoxReceiver - objectMemory wordSize + ((frameNumArgs - offset) * objectMemory wordSize)]
]

{ #category : #'internal interpreter access' }
StackInterpreter >> temporary: offset in: theFP put: valueOop [
	"See StackInterpreter class>>initializeFrameIndices"
	| frameNumArgs |
	<inline: true>
	<var: #theFP type: #'char *'>
	^offset < (frameNumArgs := self frameNumArgs: theFP)
		ifTrue: [stackPages longAt: theFP + FoxCallerSavedIP + ((frameNumArgs - offset) * objectMemory wordSize) put: valueOop]
		ifFalse: [stackPages longAt: theFP + FoxReceiver - objectMemory wordSize + ((frameNumArgs - offset) * objectMemory wordSize) put: valueOop]
]

{ #category : #'compiled methods' }
StackInterpreter >> temporaryCountOfMethodHeader: header [
	<api>
	<inline: true>
	^header >> MethodHeaderTempCountShift bitAnd: 16r3F
]

{ #category : #'internal interpreter access' }
StackInterpreter >> temporaryLocation: offset in: theFP numArgs: numArgs [
	"Answer the pointer to a given temporary (for debug frame printing in odd circumstances)"
	<var: #theFP type: #'char *'>
	<returnTypeC: #'char *'>
	^offset < numArgs
		ifTrue: [theFP + FoxCallerSavedIP + ((numArgs - offset) * objectMemory wordSize)]
		ifFalse: [theFP + FoxReceiver - objectMemory wordSize + ((numArgs - offset) * objectMemory wordSize)]
]

{ #category : #simulation }
StackInterpreter >> thisClassIndex [
	<doNotGenerate>
	^thisClassIndex
]

{ #category : #'object memory support' }
StackInterpreter >> traceProfileState [
	objectMemory hasSpurMemoryManagerAPI ifTrue:
		[self followForwardingPointersInProfileState].
	objectMemory markAndTrace: profileProcess.
	objectMemory markAndTrace: profileMethod.
	objectMemory markAndTrace: profileSemaphore.

	"The longRunningPrimitiveCheckMethod (LRPCM) is sampled in an interrupt.  Be very careful with it.
	  If longRunningPrimitiveCheckSequenceNumber (LRPCSN) = statCheckForEvents then LRPCM has
	  been recenty sampled, but it must be newMethod and we don't need to trace it twice.  If LRPCSN
	  ~= statCheckForEvents then LRPCM must be some extant object and needs to be traced."
	self sqLowLevelMFence.
	(longRunningPrimitiveCheckMethod ~= nil
	 and: [longRunningPrimitiveCheckSequenceNumber ~= statCheckForEvents]) ifTrue:
		[(objectMemory isForwarded: longRunningPrimitiveCheckMethod) ifTrue:
			[longRunningPrimitiveCheckMethod := objectMemory followForwarded: longRunningPrimitiveCheckMethod].
	objectMemory markAndTrace: longRunningPrimitiveCheckMethod].
	longRunningPrimitiveCheckSemaphore ~= nil ifTrue:
		[(objectMemory isForwarded: longRunningPrimitiveCheckSemaphore) ifTrue:
			[longRunningPrimitiveCheckSemaphore := objectMemory followForwarded: longRunningPrimitiveCheckSemaphore].
		 objectMemory markAndTrace: longRunningPrimitiveCheckSemaphore]
]

{ #category : #'process primitive support' }
StackInterpreter >> transferTo: newProc [ 
	"Record a process to be awoken on the next interpreter cycle."
	| activeContext sched oldProc |
	<inline: false>
	statProcessSwitch := statProcessSwitch + 1.
	self push: instructionPointer.
	self externalWriteBackHeadFramePointers.
	self assertValidExecutionPointe: instructionPointer + 1 r: framePointer s: stackPointer.
	sched := self schedulerPointer.
	oldProc := objectMemory fetchPointer: ActiveProcessIndex ofObject: sched.
	activeContext := self ensureFrameIsMarried: framePointer SP: stackPointer + objectMemory wordSize.
	objectMemory storePointer: SuspendedContextIndex ofObject: oldProc withValue: activeContext.
	objectMemory storePointer: ActiveProcessIndex ofObject: sched withValue: newProc.
	objectMemory storePointerUnchecked: MyListIndex ofObject: newProc withValue: objectMemory nilObject.
	self externalSetStackPageAndPointersForSuspendedContextOfProcess: newProc
]

{ #category : #'sista bytecodes' }
StackInterpreter >> trinaryAtPutInlinePrimitive: primIndex [
	<option: #SistaVM>
	| result rec argIntAdjusted arg1|
	arg1 := self internalStackValue: 1.
	rec := self internalStackValue: 2.
	self deny: ((objectMemory isOopForwarded: rec) or: [(objectMemory isImmediate: rec)]).
	self assert: (objectMemory isIntegerObject: arg1).
	argIntAdjusted := (objectMemory integerValueOf: arg1) - 1.
	self assert: argIntAdjusted >= 0.
	result := self internalStackTop.
	
	primIndex caseOf: {
		"3000	pointerAt:put:
		 Mutable pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)"
		[0]	->	[self assert: (objectMemory isPointers: rec).
				 self assert: argIntAdjusted < (objectMemory numSlotsOfAny: rec).
				 objectMemory
					storePointerUnchecked: argIntAdjusted
					ofObject: rec
					withValue: result.].
		"3001	storeCheckPointerAt:put:
		 Mutable pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)"
		[1]	->	[self assert: (objectMemory isPointers: rec).
				 self assert: argIntAdjusted < (objectMemory numSlotsOfAny: rec).
				 objectMemory
					storePointer: argIntAdjusted
					ofObject: rec
					withValue: result].
		"3002	maybeContextPointerAt:put:
		 Mutable pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)"
		[2]	->	[((objectMemory isContextNonImm: rec) 
				 and: [self isMarriedOrWidowedContext: rec])
					ifTrue:
						[self externalizeIPandSP.
						 self externalInstVar: argIntAdjusted ofContext: rec  put: result.
						 self internalizeIPandSP]
					ifFalse: [objectMemory storePointer: argIntAdjusted ofObject: rec withValue: result]].
		"3003	maybeContextStoreCheckPointerAt:put:
		Mutable pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)"
		[3]	->	[((objectMemory isContextNonImm: rec) 
				 and: [self isMarriedOrWidowedContext: rec])
					ifTrue:
						[self externalizeIPandSP.
						 self externalInstVar: argIntAdjusted ofContext: rec  put: result.
						 self internalizeIPandSP]
					ifFalse: [objectMemory storePointer: argIntAdjusted ofObject: rec withValue: result]].
		"3004	byteAt:put:
		Mutable byte object, Smi, 8 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)"
		[4]	->	[self assert: (objectMemory isBytes: rec).
				 self assert: argIntAdjusted < (objectMemory numBytesOf: rec).
				 self assert: (objectMemory isIntegerObject: result).
				 objectMemory
					storeByte: argIntAdjusted
					ofObject: rec
					withValue: (objectMemory integerValueOf: result).].
		"3005	shortAt:put:
		 Mutable short object, Smi, 16 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)"
		[5]	->	[self assert: (objectMemory isShorts: rec).
				 self assert: argIntAdjusted < (objectMemory num16BitUnitsOf: rec).
				 self assert: (objectMemory isIntegerObject: result).
				 objectMemory
					storeShort16: argIntAdjusted
					ofObject: rec
					withValue: (objectMemory integerValueOf: result).].
		"3006	wordAt:put:
		 Mutable word object, Smi, 32 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)"
		[6]	->	[self assert: (objectMemory isWords: rec).
				 self assert: argIntAdjusted < (objectMemory num32BitUnitsOf: rec).
				 objectMemory
					storeLong32: argIntAdjusted
					ofObject: rec
					withValue: (objectMemory positive32BitValueOf: result).].
		"3007	doubleWordAt:put:
		 Mutable double word object, Smi, 64 bits unsigned Smi or LargePositiveInteger => arg2 (1-based, optimised if arg1 is a constant)"
		[7]	->	[self assert: (objectMemory isLong64s: rec).
				 self assert: argIntAdjusted < (objectMemory num64BitUnitsOf: rec).
				 objectMemory
					storeLong64: argIntAdjusted
					ofObject: rec
					withValue: (objectMemory positive64BitValueOf: result).].
	}.
	 self internalPop: 2; internalStackTopPut: result
]

{ #category : #'sista bytecodes' }
StackInterpreter >> trinaryInlinePrimitive: primIndex [
	<option: #SistaVM>
	"Bulk comment, each sub method has its own comment
	3000	pointerAt:put:
	Mutable pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	3001	storeCheckPointerAt:put:
	Mutable pointer object (Fixed sized or not) and not a context, Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	3002	maybeContextPointerAt:put:
	Mutable pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	3003	maybeContextStoreCheckPointerAt:put:
	Mutable pointer object (Fixed sized or not), Smi, Anything => arg2 (1-based, optimised if arg1 is a constant)
	3004	byteAt:put:
	Mutable byte object, Smi, 8 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)
	3005	shortAt:put:
	Mutable short object, Smi, 16 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)
	3006	wordAt:put:
	Mutable word object, Smi, 32 bits unsigned Smi => arg2 (1-based, optimised if arg1 is a constant)
	3007	doubleWordAt:put:
	Mutable double word object, Smi, 64 bits unsigned Smi or LargePositiveInteger => arg2 (1-based, optimised if arg1 is a constant)
	3021 is deprecated."
	primIndex <= 7 ifTrue: [^self trinaryAtPutInlinePrimitive: primIndex].
	"21 is deprecated, now this can be handled at Scorch level"
	primIndex = 21 ifTrue: 
		[ | str1 str2 word1 word2 len |
		  len := objectMemory integerValueOf: self internalStackTop.
		  len = 0 ifTrue: [^self internalPop: 2; internalStackTopPut: objectMemory trueObject].
		  str1 := self internalStackValue: 2.
  					  str2 := self internalStackValue: 1.
		  0 to: len - 1 >> objectMemory shiftForWord do: [:i |
			word1 := objectMemory fetchPointer: i ofObject: str1.
			word2 := objectMemory fetchPointer: i ofObject: str2. 
			word1 = word2 ifFalse: [^self internalPop: 2; internalStackTopPut: objectMemory falseObject] ].
		 ^self internalPop: 2; internalStackTopPut: objectMemory trueObject ].
	self unknownInlinePrimitive
]

{ #category : #'primitive support' }
StackInterpreter >> tryLoadNewPlugin: pluginString pluginEntries: pluginEntries [
	"Load the plugin and if on Spur, populate pluginEntries with the prmitives in the plugin."
	<doNotGenerate>
	| plugin realPluginClass plugins |
	self transcript cr; show: 'Looking for module ', pluginString.
	pluginString isEmpty
		ifTrue:
			[plugin := self]
		ifFalse:
			[plugins := InterpreterPlugin allSubclasses select:
							[:psc|
							 psc moduleName asString = pluginString asString
							 and: [psc shouldBeTranslated]].
			 plugins isEmpty ifTrue: [self transcript show: ' ... not found'. ^nil].
			 plugins size > 1 ifTrue: [^self error: 'This won''t work...'].
			 "plugins size > 1 ifTrue:
				[self transcript show: '...multiple plugin classes; choosing ', plugins last name]."
			 realPluginClass := plugins anyOne. "hopefully lowest in the hierarchy..."
			 plugin := realPluginClass simulatorForInterpreterInterface: objectMemory.
			 plugin ifNil: [self transcript show: ' ... no simulator class; cannot simulate'. ^nil].
			 (plugin respondsTo: #initialiseModule) ifTrue:
				[plugin initialiseModule ifFalse:
					[self transcript show: ' ... initialiser failed'. ^nil]]]. "module initialiser failed"
	self transcript show: ' ... loaded'.
	objectMemory hasSpurMemoryManagerAPI ifTrue:
		[| realPlugin cg |
		 self transcript show: '...computing accessor depths'.
		 plugin class isPluginClass
			ifTrue:
				[realPlugin := (plugin isSmartSyntaxPluginSimulator
									ifTrue: [realPluginClass]
									ifFalse: [plugin class])
								 withAllSuperclasses detect: [:class| class shouldBeTranslated].
				 cg := realPlugin buildCodeGeneratorForVMClass: self class]
			ifFalse:
				[cg := self codeGeneratorToComputeAccessorDepth.
				 primitiveTable withIndexDo:
					[:prim :index| | depth |
					 prim isSymbol ifTrue:
						[depth := cg accessorDepthCalculator accessorDepthForSelector: prim.
						 self assert: (depth isInteger or: [depth isNil and: [(plugin class whichClassIncludesSelector: prim) isNil]]).
						 primitiveAccessorDepthTable at: index - 1 put: depth]]].
		 cg exportedPrimitiveNames do:
			[:primName| | fnSymbol |
			 fnSymbol := primName asSymbol.
			 pluginEntries addLast: {plugin.
									fnSymbol.
									[plugin perform: fnSymbol. self].
									cg accessorDepthCalculator accessorDepthForSelector: fnSymbol}].
		 self transcript show: '...done'].
	^pluginString asString -> plugin
]

{ #category : #'debug printing' }
StackInterpreter >> ultimateLiteralOf: aMethodOop [
	<api>
	self assert: (objectMemory isOopCompiledMethod: aMethodOop).
	^self literal: (objectMemory literalCountOf: aMethodOop) - 1 ofMethod: aMethodOop
]

{ #category : #'internal interpreter access' }
StackInterpreter >> unPop: nItems [
	"In the StackInterpreter stacks grow down."
	stackPointer := stackPointer - (nItems*objectMemory wordSize)
]

{ #category : #'sista inline primitives - unary' }
StackInterpreter >> unaryClassPrimitive [
	| result top |
	"1000	rawClass
	 not a forwarder => Behavior (Same as class special send, but receiver is not a forwarder)"
	 top := self internalStackTop.
	 self deny: (objectMemory isOopForwarded: top).
	 result := objectMemory fetchClassOf: top.
	 self internalStackTopPut: result
]

{ #category : #'sista inline primitives - unary' }
StackInterpreter >> unaryConvertInlinePrimitive: primIndex [
	<option: #SistaVM>
	| result top |
	self assert: (primIndex between: 30 and: 32).
	top := self internalStackTop.
	primIndex caseOf: {
		"1030	characterAsInteger
		 Character => 22 bits strictly positive Smi (Unicode)"
		[30] -> [self assert: (objectMemory isImmediateCharacter: top).
				result := objectMemory characterValueOf: top.
				self assert: (result between: 1 and: "1 << 22 - 1" 4194303).
				self internalStackTopPutIntegerObjectOf: result].
		"1031	smallFloatAsInteger
		 SmallFloat => Smi"
		[31] -> [objectMemory hasSixtyFourBitImmediates
					ifTrue: "Needs to protect rotatedFloatBitsOf:"
						[self assert: (objectMemory isImmediateFloat: top).
						result := objectMemory rotatedFloatBitsOf: top.
						self assert: (objectMemory isIntegerObject: result).
						self internalStackTopPutIntegerObjectOf: result]
					ifFalse: [self unknownInlinePrimitive]].
		"1032	smiAsFloat
		 Smi => SmallFloat"
		[32] -> [self assert: (objectMemory isIntegerObject: top).
				self pop: 1 thenPushFloat: (objectMemory integerValueOf: top) asFloat].
		 }
]

{ #category : #'sista inline primitives - unary' }
StackInterpreter >> unaryHashInlinePrimitive: primIndex [
	<option: #SistaVM>
	| result top |
	self assert: (primIndex between: 20 and: 23).
	top := self internalStackTop.
	primIndex caseOf: {
		"1020	objectIdentityHash
		 non-immediate and non-behavior => 22 bits strictly positive Smi"
		[20] ->	[self deny: ((objectMemory isOopForwarded: top)
						or: [(objectMemory isImmediate: top)
							or: [objectMemory isInClassTable: top]]).
				 result := objectMemory hashBitsOf: top.
				self assert: (result between: 1 and: "1 << 22 - 1" 4194303).
				self internalStackTopPutIntegerObjectOf: result].
		"1021	smiIdentityHash
		 Smi => Smi"
		[21] -> [self assert: (objectMemory isIntegerObject: top).
				"Don't do anything, Smi hash is the object itself"].		
		"1022	charIdentityHash
		 Character => 22 bits strictly positive Smi"
		[22] -> [self assert: (objectMemory isImmediateCharacter: top).
				result := objectMemory integerObjectOfCharacterObject: top.
				self assert: (result between: 1 and: "1 << 22 - 1" 4194303).
				self internalStackTopPut: result].
		"1023	smallfloatIdentityHash
		 SmallFloat => Smi"
		[23] -> [objectMemory hasSixtyFourBitImmediates
					ifTrue: "Needs to protect rotatedFloatBitsOf:"
						[self assert: (objectMemory isImmediateFloat: top).
						result := objectMemory rotatedFloatBitsOf: top.
						self assert: (objectMemory isIntegerObject: result).
						self internalStackTopPutIntegerObjectOf: result]
					ifFalse: [self unknownInlinePrimitive]].
		"1024	behaviorIdentityHash
		 Behavior => 22 bits strictly positive Smi"
		[24] -> [self assert: ((objectMemory isNonImmediate: top) 
					and: [objectMemory objCouldBeClassObj: top]).
				result := objectMemory ensureBehaviorHash: top.
				self assert: (result between: 1 and: "1 << 22 - 1" 4194303).
				self internalStackTopPutIntegerObjectOf: result].	
		 }
]

{ #category : #'sista inline primitives - unary' }
StackInterpreter >> unaryInlinePrimitive: primIndex [
	<option: #SistaVM>
	"Bulk comments: each sub-method has its own comment with the specific case.
	1000	rawClass
	not a forwarder => Behavior (Same as class special send, but receiver is not a forwarder)
	1001	numSlots
	pointer object => Smi between 0 and SmallInteger maxVal // 4 - 1 (Answers total size in pointer-sized slots)
	1002	numBytes
	byte object => Smi between 0 and SmallInteger maxVal - 9 (Includes compiled code)
	1003	numShorts
	short object => Smi between 0 and SmallInteger maxVal - 9
	1004	numWords
	word object => Smi between 0 and SmallInteger maxVal - 9
	1005	numDoubleWords
	double word object => Smi between 0 and SmallInteger maxVal - 9
	1011	RawNew
	literal which is a fixed-sized behavior => instance of the receiver with fields nilled out
	1012	RawNewNoInit
	literal which is a fixed-sized behavior => instance of the receiver (Fields of returned value contain undefined data)
	1020	objectIdentityHash
	non-immediate and non-behavior => 22 bits strictly positive Smi
	1021	smiIdentityHash
	Smi => Smi
	1022	charIdentityHash
	Character => 22 bits strictly positive Smi
	1023	smallfloatIdentityHash
	SmallFloat => Smi
	1024	behaviorIdentityHash
	Behavior => 22 bits strictly positive Smi
	1030	characterAsInteger
	Character => 22 bits strictly positive Smi (Unicode)
	1031	smallFloatAsInteger
	SmallFloat => Smi
	1032	smiAsFloat
	Smi => SmallFloat
	1039	unforwardNonImmediate
	non immediate => Not a forwarder
	1040	unforward
	Anything => Not a forwarder
	1041	possibleRoot
	non-immediate, not a forwarder => receiver is returned (should be effect-only) (If old, becomes gray and remembered to allow many unchecked stores in a row afterwards)"
	primIndex = 0 ifTrue: [^self unaryClassPrimitive].
	primIndex <= 6 ifTrue: [^self unarySizeInlinePrimitive: primIndex].
	primIndex < 11 ifTrue: [^self unknownInlinePrimitive].
	primIndex <= 12 ifTrue: [^self unaryNewInlinePrimitive: primIndex].
	primIndex < 20 ifTrue: [^self unknownInlinePrimitive].
	primIndex <= 24 ifTrue: [^self unaryHashInlinePrimitive: primIndex].
	primIndex < 30 ifTrue: [^self unknownInlinePrimitive].
	primIndex <= 32 ifTrue: [^self unaryConvertInlinePrimitive: primIndex].
	primIndex < 39 ifTrue: [^ self unknownInlinePrimitive].
	primIndex <= 40 ifTrue: [^self unaryUnforwardInlinePrimitive: primIndex].
	primIndex = 41 ifTrue: [^self unaryPossibleRootInlinePrimitive].
	self unknownInlinePrimitive
]

{ #category : #'sista inline primitives - unary' }
StackInterpreter >> unaryNewInlinePrimitive: primIndex [
	"1011	RawNew
	 literal which is a fixed-sized behavior => instance of the receiver with fields nilled out
	1012	RawNewNoInit
	literal which is a fixed-sized behavior => instance of the receiver (Fields of returned value contain undefined data)
	
	WARNING: In the interpreter version, fields are always initialized."
	| classObj result |
	self assert: (primIndex between: 11 and: 12).
	classObj := self internalStackTop.
	self assert: ((objectMemory isNonImmediate: classObj) and: [self objCouldBeClassObj: classObj]).
	result := objectMemory instantiateClass: classObj.
	self internalStackTopPut: result
]

{ #category : #'sista inline primitives - unary' }
StackInterpreter >> unaryPossibleRootInlinePrimitive [
	<option: #SistaVM>
	"1041	possibleRoot
	 non-immediate, not a forwarder => receiver is returned (should be effect-only) (If old, becomes gray and remembered to allow many unchecked stores in a row afterwards)"
	| top |
	top := self internalStackTop.
	self deny: (objectMemory isImmediate: top).
	self deny: (objectMemory isOopForwarded: top).
	(objectMemory isYoungObject: top)
		ifFalse: [objectMemory possibleRootStoreInto: top]
]

{ #category : #'sista inline primitives - unary' }
StackInterpreter >> unarySizeInlinePrimitive: primIndex [
	<option: #SistaVM>
	| result top |
	self assert: (primIndex between: 1 and: 6).
	top := self internalStackTop.
	primIndex caseOf: {
		"1001	numSlots
		 pointer object => Smi between 0 and SmallInteger maxVal // 4 - 1 (Answers total size in pointer-sized slots)"
		[1]	->	[self assert: (objectMemory isPointers: top).
				 result := objectMemory numSlotsOfAny: top.
				 self assert: (result between: 0 and: objectMemory maxSmallInteger // 4 - 1)].
		"1002	numBytes
		 byte object => Smi between 0 and SmallInteger maxVal - 9 (Includes compiled code)"
		[2]	->	[self assert: (objectMemory isBytes: top).
				 result := objectMemory numBytesOf: top].
		"1003	numShorts
		 short object => Smi between 0 and SmallInteger maxVal - 9"
		[3]	->	[self assert: (objectMemory isShorts: top).
				 result := objectMemory num16BitUnitsOf: top].
		"1004	numWords
		 word object => Smi between 0 and SmallInteger maxVal - 9"
		[5]	->	[self assert: (objectMemory isWords: top).
				 result := objectMemory num32BitUnitsOf: top].
		"1005	numDoubleWords 
		 double word object => Smi between 0 and SmallInteger maxVal - 9"
		[6]	->	[self assert: (objectMemory isLong64s: top).
				 result := objectMemory num64BitUnitsOf: top].
	}.
	self assert: (result between: 0 and: objectMemory maxSmallInteger - 9).
	self internalStackTopPut: (objectMemory integerObjectOf: result)
	
]

{ #category : #'sista inline primitives - unary' }
StackInterpreter >> unaryUnforwardInlinePrimitive: primIndex [
	<option: #SistaVM>
	"1039	unforwardNonImmediate
	 non immediate => Not a forwarder
	 1040	unforward
	 Anything => Not a forwarder"
	"Only perf in jitted code matters, don't remove the immediate check"
	 | top |
	 top := self internalStackTop.
	self assert: (primIndex = 40 or: [objectMemory isNonImmediate: top]).
	 (objectMemory isOopForwarded: top) ifTrue:
		[self internalStackTopPut: (objectMemory followForwarded: top)]
]

{ #category : #'sista bytecodes' }
StackInterpreter >> unconditionnalTrapBytecode [
	"SistaV1: *	217	Trap"
	SistaVM 
		ifTrue: [^self respondToSistaTrap]
		ifFalse: [^self respondToUnknownBytecode]
]

{ #category : #'interpreter shell' }
StackInterpreter >> undoFetchNextBytecode [
	"Backup the ip when it has been incremented to fetch the next bytecode."

	localIP := localIP - 1
]

{ #category : #'compiled methods' }
StackInterpreter >> unfollow: litVar atIndex: literalIndex [
	<option: #SpurMemoryManager>
	<inline: #never> "So rare it mustn't bulk up the common path"
	| followed |
	followed := objectMemory followForwarded: litVar.
	self literal: literalIndex ofMethod: method put: followed.
	^followed
]

{ #category : #'compiled methods' }
StackInterpreter >> unfollowTempVector: tempVector atIndex: tempVectorIndex in: theFP [
	<option: #TempVectReadBarrier>
	<inline: #never> "So rare it mustn't bulk up the common path"
	| followed |
	followed := objectMemory followForwarded: tempVector.
	self temporary: tempVectorIndex in: theFP put: followed.
	^followed
]

{ #category : #'miscellaneous bytecodes' }
StackInterpreter >> unknownBytecode [
	"If an error selector is available then send it to the activeContext, otherwise abort."
	self respondToUnknownBytecode
]

{ #category : #'sista bytecodes' }
StackInterpreter >> unknownInlinePrimitive [
	<inline: true> "Should be inlined everywhere to access localIP"
	localIP := localIP - 3.
	self respondToUnknownBytecode
]

{ #category : #'image save/restore' }
StackInterpreter >> unknownShortOrCodeSizeInKs [
	"preserve whatever this value was (for images run on Cog)"
	^theUnknownShort
]

{ #category : #'I/O primitive support' }
StackInterpreter >> updateDisplayLeft: l Top: t Right: r Bottom: b [
	"Repaint the portion of the Smalltalk screen bounded by the affected rectangle.
	 Used to synchronize the screen after a Bitblt to the Smalltalk Display object."
	| left right top bottom surfaceHandle |
	left := l max: 0.
	right := r min: displayWidth.
	top := t max: 0.
	bottom := b min: displayHeight.
	(left <= right and: [top <= bottom]) ifFalse: [^nil].
	(objectMemory isIntegerObject: displayBits asInteger)
		ifTrue:
			[surfaceHandle := objectMemory integerValueOf: displayBits asInteger.
			 showSurfaceFn = 0 ifTrue:
				[showSurfaceFn := self ioLoadFunction: 'ioShowSurface' From: 'SurfacePlugin'.
				 showSurfaceFn = 0 ifTrue: [^self primitiveFailFor: PrimErrNotFound]].
			 self show: surfaceHandle Sur: left fa: top ce: right - left Fn: bottom - top]
		ifFalse:
			[self assert: (objectMemory isNonImmediate: displayBits asInteger).
			 self ioShow: displayBits asInteger
				D: displayWidth i: displayHeight s: displayDepth
				p: left l: right a: top y: bottom]
]

{ #category : #'image save/restore' }
StackInterpreter >> updateObjectsPostByteSwap [
	"Byte-swap the words of all bytes objects in the image, including Strings, ByteArrays,
	 and CompiledMethods. This returns these objects to their original byte ordering
	 after blindly byte-swapping the entire image. For compiled  methods, byte-swap
	 only their bytecodes part. Ensure floats are in platform-order."
	| swapFloatWords |
	swapFloatWords := objectMemory vmEndianness ~= imageFloatsBigEndian.
	self assert: ClassFloatCompactIndex ~= 0.
	objectMemory allObjectsDo:
		[:oop| | fmt wordAddr methodHeader temp |
		fmt := objectMemory formatOf: oop.
		 fmt >= self firstByteFormat ifTrue: "oop contains bytes"
			[wordAddr := oop + objectMemory baseHeaderSize.
			fmt >= self firstCompiledMethodFormat ifTrue: "compiled method; start after methodHeader and literals"
				[methodHeader := objectMemory longAt: oop + objectMemory baseHeaderSize.
				 wordAddr := wordAddr + (((objectMemory literalCountOfMethodHeader: methodHeader) + LiteralStart) * objectMemory bytesPerOop)].
			objectMemory reverseBytesFrom: wordAddr to: oop + (objectMemory sizeBitsOf: oop)].
		 fmt = self firstLongFormat ifTrue: "Bitmap, Float etc"
			[(swapFloatWords
			  and: [(objectMemory compactClassIndexOf: oop) = ClassFloatCompactIndex])
				ifTrue:
					[temp := objectMemory longAt: oop + objectMemory baseHeaderSize.
					 objectMemory longAt: oop + objectMemory baseHeaderSize put: (self longAt: oop + objectMemory baseHeaderSize + 4).
					 objectMemory longAt: oop + objectMemory baseHeaderSize + 4 put: temp]
				ifFalse:
					[(objectMemory hasSpurMemoryManagerAPI not
					  and: [objectMemory wordSize = 8]) ifTrue: "Object contains 32-bit half-words packed into 64-bit machine words."
						[wordAddr := oop + objectMemory baseHeaderSize.
						 objectMemory reverseWordsFrom: wordAddr to: oop + (objectMemory sizeBitsOf: oop)]]]]
]

{ #category : #'frame access' }
StackInterpreter >> updateStateOfSpouseContextForFrame: theFP WithSP: theSP [
	"Update the frame's spouse context with the frame's current state except for the
	 sender and instruction pointer, which are used to mark the context as married."
	| theContext tempIndex pointer |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #pointer type: #'char *'>
	self assert: (self frameHasContext: theFP).
	theContext := self frameContext: theFP.
	self assert: (self frameReceiver: theFP)
				= (objectMemory fetchPointer: ReceiverIndex ofObject: theContext).
	tempIndex := self frameNumArgs: theFP.
	"update the arguments. this would appear not to be strictly necessary, but is for two reasons.
	 First, the fact that arguments are read-only is only as convention in the Smalltalk compiler;
	 other languages may choose to modify arguments.
	 Second, the Squeak runUntilErrorOrReturnFrom: nightmare pops the stack top, which may, in
	 certain circumstances, be the last argument, and hence the last argument may not have been
	 stored into the context."
	pointer := theFP + (self frameStackedReceiverOffsetNumArgs: tempIndex).
	1 to: tempIndex do:
		[:i|
		pointer := pointer - objectMemory wordSize.
		self assert: (objectMemory addressCouldBeOop: (stackPages longAt: pointer)).
		 objectMemory storePointer: ReceiverIndex + i
			ofObject: theContext
			withValue: (stackPages longAt: pointer)].
	"now update the non-argument stack contents."
	pointer := theFP + FoxReceiver - objectMemory wordSize.
	[pointer >= theSP] whileTrue:
		[self assert: (objectMemory addressCouldBeOop: (stackPages longAt: pointer)).
		 tempIndex := tempIndex + 1.
		 objectMemory storePointer: ReceiverIndex + tempIndex
			ofObject: theContext
			withValue: (stackPages longAt: pointer).
		 pointer := pointer - objectMemory wordSize].
	self assert: ReceiverIndex + tempIndex < (objectMemory lengthOf: theContext).
	objectMemory storePointerUnchecked: StackPointerIndex
		ofObject: theContext
		withValue: (objectMemory integerObjectOf: tempIndex)
]

{ #category : #'debug support' }
StackInterpreter >> validBCPC: thePC inMethod: aMethod [
	<var: #aMethod type: #usqInt>
	"Note that we accept anInstrPointer pointing to a callPrimitiveBytecode
	 at the start of a method that contains a primitive.  This because methods like
	 Context(Part)>>reset have to be updated to skip the callPrimtiive bytecode otherwise."
	^thePC >= (self startPCOfMethod: aMethod)
	  and: [thePC <= (objectMemory numBytesOfBytes: aMethod)]
]

{ #category : #'debug support' }
StackInterpreter >> validInstructionPointer: anInstrPointer inFrame: fp [
	<var: #anInstrPointer type: #usqInt>
	<var: #fp type: #'char *'>
	<inline: false>
	"Note that we accept anInstrPointer pointing to a callPrimitiveBytecode
	 at the start of a method that contains a primitive.  This because methods like
	 Context(Part)>>reset have to be updated to skip the callPrimtiive bytecode otherwise."
	^self validInstructionPointer: anInstrPointer inMethod: (self frameMethodObject: fp) framePointer: fp
]

{ #category : #'debug support' }
StackInterpreter >> validInstructionPointer: theInstrPointer inMethod: aMethod framePointer: fp [
	<var: #theInstrPointer type: #usqInt>
	<var: #aMethod type: #usqInt>
	<var: #fp type: #'char *'>
	"Note that we accept anInstrPointer pointing to a callPrimitiveBytecode
	 at the start of a method that contains a primitive.  This because methods like
	 Context(Part)>>reset have to be updated to skip the callPrimtiive bytecode otherwise."
	"-1 for pre-increment in fetchNextBytecode"
	^theInstrPointer >= (aMethod + (objectMemory lastPointerOf: aMethod) + objectMemory bytesPerOop - 1)
	  and: [theInstrPointer < (aMethod + (objectMemory numBytesOfBytes: aMethod) + objectMemory baseHeaderSize - 1)]
]

{ #category : #'stack pages' }
StackInterpreter >> validStackPageBaseFrame: aPage [
	"Check that the base frame in the stack page has a valid sender context."
	<var: #aPage type: #'StackPage *'>
	<inline: false>
	| senderContextOrNil |
	(self asserta: (self isBaseFrame: aPage baseFP)) ifFalse:
		[^false].
	senderContextOrNil := self frameCallerContext: aPage baseFP.
	(self asserta: (objectMemory addressCouldBeObj: senderContextOrNil)) ifFalse:
		[^false].
	(self asserta: (senderContextOrNil = objectMemory nilObject or: [objectMemory isContext: senderContextOrNil])) ifFalse:
		[^false].
	^true
]

{ #category : #'stack pages' }
StackInterpreter >> validStackPageBaseFrames [
	"Check that the base frames in all in-use stack pages have a sender and a saved context."
	<var: #aPage type: #'StackPage *'>
	0 to: numStackPages - 1 do:
		[:i| | aPage senderContextOrNil savedThisContext |
		aPage := stackPages stackPageAt: i.
		(stackPages isFree: aPage) ifFalse:
			[(self validStackPageBaseFrame: aPage) ifFalse:
				[^false]]].
	^true
]

{ #category : #'primitive support' }
StackInterpreter >> voidLongRunningPrimitive: reason [
	"Void the state associated with the long-running primitive check.
	 This is done when a new semaphore is installed or when it appears
	 that is longRunningPrimitiveCheckMethod is invalid, e.g. because it
	 has eben sampled in the middle of a GC."
	<var: #reason type: #'char *'>
	<inline: #never>
	longRunningPrimitiveCheckMethod := nil.
	longRunningPrimitiveStartUsecs :=
	longRunningPrimitiveStopUsecs := 0.
	longRunningPrimitiveSignalUndelivered := true.
	self sqLowLevelMFence
]

{ #category : #'frame access' }
StackInterpreter >> voidVMStateForSnapshotFlushingExternalPrimitivesIf: flushExtPrims [
	"Make sure that all VM state that affects the heap contents is voided so that the heap is
	 ready to be snapshotted.  If flushExtPrims is true, flush references to external
	 primitives in methods.  Answer the activeContext that should be stored in the snapshot."
	| activeContext |
	<inline: false>
	activeContext := self divorceAllFrames.
	self bereaveAllMarriedContextsForSnapshotFlushingExternalPrimitivesIf: flushExtPrims.
	^activeContext
]

{ #category : #'process primitive support' }
StackInterpreter >> wakeHighestPriority [
	"Return the highest priority process that is ready to run.
	 To save time looking at many empty lists before finding a
	 runnable process the VM maintains a variable holding the
	 highest priority runnable process.  If this variable is 0 then the
	 VM does not know the highest priority and must search all lists.
	 Note: It is a fatal VM error if there is no runnable process."
	| schedLists p processList proc ctxt |
	self externalWriteBackHeadFramePointers.
	schedLists := objectMemory fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	p := highestRunnableProcessPriority = 0
			ifTrue: [objectMemory numSlotsOf: schedLists]
			ifFalse: [highestRunnableProcessPriority].
	[(p := p - 1) >= 0] whileTrue:
		[processList := objectMemory fetchPointer: p ofObject: schedLists.
	 	 [self isEmptyList: processList] whileFalse:
			["Only answer processes with a runnable suspendedContext.
			  Discard those that aren't; the VM would crash otherwise."
			 proc := self removeFirstLinkOfList: processList.
			 ctxt := objectMemory fetchPointer: SuspendedContextIndex ofObject: proc.
			 (self isLiveContext: ctxt) ifTrue:
				[highestRunnableProcessPriority := p + 1.
				^proc].
			  self cppIf: SPURVM ifTrue: 
				["This is uncommon, so we can deal with forwarders here instead of assuming there isn't."
				 (objectMemory isOopForwarded: ctxt) ifTrue:
					[ctxt := self fixFollowedField: SuspendedContextIndex ofObject: proc withInitialValue: ctxt].
				  (self isLiveContext: ctxt) ifTrue:
					[highestRunnableProcessPriority := p + 1.
					^proc].].
			 self warning: 'evicted zombie process from run queue']].
	self error: 'scheduler could not find a runnable process'.
	^nil
]

{ #category : #'debug printing' }
StackInterpreter >> whereIs: anOop [
	<api>
	<returnTypeC: 'char *'>
	<inline: false>
	<var: 'where' type: #'char *'>
	(objectMemory whereIsMaybeHeapThing: anOop) ifNotNil: [:where| ^where].
	(stackPages whereIsMaybeStackThing: anOop) ifNotNil: [:where| ^where].
	^' is no where obvious'
]

{ #category : #'frame access' }
StackInterpreter >> withSmallIntegerTags: value [
	<inline: true>
	<var: #value type: #'char *'>
	self assert: ((self oopForPointer: value) bitAnd: objectMemory wordSize - 1) = 0.
	^(self
		cCode: [self oopForPointer: value]
		inSmalltalk: [value bitAnd: objectMemory maxCInteger]) + objectMemory smallIntegerTag
]

{ #category : #'frame access' }
StackInterpreter >> withoutSmallIntegerTags: anInteger [
	<inline: true>
	<returnTypeC: #'char *'>
	self assert: (objectMemory isIntegerObject: anInteger).
	^self pointerForOop: (anInteger - 1)
]

{ #category : #'image save/restore' }
StackInterpreter >> wordSwapped: w [
	"Return the given 64-bit integer with its halves in the reverse order."

	objectMemory wordSize = 8 ifFalse: [self error: 'This cannot happen.'].
	^   ((w >> 32) bitAnd: 16r00000000FFFFFFFF) bitOr:
	     ((w << 32) bitAnd: 16rFFFFFFFF00000000)

]

{ #category : #'stack pages' }
StackInterpreter >> writeBackHeadFramePointers [
	self assert: stackPage = stackPages mostRecentlyUsedPage.
	self setHeadFP: localFP andSP: localSP inPage: stackPage.
	self assert: stackPages pageListIsWellFormed
]

{ #category : #'image save/restore' }
StackInterpreter >> writeImageFileIO [
	"Write the image header and heap contents to imageFile for snapshot. c.f. writeImageFileIOSimulation.
	 The game below is to maintain 64-bit alignment for all putLong:toFile: occurrences."
	<inline: #never>
	| imageName headerStart headerSize f imageBytes bytesWritten sCWIfn okToWrite |
	<var: #f type: #sqImageFile>
	<var: #headerStart type: #squeakFileOffsetType>
	<var: #sCWIfn type: #'void *'>
	<var: #imageName declareC: 'extern char imageName[]'>

	self cCode: [] inSmalltalk: [imageName := 'sooth compiler'. ^self writeImageFileIOSimulation].

	"If the security plugin can be loaded, use it to check for write permission.
	 If not, assume it's ok"
	sCWIfn := self ioLoadFunction: 'secCanWriteImage' From: 'SecurityPlugin'.
	sCWIfn ~= 0 ifTrue:
		[okToWrite := self cCode: '((sqInt (*)(void))sCWIfn)()'.
		 okToWrite ifFalse:[^self primitiveFail]].
	
	"local constants"
	headerStart := 0.  
	headerSize := objectMemory wordSize = 4 ifTrue: [64] ifFalse: [128].  "header size in bytes; do not change!"

	f := self sqImageFile: imageName Open: 'wb'.
	f = nil ifTrue: "could not open the image file for writing"
		[^self primitiveFail].

	imageBytes := objectMemory imageSizeToWrite.
	headerStart := self sqImage: f File: imageName StartLocation: headerSize + imageBytes.
	self cCode: '/* Note: on Unix systems one could put an exec command here, padded to 512 bytes */'.
	"position file to start of header"
	self sqImageFile: f Seek: headerStart.

	self putWord32: self imageFormatVersion toFile: f.
	self putWord32: headerSize toFile: f.
	self putLong: imageBytes toFile: f.
	self putLong: objectMemory baseAddressOfImage toFile: f.
	self putLong: objectMemory specialObjectsOop toFile: f.
	self putLong: objectMemory newObjectHash toFile: f.
	self putLong: self getSnapshotScreenSize toFile: f.
	self putLong: self getImageHeaderFlags toFile: f.
	self putWord32: extraVMMemory toFile: f.
	self putShort: desiredNumStackPages toFile: f.
	self putShort: self unknownShortOrCodeSizeInKs toFile: f.
	self putWord32: desiredEdenBytes toFile: f.
	self putShort: (maxExtSemTabSizeSet ifTrue: [self ioGetMaxExtSemTableSize] ifFalse: [0]) toFile: f.
	self putShort: the2ndUnknownShort toFile: f.
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[self putLong: objectMemory firstSegmentBytes toFile: f.
			 self putLong: objectMemory bytesLeftInOldSpace toFile: f.
			 2 timesRepeat: [self putLong: 0 toFile: f]	"Pad the rest of the header."]
		ifFalse:
			[4 timesRepeat: [self putLong: 0 toFile: f]].  "Pad the rest of the header."

	 objectMemory wordSize = 8 ifTrue:
		[3 timesRepeat: [self putLong: 0 toFile: f]]. "Pad the rest of the header."

	self assert: headerStart + headerSize = (self sqImageFilePosition: f).
	"position file after the header"
	self sqImageFile: f Seek: headerStart + headerSize.

	self successful ifFalse: "file write or seek failure"
		[self sqImageFileClose: f.
		 ^nil].

	"write the image data"
	objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[bytesWritten := objectMemory writeImageSegmentsToFile: f]
		ifFalse:
			[bytesWritten := self sq: (self pointerForOop: objectMemory baseAddressOfImage)
								Image: (self sizeof: #char)
								File: imageBytes
								Write: f].
	self success: bytesWritten = imageBytes.
	self sqImageFileClose: f
]

{ #category : #'image save/restore' }
StackInterpreter >> writeImageFileIOSimulation [
	"Write the image header and heap contents to imageFile for snapshot.
	 c.f. writeImageFileIO.  The game below is to maintain 64-bit alignment
	 for all putLong:toFile: occurrences."
	<doNotGenerate>
	| headerSize |
	headerSize := objectMemory wordSize = 4 ifTrue: [64] ifFalse: [128].

	self imageName asFileReference binaryWriteStreamDo: [ :file |
			 self putWord32: self imageFormatVersion toFile: file.
			 self putWord32: headerSize toFile: file.
			{
		objectMemory imageSizeToWrite.
		objectMemory baseAddressOfImage.
		objectMemory specialObjectsOop.
		objectMemory lastHash.
		self ioScreenSize.
		self getImageHeaderFlags
	 }
		do: [:long | self putLong: long toFile: file].		

	 self putWord32: (extraVMMemory ifNil: [0]) toFile: file.
	 {	desiredNumStackPages. self unknownShortOrCodeSizeInKs } do:
		[:short| self putShort: short toFile: file].

	 self putWord32: desiredEdenBytes toFile: file.

	 {	maxExtSemTabSizeSet ifTrue: [self ioGetMaxExtSemTableSize] ifFalse: [0]. 0 } do:
		[:short| self putShort: short toFile: file].

	 objectMemory hasSpurMemoryManagerAPI
		ifTrue:
			[| bytesWritten |
			 self putLong: objectMemory firstSegmentBytes toFile: file.
			 self putLong: objectMemory bytesLeftInOldSpace toFile: file.
			 2 timesRepeat: [self putLong: 0 toFile: file] "Pad the rest of the header.".
			 objectMemory wordSize = 8 ifTrue:
				[3 timesRepeat: [self putLong: 0 toFile: file]].

			 self assert: file position = headerSize.
			"Position the file after the header."
			file position: headerSize.
			bytesWritten := objectMemory writeImageSegmentsToFile: file.
			self assert: bytesWritten = objectMemory imageSizeToWrite]
		ifFalse:
			["Pad the rest of the header."
			 4 timesRepeat: [self putLong: 0 toFile: file].
			 objectMemory wordSize = 8 ifTrue:
				[3 timesRepeat: [self putLong: 0 toFile: file]].

			 self assert: file position = headerSize.
			 "Position the file after the header."
			 file position: headerSize.

			 "Write the object memory."
			 objectMemory baseAddressOfImage // 4 + 1
				to: objectMemory baseAddressOfImage + objectMemory imageSizeToWrite // 4
				do: [:index |
					self
						putLong: (objectMemory memory at: index)
						toFile: file]].
	
	 self success: true
	]
]

{ #category : #'stack pages' }
StackInterpreter >> zeroStackPage [
	"In its own method as a debugging hook.
	 Frame pointers should have been written back already."
	<inline: true>
	self assert: (stackPage = 0
				or: [stackPage headFP = framePointer
					and: [stackPage headSP = stackPointer]]).
	stackPage := 0
]
