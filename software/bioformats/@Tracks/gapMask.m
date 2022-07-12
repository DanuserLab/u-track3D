function [ varargout ] = gapMask( obj )
%gapMask creates a binary mask of where gaps are in the compound track
    if(isscalar(obj))
        mask = obj.aliveMask;
        mask = mask & obj.tracksFeatIndxCG == 0;
        varargout{1} = mask;
    else
        varargout = cellfun(@gapMask,num2cell(obj(1:nargout)),'UniformOutput',false);
    end

end

