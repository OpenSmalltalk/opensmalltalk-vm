Class {
	#name : #CogScripts,
	#superclass : #Object,
	#category : #'Cog-Scripts'
}

{ #category : #'closure scripts' }
CogScripts class >> bootstrapClosuresClosureCompilerSwitchCode [
	^'
!Parser methodsFor: ''public access'' stamp: ''eem 5/15/2008 15:44''!
encoder
	encoder isNil ifTrue:
		[encoder := EncoderForV3PlusClosures new].
	^encoder! !'
]

{ #category : #'closure scripts' }
CogScripts class >> bootstrapClosuresCompilerPreloadCode [
	^'
!ClassBuilder methodsFor: ''class format'' stamp: ''eem 6/13/2008 10:03''!
computeFormat: type instSize: newInstSize forSuper: newSuper ccIndex: ccIndex
	"Compute the new format for making oldClass a subclass of newSuper.
	Return the format or nil if there is any problem."
	| instSize isVar isWords isPointers isWeak |
	type == #compiledMethod
		ifTrue:[^CompiledMethod format].
	instSize := newInstSize + (newSuper ifNil:[0] ifNotNil:[newSuper instSize]).
	instSize > 254 ifTrue:[
		self error: ''Class has too many instance variables ('', instSize printString,'')''.
		^nil].
	type == #normal ifTrue:[isVar := isWeak := false. isWords := isPointers := true].
	type == #bytes ifTrue:[isVar := true. isWords := isPointers := isWeak := false].
	type == #words ifTrue:[isVar := isWords := true. isPointers := isWeak := false].
	type == #variable ifTrue:[isVar := isPointers := isWords := true. isWeak := false].
	type == #weak ifTrue:[isVar := isWeak := isWords := isPointers := true].
	(isPointers not and:[instSize > 0]) ifTrue:[
		self error:''A non-pointer class cannot have instance variables''.
		^nil].
	^(self format: instSize 
		variable: isVar 
		words: isWords 
		pointers: isPointers 
		weak: isWeak) + (ccIndex bitShift: 11).! !

!ClassBuilder methodsFor: ''public'' stamp: ''eem 6/13/2008 10:00''!
superclass: aClass
	variableByteSubclass: t instanceVariableNames: f 
	classVariableNames: d poolDictionaries: s category: cat
	"This is the standard initialization message for creating a new class as a 
	subclass of an existing class in which the subclass is to 
	have indexable byte-sized nonpointer variables."
	| oldClassOrNil actualType |
	(aClass instSize > 0)
		ifTrue: [^self error: ''cannot make a byte subclass of a class with named fields''].
	(aClass isVariable and: [aClass isWords])
		ifTrue: [^self error: ''cannot make a byte subclass of a class with word fields''].
	(aClass isVariable and: [aClass isPointers])
		ifTrue: [^self error: ''cannot make a byte subclass of a class with pointer fields''].
	oldClassOrNil := aClass environment at: t ifAbsent:[nil].
	actualType := (oldClassOrNil notNil
				   and: [oldClassOrNil typeOfClass == #compiledMethod])
					ifTrue: [#compiledMethod]
					ifFalse: [#bytes].
	^self 
		name: t
		inEnvironment: aClass environment
		subclassOf: aClass
		type: actualType
		instanceVariableNames: f
		classVariableNames: d
		poolDictionaries: s
		category: cat! !

!Array methodsFor: ''testing'' stamp: ''eem 5/8/2008 11:13''!
isArray
	^true! !

!Object methodsFor: ''testing'' stamp: ''eem 5/8/2008 11:13''!
isArray
	^false! !

!Behavior methodsFor: ''compiling'' stamp: ''eem 5/13/2008 09:50''!
instVarNamesAndOffsetsDo: aBinaryBlock
	"This is part of the interface between the compiler and a class''s instance or field names.
	 The class should enumerate aBinaryBlock with the instance variable name strings and
	 their integer offsets.  The order is important. Names evaluated later will override the
	 same names occurring earlier."

	"Nothing to do here; ClassDescription introduces named instance variables"
	^self! !

!ClassDescription methodsFor: ''compiling'' stamp: ''eem 5/13/2008 09:48''!
instVarNamesAndOffsetsDo: aBinaryBlock
	"This is part of the interface between the compiler and a class''s instance or field names.
	 The class should enumerate aBinaryBlock with the instance variable name strings and
	 their integer offsets.  The order is important. Names evaluated later will override the
	 same names occurring earlier."

	| superInstSize |
	(superInstSize := superclass notNil ifTrue: [superclass instSize] ifFalse: [0]) > 0 ifTrue:
		[superclass instVarNamesAndOffsetsDo: aBinaryBlock].
	1 to: self instSize - superInstSize do:
		[:i| aBinaryBlock value: (instanceVariables at: i) value: i + superInstSize]! !


!Behavior methodsFor: ''compiling'' stamp: ''eem 5/13/2008 09:50''!
variablesAndOffsetsDo: aBinaryBlock
	"This is the interface between the compiler and a class''s instance or field names.  The
	 class should enumerate aBinaryBlock with the field definitions (with nil offsets) followed
	 by the instance variable name strings and their integer offsets.  The order is important.
	 Names evaluated later will override the same names occurring earlier."

	"Only need to do instance variables here.  CProtoObject introduces field definitions."
	self instVarNamesAndOffsetsDo: aBinaryBlock! !

!CProtoObject class methodsFor: ''compiling'' stamp: ''eem 5/13/2008 09:53''!
variablesAndOffsetsDo: aBinaryBlock
	"This is the interface between the compiler and a class''s instance or field names.  The
	 class should enumerate aBinaryBlock with the field definitions (with nil offsets) followed
	 by the instance variable name strings and their integer offsets.  The order is important.
	 Names evaluated later will override the same names occurring earlier."

	self allFieldsReverseDo: [:field| aBinaryBlock value: field value: nil].
	self instVarNamesAndOffsetsDo: aBinaryBlock! !'
]

{ #category : #'closure scripts' }
CogScripts class >> bootstrapClosuresNeuterMonticelloCode [
	^'
!MCVersionLoader methodsFor: ''checking'' stamp: ''eem 6/12/2008 17:30''!
checkForModifications
	| modifications |
	modifications := versions select: [:ea | ea package workingCopy modified].
	true ifTrue: [^true].
	modifications isEmpty ifFalse: [self warnAboutLosingChangesTo: modifications].! !

!MCClassDefinition methodsFor: ''installing'' stamp: ''eem 6/12/2008 17:53''!
unload
	(Smalltalk at: #DoNotUnload ifAbsent: [false]) ifTrue: [^self].
	Smalltalk removeClassNamed: name! !

!MCMethodDefinition methodsFor: ''installing'' stamp: ''eem 6/12/2008 17:53''!
unload
	| previousVersion |
	(Smalltalk at: #DoNotUnload ifAbsent: [false]) ifTrue: [^self].
	self isOverrideMethod ifTrue: [previousVersion := self scanForPreviousVersion].
	previousVersion
		ifNil: [self actualClass ifNotNilDo: [:class | class removeSelector: selector]]
		ifNotNil: [previousVersion fileIn] ! !

!MCOrganizationDefinition methodsFor: ''as yet unclassified'' stamp: ''eem 6/12/2008 18:06''!
postloadOver: oldDefinition
	[SystemOrganization categories:
		(self
			reorderCategories: SystemOrganization categories
			original: (oldDefinition ifNil: [#()] ifNotNil: [oldDefinition categories]))]
		on: Error
		do: [:ex| Transcript cr; print: ex messageText; endEntry]! !

!MCPackageLoader methodsFor: ''private'' stamp: ''eem 6/12/2008 21:32''!
tryToLoad: aDefinition
	[aDefinition loadOver: (self obsoletionFor: aDefinition)]
		on: Error
		do: [:ex| self halt. errorDefinitions add: aDefinition]! !'
]

{ #category : #'separate vm scripts' }
CogScripts class >> browseExclusiveMethodImportsForPrimitiveClass: primClass [
	"Browse methods used by the class holding VM primitives and unused elsewhere."
	"self browseExclusiveMethodImportsForPrimitiveClass: StackInterpreterSPrimitives"
	Cursor execute showWhile:
		["The algorithm computes a fixed point of the methods used
		   by the parcel which are unused outside it.  The algorithm is
				compute messages sent within parcel
				repeat until at a fixed point:
					compute intersection of this with methods implemented outside parcel
					compute messages sent outside parcel not within the intersection
					remove these from intersection"

		| parcelMessages "<IdentitySet of: Symbol>
								messages sent within this parcel"
		  externalMethods "<Set of: MethodDescription>
								methods implemented outside this parcel"
		  danglingMethods "<Set of: MethodDescription>
								methods importeded only by this parcel"
		  previousDangling "<Set of: MethodDescription>
								intermediate value of danglingMethods (for determining if fixed point is reached)"
		  danglingMessages "<Set of: Symbol> selectors of methods in danglingMethods"
		  noLongerDangling "<Set of: Symbol> selectors to be moved from dangling" |

		parcelMessages := IdentitySet new.
		primClass methodsDo:
			[:meth| parcelMessages addAll: meth messages].
		"compute starting points for danglingMethods and externalMethods"
		danglingMethods := Set new: 50.
		externalMethods := Set new: 20000.
		(PackageInfo named: 'VMMaker') classes do:
			[:aBehavior| | extends |
			(aBehavior = primClass or: [aBehavior inheritsFrom: primClass]) ifFalse:
				[aBehavior selectorsAndMethodsDo:
					[:sel :meth|
					(primClass includesSelector: sel) ifFalse:
						[((parcelMessages includes: sel)
							ifTrue: [danglingMethods]
							ifFalse: [externalMethods])
								add: (MethodReference class: aBehavior selector: sel)]]]].
		["Now iterate to the fixed-point.  Any method in dangling with a selector sent
		  in external must be moved into external until dangling reaches its fixed point."
		previousDangling := danglingMethods copy.
		danglingMessages := danglingMethods collect: [:md| md selector].
		noLongerDangling := Set new: danglingMethods size.
		externalMethods do:
			[:md|
			md compiledMethod messages do:
				[:l|
				(danglingMessages includes: l) ifTrue:
					[noLongerDangling add: l]]].
		externalMethods := danglingMethods select: [:md| noLongerDangling includes: md selector].
		danglingMethods removeAll: externalMethods.
		danglingMethods size ~= previousDangling size] whileTrue.
		SystemNavigation default
			browseMessageList: danglingMethods asSortedCollection
			name: 'Methods Used Only by ', primClass name, ' but not in ', primClass name]
]

{ #category : #'separate vm scripts' }
CogScripts class >> changeMethodsForBasicConstantSendsIn: aClass [
	"CogScripts changedMethodsForBasicConstantSendsIn: StackInterpreter"
	| receiver rules model env |
	rules := RBParseTreeRewriter new.
	receiver := ((aClass includesBehavior: ObjectMemory)
				 or: [aClass includesBehavior: SpurMemoryManager])
					ifTrue: ['self']
					ifFalse:
						[#('objectMemory' 'manager' 'interpreterProxy') detect: [:ivn| (aClass instVarIndexFor: ivn ifAbsent: nil) notNil]].
	rules
		replace: 'BaseHeaderSize' with: receiver, ' baseHeaderSize';
		replace: 'BytesPerOop' with: receiver, ' bytesPerOop';
		replace: 'BytesPerWord' with: receiver, ' wordSize';
		replace: 'ShiftForWord' with: receiver, ' shiftForWord'.
	model := RBNamespace new.
	env := RBBrowserEnvironment new forClasses: { aClass }.
	env classesAndSelectorsDo:
		[ :class :selector | | tree |
		tree := class parseTreeFor: selector.
		(rules executeTree: tree) ifTrue:
			[model compile: rules tree newSource in: class classified: (class whichCategoryIncludesSelector: selector)]].

	model changes changes do:
		[:mr|
		aClass
			compile: mr source
			classified: (aClass whichCategoryIncludesSelector: mr selector)
			withStamp: (Utilities changeStamp copyReplaceAll: Utilities authorInitials with: Utilities authorInitials, ' (const to msg rewrite)')
			notifying: nil]
]

{ #category : #'separate vm scripts' }
CogScripts class >> changedMethodsForObjectMemorySends [
	"Answer the methods in StackInterpreter and subclasses that change if sends to self for methods implemented
	 in ObjectMemory, NewObjectMemory (& NewObjectMemorySE ?) become sends to objectMemory."
	"CogScripts changedMethodsForObjectMemorySends"
	| selectors rules model environment sortedChanges |
	selectors := { ObjectMemory. NewObjectMemory. "NewObjectMemorySE" }
					inject: Set new
					into: [:sels :class| sels addAll: class selectors; yourself].
	rules := RBParseTreeRewriter new.
	rules
		replace: 'self `@method: ``@args'
		with: 'objectMemory `@method: ``@args'
		when: [:node| selectors includes: node selector].
	#(	'nilObj' 'trueObj' 'falseObj')
		do: [:instVar|
			rules
				replace: instVar, ' := ``@args' with: 'objectMemory ', instVar, 'ect: ``@args';
				replace: instVar with: 'objectMemory ', instVar, 'ect'].
	self readWriteVars do: [:instVar|
			rules
				replace: instVar, ' := ``@args' with: 'objectMemory ', instVar, ': ``@args';
				replace: instVar with: 'objectMemory ', instVar].
	self readOnlyVars do: [:instVar|
			rules replace: instVar with: 'objectMemory ', instVar].
	model := RBNamespace new.
	environment := RBBrowserEnvironment new forClasses:
						{ StackInterpreter. CoInterpreter. CoInterpreterMT.
						   StackInterpreterSimulator. CogVMSimulator }.
	environment classesAndSelectorsDo:
		[ :class :selector | | tree |
		"(class == StackInterpreter and: [selector == #isContextHeader:]) ifTrue: [self halt]."
		"(class == StackInterpreter and: [selector == #isIndexable:]) ifTrue: [self halt]."
		"(class == StackInterpreter and: [selector == #printContextCallStackOf:]) ifTrue: [self halt]."
		tree := class parseTreeFor: selector.
		(rules executeTree: tree) ifTrue:
			[model compile: rules tree newSource in: class classified: (class whichCategoryIncludesSelector: selector)]].
	false ifTrue: [model changes inspect].
	false ifTrue: "shortest change:"
		[(model changes changes inject: model changes changes first into: [:c1 :c2| c1 printString size < c2 printString size ifTrue: [c1] ifFalse: [c2]]) inspect].

	sortedChanges := model changes changes asSortedCollection:
						[:c1 :c2|
						c1 changeClass == c2 changeClass
							ifTrue: [c1 selector <= c2 selector]
							ifFalse: [c2 changeClass inheritsFrom: c1 changeClass]].
	true ifTrue:
		[MessageSetTextDifferencer
			openMessageList: (sortedChanges collect: [:mr| { MethodReference class: mr changeClass selector: mr selector. TextReference new text: mr source class: mr class selector: mr selector }])
			name: 'self foo <-> objectMemory foo et al' 
			autoSelect: nil].

	^sortedChanges
]

{ #category : #'separate vm scripts' }
CogScripts class >> changedSpurCompactorMethods [
	"Answer the methods in SpurPigCompactor and subclasses that change if sends to self for methods implemented
	 in SpurMemoryManager become sends to manager."
	"CogScripts changedSpurCompactorMethods"
	| selectors compactorVars spurMemoryManagerSelectors rules model environment sortedChanges |
	selectors := (self systemNavigation allAccessesTo: 'firstFreeChunk' from: SpurMemoryManager) asSet,
				 (self systemNavigation allAccessesTo: 'lastFreeChunk' from: SpurMemoryManager)
					collect: [:mr| mr selector].
	selectors addAll: (SpurMemoryManager selectors select: [:s| ('*pigcompact*' match: s) or: [s endsWith: 'Pig']]).
	compactorVars := #('numCompactionPasses' 'firstFreeChunk' 'lastFreeChunk' 'scavenger' 'coInterpreter').
	spurMemoryManagerSelectors := SpurMemoryManager selectors.
	rules := RBParseTreeRewriter new.
	rules
		replace: 'self `@method: ``@args'
		with: 'manager `@method: ``@args'
		when: [:node| (spurMemoryManagerSelectors includes: node selector) and: [(selectors includes: node selector) not]].
	(SpurMemoryManager instVarNames reject: [:iv| compactorVars includes: iv]) do:
		[:instVar|
		 rules
			replace: instVar, ' := ``@args' with: 'manager ', instVar, ': ``@args';
			replace: instVar with: 'manager ', instVar].
	#(	'nilObj' 'trueObj' 'falseObj')
		do: [:instVar|
			rules
				replace: instVar, ' := ``@args' with: 'manager ', instVar, 'ect: ``@args';
				replace: instVar with: 'manager ', instVar, 'ect'].
	model := RBNamespace new.
	environment := RBBrowserEnvironment new forClasses: { SpurMemoryManager }.
	environment classesAndSelectorsDo:
		[ :class :selector | | tree |
		((selectors includes: selector)
		 and: [rules executeTree: (tree := class parseTreeFor: selector)]) ifTrue:
			[model compile: rules tree newSource in: class classified: (class whichCategoryIncludesSelector: selector)]].
	false ifTrue: [model changes inspect].
	false ifTrue: "shortest change:"
		[(model changes changes inject: model changes changes first into: [:c1 :c2| c1 printString size < c2 printString size ifTrue: [c1] ifFalse: [c2]]) inspect].

	sortedChanges := model changes changes asSortedCollection:
						[:c1 :c2|
						c1 changeClass == c2 changeClass
							ifTrue: [c1 selector <= c2 selector]
							ifFalse: [c2 changeClass inheritsFrom: c1 changeClass]].
	true ifTrue:
		[MessageSetTextDifferencer
			openMessageList: (sortedChanges collect: [:mr| { MethodReference class: mr changeClass selector: mr selector. TextReference new text: mr source class: mr changeClass selector: mr selector }])
			name: 'self foo <-> manager foo et al' 
			autoSelect: nil].

	^sortedChanges
]

{ #category : #'separate vm scripts' }
CogScripts class >> createObjMemSims [
	"self createObjMemSims"
	{ NewObjectMemory. NewCoObjectMemory } do:
		[:c| | sc oc nc |
		sc := Compiler evaluate: ((Class templateForSubclassOf: c category: c category, 'Simulation') copyReplaceAll: 'NameOfSubclass' with: c name, 'Simulator').
		false ifTrue:
			[oc := NewObjectMemorySimulator.
			oc selectors do:
				[:s| [sc compile: (oc sourceCodeAt: s) asString
						classified: (oc whichCategoryIncludesSelector: s)
						withStamp: (oc >> s) timeStamp
						notifying: nil] on: Error do: [:ex|]]].
		nc := Compiler evaluate: ((Class templateForSubclassOf: sc category: sc category) copyReplaceAll: 'NameOfSubclass' with: sc name, 'LSB').
		oc := nc selectors size > 0 ifTrue: [nc] ifFalse: [NewObjectMemorySimulatorLSB].
		oc selectors do:
			[:s| | aoc |
			aoc := (CogVMSimulatorLSB includesSelector: s) ifTrue: [CogVMSimulatorLSB] ifFalse: [NewObjectMemorySimulatorLSB].
			nc compile: (aoc sourceCodeAt: s) asString
					classified: (aoc whichCategoryIncludesSelector: s)
					withStamp: (aoc >> s) timeStamp
					notifying: nil].
		nc := Compiler evaluate: ((Class templateForSubclassOf: sc category: sc category) copyReplaceAll: 'NameOfSubclass' with: sc name, 'MSB').
		oc := NewObjectMemorySimulatorMSB.
		oc selectors do:
			[:s| nc compile: (oc sourceCodeAt: s) asString
					classified: (oc whichCategoryIncludesSelector: s)
					withStamp: (oc >> s) timeStamp
					notifying: nil]]
]

{ #category : #'separate vm scripts' }
CogScripts class >> defineSpurPigCompactor [
	"Define SpurPigCompactor"
	"self defineSpurPigCompactor"
	| changes pigCompactor |
	pigCompactor := SpurMemoryManager superclass
						subclass: #SpurPigCompactor
						instanceVariableNames: 'manager scavenger coInterpreter firstFreeChunk lastFreeChunk numCompactionPasses'
						classVariableNames: 'CompactionPassesForGC CompactionPassesForSnapshot'
						poolDictionaries: 'SpurMemoryManagementConstants VMBasicConstants VMSpurObjectRepresentationConstants'
						category: SpurMemoryManager category.
	changes := CogScripts changedSpurCompactorMethods.
	changes do:
		[:mr|
		pigCompactor compile: mr source classified: (SpurMemoryManager whichCategoryIncludesSelector: mr selector)].
	changes do:
		[:mr|
		SpurMemoryManager removeSelector: mr selector].
	SpurMemoryManager organization removeEmptyCategories
]

{ #category : #'separate vm scripts' }
CogScripts class >> doClassSide [
	"self doClassSide"
	| classes rules model env sortedChanges |
	classes := (PackageInfo named: 'VMMaker') classes.
	classes := classes select: [:c| classes anySatisfy: [:d| d name last = $S and: [d name allButLast = c name]]].

	rules := RBParseTreeRewriter new.
	model := RBNamespace new.
	env := RBBrowserEnvironment new forClasses: classes.
	classes do: [:c| rules replace: c name with: c name, 'S'].
	env classesAndSelectorsDo:
		[:class :selector| | tree |
		class isMeta ifTrue:
			[tree := class parseTreeFor: selector.
			rules executeTree: tree.
			model compile: rules tree newSource in: class classified: (class whichCategoryIncludesSelector: selector)]].
	false ifTrue: [model changes inspect].
	false ifTrue: "shortest change:"
		[(model changes changes inject: model changes changes first into: [:c1 :c2| c1 printString size < c2 printString size ifTrue: [c1] ifFalse: [c2]]) inspect].

	sortedChanges := model changes changes asSortedCollection:
						[:c1 :c2|
						c1 changeClass == c2 changeClass
							ifTrue: [c1 selector <= c2 selector]
							ifFalse: [c2 changeClass inheritsFrom: c1 changeClass]].
	true ifTrue:
		[MessageSetTextDifferencer
			openMessageList: (sortedChanges collect: [:mr| { MethodReference class: mr changeClass selector: mr selector. TextReference new text: mr source class: mr class selector: mr selector }])
			name: 'class side' 
			autoSelect: nil].

	sortedChanges do:
		[:mr|
		(Smalltalk classNamed: (mr changeClass theNonMetaClass name, 'S') asSymbol) class
			compile: mr source
			classified: (mr changeClass whichCategoryIncludesSelector: mr selector)
			withStamp: (mr source asString = (mr changeClass sourceCodeAt: mr selector) asString
							ifTrue: [(mr changeClass >> mr selector) timeStamp]
							ifFalse: [Utilities changeStamp copyReplaceAll: Utilities authorInitials with: Utilities authorInitials, ' (objmem refactor)'])
			notifying: nil]
]

{ #category : #'plugin scripts' }
CogScripts class >> eliminateCCodeInSmalltalkFrom: aPluginClass [
	"Edit any self cCode: 'something that looks like a C call' [ inSmalltalk: [ ...] ]
	 into the function: arg1 _: arg2 style, ensuring that if the class has (a) simulator
	 subclass(es), that a stub implementation exists in the subclass. Write any failures
	 to the transcript."

	"(Smalltalk organization classesInCategory: #'3DICC-Plugins') do:
		[:aPluginClass|
		CogScripts eliminateCCodeInSmalltalkFrom: aPluginClass]"

	| transformations |
	transformations := Dictionary new.
	aPluginClass selectorsAndMethodsDo:
		[:selector :method|
		(self mapCCodeToSmalltalkIn: method)
			ifNotNil: [:edit| transformations at: selector put: edit]
			ifNil: [((method sendsSelector: #cCode:) or: [method sendsSelector: #cCode:inSmalltalk:]) ifTrue:
					[Transcript cr; show: 'mapCCodeToSmalltalkIn: failed to edit cCode:... in ', aPluginClass name, '>>', selector]]].
	transformations keys sort do:
		[:selector|
		[:code :messages|
		(aPluginClass compile: code notifying: nil)
			ifNil: [Transcript cr; show: 'Failed to compile mapCCodeToSmalltalkIn: transformation for ', aPluginClass name, '>>', selector]
			ifNotNil:
				[(aPluginClass allSubclasses select: [:sc| sc name endsWith: 'Simulator']) do:
					[:sc|
					messages do:
						[:msg|
						(sc includesSelector: msg selector) ifFalse:
							[sc compile: msg createStubMethod classified: 'simulation']]]]]
			valueWithArguments: (transformations at: selector)]
]

{ #category : #'plugin scripts' }
CogScripts class >> mapCCodeToSmalltalkIn: aMethod [
	"Answer new source code for aMethod where cCode: strings have been mapped to the new foo: arg1 _: arg2
	 format and any inSmalltalk: code is included in a trailing comment."
	| methodNode edits text |
	methodNode := aMethod methodNode.
	edits := Dictionary new.
	methodNode block nodesDo:
		[:n| | cCode |
		(n isMessage
		 and: [(#(cCode: cCode:inSmalltalk:) includes: n selector key)
		 and: [(cCode := n arguments first value key) isString
		 and: [cCode notEmpty]]]) ifTrue:
			[| argVec |
			argVec := self processedCCodeCallFor: cCode.
			edits at: (methodNode encoder sourceRangeFor: n)
				put: (String streamContents:
						[:s| | first |
						argVec size > 2 ifTrue:
							[s nextPutAll: 'cCoerce: (self '].
						s nextPutAll: argVec first.
						argVec size > 1 ifTrue:
							[first := true.
							 argVec second do:
								[:thing| | param |
								thing ~~ #, ifTrue:
									[s nextPutAll: (first
													ifTrue: [': ']
													ifFalse: [' _: ']).
									 first := false.
									 param := thing isArray
												ifTrue: [s nextPutAll: '(self cCoerce: '. thing first]
												ifFalse: [thing].
									(methodNode encoder lookupVariable: param ifAbsent: [])
										ifNotNil: [s nextPutAll: param]
										ifNil: [s store: param]].
									thing isArray ifTrue:
										[(self printTypeFor: thing last on: s) ifFalse:
											[^nil].
										 s nextPut: $)]]].
						argVec size > 2 ifTrue:
							[s nextPut: $).
							 (self printTypeFor: argVec last on: s) ifFalse:
								[^nil]].
						#cCode:inSmalltalk: == n selector key ifTrue:
							[| r |
							 r := methodNode encoder sourceRangeFor: n arguments last.
							 s space; nextPutAll: ' "inSmalltalk: '; nextPutAll: (methodNode sourceText copyFrom: r first to: r last); nextPut: $"]])]].
	edits ifEmpty: [^nil].
	text := methodNode sourceText asString.
	(edits keys asSortedCollection: [:a :b| a first > b first]) do:
		[:range|
		text := text copyReplaceFrom: range first to: range last with: (edits at: range)].
	^{ text.
		(edits collect:
			[:string| | selectorString index |
			selectorString := (string beginsWith: 'cCoerce:') ifTrue: [string allButFirst: 10] ifFalse: [string].
			(index := selectorString indexOfSubCollection: '"inSmalltalk') > 0 ifTrue:
				[selectorString := selectorString first: index - 1].
			(selectorString occurrencesOf: $)) > (selectorString occurrencesOf: $() ifTrue:
				[selectorString := selectorString first: (selectorString lastIndexOf: $)) - 1].
			(selectorString beginsWith: 'self') ifTrue:
				[selectorString := selectorString allButFirst: 4].
			selectorString := selectorString extractSelector.
			Message
				selector: selectorString asSymbol
				arguments: (1 to: selectorString numArgs) asArray]) }
]

{ #category : #'plugin scripts' }
CogScripts class >> printTypeFor: anArray on: aWriteStream [
	| type |
	type := String streamContents:
				[:s|
				anArray
					do: [:ea| [s nextPutAll: ea] on: Error do: [:ex| ^false]]
					separatedBy: [s space]].
	aWriteStream nextPutAll: ' to: '; store: type asSymbol.
	^true
]

{ #category : #'plugin scripts' }
CogScripts class >> processedCCodeCallFor: aCCodeString [
	"Take a cCode: string containing a C call and answer a literal array encoding the parameter
	 list with any casts moved to the back, for ease of generating self cCoerce: thing to: type.

		'func(a,b)'		=> #(func #(a b))
		'(type)func()'	=> #(func #() #(type))
		'func((type)a)')	=> #(func #(#(a #(type))))) 
	"
	| argVec parameterList |
	argVec := Compiler evaluate: '#(', (aCCodeString copyReplaceAll: $" asString with: $' asString), ')'.
	[argVec size > 2 and: [argVec last == #';']] whileTrue: [argVec := argVec allButLast].
	argVec last notEmpty ifTrue:
		[parameterList := (argVec last splitBy: #(#,)) collect: [:p| p size > 1 ifTrue: [{p last. p first}] ifFalse: [p first]].
		 argVec at: argVec size put: parameterList].
	^argVec first isArray
		ifTrue: [argVec allButFirst, {argVec first}]
		ifFalse: [argVec]
]

{ #category : #'separate vm scripts' }
CogScripts class >> readOnlyVars [
	^#(#checkForLeaks #fullGCLock #gcStartUsecs #memoryLimit #scavengeThreshold #youngStart
		#statCompMoveCount #statFullGCUsecs #statFullGCs #statGCEndUsecs #statGrowMemory #statIGCDeltaUsecs
		#statIncrGCUsecs #statIncrGCs #statMarkCount #statMkFwdCount #statRootTableCount #statRootTableOverflows
		#statShrinkMemory #statSpecialMarkCount #statSurvivorCount #statSweepCount #statTenures)
]

{ #category : #'separate vm scripts' }
CogScripts class >> readWriteVars [
	^#(#specialObjectsOop
		#edenBytes #endOfMemory #forceTenureFlag #freeStart #needGCFlag
		#gcBiasToGrow #gcBiasToGrowGCLimit #gcBiasToGrowThreshold
		#growHeadroom #lastHash #lowSpaceThreshold #memory
		#remapBuffer #remapBufferCount #rootTable #rootTableCount
		#signalLowSpace #shrinkThreshold tenuringThreshold)
]

{ #category : #documentation }
CogScripts class >> refactoringPackages [
	"to use the source editing facilities in the refactoring browser that this class uses load
		AST-Core
		AST-Semantic
		Refactoring-Core
		Refactoring-Environment
		Refactoring-Changes
	in that order from http://www.squeaksource.com/rb.  Relevant tests are
		AST-Tests-Core
		AST-Tests-Semantic
		Refactoring-Tests-Core
		Refactoring-Tests-Environment
		Refactoring-Tests-Changes"
]

{ #category : #'look on class side' }
CogScripts >> seeClassSide [
	"All the code is on the class side"
]
