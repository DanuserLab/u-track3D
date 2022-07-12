function MLorMDOut=addAnalysisFolder(MLorMD,currentAnalysisRoot,newAnalysisRoot,varargin)
% This function copies a movieData object (or ML) and creates a new analysis folder.
% It never re-write the orignal MD or ML file. It refers to the same
% channels.
%
% Optionnaly the channel can be relocated to using the options
% oldRawDataRoot and newRawDataRoot.
ip = inputParser;
ip.CaseSensitive = false;
ip.KeepUnmatched=true;
ip.addRequired('MLorMD');
ip.addRequired('currentAnalysisRoot',@ischar);
ip.addRequired('newAnalysisRoot',@ischar);
ip.addOptional('oldRawDataRoot','',@ischar);
ip.addOptional('newRawDataRoot','',@ischar);
ip.addParamValue('recursive',true,@islogical);
ip.parse(MLorMD,currentAnalysisRoot,newAnalysisRoot,varargin{:});
oldRawDataRoot=ip.Results.oldRawDataRoot;
newRawDataRoot=ip.Results.newRawDataRoot;

error('MovieObject:addAnalysisFolder','addAnalysisFolder has not implemented for a general MovieObject');
