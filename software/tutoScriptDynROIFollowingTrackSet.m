% This script demonstrates a workflow for detection, tracking and the definition of
% dynROIs that fit and follows all the detected trajectories.  The example
% dataset describes endocytic pits in a moving cells. It is downloaded automatically. The
% following features are demonstrated:
%
% - Detection
% - Tracking
% - Building dynROI automatically around a set of tracks
% - Rendering and exporting a visualization of tracking results in the dynROI.
%
% Copyright (C) 2024, Danuser Lab - UTSouthwestern 
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

% Note: for the sake of clarity and modularity, the parameters associated to each process
% are defined just above the execution of each process.

clear all;

outputFolder=fullfile(tempdir,'testTrackSetROI');   % Output folder for raw data 


%% Download and decompress movie 
datasetUrl='https://zenodo.org/record/6881276/files/endocyticPits_cropped.zip'
dataFolder=retrieveRemoteDataset(datasetUrl,outputFolder);
analysisRoot=[dataFolder '_analysis'];  %  Analysis results are stored here. 

%% Building a movie with metadata
tifFolder=fullfile(dataFolder,'ch1'); 
c1 = Channel(tifFolder);
MD = MovieData(c1,analysisRoot); 
MD.setPath(analysisRoot);               % Folder where process output is saved.
MD.setFilename('movieData.mat');        % Filename where metadata on images and
                                        % processes are saved
MD.pixelSize_ = 0.1040;                 % Axial Pixel Size
MD.pixelSizeZ_ = 0.3500;                % Lateral Pixel Size
md.timeInterval_ = 1;                   % Time interval
MD.sanityCheck;
MD.save();

%% Detection parameterization and processing 
processDetection=PointSourceDetectionProcess3D(MD);
processDetection.setProcessTag('detection'); % Naming the process for later reference.
MD.addProcess(processDetection);             % Adding the process to the pipeline. 
funParams = processDetection.getParameters();
funParams.scales=1.25:0.5:2.5;          % Range of object scale of interest in pixel.
funParams.alpha=0.001;                  % p-value used for sensitivity
funParams.OutputDirectory=[MD.outputDirectory_ filesep processDetection.getProcessTag()];
processDetection.setPara(funParams);
paramsIn.ChannelIndex=1;                % Channel used for detection
processDetection.run(paramsIn);    
MD.save();

%% Tracking parameterization and processing 
processTrack=TrackingProcess(MD);
processTrack.setProcessTag('tracking');
MD.addProcess(processTrack);    
funParams=processTrack.getParameters();
funParams=endoTrackingParameters(funParams); % Editing essential tracking parameters
                                             % funParams.gapCloseParam.minTrackLen= 5;      % Addition lifetime threshold for trajectories
processTrack.setPara(funParams);
paramsIn.ChannelIndex=1;
paramsIn.DetProcessIndex=MD.searchProcessTag('detection').getIndex(); % Detection used
                                                                      % for tracking
processTrack.run(paramsIn);
MD.save();

%% Rendering the full Movie
processRenderFullMIP=RenderDynROI(MD);
processRenderFullMIP.setProcessTag('fullMIP');
MD.addProcess(processRenderFullMIP);
funParams=processRenderFullMIP.getParameters();
funParams.mipSize=800;                  % Size of the resulting render
processRenderFullMIP.setPara(funParams);
processRenderFullMIP.run();
MD.save();

%% Building DynROI 
processBuildDynROI=BuilDynROI(MD);
processBuildDynROI.setProcessTag('trackSetROI');
MD.addProcess(processBuildDynROI);
funParams=processBuildDynROI.getParameters();
funParams.trackProcess=processTrack;
funParams.roiType='trackSetROI'; % Building the DynROI around the set of trajectories
funParams.fringe=10;             % Additional margin outside the box around trajectory
                                 % set. 
processBuildDynROI.setPara(funParams);
processBuildDynROI.run();
MD.save();

%% Rendering the DynROI 
processRenderDynROI=RenderDynROI(MD);
processRenderDynROI.setProcessTag('renderTracksROI');
MD.addProcess(processRenderDynROI);
funParams=processRenderDynROI.getParameters();
funParams.processBuildDynROI=MD.searchProcessTag('trackSetROI'); % ROI to render.
funParams.gamma=0.7;                    % Gamma correction
funParams.contrast=[0.3 1];             % Constrast adjustement
processRenderDynROI.setPara(funParams);
processRenderDynROI.run();
MD.save();

%% Rendering and exporting a visualization of tracking results
% Display tracks on the rendering of the full volume
trackDisplayParameters = {'trackLabel','lifetime', ...
                          'colormap',256*parula(256), ...
                          'dragonTail',20, ...
                          'linewidth',4, ...
                          'show',false};
animTracks=processTrack.displayAll(1,MD.searchProcessTag('fullMIP'), trackDisplayParameters{:});

% Overlay ROI locations on top of the track rendering 
animDynROI=processBuildDynROI.displayAll(animTracks, ... 
                                         'linewidth',3, ...
                                         'show',false);
% Load ROI rendering
renderROI=processRenderDynROI.displayAll('show',false);

% Display tracks on the ROI
trackDisplayParameters = {'trackLabel','lifetime', ...
                          'dragonTail',20,...
                          'colormap',256*parula(256), ...
                          'linewidth',2, ...
                          'show',false, ...
                          'processFrames',1:MD.nFrames_};
animTracksROI = processTrack.displayAll(1,renderROI,trackDisplayParameters{:});

% Display tracks as detections on the ROI 
trackDisplayParameters={'colormap',[255 240 100], ...
                            'renderingMethod','FilledCircle', ...
                            'useDetection',true, ...
                            'radius',1.1, ...
                            'opacity',1, ... 
                            'show',false, ...
                            'processFrames',1:MD.nFrames_};
animTracksROI = processTrack.displayAll(1,animTracksROI,trackDisplayParameters{:});

% Montage of ROI location and details in a single movie
movieArray={animDynROI,animTracksROI};
animArray=printProcMIPArrayCellBased(movieArray,'maxWidth',1920,'maxHeigth',1080,'forceHeight',true);

% Movie and image exp
animArray.saveVideo(fullfile(MD.getPath(),'rendering_export','detailROI.avi'),'frameRate',10);
animArray.saveGif(fullfile(MD.getPath(),'rendering_export','detailROI.gif'),'frameRate',10);
animArray.printAnimation(fullfile(MD.getPath(),'rendering_export', 'detailROI','detailROI.png'));

% Dynamic display (use arrow to scroll through time)
animArray.imdisp();


