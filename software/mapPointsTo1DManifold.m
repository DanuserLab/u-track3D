function [mappedPointIdxMask,dist]=mapPointsTo1DManifold(points,manifold,cutoff,varargin)
ip = inputParser;
ip.CaseSensitive = false;
ip.KeepUnmatched = true;
ip.addParameter('distType','normalDistPseudOptimized');
ip.parse(varargin{:});
p=ip.Results;

if(isempty(points))
    mappedPointIdxMask=[];
    dist=[];
    return;
end

manifOrig=manifold(:,1);
manifVector=manifold(:,2)-manifOrig;
normManifVector=norm(manifVector);

%% reduce the number of point with KDTree
%% WARNING: we exclude the full sphere!
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
nDet=size(points,2);
% [idx] = KDTreeBallQuery(points',manifOrig',normManifVector+cutoff);
% points=points(:,idx{1});
% mappedPointIdx=find(idx{1});

mappedPointIdx=1:size(points,2);
trackVector=points-repmat(manifOrig,1,size(points,2));



mappedPoint=[];
dist=[];
switch p.distType
    case 'normalDistAndAngle'
        %   distP1=sin(MTAnglesP1Kin).*norm(trackVector);
        %   assocMTP1Kin=TracksTracks(P1KinAssociatedMTIndex((distP1<cutoff)&(abs(tracksAngle)<p.angleCutoff)));
        error('not implemented')
    case 'normalDist'
        tracksAngle= vectorAngleND(trackVector,manifVector);
        tracksDist=sum(trackVector.^2,1).^(0.5);
        dist=sin(tracksAngle).*tracksDist;
        mappedPoint=((dist<cutoff)&(abs(tracksAngle)<pi/2)&(tracksDist<sum(manifVector.^2,1).^(0.5)));
    case 'cone'
        tanAngleCutoff=tan(cutoff);
        normVecRep=repmat(manifVector/normManifVector,1,size(points,2));
        projPara=dot(trackVector,normVecRep);
        inBound=(projPara>=0)&(projPara<=normManifVector);
        mappedPoint=inBound;
        dist=zeros(size(mappedPoint));
        if(any(inBound))
            dist(inBound)=sum((trackVector(:,inBound)- normVecRep(:,inBound).*repmat(projPara(inBound),3,1)).^2,1).^0.5;
            mappedPoint(dist>(projPara.*tanAngleCutoff))=0;
            dist(mappedPoint==0)=0;
            dist(mappedPoint==1)=atan(dist(mappedPoint==1)./projPara(mappedPoint==1));
        end
    case 'euclideanDist'
        tracksAngle= vectorAngleND(trackVector,manifVector);
        tracksDist=sum(trackVector.^2,1).^(0.5);
        dist=sin(tracksAngle).*tracksDist;
        trackVector2=points-repmat(manifold(:,2),1,size(points,2));
        tracksDist2=sum(trackVector2.^2,1).^(0.5);
        mappedPoint=(((dist<cutoff)&(abs(tracksAngle)<pi/2)&(tracksDist<sum(manifVector.^2,1).^(0.5))) ... 
                    |(tracksDist<cutoff)|(tracksDist2<cutoff));
    case 'normalDistPseudOptimized'
        normVecRep=repmat(manifVector/normManifVector,1,size(points,2));
        projPara=dot(trackVector,normVecRep);
        inBound=(projPara>=0)&(projPara<=normManifVector);
        mappedPoint=inBound;
        dist=zeros(size(mappedPoint));
        if(any(inBound))
            dist(inBound)=sum((trackVector(:,inBound)- normVecRep(:,inBound).*repmat(projPara(inBound),3,1)).^2,1).^0.5;
            mappedPoint(dist>cutoff)=0;
            dist(dist>cutoff)=0;
        end
    case 'euclideanPseudOptimized'
        normVecRep=repmat(manifVector/normManifVector,1,size(points,2));
        projPara=dot(trackVector,normVecRep);
        inBound=(projPara>=-cutoff)&(projPara<=normManifVector+cutoff);
        mappedPoint=inBound;
        dist=zeros(size(mappedPoint));
        if(any(inBound))
            % dist 
            dist(inBound)=sum((trackVector(:,inBound)- normVecRep(:,inBound).*repmat(projPara(inBound),3,1)).^2,1).^0.5;
            mappedPoint(dist>cutoff)=0;
            mappedPoint(projPara<0)=(dist(projPara<0)<(cutoff.^2-projPara(projPara<0).^2).^.5);
            mappedPoint(projPara>normManifVector)=dist(projPara>normManifVector)<(cutoff.^2-projPara(projPara>normManifVector).^2).^.5;
            dist(dist>cutoff)=0;
        end
    case 'vertexDistOtsu'
        pointDist=points-repmat(manifold(:,1),1,size(points,2));
        minDist=sum(pointDist.^2,1).^(0.5);
        for mIdx=2:size(manifold,2)
            pointDist=points-repmat(manifold(:,mIdx),1,size(points,2));
            tmpMinDist=sum(pointDist.^2,1).^(0.5);
            minDist=min(tmpMinDist,minDist);
        end
        l=graythresh(double(minDist)/max(minDist))*max(minDist);
        mappedPoint=minDist<l;
        dist=minDist;
        dist(mappedPoint==0)=1;
    otherwise
        error('not implemented')
end

mappedPointIdxMask=false(1,nDet);
mappedPointIdxMask(mappedPointIdx(mappedPoint))=true;
end

function angle=vectorAngleND(a,b)
  if (size(a,2)==1)
    a=repmat(a,1,size(b,2));
  end
  if (size(b,2)==1)
    b=repmat(b,1,size(a,2));
  end
  f=@(a,b)atan2(norm(cross(a,b)), dot(a,b));
  angle=arrayfun(@(i) f(a(:,i),b(:,i)),1:size(a,2));
end
