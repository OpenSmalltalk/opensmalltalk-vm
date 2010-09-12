"
I am a variant of the StackInterpreter that can co-exist with the Cog JIT.  I interpret unjitted methods, either because they have been found for the first time or because they are judged to be too big to JIT.  See CogMethod class's comment for method interoperability.
"
Class {
	#name : #CoInterpreter,
	#superclass : #StackInterpreter,
	#instVars : [
		'cogit',
		'cogMethodZone',
		'inFullGC',
		'cogCodeSize',
		'desiredCogCodeSize',
		'heapBase',
		'linkSends',
		'lastCoggableInterpretedBlockMethod',
		'reenterInterpreter',
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
		'processHasThreadId',
		'flagInterpretedMethods',
		'maxLiteralCountForCompile'
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
		'CSThreadSchedulingLoop',
		'CSWait',
		'CSYield',
		'HasBeenReturnedFromMCPC',
		'PrimTraceLogSize',
		'TraceBlockActivation',
		'TraceBlockCreation',
		'TraceBufferSize',
		'TraceCodeCompaction',
		'TraceContextSwitch',
		'TraceFullGC',
		'TraceIncrementalGC',
		'TraceIsFromInterpreter',
		'TraceIsFromMachineCode',
		'TraceSources'
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
	^super ancilliaryClasses
		copyReplaceAll: { InterpreterStackPages }
		with: { CoInterpreterStackPages }
]

