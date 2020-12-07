project(TestLibrary)

include(../macros.cmake)

set(TestLibrary_SOURCES	
	${CMAKE_CURRENT_SOURCE_DIR}/src/basic_types.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/callback_types.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/callbacks.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/callout.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/registerCallback.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/structures.c
)

addLibraryWithRPATH(TestLibrary ${TestLibrary_SOURCES})

target_include_directories(TestLibrary
PRIVATE
	${CMAKE_CURRENT_SOURCE_DIR}/includes
)
