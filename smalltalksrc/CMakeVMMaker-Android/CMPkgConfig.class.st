"
this will build a pkg-config package, required to built cairo

"
Class {
	#name : #CMPkgConfig,
	#superclass : #CMThirdpartyLibrary,
	#category : #'CMakeVMMaker-Libs'
}

{ #category : #'as yet unclassified' }
CMPkgConfig class >> canonicalName [
	^ 'pkg-config'
]

{ #category : #'package properties' }
CMPkgConfig >> archiveMD5Sum [

	^ 'd922a88782b64441d06547632fd85744'
]

{ #category : #'generating actions' }
CMPkgConfig >> build [
	gen 
		puts: '
add_custom_command(OUTPUT "${pkgConfigBinary}"
	COMMAND ./configure --prefix=''${installPrefix}'' CFLAGS=''-arch i386'' LDFLAGS=''-arch i386''
	COMMAND make
	COMMAND make install
	WORKING_DIRECTORY "${libSourcesDir}"
	DEPENDS "${unpackTarget}"
	COMMENT "Building ${libName}"
)
'

]

{ #category : #'generating actions' }
CMPkgConfig >> copyArtefacts [
	"do nothing.. "
]

{ #category : #'generating actions' }
CMPkgConfig >> defineAsTarget [
	
	gen puts: '
add_custom_target(${libName} 
	DEPENDS "${pkgConfigBinary}"
	)
'


]

{ #category : #'generating actions' }
CMPkgConfig >> defineGlobalTargets [

	"none"
	vmGen
		set: #installPrefix toString: '${thirdpartyDir}/out';
		set: #pkgconfigPath toString: '${installPrefix}/bin/pkg-config'
		
]

{ #category : #'package properties' }
CMPkgConfig >> downloadURL [

	^ 'http://pkgconfig.freedesktop.org/releases/pkg-config-0.23.tar.gz'
]

{ #category : #'generating actions' }
CMPkgConfig >> setVariables [

	super setVariables.
	
	gen set: #pkgConfigBinary toString: '${installPrefix}/bin/pkg-config'
]

{ #category : #'package properties' }
CMPkgConfig >> unpackedDirName [

	^ 'pkg-config-0.23'
]
