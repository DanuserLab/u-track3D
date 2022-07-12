function [ xml ] = getXML( reader, castToChar)
%getXML Get OME XML metadata from BioformatsReader
%
%
% INPUT
% reader - a BioformatsReader instance
% castToChar - (optional ) if true, cast to MATLAB char. Otherwise, keep as
%              java.lang.String (default: true)
%
% OUTPUT
% xml - XML data
%
% To actually parse the XML output, use getMetadataStore or the following:
% Adapted from comment by StephenLL in http://blogs.mathworks.com/community/2010/06/28/using-xml-in-matlab/
%
% xml = MD.getReader().getXML();
% iS = org.xml.sax.InputSource;
% iS.setCharacterStream( java.io.StringReader(xml) );
% p = xmlread(iS);
%
% For more documentation, see xmlread
%
% See also showMetadata, getMetadataStore, xmlread

% Mark Kittisopikul, May 2017

%     Roundabout way to get to get service, not necessary
%     Problem is that we cannot get the class object for the OMEXMLService
%     directly.
%     impl = loci.formats.services.OMEXMLServiceImpl;
%     implClass = impl.getClass();
%     interfaces = implClass.getInterfaces();
%     omeXMLServiceClass = interfaces(1);
%     
%     factory = loci.common.services.ServiceFactory();
%     
%     service = factory.getInstance(omeXMLServiceClass);

    if(nargin < 2)
        castToChar = true;
    end

    service = loci.formats.services.OMEXMLServiceImpl;
    
    xml = service.getOMEXML(reader.getMetadataStore());
    if(castToChar)
        xml = char(xml);
    end

end

