function [ obj ] = mapFramesToTimepoints( obj, timepoints, frames )
%mapFramesToTime map frames to timepoints for the collection of Tracks
%
% INPUT
% timepoints to set the .t property to based on frames property .f
% (optional) frames to map to timepoints
%            default: min(.startFrame):max(.endFrame)
%
% OUTPUT
% the object

if(nargin < 3)
    frames = min([obj.startFrame]):max([obj.endFrame]);
end

assert(numel(timepoints) == numel(frames), ...
    'Tracks:mapFramesToTime:invalidNumberOfTimepoints', ...
    'The number of timepoints must match the number of frames');

framesMap(frames) = timepoints;

for ii=1:numel(obj)
    obj(ii).t = framesMap(obj(ii).f);
end


end

