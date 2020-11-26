Extension { #name : #ByteSymbol }

{ #category : #'*VMMakerTests' }
ByteSymbol >> forMemory: aMemory [ 

	| vmString instSpec numSlots |

	numSlots := self size + (aMemory wordSize - 1) // aMemory wordSize.
	instSpec := aMemory firstByteFormat + (aMemory wordSize - self size bitAnd: (aMemory wordSize - 1)).
	
	vmString := aMemory
			allocateSlotsInOldSpace: numSlots
			format: instSpec
			classIndex: self class hash.
	
	vmString ifNil: [ self error: 'Could not allocate object, not enough space' ].

	aMemory fillObj: vmString numSlots: numSlots with: aMemory nilObject.

	self
		doWithIndex: [ :char :index | 
			aMemory
				storeByte: index - 1
				ofObject: vmString
				withValue: char asInteger ].

	^ vmString
]
