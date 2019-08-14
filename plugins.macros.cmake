macro(add_vm_plugin NAME)

    set(${NAME}_SOURCES_EXTRA ${ARGN})

    if(OSX)
        file(GLOB ${NAME}_SOURCES
            ${${NAME}_SOURCES_EXTRA}
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/${NAME}/src/common/*.c   
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/${NAME}/src/osx/*.c   
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/${NAME}/src/unix/*.c 
        )
        include_directories(
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/${NAME}/include/common
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/${NAME}/include/osx
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/${NAME}/include/unix
        )        
    elseif(UNIX)
        file(GLOB ${NAME}_SOURCES
            ${${NAME}_SOURCES_EXTRA}
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/${NAME}/src/common/*.c   
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/${NAME}/src/unix/*.c 
        )         
        include_directories(
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/${NAME}/include/common
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/${NAME}/include/unix
        )
    else()
        file(GLOB ${NAME}_SOURCES
            ${${NAME}_SOURCES_EXTRA}       
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/${NAME}/src/common/*.c   
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/${NAME}/src/win/*.c 
        )                 
        include_directories(
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/${NAME}/include/common
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/${NAME}/include/win
        )
    endif()

    message(STATUS "Adding plugin: ${NAME}")    

    addLibraryWithRPATH(${NAME} ${${NAME}_SOURCES})
    target_link_libraries(${NAME} ${VM_LIBRARY_NAME})   
endmacro()