"
This plugin implements the Alien foreign-function interface, a small elaboration on the Strongtalk FFI.

Call-outs are performed by a small number of primitives, one each for the four different kinds of return linkage on x86.  The primitives are var-args.  Each primitive has a signature something like:
primFFICall: functionAddress <Alien> result: result <Alien> with: firstArg <Alien> ... with: lastArg <Alien>
	<primitive: 'primCallOutIntegralReturn' module: 'IA32ABI'>
which arranges to call-out supplying the arguments to the function pointed to by functionAddress, copying its return value into result.  The call-out primitives are as follows:

primCallOutIntegralReturn call a function which returns up to 8 bytes in %eax & %edx, taking up to the first 4 bytes from %eax.  i.e. if the sizeof(result) is 4 or less only bytes from %eax will be returned, but if more then the first 4 bytes of result will be assigned with %eax and subsequent bytes with %edx, up to a total of 8 bytes.

primCallOutPointerReturn call a function which returns a pointer in %eax.  Assign sizeof(result) bytes from this pointer into the result.

primCallOutFloatReturn call a function which returns a 4 byte single-precision float in %f0, assigning the 4 bytes of %f0 into result.

primCallOutDoubleReturn call a function which returns an 8 byte double-precision float in %f0, assigning the 8 bytes of %f0 into result.


"
Class {
	#name : #IA32ABIPlugin,
	#superclass : #InterpreterPlugin,
	#pools : [
		'VMBasicConstants'
	],
	#category : #'VMMaker-Plugins-FFI'
}

{ #category : #translation }
IA32ABIPlugin class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	^{ VMCallbackContext. VMCallbackReturnValue }
]

