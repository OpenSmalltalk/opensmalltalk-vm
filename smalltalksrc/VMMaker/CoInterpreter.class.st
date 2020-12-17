"
I am a variant of the StackInterpreter that can co-exist with the Cog JIT.  I interpret unjitted methods, either because they have been found for the first time or because they are judged to be too big to JIT.  See CogMethod class's comment for method interoperability.

cogCodeSize
	- the current size of the machine code zone

cogCompiledCodeCompactionCalledFor
	- a variable set when the machine code zone runs out of space, causing a machine code zone compaction at the next available opportunity

cogMethodZone
	- the manager for the machine code zone (instance of CogMethodZone)

cogit
	- the JIT (co-jit) (instance of SimpleStackBasedCogit, StackToRegisterMappoingCogit, etc)

deferSmash
	- a flag causing deferral of smashes of the stackLimit around the call of functionSymbol (for assert checks)

deferredSmash
	- a flag noting deferral of smashes of the stackLimit around the call of functionSymbol (for assert checks)

desiredCogCodeSize
	- the desred size of the machine code zone, set at startup or via primitiveVMParameter to be written at snapshot time

flagInterpretedMethods
	- true if methods that are interpreted shoudl have their flag bit set (used to identity methods that are interpreted because they're unjittable for some reason)

gcMode
	- the variable holding the gcMode, used to inform the cogit of how to scan the machine code zone for oops on GC

heapBase
	- the address in memory of the base of the objectMemory's heap, which is immediately above the machine code zone

lastCoggableInterpretedBlockMethod
	- a variable used to invoke the cogit for a block mehtod being invoked repeatedly in the interpreter

lastUncoggableInterpretedBlockMethod
	- a variable used to avoid invoking the cogit for an unjittable method encountered on block evaluation

maxLiteralCountForCompile
	- the variable controlling which methods to jit.  methods with a literal count above this value will not be jitted (on the grounds that large methods are typically used for initialization, and take up a lot of space in the code zone)

minBackwardJumpCountForCompile
	- the variable controlling when to attempt to jit a method being interpreted.  If as many backward jumps as this occur, the current method will be jitted

primTraceLog
	- a small array implementing a crcular buffer logging the last N primitive invocations, GCs, code compactions, etc used for crash reporting

primTraceLogIndex
	- the index into primTraceLog of the next entry

reenterInterpreter
	- the jmpbuf used to jmp back into the interpreter when transitioning from machine code to the interpreter

statCodeCompactionCount
	- the count of machine code zone compactions

statCodeCompactionUsecs
	- the total microseconds spent in machine code zone compactions

traceLog
	- a log of various events, used in debugging

traceLogIndex
	- the index into traceLog of the next entry

traceSources
	- the names associated with the codes of events in traceLog
"
Class {
	#name : #CoInterpreter,
	#superclass : #StackInterpreterPrimitives,
	#instVars : [
		'cogit',
		'cogMethodZone',
		'gcMode',
		'cogCodeSize',
		'desiredCogCodeSize',
		'heapBase',
		'lastCoggableInterpretedBlockMethod',
		'deferSmash',
		'deferredSmash',
		'primTraceLog',
		'primTraceLogIndex',
		'traceLog',
		'traceLogIndex',
		'traceSources',
		'cogCompiledCodeCompactionCalledFor',
		'statCodeCompactionCount',
		'statCodeCompactionUsecs',
		'lastUncoggableInterpretedBlockMethod',
		'flagInterpretedMethods',
		'maxLiteralCountForCompile',
		'minBackwardJumpCountForCompile'
	],
	#classVars : [
		'CSCallbackEnter',
		'CSCallbackLeave',
		'CSCheckEvents',
		'CSEnterCriticalSection',
		'CSExitCriticalSection',
		'CSOwnVM',
		'CSResume',
		'CSSignal',
		'CSSuspend',
		'CSSwitchIfNeccessary',
		'CSThreadBind',
		'CSThreadSchedulingLoop',
		'CSWait',
		'CSYield',
		'HasBeenReturnedFromMCPC',
		'HasBeenReturnedFromMCPCOop',
		'MFMethodFlagFrameIsMarkedFlag',
		'MinBackwardJumpCountForCompile',
		'PrimNumberHashMultiply',
		'PrimTraceLogSize',
		'RumpCStackSize',
		'TraceBlockActivation',
		'TraceBlockCreation',
		'TraceBufferSize',
		'TraceCodeCompaction',
		'TraceContextSwitch',
		'TraceDisownVM',
		'TraceFullGC',
		'TraceIncrementalGC',
		'TraceIsFromInterpreter',
		'TraceIsFromMachineCode',
		'TraceOwnVM',
		'TracePreemptDisowningThread',
		'TracePrimitiveFailure',
		'TracePrimitiveRetry',
		'TraceSources',
		'TraceStackOverflow',
		'TraceThreadSwitch',
		'TraceVMCallback',
		'TraceVMCallbackReturn'
	],
	#pools : [
		'CogMethodConstants',
		'VMStackFrameOffsets'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CoInterpreter class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	^(super ancilliaryClasses copyWithout: InterpreterStackPages),
	   {	CoInterpreterStackPages.
		CogBlockMethod },
	((Cogit ancilliaryClasses) select: [:class| class inheritsFrom: CogBlockMethod])
]

