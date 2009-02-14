Extension { #name : #ObjectMemory }

{ #category : #'*SlangBrowser-translation' }
ObjectMemory classSide >> asCString [
	"Answer the translated C source for this class."

	"Interpreter asCString"
	"ObjectMemory asCString"

	| vmm cg stream |
	(Smalltalk hasClassNamed: 'VMMaker')
		ifTrue: [vmm := Smalltalk at: #VMMaker]
		ifFalse: [^ self notify: 'VMMaker not in this image'].
	cg := vmm codeGenerator: #cCode forClass: self.
	stream := ReadWriteStream on: ''.
	cg emitCCodeOn: stream doAssertions: true.
	cg emitExportsOn: stream.
	^ stream contents

]

{ #category : #'*SlangBrowser-translation' }
ObjectMemory classSide >> asCString: aSelector [
	"Answer the translated C source for a method."

	"Interpreter asCString: #bytecodePrimBlockCopy"
	"ObjectMemory asCString: #lastPointerOf:"

	| vmm cg method stream |
	(Smalltalk hasClassNamed: 'VMMaker')
		ifTrue: [vmm := Smalltalk at: #VMMaker]
		ifFalse: [^ self notify: 'VMMaker not in this image'].
	cg := vmm codeGenerator: #cCode forClass: self.
	cg isString ifTrue:
		[^ '/* Simulator subclasses with method overrides should not be translated. */',
			String cr, '/* ', cg, ' */'].
	method := cg methodNamed: aSelector.
	method ifNil: [^ self methodNotTranslatedMessage: aSelector].
	stream := ReadWriteStream on: ''.
	method emitCCodeOn: stream generator: cg.
	^ stream contents

]

{ #category : #'*SlangBrowser-translation' }
ObjectMemory classSide >> asInlinedCString: aSelector [
	"Answer the translated Inlined C source for a method."

	"Interpreter asCString: #bytecodePrimBlockCopy"
	"ObjectMemory asCString: #lastPointerOf:"

	| vmm cg method stream |
	(Smalltalk hasClassNamed: 'VMMaker')
		ifTrue: [vmm := Smalltalk at: #VMMaker]
		ifFalse: [^ self notify: 'VMMaker not in this image'].
	cg := vmm codeGenerator: #inlinedCCode forClass: self.
	cg isString ifTrue:
		[^ '/* Simulator subclasses with method overrides should not be translated. */',
			String cr, '/* ', cg, ' */'].
	method := cg methodNamed: aSelector.
	method ifNil: [^ self methodNotTranslatedMessage: aSelector].
	stream := ReadWriteStream on: ''.
	method emitCCodeOn: stream generator: cg.
	^ stream contents

]

{ #category : #'*SlangBrowser-translation' }
ObjectMemory classSide >> methodNotTranslatedMessage: aSelector [
	"For browser support with VMMaker"

	^ 	'/* No source has been generated for #', aSelector asString, ' */', String cr,
		'/* Method may have been fully inlined, or is not exported and */' translated,
		String cr, '/* has no senders. See senders of #' translated, aSelector asString, ' */'

]
