Extension { #name : #InterpreterPlugin }

{ #category : #'*SlangBrowser-translation' }
InterpreterPlugin classSide >> asCString [
	"Answer the translated C source for this class."

	"FilePlugin asCString"

	| cg stream vmm |
	(Smalltalk hasClassNamed: 'VMMaker')
		ifTrue: [vmm := Smalltalk at: #VMMaker]
		ifFalse: [^ self notify: 'VMMaker not in this image' translated].
	cg := vmm codeGenerator: #cCode forClass: self.
	stream := ReadWriteStream on: ''.
	cg emitCCodeOn: stream doAssertions: true.
	^ stream contents

]

{ #category : #'*SlangBrowser-translation' }
InterpreterPlugin classSide >> asCString: aSelector [
	"Answer the translated C source for a method."

	| cg stream method vmm |
	(Smalltalk hasClassNamed: 'VMMaker')
		ifTrue: [vmm := Smalltalk at: #VMMaker]
		ifFalse: [^ self notify: 'VMMaker not in this image' translated].
	cg := vmm codeGenerator: #cCode forClass: self.
	cg isString ifTrue:
		[^ '/* Simulator subclasses with method overrides should not be translated. */',
			String cr, '/* ', cg, ' */'].
	method := cg methodNamed: aSelector.
	method ifNil: [^ ObjectMemory methodNotTranslatedMessage: aSelector].
	stream := ReadWriteStream on: ''.
	method emitCCodeOn: stream generator: cg.
	^ stream contents

]

{ #category : #'*SlangBrowser-translation' }
InterpreterPlugin classSide >> asInlinedCString: aSelector [
	"Answer the translated inlined C source for a method."

	| cg stream method vmm |
	(Smalltalk hasClassNamed: 'VMMaker')
		ifTrue: [vmm := Smalltalk at: #VMMaker]
		ifFalse: [^ self notify: 'VMMaker not in this image' translated].
	cg := vmm codeGenerator: #inlinedCCode forClass: self.
	cg isString ifTrue:
		[^ '/* Simulator subclasses with method overrides should not be translated. */',
			String cr, '/* ', cg, ' */'].
	method := cg methodNamed: aSelector.
	method ifNil: [^ ObjectMemory methodNotTranslatedMessage: aSelector].
	stream := ReadWriteStream on: ''.
	method emitCCodeOn: stream generator: cg.
	^ stream contents

]
