"
Subclass of CCodeGenerator, used in connection with TestInterpreterPlugin to generate named primitives with type coercion specifications. See the plugins implemeted as subclasses of TestInterpreterPlugin
"
Class {
	#name : #SmartSyntaxPluginCodeGenerator,
	#superclass : #VMPluginCodeGenerator,
	#instVars : [
		'debugFlag'
	],
	#category : #'VMMaker-SmartSyntaxPlugins'
}

{ #category : #coercing }
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asBooleanValueFrom: anInteger [
	"Answer codestring for boolean coercion (with validating side-effect) of object, as described in comment to ccgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy booleanValueOf:';
		crtab: 2;
		nextPutAll: '(interpreterProxy stackValue:';
		nextPutAll: anInteger asString;
		nextPutAll:	')'])
]

{ #category : #coercing }
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asCharPtrFrom: anInteger [
	"Answer codestring for character pointer to first indexable field of object (without validating side-effect), as described in comment to ccgLoad:expr:asRawOopFrom:"

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
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asCharPtrFrom: anInteger andThen: valBlock [
	"Answer codestring for character pointer to first indexable field of object (without validating side-effect unless specified in valBlock), as described in comment to ccgLoad:expr:asRawOopFrom:"

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
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asFloatValueFrom: anInteger [
	"Answer codestring for double precision coercion (with validating side-effect) of oop, as described in comment to ccgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy stackFloatValue: ';
		nextPutAll: anInteger asString])
]

{ #category : #coercing }
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asIntPtrFrom: anInteger [
	"Answer codestring for integer pointer to first indexable field of object (without validating side-effect), as described in comment to ccgLoad:expr:asRawOopFrom:"

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
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asIntPtrFrom: anInteger andThen: valBlock [
	"Answer codestring for integer pointer to first indexable field of object (without validating side-effect unless specified in valBlock), as described in comment to ccgLoad:expr:asRawOopFrom:"

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
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asIntegerValueFrom: anInteger [
	"Answer codestring for integer coercion (with validating side-effect) of oop, as described in comment to ccgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy stackIntegerValue: ';
		nextPutAll: anInteger asString])
]

{ #category : #coercing }
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asKindOf: aClass from: anInteger [

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
						ccgLoad: aBlock 
						expr: aString 
						asRawOopFrom: anInteger)]
]

{ #category : #coercing }
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asMemberOf: aClass from: anInteger [

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
						ccgLoad: aBlock 
						expr: aString 
						asRawOopFrom: anInteger)]
]

{ #category : #coercing }
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: exprString asNamedPtr: recordString from: anInteger [
	"Answer codestring for integer pointer to first indexable field of object (without validating side-effect), as described in comment to ccgLoad:expr:asRawOopFrom:"

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
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: exprString asNamedPtr: recordString from: anInteger andThen: valBlock [
	"Answer codestring for integer pointer to first indexable field of object (without validating side-effect), as described in comment to ccgLoad:expr:asRawOopFrom:"

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
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asNonIntegerValueFrom: anInteger [
	"Answer codestring for oop (with validating side effect), as described in comment to ccgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy stackObjectValue: ';
		nextPutAll: anInteger asString])
]

{ #category : #coercing }
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asRawOopFrom: anInteger [
	"Answer a string for a Slang expression that will load an oop (without validation) from stack index anInteger.  Apply aBlock, a BlockContext instance that when passed an expression, will return a string assigning the expression to the desired identifier, to the string before answering.  aString is a Slang expression that refers to the stack value, once it has been loaded."

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy stackValue: ';
		nextPutAll: anInteger asString])
]

{ #category : #coercing }
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asUnsignedPtrFrom: anInteger andThen: valBlock [
	"Answer a codestring for integer pointer to first indexable field of object (without validating side-effect unless specified in valBlock), as described in comment to ccgLoad:expr:asRawOopFrom:"

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
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asUnsignedValueFrom: anInteger [
	"Answer a codestring for positive integer coercion (with validating side-effect) of oop, as described in comment to ccgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy positive32BitValueOf:';
		crtab: 2;
		nextPutAll: '(interpreterProxy stackValue:';
		nextPutAll: anInteger asString;
		nextPutAll:	')'])
]

