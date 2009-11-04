CC = gcc
CXX = g++
CXXFLAGS = -Wall -O2 -g -msse2 -march=native -fPIC
CFLAGS = ${CXXFLAGS}
LIBDIR = /usr/lib/
INCDIR = /usr/include/

all: libfastann.so

libfastann.so: dist_l2.o fastann.o randomkit.o
	${CXX} ${CXXFLAGS} -shared dist_l2.o fastann.o randomkit.o -o libfastann.so

dist_l2.o: dist_l2.cpp dist_l2.hpp dist_l2_funcs.hpp
	${CXX} -Wall -O2 -fomit-frame-pointer -msse2 -march=native -fPIC -c dist_l2.cpp -o dist_l2.o

fastann.o: fastann.cpp fastann.hpp nn_kdtree.hpp

randomkit.o: randomkit.c randomkit.h

all: dist_l2.o

test:
	${CXX} ${CXXFLAGS} test_dist_l2.cpp randomkit.c -o test_dist_l2
	${CXX} ${CXXFLAGS} test_kdtree.cpp randomkit.c fastann.cpp dist_l2.cpp -o test_kdtree
	./test_dist_l2
	./test_kdtree

perf:
	${CXX} ${CXXFLAGS} perf_dist_l2.cpp randomkit.c -o perf_dist_l2
	./perf_dist_l2

clean:
	-rm *.o *.so test_dist_l2 perf_dist_l2 test_kdtree libfastann.so

install:
	install libfastann.so ${LIBDIR}libfastann.so
	install -m 644 -D randomkit.h ${INCDIR}fastann/randomkit.h
	install -m 644 -D rand_point_gen.hpp ${INCDIR}fastann/rand_point_gen.hpp
	install -m 644 -D fastann.hpp ${INCDIR}fastann/fastann.hpp
