function  newTracks=getMultCoord(obj,scalarOrArray)
   % Philippe Roudot 2017
   newTracks=obj.copy();
   newTracks.multCoord(scalarOrArray);
end
