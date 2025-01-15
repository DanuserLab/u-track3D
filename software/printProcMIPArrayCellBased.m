 function processRenderArray=printProcMIPArrayCellBased(processCellArray,varargin)
%% MIPSize: 
%% 
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
ip = inputParser;
ip.KeepUnmatched = true;
ip.addRequired('processCellArray',(@(pr) isa(pr,'cell')&&(ndims(pr)==2)));
ip.addParamValue('savePath','/tmp/printProcMIPArrayCellBased/',@ischar);
ip.addParamValue('maxWidth',1600,@isnumeric);
ip.addParamValue('maxHeight',1000,@isnumeric);
ip.addParamValue('MIPSize',400,(@(x) isnumeric(x)||strcmp(x,'auto'))); % Max size of each rendering. If set to Auto, use the array arrangement of processCellArray and maxWidth/maxHeight to define Size.
ip.addParamValue('MIParrangement','useMap',(@(x) strcmp(x,'useMap')||strcmp(x,'auto'))); % If set to auto use the MIPSize. Otherwise use the array arrangement of processCellArray.
ip.addParamValue('keepSize',false,@islogical);
ip.addParamValue('forceHeight',false,@islogical);
ip.addParamValue('forceWidth',false,@islogical);
ip.addParamValue('invertLUT',0,@islogical);
ip.addParamValue('saveVideo',true,@islogical)
ip.addParamValue('printFrame',[],@isnumeric);
ip.parse(processCellArray,varargin{:});
p=ip.Results;

disp('::::')
disp('Building Montage');


MIPSize=p.MIPSize;
nProcess=numel(processCellArray);

[processCellArray,frameNb]=managedLegacyProcess(processCellArray);

if(isempty(p.printFrame))
    printFrame=1:max(frameNb);
else
    printFrame=p.printFrame;
end

% set parameters
stripeSize = 4; 
stripeColor = 200; 

% Build a (non-optimal) array arrangment for movie location that will fit
% the maximum video size.
% MIPSize option:
% Auto: fit all picture in frame

MDArray=1:nProcess;
MDArray=reshape(MDArray,size(processCellArray,1),size(processCellArray,2));
MIPSize=p.MIPSize;
if(strcmp(p.MIPSize,'auto'))
    % Maximum size in heigth and width to optimize space at the single image level
    maxMIPSize=[(p.maxHeight-(size(MDArray,1)-1)*stripeSize)/size(MDArray,1) ,(p.maxWidth-(size(MDArray,2)-1)*stripeSize)/size(MDArray,2)];
else
    % Fit as many object as possible given MIPSize
    % Only compute arragnement if MIPSize is specified.
    if(strcmp(p.MIParrangement,'auto'))
        maxMoviePerLine=floor(p.maxWidth/(MIPSize+stripeSize));
        MDArray=(1:nProcess);
        untruncatedArraySize=[ceil(nProcess/maxMoviePerLine), min(nProcess,maxMoviePerLine)]
        if(untruncatedArraySize(1)*untruncatedArraySize(2)>nProcess)
            MDArray(untruncatedArraySize(1)*untruncatedArraySize(2))=0;
        end
        MDArray=reshape(MDArray,fliplr(untruncatedArraySize))'
    end
    maxMIPSize=[MIPSize MIPSize];
end

renderCell=cell(1,numel(printFrame));
for fIdx=1:numel(printFrame)
    frameIdx=printFrame(fIdx);
    renderCell{fIdx}=buildArray(processCellArray,frameIdx,[p.maxHeight p.maxWidth],...
                        p.MIParrangement,p.MIPSize,stripeSize,stripeColor, ... 
                        'forceWidth',p.forceWidth,'forceHeight',p.forceHeight);
end

processRenderArray=CachedAnimation(p.savePath,numel(printFrame));
for fIdx=1:numel(printFrame)
    processRenderArray.saveView(fIdx,renderCell{fIdx});
end


