Extension { #name : #BitBlt }

{ #category : #'*VMMaker-Interpreter' }
BitBlt >> simulatePrimitive: aString args: args [ 
	"simulate primitives in RSqueak"
	aString = 'primitiveCopyBits'
		ifTrue: [
			args size = 1
				ifTrue: [^ self copyBitsSimulated: (args at: 1)]
				ifFalse: [^ self copyBitsSimulated]].
	aString = 'primitiveWarpBits'
		ifTrue: [^ self
				warpBitsSimulated: (args at: 1)
				sourceMap: (args at: 2)].
	^ InterpreterProxy new primitiveFailFor: 255

]
