Class {
	#name : #VMStackFrame,
	#superclass : #Object,
	#instVars : [
		'framePointer',
		'interpreter'
	],
	#pools : [
		'VMStackFrameOffsets'
	],
	#category : #'VMMakerTests-Visualisation'
}

{ #category : #'instance creation' }
VMStackFrame class >> newFramePointer: anInteger withInterpreter: aStackInterpreterSimulatorLSB [
	^self new
		framePointer: anInteger;
		interpreter: aStackInterpreterSimulatorLSB;
		yourself
]

{ #category : #'instance creation' }
VMStackFrame class >> virtualMachine: aVirtualMachine fp: anInteger [
	
	^ self newFramePointer: anInteger withInterpreter: aVirtualMachine
]

{ #category : #accessing }
VMStackFrame >> bytecodeMethod [
	
	^ VMBytecodeMethod newOnInterpreter: interpreter methodOop: self method
]

{ #category : #accessing }
VMStackFrame >> caller [

	| callerContext |

	"If the caller FP is different than zero, it is just a stack frame, return it"
	self callerFP ~= 0 ifTrue: [ 
		^ VMStackFrame
			newFramePointer: self callerFP
			withInterpreter: interpreter ].
	
	"Get the caller frame context. If nil, we finished". 
	callerContext := interpreter frameCallerContext: framePointer.
	(interpreter objectMemory isForwarded: callerContext) ifTrue:
		[callerContext := interpreter objectMemory followForwarded: callerContext].
	
	callerContext = interpreter objectMemory nilObject
		ifTrue: [ ^ nil ].
	
	"If the context is married get its espouse frame"
	((interpreter isMarriedOrWidowedContext: callerContext)
		and: [interpreter
			checkIsStillMarriedContext: callerContext
			currentFP: interpreter framePointer])
				ifTrue: [ 
					^ VMStackFrame
						newFramePointer: (interpreter frameOfMarriedContext: callerContext)
						withInterpreter: interpreter ].
		
	"At this point, the caller context is not married, so it is either widowed or single.
	Return a special ContextFrame"
	^ VMContext newOnContext: callerContext withInterpreter: interpreter
]

{ #category : #accessing }
VMStackFrame >> callerContext [
	
	^ interpreter frameCallerContext: framePointer
]

{ #category : #accessing }
VMStackFrame >> callerFP [

	^ interpreter frameCallerFP: framePointer
]

{ #category : #accessing }
VMStackFrame >> context [
	^VMContext newOnContext: (interpreter frameContext: framePointer) withInterpreter: interpreter 
]

{ #category : #accessing }
VMStackFrame >> description [
	| selector |
	selector := interpreter findSelectorOfMethod: self methodOop.
	^ interpreter stringOf: selector
]

{ #category : #accesing }
VMStackFrame >> framePointer: anInteger [ 
	framePointer := anInteger
]

{ #category : #testing }
VMStackFrame >> hasContext [
	^interpreter frameHasContext: framePointer 
]

{ #category : #accessing }
VMStackFrame >> instructionPointer [

	^ interpreter framePointer = framePointer
		ifTrue: [ interpreter instructionPointer ]
		ifFalse: [ interpreter frameCallerSavedIP: ( interpreter findFrameAbove: framePointer inPage: self stackPage) ]
]

{ #category : #acccessing }
VMStackFrame >> interpreter: aStackInterpreterSimulatorLSB [ 
	interpreter := aStackInterpreterSimulatorLSB
]

{ #category : #testing }
VMStackFrame >> isMachineCodeFrame [
	
	^ interpreter isMachineCodeFrame: framePointer
]

{ #category : #accessing }
VMStackFrame >> machineCodeMethod [
	| methodSurrogate |
	methodSurrogate := interpreter cogMethodZone methodFor: self method.
	^ VMMachineCodeMethod newOnInterpreter: interpreter cogMethodSurrogate: methodSurrogate
]

{ #category : #accessing }
VMStackFrame >> method [

	^ interpreter frameMethod: framePointer
]

{ #category : #accessing }
VMStackFrame >> methodOop [

	^ interpreter frameMethodObject: framePointer
]

{ #category : #accessing }
VMStackFrame >> receiver [
	^ interpreter framePointer = framePointer
		ifTrue: [ interpreter receiver ]
		ifFalse: [ self halt. interpreter frameCallerSavedIP: ( interpreter findFrameAbove: framePointer inPage: self stackPage) ]
]

{ #category : #accessing }
VMStackFrame >> sender [
	^ VMStackFrame newFramePointer:(interpreter frameCallerFP: framePointer) withInterpreter: interpreter
	 
]

{ #category : #accessing }
VMStackFrame >> sourceCode [
	
	^ self isMachineCodeFrame
		ifTrue: [ self machineCodeMethod disassemble ]
		ifFalse: [ self bytecodeMethod disassemble ]
]

{ #category : #accessing }
VMStackFrame >> stack [
	| stack currentFrame |
	stack := OrderedCollection new.
	currentFrame := self.
	[ currentFrame notNil ] whileTrue: [ 
		stack add: currentFrame.
		currentFrame := currentFrame caller ].
	^ stack
]

{ #category : #accessing }
VMStackFrame >> stackPage [
	^interpreter stackPages stackPageFor: framePointer.
]
