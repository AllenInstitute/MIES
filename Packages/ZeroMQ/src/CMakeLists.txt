CMAKE_MINIMUM_REQUIRED(VERSION 2.8.11)

# get working XOP on MacOSX, exported symbol list??
PROJECT(ZeroMQ)

IF(CMAKE_SIZEOF_VOID_P EQUAL 4)
  SET(bitness "")
  SET(bitnessWithDash "")
  SET(bitnessWithDashAndText "-64")
  SET(bitnessLibFolder "x86")
  SET(installFolder "${CMAKE_SOURCE_DIR}/../../../XOPs-IP7")
ELSEIF(CMAKE_SIZEOF_VOID_P EQUAL 8)
  SET(bitness "64")
  SET(bitnessWithDash "-64")
  SET(bitnessWithDashAndText "-64bit")
  SET(bitnessLibFolder "x64")
  SET(installFolder "${CMAKE_SOURCE_DIR}/../../../XOPs-IP7-64bit")
ENDIF()

SET(libname "${PROJECT_NAME}${bitnessWithDash}")

IF(APPLE)
  # use RPATH
  cmake_policy(SET CMP0042 NEW)
  SET(RESOURCES "${PROJECT_NAME}.r")
ELSEIF(WIN32)
  SET(RESOURCES "${PROJECT_NAME}.rc")
ENDIF()

SET(SOURCES
CallFunctionOperation.cpp
CallFunctionParameterHandler.cpp
ConcurrentXOPNotice.cpp
CustomExceptions.cpp
functions.cpp
GlobalData.cpp
HelperFunctions.cpp
MessageHandler.cpp
RequestInterface.cpp
RequestInterfaceException.cpp
SerializeWave.cpp
ZeroMQ.cpp
zeromq_client_connect.cpp
zeromq_client_recv.cpp
zeromq_client_send.cpp
zeromq_server_bind.cpp
zeromq_server_recv.cpp
zeromq_server_send.cpp
zeromq_set.cpp
zeromq_handler_start.cpp
zeromq_stop.cpp
zeromq_handler_stop.cpp
zeromq_test_callfunction.cpp
zeromq_test_serializeWave.cpp)

SET(SOURCES_EXT
fmt/format.cc
fmt/ostream.cc
fmt/posix.cc)

SET(HEADERS
CallFunctionOperation.h
CallFunctionParameterHandler.h
ConcurrentQueue.h
ConcurrentXOPNotice.h
CustomExceptions.h
Errors.h
functions.h
GlobalData.h
HelperFunctions.h
IgorTypeUnion.h
MessageHandler.h
RequestInterface.h
RequestInterfaceException.h
resource.h
SerializeWave.h
SocketWithMutex.h
ZeroMQ.h)

SOURCE_GROUP("Headers" FILES ${HEADERS})

INCLUDE_DIRECTORIES(XOPSupport . "libzmq/include")

IF(APPLE)
  SET_TARGET_PROPERTIES(${libname} PROPERTIES PREFIX "")

  FIND_LIBRARY(CARBON_LIBRARY Carbon)
  FIND_LIBRARY(COCOA_LIBRARY Cocoa)
  FIND_LIBRARY(AUDIO_UNIT AudioUnit)
  FIND_LIBRARY(AUDIO_TOOLBOX AudioToolbox)
  MARK_AS_ADVANCED(CARBON_LIBRARY AUDIO_TOOLBOX AUDIO_UNIT COCOA_LIBRARY)
  SET(EXTRA_LIBS ${CARBON_LIBRARY} ${COCOA_LIBRARY} ${AUDIO_TOOLBOX} ${AUDIO_UNIT})

  FIND_PROGRAM(APPLE_RESOURCE Rez /Developer/Tools)
  ADD_CUSTOM_COMMAND(TARGET ${libname}
    POST_BUILD
    COMMAND ${APPLE_RESOURCE} -i XOPSupport -F ${CARBON_LIBRARY}/.. ${RESOURCES} -o ${CMAKE_BINARY_DIR}/${libname}.xop
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

  TARGET_LINK_LIBRARIES(${libname} ${EXTRA_LIBS}
                         ${CMAKE_SOURCE_DIR}/XOPSupport/Xcode/libXOPSupport${bitness}.a
                         /Users/thomas/devel/libzmq/build/lib/libzmq-static.a)

  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -D=TARGET_OS_MAC -Wno-deprecated -mmacosx-version-min=10.9")
ELSEIF(WIN32)

  ADD_LIBRARY(${libname} SHARED ${SOURCES} ${SOURCES_EXT} ${HEADERS} ${RESOURCES})

  SET_TARGET_PROPERTIES(${libname} PROPERTIES SUFFIX ".xop")

  # CMAKE links by default to the MSVC runtime dynamically
  # so we don't have to set that here

  TARGET_LINK_LIBRARIES(${libname} version.lib ${EXTRA_LIBS}
                        ${CMAKE_SOURCE_DIR}/XOPSupport/IGOR${bitness}.lib
                        ${CMAKE_SOURCE_DIR}/XOPSupport/VC2015/XOPSupport${bitness}.lib
                        optimized ${CMAKE_SOURCE_DIR}/libzmq/${bitnessLibFolder}/libzmq-v140-mt-4_2_3.lib
                        debug ${CMAKE_SOURCE_DIR}/libzmq/${bitnessLibFolder}/libzmq-v140-mt-gd-4_2_3.lib)

  # Use parallel builds
  IF(MSVC)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /Zi")
    set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /DEBUG /OPT:REF /OPT:ICF")
  ENDIF()
ENDIF()

# run clang-format before building
ADD_CUSTOM_COMMAND(TARGET ${libname}
        PRE_BUILD
        COMMAND clang-format -i ${SOURCES} ${HEADERS}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Running clang-format" VERBATIM)

ADD_CUSTOM_TARGET(clang-tidy
        COMMAND clang-tidy -i -- ${SOURCES} -p=${CMAKE_BUILD_DIR} -checks=*
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Running clang-tidy" VERBATIM)

INSTALL(TARGETS ${libname}
        RUNTIME
        DESTINATION ${installFolder})

INSTALL(FILES libzmq/${bitnessLibFolder}/libzmq-v140-mt-4_2_3.dll
        DESTINATION ${installFolder}
        CONFIGURATIONS Release)

IF(MSVC)
  INSTALL(FILES ${CMAKE_BINARY_DIR}/release/${PROJECT_NAME}${bitnessWithDash}.pdb
          DESTINATION ${CMAKE_SOURCE_DIR}/PDBs
          CONFIGURATIONS Release
          RENAME ${PROJECT_NAME}${bitnessWithDash}.pdb)
ENDIF()

INSTALL(FILES libzmq/${bitnessLibFolder}/libzmq-v140-mt-gd-4_2_3.dll
        DESTINATION ${installFolder}
        CONFIGURATIONS Debug)
