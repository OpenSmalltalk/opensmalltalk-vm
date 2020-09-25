Class {
	#name : #CoInterpreterPrimitives,
	#superclass : #CoInterpreter,
	#category : #'VMMaker-JIT'
}

{ #category : #'process primitives' }
CoInterpreterPrimitives >> doWaitSemaphore: sema [

	<api>
	<returnTypeC: #void>
	
	self doWaitSemaphore: sema reEnterInterpreter: true
]

{ #category : #'process primitives' }
CoInterpreterPrimitives >> doWaitSemaphore: sema reEnterInterpreter: hasToReenter [
	| excessSignals activeProc inInterpreter |
	<api>
	<returnTypeC: #void>	

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
			inInterpreter := instructionPointer >= objectMemory startOfMemory.
			activeProc := self activeProcess.
			self addLastLink: activeProc toList: sema.
			self transferTo: self wakeHighestPriority from: CSWait.
			hasToReenter ifTrue: [self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter]]
]

{ #category : #'object access primitives' }
CoInterpreterPrimitives >> frameIsMarked: theFPInt [
	| methodField |
	methodField := stackPages longAt: theFPInt + FoxMethod.
	^methodField asUnsignedInteger < objectMemory startOfMemory
		ifTrue: [(methodField bitAnd: 4) ~= 0]
		ifFalse: [((stackPages longAt: theFPInt + FoxIFrameFlags) bitAnd: 2) ~= 0]
]

{ #category : #'object access primitives' }
CoInterpreterPrimitives >> markFrame: theFPInt [
	| methodField |
	methodField := stackPages longAt: theFPInt + FoxMethod.
	methodField asUnsignedInteger < objectMemory startOfMemory
		ifTrue:
			[stackPages
				longAt: theFPInt + FoxMethod
				put: (methodField bitOr: 4)]
		ifFalse:
			[stackPages
				longAt: theFPInt + FoxIFrameFlags
				put: ((stackPages longAt: theFPInt + FoxIFrameFlags) bitOr: 2)]
]

{ #category : #'arithmetic primitives' }
CoInterpreterPrimitives >> mcprimHashMultiply: receiverArg [
	"Machine code primitive for hash multiply. c.f. primitiveHashMultiply.
	 mcprims consume receiver and arguments as parameters and answer the
	 result on success, or set the primitive error code and answer 0 on failure."
	"Implement 28-bit hashMultiply for SmallInteger and LargePositiveInteger receivers."
	<api>
	| value |
	(objectMemory isIntegerObject: receiverArg)
		ifTrue: [value := objectMemory integerValueOf: receiverArg]
		ifFalse:
			[| ok |
			 ok := objectMemory is: receiverArg instanceOf: (objectMemory splObj: ClassLargePositiveInteger) compactClassIndex: ClassLargePositiveIntegerCompactIndex.
			 ok ifFalse:
				[self primitiveFailFor: PrimErrBadReceiver.
				 ^0].
			 value := objectMemory byteSwapped32IfBigEndian: (objectMemory fetchLong32: 0 ofObject: receiverArg)].
	^objectMemory integerObjectOf: (value * HashMultiplyConstant bitAnd: 16rFFFFFFF)
]

{ #category : #'object access primitives' }
CoInterpreterPrimitives >> pathTo: goal using: stack followWeak: followWeak [
	"Trace objects and frames from the root, marking visited objects, pushing the current path on stack, until goal is found.
	 If found, unmark, leaving path in stack, and answer 0.  Otherwise answer an error:
		PrimErrBadArgument if stack is not an Array
		PrimErrBadIndex if search overflows stack
		PrimErrNotFound if goal cannot be found"
	| current index next stackSize stackp freeStartAtStart |
	<var: #index type: #sqInt> "Force the sign because typeInference does not seem to work"
	(objectMemory isArray: stack) ifFalse:
		[^PrimErrBadArgument].
	self assert: objectMemory allObjectsUnmarked.
	freeStartAtStart := objectMemory freeStart. "check no allocations during search"
	objectMemory beRootIfOld: stack. "so no store checks are necessary on stack"
	stackSize := objectMemory lengthOf: stack.
	objectMemory mark: stack.
	"no need. the current context is not reachable from the active process (suspendedContext is nil)"
	"objectMemory mark: self activeProcess."
	current := objectMemory specialObjectsOop.
	objectMemory mark: current.
	index := objectMemory lengthOf: current.
	stackp := 0.
	[[(index := index - 1) >= -1] whileTrue:
		[(stackPages couldBeFramePointer: current)
			ifTrue:
				[next := index >= 0
							ifTrue: [self field: index ofFrame: (self cCoerceSimple: current to: #'char *')]
							ifFalse: [objectMemory nilObject]]
			ifFalse:
				[index >= 0
					ifTrue:
						[next := (objectMemory isContextNonImm: current)
									ifTrue: [self fieldOrSenderFP: index ofContext: current]
									ifFalse: [objectMemory fetchPointer: index ofObject: current]]
					ifFalse:
						[next := objectMemory fetchClassOfNonImm: current]].
		 (stackPages couldBeFramePointer: next)
			ifTrue: [self assert: (self isFrame: (self cCoerceSimple: next to: #'char *')
										onPage: (stackPages stackPageFor: (self cCoerceSimple: next to: #'char *')))]
			ifFalse:
				[next >= heapBase ifTrue: "exclude Cog methods"
					[self assert: (self checkOkayOop: next)]].
		 next = goal ifTrue:
			[self assert: freeStartAtStart = objectMemory freeStart.
			 self unmarkAfterPathTo.
			 objectMemory storePointer: stackp ofObject: stack withValue: current.
			 self pruneStack: stack stackp: stackp.
			 ^0].
		 ((objectMemory isNonIntegerObject: next)
		  and: [(stackPages couldBeFramePointer: next)
				ifTrue: [(self frameIsMarked: next) not]
				ifFalse:
					[next >= heapBase "exclude Cog methods"
					  and: [(objectMemory isMarked: next) not
					  and: [((objectMemory isPointers: next) or: [objectMemory isCompiledMethod: next])
					  and: [followWeak or: [(objectMemory isWeakNonImm: next) not]]]]]])
			ifTrue:
				[stackp + 2 > stackSize ifTrue:
					[self assert: freeStartAtStart = objectMemory freeStart.
					 self unmarkAfterPathTo.
					 objectMemory nilFieldsOf: stack.
					 ^PrimErrBadIndex]. "PrimErrNoMemory ?"
				 objectMemory
					storePointerUnchecked: stackp ofObject: stack withValue: current;
					storePointerUnchecked: stackp + 1 ofObject: stack withValue: (objectMemory integerObjectOf: index).
				 stackp := stackp + 2.
				 (stackPages couldBeFramePointer: (self cCoerceSimple: next to: #'char *'))
					ifTrue:
						[self markFrame: next.
						index := self fieldsInFrame: (self cCoerceSimple: next to: #'char *')]
					ifFalse:
						[objectMemory mark: next.
						 (objectMemory isCompiledMethod: next)
							ifTrue: [index := (objectMemory literalCountOf: next) + LiteralStart]
							ifFalse: [index := objectMemory lengthOf: next]].
				 current := next]].
		 current = objectMemory specialObjectsOop ifTrue:
			[self assert: freeStartAtStart = objectMemory freeStart.
			 self unmarkAfterPathTo.
			 objectMemory nilFieldsOf: stack.
			^PrimErrNotFound].
		 index := objectMemory integerValueOf: (objectMemory fetchPointer: stackp - 1 ofObject: stack).
		 current := objectMemory fetchPointer: stackp - 2 ofObject: stack.
		 stackp := stackp - 2] repeat
]

{ #category : #'method introspection support' }
CoInterpreterPrimitives >> pcDataFor: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	| cm nSlots nEntries data |
	cm := cogMethod methodObject.
	nSlots := (objectMemory byteSizeOf: cm) - (self startPCOfMethod: cm) * 2 + objectMemory minSlotsForShortening.
	data := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: nSlots.
	data ifNil: [^-1].
	nEntries := cogit mapPCDataFor: cogMethod into: data.
	nEntries = 0 ifTrue:
		[^0].
	nEntries < nSlots ifTrue:
		[objectMemory shorten: data toIndexableSize: nEntries].
	^data
]

{ #category : #'method introspection support' }
CoInterpreterPrimitives >> picDataFor: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	| cm nSlots nEntries data |
	cm := cogMethod methodObject.
	nSlots := (objectMemory byteSizeOf: cm) - (self startPCOfMethod: cm) + objectMemory minSlotsForShortening.
	data := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: nSlots.
	data ifNil: [^-1].
	nEntries := cogit picDataFor: cogMethod into: data.
	nEntries = 0 ifTrue:
		[^0].
	nEntries < nSlots ifTrue:
		[objectMemory shorten: data toIndexableSize: nEntries].
	^data
]

{ #category : #'method introspection primitives' }
CoInterpreterPrimitives >> primitiveAllMethodsCompiledToMachineCode [
	<export: true>
	<option: #SistaCogit>
	| arrayObj nEntries maxNumEntries |
	argumentCount ~= 0 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	maxNumEntries := cogit numMethods + objectMemory minSlotsForShortening.
	arrayObj := objectMemory 
		instantiateClass: (objectMemory splObj: ClassArray) 
		indexableSize: maxNumEntries.
	arrayObj ifNil: [^-1].
	nEntries := cogit methodsCompiledToMachineCodeInto: arrayObj.
	(nEntries < maxNumEntries) ifTrue:
		[objectMemory shorten: arrayObj toIndexableSize: nEntries].
	self pop: 1 thenPush: arrayObj
]

{ #category : #'control primitives' }
CoInterpreterPrimitives >> primitiveClosureCopyWithCopiedValues [
	"This is optional old obsolete stuff tedious to implement in Cog because of
	 the need to map from machine code pc to bytecode pc.  So for now just fail."
	self primitiveFail
]

{ #category : #'process primitives' }
CoInterpreterPrimitives >> primitiveCollectCogCodeConstituents [
	"Answer the contents of the code zone as an array of pair-wise element, address in ascending
	 address order. Answer a string for a runtime routine or abstract label (beginning, end, etc),
	 a CompiledMethod for a CMMethod, or a selector (presumably a Symbol) for a PIC.
	 If there is an argument and it is true, then collect inner information about the CogMethod."
	| constituents withDetails |
	argumentCount = 0
		ifTrue: [withDetails := false]
		ifFalse:
			[withDetails := self stackTop.
			 (withDetails = objectMemory trueObject
			  or: [withDetails = objectMemory falseObject]) ifFalse:
				[^self primitiveFailFor: PrimErrBadArgument].
			  withDetails := withDetails = objectMemory trueObject].
	constituents := cogit cogCodeConstituents: withDetails.
	constituents ifNil:
		[^self primitiveFailFor: PrimErrNoMemory].
	self pop: argumentCount + 1 thenPush: constituents
]

{ #category : #'indexing primitives' }
CoInterpreterPrimitives >> primitiveContextXray [
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
	pc := objectMemory fetchPointer: InstructionPointerIndex ofObject: context.
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
	((objectMemory isIntegerObject: pc)
	 and: [(objectMemory integerValueOf: pc) < 0]) ifTrue:
		[flags := flags bitOr: 8].
	theMethod := objectMemory fetchPointer: MethodIndex ofObject: context.
	(self maybeMethodHasCogMethod: theMethod) ifTrue:
		[flags := flags bitOr: 16].
	self pop: 1 thenPush: (objectMemory integerObjectOf: flags)
]

{ #category : #'process primitives' }
CoInterpreterPrimitives >> primitiveEnterCriticalSection [
	"Attempt to enter a CriticalSection/Mutex.  If not owned, set the owner to the current
	 process and answer false. If owned by the current process  answer true.   Otherwise
	 suspend the process.  Answer if the receiver is owned by the current process."
	| criticalSection owningProcessIndex owningProcess activeProc inInterpreter |
	argumentCount > 0
		ifTrue:
			[criticalSection := self stackValue: 1.  "rcvr"
			 activeProc := self stackTop]
		ifFalse:
			[criticalSection := self stackTop.  "rcvr"
			 activeProc := self activeProcess].
	owningProcessIndex := ExcessSignalsIndex. "CriticalSections are laid out like Semaphores"
	owningProcess := objectMemory fetchPointer: owningProcessIndex ofObject: criticalSection.
	owningProcess = objectMemory nilObject ifTrue:
		[objectMemory storePointer: owningProcessIndex
			ofObject: criticalSection
			withValue: activeProc.
		 ^self pop: argumentCount + 1 thenPush: objectMemory falseObject].
	owningProcess = activeProc ifTrue:
		[^self pop: argumentCount + 1 thenPush: objectMemory trueObject].
	"Arrange to answer false (unowned) when the process is resumed."
	self pop: argumentCount + 1 thenPush: objectMemory falseObject.
	"We're going to switch process, either to an interpreted frame or a machine
	 code frame. To know whether to return or enter machine code we have to
	 know from whence we came.  We could have come from the interpreter,
	 either directly or via a machine code primitive.  We could have come from
	 machine code.  The instructionPointer tells us where from:"
	inInterpreter := instructionPointer >= objectMemory startOfMemory.
	self addLastLink: activeProc toList: criticalSection.
	self transferTo: self wakeHighestPriority from: CSEnterCriticalSection.
	self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter
]

{ #category : #'process primitives' }
CoInterpreterPrimitives >> primitiveExitCriticalSection [
	"Exit the critical section.
	 This may change the active process as a result."
	| criticalSection owningProcessIndex inInterpreter owningProcess |
	criticalSection := self stackTop.  "rcvr"
	owningProcessIndex := ExcessSignalsIndex. "CriticalSections are laid out like Semaphores"
	(self isEmptyList: criticalSection)
		ifTrue:
			[objectMemory storePointerUnchecked: owningProcessIndex
				ofObject: criticalSection
				withValue: objectMemory nilObject]
		ifFalse:
			["We're going to switch process, either to an interpreted frame or a machine
			  code frame. To know whether to return or enter machine code we have to
			  know from whence we came.  We could have come from the interpreter,
			  either directly or via a machine code primitive.  We could have come from
			  machine code.  The instructionPointer tells us where from:"
			 inInterpreter := instructionPointer >= objectMemory startOfMemory.
			 owningProcess := self removeFirstLinkOfList: criticalSection.
			 "store check unnecessary because aSemaphore referred to owningProcess
			  via its FirstLinkIndex slot before owningProcess was removed."
			 objectMemory storePointerUnchecked: owningProcessIndex
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
CoInterpreterPrimitives >> primitiveFlushCacheByMethod [
	"The receiver is a compiledMethod.  Clear all entries in the method lookup cache that
	 refer to this method, presumably because it has been redefined, overridden or removed.
	 Override to flush appropriate machine code caches also."
	super primitiveFlushCacheByMethod.
	cogit unlinkSendsTo: self stackTop andFreeIf: false
]

{ #category : #'system control primitives' }
CoInterpreterPrimitives >> primitiveFlushCacheBySelector [
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
	cogit
		unlinkSendsOf: selector
		isMNUSelector: (selector = (objectMemory splObj: SelectorDoesNotUnderstand))
]

{ #category : #'trampoline support' }
CoInterpreterPrimitives >> primitiveFunctionPointerAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: primitiveFunctionPointer) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #primitiveFunctionPointer in: self]
]

{ #category : #'process primitives' }
CoInterpreterPrimitives >> primitiveLongRunningPrimitiveSemaphore [
	"Primitive. Install the semaphore to be used for collecting long-running primitives, 
	 or nil if no semaphore should be used."
	| sema flushState activeContext |
	<export: true>
	self methodArgumentCount ~= 1 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	sema := self stackValue: 0.
	sema = objectMemory nilObject
		ifTrue:
			[flushState := longRunningPrimitiveCheckSemaphore notNil.
			 longRunningPrimitiveCheckSemaphore := nil]
		ifFalse:
			[flushState := longRunningPrimitiveCheckSemaphore isNil.
			 (objectMemory isSemaphoreOop: sema) ifFalse:
				[^self primitiveFailFor: PrimErrBadArgument].
			 longRunningPrimitiveCheckSemaphore := sema].
	"If we've switched checking on or off we must void machine code
	 (and machine code pcs in contexts) since we will start or stop setting
	 newMethod in machine code primitive invocations, and so generate
	 slightly different code from here on in."
	flushState ifTrue:
		[self push: instructionPointer.
		 activeContext := self voidVMStateForSnapshotFlushingExternalPrimitivesIf: false.
		 self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext.
		 self assert: (((self stackValue: 0) = objectMemory nilObject and: [longRunningPrimitiveCheckSemaphore isNil])
				  or: [(self stackValue: 0) = longRunningPrimitiveCheckSemaphore
					  and: [objectMemory isSemaphoreOop: sema]])].
	self voidLongRunningPrimitive: 'install'.
	self pop: 1.
	flushState ifTrue:
		[self siglong: reenterInterpreter jmp: ReturnToInterpreter]
]

{ #category : #'method introspection primitives' }
CoInterpreterPrimitives >> primitiveMethodPCData [
	<export: true>
	| methodReceiver data |
	argumentCount ~= 0 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	methodReceiver := self stackTop.
	data := 0.
	(self methodHasCogMethod: methodReceiver) ifTrue:
		[data := self pcDataFor: (self cogMethodOf: methodReceiver).
		 data = -1 ifTrue:
			[^self primitiveFailFor: PrimErrNoMemory]].
	data = 0 ifTrue:
		[data := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 0].
	self pop: 1 thenPush: data
]

{ #category : #'indexing primitives' }
CoInterpreterPrimitives >> primitiveMethodXray [
	"Lift the veil from a method and answer an integer describing the interior state
	 of its machine code.
	 Used for e.g. VM tests so they can verify they're testing what they think they're testing.
	 0 implies a vanilla method.
	 Bit 0 = method might be compiled to machine code
	 Bit 1 = method is currently compiled to machine code
	 Bit 2 = is compiled frameless.
	 Bit 3 = method refers to young object.
	 Bit 4 = method too big to be jitted (more than 64k of code, or needs more than 1.5Mb of stack space to compile)
	 Bit 5 = method contains unknown/unjittable bytecode
	 Bit 6 = method should not be jitted because it contains a primitive not to be called from machine code (unused)"
	| alreadyCogged flags cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	(self methodWithHeaderShouldBeCogged: (objectMemory methodHeaderOf: self stackTop))
		ifTrue:
			[alreadyCogged := self maybeMethodHasCogMethod: self stackTop.
			 flags := 1.
			 alreadyCogged ifFalse:
				[cogMethod := cogit cog: self stackTop selector: objectMemory nilObject.
				 (cogMethod = nil
				  and: [cogCompiledCodeCompactionCalledFor]) ifTrue:
					[self commenceCogCompiledCodeCompaction.
					 cogMethod := cogit cog: self stackTop selector: objectMemory nilObject].
			 cogMethod asInteger
				caseOf: {
					[MethodTooBig] -> [flags := 1 + 16].
					[EncounteredUnknownBytecode] -> [flags := 1 + 32].
					[ShouldNotJIT] -> [flags := 1 + 64] }
				otherwise: [self deny: (cogMethod asInteger between: MaxNegativeErrorCode and: NotFullyInitialized)]].
			 (flags = 1
			  and: [self maybeMethodHasCogMethod: self stackTop]) ifTrue:
				[cogMethod := self cogMethodOf: self stackTop.
				 flags := cogMethod stackCheckOffset = 0 ifTrue: [7] ifFalse: [3].
				 cogMethod cmRefersToYoung ifTrue:
					[flags := flags + 8].
				 alreadyCogged ifFalse:
					[cogit freeMethod: cogMethod]]]
		ifFalse: [flags := 0].
	self pop: 1 thenPush: (objectMemory integerObjectOf: flags)
]

{ #category : #'other primitives' }
CoInterpreterPrimitives >> primitiveMinimumUnusedHeadroom [
	<export: true>
	self methodReturnValue: (self integerObjectOf: self minimumUnusedHeadroom)
]

{ #category : #'object access primitives' }
CoInterpreterPrimitives >> primitiveObjectAt [
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
	 and: [index <= ((objectMemory literalCountOfMethodHeader: realHeader) + LiteralStart)]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	self pop: 2
		thenPush: (index = 1
					ifTrue: [realHeader]
					ifFalse: [objectMemory fetchPointer: index - 1 ofObject: thisReceiver])
]

{ #category : #'object access primitives' }
CoInterpreterPrimitives >> primitiveObjectAtPut [
	"Store a literal into a CompiledMethod at the given index. Defined for CompiledMethods only."
	| thisReceiver rawHeader realHeader index newValue |
	newValue := self stackValue: 0.
	index := self stackValue: 1.
	(objectMemory isNonIntegerObject: index) ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: index.
	thisReceiver := self stackValue: 2.
	(objectMemory isObjImmutable: thisReceiver) ifTrue:
		[^self primitiveFailFor: PrimErrNoModification].
	rawHeader := self rawHeaderOf: thisReceiver.
	realHeader := (self isCogMethodReference: rawHeader)
					ifTrue: [(self cCoerceSimple: rawHeader to: #'CogMethod *') methodHeader]
					ifFalse: [rawHeader].
	(index > 0
	 and: [index <= ((objectMemory literalCountOfMethodHeader: realHeader) + LiteralStart)]) ifFalse:
		[^self primitiveFailFor: PrimErrBadIndex].
	index = 1
		ifTrue:
			[((objectMemory isNonIntegerObject: newValue)
			 or: [(objectMemory literalCountOfMethodHeader: newValue) ~= (objectMemory literalCountOfMethodHeader: realHeader)]) ifTrue:
				[^self primitiveFailFor: PrimErrBadArgument].
			 (self isCogMethodReference: rawHeader)
				ifTrue: [(self cCoerceSimple: rawHeader to: #'CogMethod *') methodHeader: newValue]
				ifFalse: [objectMemory storePointerUnchecked: 0 ofObject: thisReceiver withValue: newValue]]
		ifFalse:
			[objectMemory storePointer: index - 1 ofObject: thisReceiver withValue: newValue].
	self pop: 3 thenPush: newValue
]

{ #category : #'process primitives' }
CoInterpreterPrimitives >> primitiveProfileSemaphore [
	"Primitive. Install the semaphore to be used for profiling, 
	or nil if no semaphore should be used.
	See also primitiveProfileStart."
	| sema flushState activeContext |
	<export: true>
	self methodArgumentCount ~= 1 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	sema := self stackValue: 0.
	sema = objectMemory nilObject
		ifTrue:
			[flushState := profileSemaphore ~= objectMemory nilObject]
		ifFalse:
			[flushState := profileSemaphore = objectMemory nilObject.
			 (objectMemory isSemaphoreOop: sema) ifFalse:
				[^self primitiveFailFor: PrimErrBadArgument]].
	profileSemaphore := sema.
	"If we've switched profiling on or off we must void machine code
	 (and machine code pcs in contexts) since we will start or stop
	 testing the profile clock in machine code primitive invocations,
	 and so generate slightly different code from here on in."
	flushState ifTrue:
		[self push: instructionPointer.
		 activeContext := self voidVMStateForSnapshotFlushingExternalPrimitivesIf: false.
		 self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext.
		 self assert: (((self stackValue: 0) = objectMemory nilObject and: [profileSemaphore = objectMemory nilObject])
				  or: [(self stackValue: 0) = profileSemaphore
					  and: [objectMemory isSemaphoreOop: sema]])].
	profileProcess := profileMethod := objectMemory nilObject.
	self pop: 1.
	flushState ifTrue:
		[self siglong: reenterInterpreter jmp: ReturnToInterpreter]
]

{ #category : #'method introspection primitives' }
CoInterpreterPrimitives >> primitiveResetCountersInMethod [
	<export: true>
	<option: #SistaCogit>
	| methodReceiver |
	argumentCount ~= 0 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	methodReceiver := self stackTop.
	(self methodHasCogMethod: methodReceiver) ifTrue:
		[cogit resetCountersIn: (self cogMethodOf: methodReceiver)]
]

{ #category : #'process primitives' }
CoInterpreterPrimitives >> primitiveResume [
	"Put this process on the scheduler's lists thus allowing it to proceed next time there is
	 a chance for processes of it's priority level.  It must go to the back of its run queue so
	 as not to preempt any already running processes at this level.  If the process's priority
	 is higher than the current process, preempt the current process."
	| proc inInterpreter |
	proc := self stackTop.  "rcvr"
	(objectMemory isContext: (objectMemory followField: SuspendedContextIndex ofObject: proc)) ifFalse:
		[^self primitiveFail].
	"We're about to switch process, either to an interpreted frame or a
	 machine code frame. To know whether to return or enter machine code
	 we have to know from whence we came.  We could have come from the
	 interpreter, either directly or via a machine code primitive.  We could have
	 come from machine code.  The instructionPointer tells us where from:"
	inInterpreter := instructionPointer >= objectMemory startOfMemory.
	(self resume: proc preemptedYieldingIf: preemptionYields from: CSResume) ifTrue:
		[self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter]

	"Personally I would like to check MyList, which should not be one of the elements of the scheduler lists.
	 But there are awful race conditions in things like should:notTakeMoreThan: that mean we can't.
	 eem 9/27/2010 23:08. e.g.

	| proc myList classLinkedList |
	proc := self stackTop.
	myList := objectMemory fetchPointer: MyListIndex ofObject: proc.
	classLinkedList := self superclassOf: (objectMemory splObj: ClassSemaphore).
	((self fetchClassOfNonInt: myList) ~= classLinkedList
	and: [objectMemory isContext: (objectMemory fetchPointer: SuspendedContextIndex ofObject: proc)]) ifFalse:
		[^self primitiveFail].
	''We're about to switch process, either to an interpreted frame or a
	 machine code frame. To know whether to return or enter machine code
	 we have to know from whence we came.  We could have come from the
	 interpreter, either directly or via a machine code primitive.  We could have
	 come from machine code.  The instructionPointer tells us where from:''
	inInterpreter := instructionPointer >= objectMemory startOfMemory.
	(self resume: proc  preemptedYieldingIf: preemptionYields from: CSResume) ifTrue:
		[self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter]"
]

{ #category : #'process primitives' }
CoInterpreterPrimitives >> primitiveSignal [
	"Synchronously signal the semaphore.
	 This may change the active process as a result."
	| inInterpreter |
	"We may be about to switch process, either to an interpreted frame or a
	 machine code frame. To know whether to return or enter machine code
	 we have to know from whence we came.  We could have come from the
	 interpreter, either directly or via a machine code primitive.  We could have
	 come from machine code.  The instructionPointer tells us where from:"
	inInterpreter := instructionPointer >= objectMemory startOfMemory.
	(self synchronousSignal: self stackTop) ifTrue:
		[self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter]
]

{ #category : #'method introspection primitives' }
CoInterpreterPrimitives >> primitiveSistaMethodPICAndCounterData [
	<export: true>
	<option: #SistaCogit>
	| methodReceiver data |
	argumentCount ~= 0 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	methodReceiver := self stackTop.
	data := 0.
	(self methodHasCogMethod: methodReceiver) ifTrue:
		[data := self picDataFor: (self cogMethodOf: methodReceiver).
		 data = -1 ifTrue:
			[^self primitiveFailFor: PrimErrNoMemory]].
	data = 0 ifTrue:
		[data := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 0].
	self pop: 1 thenPush: data
]

{ #category : #'system control primitives' }
CoInterpreterPrimitives >> primitiveSnapshot [
	"Save a normal snapshot under the same name as it was loaded
	 unless it has been renamed by the last primitiveImageName.

	 Override to jump to the interpreter because the machine code zone is now void."
	<inline: false>
	self snapshot: false.
	(self iframeMethod: framePointer) = newMethod ifTrue:
		["snapshot: has reached the end and built a frame.
		 In the JIT we need to back-up the pc before reentering the interpreter."
		instructionPointer := instructionPointer - 1].
	self siglong: reenterInterpreter jmp: ReturnToInterpreter
	"NOTREACHED"
]

{ #category : #'system control primitives' }
CoInterpreterPrimitives >> primitiveSnapshotEmbedded [
	"Save an embedded snapshot.

	 Override to jump to the interpreter because the machine code zone is now void."
	<inline: false>
	self snapshot: true.
	(self iframeMethod: framePointer) = newMethod ifTrue:
		["snapshot: has reached the end and built a frame.
		 In the JIT we need to back-up the pc before reentering the interpreter."
		instructionPointer := instructionPointer - 1].
	self siglong: reenterInterpreter jmp: ReturnToInterpreter
	"NOTREACHED"
]

{ #category : #'process primitives' }
CoInterpreterPrimitives >> primitiveSuspend [
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
		self pop: 1 thenPush: objectMemory nilObject.
		inInterpreter := instructionPointer >= objectMemory startOfMemory.
		self transferTo: self wakeHighestPriority from: CSSuspend.
		^self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter].
	myList := objectMemory fetchPointer: MyListIndex ofObject: process.
	"XXXX Fixme. We should really check whether myList is a kind of LinkedList or not
	but we can't easily so just do a quick check for nil which is the most common case."
	myList = objectMemory nilObject ifTrue:
		[^self primitiveFailFor: PrimErrBadReceiver].
	"Alas in Spur we need a read barrier"
	(objectMemory isForwarded: myList) ifTrue:
		[myList := objectMemory followForwarded: myList.
		 objectMemory storePointer: MyListIndex ofObject: process withValue: myList].
	self removeProcess: process fromList: myList.
	self successful ifTrue:
		[objectMemory storePointer: MyListIndex ofObject: process withValue: objectMemory nilObject.
		 self pop: 1 thenPush: myList]
]

{ #category : #'control primitives' }
CoInterpreterPrimitives >> primitiveTerminateTo [
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
	(aContextOrNil = objectMemory nilObject or: [objectMemory isContext: aContextOrNil]) ifFalse:
		[^self primitiveFail].
	thisCtx := self stackValue: 1.
	thisCtx = aContextOrNil ifTrue:
		[^self primitiveFail].		

	"All stackPages need to have current head pointers to avoid confusion."
	self externalWriteBackHeadFramePointers.

	"If we're searching for aContextOrNil it might be on a stack page.  Helps to know
	 if we can free a whole page or not, or if we can short-cut the termination."
	(aContextOrNil ~= objectMemory nilObject and: [self isStillMarriedContext: aContextOrNil])
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
				[self assertValidStackedInstructionPointersIn: stackPage line: #'__LINE__'.
				 (self frameCallerFP: theFP) ~= contextsFP ifTrue:
					[stackedReceiverOffset := self frameStackedReceiverOffset: theFP.
					 frameAbove := self findFrameAbove: contextsFP inPage: pageToStopOn.
					 contextsIP := (self frameCallerSavedIP: frameAbove) asUnsignedInteger.
					 self assert: ((contextsIP asUnsignedInteger >= objectMemory startOfMemory)
								or: [contextsIP = cogit ceReturnToInterpreterPC]) == (self isMachineCodeFrame: contextsFP) not.
					 newSP := self frameCallerSP: frameAbove.
					 newFP := newSP - stackedReceiverOffset - objectMemory wordSize.
					 theFP + stackedReceiverOffset
						to: stackPointer
						by: objectMemory wordSize negated
						do: [:source|
							newSP := newSP - objectMemory wordSize.
							stackPages longAt: newSP put: (stackPages longAt: source)].
					 stackPages longAt: newFP + FoxSavedFP put: contextsFP.
					"Ensure contract between machine-code callee and interpreter caller frames is preserved.
					 Return pc needs to be ceReturnToInterpreterPC."
					 ((self isMachineCodeFrame: newFP)
					  and: [contextsIP >= objectMemory startOfMemory]) ifTrue:
						[self iframeSavedIP: contextsFP put: contextsIP.
						 contextsIP := cogit ceReturnToInterpreterPC].
					 stackPages longAt: newFP + FoxCallerSavedIP put: contextsIP.
					 self assert: (objectMemory isContext: thisCtx).
					 objectMemory storePointerUnchecked: SenderIndex
						ofObject: thisCtx
						withValue: (self withSmallIntegerTags: newFP).
					 objectMemory storePointerUnchecked: InstructionPointerIndex
						ofObject: thisCtx
						withValue: (self withSmallIntegerTags: contextsFP).
					 framePointer := newFP.
					 stackPointer := newSP].
				 self pop: 1.
				 self assertValidStackedInstructionPointersIn: stackPage line: #'__LINE__'.
				 self assert: stackPage = stackPages mostRecentlyUsedPage.
				 ^nil].
			 self assertValidStackedInstructionPointers: #'__LINE__'.
			 theFP := self externalEnsureIsBaseFrame: theFP. "May cause a GC!!"
			 currentCtx := self frameCallerContext: theFP.
			 "May also reclaim aContextOrNil's page, hence..."
			 (aContextOrNil ~= objectMemory nilObject and: [self isStillMarriedContext: aContextOrNil])
				ifTrue: [contextsFP := self frameOfMarriedContext: aContextOrNil.
						pageToStopOn := stackPages stackPageFor: contextsFP]
				ifFalse: [pageToStopOn := 0]]
		ifFalse:
			[currentCtx := objectMemory fetchPointer: SenderIndex ofObject: thisCtx].

	self assertValidStackedInstructionPointers: #'__LINE__'.
	(self context: thisCtx hasSender: aContextOrNil) ifTrue:
		["Need to walk the stack freeing stack pages and nilling contexts."
		[currentCtx = aContextOrNil
		 or: [currentCtx = objectMemory nilObject]] whileFalse:
			[self assert: (objectMemory isContext: currentCtx).
			 (self isMarriedOrWidowedContext: currentCtx)
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
							(aContextOrNil ~= objectMemory nilObject and: [self isStillMarriedContext: aContextOrNil])
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
										[contextsSP := (self frameCallerSP: frameAbove) - objectMemory wordSize.
										 stackPages longAt: contextsSP put: (self frameCallerSavedIP: frameAbove).
										 self setHeadFP: contextsFP andSP: contextsSP inPage: thePage].
									 currentCtx := aContextOrNil]
								ifFalse:
									["We can free the entire page without further ado."
									 currentCtx := self frameCallerContext: thePage baseFP.
									 "for a short time invariant is violated; assert follows"
									 stackPages freeStackPageNoAssert: thePage]]]
				ifFalse:
					[nextCntx := objectMemory fetchPointer: SenderIndex ofObject: currentCtx.
					 self markContextAsDead: currentCtx.
					 currentCtx := nextCntx]]].
	self assert: stackPages pageListIsWellFormed.
	(self isMarriedOrWidowedContext: thisCtx)
		ifTrue:
			[self assert: (self checkIsStillMarriedContext: thisCtx currentFP: framePointer).
			 self assert: (self isBaseFrame: (self frameOfMarriedContext: thisCtx)).
			 theFP := self frameOfMarriedContext: thisCtx.
			 self frameCallerContext: theFP put: aContextOrNil]
		ifFalse:
			[objectMemory storePointer: SenderIndex ofObject: thisCtx withValue: aContextOrNil].
	self pop: 1.
	self assertValidStackedInstructionPointers: #'__LINE__'.
	self assert: stackPage = stackPages mostRecentlyUsedPage
]

{ #category : #'system control primitives' }
CoInterpreterPrimitives >> primitiveVoidVMState [
	"Void all internal VM state in the stack and machine code zones

	 Override to jump to the interpreter because the machine code zone is now void."
	| activeContext |
	self push: instructionPointer.
	activeContext := self voidVMStateForSnapshotFlushingExternalPrimitivesIf: false.
	self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext.
	self siglong: reenterInterpreter jmp: ReturnToInterpreter
	"NOTREACHED"
]

{ #category : #'system control primitives' }
CoInterpreterPrimitives >> primitiveVoidVMStateForMethod [
	"The receiver (or first argument) must be a compiledMethod.  The optional (or second) argument must be a
	 boolean. Clear all VM state associated with the method, including any machine code, or machine code pcs
	 in context objects.  If the optional boolean argument is false do not scan the heap looking for contexts."
	| activeContext methodObj scanHeapForContexts hasCogMethod theFrame thePage |
	<var: #theFrame type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	scanHeapForContexts := true. "See comment ''One might think...'' below"
	"In Smalltalk allow both aMethod voidCogVMState and aMethod voidCogVMStateScanningContextsIf: aBoolean"
	argumentCount = 0
		ifTrue:
			[methodObj := self stackTop]
		ifFalse:
			[methodObj := self stackValue: 1.
			 scanHeapForContexts := self booleanValueOf: self stackTop.
			 self failed ifTrue:
				[^self primitiveFailFor: PrimErrBadArgument]].
	argumentCount > 1 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	self flushMethodCacheForMethod: methodObj.
	activeContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
	self ensurePushedInstructionPointer.
	self externalWriteBackHeadFramePointers.
	(hasCogMethod := self methodHasCogMethod: methodObj) ifTrue:
		[self divorceMachineCodeFramesWithMethod: methodObj].
	"One might think (as this author did) that the heap scan is unnecessary if the method does not
	 have a cog method.  But it could be the case that the code zone has recently been reclaimed
	 and so not having a cog method is no indication that it didn't have a cog method some time in
	 the recent past, and that there are indeed still contexts with machine code pcs out there.  The
	 only steps that can be avoided are divorcing frames in the stack zone, and scanning to unlink and
	 free if there isn't a cog method, unless we are told otherwise."
	scanHeapForContexts ifTrue:
		[self ensureAllContextsWithMethodHaveBytecodePCs: methodObj].
	hasCogMethod ifTrue:
		[cogit unlinkSendsTo: methodObj andFreeIf: true].

	"If flushing led to divorce continue in the interpreter."
	(self isStillMarriedContext: activeContext) ifFalse:
		[self zeroStackPage. "to avoid assert in marryContextInNewStackPageAndInitializeInterpreterRegisters:"
		 self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext.
		 self popStack. "pop bogus machine-code instructionPointer"
		 self assert: (methodObj = self stackTop or: [argumentCount > 0 and: [methodObj = (self stackValue: 1)]]).
		 self pop: argumentCount.
		 self siglong: reenterInterpreter jmp: ReturnToInterpreter.
		 "NOTREACHED"].
	"If not, work out where we are and continue"
	theFrame := self frameOfMarriedContext: activeContext.
	thePage := stackPages stackPageFor: theFrame.
	self assert: thePage headFP = theFrame.
	self setStackPageAndLimit: thePage.
	self setStackPointersFromPage: thePage.
	instructionPointer := self popStack.
	self assert: (methodObj = self stackTop or: [argumentCount > 0 and: [methodObj = (self stackValue: 1)]]).
	self pop: argumentCount
]

{ #category : #'process primitives' }
CoInterpreterPrimitives >> primitiveYield [
"primitively do the equivalent of Process>yield"
	| scheduler activeProc priority processLists processList inInterpreter |
	scheduler := self schedulerPointer.
	activeProc := objectMemory fetchPointer: ActiveProcessIndex ofObject: scheduler.
	priority := self quickFetchInteger: PriorityIndex ofObject: activeProc.
	processLists := objectMemory fetchPointer: ProcessListsIndex ofObject: scheduler.
	processList := objectMemory fetchPointer: priority - 1 ofObject: processLists.

	(self isEmptyList: processList) ifTrue:
		[^nil].
	"We're going to switch process, either to an interpreted frame or a machine
	 code frame. To know whether to return or enter machine code we have to
	 know from whence we came.  We could have come from the interpreter,
	 either directly or via a machine code primitive.  We could have come from
	 machine code.  The instructionPointer tells us where from:"
	inInterpreter := instructionPointer >= objectMemory startOfMemory.
	self addLastLink: activeProc toList: processList.
	self transferTo: self wakeHighestPriority from: CSYield.
	self forProcessPrimitiveReturnToExecutivePostContextSwitch: inInterpreter
]

{ #category : #'object access primitives' }
CoInterpreterPrimitives >> unmarkAllFrames [
	| thePage theFP methodField flags |
	<var: #thePage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<inline: false>
	0 to: numStackPages - 1 do:
		[:i|
		thePage := stackPages stackPageAt: i.
		(stackPages isFree: thePage) ifFalse:
			[theFP := thePage  headFP.
			 [methodField := stackPages longAt: theFP + FoxMethod.
			 methodField asUnsignedInteger < objectMemory startOfMemory
				ifTrue:
					[(methodField bitAnd: 4) ~= 0 ifTrue:
						[self longAt: theFP + FoxMethod put: methodField - 4]]
				ifFalse:
					[flags := stackPages longAt: theFP + FoxIFrameFlags.
					  (flags bitAnd: 2) ~= 0 ifTrue:
						[stackPages longAt: theFP + FoxIFrameFlags put: flags - 2]].
			  (theFP := self frameCallerFP: theFP) ~= 0] whileTrue]]
]
