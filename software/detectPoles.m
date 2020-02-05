function [poleMovieInfo,tracks] = detectPoles(MD,varargin)
% Philippe Roudot 2014
% Detecting higher scale fidiciaries in 3D
% OUTPUT:
% - poleMovieInfo: anistropized(default) or isotropized location in the pixel referential.
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
ip = inputParser;
ip.CaseSensitive = false;
ip.KeepUnmatched=true;
ip.addRequired('MD',@(MD) isa(MD,'MovieData'));
ip.addParamValue('channel',1,@isnumeric);
ip.addParamValue('scales',3, @isnumeric);
ip.addParamValue('Alpha',0.05, @isnumeric);
ip.addParamValue('processFrames',[], @isnumeric);
ip.addParamValue('showAll', false, @islogical);
ip.addParamValue('printAll', false, @islogical);
ip.addParamValue('isoOutput', false, @islogical);
ip.addParamValue('type', 'simplex',  @ischar);
ip.addParamValue('process', []);
ip.parse(MD, varargin{:});
p=ip.Results;

processFrames=[];
if isempty(ip.Results.processFrames)
    processFrames=1:numel(MD.getChannel(ip.Results.channel).getImageFileNames);
else
    processFrames=ip.Results.processFrames;
end

scales=ip.Results.scales;
if(isscalar(scales))
    dataAnisotropy=[MD.pixelSize_ MD.pixelSize_ MD.pixelSizeZ_];
    scales=(scales*(dataAnisotropy/dataAnisotropy(1)).^(-1));
end

poleMovieInfo(numel(processFrames),1) = struct('xCoord', [], 'yCoord',[],'zCoord', [], 'amp', [], 'int',[]);
movieInfo(numel(processFrames),1) = struct('xCoord', [], 'yCoord',[],'zCoord', [], 'amp', [], 'int',[]);
parfor frameIdx=1:numel(processFrames)
    timePoint=processFrames(frameIdx);
    disp(['Processing time point ' num2str(timePoint,'%04.f')])
    vol=double(MD.getChannel(ip.Results.channel).loadStack(timePoint));
    ws = ceil(2*scales);

    gx = exp(-(0:ws(1)).^2/(2*scales(1)^2));
    gz = exp(-(0:ws(3)).^2/(2*scales(3)^2));
    fg = conv3fast(vol, gx, gx, gz);

    lm=locmaxnd(fg,ceil(scales));
%     lm(1:ws(1),:,:)=0;
%     lm(:,1:ws(2),:)=0;
%     lm(:,:,1:ws(3))=0;
    perc=100;
    notEnoughPoles=true;
    percentile=100;
    while( notEnoughPoles)
        perc=perc-5;
        percentile=prctile(lm(lm>0),perc);
        notEnoughPoles=sum(sum(sum(lm>=percentile)))<2;
    end
    lm(lm<percentile)=0;
    movieInfo(frameIdx)=pointCloudToMovieInfo(lm,vol);
end

%% load detection results and save them to Amira
if(ip.Results.printAll)
outputDirDetect=[MD.outputDirectory_ filesep 'poles' filesep ip.Results.type '_scale_' num2str(scales(1),'%03d') filesep 'poleCandidates'];
mkdir([outputDirDetect filesep 'AmiraPoles']);
amiraWriteMovieInfo([outputDirDetect filesep filesep 'polesCandidates.am'],movieInfo,'scales',ip.Results.scales);
end

%% Track each candidate to filter theire intensity and lifetime 
[gapCloseParam,costMatrices,kalmanFunctions,probDim,verbose]=candidatePolesTrackingParam();
outputDirTrack=[MD.outputDirectory_ filesep 'poles' filesep ip.Results.type '_scale_' ...
    num2str(scales(1),'%03d') filesep 'tracks'];

saveResults.dir =  outputDirTrack; % directory where to save input and output
saveResults.filename = 'trackResults.mat'; % name of file where input and output are saved
saveResults=[];
[tracksFinal,kalmanInfoLink,errFlag] = ...
    trackCloseGapsKalmanSparse(movieInfo, ...
    costMatrices,gapCloseParam,kalmanFunctions,...
    probDim,saveResults,verbose);

