Class {
	#name : #VMSimpleStackBasedCogitMegamorphicPICTest,
	#superclass : #VMSimpleStackBasedCogitBytecodeTest,
	#category : #VMMakerTests
}

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitMegamorphicPICTest >> setUp [

	| specialSelectorsArray |
	super setUp.
	self setUpCogMethodEntry.
	1halt.
	memory coInterpreter
		moveMethodCacheToMemoryAt: initialAddress + memory cogCodeBase + self initialCodeSize + stackSpaceSize.
	specialSelectorsArray := self newOldSpaceObjectWithSlots: 2.
	memory coInterpreter
		specialSelectorArray: specialSelectorsArray;
		specialSelector: 0 put: memory falseObject.
	
	cogit generateOpenPICPrototype.
]

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitMegamorphicPICTest >> testLookupExistingMegamorphicPICReturnsPIC [

	| selector createdPic specialObjectsArray |
	selector := memory trueObject.
	
	createdPic := cogit cogOpenPICSelector: selector numArgs: 1.
	
	
	self assert: (cogit methodZone openPICWithSelector: selector) equals: createdPic.
]

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitMegamorphicPICTest >> testLookupNonExistingMegamorphicPICReturnsNil [

	self assert: (cogit methodZone openPICWithSelector: memory trueObject) equals: nil
]

{ #category : #'tests - metadata' }
VMSimpleStackBasedCogitMegamorphicPICTest >> testNewMegamorphicPICCallsPicAbortTrampoline [

	"self assert: pic cmType = CMOpenPIC.
	self assert: pic selector = selector.
	self assert: pic cmNumArgs = numArgs.
	self assert: (backEnd callTargetFromReturnAddress: pic asInteger + missOffset) = (self picAbortTrampolineFor: numArgs).
	self assert: openPICSize = (methodZone roundUpLength: openPICSize)."

	self assert: false
" self patchToOpenPICFor: cPIC selector
					numArgs: cPIC cmNumArgs
					receiver: rec"
]

{ #category : #'tests - metadata' }
VMSimpleStackBasedCogitMegamorphicPICTest >> testNewMegamorphicPICNumArgs [

	"self assert: pic cmType = CMOpenPIC.
	self assert: pic selector = selector.
	self assert: pic cmNumArgs = numArgs.
	self assert: (backEnd callTargetFromReturnAddress: pic asInteger + missOffset) = (self picAbortTrampolineFor: numArgs).
	self assert: openPICSize = (methodZone roundUpLength: openPICSize)."

	self assert: false
" self patchToOpenPICFor: cPIC selector
					numArgs: cPIC cmNumArgs
					receiver: rec"
]

{ #category : #'tests - metadata' }
VMSimpleStackBasedCogitMegamorphicPICTest >> testNewMegamorphicPICSelector [

	"self assert: pic cmType = CMOpenPIC.
	self assert: pic selector = selector.
	self assert: pic cmNumArgs = numArgs.
	self assert: (backEnd callTargetFromReturnAddress: pic asInteger + missOffset) = (self picAbortTrampolineFor: numArgs).
	self assert: openPICSize = (methodZone roundUpLength: openPICSize)."

	self assert: false
" self patchToOpenPICFor: cPIC selector
					numArgs: cPIC cmNumArgs
					receiver: rec"
]

{ #category : #'tests - metadata' }
VMSimpleStackBasedCogitMegamorphicPICTest >> testNewMegamorphicPICSize [

	"self assert: pic cmType = CMOpenPIC.
	self assert: pic selector = selector.
	self assert: pic cmNumArgs = numArgs.
	self assert: (backEnd callTargetFromReturnAddress: pic asInteger + missOffset) = (self picAbortTrampolineFor: numArgs).
	self assert: openPICSize = (methodZone roundUpLength: openPICSize)."

	self assert: false
" self patchToOpenPICFor: cPIC selector
					numArgs: cPIC cmNumArgs
					receiver: rec"
]

{ #category : #'tests - metadata' }
VMSimpleStackBasedCogitMegamorphicPICTest >> testNewMegamorphicPICType [

	"self assert: pic cmType = CMOpenPIC.
	self assert: pic selector = selector.
	self assert: pic cmNumArgs = numArgs.
	self assert: (backEnd callTargetFromReturnAddress: pic asInteger + missOffset) = (self picAbortTrampolineFor: numArgs).
	self assert: openPICSize = (methodZone roundUpLength: openPICSize)."

	self assert: false
" self patchToOpenPICFor: cPIC selector
					numArgs: cPIC cmNumArgs
					receiver: rec"
]

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitMegamorphicPICTest >> testRelinkCallSiteToMegamorphicPICCallsNewPIC [

	"self assert: pic cmType = CMOpenPIC.
	self assert: pic selector = selector.
	self assert: pic cmNumArgs = numArgs.
	self assert: (backEnd callTargetFromReturnAddress: pic asInteger + missOffset) = (self picAbortTrampolineFor: numArgs).
	self assert: openPICSize = (methodZone roundUpLength: openPICSize)."

	self assert: false
" self patchToOpenPICFor: cPIC selector
					numArgs: cPIC cmNumArgs
					receiver: rec"
]
