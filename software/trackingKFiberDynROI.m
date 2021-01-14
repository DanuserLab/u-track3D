% Building, rendering and analysing  a dynROI between two tajectories
% Reproduce Figure 2.j-m. of Roudot et. al "u-track 3D: measuring and interrogating
% intracellular dynamics in three dimensions" 2020
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

% Processes
% 1) Render MIP
% 2) Detect Poles
% 3) Track Poles
% 4) Detect Kinetochores
% 5) Track Kinetochores
% 6) Build DynROI for the K-fiber (between one pole and one kinetochore)
% 7) Render DynROI
% 8) Detect Plus-ends in the dynROI only
% 9) Display and statistics


% Matlab environment init (clear & close, start parallelization, add code)
clear all; 
% Parallel workers
try, parpool(12);  catch disp('Parallel workers are already running.'); end
% Closing windows
close all; ff = findall(0,'Type', 'Figure');delete(ff);
% Adding code automatically
% addpath(genpath('~/repo/utsw-ssh/'));

% Data-related variables
KTChannel=2;
EB3Channel=1;
lateralPixelSize=100;
axialPixelSize=216;

% Folder where results and metadata are saved
analysisRoot='/project/bioinformatics/Danuser_lab/shared/proudot/3D-u-track/analysis/coneROIScript/';

%% Build MD by channel
fullpath1 = '/project/bioinformatics/Danuser_lab/shared/proudot/3D-u-track/analysis/coneROI/2DImg_for_1min/cell1_12_half_volume_double_time/analysis/selectROI-swap/ch1/';
fullpath2 = '/project/bioinformatics/Danuser_lab/shared/proudot/3D-u-track/analysis/coneROI/2DImg_for_1min/cell1_12_half_volume_double_time/analysis/selectROI-swap/ch2/';
path1 = [analysisRoot filesep 'movieData' filesep]; % Output folder for movie metadata and results
mkClrDir(path1);
c1 = Channel(fullpath1);
c2 = Channel(fullpath2);
MD = MovieData([c1,c2],path1); 
MD.setPath(path1); 
MD.setFilename('movieData.mat');
MD.pixelSize_ = lateralPixelSize;
MD.pixelSizeZ_ = axialPixelSize;
MD.timeInterval_ = 1;
MD.sanityCheck;
MD.save;

%% Rendering the dual channel data
processRenderROI=RenderDynROI(MD);
funParams=processRenderROI.getParameters();
funParams.processChannel=[1 2];
funParams.gamma={0.5 1.2}; % Gamma for channel 1 and 2
funParams.contrastIn={[0 1],[0.5 1]}; % Contrast limit for channel 1 and 2
funParams.channelRender='grayRedMix2'; % Channel mixing mode
processRenderROI.setPara(funParams);
processRenderROI.setProcessTag('renderMIP');
processRenderROI.run();
processRenderROI.displayAll(); % display the output 
MD.addProcess(processRenderROI);

%% Detecting poles 
process=PointSourceDetectionProcess3D(MD, [MD.outputDirectory_ filesep 'poleMultiscale']);
process.setProcessTag('poleMultiscale');
MD.addProcess(process);
funParams = process.funParams_;
funParams.algorithmType= {'multiscaleDetectionDebug'};
funParams.version='useMaxResponse';
funParams.debug=false;
funParams.scales=5; % object scale (can be multiple)
funParams.Alpha=0.005; % p-value for statistical test (the lower the stricter)
funParams.OutputDirectory=[MD.outputDirectory_ filesep process.getProcessTag()];
process.setPara(funParams);
paramsIn.ChannelIndex=EB3Channel;
paramsIn.isoCoord=true;
process.run(paramsIn);

%% Tracking poles
processTrack=TrackingProcess(MD, [MD.outputDirectory_ filesep 'poleTracking']);
MD.addProcess(processTrack);    
funParams = processTrack.funParams_;
[gapCloseParam,costMatrices,kalmanFunctions,probDim,verbose]=poleTrackingParamDemo();
funParams.gapCloseParam=gapCloseParam;
funParams.costMatrices=costMatrices;
funParams.kalmanFunctions=kalmanFunctions;
funParams.probDim=probDim;
processTrack.setPara(funParams);
paramsIn.ChannelIndex=EB3Channel;
paramsIn.DetProcessIndex=MD.searchProcessTag('poleMultiscale').getIndex();
processTrack.run(paramsIn);
processTrack.setProcessTag('poleTracking');

% Detecting KT
processDetect=PointSourceDetectionProcess3D(MD,[MD.outputDirectory_ filesep 'detectKT']);
processDetect.setProcessTag('detectKT');
funParams = processDetect.getParameters();
funParams.scales=[1.5 1.75 2.0]; % object scale (can be multiple)
funParams.Alpha=0.005; % p-value for statistical test (the lower the stricter)
funParams.OutputDirectory=[MD.outputDirectory_ filesep processDetect.getProcessTag()];
funParams.algorithmType= {'multiscaleDetectionDebug'};
funParams.version='useMaxResponse';
funParams.debug=false;
funParams.RemoveRedundant=true;
funParams.RedundancyRadius=3;
processDetect.setPara(funParams);
paramsIn.ChannelIndex=KTChannel;
paramsIn.isoCoord=true;
MD.addProcess(processDetect); % This is necessary for backward compatibility.
processDetect.run(paramsIn);  

