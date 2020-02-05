function RenderFullMIP(movieDataOrProcess, varargin)
% RenderFullMIP wrapper function for RenderDynROI.runFunction
% to be executed by RenderFullMIPProcess.
%
% INPUT
% movieDataOrProcess - either a MovieData (legacy)
%                      or a Process (new as of July 2016)
%
% param - (optional) A struct describing the parameters, overrides the
%                    parameters stored in the process (as of Aug 2016)
%
% OUTPUT
% none (saved to p.OutputDirectory)
%
% Changes
% As of July 2016, the first argument could also be a Process. Use
% getOwnerAndProcess to simplify compatability.
%
% As of August 2016, the standard second argument should be the parameter
% structure
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

%% ------------------ Input ---------------- %%
ip = inputParser;
ip.addRequired('MD', @(x) isa(x,'MovieData') || isa(x,'Process') && isa(x.getOwner(),'MovieData'));
ip.addOptional('paramsIn',[], @isstruct);
ip.parse(movieDataOrProcess, varargin{:});
paramsIn = ip.Results.paramsIn;

%% Registration
% Get MovieData object and Process
[movieData, thisProc] = getOwnerAndProcess(movieDataOrProcess, 'RenderFullMIPProcess', true);
p = parseProcessParams(thisProc, paramsIn); % If parameters are explicitly given, they should be used
% rather than the one stored in RenderFullMIPProcess

% Parameters: funParams = p;

% Sanity Checks
nChan = numel(movieData.channels_);
if max(p.ChannelIndex) > nChan || min(p.ChannelIndex)<1 || ~isequal(round(p.ChannelIndex), p.ChannelIndex)
    error('Invalid channel numbers specified! Check ChannelIndex input!!')
end

% precondition / error checking
if isa(thisProc, 'RenderDynROIMIPProcess')
%     If numel(buildDynROIProcId) > 1, popup window will show and let user to choose which BuildDynROIProcess. 
%     Later, added in the setting GUI for user to select a BuildDynROIProcess, so comment out.
%     buildDynROIProcId = movieData.getProcessIndex('BuildDynROIProcess');
    if isempty(p.processBuildDynROI)
        error("BuildDynROIProcess needs to be done and selected in setting before run RenderDynROIMIPProcess.")
    elseif ~ismember(1, p.processBuildDynROI.funParams_.ChannelIndex)
        error("Channel 1 in BuildDynROIProcess needs to be analyzed before run RenderDynROIMIPProcess.")
    end
end

% logging input paths (bookkeeping)
inFilePaths = cell(1, numel(movieData.channels_));
for i = p.ChannelIndex
    inFilePaths{1,i} = movieData.getChannelPaths{i};
end
thisProc.setInFilePaths(inFilePaths);

% logging output paths.
mkClrDir(p.OutputDirectory, false);
outFilePaths = cell(5, numel(movieData.channels_));
for i = p.ChannelIndex
    outFilePaths{1,i} = [p.OutputDirectory filesep 'MIP' filesep 'ch' num2str(i) filesep 'XY'];
    outFilePaths{2,i} = [p.OutputDirectory filesep 'MIP' filesep 'ch' num2str(i) filesep 'ZY'];
    outFilePaths{3,i} = [p.OutputDirectory filesep 'MIP' filesep 'ch' num2str(i) filesep 'ZX'];
    outFilePaths{4,i} = [p.OutputDirectory filesep 'MIP' filesep 'ch' num2str(i) filesep 'three'];
    outFilePaths{5,i} = [p.OutputDirectory filesep 'MIP' filesep 'ch' num2str(i)];
    mkClrDir(outFilePaths{1,i});
    mkClrDir(outFilePaths{2,i});
    mkClrDir(outFilePaths{3,i});
    mkClrDir(outFilePaths{4,i});
end
thisProc.setOutFilePaths(outFilePaths);


%% Algorithm
% Copied from RenderDynROI.runFunction, expect first line, line 121-122 and last 2 lines.
% Edited outputDir of ProjectDynROIProcess so thisProc results can be saved in appropriate folders. 'name' ('MIP') cannot be empty. -- Oct 2019

