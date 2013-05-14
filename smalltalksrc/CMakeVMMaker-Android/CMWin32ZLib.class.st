Class {
	#name : #CMWin32ZLib,
	#superclass : #CMThirdpartyLibrary,
	#category : #'CMakeVMMaker-Libs'
}

{ #category : #'as yet unclassified' }
CMWin32ZLib class >> canonicalName [ 
	^ 'zlib'
]

{ #category : #'as yet unclassified' }
CMWin32ZLib class >> supports: aConfig [
	^  aConfig platformName  = 'win32' 
]

{ #category : #'as yet unclassified' }
CMWin32ZLib >> archiveMD5Sum [
	"answer the MD5 checksum (in string) for downloaded library archive 
	(to check that downloaded file is not corrupt).
	
	You can take this sum by issuing:
	  md5 filename
	from command line
	"
	^ '44d667c142d7cda120332623eab69f40'
]

{ #category : #'as yet unclassified' }
CMWin32ZLib >> build [

'	COMMAND ./configure --prefix="${installPrefix}" --archs="-arch i386" '.
	
	gen 
		puts: '
add_custom_command(OUTPUT "${libzInstalled}"
	COMMAND make -fwin32/Makefile.gcc 
	COMMAND make install -fwin32/Makefile.gcc prefix="${installPrefix}" INCLUDE_PATH="${installPrefix}/include" LIBRARY_PATH="${installPrefix}/lib" BINARY_PATH="${installPrefix}/bin" SHARED_MODE=1
	WORKING_DIRECTORY "${libSourcesDir}"
	DEPENDS "${unpackTarget}"
	COMMENT "Building ${libName}"
)
'

]

{ #category : #'as yet unclassified' }
CMWin32ZLib >> copyArtefacts [

	self 
		copy: '${libzInstalled}' 
		to: '${externalModulesDir}/${libraryFileName}'

]

{ #category : #'as yet unclassified' }
CMWin32ZLib >> defineAsTarget [ 
	
	gen puts:
	'add_custom_target(', self buildTarget , '
		DEPENDS 
		"${externalModulesDir}/${libraryFileName}"
	)'
	
		"${externalModulesDir}/${libraryFileName}"

]

{ #category : #'as yet unclassified' }
CMWin32ZLib >> defineGlobalTargets [ 

]

{ #category : #'as yet unclassified' }
CMWin32ZLib >> downloadURL [ 
	^ 'http://zlib.net/zlib-1.2.8.tar.gz'
]

{ #category : #'as yet unclassified' }
CMWin32ZLib >> libraryFileName [
	^ 'zlib1.dll'
]

{ #category : #'as yet unclassified' }
CMWin32ZLib >> setVariables [
	super setVariables.
	gen 
		set: #libraryFileName to: self libraryFileName;
		set: #libzInstalled toString: '${installPrefix}/bin/${libraryFileName}'.
		
]

{ #category : #'as yet unclassified' }
CMWin32ZLib >> unpackedDirName [
	^ 'zlib-1.2.7'
]
