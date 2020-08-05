"
Variation of TMethod node of the Smalltalk C Code Generator, used in conjunction with SmartSyntaxPluginCodeGenerator and SmartSyntaxInterpreterPlugin to generate named primitives from methods containing type coercion specifications such as
	primitive: functionName parameters: #(Boolean Oop String WordsArray WordsOrBytes)
	primitive: functionName parameters: #(SmallInteger LargeNegativeInteger LargePositiveInteger Integer Unsigned) receiver: #Oop
"
Class {
	#name : #SmartSyntaxPluginTMethod,
	#superclass : #TMethod,
	#instVars : [
		'isPrimitive',
		'fullSelector',
		'fullArgs',
		'parmSpecs',
		'rcvrSpec'
	],
	#classVars : [
		'Them'
	],
	#category : #'VMMaker-SmartSyntaxPlugins'
}

{ #category : #accessing }
SmartSyntaxPluginTMethod >> args: anInteger [

	^args := anInteger
]

{ #category : #private }
SmartSyntaxPluginTMethod >> assign: variable expression: expression [

	^TAssignmentNode new
		setVariable: variable
		expression: expression
]

{ #category : #'C code generation' }
SmartSyntaxPluginTMethod >> emitCLocalsOn: aStream generator: aCodeGen [
	"Emit a C function header for this method onto the given stream."

	aStream cr.
	locals isEmpty ifFalse:
		[(aCodeGen sortStrings: locals) do:
			[ :var |
		aStream 
			tab; 
			nextPutAll: (self declarationAt: var);
			nextPut: $;; 
			cr].
		 aStream cr]
]

{ #category : #'specifying primitives' }
SmartSyntaxPluginTMethod >> extractPrimitiveDirectives [
	"Save selector in fullSelector and args in fullArgs.  Scan top-level statements for a directive of the form:

		self	
			primitive: 	<string>
or
		self
			primitive:	<string>
			parameters: <list of class names>
or
		self
			primitive:	<string>
			parameters: <list of class names>
			receiver: <class name>

or an assignment of that expression to a local, and manipulate the state and parse tree accordingly."

	parseTree setStatements: (Array streamContents:
		[:sStream |
			parseTree statements do:
				[:stmt |
				 (self primitiveDirectiveWasHandled: stmt on: sStream)
					ifFalse: [sStream nextPut: stmt]]]).
	isPrimitive 
		ifTrue:
			[export := true.
			 parseTree 
				setStatements: self namedPrimitiveProlog, 
								parseTree statements.
			 self fixUpReturns.
			 self replaceSizeMessages.
			 ^true]
		ifFalse: [self removeFinalSelfReturnIn: nil].
	^false
]

{ #category : #transforming }
SmartSyntaxPluginTMethod >> fixUpReturnOneStmt: stmt on: sStream [
	| expr exprRetStmts "p t" |
	stmt isReturn ifFalse: [^sStream nextPut: stmt].
	expr := stmt expression.
	(expr isSend
	 and: [self resultSendAlwaysFails: expr]) ifTrue:
		["failure returns"
		 sStream nextPut: expr; nextPut: self nullReturnExpr.
		 ^nil].
	(expr isVariable and: ['nil' = expr name]) ifTrue:
		["^ nil -- this is never right unless automatically generated"
		 sStream nextPut: stmt.
		 ^nil].
	(expr isVariable and: ['self' = expr name]) ifTrue:
		["^ self"
		 fullArgs isEmpty ifFalse:
			[sStream nextPut: (self statementGuardedWithSuccess: (self popExpr: fullArgs size))].
		 sStream nextPut: self nullReturnExpr.
		 ^nil].
	(expr isVariable or: [expr isConstant]) ifTrue:
		["^ variable or ^ constant without guardchecking"
		sStream
			nextPut: (sStream isEmpty "No statements to cause failure, therefore no need for failure guard."
						ifTrue:
							[self pop: fullArgs size + 1 thenReturnExpr: expr]
						ifFalse:
							[self statementGuardedWithSuccess:
								(self pop: fullArgs size + 1 thenReturnExpr: expr)]);
			nextPut: self nullReturnExpr.
		 ^nil].
	"^ expr with necessary guard checking"
	"p := sStream position."
	exprRetStmts := Array streamContents:
		[:ersStream|
		 (self resultExpressionCanFail: expr)
			ifTrue:
				["t := 1."
				ersStream
					nextPut: (self assign: (self oopVariable: '_return_value') expression: expr);
					nextPut: (self statementGuardedWithSuccess: (self pop: fullArgs size + 1
																		thenReturnExpr: (self oopVariable: '_return_value')))]
			ifFalse:
				["t := 2."
				 ersStream nextPut: (self pop: fullArgs size + 1 thenReturnExpr: expr)]].
		sStream isEmpty "No statements to cause failure, therefore no need for an initial failure guard."
			ifTrue: [sStream nextPutAll: exprRetStmts]
			ifFalse:
				["t := t + 2."
				 sStream nextPut: (self statementGuardedWithSuccess: exprRetStmts)].
	sStream nextPut: self nullReturnExpr.
	"Them := Dictionary new"
	"(Them at: t ifAbsentPut: [Dictionary new])
		at: self selector
		put: (sStream originalContents copyFrom: p + 1 to: sStream position)"
]

{ #category : #transforming }
SmartSyntaxPluginTMethod >> fixUpReturns [
	"Replace each return statement in this method with (a) the given postlog, (b) code to pop the receiver and the given number of arguments, and (c) code to push the integer result and return."

	parseTree nodesDo: [:node |
		node isStmtList ifTrue: [
			node setStatements: (Array streamContents:
				[:sStream |
				 node statements do: 
					[:stmt | self fixUpReturnOneStmt: stmt on: sStream]])]]
]

{ #category : #initialization }
SmartSyntaxPluginTMethod >> fromContext: aContext primitive: aString parameters: aClassList receiver: aClass [

	fullArgs := args := aContext tempNames
				copyFrom: 1
				to: aContext method numArgs.
	self 
		primitive: aString
		parameters: aClassList
		receiver: aClass
]

{ #category : #'specifying primitives' }
SmartSyntaxPluginTMethod >> handlePrimitiveDirective: aStmt on: sStream [

	isPrimitive := true.
	fullArgs := args.
	locals addAll: args.
	args := OrderedCollection new.
	fullArgs with: parmSpecs do:
		[:argName :spec |
		self declarationAt: argName
			put: (spec ccgDeclareCForVar: argName)].
	aStmt isAssignment ifTrue:
		[self declarationAt: aStmt variable name
			put: (rcvrSpec ccgDeclareCForVar: aStmt variable name).
		 sStream nextPutAll: (self
			statementsFor:
				(rcvrSpec
					ccg:	SmartSyntaxPluginCodeGenerator new
					prolog:  [:expr | aStmt variable name, ' := ', expr]
					expr: 	aStmt variable name
					index: 	fullArgs size)
			varName: '')].

	"only add the failure guard if there are args or it is an assignment"
	(fullArgs isEmpty not or: [aStmt isAssignment]) ifTrue:
		[sStream nextPutAll: self checkSuccessExpr].
	^true.

]

{ #category : #'specifying primitives' }
SmartSyntaxPluginTMethod >> isPrimitiveDirectiveSend: stmt [
	
	stmt isSend ifTrue:
		[stmt selector = #primitive: ifTrue:
			[^self primitive: 	stmt args first value
				   parameters:	(Array new: args size withAll: #Oop)
				   receiver:		#Oop].
		 stmt selector = #primitive:parameters: ifTrue:
			[^self primitive: 	stmt args first value
				   parameters: 	stmt args second value
				   receiver:		#Oop].
		 stmt selector = #primitive:parameters:receiver: ifTrue:
			[^self primitive:		stmt args first value
				   parameters:	stmt args second value
				   receiver:		stmt args third value].
		^false].
	^false.

]

{ #category : #'specifying primitives' }
SmartSyntaxPluginTMethod >> namedPrimitiveProlog [
	"Generate the code for a primitive:parameters:... send.  This is in two parts.
	 The first is validation; the second is coercing assignment."
	| statements validator validations assigner |
	fullArgs isEmpty ifTrue:
		[^#()].
	validator := SmartSyntaxPluginValidationCodeGenerator new.
	statements := OrderedCollection new.
	validations := fullArgs withIndexCollect:
					[:arg :i|
					(parmSpecs at: i) 
							ccg: 	validator
							prolog:  nil
							expr: arg
							index: (fullArgs size - i)].
	validations := validations reject: [:validation| validation isNil].
	validations isEmpty ifFalse:
		[statements addAllLast: (self statementsFor:
									(String streamContents:
										[:s|
										s nextPut: $(.
										validations
											do: [:validation| s nextPut: $(; nextPutAll: validation; nextPut: $)]
											separatedBy: [s crtab; nextPutAll: 'and: ['].
										s next: validations size - 1 put: $].
										s	nextPutAll: ') ifFalse:';
											crtab: 2;
											nextPutAll: '[interpreterProxy primitiveFailFor: PrimErrBadArgument.';
											crtab: 2;
											nextPutAll: '^nil';
											crtab: 2;
											nextPut: $]])
									varName: '')].
	assigner := SmartSyntaxPluginAssignmentCodeGenerator new.
	fullArgs withIndexDo:
		[:arg :i|
		statements addAllLast:
			(self 
				statementsFor: 
					((parmSpecs at: i) 
						ccg: 	assigner
						prolog:  nil
						expr: arg
						index: (fullArgs size - i))
				varName: '')].
	^statements
]

{ #category : #private }
SmartSyntaxPluginTMethod >> nullReturnExpr [

	^ TReturnNode new
		setExpression: (TVariableNode new setName: 'null')
]

{ #category : #accessing }
SmartSyntaxPluginTMethod >> parmSpecs [

	^parmSpecs
]

{ #category : #private }
SmartSyntaxPluginTMethod >> pop: anInteger thenReturnExpr: anExpression [

	^TSendNode new
		setSelector: #pop:thenPush:
		receiver: (TVariableNode new setName: 'interpreterProxy')
		arguments: {TConstantNode new setValue: anInteger. anExpression}
]

{ #category : #private }
SmartSyntaxPluginTMethod >> popExpr: anInteger [

	^ TSendNode new
			 setSelector: #pop:
			 receiver: (TVariableNode new setName: 'interpreterProxy')
			 arguments: (Array 
				with: (TConstantNode new 
					setValue: anInteger))
]

{ #category : #'specifying primitives' }
SmartSyntaxPluginTMethod >> primitive: aString parameters: anArray receiver: aClassSymbol [

	fullSelector := selector.
	selector := aString asSymbol.
	anArray size == args size ifFalse: 
		[^self error: selector, ': incorrect number of parameter specifications'].
	parmSpecs := anArray collect:
		[:each | Smalltalk at: each ifAbsent:
			[^self error: selector, ': parameter spec must be a Behavior']].
	parmSpecs do: [:each | each isBehavior ifFalse:
		[^self error: selector, ': parameter spec must be a Behavior']].
	rcvrSpec := Smalltalk at: aClassSymbol asSymbol ifAbsent:
		[^self error: selector, ': receiver spec must be a Behavior'].
	rcvrSpec isBehavior ifFalse:
		[^self error: selector, ': receiver spec must be a Behavior'].
	^true
]

{ #category : #'specifying primitives' }
SmartSyntaxPluginTMethod >> primitiveDirectiveWasHandled: stmt on: sStream [

	(self isPrimitiveDirectiveSend: stmt) ifTrue:
		[^self handlePrimitiveDirective: stmt on: sStream].
	(stmt isAssignment and: 
		[self isPrimitiveDirectiveSend: stmt expression]) ifTrue:
			[^self handlePrimitiveDirective: stmt on: sStream].
	^false.

]

{ #category : #private }
SmartSyntaxPluginTMethod >> printTempsAndVar: varName on: aStream [ 
	"add the required temps and the varname to the stream"
	aStream nextPut: $|; space.
	(#('rcvr' 'stackPointer' 'interpreterProxy') reject: [:each | locals includes: each]) do:
		[:each | aStream nextPutAll: each;  space].
	(locals reject: [:each | each first = $_]) do:
		[:each | aStream nextPutAll: each;  space].
"don't add varName twice. Probably a deeper reason for this, but WTH. TPR"
	(locals includes: varName) ifFalse:
		[aStream nextPutAll: varName; space].
	aStream nextPut: $|; cr
]

{ #category : #accessing }
SmartSyntaxPluginTMethod >> rcvrSpec [

	^rcvrSpec
]

{ #category : #transforming }
SmartSyntaxPluginTMethod >> recordDeclarationsIn: aCCodeGen [
	"Record C type declarations of the forms
		<returnTypeC: 'float'>
		<var: #foo declareC: 'float foo'>
		<var: #foo type:'float'>
		<var: #foo as: Class>
	 or the older, obsolete
		self returnTypeC: 'float'.
		self var: #foo declareC: 'float foo'
		self var: #foo type:'float'.
		self var: #foo as: Class
	 and remove the declarations from the method body."

	| newStatements |
	properties pragmas notEmpty ifTrue: [ 
		properties pragmas do: [ :pragma | 
			pragma key == #var:declareC: ifTrue: [ 
				self
					checkedDeclarationAt: pragma arguments first asString
					put: pragma arguments last
					in: aCCodeGen ].
			pragma key == #var:type: ifTrue: [ 
				| varName varType |
				varName := pragma arguments first asString.
				varType := aCCodeGen conventionalTypeForType:
					           pragma arguments last.
				varType last == $* ifFalse: [ varType := varType , ' ' ].
				self
					checkedDeclarationAt: varName
					put: varType , varName
					in: aCCodeGen ].
			pragma key == #var:as: ifTrue: [ 
				| theClass |
				theClass := Smalltalk
					            at: pragma arguments last name asSymbol
					            ifAbsent: [ nil ].
				theClass isBehavior ifFalse: [ 
					^ self error: 'declarator must be a Behavior' ].
				self
					checkedDeclarationAt: pragma arguments first value asString
					put:
					(theClass ccgDeclareCForVar: pragma arguments first asString)
					in: aCCodeGen ].
			pragma key == #returnTypeC: ifTrue: [ 
				self returnType: pragma arguments last ].
			pragma key = #doNotGenerate: ifTrue: [ 
				locals removeKey: pragma arguments last ] ].
		^ self ].
	newStatements := OrderedCollection new: parseTree statements size.
	parseTree statements do: [ :stmt | 
		| isDeclaration |
		isDeclaration := false.
		stmt isSend ifTrue: [ 
			stmt selector == #var:declareC: ifTrue: [ 
				isDeclaration := true.
				self
					declarationAt: stmt args first value asString
					put: stmt args last value ].
			stmt selector = #var:type: ifTrue: [ 
				| varName varType |
				isDeclaration := true.
				varName := stmt args first value asString.
				varType := aCCodeGen conventionalTypeForType: stmt args last value.
				varType last == $* ifFalse: [ varType := varType , ' ' ].
				self declarationAt: varName put: varType , varName ].
			stmt selector == #var:as: ifTrue: [ 
				| theClass |
				isDeclaration := true.
				theClass := Smalltalk
					            at: stmt args last name asSymbol
					            ifAbsent: [ nil ].
				theClass isBehavior ifFalse: [ 
					^ self error: 'declarator must be a Behavior' ].
				self
					declarationAt: stmt args first value asString
					put: (theClass ccgDeclareCForVar: stmt args first value asString) ].
			stmt selector == #returnTypeC: ifTrue: [ 
				isDeclaration := true.
				returnType := stmt args last value ] ].
		isDeclaration ifFalse: [ newStatements add: stmt ] ].
	parseTree setStatements: newStatements asArray
]

{ #category : #transforming }
SmartSyntaxPluginTMethod >> replaceSizeMessages [
	"Replace sends of the message 'size' with calls to sizeOfSTArrayFromCPrimitive."

	parseTree nodesDo: [:n |
		(n isSend and: [n selector = #size]) ifTrue: [
			n
				setSelector: #sizeOfSTArrayFromCPrimitive:
				receiver: (TVariableNode new setName: 'interpreterProxy')
				arguments: (Array with: n receiver)]].

]

{ #category : #private }
SmartSyntaxPluginTMethod >> resultExpressionCanFail: aTSendNode [
	"Neither asSmallIntegerObj nor asBooleanObj can fail."
	^(#(asSmallIntegerObj asBooleanObj nilObject trueObject falseObject) includes: aTSendNode selector) not
]

{ #category : #private }
SmartSyntaxPluginTMethod >> resultSendAlwaysFails: aTSendNode [
	^(#(primitiveFail primitiveFailFor:) includes: aTSendNode selector)
		or: [aTSendNode selector == #success:
			 and: [aTSendNode args first isConstant
			 and: [aTSendNode args first value == false]]]
]

{ #category : #initialization }
SmartSyntaxPluginTMethod >> setSelector: sel definingClass: class args: argList locals: localList block: aBlockNode primitive: aNumber properties: methodProperties comment: aComment [
	"Initialize this method using the given information."

	selector := sel.
	definingClass := class.
	returnType := #sqInt. 	 "assume return type is sqInt for now"
	args := argList asOrderedCollection collect: [:arg | arg key].
	locals := (localList collect: [:arg | arg key]) asSet.
	declarations := Dictionary new.
	primitive := aNumber.
	properties := methodProperties.
	comment := aComment.
	parseTree := aBlockNode asTranslatorNodeIn: self.
	labels := Set new.
	complete := false.  "set to true when all possible inlining has been done"
	export := self extractExportDirective.
	static := self extractStaticDirective.
	self extractSharedCase.
	isPrimitive := false.  "set to true only if you find a primtive direction."
	self recordDeclarationsIn: CCodeGenerator basicNew. "Just for conventionalTypeForType:"
	self extractPrimitiveDirectives.

]

{ #category : #accessing }
SmartSyntaxPluginTMethod >> smalltalkSelector [
	"Answer the selector of the original Smalltalk method, not any mangled one."
	^fullSelector ifNil: [selector]
]

{ #category : #private }
SmartSyntaxPluginTMethod >> statementGuardedWithSuccess: aTParseNodeOrSequenceThereof [
	"Answer a TSendNode for interpreterProxy failed ifFalse: [aTParseNodeOrSequenceThereof]"
	^TSendNode new
		setSelector: #ifFalse:
		receiver: (TSendNode new
					setSelector: #failed
					receiver: (TVariableNode new setName: 'interpreterProxy')
					arguments: #())
		arguments: {(aTParseNodeOrSequenceThereof isTParseNode and: [aTParseNodeOrSequenceThereof isStmtList])
						ifTrue: [aTParseNodeOrSequenceThereof]
						ifFalse: [TStmtListNode new
									setArguments: #()
									statements: (aTParseNodeOrSequenceThereof isCollection
													ifTrue: [aTParseNodeOrSequenceThereof]
													ifFalse: [{aTParseNodeOrSequenceThereof}])]}
]

{ #category : #'primitive compilation' }
SmartSyntaxPluginTMethod >> vmNameString [
	"return the string to use as the vm name in code generated for this method"
	^'interpreterProxy'
]
