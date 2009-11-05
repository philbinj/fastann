cmake_minimum_required(VERSION 2.6)
project(fastann)

SET(CMAKE_BUILD_TYPE Release)

IF(WIN32)
    MESSAGE("Windows not currently supported" FATAL_ERROR)
ENDIF(WIN32)

IF(UNIX)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -O2 -g -msse2 -march=native")
    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -O2 -g -msse2 -march=native")
    SET(CMAKE_INSTALL_PREFIX "/usr/")
    MESSAGE("${CMAKE_CXX_FLAGS}")
ENDIF(UNIX)

FIND_PROGRAM(YASM_EXECUTABLE yasm)
SET(YASM_OBJS)
IF(YASM_EXECUTABLE AND CMAKE_SIZEOF_VOID_P MATCHES "4")
    MESSAGE("Using experimental asm routines")
    ADD_DEFINITIONS(-DEXPERIMENTAL_ASM)
    ADD_CUSTOM_COMMAND(
        OUTPUT dist_l2_funcs_exp.o
        COMMAND yasm ARGS -f elf32 dist_l2_funcs_exp.asm -o dist_l2_funcs_exp.o
        DEPENDS dist_l2_funcs_exp.asm)
    SET(YASM_OBJS ${YASM_OBJS} dist_l2_funcs_exp.o)
ENDIF(YASM_EXECUTABLE AND CMAKE_SIZEOF_VOID_P MATCHES "4")
IF(YASM_EXECUTABLE AND CMAKE_SIZEOF_VOID_P MATCHES "8")
    MESSAGE("Using experimental asm routines")
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

ADD_EXECUTABLE(test_dist_l2 test_dist_l2.cpp)
TARGET_LINK_LIBRARIES(test_dist_l2 fastann)

ADD_EXECUTABLE(test_kdtree test_kdtree.cpp)
TARGET_LINK_LIBRARIES(test_kdtree fastann)

INSTALL(TARGETS fastann 
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        )
INSTALL(FILES fastann.hpp randomkit.h rand_point_gen.hpp DESTINATION include/fastann)
