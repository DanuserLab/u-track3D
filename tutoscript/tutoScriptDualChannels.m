% This script demonstrates detection, tracking and building dynROI accross multiple
% channels. The example dataset describes a cell during early stages of mitosis, it is
% downloaded automatically. The following features are demonstrated:
%
% - Detection and tracking with scale selectivity on the EB3 Channels  (channel 1)
% - Detection and tracking on the kinetochore channel (channel 2)
% - Sideloading previous detection and tracking results with process parameters
% - Building a dynROI between two trajectories measured on two different channels. 
% - Rendering 
%
% Note: for the sake of clarity and modularity, the parameters associated to each process
% are defined just above the execution of each process.

clear all;

outputFolder=fullfile(tempdir,'testDualChannel');   % Output folder for the raw data

MTChannel=1;
KTChannel=2;

%% Download and decompress movie 
datasetUrl='https://zenodo.org/record/6881276/files/prometaphase.zip'; 
dataFolder=retrieveRemoteDataset(datasetUrl,outputFolder);
analysisRoot=[dataFolder '_analysis'];  %  Analysis results are stored here. 

%% Building a movie with metadata
c1 = Channel(fullfile(dataFolder,'ch1'));
c2 = Channel(fullfile(dataFolder,'ch2'));
MD = MovieData([c1,c2],analysisRoot);   % Building movie from two channels
MD.setPath(analysisRoot);               % Folder where process output is saved.
MD.setFilename('movieData.mat');        % Filename where metadata on images and
                                        % processes are saved
MD.pixelSize_ = 100;                    % Axial Pixel Size
MD.pixelSizeZ_ = 216;                   % Lateral Pixel Size
md.timeInterval_ = 1;                   % Time interval
MD.sanityCheck;
MD.save();

%% Detection parameterization and processing for centrosome
processDetection=PointSourceDetectionProcess3D(MD);
processDetection.setProcessTag('centrosomeDetection'); % Naming the process for later reference.
MD.addProcess(processDetection);             % Adding the process to the pipeline. 
funParams = processDetection.getParameters();
funParams.scales=5; % object scale (can be multiple)
funParams.alpha=0.005; % p-value for statistical test (the lower the stricter)
                       % funParams.frameRange=[1 10];
funParams.OutputDirectory=[MD.outputDirectory_ filesep processDetection.getProcessTag()];
processDetection.setPara(funParams);
paramsIn.ChannelIndex=MTChannel;
processDetection.run(paramsIn);    
MD.save();

%% Tracking parameterization and processing 
processTrack=TrackingProcess(MD);
processTrack.setProcessTag('centrosomeTracking');
MD.addProcess(processTrack);    
[gapCloseParam,costMatrices,kalmanFunctions,probDim,verbose]=poleTrackingParamDemo();
funParams=processTrack.getParameters();
funParams.gapCloseParam=gapCloseParam;
funParams.costMatrices=costMatrices;
funParams.kalmanFunctions=kalmanFunctions;
funParams.probDim=probDim;
funParams.OutputDirectory=[MD.outputDirectory_ filesep processTrack.getProcessTag()];
processTrack.setPara(funParams);
paramsIn.ChannelIndex=MTChannel;
paramsIn.DetProcessIndex=MD.searchProcessTag('centrosomeDetection').getIndex();
processTrack.run(paramsIn);
MD.save();

%% Detection parameterization and processing for Kinetochores
processDetection=PointSourceDetectionProcess3D(MD);
processDetection.setProcessTag('KTDetection'); % Naming the process for later reference.
MD.addProcess(processDetection);             % Adding the process to the pipeline. 
funParams = processDetection.getParameters();
funParams.scales=[1.5 1.75 2.0]; % object scale (can be multiple)
funParams.alpha=0.005; % p-value for statistical test (the lower the stricter)
                       % funParams.frameRange=[1 10];
funParams.RemoveRedundant=true;
funParams.RedundancyRadius=3;
funParams.OutputDirectory=[MD.outputDirectory_ filesep processDetection.getProcessTag()];
processDetection.setPara(funParams);
paramsIn.ChannelIndex=KTChannel;
processDetection.run(paramsIn);    
MD.save();

