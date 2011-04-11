"
SlangTestSupport implements translatable methods for use in SlangTest unit tests.
This is a subclass of InterpreterPlugin, which provides coverage of slang translation
for base plugins.

	""VMMaker clearCacheEntriesFor: SlangTestSupportPlugin.
	SlangTestSupportPlugin asCString""
"
Class {
	#name : #SlangTestSupportPlugin,
	#superclass : #InterpreterPlugin,
	#category : #'VMMaker-Tests'
}

{ #category : #'export declaration' }
SlangTestSupportPlugin >> declareExportFalseByMethod [
	"SlangTestSupport asCString: #declareExportFalseByMethod"

	self export: false

]

{ #category : #'export declaration' }
SlangTestSupportPlugin >> declareExportFalseByPragma [
	"SlangTestSupport asCString: #declareExportFalseByPragma"

	<export: false>

]

{ #category : #'export declaration' }
SlangTestSupportPlugin >> declareExportTrueByMethod [
	"SlangTestSupport asCString: #declareExportTrueByMethod"

	self export: true

]

{ #category : #'export declaration' }
SlangTestSupportPlugin >> declareExportTrueByPragma [
	"SlangTestSupport asCString: #declareExportTrueByPragma"

	<export: true>

]

{ #category : #'static declaration' }
SlangTestSupportPlugin >> declareStaticFalseByMethod [
	"SlangTestSupport asCString: #declareStaticFalseByMethod"

	self static: false

]

{ #category : #'static declaration' }
SlangTestSupportPlugin >> declareStaticFalseByPragma [
	"SlangTestSupport asCString: #declareStaticFalseByPragma"

	<static: false>

]

{ #category : #'static declaration' }
SlangTestSupportPlugin >> declareStaticTrueByMethod [
	"SlangTestSupport asCString: #declareStaticTrueByMethod"

	self static: true

]

{ #category : #'static declaration' }
SlangTestSupportPlugin >> declareStaticTrueByPragma [
	"SlangTestSupport asCString: #declareStaticTrueByPragma"

	<static: true>

]

{ #category : #inlining }
SlangTestSupportPlugin >> inlineByMethod [
	"SlangTestSupport asCString: #inlineByMethod"
	"SlangTestSupport asInlinedCString: #inlineByMethod"

	| bar foo |
	foo := self methodThatShouldBeInlinedByMethod.
	bar := self methodThatShouldNotBeInlinedByMethod
]

{ #category : #inlining }
SlangTestSupportPlugin >> inlineByPragma [
	"SlangTestSupport asCString: #inlineByPragma"
	"SlangTestSupport asInlinedCString: #inlineByPragma"

	| bar foo |
	foo := self methodThatShouldBeInlinedByPragma.
	bar := self methodThatShouldNotBeInlinedByPragma
]

{ #category : #inlining }
SlangTestSupportPlugin >> methodThatShouldBeInlinedByMethod [

	self inline: true.
	^ #foo
]

{ #category : #inlining }
SlangTestSupportPlugin >> methodThatShouldBeInlinedByPragma [

	<inline: true>
	^ #foo
]

{ #category : #inlining }
SlangTestSupportPlugin >> methodThatShouldNotBeInlinedByMethod [

	self inline: false.
	^ #bar
]

{ #category : #inlining }
SlangTestSupportPlugin >> methodThatShouldNotBeInlinedByPragma [

	<inline: false>
	^ #bar
]

{ #category : #'type declaration' }
SlangTestSupportPlugin >> returnTypeByMethod [
	"SlangTestSupport asCString: #returnTypeByMethod"

	self returnTypeC: 'char *'.

]

{ #category : #'type declaration' }
SlangTestSupportPlugin >> returnTypeByPragma [
	"SlangTestSupport asCString: #returnTypeByPragma"

	<returnTypeC: 'char *'>

]

{ #category : #'type declaration' }
SlangTestSupportPlugin >> varDefByMethod [
	"SlangTestSupport asCString: #varDefByMethod"

	| foo bar |
	self var: #foo type: 'char *'.
	self var: #bar declareC: 'unsigned int * bar'

]

{ #category : #'type declaration' }
SlangTestSupportPlugin >> varDefByMethodAndPragma [
	"SlangTestSupportPlugin asCString: #varDefByMethodAndPragma"

	| foo bar baz fum |
	<var: #baz type: 'float'>
	<var: #fum declareC: 'double fum'>
	self var: #foo type: 'char *'.
	self var: #bar declareC: 'unsigned int * bar'

]

{ #category : #'type declaration' }
SlangTestSupportPlugin >> varDefByPragma [
	"SlangTestSupport asCString: #varDefByPragma"

	| foo bar |
	<var: #foo type: 'char *'>
	<var: #bar declareC: 'unsigned int * bar'>

]
