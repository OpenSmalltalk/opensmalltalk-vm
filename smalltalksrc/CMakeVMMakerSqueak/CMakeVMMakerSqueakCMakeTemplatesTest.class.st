Class {
	#name : #CMakeVMMakerSqueakCMakeTemplatesTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCMakeTemplatesTest >> testCMakeTemplateContent [
	"a template encapsulates CMake content and should have default content on instantiation"
	CMakeTemplate
		subclassesDo:[:c | |template| 
				template := c new.
				template initialize.
"				template content inspect."
				self assert: ((template content) isString)]


]
