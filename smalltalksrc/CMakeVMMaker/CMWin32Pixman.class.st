Class {
	#name : #CMWin32Pixman,
	#superclass : #CMPixman,
	#category : #'CMakeVMMaker-Libs'
}

{ #category : #'as yet unclassified' }
CMWin32Pixman class >> supports: aConfig [
	^  aConfig platformName  = 'win32' 
]

{ #category : #'as yet unclassified' }
CMWin32Pixman >> build [

	gen 
		puts:
'
add_custom_command(OUTPUT "${libpixmanInstalled}"
	COMMAND ./configure --prefix=''${installPrefix}'' PKG_CONFIG="${pkgconfigPath}"
		PKG_CONFIG_PATH="${installPrefix}/lib/pkgconfig" CFLAGS="-m32 -march=pentium4 -I${installPrefix}/include" LDFLAGS="-m32 -march=pentium4" LIBS="-L${installPrefix}/lib"
	COMMAND make
	COMMAND make install
	WORKING_DIRECTORY "${libSourcesDir}"
	DEPENDS "${unpackTarget}" pkg-config
	COMMENT "Building ${libName}"
)
'

]

{ #category : #'as yet unclassified' }
CMWin32Pixman >> libraryFileName [ 
	^ 'libpixman-1-0.dll'
]

{ #category : #'as yet unclassified' }
CMWin32Pixman >> setVariables [
	super setVariables.
	
"add include path"
	gen 
		set: #libraryFileName to: self libraryFileName;
		set: #libpixmanInstalled toString: '${installPrefix}/bin/${libraryFileName}'.
		
]
