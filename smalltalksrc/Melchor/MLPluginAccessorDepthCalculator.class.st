Class {
	#name : #MLPluginAccessorDepthCalculator,
	#superclass : #MLAccessorDepthCalculator,
	#instVars : [
		'inProgressSelectors'
	],
	#category : #Melchor
}

{ #category : #'spur primitive compilation' }
MLPluginAccessorDepthCalculator >> accessorChainsForMethod: method interpreterClass: interpreterClass [
	inProgressSelectors := Set new.
	^[super accessorChainsForMethod: method interpreterClass: interpreterClass] ensure:
		[inProgressSelectors := nil]
]

{ #category : #'spur primitive compilation' }
MLPluginAccessorDepthCalculator >> accessorDepthDeterminationFollowsSelfSends [
	^true
]

{ #category : #'spur primitive compilation' }
MLPluginAccessorDepthCalculator >> accessorsAndAssignmentsForSubMethodNamed: selector actuals: actualParameters depth: depth interpreterClass: interpreterClass into: aTrinaryBlock [
	"Evaluate aTrinaryBlock with the root accessor sends, accessor sends and assignments in the sub-method named selector."

	| method map |
	(inProgressSelectors includes: selector) ifTrue:
		[^nil].
	inProgressSelectors add: selector.
	method := codeGenerator methodNamed: selector.
	method ifNil:
		[^nil].
	map := Dictionary new.
	method args do: [:var| map at: var put: depth asString, var].
	method locals do: [:var| map at: var put: depth asString, var].
	^self accessorsAndAssignmentsForMethod: (method copy renameVariablesUsing: map)
		actuals: actualParameters
		depth: depth + 1
		interpreterClass: interpreterClass
		into: aTrinaryBlock
]

{ #category : #'spur primitive compilation' }
MLPluginAccessorDepthCalculator >> actualsForMethod: aTMethod [
	"Normal primitives have no arguments, but translated primitives do.
	 Override to answer actuals for translated primitives."
	^(aTMethod args size - 1 to: 0 by: -1) collect:
		[:i|
		 TSendNode new
			setSelector: #stackValue:
			receiver: (TVariableNode new setName: 'interpreterProxy')
			arguments: {TConstantNode new setValue: i}]
]

{ #category : #'spur primitive compilation' }
MLPluginAccessorDepthCalculator >> isObjectAccessor: selector given: interpreterClass [
	"Override to include the selectors transformed into accessors for translated primitives.
	 InterpreterPlugin browseTranslatedPrimitives"
	^(#(asciiValue at: at:put: basicAt: size) includes: selector)
	  or: [super isObjectAccessor: selector given: interpreterClass]
]
