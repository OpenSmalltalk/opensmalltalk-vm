# RETURN ()

# # Some binary distrbutions are built badly.  Attempt to work around only those bugs that we need to fix.
# # 
# # Last edited: 2009-08-15 12:27:17 by piumarta on emilia-2.local

# IF (NOT DEFINED CMAKE_FIND_LIBRARY_PREFIXES)
#     IF (UNIX)
# 	SET (CMAKE_FIND_LIBRARY_PREFIXES lib)
#     ENDIF (UNIX)
# ENDIF (NOT DEFINED CMAKE_FIND_LIBRARY_PREFIXES)

# IF (NOT DEFINED CMAKE_FIND_LIBRARY_SUFFIXES)
#     IF (UNIX)
#         IF (APPLE)
#             SET (CMAKE_FIND_LIBRARY_SUFFIXES .a .dylib)
#         ELSE (APPLE)
#             SET (CMAKE_FIND_LIBRARY_SUFFIXES .a .so)
#         ENDIF (APPLE)
#     ENDIF (UNIX)
# ENDIF (NOT DEFINED CMAKE_FIND_LIBRARY_SUFFIXES)
