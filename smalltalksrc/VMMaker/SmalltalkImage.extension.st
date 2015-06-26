Extension { #name : #SmalltalkImage }

{ #category : #'*VMMaker-Interpreter' }
SmalltalkImage >> simulatePrimitive: aPrimitive args: args [ 
	"simulate primitives in RSqueak"
	"IMAGE_NAME"
	aPrimitive = 121
		ifTrue: [^ self getSystemAttribute: 1].
	"SNAPSHOT"
	aPrimitive = 97
		ifTrue: [Smalltalk
				at: #SystemTracer2
				ifPresent: [:st | ^ st writeImage: Smalltalk imageName]].
	"SNAPSHOT_EMBEDDED"
	aPrimitive = 247
		ifTrue: [Smalltalk
				at: #SystemTracer2
				ifPresent: [:st | ^ st writeImage: Smalltalk imageName]].
	^ InterpreterProxy new primitiveFailFor: 255

]