{ #category : #translation }
CoInterpreter class >> ancilliaryStructClasses [
	^{ CogSimpleStackPage.
		CogBlockMethod.
		CogMethod }
]

{ #category : #translation }
CoInterpreter class >> apiExportHeaderName [
	^'cointerp.h'
]

{ #category : #translation }
CoInterpreter class >> cogitClass [
	^SimpleStackBasedCogit
]

{ #category : #translation }
CoInterpreter class >> declareCVarsIn: aCCodeGenerator [
	"Override to avoid repeating StackInterpreter's declarations and add our own extensions"
	| threaded |
	threaded := aCCodeGenerator vmClass isThreadedVM.
	aCCodeGenerator
		addHeaderFile:'"sqCogStackAlignment.h"';
		addHeaderFile:'"cogmethod.h"';
		addHeaderFile: (threaded ifTrue: ['"cointerpmt.h"'] ifFalse: ['"cointerp.h"']);
		addHeaderFile:'"cogit.h"'.
	aCCodeGenerator
		var: #interpreterVersion
		declareC: 'const char *interpreterVersion = "Croquet Closure Cog ',
					(threaded ifTrue: ['MT '] ifFalse: ['']), 'VM [',
					(aCCodeGenerator shortMonticelloDescriptionForClass: self),']"'.
	aCCodeGenerator
		var: #heapBase
		declareC: 'static usqInt heapBase';
		var: #maxLiteralCountForCompile
		declareC: 'sqInt maxLiteralCountForCompile = MaxLiteralCountForCompile /* ', MaxLiteralCountForCompile printString, ' */'.
	aCCodeGenerator
		var: #reenterInterpreter
		type: 'jmp_buf'.
	aCCodeGenerator
		var: #statCodeCompactionUsecs
		type: #usqLong.
	aCCodeGenerator
		var: #primTraceLogIndex type: #'unsigned char';
		var: #primTraceLog declareC: 'sqInt primTraceLog[256]';
		var: #traceLog
		declareC: 'sqInt traceLog[TraceBufferSize /* ', (TraceBufferSize) printString, ' */]';
		var: #traceSources
		declareC: (String streamContents:
					[:s|
					s nextPutAll: 'static char *traceSources[] = {'; crtab: 2.
					TraceSources object
						do: [:string| s nextPut: $"; nextPutAll: string; nextPut: $"]
						separatedBy: [ s crtab: 2; nextPut: $,].
					s crtab; nextPut: $}; cr])
]

{ #category : #translation }
CoInterpreter class >> emitExportPragma [
	^false
]

{ #category : #translation }
CoInterpreter class >> exportAPISelectors [
	"Yes this is a mess.  When all exportAPI methods are marked with the <api> pragma
	 this can go away."
	^((self withAllSuperclasses copyUpThrough: thisContext methodClass theNonMetaClass),
		self ancilliaryClasses
			inject: ObjectMemory exportAPISelectors,
				   NewObjectMemory exportAPISelectors,
				   StackInterpreter exportAPISelectors
			into: [:set :class| set addAll: (self exportAPISelectorsFor: class); yourself])
	 	addAll: #(	argumentCountOfMethodHeader:
					canContextSwitchIfActivating:
					classFieldOffset
					classHeader:
					compactClassFieldLSB
					compactClassFieldWidth
					compactClassIndexOf:
					fetchByte:ofObject:
					functionPointerFor:inClass:
					isNonIntegerObject:
					lastPointerOf:
					literal:ofMethod:
					objectAfter: 
					popStack
					primitiveClosureValueNoContextSwitch
					specialSelector:
					stackTop
					tempCountOf:
					tempCountOfMethodHeader:);
		yourself
]

{ #category : #translation }
CoInterpreter class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #initialization }
CoInterpreter class >> initializeContextIndices [
	super initializeContextIndices.

	HasBeenReturnedFromMCPC := self basicNew integerObjectOf: -1
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
			context (uninitialized?)
			frame flags (interpreter only)
			saved method ip (uninitialized?; interpreter only)
			receiver
			first temp
			...
	sp->	Nth temp

	In an interpreter frame
		frame flags holds
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

	"For debugging nil out values that differ in the StackInterpreter."
	FrameSlots := nil.
	IFrameSlots := fxCallerSavedIP - fxIFReceiver + 1.
	MFrameSlots := fxCallerSavedIP - fxMFReceiver + 1.

	FoxCallerSavedIP := fxCallerSavedIP * BytesPerWord.
	"In Cog a base frame's caller context is stored on the first word of the stack page."
	FoxCallerContext := nil.
	FoxSavedFP := fxSavedFP * BytesPerWord.
	FoxMethod := fxMethod * BytesPerWord.
	FoxThisContext := fxThisContext * BytesPerWord.
	FoxFrameFlags := nil.
	FoxIFrameFlags := fxIFrameFlags * BytesPerWord.
	FoxIFSavedIP := fxIFSavedIP * BytesPerWord.
	FoxReceiver := #undeclared asSymbol.
	FoxIFReceiver := fxIFReceiver * BytesPerWord.
	FoxMFReceiver := fxMFReceiver * BytesPerWord.

	"N.B.  There is room for one more flag given the current 8 byte alignment of methods (which
	 is at least needed to distinguish the checked and uncecked entry points by their alignment."
	MFMethodFlagHasContextFlag := 1.
	MFMethodFlagIsBlockFlag := 2.
	MFMethodFlagsMask := MFMethodFlagHasContextFlag + MFMethodFlagIsBlockFlag.
	MFMethodMask := (MFMethodFlagsMask + 1) negated
]

{ #category : #initialization }
CoInterpreter class >> initializeMiscConstants [

	super initializeMiscConstants.

	MaxNumArgs := 15.
	PrimCallNeedsNewMethod := 1.
	PrimCallNeedsPrimitiveFunction := 2.
	PrimCallMayCallBack := 4.
	PrimCallCollectsProfileSamples := 8.

	PrimTraceLogSize := 256. "Room for 256 selectors.  Must be 256 because we use a byte to hold the index"
	TraceBufferSize := 256 * 3. "Room for 256 events"
	TraceContextSwitch := ObjectMemory basicNew integerObjectOf: 1.
	TraceBlockActivation := ObjectMemory basicNew integerObjectOf: 2.
	TraceBlockCreation := ObjectMemory basicNew integerObjectOf: 3.
	TraceIncrementalGC := ObjectMemory basicNew integerObjectOf: 4.
	TraceFullGC := ObjectMemory basicNew integerObjectOf: 5.
	TraceCodeCompaction := ObjectMemory basicNew integerObjectOf: 6.

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

	TraceSources := CArrayAccessor on: #('?' 'm' 'i' 'callbackEnter' 'callbackLeave' 'enterCritical' 'exitCritical' 'resume' 'signal'  'suspend' 'wait' 'yield' 'eventcheck' 'threadsched' 'ownVM')
]

{ #category : #initialization }
CoInterpreter class >> initializePrimitiveTable [
	super initializePrimitiveTable.
	self assert: (PrimitiveTable at: 253 + 1) = #primitiveFail.
	PrimitiveTable at: 253 + 1 put: #primitiveCollectCogCodeConstituents
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

{ #category : #translation }
CoInterpreter class >> isNonArgumentImplicitReceiverVariableName: aString [
	^#('self' 'stackPages' 'cogit' 'coInterpreter' 'cogMethodZone') includes: aString
]

{ #category : #testing }
CoInterpreter class >> isThreadedVM [
	^false
]

{ #category : #translation }
CoInterpreter class >> isTypePointerToStruct: type [ "<String>"
	^type notNil
	  and: [(type includes: $*)
	  and: [(type beginsWith: 'CogMethod')
			or: [(super isTypePointerToStruct: type)
			or: [Cogit isTypePointerToStruct: type]]]]
]

{ #category : #translation }
CoInterpreter class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^(super mustBeGlobal: var)
	   or: [ #('desiredCogCodeSize' 'heapBase' 'maxLiteralCountForCompile') includes: var]
]

{ #category : #translation }
CoInterpreter class >> needsCogit [
	^true
]

{ #category : #translation }
CoInterpreter class >> preGenerationHook: aCCodeGenerator [
	"Override to undo the hiding of primitiveClosureValueNoContextSwitch"
	super preGenerationHook: aCCodeGenerator.
	(aCCodeGenerator methodNamed: #primitiveClosureValueNoContextSwitch) static: false
]

{ #category : #translation }
CoInterpreter class >> preambleCCode [
	^super 	preambleCCode,
'
/*
 * Define sigsetjmp and siglongjmp to be the most minimal setjmp/longjmp available on the platform.
 */
#if WIN32
# define sigsetjmp(jb,ssmf) setjmp(jb)
# define siglongjmp(jb,v) longjmp(jb,v)
#else
# define sigsetjmp(jb,ssmf) _setjmp(jb)
# define siglongjmp(jb,v) _longjmp(jb,v)
#endif
'
]

{ #category : #translation }
CoInterpreter class >> prepareToBeAddedToCodeGenerator: aCodeGen [
	"Override to avoid repeating StackInterpreter's preparations
	 and to delete StackInterpreter methods we override."
	#(	startOfMemory growObjectMemory: clearLeakMapAndMapAccessibleObjects
		lastPointerOf:recordWeakRoot: lastPointerOf: lastPointerWhileForwarding:) do:
			[:sel| aCodeGen removeMethodForSelector: sel].
	thisContext methodClass theNonMetaClass selectors do:
		[:sel|
		 (StackInterpreter includesSelector: sel) ifTrue:
			[aCodeGen removeMethodForSelector: sel]].
	"It is either this or scan cmacro methods for selectors."
	aCodeGen retainMethods: #(enterSmalltalkExecutiveImplementation)
]

{ #category : #translation }
CoInterpreter class >> shouldGenerateTypedefFor: aStructClass [
	"Hack to work-around mutliple definitions.  Sometimes a type has been defined in an include."
	^({ CogStackPage. CogBlockMethod. CogMethod } includes: aStructClass) not
]

{ #category : #translation }
CoInterpreter class >> sourceFileName [
	"Answer the filename for the core interpreter"

	^'cointerp.c'
]

{ #category : #translation }
CoInterpreter class >> specialValueForConstant: constantName [
	^constantName = 'DoAssertionChecks' ifTrue: ['(!PRODUCTION)']
]

{ #category : #translation }
CoInterpreter class >> writeVMHeaderTo: aStream bytesPerWord: bytesPerWord [
	aStream
		nextPutAll: '#define COGVM 1'; cr;
		nextPutAll: '#if !defined(COGMTVM)'; cr;
		nextPutAll: '#	define COGMTVM '; nextPut: (self isThreadedVM ifTrue: [$1] ifFalse: [$0]); cr;
		nextPutAll: '#endif'; cr.
	super writeVMHeaderTo: aStream bytesPerWord: bytesPerWord
]

{ #category : #trampolines }
CoInterpreter >> activateInterpreterMethodFromMachineCode [
	"Execute an interpreted method from machine code.  We assume (require) that newMethod
	 messageSelector, primitiveFunctionPointer and argumentCount have been set in the caller.
	 Once evaluated either continue in the interpreter via a jongjmp or in machine code via an
	 enilopmart (a form of longjmp - a stinking rose by any other name)."
	<inline: false>
	cogit assertCStackWellAligned.
	self assert: (self validInstructionPointer: self stackTop inFrame: framePointer).
	instructionPointer := self popStack.
	primitiveFunctionPointer ~= 0
		ifTrue:
			[self assert: (self primitiveIndexOf: newMethod) ~= 0.
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
			[self assert: ((self primitiveIndexOf: newMethod) = 0
						or: [(self functionPointerFor: (self primitiveIndexOf: newMethod) inClass: nilObj) = 0])].
	"if not primitive, or primitive failed, activate the method and reenter the interpreter"
	self activateNewMethod.
	self siglong: reenterInterpreter jmp: 1.
	"NOTREACHED"
	^nil
]

{ #category : #'control primitives' }
CoInterpreter >> activateNewClosureMethod: blockClosure numArgs: numArgs mayContextSwitch: mayContextSwitch [
	"Similar to activateNewMethod but for Closure and newMethod.
	 Override to handle the various interpreter/machine code transitions
	 and to create an appropriate frame layout."
	| numCopied outerContext theMethod methodHeader inInterpreter closureIP switched |
	<inline: true>
	outerContext := self fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	self assert: outerContext ~= blockClosure.
	numCopied := self copiedValueCountOfClosure: blockClosure.
	theMethod := self fetchPointer: MethodIndex ofObject: outerContext.
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
			[theMethod = lastCoggableInterpretedBlockMethod
				ifTrue:
					[theMethod ~= lastUncoggableInterpretedBlockMethod ifTrue:
						[cogit cog: theMethod selector: nilObj.
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
	(inInterpreter := instructionPointer >= self startOfMemory) ifFalse:
		[instructionPointer = cogit ceReturnToInterpreterPC ifTrue:
			[instructionPointer := self iframeSavedIP: framePointer]].
	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: theMethod.
	self push: nilObj. "FxThisContext field"
	self push: (self encodeFrameFieldHasContext: false isBlock: true numArgs: numArgs).
	self push: 0. "FoxIFSavedIP"
	self push: (self fetchPointer: ReceiverIndex ofObject: outerContext).

	"Copy the copied values..."
	0 to: numCopied - 1 do:
		[:i|
		self push: (self
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
	instructionPointer := theMethod + closureIP + BaseHeaderSize - 2.
	self setMethod: theMethod.

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)"
	switched := false.
	stackPointer < stackLimit ifTrue:
		[switched := self handleStackOverflowOrEventAllowContextSwitch: mayContextSwitch].
	self returnToExecutive: inInterpreter postContextSwitch: switched
]

{ #category : #'message sending' }
CoInterpreter >> activateNewMethod [
	| methodHeader numArgs numTemps rcvr errorCode inInterpreter switched |

	methodHeader := self headerOf: newMethod.
	numTemps := self temporaryCountOfMethodHeader: methodHeader.
	numArgs := self argumentCountOfMethodHeader: methodHeader.

	rcvr := self stackValue: numArgs. "could new rcvr be set at point of send?"

	"Because this is an uncogged method we need to continue via the interpreter.
	 We could have been reached either from the interpreter, in which case we
	 should simply return, or from a machine code frame or from a compiled
	 primitive.  In these latter two cases we must longjmp back to the interpreter.
	 The instructionPointer tells us which path we took.
	 If the sender was an interpreter frame but called through a (failing) primitive
	 then make sure we restore the saved instruction pointer and avoid pushing
	 ceReturnToInterpreterPC which is only valid between an interpreter caller
	 frame and a machine code callee frame."
	(inInterpreter := instructionPointer >= self startOfMemory) ifFalse:
		[instructionPointer = cogit ceReturnToInterpreterPC ifTrue:
			[instructionPointer := self iframeSavedIP: framePointer]].
	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: newMethod.
	self setMethod: newMethod.
	self push: nilObj. "FxThisContext field"
	self push: (self encodeFrameFieldHasContext: false isBlock: false numArgs: numArgs).
	self push: 0. "FoxIFSavedIP"
	self push: rcvr.

	"clear remaining temps to nil"
	numArgs+1 to: numTemps do:
		[:i | self push: nilObj].

	instructionPointer := (self initialPCForHeader: methodHeader method: newMethod) - 1.

	"Pass primitive error code to last temp if method receives it (indicated
	 by an initial long store temp bytecode).  Protect against obsolete values
	 in primFailCode by checking that newMethod actually has a primitive?"
	primFailCode ~= 0 ifTrue:
		[((self methodHeaderHasPrimitive: methodHeader)
		   and: [(self byteAtPointer: instructionPointer + 1) = 129 "long store temp"]) ifTrue:
			[errorCode := self getErrorObjectFromPrimFailCode.
			 self stackTopPut: errorCode "nil if primFailCode == 1, or primFailCode"].
		primFailCode := 0].

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)."
	switched := true.
	stackPointer < stackLimit ifTrue:
		[switched := self handleStackOverflowOrEventAllowContextSwitch:
							(self canContextSwitchIfActivating: methodHeader)].
	self returnToExecutive: inInterpreter postContextSwitch: switched
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
		ifFalse: [cogit cogHomeMethod: aCogMethod]
]

{ #category : #'debug support' }
CoInterpreter >> assertCStackCorrectlyAligned [
	<inline: true>
	cogit assertCStackWellAligned
]

{ #category : #'debug support' }
CoInterpreter >> assertValidExecutionPointe: lip r: lifp s: lisp imbar: inInterpreter [
	<var: #lip type: #usqInt>
	<var: #lifp type: #'char *'>
	<var: #lisp type: #'char *'>
	| methodField cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	self assert: stackPage = (stackPages stackPageFor: lifp).
	self assert: stackPage = stackPages mostRecentlyUsedPage.
	self deferStackLimitSmashAround: #assertValidStackLimits asSymbol.
	self assert: lifp < stackPage baseAddress.
	self assert: lisp < lifp.
	self assert: lifp > lisp.
	self assert: lisp >= (stackPage realStackLimit - self stackLimitOffset).
	self assert:  (lifp - lisp) < LargeContextSize.
	methodField := self frameMethodField: lifp.
	inInterpreter
		ifTrue:
			[self assert: (self isMachineCodeFrame: lifp) not.
			 self assert: method = methodField.
			 ((self asserta: methodField asUnsignedInteger > self startOfMemory)
			   and: [self asserta: methodField asUnsignedInteger < freeStart]) ifTrue:
				[lip ~= cogit ceReturnToInterpreterPC ifTrue:
					[self assert: (lip >= (methodField + (self lastPointerOf: methodField) + BytesPerWord - 1)
								  and: [lip < (methodField + (self byteLengthOf: methodField) + BaseHeaderSize)])]].
			 self assert: ((self iframeIsBlockActivation: lifp)
					or: [(self pushedReceiverOrClosureOfFrame: lifp) = (self iframeReceiver: lifp)])]
		ifFalse:
			[self assert: (self isMachineCodeFrame: lifp).
			 ((self asserta: methodField asUnsignedInteger >= cogit minCogMethodAddress)
			  and: [self asserta: methodField asUnsignedInteger < cogit maxCogMethodAddress]) ifTrue:
				[cogMethod := self mframeHomeMethod: lifp.
				 self assert: (lip > (methodField + ((self mframeIsBlockActivation: lifp)
													ifTrue: [self sizeof: CogBlockMethod]
													ifFalse: [self sizeof: CogMethod]))
						and: [lip < (methodField + cogMethod blockSize)])].
			 self assert: ((self mframeIsBlockActivation: lifp)
					or: [(self pushedReceiverOrClosureOfFrame: lifp) = (self mframeReceiver: lifp)])].
	(self isBaseFrame: lifp) ifTrue:
		[self assert: (self frameHasContext: lifp).
		 self assert: (self frameContext: lifp) = (stackPages longAt: stackPage baseAddress - BytesPerWord)]
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
	homeMethod := cogit cogHomeMethod: cogMethod.
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

{ #category : #'return bytecodes' }
CoInterpreter >> baseFrameReturn [
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
	retToContext := self isContext: contextToReturnTo.
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
					 newPage := self newStackPage.
					 self assert: newPage = stackPage.
					 self moveFramesIn: thePage through: frameAbove toPage: newPage.
					 stackPages markStackPageMostRecentlyUsed: newPage.
					 theFP := thePage headFP.
					 theSP := thePage headSP]]
		ifFalse:
			[(retToContext
			  and: [self isIntegerObject: (self fetchPointer: InstructionPointerIndex ofObject: contextToReturnTo)]) ifFalse:
				[| contextToReturnFrom |
				 contextToReturnFrom := stackPages longAt: stackPage baseAddress - BytesPerWord.
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
	localIP asUnsignedInteger < self startOfMemory ifTrue:
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
			[cogMethodForIP := self cCoerceSimple: cogMethod asInteger - ((theIP signedBitShift: -16) * (cogit sizeof: CogBlockMethod))
									to: #'CogBlockMethod *'.
			 self assert: cogMethodForIP cmType = CMBlock.
			 self assert: cogMethodForIP objectHeader = cogMethod asUnsignedInteger.
			 mcpc := cogMethodForIP asInteger - theIP signedIntFromShort]
		ifFalse:
			[cogMethodForIP := self cCoerceSimple: cogMethod to: #'CogBlockMethod *'.
			 self assert: cogMethodForIP cmType = CMMethod.
			 mcpc := cogMethod asInteger - theIP].
	self assert: (mcpc between: cogMethod asInteger and: cogMethod asInteger + cogMethod blockSize).
	^cogit bytecodePCFor: mcpc startBcpc: startBcpc in: cogMethodForIP
]

{ #category : #'common selector sends' }
CoInterpreter >> bytecodePrimAt [
	"BytecodePrimAt will only succeed if the receiver is in the atCache.
	 Otherwise it will fail so that the more general primitiveAt will put it in the
	 cache after validating that message lookup results in a primitive response.
	 Override to insert in the at: cache here.  This is necessary since once there
	 is a compiled at: primitive method (which doesn't use the at: cache) the only
	 way something can get installed in the atCache is here."
	| index rcvr result atIx |
	index := self internalStackTop.
	rcvr := self internalStackValue: 1.
	((self isIntegerObject: rcvr) not
	 and: [self isIntegerObject: index]) ifTrue:
		[atIx := rcvr bitAnd: AtCacheMask.  "Index into atCache = 4N, for N = 0 ... 7"
		(atCache at: atIx+AtCacheOop) ~= rcvr ifTrue:
			[lkupClass := self fetchClassOfNonInt: rcvr.
			 messageSelector := self specialSelector: 16.
			 (self lookupInMethodCacheSel: messageSelector class: lkupClass) ifFalse:
				[argumentCount := 1.
				 ^self commonSend].
			 primitiveFunctionPointer == #primitiveAt asSymbol
				ifTrue: [self install: rcvr inAtCache: atCache at: atIx string: false]
				ifFalse:
					[primitiveFunctionPointer == #primitiveStringAt asSymbol
						ifTrue: [self install: rcvr inAtCache: atCache at: atIx string: true]
						ifFalse:
							[argumentCount := 1.
							 ^self commonSend]]].
		 result := self commonVariable: rcvr at: (self integerValueOf: index) cacheIndex: atIx.
		 self successful ifTrue:
			[self fetchNextBytecode.
			 ^self internalPop: 2 thenPush: result]].

	messageSelector := self specialSelector: 16.
	argumentCount := 1.
	self normalSend
]

{ #category : #'common selector sends' }
CoInterpreter >> bytecodePrimAtPut [
	"BytecodePrimAtPut will only succeed if the receiver is in the atCache.
	Otherwise it will fail so that the more general primitiveAtPut will put it in the
	cache after validating that message lookup results in a primitive response.
	 Override to insert in the atCache here.  This is necessary since once there
	 is a compiled at:[put:] primitive method (which doesn't use the at: cache) the
	 only way something can get installed in the atCache is here."
	| index rcvr atIx value |
	value := self internalStackTop.
	index := self internalStackValue: 1.
	rcvr := self internalStackValue: 2.
	((self isIntegerObject: rcvr) not
	 and: [self isIntegerObject: index]) ifTrue:
		[atIx := (rcvr bitAnd: AtCacheMask) + AtPutBase.  "Index into atPutCache"
		 (atCache at: atIx+AtCacheOop) ~= rcvr ifTrue:
			[lkupClass := self fetchClassOfNonInt: rcvr.
			 messageSelector := self specialSelector: 17.
			 (self lookupInMethodCacheSel: messageSelector class: lkupClass) ifFalse:
				[argumentCount := 2.
				 ^self commonSend].
			 primitiveFunctionPointer == #primitiveAtPut asSymbol
				ifTrue: [self install: rcvr inAtCache: atCache at: atIx string: false]
				ifFalse:
					[primitiveFunctionPointer == #primitiveStringAtPut asSymbol
						ifTrue: [self install: rcvr inAtCache: atCache at: atIx string: true]
						ifFalse:
							[argumentCount := 2.
							 ^self commonSend]]].
		 self commonVariable: rcvr at: (self integerValueOf: index) put: value cacheIndex: atIx.
		 self successful ifTrue:
			[self fetchNextBytecode.
			 ^self internalPop: 3 thenPush: value]].

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
	(self asserta: jmpDepth < jmpMax) ifFalse:
		[^false].
	jmpDepth := jmpDepth + 1.

	wasInMachineCode := self isMachineCodeFrame: framePointer.
	calledFromMachineCode := instructionPointer <= self startOfMemory.

	"Suspend the currently active process"
	suspendedCallbacks at: jmpDepth put: self activeProcess.
	"We need to preserve newMethod explicitly since it is not activated yet
	and therefore no context has been created for it. If the caller primitive
	for any reason decides to fail we need to make sure we execute the correct
	method and not the one 'last used' in the call back"
	suspendedMethods at: jmpDepth put: newMethod.
	self transferTo: self wakeHighestPriority from: CSCallbackEnter.

	"Typically, invoking the callback means that some semaphore has been 
	signaled to indicate the callback. Force an interrupt check as soon as possible."
	self forceInterruptCheck.

	"Save the previous CStackPointers and interpreter entry jmp_buf."
	currentCStackPointer := cogit getCStackPointer.
	currentCFramePointer := cogit getCFramePointer.
	self mem: (self cCoerceSimple: savedReenterInterpreter to: #'void *')
		cp: reenterInterpreter
		y: (self sizeof: #'jmp_buf' asSymbol).
	cogit assertCStackWellAligned.
	(self setjmp: (jmpBuf at: jmpDepth)) == 0 ifTrue: "Fill in callbackID"
		[callbackID at: 0 put: jmpDepth.
		 self enterSmalltalkExecutive.
		 self assert: false "NOTREACHED"].

	"Restore the previous CStackPointers and interpreter entry jmp_buf."
	cogit setCStackPointer: currentCStackPointer.
	cogit setCFramePointer: currentCFramePointer.
	self mem: reenterInterpreter
		cp: (self cCoerceSimple: savedReenterInterpreter to: #'void *')
		y: (self sizeof: #'jmp_buf' asSymbol).

	"Transfer back to the previous process so that caller can push result"
	self putToSleep: self activeProcess yieldingIf: preemptionYields.
	newMethod := suspendedMethods at: jmpDepth.	"see comment above"
	argumentCount := self argumentCountOf: newMethod.
	self transferTo: (suspendedCallbacks at: jmpDepth) from: CSCallbackLeave.
	self assert: wasInMachineCode = (self isMachineCodeFrame: framePointer).
	calledFromMachineCode
		ifTrue:
			[instructionPointer >= self startOfMemory ifTrue:
				[self assert: (self isMachineCodeFrame: framePointer) not.
				 self iframeSavedIP: framePointer put: instructionPointer.
				 instructionPointer := cogit ceReturnToInterpreterPC]]
		ifFalse:
			["Even if the context was flushed to the heap and rebuilt in transferTo:from:
			  above it will remain an interpreted frame because the context's pc would
			  remain a bytecode pc.  So the instructionPointer must also be a bytecode pc."
			 self assert: (self isMachineCodeFrame: framePointer) not.
			 self assert: calledFromMachineCode = (instructionPointer <= self startOfMemory)].
	self assert: primFailCode = 0.
	jmpDepth := jmpDepth-1.
	^true
]

{ #category : #enilopmarts }
CoInterpreter >> ceActivateFailingPrimitiveMethod: aPrimitiveMethod [
	"An external call or FFI primitive has failed.  Build the frame and
	 activate as appropriate.  Enter either the interpreter or machine
	 code depending on whether aPrimitiveMethod has been cogged.
	 Note that we could always interpret but want the efficiency of
	 executing machine code if it is available."
	<api>
	| methodHeader cogMethod rcvr numTemps errorCode switched |
	<var: #cogMethod type: #'CogMethod *'>

	self assert: newMethod = aPrimitiveMethod.
	methodHeader := self rawHeaderOf: aPrimitiveMethod.
	(self isCogMethodReference: methodHeader) ifFalse:
		[^self activateNewMethod].

	cogMethod := self cCoerceSimple: methodHeader to: #'CogMethod *'.
	methodHeader := cogMethod methodHeader.
	self assert: (self methodHeaderHasPrimitive: methodHeader).
	rcvr := self stackValue: cogMethod cmNumArgs. "could new rcvr be set at point of send?"
	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: cogMethod asInteger.
	self push: nilObj. "FxThisContext field"
	self push: rcvr.

	"clear remaining temps to nil"
	numTemps := self temporaryCountOfMethodHeader: methodHeader.
	cogMethod cmNumArgs + 1 to: numTemps do:
		[:i | self push: nilObj].

	"Pass primitive error code to last temp if method receives it (indicated
	 by an initial long store temp bytecode).  Protect against obsolete values
	 in primFailCode by checking that newMethod actually has a primitive?"
	primFailCode ~= 0 ifTrue:
		[(self byteAtPointer: (self initialPCForHeader: methodHeader method: newMethod)) = 129 "long store temp" ifTrue:
			[errorCode := self getErrorObjectFromPrimFailCode.
			 self pop: 1 thenPush: errorCode "nil if primFailCode == 1, or primFailCode"].
		primFailCode := 0].

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)."
	stackPointer >= stackLimit ifTrue:
		[self assert: cogMethod stackCheckOffset > cogit noCheckEntryOffset.
		 self push: cogMethod asInteger + cogMethod stackCheckOffset.
		 self push: rcvr.
		 cogit ceEnterCogCodePopReceiverReg.
		 self error: 'should not be reached'].
	instructionPointer := cogMethod asInteger + cogMethod stackCheckOffset.
	switched := self handleStackOverflowOrEventAllowContextSwitch: (self canContextSwitchIfActivating: methodHeader).
	self returnToExecutive: false postContextSwitch: switched
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
	self assert: stackPointer <= (stackPage baseAddress - BytesPerWord).
	self assert: stackPage baseFP + (2 * BytesPerWord) < stackPage baseAddress.
	"We would like to use the following assert but we can't since the stack pointer will be above the
	 base frame pointer in the base frame return and hence the 0 a base frame pointer points at could
	 be overwritten which will cause the isBaseFrame assert in frameCallerContext: to fail."
	"self assert: (self frameCallerContext: stackPage baseFP) = (stackPages longAt: stackPage baseAddress)."
	self assert: ((self addressCouldBeObj: (stackPages longAt: stackPage baseAddress - BytesPerWord))
				and: [self isContext: (stackPages longAt: stackPage baseAddress - BytesPerWord)]).
	self assert: ((self addressCouldBeObj: (stackPages longAt: stackPage baseAddress))
				and: [self isContext: (stackPages longAt: stackPage baseAddress)]).
	contextToReturnTo := stackPages longAt: stackPage baseAddress.

	"The stack page is effectively free now, so free it.  We must free it to be
	 correct in determining if contextToReturnTo is still married, and in case
	 makeBaseFrameFor: cogs a method, which may cause a code compaction,
	 in which case the frame must be free to avoid the relocation machinery
	 tracing the dead frame.  Since freeing now temporarily violates the page-list
	 ordering invariant, use the assert-free version."
	stackPages freeStackPageNoAssert: stackPage.
	isAContext := self isContext: contextToReturnTo.
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
					 newPage := self newStackPage.
					 self assert: newPage = stackPage.
					 self moveFramesIn: thePage through: frameAbove toPage: newPage.
					 stackPages markStackPageMostRecentlyUsed: newPage.
					 framePointer := thePage headFP.
					 stackPointer := thePage headSP]]
		ifFalse:
			[(isAContext
			  and: [self isIntegerObject: (self fetchPointer: InstructionPointerIndex ofObject: contextToReturnTo)]) ifFalse:
				[contextToReturnFrom := stackPages longAt: stackPage baseAddress - BytesPerWord.
				 self tearDownAndRebuildFrameForCannotReturnBaseFrameReturnFrom: contextToReturnFrom
					to: contextToReturnTo
					returnValue: returnValue.
				^self externalCannotReturn: returnValue from: contextToReturnFrom].
			 "void the instructionPointer to stop it being incorrectly updated in a code
			 compaction in makeBaseFrameFor:."
			 instructionPointer := 0.
			 thePage := self makeBaseFrameFor: contextToReturnTo.
			 framePointer := thePage headFP.
			 stackPointer := thePage headSP].
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
	self siglong: reenterInterpreter jmp: 1.
	"NOTREACHED"
	^nil
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
		ceSend: (self splObj: SelectorCannotReturn)
		super: 0
		to: (self frameContext: framePointer)
		numArgs: -1 - 1 "i.e. 1 arg & don't link"
]

{ #category : #trampolines }
CoInterpreter >> ceCheckForInterrupts [
	<api>
	| switched |
	switched := self checkForEventsMayContextSwitch: true.
	self returnToExecutive: false postContextSwitch: switched
]

{ #category : #'cog jit support' }
CoInterpreter >> ceCheckProfileTick [
	"Check if the profile timer has expired and if so take a sample.
	 If the primitive has failed sample the profileMethod as nil.
	 As a courtesy to compileInterpreterPrimitive: map NULL to nilObj."
	<api>
	newMethod isNil ifTrue: [newMethod := nilObj].
	self checkProfileTick: newMethod
]

{ #category : #trampolines }
CoInterpreter >> ceContext: maybeContext instVar: slotIndex [
	<api>
	| result |
	(self isContextNonInt: maybeContext)
		ifTrue:
			[instructionPointer := self popStack.
			 result := self externalInstVar: slotIndex ofContext: maybeContext.
			 self push: instructionPointer]
		ifFalse: [result := self fetchPointer: slotIndex ofObject: maybeContext].
	^result
]

{ #category : #trampolines }
CoInterpreter >> ceContext: maybeMarriedContext instVar: slotIndex value: anOop [
	<api>
	"genStorePop:MaybeContextReceiverVariable: filters out unmarried contexts
	 but not arbitrary objects in subclasses."
	(self isContextNonInt: maybeMarriedContext)
		ifTrue:
			[self assert: (self isMarriedOrWidowedContext: maybeMarriedContext).
			 instructionPointer := self popStack.
			 self externalInstVar: slotIndex ofContext: maybeMarriedContext put: anOop.
			 self push: instructionPointer]
		ifFalse:
			[self storePointer: slotIndex ofObject: maybeMarriedContext withValue: anOop]
]

{ #category : #trampolines }
CoInterpreter >> ceInterpretMethodFromPIC: aMethodObj receiver: rcvr [
	<api>
	| pic primitiveIndex |
	<var: #pic type: #'CogMethod *'>
	self assert: (self methodHasCogMethod: aMethodObj) not.
	"pop off inner return and locate open PIC"
	pic := self cCoerceSimple: self popStack - cogit interpretOffset to: #'CogMethod *'.
	self assert: (pic cmType = CMOpenPIC or: [pic cmType = CMClosedPIC]).
	pic cmType = CMOpenPIC
		ifTrue:
			[(self methodShouldBeCogged: aMethodObj) ifTrue:
				[cogit cog: aMethodObj selector: pic selector.
				 (self methodHasCogMethod: aMethodObj) ifTrue:
					[self executeCogMethodFromUnlinkedSend: (self cogMethodOf: aMethodObj)
						withReceiver: rcvr]]]
		ifFalse:
			[self assert: (cogCompiledCodeCompactionCalledFor
						or: [(cogit methodShouldBeCogged: aMethodObj) not])].
	messageSelector := pic selector.
	newMethod := aMethodObj.
	primitiveIndex := self primitiveIndexOf: aMethodObj.
	primitiveFunctionPointer := self functionPointerFor: primitiveIndex inClass: nilObj.
	argumentCount := pic cmNumArgs.
	^self activateInterpreterMethodFromMachineCode
	"NOTREACHED"
]

{ #category : #trampolines }
CoInterpreter >> ceMNUFromPICMNUMethod: aMethodObj receiver: rcvr [
	<api>
	| cPIC class |
	<var: #cPIC type: #'CogMethod *'>
	self assert: ((self isIntegerObject: rcvr) or: [self addressCouldBeObj: rcvr]).
	cPIC := self cCoerceSimple: self popStack - cogit mnuOffset to: #'CogMethod *'.
	self assert: cPIC cmType = CMClosedPIC.
	argumentCount := cPIC cmNumArgs.
	messageSelector := cPIC selector.
	class := self fetchClassOf: rcvr.
	self handleMNUInMachineCodeTo: rcvr lookupClass: class mayLink: false
]

{ #category : #trampolines }
CoInterpreter >> ceNewArraySlotSize: slotSize [
	<api>
	^self eeInstantiateAndInitializeClass: (self splObj: ClassArray) indexableSize: slotSize
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

	"Since this is a block activation the closure is on the stack above any args and the frame."
	closure := self pushedReceiverOrClosureOfFrame: framePointer.

	home := nil.
	"Walk the closure's lexical chain to find the context or frame to return from (home)."
	[closure ~~ nilObj] whileTrue:
		[home := self fetchPointer: ClosureOuterContextIndex ofObject: closure.
		 closure := self fetchPointer: ClosureIndex ofObject: home].
	"home is to be returned from provided there is no unwind-protect activation between
	 this frame and home's sender.  Search for an unwind.  findUnwindThroughContext:
	 will answer either the context for an unwind-protect activation or nilObj if the sender
	 cannot be found or 0 if no unwind is found but the sender is.  We must update the
	 current page's headFrame pointers to enable the search to identify widowed contexts
	 correctly."
	self externalWriteBackHeadFramePointers.
	unwindContextOrNilOrZero := self findUnwindThroughContext: home.
	unwindContextOrNilOrZero = nilObj ifTrue:
		["error: can't find home on chain; cannot return"
		 ourContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
		 ^self externalCannotReturn: returnValue from: ourContext].
	unwindContextOrNilOrZero ~~ 0 ifTrue:
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
			[contextToReturnTo := self fetchPointer: SenderIndex ofObject: home.
			 ((self isContext: contextToReturnTo)
			  and: [self isMarriedOrWidowedContext: contextToReturnTo]) ifTrue:
				[self assert: (self checkIsStillMarriedContext: contextToReturnTo currentFP: framePointer).
			 	 frameToReturnTo := self frameOfMarriedContext: contextToReturnTo.
				 contextToReturnTo := nil]].

	"If returning to a context we must make a frame for it unless it is dead."
	contextToReturnTo ~= nil ifTrue:
		[frameToReturnTo := self establishFrameForContextToReturnTo: contextToReturnTo.
		 frameToReturnTo == 0 ifTrue:
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
		 self assert: (self isContext: currentCtx).
		 stackPages freeStackPage: stackPage.
		 [(self isMarriedOrWidowedContext: currentCtx)
		   and: [(stackPages stackPageFor: (theFP := self frameOfMarriedContext: currentCtx)) = newPage]] whileFalse:
			[(self isMarriedOrWidowedContext: currentCtx)
				ifTrue:
					[thePage := stackPages stackPageFor: theFP.
					 currentCtx := self frameCallerContext: thePage baseFP.
					 self freeStackPage: thePage]
				ifFalse:
					[self assert: (self isContext: currentCtx).
					 nextCntx := self fetchPointer: SenderIndex ofObject: currentCtx.
					 self storePointerUnchecked: SenderIndex ofObject: currentCtx withValue: nilObj.
					 self storePointerUnchecked: InstructionPointerIndex ofObject: currentCtx withValue: nilObj.
					 currentCtx := nextCntx]].
		 self setStackPageAndLimit: newPage.
		 stackPointer := stackPage headSP.
		 framePointer := stackPage headFP].

	"Two cases.  Returning to the top frame or an interior frame.  The
	 top frame has its instruction pointer on top of stack.  An interior
	 frame has its instruction pointer in the caller frame. We need to
	 peel back any frames on the page until we get to the correct frame."
	self flag: 'currently caller pushes result'. "(in machine code)"
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
CoInterpreter >> cePositive32BitIntegerFor: anInteger [
	<api>
	<var: #anInteger type: #usqInt>
	^self positive32BitIntegerFor: anInteger
]

{ #category : #trampolines }
CoInterpreter >> cePushActiveContext [
	<api>
	"Since the trampoline checks for marriage we should only be here for a single frame."
	self assert: (self isMachineCodeFrame: framePointer).
	self assert: (self frameHasContext: framePointer) not.
	"Do *not* include the return pc in the stack contents; hence + BytesPerWord"
	^self marryFrame: framePointer SP: stackPointer + BytesPerWord
]

{ #category : #trampolines }
CoInterpreter >> ceReturnToInterpreter: anOop [
	<api>
	self assert: ((self isIntegerObject: anOop) or: [self addressCouldBeObj: anOop]).
	self flag: 'are you really sure setStackPageAndLimit: is needed?'.
	"I think you're only doing this for the markStackPageMostRecentlyUsed:
	 and that's probably not needed either"
	self setStackPageAndLimit: stackPage.
	self assert: (self isMachineCodeFrame: framePointer) not.
	self setMethod: (self iframeMethod: framePointer).
	self assertValidExecutionPointe: (self iframeSavedIP: framePointer)
		r: framePointer
		s: stackPointer
		imbar: true.
	instructionPointer := self iframeSavedIP: framePointer.
	self push: anOop.
	self siglong: reenterInterpreter jmp: 1.
	"NOTREACHED"
	^nil
]

{ #category : #trampolines }
CoInterpreter >> ceSend: selector "<Integer>" super: superNormalBar to: rcvr "<Integer>" numArgs: numArgs [ "<Integer>"
	"Entry-point for an unlinked send in a CogMethod, or, if numArgs < 0, a send of
	 a return escape case (cannotReturn:, aboutToReturn:through:, mustBeBoolean)
	 in machine-code.  Smalltalk stack looks like
					receiver
					args
		head sp ->	sender return pc
		
	If a return escape then simply try and dispatch the send, but the send may turn into an MNU.
	If a normal send then try and link the send site as efficiently as possible.

	If an MNU then defer to handleMNUInMachineCodeTo:... which will dispatch the MNU and
	may choose to allocate a closed PIC with a fast MNU dispatch for this send.

	If not an MNU and the receiver's class is old then try to link to the target method.
	If not an MNU but the receiver's class is young then try and link to an Open PIC for
	this selector.  All link attempts may fail; e.g. because we're out of code memory.

	Continue execution via either executeCogMethodFromUnlinkedSend:withReceiver: or
	activateInterpreterMethodFromMachineCode: depending on whether the target method
	is cogged or not."
	<api>
	| class mayLink canLinkCacheTag |
	<inline: false>
	<var: #cogMethod type: #'CogMethod *'>
	"self printExternalHeadFrame"
	"self printStringOf: selector"
	cogit assertCStackWellAligned.
	self assert: ((self isIntegerObject: rcvr) or: [self addressCouldBeObj: rcvr]).
	self sendBreak: selector + BaseHeaderSize
		point: (self lengthOf: selector)
		receiver: rcvr.
	superNormalBar = 0
		ifTrue: [class := self fetchClassOf: rcvr]
		ifFalse: [class := self superclassOf: (self methodClassOf: (self frameMethodObject: framePointer))].
	numArgs >= 0
		ifTrue:
			[mayLink := linkSends.
			 canLinkCacheTag := (self isYoungObject: class) not or: [cogit canLinkToYoungClasses].
			 argumentCount := numArgs]
		ifFalse: "This is a cannotReturn:, nonLocalreturn:through: or mustBeBoolean send.  Must not link."
			[mayLink := false.
			 argumentCount := -1 - numArgs].
	(self lookupInMethodCacheSel: selector class: class)
		ifTrue:"check for coggability because method is in the cache"
			[self
				ifAppropriateCompileToNativeCode: newMethod
				selector: selector]
		ifFalse:
			[messageSelector := selector.
			 (self lookupMethodNoMNUEtcInClass: class) ifFalse:
				[^self handleMNUInMachineCodeTo: rcvr
					lookupClass: class
					mayLink: (mayLink and: [canLinkCacheTag])].
			 self addNewMethodToCache: class].
	"Method found and has a cog method.  Attempt to link to it.  The receiver's class may be young.
	 If the Cogit can't store young classes in inline caches we can link to an open PIC instead."
	(self methodHasCogMethod: newMethod) ifTrue:
		[mayLink ifTrue:
			[| cogMethod |
			 cogMethod := self cogMethodOf: newMethod.
			 cogMethod selector = nilObj ifTrue:
				[cogit setSelectorOf: cogMethod to: selector].
			 canLinkCacheTag
				ifTrue:
					[cogit
						linkSendAt: (stackPages longAt: stackPointer)
						in: (self mframeHomeMethod: framePointer)
						to: cogMethod
						checked: superNormalBar = 0
						receiver: rcvr]
				ifFalse:
					[cogit
						patchToOpenPICFor: selector
						numArgs: numArgs
						receiver: rcvr]].
		 "Smalltalk stack contains pushed receiver and arguments and return address for sender.
		  Push the registers to be reloaded and the entry-point and jump/return to the new cog method."
		 self executeCogMethodFromUnlinkedSend: (self cogMethodOf: newMethod) withReceiver: rcvr
		 "NOTREACHED"].
	^self activateInterpreterMethodFromMachineCode
	"NOTREACHED"
]

{ #category : #trampolines }
CoInterpreter >> ceSendFromInLineCacheMiss: oPIC [
	"Send from an Open PIC when the first-level method lookup probe has failed,
	 or to continue when PIC creation has failed (e.g. because we're out of code space)."
	<api>
	<var: #oPIC type: #'CogMethod *'>
	| numArgs rcvr class |
	"self printFrame: stackPage headFP WithSP: stackPage headSP"
	"self printStringOf: selector"
	numArgs := oPIC cmNumArgs.
	rcvr := self stackValue: numArgs + 1. "skip return pc"
	self assert: ((self isIntegerObject: rcvr) or: [self addressCouldBeObj: rcvr]).
	class := self fetchClassOf: rcvr.
	argumentCount := numArgs.
	(self lookupInMethodCacheSel: oPIC selector class: class)
		ifTrue:"check for coggability because method is in the cache"
			[self
				ifAppropriateCompileToNativeCode: newMethod
				selector: oPIC selector]
		ifFalse:
			[messageSelector := oPIC selector.
			 (self lookupMethodNoMNUEtcInClass: class) ifFalse:
				[self handleMNUInMachineCodeTo: rcvr
					lookupClass: class
					mayLink: false].
			 self addNewMethodToCache: class].
	(self methodHasCogMethod: newMethod) ifTrue:
		["Smalltalk stack contains pushed receiver and arguments and return address for sender.
		  Push the registers to be reloaded and the entry-point and jump/return to the new cog method."
		 self executeCogMethodFromUnlinkedSend: (self cogMethodOf: newMethod) withReceiver: rcvr
		 "NOTREACHED"].
	^self activateInterpreterMethodFromMachineCode
	"NOTREACHED"
]

{ #category : #trampolines }
CoInterpreter >> ceSendMustBeBoolean: anObject [
	<api>
	instructionPointer := self popStack.
	self push: anObject.
	self push: instructionPointer.
	^self
		ceSend: (self splObj: SelectorMustBeBoolean)
		super: 0
		to: anObject
		numArgs: -0 - 1 "i.e. 0 args & don't link"
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
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: false.
	self setMethod: (newMethod := messageSelector := lkupClass := nilObj).
	switched := self handleStackOverflowOrEventAllowContextSwitch: contextSwitchIfNotNil ~= 0.
	self returnToExecutive: false postContextSwitch: switched.
	self error: 'should not be reached'

]

{ #category : #trampolines }
CoInterpreter >> ceStoreCheck: anOop [
	<api>
	self assert: (self isNonIntegerObject: anOop).
	self assert: (self oop: anOop isLessThan: youngStart).
	self assert: ((self baseHeader: anOop) bitAnd: RootBit) = 0.
	self noteAsRoot: anOop headerLoc: anOop
]

{ #category : #'debug support' }
CoInterpreter >> ceTraceBlockActivation [
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	cogit recordSendTrace ifTrue:
		[self recordTrace: TraceBlockActivation
			thing: (self mframeHomeMethod: framePointer) methodObject
			source: TraceIsFromMachineCode].
	cogit printOnTrace ifTrue:
		[self printActivationNameFor: (self mframeHomeMethod: framePointer) methodObject
			receiver: (self frameReceiver: framePointer)
			isBlock: true
			firstTemporary: nil.
		 self cr]
]

{ #category : #'debug support' }
CoInterpreter >> ceTraceLinkedSend: theReceiver [
	| cogMethod |
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self cCoerceSimple: (self stackTop - cogit traceLinkedSendOffset)
						to: #'CogMethod *'.
	cogit recordSendTrace ifTrue:
		[self recordTrace: (self fetchClassOf: theReceiver) thing: cogMethod selector source: TraceIsFromMachineCode].
	cogit printOnTrace ifTrue:
		[self printActivationNameFor: cogMethod methodObject
			receiver: theReceiver
			isBlock: false
			firstTemporary: nil;
			cr].
	self sendBreak: cogMethod selector + BaseHeaderSize
		point: (self lengthOf: cogMethod selector)
		receiver: (self stackValue: cogMethod cmNumArgs + 2) "+1 for return pc, + 1 for ceSendTrace call ret pc"
]

{ #category : #trampolines }
CoInterpreter >> ceTraceStoreOf: aValue into: anObject [
	<api>
	"For assertion checking."
	self assert: ((self isIntegerObject: aValue) or: [self addressCouldBeObj: aValue]).
	self assert: (self addressCouldBeObj: anObject)
]

{ #category : #'debug support' }
CoInterpreter >> checkAssertsEnabledInCoInterpreter [
	<api>
	| assertsAreEnabledInCoInterpreter |
	assertsAreEnabledInCoInterpreter := false.
	self assert: assertsAreEnabledInCoInterpreter
]

{ #category : #'object memory support' }
CoInterpreter >> checkCodeIntegrity: fullGCFlag [
	"Perform an integrity/leak check using the heapMap.  Assume
	 clearLeakMapAndMapAccessibleObjects has set a bit at each
	 object's header.  Check that all object references in machine
	 code are valid.  Answer if all checks pass."
	^cogit checkIntegrityOfObjectReferencesInCode: fullGCFlag
]

{ #category : #'process primitive support' }
CoInterpreter >> checkCogCompiledCodeCompactionCalledFor [
	cogCompiledCodeCompactionCalledFor ifTrue:
		[self commenceCogCompiledCodeCompaction]
]

{ #category : #'object memory support' }
CoInterpreter >> checkLogIntegrity [
	"Check the log for leaks.  The trace log is a circular buffer of pairs of entries.
	 If there is an entry at traceLogIndex - 3 \\ TraceBufferSize it has entries.  If
	 there is something at traceLogIndex it has wrapped."
	| limit ok |
	limit := self safe: traceLogIndex - 3 mod: TraceBufferSize.
	(traceLog at: limit) = 0 ifTrue: [^nil].
	(traceLog at: traceLogIndex) ~= 0 ifTrue:
		[limit := TraceBufferSize - 3].
	ok := true.
	0 to: limit by: 3 do:
		[:i| | oop |
		oop := traceLog at: i.
		(self isIntegerObject: oop) ifFalse:
			[(self checkOopIntegrity: oop named: 'traceLog' index: i) ifFalse:
				[ok := false]].
		oop := traceLog at: i + 1.
		(self isIntegerObject: oop) ifFalse:
			[(self checkOopIntegrity: oop named: 'traceLog' index: i + 1) ifFalse:
				[ok := false]]].
	^ok
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
	<var: #cogMethod type: #'CogBlockMethod *'>
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
				[theSP := theSP + BytesPerWord].
			 [frameRcvrOffset := self frameReceiverOffset: theFP.
			  [theSP <= frameRcvrOffset] whileTrue:
				[oop := stackPages longAt: theSP.
				 ((self isNonIntegerObject: oop) 
				   and: [(self heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
					[self printFrameThing: 'object leak in frame temp' at: theSP; cr.
					 ok := false].
				 theSP := theSP + BytesPerWord].
			 (self frameHasContext: theFP) ifTrue:
				[oop := self frameContext: theFP.
				 ((self isIntegerObject: oop) 
				   or: [(self heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
					[self printFrameThing: 'object leak in frame ctxt' at: theFP + FoxThisContext; cr.
					 ok := false].
				 (oop = nilObj or: [self isContext: oop]) ifFalse:
					[self printFrameThing: 'frame ctxt should be context' at: theFP + FoxThisContext; cr.
					 ok := false]].
			 (self isMachineCodeFrame: theFP)
				ifTrue:
					[| cogMethod |
					 cogMethod := self mframeCogMethod: theFP.
					 cogMethod cmType = CMBlock ifTrue:
						[cogMethod := self cCoerceSimple: (cogit cogHomeMethod: cogMethod)
											to: #'CogBlockMethod *'].
					 ((cogMethod asInteger bitAnd: BytesPerWord - 1) ~= 0 
					   or: [(self heapMapAtWord: (self pointerForOop: cogMethod)) = 0]) ifTrue:
						[self printFrameThing: 'object leak in mframe mthd' at: theFP + FoxMethod; cr.
						 ok := false]]
				ifFalse:
					[oop := self iframeMethod: theFP.
					 ((self isIntegerObject: oop) 
					   or: [(self heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
						[self printFrameThing: 'object leak in iframe mthd' at: theFP + FoxMethod; cr.
						 ok := false]].
			 (callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
				[theSP := theFP + FoxCallerSavedIP + BytesPerWord.
				 theFP := callerFP].
			 theSP := theFP + FoxCallerSavedIP + BytesPerWord.
			 [theSP <= thePage baseAddress] whileTrue:
				[oop := stackPages longAt: theSP.
				 ((self isNonIntegerObject: oop) 
				   and: [(self heapMapAtWord: (self pointerForOop: oop)) = 0]) ifTrue:
					[self printFrameThing: 'object leak in frame arg' at: theSP; cr.
					 ok := false].
				 theSP := theSP + BytesPerWord]]].
	^ok
]

{ #category : #'cog jit support' }
CoInterpreter >> classFloatCompactIndex [
	<api>
	^ClassFloatCompactIndex
]

{ #category : #'object enumeration' }
CoInterpreter >> clearLeakMapAndMapAccessibleObjects [
	"Perform an integrity/leak check using the heapMap.  Set a bit at each object's header.
	 Override to set a bit at each Cog method"
	| obj sz nextHeader |
	<inline: false>
	<var: #obj type: #usqInt>
	<var: #sz type: #usqInt>
	<var: #nextHeader type: #usqInt>
	self clearHeapMap.
	obj := self firstObject.
	[obj < freeStart] whileTrue:
		[(self isFreeObject: obj)
			ifTrue:
				[sz := self sizeOfFree: obj]
			ifFalse:
				[self heapMapAtWord: (self pointerForOop: obj) Put: 1.
				 sz := self sizeBitsOf: obj].
		nextHeader := obj + sz.
		obj := self oopFromChunk: nextHeader].
	cogit addCogMethodsToHeapMap
]

{ #category : #'debug support' }
CoInterpreter >> clearTraceLog [
	<api>
	traceLogIndex := 0.
	0 to: TraceBufferSize - 1 do:
		[:i|
		traceLog at: i put: 0]
]

{ #category : #'compiled methods' }
CoInterpreter >> cogMethodOf: aMethodOop [
	<api>
	<returnTypeC: #'CogMethod *'>
	| methodHeader |
	methodHeader := self rawHeaderOf: aMethodOop.
	self assert: ((self isNonIntegerObject: methodHeader)
				and: [methodHeader asUnsignedInteger < self startOfMemory]).
	^self cCoerceSimple: methodHeader to: #'CogMethod *'
]

{ #category : #'process primitive support' }
CoInterpreter >> commenceCogCompiledCodeCompaction [
	| startTime |
	<var: #startTime type: #usqLong>
	cogCompiledCodeCompactionCalledFor := false.
	cogit recordEventTrace ifTrue:
		[self recordTrace: TraceCodeCompaction thing: TraceCodeCompaction source: 0].
	startTime := self ioUTCMicrosecondsNow.

	"This can be called in a number of circumstances.  The instructionPointer
	 may contain a native pc that must be relocated.  There may already be a
	 pushed instructionPointer on stack.  Clients ensure that instructionPointer
	 is 0 if it should not be pushed and/or relocated.  Pushing twice is a mistake
	 because only the top one will be relocated."
	instructionPointer ~= 0 ifTrue:
		[self push: instructionPointer.
		 self externalWriteBackHeadStackPointer].
	cogit compactCogCompiledCode.
	instructionPointer ~= 0 ifTrue:
		[instructionPointer := self popStack.
		 self externalWriteBackHeadStackPointer].

	statCodeCompactionCount := statCodeCompactionCount + 1.
	statCodeCompactionUsecs := statCodeCompactionUsecs + (self ioUTCMicrosecondsNow - startTime).

	checkForLeaks ~= 0 ifTrue:
		[self clearLeakMapAndMapAccessibleObjects.
		 self assert: (self checkCodeIntegrity: false)]
]

{ #category : #'return bytecodes' }
CoInterpreter >> commonCallerReturn [
	"Return to the previous context/frame (sender for method activations, caller for block activations)."
	| callersFPOrNull |
	<var: #callersFPOrNull type: #'char *'>
	<sharedCodeNamed: 'commonCallerReturn' inCase: 125> "returnTopFromBlock"

	callersFPOrNull := self frameCallerFP: localFP.
	callersFPOrNull == 0 "baseFrame" ifTrue:
		[self assert: localFP = stackPage baseFP.
		 ^self baseFrameReturn].

	localIP := self pointerForOop: (self frameCallerSavedIP: localFP).
	localSP := localFP + (self frameStackedReceiverOffset: localFP).
	localFP := callersFPOrNull.
	localIP asUnsignedInteger < self startOfMemory ifTrue:
		[localIP asUnsignedInteger ~= cogit ceReturnToInterpreterPC ifTrue:
			["localIP in the cog method zone indicates a return to machine code."
			 ^self returnToMachineCodeFrame].
		 localIP := self pointerForOop: (self iframeSavedIP: localFP)].
	self internalStackTopPut: localReturnValue.
	self setMethod: (self iframeMethod: localFP).
	^self fetchNextBytecode
]

{ #category : #'return bytecodes' }
CoInterpreter >> commonReturn [
	"Note: Assumed to be inlined into the dispatch loop."

	| closure home unwindContextOrNilOrZero frameToReturnTo contextToReturnTo theFP callerFP newPage |
	<var: #frameToReturnTo type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #newPage type: #'StackPage *'>
	<var: #thePage type: #'StackPage *'>
	<sharedCodeNamed: 'commonReturn' inCase: 120>

	"If this is a method simply return to the  sender/caller."
	(self frameIsBlockActivation: localFP) ifFalse:
		[^self commonCallerReturn].

	"Since this is a block activation the closure is on the stack above any args and the frame."
	closure := self pushedReceiverOrClosureOfFrame: localFP.

	home := nil.
	"Walk the closure's lexical chain to find the context or frame to return from (home)."
	[closure ~~ nilObj] whileTrue:
		[home := self fetchPointer: ClosureOuterContextIndex ofObject: closure.
		 closure := self fetchPointer: ClosureIndex ofObject: home].
	"home is to be returned from provided there is no unwind-protect activation between
	 this frame and home's sender.  Search for an unwind.  findUnwindThroughContext:
	 will answer either the context for an unwind-protect activation or nilObj if the sender
	 cannot be found or 0 if no unwind is found but the sender is.  We must update the
	 current page's headFrame pointers to enable the search to identify widowed contexts
	 correctly."
	self writeBackHeadFramePointers.
	unwindContextOrNilOrZero := self internalFindUnwindThroughContext: home.
	unwindContextOrNilOrZero = nilObj ifTrue:
		["error: can't find home on chain; cannot return"
		 ^self internalCannotReturn: localReturnValue].
	unwindContextOrNilOrZero ~~ 0 ifTrue:
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
			[contextToReturnTo := self fetchPointer: SenderIndex ofObject: home.
			 ((self isContext: contextToReturnTo)
			  and: [self isMarriedOrWidowedContext: contextToReturnTo]) ifTrue:
				[self assert: (self checkIsStillMarriedContext: contextToReturnTo currentFP: localFP).
			 	 frameToReturnTo := self frameOfMarriedContext: contextToReturnTo.
				 contextToReturnTo := nil]].

	"If returning to a context we must make a frame for it unless it is dead."
	contextToReturnTo ~= nil ifTrue:
		[frameToReturnTo := self establishFrameForContextToReturnTo: contextToReturnTo.
		 frameToReturnTo == 0 ifTrue:
			["error: home's sender is dead; cannot return"
			 ^self internalCannotReturn: localReturnValue]].

	"Now we have a frame to return to.  If it is on a different page we must free intervening pages and
	 nil out intervening contexts.  We must free intervening stack pages because if we leave the pages
	 to be divorced then their contexts will be divorced with intact senders and instruction pointers.  This
	 code is similar to primitiveTerminateTo.  We must move any frames on itervening pages above the
	 frame linked to because these may be in use, e.g. via co-routining (see baseFrameReturn)."
	self assert: stackPages pageListIsWellFormed.
	newPage := stackPages stackPageFor: frameToReturnTo.
	newPage ~~ stackPage ifTrue:
		[| currentCtx thePage nextCntx |
		 currentCtx := self frameCallerContext: stackPage baseFP.
		 self assert: (self isContext: currentCtx).
		 stackPages freeStackPage: stackPage.
		 [(self isMarriedOrWidowedContext: currentCtx)
		   and: [(stackPages stackPageFor: (theFP := self frameOfMarriedContext: currentCtx)) = newPage]] whileFalse:
			[(self isMarriedOrWidowedContext: currentCtx)
				ifTrue:
					[thePage := stackPages stackPageFor: theFP.
					 theFP ~= thePage headFP ifTrue:
						["Since we've just deallocated a page we know that newStackPage won't deallocate an existing one."
						 self moveFramesIn: thePage through: (self findFrameAbove: theFP inPage: thePage) toPage: self newStackPage].
					 currentCtx := self frameCallerContext: thePage baseFP.
					 self freeStackPage: thePage]
				ifFalse:
					[self assert: (self isContext: currentCtx).
					 nextCntx := self fetchPointer: SenderIndex ofObject: currentCtx.
					 self storePointerUnchecked: SenderIndex ofObject: currentCtx withValue: nilObj.
					 self storePointerUnchecked: InstructionPointerIndex ofObject: currentCtx withValue: nilObj.
					 currentCtx := nextCntx]].
		 self setStackPageAndLimit: newPage.
		 localSP := stackPage headSP.
		 localFP := stackPage headFP].

	"Two cases.  Returning to the top frame on a new page or an interior frame on the current page.
	 The top frame has its instruction pointer on top of stack. An interior frame has its instruction pointer
	 in the caller frame. We need to peel back any frames on the page until we get to the correct frame."
	localFP = frameToReturnTo
		ifTrue:
			[localIP := self pointerForOop: self internalStackTop]
		ifFalse:
			[[callerFP := localFP.
			  localFP := self frameCallerFP: localFP.
			  localFP ~~ frameToReturnTo] whileTrue.
			localIP := self frameCallerSavedIP: callerFP.
			localSP := (self frameCallerSP: callerFP) - BytesPerWord].
	localIP asUnsignedInteger < self startOfMemory ifTrue:
		[localIP asUnsignedInteger ~= cogit ceReturnToInterpreterPC ifTrue:
			["localIP in the cog method zone indicates a return to machine code."
			 ^self returnToMachineCodeFrame].
		 localIP := self pointerForOop: (self iframeSavedIP: localFP)].
	"pop the saved IP, push the return value and continue."
	self internalStackTopPut: localReturnValue.
	self setMethod: (self iframeMethod: localFP).
	^self fetchNextBytecode
]

{ #category : #'message sending' }
CoInterpreter >> commonSend [
	"Send a message, starting lookup with the receiver's class."
	"Assume: messageSelector and argumentCount have been set, and that 
	the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."
	<sharedCodeNamed: 'commonSend' inCase: 131>
	self sendBreak: messageSelector + BaseHeaderSize
		point: (self lengthOf: messageSelector)
		receiver: (self internalStackValue: argumentCount).
	cogit recordSendTrace ifTrue:
		[self recordTrace: lkupClass thing: messageSelector source: TraceIsFromInterpreter].
	self internalFindNewMethod.
	self internalExecuteNewMethod.
	self fetchNextBytecode
]

{ #category : #'cog jit support' }
CoInterpreter >> compactClassTable [
	<api>
	^self splObj: CompactClasses
]

{ #category : #'debug support' }
CoInterpreter >> compilationBreak: selectorString point: selectorLength [
	<api>
	<cmacro: '(sel, len) do { \
	if ((len) == breakSelectorLength \
	 && !strncmp((char *)(sel), breakSelector, breakSelectorLength)) { \
		suppressHeartbeatFlag = 1; \
		warning("compilation send break (heartbeat suppressed)"); \
	} \
} while (0)'>
	| i |
	breakSelectorLength = selectorLength ifTrue:
		[i := breakSelectorLength.
		 [i > 0] whileTrue:
			[(self byteAt: selectorString + i - 1) = (breakSelector at: i) asInteger
				ifTrue: [(i := i - 1) = 0 ifTrue:
							[self halt: 'Compilation of ', breakSelector]]
				ifFalse: [i := 0]]]
]

{ #category : #initialization }
CoInterpreter >> computeStackZoneSize [
	^numStackPages * ((self sizeof: CogSimpleStackPage) + self stackPageByteSize)
	 + stackPages extraStackBytes
]

{ #category : #'frame access' }
CoInterpreter >> contextInstructionPointer: mcpc context: aContext [
	"Answer a value to store in the InstructionPointer index of a context object for mcpc.
	 This is needed for cannotReturn: where we have the instructionPointer, the context
	 but not the cog method, and so don't know which method or block we're in.  Find it."
	<inline: false>
	| methodObj homeMethod cogMethod |
	<var: #homeMethod type: #'CogMethod *'>
	<var: #cogMethod type: #'CogBlockMethod *'>
	methodObj := self fetchPointer: MethodIndex ofObject: aContext.
	self assert: (self methodHasCogMethod: methodObj).
	homeMethod := self cogMethodOf: methodObj.
	cogMethod := cogit findEnclosingMethodFor: mcpc inHomeMethod: homeMethod.
	self assert: (cogMethod cmType = CMBlock)
				= ((self fetchPointer: ClosureIndex ofObject: aContext) ~= nilObj).
	^self encodedNativePCOf: mcpc cogMethod: cogMethod
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
	^self integerObjectOf: (theIP = cogit ceReturnToInterpreterPC
							ifTrue: [self iframeSavedIP: theFP]
							ifFalse: [theIP])
						- (self iframeMethod: theFP)
						- BaseHeaderSize
						+ 2
]

{ #category : #'image segment in/out' }
CoInterpreter >> copyObj: oop toSegment: segmentWordArray addr: lastSeg stopAt: stopAddr saveOopAt: oopPtr headerAt: hdrPtr [
	"Copy this object into the segment beginning at lastSeg.
	Install a forwarding pointer, and save oop and header.
	Fail if out of space.  Return the next segmentAddr if successful.
	Override to write the true header of cogged compiled methods."

	"Copy the object..."
	| extraSize bodySize hdrAddr |
	self flag: #Dan.  "None of the imageSegment stuff has been updated for 64 bits"
	self successful ifFalse: [^ lastSeg].
	extraSize := self extraHeaderBytes: oop.
	bodySize := self sizeBitsOf: oop.
	(self oop: lastSeg + extraSize + bodySize isGreaterThanOrEqualTo: stopAddr)
		ifTrue: [^ self primitiveFail].
	self transfer: extraSize + bodySize // BytesPerWord  "wordCount"
		from: oop - extraSize
		to: lastSeg+BytesPerWord.

	"Clear root and mark bits of all headers copied into the segment"
	hdrAddr := (lastSeg+BytesPerWord) + extraSize.
	self longAt: hdrAddr put: ((self longAt: hdrAddr) bitAnd: AllButRootBit - MarkBit).

	"Make sure Cogged methods have their true header field written to the segment."
	((self isCompiledMethod: oop)
	and: [self methodHasCogMethod: oop]) ifTrue:
		[self longAt: hdrAddr+BaseHeaderSize put: (self headerOf: oop)].

	self forward: oop
		to: lastSeg+BytesPerWord + extraSize - segmentWordArray
		savingOopAt: oopPtr andHeaderAt: hdrPtr.

	"Return new end of segment"
	^ lastSeg + extraSize + bodySize
]

{ #category : #trampolines }
CoInterpreter >> createClosureNumArgs: numArgs numCopied: numCopied startpc: initialIP [
	<api>
	| context newClosure |
	<var: #sp type: #'char *'>
	self assert: (self isMachineCodeFrame: framePointer).
	"Do *not* include the return pc or copied values in the stack contents;
	 hence + ((1 + numCopied) * BytesPerWord)"
	context := self ensureFrameIsMarried: framePointer
					SP: stackPointer + ((1 + numCopied) * BytesPerWord).
	newClosure := self
					closureIn: context
					numArgs: numArgs
					instructionPointer: initialIP
					numCopiedValues: numCopied.
	cogit recordSendTrace ifTrue:
		[self recordTrace: TraceBlockCreation thing: newClosure source: TraceIsFromMachineCode].
	numCopied > 0 ifTrue:
		["N.B. the expression ((numCopied - i) * BytesPerWord)) skips the return address"
		 0 to: numCopied - 1 do:
			[:i|
			"Assume: have just allocated a new BlockClosure; it must be young.
			 Thus, can use unchecked stores."
			 self storePointerUnchecked: i + ClosureFirstCopiedValueIndex
				ofObject: newClosure
				withValue: (stackPages longAt: stackPointer + ((numCopied - i) * BytesPerWord))]].
	"Assume caller will pop stack"
	^newClosure
]

{ #category : #initialization }
CoInterpreter >> defaultCogCodeSize [
	"Return the default number of bytes to allocate for native code at startup.
	 The actual value can be set via vmParameterAt: and/or a preference in the ini file."
	<inline: false>
	^1024 * 1024
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
		 self forceInterruptCheck]
]

{ #category : #'debug support' }
CoInterpreter >> dumpPrimTraceLog [
	<api>
	"The prim trace log is a circular buffer of entries. If there is
	 an entry at primTraceLogIndex \\ PrimTraceLogSize it has entries.
	 If there is something at primTraceLogIndex it has wrapped."
	<inline: false>
	(primTraceLog at: (self safe: primTraceLogIndex - 1 mod: PrimTraceLogSize)) = 0 ifTrue: [^nil].
	(primTraceLog at: primTraceLogIndex) ~= 0 ifTrue:
		[primTraceLogIndex to: PrimTraceLogSize - 1 do:
			[:i| self safePrintStringOf: (primTraceLog at: i); cr]].

	0 to: primTraceLogIndex - 1 do:
		[:i| self safePrintStringOf: (primTraceLog at: i); cr]
]

{ #category : #'debug support' }
CoInterpreter >> dumpTraceLog [
	<api>
	"The trace log is a circular buffer of pairs of entries. If there is
	 an entry at traceLogIndex - 3 \\ TraceBufferSize it has entries.
	 If there is something at traceLogIndex it has wrapped."
	<inline: false>
	(traceLog at: (self safe: traceLogIndex - 3 mod: TraceBufferSize)) = 0 ifTrue: [^nil].
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
		[^HasBeenReturnedFromMCPC].
	cogMethod cmType = CMMethod ifTrue:
		[^self integerObjectOf: cogMethod asInteger - mcpc].
	homeMethod := cogit cogHomeMethod: cogMethod.
	blockOffset := homeMethod asInteger - cogMethod asInteger / (cogit sizeof: CogBlockMethod).
	^self integerObjectOf: ((blockOffset bitShift: 16) bitOr: (cogMethod asInteger - mcpc bitAnd: 16rFFFF))
]

{ #category : #'frame access' }
CoInterpreter >> ensureAllContextsHaveBytecodePCsOrAreBereaved [
	"Enumerate all contexts preparing them for a snapshot.  Map all native pcs to bytecoded pcs.
	 Convert widowed contexts to single contexts so that the snapshot contains only single contexts.
	 This allows the being married test to avoid checking for a context's frame pointer being in bounds
	 since all frame pointers must have been created in the current system and so be in bounds.
	 Thanks to Greg Nuyens for this idea."
	| oop decodedIP |
	oop := self firstObject.
	[oop < freeStart] whileTrue:
		[((self isFreeObject: oop) not
		   and: [self isContextNonInt: oop]) ifTrue:
			[(self isMarriedOrWidowedContext: oop)
				ifTrue: "The stack pages have already been discarded.  Any remaining married contexts are actually widows."
					[self storePointerUnchecked: SenderIndex ofObject: oop withValue: nilObj.
					 self storePointerUnchecked: InstructionPointerIndex ofObject: oop withValue: nilObj]
				ifFalse:
					[decodedIP := self fetchPointer: InstructionPointerIndex ofObject: oop.
					((self isIntegerObject: decodedIP)
					 and: [decodedIP signedIntFromLong < 0]) ifTrue:
						[decodedIP := self mustMapMachineCodePC: (self integerValueOf: decodedIP)
											context: oop.
						 self storePointerUnchecked: InstructionPointerIndex ofObject: oop withValue: decodedIP]]].
		 oop := self objectAfter: oop]
]

{ #category : #'frame access' }
CoInterpreter >> ensureMethodIsCogged: methodObj [
	(self methodHasCogMethod: methodObj) ifFalse:
		[((cogit cog: methodObj selector: nilObj) = nil
		   and: [cogCompiledCodeCompactionCalledFor]) ifTrue:
			[self commenceCogCompiledCodeCompaction.
			 cogit cog: methodObj selector: nilObj]].
	(self asserta: (self methodHasCogMethod: methodObj)) ifFalse:
		[self error: 'could not compile method that should have been compiled']
]

{ #category : #enilopmarts }
CoInterpreter >> ensurePushedInstructionPointer [
	"We're about to make some transition to a machine code method which
	 requires the instructionPointer must be on the stack.  We could have come
	 from the interpreter, either directly or via a machine code primitive.  We
	 could have come from machine code.  The instructionPointer tells us where
	 from.  Make sure the instruction pointer is pushed and/or saved."
	instructionPointer asUnsignedInteger >= self startOfMemory
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
CoInterpreter >> enterSmalltalkExecutive [
	"Main entry-point into the interpreter at each execution level, where an
	 execution level is either the start of execution or reentry for a callback."
	<cmacro: '() enterSmalltalkExecutiveImplementation()'>
	"Simulation of the setjmp in enterSmalltalkExecutiveImplementation for reentry into interpreter."
	[([self enterSmalltalkExecutiveImplementation]
		on: ReenterInterpreter
		do: [:ex| ex return: ex returnValue]) = 1] whileTrue
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
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: true.
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
	"Execute a block within a CogMethod.  The caller has already pushed
	 the block and any arguments and the return pc.  First push the
	 return-to-interpreter trampoline, then the entry-point and finally the
	 register argument(s).  Then jump to the block entry by executing a
	 return instruction.
	 In the simple jit only the receiver gets passed in registers, so only the
	 receiver gets pushed."
	<var: #cogMethod type: #'CogMethod *'>
	cogit assertCStackWellAligned.
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer.
	self ensurePushedInstructionPointer.
	self push: cogMethod asInteger
			+ (mayContextSwitch
				ifTrue: [cogMethod blockEntryOffset]
				ifFalse: [cogMethod blockEntryOffset - cogit noContextSwitchBlockEntryOffset]).
	self push: closure.
	cogit ceEnterCogCodePopReceiverReg
	"NOTREACHED"
]

{ #category : #enilopmarts }
CoInterpreter >> executeCogMethod: cogMethod [
	"Execute a CogMethod.  The interpreter has already pushed the receiver
	 and any arguments.  First push the return-to-interpreter trampoline,
	 then the entry-point and finally  the register argument(s).  Then write
	 back the frame pointers and call the routine that will pop off the register
	 argument(s) and jump to the entry by executing a return instruction.

	 In the simple jit only the receiver gets passed in registers, so only the
	 receiver gets pushed."
	| rcvr |
	<var: #cogMethod type: #'CogMethod *'>
	cogit assertCStackWellAligned.
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer.
	rcvr := self stackValue: cogMethod cmNumArgs.
	self ensurePushedInstructionPointer.
	self push: cogMethod asUnsignedInteger + cogit noCheckEntryOffset.
	self push: rcvr.
	cogit ceEnterCogCodePopReceiverReg
	"NOTREACHED"
]

{ #category : #enilopmarts }
CoInterpreter >> executeCogMethodFromLinkedSend: cogMethod withReceiver: rcvr [
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
	self assertValidExecutionPointe: self stackTop r: framePointer s: stackPointer imbar: false.
	self
		push: cogMethod asInteger + cogit entryOffset;
		push: rcvr.
	cogit ceEnterCogCodePopReceiverReg
	"NOTREACHED"
]

{ #category : #enilopmarts }
CoInterpreter >> executeCogMethodFromLinkedSend: cogMethod withReceiver: rcvr andCacheTag: cacheTag [
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
	self assertValidExecutionPointe: self stackTop r: framePointer s: stackPointer imbar: false.
	self
		push: cogMethod asInteger + cogit entryOffset;
		push: rcvr;
		push: cacheTag.
	cogit ceEnterCogCodePopReceiverAndClassRegs
	"NOTREACHED"
]

{ #category : #enilopmarts }
CoInterpreter >> executeCogMethodFromUnlinkedSend: cogMethod withReceiver: rcvr [
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
	self assertValidExecutionPointe: self stackTop r: framePointer s: stackPointer imbar: false.
	self
		push: cogMethod asInteger + cogit noCheckEntryOffset;
		push: rcvr.
	cogit ceEnterCogCodePopReceiverReg
	"NOTREACHED"
]

{ #category : #'message sending' }
CoInterpreter >> executeNewMethod [
	"Execute newMethod - either primitiveFunctionPointer must be set directly
	 (i.e. from primitiveExecuteMethod et al), or it would have been set probing
	 the method cache (i.e. primitivePerform et al).
	 Eagerly compile it if it is large enough so that doits are fast."
	| methodHeader inInterpreter |
	methodHeader := self rawHeaderOf: newMethod.
	(self isCogMethodReference: methodHeader) ifFalse:
		[(self methodWithHeaderShouldBeCogged: methodHeader)
			ifTrue:
				[cogit cog: newMethod selector: nilObj.
				 methodHeader := self rawHeaderOf: newMethod]
			ifFalse: [self maybeFlagMethodAsInterpreted: newMethod]].
	(self isCogMethodReference: methodHeader) ifTrue:
		[^self executeCogMethod: (self cCoerceSimple: methodHeader to: #'CogMethod *')].
	primitiveFunctionPointer ~= 0 ifTrue:
		[self isPrimitiveFunctionPointerAnIndex ifTrue:
			[self externalQuickPrimitiveResponse.
			 ^nil].
		 "slowPrimitiveResponse may of course context-switch.  If so we must reenter the
		  new process appopriately, returning only if we've reached here directly from the
		  interpreter and have found an interpreter frame.  The instructionPointer tells us
		  from whence we came."
		 inInterpreter := instructionPointer >= self startOfMemory.
		 self slowPrimitiveResponse.
		 self successful ifTrue:
			[self return: self popStack toExecutive: inInterpreter.
			 ^nil]].
	"if not primitive, or primitive failed, activate the method"
	self activateNewMethod
]

{ #category : #'stack bytecodes' }
CoInterpreter >> extendedStoreBytecode [
	"Override to use itemporary:in:put:"
	| descriptor variableType variableIndex association |
	<inline: true>
	descriptor := self fetchByte.
	self fetchNextBytecode.
	variableType := descriptor >> 6 bitAnd: 3.
	variableIndex := descriptor bitAnd: 63.
	variableType = 0 ifTrue:
		[^self storePointer: variableIndex ofObject: self receiver withValue: self internalStackTop].
	variableType = 1 ifTrue:
		[^self itemporary: variableIndex in: localFP put: self internalStackTop].
	variableType = 3 ifTrue:
		[association := self literal: variableIndex.
		 ^self storePointer: ValueIndex ofObject: association withValue: self internalStackTop].
	self error: 'illegal store'.
	^nil
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
		ceSend: (self splObj: SelectorAboutToReturn)
		super: 0
		to: ourContext
		numArgs: -2 - 1 "i.e. 2 args & don't link"
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
		ceSend: (self splObj: SelectorCannotReturn)
		super: 0
		to: aContext
		numArgs: -1 - 1 "i.e. 1 arg & don't link"
]

{ #category : #'frame access' }
CoInterpreter >> externalInstVar: offset ofContext: aContext [
	"Fetch an instance variable from a maybe married context.
	 If the context is still married compute the value of the
	 relevant inst var from the spouse frame's state.

	 If the context is single but has a negative instruction pointer
	 recognise that the instruction pointer is actually into machine
	 code and convert it to the corresponding bytecode pc."
	| value spouseFP |
	<var: #spouseFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #theFPAbove type: #'char *'>

	self assert: offset < MethodIndex.
	self assert: (self isContext: aContext).
	self externalWriteBackHeadFramePointers.
	(self isMarriedOrWidowedContext: aContext) ifFalse:
		[value := self fetchPointer: offset ofObject: aContext.
		 ^(offset = InstructionPointerIndex
		    and: [(self isIntegerObject: value)
		    and: [value signedIntFromLong < 0]])
			ifTrue: [self mustMapMachineCodePC: (self integerValueOf: value)
						context: aContext]
			ifFalse: [value]].

	(self isWidowedContext: aContext) ifTrue:
		[^self fetchPointer: offset ofObject: aContext].

	spouseFP := self frameOfMarriedContext: aContext.
	offset = SenderIndex ifTrue:
		[^self ensureCallerContext: spouseFP].
	offset = StackPointerIndex ifTrue:
		[self assert: ReceiverIndex + (self stackPointerIndexForFrame: spouseFP) < (self lengthOf: aContext).
		^self integerObjectOf: (self stackPointerIndexForFrame: spouseFP)].
	offset = InstructionPointerIndex ifTrue:
		[| theIP thePage theFPAbove |
		 spouseFP = framePointer
			ifTrue: [theIP := self oopForPointer: instructionPointer]
			ifFalse:
				[thePage := stackPages stackPageFor: spouseFP.
				 theFPAbove := self findFrameAbove: spouseFP inPage: thePage.
				 theIP := theFPAbove == 0
							ifTrue: [stackPages longAt: thePage headSP]
							ifFalse:[self oopForPointer: (self frameCallerSavedIP: theFPAbove)]].
		 value := self contextInstructionPointer: theIP frame: spouseFP.
		 ^value signedIntFromLong < 0
			ifTrue: [self mustMapMachineCodePC: (self integerValueOf: value)
						context: aContext]
			ifFalse: [value]].
	self error: 'bad index'.
	^0
]

{ #category : #'cog jit support' }
CoInterpreter >> externalWriteBackHeadStackPointer [
	self assert: (stackPointer < stackPage baseAddress
				and: [stackPointer > (stackPage realStackLimit - LargeContextSize)]).
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
CoInterpreter >> fastLogPrim: aSelector [
	"Fast tracing of named primitives.  primTraceLogIndex is a byte variable.
	 primTraceLog has 256 entries.  In C the + 1 below is hence implicitly modulo 256."
	<inline: true>
	primTraceLog at: primTraceLogIndex put: aSelector.
	self primTraceLogIndex: primTraceLogIndex + 1
]

{ #category : #'message sending' }
CoInterpreter >> findNewMethodInClass: class [ 
	"Find the compiled method to be run when the current messageSelector is
	 sent to the given class, setting the values of newMethod and primitiveIndex."
	| ok |
	<inline: false>
	ok := self lookupInMethodCacheSel: messageSelector class: class.
	ok	ifTrue:
			[self ifAppropriateCompileToNativeCode: newMethod selector: messageSelector]
		ifFalse:
			["entry was not found in the cache; look it up the hard way "
			 self lookupMethodInClass: class.
			 self addNewMethodToCache: class]
]

{ #category : #'plugin primitive support' }
CoInterpreter >> flushExternalPrimitiveOf: methodObj [
	"methodObj is a CompiledMethod containing an external primitive.
	 Flush the function address and session ID of the CM.  Override
	 to also flush the machine code call if one exists."
	| lit |
	(self literalCountOf: methodObj) > 0 ifFalse:
		[^nil]. "Something's broken"
	lit := self literal: 0 ofMethod: methodObj.
	((self isArray: lit) and:[(self lengthOf: lit) = 4]) ifFalse:
		[^nil]. "Something's broken"
	"ConstZero is a known SmallInt so no root check needed"
	self storePointerUnchecked: 2 ofObject: lit withValue: ConstZero.
	self storePointerUnchecked: 3 ofObject: lit withValue: ConstZero.
	(self methodHasCogMethod: methodObj) ifTrue:
		[cogit rewritePrimInvocationIn: (self cogMethodOf: methodObj)
			to: #primitiveExternalCall asSymbol]
]

{ #category : #'method lookup cache' }
CoInterpreter >> flushMethodCache [
	"Flush the method cache. The method cache is flushed on every programming change and garbage collect."

	1 to: MethodCacheSize do: [ :i | methodCache at: i put: 0 ].
	lastMethodCacheProbeWrite := 0. "this for primitiveExternalMethod"
	cogit unlinkAllSends
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
		 deferSmash
			ifTrue: [deferredSmash := true]
			ifFalse: [self forceInterruptCheck]]
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
	self assert: (self addressCouldBeObj: callerContextOrNil).
	self assert: (callerContextOrNil = nilObj or: [self isContext: callerContextOrNil]).
	^callerContextOrNil
]

{ #category : #'frame access' }
CoInterpreter >> frameCallerContext: theFP put: aValue [
	"In the StackInterpreter the saved ip field of a base frame holds the
	 base frame's caller context. But in the Cog VM the first word on the
	 stack holds the base frame's caller context, which is immediately
	 above the stacked receiver."
	self assert: (self isBaseFrame: theFP).
	self assert: theFP + (self frameStackedReceiverOffset: theFP) + (2 * BytesPerWord) = (stackPages stackPageFor: theFP) baseAddress.
	self assert: (stackPages longAt: theFP + (self frameStackedReceiverOffset: theFP) + BytesPerWord) = (self frameContext: theFP).
	^stackPages
		longAt: theFP + (self frameStackedReceiverOffset: theFP) + (2 * BytesPerWord)
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

{ #category : #'cog jit support' }
CoInterpreter >> framePointer: theFP [
	"Simulation only"
	<doNotGenerate>
	framePointer := theFP
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
CoInterpreter >> frameReceiverOffset: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^(self isMachineCodeFrame: theFP)
		ifTrue: [theFP + FoxMFReceiver]
		ifFalse: [theFP + FoxIFReceiver]
]

{ #category : #'cog jit support' }
CoInterpreter >> freeStart [
	<doNotGenerate>
	^freeStart
]

{ #category : #'cog jit support' }
CoInterpreter >> freeStart: aValue [
	<doNotGenerate>
	freeStart := aValue
]

{ #category : #'trampoline support' }
CoInterpreter >> freeStartAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: freeStart) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #freeStart in: self]
]

{ #category : #'plugin primitives' }
CoInterpreter >> functionForPrimitiveExternalCall: methodObj [
	"Arrange to call the external primitive directly.  The complication is arranging
	 that the call can be flushed, given that it is embedded in machine code."
	<returnTypeC: 'void (*functionForPrimitiveExternalCall(sqInt methodObj))(void)'>
	| lit index functionPointer |
	<var: #functionPointer declareC: #'void (*functionPointer)(void)'>
	cogit setPostCompileHook: #recordCallOffsetIn:of: asSymbol.
	(self literalCountOf: methodObj) > 0 ifFalse:
		[^#primitiveExternalCall asSymbol].
	lit := self literal: 0 ofMethod: methodObj. 
	"Check if it's an array of length 4"
	((self isArray: lit) and: [(self lengthOf: lit) = 4]) ifFalse:
		[^#primitiveExternalCall asSymbol].
	index := self fetchPointer: 3 ofObject: lit.
	((self isIntegerObject: index)
	and: [(index := self integerValueOf: index) > 0
	and: [index <= MaxExternalPrimitiveTableSize]]) ifFalse:
		[^#primitiveExternalCall asSymbol].
	functionPointer := externalPrimitiveTable at: index - 1.
	functionPointer = 0 ifTrue:
		[^#primitiveExternalCall asSymbol].
	^functionPointer
]

{ #category : #'cog jit support' }
CoInterpreter >> functionPointerForCompiledMethod: methodObj primitiveIndex: primIndex [
	<api>
	<returnTypeC: 'void (*functionPointerForCompiledMethodprimitiveIndex(sqInt methodObj, sqInt primIndex))(void)'>
	| functionPointer |
	<var: #functionPointer declareC: #'void (*functionPointer)(void)'>
	functionPointer := self functionPointerFor: primIndex inClass: nil.
	functionPointer == #primitiveAt asSymbol ifTrue:
		[^#primitiveNoAtCacheAt asSymbol].
	functionPointer == #primitiveAtPut asSymbol ifTrue:
		[^#primitiveNoAtCacheAtPut asSymbol].
	functionPointer == #primitiveStringAt asSymbol ifTrue:
		[^#primitiveNoAtCacheStringAt asSymbol].
	functionPointer == #primitiveStringAtPut asSymbol ifTrue:
		[^#primitiveNoAtCacheStringAtPut asSymbol].
	functionPointer == #primitiveCalloutToFFI asSymbol ifTrue:
		[^self functionForPrimitiveCallout].
	functionPointer == #primitiveExternalCall asSymbol ifTrue:
		[^self functionForPrimitiveExternalCall: methodObj].
	^functionPointer
]

{ #category : #'internal interpreter access' }
CoInterpreter >> getCodeCompactionCount [
	<cmacro: '() integerObjectOf(GIV(statCodeCompactionCount))'>
	^self integerObjectOf: statCodeCompactionCount
]

{ #category : #'internal interpreter access' }
CoInterpreter >> getCodeCompactionMSecs [
	<cmacro: '() integerObjectOf((GIV(statCodeCompactionUsecs) + 500) / 1000)'>
	^self integerObjectOf: statCodeCompactionUsecs + 500 // 1000
]

{ #category : #'internal interpreter access' }
CoInterpreter >> getCogCodeSize [
	<cmacro: '() integerObjectOf(GIV(cogCodeSize))'>
	^self integerObjectOf: cogCodeSize
]

{ #category : #'internal interpreter access' }
CoInterpreter >> getCogVMFlags [
	"Answer an array of flags indicating various properties of the Cog VM.
	 Bit 0: implies the image's Process class has threadId as its 3rd inst var (zero relative)
	 Bit 1: if set, methods that are interpreted will have the flag bit set in their header
	 Bit 2: if set, implies preempting a process does not put it to the back of its run queue"
	^self integerObjectOf: (processHasThreadId ifTrue: [1] ifFalse: [0])
						+ (flagInterpretedMethods ifTrue: [2] ifFalse: [0])
						+ (preemptionYields ifTrue: [0] ifFalse: [4])
]

{ #category : #'interpreter shell' }
CoInterpreter >> getCurrentBytecode [
	"currentBytecode will be private to the main dispatch loop in the generated code.
	 This method allows the currentBytecode to be retrieved from global variables.
	 Override to answer -1 if we're not in an interpreter frame."

	^((stackPages couldBeFramePointer: framePointer)
	   and: [(self isMachineCodeFrame: framePointer) not])
		ifTrue: [self byteAt: instructionPointer]
		ifFalse: [-1]
]

{ #category : #'internal interpreter access' }
CoInterpreter >> getDesiredCogCodeSize [
	<cmacro: '() integerObjectOf(desiredCogCodeSize)'>
	^self integerObjectOf: desiredCogCodeSize
]

{ #category : #'image save/restore' }
CoInterpreter >> getImageHeaderFlags [
	"Answer the flags that are contained in the 7th long of the image header."
	^fullScreenFlag "0 or 1"
	+ (VMBIGENDIAN ifTrue: [0] ifFalse: [2]) "this is the imageFloatsLittleEndian flag"
	+ (processHasThreadId ifTrue: [4] ifFalse: [0])
	+ (flagInterpretedMethods ifTrue: [8] ifFalse: [0])
	+ (preemptionYields ifTrue: [0] ifFalse: [16])
	+ (imageHeaderFlags bitAnd: 31 bitInvert32) "these are any flags we do not recognize"
]

{ #category : #allocation }
CoInterpreter >> growObjectMemory: delta [ 
	"Attempt to grow the object memory by the given delta amount."
	| limit |
	statGrowMemory := statGrowMemory + 1.
	limit := self sqGrowMemory: memoryLimit By: delta.
	limit = memoryLimit ifFalse:
		[self setMemoryLimit: limit - 24. "remove a tad for safety"
		 self initializeMemoryFirstFree: freeStart.
		 self sqMakeMemoryNotExecutableFrom: self startOfMemory To: memoryLimit]
]

{ #category : #'message sending' }
CoInterpreter >> handleMNUInMachineCodeTo: rcvr lookupClass: class mayLink: mayLinkBoolean [
	"A message send from either an open PIC or an unlinked send has not
	 been understood.  Load newMethod with the MNU method.  If linking
	 is allowed and the target MNU method is in the cache then create a
	 closed PIC with an mnu-entry and link the send to it.  messageSelector
	 and argumentCount have already been set by the caller."
	self assert: ((self isIntegerObject: rcvr) or: [self addressCouldBeObj: rcvr]).
	instructionPointer := self popStack.
	self createActualMessageTo: class.
	messageSelector := self splObj: SelectorDoesNotUnderstand.
	(self lookupInMethodCacheSel: messageSelector class: class)
		ifTrue:"check for coggability because method is in the cache"
			[self
				ifAppropriateCompileToNativeCode: newMethod
				selector: messageSelector]
		ifFalse:
			[(self lookupMethodNoMNUEtcInClass: class) ifFalse:
				[self error: 'Recursive not understood error encountered'].
			 self addNewMethodToCache: class].
	(self methodHasCogMethod: newMethod) ifTrue:
		[mayLinkBoolean ifTrue:
			[self flag: 'implement creating an MNU PIC sometime'.
			 false ifTrue: [self shouldBeImplemented]].
		 self push: instructionPointer.
		 self executeCogMethodFromUnlinkedSend: (self cogMethodOf: newMethod)
			 withReceiver: rcvr
		 "NOTREACHED"].
	self push: instructionPointer.
	^self activateInterpreterMethodFromMachineCode
	"NOTREACHED"
]

{ #category : #'compiled methods' }
CoInterpreter >> headerOf: methodPointer [
	| methodHeader |
	methodHeader := self rawHeaderOf: methodPointer.
	^(self isCogMethodReference: methodHeader)
		ifTrue: [(self cCoerceSimple: methodHeader to: #'CogMethod *') methodHeader]
		ifFalse: [methodHeader]
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
			 cogMethod selector = nilObj ifTrue:
				[cogit setSelectorOf: cogMethod to: selector]]
		ifFalse:
			[(self methodWithHeaderShouldBeCogged: methodHeader)
				ifTrue: [cogit cog: aMethodObj selector: selector]
				ifFalse: [self maybeFlagMethodAsInterpreted: aMethodObj]]
]

{ #category : #'debug support' }
CoInterpreter >> ifValidWriteBackStack: theCFP Pointers: theCSP [
	"This is for low-level error reporting.  If either of the C stack pointers are
	 pointing into the stack zone then write them back to framePointer and/or
	 stackPointer so that the stack backtrace will be up to date."
	<api>
	<var: #theCFP type: #'void *'>
	<var: #theCSP type: #'void *'>
	<returnTypeC: #void>
	(self couldBeFramePointer: theCFP) ifTrue:
		[framePointer := theCFP].
	(self couldBeFramePointer: theCSP) ifTrue:
		[stackPointer := theCSP]
]

{ #category : #'frame access' }
CoInterpreter >> iframeHasContext: theFP [
	"See encodeFrameFieldHasContext:numArgs:"
	<inline: true>
	<var: #theFP type: #'char *'>
	^(stackPages byteAt: theFP + FoxIFrameFlags + 2) ~= 0
]

{ #category : #'frame access' }
CoInterpreter >> iframeInstructionPointerForIndex: ip method: aMethod [
	"Answer the instruction pointer for use in an interpreter frame (a pointer to a bytecode)."
	self assert: (ip between: (self lastPointerOf: aMethod) and: (self lengthOf: aMethod)).
	^aMethod + ip + BaseHeaderSize - 2
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
	stackPages longAt: theFP + FoxIFSavedIP put: savedIP
]

{ #category : #'primitive support' }
CoInterpreter >> initPrimCall [
	"Set the failure code/success flag in preparation for calling a primitve.
	 If primFailCode is non-zero a primitive has failed.  If primFailCode is
	 greater than one then its value indicates the reason for failure. Override
	 to disable the - for the jit - cumbersome stack balance checking code."
	<inline: true>
	primFailCode := 0
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
						cCode: 'alloca(stackPagesBytes)'
						inSmalltalk:
							[stackPages := self stackPagesClass new.
							 stackPages initializeWithByteSize: stackPagesBytes for: self].
	self sqMakeMemoryNotExecutableFrom: self startOfMemory asUnsignedInteger
		To: memoryLimit asUnsignedInteger.
	self sqMakeMemoryNotExecutableFrom: theStackMemory asUnsignedInteger
		To: theStackMemory asUnsignedInteger + stackPagesBytes.
	stackPages
		initializeStack: theStackMemory
		numSlots: stackPagesBytes / BytesPerWord
		pageSize: stackPageBytes / BytesPerWord
		stackLimitOffset: self stackLimitOffset
		stackPageHeadroom: self stackPageHeadroom.

	"Once the stack pages are initialized we can continue to bootstrap the system."
	self loadInitialContext.
	"We're ready for the heartbeat (poll interrupt)"
	self ioInitHeartbeat.
	self initialEnterSmalltalkExecutive.
	^nil
]

{ #category : #initialization }
CoInterpreter >> initialEnterSmalltalkExecutive [
	"Main entry-point into the interpreter at system start-up.
	 In the non-threaded VM this is identical to enterSmalltalkExecutive"
	<cmacro: '() enterSmalltalkExecutiveImplementation()'>
	"Simulation of the setjmp in enterSmalltalkExecutiveImplementation for reentry into interpreter."
	[([self enterSmalltalkExecutiveImplementation]
		on: ReenterInterpreter
		do: [:ex| ex return: ex returnValue]) = 1] whileTrue
]

{ #category : #initialization }
CoInterpreter >> initializeCodeGenerator [
	linkSends := true.
	cogit
		initializeCodeZoneFrom: (self cCode: 'memory' inSmalltalk: [0])
		upTo: (self cCode: 'memory' inSmalltalk: [0]) + cogCodeSize
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
	<var: #thePage type: #'StackPage *'>
	<var: #theFPAbove type: #'char *'>
	<inline: true>
	self assert: offset < MethodIndex.
	self assert: (self isContext: aContext).
	self writeBackHeadFramePointers.
	(self isMarriedOrWidowedContext: aContext) ifFalse:
		[value := self fetchPointer: offset ofObject: aContext.
		 (offset = InstructionPointerIndex
		  and: ["self halt: value hex." (self isIntegerObject: value)
		  and: [value signedIntFromLong < 0]]) ifTrue:
			[value := self internalMustMapMachineCodePC: (self integerValueOf: value)
						context: aContext].
		 ^value].

	(self isWidowedContext: aContext) ifTrue:
		[^self fetchPointer: offset ofObject: aContext].

	spouseFP := self frameOfMarriedContext: aContext.
	offset = SenderIndex ifTrue:
		[^self ensureCallerContext: spouseFP].
	offset = StackPointerIndex ifTrue:
		[self assert: ReceiverIndex + (self stackPointerIndexForFrame: spouseFP) < (self lengthOf: aContext).
		^self integerObjectOf: (self stackPointerIndexForFrame: spouseFP)].
	offset = InstructionPointerIndex ifTrue:
		[| theIP thePage theFPAbove |
		 spouseFP = localFP
			ifTrue: [theIP := self oopForPointer: localIP]
			ifFalse:
				[thePage := stackPages stackPageFor: spouseFP.
				 theFPAbove := self findFrameAbove: spouseFP inPage: thePage.
				 theIP := theFPAbove == 0
							ifTrue: [stackPages longAt: thePage headSP]
							ifFalse:[self oopForPointer: (self frameCallerSavedIP: theFPAbove)]].
		 value := self contextInstructionPointer: theIP frame: spouseFP.
		 value signedIntFromLong < 0 ifTrue:
			[value := self internalMustMapMachineCodePC: (self integerValueOf: value)
							context: aContext].
		 ^value].
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

{ #category : #'message sending' }
CoInterpreter >> internalActivateNewMethod [
	| methodHeader numTemps rcvr errorCode switched |
	<inline: true>

	methodHeader := self rawHeaderOf: newMethod.
	self assert: (self isCogMethodReference: methodHeader) not.
	numTemps := self tempCountOfMethodHeader: methodHeader.

	rcvr := self internalStackValue: argumentCount. "could new rcvr be set at point of send?"

	self internalPush: localIP.
	self internalPush: localFP.
	localFP := localSP.
	self internalPush: newMethod.
	self setMethod: newMethod.
	self internalPush: nilObj. "FxThisContext field"
	self internalPush: (self
						encodeFrameFieldHasContext: false
						isBlock: false
						numArgs: (self argumentCountOfMethodHeader: methodHeader)).
	self internalPush: 0. "FoxIFSavedIP"
	self internalPush: rcvr.

	"Initialize temps..."
	argumentCount + 1 to: numTemps do:
		[:i | self internalPush: nilObj].

	"-1 to account for pre-increment in fetchNextBytecode"
	localIP := self pointerForOop: (self initialPCForHeader: methodHeader method: newMethod) - 1.

	"Pass primitive error code to last temp if method receives it (indicated
	 by an initial long store temp bytecode).  Protect against obsolete values
	 in primFailCode by checking that newMethod actually has a primitive?"
	primFailCode ~= 0 ifTrue:
		[((self methodHeaderHasPrimitive: methodHeader)
		   and: [(self byteAtPointer: localIP + 1) = 129 "long store temp"]) ifTrue:
			[errorCode := self getErrorObjectFromPrimFailCode.
			 self internalStackTopPut: errorCode "nil if primFailCode == 1, or primFailCode"].
		primFailCode := 0].

	self assert: (self frameNumArgs: localFP) == argumentCount.
	self assert: (self frameIsBlockActivation: localFP) not.
	self assert: (self frameHasContext: localFP) not.

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)."
	localSP < stackLimit ifTrue:
		[self externalizeIPandSP.
		 switched := self handleStackOverflowOrEventAllowContextSwitch:
						(self canContextSwitchIfActivating: methodHeader).
		 self returnToExecutive: true postContextSwitch: switched.
		 self internalizeIPandSP]
]

{ #category : #'message sending' }
CoInterpreter >> internalExecuteNewMethod [
	| methodHeader succeeded |
	<inline: true>
	methodHeader := self rawHeaderOf: newMethod.
	(self isCogMethodReference: methodHeader) ifTrue:
		[self externalizeIPandSP.
		 self executeCogMethod: (self cCoerceSimple: methodHeader to: #'CogMethod *').
		 "At least in the simulator control returns here on return."
		 self internalizeIPandSP.
		 ^nil].
	primitiveFunctionPointer ~~ 0 ifTrue:
		[self isPrimitiveFunctionPointerAnIndex ifTrue:
			[^self internalQuickPrimitiveResponse].
		 "slowPrimitiveResponse may of course context-switch.  If so we must reenter the
		  new process appopriately, returning only if we've found an interpreter frame."
		 self externalizeIPandSP.
		 succeeded := self slowPrimitiveResponse.
		 self internalizeIPandSP.
		 succeeded ifTrue:
			[self return: self popStack toExecutive: false.
			 self browserPluginReturnIfNeeded.
			^nil]].
	"if not primitive, or primitive failed, activate the method"
	^self internalActivateNewMethod
]

{ #category : #'message sending' }
CoInterpreter >> internalFindNewMethod [
	"Find the compiled method to be run when the current messageSelector is
	 sent to the given class, setting the values of newMethod and primitiveIndex."
	| ok |
	<inline: true>
	ok := self lookupInMethodCacheSel: messageSelector class: lkupClass.
	ok	ifTrue:
			[self ifAppropriateCompileToNativeCode: newMethod selector: messageSelector]
		ifFalse:
			["entry was not found in the cache; look it up the hard way"
			self externalizeIPandSP.
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
	localFP := self pointerForOop: framePointer
]

{ #category : #'stack pages' }
CoInterpreter >> interpreterAllocationReserveBytes [
	"At a rough approximation we may need to allocate up to a couple
	 of page's worth of contexts when switching stack pages, assigning
	 to senders, etc.  But the snapshot primitive voids all stack pages.
	 So a safe margin is the size of a large context times the maximum
	 number of frames per page times the number of pages."
	| availableBytesPerPage maxFramesPerPage |
	availableBytesPerPage := self stackPageByteSize - self stackLimitOffset - self stackPageHeadroom.
	maxFramesPerPage := availableBytesPerPage / BytesPerWord // MFrameSlots.
	^2 raisedTo: (maxFramesPerPage * LargeContextSize * numStackPages) highBit
]

{ #category : #'internal interpreter access' }
CoInterpreter >> isCog [
	^true
]

{ #category : #'compiled methods' }
CoInterpreter >> isCogMethodReference: methodHeader [
	self assert: ((self isIntegerObject: methodHeader)
				or: [methodHeader asUnsignedInteger < self startOfMemory
					and: [methodHeader asUnsignedInteger >= cogit minCogMethodAddress]]).
	^self isNonIntegerObject: methodHeader
]

{ #category : #'frame access' }
CoInterpreter >> isMachineCodeFrame: theFP [ 
	<var: #theFP type: #'char *'>
	^(stackPages longAt: theFP + FoxMethod) asUnsignedInteger < self startOfMemory
]

{ #category : #'compiled methods' }
CoInterpreter >> isQuickPrimitiveIndex: anInteger [
	<api>
	^anInteger between: 256 and: 519
]

{ #category : #'cog jit support' }
CoInterpreter >> isReallyYoungObject: obj [
	<api>
	"For machien code assertion checking.  Answer true iif not in a fulGC and obj is young."
	^inFullGC not
	   and: [self oop: obj isGreaterThanOrEqualTo: youngStart]
]

{ #category : #'internal interpreter access' }
CoInterpreter >> itemporary: offset in: theFP [
	"Temporary access for an interpreter frame only."
	"See StackInterpreter class>>initializeFrameIndices"
	| frameNumArgs |
	<inline: true>
	<var: #theFP type: #'char *'>
	^offset < (frameNumArgs := self iframeNumArgs: theFP)
		ifTrue: [stackPages longAt: theFP + FoxCallerSavedIP + ((frameNumArgs - offset) * BytesPerWord)]
		ifFalse: [stackPages longAt: theFP + FoxIFReceiver - BytesPerWord + ((frameNumArgs - offset) * BytesPerWord)]
]

{ #category : #'internal interpreter access' }
CoInterpreter >> itemporary: offset in: theFP put: valueOop [
	"Temporary access for an interpreter frame only."
	"See StackInterpreter class>>initializeFrameIndices"
	| frameNumArgs |
	<inline: true>
	<var: #theFP type: #'char *'>
	offset < (frameNumArgs := self iframeNumArgs: theFP)
		ifTrue: [stackPages longAt: theFP + FoxCallerSavedIP + ((frameNumArgs - offset) * BytesPerWord) put: valueOop]
		ifFalse: [stackPages longAt: theFP + FoxIFReceiver - BytesPerWord + ((frameNumArgs - offset) * BytesPerWord) put: valueOop]
]

{ #category : #'object enumeration' }
CoInterpreter >> lastPointerOf: oop [ 
	"Return the byte offset of the last pointer field of the given object.  
	 Can be used even when the type bits are not correct.
	 Works with CompiledMethods, as well as ordinary objects.
	 Override to handle hidden pointer to CogMethod in a CompiledMethod header field."
	| fmt methodHeader header contextSize |
	<inline: true>
	<asmLabel: false>
	header := self baseHeader: oop.
	fmt := self formatOfHeader: header.
	fmt <= 4 ifTrue:
		[(fmt = 3
		  and: [self isContextHeader: header]) ifTrue:
			["contexts end at the stack pointer"
			contextSize := self fetchStackPointerOf: oop.
			^CtxtTempFrameStart + contextSize * BytesPerWord].
		^(self sizeBitsOfSafe: oop) - BaseHeaderSize  "all pointers"].
	fmt < 12 ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes; may have an associated CogMethod"
	methodHeader := self longAt: oop + BaseHeaderSize.
	(self isCogMethodReference: methodHeader) ifTrue:
		[methodHeader := (self cCoerceSimple: methodHeader to: #'CogMethod *') methodHeader].
	^(self literalCountOfHeader:methodHeader) * BytesPerWord + BaseHeaderSize
]

{ #category : #'object enumeration' }
CoInterpreter >> lastPointerOf: oop recordWeakRoot: recordWeakRoot [ "<Boolean>"
	"Return the byte offset of the last pointer field of the given object.  
	 Works with CompiledMethods, as well as ordinary objects. 
	 Can be used even when the type bits are not correct.
	 This is a version of lastPointerOf: for markAndTrace:.
	 Already overridden to trace stack pages for the StackInterpreter.
	 Override to handle hidden pointer to CogMethod in a
	 CompiledMethod header field."
	| fmt sz header contextSize methodHeader |
	<inline: true>
	<asmLabel: false>
	header := self baseHeader: oop.
	fmt := self formatOfHeader: header.
	fmt <= 4 ifTrue:
		[fmt >= 3 ifTrue:
			[fmt = 4 ifTrue:
				[recordWeakRoot ifTrue:
					["And remember as weak root"
					 weakRootCount := weakRootCount + 1.
					 self assert: weakRootCount <= WeakRootTableSize.
					 weakRoots at: weakRootCount put: oop].
				"Do not trace the object's indexed fields if it's a weak class"
				^(self nonWeakFieldsOf: oop) << ShiftForWord].
			"So fmt is 3"
			(self isContextHeader: header) ifTrue:
				[self setTraceFlagOnContextsFramesPageIfNeeded: oop.
				 "contexts end at the stack pointer avoiding having to init fields beyond it"
				 contextSize := self fetchStackPointerOf: oop.
				 self assert: ReceiverIndex + contextSize < (self lengthOf: oop baseHeader: header format: fmt).
				 ^CtxtTempFrameStart + contextSize * BytesPerWord]].
		 sz := self sizeBitsOfSafe: oop.
		 ^sz - BaseHeaderSize  "all pointers" ].
	fmt < 12 ifTrue: [^0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes; may have an associated CogMethod"
	methodHeader := self longAt: oop + BaseHeaderSize.
	(self isCogMethodReference: methodHeader) ifTrue:
		[self assert: (self cCoerceSimple: methodHeader to: #'CogMethod *') cmType = CMMethod.
		 methodHeader := (self cCoerceSimple: methodHeader to: #'CogMethod *') methodHeader].
	^(self literalCountOfHeader: methodHeader) * BytesPerWord + BaseHeaderSize
]

{ #category : #'gc -- compaction' }
CoInterpreter >> lastPointerWhileForwarding: oop [ 
	"The given object may have its header word in a forwarding block. Find  
	 the offset of the last pointer in the object in spite of this obstacle."
	| header fmt size methodHeader contextSize |
	<inline: true>
	header := self headerWhileForwardingOf: oop.
	fmt := self formatOfHeader: header.
	fmt <= 4 ifTrue:
		[(fmt = 3
		  and: [self isContextHeader: header]) ifTrue:
			["contexts end at the stack pointer"
			 contextSize := self nacFetchStackPointerOf: oop.
			 self assert: ReceiverIndex + contextSize < (self lengthOf: oop baseHeader: header format: fmt).
			 ^CtxtTempFrameStart + contextSize * BytesPerWord].
		 "do sizeBitsOf: using the header we obtained"
		 size := (header bitAnd: TypeMask) = HeaderTypeSizeAndClass
					ifTrue: [(self sizeHeader: oop) bitAnd: AllButTypeMask]
					ifFalse: [header bitAnd: SizeMask].
		 ^size - BaseHeaderSize].
	fmt < 12 ifTrue: [^0]. "no pointers"
	methodHeader := self longAt: oop + BaseHeaderSize.
	(self isCogMethodReference: methodHeader) ifTrue:
		[methodHeader := (self cCoerceSimple: methodHeader to: #'CogMethod *') methodHeader].
	^(self literalCountOfHeader: methodHeader) * BytesPerWord + BaseHeaderSize
]

{ #category : #'debug support' }
CoInterpreter >> linkSends: aBoolean [
	linkSends := aBoolean
]

{ #category : #'cog jit support' }
CoInterpreter >> long: aJumpBuf jmp: returnValue [
	"Hack simulation of setjmp/longjmp.
	 Signal the exception that simulates a longjmp back to the interpreter." 
	<doNotGenerate>
	aJumpBuf == reenterInterpreter ifTrue:
		[self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: true].
	aJumpBuf returnValue: returnValue; signal
]

{ #category : #'jump bytecodes' }
CoInterpreter >> longUnconditionalJump [
	| offset switched |
	offset := (((currentBytecode bitAnd: 7) - 4) * 256) + self fetchByte.
	localIP := localIP + offset.
	(offset < 0 "backward jump means we're in a loop; check for possible interrupts"
	 and: [localSP < stackLimit]) ifTrue:
		[self externalizeIPandSP.
		 switched := self checkForEventsMayContextSwitch: true.
		 self returnToExecutive: true postContextSwitch: switched.
		 self browserPluginReturnIfNeeded.
		 self internalizeIPandSP].
	self fetchNextBytecode
]

{ #category : #'cog jit support' }
CoInterpreter >> lookup: selector receiver: rcvr [
	<api>
	"Lookup selector in rcvr, without doing MNU processing, and
	 answer either a method or nil if the message was not understood."
	| class |
	"self printFrame: stackPage headFP WithSP: stackPage headSP"
	"self printStringOf: selector"
	class := self fetchClassOf: rcvr.
	(self lookupInMethodCacheSel: selector class: class) ifFalse:
		[messageSelector := selector.
		 (self lookupMethodNoMNUEtcInClass: class) ifFalse:
			[^nil].
		 self addNewMethodToCache: class].
	^newMethod
]

{ #category : #'frame access' }
CoInterpreter >> makeBaseFrameFor: aContext [ "<Integer>"
	"Marry aContext with the base frame of a new stack page.  Build the base
	 frame to reflect the context's state.  Answer the new page.  Override to
	 hold the caller context in a different place,  In the StackInterpreter we use
	 the caller saved ip, but in the Cog VM caller saved ip is the ceBaseReturn:
	 trampoline.  Simply hold the caller context in the first word of the stack."
	| page pointer theMethod theIP numArgs stackPtrIndex maybeClosure |
	<inline: false>
	<var: #page type: #'StackPage *'>
	<var: #pointer type: #'char *'>
	<returnTypeC: #'StackPage *'>
	self assert: (self isSingleContext: aContext).
	theIP := self fetchPointer: InstructionPointerIndex ofObject: aContext.
	self assert: HasBeenReturnedFromMCPC signedIntFromLong < 0.
	theIP := (self isIntegerObject: theIP)
				ifTrue: [self integerValueOf: theIP]
				ifFalse: [HasBeenReturnedFromMCPC].
	theMethod := self fetchPointer: MethodIndex ofObject: aContext.
	page := self newStackPage.
	"first word on stack is caller context of base frame"
	stackPages
		longAt: (pointer := page baseAddress)
		put: (self fetchPointer: SenderIndex ofObject: aContext).
	"second word is the context itself; needed for cannotReturn processing; see ceBaseReturn:."
	stackPages
		longAt: (pointer := pointer - BytesPerWord)
		put: aContext.
	"If the frame is a closure activation then the closure should be on the stack in
	 the pushed receiver position (closures receiver the value[:value:] messages).
	 Otherwise it should be the receiver proper."
	maybeClosure := (self fetchPointer: ClosureIndex ofObject: aContext).
	maybeClosure ~= nilObj
		ifTrue:
			[numArgs := self argumentCountOfClosure: maybeClosure.
			 stackPages
				longAt: (pointer := pointer - BytesPerWord)
				put: maybeClosure]
		ifFalse:
			[numArgs := self argumentCountOf: theMethod.
			 stackPages
				longAt: (pointer := pointer - BytesPerWord)
				put: (self fetchPointer: ReceiverIndex ofObject: aContext)].
	"Put the arguments on the stack"
	1 to: numArgs do:
		[:i|
		stackPages
			longAt: (pointer := pointer - BytesPerWord)
			put: (self fetchPointer: ReceiverIndex + i ofObject: aContext)].
	"saved caller ip is base return trampoline"
	stackPages
		longAt: (pointer := pointer - BytesPerWord)
		put: cogit ceBaseFrameReturnPC.
	"base frame's saved fp is null"
	stackPages
		longAt: (pointer := pointer - BytesPerWord)
		put: 0.
	"N.B.  Don't set the baseFP, which marks the page as in use, until after
	 ensureMethodIsCogged: and/or instructionPointer:forContext:frame:. These
	 can cause a compiled code compaction which, if marked as in use, will
	 examine this partially initialized page and crash."
	page headFP: pointer.
	theIP signedIntFromLong < 0
		ifTrue:
			["Since we would have to generate a machine-code method to be able to map
			  the native pc anyway we should create a native method and native frame."
			 self ensureMethodIsCogged: theMethod.
			 theMethod := (self cogMethodOf: theMethod) asInteger.
			 maybeClosure ~= nilObj
				ifTrue:
					["If the pc is the special HasBeenReturnedFromMCPC pc set the pc
					  appropriately so that the frame stays in the cannotReturn: state."
					 theIP = HasBeenReturnedFromMCPC signedIntFromLong
						ifTrue:
							[theMethod := (cogit findMethodForStartBcpc: (self startPCOfClosure: maybeClosure)
												inHomeMethod: (self cCoerceSimple: theMethod
																	to: #'CogMethod *')) asInteger.
							 theMethod = 0 ifTrue:
								[self error: 'cannot find machine code block matching closure''s startpc'].
							 theIP := cogit ceCannotResumePC]
						ifFalse:
							[self assert: (theIP signedBitShift: -16) < -1. "See contextInstructionPointer:frame:"
							 theMethod := theMethod - ((theIP signedBitShift: -16) * (cogit sizeof: CogBlockMethod)).
							 theIP := theMethod - theIP signedIntFromShort].
					 stackPages
						longAt: (pointer := pointer - BytesPerWord)
						put: theMethod + MFMethodFlagHasContextFlag + MFMethodFlagIsBlockFlag]
				ifFalse:
					[self assert: (theIP signedBitShift: -16) >= -1.
					 "If the pc is the special HasBeenReturnedFromMCPC pc set the pc
					  appropriately so that the frame stays in the cannotReturn: state."
					 theIP := theIP = HasBeenReturnedFromMCPC signedIntFromLong
								ifTrue: [cogit ceCannotResumePC]
								ifFalse: [theMethod asInteger - theIP].
					 stackPages
						longAt: (pointer := pointer - BytesPerWord)
						put: theMethod + MFMethodFlagHasContextFlag].
			 stackPages
				longAt: (pointer := pointer - BytesPerWord)
				put: aContext]
		ifFalse:
			[stackPages
				longAt: (pointer := pointer - BytesPerWord)
				put: theMethod.
			stackPages
				longAt: (pointer := pointer - BytesPerWord)
				put: aContext.
			stackPages
				longAt: (pointer := pointer - BytesPerWord)
				put: (self encodeFrameFieldHasContext: true isBlock: maybeClosure ~= nilObj numArgs: numArgs).
			stackPages
				longAt: (pointer := pointer - BytesPerWord)
				put: 0. "FoxIFSavedIP"
			theIP := self iframeInstructionPointerForIndex: theIP method: theMethod].
	page baseFP: page headFP.
	self assert: (self frameHasContext: page baseFP).
	self assert: (self frameNumArgs: page baseFP) == numArgs.
	stackPages
		longAt: (pointer := pointer - BytesPerWord)
		put: (self fetchPointer: ReceiverIndex ofObject: aContext).
	stackPtrIndex := self quickFetchInteger: StackPointerIndex ofObject: aContext.
	self assert: ReceiverIndex + stackPtrIndex < (self lengthOf: aContext).
	numArgs + 1 to: stackPtrIndex do:
		[:i|
		stackPages
			longAt: (pointer := pointer - BytesPerWord)
			put: (self fetchPointer: ReceiverIndex + i ofObject: aContext)].
	"top of stack is the instruction pointer"
	stackPages longAt: (pointer := pointer - BytesPerWord) put: theIP.
	self assert: (self fetchPointer: InstructionPointerIndex ofObject: aContext)
			 = (self contextInstructionPointer: theIP frame: page baseFP).
	page headSP: pointer.

	"Mark context as married by setting its sender to the frame pointer plus SmallInteger
	 tags and the InstructionPointer to the saved fp (which ensures correct alignment
	 w.r.t. the frame when we check for validity) plus SmallInteger tags."
	self storePointerUnchecked: SenderIndex
		ofObject: aContext
		withValue: (self withSmallIntegerTags: page baseFP).
	self storePointerUnchecked: InstructionPointerIndex
		ofObject: aContext
		withValue: (self withSmallIntegerTags: 0).
	self assert: (self isIntegerObject: (self fetchPointer: SenderIndex ofObject: aContext)).
	self assert: (self frameOfMarriedContext: aContext) = page baseFP.
	self assert: self validStackPageBaseFrames.
	^page
]

{ #category : #'object memory support' }
CoInterpreter >> mapMachineCode [
	"Update all references to objects in machine code."
	cogit mapObjectReferencesInMachineCode: inFullGC
]

{ #category : #'debug support' }
CoInterpreter >> mapPrimTraceLog [
	"The prim trace log is a circular buffer of selectors. If there is
	 an entry at primTraceLogIndex - 1 \\ PrimTraceBufferSize it has entries.
	 If there is something at primTraceLogIndex it has wrapped."
	<inline: false>
	| limit |
	limit := self safe: primTraceLogIndex - 1 mod: PrimTraceLogSize.
	(primTraceLog at: limit) = 0 ifTrue: [^nil].
	(primTraceLog at: primTraceLogIndex) ~= 0 ifTrue:
		[limit := PrimTraceLogSize - 1].
	0 to: limit do:
		[:i| | selector |
		selector := primTraceLog at: i.
		(self isIntegerObject: selector) ifFalse:
			[primTraceLog at: i put: (self remap: selector)]]
]

{ #category : #'object memory support' }
CoInterpreter >> mapStackPages [
	<inline: false>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #frameRcvrOffset type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #theIPPtr type: #'char *'>
	"Need to write back the frame pointers unless all pages are free (as in snapshot)"
	stackPage ~= 0 ifTrue:
		[self externalWriteBackHeadFramePointers].
	0 to: numStackPages - 1 do:
		[:i| | thePage theSP theFP frameRcvrOffset callerFP theIPPtr theIP oop |
		thePage := stackPages stackPageAt: i.
		thePage isFree ifFalse:
			[theSP := thePage headSP.
			 theFP := thePage  headFP.
			 "Skip the instruction pointer on top of stack of inactive pages."
			 thePage = stackPage
				ifTrue: [theIPPtr := ((self isMachineCodeFrame: theFP)
									or: [(self iframeSavedIP: theFP) = 0])
										ifTrue: [0]
										ifFalse: [theFP + FoxIFSavedIP]]
				ifFalse:
					[theIPPtr := theSP.
					 theSP := theSP + BytesPerWord].
			[self assert: (thePage addressIsInPage: theFP).
			 self assert: (thePage addressIsInPage: theSP).
			 self assert: (theIPPtr = 0 or: [thePage addressIsInPage: theFP]).
			 frameRcvrOffset := self frameReceiverOffset: theFP.
	 		  [theSP <= frameRcvrOffset] whileTrue:
				[oop := stackPages longAt: theSP.
				 (self isIntegerObject: oop) ifFalse:
					[stackPages longAt: theSP put: (self remap: oop)].
				 theSP := theSP + BytesPerWord].
			 (self frameHasContext: theFP) ifTrue:
				[stackPages
					longAt: theFP + FoxThisContext
					put: (self remap: (self frameContext: theFP))].
			(self isMachineCodeFrame: theFP) ifFalse:
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
					put: (self remap: (self iframeMethod: theFP)).
				 theIPPtr ~= 0 ifTrue:
					[stackPages longAt: theIPPtr put: theIP + (self iframeMethod: theFP)]].
			 (callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
				[theSP := (theIPPtr := theFP + FoxCallerSavedIP) + BytesPerWord.
				 theFP := callerFP].
			 theSP := theFP + FoxCallerSavedIP + BytesPerWord.
			 [theSP <= thePage baseAddress] whileTrue:
				[oop := stackPages longAt: theSP.
				 (self isIntegerObject: oop) ifFalse:
					[stackPages longAt: theSP put: (self remap: oop)].
				 theSP := theSP + BytesPerWord]]]
]

{ #category : #'debug support' }
CoInterpreter >> mapTraceLog [
	"The trace log is a circular buffer of pairs of entries. If there is
	 an entry at traceLogIndex - 3 \\ TraceBufferSize it has entries.
	 If there is something at traceLogIndex it has wrapped."
	<inline: false>
	| limit |
	limit := self safe: traceLogIndex - 3 mod: TraceBufferSize.
	(traceLog at: limit) = 0 ifTrue: [^nil].
	(traceLog at: traceLogIndex) ~= 0 ifTrue:
		[limit := TraceBufferSize - 3].
	0 to: limit by: 3 do:
		[:i| | intOrClass selectorOrMethod |
		intOrClass := traceLog at: i.
		(self isIntegerObject: intOrClass) ifFalse:
			[traceLog at: i put: (self remap: intOrClass)].
		selectorOrMethod := traceLog at: i + 1.
		(self isIntegerObject: selectorOrMethod) ifFalse:
			[traceLog at: i + 1 put: (self remap: selectorOrMethod)]]
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
	"Assume: All traced variables contain valid oops."
	| mapInstructionPointer |
	mapInstructionPointer := instructionPointer > method.
	mapInstructionPointer ifTrue:
		[instructionPointer := instructionPointer - method]. "*rel to method"
	self setMethod: (self remap: method).
	mapInstructionPointer ifTrue:
		[instructionPointer := instructionPointer + method]. "*rel to method"
	messageSelector := self remap: messageSelector.
	newMethod := self remap: newMethod.
	lkupClass := self remap: lkupClass
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
	self markAndTrace: homeMethod methodObject
]

{ #category : #'object memory support' }
CoInterpreter >> markAndTraceOrFreeMachineCode: fullGCFlag [
	"Deal with a fulGC's effects on machine code.  Either mark and trace
	 oops in machine code or free machine-code methds that refer to freed
	 oops.  The stack pages have already been traced so any methods
	 of live stack activations have already been marked and traced."
	cogit markAndTraceObjectsOrFreeMachineCode: fullGCFlag
]

{ #category : #'debug support' }
CoInterpreter >> markAndTracePrimTraceLog [
	"The prim trace log is a circular buffer of selectors. If there is
	 an entry at primTraceLogIndex - 1 \\ PrimTraceBufferSize it has entries.
	 If there is something at primTraceLogIndex it has wrapped."
	<inline: false>
	| limit |
	limit := self safe: primTraceLogIndex - 1 mod: PrimTraceLogSize.
	(primTraceLog at: limit) = 0 ifTrue: [^nil].
	(primTraceLog at: primTraceLogIndex) ~= 0 ifTrue:
		[limit := PrimTraceLogSize - 1].
	0 to: limit do:
		[:i| | selector |
		selector := primTraceLog at: i.
		(self isIntegerObject: selector) ifFalse:
			[self markAndTrace: selector]]
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
	theSP := thePage headSP.
	theFP := thePage  headFP.
	"Skip the instruction pointer on top of stack of inactive pages."
	thePage = stackPage ifFalse:
		[theSP := theSP + BytesPerWord].
	[frameRcvrOffset := self frameReceiverOffset: theFP.
	 [theSP <= frameRcvrOffset] whileTrue:
		[oop := stackPages longAt: theSP.
		 (self isIntegerObject: oop) ifFalse:
			[self markAndTrace: oop].
		 theSP := theSP + BytesPerWord].
	(self frameHasContext: theFP) ifTrue:
		[self assert: (self isContext: (self frameContext: theFP)).
		 self markAndTrace: (self frameContext: theFP)].
	(self isMachineCodeFrame: theFP)
		ifTrue: [self markAndTraceMachineCodeMethod: (self mframeCogMethod: theFP)]
		ifFalse: [self markAndTrace: (self iframeMethod: theFP)].
	(callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
		[theSP := theFP + FoxCallerSavedIP + BytesPerWord.
		 theFP := callerFP].
	theSP := self isCog
				ifTrue: [theFP + FoxCallerSavedIP + BytesPerWord] "caller ip is ceBaseReturnPC"
				ifFalse: [theFP + FoxCallerSavedIP]. "caller ip is frameCallerContext in a base frame"
	[theSP <= thePage baseAddress] whileTrue:
		[oop := stackPages longAt: theSP.
		 (self isIntegerObject: oop) ifFalse:
			[self markAndTrace: oop].
		 theSP := theSP + BytesPerWord]
]

{ #category : #'object memory support' }
CoInterpreter >> markAndTraceTraceLog [
	"The trace log is a circular buffer of pairs of entries. If there is an entry at
	 traceLogIndex - 3 \\ TraceBufferSize it has entries.  If there is something at
	 traceLogIndex it has wrapped."
	<inline: false>
	| limit |
	limit := self safe: traceLogIndex - 3 mod: TraceBufferSize.
	(traceLog at: limit) = 0 ifTrue: [^nil].
	(traceLog at: traceLogIndex) ~= 0 ifTrue:
		[limit := TraceBufferSize - 3].
	0 to: limit by: 3 do:
		[:i| | oop |
		oop := traceLog at: i.
		(self isIntegerObject: oop) ifFalse:
			[self markAndTrace: oop].
		oop := traceLog at: i + 1.
		(self isIntegerObject: oop) ifFalse:
			[self markAndTrace: oop]]
]

{ #category : #'frame access' }
CoInterpreter >> markCogMethodsAndReferentsOnPage: thePage [
	<var: #thePage type: #'StackPage *'>
	| theFP callerFP |
	<var: #theFP type: #'char *'>
	<var: #callerFP type: #'char *'>
	<inline: false>
	self assert: (stackPages isFree: thePage) not.
	theFP := thePage headFP.
	"Skip the instruction pointer on top of stack of inactive pages."
	[(self isMachineCodeFrame: theFP) ifTrue:
		[cogit markMethodAndReferents: (self mframeCogMethod: theFP)].
	(callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
		[theFP := callerFP]
]

{ #category : #'frame access' }
CoInterpreter >> marryFrame: theFP SP: theSP [
	"Marry an unmarried frame.  This means creating a spouse context  initialized with
	 a subset of the frame's state (state through the last argument) that references the
	 frame. This is important enough for performance to be worth streamlining.

	Override to set the ``has context'' flag appropriately for both machine code and interpreter frames
	and to streamline the machine code/interpreter differences.."
	| theContext methodFieldOrObj closureOrNil rcvr byteSize numArgs numStack |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #cogMethod type: #'CogMethod *'>
	self assert: (self frameHasContext: theFP) not.
	self assert: (self isBaseFrame: theFP) not. "base frames must aready be married for cannotReturn: processing"

	"Decide how much of the stack to preserve in widowed contexts.  Preserving too much
	 state will potentially hold onto garbage.  Holding onto too little may mean that a dead
	 context isn't informative enough in a debugging situation.  We compromise, retaining
	 only the arguments with no temporaries.  Note that we still set the stack pointer to its
	 current value, but stack contents other than the arguments are nil."
	methodFieldOrObj := self frameMethodField: theFP.
	methodFieldOrObj asUnsignedInteger < self startOfMemory "inline (self isMachineCodeFrame: theFP)"
		ifTrue:
			[| cogMethod |
			 stackPages
				longAt: theFP + FoxMethod
				put: methodFieldOrObj + MFMethodFlagHasContextFlag.
			 cogMethod := self cCoerceSimple: (methodFieldOrObj bitAnd: MFMethodMask) to: #'CogMethod *'.
			 numArgs := cogMethod cmNumArgs.
			 cogMethod cmType = CMMethod
				ifTrue:
					[closureOrNil := nilObj]
				ifFalse:
					[cogMethod := cogit cogHomeMethod: (self cCoerceSimple: cogMethod to: #'CogBlockMethod *').
					 closureOrNil := self frameStackedReceiver: theFP numArgs: numArgs].
			 byteSize := (cogMethod methodHeader bitAnd: LargeContextBit) ~= 0
							ifTrue: [LargeContextSize]
							ifFalse: [SmallContextSize].
			 methodFieldOrObj := cogMethod methodObject.
			 rcvr := self mframeReceiver: theFP.
			 numStack := self stackPointerIndexForMFrame: theFP WithSP: theSP numArgs: numArgs]
		ifFalse:
			[stackPages byteAt: theFP + FoxIFrameFlags + 2 put: 1.
			 numArgs := self iframeNumArgs: theFP.
			 byteSize := ((self headerOf: methodFieldOrObj) bitAnd: LargeContextBit) ~= 0
							ifTrue: [LargeContextSize]
							ifFalse: [SmallContextSize].
			 closureOrNil := (self iframeIsBlockActivation: theFP)
								ifTrue: [self frameStackedReceiver: theFP numArgs: numArgs]
								ifFalse: [nilObj].
			 rcvr := self iframeReceiver: theFP.
			 numStack := self stackPointerIndexForIFrame: theFP WithSP: theSP numArgs: numArgs].
	theContext := self eeInstantiateMethodContextByteSize: byteSize.
	stackPages longAt: theFP + FoxThisContext put: theContext.
	"Mark context as married by setting its sender to the frame pointer plus SmallInteger
	 tags and the InstructionPointer to the saved fp (which ensures correct alignment
	 w.r.t. the frame when we check for validity)"
	self storePointerUnchecked: SenderIndex
		ofObject: theContext
		withValue: (self withSmallIntegerTags: theFP).
	self storePointerUnchecked: InstructionPointerIndex
		ofObject: theContext
		withValue: (self withSmallIntegerTags: (self frameCallerFP: theFP)).
	self storePointerUnchecked: StackPointerIndex
		ofObject: theContext
		withValue: (self integerObjectOf: numStack).
	self storePointerUnchecked: MethodIndex
		ofObject: theContext
		withValue: methodFieldOrObj.
	self storePointerUnchecked: ClosureIndex ofObject: theContext withValue: closureOrNil.
	self storePointerUnchecked: ReceiverIndex
		ofObject: theContext
		withValue: rcvr.
	1 to: numArgs do:
		[:i|
		self storePointerUnchecked: ReceiverIndex + i
			ofObject: theContext
			withValue: (self temporary: i - 1 in: theFP)].
	numArgs + 1 to: numStack do:
		[:i|
		self storePointerUnchecked: ReceiverIndex + i
			ofObject: theContext
			withValue: nilObj].

	self assert: (self frameHasContext: theFP).
	self assert: (self frameOfMarriedContext: theContext) = theFP.
	self assert: numStack + ReceiverIndex < (self lengthOf: theContext).

	^theContext
]

{ #category : #'compiled methods' }
CoInterpreter >> maybeFlagMethodAsInterpreted: aMethod [
	| rawHeader realHeader |
	<api>
	flagInterpretedMethods ifTrue:
		[rawHeader := self rawHeaderOf: aMethod.
		 realHeader := (self isCogMethodReference: rawHeader)
						ifTrue: [(self cCoerceSimple: rawHeader to: #'CogMethod *') methodHeader]
						ifFalse: [rawHeader].
		 realHeader := realHeader bitOr: (self integerObjectOf: 1 << HeaderFlagBitPosition).
		 (self isCogMethodReference: rawHeader)
			ifTrue: [(self cCoerceSimple: rawHeader to: #'CogMethod *') methodHeader: realHeader]
			ifFalse: [self storePointerUnchecked: 0 ofObject: aMethod withValue: realHeader]]
]

{ #category : #'cog jit support' }
CoInterpreter >> messageSelector: oop [
	<doNotGenerate>
	messageSelector := oop
]

{ #category : #'compiled methods' }
CoInterpreter >> method: methodObj withInitialPCHasErrorCode: initialPC [
	<api>
	^(self fetchByte: initialPC ofObject: methodObj) = 129 "long store temp"
]

{ #category : #'cog jit support' }
CoInterpreter >> methodCacheAddress [
	<api>
	<returnTypeC: #'void *'>
	^self cCode: 'GIV(methodCache)' inSmalltalk: [methodCache offset * BytesPerWord]
]

{ #category : #'compiled methods' }
CoInterpreter >> methodHasCogMethod: aMethodOop [
	<api>
	self assert: (self isNonIntegerObject: aMethodOop).
	^self isCogMethodReference: (self rawHeaderOf: aMethodOop)
]

{ #category : #'compiled methods' }
CoInterpreter >> methodShouldBeCogged: aMethodObj [
	<api>
	(self methodWithHeaderShouldBeCogged: (self headerOf: aMethodObj)) ifTrue:
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
	^(self literalCountOfHeader: methodHeader) <= maxLiteralCountForCompile
]

{ #category : #'frame access' }
CoInterpreter >> mframeCogMethod: theFP [
	"Answer the Cog method for a machine code frame.  This may be
	 either a full CogMethod or merely a CogBlockMethod rump header."
	<returnTypeC: #'CogBlockMethod *'>
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
	"Answer the home method for a machine code frame.  From a block frame
	 we find the home method through the objectHeader field which points at it.
	 In both cases we need to strip the isBlock and isContext flags from the pointer."
	<returnTypeC: #'CogMethod *'>
	| methodField |
	methodField := self frameMethodField: theFP.
	(methodField bitAnd: MFMethodFlagIsBlockFlag) ~= 0 ifTrue:
		[methodField := (self cCoerceSimple: (methodField bitAnd: MFMethodMask) to: #'CogMethod *') objectHeader].
	^self cCoerceSimple: (methodField bitAnd: MFMethodMask) to: #'CogMethod *'
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
	^(self mframeCogMethod: theFP) cmNumArgs
]

{ #category : #'frame access' }
CoInterpreter >> mframeReceiver: theFP [
	<inline: true>
	<var: #theFP type: #'char *'>
	^stackPages longAt: theFP + FoxMFReceiver
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
	self assert: (self isContext: (self frameContext: callerFP)).
	theContext := self ensureFrameIsMarried: theFP
					SP: theFP + ((self isMachineCodeFrame: theFP) ifTrue: [FoxMFReceiver] ifFalse: [FoxIFReceiver]).
	stackPages
		longAt: (newSP := newPage baseAddress) put: (self frameContext: callerFP);
		longAt: (newSP := newSP - BytesPerWord) put:  theContext.
	stackedReceiverOffset := self frameStackedReceiverOffset: theFP.
	"First move the data, leaving room for the caller and base frame contexts.  We will fix up frame pointers later."
	theFP + stackedReceiverOffset
		to: oldPage headSP
		by: BytesPerWord negated
		do: [:source|
			newSP := newSP - BytesPerWord.
			stackPages longAt: newSP put: (stackPages longAt: source)].
	"newSP = oldSP + delta => delta = newSP - oldSP"
	delta := newSP - oldPage headSP.
	newFP := newPage baseAddress - stackedReceiverOffset - (2 * BytesPerWord).
	self setHeadFP: oldPage headFP + delta andSP: newSP inPage: newPage.
	newPage baseFP: newFP.
	callerIP := self oopForPointer: (self frameCallerSavedIP: theFP).
	callerIP asUnsignedInteger >= self startOfMemory ifTrue:
		[self iframeSavedIP: callerFP put: callerIP.
		 callerIP := cogit ceReturnToInterpreterPC].
	stackPages longAt: theFP + stackedReceiverOffset put: callerIP.
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
		 self storePointerUnchecked: SenderIndex
			ofObject: theContext
			withValue: (self withSmallIntegerTags: fpInNewPage).
		 self storePointerUnchecked: InstructionPointerIndex
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
	stackPages
		longAt: (offset < (frameNumArgs := self mframeNumArgs: theFP)
					ifTrue: [theFP + FoxCallerSavedIP + ((frameNumArgs - offset) * BytesPerWord)]
					ifFalse: [theFP + FoxMFReceiver - BytesPerWord + ((frameNumArgs - offset) * BytesPerWord)])
		put: valueOop
]

{ #category : #'frame access' }
CoInterpreter >> mustMapMachineCodePC: theIP context: aOnceMarriedContext [
	"Map the native pc theIP into a bytecode pc integer object and answer it.
	 See contextInstructionPointer:frame: for the explanation."
	| maybeClosure methodObj startBcpc bcpc |
	<inline: false>
	theIP = HasBeenReturnedFromMCPC signedIntFromLong ifTrue:
		[^nilObj].
	maybeClosure := self fetchPointer: ClosureIndex ofObject: aOnceMarriedContext.
	methodObj := self fetchPointer: MethodIndex ofObject: aOnceMarriedContext.
	maybeClosure ~= nilObj
		ifTrue: [self assert: (theIP signedBitShift: -16) < -1.
				startBcpc := self startPCOfClosure: maybeClosure]
		ifFalse: [self assert: (theIP signedBitShift: -16) = -1.
				startBcpc := self startPCOfMethod: methodObj].
	self ensureMethodIsCogged: methodObj.
	bcpc := self bytecodePCFor: theIP cogMethod: (self cogMethodOf: methodObj) startBcpc: startBcpc.
	^self integerObjectOf: bcpc + 1
]

{ #category : #'cog jit support' }
CoInterpreter >> newMethod [
	<doNotGenerate>
	^newMethod
]

{ #category : #'cog jit support' }
CoInterpreter >> newMethod: oop [
	<doNotGenerate>
	newMethod := oop
]

{ #category : #'trampoline support' }
CoInterpreter >> newMethodAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: newMethod) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #newMethod in: self]
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
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #nextProfileTick in: self]
]

{ #category : #'indexing primitive support' }
CoInterpreter >> noAtCacheCommonAt: stringy [
	"This code is called if the receiver responds primitively to at:.
	 The cogit can implement at: & at:put: quickly in machine code, and needs a backup
	 that provides error codes.  But it does not want the at cache so it does not have to
	 waste time assigning messageSelector and lkupClass."
	| index rcvr result |
	self initPrimCall.
	rcvr := self stackValue: 1.
	(self isNonIntegerObject: rcvr) ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].
	index := self stackTop.
	"No need to test for large positive integers here.  No object has 1g elements"
	(self isIntegerObject: index) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := self integerValueOf: index.
	result := self stObject: rcvr at: index.
	self successful ifTrue:
		[stringy ifTrue: [result := self characterForAscii: (self integerValueOf: result)].
		^ self pop: argumentCount+1 thenPush: result]
]

{ #category : #'indexing primitive support' }
CoInterpreter >> noAtCacheCommonAtPut: stringy [
	"This code is called if the receiver responds primitively to at:Put:.
	 The cogit can implement at: & at:put: quickly in machine code, and needs a backup
	 that provides error codes.  But it does not want the at cache so it does not have to
	 waste time assigning messageSelector and lkupClass."
	| value index rcvr |
	value := self stackTop.
	self initPrimCall.
	rcvr := self stackValue: 2.
	(self isNonIntegerObject: rcvr) ifFalse:
		[^self primitiveFailFor: PrimErrInappropriate].
	index := self stackValue: 1.
	"No need to test for large positive integers here.  No object has 1g elements"
	(self isIntegerObject: index) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := self integerValueOf: index.
	stringy
		ifTrue: [self stObject: rcvr at: index put: (self asciiOfCharacter: value)]
		ifFalse: [self stObject: rcvr at: index put: value].
	self successful ifTrue:
		[^ self pop: argumentCount+1 thenPush: value]
]

{ #category : #'gc -- compaction' }
CoInterpreter >> nullHeaderForMachineCodeMethod [
	<api>
	^(1 << 12 "CompactClassIndex 1") + HeaderTypeShort
]

{ #category : #'cog jit support' }
CoInterpreter >> objectIsOld: anObject [
	<api>
	^self oop: anObject isLessThan: youngStart
]

{ #category : #'object memory support' }
CoInterpreter >> postGCAction: fullGCFlag [
	"Shrink free memory, signal the gc semaphore and let the Cogit do its post GC thang"
	| freeSizeNow |

	freeSizeNow := self freeSize.
	(freeSizeNow > shrinkThreshold
	 and: [freeSizeNow > growHeadroom]) ifTrue:
		["Attempt to shrink memory after successfully reclaiming lots of memory"
		 self shrinkObjectMemory: freeSizeNow - growHeadroom].

	cogit cogitPostGCAction.

	self signalSemaphoreWithIndex: gcSemaphoreIndex.

	lastCoggableInterpretedBlockMethod := lastUncoggableInterpretedBlockMethod := nil.

	inFullGC := false
]

{ #category : #'object memory support' }
CoInterpreter >> preGCAction: fullGCFlag [
	"Need to write back the frame pointers unless all pages are free (as in snapshot).
	 Need to set inFullGC flag (to avoid passing the flag through a lot of the updating code)"
	stackPage ~= 0 ifTrue:
		[self externalWriteBackHeadFramePointers].

	inFullGC := fullGCFlag.

	cogit recordEventTrace ifTrue:
		[| traceType |
		traceType := fullGCFlag ifTrue: [TraceFullGC] ifFalse: [TraceIncrementalGC].
		self recordTrace: traceType thing: traceType source: 0]
]

{ #category : #'cog jit support' }
CoInterpreter >> primErrTable [
	<api>
	^self splObj: PrimErrTableIndex
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

{ #category : #'cog jit support' }
CoInterpreter >> primTraceLogAddress [
	<api>
	<returnTypeC: #'void *'>
	^self cCode: [primTraceLog] inSmalltalk: [primTraceLog offset * BytesPerWord]
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

{ #category : #'control primitives' }
CoInterpreter >> primitiveClosureCopyWithCopiedValues [
	"This is optional old obsolete stuff tedious to implement in Cog because of
	 the need to map from machine code pc to bytecode pc.  So for now just fail."
	self primitiveFail
]

{ #category : #'process primitives' }
CoInterpreter >> primitiveCollectCogCodeConstituents [
	"Answer the contents of the code zone as an array of pair-wise element, address in ascending address order.
	 Answer a string for a runtime routine or abstract label (beginning, end, etc), a CompiledMethod for a CMMethod,
	 or a selector (presumably a Symbol) for a PIC."
	| constituents |
	constituents := cogit cogCodeConstituents.
	constituents isNil ifTrue:
		[^self primitiveFailFor: PrimErrNoMemory].
	self pop: 1 thenPush: constituents
]

{ #category : #'indexing primitives' }
CoInterpreter >> primitiveContextXray [
	"Lift the veil from a context and answer an integer describing its interior state.
	 Used for e.g. VM tests so they can verify they're testing what they think they're testing.
	 0 implies a vanilla heap context.
	 Bit 0 = is or was married to a frame
	 Bit 1 = is still married to a frame
	 Bit 2 = frame is executing machine code
	 Bit 3 = has machine code pc (as opposed to nil or a bytecode pc)
	 Bit 4 = method is currently compiled to machine code"
	| context pc flags theFP theMethod |
	<var: #theFP type: #'char *'>
	context := self stackTop.
	pc := self fetchPointer: InstructionPointerIndex ofObject: context.
	(self isMarriedOrWidowedContext: context)
		ifTrue:
			[(self checkIsStillMarriedContext: context currentFP: framePointer)
				ifTrue: [theFP := self frameOfMarriedContext: context.
						(self isMachineCodeFrame: theFP)
							ifTrue: [flags := 7]
							ifFalse: [flags := 3]]
				ifFalse: [flags := 1]]
		ifFalse:
			[flags := 0].
	((self isIntegerObject: pc)
	 and: [(self integerValueOf: pc) < 0]) ifTrue:
		[flags := flags bitOr: 8].
	theMethod := self fetchPointer: MethodIndex ofObject: context.
	((self isNonIntegerObject: theMethod)
	 and: [(self isCompiledMethod: theMethod)
	 and: [self methodHasCogMethod: theMethod]]) ifTrue:
		[flags := flags bitOr: 16].
	self pop: 1 thenPush: (self integerObjectOf: flags)
]

{ #category : #'process primitives' }
CoInterpreter >> primitiveEnterCriticalSection [
	"Attempt to enter a CriticalSection/Mutex.  If not owned, set the owner to the current
	 process and answer false. If owned by the current process  answer true.   Otherwise
	 suspend the process.  Answer if the receiver is owned by the current process."
	| criticalSection owningProcessIndex owningProcess activeProc inInterpreter |
	criticalSection := self stackTop.  "rcvr"
	owningProcessIndex := ExcessSignalsIndex. "CriticalSections are laid out like Semaphores"
	owningProcess := self fetchPointer: owningProcessIndex ofObject: criticalSection.
	activeProc := self activeProcess.
	owningProcess = nilObj ifTrue:
		[self storePointer: owningProcessIndex
			ofObject: criticalSection
			withValue: activeProc.
		 ^self pop: 1 thenPush: falseObj].
	owningProcess = activeProc ifTrue:
		[^self pop: 1 thenPush: trueObj].
	"Arrange to answer false (unowned) when the process is resumed."
	self pop: 1 thenPush: falseObj.
	"We're going to switch process, either to an interpreted frame or a machine
	 code frame. To know whether to return or enter machine code we have to
	 know from whence we came.  We could have come from the interpreter,
	 either directly or via a machine code primitive.  We could have come from
	 machine code.  The instructionPointer tells us where from:"
	inInterpreter := instructionPointer >= self startOfMemory.
	self addLastLink: activeProc toList: criticalSection.
	self transferTo: self wakeHighestPriority from: CSEnterCriticalSection.
	self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter
]

{ #category : #'process primitives' }
CoInterpreter >> primitiveExitCriticalSection [
	"Exit the critical section.
	 This may change the active process as a result."
	| criticalSection owningProcessIndex inInterpreter owningProcess |
	criticalSection := self stackTop.  "rcvr"
	owningProcessIndex := ExcessSignalsIndex. "CriticalSections are laid out like Semaphores"
	(self isEmptyList: criticalSection)
		ifTrue:
			[self storePointerUnchecked: owningProcessIndex
				ofObject: criticalSection
				withValue: nilObj]
		ifFalse:
			["We're going to switch process, either to an interpreted frame or a machine
			  code frame. To know whether to return or enter machine code we have to
			  know from whence we came.  We could have come from the interpreter,
			  either directly or via a machine code primitive.  We could have come from
			  machine code.  The instructionPointer tells us where from:"
			 inInterpreter := instructionPointer >= self startOfMemory.
			 owningProcess := self removeFirstLinkOfList: criticalSection.
			 "store check unnecessary because aSemaphore referred to owningProcess
			  via its FirstLinkIndex slot before owningProcess was removed."
			 self storePointerUnchecked: owningProcessIndex
				ofObject: criticalSection
				withValue: owningProcess.
			 "Note that resume: isn't fair; it won't suspend the active process.
			  For fairness we must do the equivalent of a primitiveYield, but that
			  may break old code, so we stick with unfair resume:."
			 (self resume: owningProcess
				preemptedYieldingIf: preemptionYields
				from: CSExitCriticalSection) ifTrue:
						[self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter]]
]

{ #category : #'system control primitives' }
CoInterpreter >> primitiveFlushCacheByMethod [
	"The receiver is a compiledMethod.  Clear all entries in the method lookup cache that
	 refer to this method, presumably because it has been redefined, overridden or removed.
	 Override to flush appropriate machine code caches also."
	| probe oldMethod primIdx |
	oldMethod := self stackTop.
	probe := 0.
	1 to: MethodCacheEntries do:
		[:i |
		(methodCache at: probe + MethodCacheMethod) = oldMethod ifTrue:
			[methodCache at: probe + MethodCacheSelector put: 0].
		probe := probe + MethodCacheEntrySize].
	primIdx := self primitiveIndexOf: oldMethod.
	primIdx = PrimitiveExternalCallIndex ifTrue:
		["It's primitiveExternalCall"
		self flushExternalPrimitiveOf: oldMethod].
	(self methodHasCogMethod: oldMethod) ifTrue:
		[cogit unlinkSendsTo: (self cogMethodOf: oldMethod)]
]

{ #category : #'system control primitives' }
CoInterpreter >> primitiveFlushCacheBySelector [
	"The receiver is a message selector.  Clear all entries in the method lookup cache
	 with this selector, presumably because an associated method has been redefined.
	 Override to also flush machine code caches."
	| selector probe |
	selector := self stackTop.
	probe := 0.
	1 to: MethodCacheEntries do:
		[:i | (methodCache at: probe + MethodCacheSelector) = selector ifTrue:
			[methodCache at: probe + MethodCacheSelector put: 0].
		probe := probe + MethodCacheEntrySize].
	(selector = (self specialSelector: 16) "at:"
	 or: [selector = (self specialSelector: 17) "at:put:"]) ifTrue:
		[self flushAtCache].
	cogit unlinkSendsOf: selector
]

{ #category : #'cog jit support' }
CoInterpreter >> primitiveFunctionPointer: oop [
	<doNotGenerate>
	primitiveFunctionPointer := oop
]

{ #category : #'trampoline support' }
CoInterpreter >> primitiveFunctionPointerAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: primitiveFunctionPointer) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #primitiveFunctionPointer in: self]
]

{ #category : #'process primitives' }
CoInterpreter >> primitiveLongRunningPrimitiveSemaphore [
	"Primitive. Install the semaphore to be used for collecting long-running primitives, 
	 or nil if no semaphore should be used."
	| sema flushState activeContext |
	<export: true>
	sema := self stackValue: 0.
	((self isIntegerObject: sema)
	or: [self methodArgumentCount ~= 1]) ifTrue:
		[^self primitiveFail].
	sema = nilObj
		ifTrue:
			[flushState := longRunningPrimitiveCheckSemaphore notNil.
			 longRunningPrimitiveCheckSemaphore := nil]
		ifFalse:
			[flushState := longRunningPrimitiveCheckSemaphore isNil.
			 (self fetchClassOfNonInt: sema) = (self splObj: ClassSemaphore) ifFalse:
				[^self primitiveFail].
			 longRunningPrimitiveCheckSemaphore := sema].
	"If we've switched checking on or off we must void machine code
	 (and machine code pcs in contexts) since we will start or stop setting
	 newMethod in machine code primitive invocations, and so generate
	 slightly different code from here on in."
	flushState ifTrue:
		[self push: instructionPointer.
		 activeContext := self voidVMStateForSnapshot.
		 self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext.
		 self assert: (((self stackValue: 0) = nilObj and: [longRunningPrimitiveCheckSemaphore isNil])
				  or: [(self stackValue: 0) = longRunningPrimitiveCheckSemaphore
					  and: [(self fetchClassOfNonInt: sema) = (self splObj: ClassSemaphore)]])].
	self voidLongRunningPrimitive: 'install'.
	self pop: 1.
	flushState ifTrue:
		[self siglong: reenterInterpreter jmp: 1]
]

{ #category : #'indexing primitives' }
CoInterpreter >> primitiveNoAtCacheAt [

	self noAtCacheCommonAt: false.
]

{ #category : #'indexing primitives' }
CoInterpreter >> primitiveNoAtCacheAtPut [

	self noAtCacheCommonAtPut: false.
]

{ #category : #'indexing primitives' }
CoInterpreter >> primitiveNoAtCacheStringAt [

	self noAtCacheCommonAt: true.
]

{ #category : #'indexing primitives' }
CoInterpreter >> primitiveNoAtCacheStringAtPut [

	self noAtCacheCommonAtPut: true.
]

{ #category : #'object access primitives' }
CoInterpreter >> primitiveObjectAt [
"Defined for CompiledMethods only"
	| thisReceiver rawHeader realHeader index |
	index  := self stackIntegerValue: 0.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	thisReceiver := self stackValue: 1.
	rawHeader := self rawHeaderOf: thisReceiver.
	realHeader := (self isCogMethodReference: rawHeader)
					ifTrue: [(self cCoerceSimple: rawHeader to: #'CogMethod *') methodHeader]
					ifFalse: [rawHeader].
	(index > 0
	 and: [index <= ((self literalCountOfHeader: realHeader) + LiteralStart)]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	self pop: 2
		thenPush: (index = 1
					ifTrue: [realHeader]
					ifFalse: [self fetchPointer: index - 1 ofObject: thisReceiver])
]

{ #category : #'object access primitives' }
CoInterpreter >> primitiveObjectAtPut [
"Defined for CompiledMethods only"
	| thisReceiver rawHeader realHeader index newValue |
	newValue := self stackValue: 0.
	index := self stackIntegerValue: 1.
	self successful ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	thisReceiver := self stackValue: 2.
	rawHeader := self rawHeaderOf: thisReceiver.
	realHeader := (self isCogMethodReference: rawHeader)
					ifTrue: [(self cCoerceSimple: rawHeader to: #'CogMethod *') methodHeader]
					ifFalse: [rawHeader].
	(index > 0
	 and: [index <= ((self literalCountOfHeader: realHeader) + LiteralStart)]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	(index = 1
	 and: [self isCogMethodReference: rawHeader])
		ifTrue: [(self cCoerceSimple: rawHeader to: #'CogMethod *') methodHeader: newValue]
		ifFalse: [self storePointer: index - 1 ofObject: thisReceiver withValue: newValue].
	self pop: 3 thenPush: newValue
]

{ #category : #'process primitives' }
CoInterpreter >> primitiveProfileSemaphore [
	"Primitive. Install the semaphore to be used for profiling, 
	or nil if no semaphore should be used.
	See also primitiveProfileStart."
	| sema flushState activeContext |
	<export: true>
	sema := self stackValue: 0.
	((self isIntegerObject: sema)
	or: [self methodArgumentCount ~= 1]) ifTrue:
		[^self primitiveFail].
	sema = nilObj
		ifTrue:
			[flushState := profileSemaphore ~= nilObj]
		ifFalse:
			[flushState := profileSemaphore = nilObj.
			 (self fetchClassOfNonInt: sema) = (self splObj: ClassSemaphore) ifFalse:
				[^self primitiveFail]].
	profileSemaphore := sema.
	"If we've switched pofiling on or off we must void machine code
	 (and machine code pcs in contexts) since we will start or stop testing
	 the profile clock in machine code primitive invocations, and so generate
	 slightly different code from here on in."
	flushState ifTrue:
		[self push: instructionPointer.
		 activeContext := self voidVMStateForSnapshot.
		 self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext.
		 self assert: (((self stackValue: 0) = nilObj and: [profileSemaphore = nilObj])
				  or: [(self stackValue: 0) = profileSemaphore
					  and: [(self fetchClassOfNonInt: sema) = (self splObj: ClassSemaphore)]])].
	profileProcess := profileMethod := nilObj.
	self pop: 1.
	flushState ifTrue:
		[self siglong: reenterInterpreter jmp: 1]
]

{ #category : #'cog jit support' }
CoInterpreter >> primitivePropertyFlags: primIndex [
	<api>
	"Answer any special requirements of the given primitive"
	| baseFlags functionPointer |
	<var: #functionPointer declareC: 'void (*functionPointer)(void)'>
	functionPointer := self functionPointerFor: primIndex inClass: nil.

	baseFlags := profileSemaphore ~= nilObj
					ifTrue: [PrimCallNeedsNewMethod + PrimCallCollectsProfileSamples]
					ifFalse: [0].

	longRunningPrimitiveCheckSemaphore ~= nil ifTrue:
		[baseFlags := baseFlags bitOr: PrimCallNeedsNewMethod].

		(functionPointer == #primitiveExternalCall asSymbol
	 or: [functionPointer == #primitiveCalloutToFFI asSymbol]) ifTrue: "For callbacks"
		[baseFlags := baseFlags bitOr: PrimCallNeedsNewMethod + PrimCallNeedsPrimitiveFunction + PrimCallMayCallBack].

	^baseFlags
]

{ #category : #'process primitives' }
CoInterpreter >> primitiveResume [
	"Put this process on the scheduler's lists thus allowing it to proceed next time there is
	 a chance for processes of it's priority level.  It must go to the back of its run queue so
	 as not to preempt any already running processes at this level.  If the process's priority
	 is higher than the current process, preempt the current process."
	| proc inInterpreter |
	proc := self stackTop.  "rcvr"
	(self isContext: (self fetchPointer: SuspendedContextIndex ofObject: proc)) ifFalse:
		[^self primitiveFail].
	"We're about to switch process, either to an interpreted frame or a
	 machine code frame. To know whether to return or enter machine code
	 we have to know from whence we came.  We could have come from the
	 interpreter, either directly or via a machine code primitive.  We could have
	 come from machine code.  The instructionPointer tells us where from:"
	inInterpreter := instructionPointer >= self startOfMemory.
	(self resume: proc  preemptedYieldingIf: preemptionYields from: CSResume) ifTrue:
		[self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter]
]

{ #category : #'process primitives' }
CoInterpreter >> primitiveSignal [
	"Synchronously signal the semaphore.
	 This may change the active process as a result."
	| inInterpreter |
	"We may be about to switch process, either to an interpreted frame or a
	 machine code frame. To know whether to return or enter machine code
	 we have to know from whence we came.  We could have come from the
	 interpreter, either directly or via a machine code primitive.  We could have
	 come from machine code.  The instructionPointer tells us where from:"
	inInterpreter := instructionPointer >= self startOfMemory.
	(self synchronousSignal: self stackTop) ifTrue:
		[self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter]
]

{ #category : #'system control primitives' }
CoInterpreter >> primitiveSnapshot [
	"Save a normal snapshot under the same name as it was loaded
	 unless it has been renamed by the last primitiveImageName.

	 Override to jump to the interpreter because the machine code zone is now void."
	<inline: false>
	self snapshot: false.
	self siglong: reenterInterpreter jmp: 1.
	"NOTREACHED"
	^0
]

{ #category : #'system control primitives' }
CoInterpreter >> primitiveSnapshotEmbedded [
	"Save an embedded snapshot.

	 Override to jump to the interpreter because the machine code zone is now void."
	<inline: false>
	self snapshot: true.
	self siglong: reenterInterpreter jmp: 1.
	"NOTREACHED"
	^0
]

{ #category : #'process primitives' }
CoInterpreter >> primitiveSuspend [
	"Primitive. Suspend the receiver, aProcess such that it can be executed again
	by sending #resume. If the given process is not currently running, take it off
	its corresponding list. The primitive returns the list the receiver was previously on."
	| process myList |
	process := self stackTop.
	process = self activeProcess ifTrue:
		[| inInterpreter |
		"We're going to switch process, either to an interpreted frame or a machine
		 code frame. To know whether to return or enter machine code we have to
		 know from whence we came.  We could have come from the interpreter,
		 either directly or via a machine code primitive.  We could have come from
		 machine code.  The instructionPointer tells us where from:"
		self pop: 1 thenPush: nilObj.
		inInterpreter := instructionPointer >= self startOfMemory.
		self transferTo: self wakeHighestPriority from: CSSuspend.
		^self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter].
	myList := self fetchPointer: MyListIndex ofObject: process.
	"XXXX Fixme. We should really check whether myList is a kind of LinkedList or not
	but we can't easily so just do a quick check for nil which is the most common case."
	myList = nilObj ifTrue:[^self primitiveFail].
	self removeProcess: process fromList: myList.
	self successful ifTrue:
		[self storePointer: MyListIndex ofObject: process withValue: nilObj.
		 self pop: 1 thenPush: myList]
]

{ #category : #'control primitives' }
CoInterpreter >> primitiveTerminateTo [
	"Primitive. Terminate up the context stack from the receiver up to but not including
	 the argument, if previousContext is on my Context stack. Make previousContext my
	 sender. This prim has to shadow the code in ContextPart>terminateTo: to be correct.

	 Override to ensure the caller's saved ip is correct, i.e. if an interpreter frame it may
	 have to move to iframeSavedIP."
	| thisCtx currentCtx aContextOrNil contextsFP contextsSP contextsIP nextCntx stackedReceiverOffset 
	  theFP newFP newSP pageToStopOn thePage frameAbove |
	<var: #contextsFP type: #'char *'>
	<var: #theFP type: #'char *'>
	<var: #newFP type: #'char *'>
	<var: #newSP type: #'char *'>
	<var: #contextsIP type: #usqInt>
	<var: #frameAbove type: #'char *'>
	<var: #contextsSP type: #'char *'>
	<var: #source type: #'char *'>
	<var: #pageToStopOn type: #'StackPage *'>
	<var: #thePage type: #'StackPage *'>

	aContextOrNil := self stackTop.
	(aContextOrNil = nilObj or: [self isContext: aContextOrNil]) ifFalse:
		[^self primitiveFail].
	thisCtx := self stackValue: 1.
	thisCtx = aContextOrNil ifTrue:
		[^self primitiveFail].		

	"All stackPages need to have current head pointers to avoid confusion."
	self externalWriteBackHeadFramePointers.

	"If we're searching for aContextOrNil it might be on a stack page.  Helps to know
	 if we can free a whole page or not, or if we can short-cut the termination."
	(aContextOrNil ~= nilObj and: [self isStillMarriedContext: aContextOrNil])
		ifTrue: [contextsFP := self frameOfMarriedContext: aContextOrNil.
				pageToStopOn := stackPages stackPageFor: contextsFP]
		ifFalse: [pageToStopOn := 0].

	"if thisCtx is married ensure it is a base frame.  Then we can assign its sender."
	(self isStillMarriedContext: thisCtx)
		ifTrue:
			[theFP := self frameOfMarriedContext: thisCtx.
			 "Optimize terminating thisContext.  Move its frame down to be next to
			  aContextOrNil's frame. Common in the exception system and so helps to be fast."
			 (theFP = framePointer
			  and: [pageToStopOn = stackPage]) ifTrue:
				[(self frameCallerFP: theFP) ~= contextsFP ifTrue:
					[stackedReceiverOffset := self frameStackedReceiverOffset: theFP.
					 frameAbove := self findFrameAbove: contextsFP inPage: pageToStopOn.
					 contextsIP := (self frameCallerSavedIP: frameAbove) asUnsignedInteger.
					 self assert: ((contextsIP asUnsignedInteger >= self startOfMemory)
								or: [contextsIP = cogit ceReturnToInterpreterPC]) == (self isMachineCodeFrame: contextsFP) not.
					 newSP := self frameCallerSP: frameAbove.
					 newFP := newSP - stackedReceiverOffset - BytesPerWord.
					 theFP + stackedReceiverOffset
						to: stackPointer
						by: BytesPerWord negated
						do: [:source|
							newSP := newSP - BytesPerWord.
							stackPages longAt: newSP put: (stackPages longAt: source)].
					 stackPages longAt: newFP + FoxSavedFP put: contextsFP.
					"Ensure contract between machine-code callee and interpreter caller frames is preserved.
					 Return pc needs to be ceReturnToInterpreterPC."
					 ((self isMachineCodeFrame: newFP)
					  and: [contextsIP >= self startOfMemory]) ifTrue:
						[self iframeSavedIP: contextsFP put: contextsIP.
						 contextsIP := cogit ceReturnToInterpreterPC].
					 stackPages longAt: newFP + FoxCallerSavedIP put: contextsIP.
					 self assert: (self isContext: thisCtx).
					 self storePointerUnchecked: SenderIndex
						ofObject: thisCtx
						withValue: (self withSmallIntegerTags: newFP).
					 self storePointerUnchecked: InstructionPointerIndex
						ofObject: thisCtx
						withValue: (self withSmallIntegerTags: contextsFP).
					 framePointer := newFP.
					 stackPointer := newSP].
				self pop: 1.
				self assert: stackPage = stackPages mostRecentlyUsedPage.
				^nil].
			 theFP := self externalEnsureIsBaseFrame: theFP. "May cause a GC!!"
			 currentCtx := self frameCallerContext: theFP.
			 "May also reclaim aContextOrNil's page, hence..."
			 (aContextOrNil ~= nilObj and: [self isStillMarriedContext: aContextOrNil])
				ifTrue: [contextsFP := self frameOfMarriedContext: aContextOrNil.
						pageToStopOn := stackPages stackPageFor: contextsFP]
				ifFalse: [pageToStopOn := 0]]
		ifFalse:
			[currentCtx := self fetchPointer: SenderIndex ofObject: thisCtx].

	(self context: thisCtx hasSender: aContextOrNil) ifTrue:
		["Need to walk the stack freeing stack pages and nilling contexts."
		[currentCtx = aContextOrNil
		 or: [currentCtx = nilObj]] whileFalse:
			[(self isMarriedOrWidowedContext: currentCtx)
				ifTrue:
					[theFP := self frameOfMarriedContext: currentCtx.
					thePage := stackPages stackPageFor: theFP.
					"If externalEnsureIsBaseFrame: above has moved thisContext to its own stack
					 then we will always terminate to a frame on a different page.  But if we are
					 terminating some other context to a context somewhere on the current page
					 we must save the active frames above that context.  Things will look e.g. like this:
		thisCtx			499383332 s MethodContext(ContextPart)>resume:
						499380484 s BlockClosure>ensure:
						499377320 s MethodContext(ContextPart)>handleSignal:
						499373760 s MethodContext(ContextPart)>handleSignal:
						499372772 s MessageNotUnderstood(Exception)>signal
						499369068 s CodeSimulationTests(Object)>doesNotUnderstand: absentMethod
						499368708 s [] in CodeSimulationTests>testDNU
							(sender is 0xbffc2480 I CodeSimulationTests>runSimulated:)
						------------
		framePointer	0xbffc234c M MethodContext(ContextPart)>doPrimitive:method:receiver:args:
						0xbffc2378 M MethodContext(ContextPart)>tryPrimitiveFor:receiver:args:
						0xbffc23ac M MethodContext(ContextPart)>send:to:with:super:
						0xbffc23e4 M MethodContext(ContextPart)>send:super:numArgs:
						0xbffc2418 M MethodContext(InstructionStream)>interpretNextInstructionFor:
						0xbffc2434 M MethodContext(ContextPart)>step
						0xbffc2458 I MethodContext(ContextPart)>runSimulated:contextAtEachStep:
						------------
(499368708's sender)	0xbffc2480 I CodeSimulationTests>runSimulated:
						0xbffc249c M CodeSimulationTests>testDNU
						0xbffc24bc I CodeSimulationTests(TestCase)>performTest
						0xbffc24dc I [] in CodeSimulationTests(TestCase)>runCase
		aContextOrNil	0xbffc24fc M BlockClosure>ensure:
						0xbffc2520 I CodeSimulationTests(TestCase)>runCase
						0xbffc253c M [] in TestResult>runCase:
					When we find this case we move the frames above to a new page by making the
					frame above currentCtx a base frame, i.e. making 0xbffc2458 in the above example
					a base frame.  But in this iteration of the loop we don't move down a frame i.e. currentCtx
					doesn't change on this iteration."
					thePage = stackPage
						ifTrue:
							[frameAbove := self findFrameAbove: theFP inPage: thePage.
							self assert: frameAbove ~= 0.
							frameAbove := self externalEnsureIsBaseFrame: frameAbove. "May cause a GC!! May also reclaim aContextOrNil's page, hence..."
							(aContextOrNil ~= nilObj and: [self isStillMarriedContext: aContextOrNil])
								ifTrue: [contextsFP := self frameOfMarriedContext: aContextOrNil.
										pageToStopOn := stackPages stackPageFor: contextsFP]
								ifFalse: [pageToStopOn := 0]]
						ifFalse:
							[thePage = pageToStopOn
								ifTrue:
									["We're here.  Cut back the stack to aContextOrNil's frame,
									  push its instructionPointer if it's not already a head frame,
									  and we're done."
									 frameAbove := self findFrameAbove: contextsFP inPage: thePage.
									 frameAbove ~= 0 ifTrue:
										[contextsSP := (self frameCallerSP: frameAbove) - BytesPerWord.
										 stackPages longAt: contextsSP put: (self frameCallerSavedIP: frameAbove).
										 self setHeadFP: contextsFP andSP: contextsSP inPage: thePage].
									 currentCtx := aContextOrNil]
								ifFalse:
									["We can free the entire page without further ado."
									 currentCtx := self frameCallerContext: thePage baseFP.
									 "for a short time invariant is violated; assert follows"
									 stackPages freeStackPageNoAssert: thePage]]]
				ifFalse:
					[self assert: (self isContext: currentCtx).
					 nextCntx := self fetchPointer: SenderIndex ofObject: currentCtx.
					 self storePointerUnchecked: SenderIndex ofObject: currentCtx withValue: nilObj.
					 self storePointerUnchecked: InstructionPointerIndex ofObject: currentCtx withValue: nilObj.
					 currentCtx := nextCntx]]].
	self assert: stackPages pageListIsWellFormed.
	(self isMarriedOrWidowedContext: thisCtx)
		ifTrue:
			[self assert: (self checkIsStillMarriedContext: thisCtx currentFP: framePointer).
			 self assert: (self isBaseFrame: (self frameOfMarriedContext: thisCtx)).
			 theFP := self frameOfMarriedContext: thisCtx.
			 self frameCallerContext: theFP put: aContextOrNil]
		ifFalse: [self storePointer: SenderIndex ofObject: thisCtx withValue: aContextOrNil].
	self pop: 1.
	self assert: stackPage = stackPages mostRecentlyUsedPage.
	^nil
]

{ #category : #'system control primitives' }
CoInterpreter >> primitiveVoidVMState [
	"Void all internal VM state in the stack and machine code zones

	 Override to jump to the interpreter because the machine code zone is now void."
	| activeContext |

	self push: instructionPointer.
	activeContext := self voidVMStateForSnapshot.
	self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext.
	self siglong: reenterInterpreter jmp: 1.
	"NOTREACHED"
	^0
]

{ #category : #'process primitives' }
CoInterpreter >> primitiveWait [
	| sema excessSignals activeProc inInterpreter |
	sema := self stackTop.  "rcvr"
	excessSignals := self fetchInteger: ExcessSignalsIndex ofObject: sema.
	excessSignals > 0
		ifTrue:
			[self storeInteger: ExcessSignalsIndex
				ofObject: sema
				withValue: excessSignals - 1]
		ifFalse:
			["We're going to switch process, either to an interpreted frame or a machine
			  code frame. To know whether to return or enter machine code we have to
			  know from whence we came.  We could have come from the interpreter,
			  either directly or via a machine code primitive.  We could have come from
			  machine code.  The instructionPointer tells us where from:"
			inInterpreter := instructionPointer >= self startOfMemory.
			activeProc := self activeProcess.
			self addLastLink: activeProc toList: sema.
			self transferTo: self wakeHighestPriority from: CSWait.
			self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter]
]

{ #category : #'process primitives' }
CoInterpreter >> primitiveYield [
"primitively do the equivalent of Process>yield"
	| activeProc priority processLists processList inInterpreter |
	activeProc := self activeProcess.
	priority := self quickFetchInteger: PriorityIndex ofObject: activeProc.
	processLists := self fetchPointer: ProcessListsIndex ofObject: self schedulerPointer.
	processList := self fetchPointer: priority - 1 ofObject: processLists.

	(self isEmptyList: processList) ifTrue:
		[^nil].
	"We're going to switch process, either to an interpreted frame or a machine
	 code frame. To know whether to return or enter machine code we have to
	 know from whence we came.  We could have come from the interpreter,
	 either directly or via a machine code primitive.  We could have come from
	 machine code.  The instructionPointer tells us where from:"
	inInterpreter := instructionPointer >= self startOfMemory.
	self addLastLink: activeProc toList: processList.
	self transferTo: self wakeHighestPriority from: CSYield.
	self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter
]

{ #category : #'debug printing' }
CoInterpreter >> printCogMethod: cogMethod [
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	| address |
	self cCode: ''
		inSmalltalk:
			[cogMethod isInteger ifTrue:
				[^self printCogMethod: (self cCoerceSimple: cogMethod to: #'CogMethod *')]].
	address := cogMethod asInteger.
	self printHex: address;
		print: ' <-> ';
		printHex: address + cogMethod blockSize.
	cogMethod cmType = CMMethod ifTrue:
		[self print: ': method: ';
			printHex: cogMethod methodObject].
	cogMethod cmType = CMBlock ifTrue:
		[self print: ': block home: ';
			printHex: cogMethod objectHeader].
	cogMethod cmType = CMClosedPIC ifTrue:
		[self print: ': Closed PIC N: ';
			printHex: cogMethod cPICNumCases].
	cogMethod cmType = CMOpenPIC ifTrue:
		[self print: ': Open PIC '].
	self print: ' selector: ';
		printHex: cogMethod selector;
		print: ' ';
		printStringOf: cogMethod selector;
		cr
]

{ #category : #'debug printing' }
CoInterpreter >> printFrame: theFP [
	| thePage theSP |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	<var: #theSP type: #'char *'>
	theFP = framePointer
		ifTrue: [theSP := stackPointer]
		ifFalse:
			[thePage := stackPages stackPageFor: theFP.
			 (stackPages isFree: thePage) ifTrue:
				[self printHexPtr: theFP; print: ' is on a free page?!'; cr.
				 ^nil].
			 theSP := self findSPOrNilOf: theFP
						on: thePage
						startingFrom: ((thePage = stackPage
									and: [framePointer < thePage headFP])
										ifTrue: [framePointer]
										ifFalse: [thePage headFP])].
	theSP isNil ifTrue:
		[self print: 'could not find sp; using bogus value'; cr.
		 theSP := theFP + ((self isMachineCodeFrame: theFP)
								ifTrue: [FoxMFReceiver]
								ifFalse: [FoxIFReceiver])].
	self printFrame: theFP WithSP: theSP
]

{ #category : #'debug printing' }
CoInterpreter >> printFrame: theFP WithSP: theSP [
	| theMethod theMethodEnd numArgs numTemps rcvrAddress topThing |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #addr type: #'char *'>
	<var: #rcvrAddress type: #'char *'>
	<var: #cogMethod type: #'CogBlockMethod *'>
	<var: #homeMethod type: #'CogMethod *'>
	(self isMachineCodeFrame: theFP)
		ifTrue:
			[| cogMethod homeMethod |
			 cogMethod := self mframeCogMethod: theFP.
			 homeMethod := self mframeHomeMethod: theFP.
			 theMethod := homeMethod asInteger.
			 theMethodEnd := homeMethod asInteger + homeMethod blockSize.
			 numArgs := cogMethod cmNumArgs.
			 numTemps := self tempCountOfMethodHeader: homeMethod methodHeader]
		ifFalse:
			[theMethod := self frameMethodObject: theFP.
			 theMethodEnd := theMethod + (self sizeBitsOfSafe: theMethod).
			 numArgs := self iframeNumArgs: theFP.
			 numTemps := self tempCountOf: theMethod].
	(self frameIsBlockActivation: theFP) ifTrue:
		[| rcvrOrClosure |
		 rcvrOrClosure := self pushedReceiverOrClosureOfFrame: theFP.
		 ((self isNonIntegerObject: rcvrOrClosure)
		 and: [(self addressCouldBeObj: rcvrOrClosure)
		 and: [(self fetchClassOfNonInt: rcvrOrClosure) = (self splObj: ClassBlockClosure)]])
			ifTrue: [numTemps := numArgs + (self stSizeOf: rcvrOrClosure)]
			ifFalse: [numTemps := 0]].
	self shortPrintFrame: theFP.
	(self isBaseFrame: theFP) ifTrue:
		[self printFrameOop: '(caller ctxt'
			at: theFP + (self frameStackedReceiverOffset: theFP) + (2 * BytesPerWord).
		 self printFrameOop: '(saved ctxt'
			at: theFP + (self frameStackedReceiverOffset: theFP) + (1 * BytesPerWord)].
	self printFrameOop: 'rcvr/clsr'
		at: theFP + FoxCallerSavedIP + ((numArgs + 1) * BytesPerWord).
	numArgs to: 1 by: -1 do:
		[:i|
		self printFrameOop: 'arg' index: (numArgs + 1 - i) at: theFP + FoxCallerSavedIP + (i * BytesPerWord)].
	self printFrameThing: 'caller ip' at: theFP + FoxCallerSavedIP.
	self printFrameThing: 'saved fp' at: theFP + FoxSavedFP.
	self printFrameMethodFor: theFP.
	(self isMachineCodeFrame: theFP) ifFalse:
		[self printFrameFlagsForFP: theFP].
	self printFrameThing: 'context' at: theFP + FoxThisContext.
	(self isMachineCodeFrame: theFP) ifTrue:
		[self printFrameFlagsForFP: theFP].
	(self isMachineCodeFrame: theFP)
		ifTrue: [rcvrAddress := theFP + FoxMFReceiver]
		ifFalse:
			[self printFrameThing: 'saved ip'
				at: theFP + FoxIFSavedIP
				extra: ((self iframeSavedIP: theFP) = 0
							ifTrue: [0]
							ifFalse: [(self iframeSavedIP: theFP) - theMethod + 2 - BaseHeaderSize]).
			 rcvrAddress := theFP + FoxIFReceiver].
	self printFrameOop: 'receiver' at: rcvrAddress.
	topThing := stackPages longAt: theSP.
	(topThing between: theMethod and: theMethodEnd)
		ifTrue:
			[rcvrAddress - BytesPerWord to: theSP + BytesPerWord by: BytesPerWord negated do:
				[:addr| | index |
				index := rcvrAddress - addr / BytesPerWord + numArgs.
				index <= numTemps
					ifTrue: [self printFrameOop: 'temp' index: index at: addr]
					ifFalse: [self printFrameOop: 'stck' at: addr]].
			self printFrameThing: 'frame ip'
				at: theSP
				extra: ((self isMachineCodeFrame: theFP)
						ifTrue: [topThing - theMethod]
						ifFalse: [topThing - theMethod + 2 - BaseHeaderSize])]
		ifFalse:
			[rcvrAddress - BytesPerWord to: theSP by: BytesPerWord negated do:
				[:addr| | index |
				index := rcvrAddress - addr / BytesPerWord + numArgs.
				index <= numTemps
					ifTrue: [self printFrameOop: 'temp' index: index at: addr]
					ifFalse: [self printFrameOop: 'stck' at: addr]]]
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
		print: '  hasContext: '; printNum: (self frameHasContext: theFP);
		print: '  isBlock: '; printNum: (self frameIsBlockActivation: theFP);
		cr
]

{ #category : #'debug printing' }
CoInterpreter >> printFrameMethodFor: theFP [
	| address it homeMethod obj |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #address type: #'char *'>
	<var: #cogMethod type: #'CogBlockMethod *'>
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
	self printHex: obj; space; shortPrintOop: obj
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
		 it = nilObj
			ifTrue: [self print: 'nil']
			ifFalse:
				[self printNum: it]].
	self space; printNum: extraValue; cr
]

{ #category : #'debug support' }
CoInterpreter >> printLogEntryAt: i [
	<inline: false>
	| intOrClass selectorOrMethod source |
	intOrClass := traceLog at: i.
	selectorOrMethod := traceLog at: i + 1.
	source := traceLog at: i + 2.
	source <= TraceIsFromInterpreter ifTrue:
		[self print: (traceSources at: source); space].
	(self isIntegerObject: intOrClass)
		ifTrue:
			[intOrClass = TraceContextSwitch ifTrue:
				[self print: 'context switch'].
			 intOrClass = TraceBlockActivation ifTrue:
				[self print: ' [] in '; printHex: selectorOrMethod].
			 intOrClass = TraceBlockCreation ifTrue:
				[self print: 'create [] '; printHex: selectorOrMethod].
			 intOrClass = TraceIncrementalGC ifTrue:
				[self print: 'incrementalGC'].
			 intOrClass = TraceFullGC ifTrue:
				[self print: 'fullGC'].
			 intOrClass = TraceCodeCompaction ifTrue:
				[self print: 'compactCode']]
		ifFalse:
			[self space; printNameOfClass: intOrClass count: 5; print: '>>'; safePrintStringOf: selectorOrMethod].
	source > TraceIsFromInterpreter ifTrue:
		[self space; print: (traceSources at: source)].
	self cr
]

{ #category : #'stack bytecodes' }
CoInterpreter >> pushClosureCopyCopiedValuesBytecode [
	"The compiler has pushed the values to be copied, if any.  Find numArgs and numCopied in the byte following.
	 Create a Closure with space for the copiedValues and pop numCopied values off the stack into the closure.
	 Set numArgs as specified, and set startpc to the pc following the block size and jump over that code.

	Override only to add debug tracing as of 4/26/2009"
	| newClosure numArgsNumCopied numArgs numCopied blockSize context |
	numArgsNumCopied := self fetchByte.
	numArgs := numArgsNumCopied bitAnd: 16rF.
	numCopied := numArgsNumCopied bitShift: -4.
	"Split blockSize := (self fetchByte * 256) + self fetchByte. into two because evaluation order in C is undefined."
	blockSize := self fetchByte << 8.
	blockSize := blockSize + self fetchByte.
	context := self ensureFrameIsMarried: localFP SP: localSP.
	newClosure := self
					closureIn: context
					numArgs: numArgs
					instructionPointer: (self oopForPointer: localIP) + 2 - (method+BaseHeaderSize)
					numCopiedValues: numCopied.
	cogit recordSendTrace ifTrue:
		[self recordTrace: TraceBlockCreation thing: newClosure source: TraceIsFromInterpreter].
	numCopied > 0 ifTrue:
		[0 to: numCopied - 1 do:
			[:i|
			"Assume: have just allocated a new BlockClosure; it must be young.
			 Thus, can use unchecked stores."
			 self storePointerUnchecked: i + ClosureFirstCopiedValueIndex
				ofObject: newClosure
				withValue: (self internalStackValue: numCopied - i - 1)].
		 self internalPop: numCopied].
	localIP := localIP + blockSize.
	self fetchNextBytecode.
	self internalPush: newClosure
]

{ #category : #'stack bytecodes' }
CoInterpreter >> pushRemoteTemp: index inVectorAt: tempVectorIndex [
	"Override to use itemporary:in:put:"
	| tempVector |
	tempVector := self itemporary: tempVectorIndex in: localFP.
	self internalPush: (self fetchPointer: index ofObject: tempVector)
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
		[257] -> [trueObj].
		[258] -> [falseObj].
		[259] -> [nilObj].
		[260] -> [ConstMinusOne].
		[261] -> [ConstZero].
		[262] -> [ConstOne].
		[263] -> [ConstTwo] }
]

{ #category : #'cog jit support' }
CoInterpreter >> quickPrimitiveGeneratorFor: aQuickPrimitiveIndex [
	<api>
	<returnTypeC: 'int (*quickPrimitiveGeneratorFor(sqInt aQuickPrimitiveIndex))(void)'>
	^aQuickPrimitiveIndex
		caseOf: {
			[256] -> [#genQuickReturnSelf asSymbol].
			[257] -> [#genQuickReturnConst asSymbol].
			[258] -> [#genQuickReturnConst asSymbol].
			[259] -> [#genQuickReturnConst asSymbol].
			[260] -> [#genQuickReturnConst asSymbol].
			[261] -> [#genQuickReturnConst asSymbol].
			[262] -> [#genQuickReturnConst asSymbol].
			[263] -> [#genQuickReturnConst asSymbol] }
		otherwise: [#genQuickReturnInstVar asSymbol]
]

{ #category : #'cog jit support' }
CoInterpreter >> quickPrimitiveInstVarIndexFor: primIndex [
	<api>
	^primIndex - 264
]

{ #category : #'compiled methods' }
CoInterpreter >> rawHeaderOf: methodPointer [
	<api>
	^self fetchPointer: HeaderIndex ofObject: methodPointer
]

{ #category : #'compiled methods' }
CoInterpreter >> rawHeaderOf: methodOop put: cogMethod [
	<api>
	<var: #cogMethod type: #'void *'> 
	self storePointerUnchecked: HeaderIndex
		ofObject: methodOop
		withValue: cogMethod asInteger
]

{ #category : #'image save/restore' }
CoInterpreter >> readImageFromFile: f HeapSize: desiredHeapSize StartingAt: imageOffset [
	"Read an image from the given file stream, allocating the given amount of memory to its object heap. Fail if the image has an unknown format or requires more than the given amount of memory."
	"Details: This method detects when the image was stored on a machine with the opposite byte ordering from this machine and swaps the bytes automatically. Furthermore, it allows the header information to start 512 bytes into the file, since some file transfer programs for the Macintosh apparently prepend a Mac-specific header of this size. Note that this same 512 bytes of prefix area could also be used to store an exec command on Unix systems, allowing one to launch Smalltalk by invoking the image name as a command."
	"This code is based on C code by Ian Piumarta and Smalltalk code by Tim Rowledge. Many thanks to both of you!!"

	| swapBytes headerStart headerSize dataSize oldBaseAddr
	  minimumMemory heapSize bytesRead bytesToShift
	  hdrNumStackPages hdrEdenBytes hdrCogCodeSize headerFlags hdrMaxExtSemTabSize |
	<var: #f type: 'sqImageFile '>
	<var: #memStart type: 'usqInt'>
	<var: #headerStart type: 'squeakFileOffsetType '>
	<var: #dataSize type: 'size_t '>
	<var: #imageOffset type: 'squeakFileOffsetType '>

	metaclassSizeBytes := 6 * BytesPerWord.	"guess (Metaclass instSize * BPW)"
	swapBytes := self checkImageVersionFrom: f startingAt: imageOffset.
	headerStart := (self sqImageFilePosition: f) - BytesPerWord.  "record header start position"

	headerSize			:= self getLongFromFile: f swap: swapBytes.
	dataSize			:= self getLongFromFile: f swap: swapBytes.
	oldBaseAddr		:= self getLongFromFile: f swap: swapBytes.
	specialObjectsOop	:= self getLongFromFile: f swap: swapBytes.
	lastHash			:= self getLongFromFile: f swap: swapBytes. "N.B.  not used."
	savedWindowSize	:= self getLongFromFile: f swap: swapBytes.
	headerFlags			:= self getLongFromFile: f swap: swapBytes.
	self setImageHeaderFlagsFrom: headerFlags.
	extraVMMemory		:= self getLongFromFile: f swap: swapBytes. "N.B.  not used."
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
									ifTrue: [self defaultCogCodeSize]
									ifFalse: [hdrCogCodeSize]].
	hdrEdenBytes		:= self getLongFromFile: f swap: swapBytes.
	edenBytes := desiredEdenBytes ~= 0
						ifTrue: [desiredEdenBytes]
						ifFalse:
							[hdrEdenBytes = 0
									ifTrue: [self defaultEdenBytes]
									ifFalse: [hdrEdenBytes]].
	desiredEdenBytes := hdrEdenBytes.
	hdrMaxExtSemTabSize := self getShortFromFile: f swap: swapBytes.
	hdrMaxExtSemTabSize ~= 0 ifTrue:
		[self setMaxExtSemSizeTo: hdrMaxExtSemTabSize].

	"compare memory requirements with availability"
	minimumMemory := cogCodeSize "no need to include the stackZone; this is alloca'ed"
						+ dataSize
						+ edenBytes
						+ self interpreterAllocationReserveBytes.
	heapSize             :=  cogCodeSize "no need to include the stackZone; this is alloca'ed"
						+ desiredHeapSize
						"+ edenBytes" "don't include edenBytes; this is part of the heap and so part of desiredHeapSize"
						+ self interpreterAllocationReserveBytes.
	heapSize < minimumMemory ifTrue:
		[self insufficientMemorySpecifiedError].

	"allocate a contiguous block of memory for the Squeak heap"
	"N.B. If the platform needs to it will redefine this macro to make heapSize
	 an in/out parameter and assign the ammount actually allocated into heapSize.
	 See e.g. platforms/Mac OS/vm/sqPlatformSpecific.h.  (I *hate* this. eem 7/23/2009)"
	memory := self cCode: 'sqAllocateMemory(minimumMemory, heapSize)'.
	memory = nil ifTrue: [self insufficientMemoryAvailableError].
	heapBase := memory + cogCodeSize.
	self assert: self startOfMemory = heapBase.
	self setMemoryLimit: memory + heapSize - 24.  "decrease memoryLimit a tad for safety"
	self setEndOfMemory: heapBase + dataSize.

	"position file after the header"
	self sqImageFile: f Seek: headerStart + headerSize.

	"read in the image in bulk, then swap the bytes if necessary"
	bytesRead := self cCode: 'sqImageFileRead(pointerForOop(heapBase), sizeof(unsigned char), dataSize, f)'.
	bytesRead ~= dataSize ifTrue: [self unableToReadImageError].

	self ensureImageFormatIsUpToDate: swapBytes.

	"compute difference between old and new memory base addresses"
	bytesToShift := heapBase - oldBaseAddr.
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
CoInterpreter >> recordContextSwitchFrom: sourceCode [
	cogit recordEventTrace ifTrue:
		[self recordTrace: TraceContextSwitch thing: TraceContextSwitch source: sourceCode]
]

{ #category : #'debug support' }
CoInterpreter >> recordTrace: classOrInteger thing: selector source: source [
	traceLog at: traceLogIndex put: classOrInteger.
	traceLog at: traceLogIndex + 1 put: selector.
	traceLog at: traceLogIndex + 2 put: source.
	traceLogIndex := traceLogIndex + 3 \\ TraceBufferSize
]

{ #category : #'process primitive support' }
CoInterpreter >> resume: aProcess [
	"Make aProcess runnable and if its priority is higher than
	 that of the current process, preempt the current process.
	 Answer if the current process was preempted.  Override
	 to add tracing info (see resume:from:)."
	<doNotGenerate>
	self shouldNotImplement
]

{ #category : #'process primitive support' }
CoInterpreter >> resume: aProcess preemptedYieldingIf: yieldImplicitly from: sourceCode [
	"Make aProcess runnable and if its priority is higher than  that of the
	 current process, preempt the current process.   Answer if the current
	 process was preempted.  If the current process was preempted then if
	 yieldImplicitly add the current process to the back of its run queue,
	 causing an implicit yiled to other processes on the run queue,  otherwise
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
		[self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: false.
		 self push: instructionPointer.
		 self push: returnValue.
		 cogit ceEnterCogCodePopReceiverReg
		 "NOTREACHED"].
	self push: returnValue.
	self setMethod: (self iframeMethod: framePointer).
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: true.
	instructionPointer = cogit ceReturnToInterpreterPC ifTrue:
		[instructionPointer := self iframeSavedIP: framePointer].
	inInterpreter ifTrue:
		[^nil].
	self siglong: reenterInterpreter jmp: 1.
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
		[self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: false.
		 "If returning after a context switch then a result may have to be popped from the stack.
		  If the process is suspended at a send then the result of the primitive in which the
		  process was suspended is still on the stack and must be popped into ReceiverResultReg.
		  If not, nothing should be popped and ReceiverResultReg gets the receiver."
		 switchedContext
			ifTrue:
				[cogMethod := self mframeCogMethod: framePointer.
				 (instructionPointer ~= (cogMethod asInteger + cogMethod stackCheckOffset)
				  and: [cogit isSendReturnPC: instructionPointer])
					ifTrue:
						[self assert: ((self isIntegerObject: self stackTop) or: [self addressCouldBeObj: self stackTop]).
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
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: true.
	fullyInInterpreter ifFalse:
		[self siglong: reenterInterpreter jmp: 1.
		 "NOTREACHED"].
	^nil
]

{ #category : #'return bytecodes' }
CoInterpreter >> returnToMachineCodeFrame [
	"Return to the previous context/frame after assigning localIP, localSP and localFP."
	cogit assertCStackWellAligned.
	self assert: localIP asUnsignedInteger < self startOfMemory.
	self assert: (self isMachineCodeFrame: localFP).
	self assertValidExecutionPointe: localIP asUnsignedInteger r: localFP s: localSP imbar: false.
	self flag: 'currently caller pushes result'.
	self internalPop: 1 thenPush: localIP.
	self internalPush: localReturnValue.
	self externalizeFPandSP.
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
				ifTrue: [self cCoerceSimple: #primitiveFail asSymbol to: #'void (*)(void)']
				ifFalse: [localPrimAddress])].
	(methodCache at: lastMethodCacheProbeWrite + MethodCacheMethod) = newMethod ifTrue:
		[methodCache
			at: lastMethodCacheProbeWrite + MethodCachePrimFunction
			put: (self cCoerce: localPrimAddress to: #long)]
]

{ #category : #'primitive support' }
CoInterpreter >> roomToPushNArgs: n [
	"Answer if there is room to push n arguments onto the current stack.
	 There may be room in this stackPage but there may not be room if
	 the frame were converted into a context."
	| methodHeader cntxSize |
	(self isMachineCodeFrame: framePointer)
		ifTrue: [methodHeader := (self mframeHomeMethod: framePointer) methodHeader]
		ifFalse: [methodHeader := self headerOf: (self iframeMethod: framePointer)].
	cntxSize := (methodHeader bitAnd: LargeContextBit) ~= 0
					ifTrue: [LargeContextSize / BytesPerWord - ReceiverIndex]
					ifFalse: [SmallContextSize / BytesPerWord - ReceiverIndex].
	^self stackPointerIndex + n <= cntxSize
]

{ #category : #'cog jit support' }
CoInterpreter >> scavengeThreshold [
	<doNotGenerate>
	^scavengeThreshold
]

{ #category : #'trampoline support' }
CoInterpreter >> scavengeThresholdAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: scavengeThreshold) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #scavengeThreshold in: self]
]

{ #category : #'internal interpreter access' }
CoInterpreter >> setCogVMFlags: flags [
	"Set an array of flags indicating various properties of the Cog VM.
	 Bit 0: if set, implies the image's Process class has threadId as its 3rd inst var (zero relative)
	 Bit 1: if set, methods that are interpreted will have the flag bit set in their header
	 Bit 2: if set, implies preempting a process does not put it to the back of its run queue"
	flags asUnsignedInteger > 7 ifTrue:
		[^self primitiveFailFor: PrimErrUnsupported].
	processHasThreadId := (flags bitAnd: 1) ~= 0.
	flagInterpretedMethods := (flags bitAnd: 2) ~= 0.
	preemptionYields := (flags bitAnd: 4) = 0.
]

{ #category : #'internal interpreter access' }
CoInterpreter >> setDesiredCogCodeSize: dccs [
	<cmacro: '(dccs) (desiredCogCodeSize = (dccs))'>
	desiredCogCodeSize := dccs
]

{ #category : #'image save/restore' }
CoInterpreter >> setImageHeaderFlagsFrom: headerFlags [
	"Set the flags that are contained in the 7th long of the image header."
	imageHeaderFlags := headerFlags. "so as to preserve unrecognised flags."
	fullScreenFlag := headerFlags bitAnd: 1.
	imageFloatsBigEndian := (headerFlags bitAnd: 2) = 0 ifTrue: [1] ifFalse: [0].
	processHasThreadId := (headerFlags bitAnd: 4) ~= 0.
	flagInterpretedMethods := (headerFlags bitAnd: 8) ~= 0.
	preemptionYields := (headerFlags bitAnd: 16) = 0
]

{ #category : #'internal interpreter access' }
CoInterpreter >> setMethod: aMethodObj [
	self assert: aMethodObj asUnsignedInteger >= self startOfMemory.
	method := aMethodObj
]

{ #category : #'debug printing' }
CoInterpreter >> shortPrintFrame: theFP [
	<inline: false>
	<var: #theFP type: #'char *'>
	| rcvr mthd |
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
		 self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer imbar: true].
	aJumpBuf returnValue: returnValue; signal
]

{ #category : #'cog jit support' }
CoInterpreter >> sigset:aJumpBuf jmp: sigSaveMask [
	"Hack simulation of sigsetjmp/siglongjmp.
	 Assign to reenterInterpreter the exception that when
	 raised simulates a longjmp back to the interpreter." 
	<doNotGenerate>
	reenterInterpreter := ReenterInterpreter new returnValue: 0; yourself.
	^0
]

{ #category : #'primitive support' }
CoInterpreter >> slowPrimitiveResponse [
	"Called under the assumption that primFunctionPtr has been preloaded"
	| nArgs savedFramePointer savedStackPointer |
	<inline: true>
	<asmLabel: false>
	<var: #savedFramePointer type: #'char *'>
	<var: #savedStackPointer type: #'char *'>
	cogit recordPrimTrace ifTrue:
		[self fastLogPrim: messageSelector].
	FailImbalancedPrimitives ifTrue:
		[nArgs := argumentCount.
		 savedStackPointer := stackPointer.
		 savedFramePointer := framePointer].
	self initPrimCall.
	self dispatchFunctionPointer: primitiveFunctionPointer.
	(FailImbalancedPrimitives
	and: [self successful
	and: [framePointer = savedFramePointer
	and: [(self isMachineCodeFrame: framePointer) not]]]) ifTrue:"Don't fail if primitive has done something radical, e.g. perform:"
		[stackPointer ~= (savedStackPointer + (nArgs * BytesPerWord)) ifTrue:
			[self flag: 'Would be nice to make this a message send of e.g. unbalancedPrimitive to the current process or context'.
			 "This is necessary but insufficient; the result may still have been written to the stack.
			   At least we'll know something is wrong."
			 stackPointer := savedStackPointer.
			 self failUnbalancedPrimitive]].
	"If we are profiling, take accurate primitive measures"
	nextProfileTick > 0 ifTrue:
		[self checkProfileTick: newMethod].
	^self successful
]

{ #category : #'cog jit support' }
CoInterpreter >> specialSelectorNumArgs: index [ "<SmallInteger>"
	<api>
	^self integerValueOf: (self fetchPointer: (index * 2) + 1
							ofObject: (self splObj: SpecialSelectors))
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
	^(IFrameSlots + 64) * BytesPerWord
]

{ #category : #'stack pages' }
CoInterpreter >> stackPageHeadroom [
	"Return a minimum amount of headroom for each stack page (in bytes).
	 In a JIT the stack has to have room for interrupt handlers which will run on the
	 stack.  In the interpreter we don't actually need any headroom."
	^cogit stackPageHeadroomBytes + 1024
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
		ifTrue: [(((theFP + FoxMFReceiver) - theSP) >> ShiftForWord) + (self mframeNumArgs: theFP)]
		ifFalse: [(((theFP + FoxIFReceiver) - theSP) >> ShiftForWord) + (self iframeNumArgs: theFP)]
]

{ #category : #'frame access' }
CoInterpreter >> stackPointerIndexForIFrame: theFP WithSP: theSP numArgs: numArgs [
	"Return the 1-based index rel to the given frame"
	"In the StackInterpreter stacks grow down."
	^(((theFP + FoxIFReceiver) - theSP) >> ShiftForWord) + numArgs
]

{ #category : #'frame access' }
CoInterpreter >> stackPointerIndexForMFrame: theFP WithSP: theSP numArgs: numArgs [
	"Return the 1-based index rel to the given machine code frame"
	"In the StackInterpreter stacks grow down."
	^(((theFP + FoxMFReceiver) - theSP) >> ShiftForWord) + numArgs
]

{ #category : #initialization }
CoInterpreter >> startOfMemory [
	"Return the start of object memory.  This is immediately after the native code zone.
	 N.B. the stack zone is alloca'ed."
	<api>
	^heapBase
]

{ #category : #'compiled methods' }
CoInterpreter >> startPCOfClosure: aBlockClosure [
	"Zero-relative version of BlockClosure>>startpc."
	^(self integerValueOf: (self fetchPointer: ClosureStartPCIndex ofObject: aBlockClosure)) - 1
]

{ #category : #'compiled methods' }
CoInterpreter >> startPCOfMethod: aCompiledMethod [
	<api>
	"Zero-relative version of CompiledMethod>>startpc."
	^self lastPointerOf: aCompiledMethod
]

{ #category : #'compiled methods' }
CoInterpreter >> startPCOfMethodHeader: aCompiledMethodHeader [
	<api>
	"Zero-relative version of CompiledMethod>>startpc."
	^(self literalCountOfHeader: aCompiledMethodHeader) * BytesPerWord + BaseHeaderSize
]

{ #category : #'stack bytecodes' }
CoInterpreter >> storeAndPopTemporaryVariableBytecode [
	<expandCases>
	"this bytecode will be expanded so that refs to currentBytecode below will be constant"
	self fetchNextBytecode.
	self itemporary: (currentBytecode bitAnd: 7) in: localFP put: self internalStackTop.
	self internalPop: 1
]

{ #category : #'stack bytecodes' }
CoInterpreter >> storeRemoteTemp: index inVectorAt: tempVectorIndex [
	"Override to use itemporary:in:put:"
	| tempVector |
	tempVector := self itemporary: tempVectorIndex in: localFP.
	self storePointer: index ofObject: tempVector withValue: self internalStackTop
]

{ #category : #'primitive support' }
CoInterpreter >> stringForCString: aCString [
	"Answer a new String copied from a null-terminated C string,
	 or nil if out of memory.
	 Caution: This may invoke the garbage collector."
	<api>
	<var: 'aCString' type: 'const char *'>
	| len newString |
	len := self strlen: aCString.
	newString := self instantiateClass: self classString indexableSize: len.
	newString isNil ifFalse:
		[self st: (self arrayValueOf: newString)
			rn: aCString
			cpy: len]. "(char *)strncpy()"
	^newString
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
	self storePointer: SenderIndex ofObject: contextToReturnFrom withValue: contextToReturnTo.
	self storePointer: InstructionPointerIndex ofObject: contextToReturnFrom withValue: HasBeenReturnedFromMCPC.
	"void the instructionPointer to stop it being incorrectly updated in a code
	 compaction in makeBaseFrameFor:."
	instructionPointer := 0.
	newPage := self makeBaseFrameFor: contextToReturnFrom.
	self assert: stackPage = newPage.
	self setStackPageAndLimit: newPage.
	framePointer := stackPage headFP.
	stackPointer := stackPage headSP.
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
				ifTrue: [stackPages longAt: theFP + FoxCallerSavedIP + ((frameNumArgs - offset) * BytesPerWord)]
				ifFalse: [stackPages longAt: theFP + FoxMFReceiver - BytesPerWord + ((frameNumArgs - offset) * BytesPerWord)]]
		ifFalse:
			[self itemporary: offset in: theFP]
]

{ #category : #'internal interpreter access' }
CoInterpreter >> temporary: offset in: theFP put: valueOop [
	self cCode: ''
		inSmalltalk:
			[self assert: thisContext sender sender sender method selector == #primitiveContextAtPut].
	(self isMachineCodeFrame: theFP)
		ifTrue: [self mtemporary: offset in: theFP put: valueOop]
		ifFalse: [self itemporary: offset in: theFP put: valueOop]
]

{ #category : #'internal interpreter access' }
CoInterpreter >> temporaryLocation: offset in: theFP numArgs: numArgs [
	"Answer the pointer to a given temporary (for debug frame printing in odd circumstances)"
	<var: #theFP type: #'char *'>
	<returnTypeC: #'char *'>
	<asmLabel: false>
	^offset < numArgs
		ifTrue: [theFP + FoxCallerSavedIP + ((numArgs - offset) * BytesPerWord)]
		ifFalse: [theFP
			+ ((self isMachineCodeFrame: theFP)
					ifTrue: [FoxMFReceiver - BytesPerWord]
					ifFalse: [FoxIFReceiver - BytesPerWord])
			+ ((numArgs - offset) * BytesPerWord)]
]

{ #category : #accessing }
CoInterpreter >> threadManager [
	<doNotGenerate>
	^nil
]

{ #category : #'process primitive support' }
CoInterpreter >> threadSwitchIfNecessary: newProc from: sourceCode [
	"This is a no-op in the non-threaded VM"
]

{ #category : #simulation }
CoInterpreter >> transcript [
	<doNotGenerate>
	^Transcript
]

{ #category : #'process primitive support' }
CoInterpreter >> transferTo: newProc [
	"replaced by transferTo:from: for better tracing (for debugging)"
	<doNotGenerate>
	self shouldNotImplement
]

{ #category : #'process primitive support' }
CoInterpreter >> transferTo: newProc from: sourceCode [
	"Record a process to be awoken on the next interpreter cycle."
	| sched oldProc activeContext |
	statProcessSwitch := statProcessSwitch + 1.
	self push: instructionPointer.
	self externalWriteBackHeadFramePointers.
	sched := self schedulerPointer.
	oldProc := self fetchPointer: ActiveProcessIndex ofObject: sched.
	activeContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
	self storePointer: SuspendedContextIndex ofObject: oldProc withValue: activeContext.
	self storePointer: ActiveProcessIndex ofObject: sched withValue: newProc.
	self storePointerUnchecked: MyListIndex ofObject: newProc withValue: nilObj.

	self threadSwitchIfNecessary: newProc from: sourceCode.

	self externalSetStackPageAndPointersForSuspendedContextOfProcess: newProc.
	instructionPointer := self popStack.
	self assertValidExecutionPointe: instructionPointer r: framePointer s: stackPointer.
	self recordContextSwitchFrom: sourceCode
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
					[theMethod := self cCoerceSimple: theMethod objectHeader to: #'CogMethod *'].
				 theIP := (stackPages longAt: theIPPtr) asUnsignedInteger.
				 (theIP ~= cogit ceCannotResumePC
				  and: [self asserta: (theIP >= theMethod asUnsignedInteger
							   and: [theIP < (theMethod asUnsignedInteger + theMethod blockSize)])]) ifTrue:
					[stackPages
						longAt: theIPPtr
						put: theIP + theMethod objectHeader signedIntFromLong].
				 stackPages
					longAt: theFP + FoxMethod
					put: theMethodField + theMethod objectHeader signedIntFromLong].
			 (callerFP := self frameCallerFP: theFP) ~= 0] whileTrue:
				[theIPPtr := theFP + FoxCallerSavedIP.
				 theFP := callerFP]]]
]

{ #category : #'frame access' }
CoInterpreter >> updateStateOfSpouseContextForFrame: theFP WithSP: theSP [
	"Update the frame's spouse context with the frame's current state except for the
	 sender and instruction pointer, which are used to mark the context as married."
	| theContext tempIndex pointer |
	<inline: false>
	<var: #theFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #pointer type: #'char *'>
	self assert: (self frameHasContext: theFP).
	theContext := self frameContext: theFP.
	self assert: (self isContext: theContext).
	self assert: (self frameReceiver: theFP)
				= (self fetchPointer: ReceiverIndex ofObject: theContext).
	(self isMachineCodeFrame: theFP)
		ifTrue:
			[tempIndex := self mframeNumArgs: theFP.
			 pointer := theFP + FoxMFReceiver - BytesPerWord]
		ifFalse:
			[tempIndex := self iframeNumArgs: theFP.
			 pointer := theFP + FoxIFReceiver - BytesPerWord].
	[pointer >= theSP] whileTrue:
		[self assert: (self addressCouldBeOop: (stackPages longAt: pointer)).
		 tempIndex := tempIndex + 1.
		 self storePointer: ReceiverIndex + tempIndex
			ofObject: theContext
			withValue: (stackPages longAt: pointer).
		 pointer := pointer - BytesPerWord].
	self assert: ReceiverIndex + tempIndex < (self lengthOf: theContext).
	self storePointerUnchecked: StackPointerIndex
		ofObject: theContext
		withValue: (self integerObjectOf: tempIndex)
]

{ #category : #'debug support' }
CoInterpreter >> validInstructionPointer: anInstrPointer inMethod: aMethod framePointer: fp [
	<var: #anInstrPointer type: #usqInt>
	<var: #aMethod type: #usqInt>
	<var: #fp type: #'char *'>
	| theInstrPointer header cogMethod |
	<var: #theInstrPointer type: #usqInt>
	<var: #cogMethod type: #'CogMethod *'>
	anInstrPointer = cogit ceCannotResumePC ifTrue:
		[^self isMachineCodeFrame: fp].
	anInstrPointer = cogit ceReturnToInterpreterPC
		ifTrue:
			[(self isMachineCodeFrame: fp) ifTrue:
				[^false].
			 theInstrPointer := self iframeSavedIP: fp]
		ifFalse:
			[theInstrPointer := anInstrPointer.
			 header := self rawHeaderOf: aMethod.
			 ((self isCogMethodReference: header)
			   and: [theInstrPointer < self startOfMemory]) ifTrue:
			 	[cogMethod := self cCoerceSimple: header to: #'CogMethod *'.
			 	 ^theInstrPointer >= (header + (cogit sizeof: CogMethod))
			 	 and: [theInstrPointer < (header + cogMethod blockSize)]]].
	^theInstrPointer >= (aMethod + (self lastPointerOf: aMethod) + BytesPerWord - 1)
	  and: [theInstrPointer < (aMethod + (self byteLengthOf: aMethod) + BaseHeaderSize)]
]

{ #category : #'stack pages' }
CoInterpreter >> validStackPageBaseFrames [
	"Check that the base frames in all in-use stack pages have a sender and a saved context."
	<var: #aPage type: #'StackPage *'>
	0 to: numStackPages - 1 do:
		[:i| | aPage senderContextOrNil savedThisContext |
		aPage := stackPages stackPageAt: i.
		(stackPages isFree: aPage) ifFalse:
			[senderContextOrNil := stackPages longAt: aPage baseAddress.
			 savedThisContext := stackPages longAt: aPage baseAddress - BytesPerWord.
			 (self asserta: aPage baseFP + (self frameStackedReceiverOffset: aPage baseFP) + (2 * BytesPerWord) = aPage baseAddress) ifFalse:
				[^false].
			 (self asserta: (self addressCouldBeObj: senderContextOrNil)) ifFalse:
				[^false].
			 (self asserta: (self addressCouldBeObj: savedThisContext)) ifFalse:
				[^false].
			 (self asserta: (senderContextOrNil = nilObj or: [self isContext: senderContextOrNil])) ifFalse:
				[^false].
			 (self asserta: (self isContext: savedThisContext)) ifFalse:
				[^false].
			 (self asserta: (self frameCallerContext: aPage baseFP) = senderContextOrNil) ifFalse:
				[^false].
			 (self asserta: (self frameContext: aPage baseFP) = savedThisContext) ifFalse:
				[^false]]].
	^true
]

{ #category : #'frame access' }
CoInterpreter >> voidVMStateForSnapshot [
	"Make sure that all VM state that affects the heap contents is voided so that the heap is ready
	 to be snapshotted. Answer the activeContext object that should be stored in the snapshot."
	| activeContext |
	instructionPointer := 0. "in case of code compactions."
	activeContext := self divorceAllFrames.
	self ensureAllContextsHaveBytecodePCsOrAreBereaved.
	cogit voidCogCompiledCode.
	^activeContext
]

{ #category : #'cog jit support' }
CoInterpreter >> warning: aString [
	<api: 'extern void warning(char *s)'>
	<doNotGenerate>
	self transcript cr; nextPutAll: aString; flush
]

{ #category : #simulation }
CoInterpreter >> withRegisterStateForCurrentThreadSetIn: aProcessorAlien do: aBlock [
	<doNotGenerate>
	"No multi-threading support so per-thread state to arrange."
	^aBlock value
]

{ #category : #'trampoline support' }
CoInterpreter >> youngStartAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: youngStart) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #youngStart in: self]
]
