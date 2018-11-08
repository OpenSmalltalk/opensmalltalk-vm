"
I am the outermost wrapper on config.cmake

IF (NOT DEFINED __sq_config_h)
	
	rest of config.cmake here

ENDIF (NOT DEFINED __sq_config_h)

View me with: 
Transcript show: ((Linux64x86w32BitSqueakCogV3Config new) configureForBuildType: #build) contentForVmConfigCmake


"
Class {
	#name : #CMakeSqConfigH,
	#superclass : #CMakeTemplate,
	#instVars : [
		'config',
		'templates'
	],
	#category : #'CMakeVMMakerSqueak-CMakeCompositeTemplates'
}

{ #category : #accessing }
CMakeSqConfigH >> config [

	^ config
]

{ #category : #accessing }
CMakeSqConfigH >> config: anObject [

	config := anObject
]

{ #category : #'code generation' }
CMakeSqConfigH >> contentFor [
"
IF (NOT DEFINED __sq_config_h)
	
	rest of config.cmake here

ENDIF (NOT DEFINED __sq_config_h)"
	templates do: [:each | self puts: each content].
	self puts: 'ENDIF (NOT DEFINED __sq_config_h)'.   "close the IF/ENDIF and write"
	^output contents

	
	
]

{ #category : #'code generation' }
CMakeSqConfigH >> contentFor: aConfigOrClass [
	
	config := aConfigOrClass isBehavior ifTrue: [ aConfigOrClass new ] ifFalse: [aConfigOrClass].
	^ self contentFor
]

{ #category : #'code generation' }
CMakeSqConfigH >> generate [
"
IF (NOT DEFINED __sq_config_h)
	
	rest of config.cmake here

ENDIF (NOT DEFINED __sq_config_h)"
	templates do: [:each | self puts: each content].
	self puts: 'ENDIF (NOT DEFINED __sq_config_h)'.   "close the IF/ENDIF and write"
	config write: output contents toFile: (self outputFileName)
]

{ #category : #'code generation' }
CMakeSqConfigH >> generate: aConfigOrClass [
	
	config := aConfigOrClass isBehavior ifTrue: [ aConfigOrClass new ] ifFalse: [aConfigOrClass].
	^ self generate
]

{ #category : #'initialize-release' }
CMakeSqConfigH >> initialize [

" See class comment"

      content:='should not get here. writestream is used instead of content. this is a hack for tests to pass.'.
	templates := OrderedCollection new.
	output := String new writeStream.
	self puts: 'IF (NOT DEFINED __sq_config_h)

  SET(__sq_config_h 1)
  CONFIG_DEFINE(__sq_config_h)
'.   
]

{ #category : #accessing }
CMakeSqConfigH >> outputFileName [
	^ 'config.cmake'
]

{ #category : #'code generation' }
CMakeSqConfigH >> saveFile [
	
	config write: output contents toFile: (self outputFileName).
]

{ #category : #accessing }
CMakeSqConfigH >> templates [

	^ templates
]

{ #category : #accessing }
CMakeSqConfigH >> templates: anObject [

	templates := anObject
]
