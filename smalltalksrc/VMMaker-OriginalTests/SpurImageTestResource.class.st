Class {
	#name : #SpurImageTestResource,
	#superclass : #TestResource,
	#instVars : [
		'emptyVM',
		'vmWithLoadedImage'
	],
	#category : #'VMMaker-OriginalTests'
}

{ #category : #accessing }
SpurImageTestResource class >> baseImageName [
	^'core32-preen.image'
]

{ #category : #accessing }
SpurImageTestResource class >> imageNameForTests [
	"self imageNameForTests"
	| baseImageName |
	baseImageName := self baseImageName.
	#('.' 'oscogvm/image' '../oscogvm/image') do:
		[:dirName|
		 (dirName asFileReference exists
		  and: [
			(dirName asFileReference / baseImageName) exists ]) ifTrue:
			[^dirName, '/', baseImageName]].
	self error: 'cannot find ', baseImageName
]

{ #category : #preening }
SpurImageTestResource class >> preenImage [
	"Assume there's a Pharo bootstrap core32.image in ../oscogvm/image/core32.image.
	 We should find out where the image directory is and write a download script to get it.
	 But for now assume it's there.  See e.g.
		https://bintray.com/pharo-project/pharo/Pharo/201701061402-32bit#files"
	"[self preenImage] timeToRun"
	Spur32BitPreen new
		writeDefaultHeader: true;
		savedWindowSize: 640@480;
		preenImage: self imageNameForTests
]

{ #category : #accessing }
SpurImageTestResource >> emptyVM [
	^emptyVM ifNil:
		[emptyVM := StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur32BitMemoryManager
																	  compactorClass SpurPlanningCompactor)]
]

{ #category : #accessing }
SpurImageTestResource >> initializedVM [
	vmWithLoadedImage ifNil:
		[vmWithLoadedImage := StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur32BitMemoryManager).
		 vmWithLoadedImage
			openOn: self class imageNameForTests extraMemory: 0.
		vmWithLoadedImage objectMemory
			initializeMarkStack; "The Pharo bootstrap has no mark or weakling stacks :-)"
			initializeWeaklingStack].
	^vmWithLoadedImage
]

{ #category : #accessing }
SpurImageTestResource >> reset [
	"self current reset"
	emptyVM := vmWithLoadedImage := nil
]
