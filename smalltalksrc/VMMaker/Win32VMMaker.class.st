"
A special form of VMMaker to suit Windows machines.  Copies files around a little.
"
Class {
	#name : #Win32VMMaker,
	#superclass : #VMMakerWithFileCopying,
	#category : 'VMMaker-Building'
}

{ #category : #'target directories' }
Win32VMMaker >> copyPlatformFilesFor: plugin internal: aBoolean [
	"do nothing for Windows - code is generated into the platform tree so the files are already there"
]

{ #category : #'target directories' }
Win32VMMaker >> copyPlatformVMFiles [
	"Windows builds the sources in the platforms tree, so do nothing here"
]

{ #category : #'target directories' }
Win32VMMaker >> deleteEntireGeneratedTree [
	"remove all the files - but on Windows we can't easily tell which ones. So do nothing for now"
]

{ #category : #'target directories' }
Win32VMMaker >> deleteUnwantedExternalPluginDirectories [
	"delete directories in the external plugins tree with names not in the list  
	of external plugins. This will make sure that only wanted plugins are  
	left after generating external plugins - no previous ones will get left  
	there like unwanted porridge"
	"On windows, we are keeping all the plugins in one place, the platforms tree, so don't delete - we can't easily tell which ones need to be kept"
]

{ #category : #'target directories' }
Win32VMMaker >> deleteUnwantedInternalPluginDirectories [
	"delete directories in the internal plugins tree with names not in the list  
	of internal plugins. This will make sure that only wanted plugins are  
	left after generating inernal plugins - no previous ones will get left  
	there like unwanted porridge"
	"On windows, we are keeping all the plugins in one place, the platforms tree, so don't delete - we can't easily tell which ones need to be kept"
]

{ #category : #'target directories' }
Win32VMMaker >> externalPluginsDirectory [
	"return the target directory for the external plugins sources"
	^self pluginsDirectory
]

{ #category : #'target directories' }
Win32VMMaker >> internalPluginsDirectory [
	^self pluginsDirectory
]

{ #category : #'target directories' }
Win32VMMaker >> makefileDirectory [
"where to put generated makefile related files"
	^self pluginsDirectory
]

{ #category : #'target directories' }
Win32VMMaker >> pluginsDirectory [
	"return the target directory for the plugins sources - for Windows this is the platforms source directory for the plugin"
	| fd |
	fd _ self sourceDirectory directoryNamed: self class pluginsDirName.
	fd assureExistence.
	^fd
]

{ #category : #'copying files' }
Win32VMMaker >> processAssortedFiles [
	"Do nothing."
]

{ #category : #'target directories' }
Win32VMMaker >> sourceDirectory [
	"For Andreas... "
	^self platformDirectory
]

{ #category : #'generate sources' }
Win32VMMaker >> validatePlugin:	plName in: listOfPlugins [
	"The normal file release process bundles all files in the plugin directory, so don't bother users telling them 'there are no cross platform files for xyz' if there is are platform specific files present."
	| plugin |
	plName isString
		ifTrue: [(listOfPlugins includes: plName)
				ifTrue: [plugin _ Smalltalk classNamed: plName]]
		ifFalse: [((plName isBehavior
						and: [plName inheritsFrom: InterpreterPlugin])
					and: [listOfPlugins includes: plName name])
				ifTrue: [plugin _ plName]].
	plugin ifNil: [^ self couldNotFindPluginClass: plName].

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
