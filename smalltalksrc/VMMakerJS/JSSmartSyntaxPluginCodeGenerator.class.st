"
Subclass of JSCodeGenerator, used in connection with SmartSyntaxInterpreterPlugin to generate named primitives with type coercion specifications.
"
Class {
	#name : #JSSmartSyntaxPluginCodeGenerator,
	#superclass : #JSPluginCodeGenerator,
	#instVars : [
		'debugFlag'
	],
	#category : #'VMMakerJS-SmartSyntaxPlugins'
}

{ #category : #linking }
JSSmartSyntaxPluginCodeGenerator >> emitLoad: aString asBooleanValueFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: ' = interpreterProxy->booleanValueOf(';
		crtab: 2;
		nextPutAll: 'interpreterProxy->stackValue(';
		nextPutAll: anInteger asString;
		nextPutAll: '))'
]

{ #category : #linking }
JSSmartSyntaxPluginCodeGenerator >> emitLoad: aString asCharPtrFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: 	' = (char *) interpreterProxy->firstIndexableField(';
		crtab: 2;
		nextPutAll: 	'interpreterProxy->stackValueOf(';
		nextPutAll: anInteger asString;
		nextPutAll: '))'
]

{ #category : #linking }
JSSmartSyntaxPluginCodeGenerator >> emitLoad: aString asFloatPtrFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: 	' = (float *) interpreterProxy->firstIndexableField(';
		crtab: 2;
		nextPutAll: 	'interpreterProxy->stackValueOf(';
		nextPutAll: anInteger asString;
		nextPutAll: '))'
]

{ #category : #linking }
JSSmartSyntaxPluginCodeGenerator >> emitLoad: aString asFloatValueFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: 	' = interpreterProxy->stackFloatValue(';
		nextPutAll: anInteger asString;
		nextPutAll: ')'
]

{ #category : #linking }
JSSmartSyntaxPluginCodeGenerator >> emitLoad: aString asIntPtrFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: 	' = (int *) interpreterProxy->firstIndexableField(';
		crtab: 2;
		nextPutAll: 	'interpreterProxy->stackValueOf(';
		nextPutAll: anInteger asString;
		nextPutAll: '))'
]

{ #category : #linking }
JSSmartSyntaxPluginCodeGenerator >> emitLoad: aString asIntegerValueFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: 	' = interpreterProxy stackIntegerValue(';
		nextPutAll: anInteger asString;
		nextPutAll: ')'
]

