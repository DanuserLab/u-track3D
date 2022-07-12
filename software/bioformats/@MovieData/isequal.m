function [ tf ] = isequal( obj, MD, varargin )
%isequal Compare two or more MovieData objects
     if(isequal(size(obj),size(MD)))
         if(numel(obj) > 1)
             tf = all(arrayfun(@isequal,obj,MD));
         elseif(isempty(obj))
             tf = true;
         elseif(isa(obj,'MovieData') && isa(MD,'MovieData'))
             % Two MovieData are the same if they will be saved in the same
             % place
             tf = obj == MD || ...
                  strcmp(obj.movieDataPath_,MD.movieDataPath_) && ...
                  strcmp(obj.movieDataFileName_,MD.movieDataFileName_);
         else
             tf = false;
         end
     else
         tf = false;
     end
     if(tf && nargin > 2)
         tf = isequal(obj,varargin{1},varargin{2:end});
     end
end

