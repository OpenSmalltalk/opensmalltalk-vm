"
I generate code that can be loaded dynamically from external libraries (e.g., DSOs on Unix or DLLs on Windows)
"
Class {
	#name : #VMPluginCodeGenerator,
	#superclass : #MLVMCCodeGenerator,
	#instVars : [
		'pluginClass',
		'pluginFunctionsUsed',
		'inProgressSelectors',
		'inliningDone'
	],
	#category : #Melchor
}

{ #category : #'spur primitive compilation' }
VMPluginCodeGenerator >> accessorDepthCalculator [

	^ MLPluginAccessorDepthCalculator forCodeGenerator: self
]

{ #category : #'C translation' }
VMPluginCodeGenerator >> atLeastVMProxyMajor: major minor: minor [ 
	^String streamContents:
		[:s|
		s	nextPutAll: 'VM_PROXY_MAJOR > '; print: major;
			nextPutAll: ' || (VM_PROXY_MAJOR == '; print: major;
			nextPutAll: ' && VM_PROXY_MINOR >= '; print: minor;
			nextPutAll: ')']
]

{ #category : #utilities }
VMPluginCodeGenerator >> collectAndCheckInterpreterProxyInterfaceFor: selectors verbose: beVerbose [
	"self new
		collectAndCheckInterpreterProxyInterfaceFor: (InterpreterProxy selectors reject: [:s| #(initialize private) includes: (InterpreterProxy whichCategoryIncludesSelector: s)])
		verbose: true"
	| interpreterClass objectMemoryClass |
	interpreterClass := self referenceInterpreterClass.
	objectMemoryClass := self referenceObjectMemoryClass.
	^selectors collect:
		[:selector| | reference actual |
		reference := self compileToTMethodSelector: selector
						in: ((interpreterClass whichClassIncludesSelector: selector) ifNil:
							[(objectMemoryClass whichClassIncludesSelector: selector) ifNil:
								[self vmmakerConfiguration interpreterProxyClass]]).
		actual := self compileToTMethodSelector: selector in: self vmmakerConfiguration interpreterProxyClass.
		{ actual. reference } do:
			[:tMethod|
			 tMethod recordDeclarationsIn: self.
			 tMethod returnType ifNil:
				[tMethod inferReturnTypeIn: self.
				 tMethod returnType ifNil:
					[tMethod returnType: #sqInt]]].
		(reference returnType ~= actual returnType
		 or: [(1 to: reference args size) anySatisfy:
				[:i| (reference typeFor: (reference args at: i) in: self)
				  ~= (actual typeFor: (actual args at: i) in: self)]]) ifTrue:
			[self logger
				nextPutAll: 'warning, signature of InterpreterProxy>>';
				nextPutAll: selector;
				nextPutAll: ' does not match reference implementation.';
				cr.
			 beVerbose ifTrue:
				[self logger nextPutAll: 'reference:'; tab.
				 reference emitCFunctionPrototype: self logger generator: self.
				 self logger nextPutAll: 'actual:'; tab; tab.
				 actual emitCFunctionPrototype: self logger generator: self].
			 self logger flush"; halt: selector"].
		actual]
]

{ #category : #inlining }
VMPluginCodeGenerator >> doInlining: inlineFlag [
	"do inlining for a plugin; avoid doing it twice and make sure that
	 primitive prolog preparation is done immediately after inlining.
	 Also, since sharing between plugins means that normal pruning
	 can't be done, allow plugins that want to prune specific methods."
	inliningDone ifFalse:
		[self doBasicInlining: inlineFlag.
		 self prepareTranslatedPrimitives.
		 pluginClass methodsToBePruned do:
			[:sel|
			methods removeKey: sel].
		 inliningDone := true]
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> emitAccessorDepthsOn: aStream [ 
	"Output accessor depth bytes for all primitives in the plugin.
	 This is for external primitives in Spur."
	self sortedExportMethods do:
		[:method| | primName |
		 primName := self cFunctionNameFor: method selector.
		 (self accessorDepthCalculator accessorDepthForSelector: primName asSymbol) ifNotNil:
			[:depth|
			 "store the accessor depth in a byte variable; save a little space
			  by omitting depths < 0; support code supplies the default."
			 self assert: depth < 128.
			 depth >= 0 ifTrue:
				[self withOptionalConditionalDefineFor: method
					on: aStream
					do: [aStream
							nextPutAll: 'EXPORT(signed char) ';
							nextPutAll: primName;
							nextPutAll: 'AccessorDepth = ';
							nextPutAll: (self cLiteralFor: depth);
							nextPut: $;;
							cr]]]]
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag [
	"Generate twice; the first time to collect the used functions, the second to output the used functions."
	| savedHeaders |
	savedHeaders := headerFiles copy.
	[super emitCCodeOn: NullStream new doInlining: inlineFlag doAssertions: assertionFlag]
		on: MessageNotUnderstood
		do: [:ex|
				(#(cr crtab: ensureCr peekLast space tab tab:) includes: ex message selector) ifTrue:
					[ex resume: nil].
				ex pass].
	headerFiles := savedHeaders.
	super emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> emitCHeaderOn: aStream [
	"Write a C file header onto the given stream, adding include files and some basic definitions."
	| standardHeaders |
	aStream nextPutAll: (self fileHeaderVersionStampForSourceClass: pluginClass); cr; cr.

	"config.h should always go first because config.h properly defines flags.
	 One of those is _GNU_SOURCE, as explained in https://www.gnu.org/software/autoconf/manual/autoconf.html#Posix-Variants,
	 where the Autoconf macro AC_USE_SYSTEM_EXTENSIONS makes sure this is defined."
	standardHeaders := #('"config.h"' '<math.h>' '<stdio.h>' '<stdlib.h>' '<string.h>' '<time.h>').
	self emitHeaderFiles: standardHeaders on: aStream.

	headerFiles := headerFiles copyWithoutAll: standardHeaders.
	"Additional header files; include C library ones first."
	self emitHeaderFiles: (headerFiles select: [:hdr| hdr includes: $<]) on: aStream.

	aStream cr; nextPutAll: '/* Default EXPORT macro that does nothing (see comment in sq.h): */
#define EXPORT(returnType) returnType

/* Do not include the entire sq.h file but just those parts needed. */
#include "sqConfig.h"			/* Configuration options */
#include "sqVirtualMachine.h"	/*  The virtual machine proxy definition */
#include "sqPlatformSpecific.h"	/* Platform specific definitions */

#define true 1
#define false 0
#define null 0  /* using ''null'' because nil is predefined in Think C */
#ifdef SQUEAK_BUILTIN_PLUGIN
# undef EXPORT
# define EXPORT(returnType) static returnType
#endif'; cr; cr.
	self addHeaderFile: '"sqMemoryAccess.h"'.
	"Additional header files; include squeak VM ones last"
	self emitHeaderFiles: (headerFiles reject: [:hdr| hdr includes: $<]) on: aStream.
	self maybePutPreambleFor: pluginClass on: aStream.
	aStream cr
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> emitExportsOn: aStream [
	"Store all the exported primitives in the form used by the internal named prim system."
	| nilVMClass |
	(nilVMClass := self vmClass isNil) ifTrue: "We need a vmClass temporarily to compute accessor depths."
		[self vmClass: self vmmakerConfiguration defaultInterpreterClass ].
	aStream cr; cr; nextPutAll:'#ifdef SQUEAK_BUILTIN_PLUGIN'.
	self emitExportsNamed: pluginClass moduleName
		pluginName: pluginClass moduleExportsName
		on: aStream.
	aStream cr; nextPutAll: '#else /* ifdef SQ_BUILTIN_PLUGIN */'; cr; cr.
	self emitAccessorDepthsOn: aStream.
	aStream cr; nextPutAll: '#endif /* ifdef SQ_BUILTIN_PLUGIN */'; cr.
	nilVMClass ifTrue:
		[self vmClass: nil]
]

{ #category : #'C translation' }
VMPluginCodeGenerator >> emitIfdefForPluginFunctionOption: anArrayOrSymbol on: aStream [
	"See e.g. senders of atLeastVMProxyMajor:minor: or <option: #IMMUTABLITY>
	 in InterpreterProxy"
	aStream nextPutAll: '#if '; nextPutAll: (anArrayOrSymbol isSymbol
											ifTrue: [anArrayOrSymbol]
											ifFalse: [self perform: anArrayOrSymbol first
														withArguments: anArrayOrSymbol allButFirst])
]

{ #category : #'C translation' }
VMPluginCodeGenerator >> generateIntegerObjectOf: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."
	| expr mustCastToUnsigned type typeIsUnsigned |
	expr := msgNode args first.
	aStream nextPutAll: '(('.
	"Note that the default type of an integer constant in C is int.  Hence we /must/
	 cast expression to long if in the 64-bit world, since e.g. in 64-bits
		(int)(16r1FFFFF << 3) = (int)16rFFFFFFF8 = -8
	 whereas
		(long)(16r1FFFFF << 3) = (long) 16rFFFFFFF8 = 4294967288."
	type := self typeFor: expr in: currentMethod.
	typeIsUnsigned := type first = $u.
	mustCastToUnsigned := typeIsUnsigned not
		or: [(self sizeOfIntegralCType: type) < (self sizeOfIntegralCType: #usqInt)].
	mustCastToUnsigned ifTrue:
		[aStream nextPutAll: '(usqInt)'].
	self emitCExpression: expr on: aStream.
	aStream nextPutAll: ' << NumSmallIntegerTagBits) | 1)'
]

{ #category : #'C translation' }
VMPluginCodeGenerator >> generateIntegerValueOf: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPut: $(.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPutAll: ' >> NumSmallIntegerTagBits)'
]

{ #category : #'C translation' }
VMPluginCodeGenerator >> generateInterpreterProxyFunctionDereference: aNode on: aStream indent: anInteger [
	| pluginsToClone |
	pluginsToClone := self pluginFunctionsToClone copyWithoutAll: self selectorsThatAreGeneratedAsMacros.
	pluginsToClone isEmpty ifTrue:
		[^self].
	aStream cr.
	self withConditionalDefineOf: 'SQUEAK_BUILTIN_PLUGIN'
		comment: nil
		on: aStream
		do: [pluginsToClone do:
				[:s| | cs |
				cs := self cFunctionNameFor: s.
				self withOptionalVerbiageFor: s
					on: aStream
					do: [aStream tab: anInteger; nextPutAll: cs; nextPutAll: ' = interpreterProxy->'; nextPutAll: cs; nextPut: $;; cr]
					ifOptionalDo:
						[self
							withConditionalDefineOf: cs
							comment: nil
							on: aStream
							do: [aStream tab: anInteger; nextPutAll: cs; nextPutAll: ' = 0;'; cr]]]]
]

{ #category : #'C translation' }
VMPluginCodeGenerator >> generateRemapOopIn: aNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."
	| arm |
	"Avoid nesting #if SPURVM...#else...#endif within arms of an outer #if SPURVM...#else...#endif."
	(Notification new tag: #inRemapOopInArm; signal) ifNotNil:
		[:inRemapOopInArm|
		 ^inRemapOopInArm
			ifTrue: [self generateSpurRemapOopIn: aNode on: aStream indent: level]
			ifFalse: [self generateV3RemapOopIn: aNode on: aStream indent: level]].
	[aStream cr; nextPutAll: '#if SPURVM'; cr.
	 arm := true.
	 self generateSpurRemapOopIn: aNode on: aStream indent: level.
	 aStream cr; nextPutAll: '#else /* SPURVM */'; cr.
	 arm := false.
	 self generateV3RemapOopIn: aNode on: aStream indent: level.
	 aStream cr; nextPutAll: '#endif /* SPURVM */'; cr]
		on: Notification
		do: [:ex|
			ex tag == #inRemapOopInArm
				ifTrue: [ex resume: arm]
				ifFalse: [ex pass]]
]

{ #category : #'C translation' }
VMPluginCodeGenerator >> generateSpurRemapOopIn: aNode on: aStream indent: level [
	"Generate just the block argument for this message as Spur does not GC on allocation."

	aNode args second emitCCodeOn: aStream level: level generator: self
]

{ #category : #'C translation' }
VMPluginCodeGenerator >> generateV3RemapOopIn: aNode on: aStream indent: level [
	"Generate call on remapOop: for the variable oopOrList (or all of the
	 variables in oopOrList) before evaluating aBlock, and restore them after.
	 This keeps the oops valid if, as V3 will, there is a GC on allocation."

	| idList |
	pluginFunctionsUsed add: #pushRemappableOop:; add: #popRemappableOop.
	idList := aNode args first nameOrValue.
	idList class == Array ifFalse: [idList := Array with: idList].
	idList do:
		[:each | 
		 aStream
			tab: level;
			nextPutAll: 'pushRemappableOop(';
			nextPutAll: each asString;
			nextPutAll: ');']
		separatedBy: [aStream cr].
	aStream cr.
	aNode args second emitCCodeOn: aStream level: level generator: self.
	level timesRepeat: [aStream tab].
	idList reversed do:
		[:each |
		 aStream 
			nextPutAll: each asString;
			nextPutAll: ' = popRemappableOop()']
		separatedBy: [aStream nextPut: $;; crtab: level]
]

{ #category : #'type inference' }
VMPluginCodeGenerator >> harmonizeReturnTypesIn: aSetOfTypes [
	"Eliminate signed/unsigned conflicts in aSetOfTypes.  Override to
	 default to void if any one return type is void."
	^(aSetOfTypes includes: #void)
		ifTrue: [Set with: #void]
		ifFalse: [super harmonizeReturnTypesIn: aSetOfTypes]
]

{ #category : #public }
VMPluginCodeGenerator >> initialize [
	super initialize.
	pluginFunctionsUsed := Set new.
	inliningDone := false
]

{ #category : #public }
VMPluginCodeGenerator >> initializeCTranslationDictionary [ 
	"Initialize the dictionary mapping message names to actions for C code generation."

	super initializeCTranslationDictionary.
	translationDict
		at: #expandDereferenceInterpreterProxyFunctionTable
			put: #generateInterpreterProxyFunctionDereference:on:indent:;
		at: #remapOop:in:
			put: #generateRemapOopIn:on:indent:
]

{ #category : #testing }
VMPluginCodeGenerator >> isGeneratingPluginCode [
	^true
]

{ #category : #utilities }
VMPluginCodeGenerator >> isStructSend: aTSendNode [
	"Answer if the argument aTSendNode is a send of a structure accessor.
	 This is tricky.  We want
		foo bar => foo->bar
		foo bar => foo.bar
		foo bar: expr => foo->bar = expr
		foo bar: expr => foo.bar = expr
	 depending on whether foo is a struct or a pointer to a struct,
	 but only if both foo is a struct type and bar is a field accessor.
	 The tricky cases are self-sends within struct class methods.  Here we need to
	 distinguish between self-sends of ordinary methods from self sends of accessors.

	Override to avoid requiring that there be a struct accessor method for the selector."
	^aTSendNode numArgs <= 1
	   and: [(aTSendNode receiver structTargetKindIn: self) notNil]
]

{ #category : #public }
VMPluginCodeGenerator >> localizeGlobalVariables [
"TPR - we don't do this for plugins"
]

{ #category : #public }
VMPluginCodeGenerator >> notePluginFunctionsUsedByMacros [
	"Declare the plugin functions that are used by macros."
	#(
		isKindOfInteger: #(classLargeNegativeInteger classLargePositiveInteger fetchClassOf: isIntegerObject: )
		isIntegerObject:  #()
		isLargeIntegerObject: #(classLargeNegativeInteger classLargePositiveInteger fetchClassOf: )
		isLargeNegativeIntegerObject: 	#(classLargeNegativeInteger fetchClassOf: )
		isLargePositiveIntegerObject: 	#(classLargePositiveInteger fetchClassOf: ))
			pairsDo: [:macro :funcs |
				(pluginFunctionsUsed includes: macro) ifTrue: [pluginFunctionsUsed addAll: funcs]].
]

{ #category : #public }
VMPluginCodeGenerator >> noteUsedPluginFunction: aSelector [
	"Remember aSelector and answer whether the call should be made through
	 interpreterProxy. If not, it will be made either directly (in an internal plugin)
	 or through a local copy of the function pointer (in an external plugin)."
	pluginFunctionsUsed add: aSelector.
	"These two are static to sqVirtualMachine.c and so
	 they must be called through the interpreterProxy."
	^#(majorVersion minorVersion) includes: aSelector
]

{ #category : #public }
VMPluginCodeGenerator >> pluginClass: aPluginClass [
	"Set the plugin class and name when generating plugins.
	 And for run-time use, answer the name string."
	| packageId |
	pluginClass := aPluginClass.
	packageId := self shortMonticelloDescriptionForClass: pluginClass.
	(packageId beginsWith: pluginClass name) ifTrue:
		[packageId := packageId allButFirst: pluginClass name size].
	(packageId beginsWith: pluginClass moduleName) ifTrue:
		[packageId := packageId allButFirst: pluginClass moduleName size].
	^self declareModuleName: pluginClass moduleNameAndVersion, packageId
]

{ #category : #public }
VMPluginCodeGenerator >> pluginFunctionsToClone [
	"Answer those of the used plugin functions to clone as a sorted collection.
	 Exclude those that are static to sqVirtualMachine.c and hence always need
	 to be called through interpreterProxy."

	^((pluginFunctionsUsed
		reject: [:selector| self noteUsedPluginFunction: selector])
			select: [:selector| self vmmakerConfiguration interpreterProxyClass includesSelector: selector])
				asSortedCollection
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> preDeclareInterpreterProxyOn: aStream [
	"Put the necessary #defines needed before interpreterProxy.  Basically
	 internal plugins use the VM's interpreterProxy variable and external plugins
	 use their own.  Override to keep local copies of all functions in external
	 prims, and link directly in internal plugins."
	"| pcc |
	pcc := self new.
	(InterpreterProxy selectors reject: [:s| #(initialize private) includes: (InterpreterProxy whichCategoryIncludesSelector: s)]) do:
		[:s| pcc noteUsedPluginFunction: s].
	pcc preDeclareInterpreterProxyOn: Transcript.
	Transcript flush"
	| pluginFuncs |
	self notePluginFunctionsUsedByMacros.
	(pluginFuncs := self pluginFunctionsToClone) isEmpty ifTrue:
		[^super preDeclareInterpreterProxyOn: aStream].
	(pluginFuncs includesAnyOf: self selectorsThatAreGeneratedAsMacros) ifTrue:
		[self preDeclareMacrosForFastClassCheckingOn: aStream].
	pluginFuncs := pluginFuncs copyWithoutAll: self selectorsThatAreGeneratedAsMacros.
	pluginFuncs isEmpty ifTrue:
		[^self].
	pluginFuncs := self collectAndCheckInterpreterProxyInterfaceFor: pluginFuncs verbose: false.
	aStream cr; nextPutAll: '#if !defined(SQUEAK_BUILTIN_PLUGIN)'; cr.
	pluginFuncs do:
		[:tMethod| | functionName |
		functionName := self cFunctionNameFor: tMethod selector.
		aStream nextPutAll:
			((String streamContents:
					[:s|
					tMethod
						static: true;
						emitCFunctionPrototype: s generator: self])
				copyReplaceAll: functionName
				with: '(*', functionName, ')'
				tokenish: [:ch| ch = $_ or: [ch isAlphaNumeric]])].
	aStream nextPutAll: '#else /* !defined(SQUEAK_BUILTIN_PLUGIN) */'; cr.
	pluginFuncs do:
		[:tMethod|
		self withGuardAgainstDefinitionOf: tMethod selector on: aStream do:
			[self withOptionalVerbiageFor: tMethod selector
				on: aStream
				do: [tMethod static: false; export: false; emitCFunctionPrototype: aStream generator: self]
				ifOptionalDo:
					[aStream nextPutAll: '# define '.
					 (TSendNode new
						setSelector: tMethod selector
							receiver: (TVariableNode new setName: 'interpreterProxy')
								arguments: (tMethod args collect: [:a| TVariableNode new setName: a]))
						emitCCodeAsArgumentOn: aStream
							level: 0
								generator: self.
					 aStream nextPutAll: ' 0'; cr]]].
	aStream nextPutAll: 'extern'; cr; nextPutAll: '#endif'; cr
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> preDeclareMacrosForFastClassCheckingOn: aStream [
	"These macros can be used to check for various cases of Integer types.
	 Since they can be defined based on existing API, this is a good trade off:
	 - avoid extending the interpreterProxy API unnecessarily
	 - provide fast type checking"
	
	"Speed-up generated code for internal plugins by using macros and fixed class indices to define this well known functionality."
	#(	'#if defined(SQUEAK_BUILTIN_PLUGIN)' cr

		'# define isIntegerObject(oop) ((oop) & 1)' cr

		'# if SPURVM'
		'extern sqInt classIndexOf(sqInt);'
	"Compact class indices are hardcoded here because there is no guarantee that the pool values at generation time
	 are that of SPUR.. Make sure they are in sync with SpurMemoryManager class>>initializeCompactClassIndices"
		'#	define LargeNegativeIntegerClassIndex 32'
		'#	define LargePositiveIntegerClassIndex 33'
		'#	if BytesPerOop == 4'
		'#	  define isImmediate(oop) ((oop) & 3)'
		'#	else'
		'#	  define isImmediate(oop) ((oop) & 7)'
		'#	endif'
		'#	define isKindOfInteger(oop) (isImmediate(oop) ? isIntegerObject(oop) : (unsigned)(classIndexOf(oop) - LargeNegativeIntegerClassIndex) <= 1)'
		'#	define isLargeIntegerObject(oop) (!isImmediate(oop) && (unsigned)(classIndexOf(oop) - LargeNegativeIntegerClassIndex) <= 1)'
		'#	define isLargeNegativeIntegerObject(oop) (!isImmediate(oop) && classIndexOf(oop) == LargeNegativeIntegerClassIndex)'
		'#	define isLargePositiveIntegerObject(oop) (!isImmediate(oop) && classIndexOf(oop) == LargePositiveIntegerClassIndex)'
		'# endif /* SPURVM */'
		'#endif /* defined(SQUEAK_BUILTIN_PLUGIN) */' cr

	"If the functionality has not been defined via macros, define default versions using existing plugin API"
		'#if !defined(isKindOfInteger)'
		'# define isLargeNegativeIntegerObject(oop) (fetchClassOf(oop) == classLargeNegativeInteger())'
		'# define isLargePositiveIntegerObject(oop) (fetchClassOf(oop) == classLargePositiveInteger())'
		'# define isLargeIntegerObject(oop) (isLargeNegativeIntegerObject(oop) || isLargePositiveIntegerObject(oop))'
		'# define isKindOfInteger(oop) (isIntegerObject(oop) || isLargeNegativeIntegerObject(oop) || isLargePositiveIntegerObject(oop))'
		'#endif' cr) do:
		[:element|
		aStream cr.
		element ~~ #cr ifTrue: [aStream nextPutAll: element]]
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> prepareTranslatedPrimitives [
	"Translated primitives need their prolog and epilog adding and all
	 sends to self that should be sends to interpreterproxy changing."
	methods do:
		[:meth|
		 meth primitive > 0 ifTrue:
			[meth
				preparePrimitivePrologue;
				mapSendsFromSelfToInterpreterProxy: self vmmakerConfiguration interpreterProxyClass selectors]]
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> referenceInterpreterClass [
	"Define the class from which to take methods to define the interpreter proxy imports."
	^(Smalltalk classNamed: #StackInterpreter) 
		ifNil: [self vmmakerConfiguration interpreterProxyClass]
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> referenceObjectMemoryClass [
	"Define the class from which to take methods to define the interpreter proxy imports."
	^ self vmmakerConfiguration referenceObjectMemoryClass
]

{ #category : #public }
VMPluginCodeGenerator >> selectorsThatAreGeneratedAsMacros [
	"Answer a list of selectors that are generated as a C macro rather than as an interpreterProxy function call."
	
	^#(isKindOfInteger: isLargeIntegerObject: isLargeNegativeIntegerObject: isLargePositiveIntegerObject:)
]

{ #category : #public }
VMPluginCodeGenerator >> selectorsThatMayBeGeneratedAsMacros [
	"Answer a list of selectors that maybe generated as a C macro rather than as an interpreterProxy function call."
	
	^self selectorsThatAreGeneratedAsMacros, #(isIntegerObject: isImmediate:)
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> shouldGenerateStruct: structClass [

	^ structClass isAbstract not
		 and: [pluginClass shouldGenerateTypedefFor: structClass]
]

{ #category : #inlining }
VMPluginCodeGenerator >> sizeOfIntegralCType: anIntegralCType [ "<String>"
	"Hack; because the plugin sources are compiled either as 32 or 64 bit
	 size those types which are either 32 or 64 bits in size as 48 bits.
	 This happens to produce sane results for integer promotion."
	"N.B. Only works for values for which isIntegralCType: answers true."
	| prunedCType index |
	(anIntegralCType beginsWith: 'register ') ifTrue:
		[^self sizeOfIntegralCType: (anIntegralCType allButFirst: 9)].
	prunedCType := (anIntegralCType beginsWith: 'unsigned ')
						ifTrue: [(anIntegralCType allButFirst: 9) withBlanksTrimmed]
						ifFalse: [(anIntegralCType beginsWith: 'signed ')
									ifTrue: [(anIntegralCType allButFirst: 7) withBlanksTrimmed]
									ifFalse: [anIntegralCType]].
	
	^prunedCType asString caseOf: {
		['sqLong']		->	[8].
		['usqLong']		->	[8].
		['long long']	->	[8].
		['sqInt']			->	[6].
		['usqInt']		->	[6].
		['sqIntptr_t']	->	[6].
		['usqIntptr_t']	->	[6].
		['int']			->	[4].
		['short']			->	[2].
		['short int']		->	[2].
		['char']			->	[1].
		['long']			->	[BytesPerWord]. "It's ambiguous on LLP64 and we'll later remove it"
		['size_t']		->	[6].
		['pid_t']			->	[6].
	}
	otherwise:
		[((anIntegralCType beginsWith: 'unsigned') "e.g. 'unsigned  : 8'"
		  and: [(anIntegralCType includesAnyOf: '[*]') not
		  and: [(index := anIntegralCType indexOf: $:) > 0]])
			ifTrue: [(Integer readFrom: (anIntegralCType copyFrom: index + 1 to: anIntegralCType size) withBlanksTrimmed readStream) + 7 // 8]
			ifFalse: [self error: 'unrecognized integral type']]
]

{ #category : #private }
VMPluginCodeGenerator >> storeVirtualMachineProxyHeader: categoryList on: fileName [
	"Store the interpreter definitions on the given file"
	| stream |
	stream := FileStream newFileNamed: fileName.
	stream nextPutAll:
'#ifndef _SqueakVM_H
#define _SqueakVM_H

/* Increment the following number if you change the order of
   functions listed or if you remove functions */
#define VM_PROXY_MAJOR 1

/* Increment the following number if you add functions at the end */
#define VM_PROXY_MINOR 0

typedef struct VirtualMachine {
	int (*minorVersion) (void);
	int (*majorVersion) (void);
'.

	categoryList do:[:assoc|
		stream cr; crtab; nextPutAll:'/* InterpreterProxy methodsFor: ''',assoc key, ''' */'; cr; crtab.
		(self sortStrings: assoc value) do:[:sel|
			(methods at: sel) emitProxyFunctionPrototype: stream generator: self.
			stream nextPutAll: ';'; crtab]].

	stream nextPutAll:'
} VirtualMachine;

#endif /* _SqueakVM_H */
'.
	stream close.
]

{ #category : #private }
VMPluginCodeGenerator >> storeVirtualMachineProxyImplementation: categoryList on: fileName [
	"Store the interpreter definitions on the given file"
	| stream |
	stream := FileStream newFileNamed: fileName.
	stream nextPutAll:'
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "sqVirtualMachine.h"'; cr;cr.
	stream nextPutAll:'/*** Function prototypes ***/'.

	categoryList do:[:assoc|
		stream cr; cr; nextPutAll:'/* InterpreterProxy methodsFor: ''',assoc key, ''' */'; cr.
		(self sortStrings: assoc value) do:[:sel|
			(methods at: sel) emitCFunctionPrototype: stream generator: self]].

	stream cr; nextPutAll:'struct VirtualMachine *VM = NULL;'; cr.
	stream cr; nextPutAll:
'static int majorVersion(void) {
	return VM_PROXY_MAJOR;
}

static int minorVersion(void) {
	return VM_PROXY_MINOR;
}

struct VirtualMachine* sqGetInterpreterProxy(void)
{
	if(VM) return VM;
	VM = (struct VirtualMachine *) calloc(1, sizeof(VirtualMachine));
	/* Initialize Function pointers */
	VM->majorVersion = majorVersion;
	VM->minorVersion = minorVersion;
'.
	categoryList do:[:assoc|
		stream cr; crtab; nextPutAll:'/* InterpreterProxy methodsFor: ''',assoc key, ''' */'; crtab.
		assoc value asSortedCollection do:[:sel|
		stream nextPutAll:'VM->';
			nextPutAll: (self cFunctionNameFor: sel);
			nextPutAll:' = ';
			nextPutAll: (self cFunctionNameFor: sel);
			nextPutAll:';';
			crtab]].

	stream cr; crtab; nextPutAll:'return VM;'; cr; nextPutAll:'}'; cr.
	stream close.
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> structClasses [
	
	^ self structClassesForTranslationClasses: { pluginClass }
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> structTargetKindForDeclaration: decl [ "<String>"
	^(super structTargetKindForDeclaration: decl) ifNil:
		[pluginClass ifNotNil:
			[(pluginClass isStructType: (decl last = $*
											ifTrue: [decl allButLast]
											ifFalse: [decl]) withBlanksTrimmed) ifTrue:
				[(decl indexOf: $*) > 0
					ifTrue: [#pointer]
					ifFalse: [#struct]]]]
]

{ #category : #'type inference' }
VMPluginCodeGenerator >> typeFor: aNode in: aTMethod [
	"Override to provide the type for InterpreterProxy's implicit stack variable."
	aNode isVariable ifTrue:
		[^(aTMethod typeFor: aNode in: self) ifNil:
			[aNode name = 'stack'
				ifTrue: [#'sqInt *']
				ifFalse: [#sqInt]]].
	^super typeFor: aNode in: aTMethod
]

{ #category : #'C translation' }
VMPluginCodeGenerator >> withGuardAgainstDefinitionOf: selector on: aStream do: aBlock [
	"Evaluate aBlock, surrounded by a define if selector is defined as a macro (i.e. by preDeclareInterpreterProxyOn:"
	(self selectorsThatMayBeGeneratedAsMacros includes: selector) ifFalse:
		[^aBlock value].
	self
		withConditionalDefineOf: (self cFunctionNameFor: selector)
		comment: nil
		on: aStream
		do: aBlock
]

{ #category : #'C translation' }
VMPluginCodeGenerator >> withOptionalVerbiageFor: selector on: aStream do: mainBlock ifOptionalDo: optionalBlock [
	(self vmmakerConfiguration interpreterProxyClass >> selector pragmaAt: #option:)
		ifNil:
			[mainBlock value]
		ifNotNil:
			[:pragma|
			 self emitIfdefForPluginFunctionOption: pragma arguments first on: aStream.
			 aStream cr.
			 mainBlock value.
			 aStream nextPutAll: '#else'; cr.
			 optionalBlock value.
			 aStream nextPutAll: '#endif'; cr]
]
