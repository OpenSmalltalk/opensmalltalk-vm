Extension { #name : #VMMaker }

{ #category : #'*SlangBrowser-browser support' }
VMMaker classSide >> buildCodeGenerator: aClass inlined: doInlining [
	"Answer a new C code generator for aClass"

	| cg |
	ObjectMemory initialize; initializeConstants.
	cg := aClass buildCodeGeneratorInlined: doInlining.
	cg prepareMethodsInlined: doInlining doAssertions: true.
	^ cg

]

{ #category : #'*SlangBrowser-browser support' }
VMMaker classSide >> cCodeGenerator: aClass inCache: cache inlined: doInlining [
	"Answer a C code generator, or a string explaining why a code generator is not available"

	| cg |
	cg := cache
		at: aClass name asSymbol
		ifAbsentPut: [self buildCodeGenerator: aClass inlined: doInlining].
	^ cg

]

{ #category : #'*SlangBrowser-browser support' }
VMMaker classSide >> cacheFor: generatorType [

	^ self codeGeneratorCache at: generatorType ifAbsentPut: [Dictionary new]

]

{ #category : #'*SlangBrowser-browser support' }
VMMaker classSide >> clearCache: cache entriesFor: aClass [ 
	"Clear the of code generators for aClass and its dependent subclasses"

	aClass withAllSubclasses
		do: [:cls | cache
				removeKey: cls name asSymbol
				ifAbsent: []]
]

{ #category : #'*SlangBrowser-browser support' }
VMMaker classSide >> clearCacheEntriesFor: aClass [ 
	"Clear all code generator caches for aClass and its dependent subclasses"

	self codeGeneratorCache
		do: [:cache | self clearCache: cache entriesFor: aClass]
]

{ #category : #'*SlangBrowser-browser support' }
VMMaker classSide >> clearCodeGeneratorCache [
	"Code generators used by browsers display translated C code"

	"VMMaker clearCodeGeneratorCache"

	CodeGeneratorCache := nil

]

{ #category : #'*SlangBrowser-browser support' }
VMMaker classSide >> codeGenerator: generatorType forClass: aClass [

	| cache |
	generatorType = #cCode
		ifTrue: [cache := self cacheFor: generatorType.
				^ self cCodeGenerator: aClass inCache: cache inlined: false].
	generatorType = #inlinedCCode
		ifTrue: [cache := self cacheFor: generatorType.
				^ self cCodeGenerator: aClass inCache: cache inlined: true].
	self error: generatorType asString, ' not recognized'.

]

{ #category : #'*SlangBrowser-browser support' }
VMMaker classSide >> codeGeneratorCache [
	"Code generators used by browsers display translated C code"

	^ CodeGeneratorCache ifNil: [CodeGeneratorCache := Dictionary new]
]

{ #category : #'*SlangBrowser-browser support' }
VMMaker classSide >> event: anEvent [
	"Hook for SystemChangeNotifier. If a translatable class changes, clear all
	of its code generators from caches to force retranslation."

	| cls itemClass |
	(itemClass := anEvent itemClass) ifNotNil:
		[cls := itemClass isMeta
			ifTrue: [itemClass soleInstance]
			ifFalse: [itemClass].
		self clearCacheEntriesFor: cls]

]

{ #category : #'*SlangBrowser-initialisation' }
VMMaker classSide >> initializeBrowserSupport [

	self clearCodeGeneratorCache.
	self registerNotification.
	(CodeHolder respondsTo: #addEditContentsOption:)
		ifTrue: [CodeHolder addEditContentsOption: #translateToC -> #selectedTranslateToC.
				CodeHolder addEditContentsOption: #translateInlinedC -> #selectedTranslateInlinedC.
				CodeHolder removeContentsSymbol: #translateToC.
				CodeHolder removeContentsSymbol: #translateInlinedC.
			CodeHolder addContentsSymbolQuint:
							{#translateToC
							. #toggleShowingTranslateToC
							. #showingTranslateToCString
							. 'C code'
							. 'translate to C source code, no method inlining' translated}
						afterEntry: #byteCodes.
			CodeHolder addContentsSymbolQuint:
							{#translateInlinedC
							. #toggleShowingTranslateInlinedC
							. #showingTranslateInlinedCString
							. 'inlined C'
							. 'translate to C source code with method inlining' translated}
						afterEntry: #translateToC]
		ifFalse: [self notify: 'package SlangBrowser requires browser support, not yet loaded']

]

{ #category : #'*SlangBrowser-browser support' }
VMMaker classSide >> registerNotification [

	SystemChangeNotifier uniqueInstance notify: self ofAllSystemChangesUsing: #event:

]

{ #category : #'*SlangBrowser-browser support' }
VMMaker classSide >> unregisterNotification [

	"self unregisterNotification"

	SystemChangeNotifier uniqueInstance noMoreNotificationsFor: self

]
