function [ out ] = textGraph( obj )
%textGraph Summary of this function goes here
%   Detailed explanation goes here
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
    assert(isscalar(obj));
    numLabels = num2str(mod(obj.startFrame : obj.endFrame,10),'%d');
    out = char(zeros(size(obj.tracksFeatIndxCG)));
    out(obj.tracksFeatIndxCG ~= 0) = '.';
    out(gapMask(obj)) = '-';
    out(1:2:end*2,:) = out;
    out(2:2:end,:) = ' ';
    out = [numLabels ; out ];
end

