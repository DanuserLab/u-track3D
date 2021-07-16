classdef CachedAnimation < Animation & CachedSequenceCellCache
%% Simple cache interface for a XYT RGB sequences.
%% From Animation and CachedSequence
%
% Copyright (C) 2021, Danuser Lab - UTSouthwestern 
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

%% Because they have different usage. CachedAnimation may have to split from 
%% Cached sequence in the future.

%% Caching is very basic. Could be improved with advanced libraries.

%% Philippe Roudot.
    methods 
    function obj = CachedAnimation(outputPath,nFrames,varargin)
        ip = inputParser;
        ip.CaseSensitive = false;
        ip.KeepUnmatched = true;
        ip.addRequired('outputPath',@ischar);
        ip.addRequired('nFrames',@isnumeric);
        ip.parse(outputPath,nFrames,varargin{:});
        p=ip.Results;
        %% Used as a 3D cache for contiguity
        obj=obj@CachedSequenceCellCache(outputPath,nFrames,1)
    end

    function rgbImg=loadView(obj,fIdx)
        rgbImg=obj.loadFrame(fIdx,1);
    end

    function aImAnimation=printAnimation(obj,outputPath)
        aImAnimation=ImAnimation([outputPath 'frame_%04d.png'],obj.getFrameNb());
        mkdirRobust(fileparts(aImAnimation.pathTemplate));
        for fIdx=1:aImAnimation.getFrameNb();
            img=obj.loadView(fIdx);
            aImAnimation.saveView(fIdx,img);
        end
    end

    function img=saveView(obj,fIdx,rgbImg)
       obj.saveFrame(rgbImg,fIdx,1);
    end

    end
    
    methods(Static)
        
        function obj=buildFromRGBCell(RGBCell,outputPath)
            obj=CachedAnimation(outputPath,numel(RGBCell));
            mkdirRobust(fileparts(outputPath));
            for fIdx=1:obj.getFrameNb();
                obj.saveView(fIdx,RGBCell{fIdx});
            end
        end
    end


end


% if(nargin>1)
%     obj.buildAndSetOutFilePaths([rawProjectDynROIProcess.getOutputDir() filesep 'Rendering' filesep name],1);
%     set(obj,'ref',rawProjectDynROIProcess.ref);
%     set(obj,'nFrames',length(rawProjectDynROIProcess.nFrames));   
%     [BX,BY,BZ]=rawProjectDynROIProcess.getBoundingBox();
%     obj.setBoundingBox(BX,BY,BZ);
% end