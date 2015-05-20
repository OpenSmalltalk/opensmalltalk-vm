Extension { #name : #String }

{ #category : #'*VMMaker-plugin generation' }
String class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg 
		ccgLoad: aBlock 
		expr: aString 
		asCharPtrFrom: anInteger
		andThen: (cg ccgValBlock: 'isBytes')
]

{ #category : #'*VMMaker-plugin generation' }
String class >> ccgDeclareCForVar: aSymbolOrString [

	^'char *', aSymbolOrString
]

{ #category : #'*VMMaker-translation support' }
String >> indexOfWord: aSubString [
	^self indexOfWord: aSubString startingAt: 1
]

{ #category : #'*VMMaker-translation support' }
String >> indexOfWord: aSubString startingAt: startIndex [
	| index |
	index := startIndex.
	[index <= self size] whileTrue:
		[index := self indexOfSubCollection: aSubString startingAt: index ifAbsent: [^0].
		 ((index = 1 or: [(self at: index - 1) isLetter not])
		  and: [index + aSubString size > self size
				or: [(self at: index + aSubString size) isAlphaNumeric not]]) ifTrue:
			[^index].
		 index := index + 1].
	^0
]
