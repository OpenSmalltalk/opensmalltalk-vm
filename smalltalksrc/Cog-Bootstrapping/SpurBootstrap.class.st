"
SpurBootstrap bootstraps an image in CogMemoryManager format from a Squeak V3 + closures format.

e.g.
	(SpurBootstrap32 new on: '/Users/eliot/Cog/startreader.image') transform
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
		'classToIndex',
		'oldInterpreter'
	],
	#pools : [
		'VMObjectIndices'
	],
	#category : #'Cog-Bootstrapping'
}

{ #category : #bootstrap }
SpurBootstrap >> allocateClassTable [
	"Allocate the root of the classTable plus enough pages to accomodate all classes in
	 the classToIndex map.  Don;t fill in the entries yet; the classes have yet to be cloned."
	| tableRootSize tableRoot page maxSize numPages |
	tableRootSize := self classTableSize / newHeap classTablePageSize.
	tableRoot := newHeap
					allocateSlots: tableRootSize
					format: newHeap arrayFormat
					classIndex: newHeap arrayClassIndexPun.
	newHeap classTableRootObj: tableRoot.
	newHeap nilFieldsOf: tableRoot.
	"first page is strong"
	page := newHeap
					allocateSlots: tableRootSize
					format: newHeap arrayFormat
					classIndex: newHeap arrayClassIndexPun.
	newHeap nilFieldsOf: page.
	newHeap storePointer: 0 ofObject: tableRoot withValue: page.
	maxSize := classToIndex inject: 0 into: [:a :b| a max: b].
	numPages := (maxSize + newHeap classTableMinorIndexMask / newHeap classTablePageSize) truncated.
	2 to: numPages do:
		[:i|
		page := newHeap
					allocateSlots: tableRootSize
					format: newHeap weakArrayFormat
					classIndex: newHeap weakArrayClassIndexPun.
		newHeap nilFieldsOf: page.
		newHeap storePointer: i - 1 ofObject: tableRoot withValue: page]
]

{ #category : #bootstrap }
SpurBootstrap >> buildClassMap [
	"enumerate all objects asking isBehavior:?  (class == Metaclass or class class == Metaclass) doesn't work for Newspeak"
	"Build a map from all classes in oldHeap to a class index.
	 ONLY DEALS WITH CLASSES THAT HAVE INSTANCES!! (can walk superclass chain?  Can walk subclasses set? Can ask class == Metaclass or class class == Metaclass class?)"
	| classes classTableIndex |
	self defineKnownClassIndices.
	classes := classToIndex keys asSet.
	classTableIndex := newHeap classTablePageSize.
	oldHeap allObjectsDo:
		[:oldObj| | oldClass |
		 oldClass := oldHeap fetchClassOfNonInt: oldObj.
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
	map
		at: oldObj
		put: (newHeap
				allocateSlots: (oldHeap fetchWordLengthOf: oldObj)
				format: (self newFormatFor: oldObj)
				classIndex: classIndex)
]

{ #category : #bootstrap }
SpurBootstrap >> cloneNilTrueAndFalse [
	{	oldHeap nilObject.
		oldHeap falseObject.
		oldHeap trueObject. }
		with: (self firstOrdinaryClassIndex to: self firstOrdinaryClassIndex + 2)
		do: [:obj :classIndex|
			classToIndex at: (oldHeap fetchClassOfNonInt: obj) put: classIndex.
			self clone: obj classIndex: classIndex].
	newHeap nilObject: (map at: oldHeap nilObject). "needed for nilling objects etc"
]

{ #category : #bootstrap }
SpurBootstrap >> cloneObjects [
	| characterClass characterTable oldObj oldClass |
	characterClass := oldHeap classCharacter.
	characterTable := oldHeap characterTable.
	oldObj := oldHeap objectAfter: oldHeap trueObject.
	[oldObj < oldHeap freeStart] whileTrue:
		[oldClass := oldHeap fetchClassOfNonInt: oldObj.
		 (oldObj ~= characterTable
		 and: [oldClass ~= characterClass]) ifTrue:
			[self clone: oldObj classIndex: (classToIndex at: oldClass)].
		 oldObj := oldHeap objectAfter: oldObj]
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
	classToIndex
		at: oldHeap classSmallInteger put: 1; "N.B. must fill-in index 3 manually"
		at: oldHeap classCharacter put: 2;
		"at: oldHeap classSmallInteger put: 3" "N.B. must fill-in index 3 manually"
		"leave room for up to 15 tagged classes"
		"leave room for up to 16 puns"
		at: oldHeap classLargePositiveInteger put: 32;
		at: oldHeap classLargeNegativeInteger put: 33;
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
		at: oldHeap classUnsafeAlien put: 133
]

{ #category : #bootstrap }
SpurBootstrap >> fillInClassTable [
	| firstPage classWeakArray |
	classToIndex keysAndValuesDo:
		[:oldClass :index| | newClass page |
		newClass := map at: oldClass.
		newHeap setHashBitsOf: newClass to: index.
		page := newHeap
					fetchPointer: index >> newHeap classTableMajorIndexShift
					ofObject: newHeap classTableRootObj.
		newHeap
			storePointer: (index bitAnd: newHeap classTableMinorIndexMask)
			ofObject: page
			withValue: newClass].
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
	0 to: (oldHeap lastPointerOf: oldObj) >> 4 - 1 do:
		[:i| | oldValue newValue |
		oldValue := oldHeap fetchPointer: i ofObject: oldObj.
		newValue := (oldHeap isIntegerObject: oldValue)
						ifTrue: [oldValue]
						ifFalse:
							[map at: oldValue ifAbsent:
								[self assert: (oldHeap fetchClassOfNonInt: oldValue) = oldHeap classCharacter.
								 newHeap characterObjectOf:
									(oldHeap integerValueOf:
										(oldHeap fetchPointer: CharacterValueIndex ofObject: oldValue))]].
		newHeap
			storePointerUnchecked: i
			ofObject: newObj
			withValue: newValue]
]

{ #category : #'class indices' }
SpurBootstrap >> firstOrdinaryClassIndex [
	^newHeap classTablePageSize
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
	newHeap := CMM32LSBSimulator new.
	newHeap allocateMemoryOfSize: oldHeap memory size * 5 / 4.
	map := IdentityDictionary new: oldHeap memory size.
	classToIndex := IdentityDictionary new: 1024
]

{ #category : #bootstrap }
SpurBootstrap >> transform [
	self cloneNilTrueAndFalse.
	self buildClassMap.
	self allocateClassTable.
	self cloneObjects.
	self fillInObjects.
	self fillInClassTable
]

{ #category : #'word size' }
SpurBootstrap >> wordSize [
	^self subclassResponsibility
]

{ #category : #'word size' }
SpurBootstrap >> wordSizeMask [
	^self subclassResponsibility
]
