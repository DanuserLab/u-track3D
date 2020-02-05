classdef ProjectDynROIRendering < CachedProjectDynROIProcess
%% This class provide a view from an orthogonal projection rawProjectDynROIProcess.
%% It reuses ProjectDynROIProcess as a backEnd, since this class already the necessary containers. 
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
    methods 

    function obj = ProjectDynROIRendering(rawProjectDynROIProcess,name)
        obj=obj@CachedProjectDynROIProcess(rawProjectDynROIProcess.getOwner(),'','nRenderedChannel',1);
        obj.setProcessTag([rawProjectDynROIProcess.tag_ '-' name]);
        obj.ZRight=rawProjectDynROIProcess.ZRight;
        obj.Zup=rawProjectDynROIProcess.Zup;
        if(nargin>1)
            obj.buildAndSetOutFilePaths([rawProjectDynROIProcess.getOutputDir() filesep 'Rendering' filesep name],1,rawProjectDynROIProcess.nFrames);
            set(obj,'ref',rawProjectDynROIProcess.ref);
            set(obj,'nFrames',(rawProjectDynROIProcess.nFrames));   
            [BX,BY,BZ]=rawProjectDynROIProcess.getBoundingBox();
            obj.setBoundingBox(BX,BY,BZ);
        end
    end

end
end

