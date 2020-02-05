classdef  RenderFullMIPProcess < ImageProcessingProcess & NonSingularProcess
    % Process Class for render full Maximum Intensity Projections (MIP)
    % RenderFullMIP.m is the wrapper function
    % RenderFullMIPProcess is part of New Utrack 3D package
    % 
    % This process class was modified from ComputeMIPProcess.m and RenderDynROI.m classes.
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
        function obj = RenderFullMIPProcess(owner, varargin)
            
            if nargin == 0
                super_args = {};
            elseif nargin == 4 % added for its subclass RenderDynROIMIPProcess
                super_args{1} = owner;
                super_args{2} = varargin{1};
                super_args{3} = varargin{2};
                super_args{4} = varargin{3};
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
                super_args{2} = RenderFullMIPProcess.getName;
                super_args{3} = @RenderFullMIP;
                if isempty(funParams)
                    funParams = RenderFullMIPProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end
            obj = obj@ImageProcessingProcess(super_args{:});
            obj.is3Dcompatible_ = false; % outputs are 2D % QZ ask P output 2D or 3D???
        end

        function h = draw(obj, varargin) % QZ come back to this later
            % Function to draw process output
            outputList = obj.getDrawableOutput();  
                               
            ip = inputParser;
            ip.addRequired('obj',@(x) isa(x,'Process'));
            ip.addRequired('iChan',@isnumeric);
            ip.addOptional('iFrame',[],@isnumeric);
            ip.addOptional('iZ',[], @(x) ismember(x,1:obj.owner_.zSize_)); % since it's 2D MIP, iZ was not used.
            ip.addParameter('output', [], @(x) all(ismember(x,{outputList.var})));
            ip.KeepUnmatched = true;
            ip.parse(obj, varargin{:});

            iChan = ip.Results.iChan;
            iOutput = find(cellfun(@(y) isequal(ip.Results.output,y),{outputList.var}));

            % Initialize display method
            if isempty(obj.getDisplayMethod(iOutput,iChan))
                obj.setDisplayMethod(iOutput, iChan,...
                    outputList(iOutput).defaultDisplayMethod(iChan));
            end

            % Display all channels
            switch ip.Results.output
                case {'merged_XY', 'merged_ZY', 'merged_ZX', 'merged_all_three'}

                    switch ip.Results.output
                        case 'merged_XY'
                            iOutput = 1; % see obj.outputfilePaths_
                        case 'merged_ZY'
                            iOutput = 2; % see obj.outputfilePaths_
                        case 'merged_ZX'
                            iOutput = 3; % see obj.outputfilePaths_
                        case 'merged_all_three'
                            iOutput = 4; % see obj.outputfilePaths_
                    end
                        
                    numChan = numel(obj.owner_.channels_);
                    if numChan > 1, cdim=3; else cdim=1; end
                    imData = obj.loadChannelOutput(1, ip.Results.iFrame, 'iOutput', iOutput, 'outputIs3D', false);
                    data = zeros(size(imData,1),size(imData,2), cdim);
                    data(:,:,1) = outputList(iOutput).formatData(imData);
                    
                    if numChan > 1
                        for iChan = 2:numChan
                            imData = obj.loadChannelOutput(iChan, ip.Results.iFrame, 'iOutput', iOutput, 'outputIs3D', false); 
                            data(:,:,iChan) = outputList(iOutput).formatData(imData);
                        end
                    end                  

                    try
                        assert(~isempty(obj.displayMethod_{iOutput,1}));
                    catch ME
                        obj.displayMethod_{iOutput, 1} = ...
                            outputList(iOutput).defaultDisplayMethod();
                    end

                    % Create graphic tag and delegate drawing to the display class
                    tag = ['process' num2str(obj.getIndex()) ip.Results.output 'Output'];
                    h = obj.displayMethod_{iOutput, 1}.draw(data, tag, ip.Unmatched);
                
                case {'XY','ZY','ZX','three'}

                    imData = obj.loadChannelOutput(iChan, ip.Results.iFrame, 'iOutput', iOutput, 'outputIs3D', false);
                    data = outputList(iOutput).formatData(imData);

                    try
                        assert(~isempty(obj.displayMethod_{iOutput,iChan}));
                    catch ME
                        obj.displayMethod_{iOutput, iChan} = ...
                            outputList(iOutput).defaultDisplayMethod();
                    end

                    tag = ['process' num2str(obj.getIndex()) '_channel' num2str(iChan) '_output' num2str(iOutput)];
                    h = obj.displayMethod_{iOutput, iChan}.draw(data, tag, ip.Unmatched);
                
                otherwise
                    error('Incorrect Output Var type');
            end
        end
        
        function output = getDrawableOutput(obj, varargin)  % QZ come back to this later
        
            n = 1;
            output(n).name = 'XY';
            output(n).var = 'XY';
            output(n).formatData = @mat2gray;
            output(n).defaultDisplayMethod = @ImageDisplay;
            output(n).type = 'image';
            
            n = length(output)+1;
            output(n).name = 'ZY';
            output(n).var = 'ZY';
            output(n).formatData = @mat2gray;
            output(n).defaultDisplayMethod = @ImageDisplay;
            output(n).type = 'image';
            
            n = length(output)+1;
            output(n).name = 'ZX';
            output(n).var = 'ZX';
            output(n).formatData = @mat2gray;
            output(n).defaultDisplayMethod = @ImageDisplay;
            output(n).type = 'image';

            n = length(output)+1;
            output(n).name = 'three';
            output(n).var = 'three';
            output(n).formatData = @mat2gray;
            output(n).defaultDisplayMethod = @ImageDisplay;
            output(n).type = 'image';

            if numel(obj.owner_.channels_) > 1 && numel(obj.funParams_.ChannelIndex) > 1
                n = length(output)+1;
                output(n).name = 'merged_all_three';
                output(n).var = 'merged_all_three';
                output(n).formatData = @mat2gray;
                output(n).defaultDisplayMethod = @ImageDisplay;
                output(n).type = 'image';

                n = length(output)+1;
                output(n).name = 'Merged_XY';
                output(n).var = 'merged_XY';
                output(n).formatData = @mat2gray;
                output(n).defaultDisplayMethod = @ImageDisplay;
                output(n).type = 'image';

                n = length(output)+1;
                output(n).name = 'Merged_ZY';
                output(n).var = 'merged_ZY';
                output(n).formatData = @mat2gray;
                output(n).defaultDisplayMethod = @ImageDisplay;
                output(n).type = 'image';

                n = length(output)+1;
                output(n).name = 'Merged_ZX';
                output(n).var = 'merged_ZX';
                output(n).formatData = @mat2gray;
                output(n).defaultDisplayMethod = @ImageDisplay;
                output(n).type = 'image';
            end
        end

        function out = unrelatedProc(obj)
            % This functions was used in movieViewer GUI to disable unralted processes on the overlay panel.
            if isa(obj, 'RenderDynROIMIPProcess')
                out = {'^PointSourceDetectionProcess3D$', '^TrackingProcess$', '^BuildDynROIProcess$'};
            else
                out = {'^PointSourceDetectionProcess3DDynROI$', '^TrackingDynROIProcess$'};
            end
        end
        
    end
    
    methods (Static)
        function name = getName()
            name = 'Render Full Maximum Intensity Projection';
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
            funParams.OutputDirectory = [outputDir  filesep 'RenderFullMIP'];


            %% Rendering parameter:

            %% 1) Mandatory parameters
            funParams.renderFrames=1:owner.nFrames_; % if not start at 1, algorithm will fail.
            % The frames to be renderered
            % funParams.processChannel=1:numel(owner.channels_); % deleted b/c same as funParams.ChannelIndex
            % The channel to be rendered

            %% 2) Parameters that may not make sense in the GUI
            funParams.processBuildDynROI=[];
            funParams.buildDynROIProcessChannel=1;
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