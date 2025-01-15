classdef PCViewer <  handle  & matlab.mixin.Copyable & dynamicprops

    properties %(SetAccess = protected)
       detectionsHandle
       colormaps
       minMaxLabel
    end
    
    methods
        
        function obj = PCViewer()
            obj.detectionsHandle={};
            obj.colormaps={};
            obj.minMaxLabel={};
        end

        function obj = addDetection(obj,det,varargin)
            ip = inputParser;
            ip.CaseSensitive = false;
            ip.KeepUnmatched=true;
            ip.addOptional('colormap',uint8(255*summer(256)));
            ip.addOptional('minMaxLabel',[])
            ip.parse(varargin{:});
            p=ip.Results;

            obj.detectionsHandle=[obj.detectionsHandle {det}];
            obj.colormaps=[obj.colormaps {p.colormap}];
            obj.minMaxLabel=[obj.minMaxLabel {p.minMaxLabel}];
        end


        function [playerHandle,h]=scatterPlot(obj,varargin)
            ip = inputParser;
            ip.CaseSensitive = false;
            ip.KeepUnmatched=true;
            ip.addOptional('colormap',uint8(255*summer(256)));
            ip.addOptional('colorIndex',{});
            ip.addOptional('handle',[]);
            ip.addOptional('timeStep',1);
            ip.addOptional('detections',[]);
            ip.addOptional('MarkerSize',20);
            ip.addOptional('player',[]);
            ip.addOptional('printFilePattern',[]);
            ip.addOptional('colorbar',[]);
            ip.addOptional('colorbarLabel',[]);
            ip.addOptional('colorbarLimit',[0 1]);
            ip.addOptional('view','XY');
            ip.addOptional('show',true);
            ip.parse(varargin{:});
            p=ip.Results;

            posCell=cell(1,numel(obj.detectionsHandle));
            colors=cell(1,numel(obj.detectionsHandle));
            for dIdx=1:numel(obj.detectionsHandle)
                det=obj.detectionsHandle{dIdx};
                det=det(p.timeStep);
                if(isempty(p.colorIndex))
                    if(isempty(obj.minMaxLabel{dIdx}))
                    minInt=min(det.getAllStruct().A);
                    maxInt=max(det.getAllStruct().A);
                    else
                    minInt=obj.minMaxLabel{dIdx}(1);
                    maxInt=obj.minMaxLabel{dIdx}(2);
                    end
                    NC=size(obj.colormaps{dIdx},1);
                    colorIndex=arrayfun(@(d) (ceil((NC-1)*mat2gray(d.getAllStruct().A,double([minInt maxInt])))+1),det,'unif',0);
                    % sum(isnan(det(1).getAllStruct().A))/numel((det(1).getAllStruct().A))
                    % figure();
                    % histogram(det(1).getAllStruct().A,100);
                    % figure();
                    % histogram([colorIndex{:}],100);
