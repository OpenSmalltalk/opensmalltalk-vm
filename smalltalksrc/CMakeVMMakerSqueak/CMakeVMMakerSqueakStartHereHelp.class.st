Class {
	#name : #CMakeVMMakerSqueakStartHereHelp,
	#superclass : #CMakeVMMakerSqueakHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakStartHereHelp class >> bookName [
	^'CMakeVMMaker Start Here'
]

{ #category : #accessing }
CMakeVMMakerSqueakStartHereHelp class >> pages [
	^#(scratch shortVersionLinuxBuild)
]

{ #category : #pages }
CMakeVMMakerSqueakStartHereHelp class >> scratch [
	^HelpTopic
		title: 'Start Here Scratch'
		contents:
'Goal is that a complete newbie can open this and get up and running.

'
]

{ #category : #pages }
CMakeVMMakerSqueakStartHereHelp class >> shortVersionLinuxBuild [
	^HelpTopic
		title: 'Short  Version Linux Build'
		contents:
'These steps will familiarize you with the CMakeVMMaker system from a user perspective. At the end of this Help Topic you should have a working system for Linux.
Each step is an action followed by an explanation of what you are looking at.

1. (SqueakLinux64x86w32CompatBuilder default) browseHierarchy

    CMakeVmMakerSqueak uses Builders to build builds. 
    The author''s system is a 64 bit architecture with 32 bit compatability libraries installed, so he uses the SqueakLinux64x86w32CompatBuilder.
     Builder.

2. (SqueakLinux64x86w32CompatBuilder default) browse	
    The Classes in the CMakeVMMakerSqueak-Builder Class Category are named with the convention "Squeak[Operating System][Architecture][Miscelaneous]Builder".
      
     If you are compiling on a pure 32 bit linux box, use the  (SqueakLinux32x86Builder default)    builder
    
      A pure 64 bit linux build would require the (SqueakLinux32x86_64Builder default)  builder.
       
     The same convention holds for other operating systems (mac, windows, etc) 

2.  (SqueakLinux64x86w32CompatBuilder default) configurationsCategory  inspect

     In CmakeVMMakerSqueak, Builders utilize "Configurations" to generate "builds".
     Configurations are classes and are stored in specific class categories .
     Open a browser and look in the "CMakeVMMakerSqueak-Linux64X86-32BitCompatibility" category and you will see the Configuration classes available for that builder.

      
     
3. (SqueakLinux64x86w32CompatBuilder default) allAvailableBuildTypes


do c

'
]
