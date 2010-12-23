Extension { #name : #FilePlugin }

{ #category : #'*CMakeVMMaker' }
FilePlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |

	maker addCrossSources: #( 'sqFilePluginBasicPrims.c').
	
	maker ifMac: [
		maker addPlatformSources:
			#( 'sqMacUnixFileInterface.c' 'sqMacDirectory.c')
		]
	].
		
		




]