%
% Copyright (C) 2025, Danuser Lab - UTSouthwestern 
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
                else
                    colorIndex=p.colorIndex;
                end
                colors{dIdx}=cellfun(@(ci) uint8(obj.colormaps{dIdx}(ci,:)),colorIndex,'unif',0);
                posCell{dIdx}=det.getPosMatrix();
            end

            P=[posCell{:}]; %cellfun(@(p) p{1},posCell,'unif',0);
            P=vertcat(P{:});
            C=[colors{:}]; %C=cellfun(@(c) c{1},colors,'unif',0);
            C=vertcat(C{:});

            if(isempty(p.player))            
                maxBound=max(P); %vertcat(posCell{1}{:}));
                minBound=min(P); %vertcat(posCell{1}{:}));
                if(isempty(maxBound))
                    maxBound=[1 1 1];
                    minBound=[0 0 0];
                end
                player=pcplayer([minBound(1) maxBound(1)+1],[minBound(2) maxBound(2)+1],[minBound(3) maxBound(3)+1],'MarkerSize',p.MarkerSize);
                player.Axes.Color='k';
                player.Axes.GridColor=[0.9, 0.9, 0.9];
                player.Axes.XColor=[0.9, 0.9, 0.9];
                player.Axes.YColor=[0.9, 0.9, 0.9];
                player.Axes.ZColor=[0.9, 0.9, 0.9];
                player.Axes.Children.SizeData=10;
                player.Axes.Parent.Color='k';
                player.Axes.Parent.InvertHardcopy = 'off';
 
            else
                player=p.player;
            end


            if(~isempty(p.printFilePattern))
                mkdirRobust(fileparts(p.printFilePattern));
            end

            if(p.show)
                    pcUnif=pointCloud(P,'Color',C);
                    view(player,pcUnif);
                    if(~isempty(p.printFilePattern))
                        savePath=sprintfPath(p.printFilePattern,p.timeStep);
                        print(player.Axes.Parent,savePath,'-dpng');
                    end
            end

            switch p.view
                case 'XY'
                    az=0;
                    el=90;
                    view(player.Axes,az,el);
                case 'ZY'
                    az=90;
                    el=180;
                    view(player.Axes,az,el);
                case 'ZX'
                    az=180;
                    el=180;
                    view(player.Axes,az,el);
                otherwise
            end
            if(~isempty(p.colorbar))
                cmap=p.colorbar;
                colormap(player.Axes,cmap);
                c=colorbar(player.Axes,'Color','w');
                c.Label.String = p.colorbarLabel;
                % c.Limits=p.colorbarLimit;
                c.Ticks=[0 1];
                c.TickLabels=arrayfun(@(n) num2str(n), p.colorbarLimit,'unif',0);
            end
            h=player.Axes;
            playerHandle=player;
        end


        function [obj] = recordRotation(obj,playerHandle,printFilePattern,azimRange,elevRange);
            % Contract: to be used after scatterPlota
            assert(numel(azimRange)==numel(elevRange));
            mkClrDir(fileparts(printFilePattern));
            for rIdx=1:numel(azimRange)
                az=azimRange(rIdx);
                el=elevRange(rIdx);
                view(playerHandle.Axes,az,el);
                savePath=sprintfPath(printFilePattern,rIdx);
                print(playerHandle.Axes.Parent,savePath,'-dpng');
            end
        end

        function [obj] = rotateHandle(obj,playerHandle,azimRange,elevRange);
            % Contract: to be used after scatterPlota
            assert(numel(azimRange)==numel(elevRange));
            while(true)
            for rIdx=1:numel(azimRange)
                az=azimRange(rIdx);
                el=elevRange(rIdx);
                view(playerHandle.Axes,az,el);
                pause(0.1);
            end
            end
        end

        function [playerHandle,h]=dynScatterPlot(obj,varargin)
            ip = inputParser;
            ip.CaseSensitive = false;
            ip.KeepUnmatched=true;
            ip.addOptional('colormap',uint8(255*summer(256)));
            ip.addOptional('colorIndex',{});
            ip.addOptional('handle',[]);
            ip.addOptional('timeInterval',0.2);
            ip.addOptional('detections',[]);
            ip.addOptional('MarkerSize',20);
            ip.addOptional('player',[]);
            ip.addOptional('printFilePattern',[]);
            ip.addOptional('colorbar',[]);
            ip.addOptional('colorbarLabel',[]);
            ip.addOptional('colorbarLimit',[0 1]);
            ip.addOptional('view','XY');
            ip.addOptional('show',true);
            ip.parse(varargin{:});
            p=ip.Results;

            posCell=cell(1,numel(obj.detectionsHandle));
            colors=cell(1,numel(obj.detectionsHandle));
            for dIdx=1:numel(obj.detectionsHandle)
                det=obj.detectionsHandle{dIdx};
                if(isempty(p.colorIndex))
                 if(isempty(obj.minMaxLabel{dIdx}))
                     minInt=min(det.getAllStruct().A); 
                     maxInt=max(det.getAllStruct().A); 
                 else
                     minInt=obj.minMaxLabel{dIdx}(1);
                     maxInt=obj.minMaxLabel{dIdx}(2);
                 end
                    NC=size(obj.colormaps{dIdx},1);
                    colorIndex=arrayfun(@(d) (ceil((NC-1)*mat2gray(d.getAllStruct().A,double([minInt maxInt])))+1),det,'unif',0);
                else
                    colorIndex=p.colorIndex;
                end
                colors{dIdx}=cellfun(@(ci) uint8(obj.colormaps{dIdx}(ci,:)),colorIndex,'unif',0);
                posCell{dIdx}=det.getPosMatrix();
            end


            if(isempty(p.player))            
                maxBound=max(vertcat(posCell{1}{:}));
                minBound=min(vertcat(posCell{1}{:}));
                player=pcplayer([minBound(1) maxBound(1)],[minBound(2) maxBound(2)],[minBound(3) maxBound(3)], ... 
                                'MarkerSize',p.MarkerSize);
                player.Axes.Color='k';
                player.Axes.GridColor=[0.9, 0.9, 0.9];
                player.Axes.XColor=[0.9, 0.9, 0.9];
                player.Axes.YColor=[0.9, 0.9, 0.9];
                player.Axes.ZColor=[0.9, 0.9, 0.9];
                player.Axes.Children.SizeData=10;
                player.Axes.Parent.Color='k';
                player.Axes.Parent.InvertHardcopy = 'off';
                if(~isempty(p.colorbar))
                    colormap(player.Axes,p.colorbar);
                    c=colorbar(player.Axes,'Color','w');
                    c.Label.String = p.colorbarLabel;
                end
            else
                player=p.player;
            end

            switch p.view
                case 'XY'
                    az=0;
                    el=90;
                    view(player.Axes,az,el);
                case 'ZY'
                    az=90;
                    el=180;
                    view(player.Axes,az,el);
                case 'ZX'
                    az=180;
                    el=180;
                    view(player.Axes,az,el);
                otherwise
                    body
            end
            if(~isempty(p.printFilePattern))
                mkdirRobust(fileparts(p.printFilePattern));
            end
            if(~isempty(p.colorbar))
                cmap=p.colorbar;
                colormap(player.Axes,cmap);
                c=colorbar(player.Axes,'Color','w');
                c.Label.String = p.colorbarLabel;
                % c.Limits=p.colorbarLimit;
                c.Ticks=[0 1];
                c.TickLabels=arrayfun(@(n) num2str(n), p.colorbarLimit,'unif',0);
            end
            disp('Close the point cloud visualization window to release execution');
            if(p.show)
                firstLoop=true;
            while player.isOpen;
                for i=1:numel(posCell{1})
                    P=cellfun(@(p) p{i},posCell,'unif',0);
                    P=vertcat(P{:});
                    C=cellfun(@(c) c{i},colors,'unif',0);
                    C=vertcat(C{:});
                    pcUnif=pointCloud(P,'Color',C);
                    pcUnif=pcdownsample(pcUnif,'gridAverage',1);
                    

                    view(player,pcUnif);
                    pause(p.timeInterval);

                    if(~isempty(p.printFilePattern)&&firstLoop)
                        savePath=sprintfPath(p.printFilePattern,i);
                        print(player.Axes.Parent,savePath,'-dpng');
                    end
                end;
                firstLoop=false;
                if(~isempty(p.printFilePattern))
                    break;
                end
            end
            end
            h=player.Axes;
            playerHandle=player;
        end

     end

     methods(Static)
     function testTwoColormaps()
        V=PCViewer();
        pos=arrayfun(@(n) randn(1000,3),1:100,'unif',0);
        det=Detections().initFromPosMatrices(pos,pos);
        V.addDetection(det,255*summer(255));
        V.addDetection(det.copy().addOffset(0.3,0.3,0),255*autumn(255));
        V.dynScatterPlot();
    end
    end
 end