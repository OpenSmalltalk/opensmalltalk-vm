Class {
	#name : #StackInterpreterTests,
	#superclass : #TestCase,
	#category : #'VMMaker-Tests'
}

{ #category : #tests }
StackInterpreterTests >> testPointerTaggingDetagging [
	"Test the adding/removal of SmallInteger tags to memory adresses used in
	 StackInterpreter and StackInterpreterSimulator for married context management."

	"StackInterpreterTests new testPointerTaggingDetagging"

	{ StackInterpreterSimulatorLSB new. "StackInterpreterSimulatorMSB new" } do: "Need to add MSB soon"
		[:sis|
		({ SmallInteger minVal. SmallInteger minVal / 2. -1024. -4.
		    SmallInteger maxVal - 1. SmallInteger maxVal // 2. 4 } collect:
			[:n| n bitAnd: -4]) do:
				[:n| | tagged untagged |
				self assert: n \\ 4 = 0.
				self assert: (sis isNonIntegerObject: n).
				tagged := sis withSmallIntegerTags: n.
				untagged := sis withoutSmallIntegerTags: tagged.
				self assert: (sis isIntegerObject: tagged).
				self assert: untagged = n]]
]
