"
FloatArrayPlugin provides fast access to FloatArrays for batch processing of float numbers
"
Class {
	#name : #FloatArrayPlugin,
	#superclass : #InterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #'translation to C' }
FloatArrayPlugin class >> declareCVarsIn: cg [
	"Nothing to declare..."
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveAddFloatArray [
	"Primitive. Add the receiver and the argument, both FloatArrays and store the result into the receiver."
	| rcvr arg rcvrPtr argPtr length |
	self export: true.
	self var: #rcvrPtr declareC:'float *rcvrPtr'.
	self var: #argPtr declareC:'float *argPtr'.
	arg _ interpreterProxy stackObjectValue: 0.
	rcvr _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: arg).
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length _ interpreterProxy stSizeOf: arg.
	interpreterProxy success: (length = (interpreterProxy stSizeOf: rcvr)).
	interpreterProxy failed ifTrue:[^nil].
	rcvrPtr _ self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	argPtr _ self cCoerce: (interpreterProxy firstIndexableField: arg) to: 'float *'.
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (rcvrPtr at: i) + (argPtr at: i).
	].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveAddScalar [
	"Primitive. Add the argument, a scalar value to the receiver, a FloatArray"
	| rcvr rcvrPtr value length |
	self export: true.
	self var: #value declareC:'double value'.
	self var: #rcvrPtr declareC:'float *rcvrPtr'.
	value _ interpreterProxy stackFloatValue: 0.
	rcvr _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length _ interpreterProxy stSizeOf: rcvr.
	rcvrPtr _ self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (rcvrPtr at: i) + value.
	].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'access primitives' }
FloatArrayPlugin >> primitiveAt [

	| index rcvr floatValue floatPtr |
	self export: true.
	self var: #floatValue declareC:'double floatValue'.
	self var: #floatPtr declareC:'float *floatPtr'.
	index _ interpreterProxy stackIntegerValue: 0.
	rcvr _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy success: (index > 0 and:[index <= (interpreterProxy slotSizeOf: rcvr)]).
	interpreterProxy failed ifTrue:[^nil].
	floatPtr _ interpreterProxy firstIndexableField: rcvr.
	floatValue _ (floatPtr at: index-1) asFloat.
	interpreterProxy pop: 2.
	interpreterProxy pushFloat: floatValue.
]

{ #category : #'access primitives' }
FloatArrayPlugin >> primitiveAtPut [

	| value floatValue index rcvr floatPtr |
	self export: true.
	self var: #floatValue declareC: 'double floatValue'.
	self var: #floatPtr declareC:'float *floatPtr'.
	value _ interpreterProxy stackValue: 0.
	(interpreterProxy isIntegerObject: value)
		ifTrue:[floatValue _ (interpreterProxy integerValueOf: value) asFloat]
		ifFalse:[floatValue _ interpreterProxy floatValueOf: value].
	index _ interpreterProxy stackIntegerValue: 1.
	rcvr _ interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy success: (index > 0 and:[index <= (interpreterProxy slotSizeOf: rcvr)]).
	interpreterProxy failed ifTrue:[^nil].
	floatPtr _ interpreterProxy firstIndexableField: rcvr.
	floatPtr at: index-1 put: (self cCoerce: floatValue to:'float').
	interpreterProxy failed ifFalse:[interpreterProxy pop: 3 thenPush: value].
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveDivFloatArray [
	"Primitive. Add the receiver and the argument, both FloatArrays and store the result into the receiver."
	| rcvr arg rcvrPtr argPtr length |
	self export: true.
	self var: #rcvrPtr declareC:'float *rcvrPtr'.
	self var: #argPtr declareC:'float *argPtr'.
	arg _ interpreterProxy stackObjectValue: 0.
	rcvr _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: arg).
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length _ interpreterProxy stSizeOf: arg.
	interpreterProxy success: (length = (interpreterProxy stSizeOf: rcvr)).
	interpreterProxy failed ifTrue:[^nil].
	rcvrPtr _ self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	argPtr _ self cCoerce: (interpreterProxy firstIndexableField: arg) to: 'float *'.
	"Check if any of the argument's values is zero"
	0 to: length-1 do:[:i|
		(interpreterProxy longAt: (argPtr + i)) = 0 ifTrue:[^interpreterProxy primitiveFail]].
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (rcvrPtr at: i) / (argPtr at: i).
	].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveDivScalar [
	"Primitive. Add the argument, a scalar value to the receiver, a FloatArray"
	| rcvr rcvrPtr value inverse length |
	self export: true.
	self var: #value declareC:'double value'.
	self var: #inverse declareC:'double inverse'.
	self var: #rcvrPtr declareC:'float *rcvrPtr'.
	value _ interpreterProxy stackFloatValue: 0.
	rcvr _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	value = 0.0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length _ interpreterProxy stSizeOf: rcvr.
	rcvrPtr _ self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	inverse _ 1.0 / value.
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (rcvrPtr at: i) * inverse.
	].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveDotProduct [
	"Primitive. Compute the dot product of the receiver and the argument.
	The dot product is defined as the sum of the products of the individual elements."
	| rcvr arg rcvrPtr argPtr length result |
	self export: true.
	self var: #rcvrPtr declareC:'float *rcvrPtr'.
	self var: #argPtr declareC:'float *argPtr'.
	self var: #result declareC:'double result'.
	arg _ interpreterProxy stackObjectValue: 0.
	rcvr _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: arg).
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length _ interpreterProxy stSizeOf: arg.
	interpreterProxy success: (length = (interpreterProxy stSizeOf: rcvr)).
	interpreterProxy failed ifTrue:[^nil].
	rcvrPtr _ self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	argPtr _ self cCoerce: (interpreterProxy firstIndexableField: arg) to: 'float *'.
	result _ 0.0.
	0 to: length-1 do:[:i|
		result _ result + ((rcvrPtr at: i) * (argPtr at: i)).
	].
	interpreterProxy pop: 2. "Pop args + rcvr"
	interpreterProxy pushFloat: result. "Return result"
]

