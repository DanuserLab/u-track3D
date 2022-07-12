function obj=addOffset(obj,X,Y,Z)
   % Philippe Roudot 2017
   if(length(obj)==1)
     obj.x=obj.x+X;
     obj.y=obj.y+Y;
     obj.z=obj.z+Z;
   else
     arrayfun(@(o) o.addOffset(X,Y,Z),obj,'unif',false);
   end
 end
