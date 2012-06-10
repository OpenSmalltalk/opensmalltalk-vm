Class {
	#name : #CMCairo,
	#superclass : #CMThirdpartyLibrary,
	#category : #'CMakeVMMaker-Libs'
}

{ #category : #'as yet unclassified' }
CMCairo class >> canonicalName [
	^ 'cairo'
]

{ #category : #'package properties' }
CMCairo >> archiveMD5Sum [

	^ '87649eb75789739d517c743e94879e51'
]

{ #category : #'generating actions' }
CMCairo >> build [

	gen 
		puts:
'
add_custom_command(OUTPUT "${libcairoInstalled}"
	COMMAND ./configure --prefix=''${installPrefix}'' PKG_CONFIG="${pkgconfigPath}"
		PKG_CONFIG_PATH="${installPrefix}/lib/pkgconfig" CFLAGS=''-arch i386'' LDFLAGS=''-arch i386''
		--disable-silent-rules --disable-xlib --disable-dependency-tracking
	COMMAND make
	COMMAND make install
	WORKING_DIRECTORY "${libSourcesDir}"
	DEPENDS "${unpackTarget}" pkg-config freetype2 libpng pixman
	COMMENT "Building ${libName}"
)
'

]

{ #category : #'generating actions' }
CMCairo >> copyArtefacts [

	gen puts:
'add_custom_command(
	OUTPUT "${externalModulesDir}/${libraryFileName}"
	COMMAND cp ${libcairoInstalled} ${externalModulesDir}/${libraryFileName}
	DEPENDS "${libcairoInstalled}"
)'
]

{ #category : #'generating actions' }
CMCairo >> defineAsTarget [
	
	gen puts:
	'add_custom_target(${libName}
		DEPENDS "${externalModulesDir}/${libraryFileName}"
	)'
]

{ #category : #'generating actions' }
CMCairo >> defineGlobalTargets [
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
CMCairo >> dependencies [
	^ #( 'pkg-config' 'pixman' 'libpng' 'freetype2')
]

{ #category : #'package properties' }
CMCairo >> downloadURL [

	^ 'http://www.cairographics.org/releases/cairo-1.12.2.tar.xz'
]

{ #category : #'package properties' }
CMCairo >> libraryFileName [

	^ 'libcairo.2.dylib'
]

{ #category : #'generating actions' }
CMCairo >> setVariables [
	super setVariables.
	gen 
		set: #libraryFileName to: self libraryFileName;
		set: #libcairoInstalled toString: '${installPrefix}/lib/${libraryFileName}'.
		
]

{ #category : #'package properties' }
CMCairo >> unpackedDirName [
	^ 'cairo-1.12.2'
]
