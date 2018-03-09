"
Variation of TMethod node of the Smalltalk C Code Generator, used in conjunction with TestCodeGenerator and TestInterpreterPlugin to generate named primitives with type coercion specifications.
"
Class {
	#name : #SmartSyntaxPluginTMethod,
	#superclass : #TMethod,
	#instVars : [
		'isPrimitive',
		'suppressingFailureGuards',
		'fullSelector',
		'fullArgs',
		'parmSpecs',
		'rcvrSpec'
	],
	#category : 'VMMaker-SmartSyntaxPlugins'
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
SmartSyntaxPluginTMethod >> extractSuppressFailureGuardDirective [
	"Scan the top-level statements for a pragma directive of the form:

		self suppressFailureGuards: <boolean>

	 and remove the directive from the method body. Answer the argument
	 of the directive or false if there is no #supressFailureGuards: directive."

	^self
		extractDirective: #suppressFailureGuards:
		valueBlock: [:sendNode| sendNode args first name = 'true']
		default: false
]

{ #category : #transforming }
SmartSyntaxPluginTMethod >> fixUpReturnOneStmt: stmt on: sStream [

	stmt isReturn ifFalse: [^sStream nextPut: stmt].
	(stmt expression isSend
	 and: [#('primitiveFail' 'primitiveFailFor:') includes: stmt expression selector]) ifTrue: 
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
	"^ expr with necessary guard checking"
	sStream isEmpty ifFalse: [self generateFailureGuardOn: sStream].
	(self resultExpressionAlwaysFails: stmt expression)
		ifTrue:
			[sStream nextPut: stmt expression]
		ifFalse:
			[sStream nextPut: (self assign: (self oopVariable: '_return_value') expression: stmt expression).
			 (self resultExpressionCanFail: stmt expression) ifTrue:
				[self generateFailureGuardOn: sStream].
			 sStream nextPut: (self pop: fullArgs size + 1 thenReturnExpr: (self oopVariable: '_return_value'))].
	sStream nextPut: self nullReturnExpr
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

{ #category : #initializing }
SmartSyntaxPluginTMethod >> fromContext: aContext primitive: aString parameters: aClassList receiver: aClass [

	fullArgs := args := aContext tempNames
				copyFrom: 1
				to: aContext method numArgs.
	self 
		primitive: aString
		parameters: aClassList
		receiver: aClass
]

{ #category : #private }
SmartSyntaxPluginTMethod >> generateFailureGuardOn: sStream [
	suppressingFailureGuards ifTrue: [^nil].
	sStream nextPutAll: self checkSuccessExpr

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
					ccg:		SmartSyntaxPluginCodeGenerator new
					prolog:  [:expr | aStmt variable name, ' := ', expr]
					expr: 	aStmt variable name
					index: 	(fullArgs size))
			varName: '')].

	"only add the failure guard if there are args or it is an assignment"
	(fullArgs isEmpty not or:[aStmt isAssignment]) ifTrue:[self generateFailureGuardOn: sStream].
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

	| cg |
	cg := SmartSyntaxPluginCodeGenerator new.
	^Array streamContents: [:sStream |
		1 to: fullArgs size do:
			[:i |
			 sStream nextPutAll: 
				(self 
					statementsFor: 
						((parmSpecs at: i) 
							ccg: 	cg
							prolog:  [:expr | (fullArgs at: i), ' := ', expr]
							expr: (fullArgs at: i)
							index: (fullArgs size - i))
					varName: '')]]
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
		arguments: (Array 
			with: (TConstantNode new 
				setValue: anInteger)
			with: anExpression)
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
	aStream nextPutAll: '| '.
	(#('rcvr' 'stackPointer' 'interpreterProxy') reject: [:each | locals includes: each])
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
	properties pragmas notEmpty ifTrue:
		[properties pragmas do:
			[:pragma|
			pragma keyword = #var:declareC: ifTrue:
				[self checkedDeclarationAt: pragma arguments first asString
					put: pragma arguments last
					in: aCCodeGen].
			pragma keyword = #var:type: ifTrue:
				[| varName varType |
				varName := pragma arguments first asString.
				varType := pragma arguments last.
				varType last = $* ifFalse: [varType := varType, ' '].
				self checkedDeclarationAt: varName
					put: varType, varName
					in: aCCodeGen].
			 pragma keyword = #var:as: ifTrue:
				[| theClass |
				 theClass := Smalltalk at: pragma arguments last name asSymbol ifAbsent: [nil].
				 (theClass isKindOf: Behavior) ifFalse:
					[^self error: 'declarator must be a Behavior'].
				 self checkedDeclarationAt: pragma arguments first value asString 
					put: (theClass ccgDeclareCForVar: pragma arguments first asString)
					in: aCCodeGen].
			pragma keyword = #returnTypeC: ifTrue:
				[self returnType: pragma arguments last].
			pragma keyword = #doNotGenerate: ifTrue:
				[locals removeKey: pragma arguments last]].
		^self].
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
					put: (theClass ccgDeclareCForVar: stmt args first value asString)].
			 stmt selector = #returnTypeC: ifTrue: 
				[isDeclaration := true.
				 returnType := stmt args last value]].
		 isDeclaration ifFalse: [newStatements add: stmt]].
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
SmartSyntaxPluginTMethod >> resultExpressionAlwaysFails: aTSendNode [
	^aTSendNode selector == #success:
	 and: [aTSendNode args first isConstant
	 and: [aTSendNode args first value == false]]
]

{ #category : #private }
SmartSyntaxPluginTMethod >> resultExpressionCanFail: aTSendNode [
	"Neither asSmallIntegerObj nor asBooleanObj can fail."
	^(#(asSmallIntegerObj asBooleanObj) includes: aTSendNode selector) not
]

{ #category : #initializing }
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
	suppressingFailureGuards := self extractSuppressFailureGuardDirective.
	self recordDeclarationsIn: nil.
	self extractPrimitiveDirectives.

]

{ #category : #accessing }
SmartSyntaxPluginTMethod >> smalltalkSelector [
	"Answer the selector of the original Smalltalk method, not any mangled one."
	^fullSelector ifNil: [selector]
]

{ #category : #'primitive compilation' }
SmartSyntaxPluginTMethod >> vmNameString [
	"return the string to use as the vm name in code generated for this method"
	^'interpreterProxy'
]
