Class {
	#name : #MultiProcessor,
	#superclass : #Object,
	#instVars : [
		'mutex',
		'processor',
		'guardedProcessorProtocol',
		'unguardedProcessorProtocol',
		'owner',
		'registerState',
		'coInterpreter',
		'threadIndex'
	],
	#category : #'Cog-Processors'
}

{ #category : #'instance creation' }
MultiProcessor class >> for: aProcessorAlien coInterpreter: coInterpreter [
	^self new
		processor: aProcessorAlien;
		coInterpreter: coInterpreter;
		yourself
]

{ #category : #'initialize-release' }
MultiProcessor >> coInterpreter: aCoInterpreter [
	coInterpreter := aCoInterpreter
]

{ #category : #'message forwarding' }
MultiProcessor >> doesNotUnderstand: aMessage [
	"Forward a message to the actual processor, managing a thread-switch if necessary.
	 Catch ProcessorSimulationTraps and raise them outside of the critical section to
	 avoid deadlock when reentering the VM from a trap and switching threads in the run-time."
	| selector result trap |
	selector := aMessage selector.
	(guardedProcessorProtocol includes: selector) ifFalse:
		[^(unguardedProcessorProtocol includes: selector)
			ifTrue: [processor perform: selector withArguments: aMessage arguments]
			ifFalse: [super doesNotUnderstand: aMessage]].
	result := [mutex critical:
				[owner ~~ mutex owningProcess ifTrue:
					[owner ifNotNil:
						[registerState at: owner put: processor registerState].
					 (registerState at: (owner := mutex owningProcess) ifAbsent: nil)
						ifNil: [coInterpreter initializeProcessorForThreadIndex: (threadIndex := threadIndex + 1)]
						ifNotNil: [:newState| processor setRegisterState: newState]].
				 processor perform: selector withArguments: aMessage arguments]]
					on: ProcessorSimulationTrap, Error
					do: [:ex| trap := ex].
	^trap ifNil: [result] ifNotNil: [trap signal]
]

{ #category : #'initialize-release' }
MultiProcessor >> initialize [
	registerState := WeakIdentityKeyDictionary new.
	mutex := Mutex new.
	threadIndex := 0.
	guardedProcessorProtocol := unguardedProcessorProtocol := Set new
]

{ #category : #'initialize-release' }
MultiProcessor >> processor: aProcessor [
	processor := aProcessor.
	guardedProcessorProtocol := aProcessor class selectors asSet
									addAll: aProcessor class superclass selectors;
									yourself.
	unguardedProcessorProtocol := #(#'Cog API' #opcodes #disassembly #printing)
										inject: Set new
										into: [ :protocol :category|
											protocol
												addAll: (aProcessor class organization listAtCategoryNamed: category);
												addAll: (aProcessor class superclass organization listAtCategoryNamed: category);
												yourself].
	guardedProcessorProtocol removeAll: unguardedProcessorProtocol
]
