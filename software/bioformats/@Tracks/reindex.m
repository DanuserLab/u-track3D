function [ oldIdx ] = reindex( obj, idx )
%reindex Reindex array elements by their current array position or as
%specified
%
% INPUT
% obj - Tracks object array
% idx - (optional) new indices
%
% OUTPUT
% oldIdx - Previous indices or empty if not available

if(nargout > 0)
    oldIdx = [obj.index];
end

if(nargin < 2)
    idx = 1:numel(obj);
end

idx = num2cell(idx);
[obj.index] = idx{:};


end

