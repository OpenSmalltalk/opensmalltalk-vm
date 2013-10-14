Class {
	#name : #TMethod,
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
		'writtenToGlobalVarsCache',
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
		'extraVariableNumber'
	],
	#classVars : [
		'CaseStatements'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'class initialization' }
TMethod class >> initialize [
	"TMethod initialize"	
	CaseStatements := IdentitySet new: 10.
	CaseStatements addAll: #(dispatchOn:in: dispatchOn:in:with: dispatchOn:in:with:with:).
]

{ #category : #utilities }
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

{ #category : #inlining }
TMethod >> argAssignmentsFor: meth args: argList in: aCodeGen [
	"Return a collection of assignment nodes that assign the given argument expressions to the formal parameter variables of the given method."
	"Optimization: If the actual parameters are either constants or local variables in the target method (the receiver), substitute them directly into the body of meth. Note that global variables cannot be subsituted because the inlined method might depend on the exact ordering of side effects to the globals."

	| stmtList substitutionDict |
	stmtList := OrderedCollection new: 100.
	substitutionDict := Dictionary new: 100.
	meth args with: argList do:
		[ :argName :exprNode |
		(self isNode: exprNode substitutableFor: argName inMethod: meth in: aCodeGen)
			ifTrue:
				[substitutionDict at: argName put: exprNode.
				 locals remove: argName]
			ifFalse:
				[stmtList add: (TAssignmentNode new
								setVariable: (TVariableNode new setName: argName)
								expression: exprNode copy)]].
	meth parseTree: (meth parseTree bindVariablesIn: substitutionDict).
	^stmtList
]

{ #category : #'primitive compilation' }
TMethod >> argConversionExprFor: varName stackIndex: stackIndex [ 
	"Return the parse tree for an expression that fetches and converts the 
	primitive argument at the given stack offset."
	| exprList decl stmtList |
	exprList := OrderedCollection new.
	(declarations includesKey: varName) ifTrue:[
		decl := declarations at: varName.
		(decl includes: $*) ifTrue:["array"
			(decl includesSubString: 'char') ifTrue:[ | expr |
				expr := '(interpreterProxy isBytes: (interpreterProxy stackValue: (stackIndex))) ifFalse:[^interpreterProxy primitiveFail].'.
				expr := expr copyReplaceAll: 'interpreterProxy' with: self vmNameString.
				expr := expr copyReplaceAll: 'stackIndex' with: stackIndex printString.
				exprList add: expr.
			].
			exprList add: varName , ' := ', self vmNameString, ' arrayValueOf: (', self vmNameString, ' stackValue: (' , stackIndex printString , '))'.
			exprList add: varName , ' := ' , varName , ' - 1'.
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
TMethod >> args [
	"The arguments of this method."

	^args
]

{ #category : #transformations }
TMethod >> asInlineNode [
	^TInlineNode new method: self
]

{ #category : #accessing }
TMethod >> asmLabel [
	^canAsmLabel
]

{ #category : #accessing }
TMethod >> asmLabel: aBoolean [
	canAsmLabel := aBoolean
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
TMethod >> buildCaseStmt: aSendNode [
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

{ #category : #inlining }
TMethod >> checkForCompleteness: stmtLists in: aCodeGen [
	"Set the complete flag if none of the given statement list nodes contains further candidates for inlining."

	complete := true.
	stmtLists do:
		[:stmtList|
		stmtList statements do:
			[:node|
			[(self inlineableSend: node in: aCodeGen) ifTrue:
				[complete := false.  "more inlining to do"
				^self]]]].

	parseTree
		nodesDo:
			[:node|
			(self inlineableFunctionCall: node in: aCodeGen) ifTrue:
				[complete := false.  "more inlining to do"
				^self]]
		unless:
			[:node|
			node isSend
			and: [node selector == #cCode:inSmalltalk:
				or: [aCodeGen isAssertSelector: node selector]]]
]

{ #category : #'primitive compilation' }
TMethod >> checkSuccessExpr [
	"Return the parse tree for an expression that aborts the primitive if the successFlag is not true."

	| expr |
	expr := 'successFlag ifFalse: [^ nil ]'.
	^ self statementsFor: expr varName: ''

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
TMethod >> compiledMethod [
	^definingClass >> selector
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
			 and: [(node isStructSend: aCodeGen) not]]) ifTrue:
				[(aCodeGen methodNamed: node selector) ifNotNil:
					[:method|
					 method
						computePossibleSideEffectsInto: writtenToVars
						visited: visitedSelectors
						in: aCodeGen]]].
	writtenToGlobalVarsCache := writtenToVars copy
]

{ #category : #'primitive compilation' }
TMethod >> covertToZeroBasedArrayReferences [
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
TMethod >> declarationAt: aVariableName [
	^declarations at: aVariableName ifAbsent: [#sqInt, ' ', aVariableName]
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
	  and: [properties includesKey: #cmacro:]
]

{ #category : #accessing }
TMethod >> definingClass [
	^definingClass
]

{ #category : #accessing }
TMethod >> definingClass: aClass [
	definingClass := aClass.
]

{ #category : #'C code generation' }
TMethod >> determineTypeFor: aNode in: aCodeGen [
	aNode isSend ifTrue:
		[aNode selector == #addressOf: ifTrue:
			[^(self determineTypeFor: aNode args first in: aCodeGen)
				ifNil: [#sqInt]
				ifNotNil: [:type| type, (type last isLetter ifTrue: [' *'] ifFalse: ['*'])]].
		(aNode selector == #at:
		 and: [aNode receiver isVariable]) ifTrue:
			[(aCodeGen typeOfVariable: aNode receiver name) ifNotNil:
				[:type|
				^type last = $*
					ifTrue: [aCodeGen
								extractTypeFor: aNode receiver name
								fromDeclaration: type allButLast]
					ifFalse: [type]]].
		^(aCodeGen methodNamed: aNode selector)
			ifNil: [#sqInt]
			ifNotNil: [:method| method returnType]].
	aNode isAssignment ifTrue:
		[^self determineTypeFor: aNode expression in: aCodeGen].
	self error: 'don''t know how to extract return type from this kind of node'
]

{ #category : #transformations }
TMethod >> elideAnyFinalReturn [
	"For super expansions we need to eliminate any final return to prevent premature exit.
	 Anything meaningful in the returned expression must be retained."

	| stmtList lastStmt |
	stmtList := parseTree statements asOrderedCollection.
	(lastStmt := stmtList last) isReturn ifTrue:
		[stmtList at: stmtList size put: lastStmt expression.
		parseTree setStatements: stmtList]
]

{ #category : #'C code generation' }
TMethod >> emitCCodeOn: aStream generator: aCodeGen [
	"Emit C code for this method onto the given stream.
	 All calls to inlined methods should already have been expanded."

	aCodeGen currentMethod: self.
	self emitCCommentOn: aStream.	"place method comment before function"
	aStream cr. 
	self emitCFunctionPrototype: aStream generator: aCodeGen newlineBeforeName: true.
	aStream cr; nextPut: ${.
	self emitCLocalsOn: aStream generator: aCodeGen.
	aCodeGen
		pushScope: declarations
		while: [parseTree emitCCodeOn: aStream level: 1 generator: aCodeGen].
	aStream nextPut: $}; cr
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
			aStream nextPutAll: (pragma argumentAt: 1).
			^self]].
	self emitCFunctionPrototype: aStream generator: aCodeGen newlineBeforeName: false
]

{ #category : #'C code generation' }
TMethod >> emitCFunctionPrototype: aStream generator: aCodeGen newlineBeforeName: newlineBeforeName [ "<Boolean>"
	"Emit a C function header for this method onto the given stream."

	export 
		ifTrue:[aStream nextPutAll: 'EXPORT('; nextPutAll: returnType; nextPut: $)]
		ifFalse:[self isStatic ifTrue:[aStream nextPutAll: 'static '].
				aStream nextPutAll: returnType].
	newlineBeforeName ifTrue: [aStream cr] ifFalse: [aStream space].
	(returnType last = $)
	and: [returnType includesSubString: (aCodeGen cFunctionNameFor: selector)]) ifTrue:
		["Hack fix for e.g. <returnTypeC: 'void (*setInterruptCheckChain(void (*aFunction)(void)))()'>"
		 ^self].
	aStream
		nextPutAll: (aCodeGen cFunctionNameFor: selector);
		nextPut: $(.
	args isEmpty
		ifTrue: [aStream nextPutAll: #void]
		ifFalse:
			[args
				do: [:arg| aStream nextPutAll: (self declarationAt: arg)]
				separatedBy: [ aStream nextPutAll: ', ' ]].
	aStream nextPut: $)
]

{ #category : #'C code generation' }
TMethod >> emitCLocalsOn: aStream generator: aCodeGen [
	"Emit a C function header for this method onto the given stream."

	| volatileVariables |
	volatileVariables := properties includesKey: #volatile.
	self refersToGlobalStruct ifTrue:
		[aStream
			next: 3 put: Character space; "there's already an opening ${ on this line; see sender"
			nextPutAll: (volatileVariables
						ifTrue: ['DECL_MAYBE_VOLATILE_SQ_GLOBAL_STRUCT']
						ifFalse: ['DECL_MAYBE_SQ_GLOBAL_STRUCT'])].
	aStream cr.
	locals isEmpty ifFalse:
		[(aCodeGen sortStrings: locals) do:
			[ :var |
			aStream next: 4 put: Character space.
			volatileVariables ifTrue:
				[aStream nextPutAll: #volatile; space].
			aStream
				nextPutAll: (self declarationAt: var);
				nextPut: $;;
				cr].
		 aStream cr]
]

{ #category : #'C code generation' }
TMethod >> emitInlineOn: aStream level: level generator: aCodeGen [
	"Emit C code for this method onto the given stream. All calls to inlined methods should already have been expanded."
	self removeUnusedTemps.
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
				nextPutAll: (self declarationAt: var);
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
TMethod >> exitVar: exitVar label: exitLabel [
	"Replace each return statement in this method with an assignment to the
	 exit variable followed by either a return or a goto to the given label.
	 Answer if a goto was generated."
	"Optimization: If exitVar is nil, the return value of the inlined method is not being used, so don't add the assignment statement."

	| labelUsed map eliminateReturnSelfs |
	labelUsed := false.
	map := Dictionary new.
	"Conceivably one might ^self from a struct class and mean it.  In most cases though
	 ^self means `get me outta here, fast'.  So unless this method is from a VMStruct class,
	 elide any ^self's"
	eliminateReturnSelfs := ((definingClass inheritsFrom: VMClass) and: [definingClass isStructClass]) not
							  and: [returnType = #void or: [returnType = #sqInt]].
	parseTree nodesDo:
		[:node | | replacement |
		node isReturn ifTrue:
			[replacement := (node expression isVariable "Eliminate ^self's"
							   and: [node expression name = 'self'
							   and: [eliminateReturnSelfs]])
								ifTrue: [nil]
								ifFalse:
									[exitVar
										ifNil: [node expression]
										ifNotNil: [TAssignmentNode new
													setVariable: (TVariableNode new setName: exitVar)
													expression: node expression]].
			 node ~~ parseTree statements last ifTrue:
				[replacement := replacement
									ifNil: [TGoToNode new setLabel: exitLabel; yourself]
									ifNotNil:
										[TStmtListNode new
											setArguments: #()
											statements: {replacement.
														  TGoToNode new setLabel: exitLabel; yourself};
											yourself].
				 labelUsed := true].
			map
				at: node
				put: (replacement ifNil:
						[TLabeledCommentNode new setComment: 'return ', node expression printString])]].
	parseTree replaceNodesIn: map.
	"Now flatten any new statement lists..."
	parseTree nodesDo:
		[:node| | list |
		(node isStmtList and: [node statements last isStmtList]) ifTrue:
			[list := node statements last statements.
			 node statements removeLast; addAllLast: list]].
	^labelUsed
]

{ #category : #accessing }
TMethod >> export [

	^ export

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
	"Scan the top-level statements for an inlining directive of the form:

		self inline: <boolean>

	 and remove the directive from the method body. Return the argument of the directive or #dontCare if there is no inlining directive."

	sharedCase ifNotNil: [^false]. "don't auto-inline shared code; it gets handled specially"
	^self
		extractDirective: #inline:
		valueBlock: [:sendNode| sendNode args first value = true]
		default: #dontCare
]

{ #category : #transformations }
TMethod >> extractLabelDirective [
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
TMethod >> extractSharedCase [
	"Scan the top-level statements for an shared case directive of the form:

		self sharedCodeNamed: <sharedLabel> inCase: <sharedCase>.

	and remove the directive from the method body."

	self extractDirective: #sharedCodeNamed:inCase:
		valueBlock: [:sendNode|
			args isEmpty ifFalse:
				[self error: 'Cannot share code sections in methods with arguments'].
			sharedLabel := sendNode args first value.
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
		default: (export or: [(properties includesKey: #api) or: [properties includesKey: #api:]]) not
]

{ #category : #'primitive compilation' }
TMethod >> fetchRcvrExpr [
	"Return the parse tree for an expression that fetches the receiver from the stack."

	| expr |
	expr := 'rcvr := ', self vmNameString, ' stackValue: (', args size printString, ')'.
	^ self statementsFor: expr varName: ''

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
	"Answer true if the receiver uses inlined C or complex C declarations,
	 which are not currently renamed properly by the the inliner."

	declarations keysAndValuesDo:
		[:name :value|
		((value endsWith: name)
		 or: [value == #implicit]) ifFalse: 
			[^true]].

	parseTree nodesDo:
		[:node|
		(node isSend
		 and: [node isNonNullCCode]) ifTrue:
			[^true]].
	^false
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
TMethod >> inlineCodeOrNilForStatement: aNode in: aCodeGen [
	"If the given statement node can be inlined, answer the statements that replace it. Otherwise, answer nil."

	| stmts |
	aNode isReturn ifTrue:
		[(self inlineableSend: aNode expression in: aCodeGen) ifTrue:
			[stmts := self inlineSend: aNode expression
				directReturn: true exitVar: nil in: aCodeGen.
			^stmts]].
	(aNode isAssignment and: [aNode expression isSend])  ifTrue:
		[(self inlineableSend: aNode expression in: aCodeGen) ifTrue:
			[^self inlineSend: aNode expression
				directReturn: false exitVar: aNode variable name in: aCodeGen]].
	aNode isSend ifTrue:
		[(self inlineableSend: aNode in: aCodeGen) ifTrue:
			[^self inlineSend: aNode
				directReturn: false exitVar: nil in: aCodeGen]].
	^nil
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
	doNotRename := Set withAll: args.
	argsForInlining := aSendNode argumentsForInliningCodeGenerator: aCodeGen.
	meth args with: argsForInlining do:
		[ :argName :exprNode |
		exprNode isLeaf ifTrue:
			[doNotRename add: argName]].
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
	^meth statements first expression
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

	| sel meth exitLabel inlineStmts label exitType |
	sel := aSendNode selector.
	meth := aCodeGen methodNamed: sel.
	"convenient for debugging..."
	self maybeBreakFor: aSendNode in: aCodeGen.
	meth args size = aSendNode args size ifFalse:
		[^nil].
	meth args with: aSendNode args do:
		[:formal :actual|
		(actual isVariable
		and: [(aCodeGen
				variableOfType: (self typeFor: formal using: aCodeGen)
				acceptsValueOfType: (self typeFor: actual name in: aCodeGen)) not]) ifTrue:
			[aCodeGen logger
				nextPutAll:
					'type mismatch for formal ', formal, ' and actual ', actual name,
					' when inlining ', sel, ' in ', selector, '. Use a cast.';
				cr; flush]]. 
	meth := meth copy.

	"Propagate the return type of an inlined method"
	(directReturn or:[exitVar notNil]) ifTrue:[
		exitType := directReturn 
			ifTrue:[returnType] 
			ifFalse:[(self typeFor: exitVar in: aCodeGen) ifNil:[#sqInt]].
		(exitType = #void or:[exitType = meth returnType]) 
			ifFalse:[meth propagateReturnIn: aCodeGen]].

	meth renameVarsForInliningInto: self except: #() in: aCodeGen.
	meth renameLabelsForInliningInto: self.
	self addVarsDeclarationsAndLabelsOf: meth except: #().
	meth hasReturn ifTrue:[
		directReturn ifFalse:[
			exitLabel := self unusedLabelForInliningInto: self.
			(meth exitVar: exitVar label: exitLabel) "is label used?"
				ifTrue: [ labels add: exitLabel ]
				ifFalse: [ exitLabel := nil ]]].
	(inlineStmts := OrderedCollection new: 100)
		add: (label := TLabeledCommentNode new setComment: 'begin ', sel);
		addAll: (self argAssignmentsFor: meth args: aSendNode args in: aCodeGen);
		addAll: meth statements.  "method body"
	"Vile hacks to prevent too many labels.  If the C compiler inlines functions it can duplicate
	 labels and cause compilation to fail.  The second statement prevents us creating labels in
	 anything other than the interpreter.  If we add labels to small functions that may be inlined
	 by the C compiler then the label can be duplicated by the C compiler and cause the assembler
	 to fail.  eem 9/20/2008 12:29"
	(aCodeGen wantsLabels
	 and: [meth asmLabel
	 and: [meth mustAsmLabel or: [meth hasMoreSendsThan: 20]]]) ifTrue:
		[label asmLabel: sel].
	(directReturn
	 and: [meth endsWithReturn not]) ifTrue:
		[inlineStmts add:
			(TReturnNode new setExpression: (TVariableNode new setName: 'nil'))].
	exitLabel ~= nil ifTrue:
		[inlineStmts add:
			(TLabeledCommentNode new setLabel:
				exitLabel comment: 'end ', meth selector)].
	^inlineStmts
]

{ #category : #inlining }
TMethod >> inlineableFunctionCall: aNode in: aCodeGen [
	"Answer true if the given send node is a call to a 'functional' method--a method whose body is a single return statement of some expression and whose actual parameters can all be directly substituted."

	| m |
	self maybeBreakFor: aNode in: aCodeGen.
	^aNode isSend
	and: [(m := aCodeGen methodNamed: aNode selector) notNil  "nil if builtin or external function"
	and: [m isFunctional
	and: [(aCodeGen mayInline: m selector)
	and: [aNode args allSatisfy: [ :a | self isSubstitutableNode: a intoMethod: m in: aCodeGen]]]]]
]

{ #category : #inlining }
TMethod >> inlineableSend: aNode in: aCodeGen [
	"Answer true if the given send node is a call to a method that can be inlined."

	| m |
	self maybeBreakFor: aNode in: aCodeGen.
	aNode isSend ifFalse: [ ^false ].
	m := aCodeGen methodNamed: aNode selector.  "nil if builtin or external function"
	^(m ~= nil) and: [m isComplete and: [aCodeGen mayInline: m selector]]
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
TMethod >> isFunctional [
	"Answer true if the receiver is a functional method. That is, if it
	 consists of a single return statement of an expression that contains
	 no other returns.

	 Answer false for methods with return types other than #sqInt to work
	 around bugs in the inliner."

	(parseTree statements size = 1 and:
	 [parseTree statements last isReturn]) ifFalse: [ ^false ].
	parseTree statements last expression nodesDo: [ :n | n isReturn ifTrue: [ ^false ]].
	returnType = #sqInt ifFalse:[^false].
	^true
]

{ #category : #inlining }
TMethod >> isNode: aNode substitutableFor: argName inMethod: targetMeth in: aCodeGen [
	"Answer true if the given parameter node is either a constant, a local variable, or a formal parameter of the receiver. Such parameter nodes may be substituted directly into the body of the method during inlining. Note that global variables cannot be subsituted into methods with possible side effects (i.e., methods that may assign to global variables) because the inlined method might depend on having the value of the global variable captured when it is passed in as an argument."

	| var madeNonTrivialCall |
	aNode isConstant ifTrue: [^true].

	aNode isVariable ifTrue:
		[var := aNode name.
		((locals includes: var) or: [args includes: var]) ifTrue: [^true].
		(#(self true false nil) includes: var) ifTrue: [^true].
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
		(targetMeth maySubstituteGlobal: var in: aCodeGen) ifTrue: [^true]].

	"For now allow literal blocks to be substituted.  They better be accessed only
	 with value[:value:*] messages though!"
	aNode isStmtList ifTrue: [^true].

	"scan expression tree; must contain only constants, builtin ops, and inlineable vars"
	aNode nodesDo: [ :node |
		node isSend ifTrue: [
			node isBuiltinOperator ifFalse: [^false].
		].
		node isVariable ifTrue: [
			var := node name.
			((locals includes: var) or:
			 [(args includes: var) or:
			 [(#(self true false nil) includes: var) or:
			 [targetMeth maySubstituteGlobal: var in: aCodeGen]]]) ifFalse: [^false].
		].
		(node isConstant or: [node isVariable or: [node isSend]]) ifFalse: [^false].
	].

	^ true
]

{ #category : #testing }
TMethod >> isRealMethod [
	^(self definedAsMacro or: [self isStructAccessor]) not
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
TMethod >> labels [

	^labels
]

{ #category : #accessing }
TMethod >> labels: aCollection [

	labels := aCollection isSequenceable
				ifTrue: [aCollection asOrderedCollection]
				ifFalse: [aCollection asSortedCollection asOrderedCollection]
]

{ #category : #accessing }
TMethod >> locals [
	"The local variables of this method."

	^locals
]

{ #category : #'inlining support' }
TMethod >> maySubstituteGlobal: globalVar in: aCodeGen [
	"We can substitute globalVar into this method provided globalVar is only read, not written."

	writtenToGlobalVarsCache = nil ifTrue:
		[self computePossibleSideEffectsInto: (Set new: 50) visited: (Set new: 50) in: aCodeGen].
	^(writtenToGlobalVarsCache includes: globalVar) not
]

{ #category : #inlining }
TMethod >> maybeBreakFor: aNode in: aCodeGen [
	"convenient for debugging..."
	(aNode isSend
	and: [(aCodeGen breakSrcInlineSelector notNil or: [aCodeGen breakDestInlineSelector notNil])
	and: [(aCodeGen breakSrcInlineSelector ifNil: [true] ifNotNil: [:srcSel| srcSel = aNode selector])
	and: [aCodeGen breakDestInlineSelector ifNil: [true] ifNotNil: [:dstSel| dstSel = selector]]]]) ifTrue:
		[self halt]
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

{ #category : #accessing }
TMethod >> mustAsmLabel [
	^mustAsmLabel == true
]

{ #category : #accessing }
TMethod >> mustAsmLabel: aBoolean [
	mustAsmLabel := aBoolean
]

{ #category : #initialization }
TMethod >> newCascadeTempFor: aTParseNode [
	| varNode |
	varNode := TVariableNode new setName: (self extraVariableName: 'cascade').
	aTParseNode isLeaf ifFalse:
		[declarations
			at: varNode name
			put: [:tm :cg| tm halt; determineTypeFor: aTParseNode in: cg]].
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

{ #category : #private }
TMethod >> oopVariable: aString [

	(locals includes: aString) ifFalse:
		[locals add: aString.
		self declarationAt: aString put: 'sqInt ', aString].
	^TVariableNode new setName: aString
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
	 Note: Only replaces top-level sends of dispatchOn:in: et al and caseOf:[otherwise:].
	 These must be top-level statements; they cannot appear in expressions.
	 As a hack also update the types of variables introduced to implement cascades correctly.
	 This has to be done at the same time as this is done, so why not piggy back here?"
	| replacements |
	extraVariableNumber ifNotNil:
		[declarations keysAndValuesDo:
			[:varName :decl|
			decl isBlock ifTrue:
				[self assert: ((varName beginsWith: 'cascade') and: [varName last isDigit]).
				 locals add: varName.
				 self declarationAt: varName
					put: (decl value: self value: aCodeGen), ' ', varName]]].
	replacements := IdentityDictionary new.
	aCodeGen
		pushScope: declarations
		while:
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
										and: [(subNode isStructSend: aCodeGen) not]]])
									ifTrue: [locals add: node args last name]
									ifFalse:
										[node arguments: node args allButLast]]]
						ifFalse:
							[(CaseStatements includes: node selector) ifTrue:
								[replacements at: node put: (self buildCaseStmt: node)].
							 (#(caseOf: #caseOf:otherwise:) includes: node selector) ifTrue:
								[replacements at: node put: (self buildSwitchStmt: node parent: parent)]]].
				 ((node isAssignment or: [node isReturn])
				  and: [node expression isSwitch]) ifTrue:
					[replacements at: node put: (self transformSwitchExpression: node)]]].
	replacements isEmpty ifFalse:
		[parseTree := parseTree replaceNodesIn: replacements]
]

{ #category : #'primitive compilation' }
TMethod >> preparePrimitiveName [
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
	aStream nextPutAll: '| rcvr stackPointer successFlag ' , varName , ' |';
	 cr
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
		node isReturn ifTrue:[
			map at: node expression put: (TSendNode new
				setSelector: #cCoerce:to:
				receiver: (TVariableNode new setName: 'self')
				arguments: {node expression.
							TConstantNode new setValue: coercionType})]].
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

{ #category : #transformations }
TMethod >> recordDeclarations [
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
				[locals remove: pragma arguments last]].
		^self].
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
TMethod >> removeFinalSelfReturn [
	"The Smalltalk parser automatically adds the statement '^self' to the end of methods
	 without explicit returns.  This method removes such statements, since in most VMMaker
	 classes (except struct classes) the generated code has no notion of 'self' anyway.
	 If the statement is removed and no return type has yet been specified asnd the class
	 specifies a default return type (e.g. #void) for methods that don't return, then set the
	 return type accordingly."

	| lastStmt |
	((lastStmt := parseTree statements last) isReturn
	 and: [lastStmt expression isVariable
	 and: ['self' = lastStmt expression name]]) ifTrue:
		[| tokens |
		tokens := Scanner new scanTokens: (definingClass sourceCodeAt: selector ifAbsent: ['']).
		(tokens size < 2
		 or: [(tokens last: 2) ~= #(#'^' 'self')]) ifTrue:
			[parseTree setStatements: parseTree statements allButLast.
			 returnType = #sqInt ifTrue:
				[([definingClass implicitReturnTypeFor: selector]
					on: MessageNotUnderstood
					do: [:ex| nil]) ifNotNil:
						[:defaultReturnType|
						returnType := defaultReturnType]]]]
]

{ #category : #utilities }
TMethod >> removeUnusedTemps [
	"Remove all of the unused temps in this method. Answer a bag (why the hell a bag???) with the references."
	"After inlining some variable references are now obsolete, we could fix them there but the 
	code seems a bit complicated, the other choice to to rebuild the locals before extruding. This is done here"
	| refs |
	refs := Bag new.
	"find all the variable names referenced in this method"
	parseTree nodesDo: [ :node |
		node isVariable ifTrue: [ refs add: node name asString ].
		node isStmtList ifTrue: [refs addAll: node args]].
	"add all the non-arg declarations (might be variables used only in cCode sections)"
	refs addAll: (declarations keys reject: [:e | self args includes: e]).
	"reset the locals to be only those still referred to"
	locals := locals select: [:e | refs includes: e].
	^refs

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

{ #category : #'inlining support' }
TMethod >> renameVariablesUsing: aDictionary [
	"Rename all variables according to old->new mappings of the given dictionary."

	| newDecls |
	"map args and locals"
	args := args collect: [ :arg | aDictionary at: arg ifAbsent: [ arg ]].
	locals := locals collect: [ :v | aDictionary at: v ifAbsent: [ v ]].

	"map declarations"
	newDecls := declarations species new.
	declarations keysAndValuesDo:
		[ :oldName :decl|
		(aDictionary at: oldName ifAbsent: nil)
			ifNotNil: [:newName|
					newDecls
						at: newName
						put: ((decl endsWith: oldName)
								ifTrue: [(decl allButLast: oldName size), newName]
								ifFalse:
									[Transcript cr; show: 'suspicious renaming ', oldName, ' -> ', newName, ' ', decl, ' in ', selector.
									 decl])]
			ifNil: [ newDecls at: oldName put: decl ]].
	self newDeclarations: newDecls.

	"map variable names in parse tree"
	parseTree nodesDo: [ :node |
		(node isVariable
		and: [aDictionary includesKey: node name]) ifTrue:
			[node setName: (aDictionary at: node name)].
		(node isStmtList and: [node args size > 0]) ifTrue:
			[node setArguments: (node args collect: [ :arg | aDictionary at: arg ifAbsent: [ arg ]])]]
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
	"Set the type of the values returned by this method. This string will be used in the C declaration of this function."

	returnType := aString
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
	returnType := #sqInt. 	 "assume return type is long for now"
	args := argList asOrderedCollection collect: [:arg | arg key].
	locals := (localList collect: [:arg | arg key]) asSet.
	declarations := Dictionary new.
	self addTypeForSelf.
	primitive := aNumber.
	properties := methodProperties.
	comment := aComment.
	parseTree := aBlockNode. "hack; allows nodes to find their parent, etc"
	parseTree := aBlockNode asTranslatorNodeIn: self.
	labels := OrderedCollection new.
	complete := false.  "set to true when all possible inlining has been done"
	export := self extractExportDirective.
	static := self extractStaticDirective.
	canAsmLabel := self extractLabelDirective.
	self extractSharedCase.
	self removeFinalSelfReturn.	"must preceed recordDeclarations because this may set returnType"
	self recordDeclarations.
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
	(properties includesKey: aPragma keyword) ifFalse:
		[^true].
	((aPragma keyword beginsWith: #var:)
	  and: [properties pragmas noneSatisfy:
			[:p|
			(p keyword beginsWith: #var:)
			and: [(p argumentAt: 1) = (aPragma argumentAt: 1)]]]) ifTrue:
		[^true].
	^false
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

	| s |
	s := WriteStream on: ''.
	s nextPutAll: 'temp'; cr; cr; tab.
	self printTempsAndVar: varName on: s.
	s nextPutAll: sourceText.
	^ ((Compiler new parse: s contents in: Object notifying: nil)
			asTranslationMethodOfClass: self class) statements

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
			 node selector = #cppIf:ifTrue:ifFalse: ifTrue:
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
			superTMethod := superMethod methodNode asTranslationMethodOfClass: self class.
			((argumentNodes allSatisfy: [:parseNode| parseNode isVariableNode])
			and: [(argumentNodes asOrderedCollection collect: [:parseNode| parseNode key]) = superTMethod args]) ifFalse:
				[self error: definingClass name, '>>',selector, ' args ~= ',
							superTMethod definingClass name, '>>', aSelector,
							(String with: $. with: Character cr),
							'For super expansions to be translated correctly each argument must be a variable with the same name as the corresponding argument in the super method.'].
			self mergePropertiesOfSuperMethod: superTMethod.
			(commonVars := superTMethod locals intersection: self locals) notEmpty ifTrue:
				[varMap := Dictionary new.
				 commonVars do:
					[:k| varMap at: k put: (superTMethod unusedNamePrefixedBy: k avoiding: self allLocals)].
				 superTMethod renameVariablesUsing: varMap].
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

{ #category : #transformations }
TMethod >> transformToStructClassMethodFor: aCCodeGenerator [
	"Transform this method so that it can be used on an instance of a struct class (VMStructType subclass).
	 Convert inst var refs into field dereferences of self.  Add selfSelector as the first argument with the
	 right struct type. As a complete hack to avoid breaking the inlinert don't use 'self' as the name for self
	 as this causes surious type redefinitions ``somewhere'' in the inliner."
	| replacements selfNode typeForSelf |
	self isStructAccessor ifTrue:
		[^returnType := definingClass returnTypeForAccessor: selector].
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
		[parseTree := parseTree replaceNodesIn: replacements].
	typeForSelf := self typeForSelf.
	self assert: (typeForSelf notNil and: [typeForSelf ~~ #implicit]).
	self declarationAt: (args addFirst: selfNode name)
		put: (declarations removeKey: 'self'), '_in_', (aCCodeGenerator cFunctionNameFor: selector)
]

{ #category : #inlining }
TMethod >> tryToInlineMethodsIn: aCodeGen [
	"Expand any (complete) inline methods called by this method. Set the complete bit when all inlining has been done. Return true if something was inlined."

	| stmtLists didSomething newStatements sendsToInline |
	self definedAsMacro ifTrue:
		[complete := true.
		 ^false].
	didSomething := false.
	sendsToInline := Dictionary new: 100.
	parseTree
		nodesDo:
			[:node|
			(self inlineableFunctionCall: node in: aCodeGen) ifTrue:
				[sendsToInline at: node put: (self inlineFunctionCall: node in: aCodeGen)]]
		unless: "Don't inline the arguments to asserts to keep the asserts readable"
			[:node|
			node isSend
			and: [node selector == #cCode:inSmalltalk:
				or: [aCodeGen isAssertSelector: node selector]]].

	sendsToInline isEmpty ifFalse:
		[didSomething := true.
		parseTree := parseTree replaceNodesIn: sendsToInline].

	didSomething ifTrue:
		[writtenToGlobalVarsCache := nil.
		^didSomething].

	stmtLists := self statementsListsForInliningIn: aCodeGen.
	stmtLists do:
		[:stmtList|
		newStatements := OrderedCollection new: 100.
		stmtList statements do:
			[:stmt|
			(self inlineCodeOrNilForStatement: stmt in: aCodeGen)
				ifNil: [newStatements addLast: stmt]
				ifNotNil: [:inlinedStmts|
					didSomething := true.
					newStatements addAllLast: inlinedStmts]].
		stmtList setStatements: newStatements asArray].

	didSomething ifTrue:
		[writtenToGlobalVarsCache := nil.
		^didSomething].

	complete ifFalse:
		[self checkForCompleteness: stmtLists in: aCodeGen.
		 complete ifTrue: [ didSomething := true ]].  "marking a method complete is progress"
	^didSomething
]

{ #category : #utilities }
TMethod >> typeFor: aVariable in: aCodeGen [
	"Answer the type for aVariable, deferring to aCodeGen (which defers to the vmClass)
	 if no type is found and the variable is global (not an arg or a local).  Expect the
	 cCodeGen to answer nil for variables without types. nil for typelessness is required
	 by the type propagation logic in inlineSend:directReturn:exitVar:in:."
	^(declarations
			at: aVariable asString
			ifAbsent: [((locals includes: aVariable) or: [args includes: aVariable]) ifFalse:
						[aCodeGen typeOfVariable: aVariable]]) ifNotNil:
		[:decl|
		aCodeGen extractTypeFor: aVariable fromDeclaration: decl]
]

{ #category : #utilities }
TMethod >> typeFor: aVariable using: aCCodeGen [
	"Answer the type for aVariable.  Answer nil for variables without types.  nil for
	 typelessness is required by the type propagation logic in inlineSend:directReturn:exitVar:in:."
	^aCCodeGen extractTypeFor: aVariable fromDeclaration: (declarations at: aVariable asString ifAbsent: [^nil])
]

{ #category : #utilities }
TMethod >> typeForSelf [
	self assert: definingClass notNil.
	^[definingClass typeForSelf]
		on: MessageNotUnderstood
		do: [:ex| nil]
]

{ #category : #inlining }
TMethod >> unusedLabelForInliningInto: targetMethod [

	| usedLabels |
	usedLabels := labels asSet.
	usedLabels addAll: targetMethod labels.
	^self unusedNamePrefixedBy: 'l' avoiding: usedLabels
]

{ #category : #'inlining support' }
TMethod >> unusedNamePrefixedBy: aString avoiding: usedNames [
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
