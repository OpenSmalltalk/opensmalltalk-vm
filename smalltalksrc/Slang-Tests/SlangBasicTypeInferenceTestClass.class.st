Class {
	#name : #SlangBasicTypeInferenceTestClass,
	#superclass : #SlangClass,
	#category : #'Slang-Tests'
}

{ #category : #constant }
SlangBasicTypeInferenceTestClass >> aBigNegativeIntegerConstantNode [
	"SmallInteger maxVal on a 64bit system"
	-1152921504606846975
]

{ #category : #constant }
SlangBasicTypeInferenceTestClass >> aFalseConstantNode [
	false
]

{ #category : #constant }
SlangBasicTypeInferenceTestClass >> aFloatConstantNode [
	1.0
]

{ #category : #constant }
SlangBasicTypeInferenceTestClass >> aNilConstantNode [
	nil
]

{ #category : #constant }
SlangBasicTypeInferenceTestClass >> aSmallNegativeIntegerConstantNode [
	-30
]

{ #category : #constant }
SlangBasicTypeInferenceTestClass >> aStringConstantNode [
	'aString'
]

{ #category : #constant }
SlangBasicTypeInferenceTestClass >> aTrueConstantNode [
	true
]

{ #category : #constant }
SlangBasicTypeInferenceTestClass >> anIntEqual32ConstantNode [
	" 2 ^ 32 - 1"
	4294967295
]

{ #category : #constant }
SlangBasicTypeInferenceTestClass >> anIntEqual64ConstantNode [
	" 2 raisedTo: 64 "
	18446744073709551615
]

{ #category : #constant }
SlangBasicTypeInferenceTestClass >> anIntGreater64ConstantNode [
	"SmallInteger maxVal on a 64bit system"
	1152921504606846975
]

{ #category : #constant }
SlangBasicTypeInferenceTestClass >> anIntLesser32ConstantNode [
	30
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTestClass >> returnABigNegativeIntegerConstantNode [
"SmallInteger maxVal on a 64bit system"
	^ -1152921504606846975
	
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTestClass >> returnABigNegativeIntegerMessageSend [
	^ self returnABigNegativeIntegerConstantNode
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTestClass >> returnAFalseConstantNode [
	^ false
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTestClass >> returnAFalseMessageSend [
	^ self returnAFalseConstantNode
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTestClass >> returnAFloatConstantNode [
	^ 1.0
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTestClass >> returnAFloatMessageSend [
	^ self returnAFloatConstantNode
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTestClass >> returnANilConstantNode [
	^ nil
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTestClass >> returnANilMessageSend [
	^ self returnANilConstantNode
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTestClass >> returnASmallNegativeIntegerConstantNode [
	^ -30
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTestClass >> returnASmallNegativeIntegerMessageSend [
	^ self returnASmallNegativeIntegerConstantNode
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTestClass >> returnAStringConstantNode [
	^ 'aString'
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTestClass >> returnAStringMessageSend [
	^ self returnAStringConstantNode
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTestClass >> returnATrueConstantNode [
	^ true
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTestClass >> returnATrueMessageSend [
	^ self returnATrueConstantNode
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTestClass >> returnAnIntEqual32ConstantNode [
	" 2 ^ 32 - 1"
	^ 4294967295
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTestClass >> returnAnIntEqual32MessageSend [
	^ self returnAnIntEqual32ConstantNode
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTestClass >> returnAnIntEqual64ConstantNode [
	" 2 raisedTo: 64 "
	^ 18446744073709551615
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTestClass >> returnAnIntEqual64MessageSend [
	^ self returnAnIntEqual64ConstantNode
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTestClass >> returnAnIntGreater64ConstantNode [
	"SmallInteger maxVal on a 64bit system"
	^ 1152921504606846975
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTestClass >> returnAnIntGreater64MessageSend [
	^ self returnAnIntGreater64ConstantNode
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTestClass >> returnAnIntLesser32ConstantNode [
	^ 30
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTestClass >> returnAnIntLesser32MessageSend [
	^ self returnAnIntLesser32ConstantNode
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTestClass >> returnExplicitArgDouble: t [
	<var:#t type:#double>
	^ t
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTestClass >> returnExplicitArgFloat: t [
	<var:#t type:#float>
	^ t
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTestClass >> returnExplicitArgInt: t [
	<var:#t type:#int>
	^ t
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTestClass >> returnExplicitArgLongLong: t [
	<var:#t type:#'long long'>
	^ t
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTestClass >> returnExplicitArgRandom: t [
	<var:#t type:#completelyRandom>
	^ t
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTestClass >> returnExplicitArgString: t [
	<var:#t type:#'char *'>
	^ t
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTestClass >> returnExplicitArgUnsignedInt: t [
	<var:#t type:#'unsigned int'>
	^ t
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTestClass >> returnExplicitArgUnsignedLongLong: t [
	<var:#t type:#'unsigned long long'>
	^ t
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTestClass >> returnExplicitTempDouble [
	<var:#t type:#double>
	| t |
	^ t
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTestClass >> returnExplicitTempFloat [
	<var:#t type:#float>
	| t |
	^ t
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTestClass >> returnExplicitTempInt [
	<var:#t type:#int>
	| t |
	^ t
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTestClass >> returnExplicitTempLongLong [
	<var:#t type:#'long long'>
	| t | 
	^ t
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTestClass >> returnExplicitTempRandom [
	<var:#t type:#completelyRandom>
	| t |
	^ t
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTestClass >> returnExplicitTempString [
	<var:#t type:#'char *'>
	| t |
	^ t
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTestClass >> returnExplicitTempUnsignedInt [
	<var:#t type:#'unsigned int'>
	| t |
	^ t
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTestClass >> returnExplicitTempUnsignedLongLong [
	<var:#t type:#'unsigned long long'>
	| t |
	^ t
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTestClass >> returnTempBigNegativeIntegerConstantNode [
	| t |
	"SmallInteger maxVal on a 64bit system"
	t := -1152921504606846975.
	^ t
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTestClass >> returnTempBigNegativeIntegerMessageNode [
	| t |
	t := self returnABigNegativeIntegerConstantNode.
	^ t
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTestClass >> returnTempFalseConstantNode [
	| t |
	t := false.
	^ t
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTestClass >> returnTempFalseMessageNode [
	| t |
	t := self returnAFalseConstantNode.
	^ t
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTestClass >> returnTempFloatConstantNode [
	| t |
	t := 1.0.
	^ t
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTestClass >> returnTempFloatMessageNode [
	| t |
	t := self returnAFloatMessageSend.
	^ t
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTestClass >> returnTempIntEqual32ConstantNode [
	" 2 ^ 32 - 1"
	| t |
	t := 4294967295.
	^ t
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTestClass >> returnTempIntEqual32MessageNode [
	| t |
	t := self returnAnIntEqual32ConstantNode.
	^ t
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTestClass >> returnTempIntEqual64ConstantNode [
	" 2 raisedTo: 64 "
	| t | 
	t := 18446744073709551615.
	^ t
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTestClass >> returnTempIntEqual64MessageNode [
	| t | 
	t := self returnAnIntEqual64ConstantNode.
	^ t
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTestClass >> returnTempIntGreater64ConstantNode [
	| t |
	"SmallInteger maxVal on a 64bit system"
	t := 1152921504606846975.
	^ t
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTestClass >> returnTempIntGreater64MessageNode [
	| t |
	t := self returnAnIntGreater64ConstantNode.
	^ t
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTestClass >> returnTempIntLesser32ConstantNode [
	| t |
	t := 30.
	^ t
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTestClass >> returnTempIntLesser32MessageNode [
	| t |
	t := self returnAnIntLesser32ConstantNode.
	^ t
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTestClass >> returnTempNilConstantNode [
	| t |
	t := nil.
	^ t
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTestClass >> returnTempNilMessageNode [
	| t |
	t := self returnANilConstantNode.
	^ t
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTestClass >> returnTempSmallNegativeIntegerConstantNode [
	| t |
	t := -30.
	^ t
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTestClass >> returnTempSmallNegativeIntegerMessageNode [
	| t |
	t := self returnASmallNegativeIntegerConstantNode.
	^ t
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTestClass >> returnTempStringConstantNode [
	| t |
	t := 'aString'.
	^ t
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTestClass >> returnTempStringMessageNode [
	| t |
	t := self returnAStringConstantNode.
	^ t
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTestClass >> returnTempTrueConstantNode [
	| t |
	t := true.
	^ t
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTestClass >> returnTempTrueMessageNode [
	| t |
	t := self returnATrueConstantNode.
	^ t
]
