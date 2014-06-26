"
N.B. tty.

Honestly, I have know idea how to use this (:


SqueakIOSBuilder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #SqueakIPhoneSimulatorSqueakStackV3Config,
	#superclass : #SqueakIPhoneSqueakStackV3Config,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #accessing }
SqueakIPhoneSimulatorSqueakStackV3Config >> architecture [ 
	^'i386'
]

{ #category : #accessing }
SqueakIPhoneSimulatorSqueakStackV3Config >> commonCompilerFlags [
	^ super commonCompilerFlags, {
		'-mios-simulator-version-min={1}' format: { self sdkVersion } }
]

{ #category : #cmake }
SqueakIPhoneSimulatorSqueakStackV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
SqueakIPhoneSimulatorSqueakStackV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
SqueakIPhoneSimulatorSqueakStackV3Config >> executableName [
	^ self vmStackExecutableName
]

{ #category : #'plugin extra rules' }
SqueakIPhoneSimulatorSqueakStackV3Config >> ft2PluginConfigurationFlags [ 
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
SqueakIPhoneSimulatorSqueakStackV3Config >> sdkTarget [ 
	^'iphonesimulator', self sdkVersion
]

{ #category : #settings }
SqueakIPhoneSimulatorSqueakStackV3Config >> setCommonProperties: maker [ 
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

{ #category : #'cmake buildType redirects' }
SqueakIPhoneSimulatorSqueakStackV3Config >> standardIncludesBuild [ 
	^super standardIncludesBuild, {
		'/Applications/Xcode.app/Contents/Developer/Platforms/{1}.platform/Developer/SDKs/{1}{2}.sdk/usr/include/'
			format: { 
				self targetDevice. 
				self sdkVersion} }
		 
]

{ #category : #accessing }
SqueakIPhoneSimulatorSqueakStackV3Config >> targetDevice [ 
	^'iPhoneSimulator'
]
