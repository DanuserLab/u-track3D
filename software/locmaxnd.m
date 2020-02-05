function [lm] = locmaxnd(img, windowRadius)

    ip = inputParser;
    ip.CaseSensitive = false;
    ip.addRequired('img', @(x) isnumeric(x));
    ip.addRequired('windowRadius', @(x) isnumeric(x) &&  all(x >= 1) && (isscalar(x) || numel(x) == ndims(img)));
    ip.parse(img, windowRadius);

    if any(windowRadius - floor(windowRadius) > 0)
        error('windowRadius must be integer');
    end
    
    if numel(windowRadius) == 1
        windowRadius = windowRadius * ones(1, ndims(img));
    end
    
    mask = true(2 * windowRadius + 1);
    lm = imdilate(img, mask);
    lm(lm~=img) = 0;
    
end
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
