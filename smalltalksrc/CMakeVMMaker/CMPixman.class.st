Class {
	#name : #CMPixman,
	#superclass : #CMCairoBundle,
	#category : #'CMakeVMMaker-Libs'
}

{ #category : #'as yet unclassified' }
CMPixman class >> canonicalName [
	^ 'pixman'
]

{ #category : #'package properties' }
CMPixman >> archiveMD5Sum [

	^ '6563b6400b9fa23b47fd52105faf72b4'
]

{ #category : #'generating actions' }
CMPixman >> build [

	gen 
		puts:
'
add_custom_command(OUTPUT "${libpixmanInstalled}"
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
CMPixman >> copyArtefacts [

	gen puts:
'add_custom_command(
	OUTPUT "${externalModulesDir}/${libraryFileName}"
	COMMAND cp ${libpixmanInstalled} ${externalModulesDir}/${libraryFileName}
	DEPENDS "${libpixmanInstalled}"
)'
]

{ #category : #'generating actions' }
CMPixman >> defineAsTarget [
	
	gen puts:
	'add_custom_target(${libName}
		DEPENDS "${externalModulesDir}/${libraryFileName}"
	)'
]

{ #category : #'generating actions' }
CMPixman >> defineGlobalTargets [
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
CMPixman >> dependencies [
	^ #( 'pkg-config' 'libpng')
]

{ #category : #'package properties' }
CMPixman >> downloadURL [

	^ 'http://www.cairographics.org/releases/pixman-0.26.0.tar.gz'
]

{ #category : #'package properties' }
CMPixman >> libraryFileName [

	^ 'libpixman-1.0.dylib'
]

{ #category : #'generating actions' }
CMPixman >> setVariables [
	super setVariables.
	gen 
		set: #libraryFileName to: self libraryFileName;
		set: #libpixmanInstalled toString: '${installPrefix}/lib/${libraryFileName}'.
		
	
]

{ #category : #'package properties' }
CMPixman >> unpackedDirName [
	^ 'pixman-0.26.0'
]
