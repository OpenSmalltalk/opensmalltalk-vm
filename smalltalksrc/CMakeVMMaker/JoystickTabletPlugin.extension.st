Extension { #name : #JoystickTabletPlugin }

{ #category : #'*CMakeVMMaker' }
JoystickTabletPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |

	maker ifMac: [
		maker addPlatformSources:
			#( 
			'HID_Error_Handler.c'
			'HID_Name_Lookup.c'
			'HID_Queue_Utilities.c'
			'HID_Utilities.c'
			'sqMacJoystickAndTablet.c'
			)
		]
	].
		
		




]