funParams = p; % change variable name to be consistent with RenderDynROI.runFunction
process = thisProc; % change variable name to be consistent with RenderDynROI.runFunction
funParams.processChannel = funParams.ChannelIndex; % change variable name to be consistent with RenderDynROI.runFunction

processBuildDynROI=funParams.processBuildDynROI;
processBuildDynROIInset=funParams.insetROI;

if(~isempty(processBuildDynROI))
    tmp=processBuildDynROI.loadFileOrCache(); % try initDynROIs
    dynROICell=tmp{1}.dynROICell;   %% Warning only render the first one here !!!
else
    dynROI=TracksROI();
    dynROICell={dynROI};
end

if(~isempty(processBuildDynROIInset))
    tmp=processBuildDynROIInset.loadFileOrCache(); % try initDynROIs
    insetDynROICell=tmp{1}.dynROICell(1);   %% Warning only render the first one here !!!
else
    insetDynROICell=cell(size(dynROICell));
end

processProjectionCell=cell(1,numel(dynROICell));

processRenderCell=cell(numel(dynROICell),1);

if(~isempty(funParams.preProcessedMovie))
    MD=MovieData.loadMatFile(funParams.preProcessedMovie.outFilePaths_{1});
else
    MD=process.getOwner();
end

renderFrames=funParams.renderFrames;

