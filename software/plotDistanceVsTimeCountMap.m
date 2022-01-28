function [countFixed]=plotDistanceVsTimeCountMap(alignedDet,alignedTrack,distanceBinning,timeBinning,startTime,timeInterval)
        alignedDet.addSphericalCoord();

        poleDistancePerFrameCell=arrayfun(@(d) d.rho,alignedDet,'unif',0);
        

        allTime=arrayfun(@(t) startTime+timeInterval*(t-1)*ones(numel(poleDistancePerFrameCell{t}),1),1:numel(poleDistancePerFrameCell),'unif',0);
        allTime=vertcat(allTime{:});
        allDist=vertcat(poleDistancePerFrameCell{:});
        %%
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
        [heatMap] = histcounts2(allDist,allTime,distanceBinning,timeBinning);
        [ax,~, figH]=setupFigure(1,1,1,'AspectRatio',1,'AxesWidth',10);
        xlabel('Time after NEBD (s)')
        ylabel('Distance from poles (um)')
        imsc(timeBinning(1:end-1),distanceBinning(1:end-1)/10,heatMap,'parula',[0 prctile(heatMap(:),99)]);%;
        hold on;
        p=plot(startTime+timeInterval*(alignedTrack.f-1),alignedTrack.z/10,'r','LineWidth',4);
        hold off;
        xlim([min(timeBinning),max(timeBinning)])
        ylim([1,max(alignedTrack.z/10)+1])
        colorbar;p
        c = colorbar;
        c.Label.String = '+Tips count';