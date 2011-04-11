"
The SlangTest tests verify code generation and inlining.

"
Class {
	#name : #SlangTest,
	#superclass : #TestCase,
	#category : #'VMMaker-Tests'
}

{ #category : #running }
SlangTest >> setUp [

	"Some of the test may be long running when SlangTestSupport is a subclass
	of ObjectMemory."
	(self respondsTo: #timeout: ) "Recent Squeak images with test case timeout"
		ifTrue: [self perform: #timeout: with: 30].
	VMMaker clearCacheEntriesFor: SlangTestSupportPlugin.
	VMMaker clearCacheEntriesFor: SlangTestSupportSSIP
]

{ #category : #'slang browser dependency' }
SlangTest >> testASlangBrowserInstalled [
	"The SlangBrowser package must be installed in order for these tests
	to run"

	self assert: (SlangTestSupportPlugin respondsTo: #asCString)
]

{ #category : #'testing interpreter' }
SlangTest >> testInterpDeclareExport [
	"Pragma declarations should generate the same C source code as the
	traditional method send declarations"

	| m p |
	m := (SlangTestSupportInterpreter asCString: #declareExportTrueByMethod)
			copyReplaceAll: 'declareExportTrueByMethod'
			with: 'methodName'.
	p := (SlangTestSupportInterpreter asCString: #declareExportTrueByPragma)
			copyReplaceAll: 'declareExportTrueByPragma'
			with: 'methodName'.
	self assert: m = p.

	m := (SlangTestSupportInterpreter asCString: #declareExportFalseByMethod)
			copyReplaceAll: 'declareExportFalseByMethod'
			with: 'methodName'.
	p := (SlangTestSupportInterpreter asCString: #declareExportFalseByPragma)
			copyReplaceAll: 'declareExportFalseByPragma'
			with: 'methodName'.
	self assert: m = p.
]

{ #category : #'testing interpreter' }
SlangTest >> testInterpDeclareInline [
	"Pragma declarations should generate the same C source code as the
	traditional method send declarations"

	| m p |
	m := ((SlangTestSupportInterpreter asInlinedCString: #inlineByMethod)
			copyReplaceAll: 'inlineByMethod'
			with: 'methodName')
				copyReplaceAll: 'methodThatShouldNotBeInlinedByMethod'
				with: 'calledMethodName'.
	p := ((SlangTestSupportInterpreter asInlinedCString: #inlineByPragma)
			copyReplaceAll: 'inlineByPragma'
			with: 'methodName')
				copyReplaceAll: 'methodThatShouldNotBeInlinedByPragma'
				with: 'calledMethodName'.
	self assert: m = p
]

{ #category : #'testing interpreter' }
SlangTest >> testInterpDeclareStatic [

	| m1 p1 m2 p2 |
	m1 := (SlangTestSupportInterpreter asCString: #declareStaticTrueByMethod)
			copyReplaceAll: 'declareStaticTrueByMethod'
			with: 'methodName'.
	p1 := (SlangTestSupportInterpreter asCString: #declareStaticTrueByPragma)
			copyReplaceAll: 'declareStaticTrueByPragma'
			with: 'methodName'.
	self assert: m1 = p1.

	m2 := (SlangTestSupportInterpreter asCString: #declareStaticFalseByMethod)
			copyReplaceAll: 'declareStaticFalseByMethod'
			with: 'methodName'.
	p2 := (SlangTestSupportInterpreter asCString: #declareStaticFalseByPragma)
			copyReplaceAll: 'declareStaticFalseByPragma'
			with: 'methodName'.
	self assert: m2 = p2.

	"verify that the keyword 'static appears in the generated C source"
	self assert: (m1 includesSubString: 'static').
	self assert: (p1 includesSubString: 'static').
	self deny: (m2 includesSubString: 'static').
	self deny: (p2 includesSubString: 'static')

]

{ #category : #'testing interpreter' }
SlangTest >> testInterpMixedMethodAndPragmaDeclarations [
	"Pragmas and method declarations should coexist"

	| s |
	s := (SlangTestSupportInterpreter asCString: #varDefByMethodAndPragma)
			copyReplaceAll: 'varDefByMethod'
			with: 'methodName'.
	self assert: (s includesSubString: 'unsigned int * bar').
	self assert: (s includesSubString: 'char *foo').
	self assert: (s includesSubString: 'float baz').
	self assert: (s includesSubString: 'double fum').

]

{ #category : #'testing interpreter' }
SlangTest >> testInterpReturnTypeC [
	"Pragma declarations should generate the same C source code as the
	traditional method send declarations"

	| m p |
	m := (SlangTestSupportInterpreter asCString: #returnTypeByMethod)
			copyReplaceAll: 'returnTypeByMethod'
			with: 'methodName'.
	p := (SlangTestSupportInterpreter asCString: #returnTypeByPragma)
			copyReplaceAll: 'returnTypeByPragma'
			with: 'methodName'.
	self assert: m = p
]

{ #category : #'testing interpreter' }
SlangTest >> testInterpTypeDeclarations [
	"Pragma declarations should generate the same C source code as the
	traditional method send declarations"

	| m p |
	m := (SlangTestSupportInterpreter asCString: #varDefByMethod)
			copyReplaceAll: 'varDefByMethod'
			with: 'methodName'.
	p := (SlangTestSupportInterpreter asCString: #varDefByPragma)
			copyReplaceAll: 'varDefByPragma'
			with: 'methodName'.
	self assert: m = p
]

{ #category : #'testing base plugins' }
SlangTest >> testPluginDeclareExport [
	"Pragma declarations should generate the same C source code as the
	traditional method send declarations"

	| m p |
	m := (SlangTestSupportPlugin asCString: #declareExportTrueByMethod)
			copyReplaceAll: 'declareExportTrueByMethod'
			with: 'methodName'.
	p := (SlangTestSupportPlugin asCString: #declareExportTrueByPragma)
			copyReplaceAll: 'declareExportTrueByPragma'
			with: 'methodName'.
	self assert: m = p.

	m := (SlangTestSupportPlugin asCString: #declareExportFalseByMethod)
			copyReplaceAll: 'declareExportFalseByMethod'
			with: 'methodName'.
	p := (SlangTestSupportPlugin asCString: #declareExportFalseByPragma)
			copyReplaceAll: 'declareExportFalseByPragma'
			with: 'methodName'.
	self assert: m = p.
]

{ #category : #'testing base plugins' }
SlangTest >> testPluginDeclareInline [
	"Pragma declarations should generate the same C source code as the
	traditional method send declarations"

	| m p |
	m := ((SlangTestSupportPlugin asInlinedCString: #inlineByMethod)
			copyReplaceAll: 'inlineByMethod'
			with: 'methodName')
				copyReplaceAll: 'methodThatShouldNotBeInlinedByMethod'
				with: 'calledMethodName'.
	p := ((SlangTestSupportPlugin asInlinedCString: #inlineByPragma)
			copyReplaceAll: 'inlineByPragma'
			with: 'methodName')
				copyReplaceAll: 'methodThatShouldNotBeInlinedByPragma'
				with: 'calledMethodName'.
	self assert: m = p
]

{ #category : #'testing base plugins' }
SlangTest >> testPluginDeclareStatic [

	| m1 p1 m2 p2 |
	m1 := (SlangTestSupportPlugin asCString: #declareStaticTrueByMethod)
			copyReplaceAll: 'declareStaticTrueByMethod'
			with: 'methodName'.
	p1 := (SlangTestSupportPlugin asCString: #declareStaticTrueByPragma)
			copyReplaceAll: 'declareStaticTrueByPragma'
			with: 'methodName'.
	self assert: m1 = p1.

	m2 := (SlangTestSupportPlugin asCString: #declareStaticFalseByMethod)
			copyReplaceAll: 'declareStaticFalseByMethod'
			with: 'methodName'.
	p2 := (SlangTestSupportPlugin asCString: #declareStaticFalseByPragma)
			copyReplaceAll: 'declareStaticFalseByPragma'
			with: 'methodName'.
	self assert: m2 = p2.

	"verify that the keyword 'static appears in the generated C source"
	self assert: (m1 includesSubString: 'static').
	self assert: (p1 includesSubString: 'static').
	self deny: (m2 includesSubString: 'static').
	self deny: (p2 includesSubString: 'static')

]

{ #category : #'testing base plugins' }
SlangTest >> testPluginMixedMethodAndPragmaDeclarations [
	"Pragmas and method declarations should coexist"

	| s |
	s := (SlangTestSupportPlugin asCString: #varDefByMethodAndPragma)
			copyReplaceAll: 'varDefByMethod'
			with: 'methodName'.
	self assert: (s includesSubString: 'unsigned int * bar').
	self assert: (s includesSubString: 'char *foo').
	self assert: (s includesSubString: 'float baz').
	self assert: (s includesSubString: 'double fum').

]

{ #category : #'testing base plugins' }
SlangTest >> testPluginReturnTypeC [
	"Pragma declarations should generate the same C source code as the
	traditional method send declarations"

	| m p |
	m := (SlangTestSupportPlugin asCString: #returnTypeByMethod)
			copyReplaceAll: 'returnTypeByMethod'
			with: 'methodName'.
	p := (SlangTestSupportPlugin asCString: #returnTypeByPragma)
			copyReplaceAll: 'returnTypeByPragma'
			with: 'methodName'.
	self assert: m = p
]

{ #category : #'testing base plugins' }
SlangTest >> testPluginTypeDeclarations [
	"Pragma declarations should generate the same C source code as the
	traditional method send declarations"

	| m p |
	m := (SlangTestSupportPlugin asCString: #varDefByMethod)
			copyReplaceAll: 'varDefByMethod'
			with: 'methodName'.
	p := (SlangTestSupportPlugin asCString: #varDefByPragma)
			copyReplaceAll: 'varDefByPragma'
			with: 'methodName'.
	self assert: m = p
]

{ #category : #'testing ssip plugins' }
SlangTest >> testSSIPDeclareExport [
	"Pragma declarations should generate the same C source code as the
	traditional method send declarations"

	| m p |
	m := (SlangTestSupportSSIP asCString: #declareExportTrueByMethod)
			copyReplaceAll: 'declareExportTrueByMethod'
			with: 'methodName'.
	p := (SlangTestSupportSSIP asCString: #declareExportTrueByPragma)
			copyReplaceAll: 'declareExportTrueByPragma'
			with: 'methodName'.
	self assert: m = p.

	m := (SlangTestSupportSSIP asCString: #declareExportFalseByMethod)
			copyReplaceAll: 'declareExportFalseByMethod'
			with: 'methodName'.
	p := (SlangTestSupportSSIP asCString: #declareExportFalseByPragma)
			copyReplaceAll: 'declareExportFalseByPragma'
			with: 'methodName'.
	self assert: m = p.
]

{ #category : #'testing ssip plugins' }
SlangTest >> testSSIPDeclareInline [
	"Pragma declarations should generate the same C source code as the
	traditional method send declarations"

	| m p |
	m := ((SlangTestSupportSSIP asInlinedCString: #inlineByMethod)
			copyReplaceAll: 'inlineByMethod'
			with: 'methodName')
				copyReplaceAll: 'methodThatShouldNotBeInlinedByMethod'
				with: 'calledMethodName'.
	p := ((SlangTestSupportSSIP asInlinedCString: #inlineByPragma)
			copyReplaceAll: 'inlineByPragma'
			with: 'methodName')
				copyReplaceAll: 'methodThatShouldNotBeInlinedByPragma'
				with: 'calledMethodName'.
	self assert: m = p
]

{ #category : #'testing ssip plugins' }
SlangTest >> testSSIPDeclareStatic [

	| m1 p1 m2 p2 |
	m1 := (SlangTestSupportSSIP asCString: #declareStaticTrueByMethod)
			copyReplaceAll: 'declareStaticTrueByMethod'
			with: 'methodName'.
	p1 := (SlangTestSupportSSIP asCString: #declareStaticTrueByPragma)
			copyReplaceAll: 'declareStaticTrueByPragma'
			with: 'methodName'.
	self assert: m1 = p1.

	m2 := (SlangTestSupportSSIP asCString: #declareStaticFalseByMethod)
			copyReplaceAll: 'declareStaticFalseByMethod'
			with: 'methodName'.
	p2 := (SlangTestSupportSSIP asCString: #declareStaticFalseByPragma)
			copyReplaceAll: 'declareStaticFalseByPragma'
			with: 'methodName'.
	self assert: m2 = p2.

	"verify that the keyword 'static appears in the generated C source"
	self assert: (m1 includesSubString: 'static').
	self assert: (p1 includesSubString: 'static').
	self deny: (m2 includesSubString: 'static').
	self deny: (p2 includesSubString: 'static')

]

{ #category : #'testing ssip plugins' }
SlangTest >> testSSIPMixedMethodAndPragmaDeclarations [
	"Pragmas and method declarations should coexist"

	| s |
	s := (SlangTestSupportSSIP asCString: #varDefByMethodAndPragma)
			copyReplaceAll: 'varDefByMethod'
			with: 'methodName'.
	self assert: (s includesSubString: 'unsigned int * bar').
	self assert: (s includesSubString: 'char *foo').
	self assert: (s includesSubString: 'float baz').
	self assert: (s includesSubString: 'double fum').

]

{ #category : #'testing ssip plugins' }
SlangTest >> testSSIPReturnTypeC [
	"Pragma declarations should generate the same C source code as the
	traditional method send declarations"

	| m p |
	m := (SlangTestSupportSSIP asCString: #returnTypeByMethod)
			copyReplaceAll: 'returnTypeByMethod'
			with: 'methodName'.
	p := (SlangTestSupportSSIP asCString: #returnTypeByPragma)
			copyReplaceAll: 'returnTypeByPragma'
			with: 'methodName'.
	self assert: m = p
]

{ #category : #'testing ssip plugins' }
SlangTest >> testSSIPTypeDeclarations [
	"Pragma declarations should generate the same C source code as the
	traditional method send declarations"

	| m p |
	m := (SlangTestSupportSSIP asCString: #varDefByMethod)
			copyReplaceAll: 'varDefByMethod'
			with: 'methodName'.
	p := (SlangTestSupportSSIP asCString: #varDefByPragma)
			copyReplaceAll: 'varDefByPragma'
			with: 'methodName'.
	self assert: m = p
]
