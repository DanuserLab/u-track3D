function C = plus(A,B,outputDirectory)
% Override plus (+) operation to create a unique union of two MovieLists
%
% Use the plus function explicitly to specify an output directory other
% than pwd
%
% See also plus, unique

% Mark Kittisopikul, March 2018
% Goldman Lab
% Northwestern University

    if(nargin < 3)
        outputDirectory = pwd;
    end
    A_isMovieList = isa(A,'MovieList');
    A_isMovieData = isa(A,'MovieData');

    B_isMovieList = isa(B,'MovieList');
    B_isMovieData = isa(B,'MovieData');

    assert(A_isMovieList || B_isMovieList);

    if(A_isMovieData)
        A = MovieList(A);
    end
    if(B_isMovieData)
        B = MovieList(B);
    end
    C  = MovieList(unique([A.movieDataFile_ B.movieDataFile_]),outputDirectory);
end