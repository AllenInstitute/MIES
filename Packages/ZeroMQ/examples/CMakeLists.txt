CMAKE_MINIMUM_REQUIRED(VERSION 2.6)

SET(prog "zmq_xop_client")

PROJECT(${prog})
ADD_EXECUTABLE(${prog} cli-client.cpp)

INCLUDE_DIRECTORIES("${CMAKE_SOURCE_DIR}/../src/libzmq/include")
SET_TARGET_PROPERTIES(${prog} PROPERTIES CXX_STANDARD 11)

TARGET_LINK_LIBRARIES(${prog}
                      optimized ${CMAKE_SOURCE_DIR}/../src/libzmq/x86/libzmq-v140-mt-4_2_3.lib
                      debug ${CMAKE_SOURCE_DIR}/../src/libzmq/x86/libzmq-v140-mt-gd-4_2_3.lib)
