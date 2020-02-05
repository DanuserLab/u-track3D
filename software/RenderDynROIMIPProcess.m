classdef  RenderDynROIMIPProcess < RenderFullMIPProcess
    % Process Class for render dynamic ROI Maximum Intensity Projections (MIP)
    % RenderFullMIP.m is the wrapper function
    % RenderDynROIMIPProcess is part of New Utrack 3D package
    % 
    % This process class is a subclass of RenderFullMIPProcess class.
    % So different getName and funParams.OutputDirectory can be put for this process.
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
    
    methods (Access = public)
        function obj = RenderDynROIMIPProcess(owner, varargin)
            
            if nargin == 0
                super_args = {};
            else
                % Input check
                ip = inputParser;
                ip.CaseSensitive = false;
                ip.KeepUnmatched = true;
                ip.addRequired('owner',@(x) isa(x,'MovieData'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;

                super_args{1} = owner;
                super_args{2} = RenderDynROIMIPProcess.getName;
                super_args{3} = @RenderFullMIP;
                if isempty(funParams)
                    funParams = RenderDynROIMIPProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end
            obj = obj@RenderFullMIPProcess(super_args{:});
            obj.is3Dcompatible_ = false; % outputs are 2D % QZ ask P output 2D or 3D???
        end

    end


    methods (Static)
        function name = getName()
            name = 'Render Dynamic ROI Maximum Intensity Projection';
        end

        function h = GUI(varargin)
            h = @RenderFullMIPProcessGUI;
        end
        
        function funParams = getDefaultParams(owner, varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir', owner.outputDirectory_, @ischar);
            ip.parse(owner, varargin{:})
            outputDir = ip.Results.outputDir;
            
            % Set default parameters
            funParams.ChannelIndex = 1:numel(owner.channels_);
            funParams.OutputDirectory = [outputDir  filesep 'RenderMIPInROI'];

            
            %% Rendering parameter:

            %% 1) Mandatory parameters
            funParams.renderFrames=1:owner.nFrames_; % if not from 1, algorithm will fail.
            % The frames to be renderered
            % funParams.processChannel=1:numel(owner.channels_); % deleted b/c same as funParams.ChannelIndex
            % The channel to be rendered

            %% 2) Parameters that may not make sense in the GUI
            funParams.processBuildDynROI=[];
            funParams.buildDynROIProcessChannel=1; % Added for the setting GUI, but not used in the wrapper func.
            % Specifying the dynROI we want to look at by selecting the
            % process that build them. In V1, we specify only a single ROI.
            % However, it will be also useful for many user to render many
            % ROI, for example small views around trajectories

            funParams.dynROIRenderingSamplingNumber=3;
            % Specigying how many ROI we want to render, usefull when
            % <BuilDynROI> produde multiple DynROI.

            %% 3) Parameter that may not make sense as a "setting" but maybe
            %% in the "results" section
            funParams.gamma=1;
            funParams.contrastIn=[0 1];
            funParams.contrastOut=[0 1];
            % The class output two types of image:  1) The raw mips, or 2) the
            % blended channels view that is only used for script and that are
            % independent from Matlab Graphic Back-end. The above parameters
            % are the one of the matlab built-in function  <imadjust> function
            % and only affect the second output. Ideally, the viewer dialog
            % only uses the raw mips and enable the adjustement of image
            % contrast on-the-fly, hence those parameter belong into the
            % results viewer.

            funParams.channelRender='stereo'; 
            % Same as above. The second output is rendered according to the
            % <channelRender> option. This is an option for viewing rather
            % than generating.

            %% 4) Parameters hidden from the GUI
            funParams.preProcessedMovie=[];
            % Specify a FilteringProcess instance to view  a processes movie
            % instead of the raw data. May be useful later but probably not
            % for an early development stage

            funParams.mipSize=500;
            % The scale of the image should probably decided by the GUI

            % Other legacy parameters
            funParams.insetROI=[];
            funParams.insetOnly=false;
            funParams.V2=true; % if false, algorithm will fail!
            funParams.debug=false;
            funParams.ZRight=false;
            funParams.Zup=false;
            funParams.intMinPrctil=[1 1];
            funParams.intMaxPrctil=[100 100];

        end
        
    end
end