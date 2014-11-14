Extension { #name : #TSendNode }

{ #category : #'*vmmakerjs' }
TSendNode >> emitJSCodeAsArgumentOn: aStream level: level generator: aCodeGen [
	"Emit the receiver in a form that can be passed as an argument."

	"If the selector is a built-in construct, translate it and return"
	(aCodeGen emitBuiltinConstructAsArgumentFor: self asExpression on: aStream level: level) ifFalse:
		["If it is a pointer dereference generate it"
		(self emitJSCodeAsPointerDereferenceOn: aStream level: level generator: aCodeGen) ifFalse:
			["Otherwise generate the vanilla C function call."
			 self emitJSCodeAsFunctionCallOn: aStream level: level generator: aCodeGen]]
]

{ #category : #'*vmmakerjs' }
TSendNode >> emitJSCodeAsExpressionOn: aStream level: level generator: aCodeGen [
	^self emitJSCodeAsArgumentOn: aStream level: level generator: aCodeGen
]

{ #category : #'*vmmakerjs' }
TSendNode >> emitJSCodeAsFunctionCallOn: aStream level: level generator: aCodeGen [

	"Translate this message send into a JS function call"
	"Special case for pluggable modules. Replace messages to interpreterProxy
	 by interpreterProxy->message(..) if the message is not builtin"
	(aCodeGen isGeneratingPluginCode
	 and: [receiver isVariable
	 and: ['interpreterProxy' = receiver name
	 and: [self isBuiltinOperator not]]]) ifTrue:
		[aStream nextPutAll:'interpreterProxy.'].
	"Translate this message send into a JS function call."
	aStream nextPutAll: (aCodeGen jsFunctionNameFor: selector); nextPut: $(.
	"Only include the receiver as the first argument in certain cases.
	 The receiver is always included if it is an expression.
	 If it is a variable:
		 If the vmClass says it is an implicit variable, don't include it.
		 If the variable is 'self' and the method being called is not in
		 the method set (i.e. it is some external code), don't include it."
	(self shouldIncludeReceiverAsFirstArgument: aCodeGen) ifTrue:
		[receiver emitJSCodeOn: aStream level: level generator: aCodeGen.
		arguments isEmpty ifFalse:
			[aStream nextPutAll: ', ']].
	arguments do:
		[ :arg| arg emitJSCodeAsArgumentOn: aStream level: level generator: aCodeGen]
		separatedBy: [aStream nextPut: $,; space].
	aStream nextPut: $)
]

{ #category : #'*vmmakerjs' }
TSendNode >> emitJSCodeAsPointerDereferenceOn: aStream level: level generator: aCodeGen [
	"If appropriate, translate this message send as a pointer dereference"

	(self isStructSend: aCodeGen) ifFalse:
		[^false].

	aStream nextPut: $(.
	receiver  emitJSCodeAsExpressionOn: aStream level: 0 generator: aCodeGen.
	aStream nextPut: $-; nextPut: $>.
	aStream nextPutAll: (aCodeGen jsFunctionNameFor: selector).
	arguments isEmpty ifFalse:
		[self assert: arguments size = 1.
		 aStream nextPutAll: ' = '.
		 arguments first emitJSCodeAsExpressionOn: aStream level: level generator: aCodeGen].
	aStream nextPut: $).
	^true
]

{ #category : #'*vmmakerjs' }
TSendNode >> emitJSCodeOn: aStream level: level generator: aCodeGen [
	"Emit the receiver as a statement."

	"If the selector is a built-in construct, translate it and return"
	(aCodeGen emitBuiltinConstructFor: self on: aStream level: level) ifFalse:
		["If it is a pointer dereference generate it"
		(self emitJSCodeAsPointerDereferenceOn: aStream level: level generator: aCodeGen) ifFalse:
			["Otherwise generate the vanilla C function call."
			 self emitJSCodeAsFunctionCallOn: aStream level: level generator: aCodeGen]]
]

{ #category : #'*vmmakerjs' }
TSendNode >> emitJSPointerArithmetic: type on: aStream level: level generator: aGenerator type: cType top: top [
	(selector = #+) ifFalse: [self halt].
	receiver isVariable
		ifTrue: [ | func |
			func := ({'int' -> 'PTR_ADD'. 'float' -> 'FPTR_ADD'} as: Dictionary)
				at: ((cType copyUpTo: $*) copyWithout: $ ).
			aStream nextPutAll: func, '(',  receiver name, ', ']
		ifFalse: [receiver emitJSPointerArithmetic: type on: aStream level: level generator: aGenerator type: cType top: false.
			aStream nextPutAll: ' + '].
	aGenerator emitJSExpression: arguments first on: aStream.
	top ifTrue: [aStream nextPutAll: ')'].
]

{ #category : #'*vmmakerjs' }
TSendNode >> isEqualityTest [
	^#(= == ~= ~~) includes: self selector
]

{ #category : #'*vmmakerjs' }
TSendNode >> isFloatIn: aCodeGen [
	selector precedence = 2 ifFalse: [^false].
	^ (receiver isFloatIn: aCodeGen)
		or: [arguments first isFloatIn: aCodeGen]
]

{ #category : #'*vmmakerjs' }
TSendNode >> isInterpreterProxyConstant [
	^#(nilObject trueObject falseObject) includes: self selector
]

{ #category : #'*vmmakerjs' }
TSendNode >> isLeafOrFunc [
	selector precedence = 2 ifTrue: [^false].
	(#(and: or: bitAnd: bitOr: bitXor: bitShift:) includes: selector) ifTrue: [^false].
	^true
]

{ #category : #'*vmmakerjs' }
TSendNode >> isPlusOne [
	^ self selector = #+ and: [self args first isConstant and: [self args first value = 1]]
]

{ #category : #'*vmmakerjs' }
TSendNode >> isTimesFour [
	^self args first isConstant and:
		[(self selector = #* and: [self args first value = 4])
		or: [self selector = #<< and: [self args first value = 2]]]
]
