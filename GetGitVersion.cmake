# Script source: https://cmake.org/pipermail/cmake/2010-July/038015.html
find_package(Git)

file(WRITE ${CMAKE_BINARY_DIR}/sqGitVersionString.h.in
"\#define SOURCE_VERSION_STRING \"@URL@ @VERSION@\"\n"
)
file(WRITE ${CMAKE_BINARY_DIR}/sqGitVersionString.cmake
"
execute_process(
    COMMAND ${GIT_EXECUTABLE} config --get remote.origin.url
    OUTPUT_VARIABLE URL
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

execute_process(
    COMMAND ${GIT_EXECUTABLE} log -1 \"--format=Commit: %H Date: %ci By: %cn <%cE>\"
    OUTPUT_VARIABLE VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
configure_file(\${SRC} \${DST} @ONLY)
")

include_directories(${CMAKE_BINARY_DIR})
add_custom_target(
    sqGitVersionString
    ${CMAKE_COMMAND} -D SRC=${CMAKE_BINARY_DIR}/sqGitVersionString.h.in
                     -D DST=${CMAKE_BINARY_DIR}/sqGitVersionString.h
                     -P ${CMAKE_BINARY_DIR}/sqGitVersionString.cmake
)
