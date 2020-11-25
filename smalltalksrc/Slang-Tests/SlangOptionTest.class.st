Class {
	#name : #SlangOptionTest,
	#superclass : #TestCase,
	#instVars : [
		'cogitSubclassName',
		'slang'
	],
	#category : #'Slang-Tests'
}

{ #category : #running }
SlangOptionTest >> setUp [
	super setUp.
	slang := CCodeGenerator new.
	
	slang environment: SystemDictionary new.
	slang environment at: SlangCogitSubclass name put: SlangCogitSubclass.
	slang environment at: SlangCogitSuperclass name put: SlangCogitSuperclass.
	
	"We set an instance, polymorphic with the class"
	slang vmClass: MockSlangClass new.
	slang vmClass optionsAt: #SlangObjectMemorySubclass put: false.
	slang vmClass optionsAt: #SlangObjectMemorySuperclass put: false.
	slang vmClass mockConstantClass: MockConstantClass new.
]

{ #category : #'tests - option - cogit' }
SlangOptionTest >> testOptionInSpecifiedCogitShouldBeActive [

	"This is a VM-tied slang test"
	"Configure the code generator with a Cogit.
	Options for that cogit should be active"
	<regressionTest>
	

	| optionPragma |
	optionPragma := Pragma selector: #option: arguments: {#SlangCogitSubclass}.
	
	slang vmClass cogitClass: SlangCogitSubclass.
	self assert: (slang optionIsTrue: optionPragma in: slang vmClass)
]

{ #category : #'tests - option - cogit' }
SlangOptionTest >> testOptionInSpecifiedCogitSubclassShouldNotBeActive [

	"This is a VM-tied slang test"
	"Configure the code generator with a Cogit.
	Options for that cogit's subclasses should not be active"
	<regressionTest>
	

	| optionPragma |
	optionPragma := Pragma selector: #option: arguments: {#SlangCogitSubclass}.
	
	"Configure the generation for a superclass, making the subclass unavailable"
	slang vmClass cogitClass: SlangCogitSuperclass.
	self deny: (slang optionIsTrue: optionPragma in: slang vmClass)
]

{ #category : #'tests - option - cogit' }
SlangOptionTest >> testOptionInSpecifiedCogitSuperclassShouldBeActive [

	"This is a VM-tied slang test"
	"Configure the code generator with a Cogit.
	Options for that cogit's superclasses should be active"
	<regressionTest>
	

	| optionPragma |
	optionPragma := Pragma selector: #option: arguments: {#SlangCogitSuperclass}.
	
	"Configure the generation for a subclass, making the superclass available"
	slang vmClass cogitClass: SlangCogitSubclass.
	self assert: (slang optionIsTrue: optionPragma in: slang vmClass)
]

{ #category : #'tests - option - memory' }
SlangOptionTest >> testOptionInSpecifiedObjectMemoryShouldBeActive [

	"This is a VM-tied slang test"
	"Configure the code generator with an ObjectMemory.
	Options for that objectMemory should be active"
	<regressionTest>
	

	| optionPragma |
	optionPragma := Pragma selector: #option: arguments: {#SlangObjectMemorySubclass}.
	
	slang vmClass objectMemoryClass: SlangObjectMemorySubclass.
	self assert: (slang optionIsTrue: optionPragma in: slang vmClass)
]

{ #category : #'tests - option - memory' }
SlangOptionTest >> testOptionInSpecifiedObjectMemorySubclassShouldNotBeActive [

	"This is a VM-tied slang test"
	"Configure the code generator with an ObjectMemory.
	Options for that object memories' subclasses should not be active"
	<regressionTest>
	
	"This test is supposed to fail but it works because the class is looked up by bindingOf: and eventually found in the global environment"
	<expectedFailure>
	

	| optionPragma |
	optionPragma := Pragma selector: #option: arguments: {#SlangObjectMemorySubclass}.
	
	"Configure the generation for a superclass, making the subclass unavailable"
	slang vmClass objectMemoryClass: SlangObjectMemorySuperclass.
	self deny: (slang optionIsTrue: optionPragma in: slang vmClass)
]

{ #category : #'tests - option - memory' }
SlangOptionTest >> testOptionInSpecifiedObjectMemorySuperclassShouldBeActive [

	"This is a VM-tied slang test"
	"Configure the code generator with an Object Memory.
	Options for that Object Memory's superclasses should be active"
	<regressionTest>
	

	| optionPragma |
	optionPragma := Pragma selector: #option: arguments: {#SlangObjectMemorySuperclass}.
	
	"Configure the generation for a subclass, making the superclass available"
	slang vmClass objectMemoryClass: SlangObjectMemorySubclass.
	self assert: (slang optionIsTrue: optionPragma in: slang vmClass)
]

{ #category : #'tests - option - cogit' }
SlangOptionTest >> testOptionWithUnrelatedCogitClassShouldNotBeActive [

	"This is a VM-tied slang test"
	"Configure the code generator with a Cogit.
	Options for that cogit should be active"
	<regressionTest>
	

	| optionPragma |
	optionPragma := Pragma selector: #option: arguments: {#SlangCogitSubclass}.
	
	slang vmClass cogitClass: OrderedCollection.
	self deny: (slang optionIsTrue: optionPragma in: slang vmClass)
]

{ #category : #'tests - option - memory' }
SlangOptionTest >> testOptionWithUnrelatedObjectMemoryClassShouldNotBeActive [

	"This is a VM-tied slang test"
	"Configure the code generator with a Object Memory.
	Options for that Object Memory should be active"
	<regressionTest>
	
	"This test is supposed to fail but it works because the class is looked up by bindingOf: and eventually found in the global environment"
	<expectedFailure>
	

	| optionPragma |
	optionPragma := Pragma selector: #option: arguments: {#SlangObjectMemorySubclass}.
	
	slang vmClass objectMemoryClass: OrderedCollection.
	self deny: (slang optionIsTrue: optionPragma in: slang vmClass)
]

{ #category : #'tests - option - cogit' }
SlangOptionTest >> testOptionWithoutCogitShouldNotBeActive [

	"This is a VM-tied slang test"
	"Configure the code generator with a Cogit.
	Options for that cogit should be active"
	<regressionTest>
	

	| optionPragma |
	optionPragma := Pragma selector: #option: arguments: {#SlangCogitSubclass}.
	
	slang vmClass cogitClass: nil.
	self deny: (slang optionIsTrue: optionPragma in: slang vmClass)
]

{ #category : #'tests - option - memory' }
SlangOptionTest >> testOptionWithoutObjectMemoryShouldNotBeActive [

	"This is a VM-tied slang test"
	"Configure the code generator with a ObjectMemory.
	Options for that ObjectMemory should be active"
	<regressionTest>
	

	| optionPragma |
	optionPragma := Pragma selector: #option: arguments: {#SlangObjectMemorySubclass}.
	
	slang vmClass objectMemoryClass: nil.
	self deny: (slang optionIsTrue: optionPragma in: slang vmClass)
]
