"
This is a configuration for building freetype2 library
"
Class {
	#name : #CMFreetype2,
	#superclass : #CMThirdpartyLibrary,
	#category : #'CMakeVMMaker-Libs'
}

{ #category : #'as yet unclassified' }
CMFreetype2 class >> canonicalName [
	^ 'freetype2'
]

{ #category : #'package properties' }
CMFreetype2 >> archiveMD5Sum [

	^ 'c15f6dc8ed190d67b89ae09aaf7896b4'
]

{ #category : #'generating actions' }
CMFreetype2 >> build [

	gen 
		puts:
'
add_custom_command(OUTPUT "${ft2config}"
	COMMAND ./configure --prefix=''${installPrefix}'' ', self configurationFlags, '
	WORKING_DIRECTORY "${libSourcesDir}"
	DEPENDS "${unpackTarget}"
)
add_custom_command(OUTPUT "${ft2libInstalled}"
	COMMAND make
	COMMAND make install
	WORKING_DIRECTORY "${libSourcesDir}"
	DEPENDS "${ft2config}"
	COMMENT "Building ${libName}"
)
'

]

{ #category : #'generating actions' }
CMFreetype2 >> copyArtefacts [

	gen puts:
'add_custom_command(
	OUTPUT "${externalModulesDir}/${libraryFileName}"
	COMMAND cp ${installPrefix}/lib/${libraryFileName} ${externalModulesDir}/${libraryFileName}
	DEPENDS "${ft2libInstalled}"
)'
]

{ #category : #'generating actions' }
CMFreetype2 >> defineAsTarget [

	gen puts:
	
'
add_custom_target(${libName} 
	DEPENDS ${externalModulesDir}/${libraryFileName}
	)
'


]

{ #category : #'generating actions' }
CMFreetype2 >> defineGlobalTargets [
	| var |
	var := self canonicalName , '_LIB'.
	vmGen set: var toString: self targetForLinking.
"
define a library as imported one
and make it depend from it's build target
"
	vmGen
		puts: 
('add_library("{1}" SHARED IMPORTED GLOBAL)
	set_target_properties("{1}" PROPERTIES IMPORTED_LOCATION "{1}")
add_dependencies("{1}" "{2}")
' format: { '${',var, '}' . self buildTarget }
).

	vmGen cmd: 'add_dependencies' params:
		vmGen moduleName , ' ' , self buildTarget
]

{ #category : #'package properties' }
CMFreetype2 >> downloadURL [
	^ 'http://ftp.igh.cnrs.fr/pub/nongnu/freetype/freetype-2.4.9.tar.gz'

]

{ #category : #accessing }
CMFreetype2 >> includeDir [
	"see setVariables"

" `<prefix>/include/freetype2' must be in your current inclusion path "


	^ '"${thirdpartyDir}/out/include" "${thirdpartyDir}/out/include/freetype2"'
]

{ #category : #'package properties' }
CMFreetype2 >> libraryFileName [
	^ 'libfreetype.6.dylib'
]

{ #category : #'generating actions' }
CMFreetype2 >> setVariables [
	super setVariables.
	
"add include path"
	gen 
		set: #freetype2_includeDir toString: '${installPrefix}/include';
		set: #libraryFileName to: self libraryFileName;
		set: #freetype2_location toString: '${externalModulesDir}/${libraryFileName}';
		set: #ft2config toString: '${libSourcesDir}/builds/unix/config.status';
	 	set: #ft2libInstalled toString: '${installPrefix}/lib/${libraryFileName}'
]

{ #category : #'package properties' }
CMFreetype2 >> unpackedDirName [

	^ 'freetype-2.4.9'
]
