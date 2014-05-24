Class {
	#name : #SqueakVMMakerSqueakStackUnixTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
SqueakVMMakerSqueakStackUnixTest >> testBuildDir [
	| config dir |
	config := SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig new.  "uses the Trait"
	dir := config buildDir.
	self assert: (dir isKindOf: FileDirectory).
]

{ #category : #'as yet unclassified' }
SqueakVMMakerSqueakStackUnixTest >> testSrcDir [
	| config dir |
	config := SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig new.  "uses the Trait"
	dir := config srcDir.
	self assert: (dir isKindOf: FileDirectory).
]

{ #category : #'as yet unclassified' }
SqueakVMMakerSqueakStackUnixTest >> testTSqueakCPlatformConfigDirFrom [
	| config stringDir dirDir|
	config := SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig new.  "uses the Trait"
	stringDir := config dirFrom: Smalltalk vmPath.
	dirDir := FileDirectory default.
	self assert: (stringDir isKindOf: FileDirectory).
	self assert: (dirDir isKindOf: FileDirectory).
]

{ #category : #'as yet unclassified' }
SqueakVMMakerSqueakStackUnixTest >> testTopDir [
	| config dir |
	config := SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig new.  "uses the Trait"
	dir := config topDir.
	self assert: (dir isKindOf: FileDirectory).
]
