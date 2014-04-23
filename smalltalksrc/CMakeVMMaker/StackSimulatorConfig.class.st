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
StackSimulatorConfig >> executableName [
	^'iStackVMSimulator'
]

{ #category : #accessing }
StackSimulatorConfig >> sdkTarget [ 
	^'iphonesimulator', self sdkVersion
]

{ #category : #'source files' }
StackSimulatorConfig >> standardIncludes [ 
	^super standardIncludes, {'/Applications/Xcode.app/Contents/Developer/Platforms/{1}.platform/Developer/SDKs/{1}{2}.sdk/usr/include/'
	format: { self targetDevice. self sdkVersion} }
		 
]

{ #category : #accessing }
StackSimulatorConfig >> targetDevice [ 
	^'iPhoneSimulator'
]
