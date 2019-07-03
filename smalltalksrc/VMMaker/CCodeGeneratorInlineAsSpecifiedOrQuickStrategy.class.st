Class {
	#name : #CCodeGeneratorInlineAsSpecifiedOrQuickStrategy,
	#superclass : #CCodeGeneratorInlineAsSpecifiedStrategy,
	#category : #'VMMaker-Translation to C'
}

{ #category : #accessing }
CCodeGeneratorInlineAsSpecifiedOrQuickStrategy >> inlineFlagOrSymbol [
	
	^ #asSpecifiedOrQuick
]

{ #category : #testing }
CCodeGeneratorInlineAsSpecifiedOrQuickStrategy >> isQuickCompiledMethod: aCompiledMethod [

	^aCompiledMethod isQuick
	 or: [(#(pushConstant: pushLiteralVariable:) includes: (aCompiledMethod abstractBytecodeMessageAt: aCompiledMethod initialPC) selector)
		and: [(aCompiledMethod abstractBytecodeMessageAt: (InstructionStream on: aCompiledMethod) followingPc) selector == #methodReturnTop]]
]

{ #category : #asserting }
CCodeGeneratorInlineAsSpecifiedOrQuickStrategy >> shouldInlineMethod: aMethod [

	^ (super shouldInlineMethod: aMethod)
		or: [ self isQuickCompiledMethod: aMethod compiledMethod ]
]
