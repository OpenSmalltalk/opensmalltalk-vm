# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# - Try to find libffi define the variables for the binaries/headers and include 
#
# Once done this will define
#  FFI_FOUND - System has libffi
#  FFI::lib - Imported target for the libffi

find_library(FFI_LIBRARY NAMES ffi libffi
    PATHS $ENV{FFI_DIR} ${FFI_DIR} /usr/local/opt/libffi /opt/local /usr /usr/local
    PATH_SUFFIXES lib lib64 x86_64-linux-gnu lib/x86_64-linux-gnu
    HINTS ${PC_LIBFFI_LIBDIR} ${PC_LIBFFI_LIBRARY_DIRS}
)

find_path(FFI_INCLUDE_DIR ffi.h
     PATHS $ENV{FFI_DIR} ${FFI_DIR} /usr/local/opt/libffi /opt/local /usr /usr/local
     PATH_SUFFIXES include include/ffi include/x86_64-linux-gnu x86_64-linux-gnu
     HINTS ${PC_LIBFFI_INCLUDEDIR} ${PC_LIBFFI_INCLUDE_DIRS}
)

include(FindPackageHandleStandardArgs)
# handle the QUIETLY and REQUIRED arguments and set FFI_FOUND to TRUE
# if all listed variables are TRUE
find_package_handle_standard_args(FFI DEFAULT_MSG
                                  FFI_LIBRARY FFI_INCLUDE_DIR)
mark_as_advanced(FFI_INCLUDE_DIR FFI_LIBRARY)

set(FFI_LIBRARIES ${FFI_LIBRARY})
set(FFI_INCLUDE_DIRS ${FFI_INCLUDE_DIR})


if(FFI_FOUND AND NOT TARGET FFI::lib)
    add_library(FFI::lib SHARED IMPORTED)
    set_target_properties(FFI::lib PROPERTIES
            IMPORTED_LOCATION "${FFI_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${FFI_INCLUDE_DIR}"
    )

endif()
