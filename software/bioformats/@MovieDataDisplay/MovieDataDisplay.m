classdef MovieDataDisplay < handle
    % Abstract class for displaying MovieData components output
    % Delegates drawing methods to the concrete classes
    % Sebastien Besson, July 2011
    
    methods
        function obj=MovieDataDisplay(varargin)
            nVarargin = numel(varargin);
            if nVarargin > 1 && mod(nVarargin,2)==0
                for i=1 : 2 : nVarargin-1
                    obj.(varargin{i}) = varargin{i+1};
                end
            end
        end
        
        function h=draw(obj,data,tag,varargin)
            % Template method to draw a movie data component
            
            % Check input
            
            ip =inputParser;
            ip.addRequired('obj',@(x) isa(x,'MovieDataDisplay'));
            ip.addRequired('data',obj.getDataValidator());
            ip.addRequired('tag',@ischar);
            ip.addParameter('hAxes',gca,@ishandle);
            params = obj.getParamValidators;
            for i=1:numel(params)
                ip.addParameter(params(i).name,obj.(params(i).name),params(i).validator);
            end
            ip.KeepUnmatched = true; % Allow unmatched arguments
            ip.parse(obj,data,tag,varargin{:});
            for i=1:numel(params)
                obj.(params(i).name)=ip.Results.(params(i).name);
            end
            
            % Retrieve the axes handle and call the create figure method 
            hAxes = ip.Results.hAxes;
            set(hAxes,'NextPlot','add');
            
            % Get the component handle and call the adapted draw function
            h = findobj(hAxes,'-regexp','Tag',['^' tag '$']);
            if ~isempty(h) && any(ishandle(h))
                obj.updateDraw(h,data);
            else
                h=obj.initDraw(data,tag,'Parent',hAxes);
            end
        end
    end
    methods(Abstract)
        initDraw(obj,data,tag,varargin)
        updateDraw(obj,h,data,varargin)
    end
    methods (Static,Abstract)
        getDataValidator()
        getParamValidators()
    end           
end