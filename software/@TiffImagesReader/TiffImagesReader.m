classdef  TiffImagesReader < TiffSeriesReader
    % TiffImagesReader reads tiff images containing a single imFolder.
    % TiffImagesReader is a reader for ImageData AND ImFolder, it inherits properties
    % and methods from its superclasses, TiffSeriesReader and Reader, but
    % overwrites some methods in its superclasses to fit the special needs
    % for ImageData and ImFolder.
    %
    % TiffImageReader's properties - sizeXmax, sizeYmax, nImages, bitDepthMax, sizeZ, and filenames are overwritable.
    %
    % See also Reader, TiffSeriesReader
    %
    % Qiongjing (Jenny) Zou, June 2020
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
        sizeXmax     % max of the length of the x dimension, horizontal, in one imFolders. If as ImageData.reader, then is a cell array of sizeXmax of all imFolders.
        sizeYmax     % max of the length of the y dimension, vertical, in one imFolders. If as ImageData.reader, then is a cell array of sizeYmax of all imFolders.
        nImages      % number of images in one imFolders. If as ImageData.reader, then is a cell array of nImages of all imFolders. Also see reader.sizeT.
        bitDepthMax     % max of the bitDepth, among all images, in one imFolders. If as ImageData.reader, then is a cell array of bitDepthMax of all imFolders.
    end
    
    methods
        
        % Constructor
        function obj = TiffImagesReader(imFolderPaths,varargin)
            obj = obj@TiffSeriesReader(imFolderPaths,varargin{:});
        end
        
        function getDimensions(obj)
            % Set/update sizeXmax, sizeYmax, nImages, bitDepthMax, sizeZ, and filenames for
            % the reader, and those properties are overwritable.
            
            % QZ sizeZ is always 1, since right now do not consider 3D iamges.
            % QZ Image dimensions and Bit dept do not need to be consistent.
            
            obj.sizeXmax = cell(obj.getSizeC(), 1);
            obj.sizeYmax = cell(obj.getSizeC(), 1);
            obj.nImages = cell(obj.getSizeC(), 1);
            obj.sizeZ = cell(obj.getSizeC(), 1);
            obj.bitDepthMax = cell(obj.getSizeC(), 1);
            for iImFol = 1 : obj.getSizeC()
                fileNames = obj.getImageFileNames(iImFol); % TiffImagesReader.filenames was set here.
                imInfo = cellfun(@(x) imfinfo([obj.paths{iImFol} filesep x]), fileNames, 'unif', 0);
                % sizeX(iChan) = unique(cellfun(@(x)(x.Width), imInfo));
                % sizeY(iChan) = unique(cellfun(@(x)(x.Height), imInfo));
                obj.sizeXmax{iImFol} = max(cellfun(@(x)(x.Width), imInfo));
                obj.sizeYmax{iImFol} = max(cellfun(@(x)(x.Height), imInfo));
                
                
                if length(fileNames)>1
                    obj.sizeZ{iImFol} = unique(cellfun(@numel, imInfo));
                    obj.nImages{iImFol} = length(fileNames);
                else % if single file, assume stack and check for # of files
                    if(obj.force3D)
                        info = imfinfo(fullfile(obj.paths{iImFol}, fileNames{1}));
                        obj.nImages{iImFol} = 1;
                        obj.sizeZ{iImFol} = numel(info);
                    else
                        info = imfinfo(fullfile(obj.paths{iImFol}, fileNames{1}));
                        obj.nImages{iImFol} = numel(info);
                        obj.sizeZ{iImFol} = 1 ;
                    end
                end
                obj.bitDepthMax{iImFol} = max(cellfun(@(x)(x.BitDepth), imInfo));
            end

            if obj.getSizeC() == 1
                obj.sizeXmax = obj.sizeXmax{:};
                obj.sizeYmax = obj.sizeYmax{:};
                obj.nImages = obj.nImages{:};
                obj.sizeZ = obj.sizeZ{:};
                obj.bitDepthMax = obj.bitDepthMax{:};
            end
        end
        
        function nImages = getNumImages(obj)
            % QZ allow adding more images to the ImFolder, and update
            % nImages
            obj.getDimensions();
            nImages = obj.nImages;
        end
        
        function filenames = getImageFileNames(obj, iImFol, iImage)
            % QZ to overwrite TiffSeriesReader.getImageFileNames
            % Allow filenames to be overwritable.
            
            obj.checkPath(iImFol);
            [files, nofExt] = imDir(obj.paths{iImFol}, true);
            assert(nofExt~=0,['No proper image files are detected in:'...
                '\n\n%s\n\nValid image file extension: tif, TIF, STK, bmp, BMP, jpg, JPG.'],obj.paths{iImFol});
            assert(nofExt==1,['More than one type of image files are found in:'...
                '\n\n%s\n\nPlease make sure all images are of same type.'],obj.paths{iImFol});
            
            obj.filenames{iImFol} = arrayfun(@(x) x.name, files, 'unif', 0);
            
            % if index has been supplied & frames are not stored in single stack
            if nargin>2 && ~obj.isSingleMultiPageTiff(iImFol)
                filenames = obj.filenames{iImFol}(iImage);
            else
                filenames = obj.filenames{iImFol};
            end
        end
    end
end