Class {
	#name : #CMLibPng,
	#superclass : #CMThirdpartyLibrary,
	#category : #'CMakeVMMaker-Libs'
}

{ #category : #'as yet unclassified' }
CMLibPng class >> canonicalName [
	^ 'libpng'
]

{ #category : #'package properties' }
CMLibPng >> archiveMD5Sum [

	^ '39a35257cd888d29f1d000c2ffcc79eb'
]

{ #category : #'generating actions' }
CMLibPng >> build [

	gen 
		puts:
'
add_custom_command(OUTPUT "${libpngInstalled}"
	COMMAND ./configure --prefix=''${installPrefix}'' PKG_CONFIG="${pkgconfigPath}"
		PKG_CONFIG_PATH="${installPrefix}/lib/pkgconfig" CFLAGS=''-arch i386'' LDFLAGS=''-arch i386''
	COMMAND make
	COMMAND make install
	WORKING_DIRECTORY "${libSourcesDir}"
	DEPENDS "${unpackTarget}" pkg-config
	COMMENT "Building ${libName}"
)
'

]

{ #category : #'generating actions' }
CMLibPng >> copyArtefacts [

	gen puts:
'add_custom_command(
	OUTPUT "${externalModulesDir}/${libraryFileName}"
	COMMAND cp ${libpngInstalled} ${externalModulesDir}/${libraryFileName}
	DEPENDS "${libpngInstalled}"
)'
]

{ #category : #'generating actions' }
CMLibPng >> defineAsTarget [
	
	gen puts:
	'add_custom_target(${libName}
		DEPENDS "${externalModulesDir}/${libraryFileName}"
	)'
]

{ #category : #'generating actions' }
CMLibPng >> defineGlobalTargets [
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
CMLibPng >> dependencies [
	^ #( 'pkg-config' )
]

{ #category : #'package properties' }
CMLibPng >> downloadURL [

	^ 'ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng-1.2.49.tar.gz'
]

{ #category : #'package properties' }
CMLibPng >> libraryFileName [

	^ 'libpng12.0.dylib'
]

{ #category : #'generating actions' }
CMLibPng >> setVariables [
	super setVariables.
	
"add include path"
	gen 
		set: #libraryFileName to: self libraryFileName;
		set: #libpngInstalled toString: '${installPrefix}/lib/${libraryFileName}'.
		
]

{ #category : #'package properties' }
CMLibPng >> unpackedDirName [
	^ 'libpng-1.2.49'
]
