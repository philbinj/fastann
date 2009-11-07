import fastann
import numpy as np
import numpy.random as npr

A = npr.rand(10000,128)
B = npr.rand(10000,128)

nno = fastann.build_exact(A)
argmins, mins = nno.search_nn(B)
nno_kdt = fastann.build_kdtree(A, 8, 768)
argmins_kdt, mins_kdt = nno_kdt.search_nn(B)

print float(np.sum(argmins == argmins_kdt))/10000
