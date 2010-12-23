Extension { #name : #SoundPlugin }

{ #category : #'*CMakeVMMaker' }
SoundPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |

	maker ifMac: [
		maker includeDirectories: '${platformsDir}/unix/vm/'.
		maker addPlatformSources:
			#( 'sqMacAudioDeviceList.c' 'sqMacUnixInterfaceSound.c' 
			'sqUnixSoundMacOSXJMM.c')
		]
	].
		
		




]
