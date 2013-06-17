"
- use 0.27.1 version from official source, which builds on windows

http://pkgconfig.freedesktop.org/releases/pkg-config-0.27.1.tar.gz

- ./configure --with-internal-glib -
"
Class {
	#name : #CMWin32PkgConfig,
	#superclass : #CMPkgConfig,
	#category : #'CMakeVMMaker-Libs'
}

{ #category : #'as yet unclassified' }
CMWin32PkgConfig class >> supports: aConfig [
	^  aConfig platformName  = 'win32' 
]

{ #category : #'as yet unclassified' }
CMWin32PkgConfig >> archiveMD5Sum [ 
	^ '5392b4e3372879c5bf856173b418d6a2'
]

{ #category : #'as yet unclassified' }
CMWin32PkgConfig >> build [
	gen 
		puts: '
add_custom_command(OUTPUT "${pkgConfigBinary}"
	COMMAND ./configure --prefix="${installPrefix}" --with-internal-glib CFLAGS="-m32 -march=pentium4" LDFLAGS="-m32 -march=pentium4"
	COMMAND make
	COMMAND make install
	WORKING_DIRECTORY "${libSourcesDir}"
	DEPENDS "${unpackTarget}"
	COMMENT "Building ${libName}"
)
'

]

{ #category : #'as yet unclassified' }
CMWin32PkgConfig >> defineGlobalTargets [

	"none"
	vmGen
		set: #installPrefix toString: '${thirdpartyDir}/out';
		set: #pkgconfigPath toString: '${installPrefix}/bin/pkg-config.exe'
		
]

{ #category : #'as yet unclassified' }
CMWin32PkgConfig >> downloadURL [ 
	^ 'http://pkgconfig.freedesktop.org/releases/pkg-config-0.27.1.tar.gz'
]

{ #category : #'as yet unclassified' }
CMWin32PkgConfig >> setVariables [

	super setVariables.
	
	gen set: #pkgConfigBinary toString: '${installPrefix}/bin/pkg-config.exe'
]

{ #category : #'as yet unclassified' }
CMWin32PkgConfig >> unpackedDirName [

	^ 'pkg-config-0.27.1'
]
