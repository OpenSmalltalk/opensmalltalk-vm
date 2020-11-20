# Find libgit2 Library
#
#  LIBGIT2_INCLUDE_DIRS - where to find git2.h, etc.
#  LIBGIT2_LIBRARIES    - List of libraries when using libgit2.
#  LIBGIT2_FOUND        - True if libgit2 is found.

# LIBGIT2_INCLUDE_PATH
find_path(LIBGIT2_INCLUDE_PATH NAMES git2.h)
# LIBGIT2_LIBRARY
find_library(LIBGIT2_LIBRARY NAMES git2)

# handle the QUIETLY and REQUIRED arguments and set GIT2_FOUND to TRUE if
# all listed variables are TRUE
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(libgit2 REQUIRED_VARS LIBGIT2_LIBRARY LIBGIT2_INCLUDE_PATH)


if (LIBGIT2_FOUND)
  set(LIBGIT2_INCLUDE_DIR  ${LIBGIT2_INCLUDE_PATH})
  set(LIBGIT2_INCLUDE_DIRS ${LIBGIT2_INCLUDE_PATH})
  set(LIBGIT2_LIBRARIES    ${LIBGIT2_LIBRARY})
endif()

mark_as_advanced(
  LIBGIT2_INCLUDE_PATH
  LIBGIT2_LIBRARY
)