{ #category : #linking }
JSSmartSyntaxPluginCodeGenerator >> emitLoad: aString asKindOf: aClass from: anInteger on: aStream [

	self emitLoad: aString asNakedOopFrom: anInteger on: aStream.
	aStream
		crtab;
		nextPutAll: 'interpreterProxy->success(interpreterProxy->isKindOf(';
		nextPutAll: aString;
		nextPutAll: 	', ''';
		nextPutAll:	aClass asString;
		nextPutAll: '''))'
]

{ #category : #linking }
JSSmartSyntaxPluginCodeGenerator >> emitLoad: aString asMemberOf: aClass from: anInteger on: aStream [

	self emitLoad: aString asNakedOopFrom: anInteger on: aStream.
	aStream
		crtab;
		nextPutAll: 'interpreterProxy->success(interpreterProxy->isMemberOf(';
		nextPutAll: aString;
		nextPutAll: 	', ''';
		nextPutAll:	aClass asString;
		nextPutAll: '''))'
]

{ #category : #linking }
JSSmartSyntaxPluginCodeGenerator >> emitLoad: aString asNakedOopFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: ' = interpreterProxy stackValue(';
		nextPutAll: anInteger asString;
		nextPutAll: ')'
]

{ #category : #linking }
JSSmartSyntaxPluginCodeGenerator >> emitLoad: aString asNonIntegerValueFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: 	' = interpreterProxy stackObjectValue(';
		nextPutAll: anInteger asString;
		nextPutAll: ')'
]

{ #category : #linking }
JSSmartSyntaxPluginCodeGenerator >> emitLoad: aString asUnsignedValueFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: 	' = interpreterProxy->positive32BitValueOf(';
		crtab: 2;
		nextPutAll: 	'interpreterProxy->stackValue(';
		nextPutAll: anInteger asString;
		nextPutAll: '))'
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateAsBooleanObj: aNode on: aStream indent: anInteger [

	aStream nextPutAll: '('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: 
		') ? interpreterProxy->trueObject(): interpreterProxy->falseObject()'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateAsCBoolean: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->booleanValueOf('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateAsCDouble: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->floatValueOf('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateAsCInt: aNode on: aStream indent: anInteger [

	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ' >> 1'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateAsCUnsigned: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->positive32BitValueOf('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateAsCharPtr: aNode on: aStream indent: anInteger [

	aStream nextPutAll: '(char *) interpreterProxy->firstIndexableField('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateAsFloatObj: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->floatObjectOf('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateAsIfVar: aNode on: aStream indent: anInteger [

	| cName fName class index |
	cName := String streamContents: 
		[:scStr | self emitJSExpression: aNode args first on: scStr].
	class := Smalltalk 
		at: (cName asSymbol) 
		ifAbsent: [nil].
	(class isNil not and: [class isBehavior]) ifFalse: 
		[^self error: 'first arg must identify class'].
	fName := aNode args second value.
	index := class allInstVarNames
		indexOf: fName
		ifAbsent: [^self error: 'second arg must be instVar'].
	aStream 
		nextPutAll: 'interpreterProxy->fetchPointerofObject(';
		nextPutAll: (index - 1) asString;
		nextPutAll: ','.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateAsIfVarAsValue: aNode on: aStream indent: anInteger [

	| cName fName class index fetchNode |
	cName := String streamContents: 
		[:scStr | self emitJSExpression: aNode args first on: scStr].
	class := Smalltalk 
		at: (cName asSymbol) 
		ifAbsent: [nil].
	(class isNil not and: [class isBehavior]) ifFalse: 
		[^self error: 'first arg must identify class'].
	fName := aNode args second value.
	index := class allInstVarNames
		indexOf: fName
		ifAbsent: [^self error: 'second arg must be instVar'].
	fetchNode := TSendNode new
		setSelector: #fetchPointer:ofObject:
		receiver: (TVariableNode new setName: 'interpreterProxy')
		arguments: (Array
			with: (TConstantNode new setValue: index - 1)
			with: aNode receiver).
	cName := aNode args third nameOrValue.
	class := Smalltalk 
		at: (cName asSymbol) 
		ifAbsent: [nil].
	(class isNil not and: [class isBehavior]) ifFalse: 
		[^self error: 'third arg must identify class'].
	class jscg: self generateCoerceToValueFrom: fetchNode on: aStream

]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateAsIfVarPut: aNode on: aStream indent: anInteger [

	| cName fName class index |
	cName := String streamContents: 
		[:scStr | self emitJSExpression: aNode args first on: scStr].
	class := Smalltalk 
		at: (cName asSymbol) 
		ifAbsent: [nil].
	(class isNil not and: [class isBehavior]) ifFalse: 
		[^self error: 'first arg must identify class'].
	fName := aNode args second value.
	index := class allInstVarNames
		indexOf: fName
		ifAbsent: [^self error: 'second arg must be instVar'].
	aStream 
		nextPutAll: 'interpreterProxy->storePointerofObjectwithValue(';
		nextPutAll: (index - 1) asString;
		nextPutAll: ','.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ','.
	self emitJSExpression: aNode args third on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateAsIntPtr: aNode on: aStream indent: anInteger [

	aStream nextPutAll: '(int *) interpreterProxy->firstIndexableField('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateAsOop: aNode on: aStream indent: anInteger [

	| cName class |
	cName := aNode args first nameOrValue.
	class := Smalltalk 
		at: (cName asSymbol) 
		ifAbsent: [nil].
	(class isNil not and: [class isBehavior]) ifFalse: 
		[^self error: 'first arg must identify class'].
	class jscg: self generateCoerceToOopFrom: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateAsPositiveIntegerObj: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->positive32BitIntegerFor('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateAsSmallIntegerObj: aNode on: aStream indent: anInteger [
	self emitJSExpression: aNode receiver on: aStream.

]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateAsValue: aNode on: aStream indent: anInteger [

	| cName class |
	cName := aNode args first nameOrValue.
	class := Smalltalk 
		at: (cName asSymbol) 
		ifAbsent: [nil].
	(class isNil not and: [class isBehavior]) ifFalse: 
		[^self error: 'first arg must identify class'].
	class jscg: self generateCoerceToValueFrom: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateCPtrAsOop: aNode on: aStream indent: anInteger [ 

	aStream nextPutAll: '('.
	aStream nextPutAll: 'oopForPointer( '.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ' ) - BASE_HEADER_SIZE)'
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateClass: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->fetchClassOf('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'asOop:/asValue:' }
JSSmartSyntaxPluginCodeGenerator >> generateCoerceToBooleanObjectFrom: aNode on: aStream [

	aStream nextPutAll: '('.
	self emitJSExpression: aNode on: aStream.
	aStream nextPutAll: '? interpreterProxy.trueObject() : interpreterProxy.falseObject())'
]

{ #category : #'asOop:/asValue:' }
JSSmartSyntaxPluginCodeGenerator >> generateCoerceToBooleanValueFrom: aNode on: aStream [
self halt: 'todo'.
	aStream nextPutAll: 'interpreterProxy.booleanValueOf('.
	self emitJSExpression: aNode on: aStream.
	aStream nextPutAll: ')'
]

{ #category : #'asOop:/asValue:' }
JSSmartSyntaxPluginCodeGenerator >> generateCoerceToFloatObjectFrom: aNode on: aStream [
self halt: 'todo'.
	aStream nextPutAll: 'interpreterProxy.floatObjectOf('.
	self emitJSExpression: aNode on: aStream.
	aStream nextPutAll: ')'
]

{ #category : #'asOop:/asValue:' }
JSSmartSyntaxPluginCodeGenerator >> generateCoerceToFloatValueFrom: aNode on: aStream [
self halt: 'todo'.
	aStream nextPutAll: 'interpreterProxy.floatValueOf('.
	self emitJSExpression: aNode on: aStream.
	aStream nextPutAll: ')'
]

{ #category : #'asOop:/asValue:' }
JSSmartSyntaxPluginCodeGenerator >> generateCoerceToObjectFromPtr: aNode on: aStream [
	"This code assumes no named instance variables"
self halt: 'todo'.
	aStream nextPutAll: 'oopForPointer('.
	self emitJSExpression: aNode on: aStream.
	aStream nextPutAll: ') - BASE_HEADER_SIZE'
]

{ #category : #'asOop:/asValue:' }
JSSmartSyntaxPluginCodeGenerator >> generateCoerceToPtr: aString fromObject: aNode on: aStream [
	"This code assumes no named instance variables"
self halt: 'todo'.
	aStream 
		nextPutAll: '((';
		nextPutAll: aString;
		nextPutAll: ') interpreterProxy->firstIndexableField('.
	self emitJSExpression: aNode on: aStream.
	aStream nextPutAll: '))'
]

{ #category : #'asOop:/asValue:' }
JSSmartSyntaxPluginCodeGenerator >> generateCoerceToSmallIntegerObjectFrom: aNode on: aStream [
	self emitJSExpression: aNode on: aStream.

]

{ #category : #'asOop:/asValue:' }
JSSmartSyntaxPluginCodeGenerator >> generateCoerceToSmallIntegerValueFrom: aNode on: aStream [
	self emitJSExpression: aNode on: aStream.

]

{ #category : #'asOop:/asValue:' }
JSSmartSyntaxPluginCodeGenerator >> generateCoerceToUnsignedObjectFrom: aNode on: aStream [
self halt: 'todo'.
	aStream nextPutAll: 'interpreterProxy.positive32BitIntegerFor('.
	self emitJSExpression: aNode on: aStream.
	aStream nextPutAll: ')'
]

{ #category : #'asOop:/asValue:' }
JSSmartSyntaxPluginCodeGenerator >> generateCoerceToUnsignedValueFrom: aNode on: aStream [
self halt: 'todo'.
	aStream nextPutAll: 'interpreterProxy.positive32BitValueOf('.
	self emitJSExpression: aNode on: aStream.
	aStream nextPutAll: ')'
]

{ #category : #'debug code' }
JSSmartSyntaxPluginCodeGenerator >> generateDebugCode [
	^ debugFlag
]

{ #category : #'debug code' }
JSSmartSyntaxPluginCodeGenerator >> generateDebugCode: aBool [ 
	debugFlag := aBool
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateDebugCode: aNode on: aStream indent: level [ 
	"Generate the C debug code for this message onto the given stream, if  
	compiled in debugMode."
	self generateDebugCode
		ifTrue: 
			[aStream nextPutAll: '// DebugCode...';
			 cr.
			aNode args first
				emitJSCodeOn: aStream
				level: level
				generator: self.
			aStream tab: level.
			aStream nextPutAll: '// ...DebugCode']
		ifFalse: [aStream nextPutAll: '// missing DebugCode']
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateField: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->fetchPointerofObject('.
	self emitJSExpression: aNode args first on: aStream.
	aStream nextPutAll: ','.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateFieldPut: aNode on: aStream indent: anInteger [
		
	aStream nextPutAll: 'interpreterProxy->storePointerofObjectwithValue('.
	self emitJSExpression: aNode args first on: aStream.
	aStream nextPutAll: ','.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ','.
	self emitJSExpression: aNode args second on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateFromStack: aNode on: aStream indent: anInteger [

	| idList |
	aNode args first isConstant ifFalse: [^self error: 'arg must be constant'].
	idList := aNode args first value.
	(1 to: idList size)
		do: [:i | 
			aStream 
				nextPutAll: (idList at: i);
				nextPutAll: ' = interpreterProxy->stackValue(';
				nextPutAll: (idList size - i) asString;
				nextPutAll: ')']
		separatedBy: [aStream nextPut: $;; crtab: anInteger].

]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateIsBytes: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isBytes('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateIsFloat: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isFloatObject('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateIsIndexable: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isIndexable('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateIsInteger: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isIntegerValue('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateIsIntegerOop: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isIntegerObject('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateIsIntegerValue: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isIntegerValue('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateIsKindOf: aNode on: aStream indent: anInteger [
	| className |
	className := aNode args second value.
	(#('LargePositiveInteger', 'LargeNegativeInteger') includes: className) ifTrue: [
		self emitJSExpression: aNode args first on: aStream.
		^aStream nextPutAll: '.sqClass === interpreterProxy.class', className, '()'].
	(#('Integer') includes: className) ifFalse: [self halt: 'isKindOf: ', className].
	aStream nextPutAll: 'interpreterProxy.isKindOf', className, '('.
	self emitJSExpression: aNode args first on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateIsMemberOf: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isMemberOf('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ','''.
	self emitJSExpression: aNode args first on: aStream.
	aStream nextPutAll: ''')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateIsPointers: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isPointers('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateIsWords: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isWords('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateIsWordsOrBytes: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isWordsOrBytes('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateNext: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| varNode |
	varNode := msgNode receiver.
	varNode isVariable
		ifFalse: [ self error: 'next can only be applied to variables' ].
	aStream nextPutAll: '*'.
	aStream nextPutAll: varNode name.
	aStream nextPutAll: '++'

]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateRemapOopIn: aNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	aNode args second emitJSCodeOn: aStream level: level-1 generator: self.

]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateStAt: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->stObjectat('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ','.
	self emitJSExpression: aNode args first on: aStream.
	aStream nextPutAll: ')'

]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateStAtPut: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy.stObjectatput('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ','.
	self emitJSExpression: aNode args first on: aStream.
	aStream nextPutAll: ','.
	self emitJSExpression: aNode args second on: aStream.
	aStream nextPutAll: ')'

]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> generateStSize: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->stSizeOf('.
	self emitJSExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #initialize }
JSSmartSyntaxPluginCodeGenerator >> initialize [
	super initialize.
	debugFlag := false.

]

{ #category : #'translating builtins' }
JSSmartSyntaxPluginCodeGenerator >> initializeCTranslationDictionary [ 
	"Initialize the dictionary mapping message names to actions for C code generation."

	| pairs |
	super initializeCTranslationDictionary.
	pairs := #(
		#asCInt						#generateAsCInt:on:indent:
		#asCUnsigned				#generateAsCUnsigned:on:indent:
		#asCBoolean					#generateAsCBoolean:on:indent:
		#asCDouble					#generateAsCDouble:on:indent:

		#asSmallIntegerObj			#generateAsSmallIntegerObj:on:indent:
		#asPositiveIntegerObj		#generateAsPositiveIntegerObj:on:indent:
		#asBooleanObj				#generateAsBooleanObj:on:indent:
		#asFloatObj					#generateAsFloatObj:on:indent:

		#asIf:var:					#generateAsIfVar:on:indent:
		#asIf:var:asValue:			#generateAsIfVarAsValue:on:indent:
		#asIf:var:put:				#generateAsIfVarPut:on:indent:
		#field:						#generateField:on:indent:
		#field:put:					#generateFieldPut:on:indent:
		
		#class						#generateClass:on:indent:

		#stSize						#generateStSize:on:indent:
		#stAt:						#generateStAt:on:indent:
		#stAt:put:					#generateStAtPut:on:indent:

		#asCharPtr					#generateAsCharPtr:on:indent:
		#asIntPtr					#generateAsIntPtr:on:indent:
		#cPtrAsOop					#generateCPtrAsOop:on:indent:
		#next						#generateNext:on:indent:

		#asOop:						#generateAsOop:on:indent:
		#asValue:					#generateAsValue:on:indent:

		#isFloat						#generateIsFloat:on:indent:
		#isIndexable					#generateIsIndexable:on:indent:
		#isIntegerOop				#generateIsIntegerOop:on:indent:
		#isIntegerValue				#generateIsIntegerValue:on:indent:
		#FloatOop					#generateIsFloatValue:on:indent:
		#isWords					#generateIsWords:on:indent:
		#isWordsOrBytes				#generateIsWordsOrBytes:on:indent:
		#isPointers					#generateIsPointers:on:indent:
		#isNil						#generateIsNil:on:indent:
		#isMemberOf:				#generateIsMemberOf:on:indent:
		#isKindOf:					#generateIsKindOf:on:indent:

		#fromStack:					#generateFromStack:on:indent:
		#clone						#generateClone:on:indent
		#new						#generateNew:on:indent
		#new:						#generateNewSize:on:indent
		#superclass					#generateSuperclass:on:indent:
		#remapOop:in:				#generateRemapOopIn:on:indent:
		#debugCode:					#generateDebugCode:on:indent:
	).

	1 to: pairs size by: 2 do: [:i |
		translationDict at: (pairs at: i) put: (pairs at: i + 1)].

]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asBooleanValueFrom: anInteger [
	"Answer codestring for boolean coercion (with validating side-effect) of object, as described in comment to jscgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy booleanValueOf:';
		crtab: 2;
		nextPutAll: '(interpreterProxy stackValue:';
		nextPutAll: anInteger asString;
		nextPutAll:	')'])
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asCharPtrFrom: anInteger [
	"Answer codestring for character pointer to first indexable field of object (without validating side-effect), as described in comment to jscgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'self cCoerce: (interpreterProxy firstIndexableField:';
		crtab: 4;
		nextPutAll: '(interpreterProxy stackValue:';
		nextPutAll: anInteger asString;
		nextPutAll:	'))';
		crtab: 3;
		nextPutAll: 'to: ''char *'''])
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asCharPtrFrom: anInteger andThen: valBlock [
	"Answer codestring for character pointer to first indexable field of object (without validating side-effect unless specified in valBlock), as described in comment to jscgLoad:expr:asRawOopFrom:"

	^(valBlock value: anInteger), '.',
	 (aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'self cCoerce: (interpreterProxy firstIndexableField:';
		crtab: 4;
		nextPutAll: '(interpreterProxy stackValue:';
		nextPutAll: anInteger asString;
		nextPutAll:	'))';
		crtab: 3;
		nextPutAll: 'to: ''char *''']))
	 
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asFloatValueFrom: anInteger [
	"Answer codestring for double precision coercion (with validating side-effect) of oop, as described in comment to jscgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy stackFloatValue: ';
		nextPutAll: anInteger asString])
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asIntPtrFrom: anInteger [
	"Answer codestring for integer pointer to first indexable field of object (without validating side-effect), as described in comment to jscgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'self cCoerce: (interpreterProxy firstIndexableField:';
		crtab: 4;
		nextPutAll: '(interpreterProxy stackValue:';
		nextPutAll: anInteger asString;
		nextPutAll:	'))';
		crtab: 3;
		nextPutAll: 'to: ''int *'''])
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asIntPtrFrom: anInteger andThen: valBlock [
	"Answer codestring for integer pointer to first indexable field of object (without validating side-effect unless specified in valBlock), as described in comment to jscgLoad:expr:asRawOopFrom:"

	^(valBlock value: anInteger), '.',
	 (aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'self cCoerce: (interpreterProxy firstIndexableField:';
		crtab: 4;
		nextPutAll: '(interpreterProxy stackValue:';
		nextPutAll: anInteger asString;
		nextPutAll:	'))';
		crtab: 3;
		nextPutAll: 'to: ''int *''']))
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asIntegerValueFrom: anInteger [
	"Answer codestring for integer coercion (with validating side-effect) of oop, as described in comment to jscgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy stackIntegerValue: ';
		nextPutAll: anInteger asString])
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asKindOf: aClass from: anInteger [

	^String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy success: (interpreterProxy';
		crtab: 2;
		nextPutAll: 'is: (interpreterProxy stackValue: ';
		nextPutAll: anInteger asString;
		nextPutAll: ')';
		crtab: 2;
		nextPutAll: 	'KindOf: ''';
		nextPutAll:	aClass asString;
		nextPutAll: ''').';
		crtab;
		nextPutAll: (self 
						jscgLoad: aBlock 
						expr: aString 
						asRawOopFrom: anInteger)]
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asMemberOf: aClass from: anInteger [

	^String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy success: (interpreterProxy';
		crtab: 2;
		nextPutAll: 'is: (interpreterProxy stackValue: ';
		nextPutAll: anInteger asString;
		nextPutAll: ')';
		crtab: 2;
		nextPutAll: 	'MemberOf: ''';
		nextPutAll:	aClass asString;
		nextPutAll: ''').';
		crtab;
		nextPutAll: (self 
						jscgLoad: aBlock 
						expr: aString 
						asRawOopFrom: anInteger)]
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: exprString asNamedPtr: recordString from: anInteger [
	"Answer codestring for integer pointer to first indexable field of object (without validating side-effect), as described in comment to jscgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'self cCoerce: (interpreterProxy firstIndexableField:';
		crtab: 4;
		nextPutAll: '(interpreterProxy stackValue:';
		nextPutAll: anInteger asString;
		nextPutAll:	'))';
		crtab: 3;
		nextPutAll: 'to: ''';
		nextPutAll: recordString;
		nextPutAll: ' *'''])
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: exprString asNamedPtr: recordString from: anInteger andThen: valBlock [
	"Answer codestring for integer pointer to first indexable field of object (without validating side-effect), as described in comment to jscgLoad:expr:asRawOopFrom:"

	^(valBlock value: anInteger), '.',
	 (aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'self cCoerce: (interpreterProxy firstIndexableField:';
		crtab: 4;
		nextPutAll: '(interpreterProxy stackValue:';
		nextPutAll: anInteger asString;
		nextPutAll:	'))';
		crtab: 3;
		nextPutAll: 'to: ''';
		nextPutAll: recordString;
		nextPutAll: ' *''']))
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asNonIntegerValueFrom: anInteger [
	"Answer codestring for oop (with validating side effect), as described in comment to jscgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy stackObjectValue: ';
		nextPutAll: anInteger asString])
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asRawOopFrom: anInteger [
	"Answer a string for a Slang expression that will load an oop (without validation) from stack index anInteger.  Apply aBlock, a BlockContext instance that when passed an expression, will return a string assigning the expression to the desired identifier, to the string before answering.  aString is a Slang expression that refers to the stack value, once it has been loaded."

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy stackValue: ';
		nextPutAll: anInteger asString])
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asUnsignedPtrFrom: anInteger andThen: valBlock [
	"Answer a codestring for integer pointer to first indexable field of object (without validating side-effect unless specified in valBlock), as described in comment to jscgLoad:expr:asRawOopFrom:"

	^(valBlock value: anInteger), '.',
	 (aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'self cCoerce: (interpreterProxy firstIndexableField:';
		crtab: 4;
		nextPutAll: '(interpreterProxy stackValue:';
		nextPutAll: anInteger asString;
		nextPutAll:	'))';
		crtab: 3;
		nextPutAll: 'to: ''unsigned *''']))
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asUnsignedValueFrom: anInteger [
	"Answer a codestring for positive integer coercion (with validating side-effect) of oop, as described in comment to jscgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy positive32BitValueOf:';
		crtab: 2;
		nextPutAll: '(interpreterProxy stackValue:';
		nextPutAll: anInteger asString;
		nextPutAll:	')'])
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asWBCharPtrFrom: anInteger [
	"Answer codestring for char pointer to first indexable field of object (with validating side-effect), as described in comment to jscgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'self cCoerce: (interpreterProxy arrayValueOf:';
		crtab: 4;
		nextPutAll: '(interpreterProxy stackValue:';
		nextPutAll: anInteger asString;
		nextPutAll:	'))';
		crtab: 3;
		nextPutAll: 'to: ''char *'''])
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asWBFloatPtrFrom: anInteger [
	"Answer codestring for single-precision float pointer to first indexable field of object (with validating side-effect), as described in comment to jscgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'self cCoerce: (interpreterProxy arrayValueOf:';
		crtab: 4;
		nextPutAll: '(interpreterProxy stackValue:';
		nextPutAll: anInteger asString;
		nextPutAll:	'))';
		crtab: 3;
		nextPutAll: 'to: ''float *'''])
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgLoad: aBlock expr: aString asWBIntPtrFrom: anInteger [
	"Answer codestring for integer pointer to first indexable field of object (with validating side-effect), as described in comment to jscgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'self cCoerce: (interpreterProxy arrayValueOf:';
		crtab: 4;
		nextPutAll: '(interpreterProxy stackValue:';
		nextPutAll: anInteger asString;
		nextPutAll:	'))';
		crtab: 3;
		nextPutAll: 'to: ''int *'''])
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgSetBlock: aString [

	^[:expr | aString, ' := ', expr]
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgTVarBlock: anInteger [

	^[:expr | '(thisContext tempAt: 1) tempAt: ', anInteger asString, ' put: (', expr, ')']
]

{ #category : #coercing }
JSSmartSyntaxPluginCodeGenerator >> jscgValBlock: valString [
	^[:index | String streamContents:
		[:aStream | aStream
			nextPutAll: 'interpreterProxy success: (interpreterProxy ';
			nextPutAll: valString;
			nextPutAll: ': (interpreterProxy stackValue: ';
			nextPutAll: index asString;
			nextPutAll: '))']]
]

{ #category : #initialize }
JSSmartSyntaxPluginCodeGenerator >> translationMethodClass [
	"return the class used to produce C translation methods from MethodNodes"
	^JSSmartSyntaxPluginMethod
]

{ #category : #transforming }
JSSmartSyntaxPluginCodeGenerator >> var: varName as: aClass [
	"Record the given C declaration for a global variable"

	variableDeclarations at: varName asString put: (aClass jscgDeclareJSForVar: varName)
]
