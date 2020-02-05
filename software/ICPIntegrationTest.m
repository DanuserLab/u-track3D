function [ref,transforms,RMSE]=ICPIntegrationTest(detections)

% Find the track center
% names={};
% medianPos=cellfun(@(p) nanmedian(p,1),pos,'unif',0)
% cenTrack=Detections().initFromPosMatrices(medianPos,medianPos).buildTracksFromDetection();
% allCenter=cenTrack.x;
% names=[names {'median'}];
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

% cenTrack=Detections().initFromPosMatrices(meanPos,medianPos).buildTracksFromDetection();
% allCenter=[allCenter;cenTrack.x];
% names=[names {'mean'}];

% meanRobust=cell(1,numel(meanPos));
% weigths=cell(1,numel(meanPos));

% for fIdx=1:numel(pos)
%     p=pos{fIdx};
%     M=meanPos{fIdx};
%     distances=sum((p-M).^2,2).^0.5;
%     sigma = 1.4826*mad(distances,1);
%     err=1;
%     NIter=0;
%     while err>0.001
%         distances=sum((p-M).^2,2).^0.5;
%         distances=(distances/(3*sigma));
%         w = (abs(distances)<1) .* (1 - distances.^2).^2;
%         Mprev=M;
%         M=sum(w.*p,1)/sum(w);
%         err=sum((M-Mprev).^2)/sum(Mprev.^2);
%         NIter=NIter+1;
%     end 
%     NIter;
%     meanRobust{fIdx}=M;
%     weigths{fIdx}=w;
% end

% cenTrack=Detections().initFromPosMatrices(meanRobust,meanRobust).buildTracksFromDetection();
% allCenter=[allCenter;cenTrack.x];
% names=[names {'robust'}]; 

pos=detections.getPosMatrix();

covMX=cell(1,numel(pos));

%% Compute cov matrix on the first frame
i=1;
x=pos{i}(:,1);
y=pos{i}(:,2);
z=pos{i}(:,3);
N=size(pos{i},1);
CovXY=(x-mean(x))'*(y-mean(y))/(N-1);
CovYX=CovXY;
CovXZ=(x-mean(x))'*(z-mean(z))/(N-1);
CovZX=CovXZ;
CovYZ=(y-mean(y))'*(z-mean(z))/(N-1);
CovZY=CovYZ;
covMXI=[var(x) CovXY  CovXZ;CovYX   var(y)   CovYZ; CovZX   CovZY    var(z)];

% Compute orthogonal basis and use it for the frame of reference of the first frame
[V,D,W] = eig(covMXI)
[L,sIdx]=sort(-sum(D));
X=V(:,sIdx(1));
Y=V(:,sIdx(2));
Z=cross(X,Y);
covMXI=[X Y Z];
covMX{i}=covMXI;

% Estimate rigid transform between tracked object one frame to the next
% shift the center and FoF basis accordingly.     
meanPos=cellfun(@(p) nanmean(p,1),pos,'unif',0);

shiftPos=meanPos;
transforms=cell(1,numel(covMX));


A=zeros(4);
A(1:3,1:3)=covMX{1};
A(4,1:3)=-shiftPos{1}*covMX{1};
A(4,4)=1;
transforms{1}=affine3d(A);

pc=pointCloud(pos{1});
RMSE=zeros(1,numel(covMX))
for i=2:numel(covMX)
	% [tform,pc]=pcregrigid(pointCloud(pos{i}),pc);
	% transforms{i}=tform;
	% covMX{i}=tform.T(1:3,1:3);
	% shiftPos{i}=-tform.T(4,1:3)*inv(covMX{i})';

	% B=covMX{i-1};
	% tformNoOrig=tform;
	% tformNoOrig.T(4,1:3)=0;
	% X =  tformNoOrig.transformPointsInverse(B(1,:));
	% Y =  tformNoOrig.transformPointsInverse(B(2,:));
	% Z =  tformNoOrig.transformPointsInverse(B(3,:));
	% % covMX{i}=tform.transformPointsInverse(covMX{i-1});
	% covMX{i}=[X;Y;Z];


	% shiftPos{i}=tform.transformPointsInverse(shiftPos{i-1});

	[tform,~,RMSE(i)]=pcregrigid(pointCloud(pos{i}),pointCloud(pos{i-1}),'Tolerance',[0.00001,0.00001],'MaxIterations',100,'Extrapolate',true);
	transforms{i}=tform;
	covMX{i}=tform.T(1:3,1:3)*covMX{i-1};
	shiftPos{i}=tform.transformPointsInverse(shiftPos{i-1});
end
cenTrack=Detections().initFromPosMatrices(shiftPos,shiftPos).buildTracksFromDetection();



% tracksROI=TracksROI([cenTrack; tracks],funParams.fringe,false);

ref=FrameOfRef().setOriginFromTrack(cenTrack);
ref.setBase(covMX);