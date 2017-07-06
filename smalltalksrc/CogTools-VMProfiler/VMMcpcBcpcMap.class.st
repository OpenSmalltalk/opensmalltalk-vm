"
My instances represent the mapping between mcpc (machine code program counter) to bcpc (bytecode program counter) for a given compiled code. 

map is an orderedCollection, each element being an association, the key being the range in the bytecode, the value the number of samples within that range.
"
Class {
	#name : #VMMcpcBcpcMap,
	#superclass : #Object,
	#instVars : [
		'map'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #accessing }
VMMcpcBcpcMap >> addRange: range numSamples: numSamples [
	map add: (range key + 1 -> (range value + 1)) -> numSamples
]

{ #category : #iterating }
VMMcpcBcpcMap >> bcRangeAndNumSamplesDo: binaryBlock [
	map do: [ :assoc |
		binaryBlock
			value: assoc key 
			value: assoc value ]
]

{ #category : #initialization }
VMMcpcBcpcMap >> initialize [

	super initialize.

	map := OrderedCollection new.
]

{ #category : #printing }
VMMcpcBcpcMap >> printOn: s [
	s << 'McpcBcpcMap ('.
	map do: 
		[ :assoc |
			s 
				<< '['
				<< assoc key key printString 
				<< ';'
				<< assoc key value printString
				<< ']>'
				<< assoc value printString 
				<< ' ' ].
	s << ')'
]
