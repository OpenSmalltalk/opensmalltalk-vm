Extension { #name : #PrintfNumberFormatDescriptor }

{ #category : #'*VMMaker-C code generation' }
PrintfNumberFormatDescriptor >> transformForVMMaker [
	('duxX' includes: operator) ifFalse:
		[^super transformForVMMaker].
	^'%" PRI', (String with: operator), 'SQINT "'
]
