function [pos,imgLoG] = fastFindBlobFinder(vol, sigma,varargin)
% P. Roudot 2018
%
% Copyright (C) 2020, Danuser Lab - UTSouthwestern 
%
% This file is part of NewUtrack3DPackage.
% 
% NewUtrack3DPackage is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% NewUtrack3DPackage is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with NewUtrack3DPackage.  If not, see <http://www.gnu.org/licenses/>.
% 
% 
ip = inputParser;
ip.CaseSensitive = false;
ip.KeepUnmatched = true;
ip.addRequired('vol', @isnumeric);
ip.addRequired('sigma', @isnumeric);
ip.parse(vol, sigma, varargin{:});

if ~isa(vol, 'double')
    vol = double(vol);
end


[mask, ~, imgLoG] =pointSourceStochasticFiltering(vol, sigma, varargin{:});

disp('locmax3d');
tic;
localMaxWindowSize=max(3,roundOddOrEven(ceil(2*sigma([1 1 2])),'odd'));
allMax = locmax3d(imgLoG.*mask, localMaxWindowSize, 'ClearBorder', false);
toc;

lmIdx = find(allMax~=0);
[lmy,lmx,lmz] = ind2sub(size(vol), lmIdx);
pos=[lmy,lmx,lmz];
