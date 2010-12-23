Extension { #name : #SerialPlugin }

{ #category : #'*CMakeVMMaker' }
SerialPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |

	maker ifMac: [
		maker addPlatformSources:
			#( 'sqMacSerialPort.c' )
		]
	].
		
		




]
