"
Variation of JSMethod node of the Smalltalk JS Code Generator, used in conjunction with SmartSyntaxCodeGenerator and SmartSyntaxInterpreterPlugin to generate named primitives with type coercion specifications.
"
Class {
	#name : #JSSmartSyntaxPluginMethod,
	#superclass : #JSMethod,
	#instVars : [
		'isPrimitive',
		'suppressingFailureGuards',
		'selectorOverride',
		'fullArgs',
		'parmSpecs',
		'rcvrSpec'
	],
	#category : #'VMMakerJS-SmartSyntaxPlugins'
}

{ #category : #'as yet unclassified' }
JSSmartSyntaxPluginMethod class >> fromContext: aContext primitive: aString parameters: aClassList receiver: aClass [

	^super new 
		fromContext: aContext 
		primitive: aString 
		parameters: aClassList 
		receiver: aClass

]

{ #category : #accessing }
JSSmartSyntaxPluginMethod >> args: anInteger [

	^args := anInteger
]

{ #category : #private }
JSSmartSyntaxPluginMethod >> assign: variable expression: expression [

	^TAssignmentNode new
		setVariable: variable
		expression: expression
]

{ #category : #private }
JSSmartSyntaxPluginMethod >> checkSuccessExpr [
	"Return the parse tree for an expression that aborts the primitive if primFailCode is set."

	| expr |
	expr := 'interpreterProxy failed ifTrue: [^nil]'.
	^ self statementsFor: expr varName: ''

]

{ #category : #'specifying primitives' }
JSSmartSyntaxPluginMethod >> extractPrimitiveDirectives [
	"Set selectorOverride, and save args in fullArgs.  Scan top-level statements for a directive of the form:

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
		ifFalse: [self removeFinalSelfReturn].
	^false
]

{ #category : #transforming }
JSSmartSyntaxPluginMethod >> extractSuppressFailureGuardDirective [
	"Scan the top-level statements for a pragma directive of the form:

		self suppressFailureGuards: <boolean>

	 and remove the directive from the method body. Answer the argument of the directive or false if there is no #supressFailureGuards: directive."

	| result newStatements |
	result := false.
	newStatements := OrderedCollection new: parseTree statements size.
	parseTree statements do: [ :stmt |
		(stmt isSend and: [stmt selector = #suppressFailureGuards:]) ifTrue: [
			result := stmt args first name = 'true'.
		] ifFalse: [
			newStatements add: stmt.
		].
	].
	parseTree setStatements: newStatements asArray.
	^ result
]

{ #category : #transforming }
JSSmartSyntaxPluginMethod >> fixUpReturnOneStmt: stmt on: sStream [

	stmt isReturn ifFalse: [^sStream nextPut: stmt].
	(stmt expression isSend and: ['primitiveFail' = stmt expression selector]) ifTrue: 
		["failure return"
		 sStream nextPut: stmt expression.
		 sStream nextPut: self nullReturnExpr.
		 ^nil].
	(stmt expression isVariable and: ['nil' = stmt expression name]) ifTrue: 
		["^ nil -- this is never right unless automatically generated"
		 sStream nextPut: stmt.
		 ^nil].
	(stmt expression isVariable and: ['self' = stmt expression name]) ifTrue: 
		["^ self"
		 self generateFailureGuardOn: sStream.
		 fullArgs isEmpty ifFalse:[ sStream nextPut: (self popExpr: fullArgs size)].
		 sStream nextPut: self nullReturnExpr.
		 ^nil].
	(stmt expression isVariable | stmt expression isConstant | suppressingFailureGuards) ifTrue:
		["^ variable or ^ constant or ^ expr without guardchecking"
		 self generateFailureGuardOn: sStream.
		 sStream nextPut: (self pop: fullArgs size + 1 thenReturnExpr: stmt expression).
		 sStream nextPut: self nullReturnExpr.
		 ^nil].
	"^ expr with guardchecking"
	sStream nextPut: (self assign: (self oopVariable: '_return_value') expression: stmt expression).
	self generateFailureGuardOn: sStream.
	sStream nextPut: (self pop: fullArgs size + 1 thenReturnExpr: (self oopVariable: '_return_value')).
	sStream nextPut: self nullReturnExpr

]

{ #category : #transforming }
JSSmartSyntaxPluginMethod >> fixUpReturns [
	"Replace each return statement in this method with (a) the given postlog, (b) code to pop the receiver and the given number of arguments, and (c) code to push the integer result and return."

	parseTree nodesDo: [:node |
		node isStmtList ifTrue: [
			node setStatements: (Array streamContents:
				[:sStream |
				 node statements do: 
					[:stmt | self fixUpReturnOneStmt: stmt on: sStream]])]]
]

{ #category : #initializing }
JSSmartSyntaxPluginMethod >> fromContext: aContext primitive: aString parameters: aClassList receiver: aClass [

	fullArgs := args := aContext tempNames
				copyFrom: 1
				to: aContext method numArgs.
	self 
		primitive: aString
		parameters: aClassList
		receiver: aClass
]

{ #category : #private }
JSSmartSyntaxPluginMethod >> generateFailureGuardOn: sStream [
	suppressingFailureGuards ifTrue: [^nil].
	sStream nextPutAll: self checkSuccessExpr

]

{ #category : #'specifying primitives' }
JSSmartSyntaxPluginMethod >> handlePrimitiveDirective: aStmt on: sStream [

	isPrimitive := true.
	fullArgs := args.
	locals addAll: args.
	args := OrderedCollection new.
	fullArgs with: parmSpecs do:
		[:argName :spec |
			declarations
				at: argName
				put: (spec jscgDeclareJSForVar: argName)].
	aStmt isAssignment ifTrue:
		[declarations
			at: aStmt variable name
			put: (rcvrSpec jscgDeclareJSForVar: aStmt variable name).
		 sStream nextPutAll: (self
			statementsFor:
				(rcvrSpec
					jscg:	JSSmartSyntaxPluginCodeGenerator new
					prolog:  [:expr | aStmt variable name, ' := ', expr]
					expr: 	aStmt variable name
					index: 	(fullArgs size))
			varName: '')].

	"only add the failure guard if there are args or it is an assignment"
	(fullArgs isEmpty not or:[aStmt isAssignment]) ifTrue:[self generateFailureGuardOn: sStream].
	^true.

]

{ #category : #'specifying primitives' }
JSSmartSyntaxPluginMethod >> isPrimitiveDirectiveSend: stmt [
	
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
JSSmartSyntaxPluginMethod >> namedPrimitiveProlog [

	| cg |
	cg := SmartSyntaxPluginCodeGenerator new.
	^Array streamContents: [:sStream |
		1 to: fullArgs size do:
			[:i |
			 sStream nextPutAll: 
				(self 
					statementsFor: 
						((parmSpecs at: i) 
							jscg: 	cg
							prolog:  [:expr | (fullArgs at: i), ' := ', expr]
							expr: (fullArgs at: i)
							index: (fullArgs size - i))
					varName: '')]]
]

{ #category : #private }
JSSmartSyntaxPluginMethod >> nullReturnExpr [

	^ TReturnNode new
		setExpression: (TVariableNode new setName: 'null')
]

{ #category : #private }
JSSmartSyntaxPluginMethod >> oopVariable: aString [

	(locals includes: aString) ifFalse:
		[locals add: aString.
		 declarations
			at: aString 
			put: 'sqInt ', aString].
	^TVariableNode new setName: aString
]

{ #category : #accessing }
JSSmartSyntaxPluginMethod >> parmSpecs [

	^parmSpecs
]

{ #category : #private }
JSSmartSyntaxPluginMethod >> pop: anInteger thenReturnExpr: anExpression [

	^TSendNode new
		setSelector: #pop:thenPush:
		receiver: (TVariableNode new setName: 'interpreterProxy')
		arguments: (Array 
			with: (TConstantNode new 
				setValue: anInteger)
			with: anExpression)
]

{ #category : #private }
JSSmartSyntaxPluginMethod >> popExpr: anInteger [

	^ TSendNode new
			 setSelector: #pop:
			 receiver: (TVariableNode new setName: 'interpreterProxy')
			 arguments: (Array 
				with: (TConstantNode new 
					setValue: anInteger))
]

{ #category : #'specifying primitives' }
JSSmartSyntaxPluginMethod >> primitive: aString parameters: anArray receiver: aClassSymbol [

	self selectorOverride: aString asSymbol.
	anArray size == args size ifFalse: 
		[^self error: self selectorOverride, ': incorrect number of parameter specifications'].
	parmSpecs := anArray collect:
		[:each | Smalltalk at: each ifAbsent:
			[^self error: self selectorOverride, ': parameter spec must be a Behavior']].
	parmSpecs do: [:each | each isBehavior ifFalse:
		[^self error: self selectorOverride, ': parameter spec must be a Behavior']].
	rcvrSpec := Smalltalk at: aClassSymbol asSymbol ifAbsent:
		[^self error: self selectorOverride, ': receiver spec must be a Behavior'].
	rcvrSpec isBehavior ifFalse:
		[^self error: self selectorOverride, ': receiver spec must be a Behavior'].
	^true
]

{ #category : #'specifying primitives' }
JSSmartSyntaxPluginMethod >> primitiveDirectiveWasHandled: stmt on: sStream [

	(self isPrimitiveDirectiveSend: stmt) ifTrue:
		[^self handlePrimitiveDirective: stmt on: sStream].
	(stmt isAssignment and: 
		[self isPrimitiveDirectiveSend: stmt expression]) ifTrue:
			[^self handlePrimitiveDirective: stmt on: sStream].
	^false.

]

{ #category : #private }
JSSmartSyntaxPluginMethod >> printTempsAndVar: varName on: aStream [ 
	"add the required temps and the varname to the stream"
	aStream nextPutAll: '| '.
	(#('rcvr' 'stackPointer' 'successFlag' 'interpreterProxy' ) reject: [:each | locals includes: each])
		do: [:each | aStream nextPutAll: each;
			 space].
	(locals reject: [:each | each first = $_])
		do: [:each | aStream nextPutAll: each;
			 space].
"don't add varName twice. Probably a deeper reason for this, but WTH. TPR"
	(locals includes: varName) ifFalse:[aStream nextPutAll: varName].
	aStream nextPutAll: '|';
	 cr
]

{ #category : #accessing }
JSSmartSyntaxPluginMethod >> rcvrSpec [

	^rcvrSpec
]

{ #category : #transforming }
JSSmartSyntaxPluginMethod >> recordDeclarations [
	"Record C type declarations of the forms

		self returnTypeC: 'float'.
		self var: #foo declareC: 'float foo'
		self var: #foo as: Class
		self var: #foo type: 'float'.

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
			 pragma keyword = #var:as: ifTrue:
				[| theClass |
				 theClass := Smalltalk at: pragma arguments last name asSymbol ifAbsent: [nil].
				 (theClass isKindOf: Behavior) ifFalse:
					[^self error: 'declarator must be a Behavior'].
				 self declarationAt: pragma arguments first value asString 
					put: (theClass jscgDeclareJSForVar: pragma arguments first asString)].
			pragma keyword = #returnTypeC: ifTrue:
				[returnType := pragma arguments last].
			pragma keyword = #doNotGenerate: ifTrue:
				[locals removeKey: pragma arguments last]]].
	newStatements := OrderedCollection new: parseTree statements size.
	parseTree statements do: 
		[:stmt | | isDeclaration |
		 isDeclaration := false.
		 stmt isSend ifTrue: 
			[stmt selector = #var:declareC: ifTrue:
				[isDeclaration := true.
				self declarationAt: stmt args first value asString put: stmt args last value].
			stmt selector = #var:type: ifTrue: [
				| varName varType |
				isDeclaration := true.
				varName := stmt args first value asString.
				varType := stmt args last value.
				varType last = $* ifFalse: [varType := varType, ' '].
				self declarationAt: varName put: varType, varName.
			].
			 stmt selector = #var:as: ifTrue:
				[| theClass |
				 isDeclaration := true.
				 theClass := Smalltalk  at: stmt args last name asSymbol ifAbsent: [nil].
				 (theClass isKindOf: Behavior) ifFalse:
					[^self error: 'declarator must be a Behavior'].
				 self declarationAt: stmt args first value asString 
					put: (theClass jscgDeclareJSForVar: stmt args first value asString)].
			 stmt selector = #returnTypeC: ifTrue: 
				[isDeclaration := true.
				 returnType := stmt args last value]].
		 isDeclaration ifFalse: [newStatements add: stmt]].
	parseTree setStatements: newStatements asArray
]

{ #category : #transforming }
JSSmartSyntaxPluginMethod >> removeFinalSelfReturn [
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

{ #category : #transforming }
JSSmartSyntaxPluginMethod >> replaceArraySizeMessages [
	"Replace sends of the message 'size' with calls to sizeOfSTArrayFromCPrimitive. Specialised version for generating primitives outside a plugin"

	super replaceSizeMessages

]

{ #category : #transforming }
JSSmartSyntaxPluginMethod >> replaceSizeMessages [
	"Replace sends of the message 'size' with calls to sizeOfSTArrayFromCPrimitive."

	parseTree nodesDo: [:n |
		(n isSend and: [n selector = #size]) ifTrue: [
			n
				setSelector: #sizeOfSTArrayFromCPrimitive:
				receiver: (TVariableNode new setName: 'interpreterProxy')
				arguments: (Array with: n receiver)]].

]

{ #category : #accessing }
JSSmartSyntaxPluginMethod >> selectorForCodeGeneration [
	"A primitive directive my override the selector specification."

	^ self selectorOverride ifNil: [self selector]
]

{ #category : #accessing }
JSSmartSyntaxPluginMethod >> selectorOverride [
	"A primitive directive allows the selector to be overridden in order to specify
	a preferred name for the generated primitive."

	^ selectorOverride
]

{ #category : #accessing }
JSSmartSyntaxPluginMethod >> selectorOverride: preferredSelectorName [
	"A primitive directive allows the selector to be overridden in order to specify
	a preferred name for the generated primitive."

	selectorOverride := preferredSelectorName
]

{ #category : #initializing }
JSSmartSyntaxPluginMethod >> setSelector: sel definingClass: class args: argList locals: localList block: aBlockNode primitive: aNumber properties: methodProperties comment: aComment [
	"Initialize this method using the given information."

	selector := sel.
	definingClass := class.
	returnType := #sqInt. 	 "assume return type is sqInt for now"
	args := argList asOrderedCollection collect: [:arg | arg key].
	locals := localList asOrderedCollection collect: [:arg | arg key].
	declarations := Dictionary new.
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
	isPrimitive := false.  "set to true only if you find a primtive direction."
	suppressingFailureGuards := self extractSuppressFailureGuardDirective.
	self recordDeclarations.
	self extractPrimitiveDirectives.

]

{ #category : #'specifying primitives' }
JSSmartSyntaxPluginMethod >> simulatePrologInContext: aContext [

	|cg instructions |
	cg := SmartSyntaxPluginCodeGenerator new.
	parmSpecs keysAndValuesDo: 
		[:index :each |
		 instructions := ((parmSpecs at: index)
			jscg: cg 
			prolog: (cg jscgTVarBlock: index) 
			expr: '<foo>' 
			index: args size - index).
		 Compiler new 
			evaluate: instructions
			in: aContext 
			to: aContext receiver
			notifying: nil
			ifFail: nil].
	instructions := (rcvrSpec
		jscg: cg 
		prolog: [:expr | '^', expr]
		expr: '<foo>' 
		index: args size).
	 ^Compiler new 
		evaluate: instructions
		in: aContext 
		to: aContext receiver
		notifying: nil
		ifFail: nil
]

{ #category : #'primitive compilation' }
JSSmartSyntaxPluginMethod >> vmNameString [
	"return the string to use as the vm name in code generated for this method"
	^'interpreterProxy'
]
