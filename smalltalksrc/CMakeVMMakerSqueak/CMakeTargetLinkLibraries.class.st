"
I am a simple wrapper for the CMake target_link_libraries command.
The CMake command has many more options than I offer. If you want more, modify me or create a different template.

cmake --help-command target-link-libraries

target_link_libraries
---------------------

Link a target to given libraries.

::

 target_link_libraries(<target> [item1 [item2 [...]]]
                       [[debug|optimized|general] <item>] ...)

Specify libraries or flags to use when linking a given target.  The
named ``<target>`` must have been created in the current directory by a
command such as ``add_executable()`` or ``add_library()``.  The
remaining arguments specify library names or flags.  Repeated calls for
the same ``<target>`` append items in the order called.

If a library name matches that of another target in the project a
dependency will automatically be added in the build system to make sure
the library being linked is up-to-date before the target links. Item names
starting with ``-``, but not ``-l`` or ``-framework``, are treated as
linker flags.

A ``debug``, ``optimized``, or ``general`` keyword indicates that the
library immediately following it is to be used only for the
corresponding build configuration.  The ``debug`` keyword corresponds to
the Debug configuration (or to configurations named in the
``DEBUG_CONFIGURATIONS`` global property if it is set).  The
``optimized`` keyword corresponds to all other configurations.  The
``general`` keyword corresponds to all configurations, and is purely
optional (assumed if omitted).  Higher granularity may be achieved for
per-configuration rules by creating and linking to
:ref:`IMPORTED library targets <Imported Targets>`.

Library dependencies are transitive by default with this signature.
When this target is linked into another target then the libraries
linked to this target will appear on the link line for the other
target too.  This transitive ""link interface"" is stored in the
``INTERFACE_LINK_LIBRARIES`` target property and may be overridden
by setting the property directly.  When ``CMP0022`` is not set to
``NEW``, transitive linking is built in but may be overridden by the
``LINK_INTERFACE_LIBRARIES`` property.  Calls to other signatures
of this command may set the property making any libraries linked
exclusively by this signature private.

CMake will also propagate :ref:`usage requirements <Target Usage Requirements>`
from linked library targets.  Usage requirements of dependencies affect
compilation of sources in the ``<target>``.

If an ``<item>`` is a library in a Mac OX framework, the ``Headers``
directory of the framework will also be processed as a
:ref:`usage requirement <Target Usage Requirements>`.  This has the same
effect as passing the framework directory as an include directory.

"
Class {
	#name : #CMakeTargetLinkLibraries,
	#superclass : #CMakeTemplate,
	#instVars : [
		'target',
		'items'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #'initialize-release' }
CMakeTargetLinkLibraries >> initialize [
	target := OrderedCollection with: 'target1' with:'target2'.
	items := OrderedCollection with: 'item1' with: 'item2'.
	self content:'  target_link_libraries(', target ,'  ',  self items,')'

" target_link_libraries(<target> [item1 [item2 [...]]]
                       [[debug|optimized|general] <item>] ...)"
]

{ #category : #accessing }
CMakeTargetLinkLibraries >> items [
 	^ String streamContents: [:stream | items asStringOn: stream delimiter: ' ' ]
]

{ #category : #accessing }
CMakeTargetLinkLibraries >> target [
	^ target
]

{ #category : #accessing }
CMakeTargetLinkLibraries >> target: tString [
	target := tString
]

{ #category : #accessing }
CMakeTargetLinkLibraries >> target: tString  items: anOrderedCollection [
	target := tString.
	items := anOrderedCollection.
	self content:'  target_link_libraries(', target ,'  ',  self items,')'

]
