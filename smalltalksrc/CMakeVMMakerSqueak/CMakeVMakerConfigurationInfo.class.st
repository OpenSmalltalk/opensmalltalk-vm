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

{ #category : #accessing }
CMakeVMakerConfigurationInfo >> isAbstractBaseClass [

	^ isAbstractBaseClass
]

{ #category : #visiting }
CMakeVMakerConfigurationInfo >> visit: aVisitor [
	|v|
	"I am being visited by a CMakeVMMakerSqueak configuration class. Extract its information and store it in myself"
	self flag:'tty dirSource and dirBuildPlatform  an instance of an irritating difference in idioms when dealing with directory paths'. 
	v:= aVisitor basicNew.
	(v class isAbstractBaseClass)
		ifTrue:[	
				isAbstractBaseClass := true.
				excludeFromBuild := true]
		ifFalse:[
			availableBuildTypes := v availableBuildTypes.
			dirBuildPlatform := v dirBuildPlatform .  "dirBuildPlatform is a String"
			dirSource := v dirSource fullName.      "dirSource is a FileDirectory, so convert to string"
			excludeFromBuild := v excludeFromBuild.
			isAbstractBaseClass := false]. 


]
