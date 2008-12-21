Extension { #name : #Behavior }

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
Behavior >> asCString: aSelector [
	"Answer the translated C source for a method."

	^ 'Class methods are not translated to C.' translated
]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
Behavior >> asInlinedCString: aSelector [
	"Answer the translated C source for a method."

	^ 'Class methods are not translated to C.' translated
]
