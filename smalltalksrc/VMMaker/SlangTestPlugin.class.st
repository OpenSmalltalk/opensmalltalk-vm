Class {
	#name : #SlangTestPlugin,
	#superclass : #InterpreterPlugin,
	#category : 'VMMaker-Plugins'
}

{ #category : #primitives }
SlangTestPlugin >> getByteFunctional [
	"Return a byte from a (semi-)functional method"
	<returnTypeC: 'unsigned char'>
	^12345
]

{ #category : #primitives }
SlangTestPlugin >> getByteFunctionalAt: addr [
	"Return a byte from a (semi-)functional method"
	<returnTypeC: 'unsigned char'>
	^interpreterProxy longAt: addr
]

{ #category : #primitives }
SlangTestPlugin >> getByteNonFunctional [
	"Return a byte from a non-functional method"
	<returnTypeC: 'unsigned char'>
	self msg: 'yo'.
	^12345
]

{ #category : #primitives }
SlangTestPlugin >> getByteNonFunctionalAt: addr [
	"Return a byte from a non-functional method"
	<returnTypeC: 'unsigned char'>
	self msg: 'yo'.
	^interpreterProxy longAt: addr
]

{ #category : #primitives }
SlangTestPlugin >> testTypePropagationBasic [
	"Ensure that types are propagated correctly"
	| shouldBeInt |
	<export: true>
	"the resulting byte should be truncated by the functions and expanded back to sqInt"
	shouldBeInt := self getByteNonFunctional.
	interpreterProxy pushBool: shouldBeInt < 256.

]

{ #category : #primitives }
SlangTestPlugin >> testTypePropagationBasicAt [
	"Ensure that types are propagated correctly"
	| buffer shouldBeInt |
	<export: true>
	<var: #buffer declareC: 'sqInt buffer[1] = { 12345 }'>
	"the resulting byte should be truncated by the functions and expanded back to sqInt"
	shouldBeInt := self getByteNonFunctionalAt: buffer.
	interpreterProxy pushBool: shouldBeInt < 256.

]

{ #category : #primitives }
SlangTestPlugin >> testTypePropagationBasicFunctional [
	"Ensure that types are propagated correctly"
	| shouldBeInt |
	<export: true>
	"the resulting byte should be truncated by the functions and expanded back to sqInt"
	shouldBeInt := self getByteFunctional.
	interpreterProxy pushBool: shouldBeInt < 256.

]

{ #category : #primitives }
SlangTestPlugin >> testTypePropagationBasicFunctionalAt [
	"Ensure that types are propagated correctly"
	| buffer shouldBeInt |
	<export: true>
	<var: #buffer declareC: 'sqInt buffer[1] = { 12345 }'>
	"the resulting byte should be truncated by the functions and expanded back to sqInt"
	shouldBeInt := self getByteFunctionalAt: buffer.
	interpreterProxy pushBool: shouldBeInt < 256.

]

{ #category : #primitives }
SlangTestPlugin >> testTypePropagationBasicNoPropagate [
	"Ensure that types are propagated correctly"
	| shouldBeInt |
	<export: true>
	shouldBeInt := self getByteNonFunctional.
	"shoudBeInt should be int, not unsigned char"
	shouldBeInt := 12345.
	interpreterProxy pushBool: shouldBeInt > 256.
]

{ #category : #primitives }
SlangTestPlugin >> testTypePropagationBasicNoPropagateAt [
	"Ensure that types are propagated correctly"
	| buffer shouldBeInt |
	<export: true>
	<var: #buffer declareC: 'sqInt buffer[1] = { 12345 }'>
	shouldBeInt := self getByteNonFunctionalAt: buffer.
	"shoudBeInt should be int, not unsigned char"
	shouldBeInt := 12345.
	interpreterProxy pushBool: shouldBeInt > 256.
]

{ #category : #primitives }
SlangTestPlugin >> testTypePropagationBasicNoPropagateFunctional [
	"Ensure that types are propagated correctly"
	| shouldBeInt |
	<export: true>
	shouldBeInt := self getByteFunctional.
	"shoudBeInt should be int, not unsigned char"
	shouldBeInt := 12345.
	interpreterProxy pushBool: shouldBeInt > 256.
]

{ #category : #primitives }
SlangTestPlugin >> testTypePropagationBasicNoPropagateFunctionalAt [
	"Ensure that types are propagated correctly"
	| buffer shouldBeInt |
	<export: true>
	<var: #buffer declareC: 'sqInt buffer[1] = { 12345 }'>
	shouldBeInt := self getByteFunctionalAt: buffer.
	"shoudBeInt should be int, not unsigned char"
	shouldBeInt := 12345.
	interpreterProxy pushBool: shouldBeInt > 256.
]
