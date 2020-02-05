function varargout = NewUTrack3DPackageGUI(varargin)
% Launch the GUI for the New UTack 3D Package
%
% This function calls the generic packageGUI function, passes all its input
% arguments and returns all output arguments of packageGUI
%
%
% Qiongjing (Jenny) Zou, July 2019
%
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

if nargin>0 && isa(varargin{1},'MovieList')
    varargout{1} = packageGUI('NewUTrack3DPackage',[varargin{1}.getMovies{:}],...
        varargin{2:end}, 'ML', varargin{1});
else
    varargout{1} = packageGUI('NewUTrack3DPackage',varargin{:});
end
end