"
A CMakePluginInternal is what Ian Piumarta wrote in trunk/platforms/unix/cmake/PlatformInternal.cmake. 

I .look like this in the original:

MESSAGE (""${@plugin@_definitions}"")
ADD_DEFINITIONS (-DSQUEAK_BUILTIN_PLUGIN=1 ${@plugin@_definitions})
LINK_DIRECTORIES (${@plugin@_link_directories})
INCLUDE_DIRECTORIES (${@plugin@_include_directories}
    ${bld}
    ${src}/vm
    ${cross}/vm
    ${src}/plugins/@plugin@
    ${unix}/vm
    ${unix}/plugins/@plugin@
    ${unix}/@plugin@
    ${cross}/plugins/@plugin@
)

ADD_LIBRARY (@plugin@ STATIC @plugin_sources@)

"
Class {
	#name : #CMakePluginInternal,
	#superclass : #CMakeTemplate,
	#instVars : [
		'plugindefinitions',
		'pluginlinkdirectories',
		'pluginincludedirectories',
		'bld',
		'src',
		'cross',
		'srcplugins',
		'unixvm',
		'unixplugins',
		'unix',
		'crossplugins',
		'plugin',
		'pluginsources'
	],
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'as yet unclassified' }
CMakePluginInternal >> initialize [
	self content:'
  SET (version  \"1.2.3.4\")
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\1" major   ${version})
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\2" minor   ${version})
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\3" patch   ${version})
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\4" release ${version})
'
]
