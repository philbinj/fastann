/**
 * Spectral hashing.
 */

#include <algorithm>
#include <vector>

#include <cstdio>

// From LAPACK
// SUBROUTINE DSYEV( JOBZ, UPLO, N, A, LDA, W, WORK, LWORK, INFO )
extern "C"
void
dsyev_(char* JOBZ, char* UPLO, int* N, double* A, int* LDA, double* W, 
double* WORK, int* LWORK, int* INFO);

namespace fastann {
/**
 * Find the covariance of \c data, a row-major array of the
 * datapoints.
 */
template<class Float>
void
cov(const Float* data, unsigned N, unsigned D,
    double* cov)
{
    // Find the mean.
    std::vector<double> mean(D, 0.0);
    for (unsigned n=0; n < N; ++n) {
        for (unsigned d=0; d < D; ++d) {
            mean[d] += data[n*D + d];
        }
    }
    for (unsigned d=0; d<D; ++d) {
        mean[d] /= N;
    }
    
    // Find the covariance
    std::fill(cov, cov + D*D, 0.0);
    
    for (unsigned n=0; n < N; ++n) {
        for (unsigned d1=0; d1<D; ++d1) {
            for (unsigned d2=0; d2<D; ++d2) {
                cov[d1*D + d2] += (data[n*D + d1] - mean[d1])*(data[n*D + d2] - mean[d2]);
            }
        }
    }
}

template<class Float>
void
proj(const Float* data, unsigned N, unsigned D, unsigned npca, const double* proj, double* proj_data)
{
    for (unsigned n=0; n < N; ++n) {
        for (unsigned p=0; p < npca; ++p) {
            double acc = 0.0;
            for (unsigned d=0; d < D; ++d) {
                acc += data[n*D + d]*proj[p*D + d];
            }
            proj_data[n*npca + p] = acc;
        }
    }
}
/**
 * Find the eigenvector/eigenvalue pairs of a square
 * symmetric covariance matrix \c cov.
 */
int
pca(const double* cov, unsigned D, unsigned nproj,
    double* eigvals, double* eigvecs)
{
    std::vector<double> eigenvectors(cov, cov+D*D);
    std::vector<double> eigenvalues(D);
    // We use the wonderfully difficult to use LAPACK.
    {
        std::vector< double > WORK(3*D - 1);
        double* work = &WORK[0];
        char jobz = 'V'; // Eigenvalues and eigenvectors please.
        char uplo = 'U'; // Doesn't matter.
        int n = D;
        double* a = &eigenvectors[0];
        int lda = D;
        double* w = &eigenvalues[0];
        int lwork = 3*D - 1;
        int info = -1;
        
        dsyev_(&jobz, &uplo, &n, a, &lda, w, work, &lwork, &info);
        
        if (info != 0) {
            fprintf(stderr, "dsyev_ has some issues!\n");
            return 0;
        }
    }
    // We want to return the top nproj eigenvalue/eigenvector pairs
    std::copy(eigenvectors.begin(), eigenvectors.begin() + nproj*D, eigvecs);
    std::copy(eigenvalues.begin(), eigenvalues.begin() + nproj, eigvals);
    
    nproj = std::min(nproj, D);
    for (unsigned p = 0; p < nproj; ++p) {
        eigvals[p] = eigenvalues[D - p - 1];
        for (unsigned d=0; d < D; ++d) {
            eigvecs[p*D + d] = eigenvectors[(D - p - 1)*D + d];
        }
    }
    
    return 1;
}

/**
 * Trains the parameters for spectral hashing.
 *
 * This should be a pretty much one->one mapping to trainSH.m
 */
template<class Float>
void
train_spectral_hash(const Float* data, unsigned N, unsigned D, unsigned nbits)
{
    std::vector<double> cov(D*D);
    unsigned npca = std::min(nbits, D);
    std::vector<double> eigvecs(npca*D, 0.0);
    std::vector<double> eigvals(npca, 0.0);
    std::vector<double> proj_points(npca*N, 0.0);
    std::vector<double> mn(npca, 0.0);
    std::vector<double> mx(npca, 0.0);
//    % algo:
//    % 1) PCA
//    npca = min(nbits, Ndim);
//    [pc, l] = eigs(cov(X), npca);
//    X = X * pc; % no need to remove the mean
    cov(data, N, D, &cov[0]);
    pca(&cov[0], D, npca, &eigvals[0], &eigvecs[0]);
    proj(&data[0], N, D, npca, &eigvecs[0], &proj_points[0]);
    
//    % 2) fit uniform distribution
//    mn = prctile(X, 5);  mn = min(X)-eps;
//    mx = prctile(X, 95);  mx = max(X)+eps;
    for (unsigned n=0; n < N; n++) {
        for (unsigned p=0; p < npca; ++p) {
            mn[p] = std::min(mn[p], proj_points[n*npca + p]);
            mx[p] = std::max(mx[p], proj_points[n*npca + p]);
        }
    }
    
//    % 3) enumerate eigenfunctions
//    R=(mx-mn);
//    maxMode=ceil((nbits+1)*R/max(R));
}

void
hilbert(unsigned N, double* data_out)
{
    for (unsigned i = 0; i < N; ++i) {
        for (unsigned j = 0; j < N; ++j) {
            data_out[i*N + j] = 1.0/(i + j + 1);
        }
    }
}

}
