classdef ImageAnalysisProcess < Process
    %A class definition for a generic image analysis process. That is, a
    %process which takes in images and produces some other (non-image) form of
    %output. This generic class expects the output to be one file per frame,
    %per channel with each channel in a separate directory.
    %
    %
    % Hunter Elliott, 7/2010
    %
    
    methods (Access = public)
        
        function obj = ImageAnalysisProcess(owner,name,funName,funParams,...
                inImagePaths,outFilePaths)
            
            if nargin == 0;
                super_args = {};
            else
                super_args{1} = owner;
                super_args{2} = name;
            end
            
            obj = obj@Process(super_args{:});
            
            if nargin > 2
                obj.funName_ = funName;
            end
            if nargin > 3
                obj.funParams_ = funParams;
            end
            
            %Initialize in and out file paths to a cell array to avoid
            %conversion errors.
            nChan = numel(owner.channels_);
            obj.inFilePaths_ = cell(1,nChan);
            obj.outFilePaths_ = cell(1,nChan);
            
            if nargin > 4
                if ~isempty(inImagePaths) && numel(inImagePaths) ...
                        ~= numel(owner.channels_) || ~iscell(inImagePaths)
                    error('lccb:set:fatal','Input image paths must be a cell-array of the same size as the number of image channels!\n\n');
                end
                obj.inFilePaths_(1,:) = inImagePaths;
            else
                %Default is to use raw images as input.
                obj.inFilePaths_(1,:) = owner.getChannelPaths;
            end
            if nargin > 5
                if ~isempty(outFilePaths) && numel(outFilePaths) ...
                        ~= numel(owner.channels_) || ~iscell(outFilePaths)
                    error('lccb:set:fatal','Output File paths must be a cell-array of the same size as the number of image channels!\n\n');
                end
                obj.outFilePaths_ = outFilePaths;
            else
                obj.outFilePaths_ = cell(1, numel(owner.channels_));
            end
            
        end
        
        function setOutFilePath(obj,chanNum,filePath)
            
            if ~obj.checkChanNum(chanNum)
                error('lccb:set:fatal','Invalid image channel number for file path!\n\n');
            end
            
            if ~iscell(filePath)
                filePath = {filePath};
            end
            nChan = length(chanNum);
            if nChan ~= length(filePath)
                error('lccb:set:fatal','You must specify a path for every channel!')
            end
            
            for j = 1:nChan
                if ~exist(filePath{j},'dir') && ~exist(filePath{j},'file')
                    error('lccb:set:fatal',...
                        ['The directory specified for output for channel ' ...
                        num2str(chanNum(j)) ' is invalid!'])
                else
                    obj.outFilePaths_{chanNum(j)} = filePath{j};
                end
            end
            
            
        end
        function setInImagePath(obj,chanNum,imagePath)
            
            if ~obj.checkChanNum(chanNum)
                error('lccb:set:fatal','Invalid image channel number for image path!\n\n');
            end
            
            if ~iscell(imagePath)
                imagePath = {imagePath};
            end
            nChan = length(chanNum);
            if nChan ~= length(imagePath)
                error('lccb:set:fatal','You must specify a path for every channel!')
            end
            
            for j = 1:nChan
                if ~exist(imagePath{j},'dir')
                    error('lccb:set:fatal',...
                        ['The directory specified for channel ' ...
                        num2str(chanNum(j)) ' is invalid!'])
                    
                else
                    if isempty(imDir(imagePath{j}))
                        error('lccb:set:fatal',...
                            ['The directory specified for channel ' ...
                            num2str(chanNum(j)) ' does not contain any images!!'])
                    else
                        obj.inFilePaths_{1,chanNum(j)} = imagePath{j};
                    end
                end
            end
        end
        
        function fileNames = getInImageFileNames(obj,iChan)
            if obj.checkChanNum(iChan)
                fileNames = cellfun(@(x)(imDir(x)),obj.inFilePaths_(1,iChan),'UniformOutput',false);
                fileNames = cellfun(@(x)(arrayfun(@(x)(x.name),x,'UniformOutput',false)),fileNames,'UniformOutput',false);
                nIm = cellfun(@(x)(length(x)),fileNames);
                if ~all(nIm == obj.owner_.nFrames_)
                    error('Incorrect number of images found in one or more channels!')
                end
            else
                error('Invalid channel numbers! Must be positive integers less than the number of image channels!')
            end
            
            
        end
  
        function status = checkChannelOutput(obj,varargin)
            % Input check
            ip =inputParser;
            ip.addOptional('iChan',1:numel(obj.owner_.channels_),...
                @(x) all(obj.checkChanNum(x)));
            ip.parse(varargin{:});
            iChan=ip.Results.iChan;
            
            %Makes sure there's at least one output file per channel
            status =  arrayfun(@(x) (exist(obj.outFilePaths_{1,x},'dir') && ...
                numel(dir([obj.outFilePaths_{1,x} filesep '*.mat']))==obj.owner_.nFrames_),iChan);
        end
        
    end
end