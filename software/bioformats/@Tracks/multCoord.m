function obj=multCoord(obj,scalarOrArray)
   % Philippe Roudot 2017

   if(length(obj)==1)
     obj.x=obj.x.*scalarOrArray;
     obj.y=obj.y.*scalarOrArray;
     obj.z=obj.z.*scalarOrArray;
   else
     arrayfun(@(o) o.multCoord(scalarOrArray),obj,'unif',0);
   end
 end
