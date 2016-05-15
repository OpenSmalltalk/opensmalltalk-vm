"
I am a lowly data bucket.

Think of me as a database dataset. 

A CMakeVMMaker-Builder can request information from its configurations passing an instance of me as a storage container. 

They stick their info in me; the builder then extracts it and prints it out for the user.

The Builder then reports the data that I have.


"
Class {
	#name : #CMakeVMakerConfigurationInfo,
	#superclass : #Object,
	#instVars : [
		'availableBuildTypes',
		'dirBuildPlatform',
		'dirSource',
		'excludeFromBuild',
		'isAbstractBaseClass'
	],
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #accessing }
CMakeVMakerConfigurationInfo >> availableBuildTypes [

	^ availableBuildTypes
]

{ #category : #accessing }
CMakeVMakerConfigurationInfo >> dirBuildPlatform [

	^ dirBuildPlatform
]

{ #category : #accessing }
CMakeVMakerConfigurationInfo >> dirSource [
	^ dirSource
]

{ #category : #accessing }
CMakeVMakerConfigurationInfo >> excludeFromBuild [

	^ excludeFromBuild
]

{ #category : #visiting }
CMakeVMakerConfigurationInfo >> visit: aVisitor [
	|v|
	"I am being visited by a CMakeVMMakerSqueak configuration class. Extract its information and store it in myself"
	self flag:'tty'. "why am I not storing the instances itself?does this visit stuff really make sense? I am thinking its 'lightweight'. hmmm"
	v:= aVisitor basicNew.
	(v class isAbstractBaseClass)
		ifFalse:[
			availableBuildTypes := v availableBuildTypes.
			dirBuildPlatform := v dirBuildPlatform.
			dirSource  := v dirSource.
			excludeFromBuild := v excludeFromBuild.
			isAbstractBaseClass := (v class) isAbstractBaseClass].


]
