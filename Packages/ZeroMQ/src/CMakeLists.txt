CMAKE_MINIMUM_REQUIRED(VERSION 3.8)

PROJECT(ZeroMQ)

IF(CMAKE_SIZEOF_VOID_P EQUAL 4)
  SET(bitness "")
  SET(bitnessWithDash "")
  SET(bitnessWithDashAndText "-64")
  SET(bitnessLibFolder "x86")
ELSEIF(CMAKE_SIZEOF_VOID_P EQUAL 8)
  SET(bitness "64")
  SET(bitnessWithDash "-64")
  SET(bitnessWithDashAndText "-64bit")
  SET(bitnessLibFolder "x64")
ENDIF()

SET(libname "${PROJECT_NAME}${bitnessWithDash}")

IF(APPLE)
  # use RPATH
  cmake_policy(SET CMP0042 NEW)
  SET(RESOURCES "${PROJECT_NAME}.r")
  SET(installFolder "${CMAKE_SOURCE_DIR}/../output/mac")
ELSEIF(WIN32)
  SET(RESOURCES "${PROJECT_NAME}.rc")
  SET(installFolder "${CMAKE_SOURCE_DIR}/../output/win/${bitnessLibFolder}")
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

  # heavily inspired by https://github.com/Kitware/CMake/blob/master/Tests/CFBundleTest/CMakeLists.txt

  SET(MISC
    InfoPlist.strings
    ${CMAKE_BINARY_DIR}/${libname}.rsrc)

  ADD_EXECUTABLE(${libname} MACOSX_BUNDLE ${SOURCES} ${SOURCES_EXT} ${HEADERS} ${RESOURCES} ${MISC})

  SET_TARGET_PROPERTIES(${libname} PROPERTIES PREFIX "")
  SET_TARGET_PROPERTIES(${libname} PROPERTIES BUNDLE_EXTENSION "xop")
  SET_TARGET_PROPERTIES(${libname} PROPERTIES ENABLE_EXPORTS true)
  SET_TARGET_PROPERTIES(${libname} PROPERTIES XCODE_ATTRIBUTE_EXPORTED_SYMBOLS_FILE "${CMAKE_SOURCE_DIR}/Exports.exp")
  SET_TARGET_PROPERTIES(${libname} PROPERTIES XCODE_ATTRIBUTE_MACH_O_TYPE mh_bundle)

  SET(sysroot)
  IF(CMAKE_OSX_SYSROOT)
    SET(sysroot -isysroot ${CMAKE_OSX_SYSROOT})
  ENDIF()

  SET_TARGET_PROPERTIES(${libname} PROPERTIES CXX_STANDARD 14)

  FIND_LIBRARY(CARBON_LIBRARY Carbon)
  FIND_LIBRARY(COCOA_LIBRARY Cocoa)
  FIND_LIBRARY(AUDIO_UNIT AudioUnit)
  FIND_LIBRARY(AUDIO_TOOLBOX AudioToolbox)
  MARK_AS_ADVANCED(CARBON_LIBRARY AUDIO_TOOLBOX AUDIO_UNIT COCOA_LIBRARY)
  SET(EXTRA_LIBS ${CARBON_LIBRARY} ${COCOA_LIBRARY} ${AUDIO_TOOLBOX} ${AUDIO_UNIT})

  FIND_PROGRAM(APPLE_RESOURCE Rez /Developer/Tools)
  IF(NOT APPLE_RESOURCE)
    MESSAGE(FATAL_ERROR "Could not find Rez to build resources from .r file.")
  ENDIF()

  ADD_CUSTOM_COMMAND(TARGET ${libname}
    PRE_BUILD
    COMMAND ${APPLE_RESOURCE}
    ${sysroot}
    -i XOPSupport
    -F ${CARBON_LIBRARY}
    -useDF
    ${RESOURCES}
    -o ${CMAKE_BINARY_DIR}/${libname}.rsrc
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

  ADD_CUSTOM_COMMAND(TARGET ${libname}
    POST_BUILD
    COMMAND zip
    -r ${libname}.zip
    ${CMAKE_CFG_INTDIR}/${libname}.xop
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR})

  SET_SOURCE_FILES_PROPERTIES(
      ${CMAKE_BINARY_DIR}/${libname}.rsrc
      PROPERTIES GENERATED 1)

  SET_SOURCE_FILES_PROPERTIES(
    ${CMAKE_BINARY_DIR}/${libname}.rsrc
    PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

  SET_SOURCE_FILES_PROPERTIES(
    ${CMAKE_SOURCE_DIR}/InfoPlist.strings
    PROPERTIES MACOSX_PACKAGE_LOCATION "Resources/English.lproj")

  TARGET_LINK_LIBRARIES(${libname} ${EXTRA_LIBS}
                         ${CMAKE_SOURCE_DIR}/XOPSupport/Xcode/libXOPSupport${bitness}.a
                         ${CMAKE_SOURCE_DIR}/libzmq/${bitnessLibFolder}_mac/libzmq.a)

  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D=TARGET_OS_MAC -Wno-deprecated")
  SET(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -D=_DEBUG")

  LIST(APPEND CMAKE_PROGRAM_PATH "/usr/local/opt/llvm/bin")
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

FIND_PROGRAM(CLANG-TIDY clang-tidy)

ADD_CUSTOM_TARGET(clang-tidy
                  COMMAND ${CLANG-TIDY} -fix -p=${CMAKE_BINARY_DIR} -checks=* ${SOURCES}
                  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                  COMMENT "Running clang-tidy" VERBATIM)

IF(MSVC)
  INSTALL(TARGETS ${libname}
          RUNTIME
          DESTINATION ${installFolder})

  INSTALL(FILES ${CMAKE_BINARY_DIR}/Release/${libname}.pdb
          DESTINATION ${installFolder}
          CONFIGURATIONS Release)

  INSTALL(FILES libzmq/${bitnessLibFolder}/libzmq-v140-mt-gd-4_2_3.dll
          DESTINATION ${installFolder}
          CONFIGURATIONS Debug)

  INSTALL(FILES libzmq/${bitnessLibFolder}/libzmq-v140-mt-4_2_3.dll
          DESTINATION ${installFolder}
          CONFIGURATIONS Release)
ELSEIF(APPLE)
  INSTALL(FILES ${CMAKE_BINARY_DIR}/${libname}.zip
          DESTINATION ${installFolder})
ENDIF()
