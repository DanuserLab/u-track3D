function overlayProjGraphMovie(processProj,positions,edgesCell,varargin)
ip = inputParser;
ip.CaseSensitive = false;
ip.KeepUnmatched = true;
ip.addRequired('processProj');
ip.addOptional('positions',[],@(x) isa(x,'Detections')); 
ip.addOptional('edgesCell',[],(@(x) iscell(x)||isempty(x))); %% size(edgesCell{1}) == Nx2
ip.addOptional('process',[],@(x) isa(x,'Process'));
ip.addOptional('colormap',[],@isnumeric);
ip.addOptional('dragonTail',[],@isnumeric);  % dragonTrail: - N: display on frame <f> the graph described at frame <f>-N to <f>
ip.addOptional('dragonTailGap',1,@isscalar)  % dragonTailGap: - time interval between each graph drawn in the tail (to reduce density)
ip.addParameter('colorTail',false);  % colorTail: - true: use colormap to color the dragon tail (frame <f> is colored with cm(1,:))
ip.addOptional('processFrames',[]);
ip.addOptional('cumulative',false);
ip.addOptional('saveVideo',false);
ip.addOptional('printVectorFilePattern','');
ip.addOptional('colorIndx',[],@iscell);
ip.addOptional('colorLabel',[],(@(x) iscell(x)||isempty(x)));
ip.addOptional('name','spatialGraphs');
ip.parse(processProj,positions,edgesCell,varargin{:});
p=ip.Results;

cumulative=p.cumulative;
%% testing imwarp to crop the image
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

projDataIdx=5;
ref=[];

%% Dealing with legacy container for MIP container. Probably to be removed. PR June 2018.
if(isa(processProj,'ExternalProcess'))
  processProjDynROI=ProjectDynROIRendering();
  processProjDynROI.importFromDeprecatedExternalProcess(processProj);
  try % Handle Project1D/ProjDyn different outFilePaths_spec (need to be defined through a class...)
    projData=load(processProj.outFilePaths_{projDataIdx},'minXBorder', 'maxXBorder','minYBorder','maxYBorder','minZBorder','maxZBorder','frameNb');
  catch
    projDataIdx=4;
  end
  projData=load(processProj.outFilePaths_{projDataIdx},'minXBorder', 'maxXBorder','minYBorder','maxYBorder','minZBorder','maxZBorder','frameNb');
  processProjDynROI.setBoundingBox( [projData.minXBorder projData.maxXBorder], [projData.minYBorder projData.maxYBorder], [projData.minZBorder projData.maxZBorder]);
  processProj=processProjDynROI;
end

%% Projecting in MIP-associated frame of reference.
ref=get(processProj,'ref');
if(~isempty(ref))
    positions=ref.applyBase(positions,'');  
end
projData=processProj;

processFrames=p.processFrames;
frameNb=min([projData.frameNb,length(positions)]);
if(isempty(processFrames))
    processFrames=1:frameNb;
end
frameNb=min([projData.frameNb,length(positions),length(processFrames)]);


%% create projection process saving independant projection location
% if(~isempty(p.process))
%   processRenderer = ProjRendering(processProj,p.name);
% end

colorIndx=p.colorIndx;

colormapSize=size(p.colormap,1);
if(isempty(p.colormap))
    colormapSize=256;
end

if(~isempty(p.colorLabel))

    try
        allLabel=vertcat(p.colorLabel{:});
    catch
        allLabel=[p.colorLabel{:}];
    end;

   colorIndx=cellfun(@(d) ceil((colormapSize-1)*mat2gray(reshape(d,numel(d),1),[min(allLabel),max(allLabel)]))+1,p.colorLabel,'unif',0);


end

if(isempty(colorIndx))
    colorIndx=cellfun(@(e) ones(1,size(e,1)),edgesCell,'unif',0);
end

acolormap=p.colormap;
if(isempty(acolormap))
    acolormap=255*hsv(colormapSize);
end

keptIdx=cell(1,numel(processFrames));
%% Trying to get around parfor limitation PR 2018.
%% TODO: slicing project Class and use spmd for more control
pCell1=cell(1,numel(processFrames));
pCell2=cell(1,numel(processFrames));
pCell3=cell(1,numel(processFrames));
oCell1=cell(1,numel(processFrames));
oCell2=cell(1,numel(processFrames));
oCell3=cell(1,numel(processFrames));
for fIdx=processFrames
  [pCell1{fIdx},pCell2{fIdx},pCell3{fIdx}]=processProj.loadFrame(1,fIdx);
end

[xBound,yBound,zBound]=projData.getBoundingBox();
pos=positions.getPosMatrix();
for fIdx=processFrames
    XYProj=pCell1{fIdx};
    ZYProj=pCell2{fIdx};
    ZXProj=pCell3{fIdx};
    if(cumulative)
        error('Not implemented');
%         detectionsAtFrame=positions;
        fColorIndx=colorIndx;
    else
%         detectionsAtFrame=positions(fIdx);
        fColorIndx=colorIndx{fIdx};
    end
    printVectorFile=[];
    if(~isempty(p.printVectorFilePattern))
        mkdirRobust(fileparts(p.printVectorFilePattern));
        printVectorFile=sprintfPath(p.printVectorFilePattern,fIdx);
    end
    if(isempty(p.dragonTail))
      posToDraw=pos{fIdx};
      edgeToDraw=edgesCell{fIdx};
    else
      dragTailRange=max(1,fIdx-p.dragonTail):fIdx;
      dragTailRange=union(intersect(dragTailRange,1:p.dragonTailGap:numel(processFrames)),fIdx);
      posToDraw=vertcat(pos{dragTailRange});
      % Handle new position ID
      edgeToDraw=edgesCell(dragTailRange);
      cumulPosCount=cumsum(cellfun(@(p) size(p,1),pos(dragTailRange)));
      for ffIdx=2:numel(edgeToDraw)
        edgeToDraw{ffIdx}=edgeToDraw{ffIdx}+cumulPosCount(ffIdx-1);
      end
      edgeToDraw=vertcat(edgeToDraw{:});

      if((p.colorTail))
        fColorIndx=colorIndx(dragTailRange);
        cIdx=size(acolormap,1);
        for ffIdx=numel(fColorIndx):-1:1
          fColorIndx{ffIdx}(:)=cIdx;
          cIdx=max(1,cIdx-1);
        end
        fColorIndx=vertcat(fColorIndx{:});
      else
        fColorIndx=vertcat(colorIndx{dragTailRange});
      end
    end
      
    % detectionsAtFrame.zCoord(:,1)=detectionsAtFrame.zCoord(:,1)/0.378;
    [overlayXY,overlayZY,overlayZX]=overlayProjGraph(XYProj,ZYProj,ZXProj, ...
        xBound,yBound,zBound, ...
        posToDraw,edgeToDraw,acolormap,fColorIndx,varargin{:});
    oCell1{fIdx}=overlayXY;
    oCell2{fIdx}=overlayZY;
    oCell3{fIdx}=overlayZX;
end

if(~isempty(p.process))
  for fIdx=processFrames
      p.process.saveFrame(1,fIdx,oCell1{fIdx},oCell2{fIdx},oCell3{fIdx});
  end
end

if(~isempty(p.process)&&p.saveVideo) 
    ProjAnimation(p.process,'ortho').saveVideo([p.process.getOutputDir()  '.avi']);
end

