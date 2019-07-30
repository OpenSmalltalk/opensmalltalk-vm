include_directories(
    extracted/vm/include/win
    extracted/vm/include/common
    generated/vm/include
)

set(EXTRACTED_SOURCES
#Common sources
    extracted/vm/src/common/sqHeapMap.c
    extracted/vm/src/common/sqVirtualMachine.c
    extracted/vm/src/common/sqNamedPrims.c
    extracted/vm/src/common/sqExternalSemaphores.c
    extracted/vm/src/common/sqTicker.c

#Platform sources
    extracted/vm/src/win/sqWin32SpurAlloc.c
    extracted/vm/src/win/sqWin32Heartbeat.c
    src/aioWin.c
    src/debugWin.c
)

set(VM_FRONTEND_SOURCES
    src/main.c
    src/parameters.c
    src/winOpenFileDialog.cpp)

macro(add_third_party_dependencies_per_platform)
    add_third_party_dependency("pixman-0.34.0" "build/vm")
    add_third_party_dependency("cairo-1.15.4" "build/vm")
    add_third_party_dependency("freetype-2.9.1" "build/vm")
    add_third_party_dependency("libffi-3.3-rc0" "build/vm")
    add_third_party_dependency("libgit2-0.25.1" "build/vm")
    add_third_party_dependency("libpng-1.6.34" "build/vm")
    add_third_party_dependency("libssh2-1.7.0" "build/vm")
    add_third_party_dependency("openssl-1.0.2q" "build/vm")
    add_third_party_dependency("gcc-runtime-3.4" "build/vm")
    add_third_party_dependency("zlib-1.2.11" "build/vm")
    add_third_party_dependency("SDL2-2.0.5" "build/vm")   
    add_third_party_dependency("pthreadedPlugin-0.0.1" "build/vm")
endmacro()


macro(configure_installables)
    set(CMAKE_INSTALL_PREFIX "${CMAKE_SOURCE_DIR}/build/dist")
    
    install(DIRECTORY "${CMAKE_SOURCE_DIR}/build/vm/" DESTINATION "./" USE_SOURCE_PERMISSIONS)
endmacro()
