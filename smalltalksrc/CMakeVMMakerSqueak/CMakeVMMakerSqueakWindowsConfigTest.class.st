Class {
	#name : #CMakeVMMakerSqueakWindowsConfigTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakWindowsConfigTest >> testExecutableType [

	#(#SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
					o:= configuration new.
					(o excludeFromBuild not)  |(configuration isAbstractBaseClass)  
						ifTrue:[
								o:= configuration new.
								self assert:(o  executableType = 'WIN32').  "hello code smell"]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakWindowsConfigTest >> testPlatformName [
		self flag:'tty'. "todo: fix code smell in hard coded string"
	#(#SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
					o:= configuration new.
					(o excludeFromBuild not)  |(configuration isAbstractBaseClass)  
						ifTrue:[
								o:= configuration new.
								self assert:(o  platformName = 'win32').  "hello code smell"]]]








]
