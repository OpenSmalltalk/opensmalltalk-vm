Extension { #name : #SoundCodecPlugin }

{ #category : #'*CMakeVMMaker' }
SoundCodecPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |

		maker addCrossSources:
			#( 'sqSoundCodecPluginBasicPrims.c' )

	].
		
		




]
