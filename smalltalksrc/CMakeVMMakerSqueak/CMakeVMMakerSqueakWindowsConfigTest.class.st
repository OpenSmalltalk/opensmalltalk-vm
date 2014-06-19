Class {
	#name : #CMakeVMMakerSqueakWindowsConfigTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakWindowsConfigTest >> testCommonCompilerFlags [
		""
		self flag:'tty'. "I need to differentiate this from the test in CommonConfigTests. Also, why is windows Array and others String?"
		#(#SqueakWin32x86Builder) 
		do:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: ((Smalltalk at:builder)  configurationsCategory))
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
							self assert:(o  compilerFlagsMultiThreadedDebug isArray)."


								]]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakWindowsConfigTest >> testExecutableType [

		#(#SqueakWin32x86Builder) 
		do:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: ((Smalltalk at:builder)  configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  executableType = 'WIN32').  "hello code smell"


								]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakWindowsConfigTest >> testPlatformName [

		#(#SqueakWin32x86Builder) 
		do:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: ((Smalltalk at:builder)  configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  platformName = 'win32').  "hello code smell"


								]]]








]
