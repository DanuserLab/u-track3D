%IMSC Wrapper function to SC which replicates display behaviour of IMAGESC
%
% Examples:
%   imsc(I, varargin)
%   imsc(x, y, I, varargin)
%   h = imsc(...)
%
% IN:
%    x - 1xJ vector of x-axis bounds. If x(1) > x(2) the image is flipped
%        left-right. If J > 2 then only the first and last values are used.
%        Default: [1 size(I, 2)].
%    y - 1xK vector of y-axis bounds. If y(1) > y(2) the image is flipped
%        up-down. If K > 2 then only the first and last values are used.
%        Default: [1 size(I, 1)].
%    I - MxNxC input image.
%    varargin - Extra input parameters passed to SC. See SC's help for more
%               information.
%
% OUT:
%    h - Handle of the image graphics object generated.
%
% See also IMAGESC, SC.
%
% Copyright (C) 2021, Danuser Lab - UTSouthwestern 
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

% Copyright: Oliver Woodford, 2010

function h = imsc(varargin)

% Check for x, y as first two inputs
if nargin > 2 && isvector(varargin{1}) && numel(varargin{1}) > 1 && isvector(varargin{2}) && numel(varargin{2}) > 1
    % Render
    [I, clim, map] = sc(varargin{3:end});
    % Display
    h = image(varargin{1}([1 end]), varargin{2}([1 end]), I);
else
    % Render
    [I, clim, map] = sc(varargin{:});
    % Display
    h = image(I);
end
% Fix up colormap, if there is one
if ~isempty(clim)
    set(h, 'CDataMapping', 'scaled');
    ha = get(h, 'Parent');
    try
        colormap(ha, map);
    catch
        set(get(ha, 'Parent'), 'Colormap', map);
    end
    if clim(1) == clim(2)
        clim(2) = clim(2) + 1;
    end
    set(ha, 'CLim', clim);
end
% Don't display the handle if not requested
if nargout < 1
    clear h
end