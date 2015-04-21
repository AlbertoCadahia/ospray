## ======================================================================== ##
## Copyright 2009-2015 Intel Corporation                                    ##
##                                                                          ##
## Licensed under the Apache License, Version 2.0 (the "License");          ##
## you may not use this file except in compliance with the License.         ##
## You may obtain a copy of the License at                                  ##
##                                                                          ##
##     http://www.apache.org/licenses/LICENSE-2.0                           ##
##                                                                          ##
## Unless required by applicable law or agreed to in writing, software      ##
## distributed under the License is distributed on an "AS IS" BASIS,        ##
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. ##
## See the License for the specific language governing permissions and      ##
## limitations under the License.                                           ##
## ======================================================================== ##

FILE(WRITE "${CMAKE_BINARY_DIR}/CMakeDefines.h" "#define CMAKE_BUILD_DIR \"${CMAKE_BINARY_DIR}\"\n")

#include bindir - that's where ispc puts generated header files
INCLUDE_DIRECTORIES(${CMAKE_BINARY_DIR})
SET(OSPRAY_BINARY_DIR ${CMAKE_BINARY_DIR})
SET(OSPRAY_DIR ${PROJECT_SOURCE_DIR})
# arch-specific cmd-line flags for various arch and compiler configs

# Configure the output directories. To allow IMPI to do its magic we
# will put *executables* into the (same) build directory, but tag
# mic-executables with ".mic". *libraries* cannot use the
# ".mic"-suffix trick, so we'll put libraries into separate
# directories (names 'intel64' and 'mic', respectively)
MACRO(CONFIGURE_OSPRAY_NO_ARCH)
  SET(LIBRARY_OUTPUT_PATH ${OSPRAY_BINARY_DIR})
  SET(EXECUTABLE_OUTPUT_PATH ${OSPRAY_BINARY_DIR})

  LINK_DIRECTORIES(${LIBRARY_OUTPUT_PATH})

  # Embree common include directories; others may be added depending on build target.
  # this section could be sooo much cleaner if embree only used
  # fully-qualified include names...
  SET(EMBREE_INCLUDE_DIRECTORIES
    ${OSPRAY_EMBREE_SOURCE_DIR}/ 
    ${OSPRAY_EMBREE_SOURCE_DIR}/include
    ${OSPRAY_EMBREE_SOURCE_DIR}/common
    ${OSPRAY_EMBREE_SOURCE_DIR}/
    ${OSPRAY_EMBREE_SOURCE_DIR}/kernels
    )

  IF (OSPRAY_TARGET STREQUAL "mic")
    SET(OSPRAY_EXE_SUFFIX ".mic")
    SET(OSPRAY_LIB_SUFFIX "_mic")
    SET(OSPRAY_ISPC_SUFFIX ".cpp")
    SET(OSPRAY_ISPC_TARGET "mic")
    SET(THIS_IS_MIC ON)
    SET(__XEON__ OFF)
    INCLUDE(${PROJECT_SOURCE_DIR}/cmake/icc_xeonphi.cmake)

    # additional Embree include directory
    LIST(APPEND EMBREE_INCLUDE_DIRECTORIES ${OSPRAY_EMBREE_SOURCE_DIR}/kernels/xeonphi)

    #		SET(LIBRARY_OUTPUT_PATH "${OSPRAY_BINARY_DIR}/lib/mic")
    ADD_DEFINITIONS(-DOSPRAY_TARGET_MIC=1)
  ELSE()
    SET(OSPRAY_EXE_SUFFIX "")
    SET(OSPRAY_LIB_SUFFIX "")
    SET(OSPRAY_ISPC_SUFFIX ".o")
    SET(THIS_IS_MIC OFF)
    SET(__XEON__ ON)
    IF ((OSPRAY_COMPILER STREQUAL "ICC"))
      INCLUDE(${PROJECT_SOURCE_DIR}/cmake/icc.cmake)
    ELSEIF ((OSPRAY_COMPILER STREQUAL "GCC"))
      INCLUDE(${PROJECT_SOURCE_DIR}/cmake/gcc.cmake)
    ELSEIF ((OSPRAY_COMPILER STREQUAL "CLANG"))
      INCLUDE(${PROJECT_SOURCE_DIR}/cmake/clang.cmake)
    ELSE()
      MESSAGE(FATAL_ERROR "Unknown OSPRAY_COMPILER '${OSPRAY_COMPILER}'; recognized values are 'clang', 'icc', and 'gcc'")
    ENDIF()

    # additional Embree include directory
    LIST(APPEND EMBREE_INCLUDE_DIRECTORIES ${OSPRAY_EMBREE_SOURCE_DIR}/kernels/xeon)

    IF (OSPRAY_BUILD_ISA STREQUAL "ALL")
      SET(OSPRAY_ISPC_TARGET_LIST sse4 avx avx2)