dynROISampleIdx=1:numel(dynROICell);
dynROISampleIdx=dynROISampleIdx(1:min(funParams.dynROIRenderingSamplingNumber,end));
for rIdx=dynROISampleIdx
    dynROI=dynROICell{rIdx};
    % processProj=ProjectDynROIProcess(process.getOwner(),[process.tag_ '-roi-' num2str(rIdx)]);
    processProj=ProjectDynROIProcess(process.getOwner(),'MIP', 'outputDir', p.OutputDirectory); % QZ edited. Oct 2019
    %renderer=ProjectDynROIProcess(process.getOwner(),[process.tag_ '-roi-' num2str(rIdx) '-stereo']);
    
    renderer=ProjectDynROIRendering(processProj,'stereo');
    renderer.ZRight=funParams.ZRight;
    renderer.Zup=funParams.Zup;
    if(~isempty(dynROI))
        ref=dynROI.getDefaultRef();
    else
        ref=[];
    end
    
    if(funParams.V2)
        disp('build MIP');tic;
        MIPS=cell(numel(funParams.processChannel),3,numel(renderFrames));
        minCoord=[];
        maxCoord=[];
        for cIdxIdx=1:numel(funParams.processChannel)
            cIdx=funParams.processChannel(cIdxIdx);
            [MIPS(cIdxIdx,1,:),MIPS(cIdxIdx,2,:),MIPS(cIdxIdx,3,:),minCoord,maxCoord]= ...
                dynROI.getMIP(MD,cIdx,renderFrames);
        end
        toc;
        
        if(funParams.debug) figure(); imdisp(MIPS{1,1,1}); drawnow; end;
        
        % store raw MIPS
        disp('Store raw mips');tic;
        set(processProj,'ref',dynROI.getDefaultRef());
        set(processProj,'nFrames',numel(renderFrames));
        processProj.setBoundingBox( ...
            [minCoord(1) maxCoord(1)],...
            [minCoord(2) maxCoord(2)],...
            [minCoord(3) maxCoord(3)]    );
        for cIdxIdx=1:numel(funParams.processChannel)
            cIdx=funParams.processChannel(cIdxIdx);
            for fIdx=renderFrames
                processProj.saveFrame(cIdx,fIdx,MIPS{cIdxIdx,1,fIdx},MIPS{cIdxIdx,2,fIdx},MIPS{cIdxIdx,3,fIdx});
            end
        end
        toc;
        
        %% Adjust contrast
        disp('Adjust contrast');tic;
        contrastOut=funParams.contrastOut;
        contrastIn=funParams.contrastIn;
        gamma=funParams.gamma;
        if(~iscell(contrastOut))
            contrastOut=arrayfun(@(i) contrastOut,1:numel(funParams.processChannel),'unif',0);
        end;
        if(~iscell(contrastIn))
            contrastIn=arrayfun(@(i) contrastIn,1:numel(funParams.processChannel),'unif',0);
        end;
        if(~iscell(gamma))
            gamma=arrayfun(@(i) gamma,1:numel(funParams.processChannel),'unif',0);
        end;
        
        for cIdxIdx=1:numel(funParams.processChannel)
            for mIdx=1:3
                for f=renderFrames
                    MIPS{cIdxIdx,mIdx,f}=255*imadjust(mat2gray(MIPS{cIdxIdx,mIdx,f}),contrastIn{cIdxIdx},contrastOut{cIdxIdx},gamma{cIdxIdx});
                end
            end
        end
        
        toc;
        if(funParams.debug) figure(); imdisp(MIPS{1,1,1}); drawnow; end;
        
        
        disp('Fuse in the case of two channels');
        finalMIP=cell(3,numel(renderFrames));
        if(numel(funParams.processChannel)==2)
            for fIdx=renderFrames
                [XY1,ZY1,ZX1]=processProj.loadFrame(1,fIdx);
                [XY2,ZY2,ZX2]=processProj.loadFrame(2,fIdx);
                
                finalMIP{1,fIdx} = renderChannel(MIPS{1,1,fIdx},MIPS{2,1,fIdx},funParams.channelRender);
                finalMIP{2,fIdx} = renderChannel(MIPS{1,2,fIdx},MIPS{2,2,fIdx},funParams.channelRender);
                finalMIP{3,fIdx} = renderChannel(MIPS{1,3,fIdx},MIPS{2,3,fIdx},funParams.channelRender);
            end
        else
            for mIdx=1:numel(finalMIP)
                finalMIP{mIdx}=repmat(MIPS{1,mIdx},1,1,3);
            end
        end
        
        if(funParams.debug) figure(); imdisp(finalMIP{1,1,1}); drawnow; end;
        
        maxMIPSize=funParams.mipSize;
        orthoSizes=maxCoord-minCoord;
        resizeScale=maxMIPSize/max(orthoSizes);
        parfor fIdx=1:numel(finalMIP)
            finalMIP{fIdx} =imresize(finalMIP{fIdx} ,resizeScale,'nearest');
        end
        
        disp('Store rendered MIPS');tic;
        renderer.emptyCache();
        set(renderer,'ref',dynROI.getDefaultRef());
        set(renderer,'nFrames',length(renderFrames));
        renderer.setBoundingBox( ...
            [minCoord(1) maxCoord(1)],...
            [minCoord(2) maxCoord(2)],...
            [minCoord(3) maxCoord(3)]    );
        for cIdx=funParams.processChannel
            for fIdx=renderFrames
                renderer.saveFrame(1,fIdx,finalMIP{1,fIdx},finalMIP{2,fIdx},finalMIP{3,fIdx});
            end
        end
        toc;
        renderer.swapCache();
        
    else
        
        renderFrames=renderFrames;
        renderFrames=dynROI.getStartFrame():dynROI.getEndFrame();
        projectDynROI(MD,dynROI,insetDynROICell{rIdx},'FoF',ref,'renderedChannel',funParams.processChannel, ...
            'channelRender',funParams.channelRender,'processFrame',renderFrames, ...
            'processSingleProj',processProj,'processRenderer',renderer,'insetOnly',funParams.insetOnly, ...
            'intMinPrctil',funParams.intMinPrctil ,'intMaxPrctil',funParams.intMaxPrctil,'maxMIPSize',funParams.mipSize,...
            'gamma',funParams.gamma,'contrastIn',funParams.contrastIn,'contrastOut',funParams.contrastOut);
        
        try
            renderer.swapCache();
        catch
        end
        
    end
    
    
    processProjectionCell{rIdx}=processProj;
    processRenderCell{rIdx}=renderer;
end


% Comment out since not used by GUI. -- Oct 2019.
% % save output, see RenderDynROI.saveOutput=
% mkClrDir(p.OutputDirectory);
% outputFiles=cell(1,2);
% outputFiles{1}=[p.OutputDirectory filesep 'dynROIsProjections.mat'];
% outputFiles{2}=[p.OutputDirectory filesep 'dynROIsRendering.mat'];
% mkdirRobust(fileparts(outputFiles{1}));
% mkdirRobust(fileparts(outputFiles{2}));
% save(outputFiles{1},'processProjectionCell');
% save(outputFiles{2},'processRenderCell');
% disp('save output');


end