{ #category : #translation }
CoInterpreter class >> apiExportHeaderName [
	^'cointerp.h'
]

{ #category : #translation }
CoInterpreter class >> declareCVarsIn: aCCodeGenerator [
	"Override to avoid repeating StackInterpreter's declarations and add our own extensions"
	self class == thisContext methodClass ifFalse: [^self]. "Don't duplicate decls in subclasses"
	aCCodeGenerator
		addHeaderFile:'"sqCogStackAlignment.h"';
		addHeaderFile:'"cogmethod.h"'.
	aCCodeGenerator
		addHeaderFile: (aCCodeGenerator vmClass isThreadedVM 
			ifTrue: ['"cointerpmt.h"'] 
			ifFalse: ['"cointerp.h"']);
		addHeaderFile:'"cogit.h"'.
	aCCodeGenerator vmClass
		declareInterpreterVersionIn: aCCodeGenerator
		defaultName: aCCodeGenerator interpreterVersion.
	aCCodeGenerator
		var: #heapBase type: #usqInt;
		var: #statCodeCompactionUsecs type: #usqLong;
		var: #maxLiteralCountForCompile
			declareC: 'sqInt maxLiteralCountForCompile = MaxLiteralCountForCompile /* ', MaxLiteralCountForCompile printString, ' */';
		var: #minBackwardJumpCountForCompile
			declareC: 'sqInt minBackwardJumpCountForCompile = MinBackwardJumpCountForCompile /* ', MinBackwardJumpCountForCompile printString, ' */'.
	aCCodeGenerator removeVariable: 'atCache'. "Way too much trouble than it's worth in the Cog VM"
	aCCodeGenerator
		var: #primTraceLogIndex type: #'unsigned char';
		var: #primTraceLog declareC: 'sqInt primTraceLog[256]';
		var: #traceLog
		declareC: 'sqInt traceLog[TraceBufferSize /* ', TraceBufferSize printString, ' */]';
		var: #traceSources type: #'char *' array: TraceSources
]

{ #category : #'accessing class hierarchy' }
CoInterpreter class >> hasCogit [
	^true
]

{ #category : #initialization }
CoInterpreter class >> initializeCaches [
	"Eliminate the AtCache"
	super initializeCaches.
	AtCacheTotalSize := AtCacheSize := AtCacheMask := AtCacheFixedFields := AtCacheFmt := AtCacheOop := #undefined
]

{ #category : #initialization }
CoInterpreter class >> initializeContextIndices [
	super initializeContextIndices.

	HasBeenReturnedFromMCPC := -1.
	HasBeenReturnedFromMCPCOop := self objectMemoryClass basicNew integerObjectOf: HasBeenReturnedFromMCPC
]

{ #category : #initialization }
CoInterpreter class >> initializeFrameIndices [
	"Format of a stack frame.  Word-sized indices relative to the frame pointer.
	 Terminology
		Frames are either single (have no context) or married (have a context).
		Contexts are either single (exist on the heap), married (have a context) or widowed (had a frame that has exited).
	 Stacks grow down:

			receiver for method activations/closure for block activations
			arg0
			...
			argN
			caller's saved ip/this stackPage (for a base frame)
	fp->	saved fp
			method
			context (initialized to nil)
			frame flags (interpreter only)
			saved method ip (initialized to 0; interpreter only)
			receiver
			first temp
			...
	sp->	Nth temp

	In an interpreter frame
		frame flags holds
			the backward jump count (see ifBackwardsCheckForEvents)
			the number of arguments (since argument temporaries are above the frame)
			the flag for a block activation
			and the flag indicating if the context field is valid (whether the frame is married).
		saved method ip holds the saved method ip when the callee frame is a machine code frame.
		This is because the saved method ip is actually the ceReturnToInterpreterTrampoline address.
	In a machine code frame
		the flag indicating if the context is valid is the least significant bit of the method pointer
		the flag for a block activation is the next most significant bit of the method pointer

	Interpreter frames are distinguished from method frames by the method field which will
	be a pointer into the heap for an interpreter frame and a pointer into the method zone for
	a machine code frame.

	The first frame in a stack page is the baseFrame and is marked as such by a saved fp being its stackPage,
	in which case the first word on the stack is the caller context (possibly hybrid) beneath the base frame."

	| fxCallerSavedIP fxSavedFP fxMethod fxIFrameFlags fxThisContext fxIFReceiver fxMFReceiver fxIFSavedIP |
	fxCallerSavedIP := 1.
	fxSavedFP := 0.
	fxMethod := -1.
	fxThisContext := -2.
	fxIFrameFlags := -3.	"Can find numArgs, needed for fast temp access. args are above fxCallerSavedIP.
							 Can find ``is block'' bit
							 Can find ``has context'' bit"
	fxIFSavedIP := -4.
	fxIFReceiver := -5.
	fxMFReceiver := -3.

	"For debugging undefine values that differ in the StackInterpreter."
	FrameSlots := #undefined.
	IFrameSlots := fxCallerSavedIP - fxIFReceiver + 1.
	MFrameSlots := fxCallerSavedIP - fxMFReceiver + 1.

	FoxCallerSavedIP := fxCallerSavedIP * BytesPerWord.
	"In Cog a base frame's caller context is stored on the first word of the stack page."
	FoxCallerContext := #undefined.
	FoxSavedFP := fxSavedFP * BytesPerWord.
	FoxMethod := fxMethod * BytesPerWord.
	FoxThisContext := fxThisContext * BytesPerWord.
	FoxFrameFlags := #undefined.
	FoxIFrameFlags := fxIFrameFlags * BytesPerWord.
	FoxIFSavedIP := fxIFSavedIP * BytesPerWord.
	FoxReceiver := #undefined.
	FoxIFReceiver := fxIFReceiver * BytesPerWord.
	FoxMFReceiver := fxMFReceiver * BytesPerWord.

	"N.B.  There is room for one more flag given the current 8 byte alignment of methods (which
	 is at least needed to distinguish the checked and uncecked entry points by their alignment."
	MFMethodFlagHasContextFlag := 1.
	MFMethodFlagIsBlockFlag := 2.
	MFMethodFlagFrameIsMarkedFlag := 4. "for pathTo:using:followWeak:"
	MFMethodFlagsMask := MFMethodFlagHasContextFlag + MFMethodFlagIsBlockFlag + MFMethodFlagFrameIsMarkedFlag.
	MFMethodMask := (MFMethodFlagsMask + 1) negated
]

{ #category : #initialization }
CoInterpreter class >> initializeMiscConstants [

	super initializeMiscConstants.
	COGVM := true.

	MinBackwardJumpCountForCompile := 40.

	MaxNumArgs := 15.
	PrimCallNeedsNewMethod := 1.
	PrimCallNeedsPrimitiveFunction := 2.
	PrimCallMayCallBack := 4.
	PrimCallOnSmalltalkStack := 8.
	PrimCallCollectsProfileSamples := 16.
	CheckAllocationFillerAfterPrimCall := 32.
	PrimCallDoNotJIT := 64.

	PrimTraceLogSize := 256. "Room for 256 selectors.  Must be 256 because we use a byte to hold the index"
	TraceBufferSize := 256 * 3. "Room for 256 events"
	TraceContextSwitch := self objectMemoryClass basicNew integerObjectOf: 1.
	TraceBlockActivation := self objectMemoryClass basicNew integerObjectOf: 2.
	TraceBlockCreation := self objectMemoryClass basicNew integerObjectOf: 3.
	TraceIncrementalGC := self objectMemoryClass basicNew integerObjectOf: 4.
	TraceFullGC := self objectMemoryClass basicNew integerObjectOf: 5.
	TraceCodeCompaction := self objectMemoryClass basicNew integerObjectOf: 6.
	TraceOwnVM := self objectMemoryClass basicNew integerObjectOf: 7.
	TraceDisownVM := self objectMemoryClass basicNew integerObjectOf: 8.
	TraceThreadSwitch := self objectMemoryClass basicNew integerObjectOf: 9.
	TracePreemptDisowningThread := self objectMemoryClass basicNew integerObjectOf: 10.
	TraceVMCallback := self objectMemoryClass basicNew integerObjectOf: 11.
	TraceVMCallbackReturn := self objectMemoryClass basicNew integerObjectOf: 12.
	TraceStackOverflow := self objectMemoryClass basicNew integerObjectOf: 13.
	TracePrimitiveFailure := self objectMemoryClass basicNew integerObjectOf: 14.
	TracePrimitiveRetry := self objectMemoryClass basicNew integerObjectOf: 15.

	TraceIsFromMachineCode := 1.
	TraceIsFromInterpreter := 2.
	CSCallbackEnter := 3.
	CSCallbackLeave := 4.
	CSEnterCriticalSection := 5.
	CSExitCriticalSection := 6.
	CSResume := 7.
	CSSignal := 8.
	CSSuspend := 9.
	CSWait := 10.
	CSYield := 11.
	CSCheckEvents := 12.
	CSThreadSchedulingLoop := 13.
	CSOwnVM := 14.
	CSThreadBind := 15.
	CSSwitchIfNeccessary := 16.

	TraceSources := CArrayAccessor on: #('?' 'm' 'i' 'callbackEnter' 'callbackLeave' 'enterCritical' 'exitCritical' 'resume' 'signal'  'suspend' 'wait' 'yield' 'eventcheck' 'threadsched' 'ownVM' 'bindToThread' 'switchIfNecessary').

	"this is simulation only"
	RumpCStackSize := 4096
]

{ #category : #initialization }
CoInterpreter class >> initializePrimitiveTable [
	super initializePrimitiveTable.
	PrimNumberHashMultiply := 159.
	self assert: (PrimitiveTable at: PrimNumberHashMultiply + 1) = #primitiveHashMultiply.

	#(216 253) do:
		[:pidx| self assert: (PrimitiveTable at: pidx + 1) = #primitiveFail].
	self assert: (PrimitiveTable at: 215 + 1) = #primitiveFlushCacheByMethod.
	PrimitiveTable
		at: 253 + 1 put: #primitiveCollectCogCodeConstituents;
		at: 215 + 1 put: #primitiveVoidVMStateForMethod;
		at: 216 + 1 put: #primitiveMethodXray
]

{ #category : #documentation }
CoInterpreter class >> interpreterMachineCodeTransitions [
	"The CoInterpreter only asks the Cog compiler to generate machine-code methods
	 when a bytecoded method has been found in the cache, or block value has tried to
	 invoke a block in the method two times consecutively.  This prevents the compiler
	 being asked to compile an infrequenttly used method.

	I would like the following to be true, but it isn't.  The interpreter *does* invoke
	machine-code primitives that may context switch.

	 The CoInterpreter will only activate a Cog method that doesn't have a primitive
	 (this does not mean it won't invoke a Cog block method; it just does so through the
	 interpreted block value primitives).  This is to avoid serious complications with the
	 process switch primitives.  The CoInterpreter needs to know if it should push the
	 instructionPointer or save it in frameSavedIP and substitute ceReturtnToInterpreterPC
	 as the pushed instruction pointer.  The process switch primitives need to know if
	 they were called from the interpreter or from machine-code to know how to continue.

	 If a process switch primitive has been invoked from the interpreter and switches to
	 a process suspended in an interpreted method it can return to the interpreter.  In both
	 cases switching to a process in machine-code the primtiive can continue via the
	 ceEnterCogCodeXXX enilopmart(s).  But if in machine-code and switching to a process
	 in the interpreter it must longjmp to the interpreter.  So the process-switch primtiives
	 need to know whether they werer invoked from the interpreter or not.

	 If the process-switch primitives are allowed to be invoked from the interpreter via a
	 machine-code method then, in the immortal words of Robert Fripp, ``affairs stand a
	 good chance of getting severely out of hand...'' (The Guitar Handbook, Ralph Denyer,
	 p 114, Pan Books).  The VM now has to longjmp not only if invoked from machine code
	 and switching to the interpreter but if invoked from the interpreter via machine code
	 and switching to the interpreter.  The issue is that it is difficult to discover from within
	 a primitive whether the primitive call is from machine code, as it should be; it isn't a
	 concern of the primitive.  Hence KISS says ``no machine-code invocation of primitives
	 from the interpreter''."
]

{ #category : #accessing }
CoInterpreter class >> interpreterVersion [ 
	^ 'Cog'
]

{ #category : #translation }
CoInterpreter class >> isAcceptableAncilliaryClass: aClass [
	^aClass ~~ InterpreterStackPages
]

{ #category : #translation }
CoInterpreter class >> isNonArgumentImplicitReceiverVariableName: aString [
	^(#('self' 'stackPages' 'cogit' 'coInterpreter' 'cogMethodZone' 'interpreter' 'objectMemory') includes: aString)
	  or: [self objectMemoryClass isNonArgumentImplicitReceiverVariableName: aString]
]

{ #category : #testing }
CoInterpreter class >> isThreadedVM [
	^false
]

{ #category : #translation }
CoInterpreter class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^(super mustBeGlobal: var)
	   or: [#('desiredCogCodeSize' 'heapBase'
			'maxLiteralCountForCompile' 'minBackwardJumpCountForCompile') includes: var]
]

{ #category : #translation }
CoInterpreter class >> needsCogit [
	^true
]

{ #category : #translation }
CoInterpreter class >> preGenerationHook: aCCodeGenerator [
	"Override to undo the hiding of primitiveClosureValueNoContextSwitch"
	super preGenerationHook: aCCodeGenerator.
	(aCCodeGenerator methodNamed: #primitiveClosureValueNoContextSwitch) static: false.

	"horrible hack to declare primErrorCode and argumentCount as bytes in the same word, and
	 hence save an instruction by initializing two birds^H^H^H^H^Hbytes with one word write.
	 Stalled awaiting MoveAbR and MoveRAb support in the Cogit"
	false ifTrue:
		[aCCodeGenerator
			var: #argumentCount declareC: '#define argumentCount acpfc.ac\#define primFailCode acpfc.pfc' withCRs;
			var: #primFailCode declareC: '#if VMBIGENDIAN\struct { short pad; unsigned char pfc; unsigned char ac; } acpfc;\#else /* argumentCount & primFailCode */\struct { unsigned char ac; unsigned char pfc; } acpfc;\#endif' withCRs]
]

{ #category : #'accessing class hierarchy' }
CoInterpreter class >> primitivesClass [
	^CoInterpreterPrimitives
]

{ #category : #translation }
CoInterpreter class >> shouldGenerateTypedefFor: aStructClass [
	"Hack to work-around multiple definitions.  Sometimes a type has been defined in an include."
	^(super shouldGenerateTypedefFor: aStructClass)
	  and: [Cogit shouldGenerateTypedefFor: aStructClass]
]

{ #category : #translation }
CoInterpreter class >> sourceFileName [
	"Answer the filename for the core interpreter"

	^'cointerp.c'
]

{ #category : #translation }
CoInterpreter class >> specialValueForConstant: constantName default: defaultValue [
	constantName = 'DoAssertionChecks' ifTrue:
		[^'(!PRODUCTION)'].
	constantName = 'AllocationCheckFiller' ifTrue:
		[^('#if !defined(AllocationCheckFiller)\# define AllocationCheckFiller ', defaultValue, '\#endif') withCRs].
	^super specialValueForConstant: constantName default: defaultValue
]

{ #category : #translation }
CoInterpreter class >> writeVMHeaderTo: aStream bytesPerWord: bytesPerWord generator: aCCodeGenerator [
	super writeVMHeaderTo: aStream bytesPerWord: bytesPerWord generator: aCCodeGenerator.
	aCCodeGenerator
		putDefineOf: #COGVM as: 1 on: aStream;
		putConditionalDefineOf: #COGMTVM as: 0 comment: nil on: aStream.
	aStream cr
]

{ #category : #simulation }
CoInterpreter >> ISA [
	<doNotGenerate>
	^cogit backEnd class ISA
]

{ #category : #'cog jit support' }
CoInterpreter >> accessorDepthForPrimitiveIndex: primIndex [
	<api>
	<option: #SpurObjectMemory>
	^primitiveAccessorDepthTable at: primIndex
]

{ #category : #'message sending' }
CoInterpreter >> activateCoggedNewMethod: inInterpreter [
	"Activate newMethod when newMethod has been cogged, i.e. create a machine-code frame and (re)enter machine-code."
	| methodHeader cogMethod rcvr numTemps switched |
	<var: #cogMethod type: #'CogMethod *'>

	methodHeader := self rawHeaderOf: newMethod.
	self assert: (self isCogMethodReference: methodHeader).

	cogMethod := self cCoerceSimple: methodHeader to: #'CogMethod *'.
	methodHeader := cogMethod methodHeader.
	rcvr := self stackValue: cogMethod cmNumArgs. "could new rcvr be set at point of send?"
	self push: instructionPointer.
	cogMethod stackCheckOffset = 0 ifTrue:
		["frameless method; nothing to activate..."
		 cogit numRegArgs > 0 ifTrue: "dont use and: so as to get Slang to inline cogit numRegArgs > 0"
			[cogMethod cmNumArgs <= cogit numRegArgs ifTrue:
				[self callRegisterArgCogMethod: cogMethod at: cogit noCheckEntryOffset receiver: rcvr]].
		 self push: cogMethod asInteger + cogit noCheckEntryOffset.
		 self push: rcvr.
		 cogit ceCallCogCodePopReceiverReg.
		 self error: 'should not be reached'].
	self push: framePointer.
	framePointer := stackPointer.
	self push: cogMethod asInteger.
	self push: objectMemory nilObject. "FxThisContext field"
	self push: rcvr.

	"clear remaining temps to nil"
	numTemps := self temporaryCountOfMethodHeader: methodHeader.
	cogMethod cmNumArgs + 1 to: numTemps do:
		[:i | self push: objectMemory nilObject].

	((self methodHeaderHasPrimitive: methodHeader)
	 and: [primFailCode ~= 0]) ifTrue:
		[self reapAndResetErrorCodeTo: stackPointer header: methodHeader].

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)."
	stackPointer >= stackLimit ifTrue:
		[self assert: cogMethod stackCheckOffset > cogit noCheckEntryOffset.
		 self push: cogMethod asInteger + cogMethod stackCheckOffset.
		 self push: rcvr.
		 cogit ceEnterCogCodePopReceiverReg.
		 self error: 'should not be reached'].
	instructionPointer := cogMethod asInteger + cogMethod stackCheckOffset.
	switched := self handleStackOverflowOrEventAllowContextSwitch: (self canContextSwitchIfActivating: newMethod header: methodHeader).
	self returnToExecutive: inInterpreter postContextSwitch: switched
]

{ #category : #'control primitives' }
CoInterpreter >> activateNewClosure: blockClosure outer: outerContext method: theMethod  numArgs: numArgs mayContextSwitch: mayContextSwitch [
	"Similar to activateNewMethod but for Closure and newMethod.
	 Override to handle the various interpreter/machine code transitions
	 and to create an appropriate frame layout."
	| numCopied methodHeader inInterpreter closureIP switched |
	<inline: true>
	self assert: (objectMemory isContext: outerContext).
	numCopied := self copiedValueCountOfClosure: blockClosure.
	self assert: theMethod = (objectMemory fetchPointer: MethodIndex ofObject: outerContext).
	self assert: (objectMemory isOopCompiledMethod: theMethod).
	methodHeader := self rawHeaderOf: theMethod.
	(self isCogMethodReference: methodHeader) ifTrue:
		[^self executeCogBlock: (self cogMethodOf: theMethod)
			closure: blockClosure
			mayContextSwitch: mayContextSwitch].
	"How do we know when to compile a block method?
	 One simple criterion is to check if the block is running within its inner context,
	 i.e. if the outerContext is married.
	 Even simpler is to remember the previous block entered via the interpreter and
	 compile if this is the same one.  But we can thrash trying to compile an uncoggable
	 method unless we try and remember which ones can't be cogged.  So also record
	 the last block method we failed to compile and avoid recompiling it."
	(self methodWithHeaderShouldBeCogged: methodHeader)
		ifTrue:
			[(instructionPointer < objectMemory startOfMemory "If from machine code (via value primitive) attempt jitting"
			  or: [theMethod = lastCoggableInterpretedBlockMethod]) "If from interpreter and repeat block, attempt jitting"
				ifTrue:
					[theMethod ~= lastUncoggableInterpretedBlockMethod ifTrue:
						[cogit cog: theMethod selector: objectMemory nilObject.
						 (self methodHasCogMethod: theMethod) ifTrue:
							[^self executeCogBlock: (self cogMethodOf: theMethod)
								closure: blockClosure
								mayContextSwitch: mayContextSwitch].
						 cogCompiledCodeCompactionCalledFor ifFalse:
							[lastUncoggableInterpretedBlockMethod := theMethod]]]
				ifFalse:
					[lastCoggableInterpretedBlockMethod := theMethod]]
		ifFalse:
			[self maybeFlagMethodAsInterpreted: theMethod].

	self assert: (self methodHasCogMethod: theMethod) not.
	"Because this is an uncogged method we need to continue via the interpreter.
	 We could have been reached either from the interpreter, in which case we
	 should simply return, or from a machine code frame or from a compiled
	 primitive.  In these latter two cases we must longjmp back to the interpreter.
	 The instructionPointer tells us which path we took.
	 If the sender was an interpreter frame but called through a (failing) primitive
	 then make sure we restore the saved instruction pointer and avoid pushing
	 ceReturnToInterpreterPC which is only valid between an interpreter caller
	 frame and a machine code callee frame."
	(inInterpreter := instructionPointer >= objectMemory startOfMemory) ifFalse:
		[instructionPointer = cogit ceReturnToInterpreterPC ifTrue:
			[instructionPointer := self iframeSavedIP: framePointer]].
	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: theMethod.
	self push: objectMemory nilObject. "FxThisContext field"
	self push: (self encodeFrameFieldHasContext: false isBlock: true numArgs: numArgs).
	self push: 0. "FoxIFSavedIP"
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
	self setMethod: theMethod methodHeader: methodHeader.

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)"
	switched := false.
	stackPointer < stackLimit ifTrue:
		[switched := self handleStackOverflowOrEventAllowContextSwitch: mayContextSwitch].
	self returnToExecutive: inInterpreter postContextSwitch: switched
]

{ #category : #'control primitives' }
CoInterpreter >> activateNewFullClosure: blockClosure method: theMethod numArgs: numArgs mayContextSwitch: mayContextSwitch [
	"Similar to activateNewMethod but for Closure and newMethod."
	| numCopied methodHeader numTemps inInterpreter switched |
	<inline: true>
	self assert: theMethod = (objectMemory fetchPointer: FullClosureCompiledBlockIndex ofObject: blockClosure).
	methodHeader := self rawHeaderOf: theMethod.
	(self isCogMethodReference: methodHeader) ifTrue:
		[^self
			executeFullCogBlock: (self cogMethodOf: theMethod)
			closure: blockClosure
			mayContextSwitch: mayContextSwitch].
	numCopied := self copiedValueCountOfFullClosure: blockClosure.
	"How do we know when to compile a block method?
	 One simple criterion is to check if the block is running within its inner context,
	 i.e. if the outerContext is married.
	 Even simpler is to remember the previous block entered via the interpreter and
	 compile if this is the same one.  But we can thrash trying to compile an uncoggable
	 method unless we try and remember which ones can't be cogged.  So also record
	 the last block method we failed to compile and avoid recompiling it."
	(self methodWithHeaderShouldBeCogged: methodHeader)
		ifTrue:
			[(instructionPointer < objectMemory startOfMemory "If from machine code (via value primitive) attempt jitting"
			  or: [theMethod = lastCoggableInterpretedBlockMethod]) "If from interpreter and repeat block, attempt jitting"
				ifTrue:
					[theMethod ~= lastUncoggableInterpretedBlockMethod ifTrue:
						[cogit cogFullBlockMethod: theMethod numCopied: numCopied.
						 (self methodHasCogMethod: theMethod) ifTrue:
							[^self executeFullCogBlock: (self cogMethodOf: theMethod)
								closure: blockClosure
								mayContextSwitch: mayContextSwitch].
						 cogCompiledCodeCompactionCalledFor ifFalse:
							[lastUncoggableInterpretedBlockMethod := theMethod]]]
				ifFalse:
					[lastCoggableInterpretedBlockMethod := theMethod]]
		ifFalse:
			[self maybeFlagMethodAsInterpreted: theMethod].

	self assert: (self methodHasCogMethod: theMethod) not.
	"Because this is an uncogged method we need to continue via the interpreter.
	 We could have been reached either from the interpreter, in which case we
	 should simply return, or from a machine code frame or from a compiled
	 primitive.  In these latter two cases we must longjmp back to the interpreter.
	 The instructionPointer tells us which path we took.
	 If the sender was an interpreter frame but called through a (failing) primitive
	 then make sure we restore the saved instruction pointer and avoid pushing
	 ceReturnToInterpreterPC which is only valid between an interpreter caller
	 frame and a machine code callee frame."
	(inInterpreter := instructionPointer >= objectMemory startOfMemory) ifFalse:
		[instructionPointer = cogit ceReturnToInterpreterPC ifTrue:
			[instructionPointer := self iframeSavedIP: framePointer]].

	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: theMethod.
	self push: objectMemory nilObject. "FxThisContext field"
	self push: (self encodeFrameFieldHasContext: false isBlock: true numArgs: numArgs).
	self push: 0. "FoxIFSavedIP"
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
	switched := false.
	stackPointer < stackLimit ifTrue:
		[switched := self handleStackOverflowOrEventAllowContextSwitch: mayContextSwitch].
	self returnToExecutive: inInterpreter postContextSwitch: switched
]

{ #category : #'message sending' }
CoInterpreter >> activateNewMethod [
	| methodHeader numArgs numTemps rcvr inInterpreter switched |

	methodHeader := objectMemory methodHeaderOf: newMethod.
	numTemps := self temporaryCountOfMethodHeader: methodHeader.
	numArgs := self argumentCountOfMethodHeader: methodHeader.

	rcvr := self stackValue: numArgs. "could new rcvr be set at point of send?"
	self assert: (objectMemory isOopForwarded: rcvr) not.

	"Because this is an uncogged method we need to continue via the interpreter.
	 We could have been reached either from the interpreter, in which case we
	 should simply return, or from a machine code frame or from a compiled
	 primitive.  In these latter two cases we must longjmp back to the interpreter.
	 The instructionPointer tells us which path we took.
	 If the sender was an interpreter frame but called through a (failing) primitive
	 then make sure we restore the saved instruction pointer and avoid pushing
	 ceReturnToInterpreterPC which is only valid between an interpreter caller
	 frame and a machine code callee frame."
	(inInterpreter := instructionPointer >= objectMemory startOfMemory) ifFalse:
		[instructionPointer = cogit ceReturnToInterpreterPC ifTrue:
			[instructionPointer := self iframeSavedIP: framePointer]].
	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: newMethod.
	self setMethod: newMethod methodHeader: methodHeader.
	self push: objectMemory nilObject. "FxThisContext field"
	self push: (self encodeFrameFieldHasContext: false isBlock: false numArgs: numArgs).
	self push: 0. "FoxIFSavedIP"
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

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)."
	switched := true.
	stackPointer < stackLimit ifTrue:
		[switched := self handleStackOverflowOrEventAllowContextSwitch:
							(self canContextSwitchIfActivating: newMethod header: methodHeader)].
	self returnToExecutive: inInterpreter postContextSwitch: switched
]

{ #category : #'method lookup cache' }
CoInterpreter >> addNewMethodToCache: classObj [
	"Override to refuse to cache other than compiled methods.
	 This protects open PICs against having to test for compiled methods."
	(objectMemory isOopCompiledMethod: newMethod) ifFalse:
		[primitiveFunctionPointer := #primitiveInvokeObjectAsMethod.
		^self].
	super addNewMethodToCache: classObj
]

{ #category : #'cog jit support' }
CoInterpreter >> argumentCount [
	<doNotGenerate>
	^argumentCount
]

{ #category : #'cog jit support' }
CoInterpreter >> argumentCount: numArgs [
	<doNotGenerate>
	argumentCount := numArgs
]

{ #category : #'trampoline support' }
CoInterpreter >> argumentCountAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: argumentCount) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #argumentCount in: self]
]

{ #category : #'frame access' }
CoInterpreter >> asCogHomeMethod: aCogMethod [
	"Coerce either a CMMethod or a CMBlock to the home CMMethod"
	<var: #aCogMethod type: #'CogBlockMethod *'>
	<returnTypeC: #'CogMethod *'>
	^aCogMethod cmType = CMMethod
		ifTrue: [self cCoerceSimple: aCogMethod to: #'CogMethod *']
		ifFalse: [aCogMethod cmHomeMethod]
]

{ #category : #'debug support' }
CoInterpreter >> assertValidExecutionPointe: lip r: lifp s: lisp imbar: inInterpreter line: ln [
	<var: #lip type: #usqInt>
	<var: #lifp type: #'char *'>
	<var: #lisp type: #'char *'>
	| methodField cogMethod theIP  |
	<var: #cogMethod type: #'CogMethod *'>
	self assert: stackPage = stackPages mostRecentlyUsedPage l: ln.
	self assert: (stackPage addressIsInPage: lifp) l: ln.
	self assert: (self deferStackLimitSmashAround: #assertValidStackLimits: asSymbol with: ln).
	self assert: lisp < lifp l: ln.
	self assert: lifp > lisp l: ln.
	self assert: lisp >= (stackPage realStackLimit - self stackLimitOffset) l: ln.
	self assert: (lifp - lisp) / objectMemory bytesPerOop < LargeContextSlots l: ln.
	methodField := self frameMethodField: lifp.
	inInterpreter
		ifTrue:
			[self assert: (self isMachineCodeFrame: lifp) not l: ln.
			 self assert: method = methodField l: ln.
			 self cppIf: MULTIPLEBYTECODESETS
				ifTrue: [self assert: (self methodUsesAlternateBytecodeSet: method) = (bytecodeSetSelector = 256) l: ln].
			 (self asserta: (objectMemory cheapAddressCouldBeInHeap: methodField) l: ln) ifTrue:
				[theIP := lip = cogit ceReturnToInterpreterPC
							ifTrue: [self iframeSavedIP: lifp]
							ifFalse: [lip].
				 self assert: (theIP >= (methodField + (objectMemory lastPointerOf: methodField))
							  and: [theIP <= (methodField + (objectMemory numBytesOfBytes: methodField) + objectMemory baseHeaderSize - 1)])
					l: ln].
			 self assert: ((self iframeIsBlockActivation: lifp)
					or: [(self pushedReceiverOrClosureOfFrame: lifp) = (self iframeReceiver: lifp)])
				l: ln]
		ifFalse:
			[self assert: (self isMachineCodeFrame: lifp) l: ln.
			 ((self asserta: methodField asUnsignedInteger >= cogit minCogMethodAddress l: ln)
			  and: [self asserta: methodField asUnsignedInteger < cogit maxCogMethodAddress l: ln]) ifTrue:
				[cogMethod := self mframeHomeMethod: lifp.
				 self assert: (lip > (methodField + ((self mframeIsBlockActivation: lifp)
													ifTrue: [self sizeof: CogBlockMethod]
													ifFalse: [self sizeof: CogMethod]))
						and: [lip < (methodField + cogMethod blockSize)])
					l: ln].
			 self assert: ((self mframeIsBlockActivation: lifp)
					or: [(self pushedReceiverOrClosureOfFrame: lifp) = (self mframeReceiver: lifp)])
				l: ln].
	(self isBaseFrame: lifp) ifTrue:
		[self assert: (self frameHasContext: lifp) l: ln.
		 self assert: (self frameContext: lifp) = (stackPages longAt: stackPage baseAddress - objectMemory wordSize) l: ln]
]

{ #category : #'debug support' }
CoInterpreter >> assertValidExternalStackPointers [
	self assert: framePointer < stackPage baseAddress.
	self assert: stackPointer < framePointer.
	self assert: framePointer > stackPointer.
	self assert: stackPointer >= (stackPage realStackLimit - self stackLimitOffset)
]

{ #category : #'cog jit support' }
CoInterpreter >> assertValidMachineCodeFrame: instrPtr [
	<api>
	| cogMethod homeMethod |
	<var: #cogMethod type: #'CogBlockMethod *'>
	<var: #homeMethod type: #'CogMethod *'>
	self assert: (self isMachineCodeFrame: framePointer).
	cogMethod := self mframeCogMethod: framePointer.
	homeMethod := self asCogHomeMethod: cogMethod.
	self assert: (cogMethodZone methodFor: cogMethod) = homeMethod.
	self assert: (instrPtr > cogMethod asInteger
				and: [instrPtr < (homeMethod asInteger + homeMethod blockSize)])
]

{ #category : #'debug support' }
CoInterpreter >> assertValidStackPageHeadPointers [
	self assert: stackPage headFP < stackPage baseAddress.
	self assert: stackPage headSP < stackPage headFP.
	self assert: stackPage headFP > stackPage headSP.
	self assert: stackPage headSP >= (stackPage realStackLimit - self stackLimitOffset)
]

{ #category : #'debug support' }
CoInterpreter >> assertValidStackedInstructionPointers: ln [
	"Check that the stacked instruction pointers in all pages are correct.
	 Checks the interpreter sender/machine code callee contract.
	 Written so it will be optimized away if not in an assert VM."
	| thePage |
	<inline: false>
	<var: #thePage type: #'StackPage *'>
	0 to: numStackPages - 1 do:
		[:i|
		thePage := stackPages stackPageAt: i.
		(stackPages isFree: thePage) ifFalse:
			[self assert: (self assertValidStackedInstructionPointersIn: thePage line: ln) l: ln]]
]

{ #category : #'debug support' }
CoInterpreter >> assertValidStackedInstructionPointersIn: aStackPage line: ln [
	"Check that the stacked instruction pointers in the given page are correct.
	 Checks the interpreter sender/machine code callee contract."
	<var: #aStackPage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #theIP type: #usqInt>
	<var: #theMethod type: #'CogMethod *'>
	<inline: false>
	| prevFrameWasCogged theFP callerFP theMethod theIP methodObj |
	(self asserta: (stackPages isFree: aStackPage) not l: ln) ifFalse:
		[^false].
	prevFrameWasCogged := false.
	"The top of stack of an inactive page is always the instructionPointer.
	 The top of stack of the active page may be the instructionPointer if it has been pushed,
	 which is indicated by a 0 instructionPointer."
	(stackPage = aStackPage and: [instructionPointer ~= 0])
		ifTrue:
			[theIP := instructionPointer.
			theFP := framePointer]
		ifFalse:
			[theIP := (stackPages longAt: aStackPage headSP) asUnsignedInteger.
			 theFP := aStackPage headFP.
			 stackPage = aStackPage ifTrue:
				[self assert: framePointer = theFP l: ln]].
	[(self isMachineCodeFrame: theFP)
		ifTrue:
			[theMethod := self mframeHomeMethod: theFP.
			 self assert: (theIP = cogit ceCannotResumePC
						  or: [theIP >= theMethod asUnsignedInteger
							   and: [theIP < (theMethod asUnsignedInteger + theMethod blockSize)]])
					l: ln.
			prevFrameWasCogged := true]
		ifFalse: "assert-check the interpreter frame."
			[methodObj := self iframeMethod: theFP.
			 prevFrameWasCogged ifTrue:
				[self assert: theIP = cogit ceReturnToInterpreterPC l: ln].
			 theIP = cogit ceReturnToInterpreterPC ifTrue:
				[theIP := self iframeSavedIP: theFP].
			 self assert: (theIP >= (methodObj + (objectMemory lastPointerOf: methodObj))
						  and: [theIP < (methodObj + (objectMemory numBytesOfBytes: methodObj) + objectMemory baseHeaderSize - 1)])
				l: ln.
			 prevFrameWasCogged := false].
	 theIP := (stackPages longAt: theFP + FoxCallerSavedIP) asUnsignedInteger.
	 (callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
		[theFP := callerFP].
	self assert: theIP = cogit ceBaseFrameReturnPC l: ln.
	^true
]

{ #category : #'jump bytecodes' }
CoInterpreter >> attemptToSwitchToMachineCode: bcpc [
	"Attempt to convert the current interpreted activation into a machine code
	 activation, and if this is popssible, jump into machine code.  bcpc is the
	 0-relative pc of the backward branch bytecode (not any preceding extension)."
	| cogMethod pc cls |
	<inline: false>
	<var: #cogMethod type: #'CogMethod *'>
	(self methodHasCogMethod: method)
		ifFalse: 
			[SistaV1BytecodeSet
				ifTrue: 
					[ ((self iframeIsBlockActivation: framePointer) 
					   and: [(self isVanillaBlockClosure: (cls := self frameStackedReceiver: framePointer numArgs: (self frameNumArgs: framePointer))) not ])
						ifTrue: 
							["Compiled block / full closure"
							 cogit cogFullBlockMethod: method numCopied: (objectMemory numPointerSlotsOf: cls) - FullClosureFirstCopiedValueIndex]
						ifFalse: 
							["Compiled method"
							cogit cog: method selector: objectMemory nilObject] ]
				ifFalse: 
					[cogit cog: method selector: objectMemory nilObject] ].
	(self methodHasCogMethod: method) ifTrue:
		[cogMethod := self cogMethodOf: method.
		 pc := self convertToMachineCodeFrame: cogMethod bcpc: bcpc.
		 self assertValidMachineCodeFrame: pc.
		 self push: pc.
		 self push: objectMemory nilObject.
		 cogit ceEnterCogCodePopReceiverReg]
]

{ #category : #'return bytecodes' }
CoInterpreter >> baseFrameReturn [
	"Return from a baseFrame (the bottom frame in a stackPage).  The context to
	 return to (which may be married) is stored in the first word of the stack."
	<inline: true>
	| contextToReturnTo retToContext theFP theSP thePage newPage frameAbove |
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #newPage type: #'StackPage *'>
	<var: #frameAbove type: #'char *'>
	contextToReturnTo := self frameCallerContext: localFP.

	"The stack page is effectively free now, so free it.  We must free it to be
	 correct in determining if contextToReturnTo is still married, and in case
	 makeBaseFrameFor: cogs a method, which may cause a code compaction,
	 in which case the frame must be free to avoid the relocation machinery
	 tracing the dead frame.  Since freeing now temporarily violates the page-list
	 ordering invariant, use the assert-free version."
	stackPages freeStackPageNoAssert: stackPage.
	retToContext := objectMemory isContext: contextToReturnTo.
	(retToContext
	 and: [self isStillMarriedContext: contextToReturnTo])
		ifTrue:
			[theFP := self frameOfMarriedContext: contextToReturnTo.
			 thePage := stackPages stackPageFor: theFP.
			 theFP = thePage headFP
				ifTrue:
					[theSP := thePage headSP]
				ifFalse:
					["Returning to some interior frame, presumably because of a sender assignment.
					  Move the frames above to another page (they may be in use, e.g. via coroutining).
					  Make the interior frame the top frame."
					 frameAbove := self findFrameAbove: theFP inPage: thePage.
					 "Since we've just deallocated a page we know that newStackPage won't deallocate an existing one."
					 newPage := stackPages newStackPage.
					 self assert: newPage = stackPage.
					 self moveFramesIn: thePage through: frameAbove toPage: newPage.
					 stackPages markStackPageMostRecentlyUsed: newPage.
					 theFP := thePage headFP.
					 theSP := thePage headSP]]
		ifFalse:
			[(retToContext
			  and: [objectMemory isIntegerObject: (objectMemory fetchPointer: InstructionPointerIndex ofObject: contextToReturnTo)]) ifFalse:
				[| contextToReturnFrom |
				 contextToReturnFrom := stackPages longAt: stackPage baseAddress - objectMemory wordSize.
				 self tearDownAndRebuildFrameForCannotReturnBaseFrameReturnFrom: contextToReturnFrom
					to: contextToReturnTo
					returnValue: localReturnValue.
				^self externalCannotReturn: localReturnValue from: contextToReturnFrom].
			 "We must void the instructionPointer to stop it being updated if makeBaseFrameFor:
			  cogs a method, which may cause a code compaction."
			 instructionPointer := 0.
			 thePage := self makeBaseFrameFor: contextToReturnTo.
			 theFP := thePage headFP.
			 theSP := thePage headSP].
	self setStackPageAndLimit: thePage.
	self assert: (stackPages stackPageFor: theFP) = stackPage.
	localSP := theSP.
	localFP := theFP.
	localIP := self pointerForOop: self internalStackTop.
	localIP asUnsignedInteger < objectMemory startOfMemory ifTrue:
		[localIP asUnsignedInteger ~= cogit ceReturnToInterpreterPC ifTrue:
			["localIP in the cog method zone indicates a return to machine code."
			 ^self returnToMachineCodeFrame].
		 localIP := self pointerForOop: (self iframeSavedIP: localFP)].
	self assert: (self checkIsStillMarriedContext: contextToReturnTo currentFP: localFP).
	self setMethod: (self iframeMethod: localFP).
	self internalStackTopPut: localReturnValue.
	^self fetchNextBytecode
]

{ #category : #'frame access' }
CoInterpreter >> bytecodePCFor: theIP cogMethod: cogMethod startBcpc: startBcpc [
	"Answer the mapping of the native pc theIP to a zero-relative bytecode pc.
	 See contextInstructionPointer:frame: for the explanation."
	<var: #cogMethod type: #'CogMethod *'>
	| cogMethodForIP mcpc |
	<inline: true>
	<var: #cogMethodForIP type: #'CogBlockMethod *'>
	self assert: theIP < 0.
	(theIP signedBitShift: -16) < -1 "See contextInstructionPointer:frame:"
		ifTrue:
			[cogMethodForIP := self cCoerceSimple: cogMethod asInteger - ((theIP signedBitShift: -16) * cogit blockAlignment)
									to: #'CogBlockMethod *'.
			 self assert: cogMethodForIP cmType = CMBlock.
			 self assert: cogMethodForIP cmHomeMethod = cogMethod.
			 mcpc := cogMethodForIP asInteger - theIP signedIntFromShort]
		ifFalse:
			[cogMethodForIP := self cCoerceSimple: cogMethod to: #'CogBlockMethod *'.
			 self assert: cogMethodForIP cmType = CMMethod.
			 mcpc := cogMethod asInteger - theIP.
			 "map any pcs in primitive code (i.e. return addresses for interpreter primitive calls) to the initial pc"
			 mcpc asUnsignedInteger < cogMethod stackCheckOffset ifTrue:
				[^startBcpc]].
	self assert: (mcpc between: cogMethod asInteger and: cogMethod asInteger + cogMethod blockSize).
	^cogit bytecodePCFor: mcpc startBcpc: startBcpc in: cogMethodForIP
]

{ #category : #'common selector sends' }
CoInterpreter >> bytecodePrimAt [
	"Override to eliminate the atCache, something of little benefit to the JIT."
	messageSelector := self specialSelector: 16.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
CoInterpreter >> bytecodePrimAtPut [
	"Override to eliminate the atCache, something of little benefit to the JIT."
	messageSelector := self specialSelector: 17.
	argumentCount := 2.
	self normalSend
]

{ #category : #'cog jit support' }
CoInterpreter >> callForCogCompiledCodeCompaction [
	<api>
	cogCompiledCodeCompactionCalledFor := true.
	self forceInterruptCheck
]

{ #category : #enilopmarts }
CoInterpreter >> callRegisterArgCogMethod: cogMethod at: entryOffset receiver: rcvr [
	"convert
	 		rcvr	base
			arg(s)
			retpc	<- sp
	 to
			retpc	base
			entrypc
			rcvr
			arg(s)	<- sp
	 and then enter at either the checked or the unchecked entry-point."
	<option: #StackToRegisterMappingCogit>
	<var: #cogMethod type: #'CogMethod *'>
	self assert: (cogit numRegArgs > 0 and: [cogit numRegArgs <= 2 and: [cogMethod cmNumArgs <= cogit numRegArgs]]).
	cogMethod cmNumArgs = 2 ifTrue:
		[self stackValue: 3 put: self stackTop. "retpc"
		 self push: (self stackValue: 1). "last arg"
		 self stackValue: 1 put: (self stackValue: 3). "first arg"
		 self stackValue: 2 put: rcvr.
		 self stackValue: 3 put: cogMethod asInteger + entryOffset.
		 cogit ceCallCogCodePopReceiverArg1Arg0Regs
		"NOTREACHED"].
	cogMethod cmNumArgs = 1 ifTrue:
		[self stackValue: 2 put: self stackTop. "retpc"
		 self push: (self stackValue: 1). "arg"
		 self stackValue: 1 put: rcvr.
		 self stackValue: 2 put: cogMethod asInteger + entryOffset.
		 cogit ceCallCogCodePopReceiverArg0Regs
		"NOTREACHED"].
	self assert: cogMethod cmNumArgs = 0.
	self stackValue: 1 put: self stackTop. "retpc"
	self stackValue: 0 put: cogMethod asInteger + entryOffset.
	self push: rcvr.
	cogit ceCallCogCodePopReceiverReg
	"NOTREACHED"
]

{ #category : #'callback support' }
CoInterpreter >> callbackEnter: callbackID [
	"Re-enter the interpreter for executing a callback"
	| currentCStackPointer currentCFramePointer savedReenterInterpreter
	  wasInMachineCode calledFromMachineCode |
	<volatile>
	<export: true>
	<var: #currentCStackPointer type: #'void *'>
	<var: #currentCFramePointer type: #'void *'>
	<var: #callbackID type: #'sqInt *'>
	<var: #savedReenterInterpreter type: #'jmp_buf'>

	"For now, do not allow a callback unless we're in a primitiveResponse"
	(self asserta: primitiveFunctionPointer ~= 0) ifFalse:
		[^false].

	self assert: primFailCode = 0.

	"Check if we've exceeded the callback depth"
	(self asserta: jmpDepth < MaxJumpBuf) ifFalse:
		[^false].
	jmpDepth := jmpDepth + 1.

	wasInMachineCode := self isMachineCodeFrame: framePointer.
	calledFromMachineCode := instructionPointer <= objectMemory startOfMemory.

	"Suspend the currently active process"
	suspendedCallbacks at: jmpDepth put: self activeProcess.
	"We need to preserve newMethod explicitly since it is not activated yet
	and therefore no context has been created for it. If the caller primitive
	for any reason decides to fail we need to make sure we execute the correct
	method and not the one 'last used' in the call back"
	suspendedMethods at: jmpDepth put: newMethod.
	self flag: 'need to debug this properly.  Conceptually it is the right thing to do but it crashes in practice'.
	false
		ifTrue:
			["Signal external semaphores since a signalSemaphoreWithIndex: request may
			  have been issued immediately prior to this callback before the VM has any
			  chance to do a signalExternalSemaphores in checkForEventsMayContextSwitch:"
			 self signalExternalSemaphores.
			 "If no process is awakened by signalExternalSemaphores then transfer
			  to the highest priority runnable one."
			 (suspendedCallbacks at: jmpDepth) = self activeProcess ifTrue:
				[self transferTo: self wakeHighestPriority from: CSCallbackLeave]]
		ifFalse:
			[self transferTo: self wakeHighestPriority from: CSCallbackLeave].

	"Typically, invoking the callback means that some semaphore has been 
	signaled to indicate the callback. Force an interrupt check as soon as possible."
	self forceInterruptCheck.

	"Save the previous CStackPointers and interpreter entry jmp_buf."
	currentCStackPointer := cogit getCStackPointer.
	currentCFramePointer := cogit getCFramePointer.
	self memcpy: savedReenterInterpreter asVoidPointer
		_: reenterInterpreter
		_: (self sizeof: #'jmp_buf').
	cogit assertCStackWellAligned.
	(self setjmp: (jmpBuf at: jmpDepth)) = 0 ifTrue: "Fill in callbackID"
		[callbackID at: 0 put: jmpDepth.
		 self enterSmalltalkExecutive.
		 self assert: false "NOTREACHED"].

	"Restore the previous CStackPointers and interpreter entry jmp_buf."
	cogit setCStackPointer: currentCStackPointer.
	cogit setCFramePointer: currentCFramePointer.
	self memcpy: reenterInterpreter
		_: (self cCoerceSimple: savedReenterInterpreter to: #'void *')
		_: (self sizeof: #'jmp_buf').

	"Transfer back to the previous process so that caller can push result"
	self putToSleep: self activeProcess yieldingIf: preemptionYields.
	self transferTo: (suspendedCallbacks at: jmpDepth) from: CSCallbackLeave.
	newMethod := suspendedMethods at: jmpDepth.	"see comment above"
	argumentCount := self argumentCountOf: newMethod.
	self assert: wasInMachineCode = (self isMachineCodeFrame: framePointer).
	calledFromMachineCode
		ifTrue:
			[instructionPointer asUnsignedInteger >= objectMemory startOfMemory ifTrue:
				[self iframeSavedIP: framePointer put: instructionPointer.
				 instructionPointer := cogit ceReturnToInterpreterPC]]
		ifFalse:
			["Even if the context was flushed to the heap and rebuilt in transferTo:from:
			  above it will remain an interpreted frame because the context's pc would
			  remain a bytecode pc.  So the instructionPointer must also be a bytecode pc."
			 self assert: (self isMachineCodeFrame: framePointer) not.
			 self assert: instructionPointer > objectMemory startOfMemory].
	self assert: primFailCode = 0.
	jmpDepth := jmpDepth-1.
	^true
]

{ #category : #enilopmarts }
CoInterpreter >> ceActivateFailingPrimitiveMethod: aPrimitiveMethod [
	"An external call or FFI primitive has failed.  Build the frame and
	 activate as appropriate.  Enter either the interpreter or machine
	 code depending on whether aPrimitiveMethod has been or is still
	 cogged.  Note that we could always interpret but want the efficiency
	 of executing machine code if it is available."
	<api>
	| methodHeader result |
	self assert: primFailCode ~= 0.
	self assert: newMethod = aPrimitiveMethod.
	"If we're on Spur, retry the primitive, if appropriate,
	 returning if successful after retry."
	objectMemory hasSpurMemoryManagerAPI ifTrue:
		[self retryPrimitiveOnFailure.
		 self successful ifTrue:
			[result := self stackTop.
			 self stackTopPut: instructionPointer.
			 self push: result.
			 cogit ceEnterCogCodePopReceiverReg]].
	methodHeader := self rawHeaderOf: aPrimitiveMethod.
	(self isCogMethodReference: methodHeader)
		ifTrue: [self activateCoggedNewMethod: false]
		ifFalse: [self activateNewMethod]
]

{ #category : #trampolines }
CoInterpreter >> ceBaseFrameReturn: returnValue [
	"Return across a page boundary.  The context to return to (which may be married)
	 is stored in the first word of the stack.  We get here when a return instruction jumps
	 to the ceBaseFrameReturn: address that is the return pc for base frames.  A consequence
	 of this is that the current frame is no longer valid since an interrupt may have overwritten
	 its state as soon as the stack pointer has been cut-back beyond the return pc.  So to have
	 a context to send the cannotReturn: message to we also store the base frame's context
	 in the second word of the stack page."
	<api>
	| contextToReturnTo contextToReturnFrom isAContext thePage newPage frameAbove |
	<var: #thePage type: #'StackPage *'>
	<var: #newPage type: #'StackPage *'>
	<var: #frameAbove type: #'char *'>
	self assert: (stackPages stackPageFor: stackPointer) = stackPage.
	self assert: stackPages mostRecentlyUsedPage = stackPage.
	cogit assertCStackWellAligned.
	self assert: framePointer = 0.
	self assert: stackPointer <= (stackPage baseAddress - objectMemory wordSize).
	self assert: stackPage baseFP + (2 * objectMemory wordSize) < stackPage baseAddress.
	"We would like to use the following assert but we can't since the stack pointer will be above the
	 base frame pointer in the base frame return and hence the 0 a base frame pointer points at could
	 be overwritten which will cause the isBaseFrame assert in frameCallerContext: to fail."
	"self assert: (self frameCallerContext: stackPage baseFP) = (stackPages longAt: stackPage baseAddress)."
	self assert: ((objectMemory addressCouldBeObj: (stackPages longAt: stackPage baseAddress - objectMemory wordSize))
				and: [objectMemory isContext: (stackPages longAt: stackPage baseAddress - objectMemory wordSize)]).
	contextToReturnTo := stackPages longAt: stackPage baseAddress.
	self assert: (objectMemory addressCouldBeObj: contextToReturnTo).

	"The stack page is effectively free now, so free it.  We must free it to be
	 correct in determining if contextToReturnTo is still married, and in case
	 makeBaseFrameFor: cogs a method, which may cause a code compaction,
	 in which case the frame must be free to avoid the relocation machinery
	 tracing the dead frame.  Since freeing now temporarily violates the page-list
	 ordering invariant, use the assert-free version."
	stackPages freeStackPageNoAssert: stackPage.
	isAContext := objectMemory isContext: contextToReturnTo.
	(isAContext
	 and: [self isStillMarriedContext: contextToReturnTo])
		ifTrue:
			[framePointer := self frameOfMarriedContext: contextToReturnTo.
			 thePage := stackPages stackPageFor: framePointer.
			 framePointer = thePage headFP
				ifTrue:
					[stackPointer := thePage headSP]
				ifFalse:
					["Returning to some interior frame, presumably because of a sender assignment.
					  Move the frames above to another page (they may be in use, e.g. via coroutining).
					  Make the interior frame the top frame."
					 frameAbove := self findFrameAbove: framePointer inPage: thePage.
					 "Since we've just deallocated a page we know that newStackPage won't deallocate an existing one."
					 newPage := stackPages newStackPage.
					 self assert: newPage = stackPage.
					 self moveFramesIn: thePage through: frameAbove toPage: newPage.
					 stackPages markStackPageMostRecentlyUsed: newPage.
					 self setStackPointersFromPage: thePage]]
		ifFalse:
			[(isAContext
			  and: [objectMemory isIntegerObject: (objectMemory fetchPointer: InstructionPointerIndex ofObject: contextToReturnTo)]) ifFalse:
				[contextToReturnFrom := stackPages longAt: stackPage baseAddress - objectMemory wordSize.
				 self tearDownAndRebuildFrameForCannotReturnBaseFrameReturnFrom: contextToReturnFrom
					to: contextToReturnTo
					returnValue: returnValue.
				^self externalCannotReturn: returnValue from: contextToReturnFrom].
			 "void the instructionPointer to stop it being incorrectly updated in a code
			 compaction in makeBaseFrameFor:."
			 instructionPointer := 0.
			 thePage := self makeBaseFrameFor: contextToReturnTo.
			 self setStackPointersFromPage: thePage].
	self setStackPageAndLimit: thePage.
	self assert: (stackPages stackPageFor: framePointer) = stackPage.
	(self isMachineCodeFrame: framePointer) ifTrue:
		[self push: returnValue.
		 cogit ceEnterCogCodePopReceiverReg.
		 "NOTREACHED"].
	instructionPointer := self stackTop.
	instructionPointer = cogit ceReturnToInterpreterPC ifTrue:
		[instructionPointer := self iframeSavedIP: framePointer].
	self setMethod: (self iframeMethod: framePointer).
	self stackTopPut: returnValue. "a.k.a. pop saved ip then push result"
	self assert: (self checkIsStillMarriedContext: contextToReturnTo currentFP: framePointer).
	self siglong: reenterInterpreter jmp: ReturnToInterpreter.
	"NOTREACHED"
	^nil
]

{ #category : #trampolines }
CoInterpreter >> ceCannotAssignTo: immutableObject withIndex: index valueToAssign: valueToAssign [
	"index is unboxed and 0-based. The call-back expects 1-based value (to perform the operation with instVarAt:put:"
	<api>
	<option: #IMMUTABILITY>
	instructionPointer := self popStack.
	self push: immutableObject.
	self push: valueToAssign.
	self push: (objectMemory integerObjectOf: index + 1).
	self push: instructionPointer.
	^ self
		ceSendAbort: (objectMemory splObj: SelectorAttemptToAssign)
		to: immutableObject
		numArgs: 2
]

{ #category : #trampolines }
CoInterpreter >> ceCannotResume [
	<api>
	"A context that has been returned from, or otherwise has an invalid pc has been reentered.
	 Until we have a cannotResume: selector, simply resend cannotReturn:."
	| resultOop |
	self assert: (self isMachineCodeFrame: framePointer).
	self assert: (self frameHasContext: framePointer).
	resultOop := self stackTop.
	self push: (self frameContext: framePointer).
	self push: resultOop.
	"Make sure the happy couple remain returned from."
	self push: cogit ceCannotResumePC.
	^self
		ceSendAbort: (objectMemory splObj: SelectorCannotReturn)
		to: (self frameContext: framePointer)
		numArgs: 1
]

{ #category : #'primitive support' }
CoInterpreter >> ceCheckAndMaybeRetryPrimitive: primIndex [
	"Log failure and then retry if there's an accessorDepth or failure due to no memory."
	<api>
	<option: #SpurObjectMemory>
	| retried |
	
	cogit recordPrimTrace ifTrue:
		[self fastLogPrim: TracePrimitiveFailure].
	retried := self retryPrimitiveOnFailure.
	(retried and: [cogit recordPrimTrace]) ifTrue:
		[self fastLogPrim: TracePrimitiveRetry]
]

{ #category : #trampolines }
CoInterpreter >> ceCheckForInterrupts [
	<api>
	| switched |
	self cCode: [] inSmalltalk:
		[self maybeCheckStackDepth: 0 sp: stackPointer pc: instructionPointer].
	switched := self checkForEventsMayContextSwitch: true.
	self returnToExecutive: false postContextSwitch: switched
]

{ #category : #'cog jit support' }
CoInterpreter >> ceCheckProfileTick [
	"Check if the profile timer has expired and if so take a sample.
	 If the primitive has failed sample the profileMethod as nil.
	 As a courtesy to compileInterpreterPrimitive: map NULL to nilObj."
	<api>
	newMethod ifNil: [newMethod := objectMemory nilObject].
	self cCode: [] inSmalltalk:
		[newMethod = 0 ifTrue: [newMethod := objectMemory nilObject]].
	self checkProfileTick: newMethod
]

{ #category : #trampolines }
CoInterpreter >> ceContext: maybeContext instVar: slotIndex [
	<api>
	| result |
	(objectMemory isContextNonImm: maybeContext)
		ifTrue:
			[instructionPointer := self popStack.
			 result := self externalInstVar: slotIndex ofContext: maybeContext.
			 self push: instructionPointer]
		ifFalse: [result := objectMemory fetchPointer: slotIndex ofObject: maybeContext].
	^result
]

{ #category : #trampolines }
CoInterpreter >> ceContext: maybeMarriedContext instVar: slotIndex value: anOop [
	<api>
	"genStorePop:MaybeContextReceiverVariable: filters out unmarried contexts
	 but not arbitrary objects in subclasses.  It answers maybeMarriedContext so
	 that the StackToRegisterMappingCogit can keep ReceiverResultReg live."
	((objectMemory isContextNonImm: maybeMarriedContext) 
	 and: [self isMarriedOrWidowedContext: maybeMarriedContext])
		ifTrue:
			[instructionPointer := self popStack.
			 self externalInstVar: slotIndex ofContext: maybeMarriedContext put: anOop.
			 self push: instructionPointer]
		ifFalse:
			[objectMemory storePointer: slotIndex ofObject: maybeMarriedContext withValue: anOop].
	^maybeMarriedContext
]

{ #category : #'cog jit support' }
CoInterpreter >> ceCounterTripped: condition [
	"Two things are going on here.  The main one is catching a counter trip and attempting
	 to send the SelectorCounterTripped selector.  In this case we would like to back-up
	 the pc to the return address of the send that yields the boolean to be tested, so that
	 after potential optimization, computation proceeds by retrying the jump.  But we cannot,
	 since there may be no send, just a pop (as in and: [] and or: [] chains).  In this case we also
	 want to prevent further callbacks until optimization is complete.  So we nil-out the
	 SelectorCounterTripped entry in the specialSelectorArray.

	 The minor case is that there is an unlikely  possibility that the cointer tripped but condition
	 is not a boolean, in which case a mustBeBoolean response should occur."
	<api>
	<option: #SistaCogit>
	"Send e.g. thisContext conditionalBranchCounterTrippedOn: boolean."
	| context counterTrippedSelector classTag classObj |
	(condition = objectMemory falseObject
	or: [condition = objectMemory trueObject]) ifFalse:
		[^self ceSendMustBeBoolean: condition].

	counterTrippedSelector := objectMemory maybeSplObj: SelectorCounterTripped.
	(counterTrippedSelector isNil
	or: [counterTrippedSelector = objectMemory nilObject]) ifTrue:
		[cogit resetCountersIn: (self mframeHomeMethod: framePointer).
		 ^condition].

	classTag := objectMemory
					classTagForSpecialObjectsIndex: ClassMethodContext
					compactClassIndex: ClassMethodContextCompactIndex.
	(self lookupInMethodCacheSel: counterTrippedSelector classTag: classTag) ifFalse:
	 	[messageSelector := counterTrippedSelector.
		 classObj := objectMemory classForClassTag: classTag.
		 (self lookupOrdinaryNoMNUEtcInClass: classObj) ~= 0 ifTrue:
			[cogit resetCountersIn: (self mframeHomeMethod: framePointer).
			 ^condition]].

	(primitiveFunctionPointer ~= 0
	or: [(self argumentCountOf: newMethod) ~= 1]) ifTrue:
		[cogit resetCountersIn: (self mframeHomeMethod: framePointer).
		 ^condition].

	cogit setCogCodeZoneThreshold: 1.0.
	objectMemory splObj: SelectorCounterTripped put: objectMemory nilObject.
	instructionPointer := self popStack.
	context := self ensureFrameIsMarried: framePointer SP: stackPointer.
	self push: context.
	self push: condition.
	self ifAppropriateCompileToNativeCode: newMethod selector: counterTrippedSelector.
	self activateNewMethod.
	"not reached"
	^true
]

{ #category : #trampolines }
CoInterpreter >> ceInterpretMethodFromPIC: aMethodObj receiver: rcvr [
	<api>
	| pic primitiveIndex |
	<var: #pic type: #'CogMethod *'>
	"pop off inner return and locate open or closed PIC"
	pic := self cCoerceSimple: self popStack - cogit interpretOffset to: #'CogMethod *'.
	self assert: (pic cmType = CMOpenPIC or: [pic cmType = CMClosedPIC]).
	"If found from an open PIC then it must be an uncogged method and, since it's been found
	 in the method cache, should be cogged if possible.  If found from a closed PIC then at the
	 time the closed PIC was created the method was uncoggable, either because there was
	 no space, it had too many literals or it contained an illegal bytecode).  So don't try and cog
	 it, but subsequently it may have been cogged via another path.  If the method is, or ends up
	 cogged, jump to machine code, otherwise interpret."
	pic cmType = CMOpenPIC ifTrue:
		[self assert: (self methodHasCogMethod: aMethodObj) not.
		 (self methodShouldBeCogged: aMethodObj) ifTrue:
			[cogit cog: aMethodObj selector: pic selector]].
	(self methodHasCogMethod: aMethodObj) ifTrue:
		[self executeCogMethod: (self cogMethodOf: aMethodObj)
			fromUnlinkedSendWithReceiver: rcvr
		 "NOTREACHED"].
	messageSelector := pic selector.
	newMethod := aMethodObj.
	primitiveIndex := self primitiveIndexOf: aMethodObj.
	primitiveFunctionPointer := self functionPointerFor: primitiveIndex inClass: objectMemory nilObject.
	argumentCount := pic cmNumArgs.
	instructionPointer := self popStack.
	^self interpretMethodFromMachineCode
	"NOTREACHED"
]

{ #category : #trampolines }
CoInterpreter >> ceMNUFromPICMNUMethod: aMethodObj receiver: rcvr [
	<api>
	| cPIC primitiveIndex |
	<var: #cPIC type: #'CogMethod *'>
	self assert: (objectMemory addressCouldBeOop: rcvr).
	self assert: (aMethodObj = 0
				or: [(objectMemory addressCouldBeObj: aMethodObj)
					and: [objectMemory isOopCompiledMethod: aMethodObj]]).
	cPIC := self cCoerceSimple: self popStack - cogit mnuOffset to: #'CogMethod *'.
	self assert: (cPIC cmType = CMClosedPIC or: [cPIC cmType = CMOpenPIC]).
	argumentCount := cPIC cmNumArgs.
	messageSelector := cPIC selector.
	aMethodObj ~= 0 ifTrue:
		[instructionPointer := self popStack.
		self createActualMessageTo: (objectMemory fetchClassOf: rcvr).
		(self maybeMethodHasCogMethod: aMethodObj) ifTrue:
			[self push: instructionPointer.
			 self executeCogMethod: (self cogMethodOf: aMethodObj)
				 fromUnlinkedSendWithReceiver: rcvr.
			 "NOTREACHED"
			 self assert: false].
		newMethod := aMethodObj.
		primitiveIndex := self primitiveIndexOf: aMethodObj.
		primitiveFunctionPointer := self functionPointerFor: primitiveIndex inClass: objectMemory nilObject.
		^self interpretMethodFromMachineCode].
	"handleMNU:InMachineCodeTo:classForMessage: assumes lkupClass is set, since every other use is
	 after a lookupMethodNoMNUEtcInClass: call, which sets lkupClass.  Here we must set it manually.
	 Global variables.  Bah!"
	self handleMNU: SelectorDoesNotUnderstand
		InMachineCodeTo: rcvr
		classForMessage: (lkupClass := objectMemory fetchClassOf: rcvr).
	"NOTREACHED"
	self assert: false
]

{ #category : #trampolines }
CoInterpreter >> ceNewHashOf: anObject [
	<api>
	<option: #SpurObjectMemory>
	"We know anObject has not a hash yet (or this trampoline would not be called.
	 Sets the hash, then answers it as a smallinteger"
	self assert: ((objectMemory isNonImmediate: anObject)
				and: [(objectMemory rawHashBitsOf: anObject) = 0]).
	^objectMemory integerObjectOf: (objectMemory newHashBitsOf: anObject)
]

{ #category : #trampolines }
CoInterpreter >> ceNonLocalReturn: returnValue [
	<api>
	| closure home unwindContextOrNilOrZero ourContext frameToReturnTo contextToReturnTo theFP callerFP newPage |
	<var: #frameToReturnTo type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #newPage type: #'StackPage *'>
	<var: #thePage type: #'StackPage *'>

	"self shortPrintFrameAndCallers: framePointer.
	self printOop: returnValue.
	self halt."

	self assert: (self isMachineCodeFrame: framePointer).
	self assert: (self frameIsBlockActivation: framePointer).

	"Update the current page's headFrame pointers to enable the search for unwind protects below
	 to identify widowed contexts correctly."
	self externalWriteBackHeadFramePointers.

	"Since this is a block activation the closure is on the stack above any args and the frame."
	closure := self pushedReceiverOrClosureOfFrame: framePointer.
	home := nil. "avoid compiler warning"
	"Walk the closure's lexical chain to find the context or frame to return from (home)."
	[closure ~= objectMemory nilObject] whileTrue:
		[home := objectMemory followField: ClosureOuterContextIndex ofObject: closure.
		 (objectMemory isContext: home) ifFalse:
			["error: can't find home on chain; cannot return"
			 ourContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
			 ^self externalCannotReturn: returnValue from: ourContext].
		 closure := objectMemory followField: ClosureIndex ofObject: home].
	"home is to be returned from provided there is no unwind-protect activation between
	 this frame and home's sender.  Search for an unwind.  findUnwindThroughContext:
	 will answer either the context for an unwind-protect activation or nilObj if the sender
	 cannot be found or 0 if no unwind is found but the sender is."
	unwindContextOrNilOrZero := self findUnwindThroughContext: home.
	unwindContextOrNilOrZero = objectMemory nilObject ifTrue:
		["error: can't find home on chain; cannot return"
		 ourContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
		 ^self externalCannotReturn: returnValue from: ourContext].
	unwindContextOrNilOrZero ~= 0 ifTrue:
		[^self externalAboutToReturn: returnValue through: unwindContextOrNilOrZero].

	"Now we know home is on the sender chain.
	 We could be returning to either a context or a frame.  Find out which."
	contextToReturnTo := nil.
	(self isMarriedOrWidowedContext: home)
		ifTrue:
			[self assert: (self checkIsStillMarriedContext: home currentFP: framePointer).
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
				[self assert: (self checkIsStillMarriedContext: contextToReturnTo currentFP: framePointer).
			 	 frameToReturnTo := self frameOfMarriedContext: contextToReturnTo.
				 contextToReturnTo := nil]].

	"If returning to a context we must make a frame for it unless it is dead."
	contextToReturnTo ~= nil ifTrue:
		[frameToReturnTo := self establishFrameForContextToReturnTo: contextToReturnTo.
		 frameToReturnTo = 0 ifTrue:
			["error: home's sender is dead; cannot return"
			 ourContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
			 ^self externalCannotReturn: returnValue from: ourContext]].

	"Now we have a frame to return to.  If it is on a different page we must
	 free intervening pages and nil out intervening contexts.  We must free
	 intervening stack pages because if we leave the pages to be divorced
	 then their contexts will be divorced with intact senders and instruction
	 pointers.  This code is similar to primitiveTerminateTo."
	self assert: stackPages pageListIsWellFormed.
	newPage := stackPages stackPageFor: frameToReturnTo.
	newPage ~~ stackPage ifTrue:
		[| currentCtx thePage nextCntx |
		 currentCtx := self frameCallerContext: stackPage baseFP.
		 self assert: (objectMemory isContext: currentCtx).
		 stackPages freeStackPage: stackPage.
		 [self assert: (objectMemory isContext: currentCtx).
		  (self isMarriedOrWidowedContext: currentCtx)
		   and: [(stackPages stackPageFor: (theFP := self frameOfMarriedContext: currentCtx)) = newPage]] whileFalse:
			[(self isMarriedOrWidowedContext: currentCtx)
				ifTrue:
					[thePage := stackPages stackPageFor: theFP.
					 currentCtx := self frameCallerContext: thePage baseFP.
					 stackPages freeStackPage: thePage]
				ifFalse:
					[nextCntx := objectMemory fetchPointer: SenderIndex ofObject: currentCtx.
					 self markContextAsDead: currentCtx.
					 currentCtx := nextCntx]].
		 self setStackPageAndLimit: newPage.
		 self setStackPointersFromPage: newPage].

	"Two cases.  Returning to the top frame or an interior frame.  The
	 top frame has its instruction pointer on top of stack.  An interior
	 frame has its instruction pointer in the caller frame. We need to
	 peel back any frames on the page until we get to the correct frame."
	framePointer = frameToReturnTo
		ifTrue:
			[instructionPointer := self popStack]
		ifFalse:
			[[callerFP := framePointer.
			  framePointer := self frameCallerFP: framePointer.
			  framePointer ~~ frameToReturnTo] whileTrue.
			 instructionPointer := (self frameCallerSavedIP: callerFP) asUnsignedInteger.
			 stackPointer := (self frameCallerSP: callerFP)].
	^self return: returnValue toExecutive: false
]

{ #category : #trampolines }
CoInterpreter >> ceReapAndResetErrorCodeFor: cogMethod [
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	self assert: primFailCode ~= 0.
	newMethod := cogMethod methodObject.
	self reapAndResetErrorCodeTo: stackPointer + objectMemory wordSize
		header: cogMethod methodHeader
]

{ #category : #trampolines }
CoInterpreter >> ceReturnToInterpreter: anOop [
	"Perform a return from a machine code frame to an interpreted frame.
	 The machine code has executed a return instruction when the return address
	 is set to ceReturnToInterpreterPC.  Return the result and switch to the interpreter."
	<api>
	self assert: (objectMemory addressCouldBeOop: anOop).
	self flag: 'are you really sure setStackPageAndLimit: is needed?'.
	"I think you're only doing this for the markStackPageMostRecentlyUsed:
	 and that's probably not needed either"
	self setStackPageAndLimit: stackPage.
	self assert: (self isMachineCodeFrame: framePointer) not.
	self setMethod: (self iframeMethod: framePointer).
	self assertValidExecutionPointe: (self iframeSavedIP: framePointer)
		r: framePointer
		s: stackPointer
		imbar: true
		line: #'__LINE__'.
	instructionPointer := self iframeSavedIP: framePointer.
	self push: anOop.
	self siglong: reenterInterpreter jmp: ReturnToInterpreter.
	"NOTREACHED"
	^nil
]

{ #category : #trampolines }
CoInterpreter >> ceSend: selector above: methodClass to: rcvr numArgs: numArgs [
	"Entry-point for an unlinked directed super send in a CogMethod.  Smalltalk stack looks like
					receiver
					args
		head sp ->	sender return pc
	methodClass is the class above which to start the lookup.

	If an MNU then defer to handleMNUInMachineCodeTo:... which will dispatch the MNU and
	may choose to allocate a closed PIC with a fast MNU dispatch for this send.  Otherwise
	attempt to link the send site as efficiently as possible.  All link attempts may fail; e.g.
	because we're out of code memory.

	Continue execution via either executeMethod or interpretMethodFromMachineCode:
	depending on whether the target method is cogged or not."
	<api>
	<option: #BytecodeSetHasDirectedSuperSend>
	| classTag classObj errSelIdx cogMethod |
	<inline: false>
	<var: #cogMethod type: #'CogMethod *'>
	<var: #newCogMethod type: #'CogMethod *'>
	"self printExternalHeadFrame"
	"self printStringOf: selector"
	cogit assertCStackWellAligned.
	self assert: (objectMemory addressCouldBeOop: rcvr).
	self sendBreakpoint: selector receiver: rcvr.
	classTag := objectMemory classTagForClass: (self superclassOf: (objectMemory followMaybeForwarded: methodClass)).
	argumentCount := numArgs.
	(self lookupInMethodCacheSel: selector classTag: classTag)
		ifTrue:"check for coggability because method is in the cache"
			[self
				ifAppropriateCompileToNativeCode: newMethod
				selector: selector]
		ifFalse:
			[self deny: (objectMemory isForwardedClassTag: classTag).
			 (objectMemory isOopForwarded: selector) ifTrue:
				[^self
					ceSend: (self handleForwardedSelectorFaultFor: selector)
					above: methodClass
					to: rcvr
					numArgs: numArgs].
			 messageSelector := selector.
			 classObj := objectMemory classForClassTag: classTag.
			 (errSelIdx := self lookupOrdinaryNoMNUEtcInClass: classObj) ~= 0 ifTrue:
				[(errSelIdx = SelectorDoesNotUnderstand
				  and: [(cogMethod := cogit cogMNUPICSelector: messageSelector
											receiver: rcvr
											methodOperand: (self mnuMethodOrNilFor: rcvr)
											numArgs: argumentCount) asUnsignedInteger
						> cogit minCogMethodAddress]) ifTrue:
						[cogit
							linkSendAt: (stackPages longAt: stackPointer)
							in: (self mframeHomeMethod: framePointer)
							to: cogMethod
							offset: cogit noCheckEntryOffset
							receiver: rcvr].
				self handleMNU: errSelIdx
					InMachineCodeTo: rcvr
					classForMessage: classObj.
				self assert: false "NOTREACHED"]].
	"Method found and has a cog method.  Attempt to link to it.  The receiver's class may be young.
	 We must not link to an Open PIC since they perform normal sends."
	(self maybeMethodHasCogMethod: newMethod) ifTrue:
		[cogMethod := self cogMethodOf: newMethod.
		 cogMethod selector = objectMemory nilObject
			ifTrue: [cogit setSelectorOf: cogMethod to: selector]
			ifFalse:
				["Deal with anonymous accessors, e.g. in Newspeak.  The cogMethod may not have the
				  correct selector.  If not, try and compile a new method with the correct selector."
				 cogMethod selector ~= selector ifTrue:
					[(cogit cog: newMethod selector: selector) ifNotNil:
						[:newCogMethod| cogMethod := newCogMethod]]].
		 cogMethod selector = selector ifTrue:
			[cogit
				linkSendAt: (stackPages longAt: stackPointer)
				in: (self mframeHomeMethod: framePointer)
				to: cogMethod
				offset: cogit noCheckEntryOffset
				receiver: rcvr].
		 instructionPointer := self popStack.
		 self executeNewMethod.
		 self assert: false "NOTREACHED"].
	instructionPointer := self popStack.
	^self interpretMethodFromMachineCode
	"NOTREACHED"
]

{ #category : #trampolines }
CoInterpreter >> ceSend: selector aboveClassBinding: methodClassBinding to: rcvr numArgs: numArgs [
	"Entry-point for an unlinked directed super send in a CogMethod.  Smalltalk stack looks like
					receiver
					args
		head sp ->	sender return pc
	methodClassBinding is an association whose value is the class above which to start the lookup."
	<api>
	<option: #BytecodeSetHasDirectedSuperSend>
	self ceSend: selector
		above: (self fetchPointer: ValueIndex
					ofObject: (objectMemory followMaybeForwarded: methodClassBinding))
		to: rcvr
		numArgs: numArgs
]

{ #category : #trampolines }
CoInterpreter >> ceSend: selector super: superNormalBar to: rcvr numArgs: numArgs [
	"Entry-point for an unlinked send in a CogMethod.  Smalltalk stack looks like
					receiver
					args
		head sp ->	sender return pc
		
	If an MNU then defer to handleMNUInMachineCodeTo:... which will dispatch the MNU and
	may choose to allocate a closed PIC with a fast MNU dispatch for this send.  Otherwise
	attempt to link the send site as efficiently as possible.  All link attempts may fail; e.g.
	because we're out of code memory.

	Continue execution via either executeMethod or interpretMethodFromMachineCode:
	depending on whether the target method is cogged or not."
	<api>
	| classTag classObj errSelIdx cogMethod |
	<inline: false>
	<var: #cogMethod type: #'CogMethod *'>
	<var: #newCogMethod type: #'CogMethod *'>
	"self printExternalHeadFrame"
	"self printStringOf: selector"
	cogit assertCStackWellAligned.
	self assert: (objectMemory addressCouldBeOop: rcvr).
	self sendBreakpoint: selector receiver: rcvr.
	superNormalBar = 0
		ifTrue: [classTag := objectMemory fetchClassTagOf: rcvr]
		ifFalse: [classTag := objectMemory classTagForClass: (self superclassOf: (self methodClassOf: (self frameMethodObject: framePointer)))].
	argumentCount := numArgs.
	(self lookupInMethodCacheSel: selector classTag: classTag)
		ifTrue:"check for coggability because method is in the cache"
			[self
				ifAppropriateCompileToNativeCode: newMethod
				selector: selector]
		ifFalse:
			[(objectMemory isOopForwarded: selector) ifTrue:
				[^self
					ceSend: (self handleForwardedSelectorFaultFor: selector)
					super: superNormalBar
					to: rcvr
					numArgs: numArgs].
			 (objectMemory isForwardedClassTag: classTag) ifTrue:
				[self assert: superNormalBar = 0.
				^self
					ceSend: selector
					super: superNormalBar
					to: (self handleForwardedSendFaultForReceiver: rcvr stackDelta: 1 "skip return pc")
					numArgs: numArgs].
			 messageSelector := selector.
			 classObj := objectMemory classForClassTag: classTag.
			 (errSelIdx := self lookupOrdinaryNoMNUEtcInClass: classObj) ~= 0 ifTrue:
				[(errSelIdx = SelectorDoesNotUnderstand
				  and: [(cogMethod := cogit cogMNUPICSelector: messageSelector
											receiver: rcvr
											methodOperand: (self mnuMethodOrNilFor: rcvr)
											numArgs: argumentCount) asUnsignedInteger
						> cogit minCogMethodAddress]) ifTrue:
						[cogit
							linkSendAt: (stackPages longAt: stackPointer)
							in: (self mframeHomeMethod: framePointer)
							to: cogMethod
							offset: (superNormalBar = 0
									ifTrue: [cogit entryOffset]
									ifFalse: [cogit noCheckEntryOffset])
							receiver: rcvr].
				self handleMNU: errSelIdx InMachineCodeTo: rcvr classForMessage: classObj.
				self assert: false "NOTREACHED"]].
	"Method found and has a cog method.  Attempt to link to it.  The receiver's class may be young.
	 If the Cogit can't store young classes in inline caches we can link to an open PIC instead."
	(self maybeMethodHasCogMethod: newMethod) ifTrue:
		[cogMethod := self cogMethodOf: newMethod.
		 cogMethod selector = objectMemory nilObject
			ifTrue: [cogit setSelectorOf: cogMethod to: selector]
			ifFalse:
				["Deal with anonymous accessors, e.g. in Newspeak.  The cogMethod may not have the
				  correct selector.  If not, try and compile a new method with the correct selector."
				 cogMethod selector ~= selector ifTrue:
					[(cogit cog: newMethod selector: selector) ifNotNil:
						[:newCogMethod| cogMethod := newCogMethod]]].
		 cogMethod selector = selector
			ifTrue:
				[cogit
					linkSendAt: (stackPages longAt: stackPointer)
					in: (self mframeHomeMethod: framePointer)
					to: cogMethod
					offset: (superNormalBar = 0
								ifTrue: [cogit entryOffset]
								ifFalse: [cogit noCheckEntryOffset])
					receiver: rcvr]
			ifFalse: "If patchToOpenPICFor:.. returns we're out of code memory"
				[superNormalBar = 0 ifTrue: "Open PICs perform normal sends. Can't patch if this is a super send."
					[cogit
						patchToOpenPICFor: selector
						numArgs: numArgs
						receiver: rcvr]].
		 instructionPointer := self popStack.
		 self executeNewMethod.
		 self assert: false "NOTREACHED"].
	instructionPointer := self popStack.
	^self interpretMethodFromMachineCode
	"NOTREACHED"
]

{ #category : #trampolines }
CoInterpreter >> ceSendAbort: selector to: rcvr numArgs: numArgs [
	"Entry-point for an abort send in a CogMethod (aboutToReturn:through:, cannotReturn: et al).
	 Try and dispatch the send, but the send may turn into an MNU in which case defer to
	 handleMNUInMachineCodeTo:... which will dispatch the MNU.

	 Continue execution via either executeMethod or interpretMethodFromMachineCode:
	 depending on whether the target method is cogged or not."
	<api>
	| classTag classObj errSelIdx |
	<inline: false>
	"self printExternalHeadFrame"
	"self printStringOf: selector"
	cogit assertCStackWellAligned.
	self assert: (objectMemory addressCouldBeOop: rcvr).
	self sendBreakpoint: selector receiver: rcvr.
	argumentCount := numArgs.
	classTag := objectMemory fetchClassTagOf: rcvr.
	(self lookupInMethodCacheSel: selector classTag: classTag)
		ifTrue:"check for coggability because method is in the cache"
			[self
				ifAppropriateCompileToNativeCode: newMethod
				selector: selector]
		ifFalse:
			[messageSelector := selector.
			 classObj := objectMemory classForClassTag: classTag.
			 (errSelIdx := self lookupOrdinaryNoMNUEtcInClass: classObj) ~= 0 ifTrue:
				[self handleMNU: errSelIdx InMachineCodeTo: rcvr classForMessage: classObj.
				"NOTREACHED"
				self assert: false]].
	instructionPointer := self popStack.
	(self maybeMethodHasCogMethod: newMethod) ifTrue:
		[self executeNewMethod.
		 self assert: false
		 "NOTREACHED"].
	^self interpretMethodFromMachineCode
	"NOTREACHED"
]

{ #category : #trampolines }
CoInterpreter >> ceSendFromInLineCacheMiss: cogMethodOrPIC [
	"Send from an Open PIC when the first-level method lookup probe has failed,
	 or to continue when PIC creation has failed (e.g. because we're out of code space),
	 or when a send has failed due to a forwarded receiver."
	<api>
	<var: #cogMethodOrPIC type: #'CogMethod *'>
	| numArgs rcvr classTag classObj errSelIdx |
	"self printFrame: stackPage headFP WithSP: stackPage headSP"
	"self printStringOf: selector"
	numArgs := cogMethodOrPIC cmNumArgs.
	rcvr := self stackValue: numArgs + 1. "skip return pc"
	self assert: (objectMemory addressCouldBeOop: rcvr).
	classTag := objectMemory fetchClassTagOf: rcvr.
	argumentCount := numArgs.
	false ifTrue: "would like to assert this but must also allow for an interpretable method in the cache."
		[self deny: (cogMethodOrPIC cmType = CMOpenPIC
					and: [self newMethodInLookupCacheAt: cogMethodOrPIC selector and: classTag])].
	(self lookupInMethodCacheSel: cogMethodOrPIC selector classTag: classTag)
		ifTrue:"check for coggability because method is in the cache"
			[self
				ifAppropriateCompileToNativeCode: newMethod
				selector: cogMethodOrPIC selector]
		ifFalse:
			[(objectMemory isOopForwarded: cogMethodOrPIC selector) ifTrue:
				[self handleForwardedSelectorFaultFor: cogMethodOrPIC selector.
				 ^self ceSendFromInLineCacheMiss: cogMethodOrPIC].
			 (objectMemory isForwardedClassTag: classTag) ifTrue:
				[self handleForwardedSendFaultForReceiver: rcvr stackDelta: 1 "skip return pc".
				 ^self ceSendFromInLineCacheMiss: cogMethodOrPIC].
			 messageSelector := cogMethodOrPIC selector.
			 classObj := objectMemory classForClassTag: classTag.
			 (errSelIdx := self lookupOrdinaryNoMNUEtcInClass: classObj) ~= 0 ifTrue:
				[self handleMNU: errSelIdx InMachineCodeTo: rcvr classForMessage: classObj.
				"NOTREACHED"
				self assert: false]].
	instructionPointer := self popStack.
	(self maybeMethodHasCogMethod: newMethod) ifTrue:
		[self executeNewMethod.
		 self assert: false
		 "NOTREACHED"].
	^self interpretMethodFromMachineCode
	"NOTREACHED"
]

{ #category : #trampolines }
CoInterpreter >> ceSendMustBeBoolean: anObject [
	<api>
	instructionPointer := self popStack.
	self push: anObject.
	self push: instructionPointer.
	^self
		ceSendAbort: (objectMemory splObj: SelectorMustBeBoolean)
		to: anObject
		numArgs: 0
]

{ #category : #trampolines }
CoInterpreter >> ceSendMustBeBooleanTo: aNonBooleanObject interpretingAtDelta: jumpSize [
	"For RegisterAllocatingCogit we want the pc following a conditional branch not to be reachable, so
	 we don't have to generate code to reload registers.  But notionally the pc following a conditional
	 branch is reached when continuing from a mustBeBoolean error.  Instead of supporting this in the
	 JIT, simply convert to an interpreter frame, backup the pc to the branch, reenter the interpreter
	 and hence retry the mustBeBoolean send therein.  N.B. We could do this for immutability violations
	 too, but immutability is used in actual applications and so should be performant, whereas
	 mustBeBoolean errors are extremely rare and so we choose brevity over performance in this case."
	<api>
	| cogMethod methodObj methodHeader startBcpc |
	<var: 'cogMethod' type: #'CogBlockMethod *'>
	<var: 'p' type: #'char *'>
	self assert: (objectMemory addressCouldBeOop: aNonBooleanObject).
	cogMethod := self mframeCogMethod: framePointer.
	((self mframeIsBlockActivation: framePointer)
	 and: [cogMethod cmIsFullBlock not])
		ifTrue:
			[methodHeader := (self cCoerceSimple: cogMethod cmHomeMethod to: #'CogMethod *') methodHeader.
			 methodObj := (self cCoerceSimple: cogMethod cmHomeMethod to: #'CogMethod *') methodObject.
			 startBcpc := cogMethod startpc]
		ifFalse:
			[methodHeader := (self cCoerceSimple: cogMethod to: #'CogMethod *') methodHeader.
			 methodObj := (self cCoerceSimple: cogMethod to: #'CogMethod *') methodObject.
			 startBcpc := self startPCOfMethod: methodObj].

	"Map the machine code instructionPointer to the interpreter instructionPointer of the branch."
	instructionPointer := self popStack.
	instructionPointer := cogit bytecodePCFor: instructionPointer startBcpc: startBcpc in: cogMethod.
	instructionPointer := methodObj + objectMemory baseHeaderSize + instructionPointer - jumpSize - 1. "pre-decrement"

	"Make space for the two extra fields in an interpreter frame"
	stackPointer to: framePointer + FoxMFReceiver by: objectMemory wordSize do:
		[:p| | oop |
		 oop := objectMemory longAt: p.
		 objectMemory
			longAt: p - objectMemory wordSize - objectMemory wordSize
			put: (objectMemory longAt: p)].
	stackPointer := stackPointer - objectMemory wordSize - objectMemory wordSize.
	self push: aNonBooleanObject.
	"Fill in the fields"
	objectMemory
		longAt: framePointer + FoxIFrameFlags
			put: (self
					encodeFrameFieldHasContext: (self mframeHasContext: framePointer)
					isBlock: (self mframeIsBlockActivation: framePointer)
					numArgs: cogMethod cmNumArgs);
		longAt: framePointer + FoxIFSavedIP
			put: 0;
		longAt: framePointer + FoxMethod
			put: methodObj.

	"and now reenter the interpreter..."
	self setMethod: methodObj methodHeader: methodHeader.
	self siglong: reenterInterpreter jmp: ReturnToInterpreter.
]

{ #category : #trampolines }
CoInterpreter >> ceSistaTrap [
	"When we arrive here, the value that trapped is pushed on stack"
	<api>
	<option: #SistaVM>
	| context |
	instructionPointer := self popStack.
	context := self ensureFrameIsMarried: framePointer SP: stackPointer.
	self push: context.
	self push: instructionPointer.
	^self
		ceSendAbort: (objectMemory splObj: SelectorSistaTrap)
		to: context
		numArgs: 0
]

{ #category : #trampolines }
CoInterpreter >> ceStackOverflow: contextSwitchIfNotNil [
	"If contextSwitchIfNotNil is nil we can't context switch.
	 contextSwitchIfNotNil is set to nil by
		- the special primitiveClosureValueNoContextSwitch entry-point in block dispatch
		- the stack check in methods with primitive 198.
	 In a normal method contextSwitchIfNotNil will be the method (see e.g.
	 SimpleStackBasedCogit>>compileFrameBuild).  In a block it will be the
	 closure (see e.g. SimpleStackBasedCogit>>compileMethodBody)."
	<api>
	| cogMethod switched cesoRetAddr |
	<var: #cogMethod type: #'CogBlockMethod *'>
	cesoRetAddr := self popStack. "discard the ceStackOverflow call return address."
	cogMethod := self mframeCogMethod: framePointer.
	self assert: cesoRetAddr - cogit abortOffset = (self asCogHomeMethod: cogMethod) asInteger.
	instructionPointer := cogMethod asInteger + cogMethod stackCheckOffset.
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: false line: #'__LINE__'.
	method := newMethod := messageSelector := objectMemory nilObject.
	switched := self handleStackOverflowOrEventAllowContextSwitch: contextSwitchIfNotNil ~= 0.
	self returnToExecutive: false postContextSwitch: switched.
	self error: 'should not be reached'

]

{ #category : #'debug support' }
CoInterpreter >> ceTraceBlockActivation [
	<api>
	cogit recordBlockTrace ifTrue:
		[self recordTrace: TraceBlockActivation
			thing: (self mframeHomeMethod: framePointer) methodObject
			source: TraceIsFromMachineCode.
		 cogit printOnTrace ifTrue:
			[self printActivationNameFor: (self mframeHomeMethod: framePointer) methodObject
				receiver: (self frameReceiver: framePointer)
				isBlock: true
				firstTemporary: nil.
			 self cr]]
]

{ #category : #'debug support' }
CoInterpreter >> ceTraceLinkedSend: theReceiver [
	| cogMethod |
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self cCoerceSimple: (self stackTop - cogit traceLinkedSendOffset)
						to: #'CogMethod *'.
	self cCode: [] inSmalltalk:
		[cogit checkStackDepthOnSend ifTrue:
			[self maybeCheckStackDepth: (cogMethod cmNumArgs > cogit numRegArgs
											ifTrue: [cogMethod cmNumArgs + 1]
											ifFalse: [0])
				sp: stackPointer + objectMemory wordSize
				pc: (self stackValue: 1)]].
	"cogit recordSendTrace ifTrue: is implicit; wouldn't compile the call otherwise."
	self recordTrace: (objectMemory fetchClassOf: theReceiver)
		thing: cogMethod selector
		source: TraceIsFromMachineCode.
	cogit printOnTrace ifTrue:
		[self printActivationNameFor: cogMethod methodObject
			receiver: theReceiver
			isBlock: false
			firstTemporary: (self cCode: [nil] inSmalltalk: [0]);
			cr].
	self sendBreakpoint: cogMethod selector receiver: theReceiver
]

{ #category : #trampolines }
CoInterpreter >> ceTraceStoreOf: aValue into: anObject [
	<api>
	"For assertion checking."
	self assert: ((objectMemory isImmediate: aValue) or: [objectMemory addressCouldBeObj: aValue]).
	self assert: (objectMemory addressCouldBeObj: anObject)
]

{ #category : #'debug support' }
CoInterpreter >> checkAssertsEnabledInCoInterpreter [
	<api>
	| assertsAreEnabledInCoInterpreter |
	assertsAreEnabledInCoInterpreter := false.
	self assert: assertsAreEnabledInCoInterpreter
]

{ #category : #'object memory support' }
CoInterpreter >> checkCodeIntegrity: gcModes [
	"Perform an integrity/leak check using the heapMap.  Assume
	 clearLeakMapAndMapAccessibleObjects has set a bit at each
	 object's header.  Check that all object references in machine
	 code are valid.  Answer if all checks pass."
	^cogit checkIntegrityOfObjectReferencesInCode: gcModes
]

{ #category : #'process primitive support' }
CoInterpreter >> checkCogCompiledCodeCompactionCalledFor [
	cogCompiledCodeCompactionCalledFor ifTrue:
		[self commenceCogCompiledCodeCompaction]
]

{ #category : #'primitive support' }
CoInterpreter >> checkForAndFollowForwardedPrimitiveState [
	"Override to log"
	<option: #SpurObjectMemory>
	| found |
	cogit recordPrimTrace ifTrue:
		[self fastLogPrim: TracePrimitiveFailure].
	found := super checkForAndFollowForwardedPrimitiveState.
	(found and: [cogit recordPrimTrace]) ifTrue:
		[self fastLogPrim: TracePrimitiveRetry].
	^found
]

{ #category : #'object memory support' }
CoInterpreter >> checkLogIntegrity [
	"Check the log for leaks.  The trace log is a circular buffer of pairs of entries.
	 If there is an entry at traceLogIndex - 3 \\ TraceBufferSize it has entries.  If
	 there is something at traceLogIndex it has wrapped."
	| limit ok |
	limit := self safe: traceLogIndex - 3 mod: TraceBufferSize.
	(traceLog at: limit) = 0 ifTrue: [^true].
	(traceLog at: traceLogIndex) ~= 0 ifTrue:
		[limit := TraceBufferSize - 3].
	ok := true.
	0 to: limit by: 3 do:
		[:i| | oop |
		oop := traceLog at: i.
		(objectMemory isImmediate: oop) ifFalse:
			[(objectMemory checkOopIntegrity: oop named: 'traceLog' index: i) ifFalse:
				[ok := false]].
		oop := traceLog at: i + 1.
		(objectMemory isImmediate: oop) ifFalse:
			[(objectMemory checkOopIntegrity: oop named: 'traceLog' index: i + 1) ifFalse:
				[ok := false]]].
	^ok
]

{ #category : #'debug support' }
CoInterpreter >> checkOkayFields: oop [
	"Check if the argument is an ok object.
	 If this is a pointers object, check that its fields are all okay oops."

	| hasYoung i fieldOop |
	(oop = nil or: [oop = 0]) ifTrue: [ ^true ]. "?? eem 1/16/2013"
	(objectMemory isIntegerObject: oop) ifTrue: [ ^true ].
	(objectMemory checkOkayOop: oop) ifFalse: [ ^false ].
	(objectMemory checkOopHasOkayClass: oop) ifFalse: [ ^false ].
	((objectMemory isPointersNonImm: oop) or: [objectMemory isCompiledMethod: oop]) ifFalse: [ ^true ].
	hasYoung := objectMemory hasSpurMemoryManagerAPI not
				  and: [objectMemory isYoungObject: (objectMemory fetchClassOfNonImm: oop)].
	(objectMemory isCompiledMethod: oop)
		ifTrue:
			[i := (objectMemory literalCountOf: oop) + LiteralStart - 1]
		ifFalse:
			[(objectMemory isContext: oop)
				ifTrue: [i := CtxtTempFrameStart + (self fetchStackPointerOf: oop) - 1]
				ifFalse: [i := (objectMemory lengthOf: oop) - 1]].
	[i >= 0] whileTrue:
		[fieldOop := objectMemory fetchPointer: i ofObject: oop.
		(objectMemory isNonIntegerObject: fieldOop) ifTrue:
			[(i = 0 and: [objectMemory isCompiledMethod: oop])
				ifTrue:
					[(cogMethodZone methodFor: (self pointerForOop: fieldOop)) = 0 ifTrue:
						[self print: 'method '; printHex: oop; print: ' has an invalid cog method reference'.
						^false]]
				ifFalse:
					[hasYoung := hasYoung or: [objectMemory isYoung: fieldOop].
					(objectMemory checkOkayOop: fieldOop) ifFalse: [ ^false ].
					(self checkOopHasOkayClass: fieldOop) ifFalse: [ ^false ]]].
		i := i - 1].
	hasYoung ifTrue:
		[^objectMemory checkOkayYoungReferrer: oop].
	^true
]

{ #category : #'object memory support' }
CoInterpreter >> checkStackIntegrity [
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
	<var: #frameRcvrOffset type: #'char *'>
	<var: #cogMethod type: #'CogMethod *'>
	ok := true.
	0 to: numStackPages - 1 do:
		[:i| | thePage theSP theFP frameRcvrOffset callerFP oop |
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
			 [frameRcvrOffset := self frameReceiverLocation: theFP.
			  [theSP <= frameRcvrOffset] whileTrue:
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
				 ((objectMemory isContext: oop) and: [(self frameOfMarriedContext: oop) = theFP]) ifFalse:
					[self printFrameThing: 'frame ctxt should be married to this frame ' andFrame: theFP at: theFP + FoxThisContext.
					 ok := false]].
			 (self isMachineCodeFrame: theFP)
				ifTrue:
					[| cogMethod |
					 cogMethod := self mframeHomeMethod: theFP.
					 (objectMemory heapMapAtWord: (self pointerForOop: cogMethod)) = 0 ifTrue:
						[self printFrameThing: 'object leak in mframe mthd' andFrame: theFP at: theFP + FoxMethod.
						 ok := false]]
				ifFalse:
					[oop := self iframeMethod: theFP.
					 ((objectMemory isImmediate: oop) 
					   or: [(objectMemory heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
						[self printFrameThing: 'object leak in iframe mthd' andFrame: theFP at: theFP + FoxMethod.
						 ok := false]].
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

{ #category : #'process primitive support' }
CoInterpreter >> clearCogCompiledCodeCompactionCalledFor [
	"For in-image tests"
	cogCompiledCodeCompactionCalledFor := false
]

{ #category : #'debug support' }
CoInterpreter >> clearTraceLog [
	<api>
	traceLogIndex := 0.
	0 to: TraceBufferSize - 1 do:
		[:i|
		traceLog at: i put: 0]
]

{ #category : #accessing }
CoInterpreter >> cogCodeSize [
	^cogCodeSize
]

{ #category : #accessing }
CoInterpreter >> cogCodeSize: anInteger [ 
	<doNotGenerate>
	cogCodeSize := anInteger
]

{ #category : #'compiled methods' }
CoInterpreter >> cogMethodOf: aMethodOop [
	<api>
	| methodHeader |
	methodHeader := self rawHeaderOf: aMethodOop.
	self assert: ((objectMemory isNonImmediate: methodHeader)
				and: [methodHeader asUnsignedInteger < objectMemory startOfMemory]).
	^self cCoerceSimple: methodHeader to: #'CogMethod *'
]

{ #category : #'as yet unclassified' }
CoInterpreter >> cogMethodZone [
	<doNotGenerate>
	^ cogMethodZone
]

{ #category : #'as yet unclassified' }
CoInterpreter >> cogMethodZone: aCogMethodZone [ 
	<doNotGenerate>
	cogMethodZone := aCogMethodZone
]

{ #category : #accessing }
CoInterpreter >> cogit: aCogit [
	<doNotGenerate>
	"for in-image tests"
	cogit := aCogit
]

{ #category : #'cog jit support' }
CoInterpreter >> commenceCogCompiledCodeCompaction [
	| startTime |
	<var: #startTime type: #usqLong>
	cogCompiledCodeCompactionCalledFor := false.
	cogit recordEventTrace ifTrue:
		[self recordTrace: TraceCodeCompaction thing: TraceCodeCompaction source: 0].
	cogit recordPrimTrace ifTrue:
		[self fastLogPrim: TraceCodeCompaction].
	startTime := self ioUTCMicrosecondsNow.

	"This can be called in a number of circumstances.  The instructionPointer
	 may contain a native pc that must be relocated.  There may already be a
	 pushed instructionPointer on stack.  Clients ensure that instructionPointer
	 is 0 if it should not be pushed and/or relocated.  Pushing twice is a mistake
	 because only the top one will be relocated."
	instructionPointer ~= 0 ifTrue:
		["better not have already been pushed"
		 self assert: self stackTop asUnsignedInteger ~= instructionPointer.
		 self push: instructionPointer.
		 self externalWriteBackHeadStackPointer].
	self assertValidStackedInstructionPointers: #'__LINE__'.
	cogit compactCogCompiledCode.
	self nilUncoggableMethods.
	instructionPointer ~= 0 ifTrue:
		[instructionPointer := self popStack.
		 self externalWriteBackHeadStackPointer].
	self assertValidStackedInstructionPointers: #'__LINE__'.

	statCodeCompactionCount := statCodeCompactionCount + 1.
	statCodeCompactionUsecs := statCodeCompactionUsecs + (self ioUTCMicrosecondsNow - startTime).

	objectMemory checkForLeaks ~= 0 ifTrue:
		[objectMemory clearLeakMapAndMapAccessibleObjects.
		 self asserta: (self checkCodeIntegrity: false)]
]

{ #category : #'return bytecodes' }
CoInterpreter >> commonCallerReturn [
	"Return to the previous context/frame (sender for method activations, caller for block activations)."
	<sharedCodeNamed: 'commonCallerReturn' inCase: #returnTopFromBlock>
	| callersFPOrNull |
	<var: #callersFPOrNull type: #'char *'>
	callersFPOrNull := self frameCallerFP: localFP.
	callersFPOrNull = 0 "baseFrame" ifTrue:
		[self assert: localFP = stackPage baseFP.
		 ^self baseFrameReturn].

	localIP := self frameCallerSavedIP: localFP.
	localSP := localFP + (self frameStackedReceiverOffset: localFP).
	localFP := callersFPOrNull.
	localIP asUnsignedInteger < objectMemory startOfMemory ifTrue:
		[localIP asUnsignedInteger ~= cogit ceReturnToInterpreterPC ifTrue:
			["localIP in the cog method zone indicates a return to machine code."
			 ^self returnToMachineCodeFrame].
		 localIP := self pointerForOop: (self iframeSavedIP: localFP)].
	self setMethod: (self iframeMethod: localFP).
	self fetchNextBytecode.
	self internalStackTopPut: localReturnValue
]

{ #category : #'send bytecodes' }
CoInterpreter >> commonSendOrdinary [
	"Send a message, starting lookup with the receiver's class."
	"Assume: messageSelector and argumentCount have been set, and that 
	the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	<sharedCodeNamed: 'commonSendOrdinary' inCase: #singleExtendedSendBytecode>
	self sendBreakpoint: messageSelector receiver: (self internalStackValue: argumentCount).
	cogit recordSendTrace ifTrue:
		[self recordTrace: (objectMemory classForClassTag: lkupClassTag)
			thing: messageSelector
			source: TraceIsFromInterpreter.
		cogit printOnTrace ifTrue:
			[self printActivationNameForSelector: messageSelector
				startClass: (objectMemory classForClassTag: lkupClassTag); cr]].
	self internalFindNewMethodOrdinary.
	self internalExecuteNewMethod.
	self fetchNextBytecode
]

{ #category : #'indexing primitive support' }
CoInterpreter >> commonVariable: rcvr at: index cacheIndex: atIx [
	"There is no atCache in the CoInterpreter."
	self shouldNotImplement
]

{ #category : #'indexing primitive support' }
CoInterpreter >> commonVariable: rcvr at: index put: value cacheIndex: atIx [
	"There is no atCache in the CoInterpreter."
	self shouldNotImplement
]

{ #category : #'debug support' }
CoInterpreter >> compilationBreak: selectorOop point: selectorLength isMNUCase: isMNUCase [
	<api>
	<cmacro: '(sel, len, isMNU) do { \
	if ((len) == (isMNU ? -breakSelectorLength : breakSelectorLength) \
	 && !strncmp((char *)((sel) + BaseHeaderSize), breakSelector, (isMNU ? -breakSelectorLength : breakSelectorLength))) { \
		suppressHeartbeatFlag = 1; \
		compilationBreakpointFor(sel); \
	} \
} while (0)'>
	| bsl i |
	bsl := isMNUCase ifTrue: [breakSelectorLength negated] ifFalse: [breakSelectorLength].
	bsl = selectorLength ifTrue:
		[i := bsl.
		 [i > 0] whileTrue:
			[(objectMemory byteAt: selectorOop + i + objectMemory baseHeaderSize - 1) = (breakSelector at: i) asInteger
				ifTrue: [(i := i - 1) = 0 ifTrue:
							[self compilationBreakpointFor: selectorOop]]
				ifFalse: [i := 0]]]
]

{ #category : #'debug support' }
CoInterpreter >> compilationBreakpointFor: selectorOop [
	<api>
	suppressHeartbeatFlag := true.
	self
		cCode: [self warning: 'compilation send break (heartbeat suppressed)']
		inSmalltalk: [self halt: 'Compilation of ', breakSelector]
]

{ #category : #'frame access' }
CoInterpreter >> contextInstructionPointer: theIP frame: theFP [
	"Answer a value to store in the InstructionPointer index of a context object for theIP and theFP.
	 Mapping native pcs to bytecode pcs is quite expensive, requiring a search through the method
	 map.  We mitigate this cost by deferring mapping until we really have to, which is when a context's
	 instruction pointer is accessed by Smalltalk code (either direct inst var access or through the
	 instVarAt: primitive).  But to defer mapping we have to be able to distinguish machine code from
	 bytecode pcs, which we do by using negative values for machine code pcs.  So if the frame is a
	 machine code one answer the negation of the offset in the cog method.

	 As a whorish performance hack we also include the block method offset in the pc of a block.
	 The least significant 16 bits are the native pc and the most significant 14 bits are the block
	 start, in block alignment units.  So when mapping back we can find the start of the block.

	 See mustMapMachineCodePC:context: for the code that does the actual mapping."
	<var: #theFP type: #'char *'>
	<inline: false>
	self assert: (self validInstructionPointer: theIP inFrame: theFP).
	(self isMachineCodeFrame: theFP) ifTrue:
		[^self encodedNativePCOf: theIP cogMethod: (self mframeCogMethod: theFP)].
	^objectMemory integerObjectOf: (theIP = cogit ceReturnToInterpreterPC
							ifTrue: [self iframeSavedIP: theFP]
							ifFalse: [theIP])
						- (self iframeMethod: theFP)
						- objectMemory baseHeaderSize
						+ 2
]

{ #category : #'frame access' }
CoInterpreter >> convertToMachineCodeFrame: cogHomeMethod bcpc: bcpc [
	<var: #cogHomeMethod type: #'CogMethod *'>
	<returnTypeC: #usqInt>
	"Convert the current interpreter frame into a machine code frame
	 and answer the machine code pc matching bcpc."
	| startBcpc methodField closure cogMethod pc |
	<var: #cogMethod type: #'CogBlockMethod *'>
	<var: #p type: #'char *'>
	self assert: (self isMachineCodeFrame: framePointer) not.
	"Update the return pc, perhaps saving it in the caller's iframeSavedIP."
	(self isBaseFrame: framePointer)
		ifTrue:
			[stackPages
				longAt: framePointer + FoxCallerSavedIP
				put: cogit ceBaseFrameReturnPC]
		ifFalse:
			[(self isMachineCodeFrame: (self frameCallerFP: framePointer)) ifFalse:
				[self iframeSavedIP: (self frameCallerFP: framePointer)
					put: (self frameCallerSavedIP: framePointer) asInteger.
				 stackPages
					longAt: framePointer + FoxCallerSavedIP
					put: cogit ceReturnToInterpreterPC]].
	"Compute the cog method field"
	(self iframeIsBlockActivation: framePointer)
		ifTrue:
			[closure := self pushedReceiverOrClosureOfFrame: framePointer.
			 (self isVanillaBlockClosure: closure)
				ifTrue:
					[startBcpc := self startPCOfClosure: closure.
					 cogMethod := cogit
										findMethodForStartBcpc: startBcpc
										inHomeMethod: cogHomeMethod]
				ifFalse:
					[startBcpc := self startPCOfMethodHeader: cogHomeMethod methodHeader.
					 cogMethod := self cCoerceSimple: cogHomeMethod to: #'CogBlockMethod *'].
			 methodField := cogMethod asInteger + MFMethodFlagIsBlockFlag]
		ifFalse:
			[startBcpc := self startPCOfMethodHeader: cogHomeMethod methodHeader.
			 cogMethod := self cCoerceSimple: cogHomeMethod to: #'CogBlockMethod *'.
			 methodField := cogHomeMethod asInteger].
	"compute the pc before converting the frame to help with debugging."
	pc := cogit mcPCForBackwardBranch: bcpc startBcpc: startBcpc in: cogMethod.
	self assert: pc > (cogMethod asUnsignedInteger + cogit noCheckEntryOffset).
	self assert: bcpc = (cogit bytecodePCFor: pc startBcpc: startBcpc in: cogMethod).
	"now convert to a machine code frame"
	stackPages
		longAt: framePointer + FoxMethod
		put: methodField
			+ ((self iframeHasContext: framePointer)
				ifTrue: [MFMethodFlagHasContextFlag]
				ifFalse: [0]).
	framePointer + FoxIFReceiver to: stackPointer by: objectMemory wordSize negated do:
		[:p|
		stackPages longAt: p + FoxMFReceiver - FoxIFReceiver put: (stackPages longAt: p)].
	stackPointer := stackPointer + FoxMFReceiver - FoxIFReceiver.
	^pc
]

{ #category : #'stack pages' }
CoInterpreter >> defaultNativeStackFrameSize [
	<api>
	^ super defaultNativeStackFrameSize
]

{ #category : #'process primitive support' }
CoInterpreter >> deferStackLimitSmashAround: functionSymbol [
	"Defer smashes of the stackLimit around the call of functionSymbol (for assert checks)"
	<var: #functionSymbol declareC: 'void (*functionSymbol)(void)'>
	deferSmash := true.
	self perform: functionSymbol.
	deferSmash := false.
	deferredSmash ifTrue:
		[deferredSmash := false.
		 self forceInterruptCheck].
	^true "called from assert"
]

{ #category : #'process primitive support' }
CoInterpreter >> deferStackLimitSmashAround: functionSymbol with: arg [
	"Defer smashes of the stackLimit around the call of functionSymbol (for assert checks)"
	<var: #functionSymbol declareC: 'void (*functionSymbol)(sqInt)'>
	deferSmash := true.
	self sqLowLevelMFence.
	self perform: functionSymbol with: arg.
	deferSmash := false.
	self sqLowLevelMFence.
	deferredSmash ifTrue:
		[deferredSmash := false.
		 self sqLowLevelMFence.
		 self forceInterruptCheck].
	^true "called from assert"
]

{ #category : #'frame access' }
CoInterpreter >> divorceAMachineCodeFrameWithCogMethod: cogMethod in: aStackPage [
	"Divorce at most one frame in the current page (since the divorce may cause the page to be split)
	 and answer whether a frame was divorced."
	<var: #cogMethod type: #'CogMethod *'>
	<var: #aStackPage type: #'StackPage *'>
	| theFP calleeFP theSP theContext |
	<var: #aStackPage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<var: #calleeFP type: #'char *'>
	<var: #theSP type: #'char *'>

	theFP := aStackPage headFP.
	theSP := aStackPage headSP.
	theSP := theSP + objectMemory wordSize. "theSP points at hottest item on frame's stack"

	[((self isMachineCodeFrame: theFP)
	  and: [cogMethod = (self mframeHomeMethod: theFP)]) ifTrue:
		[theContext := self ensureFrameIsMarried: theFP SP: theSP.
		 self externalDivorceFrame: theFP andContext: theContext.
		 ^true].
	 calleeFP := theFP.
	 theFP := self frameCallerFP: theFP.
	 theFP ~= 0] whileTrue:
		["theSP points at stacked hottest item on frame's stack"
		 theSP := self frameCallerSP: calleeFP].

	^false
]

{ #category : #'frame access' }
CoInterpreter >> divorceMachineCodeFramesWithMethod: methodObj [
	| cogMethod divorcedSome |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self cogMethodOf: methodObj.
	[stackPage ~= 0 ifTrue: "This is needed for the assert in externalDivorceFrame:andContext:"
		[stackPages markStackPageMostRecentlyUsed: stackPage].
	 "Slang can't currently cope with the lack of the variable here.
	  Something to do with the preceding statement.  Take it out
	  and the code is good.  leave it in and we get do { ... } while(l1:)"
	 divorcedSome := self divorceSomeMachineCodeFramesWithMethod: cogMethod.
	 divorcedSome] whileTrue
]

{ #category : #'frame access' }
CoInterpreter >> divorceSomeMachineCodeFramesWithMethod: cogMethod [
	"Divorce at most one frame (since the divorce may cause the containing
	 page to be split) and answer whether a frame was divorced."
	<var: #cogMethod type: #'CogMethod *'>
	| divorcedSome |
	<var: #aPage type: #'StackPage *'>
	divorcedSome := false.
	0 to: numStackPages - 1 do:
		[:i| | aPage |
		aPage := stackPages stackPageAt: i.
		(stackPages isFree: aPage) ifFalse:
			["this to avoid assert in externalDivorceFrame:andContext:"
			 stackPages markStackPageMostRecentlyUsed: stackPage.
			 (self divorceAMachineCodeFrameWithCogMethod: cogMethod in: aPage) ifTrue:
				[divorcedSome := true]]].
	^divorcedSome
]

{ #category : #'debug support' }
CoInterpreter >> dumpPrimTraceLog [
	"The prim trace log is a circular buffer of entries. If there is
	 an entry at primTraceLogIndex \\ PrimTraceLogSize it has entries.
	 If there is something at primTraceLogIndex it has wrapped."

	<api>
	<inline: false>
	(primTraceLog at: (self safe: primTraceLogIndex - 1 mod: PrimTraceLogSize)) = 0 ifTrue: [^self].
	(primTraceLog at: primTraceLogIndex) ~= 0 ifTrue:
		[primTraceLogIndex to: PrimTraceLogSize - 1 do:
			[:i | self printPrimLogEntryAt: i; cr]].
	0 to: primTraceLogIndex - 1 do:
		[:i | self printPrimLogEntryAt: i; cr]
]

{ #category : #'debug support' }
CoInterpreter >> dumpTraceLog [
	<api>
	"The trace log is a circular buffer of pairs of entries. If there is
	 an entry at traceLogIndex - 3 \\ TraceBufferSize it has entries.
	 If there is something at traceLogIndex it has wrapped."
	<inline: false>
	(traceLog at: (self safe: traceLogIndex - 3 mod: TraceBufferSize)) = 0 ifTrue: [^self].
	(traceLog at: traceLogIndex) ~= 0 ifTrue:
		[traceLogIndex to: TraceBufferSize - 3 by: 3 do:
			[:i| self printLogEntryAt: i]].

	0 to: traceLogIndex - 3 by: 3 do:
		[:i| self printLogEntryAt: i]
]

{ #category : #'frame access' }
CoInterpreter >> encodedNativePCOf: mcpc cogMethod: cogMethod [
	"Encode the mcpc in cogMethod as a value that can be stashed in a context.
	 Mapping native pcs to bytecode pcs is quite expensive, requiring a search
	 through the method map.  We mitigate this cost by deferring mapping until
	 we really have to, which is when a context's instruction pointer is accessed
	 by Smalltalk code.  But to defer mapping we have to be able to distinguish
	 machine code from bytecode pcs, which we do by using negative values for
	 machine code pcs.

	 As a whorish performance hack we also include the block method offset in
	 the pc of a block. The least significant 16 bits are the native pc and the most
	 significant 15 bits are the block start, in block alignment units.  So when
	 mapping back we can find the start of the block.

	 See mustMapMachineCodePC:context: for the code that does the actual mapping."
	<var: #cogMethod type: #'CogBlockMethod *'>
	| homeMethod blockOffset |
	<var: #homeMethod type: #'CogMethod *'>
	mcpc = cogit ceCannotResumePC ifTrue:
		[^HasBeenReturnedFromMCPCOop].
	cogMethod cmType = CMMethod ifTrue:
		[^objectMemory integerObjectOf: cogMethod asInteger - mcpc].
	homeMethod := cogMethod cmHomeMethod.
	blockOffset := homeMethod asInteger - cogMethod asInteger / cogit blockAlignment.
	^objectMemory integerObjectOf: ((blockOffset bitShift: 16) bitOr: (cogMethod asInteger - mcpc bitAnd: 16rFFFF))
]

{ #category : #'frame access' }
CoInterpreter >> ensureAllContextsWithMethodHaveBytecodePCs: methodObj [
	"Map all native pcs to bytecoded pcs in all contexts on methodObj.
	 Used to implement primitiveVoidVMStateForMethod."
	objectMemory allObjectsDo:
		[:oop|
		 ((objectMemory isContextNonImm: oop)
		  and: [(objectMemory fetchPointer: MethodIndex ofObject: oop) = methodObj]) ifTrue:
			[self widowOrForceToBytecodePC: oop]]
]

{ #category : #'frame access' }
CoInterpreter >> ensureContextHasBytecodePC: aContext [
	"Make sure the context has a byetcode pc.  Can only be used on single contexts."
	| pc |
	self assert: (self isMarriedOrWidowedContext: aContext) not.
	pc := objectMemory fetchPointer: InstructionPointerIndex ofObject: aContext.
	((objectMemory isIntegerObject: pc)
	 and: [(pc := objectMemory integerValueOf: pc) < 0]) ifTrue:
		[pc := self mustMapMachineCodePC: pc context: aContext.
		 self assert: (self validBCPC: (objectMemory integerValueOf: pc) inMethod: (objectMemory fetchPointer: MethodIndex ofObject: aContext)).
		 objectMemory storePointerUnchecked: InstructionPointerIndex ofObject: aContext withValue: pc]
]

{ #category : #'frame access' }
CoInterpreter >> ensureContextIsExecutionSafeAfterAssignToStackPointer: aContext [
	"Safety to give the JIT lattitude in calling convention.  Conceptually, returning
	 a value to a context involves pushing that value onto the stack.  This is used
	 in Squeak methods such as ContextPart>>jump
		jump
			| top |
			thisContext sender push: nil.
			stackp = 0 ifTrue: [self stepToSendOrReturn].
			stackp = 0 ifTrue: [self push: nil].
			top := self pop.
			thisContext privSender: self.
			^top
	 Here jump may pop the value of a temporary variable off the stack which will,
	 conceptually and, in the interpreter, actually, get pushed back on return.  But
	 if the JIT is mapping the stack to registers disaster may ensue since the value
	 may not get pushed to the stack and code may access an invalid value (e.g. a pc).

	 The solution is to fall back on the interpreter.  If the stack pointer is changed we
	 also ensure the pc is a bytecode pc (+ive) which will cause makeBaseFrameFor:
	 to create an interpreter frame if the context is executed again."
	<inline: false>
	self ensureContextHasBytecodePC: aContext
]

{ #category : #'frame access' }
CoInterpreter >> ensureMethodIsCogged: methodObj maybeClosure: maybeClosure [
	"Ensure that methodObj has been cogged.  It may be a FullBlockMethod if maybeClosure is a FullBlockClosure."
	<returnTypeC: #'CogMethod *'>
	| rawHeader cogMethod yetToCompact |
	<inline: true>
	<var: #cogMethod type: #'CogMethod *'>
	rawHeader := self rawHeaderOf: methodObj.
	(self isCogMethodReference: rawHeader) ifTrue:
		[^self cCoerceSimple: rawHeader to: #'CogMethod *'].
	yetToCompact := true.
	[(maybeClosure ~= objectMemory nilObject and: [(self isVanillaBlockClosure: maybeClosure) not])
		ifTrue: [cogMethod := cogit cogFullBlockMethod: methodObj numCopied: (self copiedValueCountOfFullClosure: maybeClosure)]
		ifFalse: [cogMethod := cogit cog: methodObj selector: objectMemory nilObject].
	 cogMethod == nil
	 and: [cogCompiledCodeCompactionCalledFor
	 and: [yetToCompact]]] whileTrue:
		[yetToCompact := false.
		 self commenceCogCompiledCodeCompaction].
	(self asserta: cogMethod ~~ nil) ifFalse:
		[self error: 'could not compile method that should have been compiled'].
	^cogMethod
]

{ #category : #enilopmarts }
CoInterpreter >> ensurePushedInstructionPointer [
	"We're about to make some transition to a machine code method which
	 requires the instructionPointer must be on the stack.  We could have come
	 from the interpreter, either directly or via a machine code primitive.  We
	 could have come from machine code.  The instructionPointer tells us where
	 from.  Make sure the instruction pointer is pushed and/or saved."
	instructionPointer asUnsignedInteger >= objectMemory startOfMemory
		ifTrue:
			"invoked directly from the interpreter"
			[self iframeSavedIP: framePointer put: instructionPointer.
			 self push: cogit ceReturnToInterpreterPC]
		ifFalse:
			["instructionPointer == cogit ceReturnToInterpreterPC
				ifTrue: [invoked from the interpreter via a machine code primitive]
				ifFalse: [invoked from machine code].
			 If in the first case the bytecode instructionPointer has already been
			 saved in iframeSavedIP so all we need to do is push the instructionPointer."
			 self push: instructionPointer]
]

{ #category : #initialization }
CoInterpreter >> enterSmalltalkExecutiveImplementation [
	"Main entry-point into the interpreter at each execution level, where an execution
	 level is either the start of execution or reentry for a callback.  Capture the C stack
	 pointers so that calls from machine-code into the C run-time occur at this level.
	 This is the actual implementation, separated from enterSmalltalkExecutive so the
	 simulator can wrap it in an exception handler and hence simulate the setjmp/longjmp."
	<inline: false>
	cogit assertCStackWellAligned.
	cogit ceCaptureCStackPointers.
	"Setjmp for reentry into interpreter from elsewhere, e.g. machine-code trampolines."
	self sigset: reenterInterpreter jmp: 0.
	(self isMachineCodeFrame: framePointer) ifTrue:
		[self returnToExecutive: false postContextSwitch: true
		 "NOTREACHED"].
	self setMethod: (self iframeMethod: framePointer).
	instructionPointer = cogit ceReturnToInterpreterPC ifTrue:
		[instructionPointer := self iframeSavedIP: framePointer].
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: true line: #'__LINE__'.
	self interpret.
	^0
]

{ #category : #'cog jit support' }
CoInterpreter >> error: aString [
	<api: 'extern void error(char *s)'>
	<doNotGenerate>
	super error: aString
]

{ #category : #enilopmarts }
CoInterpreter >> executeCogBlock: cogMethod closure: closure mayContextSwitch: mayContextSwitch [
	"Execute a block within a CogMethod.  The caller has already pushed the block and
	 any arguments and the return pc.  First push the return-to-interpreter trampoline,
	 then the entry-point and finally the receiver.  We /do not/ push any register
	 argument(s) to reduce complications in block dispatch; effectively there are no
	 register arguments to blocks. Instead, the machine code block value primitives
	 push the reg args if necessary before dispatching to the block.  Hence here, only
	 the receiver gets pushed. See genPrimitiveClosureValue"
	<var: #cogMethod type: #'CogMethod *'>
	cogit assertCStackWellAligned.
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer.
	self ensurePushedInstructionPointer.
	self push: cogMethod asInteger
			+ (mayContextSwitch
				ifTrue: [cogMethod blockEntryOffset]
				ifFalse: [cogMethod blockEntryOffset - cogit noContextSwitchBlockEntryOffset]).
	self push: closure.
	cogit ceCallCogCodePopReceiverReg
	"NOTREACHED"
]

{ #category : #enilopmarts }
CoInterpreter >> executeCogMethod: cogMethod fromLinkedSendWithReceiver: rcvr [
	<api>
	"Execute a CogMethod from a linked send.  The receiver,
	 arguments and return address are on the Smalltalk stack.  First
	 push the entry-point and finally the register argument(s).  Then write
	 back the frame pointers and call the routine that will pop off the register
	 argument(s) and jump to the entry by executing a return instruction.

	 In the simple jit only the receiver gets passed in registers, so only the
	 receiver gets pushed."
	<var: #cogMethod type: #'CogMethod *'>
	cogit assertCStackWellAligned.
	self assert: (self isMachineCodeFrame: framePointer).
	self assertValidExecutionPointe: self stackTop r: framePointer s: stackPointer imbar: false line: #'__LINE__'.
	cogit numRegArgs > 0 ifTrue: "dont use and: so as to get Slang to inline cogit numRegArgs > 0"
		[cogMethod cmNumArgs <= cogit numRegArgs ifTrue:
			[self callRegisterArgCogMethod: cogMethod at: cogit entryOffset receiver: rcvr]].
	self
		push: cogMethod asInteger + cogit entryOffset;
		push: rcvr.
	cogit ceCallCogCodePopReceiverReg
	"NOTREACHED"
]

{ #category : #enilopmarts }
CoInterpreter >> executeCogMethod: cogMethod fromUnlinkedSendWithReceiver: rcvr [
	"Execute a CogMethod from an unlinked send.  The receiver,
	 arguments and return address are on the Smalltalk stack.  First
	 push the entry-point and finally the register argument(s).  Then write
	 back the frame pointers and call the routine that will pop off the register
	 argument(s) and jump to the entry by executing a return instruction.

	 In the simple jit only the receiver gets passed in registers, so only the
	 receiver gets pushed."
	<var: #cogMethod type: #'CogMethod *'>
	cogit assertCStackWellAligned.
	self assert: (self isMachineCodeFrame: framePointer).
	self assertValidExecutionPointe: self stackTop r: framePointer s: stackPointer imbar: false line: #'__LINE__'.
	cogit numRegArgs > 0 ifTrue: "dont use and: so as to get Slang to inline cogit numRegArgs > 0"
		[cogMethod cmNumArgs <= cogit numRegArgs ifTrue:
			[self callRegisterArgCogMethod: cogMethod at: cogit noCheckEntryOffset receiver: rcvr]].
	self
		push: cogMethod asInteger + cogit noCheckEntryOffset;
		push: rcvr.
	cogit ceCallCogCodePopReceiverReg
	"NOTREACHED"
]

{ #category : #enilopmarts }
CoInterpreter >> executeCogPIC: cogPIC fromLinkedSendWithReceiver: rcvr andCacheTag: cacheTag [
	<api>
	"Execute a closed PIC from a linked send, to redispatch based on the rcvr.
	 The receiver, arguments and return address are on the Smalltalk stack.
	 First push the entry-point and finally the register argument(s).  Then write
	 back the frame pointers and call the routine that will pop off the register
	 argument(s) and jump to the entry by executing a return instruction.

	 In the simple jit only the receiver gets passed in registers, so only the
	 receiver gets pushed."
	<var: #cogPIC type: #'CogMethod *'>
	cogit assertCStackWellAligned.
	self assert: (self isMachineCodeFrame: framePointer).
	self assertValidExecutionPointe: self stackTop r: framePointer s: stackPointer imbar: false line: #'__LINE__'.
	self push: cogPIC asInteger + cogit entryOffset.
	cogit numRegArgs > 0 ifTrue:"dont use and: so as to get Slang to inline cogit numRegArgs > 0"
		[cogPIC cmNumArgs <= cogit numRegArgs ifTrue:
			[self push: cacheTag.
			 cogPIC cmNumArgs caseOf: {
				[0]	->	[cogit ceCall0ArgsPIC].
				[1]	->	[cogit ceCall1ArgsPIC].
				[2]	->	[cogit ceCall2ArgsPIC]
			 	}
				otherwise: [].
			 self error: 'not reached']].
	self
		push: rcvr;
		push: cacheTag.
	cogit ceCallCogCodePopReceiverAndClassRegs
	"NOTREACHED"
]

{ #category : #enilopmarts }
CoInterpreter >> executeFullCogBlock: cogMethod closure: closure mayContextSwitch: mayContextSwitch [
	"Execute a FullBlockClosure with a CogMethod.  The caller has already pushed the block and
	 any arguments and the return pc.  First push the return-to-interpreter trampoline,
	 then the entry-point and finally the receiver.  We /do not/ push any register
	 argument(s) to reduce complications in block dispatch; effectively there are no
	 register arguments to blocks. Instead, the machine code block value primitives
	 push the reg args if necessary before dispatching to the block.  Hence here, only
	 the receiver gets pushed. See genPrimitiveClosureValue"
	<var: #cogMethod type: #'CogMethod *'>
	cogit assertCStackWellAligned.
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer.
	self ensurePushedInstructionPointer.
	self push: cogMethod asInteger 
		+ (mayContextSwitch
				ifTrue: [cogit fullBlockEntryOffset]
				ifFalse: [cogit fullBlockNoContextSwitchEntryOffset]).
	self push: closure.
	cogit ceCallCogCodePopReceiverReg
	"NOTREACHED"
]

{ #category : #'message sending' }
CoInterpreter >> executeNewMethod [
	"Execute newMethod - either primitiveFunctionPointer must be set directly
	 (i.e. from primitiveExecuteMethod et al), or it would have been set probing
	 the method cache (i.e. primitivePerform et al).
	 Eagerly compile it if appropriate so that doits are fast."
	| methodHeader inInterpreter |
	inInterpreter := instructionPointer >= objectMemory startOfMemory.
	primitiveFunctionPointer ~= 0 ifTrue:
		[self isPrimitiveFunctionPointerAnIndex ifTrue:
			[self externalQuickPrimitiveResponse.
			 self return: self popStack toExecutive: inInterpreter.
			 ^nil].
		 "slowPrimitiveResponse may of course context-switch.  If so we must reenter the
		  new process appopriately, returning only if we've reached here directly from the
		  interpreter and have found an interpreter frame.  The instructionPointer tells us
		  from whence we came."
		 self slowPrimitiveResponse ifTrue:
			[self return: self popStack toExecutive: inInterpreter.
			 ^nil]].
	"Eagerly compile it if appropriate so that doits are fast."
	methodHeader := self rawHeaderOf: newMethod.
	(self isCogMethodReference: methodHeader) ifFalse:
		[(self methodWithHeaderShouldBeCogged: methodHeader)
			ifTrue:
				[cogit cog: newMethod selector: objectMemory nilObject.
				 methodHeader := self rawHeaderOf: newMethod]
			ifFalse: [self maybeFlagMethodAsInterpreted: newMethod]].
	"if not primitive, or primitive failed, activate the method"
	(self isCogMethodReference: methodHeader)
		ifTrue:
			[instructionPointer asUnsignedInteger >= objectMemory startOfMemory ifTrue:
				[self iframeSavedIP: framePointer put: instructionPointer asInteger.
				 instructionPointer := cogit ceReturnToInterpreterPC].
			self activateCoggedNewMethod: inInterpreter]
		ifFalse:
			[self activateNewMethod]
]

{ #category : #'stack bytecodes' }
CoInterpreter >> extendedStoreBytecodePop: popBoolean [
	"Override to use itemporary:in:put:"
	| descriptor variableType variableIndex value |
	<inline: true>
	descriptor := self fetchByte.
	variableType := descriptor >> 6 bitAnd: 3.
	variableIndex := descriptor bitAnd: 63.
	value := self internalStackTop.
	popBoolean ifTrue: [ self internalPop: 1 ].
	variableType = 0 ifTrue:
		[objectMemory storePointerImmutabilityCheck: variableIndex ofObject: self receiver withValue: value.
		^ self fetchNextBytecode.].
	variableType = 1 ifTrue:
		[ self fetchNextBytecode.
		^self itemporary: variableIndex in: localFP put: value].
	variableType = 3 ifTrue:
		[self storeLiteralVariable: variableIndex withValue: value.
		^ self fetchNextBytecode.].
	self error: 'illegal store'
]

{ #category : #'return bytecodes' }
CoInterpreter >> externalAboutToReturn: resultOop through: aContext [
	| ourContext |
	<inline: true>
	ourContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
	self push: ourContext.
	self push: resultOop.
	self push: aContext.
	"The ceNonLocalReturnTrampoline pops its caller's return pc into instructionPointer.
	 In this uncommon case restore it, since a send's call pushes the instructionPointer (after the arguments)."
	self push: instructionPointer.
	^self
		ceSendAbort: (objectMemory splObj: SelectorAboutToReturn)
		to: ourContext
		numArgs: 2
]

{ #category : #'return bytecodes' }
CoInterpreter >> externalCannotReturn: resultOop from: aContext [
	<inline: true>
	self push: aContext.
	self push: resultOop.
	"Both ceBaseFrameReturnTrampoline & ceNonLocalReturnTrampoline pop
	 their caller's return pc into instructionPointer.  In this uncommon case restore
	 it, since a send's call pushes the instructionPointer (after the arguments)."
	self push: instructionPointer.
	^self
		ceSendAbort: (objectMemory splObj: SelectorCannotReturn)
		to: aContext
		numArgs: 1
]

{ #category : #'frame access' }
CoInterpreter >> externalInstVar: offset ofContext: aContext [
	"Fetch an instance variable from a maybe married context.
	 If the context is still married compute the value of the
	 relevant inst var from the spouse frame's state.

	 If the context is single but has a negative instruction pointer
	 recognise that the instruction pointer is actually into machine
	 code and convert it to the corresponding bytecode pc."
	<inline: false>
	| value |

	self assert: (objectMemory isContext: aContext).
	self assert: offset <= (ReceiverIndex + (self checkStackPointerForMaybeMarriedContext: aContext)).
	"method, closureOrNil & receiver need no special handling; only
	 sender, pc & stackp have to be computed for married contexts."
	(self isReadMediatedContextInstVarIndex: offset) ifFalse:
		[^objectMemory fetchPointer: offset ofObject: aContext].

	self externalWriteBackHeadFramePointers.
	(self isStillMarriedContext: aContext) ifTrue:
		[^self fetchPointer: offset ofMarriedContext: aContext].
	
	value := objectMemory fetchPointer: offset ofObject: aContext.
	(offset = InstructionPointerIndex
 	 and: [(objectMemory isIntegerObject: value)
 	 and: [value signedIntFromLong < 0]]) ifTrue:
		[^self mustMapMachineCodePC: (objectMemory integerValueOf: value) context: aContext].
	^value
]

{ #category : #'cog jit support' }
CoInterpreter >> externalWriteBackHeadStackPointer [
	self assert: (stackPointer < stackPage baseAddress
				and: [stackPointer > (stackPage realStackLimit - (LargeContextSlots * objectMemory bytesPerOop))]).
	stackPage headSP: stackPointer
]

{ #category : #utilities }
CoInterpreter >> externalizeIPandSP [
	"Copy the local instruction, stack and frame pointers to global variables for use in primitives and other functions outside the interpret loop."

	self assert: localIP asUnsignedInteger ~= cogit ceReturnToInterpreterPC.
	instructionPointer := self oopForPointer: localIP.
	stackPointer := localSP.
	framePointer := localFP
]

{ #category : #'debug support' }
CoInterpreter >> fastLogPrim: aSelectorOrImmediate [
	"Fast tracing of named primitives.  primTraceLogIndex is a byte variable.
	 aSelectorOrImmediate is a selector oop or one of TraceCodeCompaction et al.
	 primTraceLog has 256 entries.  In C the + 1 below is hence implicitly modulo 256."
	<inline: true>
	primTraceLog at: primTraceLogIndex put: aSelectorOrImmediate.
	self primTraceLogIndex: primTraceLogIndex + 1
]

{ #category : #'message sending' }
CoInterpreter >> findNewMethodInClassTag: classTagArg [
	"Find the compiled method to be run when the current messageSelector is
	 sent to the given classTag, setting the values of newMethod and primitiveIndex."
	| ok classTag |
	<inline: false>
	ok := self lookupInMethodCacheSel: messageSelector classTag: classTagArg.
	ok	ifTrue:
			[self ifAppropriateCompileToNativeCode: newMethod selector: messageSelector]
		ifFalse:
			["entry was not found in the cache; perhaps soemthing was forwarded."
			 classTag := classTagArg.
			 ((objectMemory isOopForwarded: messageSelector)
			  or: [objectMemory isForwardedClassTag: classTag]) ifTrue:
				[(objectMemory isOopForwarded: messageSelector) ifTrue:
					[messageSelector := self handleForwardedSelectorFaultFor: messageSelector].
				 (objectMemory isForwardedClassTag: classTag) ifTrue:
					[classTag := self handleForwardedSendFaultForTag: classTag].
				ok := self lookupInMethodCacheSel: messageSelector classTag: classTag.
				ok ifTrue:
					[^self ifAppropriateCompileToNativeCode: newMethod selector: messageSelector]].
			 "entry was not found in the cache; look it up the hard way "
			 lkupClass := objectMemory classForClassTag: classTag.
			 self lookupMethodInClass: lkupClass.
			 self addNewMethodToCache: lkupClass]
]

{ #category : #'method lookup cache' }
CoInterpreter >> flushAtCache [
	"There is no atCache in the CoInterpreter."
	<inline: true>
]

{ #category : #'object memory support' }
CoInterpreter >> flushBecommedClassesInMethodZone [
	<inline: true>
	cogit unlinkSendsLinkedForInvalidClasses
]

{ #category : #'plugin primitive support' }
CoInterpreter >> flushExternalPrimitiveOf: methodObj [
	"methodObj is a CompiledMethod containing an external primitive.
	 Flush the function address and session ID of the CM.  Override
	 to also flush the machine code call if one exists."
	<api>
	| primIdx |
	primIdx := super flushExternalPrimitiveOf: methodObj.
	(primIdx = PrimNumberExternalCall
	 and: [self methodHasCogMethod: methodObj]) ifTrue:
		[cogit
			rewritePrimInvocationIn: (self cogMethodOf: methodObj)
			to: #primitiveExternalCall]
]

{ #category : #'method lookup cache' }
CoInterpreter >> flushMethodCache [
	"Flush the method cache. The method cache is flushed on every programming change and garbage collect."

	super flushMethodCache.
	cogit unlinkAllSends
]

{ #category : #'message sending' }
CoInterpreter >> followForwardedFieldsInCurrentMethod [
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	<inline: false>
	(self isMachineCodeFrame: framePointer)
		ifTrue:
			[cogMethod := self mframeHomeMethod: framePointer.
			 objectMemory
				followForwardedObjectFields: cogMethod methodObject
				toDepth: 0.
			 cogit followForwardedLiteralsIn: cogMethod]
		ifFalse:
			[objectMemory
				followForwardedObjectFields: method
				toDepth: 0]
]

{ #category : #'object memory support' }
CoInterpreter >> followForwardedMethodsInMethodZone [
	<inline: true>
	cogit followForwardedMethods
]

{ #category : #'object memory support' }
CoInterpreter >> followForwardingPointersInStackZone: theBecomeEffectsFlags [
	"Spur's become: is lazy, turning the becommed object into a forwarding object to the other.
	 The read-barrier is minimised by arranging that forwarding pointers will fail a method cache
	 probe, since notionally objects' internals are accessed only via sending messages to them,
	 the exception is primitives that access the internals of the non-receiver argument(s).

	 To avoid a read barrier on bytecode, literal and inst var fetch and non-local return, we scan
	 the receivers (including the stacked receiver for non-local return) and method references
	 in the stack zone and follow any forwarded ones.  This is of course way cheaper than
	 scanning all of memory as in the old become.

	 Override to handle machine code frames"
	| theIPPtr |
	<inline: false>
	<var: #theSP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #theIPPtr type: #usqInt>
	<var: #callerFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>

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
		[:i| | thePage theSP theFP callerFP oop offset |
		thePage := stackPages stackPageAt: i.
		thePage isFree ifFalse:
			[self assert: (self ifCurrentStackPageHasValidHeadPointers: thePage).
			 theFP := thePage headFP.
			 "Skip the instruction pointer on top of stack of inactive pages."
			 theIPPtr := thePage = stackPage ifTrue: [0] ifFalse: [thePage headSP asUnsignedInteger].
			 [self assert: (thePage addressIsInPage: theFP).
			  self assert: (theIPPtr = 0 or: [thePage addressIsInPage: theIPPtr asVoidPointer]).
			  (self isMachineCodeFrame: theFP)
				ifTrue:
					[oop := stackPages longAt: theFP + FoxMFReceiver.
					 (objectMemory isOopForwarded: oop) ifTrue:
						[stackPages
							longAt: theFP + FoxMFReceiver
							put: (objectMemory followForwarded: oop)].
					 self assert: (objectMemory isForwarded: (self mframeHomeMethod: theFP) methodObject) not]
				ifFalse:
					[oop := stackPages longAt: theFP + FoxIFReceiver.
					 (objectMemory isOopForwarded: oop) ifTrue:
						[stackPages
							longAt: theFP + FoxIFReceiver
							put: (objectMemory followForwarded: oop)].
					 oop := self iframeMethod: theFP.
					 (objectMemory isForwarded: oop) ifTrue:
						[| newOop |
						 newOop := objectMemory followForwarded: oop.
						 offset := newOop - oop.
						 (theIPPtr ~= 0
						  and: [(stackPages longAt: theIPPtr) > oop]) ifTrue:
							[stackPages
								longAt: theIPPtr
								put: (stackPages longAt: theIPPtr) + offset].
						stackPages
							longAt: theFP + FoxIFSavedIP
							put: (stackPages longAt: theFP + FoxIFSavedIP) + offset.
						stackPages
							longAt: theFP + FoxMethod
							put: (oop := newOop)]].
			  ((self frameHasContext: theFP)
			   and: [(objectMemory isForwarded: (self frameContext: theFP))]) ifTrue:
				[stackPages
					longAt: theFP + FoxThisContext
					put: (objectMemory followForwarded: (self frameContext: theFP))].
			  offset := self frameStackedReceiverOffset: theFP.
			  oop := stackPages longAt: theFP + offset.
			  (objectMemory isOopForwarded: oop) ifTrue:
				[stackPages
					longAt: theFP + offset
					put: (objectMemory followForwarded: oop)].
			  (callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
				[theIPPtr := (theFP + FoxCallerSavedIP) asUnsignedInteger.
				 theFP := callerFP].
			 "And finally follow the saved context and the caller context."
			 theSP := thePage baseAddress - objectMemory wordSize.
			 [theSP <= thePage baseAddress] whileTrue:
				[oop := stackPages longAt: theSP.
				 (objectMemory isForwarded: oop) ifTrue:
					[stackPages longAt: theSP put: (objectMemory followForwarded: oop)].
				 theSP := theSP + objectMemory wordSize]]]
]

{ #category : #'process primitive support' }
CoInterpreter >> forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter [
	"Do a returnToExecutive: inInterpreter postContextSwitch: true for a process primtive
	 being sure to sample the profile clock before making the switch."
	<inline: true>
	"If we are profiling, take accurate primitive measures"
	nextProfileTick > 0 ifTrue:
		[self checkProfileTick: newMethod].
	^self returnToExecutive: inInterpreter postContextSwitch: true
]

{ #category : #'process primitive support' }
CoInterpreter >> forceInterruptCheckFromHeartbeat [
	"Force an interrupt check ASAP. This version is the
	 entry-point to forceInterruptCheck for the heartbeat
	 timer to allow for repeatable debugging."
	suppressHeartbeatFlag ifFalse:
		[self checkForLongRunningPrimitive.
		 self sqLowLevelMFence.
		 deferSmash
			ifTrue:
				[deferredSmash := true.
				 self sqLowLevelMFence]
			ifFalse:
				[self forceInterruptCheck]]
]

{ #category : #'frame access' }
CoInterpreter >> frameCallerContext: theFP [
	"In the StackInterpreter the saved ip field of a base frame holds the
	 base frame's caller context. But in the Cog VM the first word on the
	 stack holds the base frame's caller context, which is immediately
	 above the stacked receiver."
	<var: #theFP type: #'char *'>
	| thePage callerContextOrNil |
	<var: #thePage type: #'StackPage *'>
	self assert: (self isBaseFrame: theFP).
	thePage := stackPages stackPageFor: theFP.
	callerContextOrNil := stackPages longAt: thePage baseAddress.
	self assert: (objectMemory addressCouldBeObj: callerContextOrNil).
	self assert: (callerContextOrNil = objectMemory nilObject or: [objectMemory isContext: callerContextOrNil]).
	^callerContextOrNil
]

{ #category : #'frame access' }
CoInterpreter >> frameCallerContext: theFP put: aValue [
	"In the StackInterpreter the saved ip field of a base frame holds the
	 base frame's caller context. But in the Cog VM the first word on the
	 stack holds the base frame's caller context, which is immediately
	 above the stacked receiver."
	<var: #theFP type: #'char *'>
	<inline: true>
	self assert: (aValue = objectMemory nilObject or: [objectMemory isContext: aValue]).
	self assert: (self isBaseFrame: theFP).
	self assert: theFP + (self frameStackedReceiverOffset: theFP) + (2 * objectMemory wordSize) = (stackPages stackPageFor: theFP) baseAddress.
	self assert: (stackPages longAt: theFP + (self frameStackedReceiverOffset: theFP) + objectMemory wordSize) = (self frameContext: theFP).
	^stackPages
		longAt: theFP + (self frameStackedReceiverOffset: theFP) + (2 * objectMemory wordSize)
		put: aValue
]

{ #category : #'frame access' }
CoInterpreter >> frameHasContext: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^(self isMachineCodeFrame: theFP)
		ifTrue: [self mframeHasContext: theFP]
		ifFalse: [self iframeHasContext: theFP]
]

{ #category : #'frame access' }
CoInterpreter >> frameIsBlockActivation: theFP [ "<Integer>"
	<inline: true>
	<var: #theFP type: #'char *'>
	^(self isMachineCodeFrame: theFP)
		ifTrue: [self mframeIsBlockActivation: theFP]
		ifFalse: [self iframeIsBlockActivation: theFP]
]

{ #category : #'frame access' }
CoInterpreter >> frameMethodField: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxMethod
]

{ #category : #'frame access' }
CoInterpreter >> frameMethodObject: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^(self isMachineCodeFrame: theFP)
		ifTrue: [(self mframeHomeMethod: theFP) methodObject]
		ifFalse: [self iframeMethod: theFP]
]

{ #category : #'frame access' }
CoInterpreter >> frameNumArgs: theFP [
	"See encodeFrameFieldHasContext:numArgs:"
	<inline: true>
	<var: #theFP type: #'char *'>
	^(self isMachineCodeFrame: theFP)
		ifTrue: [(self mframeCogMethod: theFP) cmNumArgs]
		ifFalse: [stackPages byteAt: theFP + FoxIFrameFlags + 1]
]

{ #category : #'frame access' }
CoInterpreter >> frameNumTemps: theFP [
	"For subclasses to redefine to implement different closure semantics."
	<var: #theFP type: #'char *'>
	^0
]

{ #category : #'trampoline support' }
CoInterpreter >> framePointerAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: framePointer) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #framePointer in: self]
]

{ #category : #'frame access' }
CoInterpreter >> frameReceiver: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^(self isMachineCodeFrame: theFP)
		ifTrue: [self mframeReceiver: theFP]
		ifFalse: [self iframeReceiver: theFP]
]

{ #category : #'frame access' }
CoInterpreter >> frameReceiverLocation: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^(self isMachineCodeFrame: theFP)
		ifTrue: [theFP + FoxMFReceiver]
		ifFalse: [theFP + FoxIFReceiver]
]

{ #category : #'object memory support' }
CoInterpreter >> freeUnmarkedMachineCode [
	"Free machine-code methods whose compiled methods are unmarked
	 (or open PICs whose selectors are not marked).
	 The stack pages have already been traced so any methods
	 of live stack activations have already been marked and traced."
	<doNotGenerate>
	cogit freeUnmarkedMachineCode
]

{ #category : #'plugin primitives' }
CoInterpreter >> functionForPrimitiveExternalCall: methodObj [
	"Arrange to call the external primitive directly.  The complication is arranging
	 that the call can be flushed, given that it is embedded in machine code."
	<returnTypeC: 'void (*functionForPrimitiveExternalCall(sqInt methodObj))(void)'>
	| lit index functionPointer |
	<var: #functionPointer declareC: #'void (*functionPointer)(void)'>
	cogit setPostCompileHook: #recordCallOffsetIn:.
	(objectMemory literalCountOf: methodObj) > 0 ifFalse:
		[^#primitiveExternalCall].
	lit := self literal: 0 ofMethod: methodObj. 
	"Check if it's an array of length 4"
	((objectMemory isArray: lit) and: [(objectMemory lengthOf: lit) = 4]) ifFalse:
		[^#primitiveExternalCall].
	index := objectMemory fetchPointer: 3 ofObject: lit.
	((objectMemory isIntegerObject: index)
	and: [(index := objectMemory integerValueOf: index) > 0
	and: [index <= MaxExternalPrimitiveTableSize]]) ifFalse:
		[^#primitiveExternalCall].
	functionPointer := externalPrimitiveTable at: index - 1.
	functionPointer = 0 ifTrue:
		[^#primitiveExternalCall].
	^functionPointer
]

{ #category : #'cog jit support' }
CoInterpreter >> functionPointerForCompiledMethod: methodObj primitiveIndex: primIndex [
	<api>
	<returnTypeC: 'void (*functionPointerForCompiledMethodprimitiveIndex(sqInt methodObj, sqInt primIndex))(void)'>
	| functionPointer |
	<var: #functionPointer declareC: #'void (*functionPointer)(void)'>
	functionPointer := self functionPointerFor: primIndex inClass: nil.
	functionPointer == #primitiveCalloutToFFI ifTrue:
		[^self functionForPrimitiveCallout].
	functionPointer == #primitiveExternalCall ifTrue:
		[^self functionForPrimitiveExternalCall: methodObj].
	^functionPointer
]

{ #category : #'object memory support' }
CoInterpreter >> gcMode [
	^gcMode
]

{ #category : #'as yet unclassified' }
CoInterpreter >> gcMode: anInteger [ 

	<doNotGenerate>
	gcMode := anInteger
]

{ #category : #'cog jit support' }
CoInterpreter >> getCheckAllocFiller [
	<api>
	^checkAllocFiller
]

{ #category : #'internal interpreter access' }
CoInterpreter >> getCodeCompactionCount [
	<cmacro: '() integerObjectOf(GIV(statCodeCompactionCount))'>
	^objectMemory integerObjectOf: statCodeCompactionCount
]

{ #category : #'internal interpreter access' }
CoInterpreter >> getCodeCompactionMSecs [
	<cmacro: '() integerObjectOf((GIV(statCodeCompactionUsecs) + 500) / 1000)'>
	^objectMemory integerObjectOf: statCodeCompactionUsecs + 500 // 1000
]

{ #category : #'internal interpreter access' }
CoInterpreter >> getCogCodeSize [
	<cmacro: '() integerObjectOf(GIV(cogCodeSize))'>
	^objectMemory integerObjectOf: cogCodeSize
]

{ #category : #'internal interpreter access' }
CoInterpreter >> getCogCodeZoneThreshold [
	<doNotGenerate>
	<returnTypeC: #double>
	^cogit getCogCodeZoneThreshold
]

{ #category : #'internal interpreter access' }
CoInterpreter >> getCogMethodCount [
	^objectMemory integerObjectOf: (cogMethodZone numMethodsOfType: CMMethod)
]

{ #category : #'internal interpreter access' }
CoInterpreter >> getCogVMFlags [
	"Answer an array of flags indicating various properties of the Cog VM.
	 These are the same as the image header flags shifted right two bits (excluding float order and full screen flags).
	 Bit 0: specific to CoInterpreterMT
	 Bit 1: if set, methods that are interpreted will have the flag bit set in their header
	 Bit 2: if set, implies preempting a process does not put it to the back of its run queue
	 Bit 3: specific to CoInterpreterMT
	 Bit 4: if set, implies the new finalization scheme where WeakArrays are queued
	 Bit 5: if set, implies wheel events will be delivered as such and not mapped to arrow key events"
	^objectMemory integerObjectOf: (flagInterpretedMethods ifTrue: [2] ifFalse: [0])
									+ (preemptionYields ifTrue: [0] ifFalse: [4])
									+ (newFinalization ifTrue: [16] ifFalse: [0])
									+ (sendWheelEvents ifTrue: [32] ifFalse: [0])
									+ (imageHeaderFlags >> 2 bitClear: 2 + 4 + 16 + 32)
]

{ #category : #'interpreter shell' }
CoInterpreter >> getCurrentBytecode [
	"currentBytecode will be private to the main dispatch loop in the generated code.
	 This method allows the currentBytecode to be retrieved from global variables.
	 Override to answer -1 if we're not in an interpreter frame."

	^((stackPages couldBeFramePointer: framePointer)
	   and: [(self isMachineCodeFrame: framePointer) not])
		ifTrue: [objectMemory byteAt: instructionPointer]
		ifFalse: [-1]
]

{ #category : #'internal interpreter access' }
CoInterpreter >> getDesiredCogCodeSize [
	<cmacro: '() integerObjectOf(desiredCogCodeSize)'>
	^objectMemory integerObjectOf: desiredCogCodeSize
]

{ #category : #'object memory support' }
CoInterpreter >> getGCMode [
	^gcMode
]

{ #category : #'image save/restore' }
CoInterpreter >> getImageHeaderFlags [
	"Answer the flags that are contained in the 7th long of the image header."
	^fullScreenFlag "0 or 1"
	+ (VMBIGENDIAN ifTrue: [0] ifFalse: [2]) "this is the imageFloatsLittleEndian flag"
	+ (flagInterpretedMethods ifTrue: [8] ifFalse: [0])
	+ (preemptionYields ifTrue: [0] ifFalse: [16r10])
	+ (newFinalization ifTrue: [16r40] ifFalse: [0])
	+ (sendWheelEvents ifTrue: [16r80] ifFalse: [0])
	+ (imageHeaderFlags bitClear: 16rDB) "these are any flags we do not recognize"
]

{ #category : #'message sending' }
CoInterpreter >> handleForwardedSendFaultForReceiver: forwardedReceiver stackDelta: stackDelta [
	"Handle a send fault that may be due to a send to a forwarded object.
	 Unforward the receiver on the stack and answer it."
	<option: #SpurObjectMemory>
	| rcvrStackIndex rcvr |
	<inline: false>
	"should *not* be a super send, so the receiver should be forwarded."
	self assert: (objectMemory isOopForwarded: forwardedReceiver).
	rcvrStackIndex := argumentCount + stackDelta.
	self assert: (self stackValue: rcvrStackIndex) = forwardedReceiver.
	rcvr := objectMemory followForwarded: forwardedReceiver.
	self stackValue: rcvrStackIndex put: rcvr.
	self followForwardedFrameContents: framePointer
		stackPointer: stackPointer + (rcvrStackIndex + 1 * objectMemory wordSize). "don't repeat effort"
	(objectMemory isPointers: (self frameReceiver: framePointer)) ifTrue:
		[objectMemory
			followForwardedObjectFields: (self frameReceiver: framePointer)
			toDepth: 0].
	self followForwardedFieldsInCurrentMethod.
	^rcvr
]

{ #category : #'message sending' }
CoInterpreter >> handleMNU: selectorIndex InMachineCodeTo: rcvr classForMessage: classForMessage [
	"A message send from either an open PIC or an unlinked send has not  been
	 understood.  Create a message and execute the relevant resulting MNU method.
	 messageSelector is an implicit argument (yuck)."
	| errSelIdx classForThisMessage |
	self assert: (objectMemory addressCouldBeOop: rcvr).
	instructionPointer := self popStack.
	self createActualMessageTo: classForMessage.
	messageSelector := objectMemory splObj: selectorIndex.
	(self lookupInMethodCacheSel: messageSelector classTag: (objectMemory classTagForClass: lkupClass))
		ifTrue:"check for coggability because method is in the cache"
			[self
				ifAppropriateCompileToNativeCode: newMethod
				selector: messageSelector]
		ifFalse:
			[errSelIdx := self lookupMNUInClass: (classForThisMessage := lkupClass).
			 errSelIdx ~= 0 ifTrue:
				[selectorIndex = SelectorDoesNotUnderstand ifTrue:
					[self error: 'Recursive not understood error encountered'].
				 self push: instructionPointer.
				 ^self handleMNU: errSelIdx InMachineCodeTo: rcvr classForMessage: classForThisMessage]].
	(self maybeMethodHasCogMethod: newMethod) ifTrue:
		[self push: instructionPointer.
		 self executeCogMethod: (self cogMethodOf: newMethod)
			 fromUnlinkedSendWithReceiver: rcvr.
		 "NOTREACHED"
		 self assert: false].
	^self interpretMethodFromMachineCode
	"NOTREACHED"
]

{ #category : #accessing }
CoInterpreter >> heapBase [
	<cmacro: '() heapBase'>
	^heapBase
]

{ #category : #accessing }
CoInterpreter >> heapBase: anInteger [ 
	<doNotGenerate>
	heapBase := anInteger
]

{ #category : #'message sending' }
CoInterpreter >> ifAppropriateCompileToNativeCode: aMethodObj selector: selector [
	| methodHeader cogMethod |
	<inline: true>
	<var: #cogMethod type: #'CogMethod *'>
	methodHeader := self rawHeaderOf: aMethodObj.
	(self isCogMethodReference: methodHeader)
		ifTrue: "makeBaseFrame: can create cog methods with nil selectors."
			[cogMethod := self cCoerceSimple: methodHeader to: #'CogMethod *'.
			 cogMethod selector = objectMemory nilObject ifTrue:
				[cogit setSelectorOf: cogMethod to: selector]]
		ifFalse:
			[(self methodWithHeaderShouldBeCogged: methodHeader)
				ifTrue: [cogit cog: aMethodObj selector: selector]
				ifFalse: [self maybeFlagMethodAsInterpreted: aMethodObj]]
]

{ #category : #'jump bytecodes' }
CoInterpreter >> ifBackwardsCheckForEvents: offsetToJumpBytecode [
	"Backward jump means we're in a loop.
		- check for possible interrupts.
		- check for long-running loops and JIT if appropriate."
	| switched backwardJumpCountByte |
	<inline: true>
	offsetToJumpBytecode >= 0 ifTrue:
		[^self].

	localSP < stackLimit ifTrue:
		[self externalizeIPandSP.
		 switched := self checkForEventsMayContextSwitch: true.
		 self returnToExecutive: true postContextSwitch: switched.
		 self browserPluginReturnIfNeeded.
		 self internalizeIPandSP.
		 switched ifTrue:
			[^self]].

	"We use the least significant byte of the flags word (which is marked as an immediate) and
	 subtract two each time to avoid disturbing the least significant tag bit.  Since the byte is
	 initialized to 1 (on frame build), on first decrement it will become -1.  Trip when it reaches 1 again."
	backwardJumpCountByte := self iframeBackwardBranchByte: localFP.
	(backwardJumpCountByte := backwardJumpCountByte - 2) = 1
		ifTrue:
			[(self methodWithHeaderShouldBeCogged: (objectMemory methodHeaderOf: method)) ifTrue:
				[self externalizeIPandSP.
				 self attemptToSwitchToMachineCode: (self oopForPointer: localIP) - offsetToJumpBytecode - method - objectMemory baseHeaderSize - 1
				 "If attemptToSwitchToMachineCode: returns the method could not be cogged, hence..."].
			 "can't cog method; avoid asking to cog it again for the longest possible time."
			 backwardJumpCountByte := 16r7F]
		ifFalse:
			[backwardJumpCountByte = -1 ifTrue: "initialize the count"
				[self assert: minBackwardJumpCountForCompile <= 128.
				 backwardJumpCountByte := minBackwardJumpCountForCompile - 1 << 1 + 1]].
	self iframeBackwardBranchByte: localFP put: backwardJumpCountByte
]

{ #category : #'debug support' }
CoInterpreter >> ifValidWriteBackStack: theCFP Pointers: theCSP Save: savedFPP To: savedSPP [
	"This is for low-level error reporting.  If either of the C stack pointers are
	 pointing into the stack zone then write them back to framePointer and/or
	 stackPointer so that the stack backtrace will be up to date.  Write their
	 original values through savedFPP & savedSPP if non-null."
	<api>
	<var: #theCFP type: #'void *'>
	<var: #theCSP type: #'void *'>
	<var: #savedFPP type: #'char **'>
	<var: #savedSPP type: #'char **'>
	<returnTypeC: #void>
	savedFPP ~= 0 ifTrue:
		[savedFPP at: 0 put: framePointer].
	savedSPP ~= 0 ifTrue:
		[savedSPP at: 0 put: stackPointer].
	(self couldBeFramePointer: theCFP) ifTrue:
		[framePointer := theCFP].
	(self couldBeFramePointer: theCSP) ifTrue:
		[stackPointer := theCSP]
]

{ #category : #'frame access' }
CoInterpreter >> iframeBackwardBranchByte: theFP [
	"See encodeFrameFieldHasContext:numArgs: and ifBackwardsCheckForEvents:"
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages byteAt: theFP + (VMBIGENDIAN ifTrue: [FoxIFrameFlags + objectMemory wordSize - 1] ifFalse: [FoxIFrameFlags])
]

{ #category : #'frame access' }
CoInterpreter >> iframeBackwardBranchByte: theFP put: aByte [
	"See encodeFrameFieldHasContext:numArgs: and ifBackwardsCheckForEvents:"
	<inline: true>
	<var: #theFP type: #'char *'>
	stackPages
		byteAt: theFP + (VMBIGENDIAN ifTrue: [FoxIFrameFlags + objectMemory wordSize - 1] ifFalse: [FoxIFrameFlags])
		put: aByte
]

{ #category : #'frame access' }
CoInterpreter >> iframeHasContext: theFP [
	"See encodeFrameFieldHasContext:numArgs:"
	<inline: true>
	<var: #theFP type: #'char *'>
	^(stackPages byteAt: theFP + FoxIFrameFlags + 2) ~= 0
]

{ #category : #'frame access' }
CoInterpreter >> iframeIsBlockActivation: theFP [ "<Integer>"
	<inline: true>
	<var: #theFP type: #'char *'>
	^(stackPages byteAt: theFP + FoxIFrameFlags + 3) ~= 0
]

{ #category : #'frame access' }
CoInterpreter >> iframeNumArgs: theFP [
	"See encodeFrameFieldHasContext:numArgs:"
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages byteAt: theFP + FoxIFrameFlags + 1
]

{ #category : #'frame access' }
CoInterpreter >> iframeReceiver: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxIFReceiver
]

{ #category : #'frame access' }
CoInterpreter >> iframeSavedIP: theFP [
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxIFSavedIP
]

{ #category : #'frame access' }
CoInterpreter >> iframeSavedIP: theFP put: savedIP [
	<var: #theFP type: #'char *'>
	self assert: (self isMachineCodeFrame: theFP) not.
	stackPages longAt: theFP + FoxIFSavedIP put: savedIP
]

{ #category : #initialization }
CoInterpreter >> initStackPagesAndInterpret [
	"Initialize the stack pages and enter interpret. Use alloca'ed memory so that when
	 we have a JIT its stack pointer will be on the native stack since alloca allocates
	 memory on the stack. Certain thread systems use the native stack pointer as the
	 frame ID so putting the stack anywhere else can confuse the thread system."

	"Override to establish the setjmp/longjmp handler for reentering the interpreter
	 from machine code, and disable executablity on the heap and stack pages."

	"This should be in its own initStackPages method but Slang can't inline
	 C code strings."
	| stackPageBytes stackPagesBytes theStackMemory |
	<var: #theStackMemory type: #'char *'>
	stackPageBytes := self stackPageByteSize.
	stackPagesBytes := self computeStackZoneSize.
	theStackMemory := self
							cCode: [self alloca: stackPagesBytes]
							inSmalltalk: [stackPages initializeWithByteSize: stackPagesBytes for: self].
	self cCode: [self me: theStackMemory ms: 0 et: stackPagesBytes].
	self sqMakeMemoryNotExecutableFrom: objectMemory startOfMemory asUnsignedInteger
		To: objectMemory memoryLimit asUnsignedInteger.
	self sqMakeMemoryNotExecutableFrom: theStackMemory asUnsignedInteger
		To: theStackMemory asUnsignedInteger + stackPagesBytes.
	stackPages
		initializeStack: theStackMemory
		numSlots: stackPagesBytes / objectMemory wordSize
		pageSize: stackPageBytes / objectMemory wordSize.
	self assert: self minimumUnusedHeadroom = stackPageBytes.

	"Once the stack pages are initialized we can continue to bootstrap the system."
	self loadInitialContext.
	"We're ready for the heartbeat (poll interrupt)"
	self ioInitHeartbeat.
	self initialEnterSmalltalkExecutive.
	^nil
]

{ #category : #initialization }
CoInterpreter >> initializeCodeGenerator [
	cogit
		initializeCodeZoneFrom: (self cCode: [objectMemory memory] inSmalltalk: [objectMemory cogCodeBase])
		upTo: (self cCode: [objectMemory memory] inSmalltalk: [objectMemory cogCodeBase]) + cogCodeSize
]

{ #category : #'frame access' }
CoInterpreter >> instVar: offset ofContext: aContext [
	"Fetch an instance avriable from a maybe married context.
	 If the context is still married compute the value of the
	 relevant inst var from the spouse frame's state.

	 If the context is single but has a negative instruction pointer
	 recognise that the instruction pointer is actually into machine
	 code and convert it to the corresponding bytecode pc."
	| value spouseFP |
	<var: #spouseFP type: #'char *'>
	<inline: true>
	self assert: offset < MethodIndex.
	self assert: (objectMemory isContext: aContext).
	self writeBackHeadFramePointers.
	(self isMarriedOrWidowedContext: aContext) ifFalse:
		[value := objectMemory fetchPointer: offset ofObject: aContext.
		 (offset = InstructionPointerIndex
		  and: [(objectMemory isIntegerObject: value)
		  and: [value signedIntFromLong < 0]]) ifTrue:
			[value := self internalMustMapMachineCodePC: (objectMemory integerValueOf: value)
						context: aContext].
		 ^value].

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

{ #category : #'cog jit support' }
CoInterpreter >> instructionPointer [
	<doNotGenerate>
	^instructionPointer
]

{ #category : #'cog jit support' }
CoInterpreter >> instructionPointer: aValue [
	<doNotGenerate>
	instructionPointer := aValue
]

{ #category : #'trampoline support' }
CoInterpreter >> instructionPointerAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: instructionPointer) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #instructionPointer in: self]
]

{ #category : #'frame access' }
CoInterpreter >> instructionPointerForFrame: spouseFP currentFP: currentFP currentIP: instrPtr [
	"Answer the bytecode pc object (i.e. SmallInteger) for an active frame.  The bytecode
	 pc is derived from the frame's pc.  If the frame is the top frame on the current stack
	 the frame pc is whatever the current instruction pointer is.  If the frame is the top
	 frame on some other stack the frame pc is the value on top of stack.  Otherwise the
	 frame pc is the saved pc of the frame above.  Once the frame pc is found it must be
	 mapped to a bytecode pc."
	<var: #spouseFP type: #'char *'>
	<var: #currentFP type: #'char *'>
	| value theIP thePage theFPAbove |
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
	value := self contextInstructionPointer: theIP frame: spouseFP.
	^value signedIntFromLong < 0
		ifTrue: [self mustMapMachineCodePC: (objectMemory integerValueOf: value)
					context: (self frameContext: spouseFP)]
		ifFalse: [value]
]

{ #category : #'message sending' }
CoInterpreter >> internalActivateNewMethod [
	| methodHeader numTemps rcvr switched |
	<inline: true>

	methodHeader := self rawHeaderOf: newMethod.
	self assert: (self isCogMethodReference: methodHeader) not.
	numTemps := self temporaryCountOfMethodHeader: methodHeader.
	self assert: argumentCount = (self argumentCountOfMethodHeader: methodHeader).
	rcvr := self internalStackValue: argumentCount. "could new rcvr be set at point of send?"
	self assert: (objectMemory isOopForwarded: rcvr) not.

	self internalPush: localIP.
	self internalPush: localFP.
	localFP := localSP.
	self internalPush: newMethod.
	self setMethod: newMethod methodHeader: methodHeader.
	self internalPush: objectMemory nilObject. "FxThisContext field"
	self internalPush: (self
						encodeFrameFieldHasContext: false
						isBlock: false
						numArgs: (self argumentCountOfMethodHeader: methodHeader)).
	self internalPush: 0. "FoxIFSavedIP"
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
		 switched := self handleStackOverflowOrEventAllowContextSwitch:
						(self canContextSwitchIfActivating: newMethod header: methodHeader).
		 self returnToExecutive: true postContextSwitch: switched.
		 self internalizeIPandSP]
]

{ #category : #'message sending' }
CoInterpreter >> internalExecuteNewMethod [
	<inline: true>
	"For interpreter performance and to ease the objectAsMethod implementation eagerly
	 evaluate the primtiive, i.e. if the method is cogged and has a primitive /do not/ evaluate
	 the machine code primitive, just evaluate primitiveFunctionPointer directly."
	primitiveFunctionPointer ~= 0 ifTrue:
		[| succeeded |
		 self isPrimitiveFunctionPointerAnIndex ifTrue:
			[^self internalQuickPrimitiveResponse].
		 "slowPrimitiveResponse may of course context-switch.  If so we must reenter the
		  new process appropriately, returning only if we've found an interpreter frame."
		 self externalizeIPandSP.
		 succeeded := self slowPrimitiveResponse.
		 instructionPointer = cogit ceReturnToInterpreterPC ifTrue:
			[instructionPointer := self iframeSavedIP: framePointer].
		 self internalizeIPandSP.
		 succeeded ifTrue:
			[self return: self popStack toExecutive: true.
			 self browserPluginReturnIfNeeded.
			^nil]].
	"if not primitive, or primitive failed, activate the method"
	(self methodHasCogMethod: newMethod)
		ifTrue: [self iframeSavedIP: localFP put: localIP asInteger.
				instructionPointer := cogit ceReturnToInterpreterPC.
				self externalizeFPandSP.
				self activateCoggedNewMethod: true.
				self internalizeIPandSP]
		ifFalse: [self internalActivateNewMethod]
]

{ #category : #'message sending' }
CoInterpreter >> internalFindNewMethodOrdinary [
	"Find the compiled method to be run when the current messageSelector is
	 sent to the given class, setting the values of newMethod and primitiveIndex."
	| ok |
	<inline: true>
	ok := self inlineLookupInMethodCacheSel: messageSelector classTag: lkupClassTag.
	ok	ifTrue:
			[self ifAppropriateCompileToNativeCode: newMethod selector: messageSelector]
		ifFalse:
			[self externalizeIPandSP.
			 ((objectMemory isOopForwarded: messageSelector)
			  or: [objectMemory isForwardedClassTag: lkupClassTag]) ifTrue:
				[(objectMemory isOopForwarded: messageSelector) ifTrue:
					[messageSelector := self handleForwardedSelectorFaultFor: messageSelector].
				 (objectMemory isForwardedClassTag: lkupClassTag) ifTrue:
					[lkupClassTag := self handleForwardedSendFaultForTag: lkupClassTag].
				(self lookupInMethodCacheSel: messageSelector classTag: lkupClassTag) ifTrue:
					[^self ifAppropriateCompileToNativeCode: newMethod selector: messageSelector]].
			lkupClass := objectMemory classForClassTag: lkupClassTag.
			self assert: (lkupClass notNil and: [self addressCouldBeClassObj: lkupClass]).
			self lookupMethodInClass: lkupClass.
			self internalizeIPandSP.
			self addNewMethodToCache: lkupClass]
]

{ #category : #'frame access' }
CoInterpreter >> internalMustMapMachineCodePC: theIP context: aOnceMarriedContext [
	"Must externalize before calling mustMapMachineCodePC:context:
	 because it may cause a code compaction."
	| result |
	self externalizeIPandSP.
	result := self mustMapMachineCodePC: theIP context: aOnceMarriedContext.
	self internalizeIPandSP.
	^result
]

{ #category : #utilities }
CoInterpreter >> internalizeIPandSP [
	"Copy the instruction, stack and frame pointers to local variables for rapid access within the interpret loop."

	self assert: instructionPointer ~= cogit ceReturnToInterpreterPC.
	localIP := self pointerForOop: instructionPointer.
	localSP := self pointerForOop: stackPointer.
	localFP := self pointerForOop: framePointer.
]

{ #category : #'trampoline support' }
CoInterpreter >> interpretAddress [
	"This is used for asserts that check that inline cache editing results in valid addresses.
	 In the C VM interpret is presumed to come before any primitives and so it constitutes
	 the lowest address in C code that machine code should be linked.  In the simulator
	 we just answer something not low."
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: #interpret) asUnsignedInteger]
		inSmalltalk: [heapBase]
]

{ #category : #'message sending' }
CoInterpreter >> interpretMethodFromMachineCode [
	"Execute a method interpretively from machine code.  We assume (require) that newMethod
	 messageSelector, primitiveFunctionPointer and argumentCount have been set in the caller.
	 Once evaluated either continue in the interpreter via a jongjmp or in machine code via an
	 enilopmart (a form of longjmp - a stinking rose by any other name)."
	<inline: false>
	cogit assertCStackWellAligned.
	self assert: (self validInstructionPointer: instructionPointer inFrame: framePointer).
	primitiveFunctionPointer ~= 0
		ifTrue:
			[primitiveFunctionPointer = #primitiveInvokeObjectAsMethod
				ifTrue: [self assert: (objectMemory isOopCompiledMethod: newMethod) not]
				ifFalse: [self assert: ((objectMemory isOopCompiledMethod: newMethod)
									  and: [(self primitiveIndexOf: newMethod) ~= 0])].
			 "Invoke an interpreter primitive (because the method is to be interpreted or has not yet been
			  compiled).  This is very similar to invoking an interpreter primitive from a compiled primitive
			  (see e.g. SimpleStackBasedCogit>>compileInterpreterPrimitive:).  Cut back the stack pointer
			  (done above) to skip the return address and invoke the function.  On return if it has succeeded
			  simply continue otherwise restore the stackPointer, collect the pc and interpret.  Note that
			  frame building primitives such as primitiveClosureValue, primitiveEvaluateMethod et al will not
			  return but will instead jump into either machine code or longjmp back to the interpreter."
			"Assign stackPage headFP so we can tell if the primitive built a frame.  We can't simply save
			 the framePointer since e.g. assignment to contexts (via primitiveInstVarAt:put:) can change the
			 framePointer.  But context assignments will change both the framePointer and stackPage headFP."
			
			 self assert: (framePointer < stackPage baseAddress
						and: [framePointer > (stackPage realStackLimit - (LargeContextSlots * objectMemory bytesPerOop / 2))]).
			 stackPage headFP: framePointer.
			 self isPrimitiveFunctionPointerAnIndex
				ifTrue:
					[self externalQuickPrimitiveResponse.
					 primFailCode := 0]
				ifFalse:
					[self slowPrimitiveResponse].
			self successful ifTrue:
				[self return: self popStack toExecutive: false
				 "NOTREACHED"]]
		ifFalse:
			[self assert: ((objectMemory isOopCompiledMethod: newMethod)
						   and: [(self primitiveIndexOf: newMethod) = 0
								or: [(self functionPointerFor: (self primitiveIndexOf: newMethod) inClass: objectMemory nilObject) = 0
								or: [self isNullExternalPrimitiveCall: newMethod]]])].
	"if not primitive, or primitive failed, activate the method and reenter the interpreter"
	self activateNewMethod.
	self siglong: reenterInterpreter jmp: ReturnToInterpreter.
	"NOTREACHED"
	^nil
]

{ #category : #'stack pages' }
CoInterpreter >> interpreterAllocationReserveBytes [
	"At a rough approximation we may need to allocate up to a couple
	 of page's worth of contexts when switching stack pages, assigning
	 to senders, etc.  But the snapshot primitive voids all stack pages.
	 So a safe margin is the size of a large context times the maximum
	 number of frames per page times the number of pages."
	<inline: #never>
	| maxUsedBytesPerPage maxFramesPerPage |
	maxUsedBytesPerPage := self stackPageFrameBytes + self stackLimitOffset.
	maxFramesPerPage := maxUsedBytesPerPage / objectMemory wordSize // MFrameSlots.
	^maxFramesPerPage * LargeContextSlots * objectMemory bytesPerOop * numStackPages
]

{ #category : #'internal interpreter access' }
CoInterpreter >> is: fieldIndex methodAssignmentToContextWithMachineCodePC: anOop [
	"If the method is assigned, any machine code pc must be mapped to a bytecode one
	 before the method is changed."
	<inline: true>
	| thePC |
	^fieldIndex = MethodIndex
	  and: [(thePC := objectMemory fetchPointer: InstructionPointerIndex ofObject: anOop) signedIntFromLong < 0
	  and: [objectMemory isIntegerObject: thePC]]
]

{ #category : #'internal interpreter access' }
CoInterpreter >> isCog [
	^true
]

{ #category : #'process primitive support' }
CoInterpreter >> isCogCompiledCodeCompactionCalledFor [
	"For in-image tests"
	^cogCompiledCodeCompactionCalledFor
]

{ #category : #'compiled methods' }
CoInterpreter >> isCogMethodReference: methodHeader [
	<api>
	self assert: ((objectMemory isIntegerObject: methodHeader)
				or: [methodHeader asUnsignedInteger < objectMemory startOfMemory
					and: [methodHeader asUnsignedInteger >= cogit minCogMethodAddress]]).
	^objectMemory isNonIntegerObject: methodHeader
]

{ #category : #'frame access' }
CoInterpreter >> isMachineCodeFrame: theFP [ 
	<var: #theFP type: #'char *'>
	^(stackPages longAt: theFP + FoxMethod) asUnsignedInteger < objectMemory startOfMemory
]

{ #category : #'debug support' }
CoInterpreter >> isMachineCodeIP: anInstrPointer [
	^anInstrPointer < objectMemory startOfMemory
]

{ #category : #simulation }
CoInterpreter >> isThreadedVM [
	<doNotGenerate>
	^false
]

{ #category : #'internal interpreter access' }
CoInterpreter >> itemporary: offset in: theFP [
	"Temporary access for an interpreter frame only."
	"See StackInterpreter class>>initializeFrameIndices"
	| frameNumArgs |
	<inline: true>
	<var: #theFP type: #'char *'>
	^offset < (frameNumArgs := self iframeNumArgs: theFP)
		ifTrue: [stackPages longAt: theFP + FoxCallerSavedIP + ((frameNumArgs - offset) * objectMemory wordSize)]
		ifFalse: [stackPages longAt: theFP + FoxIFReceiver - objectMemory wordSize + ((frameNumArgs - offset) * objectMemory wordSize)]
]

{ #category : #'internal interpreter access' }
CoInterpreter >> itemporary: offset in: theFP put: valueOop [
	"Temporary access for an interpreter frame only."
	"See StackInterpreter class>>initializeFrameIndices"
	| frameNumArgs |
	<inline: true>
	<var: #theFP type: #'char *'>
	^offset < (frameNumArgs := self iframeNumArgs: theFP)
		ifTrue: [stackPages longAt: theFP + FoxCallerSavedIP + ((frameNumArgs - offset) * objectMemory wordSize) put: valueOop]
		ifFalse: [stackPages longAt: theFP + FoxIFReceiver - objectMemory wordSize + ((frameNumArgs - offset) * objectMemory wordSize) put: valueOop]
]

{ #category : #'message sending' }
CoInterpreter >> justActivateNewMethod: mustBeInterpreterFrame [
	| methodHeader cogMethod numArgs numTemps rcvr initialIP |
	<var: #cogMethod type: #'CogMethod *'>
	<var: #initialIP type: #usqInt>
	<inline: true>
	methodHeader := self rawHeaderOf: newMethod.
	(mustBeInterpreterFrame not
	 and: [self isCogMethodReference: methodHeader]) ifTrue:
		[cogMethod := self cCoerceSimple: methodHeader to: #'CogMethod *'.
		 methodHeader := cogMethod methodHeader].
	numTemps := self temporaryCountOfMethodHeader: methodHeader.
	numArgs := self argumentCountOfMethodHeader: methodHeader.

	rcvr := self stackValue: numArgs. "could new rcvr be set at point of send?"
	self assert: (objectMemory isOopForwarded: rcvr) not.

	(cogMethod notNil
	and: [instructionPointer asUnsignedInteger >= objectMemory startOfMemory]) ifTrue:
		[self iframeSavedIP: framePointer put: instructionPointer.
		 instructionPointer := cogit ceReturnToInterpreterPC].
	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	initialIP := self initialIPForHeader: methodHeader method: newMethod.
	cogMethod
		ifNotNil:
			[self push: cogMethod asUnsignedInteger.
			 self push: objectMemory nilObject. "FoxThisContext field"
			 instructionPointer := cogMethod asUnsignedInteger + cogMethod stackCheckOffset]
		ifNil:
			[self push: newMethod.
			 self setMethod: newMethod methodHeader: methodHeader.
			 self push: objectMemory nilObject. "FoxThisContext field"
			 self push: (self encodeFrameFieldHasContext: false isBlock: false numArgs: numArgs).
			 self push: 0. "FoxIFSavedIP"
			 instructionPointer := initialIP - 1].
	self push: rcvr.

	"clear remaining temps to nil"
	numArgs+1 to: numTemps do:
		[:i | self push: objectMemory nilObject].

	(self methodHeaderHasPrimitive: methodHeader) ifTrue:
		["Skip the CallPrimitive bytecode, if it's there, and store the error code if the method starts
		  with a long store temp.  Strictly no need to skip the store because it's effectively a noop."
		 cogMethod ifNil:
			[instructionPointer := instructionPointer + (self sizeOfCallPrimitiveBytecode: methodHeader)].
		 primFailCode ~= 0 ifTrue:
			[self reapAndResetErrorCodeTo: stackPointer header: methodHeader]].

	^methodHeader
]

{ #category : #'stack bytecodes' }
CoInterpreter >> longPushTemporaryVariableBytecode [
	"230		11100110	i i i i i i i i	Push Temporary Variable #iiiiiiii"
	| index |
	index := self fetchByte.
	self fetchNextBytecode.
	self internalPush: (self itemporary: index in: localFP)
]

{ #category : #'stack bytecodes' }
CoInterpreter >> longStoreTemporaryVariableBytecode [
	"234		11101010	i i i i i i i i	Store Temporary Variable #iiiiiiii"
	| index |
	index := self fetchByte.
	self fetchNextBytecode.
	self itemporary: index in: localFP put: self internalStackTop
]

{ #category : #simulation }
CoInterpreter >> lookupAddress: address [
	"If address appears to be that of a Symbol or a few well-known objects (such as classes) answer it, otherwise answer nil.
	 For code disassembly"
	<doNotGenerate>
	(objectMemory lookupAddress: address) ifNotNil:
		[:lookup| ^lookup].
	address / objectMemory wordSize = primTraceLog offset ifTrue: [^'primTraceLog'].
	^nil
]

{ #category : #'cog jit support' }
CoInterpreter >> lookupMNU: selector receiver: rcvr [
	<api>
	"Lookup selector in rcvr, without doing MNU processing, and answer either a
	 method or an error code if the message was not understood.  Used to populate closed PICs."
	| classTag inCache erridx |
	"self printFrame: stackPage headFP WithSP: stackPage headSP"
	"self printStringOf: selector"
	classTag := objectMemory fetchClassTagOf: rcvr.
	inCache := self lookupInMethodCacheSel: selector classTag: classTag.
	inCache ifFalse:
		[messageSelector := selector.
		 erridx := self lookupMNUInClass: (objectMemory classForClassTag: classTag).
		 erridx ~= 0 ifTrue:
			[self assert: erridx <= self maxLookupNoMNUErrorCode.
			 ^erridx]].
	^newMethod
]

{ #category : #'cog jit support' }
CoInterpreter >> lookupOrdinary: selector receiver: rcvr [
	<api>
	"Lookup selector in rcvr, without doing MNU processing, and answer either a
	 method or an error code if the message was not understood.  Used to populate closed PICs."
	| classTag erridx |
	"self printFrame: stackPage headFP WithSP: stackPage headSP"
	"self printStringOf: selector"
	classTag := objectMemory fetchClassTagOf: rcvr.
	(self lookupInMethodCacheSel: selector classTag: classTag) ifFalse:
		[messageSelector := selector.
		 (erridx := self lookupOrdinaryNoMNUEtcInClass: (objectMemory classForClassTag: classTag)) ~= 0 ifTrue:
			[self assert: erridx <= self maxLookupNoMNUErrorCode.
			 ^erridx]].
	^newMethod
]

{ #category : #'cog jit support' }
CoInterpreter >> mMethodClass [
	<api>
	^self methodClassOf: (self mframeHomeMethod: framePointer) methodObject
]

{ #category : #'frame access' }
CoInterpreter >> makeBaseFrameFor: aContext [ "<Integer>"
	"Marry aContext with the base frame of a new stack page.  Build the base
	 frame to reflect the context's state.  Answer the new page.  Override to
	 hold the caller context in a different place,  In the StackInterpreter we use
	 the caller saved ip, but in the Cog VM caller saved ip is the ceBaseReturn:
	 trampoline.  Simply hold the caller context in the first word of the stack."
	<returnTypeC: #'StackPage *'>
	| page pointer theMethod theIP numArgs stackPtrIndex maybeClosure rcvr |
	<inline: false>
	<var: #page type: #'StackPage *'>
	<var: #pointer type: #'char *'>
	<var: #cogMethod type: #'CogMethod *'>
	"theIP must be typed as signed because it is assigned ceCannotResumePC and so maybe implicitly typed as unsigned."
	<var: #theIP type: #sqInt>
	self assert: (objectMemory isContext: aContext).
	self assert: (self isSingleContext: aContext).
	self assert: (objectMemory goodContextSize: aContext).
	theIP := objectMemory fetchPointer: InstructionPointerIndex ofObject: aContext.
	self assert: HasBeenReturnedFromMCPC < 0.
	theIP := (objectMemory isIntegerObject: theIP)
				ifTrue: [objectMemory integerValueOf: theIP]
				ifFalse: [HasBeenReturnedFromMCPC].
	theMethod := objectMemory followObjField: MethodIndex ofObject: aContext.
	page := stackPages newStackPage.
	"first word on stack is caller context of base frame"
	stackPages
		longAt: (pointer := page baseAddress)
		put: (objectMemory followObjField: SenderIndex ofObject: aContext).
	"second word is the context itself; needed for cannotReturn processing; see ceBaseReturn:."
	stackPages
		longAt: (pointer := pointer - objectMemory wordSize)
		put: aContext.
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
			 stackPages
				longAt: (pointer := pointer - objectMemory wordSize)
				put: maybeClosure]
		ifFalse:
			[| header |
			 header := objectMemory methodHeaderOf: theMethod.
			 numArgs := self argumentCountOfMethodHeader: header.
			 "If this is a synthetic context its IP could be pointing at the CallPrimitive opcode.  If so, skip it."
			 ((self methodHeaderHasPrimitive: header)
			  and: [theIP = (1 + (self startPCOfMethodHeader: header))]) ifTrue:
				[theIP := theIP + (self sizeOfCallPrimitiveBytecode: header)].
			 stackPages
				longAt: (pointer := pointer - objectMemory wordSize)
				put: rcvr].
	"Put the arguments on the stack"
	1 to: numArgs do:
		[:i|
		stackPages
			longAt: (pointer := pointer - objectMemory wordSize)
			put: (objectMemory fetchPointer: ReceiverIndex + i ofObject: aContext)].
	"saved caller ip is base return trampoline"
	stackPages
		longAt: (pointer := pointer - objectMemory wordSize)
		put: cogit ceBaseFrameReturnPC.
	"base frame's saved fp is null"
	stackPages
		longAt: (pointer := pointer - objectMemory wordSize)
		put: 0.
	"N.B.  Don't set the baseFP, which marks the page as in use, until after
	 ensureMethodIsCogged: and/or instructionPointer:forContext:frame:. These
	 can cause a compiled code compaction which, if marked as in use, will
	 examine this partially initialized page and crash."
	page headFP: pointer.
	"Create either a machine code frame or an interpreter frame based on the pc.  If the pc is -ve
	 it is a machine code pc and so we produce a machine code frame.  If +ve an interpreter frame.
	 N.B. Do *not* change this to try and map from a bytecode pc to a machine code frame under
	 any circumstances.  See ensureContextIsExecutionSafeAfterAssignToStackPointer:"
	theIP < 0
		ifTrue:
			[| cogMethod |
			 "Since we would have to generate a machine-code method to be able to map
			  the native pc anyway we should create a native method and native frame."
			 cogMethod := self ensureMethodIsCogged: theMethod maybeClosure: maybeClosure.
			 theMethod := cogMethod asInteger.
			 maybeClosure ~= objectMemory nilObject
				ifTrue:
					[(self isVanillaBlockClosure: maybeClosure)
						ifTrue:
							["If the pc is the special HasBeenReturnedFromMCPC pc set the pc
							  appropriately so that the frame stays in the cannotReturn: state."
							 theIP = HasBeenReturnedFromMCPC
								ifTrue:
									[theMethod := (cogit findMethodForStartBcpc: (self startPCOfClosure: maybeClosure)
														inHomeMethod: (self cCoerceSimple: theMethod
																			to: #'CogMethod *')) asInteger.
									 theMethod = 0 ifTrue:
										[self error: 'cannot find machine code block matching closure''s startpc'].
									 theIP := cogit ceCannotResumePC]
								ifFalse:
									[self assert: (theIP signedBitShift: -16) < -1. "See contextInstructionPointer:frame:"
									 theMethod := theMethod - ((theIP signedBitShift: -16) * cogit blockAlignment).
									 theIP := theMethod - theIP signedIntFromShort]]
						ifFalse:
							[self assert: (theIP signedBitShift: -16) >= -1.
							 "If the pc is the special HasBeenReturnedFromMCPC pc set the pc
							  appropriately so that the frame stays in the cannotReturn: state."
							 theIP := theIP = HasBeenReturnedFromMCPC
										ifTrue: [cogit ceCannotResumePC]
										ifFalse: [theMethod asInteger - theIP]].
					 stackPages
						longAt: (pointer := pointer - objectMemory wordSize)
						put: theMethod + MFMethodFlagHasContextFlag + MFMethodFlagIsBlockFlag]
				ifFalse:
					[self assert: (theIP signedBitShift: -16) >= -1.
					 "If the pc is the special HasBeenReturnedFromMCPC pc set the pc
					  appropriately so that the frame stays in the cannotReturn: state."
					 theIP := theIP = HasBeenReturnedFromMCPC
								ifTrue: [cogit ceCannotResumePC]
								ifFalse: [theMethod asInteger - theIP].
					 stackPages
						longAt: (pointer := pointer - objectMemory wordSize)
						put: theMethod + MFMethodFlagHasContextFlag].
			 stackPages
				longAt: (pointer := pointer - objectMemory wordSize)
				put: aContext]
		ifFalse:
			[stackPages
				longAt: (pointer := pointer - objectMemory wordSize)
				put: theMethod.
			stackPages
				longAt: (pointer := pointer - objectMemory wordSize)
				put: aContext.
			stackPages
				longAt: (pointer := pointer - objectMemory wordSize)
				put: (self encodeFrameFieldHasContext: true isBlock: maybeClosure ~= objectMemory nilObject numArgs: numArgs).
			stackPages
				longAt: (pointer := pointer - objectMemory wordSize)
				put: 0. "FoxIFSavedIP"
			theIP := self iframeInstructionPointerForIndex: theIP method: theMethod].
	page baseFP: page headFP.
	self assert: (self frameHasContext: page baseFP).
	self assert: (self frameNumArgs: page baseFP) == numArgs.
	stackPages
		longAt: (pointer := pointer - objectMemory wordSize)
		put: rcvr.
	stackPtrIndex := self quickFetchInteger: StackPointerIndex ofObject: aContext.
	self assert: ReceiverIndex + stackPtrIndex < (objectMemory lengthOf: aContext).
	numArgs + 1 to: stackPtrIndex do:
		[:i|
		stackPages
			longAt: (pointer := pointer - objectMemory wordSize)
			put: (objectMemory fetchPointer: ReceiverIndex + i ofObject: aContext).
		"nil the slot in the context so that it doesn't inadvertently hang onto some collectable object.
		 Thanks to Ryan Macnak for identifying this bug"
		objectMemory storePointerUnchecked: ReceiverIndex + i ofObject: aContext withValue: objectMemory nilObject].
	"top of stack is the instruction pointer"
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

{ #category : #'object memory support' }
CoInterpreter >> mapMachineCode: theGCMode [
	<inline: true>
	"Update all references to objects in machine code."
	cogit mapObjectReferencesInMachineCode: theGCMode
]

{ #category : #'debug support' }
CoInterpreter >> mapPrimTraceLog [
	"The prim trace log is a circular buffer of selectors. If there is
	 an entry at primTraceLogIndex - 1 \\ PrimTraceBufferSize it has entries.
	 If there is something at primTraceLogIndex it has wrapped."
	<inline: false>
	(primTraceLog at: (self safe: primTraceLogIndex - 1 mod: PrimTraceLogSize)) = 0 ifTrue:
		[^self].
	(primTraceLog at: primTraceLogIndex) ~= 0 ifTrue:
		[primTraceLogIndex to: PrimTraceLogSize - 1 do:
			[:i| | selector |
			 selector := primTraceLog at: i.
			 (selector ~= 0
			  and: [objectMemory shouldRemapOop: selector]) ifTrue:
				[primTraceLog at: i put: (objectMemory remapObj: selector)]]].
	0 to: primTraceLogIndex - 1 do:
		[:i| | selector |
		 selector := primTraceLog at: i.
		 (selector ~= 0
		  and: [objectMemory shouldRemapOop: selector]) ifTrue:
			[primTraceLog at: i put: (objectMemory remapObj: selector)]]
]

{ #category : #'object memory support' }
CoInterpreter >> mapStackPages [
	<inline: #never>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #frameRcvrOffset type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #theIPPtr type: #'char *'>
	| numLivePages |
	numLivePages := 0.
	0 to: numStackPages - 1 do:
		[:i| | thePage theSP theFP frameRcvrOffset callerFP theIPPtr theIP oop |
		thePage := stackPages stackPageAt: i.
		thePage isFree ifFalse:
			[self assert: (self ifCurrentStackPageHasValidHeadPointers: thePage).
			 numLivePages := numLivePages + 1.
			 theSP := thePage headSP.
			 theFP := thePage  headFP.
			 "Skip the instruction pointer on top of stack of inactive pages."
			 thePage = stackPage
				ifTrue: [theIPPtr := ((self isMachineCodeFrame: theFP)
									or: [(self iframeSavedIP: theFP) = 0])
										ifTrue: [0]
										ifFalse: [theFP + FoxIFSavedIP]]
				ifFalse:
					[theIPPtr := theSP.
					 theSP := theSP + objectMemory wordSize].
			[self assert: (thePage addressIsInPage: theFP).
			 self assert: (thePage addressIsInPage: theSP).
			 self assert: (theIPPtr = 0 or: [thePage addressIsInPage: theIPPtr]).
			 frameRcvrOffset := self frameReceiverLocation: theFP.
	 		  [theSP <= frameRcvrOffset] whileTrue:
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
			(self isMachineCodeFrame: theFP) ifFalse:
				[(objectMemory shouldRemapObj: (self iframeMethod: theFP)) ifTrue:
					[theIPPtr ~= 0 ifTrue:
						[theIP := stackPages longAt: theIPPtr.
						 theIP = cogit ceReturnToInterpreterPC
							ifTrue:
								[self assert: (self iframeSavedIP: theFP) > (self iframeMethod: theFP).
								 theIPPtr := theFP + FoxIFSavedIP.
								 theIP := stackPages longAt: theIPPtr]
							ifFalse:
								[self assert: theIP > (self iframeMethod: theFP)].
						 theIP := theIP - (self iframeMethod: theFP)].
					 stackPages
						longAt: theFP + FoxMethod
						put: (objectMemory remapObj: (self iframeMethod: theFP)).
					 theIPPtr ~= 0 ifTrue:
						[stackPages longAt: theIPPtr put: theIP + (self iframeMethod: theFP)]]].
			 (callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
				[theSP := (theIPPtr := theFP + FoxCallerSavedIP) + objectMemory wordSize.
				 theFP := callerFP].
			 theSP := theFP + FoxCallerSavedIP + objectMemory wordSize.
			 [theSP <= thePage baseAddress] whileTrue:
				[oop := stackPages longAt: theSP.
				 (objectMemory shouldRemapOop: oop) ifTrue:
					[stackPages longAt: theSP put: (objectMemory remapObj: oop)].
				 theSP := theSP + objectMemory wordSize]]].
	stackPages recordLivePagesOnMapping: numLivePages
]

{ #category : #'debug support' }
CoInterpreter >> mapTraceLog [
	"The trace log is a circular buffer of pairs of entries. If there is
	 an entry at traceLogIndex - 3 \\ TraceBufferSize it has entries.
	 If there is something at traceLogIndex it has wrapped."
	<inline: false>
	| limit |
	limit := self safe: traceLogIndex - 3 mod: TraceBufferSize.
	(traceLog at: limit) = 0 ifTrue: [^self].
	(traceLog at: traceLogIndex) ~= 0 ifTrue:
		[limit := TraceBufferSize - 3].
	0 to: limit by: 3 do:
		[:i| | intOrClass selectorOrMethod |
		intOrClass := traceLog at: i.
		(objectMemory shouldRemapOop: intOrClass) ifTrue:
			[traceLog at: i put: (objectMemory remapObj: intOrClass)].
		selectorOrMethod := traceLog at: i + 1.
		(objectMemory shouldRemapOop: selectorOrMethod) ifTrue:
			[traceLog at: i + 1 put: (objectMemory remapObj: selectorOrMethod)]]
]

{ #category : #'debug support' }
CoInterpreter >> mapTraceLogs [
	self mapTraceLog.
	self mapPrimTraceLog
]

{ #category : #'object memory support' }
CoInterpreter >> mapVMRegisters [
	"Map the oops in the interpreter's vm ``registers'' to their new values 
	 during garbage collection or a become: operation."
	"Assume: All traced variables contain valid oops.
	 N.B. Don't trace messageSelector and lkupClass; these are ephemeral, live
	 only during message lookup and because createActualMessageTo will not
	 cause a GC these cannot change during message lookup."
	| mapInstructionPointer |
	(objectMemory shouldRemapObj: method) ifTrue:
		["i.e. interpreter instructionPointer in method as opposed to machine code?"
		(mapInstructionPointer := instructionPointer > method) ifTrue:
			[instructionPointer := instructionPointer - method]. "*rel to method"
		method := objectMemory remapObj: method.
		mapInstructionPointer ifTrue:
			[instructionPointer := instructionPointer + method]]. "*rel to method"
	(objectMemory shouldRemapOop: newMethod) ifTrue: "maybe oop due to object-as-method"
		[newMethod := objectMemory remapObj: newMethod]
]

{ #category : #'cog jit support' }
CoInterpreter >> markActiveMethodsAndReferents [
	<api>
	| thePage |
	<var: #thePage type: #'StackPage *'>
	0 to: numStackPages - 1 do:
		[:i|
		thePage := stackPages stackPageAt: i.
		(stackPages isFree: thePage) ifFalse:
			[self markCogMethodsAndReferentsOnPage: thePage]]
]

{ #category : #'gc -- mark and sweep' }
CoInterpreter >> markAndTraceMachineCodeMethod: aCogMethod [
	<var: #aCogMethod type: #'CogBlockMethod *'>
	| homeMethod |
	<var: #homeMethod type: #'CogMethod *'>
	homeMethod := self asCogHomeMethod: aCogMethod.
	objectMemory markAndTrace: homeMethod methodObject
]

{ #category : #'object memory support' }
CoInterpreter >> markAndTraceMachineCodeOfMarkedMethods [
	"Deal with a fulGC's effects on machine code.  Mark and
	 trace oops in marked machine code methods.  The stack
	 pages have already been traced so any methods of live
	 stack activations have already been marked and traced."
	<doNotGenerate>
	cogit markAndTraceMachineCodeOfMarkedMethods
]

{ #category : #'debug support' }
CoInterpreter >> markAndTracePrimTraceLog [
	"The prim trace log is a circular buffer of selectors. If there is
	 an entry at primTraceLogIndex - 1 \\ PrimTraceBufferSize it has entries.
	 If there is something at primTraceLogIndex it has wrapped."
	<inline: false>
	(primTraceLog at: (self safe: primTraceLogIndex - 1 mod: PrimTraceLogSize)) = 0 ifTrue:
		[^self].
	(primTraceLog at: primTraceLogIndex) ~= 0 ifTrue:
		[primTraceLogIndex to: PrimTraceLogSize - 1 do:
			[:i| | selector |
			 selector := primTraceLog at: i.
			 (selector ~= 0
			  and: [objectMemory isNonImmediate: selector]) ifTrue:
				[objectMemory markAndTrace: selector]]].
	0 to: primTraceLogIndex - 1 do:
		[:i| | selector |
		selector := primTraceLog at: i.
		(selector ~= 0
		  and: [objectMemory isNonImmediate: selector]) ifTrue:
			[objectMemory markAndTrace: selector]]
]

{ #category : #'object memory support' }
CoInterpreter >> markAndTraceStackPage: thePage [
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
	(self isMachineCodeFrame: theFP)
		ifTrue: [self markAndTraceMachineCodeMethod: (self mframeCogMethod: theFP)]
		ifFalse: [objectMemory markAndTrace: (self iframeMethod: theFP)].
	(callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
		[theSP := theFP + FoxCallerSavedIP + objectMemory wordSize.
		 theFP := callerFP].
	theSP := theFP + FoxCallerSavedIP + objectMemory wordSize. "caller ip is ceBaseReturnPC"
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
CoInterpreter >> markAndTraceTraceLog [
	"The trace log is a circular buffer of pairs of entries. If there is an entry at
	 traceLogIndex - 3 \\ TraceBufferSize it has entries.  If there is something at
	 traceLogIndex it has wrapped."
	<inline: false>
	| limit |
	limit := self safe: traceLogIndex - 3 mod: TraceBufferSize.
	(traceLog at: limit) = 0 ifTrue: [^self].
	(traceLog at: traceLogIndex) ~= 0 ifTrue:
		[limit := TraceBufferSize - 3].
	0 to: limit by: 3 do:
		[:i| | oop |
		oop := traceLog at: i.
		(objectMemory isImmediate: oop) ifFalse:
			[objectMemory markAndTrace: oop].
		oop := traceLog at: i + 1.
		(objectMemory isImmediate: oop) ifFalse:
			[objectMemory markAndTrace: oop]]
]

{ #category : #'frame access' }
CoInterpreter >> markCogMethodsAndReferentsOnPage: thePage [
	<var: #thePage type: #'StackPage *'>
	| theFP callerFP |
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<inline: false>
	self assert: (stackPages isFree: thePage) not.
	self assert: (self ifCurrentStackPageHasValidHeadPointers: thePage).
	theFP := thePage headFP.
	"Skip the instruction pointer on top of stack of inactive pages."
	[(self isMachineCodeFrame: theFP) ifTrue:
		[cogit markMethodAndReferents: (self mframeCogMethod: theFP)].
	(callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
		[theFP := callerFP]
]

{ #category : #'frame access' }
CoInterpreter >> marryFrame: theFP SP: theSP copyTemps: copyTemps [
	"Marry an unmarried frame.  This means creating a spouse context
	 initialized with a subset of the frame's state that references the frame.
	 For the default closure implementation we do not need to copy temps.
	 Different closure implementations may require temps to be copied.

	 This method is important enough for performance to be worth streamlining.

	Override to set the ``has context'' flag appropriately for both machine code and interpreter frames
	and to streamline the machine code/interpreter differences.."
	| theContext methodFieldOrObj closureOrNil rcvr numSlots numArgs numStack numTemps |
	<inline: true>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #cogMethod type: #'CogMethod *'>
	self assert: (self frameHasContext: theFP) not.
	self assert: (self isBaseFrame: theFP) not. "base frames must aready be married for cannotReturn: processing"

	"The SP is expected to be pointing at the last oop on the stack, not at the pc"
	self assert: (objectMemory addressCouldBeOop: (objectMemory longAt: theSP)).

	"Decide how much of the stack to preserve in widowed contexts.  Preserving too much
	 state will potentially hold onto garbage.  Holding onto too little may mean that a dead
	 context isn't informative enough in a debugging situation.  If copyTemps is false (as it
	 is in the default closure implementation) compromise, retaining only the arguments with
	 no temporaries.  Note that we still set the stack pointer to its current value, but stack
	 contents other than the arguments are nil."
	methodFieldOrObj := self frameMethodField: theFP.
	methodFieldOrObj asUnsignedInteger < objectMemory startOfMemory "inline (self isMachineCodeFrame: theFP)"
		ifTrue:
			[| cogMethod |
			 stackPages
				longAt: theFP + FoxMethod
				put: methodFieldOrObj + MFMethodFlagHasContextFlag.
			 cogMethod := self cCoerceSimple: (methodFieldOrObj bitAnd: MFMethodMask) to: #'CogMethod *'.
			 numArgs := cogMethod cmNumArgs.
			 cogMethod cmType = CMMethod
				ifTrue:
					[closureOrNil := cogMethod cmIsFullBlock
										ifTrue: [self frameStackedReceiver: theFP numArgs: numArgs]
										ifFalse: [objectMemory nilObject]]
				ifFalse:
					[cogMethod := (self cCoerceSimple: cogMethod to: #'CogBlockMethod *') cmHomeMethod.
					 closureOrNil := self frameStackedReceiver: theFP numArgs: numArgs].
			 numSlots := (self methodHeaderIndicatesLargeFrame: cogMethod methodHeader)
							ifTrue: [LargeContextSlots]
							ifFalse: [SmallContextSlots].
			 methodFieldOrObj := cogMethod methodObject.
			 rcvr := self mframeReceiver: theFP.
			 numStack := self stackPointerIndexForMFrame: theFP WithSP: theSP numArgs: numArgs]
		ifFalse:
			[self setIFrameHasContext: theFP.
			 numArgs := self iframeNumArgs: theFP.
			 numSlots := (self methodHeaderIndicatesLargeFrame: (objectMemory methodHeaderOf: methodFieldOrObj))
							ifTrue: [LargeContextSlots]
							ifFalse: [SmallContextSlots].
			 closureOrNil := (self iframeIsBlockActivation: theFP)
								ifTrue: [self frameStackedReceiver: theFP numArgs: numArgs]
								ifFalse: [objectMemory nilObject].
			 rcvr := self iframeReceiver: theFP.
			 numStack := self stackPointerIndexForIFrame: theFP WithSP: theSP numArgs: numArgs].
	theContext := objectMemory eeInstantiateMethodContextSlots: numSlots.
	self setFrameContext: theFP to: theContext.
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
		withValue: methodFieldOrObj.
	objectMemory storePointerUnchecked: ClosureIndex ofObject: theContext withValue: closureOrNil.
	objectMemory storePointerUnchecked: ReceiverIndex
		ofObject: theContext
		withValue: rcvr.
	1 to: numArgs do:
		[:i|
		objectMemory storePointerUnchecked: ReceiverIndex + i
			ofObject: theContext
			withValue: (self temporary: i - 1 in: theFP)].
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

	self assert: (self frameHasContext: theFP).
	self assert: (self frameOfMarriedContext: theContext) = theFP.
	self assert: numStack + ReceiverIndex < (objectMemory lengthOf: theContext).

	^theContext
]

{ #category : #'frame access' }
CoInterpreter >> marryFrameCopiesTemps [
	"Answer whether marryFrame:SP: copies non-argument temporaries."
	<api>
	^false
]

{ #category : #'cog jit support' }
CoInterpreter >> maxLookupNoMNUErrorCode [
	<api>
	^SelectorCannotInterpret max: SelectorDoesNotUnderstand
]

{ #category : #'cog jit support' }
CoInterpreter >> maybeFixClonedCompiledMethod: objOop [
	"Make sure a cloned method doesn't reference its originals Cog method, if any."
	| rawHeader |
	self assert: (objectMemory isOopCompiledMethod: objOop).
	rawHeader := self rawHeaderOf: objOop.
	(self isCogMethodReference: rawHeader) ifTrue:
		[self
			rawHeaderOf: objOop
			put: (self cCoerceSimple: rawHeader to: #'CogMethod *') methodHeader]
]

{ #category : #'compiled methods' }
CoInterpreter >> maybeFlagMethodAsInterpreted: aMethod [
	"The flag bit can be used to flag methods that are interpreted, if it has been requested
	 from the image header flags."
	flagInterpretedMethods ifTrue:
		[| rawHeader realHeader |
		 rawHeader := self rawHeaderOf: aMethod.
		 realHeader := (self isCogMethodReference: rawHeader)
						ifTrue: [(self cCoerceSimple: rawHeader to: #'CogMethod *') methodHeader]
						ifFalse: [rawHeader].
		 realHeader := realHeader bitOr: (objectMemory integerObjectOf: 1 << MethodHeaderFlagBitPosition).
		 (self isCogMethodReference: rawHeader)
			ifTrue: [(self cCoerceSimple: rawHeader to: #'CogMethod *') methodHeader: realHeader]
			ifFalse: [objectMemory storePointerUnchecked: 0 ofObject: aMethod withValue: realHeader]]
]

{ #category : #'compiled methods' }
CoInterpreter >> maybeMethodHasCogMethod: anOop [
	^(objectMemory isNonImmediate: anOop)
	  and: [(objectMemory isCompiledMethod: anOop)
	  and: [self isCogMethodReference: (self rawHeaderOf: anOop)]]
]

{ #category : #'return bytecodes' }
CoInterpreter >> maybeReturnToMachineCodeFrame [
	"If the frame we're returning to is a machine code one, then return to it.
	 Otherwise, if it's an interpreter frame, load the saved ip."
	<inline: true>
	localIP asUnsignedInteger < objectMemory startOfMemory ifTrue:
		[localIP asUnsignedInteger ~= cogit ceReturnToInterpreterPC ifTrue:
			["localIP in the cog method zone indicates a return to machine code."
			 ^self returnToMachineCodeFrame].
		 localIP := self pointerForOop: (self iframeSavedIP: localFP)]
]

{ #category : #'debug support' }
CoInterpreter >> maybeTraceStackOverflow [
	cogit recordOverflowTrace ifTrue:
		[self recordTrace: TraceStackOverflow
			thing: TraceStackOverflow
			source: ((self isMachineCodeFrame: framePointer)
						ifTrue: [TraceIsFromMachineCode]
						ifFalse: [TraceIsFromInterpreter])].
	cogit recordPrimTrace ifTrue:
		[self fastLogPrim: TraceStackOverflow]
]

{ #category : #'cog jit support' }
CoInterpreter >> mcprimFunctionForPrimitiveIndex: primIndex [
	<api>
	primIndex = PrimNumberHashMultiply ifTrue:
		[^#mcprimHashMultiply:].
	self error: 'unknown mcprim'.
	^nil
]

{ #category : #'cog jit support' }
CoInterpreter >> methodCacheAddress [
	<api>
	<returnTypeC: #'void *'>
	^self cCode: [methodCache] inSmalltalk: [methodCache address]
]

{ #category : #'compiled methods' }
CoInterpreter >> methodHasCogMethod: aMethodOop [
	<api>
	self assert: (objectMemory isNonImmediate: aMethodOop).
	^self isCogMethodReference: (self rawHeaderOf: aMethodOop)
]

{ #category : #'cog jit support' }
CoInterpreter >> methodNeedsLargeContext: methodObj [
	<api>
	^self methodHeaderIndicatesLargeFrame: (objectMemory methodHeaderOf: methodObj)
]

{ #category : #'compiled methods' }
CoInterpreter >> methodShouldBeCogged: aMethodObj [
	<api>
	(self methodWithHeaderShouldBeCogged: (objectMemory methodHeaderOf: aMethodObj)) ifTrue:
		[^true].
	self maybeFlagMethodAsInterpreted: aMethodObj.
	^false
]

{ #category : #'compiled methods' }
CoInterpreter >> methodWithHeaderShouldBeCogged: methodHeader [
	"At the moment jit any method with less than N literals, where N defaults to 60.
	 See e.g. SimpleStackBasedCogit class>>initialize.
	 In my dev image eem 2/22/2009 13:39
		(30 to: 100 by: 5) collect:
			[:n| n -> (SystemNavigation default allSelect: [:m| m numLiterals > n]) size]
		#(30->1681 35->1150 40->765 45->523 50->389 55->289 60->206
		    65->151 70->124 75->99 80->73 85->63 90->54 95->42 100->38).
	 And running the CogVMSimulator with flagging of interpreted methods turned on reveals
	 the following sizes of interpreted methods.
		| sizes |
		sizes := Bag new.
		SystemNavigation default allSelect: [:m| m flag ifTrue: [sizes add: m numLiterals]. false].
		sizes sortedElements asArray
			#(	40->4 41->1 42->2 44->1 45->3 46->1 47->2 48->1
				50->2 51->1 53->1 55->1 56->1
				87->1 108->1 171->1)
	 literalCountOfHeader: does not include the header word."
	^SistaVM
		ifTrue: [(self isOptimizedMethodHeader: methodHeader)
				or: [(objectMemory literalCountOfMethodHeader: methodHeader) <= maxLiteralCountForCompile]]
		ifFalse: [(objectMemory literalCountOfMethodHeader: methodHeader) <= maxLiteralCountForCompile]
]

{ #category : #'frame access' }
CoInterpreter >> mframeCogMethod: theFP [
	"Answer the Cog method for a machine code frame.  This may be
	 either a full CogMethod or merely a CogBlockMethod rump header."
	<var: #theFP type: #'char *'>
	^self cCoerceSimple: (self mframeMethod: theFP) to: #'CogBlockMethod *'
]

{ #category : #'frame access' }
CoInterpreter >> mframeHasContext: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^((self frameMethodField: theFP) bitAnd: MFMethodFlagHasContextFlag) ~= 0
]

{ #category : #'frame access' }
CoInterpreter >> mframeHomeMethod: theFP [
	"Answer the home method for a machine code frame.  From a block frame we find
	 the home method through the block's homeOffset field which is the delta to it.
	 In both cases we need to strip the isBlock and isContext flags from the method field."
	<api>
	<returnTypeC: #'CogMethod *'>
	<var: #theFP type: #'char *'>
	| methodField |
	methodField := self frameMethodField: theFP.
	(methodField bitAnd: MFMethodFlagIsBlockFlag) ~= 0 ifTrue:
		[^(self cCoerceSimple: (methodField bitAnd: MFMethodMask) to: #'CogBlockMethod *') cmHomeMethod].
	^self cCoerceSimple: (methodField bitAnd: MFMethodMask) to: #'CogMethod *'
]

{ #category : #'frame access' }
CoInterpreter >> mframeHomeMethodExport [
	<api>
	<returnTypeC: #'CogMethod *'>
	^self mframeHomeMethod: framePointer
]

{ #category : #'frame access' }
CoInterpreter >> mframeIsBlockActivation: theFP [ "<Integer>"
	<inline: true>
	<var: #theFP type: #'char *'>
	^((self frameMethodField: theFP) bitAnd: MFMethodFlagIsBlockFlag) ~= 0
]

{ #category : #'frame access' }
CoInterpreter >> mframeMethod: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^(self frameMethodField: theFP) bitAnd: MFMethodMask
]

{ #category : #'frame access' }
CoInterpreter >> mframeNumArgs: theFP [
	<returnTypeC: #sqInt>
	^(self mframeCogMethod: theFP) cmNumArgs
]

{ #category : #'frame access' }
CoInterpreter >> mframeReceiver: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxMFReceiver
]

{ #category : #'debug support' }
CoInterpreter >> minimumUnusedHeadroom [
	"Traverse all stack pages looking for non-zero bytes in the headroom part of each page.
	 Answer the minimum size of unused headroom (zero bytes) in the pages.  This is for
	 checking that there is enough headroom allocated in stack pages."
	| minUnused page |
	<var: #page type: #'StackPage *'>
	<var: #p type: #'char *'>
	minUnused := (stackPages stackPageAt: 0) baseAddress - (stackPages stackPageAt: 0) lastAddress.
	0 to: numStackPages - 1 do:
		[:i| | p unused |
		page := stackPages stackPageAt: i.
		p := page lastAddress.
		[p := p + objectMemory wordSize.
		(self longAtPointer: p) = 0
		 and: [p <= page baseAddress]] whileTrue.
		unused := p - objectMemory wordSize - page lastAddress.
		unused < minUnused ifTrue:
			[minUnused := unused]].
	^minUnused
]

{ #category : #'debug support' }
CoInterpreter >> mnuCompilationBreak: selectorOop point: selectorLength [
	<api>
	<cmacro: '(sel, len) do { \
	if ((len) == -breakSelectorLength \
	 && !strncmp((char *)((sel) + BaseHeaderSize), breakSelector, -breakSelectorLength)) { \
		suppressHeartbeatFlag = 1; \
		compilationBreakpointFor(sel); \
	} \
} while (0)'>
	| i |
	breakSelectorLength negated = selectorLength ifTrue:
		[i := breakSelectorLength negated.
		 [i > 0] whileTrue:
			[(objectMemory byteAt: selectorOop + i + objectMemory baseHeaderSize - 1) = (breakSelector at: i) asInteger
				ifTrue: [(i := i - 1) = 0 ifTrue:
							[self mnuCompilationBreakpointFor: selectorOop]]
				ifFalse: [i := 0]]]
]

{ #category : #'debug support' }
CoInterpreter >> mnuCompilationBreakpointFor: selectorOop [
	<api>
	suppressHeartbeatFlag := true.
	self
		cCode: [self warning: 'compilation MNU break (heartbeat suppressed)']
		inSmalltalk: [self halt: 'Compilation for MNU of ', breakSelector]
]

{ #category : #'message sending' }
CoInterpreter >> mnuMethodOrNilFor: rcvr [
	"Lookup the doesNotUnderstand: selector in the class of the argument rcvr.
	 Answer either the matching method (cogged if appropriate), or nil, if not found."
	| currentClass mnuSelector dictionary mnuMethod methodHeader |
	self deny: (objectMemory isOopForwarded: rcvr).
	currentClass := objectMemory fetchClassOf: rcvr.
	mnuSelector := objectMemory splObj: SelectorDoesNotUnderstand.
	[currentClass ~= objectMemory nilObject] whileTrue:
		[dictionary := objectMemory fetchPointer: MethodDictionaryIndex ofObject: currentClass.
		 dictionary = objectMemory nilObject ifTrue:
			[^nil].
		 mnuMethod := self lookupMethodFor: mnuSelector InDictionary: dictionary.
		 mnuMethod ifNotNil:
			[methodHeader := self rawHeaderOf: mnuMethod.
			 ((self isCogMethodReference: methodHeader) not
			  and: [self methodWithHeaderShouldBeCogged: methodHeader]) ifTrue:
				[cogit cog: mnuMethod selector: mnuSelector].
			^mnuMethod].
		currentClass := self superclassOf: currentClass].
	^nil
]

{ #category : #'frame access' }
CoInterpreter >> moveFramesIn: oldPage through: theFP toPage: newPage [
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
	<returnTypeC: #'char *'>
	"A base frame must have a context for cannotReturn: processing."
	self assert: (self isBaseFrame: theFP) not.
	self assert: self validStackPageBaseFrames.
	callerFP := self frameCallerFP: theFP.
	self assert: (self frameHasContext: callerFP).
	self assert: (objectMemory isContext: (self frameContext: callerFP)).
	theContext := self ensureFrameIsMarried: theFP
					SP: theFP + ((self isMachineCodeFrame: theFP) ifTrue: [FoxMFReceiver] ifFalse: [FoxIFReceiver]).
	stackPages
		longAt: (newSP := newPage baseAddress) put: (self frameContext: callerFP);
		longAt: (newSP := newSP - objectMemory wordSize) put:  theContext.
	stackedReceiverOffset := self frameStackedReceiverOffset: theFP.
	"First move the data, leaving room for the caller and base frame contexts.  We will fix up frame pointers later."
	theFP + stackedReceiverOffset
		to: oldPage headSP
		by: objectMemory wordSize negated
		do: [:source|
			newSP := newSP - objectMemory wordSize.
			stackPages longAt: newSP put: (stackPages longAt: source)].
	"newSP = oldSP + delta => delta = newSP - oldSP"
	delta := newSP - oldPage headSP.
	newFP := newPage baseAddress - stackedReceiverOffset - (2 * objectMemory wordSize).
	self setHeadFP: oldPage headFP + delta andSP: newSP inPage: newPage.
	newPage baseFP: newFP.
	callerIP := self oopForPointer: (self frameCallerSavedIP: theFP).
	callerIP asUnsignedInteger >= objectMemory startOfMemory ifTrue:
		[self iframeSavedIP: callerFP put: callerIP.
		 callerIP := cogit ceReturnToInterpreterPC].
	stackPages longAt: theFP + stackedReceiverOffset put: callerIP.
	self assert: (callerFP < oldPage baseAddress
				and: [callerFP > (oldPage realStackLimit - (LargeContextSlots * objectMemory bytesPerOop / 2))]).
	oldPage
		headFP: callerFP;
		headSP: theFP + stackedReceiverOffset.
	"Mark the new base frame in the new page"
	stackPages
		longAt: newFP + FoxCallerSavedIP put: cogit ceBaseFrameReturnPC;
		longAt: newFP + FoxSavedFP put: 0.
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
	self assert: self validStackPageBaseFrames.
	^newFP
]

{ #category : #'internal interpreter access' }
CoInterpreter >> mtemporary: offset in: theFP put: valueOop [
	"Temporary access for a machine code frame only."
	"See StackInterpreter class>>initializeFrameIndices"
	| frameNumArgs |
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages
		longAt: (offset < (frameNumArgs := self mframeNumArgs: theFP)
					ifTrue: [theFP + FoxCallerSavedIP + ((frameNumArgs - offset) * objectMemory wordSize)]
					ifFalse: [theFP + FoxMFReceiver - objectMemory wordSize + ((frameNumArgs - offset) * objectMemory wordSize)])
		put: valueOop
]

{ #category : #'frame access' }
CoInterpreter >> mustMapMachineCodePC: theIP context: aOnceMarriedContext [
	"Map the native pc theIP into a bytecode pc integer object and answer it.
	 See contextInstructionPointer:frame: for the explanation."
	| maybeClosure methodObj cogMethod startBcpc bcpc |
	<inline: false>
	<var: #cogMethod type: #'CogMethod *'>
	theIP = HasBeenReturnedFromMCPC ifTrue:
		[^objectMemory nilObject].
	maybeClosure := objectMemory fetchPointer: ClosureIndex ofObject: aOnceMarriedContext.
	methodObj := objectMemory fetchPointer: MethodIndex ofObject: aOnceMarriedContext.
	(maybeClosure ~= objectMemory nilObject
	and: [self isVanillaBlockClosure: maybeClosure])
		ifTrue: [self assert: (theIP signedBitShift: -16) < -1.
				startBcpc := self startPCOfClosure: maybeClosure]
		ifFalse: [self assert: (theIP signedBitShift: -16) = -1.
				startBcpc := self startPCOfMethod: methodObj].
	cogMethod := self ensureMethodIsCogged: methodObj maybeClosure: maybeClosure.
	bcpc := self bytecodePCFor: theIP cogMethod: cogMethod startBcpc: startBcpc.
	self assert: bcpc >= (self startPCOfMethod: methodObj).
	"If there's a CallPrimitive we need to skip it."
	(bcpc = startBcpc
	 and: [maybeClosure = objectMemory nilObject
	 and: [self methodHeaderHasPrimitive: cogMethod methodHeader]]) ifTrue:
		[bcpc := bcpc + (self sizeOfCallPrimitiveBytecode: cogMethod methodHeader)].
	^objectMemory integerObjectOf: bcpc + 1
]

{ #category : #'cog jit support' }
CoInterpreter >> newMethod [
	<doNotGenerate>
	^newMethod
]

{ #category : #'trampoline support' }
CoInterpreter >> newMethodAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: newMethod) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #newMethod in: self]
]

{ #category : #'method lookup cache' }
CoInterpreter >> newMethodInLookupCacheAt: selector and: classTag [
	"Answer if classTag x messageSelector => newMethod is in the lookup cache.
	 This is for assert checking to check that open PICs find entries."
	| probe hash |
	<inline: false>
	hash := objectMemory methodCacheHashOf: selector with: classTag.

	0 to: CacheProbeMax-1 do:
		[:p |
		probe := (hash >> p) bitAnd: MethodCacheMask.
		((methodCache at: probe + MethodCacheSelector) = selector
		 and: [(methodCache at: probe + MethodCacheClass) = classTag
		 and: [(methodCache at: probe + MethodCacheMethod) = newMethod]]) ifTrue:
			[^true]].

	^false
]

{ #category : #'cog jit support' }
CoInterpreter >> nextProfileTick [
	<doNotGenerate>
	^nextProfileTick
]

{ #category : #'trampoline support' }
CoInterpreter >> nextProfileTickAddress [
	<api>
	<returnTypeC: #usqInt>
	"N.B. nextProfileTick is 64-bits"
	^self cCode: [(self addressOf: nextProfileTick) asUnsignedInteger]
		inSmalltalk:
			[VMBIGENDIAN
				ifTrue:
					[cogit simulatedReadWriteVariableAddress: #nextProfileTickLow in: self.
					 cogit simulatedReadWriteVariableAddress: #nextProfileTickHigh in: self]
				ifFalse:
					[cogit simulatedReadWriteVariableAddress: #nextProfileTickHigh in: self.
					 cogit simulatedReadWriteVariableAddress: #nextProfileTickLow in: self]]
]

{ #category : #'cog jit support' }
CoInterpreter >> nextProfileTickHigh [
	<doNotGenerate>
	^nextProfileTick bitShift: -32
]

{ #category : #'cog jit support' }
CoInterpreter >> nextProfileTickLow [
	<doNotGenerate>
	^nextProfileTick bitAnd: 16rFFFFFFFF
]

{ #category : #simulation }
CoInterpreter >> nilLocalFP [
	<doNotGenerate>
	localFP := nil
]

{ #category : #'cog jit support' }
CoInterpreter >> nilUncoggableMethods [
	<inline: true>
	lastCoggableInterpretedBlockMethod := lastUncoggableInterpretedBlockMethod := nil
]

{ #category : #'compiled methods' }
CoInterpreter >> noAssertHeaderOf: methodPointer [
	<api>
	| methodHeader |
	methodHeader := self rawHeaderOf: methodPointer.
	^(self isCogMethodReference: methodHeader)
		ifTrue: [(self cCoerceSimple: methodHeader to: #'CogMethod *') methodHeader]
		ifFalse: [methodHeader]
]

{ #category : #trampolines }
CoInterpreter >> positive32BitIntegerFor: integerValue [
	<api>
	^super positive32BitIntegerFor: integerValue
]

{ #category : #trampolines }
CoInterpreter >> positive32BitValueOf: oop [
	<api>
	^super positive32BitValueOf: oop
]

{ #category : #trampolines }
CoInterpreter >> positive64BitIntegerFor: integerValue [
	<api>
	^super positive64BitIntegerFor: integerValue
]

{ #category : #trampolines }
CoInterpreter >> positive64BitValueOf: oop [
	<api>
	^super positive64BitValueOf: oop
]

{ #category : #'object memory support' }
CoInterpreter >> postBecomeAction: theBecomeEffectsFlags [
	"Clear the gcMode var and let the Cogit do its post GC checks."
	super postBecomeAction: theBecomeEffectsFlags.

	(objectMemory hasSpurMemoryManagerAPI
	 and: [theBecomeEffectsFlags anyMask: OldBecameNewFlag]) ifTrue:
		[cogit addAllToYoungReferrers].
	cogit cogitPostGCAction: gcMode.
	self nilUncoggableMethods.
	gcMode := 0
]

{ #category : #'object memory support' }
CoInterpreter >> postGCAction: gcModeArg [
	"Attempt to shrink free memory, signal the gc semaphore and let the Cogit do its post GC thang"
	<inline: false>
	self assert: gcModeArg = gcMode.
	super postGCAction: gcModeArg.
	cogit cogitPostGCAction: gcModeArg.
	self nilUncoggableMethods.
	gcMode := 0
]

{ #category : #'object memory support' }
CoInterpreter >> preBecomeAction [
	"Need to set gcMode var (to avoid passing the flag through a lot of the updating code)"
	super preBecomeAction.
	gcMode := GCModeBecome
]

{ #category : #'object memory support' }
CoInterpreter >> preGCAction: gcModeArg [
	<inline: false>
	"Need to write back the frame pointers unless all pages are free (as in snapshot).
	 Need to set gcMode var (to avoid passing the flag through a lot of the updating code)"
	super preGCAction: gcModeArg.

	gcMode := gcModeArg.

	cogit recordEventTrace ifTrue:
		[| traceType |
		traceType := gcModeArg == GCModeFull ifTrue: [TraceFullGC] ifFalse: [TraceIncrementalGC].
		self recordTrace: traceType thing: traceType source: 0].

	cogit recordPrimTrace ifTrue:
		[| traceType |
		traceType := gcModeArg == GCModeFull ifTrue: [TraceFullGC] ifFalse: [TraceIncrementalGC].
		self fastLogPrim: traceType]
]

{ #category : #'cog jit support' }
CoInterpreter >> primErrTable [
	<api>
	^objectMemory splObj: PrimErrTableIndex
]

{ #category : #'cog jit support' }
CoInterpreter >> primFailCode [
	<doNotGenerate>
	^primFailCode
]

{ #category : #'cog jit support' }
CoInterpreter >> primFailCode: anInteger [
	<doNotGenerate>
	primFailCode := anInteger
]

{ #category : #'trampoline support' }
CoInterpreter >> primFailCodeAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: primFailCode) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #primFailCode in: self]
]

{ #category : #'compiled methods' }
CoInterpreter >> primNumberExternalCall [
	"Answer if the method is an external primtiive call (prim 117)."
	<api>
	<cmacro>
	^PrimNumberExternalCall
]

{ #category : #'as yet unclassified' }
CoInterpreter >> primTraceLog [
	<doNotGenerate>
	^ primTraceLog
]

{ #category : #'cog jit support' }
CoInterpreter >> primTraceLogAddress [
	<api>
	<returnTypeC: #'void *'>
	^self cCode: [primTraceLog] inSmalltalk: [primTraceLog offset * objectMemory wordSize]
]

{ #category : #'as yet unclassified' }
CoInterpreter >> primTraceLogEntries [
	<doNotGenerate>
	
	^ PrimTraceLogSize
]

{ #category : #'cog jit support' }
CoInterpreter >> primTraceLogIndex [
	<doNotGenerate>
	^primTraceLogIndex
]

{ #category : #'cog jit support' }
CoInterpreter >> primTraceLogIndex: aValue [
	<cmacro: '(aValue) (GIV(primTraceLogIndex) = (aValue))'>
	"N.B. primTraceLogIndex is 8-bits"
	^primTraceLogIndex := aValue bitAnd: 16rFF
]

{ #category : #'cog jit support' }
CoInterpreter >> primTraceLogIndexAddress [
	<api>
	<returnTypeC: #usqInt>
	"N.B. primTraceLogIndex is 8-bits"
	^self cCode: [(self addressOf: primTraceLogIndex) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #primTraceLogIndex in: self]
]

{ #category : #'as yet unclassified' }
CoInterpreter >> primitiveAccessorDepthTable [
	
	<doNotGenerate>
	
	^ primitiveAccessorDepthTable
]

{ #category : #'as yet unclassified' }
CoInterpreter >> primitiveAccessorDepthTable: aCollection [ 
	
	<doNotGenerate>
	
	primitiveAccessorDepthTable := aCollection
]

{ #category : #'trampoline support' }
CoInterpreter >> primitiveFailAddress [
	"This is used for asserts that check that inline cache editing results in valid addresses.
	 In the C VM interpret is presumed to come before any primitives and so it constitutes
	 the lowest address in C code that machine code should be linked, but optimizing
	 compilers change things around.  In the simulator we just answer something not low."
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: #primitiveFail) asUnsignedInteger]
		inSmalltalk: [heapBase]
]

{ #category : #'cog jit support' }
CoInterpreter >> primitiveFunctionPointer: oop [
	"Apparently not sent but is used in the simulator."
	<doNotGenerate>
	primitiveFunctionPointer := oop
]

{ #category : #'cog jit support' }
CoInterpreter >> primitivePropertyFlags: primIndex [
	<api>
	"Answer any special requirements of the given primitive"
	objectMemory hasSpurMemoryManagerAPI
		ifTrue: [^self primitivePropertyFlagsForSpur: primIndex]
		ifFalse: [^self primitivePropertyFlagsForV3: primIndex]
]

{ #category : #'cog jit support' }
CoInterpreter >> primitivePropertyFlagsForSpur: primIndex [
	<inline: true>
	"Answer any special requirements of the given primitive.  Spur always needs to set
	 primitiveFunctionPointer and newMethod so primitives can retry on failure due to forwarders."
	| baseFlags |
	self cCode: [] inSmalltalk: [#(mcprimHashMultiply: primitiveExternalCall primitiveCalloutToFFI)]. "For senders..."
	primIndex = PrimNumberHashMultiply ifTrue:
		[^PrimCallOnSmalltalkStack].
	baseFlags := PrimCallNeedsPrimitiveFunction + PrimCallNeedsNewMethod.
	profileSemaphore ~= objectMemory nilObject ifTrue:
		[baseFlags := baseFlags bitOr: PrimCallCollectsProfileSamples].

		(primIndex = PrimNumberExternalCall "#primitiveExternalCall"
	 or: [primIndex = PrimNumberFFICall "#primitiveCalloutToFFI"]) ifTrue: "For callbacks"
		[baseFlags := baseFlags bitOr: PrimCallMayCallBack.
		 checkAllocFiller ifTrue:
			[baseFlags := baseFlags bitOr: CheckAllocationFillerAfterPrimCall]].

	^baseFlags
]

{ #category : #'cog jit support' }
CoInterpreter >> primitivePropertyFlagsForV3: primIndex [
	<inline: true>
	"Answer any special requirements of the given primitive"
	| baseFlags |
	baseFlags := profileSemaphore ~= objectMemory nilObject
					ifTrue: [PrimCallNeedsNewMethod + PrimCallCollectsProfileSamples]
					ifFalse: [0].

	longRunningPrimitiveCheckSemaphore ifNotNil:
		[baseFlags := baseFlags bitOr: PrimCallNeedsNewMethod].

	self cCode: [] inSmalltalk: [#(primitiveExternalCall primitiveCalloutToFFI)]. "For senders..."
		(primIndex = PrimNumberExternalCall "#primitiveExternalCall"
	 or: [primIndex = PrimNumberFFICall "#primitiveCalloutToFFI"]) ifTrue: "For callbacks"
		[baseFlags := baseFlags bitOr: PrimCallNeedsNewMethod + PrimCallNeedsPrimitiveFunction + PrimCallMayCallBack].

	^baseFlags
]

{ #category : #'debug printing' }
CoInterpreter >> printCogMethod: cogMethod [
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	| address primitive |
	self cCode: ''
		inSmalltalk:
			[self transcript ensureCr.
			 cogMethod isInteger ifTrue:
				[^self printCogMethod: (self cCoerceSimple: cogMethod to: #'CogMethod *')]].
	address := cogMethod asInteger.
	self printHex: address;
		print: ' <-> ';
		printHex: address + cogMethod blockSize.
	cogMethod cmType = CMMethod ifTrue:
		[self print: ': method: ';
			printHex: cogMethod methodObject.
		 primitive := self primitiveIndexOfMethod: cogMethod methodObject
							header: cogMethod methodHeader.
		 primitive ~= 0 ifTrue:
			[self print: ' prim '; printNum: primitive]].
	cogMethod cmType = CMBlock ifTrue:
		[self print: ': block home: ';
			printHex: (self cCoerceSimple: cogMethod to: #'CogBlockMethod *') cmHomeMethod asUnsignedInteger].
	cogMethod cmType = CMClosedPIC ifTrue:
		[self print: ': Closed PIC N: ';
			printHex: cogMethod cPICNumCases].
	cogMethod cmType = CMOpenPIC ifTrue:
		[self print: ': Open PIC '].
	self print: ' selector: '; printHex: cogMethod selector.
	cogMethod selector = objectMemory nilObject
		ifTrue: [| s |
			(cogMethod cmType = CMMethod
			 and: [(s := self maybeSelectorOfMethod: cogMethod methodObject) notNil])
				ifTrue: [self print: ' (nil: '; printStringOf: s; print: ')']
				ifFalse: [self print: ' (nil)']]
		ifFalse: [self space; printStringOf: cogMethod selector].
	self cr
]

{ #category : #'debug printing' }
CoInterpreter >> printFrame: theFP WithSP: theSP [
	<api>
	| theMethod theMethodEnd numArgs numTemps rcvrAddress topThing |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #addr type: #'char *'>
	<var: #rcvrAddress type: #'char *'>
	<var: #cogMethod type: #'CogBlockMethod *'>
	<var: #homeMethod type: #'CogMethod *'>
	self cCode: '' inSmalltalk: [self transcript ensureCr].
	(stackPages couldBeFramePointer: theFP) ifNil:
		[self printHexPtr: theFP; print: ' is not in the stack zone?!'; cr.
		 ^nil].
	(self isMachineCodeFrame: theFP)
		ifTrue:
			[| cogMethod homeMethod |
			 cogMethod := self mframeCogMethod: theFP.
			 homeMethod := self mframeHomeMethod: theFP.
			 theMethod := homeMethod asInteger.
			 theMethodEnd := homeMethod asInteger + homeMethod blockSize.
			 numArgs := cogMethod cmNumArgs.
			 numTemps := self temporaryCountOfMethodHeader: homeMethod methodHeader]
		ifFalse:
			[theMethod := self frameMethodObject: theFP.
			 theMethodEnd := theMethod + (objectMemory sizeBitsOfSafe: theMethod).
			 numArgs := self iframeNumArgs: theFP.
			 numTemps := self tempCountOf: theMethod].
	(self frameIsBlockActivation: theFP) ifTrue:
		[| rcvrOrClosure |
		 "No BlockLocalTempCounter in the Cogit's C code, so quick hack is to use numCopied + numArgs"
		 rcvrOrClosure := self pushedReceiverOrClosureOfFrame: theFP.
		 ((objectMemory isNonImmediate: rcvrOrClosure)
		 and: [(objectMemory addressCouldBeObj: rcvrOrClosure)
		 and: [(objectMemory fetchClassOfNonImm: rcvrOrClosure) = (objectMemory splObj: ClassBlockClosure)]])
			ifTrue: [numTemps := numArgs + (self stSizeOf: rcvrOrClosure)]
			ifFalse: [numTemps := numArgs]].
	self shortPrintFrame: theFP.
	(self isBaseFrame: theFP) ifTrue:
		[self printFrameOop: '(caller ctxt'
			at: theFP + (self frameStackedReceiverOffset: theFP) + (2 * objectMemory wordSize).
		 self printFrameOop: '(saved ctxt'
			at: theFP + (self frameStackedReceiverOffset: theFP) + (1 * objectMemory wordSize)].
	self printFrameOop: 'rcvr/clsr'
		at: theFP + FoxCallerSavedIP + ((numArgs + 1) * objectMemory wordSize).
	numArgs to: 1 by: -1 do:
		[:i|
		self printFrameOop: 'arg' index: numArgs - i at: theFP + FoxCallerSavedIP + (i * objectMemory wordSize)].
	self printFrameThing: 'caller ip'
		at: theFP + FoxCallerSavedIP
		extraString: ((stackPages longAt: theFP + FoxCallerSavedIP) = cogit ceReturnToInterpreterPC ifTrue:
						['ceReturnToInterpreter']).
	self printFrameThing: 'saved fp' at: theFP + FoxSavedFP.
	self printFrameMethodFor: theFP.
	(self isMachineCodeFrame: theFP) ifTrue:
		[self printFrameFlagsForFP: theFP].
	self printFrameOop: 'context' at: theFP + FoxThisContext.
	(self isMachineCodeFrame: theFP) ifFalse:
		[self printFrameFlagsForFP: theFP].
	(self isMachineCodeFrame: theFP)
		ifTrue: [rcvrAddress := theFP + FoxMFReceiver]
		ifFalse:
			[self printFrameThing: 'saved ip'
				at: theFP + FoxIFSavedIP
				extra: ((self iframeSavedIP: theFP) = 0
							ifTrue: [0]
							ifFalse: [(self iframeSavedIP: theFP) - theMethod + 2 - objectMemory baseHeaderSize]).
			 rcvrAddress := theFP + FoxIFReceiver].
	self printFrameOop: 'receiver' at: rcvrAddress.
	topThing := stackPages longAt: theSP.
	(self oop: topThing isGreaterThanOrEqualTo: theMethod andLessThan: theMethodEnd)
		ifTrue:
			[rcvrAddress - objectMemory wordSize to: theSP + objectMemory wordSize by: objectMemory wordSize negated do:
				[:addr| | index |
				index := rcvrAddress - addr / objectMemory wordSize + numArgs.
				index <= numTemps
					ifTrue: [self printFrameOop: 'temp' index: index - 1 at: addr]
					ifFalse: [self printFrameOop: ((self frameIsBlockActivation: theFP)
													ifTrue: ['temp/stck']
													ifFalse: ['stck'])
								at: addr]].
			self printFrameThing: 'frame ip'
				at: theSP
				extra: ((self isMachineCodeFrame: theFP)
						ifTrue: [topThing - theMethod]
						ifFalse: [topThing - theMethod + 2 - objectMemory baseHeaderSize])]
		ifFalse:
			[rcvrAddress - objectMemory wordSize to: theSP by: objectMemory wordSize negated do:
				[:addr| | index |
				index := rcvrAddress - addr / objectMemory wordSize + numArgs.
				index <= numTemps
					ifTrue: [self printFrameOop: 'temp' index: index - 1 at: addr]
					ifFalse: [self printFrameOop: ((self frameIsBlockActivation: theFP)
													ifTrue: ['temp/stck']
													ifFalse: ['stck'])
								at: addr]]]
]

{ #category : #'debug printing' }
CoInterpreter >> printFrameFlagsForFP: theFP [
	| address it |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #address type: #'char *'>
	(self isMachineCodeFrame: theFP)
		ifTrue:
			[address := theFP + FoxMethod.
			it := (stackPages longAt: address) bitAnd: 16r7]
		ifFalse:
			[address := theFP + FoxIFrameFlags.
			 it := stackPages longAt: address].
	self printHexPtr: address;
		print: ((self isMachineCodeFrame: theFP)
				ifTrue: [': mcfrm flags: ']
				ifFalse: [':intfrm flags: ']);
		printHex: it.
	it ~= 0 ifTrue:
		[self printChar: $=; printNum: it].
	self print: '  numArgs: '; printNum: (self frameNumArgs: theFP);
		print: ((self frameHasContext: theFP) ifTrue: [' hasContext'] ifFalse: [' noContext']);
		print: ((self frameIsBlockActivation: theFP) ifTrue: [' isBlock'] ifFalse: [' notBlock']);
		cr
]

{ #category : #'debug printing' }
CoInterpreter >> printFrameMethodFor: theFP [
	<inline: false>
	| address it homeMethod obj |
	<var: #theFP type: #'char *'>
	<var: #address type: #'char *'>
	<var: #homeMethod type: #'CogMethod *'>

	address := theFP + FoxMethod.
	it := stackPages longAt: address.
	self printHex: address asInteger;
		printChar: $:.
	self print: '      method: ';
		printHex: it.
	self tab.
	((self isMachineCodeFrame: theFP)
	 and: [self mframeIsBlockActivation: theFP]) ifTrue:
		[homeMethod := self mframeHomeMethod: theFP.
		 self print: 'hm: '; printHex: homeMethod asInteger; tab].
	obj := self frameMethodObject: theFP.
	self shortPrintOop: obj
]

{ #category : #'debug printing' }
CoInterpreter >> printFrameThing: name at: address extra: extraValue [
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
	self space; printNum: extraValue; cr
]

{ #category : #'debug printing' }
CoInterpreter >> printFrameThing: name at: address extraString: extraStringOrNil [
	| it len |
	<inline: false>
	<var: #name type: #'char *'>
	<var: #address type: #'char *'>
	<var: #extraStringOrNil type: #'char *'>
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
	extraStringOrNil ifNotNil: [self space; print: extraStringOrNil].
	self cr
]

{ #category : #'debug support' }
CoInterpreter >> printLogEntryAt: i [
	<inline: false>
	| intOrClass selectorMethodOrProcess source |
	intOrClass := traceLog at: i.
	selectorMethodOrProcess := traceLog at: i + 1.
	source := traceLog at: i + 2.
	source <= TraceIsFromInterpreter ifTrue:
		[self print: (traceSources at: source); space].
	(objectMemory isIntegerObject: intOrClass)
		ifTrue:
			[intOrClass = TraceStackOverflow ifTrue:
				[self print: 'stack overflow'].
			 intOrClass = TraceContextSwitch ifTrue:
				[self print: 'context switch from '; printHex: selectorMethodOrProcess].
			 intOrClass = TraceBlockActivation ifTrue:
				[self print: ' [] in '; printHex: selectorMethodOrProcess].
			 intOrClass = TraceBlockCreation ifTrue:
				[self print: 'create [] '; printHex: selectorMethodOrProcess].
			 intOrClass = TraceIncrementalGC ifTrue:
				[self print: 'incrementalGC'].
			 intOrClass = TraceFullGC ifTrue:
				[self print: 'fullGC'].
			 intOrClass = TraceCodeCompaction ifTrue:
				[self print: 'compactCode'].
			 intOrClass = TraceVMCallback ifTrue:
				[self print: 'callback'].
			 intOrClass = TraceVMCallbackReturn ifTrue:
				[self print: 'return from callback']]
		ifFalse:
			[self space; printNameOfClass: intOrClass count: 5; print: '>>'; printStringOf: selectorMethodOrProcess].
	source > TraceIsFromInterpreter ifTrue:
		[self space; print: (traceSources at: source)].
	self cr
]

{ #category : #'debug printing' }
CoInterpreter >> printMethodCacheFor: thing [
	<api>
	| n |
	n := 0.
	0 to: MethodCacheSize - 1 by: MethodCacheEntrySize do:
		[:i | | s c m p |
		s := methodCache at: i + MethodCacheSelector.
		c := methodCache at: i + MethodCacheClass.
		m := methodCache at: i + MethodCacheMethod.
		p := methodCache at: i + MethodCachePrimFunction.
		((thing = -1 or: [s = thing or: [c = thing or: [p = thing or: [m = thing
			or: [(objectMemory addressCouldBeObj: m)
				and: [(self maybeMethodHasCogMethod: m)
				and: [(self cogMethodOf: m) asInteger = thing]]]]]]])
		 and: [(objectMemory addressCouldBeOop: s)
		 and: [c ~= 0
		 and: [(self addressCouldBeClassObj: c)
			or: [self addressCouldBeClassObj: (objectMemory classForClassTag: c)]]]]) ifTrue:
			[n := n + 1.
			 self cCode: [] inSmalltalk: [self transcript ensureCr].
			 self printNum: i; space; printHexnp: i; cr; tab.
			 (objectMemory isBytesNonImm: s)
				ifTrue: [self cCode: 'vm_printf("%" PRIxSQPTR " %.*s\n", s, (int)(numBytesOf(s)), (char *)firstIndexableField(s))'
						inSmalltalk: [self printHex: s; space; print: (self stringOf: s); cr]]
				ifFalse: [self shortPrintOop: s].
			 self tab.
			 (self addressCouldBeClassObj: c)
				ifTrue: [self shortPrintOop: c]
				ifFalse: [self printNum: c; space; printHexnp: c; space; shortPrintOop: (objectMemory classForClassTag: c)].
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
CoInterpreter >> printMethodFieldForPrintContext: aContext [
	<inline: true>
	| meth |
	meth := objectMemory fetchPointer: MethodIndex ofObject: aContext.
	(self isMarriedOrWidowedContext: aContext)
		ifFalse:
			[self shortPrintOop: meth.
			(self methodHasCogMethod: meth) ifTrue:
				[self space; printHexnp: (self cogMethodOf: meth)]]
		ifTrue:
			[(self methodHasCogMethod: meth) ifTrue:
				[self printHexnp: (self cogMethodOf: meth); space].
			 self shortPrintOop: meth]
]

{ #category : #'debug printing' }
CoInterpreter >> printMethodHeaderOop: anOop [
	"Print the CogMethod and its header if this is a CogMethod reference."
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	(self isCogMethodReference: anOop) ifTrue:
		[cogMethod := cogMethodZone methodFor: (self pointerForOop: anOop).
		 cogMethod ~= 0 ifTrue:
			[^self printHex: anOop; space; printDecodeMethodHeaderOop: cogMethod methodHeader]].
	^self printDecodeMethodHeaderOop: anOop
]

{ #category : #'debug support' }
CoInterpreter >> printPrimLogEntryAt: i [
	<inline: false>
	| intOrSelector |
	intOrSelector := primTraceLog at: i.
	(objectMemory isImmediate: intOrSelector)
		ifTrue:
			[intOrSelector = TraceIncrementalGC ifTrue:
				[self print: '**IncrementalGC**'. ^nil].
			 intOrSelector = TraceFullGC ifTrue:
				[self print: '**FullGC**'. ^nil].
			 intOrSelector = TraceCodeCompaction ifTrue:
				[self print: '**CompactCode**'. ^nil].
			 intOrSelector = TraceStackOverflow ifTrue:
				[self print: '**StackOverflow**'. ^nil].
			 intOrSelector = TracePrimitiveFailure ifTrue:
				[self print: '**PrimitiveFailure**'. ^nil].
			 intOrSelector = TracePrimitiveRetry ifTrue:
				[self print: '**PrimitiveRetry**'. ^nil].
			 self print: '???']
		ifFalse:
			[intOrSelector = 0
				ifTrue: [self printNum: i; print: '!!!']
				ifFalse: [objectMemory safePrintStringOf: intOrSelector]]
]

{ #category : #'debug printing' }
CoInterpreter >> printSends [
	<inline: true>
	^cogit printOnTrace
]

{ #category : #'stack bytecodes' }
CoInterpreter >> pushClosureNumArgs: numArgs copiedValues: numCopied blockSize: blockSize [
	"The compiler has pushed the values to be copied, if any.
	 Create a Closure with space for the copiedValues and pop numCopied values off the stack into the closure.
	 Set numArgs as specified, and set startpc to the pc following the block size and jump over that code.

	Override only to add debug tracing as of 4/26/2009"
	<inline: true>
	| newClosure context |
	"No need to record the pushed copied values in the outerContext."
	context := self ensureFrameIsMarried: localFP SP: localSP + (numCopied * objectMemory bytesPerOop).
	newClosure := self
					closureIn: context
					numArgs: numArgs
					instructionPointer: (self oopForPointer: localIP) + 2 - (method+objectMemory baseHeaderSize)
					numCopiedValues: numCopied.
	cogit recordSendTrace ifTrue:
		[self recordTrace: TraceBlockCreation thing: newClosure source: TraceIsFromInterpreter].
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
CoInterpreter >> pushFullClosureNumArgs: numArgs copiedValues: numCopiedArg compiledBlock: compiledBlock receiverIsOnStack: receiverIsOnStack ignoreContext: ignoreContext [
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
	cogit recordSendTrace ifTrue:
		[self recordTrace: TraceBlockCreation thing: newClosure source: TraceIsFromInterpreter].
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

{ #category : #'stack bytecodes' }
CoInterpreter >> pushRemoteTemp: index inVectorAt: tempVectorIndex [
	"Override to use itemporary:in:put:"
	| tempVector |
	tempVector := self itemporary: tempVectorIndex in: localFP.
	TempVectReadBarrier
		ifTrue: 
			[(objectMemory isForwarded: tempVector) ifTrue:
				[tempVector := self unfollowTempVector: tempVector atIndex: tempVectorIndex in: localFP]].
	self internalPush: (objectMemory fetchPointer: index ofObject: tempVector)
]

{ #category : #'stack bytecodes' }
CoInterpreter >> pushTemporaryVariable: temporaryIndex [
	"Override to use itemporary:in:put:"
	self internalPush: (self itemporary: temporaryIndex in: localFP)
]

{ #category : #'cog jit support' }
CoInterpreter >> quickPrimitiveConstantFor: aQuickPrimitiveIndex [
	<api>
	^aQuickPrimitiveIndex caseOf: {
		[257] -> [objectMemory trueObject].
		[258] -> [objectMemory falseObject].
		[259] -> [objectMemory nilObject].
		[260] -> [ConstMinusOne].
		[261] -> [ConstZero].
		[262] -> [ConstOne].
		[263] -> [ConstTwo] }
]

{ #category : #'cog jit support' }
CoInterpreter >> quickPrimitiveGeneratorFor: aQuickPrimitiveIndex [
	<api>
	<returnTypeC: 'sqInt (*quickPrimitiveGeneratorFor(sqInt aQuickPrimitiveIndex))(void)'>
	^aQuickPrimitiveIndex
		caseOf: {
			[256] -> [#genQuickReturnSelf].
			[257] -> [#genQuickReturnConst].
			[258] -> [#genQuickReturnConst].
			[259] -> [#genQuickReturnConst].
			[260] -> [#genQuickReturnConst].
			[261] -> [#genQuickReturnConst].
			[262] -> [#genQuickReturnConst].
			[263] -> [#genQuickReturnConst] }
		otherwise: [#genQuickReturnInstVar]
]

{ #category : #'cog jit support' }
CoInterpreter >> quickPrimitiveInstVarIndexFor: primIndex [
	<api>
	^primIndex - 264
]

{ #category : #'compiled methods' }
CoInterpreter >> rawHeaderOf: methodPointer [
	<api>
	^objectMemory fetchPointer: HeaderIndex ofObject: methodPointer
]

{ #category : #'compiled methods' }
CoInterpreter >> rawHeaderOf: methodOop put: cogMethodOrMethodHeader [
	<api>
	"Since methods may be updated while forwarding during become, make the assert accomodate this."
	self assert: (objectMemory isCompiledMethodHeader: (objectMemory headerWhileForwardingOf: methodOop)).
	objectMemory
		storePointerUnchecked: HeaderIndex
		ofObject: methodOop
		withValue: cogMethodOrMethodHeader
]

{ #category : #'image save/restore' }
CoInterpreter >> readImageFromFile: f HeapSize: desiredHeapSize StartingAt: imageOffset [
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

	| swapBytes headerStart headerSize dataSize oldBaseAddr
	  minimumMemory heapSize bytesRead bytesToShift firstSegSize
	  hdrNumStackPages hdrEdenBytes hdrCogCodeSize headerFlags hdrMaxExtSemTabSize allocationReserve |
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
	extraVMMemory	:= self getWord32FromFile: f swap: swapBytes. "N.B.  ignored in V3."
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
	"This slot holds the size of the native method zone in 1k units. (pad to word boundary)."
	hdrCogCodeSize := (self getShortFromFile: f swap: swapBytes) * 1024.
	cogCodeSize := desiredCogCodeSize ~= 0
						ifTrue: [desiredCogCodeSize]
						ifFalse:
							[hdrCogCodeSize = 0
									ifTrue: [cogit defaultCogCodeSize]
									ifFalse: [hdrCogCodeSize]].
	cogCodeSize > cogit maxCogCodeSize ifTrue:
		[cogCodeSize := cogit maxCogCodeSize].
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
	minimumMemory := cogCodeSize "no need to include the stackZone; this is alloca'ed"
						+ dataSize
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
						   cogCodeSize "no need to include the stackZone; this is alloca'ed"
						+ dataSize
						+ headroom
						+ objectMemory newSpaceBytes
						+ (headroom > allocationReserve
							ifTrue: [0]
							ifFalse: [allocationReserve])]
		ifFalse:
			[heapSize :=  cogCodeSize "no need to include the stackZone; this is alloca'ed"
						+ desiredHeapSize
						+ objectMemory newSpaceBytes
						+ (desiredHeapSize - dataSize > allocationReserve
							ifTrue: [0]
							ifFalse: [allocationReserve]).
			 heapSize < minimumMemory ifTrue:
				[self insufficientMemorySpecifiedError]].

	"allocate a contiguous block of memory for the Squeak heap and ancilliary data structures"
	objectMemory memory: (self
								allocateMemory: heapSize
								minimum: minimumMemory
								imageFile: f
								headerSize: headerSize
								desiredPosition: oldBaseAddr) asUnsignedInteger.
	objectMemory memory ifNil:
		[self insufficientMemoryAvailableError].

	heapBase := objectMemory
					setHeapBase: objectMemory memory + cogCodeSize
					memoryLimit: objectMemory memory + heapSize
					endOfMemory: objectMemory memory + cogCodeSize + dataSize.

	"position file after the header"
	self sqImageFile: f Seek: headerStart + headerSize.

	"read in the image in bulk, then swap the bytes if necessary"
	bytesRead := objectMemory readHeapFromImageFile: f dataBytes: dataSize.
	bytesRead ~= dataSize ifTrue: [self unableToReadImageError].

	self ensureImageFormatIsUpToDate: swapBytes.

	"compute difference between old and new memory base addresses"
	bytesToShift := objectMemory memoryBaseForImageRead - oldBaseAddr.
	self initializeInterpreter: bytesToShift.  "adjusts all oops to new location"
	self initializeCodeGenerator.
	^dataSize
]

{ #category : #'internal interpreter access' }
CoInterpreter >> receiver [
	<inline: true>
	^stackPages longAt: localFP + FoxIFReceiver
]

{ #category : #'debug support' }
CoInterpreter >> recordContextSwitchFrom: aProcess in: sourceCode [
	cogit recordEventTrace ifTrue:
		[self recordTrace: TraceContextSwitch thing: aProcess source: sourceCode]
]

{ #category : #'debug support' }
CoInterpreter >> recordTrace: classOrInteger thing: selector source: source [
	traceLog at: traceLogIndex put: classOrInteger.
	traceLog at: traceLogIndex + 1 put: selector.
	traceLog at: traceLogIndex + 2 put: source.
	traceLogIndex := traceLogIndex + 3 \\ TraceBufferSize
]

{ #category : #'debug support' }
CoInterpreter >> reportMinimumUnusedHeadroom [
	"Report the stack page size and minimum unused headroom to stdout."
	<api>
	self cCode:
			[self vm_printf: 'stack page bytes %lld available headroom %lld minimum unused headroom %lld\n'
				_: self stackPageByteSize asUnsignedLongLong
				_: (self stackPageByteSize - self stackLimitBytes - self stackLimitOffset) asUnsignedLongLong
				_: self minimumUnusedHeadroom asUnsignedLongLong]
		inSmalltalk:
			["CogVMSimulator new initStackPagesForTests reportMinimumUnusedHeadroom"
			 self print: 'stack page bytes '; printNum: self stackPageByteSize;
				print: ' available headroom '; printNum: self stackPageByteSize - self stackLimitBytes - self stackLimitOffset;
				print: ' minimum unused headroom '; printNum: self minimumUnusedHeadroom;
				cr]
]

{ #category : #'callback support' }
CoInterpreter >> restoreCStackStateForCallbackContext: vmCallbackContext [
	<var: #vmCallbackContext type: #'VMCallbackContext *'>
	cogit
		setCStackPointer: vmCallbackContext savedCStackPointer;
		setCFramePointer: vmCallbackContext savedCFramePointer.

	super restoreCStackStateForCallbackContext: vmCallbackContext
]

{ #category : #'process primitive support' }
CoInterpreter >> resume: aProcess [
	"Replaced by resume:preemptedYieldingIf:from:"
	"Make aProcess runnable and if its priority is higher than
	 that of the current process, preempt the current process.
	 Answer if the current process was preempted.  Override
	 to add tracing info (see resume:from:)."
	<doNotGenerate>
	self shouldNotImplement
]

{ #category : #'process primitive support' }
CoInterpreter >> resume: aProcess preemptedYieldingIf: yieldImplicitly [
	"Replaced by resume:preemptedYieldingIf:from:"
	"Make aProcess runnable and if its priority is higher than  that of the
	 current process, preempt the current process.   Answer if the current
	 process was preempted.  If the current process was preempted then if
	 yieldImplicitly add the current process to the back of its run queue,
	 causing an implicit yiled to other processes on the run queue,  otherwise
	 add the current process to the front of its run queue, hence not yielding.
	 Blue book behaviour is to yield implicitly but is arguably incorrect."
	<doNotGenerate>
	self shouldNotImplement
]

{ #category : #'process primitive support' }
CoInterpreter >> resume: aProcess preemptedYieldingIf: yieldImplicitly from: sourceCode [
	"Make aProcess runnable and if its priority is higher than  that of the
	 current process, preempt the current process.   Answer if the current
	 process was preempted.  If the current process was preempted then if
	 yieldImplicitly add the current process to the back of its run queue,
	 causing an implicit yeild to other processes on the run queue,  otherwise
	 add the current process to the front of its run queue, hence not yielding.
	 Blue book behaviour is to yield implicitly but is arguably incorrect.
	 Override to add tracing info."
	| activeProc activePriority newPriority |
	<inline: false>
	activeProc := self activeProcess.
	activePriority := self quickFetchInteger: PriorityIndex ofObject: activeProc.
	newPriority := self quickFetchInteger: PriorityIndex ofObject: aProcess.
	newPriority <= activePriority ifTrue:
		[self putToSleep: aProcess yieldingIf: true.
		 ^false].
	self putToSleep: activeProc yieldingIf: yieldImplicitly.
	self transferTo: aProcess from: sourceCode.
	^true
]

{ #category : #enilopmarts }
CoInterpreter >> return: returnValue toExecutive: inInterpreter [
	"We have made a context switch, either when interpreting or from machine code.
	 Effectively return to the current frame, either by entering machine code, or
	 longjmp-ing back to the interpreter or simply returning, depending on where we are."

	cogit assertCStackWellAligned.
	(self isMachineCodeFrame: framePointer) ifTrue:
		[self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: false line: #'__LINE__'.
		 self push: instructionPointer.
		 self push: returnValue.
		 cogit ceEnterCogCodePopReceiverReg
		 "NOTREACHED"].
	self push: returnValue.
	self setMethod: (self iframeMethod: framePointer).
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: true line: #'__LINE__'.
	instructionPointer = cogit ceReturnToInterpreterPC ifTrue:
		[instructionPointer := self iframeSavedIP: framePointer].
	inInterpreter ifTrue:
		[^nil].
	self siglong: reenterInterpreter jmp: ReturnToInterpreter.
	"NOTREACHED"
	^nil
]

{ #category : #enilopmarts }
CoInterpreter >> returnToExecutive: inInterpreter postContextSwitch: switchedContext [
	"Return to the current frame, either by entering machine code, or longjmp-ing back to the
	 interpreter or simply returning, depending on where we are. To know whether to return or
	 enter machine code we have to know from whence we came.  We could have come from
	 the interpreter, either directly or via a machine code primitive.  We could have come from
	 machine code.  The instructionPointer tells us where from.  If it is above startOfMemory we're
	 in the interpreter.  If it is below, then we are in machine-code unless it is ceReturnToInterpreterPC,
	 in which case we're in a machine-code primitive called from the interpreter."
	<inline: false>
	| cogMethod retValue fullyInInterpreter |
	<var: #cogMethod type: #'CogBlockMethod *'>

	cogit assertCStackWellAligned.
	(self isMachineCodeFrame: framePointer) ifTrue:
		[self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: false line: #'__LINE__'.
		 "If returning after a context switch then a result may have to be popped from the stack.
		  If the process is suspended at a send then the result of the primitive in which the
		  process was suspended is still on the stack and must be popped into ReceiverResultReg.
		  If not, nothing should be popped and ReceiverResultReg gets the receiver."
		 switchedContext
			ifTrue:
				[cogMethod := self mframeCogMethod: framePointer.
				self assert: (instructionPointer > cogit minCogMethodAddress 
							and: [instructionPointer < cogit maxCogMethodAddress]).
				 (instructionPointer ~= (cogMethod asInteger + cogMethod stackCheckOffset)
				  and: [cogit isSendReturnPC: instructionPointer])
					ifTrue:
						[self assert: (objectMemory addressCouldBeOop: self stackTop).
						 retValue := self popStack]
					ifFalse:
						[retValue := self mframeReceiver: framePointer]]
			ifFalse: [retValue := self mframeReceiver: framePointer].
		 self push: instructionPointer.
		 self push: retValue.
		 cogit ceEnterCogCodePopReceiverReg
		 "NOTREACHED"].
	self setMethod: (self iframeMethod: framePointer).
	fullyInInterpreter := inInterpreter.
	instructionPointer = cogit ceReturnToInterpreterPC ifTrue:
		[instructionPointer := (self iframeSavedIP: framePointer) asUnsignedInteger.
		 fullyInInterpreter := false].
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: true line: #'__LINE__'.
	fullyInInterpreter ifFalse:
		[self siglong: reenterInterpreter jmp: ReturnToInterpreter.
		 "NOTREACHED"].
	^nil
]

{ #category : #'return bytecodes' }
CoInterpreter >> returnToMachineCodeFrame [
	"Return to the previous context/frame after assigning localIP, localSP and localFP."
	<inline: true>
	cogit assertCStackWellAligned.
	self assert: localIP asUnsignedInteger < objectMemory startOfMemory.
	self assert: (self isMachineCodeFrame: localFP).
	self assertValidExecutionPointe: localIP asUnsignedInteger r: localFP s: localSP imbar: false line: #'__LINE__'.
	self internalStackTopPut: localIP.
	self internalPush: localReturnValue.
	self externalizeFPandSP.
	self cCode: '' inSmalltalk:
		[self maybeCheckStackDepth: 1 sp: stackPointer pc: localIP].
	cogit ceEnterCogCodePopReceiverReg
	"NOTREACHED"
]

{ #category : #'method lookup cache' }
CoInterpreter >> rewriteMethodCacheEntryForExternalPrimitiveToFunction: localPrimAddress [
	"Rewrite an existing entry in the method cache with a new primitive function address.
	 Used by primitiveExternalCall to make direct calls to found external prims, or quickly
	 fail not found external prims.
	 Override to do the same to the machine code call.  If methodObj has a cogged dual
	 rewrite the primitive call in it to call localPrimAddress. Used to update calls through
	 primitiveExternalCall to directly call the target function or to revert to calling
	 primitiveExternalCall after a flush."
	<var: #localPrimAddress declareC: 'void (*localPrimAddress)(void)'>
	<inline: false>
	(self methodHasCogMethod: newMethod) ifTrue:
		[cogit
			rewritePrimInvocationIn: (self cogMethodOf: newMethod)
			to: (localPrimAddress = 0
				ifTrue: [self cCoerceSimple: #primitiveFail to: #'void (*)(void)']
				ifFalse: [localPrimAddress])].
	(methodCache at: lastMethodCacheProbeWrite + MethodCacheMethod) = newMethod ifTrue:
		[methodCache
			at: lastMethodCacheProbeWrite + MethodCachePrimFunction
			put: (self cCoerce: localPrimAddress to: #'sqIntptr_t')]
]

{ #category : #'primitive support' }
CoInterpreter >> roomToPushNArgs: n [
	"Answer if there is room to push n arguments onto the current stack.  We assume
	 this is called by primitives that check there is enough room in any new context, and
	 won't actually push the arguments in the current context if the primitive fails.  With
	 this assumption it is safe to answer based on the maximum argument count, /not/
	 the ammount of space in the current frame were it converted to a context.."
	false
		ifTrue: "old code that checked size of context..."
			[| methodHeader cntxSize |
			(self isMachineCodeFrame: framePointer)
				ifTrue: [methodHeader := (self mframeHomeMethod: framePointer) methodHeader]
				ifFalse: [methodHeader := objectMemory methodHeaderOf: (self iframeMethod: framePointer)].
			cntxSize := (self methodHeaderIndicatesLargeFrame: methodHeader)
							ifTrue: [LargeContextSlots - CtxtTempFrameStart]
							ifFalse: [SmallContextSlots - CtxtTempFrameStart].
			^self stackPointerIndex + n <= cntxSize]
		ifFalse: "simpler code that simply insists args are <= max arg count"
			[^n <= (LargeContextSlots - CtxtTempFrameStart)]
]

{ #category : #'callback support' }
CoInterpreter >> saveCStackStateForCallbackContext: vmCallbackContext [
	<var: #vmCallbackContext type: #'VMCallbackContext *'>
	vmCallbackContext
		savedCStackPointer: cogit getCStackPointer;
		savedCFramePointer: cogit getCFramePointer.
	super saveCStackStateForCallbackContext: vmCallbackContext
]

{ #category : #'cog jit support' }
CoInterpreter >> scavengeThreshold [
	<doNotGenerate>
	^objectMemory scavengeThreshold
]

{ #category : #'callback support' }
CoInterpreter >> sendInvokeCallback: thunkPtr Stack: stackPtr Registers: regsPtr Jmpbuf: jmpBufPtr [
	"Override to log and check stack alignment.  Since this is an implicit send we need to
	 log it explicitly. The return side is done via a primitive so that gets logged normally."
	cogit assertCStackWellAligned.
	cogit recordPrimTrace ifTrue:
		[self fastLogPrim: (self splObj: SelectorInvokeCallback)].
	^super sendInvokeCallback: thunkPtr Stack: stackPtr Registers: regsPtr Jmpbuf: jmpBufPtr
]

{ #category : #'callback support' }
CoInterpreter >> sendInvokeCallbackContext: vmCallbackContext [
	"Override to log and check stack alignment.  Since this is an implicit send we need to
	 log it explicitly. The return side is done via a primitive so that gets logged normally."
	cogit assertCStackWellAligned.
	cogit recordPrimTrace ifTrue:
		[self fastLogPrim: (self splObj: SelectorInvokeCallback)].
	^super sendInvokeCallbackContext: vmCallbackContext
]

{ #category : #'internal interpreter access' }
CoInterpreter >> setCogCodeZoneThreshold: threshold [
	<doNotGenerate>
	<var: 'threshold' type: #double>
	^cogit setCogCodeZoneThreshold: threshold
]

{ #category : #'internal interpreter access' }
CoInterpreter >> setCogVMFlags: flags [
	"Set an array of flags indicating various properties of the Cog VM.
	 Bit 0: if set, implies the image's Process class has threadId as its 3rd inst var (zero relative)
	 Bit 1: if set, methods that are interpreted will have the flag bit set in their header
	 Bit 2: if set, implies preempting a process does not put it to the back of its run queue
	 Bit 3: if set, implies a threaded VM will not dosown the VM if owned by the GUI thread
	 Bit 4: if set, implies the new finalization scheme where WeakArrays are queued
	 Bit 5: if set, implies wheel events will be delivered as such and not mapped to arrow key events"
	flags asUnsignedInteger > 63 ifTrue:
		[^self primitiveFailFor: PrimErrUnsupported].
	"processHasThreadId := flags anyMask: 1. specific to CoInterpreterMT"
	flagInterpretedMethods := flags anyMask: 2.
	preemptionYields := flags noMask: 4.
	"noThreadingOfGUIThread := flags anyMask: 8.. specific to CoInterpreterMT"
	newFinalization := flags anyMask: 16.
	sendWheelEvents := flags anyMask: 32
]

{ #category : #'internal interpreter access' }
CoInterpreter >> setDesiredCogCodeSize: dccs [
	<inline: true>
	desiredCogCodeSize := dccs
]

{ #category : #'object memory support' }
CoInterpreter >> setGCMode: mode [
	gcMode := mode
]

{ #category : #'frame access' }
CoInterpreter >> setIFrameHasContext: theFP [
	"See encodeFrameFieldHasContext:numArgs:"
	<inline: true>
	<var: #theFP type: #'char *'>
	stackPages byteAt: theFP + FoxIFrameFlags + 2 put: 1
]

{ #category : #'image save/restore' }
CoInterpreter >> setImageHeaderFlagsFrom: headerFlags [
	"Set the flags that are contained in the 7th long of the image header."
	imageHeaderFlags := headerFlags. "so as to preserve unrecognised flags."
	fullScreenFlag := headerFlags bitAnd: 1.
	imageFloatsBigEndian := (headerFlags noMask: 2) ifTrue: [1] ifFalse: [0].
	"processHasThreadId := headerFlags anyMask: 4. specific to CoInterpreterMT"
	flagInterpretedMethods := headerFlags anyMask: 8.
	preemptionYields := headerFlags noMask: 16.
	"noThreadingOfGUIThread := headerFlags anyMask: 32. specific to CoInterpreterMT"
	newFinalization := headerFlags anyMask: 64.
	sendWheelEvents := headerFlags anyMask: 128
]

{ #category : #'internal interpreter access' }
CoInterpreter >> setMethod: aMethodObj [
	self assert: aMethodObj asUnsignedInteger >= objectMemory startOfMemory.
	super setMethod: aMethodObj
]

{ #category : #'debug support' }
CoInterpreter >> setUpForUseByFacade: aCurrentImageCoInterpreterFacade [
	"Set up variables with default values so that other initializations work.
	 numStackPages needs to be initialized so that interpreterAllocationReserveBytes
	 can be computed."
	<doNotGenerate>
	numStackPages := 0
]

{ #category : #'debug printing' }
CoInterpreter >> shortPrintFrame: theFP [
	<inline: false>
	<var: #theFP type: #'char *'>
	| rcvr mthd |
	
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
	mthd := self frameMethodObject: theFP.
	self printHexPtr: theFP.
	self space.
	self printChar: ((self isMachineCodeFrame: theFP) ifTrue: [$M] ifFalse: [$I]).
	self space.
	self printActivationNameFor: mthd
		receiver: rcvr
		isBlock: (self frameIsBlockActivation: theFP)
		firstTemporary: (self temporary: 0 in: theFP).
	self space.
	self shortPrintOop: rcvr "shortPrintOop: adds a cr"
]

{ #category : #'cog jit support' }
CoInterpreter >> siglong: aJumpBuf jmp: returnValue [
	"Hack simulation of sigsetjmp/siglongjmp.
	 Signal the exception that simulates a longjmp back to the interpreter." 
	<doNotGenerate>
	(aJumpBuf == reenterInterpreter
	 and: [returnValue ~= 2 "2 == returnToThreadSchedulingLoopVia:"]) ifTrue:
		[self assert: (self isOnRumpCStack: cogit processor sp).
		 self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: true line: nil].
	"Restore the Registers"
	cogit processor sp: (aJumpBuf properties at: #savedSP).
	aJumpBuf returnValue: returnValue; signal.
]

{ #category : #trampolines }
CoInterpreter >> signed32BitIntegerFor: integerValue [
	<api>
	^super signed32BitIntegerFor: integerValue
]

{ #category : #trampolines }
CoInterpreter >> signed32BitValueOf: oop [
	<api>
	^super signed32BitValueOf: oop
]

{ #category : #trampolines }
CoInterpreter >> signed64BitIntegerFor: integerValue [
	<api>
	^super signed64BitIntegerFor: integerValue
]

{ #category : #trampolines }
CoInterpreter >> signed64BitValueOf: oop [
	<api>
	^super signed64BitValueOf: oop
]

{ #category : #'runtime support' }
CoInterpreter >> sigset: aJumpBuf jmp: sigSaveMask [
	"Hack simulation of sigsetjmp/siglongjmp.
	 Assign to reenterInterpreter the exception that when
	 raised simulates a longjmp back to the interpreter." 
	<doNotGenerate>
	| result |
	result := super sigset: aJumpBuf jmp: sigSaveMask.
	reenterInterpreter properties at: #savedSP put: cogit processor sp.
	^result
]

{ #category : #'primitive support' }
CoInterpreter >> slowPrimitiveResponse [
	"Invoke a normal (non-quick) primitive.
	 Called under the assumption that primFunctionPointer has been preloaded.
	 Override to log primitive."
	cogit recordPrimTrace ifTrue:
		[self fastLogPrim: messageSelector].
	^super slowPrimitiveResponse
]

{ #category : #'cog jit support' }
CoInterpreter >> specialSelectorNumArgs: index [ "<SmallInteger>"
	<api>
	^objectMemory integerValueOf: (objectMemory fetchPointer: (index * 2) + 1
							ofObject: (objectMemory splObj: SpecialSelectors))
]

{ #category : #'trampoline support' }
CoInterpreter >> stackLimitAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: '(usqInt)&GIV(stackLimit)'
		  inSmalltalk: [cogit simulatedVariableAddress: #stackLimitFromMachineCode in: self]
]

{ #category : #'stack pages' }
CoInterpreter >> stackLimitOffset [
	"Answer the amount of slots needed to fit a new frame at the point the stack
	 limit is checked.  A frame looks like this at the point the stack limit is checked:
			stacked receiver/closure
			arg0
			...
			argN
			caller's method ip/base frame's sender context
	fp->	saved fp
			method
			context (uninitialized?)
			method header fields (interpreter only)
			saved method ip (uninitialized?; interpreter only)
			receiver
			first temp
			...
	sp->	Nth temp
	So the amount of headroom is
		the maximum number of arguments + 1 (for stacked receiver and arguments)
		+ the frame size
		+ the max number of temps.
	 Since a method's number of temps includes its arguments the actual offset is:"
	^(IFrameSlots + 64) * objectMemory wordSize
]

{ #category : #'stack pages' }
CoInterpreter >> stackPageHeadroom [
	"Return a minimum amount of headroom for each stack page (in bytes).
	 In the interpreter we don't actually need any headroom.  In a JIT the stack
	 has to have room for interrupt handlers which will run on the stack.
	 Defer to the platform for this one."
	<inline: true>
	^self osCogStackPageHeadroom
]

{ #category : #initialization }
CoInterpreter >> stackPagesClass [
	<doNotGenerate>
	^VMBIGENDIAN
		ifTrue: [CoInterpreterStackPagesMSB]
		ifFalse: [CoInterpreterStackPagesLSB]
]

{ #category : #'cog jit support' }
CoInterpreter >> stackPointer: theSP [
	"Simulation only"
	<doNotGenerate>
	stackPointer := theSP
]

{ #category : #'trampoline support' }
CoInterpreter >> stackPointerAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: stackPointer) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #stackPointer in: self]
]

{ #category : #'frame access' }
CoInterpreter >> stackPointerIndexForFrame: theFP WithSP: theSP [
	"Return the 1-based index rel to the given frame"
	"In the StackInterpreter stacks grow down."
	^(self isMachineCodeFrame: theFP)
		ifTrue: [(((theFP + FoxMFReceiver) - theSP) >> objectMemory shiftForWord) + (self mframeNumArgs: theFP)]
		ifFalse: [(((theFP + FoxIFReceiver) - theSP) >> objectMemory shiftForWord) + (self iframeNumArgs: theFP)]
]

{ #category : #'frame access' }
CoInterpreter >> stackPointerIndexForIFrame: theFP WithSP: theSP numArgs: numArgs [
	"Return the 1-based index rel to the given frame"
	"In the StackInterpreter stacks grow down."
	^(((theFP + FoxIFReceiver) - theSP) >> objectMemory shiftForWord) + numArgs
]

{ #category : #'frame access' }
CoInterpreter >> stackPointerIndexForMFrame: theFP WithSP: theSP numArgs: numArgs [
	"Return the 1-based index rel to the given machine code frame"
	"In the StackInterpreter stacks grow down."
	^(((theFP + FoxMFReceiver) - theSP) >> objectMemory shiftForWord) + numArgs
]

{ #category : #'compiled methods' }
CoInterpreter >> startPCOfClosure: aBlockClosure [
	"Zero-relative version of BlockClosure>>startpc."
	^(objectMemory integerValueOf: (objectMemory fetchPointer: ClosureStartPCIndex ofObject: aBlockClosure)) - 1
]

{ #category : #'compiled methods' }
CoInterpreter >> startPCOfMethodHeader: aCompiledMethodHeader [
	<api>
	"Zero-relative version of CompiledMethod>>startpc."
	^(objectMemory literalCountOfMethodHeader: aCompiledMethodHeader) + LiteralStart * objectMemory bytesPerOop
]

{ #category : #'cog jit support' }
CoInterpreter >> startPCOrNilOfLiteral: lit in: aMethodObj [
	"Answer the startPC of lit if it is a (clean) block in aMethodObj, otherwise answer nil."
	<api>
	| outerContext |
	((objectMemory isNonImmediate: lit)
	 and: [(objectMemory formatOf: lit) = objectMemory indexablePointersFormat
	 and: [(objectMemory numSlotsOf: lit) >= ClosureFirstCopiedValueIndex]]) ifFalse:
		[^nil].
	outerContext := objectMemory fetchPointer: ClosureOuterContextIndex ofObject: lit.
	(objectMemory isContext: outerContext) ifFalse:
		[^nil].
	aMethodObj ~~ (objectMemory fetchPointer: MethodIndex ofObject: outerContext) ifTrue:
		[^nil].
	^self quickFetchInteger: ClosureStartPCIndex ofObject: lit
]

{ #category : #'stack bytecodes' }
CoInterpreter >> storeAndPopTemporaryVariableBytecode [
	<expandCases>
	self
		cCode: "this bytecode will be expanded so that refs to currentBytecode below will be constant"
			[self fetchNextBytecode.
			 self itemporary: (currentBytecode bitAnd: 7) in: localFP put: self internalStackTop.
			 self internalPop: 1]
		inSmalltalk: "Interpreter version has fetchNextBytecode out of order"
			[self itemporary: (currentBytecode bitAnd: 7) in: localFP put: self internalStackTop.
			 self fetchNextBytecode.
			 self internalPop: 1]
]

{ #category : #'stack bytecodes' }
CoInterpreter >> storeRemoteTemp: index inVectorAt: tempVectorIndex [
	"Override to use itemporary:in:put:"
	| tempVector |
	tempVector := self itemporary: tempVectorIndex in: localFP.
	TempVectReadBarrier
		ifTrue: 
			[(objectMemory isForwarded: tempVector) ifTrue:
				[tempVector := self unfollowTempVector: tempVector atIndex: tempVectorIndex in: localFP]].
	objectMemory storePointer: index ofObject: tempVector withValue: self internalStackTop
]

{ #category : #'process primitive support' }
CoInterpreter >> synchronousSignal: aSemaphore [ 
	"Signal the given semaphore from within the interpreter.
	 Answer if the current process was preempted.
	 Override to add tracing info."
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
		from: CSSignal
]

{ #category : #'return bytecodes' }
CoInterpreter >> tearDownAndRebuildFrameForCannotReturnBaseFrameReturnFrom: contextToReturnFrom to: contextToReturnTo returnValue: returnValue [
	"Handle the cannot return response for a base frame return to an invalid context.
	 Build a new base frame for the context in the cannot resume state ready for the
	 send of cannotReturn:.

	 Since we have returned from the base frame of the page the context is effectively widowed.
	 But its sender needs to be contextToReturnTo, and its pc needs to be the HasBeenReturnedFromMCPC
	 marker.  So bereave it (as a side-effect of isWidowedContext:), assign contextToReturnTo to
	 sender, and rebuild its frame, which will have the ceCannotResumePC as its pc.  Finally push
	 returnValue and set instructionPointer to ceCannotResumePC in preparation for the send."
	| newPage |
	<inline: false>
	<var: #newPage type: #'StackPage *'>
	self assert: (stackPage ~= 0 and: [stackPage isFree]).
	self isWidowedContext: contextToReturnFrom.
	self assert: (self isMarriedOrWidowedContext: contextToReturnFrom) not.
	objectMemory
		storePointer: SenderIndex ofObject: contextToReturnFrom withValue: contextToReturnTo;
		storePointer: InstructionPointerIndex ofObject: contextToReturnFrom withValue: HasBeenReturnedFromMCPCOop.
	"void the instructionPointer to stop it being incorrectly updated in a code
	 compaction in makeBaseFrameFor:."
	instructionPointer := 0.
	newPage := self makeBaseFrameFor: contextToReturnFrom.
	self assert: stackPage = newPage.
	self setStackPageAndLimit: newPage.
	self setStackPointersFromPage: newPage.
	self assert: self stackTop = cogit ceCannotResumePC.
	"overwrite the ceSendCannotResumePC on the stack.  If ever re-executed
	 the returnValue will be taken from top-of-stack by ceCannotResume."
	self stackTopPut: returnValue.
	"Assign it to instructionPointer as externalCannotReturn:from: pushes it."
	instructionPointer := cogit ceCannotResumePC
]

{ #category : #'internal interpreter access' }
CoInterpreter >> temporary: offset in: theFP [
	"See StackInterpreter class>>initializeFrameIndices"
	| frameNumArgs |
	<inline: true>
	<var: #theFP type: #'char *'>
	^(self isMachineCodeFrame: theFP)
		ifTrue:
			[offset < (frameNumArgs := self mframeNumArgs: theFP)
				ifTrue: [stackPages longAt: theFP + FoxCallerSavedIP + ((frameNumArgs - offset) * objectMemory wordSize)]
				ifFalse: [stackPages longAt: theFP + FoxMFReceiver - objectMemory wordSize + ((frameNumArgs - offset) * objectMemory wordSize)]]
		ifFalse:
			[self itemporary: offset in: theFP]
]

{ #category : #'internal interpreter access' }
CoInterpreter >> temporary: offset in: theFP put: valueOop [
	<inline: true>
	^(self isMachineCodeFrame: theFP)
		ifTrue: [self mtemporary: offset in: theFP put: valueOop]
		ifFalse: [self itemporary: offset in: theFP put: valueOop]
]

{ #category : #'internal interpreter access' }
CoInterpreter >> temporaryLocation: offset in: theFP numArgs: numArgs [
	"Answer the pointer to a given temporary (for debug frame printing in odd circumstances)"
	<var: #theFP type: #'char *'>
	<returnTypeC: #'char *'>
	^offset < numArgs
		ifTrue: [theFP + FoxCallerSavedIP + ((numArgs - offset) * objectMemory wordSize)]
		ifFalse: [theFP
			+ ((self isMachineCodeFrame: theFP)
					ifTrue: [FoxMFReceiver - objectMemory wordSize]
					ifFalse: [FoxIFReceiver - objectMemory wordSize])
			+ ((numArgs - offset) * objectMemory wordSize)]
]

{ #category : #simulation }
CoInterpreter >> threadManager [
	<doNotGenerate>
	^nil
]

{ #category : #simulation }
CoInterpreter >> transcript [
	<doNotGenerate>
	^Transcript
]

{ #category : #'process primitive support' }
CoInterpreter >> transferTo: newProc [
	"replaced by transferTo:from: for better tracing (for debugging)"

	^ self transferTo: newProc from: 0
]

{ #category : #'process primitive support' }
CoInterpreter >> transferTo: newProc from: sourceCode [
	"Record a process to be awoken on the next interpreter cycle.
	 Reimplement to record the source of the switch for debugging,
	 and to cope with possible code compaction in makeBaseFrameFor:."
	| activeContext sched oldProc |
	<inline: false>
	statProcessSwitch := statProcessSwitch + 1.
	self push: instructionPointer.
	self externalWriteBackHeadFramePointers.
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer.
	"ensureMethodIsCogged: in makeBaseFrameFor: in
	 externalSetStackPageAndPointersForSuspendedContextOfProcess:
	 below may do a code compaction. Nil instructionPointer to avoid it getting pushed twice."
	instructionPointer := 0.
	sched := self schedulerPointer.
	oldProc := objectMemory fetchPointer: ActiveProcessIndex ofObject: sched.
	self recordContextSwitchFrom: oldProc in: sourceCode.
	activeContext := self ensureFrameIsMarried: framePointer SP: stackPointer + objectMemory wordSize.
	objectMemory storePointer: SuspendedContextIndex ofObject: oldProc withValue: activeContext.
	objectMemory storePointer: ActiveProcessIndex ofObject: sched withValue: newProc.
	objectMemory storePointerUnchecked: MyListIndex ofObject: newProc withValue: objectMemory nilObject.
	self externalSetStackPageAndPointersForSuspendedContextOfProcess: newProc
]

{ #category : #'compiled methods' }
CoInterpreter >> unfollowTempVector: tempVector atIndex: tempVectorIndex in: theFP [
	"override for itemporary"
	<option: #TempVectReadBarrier>
	<inline: #never> "So rare it mustn't bulk up the common path"
	| followed |
	followed := objectMemory followForwarded: tempVector.
	self itemporary: tempVectorIndex in: theFP put: followed.
	^followed
]

{ #category : #'image save/restore' }
CoInterpreter >> unknownShortOrCodeSizeInKs [
	^desiredCogCodeSize + 1023 // 1024
]

{ #category : #'code compaction' }
CoInterpreter >> updateStackZoneReferencesToCompiledCodePreCompaction [
	<api>
	<var: #thePage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #theIPPtr type: #'char *'>
	<var: #theIP type: #usqInt>
	<var: #theMethod type: #'CogMethod *'>
	0 to: numStackPages - 1 do:
		[:i| | thePage theFP callerFP theIPPtr theIP theMethodField theFlags theMethod |
		thePage := stackPages stackPageAt: i.
		(stackPages isFree: thePage) ifFalse:
			[theIPPtr := thePage headSP.
			 theFP := thePage  headFP.
			 [(self isMachineCodeFrame: theFP) ifTrue:
				[theMethodField := self frameMethodField: theFP.
				 theFlags := theMethodField bitAnd: MFMethodFlagsMask.
				 theMethod := self cCoerceSimple: theMethodField - theFlags to: #'CogMethod *'.
				 theMethod cmType = CMBlock ifTrue:
					[theMethod := (self cCoerceSimple: theMethodField - theFlags to: #'CogBlockMethod *') cmHomeMethod].
				 theIP := (stackPages longAt: theIPPtr) asUnsignedInteger.
				 (theIP ~= cogit ceCannotResumePC
				  and: [self asserta: (theIP >= theMethod asUnsignedInteger
							   and: [theIP < (theMethod asUnsignedInteger + theMethod blockSize)])]) ifTrue:
					[stackPages
						longAt: theIPPtr
						put: theIP + theMethod objectHeader].
				 stackPages
					longAt: theFP + FoxMethod
					put: theMethodField + theMethod objectHeader].
			 (callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
				[theIPPtr := theFP + FoxCallerSavedIP.
				 theFP := callerFP]]]
]

{ #category : #'frame access' }
CoInterpreter >> updateStateOfSpouseContextForFrame: theFP WithSP: theSP [
	"Update the frame's spouse context with the frame's current state except for the
	 sender and instruction pointer, which are used to mark the context as married."
	| theContext tempIndex pointer argsPointer |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #pointer type: #'char *'>
	<var: #argsPointer type: #'char *'>
	self assert: (self frameHasContext: theFP).
	theContext := self frameContext: theFP.
	self assert: (objectMemory isContext: theContext).
	self assert: (self frameReceiver: theFP)
				= (objectMemory noFixupFollowField: ReceiverIndex ofObject: theContext).
	(self isMachineCodeFrame: theFP)
		ifTrue:
			[tempIndex := self mframeNumArgs: theFP.
			 pointer := theFP + FoxMFReceiver - objectMemory wordSize]
		ifFalse:
			[tempIndex := self iframeNumArgs: theFP.
			 pointer := theFP + FoxIFReceiver - objectMemory wordSize].
	"update the arguments. this would appear not to be strictly necessary, but is for two reasons.
	 First, the fact that arguments are read-only is only as convention in the Smalltalk compiler;
	 other languages may choose to modify arguments.
	 Second, the Squeak runUntilErrorOrReturnFrom: nightmare pops the stack top, which may, in
	 certain circumstances, be the last argument, and hence the last argument may not have been
	 stored into the context."
	argsPointer := theFP + (self frameStackedReceiverOffsetNumArgs: tempIndex).
	1 to: tempIndex do:
		[:i|
		argsPointer := argsPointer - objectMemory wordSize.
		self assert: (objectMemory addressCouldBeOop: (stackPages longAt: argsPointer)).
		 objectMemory storePointer: ReceiverIndex + i
			ofObject: theContext
			withValue: (stackPages longAt: argsPointer)].
	"now update the non-argument stack contents."
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
CoInterpreter >> validInstructionPointer: instrPointer inMethod: aMethod framePointer: fp [
	<var: #instrPointer type: #usqInt>
	<var: #aMethod type: #usqInt>
	<var: #fp type: #'char *'>
	| theInstrPointer cogMethod |
	<var: #theInstrPointer type: #usqInt>
	<var: #cogMethod type: #'CogMethod *'>
	instrPointer = cogit ceCannotResumePC ifTrue:
		[^self isMachineCodeFrame: fp].
	instrPointer = cogit ceReturnToInterpreterPC
		ifTrue:
			[(self isMachineCodeFrame: fp) ifTrue:
				[^false].
			 theInstrPointer := self iframeSavedIP: fp]
		ifFalse:
			[ | header |
				theInstrPointer := instrPointer.
				header := self rawHeaderOf: aMethod.
				((self isCogMethodReference: header)
				   and: [theInstrPointer < objectMemory startOfMemory]) ifTrue:
				 	[cogMethod := self cCoerceSimple: header to: #'CogMethod *'.
				 	 ^theInstrPointer >= (header + (cogit sizeof: CogMethod))
				 	 and: [theInstrPointer < (header + cogMethod blockSize)]]].
	^super validInstructionPointer: theInstrPointer inMethod: aMethod framePointer: fp
]

{ #category : #'stack pages' }
CoInterpreter >> validStackPageBaseFrame: aPage [
	"Check that the base frame in the stack page has a valid sender and saved context."
	<var: #aPage type: #'StackPage *'>
	<inline: false>
	| savedThisContext senderContextOrNil |
	senderContextOrNil := stackPages longAt: aPage baseAddress.
	savedThisContext := stackPages longAt: aPage baseAddress - objectMemory wordSize.
	(self asserta: aPage baseFP + (self frameStackedReceiverOffset: aPage baseFP) + (2 * objectMemory wordSize) = aPage baseAddress) ifFalse:
		[^false].
	(self asserta: (objectMemory addressCouldBeObj: senderContextOrNil)) ifFalse:
		[^false].
	(self asserta: (objectMemory addressCouldBeObj: savedThisContext)) ifFalse:
		[^false].
	(self asserta: (senderContextOrNil = objectMemory nilObject or: [objectMemory isContext: senderContextOrNil])) ifFalse:
		[^false].
	(self asserta: (objectMemory isContext: savedThisContext)) ifFalse:
		[^false].
	(self asserta: (self frameCallerContext: aPage baseFP) = senderContextOrNil) ifFalse:
		[^false].
	(self asserta: (self frameContext: aPage baseFP) = savedThisContext) ifFalse:
		[^false].
	^true
]

{ #category : #'cog jit support' }
CoInterpreter >> varBaseAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: stackPointer) asUnsignedInteger - 16r40]
		inSmalltalk: [cogit fakeVarBaseAddress]
]

{ #category : #'frame access' }
CoInterpreter >> voidVMStateForSnapshotFlushingExternalPrimitivesIf: flushExtPrims [
	"Make sure that all VM state that affects the heap contents is voided so that the heap is
	 ready to be snapshotted.  If flushExtPrims is true, flush references to external
	 primitives in methods.  Answer the activeContext that should be stored in the snapshot."
	<inline: false>
	| activeContext |
	instructionPointer := 0. "in case of code compactions."
	activeContext := super voidVMStateForSnapshotFlushingExternalPrimitivesIf: flushExtPrims.
	cogit voidCogCompiledCode.
	^activeContext
]

{ #category : #'cog jit support' }
CoInterpreter >> warning: aString [
	<api: 'extern void warning(char *s)'>
	<doNotGenerate>
	self transcript cr; nextPutAll: aString; flush
]

{ #category : #'debug printing' }
CoInterpreter >> whereIs: anOop [
	<var: 'somewhere' type: #'char *'>
	(cogit whereIsMaybeCodeThing: anOop) ifNotNil: [:somewhere| ^somewhere].
	^super whereIs: anOop
]

{ #category : #'frame access' }
CoInterpreter >> widowOrForceToBytecodePC: ctxt [
	"Either widow the context or map its pc to a bytecode one.
	 Used to implement primitiveVoidVMStateForMethod."
	<inline: #never> "for debugging & saving space"
	(self isMarriedOrWidowedContext: ctxt)
		ifTrue:
			"Since any machine-code frame activations of the method have been divorced
			 there should only be interpreted activations of marriecd contexts."
			[(self isWidowedContext: ctxt) ifFalse:
				[self deny: (self isMachineCodeFrame: (self frameOfMarriedContext: ctxt))]]
		ifFalse:
			[self ensureContextHasBytecodePC: ctxt]
]
