function [ metaWindow ] = showMetadata( reader )
%showOMEXML Show OME XML metadata in a GUI like in the ImageJ plugin
%
% INPUT
% reader - a BioformatsReader such as from MovieData.getReader()
%
% OUTPUT
% metaWindow - a reference to the Java window of class loci.formats.gui.XMLWindow
%
% See also getXML, getMetadataStore

    % Get XML as java.lang.String
    xml = reader.getXML(false);
    
    metaWindow = loci.formats.gui.XMLWindow(['OME MetaData ' reader.id]);
    metaWindow.setXML(xml);
    metaWindow.setVisible(true);


end

