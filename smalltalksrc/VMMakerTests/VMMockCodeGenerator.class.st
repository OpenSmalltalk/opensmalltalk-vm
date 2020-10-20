Class {
	#name : #VMMockCodeGenerator,
	#superclass : #Object,
	#instVars : [
		'interpreter',
		'addedPrimitives',
		'codeGenerator'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #'as yet unclassified' }
VMMockCodeGenerator class >> for: aCogVMSimulatorLSB [ 

	^ self new
		interpreter: aCogVMSimulatorLSB;
		yourself
]

{ #category : #'as yet unclassified' }
VMMockCodeGenerator >> accessorDepthForSelector: aString [ 
	
	(addedPrimitives includes: aString) 
		ifTrue: [ ^ -1 ].
	
	^ self codeGenerator accessorDepthForSelector: aString
]

{ #category : #'as yet unclassified' }
VMMockCodeGenerator >> addPrimitive: aSelector [ 
	
	addedPrimitives add: aSelector
]

{ #category : #'as yet unclassified' }
VMMockCodeGenerator >> codeGenerator [
	
	^ codeGenerator ifNil: [ 
		codeGenerator := (VMMaker new
			buildCodeGeneratorForInterpreter: CoInterpreterPrimitives
			includeAPIMethods: false
			initializeClasses: false)
				logger: Transcript;
				yourself ]
]

{ #category : #'as yet unclassified' }
VMMockCodeGenerator >> exportedPrimitiveNames [

	^ codeGenerator exportedPrimitiveNames ,
	  (addedPrimitives collect: [ :e | e -> e ]) asDictionary
]

{ #category : #initialization }
VMMockCodeGenerator >> initialize [ 

	addedPrimitives := OrderedCollection new
]

{ #category : #'as yet unclassified' }
VMMockCodeGenerator >> interpreter: aCogVMSimulatorLSB [ 

	interpreter := aCogVMSimulatorLSB.

]
