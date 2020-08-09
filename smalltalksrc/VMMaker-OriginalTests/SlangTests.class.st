Class {
	#name : #SlangTests,
	#superclass : #TestCase,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #tests }
SlangTests >> testSimpleMethod [
	| codeGenerator tMethod code |
	codeGenerator := CCodeGenerator new.
	tMethod := codeGenerator compileToTMethodSelector: #extBBytecode in: StackInterpreter.
	self assert: #(	#'['
					byte #':=' self fetchByte #'.'
					self fetchNextBytecode #'.'
					extB #':=' #(numExtB #= 0 and: #'[' byte #> 127 #']')
									ifTrue: #'[' byte #- 256 #']'
									ifFalse: #'[' #(extB bitShift: 8) #+ byte #']' #'.'
					numExtB #':=' numExtB #+ 1 #'.'
					#'^' self
					#']')
		equals: (Scanner new scanTokens: tMethod parseTree printString).
	code := String streamContents: [:s| tMethod emitCCodeOn: s generator: codeGenerator].
	code := code allButFirst: (code indexOfSubCollection: 'sqInt') - 1.
	self assert:  #('sqInt' 'extBBytecode(void)' '{' 'sqInt' 'byte;'
					'byte' '=' 'fetchByte();'
					'fetchNextBytecode();'
					'extB' '=' '((numExtB' '==' '0)' '&&' '(byte' '>' '0x7F)'
						'?' 'byte' '-' '256'
						':' '(((usqInt)' 'extB' '<<' '8))' '+' 'byte);'
					'numExtB' '+=' '1;' 'return' 'self;' '}')
		equals: (code findTokens: Character separators) asArray 
]

{ #category : #tests }
SlangTests >> testStatementsHaveNoArguments [
	"The inliner expects the body of a TMethod to have no arguments."

	| tMethod |
	tMethod := InterpreterStackPages>>#pageIndexFor: asTranslationMethodOfClass: TMethod.
	self assert: (tMethod parseTree args isNil or: [tMethod parseTree args isEmpty])
]
