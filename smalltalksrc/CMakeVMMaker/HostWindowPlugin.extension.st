Extension { #name : #HostWindowPlugin }

{ #category : #'*CMakeVMMaker' }
HostWindowPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |

	maker ifMac: [
		maker addPlatformSources:
			#( 'sqMacHostWindow.c' )
		]
	].
		
		




]
