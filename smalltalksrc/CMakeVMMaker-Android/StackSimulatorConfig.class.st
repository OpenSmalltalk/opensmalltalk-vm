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
	^super standardIncludes, {'/Applications/Xcode.app/Contents/Developer/Platforms/{target}.platform/Developer/SDKs/{target}{sdkVersion}.sdk/usr/include/'
	nameFormat: {'target'->self targetDevice. 'sdkVersion'->self sdkVersion} asDictionary}
		 
]

{ #category : #accessing }
StackSimulatorConfig >> targetDevice [ 
	^'iPhoneSimulator'
]
