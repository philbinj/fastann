#include "fastann.hpp"
#include "dist_l2.hpp"
#include "nn_kdtree.hpp"

namespace fastann {

template<class Float>
class nn_obj_exact : public nn_obj<Float>
{
public:
    typedef typename nn_obj<Float>::float_type float_type;
    typedef typename nn_obj<Float>::accum_float_type accum_float_type;

    virtual void search_nn(const float_type* qus, unsigned N,
                           unsigned* argmins, accum_float_type* mins) const
    {
        std::vector< accum_float_type > dsqout(npoints_);
        for (unsigned n=0; n < N; ++n) {
            dist_.func(qus + n*ndims_, pnts_, npoints_, ndims_, &dsqout[0]);

            argmins[n] = (unsigned)(std::min_element(dsqout.begin(), dsqout.end()) - dsqout.begin());
            mins[n] = dsqout[argmins[n]];
        }
    }
    
    virtual void search_knn(const float_type* qus, unsigned N, unsigned K,
                            unsigned* argmins, accum_float_type* mins) const
    {
        std::vector< accum_float_type > dsqout(npoints_);
        std::vector< std::pair<accum_float_type,unsigned> > knn_prs(npoints_);
        for (unsigned n=0; n < N; ++n) {
            dist_.func(qus + n*ndims_, pnts_, npoints_, ndims_, &dsqout[0]);

            for (unsigned p=0; p < npoints_; ++p) knn_prs[p] = std::make_pair(dsqout[p], p);

            std::partial_sort(knn_prs.begin(), knn_prs.begin() + K, knn_prs.end());

            for (unsigned k=0; k < K; ++k) {
                argmins[n*K + k] = knn_prs[k].second;
                mins[n*K + k] = knn_prs[k].first;
            }
        }
    }
    
    virtual unsigned ndims() const { return ndims_; }
    virtual unsigned npoints() const { return npoints_; }

    nn_obj_exact(const Float* pnts, unsigned N, unsigned D)
     : pnts_(pnts), ndims_(D), npoints_(N), dist_(dist_l2_best<Float>(D))
    { }
private:
    const Float* pnts_;
    unsigned ndims_;
    unsigned npoints_;
    dist_l2_wrapper<Float> dist_;
};

template<class Float>
class nn_obj_kdtree : public nn_obj<Float>
{
public:
    typedef typename nn_obj<Float>::float_type float_type;
    typedef typename nn_obj<Float>::accum_float_type accum_float_type;

    virtual void search_nn(const float_type* qus, unsigned N,
                           unsigned* argmins, accum_float_type* mins) const
    {
        for (unsigned n=0; n < N; ++n) {
            std::pair<unsigned, accum_float_type> nn;
            kdt_.search(qus + n*ndims_, dist_, 1, &nn, nchecks_);
            argmins[n] = nn.first;
            mins[n] = nn.second;
        }
    }

    virtual void search_knn(const float_type* qus, unsigned N, unsigned K,
                            unsigned* argmins, accum_float_type* mins) const
    {
        std::vector< std::pair<unsigned, accum_float_type> > nns(K);
        for (unsigned n=0; n < N; ++n) {
            kdt_.search(qus + n*ndims_, dist_, K, &nns[0], nchecks_);
            for (unsigned k=0; k < K; ++k) {
                argmins[n*K + k] = nns[k].first;
                mins[n*K + k] = nns[k].second;
            }
        }
    }

    virtual unsigned ndims() const { return ndims_; }
    virtual unsigned npoints() const { return npoints_; }

    nn_obj_kdtree(const Float* pnts, unsigned N, unsigned D, unsigned ntrees, unsigned nchecks)
     : kdt_(pnts, N, D, ntrees), npoints_(N), ndims_(D), nchecks_(nchecks), dist_(dist_l2_best<Float>(D))
    { }

    virtual ~nn_obj_kdtree() { }

private:
    nn_kdtree<Float> kdt_;
    unsigned npoints_;
    unsigned ndims_;
    unsigned nchecks_;
    dist_l2_wrapper<Float> dist_;
};

template<class Float>
nn_obj<Float>*
nn_obj_build_kdtree(const Float* pnts, unsigned N, unsigned D, unsigned ntrees, unsigned nchecks)
{
    return new nn_obj_kdtree<Float>(pnts, N, D, ntrees, nchecks);
}


template
nn_obj<unsigned char>*
nn_obj_build_kdtree<unsigned char>(const unsigned char* pnts, unsigned N, unsigned D, unsigned ntrees, unsigned nchecks);

template
nn_obj<float>*
nn_obj_build_kdtree<float>(const float* pnts, unsigned N, unsigned D, unsigned ntrees, unsigned nchecks);

template
nn_obj<double>*
nn_obj_build_kdtree<double>(const double* pnts, unsigned N, unsigned D, unsigned ntrees, unsigned nchecks);

template<class Float>
nn_obj<Float>*
nn_obj_build_exact(const Float* pnts, unsigned N, unsigned D)
{
    return new nn_obj_exact<Float>(pnts, N, D);
}
template
nn_obj<unsigned char>*
nn_obj_build_exact(const unsigned char* pnts, unsigned N, unsigned D);
template
nn_obj<float>*
nn_obj_build_exact(const float* pnts, unsigned N, unsigned D);
template
nn_obj<double>*
nn_obj_build_exact(const double* pnts, unsigned N, unsigned D);

}
