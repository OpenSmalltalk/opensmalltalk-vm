Extension { #name : #UUIDPlugin }

{ #category : #'*CMakeVMMaker' }
UUIDPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |

	maker ifMac: [
		maker addPlatformSources:
			#( 'sqMacUUID.c')
		]
	].
]
