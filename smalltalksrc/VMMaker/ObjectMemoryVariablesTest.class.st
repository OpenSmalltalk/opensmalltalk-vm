"
ObjectMemoryVariablesTest validates the values of the constants defined in ObjectMemory class>>initBytesPerWord:

The intent is to enable rewriting these constants in a manner that permits them to be fully defined as C preprocessor macros at compile time, such that separate code generation is not required for 32-bit and 64-bit object memory.

See CCodeGenerator>>emitDefineBytesPerWordOn: for the C preprocessor macro definitions.
"
Class {
	#name : #ObjectMemoryVariablesTest,
	#superclass : #TestCase,
	#instVars : [
		'saveWordSize',
		'omv32',
		'omv64'
	],
	#category : #'VMMaker-Tests'
}

{ #category : #running }
ObjectMemoryVariablesTest >> setUp [
	ObjectMemory initializeConstants
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte0Mask [

	self assert: ObjectMemory byte0Mask = 16r00000000000000FF
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte0Shift [

	self assert: ObjectMemory byte0Shift = 0
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte1Mask [

	self assert: ObjectMemory byte1Mask = 16r000000000000FF00
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte1Shift [

	self assert: ObjectMemory byte1Shift = 8
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte1ShiftNegated [
	"Note - signed values are not relevant for bit mask operations, can be recoded as positive"

	self assert: ObjectMemory byte1ShiftNegated = -16r0000000000000008.
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte2Mask [

	self assert: ObjectMemory byte2Mask = 16r0000000000FF0000
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte2Shift [

	self assert: ObjectMemory byte2Shift = 16
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte3Mask [

	self assert: ObjectMemory byte3Mask = 16r00000000FF000000
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte3Shift [

	self assert: ObjectMemory byte3Shift = 24
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte3ShiftNegated [
	"Note - signed values are not relevant for bit mask operations, can be recoded as positive"

	self assert: ObjectMemory byte3ShiftNegated = -16r0000000000000018
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte4Mask [

	"Note - unused for 32-bit object memory, so 32-bit test is no longer relevant
	ObjectMemory initBytesPerWord: 4.
	self assert: ObjectMemory byte4Mask = 16r0000000000000000."

	self assert: ObjectMemory byte4Mask = 16r000000FF00000000
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte4Shift [

	"Note - unused for 32-bit object memory, so 32-bit test is no longer relevant
	ObjectMemory initBytesPerWord: 4.
	self assert: ObjectMemoryConstantsAccess byte4Shift = 0."

	self assert: ObjectMemory byte4Shift = 32
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte4ShiftNegated [
	"Note - signed values are not relevant for bit mask operations, can be recoded as positive"

	"Note - unused for 32-bit object memory, so 32-bit test is no longer relevant
	ObjectMemory  initBytesPerWord: 4.
	self assert: ObjectMemory byte4ShiftNegated = 16r0000000000000000."

	self assert: ObjectMemory byte4ShiftNegated = -16r0000000000000020
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte5Mask [

	"Note - unused for 32-bit object memory, so 32-bit test is no longer relevant
	ObjectMemory initBytesPerWord: 4.
	self assert: ObjectMemory byte5Mask = 16r0000000000000000."

	self assert: ObjectMemory byte5Mask = 16r0000FF0000000000
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte5Shift [

	"Note - unused for 32-bit object memory, so 32-bit test is no longer relevant
	ObjectMemory initBytesPerWord: 4.
	self assert: ObjectMemory byte5Shift = 0."

	self assert: ObjectMemory byte5Shift = 40
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte5ShiftNegated [
	"Note - signed values are not relevant for bit mask operations, can be recoded as positive"

	"Note - unused for 32-bit object memory, so 32-bit test is no longer relevant
	ObjectMemory  initBytesPerWord: 4.
	self assert: ObjectMemory byte5ShiftNegated = 16r0000000000000000."

	self assert: ObjectMemory byte5ShiftNegated = -16r0000000000000028
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte6Mask [

	"Note - unused for 32-bit object memory, so 32-bit test is no longer relevant
	ObjectMemory initBytesPerWord: 4.
	self assert: ObjectMemory byte6Mask = 16r0000000000000000."

	self assert: ObjectMemory byte6Mask = 16r00FF000000000000
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte6Shift [

	"Note - unused for 32-bit object memory, so 32-bit test is no longer relevant
	ObjectMemory initBytesPerWord: 4.
	self assert: ObjectMemory byte6Shift = 0."

	self assert: ObjectMemory byte6Shift = 48
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte7Mask [

	"Note - unused for 32-bit object memory, so 32-bit test is no longer relevant
	ObjectMemory initBytesPerWord: 4.
	self assert: ObjectMemory byte7Mask = 16r0000000000000000."

	self assert: ObjectMemory byte7Mask = 16rFF00000000000000
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte7Shift [

	"Note - unused for 32-bit object memory, so 32-bit test is no longer relevant
	ObjectMemory initBytesPerWord: 4.
	self assert: ObjectMemory byte7Shift = 0."

	self assert: ObjectMemory byte7Shift = 56
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testByte7ShiftNegated [
	"Note - signed values are not relevant for bit mask operations, can be recoded as positive"

	"Note - unused for 32-bit object memory, so 32-bit test is no longer relevant
	ObjectMemory  initBytesPerWord: 4.
	self assert: ObjectMemory byte7ShiftNegated = 16r0000000000000000."

	self assert: ObjectMemory byte7ShiftNegated = -16r0000000000000038
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testBytes3to0Mask [

	"Note - unused for 32-bit object memory, so 32-bit test is no longer relevant
	ObjectMemory initBytesPerWord: 4.
	self assert: ObjectMemory bytes3to0Mask = 16r0000000000000000."

	self assert: ObjectMemory bytes3to0Mask = 16r00000000FFFFFFFF
]

{ #category : #'testing - constants' }
ObjectMemoryVariablesTest >> testBytes7to4Mask [

	"Note - unused for 32-bit object memory, so 32-bit test is no longer relevant
	ObjectMemory initBytesPerWord: 4.
	self assert: ObjectMemory bytes7to4Mask = 16r0000000000000000."

	self assert: ObjectMemory bytes7to4Mask = 16rFFFFFFFF00000000
]
