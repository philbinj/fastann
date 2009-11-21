---------------------------------------------------------------------
| FASTANN: A library for fast approximate nearest neighbours        |
|                                                                   |
| James Philbin <philbinj@gmail.com>                                |
---------------------------------------------------------------------
The plan is to support a number of different approximate nearest
neighbour routines and possibly different distance norms. At the
moment only the Euclidean distance is supported with the following
methods:
- Exact NN
- Approximate k-d trees

Both methods use some fairly optimized distance functions (though
these can be improved).

---------------------------------------------------------------------
| INSTALLATION                                                      |
---------------------------------------------------------------------
Before installation the following requirements should be met:
- Linux
- CMake >= 2.6.0
- Yasm (http://www.tortall.net/projects/yasm/) (OPTIONAL)

Build the library for installing to /usr/local/ (default /usr/)
> PREFIX=/usr/local/ cmake . && make

Test the library (everything should say PASSED)
> make test

Time the routines
> make perf

Install the library to $PREFIX/include and $PREFIX/lib
> make install

---------------------------------------------------------------------
| INTERFACES                                                        |
---------------------------------------------------------------------
The Python interface has the following requirements:
- Python >= 2.5.0
- Numpy >= 1.2.0

Install (as root)
> cd interfaces/python && python setup.py install

---------------------------------------------------------------------
| USAGE                                                             |
---------------------------------------------------------------------
See examples/

---------------------------------------------------------------------
| TODO                                                              |
---------------------------------------------------------------------
In no particular order:
- Better use of cache in kdtree. This might involve using prefetches,
  re-ordering the points in some way or even placing the point data in
  the nodes.
- Other types of approximate search such as LSH and Spectral Hashing.

---------------------------------------------------------------------
| CHANGELOG                                                         |
---------------------------------------------------------------------
v0.22
    - Adding stuff for installing to a specified path
v0.21
    - Added reference
v0.2
    - Moved over to using CMake -- much improved build.
    - Implemented C compatible routines in fastann.h
    - Added Python wrapper routines using ctypes.
    - Faster distance functions for 32-bit and 64-bit platforms.
v0.11
    - Moved to pure static library.
    - Added experimental hand coded double precision distance 
      routine.
v0.1
    - Initial checkin.
    - Support for exact NN and approximate k-d trees.

---------------------------------------------------------------------
| REFERENCES                                                        |
---------------------------------------------------------------------
[1] Muja, M. and Lowe, D.
    Fast approximate nearest neighbors with automatic algorithm 
    configuration, VISAPP 2009