{ #category : #coercing }
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asWBCharPtrFrom: anInteger [
	"Answer codestring for char pointer to first indexable field of object (with validating side-effect), as described in comment to ccgLoad:expr:asRawOopFrom:"

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
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asWBFloatPtrFrom: anInteger [
	"Answer codestring for single-precision float pointer to first indexable field of object (with validating side-effect), as described in comment to ccgLoad:expr:asRawOopFrom:"

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
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asWBIntPtrFrom: anInteger [
	"Answer codestring for integer pointer to first indexable field of object (with validating side-effect), as described in comment to ccgLoad:expr:asRawOopFrom:"

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
SmartSyntaxPluginCodeGenerator >> ccgSetBlock: aString [

	^[:expr | aString, ' := ', expr]
]

{ #category : #coercing }
SmartSyntaxPluginCodeGenerator >> ccgTVarBlock: anInteger [

	^[:expr | '(thisContext tempAt: 1) tempAt: ', anInteger asString, ' put: (', expr, ')']
]

{ #category : #coercing }
SmartSyntaxPluginCodeGenerator >> ccgValBlock: valString [

	^[:index | String streamContents:
		[:aStream | aStream
			nextPutAll: 'interpreterProxy success: (interpreterProxy ';
			nextPutAll: valString;
			nextPutAll: ': (interpreterProxy stackValue: ';
			nextPutAll: index asString;
			nextPutAll: '))']] 
]

{ #category : #linking }
SmartSyntaxPluginCodeGenerator >> emitLoad: aString asBooleanValueFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: ' = interpreterProxy->booleanValueOf(';
		crtab: 2;
		nextPutAll: 'interpreterProxy->stackValue(';
		nextPutAll: anInteger asString;
		nextPutAll: '))'
]

{ #category : #linking }
SmartSyntaxPluginCodeGenerator >> emitLoad: aString asCharPtrFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: 	' = (char *) interpreterProxy->firstIndexableField(';
		crtab: 2;
		nextPutAll: 	'interpreterProxy->stackValueOf(';
		nextPutAll: anInteger asString;
		nextPutAll: '))'
]

{ #category : #linking }
SmartSyntaxPluginCodeGenerator >> emitLoad: aString asFloatPtrFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: 	' = (float *) interpreterProxy->firstIndexableField(';
		crtab: 2;
		nextPutAll: 	'interpreterProxy->stackValueOf(';
		nextPutAll: anInteger asString;
		nextPutAll: '))'
]

{ #category : #linking }
SmartSyntaxPluginCodeGenerator >> emitLoad: aString asFloatValueFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: 	' = interpreterProxy->stackFloatValue(';
		nextPutAll: anInteger asString;
		nextPutAll: ')'
]

{ #category : #linking }
SmartSyntaxPluginCodeGenerator >> emitLoad: aString asIntPtrFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: 	' = (int *) interpreterProxy->firstIndexableField(';
		crtab: 2;
		nextPutAll: 	'interpreterProxy->stackValueOf(';
		nextPutAll: anInteger asString;
		nextPutAll: '))'
]

{ #category : #linking }
SmartSyntaxPluginCodeGenerator >> emitLoad: aString asIntegerValueFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: 	' = interpreterProxy stackIntegerValue(';
		nextPutAll: anInteger asString;
		nextPutAll: ')'
]

{ #category : #linking }
SmartSyntaxPluginCodeGenerator >> emitLoad: aString asKindOf: aClass from: anInteger on: aStream [

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
SmartSyntaxPluginCodeGenerator >> emitLoad: aString asMemberOf: aClass from: anInteger on: aStream [

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
SmartSyntaxPluginCodeGenerator >> emitLoad: aString asNakedOopFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: ' = interpreterProxy stackValue(';
		nextPutAll: anInteger asString;
		nextPutAll: ')'
]

{ #category : #linking }
SmartSyntaxPluginCodeGenerator >> emitLoad: aString asNonIntegerValueFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: 	' = interpreterProxy stackObjectValue(';
		nextPutAll: anInteger asString;
		nextPutAll: ')'
]

{ #category : #linking }
SmartSyntaxPluginCodeGenerator >> emitLoad: aString asUnsignedValueFrom: anInteger on: aStream [

	aStream
		nextPutAll: aString;
		nextPutAll: 	' = interpreterProxy->positive32BitValueOf(';
		crtab: 2;
		nextPutAll: 	'interpreterProxy->stackValue(';
		nextPutAll: anInteger asString;
		nextPutAll: '))'
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsBooleanObj: aNode on: aStream indent: anInteger [

	aStream nextPutAll: '('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: 
		') ? interpreterProxy->trueObject(): interpreterProxy->falseObject()'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsCBoolean: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->booleanValueOf('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsCDouble: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->floatValueOf('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsCInt: aNode on: aStream indent: anInteger [

	aStream nextPut: $(.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ' >> 1)'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsCUnsigned: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->positive32BitValueOf('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsCharPtr: aNode on: aStream indent: anInteger [

	aStream nextPutAll: '(char *) interpreterProxy->firstIndexableField('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsFloatObj: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->floatObjectOf('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsIfVar: aNode on: aStream indent: anInteger [

	| cName fName class index |
	cName := String streamContents: 
		[:scStr | self emitCExpression: aNode args first on: scStr].
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
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsIfVarAsValue: aNode on: aStream indent: anInteger [

	| cName fName class index fetchNode |
	cName := String streamContents: 
		[:scStr | self emitCExpression: aNode args first on: scStr].
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
	class ccg: self generateCoerceToValueFrom: fetchNode on: aStream

]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsIfVarPut: aNode on: aStream indent: anInteger [

	| cName fName class index |
	cName := String streamContents: 
		[:scStr | self emitCExpression: aNode args first on: scStr].
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
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ','.
	self emitCExpression: aNode args third on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsIntPtr: aNode on: aStream indent: anInteger [

	aStream nextPutAll: '(int *) interpreterProxy->firstIndexableField('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsOop: aNode on: aStream indent: anInteger [

	| cName class |
	cName := aNode args first nameOrValue.
	class := Smalltalk 
		at: (cName asSymbol) 
		ifAbsent: [nil].
	(class isNil not and: [class isBehavior]) ifFalse: 
		[^self error: 'first arg must identify class'].
	class ccg: self generateCoerceToOopFrom: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsPositiveIntegerObj: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->positive32BitIntegerFor('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsSmallIntegerObj: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->integerObjectOf('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsValue: aNode on: aStream indent: anInteger [

	| cName class |
	cName := aNode args first nameOrValue.
	class := Smalltalk 
		at: (cName asSymbol) 
		ifAbsent: [nil].
	(class isNil not and: [class isBehavior]) ifFalse: 
		[^self error: 'first arg must identify class'].
	class ccg: self generateCoerceToValueFrom: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateCPtrAsOop: aNode on: aStream indent: anInteger [

	aStream nextPutAll: '((sqInt)(long)('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ') - ';
		nextPutAll: ObjectMemory baseHeaderSize printString;
		nextPut: $).
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateClass: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->fetchClassOf('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToBooleanObjectFrom: aNode on: aStream [

	aStream nextPutAll: '('.
	self emitCExpression: aNode on: aStream.
	aStream nextPutAll: '? interpreterProxy->trueObject(): interpreterProxy->falseObject())'
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToBooleanValueFrom: aNode on: aStream [

	aStream nextPutAll: 'interpreterProxy->booleanValueOf('.
	self emitCExpression: aNode on: aStream.
	aStream nextPutAll: ')'
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToFloatObjectFrom: aNode on: aStream [

	aStream nextPutAll: 'interpreterProxy->floatObjectOf('.
	self emitCExpression: aNode on: aStream.
	aStream nextPutAll: ')'
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToFloatValueFrom: aNode on: aStream [

	aStream nextPutAll: 'interpreterProxy->floatValueOf('.
	self emitCExpression: aNode on: aStream.
	aStream nextPutAll: ')'
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToObjectFromPtr: aNode on: aStream [
	"This code assumes no named instance variables"

	aStream nextPutAll: '((int) '.
	self emitCExpression: aNode on: aStream.
	aStream nextPutAll: ') - 4'
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToPtr: aString fromObject: aNode on: aStream [
	"This code assumes no named instance variables"

	aStream 
		nextPutAll: '((';
		nextPutAll: aString;
		nextPutAll: ') interpreterProxy->firstIndexableField('.
	self emitCExpression: aNode on: aStream.
	aStream nextPutAll: '))'
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToSmallIntegerObjectFrom: aNode on: aStream [

	aStream nextPutAll: 'interpreterProxy->integerObjectOf('.
	self emitCExpression: aNode on: aStream.
	aStream nextPutAll: ')'
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToSmallIntegerValueFrom: aNode on: aStream [

	aStream nextPutAll: 'interpreterProxy->integerValueOf('.
	self emitCExpression: aNode on: aStream.
	aStream nextPutAll: ')'
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToUnsignedObjectFrom: aNode on: aStream [

	aStream nextPutAll: 'interpreterProxy->positive32BitIntegerFor('.
	self emitCExpression: aNode on: aStream.
	aStream nextPutAll: ')'
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToUnsignedValueFrom: aNode on: aStream [

	aStream nextPutAll: 'interpreterProxy->positive32BitValueOf('.
	self emitCExpression: aNode on: aStream.
	aStream nextPutAll: ')'
]

{ #category : #'debug code' }
SmartSyntaxPluginCodeGenerator >> generateDebugCode [
	^ debugFlag
]

{ #category : #'debug code' }
SmartSyntaxPluginCodeGenerator >> generateDebugCode: aBool [ 
	debugFlag := aBool
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateDebugCode: aNode on: aStream indent: level [ 
	"Generate the C debug code for this message onto the given stream, if  
	compiled in debugMode."
	self generateDebugCode
		ifTrue: 
			[aStream nextPutAll: '/* DebugCode... */';
			 cr.
			aNode args first
				emitCCodeOn: aStream
				level: level
				generator: self.
			aStream tab: level.
			aStream nextPutAll: '/* ...DebugCode */']
		ifFalse: [aStream nextPutAll: '/* missing DebugCode */']
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateField: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->fetchPointerofObject('.
	self emitCExpression: aNode args first on: aStream.
	aStream nextPutAll: ','.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateFieldPut: aNode on: aStream indent: anInteger [
		
	aStream nextPutAll: 'interpreterProxy->storePointerofObjectwithValue('.
	self emitCExpression: aNode args first on: aStream.
	aStream nextPutAll: ','.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ','.
	self emitCExpression: aNode args second on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateFromStack: aNode on: aStream indent: anInteger [

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
SmartSyntaxPluginCodeGenerator >> generateIsBytes: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isBytes('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsFloat: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isFloatObject('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsIndexable: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isIndexable('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsInteger: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isIntegerValue('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsIntegerOop: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isIntegerObject('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsIntegerValue: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isIntegerValue('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsKindOf: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isKindOf('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ','''.
	self emitCExpression: aNode args first on: aStream.
	aStream nextPutAll: ''')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsMemberOf: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isMemberOf('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ','''.
	self emitCExpression: aNode args first on: aStream.
	aStream nextPutAll: ''')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsPointers: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isPointers('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsWords: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isWords('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsWordsOrBytes: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->isWordsOrBytes('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateNext: msgNode on: aStream indent: level [
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
SmartSyntaxPluginCodeGenerator >> generateRemapOopIn: aNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| idList |
	idList := aNode args first nameOrValue.
	idList class == Array ifFalse: [idList := Array with: idList].
	idList do:
		[:each | 
		 aStream 
			nextPutAll: 'interpreterProxy->pushRemappableOop(';
			nextPutAll: each asString;
			nextPutAll: ');']
		separatedBy: [aStream crtab: level].
	aStream cr.
	aNode args second emitCCodeOn: aStream level: level generator: self.
	level timesRepeat: [aStream tab].
	idList reversed do:
		[:each |
		 aStream 
			nextPutAll: each asString;
			nextPutAll: ' = interpreterProxy->popRemappableOop()']
		separatedBy: [aStream nextPut: $;; crtab: level].
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateStAt: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->stObjectat('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ','.
	self emitCExpression: aNode args first on: aStream.
	aStream nextPutAll: ')'

]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateStAtPut: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->stObjectatput('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ','.
	self emitCExpression: aNode args first on: aStream.
	aStream nextPutAll: ','.
	self emitCExpression: aNode args second on: aStream.
	aStream nextPutAll: ')'

]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateStSize: aNode on: aStream indent: anInteger [

	aStream nextPutAll: 'interpreterProxy->stSizeOf('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #initialize }
SmartSyntaxPluginCodeGenerator >> initialize [
	super initialize.
	debugFlag := false
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> initializeCTranslationDictionary [ 
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

{ #category : #initialize }
SmartSyntaxPluginCodeGenerator >> translationMethodClass [
	"return the class used to produce C translation methods from MethodNodes"
	^SmartSyntaxPluginTMethod
]

{ #category : #transforming }
SmartSyntaxPluginCodeGenerator >> var: varName as: aClass [
	"Record the given C declaration for a global variable"

	variableDeclarations at: varName asString put: (aClass ccgDeclareCForVar: varName)
]
