% This script demonstrates a  workflow for detection, tracking and the
% estimation of trackability on static ROI selected randomly.  The
% example dataset describes endocytic pits in a moving cells. It is downloaded
% automatically. The following features are demonstrated:
%
% - Detection
% - Tracking
% - Selecting a ROI of interest manually
% - Rendering and exporting a visualization of tracking and trackability results
% - Plotting trackability scores for the ROI

% Note: for the sake of clarity and modularity, the parameters associated to each process
% are defined just above the execution of each process.

close all; clear all;

outputFolder=fullfile(tempdir,'testTrackability');   % Output folder for raw data 

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
funParams.algorithmType= {'multiscaleDetectionDebug'};
funParams.version='useMaxResponse';
funParams.scales=1.25:0.5:2.5;          % Range of object scale of interest in pixel.
funParams.alpha=0.001;                  % p-value used for sensitivity
funParams.OutputDirectory=[MD.outputDirectory_ filesep processDetection.getProcessTag()];
processDetection.setPara(funParams);
paramsIn.ChannelIndex=1;                % Channel used for detection
processDetection.run(paramsIn);    

%% Tracking parameterization and processing 
processTrack=TrackingProcess(MD);
processTrack.setProcessTag('tracking');
MD.addProcess(processTrack);    
funParams=processTrack.getParameters();
funParams=endoTrackingParameters(funParams); % Editing essential tracking parameters
processTrack.setPara(funParams);
paramsIn.ChannelIndex=1;
paramsIn.DetProcessIndex=MD.searchProcessTag('detection').getIndex(); % Detection used
                                                                      % for tracking
processTrack.run(paramsIn);

%% Rendering the full Movie
processRenderFullMIP=RenderDynROI(MD);
processRenderFullMIP.setProcessTag('fullMIP');
MD.addProcess(processRenderFullMIP);
funParams=processRenderFullMIP.getParameters();
funParams.mipSize=800;                  % Size of the resulting render
processRenderFullMIP.setPara(funParams);
processRenderFullMIP.run();
MD.save();

%% Building random DynROI 
processBuildDynROI=BuilDynROI(MD);
processBuildDynROI.setProcessTag('staticROI');
MD.addProcess(processBuildDynROI);
funParams=processBuildDynROI.getParameters();
funParams.roiType='randomSamplingStatic'; % DynROI around a randomly selected set of trajectories
funParams.trackProcess=MD.searchProcessTag('tracking'); % Trajectory used to build the ROI.
funParams.fringe=30;                      % Determine the size of the box around the trajectory
funParams.nSample=1;                      % Number of ROIs
processBuildDynROI.setPara(funParams);
processBuildDynROI.run();
MD.save();

%% Tracking in ROI with trackability estimation 
% Track in the dynROI, enabling trackability computations.
processTrack=TrackingProcess(MD);
processTrack.setProcessTag('trackInROI');
MD.addProcess(processTrack);  
funParams = processTrack.getParameters();
funParams=endoTrackingParameters(funParams);
funParams.processBuildDynROI=MD.searchProcessTag('staticROI');
funParams.EstimateTrackability=true;
funParams.OutputDirectory=[MD.outputDirectory_ filesep processTrack.getProcessTag()];
processTrack.setPara(funParams);
paramsIn.ChannelIndex=1;
paramsIn.DetProcessIndex=processDetection.getIndex();
processTrack.run(paramsIn);

%% Rendering the DynROI 
processRenderDynROI=RenderDynROI(MD);
processRenderDynROI.setProcessTag('renderTracksROI');
MD.addProcess(processRenderDynROI);
funParams=processRenderDynROI.getParameters();
funParams.processBuildDynROI=MD.searchProcessTag('staticROI'); % ROI to render.
funParams.contrast=[0.5 0.999];       % Constrast adjustement
processRenderDynROI.setPara(funParams);
processRenderDynROI.run();
MD.save();

%% Rendering and exporting a visualization of tracking results
% Display tracks on the rendering of the full volume

% Load full render
renderFull=MD.searchProcessTag('fullMIP');

% Overlay ROI location on top of the track rendering 
animDynROI=processBuildDynROI.displayAll(renderFull, ... 
                                         'linewidth',3, ...
                                         'show',false);
% load ROI rendering
renderROI=processRenderDynROI.displayAll('show',false);

% Display tracks on the ROI
trackDisplayParameters = {'trackLabel','ID', ...
                          'colormap',256*prism(256), ...
                          'linewidth',6, ...
                          'show',false, ...
                          'processFrames',1:MD.nFrames_};
animTracksROI = processTrack.displayAll(1,renderROI,trackDisplayParameters{:});

% Display tracks on the ROI
trackDisplayParameters = {'trackLabel','meanTrackability', ...
                          'minMaxLabel',[0.9 1], ...
                          'colormap',256*autumn(256), ...
                          'linewidth',6, ...
                          'show',false, ...
                          'processFrames',1:MD.nFrames_};
animTrackabilityROI = processTrack.displayAll(1,renderROI,trackDisplayParameters{:});

% Montage of ROI location and details in a single movie
movieArray={animDynROI,animTracksROI,animTrackabilityROI};
animArray=printProcMIPArrayCellBased(movieArray,'maxWidth',1920,'maxHeigth',1080,'forceHeight',true);

% Dynamic display (use arrow to scroll through time)
animArray.imdisp();

%% 
% movie and image exp
animArray.saveVideo(fullfile(MD.getPath(),'rendering_export','detailROI.avi'),'frameRate',10);
animArray.saveGif(fullfile(MD.getPath(),'rendering_export','detailROI.gif'),'frameRate',10);
animArray.printAnimation(fullfile(MD.getPath(),'rendering_export', 'detailROI','detailROI.png'));

%% Load and plot trackability measurements
tmp=load(MD.searchProcessTag('trackInROI').outFilePaths_{3,1}); 
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






