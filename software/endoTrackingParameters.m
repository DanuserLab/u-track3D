function [funParams,verbose]=endoTrackingParameters(defFunParams)

%% general gap closing parameters
%
% Copyright (C) 2022, Danuser Lab - UTSouthwestern 
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
gapCloseParam.timeWindow = 3; % Maximum allowed time gap (in frames) between a track
                              % segment end and a track segment start that allows linking
                              % them.
gapCloseParam.mergeSplit = 0; % 1 if merging and splitting are to be considered, 2 if only
                              % merging is to be considered, 3 if only splitting is to be
                              % considered, 0 if no merging or splitting are to be
                              % considered.
gapCloseParam.minTrackLen = 2; % Minimum length of track segments from linking to be used
                               % in gap closing.

%optional input:
gapCloseParam.diagnostics = 0; % 1 to plot a histogram of gap lengths in the end; 0 or
                               % empty otherwise.

%% cost matrix for frame-to-frame linking

%function name
costMatrices(1).funcName = 'costMatRandomDirectedSwitchingMotionLink';

%parameters
parameters.linearMotion = 0;    % Use linear motion Kalman filter.

parameters.minSearchRadius = 2; % Minimum allowed search radius. The search radius is
                                % estimated for each object and each time point. If it
                                % happens to be smaller than this minimum, it will be
                                % increased to the minimum.
parameters.maxSearchRadius = 5; % Maximum allowed search radius. Again, if a feature's
                                % calculated search radius is larger than this maximum, it
                                % will be reduced to this maximum.
parameters.brownStdMult = 3;    % Multiplication factor to calculate search radius from
                                % standard deviation.

parameters.useLocalDensity = 1; % 1 if you want to expand the search radius of isolated
                                % features in the linking (initial tracking) step.
parameters.nnWindow = gapCloseParam.timeWindow; % Number of frames before the current one
                                                % where you want to look to see a
                                                % feature's nearest neighbor in order to
                                                % decide how isolated it is (in the
                                                % initial linking step).

parameters.kalmanInitParam.searchRadiusFirstIteration = 3; % Kalman filter initialization parameters.

%optional input
parameters.diagnostics = []; % If you want to plot the histogram of linking distances up
                             % to certain frames, indicate their numbers; 0 or empty
                             % otherwise. Does not work for the first or last frame of a
                             % movie.

costMatrices(1).parameters = parameters;
clear parameters

%% cost matrix for gap closing

%function name
costMatrices(2).funcName = 'costMatRandomDirectedSwitchingMotionCloseGaps';

%parameters needed all the time
parameters.linearMotion = 0; % Use linear motion Kalman filter.

parameters.minSearchRadius = 1; % Minimum allowed search radius.
parameters.maxSearchRadius = 3; % Maximum allowed search radius.
parameters.brownStdMult = 3*ones(gapCloseParam.timeWindow,1); % Multiplication factor to
                                                              % calculate Brownian search
                                                              % radius from standard
                                                              % deviation.

% Power for scaling the Brownian search radius with time, before and after timeReachConfB
% (next parameter). Note that it is only the gap value which is powered, then we have
% brownStdMult*powered_gap*sig*sqrt(dim)
parameters.brownScaling = [0.25 0.01];
parameters.timeReachConfB = gapCloseParam.timeWindow; % Before timeReachConfB, the search
                                                      % radius grows with time with the
                                                      % power in brownScaling(1); after
                                                      % timeReachConfB it grows with the
                                                      % power in brownScaling(2).

parameters.ampRatioLimit = [0.7 4]; % For merging and splitting. Minimum and maximum
                                    % ratios between the intensity of a feature after
                                    % merging/before splitting and the sum of the
                                    % intensities of the 2 features that merge/split.

parameters.lenForClassify = 5; % Minimum track segment length to classify it as linear or
                               % random.

parameters.useLocalDensity = 0; % 1 if you want to expand the search radius of isolated
                                % features in the gap closing and merging/splitting step.
parameters.nnWindow = gapCloseParam.timeWindow; % Number of frames before/after the
                                                % current one where you want to look for a
                                                % track's nearest neighbor at its
                                                % end/start (in the gap closing step).

parameters.linStdMult = 1*ones(gapCloseParam.timeWindow,1); % Multiplication factor to
                                                            % calculate linear search
                                                            % radius from standard
                                                            % deviation.

parameters.linScaling = [0.25 0.01]; % Power for scaling the linear search radius with
                                     % time (similar to brownScaling).
% parameters.timeReachConfL = 4; % Similar to timeReachConfB, but for the linear part of
% the motion.
parameters.timeReachConfL = gapCloseParam.timeWindow; % Similar to timeReachConfB, but for
                                                      % the linear part of the motion.

parameters.maxAngleVV = 30; % Maximum angle between the directions of motion of two tracks
                            % that allows linking them (and thus closing a gap). Think of
                            % it as the equivalent of a searchRadius but for angles.

%optional; if not input, 1 will be used (i.e. no penalty)
parameters.gapPenalty = 1.5; % Penalty for increasing temporary disappearance time
                             % (disappearing for n frames gets a penalty of gapPenalty^n).

%optional; to calculate MS search radius
%if not input, MS search radius will be the same as gap closing search radius
parameters.resLimit = []; %resolution limit, which is generally equal to 3 * point spread function sigma.

costMatrices(2).parameters = parameters;
clear parameters

%% Kalman filter function names

kalmanFunctions.reserveMem  = 'kalmanResMemLM';
kalmanFunctions.initialize  = 'kalmanInitLinearMotion';
kalmanFunctions.calcGain    = 'kalmanGainLinearMotion';
kalmanFunctions.timeReverse = 'kalmanReverseLinearMotion';

%% additional input

%verbose state
verbose = 1;

probDim=3;

% Updating default parameters.
newFunParams.gapCloseParam=gapCloseParam;
newFunParams.costMatrices=costMatrices;
newFunParams.kalmanFunctions=kalmanFunctions;
newFunParams.probDim=probDim;
newFunParams.verbose=verbose;

F=fields(newFunParams); 
for fIdx=1:length(F) defFunParams.(F{fIdx})=newFunParams.(F{fIdx}); end;
funParams=defFunParams;