{ #category : #translation }
IA32ABIPlugin class >> declareCVarsIn: aCCodeGen [
	aCCodeGen
		addHeaderFile: '<setjmp.h>';
		addHeaderFile: '"vmCallback.h"';
		addHeaderFile: '"ia32abi.h"';
		addHeaderFile: '"sqAssert.h"'
]

{ #category : #accessing }
IA32ABIPlugin class >> hasHeaderFile [
	^true
]

{ #category : #translation }
IA32ABIPlugin class >> moduleName [
	^'IA32ABI'
]

{ #category : #translation }
IA32ABIPlugin class >> shouldGenerateTypedefFor: aStructClass [
	"Hack to work-around mutliple definitions.  Sometimes a type has been defined in an include."
	^aStructClass ~~ VMCallbackContext
]

{ #category : #'simulation only' }
IA32ABIPlugin class >> simulatorClass [
	^ IA32ABIPluginSimulator
]

{ #category : #'private-support' }
IA32ABIPlugin >> index: byteIndex length: length inRange: rcvr [
	"Answer if the indices byteIndex to byteIndex + length - 1 are valid zero-relative indices into the rcvr.
	 Beware!  There be dragons here.  The form below (byteIndex <= (dataSize abs - length)) is used
	 because byteIndex + length could overflow, whereas (dataSize abs - length) can't.  We *don't* use the
	 obvious optimization
		^dataSize = 0 or: [byteIndex asUnsignedInteger <= (dataSize abs - length)]
	 because with C's Usual Arithmetic Conversions
		5. Otherwise, both operands are converted to the unsigned integer type corresponding to the type of the operand with signed integer type.
	 means that the comparison will be unsigned, and if length > dataSize abs then dataSize abs - length is large and positive."
	| dataSize |
	<inline: true>
	dataSize := self sizeField: rcvr.
	^dataSize = 0 or: [byteIndex >= 0 and: [byteIndex <= (dataSize abs - length)]]
]

{ #category : #'private-support' }
IA32ABIPlugin >> isAlien: anOop [
	<export: true>
	^interpreterProxy
		includesBehavior: (interpreterProxy fetchClassOf: anOop)
		ThatOf: interpreterProxy classAlien
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primAddressField [
	"Answer the unsigned 32-bit (or 64-bit) integer comprising the address field (the second 32-bit or 64-bit field)."
	"<Alien> primAddressField ^<Integer>
		<primitive: 'primAddressField' error: errorCode module: 'IA32ABI'>"
	| rcvr value valueOop |
	<export: true>
	rcvr := interpreterProxy stackValue: 0.
	value := self longAt: rcvr + interpreterProxy baseHeaderSize + interpreterProxy bytesPerOop.
	valueOop := self positiveMachineIntegerFor: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primAddressFieldPut [
	"Store an unsigned integer into the size field (the second 32/64 bit field; little endian)."
	"<Alien> addressFieldPut: value <Integer> ^<Integer>
		<primitive: 'primAddressFieldPut' error: errorCode module: 'IA32ABI'>"
	| rcvr value valueOop |
	<export: true>
	valueOop := interpreterProxy stackValue: 0.
	rcvr := interpreterProxy stackValue: 1.
	value := interpreterProxy positiveMachineIntegerValueOf: valueOop.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(interpreterProxy isOopImmutable: rcvr) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	self longAt: rcvr + interpreterProxy baseHeaderSize + interpreterProxy bytesPerOop put: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primAlienReplace [
	"Copy some number of bytes from some source object starting at the index
	 into the receiver destination object from startIndex to stopIndex.  The  source
	 and destination may be Aliens or byte-indexable objects.  The primitive wll have
	 either of the following signatures:
	<Alien | indexableByteSubclass | indexableWordSubclass>
		primReplaceFrom: start <Integer>
		to: stop <Integer>
		with: replacement <Alien | indexableByteSubclass | indexableWordSubclass | Integer>
		startingAt: repStart <Integer> ^<self>
		<primitive: 'primitiveAlienReplace' error: errorCode module: 'IA32ABI'>
	<Anywhere>
		primReplaceIn: dest <Alien | indexableByteSubclass | indexableWordSubclass>
		from: start <Integer>
		to: stop <Integer>
		with: replacement <Alien | indexableByteSubclass | indexableWordSubclass | Integer>
		startingAt: repStart <Integer> ^<self>
		<primitive: 'primitiveAlienReplace' error: errorCode module: 'IA32ABI'>
	"
	| array start stop repl replStart dest src totalLength count |
	<export: true>
	array := interpreterProxy stackValue: 4.
	start := interpreterProxy stackIntegerValue: 3.
	stop := interpreterProxy stackIntegerValue: 2.
	repl := interpreterProxy stackValue: 1.
	replStart := interpreterProxy stackIntegerValue: 0.

	(interpreterProxy failed
	 or: [(interpreterProxy isWordsOrBytes: array) not]) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	(self isAlien: array)
		ifTrue:
			[totalLength := self sizeField: array.
			 dest := (self startOfData: array withSize: totalLength) + start - 1.
			 totalLength = 0 "no bounds checks for zero-sized (pointer) Aliens"
				ifTrue: [totalLength := stop]
				ifFalse: [totalLength := totalLength abs]]
		ifFalse:
			[totalLength := interpreterProxy byteSizeOf: array.
			 dest := (self startOfByteData: array) + start - 1].
	(start >= 1 and: [start - 1 <= stop and: [stop <= totalLength]]) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].

	(interpreterProxy isKindOfInteger: repl)
		ifTrue:
			[src := (interpreterProxy positiveMachineIntegerValueOf: repl) + replStart - 1.
			 interpreterProxy failed ifTrue:
				[^interpreterProxy primitiveFailFor: PrimErrBadArgument]]
		ifFalse:
			[(self isAlien: repl)
				ifTrue:
					[totalLength := self sizeField: repl.
					 src := (self startOfData: repl withSize: totalLength) + replStart - 1.
					 totalLength = 0 "no bounds checks for zero-sized (pointer) Aliens"
						ifTrue: [totalLength := stop - start + replStart]
						ifFalse: [totalLength := totalLength abs]]
				ifFalse:
					[(interpreterProxy isWordsOrBytes: repl) ifFalse:
						[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
					 totalLength := interpreterProxy byteSizeOf: repl.
					 src := (self startOfByteData: repl) + replStart - 1].
			(replStart >= 1 and: [stop - start + replStart <= totalLength]) ifFalse:
				[^interpreterProxy primitiveFailFor: PrimErrBadIndex]].

	(interpreterProxy isOopImmutable: array) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].

	count := stop - start + 1.
	self memmove: dest asVoidPointer _: src asVoidPointer _: count.

	interpreterProxy pop: interpreterProxy methodArgumentCount
]

{ #category : #'primitives-memory management' }
IA32ABIPlugin >> primAllocateExecutablePage [
	"Answer an Alien for an executable page; for thunks"
	"primAllocateExecutablePage ^<Alien>
		<primitive: 'primAllocateExecutablePage' error: errorCode module: 'IA32ABI'>"
	| byteSize ptr mem alien |
	<export: true>
	<var: #byteSize type: #'sqIntptr_t'>
	<var: #ptr type: #'sqIntptr_t *'>
	<var: #mem type: #'void *'>

	self cCode: 'mem = allocateExecutablePage(&byteSize)'
		inSmalltalk: [self error: 'not yet implemented'. mem := 0. byteSize := 0].
	mem = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoCMemory].
	alien := interpreterProxy
				instantiateClass: interpreterProxy classAlien
				indexableSize: 2 * interpreterProxy bytesPerOop.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	ptr := interpreterProxy firstIndexableField: alien.
	ptr at: 0 put: 0 - byteSize. "indirect mem indicated by negative size. Slang doesn't grok negated"
	ptr at: 1 put: (self cCoerce: mem to: #'sqIntptr_t').
	interpreterProxy methodReturnValue: alien
]

{ #category : #'primitives-memory management' }
IA32ABIPlugin >> primBoxedFree [
	"Free the memory referenced by the receiver, an Alien."
	"proxy <Alien> primFree ^<Alien>
		<primitive: 'primBoxedFree' error: errorCode module: 'IA32ABI'>"
	| addr rcvr ptr sizeField |
	<export: true>
	<var: #ptr type: #'sqIntptr_t *'>
	<var: #addr type: #'sqIntptr_t'>
	<var: #sizeField type: #'sqIntptr_t'>

	rcvr := interpreterProxy stackValue: 0.
	(interpreterProxy byteSizeOf: rcvr) >= (2 * interpreterProxy bytesPerOop) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	ptr := interpreterProxy firstIndexableField: rcvr.
	sizeField := ptr at: 0.
	addr := ptr at: 1.
	"Don't you dare to free Squeak's memory!"
	(sizeField >= 0 or: [addr = 0 or: [interpreterProxy isInMemory: addr]]) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrInappropriate].
	self cCode: 'free((void *)addr)'
		inSmalltalk: [self Cfree: addr].
	ptr
		at: 0 put: 0;
		at: 1 put: 0 "cleanup"
]

{ #category : #'primitives-callouts' }
IA32ABIPlugin >> primCallOutDoubleReturn [
	"Call a foreign function that answers a double-precision floating-point result in %f0
	 according to IA32-ish ABI rules. The primitive will have a signature of the form
	functionAddress <Alien> primFFICallResult: result <Alien|Object> with: firstArg <Alien | Integer> ... with: lastArg <Alien | Integer> ^<Alien>
		<primitive: 'primCallOutDoubleReturn' error: errorCode module: 'IA32ABI'>.
	Answer result. If result is an Alien the value answered by the call will be assigned to result."
	| errCode mac result |
	<export: true>
	mac := interpreterProxy methodArgumentCount.
	self cppIf: STACKVM
		ifTrue: "In the STACKVM stacks grow down"
			[errCode := self call: interpreterProxy getStackPointer + mac - 2 "ptr to 0th arg"
							IA32: 1 - mac	"nargs negated to imply stack direction"
							Double: mac	"funcOffset"
							Return: mac - 1	"resultOffset"]
		ifFalse:
			[errCode := self call: interpreterProxy getStackPointer - mac + 2 "ptr to 0th arg"
							IA32: mac - 1	"nargs"
							Double: mac	"funcOffset"
							Return: mac - 1	"resultOffset"].
	errCode ~= 0 ifTrue:
		[^interpreterProxy primitiveFailFor: errCode].
	result := interpreterProxy stackValue: mac - 1.
	interpreterProxy pop: mac + 1 thenPush: result
]

{ #category : #'primitives-callouts' }
IA32ABIPlugin >> primCallOutFloatReturn [
	"Call a foreign function that answers a single-precision floating-point result in %f0
	 according to IA32-ish ABI rules. The primitive will have a signature of the form
	functionAddress <Alien> primFFICallResult: result <Alien|Object> with: firstArg <Alien | Integer> ... with: lastArg <Alien | Integer> ^<Alien>
		<primitive: 'primCallOutFloatReturn' error: errorCode module: 'IA32ABI'>.
	Answer result. If result is an Alien the value answered by the call will be assigned to result."
	| errCode mac result |
	<export: true>
	mac := interpreterProxy methodArgumentCount.
	self cppIf: STACKVM
		ifTrue: "In the STACKVM stacks grow down"
			[errCode := self call: interpreterProxy getStackPointer + mac - 2 "ptr to 0th arg"
							IA32: 1 - mac	"nargs negated to imply stack direction"
							Float: mac		"funcOffset"
							Return: mac - 1	"resultOffset"]
		ifFalse:
			[errCode := self call: interpreterProxy getStackPointer - mac + 2 "ptr to 0th arg"
							IA32: mac - 1	"nargs"
							Float: mac		"funcOffset"
							Return: mac - 1	"resultOffset"].
	errCode ~= 0 ifTrue:
		[^interpreterProxy primitiveFailFor: errCode].
	result := interpreterProxy stackValue: mac - 1.
	interpreterProxy pop: mac + 1 thenPush: result
]

{ #category : #'primitives-callouts' }
IA32ABIPlugin >> primCallOutIntegralReturn [
	"Call a foreign function that answers an integral result in %eax (and possibly %edx)
	 according to IA32-ish ABI rules. The primitive will have a signature of the form
	functionAddress <Alien> primFFICallResult: result <Alien|Object> with: firstArg <Alien | Integer> ... with: lastArg <Alien | Integer> ^<Alien>
		<primitive: 'primCallOutIntegralReturn' error: errorCode module: 'IA32ABI'>.
	Answer result. If result is an Alien the value answered by the call will be assigned to result."
	| errCode mac result |
	<export: true>
	mac := interpreterProxy methodArgumentCount.
	self cppIf: STACKVM
		ifTrue: "In the STACKVM stacks grow down"
			[errCode := self call: interpreterProxy getStackPointer + mac - 2 "ptr to 0th arg"
							IA32: 1 - mac	"nargs negated to imply stack direction"
							Integral: mac	"funcOffset"
							Return: mac - 1	"resultOffset"]
		ifFalse:
			[errCode := self call: interpreterProxy getStackPointer - mac + 2 "ptr to 0th arg"
							IA32: mac - 1	"nargs"
							Integral: mac	"funcOffset"
							Return: mac - 1	"resultOffset"].
	errCode ~= 0 ifTrue:
		[^interpreterProxy primitiveFailFor: errCode].
	result := interpreterProxy stackValue: mac - 1.
	interpreterProxy pop: mac + 1 thenPush: result
]

{ #category : #'primitives-memory management' }
IA32ABIPlugin >> primCalloc [
	"calloc (malloc + zero-fill) arg bytes."
	"primCalloc: byteSize <Integer> ^<Integer>
		<primitive: 'primCalloc' error: errorCode module: 'IA32ABI'>"
	| byteSize addr |
	<export: true>

	byteSize := interpreterProxy stackIntegerValue: 0.
	(interpreterProxy failed
	 or: [byteSize <= 0 "some mallocs can't deal with malloc(0) bytes"]) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	addr := self cCode: [(self c: 1 alloc: byteSize) asUnsignedInteger] inSmalltalk: [Alien Ccalloc: byteSize].
	addr = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoCMemory].
	interpreterProxy methodReturnValue: (self positiveMachineIntegerFor: addr)
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primDoubleAt [
	"Answer the 64-bit double starting at the given byte offset (little endian)."
	"<Alien> doubleAt: index <Integer> ^<Float>
		<primitive: 'primDoubleAt' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr floatValue |
	<export: true>
	<var: #floatValue type: #double>

	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 0) - 1.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 8 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	self memcpy: (self addressOf: floatValue) _: addr _: (self sizeof: floatValue).
	interpreterProxy pop: 2.
	^interpreterProxy pushFloat: floatValue
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primDoubleAtPut [
	"Store a double into 64 bits starting at the given byte offset (little endian)."
	"<Alien> doubleAt: index <Integer> put: value <Float | Integer> ^<Float | Integer>
		<primitive: 'primDoubleAtPut' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr valueOop floatValue |
	<export: true>
	<var: #floatValue type: #double>

	valueOop := interpreterProxy stackValue: 0.
	(interpreterProxy isIntegerObject: valueOop)
		ifTrue:[floatValue := self cCoerce: (interpreterProxy integerValueOf: valueOop) to: #double]
		ifFalse:[floatValue := self cCoerce: (interpreterProxy floatValueOf: valueOop) to: #double].
	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 1) - 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 8 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(interpreterProxy isOopImmutable: rcvr) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	self memcpy: addr _: (self addressOf: floatValue) _: (self sizeof: floatValue).
	interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primFloatAt [
	"Answer the 32-bit float starting at the given byte offset (little endian)."
	"<Alien> floatAt: index <Integer> ^<Float>
		<primitive: 'primFloatAt' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr floatValue |
	<export: true>
	<var: #floatValue type: #float>

	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 0) - 1.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 4 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	self memcpy: (self addressOf: floatValue) _: addr _: (self sizeof: floatValue).
	interpreterProxy pop: 2.
	^interpreterProxy pushFloat: floatValue
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primFloatAtPut [
	"Store a float into 32 bits starting at the given byte offset (little endian)."
	"<Alien> floatAt: index <Integer> put: value <Float | Integer> ^<Float | Integer>
		<primitive: 'primFloatAtPut' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr valueOop floatValue |
	<export: true>
	<var: #floatValue type: #float>

	valueOop := interpreterProxy stackValue: 0.
	(interpreterProxy isIntegerObject: valueOop)
		ifTrue:[floatValue := self cCoerce: (interpreterProxy integerValueOf: valueOop) to: #double]
		ifFalse:[floatValue := self cCoerce: (interpreterProxy floatValueOf: valueOop) to: #double].
	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 1) - 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 4 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(interpreterProxy isOopImmutable: rcvr) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	self memcpy: addr _: (self addressOf: floatValue) _: (self sizeof: floatValue).
	interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-memory management' }
IA32ABIPlugin >> primFree [
	"Free the memory referenced by the argument, an integer."
	"<Anywhere> primFree: address <Integer>
		<primitive: 'primFree' error: errorCode module: 'IA32ABI'>"
	| addr |
	<export: true>
	addr := interpreterProxy stackPositiveMachineIntegerValue: 0.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	"Don't you dare to free Squeak's memory!"
	(addr = 0 or: [interpreterProxy isInMemory: addr]) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrInappropriate].
	self cCode: 'free((void *)addr)'
		inSmalltalk: [self Cfree: addr].
	interpreterProxy pop: 1
]

{ #category : #'primitives-Windows-VM-specific' }
IA32ABIPlugin >> primInIOProcessEventsFlagAddress [
	"Answer the address of the int inIOProcessEvents flag.  This can be used to
	 disable invocation of ioProcessEvents and is for backward-compatibility.
	 Please use the core VM primitiveEventProcessingControl in new code."
	| inIOProcessEvents |
	<export: true>
	<var: 'inIOProcessEvents' declareC: 'extern int inIOProcessEvents'>
	self cCode: '' inSmalltalk: [inIOProcessEvents = 0].
	interpreterProxy methodReturnValue: (self positiveMachineIntegerFor: (self addressOf: inIOProcessEvents) asUnsignedInteger)
]

{ #category : #'primitives-library loading' }
IA32ABIPlugin >> primInLibraryFindSymbol [
	"Attempt to find the address of a symbol in a loaded library.
	 The primitive can have a signature  either of the form:
		<Anywhere> primInLibrary: libraryHandle <Alien> findSymbol: symbolName <String> ^<Integer>
			<primitive: 'primInLibraryFindSymbol' error: errorCode module: 'IA32ABI'>
	 or:
		libraryHandle <Alien>  primFindSymbol: symbolName <String> ^<Integer>
			<primitive: 'primInLibraryFindSymbol' error: errorCode module: 'IA32ABI'>"
	<export: true>
	| functionName libraryProxy address |
	<var: #address type: #'void *'>
	functionName := interpreterProxy stackValue: 0.
	libraryProxy := interpreterProxy stackValue: 1.
	((self isAlien: libraryProxy)
	 and: [(interpreterProxy byteSizeOf: libraryProxy) >= (2 * interpreterProxy bytesPerOop)
	 and: [interpreterProxy isBytes: functionName]]) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	address := interpreterProxy
					ioLoadSymbol: (self cCoerce: (interpreterProxy firstIndexableField: functionName)
										to: #sqInt)
					OfLength: (interpreterProxy byteSizeOf: functionName)
					FromModule: (self longAt: libraryProxy + interpreterProxy baseHeaderSize + interpreterProxy bytesPerOop).
	(interpreterProxy failed
	 or: [address = 0]) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNotFound].
	interpreterProxy methodReturnValue: (self positiveMachineIntegerFor: address asUnsignedInteger)
]

{ #category : #'primitives-library loading' }
IA32ABIPlugin >> primLoadLibrary [
	"Attempt to load a library of the given name.  The primitive will have a signature
	 of the form:
		<Anywhere>  primLoadLibrary: libraryName <String> ^<Integer>
			<primitive: 'primLoadLibrary' error: errorCode module: 'IA32ABI'>"
	<export: true>
	| libraryName libraryHandle |
	<var: #libraryHandle type: #'void *'>
	libraryName := interpreterProxy stackValue: 0.
	(interpreterProxy isBytes: libraryName)
		ifFalse: [^ interpreterProxy primitiveFailFor: PrimErrBadArgument].
	libraryHandle := interpreterProxy
					ioLoadModule: (self cCoerce: (interpreterProxy firstIndexableField: libraryName) to: 'sqInt')
					OfLength: (interpreterProxy byteSizeOf: libraryName).
	libraryHandle = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNotFound].
	interpreterProxy methodReturnValue: (self positiveMachineIntegerFor: libraryHandle asUnsignedInteger)
]

{ #category : #'primitives-memory management' }
IA32ABIPlugin >> primMalloc [
	"Malloc arg bytes."
	"primMalloc: byteSize <Integer> <^Integer>
		<primitive: 'primMalloc' error: errorCode module: 'IA32ABI'>"
	| byteSize addr |
	<export: true>

	byteSize := interpreterProxy stackIntegerValue: 0.
	(interpreterProxy failed
	 or: [byteSize <= 0 "some mallocs can't deal with malloc(0) bytes"]) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	addr := self cCode: [(self malloc: byteSize) asUnsignedInteger] inSmalltalk: [Alien Cmalloc: byteSize].
	addr = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoCMemory].
	interpreterProxy methodReturnValue: (self positiveMachineIntegerFor: addr)
]

{ #category : #'primitives-callbacks' }
IA32ABIPlugin >> primReturnAsFromContextThrough [
	"Return a result from a callback to the callback's callee.  The primitive
	 has a signature of either of the forms:
		result <VMCallbackContext32/64>
				primReturnAs: returnTypeCode <Integer>
				FromContext: callbackContext <Context>
		result <VMCallbackContext32/64>
				primSignal: aSemaphore <Semaphore>
				andReturnAs: returnTypeCode <Integer>
				FromContext: callbackContext <Context>
			<primitive: 'primReturnAsFromContextThrough' error: errorCode module: 'IA32ABI'>.
	 If of the second form answer false if this is not the most recent callback, and signal aSemaphore
	 if it is, so as to implement LIFO ordering of callbacks."
	<export: true>
	| vmCallbackContext isMostRecent |
	<var: #vmCallbackContext type: #'VMCallbackContext *'>
	interpreterProxy methodArgumentCount = 3
		ifTrue:
			[self assert: (interpreterProxy isNonImmediate: (interpreterProxy stackValue: 3)).
			 self assert: (interpreterProxy fetchClassOf: (interpreterProxy stackValue: 2)) = interpreterProxy classSemaphore.
			 self assert: (interpreterProxy isIntegerObject: (interpreterProxy stackValue: 1)).
			 self assert: (interpreterProxy isNonImmediate: (interpreterProxy stackValue: 0)).
			 vmCallbackContext := self cCoerceSimple: (self startOfData: (interpreterProxy stackValue: 3))
										to: #'VMCallbackContext *'.
			 isMostRecent := vmCallbackContext = self getMostRecentCallbackContext.
			 isMostRecent ifFalse:
				[^interpreterProxy methodReturnValue: interpreterProxy falseObject].
			(interpreterProxy fetchClassOf: (interpreterProxy stackValue: 2)) = interpreterProxy classSemaphore ifFalse:
				[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
			[interpreterProxy signalNoResume: (interpreterProxy stackValue: 2)] whileFalse]
		ifFalse:
			[self assert: interpreterProxy methodArgumentCount = 2.
			 self assert: (interpreterProxy isNonImmediate: (interpreterProxy stackValue: 2)).
			 self assert: (interpreterProxy isIntegerObject: (interpreterProxy stackValue: 1)).
			 self assert: (interpreterProxy isNonImmediate: (interpreterProxy stackValue: 0)).
			 vmCallbackContext := self cCoerceSimple: (self startOfData: (interpreterProxy stackValue: 2))
										to: #'VMCallbackContext *'].
	(interpreterProxy
		returnAs: (interpreterProxy stackValue: 1)
		ThroughCallback: vmCallbackContext
		Context: (interpreterProxy stackValue: 0)) ifFalse:
			[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	"NOTREACHED"
]

{ #category : #'primitives-callbacks' }
IA32ABIPlugin >> primReturnFromContextThrough [
	"Return a result from a callback to the callback's callee.  The primitive
	 has a signature of either of the forms:
		result <FFICallbackResult> primReturnFromContext: callbackContext <MethodContext> through: jmpBuf <Integer>
		result <FFICallbackResult> primSignal: aSemaphore <Semaphore> andReturnFromContext: callbackContext <MethodContext> through: jmpBuf <Integer>
			<primitive: 'primReturnFromContextThrough' error: errorCode module: 'IA32ABI'>.
	 If of the second form answer true if this is not the most recent callback, and signal aSemaphore
	 if it is, so as to implement LIFO ordering of callbacks."
	<export: true>
	<legacy>
	| mac vmCallbackContext vmCallbackReturnValue isMostRecent |
	<var: #vmCallbackContext type: #'VMCallbackContext *'>
	<var: #vmCallbackReturnValue type: #'VMCallbackReturnValue *'>
	vmCallbackContext := self cCoerceSimple: (interpreterProxy positiveMachineIntegerValueOf: (interpreterProxy stackValue: 0))
								to: #'VMCallbackContext *'.
	(interpreterProxy failed or: [vmCallbackContext = 0]) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	(mac := interpreterProxy methodArgumentCount) = 3 ifTrue:
		[isMostRecent := vmCallbackContext = self getMostRecentCallbackContext.
		isMostRecent ifFalse:
			[interpreterProxy methodReturnValue: interpreterProxy trueObject.
			^nil].
		(interpreterProxy fetchClassOf: (interpreterProxy stackValue: 2)) = interpreterProxy classSemaphore
			ifFalse: [^interpreterProxy primitiveFailFor: PrimErrBadArgument].
		[interpreterProxy signalNoResume: (interpreterProxy stackValue: 2)] whileFalse].
	vmCallbackReturnValue := self cCoerceSimple: (self startOfData: (interpreterProxy stackValue: mac))
									to: #'VMCallbackReturnValue *'.
	self cCode: "C needs a typedef for structs to be assigned, but that implies a struct class for just one assignment."
		[self memcpy: (self addressOf: vmCallbackContext rvs)
			_: (self addressOf: vmCallbackReturnValue crvrvs)
			_: (self sizeof: vmCallbackContext rvs)]
		inSmalltalk: [vmCallbackContext rvs: vmCallbackReturnValue crvrvs].
	(interpreterProxy
		returnAs: (interpreterProxy integerObjectOf: vmCallbackReturnValue type + 1)
		ThroughCallback: vmCallbackContext
		Context: (interpreterProxy stackValue: 1)) ifFalse:
			[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	"NOTREACHED"
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primSignedByteAt [
	"Answer the signed 8-bit integer starting at the given byte offset (little endian)."
	"<Alien> unsignedByteAt: index <Integer> ^<Integer>
		<primitive: 'primSignedByteAt' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>
	<var: #value type: 'signed char '>

	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 0) - 1.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 1 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	value := self byteAt: addr.
	valueOop := interpreterProxy signed32BitIntegerFor: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primSignedByteAtPut [
	"Store a signed integer into 8 bits starting at the given byte offset (little endian)."
	"<Alien> signedByteAt: index <Integer> put: value <Integer> ^<Integer>
		<primitive: 'primSignedByteAtPut' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>

	valueOop := interpreterProxy stackValue: 0.
	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 1) - 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	value := interpreterProxy signed32BitValueOf: valueOop.
	(interpreterProxy failed
	or: [value < -128
	or: [value > 127]]) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 1 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(interpreterProxy isOopImmutable: rcvr) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	self byteAt: addr put: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primSignedLongAt [
	"Answer the signed 32-bit integer starting at the given byte offset (little endian)."
	"<Alien> signedLongAt: index <Integer> ^<Integer>
		<primitive: 'primSignedLongAt' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>

	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 0) - 1.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 4 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	value := self long32At: addr.
	valueOop := interpreterProxy signed32BitIntegerFor: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primSignedLongAtPut [
	"Store a signed integer into 32 bits starting at the given byte offset (little endian)."
	"<Alien> signedLongAt: index <Integer> put: value <Integer> ^<Integer>
		<primitive: 'primSignedLongAtPut' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>

	valueOop := interpreterProxy stackValue: 0.
	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 1) - 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	value := interpreterProxy signed32BitValueOf: valueOop.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 4 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(interpreterProxy isOopImmutable: rcvr) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	self long32At: addr put: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primSignedLongLongAt [
	"Answer the signed 64-bit integer starting at the given byte offset (little endian)."
	"<Alien> signedLongLongAt: index <Integer> ^<Integer>
		<primitive: 'primSignedLongLongAt' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr valueOop signedlonglongvaluePtr signedlonglongvalue |
	<export: true>
	<var: 'signedlonglongvalue' declareC: 'long long signedlonglongvalue'>
	<var: 'signedlonglongvaluePtr' declareC: 'long long *signedlonglongvaluePtr'>

	signedlonglongvaluePtr := 0.
	self touch: signedlonglongvaluePtr.
	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 0) - 1.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 8 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	signedlonglongvaluePtr := self cCoerce: addr to: 'long long*'.
	signedlonglongvalue := self cCode: '*signedlonglongvaluePtr'.
	valueOop := interpreterProxy signed64BitIntegerFor: signedlonglongvalue.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primSignedLongLongAtPut [
	"Store a signed integer into 64 bits starting at the given byte offset (little endian)."
	"<Alien> signedLongLongAt: index <Integer> put: value <Integer> ^<Integer>
		<primitive: 'primSignedLongLongAtPut' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr valueOop signedlonglongvalue signedlonglongvaluePtr |
	<export: true>
	<var: 'signedlonglongvalue' declareC: 'long long signedlonglongvalue'>
	<var: 'signedlonglongvaluePtr' declareC: 'long long *signedlonglongvaluePtr'>

	signedlonglongvaluePtr := 0.
	self touch: signedlonglongvaluePtr.
	valueOop := interpreterProxy stackValue: 0.
	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 1) - 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	signedlonglongvalue := interpreterProxy signed64BitValueOf: valueOop.
	self touch: signedlonglongvalue.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 8 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(interpreterProxy isOopImmutable: rcvr) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	signedlonglongvaluePtr := self cCoerce: addr to: 'long long*'.
	self cCode: '*signedlonglongvaluePtr = signedlonglongvalue'.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primSignedShortAt [
	"Answer the signed 32-bit integer starting at the given byte offset (little endian)."
	"<Alien> signedShortAt: index <Integer> ^<Integer>
		<primitive: 'primSignedShortAt' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>
	<var: #value type: 'short '>

	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 0) - 1.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 2 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	value := self shortAt: addr.
	valueOop := interpreterProxy signed32BitIntegerFor: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primSignedShortAtPut [
	"Store a signed integer into 16 bits starting at the given byte offset (little endian)."
	"<Alien> signedShortAt: index <Integer> put: value <Integer> ^<Integer>
		<primitive: 'primSignedShortAtPut' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>

	valueOop := interpreterProxy stackValue: 0.
	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 1) - 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	value := interpreterProxy signed32BitValueOf: valueOop.
	(interpreterProxy failed
	or: [value < -32768
	or: [value > 32767]]) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 2 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(interpreterProxy isOopImmutable: rcvr) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	self shortAt: addr put: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primSignedWordAt [
	"Answer the signed word starting at the given byte offset (little endian)."
	"<Alien> signedWordAt: index <Integer> ^<Integer>
		<primitive: 'primSignedWordAt' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>

	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 0) - 1.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: interpreterProxy bytesPerOop inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	value := self longAt: addr.
	valueOop := interpreterProxy signedMachineIntegerValueOf: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primSignedWordAtPut [
	"Store a signed integer into the word starting at the given byte offset (little endian)."
	"<Alien> signedWordAt: index <Integer> put: value <Integer> ^<Integer>
		<primitive: 'primSignedWordAtPut' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>

	valueOop := interpreterProxy stackValue: 0.
	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 1) - 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	value := interpreterProxy signedMachineIntegerValueOf: valueOop.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: interpreterProxy bytesPerOop inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(interpreterProxy isOopImmutable: rcvr) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	self longAt: addr put: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primSizeField [
	"Answer the signed 32- or 64-bit integer comprising the size field (the first 32- or 64-bit field)."
	"<Alien> primSizeField ^<Integer>
		<primitive: 'primSizeField' error: errorCode module: 'IA32ABI'>"
	| rcvr value valueOop |
	<export: true>

	rcvr := interpreterProxy stackValue: 0.
	value := self cppIf: interpreterProxy bytesPerOop = 8
				ifTrue: [(self longAt: rcvr + interpreterProxy baseHeaderSize) signedIntFromLong64]
				ifFalse: [(self longAt: rcvr + interpreterProxy baseHeaderSize) signedIntFromLong].
	valueOop := self signedMachineIntegerFor: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primSizeFieldPut [
	"Store a signed integer into the size field (the first 32 bit field; little endian)."
	"<Alien> sizeFieldPut: value <Integer> ^<Integer>
		<primitive: 'primSizeFieldPut' error: errorCode module: 'IA32ABI'>"
	| rcvr value valueOop |
	<export: true>

	valueOop := interpreterProxy stackValue: 0.
	rcvr := interpreterProxy stackValue: 1.
	value := interpreterProxy signedMachineIntegerValueOf: valueOop.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self cppIf: interpreterProxy bytesPerOop = 8
		ifTrue: [self longAt: rcvr + interpreterProxy baseHeaderSize put: value signedIntToLong64]
		ifFalse: [self longAt: rcvr + interpreterProxy baseHeaderSize put: value signedIntToLong]).
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primStrlenFromStartIndex [
	"Answer the number of non-null bytes starting at index.  If
	 there isn't a null byte before the end of the object then the
	 result will be the number of bytes from index to the end of
	 the object, i.e. the result will be within the bounds of the object."
	"<Alien> primStrlenFrom: index <Integer> ^<Integer>
		<primitive: 'primStrlenFromStartIndex' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr index limit ptr |
	<export: true>
	<var: #ptr type: #'char *'>

	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 0) - 1.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 1 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	limit := self sizeField: rcvr.
	ptr := self cCoerce: ((self startOfData: rcvr withSize: limit) + byteOffset) to: #'char *'.
	limit = 0
		ifTrue: [index := self strlen: ptr]
		ifFalse:
			[limit := limit abs.
			 index := 0.
			 [index < limit
			  and: [(self cCode: 'ptr[index]' inSmalltalk: [ptr byteAt: index]) ~= 0]] whileTrue:
				[index := index + 1]].
	^interpreterProxy methodReturnValue: (interpreterProxy positive32BitIntegerFor: index)
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primStrlenThroughPointerAtIndex [
	"Answer the number of non-null bytes starting at the byte addressed by
	 the 4-byte pointer at index."
	"<Alien> strlenThroughPointerAt: index <Integer> ^<Integer>
		<primitive: 'primStrlenThroughPointerAtIndex' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr ptr addr |
	<export: true>
	<var: #ptr type: #'char *'>

	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 0) - 1.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: interpreterProxy bytesPerOop inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	addr := (self startOfData: rcvr) + byteOffset.
	ptr := self cCoerce: (self longAt: addr) to: #'char *'.
	^interpreterProxy methodReturnValue: (interpreterProxy positive32BitIntegerFor: (self strlen: ptr))
]

{ #category : #'primitives-callbacks' }
IA32ABIPlugin >> primThunkEntryAddress [
	"Answer the address of the entry-point for thunk callbacks:
		long thunkEntry(void *thunkp, long *stackp);
	 This could be derived via loadModule: findSymbol: etc but that would
	preclude making the plugin internal."
	| address |
	<export: true>
	address := self cCode: [#thunkEntry asIntegerPtr] inSmalltalk: [0].
	interpreterProxy methodReturnValue: (self positiveMachineIntegerFor: address)
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primUnsignedByteAt [
	"Answer the unsigned 8-bit integer starting at the given byte offset (little endian)."
	"<Alien> unsignedByteAt: index <Integer> ^<Integer>
		<primitive: 'primUnsignedByteAt' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>
	<var: #value type: 'unsigned char '>

	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 0) - 1.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 1 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	value := self byteAt: addr.
	valueOop := interpreterProxy positive32BitIntegerFor: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primUnsignedByteAtPut [
	"Store an unsigned integer into 8 bits starting at the given byte offset (little endian)."
	"<Alien> unsignedByteAt: index <Integer> put: value <Integer> ^<Integer>
		<primitive: 'primUnsignedByteAtPut' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>

	valueOop := interpreterProxy stackValue: 0.
	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 1) - 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	value := interpreterProxy positive32BitValueOf: valueOop.
	(interpreterProxy failed
	or: [value > 255]) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 1 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(interpreterProxy isOopImmutable: rcvr) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	self byteAt: addr put: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primUnsignedLongAt [
	"Answer the unsigned 32-bit integer starting at the given byte offset (little endian)."
	"<Alien> unsignedLongAt: index <Integer> ^<Integer>
		<primitive: 'primUnsignedLongAt' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>

	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 0) - 1.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 4 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	value := self long32At: addr.
	valueOop := interpreterProxy positive32BitIntegerFor: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primUnsignedLongAtPut [
	"Store an unsigned integer into 32 bits starting at the given byte offset (little endian)."
	"<Alien> unsignedLongAt: index <Integer> put: value <Integer> ^<Integer>
		<primitive: 'primUnsignedLongAtPut' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>

	valueOop := interpreterProxy stackValue: 0.
	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 1) - 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	value := interpreterProxy positive32BitValueOf: valueOop.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 4 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(interpreterProxy isOopImmutable: rcvr) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	self long32At: addr put: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primUnsignedLongLongAt [
	"Answer the unsigned 64-bit integer starting at the given byte offset (little endian)."
	"<Alien>unsignedLongLongAt: index <Integer> ^<Integer>
		<primitive: 'primUnsignedLongLongAt' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr valueOop unsignedlonglongvaluePtr unsignedlonglongvalue |
	<export: true>
	<var: 'unsignedlonglongvalue' declareC: 'unsigned long long unsignedlonglongvalue'>
	<var: 'unsignedlonglongvaluePtr' declareC: 'unsigned long long *unsignedlonglongvaluePtr'>

	unsignedlonglongvaluePtr := 0.
	self touch: unsignedlonglongvaluePtr.
	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 0) - 1.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 8 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	unsignedlonglongvaluePtr := self cCoerce: addr to: 'unsigned long long*'.
	unsignedlonglongvalue := self cCode: '*unsignedlonglongvaluePtr'.
	valueOop := interpreterProxy positive64BitIntegerFor: unsignedlonglongvalue.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primUnsignedLongLongAtPut [
	"Store a signed integer into 64 bits starting at the given byte offset (little endian)."
	"<Alien> unsignedLongLongAt: index <Integer> put: value <Integer> ^<Integer>
		<primitive: 'primUnSignedLongLongAtPut' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr valueOop unsignedlonglongvalue unsignedlonglongvaluePtr |
	<export: true>
	<var: 'unsignedlonglongvalue' declareC: 'unsigned long long unsignedlonglongvalue'>
	<var: 'unsignedlonglongvaluePtr' declareC: 'unsigned long long *unsignedlonglongvaluePtr'>

	unsignedlonglongvaluePtr := 0.
	self touch: unsignedlonglongvaluePtr.

	valueOop := interpreterProxy stackValue: 0.
	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 1) - 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	unsignedlonglongvalue := interpreterProxy positive64BitValueOf: valueOop.
	self touch: unsignedlonglongvalue.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 8 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(interpreterProxy isOopImmutable: rcvr) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	unsignedlonglongvaluePtr := self cCoerce: addr to: 'unsigned long long*'.
	self cCode: '*unsignedlonglongvaluePtr = unsignedlonglongvalue'.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primUnsignedShortAt [
	"Answer the unsigned 16-bit integer starting at the given byte offset (little endian)."
	"<Alien> unsignedShortAt: index <Integer> ^<Integer>
		<primitive: 'primUnsignedShortAt' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>
	<var: #value type: 'unsigned short'>

	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 0) - 1.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 2 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	value := self shortAt: addr.
	valueOop := interpreterProxy positive32BitIntegerFor: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primUnsignedShortAtPut [
	"Store an unsigned integer into 16 bits starting at the given byte offset (little endian)."
	"<Alien> unsignedShortAt: index <Integer> put: value <Integer> ^<Integer>
		<primitive: 'primUnsignedShortAtPut' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>

	valueOop := interpreterProxy stackValue: 0.
	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 1) - 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	value := interpreterProxy positive32BitValueOf: valueOop.
	(interpreterProxy failed
	or: [value > 65535]) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: 2 inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(interpreterProxy isOopImmutable: rcvr) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	self shortAt: addr put: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primUnsignedWordAt [
	"Answer the unsigned word starting at the given byte offset (little endian)."
	"<Alien> unsignedWordAt: index <Integer> ^<Integer>
		<primitive: 'primUnsignedWordAt' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>

	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 0) - 1.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: interpreterProxy bytesPerOop inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	value := self longAt: addr.
	valueOop := interpreterProxy positiveMachineIntegerFor: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-accessing' }
IA32ABIPlugin >> primUnsignedWordAtPut [
	"Store an unsigned integer into 32 bits starting at the given byte offset (little endian)."
	"<Alien> unsignedWordAt: index <Integer> put: value <Integer> ^<Integer>
		<primitive: 'primUnsignedWordAtPut' error: errorCode module: 'IA32ABI'>"
	| byteOffset rcvr startAddr addr value valueOop |
	<export: true>

	valueOop := interpreterProxy stackValue: 0.
	byteOffset := (interpreterProxy stackPositiveMachineIntegerValue: 1) - 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	value := interpreterProxy positiveMachineIntegerValueOf: valueOop.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(self index: byteOffset length: interpreterProxy bytesPerOop inRange: rcvr) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	(interpreterProxy isOopImmutable: rcvr) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	(startAddr := self startOfData: rcvr) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	addr := startAddr + byteOffset.
	self longAt: addr put: value.
	^interpreterProxy methodReturnValue: valueOop
]

{ #category : #'primitives-callouts' }
IA32ABIPlugin >> primVarArgsCallOutDoubleReturn [
	"Call a foreign function that answers a double-precision floating-point result in %f0
	 according to IA32-ish ABI rules. The primitive will have a signature of the form
	functionAddress <Alien> primFFICallResult: result <Alien|Object> withArguments: args <Array of: Alien | Integer> ^<Alien>
		<primitive: 'primVarArgsCallOutDoubleReturn' error: errorCode module: 'IA32ABI'>.
	Answer result. If result is an Alien the value answered by the call will be assigned to result."
	| array mac errCode result |
	<export: true>
	array := interpreterProxy stackValue: 0.
	(interpreterProxy isArray: array) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	mac := interpreterProxy methodArgumentCount.
	errCode := self call: (interpreterProxy firstIndexableField: array)	"ptr to 0th arg"
					IA32: (interpreterProxy stSizeOf: array)				"nargs"
					Double: 2											"func stackValue"
					Return: 1.											"result stackValue"
	errCode ~= 0 ifTrue:
		[^interpreterProxy primitiveFailFor: errCode].
	result := interpreterProxy stackValue: 1.
	interpreterProxy pop: mac + 1 thenPush: result
]

{ #category : #'primitives-callouts' }
IA32ABIPlugin >> primVarArgsCallOutFloatReturn [
	"Call a foreign function that answers a single-precision floating-point result in %f0
	 according to IA32-ish ABI rules. The primitive will have a signature of the form
	functionAddress <Alien> primFFICallResult: result <Alien|Object> withArguments: args <Array of: Alien | Integer> ^<Alien>
		<primitive: 'primVarArgsCallOutFloatReturn' error: errorCode module: 'IA32ABI'>.
	Answer result. If result is an Alien the value answered by the call will be assigned to result."
	| array mac errCode result |
	<export: true>
	array := interpreterProxy stackValue: 0.
	(interpreterProxy isArray: array) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	mac := interpreterProxy methodArgumentCount.
	errCode := self call: (interpreterProxy firstIndexableField: array)	"ptr to 0th arg"
					IA32: (interpreterProxy stSizeOf: array)				"nargs"
					Float: 2												"func stackValue"
					Return: 1.											"result stackValue"
	errCode ~= 0 ifTrue:
		[^interpreterProxy primitiveFailFor: errCode].
	result := interpreterProxy stackValue: 1.
	interpreterProxy pop: mac + 1 thenPush: result
]

{ #category : #'primitives-callouts' }
IA32ABIPlugin >> primVarArgsCallOutIntegralReturn [
	"Call a foreign function that answers an integral result in %eax (and possibly %edx)
	 according to IA32-ish ABI rules. The primitive will have a signature of the form
	functionAddress <Alien> primFFICallResult: result <Alien|Object> withArguments: args <Array of: Alien | Integer> ^<Alien>
		<primitive: 'primVarArgsCallOutIntegralReturn' error: errorCode module: 'IA32ABI'>.
	Answer result. If result is an Alien the value answered by the call will be assigned to result."
	| array mac errCode result |
	<export: true>
	array := interpreterProxy stackValue: 0.
	(interpreterProxy isArray: array) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	mac := interpreterProxy methodArgumentCount.
	errCode := self call: (interpreterProxy firstIndexableField: array)	"ptr to 0th arg"
					IA32: (interpreterProxy stSizeOf: array)				"nargs"
					Integral: 2											"func stackValue"
					Return: 1.											"result stackValue"
	errCode ~= 0 ifTrue:
		[^interpreterProxy primitiveFailFor: errCode].
	result := interpreterProxy stackValue: 1.
	interpreterProxy pop: mac + 1 thenPush: result
]

{ #category : #initialize }
IA32ABIPlugin >> setInterpreter: anInterpreter [ 
	"Note: This is coded so that is can be run from Squeak."
	| ok |
	<export: true>
	<var: #anInterpreter type: #'struct VirtualMachine*'>
	interpreterProxy := anInterpreter.
	ok := interpreterProxy majorVersion > 1
			or: [interpreterProxy minorVersion >= 12]. "There was no version 0"
	ok ifTrue:
		[self expandDereferenceInterpreterProxyFunctionTable].
	^ok
]

{ #category : #'private-support' }
IA32ABIPlugin >> sizeField: rcvr [
	"Answer the first field of rcvr which is assumed to be an Alien of at least 8 bytes"
	<inline: true>
	^self longAt: rcvr + interpreterProxy baseHeaderSize
]

{ #category : #'private-support' }
IA32ABIPlugin >> startOfByteData: rcvr [ "<byte indexable oop> ^<Integer>"
	"Answer the start of rcvr's data, given that it is not an alien."
	<inline: true>
	^rcvr + interpreterProxy baseHeaderSize
]

{ #category : #'private-support' }
IA32ABIPlugin >> startOfData: rcvr [ "<Alien oop> ^<Integer>"
	"Answer the start of rcvr's data.  For direct aliens this is the address of
	 the second field.  For indirect and pointer aliens it is what the second field points to."
	<inline: true>
	^(self sizeField: rcvr) > 0
	 	ifTrue: [rcvr + interpreterProxy baseHeaderSize + interpreterProxy bytesPerOop]
		ifFalse: [self longAt: rcvr + interpreterProxy baseHeaderSize + interpreterProxy bytesPerOop]
]

{ #category : #'private-support' }
IA32ABIPlugin >> startOfData: rcvr "<Alien oop>" withSize: sizeField [ "<Integer> ^<Integer>"
	"Answer the start of rcvr's data.  For direct aliens this is the address of
	 the second field.  For indirect and pointer aliens it is what the second field points to."
	<inline: true>
	^sizeField > 0
	 	ifTrue: [rcvr + interpreterProxy baseHeaderSize + interpreterProxy bytesPerOop]
		ifFalse: [self longAt: rcvr + interpreterProxy baseHeaderSize + interpreterProxy bytesPerOop]
]
