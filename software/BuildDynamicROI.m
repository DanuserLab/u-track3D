function BuildDynamicROI(movieDataOrProcess, varargin)
% BuildDynamicROI wrapper function for BuilDynROI.runFunction
% to be executed by BuildDynROIProcess.
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
[movieData, thisProc] = getOwnerAndProcess(movieDataOrProcess, 'BuildDynROIProcess', true);
p = parseProcessParams(thisProc, paramsIn); % If parameters are explicitly given, they should be used
% rather than the one stored in RenderFullMIPProcess

% Parameters: funParams = p;

% Sanity Checks
nChan = numel(movieData.channels_);
if max(p.ChannelIndex) > nChan || min(p.ChannelIndex)<1 || ~isequal(round(p.ChannelIndex), p.ChannelIndex)
    error('Invalid channel numbers specified! Check ChannelIndex input!!')
end

% precondition / error checking
% if p.trackObjects is empty, then both p.trackProcess and p.trackProcessChannel cannot be empty!
% Since p.trackObjects is not on GUI, then both p.trackProcess and p.trackProcessChannel need to be set on GUI.
if isempty(p.trackObjects) && isempty(p.trackProcess)
    error("Tracking Process needs to be chosen before run this process!")
end
if isempty(p.trackObjects) && isempty(p.trackProcessChannel)
    error("Input Tracking Channel cannot be empty before run this process!")
end

% logging input paths (bookkeeping)
inFilePaths = cell(1, numel(movieData.channels_));
for i = p.ChannelIndex
    inFilePaths{1,i} = movieData.getChannelPaths{i};
end
thisProc.setInFilePaths(inFilePaths);


%% Algorithm
% Copied from BuilDynROI.runFunction, expect first line, line 707-708 and last 4 lines.
% Edited outputDir of DynROI.swapDynBoundingBox so DynROI raw images results can be saved in appropriate folders. -- Oct 2019

funParams = p; % change variable name to be consistent with BuilDynROI.runFunction
process = thisProc; % change variable name to be consistent with BuilDynROI.runFunction
funParams.processChannel = funParams.ChannelIndex; % change variable name to be consistent with BuilDynROI.runFunction


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
        
        
        
    case {'trackSetStable','fitTrackSetFrameByFrame'}
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
            imshow(maxXY,[],'Border','tight');
            xyIndices = ceil(getrect);
            maxZX=maxZX(xyIndices(1):xyIndices(1)+xyIndices(3),:);
            maxZX=maxZX';  % flip to get Z up
            imshow(maxZX,[],'Border','tight');
            zIndices = ceil(getrect);
            
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
        for cIdx=1:size(tracks{1})
            for aIdx=1:size(tracks{2})
                dynROICell{cIdx,aIdx}=ConeROI([tracks{1}(cIdx);tracks{2}(aIdx)],angle);
            end
        end
        
    case 'roundedTube'
        if(isempty(funParams.trackObjects))
            tracks=TracksHandle(funParams.trackProcess.loadChannelOutput(funParams.trackProcessChannel));
        else
            tracks=funParams.trackObjects;
        end
        
        %% Smaller Conical ROIs used for context (TODO replace with statistical model in the context ROI)
        
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
            tracks=tracks([tracks.lifetime]==max([tracks.lifetime]));
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

%%%% end of algorithm

% save output, see BuilDynROI.saveChannelOutput, updated 2019-08-07 to
% include boundingBox.mat, updated 2019-08-21 to add movieDataDynROICell.mat

% dynROIs.mat and boundingBox.mat are not channel specific (i.e. in algorithm processChannel default is 1). 
% But DynROI raw images are channel specific, the info of which save in the same movieDataDynROICell.mat.
% movieDataDynROICell.mat contains a dir of a build movieData based on those
% DynROI raw images.
% Same outFilePaths for diff iChan.
outFilePaths = cell(3, numel(movieData.channels_));

for i = p.ChannelIndex
    outFilePaths{1,i} = [p.OutputDirectory filesep 'dynROIs.mat'];
    mkdirRobust(fileparts(outFilePaths{1,i}));
    save(outFilePaths{1,i},'dynROICell');
    
    outFilePaths{2,i} = [p.OutputDirectory filesep 'boundingBox.mat'];
    mkdirRobust(fileparts(outFilePaths{2,i}));
    
    vertices=cell(1,thisProc.getOwner().nFrames_);
    edges=cell(1,thisProc.getOwner().nFrames_);
    for fIdx=1:thisProc.getOwner().nFrames_
        [vertices{fIdx},edges{fIdx}]=dynROICell{1}.getBoundingParallelogram(fIdx);
    end
    save(outFilePaths{2,i},'vertices','edges');
    
    % Cropping and transforming voxel mapped in the DynROIs
    if(p.swappingVoxels)
        outFilePaths{3,i} = [p.OutputDirectory filesep 'movieDataDynROICell.mat']; % DynROI detection and tracking on GUI use this results outFilePaths{3,1} too.
        mkdirRobust(fileparts(outFilePaths{3,i}));
        movieDataDynROICell=cell(1,numel(dynROICell));
        for dIdx=1:numel(dynROICell)
%             subFolder=fullfile(thisProc.tag_, ['dynROI_' num2str(dIdx)]);
%             [~,movieDataDynROICell{dIdx}]=dynROICell{dIdx}.swapDynBoundingBox(thisProc.getOwner(),subFolder);
            subFolder='dynROI_rawImages'; % QZ edited. Oct 2019
            [~,movieDataDynROICell{dIdx}]=dynROICell{dIdx}.swapDynBoundingBox(thisProc.getOwner(),subFolder, 'outputDir', [p.OutputDirectory filesep subFolder]); % QZ edited. Oct 2019
        end
        save(outFilePaths{3,i},'movieDataDynROICell');
        
        % if numel(p.ChannelIndex) > 1
        %     for i = 2:numel(p.ChannelIndex)
        %         outFilePaths{1,i} = [p.OutputDirectory filesep 'dynROIs.mat']; % if leave this [], checkChannelOutput will not approve, chan >1 won't show on movieViewer GUI
        %         outFilePaths{2,i} = [p.OutputDirectory filesep 'boundingBox.mat'];
        %         outFilePaths{3,i} = [p.OutputDirectory filesep 'movieDataDynROICell.mat'];
        %     end
        % end
    end
end

% currTrackObjects=[]; % QZ why this was set to [] at the end of process???
% currDetectionsObject=[]; % QZ ???
% process.setPara(funParams); % QZ ???



% logging output paths. Note: DynROI are not channel specific! only have 2 .mat output files even for multiple channels
thisProc.setOutFilePaths(outFilePaths);

disp('Finished building dynamic ROI!')

end