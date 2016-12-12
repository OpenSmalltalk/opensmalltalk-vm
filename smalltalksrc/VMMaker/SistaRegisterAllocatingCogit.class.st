"
SistaRegisterAllocatingCogit is a port of SistaCogit under RegisterAllocatingCogit.  Its subclass SistaCogitClone holds those methods that are identical to SistaCogit's.  This class holds the methods that are different.  SistaRegisterAllocatingCogit's initialize method keeps things up-to-date and arranges that no method implemented in SistaRegisterAllocatingCogit is implemented in SistaCogitClone so that super sends in SistaCogitClone activate code in RegisterAllocatingCogit as intended.

Instance Variables
	branchReachedOnlyForCounterTrip:		<Object>
	ceTrapTrampoline:		<Object>
	counterIndex:		<Object>
	counters:		<Object>
	initialCounterValue:		<Object>
	numCounters:		<Object>

branchReachedOnlyForCounterTrip
	- xxxxx

ceTrapTrampoline
	- xxxxx

counterIndex
	- xxxxx

counters
	- xxxxx

initialCounterValue
	- xxxxx

numCounters
	- xxxxx

"
Class {
	#name : #SistaRegisterAllocatingCogit,
	#superclass : #RegisterAllocatingCogit,
	#instVars : [
		'numCounters',
		'counters',
		'counterIndex',
		'initialCounterValue',
		'ceTrapTrampoline',
		'branchReachedOnlyForCounterTrip'
	],
	#classVars : [
		'CounterBytes',
		'MaxCounterValue'
	],
	#pools : [
		'VMSqueakClassIndices'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'clone maintennance' }
SistaRegisterAllocatingCogit class >> dateAndTimeFrom: timeStampString [
	^(timeStampString copyFrom: (timeStampString findFirst: [:c| c isDigit]) to: timeStampString size) asDateAndTime
]

{ #category : #'clone maintennance' }
SistaRegisterAllocatingCogit class >> implementation: aMethodReference isDifferentThan: bMethodReference [
	^aMethodReference isValid
	 and: [bMethodReference isValid
			ifTrue: [aMethodReference sourceString ~= bMethodReference sourceString]
			ifFalse: [true]]
]

{ #category : #'class initialization' }
SistaRegisterAllocatingCogit class >> initializeWithOptions: optionsDictionary [

	self syncCodeWithSistaCogit ifTrue: "The subclass's #initializeWithOptions: method changed; resend."
		[^self initializeWithOptions: optionsDictionary].

	"Things are up-to-date; continue"
	^super initializeWithOptions: optionsDictionary
]

{ #category : #'class initialization' }
SistaRegisterAllocatingCogit class >> syncCodeIn: sourceClass with: destClass leavingUnchanged: selectorOrNil [
	"Make sure that the SistaRegisterAllocatingCogit/SistaCogitClone combination is up-to-date w.r.t. SistaCogit.
	 - 	SistaCogitClone should have all methods in SistaCogit except those implemented in SistaRegisterAllocatingCogit.
		This means that super sends in SistaCogitClone will be understood in SistaRegisterAllocatingCogit, not
		SistaRegisterAllocatingCogit.
	 -	newer methods in SistaCogitClone that are implemented in SistaRegisterAllocatingCogit should be moved up to
		SistaRegisterAllocatingCogit becaude it means that we probably changed them in SistaCogitClone by mistake
		and forgot to copy them up.
	 -	the same goes for the class side, except for the intializeWithOptions: method which /should/ exist in both
		SistaRegisterAllocatingCogit and SistaCogitClone, because it runs this initialization."

	| methodTimeStamp |
	methodTimeStamp := selectorOrNil ifNotNil:
					[(destClass superclass >>> selectorOrNil) isValid ifTrue:
						[(destClass >>> selectorOrNil) isValid
							ifTrue: [(destClass >>> selectorOrNil) timeStamp]
							ifFalse: ['ancient 01/01/1901 00:00']]].

	destClass selectorsDo:
		[:s|
		(s ~~ selectorOrNil
		 and: [(destClass superclass >>> s) isValid
		 and: [self implementation: destClass >>> s isNewerThan: destClass superclass >>> s]]) ifTrue:
			[destClass superclass recompile: s from: destClass.
			 (destClass superclass whichCategoryIncludesSelector: s) ~= (destClass whichCategoryIncludesSelector: s) ifTrue:
				[destClass superclass organization classify: s under: (destClass whichCategoryIncludesSelector: s)]]].

	sourceClass selectorsDo:
		[:s|
		(self implementation: sourceClass >>> s isDifferentThan: destClass >>> s) ifTrue:
			[destClass recompile: s from: sourceClass.
			 (destClass whichCategoryIncludesSelector: s) ~= (sourceClass whichCategoryIncludesSelector: s) ifTrue:
				[destClass organization classify: s under: (sourceClass whichCategoryIncludesSelector: s)]]].


	destClass superclass selectorsDo:
		[:s|
		(s ~~ selectorOrNil
		 and: [(destClass >>> s) isValid]) ifTrue:
			[destClass removeSelector: s]].

	^methodTimeStamp notNil
	  and: [(destClass >>> selectorOrNil) isValid
	  and: [(methodTimeStamp beginsWith: 'ancient')
		or: [(self dateAndTimeFrom: (destClass >>> selectorOrNil) timeStamp) ~= (self dateAndTimeFrom: methodTimeStamp)]]]
]

{ #category : #'class initialization' }
SistaRegisterAllocatingCogit class >> syncCodeWithSistaCogit [
	"Make sure that the SistaRegisterAllocatingCogit/SistaCogitClone combination is up-to-date w.r.t. SistaCogit.
	 - 	SistaCogitClone should have all methods in SistaCogit except those implemented in SistaRegisterAllocatingCogit.
		This means that super sends in SistaCogitClone will be understood in SistaRegisterAllocatingCogit, not
		SistaRegisterAllocatingCogit.
	 -	newer methods in SistaCogitClone that are implemented in SistaRegisterAllocatingCogit should be moved up to
		SistaRegisterAllocatingCogit becaude it means that we probably changed them in SistaCogitClone by mistake
		and forgot to copy them up.
	 -	the same goes for the class side, except for the intializeWithOptions: method which /should/ exist in both
		SistaRegisterAllocatingCogit and SistaCogitClone, because it runs this initialization."
	| syncAction |
	syncAction :=
		[self syncCodeIn: SistaCogit with: SistaCogitClone leavingUnchanged: nil.
		 self syncCodeIn: SistaCogit class with: SistaCogitClone class leavingUnchanged: #initializeWithOptions:].
	^(Smalltalk classNamed: #CurrentReadOnlySourceFiles)
		ifNil: syncAction
		ifNotNil: [:crosf| crosf cacheDuring: syncAction]
]
