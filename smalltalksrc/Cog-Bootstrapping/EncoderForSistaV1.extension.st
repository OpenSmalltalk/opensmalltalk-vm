Extension { #name : #EncoderForSistaV1 }

{ #category : #'*Cog-instruction stream support' }
EncoderForSistaV1 class >> isBranchAt: pc in: method [
	"Answer whether the bytecode at pc is a conditional branch."

	"	184-191	10111 iii				Pop and Jump 0n True iii +1 (i.e., 1 through 8)
		192-199	11000 iii				Pop and Jump 0n False iii +1 (i.e., 1 through 8)
	 *	238		11101110	iiiiiiii		Pop and Jump 0n True #iiiiiiii (+ Extend B * 256, where Extend B >= 0))
	 *	239		11101111	iiiiiiii		Pop and Jump 0n False #iiiiiiii (+ Extend B * 256, where Extend B >= 0)"
	| byte |
	byte := self nonExtensionBytecodeAt: pc in: method.
	^byte >= 184 and: [byte <= 199 or: [byte >= 238 and: [byte <= 239]]]
]
