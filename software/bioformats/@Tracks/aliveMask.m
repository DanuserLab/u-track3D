function [ varargout ] = aliveMask( obj )
%aliveMask creates a binary mask of when the segments in the compound track
%are active
    if(isscalar(obj))
        mask = false(size(obj.tracksFeatIndxCG));
        startFrames = obj.segmentStartFrame - obj.startFrame +1;
        endFrames = obj.segmentEndFrame - obj.startFrame +1;
        for i = 1:obj.numSegments
            mask(i,startFrames(i):endFrames(i)) = true;
        end
        varargout{1} = mask;
    else
        [varargout{1:nargout}] = cellfun(@aliveMask,num2cell(obj(1:nargout)),'UniformOutput',false);
    end

end