function render=buildArray(processCellArray,frameIdx,maxArraySize,arrangementType, ... 
                            mipSize,stripeSize,stripeColor,varargin)
    ip = inputParser;
    ip.KeepUnmatched = true;
    ip.addParamValue('forceHeight',false,@islogical);
    ip.addParamValue('forceWidth',false,@islogical);
    ip.parse(varargin{:});
    p=ip.Results;

nProcess=numel(processCellArray);
MDArray=1:nProcess;

%% Define maxMIPSize and array arrangement 
switch(arrangementType)
case 'useMap'
    MDArray=reshape(MDArray,size(processCellArray,1),size(processCellArray,2));
    % Resize image to fit in the array
    maxMIPSize=floor([(maxArraySize(1)-(size(MDArray,1)-1)*stripeSize)/size(MDArray,1) , ... 
                      (maxArraySize(2)-(size(MDArray,2)-1)*stripeSize)/size(MDArray,2)]);
case 'auto'
    % Define array to fit all the images at a given size
    maxMIPSize=[mipSize,mipSize];
    maxMoviePerLine=floor(maxArraySize(2)/(mipSize+stripeSize));
    untruncatedArraySize=[ceil(nProcess/maxMoviePerLine), min(nProcess,maxMoviePerLine)]
    if(untruncatedArraySize(1)*untruncatedArraySize(2)>nProcess)
        MDArray(untruncatedArraySize(1)*untruncatedArraySize(2))=0;
    end
    MDArray=reshape(MDArray,fliplr(untruncatedArraySize))';
end

mipArray=cell(size(MDArray));
%% rescale maximally
for i=1:numel(processCellArray)
    if(~isempty(processCellArray{i}))
        if(iscell(processCellArray{i}))
            mipArray{i}=buildArray(processCellArray{i},frameIdx,maxMIPSize,arrangementType,mipSize,stripeSize,stripeColor,varargin{:});
        else
            %% That is where the problem lies.  
            mMaxXY=processCellArray{i}.loadView(frameIdx);
            ratio=size(mMaxXY,1)/size(mMaxXY,2);
            if(((maxMIPSize(2)*ratio>maxMIPSize(1))||(p.forceHeight))&&(~p.forceWidth))
                mMaxXY=imresize(mMaxXY,maxMIPSize(1)/(size(mMaxXY,1)));
            else
                mMaxXY=imresize(mMaxXY,maxMIPSize(2)/(size(mMaxXY,2)));
            end
            mipArray{i}=mMaxXY;
        end
    end
end


%% Maximum column and row
maxHeightPerRow=arrayfun(@(c) max(cellfun(@(m) size(m,1),mipArray(c,:))),1:size(mipArray,1));
maxWidthPerColumn=arrayfun(@(c) max(cellfun(@(m) size(m,2),mipArray(:,c))),1:size(mipArray,2));

%% Maximum padding optimally
pIdx=1;
for i=1:size(MDArray,1)
    for j=1:size(MDArray,2)
        if(~isempty(processCellArray{pIdx}))
            pad=maxWidthPerColumn(j)-size(mipArray{i,j},2);
            if(pad>0)
            mipArray{i,j}=padarray(mipArray{i,j},[0 max(0,pad)],'post');
            end
            pad=maxHeightPerRow(i)-size(mipArray{i,j},1);
            if(pad>0)
            mipArray{i,j}=padarray(mipArray{i,j},[max(0,pad) 0],'post');
            end
        else
            mipArray{i,j}=uint8(zeros(maxHeightPerRow(i),maxWidthPerColumn(j),3));
        end
    end
    pIdx=pIdx+1;
end

%% Add border
for i=1:size(MDArray,1)
    for j=1:size(MDArray,2)
        padding=[(i~=size(MDArray,1))*stripeSize (j~=size(MDArray,2))*stripeSize];
        if(any(padding>0))
            mipArray{i,j}=padarray(mipArray{i,j},[(i~=size(MDArray,1))*stripeSize (j~=size(MDArray,2))*stripeSize],stripeColor,'post');
        end
    end
