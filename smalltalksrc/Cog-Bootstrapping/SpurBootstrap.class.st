"
SpurBootstrap bootstraps an image in SpurMemoryManager format from a Squeak V3 + closures format.

e.g.
	(SpurBootstrap32 new on: '/Users/eliot/Cog/startreader.image')
		transform;
		launch

Instance Variables
	classToIndex:			<Dictionary>
	lastClassTablePage:	<Integer>
	map:					<Dictionary>
	methodClasses:		<Set>
	newHeap:				<SpurMemoryManager>
	oldHeap:				<NewObjectMemory>
	oldInterpreter:			<StackInterpreterSimulator>
	reverseMap:			<Dictionary>
	symbolMap:				<Dictionary>

classToIndex
	- oldClass to new classIndex map

lastClassTablePage
	- oop in newHeap of last classTable page.  U<sed in validation to filter-out class table.

methodClasses
	- cache of methodClassAssociations for classes in which modified methods are installed

map
	- oldObject to newObject map

newHeap
	- the output, bootstrapped image

oldHeap
	- the input, image

oldInterpreter
	- the interpreter associated with oldHeap, needed for a hack to grab WeakArray

reverseMap
	- newObject to oldObject map

symbolMap
	- symbol toi symbol oop in oldHeap, used to map prototype methdos to methods in oldHeap