%% Convert tracks final in a user-friendlier format
tracks=TracksHandle(tracksFinal);

%% Retrieve innovation matrix
trackNoiseVar=arrayfun(@(x) kalmanInfoLink(tracks(x).segmentEndFrame).noiseVar(1,1,tracks(x).tracksFeatIndxCG(end)),1:length(tracks))';

%% Save track results to Amira
if(ip.Results.printAll)
    mkdir([outputDirTrack filesep 'AmiraTrack']);
    amiraWriteTracks([outputDirTrack filesep 'AmiraTrack' filesep 'test.am'],tracks,'scales',[MD.pixelSize_ MD.pixelSize_ MD.pixelSizeZ_],'edgeProp',{{'noiseVar',trackNoiseVar}});
end

%% For each frame, select the tracks that get the best score over its lifetime
tracksScore=[tracks.lifetime].*arrayfun(@(x) median(x.A),tracks)';

%% Compute the distance between each candidate (looking for stationary distance maybe ?)
% tracksMeanPos=[arrayfun(@(x) median(x.x),tracks) arrayfun(@(x) median(x.y),tracks) arrayfun(@(x) median(x.z),tracks)]
% distMatrix=createSparseDistanceMatrix(tracksMeanPos,tracksMeanPos,1000000);
% trackMaxDist=full(max(distMatrix));
% tracksScore=trackMaxDist;

%% Build a detections from the two best scores
for fIdx=1:numel(processFrames)
    timePoint=processFrames(fIdx);
    tracksOn=([tracks.endFrame]>=timePoint)&(timePoint>=[tracks.startFrame]);
    tracksLocal=tracks(tracksOn);
    relIdx=timePoint-[tracksLocal.startFrame]+1;
    [~,idx]=sort(tracksScore(tracksOn));
    selectedIdx=[];
    if(sum(tracksOn)>0)
        IdxPole1=(tracksLocal(idx(end)).tracksFeatIndxCG(relIdx(idx(end))));
        selectedIdx=[selectedIdx IdxPole1];
    end;
    if(sum(tracksOn)>1)
        IdxPole2=(tracksLocal(idx(end-1)).tracksFeatIndxCG(relIdx(idx(end-1))));
        selectedIdx=[selectedIdx IdxPole2];
    end;
    MI=movieInfo(timePoint);
    fn=fieldnames(MI);
    for i=1:length(fn) poleMovieInfo(fIdx).(fn{i})=MI.(fn{i})(selectedIdx,:); end;
end

if(p.isoOutput)
    for fIdx=1:length(poleMovieInfo)
        poleMovieInfo(fIdx).zCoord(:,1)=poleMovieInfo(fIdx).zCoord(:,1)*MD.pixelSizeZ_/MD.pixelSize_;
    end
end

%% create associated fiducial tracks 
pixelSize=1;
P1=TracksHandle();
P1.x=arrayfun(@(d) pixelSize*(d.xCoord(1,1)-1)+1,poleMovieInfo)';
P1.y=arrayfun(@(d) pixelSize*(d.yCoord(1,1)-1)+1,poleMovieInfo)';
P1.z=arrayfun(@(d) pixelSize*(d.zCoord(1,1)-1)+1,poleMovieInfo)';
P1.tracksFeatIndxCG=ones(1,length(poleMovieInfo));
P1.endFrame=length(poleMovieInfo);
P1.segmentStartFrame=1;
P1.segmentEndFrame=length(poleMovieInfo);
P1.startFrame=1;

