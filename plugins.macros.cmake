macro(add_vm_plugin NAME)

    set(${NAME}_SOURCES_EXTRA ${ARGN})

    if(OSX)
        file(GLOB ${NAME}_SOURCES
            ${${NAME}_SOURCES_EXTRA}
            extracted/plugins/${NAME}/src/common/*.c   
            extracted/plugins/${NAME}/src/osx/*.c   
            extracted/plugins/${NAME}/src/unix/*.c 
        )
        include_directories(
            extracted/plugins/${NAME}/include/common
            extracted/plugins/${NAME}/include/osx
            extracted/plugins/${NAME}/include/unix
        )        
    elseif(UNIX)
        file(GLOB ${NAME}_SOURCES
            ${${NAME}_SOURCES_EXTRA}
            extracted/plugins/${NAME}/src/common/*.c   
            extracted/plugins/${NAME}/src/unix/*.c 
        )         
        include_directories(
            extracted/plugins/${NAME}/include/common
            extracted/plugins/${NAME}/include/unix
        )
    else()
        file(GLOB ${NAME}_SOURCES
            ${${NAME}_SOURCES_EXTRA}       
            extracted/plugins/${NAME}/src/common/*.c   
            extracted/plugins/${NAME}/src/win/*.c 
        )                 
        include_directories(
            extracted/plugins/${NAME}/include/common
            extracted/plugins/${NAME}/include/win
        )
    endif()

    message(STATUS "Adding plugin: ${NAME}")    

    addLibraryWithRPATH(${NAME} SHARED ${${NAME}_SOURCES})
    target_link_libraries(${NAME} ${VM_LIBRARY_NAME})   
endmacro()