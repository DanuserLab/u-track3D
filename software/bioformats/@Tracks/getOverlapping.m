function  newTracks=getOverlapping(obj,tracks)
   % Philippe Roudot 2017
   newTracks=obj.copy();
   newTracks.overlapping(tracks);
end