P2=TracksHandle();
P2.x=arrayfun(@(d) pixelSize*(d.xCoord(2,1)-1)+1,poleMovieInfo)';
P2.y=arrayfun(@(d) pixelSize*(d.yCoord(2,1)-1)+1,poleMovieInfo)';
P2.z=arrayfun(@(d) pixelSize*(d.zCoord(2,1)-1)+1,poleMovieInfo)';
P2.tracksFeatIndxCG=2*ones(1,length(poleMovieInfo));
P2.endFrame=length(poleMovieInfo);
P2.startFrame=1;
P2.segmentStartFrame=1;
P2.segmentEndFrame=length(poleMovieInfo);
tracks=[P1 P2];

process=ip.Results.process;
if(~isempty(process))
    mkdirRobust(outputDirTrack);
    save([outputDirTrack filesep 'trackNewFormat.mat'],'tracks');
    outputDirPoleDetect=[process.getOwner().outputDirectory_ filesep 'poles' filesep ip.Results.type '_scale_' num2str(scales(1),'%03d')];
    save([outputDirPoleDetect filesep 'poleDetection.mat'],'poleMovieInfo','tracks');
    process.setOutFilePaths({[outputDirPoleDetect filesep 'poleDetection.mat'],[outputDirTrack filesep 'trackNewFormat.mat']})
    
    % new parameter bug
%     pa = process.getParameters();
%     pa.parameters = ip.Results;
%     process.setParameters(pa);
    process.setDateTime();
end


function movieInfo= labelToMovieInfo(label,vol)
[feats,nFeats] = bwlabeln(label);
featsProp = regionprops(feats,vol,'Area','WeightedCentroiccd','MeanIntensity','MaxIntensity','PixelValues');

% centroid coordinates with 0.5 uncertainties
tmp = vertcat(featsProp.WeightedCentroid)-1;
xCoord = [tmp(:,1) 0.5*ones(nFeats,1)]; yCoord = [tmp(:,2) 0.5*ones(nFeats,1)]; zCoord = [tmp(:,3) 0.5*ones(nFeats,1)];
amp=[vertcat(featsProp.MaxIntensity) 0.5*ones(nFeats,1)];

% u-track formating
movieInfo=struct('xCoord',[],'yCoord',[],'zCoord',[],'amp',[],'int',[]);
movieInfo.xCoord= xCoord;movieInfo.yCoord=yCoord;movieInfo.zCoord=zCoord;
movieInfo.amp=amp;
movieInfo.int=amp;

function movieInfo= pointCloudToMovieInfo(imgLM,vol)
    lmIdx = find(imgLM~=0);
    [lmy,lmx,lmz] = ind2sub(size(vol), lmIdx);
    N=length(lmy);
    % centroid coordinates with 0.5 uncertainties
    xCoord = [lmx 0.5*ones(N,1)]; yCoord = [lmy 0.5*ones(N,1)]; zCoord = [lmz 0.5*ones(N,1)];
    amp=[vol(lmIdx) 0.5*ones(N,1)];

    % u-track formating
    movieInfo=struct('xCoord',[],'yCoord',[],'zCoord',[],'amp',[],'int',[]);
    movieInfo.xCoord= xCoord;movieInfo.yCoord=yCoord;movieInfo.zCoord=zCoord;
    movieInfo.amp=amp;
    movieInfo.int=amp;



function movieInfo= pstructToMovieInfo(pstruct)
movieInfo.xCoord = [pstruct.x'-1 pstruct.x_pstd'];
movieInfo.yCoord = [pstruct.y'-1 pstruct.y_pstd'];
movieInfo.zCoord = [pstruct.z'-1 pstruct.z_pstd'];
movieInfo.amp = [pstruct.A' pstruct.A_pstd'];
movieInfo.int= [pstruct.A' pstruct.A_pstd'];

function threshNoise= QDApplegateThesh(filterDiff,show)
        % Perform maximum filter and mask out significant pixels
        thFilterDiff = locmax3d(filterDiff,1);
        threshold = thresholdOtsu(thFilterDiff)/3 + ...
            thresholdRosin(thFilterDiff)*2/3;
        std=nanstd(filterDiff(thFilterDiff<threshold));
        threshNoise= 3*std;

        if(show)
            figure();hist(thFilterDiff,100),vline([threshNoise, threshold],['-b','-r']);
        end
