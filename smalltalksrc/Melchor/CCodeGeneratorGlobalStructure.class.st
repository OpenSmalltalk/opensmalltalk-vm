"
This subclass of CCodeGenerator adds support for sticking most global variables into a large global array. This in turn means that suitably minded C compilers can do a better job of accessing those variables; in particular the Mac OS use of PPC and Acorn use of ARM benfits by a substantial margin. 

Only simple globals are currently put in the array. Someday we might try adding pointers to the various arrays etc.
"
Class {
	#name : #CCodeGeneratorGlobalStructure,
	#superclass : #MLVMCCodeGenerator,
	#instVars : [
		'localStructDef',
		'structDefDefine'
	],
	#category : #Melchor
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
			[:methodName|
			(methods at: methodName ifAbsent: []) ifNotNil:
				[:method|
				 method parseTree nodesDo:
					[:n|
					(n isVariable
					 and: [n name hasEqualElements: k]) ifTrue:
						[count := count + 1]]]].
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

	vars asSet do:
		[:var |
		"if any var is global and in the global var struct 
		tell the TMethod it may be refering to the  struct, depending upon the #defines"
		 ((variables includes: var)
		  and: [self placeInStructure: var]) ifTrue:
			[aTMethod referencesGlobalStruct]]
]

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag [
	super emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag.

	"we add an initialiser for the pointer to the global struct; "
	aStream 
		cr;
		nextPutAll: 'void initGlobalStructure(void) {';cr;
		nextPutAll: '#if SQ_USE_GLOBAL_STRUCT_REG';cr;
		nextPutAll: 'foo = &fum;' ; cr;
		nextPutAll: '#endif';  cr;
		nextPutAll:'}';
		cr
]

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> emitCVariablesOn: aStream [
	"Store the global variable declarations on the given stream.
	 Break logic into vars for structure and vars for non-structure."
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
		[ :var | | decl varString inStruct target |
		target := (inStruct := self placeInStructure: (varString := var asString)) 
					ifTrue: [structure]
					ifFalse: [nonstruct].
		decl := variableDeclarations at: varString ifAbsent: ['sqInt ' , varString].
		decl first == $# "support cgen var: #bytecodeSetSelector declareC: '#define bytecodeSetSelector 0' hack"
			ifTrue:
				[target nextPutAll: decl; cr]
			ifFalse:
				[self isGeneratingPluginCode
					ifTrue:
						[varString = 'interpreterProxy'
							ifTrue: "quite special..."
								[self preDeclareInterpreterProxyOn: target]
							ifFalse: [target nextPutAll: 'static ']]
					ifFalse:
						[(self vmClass mustBeGlobal: varString) ifFalse:
							[target nextPutAll: (inStruct ifTrue: ['_iss '] ifFalse: ['static '])]].
				target nextPutAll: decl; nextPut: $;; cr]].
	structure
		nextPutAll: '#undef _iss'; cr;
		nextPutAll: '#if SQ_USE_GLOBAL_STRUCT'; cr;
		nextPutAll: ' } fum;'; cr;
		nextPutAll: ' #if SQ_USE_GLOBAL_STRUCT_REG';cr;
		nextPutAll: '# define DECL_MAYBE_SQ_GLOBAL_STRUCT /* using a global reg pointer */'; cr;
		nextPutAll: '# define DECL_MAYBE_VOLATILE_SQ_GLOBAL_STRUCT /* using a global reg pointer */'; cr;
		nextPutAll:'#else';cr;
		nextPutAll: '# define DECL_MAYBE_SQ_GLOBAL_STRUCT register struct foo * foo = &fum;'; cr;
		nextPutAll: '# define DECL_MAYBE_VOLATILE_SQ_GLOBAL_STRUCT volatile register struct foo * foo = &fum;'; cr;
		nextPutAll: '#endif';cr;
		nextPutAll: '# define GIV(interpreterInstVar) (foo->interpreterInstVar)'; cr;
		nextPutAll: '#else'; cr;
		nextPutAll: '# define DECL_MAYBE_SQ_GLOBAL_STRUCT /* oh, no mr bill! */'; cr;
		nextPutAll: '# define DECL_MAYBE_VOLATILE_SQ_GLOBAL_STRUCT /* oh no, mr bill! */'; cr;
		nextPutAll: '# define GIV(interpreterInstVar) interpreterInstVar'; cr;
		nextPutAll: '#endif'; cr.

	"if the machine needs the fum structure defining locally, do it now; global register users don't need that, but DO need some batshit insane C macro fudging in order to convert the define of USE_GLOBAL_STRUCT_REG into a simple string to use in the asm clause below. Sigh."
	structure
		nextPutAll: '#if SQ_USE_GLOBAL_STRUCT'; cr;
		nextPutAll: '#if SQ_USE_GLOBAL_STRUCT_REG';cr;
		nextPutAll: '#define fooxstr(s) foostr(s)'; cr;
		nextPutAll: '#define foostr(s)  #s'; cr;
		nextPutAll: 'register struct foo * foo asm(fooxstr(USE_GLOBAL_STRUCT_REG));'; cr;
		nextPutAll: '#else'; cr;
		nextPutAll: 'static struct foo * foo = &fum;'; cr;
		nextPutAll: '#endif'; cr;
		nextPutAll: '#endif'; cr.

	aStream
		nextPutAll: structure contents;
		nextPutAll: nonstruct contents;
		cr
]

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> emitGlobalStructFlagOn: aStream [
	"Depending upon the value of structDefDefine (See also #structDefDefine:), define SQ_USE_GLOBAL_STRUCT before including the header. Also derive the flag for using the global register; define USE_GLOBAL_STRUCT_REG to do so"

	aStream
		nextPutAll: '#if ';
		nextPutAll: structDefDefine; cr;
		nextPutAll: '# define SQ_USE_GLOBAL_STRUCT 1'; cr;
		nextPutAll: '#else'; cr;
		nextPutAll: '# define SQ_USE_GLOBAL_STRUCT 0'; cr;
		nextPutAll: '#endif'; cr;
		nextPutAll: '#if USE_GLOBAL_STRUCT_REG '; cr;
		nextPutAll: '# define SQ_USE_GLOBAL_STRUCT_REG 1'; cr;
		nextPutAll: '#else'; cr;
		nextPutAll: '# define SQ_USE_GLOBAL_STRUCT_REG 0'; cr;
		nextPutAll: '#endif'; cr;
		cr
]

{ #category : #'C code generator' }
CCodeGeneratorGlobalStructure >> initialize [
	super initialize.
	localStructDef := nil. "ignored ivar - no longer used"
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
	(check includesSubstring: 'static') ifTrue: [^false].
	(check includesSubstring: 'volatile') ifTrue: [^false].

	^(self vmClass mustBeGlobal: var) not
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
"set the string that will appear in the C file to define whether or not to use the global struct; reasonable values would be:
'USE_GLOBAL_STRUCT' - which would be defined in a header or makefile
'0' - which would mean never do it
'1' - which would mean always do it"
	structDefDefine := aString
]
