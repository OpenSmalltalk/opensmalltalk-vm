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
	"For running from Smalltalk - answer a class that can be used to simulate the receiver, or nil if you want the primitives in this module to always fail, causing simulation to fall through to the Smalltalk code."

	^SmartSyntaxPluginSimulator
]

{ #category : #simulation }
SmartSyntaxInterpreterPlugin class >> simulatorForInterpreterInterface: objectMemoryOrInterpreterProxy [
	"Answer an uninitialized (in the sense that the plugin has been sent initialize, but not initialiseModule)
	 simulator for the receiver, or nil, if the receiver answers nil to simulatorClass.  In this case, answer an
	 instance of SmartSyntaxPluginSimulator wrapped around an uniniialized simulator for the receiver."

	^self simulatorClass ifNotNil: "Maybe specific, or the general SmartSyntaxPluginSimulator"
		[:simClass| | actualPluginSimClass |
		 actualPluginSimClass := simClass == SmartSyntaxPluginSimulator
									ifTrue: [self subclasses 
											detect: [:sc| sc name endsWith: 'Simulator']
											ifNone: [self]]
									ifFalse: [simClass].
		 SmartSyntaxPluginSimulator new
			actualPlugin: actualPluginSimClass new signatureClass: self;
			setInterpreter: objectMemoryOrInterpreterProxy;
			yourself]
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
SmartSyntaxInterpreterPlugin >> primitive: primName [
	<doNotGenerate>
	^simulator primitive: primName
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
	self debugCode:
		[aBool ifFalse:
			[self error: 'Assertion failed!']].
	^aBool
]