end

%% stick together
renderPixelSizeHeight=cellfun(@(m) size(m,1),mipArray);
renderPixelSizeWidth=cellfun(@(m) size(m,2),mipArray);

rendert=uint8(zeros(sum(renderPixelSizeHeight(:,1)),sum(renderPixelSizeWidth(1,:)),3));

renderPixelPosHeight=cumsum(renderPixelSizeHeight,1);
renderPixelPosHeight=[zeros(1,size(renderPixelPosHeight,2)); renderPixelPosHeight(1:end-1,:)];
renderPixelPosWidth=cumsum(renderPixelSizeWidth,2);
renderPixelPosWidth=[zeros(size(renderPixelPosWidth,1),1) renderPixelPosWidth(:,1:end-1)];

%tic;
for rIdx=1:size(mipArray,1)
    for cIdx=1:size(mipArray,2)
        rendert(renderPixelPosHeight(rIdx,cIdx)+(1:renderPixelSizeHeight(rIdx,cIdx)), ... 
                renderPixelPosWidth(rIdx,cIdx)+(1:renderPixelSizeWidth(rIdx,cIdx)),:) = mipArray{rIdx,cIdx};
    end
end

%toc;
%tic;
render=rendert;

% render=arrayfun(@(c) vertcat(mipArray{:,c}),1:size(mipArray,2),'unif',0);
% render=horzcat(render{:});
% F=figure('visible','off');
% [renderPixelSizeWidth renderPixelSizeHeight]
% maxArraySize
% imdisp(mipArray,'FigureSize',maxArraySize);
% render = getframe(F);
% render=render.cdata;

function [processCellArray,frameNb]=managedLegacyProcess(processCellArray)
    nProcess=numel(processCellArray);
    frameNb=nan(1,numel(processCellArray));
    %% Transforming Process to handle the numerous different type of display used in the past (legacy mode)
    for pIdx=1:nProcess
        if(~isempty(processCellArray{pIdx}))
            if(iscell(processCellArray{pIdx}))
                [processCellArray{pIdx},subFrameNb]=managedLegacyProcess(processCellArray{pIdx});
                frameNb(pIdx)=max(subFrameNb);
            else
                %% Handling the previous versions of processes before encapsulations...
                if(isa(processCellArray{pIdx},'ExternalProcess'))
                    processProj=processCellArray{pIdx};
                    if(isa(processProj,'ExternalProcess'))
                        processProjDynROI=ProjectDynROIProcess(processProj.owner_);
                        processProjDynROI.importFromDeprecatedExternalProcess(processProj);
                        try % Handle Project1D/ProjDyn different outFilePaths_spec (need to be defined through a class...)
                            projData=load(processProj.outFilePaths_{projDataIdx},'minXBorder', 'maxXBorder','minYBorder','maxYBorder','minZBorder','maxZBorder','frameNb');
                        catch
                            projDataIdx=4;
                        end
                        projData=load(processProj.outFilePaths_{projDataIdx},'minXBorder', 'maxXBorder','minYBorder','maxYBorder','minZBorder','maxZBorder','frameNb');
                        processProjDynROI.setBoundingBox( [projData.minZBorder projData.maxZBorder], [projData.minZBorder projData.maxZBorder], [projData.minZBorder projData.maxZBorder]);
                        processCellArray{pIdx}=processProjDynROI;
                    end
                end

                if(isa(processCellArray{pIdx},'ProjectDynROIProcess'))
                    processCellArray{pIdx}=ProjAnimation(processCellArray{pIdx},'ortho');
                end
                frameNb(pIdx)=processCellArray{pIdx}.getFrameNb();
                try
                    if(length(processCellArray{pIdx}.outFilePaths_)>1)
                        frameNb(pIdx)=1;
                    end
                catch
                end
            end
        else
            frameNb(pIdx)=0;
        end
    end