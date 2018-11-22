Class {
	#name : #SpurPlanningCompactorSimulator,
	#superclass : #SpurPlanningCompactor,
	#instVars : [
		'interestingObj',
		'relocationMap',
		'sffsMode'
	],
	#category : #'VMMaker-SpurMemoryManagerSimulation'
}

{ #category : #private }
SpurPlanningCompactorSimulator >> check: obj [
	<inline: true>
	sffsMode ifNotNil: [self deny: ((manager isGrey: obj) or: [(manager isImmutable: obj)  or: [manager isRemembered: obj]])].
	obj = interestingObj ifTrue: [self halt].
	"this debugged the misuse of the largest free chunk:"
	"(manager checkForLeaks bitAnd: GCModeFull+GCModeFreeSpace) = GCModeFull ifTrue:
		[self deny: ((manager isEnumerableObject: obj) and: [(manager heapMapAtWord: obj) = 0])]"
]

{ #category : #accessing }
SpurPlanningCompactorSimulator >> forceMultiPass [
	sffsMode := #multiPass
]

{ #category : #accessing }
SpurPlanningCompactorSimulator >> interestingObj: obj [
	interestingObj := obj
]

{ #category : #private }
SpurPlanningCompactorSimulator >> recordMovementOf: o to: toFinger savedFirstFieldPtr: savedFirstFieldPtr [
	relocationMap ifNotNil: [:rm| rm at: o put: savedFirstFieldPtr]
]

{ #category : #accessing }
SpurPlanningCompactorSimulator >> recordMovements [
	relocationMap := Dictionary new
]

{ #category : #'space management' }
SpurPlanningCompactorSimulator >> selectSavedFirstFieldsSpace [
	"Override to make savedFirstFieldsSpace small enough for multi-pass compaction, if desired (for testing)."
	super selectSavedFirstFieldsSpace.
	"testRandomAssortment: et al create 1000 objects, aboput 5% pnned and about 33% reclaimable.  Sp 512 objects should force multi-pass."
	sffsMode == #multiPass ifTrue:
		[savedFirstFieldsSpace limit: savedFirstFieldsSpace start + (512 * manager bytesPerOop).
		 biasForGC := false]
]
