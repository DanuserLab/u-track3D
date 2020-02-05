function polygons = boundingBoxFormat(data)
%boundingBoxFormat is the output(1).formatData function in BuildDynROIProcess.getDrawableOutput.
%   This function is to transform the saved output boundingBox.mat of BuildDynROIProcess into the 
%   format that can be used in the display class, PolygonsDisplay, so the bounding boxes of dynamic
%   ROI can be displayed on the movie on the movieViewer GUI.
%	
%	See also graphBinaryOverlay, overlayProjGraph, overlayProjGraphMovie
%
%	Qiongjing (Jenny) Zou, August 2019
%
% Copyright (C) 2020, Danuser Lab - UTSouthwestern 
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

positions = data.vertices(:,1:2);
edges = data.edges;

nProj = size(positions, 1)/8;
newPositions = cell(1, nProj);
polygons = cell(1,size(edges,1)*nProj);

for i = 1: nProj
    newPositions{i} = positions(((i-1)*8+1):i*8,:);
    
    for eIdx=1:size(edges,1)
        pol=zeros(1,4);
        pol(1:2:end)=newPositions{i}(edges(eIdx,:),1);
        pol(2:2:end)=newPositions{i}(edges(eIdx,:),2);
        polygons{((i-1)*12)+eIdx}=pol; % x1y1 x2y2 coord of 12 edges; 1x12 cell, each 1x4 double
    end
end

end

