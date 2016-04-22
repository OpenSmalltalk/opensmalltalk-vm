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
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asKindOfIntegerFrom: anInteger [ 

	^String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy success: (interpreterProxy isKindOfInteger: (interpreterProxy stackValue: ';
		nextPutAll: anInteger asString;
		nextPutAll: ')).';
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
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asMemberOfLargeNegativeIntegerFrom: anInteger [ 

	^String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy success: (interpreterProxy isLargeNegativeIntegerObject: (interpreterProxy stackValue: ';
		nextPutAll: anInteger asString;
		nextPutAll: ')).';
		crtab;
		nextPutAll: (self 
						ccgLoad: aBlock 
						expr: aString 
						asRawOopFrom: anInteger)]
]

{ #category : #coercing }
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asMemberOfLargePositiveIntegerFrom: anInteger [ 

	^String streamContents: [:aStream | aStream
		nextPutAll: 'interpreterProxy success: (interpreterProxy isLargePositiveIntegerObject: (interpreterProxy stackValue: ';
		nextPutAll: anInteger asString;
		nextPutAll: ')).';
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
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asOopPtrFrom: anInteger [
	"Answer codestring for integer pointer to first indexable field of object (without validating side-effect), as described in comment to ccgLoad:expr:asRawOopFrom:"

	^aBlock value: (String streamContents:
		[:aStream |
		 aStream
			nextPutAll: 'self cCoerce: (interpreterProxy firstIndexableField:';
			crtab: 4;
			nextPutAll: '(interpreterProxy stackValue:';
			print: anInteger;
			nextPutAll:	'))';
			crtab: 3;
			nextPutAll: 'to: ''sqInt *'''])
]

{ #category : #coercing }
SmartSyntaxPluginCodeGenerator >> ccgLoad: aBlock expr: aString asOopPtrFrom: anInteger andThen: valBlock [
	"Answer codestring for integer pointer to first indexable field of object (without validating side-effect unless specified in valBlock), as described in comment to ccgLoad:expr:asRawOopFrom:"

	^(valBlock value: anInteger), '.',
	 (aBlock value: (String streamContents:
		[:aStream |
		aStream
			nextPutAll: 'self cCoerce: (interpreterProxy firstIndexableField:';
			crtab: 4;
			nextPutAll: '(interpreterProxy stackValue:';
			print: anInteger;
			nextPutAll:	'))';
			crtab: 3;
			nextPutAll: 'to: ''sqInt *''']))
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

	^aBlock value: (String streamContents: [:aStream |
		aStream
			nextPutAll: '(interpreterProxy bytesPerOop = 4';
			crtab: 2;
			nextPutAll: 'ifTrue: [interpreterProxy positive32BitValueOf:';
			crtab: 4;
			nextPutAll: '(interpreterProxy stackValue:';
			print: anInteger;
			nextPutAll: ')]';
			crtab: 2;
			nextPutAll: 'ifFalse: [interpreterProxy positive64BitValueOf:';
			crtab: 4;
			nextPutAll: '(interpreterProxy stackValue:';
			print: anInteger;
			nextPutAll: ')])'])
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

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> genCallOf: aSelector with: aNode on: aStream [
	pluginFunctionsUsed add: aSelector.
	aStream nextPutAll: (self cFunctionNameFor: aSelector).
	aStream nextPut: $(.
	self emitCExpression: aNode on: aStream.
	aStream nextPut: $)
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> genCallOf: aSelector with: firstArgNode with: secondArgNode on: aStream [
	pluginFunctionsUsed add: aSelector.
	aStream nextPutAll: (self cFunctionNameFor: aSelector).
	aStream nextPut: $(.
	self emitCExpression: firstArgNode on: aStream.
	aStream nextPut: $,.
	self emitCExpression: secondArgNode on: aStream.
	aStream nextPut: $)
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> genCallOf: aSelector with: firstArgNode with: secondArgNode with: thirdArgNode on: aStream [
	pluginFunctionsUsed add: aSelector.
	aStream nextPutAll: (self cFunctionNameFor: aSelector).
	aStream nextPut: $(.
	self emitCExpression: firstArgNode on: aStream.
	aStream nextPut: $,.
	self emitCExpression: secondArgNode on: aStream.
	aStream nextPut: $,.
	self emitCExpression: thirdArgNode on: aStream.
	aStream nextPut: $)
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsBooleanObj: aNode on: aStream indent: anInteger [
	pluginFunctionsUsed add: #trueObject; add: #falseObject.
	aStream nextPutAll: '(('.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPutAll: ') ? trueObject() : falseObject())'.
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsCBoolean: aNode on: aStream indent: anInteger [
	self genCallOf: #booleanValueOf: with: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsCDouble: aNode on: aStream indent: anInteger [
	self genCallOf: #floatValueOf: with: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsCInt: aNode on: aStream indent: anInteger [
	self genCallOf: #integerValueOf: with: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsCUnsigned: aNode on: aStream indent: anInteger [
	self genCallOf: #positive32BitValueOf: with: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsCharPtr: aNode on: aStream indent: anInteger [
	self generateCoerceToPtr: 'char *' fromObject: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsFloatObj: aNode on: aStream indent: anInteger [
	self genCallOf: #floatObjectOf: with: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsIfVar: aNode on: aStream indent: anInteger [

	| cName fName class index |
	cName := String streamContents: 
		[:scStr | self emitCExpression: aNode args first on: scStr].
	(class := Smalltalk classNamed: cName) isBehavior ifFalse: 
		[^self error: 'first arg must identify class'].
	fName := aNode args second value.
	index := class
				instVarIndexFor: fName
				ifAbsent: [^self error: 'second arg must be instVar'].
	pluginFunctionsUsed add: #fetchPointer:ofObject:.
	aStream nextPutAll: 'fetchPointerofObject('; print: index - 1; nextPut: $,.
	self emitCExpression: aNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsIfVarAsValue: aNode on: aStream indent: anInteger [

	| cName fName class index fetchNode |
	cName := String streamContents: 
				[:scStr | self emitCExpression: aNode args first on: scStr].
	(class := Smalltalk classNamed: cName) isBehavior ifFalse: 
		[^self error: 'first arg must identify class'].
	fName := aNode args second value.
	index := class
				instVarIndexFor: fName
				ifAbsent: [^self error: 'second arg must be instVar'].
	fetchNode := TSendNode new
					setSelector: #fetchPointer:ofObject:
					receiver: (TVariableNode new setName: 'self')
					arguments: { TConstantNode new setValue: index - 1. aNode receiver}.
	cName := aNode args third nameOrValue.
	(class := Smalltalk classNamed: cName) isBehavior ifFalse: 
		[^self error: 'third arg must identify class'].
	class ccg: self generateCoerceToValueFrom: fetchNode on: aStream

]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsIfVarPut: aNode on: aStream indent: anInteger [

	| cName fName class index |
	cName := String streamContents: 
		[:scStr | self emitCExpression: aNode args first on: scStr].
	(class := Smalltalk classNamed: cName) isBehavior ifFalse: 
		[^self error: 'first arg must identify class'].
	fName := aNode args second value.
	index := class
				instVarIndexFor: fName
				ifAbsent: [^self error: 'second arg must be instVar'].
	pluginFunctionsUsed add: #storePointer:ofObject:withValue:.
	aStream  nextPutAll: 'storePointerofObjectwithValue('; print: index - 1; nextPut: $,.
	self emitCExpression: aNode receiver on: aStream.
	aStream  nextPut: $,.
	self emitCExpression: aNode args third on: aStream.
	aStream  nextPut: $)
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsIntPtr: aNode on: aStream indent: anInteger [
	self generateCoerceToPtr: 'int *' fromObject: aNode receiver on: aStream
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
	self genCallOf: #positive32BitIntegerFor: with: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateAsSmallIntegerObj: aNode on: aStream indent: anInteger [
	self genCallOf: #integerObjectOf: with: aNode receiver on: aStream
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
	aStream nextPutAll: ') - BaseHeaderSize)'
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateClass: aNode on: aStream indent: anInteger [
	self genCallOf: #fetchClassOf: with: aNode receiver on: aStream
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToBooleanObjectFrom: aNode on: aStream [
	pluginFunctionsUsed add: #trueObject; add: #falseObject.
	aStream nextPutAll: '(('.
	self emitCExpression: aNode on: aStream.
	aStream nextPutAll: ') ? trueObject() : falseObject())'
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToBooleanValueFrom: aNode on: aStream [
	self genCallOf: #booleanValueOf: with: aNode receiver on: aStream
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToFloatObjectFrom: aNode on: aStream [
	self genCallOf: #floatObjectOf: with: aNode on: aStream
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToFloatValueFrom: aNode on: aStream [
	self genCallOf: #floatValueOf: with: aNode on: aStream
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToObjectFromPtr: aNode on: aStream [
	"This code assumes no named instance variables"

	aStream nextPutAll: '((sqInt)(('.
	self emitCExpression: aNode on: aStream.
	aStream nextPutAll: ') - BaseHeaderSize))'
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToPtr: aString fromObject: aNode on: aStream [
	"This code assumes no named instance variables"
	aStream 
		nextPutAll: '((';
		nextPutAll: aString;
		nextPut: $).
	self genCallOf: #firstIndexableField: with: aNode on: aStream.
	aStream nextPut: $)
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToSmallIntegerObjectFrom: aNode on: aStream [
	self genCallOf: #integerObjectOf: with: aNode on: aStream
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToSmallIntegerValueFrom: aNode on: aStream [
	self genCallOf: #integerValueOf: with: aNode on: aStream
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToUnsignedObjectFrom: aNode on: aStream [
	self genCallOf: #positive32BitIntegerFor: with: aNode on: aStream
]

{ #category : #'asOop:/asValue:' }
SmartSyntaxPluginCodeGenerator >> generateCoerceToUnsignedValueFrom: aNode on: aStream [
	self genCallOf: #positive32BitValueOf: with: aNode on: aStream
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
	self genCallOf: #fetchPointer:ofObject: with: aNode args first with: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateFieldPut: aNode on: aStream indent: anInteger [
	self genCallOf: #storePointer:ofObject:withValue:
		with: aNode args first
		with: aNode receiver
		with: aNode args second
		on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateFromStack: aNode on: aStream indent: anInteger [
	| idList |
	aNode args first isConstant ifFalse: [^self error: 'arg must be constant'].
	pluginFunctionsUsed add: #stackValue:.
	idList := aNode args first value.
	(1 to: idList size)
		do: [:i | 
			aStream 
				nextPutAll: (idList at: i);
				nextPutAll: ' = stackValue(';
				nextPutAll: (idList size - i) asString;
				nextPut: $)]
		separatedBy: [aStream nextPut: $;; crtab: anInteger].

]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsFloat: aNode on: aStream indent: anInteger [
	self genCallOf: #isFloatObject: with: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsIndexable: aNode on: aStream indent: anInteger [
	self genCallOf: #isIndexable: with: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsIntegerOop: aNode on: aStream indent: anInteger [
	self genCallOf: #isIntegerObject: with: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsIntegerValue: aNode on: aStream indent: anInteger [
	self genCallOf: #isIntegerValue: with: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsKindOf: aNode on: aStream indent: anInteger [
	self genCallOf: #is:KindOf: with: aNode receiver with: aNode args first on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsMemberOf: aNode on: aStream indent: anInteger [
	self genCallOf: #is:MemberOf: with: aNode receiver with: aNode args first on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsPointers: aNode on: aStream indent: anInteger [
	self genCallOf: #isPointers: with: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsWords: aNode on: aStream indent: anInteger [
	self genCallOf: #isWords: with: aNode receiver on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateIsWordsOrBytes: aNode on: aStream indent: anInteger [
	self genCallOf: #isWordsOrBytes: with: aNode receiver on: aStream
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
SmartSyntaxPluginCodeGenerator >> generateStAt: aNode on: aStream indent: anInteger [
	self genCallOf: #stObject:at: with: aNode receiver with: aNode args first on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateStAtPut: aNode on: aStream indent: anInteger [
	self genCallOf: #stObject:at:put:
		with: aNode receiver
		with: aNode args first
		with: aNode args second
		on: aStream
]

{ #category : #'translating builtins' }
SmartSyntaxPluginCodeGenerator >> generateStSize: aNode on: aStream indent: anInteger [
	self genCallOf: #stSizeOf: with: aNode receiver on: aStream
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
		"#FloatOop					#generateIsFloatValue:on:indent:"		"unused, never implemented"
		#isWords					#generateIsWords:on:indent:
		#isWordsOrBytes				#generateIsWordsOrBytes:on:indent:
		#isPointers					#generateIsPointers:on:indent:
		#isNil						#generateIsNil:on:indent:
		#isMemberOf:				#generateIsMemberOf:on:indent:
		#isKindOf:					#generateIsKindOf:on:indent:

		#fromStack:					#generateFromStack:on:indent:
		"#clone						#generateClone:on:indent:"				"unused, never implemented"
		"#new						#generateNew:on:indent:"				"unused, never implemented"
		"#new:						#generateNewSize:on:indent:"			"unused, never implemented"
		"#superclass					#generateSuperclass:on:indent:"	"unused, never implemented"
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
