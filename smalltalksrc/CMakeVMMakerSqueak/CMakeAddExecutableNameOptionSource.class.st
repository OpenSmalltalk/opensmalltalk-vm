"
A CMakeAddExecutableNameOptionSource looks like this:


ADD_EXECUTABLE(name option source);

I only implement the first  idiom of the cmake command shown below


cmake --help-command add_executable
--------------

Add an executable to the project using the specified source files.

::

 add_executable(<name> [WIN32] [MACOSX_BUNDLE]
                [EXCLUDE_FROM_ALL]
                source1 [source2 ...])

Adds an executable target called ``<name>`` to be built from the source
files listed in the command invocation.  The ``<name>`` corresponds to the
logical target name and must be globally unique within a project.  The
actual file name of the executable built is constructed based on
conventions of the native platform (such as ``<name>.exe`` or just
``<name>``.

By default the executable file will be created in the build tree
directory corresponding to the source tree directory in which the
command was invoked.  See documentation of the
``RUNTIME_OUTPUT_DIRECTORY`` target property to change this
location.  See documentation of the ``OUTPUT_NAME`` target property
to change the ``<name>`` part of the final file name.

If ``WIN32`` is given the property ``WIN32_EXECUTABLE`` will be
set on the target created.  See documentation of that target property for
details.

If ``MACOSX_BUNDLE`` is given the corresponding property will be set on
the created target.  See documentation of the ``MACOSX_BUNDLE``
target property for details.

If ``EXCLUDE_FROM_ALL`` is given the corresponding property will be set on
the created target.  See documentation of the ``EXCLUDE_FROM_ALL``
target property for details.

See the ``cmake-buildsystem(7)`` manual for more on defining
buildsystem properties.

--------------------------------------------------------------------------

::

 add_executable(<name> IMPORTED [GLOBAL])

An :ref:`IMPORTED executable target <Imported Targets>` references an
executable file located outside the project.  No rules are generated to
build it, and the ``IMPORTED`` target property is ``True``.  The
target name has scope in the directory in which it is created and below, but
the ``GLOBAL`` option extends visibility.  It may be referenced like any
target built within the project.  ``IMPORTED`` executables are useful
for convenient reference from commands like ``add_custom_command()``.
Details about the imported executable are specified by setting properties
whose names begin in ``IMPORTED_``.  The most important such property is
``IMPORTED_LOCATION`` (and its per-configuration version
``IMPORTED_LOCATION_<CONFIG>``) which specifies the location of
the main executable file on disk.  See documentation of the ``IMPORTED_*``
properties for more information.

--------------------------------------------------------------------------

::

 add_executable(<name> ALIAS <target>)

Creates an :ref:`Alias Target <Alias Targets>`, such that ``<name>`` can
be used to refer to ``<target>`` in subsequent commands.  The ``<name>``
does not appear in the generated buildsystem as a make target.  The
``<target>`` may not be an :ref:`Imported Target <Imported Targets>` or an
``ALIAS``.  ``ALIAS`` targets can be used as targets to read properties
from, executables for custom commands and custom targets.  They can also be
tested for existance with the regular ``if(TARGET)`` subcommand.
The ``<name>`` may not be used to modify properties of ``<target>``, that
is, it may not be used as the operand of ``set_property()``,
``set_target_properties()``, ``target_link_libraries()`` etc.
An ``ALIAS`` target may not be installed or exported.

"
Class {
	#name : #CMakeAddExecutableNameOptionSource,
	#superclass : #CMakeTemplate,
	#instVars : [
		'executablename',
		'optionalproperty',
		'sources'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #accessing }
CMakeAddExecutableNameOptionSource >> executableName: eString optionalproperty: oString sources: anOrderedCollection [
	executablename := eString.
	optionalproperty := oString.
	sources:= anOrderedCollection.
	self content:'  add_executable(', executablename, ' ' , optionalproperty, ' ' ,self sources,')'.
	

]

{ #category : #accessing }
CMakeAddExecutableNameOptionSource >> executablename [

	^ executablename
]

{ #category : #'initialize-release' }
CMakeAddExecutableNameOptionSource >> initialize [
	executablename := 'foo'.
	optionalproperty := 'bar'.
	sources:= OrderedCollection with: 'dude'.
	self content:'
  ADD_EXECUTABLE(', executablename, ' ' , optionalproperty, ' ' ,self sources,')'.

]

{ #category : #accessing }
CMakeAddExecutableNameOptionSource >> optionalproperty [

	^ optionalproperty
]

{ #category : #accessing }
CMakeAddExecutableNameOptionSource >> sources [
	self flag:'tty'. "see CMakeListAppend>>elements for inject method to use If I have doublequotes are needed. "
	^ String streamContents: [:stream | sources asStringOn: stream delimiter: ' ' ]

]
