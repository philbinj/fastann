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
- Linux GCC or Cygwin (native windows coming soon)

Build the library
> make

Test the library (everything should say PASSED)
> make test

Install the library to /usr/include and /usr/lib
> make install

---------------------------------------------------------------------
| USAGE                                                             |
---------------------------------------------------------------------
See examples/
C++ example:
    #include <fastann/fastann.hpp>
    
    float* pnts = ...; // Points to search over go here
    
    fastann::nn_obj<float>* nno = 
       fastann::nn_obj_build_kdtree(pnts, npoints, ndims, 8, 768);
    
    float* qus = ...; // Points to query go here
    float* mins[nqueries];
    unsigned* argmins[nqueries];
    
    nno->search_nn(qus, nqueries, argmins, mins);

---------------------------------------------------------------------
| TODO                                                              |
---------------------------------------------------------------------
In no particular order:
- C interface (for easy use with Python / Matlab)
- Improved distance functions (gcc makes a cockup of some of the
  intrinsics based ones like the double precision ones.
- Better use of cache in kdtree. This might involve using prefetches,
  re-ordering the points in some way or even placing the point data in
  the nodes.
- Other types of approximate search such as LSH and Spectral Hashing.

---------------------------------------------------------------------
| CHANGELOG                                                         |
---------------------------------------------------------------------
v0.1
    - Initial checkin.
    - Support for exact NN and approximate k-d trees.
