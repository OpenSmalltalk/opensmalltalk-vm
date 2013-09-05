"
SpurBootstrap bootstraps an image in CogMemoryManager format from a Squeak V3 + closures format.

e.g.
	(SpurBootstrap32 new on: '/Users/eliot/Cog/startreader.image')
		transform;
		launch

Instance Variables
	classToIndex:		<Dictionary>
	map:		<Dictionary>
	newHeap:		<CogMemoryManager>
	oldHeap:		<NewObjectMemory>
	oldInterpreter:		<StackInterpreterSimulator>

classToIndex
	- oldClass to new classIndex map

map
	- oldObject to newObject map

newHeap
	- the output, bootstrapped image

oldHeap
	- the input, image

oldInterpreter
	- the interpreter associated with oldHeap, needed for a hack to grab WeakArray

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
		'lastClassTablePage'
	],
	#pools : [
		'VMObjectIndices'
	],
	#category : #'Cog-Bootstrapping'
}

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
	^instSpec << 16 + nInstVars
]

{ #category : #'method prototypes' }
SpurBootstrap class >> ProtoObjectPROTOTYPEscaledIdentityHash [
	"For identityHash values returned by primitive 75, answer
	 such values times 2^18.  Otherwise, match the existing
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

{ #category : #bootstrap }
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

{ #category : #bootstrap }
SpurBootstrap >> bootstrapImage [
	self cloneNilTrueAndFalse.
	self buildClassMap.
	self allocateClassTable.
	self cloneObjects.
	self fillInObjects.
	self fillInClassTable
]

{ #category : #bootstrap }
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

{ #category : #'class indices' }
SpurBootstrap >> classTableSize [
	^newHeap classIndexMask + 1
]

{ #category : #bootstrap }
SpurBootstrap >> clone: oldObj classIndex: classIndex [
	| newObj |
	newObj := newHeap
				allocateSlots: (oldHeap fetchWordLengthOf: oldObj)
				format: (self newFormatFor: oldObj)
				classIndex: classIndex.
	reverseMap at: newObj put: oldObj.
	^map at: oldObj put: newObj
]

{ #category : #bootstrap }
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

{ #category : #bootstrap }
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

{ #category : #bootstrap }
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

{ #category : #bootstrap }
SpurBootstrap >> fillInCompiledMethod: newObj from: oldObj [
	self fillInBitsObject: newObj from: oldObj.
	self fillInPointerObject: newObj from: oldObj
]

{ #category : #bootstrap }
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

{ #category : #bootstrap }
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

{ #category : #'class indices' }
SpurBootstrap >> firstOrdinaryClassIndex [
	^newHeap classTablePageSize
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

{ #category : #bootstrap }
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

{ #category : #bootstrap }
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

{ #category : #bootstrap }
SpurBootstrap >> transform [
	self bootstrapImage.
	newHeap initializePostBootstrap.
	self validate
]

{ #category : #bootstrap }
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

{ #category : #'word size' }
SpurBootstrap >> wordSize [
	^self subclassResponsibility
]

{ #category : #'word size' }
SpurBootstrap >> wordSizeMask [
	^self subclassResponsibility
]
