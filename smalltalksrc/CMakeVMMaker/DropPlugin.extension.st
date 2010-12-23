Extension { #name : #DropPlugin }

{ #category : #'*CMakeVMMaker' }
DropPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |

	maker ifMac: [
		maker addPlatformSources:
			#( 'sqMacDragDrop')
		]
	].
]
