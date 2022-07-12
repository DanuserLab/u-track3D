function  obj=addSphericalCoord(obj,tracks)
   % Philippe Roudot 2017
   for fIdx=1:length(obj)
       track=obj(fIdx);
       try
           track.addprop('azimuth');      
           track.addprop('elevation');    
           track.addprop('rho');          
       catch
       end
       [track.azimuth,track.elevation,track.rho]=cart2sph(track.x,track.y,track.z);
   
   end   
end
