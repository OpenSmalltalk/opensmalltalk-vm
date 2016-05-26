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
	<export: true>
	<var: #rcvrPtr type:'float *'>
	<var: #argPtr type:'float *'>
	arg := interpreterProxy stackObjectValue: 0.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: arg).
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length := interpreterProxy stSizeOf: arg.
	interpreterProxy success: (length = (interpreterProxy stSizeOf: rcvr)).
	interpreterProxy failed ifTrue:[^nil].
	rcvrPtr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	argPtr := self cCoerce: (interpreterProxy firstIndexableField: arg) to: 'float *'.
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (self cCoerce: (rcvrPtr at: i) to: 'double') + (self cCoerce: (argPtr at: i) to: 'double')].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveAddScalar [
	"Primitive. Add the argument, a scalar value to the receiver, a FloatArray"
	| rcvr rcvrPtr value length |
	<export: true>
	<var: #value type:'double '>
	<var: #rcvrPtr type:'float *'>
	value := interpreterProxy stackFloatValue: 0.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length := interpreterProxy stSizeOf: rcvr.
	rcvrPtr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (self cCoerce: (rcvrPtr at: i) to: 'double') + value].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'access primitives' }
FloatArrayPlugin >> primitiveAt [

	| index rcvr floatValue floatPtr |
	<export: true>
	<var: #floatValue type:'double '>
	<var: #floatPtr type:'float *'>
	index := interpreterProxy stackIntegerValue: 0.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy success: (index > 0 and:[index <= (interpreterProxy slotSizeOf: rcvr)]).
	interpreterProxy failed ifTrue:[^nil].
	floatPtr := interpreterProxy firstIndexableField: rcvr.
	floatValue := (floatPtr at: index-1) asFloat.
	interpreterProxy pop: 2.
	interpreterProxy pushFloat: floatValue.
]

{ #category : #'access primitives' }
FloatArrayPlugin >> primitiveAtPut [

	| value floatValue index rcvr floatPtr |
	<export: true>
	<var: #floatValue type: 'double '>
	<var: #floatPtr type:'float *'>
	value := interpreterProxy stackValue: 0.
	(interpreterProxy isIntegerObject: value)
		ifTrue:[floatValue := (interpreterProxy integerValueOf: value) asFloat]
		ifFalse:[floatValue := interpreterProxy floatValueOf: value].
	index := interpreterProxy stackIntegerValue: 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy success: (index > 0 and:[index <= (interpreterProxy slotSizeOf: rcvr)]).
	interpreterProxy failed ifTrue:[^nil].
	floatPtr := interpreterProxy firstIndexableField: rcvr.
	floatPtr at: index-1 put: (self cCoerce: floatValue to:'float').
	interpreterProxy failed ifFalse: [interpreterProxy pop: 3 thenPush: value].
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveDivFloatArray [
	"Primitive. Add the receiver and the argument, both FloatArrays and store the result into the receiver."
	| rcvr arg rcvrPtr argPtr length |
	<export: true>
	<var: #rcvrPtr type:'float *'>
	<var: #argPtr type:'float *'>
	arg := interpreterProxy stackObjectValue: 0.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: arg).
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length := interpreterProxy stSizeOf: arg.
	interpreterProxy success: (length = (interpreterProxy stSizeOf: rcvr)).
	interpreterProxy failed ifTrue:[^nil].
	rcvrPtr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	argPtr := self cCoerce: (interpreterProxy firstIndexableField: arg) to: 'float *'.
	"Check if any of the argument's values is zero"
	0 to: length-1 do:[:i|
		( interpreterProxy intAtPointer:(self cCoerce: (argPtr + i) to: 'char*')) = 0 ifTrue:[^interpreterProxy primitiveFail]].
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (self cCoerce: (rcvrPtr at: i) to: 'double') / (self cCoerce: (argPtr at: i) to: 'double').
	].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveDivScalar [
	"Primitive. Add the argument, a scalar value to the receiver, a FloatArray"
	| rcvr rcvrPtr value inverse length |
	<export: true>
	<var: #value type:'double '>
	<var: #inverse type:'double '>
	<var: #rcvrPtr type:'float *'>
	value := interpreterProxy stackFloatValue: 0.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	value = 0.0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length := interpreterProxy stSizeOf: rcvr.
	rcvrPtr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	inverse := 1.0 / value.
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (self cCoerce: (rcvrPtr at: i) to: 'double') * inverse.
	].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveDotProduct [
	"Primitive. Compute the dot product of the receiver and the argument.
	The dot product is defined as the sum of the products of the individual elements."
	| rcvr arg rcvrPtr argPtr length result |
	<export: true>
	<var: #rcvrPtr type:'float *'>
	<var: #argPtr type:'float *'>
	<var: #result type:'double '>
	arg := interpreterProxy stackObjectValue: 0.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: arg).
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length := interpreterProxy stSizeOf: arg.
	interpreterProxy success: (length = (interpreterProxy stSizeOf: rcvr)).
	interpreterProxy failed ifTrue:[^nil].
	rcvrPtr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	argPtr := self cCoerce: (interpreterProxy firstIndexableField: arg) to: 'float *'.
	result := 0.0.
	0 to: length-1 do:[:i|
		result := result + ((self cCoerce: (rcvrPtr at: i) to: 'double') * (self cCoerce: (argPtr at: i) to: 'double')).
	].
	interpreterProxy pop: 2. "Pop args + rcvr"
	interpreterProxy pushFloat: result. "Return result"
]

