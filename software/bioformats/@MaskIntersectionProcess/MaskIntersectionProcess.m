classdef MaskIntersectionProcess < MaskProcessingProcess
    % A concrete process to create mask interesections
    
    
    methods(Access = public)
        function obj = MaskIntersectionProcess(owner,varargin)
            
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
                
                % Define arguments for superclass constructor
                super_args{1} = owner;
                super_args{2} = MaskIntersectionProcess.getName;
                super_args{3} = @intersectMovieMasks;
                if isempty(funParams)
                    funParams=MaskIntersectionProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end
            
            obj = obj@MaskProcessingProcess(super_args{:});
            
        end
        
        
    end
    methods(Static)
        function name =getName()
            name = 'Mask Intersection';
        end
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:})
            outputDir=ip.Results.outputDir;
            
            % Set default parameters
            funParams.ChannelIndex = 1:numel(owner.channels_); %Default is to transform masks for all channels
            funParams.SegProcessIndex = []; %No default...
            funParams.OutputDirectory =  [outputDir filesep 'intersected_masks'];
            funParams.BatchMode = false;
        end
    end
end