Class {
	#name : #CMakeVMMakerSqueakDeveloperHelp,
	#superclass : #CMakeVMMakerSqueakHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> availableBuilds [
	^HelpTopic
		title:'configuring available build types'
		contents:
'The purpose of this method is to present the end user with the avaiable buildTypes for a configuration category. when they invoke a Builder like so:

	SqueakLinux32X86Builder availableBuildTypesFor: #Linux32x86SqueakStackV3Config

Since builds are sometimes not available and/or under development  a developer may wish to restrict what build types are avaiable for a configurations Builder by modifying the configuration''s "availableBuilds" method.

The default is all buildTypes: 
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildConfigurations

You can display no buildTypes with:
	^SqueakCMakeVMMakerAbstractBuilder  default  noBuildConfigurations.

or you can customize it like so:
	^(SqueakCMakeVMMakerAbstractBuilder  default  allBuildConfigurations 
			copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))  


'
]

{ #category : #accessing }
CMakeVMMakerSqueakDeveloperHelp class >> bookName [ 
	^'CMakeVMMakerSqueak Developer''s Guide'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> cMakeMacros [
	^HelpTopic
		title:'configuring cmake macros'
		contents:
'
SystemNavigation default browseMethodsWhoseNamesContain: ''cMakeMacros''
'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> excludeFromBuild [
	^HelpTopic
		title:'Excluding a Configuration From Builds'
		contents:
' The "excludeFromBuild" method in a concrete configuration can be manually toggled to exclude or include a configuration from being built by a builder.

	excludeFromBuild
		"over-ride to exclude yourself from a build"
		^false


  Be careful witht he logic. True excludes the configuration. False includes the configuration
'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> executableName [
	^HelpTopic
		title:'set executable name'
		contents:
'
In your concrete configuration, set the exectuable name in method "executableName"

SystemNavigation default browseMethodsWhoseNamesContain: ''executableName''


'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> extraPluginSettings [
	^HelpTopic
		title:'set extra plugin settings'
		contents:
'In your concrete configuration configure "extraPluginSettings"

SystemNavigation default browseMethodsWhoseNamesContain: ''extraPluginSettings''


look at the differences in the concrete implementations, especially by platform type.	

'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> igorStasenkoDesign [
	^HelpTopic
		title:'Igor Stasenko''s CMakeVMMaker Design for pharo'
		contents:
'CMakeVMMakerSqueak extends Igor Stasenko''s pharo work in CMMakeVMMaker. 

For this reason, a discussion of the Pharo design is apropos as it will support later discussion about CMakeVMMakerSqueak

TODO: finish me


'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> organizationOfBuildersConfigs [
	^HelpTopic
		title:'Organization Of Builder and Configuration Classes'
		contents:
'
The CMakeVMMakerSqueak Builders and Configurations are organized to mirror  Eliot''s GNU build system organization.

The intent is to reduce brain cycles translating from the computer''s directory layout to what you see in CMakeVMMakerSqueak by providing a (nearly) one-to-one correspondence.

Eliot has named build directories in Cog/ svn (oscogvm directory in this system) by the convention
build.[OperatingSystem].[VMWordSize].[Processor Architecture]. For  example: build.macosx32x86 

Under each build.[OperatingSystem].[VMWordSize].[Processor Architecture]  directory are subdirectories for each
[Language][VM][MemoryManager]. example newspeak.sista.spur.

The permutations of [Language][VM][MemoryManager] currently are: 

[newspeak | squeak]. [cog | sista | stack]. [spur | v3] or 2! x 3! x 2!  which is  between 12 and eleventy billion permutations 

Similarly, in CMakeVMMakerSqueak,  Categories containing Configurations are organized by CMakeVMMakerSqueak-[OperatingSystem][VMWordSize][Processor][etc]

Configuration classes within a CMakeVMMakerSqueak-[OperatingSystem][VMWordSize][Processor][etc] are Named:
[[Squeak] | [] ][Language][VM][MemoryManager][etc]Config and correspond with the 12 permutations

When CMakeVMMakerSqueak generates build or products , it prefaces Eliot''s naming convention with a ''cmake.''

for example builds take place in:  cmake.build.linux.32.x66/squeak.cog.spur
and output is placed in cmake.products. for example: oscogvm/cmake.products/squeak.cog.v3.noGL/

Builders manage Configurations and Builds for a particular [Language][VM][MemoryManager]  category.
THERE IS A ONE-TO-ONE CORRESPONEDENCE between aConcreteBuilder>configurationsCategory and the Smalltalk Category name. 
If you change one, you must change the other in order for the Builder to manage that configuration.

example: SqueakMacOSBuilder configurationsCategory



Semi-Kludgey--yes, but an acceptable kludge in my estimation.

'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> overview [
	^HelpTopic
		title:'CMakeVMMaker in a couple of sentences.'
		contents:
'The heart of the package is CMakeGenerator and its two subclasses CMakeVMGenerator and CMakePluginGenerator.

CMakeGenerator collects information from CPlatformConf, CMThirdpartyLibrary and InterpreterPlugins and writes it out to CMake files and associated directories. 

From there, the user invokes cmake and make using a generated build.sh script.

The programmer directs the flow of the generator by coding a subclass of CPlatformConf, setting it up correctly and asking it to generate itself. 

The configuration then invokes the CMakeVMGenerator passing itself as an argument. 

The VMGeneratator extracts the information and utilizes VMPluginGenerator to generate plugin stuff, the CPlatformConf to generate other stuff and CMThirdPartyLibrary''s to generate other stuff. 

The end result is a CMake evironment that is set up to correctly build a VM
'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> pages [
	^#(overview prerequisites igorStasenkoDesign plugins organizationOfBuildersConfigs availableBuilds excludeFromBuild executableName extraPluginSettings preferredIncludes setExtraTargetProperties cMakeMacros scratch)
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> plugins [
	^HelpTopic
		title:'setting up defaultInternalPlugins and defaultExternalPlugins'
		contents:
'
bad mojo with plugins.int plugins.ext in GNU and plugin names in CMakeVMMaker(Squeak)

|s|
Transcript clear.
s:=SortedCollection new.
InterpreterPlugin allSubclassesDo:[:p|
	p moduleName = ''SqueakSSL''                    "<-------Text from plugins.int or plugins.ext"
		ifTrue:[Transcript show:p name;cr].
	s add: (p moduleName)].


'


]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> preferredIncludes [
	^HelpTopic
		title:'configuring preferred includes'
		contents:
'
SystemNavigation default browseMethodsWhoseNamesContain: ''preferredIncludes'' 
'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> prerequisites [
	^HelpTopic
		title:'Pre-requisits'
		contents:
'TODO: write me


'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> scratch [
	^HelpTopic
		title:'Program Flow'
		contents:
'
Create a new configuration
add external/internal plugins
generateSources
	verifies Sources file in place
	prepares CogRTLOpcodes/CogIA32Compiler/StackInterpreter depending on configuration used
	initializes/prepares VMMaker
	asks VMMaker to generateEntire while intercepting notifications and deprecation warnings.

generate 
	a Configuration passes itself to a CMakeVMGeneratorForSqueak
	an output  writeStream is opened
	ask the config to set global options on the Generator. Stuff like (maker set: ''CMAKE_C_COMPILER'' to: ''/usr/bin/gcc'')
	"We are setting up a file here"
	print the header
	set project name
	set system specific global options after system is known (all existing implementations are XCode CMAKE_OSX_SYSROOT etc)
        set up  directories.cmake  content with all the topDir,srcDir etc in the Generator
	9. is troubling. set''s CMAKECONFIGURATIONTYPES to Release
	set up preferedIncludes. This one is important as it is config specific
	set up standardIncludes. This one is important as it is config specific
	add CompilerFlag Definitions. This is where customization among release, debug, assert flags are set.
	extraVMSettings             . more custom stuff for the VM. The generateConfigH issue resides here
        put this string  ''add_executable(Squeak  ${coreSources} ${crossVMSources} ${platformVMSources} ${extraSources})''
	generate and store internally  the internal/external plugin CMakePluginGeneratorForSqueak . Each of these has its own Stream etc.for CMake
        processThirdPartyLibraries This loops through the CMakeVMMaker-Libs that are associated with this config. these libs generate their own spiel
	                           libraries can be downloaded here?
	processPlugins   pretty complicated as well.
	setExtraTargetProperties   <---this is important. It is used by "most" configs and sets compile flags, etc. This will be messed up for cut-n-paste I did .
	self cmd: ''target_link_libraries'' params: self moduleName , '' ${LINKLIBS}''.  just puts in doc
        postBuildActions  <--used by Mac configs need to clean this up.
	saveFile  "Writes CMakeLists.txt"
	generateBuildScript "this is config specific"
	

----------------------------------------------------------------------------------
SqeuakCogMTBuilder buildUnix32
		self new buildUnix32
>>>		     SqueakCogMTUnixConfig new.   (CPlatformConfig initialize
		     			   	  		   super initialize
								   generateForRelease = true.
				addExternalPlugins#();
				addInternalPlugins#();
1.				generateSources;
2. 				generate.







1 SqueakCogMTUnixConfig generateSources
 CPlatformConfig generateSources
	"Generate whole VM + plugins sources"
	| maker |

	self validateSourcesPresent.  
	self prepareForGeneration.
	
	"suppress questions and deprecation warnings during generation "
	[[
		
		maker := self prepareVMMaker.
	
		maker interpreterClass: self interpreterClass.
		self cogitClass ifNotNil: [:cg | 
			maker cogitClass: cg.
			cg initializeWithOptions: (maker instVarNamed: ''optionsDictionary'')
		].
		
		maker generateEntire

	] on: ProvideAnswerNotification do: [:ex | ex resume: true ]]
	on: Deprecation do: [:ex | ex resume ].
	
	

2. generate 
	self generatePluginsList. writes PLUGINS.txt file from pluginsTemplate
	self generateLicense.     writes LICENSE.txt file from licenseTemplate
3.->	^CMakeVMGeneratorForSqueak generate:self    pass myself (a config) to a VMGenerator

CMakeVMGenerator generate
3. generate
	| intPlugins extPlugins |
			
	output := String new writeStream.
	
4.	config setGlobalOptions: self.
	
	self 
5		printHeader;
6		project: config executableName.

7.	config setGlobalOptionsAfterDetermineSystem: self.

8.	config setupDirectories: self.
	
9.	self message: ''${CMAKE_MODULE_PATH}''.
	self set: ''CMAKE_CONFIGURATION_TYPES'' to: ''Release''.

10.	config preferredIncludes 
		do: [ :each | self includeDirectories: each ].
	self includeDirectories: self includeDirs.	
11	config standardIncludes 
		do: [:each | self includeDirectories: each ].

12	self addDefinitions: config compilerFlags.

13.	config extraVMSettings: self.
	
14	self puts: ''add_executable('' , config executableName, '' '', config executableType, '' '' , self sources , '')''.
	
15	intPlugins := self generatePluginConfigs: config internalPlugins internal: true.  <---this area is complicated, but it generates Plugin files
	extPlugins := self generatePluginConfigs: config externalPlugins internal: false.

16	self processThirdpartyLibraries.
	
17	self processPlugins:  intPlugins, extPlugins.

18.	config setExtraTargetProperties: self.    <---this is very important
	
	self cmd: ''target_link_libraries''
		params: self moduleName , '' ${LINKLIBS}''.

19.	config postBuildActions: self.
	
20	self saveFile.
	self generateBuildScript. build.sh




4. setGlobalOptions: maker

	"set any CMake global options, before declaring a project in cmake file"
	
	maker set: ''CMAKE_C_COMPILER'' to: ''/usr/bin/gcc''.
	maker set: ''CMAKE_CXX_COMPILER'' to: ''/usr/bin/g++''.

5. printHeader
	
	self puts: ''# This is automatically generated file using '', self configurationName, '' on '',
		Date current asString, '' '' , Time current asString;
		puts: ''cmake_minimum_required(VERSION 2.6.2)''



6 project: aProjectName
	self cmd: ''project'' qparams: aProjectName{

	     cmd: cmdName qparams: aString
	     	"quoted params"
		output nextPutAll: cmdName;
		nextPutAll: ''("'';
		nextPutAll: aString;
		nextPutAll: ''")'';
		cr
        }

7.SqueakIPhoneSqueakStackV3Config setGlobalOptionsAfterDetermineSystem: maker   <---here is a representative example
	self setGlobalOptions: maker.	
	maker 
		set: ''CMAKE_OSX_SYSROOT'' 
		to: (''/Applications/Xcode.app/Contents/Developer/Platforms/{1}.platform/Developer/SDKs/{1}{2}.sdk''
			format: { self targetDevice. self sdkVersion })

8. config setupDirectories:self
   this creates directories.cmake with all the top/build/etc directories

9. this is troubling, sets CMAKE_CONFIGURATION_TYPES to ''Release''.



10. preferredIncludes
	^ #(
	''${buildDir}/''
	''${platformsDir}/iOS/vm/iPhone'' "config.h is here. Why???"
	)

	this gets put int CMakeGenerator{

	     includeDirectories: aString
	     	 ^self cmd: ''include_directories'' params: aString


11. standardIncludes <---this one is important


12. addDefinitions:config compilerFlags
    compilerFlags 
	| releaseFlags |
	
	releaseFlags := self isGenerateForRelease 
		ifTrue: [ self compilerFlagsRelease ]
		ifFalse: [ self compilerFlagsDebug ].
		
	^ String streamContents: [ :stream |
		((self commonCompilerFlags, releaseFlags)
			asStringOn: stream 
			delimiter: '' '' )]


13. extraVMSettings: maker    very customizable method. 
	| versionC |
	self generateConfigH.  <---the issue Eliot raised. 
	
	
	"output a fake version.c file"
	
	self write:
''int vm_serial= 1;
char *vm_date= "<HERE IS SUPPOSED TO BE THE DATE>";
char *cc_version= "<HERE IS SUPPOSED TO BE gcc VERSION>";
char *ux_version= "<FAKE FROZEN VERSION FOR DEBUGGING PURPOSES>";
''
	toFile: ''version.c''.


14.  ''add_executable(Squeak  ${coreSources} ${crossVMSources} ${platformVMSources} ${extraSources})''



15. generatePluginConfigs: plugins internal: bool
	"Answers a collection of CMakePluginGenerator instances"
	
	^ plugins collect: [:each | | plugin |
		plugin := Smalltalk at: each.
		plugin generateFor: self internal: bool.   <---InterpreterPlugin method added by CMakeVMMaker 
	].

	generateFor: aCMakeVMGenerator internal: aBoolean 
		^ aCMakeVMGenerator 
			generatePlugin: self 
			internal: aBoolean
			extraRules: nil
	
	so, for each plugin in the generator, invoke my generator method generatePlugin: internal:extraRules:
	    THIS invokes CMakePluginGeneratorForSqueak new
	     	    generate: aPlugin for: aCMakeVMGenerator internal: aBoolean extraRules: aBlock
		    	    doNotGenerate := false.
			    internal := aBoolean.
			    plugin := aPlugin.
			    vmGen := aCMakeVMGenerator.
			    extraRules := aBlock.
		            ^ self generate{

						| name |
						output := String new writeStream.

						name := plugin moduleName.
					#(	vmGen config setGlobalOptions: self.

						self 
							printHeader;
							project: name;
							"include directories generated for build"
							include: ''../directories.cmake''.

						self set: ''CMAKE_CONFIGURATION_TYPES'' to: ''Release''.
					).

						self message: (internal ifTrue: [ ''Adding internal plugin: ''] ifFalse: [''Adding external plugin: ''])  , name.

						self 
							set: #pluginName toString: name;
							set: #pluginSrc toString: ''${srcPluginsDir}/'', name;
							set: #pluginCross toString: ''${crossDir}/plugins/'', name;
							set: #pluginPlatform toString: ''${targetPlatform}/plugins/'', name.

						"clear LINKLIBS variable"
						self set: #LINKLIBS to: ''.		

						internal 
							ifTrue: [ self puts: ''add_definitions(-DSQUEAK_BUILTIN_PLUGIN)''].

						self addSources: { name , ''.c'' } prefixed: ''${pluginSrc}/''.

						" default include directories for plugin "
						self includeDirectories: ''${pluginSrc} ${pluginCross} ${targetPlatform}/plugins/${pluginName}''.

						"Not needed because there are already there (inherited from main configuration)"
						"self addDefinitions: vmGen config compilerFlags."

						" perform config''s configureXYZ: message to apply per-plugin custom rules, if any "

						vmGen config configurePlugin: plugin with: self.

						extraRules ifNotNil: [ extraRules value: self ].

						" generate a static lib for internal plugin, or shared for external"
						internal ifTrue: [
							self cmd: ''add_library'' params:  name , '' STATIC ${sources}''.
						] ifFalse: [
							self cmd: ''add_library'' params: name , '' SHARED ${sources}''.

						"	self cmd: ''set_property'' params: ''TARGET '' , name , ''PROPERTY LINK_FLAGS -bundle''"
						].

						vmGen config extraPluginSettings: self.

						self isExternal ifTrue: [
							self cmd: ''target_link_libraries''
								params: self moduleName , ''${LINKLIBS}''.
							].

						" see senders of #linkFlags "
						self 
							cmd: ''set_property'' 
							params: ''TARGET'', name, ''PROPERTY LINK_FLAGS "${linkFlags}''.

						"set dependencies"
						self puts: ''IF ('',self moduleName , ''_dependencies)''.

						self cmd: ''add_dependencies''
							params: name , ''${'', self moduleName , ''_dependencies}''.

						self puts: ''ENDIF ('',self moduleName , ''_dependencies)''.
						self saveFile.


}
		 	    





16. processThirdpartyLibraries

	config thirdpartyLibs do: [:each |
		each generateFor: self ]{
			      generateFor: aVMGenerator

				      | libDir stream contents |

				      vmGen := aVMGenerator.

				      gen := CMakeGenerator new
					      output: (String new writeStream).

				      libDir := (aVMGenerator thirdpartyDir / self canonicalName) ensureDirectory.

				      stream := String new writeStream.

				      self generate.

				      stream nextPutAll: (vmGen config fixLineEndsOf: gen output contents).

				      contents := stream contents. 

				      (self isFile: (libDir asFileReference / gen outputFileName) fullName hasContents: contents) ifFalse: [
					      "contents changed, update the file. Because fucking cmake will force rebuild everything if we change its modification date
					      without changing its contents"
					      (FileStream forceNewFileNamed: (libDir asFileReference / gen outputFileName)) nextPutAll: contents; close.
					      ].


				      vmGen addSubdirectory:  vmGen thirdpartyDirName , ''/'' , self canonicalName.
				      self defineGlobalTargets.


			      }



17 processPlugins: pluginGenerators
	| libs libDeps |

	libs := OrderedCollection new.
	libDeps := Dictionary new.
	pluginGenerators do: [:gen |
		gen doNotGenerate ifFalse: [
			gen isInternal 
				ifTrue: [
					libs add: gen plugin moduleName ]
				ifFalse: [
					"make main module to depend on external plugin, just to make sure it is built 
					 before main module built"
					self 
						cmd: ''add_dependencies'' 
						params: config executableName, '' '' , gen plugin moduleName ].
				gen externalDependencies 
					ifNotEmpty: [ :deps |
						libDeps 
							at: gen plugin moduleName
							put: (deps fold: [ :a :b | a, '' '', b ]) ].
			self addSubdirectory: gen plugin moduleName ] ].

	self cmd: ''target_link_libraries'' params:  config executableName , '' '' ,
		(libs inject: '' into: [:res :ea | res, '' '' , ea ]).

	libDeps keysAndValuesDo: [ :moduleName :dependencies |
		self 
			cmd: ''add_dependencies'' 
			params: moduleName, '' '', dependencies ].  

	self generateExportsH: libs.


18 setExtraTargetProperties: maker

	"maker setTargetProperties: ''LINK_FLAGS ""''."
		
	maker puts: ''set_source_files_properties( ${srcVMDir}/cogit.c PROPERTIES 
		COMPILE_FLAGS "-O1 -fno-omit-frame-pointer -momit-leaf-frame-pointer")''.
		
		
	maker 
		cmd: ''set_source_files_properties''
		params: ''${targetPlatform}/vm/sqUnixHeartbeat.c PROPERTIES 
		COMPILE_FLAGS "-O1 -fno-omit-frame-pointer"''.
						
	maker linkDirectories: ''${CMAKE_FIND_ROOT_PATH}/usr/lib/arm-linux-gnueabihf/''.
	
	maker addExternalLibraries: 
		#(
			''m''  "math lib"
			''dl''  "dynamic loader"
			''pthread'' "posix threads" 
		).
		
	maker set: ''EXECUTABLE_OUTPUT_PATH'' toString: self outputDir fullName.
	self addVMDrivers: maker.


19. postBuildActions: gen

	" override to add custom rules after all targets is defined "
	
	self write: self fixLibsTemplate toFile: ''fix_libs.cmake''.
	
	
	gen
		set: #bundlePath toString: ''${outputDir}/'', self executableName, ''.app'';
		set: #pluginsRelPath toString: ''@executable_path/Plugins''.

	gen
		puts: ''
		INSTALL(CODE "
			set(externalModulesDir \"${externalModulesDir}\")
			set(bundlePath \"${bundlePath}\")
			set(pluginsRelPath \"${pluginsRelPath}\")
			
			include(fix_libs.cmake)
		")''
			
"					FILE(GLOB_RECURSE bLibs /${externalModulesDir}/*.*)
"




'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> setExtraTargetProperties [
	^HelpTopic
		title:'set extra target properties'
		contents:
'
SystemNavigation default browseMethodsWhoseNamesContain: ''setExtraTargetProperties'' 
'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> settingCompilerFlags [
	^HelpTopic
		title:'Setting Compiler Flags for a build'
		contents:
'Each buildType (SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo) may require custom compiler flags.

Trait TCPlatformConfigForSqueak compilerFlags method provides a method lookup that is invoked for a specific buildType.
These methods are named compilerFlagsXYZ corresponding to the buildTypes displayed above.

In the compilerFlagsXYZ method for your concrete configuration, you set the internal state of your configuration.

Note: there are two legacy internal states from CPlatformConfig in CMakeVMMaker for pharo "compilerFlagsDebug" and "compilerFlagsRelease" that are invoked
for backwards compatibility.

'
]
