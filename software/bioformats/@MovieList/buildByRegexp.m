function ML = buildByRegexp(filter,outputDirectory,findMatsInDirs)
% Build a MovieList using a regular expression.
%
% INPUT
% filter - regular expression for directories in the current directory
% which should contain .mat files of the same name as their directory
% outputDirectory - outputDirectory for the MovieList constructor
%
% OUTPUT
% ML - A MovieList containing MovieData objects that matches filter

% Mark Kittisopikul, March 2018
% Goldman Lab
% Northwestern University

    if(nargin < 2)
        outputDirectory = pwd;
    end
    if(nargin < 3)
        findMatsInDirs = true;
    end
    D = dir;
    if(findMatsInDirs)
        D = D([D.isdir]);
        D = D(~cellfun(@(x) isempty(regexp(x,filter, 'once')),{D.name}));
        movieDataFileNames = strcat(pwd,filesep,{D.name},filesep,{D.name},'.mat');
    else
        D = D(~cellfun(@(x) isempty(regexp(x,filter, 'once')),{D.name}));
        movieDataFileNames = {D.name};
        disp(movieDataFileNames(:));
        x = input('Create [new] MovieData objects by loading these files Y/N [N]?: ','s');
        if(isempty(x) || x(1) ~= 'Y')
            disp('MovieList not created');
            return;
        end
        movieDataFileNames = cellfun(@MovieData.load,{D.name},'Unif',false);
    end
    ML = MovieList(movieDataFileNames,outputDirectory);
    try
        ML.sanityCheck;
    catch err
        disp(getReport(err));
    end
end