Extension { #name : #CCodeGenerator }

{ #category : #'*SlangBrowser-C code generator' }
CCodeGenerator >> emitCCodeOn: aStream doAssertions: assertionFlag [
	"Emit C code for all methods in the code base onto the given stream. All inlined method calls should already have been expanded."

	self emitCHeaderOn: aStream.
	self emitCConstantsOn: aStream.
	self emitCFunctionPrototypes: preparedMethodList on: aStream.
	self emitCVariablesOn: aStream.
'Writing Translated Code...'
displayProgressAt: Sensor cursorPoint
from: 0 to: methods size
during: [:bar |
	preparedMethodList doWithIndex: [ :m :i | bar value: i.
		m emitCCodeOn: aStream generator: self.
]].
	self emitExportsOn: aStream.

]

{ #category : #'*SlangBrowser-C code generator' }
CCodeGenerator >> emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag [
	"Emit C code for all methods in the code base onto the given stream. All inlined method calls should already have been expanded."

	self prepareMethodsInlined: inlineFlag doAssertions: assertionFlag.
	^ self emitCCodeOn: aStream doAssertions: assertionFlag

]

{ #category : #'*SlangBrowser-C code generator' }
CCodeGenerator >> prepareMethodsInlined: inlineFlag doAssertions: assertionFlag [
	"Prepare to emit C code for all methods in the code base. All inlined method calls should be expanded. Answer a list of methods to be emitted as C code."

	| verbose methodList |
	"method preparation"
	verbose := false.
	self prepareMethods.
	verbose ifTrue: [
		self printUnboundCallWarnings.
		self printUnboundVariableReferenceWarnings.
		Transcript cr.
	].
	assertionFlag ifFalse: [ self removeAssertions ].
	self doInlining: inlineFlag.

	"code generation"

	methodList := methods asSortedCollection: [ :m1 :m2 | m1 selector < m2 selector ].
	"clean out no longer valid variable names and then handle any global
		variable usage in each method"
	methodList do: [:m | self checkForGlobalUsage: m removeUnusedTemps in: m].
	self localizeGlobalVariables.
	^ preparedMethodList := methodList

]
