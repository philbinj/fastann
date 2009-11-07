"""
Python wrapper around libfastann.
"""

import numpy
import ctypes

lib = ctypes.CDLL('libfastann.so')

def get_suffix(dtype):
    return {numpy.dtype('u1') : 'c',
            numpy.dtype('f4') : 's',
            numpy.dtype('f8') : 'd'}[dtype]

class nn_obj(object):
    def __init__(self, ptr, pnts):
        self.ptr = ptr
        self.pnts = pnts # This is so we keep a reference around
        self.dtype = pnts.dtype
        self.suffix = get_suffix(self.dtype)

    def __del__(self):
        getattr(lib, "fastann_nn_obj_del_" + self.suffix)(self.ptr)

    def search_nn(self, qus):
        qus = numpy.ascontiguousarray(qus)
        if qus.dtype != self.dtype:
            raise TypeError, 'query type must be the same as the base type'
        
        N = ctypes.c_uint(qus.shape[0])
        argmins = numpy.empty((qus.shape[0],), dtype='u4')
        mins = numpy.empty((qus.shape[0],), dtype = ('u4' if self.dtype=='u1' else self.dtype))

        qus_p = qus.ctypes.data_as(ctypes.c_void_p)
        argmins_p = argmins.ctypes.data_as(ctypes.c_void_p)
        mins_p = mins.ctypes.data_as(ctypes.c_void_p)

        getattr(lib, "fastann_nn_obj_search_nn_" + self.suffix)(self.ptr, qus_p, N, argmins_p, mins_p)

        return argmins, mins

    def search_knn(self, qus, K):
        qus = numpy.ascontiguousarray(qus)
        if qus.dtype != self.dtype:
            raise TypeError, 'query type must be the same as the base type'
        
        N = ctypes.c_uint(qus.shape[0])
        argmins = numpy.empty((qus.shape[0],K), dtype='u4')
        mins = numpy.empty((qus.shape[0],K), dtype = ('u4' if self.dtype=='u1' else self.dtype))

        K = ctypes.c_uint(K)
        qus_p = qus.ctypes.data_as(ctypes.c_void_p)
        argmins_p = argmins.ctypes.data_as(ctypes.c_void_p)
        mins_p = mins.ctypes.data_as(ctypes.c_void_p)

        getattr(lib, "fastann_nn_obj_search_knn_" + self.suffix)(self.ptr, qus_p, N, K, argmins_p, mins_p)

        return argmins, mins

    def ndims(self):
        return getattr(lib, "fastann_nn_obj_ndims_" + self.suffix)(self.ptr)

    def npoints(self):
        return getattr(lib, "fastann_nn_obj_npoints_" + self.suffix)(self.ptr)

def build_exact(pnts):
    """
    Build an exact nn object from these points.
    """

    # pnts must be contiguous for the library
    pnts = numpy.ascontiguousarray(pnts)
    N = ctypes.c_uint(pnts.shape[0])
    D = ctypes.c_uint(pnts.shape[1])
    pnts_p = pnts.ctypes.data_as(ctypes.c_void_p)

    if pnts.dtype not in ['u1', 'f4', 'f8']:
        raise TypeError, 'datatype %s not currently supported' % pnts.dtype

    suffix = get_suffix(pnts.dtype)

    ptr = getattr(lib, "fastann_nn_obj_build_exact_" + suffix)(pnts_p, N, D)

    return nn_obj(ptr, pnts)

def build_kdtree(pnts, ntrees, nchecks):
    """
    Build an approximate k-d forest from these points.
    """

    # pnts must be contiguous for the library
    pnts = numpy.ascontiguousarray(pnts)
    N = ctypes.c_uint(pnts.shape[0])
    D = ctypes.c_uint(pnts.shape[1])
    pnts_p = pnts.ctypes.data_as(ctypes.c_void_p)

    if pnts.dtype not in ['u1', 'f4', 'f8']:
        raise TypeError, 'datatype %s not currently supported' % pnts.dtype

    suffix = get_suffix(pnts.dtype)

    ptr = getattr(lib, "fastann_nn_obj_build_kdtree_" + suffix)(pnts_p, N, D, ctypes.c_uint(ntrees), ctypes.c_uint(nchecks))

    return nn_obj(ptr, pnts)
