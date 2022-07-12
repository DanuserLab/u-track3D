function [ out ] = textGraph( obj )
%textGraph Summary of this function goes here
%   Detailed explanation goes here
    assert(isscalar(obj));
    numLabels = num2str(mod(obj.startFrame : obj.endFrame,10),'%d');
    out = char(zeros(size(obj.tracksFeatIndxCG)));
    out(obj.tracksFeatIndxCG ~= 0) = '.';
    out(gapMask(obj)) = '-';
    out(1:2:end*2,:) = out;
    out(2:2:end,:) = ' ';
    out = [numLabels ; out ];
end

