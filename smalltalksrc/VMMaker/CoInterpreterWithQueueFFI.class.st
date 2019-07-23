Class {
	#name : #CoInterpreterWithQueueFFI,
	#superclass : #CoInterpreterPrimitives,
	#instVars : [
		'disabledFFIFunction'
	],
	#category : #'VMMaker-QueueFFI'
}

{ #category : #'cog jit support' }
CoInterpreterWithQueueFFI >> primitivePropertyFlagsForSpur: primIndex [
	<inline: true>
"This is a hack to avoid the primitive call to be converted in a CogMethod.
 The calling code of a CogMethod calling a primitive
 modifies the interpreter stack to store the return pointer.
 As in our impl the callout starts an interpreter that runs everything that is available
 the stack is modified without control, so if the primitive is cogged it produces a crash
 because it returns to any invalid place.
" 
	(primIndex = self primNumberExternalCall) ifTrue: [
		(disabledFFIFunction notNil and: [ disabledFFIFunction = primitiveFunctionPointer ]) ifTrue: [ ^ PrimCallDoNotJIT ]
	].

	^ super primitivePropertyFlagsForSpur: primIndex	


]

{ #category : #'cog jit support' }
CoInterpreterWithQueueFFI >> ptDisableCogIt: aFunction [
	<api>
	<var: #aFunction type: #'void*'>
	
	disabledFFIFunction := aFunction
]

{ #category : #'cog jit support' }
CoInterpreterWithQueueFFI >> ptEnterInterpreterFromCallback: aPointer [
	<api>
	<var: #aPointer type: #'void *'>
	<var: #vmCallbackContext type: #'VMCallbackContext *'>

	| vmCallbackContext |

	vmCallbackContext := self cCoerce: aPointer to: #'VMCallbackContext *'.

	"I am the entry point when arriving for a callback"
	
	cogit assertCStackWellAligned.
	vmCallbackContext savedPrimFunctionPointer: primitiveFunctionPointer.
	vmCallbackContext savedCStackPointer: cogit getCStackPointer.
	vmCallbackContext savedCFramePointer: cogit getCFramePointer.	
	
	self cCode:
			[self memcpy: vmCallbackContext savedReenterInterpreter
				_: reenterInterpreter
				_: (self sizeof: #'jmp_buf')]
		inSmalltalk:
			[ vmCallbackContext savedReenterInterpreter: reenterInterpreter].
		
	
	self enterSmalltalkExecutive.
	
	"NEVER REACHED"
	^ 1
]

{ #category : #'cog jit support' }
CoInterpreterWithQueueFFI >> ptExitInterpreterToCallback: aPointer [
	<api>
	<var: #aPointer type: #'void *'>
	<var: #vmCallbackContext type: #'VMCallbackContext *'>

	| vmCallbackContext |

	vmCallbackContext := self cCoerce: aPointer to: #'VMCallbackContext *'.
	
	cogit setCStackPointer: vmCallbackContext savedCStackPointer.
	cogit setCFramePointer: vmCallbackContext savedCFramePointer.
	
	self cCode:
			[self memcpy: reenterInterpreter
				_: vmCallbackContext savedReenterInterpreter
				_: (self sizeof: #'jmp_buf')]
		inSmalltalk:
			[ reenterInterpreter := vmCallbackContext savedReenterInterpreter ].
		
	primitiveFunctionPointer := vmCallbackContext savedPrimFunctionPointer.
	
	self siglong: vmCallbackContext trampoline jmp: 1.

	"NEVER REACHED"	
	^ 1

]
