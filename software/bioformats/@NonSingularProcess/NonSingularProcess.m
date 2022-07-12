classdef NonSingularProcess < Process
    %NONSINGULARPROCESS Process that passes itself as the first argument to
    %function and does not fall back to legacy behavior
    %
    % See also Process.run
    
    properties
    end
    
    methods
        function obj = NonSingularProcess(varargin)
            obj = obj@Process(varargin{:});
        end
        function runLegacy(obj,varargin)
            % Reset sucess flags and existing display methods
            % Runs the funName_ with MovieData handle as first argument
            obj.resetDisplayMethod();
            obj.success_=false;
            
            % Run the process in legacy mode with MovieData handle
            % as first argument!
            obj.startTime_ = clock;
            obj.funName_(obj.getOwner(), varargin{:});
            
            % Update flags and set finishTime
            obj.success_= true;
            obj.updated_= true;
            obj.procChanged_= false;
            obj.finishTime_ = clock;
            
            % Run sanityCheck on parent package to update dependencies
            for packId = obj.getPackageIndex()
                obj.getOwner().getPackage(packId).sanityCheck(false,'all');
            end
            
            obj.getOwner().save();
        end
    end
    
end

