classdef CellMaskRegROI < TracksROI
    %% Detect the cell center
    %% register center using point registration.
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
        function obj = CellMaskRegROI(MD,channel,fringe)
            %% Cut the tracks to minimum lifetime
            NFrameTest=MD.nFrames_;
            cellCenterPos=cell(1,NFrameTest);
            ZRatio=MD.pixelSizeZ_/MD.pixelSize_;
            % profile on;
            % figure;

            for fIdx=1%:NFrameTest
                vol=(MD.getChannel(channel).loadStack(fIdx));
                vol=mat2gray(vol);
                vol=imgaussfilt3(vol,10);
                L=graythresh((vol));
                mask=(vol>L);
                mask = imfill(mask,'holes'); 
                treshDist=bwdist(~mask);
                [~,idxCenter]=max(treshDist(:));
                [Y,X,Z]=ind2sub(size(vol),idxCenter);
                cellCenterPos{fIdx}=[X Y Z*ZRatio];

                [Y,X,Z]=ind2sub(size(vol),mask(:));                

                %% debug
                % centerMask=zeros(size(mask));
                % centerMask(idxCenter)=1;
                % centerMask(bwdist(centerMask)<10)=1;
                % loc=sc(cat(3,computeMIPs(vol),computeMIPs(centerMask)),'stereo');
                % imdisp({loc,computeMIPs(mask),mat2gray(computeMIPs(treshDist))});
                % drawnow;
            end

            tformCell=cell(1,NFrameTest);
            posCloud=cell(1,NFrameTest);
            parfor fIdx=1:NFrameTest
                disp(['frame ' num2str(fIdx)]);
                vol=(MD.getChannel(channel).loadStack(fIdx));
                vol=mat2gray(vol);
                %vol=imresize(vol,[MD.imSize_ ZRatio*MD.zSize_]);
                vol=imgaussfilt3(vol,5);
                
                disp('threshold, fill and get pos');
                L=graythresh((vol));
                mask=(vol>L);
                mask = imfill(mask,'holes'); 
                                
                disp('Build and downsample pointCloud');
                [Y,X,Z]=ind2sub(size(vol),find(mask));  
                P=[X Y ZRatio*Z];
                PC=pointCloud(P);
                PC=pcdownsample(PC,'random',0.01);
                posCloud{fIdx}=PC;
            end

            pos=cellfun(@(pc) pc.Location,posCloud,'unif',0);
            det=Detections().initFromPosMatrices(pos,pos);
            det.setAmp(arrayfun(@(d) ones(d,1),det.getCard(),'unif',0));
            allTracks= det.buildTracksFromDetection();

            [ref,centerTrack]=ICPIntegrationFirstReg(det);
            obj = obj@TracksROI([centerTrack;allTracks],fringe);
            obj.setDefaultRef(ref);
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
