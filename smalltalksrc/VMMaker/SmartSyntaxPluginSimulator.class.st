Class {
	#name : #SmartSyntaxPluginSimulator,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'actualPlugin',
		'signatureMap',
		'forMap',
		'pluginClass'
	],
	#category : #'VMMaker-SmartSyntaxPlugins'
}

{ #category : #simulation }
SmartSyntaxPluginSimulator class >> newFor: anUnsimulatedInterpreterPluginClass [
	| simulatorClass |
	simulatorClass := anUnsimulatedInterpreterPluginClass subclasses
						detect: [:sc| sc name endsWith: 'Simulator']
						ifNone: [anUnsimulatedInterpreterPluginClass].
	^self new
		actualPlugin: simulatorClass new signatureClass: anUnsimulatedInterpreterPluginClass;
		yourself
]

{ #category : #simulation }
SmartSyntaxPluginSimulator class >> shouldBeTranslated [
	^false
]

{ #category : #accessing }
SmartSyntaxPluginSimulator >> actualPlugin [
	"Answer the value of actualPlugin"

	^ actualPlugin
]

{ #category : #accessing }
SmartSyntaxPluginSimulator >> actualPlugin: aSmartSyntaxInterpreterPlugin signatureClass: signatureClass [
	pluginClass := signatureClass.
	actualPlugin := aSmartSyntaxInterpreterPlugin.
	actualPlugin simulator: self
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> ccgLoad: forProlog expr: failBlock asBooleanValueFrom: anInteger [ 
	^[:oop| interpreterProxy booleanValueOf: oop]
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> ccgLoad: codeGen expr: exprBlock asCharPtrFrom: stackIndex andThen: validateBlock [
	^[:oop|
	   validateBlock value: oop.
	   interpreterProxy cCoerce: (interpreterProxy firstIndexableField: oop) asInteger to: #'char *']
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> ccgLoad: codeGen expr: exprBlock asFloatValueFrom: stackIndex [
	self shouldBeImplemented
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> ccgLoad: codeGen expr: exprBlock asIntPtrFrom: stackIndex andThen: validateBlock [
	^[:oop|
	   validateBlock value: oop.
	   interpreterProxy cCoerce: (interpreterProxy firstIndexableField: oop) asInteger to: #'int *']
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> ccgLoad: forProlog expr: failBlock asIntegerValueFrom: anInteger [ 
	^[:oop| interpreterProxy checkedIntegerValueOf: oop]
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> ccgLoad: forProlog expr: failBlock asKindOf: aClass from: argIndexOrNil [ 
	^[:oop|
	   interpreterProxy success: (interpreterProxy is: oop KindOf: aClass name asString).
	   oop]
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> ccgLoad: forProlog expr: failBlock asKindOfIntegerFrom: argIndexOrNil [ 
	^[:oop|
	   interpreterProxy success: (interpreterProxy isKindOfInteger: oop).
	   oop]
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> ccgLoad: forProlog expr: failBlock asMemberOfLargeNegativeIntegerFrom: argIndexOrNil [ 
	^[:oop|
	   interpreterProxy success: (interpreterProxy isLargeNegativeIntegerObject: oop).
	   oop]
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> ccgLoad: forProlog expr: failBlock asMemberOfLargePositiveIntegerFrom: argIndexOrNil [ 
	^[:oop|
	   interpreterProxy success: (interpreterProxy isLargePositiveIntegerObject: oop).
	   oop]
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> ccgLoad: codeGen expr: exprBlock asOopPtrFrom: stackIndex andThen: validateBlock [
	^[:oop|
	   validateBlock value: oop.
	   interpreterProxy cCoerce: (interpreterProxy firstIndexableField: oop) asInteger to: #'sqInt *']
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> ccgLoad: forProlog expr: failBlock asRawOopFrom: anUndefinedObject [ 
	^[:oop| oop]
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> ccgLoad: codeGen expr: exprBlock asUnsignedPtrFrom: stackIndex andThen: validateBlock [
	^[:oop|
	   validateBlock value: oop.
	   interpreterProxy cCoerce: (interpreterProxy firstIndexableField: oop) asInteger to: #'unsigned *']
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> ccgLoad: codeGen expr: exprBlock asUnsignedValueFrom: stackIndex [
	self shouldBeImplemented
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> ccgLoad: codeGen expr: exprBlock asWBFloatPtrFrom: stackIndex [
	self shouldBeImplemented
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> ccgValBlock: aString [ 
	^aString caseOf: {
		['isBytes']			-> [	[:oop|
								 interpreterProxy success: (interpreterProxy isBytes: oop).
								 oop]].
		['isWordsOrBytes']	-> [	[:oop|
								 interpreterProxy success: (interpreterProxy isWordsOrBytes: oop).
								 oop]] }
]

{ #category : #initialize }
SmartSyntaxPluginSimulator >> computeSignatureFor: selector from: tuple [
	| signature |
	self assert: tuple first == #forMap.
	signature := tuple third collect:
					[:className|
					(Smalltalk classNamed: className)
						ifNil: [self error: 'Argument class' , className, ' does not exist']
						ifNotNil:
							[:argClass|
							argClass
								ccg: self
								prolog: true
								expr: [interpreterProxy primitiveFail]
								index: nil]].
	^signatureMap
		at: tuple second asSymbol
		put: {	selector.
				signature.
				tuple fourth
					ifNil: [[:oop| oop]]
					ifNotNil:
						[:rcvrClassSymbol|
						(Smalltalk classNamed: rcvrClassSymbol)
							ifNil: [self error: 'Receiver class' , rcvrClassSymbol, ' does not exist']
							ifNotNil:
								[:rcvrClass|
								rcvrClass
									ccg: self
									prolog: false
									expr: [interpreterProxy primitiveFail]
									index: nil]] }
]

{ #category : #initialize }
SmartSyntaxPluginSimulator >> computeSignatureMap [
	forMap := true. "true only while we compute the signatureMap"
	signatureMap := Dictionary new.
	pluginClass selectorsAndMethodsDo:
		[:s :m|
		(m messages includesAnyOf: #(primitive: primitive:parameters: primitive:parameters:receiver:))
			ifTrue: [self getPrimitiveSignatureFor: s]
			ifFalse:
				[(m pragmaAt: #export:) ifNotNil:
					[:exportPragma|
					(exportPragma argumentAt: 1) ifTrue:
						[self computeSignatureFor: s from: { #forMap. s. #(). nil }]]]].
	forMap := false
]

{ #category : #'message forwarding' }
SmartSyntaxPluginSimulator >> doesNotUnderstand: aMessage [
	| signature selector parameters result |
	signature := signatureMap
					at: aMessage selector
					ifAbsent: [^super doesNotUnderstand: aMessage].
	selector := signature first.
	parameters := signature second.
	signature third "receiver block" value: (interpreterProxy stackValue: parameters size).
	interpreterProxy failed ifTrue:
		[^nil].
	result := [actualPlugin
					perform: selector
					withArguments: (parameters withIndexCollect:
										[:block :index|
										block value: (interpreterProxy stackValue: parameters size - index)])]
					on: Notification
					do: [:ex|
						ex tag == #getSimulator
							ifTrue: [ex resume: self]
							ifFalse: [ex pass]].
	interpreterProxy failed ifTrue:
		[^nil].
	result == actualPlugin ifTrue:
		[interpreterProxy pop: interpreterProxy methodArgumentCount.
		 ^nil].
	interpreterProxy
		pop: interpreterProxy methodArgumentCount + 1
		thenPush: result.
	^nil "SmartSyntaxPluginPrimitives return null"
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> generateCoerceToBooleanObjectFrom: aBoolean on: ignored [
	^interpreterProxy booleanObjectOf: aBoolean
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> generateCoerceToFloatObjectFrom: aNumber on: ignored [
	^interpreterProxy floatObjectOf: aNumber
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> generateCoerceToSmallIntegerObjectFrom: aSmallInteger on: ignored [ 
	^interpreterProxy integerObjectOf: aSmallInteger
]

{ #category : #initialize }
SmartSyntaxPluginSimulator >> getPrimitiveSignatureFor: s [
	"Execute the primitive until the send of #primitive:parameters: or primitive:parameters:receiver:,
	collect the processed signature and store it in the map"
	[actualPlugin perform: s withArguments: (1 to: s numArgs) asArray]
		on: Notification
		do: [:ex|
			(ex tag isArray
			 and: [ex tag first == #forMap]) ifTrue:
				[^self computeSignatureFor: s from: ex tag]].
	self error: 'can''t find primitive name in ', s
]

{ #category : #initialize }
SmartSyntaxPluginSimulator >> initialiseModule [
	^(actualPlugin respondsTo: #initialiseModule) not
	  or: [actualPlugin initialiseModule]
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> isPluginClass [
	"This stands in for SmartSyntaxInterpreterPlugin classes during simulation."
	^true
]

{ #category : #accessing }
SmartSyntaxPluginSimulator >> isSmartSyntaxPluginSimulator [
	<doNotGenerate>
	^true
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> primitive: primNameString [
	"If initializing, pass back the type signature.  If executing, answer nil."
	^self primitive: primNameString parameters: #() receiver: nil
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> primitive: primNameString parameters: argumentClassNames [
	"If initializing, pass back the type signature.  If executing, answer nil."
	^self primitive: primNameString parameters: argumentClassNames receiver: nil
]

{ #category : #simulation }
SmartSyntaxPluginSimulator >> primitive: primNameString parameters: argumentClassNames receiver: rcvrClassSymbolOrNil [
	"If initializing, pass back the type signature.  If executing, answer the receiver or nil."
	forMap
		ifTrue:
			[Notification new
				tag: {#forMap. primNameString. argumentClassNames. rcvrClassSymbolOrNil};
				signal]
		ifFalse:
			[^rcvrClassSymbolOrNil ifNotNil:
				[interpreterProxy stackValue: interpreterProxy methodArgumentCount]]
]

{ #category : #'message forwarding' }
SmartSyntaxPluginSimulator >> respondsTo: aSelector [
	^(signatureMap notNil and: [signatureMap includesKey: aSelector])
	  or: [super respondsTo: aSelector]
]

{ #category : #initialize }
SmartSyntaxPluginSimulator >> setInterpreter: anInterpreterProxy [
	interpreterProxy := anInterpreterProxy.
	actualPlugin setInterpreter: anInterpreterProxy.
	self computeSignatureMap
]
