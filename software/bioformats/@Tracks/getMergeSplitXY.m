function [merge, split] = getMergeSplitXY(obj, matrix, msM)
    if(nargin < 2)
        matrix = obj.getMatrix;
    end
    if(nargin < 3)
        msM = obj.getMergeSplitMatrix;
    end
    X = matrix(:,1:8:end);
    Y = matrix(:,2:8:end);
    
    merge.idx = obj.getMergeIdx(msM);
    merge.X = X(merge.idx);
    merge.Y = Y(merge.idx);
    split.idx = obj.getSplitIdx(msM);
    split.X = X(split.idx);
    split.Y = Y(split.idx);
end
