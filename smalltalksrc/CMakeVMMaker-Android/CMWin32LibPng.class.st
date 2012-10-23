Class {
	#name : #CMWin32LibPng,
	#superclass : #CMLibPng,
	#category : #'CMakeVMMaker-Libs'
}

{ #category : #'as yet unclassified' }
CMWin32LibPng class >> supports: aConfig [
	^  aConfig platformName  = 'win32' 
]

{ #category : #'as yet unclassified' }
CMWin32LibPng >> build [

"LIBS=-L${installPrefix}/lib"
	gen 
		puts:
'
add_custom_command(OUTPUT "${libpngInstalled}"
	COMMAND ./configure --prefix=''${installPrefix}'' CFLAGS="-m32 -march=pentium4 -I${installPrefix}/include" CPPFLAGS="-m32 -I${installPrefix}/include" LDFLAGS="-m32 -march=pentium4 -L${installPrefix}/lib" 
	COMMAND make
	COMMAND make install
	COMMAND cp "${installPrefix}/lib/libpng.dll.a" "${installPrefix}/lib/libpng12.dll.a"
	WORKING_DIRECTORY "${libSourcesDir}"
	DEPENDS "${unpackTarget}" pkg-config
	COMMENT "Building ${libName}"
)
'

]

{ #category : #'as yet unclassified' }
CMWin32LibPng >> dependencies [
	^ #( 'pkg-config' 'zlib')
]

{ #category : #'as yet unclassified' }
CMWin32LibPng >> downloadURL [
	^ 'ftp://ftp.simplesystems.org/pub/libpng/png/src/history/libpng12/libpng-1.2.49.tar.gz'

]

{ #category : #'as yet unclassified' }
CMWin32LibPng >> libraryFileName [

	^ 'libpng-3.dll'
]

{ #category : #'as yet unclassified' }
CMWin32LibPng >> setVariables [
	super setVariables.
	
"add include path"
	gen 
		set: #libraryFileName to: self libraryFileName;
		set: #libpngInstalled toString: '${installPrefix}/bin/${libraryFileName}'.
		
]
