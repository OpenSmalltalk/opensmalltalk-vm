"
A test plugin to exercise imbalanced stack access.
"
Class {
	#name : #BrokenPlugin,
	#superclass : #InterpreterPlugin,
	#category : 'VMMaker-Plugins'
}

{ #category : #tests }
BrokenPlugin class >> testNoPopButPush [
	"BrokenPlugin testNoPopButPush"
	<primitive: 'primitiveNoPopButPush' module: 'BrokenPlugin'>

]

{ #category : #tests }
BrokenPlugin class >> testPopAndFail [
	"BrokenPlugin testPopAndFail"
	<primitive: 'primitivePopAndFail' module: 'BrokenPlugin'>

]

{ #category : #tests }
BrokenPlugin class >> testPopLessThanExpected: arg1 with: arg2 [
	"BrokenPlugin testPopLessThanExpected: 3 with: 4"
	<primitive: 'primitivePopLessThanExpected' module: 'BrokenPlugin'>

]

{ #category : #tests }
BrokenPlugin class >> testPopMoreThanExpected [
	"BrokenPlugin testPopMoreThanExpected"
	<primitive: 'primitivePopMoreThanExpected' module: 'BrokenPlugin'>

]

{ #category : #primitives }
BrokenPlugin >> primitiveNoPopButPush [
	"Doesn't pop anything but pushes return value"
	<export: true>
	interpreterProxy pushBool: true.
]

{ #category : #primitives }
BrokenPlugin >> primitivePopAndFail [
	"Pops in a failing primitive"
	<export: true>
	interpreterProxy pop: interpreterProxy methodArgumentCount + 1.
	interpreterProxy primitiveFail.
]

{ #category : #primitives }
BrokenPlugin >> primitivePopLessThanExpected [
	"Pops less than expected; call this with two arguments."
	<export: true>
	interpreterProxy pop: interpreterProxy methodArgumentCount - 1.

]

{ #category : #primitives }
BrokenPlugin >> primitivePopMoreThanExpected [
	"Pops more than expected"
	<export: true>
	interpreterProxy pop: interpreterProxy methodArgumentCount + 4.

]
