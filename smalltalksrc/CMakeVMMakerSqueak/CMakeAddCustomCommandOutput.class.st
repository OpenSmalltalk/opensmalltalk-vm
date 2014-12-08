"
cmake --help-command add_custom_command  

add_custom_command
------------------

Add a custom build rule to the generated build system.

There are two main signatures for add_custom_command The first
signature is for adding a custom command to produce an output.

::

 add_custom_command(OUTPUT output1 [output2 ...]
                    COMMAND command1 [ARGS] [args1...]
                    [COMMAND command2 [ARGS] [args2...] ...]
                    [MAIN_DEPENDENCY depend]
                    [DEPENDS [depends...]]
                    [IMPLICIT_DEPENDS <lang1> depend1
                                     [<lang2> depend2] ...]
                    [WORKING_DIRECTORY dir]
                    [COMMENT comment] [VERBATIM] [APPEND])

This defines a command to generate specified OUTPUT file(s).  A target
created in the same directory (CMakeLists.txt file) that specifies any
output of the custom command as a source file is given a rule to
generate the file using the command at build time.  Do not list the
output in more than one independent target that may build in parallel
or the two instances of the rule may conflict (instead use
add_custom_target to drive the command and make the other targets
depend on that one).  If an output name is a relative path it will be
interpreted relative to the build tree directory corresponding to the
current source directory.  Note that MAIN_DEPENDENCY is completely
optional and is used as a suggestion to visual studio about where to
hang the custom command.  In makefile terms this creates a new target
in the following form:

::

 OUTPUT: MAIN_DEPENDENCY DEPENDS
         COMMAND

If more than one command is specified they will be executed in order.
The optional ARGS argument is for backward compatibility and will be
ignored.

The second signature adds a custom command to a target such as a
library or executable.  This is useful for performing an operation
before or after building the target.  The command becomes part of the
target and will only execute when the target itself is built.  If the
target is already built, the command will not execute.

"
Class {
	#name : #CMakeAddCustomCommandOutput,
	#superclass : #CMakeTemplate,
	#instVars : [
		'outputs',
		'commandsandargs',
		'depends',
		'implicitdepends',
		'workingdir',
		'comment',
		'verbatim',
		'append',
		'maindependency'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #accessing }
CMakeAddCustomCommandOutput >> append [

	^ append
]

{ #category : #accessing }
CMakeAddCustomCommandOutput >> commandsandargs [
	self flag:'tty'. "see CMakeListAppend>>elements for inject method to use If I have doublequotes are needed. "
 	^ String streamContents: [:stream | commandsandargs asStringOn: stream delimiter: ' ' ]
]

{ #category : #accessing }
CMakeAddCustomCommandOutput >> comment [
	^ 'COMMENT "' , comment,'"'
]

{ #category : #accessing }
CMakeAddCustomCommandOutput >> depends [
	^ String streamContents: [:stream | depends asStringOn: stream delimiter: ' ' ]

]

{ #category : #accessing }
CMakeAddCustomCommandOutput >> implicitdepends [
	^ String streamContents: [:stream | implicitdepends asStringOn: stream delimiter: ' ' ]

]

{ #category : #'initialize-release' }
CMakeAddCustomCommandOutput >> initialize [

	self 
		initializeOutputs;
		initializeCommandsAndArgs;
		initializeDepends;
	 	initializeImplicitDepends.

	maindependency:= 'MAIN_DEPENDENCY'.
	workingdir := ' [WORKING_DIRECTORY dir]'.
	comment :='[COMMENT comment]'.
	verbatim :='[VERBATIM]'.
	append:='[APPEND]'.
	self content:'
  ADD_CUSTOM_COMMAND(OUTPUT  '
							,self outputs, '  '	
							, self commandsandargs , '  ' 
							, self maindependency, ' '
							, self depends , '  ' 
							, self implicitdepends, ' '
							, self workingdir , ' ' 
							, self comment, '  ' 
							, verbatim , '  ' 
							, append ,  ')'.


]

{ #category : #'initialize-release' }
CMakeAddCustomCommandOutput >> initializeCommandsAndArgs [
	commandsandargs := OrderedCollection new.
	commandsandargs
		addLast:('COMMAND command1 [ARGS] [args1...]');
		addLast:('[COMMAND command2 [ARGS] [args2...] ...]').

]

{ #category : #'initialize-release' }
CMakeAddCustomCommandOutput >> initializeDepends [
	depends := OrderedCollection new.
	depends 
		addLast:('[DEPENDS' );
		addLast:('[depends...]' );
		addLast:(']' ).
]

{ #category : #'initialize-release' }
CMakeAddCustomCommandOutput >> initializeImplicitDepends [
	implicitdepends := OrderedCollection new.
	implicitdepends 
		addLast:('[ [IMPLICIT_DEPENDS <lang1> depend1' );
		addLast:('[ [<lang2> depend2]' );
		addLast:('...]' ).
]

{ #category : #'initialize-release' }
CMakeAddCustomCommandOutput >> initializeOutputs [
	outputs := OrderedCollection new.
	outputs 
		addLast:('output1' );
		addLast:('[output2' );
		addLast:('...]' ).
		
]

{ #category : #accessing }
CMakeAddCustomCommandOutput >> maindependency [

	^ maindependency
]

{ #category : #accessing }
CMakeAddCustomCommandOutput >> output: anObject commandsandargs: cObject comment: cString [
	outputs:= anObject.
	commandsandargs:= cObject.
	depends:=OrderedCollection new.
	implicitdepends :=OrderedCollection new.
	maindependency:= ''.
	workingdir := ''.
	comment := cString.
	verbatim :=''.
	append:=''.
	self content:'  add_custom_command(OUTPUT  '
							,self outputs, '  '	
							, self commandsandargs , '  ' 
							, self maindependency, ' '
							, self depends , '  ' 
							, self implicitdepends, ' '
							, self workingdir , ' ' 
							, self comment, '  ' 
							, verbatim , '  ' 
							, append ,  ')'.

]

{ #category : #accessing }
CMakeAddCustomCommandOutput >> output: anObject commandsandargs: cObject maindependency: mdObject implicitdepends: idObject workingdir: wString  comment: cString verbatim: vString append: aString [
	output:= anObject.
	commandsandargs := cObject .
	maindependency := mdObject.
	implicitdepends := idObject.
	workingdir := wString.
	comment:=cString.
	verbatim:= vString.
	append := aString.
self content:'  add_custom_command(OUTPUT  '
							,self outputs, '  '	
							, self commandsandargs , '  ' 
							, self maindependency, ' '
							, self depends , '  ' 
							, self implicitdepends, ' '
							, self workingdir , ' ' 
							, self comment, '  ' 
							, verbatim , '  ' 
							, append ,  ')'.
]

{ #category : #accessing }
CMakeAddCustomCommandOutput >> outputs [
	^ String streamContents: [:stream | outputs asStringOn: stream delimiter: ' ' ]
]

{ #category : #accessing }
CMakeAddCustomCommandOutput >> verbatim [

	^ verbatim
]

{ #category : #accessing }
CMakeAddCustomCommandOutput >> workingdir [

	^ workingdir
]
