
function checked = userfcn_saveCheckbox(handles)
% GUI tool function - return the check/uncheck status of checkbox of 
% processes in package control panel 
%
% Input:
%
%   handles - the "handles" of package control panel movie 
%   
% Output:
%
%   checked - array of check/unchecked status  1 - checked, 0 - unchecked
%
%
% Chuangang Ren
% 08/2010
%
% Copyright (C) 2022, Danuser Lab - UTSouthwestern 
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

userData = get(handles.figure1, 'UserData');
l = 1:size(userData.dependM, 1);

checked = arrayfun( @(x) get(handles.(['checkbox_' num2str(x)]), 'Value'), l, 'UniformOutput', true);