% Tracking KT 
processTrackKT=TrackingProcess(MD, [MD.outputDirectory_ filesep 'trackingKT']);
MD.addProcess(processTrackKT);    
funParams = processTrackKT.funParams_;
[gapCloseParam,costMatrices,kalmanFunctions,probDim,verbose]=kinTrackingParamV2();
funParams.gapCloseParam=gapCloseParam;
funParams.costMatrices=costMatrices;
funParams.kalmanFunctions=kalmanFunctions;
funParams.probDim=probDim;
processTrackKT.setPara(funParams);
paramsIn.ChannelIndex=KTChannel;
paramsIn.DetProcessIndex=MD.searchProcessTag('detectKT').getIndex();
processTrackKT.run(paramsIn);
processTrackKT.setProcessTag('trackingKT');

% Build KT Fiber ROI 
processTagFiber=['paperFiber'];
KTTracks=TracksHandle(MD.searchProcessTag('trackingKT').loadChannelOutput(KTChannel));
PoleTracks=TracksHandle(MD.searchProcessTag('poleTracking').loadChannelOutput(EB3Channel));
KTID=28;
PoleID=1;
process=BuilDynROI(MD);
funParams=process.getParameters();
funParams.trackObjects={PoleTracks(PoleID);KTTracks(KTID)};
funParams.roiType='cone';
funParams.angle=pi/16;
process.setPara(funParams);
process.setProcessTag(processTagFiber);
process.run();
MD.addProcess(process)

% Rendering the KT Fiber MIP
processTag='renderPaperFiber'
processRenderCone=RenderDynROI(MD);
funParams=processRenderCone.getParameters();
funParams.processBuildDynROI=MD.searchProcessTag('paperFiber');
funParams.processChannel=[1 2];
funParams.gamma={0.5 1.2};
funParams.contrastIn={[0 1.0],[0.1 1]};
funParams.channelRender='grayRedMix2';
funParams.Zup=true;
funParams.Zright=false;
processRenderCone.setPara(funParams);
processRenderCone.setProcessTag(processTag);
processRenderCone.run();
MD.addProcess(processRenderCone);

% Detecting Plus-ends inside the KT Fiber MIP
processDetectEB3=PointSourceDetectionProcess3D(MD, [MD.outputDirectory_ filesep 'EB3-MS']);
processDetectEB3.setProcessTag('detectEB3MS');
MD.addProcess(processDetectEB3);
funParams = processDetectEB3.funParams_;
funParams.algorithmType= {'multiscaleDetectionDebug'};
funParams.version='useMaxResponse';
funParams.debug=false;
funParams.scales=[1.2 1.5 2.0 3.0];
funParams.Alpha=0.005;
funParams.OutputDirectory=[MD.outputDirectory_ filesep processDetectEB3.getProcessTag()];
funParams.processBuildDynROI=MD.searchProcessTag('paperFiber');
processDetectEB3.setPara(funParams);
paramsIn.ChannelIndex=EB3Channel;
paramsIn.isoCoord=true;
processDetectEB3.run(paramsIn);

MD.save();

%% Build video array: dynROI location + dynROI voxel in its frame of reference
if(true)
dynROI=MD.searchProcessTag('paperFiber').loadChannelOutput();
dynROI=dynROI{1};

% Rendering ROI location 
processRender=MD.searchProcessTag('renderMIP');
cm=(255*summer(16));
cm=cm(end,:);
roiLocationAnim=MD.searchProcessTag('paperFiber').displayAll(processRender, ...
            'linewidth',2,'processFrames',[], ... 
            'show',false,'colormap',cm,'colorTail',true,'showROIOnly',false);

% Rendering plus-ends and KT in the dynROI 
processRender=MD.searchProcessTag('renderPaperFiber');
det=Detections(MD.searchProcessTag('detectEB3MS').loadChannelOutput(EB3Channel));
det=dynROI.mapDetections(det);
mappedCone=MD.searchProcessTag('detectEB3MS').displayAll(EB3Channel,processRender, ...
            'detections',det, ...
            'renderingMethod','FilledCircle','radius',2,'colormap',[0 255 0], ...
            'opacity',0.6,'detectionBorderDisplay',0,'show',false);
mappedCone=MD.searchProcessTag('trackingKT').displayAll(KTChannel,mappedCone,'tracks',dynROI.tracks(2),...
            'useDetection',true,'colormap',[255 0 0],'radius',5,'linewidth',3, ...
            'renderingMethod','Circle','show',false);

% Building array
anim=printProcMIPArrayCellBased({roiLocationAnim,mappedCone},'/tmp/','forceHeight',true);
% Display
anim.imdisp();
% Save as a video
anim.saveVideo([analysisRoot filesep 'paperFiberROI'  filesep 'ROI-and-cone-movie.avi']);
end 

