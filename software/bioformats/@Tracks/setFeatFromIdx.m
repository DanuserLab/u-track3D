function [ obj ] = setFeatFromIdx( obj, movieInfo )
%setFeatFromIdx Set features from idx of coordinates stored in movieInfo

    tracksCoordAmpCG = getFeatFromIdx(obj,movieInfo);
    [obj.tracksCoordAmpCG] = deal(tracksCoordAmpCG{:});

end

