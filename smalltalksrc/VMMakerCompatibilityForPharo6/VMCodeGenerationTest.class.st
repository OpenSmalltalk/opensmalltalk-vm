Class {
	#name : #VMCodeGenerationTest,
	#superclass : #TestCase,
	#category : #'VMMakerCompatibilityForPharo6-Tests'
}

{ #category : #'generation-targets' }
VMCodeGenerationTest >> methodWithIfNil [

	self something
		ifNil: [ 1 ]
		ifNotNil: [ 2 ]
]

{ #category : #'generation-targets' }
VMCodeGenerationTest >> methodWithIfNilAssignment [

	| variable |
	variable := self something
		ifNil: [ 1 ]
		ifNotNil: [ 2 ]
]

{ #category : #'generation-targets' }
VMCodeGenerationTest >> methodWithIfNilAssignmentOfComplexStatements [

	| variable |
	variable := self something
		ifNil: [ | temp |
			temp := 1.
			temp := temp + 1.
			temp * 3 ]
		ifNotNil: [ | temp |
			temp := 2.
			temp := temp + 5.
			temp * 3 ]
]

{ #category : #'generation-targets' }
VMCodeGenerationTest >> methodWithLoop [

	1 to: 10 do: [ :i | self foo: i ]
]

{ #category : #'generation-targets' }
VMCodeGenerationTest >> methodWithNilIfNil [

	^ nil
		ifNil: [ 1 ]
		ifNotNil: [ 2 ]
]

{ #category : #tests }
VMCodeGenerationTest >> testComplexIfNilAssignment [

	| translation method codeGenerator result |
	method := self class >> #methodWithIfNilAssignmentOfComplexStatements.
	translation := method asTranslationMethodOfClass: TMethod.
	codeGenerator := CCodeGeneratorGlobalStructure new.
	codeGenerator addMethod: translation.
	codeGenerator doInlining: true.
		
	result := String streamContents: [ :stream |
		translation parseTree statements first emitCCodeOn: stream level: 0 generator: codeGenerator.
	].
	
	self assert: result equals: 'if ((something()) == null) {
	temp = 1;
	temp += 1;
	variable = temp * 3;
}
else {
	temp = 2;
	temp += 5;
	variable = temp * 3;
}'
]

{ #category : #tests }
VMCodeGenerationTest >> testLoopVariableIsTemp [

	| translation method codeGenerator result |
	method := self class >> #methodWithLoop.
	translation := method asTranslationMethodOfClass: TMethod.
	codeGenerator := CCodeGeneratorGlobalStructure new.
	codeGenerator doInlining: true.
	
	result := String streamContents: [ :stream |
		translation emitCCodeOn: stream generator: codeGenerator.
	].

	self assert: result equals: '
	/* VMCodeGenerationTest>>#methodWithLoop */
static sqInt
methodWithLoop(void)
{
    sqInt i;

	for (i = 1; i <= 10; i += 1) {
		foo(i);
	}
	return self;
}
'
]

{ #category : #tests }
VMCodeGenerationTest >> testNilIfNilGeneratesOnlyFirstBranch [

	| translation method codeGenerator result |
	method := self class >> #methodWithNilIfNil.
	translation := method asTranslationMethodOfClass: TMethod.
	codeGenerator := CCodeGeneratorGlobalStructure new.
	codeGenerator generateDeadCode: false.
	codeGenerator addMethod: translation.
	codeGenerator doInlining: true.

	result := String streamContents: [ :stream |
		translation parseTree statements first emitCCodeOn: stream level: 0 generator: codeGenerator.
	].
	
	self assert: result equals: 'return 1'
]

{ #category : #tests }
VMCodeGenerationTest >> testSimpleIfNil [

	| translation method codeGenerator result |
	method := self class >> #methodWithIfNilAssignment.
	translation := method asTranslationMethodOfClass: TMethod.
	codeGenerator := CCodeGeneratorGlobalStructure new.
	codeGenerator generateDeadCode: false.
	codeGenerator addMethod: translation.
	codeGenerator doInlining: true.
	
	result := String streamContents: [ :stream |
		translation parseTree statements first emitCCodeOn: stream level: 0 generator: codeGenerator.
	].
	
	self assert: result equals: 'variable = ((something()) == null
	? 1
	: 2)'
]

{ #category : #tests }
VMCodeGenerationTest >> testSimpleIfNilAssignment [

	| translation method codeGenerator result |
	method := self class >> #methodWithIfNil.
	translation := method asTranslationMethodOfClass: TMethod.
	codeGenerator := CCodeGeneratorGlobalStructure new.
	codeGenerator generateDeadCode: false.
	codeGenerator addMethod: translation.
	codeGenerator doInlining: true.
	
	result := String streamContents: [ :stream |
		translation parseTree statements first emitCCodeOn: stream level: 0 generator: codeGenerator.
	].
	
	self assert: result equals: 'if ((something()) == null) {
}
else {
}'
]
