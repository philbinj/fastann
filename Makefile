CC = gcc
CXX = g++
CXXFLAGS = -Wall -O2 -g -msse2 -march=native
CFLAGS = ${CXXFLAGS}
LIBDIR = /usr/lib/
INCDIR = /usr/include/

all: libfastann.a

libfastann.a: dist_l2.o fastann.o randomkit.o dist_l2_funcs_exp.o
	- rm libfastann.a
	${AR} rcs libfastann.a dist_l2.o fastann.o randomkit.o dist_l2_funcs_exp.o

dist_l2.o: dist_l2.cpp dist_l2.hpp dist_l2_funcs.hpp
	${CXX} -Wall -O2 -fomit-frame-pointer -msse2 -march=native -c dist_l2.cpp -o dist_l2.o

dist_l2_funcs_exp.o: dist_l2_funcs_exp.asm
	yasm -f elf32 -DMARK_FUNCS dist_l2_funcs_exp.asm -o dist_l2_funcs_exp.o

fastann.o: fastann.cpp fastann.hpp nn_kdtree.hpp

randomkit.o: randomkit.c randomkit.h

all: dist_l2.o

test: libfastann.a
	${CXX} ${CXXFLAGS} test_dist_l2.cpp -o test_dist_l2 -L. -lfastann
	${CXX} ${CXXFLAGS} test_kdtree.cpp -o test_kdtree -L. -lfastann
	./test_dist_l2
	./test_kdtree

perf: libfastann.a
	${CXX} ${CXXFLAGS} perf_dist_l2.cpp -o perf_dist_l2 -L. -lfastann
	./perf_dist_l2

clean:
	-rm *.o *.so test_dist_l2 perf_dist_l2 test_kdtree libfastann.a

install:
	install libfastann.so ${LIBDIR}libfastann.a
	install -m 644 -D randomkit.h ${INCDIR}fastann/randomkit.h
	install -m 644 -D rand_point_gen.hpp ${INCDIR}fastann/rand_point_gen.hpp
	install -m 644 -D fastann.hpp ${INCDIR}fastann/fastann.hpp
