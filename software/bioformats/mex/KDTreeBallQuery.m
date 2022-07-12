%KDTREEBALLQUERY finds all of the points which are within the specified radius of the query points
% 
% [idx, dist] = KDTreeBallQuery(inPts,queryPts,radii)
% 
% This function returns the indices of the input points which are within
% the specified radii of the query points. Supports 1D, 2D or 3D point sets. 
% In other words, this returns all the indices of the input points which are
% contained in the spheres whose centers are given by the query points and
% whose radii are given by the input radii vector.
%
% Input:
% 
%     inPts - an MxK matrix specifying the input points to test for distance
%     from the query points, where M is the number of points and K is the
%     dimensionality of the points.
% 
%     queryPts - an NxK matrix specifying the query points, e.g. the centers of
%     the spheres within which input points will be found.
% 
%     radii - an Nx1 vector or a scalar specifying the distances from each 
%     query point to find input points, e.g. the radii of the spheres within 
%     which input points will be found. If scalar, the same radius is used
%     for all query points.
%     NOTE: This value should be of class double, or strange behavior may
%     occur.
% 
% 
% Output:
% 
%   idx - Nx1 cell array, the n-th element of which gives the indices of
%   the input points which are within the n-th radii of the n-th query
%   point.
% 
%   dist - Nx1 cell array, the n-th element of which gives the corresponding 
%   distances between the input points and the n-th query point.
%