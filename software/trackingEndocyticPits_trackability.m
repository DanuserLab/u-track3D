%% This script demonstrates the manual definition of a ROI nested in a dynROI and
%% the computation of trackability. 
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

% Processing work flow:
% 0) build movies
% 1) MIP
% 2) detect
% 3) track
% 4) Build dynROI
% 5) Render dynROI
% 6) Select Manual dynROI 
% 7) Render Manual dynROI 
% 8) Detect in dynROI
% 9) Track in dynROI with trackability 

close all;
clear all;

if(isempty(which('MovieData')))
	error('The code folder must be loaded first.');
end

try
	parpool(20)
catch 
	disp('Parallel pool runnning');
end

%% Build MD by channel
analysisRoot = ['/project/bioinformatics/Danuser_lab/shared/proudot/3D-u-track/GUIDev/analysis/test/']; % Output folder for movie metadata and results
mkClrDir(analysisRoot);

fullpath1 = '/project/bioinformatics/Danuser_lab/shared/proudot/3D-u-track/GUIDev/raw/endocyticPits_cropped/'; % Raw data path 
c1 = Channel(fullpath1);
MD = MovieData(c1,analysisRoot); 
MD.setPath(analysisRoot); 
MD.setFilename('movieData.mat');
MD.pixelSize_ = 0.1040
MD.pixelSizeZ_ = 0.3500; 
MD.timeInterval_ = 1;
MD.sanityCheck;
MD.save;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run rendering, detection and tracking process.

% MIP Rendering process
% Creation and naming
processRenderFullMIP=RenderDynROI(MD);
processRenderFullMIP.setProcessTag('fullMIP');
% Setting parameter
funParams=processRenderFullMIP.getParameters();
funParams.mipSize=800;
processRenderFullMIP.setPara(funParams);
processRenderFullMIP.run();
MD.addProcess(processRenderFullMIP);
MD.save();

%% Detection parameterization and processing 
processDetection=PointSourceDetectionProcess3D(MD);
MD.addProcess(processDetection);
funParams = processDetection.getParameters();
funParams.algorithmType= {'multiscaleDetectionDebug'};
funParams.version='useMaxResponse';
funParams.debug=false;
Scales=1.25:0.5:2.5; % Range of scales to be estimated
funParams.scales=Scales;
funParams.Alpha=0.001; % p-value used to select sensitivity
funParams.OutputDirectory=[MD.outputDirectory_ filesep processDetection.getProcessTag()];
processDetection.setPara(funParams);
paramsIn.ChannelIndex=1;
paramsIn.isoCoord=true;
processDetection.run(paramsIn);    
processDetection.setProcessTag('detection');

% Tracking parameterization and processing 
processTrack=TrackingProcess(MD);
MD.addProcess(processTrack);    
funParams = processTrack.funParams_;
newFunParams=AP2TrackingParameters(funParams); % Tracking parameters
processTrack.setPara(newFunParams);
paramsIn.ChannelIndex=1;
paramsIn.DetProcessIndex=processDetection.getIndex();
processTrack.run(paramsIn);
processTrack.setProcessTag('tracking');

% Estimate DynROI 
processBuildDynROI=BuilDynROI(MD);
funParams=processBuildDynROI.getParameters();
tracks=TracksHandle(processTrack.loadChannelOutput(1)); 
tracks=tracks([tracks.lifetime]>10);		
funParams.trackObjects=tracks;
funParams.roiType='fitTrackSetFrameByFrame'; % Building the DynROI around the set of trajectories
funParams.fringe=10;
processBuildDynROI.setPara(funParams);
processBuildDynROI.setProcessTag('trackSetROI');
processBuildDynROI.run();
MD.addProcess(processBuildDynROI);

% Render DynROI MIPs
processRenderDynROI=RenderDynROI(MD);
processRenderDynROI.setProcessTag('renderTracksROI');
% DynROI are specified, it will render each ROI in the BuildDynROI process.
funParams=processRenderDynROI.getParameters()
funParams.processBuildDynROI=MD.searchProcessTag('trackSetROI');
processRenderDynROI.setPara(funParams);
funParams.intMinPrctil=[50];
funParams.intMaxPrctil=[99.99];
processRenderDynROI.run();
MD.addProcess(processRenderDynROI);

% Manually select a ROI in the DynROI 
processBuildDynROI=BuilDynROI(MD);
funParams=processBuildDynROI.getParameters();
tracks=TracksHandle(processTrack.loadChannelOutput(1)); 
tracks=tracks([tracks.lifetime]>10);		
funParams.trackObjects=tracks;
funParams.roiType='selectROI'; % Manual selection
funParams.processRendererDynROI=MD.searchProcessTag('renderTracksROI'); % View on which the selection is made
funParams.fringe=10;
processBuildDynROI.setPara(funParams);
processBuildDynROI.setProcessTag('selectROI');
processBuildDynROI.run();
MD.addProcess(processBuildDynROI);

