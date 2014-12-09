Class {
	#name : #CMakeVMMakerSqueakHistoryHelp,
	#superclass : #CMakeVMMakerSqueakDeveloperHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakHistoryHelp class >> bookName [ 
	^'History'
]

{ #category : #pages }
CMakeVMMakerSqueakHistoryHelp class >> cmakeVMMakerSqueak [
	^HelpTopic
		title: 'Summary'
		contents:
'CMakeVMMakerSqueak ....

The original version subclassed the various Generators,  Configs and Builders of Igor''s version while providing a small pharo/squeak compatibility layer where required. This philosophy was in place for CMakeVMMakerSqueak-tty.1 to CMakeVMMakerSqueak-tty.26

This approach was abandoned when Eliot Miranda adopted his [Platform][Language][VM][MemoryManager][BuildType]  organization on the basis of simple math.

The build system must support 
[N Platforms: Windows Linux Mac BSD Plan9...][2 Languages: Newspeak and Squeak.] x [3. Virtual Machines: Cog, Sista and Stack.] x [2 Memory Managers: V3 and Spur.] x [9 build types build  build.assert.itimerheartbeat  build.debug.itimerheartbeat  build.multithreaded  build.multithreaded.debug  build.assert  build.debug  build.itimerheartbeat  build.multithreaded.assert  ] = N x [2 x 3 x 2 x 9]= Nx 108 distinct Configurations.


Development started along these lines at CMakeVMMakerSqueak-tty.27.  During this next stretch, I attempted to make CMakeVMMaker and CMakeVMMakerSqueak functionaly equivalent--meaning a pharo user could use the squeak system using pharo idioms. This required some ridiculous contortions exemplified by what I believe is the largest Trait ever attempted. You can see this at  CMakeVMMakerSqueak-tty.32 where I write 

''Removed old Traits from first port from Pharo and added a new Trait. Installed this trait at the topmost class of the Squeak heirarchy which is inter-twined with the existing pharo hierarchy. Ugly, but not too ugly and supports decision not to fork existing work. This lets me enforce a pseudo-abstract class discipline. 

Probably two more days coding to get this to production."

heh.

The Trait grew, and grew and grew. as I attempted to bolt on Eliot''s requirements onto the side of the Pharo code using a Trait. The result was like that scene in Aliens where the baby Alien attaches itself to the face of the astronaut...

At CMakeVMMakerSqueak-tty.63 I noticed that the Trait would not do. The functionality was OK, but the Package could not be loaded into a Squeak image from the Monticello Repository. This killed that approach.

At CMakeVMMakerSqueak-tty.64 I started over and decided to implement a ''parallel'' system to the pharo code that relied on Igor''s generators to produce the CMake files.

At CMakeVMMakerSqueak-tty.82 Eliot noticed a major problem with the Pharo approach. The config.h file was hard coded. We needed CMake to generate that. At this point I turned to Ian''s code for instruction.  

I studied his code and noted the use of templates and the overall flow of processing. Igor''s processing flow is very close to Ian''s so the processing Architecture of CMakeVMaker was kept in place. I did start the process of  using CMake Templates at this point as I found it much easier.

This process continues until CMakeVMMakerSqueak-tty.99.

At CMakeVMMakerSqueak-tty.99 I ditched the CMakeVMmaker generate methods and went generateByTemplate for all Generators.


In Summary, the programmatic flow of the system and most design patterns are Igor''s. The emphasises on CMake generation and the use of Templates are Ian''s.



















'
]

{ #category : #accessing }
CMakeVMMakerSqueakHistoryHelp class >> key [
	^'CMakeVMMakerSqueakHistoryHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakHistoryHelp class >> overview [
	^HelpTopic
		title: 'CMakeVMMakerSqueak'
		contents:
'CMakeVMMaker Squeak is a product of Igor Stasenko''s CMakeVMaker for pharo and Ian Piumurta''s custom CMake configuration files he wrote for the Stack Interpreter on Linux.

Here I present an overview of the design of each historical system and end with a summary of their contributions to this system.
'
]

{ #category : #pages }
CMakeVMMakerSqueakHistoryHelp class >> pages [
	^#( CMakeVMMakerSqueakHistoryIgorStasenkoHelp CMakeVMMakerSqueakHistoryIanPiumartaHelp cmakeVMMakerSqueak)
]
