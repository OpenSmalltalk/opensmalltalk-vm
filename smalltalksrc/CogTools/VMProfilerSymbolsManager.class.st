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

{ #category : #'Cog compiled code' }
VMProfilerSymbolsManager >> addCogModuleSymbols: symbols [
	[self initialized] whileFalse:
		[(Delay forMilliseconds: 100) wait].
	modules
		removeAllSuchThat: [:existingModule| cogModule name = existingModule name];
		add: cogModule.
	modulesByName at: cogModule name put: cogModule.
	symbolsByModule at: cogModule put: symbols
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
							name: (thing isCompiledMethod
										ifTrue: [thing methodClass name, '>>', thing selector]
										ifFalse: [thing class == cogCodeConstituents first class
													ifTrue: [thing]
													ifFalse: ['PIC ', (thing isString
																	ifTrue: [thing]
																	ifFalse: [thing printString])]]);
							address: (cogCodeConstituents at: i + 1);
							limit: (cogCodeConstituents at: i + 3 ifAbsent: [cogCodeConstituents last])].
	self addCogModuleSymbols: symbols
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
		(symbolsByModule at: module) do:
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
		(symbolsByModule at: module) do:
			[:sym|
			(aSet includes: sym type) ifTrue:
				[stream nextPut: sym]]].
	^stream contents
]

{ #category : #accessing }
VMProfilerSymbolsManager >> vmModule [
	^vmModule
]
