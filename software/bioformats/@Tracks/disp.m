function disp(obj)
    s = size(obj);
    builtin('disp',obj);
    if(numel(obj) == 1)
    else
        disp(['Total segments = ' num2str(totalSegments(obj))]);
        disp(['Total frames = ' num2str(numTimePoints(obj))]);
    end
end
