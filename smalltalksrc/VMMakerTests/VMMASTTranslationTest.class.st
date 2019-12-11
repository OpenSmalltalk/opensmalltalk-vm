Class {
	#name : #VMMASTTranslationTest,
	#superclass : #TestCase,
	#category : #VMMakerTests
}

{ #category : #'generation-targets' }
VMMASTTranslationTest >> + arg [
]

{ #category : #'generation-targets' }
VMMASTTranslationTest >> emptyBlockHasSingleNilStatement [

	[  ] value
]

{ #category : #'generation-targets' }
VMMASTTranslationTest >> inlineMethodWithLoop [

	self methodWithLoop
]

{ #category : #'generation-targets' }
VMMASTTranslationTest >> inlineSecondLevelMethodWithLoop [

	self inlineMethodWithLoop
]

{ #category : #'generation-targets' }
VMMASTTranslationTest >> inlineTwiceMethodWithLoop [

	self methodWithLoop.
	self methodWithLoop
]

{ #category : #'generation-targets' }
VMMASTTranslationTest >> inlineTwiceSecondLevelMethodWithLoop [

	self inlineMethodWithLoop.
	self inlineMethodWithLoop
]

{ #category : #'generation-targets' }
VMMASTTranslationTest >> methodWithArgument: anArgument [
]

{ #category : #'generation-targets' }
VMMASTTranslationTest >> methodWithExpressionInLoopCondition [

	1 to: self something - 10 do: [ :i | self foo: i ]
]

{ #category : #'generation-targets' }
VMMASTTranslationTest >> methodWithIfNil [

	self something
		ifNil: [ 1 ]
		ifNotNil: [ 2 ]
]

{ #category : #'generation-targets' }
VMMASTTranslationTest >> methodWithIfNilIfNotNil [

	self something
		ifNil: [ 1 ]
		ifNotNil: [ 2 ]

]

{ #category : #'generation-targets' }
VMMASTTranslationTest >> methodWithIfNilIfNotNilWithArgument [

	self something
		ifNil: [ ]
		ifNotNil: [ :soSomething | self lala: soSomething ]
]

{ #category : #'generation-targets' }
VMMASTTranslationTest >> methodWithIfNotNilIfNil [

	self something
		ifNotNil: [ 1 ]
		ifNil: [ 2 ]
]

{ #category : #'generation-targets' }
VMMASTTranslationTest >> methodWithIfNotNilIfNilWithArgument [

	self something
		ifNotNil: [ :soSomething | self lala: soSomething ]
		ifNil: [ ]
]

{ #category : #'generation-targets' }
VMMASTTranslationTest >> methodWithIfNotNilWithArgument [

	self something ifNotNil: [ :soSomething |
		self lala: soSomething ]
]

{ #category : #'generation-targets' }
VMMASTTranslationTest >> methodWithLoop [

	1 to: 10 do: [ :i | self foo: i ]
]

{ #category : #'generation-targets' }
VMMASTTranslationTest >> methodWithNoArguments [
]

{ #category : #tests }
VMMASTTranslationTest >> testArgumentIsNoTemp [

	| translation method |
	method := (self class >> #methodWithArgument:).
	translation := method asTranslationMethodOfClass: TMethod.
	
	self deny: (translation locals includes: method methodNode arguments first name)
]

{ #category : #tests }
VMMASTTranslationTest >> testComplexIfNilIfNotNilWithArgument [

	| translation method codeGenerator assignment conditional condition |
	method := (self class >> #methodWithIfNilIfNotNilWithArgument).
	translation := method asTranslationMethodOfClass: TMethod.
	codeGenerator := CCodeGeneratorGlobalStructure new.
	codeGenerator addMethod: translation.
	codeGenerator doInlining: true.

	self assert: translation parseTree statements size equals: 3.
	assignment := translation parseTree statements first.
	self assert: assignment expression isSend.
	self assert: assignment expression receiver name equals: 'self'.
	self assert: assignment expression selector equals: #something.
	self assert: assignment isAssignment.
	
	conditional := translation parseTree statements second.
	self assert: conditional isSend.
	self assert: conditional selector equals: #ifTrue:ifFalse:.
	self assert: conditional args first isStmtList.
	self assert: conditional args second isStmtList.
	self assert: conditional args first args isEmpty.
	self assert: conditional args second args notEmpty.
	
	condition := conditional receiver.
	self assert: condition isSend.
	self assert: condition selector equals: #==.
	self assert: condition receiver name equals: conditional args second args first.
	self assert: condition args first name equals: 'nil'.
]

{ #category : #tests }
VMMASTTranslationTest >> testComplexIfNotNilIfNilWithArgument [

	| translation method codeGenerator assignment conditional condition |
	method := (self class >> #methodWithIfNilIfNotNilWithArgument).
	translation := method asTranslationMethodOfClass: TMethod.
	codeGenerator := CCodeGeneratorGlobalStructure new.
	codeGenerator addMethod: translation.
	codeGenerator doInlining: true.

	self assert: translation parseTree statements size equals: 3.
	assignment := translation parseTree statements first.
	self assert: assignment expression isSend.
	self assert: assignment expression receiver name equals: 'self'.
	self assert: assignment expression selector equals: #something.
	self assert: assignment isAssignment.
	
	conditional := translation parseTree statements second.
	self assert: conditional isSend.
	self assert: conditional selector equals: #ifTrue:ifFalse:.
	self assert: conditional args first isStmtList.
	self assert: conditional args second isStmtList.
	self assert: conditional args first args isEmpty.
	self assert: conditional args second args notEmpty.
	
	condition := conditional receiver.
	self assert: condition isSend.
	self assert: condition selector equals: #==.
	self assert: condition receiver name equals: conditional args second args first.
	self assert: condition args first name equals: 'nil'.
]

{ #category : #tests }
VMMASTTranslationTest >> testComplexIfNotNilWithArgument [

	| translation method codeGenerator assignment conditional condition |
	method := (self class >> #methodWithIfNotNilWithArgument).
	translation := method asTranslationMethodOfClass: TMethod.
	codeGenerator := CCodeGeneratorGlobalStructure new.
	codeGenerator addMethod: translation.
	codeGenerator doInlining: true.

	self assert: translation parseTree statements size equals: 3.
	assignment := translation parseTree statements first.
	self assert: assignment isAssignment.
	
	conditional := translation parseTree statements second.
	self assert: conditional isSend.
	self assert: conditional selector equals: #ifFalse:.
	self assert: conditional args first isStmtList.
	self assert: conditional args first args notEmpty.
	
	condition := conditional receiver.
	self assert: condition isSend.
	self assert: condition selector equals: #==.
	self assert: condition receiver name equals: conditional args first args first.
	self assert: condition args first name equals: 'nil'.
]

{ #category : #tests }
VMMASTTranslationTest >> testEmptyBlockGeneratesSingleNilStatement [

	| translation method codeGenerator block |
	method := (self class >> #emptyBlockHasSingleNilStatement).
	translation := method asTranslationMethodOfClass: TMethod.
	
	codeGenerator := CCodeGeneratorGlobalStructure new.
	codeGenerator addMethod: translation.
	codeGenerator doInlining: true.

	block := translation statements first receiver.
	self assert: block statements size equals: 1.
	self assert: block statements first name equals: 'nil'
]

{ #category : #tests }
VMMASTTranslationTest >> testIfNilIfNotNilBecomesIfTrueIfFalse [

	| translation |
	translation := (self class >> #methodWithIfNil) asTranslationMethodOfClass: TMethod.
	
	self assert: translation statements first selector equals: #ifTrue:ifFalse:
]

{ #category : #tests }
VMMASTTranslationTest >> testIfNilIfNotNilDoesNotInvertBlocks [

	| translation |
	translation := (self class >> #methodWithIfNilIfNotNil) asTranslationMethodOfClass: TMethod.
	
	self assert: translation statements first selector equals: #ifTrue:ifFalse:.
	self assert: translation statements first args first statements first value equals: 1.
	self assert: translation statements first args second statements first value equals: 2.
]

{ #category : #tests }
VMMASTTranslationTest >> testIfNotNilIfNilInversesBlocks [

	| translation |
	translation := (self class >> #methodWithIfNotNilIfNil) asTranslationMethodOfClass: TMethod.
	
	self assert: translation statements first selector equals: #ifTrue:ifFalse:.
	self assert: translation statements first args first statements first value equals: 2.
	self assert: translation statements first args second statements first value equals: 1
]

{ #category : #tests }
VMMASTTranslationTest >> testInlineMethodWithLoopDeclaresLoopIndexVariable [

	| translation codeGenerator inlinedMethod |
	translation := (self class >> #inlineMethodWithLoop) asTranslationMethodOfClass: TMethod.
	inlinedMethod := ((self class >> #methodWithLoop) asTranslationMethodOfClass: TMethod).
	
	codeGenerator := CCodeGeneratorGlobalStructure new.
	codeGenerator addMethod: translation.
	codeGenerator addMethod: inlinedMethod.
	codeGenerator doInlining: true.

	self assert: (translation locals includesAll: inlinedMethod locals)
]

{ #category : #tests }
VMMASTTranslationTest >> testInlineSecondLevelMethodWithLoopDeclaresLoopIndexVariable [

	| translation codeGenerator inlinedMethods |
	translation := (self class >> #inlineSecondLevelMethodWithLoop) asTranslationMethodOfClass: TMethod.
	inlinedMethods := #( inlineMethodWithLoop methodWithLoop ) collect: [ :s | ((self class >> s) asTranslationMethodOfClass: TMethod)].
	
	codeGenerator := CCodeGeneratorGlobalStructure new.
	codeGenerator addMethod: translation.
	inlinedMethods do: [ :e |
		codeGenerator addMethod: e ].
	codeGenerator doInlining: true.

	self assert: translation locals size equals: 1
]

{ #category : #tests }
VMMASTTranslationTest >> testInlineTwiceMethodWithLoopDeclaresTwiceLoopIndexVariable [

	| translation codeGenerator inlinedMethod |
	translation := (self class >> #inlineTwiceMethodWithLoop) asTranslationMethodOfClass: TMethod.
	inlinedMethod := ((self class >> #methodWithLoop) asTranslationMethodOfClass: TMethod).
	
	codeGenerator := CCodeGeneratorGlobalStructure new.
	codeGenerator addMethod: translation.
	codeGenerator addMethod: inlinedMethod.
	codeGenerator doInlining: true.

	self assert: translation locals size equals: 2
]

{ #category : #tests }
VMMASTTranslationTest >> testInlineTwiceSecondLevelMethodWithLoopDeclaresLoopIndexVariable [

	| translation codeGenerator inlinedMethods |
	translation := (self class >> #inlineTwiceSecondLevelMethodWithLoop) asTranslationMethodOfClass: TMethod.
	inlinedMethods := #( inlineMethodWithLoop methodWithLoop ) collect: [ :s | ((self class >> s) asTranslationMethodOfClass: TMethod)].
	
	codeGenerator := CCodeGeneratorGlobalStructure new.
	codeGenerator addMethod: translation.
	inlinedMethods do: [ :e |
		codeGenerator addMethod: e ].
	codeGenerator doInlining: true.

	self assert: translation locals size equals: 2
]

{ #category : #tests }
VMMASTTranslationTest >> testKeywordMethodHasArgument [

	| translation method |
	method := self class >> #methodWithArgument:.
	translation := method asTranslationMethodOfClass: TMethod.
	
	self assert: (translation args includes: method methodNode arguments first name)
]

{ #category : #tests }
VMMASTTranslationTest >> testMethodWithConditionInLoopLimitHasLimitVariable [

	| translation method loop |
	method := self class >> #methodWithExpressionInLoopCondition.
	translation := method asTranslationMethodOfClass: TMethod.
	
	loop := translation statements first.
	self assert: loop args size equals: 4
]

{ #category : #tests }
VMMASTTranslationTest >> testMethodWithConstantConditionInLoopHasNoLimitVariable [

	| translation method loop |
	method := self class >> #methodWithLoop.
	translation := method asTranslationMethodOfClass: TMethod.
	
	loop := translation statements first.
	self assert: loop args size equals: 6
]

{ #category : #tests }
VMMASTTranslationTest >> testMethodWithLoopDeclaresLoopIndexVariable [

	| translation method block |
	method := self class >> #methodWithLoop.
	translation := method asTranslationMethodOfClass: TMethod.
	
	block := method methodNode statements first arguments second.
	self deny: (translation locals includes: block arguments first)
]

{ #category : #tests }
VMMASTTranslationTest >> testTranslateBinaryMethodHasSameName [

	| translation |
	translation := self class >> #+ asTranslationMethodOfClass: TMethod.
	
	self assert: translation selector equals: #+.
]

{ #category : #tests }
VMMASTTranslationTest >> testTranslateKeywordMethodHasSameName [

	| translation method |
	method := self class >> #methodWithArgument:.
	translation := method asTranslationMethodOfClass: TMethod.
	
	self assert: translation selector equals: method selector.
]

{ #category : #tests }
VMMASTTranslationTest >> testTranslateUnaryMethodHasSameName [

	| translation method |
	method := self class >> #methodWithNoArguments.
	translation := method asTranslationMethodOfClass: TMethod.
	
	self assert: translation selector equals: method selector.
]
