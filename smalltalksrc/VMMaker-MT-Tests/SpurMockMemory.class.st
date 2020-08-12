Class {
	#name : #SpurMockMemory,
	#superclass : #VMClass,
	#instVars : [
		'coInterpreter',
		'addressMap',
		'currentAddress',
		'nilObject',
		'trueObject',
		'falseObject',
		'schedulerAssociation',
		'processInExternalCodeTag'
	],
	#category : #'VMMaker-MT-Tests'
}

{ #category : #testing }
SpurMockMemory class >> hasSpurMemoryManagerAPI [

	^ true
]

{ #category : #initialization }
SpurMockMemory class >> initializeWithOptions: aCollection [ 

	Spur32BitMemoryManager initializeWithOptions: aCollection
]

{ #category : #accessing }
SpurMockMemory class >> numSmallIntegerTagBits [
	"let's mock a 32bit memory"
	^1
]

{ #category : #accessing }
SpurMockMemory class >> simulatorClass [
	"seems useless"
	^ self
]

{ #category : #initialization }
SpurMockMemory class >> wordSize [

	^ 4 "32 bits"
]

{ #category : #testing }
SpurMockMemory >> addressCouldBeObj: address [

	^ addressMap includes: address 
]

{ #category : #transforming }
SpurMockMemory >> addressOf: anObject [

	anObject isInteger ifTrue: [ ^ self integerObjectOf: anObject ].
	^ addressMap at: anObject ifAbsentPut: [ self nextAddress ]
]

{ #category : #accessing }
SpurMockMemory >> baseHeaderSize [

	^ 8
]

{ #category : #accesing }
SpurMockMemory >> bytesPerOop [

	^ self wordSize 
]

{ #category : #accessing }
SpurMockMemory >> coInterpreter: anInterpreter [ 

	coInterpreter := anInterpreter
]

{ #category : #accessing }
SpurMockMemory >> fetchPointer: anInteger ofObject: anAddress [
	
	^ (self objectFor: anAddress) fetchPointer: anInteger
]

{ #category : #accessing }
SpurMockMemory >> followField: anInteger ofObject: anObject [
	
	^ self fetchPointer: anInteger ofObject: anObject
]

{ #category : #accessing }
SpurMockMemory >> followObjField: anInteger ofObject: anObject [

	^ self fetchPointer: anInteger ofObject: anObject
]

{ #category : #asserting }
SpurMockMemory >> goodContextSize: aMockContext [ 

	^ true
]

{ #category : #testing }
SpurMockMemory >> hasSpurMemoryManagerAPI [

	^ self class hasSpurMemoryManagerAPI
]

{ #category : #accessing }
SpurMockMemory >> headerIndicatesAlternateBytecodeSet: methodHeader [
	"A negative header selects the alternate bytecode set."
	<api>
	<inline: true>
	^methodHeader signedIntFromLong < 0
]

{ #category : #initialization }
SpurMockMemory >> initialize [

	| mockProcess association |
	super initialize.	
	addressMap := IdentityDictionary new.
	currentAddress := 0.
	
	nilObject := self addressOf: nil.
	trueObject := self addressOf: true.
	falseObject := self addressOf: false.
	processInExternalCodeTag := self addressOf: #ProcessInExternalCodeTag.
	
	mockProcess := VMMockProcess new.
	mockProcess objectMemory: self.
	
	association := (VMMockSchedulerAssociation
		on:  (VMMockScheduler new
					objectMemory: self;
					activeProcess: mockProcess;
					yourself))
		objectMemory: self;
		yourself.
	schedulerAssociation := self addressOf: association.
]

{ #category : #transforming }
SpurMockMemory >> integerObjectOf: value [
	"Convert the integer value, assumed to be in SmallInteger range, into a tagged SmallInteger object.
	 In C, use a shift and an add to set the tag bit.
	 In Smalltalk we have to work harder because the simulator works with strictly positive bit patterns."
	<returnTypeC: #sqInt>
	^self
		cCode: [value << 1 + 1]
		inSmalltalk: [value >= 0
						ifTrue: [value << 1 + 1]
						ifFalse: [16r80000000 + value << 1 + 1]]
]

{ #category : #accessing }
SpurMockMemory >> integerValueOf: oop [
	"Translator produces 'oop >> 1'"
	^(oop bitShift: -31) = 1 "tests top bit"
		ifTrue: "negative"
			[((oop bitShift: -1) bitAnd: 16r3FFFFFFF) - 16r3FFFFFFF - 1  "Faster than -16r40000000 (a LgInt)"]
		ifFalse: "positive"
			[oop bitShift: -1]
]

{ #category : #asserting }
SpurMockMemory >> isContext: aMockContext [ 

	^ true
]

{ #category : #testing }
SpurMockMemory >> isForwarded: anInteger [ 

	^ false
]

{ #category : #testing }
SpurMockMemory >> isIntegerObject: oop [

	^(oop bitAnd: self smallIntegerTag) ~= 0
]

{ #category : #asserting }
SpurMockMemory >> isNonImmediate: anObject [
	
	^ anObject even
]

{ #category : #testing }
SpurMockMemory >> isOopCompiledMethod: anAddress [
	
	^ (self objectFor: anAddress) isCompiledMethod
]

{ #category : #testing }
SpurMockMemory >> isOopForwarded: anObject [
	
	^ false
]

{ #category : #'method-accessing' }
SpurMockMemory >> lastPointerOf: anInteger [ 
	"Just for testing"
	^ 0
]

{ #category : #accessing }
SpurMockMemory >> lengthOf: anAddress [
	
	^ (self objectFor: anAddress) size
]

{ #category : #'method-accessing' }
SpurMockMemory >> literalCountOf: anAddress [ 

	^ (self objectFor: anAddress) literals size
]

{ #category : #accessing }
SpurMockMemory >> maxCInteger [
	^16rFFFFFFFF
]

{ #category : #accessing }
SpurMockMemory >> memoryActiveProcess [

	^ self addressOf: self processorSchedulerMock activeProcess
]

{ #category : #'method-accessing' }
SpurMockMemory >> methodHeaderOf: anAddress [
	
	^ (self objectFor: anAddress) header
]

{ #category : #initialization }
SpurMockMemory >> nextAddress [

	| next |
	next := currentAddress.
	currentAddress := currentAddress + self wordSize.
	^ next
]

{ #category : #accessing }
SpurMockMemory >> nilObject [

	^ nilObject
]

{ #category : #'method-accessing' }
SpurMockMemory >> numBytesOfBytes: anInteger [ 

	"Just for testing"
	^ 56
]

{ #category : #accessing }
SpurMockMemory >> numSlotsOf: anAddress [

	^ (self objectFor: anAddress) numSlots
]

{ #category : #accessing }
SpurMockMemory >> objectFor: anAddress [

	(self isIntegerObject: anAddress)
		ifTrue: [ ^ self integerValueOf: anAddress ].
	^ addressMap keyAtValue: anAddress
]

{ #category : #mocks }
SpurMockMemory >> processorSchedulerMock [

	^ self objectFor: (self fetchPointer: ValueIndex ofObject: (self splObj: SchedulerAssociation))
]

{ #category : #accessing }
SpurMockMemory >> shiftForWord [
	<api>
	<cmacro>
	"32 bits"
	^2
]

{ #category : #accessing }
SpurMockMemory >> smallIntegerTag [
	"Beware, SmallInteger tags are 1 or 3.  But SmallInteger's identityHash is 1."
	<api>
	<cmacro>
	^1
]

{ #category : #accessing }
SpurMockMemory >> splObj: anInteger [ 

	"Processor Scheduler association"
	anInteger = 3
		ifTrue: [ ^ schedulerAssociation ].
	anInteger = 40
		ifTrue: [ ^ processInExternalCodeTag ].
	anInteger = 56
		ifTrue: [ ^ self nilObject "foreignCallbackProcess" ].
	self error: 'unexpected index: ', anInteger asString.
]

{ #category : #accesing }
SpurMockMemory >> startOfMemory [

	^ 0
]

{ #category : #storing }
SpurMockMemory >> storePointer: anInteger ofObject: anAddress withValue: aValue [

	(self objectFor: anAddress) storePointer: anInteger withValue: aValue
]

{ #category : #accessing }
SpurMockMemory >> storePointerUnchecked: anInteger ofObject: anAddress withValue: aValueAddress [ 

	(self objectFor: anAddress) storePointer: anInteger withValue: aValueAddress
]

{ #category : #accessing }
SpurMockMemory >> wordSize [

	^ self class wordSize
]