%% Tracking parameterization and processing 
processTrack=TrackingProcess(MD);
processTrack.setProcessTag('KTTracking');
MD.addProcess(processTrack);    
funParams=processTrack.getParameters();
[gapCloseParam,costMatrices,kalmanFunctions,probDim,verbose]=kinTrackingParamV2();
funParams.gapCloseParam=gapCloseParam;
funParams.costMatrices=costMatrices;
funParams.kalmanFunctions=kalmanFunctions;
funParams.probDim=probDim;
funParams.OutputDirectory=[MD.outputDirectory_ filesep processTrack.getProcessTag()];
processTrack.setPara(funParams);
paramsIn.ChannelIndex=KTChannel;
paramsIn.DetProcessIndex=MD.searchProcessTag('KTDetection').getIndex();
processTrack.run(paramsIn);
MD.save();

%% Build KT Fiber ROI 
process=BuilDynROI(MD);
process.setProcessTag('fiberROI');
MD.addProcess(process)
funParams=process.getParameters();
KTTracks=TracksHandle(MD.searchProcessTag('KTTracking').loadChannelOutput(KTChannel));
centTracks=TracksHandle(MD.searchProcessTag('centrosomeTracking').loadChannelOutput(MTChannel));
selectedCentrosome=centTracks(1);
selectedKT=KTTracks(28);
% Defining a cone with Apex <selectedCentrosome> and a base centered on <selectedKT>
funParams.roiType='cone';               
funParams.trackObjects={selectedCentrosome;selectedKT};
funParams.angle=pi/16; 
process.setPara(funParams);
process.run();
MD.save();

%% Rendering the full Movie
processRenderFullMIP=RenderDynROI(MD);
processRenderFullMIP.setProcessTag('fullMIP');
MD.addProcess(processRenderFullMIP);
funParams=processRenderFullMIP.getParameters();
funParams.mipSize=800;                  % Size of the resulting render
funParams.processChannel=[1 2];         % Rendering both channels
funParams.gamma={0.5 1.2};              % Gamma for channel 1 and
funParams.contrast={[0 1],[0.5 1]};     % Contrast limit for channel 1 and 2
funParams.channelRender='grayRedMix2';  % Channel mixing mode
funParams.normalize=false;              % Disabling per-frame constrast adjustement
processRenderFullMIP.setPara(funParams);
processRenderFullMIP.run();
MD.save();

%% Rendering the DynROI 
processRenderDynROI=RenderDynROI(MD);
processRenderDynROI.setProcessTag('renderDynROI');
MD.addProcess(processRenderDynROI);
funParams=processRenderDynROI.getParameters();
funParams.processBuildDynROI=MD.searchProcessTag('fiberROI'); % ROI to render.
funParams.processChannel=[1 2];        % Rendering both channels                  
funParams.gamma={0.5 1.2};             % Gamma for channel 1 and                  
funParams.contrast={[0 0.99],[0.1 1]}; % Contrast limit for channel 1 and 2       
funParams.channelRender='grayRedMix2'; % Channel mixing mode                      
funParams.Zup=true;                    % Render the XZ and YZ projections with the Z upright.
                                       % (top left: XY, bottom left: ZY, bottom right: ZX) 
processRenderDynROI.setPara(funParams);
processRenderDynROI.run();
MD.save();

%% Rendering
% Display the dynROI on the movie
fullRenderingProcess=MD.searchProcessTag('fullMIP');
dynROIProcess=MD.searchProcessTag('fiberROI');
dynROIDisplayParameters = {'linewidth',4, ...
                           'colormap',[204, 255, 102], ...
                           'show',false}; 
animDynROI=dynROIProcess.displayAll(fullRenderingProcess, dynROIDisplayParameters{:});

% Display KT tracks on the dynROI
dynROIRenderingProcess=MD.searchProcessTag('renderDynROI');
KTTrackingProcess=MD.searchProcessTag('KTTracking');
trackDisplayParameters = {'trackLabel','meanSpeed', ...
                          'minMaxLabel',[1 2], ...
                          'colormap',256*parula(256), ...
                          'dragonTail',20, ...
                          'linewidth',4, ...
                          'show',false};
animTracks = KTTrackingProcess.displayAll(KTChannel,dynROIRenderingProcess,trackDisplayParameters{:}); 

% Build and export the movie 
movieArray={animDynROI,animTracks};
animArray=printProcMIPArrayCellBased(movieArray,'maxWidth',1920,'maxHeigth',1080,'forceHeight',true);
animArray.saveVideo(fullfile(MD.getPath(),'rendering_export','detailROI.avi'),'frameRate',10);
animArray.imdisp();

