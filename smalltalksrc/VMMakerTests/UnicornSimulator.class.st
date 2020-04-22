Class {
	#name : #UnicornSimulator,
	#superclass : #Object,
	#instVars : [
		'unicorn'
	],
	#category : #VMMakerTests
}

{ #category : #'instance creation' }
UnicornSimulator class >> IA32 [

	^ UnicornI386Simulator new
]

{ #category : #accessing }
UnicornSimulator class >> X64 [
	
	^ UnicornX64Simulator new
]

{ #category : #registers }
UnicornSimulator >> classRegister [
	
	^ self subclassResponsibility
]

{ #category : #registers }
UnicornSimulator >> classRegisterValue [
	
	^ self readRegister: self classRegister
]

{ #category : #initialization }
UnicornSimulator >> createUnicorn [

	self subclassResponsibility
]

{ #category : #registers }
UnicornSimulator >> framePointerRegister [
	
	^ self subclassResponsibility
]

{ #category : #registers }
UnicornSimulator >> framePointerRegisterValue [

	^ self readRegister: self framePointerRegister
]

{ #category : #registers }
UnicornSimulator >> framePointerRegisterValue: aValue [
	
	self writeRegister: self framePointerRegister value: aValue
]

{ #category : #initialization }
UnicornSimulator >> initialize [

	super initialize.
	unicorn := self createUnicorn.
	self initializeUnicorn
]

{ #category : #initialization }
UnicornSimulator >> initializeUnicorn [

	unicorn
		registerInvalidMemoryAccessHook: UcHookType invalidMemoryAccess value 
		doing: [ :type :address :size :value | self halt ]
]

{ #category : #registers }
UnicornSimulator >> instructionPointerRegister [

	self subclassResponsibility
]

{ #category : #registers }
UnicornSimulator >> instructionPointerValue [
	
	^ self readRegister: self instructionPointerRegister
]

{ #category : #memory }
UnicornSimulator >> mapMemory: aMemory at: anAddress [

	unicorn
		mapHostMemory: aMemory
		atAddress: anAddress
		withPermissions: UnicornConstants permissionAll.
]

{ #category : #memory }
UnicornSimulator >> memoryAt: address readNext: byteSize [
	
	^ unicorn memoryAt: address readNext: byteSize
]

{ #category : #memory }
UnicornSimulator >> memoryAt: address write: bytes size: size [

	unicorn memoryAt: address write: bytes size: size
]

{ #category : #registers }
UnicornSimulator >> readRegister: aRegisterID [

	| registerValue |
	registerValue := ByteArray new: self wordSize.
	unicorn register: aRegisterID value readInto: registerValue.
	^ registerValue integerAt: 1 size: self wordSize signed: false
]

{ #category : #registers }
UnicornSimulator >> receiverRegister [
	
	^ self subclassResponsibility
]

{ #category : #registers }
UnicornSimulator >> receiverRegisterValue [

	^ self readRegister: self receiverRegister
]

{ #category : #registers }
UnicornSimulator >> receiverRegisterValue: anInteger [ 

	self writeRegister: self receiverRegister value: anInteger
]

{ #category : #'reading memory' }
UnicornSimulator >> register: anIndex readInto: aByteArray [ 

	unicorn register: anIndex readInto: aByteArray 
]

{ #category : #initialization }
UnicornSimulator >> registerHook: aBlock atAddress: anAddress [

	unicorn
		registerInvalidMemoryAccessHook: UcHookType fetchingAccess value 
		doing: [ :type :address :size :value | address = anAddress ifTrue: aBlock ]
]

{ #category : #registers }
UnicornSimulator >> returnRegisterValue [
	
	^ self receiverRegisterValue
]

{ #category : #registers }
UnicornSimulator >> returnRegisterValue: aValue [
	
	^ self receiverRegisterValue: aValue
]

{ #category : #registers }
UnicornSimulator >> sendNumberOfArgumentsRegister [

	self subclassResponsibility
]

{ #category : #regiters }
UnicornSimulator >> sendNumberOfArgumentsRegister: anInteger [ 
	self shouldBeImplemented.
]

{ #category : #registers }
UnicornSimulator >> sendNumberOfArgumentsRegisterValue [
	
	^ self readRegister: self sendNumberOfArgumentsRegister
]

{ #category : #registers }
UnicornSimulator >> sendNumberOfArgumentsRegisterValue: aValue [

	^ self writeRegister: self sendNumberOfArgumentsRegister value: aValue
]

{ #category : #registers }
UnicornSimulator >> stackPointerRegister [
	
	self subclassResponsibility
]

{ #category : #registers }
UnicornSimulator >> stackPointerRegisterValue [

	^ self readRegister: self stackPointerRegister
]

{ #category : #registers }
UnicornSimulator >> stackPointerRegisterValue: aValue [
	
	self writeRegister: self stackPointerRegister value: aValue
]

{ #category : #executing }
UnicornSimulator >> startAt: begin until: until timeout: timeout count: count [ 

	unicorn startAt: begin until: until timeout: timeout count: count
]

{ #category : #accessing }
UnicornSimulator >> wordSize [
	self subclassResponsibility
]

{ #category : #registers }
UnicornSimulator >> writeRegister: aRegister value: anInteger [ 

	| value |
	value := ByteArray new: self wordSize.
	value integerAt: 1 put: anInteger size: self wordSize signed: false.
	unicorn register: aRegister value write: value.

]
