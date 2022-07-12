function MD=addAnalysisFolder(MD,currentAnalysisRoot,newAnalysisRoot,varargin)
% This function copies a movieData object and creates a new analysis folder.
% It never re-write the orignal MD file. It refers to the same
% channels.
%
% Optionnaly the channel can be relocated to using the options
% oldRawDataRoot and newRawDataRoot.
    ip = inputParser;
    ip.CaseSensitive = false;
    ip.KeepUnmatched=true;
    ip.addRequired('MD');
    ip.addRequired('currentAnalysisRoot',@ischar);
    ip.addRequired('newAnalysisRoot',@ischar);
    ip.addOptional('copyOutput',false,@islogical);
    ip.addOptional('oldRawDataRoot','',@ischar);
    ip.addOptional('newRawDataRoot','',@ischar);
    ip.parse(MD,currentAnalysisRoot,newAnalysisRoot,varargin{:});
    p=ip.Results;

    oldRawDataRoot=ip.Results.oldRawDataRoot;
    newRawDataRoot=ip.Results.newRawDataRoot;
    MDAnalysisPath=relocatePath(MD.outputDirectory_, currentAnalysisRoot,  newAnalysisRoot);
    mkdirRobust(MDAnalysisPath);
    if(p.copyOutput)
        copyfile(MD.outputDirectory_,MDAnalysisPath);
    end
    
    %MD.sanityCheck(MDAnalysisPath,[sprintf(namePattern,i) '.mat'],false);
    
    for c=1:length(MD.channels_);
        MD.getChannel(c).relocate(oldRawDataRoot,newRawDataRoot);
    end
    MD.relocate(MD.outputDirectory_,MDAnalysisPath,false);
    MD.save();
