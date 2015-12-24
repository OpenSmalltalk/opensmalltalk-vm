Extension { #name : #Array }

{ #category : #'*VMMaker-interpreter simulator' }
Array >> addBreakpoint: address [
	^self, {address}
]

{ #category : #'*VMMaker-plugin generation' }
Array class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg 
		ccgLoad: aBlock 
		expr: aString 
		asOopPtrFrom: anInteger
		andThen: (cg ccgValBlock: 'isIndexable')
]

{ #category : #'*VMMaker-plugin generation' }
Array class >> ccgDeclareCForVar: aSymbolOrString [

	^'sqInt *', aSymbolOrString
]

{ #category : #'*VMMaker-interpreter simulator' }
Array >> coerceTo: cTypeString sim: interpreterSimulator [

	^ self
]

{ #category : #'*VMMaker-interpreter simulator' }
Array >> isActiveBreakpoint [
	^self size > 0
]

{ #category : #'*VMMaker-interpreter simulator' }
Array >> isBreakpointFor: address [
	1 to: self size do:
		[:i| (self at: i) = address ifTrue: [^true]].
	^false
]

{ #category : #'*VMMaker-interpreter simulator' }
Array >> menuPrompt [
	^String streamContents:
		[:s|
		s space; nextPut: $(.
		self do: [:address| s nextPutAll: address hex]
			separatedBy: [s space].
		s nextPut: $)]
]

{ #category : #'*VMMaker-interpreter simulator' }
Array >> removeBreakpoint: address [
	^(self copyWithout: address) ifEmpty: nil
]

{ #category : #'*VMMaker-interpreter simulator' }
Array >> singleStepRequiredToTriggerIn: aCogit [
	^self anySatisfy: [:address| address between: aCogit cogCodeBase and: aCogit methodZone limitZony]
]
