function plot(tracks,varargin)
   % Tracks.plot
   % See plotTracks2D for I/O
   % tracks are passed to plotTracks2D so that the numbering corresponds
   % to the index property
   %
   % See also plotTracks2D
   %
   % July 9th, 2015
   % Mark Kittisopikul
   % Jaqaman Lab
   % UT Southwestern
   
   % In order to for the selection tool to display the correct index
   % construct a fake larger array with null coordinates
   if(all(~cellfun('isempty',{tracks.index})))
       % convert to tracksStruct since we use legacy plotTracks2D
       tracksStruct = TracksStruct(tracks);
       tracksStruct.reindex([tracks.index]);
       
       T([tracks.index]) = tracksStruct;
       nullTracks = cellfun('isempty',{T.index});
       if(any(nullTracks))
            [T(nullTracks).tracksCoordAmpCG] = deal(NaN(1,8));
            [T(nullTracks).seqOfEvents] = deal([1 1 1 NaN
                                                1 2 1 NaN]);
       end
       disp('Tracks.plot numbers tracks according to the index property');
   else
       % If index is unset for some reason, do not attempt to reindex
       T = tracks;
   end
   % Use the legacy plotTracks2D
   plotTracks2D(T,varargin{:}); 
end
