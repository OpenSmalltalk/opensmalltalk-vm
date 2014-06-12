"
Used to build 32 bit Cog on Debian 64 bits.

You need to prepare Debian this way:

apt-get install ia32-libs libc6-dev-i386 gcc-multilib g++-multilib

ln -s /usr/lib32/libSM.so.6 /usr/lib32/libSM.so
ln -s /usr/lib32/libICE.so.6 /usr/lib32/libICE.so
ln -s /usr/lib32/libGL.so.1 /usr/lib32/libGL.so
ln -s /usr/lib32/libX11.so.6 /usr/lib32/libX11.so

Then you can go on Linux32x86SqueakCogV3Debian64Config generateWithSources.

or find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me



"
Class {
	#name : #Linux32x86SqueakCogV3Debian64Config,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-LinuxX86_64-32Compatibility'
}

{ #category : #cmake }
Linux32x86SqueakCogV3Debian64Config >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default allBuildConfigurations copyWithoutAll:#(#assert #assertWithHeartbeatTimer #debug  #debugMultiThreadedFFI #debugWithHeartbeatTimer #releaseHeartbeatTimer #releaseMultiThreadedFFI)



]

{ #category : #accessing }
Linux32x86SqueakCogV3Debian64Config >> commonCompilerFlags [ 
	^ super commonCompilerFlags , { '-L/usr/lib32' }
]

{ #category : #plugins }
Linux32x86SqueakCogV3Debian64Config >> defaultExternalPlugins [
	^ (super defaultExternalPlugins copyWithoutAll: #(#ThreadedIA32FFIPlugin #InternetConfigPlugin))


]

{ #category : #cmake }
Linux32x86SqueakCogV3Debian64Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
Linux32x86SqueakCogV3Debian64Config >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x8664
]

{ #category : #cmake }
Linux32x86SqueakCogV3Debian64Config >> excludeFromBuild [
	^false

]

{ #category : #accessing }
Linux32x86SqueakCogV3Debian64Config >> linkFlags [ 
	^ super linkFlags , ' -L/usr/lib32'
]
