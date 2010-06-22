Class {
	#name : #SchizophrenicClosureFormatStackInterpreter,
	#superclass : #StackInterpreter,
	#category : #'VMMaker-Interpreter'
}

{ #category : #translation }
SchizophrenicClosureFormatStackInterpreter class >> declareCVarsIn: aCCodeGenerator [
]

{ #category : #translation }
SchizophrenicClosureFormatStackInterpreter class >> prepareToBeAddedToCodeGenerator: aCodeGen [
	"Remove the methods of StackInterpreter we override"
	self selectors do:
		[:sel|
		 (StackInterpreter includesSelector: sel) ifTrue:
			[aCodeGen removeMethodForSelector: sel]]
]

{ #category : #'control primitives' }
SchizophrenicClosureFormatStackInterpreter >> activateNewClosureMethod: blockClosure numArgs: numArgs mayContextSwitch: mayContextSwitch [
	"Similar to activateNewMethod but for Closure and newMethod."
	| copiedValues numCopied outerContext theMethod closureIP instSpec |
	<inline: true>
	outerContext := self fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	(instSpec := self formatOf: blockClosure) = 1 "is it in the old format?"
		ifTrue: "old format"
			[copiedValues := self fetchPointer: ClosureCopiedValuesIndex ofObject: blockClosure.
			 "Should evaluate to 0 for nilObj"
			 numCopied := self fetchWordLengthOf: copiedValues]
		ifFalse:
			[numCopied := (self copiedValueCountOfClosure: blockClosure)].

	theMethod := self fetchPointer: MethodIndex ofObject: outerContext.
	self push: instructionPointer.
	self push: framePointer.
	framePointer := stackPointer.
	self push: theMethod.
	self push: (self encodeFrameFieldHasContext: false isBlock: true numArgs: numArgs).
	self push: nilObj. "FxThisContext field"
	self push: (self fetchPointer: ReceiverIndex ofObject: outerContext).

	"Copy the copied values..."
	instSpec = 1
		ifTrue: "old format"
			[0 to: numCopied - 1 do:
				[:i|
				self push: (self fetchPointer: i ofObject: copiedValues)]]
		ifFalse:
			[0 to: numCopied - 1 do:
				[:i|
				self push: (self
							fetchPointer: i + ClosureFirstCopiedValueIndex
							ofObject: blockClosure)]].

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
	stackPointer < stackLimit ifTrue:
		[self handleStackOverflowOrEventAllowContextSwitch: mayContextSwitch]
]

{ #category : #'control primitives' }
SchizophrenicClosureFormatStackInterpreter >> closureOLDIn: context numArgs: numArgs instructionPointer: initialIP copiedValues: copiedValues [
	| newClosure |
	<inline: true>
	newClosure := self
					eeInstantiateSmallClass: (self splObj: ClassBlockClosure)
					sizeInBytes: (BytesPerWord * 4) + BaseHeaderSize.
	"Assume: have just allocated a new closure; it must be young. Thus, can use unchecked stores."
	self storePointerUnchecked: ClosureOuterContextIndex ofObject: newClosure withValue: context.
	self storePointerUnchecked: ClosureStartPCIndex ofObject: newClosure withValue: (self integerObjectOf: initialIP).
	self storePointerUnchecked: ClosureNumArgsIndex ofObject: newClosure withValue: (self integerObjectOf: numArgs).
	self storePointerUnchecked: ClosureCopiedValuesIndex ofObject: newClosure withValue: copiedValues.
	^newClosure
]

{ #category : #'image save/restore' }
SchizophrenicClosureFormatStackInterpreter >> imageFormatCompatibilityVersion [
	"This VM is backward-compatible with the immediately preceeding non-closure version."

	BytesPerWord == 4
		ifTrue: [^6503]
		ifFalse: [^68000]
]

{ #category : #'image save/restore' }
SchizophrenicClosureFormatStackInterpreter >> imageFormatVersion [
	"Return a magic constant that changes when the image format changes. Since the image reading code uses this to detect byte ordering, one must avoid version numbers that are invariant under byte reversal."

	BytesPerWord == 4
		ifTrue: [^6504]
		ifFalse: [^68002]
]

{ #category : #'control primitives' }
SchizophrenicClosureFormatStackInterpreter >> primitiveClosureCopyWithCopiedValues [
	| newClosure numArgs |
	numArgs := self stackIntegerValue: 1.
	self successful ifFalse:
		[^self primitiveFail].

	(self instSpecOfClass: (self splObj: ClassBlockClosure)) = 1
		ifTrue:
			[newClosure := self
							closureOLDIn: (self stackValue: 2)
							numArgs: numArgs
									"greater by 1 due to preIncrement of localIP"
							instructionPointer: instructionPointer + 2 - (method+BaseHeaderSize)
							copiedValues: self stackTop]
		ifFalse:
			[newClosure := self
							closureIn: (self stackValue: 2)
							numArgs: numArgs
									"greater by 1 due to preIncrement of localIP"
							instructionPointer: instructionPointer + 2 - (method+BaseHeaderSize)
							copiedValues: self stackTop].
	self pop: 3 thenPush: newClosure
]

{ #category : #'control primitives' }
SchizophrenicClosureFormatStackInterpreter >> primitiveClosureValue [
	| blockClosure numArgs closureMethod copiedValues outerContext |
	blockClosure := self stackValue: argumentCount.
	numArgs := self argumentCountOfClosure: blockClosure.
	argumentCount = numArgs ifFalse:
		[^self primitiveFail].

	"Somewhat paranoiac checks we need while debugging that we may be able to discard
	 in a robust system."
	outerContext := self fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	(self isContext: outerContext) ifFalse:
		[^self primitiveFail].
	closureMethod := self fetchPointer: MethodIndex ofObject: outerContext.
	"Check if the closure's method is actually a CompiledMethod."
	((self isNonIntegerObject: closureMethod) and: [self isCompiledMethod: closureMethod]) ifFalse:
		[^self primitiveFail].
	(self formatOf: blockClosure) = 1 "old format" ifTrue:
		["Check if copiedValues is either nil or anArray."
		copiedValues := self fetchPointer: ClosureCopiedValuesIndex ofObject: blockClosure.
		(copiedValues == nilObj or: [(self fetchClassOf: copiedValues) = (self splObj: ClassArray)]) ifFalse:
			[^self primitiveFail]].

	"Note we use activateNewMethod, not executeNewMethodFromCache, to
	 avoid quickCheckForInterrupts.  Don't check until we have a full activation."
	self activateNewClosureMethod: blockClosure numArgs: numArgs mayContextSwitch: true
]

{ #category : #'control primitives' }
SchizophrenicClosureFormatStackInterpreter >> primitiveClosureValueNoContextSwitch [
	"An exact clone of primitiveClosureValue except that this version will not
	 check for interrupts on stack overflow.  It may invoke the garbage collector
	 but will not switch processes.  See checkForInterruptsMayContextSwitch:"
	| blockClosure numArgs closureMethod copiedValues outerContext |
	blockClosure := self stackValue: argumentCount.
	numArgs := self argumentCountOfClosure: blockClosure.
	argumentCount = numArgs ifFalse:
		[^self primitiveFail].

	"Somewhat paranoiac checks we need while debugging that we may be able to discard
	 in a robust system."
	outerContext := self fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	(self isContext: outerContext) ifFalse:
		[^self primitiveFail].
	closureMethod := self fetchPointer: MethodIndex ofObject: outerContext.
	"Check if the closure's method is actually a CompiledMethod."
	((self isNonIntegerObject: closureMethod) and: [self isCompiledMethod: closureMethod]) ifFalse:
		[^self primitiveFail].
	(self formatOf: blockClosure) = 1 "old format" ifTrue:
		["Check if copiedValues is either nil or anArray."
		copiedValues := self fetchPointer: ClosureCopiedValuesIndex ofObject: blockClosure.
		(copiedValues == nilObj or: [(self fetchClassOf: copiedValues) = (self splObj: ClassArray)]) ifFalse:
			[^self primitiveFail]].

	"Note we use activateNewMethod, not executeNewMethodFromCache, to
	 avoid quickCheckForInterrupts.  Don't check until we have a full activation."
	self activateNewClosureMethod: blockClosure numArgs: numArgs mayContextSwitch: false
]

{ #category : #'control primitives' }
SchizophrenicClosureFormatStackInterpreter >> primitiveClosureValueWithArgs [
	| argumentArray arraySize blockClosure numArgs closureMethod index copiedValues outerContext |
	argumentArray := self stackTop.
	(self isArray: argumentArray) ifFalse:
		[^self primitiveFail].

	"Check for enough space in thisContext to push all args"
	arraySize := self fetchWordLengthOf: argumentArray.
	(self roomToPushNArgs: arraySize) ifFalse:
		[^self primitiveFail].

	blockClosure := self stackValue: argumentCount.
	numArgs := self argumentCountOfClosure: blockClosure.
	arraySize = numArgs ifFalse:
		[^self primitiveFail].

	"Somewhat paranoiac checks we need while debugging that we may be able to discard
	 in a robust system."
	outerContext := self fetchPointer: ClosureOuterContextIndex ofObject: blockClosure.
	(self isContext: outerContext) ifFalse:
		[^self primitiveFail].
	closureMethod := self fetchPointer: MethodIndex ofObject: outerContext.
	"Check if the closure's method is actually a CompiledMethod."
	((self isNonIntegerObject: closureMethod) and: [self isCompiledMethod: closureMethod]) ifFalse:
		[^self primitiveFail].
	(self formatOf: blockClosure) = 1 "old format" ifTrue:
		["Check if copiedValues is either nil or anArray."
		copiedValues := self fetchPointer: ClosureCopiedValuesIndex ofObject: blockClosure.
		(copiedValues == nilObj or: [(self fetchClassOf: copiedValues) = (self splObj: ClassArray)]) ifFalse:
			[^self primitiveFail]].

	self popStack.

	"Copy the arguments to the stack, and activate"
	index := 1.
	[index <= numArgs]
		whileTrue:
		[self push: (self fetchPointer: index - 1 ofObject: argumentArray).
		index := index + 1].

	"Note we use activateNewMethod, not executeNewMethodFromCache, to
	 avoid quickCheckForInterrupts.  Don't check until we have a full activation."
	self activateNewClosureMethod: blockClosure numArgs: numArgs mayContextSwitch: true
]

{ #category : #'stack bytecodes' }
SchizophrenicClosureFormatStackInterpreter >> pushClosureCopyCopiedValuesBytecode [
	"The compiler has pushed the values to be copied, if any.  Find numArgs and numCopied in the byte following.
	 Pop numCopied values off the stack into an Array (or use nil if none).  Create a Closure with the copiedValues
	 and numArgs so specified, starting at the pc following the block size and jump over that code."
	| newClosure numArgsNumCopied numArgs numCopied blockSize context |
	(self instSpecOfClass: (self splObj: ClassBlockClosure)) = 1 ifTrue:
		[^self pushClosureCopyCopiedValuesBytecodeOLD].
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
SchizophrenicClosureFormatStackInterpreter >> pushClosureCopyCopiedValuesBytecodeOLD [
	"The compiler has pushed the values to be copied, if any.  Find numArgs and numCopied in the byte following.
	 Pop numCopied values off the stack into an Array (or use nil if none).  Create a Closure with the copiedValues
	 and numArgs so specified, starting at the pc following the block size and jump over that code."
	| newClosure numArgsNumCopied numArgs numCopied copiedValues blockSize context |
	numArgsNumCopied := self fetchByte.
	numArgs := numArgsNumCopied bitAnd: 16rF.
	numCopied := numArgsNumCopied bitShift: -4.
	numCopied > 0
		ifTrue:
			["self assert: numCopied * BytesPerWord <= 252."
			 copiedValues := self
								eeInstantiateSmallClass: (self splObj: ClassArray)
								sizeInBytes: (numCopied * BytesPerWord) + BaseHeaderSize.
			 0 to: numCopied - 1 do:
				[:i|
				"Assume: have just allocated a new Array; it must be young. Thus, can use unchecked stores."
				self storePointerUnchecked: i ofObject: copiedValues withValue: (self internalStackValue: numCopied - i - 1)].
			 self internalPop: numCopied]
		ifFalse:
			[copiedValues := nilObj].
	"Split blockSize := (self fetchByte * 256) + self fetchByte. into two because evaluation order in C is undefined."
	blockSize := self fetchByte << 8.
	blockSize := blockSize + self fetchByte.
	context := self ensureFrameIsMarried: localFP SP: localSP.
	newClosure := self
					closureOLDIn: context
					numArgs: numArgs
					instructionPointer: ((self cCoerce: localIP to: 'sqInt') + 2 - (method+BaseHeaderSize))
					copiedValues: copiedValues.
	localIP := localIP + blockSize.
	self fetchNextBytecode.
	self internalPush: newClosure
]

{ #category : #'image save/restore' }
SchizophrenicClosureFormatStackInterpreter >> readableFormat: imageVersion [
	"Anwer true if images of the given format are readable by this interpreter. Allows a virtual machine to accept selected older image formats."

	^ imageVersion = self imageFormatVersion
	or: [imageVersion = self imageFormatCompatibilityVersion]

	"Example of multiple formats:
	^ (imageVersion = self imageFormatVersion) or: [imageVersion = 6504]"
]
