"
I am a shared pool for the constants that define frame layout shared between the stack interpreters and the cogit.
"
Class {
	#name : #VMStackFrameOffsets,
	#superclass : #SharedPool,
	#classVars : [
		'FoxCallerContext',
		'FoxCallerSavedIP',
		'FoxFrameFlags',
		'FoxIFReceiver',
		'FoxIFSavedIP',
		'FoxIFrameFlags',
		'FoxMFReceiver',
		'FoxMethod',
		'FoxReceiver',
		'FoxSavedFP',
		'FoxThisContext',
		'FrameSlots',
		'IFrameSlots',
		'MFMethodFlagHasContextFlag',
		'MFMethodFlagIsBlockFlag',
		'MFMethodFlagsMask',
		'MFMethodMask',
		'MFrameSlots'
	],
	#category : 'VMMaker-Interpreter'
}
