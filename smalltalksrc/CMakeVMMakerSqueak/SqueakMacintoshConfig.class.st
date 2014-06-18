Class {
	#name : #SqueakMacintoshConfig,
	#superclass : #CPlatformConfigForSqueak,
	#instVars : [
		'resourcesDir'
	],
	#category : #CMakeVMMakerSqueak
}

{ #category : #accessing }
SqueakMacintoshConfig >> externalModulesDir [
	"answer the location in VM bundle, where plugins and rest of dynamic libs will be copied,
	by default, it is Framerowks subdir. i.e: 
	
		Cog.app/Contents/Frameworks
		
	"
	
	^ '${outputDir}/', self executableName, '.app/Contents/MacOS/Plugins'
]
