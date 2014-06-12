Class {
	#name : #CMakeVMMakerSqueakDeveloperHelp,
	#superclass : #CMakeVMMakerSqueakHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakDeveloperHelp class >> bookName [ 
	^'Developer''s Guide'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> igorStasenkoDesign [
	^HelpTopic
		title:'Igor Stasenko''s CMakeVMMaker Design for pharo'
		contents:
'CMakeVMMakerSqueak extends Igor Stasenko''s pharo work in CMMakeVMMaker. 

For this reason, a discussion of the Pharo design is apropos as it will support later discussion about CMakeVMMakerSqueak

TODO: finish me


'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> overview [
	^HelpTopic
		title:'CMakeVMMaker in a couple of sentences.'
		contents:
'The heart of the package is CMakeGenerator and its two subclasses CMakeVMGenerator and CMakePluginGenerator.

CMakeGenerator collects information from CPlatformConf, CMThirdpartyLibrary and InterpreterPlugins and writes it out to CMake files and associated directories. 

From there, the user invokes cmake and make using a generated build.sh script.

The programmer directs the flow of the generator by coding a subclass of CPlatformConf, setting it up correctly and asking it to generate itself. 

The configuration then invokes the CMakeVMGenerator passing itself as an argument. 

The VMGeneratator extracts the information and utilizes VMPluginGenerator to generate plugin stuff, the CPlatformConf to generate other stuff and CMThirdPartyLibrary''s to generate other stuff. 

The end result is a CMake evironment that is set up to correctly build a VM
'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> pages [
	^#(overview prerequisites igorStasenkoDesign)
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> prerequisites [
	^HelpTopic
		title:'Pre-requisits'
		contents:
'TODO: write me


'
]
