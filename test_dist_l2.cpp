/**
 * Tests all the routines in dist_l2.hpp for correctness.
 **/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "dist_l2_funcs.hpp"
#include "rand_point_gen.hpp"

namespace fastann {

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

template<class Float>
bool
is_almost_equal(const Float* m1, const Float* m2, unsigned S, double eps)
{
    for (unsigned s=0; s < S; ++s) {
        if (fabs((double)m1[s] - (double)m2[s]) > eps) return false;
    }
    return true;
}

template<class Func, class Float, class AccumFloat>
bool
test_routine(const AccumFloat* dm_known_good,
             const Float* pnts,
             unsigned N, unsigned D,
             Func func, 
             double eps)
{
    AccumFloat* dm = new AccumFloat[N*N];

    compute_distance_matrix(func, pnts, N, D, dm);
    bool ret = is_almost_equal(dm_known_good, dm, N*N, eps);

    delete[] dm;

    return ret;
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
test(int N, int D, int& num_passed, int& num_failed)
{
    static const cl2func_name_pair cfuncs[] = {
        { &cl2f_1_8, "cl2f_1_8" },
#ifdef __SSE2__
        { &cl2v_2_32, "cl2v_2_32" },
#endif
    };

    static const sl2func_name_pair sfuncs[] = {
        { &sl2f_1_8, "sl2f_1_8" },
#ifdef __SSE__
        { &sl2u_2_8, "sl2u_2_8" },
#ifdef EXPERIMENTAL_ASM
        { &sl2u_2_16_exp, "sl2u_2_16_exp" },
#endif
#endif
    };

    static const dl2func_name_pair dfuncs[] = {
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
    unsigned* pnts_uc_dm_slow = new unsigned[N*N];
    float* pnts_s_dm_slow = new float[N*N];
    double* pnts_d_dm_slow = new double[N*N];

    compute_distance_matrix(&cl2s, pnts_uc, N, D, pnts_uc_dm_slow);
    compute_distance_matrix(&sl2s, pnts_s, N, D, pnts_s_dm_slow);
    compute_distance_matrix(&dl2s, pnts_d, N, D, pnts_d_dm_slow);

    // UC
    for (size_t i=0; i < sizeof(cfuncs)/sizeof(cl2func_name_pair); ++i) {
        bool res = test_routine(pnts_uc_dm_slow, pnts_uc, N, D, cfuncs[i].func, 0.0);
        if (res) {
            printf("%10d %10d %30s %20s\n", N, D, cfuncs[i].name, "PASSED");
            num_passed++;
        }
        else {
            printf("%10d %10d %30s %20s\n", N, D, cfuncs[i].name, "FAILED");
            num_failed++;
        }
    }
    
    // S
    for (size_t i=0; i < sizeof(sfuncs)/sizeof(sl2func_name_pair); ++i) {
        bool res = test_routine(pnts_s_dm_slow, pnts_s, N, D, sfuncs[i].func, 1.e-4);
        if (res) {
            printf("%10d %10d %30s %20s\n", N, D, sfuncs[i].name, "PASSED");
            num_passed++;
        }
        else {
            printf("%10d %10d %30s %20s\n", N, D, sfuncs[i].name, "FAILED");
            num_failed++;
        }
    }
    
    // D
    for (size_t i=0; i < sizeof(dfuncs)/sizeof(dl2func_name_pair); ++i) {
        bool res = test_routine(pnts_d_dm_slow, pnts_d, N, D, dfuncs[i].func, 1.e-10);
        if (res) {
            printf("%10d %10d %30s %20s\n", N, D, dfuncs[i].name, "PASSED");
            num_passed++;
        }
        else {
            printf("%10d %10d %30s %20s\n", N, D, dfuncs[i].name, "FAILED");
            num_failed++;
        }
    }

    delete[] pnts_d_dm_slow;
    delete[] pnts_s_dm_slow;
    delete[] pnts_uc_dm_slow;

    delete[] pnts_d;
    delete[] pnts_s;
    delete[] pnts_uc;
}

}

int
main()
{
    int num_failed = 0;
    int num_passed = 0;
    static const int N_D_pairs[][2] =
    { {1000, 1}, {1000, 2}, {1000, 3}, 
        {1000, 7}, {1000, 8}, {1000, 9},
        {1000, 15}, {1000, 16}, {1000, 17}, {1000, 18},
        {1000, 30}, {1000, 32}, {1000, 33}, {1000, 34},
        {500, 128}, {500, 135}, {500, 255} };

   for (size_t i=0; i < sizeof(N_D_pairs)/sizeof(int[2]); ++i) {
       fastann::test(N_D_pairs[i][0], N_D_pairs[i][1], num_passed, num_failed);
   }

   printf("NUM_PASSED %d  NUM_FAILED %d\n", num_passed, num_failed);

   if (num_failed)
       return -1;
   else
       return 0;

}
