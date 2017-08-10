Class {
	#name : #VMProfilerSymbolsManager,
	#superclass : #Object,
	#instVars : [
		'modules',
		'symbolsByModule',
		'modulesByName',
		'vmModule',
		'cogModule'
	],
	#classVars : [
		'CompatibilityClass'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #LICENSE }
VMProfilerSymbolsManager class >> LICENSE [
	^'Project Squeak

	Copyright (c) 2005-2013, 3D Immersive Collaboration Consulting, LLC., All Rights Reserved

	Redistributions in source code form must reproduce the above copyright and this condition.

Licensed under MIT License (MIT)
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.'
]

{ #category : #'as yet unclassified' }
VMProfilerSymbolsManager class >> initialize [
	"Add to the shut down list to delete the temp directory and contents."
	Smalltalk addToShutDownList: self
]

{ #category : #'as yet unclassified' }
VMProfilerSymbolsManager class >> tempDirectory [

	^ CompatibilityClass ifNotNil: [CompatibilityClass nameFordirPath:'/tmp/vmsyms'  plus:OSProcess thisOSProcess pid printString] 

]

{ #category : #'as yet unclassified' }
VMProfilerSymbolsManager class >> using: aCompatibilityClass [

	CompatibilityClass := aCompatibilityClass.
	^ self new 
	
]

{ #category : #'Cog compiled code' }
VMProfilerSymbolsManager >> addCogModuleSymbols: symbols [
	self initialized ifFalse:
		[Cursor wait showWhile:
			[[self initialized] whileFalse:
				[(Delay forMilliseconds: 100) wait]]].
	modules
		removeAllSuchThat: [:existingModule| cogModule name = existingModule name];
		add: cogModule.
	modulesByName at: cogModule name put: cogModule.
	symbolsByModule at: cogModule put: symbols
]

{ #category : #'Constituents naming' }
VMProfilerSymbolsManager >> analyzeClosedPIC: aClosedPIC [

	^ Dictionary new
		at: 'selector' put: aClosedPIC first;
		at: 'nbOfCases' put: aClosedPIC size -1;
		at: 'listOfCases' put: ((aClosedPIC allButFirst collect: [ :each | each methodClass name ]) asSet);
		yourself.
]

{ #category : #accessing }
VMProfilerSymbolsManager >> cogModule [
	^cogModule
]

{ #category : #'Cog compiled code' }
VMProfilerSymbolsManager >> computeCogCodeModule: cogCodeConstituents [
	| symbols |
	(cogModule := VMPExecutableModuleSymbol new)
		name: vmModule shortName, '.', cogCodeConstituents first;
		shortName: cogCodeConstituents first;
		vmshift: 0;
		address: cogCodeConstituents second;
		size: cogCodeConstituents last - cogCodeConstituents second.
	symbols := (3 to: cogCodeConstituents size - 2 by: 2) collect:
					[:i| "Declare methods as public; PICs and entries as private"
					| thing |
					((thing := cogCodeConstituents at: i) isCompiledMethod
						ifTrue: [VMPPublicFunctionSymbol]
						ifFalse: [VMPPrivateFunctionSymbol]) new
							name: (self nameOf: thing cogCodeModule: cogCodeConstituents);
							address: (self extractAddress: (cogCodeConstituents at: i + 1));
							mcpcbcpcmap: (cogCodeConstituents at: i + 1);
							limit: (self extractAddress: (cogCodeConstituents at: i + 3 ifAbsent: [cogCodeConstituents last]))].
	self addCogModuleSymbols: symbols
]

{ #category : #'Cog compiled code' }
VMProfilerSymbolsManager >> extractAddress: thing [
	^ thing isArray ifTrue: [ thing first ] ifFalse: [ thing ]
]

{ #category : #'Constituents naming' }
VMProfilerSymbolsManager >> getClosedPICLabel: aThing [
"(= assoc key name )aThing could be either a selector, a trampoline/enilopmart, or a VMPSymbol"

	|list|
	list := String streamContents: [ :s |(aThing at: 'listOfCases') asStringOn: s delimiter: ', '].
	^ String streamContents: [ :s | s nextPutAll: 'cPIC', ' ', (aThing at: 'selector'), ' - ', (aThing at: 'nbOfCases') asString, ' (', list, ')' ]
]

{ #category : #'initialize-release' }
VMProfilerSymbolsManager >> initialize [
	"Initialize the receiver, parsing the symbols in the background for faster startup."
	self initializeMost.
	self parseAsynchronously
]

{ #category : #accessing }
VMProfilerSymbolsManager >> moduleFor: aSymbol [
	^modules
		detect: [:module|
				module address <= aSymbol address
				and: [module limit >= aSymbol limit]]
		ifNone: []
]

{ #category : #accessing }
VMProfilerSymbolsManager >> moduleForAddress: address [
	^modules
		detect: [:module|
				module address <= address
				and: [module limit >= address]]
		ifNone: []
]

{ #category : #accessing }
VMProfilerSymbolsManager >> modules [
	^modules
]

{ #category : #'Constituents naming' }
VMProfilerSymbolsManager >> nameOf: thing cogCodeModule: cogCodeConstituents [

	thing isCompiledMethod ifTrue: [ ^ thing methodClass name , '>>' , thing selector ].
	thing class == cogCodeConstituents first class ifTrue: [ ^thing ].				
 	^ thing isArray  
		ifTrue: [self getClosedPICLabel: (self analyzeClosedPIC: thing)]
		ifFalse: ['OpenPIC ',(thing isString
										ifTrue: [ thing ]
										ifFalse: [ thing printString ])] 
]

{ #category : #accessing }
VMProfilerSymbolsManager >> symbolsInModule: aModule [
	^symbolsByModule at: aModule ifAbsent: [#()]
]

{ #category : #accessing }
VMProfilerSymbolsManager >> symbolsSelect: aBlock [
	| size stream |
	size := symbolsByModule inject: 0 into: [:sum :symbols| sum + symbols size].
	stream := (Array new: size) writeStream.
	modules do:
		[:module|
		(aBlock value: module) ifTrue:
			[stream nextPut: module].
		(symbolsByModule at: module ifAbsent: [#()]) do:
			[:sym|
			(aBlock value: sym) ifTrue:
				[stream nextPut: sym]]].
	^stream contents
]

{ #category : #accessing }
VMProfilerSymbolsManager >> symbolsWithTypes: aSet [
	| size stream |
	(aSet size = 1 and: [aSet anyOne == #module]) ifTrue:
		[^modules].
	size := symbolsByModule inject: 0 into: [:sum :symbols| sum + symbols size].
	stream := (Array new: size) writeStream.
	modules do:
		[:module|
		(symbolsByModule at: module ifAbsent: [#()]) do:
			[:sym|
			(aSet includes: sym type) ifTrue:
				[stream nextPut: sym]]].
	^stream contents
]

{ #category : #accessing }
VMProfilerSymbolsManager >> vmModule [
	^vmModule
]
