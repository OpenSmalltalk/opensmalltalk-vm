"
SMarkTransporter is a used to interact with a git-fileout system used in the RoarVM project to manage Smalltalk source code.

SMarkTransporter is not actually a Transporter class, since there are currently no needs for customization.
Thus, it is just a dummy class for future use, and to hold #transportersForFileOutMenu.

"
Class {
	#name : #SMarkTransporter,
	#superclass : #Object,
	#category : #'CogBenchmarks-SMark'
}

{ #category : #transporter }
SMarkTransporter class >> transportersForFileOutMenu [
	^ { (Smalltalk at: #Transporter ifAbsent: [^#()])
			forPackage: (PackageInfo named: 'SMark') }
]
