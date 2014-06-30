Class {
	#name : #CMakeVMMakerSqueakUnixConfigTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakUnixConfigTest >> testCompilerFlags [
	#( #SqueakUnixConfig)
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration new.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  compilerFlags isKindOf: Collection)]]]].





]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakUnixConfigTest >> testExecutableType [
	#( SqueakUnixConfig)
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration new.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
								ifTrue:[
							o:= configuration new.
							self assert:(o  executableType = '').]]]    "hello code smell"

]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakUnixConfigTest >> testLDFlags [
	#( #SqueakUnixConfig)
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration new.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  lDFlags isArray)]]]].





]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakUnixConfigTest >> testPlatformName [
		self flag:'tty'. "todo: fix code smell in hard coded string"
	#( SqueakUnixConfig)
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration new.
							(o excludeFromBuild not)  |(configuration isAbstractBaseClass not)  
								ifTrue:[
							o:= configuration new.
							(o excludeFromBuild not)
								ifTrue:[self assert:(o  platformName = 'unix' )]]]]


]
