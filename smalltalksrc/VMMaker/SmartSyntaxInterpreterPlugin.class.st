"
Subclass of InterpreterPlugin, used in connection with TestCodeGenerator for named primitives with type coercion specifications
"
Class {
	#name : #SmartSyntaxInterpreterPlugin,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'simulator'
	],
	#category : #'VMMaker-SmartSyntaxPlugins'
}

{ #category : #private }
SmartSyntaxInterpreterPlugin class >> codeGeneratorClass [
	"return the appropriate class of code generator for this kind ofplugin"

	^SmartSyntaxPluginCodeGenerator
]

{ #category : #'instance creation' }
SmartSyntaxInterpreterPlugin class >> doPrimitive: primitiveName withArguments: argArray [
	| proxy plugin |
	proxy := InterpreterProxy new.
	proxy loadStackFrom: thisContext sender.
	plugin := (self simulatorClass ifNil: [self]) new.
	plugin setInterpreter: proxy.
	^plugin perform: primitiveName asSymbol withArguments: argArray
]

{ #category : #translation }
SmartSyntaxInterpreterPlugin class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #translation }
SmartSyntaxInterpreterPlugin class >> prepareToBeAddedToCodeGenerator: aCodeGen [
	aCodeGen removeVariable: 'simulator'
]

{ #category : #translation }
SmartSyntaxInterpreterPlugin class >> shouldBeTranslated [
"SmartSyntaxInterpreterPlugin should not be translated but its subclasses should"
	^self ~= SmartSyntaxInterpreterPlugin
]

{ #category : #simulation }
SmartSyntaxInterpreterPlugin class >> simulatorClass [
	"For running from Smalltalk - answer a class that can be used to simulate the receiver, or nil if you want the primitives in this module to always fail, causing simulation to fall through to the Smalltalk code.
	By default SmartSyntaxInterpreterPlugin answers nil because methods in these plugins are intended to be embedded in code that pushes and pops from the stack and therefore cannot be run independently.  This wrapper code is generated when translated to C.  But, unfortunately, this code is missing during simulation.  There was an attempt to simulate this, but only the prologue code (getting arg from the stack) is simulated (see simulatePrologInContext:). The epologue code (popping args and pushing result) is not.  So I am making this nil until this can be fixed.
	Also, beware that primitive methods that take no args exactly match their primitive name (faking out InterpreterSimulator>>callExternalPrimitive:).  They should only be called from within wrapper code that simulates the prologue and epilogue.  Primitive method that take args don't have this accidental matching problem since their names contain colons while their primitive names do not. - ajh 8/21/2002"

	^ nil
]

{ #category : #translation }
SmartSyntaxInterpreterPlugin class >> translateDoInlining: inlineFlag locally: localFlag debug: debugFlag [ 
	^ self
		translate: self moduleName , '.c'
		doInlining: inlineFlag
		locally: localFlag
		debug: debugFlag
]

{ #category : #simulation }
SmartSyntaxInterpreterPlugin >> primitive: primName parameters: parms [
	<doNotGenerate>
	^simulator primitive: primName parameters: parms
]

{ #category : #simulation }
SmartSyntaxInterpreterPlugin >> primitive: primName parameters: anArray receiver: aClassSymbol [
	<doNotGenerate>
	^simulator primitive: primName parameters: anArray receiver: aClassSymbol
]

{ #category : #simulation }
SmartSyntaxInterpreterPlugin >> remapOop: oopOrList in: aBlock [
	"Call remapOop: for the variable oopOrList (or all of the variables in oopOrList) before evaluating
	 aBlock, and restore them after.  If this is Spur, do nothing, since Spur does not GC on allocation
	 and the  SmartSyntaxPluginCodeGenerator generates null code for this op in Spur."
	<doNotGenerate>
	| ctxt tempNames tempIndices |
	interpreterProxy hasSpurMemoryManagerAPI ifTrue:
		[^aBlock value].
	ctxt := thisContext sender.
	tempNames := ctxt tempNames.
	oopOrList isArray
		ifTrue:
			[tempIndices := oopOrList collect: [:tempName| tempNames indexOf: tempName].
			 tempIndices do:
				[:index| interpreterProxy pushRemappableOop: (ctxt namedTempAt: index)]]
		ifFalse: [interpreterProxy pushRemappableOop: oopOrList].
	^aBlock ensure:
		[oopOrList isArray
			ifTrue:
				[tempIndices reverseDo:
					[:index| ctxt namedTempAt: index put: interpreterProxy popRemappableOop]]
			ifFalse:
				[1 to: ctxt numTemps do:
					[:index|
					(ctxt tempAt: index) = oopOrList ifTrue:
						[ctxt tempAt: index put: interpreterProxy topRemappableOop]].
				 interpreterProxy popRemappableOop]]
]

{ #category : #accessing }
SmartSyntaxInterpreterPlugin >> simulator [
	<doNotGenerate>
	^simulator
]

{ #category : #accessing }
SmartSyntaxInterpreterPlugin >> simulator: aSmartSyntaxPluginSimulator [
	<doNotGenerate>
	simulator := aSmartSyntaxPluginSimulator
]

{ #category : #debugging }
SmartSyntaxInterpreterPlugin >> sqAssert: aBool [ 
	self
		debugCode: [aBool
				ifFalse: [self error: 'Assertion failed!'].
			^ aBool]
]
