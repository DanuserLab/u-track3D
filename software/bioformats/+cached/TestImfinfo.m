classdef TestImfinfo < TestCase
% Tests cached.imfinfo
    properties
        filename
    end
    methods
        function self = TestImfinfo(varargin)
            self = self@TestCase(varargin{:});
        end
        function setUp(self)
            self.filename = [ tempname '.tif' ];
            S = load('clown');
            imwrite(S.X,self.filename);
        end
        function tearDown(self)
            cached.imfinfo('-clear');
            delete(self.filename);
        end
        function testFilename(self,varargin)
            [S, wasCached] = cached.imfinfo(self.filename,varargin{:});
        end
        function testFilenameFmt(self,varargin)
            [S, wasCached] = cached.imfinfo(self.filename,'tif',varargin{:});
        end
        function testModification(self,varargin)
            [S, wasCached] = cached.imfinfo(self.filename,varargin{:});
            assert(~wasCached);
            [S, wasCached] = cached.imfinfo(self.filename,varargin{:});
            assert(wasCached);
            
            X = imread('cameraman.tif');
            imwrite(X,self.filename);
            [S, wasCached] = cached.imfinfo(self.filename,varargin{:});
            assert(~wasCached);

            % check modification after one second
            pause(1);
            imwrite(X,self.filename);
            [S, wasCached] = cached.imfinfo(self.filename,varargin{:});
            assert(~wasCached);
        end
        function testReset(self,varargin)
            [S, wasCached] = cached.imfinfo(self.filename,varargin{:});
            assert(~wasCached);
            [S, wasCached] = cached.imfinfo(self.filename,varargin{:});
            assert(wasCached);
            [S, wasCached] = cached.imfinfo(self.filename,varargin{:},'-reset');
            assert(~wasCached);
        end
        function testUseCache(self,varargin)
            [~, wasCached] = cached.imfinfo(self.filename,varargin{:},'-useCache',true);
            assert(~wasCached);
            [~, wasCached] = cached.imfinfo(self.filename,varargin{:},'-useCache',true);
            assert(wasCached);
            [S, wasCached] = cached.imfinfo(self.filename,varargin{:},'-useCache',false);
            assert(~wasCached);
        end
        function testClear(self,varargin)
            [S, wasCached] = cached.imfinfo(self.filename,varargin{:});
            assert(~wasCached);
            [S, wasCached] = cached.imfinfo(self.filename,varargin{:});
            assert(wasCached);
            cached.imfinfo(self.filename,varargin{:},'-clear');
            [S, wasCached] = cached.imfinfo(self.filename,varargin{:});
            assert(~wasCached);
        end
        function testClearAll(self)
            [~, wasCached] = cached.imfinfo(self.filename);
            assert(~wasCached);
            
            [~, wasCached] = cached.imfinfo(self.filename);
            assert(wasCached);
             
            cached.imfinfo('-clear');
            
            [~, wasCached] = cached.imfinfo(self.filename);
            assert(~wasCached);
        end
        
    end
end