"
A CMakeCheckStructHasMemberTemplate looks like this:

	CHECK_STRUCT_HAS_MEMBER (""struct tm"" tm_gmtoff time.h HAVE_TM_GMTOFF)
	CONFIG_DEFINE(HAVE_TM_GMTOFF)

The CONFIG_DEFINE is a convenience additon to the CMake Module


My CMake Documentation reads:

# - Check if the given struct or class has the specified member variable
# CHECK_STRUCT_HAS_MEMBER (STRUCT MEMBER HEADER VARIABLE)
#
#  STRUCT - the name of the struct or class you are interested in
#  MEMBER - the member which existence you want to check
#  HEADER - the header(s) where the prototype should be declared
#  VARIABLE - variable to store the result
#
# The following variables may be set before calling this macro to
# modify the way the check is run:
#
#  CMAKE_REQUIRED_FLAGS = string of compile command line flags
#  CMAKE_REQUIRED_DEFINITIONS = list of macros to define (-DFOO=bar)
#  CMAKE_REQUIRED_INCLUDES = list of include directories
#
# Example: CHECK_STRUCT_HAS_MEMBER(""struct timeval"" tv_sec sys/select.h HAVE_TIMEVAL_TV_SEC)




"
Class {
	#name : #CMakeCheckStructHasMember,
	#superclass : #CMakeTemplate,
	#instVars : [
		'struct',
		'member',
		'header',
		'variable'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #accessing }
CMakeCheckStructHasMember >> header [

	^ header
]

{ #category : #accessing }
CMakeCheckStructHasMember >> header: anObject [

	header := anObject
]

{ #category : #'initialize-release' }
CMakeCheckStructHasMember >> initialize [
	struct:= 'struct'.
	member:= 'member'.
	header := 'header'.
	variable:= 'variable'.
	content:='
  CHECK_STRUCT_HAS_MEMBER (', struct, ' ', member,' ', header,' ', variable, ')
  CONFIG_DEFINE(', variable,')'
]

{ #category : #accessing }
CMakeCheckStructHasMember >> member [

	^ member
]

{ #category : #accessing }
CMakeCheckStructHasMember >> member: anObject [

	member := anObject
]

{ #category : #accessing }
CMakeCheckStructHasMember >> struct: sString member: mString header: hString variable: vString [
	struct:= sString.
	member:= mString.
	header := hString.
	variable:= vString.
	content:='
  CHECK_STRUCT_HAS_MEMBER (', struct, ' ', member,' ', header,' ', variable, ')
  CONFIG_DEFINE(', variable,')'

]

{ #category : #accessing }
CMakeCheckStructHasMember >> variable [

	^ variable
]

{ #category : #accessing }
CMakeCheckStructHasMember >> variable: anObject [

	variable := anObject
]
