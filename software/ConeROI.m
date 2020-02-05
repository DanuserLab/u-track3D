classdef ConeROI < TracksROI
% Track based for now. 
% Set from mask, or tube, or anything similar
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
    properties (SetAccess = public, GetAccess = public)
        angle;
    end

    methods
        function obj = ConeROI(tracks,angle)
            if(~(numel(tracks)==2))
                error('Need two tracks as input.')
            end
            obj=obj@TracksROI(tracks,1);
            obj.angle=angle;
            %% Default ref is the lab FoF centered around the starting position of the first track
            if(~isempty(obj.tracks))
                ref=FrameOfRef().setOriginFromTrack(obj.tracks(1)).setZFromTrack(obj.tracks(2)).genBaseFromZ();
                obj.setDefaultRef(ref);
                obj.fringe=tan(obj.angle)*max(ref.applyBase(obj.tracks(2)).z);
            end
        end
        
        function [minCoord,maxCoord]=getBoundingBox(obj,varargin)
            [minCoord,maxCoord]=getBoundingBoxOptim(obj,varargin{:});
        end
        
        function [minCoord,maxCoord]=getBoundingBoxOptim(obj,ref,frameIdx)
            pos=Detections().getTracksCoord(obj.tracks);
            if(nargin>2 && (max(frameIdx)<=numel(pos)))
                pos=pos(frameIdx);
            else
                frameIdx=1:numel(pos);
            end

            pos=pos.getPosMatrix();

            for fIdx=1:numel(pos)
                P=obj.getDefaultRef().applyBaseToPosPointCloud(pos{fIdx},frameIdx(fIdx));
                coneBase=P(2,:);
                pyramideBase1=coneBase+[obj.fringe obj.fringe 0];
                pyramideBase2=coneBase+[-obj.fringe -obj.fringe 0];
                pyramideBase3=coneBase+[obj.fringe -obj.fringe 0];
                pyramideBase4=coneBase+[-obj.fringe obj.fringe 0];
                P=[P;pyramideBase1;pyramideBase2;pyramideBase3;pyramideBase4];
                P=obj.getDefaultRef().applyInvBaseToPosPointCloud(P,frameIdx(fIdx));
                pos{fIdx}=P;
            end

            if(nargin>1)&&(~isempty(ref))
                for fIdx=1:numel(pos)
                    pos{fIdx}=ref.applyBaseToPosPointCloud(pos{fIdx}(:,[1 2 3]),frameIdx(fIdx));
                end
            end

            pos=vertcat(pos{:});
            if(~isempty(pos))
                fringeWidth=obj.fringe;

                minXBorder=floor(min(pos(:,1)));
                minYBorder=floor(min(pos(:,2)));
                minZBorder=floor(min(pos(:,3)));
                maxXBorder=ceil(max(pos(:,1)));
                maxYBorder=ceil(max(pos(:,2)));
                maxZBorder=ceil(max(pos(:,3)));
            else
                [m,M]=obj.getBoundingBox(ref);
                minXBorder=m(1);
                minYBorder=m(2);
                minZBorder=m(3);
                maxXBorder=M(1); 
                maxYBorder=M(2);
                maxZBorder=M(3);
            end
            minCoord=[minXBorder minYBorder minZBorder];
            maxCoord=[maxXBorder maxYBorder maxZBorder];
        end

        function [idx,dist]=mapPosition(obj,positionMatrixCell)
            %  Weights is computed to account for cone motion. I.E a detections transiently far from the center 
             manifold=obj.tracks;
%             mappedFrame=max([obj.tracks.startFrame]):min([obj.tracks.endFrame]);
%             if(numel(positionMatrixCell)<max(mappedFrame))
%                 error('not enough detection to map')
%             end
            idx=cellfun(@(p) false(1,size(p,1)),positionMatrixCell,'unif',0);
            dist=cellfun(@(p) zeros(1,size(p,1)),positionMatrixCell,'unif',0);

            for fIdx=1:numel(positionMatrixCell)
                if(~isempty(positionMatrixCell{fIdx}))
                    pIdx=find(obj.tracks(2).f==fIdx);
                    if(isempty(pIdx))
                        if(pIdx>obj.tracks(2).f(end))
                            pIdx=obj.tracks(2).f(end);
                        else
                            pIdx=obj.tracks(2).f(1);
                        end
                    end
                    manifoldAtT=[[manifold(1).x(pIdx);manifold(1).y(pIdx);manifold(1).z(pIdx)], ...
                        [manifold(2).x(pIdx);manifold(2).y(pIdx);manifold(2).z(pIdx) ]];
                    [idx{fIdx},dist{fIdx}]=mapPointsTo1DManifold(positionMatrixCell{fIdx}',manifoldAtT,obj.angle,'distType','cone');
                    if(any(dist{fIdx}>obj.angle))
                        warning('Angle mapping issues');
                    end
                end

            end

            % for f=1:numel(positionMatrixCell)
            %     tr=obj.tracks;
            %     positionMatrix=positionMatrixCell{f};
            %     tubPos=[tr(1).z(f) tr(1).y(f) tr(1).z(f);tr(2).z(f) tr(2).y(f) tr(2).z(f)];
            %     tubMaxSize=sum((tubPos(1,:)-tubPos(2,:)).^2).^.5+obj.fringe;
            %     [idx, dist] = KDTreeBallQuery(positionMatrix,sum(tubPos,2)/2,tubMaxSize);
            % end
        end

        function obj=resize(obj,diffZOrigin,diffZEnd)
            manifVector= obj.tracks(2).getAddCoord(obj.tracks(1).getMultCoord(-1));
            manifNorm=(manifVector.x.^2 + manifVector.y.^2 + manifVector.z.^2).^0.5;
            obj.tracks(1)=[obj.tracks(1).getAddCoord(manifVector.getMultCoord(diffZOrigin./manifNorm))];
            obj.tracks(2)=[obj.tracks(2).getAddCoord(manifVector.getMultCoord(diffZEnd./manifNorm))];
        end
        

    end

end
