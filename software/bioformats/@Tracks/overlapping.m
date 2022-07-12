function obj=overlapping(obj,tr)
 % Does not work with merge and split
 % Philippe Roudot 2017
  if(length(obj)==1)
    [F,idxTr,idxObj] = intersect(tr.f,obj.f);
    % M=obj.tracksCoordAmpCG;
    % M=M(8*(min(F)-1)+(1:(8*numel(F))),:);
    % M=[nan(size(M,1),min(F)-1)  M];
    % obj=TracksHandle(M);
    obj.startFrame=min(F);
    obj.endFrame=max(F);
    obj.segmentStartFrame=min(F);
    obj.segmentEndFrame=max(F);
    obj.endFrame=max(F);
    obj.x=obj.x(idxObj);
    obj.y=obj.y(idxObj);
    obj.z=obj.z(idxObj);
  else
    arrayfun(@(o,t) o.overlapping(t),obj,tracks );
  end
end
