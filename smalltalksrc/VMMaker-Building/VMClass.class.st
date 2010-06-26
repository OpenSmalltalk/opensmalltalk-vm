"
I am an abstract superclass for all classes in the VM that want to maintain a source timeStamp.
"
Class {
	#name : #VMClass,
	#superclass : #Object,
	#classInstVars : [
		'timeStamp'
	],
	#category : #'VMMaker-Support'
}

{ #category : #translation }
VMClass class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	^#()
]

{ #category : #translation }
VMClass class >> ancilliaryStructClasses [
	^#()
]

{ #category : #translation }
VMClass class >> apiExportHeaderName [
	"VM classesd that want to generate an api export header override this."
	^nil
]

{ #category : #translation }
VMClass class >> declareC: arrayOfVariableNames as: aCType in: aCCodeGenerator [
	"Declare the variables in arrayOfVariableNames with the given type."

	arrayOfVariableNames
		do: [:varName | aCCodeGenerator var: varName type: aCType]
]

{ #category : #translation }
VMClass class >> declareCVarsIn: aCCodeGenerator [ 
	"Declare any additional variables and/or add type declarations for existing variables."
]

{ #category : #debugger }
VMClass class >> defaultIntegerBaseInDebugger [
	^16
]

{ #category : #translation }
VMClass class >> emitExportPragma [	
	"#pragma export -- seems only to have been for CodeWarrior on Mac."
	^false
]

{ #category : #translation }
VMClass class >> exportAPISelectors [
	^self exportAPISelectorsFor: self
]

{ #category : #translation }
VMClass class >> exportAPISelectorsFor: aClass [
	^(aClass selectors select:
		[:s| | m |
		((m := aClass compiledMethodAt: s) pragmaAt: #api) notNil or: [(m pragmaAt: #api:) notNil]]) asSet
]

{ #category : #translation }
VMClass class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#sqInt
]

{ #category : #translation }
VMClass class >> isAccessor: aSelector [
	"Answer if aSelector is simply an accessor method for one of our fields.
	 Answer false by default.  VMStructType classes redefine this appropriately."
	^false
]

{ #category : #translation }
VMClass class >> isCogitClass [
	"The various Cogit classes override this."
	^false
]

{ #category : #translation }
VMClass class >> isInterpreterClass [
	"The various Interpreter classes override this."
	^false
]

{ #category : #translation }
VMClass class >> noteCompilationOf: aSelector meta: isMeta [
	"note the recompiliation by resetting the timeStamp "
	timeStamp := Time totalSeconds.
	^super noteCompilationOf: aSelector meta: isMeta
]

{ #category : #'accessing class hierarchy' }
VMClass class >> objectMemoryClass [
	"Default for all-in-one VMs where the interpreter inherits from the object memory."
	^nil
]

{ #category : #translation }
VMClass class >> prepareToBeAddedToCodeGenerator: aCCodeGenerator [ 
	"Hook for translation.  e.g. allows a subclass to override its
	 superclass's methods by deleting them before it adds its own."
]

{ #category : #translation }
VMClass class >> requiredMethodNames [
	"Answer the methods that must be retained, e.g. because they are exported to external code."
	^#()
]

{ #category : #translation }
VMClass class >> shouldGenerateTypedefFor: aStructClass [
	"Hack to work-around mutliple definitions.  Sometimes a type has been defined in an include."
	^true
]

{ #category : #translation }
VMClass class >> specialValueForConstant: constantName [
	^nil
]

{ #category : #translation }
VMClass class >> timeStamp [
	^timeStamp ifNil:[0]
]

{ #category : #translation }
VMClass class >> touch [
	"Reset the timeStamp"
	"Smalltalk allClasses select:
		[:c| (c category includesSubString: 'VMMaker-JIT') ifTrue: [c touch]]"
	"InterpreterPlugin withAllSubclassesDo:[:pl| pl touch]"
	timeStamp := Time totalSeconds
]

{ #category : #translation }
VMClass class >> typeForSelf [
	"Answer the type to give self if appropriate, or nil if not."
	^nil
]

{ #category : #translation }
VMClass class >> writeVMHeaderTo: tempStream bytesPerWord: bytesPerWord [
	"No op hook allowing ancialliary classes to write whatever they deem fit to interp.h"
]

{ #category : #'translation support' }
VMClass >> addressOf: anObject [
	"Translates into &anObject in C."
	^anObject
]

{ #category : #'debug support' }
VMClass >> asserta: aBooleanExpression [
	<doNotGenerate>
	| result |
	(result := aBooleanExpression value) ifFalse:
		[AssertionFailure signal: 'Assertion failed'].
	^result
]

{ #category : #'translation support' }
VMClass >> pointerForOop: oop [
	"This gets implemented by Macros in C, where its types will also be checked.
	 oop is the width of a machine word, and pointer is a raw address."
	<doNotGenerate>

	^oop
]

{ #category : #arithmetic }
VMClass >> safe: signedInteger mod: positiveModulus [
	<inline>
	| remainder |
	^(remainder := signedInteger \\ positiveModulus) < 0
		ifTrue: [remainder + positiveModulus]
		ifFalse: [remainder]
]
