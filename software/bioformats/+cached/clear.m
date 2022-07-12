function [ ] = clear( )
%cached.CLEAR Clears out the cache of all functions in the cached package
%
% Currently this includes
% cached.load
% cached.imfinfo

cached.load('-clear');
cached.imfinfo('-clear');

end

