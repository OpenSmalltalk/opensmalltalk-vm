"
A CMakeMessageTemplate looks like

	MESSAGE([TYPE] ""foo"")

from the cmake help
make --help-command message
cmake version 2.8.12
  message
       Display a message to the user.

         message([STATUS|WARNING|AUTHOR_WARNING|FATAL_ERROR|SEND_ERROR]
                 ""message to display"" ...)

       The optional keyword determines the type of message:

         (none)         = Important information
         STATUS         = Incidental information
         WARNING        = CMake Warning, continue processing
         AUTHOR_WARNING = CMake Warning (dev), continue processing
         SEND_ERROR     = CMake Error, continue processing,
                                       but skip generation
         FATAL_ERROR    = CMake Error, stop processing and generation

       The CMake command-line tool displays STATUS messages on stdout and all
       other message types on stderr.  The CMake GUI displays all messages in
       its log area.  The interactive dialogs (ccmake and CMakeSetup) show
       STATUS messages one at a time on a status line and other messages in
       interactive pop-up boxes.

       CMake Warning and Error message text displays using a simple markup
       language.  Non-indented text is formatted in line-wrapped paragraphs
       delimited by newlines.  Indented text is considered pre-formatted.

"
Class {
	#name : #CMakeMessage,
	#superclass : #CMakeTemplate,
	#instVars : [
		'optionalkeyword',
		'message'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #'initialize-release' }
CMakeMessage >> initialize [
	optionalkeyword:='AUTHOR_WARNING'.
	message := 'Dude! put your message here'.
	self content:'
  
MESSAGE(', optionalkeyword, ' "', message,'")'
]

{ #category : #'as yet unclassified' }
CMakeMessage >> message: mString [
	self optionalkeyword:'' message:mString.

]

{ #category : #'as yet unclassified' }
CMakeMessage >> optionalkeyword: oString message: mString [
	optionalkeyword:=oString.
	message := mString.
	self content:'
MESSAGE(', optionalkeyword, ' "', message,'")'
]
