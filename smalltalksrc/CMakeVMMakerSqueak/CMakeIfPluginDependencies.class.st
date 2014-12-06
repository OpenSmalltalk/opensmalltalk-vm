"
A CMakeIfPluginDependencies Template looks something like this:

	'IF (MyPlugin_dependencies)	""set dependencies""
		add_dependencies(MyPlugin ${MyPlugin_dependencies})
	ENDIF (MyPlugin_dependencies)'.
"
Class {
	#name : #CMakeIfPluginDependencies,
	#superclass : #CMakeTemplate,
	#instVars : [
		'plugin',
		'dependencies'
	],
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #accessing }
CMakeIfPluginDependencies >> dependencies [
 	^ String streamContents: [:stream | dependencies asStringOn: stream delimiter: ' ' ]
]

{ #category : #'initialize-release' }
CMakeIfPluginDependencies >> initialize [
	plugin:= 'foo'.
	dependencies:= OrderedCollection with: 'bar' with: 'nun'.
	self content:'
  IF(',plugin, '_dependencies)
	 ADD_DEPENDENCIES(' , plugin, ' ' , self dependencies,')
  ENDIF( ', plugin, '_dependencies)'


]

{ #category : #accessing }
CMakeIfPluginDependencies >> plugin [

	^ plugin
]

{ #category : #'initialize-release' }
CMakeIfPluginDependencies >> plugin: pString dependencies: anOrderedCollection [
	plugin:= pString.
	dependencies:= anOrderedCollection.
	self content:'
  IF(',plugin, '_dependencies)
	 ADD_DEPENDENCIES( ', plugin, ' ' , self dependencies,')
  ENDIF( ', plugin, '_dependencies)'

]
