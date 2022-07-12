function idx = getSplitIdx(obj,msM)
    if(nargin < 2)
        msM = obj.getMergeSplitMatrix;
    end
    splitM = msM(msM(:,2) == 1,:);
    idx = sub2ind([obj.totalSegments obj.numTimePoints],splitM(:,3:4),[splitM(:,1) splitM(:,1)-1])';
end
