function idx = getMergeIdx(obj,msM)
%getMergeIdx get the linear index of 
    if(nargin < 2)
        msM = obj.getMergeSplitMatrix;
    end
    mergeM = msM(msM(:,2) == 2,:);
    idx = sub2ind([obj.totalSegments obj.numTimePoints],mergeM(:,3:4),[mergeM(:,1)-1 mergeM(:,1)])';
end