{ #category : #'access primitives' }
FloatArrayPlugin >> primitiveEqual [

	| rcvr arg rcvrPtr argPtr length |
	self export: true.
	self var: #rcvrPtr declareC:'float *rcvrPtr'.
	self var: #argPtr declareC:'float *argPtr'.
	arg _ interpreterProxy stackObjectValue: 0.
	rcvr _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: arg).
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy pop: 2.
	length _ interpreterProxy stSizeOf: arg.
	length = (interpreterProxy stSizeOf: rcvr) ifFalse:[^interpreterProxy pushBool: false].

	rcvrPtr _ self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	argPtr _ self cCoerce: (interpreterProxy firstIndexableField: arg) to: 'float *'.
	0 to: length-1 do:[:i|
		(rcvrPtr at: i) = (argPtr at: i) ifFalse:[^interpreterProxy pushBool: false].
	].
	^interpreterProxy pushBool: true
]

{ #category : #'access primitives' }
FloatArrayPlugin >> primitiveHashArray [

	| rcvr rcvrPtr length result |
	self export: true.
	self var: #rcvrPtr declareC:'int *rcvrPtr'.
	rcvr _ interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length _ interpreterProxy stSizeOf: rcvr.
	rcvrPtr _ self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'int *'.
	result _ 0.
	0 to: length-1 do:[:i|
		result _ result + (rcvrPtr at: i).
	].
	interpreterProxy pop: 1.
	^interpreterProxy pushInteger: (result bitAnd: 16r1FFFFFFF)
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveMulFloatArray [
	"Primitive. Add the receiver and the argument, both FloatArrays and store the result into the receiver."
	| rcvr arg rcvrPtr argPtr length |
	self export: true.
	self var: #rcvrPtr declareC:'float *rcvrPtr'.
	self var: #argPtr declareC:'float *argPtr'.
	arg _ interpreterProxy stackObjectValue: 0.
	rcvr _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: arg).
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length _ interpreterProxy stSizeOf: arg.
	interpreterProxy success: (length = (interpreterProxy stSizeOf: rcvr)).
	interpreterProxy failed ifTrue:[^nil].
	rcvrPtr _ self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	argPtr _ self cCoerce: (interpreterProxy firstIndexableField: arg) to: 'float *'.
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (rcvrPtr at: i) * (argPtr at: i).
	].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveMulScalar [
	"Primitive. Add the argument, a scalar value to the receiver, a FloatArray"
	| rcvr rcvrPtr value length |
	self export: true.
	self var: #value declareC:'double value'.
	self var: #rcvrPtr declareC:'float *rcvrPtr'.
	value _ interpreterProxy stackFloatValue: 0.
	rcvr _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length _ interpreterProxy stSizeOf: rcvr.
	rcvrPtr _ self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (rcvrPtr at: i) * value.
	].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveSubFloatArray [
	"Primitive. Add the receiver and the argument, both FloatArrays and store the result into the receiver."
	| rcvr arg rcvrPtr argPtr length |
	self export: true.
	self var: #rcvrPtr declareC:'float *rcvrPtr'.
	self var: #argPtr declareC:'float *argPtr'.
	arg _ interpreterProxy stackObjectValue: 0.
	rcvr _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: arg).
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length _ interpreterProxy stSizeOf: arg.
	interpreterProxy success: (length = (interpreterProxy stSizeOf: rcvr)).
	interpreterProxy failed ifTrue:[^nil].
	rcvrPtr _ self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	argPtr _ self cCoerce: (interpreterProxy firstIndexableField: arg) to: 'float *'.
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (rcvrPtr at: i) - (argPtr at: i).
	].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveSubScalar [
	"Primitive. Add the argument, a scalar value to the receiver, a FloatArray"
	| rcvr rcvrPtr value length |
	self export: true.
	self var: #value declareC:'double value'.
	self var: #rcvrPtr declareC:'float *rcvrPtr'.
	value _ interpreterProxy stackFloatValue: 0.
	rcvr _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length _ interpreterProxy stSizeOf: rcvr.
	rcvrPtr _ self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (rcvrPtr at: i) - value.
	].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveSum [
	"Primitive. Find the sum of each float in the receiver, a FloatArray, and stash the result into the argument Float."
	| rcvr rcvrPtr length sum |
	self export: true.
	self var: #sum declareC:'double sum'.
	self var: #rcvrPtr declareC:'float *rcvrPtr'.
	rcvr _ interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length _ interpreterProxy stSizeOf: rcvr.
	rcvrPtr _ self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	sum _ 0.0.
	0 to: length-1 do:[:i|
		sum _ sum + (rcvrPtr at: i).
	].
	interpreterProxy pop: 1 thenPush: (interpreterProxy floatObjectOf: sum)
]