#      SET(OSPRAY_ISPC_CPU "core-avx2")
      SET(OSPRAY_ISA_SSE  true)
      SET(OSPRAY_ISA_AVX  true)
      SET(OSPRAY_ISA_AVX2 true)
    ELSEIF (OSPRAY_BUILD_ISA STREQUAL "AVX512")
      SET(OSPRAY_ISPC_TARGET_LIST generic-16)
 #     SET(OSPRAY_ISPC_CPU "core-avx2")
      SET(OSPRAY_ISA_SSE  true)
      SET(OSPRAY_ISA_AVX  false)
      SET(OSPRAY_ISA_AVX2 false)
    ELSEIF (OSPRAY_BUILD_ISA STREQUAL "AVX2")
      SET(OSPRAY_ISPC_TARGET_LIST avx2)
 #     SET(OSPRAY_ISPC_CPU "core-avx2")
      SET(OSPRAY_ISA_SSE  false)
      SET(OSPRAY_ISA_AVX  false)
      SET(OSPRAY_ISA_AVX2 true)
    ELSEIF (OSPRAY_BUILD_ISA STREQUAL "AVX")
      SET(OSPRAY_ISPC_TARGET_LIST avx)
 #     SET(OSPRAY_ISPC_CPU "corei7-avx")
      SET(OSPRAY_ISA_SSE  false)
      SET(OSPRAY_ISA_AVX  true)
      SET(OSPRAY_ISA_AVX2 false)
    ELSEIF (OSPRAY_BUILD_ISA STREQUAL "SSE")
      SET(OSPRAY_ISPC_TARGET_LIST sse4)
 #     SET(OSPRAY_ISPC_CPU "corei7")
      SET(OSPRAY_ISA_SSE  true)
      SET(OSPRAY_ISA_AVX  false)
      SET(OSPRAY_ISA_AVX2 false)
    ENDIF()

  ENDIF()
  
  IF (OSPRAY_MPI)
    ADD_DEFINITIONS(-DOSPRAY_MPI=1)
  ENDIF()

  IF (THIS_IS_MIC)
    # whether to build in MIC/xeon phi support
    SET(OSPRAY_BUILD_COI_DEVICE OFF CACHE BOOL "Build COI Device for OSPRay's MIC support?")
  ENDIF()

  #  INCLUDE(ospray_ispc)
  #  INCLUDE(ispc_build_rules)

  INCLUDE(${PROJECT_SOURCE_DIR}/cmake/ispc.cmake)

  INCLUDE_DIRECTORIES(${PROJECT_SOURCE_DIR})
  INCLUDE_DIRECTORIES(${EMBREE_INCLUDE_DIRECTORIES})
  
  INCLUDE_DIRECTORIES_ISPC(${PROJECT_SOURCE_DIR})
  INCLUDE_DIRECTORIES_ISPC(${EMBREE_INCLUDE_DIRECTORIES})

  IF (OSPRAY_INTERSECTION_FILTER)
    ADD_DEFINITIONS(-DOSPRAY_INTERSECTION_FILTER=1)
    ADD_DEFINITIONS_ISPC(-DOSPRAY_INTERSECTION_FILTER=1)
  ENDIF()

ENDMACRO()


MACRO(CONFIGURE_OSPRAY)

  CONFIGURE_OSPRAY_NO_ARCH()
#  IF (OSPRAY_TARGET STREQUAL "MIC")
#  ELSE()
#    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OSPRAY_ARCH_${OSPRAY_XEON_TARGET}}")
#  ENDIF()

ENDMACRO()
