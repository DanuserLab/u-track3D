classdef FigDisplay < MovieDataDisplay
    %Concreate class to display general figure plot
    % Andrew R. Jamieson Mar 2017
    
    properties
        plotFunc = @plot; 
        plotFunParams = {};
    end

    methods
        function obj=FigDisplay(varargin)
            obj@MovieDataDisplay(varargin{:})
        end
        
        function h = initDraw(obj, data, tag, varargin)

            ip =inputParser;
            ip.addParameter('Parent', [], @ishandle);
            ip.parse(varargin{:})
            parent_h = ip.Results.Parent;
            if all(cellfun(@isempty,obj.plotFunParams))
                h = obj.plotFunc(data);    
            elseif ~isempty(data) && ~isstruct(data) && ~isa(data.obj,'MovieData') && ~isa(data.obj,'Process')
                h = obj.plotFunc(data, obj.plotFunParams{:});
            elseif isstruct(data) && (isa(data.obj,'MovieData') || isa(data.obj,'Process'))
                h = obj.plotFunc(data, obj.plotFunParams{:},'figHandleIn',parent_h);
            end
            set(h,'Tag', tag);
        end
        function updateDraw(obj, h, data)   
        end  
    end 

    methods (Static)
        function params=getParamValidators()
            params(1).name = 'plotFunc';
            params(1).validator = @(A)validateattributes(A,{'function_handle'},{'nonempty'});
            params(2).name = 'plotFunParams';
            params(2).validator = @iscell;
        end
        function f=getDataValidator()
            f=@(x)isstruct(x) || isa(x,'MovieData') || isa(x,'Process');% (A)validateattributes(A,{'struct'},{'nonempty'});
        end
    end    
end