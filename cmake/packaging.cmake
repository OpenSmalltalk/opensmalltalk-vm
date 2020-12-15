# Packaging support file
#
# Manage the packaging of the VM executable, sources and headers
# This support file defines
#   - Several components to package
#   - Their packaging with CPack

make_directory("build/packages")

# Selecting files to include in the packages

configure_installables(bin)

install(FILES
  ${CMAKE_CURRENT_BINARY_DIR}/build/include/pharovm/config.h
  DESTINATION include/pharovm
  COMPONENT include)

install(
    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/include/pharovm"
    DESTINATION include
    COMPONENT include
    FILES_MATCHING PATTERN *.h)

install(
    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include/common/"
    DESTINATION include/pharovm
    COMPONENT include
    FILES_MATCHING PATTERN *.h)

install(DIRECTORY
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake"
    "${CMAKE_CURRENT_SOURCE_DIR}/extracted"
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/packaging"
    "${CMAKE_CURRENT_SOURCE_DIR}/plugins"
    "${CMAKE_CURRENT_SOURCE_DIR}/resources"
    "${CMAKE_CURRENT_SOURCE_DIR}/scripts"
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_SOURCE_DIR}/ffiTestLibrary"
    "${CMAKE_CURRENT_SOURCE_DIR}/ffi"
    DESTINATION pharo-vm
    COMPONENT c-src
)

#List all cmake files
file(GLOB SUPPORT_CMAKE_FILES
  "${CMAKE_CURRENT_SOURCE_DIR}/*.cmake"
)

install(FILES
    "CMakeLists.txt"
    ${SUPPORT_CMAKE_FILES}
    DESTINATION pharo-vm
    COMPONENT c-src
)

get_platform_name(FULL_PLATFORM_NAME)

set(CPACK_PACKAGE_DESCRIPTION "${APPNAME} Headless VM for ${FULL_PLATFORM_NAME}")
set(CPACK_PACKAGE_VERSION_MAJOR "${VERSION_MAJOR}")
set(CPACK_PACKAGE_VERSION_MINOR "${VERSION_MINOR}")
set(CPACK_PACKAGE_VERSION_PATCH "${VERSION_PATCH}")
set(CPACK_PACKAGE_VENDOR "${APPNAME}")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://pharo.org")

if(ALWAYS_INTERACTIVE)
	set(CPACK_PACKAGE_FILE_NAME "${APPNAME}VM-${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}-${GIT_COMMIT_HASH}-${FULL_PLATFORM_NAME}-stockReplacement")
else()
	set(CPACK_PACKAGE_FILE_NAME "${APPNAME}VM-${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}-${GIT_COMMIT_HASH}-${FULL_PLATFORM_NAME}")
endif()

set(CPACK_PACKAGE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build/packages")
set(CPACK_PACKAGE_CHECKSUM "SHA1")
set(CPACK_GENERATOR "ZIP" "TGZ")
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY TRUE)

#Tell CPACK to archive each sub component separately
set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)

set(CPACK_SOURCE_GENERATOR "TGZ")
set(CPACK_SOURCE_IGNORE_FILES
  ".git/;${CMAKE_CURRENT_BINARY_DIR}"
)

include (CPack)
