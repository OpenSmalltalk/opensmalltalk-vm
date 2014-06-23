Class {
	#name : #CMakeVMMakerSqueakUnixConfigTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakUnixConfigTest >> testConfigH [
	#( SqueakUnixConfig)
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration new.
							(o excludeFromBuild not)  |(configuration isAbstractBaseClass not)  
								ifTrue:[
							o:= configuration new.
							(o excludeFromBuild not)
								ifTrue:[self assert:(o  configH isString)]]]]




]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakUnixConfigTest >> testExecutableType [
	#( SqueakUnixConfig)
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration new.
							(o excludeFromBuild not)  |(configuration isAbstractBaseClass not)  
								ifTrue:[
							o:= configuration new.
							self assert:(o  executableType = '').]]]    "hello code smell"

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
