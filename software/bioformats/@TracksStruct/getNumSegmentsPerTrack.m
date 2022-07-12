function [ N ] = getNumSegmentsPerTrack( obj , idx)
%numSegments gets the number of segments within an array of compound tracks
if(nargin < 2)
    tracks = obj;
else
    tracks = obj(idx);
end

N = cellfun('size',{tracks.tracksCoordAmpCG3D},1);

end

