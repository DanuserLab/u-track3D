classdef RenderDynROI < NonSingularProcess % & ComputeMIPProcess
    methods (Access = public)
        function obj = RenderDynROI(owner)
            obj = obj@NonSingularProcess(owner, RenderDynROI.getName());
            obj.funName_ = @RenderDynROI.runFunction;
            obj.funParams_ = RenderDynROI.getDefaultParams(owner);
        end
        
        function saveOutput(obj,processProjectionsCell,processRenderCell)
            outputFiles=cell(1,2);
            outputFiles{1}=[obj.getOwner().outputDirectory_ filesep obj.tag_ filesep 'dynROIsProjections.mat'];
            outputFiles{2}=[obj.getOwner().outputDirectory_ filesep obj.tag_ filesep 'dynROIsRendering.mat'];
            mkdirRobust(fileparts(outputFiles{1}));
            mkdirRobust(fileparts(outputFiles{2}));
            save(outputFiles{1},'processProjectionsCell');
            save(outputFiles{2},'processRenderCell');
            obj.setOutFilePaths(outputFiles);
        end
        
        function dynROIRenderingCell=displayAll(obj,varargin)
            ip =inputParser;
            ip.CaseSensitive = false;
            ip.KeepUnmatched = true;
            ip.addParameter('show',true,@islogical);
            ip.parse(varargin{:})
            p=ip.Results;
            funParams=obj.funParams_;
            data=obj.loadFileOrCache();
            dynROIRenderingCell=data{2}.processRenderCell;
            if(p.show)
                dynROISampleIdx=1:numel(dynROIRenderingCell);
                dynROISampleIdx=dynROISampleIdx(1:min(funParams.dynROIRenderingSamplingNumber,end));
                for rIdx=dynROISampleIdx
                    dynROIRenderingCell{rIdx}.imdisp();
                    drawnow;
                end
            end
        end

        function [outIm,maxXY,maxZY,maxZX] = loadChannelOutput(obj, iChan, iFrame, iROI, varargin)
            ip =inputParser;
            ip.addRequired('obj');
            ip.addRequired('iChan', @obj.checkChanNum);
            ip.addRequired('iFrame', @obj.checkFrameNum);
            ip.addRequired('iROI', @isnumeric);
            ip.parse(obj,iChan,iFrame,iROI,varargin{:})
            funParams=obj.funParams_;
            data=obj.loadFileOrCache();
            dynROIProjectionCell=data{1}.processProjectionsCell;
            [maxXY,maxZY,maxZX,three]=dynROIProjectionCell{iROI}.loadFrame(iFrame,iChan);
            outIm=three;
        end
