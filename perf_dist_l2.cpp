/**
 * Tests all the routines in dist_l2.hpp for correctness.
 **/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>

#include "dist_l2_funcs.hpp"
#include "rand_point_gen.hpp"

namespace fastann {

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

template<class Func, class Float, class AccumFloat>
void
compute_distance_matrix(Func func,
                        const Float* pnts, unsigned N, unsigned D,
                        AccumFloat* dm_out)
{
    for (unsigned n=0; n < N; ++n) {
        func(pnts + n*D, pnts, N, D, dm_out + n*N);
    }
}

template<class Func, class Float, class AccumFloat>
double
time_routine(AccumFloat dummy,
             const Float* pnts,
             unsigned N, unsigned D,
             Func func)
{
    AccumFloat* dm = new AccumFloat[N*N];

    uint64_t t1 = rdtsc();
    compute_distance_matrix(func, pnts, N, D, dm);
    compute_distance_matrix(func, pnts, N, D, dm);
    compute_distance_matrix(func, pnts, N, D, dm);
    uint64_t t2 = rdtsc();

    delete[] dm;

    return ((double)(t2 - t1)/(N * N * D));
}

struct cl2func_name_pair
{
    cl2func func;
    const char* name;
};

struct sl2func_name_pair
{
    sl2func func;
    const char* name;
};

struct dl2func_name_pair
{
    dl2func func;
    const char* name;
};

void
perf(int N, int D)
{
    static const cl2func_name_pair cfuncs[] = {
        { &cl2s, "cl2s" },
        { &cl2f_1_8, "cl2f_1_8" },
#ifdef __SSE2__
        { &cl2v_2_32, "cl2v_2_32" },
#endif
    };

    static const sl2func_name_pair sfuncs[] = {
        { &sl2s, "sl2s" },
        { &sl2f_1_8, "sl2f_1_8" },
#ifdef __SSE__
        { &sl2u_2_8, "sl2u_2_8" },
#ifdef EXPERIMENTAL_ASM
        { &sl2u_2_16_exp, "sl2u_2_16_exp" },
#endif
#endif
    };

    static const dl2func_name_pair dfuncs[] = {
        { &dl2s, "dl2s" },
        { &dl2f_1_8, "dl2f_1_8" },
#ifdef __SSE2__
        { &dl2v_2_8, "dl2v_2_8" },
#ifdef EXPERIMENTAL_ASM
        { &dl2v_2_8_exp, "dl2v_2_8_exp" },
//        { &dl2v_2_8_exp2, "dl2v_2_8_exp2" },
#endif
#endif
    };
    
    unsigned char* pnts_uc;
    float* pnts_s;
    double* pnts_d;

    // Arrays of points
    pnts_d = gen_unit_random<double>(N, D, 42);
    pnts_s = new float[N*D];
    pnts_uc = new unsigned char[N*D];
    
    for (int i=0; i < N*D; ++i) pnts_s[i] = (float)pnts_d[i];
    for (int i=0; i < N*D; ++i) pnts_uc[i] = (unsigned char)(256.0*pnts_d[i]);

    double uc_bl = time_routine((unsigned)0, pnts_uc, N, D, &cl2s);
    double s_bl = time_routine(0.0f, pnts_s, N, D, &sl2s);
    double d_bl = time_routine(0.0, pnts_d, N, D, &dl2s);

    // UC
    for (size_t i=0; i < sizeof(cfuncs)/sizeof(cl2func_name_pair); ++i) {
        double dt = time_routine((unsigned)0, pnts_uc, N, D, cfuncs[i].func);
        printf("%10d %10d %30s %10.2f %10.2f\n", N, D, cfuncs[i].name, dt, dt/uc_bl);
    }
    
    // S
    for (size_t i=0; i < sizeof(sfuncs)/sizeof(sl2func_name_pair); ++i) {
        double dt = time_routine(0.0f, pnts_s, N, D, sfuncs[i].func);
        printf("%10d %10d %30s %10.2f %10.2f\n", N, D, sfuncs[i].name, dt, dt/s_bl);
    }
    
    // D
    for (size_t i=0; i < sizeof(dfuncs)/sizeof(dl2func_name_pair); ++i) {
        double dt = time_routine(0.0, pnts_d, N, D, dfuncs[i].func);
        printf("%10d %10d %30s %10.2f %10.2f\n", N, D, dfuncs[i].name, dt, dt/d_bl);
    }

    delete[] pnts_d;
    delete[] pnts_s;
    delete[] pnts_uc;
}

}

int
main()
{
    static const int N_D_pairs[][2] =
    {   {500, 16}, {500, 32}, {500,50}, {500, 64},
        {500, 128}, {500, 256} };

   for (size_t i=0; i < sizeof(N_D_pairs)/sizeof(int[2]); ++i) {
       fastann::perf(N_D_pairs[i][0], N_D_pairs[i][1]);
   }

   return 0;
}
