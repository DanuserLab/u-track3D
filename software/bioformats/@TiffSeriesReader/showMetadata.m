function [ imInfo ] = showMetadata( obj )
%showMetadata Show metadata via TiffSeriesReader

% Mark Kittisopikul, June 2017

    imInfo = cell(1,obj.getSizeC());
    for iChan = 1 : obj.getSizeC()
        fileNames = obj.getImageFileNames(iChan);
        imInfo{iChan} = cellfun(@(x) imfinfo([obj.paths{iChan} filesep x]), fileNames, 'unif', 0);
    end
    % Simplify structure if trivial
    if(isscalar(imInfo) && iscell(imInfo))
        imInfo = imInfo{1};
        if(isscalar(imInfo) && iscell(imInfo))
            imInfo = imInfo{1};
        end
    end
    % Get base workspace vars so we don't overwrite anything
    basevars = evalin('base','who');
    try
        varname = matlab.lang.makeValidName(['metadata_' fileNames{end}]);
        varname = matlab.lang.makeUniqueStrings(varname,basevars);
    catch err
        % This will be deprecated at some point
        % Needed for pre 2014a compatability
        varname = genvarname(['metadata_' fileNames{end}],basevars);
    end
    
    % Assign here and base so openvar works when function quits
    assignin('caller',varname,imInfo);
    assignin('base',varname,imInfo);
    openvar(varname);
    
    % Let the user know where the metadata is
    msgbox('See the Variable Editor for metadata.','Metadata');


end

