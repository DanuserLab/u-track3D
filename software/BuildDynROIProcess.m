classdef  BuildDynROIProcess < Process & NonSingularProcess
    % Process Class for Build Dynamic Region of Interest (ROI)
    % BuildDynamicROI.m is the wrapper function
    % BuildDynROIProcess is part of New Utrack 3D package
    % 
    % This process class was modified from BuilDynROI.m classes.
    % 
    % swapFile_ property and its related functions are added according to
    % BuilDynROI, otherwise algorithm will fail.
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

    properties
        swapFile_
    end
    
    methods (Access = public)
        function obj = BuildDynROIProcess(owner, varargin)
            
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
                super_args{2} = BuildDynROIProcess.getName;
                super_args{3} = @BuildDynamicROI;
                if isempty(funParams)
                    funParams = BuildDynROIProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end
            % obj = obj@DetectionProcess(super_args{:});
            obj = obj@Process(super_args{1:2});
            obj.funName_ = super_args{3};
            obj.funParams_ = super_args{4};

            obj.is3Dcompatible_ = true;
        end

        function swap(obj)
            dynROIs=obj.loadChannelOutput();
            swapFile=cell(1,numel(dynROIs));
            for dIdx=1:numel(dynROIs)
                [MD,MDFile]=dynROIs{dIdx}.swapRawBoundingBox(obj.getOwner(),[obj.getProcessTag() '-swap']);
                swapFile{dIdx}=MDFile;
            end
            obj.swapFile_=swapFile;
        end
        
        function res=isSwaped(obj)
            res=~isempty(obj.swapFile_);
        end

        function MD=loadSwap(obj,dynROIIdx)
            MD=MovieData.loadMatFile(obj.swapFile_{dynROIIdx});
        end

        function status = checkChannelOutput(obj,iChan) % adapted from DetectionProcess
            
            %Checks if the selected channels have valid output files
            nChan = numel(obj.owner_.channels_);
            if nargin < 2 || isempty(iChan), iChan = 1:nChan; end
            
            status=  ismember(iChan,1:nChan) & ....
                arrayfun(@(x) exist(obj.outFilePaths_{1,x},'file'),iChan);
        end

        function varargout = loadChannelOutput(obj,iChan,varargin) % adapted from PointSourceDetectionProcess3D with modification
            
            % Input check
            outputList = {'dynRIOCell', 'boundingBox','movieDataDynROICell'};
            ip = inputParser;
            ip.addRequired('iChan',@(x) ismember(x,1:numel(obj.owner_.channels_)));
            ip.addOptional('iFrame',1:obj.owner_.nFrames_,...
                @(x) ismember(x,1:obj.owner_.nFrames_));
            ip.addParameter('useCache',true,@islogical);
            ip.addParameter('iZ',[], @(x) ismember(x,1:obj.owner_.zSize_)); 
            ip.addParameter('output', outputList{1}, @(x) all(ismember(x,outputList)));
            ip.addParameter('projectionAxis3D','Z', @(x) ismember(x,{'Z','X','Y','three'}));
            if nargin > 1
                newiChan = iChan; % saved for movieDataDynROICell
            end
            ip.parse(iChan, varargin{:})
            output = ip.Results.output;
            iFrame = ip.Results.iFrame;
            projAxis3D = ip.Results.projectionAxis3D;
            iZ = ip.Results.iZ;
            ZXRatio = obj.owner_.pixelSizeZ_/obj.owner_.pixelSize_;
            
            if ischar(output),output={output}; end
            varargout = cell(numel(output), 1);
            
            for iout = 1:numel(output)
                switch output{iout}             
                    case 'dynRIOCell'
                        s = cached.load(obj.outFilePaths_{1, iChan}, '-useCache', ip.Results.useCache);
                        varargout{iout} = s.dynROICell;

                    case 'boundingBox'
                        s = cached.load(obj.outFilePaths_{2, iChan}, '-useCache', ip.Results.useCache);

                        if numel(ip.Results.iFrame)>1 % iFrame > 1 should not happen
                            v1 = s.vertices;
                            e1 = s.edges;
                            try
                                validateattributes(v1{1,1},{'double'},{'size',[8,3]})
                                validateattributes(e1{1,1},{'double'},{'size',[12,2]})
                            catch ME
                                error('Dimension mismatch occurred for dynamic ROI bounding box!');
                            end
                        else
                            v1 = s.vertices{iFrame};
                            e1 = s.edges{iFrame};
                            try
                                validateattributes(v1,{'double'},{'size',[8,3]})
                                validateattributes(e1,{'double'},{'size',[12,2]})
                            catch ME
                                error('Dimension mismatch occurred for dynamic ROI bounding box!');
                            end
                        end
                        if ~isempty(v1(:,1)) && ~isempty(iZ) && ~isempty(e1) % if numel(ip.Results.iFrame)==1, v1(:,1) are xCoord, v1(:,2), v1(:,3) are 'yCoord','zCoord'.
                            % Only show Detections in Z. 
                            dataOut = v1;

                            if isempty(dataOut) || numel(dataOut) <1
                                dataOut = [];
                            end
                        else
                            dataOut = [];
                        end
                        dataOutz = obj.convertProjection3D(dataOut, projAxis3D, ZXRatio); % projection3D converted here. Only used converted X & Y, so ZXRatio is not important here.
                        varargout{iout}.vertices = dataOutz;
                        varargout{iout}.edges = e1;
                    case 'movieDataDynROICell'
                          s = cached.load(obj.outFilePaths_{3, iChan}, '-useCache', ip.Results.useCache);
                          load(s.movieDataDynROICell{1});               
                          newMD = MD; % MD built based on DynROI raw images.
                          clear MD;
                          varargout{iout} = newMD.channels_(newiChan).loadImage(iFrame, iZ);
                    otherwise
                        error('Incorrect Output Var type');
                end
            end
        end

        function y = convertProjection3D(obj, x, zAxis, ZXRatio) % adapted from DetectionProcess
            if ~isempty(x)
                switch zAxis
                    case 'Y' %(ZX)