% 
%         function output = getDrawableOutput(obj, varargin)
%         
%             n = 1;
%             output(n).name = 'XY';
%             output(n).var = 'XY';
%             output(n).formatData = @mat2gray;
%             output(n).defaultDisplayMethod = @ImageDisplay;
%             output(n).type = 'image';
%         end
%
% Copyright (C) 2022, Danuser Lab - UTSouthwestern 
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
    end
    methods (Static)
        function name = getName()
            name = 'RenderDynROI';
        end

        function name = runFunction(process)
            funParams=process.funParams_;

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

            disp('::::')
            if(isempty(funParams.processBuildDynROI))
                disp(['Rendering orthogonal maximum intensity projections']);
            else
                disp(['Rendering orthogonal maximum intensity projections for dynROI ' ...
                      funParams.processBuildDynROI.getProcessTag()]);
            end 
            
            


            dynROISampleIdx=1:numel(dynROICell);
            dynROISampleIdx=dynROISampleIdx(1:min(funParams.dynROIRenderingSamplingNumber,end));
            for rIdx=dynROISampleIdx
                dynROI=dynROICell{rIdx};          
                if(~isempty(dynROI))
                    ref=dynROI.getDefaultRef();
                else
                    ref=[];
                end

                if(funParams.V2)
                    MIPS=cell(numel(funParams.processChannel),3,numel(renderFrames));
                    if(isempty(funParams.swappedRenderDynROI))
                        processProj=ProjectDynROIProcess(process.getOwner(),[process.tag_ ...
                                            '-roi-' num2str(rIdx)]);
                        
                       
                         
                        if(funParams.verbosity>1)
                            disp('build MIP');tic;
                        end
                        
                        minCoord=[];
                        maxCoord=[];
                        for cIdxIdx=1:numel(funParams.processChannel)
                            cIdx=funParams.processChannel(cIdxIdx);
                            [MIPS(cIdxIdx,1,:),MIPS(cIdxIdx,2,:),MIPS(cIdxIdx,3,:),minCoord,maxCoord]= ... 
                            dynROI.getMIP(MD,cIdx,renderFrames);
                        end
                        if(funParams.verbosity>1)
                            toc;                            
                        end
                            

                        if(funParams.debug) figure(); imdisp(MIPS{1,1,1}); drawnow; end;

                        % store raw MIPS
                        if(funParams.verbosity>1)
                            disp('Store raw mips');tic;
                        end
                        
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
                        if(funParams.verbosity>1)
                            toc;                            
                        end
                            
                    else
                        if(funParams.verbosity>1)
                            disp('Loading mips');tic;
                        end
                        
                        tmp=funParams.swappedRenderDynROI.loadFileOrCache();
                        processProjectionsCell=tmp{1}.processProjectionsCell;
                        processProj=processProjectionsCell{rIdx};
                        for cIdxIdx=1:numel(funParams.processChannel)
                            cIdx=funParams.processChannel(cIdxIdx);
                            for fIdx=renderFrames
                                [MIPS{cIdxIdx,1,fIdx},MIPS{cIdxIdx,2,fIdx},MIPS{cIdxIdx,3,fIdx}]=processProj.loadFrame(cIdx,fIdx);
                            end
                        end
                        [minmaxXBorder, minmaxYBorder,minmaxZBorder]=processProj.getBoundingBox();
                        minCoord=[minmaxXBorder(1),minmaxYBorder(1),minmaxZBorder(1)];
                        maxCoord=[minmaxXBorder(2),minmaxYBorder(2),minmaxZBorder(2)];
                        if(funParams.verbosity>1)
                            toc;
                        end

                    end

                    %% Adjust contrast
                    if(funParams.verbosity>1)
                        disp('Adjust contrast');tic;
                    end
                    
                    contrastOut=funParams.contrastOut;
                    contrastIn=funParams.contrastIn;
                    if((~isempty(contrastIn)|(~isempty(contrastOut)))&(~ ...
                                                                       isempty(funParams.contrast)))
                        warning (['contrastIn and contrastOut are deprecated, overidden ' ...
                                  'by contrast']);
                    end
                    contrast=funParams.contrast;
                    if(isempty(contrast))
                        contrast=[0 1]; 
                    end 
                    contrastIn=contrast;

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

                    if(funParams.normalize)
                    for cIdxIdx=1:numel(funParams.processChannel)
                        for f=renderFrames
                            quantiles=double(quantile(MIPS{cIdxIdx,1,f}(:),contrastIn{cIdxIdx}));
                            for mIdx=1:3
                                MIPS{cIdxIdx,mIdx,f}=255*imadjust(mat2gray(MIPS{cIdxIdx,mIdx,f},quantiles), ... 
                                                                    [0 1],[0 1],gamma{cIdxIdx});
                            end
                        end
                    end
                    else
                        for cIdxIdx=1:numel(funParams.processChannel)
                            quantiles=double(quantile(MIPS{cIdxIdx,1,1}(:),contrastIn{cIdxIdx}));
                            for f=renderFrames
                                for mIdx=1:3
                                    MIPS{cIdxIdx,mIdx,f}=255*imadjust(mat2gray(MIPS{cIdxIdx,mIdx,f},quantiles), ... 
                                        [0 1],[0 1],gamma{cIdxIdx});
                                end
                            end
                        end
                    end

                    if(funParams.verbosity>1)
                        toc;                        
                    end
                        
                    if(funParams.debug) figure(); imdisp(MIPS{1,1,1}); drawnow; end;

                    if(funParams.verbosity>1)
                        disp('Fuse in the case of two channels');
                    end
                    
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

                    if(funParams.verbosity>1)
                        disp('Store rendered MIPS');tic;
                    end
                    
                    renderer=ProjectDynROIRendering(processProj,'stereo');
                    renderer.ZRight=funParams.ZRight;
                    renderer.Zup=funParams.Zup;
    
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
                    if(funParams.verbosity>1)
                        toc;                        
                    end
                        
                    renderer.swapCache();

                else
                    dynROI=dynROICell{rIdx};
                    processProj=ProjectDynROIProcess(process.getOwner(),[process.tag_ '-roi-' num2str(rIdx)]);
                    %renderer=ProjectDynROIProcess(process.getOwner(),[process.tag_ '-roi-' num2str(rIdx) '-stereo']);

                    renderer=ProjectDynROIRendering(processProj,'stereo');
                    renderer.ZRight=funParams.ZRight;
                    renderer.Zup=funParams.Zup;
                    if(~isempty(dynROI))
                        ref=dynROI.getDefaultRef();
                    else
                        ref=[];
                    end

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
            process.saveOutput(processProjectionCell,processRenderCell);
            if(funParams.verbosity>1)
                disp('save output');
            end
            
        end

        
        function funParams = getDefaultParams(owner)
            % Input check
            ip=inputParser;
            ip.addRequired('owner', @(x) isa(x, 'MovieObject'));
            ip.addOptional('outputDir', owner.outputDirectory_, @ischar);
            ip.parse(owner)
            
            %% 1) Mandatory parameters
            funParams.renderFrames=1:owner.nFrames_;
            % The frame to be renderered
            funParams.processChannel=1:numel(owner.channels_); % The channel to be rendererd
            % The channel to be rendered

            %% 2) Parameters that may not make sense in the GUI
            funParams.processBuildDynROI=[];
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
            funParams.contrast=[];
            funParams.contrastIn=[];  %  Deprecated
            funParams.contrastOut=[]; %  Deprecated
            funParams.normalize=true;
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
            funParams.swappedRenderDynROI=[];

            % Other legacy parameters
            funParams.insetROI=[];

            funParams.insetOnly=false;
            funParams.V2=true;
            funParams.debug=false;
            funParams.ZRight=false;
            funParams.Zup=false;
            funParams.intMinPrctil=[1 1];
            funParams.intMaxPrctil=[100 100];
            funParams.verbosity=1;
        end
    end
end
