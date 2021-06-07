classdef BuilDynROI < NonSingularProcess
    properties
        swapFile_
    end
    methods (Access = public)
        function obj =BuilDynROI(owner)
            obj = obj@NonSingularProcess(owner, BuilDynROI.getName());
            obj.funName_ = @BuilDynROI.runFunction;
            obj.funParams_ = BuilDynROI.getDefaultParams(owner);
        end
        
        function saveChannelOutput(obj,dynROICell)
            outputFiles=cell(1,3);

            outputIdx=1; % DynROI are not channel specific
            outputFiles{outputIdx}=[obj.getOwner().outputDirectory_ filesep obj.tag_ filesep 'dynROIs.mat'];
            mkdirRobust(fileparts(outputFiles{outputIdx}));
            save(outputFiles{outputIdx},'dynROICell');

            if(false)
                outputIdx=2;
                disp('Saving Bounding box'); tic;
                outputFiles{outputIdx}=[obj.getOwner().outputDirectory_ filesep obj.tag_ filesep 'boundingBox.mat'];
                mkdirRobust(fileparts(outputFiles{outputIdx}));
                vertices=cell(1,obj.getOwner().nFrames_);
                edges=cell(1,obj.getOwner().nFrames_);
                for fIdx=1:obj.getOwner().nFrames_
                    [vertices{fIdx},edges{fIdx}]=dynROICell{1}.getBoundingParallelogram(fIdx);
                end
                save(outputFiles{outputIdx},'vertices','edges');
                toc;
            end
            

            %% Cropping and transforming voxel mapped in the DynROIs
