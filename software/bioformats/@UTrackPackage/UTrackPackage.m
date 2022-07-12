classdef UTrackPackage < TrackingPackage
    % A concrete process for UTrack Package
    
    methods (Access = public)
        function obj = UTrackPackage(varargin)
            % Call the superclass constructor
            obj = obj@TrackingPackage(varargin{:});
        end
        
    end
    methods (Static)

        function procConstr = getDefaultProcessConstructors(index)
            procConstr = {
                @SubResolutionProcess,...
                @(x,y)TrackingProcess(x,y,UTrackPackage.getDefaultTrackingParams(x,y)),...
                @MotionAnalysisProcess};
            if nargin==0, index=1:numel(procConstr); end
            procConstr=procConstr(index);
        end
        
        function funParams = getDefaultTrackingParams(owner,outputDir)
            funParams = TrackingProcess.getDefaultParams(owner,outputDir);

            % Set default kalman functions
            funParams.kalmanFunctions = TrackingProcess.getKalmanFunctions(1);

            % Set default cost matrices
            funParams.costMatrices(1) = TrackingProcess.getDefaultLinkingCostMatrices(owner, funParams.gapCloseParam.timeWindow,1);
            funParams.costMatrices(2) = TrackingProcess.getDefaultGapClosingCostMatrices(owner, funParams.gapCloseParam.timeWindow,1);
        end
        
        function varargout = GUI(varargin)
            % Start the package GUI
            varargout{1} = uTrackPackageGUI(varargin{:});
        end
    end
    
end