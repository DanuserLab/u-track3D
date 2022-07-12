function msM = getMergeSplitMatrix(obj)
% getMergeSplitMatrix returns rows from the seqOfEvents matrix describing
% merges and splits
    seqM = obj.getSeqOfEventsMatrix;
    msM = seqM(~isnan(seqM(:,4)),:);
end
