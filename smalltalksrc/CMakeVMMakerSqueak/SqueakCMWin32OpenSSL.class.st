Class {
	#name : #SqueakCMWin32OpenSSL,
	#superclass : #SqueakCMOpenSSL,
	#category : #'CMakeVMMakerSqueak-Libs'
}

{ #category : #'as yet unclassified' }
SqueakCMWin32OpenSSL class >> platformName [ 
	^'win32'
]

{ #category : #'as yet unclassified' }
SqueakCMWin32OpenSSL >> archiveMD5Sum [
	"answer the MD5 checksum (in string) for downloaded library archive 
	(to check that downloaded file is not corrupt).
	
	You can take this sum by issuing:
	  md5 filename
	from command line
	"
	^ 'ae412727c8c15b67880aef7bd2999b2e'
]

{ #category : #'as yet unclassified' }
SqueakCMWin32OpenSSL >> build [

	gen 
		puts:
'
add_custom_command(OUTPUT "${libSourcesDir}/Makefile"
	COMMAND ./config shared --prefix=''${installPrefix}'' 
	WORKING_DIRECTORY "${libSourcesDir}"
	DEPENDS "${unpackTarget}"
)

add_custom_command(OUTPUT "${installPrefix}/bin/libeay32.dll" "${installPrefix}/bin/ssleay32.dll"
	COMMAND make
	COMMAND make install
	WORKING_DIRECTORY "${libSourcesDir}"
	DEPENDS "${libSourcesDir}/Makefile"
	COMMENT "Building ${libName}"
)
'

]

{ #category : #'as yet unclassified' }
SqueakCMWin32OpenSSL >> configurationFlags [
	^ 'shared'
]

{ #category : #'as yet unclassified' }
SqueakCMWin32OpenSSL >> copyArtefacts [ 

	self copy: '${installPrefix}/bin/libeay32.dll' to: '${externalModulesDir}/libeay32.dll'.
	self copy: '${installPrefix}/bin/ssleay32.dll' to: '${externalModulesDir}/ssleay32.dll'.
"	self copy: '${installPrefix}/lib/libssl.dll.a' to: '${externalModulesDir}/libssl.dll.a'.
	self copy: '${installPrefix}/lib/libcrypto.dll.a' to: '${externalModulesDir}/libcrypto.dll.a'.
"
"
'libcrypto.dll.a' 'libssl.dll.a'.
"
]

{ #category : #'as yet unclassified' }
SqueakCMWin32OpenSSL >> defineAsTarget [ 
	
	gen puts:
	'add_custom_target(', self buildTarget , '
		DEPENDS 
		"${externalModulesDir}/libeay32.dll"
		"${externalModulesDir}/ssleay32.dll"
	)'
	
		"${externalModulesDir}/${libraryFileName}"

]

{ #category : #'as yet unclassified' }
SqueakCMWin32OpenSSL >> defineGlobalTargets [ 


]

{ #category : #'as yet unclassified' }
SqueakCMWin32OpenSSL >> downloadURL [ 
	^'http://www.openssl.org/source/openssl-1.0.1c.tar.gz'
]

{ #category : #'as yet unclassified' }
SqueakCMWin32OpenSSL >> includeDir [

	^ '"${thirdpartyDir}/out/include"'
]

{ #category : #'as yet unclassified' }
SqueakCMWin32OpenSSL >> libraryFileName [
	^ 'libssl.dll.a'
]

{ #category : #'as yet unclassified' }
SqueakCMWin32OpenSSL >> setVariables [ 
	super setVariables.
	
	gen
		set: #libraryFileName to: self libraryFileName;
		set: #libInstalled to: '${installPrefix}/lib/${libraryFileName}'
]

{ #category : #'as yet unclassified' }
SqueakCMWin32OpenSSL >> unpackedDirName [
	^ 'openssl-1.0.1c'
]
