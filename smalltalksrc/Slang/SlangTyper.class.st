Class {
	#name : #SlangTyper,
	#superclass : #Object,
	#instVars : [
		'codeGenerator',
		'stopOnErrors'
	],
	#category : #'Slang-TypeInference'
}

{ #category : #'instance creation' }
SlangTyper class >> on: aCCodeGenerator [ 
	
	^ self new
		codeGenerator: aCCodeGenerator;
		yourself
]

{ #category : #accessing }
SlangTyper >> codeGenerator [
	^ codeGenerator
]

{ #category : #accessing }
SlangTyper >> codeGenerator: aCCodeGenerator [ 
	codeGenerator := aCCodeGenerator
]

{ #category : #'type inference' }
SlangTyper >> inferTypes [
	| typeConflicts |
	typeConflicts := OrderedCollection new.
	[ self inferTypesForImplicitlyTypedVariablesAndMethods ]
		on: Notification
		do: [ :n | 
			typeConflicts add: n copy freeze.
			n resume ].
	(stopOnErrors and: [ typeConflicts isNotEmpty ]) ifTrue: [ Error signal: 'there were type errors' ]
]

{ #category : #'type inference' }
SlangTyper >> inferTypesForImplicitlyTypedVariablesAndMethods [
	"Infer the return tupe and the types of untyped variables.
	 As far as variables go, for now we try only to infer variables
	 assigned the result of #longLongAt:, but much more could be
	 done here."

	"Iterate over all methods, inferring #void return types, until we reach a fixed point."
	| allMethods |
	allMethods := codeGenerator apiMethods
					ifNil: [codeGenerator methods]
					ifNotNil: [(Set withAll: codeGenerator methods)
								addAll: codeGenerator apiMethods;
								yourself].
	"Make an initial pass to assign the return types of all simple methods that return constants,
	 or those that have explicit return types."						
	allMethods do:
		[:m|
		m removeFinalSelfReturnIn: codeGenerator. "must precede recordDeclarationsIn: because it may set returnType"
		m recordDeclarationsIn: codeGenerator.
		(m returnType isNil
		 and: [m isReturnConstant]) ifTrue:
			[m inferReturnTypeIn: codeGenerator]].

	"now iterate until we reach a fixed point"
	[| changedReturnType |
	 changedReturnType := false.
	 allMethods do:
		[:m|
		self inferTypesForImplicitlyTypedVariablesIn: m.
		 (m inferReturnTypeIn: codeGenerator) ifTrue:
			[changedReturnType := true]].
	 changedReturnType] whileTrue.

	"Type all as-yet-untyped methods as the default"
	codeGenerator methods do:
		[:m|
		m returnType ifNil:
			[m returnType: (m returnsExpression
								ifTrue: [codeGenerator defaultType]
								ifFalse: [codeGenerator implicitReturnTypeFor: m])].
		m transformReturns].

	"Make a final pass to type anything assigned from the default type"
	allMethods do: [ :m |
		self inferTypesForImplicitlyTypedVariablesIn: m ]
]

{ #category : #'type inference' }
SlangTyper >> inferTypesForImplicitlyTypedVariablesIn: aMethod [
	"infer types for untyped variables from assignments and arithmetic uses.
	 For debugging answer a Dictionary from var to the nodes that determined types
	 This for debugging:
		(self copy inferTypesForImplicitlyTypedVariablesIn: aCodeGen)"
	| alreadyExplicitlyTypedOrNotToBeTyped asYetUntyped mustBeSigned newDeclarations effectiveNodes |
	codeGenerator maybeBreakForTestToInline: aMethod selector in: aMethod.
	alreadyExplicitlyTypedOrNotToBeTyped := aMethod declarations keys asSet.
	asYetUntyped := aMethod locals copyWithoutAll: alreadyExplicitlyTypedOrNotToBeTyped.
	mustBeSigned := Set new.
	newDeclarations := Dictionary new.
	effectiveNodes := Dictionary new. "this for debugging"
	aMethod parseTree nodesDo:
		[:node| | type var |
		"If there is something of the form i >= 0, then i should be signed, not unsigned."
		(node isSend
		 and: [(aMethod locals includes: (var := node receiver variableNameOrNil))
		 and: [(#(<= < >= >) includes: node selector)
		 and: [node args first isConstant
		 and: [node args first value = 0]]]]) ifTrue:
			[mustBeSigned add: var.
			 effectiveNodes at: var put: { #signed. node }, (effectiveNodes at: var ifAbsent: [#()])].
		"if an assignment to an untyped local of a known type, set the local's type to that type.
		 Only observe known sends (methods in the current set) and typed local variables."
		(node isAssignment
		 and: [(aMethod locals includes: (var := node variable name))
		 and: [(alreadyExplicitlyTypedOrNotToBeTyped includes: var) not]]) ifTrue: "don't be fooled by previously inferred types"
		 	[type := node expression isSend
						ifTrue: [codeGenerator returnTypeForSend: node expression in: aMethod ifNil: nil]
						ifFalse: [aMethod typeFor: (node expression isAssignment
													ifTrue: [node expression variable]
													ifFalse: [node expression]) in: codeGenerator].
			 type "If untyped, then cannot type the variable yet. A subsequent assignment may assign a subtype of what this type ends up being"
				ifNil: "Further, if the type derives from an as-yet-untyped method, we must defer."
					[alreadyExplicitlyTypedOrNotToBeTyped add: var.
					 (node expression isSend
					 and: [(codeGenerator methodNamed: node expression selector) notNil]) ifTrue:
						[newDeclarations removeKey: var ifAbsent: nil]]
				ifNotNil: "Merge simple types (but *don't* merge untyped vars); complex types must be defined by the programmer."
					[(codeGenerator isSimpleType: type) ifTrue:
						[(asYetUntyped includes: var)
							ifTrue: [newDeclarations at: var put: type, ' ', var. asYetUntyped remove: var]
							ifFalse:
								[self mergeTypeOf: var in: newDeclarations with: type method: aMethod].
						 effectiveNodes at: var put: { newDeclarations at: var. node }, (effectiveNodes at: var ifAbsent: [#()])]]]].
	mustBeSigned do:
		[:var|
		 (newDeclarations at: var ifAbsent: nil) ifNotNil:
			[:decl| | type |
			 type := codeGenerator extractTypeFor: var fromDeclaration: decl.
			 type first == $u ifTrue:
				[newDeclarations at: var put: (self signedTypeForIntegralType: type), ' ', var]]].
	newDeclarations keysAndValuesDo:
		[:var :decl| aMethod declarations at: var put: decl].
	^effectiveNodes
]

{ #category : #'type inference' }
SlangTyper >> mergeTypeOf: var in: aDictionary with: newType method: tMethod [
	"var is a variable that has been assigned an expression of type  newType.
	 Either assign its type, if it is as yet untyped, or merge newType with its existing type.
	 N.B. We refuse to promote a variable that already has integral type to a floating point
	 type.  The existing plugins depend on this; one can always use an explicit type in future."
	| existingType mergedType |
	existingType := codeGenerator
						extractTypeFor: var
						fromDeclaration: (aDictionary at: var ifAbsentPut: [newType, ' ', var]).
	existingType ~= newType ifTrue:
		[((codeGenerator isPointerCType: existingType)
		  or: [codeGenerator isPointerCType: newType])
			ifTrue:
				[existingType = #'void *' ifTrue: [^newType].
				 newType = #'void *' ifTrue: [^existingType].
				 codeGenerator logger show: 'conflicting types ', existingType, ' ', newType, ' for ', var, ' in ', tMethod selector.
				 ^existingType]
			ifFalse:
				[((codeGenerator isIntegralCType: existingType)
				  and: [codeGenerator isFloatingPointCType: newType]) ifFalse:
					[mergedType := codeGenerator promoteArithmeticTypes: existingType and: newType.
					 aDictionary at: var put: mergedType, ' ', var]]]
]

{ #category : #'type inference' }
SlangTyper >> signedTypeForIntegralType: aCTypeString [
	(aCTypeString beginsWith: 'unsigned ') ifTrue:
		[^aCTypeString allButFirst: 8].
	
	(aCTypeString beginsWith: 'usq') ifTrue:
		[^aCTypeString allButFirst].

	aCTypeString = 'size_t' ifTrue: [^#usqIntptr_t].
	
	self error: 'unknown type'.
	^#long
]

{ #category : #accessing }
SlangTyper >> stopOnErrors [
	^ stopOnErrors
]

{ #category : #accessing }
SlangTyper >> stopOnErrors: anObject [
	stopOnErrors := anObject
]