%                     y = horzcat(x(:,3)*ZXRatio,x(:,1),x(:,2));
                        y = horzcat(x(:,3), x(:,1), x(:,2)*ZXRatio);
                    case 'X' % (ZY)
%                     y = horzcat(x(:,3)*ZXRatio,x(:,2),x(:,1));
                        y = horzcat(x(:,3), x(:,2), x(:,1)*ZXRatio);
                    case 'Z'
                        y = x;
                    case 'three'
                        yT = x;
                        % if isa(obj,'PointSourceDetectionProcess3DDynROI')
                        %     s = cached.load(obj.funParams_.processBuildDynROI.outFilePaths_{3,1}, '-useCache', true);
                        %     s1 = cached.load(s.movieDataDynROICell{1}, '-useCache', true); % s1.MD is a movieData built based on DynROI raw images.
                        %     zx = horzcat(x(:,1),x(:,3)+4+s1.MD.imSize_(1), x(:,2)*ZXRatio);
                        %     zy = horzcat(x(:,3)+s1.MD.imSize_(2)+4, x(:,2), x(:,1)*ZXRatio);
                        % else
                        zx = horzcat(x(:,1),x(:,3)+4+obj.owner_.imSize_(1), x(:,2)*ZXRatio);
                        zy = horzcat(x(:,3)+obj.owner_.imSize_(2)+4, x(:,2), x(:,1)*ZXRatio);
                        % end
                        y = vertcat(yT, zx, zy);
                end
            else
                y = x;
            end
        end

        function out = unrelatedProc(obj)
            % This functions was used in movieViewer GUI to disable unralted processes on the overlay panel.
            out = {'^PointSourceDetectionProcess3D$', '^TrackingProcess$', '^BuildDynROIProcess$'};
        end
        
    end
    
    methods (Static)
        function name = getName()
            name = 'Build Dynamic Region of Interest';
        end

        function h = GUI(varargin)
            h = @BuildDynROIProcessGUI;
        end
                
        function output = getDrawableOutput()
            
            output(1).name = 'Dynamic RIO';
            output(1).var = 'boundingBox';             
            output(1).formatData = @boundingBoxFormat;
            output(1).defaultDisplayMethod = @PolygonsDisplay;
            output(1).type = 'overlay';

            output(2).name = 'Dynamic RIO Raw Image';
            output(2).var = 'movieDataDynROICell';             
            output(2).formatData = @mat2gray;
            output(2).defaultDisplayMethod = @ImageDisplay;
            output(2).type = 'image';

        end
        
        function funParams = getDefaultParams(owner, varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir', owner.outputDirectory_, @ischar);
            ip.parse(owner, varargin{:})
            outputDir = ip.Results.outputDir;
            
            % Set default parameters
            funParams.ChannelIndex = 1; % make default to 1 instead of 1:numel(owner.channels_), see funParams.processChannel below
            funParams.OutputDirectory = [outputDir  filesep 'BuildDynROI'];

            % The type of ROI 
            funParams.roiType='fitTrackSetRegistered';
            % Alternative types of ROI:
            % - singleTracks              
            % - singleStaticTracks
            % - fitDetSetRegistered
            % - fitTrackSetFrameByFrame
            % - fitTrackSetRegistered
            % - fitTrackSetStatic
            % - selectROI
            % - randomSampling
            % - allTracks
            % - allTracksStatic

            % Fringe added in addition to box around all tracks
            funParams.fringe=20;
            
            % Used for selection in selectROI
            % funParams.processChannel=1; % deleted b/c same as funParams.ChannelIndex

            % Number of tracks used for singleTracks, singleStaticTracks and randomSampling
            funParams.nSample=3;

            % Track process and associated channel
            funParams.trackProcess=[];
            funParams.trackProcessChannel=1;

            % Detection process and associated channel
            funParams.detectionProcess=[];
            funParams.detectionProcessChannel=1;

            % Absent from the GUI/Advanced parameters
            funParams.processRendererDynROI=[]; % Used for nested ROI (enabled in selectROI, singleTracks)
            funParams.processBuildDynROI=[];
            funParams.detectionsObject=[];
            funParams.trackObjects=[];
            funParams.downSamplePerc=1;
            funParams.movieData=[];

            % This swappingVoxels parameter should be always true, otherwise click 'Dyn ROI raw image' on movieViewer GUI will show errors!
            funParams.swappingVoxels=true; % added 2019-08-21, to show DynROI raw images and save a new built MD based on those raw images.

            funParams.dynROI=[]; % for simple save purposes.
            funParams.resizeFactor=[];
            funParams.lifetimeOnly=false;            
            funParams.angle=pi/6;
        end

        function validTypes =  getValidROITypes()
            validTypes = {'fitTrackSetRegistered',...
                          'singleTracks',...
                          'singleStaticTracks',...
                          'fitDetSetRegistered',...
                          'fitTrackSetFrameByFrame',...
                          'fitTrackSetStatic',...
                          'selectROI',...
                          'randomSampling',...
                          'allTracks',...
                          'allTracksStatic'};
        end

    end
    
    
    
    
    
end
