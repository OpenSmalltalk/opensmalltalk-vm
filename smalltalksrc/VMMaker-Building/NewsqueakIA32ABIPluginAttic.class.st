Class {
	#name : #NewsqueakIA32ABIPluginAttic,
	#superclass : #NewsqueakIA32ABIPlugin,
	#category : #'VMMaker-Plugins-Alien'
}

{ #category : #'translation to C' }
NewsqueakIA32ABIPluginAttic class >> declareCVarsIn: aCCodeGen [
	^self  "on purpose as a sub class of existing plugin"
]

{ #category : #'primitives-memory management' }
NewsqueakIA32ABIPluginAttic >> primBoxedCalloc [
	"This version boxes the result."
	"calloc (malloc + zero-fill) arg bytes."
	"primBoxedCalloc: byteSize <Integer>
		<primitive: 'primBoxedCalloc' module: 'IA32ABI'>"
	| byteSize addr oop ptr |
	<export: true>
	<inline: false>
	<var: #ptr type: 'long *'>
	<var: #byteSize type: 'long'>
	byteSize := interpreterProxy stackIntegerValue: 0.
	(interpreterProxy failed
	 or: [byteSize <= 0 "some mallocs can't deal with malloc(0) bytes"]) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self cCode: 'addr = (sqInt)calloc(1,byteSize)'
		inSmalltalk: [addr := self Ccalloc: byteSize].
	addr = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoCMemory].
	oop := interpreterProxy 
			instantiateClass: interpreterProxy classAlien
			indexableSize: 2 * interpreterProxy bytesPerOop.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	ptr := interpreterProxy firstIndexableField: oop.
	ptr at: 0 put: 0 - byteSize. "indirect args indicated by negative size. Slang doesn't grok negated"
	ptr at: 1 put: addr.
	interpreterProxy pop: 2 thenPush: oop.

]

{ #category : #'primitives-memory management' }
NewsqueakIA32ABIPluginAttic >> primBoxedMalloc [
	"This version boxes the result."
	"Malloc arg bytes."
	"primBoxedMalloc: byteSize <Integer>
		<primitive: 'primBoxedMalloc' module: 'IA32ABI'>"
	| byteSize addr oop ptr |
	<export: true>
	<inline: false>
	<var: #ptr type: 'long *'>
	<var: #byteSize type: 'long'>
	byteSize := interpreterProxy stackIntegerValue: 0.
	(interpreterProxy failed
	 or: [byteSize <= 0 "some mallocs can't deal with malloc(0) bytes"]) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self cCode: 'addr = (sqInt)malloc(byteSize)'
		inSmalltalk: [addr := self Cmalloc: byteSize].
	addr = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoCMemory].
	oop := interpreterProxy 
			instantiateClass: interpreterProxy classAlien
			indexableSize: 2 * interpreterProxy bytesPerOop.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	ptr := interpreterProxy firstIndexableField: oop.
	ptr at: 0 put: 0 - byteSize. "indirect args indicated by negative size. Slang doesn't grok negated"
	ptr at: 1 put: addr.
	interpreterProxy pop: 2 thenPush: oop.

]

{ #category : #'primitives-callouts' }
NewsqueakIA32ABIPluginAttic >> primCallOutDoubleReturnAnywhere [
	"Call a foreign function that answers a double-precision floating-point result in %f0
	 according to IA32-ish ABI rules. The primitive will have a signature of the form
	<Anywhere> primFFICall: functionAddress <Alien> result: result <Alien|Object> with: firstArg <Alien> ... with: lastArg <Alien>
		<primitive: 'primCallOutDoubleReturnAnywhere' error: errorCode module: 'IA32ABI'>.
	Answer result. If result is an Alien the value answered by the call will be assigned to result."
	| errCode mac result |
	<export: true>
	mac := interpreterProxy methodArgumentCount.
	(self isAlien:  (interpreterProxy stackValue: mac - 2)) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self cppIf: STACKVM
		ifTrue: "In the STACKVM stacks grow down"
			[self cCode: 'errCode = callIA32DoubleReturn(interpreterProxy->getStackPointer() + mac - 3, /* arg vec */
															2 - mac	/* nargs */,
															mac	/* funcOffset*/,
															mac - 2	/* resultOffset */)'
				inSmalltalk: [errCode := PrimErrUnsupported]]
		ifFalse:
			[self cCode: 'errCode = callIA32DoubleReturn(interpreterProxy->getStackPointer() - mac + 3, /* arg vec */
															mac - 2	/* nargs */,
															mac	/* funcOffset*/,
															mac - 2	/* resultOffset */)'
				inSmalltalk: [errCode := PrimErrUnsupported]].
	errCode ~= 0 ifTrue:
		[^interpreterProxy primitiveFailFor: errCode].
	result := interpreterProxy stackValue: mac - 2.
	interpreterProxy pop: mac + 1 thenPush: result
]

