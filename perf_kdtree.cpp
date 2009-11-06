#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <vector>

#include <stdint.h>

#include "fastann.hpp"
#include "rand_point_gen.hpp"

static inline uint64_t rdtsc()
{
    #ifdef __i386__
    uint32_t a, d;
#elif defined __x86_64__
    uint64_t a, d;
#endif

    asm volatile ("rdtsc" : "=a" (a), "=d" (d));

    return ((uint64_t)a | (((uint64_t)d)<<32));
}

template<class Float>
void
perf_kdtree(unsigned N, unsigned D)
{
    Float* pnts = fastann::gen_unit_random<Float>(N, D, 42);
    Float* qus = fastann::gen_unit_random<Float>(N, D, 43);
    
    std::vector<Float> mins_exact(N);
    std::vector<unsigned> argmins_exact(N);
    std::vector<Float> mins_kdt(N);
    std::vector<unsigned> argmins_kdt(N);

    fastann::nn_obj<Float>* nnobj_exact = fastann::nn_obj_build_exact(pnts, N, D);
    fastann::nn_obj<Float>* nnobj_kdt = fastann::nn_obj_build_kdtree(pnts, N, D, 8, 768);

    uint64_t t1 = rdtsc();
    nnobj_exact->search_nn(qus, N, &argmins_exact[0], &mins_exact[0]);
    uint64_t t2 = rdtsc();
    nnobj_kdt->search_nn(qus, N, &argmins_kdt[0], &mins_kdt[0]);
    uint64_t t3 = rdtsc();
    
    double exact_clocks_per_dim = (double)(t2 - t1)/(N*D*N);
    double approx_clocks_per_dim = (double)(t3 - t2)/(N*D*768);
    printf("Exact clocks per dimension = %.3f\n", exact_clocks_per_dim);
    printf("Approx clocks per dimension = %.3f\n", approx_clocks_per_dim);
    
    unsigned num_same = 0;
    for (unsigned n = 0; n < N; ++n) {
        if (argmins_exact[n] == argmins_kdt[n]) num_same++;
    }
    
    //double accuracy = (double)num_same/N;
    //printf("Accuracy: %.1f%%\n", accuracy*100.0);

    delete[] pnts;
    delete[] qus;

    delete nnobj_exact;
    delete nnobj_kdt;
}

int
main()
{
    unsigned N = 10000;
    unsigned D = 128;
    
    perf_kdtree<float>(N, D);
    
    return 0;
}
