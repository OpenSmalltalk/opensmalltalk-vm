"
N.B. tty.

Honestly, I have know idea how to use this (:


Usage:
  SqueakIPhoneSimulatorV3StackConfig generate
Or:
  SqueakIPhoneSimulatorV3StackConfig generateWithSources
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me

"
Class {
	#name : #SqueakIPhoneSimulatorV3SqueakStackConfig,
	#superclass : #SqueakIPhoneSqueakStackV3Config,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #accessing }
SqueakIPhoneSimulatorV3SqueakStackConfig >> architecture [ 
	^'i386'
]

{ #category : #accessing }
SqueakIPhoneSimulatorV3SqueakStackConfig >> commonCompilerFlags [
	^ super commonCompilerFlags, {
		'-mios-simulator-version-min={1}' format: { self sdkVersion } }
]

{ #category : #cmake }
SqueakIPhoneSimulatorV3SqueakStackConfig >> excludeFromBuild [
	^false

]

{ #category : #accessing }
SqueakIPhoneSimulatorV3SqueakStackConfig >> executableName [
	^'iStackVMSimulator'
]

{ #category : #'plugin extra rules' }
SqueakIPhoneSimulatorV3SqueakStackConfig >> ft2PluginConfigurationFlags [ 
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
SqueakIPhoneSimulatorV3SqueakStackConfig >> sdkTarget [ 
	^'iphonesimulator', self sdkVersion
]

{ #category : #settings }
SqueakIPhoneSimulatorV3SqueakStackConfig >> setCommonProperties: maker [ 
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
SqueakIPhoneSimulatorV3SqueakStackConfig >> standardIncludes [ 
	^super standardIncludes, {
		'/Applications/Xcode.app/Contents/Developer/Platforms/{1}.platform/Developer/SDKs/{1}{2}.sdk/usr/include/'
			format: { 
				self targetDevice. 
				self sdkVersion} }
		 
]

{ #category : #accessing }
SqueakIPhoneSimulatorV3SqueakStackConfig >> targetDevice [ 
	^'iPhoneSimulator'
]
