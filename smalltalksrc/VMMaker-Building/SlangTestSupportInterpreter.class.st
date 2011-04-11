"
SlangTestSupport implements translatable methods for use in SlangTest unit tests.

	""VMMaker clearCacheEntriesFor: SlangTestSupportInterpreter.
	SlangTestSupportInterpreter asCString""
"
Class {
	#name : #SlangTestSupportInterpreter,
	#superclass : #ObjectMemory,
	#category : #'VMMaker-Tests'
}

{ #category : #'export declaration' }
SlangTestSupportInterpreter >> declareExportFalseByMethod [
	"SlangTestSupport asCString: #declareExportFalseByMethod"

	self export: false

]

{ #category : #'export declaration' }
SlangTestSupportInterpreter >> declareExportFalseByPragma [
	"SlangTestSupport asCString: #declareExportFalseByPragma"

	<export: false>

]

{ #category : #'export declaration' }
SlangTestSupportInterpreter >> declareExportTrueByMethod [
	"SlangTestSupport asCString: #declareExportTrueByMethod"

	self export: true

]

{ #category : #'export declaration' }
SlangTestSupportInterpreter >> declareExportTrueByPragma [
	"SlangTestSupport asCString: #declareExportTrueByPragma"

	<export: true>

]

{ #category : #'static declaration' }
SlangTestSupportInterpreter >> declareStaticFalseByMethod [
	"SlangTestSupport asCString: #declareStaticFalseByMethod"

	self static: false

]

{ #category : #'static declaration' }
SlangTestSupportInterpreter >> declareStaticFalseByPragma [
	"SlangTestSupport asCString: #declareStaticFalseByPragma"

	<static: false>

]

{ #category : #'static declaration' }
SlangTestSupportInterpreter >> declareStaticTrueByMethod [
	"SlangTestSupport asCString: #declareStaticTrueByMethod"

	self static: true

]

{ #category : #'static declaration' }
SlangTestSupportInterpreter >> declareStaticTrueByPragma [
	"SlangTestSupport asCString: #declareStaticTrueByPragma"

	<static: true>

]

{ #category : #inlining }
SlangTestSupportInterpreter >> inlineByMethod [
	"SlangTestSupport asCString: #inlineByMethod"
	"SlangTestSupport asInlinedCString: #inlineByMethod"

	| bar foo |
	foo := self methodThatShouldBeInlinedByMethod.
	bar := self methodThatShouldNotBeInlinedByMethod
]

{ #category : #inlining }
SlangTestSupportInterpreter >> inlineByPragma [
	"SlangTestSupport asCString: #inlineByPragma"
	"SlangTestSupport asInlinedCString: #inlineByPragma"

	| bar foo |
	foo := self methodThatShouldBeInlinedByPragma.
	bar := self methodThatShouldNotBeInlinedByPragma
]

{ #category : #inlining }
SlangTestSupportInterpreter >> methodThatShouldBeInlinedByMethod [

	self inline: true.
	^ #foo
]

{ #category : #inlining }
SlangTestSupportInterpreter >> methodThatShouldBeInlinedByPragma [

	<inline: true>
	^ #foo
]

{ #category : #inlining }
SlangTestSupportInterpreter >> methodThatShouldNotBeInlinedByMethod [

	self inline: false.
	^ #bar
]

{ #category : #inlining }
SlangTestSupportInterpreter >> methodThatShouldNotBeInlinedByPragma [

	<inline: false>
	^ #bar
]

{ #category : #'type declaration' }
SlangTestSupportInterpreter >> returnTypeByMethod [
	"SlangTestSupport asCString: #returnTypeByMethod"

	self returnTypeC: 'char *'.

]

{ #category : #'type declaration' }
SlangTestSupportInterpreter >> returnTypeByPragma [
	"SlangTestSupport asCString: #returnTypeByPragma"

	<returnTypeC: 'char *'>

]

{ #category : #'type declaration' }
SlangTestSupportInterpreter >> varDefByMethod [
	"SlangTestSupport asCString: #varDefByMethod"

	| foo bar |
	self var: #foo type: 'char *'.
	self var: #bar declareC: 'unsigned int * bar'

]

{ #category : #'type declaration' }
SlangTestSupportInterpreter >> varDefByMethodAndPragma [
	"SlangTestSupportInterpreter asCString: #varDefByMethodAndPragma"

	| foo bar baz fum |
	<var: #baz type: 'float'>
	<var: #fum declareC: 'double fum'>
	self var: #foo type: 'char *'.
	self var: #bar declareC: 'unsigned int * bar'

]

{ #category : #'type declaration' }
SlangTestSupportInterpreter >> varDefByPragma [
	"SlangTestSupport asCString: #varDefByPragma"

	| foo bar |
	<var: #foo type: 'char *'>
	<var: #bar declareC: 'unsigned int * bar'>

]
