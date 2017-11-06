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