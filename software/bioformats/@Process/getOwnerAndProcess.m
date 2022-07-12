function [ movieObject, process, processID ] = getOwnerAndProcess( process, processClass, createProcessIfNoneExists, varargin )
%getMovieObjectAndProcess Get the MovieObject and indicated Process
%instance
%
% INPUT
% movieObjectOrProcess:      Either a MovieObject instance or a Process instance
% processClass:              String, Process, or meta.class indicating
%                             the class of the Process we are looking for
% createProcessIfNoneExists: logical indicating whether to create the process if it
%                             does not exist (optional, default: false)
% Extra arguments will be passed to the constructor if creating a new
% process
%
% OUTPUT
% movieObject: MovieObject handle that owns the Process
% process: Process handle of type processClass, empty if it does not exist
%          and createProcess is false
% processID: index value of the Process in movieObject
%
% See also MovieObject.getOwnerAndProcess, Process.getOwnerAndProcess

% Mark Kittisopikul, February 2016

narginchk(2,3);

if(~ischar(processClass))
    if(isa(processClass,'Process'))
        processClass = class(processClass);
    elseif(isa(processClass,'meta.class'))
        processClass = processClass.Name;
    else
        error('MovieObject:getProcessObjectAndProcess', ... 
            'The 2nd argument, processClass, is not a string, Process, or a meta.class');
    end
end

assert(isa(process,processClass),'Process:getOwnerAndProcess','Process provided is of class %s and not of class %s',class(process), processClass);

movieObject = process.getOwner();

if(nargout > 2)
    processID = find(cellfun(@(proc) proc == process,movieObject.processes_));
end

end

