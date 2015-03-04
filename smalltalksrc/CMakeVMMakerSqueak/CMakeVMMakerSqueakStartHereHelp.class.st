"
A CMakeVMMakerSqueakStartHereHelp provides examples of usage for newbies.



"
Class {
	#name : #CMakeVMMakerSqueakStartHereHelp,
	#superclass : #CMakeVMMakerSqueakHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakStartHereHelp class >> bookName [
	^'Start Here'
]

{ #category : #pages }
CMakeVMMakerSqueakStartHereHelp class >> nextSteps [
	^HelpTopic
		title: 'Next Steps'
		contents:
'The next Help Topic entitled "Example Workflow" will walk you through an example workflow as executed on a GNU Linux system with the standard development tools. Macintosh and Windows dev tools will differ (N.B. tty The primary difference is that they have not been written yet (:  ).

The Help Topic entitled "Developer Guide" will explain the design of and how to add and modify the components of the CMakeVMMakerSqueak system.


'
]

{ #category : #pages }
CMakeVMMakerSqueakStartHereHelp class >> overview [
	^HelpTopic
		title: 'Overview'
		contents:
'CMakeVMMakerSqueak is a collection of tools for generating CMake files. The high-level workflow is:

1. Instruct  CMakeVMMakerSqueak to generate CMake build directories and CMake configuration files.

2. Invoke the  ''cmake'' command at the top level of the generated cmake build tree

3. CMake configures and outputs the build system files for that platform.

4. The user invokes the native build system.

5. A VM is produced under a ~/...../''cmake.platforms'' subdirectory.

The ''Example Workflow'' page in this Help book provides an example of the above workflow with minimal explanation.

In-depth explanations of the system(s), tools and how to use them, see the ''CMakeVMMaker Developer Guide'''
]

{ #category : #accessing }
CMakeVMMakerSqueakStartHereHelp class >> pages [
	^#(overview requirements nextSteps)
]

{ #category : #pages }
CMakeVMMakerSqueakStartHereHelp class >> requirements [
	^HelpTopic
		title: 'Requirements'
		contents:
'CMakeVMakerSqueak (as of 2014.12.09) depends on the Pharo package CMakeVMMaker. A (possibly out-of-sync) Monticello version is available at:

MCHttpRepository
	location: ''http://source.squeak.org/VMMaker''
	user: ''''
	password: ''''

CMakeVMMakerSqueak is available at:

MCHttpRepository
	location: ''http://source.squeak.org/VMMaker''
	user: ''''
	password: ''''

CMake is available from http://www.cmake.org. The version of CMake used as of 2014.12.09 is 2.8.12  

CMake provides a cmake_minimum_required(..) command, so newer versions should be ok.

The next Help Topic entitled "Example Workflow" will walk you through an example workflow  is presented on a GNU Linux system with the standard development tools. Macintosh and Windows dev tools will differ.


'
]
