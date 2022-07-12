function  newTracks=getAddCoord(obj,tracks)
   % tracks.addCoord(TracksToAdd)
   % add the coordinate when two tracks have the same lifetime.
   % the temporal window of /obj/ is kept if both tracks have different temporal window.
   %
   % Philippe Roudot 2017
   newTracks=obj.copy();
   newTracks.addCoord(tracks);
end
