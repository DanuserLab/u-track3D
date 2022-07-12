function nT = numTimePoints(obj)
% get the number of time points available
        nT = max([obj.endFrame]) - min([obj.startFrame]) + 1;
end
