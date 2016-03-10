"
Some overrides to make freetype build on windows:

Two artifacts to copy:

libfreetype.dll.a
libfreetype-6.dll

the first one is used at link time with FTPlugin to 
designate the exported symbols of .dll as well as .dll file name.

The second one is ready to use library produced by freetype makefiles.

We pass

 -march=i686

instead of

 -arch i386

to freetype configure, because MSYS GCC on windows don't understands the -arch option.

"
Class {
	#name : #CMWin32Freetype2,
	#superclass : #CMFreetype2,
	#category : #'CMakeVMMaker-Libs'
}

{ #category : #'as yet unclassified' }
CMWin32Freetype2 class >> platformName [ 
	^'win32'
]

{ #category : #'generating actions' }
CMWin32Freetype2 >> copyArtefacts [

	gen puts:
'add_custom_command(
	OUTPUT "${externalModulesDir}/${libraryFileName}"
	COMMAND cp "${ft2libInstalled}" "${externalModulesDir}"
	COMMAND cp "${ft2binInstalled}" "${externalModulesDir}"
	DEPENDS "${ft2libInstalled}"
)'
]

{ #category : #settings }
CMWin32Freetype2 >> defaultConfigurationFlags [ 
	^#(
		'CFLAGS=''-march=i686''' 
		'LDFLAGS=''-march=i686''')
]

{ #category : #'generating actions' }
CMWin32Freetype2 >> defineGlobalTargets [
	| var |
	var := self canonicalName , '_LIB'.
	vmGen set: var toString: self targetForLinking.
"
define a library as imported one
and make it depend from it's build target
"
	vmGen
		puts: 
('add_library("{1}" STATIC IMPORTED GLOBAL)
	set_target_properties("{1}" PROPERTIES IMPORTED_LOCATION "{1}")
add_dependencies("{1}" "{2}")
' format: { '${',var, '}' . self buildTarget }
).

	vmGen cmd: 'add_dependencies' params:
		vmGen moduleName , ' ' , self buildTarget
]

{ #category : #'package properties' }
CMWin32Freetype2 >> libraryFileName [
	^ 'libfreetype.dll.a'
]

{ #category : #'generating actions' }
CMWin32Freetype2 >> setVariables [
	super setVariables.
	
"add include path"
	gen 
		set: #freetype2_includeDir toString: '${installPrefix}/include';
		set: #libraryFileName to: self libraryFileName;
		set: #freetype2_location toString: '${externalModulesDir}/${libraryFileName}';
		set: #ft2config toString: '${libSourcesDir}/builds/unix/config.status';
	 	set: #ft2libInstalled toString: '${installPrefix}/lib/${libraryFileName}';
	 	set: #ft2binInstalled toString: '${installPrefix}/bin/libfreetype-6.dll'.
		
]
