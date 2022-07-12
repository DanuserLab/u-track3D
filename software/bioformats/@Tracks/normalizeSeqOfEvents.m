function [ obj ] = normalizeSeqOfEvents( obj )
%normalizeSeqOfEvents If seqOfEvents is empty, then create a default one.
    if(isa(obj,'TracksHandle'))
        % TracksHandle.seqOfEvents will always be populated
        % see TracksHandle.get.seqOfEvents
        return;
    end
    noSeqOfEvents = cellfun('isempty',{obj.seqOfEvents});
    tracksToFix = obj(noSeqOfEvents);
    if(isempty(tracksToFix))
        return;
    end
    seqOfEvents = cellfun( ...
        @(nF) [1 1 1 NaN; nF 2 1 NaN], ...
        {tracksToFix.numFrames}, ...
        'UniformOutput',false);
    [tracksToFix.seqOfEvents] = deal(seqOfEvents{:});
%     obj(noSeqOfEvents) = tracksToFix;
end

