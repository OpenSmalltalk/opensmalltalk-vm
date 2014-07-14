"
A CMakePluginExternal is what Ian Piumarta wrote in trunk/platforms/unix/cmake/PlatformExternal.cmake. 

I .look like this in the original:

ADD_DEFINITIONS (${@plugin@_definitions})
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

ADD_LIBRARY (@plugin@ MODULE @plugin_sources@)

TARGET_LINK_LIBRARIES (@plugin@ ${@plugin@_link_libraries})

INSTALL (TARGETS @plugin@ LIBRARY DESTINATION @plgdir@)
"
Class {
	#name : #CMakePluginExternal,
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
		'pluginsources',
		'plunklinklibraries',
		'plgdir'
	],
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'as yet unclassified' }
CMakePluginExternal >> initialize [
	self content:'
  SET (version  \"1.2.3.4\")
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\1" major   ${version})
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\2" minor   ${version})
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\3" patch   ${version})
  STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\4" release ${version})
'
]