{ #category : #'access primitives' }
FloatArrayPlugin >> primitiveEqual [

	| rcvr arg rcvrPtr argPtr length |
	<export: true>
	<var: #rcvrPtr type:'float *'>
	<var: #argPtr type:'float *'>
	arg := interpreterProxy stackObjectValue: 0.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: arg).
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy pop: 2.
	length := interpreterProxy stSizeOf: arg.
	length = (interpreterProxy stSizeOf: rcvr) ifFalse:[^interpreterProxy pushBool: false].

	rcvrPtr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	argPtr := self cCoerce: (interpreterProxy firstIndexableField: arg) to: 'float *'.
	0 to: length-1 do:[:i|
		(rcvrPtr at: i) = (argPtr at: i) ifFalse:[^interpreterProxy pushBool: false].
	].
	^interpreterProxy pushBool: true
]

{ #category : #'access primitives' }
FloatArrayPlugin >> primitiveHashArray [

	| rcvr rcvrPtr length result |
	<export: true>
	<var: #rcvrPtr type:'int *'>
	rcvr := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length := interpreterProxy stSizeOf: rcvr.
	rcvrPtr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'int *'.
	result := 0.
	0 to: length-1 do:[:i|
		result := result + (rcvrPtr at: i).
	].
	interpreterProxy pop: 1.
	^interpreterProxy pushInteger: (result bitAnd: 16r1FFFFFFF)
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveLength [
	"Primitive. Compute the length of the argument (sqrt of sum of component squares)."
	<export: true>
	| rcvr rcvrPtr length len |
	<var: #rcvrPtr type: #'float *'>
	<var: #len type: #double>
	rcvr := interpreterProxy stackValue: 0.
	(interpreterProxy isWords: rcvr) ifFalse:
		[interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	length := interpreterProxy stSizeOf: rcvr.
	rcvrPtr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: #'float *'.
	len := 0.0.
	0 to: length-1 do:[:i|
		len := len + ((self cCoerce: (rcvrPtr at: i) to: #double) * (self cCoerce: (rcvrPtr at: i) to: #double)).
	].
	len > 0.0 ifFalse:
		[interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	interpreterProxy pop: 1 thenPush: (interpreterProxy floatObjectOf: (self sqrt: len))
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveMulFloatArray [
	"Primitive. Add the receiver and the argument, both FloatArrays and store the result into the receiver."
	| rcvr arg rcvrPtr argPtr length |
	<export: true>
	<var: #rcvrPtr type:'float *'>
	<var: #argPtr type:'float *'>
	arg := interpreterProxy stackObjectValue: 0.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: arg).
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length := interpreterProxy stSizeOf: arg.
	interpreterProxy success: (length = (interpreterProxy stSizeOf: rcvr)).
	interpreterProxy failed ifTrue:[^nil].
	rcvrPtr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	argPtr := self cCoerce: (interpreterProxy firstIndexableField: arg) to: 'float *'.
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (self cCoerce: (rcvrPtr at: i) to: 'double') * (self cCoerce: (argPtr at: i) to: 'double').
	].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveMulScalar [
	"Primitive. Add the argument, a scalar value to the receiver, a FloatArray"
	| rcvr rcvrPtr value length |
	<export: true>
	<var: #value type:'double '>
	<var: #rcvrPtr type:'float *'>
	value := interpreterProxy stackFloatValue: 0.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length := interpreterProxy stSizeOf: rcvr.
	rcvrPtr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (self cCoerce: (rcvrPtr at: i) to: 'double') * value.
	].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveNormalize [
	"Primitive. Normalize the argument (A FloatArray) in place."
	<export: true>
	| rcvr rcvrPtr length len |
	<var: #rcvrPtr type: #'float *'>
	<var: #len type: #double>
	rcvr := interpreterProxy stackValue: 0.
	(interpreterProxy isWords: rcvr) ifFalse:
		[interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	length := interpreterProxy stSizeOf: rcvr.
	rcvrPtr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: #'float *'.
	len := 0.0.
	0 to: length-1 do:[:i|
		len := len + ((self cCoerce: (rcvrPtr at: i) to: #double) * (self cCoerce: (rcvrPtr at: i) to: #double)).
	].
	len > 0.0 ifFalse:
		[interpreterProxy primitiveFailFor: PrimErrBadReceiver].

	len := self sqrt: len.
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: ((self cCoerce: (rcvrPtr at: i) to: #double) / len).
	].

	"Leave receiver on the stack."
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveSubFloatArray [
	"Primitive. Add the receiver and the argument, both FloatArrays and store the result into the receiver."
	| rcvr arg rcvrPtr argPtr length |
	<export: true>
	<var: #rcvrPtr type:'float *'>
	<var: #argPtr type:'float *'>
	arg := interpreterProxy stackObjectValue: 0.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: arg).
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length := interpreterProxy stSizeOf: arg.
	interpreterProxy success: (length = (interpreterProxy stSizeOf: rcvr)).
	interpreterProxy failed ifTrue:[^nil].
	rcvrPtr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	argPtr := self cCoerce: (interpreterProxy firstIndexableField: arg) to: 'float *'.
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (self cCoerce: (rcvrPtr at: i) to: 'double') - (self cCoerce: (argPtr at: i) to: 'double').
	].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveSubScalar [
	"Primitive. Add the argument, a scalar value to the receiver, a FloatArray"
	| rcvr rcvrPtr value length |
	<export: true>
	<var: #value type:'double '>
	<var: #rcvrPtr type:'float *'>
	value := interpreterProxy stackFloatValue: 0.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length := interpreterProxy stSizeOf: rcvr.
	rcvrPtr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	0 to: length-1 do:[:i|
		rcvrPtr at: i put: (self cCoerce: (rcvrPtr at: i) to: 'double') - value.
	].
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'arithmetic primitives' }
FloatArrayPlugin >> primitiveSum [
	"Primitive. Find the sum of each float in the receiver, a FloatArray, and stash the result into the argument Float."
	| rcvr rcvrPtr length sum |
	<export: true>
	<var: #sum type:'double '>
	<var: #rcvrPtr type:'float *'>
	rcvr := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy success: (interpreterProxy isWords: rcvr).
	interpreterProxy failed ifTrue:[^nil].
	length := interpreterProxy stSizeOf: rcvr.
	rcvrPtr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'float *'.
	sum := 0.0.
	0 to: length-1 do:[:i|
		sum := sum + (self cCoerce: (rcvrPtr at: i) to: 'double').
	].
	interpreterProxy pop: 1 thenPush: (interpreterProxy floatObjectOf: sum)
]

{ #category : #simulation }
FloatArrayPlugin >> sqrt: aFloat [
	^aFloat sqrt
]
