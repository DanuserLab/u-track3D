classdef PlanarROI < TracksROI
    methods
        function obj = PlanarROI(tracks,fringe)
            %% first tracks is origin
            %% Second track define Z
            %% third track define X
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
            if((numel(tracks)<3))
                error('Need at least three tracks as input.')
            end
            obj=obj@TracksROI(tracks,fringe,false);

            %% Default ref is the lab FoF centered around the starting position of the first track
            if(~isempty(obj.tracks))
                ref=FrameOfRef().setOriginFromTrack(obj.tracks(1)).setZFromTrack(obj.tracks(2)).genBaseFromZ();
                ref.genBaseFromZ(obj.tracks(3));
                obj.setDefaultRef(ref);
            end
        end

        function obj=resize(obj,ZOffsets,XOffsets)
            tracksRef=obj.getDefaultRef().applyBase(obj.tracks);
            tracksRef(1).addOffset(0,0,ZOffsets(1));
            tracksRef(2).addOffset(0,0,ZOffsets(2));
            tracksRef(1).addOffset(XOffsets(1),0,0);
            tracksRef(3).addOffset(XOffsets(2),0,0);
            obj.tracks=obj.getDefaultRef().applyInvBase(tracksRef);
        end

        function [idx,dist]=mapPosition(obj,positionMatrixCell)
            idx=cell(1,numel(positionMatrixCell));
            dist=cell(1,numel(positionMatrixCell));
            for fIdx=1:numel(positionMatrixCell)
                if(~isempty(positionMatrixCell{fIdx}))
                posRef=obj.getDefaultRef().applyBaseToPosPointCloud(positionMatrixCell{fIdx},fIdx);
                [m,M]=obj.getBoundingBox(obj.getDefaultRef(),fIdx);
                idx{fIdx}=( (posRef(:,1)>m(1))&(posRef(:,1)<M(1))& ...
                            (posRef(:,2)>m(2))&(posRef(:,2)<M(2))& ...
                            (posRef(:,3)>m(3))&(posRef(:,3)<M(3))  );
                dist{fIdx}=abs(posRef(:,3));
                end
            end
        end


    end

end
