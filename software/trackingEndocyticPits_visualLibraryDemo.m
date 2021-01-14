%% This script demonstrates the definition of a dynROI using a group of trajectory
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
% 4) Build ROI
% 5) Render ROI
% 6) Detect in ROI
% 7) Track in ROI

close all; 

if(isempty(which('MovieData')))
	error('The code folder must be loaded first.');
end

try
	parpool(20)
catch 
	disp('Parallel pool runnning');
end 


%% Build MD by channel
analysisRoot = ['/tmp/GUITuto/']; % Output folder for movie metadata and results
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
funParams.processBuildDynROI=MD.searchProcessTag('trackSetROI');
funParams.OutputDirectory=[MD.outputDirectory_ filesep processDetection.getProcessTag()];
processDetection.setPara(funParams);
paramsIn.ChannelIndex=1;
paramsIn.isoCoord=true;
processDetection.run(paramsIn);    
processDetection.setProcessTag('detectInROI');

% Track in the dynROI 
processTrack=TrackingProcess(MD, [MD.outputDirectory_ filesep 'tracks-inROI']);	
MD.addProcess(processTrack);    
funParams = processTrack.funParams_;
newFunParams=AP2TrackingParameters(funParams);
newFunParams.processBuildDynROI=MD.searchProcessTag('trackSetROI');
processTrack.setPara(newFunParams);
paramsIn.ChannelIndex=1;
paramsIn.DetProcessIndex=processDetection.getIndex();
processTrack.run(paramsIn);
processTrack.setProcessTag('trackInROIs');

MD.save();

%% DISPLAY DEMO 1: MIP overlay library 

%% Display detections
cm=256*parula(256);
detectionDisplayParameters={'colormap',cm,'renderingMethod','FilledCircle','radius',1};
animDetect=processDetection.displayAll(1,MD.searchProcessTag('fullMIP'),detectionDisplayParameters{:})

%% Display tracks
cm=256*parula(256);
trackDisplayParameters={'useGraph',true,'colormap',cm,'trackLabel','lifetime','linewidth',1,'show',true};
animTracks=processTrack.displayAll(1,MD.searchProcessTag('fullMIP'),trackDisplayParameters{:})

%% Display ROI location
animDynROI=processBuildDynROI.displayAll(MD.searchProcessTag('fullMIP'),'linewidth',2,'showROIOnly',false);

%% Display ROI rendering
renderROI=processRenderDynROI.displayAll();

%% Display detections in ROI Rendering with circle 
cm=256*jet(256);
detectionDisplayParameters={'colormap',cm,'renderingMethod','Circle','radius',3};
animDetectCircle=processDetection.displayAll(1,renderROI,detectionDisplayParameters{:})

%% Display detections in ROI Rendering with opacity
cm=256*parula(256);
detectionDisplayParameters={'colormap',cm,'renderingMethod','FilledCircle','radius',1,'opacity',0.5};
animDetect=processDetection.displayAll(1,renderROI,detectionDisplayParameters{:})

%% Display tracks on top of detection, colored according to instantaneous speed
trackDisplayParameters = {'useGraph',true,'colormap',cm,'trackLabel','speed','linewidth',1,'show',true};
animTracks = MD.searchProcessTag('trackInROIs').displayAll(1,animDetect,trackDisplayParameters{:})

%% Assemble ROI location and details in a single movie
movieArray={animDynROI,{renderROI;animDetectCircle}};
animArray=printProcMIPArrayCellBased(movieArray,'/tmp/','maxWidth',1920,'maxHeigth',1080,'forceWidth',false);
animArray.imdisp();
animArray.saveVideo(fullfile(MD.getPath(), 'detailROI.avi'),'frameRate',4);
animArray.printAnimation(fullfile(MD.getPath(), 'detailROI','detailROI.png'));


%% DISPLAY DEMO 2: Amira export 

%% Visualization with Amira

% Write detection only
detections=MD.searchProcessTag('detection').loadChannelOutput(1);
amiraWriteMovieInfo(fullfile(MD.getPath(), 'amira','amiraDetection','amiraDetection.am'),detections);

% Write tracks with custom labelling for display
processTrack=MD.searchProcessTag('tracking');
tracks=TracksHandle(processTrack.loadChannelOutput(1));
amiraWriteTracks(fullfile(MD.getPath(), 'amira','amiraTracks','amiraTracks.am'),tracks); 

%% DISPLAY DEMO 3: Fast point cloud rendering 

% Loading the detection mask
detectionMasks=MD.searchProcessTag('detectInROI').loadChannelOutput(1,'output','labelSegPos')

% Display time points 1 and 10.
detectionMasks(1).scatterPlot();
detectionMasks(10).scatterPlot();

% $$$ % Dynamic display
% $$$ v=PCViewer();
% $$$ v.addDetection(detectionMasks,255*parula(256));
% $$$ v.dynScatterPlot();
 