% Render DynROI MIPs
processRenderDynROI=RenderDynROI(MD);
processRenderDynROI.setProcessTag('renderSelectROI');
% DynROI are specified, it will render each ROI in the BuildDynROI process.
funParams=processRenderDynROI.getParameters()
funParams.processBuildDynROI=MD.searchProcessTag('selectROI');
processRenderDynROI.setPara(funParams);
funParams.intMinPrctil=[50];
funParams.intMaxPrctil=[99.99];
processRenderDynROI.run();
MD.addProcess(processRenderDynROI);
MD.save();

% Detect in the dynROI 
processDetection=PointSourceDetectionProcess3D(MD);
MD.addProcess(processDetection);
funParams = processDetection.getParameters();
funParams.algorithmType= {'multiscaleDetectionDebug'};
funParams.version='useMaxResponse';
funParams.debug=false;
Scales=1.25:0.5:2.5;
funParams.scales=Scales;
funParams.Alpha=0.001;
funParams.processBuildDynROI=MD.searchProcessTag('selectROI');
funParams.OutputDirectory=[MD.outputDirectory_ filesep processDetection.getProcessTag()];
processDetection.setPara(funParams);
paramsIn.ChannelIndex=1;
paramsIn.isoCoord=true;
processDetection.run(paramsIn);    
processDetection.setProcessTag('detectInROI');

% Track in the dynROI, enabling trackability computations.
processTrack=TrackingProcess(MD, 	[MD.outputDirectory_ filesep 'tracks-inROI']);
MD.addProcess(processTrack);  
processTrack.setProcessTag('trackInROIs');
	  
funParams = processTrack.funParams_;
newFunParams=AP2TrackingParameters(funParams);
newFunParams.processBuildDynROI=MD.searchProcessTag('selectROI');
newFunParams.EstimateTrackability=true;
processTrack.setPara(newFunParams);
paramsIn.ChannelIndex=1;
paramsIn.DetProcessIndex=processDetection.getIndex();
processTrack.run(paramsIn);

MD.save();

%% DISPLAY DEMO

%% Display ROI location
animDynROI=MD.searchProcessTag('selectROI').displayAll(MD.searchProcessTag('fullMIP'),'linewidth',2,'showROIOnly',false);

renderROI=MD.searchProcessTag('renderSelectROI');
%% Display tracks 
cm=256*prism(256);
trackDisplayParameters = {'useGraph',true,'colormap',cm,'trackLabel','ID','linewidth',5,'dragonTail',50,'show',true};
animTracks = MD.searchProcessTag('trackInROIs').displayAll(1,renderROI,trackDisplayParameters{:})

%% Display tracks colored according to average trackability
cm=256*parula(256);
trackDisplayParameters = {'useGraph',true,'colormap',cm,'showTrackability',2,'linewidth',5,'dragonTail',50,'show',true,'showNumber',false};
animTrackability = MD.searchProcessTag('trackInROIs').displayAll(1,renderROI, ...
                                                  trackDisplayParameters{:})
trackDisplayParameters = {'useGraph',true,'colormap',cm,'trackLabel','meanTrackability','linewidth',5,'dragonTail',50,'show',true};
animTrackability = MD.searchProcessTag('trackInROIs').displayAll(1,animTrackability,trackDisplayParameters{:})

%% Assemble ROI location and details in a single movie
movieArray={animDynROI,{animTracks;animTrackability}};
animArray=printProcMIPArrayCellBased(movieArray,'/tmp/','maxWidth',1920,'maxHeigth',1080,'forceWidth',false);
animArray.imdisp();
animArray.saveVideo(fullfile(MD.getPath(), 'detailROI.avi'),'frameRate',4);
animArray.printAnimation(fullfile(MD.getPath(), 'detailROI','detailROI.png'));

%% Load and plot trackability measurements
tmp=load(MD.searchProcessTag('trackInROIs').outFilePaths_{3,1}); 
trackabilityData=tmp.trackabilityData;
stateCountCell=cellfun(@numel,trackabilityData.trackabilityCost);
trackabilityMeanArray=cellfun(@nanmean,trackabilityData.trackabilityCost);

figure();
subplot(2,1,1);
plot(1:MD.nFrames_,stateCountCell);
ylabel('Trajectories count');
xlabel('Frames');
xlim([2 MD.nFrames_]);

subplot(2,1,2);
plot(1:MD.nFrames_,trackabilityMeanArray);
ylabel('Avg trackability Score');
xlabel('Frames');
xlim([2 MD.nFrames_]);
ylim([0.5 1]);
