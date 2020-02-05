classdef RoundedTubeROI < TracksROI
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
    end

    methods
        function obj = RoundedTubeROI(tracks,fringe)
            if(~(numel(tracks)==2))
                error('Need two tracks as input.')
            end
            obj=obj@TracksROI(tracks,fringe);
            %% Default ref is the lab FoF centered around the starting position of the first track
            if(~isempty(obj.tracks))
                ref=FrameOfRef().setOriginFromTrack(obj.tracks(1)).setZFromTrack(obj.tracks(2)).genBaseFromZ();
                obj.setDefaultRef(ref);
            end
        end
        
        function obj=resize(obj,diffZOrigin,diffZEnd)
            manifVector= obj.tracks(2).getAddCoord(obj.tracks(1).getMultCoord(-1));
            manifNorm=(manifVector.x.^2 + manifVector.y.^2 + manifVector.z.^2).^0.5;
            obj.tracks(1)=[obj.tracks(1).getAddCoord(manifVector.getMultCoord(diffZOrigin./manifNorm))];
            obj.tracks(2)=[obj.tracks(2).getAddCoord(manifVector.getMultCoord(diffZEnd./manifNorm))];
        end

        function [idx,dist]=mapPosition(obj,positionMatrixCell)
            % positionMatrixCell is assumed to start at frame 1 
            disp('RoundedTubeROI Mapping')
            manifold=obj.tracks;
            mappedFrame=min([obj.tracks.startFrame]):max([obj.tracks.endFrame]);

            if(numel(positionMatrixCell)<max(mappedFrame))
                    positionMatrixCell=[positionMatrixCell cell(1,max(mappedFrame)-numel(positionMatrixCell))];
            end
            idx=cellfun(@(p) false(1,size(p,1)),positionMatrixCell,'unif',0);
            dist=cellfun(@(p) zeros(1,size(p,1)),positionMatrixCell,'unif',0);


            parfor fIdx=mappedFrame
                pIdx=find(obj.tracks(2).f==fIdx);
                manifoldAtT=[[manifold(1).x(pIdx);manifold(1).y(pIdx);manifold(1).z(pIdx)], ...
                             [manifold(2).x(pIdx);manifold(2).y(pIdx);manifold(2).z(pIdx) ]];
                [idx{fIdx},dist{fIdx}]=mapPointsTo1DManifold(positionMatrixCell{fIdx}',manifoldAtT,obj.fringe,'distType','euclideanDist');
            end
        end

        % function [mappedTracks,indices,dist]=mapTracks(obj,tracks,position)
        %     [mappedTracks,indices,dist]=mapTracksTo1DManifold(obj.tracks,tracks,obj.fringe,'position',position,'distType','euclideanDist');
        %     % Solving weird output inconsitencies. Why did I do that...

        %     indicestmp=false(size(tracks));
        %     indicestmp(indices)=true;
        %     indices=indicestmp;
        %     disttmp=zeros(size(tracks));
        %     disttmp(indices)=dist(:);
        %     dist=disttmp;
        % end


        function mask=getMask(obj,volSize,zRatio,fIdx)
            insetDynROI=obj.tracks;
            pIndices=nan(1,length(insetDynROI));
            for polIdx=1:length(insetDynROI)
                F=insetDynROI(polIdx).f;
                pIdx=find(F==fIdx,1);
                if isempty(pIdx)
                    if(fIdx>max(F))   pIdx=length(F);  else   pIdx=1; end;
                end
                pIndices(polIdx)=pIdx;
            end

            %% Building mask in the 1D case
            nextPoint=length(insetDynROI);
            PCurrent=[insetDynROI(1).x(pIndices(1)) insetDynROI(1).y(pIndices(1)) insetDynROI(1).z(pIndices(1))];
            KCurrent=[insetDynROI(nextPoint).x(pIndices(nextPoint)) insetDynROI(nextPoint).y(pIndices(nextPoint)) insetDynROI(nextPoint).z(pIndices(nextPoint))];
            % Building mask for both channel on the whole volume
            % NOTE: in order to apply fringe isotropically, we need the mask to
            % be isotropized briefly.
            mask=zeros(volSize(1),volSize(2),ceil(volSize(3)*zRatio));
            sampling=100;
            xSeg=round(linspace(PCurrent(1),KCurrent(1),sampling));
            ySeg=round(linspace(PCurrent(2),KCurrent(2),sampling));
            zSeg=round(linspace(PCurrent(3),KCurrent(3),sampling));
            indx=sub2ind(size(mask),ySeg,xSeg,zSeg);
            
            mask(indx)=1;
            
            distMap=mask;
            distMap=bwdist(distMap);
            mask(distMap<(obj.fringe+1))=1;
            [y x z]=...
                ndgrid( linspace(1,size(mask,1),volSize(1)),...
                        linspace(1,size(mask,2),volSize(2)),...
                        linspace(1,size(mask,3),volSize(3)));
            mask=interp3(mask,x,y,z);
        end
    end

    methods (Static)

    function ROICell=RoundedTubeROICollection(AllOrigin, AllEnds,tubeSize)
        ROICell=cell(1,numel(AllOrigin));
        for tIdx=1:numel(AllOrigin)
              ROICell{tIdx}=RoundedTubeROI([AllOrigin(tIdx),AllEnds(tIdx)],tubeSize);
        end
    end
    end

end
