Class {
	#name : #CogMIPSELCompilerForTests,
	#superclass : #CogMIPSELCompiler,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #'as yet unclassified' }
CogMIPSELCompilerForTests class >> dataRegistersWithAccessorsDo: aTrinaryBlock [
	#((16 s0 s0:)
		(17 s1 s1:)
		(18 s2 s2:)
		(19 s3 s3:)
		(20 s4 s4:)
		(21 s5 s5:)
		(22 s6 s6:)
		(29 sp sp:)
		(30 fp fp:)
		(31 ra ra:)) do: [:triple | aTrinaryBlock valueWithArguments: triple].
]

{ #category : #'as yet unclassified' }
CogMIPSELCompilerForTests class >> isRISCTempRegister: reg [
	"For tests to filter-out bogus values left in the RISCTempRegister, if any."
	^reg = AT
		or: [reg = Cmp
		or: [reg = Overflow
		or: [reg = BranchTemp]]]
]
