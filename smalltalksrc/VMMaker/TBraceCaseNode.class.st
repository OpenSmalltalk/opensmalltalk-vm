Class {
	#name : #TBraceCaseNode,
	#superclass : #TParseNode,
	#instVars : [
		'caseLabels',
		'cases'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #transformations }
TBraceCaseNode >> bindVariableUsesIn: aDictionary [

	caseLabels := caseLabels collect: [:node| node bindVariableUsesIn: aDictionary].
	cases := cases collect: [:node| node bindVariableUsesIn: aDictionary]
]

{ #category : #transformations }
TBraceCaseNode >> bindVariablesIn: aDictionary [

	caseLabels := caseLabels collect: [:node| node bindVariablesIn: aDictionary].
	cases := cases collect: [:node| node bindVariablesIn: aDictionary]
]

{ #category : #accessing }
TBraceCaseNode >> caseLabels [
	"Answer the value of caseLabels"

	^ caseLabels
]

{ #category : #accessing }
TBraceCaseNode >> caseLabels: anObject [
	"Set the value of caseLabels"

	caseLabels := anObject
]

{ #category : #accessing }
TBraceCaseNode >> cases [
	"Answer the value of cases"

	^ cases
]

{ #category : #accessing }
TBraceCaseNode >> cases: anObject [
	"Set the value of cases"

	cases := anObject
]

{ #category : #enumerating }
TBraceCaseNode >> nodesDo: aBlock [
	caseLabels do:
		[:node| node nodesDo: aBlock].
	cases do:
		[:node| node nodesDo: aBlock].
	aBlock value: self
]

{ #category : #enumerating }
TBraceCaseNode >> nodesDo: aBlock unless: cautionaryBlock [

	(cautionaryBlock value: self) ifTrue: [^self].
	caseLabels do:
		[:node| node nodesDo: aBlock unless: cautionaryBlock].
	cases do:
		[:node| node nodesDo: aBlock unless: cautionaryBlock].
	aBlock value: self
]

{ #category : #enumerating }
TBraceCaseNode >> replaceNodesIn: aDictionary [

	^aDictionary at: self ifAbsent: [
		caseLabels := caseLabels collect: [:node| node replaceNodesIn: aDictionary].
		cases := cases collect: [:node| node replaceNodesIn: aDictionary].
		self]
]
