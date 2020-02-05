function [ref,cenTrack,RMSE]=ICPIntegrationFirstReg(detections)


pos=detections.getPosMatrix();

covMX=cell(1,numel(pos));

%% Compute cov matrix on the first frame
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
[V,D,W] = eig(covMXI);
[L,sIdx]=sort(-sum(D));
X=V(:,sIdx(1));
Y=V(:,sIdx(2));
Z=cross(X,Y);
covMXI=[X Y Z];
covMX{i}=covMXI;

% Estimate rigid transform between tracked object one frame to the next
% shift the center and FoF basis accordingly.     
meanPos=cellfun(@(p) nanmean(p,1),pos,'unif',0);


% covMX{1}=eye(3);
% meanPos{1}=[0,0,0];
shiftPos=meanPos;
% transforms=cell(1,numel(covMX));


% A=zeros(4);
% A(1:3,1:3)=covMX{1};
% A(4,1:3)=-shiftPos{1}*covMX{1};
% A(4,4)=1;
% transforms{1}=affine3d(A);

pc=pointCloud(pos{1});
% pc=pcdownsample(pc,'random',0.5)
RMSE=zeros(1,numel(covMX));
for i=2:numel(covMX)
	cpc=pointCloud(pos{i});
    pc=pointCloud(pos{1});
    % cpc=pcdownsample(cpc,'random',0.2);
    % pc=pcdownsample(pc,'random',0.2);
	[tform,~,RMSE(i)]=pcregrigid(cpc,pc);   %,'Tolerance',[0.001,0.001],'MaxIterations',100);
	% tform.T(4,1:3)=tform.T(4,1:3);
    covMX{i}=(tform.T(1:3,1:3))*covMX{1};
    shiftPos{i}=tform.transformPointsInverse(shiftPos{1});

	% covMX{i}=covMX{1};
	% shiftPos{i}=shiftPos{i-1}+T;
end
cenTrack=Detections().initFromPosMatrices(shiftPos,shiftPos).buildTracksFromDetection();



% tracksROI=TracksROI([cenTrack; tracks],funParams.fringe,false);

ref=FrameOfRef().setOriginFromTrack(cenTrack);
ref.setBase(covMX);



%% snippet

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
