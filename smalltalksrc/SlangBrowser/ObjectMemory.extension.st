Extension { #name : #ObjectMemory }

{ #category : #'*SlangBrowser-translation' }
ObjectMemory classSide >> methodNotTranslatedMessage: aSelector [
	"For browser support with VMMaker"

	^ 	'/* No source has been generated for #', aSelector asString, ' */', String cr,
		'/* Method may have been fully inlined, or is not exported and */' translated,
		String cr, '/* has no senders. See senders of #' translated, aSelector asString, ' */'

]