"
Class {
	#name : #SpurBootstrap,
	#superclass : #Object,
	#instVars : [
		'oldHeap',
		'newHeap',
		'map',
		'reverseMap',
		'classToIndex',
		'oldInterpreter',
		'lastClassTablePage',
		'symbolMap',
		'methodClasses',
		'installedPrototypes'
	],
	#pools : [
		'VMObjectIndices'
	],
	#category : #'Cog-Bootstrapping'
}

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEbasicNew [
	"Primitive. Answer an instance of the receiver (which is a class) with no 
	 indexable variables. Fail if the class is indexable. Essential. See Object 
	 documentation whatIsAPrimitive.
	
	 If the primitive fails because space is low then the scavenger
	 will run before the method is activated.  Check arguments and
	 retry via failingBasicNew: if they're OK."

	<primitive: 70>
	self isVariable ifTrue: [^self basicNew: 0].
	"space must have been low, and the scavenger must have run.
	 retry after the scavenge."
	^self failingBasicNew
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEbasicNew: sizeRequested [ 
	"Primitive. Answer an instance of this class with the number of indexable
	 variables specified by the argument, sizeRequested.  Fail if this class is not
	 indexable or if the argument is not a positive Integer, or if there is not
	 enough memory available. Essential. See Object documentation whatIsAPrimitive.
	
	 If the primitive fails because space is low then the scavenger will run before the
	 method is activated.  Check arguments and retry via failingBasicNew: if they're OK."

	<primitive: 71>
	self isVariable ifFalse:
		[self error: self printString, ' cannot have variable sized instances'].
	(sizeRequested isInteger and: [sizeRequested >= 0]) ifTrue:
		["arg okay; space must have been low, and the scavenger must have run.
		  retry after the scavenge"
		^self failingBasicNew: sizeRequested].
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEhandleFailingBasicNew [
	"This basicNew gets sent after basicNew has failed and allowed a
	 scavenging garbage collection to occur.  The scavenging collection
	 will have happened as the VM is activating the (failing) basicNew.
	 If failingBasicNew fails then the scavenge failed to reclaim sufficient
	 space and a global garbage collection is required.

	 Primitive. Answer an instance of this class with the number of indexable
	 variables specified by the argument, sizeRequested.  Fail if this class is not
	 indexable or if the argument is not a positive Integer, or if there is not
	 enough memory available. Essential. See Object documentation whatIsAPrimitive."

	<primitive: 70>
	self isVariable ifTrue: [^self basicNew: 0].
	Smalltalk garbageCollect.
	^self failingFailingBasicNew "retry after global garbage collect"
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEhandleFailingBasicNew: sizeRequested [
	"This basicNew: gets sent after basicNew: has failed and allowed a
	 scavenging garbage collection to occur.  The scavenging collection
	 will have happened as the VM is activating the (failing) basicNew:.
	 If failingBasicNew: fails then the scavenge failed to reclaim sufficient
	 space and a global garbage collection is required.

	 Primitive. Answer an instance of this class with the number of indexable
	 variables specified by the argument, sizeRequested.  Fail if this class is not
	 indexable or if the argument is not a positive Integer, or if there is not
	 enough memory available. Essential. See Object documentation whatIsAPrimitive."

	<primitive: 71>
	self isVariable ifFalse:
		[self error: self printString, ' cannot have variable sized instances'].
	(sizeRequested isInteger and: [sizeRequested >= 0]) ifTrue:
		[Smalltalk garbageCollect.
		^self failingFailingBasicNew: sizeRequested  "retry after global garbage collect"].
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEhandleFailingFailingBasicNew [
	"This basicNew gets sent after failingBasicNew: has sent Smalltalk garbageCollect.
	 If this fails then the system really is low on space.

	 Primitive. Answer an instance of this class with the number of indexable
	 variables specified by the argument, sizeRequested.  Fail if this class is not
	 indexable or if the argument is not a positive Integer, or if there is not
	 enough memory available. Essential. See Object documentation whatIsAPrimitive."

	<primitive: 70>
	self isVariable ifTrue: [^self basicNew: 0].
	"space must be low"
	OutOfMemory signal.
	^self basicNew  "retry if user proceeds"
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEhandleFailingFailingBasicNew: sizeRequested [
	"This basicNew: gets sent after failingBasicNew: has sent Smalltalk garbageCollect.
	 If that fails the system really is low on space.

	 Primitive. Answer an instance of this class with the number of indexable
	 variables specified by the argument, sizeRequested.  Fail if this class is not
	 indexable or if the argument is not a positive Integer, or if there is not
	 enough memory available. Essential. See Object documentation whatIsAPrimitive."

	<primitive: 71>
	self isVariable ifFalse:
		[self error: self printString, ' cannot have variable sized instances'].
	(sizeRequested isInteger and: [sizeRequested >= 0]) ifTrue:
		["arg okay; space must be low."
		OutOfMemory signal.
		^self basicNew: sizeRequested  "retry if user proceeds"].
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEidentityHash [
	"Answer a SmallInteger whose value is related to the receiver's identity.
	This method must not be overridden.
	Primitive. Fails if the receiver is not a Behavior. Essential.
	See Object documentation whatIsAPrimitive.

	Do not override."

	<primitive: 175>
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEinstSize [
	"Answer the number of named instance variables
	(as opposed to indexed variables) of the receiver.
	 Above Cog Spur the class format is
		<5 bits inst spec><16 bits inst size>"
	^format bitAnd: 16rFFFF
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEisBits [
	"Answer whether the receiver contains just bits (not pointers).
	 Above Cog Spur the class format is
		<5 bits inst spec><16 bits inst size>
	 where the 5-bit inst spec is
		 0 = 0 sized objects (UndefinedObject True False et al)
		 1 = non-indexable objects with inst vars (Point et al)
		 2 = indexable objects with no inst vars (Array et al)
		 3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
		 4 = weak indexable objects with inst vars (WeakArray et al)
		 5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
		 6,7,8 unused
		 9 (?) 64-bit indexable
		 10 - 11 32-bit indexable
		 12 - 15 16-bit indexable
		 16 - 23 byte indexable
		 24 - 31 compiled method"
	^self instSpec >= 9
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEisBytes [
	"Answer whether the receiver has 8-bit instance variables.
	 Above Cog Spur the class format is
		<5 bits inst spec><16 bits inst size>
	 where the 5-bit inst spec is
		 0 = 0 sized objects (UndefinedObject True False et al)
		 1 = non-indexable objects with inst vars (Point et al)
		 2 = indexable objects with no inst vars (Array et al)
		 3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
		 4 = weak indexable objects with inst vars (WeakArray et al)
		 5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
		 6,7,8 unused
		 9 (?) 64-bit indexable
		 10 - 11 32-bit indexable
		 12 - 15 16-bit indexable
		 16 - 23 byte indexable
		 24 - 31 compiled method"
	^self instSpec >= 16
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEisVariable [
	"Answer whether the receiver has indexable variables.
	 Above Cog Spur the class format is
		<5 bits inst spec><16 bits inst size>
	 where the 5-bit inst spec is
		 0 = 0 sized objects (UndefinedObject True False et al)
		 1 = non-indexable objects with inst vars (Point et al)
		 2 = indexable objects with no inst vars (Array et al)
		 3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
		 4 = weak indexable objects with inst vars (WeakArray et al)
		 5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
		 6,7,8 unused
		 9 (?) 64-bit indexable
		 10 - 11 32-bit indexable
		 12 - 15 16-bit indexable
		 16 - 23 byte indexable
		 24 - 31 compiled method"
	| instSpec |
	instSpec := self instSpec.
	^instSpec >= 2 and: [instSpec ~= 5]
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CharacterPROTOTYPEasInteger [
	<primitive: 171>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CharacterPROTOTYPEasciiValue [
	<primitive: 171>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CharacterclassPROTOTYPEvalue: anInteger [
	<primitive: 170>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> ClassBuilderPROTOTYPEformat: nInstVars variable: isVar words: isWords pointers: isPointers weak: isWeak [
	"Compute the format for the given instance specfication.
	 Above Cog Spur the class format is
		<5 bits inst spec><16 bits inst size>
	 where the 5-bit inst spec is
		 0 = 0 sized objects (UndefinedObject True False et al)
		 1 = non-indexable objects with inst vars (Point et al)
		 2 = indexable objects with no inst vars (Array et al)
		 3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
		 4 = weak indexable objects with inst vars (WeakArray et al)
		 5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
		 6,7,8 unused
		 9 (?) 64-bit indexable
		 10 - 11 32-bit indexable
		 12 - 15 16-bit indexable
		 16 - 23 byte indexable
		 24 - 31 compiled method"
	| instSpec |
	instSpec := isWeak
					ifTrue: [4]
					ifFalse:
						[isPointers
							ifTrue:
								[isVar
									ifTrue: [nInstVars > 0 ifTrue: [3] ifFalse: [2]]
									ifFalse: [nInstVars > 0 ifTrue: [1] ifFalse: [0]]]
							ifFalse: [isWords ifTrue: [12] ifFalse: [16]]].
	^(instSpec bitShift: 16) + nInstVars
]

{ #category : #'method prototypes' }
SpurBootstrap class >> ProtoObjectPROTOTYPEscaledIdentityHash [
	"For identityHash values returned by primitive 75, answer
	 such values times 2^8.  Otherwise, match the existing
	 identityHash implementation"

	^self identityHash * 256 "bitShift: 8"
]

{ #category : #'method prototypes' }
SpurBootstrap class >> SmallIntegerPROTOTYPEasCharacter [
	<primitive: 170>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> SmalltalkImagePROTOTYPEmaxIdentityHash [
	"Answer the maximum identityHash value supported by the VM."
	<primitive: 176>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> SystemDictionaryPROTOTYPEmaxIdentityHash [
	"Answer the maximum identityHash value supported by the VM."
	<primitive: 176>
	^self primitiveFailed
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> addNewMethods [
	"Get the simulator to add any and all missing methods immediately."
	| cmaiaSym basSym |
	cmaiaSym := self findSymbol: #compiledMethodAt:ifAbsent:.
	basSym := self findSymbol: #basicAddSelector:withMethod:.
	basSym ifNil:
		[basSym := self findSymbol: #addSelectorSilently:withMethod:].
	self allPrototypeClassNamesDo:
		[:sym :symIsMeta| | class |
		class := self findClassNamed: (symbolMap at: sym).
		symIsMeta ifTrue: [class := oldHeap fetchClassOfNonImm: class].
		self prototypeClassNameMetaSelectorMethodDo:
			[:className :isMeta :selector :method| | methodOrNil |
			(className = sym
			 and: [symIsMeta = isMeta]) ifTrue:
				["probe method dictionary of the class for each method, installing a dummy if not found."
				 "Transcript cr; nextPutAll: 'checking for '; nextPutAll: selector; flush."
				 methodOrNil := self interpreterObject: class
									perform: cmaiaSym
									withArguments: {symbolMap at: selector. oldHeap nilObject}.
				 methodOrNil = oldHeap nilObject
					ifTrue: "no method.  install the real thing now"
						[Transcript
							cr;
							nextPutAll: 'installing ';
							nextPutAll: className;
							nextPutAll: (isMeta ifTrue: [' class>>'] ifFalse: ['>>']);
							store: selector;
							flush.
						 self interpreterObject: class
							perform: basSym
							withArguments: { symbolMap at: selector.
											   self installableMethodFor: method
												selector: selector
												className: className
												isMeta: isMeta}.
						installedPrototypes add: method selector]
					ifFalse: "existing method; collect the methodClassAssociation; its needed later"
						[methodClasses add: (oldInterpreter methodClassAssociationOf: methodOrNil)]]]]
]

{ #category : #'method prototypes' }
SpurBootstrap >> allPrototypeClassNamesDo: aBlock [
	"self basicNew allPrototypeClassNames"
	| pairs |
	pairs := Set new.
	self prototypeClassNameMetaSelectorMethodDo:
		[:className :isMeta :selector :method |
		pairs add: {className. isMeta}].
	pairs do: [:pair| aBlock value: pair first value: pair last]
]

{ #category : #'method prototypes' }
SpurBootstrap >> allPrototypeMethodSymbols [
	"self basicNew allPrototypeMethodSymbols"
	| symbols |
	symbols := Set new.
	self prototypeClassNameMetaSelectorMethodDo:
		[:className :isMeta :selector :method |
		symbols
			add: className;
			add: selector;
			addAll: (method literals select: [:l| l isSymbol and: [l ~~ method selector]])].
	^symbols
]

{ #category : #'bootstrap image' }
SpurBootstrap >> allocateClassTable [
	"Allocate the root of the classTable plus enough pages to accomodate all classes in
	 the classToIndex map.  Don't fill in the entries yet; the classes have yet to be cloned."
	| tableRootSize tableRoot page maxSize numPages |
	tableRootSize := self classTableSize / newHeap classTablePageSize.
	tableRoot := newHeap
					allocateSlots: tableRootSize
					format: newHeap arrayFormat
					classIndex: newHeap arrayClassIndexPun.
	self assert: (newHeap numSlotsOf: tableRoot) = tableRootSize.
	self assert: (newHeap formatOf: tableRoot) = newHeap arrayFormat.
	self assert: (newHeap classIndexOf: tableRoot) = newHeap arrayClassIndexPun.
	newHeap nilFieldsOf: tableRoot.
	"first page is strong"
	page := newHeap
					allocateSlots: newHeap classTablePageSize
					format: newHeap arrayFormat
					classIndex: newHeap arrayClassIndexPun.
	self assert: (newHeap numSlotsOf: page) = newHeap classTablePageSize.
	self assert: (newHeap formatOf: tableRoot) = newHeap arrayFormat.
	self assert: (newHeap classIndexOf: tableRoot) = newHeap arrayClassIndexPun.
	self assert: (newHeap objectAfter: tableRoot limit: newHeap freeStart) = page.
	lastClassTablePage := page.
	newHeap nilFieldsOf: page.
	newHeap storePointer: 0 ofObject: tableRoot withValue: page.
	newHeap classTableRootObj: tableRoot.
	maxSize := classToIndex inject: 0 into: [:a :b| a max: b].
	numPages := (maxSize + newHeap classTableMinorIndexMask / newHeap classTablePageSize) truncated.
	2 to: numPages do:
		[:i|
		page := newHeap
					allocateSlots: newHeap classTablePageSize
					format: newHeap weakArrayFormat
					classIndex: newHeap weakArrayClassIndexPun.
		self assert: (newHeap numSlotsOf: page) = newHeap classTablePageSize.
		self assert: (newHeap formatOf: page) = newHeap weakArrayFormat.
		self assert: (newHeap classIndexOf: page) = newHeap weakArrayClassIndexPun.
		newHeap nilFieldsOf: page.
		newHeap storePointer: i - 1 ofObject: tableRoot withValue: page.
		self assert: (newHeap objectAfter: (newHeap fetchPointer: i - 2 ofObject: tableRoot)  limit: newHeap freeStart) = page.
		lastClassTablePage := page]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> bootstrapImage [
	Transcript cr; nextPutAll: 'transforming image'; flush.
	self cloneNilTrueAndFalse.
	self buildClassMap.
	self allocateClassTable.
	self cloneObjects.
	self fillInObjects.
	self fillInClassTable
]

{ #category : #'bootstrap image' }
SpurBootstrap >> buildClassMap [
	"enumerate all objects asking isBehavior:?  (class == Metaclass or class class == Metaclass) doesn't work for Newspeak"
	"Build a map from all classes in oldHeap to a class index.
	 ONLY DEALS WITH CLASSES THAT HAVE INSTANCES!! (can walk superclass chain?  Can walk subclasses set? Can ask class == Metaclass or class class == Metaclass class?)"
	| classes classTableIndex |
	self defineKnownClassIndices.
	classes := classToIndex keys asSet.
	classTableIndex := classToIndex inject: 0 into: [:a :b| a max: b].
	oldHeap allObjectsDo:
		[:oldObj| | oldClass |
		 oldClass := oldHeap fetchClassOfNonImm: oldObj.
		 self assert: (oldHeap isPointersNonImm: oldClass).
		 (classes includes: oldClass) ifFalse:
			[classes add: oldClass.
			 classToIndex at: oldClass put: (classTableIndex := classTableIndex + 1)]]
]

{ #category : #'method prototypes' }
SpurBootstrap >> classNameForPrototypeMethod: protoMethod [
	| protoSelector |
	protoSelector := protoMethod selector.
	^(protoSelector first: (protoSelector indexOfSubCollection: 'PROTOTYPE') - 1) asSymbol
]

{ #category : #'class indices' }
SpurBootstrap >> classTableSize [
	^newHeap classIndexMask + 1
]

{ #category : #'bootstrap image' }
SpurBootstrap >> clone: oldObj classIndex: classIndex [
	| newObj |
	newObj := newHeap
				allocateSlots: (oldHeap fetchWordLengthOf: oldObj)
				format: (self newFormatFor: oldObj)
				classIndex: classIndex.
	reverseMap at: newObj put: oldObj.
	^map at: oldObj put: newObj
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> cloneMethodProxy: proxy [ "<VMCompiledMethodProxy>"
	| bytes newMethod |
	bytes := proxy size - proxy initialPC + 1.
	newMethod := CompiledMethod
						newMethod: bytes
						header: proxy header.
	false
		ifTrue:
			[1 to: proxy numLiterals - 2 do:
				[:i| | literal |
				literal := (proxy literalAt: i) oop.
				literal := (oldHeap isIntegerObject: literal)
							ifTrue: [oldHeap integerValueOf: literal]
							ifFalse: ['literal', i printString].
				newMethod literalAt: i put: literal].
			newMethod
				literalAt: proxy numLiterals - 1
					put: (oldHeap stringOf: (proxy literalAt: proxy numLiterals - 1) oop) asSymbol;
				literalAt: proxy numLiterals
					put: (Smalltalk bindingOf: #Character)]
		ifFalse:
			[1 to: proxy numLiterals - 1 do:
				[:i| newMethod literalAt: i put: (proxy literalAt: i)].
			newMethod
				literalAt: proxy numLiterals
				put: (Smalltalk bindingOf: #Character)].
	proxy initialPC to: proxy size do:
		[:i| newMethod at: i put: (proxy at: i)].
	^newMethod
]

{ #category : #'bootstrap image' }
SpurBootstrap >> cloneNilTrueAndFalse [
	{	oldHeap nilObject.
		oldHeap falseObject.
		oldHeap trueObject. }
		with: (self firstOrdinaryClassIndex to: self firstOrdinaryClassIndex + 2)
		do: [:obj :classIndex|
			classToIndex at: (oldHeap fetchClassOfNonImm: obj) put: classIndex.
			self clone: obj classIndex: classIndex].
	newHeap
		nilObject: (map at: oldHeap nilObject); "needed for nilling objects etc"
		falseObject: (map at: oldHeap falseObject);
		trueObject: (map at: oldHeap trueObject)
]

{ #category : #'bootstrap image' }
SpurBootstrap >> cloneObjects [
	| characterClass characterTable oldObj oldClass |
	characterClass := oldHeap classCharacter.
	characterTable := oldHeap characterTable.
	oldObj := oldHeap objectAfter: oldHeap trueObject.
	[oldObj < oldHeap freeStart] whileTrue:
		[oldClass := oldHeap fetchClassOfNonImm: oldObj.
		 (oldObj ~= characterTable
		 and: [oldClass ~= characterClass]) ifTrue:
			[self clone: oldObj classIndex: (classToIndex at: oldClass)].
		 oldObj := oldHeap objectAfter: oldObj].
	newHeap specialObjectsOop: (map at: oldHeap specialObjectsOop)
]

{ #category : #'class indices' }
SpurBootstrap >> defineKnownClassIndices [
	"The classTable is laid out
		- to make it easy to map immediates to classes; the tag pattern of an immediate is its class index.
		  hence there are two entries for SmallInteger
		- to assign small indices to well-known classes such as Array, Message et al
		- to leave plenty of room for new known classes; hence the first page contains only well-known classes
		- to enable overlaps and avoid conflicts with indices in the specialObjectsArray (?really? eem)
		- to provide a WeakArray pun for the pages of the table itself so that these do not show up as instances of WeakArray"
	| classMethodContext classBlockClosure classMessage "no api method for these" |
	classMessage := oldHeap splObj: (VMObjectIndices bindingOf: #ClassMessage) value.
	classMethodContext := oldHeap splObj: (VMObjectIndices bindingOf: #ClassMethodContext) value.
	classBlockClosure := oldHeap splObj: (VMObjectIndices bindingOf: #ClassBlockClosure) value.
	"c.f. CogMemoryManager class>>intializeCompactClassIndices".
	classToIndex keysDo:
		[:oldClass|
		self assert: (oldInterpreter addressCouldBeClassObj: oldClass)].
	classToIndex
		at: oldHeap classSmallInteger put: 1; "N.B. must fill-in index 3 manually"
		at: oldHeap classCharacter put: 2;
		"at: oldHeap classSmallInteger put: 3" "N.B. must fill-in index 3 manually"
		"leave room for up to 15 tagged classes"
		"leave room for up to 16 puns"
		at: oldHeap classLargeNegativeInteger put: 32;
		at: oldHeap classLargePositiveInteger put: 33;
		at: oldHeap classFloat put: 34;

		at: "oldHeap" classMessage put: 35;
		at: "oldHeap" classMethodContext put: 36;
		at: "oldHeap" classBlockClosure put: 37;

		at: oldHeap classSemaphore put: 48;
		at: oldHeap classMutex put: 49;

		at: oldHeap classByteArray put: 50;
		at: oldHeap classArray put: 51;
		at: oldHeap classString put: 52;
		at: oldHeap classBitmap put: 53;
		at: oldHeap classPoint put: 54;

		at: oldHeap classExternalAddress put: 128;
		at: oldHeap classExternalData put: 129;
		at: oldHeap classExternalFunction put: 130;
		at: oldHeap classExternalLibrary put: 131;
		at: oldHeap classExternalStructure put: 132;
		at: oldHeap classAlien put: 133;
		at: oldHeap classUnsafeAlien put: 134.
	classToIndex keysDo:
		[:oldClass|
		self assert: (oldInterpreter addressCouldBeClassObj: oldClass)]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> fillInClassTable [
	| firstPage classWeakArray |
	classToIndex keysAndValuesDo:
		[:oldClass :index| | newClass page |
		newClass := map at: oldClass.
		self assert: (newHeap isPointersNonImm: newClass).
		newHeap setHashBitsOf: newClass to: index.
		page := newHeap
					fetchPointer: index >> newHeap classTableMajorIndexShift
					ofObject: newHeap classTableRootObj.
		newHeap
			storePointer: (index bitAnd: newHeap classTableMinorIndexMask)
			ofObject: page
			withValue: newClass.
		self assert: (newHeap classAtIndex: index) = newClass].
	firstPage := newHeap
					fetchPointer: 0
					ofObject: newHeap classTableRootObj.
	classWeakArray := classToIndex keys detect:
							[:oldClass|
							(oldHeap instSpecOfClass: oldClass) = 4
							and: [oldInterpreter classNameOf: oldClass Is: 'WeakArray']].
	newHeap
		storePointer: 1
			ofObject: firstPage
				withValue: (map at: oldHeap classSmallInteger);
		storePointer: 2
			ofObject: firstPage
				withValue: (map at: oldHeap classCharacter);
		storePointer: 3
			ofObject: firstPage
				withValue: (map at: oldHeap classSmallInteger);
		storePointer: newHeap arrayClassIndexPun
			ofObject: firstPage
				withValue: (map at: oldHeap classArray);
		storePointer: newHeap weakArrayClassIndexPun
			ofObject: firstPage
				withValue: (map at: classWeakArray)
]

{ #category : #'bootstrap image' }
SpurBootstrap >> fillInCompiledMethod: newObj from: oldObj [
	self fillInBitsObject: newObj from: oldObj.
	self fillInPointerObject: newObj from: oldObj
]

{ #category : #'bootstrap image' }
SpurBootstrap >> fillInObjects [
	oldHeap allObjectsDo:
		[:oldObj|
		(map at: oldObj ifAbsent: nil) ifNotNil:
			[:newObj|
			(newHeap isCompiledMethod: newObj)
				ifTrue: [self fillInCompiledMethod: newObj from: oldObj]
				ifFalse:
					[(newHeap isPointersNonImm: newObj)
						ifTrue: [self fillInPointerObject: newObj from: oldObj]
						ifFalse: [self fillInBitsObject: newObj from: oldObj]]]]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> fillInPointerObject: newObj from: oldObj [
	0 to: (oldHeap lastPointerOf: oldObj) / oldHeap bytesPerWord - 1 do:
		[:i| | oldValue newValue |
		oldValue := oldHeap fetchPointer: i ofObject: oldObj.
		newValue := (oldHeap isIntegerObject: oldValue)
						ifTrue: [oldValue]
						ifFalse:
							[map at: oldValue ifAbsent:
								[oldValue = oldHeap characterTable
									ifTrue: [newHeap nilObject]
									ifFalse:
										[self assert: (oldHeap fetchClassOfNonImm: oldValue) = oldHeap classCharacter.
										 newHeap characterObjectOf:
											(oldHeap integerValueOf:
												(oldHeap fetchPointer: CharacterValueIndex ofObject: oldValue))]]].
		newHeap
			storePointerUnchecked: i
			ofObject: newObj
			withValue: newValue].
	(classToIndex includesKey: oldObj) ifTrue:
		[newHeap
			storePointerUnchecked: InstanceSpecificationIndex
			ofObject: newObj
			withValue: (self newClassFormatFor: oldObj)]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> findClassNamed: symbolOop [ 
	oldHeap allObjectsDo:
		[:o|
		((oldHeap isPointersNonImm: o)
		 and: [(oldInterpreter addressCouldBeClassObj: o)
		 and: [(oldHeap fetchPointer: oldInterpreter classNameIndex ofObject: o) = symbolOop]]) ifTrue:
			[^o]].
	^nil
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> findLiteral: aLiteral [
	| symbolOop smalltalk array |
	aLiteral isString ifTrue:
		[^self stringFor: aLiteral].
	self assert: aLiteral isVariableBinding.
	symbolOop := self findSymbol: aLiteral key.
	smalltalk := oldHeap splObj: 8.
	array := oldHeap fetchPointer: 1 ofObject: smalltalk.
	self assert: (oldHeap isArray: array).
	0 to: (oldHeap fetchWordLengthOf: array) - 1 do:
		[:i| | bindingOrNil |
		bindingOrNil := oldHeap fetchPointer: i ofObject: array.
		(bindingOrNil ~= oldHeap nilObject
		 and: [symbolOop = (oldHeap fetchPointer: KeyIndex ofObject: bindingOrNil)
		 and: [aLiteral key == #Smalltalk
				ifTrue:
					[(oldHeap fetchPointer: ValueIndex ofObject: bindingOrNil) = smalltalk]
				ifFalse:
					[oldInterpreter
						classNameOf: (oldHeap fetchPointer: ValueIndex ofObject: bindingOrNil)
						Is: aLiteral key]]]) ifTrue:
			[^bindingOrNil]].
	self error: 'couldn''t find literal ', aLiteral printString
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> findSymbol: aString [
	"Find the Symbol equal to aString in oldHeap."
	| symbolClass |
	symbolClass := self symbolClass.
	oldHeap allObjectsDo:
		[:o|
		(symbolClass = (oldHeap fetchClassOfNonImm: o)
		 and: [(oldHeap byteLengthOf: o) = aString size
		 and: [aString = (oldHeap stringOf: o)]]) ifTrue:
			[^o]].
	^nil
]

{ #category : #'class indices' }
SpurBootstrap >> firstOrdinaryClassIndex [
	^newHeap classTablePageSize
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> indexOfSelector: selectorOop in: methodDict [
	SelectorStart to: (oldHeap fetchWordLengthOf: methodDict) - 1 do:
		[:i|
		(oldHeap fetchPointer: i ofObject: methodDict) = selectorOop ifTrue:
			[^i]].
	self error: 'could not find selector in method dict'
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> installModifiedMethods [
	"Install all the methods in the class-side method prototypes protocol in the relevant classes
	 in the new image.  First use the simulator to get the image to intern all symbols and add
	 dummy methods under new selectors.  With that done we can manually replace the relevant
	 methods with the prototypes, mapping selectors and global variables as required."
	symbolMap := Dictionary new.
	methodClasses := Set new.
	installedPrototypes := Set new.
	self withExecutableInterpreterDo:
		[self internAllSymbols.
		 self addNewMethods.
		 self replaceMethods].
	self modifyCharacterMethods
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> installableMethodFor: aCompiledMethod selector: selector className: className isMeta: isMeta [
	| compiledMethodClass sourcelessMethod bytes newMethod methodClass |
	compiledMethodClass := self findClassNamed: (self findSymbol: #CompiledMethod).
	"the prototypes hve source pointers.  the Character methods to be replaced don't."
	sourcelessMethod := aCompiledMethod trailer hasSourcePointer
							ifTrue: [aCompiledMethod copyWithTempsFromMethodNode: aCompiledMethod methodNode]
							ifFalse: [aCompiledMethod].
	bytes := sourcelessMethod size - sourcelessMethod initialPC + 1.
	newMethod := self
					interpreterObject: compiledMethodClass
					perform: (self findSymbol: #newMethod:header:)
					withArguments: { oldHeap integerObjectOf: bytes.
									   oldHeap integerObjectOf: sourcelessMethod header }.
	1 to: sourcelessMethod numLiterals - 1 do:
		[:i| | literal oop |
		literal := sourcelessMethod literalAt: i.
		literal isMethodProperties ifTrue:
			[literal := selector].
		oop := (literal isLiteral or: [literal isVariableBinding])
					ifTrue:
						[literal isInteger
							ifTrue: [oldHeap integerObjectOf: literal]
							ifFalse: [symbolMap at: literal ifAbsent: [self findLiteral: literal]]]
					ifFalse: "should be a VMObjectProxy"
						[literal oop].
		oldHeap storePointer: i ofObject: newMethod withValue: oop].
	methodClass := self methodClassForClassName: className isMeta: isMeta.
	oldHeap storePointer: sourcelessMethod numLiterals ofObject: newMethod withValue: methodClass.
	sourcelessMethod initialPC to: sourcelessMethod size do:
		[:i|
		oldHeap storeByte: i - 1 ofObject: newMethod withValue: (sourcelessMethod byteAt: i)].
	^newMethod
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> internAllSymbols [
	"Ensure that all symbols in the method prototypes are interned so that later we can install them.
	 Enter them into the map, this system's symbol -> oldHeap's version.
	 Do this by interpreting Symbol intern: 'aSymbol' for each symbol."
	| internSym |
	internSym := self findSymbol: #intern:.
	self allPrototypeMethodSymbols do:
		[:sym|
		(self findSymbol: sym)
			ifNotNil: [:imageSym| symbolMap at: sym put: imageSym]
			ifNil:[Transcript cr; nextPutAll: 'interning '; nextPutAll: sym; flush.
				"Interpret Symbol intern: sym to ... intern it :-)"
				symbolMap
					at: sym
					put: (self interpreterObject: self symbolClass
							perform: internSym
							withArguments: {self stringFor: sym})]].
	symbolMap keysAndValuesDo:
		[:sym :imageSym|
		self assert: sym = (oldHeap stringOf: imageSym)]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> interpreterObject: receiver perform: selector withArguments: arguments [
	"Interpret an expression in oldHeap using oldInterpreter.
	 Answer the result."
	| fp savedpc result |
	savedpc := oldInterpreter localIP.
	oldInterpreter internalPush: receiver.
	arguments do: [:arg| oldInterpreter internalPush: arg].
	oldInterpreter
		argumentCount: arguments size;
		messageSelector: selector.
	fp := oldInterpreter localFP.
	oldInterpreter normalSend.
	[fp = oldInterpreter localFP] whileFalse:
		[oldInterpreter singleStep].
	result := oldInterpreter internalPopStack.
	self assert: oldInterpreter localIP - 1 = savedpc.
	oldInterpreter localIP: savedpc.
	^result
]

{ #category : #testing }
SpurBootstrap >> launch [
	| sim |
	sim := StackInterpreterSimulator onObjectMemory: newHeap.
	newHeap coInterpreter: sim.
	sim initializeInterpreter: 0.
	sim
		ensureDebugAtEachStepBlock;
		instVarNamed: 'printBytecodeAtEachStep' put: true;
		instVarNamed: 'methodDictLinearSearchLimit' put: SmallInteger maxVal. "for now"
	sim run
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> methodClassForClassName: classNameSymbol isMeta: isMeta [ 
	| class |
	class := self findClassNamed: (symbolMap at: classNameSymbol).
	isMeta ifTrue: [class := oldHeap fetchClassOfNonImm: class].
	methodClasses do:
		[:mca|
		class = (oldHeap fetchPointer: ValueIndex ofObject: mca) ifTrue:
			[^mca]].
	oldHeap allObjectsDo:
		[:o| | methodClassAssociation |
		(oldHeap isCompiledMethod: o) ifTrue:
			[methodClassAssociation := oldInterpreter methodClassAssociationOf: o.
			 class == (oldHeap fetchPointer: ValueIndex ofObject: methodClassAssociation) ifTrue:
				[methodClasses add: methodClassAssociation.
				 ^methodClassAssociation]]].
	self error: 'could not find methodClassAssociation for ', classNameSymbol, (isMeta ifTrue: [' class'] ifFalse:[''])
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> modifyCharacterMethods [
	| cc md mda |
	cc := oldHeap classCharacter.
	md := oldHeap fetchPointer: MethodDictionaryIndex ofObject: cc.
	mda := oldHeap fetchPointer: MethodArrayIndex ofObject: md..
	0 to: (oldHeap fetchWordLengthOf: mda) - 1 do:
		[:i| | method |
		method := oldHeap fetchPointer: i ofObject: mda.
		method ~= oldHeap nilObject ifTrue:
			[(self replacementForCharacterMethod: method) ifNotNil:
				[:replacement|
				Transcript
					cr;
					nextPutAll: 'replacing Character>>#';
					nextPutAll: (oldHeap stringOf: (oldHeap fetchPointer: i + SelectorStart ofObject: md));
					flush. 
				oldHeap
					storePointer: i
					ofObject: mda
					withValue: replacement]]]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> newClassFormatFor: oldClassObj [
	"OLD: 		<2 bits=instSize//64><5 bits=cClass><4 bits=instSpec><6 bits=instSize\\64><1 bit=0>
	 NEW: 		<5 bits inst spec><16 bits inst size>"
	| oldFormat instSize newInstSpec |
	oldFormat := oldHeap formatOfClass: oldClassObj. "N.B. SmallInteger with tag bit cleared"
	oldFormat := oldFormat >> 1.
	instSize := ((oldFormat bitShift: -10) bitAnd: 16rC0) + ((oldFormat bitShift: -1) bitAnd: 16r3F) - 1.
	newInstSpec := #(0 1 2 3 4 5 6 7 16 16 16 16 24 24 24 24) at: ((oldFormat bitShift: -7) bitAnd: 16rF) + 1.
	^newHeap integerObjectOf: newInstSpec << 16 + instSize
]

{ #category : #'bootstrap image' }
SpurBootstrap >> newFormatFor: oldObj [
	"OLD:
	 0	no fields
	 1	fixed fields only (all containing pointers)
	 2	indexable fields only (all containing pointers)
	 3	both fixed and indexable fields (all containing pointers)
	 4	both fixed and indexable weak fields (all containing pointers).

	 5	unused
	 6	indexable word fields only (no pointers)
	 7	indexable long (64-bit) fields (only in 64-bit images)
 
	 8-11	indexable byte fields only (no pointers) (low 2 bits are low 2 bits of size)
	 12-15	compiled methods:
	 	    # of literal oops specified in method header,
	 	    followed by indexable bytes (same interpretation of low 2 bits as above)"

	"NEW:
	 0 = 0 sized objects (UndefinedObject True False et al)
	 1 = non-indexable objects with inst vars (Point et al)
	 2 = indexable objects with no inst vars (Array et al)
	 3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
	 4 = weak indexable objects with inst vars (WeakArray et al)
	 5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)

	 and here it gets messy, we need 8 CompiledMethod values, 8 byte values, 4 16-bit values, 2 32-bit values and a 64-bit value, = 23 values, 23 + 5 = 30, so there may be room.

	 9 (?) 64-bit indexable
	 10 - 11 32-bit indexable
	 12 - 15 16-bit indexable
	 16 - 23 byte indexable
	 24 - 31 compiled method"
	| oldFormat |
	oldFormat := oldHeap formatOf: oldObj.
	oldFormat <= 4 ifTrue:
		[^oldFormat].
	oldFormat >= 12 ifTrue: "CompiledMethod"
		[^24 + (self wordSize - (oldHeap byteLengthOf: oldObj) bitAnd: self wordSizeMask)].
	oldFormat >= 8 ifTrue: "ByteArray et al"
		[^16 + (self wordSize - (oldHeap byteLengthOf: oldObj) bitAnd: self wordSizeMask)].
	oldFormat = 6 ifTrue: "32-bit indexable"
		[^10 + ((oldHeap byteLengthOf: oldObj) bitAnd: self wordSizeMask) sign].
	oldFormat = 7 ifTrue: "64-bit indexable"
		[^9].
	self error: 'illegal old format'
]

{ #category : #'initialize-release' }
SpurBootstrap >> on: imageName [
	StackInterpreter initializeWithOptions: Dictionary new.
	oldInterpreter := StackInterpreterSimulator new.
	oldInterpreter openOn: imageName extraMemory: 0.
	oldHeap := oldInterpreter objectMemory.
	newHeap := Spur32BitMMLESimulator new.
	newHeap
		allocateMemoryOfSize: (oldHeap youngStart * 5 / 4 roundUpTo: 8)
		newSpaceSize: 1024 * 1024
		codeSize: 1024 * 1024.
	map := Dictionary new: oldHeap memory size // 4.
	reverseMap := Dictionary new: oldHeap memory size // 4.
	classToIndex := Dictionary new: 1024
]

{ #category : #'method prototypes' }
SpurBootstrap >> prototypeClassNameMetaSelectorMethodDo: quaternaryBlock [
	"Evaluate aBlock with class name, class is meta, method and selector.
	 For now find methods in class-side category #'method prototypes'.
	 Scheme could be extended to have different protocols for different
	 Squeak/Pharo versions."
	(SpurBootstrap class organization listAtCategoryNamed: #'method prototypes') do:
		[:protoSelector| | method className isMeta |
		method := SpurBootstrap class >> protoSelector.
		className := self classNameForPrototypeMethod: method.
		(isMeta := className endsWith: 'class') ifTrue:
			[className := (className allButLast: 5) asSymbol].
		quaternaryBlock
			value: className
			value: isMeta
			value: (self selectorForPrototypeMethod: method)
			value: method]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> replaceMethods [
	"Replace all the modified method prototypes."
	self allPrototypeClassNamesDo:
		[:sym :symIsMeta| | class |
		class := self findClassNamed: (symbolMap at: sym).
		symIsMeta ifTrue: [class := oldHeap fetchClassOfNonImm: class].
		self prototypeClassNameMetaSelectorMethodDo:
			[:className :isMeta :selector :method| | replacement methodDict index |
			(className = sym
			 and: [symIsMeta = isMeta]) ifTrue:
				[(installedPrototypes includes: method selector) ifFalse:
					["probe method dictionary of the class for each method, installing a dummy if not found."
					Transcript
						cr;
						nextPutAll: 'replacing ';
						nextPutAll: className;
						nextPutAll: (isMeta ifTrue: [' class>>'] ifFalse: ['>>']);
						store: selector;
						flush.
					replacement := self installableMethodFor: method
										selector: selector
										className: className
										isMeta: isMeta.
					methodDict := oldHeap fetchPointer: MethodDictionaryIndex ofObject: class.
					index := self indexOfSelector: (symbolMap at: selector) in: methodDict.
					oldHeap
						storePointer: index - SelectorStart
						ofObject: (oldHeap fetchPointer: MethodArrayIndex ofObject: methodDict)
						withValue: replacement.
					installedPrototypes add: method selector]]]]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> replacementForCharacterMethod: characterMethodOop [
	"Answer a replacement method for the argument if it refers
	 to Character's old inst var value.  Otherwise answer nil."
	| proxy clone assembly newInsts |
	proxy := VMCompiledMethodProxy new
				for: characterMethodOop
				coInterpreter: oldInterpreter
				objectMemory: oldHeap.
	clone := self cloneMethodProxy: proxy.
	clone dropSourcePointer.
	clone hasInstVarRef ifFalse:
		[^nil].
	assembly := BytecodeDisassembler new disassemble: clone.
	assembly literals: (assembly literals allButLast: 2), {symbolMap at: #asInteger}, (assembly literals last: 2).
		"Do this by looking for index of pushReceiverVariable: and replacing it by pushSelf, send asInteger"
	newInsts := (assembly instructions piecesCutWhere:
					[:msgOrLabelAssoc :nextInst|
					 msgOrLabelAssoc isVariableBinding not
					 and: [msgOrLabelAssoc selector == #pushReceiverVariable:]]) fold:
				[:a :b|
				 a allButLast,
				 {	Message selector: #pushReceiver.
					Message
						selector: #send:super:numArgs:
						arguments: {symbolMap at: #asInteger. false. 0}},
				 b].
	assembly instructions: newInsts.
	^self
		installableMethodFor: assembly assemble
		selector: clone selector
		className: #Character
		isMeta: false
]

{ #category : #'method prototypes' }
SpurBootstrap >> selectorForPrototypeMethod: protoMethod [
	| protoSelector |
	protoSelector := protoMethod selector.
	^(protoSelector last: protoSelector size
						- (protoSelector indexOfSubCollection: 'PROTOTYPE')
						- 'PROTOTYPE' size
						+ 1) asSymbol
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> stringFor: aString [
	| string |
	string := oldHeap instantiateClass: (oldHeap splObj: ClassByteString) indexableSize: aString size.
	1 to: aString size do:
		[:i| oldHeap storeByte: i - 1 ofObject: string withValue: (aString at: i) asInteger].
	^string

]

{ #category : #'bootstrap methods' }
SpurBootstrap >> symbolClass [
	^oldHeap fetchClassOfNonImm: (oldHeap splObj: SelectorDoesNotUnderstand)
]

{ #category : #'bootstrap image' }
SpurBootstrap >> transform [
	self installModifiedMethods.
	self bootstrapImage.
	newHeap initializePostBootstrap.
	self validate
]

{ #category : #'bootstrap image' }
SpurBootstrap >> validate [
	| p n duplicates maxClassIndex |
	self assert: (reverseMap at: newHeap specialObjectsOop) = oldHeap specialObjectsOop.
	self assert: (map at: oldHeap specialObjectsOop) = newHeap specialObjectsOop.
	self assert: (reverseMap at: newHeap classTableRootObj ifAbsent: []) isNil.

	duplicates := { 3. newHeap arrayClassIndexPun. newHeap weakArrayClassIndexPun }.
	maxClassIndex := classToIndex inject: 0 into: [:a :b| a max: b].
	self assert: ((0 to: maxClassIndex) select:
					[:idx| | classObj |
					(classObj := newHeap classAtIndex: idx) ~= newHeap nilObject
					and: [(newHeap classIndexOf: classObj) = (newHeap hashBitsOf: classObj)]]) isEmpty.
	0 to: maxClassIndex do:
		[:index| | classObj |
		(classObj := newHeap classAtIndex: index) = newHeap nilObject
			ifTrue:
				[self assert: (classToIndex keyAtValue: index ifAbsent: []) isNil]
			ifFalse:
				[self assert: (newHeap classIndexOf: classObj) ~= (newHeap hashBitsOf: classObj).
				(duplicates includes: index) ifFalse:
					[self assert: (newHeap hashBitsOf: classObj) = index]]].
	classToIndex keysAndValuesDo:
		[:oldClass :idx|
		self assert: (newHeap hashBitsOf: (map at: oldClass)) = idx. 
		self assert: oldClass = (reverseMap at: (newHeap classAtIndex: idx))].
	n := 0.
	newHeap allObjectsDo:
		[:o|
		(o <= newHeap trueObject
		 or: [o > lastClassTablePage]) ifTrue:
			[self assert: (reverseMap includesKey: o).
			 self assert: (newHeap fetchClassOfNonImm: o) = (map at: (oldHeap fetchClassOfNonImm: (reverseMap at: o)))].
		n := n + 1.
		p := o].
	p class.
	self assert: (n between: map size and: map size + 5) "+ 5 is room for classTable"
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> withExecutableInterpreterDo: aBlock [
	"With the oldInterpreter ready to execute code, evaluate aBlock,
	 then return the interpreter (and the heap) to the ``just snapshotted'' state."
	| savedpc initialContext finalContext |
	oldInterpreter
		initStackPages;
		loadInitialContext;
		internalizeIPandSP.
	initialContext := oldInterpreter frameContext: oldInterpreter localFP.
	savedpc := oldInterpreter localIP.
	"oldInterpreter printHeadFrame."
	aBlock value.
	"oldInterpreter printHeadFrame."
	oldInterpreter
		internalPush: oldInterpreter localIP;
		externalizeIPandSP.
	"now undo the execution state"
	finalContext := oldInterpreter voidVMStateForSnapshot.
	self assert: initialContext = finalContext.
	self assert: oldInterpreter localIP = savedpc
]

{ #category : #'word size' }
SpurBootstrap >> wordSize [
	^self subclassResponsibility
]

{ #category : #'word size' }
SpurBootstrap >> wordSizeMask [
	^self subclassResponsibility
]
