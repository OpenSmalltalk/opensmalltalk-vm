"
This subclass of CCodeGenerator adds support for sticking most global variables into a large global array. This in turn means that suitably minded C compilers can do a better job of accessing those variables; in particular the Mac OS use of PPC and Acorn use of ARM benfits by a substantial margin. 

Only simple globals are currently put in the array. Someday we might try adding pointers to the various arrays etc.
"
Class {
	#name : #CCodeGeneratorGlobalStructure,
	#superclass : #CCodeGenerator,
	#instVars : [
		'localStructDef',
		'structDefDefine'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> buildSortedVariablesCollection [
	"Build sorted vars, end result will be sorted collection based on static usage, 
	perhaps cache lines will like this!"

	| globalNames |
	globalNames := Bag new: globalVariableUsage size.
	globalVariableUsage keysAndValuesDo:
		[:k :v | | count |
		count := 0.
		v do:
			[:methodName| | method |
			method := methods at: methodName.
			method parseTree nodesDo:
				[:n|
				(n isVariable
				 and: [n name hasEqualElements: k]) ifTrue:
					[count := count + 1]]].
		globalNames
			add: k		"move arrays (e.g. methodCache) to end of struct"
			withOccurrences: (((variableDeclarations at: k ifAbsent: ['']) includes: $[)
								ifTrue: [count]
								ifFalse: [count + 1000])].
	variableDeclarations keysDo:
		[:e | globalNames add: e withOccurrences: 0].
	variables do:
		[:e | globalNames add: e withOccurrences: 0].
	^(globalNames sortedElements asSortedCollection:
		[:a1 :a2| a1 value > a2 value or: [a1 value = a2 value and: [a1 key <= a2 key]]]) collect:
			[:ea| ea key]
]

{ #category : #utilities }
CCodeGeneratorGlobalStructure >> checkForGlobalUsage: vars in: aTMethod [ 
	"override to handle global struct needs"
	super checkForGlobalUsage: vars in: aTMethod.
	"if localStructDef is false, we  don't ever need to include a reference to it in a function"
	localStructDef ifFalse:[^self].
	vars asSet do:
		[:var |
		"if any var is global and in the global var struct 
		tell the TMethod it will be refering to the  struct"
		 ((variables includes: var)
		  and: [self placeInStructure: var]) ifTrue:
			[aTMethod referencesGlobalStructIncrementBy: (vars occurrencesOf: var)]]
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
	| structure nonstruct |

	structure := WriteStream on: (String new: 32768).
	nonstruct := WriteStream on: (String new: 32768).
	aStream nextPutAll: '/*** Variables ***/'; cr.
	structure
		nextPutAll: '#if SQ_USE_GLOBAL_STRUCT'; cr;
		nextPutAll: '# define _iss /* define in-struct static as void */'; cr;
		nextPutAll: 'static struct foo {'; cr;
		nextPutAll: '#else'; cr;
		nextPutAll: '# define _iss static'; cr;
		nextPutAll: '#endif'; cr.
	self buildSortedVariablesCollection do:
		[ :var | | varString inStruct target |
		target := (inStruct := self placeInStructure: (varString := var asString)) 
					ifTrue: [structure]
					ifFalse: [nonstruct].
		self isGeneratingPluginCode
			ifTrue:
				[varString = 'interpreterProxy'
					ifTrue: ["quite special..."
						target cr; nextPutAll: '#ifdef SQUEAK_BUILTIN_PLUGIN'.
						target cr; nextPutAll: 'extern'.
						target cr; nextPutAll: '#endif'; cr]
					ifFalse: [target nextPutAll: 'static ']]
			ifFalse:
				[(vmClass mustBeGlobal: varString) ifFalse:
					[target nextPutAll: (inStruct ifTrue: ['_iss '] ifFalse: ['static '])]].
		target
			nextPutAll: (variableDeclarations at: varString ifAbsent: ['sqInt ' , varString]);
			nextPut: $;;
			cr].
	structure
		nextPutAll: '#undef _iss'; cr;
		nextPutAll: '#if SQ_USE_GLOBAL_STRUCT'; cr;
		nextPutAll: ' } fum;'; cr;
		nextPutAll: '# define DECL_MAYBE_SQ_GLOBAL_STRUCT register struct foo * foo = &fum;'; cr;
		nextPutAll: '# define DECL_MAYBE_VOLATILE_SQ_GLOBAL_STRUCT volatile register struct foo * foo = &fum;'; cr;
		nextPutAll: '# define GIV(interpreterInstVar) (foo->interpreterInstVar)'; cr;
		nextPutAll: '#else'; cr;
		nextPutAll: '# define DECL_MAYBE_SQ_GLOBAL_STRUCT /* oh, no mr bill! */'; cr;
		nextPutAll: '# define DECL_MAYBE_VOLATILE_SQ_GLOBAL_STRUCT /* oh no, mr bill! */'; cr;
		nextPutAll: '# define GIV(interpreterInstVar) interpreterInstVar'; cr;
		nextPutAll: '#endif'; cr.

	"if the machine needs the fum structure defining locally, do it now"
	localStructDef ifTrue:
		[structure
			nextPutAll: '#if SQ_USE_GLOBAL_STRUCT'; cr;
			nextPutAll: 'static struct foo * foo = &fum;'; cr;
			nextPutAll: '#endif'; cr].

	aStream
		nextPutAll: structure contents;
		nextPutAll: nonstruct contents;
		cr
]

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> emitGlobalStructFlagOn: aStream [
	"Define SQ_USE_GLOBAL_STRUCT before including the header."

	aStream
		nextPutAll: '#if ';
		nextPutAll: structDefDefine; cr;
		nextPutAll: '# define SQ_USE_GLOBAL_STRUCT 1'; cr;
		nextPutAll: '#else'; cr;
		nextPutAll: '# define SQ_USE_GLOBAL_STRUCT 0'; cr;
		nextPutAll: '#endif'; cr;
		cr
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
	localStructDef := false.
	structDefDefine := '1'
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
	"See if we should put this array into a structure.
	The variables listed are hardcoded as C in the interpreter thus they don't get resolved via TVariableNode logic.
	Also let's ignore variables that have special definitions that require initialization, and the function def which has problems."

	| check |
	check := variableDeclarations at: var ifAbsent: [''].
	(check includes: $=) ifTrue: [^false].
	(check includes: $() ifTrue: [^false].
	(check includesSubString: 'static') ifTrue: [^false].
	(check includesSubString: 'volatile') ifTrue: [^false].

	^(vmClass mustBeGlobal: var) not
]

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> returnPrefixFromVariable: aName [
	^((variables includes: aName)
	   and: [self placeInStructure: aName])
		ifTrue: ['GIV(',aName,')']
		ifFalse: [aName]
]

{ #category : #'initialize-release' }
CCodeGeneratorGlobalStructure >> structDefDefine: aString [
	structDefDefine := aString
]
