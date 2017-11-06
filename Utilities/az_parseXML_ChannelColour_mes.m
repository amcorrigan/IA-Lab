function o_struct = az_parseXML_ChannelColour_mes(i_fileName)
% 
% i_fileName = '\\UK-Image-01\HCB\Technology Eval\Automated confocal\Yokogawa CV7000\CV7000 Demo Data\Corrected Images\Bead 96well_20140827_122725\AssayPlate_BD_#353219\JP_60x_beads_96w_4col.mes'

    try
       tree = xmlread(i_fileName);
    catch
       error('Failed to read XML file %s.',i_fileName);
    end

    % Recurse over child nodes. This could run into problems 
    % with very deeply nested trees.
    try
       xmlStruct = parseChildNodes(tree);
    catch
       error('Unable to parse XML file %s.',i_fileName);
    end
 
%%____________________________________________________________
%%
    counter = 0;

    for i = 1:length(xmlStruct.Children)
        
        if strcmp(xmlStruct.Children(i).Name, 'bts:ChannelList') == true

            for j = 1:length(xmlStruct.Children(i).Children)
                if strcmp(xmlStruct.Children(i).Children(j).Name, 'bts:Channel') == true
        
                    counter = counter + 1;
                    o_struct(counter).Ch = uint8(str2double(xmlStruct.Children(i).Children(j).Attributes.Ch));
                    o_struct(counter).Colour(1) = hex2dec(xmlStruct.Children(i).Children(j).Attributes.Color(4:5))/255;
                    o_struct(counter).Colour(2) = hex2dec(xmlStruct.Children(i).Children(j).Attributes.Color(6:7))/255;
                    o_struct(counter).Colour(3) = hex2dec(xmlStruct.Children(i).Children(j).Attributes.Color(8:9))/255;
                end;
            end;
            break;
        end;
    end;
    
end


% ----- Local function PARSECHILDNODES -----
function children = parseChildNodes(theNode)
% Recurse over node children.
    children = [];
    if theNode.hasChildNodes
       childNodes = theNode.getChildNodes;
       numChildNodes = childNodes.getLength;
       allocCell = cell(1, numChildNodes);

       children = struct(             ...
          'Name', allocCell, ...
          'Attributes', allocCell,    ...
          'Children', allocCell);

        for count = 1:numChildNodes
            theChild = childNodes.item(count-1);
            children(count) = makeStructFromNode(theChild);
        end
    end
end

% ----- Local function MAKESTRUCTFROMNODE -----
function nodeStruct = makeStructFromNode(theNode)
% Create structure of node info.

    nodeStruct = struct(                        ...
       'Name', char(theNode.getNodeName),       ...
       'Attributes', parseAttributes(theNode),  ...
       'Children', parseChildNodes(theNode));
end

% ----- Local function PARSEATTRIBUTES -----
function attributes = parseAttributes(theNode)
% Create attributes structure.

    attributes = [];
    if theNode.hasAttributes
       theAttributes = theNode.getAttributes;
       numAttributes = theAttributes.getLength;

        %-- Delete the leading 'dts:' if any
        token = 'bts:';

        for count = 1:numAttributes
            attrib = theAttributes.item(count-1);

            %-- Delete the leading 'dts:' if any
            aName = char(attrib.getName);

            [~,endIndex] = regexp(aName,token);

            if ~isempty(endIndex)
                tempName = aName(endIndex + 1 : end);
                attributes.(tempName) = char(attrib.getValue);
            end
        end;
    end
end