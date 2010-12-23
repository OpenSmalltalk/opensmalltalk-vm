Extension { #name : #InternetConfigPlugin }

{ #category : #'*CMakeVMMaker' }
InternetConfigPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |

	maker ifMac: [
		maker addPlatformSources:
			#( 'sqMacInternetConfiguration.c')
		]
	].
		
		




]
