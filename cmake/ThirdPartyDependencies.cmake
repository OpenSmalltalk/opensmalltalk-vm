include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/ThirdPartyDependenciesMacros.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/ThirdPartyDependenciesCommon.cmake")

if(PHARO_VM)
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/ThirdPartyDependenciesPharo.cmake")
elseif(SQUEAK_VM)
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/ThirdPartyDependenciesSqueak.cmake")
endif()
