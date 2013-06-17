Class {
	#name : #CMIOSFreetype2,
	#superclass : #CMOSXFreetype2,
	#category : #'CMakeVMMaker-Libs'
}

{ #category : #testing }
CMIOSFreetype2 class >> supports: aConfig [ 
	"just for iPhone"

	^ (self platformName = aConfig platformName) 
		and: [ aConfig isKindOf: StackIPhoneConfig ]
]

{ #category : #'generating actions' }
CMIOSFreetype2 >> copyArtefacts [

	gen puts:
'add_custom_command(
	OUTPUT "${externalModulesDir}/${libraryFileName}"
	DEPENDS "${ft2libInstalled}"
)'
]

{ #category : #'generating actions' }
CMIOSFreetype2 >> defineGlobalTargets [
	| var |
	var := self canonicalName , '_LIB'.
	vmGen set: var toString: self libraryFileName.
"
define a library as imported one
and make it depend from it's build target
"
	vmGen
		puts: 
('add_library("{1}" STATIC IMPORTED GLOBAL)
	set_target_properties("{1}" PROPERTIES IMPORTED_LOCATION "{1}")
add_dependencies("{1}" "{2}")
' format: { '${',var, '}' . self buildTarget }
).

	vmGen cmd: 'add_dependencies' params:
		vmGen moduleName , ' ' , self buildTarget
]

{ #category : #accessing }
CMIOSFreetype2 >> includeDir [
	"see setVariables"

" `<prefix>/include/freetype2' must be in your current inclusion path "

	^ '"${thirdpartyDir}/freetype2/freetype-2.4.9/include"'
]

{ #category : #'package properties' }
CMIOSFreetype2 >> libraryFileName [ 
	^'libfreetype.a'
]

{ #category : #exports }
CMIOSFreetype2 >> targetForLinking [
	"Answer a target or path to library to link with, which can be used by 
	external plugins or VM module"

	^ '${ft2libInstalled}/', self libraryFileName
]