{ #category : #'primitives-callouts' }
NewsqueakIA32ABIPluginAttic >> primCallOutFloatReturnAnywhere [
	"Call a foreign function that answers a single-precision floating-point result in %f0
	 according to IA32-ish ABI rules. The primitive will have a signature of the form
	<Anywhere> primFFICall: functionAddress <Alien> result: result <Alien|Object> with: firstArg <Alien> ... with: lastArg <Alien>
		<primitive: 'primCallOutFloatReturnAnywhere' error: errorCode module: 'IA32ABI'>.
	Answer result. If result is an Alien the value answered by the call will be assigned to result."
	| errCode mac result |
	<export: true>
	mac := interpreterProxy methodArgumentCount.
	(self isAlien: (interpreterProxy stackValue: mac - 2)) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self cppIf: STACKVM
		ifTrue: "In the STACKVM stacks grow down"
			[self cCode: 'errCode = callIA32FloatReturn(interpreterProxy->getStackPointer() + mac - 3, /* arg vec */
															2 - mac	/* nargs */,
															mac	/* funcOffset*/,
															mac - 2	/* resultOffset */)'
				inSmalltalk: [errCode := PrimErrUnsupported]]
		ifFalse:
			[self cCode: 'errCode = callIA32FloatReturn(interpreterProxy->getStackPointer() - mac + 3, /* arg vec */
															mac - 2	/* nargs */,
															mac	/* funcOffset*/,
															mac - 2	/* resultOffset */)'
				inSmalltalk: [errCode := PrimErrUnsupported]].
	errCode ~= 0 ifTrue:
		[^interpreterProxy primitiveFailFor: errCode].
	result := interpreterProxy stackValue: mac - 2.
	interpreterProxy pop: mac + 1 thenPush: result
]

{ #category : #'primitives-callouts' }
NewsqueakIA32ABIPluginAttic >> primCallOutIntegralReturnAnywhere [
	"Call a foreign function that answers an integral result in %eax (and possibly %edx)
	 according to IA32-ish ABI rules. The primitive will have a signature of the form
	<Anywhere> primFFICall: functionAddress <Alien> result: result <Alien|Object> with: firstArg <Alien> ... with: lastArg <Alien>
		<primitive: 'primCallOutIntegralReturnAnywhere' error: errorCode module: 'IA32ABI'>.
	Answer result. If result is an Alien the value answered by the call will be assigned to result."
	| errCode mac result |
	<export: true>
	mac := interpreterProxy methodArgumentCount.
	(self isAlien:  (interpreterProxy stackValue: mac - 2)) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self cppIf: STACKVM
		ifTrue: "In the STACKVM stacks grow down"
			[self cCode: 'errCode = callIA32IntegralReturn(interpreterProxy->getStackPointer() + mac - 3, /* arg vec */
															2 - mac	/* nargs */,
															mac	/* funcOffset*/,
															mac - 2	/* resultOffset */)'
				inSmalltalk: [errCode := PrimErrUnsupported]]
		ifFalse:
			[self cCode: 'errCode = callIA32IntegralReturn(interpreterProxy->getStackPointer() - mac + 3, /* arg vec */
															mac - 2	/* nargs */,
															mac	/* funcOffset*/,
															mac - 2	/* resultOffset */)'
				inSmalltalk: [errCode := PrimErrUnsupported]].
	errCode ~= 0 ifTrue:
		[^interpreterProxy primitiveFailFor: errCode].
	result := interpreterProxy stackValue: mac - 2.
	interpreterProxy pop: mac + 1 thenPush: result
]
