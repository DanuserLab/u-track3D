function [dataFolder]=retrieveRemoteDataset(datasetUrl,outputFolder)
mkdir(outputFolder)
[~,datasetName,fileExt]=fileparts(datasetUrl);
zipOutputFilename=fullfile(outputFolder,[datasetName,fileExt]);
dataFolder=fullfile(outputFolder,datasetName); 

disp('::::')
disp(['Downloading and decompressing dataset ' datasetName ' under:']);
disp(dataFolder)                

websave(zipOutputFilename, datasetUrl);
unzip(zipOutputFilename,[outputFolder])  


%
% Copyright (C) 2022, Danuser Lab - UTSouthwestern 
%
% This file is part of NewUtrack3DPackage.
% 
% NewUtrack3DPackage is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% NewUtrack3DPackage is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with NewUtrack3DPackage.  If not, see <http://www.gnu.org/licenses/>.
% 
% 