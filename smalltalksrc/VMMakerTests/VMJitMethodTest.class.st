Class {
	#name : #VMJitMethodTest,
	#superclass : #VMPrimitiveCallAbstractTest,
	#pools : [
		'CogRTLOpcodes'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #running }
VMJitMethodTest >> initialCodeSize [

	^ 16 * 1024
]

{ #category : #running }
VMJitMethodTest >> initializeSpecialSelectors [

	| specialSelectorsArrayOop |
	specialSelectorsArrayOop := self newOldSpaceObjectWithSlots:
		                            Smalltalk specialSelectors size.

	Smalltalk specialSelectors withIndexDo: [ :anElement :anIndex | 
		memory
			storePointer: anIndex - 1
			ofObject: specialSelectorsArrayOop
			withValue: (anElement forMemory: memory) ].
		
	memory splObj: SpecialSelectors put: specialSelectorsArrayOop
]

{ #category : #running }
VMJitMethodTest >> setUp [ 

	super setUp.
	self initializeSpecialSelectors
]

{ #category : #running }
VMJitMethodTest >> setUpTrampolines [

	super setUpTrampolines.
	
	cogit ceSendMustBeBooleanAddFalseTrampoline: (self compileTrampoline: [ cogit RetN: 0 ] named:#ceSendMustBeBooleanAddFalseTrampoline).
	cogit ceSendMustBeBooleanAddTrueTrampoline: (self compileTrampoline: [ cogit RetN: 0 ] named:#ceSendMustBeBooleanAddTrueTrampoline).

	cogit ceCheckForInterruptTrampoline: (self compileTrampoline: [ cogit RetN: 0 ] named:#ceCheckForInterruptTrampoline)
]

{ #category : #tests }
VMJitMethodTest >> testMixedInlinedLiteralsSmoteTest [
	| callingMethod |
	
	callingMethod := self jitMethod: (FreeTypeSubPixelAntiAliasedGlyphRenderer>>#filter:).
	
	self deny: callingMethod address equals: 0.
]
