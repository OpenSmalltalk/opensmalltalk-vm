"
A Linux64x86w32BitConfig is an Abstract base class that provides common information for my subclasses.
I am not meant to be built.

I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakLinux64x86w32CompatBuilder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	enableMessageTracking: true;
	generateByTemplate.



HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp



"
Class {
	#name : #SqueakIOSConfig,
	#superclass : #SqueakUnixConfig,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #cmake }
SqueakIOSConfig >> availableBuildTypes [
 	 ^SqueakCMakeVMMakerAbstractBuilder  default  noBuildTypes
"

subclasses should use

  ^super allBuildTypes copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   "
	

]

{ #category : #'cmake buildType redirects' }
SqueakIOSConfig >> coreSourcesBuild [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #'cmake buildType redirects' }
SqueakIOSConfig >> coreSourcesBuildMultiThreaded [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'cointerpmt.c'
		)
]

{ #category : #plugins }
SqueakIOSConfig >> defaultExternalPlugins [
	"add your external plugins here"
	^ #()


]

{ #category : #plugins }
SqueakIOSConfig >> defaultInternalPlugins [
	"add your internal plugins here"
	^ #()
]

{ #category : #cmake }
SqueakIOSConfig >> dirBuildPlatform [
	^self dirMacOS
]

{ #category : #cmake }
SqueakIOSConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
SqueakIOSConfig >> executableName [
	"AbstractBaseClass configurations are not meant to be executable"
	^ self vmIShouldNotBeHereExecutableName
]

{ #category : #'cmake buildType redirects' }
SqueakIOSConfig >> externalPluginsBuild [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
SqueakIOSConfig >> extraPluginSettingsBuild: aMaker [	
     self flag: 'tty'. "I have no idea what this stuff is for. DO NOT take it as the work of somebody who does (:" 
	aMaker templates 
		addLast:((CMakeSet new) variable:'CMAKE_OSX_ARCHITECTURES' value:'i386');
	     addLast:((CMakeSetTargetProperties new) 
			target: aMaker moduleName 
			propertiesandvalues: (OrderedCollection with: 'COMPILE_FLAGS   "-include \"', (self buildDir / self prefixHeaderFileName) fullName, '\""' )) .
	aMaker isExternal 
		ifTrue:[
			aMaker templates 
				addLast:((CMakeSet new) variable:'LIBRARY_OUTPUT_PATH' value:'${outputDir}');
				addLast:((CMakeSet new) variable:'EXECUTABLE_OUTPUT_PATH' value: self outputDir fullName);
				addLast:((CMakeListAppend new) list: 'linkFlags' elements:  (OrderedCollection with: '-undefined dynamic_lookup' ))].
	aMaker templates
		addLast:((CMakeSetTargetProperties new) 
			target: aMaker moduleName 
			propertiesandvalues: (OrderedCollection with: 'GCC_PREFIX_HEADER   ${buildDir}/' , self executableName , '_Prefix.pch' )) .




	

]

{ #category : #'source files' }
SqueakIOSConfig >> extraSources [
	" mac VM using some unix sources"
	^ 
	'${platformsDir}/unix/plugins/SocketPlugin/sqUnixSocket.c 
	${platformsDir}/unix/vm/aio.c 
	${platformsDir}/unix/plugins/AsynchFilePlugin/sqUnixAsynchFile.c
	${platformsDir}/unix/vm/sqUnixHeartbeat.c
	${platformsDir}/unix/vm/sqUnixVMProfile.c
	${platformsDir}/unix/vm/sqUnixThreads.c
	${resources}'
]

{ #category : #'as yet unclassified' }
SqueakIOSConfig >> fixLibsTemplate [
^
'include(GetPrerequisites)

message("Fixing library references in: ${externalModulesDir}")

FILE(GLOB libs  "${externalModulesDir}/*.dylib")

set(all_imports "")

foreach(lib ${libs})
	get_filename_component(libName "${lib}" NAME)
	list(APPEND libNames "${libName}")
	
	set(prereq "")
	get_prerequisites(${lib} prereq 1 0 "${bundlePath}" "")


	list(APPEND all_imports ${prereq})

endforeach(lib)

list(REMOVE_DUPLICATES all_imports)
set(replacements "")
message ( "Found imports: ${all_imports} " )

foreach(import ${all_imports})
	foreach(lib ${libNames})
		set(match "^.*${lib}$")
		if(import MATCHES ${match})
			set(replacement "${pluginsRelPath}/${lib}")
			message("Will replace: ${import} with: ${replacement}")
			set(replacements ${replacements} "-change" "${import}" "${replacement}")
		endif(import MATCHES ${match})
	endforeach(lib)
endforeach(import)

foreach(lib ${libs})
	get_filename_component(name ${lib} NAME)
	set(fixedName "${pluginsRelPath}/${name}")
	message("Fixing up: ${name}")

 	execute_process(COMMAND install_name_tool -id "${fixedName}" "${lib}" )

 	execute_process(COMMAND install_name_tool  ${replacements} ${lib} )

endforeach(lib)
'


]

{ #category : #'cmake buildType redirects' }
SqueakIOSConfig >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
SqueakIOSConfig >> preferredIncludesBuild [
	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: (self class name), ' preferredIncludesBuild' )
	].
	templates
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${targetPlatform}/plugins/B3DAcceleratorPlugin')).

	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_PATH =  ${CMAKE_INCLUDE_PATH}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_SYSTEM_INCLUDE_PATH =  ${CMAKE_SYSTEM_INCLUDE_PATH}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES = ${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES =  ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_FIND_ROOT_PATH_MODE_INCLUDE =  ${CMAKE_FIND_ROOT_PATH_MODE_INCLUDE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_FIND_ROOT_PATH_MODE_INCLUDE =  ${CMAKE_INCLUDE_CURRENT_DIR}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_CURRENT_DIR_IN_INTERFACE =  ${CMAKE_INCLUDE_CURRENT_DIR_IN_INTERFACE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_DIRECTORIES_BEFORE =  ${CMAKE_INCLUDE_DIRECTORIES_BEFORE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE =  ${CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE}' )
	].
]

{ #category : #'cmake buildType redirects' }
SqueakIOSConfig >> standardIncludesBuild [ 
	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: (self class name), ' standardIncludesBuild' )
	].
	templates
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/SerialPlugin'   ));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${targetPlatform}/plugins/FilePlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/FilePlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${targetPlatform}/plugins/HostWindowPlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${platformsDir}/iOS/vm/iPhone/plugins/HostWindowPlugin' ));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with:  '${crossDir}/plugins/HostWindowPlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/DropPlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/SocketPlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/SoundPlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/AsynchFilePlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${platformsDir}/unix/vm'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${platformsDir}/iOS/plugins/SoundPlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${platformsDir}/iOS/vm/OSX/plugins/SoundPlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${platformsDir}/iOS/vm/Common/Classes'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${platformsDir}/iOS/vm/OSX')).

		(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_PATH =  ${CMAKE_INCLUDE_PATH}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_SYSTEM_INCLUDE_PATH =  ${CMAKE_SYSTEM_INCLUDE_PATH}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES = ${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES =  ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_FIND_ROOT_PATH_MODE_INCLUDE =  ${CMAKE_FIND_ROOT_PATH_MODE_INCLUDE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_FIND_ROOT_PATH_MODE_INCLUDE =  ${CMAKE_INCLUDE_CURRENT_DIR}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_CURRENT_DIR_IN_INTERFACE =  ${CMAKE_INCLUDE_CURRENT_DIR_IN_INTERFACE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_DIRECTORIES_BEFORE =  ${CMAKE_INCLUDE_DIRECTORIES_BEFORE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE =  ${CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE}' )
	].
]
