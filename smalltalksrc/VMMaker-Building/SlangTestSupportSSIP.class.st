"
SlangTestSupportSSIP implements translatable methods for use in SlangTest unit tests.
It is a subclass of SmartSyntaxInterpreterPlugin, which requires additional
test coverage.

	""VMMaker clearCacheEntriesFor: SlangTestSupportSSIP.
	SlangTestSupportSSIP asCString""
"
Class {
	#name : #SlangTestSupportSSIP,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : #'VMMaker-Tests'
}

{ #category : #'export declaration' }
SlangTestSupportSSIP >> declareExportFalseByMethod [
	"SlangTestSupportSSIP asCString: #declareExportFalseByMethod"

	self export: false

]

{ #category : #'export declaration' }
SlangTestSupportSSIP >> declareExportFalseByPragma [
	"SlangTestSupportSSIP asCString: #declareExportFalseByPragma"

	<export: false>

]

{ #category : #'export declaration' }
SlangTestSupportSSIP >> declareExportTrueByMethod [
	"SlangTestSupportSSIP asCString: #declareExportTrueByMethod"

	self export: true

]

{ #category : #'export declaration' }
SlangTestSupportSSIP >> declareExportTrueByPragma [
	"SlangTestSupportSSIP asCString: #declareExportTrueByPragma"

	<export: true>

]

{ #category : #'static declaration' }
SlangTestSupportSSIP >> declareStaticFalseByMethod [
	"SlangTestSupportSSIP asCString: #declareStaticFalseByMethod"

	self static: false

]

{ #category : #'static declaration' }
SlangTestSupportSSIP >> declareStaticFalseByPragma [
	"SlangTestSupportSSIP asCString: #declareStaticFalseByPragma"

	<static: false>

]

{ #category : #'static declaration' }
SlangTestSupportSSIP >> declareStaticTrueByMethod [
	"SlangTestSupportSSIP asCString: #declareStaticTrueByMethod"

	self static: true

]

{ #category : #'static declaration' }
SlangTestSupportSSIP >> declareStaticTrueByPragma [
	"SlangTestSupportSSIP asCString: #declareStaticTrueByPragma"

	<static: true>

]

{ #category : #inlining }
SlangTestSupportSSIP >> inlineByMethod [
	"SlangTestSupportSSIP asCString: #inlineByMethod"
	"SlangTestSupportSSIP asInlinedCString: #inlineByMethod"

	| bar foo |
	foo := self methodThatShouldBeInlinedByMethod.
	bar := self methodThatShouldNotBeInlinedByMethod
]

{ #category : #inlining }
SlangTestSupportSSIP >> inlineByPragma [
	"SlangTestSupportSSIP asCString: #inlineByPragma"
	"SlangTestSupportSSIP asInlinedCString: #inlineByPragma"

	| bar foo |
	foo := self methodThatShouldBeInlinedByPragma.
	bar := self methodThatShouldNotBeInlinedByPragma
]

{ #category : #inlining }
SlangTestSupportSSIP >> methodThatShouldBeInlinedByMethod [

	self inline: true.
	^ #foo
]

{ #category : #inlining }
SlangTestSupportSSIP >> methodThatShouldBeInlinedByPragma [

	<inline: true>
	^ #foo
]

{ #category : #inlining }
SlangTestSupportSSIP >> methodThatShouldNotBeInlinedByMethod [

	self inline: false.
	^ #bar
]

{ #category : #inlining }
SlangTestSupportSSIP >> methodThatShouldNotBeInlinedByPragma [

	<inline: false>
	^ #bar
]

{ #category : #'type declaration' }
SlangTestSupportSSIP >> returnTypeByMethod [
	"SlangTestSupportSSIP asCString: #returnTypeByMethod"

	self returnTypeC: 'char *'.

]

{ #category : #'type declaration' }
SlangTestSupportSSIP >> returnTypeByPragma [
	"SlangTestSupportSSIP asCString: #returnTypeByPragma"

	<returnTypeC: 'char *'>

]

{ #category : #'type declaration' }
SlangTestSupportSSIP >> varDefByMethod [
	"SlangTestSupportSSIP asCString: #varDefByMethod"

	| foo bar |
	self var: #foo type: 'char *'.
	self var: #bar declareC: 'unsigned int * bar'

]

{ #category : #'type declaration' }
SlangTestSupportSSIP >> varDefByMethodAndPragma [
	"SlangTestSupportSSIP asCString: #varDefByMethodAndPragma"

	| foo bar baz fum |
	<var: #baz type: 'float'>
	<var: #fum declareC: 'double fum'>
	self var: #foo type: 'char *'.
	self var: #bar declareC: 'unsigned int * bar'

]

{ #category : #'type declaration' }
SlangTestSupportSSIP >> varDefByPragma [
	"SlangTestSupportSSIP asCString: #varDefByPragma"

	| foo bar |
	<var: #foo type: 'char *'>
	<var: #bar declareC: 'unsigned int * bar'>

]
