%FITGAUSSIANMIXTURE2D Fit a 3-D Gaussian mixture model to input volume
%    [prmVect prmStd C res J] = fitGaussianMixture3D(data, prmVect, mode, options)
%
%    Symbols: xp : x-position
%             yp : y-position
%             zp : y-position
%              A : amplitude
%              s : x,y standard deviation
%              r : z standard deviation
%              c : background
%
%    The origin is defined at (1,1,1).
%
%    Inputs:     data : 3-D image volume
%             prmVect : Parameter vector with order: 
%                       [xp_1 yp_1 zp_1 A_1 ... xp_n yp_n zp_n A_n s r c].
%                       The number of tuples [xp yp zp A] determines the number of Gaussians. 
%                mode : String that defines parameters to be optimized; any among 'xyzasrc'.
%           {options} : Vector [maxIter eAbs eRel]; max. iterations, tolerances. See GSL documentation.
%
%    Voxels in 'data' that are set to NaN are ignored in the optimization.
%
%    Outputs: prmVect : parameter vector
%              prmStd : parameter standard deviations
%                   C : covariance matrix
%                 res : structure with fields:
%                         .data : residuals
%                         .pval : p-value of the Kolmogorov-Smirnov test (normal dist.)
%                         .mean : mean of the residuals
%                         .std  : standard deviation of the residuals
%                   J : Jacobian
%
% Axis conventions: image processing, see meshgrid
% For single Gaussian fitting, fitGaussian3D() is faster.
%
% Example: [prmVect prmStd C res J] = fitGaussianMixture3D(data, [0 0 0 max(data(:)) 0 0 0 max(data(:)) 1.5 1.5 min(data(:))], 'xyzasrc');

% Francois Aguet, 02/2014