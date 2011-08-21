Extension { #name : #Object }

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
Object class >> asCString [
	"Answer the translated C source for this class."

	"Interpreter asCString"
	"ObjectMemory asCString"
	"FilePlugin asCString"

	| vmm cg stream |
	(Smalltalk hasClassNamed: 'VMMaker')
		ifTrue: [vmm := Smalltalk at: #VMMaker]
		ifFalse: [^ self notify: 'VMMaker not in this image'].
	cg := vmm codeGenerator: #cCode forClass: self.
	stream := ReadWriteStream on: ''.
	cg emitCCodeOn: stream doAssertions: true.
	^ stream contents

]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
Object class >> asCString: aSelector [
	"Answer the translated C source for a method."

	"Interpreter asCString: #bytecodePrimBlockCopy"
	"ObjectMemory asCString: #lastPointerOf:"

	| vmm cg method stream |
	(Smalltalk hasClassNamed: 'VMMaker')
		ifTrue: [vmm := Smalltalk at: #VMMaker]
		ifFalse: [^ self notify: 'VMMaker not in this image'].
	cg := vmm codeGenerator: #cCode forClass: self.
	cg isString ifTrue:
		[^ '/* ', self name, ' can not be translated. */',
			String cr, '/* ', cg, ' */'].
	method := cg methodNamed: aSelector.
	method ifNil: [^ self methodNotTranslatedMessage: aSelector].
	stream := ReadWriteStream on: ''.
	method emitCCodeOn: stream generator: cg.
	^ stream contents

]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
Object class >> asInlinedCString [
	"Answer the translated C source for this class."

	"Interpreter asInlinedCString"
	"ObjectMemory asInlinedCString"
	"FilePlugin asInlinedCString"

	| vmm cg stream |
	(Smalltalk hasClassNamed: 'VMMaker')
		ifTrue: [vmm := Smalltalk at: #VMMaker]
		ifFalse: [^ self notify: 'VMMaker not in this image'].
	cg := vmm codeGenerator: #inlinedCCode forClass: self.
	stream := ReadWriteStream on: ''.
	cg emitCCodeOn: stream doAssertions: true.
	^ stream contents

]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
Object class >> asInlinedCString: aSelector [
	"Answer the translated Inlined C source for a method."

	"Interpreter asCString: #bytecodePrimBlockCopy"
	"ObjectMemory asCString: #lastPointerOf:"

	| vmm cg method stream |
	(Smalltalk hasClassNamed: 'VMMaker')
		ifTrue: [vmm := Smalltalk at: #VMMaker]
		ifFalse: [^ self notify: 'VMMaker not in this image'].
	cg := vmm codeGenerator: #inlinedCCode forClass: self.
	cg isString ifTrue:
		[^ '/* ', self name, ' can not be translated. */',
			String cr, '/* ', cg, ' */'].
	method := cg methodNamed: aSelector.
	method ifNil: [^ ObjectMemory methodNotTranslatedMessage: aSelector].
	stream := ReadWriteStream on: ''.
	method emitCCodeOn: stream generator: cg.
	^ stream contents

]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
Object class >> declareCVarsIn: cg [

]

{ #category : #'*SlangBrowser-VMMaker-Translation to C' }
Object class >> requiredMethodNames [
	"return the list of method names that should be retained for export or other support reasons"
	^#()
]
