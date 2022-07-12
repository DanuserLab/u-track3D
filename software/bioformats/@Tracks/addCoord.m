function obj=addCoord(obj,tracks)
   % tracks.addCoord(TracksToAdd)
   % addition coordinate, lifetime must interset
   % TODO: 
   % Philippe Roudot 2017
   
   if((length(tracks)~=1)&&(length(tracks)~=length(obj)))
      error('Added tracks set must have the same size or unitary.')
   end

   if(length(obj)==1)
     tr=tracks.getOverlapping(obj);
     if(obj.lifetime~=tr.lifetime)
             error('tracks lifetime must overlap entirely with obj')
      end
          
     obj.x=obj.x+tr.x;
     obj.y=obj.y+tr.y;
     obj.z=obj.z+tr.z;
   else
    if(length(tracks)==1)
      arrayfun(@(o) o.addCoord(tracks),obj,'unif',0);
    else
      arrayfun(@(o,t) o.addCoord(t),obj,tracks,'unif',0);
   end
 end
