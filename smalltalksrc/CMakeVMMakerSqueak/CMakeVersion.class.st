"
A CMakeVersion looks like this:

  SET (version  \""1.2.3.4\"")
  STRING (REGEX REPLACE ""(.*)\\.(.*)\\.(.*)-(.*)"" ""\\1"" major   ${version})
  STRING (REGEX REPLACE ""(.*)\\.(.*)\\.(.*)-(.*)"" ""\\2"" minor   ${version})
  STRING (REGEX REPLACE ""(.*)\\.(.*)\\.(.*)-(.*)"" ""\\3"" patch   ${version})
  STRING (REGEX REPLACE ""(.*)\\.(.*)\\.(.*)-(.*)"" ""\\4"" release ${version})

"
Class {
	#name : #CMakeVersion,
	#superclass : #CMakeTemplate,
	#instVars : [
		'version'
	],
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'as yet unclassified' }
CMakeVersion >> initialize [
	self content:'
  SET (version  \"1.2.3.4\")
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\1" major   ${version})
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\2" minor   ${version})
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\3" patch   ${version})
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\4" release ${version})
'
]

{ #category : #accessing }
CMakeVersion >> version [

	^ version
]

{ #category : #accessing }
CMakeVersion >> version: anObject [

	version := anObject.
	self content:'
  SET (version  \"', version, '\")
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\1" major   ${version})
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\2" minor   ${version})
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\3" patch   ${version})
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\4" release ${version})
'
]
