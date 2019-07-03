Class {
	#name : #CCodeGeneratorInlineStrategy,
	#superclass : #Object,
	#instVars : [
		'codeGenerator'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'instance-cre' }
CCodeGeneratorInlineStrategy class >> always [
	
	^ CCodeGeneratorInlineAlwaysStrategy new
]

{ #category : #'instance-creation' }
CCodeGeneratorInlineStrategy class >> asSpecified [

	^ CCodeGeneratorInlineAsSpecifiedStrategy new
]

{ #category : #'instance-creation' }
CCodeGeneratorInlineStrategy class >> asSpecifiedOrQuick [

	^ CCodeGeneratorInlineAsSpecifiedOrQuickStrategy new
]

{ #category : #'instance creation' }
CCodeGeneratorInlineStrategy class >> from: anObject [
	
	"The argument is either a boolean or a sumbol.
	If a boolean, it indicates if we need to inline or not.
	If == #asSpecified only inline methods marked with <inline: true>.
	If == #asSpecifiedOrQuick only inline methods marked with <inline: true> or methods that are quick (^constant, ^inst var)."
	
	(#(true false) includes: anObject) ifTrue: [ 
		^ anObject
			ifTrue: [ self always ]
			ifFalse: [ self never ].
	].

	"If the object is a selector use a perform to instantiate it."
	^ self perform: anObject
]

{ #category : #'instance-crea' }
CCodeGeneratorInlineStrategy class >> never [

	^ CCodeGeneratorInlineNeverStrategy new
]

{ #category : #testing }
CCodeGeneratorInlineStrategy >> canInline: aTMethod [
	
	^ (self hasUnrenamableCCode: aTMethod) not
		and: [ aTMethod extractInlineDirective ~= false ]
]

{ #category : #accessing }
CCodeGeneratorInlineStrategy >> codeGenerator [
	^ codeGenerator
]

{ #category : #accessing }
CCodeGeneratorInlineStrategy >> codeGenerator: anObject [
	codeGenerator := anObject
]

{ #category : #testing }
CCodeGeneratorInlineStrategy >> hasUnrenamableCCode: aTMethod [

	^ (codeGenerator isSpecialSelector: aTMethod selector)
		or: [ aTMethod hasUnrenamableCCode ]
]

{ #category : #testing }
CCodeGeneratorInlineStrategy >> isSelectiveInlineStrategy [
	
	^ false
]

{ #category : #asserting }
CCodeGeneratorInlineStrategy >> shouldInlineMethod: aMethod [

	^ self canInline: aMethod
]

{ #category : #asserting }
CCodeGeneratorInlineStrategy >> validateCanInline: aMethod [

	((self canInline: aMethod) not
		and: [ self wantsInline: aMethod ]) ifTrue: [
			"don't inline if method has C code or contains negative inline directive"
			codeGenerator cannotInline: aMethod selector ]
]

{ #category : #testing }
CCodeGeneratorInlineStrategy >> wantsInline: aTMethod [ 
	
	^ (codeGenerator isSpecialSelector: aTMethod selector) not
		and: [ aTMethod extractInlineDirective == true ]
]
