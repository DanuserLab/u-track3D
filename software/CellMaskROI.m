classdef CellMaskROI < TracksROI
    methods
        function obj = CellMaskROI(MD,channel,fringe)
            %% Cut the tracks to minimum lifetime
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
            NFrameTest=MD.nFrames_;
            cellCenterPos=cell(1,NFrameTest);
            ZRatio=MD.pixelSizeZ_/MD.pixelSize_;
            % profile on;
            % figure;

            for fIdx=1:NFrameTest
                vol=(MD.getChannel(channel).loadStack(fIdx));
                vol=mat2gray(vol);
                vol=imgaussfilt3(vol,10);
                L=graythresh((vol));
                mask=(vol>L);
                mask = imfill(mask,'holes'); 
                treshDist=bwdist(~mask);
                [~,idxCenter]=max(treshDist(:));

                centerMask=zeros(size(mask));
                centerMask(idxCenter)=1;
                centerMask(bwdist(centerMask)<10)=1;
                loc=sc(cat(3,computeMIPs(vol),computeMIPs(centerMask)),'stereo');
                imdisp({loc,computeMIPs(mask),mat2gray(computeMIPs(treshDist))});
                drawnow;
                [Y,X,Z]=ind2sub(size(vol),idxCenter);
                cellCenterPos{fIdx}=[X Y Z*ZRatio];
            end
            %profile viewer;
            %% Default ref is the lab FoF centered around the starting position of the first track
            centerTrack=Detections().initFromPosMatrices(cellCenterPos,cellCenterPos).buildTracksFromDetection();
            obj=obj@TracksROI(centerTrack,fringe);
            return;
        end


        function [idx,dist]=mapPosition(obj,positionMatrixCell)
            idx=cell(1,numel(positionMatrixCell));
            dist=cell(1,numel(positionMatrixCell));
            for pIdx=1:numel(positionMatrixCell)
                orig=obj.getrigAtFraOme(pIdx);
                [idx{pIdx}, dist{pIdx}] = KDTreeBallQuery(positionMatrixCell{pIdx},orig,obj.fringe);
            end
        end

        function [mappedTracks,indices,dist]=mapTracks(obj,tracks,position)
            det=Detections().setFromTracks(tracks).getPosMatrix();
            [indices,dist]=obj.mapPosition(obj,det)
        end       
    end

end
