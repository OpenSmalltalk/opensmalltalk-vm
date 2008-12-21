Extension { #name : #Object }

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
Object class >> asCString: aSelector [
	"Answer the translated C source for a method."

	^ 'Translation to C not available for #' translated, aSelector asString, ', see implementors of ' translated, '#asCString:.'
]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
Object class >> asInlinedCString: aSelector [
	"Answer the translated inlined C source for a method."

	^ 'Translation to C not available for #' translated, aSelector asString, ', see implementors of ' translated, '#asCString:.'
]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
Object class >> hasCCodeGenerator [

	^ true
]
