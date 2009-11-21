cmake_minimum_required(VERSION 2.6)
project(fastann)

SET(CMAKE_BUILD_TYPE Release)

IF(WIN32)
    MESSAGE("Windows not currently supported" FATAL_ERROR)
ENDIF(WIN32)

IF(UNIX)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -O2 -g3 -msse2 -march=native -fno-exceptions -fno-rtti")
    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -O2 -g3 -msse2 -march=native -fno-exceptions")
    MESSAGE("${CMAKE_CXX_FLAGS}")
ENDIF(UNIX)

# Set the install prefix
IF(NOT $ENV{PREFIX} STREQUAL "")
    SET(CMAKE_INSTALL_PREFIX $ENV{PREFIX})
ELSE(NOT $ENV{PREFIX} STREQUAL "")
    SET(CMAKE_INSTALL_PREFIX "/usr/")
ENDIF(NOT $ENV{PREFIX} STREQUAL "")
MESSAGE("--- Prefix = " ${CMAKE_INSTALL_PREFIX})

FIND_PROGRAM(YASM_EXECUTABLE yasm)
SET(YASM_OBJS)
IF(YASM_EXECUTABLE AND CMAKE_SIZEOF_VOID_P MATCHES "4")
    MESSAGE("--- Using experimental asm routines")
    ADD_DEFINITIONS(-DEXPERIMENTAL_ASM)
    ADD_CUSTOM_COMMAND(
        OUTPUT dist_l2_funcs_exp_32.o
        COMMAND yasm ARGS -f elf32 dist_l2_funcs_exp_32.asm -o dist_l2_funcs_exp_32.o
        DEPENDS dist_l2_funcs_exp_32.asm)
    SET(YASM_OBJS ${YASM_OBJS} dist_l2_funcs_exp_32.o)
ENDIF(YASM_EXECUTABLE AND CMAKE_SIZEOF_VOID_P MATCHES "4")
IF(YASM_EXECUTABLE AND CMAKE_SIZEOF_VOID_P MATCHES "8")
    MESSAGE("--- Using experimental asm routines")
    ADD_DEFINITIONS(-DEXPERIMENTAL_ASM)
    ADD_CUSTOM_COMMAND(
        OUTPUT dist_l2_funcs_exp_64.o
        COMMAND yasm ARGS -f elf64 dist_l2_funcs_exp_64.asm -o dist_l2_funcs_exp_64.o
        DEPENDS dist_l2_funcs_exp_64.asm)
    SET(YASM_OBJS ${YASM_OBJS} dist_l2_funcs_exp_64.o)
ENDIF(YASM_EXECUTABLE AND CMAKE_SIZEOF_VOID_P MATCHES "8")

ADD_LIBRARY(fastann SHARED dist_l2.cpp fastann.cpp randomkit.c ${YASM_OBJS})

ADD_EXECUTABLE(perf_dist_l2 perf_dist_l2.cpp)
TARGET_LINK_LIBRARIES(perf_dist_l2 fastann)

ADD_EXECUTABLE(perf_kdtree perf_kdtree.cpp)
TARGET_LINK_LIBRARIES(perf_kdtree fastann)

ADD_EXECUTABLE(test_dist_l2 test_dist_l2.cpp)
TARGET_LINK_LIBRARIES(test_dist_l2 fastann)

ADD_EXECUTABLE(test_kdtree test_kdtree.cpp)
TARGET_LINK_LIBRARIES(test_kdtree fastann)

# Custom targets #
ADD_CUSTOM_COMMAND(
    OUTPUT dummy_perf
    COMMAND ./perf_dist_l2 && ./perf_kdtree
    DEPENDS perf_dist_l2 perf_kdtree)
ADD_CUSTOM_TARGET(perf DEPENDS dummy_perf)

ADD_CUSTOM_COMMAND(
    OUTPUT dummy_test
    COMMAND ./test_dist_l2 && ./test_kdtree
    DEPENDS test_dist_l2 test_kdtree)
ADD_CUSTOM_TARGET(test DEPENDS dummy_test)

INSTALL(TARGETS fastann 
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        )
INSTALL(FILES fastann.hpp randomkit.h rand_point_gen.hpp fastann.h DESTINATION include/fastann)
