Extension { #name : #LocalePlugin }

{ #category : #'*CMakeVMMaker' }
LocalePlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |

	maker ifMac: [
		maker addPlatformSources:
			#( 'sqMacLocaleCarbon.c' )	]
	].
		
		




]
