Class {
	#name : #StackSimulatorConfig,
	#superclass : #StackIPhoneConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #accessing }
StackSimulatorConfig >> architecture [ 
	^'i386'
]

{ #category : #accessing }
StackSimulatorConfig >> commonCompilerFlags [
	^ super commonCompilerFlags, {
		'-mios-simulator-version-min={1}' format: { self sdkVersion } }
]

{ #category : #accessing }
StackSimulatorConfig >> executableName [
	^'iStackVMSimulator'
]

{ #category : #'plugin extra rules' }
StackSimulatorConfig >> ft2PluginConfigurationFlags [ 
	^ {'--without-zlib'.
		'--without-bzip2'.
		'--host=i386-apple-darwin'.
		'--enable-static=yes'. 
		'--enable-shared=no'.
		'CFLAGS=\\"-arch {1} -pipe -std=c99 -Wno-trigraphs -O2 -fpascal-strings -fwrapv -Wreturn-type -Wunused-variable -fvisibility=hidden -fmessage-length=0 -mios-simulator-version-min={3}  -I{2}/usr/include/libxml2 -isysroot {2}\\"'.
		'LDFLAGS=\\"-arch {1} -mios-simulator-version-min={3} -isysroot {2}\\"' }
		collect: [ :each | 
			each format: { 
				self architecture. 
				self sysroot. 
				self sdkVersion } ]
]

{ #category : #accessing }
StackSimulatorConfig >> sdkTarget [ 
	^'iphonesimulator', self sdkVersion
]

{ #category : #settings }
StackSimulatorConfig >> setCommonProperties: maker [ 
	maker set: 'CMAKE_CROSSCOMPILING' to: 'TRUE'.
	maker set: 'CMAKE_SYSTEM_NAME' to: 'Darwin'.
	maker set: 'CMAKE_SYSTEM_PROCESSOR' to: 'i386'.

	maker 
		set: 'SDKVER' 
		toString: self sdkVersion.
	maker 
		set: 'DEVROOT' 
		toString: ('/Applications/Xcode.app/Contents/Developer/Platforms/{1}.platform/Developer' 
			format: { self targetDevice }).
	maker 
		set: 'SDKROOT' 
		toString: ('$\{DEVROOT\}/SDKs/{1}$\{SDKVER\}.sdk' format: { self targetDevice }).

	maker set: 'CMAKE_OSX_SYSROOT' to: self sysroot.
		
	maker set: 'CMAKE_FIND_ROOT_PATH' to: '"${SDKROOT}" "${DEVROOT}"'.
	maker set: 'CMAKE_FIND_ROOT_PATH_MODE_PROGRAM' to: 'ONLY'.
	maker set: 'CMAKE_FIND_ROOT_PATH_MODE_LIBRARY' to: 'ONLY'.
	maker set: 'CMAKE_FIND_ROOT_PATH_MODE_INCLUDE' to: 'ONLY'.
	
	maker 
		set: 'CMAKE_EXE_LINKER_FLAGS' 
		toString: '-mios-simulator-version-min=${SDKVER} --sysroot ${SDKROOT} -L${SDKROOT}/usr/lib -L${SDKROOT}/usr/lib/system'.
	maker 
		set: 'CMAKE_C_FLAGS' 
		toString: '--sysroot ${SDKROOT} -L${SDKROOT}/usr/lib -L${SDKROOT}/usr/lib/system'.
	maker 
		set: 'CMAKE_CXX_FLAGS' 
		toString: '--sysroot ${SDKROOT} -L${SDKROOT}/usr/lib -L${SDKROOT}/usr/lib/system'.

	maker addFrameworks: self frameworks.
]

{ #category : #'source files' }
StackSimulatorConfig >> standardIncludes [ 
	^super standardIncludes, {
		'/Applications/Xcode.app/Contents/Developer/Platforms/{1}.platform/Developer/SDKs/{1}{2}.sdk/usr/include/'
			format: { 
				self targetDevice. 
				self sdkVersion} }
		 
]

{ #category : #accessing }
StackSimulatorConfig >> targetDevice [ 
	^'iPhoneSimulator'
]
