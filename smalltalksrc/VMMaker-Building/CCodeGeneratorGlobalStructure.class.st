"
This subclass of CCodeGenerator adds support for sticking most global variables into a large global array. This in turn means that suitably minded C compilers can do a better job of accessing those variables; in particular the Mac OS use of PPC and Acorn use of ARM benfits by a substantial margin. 

Only simple globals are currently put in the array. Someday we might try adding pointers to the various arrays etc.
"
Class {
	#name : #CCodeGeneratorGlobalStructure,
	#superclass : #CCodeGenerator,
	#instVars : [
		'localStructDef'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> buildSortedVariablesCollection [
	"Build sorted vars, end result will be sorted collection based on static usage, 
	perhaps cache lines will like this!"

	| globalNames sorted |

	globalNames := Bag new: globalVariableUsage size.
	globalVariableUsage keysAndValuesDo: [:k :v | 
		(variableDeclarations includesKey: k) ifFalse: 
			[globalNames add: k withOccurrences: v size]].	
	variableDeclarations keysDo: 
		[:e | globalNames add: e withOccurrences: 0].
	sorted := SortedCollection sortBlock: 
		[:a :b | (globalNames occurrencesOf: a) > (globalNames occurrencesOf: b)].
	sorted addAll: variables.
	^sorted
]

{ #category : #utilities }
CCodeGeneratorGlobalStructure >> checkForGlobalUsage: vars in: aTMethod [ 
	"override to handle global struct needs"
	super checkForGlobalUsage: vars in: aTMethod.
	"if localStructDef is false, we  don't ever need to include a reference to it in a function"
	localStructDef ifFalse:[^self].
	vars asSet do: [:var |
		"if any var is global and in the global var struct 
		tell the TMethod it will be refering to the  struct"
			  ((self globalsAsSet includes: var )
					and: [self placeInStructure: var ])
				ifTrue: [aTMethod referencesGlobalStructIncrementBy: (vars occurrencesOf: var)]]
]

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag [
	super emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag.

	"if the machine needs the globals structure defined locally in the interp.c file, don't add the folowing function"
	localStructDef ifFalse:[self emitStructureInitFunctionOn: aStream]
]

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> emitCVariablesOn: aStream [
	"Store the global variable declarations on the given stream.
	break logic into vars for structure and vars for non-structure"
	| varString structure nonstruct target |

	structure := WriteStream on: (String new: 32768).
	nonstruct := WriteStream on: (String new: 32768).
	aStream nextPutAll: '/*** Variables ***/'; cr.
	structure nextPutAll: 'static struct foo {'; cr.
	self buildSortedVariablesCollection do: [ :var |
		varString := var asString.
		target := (self placeInStructure: var) 
			ifTrue: [structure]
			ifFalse: [nonstruct].
		(self isGeneratingPluginCode) ifTrue:[
			varString = 'interpreterProxy' ifTrue:[
				"quite special..."
				aStream cr; nextPutAll: '#ifdef SQUEAK_BUILTIN_PLUGIN'.
				aStream cr; nextPutAll: 'extern'.
				aStream cr; nextPutAll: '#endif'; cr.
			] ifFalse:[aStream nextPutAll:'static '].
		].
		(variableDeclarations includesKey: varString) ifTrue: [
			target nextPutAll: (variableDeclarations at: varString), ';'; cr.
		] ifFalse: [
			"default variable declaration"
			target nextPutAll: 'sqInt ', varString, ';'; cr.
		].
	].
	structure nextPutAll: ' } fum;';cr.

	"if the machine needs the fum structure defining locally, do it now"
	localStructDef ifTrue:[structure nextPutAll: 'struct foo * foo = &fum;';cr;cr].

	aStream nextPutAll: structure contents.
	aStream nextPutAll: nonstruct contents.
	aStream cr.
]

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> emitGlobalStructFlagOn: aStream [
	"Define SQ_USE_GLOBAL_STRUCT before including the header."

	aStream nextPutAll: '#define SQ_USE_GLOBAL_STRUCT 1'; cr; cr
]

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> emitStructureInitFunctionOn: aStream [ 
	"For the VM using a global struct for most of the global vars (useful for ARM and PPC so far), append the initGlobalStructure() function"
	aStream 
		cr;
		nextPutAll: 'void initGlobalStructure(void) {foo = &fum;}';
		cr
]

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> globalStructDefined: aBool [
	localStructDef := aBool
]

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> initialize [
	super initialize.
	localStructDef := false
]

{ #category : #public }
CCodeGeneratorGlobalStructure >> isGlobalStructureBuild [
	^true
]

{ #category : #utilities }
CCodeGeneratorGlobalStructure >> localizeGlobalVariables [
"TPR - remove all the global vars destined for the structure that are only used once - not worth the space,
actually what will happen is the folding code will fold these variables into the method"

	super localizeGlobalVariables.
	globalVariableUsage := globalVariableUsage select: [:e | e size > 1].

]

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> placeInStructure: var [
	"See if we should put this array into a structure
	This has hard coded vars, should go somewhere else!
	The variables listed are hardcoded as C in the interpreter thus they don't get resolved via TVariableNode logic
	Also let's ignore variables that have special definitions that require initialization, and the function def which has problems"

	| check |
	check := variableDeclarations at: var ifAbsent: [''].
	(check includes: $=) ifTrue: [^false].
	(check includes: $() ifTrue: [^false].

	(#( 'showSurfaceFn' 'memory' 'extraVMMemory' 'interpreterProxy') includes: var) ifTrue: [^false].
	^true.
	
]

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> returnPrefixFromVariable: aName [
	^((self globalsAsSet includes: aName) and: [self placeInStructure: aName])
		ifTrue: ['foo->',aName]
		ifFalse: [aName]
]
