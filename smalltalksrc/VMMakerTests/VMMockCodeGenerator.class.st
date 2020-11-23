Class {
	#name : #VMMockCodeGenerator,
	#superclass : #Object,
	#instVars : [
		'interpreter',
		'addedPrimitives'
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
VMMockCodeGenerator >> accessorDepthCalculator [

	^ self 
]

{ #category : #'as yet unclassified' }
VMMockCodeGenerator >> accessorDepthForSelector: aString [ 
	
	^ addedPrimitives at: aString 
	
	
]

{ #category : #'as yet unclassified' }
VMMockCodeGenerator >> addPrimitive: aSelector [ 
	
	self addPrimitive: aSelector accessorDepth: -1
]

{ #category : #'as yet unclassified' }
VMMockCodeGenerator >> addPrimitive: aSelector accessorDepth: aDepth [
	
	addedPrimitives at: aSelector put: aDepth
]

{ #category : #'as yet unclassified' }
VMMockCodeGenerator >> exportedPrimitiveNames [

	^ (addedPrimitives keys collect: [ :e | e -> e ]) asDictionary
]

{ #category : #initialization }
VMMockCodeGenerator >> initialize [ 

	addedPrimitives := Dictionary new
]

{ #category : #'as yet unclassified' }
VMMockCodeGenerator >> initializeWithPrimitiveTable [

	interpreter primitiveTable
		select: [ :aSelector | aSelector isSymbol ]
		thenDo: [ :aSelector | self addPrimitive: aSelector ]
]

{ #category : #'as yet unclassified' }
VMMockCodeGenerator >> interpreter: aCogVMSimulatorLSB [ 

	interpreter := aCogVMSimulatorLSB.

]
