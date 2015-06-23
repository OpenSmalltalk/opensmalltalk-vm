Class {
	#name : #NSSendCacheSurrogate,
	#superclass : #VMClass,
	#instVars : [
		'address',
		'memory',
		'cogit'
	],
	#category : #'VMMaker-JITSimulation'
}

{ #category : #'as yet unclassified' }
NSSendCacheSurrogate >> at: anAddress objectMemory: objectMemory cogit: aCogit [
	address := anAddress.
	memory := objectMemory memory.
	cogit := aCogit
]
