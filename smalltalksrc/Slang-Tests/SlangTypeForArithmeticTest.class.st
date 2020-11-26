Class {
	#name : #SlangTypeForArithmeticTest,
	#superclass : #SlangAbstractTestCase,
	#instVars : [
		'visitor',
		'propertyName'
	],
	#category : #'Slang-Tests'
}

{ #category : #running }
SlangTypeForArithmeticTest >> setUp [
	super setUp.
	ccg addClass: SlangTypeForDereferenceTestClass

]

{ #category : #tests }
SlangTypeForArithmeticTest >> testAtOnMatrix [
	| tMethod |
	tMethod := ccg methodNamed: #aMethodReturningAnAtOnAMatrix.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first expression in: tMethod) equals: #sqInt."at: node"
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt."returnNode"
	self assert: tMethod returnType equals: #sqInt. " euuu, looks weird. Did i do something wrong?"
]
