% This script demonstrates the various approaches available to visualize and create movies
% of tracking results. Example dataset describes endocytic pits in a moving cells. It is
% downloaded automatically. The following features are demonstrated:
%
% - DISPLAY DEMO 1 Detection & Tracking rendering on orthogonal MIP with various rendering
%   styles, exporting to gif, avi and pngs. 
% - DISPLAY DEMO 2 Exporting detection and trajectory for rendering in the Amira software. 
% - DISPLAY DEMO 3 Fast volume rendering through sparse point cloud representation.
% - Saving and Sideloading detection and tracking results

% Note: for the sake of clarity and modularity, the parameters associated to each process
% are defined just above the execution of each process.

close all; clear all;

outputFolder=fullfile(tempdir,'testAvancedViz');   % Output folder for the raw data

loadPreviousTracks=false;             % Load trajectories if they have been computed
backupMoviedataFile=fullfile(outputFolder,'backupMovieData.mat'); % Movies and Tracks
                                                                  % metadata

if(loadPreviousTracks &  isfile(backupMoviedataFile))
    % Load detection and tracking if they have been previously computed. 
    MD=MovieData.loadMatFile(backupMoviedataFile);
else 
    
 %% Download and decompress movie 
datasetUrl='https://amubox.univ-amu.fr/s/F45XmaJe5apbF6K/download/endocyticPits_cropped.zip';
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
processTrack.setPara(funParams);
paramsIn.ChannelIndex=1;
paramsIn.DetProcessIndex=processDetection.getIndex(); % Detection used for tracking
processTrack.run(paramsIn);
MD.save();

%% Backup copy of the metadata file at the root
movieDataPath=[MD.getPath() filesep MD.getFilename()];
copyfile(movieDataPath,backupMoviedataFile);
end 

%% Rendering the full Movie
processRenderFullMIP=RenderDynROI(MD);
processRenderFullMIP.setProcessTag('fullMIP');
MD.addProcess(processRenderFullMIP);
funParams=processRenderFullMIP.getParameters();
funParams.mipSize=800;                  % Size of the resulting render
funParams.gamma=0.7;                    % Gamma correction
funParams.contrast=[0.1 1];             % Contrast adjustement
funParams.normalize=false;              % Disabling per-frame constrast adjustement
processRenderFullMIP.setPara(funParams);
processRenderFullMIP.run();
MD.save();

%% Process 
renderingProcess=MD.searchProcessTag('fullMIP');
detectionProcess=MD.searchProcessTag('detection');
trackingProcess=MD.searchProcessTag('tracking');

%% DISPLAY DEMO 1: Parallized rendering for orthogonal mips

%% MIP Render
render=renderingProcess.displayAll('show',false);

%% Display detections as filled circle with transparency
detectionDisplayParameters1={'colormap',256*parula(256), ...
                             'renderingMethod','FilledCircle', ...
                             'radius',2, ...
                             'opacity',0.7, ...
                             'show',true};
animDetect1=detectionProcess.displayAll(1,render,detectionDisplayParameters1{:});


%% Display detections with circle 
detectionDisplayParameters2={'colormap',[255 0 0], ...
                             'renderingMethod','Circle', ... 
                             'radius',2, ...
                             'show',false};
animDetect2= detectionProcess.displayAll(1,render,detectionDisplayParameters2{:});

%% Display tracks on top of detection with dragon tail, colored according to instantaneous speed
trackDisplayParameters = {'trackLabel','lifetime', ...
                          'colormap',256*parula(256), ...
                          'dragonTail',20, ...
                          'linewidth',2, ...
                          'show',false};
animTracks1 = trackingProcess.displayAll(1,render,trackDisplayParameters{:}); 

%% Display tracks as detection
trackDisplayParameters = {'useDetection',true', ...
                           detectionDisplayParameters2{:}};
animTracks2 = trackingProcess.displayAll(1,animTracks1,trackDisplayParameters{:});

%% Assemble ROI location and details in a single movie
movieArray=[{[render;animDetect2]}, animTracks2];                 % Building a montage through array. 
animArray=printProcMIPArrayCellBased(movieArray,'maxWidth',1920,'maxHeigth',1080,'forceHeight',true);
animArray.saveVideo(fullfile(MD.getPath(),'rendering_export','detailROI.avi'),'frameRate',10);
animArray.saveGif(fullfile(MD.getPath(),'rendering_export','detailROI.gif'),'frameRate',10);
animArray.printAnimation(fullfile(MD.getPath(),'rendering_export', 'detailROI','detailROI.png'));
animArray.imdisp();
 
%% DISPLAY DEMO 2: Exporting Amira file
% Write detection only
detections=detectionProcess.loadChannelOutput(1);
amiraWriteMovieInfo(fullfile(MD.getPath(), 'amira','amiraDetection','amiraDetection.am'),detections);

% Write tracks with custom labelling for display
tracks=TracksHandle(trackingProcess.loadChannelOutput(1)); 
amiraWriteTracks(fullfile(MD.getPath(), 'amira','amiraTracks','amiraTracks.am'),tracks); 

%% DISPLAY DEMO 3: Fast detection mask rendering as point clouds

% Loading the detection mask
detectionMasks=detectionProcess.loadChannelOutput(1,'output','labelSegPos'); 

% Display time points 10
detectionMasks(10).scatterPlot();

% Display every mask from time point 1 to  15
detectionMasks(1:15).scatterPlot();

% Dynamic display
v=PCViewer();
v.addDetection(detectionMasks,255*parula(256));
v.dynScatterPlot();

 