function expandIdx = expandCellIndices(cellidx)

% expand the cell indices cellidx into a list of permutations

% use a recursive function?
expandIdx = recurseexpand(cellidx{1},cellidx(2:end));


end

function expandIdx = recurseexpand(currlist,remcellidx)
    % for every element of currlist, combine with each element of the next cellidx
    % and then call the next level down
    try
    if isempty(remcellidx)
        expandIdx = currlist;
    else
        initlen = size(currlist,1);

        nextlen = numel(remcellidx{1});

        newidx = [currlist(ceil((1:(initlen*nextlen))/nextlen),:), repmat(remcellidx{1}(:),[initlen,1])];
        
        expandIdx = recurseexpand(newidx,remcellidx(2:end));
        
    end
    catch ME
        rethrow(ME)
    end
end
