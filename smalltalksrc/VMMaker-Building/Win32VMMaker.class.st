"
A special form of VMMaker to suit Windows machines.  Copies files around a little.
"
Class {
	#name : #Win32VMMaker,
	#superclass : #VMMaker,
	#category : #'VMMaker-Building'
}

{ #category : #'target directories' }
Win32VMMaker >> deleteUnwantedExternalPluginDirectories [
	"Don't."
]

{ #category : #'target directories' }
Win32VMMaker >> deleteUnwantedInternalPluginDirectories [
	"Don't."
]

{ #category : #'target directories' }
Win32VMMaker >> externalPluginsDirectory [
	"return the target directory for the external plugins sources"
	^self sourceDirectory
"	| fd |
	fd := self sourceDirectory directoryNamed: 'external'.
	fd assureExistence.
	^fd"
]

{ #category : #'target directories' }
Win32VMMaker >> internalPluginsDirectory [
	"return the target directory for the internal plugins sources"
	^self sourceDirectory
"	| fd |
	fd := self sourceDirectory directoryNamed: 'internal'.
	fd assureExistence.
	^fd"
]

{ #category : #'copying files' }
Win32VMMaker >> processAssortedFiles [
	"Do nothing."
]

{ #category : #'generate sources' }
Win32VMMaker >> validatePlugin:	plName in: listOfPlugins [
	"The normal file release process bundles all files in the plugin directory, so don't bother users telling them 'there are no cross platform files for xyz' if there is are platform specific files present."
	| plugin |
	plName isString
		ifTrue: [(listOfPlugins includes: plName)
				ifTrue: [plugin := Smalltalk classNamed: plName]]
		ifFalse: [((plName isBehavior
						and: [plName inheritsFrom: InterpreterPlugin])
					and: [listOfPlugins includes: plName name])
				ifTrue: [plugin := plName]].
	plugin ifNil: [^ self couldNotFindPluginClass: plName].

	"Make sure we have any and all platform and file support for this plugin"

	(plugin isSuitablePluginForPlatform: self platformName) ifFalse:[^self notSuitablePlugin: plugin forPlatform: self platformName].
		
	"Is there a cross-platform or platform files directory of the same name as this plugin?"
	plugin requiresPlatformFiles
		ifTrue: [(self platformPluginsDirectory directoryExists: plugin moduleName)
				ifFalse: [logger show: 'No platform specific files found for ' , plugin moduleName printString; cr.
					^ self couldNotFindPlatformFilesFor: plugin]].
	plugin requiresCrossPlatformFiles ifTrue: [
		((self platformPluginsDirectory directoryExists: plugin moduleName)
			or:[self crossPlatformPluginsDirectory directoryExists: plugin moduleName])
				ifFalse: [logger show: 'No cross platform files found for ' , plugin moduleName printString; cr.
					^ self couldNotFindPlatformFilesFor: plugin]].

	^plugin
]
