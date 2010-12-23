Extension { #name : #SecurityPlugin }

{ #category : #'*CMakeVMMaker' }
SecurityPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |

	maker ifMac: [
		maker includeDirectories: '${crossDir}/plugins/FilePlugin'.
		maker addPlatformSources:
			#( 'sqMacSecurity.c' )
	 
		]
	].
		
		




]