%% Render Fiber DynROI with a dragon tail.          
if(true)
% Loading mip of the scene
processRender=MD.searchProcessTag('renderMIP');

% Define colormap 
cm=(255*summer(16));

% Display dynROI with dragon tail 
projAnim=MD.searchProcessTag('paperFiber').displayAll(processRender,...
    'dragonTail',80,'dragonTailGap',5,'ROILabel','time', ... 
    'linewidth',2,'processFrames',[], ... 
    'show',true,'colormap',cm,'colorTail',true,'showROIOnly',false);

% Build and save animation. 
anim=ProjAnimation(projAnim{1},'ortho');
anim.saveVideo([analysisRoot filesep 'paperFiberROI'  filesep 'movie.avi']);
anim.buildImAnimation([analysisRoot filesep 'paperFiberROI' filesep 'png' filesep 'movie-' filesep 'spindlePlanROITail-movie-%04d.png']);
end

%% Cumulative distibution
if(true)
% Loading dynROI
dynROI=MD.searchProcessTag('paperFiber').loadChannelOutput();
dynROI=dynROI{1};

% Loading mip of the scene
processRender=MD.searchProcessTag('renderPaperFiber');
% Loading and map detection
det=Detections(MD.searchProcessTag('detectEB3MS').loadChannelOutput(EB3Channel));
det=dynROI.mapDetections(det);
cm=255*parula(256);
cm=linspaceNDim([0, 255 , 0],[255 255 0],256)';

% Display first part showing plus-ends directional bias 
mappedCone=MD.searchProcessTag('detectEB3MS').displayAll(EB3Channel,processRender, ...
            'detections',det,'cumulative',true,'detLabel','time', ...
            'processFrames',53:62,'minMaxLabel',[53 102],'colormap',cm, ...
             'renderingMethod','FilledCircle','radius',1.5,'colormap',cm, ...
             'opacity',0.8,'detectionBorderDisplay',0,'show',false);
mappedCone=MD.searchProcessTag('trackingKT').displayAll(KTChannel,mappedCone,'tracks',dynROI.tracks(2),...
            'useDetection',true,'colormap',[255 0 0],'radius',5,'linewidth',3,'renderingMethod','Circle','show',false);
ProjAnimation(mappedCone{1},'ZY').buildImAnimation(fullfile(analysisRoot,'paperFiberROI','cumul','53-62-%04d.png'));

% Display second part showing the branching mechanism
mappedCone=MD.searchProcessTag('detectEB3MS').displayAll(EB3Channel,processRender, ...
            'detections',det,'cumulative',true, ...
            'processFrames',63:72,'minMaxLabel',[53 102],'colormap',cm, ...
             'renderingMethod','FilledCircle','radius',1.5,'detLabel','time','colormap',cm, ...
             'opacity',0.8,'detectionBorderDisplay',0,'show',false);
mappedCone=MD.searchProcessTag('trackingKT').displayAll(KTChannel,mappedCone,'tracks',dynROI.tracks(2),...
            'useDetection',true,'colormap',[255 0 0],'radius',5,'linewidth',3,'renderingMethod','Circle','show',false);
ProjAnimation(mappedCone{1},'ZY').buildImAnimation(fullfile(analysisRoot,'paperFiberROI','cumul','63-72-%04d.png'));

% Display the last part showing the capture and large plus-end recruitment
mappedCone=MD.searchProcessTag('detectEB3MS').displayAll(EB3Channel,processRender, ...
            'detections',det,'cumulative',true, ...
            'processFrames',93:102,'minMaxLabel',[53 102],'colormap',cm, ...
             'renderingMethod','FilledCircle','radius',1.5,'detLabel','time','colormap',cm, ...
             'opacity',0.8,'detectionBorderDisplay',0,'show',false);
mappedCone=MD.searchProcessTag('trackingKT').displayAll(KTChannel,mappedCone,'tracks',dynROI.tracks(2),...
            'useDetection',true,'colormap',[255 0 0],'radius',5,'linewidth',3,'renderingMethod','Circle','show',false);
ProjAnimation(mappedCone{1},'ZY').buildImAnimation(fullfile(analysisRoot,'paperFiberROI','cumul','93-102-%04d.png'));
end 


%% Spatiotemporal distribution of plus-ends location to illustrate capture:
if(true)
% loading dynROI 
dynROI=MD.searchProcessTag('paperFiber').loadChannelOutput();
dynROI=dynROI{1};

% Loading and Map detection in the dynROI 
det=Detections(MD.searchProcessTag('detectEB3MS').loadChannelOutput(EB3Channel));
mappedPos=dynROI.mapDetections(det);
mappedPos=dynROI.getDefaultRef().applyBase(mappedPos);

% Binning used for plotting
binsDistance=20:5:100;
binsTime=0:5:150;

% recovering the KT track and projecting it. 
KTTrack=dynROI.getDefaultRef().applyBase(dynROI.tracks(2));

% Plot heat map of plus-end count vs distance and time
plotDistanceVsTimeCountMap(mappedPos,KTTrack,binsDistance,binsTime,0,1);
end


