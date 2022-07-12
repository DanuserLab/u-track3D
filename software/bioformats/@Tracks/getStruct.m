function s = getStruct(obj)
    s(numel(obj)) = struct('tracksFeatIndxCG',[],'tracksCoordAmpCG',[],'seqOfEvents',[]);
    [s.tracksFeatIndxCG] = deal(obj.tracksFeatIndxCG);
    [s.tracksCoordAmpCG] = deal(obj.tracksCoordAmpCG);
    [s.seqOfEvents] = deal(obj.seqOfEvents);
end
