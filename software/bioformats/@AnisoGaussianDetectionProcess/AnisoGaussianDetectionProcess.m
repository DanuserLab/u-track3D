classdef AnisoGaussianDetectionProcess < DetectionProcess
    % A concrete class for detecting anisotropic Gaussians
    %
    % Sebastien Besson, May 2012

    
    methods (Access = public)
        function obj = AnisoGaussianDetectionProcess(owner, varargin)
            % Constructor of the CometDetectionProcess
            
            if nargin == 0
                super_args = {};
            else
                % Input check
                ip = inputParser;
                ip.addRequired('owner',@(x) isa(x,'MovieData'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;
                
                super_args{1} = owner;
                super_args{2} = AnisoGaussianDetectionProcess.getName;
                super_args{3} = @detectMovieAnisoGaussians;
                if isempty(funParams)  % Default funParams
                    funParams = AnisoGaussianDetectionProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
                
                
            end
            
            obj = obj@DetectionProcess(super_args{:});
        end

        function output = getDrawableOutput(obj)
            output=getDrawableOutput@DetectionProcess(obj);
            output(1).name='Comets';
        end
        
    end
    methods (Static)
        function name = getName()
            name = 'Anisotropic Gaussian Detection';
        end
        
        function h = GUI()
            h = @anisoGaussianDetectionProcessGUI;
        end
        
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:})
            outputDir=ip.Results.outputDir;
            
            % Set default parameters
            funParams.ChannelIndex = 1 : numel(owner.channels_);
            funParams.OutputDirectory = [outputDir  filesep 'anisoGaussians'];
            funParams.MaskProcessIndex = [];
            funParams.MaskChannelIndex =  1 : numel(owner.channels_);
            
            % Detection parameters
            if ~isempty(owner.channels_(1).psfSigma_)
                funParams.psfSigma = owner.channels_(1).psfSigma_;
            else
                funParams.psfSigma = 1;
            end
            funParams.mode = 'xyArtc';
            funParams.alpha = .05;
            funParams.kSigma = 4;
            funParams.minDist = .25;
            funParams.filterSigma=funParams.psfSigma*sqrt(2);
        end
    end    
end