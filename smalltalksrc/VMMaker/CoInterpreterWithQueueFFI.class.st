Class {
	#name : #CoInterpreterWithQueueFFI,
	#superclass : #CoInterpreterPrimitives,
	#instVars : [
		'disabledFFIFunction'
	],
	#category : #'VMMaker-QueueFFI'
}

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
