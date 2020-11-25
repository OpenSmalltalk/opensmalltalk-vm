Extension { #name : #EncoderForV3 }

{ #category : #'*Cog-instruction stream support' }
EncoderForV3 class >> isBranchAt: pc in: method [
	"Answer whether the bytecode at pc is a conditional branch."

	"152-159 	10011iii 		Pop and Jump 0n False iii +1 (i.e., 1 through 8)
	 168-171 	101010ii jjjjjjjj 	Pop and Jump On True ii *256+jjjjjjjj
	 172-175 	101011ii jjjjjjjj 	Pop and Jump On False ii *256+jjjjjjjj"
	| bytecode |
	bytecode := method at: pc.
	^bytecode >= 152
	 and: [bytecode <= 159
			or: [bytecode >= 168 and: [bytecode <= 175]]]
]
