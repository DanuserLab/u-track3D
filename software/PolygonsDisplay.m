classdef PolygonsDisplay < MovieDataDisplay
    %Concreate class to display polygons on 2D
    % Qiongjing (Jenny) Zou, August 2019
%
% Copyright (C) 2020, Danuser Lab - UTSouthwestern 
%
% This file is part of NewUtrack3DPackage.
% 
% NewUtrack3DPackage is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% NewUtrack3DPackage is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with NewUtrack3DPackage.  If not, see <http://www.gnu.org/licenses/>.
% 
% 
    
    properties
        Color='r';
        Marker = 'none';
        MarkerSize = 6; 
        LineStyle = '-';
        LineWidth = 1;
        XLabel='';
        YLabel='';
        sfont = {'FontName', 'Helvetica', 'FontSize', 18};
        lfont = {'FontName', 'Helvetica', 'FontSize', 22};
        ButtonDownFcn=[];
    end

    methods
        function obj=PolygonsDisplay(varargin)
            obj@MovieDataDisplay(varargin{:})
        end
        
        function h=initDraw(obj,data,tag,varargin)
            % Plot data and set graphical options
            if(isempty(data))
                h=line([],[],varargin{:});
            else
                for eIdx=1:size(data,2)
                    h(eIdx)=line(data{1,eIdx}(1,[1 3]),data{1,eIdx}(1,[2 4]));
                    obj.setLineProperties(h);
                    set(h(eIdx),'Tag',tag);
                end
            end
            % obj.setAxesProperties();
        end

        function updateDraw(obj, h, data)
            % Update handle xData and yData
            if(~isempty(data))
                if size(h,1) == size(data,2)
                    for eIdx=1:size(data,2)
                        set(h(eIdx),'XData',data{1,eIdx}(1,[1 3]),'YData',data{1,eIdx}(1,[2 4]));
                    end
                else
                    % when switch from one projection to three projections:
                    tag = h(1).Tag;
                    delete(h);
                    h=initDraw(obj,data,tag);
                end
            else
                set(h,'XData',[],'YData',[]);
            end
        end
        
        function setLineProperties(obj, h)
            set(h, 'MarkerSize', obj.MarkerSize,...
                'Color', obj.Color, 'Marker',obj.Marker,...
                'Linestyle', obj.LineStyle, 'LineWidth', obj.LineWidth,...
                'ButtonDownFcn', obj.ButtonDownFcn);
        end

    end 

    methods (Static)
        function params=getParamValidators()
            params(1).name='Color';
            params(1).validator=@(x)(ischar(x) || (numel(x)==3 && isnumeric(x)));
            params(2).name='Marker';
            params(2).validator=@ischar;
            params(3).name='LineStyle';
            params(3).validator=@ischar;
            params(4).name='LineWidth';
            params(4).validator=@isscalar;
            params(5).name='XLabel';
            params(5).validator=@ischar;
            params(6).name='YLabel';
            params(6).validator=@ischar;
            params(7).name='sfont';
            params(7).validator=@iscell;
            params(8).name='lfont';
            params(8).validator=@iscell;
            params(9).name='MarkerSize';
            params(9).validator=@isscalar;
            params(10).name='ButtonDownFcn';
            params(10).validator=@(x) isempty(x) || isa(x, 'function_handle');
        end

        function f=getDataValidator()
            f=@iscell;
        end
    end    
end