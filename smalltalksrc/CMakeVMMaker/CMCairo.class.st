"
This is Cairo library config for building on MacOSX
"
Class {
	#name : #CMCairo,
	#superclass : #CMCairoBundle,
	#category : #'CMakeVMMaker-Libs'
}

{ #category : #'as yet unclassified' }
CMCairo class >> canonicalName [
	^ 'cairo'
]

{ #category : #'package properties' }
CMCairo >> archiveMD5Sum [

	^ '645b7c1421ed52260d0853e3215c1d8f'
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

	self 
		copy: '${libcairoInstalled}' 
		to: '${externalModulesDir}/${libraryFileName}'

]

{ #category : #'generating actions' }
CMCairo >> defineAsTarget [
	
	gen puts:
	'add_custom_target(${libName}
		DEPENDS pixman freetype2 "${externalModulesDir}/${libraryFileName}" 
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

	^ 'http://www.cairographics.org/releases/cairo-1.12.6.tar.xz'
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

{ #category : #'generating actions' }
CMCairo >> unpack [
	"produce commands for unpacking the library archive.
	
	the output of this command should use a directory
	${workDir}/${libName}
	where the unpacked library sources will be located.
	
	see #setVariables method for understanding what variables used here
	
	NOTE: had to override since cairo uses 7z compression
	"

	gen set: #unpackTarget toString: '${libSourcesDir}/touch.cmake'.
	
	gen puts:
'add_custom_command(OUTPUT "${unpackTarget}"
		COMMAND tar -Jxf "${archiveFileName}"  
		COMMAND touch "${unpackTarget}"
		COMMENT "Unpacking ${libName} ... "
	)
'.

]

{ #category : #'package properties' }
CMCairo >> unpackedDirName [
	^ 'cairo-1.12.6'
]
