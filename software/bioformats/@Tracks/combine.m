function [ combinedTrack ] = combine( obj )
%combine Combine multiple tracks together by uniquely indexing their
%segments

constructor = str2func(class(obj));

combinedTrack = constructor();
% The combined track needs to encompass all the frames of the source tracks
combinedTrack.startFrame = min([obj.startFrame]);
combinedTrack.endFrame = max([obj.endFrame]);

% Compute the new starting index of each of the segments
segCount = cumsum([obj.numSegments]);
numSegments = segCount(end);
segCount = [0 segCount(1:end)] + 1;

% Initialize to numSegments x numFrames
tracksFeatIndxCG = zeros(numSegments,combinedTrack.lifetime);
% Initialize to numSegments x 8 x numFrames
tracksCoordAmpCG3D = NaN(numSegments,8,combinedTrack.lifetime);
% Sequence of events is already handled in another function
seqOfEvents = obj.getSeqOfEventsMatrix;

for ii=1:numel(obj)
    segmentIdx = segCount(ii):segCount(ii+1)-1;
    frameIdx = obj(ii).f-combinedTrack.startFrame+1;
    
    % Assign feature index to correct position in combined matrix
    tracksFeatIndxCG( segmentIdx, frameIdx) ...
        = obj(ii).tracksFeatIndxCG;
    
    % Assign 
    tracksCoordAmpCG3D( segmentIdx, 1:8, frameIdx) ...
        = obj(ii).tracksCoordAmpCG3D;
    
    combinedTrack.t(frameIdx) = obj(ii).t;
end

combinedTrack.tracksFeatIndxCG = tracksFeatIndxCG;
combinedTrack.tracksCoordAmpCG3D = tracksCoordAmpCG3D;
combinedTrack.seqOfEvents = seqOfEvents(:,1:4);


end

