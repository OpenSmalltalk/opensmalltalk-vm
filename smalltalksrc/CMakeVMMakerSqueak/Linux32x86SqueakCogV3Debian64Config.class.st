"
Used to build 32 bit Cog on Debian 64 bits.

You need to prepare Debian this way:

apt-get install ia32-libs libc6-dev-i386 gcc-multilib g++-multilib

ln -s /usr/lib32/libSM.so.6 /usr/lib32/libSM.so
ln -s /usr/lib32/libICE.so.6 /usr/lib32/libICE.so
ln -s /usr/lib32/libGL.so.1 /usr/lib32/libGL.so
ln -s /usr/lib32/libX11.so.6 /usr/lib32/libX11.so

Then you can go on CogOnDebian64Config generateWithSources.



"
Class {
	#name : #Linux32x86SqueakCogV3Debian64Config,
	#superclass : #Linux32x86SqueakCogV3Config,
	#category : #'CMakeVMMakerSqueak-Linux64-32Compatibility'
}

{ #category : #accessing }
Linux32x86SqueakCogV3Debian64Config >> commonCompilerFlags [ 
	^ super commonCompilerFlags , { '-L/usr/lib32' }
]

{ #category : #plugins }
Linux32x86SqueakCogV3Debian64Config >> defaultExternalPlugins [
	^ (super defaultExternalPlugins copyWithoutAll: #(#ThreadedIA32FFIPlugin #InternetConfigPlugin))


]

{ #category : #accessing }
Linux32x86SqueakCogV3Debian64Config >> linkFlags [ 
	^ super linkFlags , ' -L/usr/lib32'
]
