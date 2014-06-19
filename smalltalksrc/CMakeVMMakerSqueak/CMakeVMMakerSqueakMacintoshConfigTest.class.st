Class {
	#name : #CMakeVMMakerSqueakMacintoshConfigTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakMacintoshConfigTest >> testCMakeMacros [

	#(#SqueakIOSBuilder #SqueakMacOSBuilder  #SqueakMacOSPowerPCBuilder #SqueakMacOSX32x86Builder)
		do:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: ((Smalltalk at:builder) configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							(o excludeFromBuild not)
								ifTrue:[self assert:(o  cMakeMacros isString)]]]]




]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakMacintoshConfigTest >> testExecutableType [

	#(#SqueakIOSBuilder #SqueakMacOSBuilder  #SqueakMacOSPowerPCBuilder #SqueakMacOSX32x86Builder)
		do:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: ((Smalltalk at:builder) configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  executableType = 'MACOSX_BUNDLE').
							]]]




]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakMacintoshConfigTest >> testPlatformName [
		#(#SqueakIOSBuilder #SqueakMacOSBuilder  #SqueakMacOSPowerPCBuilder #SqueakMacOSX32x86Builder) 
		do:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: ((Smalltalk at:builder) configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							(o excludeFromBuild not)
								ifTrue:[self assert:(o  platformName = 'Mac OS' )]]]]




]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakMacintoshConfigTest >> testResourcesDir [

	#(#SqueakIOSBuilder #SqueakMacOSBuilder  #SqueakMacOSPowerPCBuilder #SqueakMacOSX32x86Builder)
		do:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: ((Smalltalk at:builder) configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							(o excludeFromBuild not)
								ifTrue:[self assert:(o  resourcesDir isKindOf: FileDirectory)]]]]




]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakMacintoshConfigTest >> testResourcesDirName [
		#(#SqueakIOSBuilder #SqueakMacOSBuilder  #SqueakMacOSPowerPCBuilder #SqueakMacOSX32x86Builder) 
		do:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: ((Smalltalk at:builder) configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							(o excludeFromBuild not)
								ifTrue:[self assert:(o  resourcesDirName isString)]]]]




]
