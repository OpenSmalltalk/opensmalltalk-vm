"
A JSMethod is a translation method, representing a MethodNode that is to be translated to JavaScript source. It has a parseTree of translation nodes that mirrors the parse tree of the corresponding Smalltalk method.
"
Class {
	#name : #JSMethod,
	#superclass : #Object,
	#instVars : [
		'selector',
		'returnType',
		'args',
		'locals',
		'declarations',
		'primitive',
		'parseTree',
		'labels',
		'possibleSideEffectsCache',
		'complete',
		'export',
		'static',
		'sharedLabel',
		'sharedCase',
		'comment',
		'definingClass',
		'globalStructureBuildMethodHasFoo',
		'canAsmLabel',
		'mustAsmLabel',
		'properties',
		'cascadeVariableNumber',
		'extraVariableNumber',
		'oneBasedArrays'
	],
	#classVars : [
		'CaseStatements'
	],
	#category : #'VMMakerJS-Translation to JS'
}

{ #category : #'class initialization' }
JSMethod class >> initialize [
	"JSMethod initialize"	
	CaseStatements := IdentitySet new: 10.
	CaseStatements addAll: #(dispatchOn:in: dispatchOn:in:with: dispatchOn:in:with:with:).
]

{ #category : #'inlining support' }
JSMethod >> addVarsDeclarationsAndLabelsOf: methodToBeInlined [
	"Prepare to inline the body of the given method into the receiver by making the args and locals of the argument to the receiver be locals of the receiver. Record any type declarations for these variables. Record labels. Assumes that the variables have already be renamed to avoid name clashes."

	methodToBeInlined args, methodToBeInlined locals do: [ :v |
		(locals includes: v) ifFalse: [ locals addLast: v ].
	].
	methodToBeInlined declarations associationsDo: [ :assoc |
		declarations add: assoc.
	].
	methodToBeInlined labels do: [ :label |
		labels add: label.
	].
]

{ #category : #utilities }
JSMethod >> allCalls [
	"Answer a collection of selectors for the messages sent by this method."

	^parseTree allCalls
]

{ #category : #inlining }
JSMethod >> argAssignmentsFor: meth args: argList in: aCodeGen [
	"Return a collection of assignment nodes that assign the given argument expressions to the formal parameter variables of the given method."
	"Optimization: If the actual parameters are either constants or local variables in the target method (the receiver), substitute them directly into the body of meth. Note that global variables cannot be subsituted because the inlined method might depend on the exact ordering of side effects to the globals."

	| stmtList substitutionDict |
	stmtList := OrderedCollection new: 100.
	substitutionDict := Dictionary new: 100.
	meth args with: argList do: [ :argName :exprNode |
		(self isSubstitutableNode: exprNode intoMethod: meth in: aCodeGen) ifTrue: [
			substitutionDict at: argName put: exprNode.
			locals remove: argName.
		] ifFalse: [
			stmtList add: (TAssignmentNode new
				setVariable: (TVariableNode new setName: argName)
				expression: exprNode copyTree).
		].
	].
	meth parseTree: (meth parseTree bindVariablesIn: substitutionDict).
	^stmtList
]

{ #category : #'primitive compilation' }
JSMethod >> argConversionExprFor: varName stackIndex: stackIndex [ 
	"Return the parse tree for an expression that fetches and converts the 
	primitive argument at the given stack offset."
	| exprList decl stmtList |
	oneBasedArrays ifNil: [oneBasedArrays := Set new]. "only non-nil in a primitive method"
	exprList := OrderedCollection new.
	(declarations includesKey: varName) ifTrue:[
		decl := declarations at: varName.
		(decl includes: $*) ifTrue:["array"
			(decl includesSubString: 'char') ifTrue:[
				exprList add: varName , ' := ', self vmNameString, ' stackBytes: ',stackIndex printString] ifFalse: [
			(decl beginsWith: 'unsigned int') ifTrue:[
				exprList add: varName , ' := ', self vmNameString, ' stackWords: ',stackIndex printString] ifFalse: [
			(decl beginsWith: 'unsigned short') ifTrue:[
				exprList add: varName , ' := ', self vmNameString, ' stackUint16Array: ',stackIndex printString] ifFalse: [
			(decl beginsWith: 'short int') ifTrue:[
				exprList add: varName , ' := ', self vmNameString, ' stackInt16Array: ',stackIndex printString] ifFalse: [
			(decl beginsWith: 'int') ifTrue:[
				exprList add: varName , ' := ', self vmNameString, ' stackInt32Array: ',stackIndex printString]
			ifFalse: [self halt]]]]].
			self beOneBasedArray: varName.
		] ifFalse:["must be a double"
			(decl findString: 'double' startingAt: 1) = 0 ifTrue: [
				self error: 'unsupported type declaration in a primitive method'
			].
			exprList add: varName , ' := ', self vmNameString, ' stackFloatValue: ' , stackIndex printString.
		]
	] ifFalse: ["undeclared variables are taken to be integer"
		exprList add: varName , ' := ', self vmNameString, ' stackIntegerValue: ' , stackIndex printString
	].
	stmtList := OrderedCollection new.
	exprList do: [:e | stmtList addAll: (self statementsFor: e varName: varName)].
	^ stmtList
]

{ #category : #accessing }
JSMethod >> args [
	"The arguments of this method."

	^args
]

{ #category : #transformations }
JSMethod >> asInlineNode [
	^TInlineNode new method: self
]

{ #category : #'JS code generation' }
JSMethod >> beOneBasedArray: varName [
	oneBasedArrays add: varName.

]

{ #category : #transformations }
JSMethod >> bindClassVariablesIn: constantDictionary [
	"Class variables are used as constants. This method replaces all references to class variables in the body of this method with the corresponding constant looked up in the class pool dictionary of the source class. The source class class variables should be initialized before this method is called."

	parseTree := parseTree bindVariablesIn: constantDictionary.
]

{ #category : #transformations }
JSMethod >> bindVariableUsesIn: aDictionary [
	parseTree := parseTree bindVariableUsesIn: aDictionary.
]

{ #category : #transformations }
JSMethod >> buildCaseStmt: aSendNode [
	"Build a case statement node for the given send of dispatchOn:in:."
	"Note: the first argument is the variable to be dispatched on. The second argument is a constant node holding an array of unary selectors, which will be turned into sends to self."

	((aSendNode args size >= 2) and:
	 [aSendNode args second isConstant and:
	 [aSendNode args second value class = Array]]) ifFalse: [
		self error: 'wrong node structure for a case statement'.
	].

	^TCaseStmtNode new
		setExpression: aSendNode args first
		selectors: aSendNode args second value
		arguments: (aSendNode args copyFrom: 3 to: aSendNode args size)
]

{ #category : #inlining }
JSMethod >> checkForCompleteness: stmtLists in: aCodeGen [
	"Set the complete flag if none of the given statement list nodes contains further candidates for inlining."

	complete := true.
	stmtLists do: [ :stmtList |
		stmtList statements do: [ :node |
			(self inlineableSend: node in: aCodeGen) ifTrue: [
				complete := false.  "more inlining to do"
				^self
			].
		].
	].
	parseTree nodesDo: [ :n |
		(self inlineableFunctionCall: n in: aCodeGen) ifTrue: [
			complete := false.  "more inlining to do"
			^self
		].
	].
]

{ #category : #'primitive compilation' }
JSMethod >> checkSuccessExpr [
	"Return the parse tree for an expression that aborts the primitive if the successFlag is not true."

	| expr |
	expr := 'interpreterProxy failed ifTrue: [^ nil ]'.
	^ self statementsFor: expr varName: ''

]

{ #category : #accessing }
JSMethod >> comment: aComment [

	comment := aComment 
]

{ #category : #'inlining support' }
JSMethod >> computePossibleSideEffectsIn: aCodeGen [
	"Answer true if this method may have side effects. It has side effects if it assigns to a global variable. It may have side effects if it calls a non-built-in method."

	parseTree nodesDo: [ :node |
		node isSend ifTrue: [
			node isBuiltinOperator ifFalse: [ ^true ].
		].
	].
	^ false
]

{ #category : #utilities }
JSMethod >> copy [
	"Make a deep copy of this JSMethod."

	^ (self class basicNew)
		setSelector: selector
		returnType: returnType
		args: args copy
		locals: locals copy
		declarations: declarations copy
		primitive: primitive
		parseTree: parseTree copyTree
		labels: labels copy
		complete: complete;
		sharedLabel: sharedLabel;
		sharedCase: sharedCase;
		yourself

]

{ #category : #'primitive compilation' }
JSMethod >> covertToZeroBasedArrayReferences [
	"Replace the index expressions in at: and at:put: messages with (<expr> - 1), since C uses zero-based array indexing."
	"Note: Up through release 1.31, generated primitives used the convention that array variables pointed to the first element. That meant that Smalltalk one-based index expressions had to have one subtracted to yield a zero-based index. Later, we decided to adjust the base address by -1 once in the primitive prolog rather on every array access. This resulted in a five percent performance increase for the bitmap compress/decompress primitives. This method is retained as documentation and in case we choose to revert the the previous scheme."

	| oldIndexExpr newIndexExpr |
	parseTree nodesDo: [ :n |
		(n isSend and: [(n selector = #at:) or: [ n selector = #at:put: ]]) ifTrue: [
			oldIndexExpr := n args first.
			oldIndexExpr isConstant ifTrue: [
				"index expression is a constant: decrement the constant now"
				newIndexExpr := TConstantNode new setValue: (n args first value - 1).
			] ifFalse: [
				"index expression is complex: build an expression to decrement result at runtime"
				newIndexExpr := TSendNode new
					setSelector: #-
					receiver: oldIndexExpr
					arguments: (Array with: (TConstantNode new setValue: 1)).
			].
			n args at: 1 put: newIndexExpr.
		].
	].

]

{ #category : #accessing }
JSMethod >> declarationAt: aVariableName [
	^declarations at: aVariableName ifAbsent: [#sqInt, ' ', aVariableName]
]

{ #category : #accessing }
JSMethod >> declarationAt: aVariableName  "<String>" put: aDeclaration [ "<String>" "^aDeclaration"
	^declarations at: aVariableName put: aDeclaration
]

{ #category : #accessing }
JSMethod >> declarations [
	"The type declaration dictionary of this method."

	^declarations
]

{ #category : #accessing }
JSMethod >> definingClass [
	^definingClass
]

{ #category : #accessing }
JSMethod >> definingClass: aClass [
	definingClass := aClass.
]

{ #category : #'JS code generation' }
JSMethod >> emitGlobalStructReferenceOn: aStream [
	"Add a reference to the globals struct if needed"

	(self globalStructureBuildMethodHasFoo > 1)
		ifTrue: [aStream nextPutAll: 'var foo = fum;'; cr].

]

{ #category : #'JS code generation' }
JSMethod >> emitInlineOn: aStream level: level generator: aCodeGen [
	"Emit C code for this method onto the given stream. All calls to inlined methods should already have been expanded."
	self removeUnusedTemps.
	sharedLabel ifNotNil:[
		aStream crtab: level-1; nextPutAll: sharedLabel; nextPutAll:':'.
		aStream crtab: level.
		aStream nextPutAll: '/* '; nextPutAll: selector; nextPutAll: ' */'.
		aStream crtab: level.
	].
	aStream nextPutAll:'{'; cr.
	locals do: [ :var |
		aStream tab: level+1.
		aStream nextPutAll: (declarations at: var ifAbsent: [ 'sqInt ', var]), ';'; cr.
	].
	parseTree emitJSCodeOn: aStream level: level+1 generator: aCodeGen.
	aStream tab: level; nextPutAll: '}'; cr.
]

{ #category : #'JS code generation' }
JSMethod >> emitJSCodeOn: aStream generator: aCodeGen [
	"Emit JS code for this method onto the given stream. All calls to inlined methods should already have been expanded."
	aCodeGen currentMethod: self.
	aCodeGen pushScope: declarations while: [
		self emitJSCommentOn: aStream.	"place method comment before function"
		self emitJSHeaderOn: aStream generator: aCodeGen.
		parseTree emitJSCodeOn: aStream level: 1 generator: aCodeGen.
		aStream nextPutAll: '}'; cr]
]

{ #category : #'JS code generation' }
JSMethod >> emitJSCommentOn: aStream [
	"Emit the transferred Smalltalk comments as C comments."

	comment ifNotNil: [
		aStream cr;cr.
		1 to: comment size do: [:index | 
			aStream 
				nextPutAll: '/*'; tab;
				nextPutAll: (comment at: index);
				nextPutAll: ' */';
				cr]]
]

{ #category : #'JS code generation' }
JSMethod >> emitJSFunctionHeader: aStream generator: aCodeGen [
	"Emit a C function header for this method onto the given stream."

	properties ifNotNil:
		[(properties at: #api: ifAbsent: []) ifNotNil:
			[:pragma|
			aStream nextPutAll: (pragma argumentAt: 1).
			^self]].
	self emitJSFunctionHeader: aStream generator: aCodeGen newlineBeforeName: false
]

{ #category : #'JS code generation' }
JSMethod >> emitJSFunctionHeader: aStream generator: aCodeGen newlineBeforeName: newlineBeforeName [ "<Boolean>"
	"Emit a JS function header for this method onto the given stream."

	aStream nextPutAll: 'function'.
	newlineBeforeName ifTrue: [aStream cr] ifFalse: [aStream space].
	(returnType last = $)
	and: [returnType includesSubString: (aCodeGen cFunctionNameFor: self selectorForCodeGeneration)]) ifTrue:
		["Hack fix for e.g. <returnTypeC: 'void (*setInterruptCheckChain(void (*aFunction)(void)))()'>"
		 ^self].
	aStream
		nextPutAll: (aCodeGen cFunctionNameFor: self selectorForCodeGeneration);
		nextPut: $(.
	args
		do: [:arg | aStream nextPutAll: (aCodeGen returnPrefixFromVariable: arg)]
		separatedBy: [ aStream nextPutAll: ', ' ].
	aStream nextPut: $)
]

{ #category : #'JS code generation' }
JSMethod >> emitJSHeaderOn: aStream generator: aCodeGen [
	"Emit a C function header for this method onto the given stream."

	aStream cr. 
	self emitJSFunctionHeader: aStream generator: aCodeGen.
	aStream nextPutAll: ' {'; cr.
	self emitGlobalStructReferenceOn: aStream.
	locals do: [ :var |
		aStream nextPutAll: '	var ', (aCodeGen returnPrefixFromVariable: var), ';'; cr.
	].
	locals isEmpty ifFalse: [ aStream cr ].
]

{ #category : #'JS code generation' }
JSMethod >> emitProxyFunctionPrototype: aStream generator: aCodeGen [
	"Emit an indirect C function header for this method onto the given stream."

	| arg |
	aStream nextPutAll: returnType; space.
	aStream nextPutAll: '(*', (aCodeGen cFunctionNameFor: self selectorForCodeGeneration), ')('.
	args isEmpty ifTrue: [ aStream nextPutAll: 'void' ].
	1 to: args size do: [ :i |
		arg := args at: i.
		(declarations includesKey: arg) ifTrue: [
			aStream nextPutAll: (declarations at: arg).
		] ifFalse: [
			aStream nextPutAll: 'sqInt ', (args at: i).
		].
		i < args size ifTrue: [ aStream nextPutAll: ', ' ].
	].
	aStream nextPutAll: ')'.
]

{ #category : #'inlining support' }
JSMethod >> endsWithReturn [
	"Answer true if the last statement of this method is a return."

	^ parseTree statements last isReturn
]

{ #category : #inlining }
JSMethod >> exitVar: exitVar label: exitLabel [
	"Replace each return statement in this method with an assignment to the exit variable followed by a goto to the given label. Return true if a goto was generated."
	"Optimization: If exitVar is nil, the return value of the inlined method is not being used, so don't add the assignment statement."

	| newStmts labelUsed |
	labelUsed := false.
	parseTree nodesDo: [ :node |
		node isStmtList ifTrue: [
			newStmts := OrderedCollection new: 100.
			node statements do: [ :stmt |
				(stmt isReturn) ifTrue: [
					exitVar = nil ifTrue: [
						stmt expression isLeaf ifFalse: [
							"evaluate return expression even though value isn't used"
							newStmts add: stmt expression.
						].
					] ifFalse: [
						"assign return expression to exit variable"
						newStmts add:
							(TAssignmentNode new
								setVariable: (TVariableNode new setName: exitVar)
								expression: stmt expression).
					].
					(stmt == parseTree statements last) ifFalse: [
						"generate a goto (this return is NOT the last statement in the method)"
						newStmts add: (TGoToNode new setLabel: exitLabel).
						labelUsed := true.
					].
				] ifFalse: [
					newStmts addLast: stmt.
				].
			].
			node setStatements: newStmts asArray.
		].
	].
	^labelUsed
]

{ #category : #accessing }
JSMethod >> export [

	^ export

]

{ #category : #transformations }
JSMethod >> extractDirective: theSelector valueBlock: aBlock default: defaultResult [
	"Find a pragma of the form:

		<theSelector[args]>

	 Answer the result of evaluating aBock with a TSendNode corresponding
	 to the pragma node, or defaultResult if there is no matching pragma."

	| result found newStatements |
	(properties at: theSelector ifAbsent: []) ifNotNil:
		[:pragma|
		^aBlock value: (TSendNode new
							setSelector: pragma keyword
							receiver: (TVariableNode new setName: 'self')
							arguments: (pragma arguments collect: [:const| TConstantNode new setValue: const]))].
	"Pre-pragma backward compatibility:
	 Scan the top-level statements for a labelling directive of the form:

		self theSelector[args]

	 and remove the directive from the method body if found.
	 Answer the result of evaluating aBock with the send node,
	  or defaultResult if there is no labelling directive."	result := defaultResult.
	found := false.
	newStatements := OrderedCollection new: parseTree statements size.
	parseTree statements do:
		[ :stmt |
		(stmt isSend
		 and: [stmt selector = theSelector])
			ifTrue:
				[found := true.
				 result := aBlock value: stmt]
			ifFalse:
				[newStatements add: stmt]].
	^found
		ifTrue:
			[parseTree setStatements: newStatements asArray.
			 result]
		ifFalse: [defaultResult]
]

{ #category : #transformations }
JSMethod >> extractExpandCaseDirective [
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
JSMethod >> extractExportDirective [
	"Scan the top-level statements for an inlining directive of the form:

		self export: <boolean>

	 and remove the directive from the method body. Return the argument of the directive or false if there is no export directive."

	| result newStatements methodDirectiveFound |
	result := false.
	methodDirectiveFound := false.
	newStatements := OrderedCollection new: parseTree statements size.
	parseTree statements do: [ :stmt |
		(stmt isSend and: [stmt selector = #export:]) ifTrue: [
			methodDirectiveFound := true.
			result := stmt args first value = true.
		] ifFalse: [
			newStatements add: stmt.
		].
	].
	parseTree setStatements: newStatements asArray.
	methodDirectiveFound ifTrue: [^ result].
	"no method declaration was used, so check for a pragma declaration"
	^self
		extractDirective: #export:
		valueBlock: [:sendNode| sendNode args first value ~= false]
		default: false

]

{ #category : #'inlining support' }
JSMethod >> extractInlineDirective [
	"Scan the top-level statements for an inlining directive of the form:

		self inline: <boolean>

	 and remove the directive from the method body. Return the argument of the directive or #dontCare if there is no inlining directive."

	| result newStatements methodDirectiveFound |
	sharedCase ifNotNil:[^false]. "don't auto-inline shared code; it gets handled specially"
	result := #dontCare.
	methodDirectiveFound := false.
	newStatements := OrderedCollection new: parseTree statements size.
	parseTree statements do: [ :stmt |
		(stmt isSend and: [stmt selector = #inline:]) ifTrue: [
			methodDirectiveFound := true.
			result := stmt args first value = true.
		] ifFalse: [
			newStatements add: stmt.
		].
	].
	parseTree setStatements: newStatements asArray.
	methodDirectiveFound ifTrue: [^ result].
	"no method declaration was used, so check for a pragma declaration"
	sharedCase ifNotNil: [^false]. "don't auto-inline shared code; it gets handled specially"
	^self
		extractDirective: #inline:
		valueBlock: [:sendNode| sendNode args first value = true]
		default: #dontCare
]

{ #category : #transformations }
JSMethod >> extractLabelDirective [
	"Scan the top-level statements for an inlining directive of the form:

		self asmLabel: <boolean>

	 and remove the directive from the method body. Answer the
	 argument of the directive or true if there is no export directive."

	^self
		extractDirective: #asmLabel:
		valueBlock: [:sendNode| sendNode args first value ~= false and: [mustAsmLabel := true. true]]
		default: true
]

{ #category : #transformations }
JSMethod >> extractSharedCase [
	"Scan the top-level statements for an shared case directive of the form:

		self sharedCodeNamed: <sharedLabel> inCase: <sharedCase>.

	and remove the directive from the method body."

	| newStatements |
	newStatements := OrderedCollection new: parseTree statements size.
	parseTree statements do: [ :stmt |
		(stmt isSend and: [stmt selector = #sharedCodeNamed:inCase:]) ifTrue: [
			sharedLabel := stmt args first value.
			sharedCase := stmt args last value
		] ifFalse: [
			newStatements add: stmt.
		].
	].
	parseTree setStatements: newStatements asArray.
	sharedCase ifNotNil:[
		args isEmpty ifFalse:[self error: 'Cannot share code sections in methods with arguments'].
	].
]

{ #category : #transformations }
JSMethod >> extractStaticDirective [
	"Scan the top-level statements for an inlining directive of the form:

		self static: <boolean>

	and remove the directive from the method body. Answer the argument of the
	directive. If there is no static directive, answer true if this is an api method,
	otherwise answer nil for undefined. The code generator may determine the
	static declaration when undefined."

	^self
		extractDirective: #static:
		valueBlock: [:sendNode| sendNode args first value ~= false]
		default: (((properties includesKey: #api) or: [properties includesKey: #api:])
					ifTrue: [false] "api methods cannot be declared static"
					ifFalse: [nil]) "undefined, defer to the code generator for default"
]

{ #category : #'primitive compilation' }
JSMethod >> fetchRcvrExpr [
	"Return the parse tree for an expression that fetches the receiver from the stack."

	| expr |
	expr := 'rcvr := ', self vmNameString, ' stackValue: (', args size printString, ')'.
	^ self statementsFor: expr varName: ''

]

{ #category : #'primitive compilation' }
JSMethod >> fixUpReturns: argCount postlog: postlog [
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
								newStmts addLast: (TSendNode new
									setSelector: #pop:thenPush:
									receiver: (TVariableNode new setName: self vmNameString)
									arguments: {TConstantNode new setValue: argCount + 1. stmt expression}).
								newStmts addLast: (TReturnNode new
									setExpression: (TVariableNode new setName: 'null'))]]
					ifFalse: [
						newStmts addLast: stmt]].
			node setStatements: newStmts asArray]].

]

{ #category : #utilities }
JSMethod >> freeVariableReferences [
	"Answer a collection of variables referenced this method, excluding locals, arguments, and pseudovariables."

	| refs |
	refs := Set new.
	parseTree nodesDo: [ :node |
		node isVariable ifTrue: [ refs add: node name asString ].
	].
	args do: [ :var | refs remove: var asString ifAbsent: [] ].
	locals do: [ :var | refs remove: var asString ifAbsent: [] ].
	#('self' 'nil' 'true' 'false') do: [ :var | refs remove: var ifAbsent: [] ].
	^ refs asSortedCollection
]

{ #category : #accessing }
JSMethod >> globalStructureBuildMethodHasFoo [
	^globalStructureBuildMethodHasFoo
]

{ #category : #accessing }
JSMethod >> globalStructureBuildMethodHasFoo: number [
	globalStructureBuildMethodHasFoo := number
]

{ #category : #'inlining support' }
JSMethod >> hasDoNotGenerateStatement [
	"True if method has a #doNotGenerate statement, equivalent to pragma <doNotGenerate>
	or if it has a #subclassResponsibility statement."
	parseTree statements
		detect: [:stmt | stmt isSend
					and: [stmt selector = #doNotGenerate
						or: [stmt selector = #subclassResponsibility]]]
		ifNone: [^ false].
	^ true
]

{ #category : #utilities }
JSMethod >> hasNoCCode [
	"Answer true if the receiver does not use inlined C or C declarations, which are not currently renamed properly by the the inliner."

	declarations isEmpty ifFalse: [ ^ false ].

	parseTree nodesDo: [ :node |
		node isSend ifTrue: [
			node selector = #cCode: ifTrue: [ ^ false ].
		].
	].
	^ true
]

{ #category : #testing }
JSMethod >> hasReturn [
	"Answer true if this method contains a return statement."

	parseTree nodesDo: [ :n | n isReturn ifTrue: [ ^ true ]].
	^ false
]

{ #category : #inlining }
JSMethod >> inlineCaseStatementBranchesIn: aCodeGen localizingVars: varsList [

	| stmt sel meth newStatements maxTemp usedVars exitLabel v |
	maxTemp := 0.
	parseTree nodesDo: [ :n |
		n isCaseStmt ifTrue: [
			n cases do: [ :stmtNode |
				stmt := stmtNode statements first.
				stmt isSend ifTrue: [
					sel := stmt selector.
					meth := aCodeGen methodNamed: sel.
					"Note, original version of this method tested for #hasNoCCode. Removed
					the test to permit inlining methods that may contain automatically
					generated C code for type conversions. -dtl"
					((meth ~= nil) and:
					 [meth args size = 0]) ifTrue: [
						meth := meth copy.
						meth hasReturn ifTrue: [
							exitLabel := self unusedLabelForInliningInto: self.
							meth exitVar: nil label: exitLabel.
							labels add: exitLabel.
						] ifFalse: [ exitLabel := nil ].

						meth renameLabelsForInliningInto: self.
						meth labels do: [ :label | labels add: label ].
						newStatements := stmtNode statements asOrderedCollection.
						newStatements removeFirst.

						exitLabel ~= nil ifTrue: [
							newStatements addFirst:
								(TLabeledCommentNode new
									setLabel: exitLabel comment: 'end case').
						].

						newStatements addFirst: meth asInlineNode.
						newStatements addFirst:
							(TLabeledCommentNode new setComment: meth selector).
						stmtNode setStatements: newStatements.
					].
				].
			].
		].
	].
	usedVars := (locals, args) asSet.
	1 to: maxTemp do: [ :i |
		v := ('t', i printString).
		(usedVars includes: v) ifTrue: [ self error: 'temp variable name conflicts with an existing local or arg' ].
		locals addLast: v.
	].

	"make local versions of the given globals"
	varsList do: [ :var |
		(usedVars includes: var) ifFalse: [ locals addFirst: var asString ].
	].

]

{ #category : #inlining }
JSMethod >> inlineCodeOrNilForStatement: aNode in: aCodeGen [
	"If the given statement node can be inlined, answer the statements that replace it. Otherwise, answer nil."

	| stmts |
	aNode isReturn ifTrue: [
		(self inlineableSend: aNode expression in: aCodeGen) ifTrue: [
			stmts := self inlineSend: aNode expression
				directReturn: true exitVar: nil in: aCodeGen.
			^stmts
		].
	].
	aNode isAssignment ifTrue: [
		(self inlineableSend: aNode expression in: aCodeGen) ifTrue: [
			^self inlineSend: aNode expression
				directReturn: false exitVar: aNode variable name in: aCodeGen
		].
	].
	aNode isSend ifTrue: [
		(self inlineableSend: aNode in: aCodeGen) ifTrue: [
			^self inlineSend: aNode
				directReturn: false exitVar: nil in: aCodeGen
		].
	].
	^nil
]

{ #category : #inlining }
JSMethod >> inlineFunctionCall: aSendNode in: aCodeGen [
	"Answer the body of the called function, substituting the actual parameters for the formal argument variables in the method body."
	"Assume caller has established that:
		1. the method arguments are all substitutable nodes, and
		2. the method to be inlined contains no additional embedded returns."

	| sel meth substitutionDict |
	sel := aSendNode selector.
	meth := (aCodeGen methodNamed: sel) copy.
	meth renameVarsForInliningInto: self in: aCodeGen.
	meth renameLabelsForInliningInto: self.
	self addVarsDeclarationsAndLabelsOf: meth.
	substitutionDict := Dictionary new: 100.
	meth args with: aSendNode args do: [ :argName :exprNode |
		substitutionDict at: argName put: exprNode.
		locals remove: argName.
		declarations removeKey: argName ifAbsent: []].
	meth parseTree bindVariablesIn: substitutionDict.
	^ meth statements first expression
]

{ #category : #inlining }
JSMethod >> inlineSend: aSendNode directReturn: directReturn exitVar: exitVar in: aCodeGen [
	"Answer a collection of statments to replace the given send. directReturn indicates that the send is the expression of a return statement, so returns can be left in the body of the inlined method. If exitVar is nil, the value returned by the send is not used; thus, returns need not assign to the output variable."

	| sel meth exitLabel labelUsed inlineStmts |
	sel := aSendNode selector.
	meth := (aCodeGen methodNamed: sel) copy.
	meth renameVarsForInliningInto: self in: aCodeGen.
	meth renameLabelsForInliningInto: self.
	self addVarsDeclarationsAndLabelsOf: meth.
	meth hasReturn ifTrue: [
		directReturn ifTrue: [
			"propagate the return type, if necessary"
			returnType = meth returnType ifFalse: [ self halt ].  "caller's return type should be declared by user"
			returnType := meth returnType.
		] ifFalse: [
			exitLabel := self unusedLabelForInliningInto: self.
			labelUsed := meth exitVar: exitVar label: exitLabel.
			labelUsed
				ifTrue: [ labels add: exitLabel ]
				ifFalse: [ exitLabel := nil ].
		].
		"propagate type info if necessary"
		((exitVar ~= nil) and: [meth returnType ~= 'sqInt']) ifTrue: [
			declarations at: exitVar put: meth returnType, ' ', exitVar.
		].
	].
	inlineStmts := OrderedCollection new: 100.
	inlineStmts add: (TLabeledCommentNode new setComment: 'begin ', sel).
	inlineStmts addAll:
		(self argAssignmentsFor: meth args: aSendNode args in: aCodeGen).
	inlineStmts addAll: meth statements.  "method body"
	(directReturn and: [meth endsWithReturn not]) ifTrue: [
		inlineStmts add: (TReturnNode new setExpression: (TVariableNode new setName: 'nil')).
	].
	exitLabel ~= nil ifTrue: [
		inlineStmts add:
			(TLabeledCommentNode new
				setLabel: exitLabel comment: 'end ', meth selector).
	].
	^inlineStmts
]

{ #category : #inlining }
JSMethod >> inlineableFunctionCall: aNode in: aCodeGen [
	"Answer true if the given send node is a call to a 'functional' method--a method whose body is a single return statement of some expression and whose actual parameters can all be directly substituted."

	| m |
	aNode isSend ifFalse: [ ^false ].
	m := aCodeGen methodNamed: aNode selector.  "nil if builtin or external function"
	((m ~= nil) and: [m isFunctional and: [aCodeGen mayInline: m selector]]) ifTrue: [
		aNode args do: [ :a | (self isSubstitutableNode: a intoMethod: m in: aCodeGen) ifFalse: [ ^false ]].
		^true
	] ifFalse: [
		^false
	].
]

{ #category : #inlining }
JSMethod >> inlineableSend: aNode in: aCodeGen [
	"Answer true if the given send node is a call to a method that can be inlined."

	| m |
	aNode isSend ifFalse: [ ^false ].
	m := aCodeGen methodNamed: aNode selector.  "nil if builtin or external function"
	^(m ~= nil) and: [m isComplete and: [aCodeGen mayInline: m selector]]
]

{ #category : #'primitive compilation' }
JSMethod >> instVarGetExprFor: varName offset: instIndex [
	"Return the parse tree for an expression that fetches and converts the value of the instance variable at the given offset."

	| exprList decl stmtList |
	exprList := OrderedCollection new.
	(declarations includesKey: varName) ifTrue: [
		decl := declarations at: varName.
		(decl includes: $*) ifTrue: ["array"
			(decl includesSubString: 'char') ifTrue:[
				exprList add: varName , ' := ', self vmNameString, ' fetchBytes: ', instIndex printString, ' ofObject: rcvr'] ifFalse: [
			(decl includesSubString: 'unsigned int') ifTrue:[
				exprList add: varName , ' := ', self vmNameString, ' fetchWords: ', instIndex printString, ' ofObject: rcvr'] ifFalse: [
			(decl beginsWith: 'unsigned short') ifTrue:[
				exprList add: varName , ' := ', self vmNameString, ' fetchUint16Array: ', instIndex printString, ' ofObject: rcvr'] ifFalse: [
			(decl beginsWith: 'short int') ifTrue:[
				exprList add: varName , ' := ', self vmNameString, ' fetchInt16Array: ', instIndex printString, ' ofObject: rcvr'] ifFalse: [
			(decl beginsWith: 'int') ifTrue:[
				exprList add: varName , ' := ', self vmNameString, ' fetchInt32Array: ', instIndex printString, ' ofObject: rcvr']
			ifFalse: [self halt]]]]].
			self beOneBasedArray: varName.
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
JSMethod >> instVarPutExprFor: varName offset: instIndex [
	"Return the parse tree for an expression that saves the value of the integer instance variable at the given offset."

	| expr |
	(declarations includesKey: varName) ifTrue: [
		self error: 'a primitive method can only modify integer instance variables'.
	].
	expr := '', self vmNameString, ' storeInteger: ', instIndex printString, ' ofObject: rcvr withValue: ', varName.
	^ self statementsFor: expr varName: varName

]

{ #category : #testing }
JSMethod >> isAssertion [
	^(selector beginsWith: 'assert') or: [selector beginsWith: 'verify']
]

{ #category : #accessing }
JSMethod >> isComplete [
	"A method is 'complete' if it does not contain any more inline-able calls."

	^complete
]

{ #category : #inlining }
JSMethod >> isFunctional [
	"Answer true if the receiver is a functional method. That is, if it consists of a single return statement of an expression that contains no other returns."

	(parseTree statements size = 1 and:
	 [parseTree statements last isReturn]) ifFalse: [ ^false ].
	parseTree statements last expression nodesDo: [ :n | n isReturn ifTrue: [ ^false ]].
	^true
]

{ #category : #'JS code generation' }
JSMethod >> isOneBasedArray: varName [
	^oneBasedArrays ifNotNil: [oneBasedArrays includes: varName].

]

{ #category : #accessing }
JSMethod >> isStaticIn: aCodeGen [
	"If static has been explicitly set, honor that setting. Otherwise defer
	to the code generator for a default setting."
	^static ifNil: [aCodeGen declareMethodsStatic]
]

{ #category : #inlining }
JSMethod >> isSubstitutableNode: aNode [
	"Answer true if the given parameter node is either a constant, a local variable, or a formal parameter of the receiver. Such parameter nodes may be substituted directly into the body of the method during inlining. Note that global variables cannot be subsituted because the inlined method might depend on the exact ordering of side effects to the globals."

	aNode isConstant ifTrue: [ ^true ].
	^aNode isVariable and:
		[(locals includes: aNode name) or:
		[args includes: aNode name]]
]

{ #category : #inlining }
JSMethod >> isSubstitutableNode: aNode intoMethod: targetMeth in: aCodeGen [
	"Answer true if the given parameter node is either a constant, a local variable, or a formal parameter of the receiver. Such parameter nodes may be substituted directly into the body of the method during inlining. Note that global variables cannot be subsituted into methods with possible side effects (i.e., methods that may assign to global variables) because the inlined method might depend on having the value of the global variable captured when it is passed in as an argument."

	| var |
	aNode isConstant ifTrue: [ ^ true ].

	aNode isVariable ifTrue: [
		var := aNode name.
		((locals includes: var) or: [args includes: var]) ifTrue: [ ^ true ].
		(#(self true false nil) includes: var) ifTrue: [ ^ true ].
		(targetMeth maySubstituteGlobal: var in: aCodeGen) ifTrue: [ ^ true ].
	].

	"scan expression tree; must contain only constants, builtin ops, and inlineable vars"
	aNode nodesDo: [ :node |
		node isSend ifTrue: [
			node isBuiltinOperator ifFalse: [ ^false ].
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

{ #category : #accessing }
JSMethod >> labels [

	^labels
]

{ #category : #accessing }
JSMethod >> locals [
	"The local variables of this method."

	^locals
]

{ #category : #transformations }
JSMethod >> mapReceiversIn: aDictionary [
	parseTree mapReceiversIn: aDictionary.
]

{ #category : #'inlining support' }
JSMethod >> maySubstituteGlobal: globalVar in: aCodeGen [
	"Answer true if this method does or may have side effects on the given global variable."

	possibleSideEffectsCache = nil ifTrue: [
		"see if this calls any other method and record the result"
		possibleSideEffectsCache := self computePossibleSideEffectsIn: aCodeGen.
	].
	possibleSideEffectsCache ifTrue: [ ^ false ].

	parseTree nodesDo: [ :node |
		node isAssignment ifTrue: [
			node variable name = globalVar ifTrue: [ ^ false ].
		].
	].

	"if we get here, receiver calls no other method
	 and does not itself assign to the given global variable"
	^ true
]

{ #category : #initialization }
JSMethod >> newCascadeTempFor: aTParseNode [
	| varNode |
	cascadeVariableNumber := cascadeVariableNumber
								ifNil: [0]
								ifNotNil: [cascadeVariableNumber + 1].
	varNode := TVariableNode new setName: 'cascade', cascadeVariableNumber printString.
	aTParseNode isLeaf ifFalse:
		[declarations
			at: varNode name
			put: [:cg| self determineTypeFor: aTParseNode in: cg]].
	^varNode
]

{ #category : #utilities }
JSMethod >> nodeCount [
	"Answer the number of nodes in this method's parseTree (a rough measure of its size)."

	| cnt |
	cnt := 0.
	parseTree nodesDo: [ :n | cnt := cnt + 1 ].
	^cnt
]

{ #category : #'JS code generation' }
JSMethod >> oneBasedArrays [
	^oneBasedArrays
]

{ #category : #accessing }
JSMethod >> parseTree [
	"The parse tree of this method."

	^parseTree
]

{ #category : #accessing }
JSMethod >> parseTree: aNode [
	"Set the parse tree of this method."

	parseTree := aNode.
]

{ #category : #'primitive compilation' }
JSMethod >> popArgsExpr: argCount [
	"Return the parse tree for an expression that pops the given number of arguments from the stack."

	| expr |
	expr := '', self vmNameString, ' pop: ', argCount printString.
	^ self statementsFor: expr varName: ''

]

{ #category : #transformations }
JSMethod >> prepareMethodIn: aCodeGen [
	"Record sends of builtin operators, map sends of the special selector dispatchOn:in:
	 with case statement nodes, and map sends of caseOf:[otherwise:] to switch statements.
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
					[(aCodeGen isBuiltinSelector: node selector)
						ifTrue:
							[node isBuiltinOperator: true.
							"If a to:by:do:'s limit has side-effects, declare the limit variable, otherwise delete it from the args"
							 (node selector = #to:by:do:
							  and: [node args size = 4]) ifTrue:
								[| limitExpr |
								 limitExpr := node args first.
								 (limitExpr anySatisfy:
										[:subNode|
										subNode isSend
										and: [(aCodeGen isBuiltinSelector: subNode selector) not
										and: [(subNode isStructSendIn: aCodeGen) not]]])
									ifTrue: [ | limitVar |
										limitVar := node args last name.
										"n.b. Two loops in the same method may share the same variable
										for loop limit, so add the variable declaration only if not already
										declared by a previous loop. Assumes that the name of the loop
										limit variable (e.g. 'iLimiT') is unlikely to have been used as an actual
										instance variable elsewhere." 
										(locals includes: limitVar) ifFalse: [locals add: limitVar]]
									ifFalse:
										[node arguments: node args allButLast]]]
						ifFalse:
							[(CaseStatements includes: node selector) ifTrue:
								[parent replaceNodesIn: (Dictionary newFromPairs: { node. self buildCaseStmt: node})].
							 (#(caseOf: #caseOf:otherwise:) includes: node selector) ifTrue:
								[parent replaceNodesIn: (Dictionary newFromPairs: { node. self buildSwitchStmt: node parent: parent })]]]]]
]

{ #category : #'primitive compilation' }
JSMethod >> preparePrimitiveName [
	"Prepare the selector for this method in translation"
	| aClass |
	aClass := definingClass.
	primitive = 117 
		ifTrue:[selector := ((aClass includesSelector: selector)
					ifTrue: [aClass compiledMethodAt: selector]
					ifFalse: [aClass class compiledMethodAt: selector]) literals first at: 2.
				export := true]
		ifFalse:[selector := 'prim', aClass name, selector].


]

{ #category : #'primitive compilation' }
JSMethod >> preparePrimitivePrologue [
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
selector == #setInterpreter: ifTrue:[self halt].
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

	locals addAllFirst: args.
	locals addFirst: 'rcvr'.
	args := args class new.
	locals asSet size = locals size
		ifFalse: [self error: 'local name conflicts with instance variable name'].
	endsWithReturn := self endsWithReturn.
	self fixUpReturns: primArgCount postlog: postlog.

	endsWithReturn
		ifTrue: [parseTree setStatements: prolog, parseTree statements]
		ifFalse: [
			postlog addAll: (self popArgsExpr: primArgCount).
			parseTree setStatements: prolog, parseTree statements, postlog].

]

{ #category : #accessing }
JSMethod >> primitive [
	"The primitive number of this method; zero if not a primitive."

	^ primitive

]

{ #category : #printing }
JSMethod >> printOn: aStream [

	super printOn: aStream.
	aStream nextPutAll: ' (', selector, ')'.
]

{ #category : #private }
JSMethod >> printTempsAndVar: varName on: aStream [ 
	"add the required temps and the varname to the stream"
	aStream nextPutAll: '| rcvr stackPointer successFlag ' , varName , ' |';
	 cr
]

{ #category : #transformations }
JSMethod >> recordDeclarations [
	"Record C type declarations of the forms

		self returnTypeC: 'float'.
		self var: #foo declareC: 'float foo'
		self var: #foo type:'float'.

	 and remove the declarations from the method body."

	| newStatements |
	properties pragmas notEmpty ifTrue:
		[properties pragmas do:
			[:pragma|
			pragma keyword = #var:declareC: ifTrue:
				[self declarationAt: pragma arguments first asString put: pragma arguments last].
			pragma keyword = #var:type: ifTrue:
				[| varName varType |
				varName := pragma arguments first asString.
				varType := pragma arguments last.
				varType last = $* ifFalse: [varType := varType, ' '].
				self declarationAt: varName put: varType, varName].
			pragma keyword = #returnTypeC: ifTrue:
				[returnType := pragma arguments last].
			pragma keyword = #doNotGenerate: ifTrue:
				[locals remove: pragma arguments last]]].
	newStatements := OrderedCollection new: parseTree statements size.
	parseTree statements do: [ :stmt |
		| isDeclaration |
		isDeclaration := false.
		stmt isSend ifTrue: [
			stmt selector = #var:declareC: ifTrue: [
				isDeclaration := true.
				self declarationAt: stmt args first value asString put: stmt args last value.
			].
			stmt selector = #var:type: ifTrue: [
				| varName varType |
				isDeclaration := true.
				varName := stmt args first value asString.
				varType := stmt args last value.
				varType last = $* ifFalse: [varType := varType, ' '].
				self declarationAt: varName put: varType, varName.
			].
			stmt selector = #returnTypeC: ifTrue: [
				isDeclaration := true.
				returnType := stmt args last value.
			].
		].
		isDeclaration ifFalse: [
			newStatements add: stmt.
		].
	].
	parseTree setStatements: newStatements asArray.
]

{ #category : #accessing }
JSMethod >> referencesGlobalStructIncrementBy: value [
	globalStructureBuildMethodHasFoo := globalStructureBuildMethodHasFoo + value.
]

{ #category : #accessing }
JSMethod >> referencesGlobalStructMakeZero [
	globalStructureBuildMethodHasFoo := 0
]

{ #category : #transformations }
JSMethod >> removeAssertions [
	parseTree removeAssertions
]

{ #category : #transformations }
JSMethod >> removeFinalSelfReturn [
	"The Smalltalk parser automatically adds the statement '^self' to the end of methods without explicit returns. This method removes such statements, since the generated code has no notion of 'self' anyway."

	| stmtList lastStmt |
	stmtList := parseTree statements asOrderedCollection.
	lastStmt := stmtList last.

	((lastStmt isReturn) and:
	 [(lastStmt expression isVariable) and:
	 ['self' = lastStmt expression name]]) ifTrue: [
		stmtList removeLast.
		parseTree setStatements: stmtList.
	].
]

{ #category : #utilities }
JSMethod >> removeUnusedTemps [
	"Remove all of the unused temps in this method. Answer a bag (why the hell a bag???) with the references."
	"After inlining some variable references are now obsolete, we could fix them there but the 
	code seems a bit complicated, the other choice to to rebuild the locals before extruding. This is done here"
	| refs |
	refs := Bag new.
	"find all the variable names referenced in this method"
	parseTree nodesDo: [ :node |
		node isVariable ifTrue: [ refs add: node name asString ].
		node isStmtList ifTrue: [refs addAll: node args]].
	"add all the non-arg declarations (might be variables usedonly in cCode sections)"
	refs addAll:((self declarations keys) reject: [:e | self args includes: e]).
	"reset the locals to be only those still referred to"
	locals := locals select: [:e | refs includes: e].
	^refs

]

{ #category : #'inlining support' }
JSMethod >> renameLabelsForInliningInto: destMethod [
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
JSMethod >> renameLabelsUsing: aDictionary [
	"Rename all labels according to the old->new mappings of the given dictionary."

	labels := labels collect: [ :label |
		(aDictionary includesKey: label) ifTrue: [ aDictionary at: label ] ifFalse: [ label ].
	].

	parseTree nodesDo: [ :node |
		(node isGoTo and: [aDictionary includesKey: node label]) ifTrue: [
			node setLabel: (aDictionary at: node label).
		].
		(node isLabel and: [aDictionary includesKey: node label]) ifTrue: [
			node setLabel: (aDictionary at: node label).
		].
	].
]

{ #category : #transformations }
JSMethod >> renameSelector: selectorName as: newSelectorName [
	"Rename selectors such that generated code will use the newSelectorName. This
	is intended to allow methods that may have default implementations in the support
	code to be renamed for code generation, such that the renamed versions will
	be referenced rather than the default platform implementations. For example,
	if #pointerForOop: is implemented in Smalltalk, it may be renamed such that
	the generated pointerForOop() function will be renamed to avoid conflict with
	the standard definitions provided in sqMemoryAccess.h."

	selector = selectorName
		ifTrue: [selector := newSelectorName].
	parseTree nodesDo: [:node |
			node
				renameSelector: selectorName
				as: newSelectorName ]

]

{ #category : #'inlining support' }
JSMethod >> renameVariablesUsing: aDictionary [
	"Rename all variables according to old->new mappings of the given dictionary."

	| newDecls newKey newValue |
	"map args and locals"
	args := args collect: [ :arg |
		(aDictionary includesKey: arg) ifTrue: [ aDictionary at: arg ] ifFalse: [ arg ].
	].
	locals := locals collect: [ :v |
		(aDictionary includesKey: v) ifTrue: [ aDictionary at: v ] ifFalse: [ v ].
	].
	"prevent runaway recursion, e.g. inlining a method with super send"
	locals size > 1000 ifTrue: [self error: 'recursive inlining in ', selector asString, ', too many locals'].

	"map declarations"
	newDecls := declarations species new.
	declarations associationsDo: [ :assoc |
		(aDictionary includesKey: assoc key)
			ifTrue: [ newKey := aDictionary at: assoc key.
					newValue := assoc value replaceLastOccurrence: assoc key with: newKey.
					newDecls at: newKey put: newValue]
			ifFalse: [ newDecls add: assoc ].
	].
	declarations := newDecls.

	"map variable names in parse tree"
	parseTree nodesDo: [ :node |
		(node isVariable and:
		 [aDictionary includesKey: node name]) ifTrue: [
			node setName: (aDictionary at: node name).
		].
		(node isStmtList and: [node args size > 0]) ifTrue: [
			node setArguments:
				(node args collect: [ :arg |
					(aDictionary includesKey: arg)
						ifTrue: [ aDictionary at: arg ]
						ifFalse: [ arg ].
				]).
		].
	].
]

{ #category : #'inlining support' }
JSMethod >> renameVarsForCaseStmt [
	"Rename the arguments and locals of this method with names like t1, t2, t3, etc. Return the number of variable names assigned. This is done to allow registers to be shared among the cases."

	| i varMap |
	i := 1.
	varMap := Dictionary new: 100.
	args, locals do: [ :v |
		varMap at: v put: ('t', i printString) asSymbol.
		i := i + 1.
	].
	self renameVariablesUsing: varMap.
	^ i - 1
]

{ #category : #'inlining support' }
JSMethod >> renameVarsForInliningInto: destMethod in: aCodeGen [
	"Rename any variables that would clash with those of the destination method."

	| destVars usedVars varMap newVarName |
	destVars := aCodeGen globalsAsSet copy.
	destVars addAll: destMethod locals.
	destVars addAll: destMethod args.
	usedVars := destVars copy.  "keeps track of names in use"
	usedVars addAll: args; addAll: locals.
	varMap := Dictionary new: 100.
	args, locals do: [ :v |
		(destVars includes: v) ifTrue: [
			newVarName := self unusedNamePrefixedBy: v avoiding: usedVars.
			varMap at: v put: newVarName.
		].
	].
	self renameVariablesUsing: varMap.
]

{ #category : #transformations }
JSMethod >> replaceNodesIn: map [
	parseTree := parseTree replaceNodesIn: map.
]

{ #category : #'primitive compilation' }
JSMethod >> replaceSizeMessages [
	"Replace sends of the message 'size' with calls to sizeOfSTArrayFromCPrimitive."

	parseTree nodesDo: [:n |
		(n isSend and: [n selector = #size]) ifTrue: [
			n
				setSelector: #sizeOfSTArrayFromCPrimitive:
				receiver: (TVariableNode new setName: self vmNameString)
				arguments: (Array with: n receiver)]].

]

{ #category : #accessing }
JSMethod >> returnType [
	"The type of the values returned by this method. This string will be used in the C declaration of this function."

	^returnType
]

{ #category : #accessing }
JSMethod >> returnType: aString [
	"Set the type of the values returned by this method. This string will be used in the C declaration of this function."

	returnType := aString
]

{ #category : #accessing }
JSMethod >> selector [
	"The Smalltalk selector of this method."

	^selector
]

{ #category : #accessing }
JSMethod >> selector: newSelector [

	selector := newSelector.
]

{ #category : #accessing }
JSMethod >> selectorForCodeGeneration [
	"Subclasses may allow a directive to override the selector specification."

	^ selector
]

{ #category : #initialization }
JSMethod >> setSelector: sel definingClass: class args: argList locals: localList block: aBlockNode primitive: aNumber properties: methodProperties comment: aComment [
	"Initialize this method using the given information."

	selector := sel.
	definingClass := class.
	returnType := #sqInt. 	 "assume return type is long for now"
	args := argList asOrderedCollection collect: [:arg | arg key].
	locals := (localList asSortedCollection: [:a :b| a key < b key]) collect: [:arg | arg key].
	declarations := Dictionary new.
	"self addTypeForSelf." "<- Cog feature to be added later"
	primitive := aNumber.
	properties := methodProperties.
	comment := aComment.
	parseTree := aBlockNode asTranslatorNodeIn: self.
	labels := OrderedCollection new.
	complete := false.  "set to true when all possible inlining has been done"
	export := self extractExportDirective.
	static := self extractStaticDirective.
	canAsmLabel := self extractLabelDirective.
	self extractSharedCase.
	self removeFinalSelfReturn.	"must preceed recordDeclarations because this may set returnType"
	self recordDeclarations.
	globalStructureBuildMethodHasFoo := 0
]

{ #category : #initialization }
JSMethod >> setSelector: sel returnType: retType args: argList locals: localList declarations: decls primitive: primNumber parseTree: aNode labels: labelList complete: completeFlag [
	"Initialize this method using the given information. Used for copying."

	selector := sel.
	returnType := retType.
	args := argList.
	locals := localList.
	declarations := decls.
	primitive := primNumber.
	parseTree := aNode.
	labels := labelList.
	complete := completeFlag.
]

{ #category : #accessing }
JSMethod >> sharedCase [
	^sharedCase
]

{ #category : #accessing }
JSMethod >> sharedCase: aNumber [
	sharedCase := aNumber.
]

{ #category : #accessing }
JSMethod >> sharedLabel [
	^sharedLabel
]

{ #category : #accessing }
JSMethod >> sharedLabel: aString [
	sharedLabel := aString
]

{ #category : #accessing }
JSMethod >> statements [

	parseTree isStmtList
		ifFalse: [ self error: 'expected method parse tree to be a TStmtListNode' ].
	((parseTree args = nil) or: [parseTree args isEmpty])
		ifFalse: [ self error: 'expected method parse tree to have no args' ].

	^parseTree statements
]

{ #category : #'primitive compilation' }
JSMethod >> statementsFor: sourceText varName: varName [
	"Return the parse tree for the given expression. The result is the statements list of the method parsed from the given source text."
	"Details: Various variables are declared as locals to avoid Undeclared warnings from the parser."

	| s |
	s := WriteStream on: ''.
	s nextPutAll: 'temp'; cr; cr; tab.
	self printTempsAndVar: varName on: s.
	s nextPutAll: sourceText.
	^ ((Compiler new parse: s contents in: Object notifying: nil)
			asTranslationMethodOfClass: self class) statements

]

{ #category : #inlining }
JSMethod >> statementsListsForInlining [
	"Answer a collection of statement list nodes that are candidates for inlining. Currently, we cannot inline into the argument blocks of and: and or: messages."

	| stmtLists |
	stmtLists := OrderedCollection new: 10.
	parseTree nodesDo: [ :node | 
		node isStmtList ifTrue: [ stmtLists add: node ].
	].
	parseTree nodesDo: [ :node | 
		node isSend ifTrue: [
			((node selector = #and:) or: [node selector = #or:]) ifTrue: [
				"Note: the PP 2.3 compiler produces two arg nodes for these selectors"
				stmtLists remove: node args first ifAbsent: [].
				stmtLists remove: node args last ifAbsent: [].
			].
			((node selector = #ifTrue:) or: [node selector = #ifFalse:]) ifTrue: [
				stmtLists remove: node receiver ifAbsent: [].
			].
			((node selector = #ifTrue:ifFalse:) or: [node selector = #ifFalse:ifTrue:]) ifTrue: [
				stmtLists remove: node receiver ifAbsent: [].
			].
			((node selector = #whileFalse:) or: [node selector = #whileTrue:]) ifTrue: [
				"Allow inlining if it is a [...] whileTrue/whileFalse.
				This is identified by having more than one statement in the 
				receiver block in which case the C code wouldn't work anyways"
				node receiver statements size = 1
					ifTrue:[stmtLists remove: node receiver ifAbsent: []].
			].
			(node selector = #to:do:) ifTrue: [
				stmtLists remove: node receiver ifAbsent: [].
				stmtLists remove: node args first ifAbsent: [].
			].
			(node selector = #to:by:do:) ifTrue: [
				stmtLists remove: node receiver ifAbsent: [].
				stmtLists remove: node args first ifAbsent: [].
				stmtLists remove: node args second ifAbsent: [].
			].
		].
		node isCaseStmt ifTrue: [
			"don't inline cases"
			node cases do: [: case | stmtLists remove: case ifAbsent: [] ].
		].
	].
	^stmtLists
]

{ #category : #accessing }
JSMethod >> static: aBoolean [
	static := aBoolean
]

{ #category : #inlining }
JSMethod >> tryToInlineMethodsIn: aCodeGen [
	"Expand any (complete) inline methods called by this method. Set the complete bit when all inlining has been done. Return true if something was inlined."

	| stmtLists didSomething newStatements inlinedStmts sendsToInline |
	didSomething := false.

	sendsToInline := Dictionary new: 100.
	parseTree nodesDo: [ :n |
		(self inlineableFunctionCall: n in: aCodeGen) ifTrue: [
			sendsToInline at: n put: (self inlineFunctionCall: n in: aCodeGen).
		].
	].
	sendsToInline isEmpty ifFalse: [
		didSomething := true.
		parseTree := parseTree replaceNodesIn: sendsToInline.
	].

	didSomething ifTrue: [
		possibleSideEffectsCache := nil.
		^didSomething
	].

	stmtLists := self statementsListsForInlining.
	stmtLists do: [ :stmtList | 
		newStatements := OrderedCollection new: 100.
		stmtList statements do: [ :stmt |
			inlinedStmts := self inlineCodeOrNilForStatement: stmt in: aCodeGen.
			(inlinedStmts = nil) ifTrue: [
				newStatements addLast: stmt.
			] ifFalse: [
				didSomething := true.
				newStatements addAllLast: inlinedStmts.
			].
		].
		stmtList setStatements: newStatements asArray.
	].

	didSomething ifTrue: [
		possibleSideEffectsCache := nil.
		^didSomething
	].

	complete ifFalse: [
		self checkForCompleteness: stmtLists in: aCodeGen.
		complete ifTrue: [ didSomething := true ].  "marking a method complete is progress"
	].
	^didSomething
]

{ #category : #inlining }
JSMethod >> unusedLabelForInliningInto: targetMethod [

	| usedLabels |
	usedLabels := labels asSet.
	usedLabels addAll: targetMethod labels.
	^self unusedNamePrefixedBy: 'l' avoiding: usedLabels
]

{ #category : #'inlining support' }
JSMethod >> unusedNamePrefixedBy: aString avoiding: usedNames [
	"Choose a unique variable or label name with the given string as a prefix, avoiding the names in the given collection. The selected name is added to usedNames."

	| n newVarName |
	n := 1.
	newVarName := aString, n printString.
	[usedNames includes: newVarName] whileTrue: [
		n := n + 1.
		newVarName := aString, n printString.
	].
	usedNames add: newVarName.
	^ newVarName
]

{ #category : #utilities }
JSMethod >> variablesAssignedTo [
	"Answer a collection of variables assigned to by this method."

	| refs |
	refs := Set new.
	parseTree nodesDo: [ :node |
		node isAssignment ifTrue: [ refs add: node variable name ].
	].
	^ refs
]

{ #category : #'primitive compilation' }
JSMethod >> vmNameString [
	"return the string to use as the vm name in code generated for this method"
	^'interpreterProxy'
]
