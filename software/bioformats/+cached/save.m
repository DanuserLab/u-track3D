function save( filename, varargin )
%cached.save saves a MAT file as per the builtin save, but also invalidates
%the cache for that file for cached.load
%
% See also save

% Inspired by Sebastien Besson

% Mark Kittisopikul
% December 2014

% execute the builtin save function in the caller workspace
expr = strjoin([filename,varargin],''',''');
expr = [ 'builtin(''save'',''' expr ''')'];
evalin('caller',expr);

% clear the cache for filename
cached.load(filename,'-clear');

end

