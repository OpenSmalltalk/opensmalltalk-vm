Class {
	#name : #CMakeVMMakerSqueakUnixConfigTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakUnixConfigTest >> testCommonCompilerFlags [

	#( #SqueakAndroidBuilder  #SqueakBSDx86Builder #SqueakLinux32ARMv6Builder #SqueakLinux32x86Builder  #SqueakLinux32x86_64Builder #SqueakLinux64x86w32CompatBuilder #SqueakSunOS32x86Builder)
		do:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: ((Smalltalk at:builder) configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							(o excludeFromBuild not)
								ifTrue:[
							self assert:(o  commonCompilerFlags isArray).
"							self assert:(o  compilerFlagsAssert isArray).
							self assert:(o  compilerFlagsAssertITimerHeartbeat isArray).
							self assert:(o  compilerFlagsBuild isArray).
							self assert:(o  compilerFlagsDebug isArray).
							self assert:(o  compilerFlagsDebugITimerHeartbeat isArray).
							self assert:(o  compilerFlagsIHeartbeatTimer isArray).
							self assert:(o  compilerFlagsMultiThreaded isArray).
							self assert:(o  compilerFlagsMultiThreadedAssert isArray).
							self assert:(o  compilerFlagsMultiThreadedDebug isArray)."]]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakUnixConfigTest >> testConfigH [

	#( #SqueakAndroidBuilder  #SqueakBSDx86Builder #SqueakLinux32ARMv6Builder #SqueakLinux32x86Builder  #SqueakLinux32x86_64Builder #SqueakLinux64x86w32CompatBuilder #SqueakSunOS32x86Builder)
		do:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: ((Smalltalk at:builder) configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							(o excludeFromBuild not)
								ifTrue:[self assert:(o  configH isString)]]]]




]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakUnixConfigTest >> testExecutableType [

	#(#SqueakAndroidBuilder  #SqueakBSDx86Builder #SqueakLinux32ARMv6Builder #SqueakLinux32x86Builder  #SqueakLinux32x86_64Builder #SqueakLinux64x86w32CompatBuilder #SqueakSunOS32x86Builder)
		do:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: ((Smalltalk at:builder)  configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  executableType = '').]]]    "hello code smell"

]
