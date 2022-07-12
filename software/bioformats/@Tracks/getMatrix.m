function matrix = getMatrix(obj,frames)
% Tracks.getMatrix gets the track information as a 2D matrix
%
% INPUT:
%
% frames can be scalar, a pair of time points, or a sequence of frames
%   scalar: Information about frames 1:frames is included. Dimensions are Nxframes
%     pair: Information about frames(1):frames(2) is included. Dimensions are Nx(frames(2)-frames(1)+1)
%   vector: Information about frames as a vector are included. Dimensions are N x length(frames)
%
% Note: frames can be any arbitrary vector. The values need not be consecutive or in order.
%
% OUTPUT:
%
% matrix: A 2D matrix with dimensions totalSegments x (8 * numTimePoints)
%  rows correspond to each segment
%  columns correspond to the frames information requested
%
% Consider reshaping matrix: 
% matrix3D = reshape(matrix,size(matrix,1),8,[]);
%
% For matrix(:,n:8:end) or matrix3D(:,n,:)
% x: n = 1
% y: n = 2
% z: n = 3
% A: n = 4
%
% Uncertainties:
% dx: n = 5
% dy: n = 6
% dz: n = 7
% dA: n = 8
%
% See also convStruct2MatNoMS, convStruct2MatIgnoreMS

% Mark Kittisopikul, January 2015

    % default is the number of time points for all the tracks in the array
    if(nargin < 2)
        frames = obj.numTimePoints;
    end
    switch(length(frames))
        case 1
            numTimePoints = frames;
            frames = 1:frames;
        case 2
            frames = frames(1):frames(2);
            numTimePoints = length(frames);
        otherwise
            numTimePoints = length(frames);
    end
    if(numel(obj) == 1)
        % for a single set of compound tracks, we just need to pad tracksCoordAmpCG with NaN
        matrix = NaN(obj.numSegments,8,numTimePoints);
        % limit the frames that we access to those within the time frame
        frameFilter = frames >= obj.startFrame & frames <= obj.endFrame;
        frames = frames(frameFilter);
        % translate the frames relative to the start time within the requested frames
        matrix(:,:,frameFilter) = obj.tracksCoordAmpCG3D(:,:,frames - obj.startFrame + 1);
    else
        % for an array of compound tracks get a cell array of matrices
        matrices = arrayfun(@(x) x.getMatrix(frames),obj,'UniformOutput',false);
        % vertically concatenate the matrices along segments dimension
        % matrix should have dimensions totalSegments x 8 x numTimePoints
        matrix = vertcat(matrices{:});
    end
    % make 2D totalSegments x (8 * numTimePoints)
    matrix = matrix(:,:);
end