%
% Copyright (C) 2021, Danuser Lab - UTSouthwestern 
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
            if(obj.funParams_.swappingVoxels)
                outputIdx=3;
                outputFiles{outputIdx}=[obj.getOwner().outputDirectory_ filesep obj.tag_ filesep 'movieDataDynROICell.mat'];
                movieDataDynROICell=cell(1,numel(dynROICell));
                for dIdx=1:numel(dynROICell)
                    subFolder=fullfile(obj.tag_,'movieDataDynROI',['dynROI_' num2str(dIdx)]);
                    [~,movieDataDynROICell{dIdx}]=dynROICell{dIdx}.swapDynBoundingBox(obj.getOwner(),subFolder);
                end
                save(outputFiles{outputIdx},'movieDataDynROICell');
            end

            obj.setOutFilePaths(outputFiles);
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


        function overlayCell=displayAll(obj,displayProjsProcess,varargin)
            ip =inputParser;
            ip.CaseSensitive = false;
            ip.KeepUnmatched = true;
            ip.addOptional('displayProjsProcess',obj.getOwner().searchProcessName('RenderDynROI'),@(x) isa(x,'RenderDynROI')||isa(x,'cell'));
            ip.addParameter('output','movieInfo',@ischar);
            ip.addParameter('show',true,@islogical);
            ip.addParameter('ROILabel',[]);
            ip.addParameter('showNumber',false,@islogical);
            ip.parse(displayProjsProcess,varargin{:})
            p=ip.Results;

            funParams=obj.funParams_;

            displayProjs=cell(1,numel(displayProjsProcess));
            for pIdx=1:numel(displayProjsProcess)
                if(isa(displayProjsProcess(pIdx),'RenderDynROI'))
                    data=displayProjsProcess(pIdx).loadFileOrCache();
                    displayProjs{pIdx}=data{2}.processRenderCell{1};
                else
                    displayProjs{pIdx}=displayProjsProcess{pIdx};
                end
            end
            overlayCell=cell(numel(displayProjs),1);

            for rIdx=1:numel(overlayCell)
                overlay=ProjectDynROIRendering(displayProjs{rIdx},['ROI-ID']);
                overlay.ZRight=false;
                overlayCell{rIdx}=overlay;
            end

            tmp=obj.loadFileOrCache();
            dynROICell=tmp{1}.dynROICell;
            tracks=cellfun(@(d) d.tracks(1),dynROICell,'unif',0);
            tracks=[tracks{:}];

            graphsCell=cell(2,numel(dynROICell));
            for dIdx=1:numel(dynROICell)
                positionCell=cell(1,obj.getOwner().nFrames_);
                gc=cell(1,obj.getOwner().nFrames_);
                dR=dynROICell{dIdx};
                ref=dR.getDefaultRef();
                disp(['Min ref: ' num2str(min(ref.frame))]);
                disp(['Max ref: ' num2str(max(ref.frame))]);
                frameRange=1:obj.getOwner().nFrames_;
                try
                    if(funParams.lifetimeOnly)
                        frameRange=dR.getStartFrame():dR.getEndFrame();
                    end
                catch
                    warning('Deprecated instance') ;
                end
                
                parfor fIdx=frameRange
                    [positionCell{fIdx},gc{fIdx}]=dR.getBoundingParallelogram(fIdx);
                end

                graphsCell{2,dIdx}=gc;
                graphsCell{1,dIdx}=Detections().initFromPosMatrices(positionCell,positionCell);
            end

            edgeLabel=cell(1,numel(dynROICell));
            if(~isempty(p.ROILabel))
                for dIdx=1:numel(dynROICell)
                    switch p.ROILabel
                    case 'time'
                        edgeLabel{dIdx}=arrayfun(@(f) f*ones(size(graphsCell{2,dIdx}{f},1),1),1:numel(graphsCell{2,dIdx}),'unif',false);
                    otherwise
                        error('Undefined label');
                    end
                end
            end

            for rIdx=1:numel(overlayCell)
                if(p.showNumber)
                    overlayProjTracksMovie(displayProjs{rIdx},'tracks',tracks,'colorIndx',1:numel(tracks), ... 
                                           'dragonTail',10,'insertTrackID',true,'process',overlayCell{rIdx}); 
                else
                    overlayCell{rIdx}=displayProjs{rIdx};
                end

                for dIdx=1:numel(dynROICell)
                    overlayProjGraphMovie(overlayCell{rIdx},graphsCell{1,dIdx},graphsCell{2,dIdx},'colorLabel',edgeLabel{dIdx}, ... 
                        'showROIOnly',false,'process',overlayCell{rIdx},'linewidth',1,varargin{:}); 
                end
            end
            if(p.show)
                for rIdx=1:numel(displayProjs)
                    overlayCell{rIdx}.cachedOrtho.imdisp();
                    drawnow;
                end
            end
        end

        function output = loadChannelOutput(obj, varargin)
            outputList = {'dynROICell','boundingBox','movieDataDynROICell'};
            nOutput = length(outputList);
            ip =inputParser;
            ip.addParamValue('output','dynROICell',@(x) all(ismember(x,outputList)));
            ip.addParamValue('useCache',false,@islogical);
            ip.parse(varargin{:})
            
            switch ip.Results.output
              case 'dynROICell'
                s = cached.load(obj.outFilePaths_{1},'-useCache',ip.Results.useCache);
                output = s.dynROICell;          
              case 'boundingBox'
                tmp=load(obj,outFilePaths_{2});
                output=tmp.boundingBox;
              case 'movieDataDynROICell'
                tmp=load(obj.outFilePaths_{3});
                output=tmp.movieDataDynROICell;
            end

        end
        
    end
    methods (Static)
        function name = getName()
            name = 'BuilDynROI';
        end

        function name = runFunction(process)
            funParams=process.funParams_;

            switch funParams.roiType
              case 'spindle'
                disp('Fiducials for mitosis');tic;
                [poleDetect,poleTracks]=detectPoles(process.getOwner(),'isoOutput',true,'channel',funParams.processChannel);
                if(~isempty(funParams.trackProcess))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                    tracks=fillTrackGaps(tracks);
                    dynROICell=RoundedTubeROI.RoundedTubeROICollection(repmat(poleTracks(1),size(tracks)),tracks,80);
                else
                    dynROICell=RoundedTubeROI.RoundedTubeROICollection(poleTracks([1,2]),poleTracks([2,1]),funParams.fringe);
                end

              case 'trackSet'
                %% Use tracks if necessary
                if(isempty(funParams.trackObjects))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                else
                    tracks=funParams.trackObjects;
                end

                tracks=fillTrackGaps(tracks);

                detections=Detections().setFromTracks(tracks);
                pos=detections.getPosMatrix();
                cellCenter=cellfun(@(d) mean(d,1),pos,'unif',0);

                covMX=cell(1,numel(pos));
                i=1;
                x=pos{i}(:,1);
                y=pos{i}(:,2);
                z=pos{i}(:,3);
                N=size(pos{i},1);
                CovXY=(x-mean(x))'*(y-mean(y))/(N-1);
                CovYX=CovXY;
                CovXZ=(x-mean(x))'*(z-mean(z))/(N-1);
                CovZX=CovXZ;
                CovYZ=(y-mean(y))'*(z-mean(z))/(N-1);
                CovZY=CovYZ;


                covMXI=[  var(x)  CovXY    CovXZ;...
                          CovYX   var(y)   CovYZ;...
                          CovZX   CovZY    var(z)...
                       ];
                [V,D,W] = eig(covMXI)

                [L,sIdx]=sort(-sum(D));
                X=V(:,sIdx(1));
                Y=V(:,sIdx(2));
                Z=cross(X,Y);
                covMXI=[X Y Z];
                det(covMXI)
                covMX{i}=covMXI;

                for i=2:numel(covMX)
                    tform=pcregrigid(pointCloud(pos{i}),pointCloud(pos{i-1}));
                    covMX{i}=tform.T(1:3,1:3)*covMX{i-1};
                end
                
                pos=arrayfun(@(f) [0 0 0],1:max([tracks.endFrame]),'unif',0);
                sumTrack=Detections().initFromPosMatrices(pos,pos).buildTracksFromDetection();
                cumulSum=zeros(1,numel(pos));
                for tIdx=1:numel(tracks)
                    T=tracks(tIdx);
                    FIdx=ismember(sumTrack.f,T.f);
                    sumTrack.x(FIdx)=sumTrack.x(FIdx)+T.x;
                    sumTrack.y(FIdx)=sumTrack.y(FIdx)+T.y;
                    sumTrack.z(FIdx)=sumTrack.z(FIdx)+T.z;
                    cumulSum(FIdx)=cumulSum(FIdx)+1;
                end
                meanTrack=sumTrack.getMultCoord(1./cumulSum);

                % varTrack=Detections().initFromPosMatrices(pos,pos).buildTracksFromDetection();
                % for tIdx=1:numel(tracks) 
                %     T=tracks(tIdx);
                %     FIdx=ismember(sumTrack.f,T.f);
                %     varTrack.x(FIdx)=varTrack.x(FIdx)+(T.x-meanTrack.x(FIdx)).^2;
                %     varTrack.y(FIdx)=varTrack.y(FIdx)+(T.y-meanTrack.y(FIdx)).^2;
                %     varTrack.z(FIdx)=varTrack.z(FIdx)+(T.z-meanTrack.z(FIdx)).^2;
                % end
                % varTrack.x=(varTrack.x./cumulSum).^(0.5);
                % varTrack.y=(varTrack.y./cumulSum).^(0.5);
                % varTrack.z=(varTrack.z./cumulSum).^(0.5);

                % secondMoment=meanTrack.getAddCoord(varTrack);
                % oppMoment=meanTrack.getAddCoord(varTrack.getMultCoord(-1));
                
                tracksROI=TracksROI(tracks,funParams.fringe,false);
                ref=FrameOfRef().setOriginFromTrack(meanTrack);
                ref.setBase(covMX);

                tracksROI.setDefaultRef(ref);
                dynROICell={tracksROI};

              case 'singleTracks'
                %% Use tracks if necessary
                if(isempty(funParams.trackObjects))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                else
                    tracks=funParams.trackObjects;
                end
                dynROICell=cell(1,numel(tracks));
                ref=[];

                if(~isempty(funParams.processRendererDynROI))
                    warning('funParams.processRenderDynROI is deprecated');
                    fp=funParams.processRendererDynROI.getParameters();
                    dynROIData=fp.processBuildDynROI.loadFileOrCache();
                    ref=dynROIData{1}.dynROICell{1}.getDefaultRef();
                end

                if(~isempty(funParams.processBuildDynROI))
                    dynROIData=funParams.processBuildDynROI.loadFileOrCache();
                    ref=dynROIData{1}.dynROICell{1}.getDefaultRef();
                end

                for tIdx=1:numel(tracks)
                    dynROICell{tIdx}=TracksROI(tracks(tIdx),funParams.fringe);
                    if(~isempty(funParams.processBuildDynROI))
                        dynROICell{tIdx}.setDefaultRef(ref);
                    else
                        ref=FrameOfRef().setOriginFromTrack(tracks(tIdx)).genCanonicalBase();
                        dynROICell{tIdx}.setDefaultRef(ref);
                    end
                end
              case 'singleStaticTracks'
                %% Use tracks if necessary
                if(isempty(funParams.trackObjects))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                else
                    tracks=funParams.trackObjects;
                end
                dynROICell=cell(1,numel(tracks));
                ref=[];

                if(~isempty(funParams.processBuildDynROI))
                    dynROIData=funParams.processBuildDynROI.loadFileOrCache();
                    ref=dynROIData{1}.dynROICell{1}.getDefaultRef();
                end

                for tIdx=1:numel(tracks)
                    dynROICell{tIdx}=StaticTracksROI(tracks(tIdx),funParams.fringe,funParams.lifetimeOnly);
                
                    if(~isempty(funParams.processBuildDynROI))
                        dynROICell{tIdx}.setDefaultRef(ref);
                    end
                end

              case 'detectionStable'
                if(isempty(funParams.detectionsObject))
                    dets=funParams.detectionProcess.loadChannelOutput(funParams.detectionProcessChannel,'output','labelSegPos');
                else
                    dets=funParams.detectionsObject;
                end
                ref=ICPIntegrationTest(dets);
                

                Axis=arrayfun(@(p) [[0,0,0];[0,0,30]],1:numel(dets),'unif',0);
                Axis=Detections().initFromPosMatrices(Axis,Axis).buildTracksFromDetection();
                Axis=ref.applyInvBase(Axis);
                

                tracksROI=TubeROI([Axis],funParams.fringe);
                tracksROI.setDefaultRef(ref);
                
                dynROICell={tracksROI};

              case {'detectionStableFirstReg','fitDetSetRegistered'}
                if(isempty(funParams.detectionsObject))
                    dets=funParams.detectionProcess.loadChannelOutput(funParams.detectionProcessChannel,'output','labelSegPos');
                else
                    dets=funParams.detectionsObject;
                end

                disp('downsampling');tic;
                pos=dets.getPosMatrix();
                pos=cellfun(@(p) (pcdownsample(pointCloud(p),'random',funParams.downSamplePerc)),pos,'unif',0);
                pos=cellfun(@(p) p.Location,pos,'unif',0);
                dets.initFromPosMatrices(pos,pos);
                toc;

                disp('registering');tic;
                [ref,cenTrack]=ICPIntegrationFirstReg(dets);
                toc;

                % tracks needed to build the ROI
                allTracks= dets.buildTracksFromDetection();

                %                    tracksROI=TracksROI([cenTrack;allTracks],funParams.fringe);
                tracksROI=TracksROI([cenTrack],funParams.fringe);

                tracksROI.setDefaultRef(ref);
                
                dynROICell={tracksROI};



              case {'trackSetStableOld','fitTrackSetFrameByFrameOld'}
                %% Use tracks if necessary
                if(isempty(funParams.trackObjects))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                else
                    tracks=funParams.trackObjects;
                end

                tracks=fillTrackGaps(tracks);
                %%
                detections=Detections().setFromTracks(tracks);
                pos=detections.getPosMatrix();
                
                % Find the track center
                % names={};
                % medianPos=cellfun(@(p) nanmedian(p,1),pos,'unif',0)
                % cenTrack=Detections().initFromPosMatrices(medianPos,medianPos).buildTracksFromDetection();
                % allCenter=cenTrack.x;
                % names=[names {'median'}];

                % cenTrack=Detections().initFromPosMatrices(meanPos,medianPos).buildTracksFromDetection();
                % allCenter=[allCenter;cenTrack.x];
                % names=[names {'mean'}];

                % meanRobust=cell(1,numel(meanPos));
                % weigths=cell(1,numel(meanPos));

                % for fIdx=1:numel(pos)
                %     p=pos{fIdx};
                %     M=meanPos{fIdx};
                %     distances=sum((p-M).^2,2).^0.5;
                %     sigma = 1.4826*mad(distances,1);
                %     err=1;
                %     NIter=0;
                %     while err>0.001
                %         distances=sum((p-M).^2,2).^0.5;
                %         distances=(distances/(3*sigma));
                %         w = (abs(distances)<1) .* (1 - distances.^2).^2;
                %         Mprev=M;
                %         M=sum(w.*p,1)/sum(w);
                %         err=sum((M-Mprev).^2)/sum(Mprev.^2);
                %         NIter=NIter+1;
                %     end 
                %     NIter;
                %     meanRobust{fIdx}=M;
                %     weigths{fIdx}=w;
                % end

                % cenTrack=Detections().initFromPosMatrices(meanRobust,meanRobust).buildTracksFromDetection();
                % allCenter=[allCenter;cenTrack.x];
                % names=[names {'robust'}]; 

                covMX=cell(1,numel(pos));

                %% Compute cov matrix on the first frame
                i=1;
                x=pos{i}(:,1);
                y=pos{i}(:,2);
                z=pos{i}(:,3);
                N=size(pos{i},1);
                CovXY=(x-mean(x))'*(y-mean(y))/(N-1);
                CovYX=CovXY;
                CovXZ=(x-mean(x))'*(z-mean(z))/(N-1);
                CovZX=CovXZ;
                CovYZ=(y-mean(y))'*(z-mean(z))/(N-1);
                CovZY=CovYZ;
                covMXI=[var(x) CovXY  CovXZ;CovYX   var(y)   CovYZ; CovZX   CovZY    var(z)];

                % Compute orthogonal basis and use it for the frame of reference of the first frame
                [V,D,W] = eig(covMXI)
                [L,sIdx]=sort(-sum(D));
                X=V(:,sIdx(1));
                Y=V(:,sIdx(2));
                Z=cross(X,Y);
                covMXI=[X Y Z];
                covMX{i}=covMXI;
                
                % Estimate rigid transform between tracked object one frame to the next
                % shift the center and FoF basis accordingly.     
                meanPos=cellfun(@(p) nanmean(p,1),pos,'unif',0);

                shiftPos=meanPos;
                for i=2:numel(covMX)
                    tform=pcregrigid(pointCloud(pos{i}),pointCloud(pos{i-1}));
                    covMX{i}=tform.T(1:3,1:3)*covMX{i-1};
                    shiftPos{i}=tform.transformPointsInverse(shiftPos{i-1});
                end
                cenTrack=Detections().initFromPosMatrices(shiftPos,shiftPos).buildTracksFromDetection();

                

                % tracksROI=TracksROI([cenTrack; tracks],funParams.fringe,false);
                
                ref=FrameOfRef().setOriginFromTrack(cenTrack);
                ref.setBase(covMX);

                % ZAxis=cellfun(@(p) [30,10,0],pos,'unif',0)
                % ZAxis=Detections().initFromPosMatrices(ZAxis,ZAxis).buildTracksFromDetection();
                % ZAxis=ref.applyInvBase(ZAxis);
                % tracksROI=TubeROI([cenTrack;ZAxis],funParams.fringe);
                % tracksROI.setDefaultRef(ref);

                tracksROI=TracksROI([cenTrack;tracks],funParams.fringe,false);
                tracksROI.setDefaultRef(ref);
                
                dynROICell={tracksROI};


                % allCenter=[allCenter; cenTrack.x];
                % names=[names,{'pcregrigid'}]; 
                % H=setupFigure(1,3,3);
                % plot(H(1),allCenter');
                % legend(H(1),names);

                % staticPos=arrayfun(@(n) meanPos{1},1:numel(meanPos),'unif',0);
                % statTracks=Detections().initFromPosMatrices(staticPos,staticPos).buildTracksFromDetection();
                % staticCov=arrayfun(@(n) covMX{1},1:numel(meanPos),'unif',0);
                % staticRef=FrameOfRef().setOriginFromTrack(statTracks);
                % staticRef.setBase(staticCov);

                %% testing 
                % detStaticRef=staticRef.applyBase(detections);
                % detRef=ref.applyBase(detections);
                % for fIdx=[1 200]
                %         scatter(H(2),detStaticRef(fIdx).getAllStruct().x,detStaticRef(fIdx).getAllStruct().y);
                %         scatter(H(3),detRef(fIdx).getAllStruct().x,detRef(fIdx).getAllStruct().y);
                %         hold on;
                % end

              case {'trackSetStable','fitTrackSetFrameByFrame'}
                %% Use tracks if necessary
                if(isempty(funParams.trackObjects))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                else
                    tracks=funParams.trackObjects;
                end
                tracks=fillTrackGaps(tracks);
                detections=Detections().setFromTracks(tracks);
                [ref,cenTrack]=ICPIntegration(detections);
                tracksROI=TracksROI([cenTrack;tracks],funParams.fringe,false);
                tracksROI.setDefaultRef(ref);
                dynROICell={tracksROI};

            case {'trackSetStableNew','fitTrackSetFrameByFrameNew'}
                %% Use tracks if necessary
                if(isempty(funParams.trackObjects))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                else
                    tracks=funParams.trackObjects;
                end
                tracks=fillTrackGaps(tracks);
                detections=Detections().setFromTracks(tracks);
                [ref,cenTrack]=ICPIntegrationPrevReg(detections);
                tracksROI=TracksROI([cenTrack;tracks],funParams.fringe,false);
                tracksROI.setDefaultRef(ref);
                dynROICell={tracksROI};  

              case {'trackSetStableDebug','fitTrackSetRegistered'}
                %% Use tracks if necessary
                if(isempty(funParams.trackObjects))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                else
                    tracks=funParams.trackObjects;
                end

                tracks=fillTrackGaps(tracks);
                %%
                detections=Detections().setFromTracks(tracks);
                [ref,cenTrack]=ICPIntegrationFirstReg(detections);
                
                % ZAxis=cellfun(@(p) [30,10,0],pos,'unif',0)
                % ZAxis=Detections().initFromPosMatrices(ZAxis,ZAxis).buildTracksFromDetection();
                % ZAxis=ref.applyInvBase(ZAxis);
                tracksROI=TracksROI([cenTrack;tracks],funParams.fringe,false);
                tracksROI.setDefaultRef(ref);

                dynROICell={tracksROI};

              case {'trackSetStatic','fitTrackSetStatic'}
                %% Compute the optimal bounding box around all the tracks
                %% QD implemenentation: using trackSetFit and keep the first 

                %% Use tracks if necessary
                if(isempty(funParams.trackObjects))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                else
                    tracks=funParams.trackObjects;
                end

                tracks=fillTrackGaps(tracks);
                %%
                detections=Detections().setFromTracks(tracks);
                [ref,cenTrack]=ICPIntegrationFirstReg(detections);

                origin=ref.origin;
                origin=repmat(origin(1,:),[size(origin,1) 1]);
                ref.origin=origin;
                ref.setBase(ref.getBase(1));
                
                % ZAxis=cellfun(@(p) [30,10,0],pos,'unif',0)
                % ZAxis=Detections().initFromPosMatrices(ZAxis,ZAxis).buildTracksFromDetection();
                % ZAxis=ref.applyInvBase(ZAxis);
                tracksROI=TracksROI([cenTrack;tracks],funParams.fringe,false);
                tracksROI.setDefaultRef(ref);

                dynROICell={tracksROI};



              case 'cellMask'
                if(isempty(funParams.movieData))
                    MD=process.getOwner();
                else
                    MD=funParams.movieData;
                end
                dynROICell={CellMaskROI(MD,funParams.processChannel,funParams.fringe)};

              case 'cellMaskReg'
                if(isempty(funParams.movieData))
                    MD=process.getOwner();
                else
                    MD=funParams.movieData;
                end
                dynROICell={CellMaskRegROI(MD,funParams.processChannel,funParams.fringe)};


              case 'selectROI'
                if(isempty(funParams.movieData))
                    MD=process.getOwner();
                else
                    MD=funParams.movieData;
                end


                if(isempty(funParams.processRendererDynROI))
                    vol=double(MD.getChannel(funParams.processChannel).loadStack(1));
                    maxXY = squeeze(max(vol,[],3)); 
                    imshow(maxXY,[],'Border','tight'); 
                    xyIndices = ceil(getrect);

                    vol2 = vol(xyIndices(2):xyIndices(2)+xyIndices(4),xyIndices(1):xyIndices(1)+xyIndices(3),:);
                    maxYZ = squeeze(max(vol2,[],1)); imshow(maxYZ,[],'Border','tight'); 
                    zIndices = ceil(getrect);
                    ratio=MD.pixelSizeZ_/MD.pixelSize_;
                    
                    roiIdx = nan(6,1);
                    roiIdx(1) = max(1,xyIndices(1));
                    roiIdx(2) = min(size(vol,2),xyIndices(1)+xyIndices(3)-1);
                    roiIdx(3) = max(1,xyIndices(2));
                    roiIdx(4) = min(size(vol,1),xyIndices(2)+xyIndices(4)-1);
                    roiIdx(5) = ratio*max(1,zIndices(1));
                    roiIdx(6) = ratio*min(size(vol,3),zIndices(1)+zIndices(3)-1);
                else
                    data=funParams.processRendererDynROI.loadFileOrCache();
                    dynROIProjectionCell=data{1}.processProjectionsCell;
                    [xBound,yBound,zBound]=dynROIProjectionCell{1}.getBoundingBox();
                    [maxXY,maxZY,maxZX,three]=dynROIProjectionCell{1}.loadFrame(funParams.processChannel,1);
                    
                    
                    hFig = figure; hAxes = axes( hFig );

                    Position = get(hAxes,'Position');
                    set(hAxes,'Position',[0.1 0.1 Position(3) Position(4)]);

                    imshow(maxXY,[],'Parent',hAxes); 
                    title(hAxes,'Select ROI in XY projection'); 
                    xyIndices = ceil(getrect(hAxes));
                    maxZX=maxZX(xyIndices(1):xyIndices(1)+xyIndices(3),:);
                    maxZX=maxZX';  % flip to get Z updated
                    
                    hFig = figure; hAxes = axes( hFig );
                     Position = get(hAxes,'Position');
                    set(hAxes,'Position',[0.1 0.1 Position(3) Position(4)]);
                    imshow(maxZX,[],'Parent',hAxes); 
                    title(hAxes,'Select ROI in XZ projection'); 
                    zIndices = ceil(getrect(hAxes));

                    XRatio=size(maxXY,2)/(xBound(2)-xBound(1))
                    YRatio=size(maxXY,1)/(yBound(2)-yBound(1))
                    xyIndices(1)=xyIndices(1)/XRatio+xBound(1);
                    xyIndices(2)=xyIndices(2)/YRatio+yBound(1);
                    xyIndices(3)=xyIndices(3)/XRatio;
                    xyIndices(4)=xyIndices(4)/YRatio;



                    ZRatio=size(maxZX,1)/(zBound(2)-zBound(1))
                    YRatio=size(maxZX,2)/(yBound(2)-yBound(1))
                    zIndices(1)=zIndices(1)/YRatio+yBound(1);
                    zIndices(2)=zIndices(2)/ZRatio+zBound(1);
                    zIndices(3)=zIndices(3)/YRatio;
                    zIndices(4)=zIndices(4)/ZRatio;
                    roiIdx = nan(6,1);
                    roiIdx(1) = xyIndices(1);
                    roiIdx(2) = xyIndices(1)+xyIndices(3)-1;
                    roiIdx(3) = xyIndices(2);
                    roiIdx(4) = xyIndices(2)+xyIndices(4)-1;
                    roiIdx(5) = zIndices(2);
                    roiIdx(6) = zIndices(2)+zIndices(4)-1;
                end

                fringe=abs(roiIdx(6)-roiIdx(5))/2;
                planeOrigin=[roiIdx(1),roiIdx(3),roiIdx(5)+fringe]; 
                planeZ=[roiIdx(1),roiIdx(3),roiIdx(6)]; 

                planeX=[roiIdx(1),roiIdx(4),roiIdx(5)+fringe]; 
                planeY=[roiIdx(2),roiIdx(3),roiIdx(5)+fringe]; 
                planeOpposed=[roiIdx(2),roiIdx(4),roiIdx(5)+fringe]; 

                planeZ2=[roiIdx(1),roiIdx(3),roiIdx(5)]; 

                planeDetections=arrayfun(@(p) [planeOrigin;planeZ;planeX;planeY;planeZ2;planeOpposed],1:MD.nFrames_,'unif',0);
                planeDetections=Detections().initFromPosMatrices(planeDetections,planeDetections);
                % [~,h1]=planeDetections.scatterPlot();

                if(~isempty(funParams.processRendererDynROI))
                    fp=funParams.processRendererDynROI.getParameters();
                    if(~isempty(fp.processBuildDynROI))
                        dynROIData=fp.processBuildDynROI.loadFileOrCache();
                        ref=dynROIData{1}.dynROICell{1}.getDefaultRef();
                        planeDetections=ref.applyInvBase(planeDetections);
                    end
                end
                % planeDetections.scatterPlot({},h1);
                planeTracks=planeDetections.buildTracksFromDetection();

                dynROI=PlanarROI(planeTracks,1);
                dynROICell={dynROI};

              case 'plane'  
                % tracks(1): origin, tracks(2)-tracks(1): Z, tracks(3)-tracks(1): Y
                if(isempty(funParams.trackObjects))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                else
                    tracks=funParams.trackObjects;
                end
                planarROI=PlanarROI(tracks,funParams.fringe);
                if(~isempty(funParams.resizeFactor))
                    planarROI.resize(funParams.resizeFactor(1,:),funParams.resizeFactor(2,:));
                end
                dynROICell={planarROI}; 

              case 'spindlePlan'
                if(isempty(funParams.trackObjects))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                else
                    tracks=funParams.trackObjects;
                end
                planarROI=PlanarROI(tracks,funParams.fringe);
                planarROI.resize([-50,50],[-50,50]);

                dynROICell={planarROI}; 

              case 'saveDynROI'
                dynROICell={funParams.dynROI}; 

              case 'cone'
                if(isempty(funParams.trackObjects))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                else
                    tracks=funParams.trackObjects;
                end
                
                %% Smaller Conical ROIs used for context (TODO replace with statistical model in the context ROI)
                angle=funParams.angle;
                dynROICell=cell(numel(tracks{1}),numel(tracks{2}));
                for cIdx=1:numel(tracks{1})
                    for aIdx=1:numel(tracks{2})
                        dynROICell{cIdx,aIdx}=ConeROI([tracks{1}(cIdx);tracks{2}(aIdx)],angle);
                    end
                end

              case 'roundedTube'
                if(isempty(funParams.trackObjects))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                else
                    tracks=funParams.trackObjects;
                end
                if(~iscell(tracks(1)))
                    tracks=arrayfun(@(t) t, tracks,'unif',0);
                end

                dynROICell=cell(numel(tracks{1}),numel(tracks{2}));
                for cIdx=1:size(tracks{1})
                    for aIdx=1:size(tracks{2})
                        dynROICell{cIdx,aIdx}=RoundedTubeROI([tracks{1}(cIdx);tracks{2}(aIdx)],funParams.fringe);
                    end
                end

              case 'randomSampling'
                dynROICell={};
                if(~isempty(funParams.detectionProcess))
                    detections=Detections(funParams.detectionProcess.loadChannelOutput(funParams.detectionProcessChannel));
                    N=detections.getCard();
                    if(sum(N)>0)
                        randSelect=arrayfun(@(n) randi([1 n],funParams.nSample,1),N,'unif',0);
                        detections.selectIdx(randSelect);
                        detections(:)=detections(1);
                        tracks=detections.buildTracksFromDetection();
                        dynROICell=arrayfun(@(t) TracksROI(t,funParams.fringe),tracks,'unif',0);
                    end
                end
                if(~isempty(funParams.trackProcess))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                    tracks=tracks([tracks.lifetime]==median([tracks.lifetime]));
                    randSelect=randi([1 numel(tracks)],funParams.nSample,1);
                    selectedTrack=tracks(randSelect);
                    dynROICell=cell(1,numel(selectedTrack));
                    for sIdx=1:numel(selectedTrack)
                        % dynROICell{2*sIdx-1}=TracksROI(selectedTrack(sIdx),20);
                        dynROICell{sIdx}=TracksROI(selectedTrack(sIdx),funParams.fringe);
                        ref=FrameOfRef().setOriginFromTrack(selectedTrack(sIdx)).genCanonicalBase();
                        dynROICell{sIdx}.setDefaultRef(ref);
                    end
                end
            case 'randomSamplingStatic'
                dynROICell={};
                if(~isempty(funParams.detectionProcess))
                    detections=Detections(funParams.detectionProcess.loadChannelOutput(funParams.detectionProcessChannel));
                    N=detections.getCard();
                    if(sum(N)>0)
                        randSelect=arrayfun(@(n) randi([1 n],funParams.nSample,1),N,'unif',0);
                        detections.selectIdx(randSelect);
                        detections(:)=detections(1);
                        tracks=detections.buildTracksFromDetection();
                        dynROICell=arrayfun(@(t) StaticTracksROI(t,funParams.fringe,false),tracks,'unif',0);
                    end
                end
                if(~isempty(funParams.trackProcess))
                    trackStruct=funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel);
                    if(~isempty(trackStruct))                     
                    tracks=TracksHandle(trackStruct);
                    lfts=[tracks.lifetime];
                    if(numel(lfts)>100) % Hack to avoid viewing too much outlier tracks
                        tracks=tracks((lfts>prctile(lfts,10))&(lfts<(prctile(lfts,90))));
                    end
                    randSelect=randi([1 numel(tracks)],funParams.nSample,1);
                    selectedTrack=tracks(randSelect);
                    dynROICell=cell(1,numel(selectedTrack));
                    for sIdx=1:numel(selectedTrack)
                        % dynROICell{2*sIdx-1}=TracksROI(selectedTrack(sIdx),20);
                        dynROICell{sIdx}=StaticTracksROI(selectedTrack(sIdx),funParams.fringe,false);
                        % ref=FrameOfRef().setOriginFromTrack(selectedTrack(sIdx)).genCanonicalBase();
                        % dynROICell{sIdx}.setDefaultRef(ref);
                    end
                    else
                        warning('No tracks detected, building a static dynROI');
                        dynROICell={StaticTracksROI([],funParams.fringe,false)};
                    end

                end
              case 'allTracks'
                dynROICell={};
                if(isempty(funParams.trackObjects))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                else
                    tracks=funParams.trackObjects;
                end
                tracks=tracks([tracks.lifetime]==max([tracks.lifetime]));
                dynROICell={TracksROI(tracks,funParams.fringe)};
                %   ref=FrameOfRef().setOriginFromTrack(tracks(1)).genCanonicalBase();
                % dynROICell{1}.setDefaultRef(ref);

              case 'allTracksStatic'
                dynROICell={};
                if(isempty(funParams.trackObjects))
                    tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
                else
                    tracks=funParams.trackObjects;
                end
                tracks=tracks([tracks.lifetime]==max([tracks.lifetime]));
                dynROICell={StaticTracksROI(tracks,funParams.fringe,false)};
                % ref=FrameOfRef().setOriginFromTrack(tracks(1)).genCanonicalBase();
                % dynROICell{1}.setDefaultRef(ref);
                
                
              case 'cytosol'
                disp('to be implemented');
              otherwise   
            end 

            process.saveChannelOutput(dynROICell);
            funParams.trackObjects=[];
            funParams.detectionsObject=[];
            process.setPara(funParams);
        end
        
        function funParams = getDefaultParams(owner)
        % Input check
            ip=inputParser;
            ip.addRequired('owner', @(x) isa(x, 'MovieObject'));
            ip.addOptional('outputDir', owner.outputDirectory_, @ischar);
            ip.parse(owner)
            
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
            funParams.processChannel=1;

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
            funParams.swappingVoxels=false;
            funParams.OutputDirectory = [ip.Results.outputDir  filesep 'stats'];       
            funParams.dynROI=[]; % for simple save purposes.
            funParams.resizeFactor=[];
            funParams.lifetimeOnly=false;            
            funParams.angle=pi/6;
            
        end
    end
end
