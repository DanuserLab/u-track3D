classdef NewUTrack3DPackage < Package
    % The main class of the New UTack 3D Package
    %
    % Qiongjing (Jenny) Zou, July 2019
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
    
    methods
        function obj = NewUTrack3DPackage(owner, varargin)
        	% Construntor of class NewUTrack3DPackage
            if nargin == 0
                super_args = {};
            else
                % Check input
                ip =inputParser;
                ip.addRequired('owner',@(x) isa(x,'MovieData'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                
                super_args{1} = owner;
                super_args{2} = [outputDir  filesep 'NewUTrack3DPackage'];
            end
                 
            % Call the superclass constructor
            obj = obj@Package(super_args{:});        
        end
    end
    
    methods (Static)
        
        function name = getName()
            name = 'New U-Track 3D';
        end

        function m = getDependencyMatrix(i,j)  % QZ come back to this later
            %    1 2 3 4 5 6 7 {processes}           
            m = [0 0 0 0 0 0 0;  %1 RenderFullMIPProcess
                 0 0 0 0 0 0 0;  %2 PointSourceDetectionProcess3D
                 0 1 0 0 0 0 0;  %3 TrackingProcess
                 0 0 1 0 0 0 0;  %4 BuildDynROIProcess
                 0 0 0 1 0 0 0;  %5 RenderDynROIMIPProcess
                 0 0 0 1 0 0 0;  %6 PointSourceDetectionProcess3DDynROI
                 0 0 0 1 0 1 0;];%7 TrackingDynROIProcess
            if nargin<2, j=1:size(m,2); end
            if nargin<1, i=1:size(m,1); end
            m=m(i,j);
        end

        function varargout = GUI(varargin)
            % Start the package GUI
            varargout{1} = NewUTrack3DPackageGUI(varargin{:});
        end

        function procConstr = getDefaultProcessConstructors(index)
            procContrs = {
                @RenderFullMIPProcess,...
                @PointSourceDetectionProcess3D,...
                @TrackingProcess, ...
                @BuildDynROIProcess, ...
                @RenderDynROIMIPProcess , ...
                @PointSourceDetectionProcess3DDynROI , ...
                @TrackingDynROIProcess};
            
            if nargin==0, index=1:numel(procContrs); end
            procConstr=procContrs(index);
        end

        function classes = getProcessClassNames(index)
            classes = {
                'RenderFullMIPProcess',...
                'PointSourceDetectionProcess3D',...
                'TrackingProcess',...
                'BuildDynROIProcess',...
                'RenderDynROIMIPProcess',...
                'PointSourceDetectionProcess3DDynROI',...
                'TrackingDynROIProcess'};
            if nargin==0, index=1:numel(classes); end
            classes=classes(index);
        end
    end
    
end