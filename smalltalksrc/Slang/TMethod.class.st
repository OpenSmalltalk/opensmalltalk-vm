"
A TMethod is a translation method, representing a MethodNode that is to be translated to C source. It has a parseTree of translation nodes that mirrors the parse tree of the corresponding Smalltalk method.
"
Class {
	#name : #TMethod,
	#superclass : #Object,
	#instVars : [
		'args',
		'comment',
		'complete',
		'declarations',
		'definingClass',
		'export',
		'extraVariableNumber',
		'globalStructureBuildMethodHasFoo',
		'inline',
		'labels',
		'locals',
		'parseTree',
		'primitive',
		'properties',
		'returnType',
		'selector',
		'sharedCase',
		'sharedLabel',
		'static',
		'writtenToGlobalVarsCache',
		'functionAttributes',
		'usedVariablesCache'
	],
	#classVars : [
		'CaseStatements'
	],
	#category : #'Slang-AST'
}

{ #category : #'class initialization' }
TMethod class >> initialize [
	"TMethod initialize"	
	CaseStatements := IdentitySet new: 10.
	CaseStatements addAll: #(dispatchOn:in: dispatchOn:in:with: dispatchOn:in:with:with:).
]

{ #category : #accessing }
TMethod >> addFunctionAttribute: aString [
	functionAttributes := functionAttributes
							ifNil: [aString]
							ifNotNil: [functionAttributes, ' ', aString]
]

{ #category : #accessing }
TMethod >> addLabelsTo: aTMethod [
	aTMethod labels addAll: labels
]

{ #category : #initialization }
TMethod >> addTypeForSelf [
	"If self should be typed then add a suitable type declaration.
	 Preserve the flagging of an implicit self using the #implicit symbol as the fake type."
	self typeForSelf ifNotNil:
		[:typeForSelf|
		self declarationAt: 'self'
			put: (typeForSelf == #implicit
					ifTrue: [typeForSelf]
					ifFalse: [typeForSelf, ' self'])]
]

{ #category : #'type inference' }
TMethod >> addTypesFor: node to: typeSet in: aCodeGen [
	"Add the value types for the node to typeSet.
	 Answer if any type was derived from an as-yet-untyped method or variable, which allows us to abort
	 inferReturnTypeFromReturnsIn: if the return type depends on a yet-to-be-typed method or variable."
	| expr |
	expr := node.
	[expr isAssignment or: [expr isStmtList]] whileTrue:
		[expr isAssignment ifTrue:
			[expr := expr variable].
		 expr isStmtList ifTrue:
			[expr := expr statements last]].
	expr isSend ifTrue:
		[(#(ifTrue: ifFalse: ifTrue:ifFalse: ifFalse:ifTrue:) includes: expr selector) ifTrue:
			[^expr args
				inject: false
				into: [:asYetUntyped :block|
					asYetUntyped | (self addTypesFor: block to: typeSet in: aCodeGen)]].
		(aCodeGen returnTypeForSend: expr in: self ifNil: nil)
			ifNil: [^(aCodeGen methodNamed: expr selector) notNil and: [expr selector ~~ selector]]
			ifNotNil:
				[:type |
				typeSet add: type.
				^false]].
	expr isVariable ifTrue:
		[(aCodeGen typeOfVariable: expr name)
			ifNotNil: [:type| typeSet add: type]
			ifNil: [(typeSet add: (expr name = 'self'
										ifTrue: [#void]
										ifFalse: [#sqInt])) == #sqInt ifTrue:
					[^true]]].
	expr isConstant ifTrue:
		[(expr value isInteger and: [expr value >= 0]) "cannot determine if signed or unsigned yet..."
			ifTrue: [typeSet add: expr value]
			ifFalse:
				[(expr typeOrNilFrom: aCodeGen in: self) ifNotNil:
					[:type | typeSet add: type]]].
	^false
]

{ #category : #'inlining support' }
TMethod >> addVarsDeclarationsAndLabelsOf: methodToBeInlined except: doNotRename [
	"Prepare to inline the body of the given method into the receiver by making the args and locals of the argument to the receiver be locals of the receiver. Record any type declarations for these variables. Record labels. Assumes that the variables have already be renamed to avoid name clashes."

	locals
		addAll: (methodToBeInlined args reject: [ :v | doNotRename includes: v]);
		addAll: (methodToBeInlined locals reject: [ :v | doNotRename includes: v]).
	methodToBeInlined declarations keysAndValuesDo:
		[ :v :decl |
		(doNotRename includes: v) ifFalse:
			[self declarationAt: v put: decl]].

	labels addAll: methodToBeInlined labels
]

{ #category : #utilities }
TMethod >> allCalls [
	"Answer a collection of selectors for the messages sent by this method."

	^parseTree allCalls
]

{ #category : #accessing }
TMethod >> allLocals [
	"The merge of locals and declarations (don't ask)"

	^(declarations keys asSet reject: [:k| (declarations at: k) == #implicit])
		addAll: locals; yourself
]

{ #category : #accessing }
TMethod >> allReferencedVariablesUsing: aCodeGen [
	"Answer the set of all variables referenced in the receiver."
	| refs |
	refs := Set new.
	"Find all the variable names referenced in this method.
	 Don't descend into conditionals that won't be generated."
	parseTree
		nodesWithParentsDo:
			[:node :parent|
			node isVariable ifTrue: [refs add: node name asString].
			node isStmtList ifTrue: [refs addAll: node args].
			(node isSend
			 and: [node selector value beginsWith: #cCode:]) ifTrue:
				[aCodeGen addVariablesInVerbatimCIn: node to: refs]]
		unless:
			[:node :parent|
			parent notNil
			and: [parent isSend
			and: [aCodeGen nodeIsDeadCode: node withParent: parent]]].
	^refs
]

{ #category : #inlining }
TMethod >> argAssignmentsFor: meth send: aSendNode except: elidedArgs in: aCodeGen [
	"Return a collection of assignment nodes that assign the given argument expressions to the formal parameter variables of the given method."
	"Optimization: If the actual parameters are either constants or local variables in the target method (the receiver), substitute them directly into the body of meth. Note that global variables cannot be subsituted because the inlined method might depend on the exact ordering of side effects to the globals."

	| stmtList substitutionDict argList |
	meth args size > (argList := aSendNode args) size ifTrue:
		[self assert: (meth args first beginsWith: 'self_in_').
		 argList := {aSendNode receiver}, aSendNode args].
	
	stmtList := OrderedCollection new: argList size.
	substitutionDict := Dictionary new: argList size.
	meth args with: argList do:
		[:argName :exprNode |
		(self isNode: exprNode substitutableFor: argName inMethod: meth in: aCodeGen)
			ifTrue:
				[substitutionDict
					at: argName
					put: (aCodeGen
							node: exprNode
							typeCompatibleWith: argName
							inliningInto: meth
							in: self).
				 locals remove: argName ifAbsent: [self assert: (argName beginsWith: 'self_in_')].
				 declarations removeKey: argName ifAbsent: nil]
			ifFalse: "Add an assignment for anything except an unused self_in_foo argument"
				[(elidedArgs includes: argName) ifFalse:
					[stmtList addLast:
						(TAssignmentNode new
							setVariable: (TVariableNode new setName: argName)
							expression: (aCodeGen
											node: exprNode copy
											typeCompatibleWith: argName
											inliningInto: meth
											in: self))]]].
	meth parseTree: (meth parseTree bindVariablesIn: substitutionDict).
	^stmtList
]

{ #category : #'primitive compilation' }
TMethod >> argConversionExprFor: varName stackIndex: stackIndex [ 
	"Return the parse tree for an expression that fetches and converts the 
	primitive argument at the given stack offset."
	| exprList decl type stmtList |
	exprList := OrderedCollection new.
	((decl := declarations at: varName ifAbsent: []) notNil
	 and: ['int' ~= (type := (decl copyReplaceAll: varName with: '') withBlanksTrimmed)])
		ifTrue:
			[(decl includes: $*) ifTrue: "array"
				[(decl includesSubstring: 'char')
					ifTrue:
						[| expr |
						expr := '(interpreterProxy isBytes: (interpreterProxy stackValue: (stackIndex))) ifFalse: [^interpreterProxy primitiveFail]'.
						expr := expr copyReplaceAll: 'interpreterProxy' with: self vmNameString.
						expr := expr copyReplaceAll: 'stackIndex' with: stackIndex printString.
						exprList addLast: expr].
					exprList addLast: varName , ' := ', self vmNameString, ' arrayValueOf: (', self vmNameString, ' stackValue: (' , stackIndex printString , '))'.
					exprList addLast: varName , ' := ' , varName , ' - 1'] "so that varName[1] is the zero'th element"
				ifFalse: "must be a double"
					[type ~= 'double' ifTrue:
						[self error: 'unsupported type declaration in a translated primitive method'].
					 exprList addLast: varName , ' := ', self vmNameString, ' stackFloatValue: ' , stackIndex printString]]
			ifFalse: "undeclared variables are taken to be integer"
				[exprList addLast: varName , ' := ', self vmNameString, ' stackIntegerValue: ' , stackIndex printString].
	stmtList := OrderedCollection new.
	exprList do: [:e | stmtList addAll: (self statementsFor: e varName: varName)].
	^ stmtList
]

{ #category : #accessing }
TMethod >> args [
	"The arguments of this method."

	^args
]

{ #category : #transformations }
TMethod >> asInlineNode [
	^TInlineNode new method: self
]

{ #category : #transformations }
TMethod >> bindClassVariablesIn: constantDictionary [
	"Class variables are used as constants. This method replaces all references to class variables in the body of this method with the corresponding constant looked up in the class pool dictionary of the source class. The source class class variables should be initialized before this method is called."

	parseTree := parseTree bindVariablesIn: constantDictionary.
]

{ #category : #transformations }
TMethod >> bindVariableUsesIn: aDictionary [
	parseTree := parseTree bindVariableUsesIn: aDictionary.
]

{ #category : #transformations }
TMethod >> bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen [
	"Answer either the receiver, if it contains no references to the given variables, or a new node with the given variables rebound."
	| newParseTree |
	newParseTree := parseTree bindVariableUsesIn: aDictionary andConstantFoldIf: constantFold in: codeGen.
	^newParseTree = parseTree
		ifTrue: [self]
		ifFalse: [self shallowCopy
					parseTree: newParseTree;
					yourself]
]

{ #category : #transformations }
TMethod >> buildCaseStmt: aSendNode in: aCodeGen [
	"Build a case statement node for the given send of dispatchOn:in:."
	"Note: the first argument is the variable to be dispatched on. The second argument is a constant node holding an array of unary selectors, which will be turned into sends to self."

	| unimplemented errorMessage |
	(aSendNode args size >= 2
	 and: [aSendNode args second isConstant
	 and: [aSendNode args second value isArray]]) ifFalse:
		[self error: 'wrong node structure for a case statement'].

	unimplemented := aSendNode args second value select: [:s| (aCodeGen methodNamed: s) isNil].
	unimplemented isEmpty ifFalse:
		[errorMessage := 'The following selectors in case statement "', (aSendNode printString copyUpTo: $#), '..." are unimplemented: ',
							(String streamContents: [:s| unimplemented do: [:sel| s crtab; store: sel]]).
		 aCodeGen logger nextPutAll: errorMessage; cr; flush.
		 (self confirm: errorMessage
			orCancel: aCodeGen abortBlock) ifFalse:
				[self halt]].

	^TCaseStmtNode new
		setExpression: aSendNode args first
		selectors: aSendNode args second value
		arguments: (aSendNode args copyFrom: 3 to: aSendNode args size)
]

{ #category : #transformations }
TMethod >> buildSwitchStmt: aSendNode parent: parentNode [
	"Build a switch statement node for the given send of caseOf: or caseOf:otherwise:."
	| switch |
	switch := TSwitchStmtNode new
				expression: aSendNode receiver
				cases: aSendNode args first
				otherwiseOrNil: (aSendNode args at: 2 ifAbsent: [nil]).
	(aSendNode receiver isVariable or: [parentNode isStmtList]) ifFalse:
		[switch switchVariable: (locals add: (self extraVariableName: 'switch'))].
	^switch
]

{ #category : #'inlining support' }
TMethod >> checkForCompletenessIn: aCodeGen [
	"Set the complete flag if the parse tree contains no further candidates for inlining."
	| foundIncompleteSend incompleteSends |
	aCodeGen maybeBreakForTestOfInliningOf: selector.

	foundIncompleteSend := false.
	incompleteSends := IdentitySet new.

	parseTree
		nodesDo:
			[:node|
			 node isSend ifTrue:
				[(self methodIsEffectivelyComplete: node selector in: aCodeGen)
					ifTrue:
						[(self inlineableFunctionCall: node in: aCodeGen) ifTrue:
							[complete := false.  "more inlining to do"
							^self]]
					ifFalse:
						[foundIncompleteSend := true.
						 incompleteSends add: node]]]
		unless:
			[:node|
			node isSend
			and: [node selector == #cCode:inSmalltalk:
				or: [aCodeGen isAssertSelector: node selector]]].

	foundIncompleteSend ifFalse:
		[complete := true]
]

{ #category : #testing }
TMethod >> checkForRequiredInlinability [
	"This is used in methods answering inlinability.
	 Always answer false.  But if the receiver is marked as something that must be inlined (inline == #always) raise an error."
	(inline == #always and: [complete]) ifTrue:
		[self error: 'cannot inline method ', selector, ' marked as <inline: #always>'].
	^false
]

{ #category : #'primitive compilation' }
TMethod >> checkSuccessExpr [
	"Answer the parse tree for an expression that aborts the primitive if there has been a failure."
	^self
		statementsFor: 'interpreterProxy failed ifTrue: [^nil]'
		varName: ''
]

{ #category : #accessing }
TMethod >> checkedDeclarationAt: aVariableName put: aDeclaration in: aCCodeGen [
	((args includes: aVariableName)
	 or: [(locals includes: aVariableName)
	 or: [(definingClass instVarIndexFor: aVariableName asString ifAbsent: nil) notNil
	 or: [aDeclaration beginsWith: 'extern ']]]) ifFalse:
		[| msg |
		 msg := definingClass name, '>>', selector, ' contains declaration for non-existent variable ', aVariableName.
		 aCCodeGen
			ifNotNil: [aCCodeGen logger show: msg; cr]
			ifNil: [self error: msg]].
	^self declarationAt: aVariableName  "<String>" put: aDeclaration
]

{ #category : #accessing }
TMethod >> clearReferencesToGlobalStruct [
	globalStructureBuildMethodHasFoo := false
]

{ #category : #accessing }
TMethod >> comment [
	^comment
]

{ #category : #accessing }
TMethod >> comment: aComment [

	comment := aComment 
]

{ #category : #accessing }
TMethod >> compileTimeOptionPragmas: aCodeGenerator [
	"Answer the (possibly empty) sequence of option: or notOption: pragmas
	 whose arguments are values to be defined at compile time."

	^ self compiledMethod pragmas
		select: [ :pragma | 
			(#option: == pragma selector or: [ #notOption: == pragma selector ])
				and: [ aCodeGenerator defineAtCompileTime: (pragma argumentAt: 1) ] ]
]

{ #category : #accessing }
TMethod >> compiledMethod [
	^definingClass
		compiledMethodAt: selector
		ifAbsent: [definingClass compiledMethodAt: properties selector]
]

{ #category : #'inlining support' }
TMethod >> computePossibleSideEffectsInto: writtenToVars visited: visitedSelectors in: aCodeGen [
	"Add all variables written to by this method and its callees to writtenToVars.
	 Avoid circularity via visitedSelectors"

	(visitedSelectors includes: selector) ifTrue:
		[^self].
	visitedSelectors add: selector.
	writtenToGlobalVarsCache ifNotNil:
		[writtenToVars addAll: writtenToGlobalVarsCache.
		 ^self].
	parseTree nodesDo:
		[ :node |
			(node isAssignment
			 and: [(locals includes: node variable name) not])
				ifTrue:
					[writtenToVars add: node variable name].
			(node isSend
			 and: [node isBuiltinOperator not
			 and: [(aCodeGen isStructSend: node) not]]) ifTrue:
				[(aCodeGen methodNamed: node selector) ifNotNil:
					[:method|
					 method
						computePossibleSideEffectsInto: writtenToVars
						visited: visitedSelectors
						in: aCodeGen]]].
	writtenToGlobalVarsCache := writtenToVars copy
]

{ #category : #accessing }
TMethod >> declarationAt: aVariableName [
	self error: 'Use declarationAt: arg ifAbsent: [aCodeGen defaultType, '' '', arg] instead'.
	^declarations at: aVariableName ifAbsent: [#sqInt, ' ', aVariableName]
]

{ #category : #accessing }
TMethod >> declarationAt: aVariableName ifAbsent: absentBlock [
	^declarations at: aVariableName ifAbsent: absentBlock
]

{ #category : #accessing }
TMethod >> declarationAt: aVariableName  "<String>" put: aDeclaration [ "<String>" "^aDeclaration"
	^declarations at: aVariableName put: aDeclaration
]

{ #category : #accessing }
TMethod >> declarations [
	"The type declaration dictionary of this method."

	^declarations
]

{ #category : #testing }
TMethod >> definedAsMacro [
	^properties notNil
	  and: [(properties includesKey: #cmacro:)
		or: [properties includesKey: #cmacro]]
]

{ #category : #accessing }
TMethod >> definingClass [
	^definingClass
]

{ #category : #accessing }
TMethod >> definingClass: aClass [
	definingClass := aClass.
]

{ #category : #'error handling' }
TMethod >> deny: aBooleanOrBlock [
	<doNotGenerate>
	aBooleanOrBlock value ifTrue: [AssertionFailure signal: 'Assertion failed']
]

{ #category : #'C code generation' }
TMethod >> determineTypeFor: aNode in: aCodeGen [
	aNode isSend ifTrue:
		[^aCodeGen returnTypeForSend: aNode in: self ifNil: #sqInt].
	aNode isAssignment ifTrue:
		[^self determineTypeFor: aNode expression in: aCodeGen].
	self error: 'don''t know how to extract return type from this kind of node'
]

{ #category : #transformations }
TMethod >> elideAnyFinalReturn [
	"For super expansions we need to eliminate any final return to prevent premature exit.
	 Anything meaningful in the returned expression must be retained."

	| stmtList expr |
	stmtList := parseTree statements asOrderedCollection.
	stmtList last isReturn ifTrue:
		[expr := stmtList last expression.
		 (expr isVariable and: [expr name = 'self'])
			ifTrue: [stmtList := stmtList allButLast]
			ifFalse: [stmtList at: stmtList size put: expr].
		parseTree setStatements: stmtList]
]

{ #category : #'C code generation' }
TMethod >> emitCCodeOn: aStream generator: aCodeGen [
	"Emit C code for this method onto the given stream.
	 All calls to inlined methods should already have been expanded."
	| bodyStream conditional |

	aCodeGen currentMethod: self.
	usedVariablesCache := Set new.
	self emitCCommentOn: aStream.	"place method comment and method name before function."
	aStream crtab; nextPutAll: '/* '; nextPutAll: self definingClass name; nextPutAll: '>>#'; nextPutAll: self smalltalkSelector; nextPutAll: ' */'.	
	aStream cr. 
	conditional := self emitCFunctionPrototype: aStream generator: aCodeGen isPrototype: false.
	aStream cr; nextPut: ${.
	bodyStream := ReadWriteStream on: (ByteString new: 128).
	aCodeGen "Generation will note used variables in usedVariablesCache"
		pushScope: declarations
		while: [parseTree emitCCodeOn: bodyStream level: 1 generator: aCodeGen].
	self emitCLocalsOn: aStream generator: aCodeGen.
	usedVariablesCache := nil.
	aStream nextPutAll: bodyStream contents.
	(returnType = #void or: [parseTree endsWithReturn]) ifFalse:
		[aStream tab; nextPutAll: 'return 0;'; cr].
	aStream nextPut: $}; cr.
	conditional ifTrue:
		[self terminateConditionalDefineFor: (self compileTimeOptionPragmas: aCodeGen) on: aStream]
]

{ #category : #'C code generation' }
TMethod >> emitCCommentOn: aStream [
	"Emit the transferred Smalltalk comments as C comments."

	comment ifNotNil: [
		aStream cr;cr.
		1 to: comment size do: [:index | | startPos |
			aStream nextPutAll: '/*'; tab.
			startPos := aStream position.
			self printSingleComment: (comment at: index)
				on: aStream
				indent: 1
				tabWidth: 4
				lineBreak: 78.
			aStream position - startPos > (comment at: index) size ifTrue: "probably a multi-line comment"
				[aStream cr].
			aStream nextPutAll: ' */'; cr]]
]

{ #category : #'C code generation' }
TMethod >> emitCFunctionPrototype: aStream generator: aCodeGen [
	"Emit a C function header for this method onto the given stream."

	properties ifNotNil:
		[(properties at: #api: ifAbsent: []) ifNotNil:
			[:pragma|
			aStream
				nextPutAll: (pragma argumentAt: 1);
				nextPut: $;;
				cr.
			^self]].
	self emitCFunctionPrototype: aStream generator: aCodeGen isPrototype: true
]

{ #category : #'C code generation' }
TMethod >> emitCFunctionPrototype: aStream generator: aCodeGen isPrototype: isPrototype [ "<Boolean>"
	"Emit a C function header for this method onto the given stream.
	 Answer if the method has any compileTimeOptionPragmas"
	| compileTimeOptionPragmas returnTypeIsFunctionPointer |
	(compileTimeOptionPragmas := (self compileTimeOptionPragmas: aCodeGen)) notEmpty ifTrue:
		[self outputConditionalDefineFor: compileTimeOptionPragmas on: aStream].
	returnTypeIsFunctionPointer := returnType notNil
									and: [returnType last = $)
									and: [returnType includesSubstring: (aCodeGen cFunctionNameFor: selector)]].
	export 
		ifTrue:
			[aStream nextPutAll: 'EXPORT('; nextPutAll: returnType; nextPut: $)]
		ifFalse:
			[self isStatic
				ifTrue: [aStream nextPutAll: 'static ']
				ifFalse:
					[isPrototype ifTrue:
						[aStream nextPutAll: 'extern ']].
			 (isPrototype or: [inline ~~ #always]) ifFalse: [aStream nextPutAll: 'inline '].
			 aStream nextPutAll: (returnType ifNil: [#sqInt])].
	(functionAttributes isNil or: [returnTypeIsFunctionPointer]) ifFalse:
		[aStream space; nextPutAll: functionAttributes].
	isPrototype ifTrue: [aStream space] ifFalse: [aStream cr].
	returnTypeIsFunctionPointer ifFalse:
		[aStream
			nextPutAll: (aCodeGen cFunctionNameFor: selector);
			nextPut: $(.
		args isEmpty
			ifTrue: [aStream nextPutAll: #void]
			ifFalse:
				[args
					do: [:arg| aStream nextPutAll: (self
							declarationAt: arg
							ifAbsent: [aCodeGen defaultType, ' ', arg])]
					separatedBy: [aStream nextPutAll: ', ']].
		aStream nextPut: $)].
	isPrototype ifTrue:
		[aStream nextPut: $;; cr.
		 compileTimeOptionPragmas isEmpty ifFalse:
			[aCodeGen maybeEmitPrimitiveFailureDefineFor: selector on: aStream.
			 self terminateConditionalDefineFor: compileTimeOptionPragmas on: aStream]].
	^compileTimeOptionPragmas notEmpty
]

{ #category : #'C code generation' }
TMethod >> emitCLocalsOn: aStream generator: aCodeGen [
	"Emit a C function header for this method onto the given stream."

	| volatileVariables maybeExternFunctions |
	volatileVariables := properties includesKey: #volatile.
	self refersToGlobalStruct ifTrue:
		[aStream
			next: 3 put: Character space; "there's already an opening ${ on this line; see sender"
			nextPutAll: (volatileVariables
						ifTrue: ['DECL_MAYBE_VOLATILE_SQ_GLOBAL_STRUCT']
						ifFalse: ['DECL_MAYBE_SQ_GLOBAL_STRUCT'])].
	aStream cr.
	maybeExternFunctions := (declarations select: [:decl| decl beginsWith: 'extern']) keys.
	(locals isEmpty and: [maybeExternFunctions isEmpty]) ifFalse:
		[(aCodeGen sortStrings: locals, maybeExternFunctions) do:
			[ :var | | decl |
			decl := self declarationAt: var
							ifAbsent: [aCodeGen defaultType, ' ', var].
			(volatileVariables
			 or: [(decl beginsWith: 'static')
			 or: [(decl beginsWith: 'extern')
			 or: [usedVariablesCache includes: var]]]) ifTrue:
				[aStream next: 4 put: Character space.
				 volatileVariables ifTrue:
					[aStream nextPutAll: #volatile; space].
				 aStream
					nextPutAll: decl;
					nextPut: $;;
					cr]].
		 aStream cr]
]

{ #category : #'C code generation' }
TMethod >> emitInlineOn: aStream level: level generator: aCodeGen [
	"Emit C code for this method onto the given stream. All calls to inlined methods should already have been expanded."
	self removeUnusedTempsAndNilIfRequiredIn: aCodeGen.
	sharedLabel ifNotNil:
		[aStream crtab: level-1; nextPutAll: sharedLabel; nextPut: $:.
		aStream crtab: level.
		aStream nextPutAll: '/* '; nextPutAll: selector; nextPutAll: ' */'.
		aStream crtab: level].
	aStream nextPut: ${.
	locals isEmpty ifFalse:
		[(aCodeGen sortStrings: locals) do:
			[:var|
			 aStream
				crtab: level+1;
				nextPutAll: (self declarationAt: var ifAbsent: [ aCodeGen defaultType, ' ', var]);
				nextPut: $;].
			 aStream cr].
	aStream crtab: level+1.
	aCodeGen outputAsmLabel: selector on: aStream.
	aStream crtab: level+1.
	aCodeGen
		pushScope: declarations
		while: [parseTree emitCCodeOn: aStream level: level+1 generator: aCodeGen].
	aStream tab: level; nextPut: $}
]

{ #category : #'C code generation' }
TMethod >> emitProxyFunctionPrototype: aStream generator: aCodeGen [
	"Emit an indirect C function header for this method onto the given stream."

	aStream
		nextPutAll: returnType;
		space;
		nextPutAll: '(*';
		nextPutAll: (aCodeGen cFunctionNameFor: selector);
		nextPutAll: ')('.
	args isEmpty
		ifTrue: [aStream nextPutAll: #void]
		ifFalse:
			[args
				do: [:arg| aStream nextPutAll: (self declarationAt: arg)]
				separatedBy: [ aStream nextPutAll: ', ' ]].
	aStream nextPut: $)
]

{ #category : #testing }
TMethod >> endsWithReturn [
	"Answer true if the last statement of this method is a return."

	^parseTree endsWithReturn
]

{ #category : #inlining }
TMethod >> ensureConditionalAssignmentsAreTransformedIn: aCodeGen [
	"Make passes transforming
		foo := expr ifTrue: [a] ifFalse: [b]
	 into
		expr ifTrue: [foo := a] ifFalse: [foo := b]
	 until no such instances exist in the tree.  This is needed for correct inlining
	 given the limitations of inlineCodeOrNilForStatement:returningNodes:in:"
	| transformedAssignments |
	[transformedAssignments := Dictionary new.
	 parseTree
		nodesDo:
			[:node|
			(self transformConditionalAssignment: node in: aCodeGen) ifNotNil:
				[:replacement|
				 transformedAssignments at: node put: replacement]]
		unless: "Don't inline the arguments to asserts to keep the asserts readable"
			[:node|
			node isSend
			and: [node selector == #cCode:inSmalltalk:
				or: [aCodeGen isAssertSelector: node selector]]].
	 transformedAssignments notEmpty
	 and: [self replaceNodesIn: transformedAssignments.
		  true]] whileTrue
		
]

{ #category : #transformations }
TMethod >> ensureToByDoLoopLimitIsSafeAndEfficient: node in: aCodeGen [
	"For both safety and efficiency, make sure that to:[by:]do: loops
	 with complex limits have a variable to hold the limit expression.
	 In C the limit expression is evaluated each time round the loop
	 so if the loop has side-effects (which it usually will), the C compiler
	 may not be able to optimize the limit expression itself."
	| limitExpr hasSideEffects |
	 limitExpr := node args first.
	 hasSideEffects := limitExpr anySatisfy:
						[:subNode|
						subNode isSend
						and: [(aCodeGen isBuiltinSelector: subNode selector) not
						and: [(aCodeGen isStructSend: subNode) not]]].
	 node args size = 4
		ifTrue:
			[hasSideEffects
				ifTrue: [locals add: node args last name]
				ifFalse: [node arguments: node args allButLast]]
		ifFalse: "If the expression is complex but as yet there is no limit variable, add it"
			[hasSideEffects ifTrue:
				[| var |
				 var := self unusedNamePrefixedBy: 'toDoLimit' avoiding: locals. "N.B. adds it to locals!!"
				 node arguments: node args, {TVariableNode new setName: var; yourself}.
				 declarations
					at: node args third args first
					ifPresent: [:decl| self declarationAt: var put: (self typeFor: node args third args first in: aCodeGen), ' ', var]]]
]

{ #category : #inlining }
TMethod >> exitVar: exitVar label: exitLabel [
	"Replace each return statement in this method with an assignment to the
	 exit variable followed by either a return or a goto to the given label.
	 Answer if a goto was generated."
	"Optimization: If exitVar is nil, the return value of the inlined method is not being used, so don't add the assignment statement."

	| labelUsed map elisions eliminateReturnSelfs |
	labelUsed := false.
	map := Dictionary new.
	elisions := Set new.
	"Conceivably one might ^self from a struct class and mean it.  In most cases though
	 ^self means `get me outta here, fast'.  So unless this method is from a VMStruct class,
	 elide any ^self's"
	eliminateReturnSelfs := ((definingClass inheritsFrom: SlangClass) and: [definingClass isStructClass]) not
							  and: [returnType = #void or: [returnType = #sqInt]].
	parseTree nodesDo:
		[:node | | replacement |
		node isReturn ifTrue:
			[self transformReturnSubExpression: node
				toAssignmentOf: exitVar
				andGoto: exitLabel
				unless: eliminateReturnSelfs
				into: [:rep :labelWasUsed|
					replacement := rep.
					labelWasUsed ifTrue: [labelUsed := true]].
			"replaceNodesIn: is strictly top-down, so any replacement for ^expr ifTrue: [...^fu...] ifFalse: [...^bar...]
			 will prevent replacement of either ^fu or ^bar. The corollary is that ^expr ifTrue: [foo] ifFalse: [^bar]
			 must be transformed into expr ifTrue: [^foo] ifFalse: [^bar]"
			(node expression isConditionalSend
			 and: [node expression hasExplicitReturn])
				ifTrue:
					[elisions add: node.
					 (node expression args reject: [:arg| arg endsWithReturn]) do:
						[:nodeNeedingReturn|
						 self transformReturnSubExpression: nodeNeedingReturn statements last
							toAssignmentOf: exitVar
							andGoto: exitLabel
							unless: eliminateReturnSelfs
							into: [:rep :labelWasUsed|
								replacement := rep.
								labelWasUsed ifTrue: [labelUsed := true]].
						 map
							at: nodeNeedingReturn statements last
							put: replacement]]
				ifFalse:
					[map
						at: node
						put: (replacement ifNil:
								[TLabeledCommentNode new setComment: 'return ', node expression printString])]]].
	map isEmpty ifTrue:
		[self deny: labelUsed.
		 ^false].
	"Now do a top-down replacement for all returns that should be mapped to assignments and gotos"
	parseTree replaceNodesIn: map.
	"Now it is safe to eliminate the returning ifs..."
	elisions isEmpty ifFalse:
		[| elisionMap |
		 elisionMap := Dictionary new.
		 elisions do: [:returnNode| elisionMap at: returnNode put: returnNode expression].
		 parseTree replaceNodesIn: elisionMap].
	"Now flatten any new statement lists..."
	parseTree nodesDo:
		[:node| | list |
		(node isStmtList
		 and: [node statements notEmpty
		 and: [node statements last isStmtList]]) ifTrue:
			[list := node statements last statements.
			 node statements removeLast; addAllLast: list]].
	^labelUsed
]

{ #category : #accessing }
TMethod >> export [

	^ export

]

{ #category : #accessing }
TMethod >> export: aBoolean [
	export := aBoolean
]

{ #category : #initialization }
TMethod >> extraVariableName: root [
	extraVariableNumber := extraVariableNumber
								ifNil: [0]
								ifNotNil: [extraVariableNumber + 1].
	^root, extraVariableNumber printString
]

{ #category : #transformations }
TMethod >> extraVariableNumber [
	^extraVariableNumber
]

{ #category : #transformations }
TMethod >> extractDirective: theSelector valueBlock: aBlock default: defaultResult [
	"Find a pragma of the form:

		<theSelector[args]>

	 Answer the result of evaluating aBock with a TSendNode corresponding
	 to the pragma node, or defaultResult if there is no matching pragma."

	| result found newStatements |
	(properties at: theSelector ifAbsent: [  ]) ifNotNil: [ :pragma | 
		^ aBlock value: (TSendNode new
				   setSelector: pragma selector
				   receiver: (TVariableNode new setName: 'self')
				   arguments: (pragma arguments collect: [ :const | 
						    TConstantNode new setValue: const ])) ].
	"Pre-pragma backward compatibility:
	 Scan the top-level statements for a labelling directive of the form:

		self theSelector[args]

	 and remove the directive from the method body if found.
	 Answer the result of evaluating aBock with the send node,
	  or defaultResult if there is no labelling directive."
	result := defaultResult.
	found := false.
	newStatements := OrderedCollection new: parseTree statements size.
	parseTree statements do: [ :stmt | 
		(stmt isSend and: [ stmt selector = theSelector ])
			ifTrue: [ 
				found := true.
				result := aBlock value: stmt ]
			ifFalse: [ newStatements add: stmt ] ].
	^ found
		  ifTrue: [ 
			  parseTree setStatements: newStatements asArray.
			  result ]
		  ifFalse: [ defaultResult ]
]

{ #category : #transformations }
TMethod >> extractExpandCaseDirective [
	"Scan the top-level statements for an inlining directive of the form:
		self expandCases
	 and remove the directive from the method body. Answer whether
	 there was such a directive."

	^self
		extractDirective: #expandCases
		valueBlock: [:sendNode| true]
		default: false
]

{ #category : #transformations }
TMethod >> extractExportDirective [
	"Scan the top-level statements for an inlining directive of the form:

		self export: <boolean>

	 and remove the directive from the method body. Answer the
	 argument of the directive or false if there is no export directive."

	^self
		extractDirective: #export:
		valueBlock: [:sendNode| sendNode args first value ~= false]
		default: false
]

{ #category : #'inlining support' }
TMethod >> extractInlineDirective [
	"Scan the pragmas (or top-level statements) for an inlining directive of the form:

		<inline: <boolean|#never|#dontCare|#asSpecified|#always>

	 Answer a boolean equivalent to the argument of the directive or #dontCare if there is no inlining directive."

	sharedCase ifNotNil: [^false]. "don't auto-inline shared code; it gets handled specially"
	^self
		extractDirective: #inline:
		valueBlock:
			[:sendNode| #(true always) includes: (inline := sendNode args first value)]
		default: #dontCare
]

{ #category : #transformations }
TMethod >> extractSharedCase [
	"Scan the pragmas for an shared case directive of the form:
		<sharedCodeNamed: 'sharedLabel' inCase: 'sharedCase'.>
		<sharedCodeInCase: 'sharedCase'.>
	or the older top-level statements for the form
		self sharedCodeNamed: 'sharedLabel' inCase: 'sharedCase'.
		self sharedCodeInCase: 'sharedCase'.
	in which case remove the directive from the method body."

	self extractDirective: #sharedCodeNamed:inCase:
		valueBlock: [:sendNode|
			args isEmpty ifFalse:
				[self error: 'Cannot share code sections in methods with arguments'].
			sharedLabel := sendNode args first value.
			sharedCase := sendNode args last value]
		default: nil.
	self extractDirective: #sharedCodeInCase:
		valueBlock: [:sendNode|
			args isEmpty ifFalse:
				[self error: 'Cannot share code sections in methods with arguments'].
			sharedLabel := selector.
			sharedCase := sendNode args last value]
		default: nil
]

{ #category : #transformations }
TMethod >> extractStaticDirective [
	"Scan the top-level statements for an inlining directive of the form:

		self static: <boolean>

	 and remove the directive from the method body. Answer the
	 argument of the directive or true if there is no static directive."

	^self
		extractDirective: #static:
		valueBlock: [:sendNode| sendNode args first value ~= false]
		default: (export or: [ self isAPIMethod ]) not
]

{ #category : #'primitive compilation' }
TMethod >> fetchRcvrExpr [
	"Return the parse tree for an expression that fetches the receiver from the stack."

	| expr |
	expr := 'rcvr := ', self vmNameString, ' stackValue: (', args size printString, ')'.
	^ self statementsFor: expr varName: ''

]

{ #category : #utilities }
TMethod >> findReadBeforeAssignedIn: variables in: aCodeGen [
	| readBeforeAssigned |
	readBeforeAssigned := Set new.
	parseTree
		addReadBeforeAssignedIn: variables
		to: readBeforeAssigned
		assignments: Set new
		in: aCodeGen.
	^readBeforeAssigned
]

{ #category : #'primitive compilation' }
TMethod >> fixUpReturns: argCount postlog: postlog [
	"Replace each return statement in this method with (a) the given postlog, (b) code to pop the receiver and the given number of arguments, and (c) code to push the integer result and return."

	| newStmts |
	parseTree nodesDo: [:node |
		node isStmtList ifTrue: [
			newStmts := OrderedCollection new: 100.
			node statements do: [:stmt |
				stmt isReturn
					ifTrue: [
						(stmt expression isSend and:
						 ['primitiveFail' = stmt expression selector])
							ifTrue: [  "failure return"
								newStmts addLast: stmt expression.
								newStmts addLast: (TReturnNode new
									setExpression: (TVariableNode new setName: 'null'))]
							ifFalse: [  "normal return"
								newStmts addAll: postlog.
								newStmts addAll: (self popArgsExpr: argCount + 1).
								newStmts addLast: (TSendNode new
									setSelector: #pushInteger:
									receiver: (TVariableNode new setName: self vmNameString)
									arguments: (Array with: stmt expression)).
								newStmts addLast: (TReturnNode new
									setExpression: (TVariableNode new setName: 'null'))]]
					ifFalse: [
						newStmts addLast: stmt]].
			node setStatements: newStmts asArray]].

]

{ #category : #utilities }
TMethod >> freeVariableReferences [
	"Answer a collection of variables referenced this method, excluding locals, arguments, and pseudovariables."

	| refs |
	refs := Set new.
	parseTree nodesDo: [ :node |
		node isVariable ifTrue: [ refs add: node name asString ].
	].
	args do: [ :var | refs remove: var asString ifAbsent: [] ].
	locals do: [ :var | refs remove: var asString ifAbsent: [] ].
	#('self' 'nil' 'true' 'false') do: [ :var | refs remove: var ifAbsent: [] ].
	^refs
]

{ #category : #accessing }
TMethod >> functionAttributes [
	^functionAttributes
]

{ #category : #accessing }
TMethod >> functionAttributes: aString [
	functionAttributes := aString
]

{ #category : #'type inference' }
TMethod >> harmonizeSignedAndUnsignedTypesIn: aSetOfTypes [
	"Eliminate signed/unsigned conflicts in aSetOfTypes"
	| sqs usqs |
	#(char short int #'unsigned char' #'unsigned short' #'unsigned int')
		with: #(sqInt sqInt sqInt #usqInt #usqInt #usqInt)
		do: [:type :replacement|
			(aSetOfTypes includes: type) ifTrue:
				[aSetOfTypes remove: type; add: replacement]].
	sqs := aSetOfTypes select: [:t| t beginsWith: 'sq'].
	usqs := aSetOfTypes select: [:t| t beginsWith: 'usq'].
	^(sqs size + usqs size = aSetOfTypes size
	   and: [sqs notEmpty
	   and: [sqs allSatisfy: [:t| usqs includes: 'u', t]]])
		ifTrue: [sqs]
		ifFalse: [aSetOfTypes]
]

{ #category : #utilities }
TMethod >> hasMoreSendsThan: nSends [
	"Answer the number of nodes in this method's parseTree (a rough measure of its size)."

	| cnt |
	cnt := 0.
	parseTree nodesDo:
		[:node|
		(node isSend
		 and: [(cnt := cnt + 1) >= nSends]) ifTrue:
			[^true]].
	^false
]

{ #category : #testing }
TMethod >> hasProperties [
	^properties notNil and: [properties notEmpty]
]

{ #category : #testing }
TMethod >> hasReturn [
	"Answer true if this method contains a return statement."

	parseTree nodesDo: [ :n | n isReturn ifTrue: [ ^ true ]].
	^ false
]

{ #category : #utilities }
TMethod >> hasUnrenamableCCode [
	"Answer true if the receiver uses inlined C which
	 is not currently renamed properly by the the inliner."

	^parseTree anySatisfy:
		[:node| node isNonNullCCode]
]

{ #category : #'inlining support' }
TMethod >> incompleteSendsIn: aCodeGen [
	"Debugging support; answer the incomplete and inlineable sends in the receiver."
	| incompleteSends inlineableSends |
	aCodeGen maybeBreakForTestOfInliningOf: selector.

	incompleteSends := IdentitySet new.
	inlineableSends := IdentitySet new.

	parseTree
		nodesDo:
			[:node|
			 node isSend ifTrue:
				[(self methodIsEffectivelyComplete: node selector in: aCodeGen)
					ifTrue:
						[(self inlineableFunctionCall: node in: aCodeGen) ifTrue:
							[inlineableSends add: node]]
					ifFalse:
						[incompleteSends add: node]]]
		unless:
			[:node|
			node isSend
			and: [node selector == #cCode:inSmalltalk:
				or: [aCodeGen isAssertSelector: node selector]]].

	^{incompleteSends. inlineableSends}
]

{ #category : #'type inference' }
TMethod >> inferReturnTypeFromReturnsIn: aCodeGen [
	"Attempt to infer the return type of the receiver from returns in the parse tree."

	"this for determining which returns have which return types:"
	"aCodeGen
		pushScope: declarations
		while: [parseTree
				nodesSelect: [:n| n isReturn]
				thenCollect: [:n| | s |
					s := Set new.
					self addTypesFor: n expression to: s in: aCodeGen.
					{n. s}]]"

	aCodeGen maybeBreakForTestToInline: selector in: self.
	returnType ifNotNil: [^self].
	aCodeGen
		pushScope: declarations
		while:
			[| hasReturn returnTypes |
			 hasReturn := false.
			 returnTypes := Set new.
			 "Debug:
			 (| rettypes |
			  rettypes := Dictionary new.
			  parseTree nodesDo:
				[:node|
				node isReturn ifTrue:
					[| types |
					 self addTypesFor: node expression to: (types := Set new) in: aCodeGen.
					 rettypes at: node expression put: types]].
			  rettypes)"
			 parseTree nodesDo:
				[:node|
				node isReturn ifTrue:
					[hasReturn := true.
					 "If we encounter a send of an as-yet-untyped method then abort,
					  retrying and computing the type when that method is fully typed."
					 (self addTypesFor: node expression to: returnTypes in: aCodeGen) ifTrue:
						[^self]]].
			returnTypes remove: #implicit ifAbsent: [].
			returnTypes := aCodeGen harmonizeReturnTypesIn: returnTypes.
			hasReturn
				ifTrue:
					[returnTypes size > 1 ifTrue:
						[| message |
						 message := String streamContents:
										[:s|
										 s nextPutAll: 'conflicting return types '.
										 returnTypes
											do: [:t| s nextPutAll: t]
											separatedBy: [s nextPutAll: ', '].
										 s nextPutAll: ' in '; nextPutAll: selector; cr].
						 Notification signal: message.
						 aCodeGen logger ensureCr; show: message].
					 returnTypes size = 1 ifTrue:
						[self returnType: returnTypes anyOne]]
				ifFalse:
					[self returnType: (aCodeGen implicitReturnTypeFor: selector)]]
]

{ #category : #'type inference' }
TMethod >> inferReturnTypeIn: aCodeGen [
	"Attempt to infer the return type of the receiver and answer if it changed."

	| existingReturnType |
	existingReturnType := returnType.
	self inferReturnTypeFromReturnsIn: aCodeGen.
	^existingReturnType ~= returnType
]

{ #category : #accessing }
TMethod >> inline [
	^inline
]

{ #category : #accessing }
TMethod >> inline: aBoolean [
	inline := aBoolean
]

{ #category : #inlining }
TMethod >> inlineBuiltin: aSendNode in: aCodeGen [
	| sel meth inlinedReplacement |
	(aSendNode selector beginsWith: 'perform:') ifTrue:
		[^self inlineFunctionCall: aSendNode asTransformedConstantPerform in: aCodeGen].
	sel := aSendNode receiver selector.
	meth := aCodeGen methodNamed: sel.
	(meth notNil and: [meth inline == true]) ifFalse: [^nil].
	(meth isFunctionalIn: aCodeGen) ifTrue:
		[inlinedReplacement := (aCodeGen methodNamed: aSendNode receiver selector) copy
									inlineFunctionCall: aSendNode receiver
									in: aCodeGen.
		 ^TSendNode new
			setSelector: aSendNode selector
			receiver: inlinedReplacement
			arguments: aSendNode args copy].
	(self isInlineableConditional: aSendNode in: aCodeGen) ifTrue:
		[^self inlineConditional: aSendNode in: aCodeGen].
	^nil
]

{ #category : #inlining }
TMethod >> inlineCaseStatementBranchesIn: aCodeGen localizingVars: varsList [ 
	| maxTemp usedVars v exitLabel |
	maxTemp := 0.
	parseTree nodesDo:
		[:n |
		n isCaseStmt ifTrue:
			[n cases do:
				[:stmtNode | | newStatements stmt meth |
				(stmt := stmtNode statements first) isSend ifTrue:
					[(meth := (aCodeGen methodNamed: stmt selector)) isNil ifFalse:
						[(meth hasUnrenamableCCode
						   or: [meth args notEmpty]) ifFalse:
							[meth := meth copy.
							 meth hasReturn
								ifTrue:
									[exitLabel := meth unusedLabelForInliningInto: self.
									 meth exitVar: nil label: exitLabel.
									 labels add: exitLabel]
								ifFalse: [exitLabel := nil].
							meth renameLabelsForInliningInto: self.
							labels addAll: meth labels.
							newStatements := stmtNode statements asOrderedCollection allButFirst.
							exitLabel ifNotNil:
								[newStatements addFirst: (TLabeledCommentNode new
																setLabel: exitLabel
																comment: 'end case')].
							newStatements
								addFirst: meth asInlineNode;
								addFirst: (TLabeledCommentNode new setComment: meth selector).
							stmtNode setStatements: newStatements]]]]]].
	usedVars := (locals , args) asSet.
	1 to: maxTemp do:
		[:i |
		v := 't' , i printString.
		(usedVars includes: v) ifTrue:
			[self error: 'temp variable name conflicts with an existing local or arg'].
		locals addLast: v].
	"make local versions of the given globals"
	locals addAll: (varsList reject: [:var | usedVars includes: var])
]

{ #category : #inlining }
TMethod >> inlineCodeOrNilForStatement: aNode returningNodes: returningNodes in: aCodeGen [
	"If the given statement node can be inlined, answer the statements that replace it. Otherwise, answer nil."

	| stmts |
	(aNode isReturn
	 and: [self inlineableSend: aNode expression in: aCodeGen]) ifTrue:
		[stmts := self inlineSend: aNode expression
						directReturn: true exitVar: nil in: aCodeGen.
		stmts last endsWithReturn ifFalse:
			[stmts at: stmts size put: stmts last asReturnNode].
		^stmts].
	(aNode isAssignment
	 and: [self inlineableSend: aNode expression in: aCodeGen]) ifTrue:
		[^self inlineSend: aNode expression
				directReturn: false exitVar: aNode variable name in: aCodeGen].
	(aNode isSend
	 and: [self inlineableSend: aNode in: aCodeGen]) ifTrue:
		[^self inlineSend: aNode
				directReturn: (returningNodes includes: aNode) exitVar: nil in: aCodeGen].
	^nil
]

{ #category : #inlining }
TMethod >> inlineConditional: aSendNode in: aCodeGen [
	"If possible answer the inlining of a conditional, otherwise answer nil.
	 Currently the only pattern we support is
		aSend ifTrue:/ifFalse: [...]
	 where aSend is marked inline and always answers booleans."
	self assert: (self isInlineableConditional: aSendNode in: aCodeGen).
	self assert: aSendNode args first isStmtList.
	^(aSendNode args first statements size = 1
	  and: [aSendNode args first statements first isReturn])
		ifTrue: [self inlineReturningConditional: aSendNode in: aCodeGen]
		ifFalse: [self inlineGuardingConditional: aSendNode in: aCodeGen]
]

{ #category : #inlining }
TMethod >> inlineFunctionCall: aSendNode in: aCodeGen [
	"Answer the body of the called function, substituting the actual
	 parameters for the formal argument variables in the method body.
	 Assume caller has established that:
		1. the method arguments are all substitutable nodes, and
		2. the method to be inlined contains no additional embedded returns."

	| sel meth doNotRename argsForInlining substitutionDict |
	sel := aSendNode selector.
	meth := (aCodeGen methodNamed: sel) copy.
	meth ifNil:
		[^self inlineBuiltin: aSendNode in: aCodeGen].
	doNotRename := Set withAll: args.
	argsForInlining := aSendNode argumentsForInliningCodeGenerator: aCodeGen.
	meth args with: argsForInlining do:
		[ :argName :exprNode |
		exprNode isLeaf ifTrue:
			[doNotRename add: argName]].
	(meth statements size = 2
	and: [meth statements first isSend
	and: [meth statements first selector == #flag:]]) ifTrue:
		[meth statements removeFirst].
	meth renameVarsForInliningInto: self except: doNotRename in: aCodeGen.
	meth renameLabelsForInliningInto: self.
	self addVarsDeclarationsAndLabelsOf: meth except: doNotRename.
	substitutionDict := Dictionary new: meth args size * 2.
	meth args with: argsForInlining do:
		[ :argName :exprNode |
		substitutionDict at: argName put: exprNode.
		(doNotRename includes: argName) ifFalse:
			[locals remove: argName]].
	meth parseTree bindVariablesIn: substitutionDict.
	^meth parseTree endsWithReturn
		ifTrue: [meth parseTree copyWithoutReturn]
		ifFalse: [meth parseTree]
]

{ #category : #inlining }
TMethod >> inlineGuardingConditional: aSendNode in: aCodeGen [
	"Inline
		aSend ifTrue:/ifFalse: [statements]
	 where aSend is inlineable and always answers booleans.  We convert
	 the boolean returns in aSend to jumps."
	| evaluateIfTrue replacementTree map lastNode evaluateLabel skipLabel method |
	self assert: self == aCodeGen currentMethod.
	self assert: (self isInlineableConditional: aSendNode in: aCodeGen).
	aCodeGen maybeBreakForInlineOf: aSendNode in: self.
	evaluateIfTrue := aSendNode selector = #ifTrue:.
	method := (aCodeGen methodNamed: aSendNode receiver selector) copy.
	replacementTree := method inlineFunctionCall: aSendNode receiver in: aCodeGen.
	map := Dictionary new.
	(replacementTree statements last isReturn
	 and: [replacementTree statements last expression value = evaluateIfTrue]) ifTrue:
		[lastNode := replacementTree statements last].
	skipLabel := TLabeledCommentNode new setLabel:
					(self unusedLabelForInlining: method).
	replacementTree nodesDo:
		[:node| | expr |
		 node isReturn ifTrue:
			[expr := node expression.
			 self assert: (expr isConstant and: [#(true false) includes: expr value]).
			 map
				at: node
				put: (expr value ~~ evaluateIfTrue
						ifTrue: [TGoToNode new setLabel: skipLabel label]
						ifFalse:
							[node == lastNode
								ifTrue: [TLabeledCommentNode new setComment: 'end ', aSendNode receiver selector, '; fall through']
								ifFalse:
									[evaluateLabel ifNil:
										[evaluateLabel := TLabeledCommentNode new setLabel:
													(self unusedLabelForInlining: method)].
									 TGoToNode new setLabel: evaluateLabel label]])]].
	replacementTree replaceNodesIn: map.
	replacementTree comment: {'inline ', aSendNode receiver selector}.
	self addVarsDeclarationsAndLabelsOf: method except: method args.
	^TStmtListNode new
		setArguments: #()
		statements:
			(evaluateLabel
				ifNil: [replacementTree statements, aSendNode args first statements, {skipLabel}]
				ifNotNil:
					[replacementTree statements, {evaluateLabel}, aSendNode args first statements, {skipLabel}])
]

{ #category : #inlining }
TMethod >> inlineReturningConditional: aSendNode in: aCodeGen [
	"Inline
		aSend ifTrue:/ifFalse: [^expr]
	 where aSend is inlineable and always answers booleans.  We inline ^expr
	 into aSend."
	| returnIfTrue returnNode replacementTree map lastNode label method |
	self assert: self == aCodeGen currentMethod.
	self assert: (self isInlineableConditional: aSendNode in: aCodeGen).
	aCodeGen maybeBreakForInlineOf: aSendNode receiver in: self.
	returnIfTrue := aSendNode selector = #ifTrue:.
	returnNode := aSendNode args first.
	method := (aCodeGen methodNamed: aSendNode receiver selector) copy.
	replacementTree := method inlineFunctionCall: aSendNode receiver in: aCodeGen.
	map := Dictionary new.
	"The last node is either a return or a boolean constant."
	lastNode := replacementTree statements last.
	replacementTree statements last isReturn
		ifTrue:
			[replacementTree statements last expression value == returnIfTrue ifTrue:
				[lastNode := nil "i.e. take the fall-through path and /don't/ return"]]
		ifFalse:
			[self assert: (lastNode isConstant and: [#(true false) includes: lastNode value]).
			 lastNode value == returnIfTrue ifTrue: "i.e. /do/ return"
				[map at: lastNode put: returnNode]].
	replacementTree nodesDo:
		[:node| | expr |
		 node isReturn ifTrue:
			[expr := node expression.
			 self assert: (expr isConstant and: [#(true false) includes: expr value]).
			 map
				at: node
				put: (expr value == returnIfTrue
						ifTrue: [returnNode]
						ifFalse:
							[node == lastNode
								ifTrue: [TLabeledCommentNode new setComment: 'end ', aSendNode receiver selector, '; fall through']
								ifFalse:
									[label ifNil:
										[label := TLabeledCommentNode new setLabel:
													(self unusedLabelForInlining: method)].
									 TGoToNode new setLabel: label label]])]].
	replacementTree replaceNodesIn: map.
	self addVarsDeclarationsAndLabelsOf: method except: method args.
	replacementTree comment: {'inline ', aSendNode receiver selector}.
	^label
		ifNil: [replacementTree]
		ifNotNil:
			[TStmtListNode new
				setArguments: #()
				statements: {replacementTree. label}]
]

{ #category : #inlining }
TMethod >> inlineSend: aSendNode directReturn: directReturn exitVar: exitVar in: aCodeGen [
	"Answer a collection of statements to replace the given send.  directReturn indicates
	 that the send is the expression in a return statement, so returns can be left in the
	 body of the inlined method. If exitVar is nil, the value returned by the send is not
	 used; thus, returns need not assign to the output variable.

	 Types are propagated to as-yet-untyped variables when inlining a send that is assigned,
	 otherwise the assignee variable type must match the return type of the inlinee.  Return
	 types are not propagated."

	| sel meth methArgs exitLabel inlineStmts label exitType elidedArgs |
	sel := aSendNode selector.
	meth := aCodeGen methodNamed: sel.
	methArgs := meth args.
	"convenient for debugging..."
	aCodeGen maybeBreakForInlineOf: aSendNode in: self.
	elidedArgs := #().
	(methArgs notEmpty and: [methArgs first beginsWith: 'self_in_'])
		ifTrue: "If the first arg is not used we can and should elide it."
			[| varNode |
			 varNode := TVariableNode new setName: methArgs first.
			 (meth parseTree noneSatisfy: [:node| varNode isSameAs: node]) ifTrue:
				[elidedArgs := {methArgs first}].
			 methArgs := methArgs allButFirst].
	methArgs size = aSendNode args size ifFalse:
		[^nil].
	meth := meth copy.

	(meth statements size > 1
	 and: [meth statements first isSend
	 and: [meth statements first selector == #flag:]]) ifTrue:
		[meth statements removeFirst].

	"Propagate the return type of an inlined method"
	(directReturn or: [exitVar notNil]) ifTrue:
		[exitType := directReturn 
						ifTrue: [returnType] 
						ifFalse: [(self typeFor: exitVar in: aCodeGen) ifNil: [#sqInt]].
		(exitType = #void or: [exitType = meth returnType]) ifFalse:
			[meth propagateReturnIn: aCodeGen]].

	"Propagate any unusual argument types to untyped argument variables"
	methArgs
		with: aSendNode args
		do: [:formal :actual|
			(meth declarationAt: formal ifAbsent: nil) ifNil:
				[(self typeFor: actual in: aCodeGen) ifNotNil:
					[:type|
					type ~= #sqInt ifTrue:
						[meth declarationAt: formal put: (type last = $* ifTrue: [type, formal] ifFalse: [type, ' ', formal])]]]].

	meth renameVarsForInliningInto: self except: elidedArgs in: aCodeGen.
	meth renameLabelsForInliningInto: self.
	self addVarsDeclarationsAndLabelsOf: meth except: elidedArgs.
	meth hasReturn ifTrue:
		[directReturn ifFalse:
			[exitLabel := self unusedLabelForInliningInto: self.
			 (meth exitVar: exitVar label: exitLabel) "is label used?"
				ifTrue: [ labels add: exitLabel ]
				ifFalse: [ exitLabel := nil ]]].
	(inlineStmts := OrderedCollection new: meth statements size + meth args size + 2)
		add: (label := TLabeledCommentNode new setComment: 'begin ', sel);
		addAll: (self argAssignmentsFor: meth send: aSendNode except: elidedArgs in: aCodeGen);
		addAll: meth statements.  "method body"
	directReturn ifTrue:
		[meth endsWithReturn
			ifTrue:
				[exitVar ifNotNil: "don't remove the returns if being invoked in the context of a return"
					[inlineStmts at: inlineStmts size put: inlineStmts last copyWithoutReturn]]
			ifFalse:
				[inlineStmts add:
					(TReturnNode new setExpression: (TVariableNode new setName: 'nil'))]].
	exitLabel ifNotNil:
		[inlineStmts add:
			(TLabeledCommentNode new setLabel:
				exitLabel comment: 'end ', meth selector)].
	inlineStmts size = 1 ifTrue: "Nuke empty methods; e.g. override of flushAtCache"
		[self assert: inlineStmts first isComment.
		 inlineStmts removeFirst].
	^inlineStmts
]

{ #category : #inlining }
TMethod >> inlineableFunctionCall: aNode in: aCodeGen [
	"Answer if the given send node is a call to a 'functional' method--a method whose body is a single return statement of some expression and whose actual parameters can all be directly substituted."

	aCodeGen maybeBreakForTestToInline: aNode in: self.
	aNode isSend ifFalse:
		[^false].
	^(aCodeGen methodNamed: aNode selector)
		ifNil:
			[aNode asTransformedConstantPerform
				ifNil: [self isInlineableConditional: aNode in: aCodeGen]
				ifNotNil: [:n| self inlineableFunctionCall: n in: aCodeGen]]
		ifNotNil:
			[:m|
			 (m ~~ self
			  and: [((m isFunctionalIn: aCodeGen) or: [m mustBeInlined and: [m isComplete]])
			  and: [m mayBeInlined
			  and: [(aCodeGen mayInline: m selector)
			  and: [aNode args allSatisfy: [:a| self isSubstitutableNode: a intoMethod: m in: aCodeGen]]]]])
			 or: [m checkForRequiredInlinability]]
]

{ #category : #inlining }
TMethod >> inlineableSend: aNode in: aCodeGen [
	"Answer if the given send node is a call to a method that can be inlined."

	| m |
	aCodeGen maybeBreakForTestToInline: aNode in: self.
	aNode isSend ifFalse: [^false].
	m := aCodeGen methodNamed: aNode selector.  "nil if builtin or external function"
	^m ~= nil
	 and: [m ~~ self
	 and: [m mayBeInlined
	 and: [(m isComplete and: [aCodeGen mayInline: m selector])
		or: [m checkForRequiredInlinability]]]]
]

{ #category : #'primitive compilation' }
TMethod >> instVarGetExprFor: varName offset: instIndex [
	"Return the parse tree for an expression that fetches and converts the value of the instance variable at the given offset."

	| exprList decl stmtList |
	exprList := OrderedCollection new.
	(declarations includesKey: varName) ifTrue: [
		decl := declarations at: varName.
		(decl includes: $*) ifTrue: [  "array"
			exprList add:
				(varName, ' := ', self vmNameString, ' fetchArray: ', instIndex printString, ' ofObject: rcvr').
			exprList add: (varName, ' := ', varName, ' - 1').
		] ifFalse: [  "must be a double"
			((decl findString: 'double' startingAt: 1) = 0)
				ifTrue: [ self error: 'unsupported type declaration in a primitive method' ].
			exprList add:
				(varName, ' := ', self vmNameString, ' fetchFloat: ', instIndex printString, ' ofObject: rcvr').
		].
	] ifFalse: [  "undeclared variables are taken to be integer"
		exprList add:
			(varName, ' := ', self vmNameString, ' fetchInteger: ', instIndex printString, ' ofObject: rcvr').
	].
	stmtList := OrderedCollection new.
	exprList do: [:e | stmtList addAll: (self statementsFor: e varName: varName)].
	^ stmtList

]

{ #category : #'primitive compilation' }
TMethod >> instVarPutExprFor: varName offset: instIndex [
	"Return the parse tree for an expression that saves the value of the integer instance variable at the given offset."

	| expr |
	(declarations includesKey: varName) ifTrue: [
		self error: 'a primitive method can only modify integer instance variables'.
	].
	expr := '', self vmNameString, ' storeInteger: ', instIndex printString, ' ofObject: rcvr withValue: ', varName.
	^ self statementsFor: expr varName: varName

]

{ #category : #testing }
TMethod >> isAPIMethod [
	^properties notNil
	  and: [(properties includesKey: #api)
			or: [properties includesKey: #api:]]
]

{ #category : #testing }
TMethod >> isAssertion [
	^(selector beginsWith: 'assert') or: [selector beginsWith: 'verify']
]

{ #category : #accessing }
TMethod >> isComplete [
	"A method is 'complete' if it does not contain any more inline-able calls."

	^complete
]

{ #category : #inlining }
TMethod >> isConditionalToBeTransformedForAssignment: aSend in: aCodeGen [
	"Answer if a send is of the form
		e1
			ifTrue: [e2 ifTrue: [self m1] ifFalse: [self m2]]
			ifFalse: [self m3]
	 such that at least one of the sends mN may be inlined.."

	^(#(ifTrue:ifFalse: ifFalse:ifTrue:) includes: aSend selector)
	   and: [aSend args anySatisfy:
			[:arg| | stmt |
			self assert: arg isStmtList.
			arg statements size > 1
			or: [(stmt := arg statements first) isSwitch
			or: [stmt isSend
				and: [(aCodeGen mayInline: stmt selector)
					or: [self isConditionalToBeTransformedForAssignment: stmt in: aCodeGen]]]]]]
]

{ #category : #inlining }
TMethod >> isFunctionalIn: aCodeGen [
	"Answer if the receiver is a functional method. That is, if it
	 consists of a single return statement of an expression that
	 contains no other returns, or an assert or flag followed by
	 such a statement.

	 Answer false for methods with return types other than the simple
	 integer types to work around bugs in the inliner."

	parseTree statements size = 1 ifFalse:
		[(parseTree statements size = 2
		  and: [parseTree statements first isSend
		  and: [parseTree statements first selector == #flag:
			or: [(aCodeGen isAssertSelector: parseTree statements first selector)
				and: [parseTree statements first selector ~~ #asserta:]]]]) ifFalse:
			[^false]].
	parseTree statements last isReturn ifFalse:
		[^false].
	parseTree statements last expression nodesDo:
		[ :n | n isReturn ifTrue: [^false]].
	^#(int #'unsigned int' #long #'unsigned long' #'long long' #'unsigned long long'
		sqInt usqInt #'sqIntptr_t' #'usqIntptr_t' sqLong usqLong
		#'int *' #'unsigned int *' #'sqInt *' #'usqInt *' #'sqLong *' #'usqLong *' #'char *'
		#'CogMethod *' #'AbstractInstruction *'
		#'FILE *') includes: returnType
]

{ #category : #inlining }
TMethod >> isInlineableConditional: aSendNode in: aCodeGen [
	"Answer if the given send node is of the form aSend [ifTrue:|ifFalse:] [statements]
	 where the method for aSend is marked as inline and all returns within it answer booleans."
	|method |
	^(#(ifTrue: ifFalse:) includes: aSendNode selector)
	  and: [aSendNode receiver isSend
	  and: [(method := aCodeGen anyMethodNamed: aSendNode receiver selector) notNil
	  and: [method inline == true
	  and: [method parseTree statements last isReturn
	  and: [method parseTree allSatisfy:
			[:node|
			 node isReturn not
			 or: [node expression isConstant
				 and: [#(true false) includes: node expression value]]]]]]]]
]

{ #category : #inlining }
TMethod >> isNode: aNode substitutableFor: argName inMethod: targetMeth in: aCodeGen [
	"Answer if the given parameter node may be substituted directly into the body of
	 the method during inlining, instead of being bound to the actual parameter variable.
	 We allow a constant, a local variable, or a formal parameter, or simple expressions
	 involving only these to to be directly substituted. Note that global variables cannot
	 be subsituted into methods with possible side effects (i.e., methods that may assign
	 to global variables) because the inlined method might depend on having the value of
	 the global variable captured when it is passed in as an argument."

	| madeNonTrivialCall count constantExpression usageCount |
	aNode isConstant ifTrue: [^true].

	aNode isVariable ifTrue:
		[((locals includes: aNode name)
		 or: [(args includes: aNode name)
		 or: [#('self' 'true' 'false' 'nil') includes: aNode name]]) ifTrue: [^true].
		"We can substitute any variable provided it is only read in the method being inlined,
		 and if it is not read after any non-trivial call (which may update the variable)."
		madeNonTrivialCall := false.
		(targetMeth isComplete
		 and: [targetMeth parseTree
				noneSatisfy:
					[:node|
					 (node isSend
					  and: [(aCodeGen isBuiltinSelector: node selector) not]) ifTrue:
						[madeNonTrivialCall := true].
					 (madeNonTrivialCall and: [node isVariable and: [node name = argName]])
					 or: [node isAssignment
						  and: [node variable name = argName]]]
				unless:
					[:node|
					node isSend and: [aCodeGen isAssertSelector: node selector]]]) ifTrue:
			[^true].
		^targetMeth maySubstituteGlobal: aNode name in: aCodeGen].

	"don't much up asserts with complex expansions"
	(targetMeth usesVariableUninlinably: argName in: aCodeGen) ifTrue:
		[^false].

	"For now allow literal blocks to be substituted.  They better be accessed only
	 with value[:value:*] messages though!"
	aNode isStmtList ifTrue: [^true].

	"Don't inline expressions unless type-compatible,"
	aNode isSend ifTrue:
		[(aCodeGen
				isActualType: (aCodeGen returnTypeForSend: aNode in: self ifNil: #incompatible)
				compatibleWithFormalType: (self typeFor: argName in: aCodeGen)) ifFalse:
			[^false]].

	count := 0.
	constantExpression := true.
	"scan expression tree; must contain only constants, builtin ops, and inlineable vars"
	aNode nodesDo:
		[:node|
		node isConstant
			ifTrue: [] ifFalse:
		[node isSend
			ifTrue:
				[((aCodeGen mostBasicConstantSelectors includes: node selector)
				  or: [node isBuiltinOperator]) ifFalse: [^false].
				 count := count + 1] ifFalse:
		[node isVariable ifTrue:
			[(aCodeGen isNonArgumentImplicitReceiverVariableName: node name) ifFalse:
				[constantExpression := false.
				((locals includes: node name)
				 or: [(args includes: node name)
				 or: [(#('self' 'true' 'false' 'nil') includes: node name)
				 or: [targetMeth maySubstituteGlobal: node name in: aCodeGen]]]) ifFalse: [^false]]] ifFalse:
		[^false]]]].
	"inline constant expressions"
	constantExpression ifNil: [^true].

	"scan target to find usage count"
	usageCount := 0.
	targetMeth parseTree nodesDo:
		[:node|
		(node isVariable and: [node name = argName]) ifTrue:
			[usageCount := usageCount + 1]].
	"(usageCount > 1 and: [count <= usageCount]) ifTrue:
		[[UsageCounts := Dictionary new.
		  self removeClassVarName: #UsageCounts].
		 (UsageCounts at: usageCount ifAbsentPut: [Set new]) add: ({targetMeth. argName. aNode})]."
	"Now only inline expressions if they are used only once or are simple
	 w.r.t. the usage count, and the usage count is not large; a heuristic that seems to work well enough."
	^usageCount = 1 or: [usageCount <= 7 and: [count <= usageCount]]
]

{ #category : #testing }
TMethod >> isRealMethod [
	^(self definedAsMacro or: [self isStructAccessor]) not
]

{ #category : #testing }
TMethod >> isReturnConstant [
	^parseTree statements size = 1
	 and: [parseTree statements last isReturn
	 and: [parseTree statements last expression isLeaf]]
]

{ #category : #accessing }
TMethod >> isStatic [
	^static ifNil:[false].
]

{ #category : #testing }
TMethod >> isStructAccessor [
	^[definingClass isAccessor: selector]
		on: MessageNotUnderstood
		do: [:ex| false]
]

{ #category : #inlining }
TMethod >> isSubstitutableNode: aNode intoMethod: targetMeth in: aCodeGen [
	"Answer true if the given parameter node is either a constant, a local variable, or a formal parameter of the receiver. Such parameter nodes may be substituted directly into the body of the method during inlining. Note that global variables cannot be subsituted into methods with possible side effects (i.e., methods that may assign to global variables) because the inlined method might depend on having the value of the global variable captured when it is passed in as an argument."

	| var |
	aNode isConstant ifTrue: [ ^ true ].

	aNode isVariable ifTrue: [
		var := aNode name.
		((locals includes: var) or: [args includes: var]) ifTrue: [ ^ true ].
		(#(self true false nil) includes: var) ifTrue: [ ^ true ].
		(targetMeth maySubstituteGlobal: var in: aCodeGen) ifTrue: [ ^ true ].
	].

	"For now allow literal blocks to be substituted.  They better be accessed only
	 with value[:value:*] messages though!"
	aNode isStmtList ifTrue: [^true].

	(aNode isSend
	 and: [aNode numArgs = 0
	 and: [aCodeGen isStructSend: aNode]]) ifTrue:
		[^true].

	"scan expression tree; must contain only constants, builtin ops, and inlineable vars"
	aNode nodesDo: [ :node |
		node isSend ifTrue: [
			(node isBuiltinOperator
			 or: [node numArgs = 0
				 and: [aCodeGen isStructSend: node]]) ifFalse: [ ^false ].
		].
		node isVariable ifTrue: [
			var := node name.
			((locals includes: var) or:
			 [(args includes: var) or:
			 [(#(self true false nil) includes: var) or:
			 [targetMeth maySubstituteGlobal: var in: aCodeGen]]]) ifFalse: [ ^ false ].
		].
		(node isConstant or: [node isVariable or: [node isSend]]) ifFalse: [ ^false ].
	].

	^ true
]

{ #category : #testing }
TMethod >> isTMethod [
	^true
]

{ #category : #accessing }
TMethod >> labels [

	^labels
]

{ #category : #accessing }
TMethod >> labels: aCollection [

	labels := aCollection asSet
]

{ #category : #accessing }
TMethod >> locals [
	"The local variables of this method."

	^locals
]

{ #category : #transformations }
TMethod >> mapSendsFromSelfToInterpreterProxy: selectors [
	| interpreterProxyNode |
	interpreterProxyNode := TVariableNode new setName: 'interpreterProxy'.
	parseTree nodesDo:
		[:node|
		(node isSend
		and: [node receiver isVariable
		and: [node receiver name = 'self'
		and: [selectors includes: node selector]]]) ifTrue:
			[node receiver: interpreterProxyNode]]
]

{ #category : #accessing }
TMethod >> mayBeInlined [
	^inline == true or: [inline == nil or: [inline == #always]]
]

{ #category : #'inlining support' }
TMethod >> maySubstituteGlobal: globalVar in: aCodeGen [
	"We can substitute globalVar into this method provided globalVar is only read, not written."

	writtenToGlobalVarsCache = nil ifTrue:
		[self computePossibleSideEffectsInto: (Set new: 50) visited: (Set new: 50) in: aCodeGen].
	^(writtenToGlobalVarsCache includes: globalVar) not
]

{ #category : #inlining }
TMethod >> mergePropertiesOfSuperMethod: superTMethod [
	superTMethod hasProperties ifFalse:
		[^self].
	self hasProperties ifFalse:
		[properties := superTMethod properties.
		 ^self].
	superTMethod properties pragmas do:
		[:aPragma|
		(self shouldIncorporatePragmaFromSuperMethod: aPragma) ifTrue:
			[properties := properties copyWith: aPragma]]
]

{ #category : #'inlining support' }
TMethod >> methodIsEffectivelyComplete: selector in: aCodeGen [
	"Answer if selector is effectively not inlineable in the receiver.
	 This is tricky because block inlining requires that certain methods must be inlined, which
	 can be at odds wuth the opportunistic strategy the inliner takes.  Since the inliner only
	 inlines complete methods and certain methods may never be marked as complete (e.g.
	 recursive methods) we have to short-cut certain kinds of send.  In particular, short-cut
	 sends that turn into jumps in the interpret routine (sharedCase and sharedLabel below)."
	^(aCodeGen methodNamed: selector)
		ifNil: [true] "builtins or externals are not inlineable"
		ifNotNil:
			[:m|
			 m isComplete
			 "unlinable methods can't be inlined"
			 or: [m mayBeInlined not
			 "Methods which are inlined as jumps don't need inlining"
			 or: [m sharedCase notNil or: [m sharedLabel notNil]]]]
]

{ #category : #accessing }
TMethod >> mustBeInlined [
	^inline == #always
]

{ #category : #initialization }
TMethod >> newCascadeTempFor: aTParseNode [
	| varName varNode |
	varName := self extraVariableName: 'cascade'.
	varNode := TVariableNode new setName: varName.
	aTParseNode isLeaf ifFalse:
		[self
			declarationAt: varName
			put: [:tm :cg| | type |
				type := tm determineTypeFor: aTParseNode in: cg.
				(SlangStructType structTargetKindForType: type) == #struct ifTrue:
					["can't copy structs into cascade temps; the struct is not updated.
					  must change to a pointer."
					type := type, ' *'.
					parseTree nodesDo:
						[:node|
						(node isAssignment
						 and: [node variable name = varName]) ifTrue:
							[node setExpression: (TSendNode new
													setSelector: #addressOf:
													receiver: (TVariableNode new setName: 'self')
													arguments: {node expression})]]].
				type]].
	^varNode
]

{ #category : #accessing }
TMethod >> newDeclarations: aDictionary [
	declarations := aDictionary
]

{ #category : #utilities }
TMethod >> nodeCount [
	"Answer the number of nodes in this method's parseTree (a rough measure of its size)."

	| cnt |
	cnt := 0.
	parseTree nodesDo: [ :n | cnt := cnt + 1 ].
	^cnt
]

{ #category : #utilities }
TMethod >> noteUsedVariableName: token [
	usedVariablesCache ifNotNil:
		[usedVariablesCache add: token]
]

{ #category : #private }
TMethod >> oopVariable: aString [

	(locals includes: aString) ifFalse:
		[locals add: aString.
		self declarationAt: aString put: 'sqInt ', aString].
	^TVariableNode new setName: aString
]

{ #category : #'C code generation' }
TMethod >> outputConditionalDefineFor: compileTimeOptionPragmas on: aStream [
	aStream nextPutAll: '#if '.
	compileTimeOptionPragmas
		do: [ :pragma | 
			pragma selector = #notOption:
				ifTrue: [ aStream nextPut: $! ].
			aStream nextPutAll: (pragma argumentAt: 1) ]
		separatedBy: [ aStream nextPutAll: ' && ' ].
	aStream cr
]

{ #category : #accessing }
TMethod >> parseTree [
	"The parse tree of this method."

	^parseTree
]

{ #category : #accessing }
TMethod >> parseTree: aNode [
	"Set the parse tree of this method."

	parseTree := aNode.
]

{ #category : #'primitive compilation' }
TMethod >> popArgsExpr: argCount [
	"Return the parse tree for an expression that pops the given number of arguments from the stack."

	| expr |
	expr := '', self vmNameString, ' pop: ', argCount printString.
	^ self statementsFor: expr varName: ''

]

{ #category : #copying }
TMethod >> postCopy [
	args := args copy.
	locals := locals copy.
	declarations := declarations copy.
	parseTree := parseTree copy.
	labels := labels copy
]

{ #category : #transformations }
TMethod >> prepareMethodIn: aCodeGen [
	"Record sends of builtin operators, map sends of the special selector dispatchOn:in:
	 with case statement nodes, and map sends of caseOf:[otherwise:] to switch statements.
	 Declare limit variables for to:[by:]do: loops with limits that potentially have side-effects.
	 As a hack also update the types of variables introduced to implement cascades correctly.
	 This has to be done at the same time as this is done, so why not piggy back here?"
	extraVariableNumber ifNotNil:
		[declarations keysAndValuesDo:
			[:varName :decl|
			decl isBlock ifTrue:
				[self assert: ((varName beginsWith: 'cascade') and: [varName last isDigit]).
				 locals add: varName.
				 self declarationAt: varName
					put: (decl value: self value: aCodeGen), ' ', varName]]].
	aCodeGen
		pushScope: declarations
		while:"N.B.  nodesWithParentsDo: is bottom-up, hence replacement is destructive and conserved."
			[parseTree nodesWithParentsDo:
				[:node :parent|
				 node isSend ifTrue:
					[aCodeGen ifStaticallyResolvedPolymorphicReceiverThenUpdateSelectorIn: node.
					 (aCodeGen isBuiltinSelector: node selector)
						ifTrue:
							[node isBuiltinOperator: true.
							"If a to:by:do:'s limit has side-effects, declare the limit variable, otherwise delete it from the args"
							 node selector = #to:by:do: ifTrue:
								[self ensureToByDoLoopLimitIsSafeAndEfficient: node in: aCodeGen]]
						ifFalse:
							[(CaseStatements includes: node selector) ifTrue:
								[parent replaceNodesIn: (Dictionary newFromPairs: { node. self buildCaseStmt: node in: aCodeGen})].
							 (#(caseOf: #caseOf:otherwise:) includes: node selector) ifTrue:
								[parent replaceNodesIn: (Dictionary newFromPairs: { node. self buildSwitchStmt: node parent: parent })].
							 (#(printf: f:printf:) includes: node selector) ifTrue:
								[| map |
								map := Dictionary new.
								node nodesDo:
									[:subNode|
									 (subNode isConstant and: [subNode value isString and: [subNode value includes: $%]]) ifTrue:
										[map at: subNode put: subNode asPrintfFormatStringNode].
								node replaceNodesIn: map]]]]]]
]

{ #category : #'primitive compilation' }
TMethod >> preparePrimitiveName [
	"Prepare the selector for this method in translation.
	 Remember the original selector in properties."
	| aClass |
	properties := properties copy.
	properties selector: selector.
	aClass := definingClass.
	primitive = 117 
		ifTrue:[selector := ((aClass includesSelector: selector)
					ifTrue: [aClass compiledMethodAt: selector]
					ifFalse: [aClass class compiledMethodAt: selector]) literals first at: 2.
				export := true]
		ifFalse:[selector := 'prim', aClass name, selector].


]

{ #category : #'primitive compilation' }
TMethod >> preparePrimitivePrologue [
	"Add a prolog and postlog to a primitive method. The prolog copies any instance variables referenced by this primitive method into local variables. The postlog copies values of assigned-to variables back into the instance. The names of the new locals are added to the local variables list.

The declarations dictionary defines the types of any non-integer variables (locals, arguments, or instance variables). In particular, it may specify the types:

	int *		-- an array of 32-bit values (e.g., a BitMap)
	short *		-- an array of 16-bit values (e.g., a SoundBuffer)
	char *		-- an array of unsigned bytes (e.g., a String)
	double		-- a double precision floating point number (e.g., 3.14159)

Undeclared variables are taken to be integers and will be converted from Smalltalk to C ints."

"Current restrictions:
	o method must not contain message sends
	o method must not allocate objects
	o method must not manipulate raw oops
	o method cannot access class variables
	o method can only return an integer"

	| prolog postlog instVarsUsed varsAssignedTo instVarList primArgCount varName endsWithReturn aClass |
	self assert: selector ~~ #setInterpreter:.
	aClass := definingClass.
	prolog := OrderedCollection new.
	postlog := OrderedCollection new.
	instVarsUsed := self freeVariableReferences asSet.
	varsAssignedTo := self variablesAssignedTo asSet.
	instVarList := aClass allInstVarNames.
	primArgCount := args size.

	"add receiver fetch and arg conversions to prolog"
	prolog addAll: self fetchRcvrExpr.
	1 to: args size do: [:argIndex |
		varName := args at: argIndex.
		prolog addAll:
			(self argConversionExprFor: varName stackIndex: args size - argIndex)].

	"add success check to postlog"
	postlog addAll: self checkSuccessExpr.

	"add instance variable fetches to prolog and instance variable stores to postlog"
	1 to: instVarList size do: [:varIndex |
		varName := instVarList at: varIndex.
		(instVarsUsed includes: varName) ifTrue: [
			locals add: varName.
			prolog addAll: (self instVarGetExprFor: varName offset: varIndex - 1).
			(varsAssignedTo includes: varName) ifTrue: [
				postlog addAll: (self instVarPutExprFor: varName offset: varIndex - 1)]]].
	prolog addAll: self checkSuccessExpr.

	((locals includes: 'rcvr') or: [(locals intersection: args) notEmpty]) ifTrue:
		[self error: 'local name conflicts with instance variable name'].
	locals add: 'rcvr'; addAll: args.
	args := args class new.
	endsWithReturn := self endsWithReturn.
	self fixUpReturns: primArgCount postlog: postlog.

	endsWithReturn
		ifTrue: [parseTree setStatements: prolog, parseTree statements]
		ifFalse: [
			postlog addAll: (self popArgsExpr: primArgCount).
			parseTree setStatements: prolog, parseTree statements, postlog].

]

{ #category : #accessing }
TMethod >> primitive [
	"The primitive number of this method; zero if not a primitive."

	^ primitive

]

{ #category : #printing }
TMethod >> printOn: aStream [

	super printOn: aStream.
	aStream nextPutAll: ' (', definingClass name, '>>', selector, ')'.
]

{ #category : #'C code generation' }
TMethod >> printSingleComment: aString on: aStream indent: indent tabWidth: tabWidth lineBreak: lineBreak [
	"Shameless hack of ParseNode>>printSingleComment:on:indent: for formatting comments."
	| readStream position wordStream |
	readStream := ReadStream on: aString.
	position := indent * tabWidth.
	wordStream := WriteStream on: (String new: 16).
	[readStream atEnd] whileFalse:
		[| word wordWidth lastChar |
		wordStream reset.
		wordWidth := 0.
		[(readStream peekFor: Character space) 
		 or: [readStream peekFor: Character tab]] whileTrue.
		[readStream atEnd
		 or: [(lastChar := readStream next) = Character cr
			 or: [lastChar = Character space]]] whileFalse:
			[wordWidth := wordWidth + 1.
			 wordStream nextPut: lastChar].
		word := wordStream contents.
		position := position + wordWidth.
		position > lineBreak
			ifTrue:
				[aStream skip: -1; crtab: indent.
				position := indent * tabWidth + wordWidth + 1.
				lastChar = Character cr ifTrue:
					[[readStream peekFor: Character tab] whileTrue].
				word isEmpty ifFalse:
					[aStream nextPutAll: word; space]]
			ifFalse:
				[aStream nextPutAll: word.
				readStream atEnd ifFalse:
					[position := position + 1.
					aStream space].
				lastChar = Character cr ifTrue:
					[aStream skip: -1; crtab: indent.
					position := indent * tabWidth.
					[readStream peekFor: Character tab] whileTrue]]]
]

{ #category : #private }
TMethod >> printTempsAndVar: varName on: aStream [ 
	"add the required temps and the varname to the stream"
	aStream nextPutAll: '| rcvr stackPointer interpreterProxy ' , varName , ' |'; cr
]

{ #category : #'inlining support' }
TMethod >> propagateReturnIn: aCodeGen [
	"Propagate the return type to all return nodes"
	| map coercionType |
	returnType = #void ifTrue:
		[^self].
	"The following is necessary for functions returning functions, which have problematic syntax"
	coercionType := aCodeGen
							extractTypeFor: (aCodeGen cFunctionNameFor: self selector)
							fromDeclaration: returnType.
	map := IdentityDictionary new.
	parseTree nodesDo:[:node|
		(node isReturn
		 and: [(aCodeGen typeFor: node expression in: self) ~= coercionType
		 and: [(aCodeGen isNode: node constantValueWithinRangeOfType: coercionType) not]]) ifTrue:
			[map at: node expression put: (aCodeGen nodeToCast: node expression to: coercionType)]].
	self replaceNodesIn: map
]

{ #category : #accessing }
TMethod >> properties [
	^properties
]

{ #category : #initialization }
TMethod >> properties: anAdditionalMethodState [
	properties := anAdditionalMethodState
]

{ #category : #accessing }
TMethod >> readsVariable: variableName [
	"Answer if the receiver reads the variable (i.e. ignore assignments to the variable)."
	parseTree nodesWithParentsDo:
		[:node :parent|
		 (node isVariable
		  and: [node name = variableName]) ifTrue:
			[(parent notNil
			  and: [parent isAssignment
			  and: [node == parent variable]]) ifFalse:
				[^true]]].
	^false
]

{ #category : #transformations }
TMethod >> recordDeclarationsIn: aCCodeGen [
	"Record C type declarations of the forms
		<returnTypeC: 'float'>
		<var: #foo declareC: 'float foo'>
		<var: #foo type:'float'>
	 or the older, obsolete
		self returnTypeC: 'float'.
		self var: #foo declareC: 'float foo'
		self var: #foo type:'float'.
	 and remove the declarations from the method body."

	| newStatements |
	properties pragmas notEmpty
		ifTrue: [ properties pragmas
				do: [ :pragma | 
					pragma selector == #var:declareC:
						ifTrue: [ self
								checkedDeclarationAt: pragma arguments first asString
								put: pragma arguments last
								in: aCCodeGen ].
					pragma selector == #var:type:
						ifTrue: [ | varName varType |
							varName := pragma arguments first asString.
							varType := aCCodeGen
								conventionalTypeForType: pragma arguments last.
							varType last == $*
								ifFalse: [ varType := varType , ' ' ].
							self
								checkedDeclarationAt: varName
								put: varType , varName
								in: aCCodeGen ].
					pragma selector = #returnTypeC:
						ifTrue: [ self returnType: pragma arguments last ].
					pragma selector = #doNotGenerate:
						ifTrue: [ locals remove: pragma arguments last ] ].
			^ self ].
	newStatements := OrderedCollection new: parseTree statements size.
	parseTree statements
		do: [ :stmt | 
			| isDeclaration |
			isDeclaration := false.
			stmt isSend
				ifTrue: [ stmt selector == #var:declareC:
						ifTrue: [ isDeclaration := true.
							self
								declarationAt: stmt args first value asString
								put: stmt args last value ].
					stmt selector == #var:type:
						ifTrue: [ | varName varType |
							isDeclaration := true.
							varName := stmt args first value asString.
							varType := aCCodeGen
								conventionalTypeForType: stmt args last value.
							varType last == $*
								ifFalse: [ varType := varType , ' ' ].
							self declarationAt: varName put: varType , varName ].
					stmt selector = #returnTypeC:
						ifTrue: [ isDeclaration := true.
							returnType := stmt args last value ] ].
			isDeclaration
				ifFalse: [ newStatements add: stmt ] ].
	parseTree setStatements: newStatements asArray
]

{ #category : #accessing }
TMethod >> referencesGlobalStruct [
	globalStructureBuildMethodHasFoo := true
]

{ #category : #accessing }
TMethod >> refersToGlobalStruct [
	^globalStructureBuildMethodHasFoo
]

{ #category : #transformations }
TMethod >> removeAssertions [
	parseTree removeAssertions
]

{ #category : #transformations }
TMethod >> removeFinalSelfReturnIn: aCodeGenOrNil [
	"The Smalltalk parser automatically adds the statement '^self' to the end of methods
	 without explicit returns.  This method removes such statements, since in most VMMaker
	 classes (except struct classes) the generated code has no notion of 'self' anyway.
	 If the statement is removed and no return type has yet been specified and the class
	 specifies a default return type (e.g. #void) for methods that don't return, then set the
	 return type accordingly."

	| lastStmt |
	parseTree statements isEmpty ifTrue: [^self].
	((lastStmt := parseTree statements last) isReturn
	 and: [lastStmt expression isVariable
	 and: ['self' = lastStmt expression name]]) ifTrue:
		[| tokens |
		tokens := Scanner new scanTokens: (definingClass sourceCodeAt: selector ifAbsent: ['']).
		(tokens size < 2
		 or: [(tokens last: 2) ~= #(#'^' 'self')]) ifTrue:
			[parseTree setStatements: parseTree statements allButLast.
			 (returnType isNil
			  and: [aCodeGenOrNil notNil
			  and: [parseTree noneSatisfy: [:node| node isReturn and: [node expression isVariable not or: [node expression name ~= 'self']]]]]) ifTrue:
				[self returnType: (aCodeGenOrNil implicitReturnTypeFor: selector)]]]
]

{ #category : #utilities }
TMethod >> removeUnusedTempsAndNilIfRequiredIn: aCodeGen [
	"Remove all of the unused temps in this method. Answer a set of the references.
	 As a side-effect introduce explicit temp := nil statements for temps that are
	 tested for nil before necessarily being assigned."
	| refs readBeforeAssigned simplyTypedLocals |
	refs := self removeUnusedTempsIn: aCodeGen.
	"reset the locals to be only those still referred to"
	locals := locals select: [:e| refs includes: e].
	(locals notEmpty
	 and: [aCodeGen
			pushScope: declarations
			while: [simplyTypedLocals := locals select:
											[:var|
											 declarations
												at: var
												ifPresent: [:decl| aCodeGen isSimpleType: (aCodeGen extractTypeFor: var fromDeclaration: decl)]
												ifAbsent: [true]].
				(readBeforeAssigned := (self findReadBeforeAssignedIn: simplyTypedLocals in: aCodeGen)) notEmpty]]) ifTrue:
		[readBeforeAssigned := readBeforeAssigned reject:
			[:v| | d | "don't initialize externs, statics, arrays or the explicitly initialized."
			 d := self declarationAt: v ifAbsent: [ aCodeGen defaultType , ' ' , v ].
			 (d beginsWith: 'extern') or: [(d beginsWith: 'static') or: [(d includes: $[) or: [d includes: $=]]]].
		 parseTree statements addAllFirst:
			(readBeforeAssigned asSortedCollection collect:
				[:var| | varNode varType zeroNode |
				 varNode := TVariableNode new setName: var; yourself.
				 varType := aCodeGen typeFor: varNode in: self.
				 zeroNode := TConstantNode new setValue: 0; yourself.
				 TAssignmentNode new
					setVariable: varNode
					expression: (((aCodeGen isIntegralCType: varType)
								    or: [aCodeGen isFloatingPointCType: varType])
									ifTrue: [zeroNode]
									ifFalse: [aCodeGen nodeToCast: zeroNode to: varType])])].
	^refs
]

{ #category : #utilities }
TMethod >> removeUnusedTempsIn: aCodeGen [
	"Remove all of the unused temps in this method. Answer a set of the references."
	"After inlining some variable references are now obsolete, we could fix them there
	 but the code seems a bit complicated, the other choice to to rebuild the locals
	 before extruding. This is done here"
	| usedVariables |
	usedVariables := self allReferencedVariablesUsing: aCodeGen.
	"reset the locals to be only those still referred to"
	locals do:
		[:local|
		 (usedVariables includes: local) ifFalse:
			[(((declarations at: local ifAbsent: ['']) includesSubstring: 'static')
			  or: [(declarations at: local ifAbsent: ['']) includesSubstring: 'extern'])
				ifFalse:
					[locals remove: local.
					 declarations removeKey: local ifAbsent: []]
				ifTrue:
					[usedVariables add: local "In case this is a function declaration, e.g. amInVMThread in ownVM:"]]].
	^usedVariables
]

{ #category : #'inlining support' }
TMethod >> renameLabelsForInliningInto: destMethod [
	"Rename any labels that would clash with those of the destination method."

	| destLabels usedLabels labelMap newLabelName |
	destLabels := destMethod labels asSet.
	usedLabels := destLabels copy.  "usedLabels keeps track of labels in use"
	usedLabels addAll: labels.
	labelMap := Dictionary new: 100.
	self labels do: [ :l |
		(destLabels includes: l) ifTrue: [
			newLabelName := self unusedNamePrefixedBy: 'l' avoiding: usedLabels.
			labelMap at: l put: newLabelName.
		].
	].
	self renameLabelsUsing: labelMap.
]

{ #category : #'inlining support' }
TMethod >> renameLabelsUsing: aDictionary [
	"Rename all labels according to the old->new mappings of the given dictionary."

	aDictionary isEmpty ifTrue:
		[^self].
	labels := labels collect: [ :label | aDictionary at: label ifAbsent: [label]].

	parseTree nodesDo:
		[ :node |
		(node isGoTo and: [aDictionary includesKey: node label]) ifTrue:
			[node setLabel: (aDictionary at: node label)].
		(node isLabel and: [aDictionary includesKey: node label]) ifTrue:
			[node setLabel: (aDictionary at: node label)]]
]

{ #category : #'inlining support' }
TMethod >> renameVariablesUsing: aDictionary [
	"Rename all variables according to old->new mappings of the given dictionary."

	| newDecls newProperties |
	aDictionary isEmpty
		ifTrue: [ ^ self ].

	"map args and locals"
	args := args
		collect: [ :arg | aDictionary at: arg ifAbsent: [ arg ] ].
	locals := locals collect: [ :v | aDictionary at: v ifAbsent: [ v ] ].

	"map declarations"
	newDecls := declarations species new.
	declarations
		keysAndValuesDo: [ :oldName :decl | 
			(aDictionary at: oldName ifAbsent: nil)
				ifNotNil: [ :newName | 
					| index |
					index := decl indexOfWord: oldName.
					newDecls
						at: newName
						put:
							(index ~= 0
								ifTrue: [ decl
										copyReplaceFrom: index
										to: index + oldName size - 1
										with: newName ]
								ifFalse: [ decl ]) ]
				ifNil: [ newDecls at: oldName put: decl ] ].
	self newDeclarations: newDecls.
	newProperties := properties copy.
	newProperties pragmas
		do: [ :pragma | 
			| mappedArgs |
			mappedArgs := pragma arguments
				collect: [ :arg | 
					arg isString
						ifTrue: [ aDictionary at: arg ifAbsent: arg ]
						ifFalse: [ arg ] ].
			mappedArgs ~= pragma arguments
				ifTrue: [ pragma arguments: mappedArgs ] ].
	self properties: newProperties.

	"map variable names in parse tree"
	parseTree
		nodesDo: [ :node | 
			(node isVariable and: [ aDictionary includesKey: node name ])
				ifTrue: [ node setName: (aDictionary at: node name) ].
			(node isStmtList and: [ node args size > 0 ])
				ifTrue: [ node
						setArguments: (node args collect: [ :arg | aDictionary at: arg ifAbsent: [ arg ] ]) ] ]
]

{ #category : #'inlining support' }
TMethod >> renameVarsForInliningInto: destMethod except: doNotRename in: aCodeGen [
	"Rename any variables that would clash with those of the destination method."

	| destVars usedVars varMap newVarName |
	destVars := aCodeGen globalsAsSet copy.
	destVars addAll: destMethod locals.
	destVars addAll: destMethod args.
	usedVars := destVars copy.  "keeps track of names in use"
	usedVars addAll: args; addAll: locals.
	varMap := Dictionary new: 100.
	locals, args do:
		[ :v |
		((doNotRename includes: v) not
		  and: [destVars includes: v]) ifTrue:
			[newVarName := self unusedNamePrefixedBy: v avoiding: usedVars.
			varMap at: v put: newVarName]].
	self renameVariablesUsing: varMap
]

{ #category : #transformations }
TMethod >> replaceNodesIn: map [
	parseTree := parseTree replaceNodesIn: map.
]

{ #category : #'primitive compilation' }
TMethod >> replaceSizeMessages [
	"Replace sends of the message 'size' with calls to sizeOfSTArrayFromCPrimitive."

	| argExpr |
	parseTree nodesDo: [:n |
		(n isSend and: [n selector = #size]) ifTrue: [
			argExpr := TSendNode new
				setSelector: #+
				receiver: n receiver
				arguments: (Array with: (TConstantNode new setValue: 1)).
			n
				setSelector: #sizeOfSTArrayFromCPrimitive:
				receiver: (TVariableNode new setName: self vmNameString)
				arguments: (Array with: argExpr)]].

]

{ #category : #accessing }
TMethod >> returnType [
	"The type of the values returned by this method. This string will be used in the C declaration of this function."

	^returnType
]

{ #category : #accessing }
TMethod >> returnType: aString [
	"Set the type of the values returned by this method.
	 This string will be used in the C declaration of this function.
	 If the type exists as a symbol, use that."

	returnType := aString isSymbol
					ifTrue: [aString]
					ifFalse: [(Symbol findInterned: aString) ifNil: [aString]]
]

{ #category : #testing }
TMethod >> returnsExpression [
	"Answer true if the last statement of this method is a return of some expression, not merely self or nil."

	^parseTree returnsExpression
]

{ #category : #accessing }
TMethod >> selector [
	"The Smalltalk selector of this method."

	^selector
]

{ #category : #accessing }
TMethod >> selector: newSelector [

	selector := newSelector.
]

{ #category : #initialization }
TMethod >> setSelector: sel definingClass: class args: argList locals: localList block: aBlockNode primitive: aNumber properties: methodProperties comment: aComment [
	"Initialize this method using the given information."

	selector := sel.
	definingClass := class.
	args := argList asOrderedCollection collect: [:arg | arg key].
	locals := (localList collect: [:arg | arg key]) asSet.
	declarations := Dictionary new.
	self addTypeForSelf.
	primitive := aNumber.
	properties := methodProperties.
	comment := aComment.
	labels := Set new.
	parseTree := aBlockNode. "hack; allows nodes to find their parent, etc"
	parseTree := aBlockNode asTranslatorNodeIn: self.
	complete := false.  "set to true when all possible inlining has been done"
	export := self extractExportDirective.
	static := self extractStaticDirective.
	self extractSharedCase.
	globalStructureBuildMethodHasFoo := false
]

{ #category : #accessing }
TMethod >> sharedCase [
	^sharedCase
]

{ #category : #accessing }
TMethod >> sharedLabel [
	^sharedLabel
]

{ #category : #inlining }
TMethod >> shouldIncorporatePragmaFromSuperMethod: aPragma [
	(properties includesKey: aPragma selector)
		ifFalse: [ ^ true ].
	((aPragma selector beginsWith: #var:)
		and: [ properties pragmas
				noneSatisfy: [ :p | 
					(p selector beginsWith: #var:)
						and: [ (p argumentAt: 1) = (aPragma argumentAt: 1) ] ] ])
		ifTrue: [ ^ true ].
	^ false
]

{ #category : #accessing }
TMethod >> smalltalkSelector [
	"Answer the selector of the original Smalltalk method, not any mangled one."
	^selector
]

{ #category : #accessing }
TMethod >> statements [

	parseTree isStmtList
		ifFalse: [ self error: 'expected method parse tree to be a TStmtListNode' ].
	((parseTree args = nil) or: [parseTree args isEmpty])
		ifFalse: [ self error: 'expected method parse tree to have no args' ].

	^parseTree statements
]

{ #category : #'primitive compilation' }
TMethod >> statementsFor: sourceText varName: varName [
	"Return the parse tree for the given expression. The result is the statements list of the method parsed from the given source text."
	"Details: Various variables are declared as locals to avoid Undeclared warnings from the parser."

	| s compiler ast |
	s := WriteStream on: String new.
	s nextPutAll: 'temp'; cr; crtab.
	self printTempsAndVar: varName on: s.
	s nextPutAll: sourceText.

	compiler := Smalltalk compiler class: (self properties at: #codeGenerator) constantClass.
		
	ast := (compiler parse: s contents) "for primitive error codes"
			compilationContext: compiler compilationContext;
			yourself.
			
	^ (ast asTranslationMethodOfClass: self class)
			removeFinalSelfReturnIn: nil;
			statements
]

{ #category : #inlining }
TMethod >> statementsListsForInliningIn: aCodeGen [
	"Answer a collection of statement list nodes that are candidates for inlining.
	 Currently, we cannot inline into the argument blocks of and: and or: messages.
	 We do not want to inline code strings within cCode:inSmalltalk: blocks (those with a
	 proper block for the cCode: argument are inlined in MessageNode>>asTranslatorNodeIn:).
	 We do not want to inline code within assert: sends (because we want the assert to read nicely)."

	| stmtLists |
	stmtLists := OrderedCollection new: 10.
	parseTree
		nodesDo:
			[:node|
			node isStmtList ifTrue: [stmtLists add: node]]
		unless:
			[:node|
			node isSend
			and: [node selector == #cCode:inSmalltalk:
				or: [aCodeGen isAssertSelector: node selector]]].
	parseTree nodesDo:
		[:node|
		node isSend ifTrue:
			[node selector = #cCode:inSmalltalk: ifTrue:
				[node nodesDo:
					[:ccisNode| stmtLists remove: ccisNode ifAbsent: []]].
			 (node selector = #cppIf:ifTrue:ifFalse: or: [node selector = #cppIf:ifTrue:]) ifTrue:
				[node args first nodesDo:
					[:inCondNode| stmtLists remove: inCondNode ifAbsent: []]].
			((node selector = #and:) or: [node selector = #or:]) ifTrue:
				"Note: the PP 2.3 compiler produces two arg nodes for these selectors"
				[stmtLists remove: node args first ifAbsent: [].
				stmtLists remove: node args last ifAbsent: []].
			(#(	#ifTrue: #ifFalse: #ifTrue:ifFalse: #ifFalse:ifTrue:
				#ifNil: #ifNotNil: #ifNil:ifNotNil: #ifNotNil:ifNil: ) includes: node selector) ifTrue:
				[stmtLists remove: node receiver ifAbsent: []].
			(#(whileTrue whileTrue: whilefalse whileFalse:) includes: node selector) ifTrue:
				"Allow inlining if it is a [...] whileTrue/whileFalse.
				This is identified by having more than one statement in the 
				receiver block in which case the C code wouldn't work anyways"
				[node receiver statements size = 1 ifTrue:
					[stmtLists remove: node receiver ifAbsent: []]].
			(node selector = #to:do:) ifTrue:
				[stmtLists remove: node receiver ifAbsent: [].
				stmtLists remove: node args first ifAbsent: []].
			(node selector = #to:by:do:) ifTrue:
				[stmtLists remove: node receiver ifAbsent: [].
				stmtLists remove: node args first ifAbsent: [].
				stmtLists remove: node args second ifAbsent: []]].
		node isCaseStmt ifTrue: "don't inline cases"
			[node cases do: [:case| stmtLists remove: case ifAbsent: []]]].
	^stmtLists
]

{ #category : #accessing }
TMethod >> static [
	^static
]

{ #category : #accessing }
TMethod >> static: aBoolean [
	static := aBoolean
]

{ #category : #inlining }
TMethod >> superExpansionNodeFor: aSelector args: argumentNodes [
	"Answer the expansion of a super send.  Merge the super expansion's
	 locals, properties and comment into this method's properties."
	(definingClass superclass lookupSelector: aSelector)
		ifNil: [self error: 'superclass does not define super method']
		ifNotNil:
			[:superMethod| | superTMethod commonVars varMap |
			superTMethod := superMethod asTranslationMethodOfClass: self class.
			((argumentNodes allSatisfy: [:parseNode| parseNode isVariableNode])
			and: [(argumentNodes asOrderedCollection collect: [:parseNode| parseNode key]) = superTMethod args]) ifFalse:
				[self error: definingClass name, '>>',selector, ' args ~= ',
							superTMethod definingClass name, '>>', aSelector,
							(String with: $. with: Character cr),
							'For super expansions to be translated correctly each argument must be a variable with the same name as the corresponding argument in the super method.'].
			(commonVars := superTMethod locals intersection: self locals) notEmpty ifTrue:
				[varMap := Dictionary new.
				 commonVars do:
					[:k| varMap at: k put: (superTMethod unusedNamePrefixedBy: k avoiding: self allLocals)].
				 superTMethod renameVariablesUsing: varMap].
			self mergePropertiesOfSuperMethod: superTMethod.
			self assert: (superTMethod locals allSatisfy: [:var| (self locals includes: var) not]).
			locals addAll: superTMethod locals.
			superTMethod declarations keysAndValuesDo:
				[:var :decl|
				self declarationAt: var put: decl].
			superTMethod comment ifNotNil:
				[:superComment|
				comment := comment
								ifNil: [superComment]
								ifNotNil: [superComment, comment]].
			superTMethod extraVariableNumber ifNotNil:
				[:scvn|
				extraVariableNumber := extraVariableNumber ifNil: [scvn] ifNotNil: [:cvn| cvn + scvn]].
			superTMethod elideAnyFinalReturn.
			^superTMethod parseTree]
]

{ #category : #'C code generation' }
TMethod >> terminateConditionalDefineFor: compileTimeOptionPragmas on: aStream [
	compileTimeOptionPragmas ifEmpty: [ ^ self ].
	aStream nextPutAll: '#endif /* '.
	compileTimeOptionPragmas
		do: [ :pragma | 
			pragma selector = #notOption:
				ifTrue: [ aStream nextPut: $! ].
			aStream nextPutAll: (pragma argumentAt: 1) ]
		separatedBy: [ aStream nextPutAll: ' && ' ].
	aStream
		nextPutAll: ' */';
		cr
]

{ #category : #inlining }
TMethod >> transformConditionalAssignment: node in: aCodeGen [
	"If possible answer the transformation of code of the form
		var := e1
				ifTrue: [e2 ifTrue: [self m1] ifFalse: [self m2]]
				ifFalse: [self m3]
	 into
		e1
			ifTrue: [e2 ifTrue: [var := self m1] ifFalse: [var := self m2]]
			ifFalse: [var := self m3]
	 to allow inlining of m1, m2, et al.  Otherwise answer nil."

	| expr |
	^(node isAssignment
	   and: [(expr := node expression) isSend
	   and: [(#(ifTrue:ifFalse: ifFalse:ifTrue:) includes: expr selector)
	   and: [self isConditionalToBeTransformedForAssignment: expr  in: aCodeGen]]]) ifTrue:
		[expr copy
			arguments:
				(expr args collect:
					[:stmtList| stmtList copy assignLastExpressionTo: node variable]);
			yourself]
]

{ #category : #inlining }
TMethod >> transformReturnSubExpression: node toAssignmentOf: exitVar andGoto: exitLabel unless: eliminateReturnSelfs into: aBinaryBlock [
	| expr replacement |
	expr := node isReturn ifTrue: [node expression] ifFalse: [node].
	replacement := (expr isVariable "Eliminate ^self's"
					   and: [expr name = 'self'
					   and: [eliminateReturnSelfs]])
						ifTrue: [nil]
						ifFalse:
							[exitVar
								ifNil: [expr]
								ifNotNil: [TAssignmentNode new
											setVariable: (TVariableNode new setName: exitVar)
											expression: expr]].
	 node == parseTree statements last
		ifTrue:
			[aBinaryBlock value: replacement value: false]
		ifFalse:
			[replacement := replacement
								ifNil: [TGoToNode new setLabel: exitLabel; yourself]
								ifNotNil:
									[TStmtListNode new
										setArguments: #()
										statements: {replacement.
													  TGoToNode new setLabel: exitLabel; yourself};
										yourself].
			 aBinaryBlock value: replacement value: true]
]

{ #category : #'type inference' }
TMethod >> transformReturns [
	"Once the return type has been found or inferred, returns may bneed to be modified.
	 If the return type is #void, any occurrences of ^expr must be replaced with expr. ^self.
	 If the type is #sqInt any any occurrences of ^self are replaced with ^0."
	(returnType == #void or: [returnType == #sqInt]) ifFalse:
		[^self].
	parseTree nodesWithParentsDo:
		[:node :parent|
		node isReturn ifTrue:
			[(node expression isVariable and: [node expression name = 'self'])
				ifTrue:
					[returnType = #sqInt ifTrue:
						[node setExpression: (TConstantNode new setValue: 0)]]
				ifFalse:
					[returnType = #void ifTrue:
						[parent
							replaceChild: node
							with: (TStmtListNode new
									setArguments: #()
									statements: {node expression.
												  TReturnNode new 
													setExpression: (TVariableNode new setName: 'self')
													yourself})]]]]
]

{ #category : #transformations }
TMethod >> transformToStructClassMethodFor: aCCodeGenerator [
	"Transform this method so that it can be used on an instance of a struct class (VMStructType subclass).
	 Convert inst var refs into field dereferences of self.  Add selfSelector as the first argument with the
	 right struct type. As a complete hack to avoid breaking the inlinert don't use 'self' as the name for self
	 as this causes serious type redefinitions ``somewhere'' in the inliner."
	| replacements selfNode typeForSelf |
	self isStructAccessor ifTrue:
		[^self returnType: (definingClass returnTypeForAccessor: selector)].
	replacements := IdentityDictionary new.
	selfNode := TVariableNode new setName: 'self_in_', (aCCodeGenerator cFunctionNameFor: selector).
	args do:
		[:var|
		(definingClass isAccessor: var) ifTrue:
			[self error: 'In ', definingClass name, '>>', selector, ' ', var, ' arg shadows struct field and will break during translation!']].
	parseTree nodesDo:
		[:node|
		node isVariable ifTrue:
			[node name = 'self' ifTrue:
				[replacements at: node put: selfNode copy].
			 (definingClass isAccessor: node name) ifTrue:
				[replacements
					at: node
					put: (TSendNode new
							setSelector: node name asSymbol
							receiver: selfNode
							arguments: #())]]].
	replacements notEmpty ifTrue:
		[self replaceNodesIn: replacements].
	typeForSelf := self typeForSelf.
	self assert: (typeForSelf notNil and: [typeForSelf ~~ #implicit]).
	self declarationAt: (args addFirst: selfNode name)
		put: (declarations removeKey: 'self'), '_in_', (aCCodeGenerator cFunctionNameFor: selector)
]

{ #category : #inlining }
TMethod >> tryToInlineMethodExpressionsIn: aCodeGen [
	"Expand any (complete) inline methods sent by this method as receivers or parameters.
	 Answer if anything was inlined."

	| sendsToInline |
	sendsToInline := Dictionary new: 100.
	aCodeGen
		pushScope: declarations
		while: [parseTree
					nodesDo:
						[:node|
						(self inlineableFunctionCall: node in: aCodeGen) ifTrue:
							[(self inlineFunctionCall: node in: aCodeGen) ifNotNil:
								[:replacement|
								 (replacement isConstant
								  and: [replacement isDefine not
								  and: [replacement value isNumber
								  and: [replacement comment isNil]]]) ifTrue:
									[replacement comment: node selector].
								 sendsToInline at: node put: replacement]]]
					unless: "Don't inline the arguments to asserts to keep the asserts readable"
						[:node|
						node isSend
						and: [node selector == #cCode:inSmalltalk:
							or: [aCodeGen isAssertSelector: node selector]]]].

	sendsToInline isEmpty ifTrue:
		[^false].
	self replaceNodesIn: sendsToInline.
	^true
]

{ #category : #inlining }
TMethod >> tryToInlineMethodStatementsIn: aCodeGen statementListsInto: aBlock [
	"Expand any (complete) inline methods sent by this method as top-level statements.
	 Answer if anything was inlined."

	| stmtLists didSomething newStatements returningNodes |
	didSomething := false.
	returningNodes := Set new.
	parseTree nodesDo:
		[:node|
		node isReturn ifTrue:
			[returningNodes add: node expression.
			 node expression isConditionalSend ifTrue:
				[returningNodes addAll: (node expression args collect: [:stmtList| stmtList statements last])]]].
	stmtLists := self statementsListsForInliningIn: aCodeGen.
	stmtLists do:
		[:stmtList|
		newStatements := OrderedCollection new: stmtList statements size.
		stmtList statements do:
			[:stmt|
			(self inlineCodeOrNilForStatement: stmt returningNodes: returningNodes in: aCodeGen)
				ifNil: [newStatements addLast: stmt]
				ifNotNil: [:inlinedStmts|
					didSomething := true.
					newStatements addAllLast: inlinedStmts]].
		stmtList setStatements: newStatements asArray].

	"This is a hack; forgive me. The inlining above tends to keep return statements in statement lists.
	 In the case of returning ifs we don't want the returns in case the returning if is generated as an expression."
	returningNodes do:
		[:returningNode|
		 (returningNode isConditionalSend
		  and: [returningNode args anySatisfy: [:alternativeNode| alternativeNode endsWithReturn]]) ifTrue:
			[returningNode args withIndexDo:
				[:alternativeNode :index|
				 alternativeNode endsWithReturn ifTrue:
					[returningNode args at: index put: alternativeNode copyWithoutReturn]]]].

	aBlock value: stmtLists.

	^didSomething
]

{ #category : #inlining }
TMethod >> tryToInlineMethodsIn: aCodeGen [
	"Expand any (complete) inline methods sent by this method.
	 Set the complete flag when all inlining has been done.
	 Answer if something was inlined."

	| didSomething statementLists |
	"complete ifTrue:
		[^false]."

	self definedAsMacro ifTrue:
		[complete ifTrue:
			[^false].
		 ^complete := true].

	self ensureConditionalAssignmentsAreTransformedIn: aCodeGen.
	didSomething := self tryToInlineMethodStatementsIn: aCodeGen statementListsInto: [:stmtLists| statementLists := stmtLists].
	didSomething := (self tryToInlineMethodExpressionsIn: aCodeGen) or: [didSomething].

	didSomething ifTrue:
		[writtenToGlobalVarsCache := nil].

	complete ifFalse:
		[self checkForCompletenessIn: aCodeGen.
		 complete ifTrue: [didSomething := true]].  "marking a method complete is progress"
	^didSomething
]

{ #category : #utilities }
TMethod >> typeFor: aVariable in: aCodeGen [
	"Answer the type for aVariable, deferring to aCodeGen (which defers to the vmClass)
	 if no type is found and the variable is global (not an arg or a local).  Expect the
	 cCodeGen to answer nil for variables without types. nil for typelessness is required
	 by the type propagation logic in inlineSend:directReturn:exitVar:in:."
	| varName |
	varName := aVariable asString.
	^(declarations
			at: varName
			ifAbsent:
				[(args includes: varName) "arg types default to default integer type"
					ifTrue: [aCodeGen defaultType, ' ', varName]
					ifFalse:
						[(locals includes: varName) ifFalse: "don't provide type for locals"
							[aCodeGen typeOfVariable: varName]]]) ifNotNil:
		[:decl|
		aCodeGen extractTypeFor: varName fromDeclaration: decl]
]

{ #category : #utilities }
TMethod >> typeForSelf [

	^ [ definingClass typeForSelf ] on: MessageNotUnderstood do: [ :ex | nil ]
]

{ #category : #inlining }
TMethod >> unusedLabelForInlining: sourceMethod [
	^labels add: (self unusedLabelForInliningInto: sourceMethod)
]

{ #category : #inlining }
TMethod >> unusedLabelForInliningInto: targetMethod [
	^self unusedNamePrefixedBy: 'l' avoiding: (targetMethod == self
												ifTrue: [labels]
												ifFalse: [labels copy
															addAll: targetMethod labels;
															yourself])
]

{ #category : #'inlining support' }
TMethod >> unusedNamePrefixedBy: aString avoiding: usedNames [
	"Choose a unique variable or label name with the given string as a prefix, avoiding
	 the names in the given collection. The selected name is added to usedNames."

	| n newVarName |
	n := 1.
	[newVarName := aString, n printString.
	 usedNames includes: newVarName] whileTrue:
		[n := n + 1].
	^usedNames add: newVarName
]

{ #category : #inlining }
TMethod >> usesVariableUninlinably: argName in: aCodeGen [
	^parseTree anySatisfy:
		[:node|
		node isSend
		and: [(aCodeGen isAssertSelector: node selector)
		and: [node args anySatisfy:
				[:argNode|
				 argNode anySatisfy:
					[:subNode|
					 subNode isVariable and: [subNode name = argName]]]]]]
]

{ #category : #utilities }
TMethod >> variablesAssignedTo [
	"Answer a collection of variables assigned to by this method."

	| refs |
	refs := Set new.
	parseTree nodesDo: [ :node |
		node isAssignment ifTrue: [ refs add: node variable name ].
	].
	^ refs
]

{ #category : #'primitive compilation' }
TMethod >> vmNameString [
	"return the string to use as the vm name in code generated for this method"
	^'self'
]
