Extension { #name : #MIDIPlugin }

{ #category : #'*CMakeVMMaker' }
MIDIPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |

	maker ifMac: [
		maker addPlatformSources:
			#( 'sqMacMIDI.c')
		]
	].
		
		




]
