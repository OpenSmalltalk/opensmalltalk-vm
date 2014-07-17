Class {
	#name : #CMakeVMMakerSqueakMacintoshConfigTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakMacintoshConfigTest >> testExecutableType [
	#(#SqueakMacintoshConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
					o:= configuration new.
					(o excludeFromBuild not) | (configuration isAbstractBaseClass)
					ifTrue:[self assert:(o  executableType = 'MACOSX_BUNDLE')]]]




]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakMacintoshConfigTest >> testPlatformName [
	#(#SqueakMacintoshConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration new.
							(o excludeFromBuild not) | (configuration isAbstractBaseClass)
								ifTrue:[self assert:(o  platformName = 'Mac OS' )]]]




]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakMacintoshConfigTest >> testResourcesDir [
	self flag:'tty'. "I modified resourcesDir to 'assureExistence' from 'fullname'. if this causes problems, look into that"
	#(#SqueakMacintoshConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
					o:= configuration new.
					(o excludeFromBuild not) | (configuration isAbstractBaseClass)
								ifTrue:[ self assert:(o  resourcesDir isKindOf: FileDirectory)]]]




]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakMacintoshConfigTest >> testResourcesDirName [
	#(#SqueakMacintoshConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration new.
							(o excludeFromBuild not) | (configuration isAbstractBaseClass)
								ifTrue:[self assert:(o  resourcesDirName isString)]]]




]
